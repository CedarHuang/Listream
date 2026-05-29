<div align="center">

<img src="src/assets/icon.svg" width="128" alt="">

# Listream

看直播，够简单。

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078d4?logo=windows)](https://github.com/CedarHuang/Listream/releases)
[![Python](https://img.shields.io/badge/Python-3.12-3776ab?logo=python&logoColor=white)](https://www.python.org/)
[![PySide6](https://img.shields.io/badge/PySide6-6.5-41cd52?logo=qt&logoColor=white)](https://doc.qt.io/qtforpython/)

</div>

---

Listream 是一个 Windows 桌面直播播放器。添加 M3U 订阅链接，自动拉取频道列表，点击即看，用完即走。

搜索框输入关键字快速定位频道，频道按类别自动分组。台标自动下载，缓冲速度和播放信息一目了然。无边框窗口干净利落，支持 Win10 / Win11。

**主要特性**

- 多个 M3U 订阅源同时管理，可拖拽排序、启用 / 禁用
- 频道分组浏览，实时搜索过滤
- 音量图标点击静音，响度均衡三档切换，防止频道间音量突变
- 画质增强一键开关
- 开启信息面板显示当前视频的编码、分辨率、帧率、码率
- 支持 HTTP / SOCKS5 代理

---

## 📦 安装

从 [Releases](https://github.com/CedarHuang/Listream/releases) 下载 `Listream-v*-windows-x64.zip`，解压运行 `Listream.exe`。无需安装。

数据目录：`%APPDATA%\CedarHuang\Listream\`

---

## 🛠️ 从源码构建

```bash
pip install -r requirements.txt
python build.py
python -m src.main
```

打包为独立可执行文件：

```bash
python build.py --package
```

---

## 📄 License

[Apache 2.0](LICENSE)
