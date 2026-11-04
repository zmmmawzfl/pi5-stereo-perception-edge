# stereo-depth — Raspberry Pi 5 采集端

**Pi 5 双 IMX219 采集 + 同步 + 推流/录制（Pi 端仓库）。**

本仓库只包含树莓派端：双相机采集、P 环同步、JPEG/ZMQ 推流、无损录制，以及第一天基线。
PC 端（SGBM/点云/ROS 2）位于**另一个仓库**：[pi5-stereo-perception-host](https://github.com/zmmmawzfl/pi5-stereo-perception-host)。两端通过 ZMQ + `SDP1` 协议通信。

## 当前状态

- 本仓库 **20 个单元测试**通过（sanitized 后的 Pi 子集：消息协议 + 同步控制环）。
- **两块 IMX219 已连接并实测**：枚举、单相机出图、Picamera2 双实例 640×480 采集都通过；
  但相机还没有刚性固定，标定/尺度/运动同步仍未验收。详见
  [docs/camera_check.md](docs/camera_check.md)。
- 未加控制的初始时间戳差约 **52.8 ms**（约 1.6 帧）；P 环 200 帧可压到 **~0.6 ms**，
  收敛约 5–7 s。服务启动阶段会丢弃尚未对齐的帧。
- PC 端的 SGBM/点云/ROS 2 **不在本仓库**，不要在这里跑。

## 目录

```text
raspberry-pi/
├── pi/
│   ├── capture/          # Picamera2 双实例 / synthetic / replay
│   ├── sync/             # PhaseLockController + 仿真
│   ├── stream/           # ZMQ PUB（JPEG + 时间戳旁路）、文件落盘
│   ├── service.py        # 采集→同步→推流/录制
│   └── tools/            # timestamp_baseline / record_pairs
├── shared/               # SDP1 消息、配置、统计、合成场景、录制格式
├── configs/              # default / pi
├── tests/                # 20 个 Pi 侧 unittest
└── docs/                 # 第一天、接口、联调、相机检查
```

## 快速开始（无需相机）

```bash
cd raspberry-pi
sudo apt install -y python3-opencv python3-picamera2 python3-zmq
python3 -m venv --system-site-packages .venv
.venv/bin/pip install -r requirements.txt

.venv/bin/python -m unittest discover -s tests -t .
# 合成后端跑第一天时间戳基线
.venv/bin/python -m pi.tools.timestamp_baseline --frames 100 --out runs/day1_raw.json
# 录制一段合成/回放数据
.venv/bin/python -m pi.tools.record_pairs --backend synthetic --frames 6 --out data/recordings/synth6
```

相机已连接；**先做刚性固定/调焦（计划 2026-11-05），再跑基线**：

```bash
rpicam-hello --list-cameras          # 必须看到两个 imx219
rpicam-still --camera 0 --width 640 --height 480 --nopreview -t 500 -o /tmp/cam0.jpg
rpicam-still --camera 1 --width 640 --height 480 --nopreview -t 500 -o /tmp/cam1.jpg
python -m pi.tools.timestamp_baseline --frames 100 --out runs/day1_raw.json
python -m pi.service --config configs/pi.yaml
```

固定前只验证“能出图/能配对”，不要采标定板；当前 `cam1` 还需要调焦。

PC 端接收（在另一个仓库/机器）：

```bash
python -m pc.receive.record_pairs --endpoint tcp://<PI_IP>:5555 --out data/recordings/day1
```

## 协议与配置

- `shared/messages.py`：`SDP1` + header + JPEG/raw；按 `pair_id` 重组，左右不靠到达顺序。
- `shared/config.py`：`camera/sync/stream/calib/sgbm/...`；`configs/pi.yaml` 只覆盖 Pi 端差异。
- 详细接口：[docs/interfaces.md](docs/interfaces.md)
- 第一天：[docs/day1.md](docs/day1.md)
- Pi↔PC 联调：[docs/runbook.md](docs/runbook.md)

## 注意

- Pi 端不要跑 SGBM/点云；那是 PC 仓库的事。
- `.venv` 是 Linux/aarch64 的，不要复制到 Mac。
- 相机实机路径未验证；无相机时用 `--backend synthetic`。
