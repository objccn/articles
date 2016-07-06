在 iOS 8 发布时，苹果把[六种全新扩展](https://developer.apple.com/library/prerelease/ios/documentation/General/Conceptual/ExtensibilityPG/index.html#//apple_ref/doc/uid/TP40014214-CH20-SW2)功能介绍给全世界，它们史无前例的提供了访问操作系统的可行性。现在，开发者可以利用照片扩展来为系统相机应用增加功能。

用户使用照片编辑扩展的流程并不简单。从选择编辑的照片开始，需要点击三次才能启动，其中一步骤是非常小一个按钮：

![照片编辑扩展用户流程](/images/issues/issue-21/user_workflow.png)

然而，这类扩展给开发者提供了为用户创造无缝体验，创建一致的方法来管理照片的绝佳的机会。

本文在了解更详细的编辑工作流程之前，将先简单讨论如何创建扩展以扩展的生命周期，我们会通过常见的相关问题和场景来创建照片编辑扩展从而得出结论。

本文的示例项目 **Filtster** 演示了如何创建自己的图片编辑扩展。它诠释使用了数个 Core Image 滤镜完成简单的图像过滤效果。[完整 Filtster 项目代码](https://github.com/objcio/issue-21-photo-extensions-Filtster) 可以在 GitHub 上找到。

## 创建扩展

所有扩展必须包含在一个功能齐全的 iOS 应用程序之内，照片编辑扩展也不例外。这可能意味着你必须做很多令人吃惊的自定义 Core Image 滤镜的才能让它到达用户手中。苹果如何严格审查还有待观察，因为苹果商店内的大多数有图片编辑功能的应用都是在 iOS 8 引入之前就已经存在了的。

为了创建新的图片编辑扩展，需要为已有的 iOS 项目添加新的 target，扩展 target 模板如下：

![图片编辑扩展模板](/images/issues/issue-21/xcode-target-template-photo-extension.png)

模板由三部分组成：

1. **Storyboard** 图片编辑扩展除了系统在顶部提供的 toolbar 包含**取消**以及**完成**按钮之外，界面几乎完全可以自定义。

    ![Cancel/Done 按钮](/images/issues/issue-21/cancel_done.png)

    虽然 storyboard 默认不包含 size classes，系统将允许你选择并激活该功能，虽然没有明显的原因来阻止你使用手动布局，但苹果还是强烈建议使用 Auto Layout 来创建照片编辑扩展。如果你忽略苹果的建议你将不得不面对很多潜在风险。

2. **Info.plist** 设定扩展的类型和可被接受媒体的类型，以及扩展的通用配置。`NSExtension` 键值是一个字典，它包含扩展所需要的配置：

    ![扩展 plist](/images/issues/issue-21/extension_plist.png)
	
    `NSExtensionPointIdentifier` 实体告诉系统这是一个使用 `com.apple.photo-editing` 作为值的照片编辑扩展。唯一特殊的 key 是 `PHSupportedMediaTypes`，它指明可以被操作的媒体类型。在默认情况下，这是一个包含 `Image` 实体的数组，当然你也可添加 `Video` 选项。

3. **View Controller** 遵守 `PHContentEditingController` 协议，其中包含了图片编辑扩展需要的生命周期方法。更多详情见本文下个部分。

值得注意的是不要忘记提供菜单内的扩展的图标：

![扩展图标](/images/issues/issue-21/extension_icon.png)

图标通过宿主 app 的资源目录内的 App Icon 提供。这里文档有些让人迷惑，它暗示你必须在扩展本身里来提供图标。然而，尽管我们可以提供一个这样的图标，但扩展将不会使用选择它。这一点有些争议，因为苹果指定与扩展相关的图标必须与容器应用程序的相同。

## 扩展的生命周期

照片编辑扩展建立于 Photos 框架之上的，这意味着编辑不是破坏性的。当一个照片资源被编辑的时候，原始文件始终没有被修改，编辑的结果将作为副本被保存下来。另外，语义细节包含了如何重新编辑并保存调整后的数据。这个数据的意思是编辑可以基于原始文件重新来过。当你实现图片编辑扩展的时候，你只负责构建你自己的数据对象。

`PHAdjustmentData` 类含有编辑所需参数，以及两个格式化的属性 (`formatIdentifier` 和 `formatVersion`) 用来确定当前编辑扩展针对于之前的编辑过的照片的兼容性。它们两个都是字符串类型，另外 `formatIdentifier` 规定为反向域名解析格式。这两个属性让你灵活的创建一套图像编辑的应用程序以及扩展，每一种都可以用另一种表示。另外 `data` 属性是 `NSData` 类型。可以被用来按你的需要存储扩展操作的细节，以便让你的扩展能继续编辑。

### 开始编辑

当用户使用你的扩展来编辑照片的时候，系统会实例化你的视图控制器并且初始化照片编辑的生命周期。如果照片之前曾经被编辑，它首先会调用 `canHandleAdjustmentData(_:)` 方法，同时为你提供一个 `PHAdjustmentData` 对象。因此，你的扩展是否可以处理之前编辑过的数据就很重要，这将决定框架发送的下一个生命周期的方法是什么。

一旦系统决定提供原始图片还是之前就被渲染编辑过的图片，接下来将会调用 `startContentEditingWithInput(_:, placeholderImage:)`。输入是一个类型为 `PHContentEditingInput` 的对象，其中包含了地理位置，创建时间以及媒体类型等来自于原始资源的元数据，以及你需要编辑的资源细节。除了原始尺寸的输入图片的路径以外，输入对象还包含一个 `displaySizedImage` 表示相同的图片数据，但是根据屏幕尺寸进行了适当缩放。这意味着交互编辑可以在较低分辨率下进行，以此来确保扩展可以保持迅速响应操作并节省能量。

下面是实现方法

```
func startContentEditingWithInput(contentEditingInput: PHContentEditingInput?,
                                  placeholderImage: UIImage) {
  input = contentEditingInput
  filter.inputImage = CIImage(image: input?.displaySizeImage)
  if let adjustmentData = contentEditingInput?.adjustmentData {
    filter.importFilterParameters(adjustmentData.data)
  }

  vignetteIntensitySlider.value = Float(filter.vignetteIntensity)
  ...
}
```

上面的实现中存储了 `contentEditingInput`，因为要完成编辑并从调整后的数据导入滤镜参数的时候我们会需要它。

如果你的 `canHandleAdjustmentData(_:)` 返回 `true`，`startContentEditingWithInput(_:, placeholderImage:)` 将会提供原始图片，然后你的扩展需要根据调整后的数据来重新创建编辑过的图片。如果这是一个耗时操作，那么 `placeholderImage` 将提供一个上次编辑渲染后的临时图片来让你暂时使用。

在这个阶段，用户将通过扩展界面的交互来控制编辑的进程。因为扩展包含一个视图控制器，你可以使用任何 UIKit 来实现它。示例项目使用了 Core Image 的滤镜链来完成编辑，所以界面使用了一个自定义的 `GLKView` 子类来减少 CPU 的负载。

### 取消编辑

在完成编辑时，用户可以选择照片界面提供的**取消**或者**完成**按钮。如果想让用户确定是否取消尚未保存的编辑内容，`shouldShowCancelConfirmation` 属性需要重写并返回 `true`：

![确认取消](/images/issues/issue-21/confirm_cancel.png)

如果需要取消操作，`cancelContentEditing` 方法将被调用来允许你清空所有临时数据。

### 提交修改

一旦用户决定保存编辑操作，并且点击了**完成**按钮，`finishContentEditingWithCompletionHandler(_:)` 将会被调用。在这个时候，原始尺寸图像需要用与当前显示的图片相同设置来编辑，并保存调整后的数据。

在这时，你可以通过在编辑过程开始时提供的 `PHContentEditingInput` 对象内的 `fullSizeImageURL` 来获取原始尺寸的图片。

要完成编辑，我们需要调用提供的回调函数，并提供一个从输入创建的 `PHContentEditingOutput` 对象。这个输出对象还包含了一个 `renderedContentURL` 属性，用来指定你应该把输出的 JPEG 数据存放在哪里：

```
func finishContentEditingWithCompletionHandler(completionHandler: ((PHContentEditingOutput!) -> Void)!) {
  // 在后台队列渲染并提供输出。
  dispatch_async(dispatch_get_global_queue(CLong(DISPATCH_QUEUE_PRIORITY_DEFAULT), 0)) {
    
    // 从编辑输入创建编辑输出。

    let output = PHContentEditingOutput(contentEditingInput: self.input)

    // 提供调整后的数据并且渲染输出到指定位置。   

    let adjustmentData = PHAdjustmentData(formatIdentifier: self.filter.filterIdentifier,
      formatVersion: self.filter.filterVersion, data: self.filter.encodeFilterParameters())
    output.adjustmentData = adjustmentData

    // 写入 JPEG 图片
    
    let fullSizeImage = CIImage(contentsOfURL: self.input?.fullSizeImageURL)
    UIGraphicsBeginImageContext(fullSizeImage.extent().size);
    self.filter.inputImage = fullSizeImage
    UIImage(CIImage: self.filter.outputImage)?.drawInRect(fullSizeImage.extent())

    let outputImage = UIGraphicsGetImageFromCurrentImageContext()
    let jpegData = UIImageJPEGRepresentation(outputImage, 1.0)
    UIGraphicsEndImageContext()

    jpegData.writeToURL(output.renderedContentURL, atomically: true)

    // 调用完成回调提交编辑后的图片。
    
    completionHandler?(output)
  }
}
```

一旦对 `completionHandler` 返回，你就可以清空临时数据，并且修改后的文件已经准备好从扩展返回。

## 常见问题

与创建图片编辑扩展相关的内容其中一些可能有些复杂，本节内容将介绍最重要的几个。

### 调整数据 (Adjustment Data)

`PHAdjustmentData` 是一个只包含三个属性的简单类，但是想要用好的话，依然需要遵循一些规则。苹果建议使用反向域名解析格式来指定 `formatIdentifier`，但是 `formatVersion` 和 `data` 如何使用将由你自己决定。

重要的是要确保你不同版本图片编辑扩展的兼容性，所以我们需要类似[语义化版本](http://semver.org/)这样能提供灵活的管理产品的生命周期的方式。你可以以自己的方式进行解析，也可以依赖于像 [SemverKit](https://github.com/nomothetis/SemverKit) 之类的第三方框架提供的功能。

最后对于调整数据要说的是 `data` 本身，它是一个 `NSData` 数据对象。苹果提供的唯一建议是它应该用来存放重建编辑时所需要的的设定，而不是编辑本身，这是因为 `PHAdjustmentData` 对象的尺寸是受 Photo 框架限制的。

对于不是很复杂的扩展 (比如 **Filtster**)，这个数据可以是简单地对一个字典归档，代码如下：

```
public func encodeFilterParameters() -> NSData {
  var dataDict = [String : AnyObject]()
  dataDict["vignetteIntensity"] = vignetteIntensity
  ...
  return NSKeyedArchiver.archivedDataWithRootObject(dataDict)
}
```

接着提供解析方式：

```
public func importFilterParameters(data: NSData?) {
  if let data = data {
    if let dataDict = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String : AnyObject] {
      vignetteIntensity = dataDict["vignetteIntensity"] as? Double ?? vignetteIntensity
      ...
    }
  }
}
```

这里，这两个方法存在于共享的 `FiltsterFilter` 类中，同时这个类也负责确定调整数据的兼容性：

```
public func supportsFilterIdentifier(identifier: String, version: String) -> Bool 
  return identifier == filterIdentifier && version == filterVersion
}
```

如果你有更复杂的需求，你可以创建一个自定义的设置类，让它支持 `NSCoding` 协议并用类似的方式进行归档。

用户需要可以将互不兼容的照片编辑串联起来 -- 如果当前扩展无法理解调整数据的话，一张预先渲染好的图像将被作为输入。比如你可以使用系统的裁剪工具先对图片进行裁剪，然后再在你的自定义照片编辑扩展中使用。在你存储编辑后的图像时，与之绑定的编辑数据只会包含最近的编辑的细节。你可以将之前的不兼容的编辑的调整数据保存到你的输出调整数据中，这样你就可以为滤镜链中你的阶段实现还原功能。Photo 框架提供的还原功能将移除所有编辑，并把照片恢复到原始状态：

![还原编辑](/images/issues/issue-21/revert.png)

### 代码/数据共享

照片编辑扩展作为一个嵌入式二进制文件包含在容器应用中。因为苹果要求这个容器应用必须有完整功能，因此你创建的照片编辑扩展，很可能与容器应用有相同的功能。你可能会希望在应用扩展和容器之间共享代码和数据。

共享代码通过 iOS 8 新功能 -- 创建 Cocoa Touch 框架 target 来实现。你可以向其中添加共用的功能，例如滤镜链和自定义视图类，并在应用和扩展中同时使用。

值得注意的是因为用于创建扩展，你必须在 Target 设置界面将 API 兼容性限制为仅扩展可用：

![限制框架 API](/images/issues/issue-21/app_extension_api.png)

共享数据的需求明显要少很多，在许多情况下并不存在。然而如果需要，你可以通过把应用和扩展都添加到一个关联到你的开发者账号的 app group 中的方式，来创建一个共享容器 (shared container)。共享容器代表的是磁盘上的一块共享的空间，你可以使用任何你喜欢的方式使用它，比如 `NSUserDefaults`，`SQLite` 或者写文件。

### 调试与分析

Xcode 调试虽然有一些潜在症结，但已经相当友好了。选择扩展的 scheme 并编译运行，接着会询问你希望启动哪一个应用，因为图片编辑扩展只能在系统照片应用中实现，所以你应该选择照片应用：

![选择应用](/images/issues/issue-21/select_app.png)

如果这么做启动的是你的容器应用的话，你可以编辑扩展 scheme 设置 executable 为 **Ask on Launch** 来解决。

Xcode 然后会等待你打开你的照片编辑扩展，然后将调试器挂载上去。从这时开始，你就可以用调试标准 iOS 应用的方式来调试扩展了。将调试器附加到扩展可能需要一些时间，所以当你激活扩展时，扩展可能会失去响应一段时间。如果你想评估启动时间的话，可以在 release 模式下运行它。

性能分析和调试类似，分析器在扩展开始执行后附加上去。你可以更新扩展相关 scheme 指定 Xcode 询问应该启动哪一个应用来执行分析。

### 内存限制

扩展不是一个全功能 iOS 应用，因此访问系统资源时要受到限制。更特别的是，如果用户使用太多内存，系统将优先关闭扩展进程。我们无法确定具体的内存限制，因为内存管理是由 iOS 内部处理的，但有这肯定是基于像是设备，宿主应用，以及其他应用程序的内存压力这些因素的。所以其实并没有硬性的限制，但我们还是应该尽量减少内存占用。

图片处理是一个高内存操作，特别是处理的对象是来自 iPhone 相机的高清晰度图片。你需要做几件事情来确保照片编辑扩展的内存使用量降到最低。

- **使用显示尺寸的图片** 当你开始编辑进程时，系统提供了一张适合屏幕尺寸的图片。用它来替代原始图片，将在交互编辑阶段将显著减少内存使用。
- **限制 Core Graphics 上下文数量** 虽然使用 Core Graphics 来处理图片是正确的方式，但不要忘记 Core Graphics 上下文其实是一大块内存。如果你需要上下文，那么需要保持数量到最低。尽可能的重用，并想想你是否以最佳的方式在使用它。
- **使用 GPU** 无论通过 Core Image 还是类似 GPUImage 的第三方框架来用 GPU 进行处理，你可以通过链式调用滤镜来降低内存并且消除中间缓存区需求。

因为图像编辑本身肯定就需要高内存，所以与其他扩展相比，照片编辑扩展的可用内存要多那么一些。在 ad hoc 测试中，图片编辑扩展可以使用高于 100 MB 内存。鉴于来自 800 万像素相机的照片大约 22MB，所以这个内存量对于大多数图片编辑扩展来说是够用的。

## 结论

iOS 8 之前，第三方开发者无法在他自己应用程序之外向用户提供功能。扩展的出现彻底改变这一状况，特别是照片编辑扩展允许你把代码运行于照片应用核心中。尽管多次点击的流程略显复杂，但照片编辑扩展使用 Photo 框架的功能提供了连贯和集成的用户体验。

可恢复的编辑一直是像 Aperture 或 Lightroom 这样的桌面应用的杀手级功能。而现在在 iOS 中使用 Photo 框架，也可以为这个功能创建一个通用架构。这具有巨大的潜力，而允许第三方开发者创建照片编辑扩展则使这一步走得更远。

制作照片编辑扩展方面有不少复杂的课题，但是它们都不是独一无二的。创建一个直观的用户界面，以及设计图像处理算法都和图片编辑扩展一样充满了挑战性，而它们都是一个完整的图片编辑应用的组成部分。

目前为止有多少用户留意到这些第三方编辑扩展还有待观察，但总的来说这有助于提高你应用曝光率。

---
 

原文 [Photo Extensions](http://www.objc.io/issue-21/photo-extensions.html)
