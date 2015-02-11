## Core Image 介绍

This article is a beginner's introduction to Core Image, an image processing framework for OS X and iOS.

这篇文章是为初学者介绍一下 Core Image，一个为 OS X 和 iOS 处理图像的框架。

If you would like to follow along with the code in this article, you can download [the sample project at GitHub](https://github.com/objcio/issue-21-core-image-explorer). The sample project is an iOS app that lists a large selection of system-provided image filters, and provides a UI for tweaking their parameters and observing the effects.

如果你想跟着本文中的代码学习，你可以在 GitHub 上下载[示例工程](https://github.com/objcio/issue-21-core-image-explorer)。示例工程是一个 iOS 应用程序，列出了系统提供的大量图像滤镜以供选择，并提供了一个用户界面用来调整参数并观察效果。

Although the sample code is written in Swift for iOS, the concepts transfer readily to Objective-C and OS X.

虽然示例代码是用 Swift 写的 iOS 程序，不过实现概念很容易转换到 Objective-C 和 OS X.

## Fundamental Concepts

## 基本概念

To talk about Core Image, we first need to introduce a few fundamental concepts.

说到 Core Image，我们首先需要介绍几个基本的概念。

A _filter_ is an object that has a number of inputs and outputs and performs some kind of transformation. For example, a blur filter might take an input image and a blur radius and produce an appropriately blurred output image.

一个 _滤镜_ 是一个对象，有很多输入和输出，并执行一些变换。例如，模糊滤镜可能需要输入图像和一个模糊半径来产生适当的模糊后的输出图像。

A _filter graph_ is a network ([directed acyclic graph](http://en.wikipedia.org/wiki/Directed_acyclic_graph)) of filters, chained together so that the output of one filter can be the input of another. In this way, elaborate effects can be achieved. We'll see below how to connect filters to create a vintage photographic effect.

一个 _滤镜图表_ 是一个链接在一起的滤镜网络（[无回路有向图](http://en.wikipedia.org/wiki/Directed_acyclic_graph)），使得一个滤镜的输出可以是另一个滤镜的输入。以这种方式，可以实现精心制作的效果。我们将在下面看到如何连接滤镜来创建一个复古的拍照效果。

## Getting Acquainted with the Core Image API

## 熟悉 Core Image API

With these concepts in our toolkit, we can start to explore the specifics of image filtering with Core Image.

有了上述的这些概念，我们可以开始探索 Core Image 的图像滤镜细节了。

### Core Image Architecture

### Core Image 结构

Core Image has a plug-in architecture, which means that it allows users to extend its functionality by writing custom filters that integrate with the system-provided filters. We will not be taking advantage of Core Image's extensibility in this article; I mention it only because it influences the API of the framework.

Core Image 有一个插件架构，这意味着它允许用户编写自定义的滤镜并与系统提供的滤镜集成来扩展其功能。我们在这篇文章中不会用到 Core Image 的可扩展性；我提到它只是因为它影响到了框架的 API。

Core Image is written to make the most of the hardware on which it is running. The actual implementation of each filter, the _kernel_, is written in a [subset](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CIKernelLangRef/Introduction/Introduction.html) of [GLSL](https://www.opengl.org/documentation/glsl/), the shading language of OpenGL. When multiple filters are connected to form a filter graph, Core Image strings together these kernels to build one efficient program that can be run on the GPU.

Core Image 是用来最大化利用其所运行之上的硬件的。每个滤镜实际上做的事情，即 _内核_，是被写入一个 [GLSL](https://www.opengl.org/documentation/glsl/) 的[子集](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CIKernelLangRef/Introduction/Introduction.html)，即 OpenGL 的着色语言。当多个滤镜连接成一个滤镜图表，Core Image 便把内核串在一起来构建一个可在 GPU 上运行的高效程序。

Whenever possible, Core Image defers work until the future. Oftentimes, no allocations or processing will take place until the output of the final filter in a filter graph is requested.

只要有可能，Core Image 都会把工作延迟。通常情况下，直到滤镜图表的最后一个滤镜的输出被请求之前都不会发生分配或处理。

In order to do work, Core Image requires an object called a _context_. The context is the actual workhorse of the framework, allocating the necessary memory and compiling and running the filter kernels that do the image processing. Contexts are very expensive to create, so you will most often want to create one context and use it repeatedly. We will see how to create a context below.

为了完成工作，Core Image 需要一个称为 _context_ 的对象。这个上下文是框架真正的重负荷，需要分配必要的存储器，并编译和运行滤镜内核来执行图像处理。建立一个上下文是非常昂贵的，所以你会经常想创建一个反复使用的上下文。接下来我们将看到如何创建一个上下文。

### Querying for Available Filters

### 查询可用的滤镜

Core Image filters are created by name. To get a list of system filters, we ask Core Image for the names of filters in the `kCICategoryBuiltIn` category:

Core Image 滤镜是按名字创建的。要获得系统滤镜的列表，我们要向 Core Image 的 `kCICategoryBuiltIn` 类别请求得到滤镜的名字：

```
let filterNames = CIFilter.filterNamesInCategory(kCICategoryBuiltIn) as [String]
```

The list of filters available on iOS is very nearly a subset of the filters available on OS X. There are 169 built-in filters on OS X, and there are 127 on iOS.

iOS 上可用的滤镜列表非常接近于 OS X 上可用滤镜的一个子集。在 OS X 上有 169 个内置滤镜，在 iOS 上有 127 个。

### Creating a Filter by Name

### 通过名字创建一个滤镜

Now that we have a list of available filters, we can create and use a filter. For example, to create a Gaussian blur filter, we pass the filter name to the appropriate `CIFilter` initializer:

现在，我们有了可用滤镜的列表，我们就可以创建和使用滤镜了。例如，要创建一个高斯模糊滤镜，我们传给 `CIFilter` 初始化方法相应的名称就可以了：

```
let blurFilter = CIFilter(named:"CIGaussianBlur")
```

### Setting Filter Parameters

### 设置滤镜参数

Because of Core Image's plug-in structure, most filter properties are not set directly, but with key-value coding (KVC). For example, to set the blur radius of the blur filter, we use KVC to set its `inputRadius` property:

由于 Core Image 的插件结构，大多数滤镜属性并不是直接设置的，而是通过键值编码（KVC）设置。例如，要设置模糊滤镜的模糊半径，我们使用 KVC 来设置 `inputRadius` 属性：

```
blurFilter.setValue(10.0 forKey:"inputRadius")
```

Since this method takes `AnyObject?` (`id` in Objective-C) as its value parameter, it is not particularly type safe. Therefore, setting filter parameters requires some vigilance to ensure that you are passing the expected type.

由于这种方法需要 `AnyObject?` （即 Objective-C 里的 `id`）作为其参数值，它不是类型安全的。因此，设置滤镜参数需要谨慎一些，确保你传值的类型是正确的。

### Querying Filter Attributes

### 查询滤镜属性

To know what input and output parameters are offered by a filter, we can ask for its `inputKeys` and `outputKeys` arrays, respectively. These each return an array of `NSString`s.

为了知道一个滤镜提供什么样的输入和输出参数，我们就可以分别获取 `inputKeys` 和 `outputKeys` 数组。它们都返回 `NSString` 的数组。

To get more information about each parameter, we can look in the `attributes` dictionary provided by the filter. Each input and output parameter name maps to a dictionary of its own, describing what kind of parameter it is, and its minimum and maximum values, if applicable. For example, here is the dictionary corresponding to the `inputBrightness` parameter of the `CIColorControls` filter:

要获取每个参数的详细信息，我们可以看看由滤镜提供的 `attributes` 字典。每个输入和输出参数名映射到它自己的字典里，描述了它是什么样的参数，如果有的话还会给出它的最大值和最小值。例如，下面是 `CIColorControls` 滤镜对应的 `inputBrightness` 参数字典：

```
inputBrightness = {
    CIAttributeClass = NSNumber;
    CIAttributeDefault = 0;
    CIAttributeIdentity = 0;
    CIAttributeMin = -1;
    CIAttributeSliderMax = 1;
    CIAttributeSliderMin = -1;
    CIAttributeType = CIAttributeTypeScalar;
};
```

For numerical parameters, the dictionary will contain `kCIAttributeSliderMin` and `kCIAttributeSliderMax` keys, which bound the expected input quantities. Most parameters also contain a `kCIAttributeDefault` key, which maps to the default value of the parameter.

对于数值参数，该字典会包含 `kCIAttributeSliderMin` 和 `kCIAttributeSliderMax` 关键字，来限制期望的输入域。大多数参数还包含一个 `kCIAttributeDefault` 关键字，映射到该参数的默认值。

## Filtering an Image in Practice

## 图片滤镜实战

The work of filtering an image consists of three parts: building and configuring a filter graph, sending an image in to be filtered, and retrieving the filtered image. The sections below cover this in detail.

图像滤镜的工作由三部分组成：构建和配置滤镜图表，发送等待滤镜处理的图像，得到滤镜处理后的图像。下面的部分对此进行了详细描述。

### Building a Filter Graph

### 构建一个滤镜图表

Building a filter graph consists of instantiating filters to do the kind of work we want to perform, setting their parameters, and wiring them up so that the image data flows through each filter in turn.

构建一个滤镜图表由这几个部分组成：实例化我们需要的滤镜，设置它们的参数，把它们连接起来以便该图像数据按顺序传过每个滤镜。

In this section, we will construct a filter graph for producing images in the style of a 19th-century tintype photograph. We will chain together two effects to create this effect: a monochrome filter to simultaneously desaturate and tint the image, and a vignette filter to create a shadow effect that frames the image.

在本节中，我们将创建一个用来制作 19 世纪锡版照风格图像的滤镜图表。我们将两个效果链在一起来达到这种效果：同时去饱和以及染色调的黑白滤镜，和一个暗角滤镜来创建一个有阴影效果的加框图片。

Quartz Composer, available for [download from the Apple Developer website](https://developer.apple.com/downloads/index.action?name=Graphics), is useful for prototyping Core Image filter graphs. Below, we have composed the desired photo filter by wiring together the Color Monochrome filter and the Vignette filter:

用 Quartz Composer，来做 Core Image 滤镜图表的原型非常有用，可以[从苹果开发者网站下载](https://developer.apple.com/downloads/index.action?name=Graphics)。下面，我们整理了所需的照片滤镜，把黑白滤镜和暗角滤镜串在一起：

![A filter graph built with Quartz Composer, showing intermediate filtered images](http://img.objccn.io/issue-21/quartz.png)

Once we're satisfied with the effect, we can recreate the filter graph in code:

一旦达到了我们满意的效果，我们可以重新在代码里创建滤镜图表：

```
let sepiaColor = CIColor(red: 0.76, green: 0.65, blue: 0.54)
let monochromeFilter = CIFilter(name: "CIColorMonochrome",
    withInputParameters: ["inputColor" : sepiaColor, "inputIntensity" : 1.0])
monochromeFilter.setValue(inputImage, forKey: "inputImage")

let vignetteFilter = CIFilter(name: "CIVignette",
    withInputParameters: ["inputRadius" : 1.75, "inputIntensity" : 1.0])
vignetteFilter.setValue(monochromeFilter.outputImage, forKey: "inputImage")

let outputImage = vignetteFilter.outputImage
```

Note that the output image of the monochrome filter becomes the input image of the vignette filter. This causes the vignette to be applied to the tinted monochrome image. Also note that we can specify parameters in the initializer, instead of setting them individually with KVC.

需要注意的是黑白滤镜的输出图像变为暗角滤镜的输入图像。这将导致暗角效果要应用到黑白图像上。还要注意的是，我们可以在初始化中指定参数，而不是用 KVC 单独设置它们。

### Creating the Input Image

### 创建输入图像

Core Image filters require that their input image be of type `CIImage`. For iOS programmers who are used to `UIImage`, this may be a little unusual, but the distinction is merited. A `CIImage` is actually a more general entity than a `UIImage`, since a `CIImage` may have infinite extent. Obviously, we can't store an infinite image in memory, but conceptually, this means that you can request image data from an arbitrary region in the 2D plane and get back a meaningful result.

Core Image 滤镜要求其输入图像是 `CIImage` 类型。而对于 iOS 的程序员来说这可能会有一点不寻常，因为他们更习惯用 `UIImage`，但这个区别是值得的。一个 `CIImage` 实例实际上比 `UIImage` 更全面，因为 `CIImage` 可以无限大。当然，我们不能存储无限的图像在内存中，但在概念上，这意味着你可以从 2D 平面上的任意区域获取图像数据，并得到一个有意义的结果。

All of the images we will be using in this article are finite, and it's easy enough to create a `CIImage` from a `UIImage`. In fact, it's just one line of code:

所有我们在本文中使用的图像都是有限的，而且也可以很容易从一个 `UIImage` 来创建一个 `CIImage`。事实上，这只需要一行代码：

```
let inputImage = CIImage(image: uiImage)
```

There are also convenience initializers for creating `CIImage`s directly from image data or a file URL.

也有很方便的初始化方法直接从图像数据或文件 URL 来创建 `CIImage`。

Once we have a `CIImage`, we can set it as the input image of the filter graph by setting the `inputImage` parameter of the filter:

一旦我们有了一个 `CIImage`，我们就可以通过设置滤镜的 `inputImage` 参数来将其设置为滤镜的输入图像：

```
filter.setValue(inputImage, forKey:"inputImage")
```

### Fetching a Filtered Image

### 得到一个滤镜处理后的图片

Filters have a property named `outputImage`. As you might guess, it has type `CIImage`. So how do we perform the inverse operation of creating a `UIImage` from a `CIImage`? Well, although we've spent all our time thus far building up a filter graph, now is the time to invoke the power of the `CIContext` and do the actual work of filtering the image.

滤镜都有一个名为 `outputImage` 的属性。正如你可能已经猜到的一样，它是 `CIImage` 类型的。那么，我们如何实现从一个 `CIImage` 创建 `UIImage` 的反向操作？好了，虽然我们到此已经花了所有的时间建立一个滤镜图表，现在是调用 `CIContext` 的力量来实际的做图像滤镜处理工作的时候了。

The simplest way to create a context is to pass a nil options dictionary to its constructor:

创建一个上下文最简单的方法是给它的构造方法传一个 nil 字典：

```
let ciContext = CIContext(options: nil)
```

To get an image out of the filter graph, we ask our `CIContext` to create a `CGImage` from a rect in the output image, passing the extent (bounds) of the input image:

为了得到一个滤镜处理过的图像，我们需要 `CIContext` 从输出图像的一个矩形内创建一个 `CGImage`，传入输入图像的范围（bounds）：

```
let cgImage = ciContext.createCGImage(filter.outputImage, fromRect: inputImage.extent())
```

The reason we use the input image's extent is that the output image often has different dimensions than the input image. For example, a blurred image has some extra pixels around its border, due to sampling beyond the edge of the input image.

我们使用输入图像大小的原因是，输出图像通常和输入图像具有不同的尺寸比。例如，一个模糊图像由于采样超出了输入图像的边缘，围绕在其边界外还会有一些额外的像素。

We can now create a `UIImage` from this newly-created `CGImage`:

现在，我们可以从这个新创建的 `CGImage` 来创建一个 `UIImage` 了：

```
let uiImage = UIImage(CGImage: cgImage)
```

It is possible to create a `UIImage` directly from a `CIImage`, but this approach is fraught: if you try to display such an image in a `UIImageView`, its `contentMode` property will be ignored. Using an intermediate `CGImage` takes an extra step, but obviates this annoyance.

可以直接从一个 `CIImage` 创建 `UIImage`，但这种方法有点让人郁闷：如果你试图在一个 `UIImageView` 上显示这样的图像，其 `contentMode` 属性将被忽略。使用过渡的 `CGImage` 则需要一个额外的步骤，但最好省却这一烦恼。

### Improving Performance with OpenGL

### 用 OpenGL 来提高性能

It's time-consuming and wasteful to use the CPU to draw a `CGImage`, only to hand the result right back to UIKit for compositing. We'd prefer to be able to draw the filtered image to the screen without having to take a trip through Core Graphics. Fortunately, because of the interoperability of OpenGL and Core Image, we can do exactly that.

用 CPU 来绘制一个 `CGImage` 是非常耗时和浪费的，它只将结果回传给 UIKit 来做合成。我们更希望能够在屏幕上绘制应用滤镜后的图像，而不必去 Core Graphics 里绕一圈。幸运的是，由于 OpenGL 和 Core Image 的可互操作性，我们可以这么做。

To share resources between an OpenGL context and a Core Image context, we need to create our `CIContext` in a slightly different way:

要 OpenGL 上下文和 Core Image 上下文之间共享资源，我们需要用一个稍微不同的方式来创建我们的 `CIContext`：

```
let eaglContext = EAGLContext(API: .OpenGLES2)
let ciContext = CIContext(EAGLContext: context)
```

Here, we create an `EAGLContext` with the OpenGL ES 2.0 feature set. This GL context can be used as the backing context for a `GLKView` or for drawing into a `CAEAGLLayer`. The sample code uses this technique to draw images efficiently.

在这里，我们用 OpenGL ES 2.0 的功能集创建了一个 `EAGLContext`。这个 GL 上下文可以用作一个 `GLKView` 的背衬上下文或用来绘制成一个 `CAEAGLLayer`。示例代码使用这种技术来有效地绘制图像。

When a `CIContext` has an associated GL context, a filtered image can be drawn with OpenGL using the following call:

当一个 `CIContext` 具有了关联 GL 的上下文，滤镜处理后的图像就可用 OpenGL 来绘制，像如下这样调用方法：

```
ciContext.drawImage(filter.outputImage, inRect: outputBounds, fromRect: inputBounds)
```

As before, the `fromRect` parameter is the portion of the image to draw in the filtered image's coordinate space. The `inRect` parameter is the rectangle in the coordinate space of the GL context into which the image should be drawn. If you want to respect the aspect ratio of the image, you may need to do some math to compute the appropriate `inRect`.

与以前一样，`fromRect` 参数是用滤镜处理后的图像的坐标空间来绘制的图像的一部分。这个 `inRect` 参数是 GL 上下文的坐标空间的矩形应用到需要绘制图像上。如果你想保持图像的长宽比，你可能需要做一些数学计算来得到适当的 `inRect`。

### Forcing Filtering onto the CPU

### 强制在 CPU 上做滤镜操作

Whenever possible, Core Image will perform filtering on the GPU. However, it does have the ability to fall back to the CPU. Filtering done on the CPU may have better accuracy, since GPUs often exchange some fidelity for speed in their floating-point calculations. You can force Core Image to run on the CPU by setting the value of the `kCIContextUseSoftwareRenderer` key in the options dictionary to `true` when creating a context.

只要有可能，Core Image 将在 GPU 上执行滤镜操作。然而，它确实有回落到 CPU 上执行的可能。滤镜操作在 CPU 上完成可具有更好的精确度，因为 GPU 经常在浮点计算上以失真换得更快的速度。在创建一个上下文时，你可以通过设置 `kCIContextUseSoftwareRenderer` 关键字的值为 `true` 来强制 Core Image 在 CPU 上运行。

You can determine whether a CPU or GPU renderer is in use by setting the `CI_PRINT_TREE` environment variable to `1` in your scheme configuration in Xcode. This will cause Core Image to print diagnostic information every time a filtered image is rendered. This setting is useful for examining the composed image filter tree as well.

你可以通过在 Xcode 中设置计划配置（scheme configuration）里的 `CI_PRINT_TREE` 环境变量为 `1` 来决定用 CPU 还是 GPU 来渲染。这将导致每次一个滤镜处理图像被渲染的时候 Core Image 都会打印诊断信息。此设置用来检查合成图像滤镜树也很有用。

## A Tour of the Sample App

## 实例应用一览

The [sample code](https://github.com/objcio/issue-21-core-image-explorer) for this article consists of an iPhone app that showcases a broad variety of the image filters available in Core Image for iOS.

本文的[示例代码](https://github.com/objcio/issue-21-core-image-explorer)是一个 iPhone 应用程序，展示了 iOS 里大量的各式 Core Image 图像滤镜。

### Creating a GUI from Filter Parameters

### 为滤镜参数创建一个 GUI

To demonstrate a maximum number of filters, the sample app takes advantage of the introspective nature of Core Image and generates a user interface for controlling the parameters of the filters it supports:

为了尽可能多的演示各种滤镜，示例应用程序利用了 Core Image 的内省特点生成了一个界面，用于控制它支持的滤镜参数：

![Image being tweaked with the Color Controls filter](http://img.objccn.io/issue-21/color-controls.png)

The sample app is restricted to filters that have a single input image, and zero or more numerical inputs. There are some interesting filters that do not fall into this category (notably, the compositing and transition filters). Even so, the app gives a good overview of the functionality available in Core Image.

示例应用程序只限于单一的图像输入以及零个或多个数值输入的滤镜。也有一些有趣的滤镜不属于这一类（值得注意的是，合成和转换滤镜）。即便如此，该应用程序仍然很好的概述了 Core Image 支持的功能。

For each input parameter to the filter, a slider is configured with the minimum and maximum value of the parameter, and its value is set to the default value. When the value of the slider changes, it conveys the change to its delegate, which is a `UIImageView` subclass that holds a `CIFilter` reference.

对于每个滤镜的输入参数，都有一个滑动条可以用于配置参数的最小值和最大值，其值被设置为默认值。当滑动条的值发生变化时，它把改变后的值传给它的 delegate，一个持有 `CIFilter` 引用的 `UIImageView` 子类。

### Using the Built-In Photo Filters

### 使用内建的照片滤镜

In addition to numerous other built-in filters, the sample app demonstrates the photo filters introduced in iOS 7. These filters have no parameters we can tune, but they merit inclusion, since they show how you can emulate the effects in the Photos app for iOS:

除了许多其他的内置滤镜，示例应用程序还展示了 iOS 7 中引入的照片滤镜。这些滤镜没有我们可以调整的参数，但他们值得被囊括进来，因为他们展示了如何在 iOS 中模拟照片应用程序的效果：

![Image processed with the Transfer photo filter](http://img.objccn.io/issue-21/photo-filters.png)

## Conclusion

## 结论

This article has been a brief introduction to Core Image, a framework for high-performance image processing. We've tried to cover as many features of the framework as practically possible in this short format. You've learned how to instantiate and wire together Core Image filters, get images in and out of filter graphs, and tune parameters to get the desired outcome. You also learned how to access the system-provided photo filters, with which you can emulate the behavior of the Photos app on iOS.

这篇文章简要介绍了 Core Image 这个高性能的图像处理框架。我们一直在试图在如此简短的形式内尽可能多的展示这个框架的功能。你现在已经学会了如何实例化和串联 Core Image 的滤镜，在滤镜图表传入和输出图像，以及调整参数来获得想要的结果。你还学习了如何访问系统提供的照片滤镜，用以模拟在 iOS 上的照片应用程序的行为。

You now know enough to go out and write your own photo editing applications. With a little more exploration, you'll be able to write your own filters that exploit the amazing power of your Mac or iPhone to perform previously unimagined effects. Go forth and filter!

现在你知道了足够多的东西来写你自己的照片编辑应用程序了。随着更多的一些探索，你就可以写自己的滤镜了，利用你的 Mac 或 iPhone 的神奇的力量来执行以前无法想象的效果。快去动手做吧！

### References

### 参考

The [Core Image Reference Collection](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CoreImagingRef/_index.html#//apple_ref/doc/uid/TP40001171) is the canonical set of documentation on Core Image.

[Core Image Reference Collection](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CoreImagingRef/_index.html#//apple_ref/doc/uid/TP40001171) 是 Core Image 的权威文档集。

The [Core Image Filter Reference](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html#//apple_ref/doc/uid/TP40004346) contains a comprehensive list of the image filters available in Core Image, along with usage examples.

[Core Image Filter Reference](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html#//apple_ref/doc/uid/TP40004346) 包含了 Core Image 提供的图像滤镜的完整列表，以及用法示例。

For a take on writing Core Image code in a more functional style, see Florian Kluger's [article in objc.io issue #16](/issue-16/functional-swift-apis.html).

如果想要写更函数式风格的 Core Image 代码，可以看看 Florian Kluger [在 objccn.io 话题 #16 里的文章](http://objccn.io/issue-16-4/)。

---

[话题 #21 下的更多文章](http://www.objccn.io/issue-21)

原文 [An Introduction to Core Image](http://www.objc.io/issue-21/core-image-intro.html)
