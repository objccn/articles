在这篇文章中，我们将研究如何将 Core Image 应用到实时视频上去。我们会看两个例子：首先，我们把这个效果加到相机拍摄的影片上去。之后，我们会将这个影响作用于拍摄好的视频文件。它也可以做到离线渲染，它会把渲染结果返回给视频，而不是直接显示在屏幕上。两个例子的完整源代码，请点击[这里](https://github.com/objcio/core-image-video)。

## 总览

当涉及到处理视频的时候，性能就会变得非常重要。而且了解黑箱下的原理 —— 也就是 Core Image 是如何工作的 —— 也很重要，这样我们才能达到足够的性能。在 GPU 上面做尽可能多的工作，并且最大限度的减少 GPU 和 CPU 之间的数据传送是非常重要的。之后的例子中，我们将看看这个细节。

想对 Core Image 有个初步认识的话，可以读读 Warren 的这篇文章 [Core Image 介绍](http://objccn.io/issue-21-6/)。我们将使用 [Swift 的函数式 API](http://objccn.io/issue-16-4/) 中介绍的基于 `CIFilter` 的 API 封装。想要了解更多关于 AVFoundation 的知识，可以看看本期话题中 [Adriaan 的文章](http://objccn.io/issue-23-1/)，还有话题 #21 中的 [iOS 上的相机捕捉](http://objccn.io/issue-21-3/)。

## 优化资源的 OpenGL ES

CPU 和 GPU 都可以运行 Core Image，我们将会在 [下面](#cpuvsgpu) 详细介绍这两个的细节。在这个例子中，我们要使用 GPU，我们做如下几样事情。

我们首先创建一个自定义的 `UIView`，它允许我们把 Core Image 的结果直接渲染成 OpenGL。我们可以新建一个 `GLKView` 并且用一个 `EAGLContext` 来初始化它。我们需要指定 OpenGL ES 2 作为渲染 API，在这两个例子中，我们要自己触发 drawing 事件 (而不是在 `-drawRect:` 中触发)，所以在初始化 GLKView 的时候，我们将 `enableSetNeedsDisplay` 设置为 false。之后我们有可用新图像的时候，我们需要主动去调用 `-display`。

在这个视图里，我们保持一个对 `CIContext` 的引用，它提供一个桥梁来连接我们的 Core Image 对象和 OpenGL 上下文。我们创建一次就可以一直使用它。这个上下文允许 Core Image 在后台做优化，比如缓存和重用纹理之类的资源等。重要的是这个上下文我们一直在重复使用。

上下文中有一个方法，`-drawImage:inRect:fromRect:`，作用是绘制出来一个 `CIImage`。如果你想画出来一个完整的图像，最容易的方法是使用图像的 `extent`。但是请注意，这可能是无限大的，所以一定要事先裁剪或者提供有限大小的矩形。一个警告：因为我们处理的是 Core Image，绘制的目标以像素为单位，而不是点。由于大部分新的 iOS 设备配备 Retina 屏幕，我们在绘制的时候需要考虑这一点。如果我们想填充整个视图，最简单的办法是获取视图边界，并且按照屏幕的 scale 来缩放图片 (Retina 屏幕的 scale 是 2)。

完整的代码示例在这里：[CoreImageView.swift](https://github.com/objcio/core-image-video/blob/master/CoreImageVideo/CoreImageView.swift)

## 从相机获取像素数据

对于 AVFoundation 如何工作的概述，请看 [Adriaan 的文章](http://objccn.io/issue-23-1/) 和 Matteo 的文章 [iOS 上的相机捕捉](http://objccn.io/issue-21-3/)。对于我们而言，我们想从镜头获得 raw 格式的数据。我们可以通过创建一个 `AVCaptureDeviceInput` 对象来选定一个摄像头。使用 `AVCaptureSession `，我们可以把它连接到一个 `AVCaptureVideoDataOutput`。这个 data output 对象有一个遵守 `AVCaptureVideoDataOutputSampleBufferDelegate` 协议的代理对象。这个代理每一帧将接收到一个消息：

```swift
func captureOutput(captureOutput: AVCaptureOutput!,
                   didOutputSampleBuffer: CMSampleBuffer!,
                   fromConnection: AVCaptureConnection!) {
```

我们将用它来驱动我们的图像渲染。在我们的示例代码中，我们已经将配置，初始化以及代理对象都打包到了一个叫做 `CaptureBufferSource` 的简单接口中去。我们可以使用前置或者后置摄像头以及一个回调来初始化它。对于每个样本缓存区，这个回调都会被调用，并且参数是缓冲区和对应摄像头的 transform：

```swift
source = CaptureBufferSource(position: AVCaptureDevicePosition.Front) {
   (buffer, transform) in
   ...
}
```

我们需要对相机返回的数据进行变换。无论你如何转动 iPhone，相机的像素数据的方向总是相同的。在我们的例子中，我们将 UI 锁定在竖直方向，我们希望屏幕上显示的图像符合照相机拍摄时的方向，为此我们需要后置摄像头拍摄出的图片旋转 -π/2。前置摄像头需要旋转 -π/2 并且加一个镜像效果。我们可以用一个 `CGAffineTransform` 来表达这种变换。请注意如果 UI 是不同的方向 (比如横屏)，我们的变换也将是不同的。还要注意，这种变换的代价其实是非常小的，因为它是在 Core Image 渲染管线中完成的。

接着，要把 `CMSampleBuffer` 转换成 `CIImage`，我们首先需要将它转换成一个 `CVPixelBuffer`。我们可以写一个方便的初始化方法来为我们做这件事：

```swift
extension CIImage {
    convenience init(buffer: CMSampleBuffer) {
        self.init(CVPixelBuffer: CMSampleBufferGetImageBuffer(buffer))
    }
}
```

现在我们可以用三个步骤来处理我们的图像。首先，把我们的 `CMSampleBuffer` 转换成 `CIImage`，并且应用一个形变，使图像旋转到正确的方向。接下来，我们用一个 `CIFilter` 滤镜来得到一个新的 `CIImage` 输出。我们使用了 [Florian 的文章](http://objccn.io/issue-16-4/) 提到的创建滤镜的方式。在这个例子中，我们使用色调调整滤镜，并且传入一个依赖于时间而变化的调整角度。最终，我们使用之前定义的 View，通过 `CIContext` 来渲染 `CIImage`。这个流程非常简单，看起来是这样的：

```swift
source = CaptureBufferSource(position: AVCaptureDevicePosition.Front) {
  [unowned self] (buffer, transform) in
    let input = CIImage(buffer: buffer).imageByApplyingTransform(transform)
    let filter = hueAdjust(self.angleForCurrentTime)
    self.coreImageView?.image = filter(input)
}
```

当你运行它时，你可能会因为如此低的 CPU 使用率感到吃惊。这其中的奥秘是 GPU 做了几乎所有的工作。尽管我们创建了一个 `CIImage`，应用了一个滤镜，并输出一个 `CIImage`，最终输出的结果是一个 *promise*：直到实际渲染才会去进行计算。一个 `CIImage` 对象可以是黑箱里的很多东西，它可以是 GPU 算出来的像素数据，也可以是如何创建像素数据的一个说明 (比如使用一个滤镜生成器)，或者它也可以是直接从 OpenGL 纹理中创建出来的图像。

下面是演示视频

<video style="display:block;max-width:100%;height:auto;border:0;" controls="1">
  <source src="/images/issues/issue-23/camera.m4v"></source>
</video>

## 从影片中获取像素数据

我们可以做的另一件事是通过 Core Image 把这个滤镜加到一个视频中。和实时拍摄不同，我们现在从影片的每一帧中生成像素缓冲区，在这里我们将采用略有不同的方法。对于相机，它会推送每一帧给我们，但是对于已有的影片，我们使用拉取的方式：通过 display link，我们可以向 AVFoundation 请求在某个特定时间的一帧。

display link 对象负责在每帧需要绘制的时候给我们发送消息，这个消息是按照显示器的刷新频率同步进行发送的。这通常用来做 [自定义动画](http://objccn.io/issue-12-6/)，但也可以用来播放和操作视频。我们要做的第一件事就是创建一个 `AVPlayer` 和一个视频输出：

```swift
player = AVPlayer(URL: url)
videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferDict)
player.currentItem.addOutput(videoOutput)
```

接下来，我们要创建 display link。方法很简单，只要创建一个 `CADisplayLink` 对象，并将其添加到 run loop。

```swift
let displayLink = CADisplayLink(target: self, selector: "displayLinkDidRefresh:")
displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
```

现在，唯一剩下的就是在 `displayLinkDidRefresh:` 调用的时候获取视频每一帧。首先，我们获取当前的时间，并且将它转换成当前播放项目里的时间比。然后我们询问 `videoOutput`，如果当前时间有一个可用的新的像素缓存区，我们把它复制一下并且调用回调方法：

```swift
func displayLinkDidRefresh(link: CADisplayLink) {
    let itemTime = videoOutput.itemTimeForHostTime(CACurrentMediaTime())
    if videoOutput.hasNewPixelBufferForItemTime(itemTime) {
        let pixelBuffer = videoOutput.copyPixelBufferForItemTime(itemTime, itemTimeForDisplay: nil)
        consumer(pixelBuffer)
    }
}
```

我们从一个视频输出获得的像素缓冲是一个 `CVPixelBuffer`，我们可以把它直接转换成 `CIImage`。正如上面的例子，我们会加上一个滤镜。在这个例子里，我们将组合多个滤镜：我们使用一个万花筒的效果，然后用渐变遮罩把原始图像和过滤图像相结合，这个操作是非常轻量级的。

<video style="display:block;max-width:100%;height:auto;border:0;" controls="1">
  <source src="/images/issues/issue-23/video.m4v"></source>
</video>

## 创意地使用滤镜

大家都知道流行的照片效果。虽然我们可以将这些应用到视频，但 Core Image 还可以做得更多。

Core Image 里所谓的滤镜有不同的类别。其中一些是传统的类型，输入一张图片并且输出一张新的图片。但有些需要两个 (或者更多) 的输入图像并且混合生成一张新的图像。另外甚至有完全不输入图片，而是基于参数的生成图像的滤镜。

通过混合这些不同的类型，我们可以创建意想不到的效果。

### 混合图片

在这个例子中，我们使用这些东西：

<img src="/images/issues/issue-23/combining-filters.svg" alt="Combining filters" width="620px" height="186px">

上面的例子可以将图像的一个圆形区域像素化。

它也可以创建交互，我们可以使用触摸事件来改变所产生的圆的位置。

[Core Image Filter Reference](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html) 按类别列出了所有可用的滤镜。请注意，有一部分只能用在 OS X。

生成器和渐变滤镜可以不需要输入就能生成图像。它们很少自己单独使用，但是作为蒙版的时候会非常强大，就像我们例子中的 `CIBlendWithMask` 那样。

混合操作和 `CIBlendWithAlphaMask` 还有 `CIBlendWithMask` 允许将两个图像合并成一个。

<a name="cpuvsgpu"></a>
## CPU vs. GPU

我们在话题 #3 的文章，[绘制像素到屏幕上](http://objccn.io/issue-3-1/)里，介绍了 iOS 和 OS X 的图形栈。需要注意的是 CPU 和 GPU 的概念，以及两者之间数据的移动方式。

在处理实时视频的时候，我们面临着性能的挑战。

首先，我们需要能在每一帧的时间内处理完所有的图像数据。我们的样本中采用 24 帧每秒的视频，这意味着我们有 41 毫秒 (1/24 秒) 的时间来解码，处理以及渲染每一帧中的百万像素。

其次，我们需要能够从 CPU 或者 GPU 上面得到这些数据。我们从视频文件读取的字节数最终会到达 CPU 里。但是这个数据还需要移动到 GPU 上，以便在显示器上可见。

### 避免转移

一个非常致命的问题是，在渲染管线中，代码可能会把图像数据在 CPU 和 GPU 之间来回移动好几次。确保像素数据仅在一个方向移动是很重要的，应该保证数据只从 CPU 移动到 GPU，如果能让数据完全只在 GPU 上那就更好。

如果我们想渲染 24 fps 的视频，我们有 41 毫秒；如果我们渲染 60 fps 的视频，我们只有 16 毫秒，如果我们不小心从 GPU 下载了一个像素缓冲到 CPU 里，然后再上传回 GPU，对于一张全屏的 iPhone 6 图像来说，我们在每个方向将要移动 3.8 MB 的数据，这将使帧率无法达标。

当我们使用 `CVPixelBuffer` 时，我们希望这样的流程：

<img src="/images/issues/issue-23/flow.svg" alt="Flow of image data" width="620px" height="232px">

`CVPixelBuffer` 是基于 CPU 的 (见下文)，我们用 `CIImage` 来包装它。构建滤镜链不会移动任何数据；它只是建立了一个流程。一旦我们绘制图像，我们使用了基于 EAGL 上下文的 Core Image 上下文，而这个 EAGL 上下文也是 GLKView 进行图像显示所使用的上下文。EAGL 上下文是基于 GPU 的。请注意，我们是如何只穿越 GPU-CPU 边界一次的，这是至关重要的部分。

### 工作和目标

Core Image 的图形上下文可以通过两种方式创建：使用 `EAGLContext` 的 GPU 上下文，或者是基于 CPU 的上下文。

这个定义了 Core Image 工作的地方，也就是像素数据将被处理的地方。与工作区域无关，基于 GPU 和基于 CPU 的图形上下文都可以通过执行 `createCGImage(…)`，`render(_, toBitmap, …)` 和 `render(_, toCVPixelBuffer, …)`，以及相关的命令来向 CPU 进行渲染。

重要的是要理解如何在 CPU 和 GPU 之间移动像素数据，或者是让数据保持在 CPU 或者 GPU 里。将数据移过这个边界是需要很大的代价的。

### 缓冲区和图像

在我们的例子中，我们使用了几个不同的**缓冲区**和**图像**。这可能有点混乱。这样做的原因很简单，不同的框架对于这些“图像”有不同的用途。下面有一个快速总览，以显示哪些是以基于 CPU 或者基于 GPU 的：

<table><thead>
<tr>
<th>类</th>
<th>描述</th>
</tr>
</thead><tbody>
<tr>
<td>CIImage</td>
<td>它们可以代表两种东西：图像数据或者生成图像数据的流程。</td>
</tr>
<tr>
<td></td>
<td>CIFilter 的输出非常轻量。它只是如何被创建的描述，并不包含任何实际的像素数据。</td>
</tr>
<tr>
<td></td>
<td>如果输出时图像数据的话，它可能是纯像素的 <code>NSData</code>，一个 <code>CGImage</code>， 一个 <code>CVPixelBuffer</code>，或者是一个 OpenGL 纹理</td>
</tr>
<tr>
<td>CVImageBuffer</td>
<td>这是 <code>CVPixelBuffer</code> (CPU) 和 <code>CVOpenGLESTexture</code> (GPU) 的抽象父类.</td>
</tr>
<tr>
<td>CVPixelBuffer</td>
<td>Core Video 像素缓冲 (Pixel Buffer) 是基于 CPU 的。</td>
</tr>
<tr>
<td>CMSampleBuffer</td>
<td>Core Media 采样缓冲 (Sample Buffer) 是 <code>CMBlockBuffer</code> 或者 <code>CVImageBuffer</code> 的包装，也包括了元数据。</td>
</tr>
<tr>
<td>CMBlockBuffer</td>
<td>Core Media 区块缓冲 (Block Buffer) 是基于 GPU 的</td>
</tr>
</tbody></table>

需要注意的是 `CIImage` 有很多方便的方法，例如，从 JPEG 数据加载图像或者直接加载一个 `UIImage` 对象。在后台，这些将会使用一个基于 `CGImage` 的 `CIImage` 来进行处理。

## 结论

Core Image 是操纵实时视频的一大利器。只要你适当的配置下，性能将会是强劲的 —— 只要确保 CPU 和 GPU 之间没有数据的转移。创意地使用滤镜，你可以实现一些非常炫酷的效果，神马简单色调，褐色滤镜都弱爆啦。所有的这些代码都很容易抽象出来，深入了解下不同的对象的作用区域 (GPU 还是 CPU) 可以帮助你提高代码的性能。

---

 

原文 [Core Image and Video](http://www.objc.io/issue-23/core-image-video.html)
