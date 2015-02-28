# The Photos Framework
# 照片框架
[Issue #21 Camera and Photos](http://www.objc.io/issue-21/index.html), February 2015
By [Saniul Ahmed](https://twitter.com/saniul)

## Introduction
## 介绍

Every day, [more photos are taken with the iPhone](https://www.flickr.com/cameras#brands) than any other camera. Displays on iOS devices get better every year, but even back in the pre-Retina era [when the iPad was introduced](http://youtu.be/_KN-5zmvjAo?t=17m7s), one of its killer uses was just displaying user photos and exploring the photo library. Since the camera is one of the iPhone’s most important and popular features, there is a big demand for apps and utilities that make use of the wealth of users' photo libraries.

每天，用 [iPhone 照的照片](https://www.flickr.com/cameras#brands)数量超过了任何相机。每年 iOS 设备上的显示效果变得越来越好，即使回到 [iPad 刚出现](http://youtu.be/_KN-5zmvjAo?t=17m7s)还没有 Retina 的时代，，它其中的一个杀手级功能就是可以展示用户照片和浏览器照片库。自从相机成为 iPhone 最重要和最受欢迎的功能，就对使用照片库资源的应用程序有了巨大的需求。

Until the summer of 2014, developers used the [AssetsLibrary Framework](https://developer.apple.com/library/ios/documentation/AssetsLibrary/Reference/ALAssetsLibrary_Class/#//apple_ref/doc/uid/TP40009722-CH1-SW57) to access the ever-growing photo libraries of users. Over the years, Camera.app and Photos.app have changed significantly, adding new features, including a way of organizing photos by moments. Meanwhile, the AssetsLibrary framework lagged behind.

直到 2014 年夏天前，开发者只能用 [AssetsLibrary 框架](https://developer.apple.com/library/ios/documentation/AssetsLibrary/Reference/ALAssetsLibrary_Class/#//apple_ref/doc/uid/TP40009722-CH1-SW57)访问日益增长的用户的照片库。几年以来，相机应用和照片应用发生了显著的变化，增加了许多新特性，包括按时刻来组织照片方式。与此同时，AssetsLibrary 框架却没有跟上步伐。

With iOS 8, Apple has given us PhotoKit, a modern framework that’s more performant than AssetsLibrary and provides features that allow applications to work seamlessly with a device’s photo library.

随着 iOS 8 的到来，苹果给我们提供了一个现代化的框架 —— PhotoKit，它比 AssetsLibrary 性能更好，并且拥有让应用和设备照片库无缝工作的特性。

## Outline
## 概要

We’ll start with a bird’s-eye view of the [framework’s object model](#PhotoKit-Object-Model): the entities and the relationships between them, fetching instances of those entities, and working with the fetch results.

我们将从[框架对象模型](#PhotoKit-Object-Model)的鸟瞰图开始：实体和实体间的关系，获取实体的实例，使用获取的结果工作。

Additionally, we’ll cover [the asset metadata](#Photo-metadata) that wasn’t available to developers when using AssetsLibrary.

除此之外，我们的讲解还会涉及到一些在使用 AssetsLibrary 时，尚未对开发者开放的[资源元数据](#Photo-metadata)。

Then we’ll discuss [loading the assets' image data](#Photo-Loading): the process itself, multitudes of available options, some gotchas, and edge cases.

然后我们会讨论[加载资源的图像数据](#Photo-Loading)：图像数据的自我处理，大量的开放选择权，一些陷阱和边界案例。

Finally, we’ll talk about [observing changes](#The-Times-They-Are-A-Changin) made to the photo library by external actors and learn how to make and commit [our own changes](#Wind-of-Change).

最后，我们会谈谈通过外部参与者[观察照片库的变化](#The-Times-They-Are-A-Changin)，学习如何创建和提交我们[自己修改的变化](#Wind-of-Change)。

<a name="PhotoKit-Object-Model"></a>
## PhotoKit Object Model
## PhotoKit 对象模型

PhotoKit defines an entity graph that models the objects presented to the user in the stock Photos.app. These photo entities are lightweight and immutable. All the PhotoKit objects inherit from the abstract `PHObject` base class, whose public interface only provides a `localIdentifier` property.

PhotoKit 定义了一个在 Photos 应用内展现给用户的模型对象的实体图表。这些照片实体是轻量级和不可变的。所有的 PhotoKit 对象都是继承自 `PHObject` 抽象基类，其公共接口只提供了一个 `localIdentifier` 属性。

`PHAsset` represents a single asset in the user’s photo library, providing the [metadata](#Photo-metadata) for that asset.

`PHAsset` 表示用户照片库中一个单独的资源，用以提供[资源的元数据](#Photo-metadata)。

Groups of assets are called asset collections and are represented by the `PHAssetCollection` class. A single asset collection can be an album or a moment in the photo library, as well as one of the special “smart albums.” These include collections of all videos, recently added items, user favorites, all burst photos, [and more](https://developer.apple.com/library/prerelease/ios/documentation/Photos/Reference/PHAssetCollection_Class/index.html#//apple_ref/c/tdef/PHAssetCollectionSubtype). `PHAssetCollection` is a subclass of `PHCollection`.

一组的资源叫做资源集合，用 `PHAssetCollection` 类表示。一个单独的资源集合可以是照片库中的一个相册或者一个时刻，就像一个特别的“智能相册”。这些包括所有的视频集合，最近添加的项目，用户收藏，所有连拍照片[等等](https://developer.apple.com/library/prerelease/ios/documentation/Photos/Reference/PHAssetCollection_Class/index.html#//apple_ref/c/tdef/PHAssetCollectionSubtype)。`PHAssetCollection` 是 `PHCollection` 的子类。

`PHCollectionList` represents a group of `PHCollections`. Since it is a `PHCollection` itself, a collection list can contain other collection lists, allowing for complex hierarchies of collections. In practice, this can be seen in the Moments tab in the Photos.app: Asset --- Moment --- Moment Cluster --- Moment Year.

`PHCollectionList` 表示一组的 `PHCollections`。既然它本身就是 `PHCollection`，集合列表就可以包含其他集合列表，允许复杂的集合继承。实际上，我们可以在照片应用的时刻栏目中看到它：照片 --- 时刻 --- 精选 --- 年度。

### Fetching Photo Entities
#### Fetching vs. Enumerating

### 取回照片实体
#### 取回 vs. 枚举

Those familiar with the AssetsLibrary framework might remember that to be able to find assets with specific properties, one has to *enumerate* through the user’s library and collect the matching assets. Granted, the API provided some ways of [narrowing down the search domain](https://developer.apple.com/library/ios/documentation/AssetsLibrary/Reference/ALAssetsGroup_Class/index.html#//apple_ref/occ/instm/ALAssetsGroup/setAssetsFilter:), but it still remains quite unwieldy.

那些熟悉 AssetsLibrary 框架的开发者可能会记得 AssetsLibrary 可以用一些特定属性来找到需要的资源，其中一个是必须*枚举*用户资源库来收集匹配资源。不得不承认，这个 API 虽然提供了一些[缩小搜索域](https://developer.apple.com/library/ios/documentation/AssetsLibrary/Reference/ALAssetsGroup_Class/index.html#//apple_ref/occ/instm/ALAssetsGroup/setAssetsFilter:)的方法，但还是十分繁琐。

In contrast, PhotoKit entity instances are *fetched*. Those familiar with Core Data will recognize the approaches and concepts used and described here.

而与之形成鲜明对比，PhotoKit 实体的实例是*取回*。那些熟悉 Core Data 的人，会觉得和 PhotoKit 在概念和描述都比较接近。

#### Fetch Request
#### 取回请求

Fetches are made using the class methods of the entities described above. Which class/method to use depends on the problem domain and how you’re representing and traversing the photo library. All of the fetch methods are named similarly: `class func fetchXXX(..., options: PHFetchOptions) -> PHFetchResult`. The `options` parameter gives us a way of filtering and ordering the returned results, similar to `NSFetchRequest`’s `predicate` and `sortDescriptors` parameters.

取回操作是由上面描述的实体类方法实现的。要使用哪个类/方法，取决于问题所在范围和你展示与遍历照片库的方式。所有取回方法的命名都是相似的：`class func fetchXXX(..., options: PHFetchOptions) -> PHFetchResult` 。`options` 参数给了我们一个对结果进行过滤和排序的方式，和 `NSFetchRequest` 的 `predicate` 与 `sortDescriptors` 参数类似。

#### Fetch Result
#### 取回结果

You may have noticed that these fetch methods aren’t asynchronous. Instead, they return a `PHFetchResult` object, which allows access to the underlying collection of results with an interface similar to `NSArray`. It will dynamically load its contents as needed and cache contents around the most recently requested value. This behavior is similar to the result array of an `NSFetchRequest` with a set `batchSize` property. There is no way to parametrize this behavior for `PHFetchResult`, but the [documentation promises](https://developer.apple.com/library/prerelease/ios/documentation/Photos/Reference/PHFetchResult_Class/index.html) “optimal performance even when handling a large number of results.”

你可能已经注意到了这些取回操作不是异步的。恰恰相反，它们返回了一个 `PHFetchResult` 对象，可以用类似 `NSArray` 的接口来访问结果内的集合。它会动态加载需要的内容和最近请求的缓存内容。这个行为和有 `batchSize` 系列属性的 `NSFetchRequest` 返回的结果数组相似。对于 `PHFetchResult`，没有办法用参数来指定这个行为，但是[官网文档](https://developer.apple.com/library/prerelease/ios/documentation/Photos/Reference/PHFetchResult_Class/index.html)保证“即使在处理大量的返回结果时，依然能够有最好的表现”。

The `PHFetchResult`s returned by the fetch methods will not be updated automatically if the photo library contents match the request change. Observing changes and processing updates for a given `PHFetchResult` are [described in a later section](http://www.objc.io/issue-21/the-photos-framework.html#The-Times-They-Are-A-Changin).

如果请求修改了照片库内容，取回方法返回的 `PHFetchResult` 对象是不会自动更新。在[后面的小节](http://objccn.io/issue-21-4#The-Times-They-Are-A-Changin)中，会介绍使用返回的 `PHFetchResult` 来观察照片库内容的变动并处理更新内容。

## Transient Collections
## 临时集合

You might find that you have designed a component that operates on an asset collection, and yet you would like to be able to use it with an arbitrary set of assets. PhotoKit provides an easy way to do that using transient asset collections.

你可能会发现你已经设计了一个可以操作资源集合的组件，并且你还希望它能够处理任意一组的资源。PhotoKit 通过临时资源集合，让我们可以轻松做到这个事儿。

Transient asset collections are created explicitly by you from an array of `PHAsset` objects or from a `PHFetchResult` containing assets. This is done using the `transientAssetCollectionWithAssets(...)` and `transientAssetCollectionWithFetchResult(...)` factory methods on `PHAssetCollection`. The objects vended by these methods can be used just like any other `PHAssetCollection`. Despite that, these collections aren’t saved to the user’s photos library and thus aren’t displayed in the Photos.app.

你可以通过 `PHAsset` 对象数组或携带资源的 `PHFetchResult` 对象来创建临时资源集合。创建的操作在 `PHAssetCollection` 的 `transientAssetCollectionWithAssets(...)` 和 `transientAssetCollectionWithFetchResult(...)` 工厂方法内都做了。这些方法创建出来的对象可以像其它的 `PHAssetCollection` 对象一样使用。尽管如此，这些集合不会被存储到用户照片库，自然也不会在照片应用中展示出来。

Similarly to asset collections, you can create transient collection lists by using the `transientCollectionListWithXXX(...)` factory methods on `PHCollectionList`.

和资源集合相似，你可以用 `PHCollectionList` 中的 `transientCollectionListWithXXX(...)` 工厂方法来创建临时集合列表。

This can turn out to be very useful when you need to combine results from two fetch requests.

当你要合并两个取回请求时，你就会发现这个东西非常有用。

<a name="Photo-metadata"></a>
## Photo Metadata
## 照片元数据

As mentioned in the beginning of this article, PhotoKit provides some additional metadata about user assets that wasn’t available (or at least not as easily available) in the past when using ALAssetsLibrary.

正如文章开头提到的，PhotoKit 提供了额外的关于用户资源的元数据，而这些数据在以前使用 ALAssetsLibrary 框架中是没有办法访问，或者很难访问到。

### HDR and Panorama Photos
### HDR 和全景照片

You can use a photo asset’s `mediaSubtypes` property to find out if the underlying image was captured with HDR enabled and whether or not it was shot in the Camera.app’s Panorama mode.

你可以使用照片资源的 `mediaSubtypes` 来验证资源库中的图像在捕捉时是否开启了 HDR，拍摄时是否有用相机应用的全景模式。

### Favorite and Hidden Assets
### 收藏和隐藏资源

To find out if an asset was marked as favorite or was hidden by the user, just inspect the `favorite` and `hidden` properties of the `PHAsset` instance.

要验证一个资源是否被用户标记为收藏或被隐藏，只要检查 `PHAsset` 实例的 `favorite` 和 `hidden` 属性。

### Burst Mode Photos
### 连拍模式照片

`PHAsset`’s `representsBurst` property is `true` for assets that are representative of a burst photo sequence (multiple photos taken while the user holds down the shutter). It will also have a `burstIdentifier` value which can then be used to fetch the rest of the assets in that burst sequence via `fetchAssetsWithBurstIdentifier(...)`.

对于一个资源，如果其 `PHAsset` 的 `representsBurst` 属性为 `true`，则表示这个资源是一系列连拍照片中具有代表性的一张（多张照片是在用户按住快门时拍摄的）。当然如果想要获取连拍照片中的剩余的其他照片，也可以通过 `fetchAssetsWithBurstIdentifier(...)` 方法，传入 `burstIdentifier` 值来获取。

The user can flag assets within a burst sequence; additionally, the system uses various heuristics to mark potential user picks automatically. This metadata is accessible via `PHAsset`’s `burstSelectionTypes` property. This property is a bitmask with three defined constants: `.UserPick` for assets marked manually by the user, `.AutoPick` for potential user picks, and `.None` for unmarked assets.

用户可以在连拍的照片中做标记；此外，系统也会自动用各种试探来标记用户可能会选择的潜在照片。这个元数据是可以通过 `PHAsset` 的 `burstSelectionTypes` 属性来访问。这个属性用三个常量组成的位掩码：`PHAssetBurstSelectionTypeUserPick ` 表示用户手动标记的资源，`PHAssetBurstSelectionTypeAutoPick ` 表示用户可能标记的潜在资源，`PHAssetBurstSelectionTypeNone ` 表示没有标记的资源。

<img src="http://img.objccn.io/issue-21/photos-burst-example.jpg" width="478" alt=".AutoPick Example">

The screenshot shows how Photos.app automatically marks potential user picks in a burst sequence.

这个屏幕快照显示了，照片应用是如何在连拍的照片中自动标记用户可能标记的潜在资源。

<a name="Photo-Loading"></a>
## Photo Loading
## 照片加载

Over the years of working with user photo libraries, developers created hundreds (if not thousands) of tiny pipelines for efficient photo loading and display. These pipelines dealt with request dispatching and cancelation, image resizing and cropping, caching, and more. PhotoKit provides a class that does all this with a convenient and modern API: `PHImageManager`.

在处理用户照片库的过去几年中，开发者创造了上百（如果没有上千）个微型管道来提高照片加载和展示的效率。这些管道处理请求的派发和取消，图像大小的修改和裁剪，缓存等等。PhotoKit 提供了一个可以用更加便捷和现代的 API 做了所有这些操作的类：`PHImageManager` 。

### Requesting Images
### 请求图像

Image requests are dispatched using the `requestImageForAsset(...)` method. The method takes in a `PHAsset`, desired sizing of the image and other options (via the `PHImageRequestOptions` parameter object), and a results handler. The returned value can be used to cancel the request if the requested data is no longer necessary.

图像请求是通过 `requestImageForAsset(...)` 方法派发的。这个方法在 `PHAsset` 内，可以设置返回图像的大小，图像的其它可选项（通过 `PHImageRequestOptions` 参数对象设置），以及 results handler。

#### Image Sizing and Cropping
#### 图像的尺寸定义和裁剪

Curiously, the parameters regarding the sizing and cropping of the result image are spread across two places. The `targetSize` and `contentMode` parameters are passed directly into the `requestImageForAsset(...)` method. The content mode describes whether the photo should be aspect-fitted or aspect-filled into the target size, similar to UIView’s `contentMode`. Note: If the photo should not be resized or cropped, pass `PHImageManagerMaximumSize` and `PHImageContentMode.Default`.

奇怪的是，对返回图像的尺寸定义和裁剪的参数是分布在两个地方的。`targetSize` 和 `contentMode` 这俩参数是被直接传入 `requestImageForAsset(...)` 方法内。这个 content Mode 和 UIView 的 `contentMode` 参数类似，决定了照片应该以合适的方式还是以填充满的方式放到目标大小内。注意：如果不对照片大小进行修改或裁剪，那么方法参数是 `PHImageManagerMaximumSize` 和 `PHImageContentModeDefault` 。

Additionally, `PHImageRequestOptions` provides means of specifying *how* the image manager should resize. The `resizeMode` property can be set to `.Exact` (when the result image must match the target size), `.Fast` (more efficient than .Exact, but the resulting image might differ from the target size), or `.None`. Furthermore, the `normalizedCroppingMode` property lets us specify how the image manager should crop the image. Note: If `normalizedcroppingMode` is provided, set `resizeMode` to `.Exact`.

此外，`PHImageRequestOptions` 还提供了一些方式来确定图像管理器该如何重新设置图像大小。`resizeMode` 属性可以设置为 `PHImageRequestOptionsResizeModeExact`（返回图像必须和目标大小相匹配），`PHImageRequestOptionsResizeModeFast`（比 PHImageRequestOptionsResizeModeExact 效率更高，但返回图像可能和目标大小不一样），`PHImageRequestOptionsResizeModeNone` 。还有个值得一提的是，`normalizedCroppingMode` 属性让我们确定图像管理器应该如何裁剪图像。注意：如果设置了 `normalizedcroppingMode` 的值，那么 `resizeMode` 需要设置为 `PHImageRequestOptionsResizeModeExact` 。

#### Request Delivery and Progress
#### 请求的移交和进展

By default, the image manager will deliver a lower-quality version of your image before delivering the high-quality version if it decides that’s the optimal strategy to use. You can control this behavior through the `deliveryMode` property; the default behavior described above is `.Opportunistic`. Set it to `.HighQualityFormat` if you’re only interested in the highest quality of the image available and if longer load times are acceptable. Use `.FastFormat` to load the image faster while sacrificing the quality.

默认情况下，如果图像管理器决定要用最优策略，那么它会在移交图像的高质量版本前，先移交一个较低质量的版本。你可以通过 `deliveryMode` 属性来控制这个行为；其默认行为的值为 `PHImageRequestOptionsDeliveryModeOpportunistic` 。如果你只想要高质量的图像，并且可以接受更长的加载时间，那么将属性设置为 `PHImageRequestOptionsDeliveryModeHighQualityFormat` 。如果你想要更快的加载速度，且可以牺牲一点图像质量，那么将属性设置为 `PHImageRequestOptionsDeliveryModeFastFormat` 。

You can make the `requestImage...` method synchronous using the `synchronous` property on `PHImageRequestOptions`. Note: When `synchronous` is set to `true`, the `deliveryMode` property is ignored and considered to be set to `.HighQualityFormat`.

你可以使用 `PHImageRequestOptions` 的 `synchronous` 属性，让 `requestImage...` 系列的方法可以支持同步操作。注意：当 `synchronous` 设为 `true` 时，`deliveryMode` 属性就会被忽略，并当成 `PHImageRequestOptionsDeliveryModeHighQualityFormat` 处理。

When setting these parameters, it is important to always consider that some of your users might have iCloud Photo Library enabled. The PhotoKit API doesn’t necessarily distinguish photos available on-device from those available in the cloud — they are all loaded using the same `requestImage` method. This means that every single one of your image requests may potentially be a slow network request over the cellular network. Keep this in mind when considering using `.HighQualityFormat` and/or making your requests synchronous. Note: If you want to make sure that the request doesn’t hit the network, set `networkAccessAllowed` to `false`.

在设置这些参数时，一定要考虑到你的一些用户有可能开启了 iCloud 照片库，这点非常重要。PhotoKit 的 API 不一定会对设备的照片和 iCloud 上照片进行区分 —— 它们都用同一个 `requestImage` 方法。这意味着任意一个图像请求都有可能是一个通过蜂窝网络来进行的非常缓慢的网络请求。当你要用 `PHImageRequestOptionsDeliveryModeHighQualityFormat` 或者做一个同步请求的时候，要牢记这个。注意：如果你想要确定请求是否有经过网络，将 `networkAccessAllowed` 设为 `false` 。

Another iCloud-related property is `progressHandler`. You can set it to a [PHAssetImageProgressHandler](https://developer.apple.com/library/ios/documentation/Photos/Reference/PHImageRequestOptions_Class/index.html#//apple_ref/doc/c_ref/PHAssetImageProgressHandler) block that will be called by the image manager when downloading the photo from iCloud.

另一个和 iCloud 相关的属性是 `progressHandler` 。你可以将它设到 [PHAssetImageProgressHandler](https://developer.apple.com/library/ios/documentation/Photos/Reference/PHImageRequestOptions_Class/index.html#//apple_ref/doc/c_ref/PHAssetImageProgressHandler) 的 block 上，当从 iCloud 下载照片时，它就会被图像管理器自动调用。

#### Asset Versions
#### 资源版本

PhotoKit allows apps to make non-destructive adjustments to photos. For edited photos, the system keeps a separate copy of the original image and the app-specific adjustment data. When fetching assets using the image manager, you can specify which version of the image asset should be delivered via the result handler. This is done by setting the `version` property: `.Current` will deliver the image with all adjustments applied to it; `.Unadjusted` delivers the image before any adjustments are applied to it; and `.Original` delivers the image in its original, highest-quality format (e.g. the RAW data, while `.Unadjusted` would deliver a JPEG).

PhotoKit 允许应用对照片进行无损的修改。编辑照片时，系统会对原始照片和修改的数据保存一份单独的拷贝。当用图像管理器取回资源时，你可以通过 result handler 来确定图像资源的哪个版本要被移交。通过设置 `version` 属性的值，这些操作就会自动完成：`PHImageRequestOptionsVersionCurrent` 会移交应用所有修改的图像；`PHImageRequestOptionsVersionUnadjusted` 会移交未应用任何修改的图像；`PHImageRequestOptionsVersionOriginal` 会移交原始的、最高质量的格式的图像（例如 RAW 格式的数据，当将属性设置为 `PHImageRequestOptionsVersionUnadjusted` 时，会移交图像的 JPEG 图像数据）。

You can read more about this aspect of the framework in Sam Davies' [article on Photo Extensions](http://www.objc.io/issue-21/photo-extensions.html).

你可以在 Sam Davies 的文章[《照片扩展》](http://objccn.io/issue-21-5/)中，浏览框架更多关于这方面的内容。

#### Result Handler
#### Result Handler

The result handler is a block that takes in a `UIImage` and an `info` dictionary. It can be called by the image manager multiple times throughout the lifetime of the request, depending on the parameters and the request options.

result handler 是一个包含了一个 `UIImage` 变量和一个 `info` 字典的 block。根据参数和请求的选项，在它请求的整个生命周期，可以被图像管理器多次调用。

The info dictionary provides information about the current status of the request, such as:

这个 `info` 字典提供了关于当前请求状态的信息，比如：

* Whether the image has to be requested from iCloud (in which case you’re going to have to re-request the image if you initially set `networkAccessAllowed` to `false`) — `PHImageResultIsInCloudKey`.
* Whether the currently delivered `UIImage` is the degraded form of the final result. This lets you display a preview of the image to the user while the higher-quality image is being downloaded — `PHImageResultIsDegradedKey`.
* The request ID (convenience for canceling the request), and whether the request has already been canceled — `PHImageResultRequestIDKey` and `PHImageCancelledKey`.
* An error, if an image wasn’t provided to the result handler — `PHImageErrorKey`.

* 图像是否必须从 iCloud 请求（在这种情况下，如果你初始化时将 `networkAccessAllowed` 设置成 `false`，那么必须重新请求图像）—— `PHImageResultIsInCloudKey` 。
* 当前移交的 `UIImage` 是否是最终结果的低质量格式。当高质量图像正在下载时，这个可以让你给用户先展示一个预览图像 —— `PHImageResultIsDegradedKey`。
* 请求 ID（可以便捷的取消请求），请求是否已经被取消 —— `PHImageResultRequestIDKey` 和 `PHImageCancelledKey`。
* 如果图像没有提供给 result handler，字典内还会有一个错误信息 —— `PHImageErrorKey`。

These values let you update your UI to inform your user and, together with the `progressHandler` discussed above, hint at the loading state of their images.

这些值可以让你更新你的 UI 来告知用户，和上面讨论到的 `progressHandler` 一起，推测出它们的加载状态。

### Caching
### 缓存

At times it’s useful to load some images into memory prior to the moment when they are going to be shown on the screen, for example when displaying a screen with a large number of asset thumbnails in a scrolling collection. PhotoKit provides a `PHImageManager` subclass that deals with that specific use case – `PHImageCachingManager`.

当图像即将要展示在屏幕上时，比如当要在一组滚动的 collection 视图上展示大量的资源图像的缩略图时，预先将一些图像加载到内存中有时是非常有用的。PhotoKit 提供了一个 `PHImageManager` 的子类来处理这种特定的使用场景 —— `PHImageCachingManager`。

`PHImageCachingManager` provides a single key method – `startCachingImagesForAssets(...)`. You pass in an array of `PHAssets`, the request parameters and options that should match those you’re going to use later when requesting individual images. Additionally, there are methods that you can use to inform the caching manager to stop caching images for a list of specific assets and to stop caching all images.

`PHImageCachingManager` 提供了一个单独的关键方法 —— `startCachingImagesForAssets(...)`。你传入一个 `PHAssets` 类型的数组，一些请求参数，以及一些请求单个图像时即将用到的可选项。此外，还有一些方法可以让你通知缓存管理器来停止缓存特定资源列表，以及停止缓存所有图像。

The `allowsCachingHighQualityImages` property lets you specify whether the image manager should prepare images at high quality. When caching a short and unchanging list of assets, the default `true` value should work just fine. When caching while quickly scrolling in a collection view, it is better to set it to `false`.

`allowsCachingHighQualityImages` 属性可以让你明确图像管理器是否应该准备高质量图像。当缓存较短和不变的资源列表时，默认 `true` 的属性可以正常运行。当要在 collection 视图上快速滑动时做缓存操作，最好将属性设置成 `false` 。

Note: In my experience, using the caching manager can be detrimental to scrolling performance when the user is scrolling extremely fast through a large asset collection. It is extremely important to tailor the caching behavior for the specific use case. The size of the caching window, when and how often to move the caching window, the value of the `allowsCachingHighQualityImages` property — these parameters should be carefully tuned and the behavior tested with a real photo library and on target hardware. Furthermore, consider setting these parameters dynamically based on the user’s actions.

注意：以我的经验，当用户正在有大量资源的 collection 视图上极其快速的滑动时，使用缓存管理器会损害滑动的表现效果。为这种特定的使用场景定制一个缓存行为是极其重要的。缓存窗口的大小，移动缓存窗口的时机和频率，`allowsCachingHighQualityImages` 的属性值 —— 这些参数都要在目标硬件上的真实照片库中仔细地调节，并测试表现效果。而且，你应该考虑在用户行为的基础上，动态的设置这些参数。

### Requesting Image Data
### 请求图像数据

Finally, in addition to requesting plain old `UIImages`, `PHImageManager` provides another method that returns the asset data as an `NSData` object, its universal type identifier, and the display orientation of the image. This method returns the largest available representation of the asset.

最后，除了请求普通的老 `UIImage` 之外，`PHImageManager` 提供了另一个方法可以返回 `NSData` 对象类型的资源数据，它的通用类型标识符，图像的展示方向。这个方法返回了最大可用的资源代表。

<a name="The-Times-They-Are-A-Changin"></a>
## The Times They Are A-Changin'
## The Times They Are A-Changin'

We have discussed requesting metadata of assets in the user’s photo library, but we haven’t covered how to keep our fetched data up to date. The photo library is essentially a big bag of mutable state, and yet the photo entities covered in the first section are immutable. PhotoKit lets you receive notifications about changes to the photo library together with all the information you need to correctly update your cached state.

我们已经讨论了在用户照片库中请求资源的元数据，但是到目前为止，我们没提及如何保存我们取回的数据。照片库本质上是一个可变状态的大包裹，而第一节中提到的照片实体是不可变的。PhotoKit 让你接收你需要的、关于照片库变动的所有信息，以正确更新你的缓存状态。

### Change Observing
### 变化观察

First, you need to register a change observer (conforming to the `PHPhotoLibraryChangeObserver` protocol) with the shared `PHPhotoLibrary` object using the `registerChangeObserver(...)` method. The change observer's `photoLibraryDidChange(...)` method will be called whenever another app or the user makes a change in the photo library **that affects any assets or collections that you fetched prior to the change**. The method has a single parameter of type `PHChange`, which you can use to find out if the changes are related to any of the fetched objects that you are interested in.

首先，你需要通过共享的 `PHPhotoLibrary` 对象，用 `registerChangeObserver(...)` 方法注册一个变化观察者（遵从 `PHPhotoLibraryChangeObserver` 协议）。无论另一个应用或者用户在照片库中做了个修改，**影响了你在变化前取回的任何资源或资源集合**，变化观察者的 `photoLibraryDidChange(...)` 方法都会被调用。这个方法只有一个单独的 `PHChange` 类型的参数，你可以用它来验证变化是否和你取回的并感兴趣的对象有关联。

### Updating Fetch Results
### 更新取回的结果

`PHChange` provides methods you can call with any `PHObject`s or `PHFetchResult`s whose changes you are interested in tracking – `changeDetailsForObject(...)` and `changeDetailsForFetchResult(...)`. If there are no changes, these methods will return `nil`, otherwise you will be vended a `PHObjectChangeDetails` or `PHFetchResultChangeDetails` object.

`PHChange` 提供了几个方法，让你可以调用任何 `PHObject` 对象或 `PHFetchResult` 对象来追踪你想感兴趣的变化 —— `changeDetailsForObject(...)` 和 `changeDetailsForFetchResult(...)` 。如果没有任何变化，这些方法会返回 `nil` ，否则你可以借助 `PHObjectChangeDetails` 或 `PHFetchResultChangeDetails` 对象来观察这些变化。

`PHObjectChangeDetails` provides a reference to an updated photo entity object, as well as boolean flags telling you whether the object’s image data was changed and whether the object was deleted.

`PHObjectChangeDetails` 提供了一个对最新的照片实体对象的引用，以及一个告诉你对象的图像数据是否曾变化过、对象是否曾被删除过的布尔值。

`PHFetchResultChangeDetails` encapsulates information about changes to a `PHFetchResult` that you have previously received after a fetch. `PHFetchResultChangeDetails` is designed to make updates to a collection view or table view as simply as possible. Its properties map exactly to the information you need to provide in a typical collection view update handler. Note that to update `UITableView`/`UICollectionView` correctly, you must process the changes in the correct order: **RICE** – **r**emovedIndexes, **i**nsertedIndexes, **c**hangedIndexes, **e**numerateMovesWithBlock (if `hasMoves` is `true`). Furthermore, the `hasIncrementalChanges` property of the change details can be set to `false`, meaning that the old fetch result should just be replaced by the new value as a whole. You should call `reloadData` on your `UITableView`/`UICollectionView` in such cases.

`PHFetchResultChangeDetails` 包含了在一次取回操作后，和之前接收到的 `PHFetchResult` 对比变化的信息。`PHFetchResultChangeDetails` 是为了尽可能简化 CollectionView 或 TableView 的更新操作而设计。它的属性恰好映射到你需要的对应信息，以提供给典型的 CollectionView 的 update handler。注意，若要正确的更新 `UITableView`/`UICollectionView`，你必须以正确顺序来处理变化：**RICE** —— **r**emovedIndexes, **i**nsertedIndexes, **c**hangedIndexes, **e**numerateMovesWithBlock（如果 `hasMoves` 为 `true`）。而且，`PHFetchResultChangeDetails` 的 `hasIncrementalChanges` 属性可以被设置成 `false`，意味着旧的获取结果应该全部被新的值代替。这种情况下，你应该在 `UITableView/UICollectionView` 调用 `reloadData` 。

Note: There is no need to make change processing centralized. If there are multiple components of your application that deal with photo entities, then each of them could have its own `PHPhotoLibraryChangeObserver`. The components can then query the `PHChange` objects on their own to find out if (and how) they need to update their own state.

注意：没有必要集中处理变化。如果你应用中的多个组件需要处理照片实体，那么它们每个都要有自己的 `PHPhotoLibraryChangeObserver` 。接着组件就能靠自己查询 `PHChange` 对象，检测是否需要（以及如何）更新它们自己的状态。

<a name="Wind-of-Change"></a>
## Wind of Change
## Wind of Change（歌名）

Now that we know how to observe changes made by the user and other applications, we should try making our own!

既然我们知道了如何观察用户和其他应用造成的变化，我们就试一下自己来做。

### Changing Existing Objects
### 对象中的变化

Performing changes on the photo library using PhotoKit boils down to creating a change request object linked to one of the assets or asset collections and setting relevant properties on the request object or calling appropriate methods describing the changes you want to commit. This has to happen within a block submitted to the shared `PHPhotoLibrary` via the `performChanges(...)` method. Note: You should be prepared to handle failure in the completion block passed to the `performChanges` method. This approach provides safety and relative ease of use, while working with state that can be changed by multiple actors, such as your application, the user, other applications, and photo extensions.

用 PhotoKit 在照片库做到的变化，说到底其实是先创建了一个链接到某个资源或者资源集合的变化请求对象，再设置请求对象的相关属性或调用合适的方法来描述你想要提交的变化。这个必须通过 `performChanges(...)` 方法，在提交到共享的 `PHPhotoLibrary` 的 block 内完成。注意：你需要准备好处理 `performChanges` 方法上的 completion block 失败的情况。当处理能被多个参与者（如你的应用，用户，其他应用，照片扩展等）改变的状态时，这个基本能提供安全和相对的易用。

To modify assets, create a [`PHAssetChangeRequest`](https://developer.apple.com/library/ios/documentation/Photos/Reference/PHAssetChangeRequest_Class/index.html#//apple_ref/occ/cl/PHAssetChangeRequest). You can then modify the creation date, the asset’s location, and whether or not it should be hidden and considered a user’s favorite. Additionally, you can delete the asset from the user’s library.

若想要修改资源，则需创建一个 [`PHAssetChangeRequest`](https://developer.apple.com/library/ios/documentation/Photos/Reference/PHAssetChangeRequest_Class/index.html#//apple_ref/occ/cl/PHAssetChangeRequest) 。然后你就可以修改创建创建日期，资源位置，以及是否将隐藏资源，是否将资源看做用户收藏。此外，你还可以从用户的库里删除资源。

Similarly, to modify asset collections or collection lists, create a [`PHAssetCollectionChangeRequest`](https://developer.apple.com/library/ios/documentation/Photos/Reference/PHAssetCollectionChangeRequest_Class/index.html#//apple_ref/occ/cl/PHAssetCollectionChangeRequest) or a [`PHCollectionListChangeRequest`](https://developer.apple.com/library/ios/documentation/Photos/Reference/PHCollectionListChangeRequest_Class/index.html#//apple_ref/occ/cl/PHCollectionListChangeRequest). You can then modify the collection title, add or remove members of the collection, or delete the collection altogether.

类似的，若要修改资源集合或集合列表，需要创建一个 [`PHAssetCollectionChangeRequest`](https://developer.apple.com/library/ios/documentation/Photos/Reference/PHAssetCollectionChangeRequest_Class/index.html#//apple_ref/occ/cl/PHAssetCollectionChangeRequest) 或 [`PHCollectionListChangeRequest`](https://developer.apple.com/library/ios/documentation/Photos/Reference/PHCollectionListChangeRequest_Class/index.html#//apple_ref/occ/cl/PHCollectionListChangeRequest) 对象。然后你就可以修改集合标题，添加或删除集合成员，或者完全删除集合。

Note that before your changes are committed to the user’s library, an alert might be shown to acquire explicit authorization from the user.

在你的变化提交到用户库前，会给用户展示一个明确的获取权限的警告框。

### Creating New Objects
### 创建新对象

Creating new assets is done similarly to changing existing assets. Just use the appropriate `creationRequestForAssetFromXXX(...)` factory method when creating the change request, and pass the asset image data (or a URL) into it. If you need to make additional changes related to the newly created asset, you can use the creation change request’s `placeholderForCreatedAsset` property. It returns a placeholder that can be used in lieu of a reference to a “real” `PHAsset`.

创建一个新资源的做法和修改已存在的资源类似。只要用 `creationRequestForAssetFromXXX(...)` 方法，在创建变化请求，传入资源图像数据（或一个 URL）时，使用合适的工厂方法即可。如果你需要对新建的资源做额外的修改，你可以用创建变化请求的 `placeholderForCreatedAsset` 属性。它会返回一个可用的 placeholder 来代替“真实的” `PHAsset` 引用。

## Conclusion
## 结论

We have discussed the basics of PhotoKit, but there is still a lot to be discovered. You should learn more by [poking around the sample code](https://developer.apple.com/library/ios/samplecode/UsingPhotosFramework/Introduction/Intro.html#//apple_ref/doc/uid/TP40014575), watching the [WWDC session](https://developer.apple.com/videos/wwdc/2014/?id=511) video, and just diving in and writing some code of your own! PhotoKit enabled a new world of possibilities for iOS developers, and we are sure to see more creative and clever products built on its foundation in the coming months and years.

我已经讨论了 PhotoKit 的基础知识，但仍然还有非常多的东西等着我们去发掘。你可以通过[查看示例的各处的代码](https://developer.apple.com/library/ios/samplecode/UsingPhotosFramework/Introduction/Intro.html#//apple_ref/doc/uid/TP40014575)，观看 [WWDC session](https://developer.apple.com/videos/wwdc/2014/?id=511) 视频学习更多内容，发掘更深的知识，然后写一些自己的代码！PhotoKit 为开发者开启了通往新世界可能性，在未来的数月或者数年里，我们确定会看到更多基于这个基础建造的富有创造性的和优秀的产品。
