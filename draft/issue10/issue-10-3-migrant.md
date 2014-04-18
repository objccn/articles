---
layout: post
title:  "精通iCloud文档存储"
category: "10"
date: "2014-03-07 09:00:00"
tags: article
author: "<a href=\"https://twitter.com/hdrxs\">Friedrich Gräter</a> & <a href=\"http://twitter.com/macguru17\">Max Seelemann</a>"
---

Even three years after its introduction, the iCloud document store is still a topic full of myth, misunderstanding, and resentment. iCloud synching has often been criticized for being unreliable or slow. And while there were imminent bugs in the early days of iCloud, application developers had to learn their lessons about file synchronization, too. File synchronization is non-trivial and brings new aspects to application development — aspects which are often underestimated, such as the requirement to handle asynchronous file changes while being cooperative regarding synchronization services.

即便在推出3年后，iCloud 文档存储依然是一个充满神秘、误解和抱怨的话题。iCloud 同步经常被批评不可靠且速度慢。虽然在 iCloud 的早期有一些紧迫的 bug，开发者们还是不得不学习有关文件同步的课程。文件同步事关重大，为应用开发带来了新方向 -- 一个经常被低估的方向，比如进行同步服务相关的合作时，对于处理文件异步更改的需要。

This article will give an overview of several common stumbling stones you may find when creating an iCloud-ready application. In case you are not already familiar with the iCloud document store, we strongly recommend reading the [Apple iCloud companion guide][1] first, since this article provides only a rough overview.

本文会介绍几个创建支持 iCloud 的应用时可能会遇到的一些绊脚石。因为本文只会给出一些粗略的概述，所以如果你对 iCloud 文档存储还不熟悉，我们强烈建议你先阅读 [Apple iCloud companion guide](https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesigningForDocumentsIniCloud.html)。

## The Document Store in a Nutshell
## 文档存储简介

The core idea of the iCloud document store is pretty simple: every application has access to at least one 'magic folder' where it can store files that are then being synchronized across all devices subscribing to the same iCloud account.

iCloud 文档存储的核心思想非常简单: 每个应用都有至少通往一个"魔法文件夹"的入口，该文件夹可以存储文件并且随后在所有注册了同一个 iCloud 帐号的设备间同步。

In contrast to other file-based syncing services, the iCloud document store benefits from a deep integration with OS X and iOS. Many system frameworks have been extended to support iCloud. Classes like `NSDocument` and `UIDocument` have been designed to deal with external changes. Synchronization conflicts are handled by the Version Store and `NSFileVersion`. Spotlight is employed to provide synchronization metadata like the progress of file transfers or the availability of documents in the cloud.

与其他基于文件系统的同步服务相比，iCloud 文档存储得益于与OS X和iOS的深度整合。很多系统框架已经被扩展以支持 iCloud。像 `NSDocument` 和 `UIDocument` 这样的类被设计为处理外部变化。版本存储和 `NSFileVersion` 处理同步冲突。Spotlight 被用来提供同步元数据，比如文件传输进度或者云端文档可用性。

It does not take much to write a simple, document-based, iCloud-enabled application on OS X. Actually, you don’t need to care about any of the inner workings of iCloud, as `NSDocument` delivers almost everything for free: it coordinates document accesses with iCloud, automatically watches for external changes, triggers downloads, and handles conflicts. It even provides a simple user interface for managing cloud documents through the default open panel. All you need to do is to be a good `NSDocument` subclass citizen and to implement the required methods for reading and writing file contents.

写一个简单的基于文档并开启了 iCloud 的 OS X 应用并不需要费多大力气。实际上你并不需要关心任何 iCloud 内部的工作，`NSDocument` 无偿的做了几乎每件事情: 协调文档的iCloud访问，自动观察外部变化，触发下载，处理冲突。它甚至提供了一个简单的UI界面来管理云文档。你需要做的所有事情就是创建一个 `NSDocument` 子类并实现读取和写入文档内容所需要的方法。

