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
	radius := flag.Float64("radius", 0, "每个角的圆弧半径（像素），0为无圆角")
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
		var actualRadius float64
		if *radius <= 0 {
			actualRadius = 0
		} else {
			actualRadius = *radius * float64(size) / 256.0
		}
		if actualRadius <= 0 {
			rounded = resized // 无圆角
		} else {
			rounded = roundCorner(resized, size, actualRadius)
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

// 四角圆弧裁剪
func roundCorner(src image.Image, size int, radius float64) image.Image {
	out := image.NewNRGBA(image.Rect(0, 0, size, size))
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			inCorner := false
			// 左上
			if x < int(radius) && y < int(radius) {
				dx := float64(x) - radius
				dy := float64(y) - radius
				inCorner = dx*dx+dy*dy > radius*radius
			}
			// 右上
			if x >= size-int(radius) && y < int(radius) {
				dx := float64(x) - (float64(size-1) - radius)
				dy := float64(y) - radius
				inCorner = dx*dx+dy*dy > radius*radius
			}
			// 左下
			if x < int(radius) && y >= size-int(radius) {
				dx := float64(x) - radius
				dy := float64(y) - (float64(size-1) - radius)
				inCorner = dx*dx+dy*dy > radius*radius
			}
			// 右下
			if x >= size-int(radius) && y >= size-int(radius) {
				dx := float64(x) - (float64(size-1) - radius)
				dy := float64(y) - (float64(size-1) - radius)
				inCorner = dx*dx+dy*dy > radius*radius
			}
			if inCorner {
				out.Set(x, y, color.NRGBA{0, 0, 0, 0})
			} else {
				out.Set(x, y, src.At(x, y))
			}
		}
	}
	return out
}
