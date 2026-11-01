PY ?= .venv/bin/python

.PHONY: help test day1 service

help:
	@echo "make test     运行 20 个 Pi 侧测试"
	@echo "make day1     第一天时间戳基线（无相机时 synthetic）"
	@echo "make service  启动采集/同步/推流服务"

test:
	$(PY) -m unittest discover -s tests -t . -v

day1:
	$(PY) -m pi.tools.timestamp_baseline --frames 100 --out runs/day1_raw.json

service:
	$(PY) -m pi.service --config configs/pi.yaml
