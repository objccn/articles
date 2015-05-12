---
title: "Audio API Overview"
category: "24"
date: "2015-05-11 8:00:00"
tags: article
author: "<a href=\"https://twitter.com/danielboedewadt\">Daniel Eggert</a> and <a href=\"https://twitter.com/floriankugler\">Florian Kugler</a>"
---



Both iOS and OS X come with a wide array of audio APIs, ranging from very low level to very high level. The number of different APIs, developed over time as these platforms have grown and changed, can be quite overwhelming to say the least. This article gives a brief overview of the available APIs and the different purposes they serve.

iOS 和 OS X 平台都带来了一系列的操作音频和视频的 API，其中包含从低层级到高层级。随着时间的推移和平台的增长以及改变，不同 API 的数量至少可以说有着非常巨大的改变。这篇文章给出了一个当前可以使用的 API 并且对它们使用的不同目的进行简要的概括。

## Media Player Framework

The Media Player framework on iOS is a high-level API for audio and video playback, and includes a stock user interface you can drop into your app. You can use it to play back items in the user's iPod library, or to play local files or network streams.

Additionally, this framework contains APIs to query the user's media library, as well as to configure system audio controls like on the lock screen or in the control center.

iOS 平台上的 Media Player 框架是一个用于声音和视频播放的高层级的 API，它还包含了一些你可以在应用中直接使用的股票??用户界面。你可以使用它来播放用户在 iPod 库中的项目，或者播放本地文件和网络流。

## AVFoundation

`AVFoundation` is Apple's modern media framework that includes several APIs for different purposes and on different levels of abstraction. Some of these are modern Objective-C wrappers for lower-level C APIs. With a few exceptions, it's available both on iOS and OS X.

`AVFoundation` 是苹果的现代媒体框架，它包含了一些不同的用途的 API 和不同层级的抽象。它们中的有一些是现在 Objective-C 对于底层 C API 的封装。除了少数的例外情况，它可以同时在 iOS 和 OS X 中使用。

### AVAudioSession

`AVAudioSession` is specific to iOS and coordinates audio playback between apps, so that, for example, audio is stopped when a call comes in, or music playback stops when the user starts a movie. This API is needed to make sure an app behaves correctly in response to such events.

`AVAudioSession` 是用于 iOS 系统中协调应用程序之间的音频播放的 API。例如，当有电话打进来时，音频的播放就会被暂停，或者在用户启动电影的时候，音乐的播放就会停止。这个 API 需要确保一个应用程序能够正确响应并处理这类事件。

### AVAudioPlayer

This high-level API gives you a simple interface to play audio from local files or memory. This is a headless audio player (i.e. no UI elements are provided), and it's very straightforward to use. It's not suitable for streaming audio from the network or for low-latency realtime audio applications. If those things are not a concern, this is probably the right choice. The audio player API also comes with a few extra features, such as looping, playback-level metering, etc.

这个高层级的 API 为你提供一个简洁的接口，用于在本地文件或者内存中播放音频。这是一个 headless 并且易用的音频播放器（即不提供任何的 UI 元素）。它不适用于网络音频流或者低延迟的实时音频的播放。如果这些问题并需要担心，那么`AVAudioPlayer ` 可能就是正确的选择。音频播放器的 API 也为我们带来课一些额外的功能，如循环播放，获取音量强度的信息 playback-level metering
等等。

### AVAudioRecorder

As the counterpart to `AVAudioPlayer`, the audio recorder API is the simplest way to record audio straight to a file. Beyond the possibility to receive peak and average power values for a level meter, the API is very bare bones, but might just be what you need if your use case is simple.

作为 `AVAudioPlayer` 的对应部分，使用 `AVAudioRecorder` 对应的 API 是用于将音频录制为文件的最简单的方法。除了接受峰值的可能性和平均功率值的电平表，API 的处理是不加渲染的，但如果你的用例非常的简单，这可能就是你想要的。

### AVPlayer

The `AVPlayer` API gives you more flexibility and control than the APIs mentioned above. Built around the `AVPlayerItem` and `AVAsset` classes, it gives you more granular access to assets, e.g. to pick a specific track. It also supports playlists via the `AVQueuePlayer` subclass, and lets you control whether the asset can be sent over AirPlay.

`AVPlayer` 的 API 给你比上面提到的 API 更多的灵活性和控制。它围绕 `AVPlayerItem` 和 `AVAsset` 类，提供对资源更细颗粒度的访问权限，如选择指定的音轨。它还通过 `AVQueuePlayer` 子类支持播放列表，并且允许你控制这些资源是否可以通过 AirPlay 发送。

A major difference compared to, for example, `AVAudioPlayer`, is `AVPlayer`'s out-of-the-box support for streaming assets from the network. This increases the complexity of playback state handling, but you can observe all state parameters using KVO. 

更加主要的区别是，`AVAudioPlayer` 是对于 `AVPlayer` 对于网络流资源即开即用的支持。这增加了处理播放状态的复杂性，但是你可以使用 KVO 来观测所有的状态参数。

### AVAudioEngine

`AVAudioEngine` is a modern Objective-C API for playback and recording. It provides a level of control for which you previously had to drop down to the C APIs of the Audio Toolbox framework (for example, with real-time audio tasks). The audio engine APIs are built to interface well with lower-level APIs, so you can still drop down to Audio Toolbox if you have to.

