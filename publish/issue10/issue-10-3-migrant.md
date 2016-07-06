即便在推出 3 年后，iCloud 文档存储依然是一个充满神秘、误解和抱怨的话题。iCloud 同步经常被批评不可靠且速度慢。虽然在 iCloud 的早期有一些严重的 bug，开发者们还是不得不学习有关文件同步的课程。文件同步事关重大，为应用开发带来了新方向 -- 一个经常被低估的方向，比如进行同步服务相关的合作时，对于处理文件异步更改的需要。

本文会介绍几个创建支持 iCloud 的应用时可能会遇到的一些绊脚石。因为本文只会给出一些粗略的概述，所以如果你对 iCloud 文档存储还不熟悉，我们强烈建议你先阅读 [Apple iCloud companion guide](https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesigningForDocumentsIniCloud.html)。

## 文档存储简介

iCloud 文档存储的核心思想非常简单：每个应用都有至少通往一个“魔法文件夹”的入口，该文件夹可以存储文件并且随后在所有注册了同一个 iCloud 帐号的设备间同步。

与其他基于文件系统的同步服务相比，iCloud 文档存储得益于与 OS X 和 iOS 的深度整合。很多系统框架已经被扩展以支持 iCloud。像 `NSDocument` 和 `UIDocument` 这样的类被按照可以处理外部变化来进行设计。版本存储和 `NSFileVersion` 处理同步冲突。Spotlight 被用来提供同步元数据，比如文件传输进度或者云端文档可用性。

写一个简单的基于文档并开启了 iCloud 的 OS X 应用并不需要费多大力气。实际上你并不需要关心任何 iCloud 内部的工作，`NSDocument` 无偿的做了几乎每件事情：协调文档的 iCloud 访问，自动观察外部变化，触发下载，处理冲突。它甚至提供了一个简单的 UI 界面来管理云文档。你需要做的所有事情就是创建一个 `NSDocument` 子类并实现读取和写入文档内容所需要的方法。

![NSDocument 为管理应用的已同步文档所提供的简单界面](/images/issues/issue-10/Open.png)

