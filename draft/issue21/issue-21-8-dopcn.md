---
title:  "GPU-Accelerated Machine Vision"
category: "21"
date: "2015-02-10 05:00:00"
author: "<a href=\"https://twitter.com/bradlarson\">Brad Larson</a>"
tags: article
---


While the proliferation of cameras attached to mobile computers has been a boon for photography, there is much more that this can enable. Beyond simply capturing the outside world, the right software running on more powerful hardware can allow these computers to understand the things their cameras see.

越来越多的移动计算设备都开始携带照相机镜头，这对于摄影界来说是一个好事情，不仅如此携带镜头也为这些设备提供了更多的可能性。除了最基本的拍摄功能，结合合适的软件这些更为强大的硬件设备可以像人脑一样理解它看到了什么。

This small bit of understanding can enable some truly powerful applications, such as barcode scanning, document recognition and imaging, translation of written words, real-time image stabilization, and augmented reality. As processing power, camera fidelity, and algorithms advance, this machine vision will be able to solve even more important problems.

仅仅具备一点点的理解能力就可以催生一些非常强大的应用，比如说条形码识别，文档识别和成像，手写文字的转化，实时成像防抖，虚拟现实。随着处理能力变得更加强大，镜头保真程度更高，算法效率更好，机器视觉（machine vision）这个技术将会解决更加重大的问题。