![NSDocument provides a simple user interface for managing the synchronized documents of an app.][image-1]
![NSDocument provides a simple user interface for managing the synchronized documents of an app.](http://www.objccn.io/images/issue-10/Open.png)

However, as soon as you leave the predefined path, you have to know a lot more. For example, everything beyond the single-level folder hierarchy provided by the default open panel has to be done manually. Maybe your application needs to manage its documents beside the documents contents, like it is done in Mail, iPhoto, or [Ulysses][2] (our own app). In these cases, you cannot rely on `NSDocument` and need to implement its functionality on your own. But for that you have to have a deep understanding of the locking and notification mechanisms employed by iCloud.

然而，一旦脱离预设的路径，你就需要了解的更多。例如，默认打开面板提供的单层文件夹以外的任何操作都需要手动完成。可能你的应用需要管理在 Mail，iPhoto 或者 [Ulysses](http://www.ulyssesapp.com/) (我们自己的app)中创建的这些文档内容以外的文档。这种时候，你不能依赖于 `NSDocument`，而需要自己实现它的功能。但为此你需要对iCloud提供的锁和通知机制有一个深入的了解。

Developing iCloud-ready apps for iOS also requires more work and knowledge; while `UIDocument` still manages file access with iCloud and handles synchronization conflicts, it lacks any user interface for managing documents and folders. For performance and storage reasons, iOS does also not automatically download new documents from the cloud. Instead, you need to query for recent changes of the directory using Spotlight and trigger downloads manually.

开发支持iCloud的iOS应用同样需要更多的工作和知识;虽然 `UIDocument` 仍然管理 iCloud 文件访问和处理同步冲突，但缺乏管理文档和文件夹的图形界面。因为性能和存储空间的原因，iOS 也不会自动从云端下载新文档。你需要使用Spotlight来检索最近变化的目录并手动触发下载。

## What’s in a Ubiquity Container?
## 什么是开放性容器

Any application that is eligible for App Store provisioning can use the iCloud document store. After setting the correct [entitlements][3], it gains access to one or multiple so-called 'ubiquity containers.' This is Apple slang for “a directory that is managed and synced by iCloud.” Each ubiquity container is bound to an application identifier, resulting in one shared storage per user per app. Developers who have multiple apps may specify multiple app identifiers (of the same team), and by that gain access to multiple containers.

任何符合 App Store 条件的应用都可以使用 iCloud 文档存储。设置正确的[授权](https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html#//apple_ref/doc/uid/TP40012094-CH6-SW13)后，就获得了一个或多个所谓的"开放性容器"的访问权限。这是苹果用来称呼"一个被 iCloud 管理和同步的目录"的俚语。每一个开放性容器限定在一个应用标识内，由此让每个用户在每个应用中有一份共享的存储仓库。有多个应用的开发者可以指定多个应用标识(同一个团队)，由此可以进入多个容器。

`NSFileManager` provides the URL of each container through [`URLForUbiquityContainerIdentifier:`][4]. On OS X, it is possible to inspect all available ubiquity containers by opening the directory `~/Library/Mobile Documents`.

`NSFileManager` 通过 [URLForUbiquityContainerIdentifier:](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/nsfilemanager_class/reference/reference.html#//apple_ref/occ/instm/NSFileManager/URLForUbiquityContainerIdentifier:) 提供每一个容器的 URL。在 OS X 系统，可以通过打开 `~/Library/Mobile Documents` 目录来查看所有可用的开放性容器。

![The contents of ”~/Library/Mobile Documents.“ It contains a separate folder for each ubiquity container of each application.][image-2]
![The contents of ”~/Library/Mobile Documents.“ It contains a separate folder for each ubiquity container of each application.](http://www.objccn.io/images/issue-10/Mobile%20Documents.png)

Typically, there are two processes concurrently accessing each ubiquity container. First, there is the application that is presenting and manipulating the documents inside the container. Second, there is the infrastructure of iCloud, which is mostly represented through the Ubiquity Daemon (*ubd*). The iCloud infrastructure waits for changes performed by the application and uploads them to Apple’s cloud servers. It also waits for incoming changes on iCloud and may modify the contents of the ubiquity container accordingly.

通常每个开放性容器有两个并发进程访问。首先，有一个应用呈现和操作容器内的文档。第二，有一个主要通过 Ubiquity Daemon (*ubd*) 体现的 iCloud 基础设施。iCloud 基础设施等待应用对文档的更改并将其上传至苹果云服务器。同时也等待 iCloud 上即将到来的更改并相应修改容器的内容。

Since both entities are working completely independent from one another, some kind of arbitration is needed to prevent race conditions or lost updates on files inside the container. To guarantee access to an isolated file, applications need to use a concept called [*file coordination*][5] for every access. This access is provided by the [`NSFileCoordinator`][6] class. In a nutshell, it provides a simple reader-writer lock for files. This lock is extended by a notification mechanism that is supposed to improve cooperation across different processes accessing the same files.

由于两个进程完全独立于彼此工作，因此需几种仲裁来避免资源竞争或丢失容器内的文件更新。应用需要使用名为 [*文件协调*](https://developer.apple.com/library/ios/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileCoordinators/FileCoordinators.html#//apple_ref/doc/uid/TP40010672-CH11-SW1) 的概念来确保对于每一个独立文件的访问权。该访问权由 [`NSFileCoordinator`](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFileCoordinator_class/Reference/Reference.html) 类提供。概括来说，它为每个文件提供了一个简单的 读-写 锁。这个锁由一个通知机制扩展，该机制用于用于改善访问同一个文件的不同进程间的合作。

This notification mechanism is an essential advantage over simple file locks and allows for a seamless user experience. iCloud may replace a document by a new version from another device at any time. If an application is currently showing the same document, it must load the new version from disk and show the updated contents to the user. During the update, the application may need to lock the user interface for a while and enable it again afterward. Even worse scenarios may happen: the application may hold unsaved contents, which need to be saved to disk *first* in order to detect synchronization conflicts. Finally, iCloud may be interested in uploading the most recent version of a file if good network conditions are available. Thus, it must be able to query an application to flush all unsaved changes immediately.

这个通知机制是简单文件锁的主要好处，并且提供了无缝的用户体验。iCloud 可能会在任何时间把文档用一个来自其他设备的新版本覆盖。如果一个应用当前正在显示同一个文档，它必须从磁盘加载新版本并向用户展示更新过的内容。更新过程中，应用可能需要锁住用户界面一段时间并随后在此打开。甚至可能发生更坏的情况: 应用可能保留着未保存的内容，这些内容需要 *先* 保存到磁盘上以便检查同步冲突。最后，在网络条件良好的时候 iCloud 会上传文件最近的版本。因此必须能够查询应用来立刻保存未保存的内容。

For these negotiations, file coordination is accompanied by another mechanism called *file presentation*. Whenever an application opens a file and shows it to the user, it is said to be *presenting the document* and should register an object implementing the [`NSFilePresenter`][7] protocol. The file presenter receives notifications about the presented file whenever another process accesses it through a file coordinator. These notifications are delivered as method calls, which are performed asynchronously on an operation queue specified by the presenter ([`presentedItemOperationQueue`][8]).

对于这些讨论，文件协调伴随着一个名为 *文件描述(file presentation)* 的机制。打开并向用户展示一个文件，被称作 *描述* 文档，并且应该注册一个实现了 [`NSFilePresenter`](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html) 协议的对象。只要另一个进程通过一个文件协调访问文件，文件描述者(file presenter)就会收到关于该文件的通知。这些通知被作为方法调用传递，这些方法在描述者指定的一个操作队列([`presentedItemOperationQueue`](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfp/NSFilePresenter/presentedItemOperationQueue))中异步执行。

For example, before any other process is allowed to start a coordinated read operation, the file presenter will be asked to persist any unsaved changes. This is done by dispatching a block on its presentation queue calling the method [`savePresentedItemChangesWithCompletionHandler:`][9]. The presenter may then save the file and confirm the notification by executing a block that has been passed as argument to the notification handler. Aside from change notifications, file presenters are also used to notify the application on synchronization conflicts. Whenever a conflicting version of a file has been downloaded, a new file version is added to the Versions store. All presenters are notified that a new version has been created through [`presentedItemDidGainVersion:`][10]. This callback receives an `NSFileVersion` instance referencing potential conflicts.

例如，在任何其他线程被允许开始一个读取操作前，文件描述者被要求保存任何未保存的变化。这些操作通过分发一个 block 到它的描述队列执行 [`savePresentedItemChangesWithCompletionHandler:`](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfm/NSFilePresenter/savePresentedItemChangesWithCompletionHandler:) 来完成。描述器可以保存文件并通过执行作为参数传入的 block 来确认通知。除了改变通知，文件描述者还用来通知应用同步冲突。一旦一个文件的冲突版本被下载，一个新的文件版本被加入到版本存储里。所有的描述者通过 [`presentedItemDidGainVersion:`](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfm/NSFilePresenter/presentedItemDidGainVersion:) 被通知有一个新版本被创建。该回调接收一个引用了潜在冲突的 `NSFileVersion` 实例。

File presenters can be also used if your application needs to monitor folder contents. For instance, whenever iCloud is changing the contents of a folder, e.g. by creating, deleting, or moving files, the application should be notified to update its documents overview. For this purpose, the application can register an instance implementing the `NSFilePresenter` protocol for a presented directory. A file presenter on a directory will be notified of any changes in the folder or any files nested to it or to its subfolders. For example, if a file inside the folder has been modified, the presenter will receive a `presentedSubitemDidChangeAtURL:` notification referencing the URL of the modified file. 

文件描述者还可以被用来监视文件夹内容。例如，一旦 iCloud 改变文件夹内容，如创建，删除或者移动文件，应用应该被通知到以便更新它的文档展示。为此，应用可以对展示的目录注册一个实现了 `NSFilePresenter` 协议的实例。一个目录的文件描述者会被任何文件夹或其中文件或子文件夹的改变所通知。比如一个文件夹内的文件被修改，描述者会收到一个引用了该文件的 URL 的 `presentedSubitemDidChangeAtURL:` 通知。

Since bandwidth and battery life are much more limited on mobile devices, iOS will not download new files automatically from iCloud. Instead, applications must decide manually when to trigger downloads of new files to the ubiquity container. To continue providing the application an overview of which files are available, as well as their current synchronization status, iCloud also synchronizes metadata for files inside the ubiquity container. An application may query this metadata by using an `NSMetadataQuery` or by accessing the ubiquity resource attributes of `NSURL`. Whenever the application wants to get access to a file’s contents, it must trigger a download explicitly through `NSFileManager`’s  [`startDownloadingUbiquitousItemAtURL:error:`][11].

因为带宽和电池寿命在移动设备上更加有限，iOS 不会自动从 iCloud 下载新文件。而是由应用手动决定何时来触发下载新文件到开放性容器中。为了持续告知应用哪些文件可用及其同步状态，iCloud 还会同步开放性容器内的文件元信息。应用可以通过 `NSMetadataQuery` 或访问 `NSURL` 的开放资源属性查询这些元信息。无论何时应用想要访问一个文件，它一定会通过 [`startDownloadingUbiquitousItemAtURL:error:`](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/nsfilemanager_class/reference/reference.html#//apple_ref/occ/instm/NSFileManager/startDownloadingUbiquitousItemAtURL:error:) 触发下载行为。

## Inside the Depths of iCloud
## 深入 iCloud

Instead of continuing to explain how to implement file coordination and observation, we will now dive into common problems we have encountered over the last few years. Again, please make sure you have read and understood the [Apple iCloud companion guide][12] for documents in the cloud.

在继续结实如何实现文件协调并观察之前，现在我们将深入一些过去几年里碰到的一些常见问题。再一次的，确保你已经阅读并理解了 [Apple iCloud companion guide](https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesigningForDocumentsIniCloud.html)。

While the description of those file mechanisms makes their use sound pretty straightforward, there are many hidden pitfalls. And some of these pitfalls originate from bugs inside the underlying frameworks. Since iCloud syncing is spread on quite a few levels of the operating system, one can expect that Apple will be fixing bugs very carefully. Actually, Apple even seems to prefer deprecating broken APIs over providing bug fixes.

虽然这些文件机制的描述让它们的使用看起来简单明了，但其实其中有很多隐藏的陷阱。这些陷阱中有些来自于底层框架的 bug。因为 iCloud 同步延伸到操作系统中相当多的层面，人们只能寄希望于苹果能够小心的修复这些 bug。实际上，苹果看起来宁愿废弃坏掉的 API 而不是修复它们。

Even so, it’s our experience that it is also very, very easy to make mistakes. The asynchronous, cooperative, and lock-based nature of file coordination and file presentation has implications that are often not easy to grasp. In the following, we would like to share our experiences in the form of a couple of general rules to follow when manually integrating iCloud document syncing.

即便如此，我们的经验告诉我们非常非常容易犯错误。异步，协作，文件协调基于锁的特性和文件描述并不容易掌握。下面，我们将介绍整合 iCloud 文档同步时的一些主要规则，并以这种形式分享我们的经验。

### Use Presenters only when Necessary

File presenters can be very expensive objects. They should only be used if your application needs to be able to react to or intervene in external file accesses immediately.

文件展描述者代价高昂。仅当你的应用需要立即应对或干预文件访问的时候，才应该使用它。

If your application is currently presenting something like a document editor to the user, file presentation is adequate. In this case, your application may need to lock the editor while other processes are writing, or it may need to flush any unsaved changes to disk. However, if only temporary access is needed and notifications may be processed lazily, your application should not use file presentation. For instance, when indexing a file or creating a thumbnail, watching change dates and using simple file coordination will probably be sufficient. Also, if you are presenting the contents of a directory tree, it may be completely sufficient to register a *single* presenter at the root of the tree or to use an `NSMetadataQuery` to be lazily notified of any changes.

如果你的应用正在展示类似文档编辑器这样的东西给用户，文件描述足以胜任。这时，在其他进程写入该文件的时候也许需要锁住编辑器，或者还需要保存未保存的改变。然而，如果只是临时访问并且通知也可能会被延迟处理，就不应该使用文件描述。例如，当创建文件索引或缩略图，查看文件更改日期并使用简单的文件协调可能会更高效。另外，如果你正展示一个字典树的内容，在树的根节点注册 *一个* 描述者或用 `NSMetadataQuery` 来延迟获取改变通知会可能会非常高效。

What makes file presentation so expensive? Well, it requires a lot of interprocess communication: each file presenter registered to a file must be asked to relinquish the presented file before other processes get access to that file. For example, if another process tries to read a certain file, its presenters will be asked to save all unsaved changes ([`savePresentedItemChangesWithCompletionHandler:`][13]). They are also asked to relinquish the file to the reader ([`relinquishPresentedItemToReader:`][14]), e.g. to temporary lock editors while the file is read.

是什么让文件描述代价如此高昂？它需要很多的进程间通信: 每个文件上注册的描述者在其他进程获取文件的访问权时都被要求释放该文件。比如另一个进程尝试读取一个文件，该文件的描述者会被要求保存所有未保存的内容 [`savePresentedItemChangesWithCompletionHandler:`](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfm/NSFilePresenter/savePresentedItemChangesWithCompletionHandler:)。它们还会被要求释放文件给读取者([`relinquishPresentedItemToReader:`](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfm/NSFilePresenter/relinquishPresentedItemToReader:))，例如文件被读取时暂时锁住编辑器。

Each of these notifications need to be dispatched, processed, and confirmed by their respective receivers. And since only the implementing process knows which notifications will be handled, interprocess communication will happen for every possible notification, even if a presenter does not implement any of those methods.

这些通知每一个都需要分发，加工并由各自的接受者确认。并且因为只有当前进程知道哪些通知会被处理，所以即使描述者没有实现任何方法，进程间也会为每一个可能的通知进行通信。

Additionally, multiple context switches between the reading process, the presenting process, and the file coordination daemon (`filecoordinationd`) are required for each step. As a result, a simple file access can quickly become a very expensive operation.

另外，每个步骤都需要读取进程，描述进程和文件协调守护进程(`filecoordinationd`)间的多重上下文的切换。结果就导致了一个简单的文件访问很快就变成耗费资源的操作。

On top of all that, the file coordination daemon can deplete critical system resources if too many presenters have been registered. For each presenter, it needs to open and observe every folder on the path of the presented item. Especially on OS X Lion and iOS 5, these resources were very scarce, and an overuse could easily have led to a full lockdown or crash of the file coordination daemon.

除此之外，如果太多的描述者被注册，文件协调守护进程能删除重要的系统资源。对于每一个描述者，都需要打开并监听每一个它所描述的路径上的文件夹。尤其在 OS X Lion 和 iOS 5 上，这些资源是非常稀少的，过渡的使用很容易导致文件协调守护进程的锁死或崩溃。

For these reasons, we strongly recommend not adding file presenters on every node inside a directory tree, rather only using as few file presenters as needed.

基于这些原因，我们强烈建议不要在目录树的每一个节点上增加文件描述器，只根据需要使用最少的文件描述器。

### Use Coordination only if Necessary
### 只在需要时使用协调

While file coordination is way cheaper than file presentation, it still adds an additional overhead to your application and to the entire system.

虽然文件协调要比文件描述节约资源，但它仍然给你的应用和整个系统增加额外的负担。

Whenever your application is coordinating a file access, other processes trying to access the same file at the same time may need to wait. Therefore, you should never perform any lengthy task while coordinating a file. If you are, for instance, saving large files, you may consider saving them to a temporary folder first and then just swizzling hard links during a coordinated access. Keep in mind that every coordinated access may trigger a file presenter inside another process — a presenter that may need time to update the file in advance to your access. Always consider the usage of flags like `NSFileCoordinatorReadingWithoutChanges` if it’s not required to read the most recent version of a file. 

每当你的应用正在协调一个文件，其他同时想要访问同一个文件的进程可能需要等待。因此你不该在协调文件时执行过于耗时的任务。如果你这么做了，比如存储了大文件，你可以考虑将它存储到一个临时文件夹，随后在协调访问时使用硬连接。注意每一个协调的访问都可能会触发另一个进程上的文件描述者 -- 该描述者可能需要时间在你的访问之前更新文件。始终考虑使用诸如 `NSFileCoordinatorReadingWithoutChanges` 这样的标识，除非需要读取文件的最新版本。

While the ubiquity container of your app will probably not be accessed by other applications, exaggerated file coordination may still become a problem with iCloud, and performing many coordination requests may lead to a starvation of system processes like `ubd`. During the startup phase of an application, `ubd` seems to scan through all files inside your ubiquity container. If your application is performing the same scan during program startup, both processes may often collide, which may lead to a high coordination overhead. It’s wise to consider more optimistic approaches in this case. For example, when scanning directory contents, isolated access to a file’s contents may not be required at all. Instead, defer the coordination until the file’s contents are actually being presented.

虽然你的应用的开放性容器可能不会被其他应用访问，过大的文件协调仍然可能成为 iCloud 的一个问题，执行太多的类似 `ubd` 的协调请求会导致系统资源枯竭。在应用启动阶段，`ubd` 似乎会扫描开放性容器内的所有文件。如果你的应用在程序启动阶段也在执行相同的扫描。两个进程会经常冲突，从而可能导致协调的高开销。这时考虑更优化的解决方案是明智的。例如扫描目录内容时，单独的文件内容访问权限是根本不需要的。延迟处理协调，直到文件内容真正被展示。

Finally, never coordinate a file that has not been downloaded yet. File coordination will trigger the downloading of files. Unfortunately, the coordination will wait until the download has been completed, which may block an application for an incalculable period of time. Before accessing a file, an app should verify the file’s download state. You can do this by querying the URL’s resource value `NSURLUbiquitousItemDownloadingStatusKey` or using an `NSMetadataQuery`.

最后，绝对不要协调一个还没有被下载的文件。文件协调会触发对该文件的下载。不幸的是，协调将会一直等待直到下载完成，这有可能会导致应用被锁住很长一段时间。访问一个文件之前，应用应该先检查文件下载转台。你可以通过 `NSURLUbiquitousItemDownloadingStatusKey` 查询 URL 的资源值或使用 `NSMetadataQuery` 做到这一点。

### Some Remarks on Coordination Methods
### 协调方法的几个备注

Reading the documentation of `NSFileCoordinator`, you may notice that many method calls have a lengthy and complicated description. While the API is generally very conclusive, it has a high complexity due to the variety of interactions with other coordinators and file presenters, as well as the differing semantics for folder and file locking. Throughout these lengthy descriptions there are several details and issues that may be easily missed:

1. Take coordination options seriously. They really influence the behavior of file coordinators and file presenters. For example, if the flag `NSFileCoordinatorWritingForDeleting` is not provided, file presenters will not be able to influence the deletion of a file through `accommodatePresentedItemDeletionWithCompletionHandler:`. If `NSFileCoordinatorWritingForMoving` is not used when moving directories, the move operation will not wait for ongoing coordinations on subitems to be finished.

2. Always expect that coordination calls may fail and return errors. Since file coordination interacts with iCloud, a coordination call may fail with an error message if the coordinated file cannot be downloaded, and your actual file operation may not be performed. If error handling is not correctly implemented, your application may not notice problems like this.

3. Verify a file’s state after entering coordination blocks. A lot of time may pass after the request for the coordination. In the meantime, preconditions that lead an application to perform a file operation may have become false. Information you are going to write could have become stale until the lock is granted. It could also be possible that your file has been deleted while you’ve waited to get write access. In this case, you might accidentally recreate the deleted file.

阅读 `NSFileCoordinator` 的文档，你可能注意到每个方法都有一个冗长而复杂的描述。虽然 API 文档通常是非常可靠的，但由于同其他协调器和文件描述者交互的多样性，以及文件夹和文件锁的语法多样性，都造成了很高的复杂度。有一些很容易忽略的细节和问题贯穿这些长长的描述:

1. 认真选择协调选项。它们真的对文件协调器和文件描述者有着影响。比如，如果没有采用 `NSFileCoordinatorWritingForDeleting` 标识，文件描述器将不会通过 `accommodatePresentedItemDeletionWithCompletionHandler:` 被通知文件删除。如果移动目录时不使用 `NSFileCoordinatorWritingForMoving`，则移动操作将不会等待正在子项目上操作的协调完成。
2. 始终认为协调调用可能会失败并返回错误。因为文件协调同 iCloud 交互，如果被协调的文件不能被下载，协调调用会失败并产生一条错误信息，并且你实际的文件操作可能不会被执行。如果没有正确的实现错误处理方法，你的应用可能不会注意到这样的问题。
3. 在进入协调 block 之前检查文件状态。协调请求之后，也许很长时间过去了。这时，应用操作文件的前提条件已经失效。你想写入的信息直到重新获得锁之前都是脏数据。也可能在你等待获得写入权限的时候文件已经被删除。这时你可能会无意中再次创建已经删除的文件。


### Notification Deadlocks
### 通知死锁

Implementing notification handlers of `NSFilePresenter` requires special attention. Some notifications, such as `relinquishPresentedItemToReader:`, must be confirmed to signal to other processes that a file is ready for access. Typically, this is done by executing a confirmation block passed as an argument to the notification handler. It is important to know that, until the confirmation block is called, the other process has to wait. If the confirmation is delayed due to slow notification processing, the coordinating process may stall. If it is never executed, it will probably hang forever.

实现通知处理方法 `NSFilePresenter` 需要特别注意。类似 `relinquishPresentedItemToReader:` 这样的方法必须被确认以通知其他进程文件已经对访问准备就绪。一般通过执行作为参数传入通知处理方法的 block 代码块来完成。确认 block 被调用之前，其他进程不得不等待，了解这一点是尤为重要的。如果确认因为通知处理的缓慢而被延迟，协调进程也许会被搁置。如果一直没有被执行，则可能会永远被挂起。

Unfortunately, notifications that need to be confirmed can also be slowed down by other, completely independent notifications. To ensure notifications are being processed in the correct order, the `presentedItemOperationQueue` is usually configured as a sequential queue. However, using a sequential queue means that slowly processed notifications will delay their succeeding notifications. In particular, they may slow down succeeding notifications that require a confirmation, and by that, any process waiting for them.

不幸的是，需要被确认的通知仍然会被其他完全独立的通知拖慢。为了确保通知以正确的顺序执行，`presentedItemOperationQueue` 一般被设置为一个顺序执行队列。但是一个顺序队列就意味着处理速度慢的通知会延缓随后的通知。尤其是它们会延缓需要确认的通知，在那之前，所有的进程都将等待。

For example, assume a notification like `presentedItemDidChange` has been enqueued first. A lengthy processing of this callback may stall other notifications, like `relinquishPresentedItemToReader:`, that have been enqueued shortly after. As a consequence, the confirmation of this notification will also be delayed, which in turn stalls the process waiting for it.

例如，假设一个 `presentedItemDidChange` 通知首先进入队列。该回调漫长的处理过程将会延缓其他随后进入队列的通知，比如 `relinquishPresentedItemToReader:`。因此，该通知的确认也会被延迟，从而也导致等待它的进程被延缓。

Above all, *never* perform any file coordination while inside a presentation queue. In fact, even simple notifications without any confirmation needs (e.g. `presentedItemDidChange`) can cause deadlocks. Just imagine two file presenters presenting the same file. Both presenters are handling the notification `presentedItemDidChange` by performing a coordinated read operation on the presented file. If the file has been changed, this notification is sent to both presenters and both presenters perform a coordinated read on the same file. As a consequence, both presenters query each other to relinquish the file by enqueuing a `relinquishPresentedItemToReader:` and wait for each other to confirm this notification. Unfortunately, both presenters are unable to confirm the notification since both are blocking their presentation queues by the coordination request waiting forever on the other's confirmation. We've prepared a small example exploiting this deadlock on [GitHub][15].

综上所述，在描述队列里的时候 *永远不要* 执行文件协调。实际上，即使简单的不需要任何确认的通知(比如 `presentedItemDidChange`)也会导致死锁。设想两个文件描述者同时在展示同一个文件。两个描述者都通过执行协调的读取操作来处理 `presentedItemDidChange` 通知。如果文件发生改变，通知被发送到两个描述者并且二者都在同一个文件上执行协调的读取操作。因此，两个描述者都通过入队一个  `relinquishPresentedItemToReader:` 请求对方释放文件并等待对方确认。不幸的是，两个描述者无法确认通知，因为它们都因为永久的等待对方确认的协调请求而阻塞了它们的描述队列。我们在 [GitHub](https://github.com/hydrixos/DeadlockExample) 上提供了一个小例子解释这种死锁。

### Defective Notifications
### 通知缺陷

Drawing the correct conclusions from notifications is not always easy. There are bugs inside file presentation causing some notification handlers to *never be called*. Here is a short glimpse of known misbehaving notifications:

1. Aside from `presentedSubitemDidChangeAtURL:` and `presentedSubitemAtURL:didMoveToURL:`, all subitem notifications are either never called or called in a very unpredictable way. Don’t rely on them at all — in particular, `presentedSubitemDidAppearAtURL:` and `accommodatePresentedSubitemDeletionAtURL:completionHandler:` will never be called.
2. `accommodatePresentedItemDeletionWithCompletionHandler:` will only work if the deletion was performed through a file coordination that used the `NSFileCoordinatorWritingForDeleting` flag. Otherwise, you may not even receive a change notification.
3. `presentedItemDidMoveToURL:` and `presentedSubitemAtURL:didMoveToURL:` will only be sent if `itemAtURL:didMoveToURL:` was called by the moving file coordinator. If not, items will not receive any useful notifications. Subitems may still receive two separate `presentedSubitemDidChange` notifications for the old and new URLs.
4. Even if files have been moved correctly and a `presentedSubitemAtURL:didMoveToURL:` notification was sent, you will still receive two additional `presentedSubitemDidChangeAtURL:` notifications for the old and new URL. Be prepared for that.

从通知中得出正确结论并不容易。文件描述中存在的 bug 造成了有些通知处理器 *从未被执行*。这里初步介绍一些已知的不太规律的通知:

1. 除了 `presentedSubitemDidChangeAtURL:` 和 `presentedSubitemAtURL:didMoveToURL:`，所有的子项目通知要么不被调用，要么以一种难以预测的方式被调用。绝对不要依赖它们 -- 实际上，`presentedSubitemDidAppearAtURL:` 和 `accommodatePresentedSubitemDeletionAtURL:completionHandler:` 从不会被调用。
2. 只有通过使用了 `NSFileCoordinatorWritingForDeleting` 的文件协调删除文件，`accommodatePresentedItemDeletionWithCompletionHandler:` 才会工作。
3. 只有文件描述者执行 `itemAtURL:didMoveToURL:`，`presentedItemDidMoveToURL:` 和 `presentedSubitemAtURL:didMoveToURL:` 才会被调用。否则项目不会收到任何游泳的通知。子项目会分别针对旧的和新的 URL 收到 `presentedSubitemDidChange` 通知。
4. 即使文件被正确移动，`presentedSubitemAtURL:didMoveToURL:` 通知也被发送，你仍然会收到两个额外的 `presentedSubitemDidChangeAtURL:` 通知。要做好准备好处理这个。


Generally, you have to be aware that notifications may be outdated. You should also not rely on any specific ordering of notifications. For example, when presenting a directory tree, you may not expect that notifications regarding a parent folder will appear before or after notifications on one of its subitems.

一般来说，你必须注意通知可能会失效。也不应该依赖于任何特定的通知顺序。例如，当描述一个目录树时，你不能期望父文件夹的通知会先于或晚于其中子项目的通知。

### Be Aware of URL Changes
### 注意 URL 变化

There are several situations where you need to be prepared in case file coordinators and file presenters deliver multiple variants of the same URL referencing the same file. You should never compare URLs using `isEqual:`, because two different URLs may still reference the same file. You should always standardize URLs before comparing them. This is especially important on iOS, where ubiquity containers are stored in `/var/mobile/Library/Mobile Documents/`, which is a symbolically linked folder for `/private/var/mobile/Library/Mobile Documents/`. You will receive presenter notifications with URLs based on *both path variants* that still reference the same file. This issue can also occur on OS X if you are using file coordination code for iCloud and local documents.

有几种你需要应对的情况，文件协调和文件描述者传递关联相同文件的多个 URL 的变体。你绝不应该使用 `isEqual:` 比较 URL，因为两个不同的 URL 可能关联同一个文件。应该始终在比较之前标准化它们。这一点在 iOS 上尤为重要，在 iOS 中开放性容器存储在 `/var/mobile/Library/Mobile Documents/` 中，这个文件夹是 `/private/var/mobile/Library/Mobile Documents/` 的符号链接。你会收到带有指向同一个文件，基于 *两种路径变体* 的 URL 的描述者通知。如果你对 iCloud 和本地文档使用文件协调代码，这个问题在 OS X 上也会发生。

Beyond that, there are also several issues on case-insensitive file systems. You should always make sure that you perform a case-insensitive comparison of filenames *if* the file system requires it. File coordination blocks and presenter notifications may deliver variants of the same URL using different casings. In particular, this an important issue when renaming files using file coordinators. To understand this issue, you need to recall how files are actually renamed:

除此之外，还有几个关于大小写不敏感的文件系统的问题。*如果* 文件系统要求，应该始终确保你使用大小写不敏感的文件名比较。文件协调 block 和描述者通知可能传递使用不同大小写的相同的 URL 变体。实际上，这是使用文件协调器重命名时的重要问题。为了搞懂这个问题，你需要回顾文件实际上是如何被重命名的:

	[coordinator coordinateWritingItemAtURL:sourceURL 
	                                options:NSFileCoordinatorWritingForMoving 
	                       writingItemAtURL:destURL 
	                                options:0 
	                                  error:NULL 
	                             byAccessor:^(NSURL *oldURL, NSURL *newURL) 
	{
		[NSFileManager.defaultManager moveItemAtURL:oldURL toURL:newURL error:NULL];
		[coordinator itemAtURL:oldURL didMoveToURL:newURL];
	}];

Assume `sourceURL` references a file named `~/Desktop/my text` and `destURL` references the new filename written in upper case: `~/Desktop/My Text`. By design, the coordination block will be passed the most recent version of both URLs in order to accommodate move operations that happened while waiting for file access. Now, unfortunately, when changing a filename’s case, the URL's validation performed by file coordination will find an existing valid file for both the old and the new URL, which is the lowercase variant `~/Desktop/my text`. The access block will receive the same *lowercase* URL as `oldURL` and `newURL`, leading to a failure of the move operation.

假设 `SourceURL` 指向一个名为 `~/Desktop/my text` 的文件，`destURL`使用了大写字母的新文件名 `~/Desktop/My Text`。协调 block 被有意设计成传入两个 URL 的最新版本，以兼容等待文件访问时发生的移动操作。现在，不幸的，当改变文件名的大小写，文件协调所执行的 URL 校验将会发现新旧两个 URL 都存在一个有效文件，URL 是小写 `~/Desktop/my text` 的变体。访问 block 将会接收到同样的 *小写* URL 作为 `oldURL` 和 `newURL`，导致移动操作失败。

### Requesting Downloads
### 请求下载

On iOS, it’s the application's responsibility to trigger downloads from iCloud. Downloads can be triggered through the method  [`startDownloadingUbiquitousItemAtURL:error:`][16] of `NSFileManager`. If your application is designed to download files automatically (i.e. not triggered by the user), you should always perform those download requests from a sequential background queue. On the one hand, each single download request involves quite a bit of interprocess communication and may take up to a second. On the other hand, triggering too many downloads at once seems to overload the *ubd* daemon at times. A common mistake is to wait for new files in iCloud using an `NSMetadataQuery` and automatically trigger a download for them. Since the query result is always delivered on the main queue and it can contain updates for dozens of files, directly triggering downloads will block an application for a long time.

在 iOS 中，触发从 iCloud 的下载是应用的责任。可以通过 `NSFileManager` 的 [`startDownloadingUbiquitousItemAtURL:error:`](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/nsfilemanager_class/reference/reference.html#//apple_ref/occ/instm/NSFileManager/startDownloadingUbiquitousItemAtURL:error:) 方法触发下载。如果你的应用设计成自动下载文件(也就是不由用户触发)，你应该始终在一个顺序后台队列中执行这些下载请求。换句话说，每一个单独的下载请求涉及到相当多的进程间通信并可能会很耗时。另一方面，同时触发太多的下载有时会过载 *ubd* 守护进程。一个普遍的错误就是使用 `NSMetadataQuery` 等待 iCloud 中的新文件然后自动触发下载它们。因为查询结果总是在主队列中传递并且可能包含一打的更新信息，直接触发下载会阻塞应用很长一段时间。

To query the download or upload status of a certain file, you can use resource values of `NSURL`. Before iOS 7 / OS X 10.9, the download status of a file was made available through `NSURLUbiquitousItemIsDownloadedKey`. According to its header documentation, this resource value never worked correctly, and so it was deprecated in iOS 7 and Mavericks. Apple now recommends to use `NSURLUbiquitousItemDownloadingStatusKey`. On older systems, you should use an `NSMetadataQuery` and query for `NSMetadataUbiquitousItemIsDownloadedKey` to get the correct download status.

为了某个文件的查询或者下载状态，你可以使用 `NSURL` 的资源值。在 iOS7 / OS X 10.9 之前，一个文件的下载状态通过 `NSURLUbiquitousItemIsDownloadedKey` 来确认。根据头文件文档，这个资源值从未正确生效过，所以在 iOS 7 和 Mavericks 中被废弃了。现在苹果建议使用 `NSURLUbiquitousItemDownloadingStatusKey`。在老系统上，你应该使用 `NSMetadataQuery` 查询 `NSMetadataUbiquitousItemIsDownloadedKey` 来获得正确的下载状态。

## General Considerations
## 总则

Adding support for iCloud to your application is not just another feature you’re adding. Instead, it is a decision that has far-reaching consequences on the design and implementation of your application. It influences your data model as well as the user interface. So don’t underestimate the efforts of properly supporting iCloud. 

为你的应用增加 iCloud 支持并不只是你增加的另一个功能，而是一个对应用设计和实现有着深远影响的决定。它既影响着你的数据模型也影响着 UI。所以不要低估支持 iCloud 所需要做出的努力。

Most importantly, adding iCloud will introduce a new level of asynchrony to an application. The application must be able to deal with changes on documents and metadata at any time. Notifications on those changes may be received by different threads, raising the need for synchronization primitives across your entire application. You need to be aware of issues in code that are critical for the integrity of a user's documents, like lost updates, race conditions, and deadlocks.

最重要的，增加 iCloud 会引入一个新的异步层。应用必须能够在任何时候处理文档和元数据的变化。这些变化上的通知可能会在多个不同线程上收到，引起贯穿你整个应用的对于同步类型的需求。你需要注意对于用户文档完整性很严重的代码中的的问题，比如丢失更新，资源竞争和死锁。

Always keep in mind that synchronization guarantees of iCloud are very weak. You can only assume that files and packages are synchronized atomically. But you cannot expect that multiple files modified simultaneously are also synchronized at once. For example, if your application stores meta information separate from the actual files, it must be able to cope with the fact that this metadata will be downloaded earlier or later than the actual files.

始终注意 iCloud 的同步保证是非常脆弱的。你只能推测文件和包是自动同步的。但你不能期望多个同时被修改的文件也会被立刻同步。比如，如果你的应用分开存储元信息，它一定要能够应对元信息会先于或晚于实际文件被下载。

Using the iCloud document sync also means that you’re writing a distributed application. Your documents will be processed on different devices running different versions of your application. You may want to be forward-compatible with different versions of your file format. At the very least, you must ensure your application will not crash or fail if it faces a file generated by a newer version of your application installed on a different device. Users may not update all devices at once, so be prepared for that.

使用 iCloud 文档同步同时也意味着你正在做一个发布的应用。你的文档会在运行着不同版本的不同设备上。你可能想要使你文件格式的不同版本向前兼容。起码，你必须确保你的应用在面对其他不同设备上安装的新版本应用创建的文件时不会崩溃或发生错误。用户未必会立刻更新所有的设备，所以预先准备好这个问题。

Finally, your user interface needs to reflect synchronization, even though it may kill some of the magic. Especially on iOS, connection failures and slow file transfers are a reality. Your users need to be informed about the synchronization status of documents. You should consider showing whether files are currently uploading or downloading, in order to give users an idea of the availability of their documents. When using large files, you may need to show progress of file transfers. Your user interface should be graceful; if iCloud can’t serve you a certain document in time, your application should still be responsive and let the user retry or at least abort the operation.

最后，你的 UI 需要反映同步行为。即使这会抹杀掉一些神奇之处。尤其在 iOS 上，连接失败和缓慢的文件转换是现实状况。你的用户应该被通知关于文档的同步状态。你应该考虑展示文件是在被上传还是在载。以便给用户提供他们现在文档有效性的提示。使用大文件时，你可能需要显示文件转换进度，你的 UI 应该优雅一些; 如果 iCloud 不能及时给你某个文档，你的应用应该响应，并且让用户重试或至少放弃操作。

## Debugging
## 调试

Due to the involvement of multiple system services and external servers, debugging iCloud issues is quite difficult. The iCloud debugging capabilities provided by Xcode 5 are limited and mostly just give a glimpse of whether iCloud sync is happening or not. Fortunately, there are some more or less official ways of debugging the iCloud document store.

因为涉及到多系统服务和外部服务，调试 iCloud 问题非常困难。Xcode 5 提供的 iCloud 调试功能非常有限并且大多数时候只会告诉你 iCloud 是否已经同步。幸运的是，还有一些差不多是官方的方法来调试 iCloud 文档存储。

### Debugging on OS X
### 在 OS X 上调试

Every now and then, you may experience iCloud stopping syncing of a certain file or even stopping to work completely. In particular, this happens easily when using debug breakpoints inside file coordinators or when killing a process during an ongoing file operation. It may even happen to your customers if your application crashed at such critical points. Often, neither rebooting nor logging out and back in to iCloud fixes the issue.

有时你可能感觉 iCould 停止同步某个文件或干脆完全停止工作。实际上，这在文件协调器内使用断点或在一个文件操作进行期间杀掉一个进程时很容易发生。甚至如果你的应用在某个关键点崩溃后也会发生。通常来说，重启或者注销后重新登录 iCloud 都不能修复这个问题。

To fix these lockdowns, one command-line utility can be very beneficial: `ubcontrol`. This utility is part of every OS X release since 10.7. Using the command `ubcontrol -x`, you are able to reset the local state of document syncing. It will revive stalled synchronizations by resetting some private databases and caches and restarting all involved system daemons. It also stores some kind of post-mortem information inside `~/Library/Application Support/Ubiquity-backups`.

为了修复这些锁定，一个命令行工具会非常有好处: `ubcontrol`。这个工具是 10.7 以后版本 OS X 的一部分。使用命令 `ubcontrol -x`，你能够重置文档同步的本地状态。它通过重置一些私有数据库和缓存，重启所有涉及到的系统守护进程，来复原熄火的同步。它也会存储一些报告分析信息到 `~/Library/Application Support/Ubiquity-backups`。

While there are already very extensive log files written to `~/Library/Logs/Ubiquity`, you may also increase the logging level through `ubcontrol -k 7`. You are usually asked by Apple engineers to do this for collecting information on an iCloud-related bug report.

虽然已经有广泛的日志文件被写入 `~/Library/Logs/Ubiquity`，你还可以通过 `~/Library/Logs/Ubiquity` 来增加日志级别。在进行 iCloud 相关的错误报告时，苹果工程师经常会要求你这么做以便收集信息。

For debugging file coordination issues, you can also directly retrieve lock status information from inside the file coordination daemon. This enables you to understand file coordination deadlocks that may occur inside your application or between multiple processes. To access this information you need to execute the following commands in Terminal:

为了调试文件协调，你还可以从文件协调守护进程中直接取回锁状态信息。这使你能够得知在应用中或多进程间可能遇到的文件协调死锁。为了访问这个信息，你需要在终端中执行以下命令:

	sudo heap filecoordinationd -addresses NSFileAccessArbiter
	sudo lldb -n filecoordinationd
	po [<address> valueForKey: @"rootNode"]

The first command will return you the address of an internal singleton object of the file coordination daemon. Afterward, you attach *lldb* to the running daemon. By using the retrieved address from the first step, you will get an overview on the state of all active locks and file presenters. The debugger command will show you the entire tree of files that are currently being presented or coordinated. For example, if TextEdit is presenting a file called `example.txt` you will get the following trace:

第一个命令会返回一个文件协调守护进程的内部单例对象。随后，你关联 *lldb* 到运行的守护进程上。通过使用第一步取回的地址，你将会得到一个所有活动的锁和文件描述者的状态的概览。调试命令会展示当前正在被描述或协调的整个文件树。例如，如果 TextEdit 正在描述一个名为 `example.txt` 的文件，你会得到以下跟踪信息:

	example.txt
		<NSFileAccessNode 0x…> parent: 0x…, name: "example.txt"
		presenters:
			<NSFilePresenterProxy …> client: TextEdit …>
			location: 0x7f9f4060b940
		access claims: <none>
		progress subscribers: <none>
		progress publishers: <none>
		children: <none>

If you create such traces while a file coordination is going on (e.g. by setting a break point inside a file coordination block), you will also get a list of all processes waiting for file coordinators.

如果你在文件协调进行时创建这种跟踪(比如通过在文件协调 block 中设置断点)，你还会得到一个等待文件协调器的所有进程的列表。

If you’re inspecting file coordination through *lldb*, you should always remember to execute the `detach` command as soon as possible. Otherwise, the global root process file coordination daemon will stay stopped, which will stall almost any application in your system.

如果通过 *lldb* 观察文件协调，你应该始终记得尽快执行 `detach` 命令。否则，全局根进程文件协调守护进程将一直等待，并使系统几乎所有应用熄火。

### Debugging on iOS
### 在 iOS 上调试

On iOS, debugging is more complicated, because you can’t inspect running system processes and you can’t use command-line tools like `ubcontrol`.

在 iOS 上，调试要更加复杂，因为你无法检查运行的系统进程，你也无法使用像 `ubcontrol` 的命令行工具。

Lockdowns of iCloud seem to occur even more often on iOS. Neither restarts of the application nor simple device reboots help. The only effective way to fix such issues is a *cold boot*. During a cold boot, iOS seems to perform a reset of iCloud’s internal databases. A device can be cold-booted by pressing the power and home button at the same time for 10 seconds. 

iCloud 锁定在 iOS 上似乎更经常发生。重启应用或设备都无效。唯一有效的修复这种问题的方法是 *冷启动*。在冷启动过程中，iOS 似乎进行了 iClouds 的内部数据库重置。可以通过同时按下电源键和 home 键10秒钟冷启动设备。

To activate extensive logging on iOS, there exists a special iCloud logging profile on Apple’s [developer downloads page][17]. If you’re searching for “Bug Reporter Logging Profiles (iOS),” you will find a mobile device profile called “iCloud Logging Profile.” Install this profile on your iOS device to activate extensive logging. You can access these logs by syncing your device with iTunes. Afterward, you will find it inside the folder `Library/Logs/CrashReporter/Mobile Device/<Device Name>/DiagnosticLogs/Ubiquity`. To deactivate intensive logging, just delete the profile from the device. Apple recommends you reboot your device before activation and after deactivation of the profile.

为了在 iOS 上激活更广泛的日志，在苹果 [developer downloads page](https://developer.apple.com/downloads) 有一个专用的 iCloud 日志概述。如果搜索 "Bug Reporter Logging Profiles (iOS)"，你将会找到一个叫做 "iCloud Logging Profile" 移动设备概述。在你的 iOS 设备上安装该文件来激活更广泛的日志。你可以用 iTunes 同步设备来访问这些日志.随后，你可以在 `Library/Logs/CrashReporter/Mobile Device/<Device Name>/DiagnosticLogs/Ubiquity` 文件夹找到它。要关闭密集的日志，从设备删除概述即可。苹果建议你在激活或关闭概述前重启设备。

### Debugging on iCloud Servers
### 在 iCloud Servers 上调试

Aside from debugging on your own devices, it might also be helpful to consider the debugging services on Apple’s servers. A particular web application is located at [developer.icloud.com][18], and it allows you to browse all information stored inside your ubiquity container, as well as the current transfer status. 

除了在你自己的设备上调试，考虑使用苹果服务上的调试服务可能也会有用。一个特殊的 web 应用放在 [developer.icloud.com](https://developer.icloud.com/)，它允许你浏览存储在开放性容器内的所有信息和当前传输状态。

For the past few months, Apple has also offered a safe server-side reset of iCloud syncing on all connected devices. For details, please have a look at this [support document][19].

过去的几个月，苹果还提供了在所有已连接设备上进行 iCloud 安全的服务端重置。更多信息可查看 [support document](http://support.apple.com/kb/HT5824)。

[1]: https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesigningForDocumentsIniCloud.html "Designing For Documents in the Cloud"
[2]:http://www.ulyssesapp.com
[3]:https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html#//apple_ref/doc/uid/TP40012094-CH6-SW13
[4]:https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/nsfilemanager_class/reference/reference.html#//apple_ref/occ/instm/NSFileManager/URLForUbiquityContainerIdentifier:
[5]:https://developer.apple.com/library/ios/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileCoordinators/FileCoordinators.html#//apple_ref/doc/uid/TP40010672-CH11-SW1
[6]:https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFileCoordinator_class/Reference/Reference.html
[7]:https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html
[8]:https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfp/NSFilePresenter/presentedItemOperationQueue
[9]:https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfm/NSFilePresenter/savePresentedItemChangesWithCompletionHandler:
[10]:https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfm/NSFilePresenter/presentedItemDidGainVersion:
[11]:https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/nsfilemanager_class/reference/reference.html#//apple_ref/occ/instm/NSFileManager/startDownloadingUbiquitousItemAtURL:error:
[12]:https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesigningForDocumentsIniCloud.html "Designing For Documents in the Cloud"
[13]:https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfm/NSFilePresenter/savePresentedItemChangesWithCompletionHandler:
[14]:https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfm/NSFilePresenter/relinquishPresentedItemToReader:
[15]:https://github.com/hydrixos/DeadlockExample
[16]:https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/nsfilemanager_class/reference/reference.html#//apple_ref/occ/instm/NSFileManager/startDownloadingUbiquitousItemAtURL:error:
[17]:https://developer.apple.com/downloads
[18]:https://developer.icloud.com/
[19]:http://support.apple.com/kb/HT5824

[image-1]:{{ site.images_path }}/issue-10/Open.png
[image-2]:{{ site.images_path }}/issue-10/Mobile%20Documents.png
