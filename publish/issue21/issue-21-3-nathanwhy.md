第一台 iPhone 问世就装有相机。在第一个 SKDs 版本中，在 app 里面整合相机的唯一方法就是使用 `UIImagePickerController`，但到了 iOS 4，发布了更灵活的 AVFoundation 框架。

在这篇文章里，我们将会看到如何使用 AVFoundation 捕捉图像，如何操控相机，以及它在 iOS 8 的新特性。

## 概述

### AVFoundation vs. `UIImagePickerController`

`UIImagePickerController` 提供了一种非常简单的拍照方法。它支持所有的基本功能，比如切换到前置摄像头，开关闪光灯，点击屏幕区域实现对焦和曝光，以及在 iOS 8 中像系统照相机应用一样调整曝光。

然而，当有直接访问相机的需求时，也可以选择 AVFoundation 框架。它提供了完全的操作权，例如，以编程方式更改硬件参数，或者操纵实时预览图。

### AVFoundation 相关类

AVFoundation 框架基于以下几个类实现图像捕捉 ，通过这些类可以访问来自相机设备的原始数据并控制它的组件。

- `AVCaptureDevice` 是关于相机硬件的接口。它被用于控制硬件特性，诸如镜头的位置、曝光、闪光灯等。
- `AVCaptureDeviceInput` 提供来自设备的数据。
- `AVCaptureOutput` 是一个抽象类，描述 capture session 的结果。以下是三种关于静态图片捕捉的具体子类：
  - `AVCaptureStillImageOutput` 用于捕捉静态图片
  - `AVCaptureMetadataOutput` 启用检测人脸和二维码
  - `AVCaptureVideoOutput` 为实时预览图提供原始帧
- `AVCaptureSession` 管理输入与输出之间的数据流，以及在出现问题时生成运行时错误。
- `AVCaptureVideoPreviewLayer` 是 `CALayer` 的子类，可被用于自动显示相机产生的实时图像。它还有几个工具性质的方法，可将 layer 上的坐标转化到设备上。它看起来像输出，但其实不是。另外，它**拥有** session (outputs 被 session **所拥有**)。

## 设置

让我们看看如何捕获图像。首先我们需要一个 `AVCaptureSession` 对象:

```
let session = AVCaptureSession()
```

现在我们需要一个相机设备输入。在大多数 iPhone 和 iPad 中，我们可以选择后置摄像头或前置摄像头 -- 又称自拍相机 (selfie camera) -- 之一。那么我们必须先遍历所有能提供视频数据的设备 (麦克风也属于 `AVCaptureDevice`，因此略过不谈)，并检查 `position` 属性：

```
let availableCameraDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
for device in availableCameraDevices as [AVCaptureDevice] {
  if device.position == .Back {
    backCameraDevice = device
  }
  else if device.position == .Front {
    frontCameraDevice = device
  }
}
```

然后，一旦我们发现合适的相机设备，我们就能获得相关的 `AVCaptureDeviceInput` 对象。我们会将它设置为 session 的输入：

```
var error:NSError?
let possibleCameraInput: AnyObject? = AVCaptureDeviceInput.deviceInputWithDevice(backCameraDevice, error: &error)
if let backCameraInput = possibleCameraInput as? AVCaptureDeviceInput {
  if self.session.canAddInput(backCameraInput) {
    self.session.addInput(backCameraInput)
  }
}
```

注意当 app 首次运行时，第一次调用 `AVCaptureDeviceInput.deviceInputWithDevice()` 会触发系统提示，向用户请求访问相机。这在 iOS 7 的时候只有部分国家会有，到了 iOS 8 拓展到了所有地区。除非得到用户同意，否则相机的输入会一直是一个黑色画面的数据流。

对于处理相机的权限，更合适的方法是先确认当前的授权状态。要是在授权还没有确定的情况下 (也就是说用户还没有看过弹出的授权对话框时)，我们应该明确地发起请求。

```
let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
switch authorizationStatus {
case .NotDetermined:
  // 许可对话没有出现，发起授权许可
  AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo,
    completionHandler: { (granted:Bool) -> Void in
    if granted {
      // 继续
    }
    else {
      // 用户拒绝，无法继续
    }
  })
case .Authorized:
  // 继续
case .Denied, .Restricted:
  // 用户明确地拒绝授权，或者相机设备无法访问
}
```

