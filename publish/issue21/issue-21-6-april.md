这篇文章会为初学者介绍一下 Core Image，一个 OS X 和 iOS 的图像处理框架。

如果你想跟着本文中的代码学习，你可以在 GitHub 上下载[示例工程](https://github.com/objcio/issue-21-core-image-explorer)。示例工程是一个 iOS 应用程序，列出了系统提供的大量图像滤镜以供选择，并提供了一个用户界面用来调整参数并观察效果。

虽然示例代码是用 Swift 写的 iOS 程序，不过实现概念很容易转换到 Objective-C 和 OS X.

## 基本概念

说到 Core Image，我们首先需要介绍几个基本的概念。

一个**滤镜**是一个对象，有很多输入和输出，并执行一些变换。例如，模糊滤镜可能需要输入图像和一个模糊半径来产生适当的模糊后的输出图像。

一个**滤镜图表**是一个链接在一起的滤镜网络 ([无回路有向图](http://en.wikipedia.org/wiki/Directed_acyclic_graph))，使得一个滤镜的输出可以是另一个滤镜的输入。以这种方式，可以实现精心制作的效果。我们将在下面看到如何连接滤镜来创建一个复古的拍照效果。

## 熟悉 Core Image API

有了上述的这些概念，我们可以开始探索 Core Image 的图像滤镜细节了。

### Core Image 架构

Core Image 有一个插件架构，这意味着它允许用户编写自定义的滤镜并与系统提供的滤镜集成来扩展其功能。我们在这篇文章中不会用到 Core Image 的可扩展性；我提到它只是因为它影响到了框架的 API。

Core Image 是用来最大化利用其所运行之上的硬件的。每个滤镜实际上的实现，即**内核**，是由一个 [GLSL](https://www.opengl.org/documentation/glsl/) (即 OpenGL 的着色语言) 的[子集](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CIKernelLangRef/Introduction/Introduction.html)来书写的。当多个滤镜连接成一个滤镜图表，Core Image 便把内核串在一起来构建一个可在 GPU 上运行的高效程序。

只要有可能，Core Image 都会把工作延迟。通常情况下，直到滤镜图表的最后一个滤镜的输出被请求之前都不会发生分配或处理。

为了完成工作，Core Image 需要一个称为**上下文 (context)** 的对象。这个上下文是框架真正工作的地方，它需要分配必要的内存，并编译和运行滤镜内核来执行图像处理。建立一个上下文是非常昂贵的，所以你会经常想创建一个反复使用的上下文。接下来我们将看到如何创建一个上下文。

### 查询可用的滤镜

Core Image 滤镜是按名字创建的。要获得系统滤镜的列表，我们要向 Core Image 的 `kCICategoryBuiltIn` 类别请求得到滤镜的名字：

```
let filterNames = CIFilter.filterNamesInCategory(kCICategoryBuiltIn) as [String]
```

iOS 上可用的滤镜列表非常接近于 OS X 上可用滤镜的一个子集。在 OS X 上有 169 个内置滤镜，在 iOS 上有 127 个。

### 通过名字创建一个滤镜

现在，我们有了可用滤镜的列表，我们就可以创建和使用滤镜了。例如，要创建一个高斯模糊滤镜，我们传给 `CIFilter` 初始化方法相应的名称就可以了：

```
let blurFilter = CIFilter(named:"CIGaussianBlur")
```

### 设置滤镜参数

由于 Core Image 的插件结构，大多数滤镜属性并不是直接设置的，而是通过键值编码（KVC）设置。例如，要设置模糊滤镜的模糊半径，我们使用 KVC 来设置 `inputRadius` 属性：

```
blurFilter.setValue(10.0 forKey:"inputRadius")
```

由于这种方法需要 `AnyObject?` （即 Objective-C 里的 `id`）作为其参数值，它不是类型安全的。因此，设置滤镜参数需要谨慎一些，确保你传值的类型是正确的。

### 查询滤镜属性

为了知道一个滤镜提供什么样的输入和输出参数，我们就可以分别获取 `inputKeys` 和 `outputKeys` 数组。它们都返回 `NSString` 的数组。

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

对于数值参数，该字典会包含 `kCIAttributeSliderMin` 和 `kCIAttributeSliderMax` 键，来限制期望的输入域。大多数参数还包含一个 `kCIAttributeDefault` 关键字，映射到该参数的默认值。

## 图片滤镜实战

图像滤镜的工作由三部分组成：构建和配置滤镜图表，发送等待滤镜处理的图像，得到滤镜处理后的图像。下面的部分对此进行了详细描述。

### 构建一个滤镜图表

构建一个滤镜图表由这几个部分组成：实例化我们需要的滤镜，设置它们的参数，把它们连接起来以便该图像数据按顺序传过每个滤镜。

在本节中，我们将创建一个用来制作 19 世纪锡版照风格图像的滤镜图表。我们将两个效果链在一起来达到这种效果：同时去饱和以及染色调的黑白滤镜，和一个暗角滤镜来创建一个有阴影效果的加框图片。

用 Quartz Composer，来做 Core Image 滤镜图表的原型非常有用，可以[从苹果开发者网站下载](https://developer.apple.com/downloads/index.action?name=Graphics)。下面，我们整理了所需的照片滤镜，把黑白滤镜和暗角滤镜串在一起：

![A filter graph built with Quartz Composer, showing intermediate filtered images](/images/issues/issue-21/quartz.png)

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

需要注意的是黑白滤镜的输出图像变为暗角滤镜的输入图像。这将导致暗角效果要应用到黑白图像上。还要注意的是，我们可以在初始化中指定参数，而不一定需要用 KVC 单独设置它们。

### 创建输入图像

Core Image 滤镜要求其输入图像是 `CIImage` 类型。而对于 iOS 的程序员来说这可能会有一点不寻常，因为他们更习惯用 `UIImage`，但这个区别是值得的。一个 `CIImage` 实例实际上比 `UIImage` 更全面，因为 `CIImage` 可以无限大。当然，我们不能存储无限的图像在内存中，但在概念上，这意味着你可以从 2D 平面上的任意区域获取图像数据，并得到一个有意义的结果。

所有我们在本文中使用的图像都是有限的，而且也可以很容易从一个 `UIImage` 来创建一个 `CIImage`。事实上，这只需要一行代码：

```
let inputImage = CIImage(image: uiImage)
```

也有很方便的初始化方法直接从图像数据或文件 URL 来创建 `CIImage`。

一旦我们有了一个 `CIImage`，我们就可以通过设置滤镜的 `inputImage` 参数来将其设置为滤镜的输入图像：

```
filter.setValue(inputImage, forKey:"inputImage")
```

### 得到一个滤镜处理后的图片

滤镜都有一个名为 `outputImage` 的属性。正如你可能已经猜到的一样，它是 `CIImage` 类型的。那么，我们如何实现从一个 `CIImage` 创建 `UIImage` 这样一个反向操作？好了，虽然我们到此已经花了所有的时间建立一个滤镜图表，现在是调用 `CIContext` 的力量来实际的做图像滤镜处理工作的时候了。

创建一个上下文最简单的方法是给它的构造方法传一个 nil 字典：

```
let ciContext = CIContext(options: nil)
```

为了得到一个滤镜处理过的图像，我们需要 `CIContext` 从输出图像的一个矩形内创建一个 `CGImage`，传入输入图像的范围（bounds）：

```
let cgImage = ciContext.createCGImage(filter.outputImage, fromRect: inputImage.extent())
```

我们使用输入图像大小的原因是，输出图像通常和输入图像具有不同的尺寸比。例如，一个模糊图像由于采样超出了输入图像的边缘，围绕在其边界外还会有一些额外的像素。

现在，我们可以从这个新创建的 `CGImage` 来创建一个 `UIImage` 了：

```
let uiImage = UIImage(CGImage: cgImage)
```

直接从一个 `CIImage` 创建 `UIImage` 也是可以的，但这种方法有点让人郁闷：如果你试图在一个 `UIImageView` 上显示这样的图像，其 `contentMode` 属性将被忽略。使用过渡的 `CGImage` 则需要一个额外的步骤，但可以省去这一烦恼。

### 用 OpenGL 来提高性能

用 CPU 来绘制一个 `CGImage` 是非常耗时和浪费的，它只将结果回传给 UIKit 来做合成。我们更希望能够在屏幕上绘制应用滤镜后的图像，而不必去 Core Graphics 里绕一圈。幸运的是，由于 OpenGL 和 Core Image 的可互操作性，我们可以这么做。

要 OpenGL 上下文和 Core Image 上下文之间共享资源，我们需要用一个稍微不同的方式来创建我们的 `CIContext`：

```
let eaglContext = EAGLContext(API: .OpenGLES2)
let ciContext = CIContext(EAGLContext: context)
```

在这里，我们用 OpenGL ES 2.0 的功能集创建了一个 `EAGLContext`。这个 GL 上下文可以用作一个 `GLKView` 的背衬上下文或用来绘制成一个 `CAEAGLLayer`。示例代码使用这种技术来有效地绘制图像。

当一个 `CIContext` 具有了关联 GL 的上下文，滤镜处理后的图像就可用 OpenGL 来绘制，像如下这样调用方法：

```
ciContext.drawImage(filter.outputImage, inRect: outputBounds, fromRect: inputBounds)
```

与以前一样，`fromRect` 参数是用滤镜处理后的图像的坐标空间来绘制的图像的一部分。这个 `inRect` 参数是 GL 上下文的坐标空间的矩形应用到需要绘制图像上。如果你想保持图像的长宽比，你可能需要做一些数学计算来得到适当的 `inRect`。

### 强制在 CPU 上做滤镜操作

只要有可能，Core Image 将在 GPU 上执行滤镜操作。然而，它确实有回滚到 CPU 上执行的可能。滤镜操作在 CPU 上完成可具有更好的精确度，因为 GPU 经常在浮点计算上以失真换得更快的速度。在创建一个上下文时，你可以通过设置 `kCIContextUseSoftwareRenderer` 关键字的值为 `true` 来强制 Core Image 在 CPU 上运行。

你可以通过在 Xcode 中设置计划配置（scheme configuration）里的 `CI_PRINT_TREE` 环境变量为 `1` 来决定用 CPU 还是 GPU 来渲染。这将导致每次一个滤镜处理图像被渲染的时候 Core Image 都会打印诊断信息。此设置用来检查合成图像滤镜树也很有用。

## 示例应用一览

本文的[示例代码](https://github.com/objcio/issue-21-core-image-explorer)是一个 iPhone 应用程序，展示了 iOS 里大量的各式 Core Image 图像滤镜。

### 为滤镜参数创建一个 GUI

为了尽可能多的演示各种滤镜，示例应用程序利用了 Core Image 的内省特点生成了一个界面，用于控制它支持的滤镜参数：

![Image being tweaked with the Color Controls filter](/images/issues/issue-21/color-controls.png)

示例应用程序只限于单一的图像输入以及零个或多个数值输入的滤镜。也有一些有趣的滤镜不属于这一类（特别是那些合成和转换滤镜）。即便如此，该应用程序仍然很好的概述了 Core Image 支持的功能。

对于每个滤镜的输入参数，都有一个滑动条可以用于配置参数的最小值和最大值，其值被设置为默认值。当滑动条的值发生变化时，它把改变后的值传给它的 delegate，一个持有 `CIFilter` 引用的 `UIImageView` 子类。

### 使用内建的照片滤镜

除了许多其他的内置滤镜，示例应用程序还展示了 iOS 7 中引入的照片滤镜。这些滤镜没有我们可以调整的参数，但它们值得被囊括进来，因为它们展示了如何在 iOS 中模拟照片应用程序的效果：

![Image processed with the Transfer photo filter](/images/issues/issue-21/photo-filters.png)

## 结论

这篇文章简要介绍了 Core Image 这个高性能的图像处理框架。我们一直在试图在如此简短的形式内尽可能多的展示这个框架的功能。你现在已经学会了如何实例化和串联 Core Image 的滤镜，在滤镜图表传入和输出图像，以及调整参数来获得想要的结果。你还学习了如何访问系统提供的照片滤镜，用以模拟在 iOS 上的照片应用程序的行为。

现在你知道了足够多的东西来写你自己的照片编辑应用程序了。随着更多的一些探索，你就可以写自己的滤镜了，利用你的 Mac 或 iPhone 的神奇的力量来执行以前无法想象的效果。快去动手做吧！

### 参考

[Core Image Reference Collection](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CoreImagingRef/_index.html#//apple_ref/doc/uid/TP40001171) 是 Core Image 的权威文档集。

[Core Image Filter Reference](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html#//apple_ref/doc/uid/TP40004346) 包含了 Core Image 提供的图像滤镜的完整列表，以及用法示例。

如果想要写更函数式风格的 Core Image 代码，可以看看 Florian Kluger [在 objccn.io 话题 #16 里的文章](http://objccn.io/issue-16-4/)。

---

 

原文 [An Introduction to Core Image](http://www.objc.io/issue-21/core-image-intro.html)

