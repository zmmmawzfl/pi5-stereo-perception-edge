# 双 IMX219 实机检查（2026-11-04）

## 结论

两块 CSI IMX219 **都能被 Pi 5 正常枚举、单独出图，也能用 Picamera2 双实例同时采集**。
摄像头目前**没有刚性固定**，所以只能验证“能调用”，不能做标定/尺度验收。

## 枚举

```text
$ rpicam-hello --list-cameras
0 : imx219 [3280x2464 10-bit RGGB] (/base/axi/pcie@1000120000/rp1/i2c@88000/imx219@10)
1 : imx219 [3280x2464 10-bit RGGB] (/base/axi/pcie@1000120000/rp1/i2c@80000/imx219@10)
```

- `Picamera2.global_camera_info()` 返回 2 个相机，`Num` 为 0/1；
- 两者 `Location=2`、`Rotation=180`；如果画面方向不合适，在采集/校正前统一旋转 180°；
- `/boot/firmware/config.txt` 同时有 `dtoverlay=imx219,cam0` 与 `dtoverlay=imx219,cam1`；
- 内核日志显示两个 `rp1-cfe` 都 `Using sensor imx219` 并注册了 `/dev/video*`。

## 单相机出图

```bash
rpicam-still --camera 0 --width 640 --height 480 --nopreview -t 500 -o cam0.jpg
rpicam-still --camera 1 --width 640 --height 480 --nopreview -t 500 -o cam1.jpg
```

两张都 exit 0，640×480。样例在 `runs/camera_check/cam0.jpg`、`cam1.jpg`。
cam1 当前画面明显失焦/过近，是镜头没固定造成的，不是相机没起来。

## 双实例 + 时间戳

`Picamera2Backend(width=640, height=480, fps=30, buffer_count=3)`：

```text
n=10  median=52.7650 ms  P25=52.7632  P75=52.7657  IQR=0.0025  std=0.0043
```

这是**未加控制**的出厂相位差：约 1.6 帧，抖动很小，但相位本身很大。
`FrameDurationLimits` 只锁周期，不会自动把两台相机的曝光对齐。

`timestamp_baseline --with-control --frames 200`（Kp=0.05、max_step=300us）：

```text
最后 10 帧: 1.07, 0.99, 0.91, 0.85, 0.79, 0.73, 0.68, 0.64, 0.60, 0.56 ms
最后 50 帧 median 3.62 ms, min 0.558, max 10.793
结束周期 33305.4 us（初始 33333.3 us）
```

结论：P 环方向正确，能把 52.8 ms 的初始相位差压到 ~0.6 ms；但按当前 Kp/步长，
收敛需要约 150–200 帧（5–7 s @30fps）。服务启动阶段会丢弃这些尚未对齐的帧。

## 本次代码修正

- `pi/capture/picamera2_backend.py`：启动后先丢弃 8 对做 warmup；`read(strict=False)`
  在坏对时返回 `skew_ok=False` 而不是直接抛异常；`retries` 默认 3→10。
- `pi/service.py`：坏对的时间戳仍喂给同步环，但不发布/不计数；报告增加 `dropped`。
- `pi/tools/timestamp_baseline.py`：基线用非严格读取，记录全部时间戳，新增 `bad_pairs`。

## 下一步（计划 2026-11-05）

1. 做刚性支架，锁死两个模组，确认基线；
2. 给 cam1 调焦，确认远近都清楚；
3. 固定后重跑 `timestamp_baseline --frames 100`（不控制）和 `--with-control --frames 200`；
4. 再采 15–25 对棋盘格做真实标定。

## 现在不能做的事

- **不要现在标定**：两台相机没有刚性固定，标定结果会随碰触失效。
- 不要用当前相位差判断“同步好坏”；看运动纹理板的 SGBM 抖动才有意义。
- 不要假设 83 mm 基线；等固定后用量具和标定 `T` 模长确认。