如果能继续的话，我们会有两种方式来显示来自相机的图像流。最简单的就是，生成一个带有 `AVCaptureVideoPreviewLayer` 的 view，并使用 capture session 作为初始化参数。

```
previewLayer = AVCaptureVideoPreviewLayer.layerWithSession(session) as AVCaptureVideoPreviewLayer
previewLayer.frame = view.bounds
view.layer.addSublayer(previewLayer)
```

`AVCaptureVideoPreviewLayer` 会自动地显示来自相机的输出。当我们需要将实时预览图上的点击转换到设备的坐标系统中，比如点击某区域实现对焦时，这种做法会很容易办到。之后我们会看到具体细节。

第二种方法是从输出数据流捕捉单一的图像帧，并使用 OpenGL 手动地把它们显示在 view 上。这有点复杂，但是如果我们想要对实时预览图进行操作或使用滤镜的话，就是必要的了。

为获得数据流，我们需要创建一个 `AVCaptureVideoDataOutput`，这样一来，当相机在运行时，我们通过代理方法 `captureOutput(_:didOutputSampleBuffer:fromConnection:)` 就能获得所有图像帧 (除非我们处理太慢而导致掉帧)，然后将它们绘制在一个 `GLKView` 中。不需要对 OpenGL 框架有什么深刻的理解，我们只需要这样就能创建一个 `GLKView`：

```
glContext = EAGLContext(API: .OpenGLES2)
glView = GLKView(frame: viewFrame, context: glContext)
ciContext = CIContext(EAGLContext: glContext)
```

现在轮到 `AVCaptureVideoOutput`：

```
videoOutput = AVCaptureVideoDataOutput()
videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL))
if session.canAddOutput(self.videoOutput) {
  session.addOutput(self.videoOutput)
}
```

以及代理方法：

```
func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
  let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
  let image = CIImage(CVPixelBuffer: pixelBuffer)
  if glContext != EAGLContext.currentContext() {
    EAGLContext.setCurrentContext(glContext)
  }
  glView.bindDrawable()
  ciContext.drawImage(image, inRect:image.extent(), fromRect: image.extent())
  glView.display()
}
```

一个警告：这些来自相机的样本旋转了 90 度，这是由于相机传感器的朝向所导致的。`AVCaptureVideoPreviewLayer` 会自动处理这种情况，但在这个例子，我们需要对 `GLKView` 进行旋转。

马上就要搞定了。最后一个组件 -- `AVCaptureStillImageOutput` -- 实际上是最重要的，因为它允许我们捕捉静态图片。只需要创建一个实例，并添加到 session 里去：

```
stillCameraOutput = AVCaptureStillImageOutput()
if self.session.canAddOutput(self.stillCameraOutput) {
  self.session.addOutput(self.stillCameraOutput)
}
```

### 配置

现在我们有了所有必需的对象，应该为我们的需求寻找最合适的配置。这里又有两种方法可以实现。最简单且最推荐是使用 session preset： 

```
session.sessionPreset = AVCaptureSessionPresetPhoto
```

