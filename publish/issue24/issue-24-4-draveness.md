iOS 和 OS X 平台都有一系列操作音频的 API，其中涵盖了从低到高的全部层级。随着时间的推移、平台的增长以及改变，不同 API 的数量可以说有着非常巨大的变化。本文对当前可以使用的 API 以及它们使用的不同目的进行简要的概括。

## Media Player 框架

Media Player 框架是 iOS 平台上一个用于音频和视频播放的高层级接口，它包含了一个你可以在应用中直接使用的默认的用户界面。你可以使用它来播放用户在 iPod 库中的项目，或者播放本地文件以及网络流。

另外，这个框架也包括了查找用户媒体库中内容的 API，同时还可以配置像是在锁屏界面或者控制中心里的音频控件。

## AVFoundation

`AVFoundation` 是苹果的现代媒体框架，它包含了一些不同的用途的 API 和不同层级的抽象。其中有一些是现代 Objective-C 对于底层 C 语言接口的封装。除了少数的例外情况，`AVFoundation` 可以同时在 iOS 和 OS X 中使用。

### AVAudioSession

`AVAudioSession` 是用于 iOS 系统中协调应用程序之间的音频播放的 API 的。例如，当有电话打进来时，音频的播放就会被暂停；在用户启动电影时，音乐的播放就会停止。我们需要使用这些 API 来确保一个应用程序能够正确响应并处理这类事件。

### AVAudioPlayer

这个高层级的 API 为你提供一个简单的接口，用来播放本地或者内存中的音频。这是一个无界面的音频播放器 (也就是说没有提供 UI 元素)，使用起来也很直接简单。它不适用于网络音频流或者低延迟的实时音频播放。如果这些问题都不需要担心，那么 `AVAudioPlayer` 可能就是正确的选择。音频播放器的 API 也为我们带来了一些额外的功能，比如循环播放、获取音频的音量强度等等。

### AVAudioRecorder

作为与 `AVAudioPlayer` 相对应的 API，`AVAudioRecorder` 是将音频录制为文件的最简单的方法。除了用一个音量计接受音量的峰值和平均值以外，这个 API 简单粗暴，但要是你的使用场景很简单的话，这可能恰恰就是你想要的方法。

### AVPlayer

`AVPlayer` 与上面提到的 API 相比，提供了更多的灵活性和可控性。它基于 `AVPlayerItem` 和 `AVAsset`，为你提供了颗粒度更细的权限来获取资源，比如选择指定的音轨。它还通过 `AVQueuePlayer` 子类支持播放列表，而且你可以控制这些资源是否能够通过 AirPlay 发送。

与 `AVAudioPlayer` 最主要的区别是，`AVPlayer` 对来自网络的流媒体资源的 “开箱即用” 支持。这增加了处理播放状态的复杂性，但是你可以使用 KVO 来观测所有的状态参数来解决这个问题。

### AVAudioEngine

`AVAudioEngine` 是播放和录制的 Objective-C 接口。它提供了以前需要深入到 Audio Toolbox 框架的 C API 才能做的控制 (例如一些实时音频任务)。该音频引擎 API 对底层的 API 建立了优秀的接口。如果你不得不处理底层的问题，你仍然可以使用 Audio Toolbox 框架。

这个 API 的基本概念是建立一个音频的节点图，从源节点 (播放器和麦克风) 以及过处理 (overprocessing) 节点 (混音器和效果器) 到目标节点 (硬件输出)。每一个节点都具有一定数量的输入和输出总线，同时这些总线也有良好定义的数据格式。这种结构使得它非常的灵活和强大。而且它集成了音频单元 (audio unit)。

## Audio Unit 框架

Audio Unit 框架是一个底层的 API；所有 iOS 中的音频技术都构建在 Audio Unit 这个框架之上。音频单元是用来加工音频数据的插件。一个音频单元链叫做音频处理图。

如果你需要非常低的延迟 (如 VoIP 或合成乐器)、回声消除、混音或者音调均衡的话，你可能需要直接使用音频单元，或者自己写一个音频单元。但是其中的大部分工作可以使用 `AVAudioEngine` 的 API 来完成。如果你不得不写自己的音频单元的话，你可以将它们与 `AVAudioUnit` 节点一起集成在 `AVAudioEngine` 处理图中。

### 跨应用程序音频

Audio Unit 的 API 可以在 iOS 中进行跨应用音频。音频流 (和 MIDI 命令) 可以在应用程序之间发送。比如说：一个应用程序可以提供音频的效果器或者滤波器。另一个应用程序可以将它的音频发送到第一个应用程序中，并使用其中的音频效果器处理音频。被过滤的音频又会被实时地发送回原来的应用程序中。 CoreAudioKit 提供了一个简单的跨应用程序的音频界面。

## 其他 APIs

### OpenAL

[OpenAL](https://en.wikipedia.org/wiki/OpenAL) 是一个跨平台的 API。它提供了位置 (3D) 和低延迟的音频服务。它主要用于跨平台游戏的开发。它有意地模仿了 OpenGL 中 API 的风格。

### MIDI

在 iOS 上，Core MIDI 和 CoreAudioKit 可以被用来使应用程序表现为 MIDI 设备。在 OS X 上，Music Sequencing 服务提供了基于 MIDI 的控制和对音乐数据访问的权限。Core MIDI 服务为服务器和驱动程序提供了支持。

### 更多

- 在 OS X 中，最基本的音频接口就是 `NSBeep()`，它能够简单地播放系统中的声音。
- `NSSound` 类为 OS X 提供了用于播放声音的简单接口，与 iOS 中的 `AVAudioPlayer` 在概念上基本类似。
- 所有的通知 API，包括 iOS 中的本地通知或者推送通知、OS X 中的 `NSUserNotification` 以及 CloudKit 通知，都可以播放声音。
- Audio Toolbox 框架是强大的，但是它的层级却非常的低。在过去，它基于 C++ 所编写，但是其大多数的功能现在都可以通过 `AVFoundation` 实现。
- QTKit 和 QuickTime 框架现在已经过时了，它们不应该被用在以后的开发中。我们应该使用 `AVFoundation` (和 AVKit) 来代替它们。

---


 

原文 [Audio API Overview](http://www.objc.io/issue-24/audio-api-overview.html)