Many people regard machine vision as a complex discipline, far outside the reach of everyday programmers. I don't believe that's the case. I created an open-source framework called [GPUImage](https://github.com/BradLarson/GPUImage) in large part because I wanted to explore high-performance machine vision and make it more accessible.

有些人认为机器视觉是个非常复杂的领域，是程序员们的日常工作中绝不会遇到的。我认为这种观点是不正确的。我发起了一个开源项目[GPUImage](https://github.com/BradLarson/GPUImage)在很大程度上是因为我想探索一下高性能的机器视觉是怎么样的，并且让这种技术更易于使用。

GPUs are ideally suited to operate on images and video because they are tuned to work on large collections of data in parallel, such as the pixels in an image or video frame. Depending on the operation, GPUs can process images hundreds or even thousands of times faster than CPUs can.

GPU 是一种理想的处理图片和视频的设备，因为它是专门为并行处理大量数据而生的，图片和视频中的每一帧都包含大量的像素数据。在某些情况下 GPU 处理图片的速度可以是 CPU 的成千上百倍。

One of the things I learned while working on GPUImage is how even seemingly complex image processing operations can be built from smaller, simpler ones. I'd like to break down the components of some common machine vision processes, and show how these processes can be accelerated to run on modern GPUs.

在我开发 GPUImage 的过程中我学到了一件事情，那就是即使是图片处理这样看上去很复杂的工作依然可以分解为一个个更小更简单的部分。这篇文章里我想将机器视觉中常见的过程分解开来，并且展示如何在现代的 GPU 设备上让这些过程运行地更快。

Every operation analyzed here has a full implementation within GPUImage, and you can try them yourself by grabbing the project and building the FilterShowcase sample application either for OS X or iOS. Additionally, all of these operations have CPU-based (and some GPU-accelerated) implementations within the OpenCV framework, which Engin Kurutepe talks about in [his article within this issue](/issue-21/face-recognition-with-opencv.html).

以下的每一步在 GPUImage 中都有完整的实现，你可以下载实例工程 FilterShowcase，工程包含了 OS X 和 iOS 版本，在其中体验一下各个功能。此外，这些功能都有基于 CPU （有些使用了 GPU 加速）的实现，这些实现是基于 OpenCV 库的，在[另一片文章](http://objccn.io/issue-21-9/)中 Engin Kurutepe 详细的讲解了这个库。

## Sobel Edge Detection

##索贝尔边界探测

The first operation I'll describe may actually be used more frequently for cosmetic image effects than machine vision, but it's a good place to start. Sobel edge detection is a process where edges (sharp transitions from light to dark, or vice versa) are found within an image.[^1] The strength of an edge around a pixel is reflected in how bright that pixel is in the processed image.

我将要描述的第一种操作事实上在滤镜方面的应用比机器视觉方面更多，但是这会是一个好的开始。索贝尔边界探测用于探测一张图片中边界的出现位置，边界通常都是由明转暗的突然变化或者反过来由暗转明。在被处理的图片中一个像素的亮度反映了这个像素周围边界的明显程度。

For example, let's see a scene before and after Sobel edge detection:

下面是一个例子，我们来看看同一张图片在进行索贝尔边界探测之前和之后

<img src="http://img.objccn.io/issue-21/MV-Chair.png" style="display: inline-block; width:240px" alt="Original image"/>
<img src="http://img.objccn.io/issue-21/MV-Sobel.png" style="display: inline-block; width:240px" alt="Sobel edge detection image"/>

As I mentioned, this is often used for visual effects. If the colors of the above are inverted, with the strongest edges represented in black instead of white, we get an image that resembles a pencil sketch:

正如我上面提到的，这项技术通常用来实现一些视觉效果。如果在上面的图片中将颜色进行反转，最明显的边界用黑色代表而不是白色，那么我就得到了一张类似铅笔素描效果的图片。

<img src="http://img.objccn.io/issue-21/MV-Sketch.png" style="width:240px" alt="Sketch filtered image"/>

So how are these edges calculated? The first step in this process is a reduction of a color image to a luminance (grayscale) image. Janie Clayton explains how this is calculated in a fragment shader within [her article](/issue-21/gpu-accelerated-image-processing.html), but basically the red, green, and blue components of each pixel are weighted and summed to arrive at a single value for how bright that pixel is.

那么这些边界是如何被探测出来的？第一步这张彩色图片需要减薄成一张亮度(灰阶)图。Janie Clayton 在[她的文章](http://objccn.io/issue-21-7/)中解释了这一步是如何在一个[片断着色器](http://zh.wikipedia.org/w/index.php?title=%E7%89%87%E6%96%AD%E7%9D%80%E8%89%B2%E5%99%A8&redirect=no)([fragment shader](https://www.opengl.org/wiki/Fragment_Shader))中完成的。简单地说这个过程就是将每个像素的红绿蓝部分加权合为一个代表这个像素亮度的值。

Some video sources and cameras provide YUV-format images, rather than RGB. The YUV color format splits luminance information (Y) from chrominance (UV), so for inputs like that, a color conversion step can be avoided. The luminance part of the image can be used directly.

有的视频设备和相机提供的是 YUV 格式的图片，而不是 RGB 格式。YUV 这种色彩格式已经亮度信息(Y)和色度信息(UV)分离，所以如果原图片是这种格式，颜色转换这个步骤就可以省略，直接用其中亮度的部分就可以。

Once an image is reduced to its luminance, the edge strength near a pixel is calculated by looking at a 3×3 array of neighboring pixels. An image processing calculation performed over a block of pixels involves what is called a convolution kernel. Convolution kernels consist of a matrix of weights that are multiplied with the values of the pixels surrounding a central pixel, with the sum of those weighted values determining the final pixel value.

图片一旦减薄到仅剩亮度信息，一个像素周围的边界明显程度是由它周围3*3个临近像素计算而得。在一堆像素上进行图片处理的计算过程涉及到一个叫做卷积矩阵（参考：[convolution matrix](http://en.wikipedia.org/wiki/Kernel_(image_processing))）的东西。卷积矩阵是一个由权重数据组成的矩阵，中心像素周围像素的亮度乘以这些权重然后再加合就得到中心像素的转化后数值。

These kernels are applied once per pixel across the entire image. The order in which pixels are processed doesn't matter, so a convolution across an image is an easy operation to parallelize. As a result, this can be greatly accelerated by running on a programmable GPU using fragment shaders. As described in [Janie's article](/issue-21/gpu-accelerated-image-processing.html), fragment shaders are C-like programs that can be used by GPUs to perform incredibly fast image processing.

图片上的每一个像素都要与这个矩阵计算出一个数值。在处理的过程中像素的处理顺序是无关紧要的，所以这种计算很容易并行运行。因此，这个计算过程可以通过运行在一个运行着片断着色器的可编程的 GPU 上来极大的提高处理效率。正如在[Janie 的文章](http://objccn.io/issue-21-7/)中所提到的，片断着色器是一些 C 语言风格的程序，运行在 GPU 上可以进行一些非常快速的图片处理。

This is the horizontal kernel of the Sobel operator:

下面这个是索贝尔算子的水平处理矩阵：

<style type="text/css">
  table.border td {
      border: 1px solid #ccc;
  }
  td.center {
    padding-left: 1em;
    padding-right: 1em;
    text-align: center;
  }
</style>
<table class="border">
  <tr>
    <td class="center">−1</td><td class="center">0</td><td class="center">+1</td>
  </tr>
  <tr>
    <td class="center">−2</td><td class="center">0</td><td class="center">+2</td>
  </tr>
  <tr>
    <td class="center">−1</td><td class="center">0</td><td class="center">+1</td>
  </tr>
</table>

To apply this to a pixel, the luminance is read from each surrounding pixel. If the input image has been converted to grayscale, this can be sampled from any of the red, green, or blue color channels. The luminance of a particular surrounding pixel is multiplied by the corresponding weight from the above matrix and added to the total.

为了进行某一个像素的计算，每一个临近像素的亮度信息都要读取出来。如果要处理的图片已经被转化为灰阶图，亮度可以从红绿蓝任意颜色通道中抽样。临近像素的亮度乘以矩阵中对应的权重加合为最终值。

How this works to find an edge in a direction is that it looks for differences in luminance (brightness) on the left and right sides of a central pixel. If you have two equally bright pixels on the left and right of the center one (a smooth area in the image), the product of their intensities and the negative and positive weights will cancel out and no edge will be detected. If there is a difference between the brightness of pixels on the left and right (an edge), one brightness will be subtracted from the other. The greater the difference, the stronger the edge measured.

在一个方向上寻找边界的过程是这样的：转化之后对比一个像素左右两边像素的亮度差。如果当前这个像素左右两边的像素亮度相同也就是说在图片上是一个柔和的过度，他们的亮度值和正负权重会相互抵消于是这个区域不会被判定为边界。如果左边像素和右边像素的亮度差别很大也就是说是一个边界，用其中一个亮度减去另一个，这种差异越大这个边界就更明显。

The Sobel operator has two stages, the horizontal kernel being the first. A vertical kernel is applied at the same time, with the following matrix of weights:

索贝尔过程有两个步骤，首先是水平矩阵进行，同时一个垂直矩阵也会进行，这个垂直矩阵中的权重如下

<table class="border">
  <tr>
    <td class="center">−1</td><td class="center">−2</td><td class="center">−1</td>
  </tr>
  <tr>
    <td class="center">0</td><td class="center">0</td><td class="center">0</td>
  </tr>
  <tr>
    <td class="center">+1</td><td class="center">+2</td><td class="center">+1</td>
  </tr>
</table>

The final weighted sum from each operator is tallied, and the square root of the sums of their squares is obtained. The squares are used because the values might be negative or positive, but we want their magnitude, not their sign. There's also a handy built-in GLSL function that does this for us.

两个方向转化后的加权和会被记录下来，他们的平方和的平方根会计算出来。之所以要进行平方是因为计算出来的值可能是正值也可能是负值，但是我们需要的是值的量级而不是他们的正负。有一个好用内建函数 GLSL 能够帮助我们快速完成这个过程。

That combined value is then used as the luminance for the final output image. Sharp transitions from light to dark (or vice versa) become bright pixels in the result, due to the Sobel kernels emphasizing differences between pixels on either side of the center.

最终计算出来的这个值会用来作为输出图片中像素的亮度。因为索贝尔算子会着重两边像素亮度的不同，图片中由明转暗或者相反的突然转变会成为结果中明亮的像素。

There are slight variations to Sobel edge detection, such as Prewitt edge detection,[^2] that use different weights for the horizontal and vertical kernels, but they rely on the same basic process.

索贝尔边界探测有一些相似的变体，例如普里维特边界探测[^2]。普里维特边界探测会在横向竖向矩阵中使用不同的权重，但是他们运作的基本过程是一样的。

As an example for how this can be implemented in code, the following is an OpenGL ES fragment shader that performs Sobel edge detection:

作为一个例子索贝尔边界探测如何用代码实现，下面是一个 OpenGL ES 进行索贝尔边界探测的片断着色器

```glsl
precision mediump float;

varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
   float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
   float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
   float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
   float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
   float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
   float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
   float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
   float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;

   float h = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
   float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
   float mag = length(vec2(h, v));

   gl_FragColor = vec4(vec3(mag), 1.0);
}
```

The above shader has manual names for the pixels around the center one, passed in from a custom vertex shader, due to an optimization to reduce dependent texture reads on mobile devices. After these named pixels are sampled in a 3×3 grid, the horizontal and vertical Sobel kernels are applied using hand-coded calculations. The 0-weight entries are left out in order to simplify these calculations. The GLSL `length()` function calculates a Pythagorean hypotenuse between the results of the horizontal and vertical kernels. That magnitude value is then copied into the red, green, and blue channels of the output pixel to produce a grayscale indication of edge strength.

上面这段着色器中中心像素周围的像素都有用户定义的名称，是由一个自定义的顶点着色器提供的，这么做可以优化减少对移动设备环境的依赖。从3*3网格中抽样出这些命名了的像素，然后用自定义的代码来进行横向和纵向索贝尔探测。为简化计算权重为0的部分会被忽略。GLSL 函数 `length()` 计算出水平和垂直矩阵转化后值的平方和的平方根。然后这个代表量级的值会被拷贝进输出像素的红绿蓝通道中，这样就可以用来代表边界的明显程度。

## Canny Edge Detection

## 坎尼边界探测

Sobel edge detection can give you a good visual measure of edge strength in a scene, but it doesn't provide a yes/no indication of whether a pixel lies on an edge or not. For such a decision, you could apply a threshold of some sort, where pixels above a certain edge strength are considered to be part of an edge. However, this isn't ideal, because it tends to produce edges that are many pixels wide, and choosing an appropriate threshold can vary with the contents of an image.

索贝尔边界探测可以给你一张图片边界明显程度的直观印象，但是并不能明确地说明某一个像素是否是一个边界。如果要判断一个像素是否是一个边界，你要设定一个类似阈值的东西，亮度高于这个阈值的像素会被判定为边界的一部分。然而这样并不是最理想的，因为这样的做法判定出的边界可能会有好几个像素宽，并且不同的图片适合的阈值不同。

A more involved form of edge detection, called Canny edge detection,[^3] might be what you want here. Canny edge detection can produce connected, single-pixel-wide edges of objects in a scene:

这里你更需要一种叫做坎尼边界探测[^3]的边界探测方法。坎尼边界探测可以在一张图片中探测出连贯的只有一像素宽的边界：

<img src="http://img.objccn.io/issue-21/MV-Canny.png" style="width:240px" alt="Canny edge detection image"/>

The Canny edge detection process consists of a sequence of steps. First, like with Sobel edge detection (and the other techniques we'll discuss), the image needs to be converted to luminance before edge detection is applied to it. Once a grayscale luminance image has been obtained, a slight [Gaussian blur](http://www.sunsetlakesoftware.com/2013/10/21/optimizing-gaussian-blurs-mobile-gpu) is used to reduce the effect of sensor noise on the edges being detected.

坎尼边界探测包含了几个步骤。和索贝尔边界探测以及其他我们接下来将要讨论的方法一样，在进行边界探测之前首先图片需要转化成亮度图。一旦转化为灰阶亮度图紧接着进行一点点的[高斯模糊](http://www.sunsetlakesoftware.com/2013/10/21/optimizing-gaussian-blurs-mobile-gpu)，这么做是为了降低传感器噪音对边界探测的影响。

Once the image has been prepared, the edge detection can be performed. The specific GPU-accelerated process used here was originally described by Ensor and Hall in "GPU-based Image Analysis on Mobile Devices."[^4]

一旦图片已经准备好了，边界探测就可以开始进行。这里的 GPU 加速过程原本是在 Ensor 和 Hall 的文章 "GPU-based Image Analysis on Mobile Devices"[^4]中所描述的。

First, both the edge strength at a given pixel and the direction of the edge gradient are determined. The edge gradient is the direction in which the greatest change in luminance is occurring. This is perpendicular to the direction the edge itself is running.

首先，一个给定像素的边界明显程度和边界梯度要确定下来。边界梯度是指亮度发生变化最大的方向，也是边界延伸方向的垂直方向。

To find this, we use the Sobel kernel described in the previous section. The magnitude of the combined horizontal and vertical results gives the edge gradient strength, which is encoded in the red component of the output pixel. The horizontal and vertical Sobel results are then clamped to one of eight directions (corresponding to the eight pixels surrounding the central pixel), and the X component of that direction is encoded in the green component of the pixel. The Y component is placed into the blue component.

为了寻找边界梯度，我们要用到上一章中的索贝尔矩阵。索贝尔转化得到的横竖值加合后就是边界梯度的强度，这个值会编码进输出像素的红色通道。然后横向竖向索贝尔结果值会与八个方向（对应一个中心像素周围的八个像素）中的一个结合起来，一个方向上 X 部分值会作为输出像素的绿色通道值，Y 部分则作为蓝色通道值。

The shader used for this looks like the Sobel edge detection one above, only with the final calculation replaced with this code:

这个方法使用的着色器和索贝尔边界探测使用的类似，只是最后一个计算步骤用下面这段代码：

```glsl
	vec2 gradientDirection;
	gradientDirection.x = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
	gradientDirection.y = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;

	float gradientMagnitude = length(gradientDirection);
	vec2 normalizedDirection = normalize(gradientDirection);
	normalizedDirection = sign(normalizedDirection) * floor(abs(normalizedDirection) + 0.617316); // Offset by 1-sin(pi/8) to set to 0 if near axis, 1 if away
	normalizedDirection = (normalizedDirection + 1.0) * 0.5; // Place -1.0 - 1.0 within 0 - 1.0

	gl_FragColor = vec4(gradientMagnitude, normalizedDirection.x, normalizedDirection.y, 1.0);
```

To refine the Canny edges to be a single pixel wide, only the strongest parts of the edge are kept. For that, we need to find the local maximum of the edge gradient at each slice along its width.

为确保坎尼边界一像素宽，只有边界中强度最高的部分会被保留下来。因此，我们需要在每一个切面边界梯度的宽度之内寻找最大值。

This is where the gradient direction we calculated in the last step comes into play. For each pixel, we look at the nearest neighboring pixels both forward and backward along this length, and compare their calculated gradient strength (edge intensity). If the current pixel's gradient strength is greater than those of the ones forward and backward along the gradient, we keep that pixel. If the strength is less than either of the neighboring pixels, we reject that pixel and turn it to black.

这就是我们在上一步中算出的梯度方向起作用的地方。对每一个像素，我们根据梯度值向前和向后取出最近的相邻像素，然后对比他们的梯度强度（边界明显程度）。如果当前像素的梯度强度高于梯度方向前后的像素我们就保留当前像素。如果当前像素的梯度强度低于任何一个临近像素，我们就不再考虑这个像素并且将他变为黑色。

A shader to do this appears as follows:

执行这个步骤的着色器如下：

```glsl
precision mediump float;

varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform highp float texelWidth;
uniform highp float texelHeight;
uniform mediump float upperThreshold;
uniform mediump float lowerThreshold;

void main()
{
    vec3 currentGradientAndDirection = texture2D(inputImageTexture, textureCoordinate).rgb;
    vec2 gradientDirection = ((currentGradientAndDirection.gb * 2.0) - 1.0) * vec2(texelWidth, texelHeight);

    float firstSampledGradientMagnitude = texture2D(inputImageTexture, textureCoordinate + gradientDirection).r;
    float secondSampledGradientMagnitude = texture2D(inputImageTexture, textureCoordinate - gradientDirection).r;

    float multiplier = step(firstSampledGradientMagnitude, currentGradientAndDirection.r);
    multiplier = multiplier * step(secondSampledGradientMagnitude, currentGradientAndDirection.r);

    float thresholdCompliance = smoothstep(lowerThreshold, upperThreshold, currentGradientAndDirection.r);
    multiplier = multiplier * thresholdCompliance;

    gl_FragColor = vec4(multiplier, multiplier, multiplier, 1.0);
}
```

Here, `texelWidth` and `texelHeight` are the distances between neighboring pixels in the input texture, and `lowerThreshold` and `upperThreshold` set limits on the range of edge strengths we want to examine in this.

其中 `texelWidth` 和 `texelHeight` 是要处理的图片中临近像素之间的距离，`lowerThreshold` 和 `upperThreshold` 分别设定了我们预期的边界强度上下限。

As a last step in the Canny edge detection process, pixel gaps in the edges are filled in to complete edges that might have had a few points failing the threshold or non-maximum suppression tests. This cleans up the edges and helps to make them continuous.

在坎尼边界探测的最后一步，边界上出现像素间间隔的地方要被填充，出现间隔是因为有一些点不在阈值范围之内或者是因为非最大值转化没有起作用。这一步会完善边界使边界连续起来。

This last step looks at all the pixels around a central pixel. If the center was a strong pixel from the previous non-maximum suppression step, it remains a white pixel. If it was a completely suppressed pixel, it stays as a black pixel. For middling grey pixels, the neighborhood around them is evaluated. Each one touched by more than one white pixel becomes a white pixel. If not, they go to black. This fills in the gaps in detected edges.

在最后一步中需要考虑一个像素周围的所有像素。如果这个中心像素是最大值，上一步中非最大值转化就不会影响他，他依然是白色。如果它不是最大值，就会变成黑色。对于中间的灰色像素，会考察他周围像素的信息。凡是与超过一个白色像素挨着的都会变为白色，相反就会变成黑色。这样就可以将边界分离的部分接合起来。

As you can tell, the Canny edge detection process is much more involved than Sobel edge detection, but it can yield nice, clean lines tracing around the edges of objects. This gives a good starting point for line detection, contour detection, or other image analysis, and can also be used to produce some interesting aesthetic effects.

正如你所看到的，坎尼边界探测会比索贝尔边界探测更复杂一些，但是它会探测出一条物品边界的干净线条。这是线条探测，轮廓探测或者其他图片分析很好的起点。同时也可以被用来生成一些有趣的美学效果。

## Harris Corner Detection

## 哈里斯边角探测

While the previous edge detection techniques can extract some information about an image, the result is an image with visual clues about the locations of edges, not higher-level information about what is present in a scene. For that, we need algorithms that process the pixels within a scene and return more descriptive information about what is shown.

虽然利用上一章中的边界探测技术我们可以获取关于图片边界的信息，我们会得到一张可以直观观察到边界所在位置的图片，但是并没有更高层面有关图片中所展示内容的信息。为了得到这些信息，我们需要一个可以处理场景中的像素然后返回场景中所展示内容的描述性信息的算法。

A popular starting point for object detection and matching is feature detection. Features are points of interest in a scene — locations that can be used to uniquely identify structures or objects. Corners are commonly used as features, due to the information contained in the pattern of abrupt changes in lighting and/or color around a corner.

进行物体探测和匹配时一个常见的出发点是特征探测。特征是指一个场景中具有特殊意义的点，这些点可以唯一的区分出一些结构或者物体。由于边角的出现往往意味着亮度或者颜色的突然变化，所以边角常常会作为特征的一种。

One technique for detecting corners was proposed by Harris and Stephens in "A Combined Corner and Edge Detector."[^5] This so-called Harris corner detector uses a multi-step process to identify corners within scenes.

在 Harris 和 Stephens 的文章 "A Combined Corner and Edge Detector."[^5] 中他们提出一个边角探测的方法。这个命名为哈里斯边角探测的方法采用了一个多步骤的方法来探测场景中的边角。

As with the other processes we've talked about, the image is first reduced to luminance. The X and Y gradients around a pixel are determined using a Sobel, Prewitt, or related kernel, but they aren't combined to yield a total edge magnitude. Instead, the X gradient strength is passed along in the red color component, the Y gradient strength in the green, and the product of the X and Y gradient strengths in the blue component.

像我们已经讨论过的其他方法一样，图片首先需要减薄到只剩亮度信息。通过索贝尔矩阵，普里维特矩阵或者其他相关的矩阵计算出一个像素 X 和 Y 方向上的梯度值，计算出的值并不会合并为边界的量级。而是将 X 梯度传入红色部分，Y 梯度传入绿色部分，XY 梯度的乘积传入蓝色部分。

A Gaussian blur is then applied to the result of that calculation. The values encoded in the red, green, and blue components are extracted from that blurred image and used to populate the variables of an equation for calculating the likelihood that a pixel is a corner point:

然后对上述计算结果进行一个高斯模糊。从模糊后的照片中取出红绿蓝不同部分的值，并将值带入一个计算像素是边角点可能性的公式：

R = I<sub>x</sub><sup>2</sup> × I<sub>y</sub><sup>2</sup> − I<sub>xy</sub> × I<sub>xy</sub> − k × (I<sub>x</sub><sup>2</sup> + I<sub>y</sub><sup>2</sup>)<sup>2</sup>

Here, I<sub>x</sub> is the gradient intensity in the X direction (the red component in the blurred image), I<sub>y</sub> is the gradient intensity in Y (the green component), I<sub>xy</sub> is the product of these intensities (the blue component), k is a scaling factor for sensitivity, and R is the resulting "cornerness" of the pixel. Alternative implementations of this calculation have been proposed by Shi and Tomasi[^6] and Noble,[^7] but the results tend to be fairly similar.

其中 I<sub>x</sub> 是 X 方向梯度值（模糊后图片中红色部分），I<sub>y</sub> 是 Y 梯度值（绿色部分），I<sub>xy</sub> 是 XY 值的乘积（蓝色部分），k 是一个灵敏性常数，R  是计算出来的这个像素是边角的确定程度。Shi，Tomasi[^6] 和 Noble[^7] 提出过这种计算的另一种实现方法但是结果其实是十分接近的。

Looking at this equation, you might think that the first two terms should cancel themselves out. That's where the Gaussian blur of the previous step matters. By blurring the X, Y, and product of X and Y values independently across several pixels, differences develop around corners and allow for them to be detected.

在公式中你可以会觉得头两项会抵消掉。但这就是前面高斯模糊那一步起作用的地方。通过在一些像素上分别模糊 X Y 和 XY 的乘积，在边角附近就会出现可以被探测到的差异。

Here we start with a test image drawn from [this question on the Signal Processing Stack Exchange site](http://dsp.stackexchange.com/questions/401/how-to-detect-corners-in-a-binary-images-with-opengl):

我们从 Stack Exchange 信号处理分站中的[一个问题](http://dsp.stackexchange.com/questions/401/how-to-detect-corners-in-a-binary-images-with-opengl)中取来一张测试图片：

<img src="http://img.objccn.io/issue-21/MV-HarrisSquares.png" alt="Harris corner detector test image"/>

The resulting cornerness map from the above calculation looks something like this:

经过前面的计算过程得到的结果如下图：

<img src="http://img.objccn.io/issue-21/MV-HarrisCornerness.png" alt="Harris cornerness intermediate image"/>

To find the exact location of corners within this map, we need to pick out local maxima (pixels of highest brightness in a region). A non-maximum suppression filter is used for this. Similar to what we did with the Canny edge detection, we now look at pixels surrounding a central one (starting at a one-pixel radius, but this can be expanded), and only keep a pixel if it is brighter than all of its neighbors. We turn it to black otherwise. This should leave behind only the brightest pixels in a general region, or those most likely to be corners.

为了找出边角准确的位置，我们需要选出极点（一个区域内亮度最高的地方）。这里需要使用一个非最大值转化。和我们在坎尼边界探测中所做的一样，我们要考察一个中心像素周围的临近像素（从一个像素半径开始，半径可以扩大），只有当中心像素的亮度高于他所有临近像素时才保留他，否则就将这个像素变为黑色。这样一来最后留下的就应该是一片区域中亮度最高的像素，也就是最可能是边角的地方。

From that, we now can read the image and see that any non-black pixel is a location of a corner:

通过这个过程，我们现在可以从图片中看到任意不是黑色的像素都是一个边角所在的位置：

<img src="http://img.objccn.io/issue-21/MV-HarrisCorners.png" alt="Harris corners"/>

I'm currently doing this point extraction stage on the CPU, which can be a bottleneck in the corner detection process, but it may be possible to accelerate this on the GPU using histogram pyramids.[^8]

目前我是使用 CPU 来进行点的提取，这可能会是边角探测的一个瓶颈，不过在 GPU 上使用柱状图金字塔[^8]可能会加速这个过程。

The Harris corner detector is but one means of finding corners within a scene. Edward Rosten's FAST corner detector, as described in "Machine learning for high-speed corner detection,"[^9] is a higher-performance corner detector that may also outpace the Harris detector for GPU-bound feature detection.

哈里斯边角探测只是在场景中寻找边角的方法之一。"Machine learning for high-speed corner detection,"[^9] 中 Edward Rosten 的 FAST 边角探测方法是另一个性能更好的方法，即使是基于 GPU 的特征探测依然会更快。

## Hough Transform Line Detection

## 霍夫变换线段探测

Straight lines are another large-scale feature we might want to detect in a scene. Finding straight lines can be useful in applications ranging from document scanning to barcode reading. However, traditional means of detecting lines within a scene haven't been amenable to implementation on a GPU, particularly on mobile GPUs.

笔直的线段是另一种我们会在一个场景需要探测的常见的特征。寻找笔直的线段可以帮助应用进行文档扫描和条形码读取。然而，传统的线段探测方法并不适合在 GPU 上实现，特别是在移动设备的 GPU 上。

Many line detection processes are based on a Hough transform, which is a technique where points in a real-world, Cartesian coordinate space are converted to another coordinate space. Calculations are then performed in this alternate coordinate space and the results converted back into normal space to determine the location of lines or other features. Unfortunately, many of these proposed calculations aren't suited for being run on a GPU because they aren't sufficiently parallel in nature and they require intense mathematical operations, like trigonometry functions, to be performed at each pixel.

许多线段探测过程都基于霍夫变换，这是一项将真实世界笛卡尔直角坐标空间中的点转化到另一个坐标空间中去的技术。转化之后在另一个坐标空间中进行计算，计算的结果又转化回正常空间代表线段的位置或者其他特征信息。不幸的是，许多已经提出的计算方法都不适合在 GPU 上运行，因为他们不太可能充分并行执行，并且都需要大量的数学计算，比如在每个像素上进行三角函数计算。

In 2011, Dubská, *et al.*[^10] [^11]</sup> proposed a much simpler, more elegant way of performing this coordinate space transformation and analysis — one that was ideally suited to being run on a GPU. Their process relies on a concept called parallel coordinate space, which sounds completely abstract, but I'll show how it's actually fairly simple to understand.

2011年，Dubská, *et al.*[^10] [^11]</sup> 提出了一种更简单并更有效的坐标空间转换方法和分析方法，这种方法更合适在 GPU 上运行。他们的方法依赖与一个叫做平行坐标空间的概念，听上去很抽象但是我会展示出它其实很容易理解。

Let's take a line and pick three points within it:

我们首先选择一条线段和线段上的三个点：

<img src="http://img.objccn.io/issue-21/MV-ParallelCoordinateSpace.png" alt="An example line"/>

To transform this to parallel coordinate space, we'll draw three parallel vertical axes. On the center axis, we'll take the X components of our line points and draw points at 1, 2, and 3 steps up from zero. On the left axis, we'll take the Y components of our line points and draw points at 3, 5, and 7 steps up from zero. On the right axis, we'll do the same, only we'll make the Y values negative.

要将这条线段转化到平行坐标空间去，我们需要画出三个平行的垂直轴。在中间的轴上，我们选取三个点在 X 轴上的值在 1，2，3 处画一个点，在左边的轴上，我们选取三个点在 Y 轴上的值在 3，5，7 处画一个点。在右边的轴上我们做同样的事情，但是取 Y 轴的负值。

We'll then connect the Y component points to the corresponding X coordinate component on the center axis. That creates a drawing like the following:

接下来我们将代表 Y 轴值的点和它对应的 X 轴值连接起来。连接后的效果像下图：

<img src="http://img.objccn.io/issue-21/MV-ParallelCoordinateTransform.png" alt="Points transformed into parallel coordinate space"/>

You'll notice that the three lines on the right intersect at a point. This point determines the slope and intercept of our line in real space. If we had a line that sloped downward, we'd have an intersection on the left half of this graph.

你会注意到在右边的三条线会相交于一点。这个点的坐标值代表了在真实空间中线段的斜率和截距。如果我们用一个向下斜的线段，那么相交会发生在图的左半边。

If we take the distance from the center axis and call that u (2 in this case), take the vertical distance from zero and call that v (1/3 in this case), and then label the width between our axes d (6, based on how I spaced the axes in this drawing), we can calculate slope and Y-intercept using the following equations:

如果我们取交点到中间轴的距离作为 u（在这个例子中是2），取竖直方向到0的距离作为 v（这里是1/3），将轴之间的距离作为 d （这个例子中我使用的距离是6），我们可以用这样的公式计算斜率和截距

slope = −1 + d/u<br>
intercept = d × v/u

The slope is thus 2, and the Y-intercept 1, matching what we drew in our line above.

斜率是2，截距是1，和上面我们所画的线段一致。

GPUs are excellent at this kind of simple, ordered line drawing, so this is an ideal means of performing line detection on the GPU.

这种简单有序的线段绘画非常适合 GPU 进行，所以这种方法是一种利用 GPU 进行线段探测理想的方式。

The first step in detecting lines within a scene is finding the points that potentially indicate a line. We're looking for points on edges, and we want to minimize the number of points we're analyzing, so the previously described Canny edge detection is an excellent starting point.

探测线段的第一步是寻找可能代表一个线段的点。我们寻找的是位于边界位置的点，并且我们希望限制需要分析的点的数量，所以之前谈论的坎尼边界探测是一个非常好的起点。

After the edge detection, the edge points are read and used to draw lines in parallel coordinate space. Each edge point has two lines drawn for it, one between the center and left axes, and one between the center and right axes. We use an additive blending mode so that pixels where lines intersect get brighter and brighter. The points of greatest brightness in an area indicate lines.

进行边界探测之后，边界点被用来在平行坐标空间进行画线。每一个边界点会画两条线，一条在中间轴和左边轴之间，另一条在中间轴和右边轴之间。我们使用一种混合添加的方式使线段的交点变得更亮。在一片区域内最亮的点代表了线段。

For example, we can start with this test image:

举例来说，我们可以从这张测试图片开始：

<img src="http://img.objccn.io/issue-21/MV-HoughSampleImage.png" alt="Sample image for line detection"/>

And this is what we get in parallel coordinate space (I've shifted the negative half upward to halve the Y space needed):

下面是我们在平行坐标空间中得到的（我已经将负值对称过来使图片高度减半）

<img src="http://img.objccn.io/issue-21/MV-HoughParallel.png" alt="Hough parallel coordinate space"/>

Those bright central points are where we detect lines. A non-maximum suppression filter is then used to find the local maxima and reduce everything else to black. From there, the points are converted back to line slopes and intercepts, yielding this result:

图中的亮点就是我们探测到线段的地方。进行一个非最大值转化来找到区域最值并将其他地方变为黑色。然后，点被转化回线段的斜率和截距，得到下面的结果：

<img src="http://img.objccn.io/issue-21/MV-HoughLines.png" alt="Hough transform line detection"/>

I should point out that the non-maximum suppression is one of the weaker points in the current implementation of this within GPUImage. It causes lines to be detected where there are none, or multiple lines to be detected near strong lines in a noisy scene.

我必须指出在 GPUImage 中这个非最大值转换过程是一个薄弱的环节。它可能会导致错误的探测出线段，或者在有噪点的地方将一条线段探测为多条线段。

As mentioned earlier, line detection has a number of interesting applications. One particular application this enables is one-dimensional barcode reading. An interesting aspect of this parallel coordinate transform is that parallel lines in real space will always appear as a series of vertically aligned dots in parallel coordinate space. This is true no matter the orientation of the parallel lines. That means that you could potentially detect standard 1-D barcodes at any orientation or position by looking for a specific ordered spacing of vertical dots. This could be a huge benefit for blind users of mobile phone barcode scanners who cannot see the box or orientation they need to align barcodes within.

正如之前所提到的，线段探测有许多有趣的应用。其中一种就是条形码识别。有关平行坐标空间转换有趣的一点是，在真实空间中平行的线段转换到平行坐标空间中后是垂直对齐的一排点。不论平行线段是怎样的都一样。这就意味着你可以通过一排有特定顺序间距的点来探测出条形码无论条形码是怎样摆放的。这对于有视力障碍的手机用户进行条形码扫描是有巨大帮助的，毕竟他们无法看到盒子也很难将条形码对齐。

Personally, the geometric elegance of this line drawing process is something I find fascinating and wanted to present to more developers.

对我而言，这种线段探测过程中的几何学优雅是令我感到十分着迷的，我希望将他介绍给更多开发者。

## Summary

## 小结

These are but some of the many machine vision operations that have been developed in the last few decades, and only a small portion of the ones that can be adapted to work well on a GPU. I personally think there is exciting and groundbreaking work left to be done in this area, with important applications that can improve the way of life for many people. Hopefully, this has at least provided a brief introduction to the field of machine vision and shown that it's not as impenetrable as many developers believe.

这些就是在过去几年中发展出来的机器视觉方法中的几个，仅仅是适合在 GPU 上工作的方法中的一部分。我个人认为在这个领域还有着令人激动的开创性工作要去做，将会诞生可以提高许多人生活质量的应用。希望这篇文章至少为你提供了一个机器视觉领域简要的总体介绍，并且展示了这个领域并不是许多开发者想象的那样无法进入。

[^1]: I. Sobel. An Isotropic 3x3 Gradient Operator, Machine Vision for Three-Dimensional Scenes, Academic Press, 1990.

[^2]: J.M.S. Prewitt. Object Enhancement and Extraction, Picture processing and Psychopictorics, Academic Press, 1970.

[^3]: J. Canny. A Computational Approach To Edge Detection, IEEE Trans. Pattern Analysis and Machine Intelligence, 8(6):679–698, 1986.

[^4]: A. Ensor, S. Hall. GPU-based Image Analysis on Mobile Devices. Proceedings of Image and Vision Computing New Zealand 2011.

[^5]: C. Harris and M. Stephens. A Combined Corner and Edge Detector. Proc. Alvey Vision Conf., Univ. Manchester, pp. 147-151, 1988.

[^6]: J. Shi and C. Tomasi. Good features to track. Proceedings of the IEEE Conference on Computer Vision and Pattern Recognition, pages 593-600, June 1994.

[^7]: A. Noble. Descriptions of Image Surfaces. PhD thesis, Department of Engineering Science, Oxford University 1989, p45.

[^8]: G. Ziegler, A. Tevs, C. Theobalt, H.-P. Seidel. GPU Point List Generation through HistogramPyramids. Research Report, Max-Planck-Institut fur Informatik, 2006.

[^9]: E. Rosten and T. Drummond. Machine learning for high-speed corner detection. European Conference on Computer Vision 2006.

[^10]: M. Dubská, J. Havel, and A. Herout. [Real-Time Detection of Lines using Parallel Coordinates and OpenGL](http://medusa.fit.vutbr.cz/public/data/papers/2011-SCCG-Dubska-Real-Time-Line-Detection-Using-PC-and-OpenGL.pdf). Proceedings of SCCG 2011, Bratislava, SK, p. 7.

[^11]: M. Dubská, J. Havel, and A. Herout. [PClines — Line detection using parallel coordinates](http://medusa.fit.vutbr.cz/public/data/papers/2011-CVPR-Dubska-PClines.pdf). 2011 IEEE Conference on Computer Vision and Pattern Recognition (CVPR), p. 1489- 1494.
