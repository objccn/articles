在 OS X 和 iOS 设备上进行视频解码的过程是比较复杂的。

为了详细了解编解码过程中所发生的事情，我们首先要了解一些基本概念。这样才能去挖掘具体的实现细节。

## Mac 硬件加速解码的简史

用 CPU 处理视频的代价非常昂贵，而且编解码器也非常复杂。软解码的流行是具有革命意义的。随着 90 年代早期 QuickTime 1.0 和它的基于 C 语言的 API 的出现，你可以播放一个缩略图那么大的视频，每个像素最多有 32,768 种可能的颜色，它们完全由 CPU 进行解码。在当时，只有具有专门的图形硬件的计算机才能播放彩色视频。

![QuickTime 1.0](/images/issues/issue-23/qt1_1.gif) 
[图片来源](http://www.emaculation.com/forum/viewtopic.php?t=5060)

到 20 世纪末，使用了当时最先进的 [MPEG-2 视频解码器](http://zh.wikipedia.org/wiki/MPEG-2) 的 DVD 被引进千家万户。随后，苹果将 DVD 驱动器加到了 PowerBooks (MacBook 的前身，2006 年停产)，但是却发现了一个问题：电脑电池和 G3 PowerPC CPU 的配合不够高效，充一次电居然没办法播放完一整部 DVD 视频。解决方案是在主板上添加一个 [C-Cube](http://zh.wikipedia.org/wiki/C-Cube) 生产的专用解码芯片，来处理这些繁重的事务。这款芯片可以在 Wallstreet，Lombard 和 Pismo 三款 PowerBook 上找到，也可以在它们所对应的专业级的桌面电脑上找到。

苹果从没有提供公共 API，所以在 2001 年 Mac OS X 问世之前 DVD 只能限制在自带的应用程序中播放。而从 Mac OS X 开始它就不再包含 DVD 播放程序了。

> 我们所知道的 DVD 播放器是在 OS X 10.1 开始引入的。在此之前，只能使用像 VLC 这样的第三方软件在 OS X 上播放 DVD。

到了 21 世纪初，CPU 和 电池的发展足以独立解码 MPEG-2，而不再需要一个专门的芯片 —— 至少只要没有特别消耗资源的程序运行在后台 (比如 Mail.app 这样不断地请求一个远程服务器的进程)。

在 00 年代中期，一个新生儿出现了，并且占据了着激光读取，数字电视广播，以及在线视频编解码的主导地位：它就是 [H.264/AVC/MPEG-4 Part 10](http://zh.wikipedia.org/wiki/H.264)。相比前几代，MPEG 的第四代编解码技术有效地降低了带宽需求。然而这是有代价的：增加了 CPU 负担以及对专用解码硬件的需求，特别是在像 iPhone 这样的嵌入式设备里这个要求尤为明显。若不使用专门的数字信号处理器 (DSP)，电池的寿命会急剧下降，通常会增至 2.5 倍的能耗 —— 哪怕是使用最高效的的软件解码技术。

随着 QTKit 这个 Cocoa 封装的 QuickTime API 在 OS X 10.5 Leopard 上的出现，苹果公开了一个高效率的软件解码器。这是用汇编语言深度优化的，并且得益于在 WWDC 2008 大会上演示过的 clang 编译器的开发，这个解码器的性能在 OS X 10.6 中得到了进一步的提升。苹果公司当时没有提到一个潜在的能力 —— 根据可用性和解码配置的兼容性，可以动态切换到硬件解码。这个特性是基于两个新引入的私有框架：视频工具箱 (Video Toolbox) 和视频解码加速 (Video Decode Acceleration, VDA)。

2008 年，Adobe 从原来的解码器 (Sorenson Spark, On2 TrueMotion VP6) 切换到 H.264 上面，并且开始在它的跨平台播放器上整合硬件加速解码。对于 OS X，Adobe 的团队发现所需要的底层技术都是存在的，并被部署在基于苹果的 QTKit 框架的应用程序里，但是苹果不对外开放。苹果公司在 OS X 10.6.3 上有所改变，苹果发布了一个针对 10.6 SDK 的补丁，里面为 VDA 添加了一个头文件。

VDA 里面有什么？这是一个封装了 H.264 硬件解码器的小框架，它可能工作也可能不工作，这取决于它是否能处理所提供的编码数据的输入缓冲。如果解码器可以处理上述请求，它将返回解码的帧，否则会话创建失败，或者不返回帧而只返回一个错误码。这里有四种不同的错误状态 (`kVDADecoderHardwareNotSupportedErr`, `kVDADecoderFormatNotSupportedErr`, `kVDADecoderConfigurationError`, `kVDADecoderDecoderFailedErr`)，哪个都不是特别详细。除去仅有的头文件，既没有官方文档，也没有备用的解决方案。

快进到现在：在 iOS 8 和 OS X 10.8，苹果开放了完整的视频工具箱框架。这就像一头野兽！它可以实时编解码视频甚至更快。你可以启用或者禁用硬件加速的视频解码，甚至可以中途改变。但是文档并不那么让人满意：这个框架有 14 个头文件，Xcode 文档中只写有一句话 “请移步头文件”

此外，如果没有实际的测试，就没有办法知道所支持的编解码器，编解码配置，或者在任意设备上可用的解码比特率。因此，大量的测试和设备专用的代码是有必要的。内部来看，它和原始的 QuickTime 模块的实现很相似。外部 API 在不同操作系统和平台上是相同的，但实际可用的特性是不一定的。

[A4 到 A6](http://en.wikipedia.org/wiki/Apple_system_on_a_chip) 的 iOS 设备是支持 H.264/AVC/MPEG-4 Part 10 (until profile 100 and up to level 5.1)，MPEG-4 Part 2 和 H.263 的。

A7 加入了对 H.264’s profile 110 的支持，它允许各个颜色通道从 8 位编码增加到 10 位，这使更高级别的色彩细节成为可能。这个功能通常用于电视台或者媒体编辑行业。

A8 似乎是包含第五代解码器 HEVC / H.265 的支持，这在支持 FaceTime 的设备的规格特性描述中有所记载，但它没有暴露给第三方应用程序。预计这会在以后的 iOS 版本中有改变，但是可能仅限于新的设备。

> 苹果在 2013 年夏天发布了一个 HEVC 开发的管理职位。

## 视频工具箱

### 什么时候需要直接访问视频工具箱？

苹果的 SDK 提供了一个开箱即用的媒体播放器，它可以播放任何 QuickTime 兼容的格式视频。唯一不能播放的是在 iTunes 商店里购买的受 FairPlay2 这个数字版权管理保护的内容。此外，苹果的 SDK 包括对苹果公司的可扩展的 HTTP 流媒体协议 [HTTP Live Streaming (HLS)](http://en.wikipedia.org/wiki/HTTP_Live_Streaming) 的支持，这项协议被用在 iOS 以及 OS X 10.7 及以上的系统中。HLS 通常包括一小块存储为 [MPEG-TS 格式](http://en.wikipedia.org/wiki/MPEG_transport_stream) 的 H.264/AAC 视频，并且允许客户端根据可用的硬件，在不同的版本之间动态切换。

如果你要在显示在 iOS 或者 OSX 的内容上面覆盖控件的话，你可以使用默认的播放框体。根据部署的设备型号和操作系统版本，默认的播放器都可以正常运行，启用硬件加速解码，或者在发生错误时无缝地回滚到软件解码。这也适用于像 AVKit 和 AVFoundation 这样的高层框架。当然，它们都是基于视频工具箱的支持的，不过普通开发者并不需要知道这些。

然而除去 MP4 之外，还有更多的编码格式，例如 MKV。也有 Adobe 和微软开发的进一步可扩展的 HTTP 流媒体协议，比如 DASH 或者 Smooth 流媒体，它们也部署了一套类似的视频编解码器，但它们是不同的格式，从本质上来说是不同的协议。视频工具箱支持自定义格式或协议是轻而易举的事情。它接受原始的视频流作为输入，而且允许在设备上对原始的或者已经编码的视频进行编码。生成的结果存储在文件里或者上传到网络流中，以便随后访问和进一步处理。视频工具箱是一种优雅的来达到原生解决方案性能的方式。而且它的用法在 [WWDC 2014 Session #513, "Direct Access to Video Encoding and Decoding](https://developer.apple.com/videos/wwdc/2014/#513) 有描述，还有很基本的[代码](https://developer.apple.com/devcenter/download.action?path=/wwdc_2014/wwdc_2014_sample_code/usingVideoToolboxtodecodecompressedsamplebuffers.zip)

最后再补充一点 iOS 设备上视频工具箱开发的知识。它在 iOS 4 上作为一个私有的框架被引入，在最近的 iOS 8 开放给开发者。建立 target 低于 8.0 的项目时，导入视频工具箱不会有任何问题，因为实际的 API 大部分没有改变。然而，任何新建会话的请求将会因为无文档的错误 -12913 被终止，因为出于安全考虑，这个框架不适用于旧版本 OS 的沙盒程序。

### 视频工具箱用法的基本概念

视频工具箱是一个基于 CoreMedia，CoreVideo，CoreFoundation 框架的 C 语言 API，并且基于三种可用类型的会话：压缩，解压缩，像素移动。它从 CoreMedia 和 CoreVideo 框架衍生了一些不同的关于时间和帧管理的数据类型，例如 CMTime 或 CVPixelBuffer。

为了说明视频工具箱的基本概念，以下段落将描述如何创建一个只包含必要的结构和类型的解压会话。压缩会话和解压缩会话是非常相似的，而在实践中，像素的传送会话应该是基本用不到的。

初始化解压会话的时候，视频工具箱需要知道以 `CMVideoFormatDescriptionRef` 结构体描述的输入的格式，以及 —— 除非你想使用默认的无参数 —— 你通过 CFDictionary 指定的输出格式。视频格式的描述可以从 AVAssetTrack 实例来获取或者如果你使用自定义分路器 (demuxer) 的话，可以通过 `CMVideoFormatDescriptionCreate` 手动创建。最后，解码后的数据是通过异步回调机制提供的。回调引用和视频格式的描述在调用 `VTDecompressionSessionCreate` 时需要，而设置输出格式是可选的。

### 什么是视频格式描述

它是一个描述编码视频的不透明结构体。它包含一个 [四字符码 (FourCC)](http://zh.wikipedia.org/wiki/FourCC) 来描述所使用的编码，视频尺寸，以及一个被叫做 `extensions` 的字典。这些是什么？
在 OS X 上，硬件加速解码是可选的，默认情况下禁用。要启用它，必须将 `kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder` 设置上，或者如果硬件加速播放不可用的话，再配合将 `kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder` 设置为 fail。在 iOS 上这些是没有必要的，因为硬件加速解码是唯一的可用选择，此外，`extensions` 允许你转发像是 MPEG-4 Part 2 或 H.264 这样的先进视频编解码器所需要的元数据 (即 `kCMFormatDescriptionExtension_SampleDescriptionExtensionAtoms` *ESDS* 或 *avcC*。)。此外，它可能包含元数据来通过 `CVPixelAspectRatio` 键处理非方形像素。

### 视频输出格式

which allows direct drawing of the decoded image in an OpenGL context without copying the data back and forth between the main bus and the GPU. This is sometimes referenced as a *0-copy pipeline*, as no copy of the decoded image is created for drawing.

这是一个纯 CFDictionary。解压会话的结果是一个原始的，未压缩的视频图像。为了高效率的输出，硬件解码器输出偏向于选择本机的[色度格式](http://en.wikipedia.org/wiki/Chroma_subsampling)，也就是 `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange`。然而，有许多其他的视频格式可以用，并且转码过程中有 GPU 参与，效率非常高。可以通过设置 `kCVPixelBufferPixelFormatTypeKey` 键来启用，我们还需要通过 `kCVPixelBufferWidthKey` 和 `kCVPixelBufferHeightKey` 来设置整数的输出尺寸。有一个可选的键也值得一提，`kCVPixelBufferOpenGLCompatibilityKey`，它允许在 OpenGL 的上下文中直接绘制解码后的图像，而不是从总线和 CPU 之间复制数据。这有时候被称为**零拷贝通道**，因为在绘制过程中没有解码的图像被拷贝。

> 请记住, "memcpy 就是犯罪" - Mans Rullgard，2013 Linux 嵌入式会议， [http://free-electrons.com/blog/elc-2013-videos/](http://free-electrons.com/blog/elc-2013-videos/)

### 数据回调记录

`VTDecompressionOutputCallbackRecord` 是一个简单的结构体，它带有一个指针 (`decompressionOutputCallback`)，指向帧解压完成后的回调方法。你需要提供可以找到这个回调方法的实例 (`decompressionOutputRefCon`)。`VTDecompressionOutputCallback` 回调方法包括七个参数：

* 回调的引用
* 帧的引用
* 一个状态标识 (包含未定义的代码)
* 指示同步/异步解码，或者解码器是否打算丢帧的标识
* 实际图像的缓冲
* 出现的时间戳
* 出现的持续时间

所有解码或者丢帧的时候都会调用这个回调。因此，你的实现必须高度优化，严格控制任何拷贝。原因是解码器会被阻塞直到回调返回，这可能导致译码器堵塞和进一步的阻塞。此外，请注意解码器总是会按解码顺序返回帧，而解码顺序并不一定就是播放顺序。帧的重新排序是由开发者决定的。

### 解码帧

一旦会话创建，把每一帧输入解码器就像在公园里散步。这个过程就是用会话的引用和要解码的采样缓冲，来重复地调用 `VTDecompressionSessionDecodeFrame`，另外还有可选的高级标识。采样缓冲可以从 `AVAssetReaderTrackOutput` 中获得，或者作为替换，可以使用 `CMBlockBufferCreateWithMemoryBlock`，`CMSampleTimingInfo` 和 `CMSampleBufferCreate`，来连同时间信息一起手动地从原始的内存块中创建。

### 小结

在特殊配置下，视频工具箱是一个底层的，高效率的方式来加速视频处理进程。上层框架 AVFoundation 允许直接把支持的媒体文件解压并且显示到屏幕上，或者直接压缩到一个文件。当需要支持自定义文件格式，流媒体协议，或需要直接访问编解码器链的时候，视频工具箱是首选的工具。缺点上来说，想要掌握这些缺少文档的 API 是需要对复杂的视频技术有着高深的知识的。但无论如何，这都是实现更好的用户体验，更高的效率，以及延长电池寿命的必经之路。

#### 参考

- [苹果示例代码](https://developer.apple.com/devcenter/download.action?path=/wwdc_2014/wwdc_2014_sample_code/usingVideoToolboxtodecodecompressedsamplebuffers.zip)
- [WWDC 2014 Session #513](https://developer.apple.com/videos/wwdc/2014/#513)

---

 

原文 [Video Toolbox and Hardware Acceleration](http://www.objc.io/issue-23/videotoolbox.html)
