The process of decoding a video on OS X and iOS is complex.

在 OS X 和 iOS 设备上进行视频解码的过程是比较复杂的。

In order to get a grasp on what is happening on our machines, we first need to understand the underlying concepts. Only then can we talk about implementation details.

为了详细了解编解码过程中所发生的事情，我们首先要了解一些基本概念。这样才能去挖掘具体的实现细节。

## A Brief History of Hardware Accelerated Decoding on Macs

## Mac 硬件加速解码的简史

CPU load is expensive and codecs are complex. When video decoding with software on computers became popular, it was revolutionary. With the introduction of QuickTime 1.0 and its C-based API in the early 90s, you were able to have a thumbnail-sized video playing, with up to 32,768 possible colors per pixel decoded solely by the CPU. Up until this point, only specialized computers with certain graphics hardware were able to play color video.

用 CPU 处理视频的代价非常昂贵，而且编解码器也非常复杂。当软解码流行起来的时候，他是具有革命意义的。随着 QuickTime 1.0 和他的基于 C 语言的 API 的引进，你可以播放一个缩略图大小的视频，多达 32,768 个像素点完全由 CPU 进行解码。在当时，只有具有专门的图形硬件的计算机才能播放彩色视频。

![QuickTime 1.0](http://img.objccn.io/issue-23/qt1_1.gif) 
[图片来源](http://www.emaculation.com/forum/viewtopic.php?t=5060)

By the end of the century, DVDs had been introduced using the then state-of-the-art [MPEG-2 video codec](http://en.wikipedia.org/wiki/MPEG-2). Subsequently, Apple added DVD drives to its PowerBooks and ran into an issue: the combination of G3 PowerPC CPUs and batteries was not efficient enough to play a full DVD on a single charge. The solution was to add a dedicated decoding chip by [C-Cube](http://en.wikipedia.org/wiki/C-Cube) to the motherboard for all the heavy lifting. This chip can be found on the Wallstreet, Lombard, and Pismo PowerBook generations, as well as on their professional desktop equivalents.

到 20 世纪末，DVD 引进了当时最先进的 [MPEG-2 视频解码器](http://zh.wikipedia.org/wiki/MPEG-2)。随后，苹果将 DVD 驱动器加到了 PowerBooks（MacBook 的前身，06 年停产），但是发现一个问题：电脑电池和 CPU 的配合不够高效率，充一次电居然没办法播放完一整部 DVD 视频。解决方案是在主板上添加一个专用的解码芯片 [C-Cube](http://zh.wikipedia.org/wiki/C-Cube)，来处理这些繁重的事务。这款芯片可以在 PowerBook G3 这代产品上找到，也可以在专业级的桌面设备上找到。

Apple never exposed a public API, so DVD playback was limited to its own application until the introduction of Mac OS X in 2001, which initially did not include a DVD playback application at all.

苹果从不暴露一个公共 API，所以在 2001 年 Mac OS X 问世之前 DVD 只能限制在自己的应用程序中播放 DVD，在这之前根本没有一个播放视频的程序。[^2]

By the early 2000s, CPUs and batteries were evolving in a way that they could reasonably decode MPEG-2 video without help from a dedicated chip — at least as long as there wasn't any further demanding process running on the machine (like Mail.app, which constantly checked a remote server).

到了 21 世纪初，CPU 和 电池的发展足以独立解码 MPEG-2，而不再需要一个专门的芯片 —— 至少只要没有特别消耗资源的程序运行在后台（就像 Mail.app，不断地请求一个远程服务器）。

In the mid 00s, a new kid arrived on the block and remains the dominant video codec on optical media, digital television broadcasting, and online distribution: [H.264/AVC/MPEG-4 Part 10](http://en.wikipedia.org/wiki/H.264). MPEG’s fourth generation video codec introduced radical improvements over previous generations with dramatically decreased bandwidth needs. However, this came at a cost: increased CPU load and the need for dedicated decoding hardware, especially on embedded devices like the iPhone. Without the use of the provided DSPs, battery life suffers — typically by a factor of 2.5 — even with the most efficient software decoders.

在 00 年代中期，一个新生儿出现了，并且保持着光学媒体，数字电视广播，以及在线视频编解码的主导地位：他就是 [H.264/AVC/MPEG-4 Part 10](http://zh.wikipedia.org/wiki/H.264)。MPEG 的第四代编解码技术有效地降低了带宽需求。然而这是有代价的：增加 CPU 和专用解码硬件的需求，特别是在嵌入式设备像 iPhone。不使用专门的 DSP，电池的寿命会急剧下降，通常会降低 2.5 **（倍/百分比）？** —— 哪怕是最高效的的软件解码技术。

With the introduction of QTKit — a Cocoa Wrapper of the QuickTime API — on OS X 10.5 Leopard, Apple delivered an efficient software decoder. It was highly optimised with handcrafted assembly code, and further improved upon in OS X 10.6 by the deployment of the clang compiler as demonstrated at WWDC 2008. What Apple didn't mention back then is the underlying ability to dynamically switch to hardware accelerated decoding depending on availability and codec profile compatibility. This feature was based on two newly introduced private frameworks: Video Toolbox and Video Decode Acceleration (VDA).

随着 QTKit 的引入 —— 一个 Cocoa 封装的 QuickTime API —— 最早出现在 OS X 10.5，苹果公开了一个高效率的软件解码器。这是用汇编语言深度优化的，在 WWDC 2008 大会上，clang 编译器证明了 OS X 10.6 性能的提升。苹果公司当时没有提到一个潜在的能力 —— 根据可用性和兼容性，动态切换到硬解码。这个特性是基于两个私有框架： 视频工具箱和视频解码加速（VDA）。

In 2008, Adobe Flash Video switched from its legacy video codecs to H.264 and started to integrate hardware accelerated decoding in its cross-platform playback applications. On OS X, Adobe's team discovered that the needed underlying technology was actually there and deployed by Apple within QTKit-based applications, but it was not available to the outside world. This changed in OS X 10.6.3 with a patch against the 10.6 SDK, which added a single header file for VDA.

2008 年，Adobe 从原来的解码器 [^3] 切换到 H.264 上面，并且开始在他的跨平台播放器上整合硬件加速解码。对于 OS X，Adobe 的团队发现需要的底层技术都有，并部署在基于苹果的 QTKit 框架的应用程序上，但是苹果不对外开放。苹果公司在 OS X 10.6.3 上有所改变，苹果发布了一个补丁针对 10.6 的 SDK，里面加了一个单独的 VDA 头文件。

What’s inside VDA? It is a small framework wrapping the H.264 hardware decoder, which may or may not work. This is based on whether or not it can handle the input buffer of the encoded data that is provided. If the decoder can handle the input, it will return the decoded frames. If it can't, the session creation will fail, or no frames will be returned with an undocumented error code. There are four different error states available, none of them being particularly verbose. There is no official documentation beyond the header file and there is no software fallback either.

VDA 里面有什么？这是一个封装了 H.264 硬件解码器的小框架，他可能工作也可能不工作，这取决于他是否可以处理所提供编码数据的输入缓冲器。如果解码器可以处理上述请求，他将返回解码的帧，否则会话创建失败，或者不返回帧，只返回一个错误码。这里有四种不同的错误状态，哪个都不是特别详细。[^4] 除去仅有的头文件，既没有官方文档，也没有备用的解决方案。

Fast-forward to the present: in iOS 8 and OS X 10.8, Apple published the full Video Toolbox framework. It is a beast!
It can compress and decompress video at real time or faster. Hardware accelerated video decoding and encoding can be enabled, disabled, or enforced at will. However, documentation isn’t staggering: there are 14 header files, and Xcode’s documentation reads “Please check the header files.”

快进到现在：在 iOS 8 和 OS X 10.8，苹果开放了完整的视频工具箱框架。这就像一头野兽！它可以实时编解码视频甚至更快。硬件加速的视频解码，可以启用，也可以禁用，还可以中途执行。但是文档并不冗余：只有 14 个头文件，Xcode 文档中只写有一句话 “请移步头文件”

Furthermore, without actual testing, there is no way of knowing the supported codec, codec profile, or encoding bitrate set available on any given device. Therefore, a lot of testing and device-specific code is needed. Internally, it appears to be similar to the modularity of the original QuickTime implementation. The external API is the same across different operating systems and platforms, while the actual available feature set varies.

此外，如果没有实际的测试，就没有办法知道所支持的编解码器，编解码信息，或者在任意设备上可用的解码比特率。因此，大量的测试和设备专用的代码是有必要的。它的核心似乎是 QuickTime 的执行模块。外部 API 在不同操作系统和平台上是相同的，实际可用的特性是不一定的。

Based on tests conducted on OS X 10.10, a Mac typically supports H.264/AVC/MPEG-4 Part 10 (until profile 100 and up to level 5.1), MPEG-4 Part 2, H.263, MPEG-1 and MPEG-2 Video and Digital Video (DV) in software, and usually both H.264 and MPEG-4 Part 2 in hardware.

基于 OS X 10.10 进行的测试，Mac 平台上软解码通常支持 H.264/AVC/MPEG-4 Part 10（until profile 100 and up to level 5.1），MPEG-4 Part 2，H.263，MPEG-1 和 MPEG-2 ，DV。硬解码支持 H.264 和 MPEG-4 Part 2。

On iOS devices with an [A4 up to A6 SoC](http://en.wikipedia.org/wiki/Apple_system_on_a_chip), there is support for H.264/AVC/MPEG-4 Part 10 (until profile 100 and up to level 5.1), MPEG-4 Part 2, and H.263.

在 iOS 设备上 [A4 到 A6](http://en.wikipedia.org/wiki/Apple_system_on_a_chip)，支持 H.264/AVC/MPEG-4 Part 10 （until profile 100 and up to level 5.1），MPEG-4 Part 2 和 H.263。

The A7 SoC added support for H.264’s profile 110, which allows the individual color channels to be encoded with 10 bits instead of 8 bits, allowing a greater level of color detail. This feature is typically used in the broadcasting and content creation industries.

A7 的 Soc 加入了对 H.264’s profile 110 的支持，它允许各个颜色通道从 8 位增加到 10位，允许更高级别的色彩细节。这个功能通常用于电视台或者媒体编辑行业。

While the A8 seems to include basic support for the fifth-generation codec HEVC / H.265, as documented in the FaceTime specifications for the equipped devices, it is not exposed to third-party applications. This is expected to change in subsequent iOS releases, but might be limited to future devices.

A8 似乎是包含第五代解码器 HEVC / H.265 的支持，作为支持 FaceTime 记录规格的设备，它不暴露给第三方应用程序。预计这个特性会在以后的 iOS 版本中有改变，[^5] 但是似乎仅限于新的设备。

## Video Toolbox
## 视频工具箱

### When Do You Need Direct Access to Video Toolbox?
### 什么时候需要直接访问视频工具箱？

Out of the box, Apple’s SDKs provide a media player that can deal with any file that was playable by the QuickTime Player. The only exception is for contents purchased from the iTunes Store which are protected by FairPlay2, the deployed Digital Rights Management. In addition, Apple's SDKs include support for Apple’s scaleable HTTP streaming protocol [HTTP Live Streaming (HLS)](http://en.wikipedia.org/wiki/HTTP_Live_Streaming) on iOS and OS X 10.7 and above. HLS typically consists of small chunks of H.264/AAC video stored in the [MPEG-TS container format](http://en.wikipedia.org/wiki/MPEG_transport_stream), and playlists that allow the client application to switch dynamically between different versions, depending on the available hardware.

开箱即用，苹果的 SDK 提供一个媒体播放器，可以播放任何 QuickTime 兼容的格式视频。唯一的区别是需要为 iTunes 商店中受 FairPlay2 保护的内容付费，FaiPlay2 是一个数字版权管理的机构。此外，苹果的 SDK 包括苹果公司的可扩展的 HTTP 流媒体协议支持 [HTTP Live Streaming (HLS)](http://en.wikipedia.org/wiki/HTTP_Live_Streaming)，这项协议被用在 iOS 以及 OS X 10.7 以上。HLS 通常包括一小块 [MPEG-TS 格式](http://en.wikipedia.org/wiki/MPEG_transport_stream) 的 H.264/AAC 视频，并且允许客户端根据可用的硬件，在不同的版本之间动态选择。

If you have control over the encoding and production of the content that is going to be displayed on iOS or OS X devices, then you can use the default playback widgets. Depending on the deployed device and operating system version, the default player will behave correctly, enable hardware accelerated decoding, or transparently fall back on a software solution in case of an error. This is also true for the high-level frameworks AVKit and AVFoundation. Of course, all of them are backed by Video Toolbox, but this is nothing that need concern the average developer.

如果你要做视频编解码，并且播放在 iOS 或者 OS X 设备上的项目，你可以使用默认的播放控件。根据部署的设备型号和操作系统版本，默认的播放器都可以正常运行，启动硬件加速解码，或者突然回落到软件解码，有可能会出现错误。这也适用于高层框架 AVKit 和 AVFoundation。当然，他们都是基于视频工具箱的支持的，不过这些开发者不需要知道。

However, there are more container formats than just MP4 — for example, MKV. There are also further scaleable HTTP streaming protocols developed by Adobe and Microsoft, like DASH or Smooth Streaming, which also deploy a similar set of video codecs, but different container formats and intrinsically different protocols. Supporting custom container formats or protocols is a breeze with Video Toolbox. It accepts raw video streams as input and also allows on-device encoding of raw or already encoded video. The result is then made accessible for further processing, be it storage in a file or active streaming to the network. Video Toolbox is an elegant way to achieve performance on par with Apple’s native solutions, and its usage is described in [WWDC 2014 Session #513, "Direct Access to Video Encoding and Decoding](https://developer.apple.com/videos/wwdc/2014/#513)," as well as the very basic [VideoTimeLine sample code project](https://developer.apple.com/devcenter/download.action?path=/wwdc_2014/wwdc_2014_sample_code/usingVideoToolboxtodecodecompressedsamplebuffers.zip).

然而除去 MP4 之外，还有更多的编码格式，例如 MKV。也有 Adobe 和微软开发的进一步可扩展的 HTTP 流媒体协议，比如 DASH 或者 Smooth Streaming （瀑布流），他们也部署了一套类似的视频编解码器，但他们是不同的格式，不同的协议。视频工具箱支持自定义格式或协议是轻而易举的事情。他接受原始的视频流作为输入，而且允许设备对原始编码或者已经编码的视频进行编码。生成的结果将随后访问，以便进一步处理，无论储存在文件也好，上传到网络也罢。视频工具箱是一个优雅的方式来达到原生解决方案的性能。而且它的用法在 [WWDC 2014 Session #513, "Direct Access to Video Encoding and Decoding](https://developer.apple.com/videos/wwdc/2014/#513) 有描述，还有很基本的 [代码](https://developer.apple.com/devcenter/download.action?path=/wwdc_2014/wwdc_2014_sample_code/usingVideoToolboxtodecodecompressedsamplebuffers.zip)

A final word on Video Toolbox deployment on iOS devices. It was introduced as a private framework in iOS 4 and was recently made public in iOS 8. When building applications with a deployment target less than 8.0, including Video Toolbox won't lead to any problems, since the actual symbols stayed the same and the API is virtually unchanged. However, any worker session creation will be terminated with the undocumented error -12913, as the framework is not available for sandboxed applications on previous OS releases due to security concerns.

最后再补充一点关于视频工具箱。它在 iOS 4 上作为一个私有的框架，在最近的 iOS 8 开放给开发者。建立 target 低于 8.0 的项目时，includ 视频工具箱不会有任何问题，因为实际的 API 大部分是不变的。然而，任何新建会话的请求将会以 error -12913 被终止，因为出于安全考虑，这个框架不适用于旧版本 OS 的沙盒程序。

### Basic Concepts of Video Toolbox Usage
### 视频工具箱用法的基本概念

Video Toolbox is a C API depending on the CoreMedia, CoreVideo, and CoreFoundation frameworks and based on sessions with three different types available: compression, decompression, and pixel transfer. It derives various types from the CoreMedia and CoreVideo frameworks for time and frame management, such as CMTime or CVPixelBuffer.

视频工具箱是一个基于 CoreMedia，CoreVideo，CoreFoundation  框架的 C 语言 API，并且基于三种可用类型的会话：压缩，解压缩，像素移动。它从 CoreMedia 和 CoreVideo 框架时间和帧管理推导不同数据的类型，例如 CMTime 或 CVPixelBuffer。

To illustrate the basic concepts of Video Toolbox, the following paragraphs will describe the creation of a decompression session along with the needed structures and types. A compression session is essentially very similar to a decompression session, while in practice, a pixel transfer session should be rarely needed.

为了说明视频工具箱的基本概念，一下段落将描述创建一个解压会话，只包含必要的结构和类型。压缩会话和解压缩会话是非常相似的，而在实践中，一个像素的传送会话应该尽可能的少。

To initialize a decompression session, Video Toolbox needs to know about the input format as part of a `CMVideoFormatDescriptionRef` structure, and — unless you want to use the undocumented default — your specified output format as plain CFDictionary reference. A video format description can be obtained from an AVAssetTrack instance or created manually with `CMVideoFormatDescriptionCreate` if you are using a custom demuxer. Finally, decoded data is provided through an asynchronous callback mechanism. The callback reference and the video format description are required by `VTDecompressionSessionCreate`, while setting the output format is optional.

初始化解压会话的时候，视频工具箱需要知道输入的格式作为 `CMVideoFormatDescriptionRef` 构造的一部分，—— 除非你想使用默认的无参数 —— 你指定的输入格式为 CFDictionary 类型。视频格式的描述可以从 AVAssetTrack 实例来获取或者手动创建 `CMVideoFormatDescriptionCreate`。最后，解码数据是通过异步回调机制提供的。回调和视频格式的描述都需要 `VTDecompressionSessionCreate`，同时设置输出格式是可选的。

### What Is a Video Format Description?
### 什么是视频格式说明

It is an opaque structure describing the encoded video. It includes a [FourCC](http://en.wikipedia.org/wiki/FourCC) indicating the used codec, the video dimensions, and a dictionary documented as `extensions`. What are those? On OS X, hardware accelerated decoding is optional and disabled by default. To enable it, the `kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder` key must be set, optionally combined with `kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder` set to fail if hardware accelerated playback is not available. This is not needed on iOS, as accelerated decoding is the only available option. Furthermore, `extensions` allows you to forward metadata required by modern video codecs such as MPEG-4 Part 2 or H.264 to the decoder. Additionally, it may contain metadata to handle support for non-square pixels with the `CVPixelAspectRatio` key.

它是描述视频文件编码的构造的。它包含一个 [FourCC](http://en.wikipedia.org/wiki/FourCC) 描述编解码器，视频尺寸，并记录成一个字典作为文件扩展描述。这些是什么？在 OS X 上，硬件加速解码是可选的，默认情况下禁用。要启用它，在 `kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder` 中必须设置，或者如果没有生效的话，在 `kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder` 中也要设置。在 iOS 上这些是没有必要的，硬件加速解码是唯一的选择，此外，`extensions` 允许你转发现代视频编解码器所需要的元数据，如 MPEG-4 Part 2 或 H.264。[^6] 此外，它可能包含元数据来通过 `CVPixelAspectRatio` 键来处理非方形像素。

### The Video Output Format
### 视频输出格式

This is a plain CFDictionary. The result of a decompression session is a raw, uncompressed video image. To optimize for speed, it is preferable to have the hardware decoder output's native [chroma format](http://en.wikipedia.org/wiki/Chroma_subsampling), which appears to be `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange`. However, a number of further formats are available, and transformation is performed in a rather efficient way using the GPU. It can be set using the `kCVPixelBufferPixelFormatTypeKey` key. We also need to set the dimensions of the output using `kCVPixelBufferWidthKey` and `kCVPixelBufferHeightKey` as plain integers. An optional key worth mentioning is `kCVPixelBufferOpenGLCompatibilityKey`, which allows direct drawing of the decoded image in an OpenGL context without copying the data back and forth between the main bus and the GPU. This is sometimes referenced as a *0-copy pipeline*, as no copy of the decoded image is created for drawing.

这是一个纯 CFDictionary。解压会话的结果是一个原始的，未压缩的视频图像。为了高效率的输出，优选为具有硬解码能力的机器输出本机的 [色度格式](http://en.wikipedia.org/wiki/Chroma_subsampling)，这似乎是 `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange`。然而，有许多更进一步的视频格式提供，并且转码过程中有 GPU 参与，效率非常高。它可以通过设置 `kCVPixelBufferPixelFormatTypeKey` 键来启用，我们还需要设置 `kCVPixelBufferWidthKey` 和 `kCVPixelBufferHeightKey` 作为输出的尺寸。有一个可选的键也值得一提 `kCVPixelBufferOpenGLCompatibilityKey`，它允许在 OpenGL 的上下文直接绘图，而不是从总线和 CPU 之间复制数据。这有时候被称为 *零拷贝通道*，作为一个专门用来零拷贝的解码图像。[^7]

### Data Callback Record
### 数据回调记录

`VTDecompressionOutputCallbackRecord` is a simple structure with a pointer to the callback function invoked when frame decompression (`decompressionOutputCallback`) is complete. Additionally, you need to provide the instance of where to find the callback function (`decompressionOutputRefCon`). The `VTDecompressionOutputCallback` function consists of seven parameters:

* the callback's reference value
* the frame's reference value
* a status flag (with undefined codes)
* info flags indicating synchronous / asynchronous decoding, or whether the decoder decided to drop the frame
* the actual image buffer
* the presentation timestamp
* the presentation duration

`VTDecompressionOutputCallbackRecord` 是一种帧解码 `decompressionOutputCallback` 完成时调用的结构简单的指针函数。此外，在调用这个回调函数 `decompressionOutputRefCon ` 时你需要提供这个实例。该 `VTDecompressionOutputCallback` 函数包括七个函数：

* 回调的相关参数
* 帧的相关参数
* 一个状态标识（与不确定的代码）
* 指示同步异步解码、是否打算丢帧的标识
* 实际图像缓冲
* 演示时间戳
* 演示持续时间

The callback is invoked for any decoded or dropped frame. Therefore, your implementation should be highly optimized and strictly avoid any copying. The reason is that the decoder is blocked until the callback returns, which can lead to decoder congestion and further complications. Additionally, note that the decoder will always return the frames in the decoding order, which is absolutely not guaranteed to be the playback order. Frame reordering is up to the developer.

所有解码或者丢帧的时候都会调用这个回调。因此，你的实现必须高度优化，严格控制任何复制。原因是解码器会被阻塞直到回调返回，这可能导致译码器堵塞和进一步的阻塞。此外，请注意解码器总是会按解码顺序返回帧，这样绝不可能保证播放顺序。帧是由开发者重新排序的。

### Decoding Frames
### 解码帧

Once your session is created, feeding frames to the decoder is a walk in the park. It is a matter of calling `VTDecompressionSessionDecodeFrame` repeatedly, with a reference to the session and a sample buffer to decode, and optionally with advanced flags. The sample buffer can be obtained from an `AVAssetReaderTrackOutput`, or alternatively, it can be created manually from a raw memory block, along with timing information, using `CMBlockBufferCreateWithMemoryBlock`, `CMSampleTimingInfo`, and `CMSampleBufferCreate`.

一旦会话创建，把帧输入解码器就像在公园里散步。这个过程重复调用 `VTDecompressionSessionDecodeFrame`，具有参考会话和实例缓冲区进行解码，并可选标识。实例缓冲可以从 `AVAssetReaderTrackOutput` 获得，或者可以从原始储存器块创建，连同定时信息，使用 `CMBlockBufferCreateWithMemoryBlock`，`CMSampleTimingInfo` 和 `CMSampleBufferCreate`。

### Conclusion
### 小结

Video Toolbox is a low-level, highly efficient way to speed up video processing in specific setups. The higher level framework AVFoundation allows decompression of supported media for direct display and compression directly to a file. Video Toolbox is the tool of choice when support of custom file formats, streaming protocols, or direct access to the codec chain is required. On the downside, profound knowledge of the involved video technology is required to master the sparsely documented API. Regardless, it is the way to go to achieve an engaging user experience with better performance, increased efficiency, and extended battery life.

在特殊配置下，视频工具箱是一个底层的，高效率的方式。上级框架 AVFoundation 允许直接把支持的媒体文件解压并且显示到屏幕上，或者直接压缩到一个文件。当需要支持自定义文件格式，流媒体协议，或直接访问编解码器链的时候，视频工具箱是首选的工具。在缺点方面，所涉及到的视频技术，需要高深的知识，掌握不常见 API 的使用很有必要。无论如何，这都是实现更好的用户体验，更高的效率，延长电池寿命的必经之路。

#### References
#### 参考

- [苹果示例代码](https://developer.apple.com/devcenter/download.action?path=/wwdc_2014/wwdc_2014_sample_code/usingVideoToolboxtodecodecompressedsamplebuffers.zip)
- [WWDC 2014 Session #513](https://developer.apple.com/videos/wwdc/2014/#513)

[^2]: 我们都知道 DVD 播放器是在 OS X 10.1 开始引用的。在此之前，第三方软件像 VLC 播放器只能在 OS X 上播放 DVD。
[^3]: Sorenson Spark, On2 TrueMotion VP6
[^4]: `kVDADecoderHardwareNotSupportedErr`, `kVDADecoderFormatNotSupportedErr`, `kVDADecoderConfigurationError`, `kVDADecoderDecoderFailedErr`
[^5]: 苹果在 2013 年夏天的 HEVC 发布了一个管理职位。
[^6]: 即 `kCMFormatDescriptionExtension_SampleDescriptionExtensionAtoms` *ESDS* 或 *avcC*。
[^7]: 请记住, "内存拷贝就是犯罪" Mans Rullgard，2013 Linux 嵌入式会议， [http://free-electrons.com/blog/elc-2013-videos/](http://free-electrons.com/blog/elc-2013-videos/)