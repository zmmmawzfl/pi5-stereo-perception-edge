"""pi.diagnostics 的解析与解码。"""
import unittest

from pi.diagnostics import decode_throttled, parse_throttled


class TestParse(unittest.TestCase):
    def test_parses_hex(self):
        self.assertEqual(parse_throttled("throttled=0x50000\n"), 0x50000)

    def test_parses_zero(self):
        self.assertEqual(parse_throttled("throttled=0x0"), 0)

    def test_rejects_garbage(self):
        self.assertIsNone(parse_throttled(""))
        self.assertIsNone(parse_throttled("Undervoltage detected!"))
        self.assertIsNone(parse_throttled("throttled=zzz"))


class TestDecode(unittest.TestCase):
    def test_zero_has_no_labels(self):
        self.assertEqual(decode_throttled(0), [])

    def test_historical_bits(self):
        # 0x50000 = bit16 (欠压) + bit18 (降频)，都是“本次开机以来”
        self.assertEqual(
            decode_throttled(0x50000),
            ["under_voltage_since_boot", "throttled_since_boot"],
        )

    def test_current_bit_first(self):
        self.assertEqual(decode_throttled(0x1), ["under_voltage_now"])

    def test_none_is_empty(self):
        self.assertEqual(decode_throttled(None), [])


if __name__ == "__main__":
    unittest.main()
