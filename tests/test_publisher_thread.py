"""ThreadedPublisher：不阻塞采集、队列满时丢最旧、close 会收尾。"""
import threading
import time
import unittest

import numpy as np

from pi.capture.base import CapturedPair
from pi.stream.publisher import PublishStats, ThreadedPublisher


def make_pair(seq: int) -> CapturedPair:
    img = np.zeros((4, 4, 3), np.uint8)
    return CapturedPair(left=img, right=img, ts_left_ns=0, ts_right_ns=0, seq=seq)


class BlockingPublisher:
    """第一次 publish 会阻塞，直到测试放开 gate。"""

    def __init__(self) -> None:
        self.stats = PublishStats()
        self.got = []
        self.started = threading.Event()
        self.gate = threading.Event()
        self.closed = False

    def publish(self, pair: CapturedPair) -> None:
        self.started.set()
        self.gate.wait(2.0)
        self.got.append(pair.seq)
        self.stats.published += 1

    def close(self) -> None:
        self.closed = True


class SlowPublisher:
    def __init__(self, delay: float = 0.2) -> None:
        self.stats = PublishStats()
        self.delay = delay
        self.closed = False

    def publish(self, pair: CapturedPair) -> None:
        time.sleep(self.delay)
        self.stats.published += 1

    def close(self) -> None:
        self.closed = True


class FlakyPublisher:
    def __init__(self) -> None:
        self.stats = PublishStats()
        self.got = []
        self.calls = 0

    def publish(self, pair: CapturedPair) -> None:
        self.calls += 1
        if self.calls == 1:
            raise RuntimeError("网络抖动")
        self.got.append(pair.seq)
        self.stats.published += 1

    def close(self) -> None:
        pass


class TestThreadedPublisher(unittest.TestCase):
    def test_publish_does_not_block_on_slow_inner(self):
        inner = SlowPublisher(delay=0.3)
        pub = ThreadedPublisher(inner, queue_size=2)
        t0 = time.perf_counter()
        for i in range(3):
            pub.publish(make_pair(i))
        elapsed = time.perf_counter() - t0
        self.assertLess(elapsed, 0.15, f"入队耗时 {elapsed:.3f}s，说明仍在同步发送")
        pub.close()

    def test_drops_oldest_and_keeps_latest(self):
        inner = BlockingPublisher()
        pub = ThreadedPublisher(inner, queue_size=1)
        pub.publish(make_pair(0))       # 被工作线程取走并阻塞
        self.assertTrue(inner.started.wait(1.0))
        pub.publish(make_pair(1))       # 占住队列
        pub.publish(make_pair(2))       # 队列满 → 丢 1，留下 2
        inner.gate.set()
        pub.close()
        self.assertEqual(inner.got, [0, 2])
        self.assertGreaterEqual(pub.stats.dropped, 1)

    def test_close_flushes_and_closes_inner(self):
        inner = SlowPublisher(delay=0.01)
        pub = ThreadedPublisher(inner, queue_size=4)
        for i in range(3):
            pub.publish(make_pair(i))
        pub.close()
        self.assertTrue(inner.closed)

    def test_inner_error_does_not_kill_thread(self):
        inner = FlakyPublisher()
        pub = ThreadedPublisher(inner, queue_size=2)
        pub.publish(make_pair(0))   # 抛一次
        time.sleep(0.1)
        pub.publish(make_pair(1))
        pub.close()
        self.assertEqual(inner.got, [1])
        self.assertIsNotNone(pub.last_error)


if __name__ == "__main__":
    unittest.main()
