*译者注：原文中大量引用出自 objc.io 的英文文章，为了方便阅读，本文已经将链接改成 objccn.io 的文章，如需查看英文原本，请点击该译文最下面的 `原文` 按钮。*

---

In this article, we'll look into applying Core Image effects to live video. We'll look at two examples: first, we'll apply effects to the camera image. Second, we'll apply effects to an existing movie file. It's also possible to do offline rendering, where you render the result back into a video instead of directly on the screen. The full code of both examples is available [here](https://github.com/objcio/core-image-video).

在这篇文章中，我们将研究 Core Image 对视频播放的影响。我们来看两个例子：首先，我们来看他对照片处理的影响，然后再来看看对视频处理的影响。它也可以做到离线渲染，它会把渲染结果返回给视频，而不是直接显示在屏幕上。两个例子的完整源代码，请点击 [这里](https://github.com/objcio/core-image-video)。

## Quick Recap
## 总览

Performance is very important when it comes to video. And it's important to understand how things work under the hood — how Core Image does its work — in order to be able to deliver that performance. It's important to do as much work on the GPU as possible, and minimize the transferring of data between GPU and CPU. After the examples, we'll look into the details of this.

当涉及到处理视频的时候，性能就会变得非常重要。但是更重要的是了解黑箱下的原理 —— 也就是 Core Image 如何工作 —— 如何提供更棒的性能。在 GPU 上面做尽可能多的工作非常有必要，并且最大限度的减少 GPU 和 CPU 之间的数据传送。之后的例子中，我们将看看这个细节。

To get a feeling for Core Image, it's good to read Warren's article: [An Introduction to Core Image](/issue-21/core-image-intro.html). We'll use the functional wrappers around `CIFilter` as described in [Functional Core Image](/issue-16/functional-swift-apis.html). To understand more about AVFoundation, have a look at [Adriaan's article](/issue-23/capturing-video.html) in this issue and the [Camera Capture](http://www.objc.io/issue-21/camera-capture-on-ios.html) article in Issue #21.

想对 Core Image 有个初步认识的话，可以读读 Warren 的这篇文章 [Core Image 介绍](http://objccn.io/issue-21-6/)。我们将使用 [Swift 的函数式 API](http://objccn.io/issue-16-4/) 中介绍的基于 `CIFilter` 的 API 封装。想要了解更多关于 AVFoundation，看看本 issue 中的 [Adriaan 的文章](http://objccn.io/issue-23-1/)，还有 issue #21 中的 [iOS 上的相机捕捉](http://objccn.io/issue-21-3/)。

## Harnessing OpenGL ES
## 能优化资源的 OpenGL ES

Core Image can run on both the CPU and the GPU. We'll go into more detail about what to be aware of [below](#cpuvsgpu). In our case, we want to use the GPU, and we do that as follows.

CPU 和 GPU 都可以运行 Core Image，我们将会在 [下面](#cpuvsgpu) 详细介绍这两个的细节。在这个例子中，我们要使用 GPU，我们做如下几样事情。

We start by creating a custom `UIView` that allows us to render Core Image's results directly into OpenGL. We can use a `GLKView` and initialize it with a new `EAGLContext`. We need to specify OpenGL ES 2 as the rendering API. In both examples, we want to trigger the drawing ourselves (rather than having `-drawRect:` called for us), so when initializing the `GLKView`, we need to set `enableSetNeedsDisplay` to false. This then puts the burden on us to call `-display` when we have a new image available.

我们首先创建一个自定义的 `UIView`，因为 UIView 允许我们把 Core Image 的结果直接渲染成 OpenGL。我们可以新建一个名为 `GLKView` 的 UIView 并且用一个 `EAGL 上下文` 来初始化。我们需要指定 OpenGL ES 2 作为渲染 API，在这两个例子中，我们要自己主动触发 drawing 事件（而不是在 `-drawRect:` 中触发，所以在初始化 GLKView 的时候，我们需要设置 `enableSetNeedsDisplay` 为 false。然后我们再创建完新的图层，就需要主动触发 `-display` 了。


In this view, we also keep a reference to a `CIContext`. This context provides the connection between our Core Image objects and the OpenGL context. We create it once and keep it around. The context allows Core Image to do behind-the-scenes optimizations, such as caching and reusing resources like textures. It is therefore important to reuse the same context.

在这个 UIView 中，我们可以不断地引用 `CIContext`，它提供一个桥梁来连接 Core Image 对象和 OpenGL 上下文。我们创建一次就可以一直使用它。这个上下文允许 Core Image 在后台做优化，比如缓存和重用资源，像纹理等等。重要的是这个上下文我们一直在重复使用。

The context has a method, `-drawImage:inRect:fromRect:`, which draws a `CIImage`. If you want to draw an entire image, it's easiest to use the image's `extent`. Note however, that it might be infinitely large, so make sure you either crop it beforehand or provide a finite rectangle. A caveat: Because we're dealing with Core Image, the drawing's destination rectangle is specified in pixels, not in points. As most new iOS devices are in Retina, we need to account for this when drawing. If we want to fill up our entire view, it's easiest to take the bounds and scale it up by the screen's scale.

上下文中有一个方法，`-drawImage:inRect:fromRect:`，作用是绘制出来一个 `CIImage`。如果你想画出来一个完整的图像，使用图像的 `extent` 会变得异常容易。但是请注意，这可能是无限大的，所以一定要事先裁剪或者提供有限大小的矩形。一个警告：因为我们正在处理 Core Image，绘制的目标以像素为单位，而不是点。由于大部分新的 iOS 设备配备 Retina 屏幕，我们在绘制的时候需要考虑这一点。如果我们想填充整个视图，最简单的办法是划分出界限，并且通过屏幕的边缘来扩大他。(*PS: 最后一句翻译的不够优雅，原文是 If we want to fill up our entire view, it's easiest to take the bounds and scale it up by the screen's scale.*)

For a full code example, take a look at [CoreImageView.swift](https://github.com/objcio/core-image-video/blob/master/CoreImageVideo/CoreImageView.swift) in our sample project.

完整的代码示例在这里：[CoreImageView.swift](https://github.com/objcio/core-image-video/blob/master/CoreImageVideo/CoreImageView.swift)

## Getting Pixel Data from the Camera
## 从相机获取像素数据

For an overview of how AVFoundation works, see [Adriaan's article](/issue-23/capturing-video.html) and the [Camera Capture](/issue-21/camera-capture-on-ios.html) article by Matteo. For our purposes, we want to get raw sample buffers from the camera. Given a camera, we do this by creating an `AVCaptureDeviceInput` object. Using an `AVCaptureSession`, we can connect it to an `AVCaptureVideoDataOutput`. This video data output has a delegate object that conforms to the `AVCaptureVideoDataOutputSampleBufferDelegate` protocol. This delegate will receive a message for each frame:

对于 AVFoundation 如何工作的概述，请看 [Adriaan 的文章](http://objccn.io/issue-23-1/) 和 Matteo 的文章 [iOS 上的相机捕捉](http://objccn.io/issue-21-3/)。对于我们而言，我们想从镜头获得 raw 格式的数据。这里有一个摄像头，我们通过创建一个 `AVCaptureDeviceInput` 对象来完成这个工作。使用 `AVCaptureSession `，我们可以把它连接到一个 `AVCaptureVideoDataOutput`。这个 data output 有一个符合 `AVCaptureVideoDataOutputSampleBufferDelegate` 协议的代理对象。这个代理将用来接受每一帧的消息：

```swift
func captureOutput(captureOutput: AVCaptureOutput!,
                   didOutputSampleBuffer: CMSampleBuffer!,
                   fromConnection: AVCaptureConnection!) {
```

We will use this to drive our image rendering. In our sample code, we have wrapped up the configuration, initialization, and delegate object into a simple interface called `CaptureBufferSource`. You can initialize it with a camera position (either front or back), and a callback, which, for each sample buffer, gets a callback with the buffer and the transform for that camera:

我们将用它来驱动我们的图像渲染。在我们的示例代码中，我们已经结束了配置以及初始化，并且代理对象进入一个简单的 interface `CaptureBufferSource`。我们可以使用前置或者后置摄像头，一个回调来初始化他，其中，对于每个缓存区的实例，都会得到一个回调和变换该摄像头的初始化：

```swift
source = CaptureBufferSource(position: AVCaptureDevicePosition.Front) {
   (buffer, transform) in
   ...
}
```

We need to transform the image data from the camera. The pixel data from the camera is always in the same orientation, no matter how we turn the iPhone. In our case, we lock the UI in portrait orientation, and we want the image onscreen to align with the image the camera sees. For that, we need the back-facing camera's image to be rotated by -π/2. The front-facing camera needs to be both rotated by -π/2 and mirrored. We express this as a `CGAffineTransform`. Note that our transform would be different if the UI had a different orientation (e.g. landscape). Note also that this transformation is very cheap, because it is done inside the Core Image rendering pipeline.

我们需要对相机返回的数据进行转码，无论你如何转动 iPhone，像素数据总是朝着相同的方向。在我们的例子中，我们把 UI 锁定在正方向，我们都希望屏幕上显示的图像方向符合我们拍摄时看到的样子，为此我们需要后置摄像头的照片旋转 -π/2 角度。前置摄像头需要旋转两个 -π/2 角度，并且加一个镜像效果。我们把这个称作为一个 `CGAffineTransform`。请注意如果 UI 是不同的方向，我们的变换将是不同的。还要注意，这种转换的代价是非常小的，因为他在 Core Image 渲染过程中完成。

Next, to convert a `CMSampleBuffer` into a `CIImage`, we first need to convert it into a `CVPixelBuffer`. We can write a convenience initializer that does this for us:

接着，要把 `CMSampleBuffer` 转换成 `CIImage`，我们首先需要先转换成一个 `CVPixelBuffer`。我们可以扩展一个方便的初始化方法为我们做这些事：

```swift
extension CIImage {
    convenience init(buffer: CMSampleBuffer) {
        self.init(CVPixelBuffer: CMSampleBufferGetImageBuffer(buffer))
    }
}
```

Now, we can process our image in three steps. First, we convert our `CMSampleBuffer` into a `CIImage`, and apply a transform so the image is rotated correctly. Next, we apply a `CIFilter` to get a new `CIImage` out. We use the style in [Florian's article](/issue-16/functional-swift-apis.html) for creating filters. In this case, we use a hue adjust filter, and pass in an angle that depends on time. Finally, we use our custom view defined in the previous section to render our `CIImage` using a `CIContext`. This flow is very simple, and looks like this:

现在我们用三个步骤来可以处理我们的图像。首先把我们的 `CMSampleBuffer` 转换成 `CIImage`，并且应用一个 Transform，使图像旋转到正确的方向。接下来，我们应用一个 `CIFilter` 滤镜得到一个新的 `CIImage` 输出。我们使用 [Florian 的文章](http://objccn.io/issue-16-4/) 提到的创建滤镜的方式。在这个例子中，我们使用色调调整滤镜，并且依赖时间通过一个角度(*PS: 不够优雅，原文是 pass in an angle that depends on time*)。最终，我们把事先定义的 View 用 `CIContext` 转换成 `CIImage`。这个流程非常简单，看起来是这样的：

```swift
source = CaptureBufferSource(position: AVCaptureDevicePosition.Front) {
  [unowned self] (buffer, transform) in
    let input = CIImage(buffer: buffer).imageByApplyingTransform(transform)
    let filter = hueAdjust(self.angleForCurrentTime)
    self.coreImageView?.image = filter(input)
}
```

When you run this, you might be surprised by the lack of CPU usage. The great thing about this setup is that all the hard work happens on the GPU. Even though we create a `CIImage`, apply a filter, and create a new `CIImage` out of it, the resulting image is a *promise*: it is not computed until it actually renders. A `CIImage` object can be many things under the hood: it can be pixel data on the GPU, it can be a description of how to create pixel data (for example, when using a generator filter), or it can be created directly from OpenGL textures.

当你运行它的时候，你可能会因为 CPU 的低使用率吃惊。这其中的奥秘是 GPU 做了几乎所有的工作。尽管我们创建了一个 `CIImage`，应用了一个滤镜，并输出一个新的 `CIImage`，但无论如何，最终渲染出来的结果都遵守一个*约定*：不呈现就不去渲染。一个 `CIImage` 对象可以是黑箱里的很多东西，它可以是 GPU 算出来的像素数据，也可以是如何创建像素数据的一个流程（例如使用一个滤镜），或者他也可以直接从 OpenGL 创建纹理。

Here's a video of the result:

下面是演示视频

<video style="display:block;max-width:100%;height:auto;border:0;" controls="1">
  <source src="http://img.objccn.io/issue-23/camera.m4v"></source>
</video>

## Getting Pixel Data from a Movie File
## 从影片中获取像素数据

Another thing we can do is filter a movie through Core Image. Instead of camera frames, we now generate pixel buffers from each movie frame. We will take a slightly different approach here. While the camera pushed frames to us, we use a pull-driven approach for the movie: using a display link, we ask AVFoundation for a frame at a specific time.

我们同样可以通过 Core Image 把这个滤镜加到一个视频中。和实时拍摄不同，我们为影片的每一帧都生成像素缓冲区，在这里将采用略有不同的方法。相机会推送每一帧给我们，在影片处理中，我们要用一个 pull-drive 的方式：通过 display link，可以让每一帧停止在特定时间。

A display link is an object that sends us messages every time a frame needs to be drawn, and sends this synchronously with the display's refresh rate. This is often used for [custom animations](http://www.objc.io/issue-12/interactive-animations.html), but can be used to play and manipulate video as well. The first thing we will do is create an `AVPlayer` and a video output:

display link 是每帧需要绘制的时候给我们发消息的对象，并按照显示器的刷新频率同步发送出去。这通常用于 [自定义动画](http://objccn.io/issue-12-6/)，但也可以用来播放和操作视频。我们要做的第一件事就是创建一个 `AVPlayer` 和一个视频输出：

```swift
player = AVPlayer(URL: url)
videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferDict)
player.currentItem.addOutput(videoOutput)
```

Then we set up our display link. Doing that is as simple as creating a `CADisplayLink` object and adding it to the run loop:

这样，我们就创建了 display link。这样做很简单，只要创建一个 `CADisplayLink` 对象，并将其添加到 run loop。

```swift
let displayLink = CADisplayLink(target: self, selector: "displayLinkDidRefresh:")
displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
```

Now, the only thing left to do is to fetch a video frame on each `displayLinkDidRefresh:` invocation. First, we take the current time and convert it into a timescale in terms of the item we're currently playing. Then we ask the `videoOutput` if there's a new pixel buffer available for the current time, and if there is one, we copy it over and call our callback method:

现在，唯一要做的就是获取视频每一帧的 `displayLinkDidRefresh:` 调用。首先，我们获取当前的时间，并且转换成当前播放项目的一个时间表。然后我们轮询 `videoOutput`，如果当前时间有一个可用的新的像素缓存区，我们把它复制过来并且调用回调方法：

```swift
func displayLinkDidRefresh(link: CADisplayLink) {
    let itemTime = videoOutput.itemTimeForHostTime(CACurrentMediaTime())
    if videoOutput.hasNewPixelBufferForItemTime(itemTime) {
        let pixelBuffer = videoOutput.copyPixelBufferForItemTime(itemTime, itemTimeForDisplay: nil)
        consumer(pixelBuffer)
    }
}
```

The pixel buffer that we get from a video output is a `CVPixelBuffer`, which we can directly convert into a `CIImage`. Like in the sample above, we will filter this image. In this case, we'll combine multiple filters: we use a kaleidoscope effect, and then use gradient mask to combine the original image with the filtered image. The result is slightly funky:

我们从视频输出获得的像素缓冲器是一个 `CVPixelBuffer` 对象，可以直接转换成 `CIImage` 对象。正如上面的例子，我们会加上一个滤镜。在这种情况下，我们将结合多个滤镜：我们使用一个万花筒的效果，然后用渐变遮罩把原始图像和过滤图像相结合，这个操作是非常轻量级的。

<video style="display:block;max-width:100%;height:auto;border:0;" controls="1">
  <source src="http://img.objccn.io/issue-23/video.m4v"></source>
</video>

## Getting Creative with Filters
## 创意地使用滤镜

Everybody knows the popular photo effects. While we can apply these to video, too, Core Image can do much more.

大家都知道流行的照片效果。虽然我们可以将这些应用到视频，Core Image 还可以做更多。

The thing that Core Image calls a *filter* comes in different categories. Some of these are of the traditional type that take an input image and produce an output image. But others take two (or more) input images and combine them to generate the output image. Others again take no input images at all, but generate an image based on parameters.

Core Image 调用的滤镜有不同的类别。其中一些是传统的类型，输入一张图片并且输出一张新的图片。但有些需要两个（或者更多）的输入图像并且混合生成一张新的图像。甚至是不输入图片就可以输出一张基于参数的图像。

By combining these various types, we can created unexpected effects.

通过混合这些不同的类型，我们可以创建意想不到的效果。

### Combining Images
### 混合图片

In our example, we use something like this:

在这个例子中，我们使用这些东西：

    image --------------------------->background|
           \---> [kaleidoscope] ----->foreground| ----> resulting image
              [generate circle] ----->mask      |

The example above pixelates a circular part of an image.

上面的例子可以像素填充一个圆形区域。

It’s possible to create interaction, too. We could use touch events to change to position of the generated circle.

它也可以创建交互，我们可以使用触摸事件来改变所产生的圆的位置。

The [Core Image Filter Reference](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html) lists all available filters by category. Note that some of these are only available on OS X.

[Core Image Filter Reference](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html)按类别列出了所有可用的滤镜。请注意，有一部分只能用在 OS X。

The generators and gradient filters produce images without an input. They are rarely useful on their own, but can be very powerful when used as masks, such as with `CIBlendWithMask` in our example.

有些滤镜不需要输入就可以输出图形，他们很少可以自己单独使用，但是作为蒙版的时候会非常强大，就像我们例子中的 `CIBlendWithMask`。

The composite operation and `CIBlendWithAlphaMask` and `CIBlendWithMask` allow combining two images into one.

混合操作和 `CIBlendWithAlphaMask` 还有 `CIBlendWithMask` 允许两个图像合并成一个。

<a name="cpuvsgpu"></a>
## CPU vs. GPU

Our article from Issue #3, [Getting Pixels onto the Screen](http://www.objc.io/issue-3/moving-pixels-onto-the-screen.html), describes the *graphics stack* of both iOS and OS X. The important thing to note is the notion of the CPU vs. the GPU, and how data moves between the two.

我们在 issue #3 的文章，[绘制像素到屏幕上](http://objccn.io/issue-3-1/)，介绍了 iOS 和 OS X 的图形上下文栈。需要注意的是 CPU 和 GPU 的概念，以及两者之间数据的移动方式。

When working on live video, we face performance challenges.

视频播放的时候，我们面临着性能的挑战。

First, we need to be able to process all image data within the time we have for each frame. The 24 fps (frames per second) cat movie we are using in our samples gives us 41 ms (1/24 seconds) to decode, process, and render all 1 million pixels in each frame.

首先，我们需要能在每一帧的时间内处理完所有的图像数据。我们的样本中采用 24 帧每秒的视频，这意味着我们有 41 毫秒（1/24秒）的时间来解码，处理，渲染每一帧中的百万像素。

Second, we need to be able to get all these pixels from the CPU to the GPU. The bytes from the movie file that we read off disk will end up in the CPU's domain. But the data needs to be on the GPU in order to be visible on the display.

再者，我们需要能够从 CPU 或者 GPU 上面得到这些数据。我们从视频文件读取的字节数最终会经过 CPU。但是这个数据还需要移动到 GPU 上，以便在显示器上可见。

### Avoiding Roundtrips
### 避免转移

One very fatal yet easily overseen problem happens when the code moves the image data back and forth between the CPU and GPU multiple times during the render pipeline. It is important to make sure that the pixel data moves in one direction only: from the CPU to the GPU. Even better is if the data stays on the GPU entirely.

数据从 CPU 到 GPU 转移的过程中，会存在一个致命的问题，确保像素数据仅在一个方向移动是很重要的，最好是数据完全在 GPU 上。

If we want to render at 24 fps, we have 41 ms; if we render at the full 60 fps, we only have 16 ms. If we accidentally download a pixel buffer from the GPU to the CPU, and then upload it back to the GPU, we are moving 3.8 MB of data in each direction for a fullscreen iPhone 6 image. That's going to break our frame rate.

如果我们想渲染 24 fps 的视频，我们有 41 毫秒；如果我们渲染 60 fps 的视频，我们只有 16 毫秒，如果我们不小心从 GPU 下载一个像素数据，然后再上传到 GPU，对于一部 iPhone 6 的屏幕分辨率，我们将要在每个方向移动 3.8 MB 的数据，这会打破我们的帧速率。

When we're using a CVPixelBuffer, we want a flow like this:

当我们使用 `CVPixelBuffer`，我们希望这样的流程：

<img src="http://img.objccn.io/issue-23/flow.svg" alt="Flow of image data" width="620px" height="232px">


The `CVPixelBuffer` is CPU based (see below). We wrap it with a `CIImage`. Building our filter chain does not move any data around; it simply builds a recipe. Once we draw the image, we're using a Core Image context based on the same EAGL context as the GLKView that will display the image. The EAGL context is GPU based. Note how we only cross the GPU-CPU boundary once. That's the crucial part.

`CVPixelBuffer` 是基于 CPU 的（见下文），我们用它包装`CIImage`。形成我们的滤镜链，不移走任何数据；他只是建立了一个流程。一旦我们绘制图像，我们使用了基于 EAGL 上下文的 Core Image 图形上下文，作为 GLKView 显示的图像。EAGL 上下文是基于 GPU 的。请注意，我们如何只穿越 GPU-CPU 边界一次，这是至关重要的组成部分。

### Work and Target
### 工作和目标

The Core Image context can be created in two ways: as a GPU context using an `EAGLContext` or as a CPU-based context.

Core Image 的图形上下文可以通过两种方式创建：使用 `EAGLContext` 的 GPU 上下文，或者是基于 CPU 的上下文。

This defines where Core Image will do its work — where pixel data will be processed. Independent of that, both GPU- and CPU-based contexts can render to the CPU using the `createCGImage(…)`, `render(_, toBitmap, …)` and `render(_, toCVPixelBuffer, …)`, methods, as well as related methods.

这个定义了 Core Image 工作的地方——像素数据将被处理的地方。除去这些，基于 GPU 和基于 CPU 的图形上下文都可以让 CPU 执行 `createCGImage(…)`，`render(_, toBitmap, …)` 和 `render(_, toCVPixelBuffer, …)` ，以及相关的命令。

It's important to understand how this moves pixel data between the CPU and GPU, or keeps all data on either the CPU and GPU. Moving data across this boundary comes at a cost.

重要的是要理解移动 CPU 和 GPU 之间的像素数据，或者是让数据保持在 CPU 或者 GPU 上，越过这个边界是需要很大的代价的。

### Buffers and Images
### 缓冲器和图像

In our sample, we are using a few different *buffers* and *images*. This can be a bit confusing. The reason for this is quite simply that different frameworks have different uses for these “images.” Here's a very quick overview to show which ones are CPU- and GPU-based, respectively:

在我们的例子中，我们使用了几个不同的*缓冲区*和*图像*。这可能有点混乱。这样做的原因很简单，不同的框架对于这些‘图像’有不同的用途。下面有一个快速预览，以显示哪些是以基于 CPU 或者基于 GPU 为主：


| 类          | 描述    |
|----------------|----------------|
| CIImage        | These can represent two things: image data or a recipe to generate image data. |
|                | The output of a CIFilter is very lightweight. It's just a description of how it is generated and does not contain any actual pixel data.
|                | If the output is image data, it can be either raw pixel `NSData`, a `CGImage`, a `CVPixelBuffer`, or an OpenGL texture. |
| CVImageBuffer  | This is an abstract superclass of `CVPixelBuffer` (CPU) and `CVOpenGLESTexture` (GPU). |
| CVPixelBuffer  | A Core Video pixel buffer is CPU based. |
| CMSampleBuffer | A Core Media sample buffer wraps either a `CMBlockBuffer` or a `CVImageBuffer`, in addition to metadata.
| CMBlockBuffer  | A Core Media block buffer is CPU based. |

Note that `CIImage` has quite a few convenience methods to, for example, load an image from JPEG data or a `UIImage` directly. Behind the scenes, these will use a `CGImage`-based `CIImage`.

需要注意的是 `CIImage` 有很多方便的方法，例如，加载一个 JPEG 图像或者直接加载一个 `UIImage` 对象。在后台，这些将会使用一个基于 `CGImage` 的 `CIImage`。

## Conclusion
## 小结

Core Image is a great tool for manipulating live video. When you have the proper setup, the performance is great — just make sure there are no roundtrips between the GPU and CPU. By using filters creatively, you can achieve very interesting effects that go way beyond a simple hue or sepia filter. All this code can be easily abstracted, and a solid understanding of where the different objects live (on the GPU or CPU) helps in getting the necessary performance.

Core Image 是操纵实时视频的一大利器。只要你适当的配置下，性能将会是强劲的——只要确保 CPU 和 GPU 之间没有数据的转移。创意地使用滤镜，你可以实现一个灰常炫酷的效果，神马简单色调，褐色滤镜都弱爆啦。所有的这些代码都很容易分离出来，深入了解下各个类的工作原理会帮助你提高代码的性能。

---

[话题 #23 下的更多文章](http://www.objccn.io/issue-23)

原文 [Core Image and Video](http://www.objc.io/issue-23/core-image-video.html)