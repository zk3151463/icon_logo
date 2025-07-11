package main

import (
	"flag"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"os"
	"path/filepath"
	"strings"

	ico "github.com/Kodeworks/golang-image-ico"
	"github.com/disintegration/imaging"
)

func main() {
	input := flag.String("input", "", "输入图片路径")
	output := flag.String("output", "", "输出目录")
	sizes := flag.String("sizes", "16,24,32,48,64,128,256,512", "生成的尺寸列表,逗号分隔 (默认 Electron icon 尺寸)")
	format := flag.String("format", "png", "输出图片格式: png 或 jpg")
	radius := flag.Float64("radius", 256, "圆角半径，默认尺寸的1/4")
	flag.Parse()

	if *input == "" || *output == "" {
		fmt.Println("请指定 --input 和 --output 参数")
		os.Exit(1)
	}

	img, err := imaging.Open(*input)
	if err != nil {
		fmt.Printf("打开图片失败: %v\n", err)
		os.Exit(1)
	}

	if err := os.MkdirAll(*output, 0755); err != nil {
		fmt.Printf("创建输出目录失败: %v\n", err)
		os.Exit(1)
	}

	// 生成所有尺寸的 PNG/JPG
	var icoImages []image.Image
	sizeList := strings.Split(*sizes, ",")
	for _, sizeStr := range sizeList {
		sizeStr = strings.TrimSpace(sizeStr)
		size, err := parseSize(sizeStr)
		if err != nil {
			fmt.Printf("尺寸解析失败: %v\n", err)
			continue
		}
		resized := imaging.Resize(img, size, size, imaging.Lanczos)
		var rounded image.Image
		if *radius == 0 || *radius == -1 {
			rounded = edgeWhiteToTransparent(resized, size, size/12) // 仅边缘白色转透明
		} else {
			rounded = roundCornerAndRemoveBg(resized, size, *radius)
		}
		filename := fmt.Sprintf("logo_%dx%d.%s", size, size, *format)
		outPath := filepath.Join(*output, filename)
		if *format == "png" {
			imaging.Save(rounded, outPath)
		} else if *format == "jpg" || *format == "jpeg" {
			// JPG 不支持透明，填充白色背景
			jpgImg := image.NewRGBA(rounded.Bounds())
			draw.Draw(jpgImg, rounded.Bounds(), &image.Uniform{color.White}, image.Point{}, draw.Src)
			draw.Draw(jpgImg, rounded.Bounds(), rounded, image.Point{}, draw.Over)
			imaging.Save(jpgImg, outPath, imaging.JPEGQuality(90))
		} else {
			fmt.Printf("不支持的格式: %s\n", *format)
		}
		fmt.Printf("生成: %s\n", outPath)
		icoImages = append(icoImages, rounded)
	}

	// 生成 ICO 文件（仅 256x256）
	icoPath := filepath.Join(*output, "icon.ico")
	icoFile, err := os.Create(icoPath)
	if err != nil {
		fmt.Printf("创建 ICO 文件失败: %v\n", err)
		return
	}
	defer icoFile.Close()
	var ico256 image.Image
	for i, sizeStr := range sizeList {
		sizeStr = strings.TrimSpace(sizeStr)
		size, _ := parseSize(sizeStr)
		if size == 256 {
			ico256 = icoImages[i]
			break
		}
	}
	if ico256 == nil {
		fmt.Println("未找到 256x256 尺寸，无法生成 ICO")
		return
	}
	if err := ico.Encode(icoFile, ico256); err != nil {
		fmt.Printf("ICO 编码失败: %v\n", err)
		return
	}
	fmt.Printf("生成: %s\n", icoPath)
}

func parseSize(s string) (int, error) {
	var size int
	_, err := fmt.Sscanf(s, "%d", &size)
	return size, err
}

// 边缘白色转透明（主体白色不变）
func edgeWhiteToTransparent(src image.Image, size int, edge int) image.Image {
	out := image.NewNRGBA(image.Rect(0, 0, size, size))
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			c := src.At(x, y)
			r, g, b, a := c.RGBA()
			isEdge := x < edge || x >= size-edge || y < edge || y >= size-edge
			if isEdge && r>>8 > 240 && g>>8 > 240 && b>>8 > 240 && a > 0 {
				out.Set(x, y, color.NRGBA{0, 0, 0, 0})
			} else {
				out.Set(x, y, c)
			}
		}
	}
	return out
}

// 白色转透明
func whiteToTransparent(src image.Image, size int) image.Image {
	out := image.NewNRGBA(image.Rect(0, 0, size, size))
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			c := src.At(x, y)
			r, g, b, a := c.RGBA()
			if r>>8 > 240 && g>>8 > 240 && b>>8 > 240 && a > 0 {
				out.Set(x, y, color.NRGBA{0, 0, 0, 0})
			} else {
				out.Set(x, y, c)
			}
		}
	}
	return out
}

// 白色转透明+圆角处理
func roundCornerAndRemoveBg(src image.Image, size int, radius float64) image.Image {
	out := image.NewNRGBA(image.Rect(0, 0, size, size))
	center := float64(size) / 2
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			dx := float64(x) - center + 0.5
			dy := float64(y) - center + 0.5
			c := src.At(x, y)
			r, g, b, a := c.RGBA()
			isWhite := (r>>8 > 240 && g>>8 > 240 && b>>8 > 240 && a > 0)
			if (radius > 0 && dx*dx+dy*dy > radius*radius) || isWhite {
				out.Set(x, y, color.NRGBA{0, 0, 0, 0})
			} else {
				out.Set(x, y, c)
			}
		}
	}
	return out
}
