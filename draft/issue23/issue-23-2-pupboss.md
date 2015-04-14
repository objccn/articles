*译者注：原文中大量引用出自 objc.io 的英文文章，为了方便阅读，本文已经将链接改成 objccn.io 的文章，如需查看英文原本，请点击该译文最下面的 `原文` 按钮。*

---

在这篇文章中，我们将研究 Core Image 对视频播放的影响。我们来看两个例子：首先，我们把这个影响作用于相机拍摄的照片。其次，我们再将这个影响作用于拍摄好的视频文件。它也可以做到离线渲染，它会把渲染结果返回给视频，而不是直接显示在屏幕上。两个例子的完整源代码，请点击 [这里](https://github.com/objcio/core-image-video)。

## 快速回顾

当涉及到处理视频的时候，性能就会变得非常重要。而且重要的是了解黑箱下的原理 —— 也就是 Core Image 如何工作 —— 如何提供足够的性能。在 GPU 上面做尽可能多的工作非常有必要，并且最大限度的减少 GPU 和 CPU 之间的数据传送。之后的例子中，我们将看看这个细节。

想对 Core Image 有个初步认识的话，可以读读 Warren 的这篇文章 [Core Image 介绍](http://objccn.io/issue-21-6/)。我们将使用 [Swift 的函数式 API](http://objccn.io/issue-16-4/) 中介绍的基于 `CIFilter` 的 API 封装。想要了解更多关于 AVFoundation，看看本 issue 中的 [Adriaan 的文章](http://objccn.io/issue-23-1/)，还有 issue #21 中的 [iOS 上的相机捕捉](http://objccn.io/issue-21-3/)。

## 优化资源的 OpenGL ES

CPU 和 GPU 都可以运行 Core Image，我们将会在 [下面](#cpuvsgpu) 详细介绍这两个的细节。在这个例子中，我们要使用 GPU，我们做如下几样事情。

我们首先创建一个自定义的 `UIView`，他允许我们把 Core Image 的结果直接渲染成 OpenGL。我们可以新建一个 `GLKView` 并且用一个 `EAGL 上下文` 来初始化。我们需要指定 OpenGL ES 2 作为渲染 API，在这两个例子中，我们要自己触发 drawing 事件（而不是在 `-drawRect:` 中触发，所以在初始化 GLKView 的时候，我们需要设置 `enableSetNeedsDisplay ` 为 false。然后我们再创建完新的图层，就需要主动触发 `-display` 了。

这样一来，我们可以不断地引用 `CIContext `，它提供一个桥梁来连接 Core Image 对象和 OpenGL 上下文。我们创建一次就可以一直使用它。这个上下文允许 Core Image 在后台做优化，比如缓存和重用资源，像纹理等等。重要的是这个上下文我们一直在重复使用。

上下文中有一个方法，`-drawImage:inRect:fromRect:`，作用是绘制出来一个 `CIImage`。如果你想画出来一个完整的图像，使用图像的 `extent ` 会变得异常容易。但是请注意，这可能是无限大的，所以一定要事先裁剪或者提供有限大小的矩形。一个警告：因为我们正在处理 Core Image，绘制的目标以像素为单位，而不是点。由于大部分新的 iOS 设备配备 Retina 屏幕，我们在绘制的时候需要考虑这一点。如果我们想填充整个视图，最简单的办法是划分出界限，并且通过屏幕的边缘来扩大他。(*PS：最后一句翻译的不够优雅，原文是 If we want to fill up our entire view, it's easiest to take the bounds and scale it up by the screen's scale.*)

完整的代码示例在这里：[CoreImageView.swift](https://github.com/objcio/core-image-video/blob/master/CoreImageVideo/CoreImageView.swift)

## 从相机获取像素数据

对于 AVFoundation 如何工作的概述






---

[话题 #23 下的更多文章](http://www.objccn.io/issue-23)

原文 [Core Image and Video](http://www.objc.io/issue-23/core-image-video.html)