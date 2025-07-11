# icon_logo

一个用于批量生成多尺寸 logo 和 icon 的 Go 命令行工具，支持圆角、去背景、自动生成 Electron 需要的所有尺寸。

## 安装依赖

```sh
go get github.com/disintegration/imaging
go get github.com/Kodeworks/golang-image-ico
```

## 使用方法

```sh
go run main.go --input 输入图片路径 --output 输出目录 [--sizes 尺寸列表] [--format png|jpg] [--radius 圆角半径]
```

### 参数说明
- `--input`   输入图片路径（必填）
- `--output`  输出目录（必填）
- `--sizes`   生成的尺寸列表，逗号分隔，默认 `16,24,32,48,64,128,256,512`
- `--format`  输出图片格式，支持 `png` 或 `jpg`，默认 `png`
- `--radius`  圆角半径，默认 2 像素。设为 0 或 -1 时无圆角。
- `help` 或 `--help` 查看命令说明

### 示例
生成所有 Electron 需要的 icon：
```sh
go run main.go --input logo.png --output out
```

生成无圆角的 icon：
```sh
go run main.go --input logo.png --output out --radius 0
```

自定义尺寸和格式：
```sh
go run main.go --input logo.png --output out --sizes 32,64,128 --format jpg
```

## 打包为各平台可执行文件

推荐使用 [Taskfile](https://taskfile.dev) 自动化打包：

```sh
task build:all
```

生成的可执行文件在 `dist/` 目录下。

---

如需更多功能或定制，欢迎反馈！
