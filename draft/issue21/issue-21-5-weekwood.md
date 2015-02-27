When iOS 8 came out, Apple introduced extensions to the world, with
[six extension points](https://developer.apple.com/library/prerelease/ios/documentation/General/Conceptual/ExtensibilityPG/index.html#//apple_ref/doc/uid/TP40014214-CH20-SW2)
available. These offer unprecedented access to the operating system, with the
Photo Editing extension allowing developers to build functionality into the
system Photos app.

在 iOS 8 发布时，苹果把[六种全新扩展](https://developer.apple.com/library/prerelease/ios/documentation/General/Conceptual/ExtensibilityPG/index.html#//apple_ref/doc/uid/TP40014214-CH20-SW2)功能介绍给全世界。它们史无前例的提供了访问操作系统的可行性，开发者可以利用照片扩展来为系统相机应用增加功能。

The user workflow for Photo Editing extensions is not entirely simple. From
selecting the photo you want to edit, it takes three taps to launch the
extension, one of which is on a tiny, unintuitive button:

用户使用照片编辑扩展的流程并不简单。从选择编辑的照片开始，需要点击三次才能启动，其中一步骤是非常小一个按钮：

![照片编辑扩展用户流程](http://img.objccn.io/issue-21/user_workflow.png)

Nevertheless, these kinds of extensions offer a fantastic opportunity for
developers to offer a seamless experience to users, thereby creating a consistent
approach to managing photos.

然而，这类扩展给开发者提供了为用户创造无缝体验，创建一致的方法来管理照片的绝佳的机会。

This article will talk briefly about how to create extensions, and their
lifecycle, before moving on to look at the editing workflow in more
details. It will conclude by looking at some common concerns and scenarios
associated with creating Photo Editing extensions.

在了解更详细的编辑工作流之前，将简单讨论如何创建扩展以扩展的生命周期，我们会通过常见的相关问题和场景来创建照片编辑扩展从而得出结论。


The _Filtster_ project, which accompanies this article, demonstrates how you
can set up your own image editing extension. It represents a really simple image
filtering process using a couple of Core Image filters. You can access the
[complete _Filtster_ project on GitHub](https://github.com/objcio/issue-21-photo-extensions-Filtster).

本文的示例项目 _Filtster_，演示了如何创建自己的图片编辑扩展。它诠释使用了数个 Core Image 滤镜完成简单的图像过滤效果。[完整 _Filtster_ 项目代码](https://github.com/objcio/issue-21-photo-extensions-Filtster)。

## Creating an Extension
## 创建扩展

All types of iOS extensions have to be contained in a fully functional iOS app,
and this includes Photo Editing extensions. This can mean that you have to
do a lot of work to get your amazing new custom Core Image filter in the hands of
some users. It remains to be seen how strict Apple is on this, since most apps
in the App Store with custom image editing extensions existed before the
introduction of iOS 8.

所有扩展必须包含在一个功能齐全的 iOS 应用程序之内，其中也包括照片编辑扩展。这可能意味着你必须做很多令人吃惊的自定义 Core Image 滤镜的才能让它到达用户手中。苹果如何严格审查还有待观察，因为在 iOS 8 引入之前，苹果商店内的大多数应用已经使用自定义了图像编辑扩展。

To create a new image editing extension, add a new target to an existing iOS
app project. There is a template target for the extension:

为了创建新的图片编辑扩展，需要为已有 iOS 添加新的 target，扩展 target 模板如下：

![图片编辑扩展模板](http://img.objccn.io/issue-21/xcode-target-template-photo-extension.png)

This template consists of three components:
模板由三部分组成：

1. __Storyboard.__ Image editing extensions can have an almost completely custom UI. The system provides only a toolbar across the top, containing _Cancel_ and
_Done_ buttons:

1. __Storyboard.__ 图片编辑扩展除了系统在顶部提供的 toolbar 包含 _Cancel_ 以及 _Done_ 按钮之外，界面几乎完全可以自定义。

	![Cancel/Done 按钮](http://img.objccn.io/issue-21/cancel_done.png)

	Although the storyboard doesn't have size classes enabled by default, the system will respect them should you choose to activate them. Apple highly recommends using Auto Layout for building Photo Editing extensions, although there is no obvious reason why you couldn't perform manual layout. Still, you're flying in the face of danger if you decide to ignore Apple's advice.

虽然 storyboard 默认不包含 size classes，系统将允许你选择并激活该功能，苹果强烈建议使用 Auto Layout 来创建照片编辑扩展，虽然没有明显的原因来阻止你使用手动布局。不过如果你忽略苹果的建议你将不得不面对很多潜在风险。

2. __Info.plist.__ This specifies the extension type and accepted media types,
and is common to all extension types. The `NSExtension` key has a
dictionary containing all the extension-related configurations:

2. __Info.plist.__  指定扩展类型和可被接受媒体类型，以及扩展的通用配置。`NSExtension` 键值是一个字典包含扩展所需要的配置：
	![扩展 plist](http://img.objccn.io/issue-21/extension_plist.png)

	The  `NSExtensionPointIdentifier` entry informs the system that this is a Photo Editing extension with a value of `com.apple.photo-editing`. The only key that is specific to photo editing is `PHSupportedMediaTypes`, and this is related to what types of media the extension can operate on. By default, this is an array with a single entry of `Image`, but you have the option of adding `Video`.
	
`NSExtensionPointIdentifier` 实体告诉系统这是一个使用  `com.apple.photo-editing` 值的照片编辑扩展。唯一特殊的 key 是 `PHSupportedMediaTypes`，指明可以被操作的媒体类型。在默认情况下，这是一个数组包含 `Image` 实体，当然你也可添加 `Video` 选项。

3. __View Controller.__ This adopts the `PHContentEditingController` protocol,
which contains methods that form the lifecycle of an image editing extension.
See the next section for further detail.

3. __View Controller.__ 采用了 `PHContentEditingController` 协议，其中包含了图片编辑扩展需要的生命周期方法。更多详情见下文。

Notably missing from this list is the ability to provide the imagery for the
icon that appears in the extension selection menu:

值得注意的是不要忘记提供菜单内的扩展的图标：

![扩展图标](http://img.objccn.io/issue-21/extension_icon.png)

This icon is provided by the App Icon image set in the host app's asset catalog.
The documentation is a little confusing here, as it implies that you have to
provide an icon in the extension itself. However, although this is possible, the
extension will not honor the selection. This point is somewhat moot, as Apple
specifies that the icon associated with an extension should be identical to that
of the container app.

图标通过苹果内置的资源目录内的 App Icon 提供。这里文档有些疑惑，因为这意味着你必须提供扩展本身的图标。然而，尽管这是有可能的，扩展将不会使用选择，这一点有些争议，因为苹果指定与扩展相关的图标必须与容器应用程序的相同。

## Extension Lifecycle
## 扩展的生命周期

The Photo Editing extension is built on top of the Photos framework, which means
that edits aren't destructive. When a photo asset is edited, the original file
remains untouched, while a rendered copy is saved. It addition, semantic
details about how to recreate the edit are saved as adjustment data. This data
means that the edit can be completely recreated from the original image. When
you implement image editing extensions, you are responsible for constructing your
own adjustment data objects.

照片编辑扩展建立于照片框架之上，这意味着编辑不是破坏性的。当一个照片资源被编辑的时候，原始文件始终没有被修改，而作为副本保存下来。另外，语义细节包含了如何重新编辑并保存调整后的数据。这个数据的意思是编辑可以基于原始文件重新来过。当你实现图片编辑扩展的时候，你只负责调整修改你自己的数据对象。

The `PHAdjustmentData` class represents these edit parameters, and has two
format properties (`formatIdentifier` and `formatVersion`) that are used to
determine compatibility of an editing extension with a previously edited image.
Both properties are strings, and the `formatIdentifier` should be in reverse-DNS
form. These two properties give you the flexibility to create a suite of image
editing apps and extensions, each of which can interpret the editing results from
the others. There is also a `data` property that is of type `NSData`. This can
be used however you wish to store the details of how your extension can resume
editing.

`PHAdjustmentData` 类含有编辑所需参数，以及两个格式化的属性 (`formatIdentifier` 和 `formatVersion`) 用来确定当前编辑扩展针对于之前的编辑照片的兼容性。它们两个都是字符串类型，另外 `formatIdentifier` 规定为反向域名解析格式。这两个属性让你灵活的创建一套图像编辑的应用程序以及扩展，每一种都可以用另一种表示。另外 `data` 属性是 `NSData` 类型。可以被用来存储你扩展操作的细节。

### Beginning Editing
### 开始编辑

When a user chooses to edit an image using your extension, the system will instantiate your view controller and initiate the photo editing lifecycle. If the photo has previously been edited, this will first call the `canHandleAdjustmentData(_:)` method, at which point you are provided a `PHAdjustmentData` object. As such, it's important to figure out in advance whether or not your extension can handle the previous edit data. This determines what the framework will send to the next method in the lifecycle.

当用户使用你的扩展来编辑照片的时候，系统会实例化你的视图控制器并且初始化照片编辑的生命周期。如果照片之前曾经被编辑，它首先会调用 `canHandleAdjustmentData(_:)` 方法，指向你提供的 `PHAdjustmentData` 对象，因此，重要的是要找出您的扩展是否可以提前处理之前编辑的数据。这将决定框架发送的下一个生命周期的方法。

Once the system has decided to supply either the original image or one
containing the rendered output from previous edits, it then calls the
`startContentEditingWithInput(_:, placeholderImage:)`. The input is an object of
type `PHContentEditingInput`, which contains metadata such as location, creation
data, and media type about the original asset, alongside the details you need to
edit the asset. In addition to the path of the full-size input
image, the input object also contains a `displaySizedImage` that represents the
same image data, but is scaled appropriately for the screen. This means that the
interactive editing phase can operate at a lower resolution, ensuring that your
extension remains responsive and energy efficient.

一旦系统决定提供原始图片还是渲染被编辑过的图片，接下来将要调用 `startContentEditingWithInput(_:, placeholderImage:)`。输入对象的类型是 `PHContentEditingInput`，其中包含了地理位置，创建时间以及媒体类型等来自于原始资源的元数据，以及你需要编辑的资源细节。除了原始尺寸的输入图片，输入对象还包含一个 `displaySizedImage` 表示相同的图片数据，但是适当根据屏幕尺寸进行缩放。意思是说交互编辑可以在较低分辨率下进行，确保扩展依然可以在低功耗下使用。

The following shows an implementation of this method:

下面是实现方法

```swift
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

The above implementation stores the `contentEditingInput`, since it's required to
complete the edit, and imports the filter parameters from the
adjustment data.

以上实现了存储 `contentEditingInput`，因为它需要完成编辑和从调整后的数据导入滤镜参数。

If your `canHandleAdjustmentData(_:)` method returned `true`, then the images
provided to `startContentEditingWithInput(_:, placeholderImage:)` will be
original, and the extension will have to recreate the edited image from the
previous adjustment data. If this is a time-consuming process, then the
`placeholderImage` is an image of the rendered previous edit that can be used
temporarily.

如果你的 `canHandleAdjustmentData(_:)` 返回 `true`，`startContentEditingWithInput(_:, placeholderImage:)` 将会返回原始图片，并且扩展将根据调整后的数据重新创建编辑图片。如果这是一个耗时操作，接下来 `placeholderImage` 将临时显示之前的图片。

At this stage, the user interacts with the UI of the extension to control the
editing process. Since the extension has a view controller, you can use any of
the features of UIKit to implement this. The sample project uses a Core Image
filter chain to facilitate editing, so the UI is handled with a custom `GLKView`
subclass to reduce the load on the CPU.

在这个阶段，用户对于扩展界面的交互将控制编辑进程。因为扩展包含一个视图控制器，你可以使用任何 UIKit 来实现。示例项目使用了 Core Image 的滤镜链来完成编辑，所以界面需要处理一个自定义的 `GLKView` 子类来减少 CPU 的负载。

### Cancelation
### 取消编辑

To finish editing, users can select either the _Cancel_ or _Done_ buttons
provided by the Photos UI. If the user decides to cancel with unsaved edits,
then the `shouldShowCancelConfirmation` property should be overridden to return
`true`:

在完成编辑时，用户可以选择照片界面提供的 _Cancel_ 或者 _Done_ 按钮。如果用户决定取消编辑内容，`shouldShowCancelConfirmation` 需要重写为 `true`：

![确认取消](http://img.objccn.io/issue-21/confirm_cancel.png)

If the cancelation is requested, then the `cancelContentEditing` method is
called to allow you to clear up any temporary data that you've created.

如果需要取消操作，`cancelContentEditing` 方法将被调用来允许你清空所有临时数据。

### Commit Changes
### 提交修改

Once the user is happy with his or her edits and taps the _Done_ button, a call is
made to `finishContentEditingWithCompletionHandler(_:)`. At this point, the full-size image needs to be edited with the settings that are currently applied to
the display-sized image, and the new adjustment data needs saving.

一旦用户决定保存他或者她的编辑操作，并且点击 _Done_ 按钮，`finishContentEditingWithCompletionHandler(_:)` 将会被调用。在这个时候，原始尺寸图像需要用与全屏图片相同设置来编辑，并保存调整后的数据。

At this point, you can obtain the full-size image using the `fullSizeImageURL` on
the `PHContentEditingInput` object provided at the beginning of the editing
process.

在这一点上，你可以通过在编辑过程提供的 `PHContentEditingInput` 对象内的 `fullSizeImageURL` 来获取原始尺寸图片。

To complete editing, the supplied callback should be invoked with a
`PHContentEditingOutput` object, which can be created from the input. This
output object also includes a `renderedContentURL` property that specifies
where you should write the output JPEG data:

完成编辑，应用调用提供的回调返回建立自输入的 `PHContentEditingOutput` 对象，输出对象包含 `renderedContentURL` 属性写入 JPEG 图片：

```swift
func finishContentEditingWithCompletionHandler(completionHandler: ((PHContentEditingOutput!) -> Void)!) {
  // Render and provide output on a background queue.
  // 从后台队列渲染并提供输出。
  dispatch_async(dispatch_get_global_queue(CLong(DISPATCH_QUEUE_PRIORITY_DEFAULT), 0)) {
    // Create editing output from the editing input.
    // 从编辑输入提供编辑输出。
    
    let output = PHContentEditingOutput(contentEditingInput: self.input)

    // Provide new adjustments and render output to given location.
    // 提供调整后的数据并且渲染输出到指定位置。
    
    let adjustmentData = PHAdjustmentData(formatIdentifier: self.filter.filterIdentifier,
      formatVersion: self.filter.filterVersion, data: self.filter.encodeFilterParameters())
    output.adjustmentData = adjustmentData

    // Write the JPEG data
    // 写入 JPEG 图片
    
    let fullSizeImage = CIImage(contentsOfURL: self.input?.fullSizeImageURL)
    UIGraphicsBeginImageContext(fullSizeImage.extent().size);
    self.filter.inputImage = fullSizeImage
    UIImage(CIImage: self.filter.outputImage)?.drawInRect(fullSizeImage.extent())

    let outputImage = UIGraphicsGetImageFromCurrentImageContext()
    let jpegData = UIImageJPEGRepresentation(outputImage, 1.0)
    UIGraphicsEndImageContext()

    jpegData.writeToURL(output.renderedContentURL, atomically: true)

    // Call completion handler to commit edit to Photos.
    // 调用完成回调提交编辑后的图片。
    
    completionHandler?(output)
  }
}
```

Once the call to the `completionHandler` has returned, you can clear up any
temporary data and files ready for the extension to return.

一旦调用回调 `completionHandler`，你可以清空临时数据并且修改后的文件已经准备好从扩展返回。


## Common Concerns
## 常见问题

There are a few areas associated with creating an image editing extension that
can be a little complicated. The topics in this section address the most
important of these.

与创建图片编辑扩展相关的内容其中一些可能有些复杂，本节内容将介绍最重要的几个。

### Adjustment Data
### 调整数据

The `PHAdjustmentData` is a simple class with just three properties, but to get
the best use from it, discipline is required. Apple suggests using reverse-DNS
notation to specify the `formatIdentifier`, but then you are left to decide how
to use the `formatVersion` and `data` properties yourself.

`PHAdjustmentData` 是一个包含三个属性的简单类，但是要获取最佳实践一些规则依然需要遵循。苹果建议使用反向域名解析格式来指定 `formatIdentifier`，但是 `formatVersion` 和 `data` 如何使用将有你自己决定。

It's important that you can determine compatibility between different versions
of your image editing framework, so an approach such as [semantic versioning](http://semver.org/)
offers the flexibility to manage this over the lifetime of your products. You
could implement your own parser, or look to a third-party framework such as
[SemverKit](https://github.com/nomothetis/SemverKit) to provide this
functionality.

重要的是要确保你不同版本图片编辑扩展的兼容性，[语义化版本](http://semver.org/)提供了灵活的方式来管理产品的生命周期。你可以实现你自己的解析，或者依赖于第三方框架比如 [SemverKit](https://github.com/nomothetis/SemverKit) 提供的功能。

The final aspect of the adjustment data is the `data` property itself,
which is just an `NSData` blob. The only advice that Apple offers here is that
it should represent the settings to recreate the edit, rather than the edit
itself, since the size of the `PHAdjustmentData` object is limited by the Photos
framework.

调整数据的最后要提及的是 `data` 本身，它是一个 `NSData` 二进制类型。苹果提供的唯一忠告是利用设置来重新创建编辑数据，替代原编辑数据本身，因为 `PHAdjustmentData` 对象受照片框架所限。

For non-complex extensions (such as _Filtster_), this can be as simple as an
archived dictionary, which can be written as follows:

对于不是很复杂的扩展（比如 _Filtster_），它可以简单的对字典归档，类似于

```swift
public func encodeFilterParameters() -> NSData {
  var dataDict = [String : AnyObject]()
  dataDict["vignetteIntensity"] = vignetteIntensity
  ...
  return NSKeyedArchiver.archivedDataWithRootObject(dataDict)
}
```

This is then reinterpreted with the following:
接着提供解析方式：

```swift
public func importFilterParameters(data: NSData?) {
  if let data = data {
    if let dataDict = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String : AnyObject] {
      vignetteIntensity = dataDict["vignetteIntensity"] as? Double ?? vignetteIntensity
      ...
    }
  }
}
```

Here, these two methods are on the shared `FiltsterFilter` class, which is also
responsible for determining compatibility of the adjustment data:

这里，有两个方法被 `FiltsterFilter` 类共享，负责确定调整数据的兼容性：

```swift
public func supportsFilterIdentifier(identifier: String, version: String) -> Bool 
  return identifier == filterIdentifier && version == filterVersion
}
```

If you have more complex requirements, you could create a custom settings
class, which adopts the `NSCoding` protocol to allow it to be archived in a
similar manner.

如果你有更复杂的需求，你可以创建一个自定义的类，支持 `NSCoding` 协议允许用类似的方式归档。

A user can chain incompatible photo edits together — if the adjustment
data is not understood by the current extension, the pre-rendered image will be
used as input. For example, you can crop an image using the system crop tool
before using your custom Photo Editing extension. Once you have saved the edited
image, the associated adjustment data will only contain details of the most
recent edit. You could store adjustment data from the previous, incompatible edit
in your output adjustment data, allowing you to implement a revert function for
just your phase of the filter chain. The revert function provided by the Photos
app will remove all the edits, returning the photo to its original state:

用户可以链式调用不同的照片编辑扩展 - 如果调整数据没有被正确解析，预加载图片将作为输入渲染，比如你用系统剪切工具在用照片编辑扩展之前剪切了一张图片。一旦你保存编辑后的图片，数据相关的调整将只包含最新编辑的详细信息。你应该存储之前的不兼容调整数据输出，允许你实现还原功能来跳过你的滤镜链。提供在照片应用的还原功能将移除所有编辑，返回照片原始状态：

![还原编辑](http://img.objccn.io/issue-21/revert.png)


### Code/Data Sharing
### 代码/数据共享

Photo Editing extensions are distributed as an embedded binary inside a
container app, which Apple has stated must be a functioning app. Since you're
creating a Photo Editing extension, it is likely that the app will offer the
same functionality. You're therefore likely to want to share code and data
between the app extension and the container app.

照片编辑扩展作为一个嵌入式二进制包含在容器应用中，因为苹果提出应用必须有完整功能。因此你创建的照片编辑扩展，很可能与容器应用有相同的功能，所以你可能希望在应用扩展和容器之间共享代码和数据。

Sharing code is achieved by creating a Cocoa Touch Framework target, a new
functionality available in iOS 8. Then you can add shared functionality, such as
the filter chain and custom view classes, and use them from both the app and
the extension.

共享代码通过 iOS 8 新功能，创建 Cocoa Touch 框架 target 实现。接着你可以共享功能，例如滤镜链和自定义视图类，在应用和扩展中使用。

Note that since the framework will be used from an app extension, you must
restrict the APIs it can use on the Target Settings page:

值得注意的是因为用于创建扩展，你必须在 Target 设置界面限制 API：

![限制框架 API](http://img.objccn.io/issue-21/app_extension_api.png)

Sharing data is a less obvious requirement, and in many cases it won't exist.
However, if necessary, you can create a shared container, which is
achieved by adding both the app and extension to an app group associated with
your developer profile. The shared container represents a shared space on disk
that you can use in any way you wish, e.g. `NSUserDefaults`, `SQLite`, or file
writing.

共享数据的需求明显要少很多，在许多情况下并不存在。然而如果需要，你创建的共享将通过应用程序和扩展添加到与开发人员配置文件关联的应用程序组。通过共享硬盘空间方式，你可以使用任何你喜欢的方式实现，比如 `NSUserDefaults`，`SQLite` 或者写文件。

### Debugging and Profiling
### 调试与分析

Debugging is reasonably well-supported in Xcode, although there are some
potential sticking points. Selecting the extension's scheme and selecting run
should build it and then let you select which app to run. Since photo
editing extensions can only be activated from within the system Photos app, you
should select the Photos app:

Xcode 调试相当友好，虽然有一些潜在症结。选择扩展 scheme 并编译运行接着提示你希望启动哪一个应用，因为图片编辑扩展只能在系统照片应用中实现，所以你应该选择照片应用：

![选择应用](http://img.objccn.io/issue-21/select_app.png)

If this instead launches your container app, then you can edit the extension's
scheme to set the executable to _Ask on Launch_.

如果你不想启动容器应用程序，你可以编辑扩展 scheme 设置 executable 为 _Ask on Launch_。

Xcode then waits for you to start the Photo Editing extension before attaching
to it. At this point, you can debug as you do with standard iOS apps. The
process of attaching the debugger to the extension can take quite a long time,
so when you activate the extension, it can appear to hang. Running in release mode
will allow you to evaluate the extension startup time.

Xcode 然后等待你开始照片编辑扩展前附加它。在这一点上，你可以用标准 iOS 方式来调试。调试附加到扩展可能需要一些时间，当你激活扩展，它可能挂起，在 release 模式下运行你可以评估启动时间。

Profiling is similarly supported, with the profiler attaching as the extension
begins to run. You might once again need to update the scheme associated with
the extension to specify that Xcode should ask which app should run as profiling
begins.

分析的支持类似，分析器附加在扩展开始执行之前，你可以更新扩展相关 scheme 指定 Xcode 询问哪一个应用来执行分析。


### Memory Restrictions
### 内存限制

Extensions are not full iOS apps and therefore are permitted restricted access
to system resources. More specifically, the OS will kill an extension if it uses
too much memory. It's not possible to determine the exact memory limit, since memory management is handled privately by iOS, however it is definitely dependent on factors such as the device, the host app, and the memory pressure from other apps. As such, there are no hard
limits, but instead a general recommendation to minimize the memory footprint.

扩展不是一个全功能 iOS 应用，因此访问系统资源受限。更特别的时，如果用户使用太多内存，OS 将优先关闭扩展进程。无法确定具体的内存限制，因为内存管理是由 iOS 内部处理，但有一些决定性因素，比如设备，宿主应用，以及其他应用程序的内存压力。因此，没有硬性限制，而是尽量减少内存占用。

Image processing is a memory-hungry operation, particularly with the resolution
of the photos from an iPhone camera. There are several things you can do to keep
the memory usage of your Photo Editing extension to a minimum.

图片处理是一个高内存操作，特别是来自 iPhone 相机的高清晰度图片。你需要做几件事情来确保内存使用量降到最低。

- __Work with the display-sized image:__ When beginning the edit process, the
system provides an image suitably scaled for the screen. Using this instead of
the original for the interactive editing phase will require significantly less
memory.

- __使用全屏图片:__ 当你开始编辑进程，系统提供了一张适合屏幕尺寸的图片。用来替代原始图片在交互编辑阶段将显著减少内存使用。
- __Limit the number of Core Graphics contexts:__ Although it might seem like the way
to work with images, a Core Graphics context is essentially just a big chunk of memory. If you need to use contexts, then keep the number to a minimum. Reuse themwhere possible, and decide whether you're using the best approach.
- __限制 Core Graphics 上下文数量:__ 因为处理图片，Core Graphics 上下文基本是一大块内存。如果你需要上下文，那么需要保持数量到最低。尽可能的重用，决定你是否使用最佳方式。
- __Use the GPU:__ Whether it be through Core Image or a third-party framework such
as GPUImage, you can keep memory down by chaining filters together and
eliminating the requirement for intermediate buffers.
- __GPU 使用:__ 无论通过 Core Image 或者第三方框架类似 GPUImage，你可以通过链式调用滤镜来降低内存并且消除中间缓存区需求。

Since image editing is expected to have high memory requirements, it seems that
the extensions are given a little more leeway than other extension types. During
ad hoc testing, it appears to be possible for an image editing extension to use
more than 100 MB. Given that an uncompressed image from an 8-megapixel camera is
approximately 22 MB, most image editing should be achievable.

因为内存编辑预计需要高内存，看来需要给其他扩展留有回旋余地。在 ad hoc 测试中，图片编辑扩展使用了高于 100 MB 内存。鉴于来自 800 万像素相机的照片大约 22MB，大多数图片编辑扩展应该可以实现。


## Conclusion
## 结论

Prior to iOS 8, there was no way for a third-party developer to provide
functionality to the user anywhere other than within his or her own app. Extensions
have changed this, with the Photo Editing extension in particular allowing you
to put your code right into the heart of the Photos app. Despite the slightly
convoluted multi-tap workflow, the Photo Editing extension uses the power of the
Photos framework to provide a coherent and integrated user experience.

iOS 8 之前，第三方开发者无法提供他自己应用程序之外的功能给用户。扩展的出现彻底改变这一状况，特别是照片编辑扩展允许你把代码运行于照片应用核心中。尽管转换、流略显复杂，但照片编辑扩展提供了连贯和集成的用户体验。

Resumable editing has traditionally been reserved for use in desktop photo
collection applications such as Aperture or Lightroom. Creating a common
architecture for this on iOS with the Photos framework offers great
potential, and allowing the creation of Photo Editing extensions takes this even
further.

可恢复的编辑一直被保留并可以在桌面应用收集程序比如 Aperture 或 Lightroom 中使用。在 iOS 中为照片框架创建一个通用架构有巨大潜力，并允许进一步创建照片编辑扩展。

There are some complexities associated with creating Photo Editing extensions,
but few of these are unique. Creating an intuitive interface and designing image processing algorithms are both as challenging for image editing extensions as they are for complete image editing apps.

这里有一些复杂性与创建照片编辑相关，但有一些是独一无二的。创建一个直观界面并且设计图片处理算法在创建图片编辑扩展时有不亚于创建完整图片应用的挑战性。

It remains to be seen how many users are aware of these third-party image editing
extensions, but they have the potential to increase your app's exposure.

目前为止有多少用户留意到这些第三方编辑扩展还有待观察，但总的来说这有助于提高你应用曝光率。