`AVCaptureSessionPresetPhoto` 会为照片捕捉选择最合适的配置，比如它可以允许我们使用最高的感光度 (ISO) 和曝光时间，基于[相位检测 (phase detection)](https://en.wikipedia.org/wiki/Autofocus#Phase_detection)的自动对焦, 以及输出全分辨率的 JPEG 格式压缩的静态图片。

然而，如果你需要更多的操控，可以使用 `AVCaptureDeviceFormat` 这个类，它描述了一些设备使用的参数，比如静态图片分辨率，视频预览分辨率，自动对焦类型，感光度和曝光时间限制等。每个设备支持的格式都列在 `AVCaptureDevice.formats` 属性中，并可以赋值给 `AVCaptureDevice` 的 `activeFormat` (注意你并不能修改格式)。

## 操作相机

iPhone 和 iPad 中内置的相机或多或少跟其他相机有相同的操作，不同的是，一些参数如对焦、曝光时间 (在单反相机上的模拟[快门](http://objccn.io/issue-21-1/)的速度)，感光度是可以调节，但是镜头光圈是固定不可调整的。到了 iOS 8，我们已经可以对所有这些可变参数进行手动调整了。

我们之后会看到细节，不过首先，该启动相机了：

```
sessionQueue = dispatch_queue_create("com.example.camera.capture_session", DISPATCH_QUEUE_SERIAL)
dispatch_async(sessionQueue) { () -> Void in
  self.session.startRunning()
}
```

在 session 和相机设备中完成的所有操作和配置都是利用 block 调用的。因此，建议将这些操作分配到后台的串行队列中。此外，相机设备在改变某些参数前必须先锁定，直到改变结束才能解锁，例如：


```
var error:NSError?
if currentDevice.lockForConfiguration(&error) {
  // 锁定成功，继续配置
  // currentDevice.unlockForConfiguration()
}
else {
  // 出错，相机可能已经被锁
}
```

### 对焦

在 iOS 相机上，对焦是通过移动镜片改变其到传感器之间的距离实现的。

自动对焦是通过相位检测和反差检测实现的。然而，反差检测只适用于低分辨率和高 FPS 视频捕捉 (慢镜头)。

> <p><span class="secondary radius label">编者注</span> 关于相位对焦和反差对焦，可以参看[这篇文章](http://ask.zealer.com/post/149)。

`AVCaptureFocusMode` 是个枚举，描述了可用的对焦模式：

- `Locked` 指镜片处于固定位置
- `AutoFocus` 指一开始相机会先自动对焦一次，然后便处于 `Locked` 模式。
- `ContinuousAutoFocus` 指当场景改变，相机会自动重新对焦到画面的中心点。

设置想要的对焦模式必须在锁定之后实施：

```
let focusMode:AVCaptureFocusMode = ...
if currentCameraDevice.isFocusModeSupported(focusMode) {
  ... // 锁定以进行配置
  currentCameraDevice.focusMode = focusMode
  ... // 解锁
  }
}
```

通常情况下，`AutoFocus` 模式会试图让屏幕中心成为最清晰的区域，但是也可以通过变换 “感兴趣的点 (point of interest)” 来设定另一个区域。这个点是一个 CGPoint，它的值从左上角 `{0，0}` 到右下角 `{1，1}`，`{0.5，0.5}` 为画面的中心点。通常可以用视频预览图上的点击手势识别来改变这个点，想要将 view 上的坐标转化到设备上的规范坐标，我们可以使用 `AVVideoCaptureVideoPreviewLayer.captureDevicePointOfInterestForPoint()`：

```
var pointInPreview = focusTapGR.locationInView(focusTapGR.view)
var pointInCamera = previewLayer.captureDevicePointOfInterestForPoint(pointInPreview)
...// 锁定，配置

// 设置感兴趣的点
currentCameraDevice.focusPointOfInterest = pointInCamera

// 在设置的点上切换成自动对焦
currentCameraDevice.focusMode = .AutoFocus

...// 解锁
```

在 iOS 8 中，有个新选项可以移动镜片的位置，从较近物体的 `0.0` 到较远物体的 `1.0` (不是指无限远)。

```
... // 锁定，配置
var lensPosition:Float = ... // 0.0 到 1.0的float
currentCameraDevice.setFocusModeLockedWithLensPosition(lensPosition) {
  (timestamp:CMTime) -> Void in
  // timestamp 对应于应用了镜片位置的第一张图像缓存区
}
... // 解锁
```

这意味着对焦可以使用 `UISlider` 设置，这有点类似于旋转单反上的对焦环。当用这种相机手动对焦时，通常有一个可见的辅助标识指向清晰的区域。AVFoundation 里面没有内置这种机制，但是比如可以通过显示 ["对焦峰值 (focus peaking)"](https://en.wikipedia.org/wiki/Focus_peaking)(一种将已对焦区域高亮显示的方式) 这样的手段来补救。我们在这里不会讨论细节，不过对焦峰值可以很容易地实现，通过使用阈值边缘 (threshold edge) 滤镜 (用自定义 `CIFilter` 或 [`GPUImageThresholdEdgeDetectionFilter`](https://github.com/BradLarson/GPUImage/blob/master/framework/Source/GPUImageThresholdEdgeDetectionFilter.h))，并调用 `AVCaptureAudioDataOutputSampleBufferDelegate`  下的 `captureOutput(_:didOutputSampleBuffer:fromConnection:)` 方法将它覆盖到实时预览图上。

### 曝光

在 iOS 设备上，镜头上的光圈是固定的 (在 iPhone 5s 以及其之后的光圈值是 f/2.2，之前的是 f/2.4)，因此只有改变曝光时间和传感器的灵敏度才能对图片的亮度进行调整，从而达到合适的效果。至于对焦，我们可以选择连续自动曝光，在“感兴趣的点”一次性自动曝光，或者手动曝光。除了指定“感兴趣的点”，我们可以通过设置曝光补偿 (compensation) 修改自动曝光，也就是曝光档位的目标偏移。目标偏移在[曝光档数](http://objccn.io/issue-21-1/)里有讲到，它的范围在 `minExposureTargetBias` 与 `maxExposureTargetBias` 之间，0为默认值 (即没有“补偿”)。

```
var exposureBias:Float = ... // 在 minExposureTargetBias 和 maxExposureTargetBias 之间的值
... // 锁定，配置
currentDevice.setExposureTargetBias(exposureBias) { (time:CMTime) -> Void in
}
... // 解锁
```

使用手动曝光，我们可以设置 ISO 和曝光时间，两者的值都必须在设备当前格式所指定的范围内。

```
var activeFormat = currentDevice.activeFormat
var duration:CTime = ... //在activeFormat.minExposureDuration 和 activeFormat.maxExposureDuration 之间的值，或用 AVCaptureExposureDurationCurrent 表示不变
var iso:Float = ... // 在 activeFormat.minISO 和 activeFormat.maxISO 之间的值，或用 AVCaptureISOCurrent 表示不变
... // 锁定，配置
currentDevice.setExposureModeCustomWithDuration(duration, ISO: iso) { (time:CMTime) -> Void in
}
... // 解锁
```

如何知道照片曝光是否正确呢？我们可以通过 KVO，观察 `AVCaptureDevice` 的 `exposureTargetOffset` 属性，确认是否在 0 附近。

### 白平衡

数码相机为了适应不同类型的光照条件[需要补偿](http://objccn.io/issue-21-1/#WhiteBalance)。这意味着在冷光线的条件下，传感器应该增强红色部分，而在暖光线下增强蓝色部分。在 iPhone 相机中，设备会自动决定合适的补光，但有时也会被场景的颜色所混淆失效。幸运地是，iOS 8 可以里手动控制白平衡。

自动模式工作方式和对焦、曝光的方式一样，但是没有“感兴趣的点”，整张图像都会被纳入考虑范围。在手动模式，我们可以通过[开尔文](https://zh.wikipedia.org/wiki/开尔文)所表示的[温度](https://zh.wikipedia.org/wiki/色温)来调节色温和色彩。典型的色温值在 2000-3000K (类似蜡烛或灯泡的暖光源) 到 8000K (纯净的蓝色天空) 之间。色彩范围从最小的 -150 (偏绿) 到 150 (偏品红)。

温度和色彩可以被用于计算来自相机传感器的恰当的 RGB 值，因此仅当它们做了基于设备的校正后才能被设置。

以下是全部过程：

```
var incandescentLightCompensation = 3_000
var tint = 0 // 不调节
let temperatureAndTintValues = AVCaptureWhiteBalanceTemperatureAndTintValues(temperature: incandescentLightCompensation, tint: tint)
var deviceGains = currentCameraDevice.deviceWhiteBalanceGainsForTemperatureAndTintValues(temperatureAndTintValues)
... // 锁定，配置
currentCameraDevice.setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains(deviceGains) {
        (timestamp:CMTime) -> Void in
    }
  }
... // 解锁
```

### 实时人脸检测

`AVCaptureMetadataOutput` 可以用于检测人脸和二维码这两种物体。很明显，[没什么人用二维码](http://picturesofpeoplescanningqrcodes.tumblr.com) (编者注: 因为在欧美现在二维码不是很流行，这里是一个恶搞。链接的这个 tumblr 博客的主题是 “当人们在扫二维码时的图片”，但是 2012 年开博至今没有任何一张图片，暗讽二维码根本没人在用，这和以中日韩为代表的亚洲用户群体的使用习惯完全相悖)，因此我们就来看看如何实现人脸检测。我们只需通过 `AVCaptureMetadataOutput` 的代理方法捕获的元对象：

```
var metadataOutput = AVCaptureMetadataOutput()
metadataOutput.setMetadataObjectsDelegate(self, queue: self.sessionQueue)
if session.canAddOutput(metadataOutput) {
  session.addOutput(metadataOutput)
}
metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
```

```
func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
    for metadataObject in metadataObjects as [AVMetadataObject] {
      if metadataObject.type == AVMetadataObjectTypeFace {
        var transformedMetadataObject = previewLayer.transformedMetadataObjectForMetadataObject(metadataObject)
      }
    }
```

更多关于人脸检测与识别的内容请查看 [Engin 的文章](http://objccn.io/issue-21-9)。

### 捕捉静态图片

最后，我们要做的是捕捉高分辨率的图像，于是我们调用 `captureStillImageAsynchronouslyFromConnection(connection, completionHandler)`。在数据时被读取时，completion handler 将会在某个未指定的线程上被调用。

如果设置使用 JPEG 编码作为静态图片输出，不管是通过 session `.Photo` 预设设定的，还是通过设备输出设置设定的，`sampleBuffer` 都会返回包含图像的元数据。如果在 `AVCaptureMetadataOutput` 中是可用的话，这会包含 EXIF 数据，或是被识别的人脸等：

```
dispatch_async(sessionQueue) { () -> Void in

  let connection = self.stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo)

  // 将视频的旋转与设备同步
  connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!

  self.stillCameraOutput.captureStillImageAsynchronouslyFromConnection(connection) {
    (imageDataSampleBuffer, error) -> Void in

    if error == nil {

      // 如果使用 session .Photo 预设，或者在设备输出设置中明确进行了设置
      // 我们就能获得已经压缩为JPEG的数据

      let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)

      // 样本缓冲区也包含元数据，我们甚至可以按需修改它
      
      let metadata:NSDictionary = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)).takeUnretainedValue()

      if let image = UIImage(data: imageData) {
        // 保存图片，或者做些其他想做的事情
        ...
      }
    }
    else {
      NSLog("error while capturing still image: \(error)")
    }
  }
}
```

当图片被捕捉的时候，有视觉上的反馈是很好的体验。想要知道何时开始以及何时结束的话，可以使用 KVO 来观察 `AVCaptureStillImageOutput` 的 `isCapturingStillImage` 属性。

#### 分级捕捉

在 iOS 8 还有一个有趣的特性叫“[分级捕捉](http://en.wikipedia.org/wiki/Bracketing)”，可以在不同的曝光设置下拍摄几张照片。这在复杂的光线下拍照显得非常有用，例如，通过设定 -1、0、1 三个不同的曝光档数，然后用 HDR 算法合并成一张。

以下是代码实现：

```
dispatch_async(sessionQueue) { () -> Void in
  let connection = self.stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo)
  connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!

  var settings = [-1.0, 0.0, 1.0].map {
    (bias:Float) -> AVCaptureAutoExposureBracketedStillImageSettings in

    AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettingsWithExposureTargetBias(bias)
  }

  var counter = settings.count

  self.stillCameraOutput.captureStillImageBracketAsynchronouslyFromConnection(connection, withSettingsArray: settings) {
    (sampleBuffer, settings, error) -> Void in

    ...
    // 保存 sampleBuffer(s)

    // 当计数为0，捕捉完成
    counter--

  }
}
```

这很像是单个图像捕捉，但是不同的是 completion handler 被调用的次数和设置的数组的元素个数一样多。

### 总结

我们已经详细看到如何在 iPhone 应用里面实现拍照的基础功能（呃…不光是 iPhone，[用 iPad 拍照](http://ipadtography.tumblr.com/)其实也是不错的）。你也可以查看这个[例子](https://github.com/objcio/issue-21-camera-controls-demo)。最后说下，iOS 8 允许更精确的捕捉，特别是对于高级用户，这使得 iPhone 与专业相机之间的差距缩小，至少在手动控制上。不过，不是任何人都喜欢在日常拍照时使用复杂的手动操作界面，因此请合理地使用这些特性。

---

 

原文 [Camera Capture on iOS](http://www.objc.io/issue-21/camera-capture-on-ios.html)