然而，一旦脱离预设的路径，你就需要了解的更多。例如，默认打开面板提供的单层文件夹以外的任何操作都需要手动完成。可能你的应用需要管理除了文档内容以外的文档，比如像 Mail，iPhoto 或者 [Ulysses](http://www.ulyssesapp.com/) (我们自己的app) 中做的那样。这种时候，你不能依赖于 `NSDocument`，而需要自己实现它的功能。但为此你需要对 iCloud 提供的锁和通知机制有一个深入的了解。

开发支持 iCloud 的 iOS 应用同样需要更多的工作和知识；虽然 `UIDocument` 仍然管理 iCloud 文件访问和处理同步冲突，但缺乏管理文档和文件夹的图形界面。因为性能和存储空间的原因，iOS 也不会自动从云端下载新文档。你需要使用 Spotlight 来检索最近变化的目录并手动触发下载。

## 什么是开放性容器 (Ubiquity Container)

任何符合 App Store 条件的应用都可以使用 iCloud 文档存储。设置正确的[授权](https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html#//apple_ref/doc/uid/TP40012094-CH6-SW13)后，就获得了一个或多个所谓的“开放性容器”的访问权限。这是苹果用来称呼“一个被 iCloud 管理和同步的目录”的别称。每一个开放性容器限定在一个 app id 内，由此让每个用户在每个应用中有一份共享的存储仓库。有多个应用的开发者可以指定同一个团队的多个 app id，由此可以访问多个容器。

`NSFileManager` 通过 [URLForUbiquityContainerIdentifier:](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/nsfilemanager_class/reference/reference.html#//apple_ref/occ/instm/NSFileManager/URLForUbiquityContainerIdentifier:) 提供每一个容器的 URL。在 OS X 系统，可以通过打开 `~/Library/Mobile Documents` 目录来查看所有可用的开放性容器。

![”~/Library/Mobile Documents“的内容，它包含了每个应用开放性容器所分别对应的文件夹](/images/issues/issue-10/Mobile%20Documents.png)

通常每个开放性容器有两个并发进程访问。首先，有一个应用呈现和操作容器内的文档。第二，有一个主要通过开放性守护 (Ubiquity Daemon *ubd*) 体现的 iCloud 架构。iCloud 架构等待应用对文档的更改并将其上传至苹果云服务器。同时也等待从 iCloud 上收到的更改并相应修改容器的内容。

由于两个进程完全独立于彼此工作，因此需某种形式的仲裁来避免资源竞争或丢失容器内的文件更新的问题。应用需要使用名为 [*文件协调 file coordination*](https://developer.apple.com/library/ios/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileCoordinators/FileCoordinators.html#//apple_ref/doc/uid/TP40010672-CH11-SW1) 的概念来确保对于每一个独立文件的访问权。该访问权由 [`NSFileCoordinator`](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFileCoordinator_class/Reference/Reference.html) 类提供。概括来说，它为每个文件提供了一个简单的 读-写 锁。这个锁由一个通知机制扩展，该机制用于用于改善访问同一个文件的不同进程间的合作。

这个通知机制相比于简单的文件锁来说是有巨大的的好处，并且提供了无缝的用户体验。iCloud 可能会在任何时间把文档用一个来自其他设备的新版本覆盖。如果一个应用当前正在显示同一个文档，它必须从磁盘加载新版本并向用户展示更新过的内容。更新过程中，应用可能需要锁住用户界面一段时间并随后在此打开。甚至可能发生更坏的情况：应用可能保留着未保存的内容，这些内容需要**首先**保存到磁盘上以便检查同步冲突。最后，在网络条件良好的时候 iCloud 会上传文件最近的版本。因此必须能够要求应用立刻保存所有未保存的变更。

为了实现这个过程，文件协调伴随着另一套名为 *文件展示 (file presentation)* 的机制。无论什么时候应用打开并向用户展示一个文件，这被称为被称作 *展示文档*，并且应该注册一个实现了 [`NSFilePresenter`](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html) 协议的对象。只要另一个进程通过一个文件协调访问文件，文件展示者 (file presenter) 就会收到关于该文件的通知。这些通知被作为方法调用传递，这些方法在展示者指定的一个操作队列([`presentedItemOperationQueue`](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfp/NSFilePresenter/presentedItemOperationQueue))中异步执行。

例如，在任何其他线程被允许开始一个读取操作前，文件展示者被要求保存任何未保存的变化。这些操作通过分发一个 block 到它的展示队列来执行 [`savePresentedItemChangesWithCompletionHandler:`](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfm/NSFilePresenter/savePresentedItemChangesWithCompletionHandler:) 方法来完成。展示者需要保存文件并通过执行作为参数传入的 block 来确认通知。除了改变通知，文件展示者还用来通知应用同步冲突。一旦一个文件的冲突版本被下载，一个新的文件版本被加入到版本存储里。所有的展现者通过 [`presentedItemDidGainVersion:`](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfm/NSFilePresenter/presentedItemDidGainVersion:) 被通知有一个新版本被创建。该回调接收一个引用了潜在冲突的 `NSFileVersion` 实例。

文件展示者还可以被用来监视文件夹内容。例如，一旦 iCloud 改变文件夹内容，如创建，删除或者移动文件，应用应该被通知到以便更新它的文档展示。为此，应用可以对展示的目录注册一个实现了 `NSFilePresenter` 协议的实例。一个目录的文件展示者会收到任何文件夹或其中文件或子文件夹的改变的通知。比如一个文件夹内的文件被修改，展示者会收到一个引用了该文件的 URL 的 `presentedSubitemDidChangeAtURL:` 通知。

因为带宽和电池寿命在移动设备上更加有限，iOS 不会自动从 iCloud 下载新文件。而是由应用手动决定何时来触发下载新文件到开放性容器中。为了持续告知应用哪些文件可用及其同步状态，iCloud 还会同步开放性容器内的文件元信息。应用可以通过 `NSMetadataQuery` 或访问 `NSURL` 的开放资源属性查询这些元信息。无论何时应用想要访问一个文件，它一定会通过 `NSFileManager` 的 [`startDownloadingUbiquitousItemAtURL:error:`](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/nsfilemanager_class/reference/reference.html#//apple_ref/occ/instm/NSFileManager/startDownloadingUbiquitousItemAtURL:error:) 来触发下载行为。

## 深入 iCloud

在继续解释如何实现文件协调和观察之前，现在我们将深入一些过去几年里碰到的一些常见问题。再一次的，确保你已经阅读并理解了 [Apple iCloud companion guide](https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesigningForDocumentsIniCloud.html)。

虽然这些文件机制的描述让它们的使用看起来简单明了，但其实其中有很多隐藏的陷阱。这些陷阱中有些来自于底层框架的 bug。因为 iCloud 同步延伸到操作系统中相当多的层面，人们只能寄希望于苹果能够小心的修复这些 bug。实际上，苹果看起来宁愿废弃坏掉的 API 而不是修复它们。

即便如此，我们的经验告诉我们使用 iCloud 是非常非常容易犯错误的。异步，协作，基于锁特性的文件协调和文件展示互相牵连，并不容易掌握。下面，我们将介绍整合 iCloud 文档同步时的一些主要规则，并以这种形式分享我们的经验。

### 只在需要时使用 Presenters

文件展示者代价高昂。仅当你的应用需要立即应对或干预文件访问的时候，才应该使用它。

如果你的应用正在展示类似文档编辑器这样的东西给用户，文件展示足以胜任。这时，在其他进程写入该文件的时候也许需要锁住编辑器，或者还需要保存未保存的改变。然而，如果只是临时访问并且通知也可能会被延迟处理，就不应该使用文件展示。例如，当创建文件索引或缩略图，查看文件更改日期并使用简单的文件协调可能会更高效。另外，如果你正展示一个字典树的内容，在树的根节点注册 *一个* 展示者或用 `NSMetadataQuery` 来延迟获取改变通知会可能会非常高效。

是什么让文件展示代价如此高昂？它需要很多的进程间通信：每个文件上注册的展示者在其他进程获取文件的访问权时都被要求释放该文件。比如另一个进程尝试读取一个文件，该文件的展示者会被要求保存所有未保存的内容 ([`savePresentedItemChangesWithCompletionHandler:`](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfm/NSFilePresenter/savePresentedItemChangesWithCompletionHandler:))。它们还会被要求释放文件给读取者([`relinquishPresentedItemToReader:`](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfm/NSFilePresenter/relinquishPresentedItemToReader:))，例如文件被读取时暂时锁住编辑器。

这些通知每一个都需要分发，加工并由各自的接收者确认。并且因为只有实现的进程知道哪些通知会被处理，所以即使展示者没有实现任何方法，进程间也会为每一个可能的通知进行通信。

另外，每个步骤都需要在读取进程，展示进程和文件协调守护进程 (`filecoordinationd`) 间的多重上下文的切换。结果就导致了一个简单的文件访问很快就变成耗费资源的操作。

除此之外，如果太多的展示者被注册，文件协调守护进程可能会删除重要的系统资源。对于每一个展示者，都需要打开并监听每一个它所描述的路径上的文件夹。尤其在 OS X Lion 和 iOS 5 上，这些资源是非常稀少的，过度的使用很容易导致文件协调守护进程的锁死或崩溃。

基于这些原因，我们强烈建议不要在目录树的每一个节点上增加文件展示者，只根据需要使用最少的文件展示者。

### 只在需要时使用协调

虽然文件协调要比文件展示节约资源，但它仍然给你的应用和整个系统增加额外的负担。

每当你的应用正在协调一个文件，其他同时想要访问同一个文件的进程可能需要等待。因此你不该在协调文件时执行过于耗时的任务。如果你这么做了，比如存储了大文件，你可以考虑将它存储到一个临时文件夹，随后在协调访问时使用硬连接。注意每一个协调的访问都可能会触发另一个进程上的文件展示者 -- 该展示者可能需要时间在你的访问之前更新文件。始终考虑使用诸如 `NSFileCoordinatorReadingWithoutChanges` 这样的标识，除非需要读取文件的最新版本。

虽然你的应用的开放性容器可能不会被其他应用访问，过分的文件协调仍然可能成为 iCloud 的一个问题，执行太多的协调请求会造成类似 `ubd` 的进程的[资源饥饿](http://en.wikipedia.org/wiki/Resource_starvation)问题。在应用启动阶段，`ubd` 似乎会扫描开放性容器内的所有文件。如果你的应用在程序启动阶段也在执行相同的扫描。两个进程会经常冲突，从而可能导致协调的高开销。这时考虑更优化的解决方案是明智的。例如扫描目录内容时，单独的文件内容访问权限是根本不需要的。把协调工作延迟到文件内容真正被展示的时候再进行会是不错的选择。

最后，绝对不要协调一个还没有被下载的文件。文件协调会触发对该文件的下载。不幸的是，协调将会一直等待直到下载完成，这有可能会导致应用被锁住很长一段时间。访问一个文件之前，应用应该先检查文件下载状态。你可以通过查询 URL 的 `NSURLUbiquitousItemDownloadingStatusKey` 的值或使用 `NSMetadataQuery` 做到这一点。

### 协调方法的几个备注

阅读 `NSFileCoordinator` 的文档，你可能注意到每个方法都有一个冗长而复杂的描述。虽然 API 文档通常是非常可靠的，但由于同其他协调器和文件展示者交互的多样性，以及文件夹和文件锁的语法多样性，都造成了很高的复杂度。有一些很容易忽略的细节和问题贯穿这些长长的描述：

1. 认真选择协调选项。它们真的对文件协调器和文件展示者有着影响。比如，如果没有采用 `NSFileCoordinatorWritingForDeleting` 标识，文件展示者将无法通过 `accommodatePresentedItemDeletionWithCompletionHandler:` 对文件删除操作做出影响。如果移动目录时不使用 `NSFileCoordinatorWritingForMoving`，则移动操作将不会等待其子项目上正在执行的协调操作进行完成。
2. 始终认为协调调用可能会失败并返回错误。因为文件协调同 iCloud 交互，如果被协调的文件不能被下载，协调调用会失败并产生一条错误信息，并且你实际的文件操作可能不会被执行。如果没有正确的实现错误处理方法，你的应用可能不会注意到这样的问题。
3. 在进入协调 block 之后检查文件状态。协调请求之后，也许很长时间已经过去了。这时，应用操作文件的前提条件可能已经失效。你想写入的信息直到重新获得锁之前有可能都是脏数据。也可能在你等待获得写入权限的时候文件已经被删除。这时你可能会无意中再次创建已经被删除的文件。

### 通知死锁

实现 `NSFilePresenter` 的通知处理方法需要特别注意。类似 `relinquishPresentedItemToReader:` 这样的通知处理方法必须被确认及告知其他进程该文件已经对访问准备就绪。这一般通过执行作为参数传入通知处理方法的确认 block 来完成。确认 block 被调用之前，其他进程不得不等待，了解这一点是尤为重要的。如果确认因为通知处理的缓慢而被延迟，协调进程也许会被搁置。如果一直没有被执行，则可能会永远被挂起。

不幸的是，需要被确认的通知也会被其他完全独立的通知拖慢。为了确保通知以正确的顺序执行，`presentedItemOperationQueue` 一般被设置为一个顺序执行队列。但是一个顺序队列就意味着处理速度慢的通知会延缓随后的通知。尤其是它们会延缓需要确认的通知，在那之前，所有的进程都将等待。

例如，假设一个 `presentedItemDidChange` 通知首先进入队列。该回调漫长的处理过程将会延缓其他随后进入队列的通知，比如 `relinquishPresentedItemToReader:`。因此，该通知的确认也会被延迟，从而也导致等待它的进程被延缓。

综上所述，在展示队列里的时候 *永远不要* 执行文件协调。实际上，即使简单的不需要任何确认的通知 (比如 `presentedItemDidChange`) 也会导致死锁。设想两个文件展示者同时在展示同一个文件。两个展示者都通过执行协调的读取操作来处理 `presentedItemDidChange` 通知。如果文件发生改变，通知被发送到两个展示者并且二者都在同一个文件上执行协调的读取操作。因此，两个展示者都通过入队一个  `relinquishPresentedItemToReader:` 请求对方释放文件并等待对方确认。不幸的是，两个展示者无法确认通知，因为它们都因为永久的等待对方确认的协调请求而阻塞了它们的展示队列。我们在 [GitHub](https://github.com/hydrixos/DeadlockExample) 上提供了一个小例子展示这种死锁。

### 通知缺陷

从通知中得出正确结论并不容易。文件展示中存在的 bug 造成了有些通知处理器*从未被执行*。这里初步介绍一些已知的不太规律的通知:

1. 除了 `presentedSubitemDidChangeAtURL:` 和 `presentedSubitemAtURL:didMoveToURL:`，所有的子项目通知要么不被调用，要么以一种难以预测的方式被调用。绝对不要依赖它们 -- 实际上，`presentedSubitemDidAppearAtURL:` 和 `accommodatePresentedSubitemDeletionAtURL:completionHandler:` 从不会被调用。
2. 只有通过使用了 `NSFileCoordinatorWritingForDeleting` 的文件协调来删除文件，`accommodatePresentedItemDeletionWithCompletionHandler:` 才会工作。否则，你会连一个 change 的通知都收不到。
3. 只有文件展示者执行 `itemAtURL:didMoveToURL:` 时，`presentedItemDidMoveToURL:` 和 `presentedSubitemAtURL:didMoveToURL:` 才会被调用。否则项目不会收到任何有用的通知。子项目仍旧会分别针对旧的和新的 URL 收到 `presentedSubitemDidChange` 通知。
4. 即使文件被正确移动，`presentedSubitemAtURL:didMoveToURL:` 通知也被发送，你仍然会针对旧的和新的 URL 收到两个额外的 `presentedSubitemDidChangeAtURL:` 通知。要做好准备好处理这个。

一般来说，你必须注意通知可能会失效。也不应该依赖于任何特定的通知顺序。例如，当描述一个目录树时，你不能期望父文件夹的通知会先于或晚于其中子项目的通知。

### 注意 URL 变化

在文件协调和文件展示者传递参照着相同文件的不同的 URL 时，有几种你需要应对的情况。你绝不应该使用 `isEqual:` 比较 URL，因为两个不同的 URL 可能关联同一个文件。应该始终在比较之前标准化它们。这一点在 iOS 上尤为重要，在 iOS 中开放性容器存储在 `/var/mobile/Library/Mobile Documents/` 中，这个文件夹是 `/private/var/mobile/Library/Mobile Documents/` 的符号链接。你会收到带有指向同一个文件，基于 *两种路径变体* 的 URL 的展示者通知。如果你对 iCloud 和本地文档使用文件协调代码，这个问题在 OS X 上也会发生。

除此之外，还有几个关于大小写不敏感的文件系统的问题。*如果*文件系统要求，应该始终确保你使用大小写不敏感的文件名比较。文件协调 block 和展示者通知可能传递使用不同大小写的相同的 URL 变体。实际上，这是使用文件协调器重命名时的重要问题。为了搞懂这个问题，你需要回顾文件实际上是如何被重命名的:

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

假设 `sourceURL` 指向一个名为 `~/Desktop/my text` 的文件，`destURL` 使用了大写字母的新文件名 `~/Desktop/My Text`。协调 block 被有意设计成传入两个 URL 的最新版本，以兼容等待文件访问时发生的移动操作。现在，不幸的，当改变文件名的大小写，文件协调所执行的 URL 校验将会发现新旧两个 URL 都存在一个有效文件，而新的 URL 是小写 `~/Desktop/my text` 的变体。访问 block 将会接收到同样的 *小写* URL 作为 `oldURL` 和 `newURL`，导致移动操作失败。

### 请求下载

在 iOS 中，触发从 iCloud 的下载是应用的责任。可以通过 `NSFileManager` 的 [`startDownloadingUbiquitousItemAtURL:error:`](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/nsfilemanager_class/reference/reference.html#//apple_ref/occ/instm/NSFileManager/startDownloadingUbiquitousItemAtURL:error:) 方法触发下载。如果你的应用设计成自动下载文件 (也就是不由用户触发)，你应该始终在一个顺序后台队列中执行这些下载请求。换句话说，每一个单独的下载请求涉及到相当多的进程间通信并可能会很耗时。另一方面，同时触发太多的下载有时会过载 *ubd* 守护进程。一个普遍的错误就是使用 `NSMetadataQuery` 等待 iCloud 中的新文件然后自动触发下载它们。因为查询结果总是在主队列中传递并且可能包含一打的更新信息，直接触发下载会阻塞应用很长一段时间。

为了查询某个文件的下载或者上传状态，你可以使用 `NSURL` 的资源值。在 iOS 7 / OS X 10.9 之前，一个文件的下载状态通过 `NSURLUbiquitousItemIsDownloadedKey` 来确认。根据头文件文档，这个资源值从未正确生效过，所以在 iOS 7 和 Mavericks 中被废弃了。现在苹果建议使用 `NSURLUbiquitousItemDownloadingStatusKey`。在老系统上，你应该使用 `NSMetadataQuery` 查询 `NSMetadataUbiquitousItemIsDownloadedKey` 来获得正确的下载状态。

## 综合考虑

为你的应用增加 iCloud 支持并不只是你增加的另一个功能，而是一个对应用设计和实现有着深远影响的决定。它既影响着你的数据模型也影响着 UI。所以不要低估支持 iCloud 所需要做出的努力。

最重要的，增加 iCloud 会引入一个新的异步层。应用必须能够在任何时候处理文档和元数据的变化。这些变化上的通知可能会在不同线程上收到，这就需要在你的整个应用中添加同步机制来对这些通知进行适当的处理。你需要注意那些对于用户文档完整性有重大影响的关键代码中的问题，比如丢失更新，竞争和死锁等。

始终注意 iCloud 的同步保证是非常脆弱的。你只能假设文件和包是自动同步的。但你不能期望多个同时被修改的文件也会被立刻同步。比如，如果你的应用分开存储元信息和实际的文件的话，你一定要能够应对元信息会先于或晚于实际文件被下载的情况。

使用 iCloud 文档同步同时也意味着你正在做一个发布的应用。你的文档会在运行着不同版本的不同设备上。你可能想要使你文件格式的不同版本向前兼容。起码，你必须确保你的应用在面对其他不同设备上安装的新版本应用创建的文件时不会崩溃或发生错误。用户未必会立刻更新所有的设备，所以预先准备好这个问题。

最后，你的 UI 需要反映同步行为。即使这会抹杀掉一些神奇之处。尤其在 iOS 上，连接失败和缓慢的文件转换是现实状况。你的用户应该被通知关于文档的同步状态。你应该考虑展示文件是在被上传还是在下载，以告知用户他们的文档现在是否可用。使用大文件时，你可能需要显示文件传输进度，你的 UI 应该优雅一些; 如果 iCloud 不能及时给你某个文档，你的应用应该响应，并且让用户重试或至少放弃操作。

## 调试

因为涉及到多系统服务和外部服务，调试 iCloud 问题非常困难。Xcode 5 提供的 iCloud 调试功能非常有限并且大多数时候只会告诉你 iCloud 是否已经同步。幸运的是，还有一些差不多是官方的方法来调试 iCloud 文档存储。

### 在 OS X 上调试

有时你可能经历过 iCould 停止同步某个文件或干脆完全停止工作。实际上，这在文件协调器内使用断点或在一个文件操作进行期间杀掉一个进程时很容易发生。甚至如果你的应用在某个关键点崩溃后也会发生。通常来说，重启或者注销后重新登录 iCloud 都不能修复这个问题。

为了修复这些锁定，一个命令行工具会非常有好处: `ubcontrol`。这个工具是 10.7 以后版本 OS X 的一部分。使用命令 `ubcontrol -x`，你能够重置文档同步的本地状态。它通过重置一些私有数据库和缓存，重启所有涉及到的系统守护进程，来复原熄火的同步。同时它也会存储一些报告分析信息到 `~/Library/Application Support/Ubiquity-backups`。

虽然已经有日志文件被写入 `~/Library/Logs/Ubiquity` 中，你也还可以通过 `ubcontrol -k 7` 来增加日志级别。在进行 iCloud 相关的错误报告时，苹果工程师经常会要求你这么做以便收集信息。

为了调试文件协调，你还可以从文件协调守护进程中直接取回锁状态信息。这使你能够得知在应用中或多进程间可能遇到的文件协调死锁。为了访问这个信息，你需要在终端中执行以下命令:

	sudo heap filecoordinationd -addresses NSFileAccessArbiter
	sudo lldb -n filecoordinationd
	po [<address> valueForKey: @"rootNode"]

第一个命令会返回一个文件协调守护进程的内部单例对象的地址。随后，你关联 *lldb* 到运行的守护进程上。通过使用第一步取回的地址，你将会得到一个所有活动的锁和文件展示者的状态的概览。调试命令会展示当前正在被展示或协调的整个文件树。例如，如果 TextEdit 正在展示一个名为 `example.txt` 的文件，你会得到以下跟踪信息：

	example.txt
		<NSFileAccessNode 0x…> parent: 0x…, name: "example.txt"
		presenters:
			<NSFilePresenterProxy …> client: TextEdit …>
			location: 0x7f9f4060b940
		access claims: <none>
		progress subscribers: <none>
		progress publishers: <none>
		children: <none>


如果你在文件协调进行时创建这种跟踪 (比如通过在文件协调 block 中设置断点)，你还会得到一个等待文件协调器的所有进程的列表。

如果通过 *lldb* 观察文件协调，你应该始终记得尽快执行 `detach` 命令。否则，全局根进程文件协调守护进程将一直等待，这会影响到系统中几乎所有的应用。

### 在 iOS 上调试

在 iOS 上，调试要更加复杂，因为你无法检查运行的系统进程，你也无法使用像 `ubcontrol` 的命令行工具。

iCloud 锁定在 iOS 上似乎更经常发生。重启应用或设备都无效。唯一有效的修复这种问题的方法是 *冷启动*。在冷启动过程中，iOS 似乎进行了 iClouds 的内部数据库重置。可以通过同时按下电源键和 home 键 10 秒钟冷启动设备。

为了在 iOS 上激活更详细的日志，在苹果 [developer downloads page](https://developer.apple.com/downloads) 有一个专用的 iCloud 日志概述。如果搜索 "Bug Reporter Logging Profiles (iOS)"，你将会找到一个叫做 "iCloud Logging Profile" 移动设备概述。在你的 iOS 设备上安装该文件来激活更详细的日志。你可以用 iTunes 同步设备来访问这些日志.随后，你可以在 `Library/Logs/CrashReporter/Mobile Device/<Device Name>/DiagnosticLogs/Ubiquity` 文件夹找到它。如果想要关掉这种加强的日志输出，从设备删除描述文件即可。苹果建议你在激活或关闭概述前重启设备。

### 在 iCloud Servers 上调试

除了在你自己的设备上调试，考虑使用苹果服务上的调试服务可能也会有用。[developer.icloud.com](https://developer.icloud.com/) 上有一个特殊的 web 应用，它允许你浏览存储在开放性容器内的所有信息和当前传输状态。

过去的几个月，苹果还提供了安全地在服务端对所有已连接设备进行 iCloud 重置的方法。更多信息可查看 [support document](http://support.apple.com/kb/HT5824)。

---

 

原文 [Mastering the iCloud Document Store](http://www.objc.io/issue-10/icloud-document-store.html)
