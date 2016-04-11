### 名词解释

**位图图像**      
* 以点或像素的方式记录图像   
* 优点：色彩自然，逼真    
* 缺点：放大缩小易失真，随着图像精度的提高或放大，占用磁盘空间较大
* 用途：照片或复杂图像

**矢量图形**
* 以数字方式来记录图像
* 优点：信息存储量小，分辨率独立，再放大缩小过程中不易失真；且是面向对象，每一个对象都可   
以任意移动、调整大小或重叠；可用于 3D   
* 缺点：使用数学方程来描述图像，运算比较复杂；图片色彩比较单调，生硬，不自然
* 用途：文字、商标等相对规则的图形             
***
**RGBA**
* R G B  正整数 | 百分比   
  A      Alpha 透明度 0 ~ 1   
  background: rgba(0, 0, 0, 0.5);
***


### 英文
| English               | Description                         |
|-----------------------|-------------------------------------|
| FLIF                  | Free Loseless Image Formate         |
| animation             | 动画                                 |
| APNG                  | Animated Portable Network Graphics  |
| compress/compression  | 压缩                                 |
| separate              | 分开的，区分的，独立的                 |
| decoded               | 解码，译码                           |
| progressive           | 逐步的，进步的                        |
| entire                | 整个的，全部的                       |
| contrast              | 对比                                |
| partial               | 部分的，局部的，偏爱的                |
| frame                 | 框架，帧                            |
| noval                 | 新奇的，异常的                       |
| outperforms           | 优于,胜过，做的比...好                |
| in terms of           | 就...而言，根据                      |
| compression ratio     | 压缩率                              |
| typical               | 典型的                              |
| key advantages        | 优点， 优势点                       |
| corpus                | 全集，语料库                        |
| perform               | 表现                               |    
| interlaced            | 隔行扫描                           |
| progressive           | 逐行扫描                           |
| artifacts             | 构件                               |


### User Commands
-d 解码    
`flif -d input.flif output.png`  

-e 编码   
`flif -e input.png output.flif`

-t 转码   
`flif -t input.flif output.flif`

-v 显示详细信息   
-h 显示帮助并退出

```
Usage: // 用法
   // -e 编码  -d 解码  -t 转码
   flif [-e] [encode options] <input image(s)> <output.flif>
   flif [-d] [decode options] <input.flif> <output.pnm | output.pam | output.png>
   flif [-t] [decode options] [encode options] <input.flif> <output.flif>
Supported input/output image formats: PNG, PNM (PPM,PGM,PBM), PAM

General Options: // 常规选项
   // -v 显示详细信息
   -h, --help                  show help (use -hvv for advanced options)
   -v, --verbose               increase verbosity (multiple -v for more output)

Encode options: (-e, --encode) // 编码选项
   // 隔行扫描 （除微小图像外）
   -I, --interlace             interlacing (default, except for tiny images)
   // 强制非隔行扫描
   -N, --no-interlace          force no interlacing
   // 保持 Alpha 通道值为 0 ,即完全透明
   -K, --keep-invisible-rgb    store original RGB values behind A=0
   // frame 帧延迟 ms         默认-F100
   -F, --frame-delay=N[,N,..]  delay between animation frames in ms; default: -F100

Advanced encode options: (mostly useful for flifcrushing) // 高级编码选项(对flifcrushing最有用)
   // 调色板(_Alpha)最大尺寸   默认值 -P1024
   -P, --max-palette-size=N    max size for Palette(_Alpha); default: -P1024
   // 强制颜色桶转换
   -A, --force-color-buckets   force Color_Buckets transform
   // 禁用颜色桶转换
   -B, --no-color-buckets      disable Color_Buckets transform
   // 禁用通道转换
   -C, --no-channel-compact    disable Channel_Compact transform
   // 禁用YCoCg 色彩空间变换
   -Y, --no-ycocg              disable YCoCg transform (use plain RGB instead)
   // 禁用框架形状转换
   -S, --no-frame-shape        disable Frame_Shape transform
   // 最大帧环回             默认值 -L1
   -L, --max-frame-lookback=N  max nb of frames for Frame_Lookback; default: -L1
   // MANIAC 学习迭代次数    默认值 -R3
   -R, --maniac-repeats=N      MANIAC learning iterations; default: -R3

Decode options: (-d, --decode) // 解码选项
   // 不进行解码，只识别输入FLIF文件
   -i, --identify             do not decode, just identify the input FLIF file
   // 有损解码              默认值 -q100
   -q, --quality=N            lossy decode quality percentage; default -q100
   // 有损缩图 1：N         默认值 -s1
   -s, --scale=N              lossy downscaled image at scale 1:N (2,4,8,16,32); default -s1
   // 有损缩图， 适应宽高比
   -r, --resize=WxH           lossy downscaled image to fit WxH
```








```shell
export LD_LIBRARY_PATH=/home/louis/12.2015/FLIF/src

export LD_LIBRARY_PATH=./
g++ -std=c++11 main.c -L. -linterface -lflif
g++ -std=c++11 -fPIC -shared -o libinterface.so interface.cpp convert.cpp -L. -lflif -I library/ -w




```
