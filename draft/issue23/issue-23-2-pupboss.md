*译者注：原文中大量引用出自 objc.io 的英文文章，为了方便阅读，本文已经将链接改成 objccn.io 的文章，如需查看英文原本，请点击该译文最下面的 `原文` 按钮。*

---

在这篇文章中，我们将研究 Core Image 对视频播放的影响。我们来看两个例子：首先，我们把这个影响作用于相机拍摄的照片。其次，我们再将这个影响作用于拍摄好的视频文件。它也可以做到离线渲染，它会把渲染结果返回给视频，而不是直接显示在屏幕上。两个例子的完整源代码，请点击 [这里](https://github.com/objcio/core-image-video)。

## 总览

当涉及到处理视频的时候，性能就会变得非常重要。而且重要的是了解黑箱下的原理 —— 也就是 Core Image 如何工作 —— 如何提供足够的性能。在 GPU 上面做尽可能多的工作非常有必要，并且最大限度的减少 GPU 和 CPU 之间的数据传送。之后的例子中，我们将看看这个细节。

想对 Core Image 有个初步认识的话，可以读读 Warren 的这篇文章 [Core Image 介绍](http://objccn.io/issue-21-6/)。我们将使用 [Swift 的函数式 API](http://objccn.io/issue-16-4/) 中介绍的基于 `CIFilter` 的 API 封装。想要了解更多关于 AVFoundation，看看本 issue 中的 [Adriaan 的文章](http://objccn.io/issue-23-1/)，还有 issue #21 中的 [iOS 上的相机捕捉](http://objccn.io/issue-21-3/)。

## 优化资源的 OpenGL ES

CPU 和 GPU 都可以运行 Core Image，我们将会在 [下面](#cpuvsgpu) 详细介绍这两个的细节。在这个例子中，我们要使用 GPU，我们做如下几样事情。

我们首先创建一个自定义的 `UIView`，他允许我们把 Core Image 的结果直接渲染成 OpenGL。我们可以新建一个 `GLKView` 并且用一个 `EAGL 上下文` 来初始化。我们需要指定 OpenGL ES 2 作为渲染 API，在这两个例子中，我们要自己触发 drawing 事件（而不是在 `-drawRect:` 中触发，所以在初始化 GLKView 的时候，我们需要设置 `enableSetNeedsDisplay` 为 false。然后我们再创建完新的图层，就需要主动触发 `-display` 了。

这样一来，我们可以不断地引用 `CIContext`，它提供一个桥梁来连接 Core Image 对象和 OpenGL 上下文。我们创建一次就可以一直使用它。这个上下文允许 Core Image 在后台做优化，比如缓存和重用资源，像纹理等等。重要的是这个上下文我们一直在重复使用。

上下文中有一个方法，`-drawImage:inRect:fromRect:`，作用是绘制出来一个 `CIImage`。如果你想画出来一个完整的图像，使用图像的 `extent` 会变得异常容易。但是请注意，这可能是无限大的，所以一定要事先裁剪或者提供有限大小的矩形。一个警告：因为我们正在处理 Core Image，绘制的目标以像素为单位，而不是点。由于大部分新的 iOS 设备配备 Retina 屏幕，我们在绘制的时候需要考虑这一点。如果我们想填充整个视图，最简单的办法是划分出界限，并且通过屏幕的边缘来扩大他。(*PS: 最后一句翻译的不够优雅，原文是 If we want to fill up our entire view, it's easiest to take the bounds and scale it up by the screen's scale.*)

完整的代码示例在这里：[CoreImageView.swift](https://github.com/objcio/core-image-video/blob/master/CoreImageVideo/CoreImageView.swift)

## 从相机获取像素数据

对于 AVFoundation 如何工作的概述，请看 [Adriaan 的文章](http://objccn.io/issue-23-1/) 和 Matteo 的文章 [iOS 上的相机捕捉](http://objccn.io/issue-21-3/)。对于我们而言，我们想从镜头获得 raw 格式的数据。这里有一个摄像头，我们通过创建一个 `AVCaptureDeviceInput` 对象。使用 `AVCaptureSession `，我们可以把它连接到一个 `AVCaptureVideoDataOutput`。这个 data output 有一个符合 `AVCaptureVideoDataOutputSampleBufferDelegate` 协议的代理对象。这个代理将用来接受每一帧的消息：

```swift
func captureOutput(captureOutput: AVCaptureOutput!,
                   didOutputSampleBuffer: CMSampleBuffer!,
                   fromConnection: AVCaptureConnection!) {
```

我们将用它来驱动我们的图像渲染。在我们的示例代码中，我们已经结束了配置以及初始化，并且代理对象进入一个简单的 interface `CaptureBufferSource`。我们可以使用前置或者后置摄像头，一个回调来初始化他，其中，对于每个缓存区的实例，都会得到一个回调和变换该摄像头的初始化：

```swift
source = CaptureBufferSource(position: AVCaptureDevicePosition.Front) {
   (buffer, transform) in
   ...
}
```

我们需要对从相机返回的数据进行转码，无论你如何转动 iPhone，像素数据总是在相同的方向。在我们的例子中，我们锁定 UI 在正方向，我们希望屏幕上显示的图像符合照相机拍出来的方向，为此我们需要后置摄像头的照片旋转 -π/2。前置摄像头需要旋转两个 -π/2 并且加一个镜像效果。我们把这个称作为一个 `CGAffineTransform`。请注意如果 UI 是不同的方向，我们的变换将是不同的。还要注意，这种转换的代价是非常小的，因为他在 Core Image 渲染过程中完成。

接着，要把 `CMSampleBuffer` 转换成 `CIImage`，我们首先需要先转换成一个 `CVPixelBuffer`。我们可以写一个方便的初始化方法为我们做这些事：

```swift
extension CIImage {
    convenience init(buffer: CMSampleBuffer) {
        self.init(CVPixelBuffer: CMSampleBufferGetImageBuffer(buffer))
    }
}
```

现在我们用三个步骤来可以处理我们的图像。首先把我们的 `CMSampleBuffer` 转换成 `CIImage`，并且应用一个形变，使图像旋转到正确的方向。接下来，我们应用一个 `CIFilter` 滤镜得到一个新的 `CIImage` 输出。我们使用 [Florian 的文章](http://objccn.io/issue-16-4/) 提到的创建滤镜的方式。在这个例子中，我们使用色调调整滤镜，并且依赖时间通过一个角度(*PS: 不够优雅，原文是 pass in an angle that depends on time*)。最终，我们把事先定义的 View 用 `CIContext` 转换成 `CIImage`。这个流程非常简单，看起来是这样的：

```swift
source = CaptureBufferSource(position: AVCaptureDevicePosition.Front) {
  [unowned self] (buffer, transform) in
    let input = CIImage(buffer: buffer).imageByApplyingTransform(transform)
    let filter = hueAdjust(self.angleForCurrentTime)
    self.coreImageView?.image = filter(input)
}
```

当你运行它，你可能会因为 CPU 的低使用率吃惊。这其中的奥秘是 GPU 做了几乎所有的工作。尽管我们创建了一个 `CIImage`，应用了一个滤镜，并输出一个 `CIImage`，最终输出的结果是一个 *promise*：不呈现就不去计算。一个 `CIImage` 对象可以是黑箱里的很多东西，它可以是 GPU 算出来的像素数据，也可以是如何创建像素数据的一个说明（例如在使用一个滤镜），或者他也可以直接从 OpenGL 创建纹理。

# 下面是演示视频



## 从影片中获取像素数据




















---

[话题 #23 下的更多文章](http://www.objccn.io/issue-23)

原文 [Core Image and Video](http://www.objc.io/issue-23/core-image-video.html)