`AVAudioEngine` 是播放和录制的现代 Objective-C API。它提供了一系列的控制，解决了很多以前需要深入到 `Audio Toolbox ` 框架中的 C 语言 API 层次才能处理的问题（例如：实时音频播放任务）。该音频引擎的 API 对底层的 API 都建立起了优秀的接口。所以如果你不得不处理底层的问题，你仍然可以使用 Audio Toolbox。

The basic concept of this API is to build up a graph of audio nodes, ranging from source nodes (players and microphones) and overprocessing nodes (mixers and effects) to destination nodes (hardware outputs). Each node has a certain number of input and output busses with well-defined data formats. This architecture makes it very flexible and powerful. And it even integrates with audio units.

这个 API 的基本概念是用于建立音频节点的曲线图，从源节点（播放器和麦克风）以及 overprocessing 节点（混音器和效果器）向目标节点（硬件输出）。每一个节点都具有一定数量的输入和输出总线，同时这些总线也有着良好定义的数据格式。这种结构使得它非常的灵活的强大。而且它甚至集成了音频单元。

## Audio Unit Framework

The Audio Unit framework is a low-level API; all audio technologies on iOS are built on top of it. Audio units are plug-ins that process audio data. A chain of audio units is called an audio processing graph. 

Audio Unit 框架是一个低层级的 API；所有 iOS 中的音频技术都构建在 Audio Unit 这个框架之上。音频单元是用来处理音频数据的插件。链式的音频单元叫做音频处理图。

You may have to use audio units directly or write your own if you need very low latency (e.g. for VoIP or synthesized musical instruments), acoustic echo cancelation, mixing, or tonal equalization. But a lot of this can often be achieved with the `AVAudioEngine` API. If you have to write your own audio units, you can integrate them in an `AVAudioEngine` processing graph with the `AVAudioUnit` node.

你可能需要直接使用音频单元，或者如果你需要非常低的延迟（比如说 VoIP 或合成乐器），回声取消、混音或者音调均衡，那么你就要自己写一个音频单元。但是其中的大部分事情经常可以使用 `AVAudioEngine` 的 API 来解决。如果你不得不写自己的音频单元，你可以将它们与 `AVAudioUnit` 节点一起集成在 `AVAudioEngine` 处理图中。

### Inter-App Audio

The Audio Unit API allows for Inter-App Audio on iOS. Audio streams (and MIDI commands) can be sent between apps. For example, an app can provide an audio effect or filter. Another app can then send its audio to the first app to apply the audio effect. The filtered audio is sent back to the originating app in real time. CoreAudioKit provides a simple UI for Inter-App Audio.

Audio Unit 的 API 允许使用在 iOS 中的跨应用音频中。音频流（和 MIDI 命令）可以在应用程序之间发送。比如说：一个应用可以提供音频的效果器或者滤波器。 另一个应用程序可以将它的音频发送到第一个应用程序中，并使用其中的音频效果。被过滤的音频文件又会被实时地发送回原来的应用程序中。 CoreAudioKit 提供了一个简单的跨应用程序的音频界面。

## Other APIs

### OpenAL

[OpenAL](https://en.wikipedia.org/wiki/OpenAL) is a cross-platform API. It provides positional (3D) and low-latency audio services. It's mostly intended for cross-platform games. The API deliberately resembles the OpenGL API in style.

[OpenAL](https://en.wikipedia.org/wiki/OpenAL) 是一个跨平台的 API。它提供了位置（3D）和低延迟的音频服务。它主要用于跨平台的游戏。这个 API 有意地模仿了 OpenGL 中 API 的风格。


### MIDI

On iOS, Core MIDI and CoreAudioKit can be used to make an app behave as a MIDI instrument. On OS X, Music Sequencing Services gives access to playing MIDI-based control and music data. Core MIDI Server gives server and driver support.

在 iOS 上， Core MIDI 和 CoreAudioKit 可以被用来使应用程序表现的像一个 MIDI 乐器。在 OS X 上，音乐排序服务提供了播放基于 MIDI 的控制和访问音乐数据的权限。Core MIDI 服务为服务器和驱动程序提供了支持。

### Even More

- The most basic of all audio APIs on OS X is the `NSBeep()` function that simply plays the system sound.
- On OS X, the `NSSound` class provides a simple API to play sounds, similar in concept to  `AVAudioPlayer`.
- All notification APIs — local and remote notifications on iOS, `NSUserNotification` on OS X, and CloudKit notifications — can play sounds.
- The Audio Toolbox framework is powerful, but very low level. It's historically C++ based, but most of its functionality is now available through the `AVFoundation` framework.
- The QTKit and QuickTime frameworks are on their way out and should not be used for new development anymore. Use `AVFoundation` (and AVKit) instead.

- 在 OS X 上，最基本的音频 API 就是 `NSBeep()` 函数， 它能够简单的播放系统的声音。
- 在 OS X 中，`NSSound` 类提供了用于播放声音的简单的 API，与 iOS 中的
`AVAudioPlayer` 在概念上基本类似。
- 所有的通知 API — iOS 中的本地通知或者推送通知、 OS X 中的 `NSUserNotification`以及 CloudKit 通知都可以播放声音。
- Audio Toolbox 框架是强大的，但是它的层级非常的低。它基于 C++ 编写，但是其大多数的功能都可以通过 `AVFoundation` 实现。
- QTKit 和 QuickTime 框架现在已经过时了，它们不应该被用在以后的开发中。而使用 `AVFoundation`（和 AVKit）来代替。