# H.264 CPU 实测（Pi 5，640×480）

日期：2026-11-14。相机未固定，场景是室内暗光；系统同时有 PackageKit/GUI 占用，
电源为 10 W，`vcgencmd get_throttled` 返回 `0x50000`（发生过欠压/降频）。
因此下面的数字是**保守参考**，不是 27 W 官方电源下的最终性能。

## 结论

树莓派 5 上，H.264 本身不是主要 CPU 负担；主要负担来自“把 BGR 帧拷进 Python 再交给软件编码器”。

| 路径 | 双路 640×480 的 CPU | 说明 |
|---|---:|---|
| Picamera2 `H264Encoder`，2.5 Mbps/路 | **约 0.48 个核** | 相机/ISP 直连编码；8 s 实测 240 帧，文件 2.57 Mbps/路 |
| 单路 `H264Encoder` | 约 0.24 个核 | 同上，按单路折算 |
| `ffmpeg libx264` 从 BGR 数组编码 | 约 1.1 个核（30 fps 折算） | 不含 `capture_array`；短时并发实测可达 1.7 个核 |
| 当前 JPEG 路径（`capture_array` + `cv2.imencode`） | 约 1.33 个核 | 双路采集本身约 1.22 个核，JPEG q90 仅约 0.11 个核 |
| `ffmpeg -c:v h264_v4l2m2m` | 不可用 | `Could not find a valid device`，不要依赖这个 V4L2 硬编 |

## 复现

单路/双路 `H264Encoder` 的关键代码：

```python
from picamera2 import Picamera2
from picamera2.encoders import H264Encoder
from picamera2.outputs import FileOutput

cam = Picamera2(0)
cam.configure(cam.create_video_configuration(main={"size": (640, 480)}, buffer_count=4))
cam.start()
cam.start_recording(H264Encoder(bitrate=2_500_000), FileOutput(open("out.h264", "wb")))
# ... 运行一段时间 ...
cam.stop_recording()
```

注意：`create_video_configuration` 默认输出的是视频流，不要再用
`capture_array()` 把同一帧拉回 Python 一遍；那样会把 CPU 从约 0.5 个核抬到 1.5 个核以上。

## 对项目的建议

- H.264 用于**预览/远程看**可以；当前 2.5 Mbps/路、640×480 足够。
- 给 PC 做 SGBM 的度量流仍优先 JPEG q90 或 raw；H.264 是有损的，弱纹理/边缘会掉精度。
- 如果要接 H.264 传输，走 Picamera2 `H264Encoder`，不要走 `capture_array` + ffmpeg 软件编码。
- 640×640 不是 IMX219 原生模式；先换 27 W 电源、固定相机，再谈 640×640 的实测。

## 电源

10 W 电源已经触发欠压；Pi 5 + 双 CSI + 编码的峰值明显超过 10 W。
在换官方 27 W（或足够余量的 5 V/5 A）电源前，CPU 频率、帧率和温度数字都不应当作验收值。
