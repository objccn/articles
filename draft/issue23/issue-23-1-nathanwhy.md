With processing power and camera hardware improving with every new release, using iPhones to capture video is getting more and more interesting. They’re small, light, and inconspicuous, and the quality gap with professional video cameras has been narrowing to the point where, in certain situations, an iPhone is a real alternative.
This article discusses the different options to configure a video capture pipeline and get the most out of the hardware.
A sample app with implementations of the different pipelines is available on [GitHub](https://github.com/objcio/VideoCaptureDemo).

随着每一代 iPhone 处理能力和相机硬件配置的提高，使用它来捕获视频也变得更加有意思。它们小巧，轻便，不起眼，而且与专业摄像机之间的差距已经变得非常小，小到在某些情况下，iPhone 真正是个合适的选择。
这篇文章讨论了关于如何配置视频捕获管道和最大限度地利用硬件性能的一些不同选择。
这里有个使用了不同管道的样例 app，可以在 [GitHub](https://github.com/objcio/VideoCaptureDemo) 查看。

## `UIImagePickerController`

By far the easiest way to integrate video capture in your app is by using `UIImagePickerController`. It’s a view controller that wraps a complete video capture pipeline and camera UI.

目前，将视频捕获集成到你的应用中，最简单的方法是使用 UIImagePickerController`。这是一个封装了视频捕获管道和相机 UI 的 view controller。

Before instantiating the camera, first check if video recording is supported on the device:

在实例化相机之前，首先要检查设备是否支持相机录制：

```objc
if ([UIImagePickerController
       isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    NSArray *availableMediaTypes = [UIImagePickerController
      availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    if ([availableMediaTypes containsObject:(NSString *)kUTTypeMovie]) {
        // Video recording is supported.
        // 支持视频录制
    }
}
```

Then create a `UIImagePickerController` object, and define a delegate to further process recorded videos (e.g. to save them to the camera roll) and respond to the user dismissing the camera:

然后创建一个 `UIImagePickerController` 对象，设置好代理便于进一步处理录制好的视频（比如存到相册）和对于用户关闭相机的响应。

```objc
UIImagePickerController *camera = [UIImagePickerController new];
camera.sourceType = UIImagePickerControllerSourceTypeCamera;
camera.mediaTypes = @[(NSString *)kUTTypeMovie];
camera.delegate = self;
```

That’s all the code you need for a fully functional video camera.

这是你实现一个功能完善的摄像机所需要的。

### Camera Configuration
### 相机配置

`UIImagePickerController` does provide some additional configuration options.

`UIImagePickerController` 提供了额外的配置选项。

A specific camera can be selected by setting the `cameraDevice` property. This takes a `UIImagePickerControllerCameraDevice` enum. By default, this is set to `UIImagePickerControllerCameraDeviceRear`, but it can also be set to `UIImagePickerControllerCameraDeviceFront`. Always check first to make sure the camera you want to set is actually available:

通过设置 `cameraDevice` 属性可以选择一个特定的相机。这是一个 `UIImagePickerControllerCameraDevice` 枚举。默认情况下是 `UIImagePickerControllerCameraDeviceRear`，你也可以设置为 `UIImagePickerControllerCameraDeviceFront`。每次都应事先确认你想要设置的相机可以被访问：

```objc
UIImagePickerController *camera = …
if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
    [camera setCameraDevice:UIImagePickerControllerCameraDeviceFront];
}
```

The `videoQuality` property gives some control over the quality of the recorded video. It allows you to set a specific encoding preset, which affects both the bitrate and the resolution of the video. There are six presets:

`videoQuality` 属性用于控制录制视频的质量。它允许你设置一个特定的编码预设，从而改变视频的比特率和分辨率。以下是六种预设：

```objc
enum {
   UIImagePickerControllerQualityTypeHigh             = 0,
   UIImagePickerControllerQualityTypeMedium           = 1,  // default  value
   UIImagePickerControllerQualityTypeLow              = 2,
   UIImagePickerControllerQualityType640x480          = 3,
   UIImagePickerControllerQualityTypeIFrame1280x720   = 4,
   UIImagePickerControllerQualityTypeIFrame960x540    = 5
};
typedef NSUInteger  UIImagePickerControllerQualityType;
```
The first three are relative presets (low, medium, and high). The encoding configuration for these presets can be different for different devices, with high giving you the highest quality available for the selected camera. The other three are resolution-specific presets (640x480 VGA, 960x540 iFrame, and 1280x720 iFrame).

前三种为同一类预设（low, medium, high）。这些预设的编码配置会因设备不同而不同。如果选择 high，那么你选定的相机会提供给你该设备所能支持的最高画质。后面三种是关于特定分辨率的预设（640x480 VGA, 960x540 iFrame, 和 1280x720 iFrame）。

### Custom UI
### 自定义 UI

As mentioned before, `UIImagePickerController` comes with a complete camera UI right out of the box. However, it is possible to customize the camera with your own controls by hiding the default controls and providing a custom view with the controls, which will be overlaid on top of the camera preview:

就像上面提到的，`UIImagePickerController` 自带一套相机 UI，可以直接使用。然而，你也可以自定义相机，通过隐藏默认控件，创建带有控件的自定义视图，覆盖在相机预览图层上面。

```objc
UIView *cameraOverlay = …
picker.showsCameraControls = NO;
picker.cameraOverlayView = cameraOverlay;
```

You then need to hook up the controls in your overlay to the control methods of the `UIImagePickerController` (e.g. `startVideoCapture` and `stopVideoCapture`).

然后你需要将你覆盖层上的控件关联上 `UIImagePickerController` 的控制方法（比如，`startVideoCapture` 和 `stopVideoCapture`）。


## AVFoundation

If you want more control over the video capture process than `UIImagePickerController` provides, you will need to use AVFoundation.

如果你想要更多关于处理捕获视频的方法，而这些方法是 `UIImagePickerController` 所不能提供的，那么你需要使用 AVFoundation。

The central AVFoundation class for video capture is `AVCaptureSession`. It coordinates the flow of data between audio and video inputs and outputs:

AVFoundation 中主要关于视频捕获的类是 `AVCaptureSession`。它协调？了影音输入与输出之间的数据流。

<img src="/images/issue-23/AVCaptureSession.svg" alt="AVCaptureSession setup" width="620px" height="376px">

To use a capture session, you instantiate it, add inputs and outputs, and start the flow of data from the connected inputs to the connected outputs:

使用一个 capture session，你需要先实例化，添加输入与输出，接着启动从输入到输出之间的数据流：

```objc
AVCaptureSession *captureSession = [AVCaptureSession new];
AVCaptureDeviceInput *cameraDeviceInput = …
AVCaptureDeviceInput *micDeviceInput = …
AVCaptureMovieFileOutput *movieFileOutput = …
if ([captureSession canAddInput:cameraDeviceInput]) {
    [captureSession addInput:cameraDeviceInput];
}
if ([captureSession canAddInput:micDeviceInput]) {
    [captureSession addInput:micDeviceInput];
}
if ([captureSession canAddOutput:movieFileOutput]) {
    [captureSession addOutput:movieFileOutput];
}

[captureSession startRunning];
```

(For simplicity, dispatch queue-related code has been omitted from the above snippet. Because all calls to a capture session are blocking, it’s recommended to dispatch them to a background serial queue.)

（为了简单起见，调度队列（dispatch queue）的相关代码已经从上面那段代码中省略了。所有对 capture session 的调用都是阻塞的，因此建议将它们分配到后台串行队列中。）

A capture session can be further configured with a `sessionPreset`, which indicates the quality level of the output. There are 11 different presets:

capture session 有个 `sessionPreset` 属性可以设置，用来指定输出质量等级。这里有 11 种不同的预设模式：

```objc
NSString *const  AVCaptureSessionPresetPhoto;
NSString *const  AVCaptureSessionPresetHigh;
NSString *const  AVCaptureSessionPresetMedium;
NSString *const  AVCaptureSessionPresetLow;
NSString *const  AVCaptureSessionPreset352x288;
NSString *const  AVCaptureSessionPreset640x480;
NSString *const  AVCaptureSessionPreset1280x720;
NSString *const  AVCaptureSessionPreset1920x1080;
NSString *const  AVCaptureSessionPresetiFrame960x540;
NSString *const  AVCaptureSessionPresetiFrame1280x720;
NSString *const  AVCaptureSessionPresetInputPriority;
```
The first one is for high-resolution photo output.
The next nine are very similar to the `UIImagePickerControllerQualityType` options we saw for the `videoQuality` setting of `UIImagePickerController`, with the exception that there are a few additional presets available for a capture session.
The last one (`AVCaptureSessionPresetInputPriority`) indicates that the capture session does not control the audio and video output settings. Instead, the `activeFormat` of the connected capture device dictates the quality level at the outputs of the capture session. In the next section, we will look at devices and device formats in more detail.

第一个代表高像素图片输出。
接下来的九个和 `UIImagePickerControllerQualityType` 选项非常相似，这个我们之前在设置 `UIImagePickerController` 的  `videoQuality` 看到过，不同的是，这里有一些额外可用于 capture session 的预设。
最后一个（`AVCaptureSessionPresetInputPriority`）代表 capture session 不能控制音频与视频输出设置。而在已连接的捕获设备中，它的 `activeFormat` 反而控制 capture session 的输出质量等级。在下一节，我们将会看到更多关于设备和设备格式的细节。


### Inputs
### 输入

The inputs for an `AVCaptureSession` are one or more `AVCaptureDevice` objects connected to the capture session through an `AVCaptureDeviceInput`.

`AVCaptureSession` 输入其实就是一个或多个的 `AVCaptureDevice` 对象，这些对象通过 `AVCaptureDeviceInput` 连接上 capture session。

We can use `[AVCaptureDevice devices]` to find the available capture devices. For an iPhone 6, they are:

我们可以使用 `[AVCaptureDevice devices]` 来寻找可用的捕获设备。以 iPhone 6 为例：

```
(
    “<AVCaptureFigVideoDevice: 0x136514db0 [Back Camera][com.apple.avfoundation.avcapturedevice.built-in_video:0]>”,
    “<AVCaptureFigVideoDevice: 0x13660be80 [Front Camera][com.apple.avfoundation.avcapturedevice.built-in_video:1]>”,
    “<AVCaptureFigAudioDevice: 0x174265e80 [iPhone Microphone][com.apple.avfoundation.avcapturedevice.built-in_audio:0]>”
)
```

#### Video Input
#### 视频输入

To configure video input, create an `AVCaptureDeviceInput` object with the desired camera device and add it to the capture session:

配置相机输入，需要实例化一个 `AVCaptureDeviceInput` 对象，参数是你期望的相机设备，然后把它添加到 capture session：

```objc
AVCaptureSession *captureSession = …
AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
NSError *error;
AVCaptureDeviceInput *cameraDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice: error:&error];
if ([captureSession canAddInput:input]) {
    [captureSession addInput:cameraDeviceInput];
}
```

If any of the capture session presets discussed in the previous section are sufficient, that’s all you need to do. If they aren’t, because, for instance, you want to capture at high frame rates, you will need to configure a specific device format. A video capture device has a number of device formats, each with specific properties and capabilities. Below are a few examples (out of a total of 22 available formats) from the back-facing camera of an iPhone 6:

上面提到的 capture session 预设列表是足够你用的了。如果不够，比如你想要高帧速率，你将需要配置具体的设备格式。一个视频捕获设备有一些设备格式，每个都带有特定的属性和功能。下面这些是一些例子（一共有 22 种可用格式），设备是 iPhone6 的后置摄像头：

| Format | Resolution | FPS     | HRSI      | FOV    | VIS | Max Zoom  | Upscales | AF | ISO        | SS                | HDR |
|--------|------------|---------|-----------|--------|-----|----------|----------|----|------------|-------------------|-----|
| 420v   | 1280x720   | 5 - 240 | 1280x720  | 54.626 | YES |49.12 | 1.09     | 1  | 29.0 - 928 | 0.000003-0.200000 | NO  |
| 420f   | 1280x720   | 5 - 240 | 1280x720  | 54.626 | YES |49.12 | 1.09     | 1  | 29.0 - 928 | 0.000003-0.200000 | NO  |
| 420v   | 1920x1080  | 2 - 30  | 3264x1836 | 58.040 | YES | 95.62 | 1.55     | 2  | 29.0 - 464 | 0.000013-0.500000 | YES |
| 420f   | 1920x1080  | 2 - 30  | 3264x1836 | 58.040 | YES | 95.62 | 1.55     | 2  | 29.0 - 464 | 0.000013-0.500000 | YES |
| 420v   | 1920x1080  | 2 - 60  | 3264x1836 | 58.040 | YES | 95.62 | 1.55     | 2  | 29.0 - 464 | 0.000008-0.500000 | YES |
| 420f   | 1920x1080  | 2 - 60  | 3264x1836 | 58.040 | YES | 95.62 | 1.55     | 2  | 29.0 - 464 | 0.000008-0.500000 | YES |

- Format = pixel format 像素格式
- FPS = the supported frame rate range 支持帧数范围
- HRSI = high-res still image dimensions 高像素静态图片尺寸
- FOV = field of view  视角
- VIS = the format supports video stabilization 支持视频防抖？
- Max Zoom = the max video zoom factor 最大放大比例
- Upscales = the zoom factor at which digital upscaling is engaged 数字转化采用的放大比（不知道是不是这么翻，参考 http://en.wikipedia.org/wiki/Video_scaler和http://m.pcgames.com.cn/x/206/2065887.html）
- AF = autofocus system (1 = contrast detect, 2 = phase detect) 自动对焦系统（1 是反差对焦，2 是相位对焦）
- ISO = the supported ISO range 支持感光度范围
- SS = the supported exposure duration range 支持曝光时间范围
- HDR = supports video HDR 支持高动态范围图像

From the above formats, you can see that for recording 240 frames per second, we would need the first or the second format, depending on the desired pixel format, and that 240 frames per second isn’t available if we want to capture at a resolution of 1920x1080.

看到上面的那些格式，你会发现录制 240 帧每秒的视频，可根据想要的像素格式使用第一个或第二个格式，并且捕获 1920x1080 的分辨率视频是不支持 240 帧每秒。

To configure a specific device format, you first call `lockForConfiguration:` to acquire exclusive access to the device’s configuration properties. Then you simply set the capture format on the capture device using `setActiveFormat:`. This will also automatically set the preset of your capture session to `AVCaptureSessionPresetInputPriority`.

配置一个具体设备格式，你首先需要调用 `lockForConfiguration:` 获取设备的配置属性的独占访问权限。接着你使用 `setActiveFormat:` 简单设置设备的捕获格式。这将会自动把 capture session 的预设设置为 `AVCaptureSessionPresetInputPriority`。

Once you set the desired device format, you can configure specific settings on the capture device within the constraints of the device format.

一旦你设置了预想的设备格式，你可以给你的捕获设备设定一些约束参数，用于配置。

Focus, exposure, and white balance for video capture are managed in the same way as for image capture described in [“Camera Capture on iOS”](http://objccn.io/issue-21/camera-capture-on-ios.html) from Issue #21. Aside from those, there are some video-specific configuration options.

视频捕获的对焦，曝光和白平衡的设置，与图像捕获一样，具体可参考第 21 期[“iOS 上的相机捕捉”](http://objccn.io/issue-21-3/)。除了那些，这里还有一些视频特有的配置选项。

You set the **frame rate** using the capture device’s `activeVideoMinFrameDuration` and `activeVideoMaxFrameDuration` properties, where the frame duration is the inverse of the frame rate. To set the frame rate, first make sure the desired frame rate is supported by the device format, and then lock the capture device for configuration. To ensure a constant frame rate, set the minimum and maximum frame duration to the same value:

你可以用捕获设备的 `activeVideoMinFrameDuration` 和 `activeVideoMaxFrameDuration` 属性设置**帧速率**，一帧的时长（FrameDuration）是帧速率的倒数。设置帧速率之前，要先确认是否是设备格式支持的范围，然后锁住捕获设备，配置。为了确保帧速率恒定，将最小与最大的帧时长设置成一样的值：

```objc
NSError *error;
CMTime frameDuration = CMTimeMake(1, 60);
NSArray *supportedFrameRateRanges = [device.activeFormat videoSupportedFrameRateRanges];
BOOL frameRateSupported = NO;
for (AVFrameRateRange *range in supportedFrameRateRanges) {
    if (CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) &&
        CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)) {
        frameRateSupported = YES;
    }
}

