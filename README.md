# icon_logo

一个用于批量生成多尺寸 logo 和 icon 的 Go 命令行工具，支持圆角、去背景、自动生成 Electron 需要的所有尺寸。

## 安装依赖

```sh
go get github.com/disintegration/imaging
go get github.com/Kodeworks/golang-image-ico
```

## 一键安装

你可以直接通过 go install 安装（Go 1.17+）：

```sh
go install github.com/zk3151463/icon_logo@latest
```

安装后可直接在终端使用 `icon_logo` 命令（需将 $GOPATH/bin 或 $HOME/go/bin 加入 PATH）。

## 使用方法

```sh
go run main.go --input 输入图片路径 --output 输出目录 [--sizes 尺寸列表] [--format png|jpg] [--radius 圆角半径]
```

### 参数说明
- `--input`   输入图片路径（必填），支持 PNG/JPG 等常见格式
- `--output`  输出目录（必填），生成的所有 icon/logo 文件会保存在此目录
- `--sizes`   生成的尺寸列表，逗号分隔，默认 `16,24,32,48,64,128,256,512`，适用于 Electron 等主流平台
- `--format`  输出图片格式，支持 `png` 或 `jpg`，默认 `png`
- `--radius`  每个角的圆弧半径（像素），以 256 尺寸为基准，其他尺寸自动等比例缩放。0 为无圆角。
- `help` 或 `--help` 查看命令说明和参数介绍

### help 命令说明

运行如下命令可查看所有参数及用法：
```sh
icon_logo help
icon_logo --help
```

输出内容包括所有参数、默认值、功能说明及示例。

### 示例
生成所有 Electron 需要的 icon：
```sh
icon_logo --input logo.png --output out
```

生成无圆角的 icon：
```sh
icon_logo --input logo.png --output out --radius 0
```

自定义尺寸和格式：
```sh
icon_logo --input logo.png --output out --sizes 32,64,128 --format jpg
```

## 打包为各平台可执行文件

推荐使用 [Taskfile](https://taskfile.dev) 自动化打包：

```sh
task build:all
```

生成的可执行文件在 `dist/` 目录下。

## 更新记录

- 2025-07-11 支持 radius 参数等比例缩放，输入以 256 尺寸为基准
- 2025-07-11 支持四角圆弧裁剪，radius 表示每个角的圆弧半径
- 2025-07-11 去除白色转透明功能，保留原图色彩
- 2025-07-11 支持一键 go install 安装和 Taskfile 多平台打包
- 2025-07-11 增加 help 命令和参数说明
- 2025-07-11 支持 Electron icon 常用尺寸批量生成

---

如需更多功能或定制，欢迎反馈！

GitHub 项目地址：[https://github.com/zk3151463/icon_logo](https://github.com/zk3151463/icon_logo)
