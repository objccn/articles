## 图像捕捉

The iPhone has shipped with a camera since its first model. In the first SDKs, the only way to integrate the camera within an app was by using `UIImagePickerController`, but iOS 4 introduced the AVFoundation framework, which allowed more flexibility.

第一台iPhone问世就装有相机。在第一个SKDs版本中，在app里面整合相机的唯一方法就是使用 `UIImagePickerController`，但到了iOS4，发布了更灵活的AVFoundation框架。

In this article, we'll see how image capture with AVFoundation works, how to control the camera, and the new features recently introduced in iOS 8.

在这篇文章，我们将会看到如何使用 AVFoundation 捕捉图像，如何控制相机，以及它在iOS8的新特性。

## Overview
## 概述

### AVFoundation vs. `UIImagePickerController`

### AVFoundation vs. `UIImagePickerController`

`UIImagePickerController` provides a very simple way to take a picture. It supports all the basic features, such as switching to the front-facing camera, toggling the flash, tapping on an area to lock focus and exposure, and, on iOS8, adjusting the exposure just as in the system camera app.

`UIImagePickerController`提供了一种非常简单的拍照方法。它支持所有基本的功能，比如切换到前置摄像头，开关闪光灯，点击屏幕区域实现对焦和曝光，以及在iOS8中像系统照相机应用一样调整曝光。

However, when direct access to the camera is necessary, the AVFoundation framework allows full control, for example, for changing the hardware parameters programmatically, or manipulating the live preview.

然而，当直接访问相机变得必要，便可选择AVFoundation框架。它支持全面的操作，例如，以编程方式更改硬件参数，或者操纵实时预览图。

### AVFoundation's Building Blocks
### AVFoundation's 编译代码块

An image capture implemented with the AVFoundation framework is based on a few classes. These classes give access to the raw data coming from the camera device and can control its components.

图像捕捉通过AVFoundation框架实现，并基于几个类。通过这些类可以访问来自相机设备的原始数据并控制它的组件。

- `AVCaptureDevice` is the interface to the hardware camera. It is used to control the hardware features such as the position of the lens, the exposure, and the flash.
- `AVCaptureDeviceInput` provides the data coming from the device.
- `AVCaptureOutput` is an abstract class describing the result of a capture session. There are three concrete subclasses of interest to still-image capture:
  - `AVCaptureStillImageOutput` is used to capture a still image.
  - `AVCaptureMetadataOutput` enables detection of faces and QR codes.
  - `AVCaptureVideoOutput` provides the raw frames for a live preview.
- `AVCaptureSession` manages the data flow between the inputs and the outputs, and generates runtime errors in case something goes wrong.
- The `AVCaptureVideoPreviewLayer` is a subclass of `CALayer`, and can be used to automatically display the live feed generated from the camera. It also has some utility methods for converting points from layer coordinates to those of the device. It looks like an output, but it's not. Additionally, it *owns* a session (the outputs are *owned by* a session).

- `AVCaptureDevice` 是关于相机硬件的接口。它被用于控制硬件特性，诸如镜头的位置、曝光、闪光灯等。
- `AVCaptureDeviceInput` 提供来自设备的数据。
- `AVCaptureOutput` 是一个抽象类，描述捕捉 session 的结果。以下是三种关于静态图片捕捉的具体子类：
  - `AVCaptureStillImageOutput` 用于捕捉静态图片
  - `AVCaptureMetadataOutput` 用于识别脸部和二维码
  - `AVCaptureVideoOutput` 为实施预览图提供原始帧
- `AVCaptureSession` 管理输入与输出之间的数据流，以及生成运行时错误以防出现问题。
- `AVCaptureVideoPreviewLayer` 是 `CALayer` 的子类，可被用于自动显示相机产生的实时图像。它还有几个实用的功能，可将layer上的坐标转化到那些设备上。看起来像输出，但其实不是。另外，它*拥有* session（outputs 被 session *所拥有*）。

## Setup
## 建立