if (frameRateSupported && [device lockForConfiguration:&error]) {
    [device setActiveVideoMaxFrameDuration:frameDuration];
    [device setActiveVideoMinFrameDuration:frameDuration];
    [device unlockForConfiguration];
}
```

**Video stabilization** was first introduced on iOS 6 and the iPhone 4S. With the iPhone 6, a second, more aggressive and fluid stabilization mode — called cinematic video stabilization — was added. This also changed the video stabilization API (which so far hasn’t been reflected in the class references; check the header files instead). Stabilization is not configured on the capture device, but on the `AVCaptureConnection`. As not all stabilization modes are supported by all device formats, the availability of a specific stabilization mode needs to be checked before it is applied:

**视频稳定模式（视频防抖？）** 第一次被提及是在 iOS6 和 iPhone 4S 发布。到了 iPhone 6，增加了更具侵略性和流畅的稳定模式，被称为影像稳定功能（cinematic video stabilization）。相关的 API 也有所改动（目前为止并没有从相关类反映出来，不过可以查看头文件）。稳定？模式是不能在捕获设备上配置的，而是在 `AVCaptureConnection`。由于不是所有的设备格式都支持全部的稳定？模式，在实际应用中应事先确认具体的稳定？模式是否支持：

```objc
AVCaptureDevice *device = ...;
AVCaptureConnection *connection = ...;

AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeCinematic;
if ([device.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
    [connection setPreferredVideoStabilizationMode:stabilizationMode];
}
```

Another new feature introduced with the iPhone 6 is **video HDR** (High Dynamic Range), which is “streaming high-dynamic-range video as opposed to the more traditional method of fusing a bracket of still images with differing EV values into a single high dynamic range photo.”[^1] It is built right into the sensor. There are two ways to configure video HDR: by directly enabling or disabling it through the capture device’s `videoHDREnabled` property, or by leaving it up to the system by using the `automaticallyAdjustsVideoHDREnabled` property.

iPhone 6的另一个新特性就是**视频 HDR**（高动态范围图像），它是“高动态范围的视频流，在单个高动态范围图像应用不同的曝光值，不同于传统方法中多张静态图片的组合”。该特性已经被编译到传感器。这里有两种方法配置视频 HDR：直接将 capture device 的 `videoHDREnabled` 设置为启用或禁用，或者使用 `automaticallyAdjustsVideoHDREnabled` 属性留给系统处理。

[^1]: [Technical Note: New AV Foundation Camera Features for the iPhone 6 and iPhone 6 Plus](https://developer.apple.com/library/ios/technotes/tn2409/_index.html#//apple_ref/doc/uid/DTS40015038-CH1-OPTICAL_IMAGE_STABILIZATION)

[^1]: [技术名词：iPhone 6 和 iPhone Plus 的新 AV Foundation 相机特性](https://developer.apple.com/library/ios/technotes/tn2409/_index.html#//apple_ref/doc/uid/DTS40015038-CH1-OPTICAL_IMAGE_STABILIZATION)

#### Audio Input
#### 音频输入

The list of capture devices presented earlier only contained one audio device, which seems a bit strange given that an iPhone 6 has three microphones. The microphones are probably treated as one device because they are sometimes used together to optimize performance. For example, when recording video on an iPhone 5 or newer, the front and back microphones will be used together to provide directional noise reduction.[^2]

之前展示的捕获设备列表里面只有一个音频设备，你可能觉得奇怪，毕竟 iPhone 6 有 3 个麦克风。然而因为有时会放在一起使用，便于优化性能，因此可能被当做一个设备来使用。例如在 iPhone 5 及以上的手机录制视频，会同时使用前置和后置麦克风，用于定向降噪。

In most cases, the default microphone configurations will be the desired option. The back microphone will automatically be used with the rear-facing camera (with noise reduction using the front microphone), and the front microphone with the front-facing camera.

大多数情况下，设置成默认的麦克风配置即可。后置麦克风会自动搭配后置摄像头使用（前置麦克风则用于降噪），前置麦克风和前置摄像头也是一样。

But it is possible to access and configure individual microphones, for example, to allow the user to record live commentary through the front-facing microphone while capturing a scene with the rear-facing camera. It is done through `AVAudioSession`.
To be able to reroute the audio, the audio session first needs to be set to a category that supports this. Then we need to iterate through the audio session’s input ports and through the port’s data sources to find the microphone we want:

然而想要访问和配置单独的麦克风也是可行的。例如，当用户正在使用后置摄像头捕获场景的时候，使用前置摄像头录制实况报道也应是允许的。这就要依赖于 `AVAudioSession`。
为了要变更要访问的音频，audio session 首先需要设置 category。然后我们需要遍历 audio session 的输入端口和端口数据来源，从而找到我们想要的麦克风：

```objc
// Configure the audio session
// 配置 audio session
AVAudioSession *audioSession = [AVAudioSession sharedInstance];
[audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
[audioSession setActive:YES error:nil];

// Find the desired input port
// 寻找期望的输入端口
NSArray* inputs = [audioSession availableInputs];
AVAudioSessionPortDescription *builtInMic = nil;
for (AVAudioSessionPortDescription* port in inputs) {
    if ([port.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
        builtInMic = port;
        break;
    }
}

// Find the desired microphone
// 寻找期望的麦克风
for (AVAudioSessionDataSourceDescription* source in builtInMic.dataSources) {
    if ([source.orientation isEqual:AVAudioSessionOrientationFront]) {
        [builtInMic setPreferredDataSource:source error:nil];
        [audioSession setPreferredInput:builtInMic error:&error];
        break;
    }
}
```

In addition to setting up a non-default microphone configuration, you can also use the `AVAudioSession` to configure other audio settings, like the audio gain and sample rate.

为了设定非默认的麦克风配置，你也可以使用 `AVAudioSession` 来配置其他音频设置，比如音频增益和采样率。

[^2]: [Technical Q&A: AVAudioSession - Microphone Selection](https://developer.apple.com/library/ios/qa/qa1799/_index.html)

#### Permissions
#### 访问权限

One thing to keep in mind when accessing cameras and microphones is that you will need the user’s permission. iOS will do this once automatically when you create your first `AVCaptureDeviceInput` for audio or video, but it’s cleaner to do it yourself. You can then use the same code to alert users when the required permissions have not been granted. Trying to record video and audio when the user hasn’t given permission will result in black frames and silence.

有件事你需要记住，访问相机和麦克风需要先获得用户授权。当你给视频或音频创建第一个 `AVCaptureDeviceInput` 对象时，iOS 会自动弹出一次对话框，请求用户授权，但你最好还是自己实现下(it’s cleaner to do it yourself)。接着当还没有被授权的时候，你可以使用相同的代码用于提示用户。当用户未获得权限而尝试录制视频或音频时，那么得到是将是黑色画面和无声。

### Outputs
### 输出

With the inputs configured, we now focus our attention on the outputs of the capture session.
输入配置完了，现在把我们的注意力转向 capture session 的输出。

#### `AVCaptureMovieFileOutput`

The easiest option to write video to file is through an `AVCaptureMovieFileOutput` object. Adding it as an output to a capture session will let you write audio and video to a QuickTime file with a minimum amount of configuration:

将视频写入文件，最简单的选择就是使用 `AVCaptureMovieFileOutput` 对象。把它作为输出添加到 capture session 中，就可以将视频和音频写入 QuickTime 文件，只需很少的配置。

```objc
AVCaptureMovieFileOutput *movieFileOutput = [AVCaptureMovieFileOutput new];
if([captureSession canAddOutput:movieFileOutput]){
    [captureSession addOutput:movieFileOutput];
}

// Start recording
// 开始输出
NSURL *outputURL = …
[movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
```

A recording delegate is required to receive callbacks when actual recording starts and stops. When recording is stopped, the output usually still has some data to write to file and will call the delegate when it’s done.

当录制开始或停止，录制代理必须接收回调。当录制停止，输出通常还在写入数据，等它完成之后会调用代理。

An `AVCaptureMovieFileOutput` object has a few other configuration options, such as stopping recording after a certain duration, when a certain file size is reached, or when the device is crossing a minimum disk space threshold. If you need more than that, e.g. for custom audio and video compression settings, or because you want to process the audio or video samples in some way before writing them to file, you will need something a little more elaborate.

`AVCaptureMovieFileOutput` 有一些其他的配置选项，比如在某段时间后停止录制，这个时间点可以是达到了指定文件的大小，或者设备越过了最小硬盘空间阀值？。如果你还需要更多设置，比如自定义视频音频的压缩率，或者你想要在写入文件之前，处理视频音频的样本，那么你需要一些更复杂的操作。

#### `AVCaptureDataOutput` and `AVAssetWriter`
#### `AVCaptureDataOutput` 和 `AVAssetWriter`

To have more control over the video and audio output from our capture session, you can use an `AVCaptureVideoDataOutput` object and an`AVCaptureAudioDataOutput` object instead of the `AVCaptureMovieFileOutput` discussed in the previous section.

如果你想要对影音输出有更多的操作，你可以使用 `AVCaptureVideoDataOutput` 和 `AVCaptureAudioDataOutput` 而不是我们上节讨论的 `AVCaptureMovieFileOutput`。

These outputs will capture video and audio sample buffers respectively, and vend them to their delegates. The delegate can either apply some processing to the sample buffer (e.g. add a filter to the video) or pass them on unchanged. The sample buffers can then be written to file using an `AVAssetWriter` object:

这些输出将会各自捕获视频和音频的样本缓存，接着发送到他们的代理。代理要么对样本缓存进行处理（比如给视频加滤镜），要么保持原样传送。使用 `AVAssetWriter` 对象可以将样本缓存写入文件。

<img src="/images/issue-23/AVAssetWriter.svg" alt="Using an AVAssetWriter" width="620px" height="507px">

You configure an asset writer by defining an output URL and file format and adding one or more inputs to receive sample buffers. Because the writer inputs will be receiving data from the capture session’s outputs in real time, we also need to set the `expectsMediaInRealTime` attribute to YES:

构建一个 asset writer 需要一个输出 URL 和文件格式，并添加一个或多个输入来接收样本缓存。我们还需要将输入的 `expectsMediaInRealTime` 属性设置为 YES，因为它们需要从 capture session 实时获得数据。

```objc
NSURL *url = …;
AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:nil];
AVAssetWriterInput *videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:nil];
videoInput.expectsMediaDataInRealTime = YES;
AVAssetWriterInput *audioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:nil];
audioInput.expectsMediaDataInRealTime = YES;
if ([assetWriter canAddInput:videoInput]) {
    [assetWriter addInput:videoInput];
}
if ([assetWriter canAddInput:audioInput]) {
    [assetWriter addInput:audioInput];
}
```

(As with the capture session, it is recommended to dispatch asset writer calls to a background serial queue.)

（这里推荐将 asset writer 派送到后台串行队列中调用。）

In the code sample above, we passed in `nil` for the output settings of the asset writer inputs. This means that the appended samples will not be re-encoded. If we do want to re-encode the samples, we need to provide a dictionary with specific output settings. Keys for audio output settings are defined [here](https://developer.apple.com/library/prerelease/ios/documentation/AVFoundation/Reference/AVFoundationAudioSettings_Constants/index.html), and keys for video output settings are defined [here](https://developer.apple.com/library/prerelease/ios/documentation/AVFoundation/Reference/AVFoundation_Constants/index.html#//apple_ref/doc/constant_group/Video_Settings).

在上面的示例代码中，我们将 asset writer 的 outputSettings 设置为 nil。这就意味着增加样本不会再被重新编码。如果你真想要增加样本，那么需要提供一个包含具体输出参数的字典。关于音频输出设置的键值被定义在[这里](https://developer.apple.com/library/prerelease/ios/documentation/AVFoundation/Reference/AVFoundationAudioSettings_Constants/index.html), 关于视频输出设置的键值定义在[这里](https://developer.apple.com/library/prerelease/ios/documentation/AVFoundation/Reference/AVFoundation_Constants/index.html#//apple_ref/doc/constant_group/Video_Settings)。

To make things a bit easier, both the `AVCaptureVideoDataOutput` class and the `AVCaptureAudioDataOutput` class have methods called `recommendedVideoSettingsForAssetWriterWithOutputFileType:` and `recommendedAudioSettingsForAssetWriterWithOutputFileType:`, respectively, that produce a fully populated dictionary of keys and values that are compatible with an asset writer. An easy way to define your own output settings is to start with this fully populated dictionary and adjust the properties you want to override. For example, increase the video bitrate to improve the quality of the video.

为了更简单点，`AVCaptureVideoDataOutput` 和 `AVCaptureAudioDataOutput` 都带有 `recommendedVideoSettingsForAssetWriterWithOutputFileType:` 和 `recommendedAudioSettingsForAssetWriterWithOutputFileType:` 方法，可以生成带有多个键值对的字典，跟 asset writer 是兼容的。所以你可以简单地用这个字典定义你自己的输出设置，调整你想要重写的属性。比如，增加视频比特率来提高视频质量。

As an alternative, you can also use the `AVOutputSettingsAssistant` class to configure output settings dictionaries, but in my experience, using the above methods is preferable; the output settings they provide are more realistic for things like video bitrates. Additionally, the output assistant appears to have some other shortcomings, e.g. it doesn’t change the video bitrate when you change the expected video frame rate.

或者，你也可以使用 `AVOutputSettingsAssistant` 来配置输出设置的字典，但是从我的经验来看，使用上面的方法会更好，它们会提供更实用的输出设置，比如视频比特率。另外，`AVOutputSettingsAssistant` 似乎存在一些缺点，例如，当你改变视频的帧速率，比特率并不会改变。

#### Live Preview
#### 实时预览图

When using `AVFoundation` for video capture, we will have to provide a custom user interface.
A key component of any camera interface is the live preview. This is most easily implemented through an `AVCaptureVideoPreviewLayer` object added as a sublayer to the camera view:

当使用 `AVFoundation` 用于图像捕获时，我们必须提供一套自定义的用户界面。其中一个关键的相机交互组件是实时预览图。这是最容易实现的，把 `AVCaptureVideoPreviewLayer` 对象作为一个 sublayer 加到相机图层即可：

```objc
AVCaptureSession *captureSession = ...;
AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
UIView *cameraView = ...;
previewLayer.frame = cameraView.bounds;
[cameraView.layer addSublayer:previewLayer];
```

If you need more control, e.g. to apply filters to the live preview, you will instead need to add an `AVCaptureVideoDataOutput` object to the capture session and display the frames onscreen using OpenGL, as discussed in [“Camera Capture on iOS”](http://objccn.io/issue-21/camera-capture-on-ios.html) from Issue #21.

如果你想要更进一步操作，比如，在实时预览图加滤镜，你需要将 `AVCaptureVideoDataOutput` 对象加到 capture session，并且使用 OpenGL 展示画面，具体可查看该文[“iOS 上的相机捕捉”](http://objccn.io/issue-21-3/)

## Summary
## 总结

There are a number of different ways to configure a pipeline for video capture on iOS — from the straightforward `UIImagePickerController`, to the more elaborate combination of  `AVCaptureSession` and `AVAssetWriter`. The correct option for your project will depend on your requirements, such as the desired video quality and compression, or the camera controls you want to expose to your app’s users.

有许多不同的方法可以给 iOS 上的视频捕获配置管道，从最直接的 `UIImagePickerController` ，到精心结合的 `AVCaptureSession` 与 `AVAssetWriter` 。如何抉择取决于你的项目要求，比如期望的视频质量和压缩率，或者是你想要暴露给用户的相机控件。
