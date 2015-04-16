The process of decoding a video on OS X and iOS is complex.

在 OS X 和 iOS 设备上进行视频解码的过程是比较复杂的。

In order to get a grasp on what is happening on our machines, we first need to understand the underlying concepts. Only then can we talk about implementation details.

为了详细了解解码过程中所发生的事情，我们首先要了解一些基本概念。这样才能去挖掘具体的实现细节。

## A Brief History of Hardware Accelerated Decoding on Macs

## Mac 硬件加速解码的简史

CPU load is expensive and codecs are complex. When video decoding with software on computers became popular, it was revolutionary. With the introduction of QuickTime 1.0 and its C-based API in the early 90s, you were able to have a thumbnail-sized video playing, with up to 32,768 possible colors per pixel decoded solely by the CPU. Up until this point, only specialized computers with certain graphics hardware were able to play color video.

用 CPU 处理视频的代价非常昂贵，而且编解码器也非常复杂。当软解码流行起来的时候，他是具有革命意义的。随着 QuickTime 1.0 和他的基于 C 语言的 API 的引进，你可以播放一个缩略图大小的视频，多达 32,768 个像素点完全由 CPU 进行解码。在当时，只有具有专门的图形硬件的计算机才能播放彩色视频。

![QuickTime 1.0](http://img.objccn.io/issue-23/qt1_1.gif) 
[图片来源](http://www.emaculation.com/forum/viewtopic.php?t=5060)

By the end of the century, DVDs had been introduced using the then state-of-the-art [MPEG-2 video codec](http://en.wikipedia.org/wiki/MPEG-2). Subsequently, Apple added DVD drives to its PowerBooks and ran into an issue: the combination of G3 PowerPC CPUs and batteries was not efficient enough to play a full DVD on a single charge. The solution was to add a dedicated decoding chip by [C-Cube](http://en.wikipedia.org/wiki/C-Cube) to the motherboard for all the heavy lifting. This chip can be found on the Wallstreet, Lombard, and Pismo PowerBook generations, as well as on their professional desktop equivalents.

到 20 世纪末，DVD 引进了当时最先进的 [MPEG-2 视频解码器](http://zh.wikipedia.org/wiki/MPEG-2)。随后，苹果将 DVD 驱动器加到了 PowerBooks（MacBook 的前身，06 年停产），但是发现一个问题：电脑电池和 CPU 的配合不够高效率，充一次电居然没办法播放完一整部 DVD 视频。解决方案是在主板上添加一个专用的解码芯片 [C-Cube](http://zh.wikipedia.org/wiki/C-Cube)，来处理这些繁重的事务。这款芯片可以在 PowerBook G3 这代产品上找到，也可以在专业级的桌面设备上找到。

Apple never exposed a public API, so DVD playback was limited to its own application until the introduction of Mac OS X in 2001, which initially did not include a DVD playback application at all.[^2]

苹果从不暴露一个公共 API，所以在 2001 年 Mac OS X 问世之前 DVD 只能限制在自己的应用程序中播放 DVD，在这之前根本没有一个播放视频的程序。[^2]

By the early 2000s, CPUs and batteries were evolving in a way that they could reasonably decode MPEG-2 video without help from a dedicated chip — at least as long as there wasn't any further demanding process running on the machine (like Mail.app, which constantly checked a remote server).

到了 21 世纪初，CPU 和 电池的发展足以独立解码 MPEG-2，而不再需要一个专门的芯片 —— 至少只要没有特别消耗资源的程序运行在后台（就像 Mail.app，不断地请求一个远程服务器）。

In the mid 00s, a new kid arrived on the block and remains the dominant video codec on optical media, digital television broadcasting, and online distribution: [H.264/AVC/MPEG-4 Part 10](http://en.wikipedia.org/wiki/H.264). MPEG’s fourth generation video codec introduced radical improvements over previous generations with dramatically decreased bandwidth needs. However, this came at a cost: increased CPU load and the need for dedicated decoding hardware, especially on embedded devices like the iPhone. Without the use of the provided DSPs, battery life suffers — typically by a factor of 2.5 — even with the most efficient software decoders.

在 00 年代中期，一个新生儿出现了，并且保持着光学媒体，数字电视广播，以及在线视频编解码的主导地位：他就是 [H.264/AVC/MPEG-4 Part 10](http://zh.wikipedia.org/wiki/H.264)。MPEG 的第四代编解码技术有效地降低了带宽需求。然而这是有代价的：增加 CPU 和专用解码硬件的需求，特别是在嵌入式设备像 iPhone。不使用所提供的 DSP，电池的寿命会急剧下降，通常会降低 2.5 **（倍/百分比）？** —— 哪怕是最高效的的软件解码技术。

With the introduction of QTKit — a Cocoa Wrapper of the QuickTime API — on OS X 10.5 Leopard, Apple delivered an efficient software decoder. It was highly optimized with handcrafted assembly code, and further improved upon in OS X 10.6 by the deployment of the clang compiler as demonstrated at WWDC 2008. What Apple didn't mention back then is the underlying ability to dynamically switch to hardware accelerated decoding depending on availability and codec profile compatibility. This feature was based on two newly introduced private frameworks: Video Toolbox and Video Decode Acceleration (VDA).

随着 QTKit 的引入 —— 一个 Cocoa 封装的 QuickTime API —— 最早出现在 OS X 10.5，苹果公开了一个高效率的软件解码器。这是用汇编高度优化的，在 WWDC 2008 大会上，clang 编译器的部署证明了 OS X 10.6 性能的提升。

In 2008, Adobe Flash Video switched from its legacy video codecs[^3] to H.264 and started to integrate hardware accelerated decoding in its cross-platform playback applications. On OS X, Adobe's team discovered that the needed underlying technology was actually there and deployed by Apple within QTKit-based applications, but it was not available to the outside world. This changed in OS X 10.6.3 with a patch against the 10.6 SDK, which added a single header file for VDA.

What’s inside VDA? It is a small framework wrapping the H.264 hardware decoder, which may or may not work. This is based on whether or not it can handle the input buffer of the encoded data that is provided. If the decoder can handle the input, it will return the decoded frames. If it can't, the session creation will fail, or no frames will be returned with an undocumented error code. There are four different error states available, none of them being particularly verbose.[^4] There is no official documentation beyond the header file and there is no software fallback either.

Fast-forward to the present: in iOS 8 and OS X 10.8, Apple published the full Video Toolbox framework. It is a beast!
It can compress and decompress video at real time or faster. Hardware accelerated video decoding and encoding can be enabled, disabled, or enforced at will. However, documentation isn’t staggering: there are 14 header files, and Xcode’s documentation reads “Please check the header files.”

Furthermore, without actual testing, there is no way of knowing the supported codec, codec profile, or encoding bitrate set available on any given device. Therefore, a lot of testing and device-specific code is needed. Internally, it appears to be similar to the modularity of the original QuickTime implementation. The external API is the same across different operating systems and platforms, while the actual available feature set varies.

Based on tests conducted on OS X 10.10, a Mac typically supports H.264/AVC/MPEG-4 Part 10 (until profile 100 and up to level 5.1), MPEG-4 Part 2, H.263, MPEG-1 and MPEG-2 Video and Digital Video (DV) in software, and usually both H.264 and MPEG-4 Part 2 in hardware.

On iOS devices with an [A4 up to A6 SoC](http://en.wikipedia.org/wiki/Apple_system_on_a_chip), there is support for H.264/AVC/MPEG-4 Part 10 (until profile 100 and up to level 5.1), MPEG-4 Part 2, and H.263.

The A7 SoC added support for H.264’s profile 110, which allows the individual color channels to be encoded with 10 bits instead of 8 bits, allowing a greater level of color detail. This feature is typically used in the broadcasting and content creation industries.

While the A8 seems to include basic support for the fifth-generation codec HEVC / H.265, as documented in the FaceTime specifications for the equipped devices, it is not exposed to third-party applications. This is expected to change in subsequent iOS releases,[^5] but might be limited to future devices.

##Video Toolbox

###When Do You Need Direct Access to Video Toolbox?

Out of the box, Apple’s SDKs provide a media player that can deal with any file that was playable by the QuickTime Player. The only exception is for contents purchased from the iTunes Store which are protected by FairPlay2, the deployed Digital Rights Management. In addition, Apple's SDKs include support for Apple’s scaleable HTTP streaming protocol [HTTP Live Streaming (HLS)](http://en.wikipedia.org/wiki/HTTP_Live_Streaming) on iOS and OS X 10.7 and above. HLS typically consists of small chunks of H.264/AAC video stored in the [MPEG-TS container format](http://en.wikipedia.org/wiki/MPEG_transport_stream), and playlists that allow the client application to switch dynamically between different versions, depending on the available hardware.

If you have control over the encoding and production of the content that is going to be displayed on iOS or OS X devices, then you can use the default playback widgets. Depending on the deployed device and operating system version, the default player will behave correctly, enable hardware accelerated decoding, or transparently fall back on a software solution in case of an error. This is also true for the high-level frameworks AVKit and AVFoundation. Of course, all of them are backed by Video Toolbox, but this is nothing that need concern the average developer.

However, there are more container formats than just MP4 — for example, MKV. There are also further scaleable HTTP streaming protocols developed by Adobe and Microsoft, like DASH or Smooth Streaming, which also deploy a similar set of video codecs, but different container formats and intrinsically different protocols. Supporting custom container formats or protocols is a breeze with Video Toolbox. It accepts raw video streams as input and also allows on-device encoding of raw or already encoded video. The result is then made accessible for further processing, be it storage in a file or active streaming to the network. Video Toolbox is an elegant way to achieve performance on par with Apple’s native solutions, and its usage is described in [WWDC 2014 Session #513, "Direct Access to Video Encoding and Decoding](https://developer.apple.com/videos/wwdc/2014/#513)," as well as the very basic [VideoTimeLine sample code project](https://developer.apple.com/devcenter/download.action?path=/wwdc_2014/wwdc_2014_sample_code/usingVideoToolboxtodecodecompressedsamplebuffers.zip).

A final word on Video Toolbox deployment on iOS devices. It was introduced as a private framework in iOS 4 and was recently made public in iOS 8. When building applications with a deployment target less than 8.0, including Video Toolbox won't lead to any problems, since the actual symbols stayed the same and the API is virtually unchanged. However, any worker session creation will be terminated with the undocumented error -12913, as the framework is not available for sandboxed applications on previous OS releases due to security concerns.

###Basic Concepts of Video Toolbox Usage

Video Toolbox is a C API depending on the CoreMedia, CoreVideo, and CoreFoundation frameworks and based on sessions with three different types available: compression, decompression, and pixel transfer. It derives various types from the CoreMedia and CoreVideo frameworks for time and frame management, such as CMTime or CVPixelBuffer.

To illustrate the basic concepts of Video Toolbox, the following paragraphs will describe the creation of a decompression session along with the needed structures and types. A compression session is essentially very similar to a decompression session, while in practice, a pixel transfer session should be rarely needed.

To initialize a decompression session, Video Toolbox needs to know about the input format as part of a `CMVideoFormatDescriptionRef` structure, and — unless you want to use the undocumented default — your specified output format as plain CFDictionary reference. A video format description can be obtained from an AVAssetTrack instance or created manually with `CMVideoFormatDescriptionCreate` if you are using a custom demuxer. Finally, decoded data is provided through an asynchronous callback mechanism. The callback reference and the video format description are required by `VTDecompressionSessionCreate`, while setting the output format is optional.

###What Is a Video Format Description?

It is an opaque structure describing the encoded video. It includes a [FourCC](http://en.wikipedia.org/wiki/FourCC) indicating the used codec, the video dimensions, and a dictionary documented as `extensions`. What are those? On OS X, hardware accelerated decoding is optional and disabled by default. To enable it, the `kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder` key must be set, optionally combined with `kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder` set to fail if hardware accelerated playback is not available. This is not needed on iOS, as accelerated decoding is the only available option. Furthermore, `extensions` allows you to forward metadata required by modern video codecs such as MPEG-4 Part 2 or H.264 to the decoder.[^6] Additionally, it may contain metadata to handle support for non-square pixels with the `CVPixelAspectRatio` key.

###The Video Output Format

This is a plain CFDictionary. The result of a decompression session is a raw, uncompressed video image. To optimize for speed, it is preferable to have the hardware decoder output's native [chroma format](http://en.wikipedia.org/wiki/Chroma_subsampling), which appears to be `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange`. However, a number of further formats are available, and transformation is performed in a rather efficient way using the GPU. It can be set using the `kCVPixelBufferPixelFormatTypeKey` key. We also need to set the dimensions of the output using `kCVPixelBufferWidthKey` and `kCVPixelBufferHeightKey` as plain integers. An optional key worth mentioning is `kCVPixelBufferOpenGLCompatibilityKey`, which allows direct drawing of the decoded image in an OpenGL context without copying the data back and forth between the main bus and the GPU. This is sometimes referenced as a *0-copy pipeline*, as no copy of the decoded image is created for drawing.[^7]

###Data Callback Record

`VTDecompressionOutputCallbackRecord` is a simple structure with a pointer to the callback function invoked when frame decompression (`decompressionOutputCallback`) is complete. Additionally, you need to provide the instance of where to find the callback function (`decompressionOutputRefCon`). The `VTDecompressionOutputCallback` function consists of seven parameters:

* the callback's reference value
* the frame's reference value
* a status flag (with undefined codes)
* info flags indicating synchronous / asynchronous decoding, or whether the decoder decided to drop the frame
* the actual image buffer
* the presentation timestamp
* the presentation duration

The callback is invoked for any decoded or dropped frame. Therefore, your implementation should be highly optimized and strictly avoid any copying. The reason is that the decoder is blocked until the callback returns, which can lead to decoder congestion and further complications. Additionally, note that the decoder will always return the frames in the decoding order, which is absolutely not guaranteed to be the playback order. Frame reordering is up to the developer.

###Decoding Frames

Once your session is created, feeding frames to the decoder is a walk in the park. It is a matter of calling `VTDecompressionSessionDecodeFrame` repeatedly, with a reference to the session and a sample buffer to decode, and optionally with advanced flags. The sample buffer can be obtained from an `AVAssetReaderTrackOutput`, or alternatively, it can be created manually from a raw memory block, along with timing information, using `CMBlockBufferCreateWithMemoryBlock`, `CMSampleTimingInfo`, and `CMSampleBufferCreate`.

###Conclusion

Video Toolbox is a low-level, highly efficient way to speed up video processing in specific setups. The higher level framework AVFoundation allows decompression of supported media for direct display and compression directly to a file. Video Toolbox is the tool of choice when support of custom file formats, streaming protocols, or direct access to the codec chain is required. On the downside, profound knowledge of the involved video technology is required to master the sparsely documented API. Regardless, it is the way to go to achieve an engaging user experience with better performance, increased efficiency, and extended battery life.

####References

- [Apple Sample Code](https://developer.apple.com/devcenter/download.action?path=/wwdc_2014/wwdc_2014_sample_code/usingVideoToolboxtodecodecompressedsamplebuffers.zip)
- [WWDC 2014 Session #513](https://developer.apple.com/videos/wwdc/2014/#513)

[^2]: DVD Player as we know it was introduced in OS X 10.1. Until then, third-party tools like VLC media player were the only playback option for DVDs on OS X.
[^3]: Sorenson Spark, On2 TrueMotion VP6
[^4]: `kVDADecoderHardwareNotSupportedErr`, `kVDADecoderFormatNotSupportedErr`, `kVDADecoderConfigurationError`, `kVDADecoderDecoderFailedErr`
[^5]: Apple published a job description for a management position in HEVC development in summer 2013.
[^6]: Namely the `kCMFormatDescriptionExtension_SampleDescriptionExtensionAtoms` *ESDS* or respectively *avcC*.
[^7]: Remember, "memcpy is murder." Mans Rullgard, Embedded Linux Conference 2013, [http://free-electrons.com/blog/elc-2013-videos/](http://free-electrons.com/blog/elc-2013-videos/)