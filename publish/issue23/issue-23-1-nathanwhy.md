随着每一代 iPhone 处理能力和相机硬件配置的提高，使用它来捕获视频也变得更加有意思。它们小巧，轻便，低调，而且与专业摄像机之间的差距已经变得非常小，小到在某些情况下，iPhone 可以真正替代它们。

这篇文章讨论了关于如何配置视频捕获管线 (pipeline) 和最大限度地利用硬件性能的一些不同选择。
这里有个使用了不同管线的样例 app，可以在 [GitHub](https://github.com/objcio/VideoCaptureDemo) 查看。

## `UIImagePickerController`

目前，将视频捕获集成到你的应用中的最简单的方法是使用 `UIImagePickerController`。这是一个封装了完整视频捕获管线和相机 UI 的 view controller。

在实例化相机之前，首先要检查设备是否支持相机录制：

```objc
if ([UIImagePickerController
       isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    NSArray *availableMediaTypes = [UIImagePickerController
      availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    if ([availableMediaTypes containsObject:(NSString *)kUTTypeMovie]) {
        // 支持视频录制
    }
}
```

然后创建一个 `UIImagePickerController` 对象，设置好代理便于进一步处理录制好的视频 (比如存到相册) 以及对于用户关闭相机作出响应：

```objc
UIImagePickerController *camera = [UIImagePickerController new];
camera.sourceType = UIImagePickerControllerSourceTypeCamera;
camera.mediaTypes = @[(NSString *)kUTTypeMovie];
camera.delegate = self;
```

这是你实现一个功能完善的摄像机所需要写的所有代码。

### 相机配置

`UIImagePickerController` 提供了额外的配置选项。

通过设置 `cameraDevice` 属性可以选择一个特定的相机。这是一个 `UIImagePickerControllerCameraDevice` 枚举，默认情况下是 `UIImagePickerControllerCameraDeviceRear`，你也可以把它设置为 `UIImagePickerControllerCameraDeviceFront`。每次都应事先确认你想要设置的相机是可用的：

```objc
UIImagePickerController *camera = …
if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
    [camera setCameraDevice:UIImagePickerControllerCameraDeviceFront];
}
```

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

前三种为相对预设 (low, medium, high)。这些预设的编码配置会因设备不同而不同。如果选择 high，那么你选定的相机会提供给你该设备所能支持的最高画质。后面三种是特定分辨率的预设 (640x480 VGA, 960x540 iFrame, 和 1280x720 iFrame)。

### 自定义 UI

就像上面提到的，`UIImagePickerController` 自带一套相机 UI，可以直接使用。然而，你也可以自定义相机的控件，通过隐藏默认控件，然后创建带有控件的自定义视图，并覆盖在相机预览图层上面：

```objc
UIView *cameraOverlay = …
picker.showsCameraControls = NO;
picker.cameraOverlayView = cameraOverlay;
```

然后你需要将你覆盖层上的控件关联上 `UIImagePickerController` 的控制方法 (比如，`startVideoCapture` 和 `stopVideoCapture`)。

## AVFoundation

如果你想要更多关于处理捕获视频的方法，而这些方法是 `UIImagePickerController` 所不能提供的，那么你需要使用 AVFoundation。

AVFoundation 中关于视频捕获的主要的类是 `AVCaptureSession`。它负责调配影音输入与输出之间的数据流：

<img src="/images/issues/issue-23/AVCaptureSession.svg" alt="AVCaptureSession setup" width="620px" height="376px">

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

(为了简单起见，调度队列 (dispatch queue) 的相关代码已经从上面那段代码中省略了。所有对 capture session 的调用都是阻塞的，因此建议将它们分配到后台串行队列中。)

capture session 可以通过一个 `sessionPreset` 来进一步配置，这可以用来指定输出质量的等级。有 11 种不同的预设模式：

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

第一个代表高像素图片输出。
接下来的九个和之前我们在设置 `UIImagePickerController` 的  `videoQuality` 时看到过的 `UIImagePickerControllerQualityType` 选项非常相似，不同的是，这里有一些额外可用于 capture session 的预设。
最后一个 (`AVCaptureSessionPresetInputPriority`) 代表 capture session 不去控制音频与视频输出设置。而是通过已连接的捕获设备的 `activeFormat` 来反过来控制 capture session 的输出质量等级。在下一节，我们将会看到更多关于设备和设备格式的细节。

### 输入

`AVCaptureSession` 的输入其实就是一个或多个的 `AVCaptureDevice` 对象，这些对象通过 `AVCaptureDeviceInput` 连接上 capture session。

我们可以使用 `[AVCaptureDevice devices]` 来寻找可用的捕获设备。以 iPhone 6 为例：

```
(
    “<AVCaptureFigVideoDevice: 0x136514db0 [Back Camera][com.apple.avfoundation.avcapturedevice.built-in_video:0]>”,
    “<AVCaptureFigVideoDevice: 0x13660be80 [Front Camera][com.apple.avfoundation.avcapturedevice.built-in_video:1]>”,
    “<AVCaptureFigAudioDevice: 0x174265e80 [iPhone Microphone][com.apple.avfoundation.avcapturedevice.built-in_audio:0]>”
)
```

#### 视频输入

配置相机输入，需要实例化一个 `AVCaptureDeviceInput` 对象，参数是你期望的相机设备，然后把它添加到 capture session：

```objc
AVCaptureSession *captureSession = …
AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
NSError *error;
AVCaptureDeviceInput *cameraDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:cameraDevice error:&error];
if ([captureSession canAddInput:input]) {
    [captureSession addInput:cameraDeviceInput];
}
```

如果上面提到的 capture session 预设列表里能满足你的需求，那你就不需要做更多的事情了。如果不够，比如你想要高的帧率，你将需要配置具体的设备格式。一个视频捕获设备有许多设备格式，每个都带有特定的属性和功能。下面是对于 iPhone6 的后置摄像头的一些例子 (一共有 22 种可用格式)：

<table><thead>
<tr>
<th>格式</th><th>分辨率</th><th>FPS</th><th>HRSI</th><th>FOV</th><th>VIS</th><th>最大放大比例</th><th>Upscales</th><th>AF</th><th>ISO</th><th>SS</th><th>HDR</th></tr>
</thead><tbody>
<tr>
<td>420v</td><td>1280x720</td><td>5 - 240</td><td>1280x720</td><td>54.626</td><td>YES</td><td>49.12</td><td>1.09</td><td>1</td><td>29.0 - 928</td><td>0.000003-0.200000</td><td>NO</td>
</tr>
<tr><td>420f</td><td>1280x720</td><td>5 - 240</td><td>1280x720</td><td>54.626</td><td>YES</td><td>49.12</td><td>1.09</td><td>1</td><td>29.0 - 928</td><td>0.000003-0.200000</td><td>NO</td>
</tr>
<tr><td>420v</td><td>1920x1080</td><td>2 - 30</td><td>3264x1836</td><td>58.040</td><td>YES</td><td>95.62</td><td>1.55</td><td>2</td><td>29.0 - 464</td><td>0.000013-0.500000</td><td>YES</td>
</tr>
<tr><td>420f</td><td>1920x1080</td><td>2 - 30</td><td>3264x1836</td><td>58.040</td><td>YES</td><td>95.62</td><td>1.55</td><td>2</td><td>29.0 - 464</td><td>0.000013-0.500000</td><td>YES</td>
</tr>
<tr><td>420v</td><td>1920x1080</td><td>2 - 60</td><td>3264x1836</td><td>58.040</td><td>YES</td><td>95.62</td><td>1.55</td><td>2</td><td>29.0 - 464</td><td>0.000008-0.500000</td><td>YES</td>
</tr>
<tr><td>420f</td><td>1920x1080</td><td>2 - 60</td><td>3264x1836</td><td>58.040</td><td>YES</td><td>95.62</td><td>1.55</td><td>2</td><td>29.0 - 464</td><td>0.000008-0.500000</td><td>YES</td>
</tr>
</tbody></table>

- 格式 = 像素格式
- FPS = 支持帧数范围
- HRSI = 高像素静态图片尺寸
- FOV = 视角
- VIS = 该格式支持视频防抖
- Upscales = 加入数字 upscaling 时的放大比例
- AF = 自动对焦系统（1 是反差对焦，2 是相位对焦）
- ISO = 支持感光度范围
- SS = 支持曝光时间范围
- HDR = 支持高动态范围图像

通过上面的那些格式，你会发现如果要录制 240 帧每秒的视频的话，可以根据想要的像素格式选用第一个或第二个格式。另外若是要捕获 1920x1080 的分辨率的视频的话，是不支持 240 帧每秒的。

配置一个具体设备格式，你首先需要调用 `lockForConfiguration:` 来获取设备的配置属性的独占访问权限。接着你简单地使用 `setActiveFormat:` 来设置设备的捕获格式。这将会自动把 capture session 的预设设置为 `AVCaptureSessionPresetInputPriority`。

一旦你设置了预想的设备格式，你就可以在这种设备格式的约束参数范围内进行进一步的配置了。

对于视频捕获的对焦，曝光和白平衡的设置，与图像捕获时一样，具体可参考第 21 期[“iOS 上的相机捕捉”](http://objccn.io/issue-21-3/)。除了那些，这里还有一些视频特有的配置选项。


你可以用捕获设备的 `activeVideoMinFrameDuration` 和 `activeVideoMaxFrameDuration` 属性设置**帧速率**，一帧的时长是帧速率的倒数。设置帧速率之前，要先确认它是否在设备格式所支持的范围内，然后锁住捕获设备来进行配置。为了确保帧速率恒定，可以将最小与最大的帧时长设置成一样的值：

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

**视频防抖** 是在 iOS 6 和 iPhone 4S 发布时引入的功能。到了 iPhone 6，增加了更强劲和流畅的防抖模式，被称为影院级的视频防抖动。相关的 API 也有所改动 (目前为止并没有在文档中反映出来，不过可以查看头文件）。防抖并不是在捕获设备上配置的，而是在 `AVCaptureConnection` 上设置。由于不是所有的设备格式都支持全部的防抖模式，所以在实际应用中应事先确认具体的防抖模式是否支持：

```objc
AVCaptureDevice *device = ...;
AVCaptureConnection *connection = ...;

AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeCinematic;
if ([device.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
    [connection setPreferredVideoStabilizationMode:stabilizationMode];
}
```

iPhone 6 的另一个新特性就是**视频 HDR** (高动态范围图像)，它是“高动态范围的视频流，与传统的将不同曝光度的静态图像合成成一张高动态范围图像的方法完全不同”，它是内建在传感器中的。有两种方法可以配置视频 HDR：直接将 capture device 的 `videoHDREnabled` 设置为启用或禁用，或者使用 `automaticallyAdjustsVideoHDREnabled` 属性来留给系统处理。

> [技术参考：iPhone 6 和 iPhone Plus 的新 AV Foundation 相机特性](https://developer.apple.com/library/ios/technotes/tn2409/_index.html#//apple_ref/doc/uid/DTS40015038-CH1-OPTICAL_IMAGE_STABILIZATION)

#### 音频输入

之前展示的捕获设备列表里面只有一个音频设备，你可能觉得奇怪，毕竟 iPhone 6 有 3 个麦克风。然而因为有时会放在一起使用，便于优化性能，因此可能被当做一个设备来使用。例如在 iPhone 5 及以上的手机录制视频时，会同时使用前置和后置麦克风，用于定向降噪。

> [Technical Q&A: AVAudioSession - Microphone Selection](https://developer.apple.com/library/ios/qa/qa1799/_index.html)

大多数情况下，设置成默认的麦克风配置即可。后置麦克风会自动搭配后置摄像头使用 (前置麦克风则用于降噪)，前置麦克风和前置摄像头也是一样。

然而想要访问和配置单独的麦克风也是可行的。例如，当用户正在使用后置摄像头捕获场景的时候，使用前置麦克风来录制解说也应是可能的。这就要依赖于 `AVAudioSession`。
为了变更要访问的音频，audio session 首先需要设置为支持这样做的类别。然后我们需要遍历 audio session 的输入端口和端口数据来源，来找到我们想要的麦克风：

```objc
// 配置 audio session
AVAudioSession *audioSession = [AVAudioSession sharedInstance];
[audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
[audioSession setActive:YES error:nil];

// 寻找期望的输入端口
NSArray* inputs = [audioSession availableInputs];
AVAudioSessionPortDescription *builtInMic = nil;
for (AVAudioSessionPortDescription* port in inputs) {
    if ([port.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
        builtInMic = port;
        break;
    }
}

// 寻找期望的麦克风
for (AVAudioSessionDataSourceDescription* source in builtInMic.dataSources) {
    if ([source.orientation isEqual:AVAudioSessionOrientationFront]) {
        [builtInMic setPreferredDataSource:source error:nil];
        [audioSession setPreferredInput:builtInMic error:&error];
        break;
    }
}
```

除了设置非默认的麦克风配置，你也可以使用 `AVAudioSession` 来配置其他音频设置，比如音频增益和采样率等。

#### 访问权限

有件事你需要记住，访问相机和麦克风需要先获得用户授权。当你给视频或音频创建第一个 `AVCaptureDeviceInput` 对象时，iOS 会自动弹出一次对话框，请求用户授权，但你最好还是自己实现下。之后你就可以在还没有被授权的时候，使用相同的代码来提示用户进行授权。当用户未授权时，对于录制视频或音频的尝试，得到的将是黑色画面和无声。

### 输出

输入配置完了，现在把我们的注意力转向 capture session 的输出。

#### `AVCaptureMovieFileOutput`

将视频写入文件，最简单的选择就是使用 `AVCaptureMovieFileOutput` 对象。把它作为输出添加到 capture session 中，就可以将视频和音频写入 QuickTime 文件，这只需很少的配置。

```objc
AVCaptureMovieFileOutput *movieFileOutput = [AVCaptureMovieFileOutput new];
if([captureSession canAddOutput:movieFileOutput]){
    [captureSession addOutput:movieFileOutput];
}

// 开始录制
NSURL *outputURL = …
[movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
```

当实际的录制开始或停止时，想要接收回调的话就必须要一个录制代理。当录制停止时，输出通常还在写入数据，等它完成之后会调用代理方法。

`AVCaptureMovieFileOutput` 有一些其他的配置选项，比如在某段时间后，在达到某个指定的文件尺寸时，或者当设备的最小磁盘剩余空间达到某个阈值时停止录制。如果你还需要更多设置，比如自定义视频音频的压缩率，或者你想要在写入文件之前，处理视频音频的样本，那么你需要一些更复杂的操作。

#### `AVCaptureDataOutput` 和 `AVAssetWriter`

如果你想要对影音输出有更多的操作，你可以使用 `AVCaptureVideoDataOutput` 和 `AVCaptureAudioDataOutput` 而不是我们上节讨论的 `AVCaptureMovieFileOutput`。

这些输出将会各自捕获视频和音频的样本缓存，接着发送到它们的代理。代理要么对采样缓冲进行处理 (比如给视频加滤镜)，要么保持原样传送。使用 `AVAssetWriter` 对象可以将样本缓存写入文件：

<img src="/images/issues/issue-23/AVAssetWriter.svg" alt="Using an AVAssetWriter" width="620px" height="507px">

配置一个 asset writer 需要定义一个输出 URL 和文件格式，并添加一个或多个输入来接收采样的缓冲。我们还需要将输入的 `expectsMediaInRealTime` 属性设置为 YES，因为它们需要从 capture session 实时获得数据。

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

(这里推荐将 asset writer 派送到后台串行队列中调用。)

在上面的示例代码中，我们将 asset writer 的 outputSettings 设置为 `nil`。这就意味着附加上来的样本不会再被重新编码。如果你确实想要重新编码这些样本，那么需要提供一个包含具体输出参数的字典。关于音频输出设置的键值被定义在[这里](https://developer.apple.com/library/prerelease/ios/documentation/AVFoundation/Reference/AVFoundationAudioSettings_Constants/index.html), 关于视频输出设置的键值定义在[这里](https://developer.apple.com/library/prerelease/ios/documentation/AVFoundation/Reference/AVFoundation_Constants/index.html#//apple_ref/doc/constant_group/Video_Settings)。

为了更简单点，`AVCaptureVideoDataOutput` 和 `AVCaptureAudioDataOutput` 分别带有 `recommendedVideoSettingsForAssetWriterWithOutputFileType:` 和 `recommendedAudioSettingsForAssetWriterWithOutputFileType:` 方法，可以生成与 asset writer 兼容的带有全部键值对的字典。所以你可以通过在这个字典里调整你想要重写的属性，来简单地定义你自己的输出设置。比如，增加视频比特率来提高视频质量等。

或者，你也可以使用 `AVOutputSettingsAssistant` 来配置输出设置的字典，但是从我的经验来看，使用上面的方法会更好，它们会提供更实用的输出设置，比如视频比特率。另外，`AVOutputSettingsAssistant` 似乎存在一些缺点，例如，当你改变希望的视频的帧速率时，视频的比特率并不会改变。

#### 实时预览

当使用 `AVFoundation` 来做图像捕获时，我们必须提供一套自定义的用户界面。其中一个关键的相机交互组件是实时预览图。最简单的实现方式是通过把 `AVCaptureVideoPreviewLayer` 对象作为一个 sublayer 加到相机图层上去：

```objc
AVCaptureSession *captureSession = ...;
AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
UIView *cameraView = ...;
previewLayer.frame = cameraView.bounds;
[cameraView.layer addSublayer:previewLayer];
```

如果你想要更进一步操作，比如，在实时预览图加滤镜，你需要将 `AVCaptureVideoDataOutput` 对象加到 capture session，并且使用 OpenGL 展示画面，具体可查看该文[“iOS 上的相机捕捉”](http://objccn.io/issue-21-3/)

## 总结

有许多不同的方法可以给 iOS 上的视频捕获配置管线，从最直接的 `UIImagePickerController`，到精密配合的 `AVCaptureSession` 与 `AVAssetWriter` 。如何抉择取决于你的项目要求，比如期望的视频质量和压缩率，或者是你想要展示给用户的相机控件。

---

 

原文 [Capturing Video on iOS](http://www.objc.io/issue-23/capturing-video.html)
