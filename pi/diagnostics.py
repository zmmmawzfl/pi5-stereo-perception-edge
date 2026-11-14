"""电源/降频诊断：读取 vcgencmd get_throttled 并解码。

树莓派 5 在 5V 供电不足时会掉压降频、甚至直接关机（本机 2026-11-14 发生过一次）。
把这些位记进 pi.service 的统计 JSON，事后才能区分“丢帧是代码问题”还是“电源问题”。
"""
from __future__ import annotations

import subprocess
from typing import Optional

#: get_throttled 的位定义（bit -> 名称）
THROTTLE_BITS = (
    (0, "under_voltage_now"),
    (1, "arm_freq_capped_now"),
    (2, "throttled_now"),
    (3, "soft_temp_limit_now"),
    (16, "under_voltage_since_boot"),
    (17, "arm_freq_capped_since_boot"),
    (18, "throttled_since_boot"),
    (19, "soft_temp_limit_since_boot"),
)


def parse_throttled(text: str) -> Optional[int]:
    """解析 "throttled=0x50000" 形式的输出；形状不对返回 None。"""
    text = (text or "").strip()
    if not text.startswith("throttled="):
        return None
    try:
        return int(text.split("=", 1)[1], 0)
    except ValueError:
        return None


def decode_throttled(bits: Optional[int]) -> list[str]:
    """把位掩码解成名称列表；None 返回空列表。"""
    if bits is None:
        return []
    return [name for bit, name in THROTTLE_BITS if bits & (1 << bit)]


def read_throttled(timeout_s: float = 2.0) -> Optional[int]:
    """调用 vcgencmd；命令不存在（非树莓派/测试机）或失败时返回 None。"""
    try:
        proc = subprocess.run(
            ["vcgencmd", "get_throttled"],
            capture_output=True,
            text=True,
            timeout=timeout_s,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if proc.returncode != 0:
        return None
    return parse_throttled(proc.stdout)