Let's start building the capture. First we need an `AVCaptureSession` object:

让我们看看如何捕获图像。首先我们需要一个 `AVCaptureSession` 对象:

```
let session = AVCaptureSession()
```

Now we need a camera device input. On most iPhones and iPads, we can choose between the back camera and the front camera — aka the selfie camera（自拍相机）. So first we have to iterate over all the devices that can provide video data (the microphone is also an `AVCaptureDevice`, so we'll skip it) and check for the `position` property:

现在我们需要一个相机设备输入。在大多数iPhone和iPad中，我们可以选择后置摄像头或前置摄像头--又称自拍相机（selfie camera）。那么我们必须先遍历所有能提供视频数据的 devices（麦克风也属于`AVCaptureDevice`，因此略过不谈），并检查 `position` 属性：

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

Then, once we found the proper camera device, we can get the corresponding `AVCaptureDeviceInput` object. We'll set this as the session's input:

然后，一旦我们发现合适的相机设备，我们就能获得相关的`AVCaptureDeviceInput` 对象。我们将会设置这个作为session的输出：

```
var error:NSError?
let possibleCameraInput: AnyObject? = AVCaptureDeviceInput.deviceInputWithDevice(backCameraDevice, error: &error)
if let backCameraInput = possibleCameraInput as? AVCaptureDeviceInput {
  if self.session.canAddInput(backCameraInput) {
    self.session.addInput(backCameraInput)
  }
}
```

Note that the first time the app is executed, the first call to  `AVCaptureDeviceInput.deviceInputWithDevice()` triggers a system dialog, asking the user to allow usage of the camera. This was introduced in some countries with iOS 7, and was extended to all regions with iOS 8. Until the user accepts the dialog, the camera input will send a stream of black frames.

注意当这个app第一次运行，第一次调用`AVCaptureDeviceInput.deviceInputWithDevice()`会触发系统提示，向用户请求访问相机。这在iOS7的时候只有部分国家会有，到了iOS8才拓展到了所有地区。直到用户同意请求，相机输入才发送一个黑色画面的数据流。

A more appropriate way to handle the camera permissions is to first check the current status of the authorization, and in case it's still not determined, i.e. the user hasn't seen the dialog, to explicitly request it:

确认当前的授权状态是一个更合适的处理相机许可的方法，以防它一直处于不确定状态，也就是说，用户没有看过弹出的授权对话，便不能明确地发起请求。

```
let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
switch authorizationStatus {
case .NotDetermined:
  // permission dialog not yet presented, request authorization
  // 许可对话没有出现，发起授权许可
  AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo,
    completionHandler: { (granted:Bool) -> Void in
    if granted {
      // go ahead
      // 继续
    }
    else {
      // user denied, nothing much to do
      // 用户拒绝，无法继续
    }
  })
case .Authorized:
  // go ahead
  // 继续
case .Denied, .Restricted:
  // the user explicitly denied camera usage or is not allowed to access the camera devices
  // 用户明确地拒绝授权，或者无法访问相机设备
}
```

At this point, we have two ways to display the video stream that comes from the camera. The simplest is to create a view with an `AVCaptureVideoPreviewLayer` and attach it to the capture session:

这时候，我们有两种方式来显示来自相机的图像流。最简单的就是，生成一个带有 `AVCaptureVideoPreviewLayer` 的view，并使用 capture session 作为初始化参数。

```
previewLayer = AVCaptureVideoPreviewLayer.layerWithSession(session) as AVCaptureVideoPreviewLayer
previewLayer.frame = view.bounds
view.layer.addSublayer(previewLayer)
```

The `AVCaptureVideoPreviewLayer` will automatically display the output from the camera. It also comes in handy when we need to translate a tap on the camera preview to the coordinate system of the device, e.g. when tapping on an area to focus. We'll see the details later.

`AVCaptureVideoPreviewLayer` 会自动地显示来自相机的输出。当我们需要将实时预览图上的点击转化到设备的坐标系统，比如点击某区域实现对焦，这种方式变得非常简单。之后我们会看到具体细节。

The second method is to capture the single frames from the output data stream and to manually display them in a view, using OpenGL. This is a bit more complicated, but necessary in case we want to manipulate or filter the live preview.
To get the data stream, we just create an `AVCaptureVideoDataOutput`, so when the camera is running, we get all the frames (except the ones that will be dropped if our processing is too slow) via the delegate method, `captureOutput(_:didOutputSampleBuffer:fromConnection:)`, and draw them in a `GLKView`. Without going too deep into the OpenGL framework, we could setup the `GLKView` like this:

第二个方法是从输出数据流捕捉的单个图像帧，使用OpenGL手动地显示在view上。这个有点复杂但是必要，以防我们想要对实时预览图进行操作或使用滤镜。为获得数据流，我们仅创建了一个 `AVCaptureVideoDataOutput` ，因此当相机在运行，我们通过代理方法`captureOutput(_:didOutputSampleBuffer:fromConnection:)`获得所有图像帧（除了掉帧，如果进程太慢的话），然后将他们绘制在`GLKView`。在没有太理解OpenGL框架情况下，我们可以像这样创建`GLKView`：

```
glContext = EAGLContext(API: .OpenGLES2)
glView = GLKView(frame: viewFrame, context: glContext)
ciContext = CIContext(EAGLContext: glContext)
```

Now the `AVCaptureVideoOutput`:
现在轮到 `AVCaptureVideoOutput`

```
videoOutput = AVCaptureVideoDataOutput()
videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL))
if session.canAddOutput(self.videoOutput) {
  session.addOutput(self.videoOutput)
}
```

And the delegate method:
代理方法：

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

One caveat: the samples sent from the camera are rotated 90 degrees, because that's how the camera sensor is oriented. The `AVCaptureVideoPreviewLayer` handles this automatically, so in this case, we should apply a rotation transform to the `GLKView`.

一个警告：这些来自相机的样本旋转了90度，其原因是相机传感器的朝向所致。`AVCaptureVideoPreviewLayer` 会自动处理这种情况，但在这个例子，我们需要对 `GLKView` 进行旋转。

We're almost done. The last component — the `AVCaptureStillImageOutput` — is actually the most important, as it allows us to capture a still image. This is just a matter of creating an instance and adding it to the session:

我们完成了大部分。最后一个组件-- `AVCaptureStillImageOutput` --实际上是最重要的，因为它允许我们捕捉静态图片。这里创建了一个实例，并添加到session：

```
stillCameraOutput = AVCaptureStillImageOutput()
if self.session.canAddOutput(self.stillCameraOutput) {
  self.session.addOutput(self.stillCameraOutput)
}
```


### Configuration
### 配置（Configuration）

Now that we have all the necessary objects in place, we should find the best configuration for our needs. Again, there are two ways to accomplish this.
The simplest — and the most recommended — is to use a session preset:

现在我们有了所有必需的对象，应该为我们的需求寻找最合适的配置。这里又有两种方法可以实现。最简单且最推荐是使用 session preset： 

```
session.sessionPreset = AVCaptureSessionPresetPhoto
```

The `AVCaptureSessionPresetPhoto` selects the best configuration for the capture of a photo, i.e. it enables the maximum ISO and exposure duration ranges, the [phase detection](https://en.wikipedia.org/wiki/Autofocus#Phase_detection) autofocus, and a full resolution, JPEG-compressed still image output.

`AVCaptureSessionPresetPhoto` 给照片捕捉选择最合适的配置，也就是说，有最高的感光度（ISO）和曝光时间，[阶段检测（phase detection）](https://en.wikipedia.org/wiki/Autofocus#Phase_detection)的自动对焦, 以及JPEG静态压缩图片输出的全面解决方案。

However, if you need more control, the `AVCaptureDeviceFormat` class describes the parameters applicable to the device, such as still image resolution, video preview resolution, the type of autofocus system, ISO, and exposure duration limits. Every device supports a set of formats, listed in the `AVCaptureDevice.formats` property, and the proper format can be set as the  `activeFormat` of the `AVCaptureDevice` (note that you cannot modify a format).

然而，如果你需要更多的操作，这个 `AVCaptureDeviceFormat` 类描述了设备适用的一些参数，比如静态图片解决方案，视频预览解决方案，自动对焦类型，感光度（ISO），和曝光时间限制。每个设备支持的格式都列在`AVCaptureDevice.formats`属性中，然后可以赋值给 `AVCaptureDevice` 的 `activeFormat` (注意你不能修改格式)。

## Controlling the Camera
## 操作相机

The camera built into iPhones and iPads has more or less the same controls as other cameras, with some exceptions: parameters such as focus, exposure duration (the analog of the [shutter speed](/issue-21/how-your-camera-works.html#shutterspeed) on DSLR cameras), and ISO sensitivity can be adjusted, but the lens aperture is fixed. Since iOS 8, we have access to full manual control of all the adjustments.

We'll look at the details later, but first, it's time to start the camera:

iPhone和ipad中内置的相机或多或少跟其他相机有相同的操作，不同的是，一些参数如对焦、曝光时间（在单反相机上模拟[快门](/issue-21/how-your-camera-works.html#shutterspeed)速度），感光度（ISO）是可以调节，但是镜头光圈是固定不可调整。到了在iOS8，我们已经可以对所有这些进行手动操作调整。

我们之后会看到细节，是时候先启动相机：

```
sessionQueue = dispatch_queue_create("com.example.camera.capture\_session", DISPATCH_QUEUE_SERIAL)
dispatch_async(sessionQueue) { () -> Void in
  self.session.startRunning()
}
```

All the actions and configurations done on the session or the camera device are blocking calls. For this reason, it's recommended to dispatch them to a background serial queue. Furthermore, the camera device must be locked before changing any of its parameters, and unlocked afterwards For example:

在session和相机设备中完成的所有操作和配置都是 block 调用。因此，建议分配到后台的串行队列中。此外，相机设备必须在改变任何一个参数前锁定，然后解锁，例如：

```
var error:NSError?
if currentDevice.lockForConfiguration(&error) {
  // locked successfully, go on with configuration
  // 锁定成功，继续配置
  // currentDevice.unlockForConfiguration()
}
else {
  // something went wrong, the device was probably 
 already locked
  // 出错，可能相机已经被锁
}
```


### Focus
### 对焦

Focus on an iOS camera is achieved by moving the lens closer to, or further from, the sensor.

Autofocus is implemented with phase detection or contrast detection. The latter, however, is available only for low-resolution, high-FPS video capture (slow motion).

在iOS相机上，对焦是通过移动镜片到传感器之间的距离实现的。

自动对焦是通过阶段检测和对比检测实现。然而，对比检测只适用于低分辨率和高FPS视频捕捉（缓慢运动）。

The enum `AVCaptureFocusMode` describes the available focus modes:

- `Locked` means the lens is at a fixed position.
- `AutoFocus` means setting this will cause the camera to focus once automatically, and then return back to `Locked`.
- `ContinuousAutoFocus` means the camera will automatically refocus on the center of the frame when the scene changes.

`AVCaptureFocusMode` 是个枚举，描述了可用的对焦模式：

- `Locked` 指镜片处于固定位置
- `AutoFocus` 指一开始相机会先自动对焦一次，然后便处于`Locked`模式。
- `ContinuousAutoFocus` 指当场景改变，相机会自动重新对焦到画面的中心点。

Setting the desired focus mode must be done after acquiring a lock:

设置想要的对焦模式必须在锁定之后实施：

```
let focusMode:AVCaptureFocusMode = ...
if currentCameraDevice.isFocusModeSupported(focusMode) {
  ... // lock for configuration
      // 锁定配置
  currentCameraDevice.focusMode = focusMode
  ... // unlock
      // 解锁
  }
}
```

By default, the `AutoFocus` mode tries to get the center of the screen as the sharpest area, but it is possible to set another area by changing the "point of interest." This is a `CGPoint`, with values ranging from `{ 0.0 , 0.0 }` (top left) to `{ 1.0, 1.0 }` (bottom right), and `{ 0.5, 0.5 }` being the center of the frame.
Usually this can be implemented with a tap gesture recognizer on the video preview, and to help with translating the point from the coordinate of the view to the device's normalized coordinates, we can use  `AVVideoCaptureVideoPreviewLayer.captureDevicePointOfInterestForPoint()`:

通常情况下，`AutoFocus` 模式会试图寻找屏幕中心最清晰，对比明显的区域，但是也可以通过变换“感兴趣的点（point of interest）”来设定另一个区域。这个点是一个 CGPoint，它的值从左上角{0，0}到右下角{1，1}，{0.5，0.5}为画面的中心点。通常这可以用视频预览图上的点击手势识别实现，并协助将view上的坐标转化到设备上规范化的坐标，我们可以使用`AVVideoCaptureVideoPreviewLayer.captureDevicePointOfInterestForPoint()`:

```
var pointInPreview = focusTapGR.locationInView(focusTapGR.view)
var pointInCamera = previewLayer.captureDevicePointOfInterestForPoint(pointInPreview)
... // lock for configuration
    // 锁定配置

// set the new point of interest:
currentCameraDevice.focusPointOfInterest = pointInCamera
// trigger auto-focus on the new point of interest
currentCameraDevice.focusMode = .AutoFocus

... // unlock
    // 解锁
```

New in iOS 8 is the option to move the lens to a position from `0.0`, focusing near objects, to `1.0`, focusing far objects (although that doesn't mean "infinity"):

在iOS8，有个新选项可以移动镜片的位置，从0.0到1.0，越靠近1.0，离物体越远（不是指无限远）。

```
... // lock for configuration
    // 锁住配置
var lensPosition:Float = ... // 0.0 and 1.0的float
currentCameraDevice.setFocusModeLockedWithLensPosition(lensPosition) {
  (timestamp:CMTime) -> Void in
  // timestamp of the first image buffer with the applied lens position
  // 第一张图像缓存区的 timestamp ，应用了镜片位置
}
... // unlock
    // 解锁
```

This means that the focus can be set with a `UISlider`, for example, which would be the equivalent of rotating the focusing ring on a DSLR. When focusing manually with these kinds of cameras, there is usually a visual aid that indicates the sharp areas. There is no such built-in mechanism in AVFoundation, but it could be interesting to display, for instance, a sort of ["focus peaking"](https://en.wikipedia.org/wiki/Focus_peaking). We won't go into details here, but focus peaking could be easily implemented by applying a threshold edge detect filter (with a custom `CIFilter` or [`GPUImageThresholdEdgeDetectionFilter`](https://github.com/BradLarson/GPUImage/blob/master/framework/Source/GPUImageThresholdEdgeDetectionFilter.h)), and overlaying it onto the live preview in the `captureOutput(_:didOutputSampleBuffer:fromConnection:)` method of `AVCaptureAudioDataOutputSampleBufferDelegate` seen above.

这意味对焦可用 `UISlider` 设置，这有点类似于单反上的旋转对焦环。当用这种相机手动对焦时，通常有一个可见的辅助标识指向清晰的区域。AVFoundation里面没有内置这种机制，但是可以有意思地显示，比如 ["focus peaking"](https://en.wikipedia.org/wiki/Focus_peaking)。我们在这里不会讨论细节，不过 focus peaking 可以很容易地实现，通过应用临界值（threshold edge）检测滤镜（用自定义 `CIFilter` 或 [`GPUImageThresholdEdgeDetectionFilter`](https://github.com/BradLarson/GPUImage/blob/master/framework/Source/GPUImageThresholdEdgeDetectionFilter.h))，并通过使用`AVCaptureAudioDataOutputSampleBufferDelegate` 下的`captureOutput(_:didOutputSampleBuffer:fromConnection:)`方法将它覆盖到实时预览图上。

### Exposure
### 曝光


On iOS devices, the aperture of the lens is fixed (at f/2.2 for iPhones after 5s, and at f/2.4 for previous models), so only the exposure duration and the sensor sensibility can be tweaked to accomplish the most appropriate image brightness. As for the focus, we can have continuous auto exposure, one-time auto exposure on the point of interest, or manual exposure. In addition to specifying a point of interest, we can modify the auto exposure by setting a compensation, known as *target bias*. The target bias is expressed in [*f-stops*](/issue-21/how-your-camera-works.html#stops), and its values range between `minExposureTargetBias` and `maxExposureTargetBias`, with 0 being the default (no compensation):

在iOS设备上，镜头上的光圈是固定的（在iPhone 5s以及其之后的光圈值是f/2.2，之前的是f/2.4），因此只有曝光时间和传感器的灵敏度才能对图片的亮度进行微调，从而达到合适的效果。至于对焦，我们可以选择连续自动曝光，手动曝光，或者在“感兴趣的点”一次性自动曝光。除了指定“感兴趣的点”，我们可以通过设置 compensation（曝光补偿）修改自动曝光，也就是 *target bias*。target bias 在[*f-stops*](/issue-21/how-your-camera-works.html#stops)有讲到，它的范围在`minExposureTargetBias` 与 `maxExposureTargetBias`之间，0为默认值（没有补光）。


```
var exposureBias:Float = ... // a value between minExposureTargetBias and maxExposureTargetBias
    // 在 minExposureTargetBias 和 maxExposureTargetBias 之间的值
... // lock for configuration
    // 锁定配置
currentDevice.setExposureTargetBias(exposureBias) { (time:CMTime) -> Void in
}
... // unlock
    // 解锁
```

To use manual exposure, instead we can set the ISO and the duration. Both values must be in the ranges specified in the device's active format:

使用手动曝光，我们可以设置 ISO 和曝光时间，两者的值都必须是设备支持的格式并在指定范围内。

```
var activeFormat = currentDevice.activeFormat
var duration:CTime = ... // a value between activeFormat.minExposureDuration and activeFormat.maxExposureDuration or AVCaptureExposureDurationCurrent for no change
//在activeFormat.minExposureDuration 和 activeFormat.maxExposureDuration 之间的值，或者 AVCaptureExposureDurationCurrent 不变
var iso:Float = ... // a value between activeFormat.minISO and activeFormat.maxISO or AVCaptureISOCurrent for no change
// 在 activeFormat.minISO 和 activeFormat.maxISO 之间的值 或 AVCaptureISOCurrent 不变
... // lock for configuration
    // 锁住配置
currentDevice.setExposureModeCustomWithDuration(duration, ISO: iso) { (time:CMTime) -> Void in
}
... // unlock
    // 解锁
```

How do we know that the picture is correctly exposed? We can observe the `exposureTargetOffset` property of the `AVCaptureDevice` object and check that it's around zero.

我们怎么知道照片曝光是正确的？我们可以通过KVO，观察 `AVCaptureDevice` 的 `exposureTargetOffset` 属性，确认是否在0附近。

### White Balance

Digital cameras [need to compensate](/issue-21/how-your-camera-works.html#whiteisnotwhite) for different types of lighting. This means that the sensor should increase the red component, for example, in case of a cold light, and the blue component in case of a warm light. On an iPhone camera, the proper compensation can be automatically determined by the device, but sometimes, as it happens with any camera, it gets tricked by the colors in the scene. Luckily, iOS 8 made manual controls available for the white balance as well.

数码相机为了适应不同类型的光照条件需要[“补偿”](/issue-21/how-your-camera-works.html#whiteisnotwhite)。这意味着的是传感器应该增强红色组件，比如在冷光线的条件下，而在暖光线下增强蓝色组件。在iPhone相机，设备会自动决定合适的补光，但有时也会被场景的颜色所混淆失效。幸运地是，iOS8可以用白平衡手动控制。

The automatic modes work in the same way as the focus and exposure, but there's no point of interest; the whole image is considered. In manual mode, we can compensate for the temperature and the tint, with the [temperature](https://en.wikipedia.org/wiki/Color_temperature) expressed in [Kelvin](https://en.wikipedia.org/wiki/Kelvin). Typical color temperature values go from around 2000–3000 K (for a warm light source like a candle or light bulb) up to 8000 K (for a clear blue sky). The tint ranges from a minimum of −150 (shift to green) to a maximum of 150 (shift to magenta).

自动模式工作方式和对焦、曝光的方式一样，但是没有“感兴趣的点”，会被认为是整张图像。在手动模式，我们可以用以[Kevin](https://en.wikipedia.org/wiki/Kelvin)命名的[色温](https://en.wikipedia.org/wiki/Color_temperature)来调节温度和色彩。典型的色温值在2000、3000K（类似蜡烛或灯泡的暖光源）到8000K（纯净的蓝色天空）。色彩范围从最小的-150（偏绿）到150（偏品红）。

Temperature and tint will be used to calculate the proper RGB gain of the camera sensor, thus they have to be normalized for the device before they can be set.

温度和色彩可以被用于计算来自相机传感器的RGB，因此他们对于每个设备要规范化才能设置。

This is the whole process:

以下是全部过程：

```
var incandescentLightCompensation = 3_000
var tint = 0 // no shift
let temperatureAndTintValues = AVCaptureWhiteBalanceTemperatureAndTintValues(temperature: incandescentLightCompensation, tint: tint)
var deviceGains = currentCameraDevice.deviceWhiteBalanceGainsForTemperatureAndTintValues(temperatureAndTintValues)
... // lock for configuration
currentCameraDevice.setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains(deviceGains) {
        (timestamp:CMTime) -> Void in
    }
  }
... // unlock
```

### Real-Time Face Detection

The `AVCaptureMetadataOutput` has the ability to detect two types of objects: faces and QR codes. Apparently [no one uses QR codes](http://picturesofpeoplescanningqrcodes.tumblr.com), so let's see how we can detect faces. We just need to catch the metadata objects the `AVCaptureMetadataOutput` is providing to its delegate:

`AVCaptureMetadataOutput` 可以用于脸部识别和二维码识别这两种。显然[没什么人用二维码](http://picturesofpeoplescanningqrcodes.tumblr.com)，因此我们就来看看如何实现脸部识别。我们只需通过 `AVCaptureMetadataOutput` 的代理方法捕获的元对象（metadata objects）：

```swift
var metadataOutput = AVCaptureMetadataOutput()
metadataOutput.setMetadataObjectsDelegate(self, queue: self.sessionQueue)
if session.canAddOutput(metadataOutput) {
  session.addOutput(metadataOutput)
}
metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
```

```swift
func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
    for metadataObject in metadataObjects as [AVMetadataObject] {
      if metadataObject.type == AVMetadataObjectTypeFace {
        var transformedMetadataObject = previewLayer.transformedMetadataObjectForMetadataObject(metadataObject)
      }
    }
```

Check out [Engin’s article in this issue](/issue-21/face-recognition-with-opencv.html) for more on face detection and recognition.

更多关于脸部识别的内容请查看 [Engin的文章](/issue-21/face-recognition-with-opencv.html)。

### Capturing a Still Image
### 捕捉静态图片

Finally, we want to capture the high-resolution image, so we call the `captureStillImageAsynchronouslyFromConnection(connection, completionHandler)` method on the camera device. When the data is read, the completion handler will be called on an unspecified thread.

最后，我们想要捕捉高像素的图像，于是我们调用`captureStillImageAsynchronouslyFromConnection(connection, completionHandler)`。当数据时被读取，completion handler 会被调用在某个不明确的线程。

If the still image output was set up to use the JPEG codec, either via the session `.Photo` preset or via the device's output settings, the `sampleBuffer` returned contains the image's metadata, i.e. EXIF data and also the detected faces — if enabled in the `AVCaptureMetadataOutput`:

如果静态图片输出被设置成使用JPEG编码，要么通过 session `.Photo` 预设，要么通过设备输出设置，`sampleBuffer` 返回值包含图像元数据，也就是EXIF数据，也能识别脸部，如果在`AVCaptureMetadataOutput`下可用的话：


```
dispatch_async(sessionQueue) { () -> Void in

  let connection = self.stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo)

  // update the video orientation to the device one
  connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!

  self.stillCameraOutput.captureStillImageAsynchronouslyFromConnection(connection) {
    (imageDataSampleBuffer, error) -> Void in

    if error == nil {

      // if the session preset .Photo is used, or if explicitly set in the device's outputSettings
      // 如果使用 session preset .Photo，或者在设备输出设置中明确设置
      // we get the data already compressed as JPEG
      // 我们获得已经压缩为JPEG的数据

      let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)

      // the sample buffer also contains the metadata, in case we want to modify it
      // 样本缓冲区也包含元数据，以防我们想修改它
      
      let metadata:NSDictionary = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)).takeUnretainedValue()

      if let image = UIImage(data: imageData) {
        // save the image or do something interesting with it
        // 保存图片，或者做些其他有趣的
        ...
      }
    }
    else {
      NSLog("error while capturing still image: \(error)")
    }
  }
}
```

It's nice to have a sort of visual feedback when the photo is being captured. To know when it starts and when it's finished, we can use KVO with the `isCapturingStillImage` property of the `AVCaptureStillImageOutput`.

当图片被捕捉的时候，有视觉上的反馈是很好的体验。想要知道何时开始，何时结束可以使用KVO，观察`AVCaptureStillImageOutput`的`isCapturingStillImage`的属性。


#### Bracketed Capture
#### 分段捕捉

An interesting feature also introduced in iOS 8 is "bracketed capture," which means taking several photos in succession with different exposure settings. This can be useful when taking a picture in mixed light, for example, by configuring three different exposures with biases at −1, 0, +1, and then merging them with an HDR algorithm.

在iOS8还有一个有趣的特性叫“分段捕捉”，可以在不同的曝光设置下拍摄几张照片。这在复杂的光线下拍照显得非常有用，例如，通过设定-1、0、1，三个不同曝光 bias 参数，然后用HDR算法合并成一张。

Here's how it looks in code:

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
    // save the sampleBuffer(s)
    // 保存 sampleBuffer(s)

    // when the counter reaches 0 the capture is complete
    counter--
    // 当计数为0，捕捉完成

  }
}
```

It looks quite similar to the single image capture, but the completion handler is called as many times as the number of elements in the settings array.

这很像是单个图像捕捉，但是不同的是 completion handler 被调用的次数和设置的数组的元素一样多。

### Conclusion
### 总结

We've seen in detail the basics of how taking a picture in an iPhone app could be implemented (hmm... what about [taking photos with an iPad](http://ipadtography.tumblr.com/)?). You can also check them in action in this [sample project](https://github.com/objcio/issue-21-camera-controls-demo). Finally, iOS 8 is allowing a more accurate capture, especially for power users, thus making the gap between iPhones and dedicated cameras a little bit narrower, at least in terms of manual controls. Anyway, not everybody would like to be using a complicated manual interface for the everyday photo, so use these features responsibly!

我们已经详细看到如何在iPhone应用里面实现拍照的基础功能（恩。。[如何用iPad拍照](http://ipadtography.tumblr.com/)？）。你也可以查看这个[例子](https://github.com/objcio/issue-21-camera-controls-demo)。最后说下，iOS8允许更精确的捕捉，特别是对于高级用户，这使得iPhone与专业相机之间的差距缩小，至少在手动控制上。不过，不是任何人都愿意为日常拍照使用这么复杂的操作界面，因此请负责任地使用这些特性。
