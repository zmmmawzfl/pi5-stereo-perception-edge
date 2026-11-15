"""SyntheticBackend 的实时节流：服务模式下必须按帧率出帧。"""
import time
import unittest

from pi.capture.synthetic_backend import SyntheticBackend


class PacingTest(unittest.TestCase):
    def test_realtime_blocks_at_target_fps(self):
        backend = SyntheticBackend(width=32, height=24, fps=50, realtime=True)
        backend.start()
        n = 10  # 50 fps -> 10 帧约 0.2 s
        t0 = time.monotonic()
        for _ in range(n):
            backend.read()
        elapsed = time.monotonic() - t0
        self.assertGreaterEqual(elapsed, 0.15, "没有按帧率阻塞")
        self.assertLess(elapsed, 1.5, "阻塞过头了")

    def test_realtime_off_is_immediate(self):
        backend = SyntheticBackend(width=32, height=24, fps=1, realtime=False)
        backend.start()
        t0 = time.monotonic()
        for _ in range(20):
            backend.read()
        self.assertLess(time.monotonic() - t0, 0.5, "realtime=False 不该阻塞")

    def test_timestamps_still_advance_by_period(self):
        backend = SyntheticBackend(width=16, height=12, fps=30, jitter_us=0.0, realtime=False)
        a = backend.read()
        b = backend.read()
        self.assertAlmostEqual((b.ts_left_ns - a.ts_left_ns) / 1000.0, 1e6 / 30.0, places=1)


if __name__ == "__main__":
    unittest.main()
