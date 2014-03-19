[Source](http://www.objc.io/issue-10/icloud-document-store.html "Permalink to Mastering the iCloud Document Store - Syncing Data - objc.io issue #10 ")

# Mastering the iCloud Document Store - Syncing Data - objc.io issue #10 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# Mastering the iCloud Document Store

[Issue #10 Syncing Data][4], March 2014

By [Friedrich Gräter][5] & [Max Seelemann][6]

Even three years after its introduction, the iCloud document store is still a topic full of myth, misunderstanding, and resentment. iCloud synching has often been criticized for being unreliable or slow. And while there were imminent bugs in the early days of iCloud, application developers had to learn their lessons about file synchronization, too. File synchronization is non-trivial and brings new aspects to application development — aspects which are often underestimated, such as the requirement to handle asynchronous file changes while being cooperative regarding synchronization services.

This article will give an overview of several common stumbling stones you may find when creating an iCloud-ready application. In case you are not already familiar with the iCloud document store, we strongly recommend reading the [Apple iCloud companion guide][7] first, since this article provides only a rough overview.

## The Document Store in a Nutshell

The core idea of the iCloud document store is pretty simple: every application has access to at least one ‘magic folder’ where it can store files that are then being synchronized across all devices subscribing to the same iCloud account.

In contrast to other file-based syncing services, the iCloud document store benefits from a deep integration with OS X and iOS. Many system frameworks have been extended to support iCloud. Classes like `NSDocument` and `UIDocument` have been designed to deal with external changes. Synchronization conflicts are handled by the Version Store and `NSFileVersion`. Spotlight is employed to provide synchronization metadata like the progress of file transfers or the availability of documents in the cloud.

It does not take much to write a simple, document-based, iCloud-enabled application on OS X. Actually, you don’t need to care about any of the inner workings of iCloud, as `NSDocument` delivers almost everything for free: it coordinates document accesses with iCloud, automatically watches for external changes, triggers downloads, and handles conflicts. It even provides a simple user interface for managing cloud documents through the default open panel. All you need to do is to be a good `NSDocument` subclass citizen and to implement the required methods for reading and writing file contents.

![NSDocument provides a simple user interface for managing the synchronized documents of an app.][8]

However, as soon as you leave the predefined path, you have to know a lot more. For example, everything beyond the single-level folder hierarchy provided by the default open panel has to be done manually. Maybe your application needs to manage its documents beside the documents contents, like it is done in Mail, iPhoto, or [Ulysses][9] (our own app). In these cases, you cannot rely on `NSDocument` and need to implement its functionality on your own. But for that you have to have a deep understanding of the locking and notification mechanisms employed by iCloud.

Developing iCloud-ready apps for iOS also requires more work and knowledge; while `UIDocument` still manages file access with iCloud and handles synchronization conflicts, it lacks any user interface for managing documents and folders. For performance and storage reasons, iOS does also not automatically download new documents from the cloud. Instead, you need to query for recent changes of the directory using Spotlight and trigger downloads manually.

## What’s in a Ubiquity Container?

Any application that is eligible for App Store provisioning can use the iCloud document store. After setting the correct [entitlements][10], it gains access to one or multiple so-called ‘ubiquity containers.’ This is Apple slang for “a directory that is managed and synced by iCloud.” Each ubiquity container is bound to an application identifier, resulting in one shared storage per user per app. Developers who have multiple apps may specify multiple app identifiers (of the same team), and by that gain access to multiple containers.

`NSFileManager` provides the URL of each container through [`URLForUbiquityContainerIdentifier:`][11]. On OS X, it is possible to inspect all available ubiquity containers by opening the directory `~/Library/Mobile Documents`.

![The contents of ”~/Library/Mobile Documents.“ It contains a separate folder for each ubiquity container of each application.][12]

Typically, there are two processes concurrently accessing each ubiquity container. First, there is the application that is presenting and manipulating the documents inside the container. Second, there is the infrastructure of iCloud, which is mostly represented through the Ubiquity Daemon (_ubd_). The iCloud infrastructure waits for changes performed by the application and uploads them to Apple’s cloud servers. It also waits for incoming changes on iCloud and may modify the contents of the ubiquity container accordingly.

Since both entities are working completely independent from one another, some kind of arbitration is needed to prevent race conditions or lost updates on files inside the container. To guarantee access to an isolated file, applications need to use a concept called _[file coordination_][13] for every access. This access is provided by the [`NSFileCoordinator`][14] class. In a nutshell, it provides a simple reader-writer lock for files. This lock is extended by a notification mechanism that is supposed to improve cooperation across different processes accessing the same files.

This notification mechanism is an essential advantage over simple file locks and allows for a seamless user experience. iCloud may replace a document by a new version from another device at any time. If an application is currently showing the same document, it must load the new version from disk and show the updated contents to the user. During the update, the application may need to lock the user interface for a while and enable it again afterward. Even worse scenarios may happen: the application may hold unsaved contents, which need to be saved to disk _first_ in order to detect synchronization conflicts. Finally, iCloud may be interested in uploading the most recent version of a file if good network conditions are available. Thus, it must be able to query an application to flush all unsaved changes immediately.

For these negotiations, file coordination is accompanied by another mechanism called _file presentation_. Whenever an application opens a file and shows it to the user, it is said to be _presenting the document_ and should register an object implementing the [`NSFilePresenter`][15] protocol. The file presenter receives notifications about the presented file whenever another process accesses it through a file coordinator. These notifications are delivered as method calls, which are performed asynchronously on an operation queue specified by the presenter ([`presentedItemOperationQueue`][16]).

For example, before any other process is allowed to start a coordinated read operation, the file presenter will be asked to persist any unsaved changes. This is done by dispatching a block on its presentation queue calling the method [`savePresentedItemChangesWithCompletionHandler:`][17]. The presenter may then save the file and confirm the notification by executing a block that has been passed as argument to the notification handler. Aside from change notifications, file presenters are also used to notify the application on synchronization conflicts. Whenever a conflicting version of a file has been downloaded, a new file version is added to the Versions store. All presenters are notified that a new version has been created through [`presentedItemDidGainVersion:`][18]. This callback receives an `NSFileVersion` instance referencing potential conflicts.

File presenters can be also used if your application needs to monitor folder contents. For instance, whenever iCloud is changing the contents of a folder, e.g. by creating, deleting, or moving files, the application should be notified to update its documents overview. For this purpose, the application can register an instance implementing the `NSFilePresenter` protocol for a presented directory. A file presenter on a directory will be notified of any changes in the folder or any files nested to it or to its subfolders. For example, if a file inside the folder has been modified, the presenter will receive a `presentedSubitemDidChangeAtURL:` notification referencing the URL of the modified file.

Since bandwidth and battery life are much more limited on mobile devices, iOS will not download new files automatically from iCloud. Instead, applications must decide manually when to trigger downloads of new files to the ubiquity container. To continue providing the application an overview of which files are available, as well as their current synchronization status, iCloud also synchronizes metadata for files inside the ubiquity container. An application may query this metadata by using an `NSMetadataQuery` or by accessing the ubiquity resource attributes of `NSURL`. Whenever the application wants to get access to a file’s contents, it must trigger a download explicitly through `NSFileManager`’s [`startDownloadingUbiquitousItemAtURL:error:`][19].

## Inside the Depths of iCloud

Instead of continuing to explain how to implement file coordination and observation, we will now dive into common problems we have encountered over the last few years. Again, please make sure you have read and understood the [Apple iCloud companion guide][7] for documents in the cloud.

While the description of those file mechanisms makes their use sound pretty straightforward, there are many hidden pitfalls. And some of these pitfalls originate from bugs inside the underlying frameworks. Since iCloud syncing is spread on quite a few levels of the operating system, one can expect that Apple will be fixing bugs very carefully. Actually, Apple even seems to prefer deprecating broken APIs over providing bug fixes.

Even so, it’s our experience that it is also very, very easy to make mistakes. The asynchronous, cooperative, and lock-based nature of file coordination and file presentation has implications that are often not easy to grasp. In the following, we would like to share our experiences in the form of a couple of general rules to follow when manually integrating iCloud document syncing.

### Use Presenters only when Necessary

File presenters can be very expensive objects. They should only be used if your application needs to be able to react to or intervene in external file accesses immediately.

If your application is currently presenting something like a document editor to the user, file presentation is adequate. In this case, your application may need to lock the editor while other processes are writing, or it may need to flush any unsaved changes to disk. However, if only temporary access is needed and notifications may be processed lazily, your application should not use file presentation. For instance, when indexing a file or creating a thumbnail, watching change dates and using simple file coordination will probably be sufficient. Also, if you are presenting the contents of a directory tree, it may be completely sufficient to register a _single_ presenter at the root of the tree or to use an `NSMetadataQuery` to be lazily notified of any changes.

What makes file presentation so expensive? Well, it requires a lot of interprocess communication: each file presenter registered to a file must be asked to relinquish the presented file before other processes get access to that file. For example, if another process tries to read a certain file, its presenters will be asked to save all unsaved changes ([`savePresentedItemChangesWithCompletionHandler:`][17]). They are also asked to relinquish the file to the reader ([`relinquishPresentedItemToReader:`][20]), e.g. to temporary lock editors while the file is read.

Each of these notifications need to be dispatched, processed, and confirmed by their respective receivers. And since only the implementing process knows which notifications will be handled, interprocess communication will happen for every possible notification, even if a presenter does not implement any of those methods.

Additionally, multiple context switches between the reading process, the presenting process, and the file coordination daemon (`filecoordinationd`) are required for each step. As a result, a simple file access can quickly become a very expensive operation.

On top of all that, the file coordination daemon can deplete critical system resources if too many presenters have been registered. For each presenter, it needs to open and observe every folder on the path of the presented item. Especially on OS X Lion and iOS 5, these resources were very scarce, and an overuse could easily have led to a full lockdown or crash of the file coordination daemon.

For these reasons, we strongly recommend not adding file presenters on every node inside a directory tree, rather only using as few file presenters as needed.

### Use Coordination only if Necessary

While file coordination is way cheaper than file presentation, it still adds an additional overhead to your application and to the entire system.

Whenever your application is coordinating a file access, other processes trying to access the same file at the same time may need to wait. Therefore, you should never perform any lengthy task while coordinating a file. If you are, for instance, saving large files, you may consider saving them to a temporary folder first and then just swizzling hard links during a coordinated access. Keep in mind that every coordinated access may trigger a file presenter inside another process — a presenter that may need time to update the file in advance to your access. Always consider the usage of flags like `NSFileCoordinatorReadingWithoutChanges` if it’s not required to read the most recent version of a file.

While the ubiquity container of your app will probably not be accessed by other applications, exaggerated file coordination may still become a problem with iCloud, and performing many coordination requests may lead to a starvation of system processes like `ubd`. During the startup phase of an application, `ubd` seems to scan through all files inside your ubiquity container. If your application is performing the same scan during program startup, both processes may often collide, which may lead to a high coordination overhead. It’s wise to consider more optimistic approaches in this case. For example, when scanning directory contents, isolated access to a file’s contents may not be required at all. Instead, defer the coordination until the file’s contents are actually being presented.

Finally, never coordinate a file that has not been downloaded yet. File coordination will trigger the downloading of files. Unfortunately, the coordination will wait until the download has been completed, which may block an application for an incalculable period of time. Before accessing a file, an app should verify the file’s download state. You can do this by querying the URL’s resource value `NSURLUbiquitousItemDownloadingStatusKey` or using an `NSMetadataQuery`.

### Some Remarks on Coordination Methods

Reading the documentation of `NSFileCoordinator`, you may notice that many method calls have a lengthy and complicated description. While the API is generally very conclusive, it has a high complexity due to the variety of interactions with other coordinators and file presenters, as well as the differing semantics for folder and file locking. Throughout these lengthy descriptions there are several details and issues that may be easily missed:

  1. Take coordination options seriously. They really influence the behavior of file coordinators and file presenters. For example, if the flag `NSFileCoordinatorWritingForDeleting` is not provided, file presenters will not be able to influence the deletion of a file through `accommodatePresentedItemDeletionWithCompletionHandler:`. If `NSFileCoordinatorWritingForMoving` is not used when moving directories, the move operation will not wait for ongoing coordinations on subitems to be finished.

  2. Always expect that coordination calls may fail and return errors. Since file coordination interacts with iCloud, a coordination call may fail with an error message if the coordinated file cannot be downloaded, and your actual file operation may not be performed. If error handling is not correctly implemented, your application may not notice problems like this.

  3. Verify a file’s state after entering coordination blocks. A lot of time may pass after the request for the coordination. In the meantime, preconditions that lead an application to perform a file operation may have become false. Information you are going to write could have become stale until the lock is granted. It could also be possible that your file has been deleted while you’ve waited to get write access. In this case, you might accidentally recreate the deleted file.

### Notification Deadlocks

Implementing notification handlers of `NSFilePresenter` requires special attention. Some notifications, such as `relinquishPresentedItemToReader:`, must be confirmed to signal to other processes that a file is ready for access. Typically, this is done by executing a confirmation block passed as an argument to the notification handler. It is important to know that, until the confirmation block is called, the other process has to wait. If the confirmation is delayed due to slow notification processing, the coordinating process may stall. If it is never executed, it will probably hang forever.

Unfortunately, notifications that need to be confirmed can also be slowed done by other, completely independent notifications. To ensure notifications are being processed in the correct order, the `presentedItemOperationQueue` is usually configured as a sequential queue. However, using a sequential queue means that slowly processed notifications will delay their succeeding notifications. In particular, they may slow down succeeding notifications that require a confirmation, and by that, any process waiting for them.

For example, assume a notification like `presentedItemDidChange` has been enqueued first. A lengthy processing of this callback may stall other notifications, like `relinquishPresentedItemToReader:`, that have been enqueued shortly after. As a consequence, the confirmation of this notification will also be delayed, which in turn stalls the process waiting for it.

Above all, _never_ perform any file coordination while inside a presentation queue. In fact, even simple notifications without any confirmation needs (e.g. `presentedItemDidChange`) can cause deadlocks. Just imagine two file presenters presenting the same file. Both presenters are handling the notification `presentedItemDidChange` by performing a coordinated read operation on the presented file. If the file has been changed, this notification is sent to both presenters and both presenters perform a coordinated read on the same file. As a consequence, both presenters query each other to relinquish the file by enqueuing a `relinquishPresentedItemToReader:` and wait for each other to confirm this notification. Unfortunately, both presenters are unable to confirm the notification since both are blocking their presentation queues by the coordination request waiting forever on the other’s confirmation. We’ve prepared a small example exploiting this deadlock on [GitHub][21].

### Defective Notifications

Drawing the correct conclusions from notifications is not always easy. There are bugs inside file presentation causing some notification handlers to _never be called_. Here is a short glimpse off known misbehaving notifications:

  1. Aside from `presentedSubitemDidChangeAtURL:` and `presentedSubitemAtURL:didMoveToURL:`, all subitem notifications are either never called or called in a very unpredictable way. Don’t rely on them at all — in particular, `presentedSubitemDidAppearAtURL:` and `accommodatePresentedSubitemDeletionAtURL:completionHandler:` will never be called.
  2. `accommodatePresentedItemDeletionWithCompletionHandler:` will only work if the deletion was performed through a file coordination that used the `NSFileCoordinatorWritingForDeleting` flag. Otherwise, you may not even receive a change notification.
  3. `presentedItemDidMoveToURL:` and `presentedSubitemAtURL:didMoveToURL` will only be sent if `itemAtURL:didMoveToURL:` was called by the moving file coordinator. If not, items will not receive any useful notifications. Subitems may still receive two separate `presentedSubitemDidChange` notifications for the old and new URLs.
  4. Even if files have been moved correctly and a `presentedSubitemAtURL:didMoveToURL` notification was sent, you will still receive two additional `presentedSubitemDidChangeAtURL:` notifications for the old and new URL. Be prepared for that.

Generally, you have to be aware that notifications may be outdated. You should also not rely on any specific ordering of notifications. For example, when presenting a directory tree, you may not expect that notifications regarding a parent folder will appear before or after notifications on one of its subitems.

### Be Aware of URL Changes

There are several situations where you need to be prepared in case file coordinators and file presenters deliver multiple variants of the same URL referencing the same file. You should never compare URLs using `isEqual:`, because two different URLs may still reference the same file. You should always standardize URLs before comparing them. This is especially important on iOS, where ubiquity containers are stored in `/var/mobile/Library/Mobile Documents/`, which is a symbolically linked folder for `/private/var/mobile/Library/Mobile Documents/`. You will receive presenter notifications with URLs based on _both path variants_ that still reference the same file. This issue can also occur on OS X if you are using file coordination code for iCloud and local documents.

Beyond that, there are also several issues on case-insensitive file systems. You should always make sure that you perform a case-insensitive comparison of filenames _if_ the file system requires it. File coordination blocks and presenter notifications may deliver variants of the same URL using different casings. In particular, this an important issue when renaming files using file coordinators. To understand this issue, you need to recall how files are actually renamed:


    [coordinator coordinateWritingItemAtURL:sourceURL
                                    options:NSF
                           writingItemAtURL:destURL
                                    options:0
                                      error:NULL
                                 byAccessor:^(NSURL *oldURL, NSURL *newURL)
    {
    	[NSFileManager.defaultManager moveItemAtURL:oldURL toURL:newURL error:NULL];
    	[coordinator itemAtURL:oldURL didMoveToURL:newURL];
    }];

Assume `sourceURL` references a file named `~/Desktop/my text` and `destURL` references the new filename written in upper case: `~/Desktop/My Text`. By design, the coordination block will be passed the most recent version of both URLs in order to accommodate move operations that happened while waiting for file access. Now, unfortunately, when changing a filename’s case, the URL’s validation performed by file coordination will find an existing valid file for both the old and the new URL, which is the lowercase variant `~/Desktop/my text`. The access block will receive the same _lowercase_ URL as `oldURL` and `newURL`, leading to a failure of the move operation.

### Requesting Downloads

On iOS, it’s the application’s responsibility to trigger downloads from iCloud. Downloads can be triggered through the method [`startDownloadingUbiquitousItemAtURL:error:`][19] of `NSFileManager`. If your application is designed to download files automatically (i.e. not triggered by the user), you should always perform those download requests from a sequential background queue. On the one hand, each single download request involves quite a bit of interprocess communication and may take up to a second. On the other hand, triggering too many downloads at once seems to overload the _ubd_ daemon at times. A common mistake is to wait for new files in iCloud using an `NSMetadataQuery` and automatically trigger a download for them. Since the query result is always delivered on the main queue and it can contain updates for dozens of files, directly triggering downloads will block an application for a long time.

To query the download or upload status of a certain file, you can use resource values of `NSURL`. Before iOS 7 / OS X 10.9, the download status of a file was made available through `NSURLUbiquitousItemIsDownloadedKey`. According to its header documentation, this resource value never worked correctly, and so it was deprecated in iOS 7 and Mavericks. Apple now recommends to use `NSURLUbiquitousItemDownloadingStatusKey`. On older systems, you should use an `NSMetadataQuery` and query for `NSMetadataUbiquitousItemIsDownloadedKey` to get the correct download status.

## General Considerations

Adding support for iCloud to your application is not just another feature you’re adding. Instead, it is a decision that has far-reaching consequences on the design and implementation of your application. It influences your data model as well as the user interface. So don’t underestimate the efforts of properly supporting iCloud.

Most importantly, adding iCloud will introduce a new level of asynchrony to an application. The application must be able to deal with changes on documents and metadata at any time. Notifications on those changes may be received by different threads, raising the need for synchronization primitives across your entire application. You need to be aware of issues in code that are critical for the integrity of a user’s documents, like lost updates, race conditions, and deadlocks.

Always keep in mind that synchronization guarantees of iCloud are very weak. You can only assume that files and packages are synchronized atomically. But you cannot expect that multiple files modified simultaneously are also synchronized at once. For example, if your application stores meta information separate from the actual files, it must be able to cope with the fact that this metadata will be downloaded earlier or later than the actual files.

Using the iCloud document sync also means that you’re writing a distributed application. Your documents will be processed on different devices running different versions of your application. You may want to be forward-compatible with different versions of your file format. At the very least, you must ensure your application will not crash or fail if it faces a file generated by a newer version of your application installed on a different device. Users may not update all devices at once, so be prepared for that.

Finally, your user interface needs to reflect synchronization, even though it may kill some of the magic. Especially on iOS, connection failures and slow file transfers are a reality. Your users need to be informed about the synchronization status of documents. You should consider showing whether files are currently uploading or downloading, in order to give users an idea of the availability of their documents. When using large files, you may need to show progress of file transfers. Your user interface should be graceful; if iCloud can’t serve you a certain document in time, your application should still be responsive and let the user retry or at least abort the operation.

## Debugging

Due to the involvement of multiple system services and external servers, debugging iCloud issues is quite difficult. The iCloud debugging capabilities provided by Xcode 5 are limited and mostly just give a glimpse of whether iCloud sync is happening or not. Fortunately, there are some more or less official ways of debugging the iCloud document store.

### Debugging on OS X

Every now and then, you may experience iCloud stopping syncing of a certain file or even stopping to work completely. In particular, this happens easily when using debug breakpoints inside file coordinators or when killing a process during an ongoing file operation. It may even happen to your customers if your application crashed at such critical points. Often, neither rebooting nor logging out and back in to iCloud fixes the issue.

To fix these lockdowns, one command-line utility can be very beneficial: `ubcontrol`. This utility is part of every OS X release since 10.7. Using the command `ubcontrol -x`, you are able to reset the local state of document syncing. It will revive stalled synchronizations by resetting some private databases and caches and restarting all involved system daemons. It also stores some kind of post-mortem information inside `~/Library/Application Support/Ubiquity-backups`.

While there are already very extensive log files written to `~/Library/Logs/Ubiquity`, you may also increase the logging level through `ubcontrol -k 7`. You are usually asked by Apple engineers to do this for collecting information on an iCloud-related bug report.

For debugging file coordination issues, you can also directly retrieve lock status information from inside the file coordination daemon. This enables you to understand file coordination deadlocks that may occur inside your application or between multiple processes. To access this information you need to execute the following commands in Terminal:


    sudo heap filecoordinationd -addresses NSFileAccessArbiter
    sudo lldb -n filecoordinationd
    po [ valueForKey: @"rootNode"]

The first command will return you the address of an internal singleton object of the file coordination daemon. Afterward, you attach _lldb_ to the running daemon. By using the retrieved address from the first step, you will get an overview on the state of all active locks and file presenters. The debugger command will show you the entire tree of files that are currently being presented or coordinated. For example, if TextEdit is presenting a file called `example.txt` you will get the following trace:


    example.txt
    	 parent: 0x…, name: "example.txt"
    	presenters:
    		 client: TextEdit …>
    		location: 0x7f9f4060b940
    	access claims: 
    	progress subscribers: 
    	progress publishers: 
    	children: 

If you create such traces while a file coordination is going on (e.g. by setting a break point inside a file coordination block), you will also get a list of all processes waiting for file coordinators.

If you’re inspecting file coordination through _lldb_, you should always remember to execute the `detach` command as soon as possible. Otherwise, the global root process file coordination daemon will stay stopped, which will stall almost any application in your system.

### Debugging on iOS

On iOS, debugging is more complicated, because you can’t inspect running system processes and you can’t use command-line tools like `ubcontrol`.

Lockdowns of iCloud seem to occur even more often on iOS. Neither restarts of the application nor simple device reboots help. The only effective way to fix such issues is a _cold boot_. During a cold boot, iOS seems to perform a reset of iCloud’s internal databases. A device can be cold-booted by pressing the power and home button at the same time for 10 seconds.

To activate extensive logging on iOS, there exists a special iCloud logging profile on Apple’s [developer downloads page][22]. If you’re searching for “Bug Reporter Logging Profiles (iOS),” you will find a mobile device profile called “iCloud Logging Profile.” Install this profile on your iOS device to activate extensive logging. You can access these logs by syncing your device with iTunes. Afterward, you will find it inside the folder `Library/Logs/CrashReporter/Mobile Device//DiagnosticLogs/Ubiquity`. To deactivate intensive logging, just delete the profile from the device. Apple recommends you reboot your device before activation and after deactivation of the profile.

### Debugging on iCloud Servers

Aside from debugging on your own devices, it might also be helpful to consider the debugging services on Apple’s servers. A particular web application is located at [developer.icloud.com][23], and it allows you to browse all information stored inside your ubiquity container, as well as the current transfer status.

For the past few months, Apple has also offered a safe server-side reset of iCloud syncing on all connected devices. For details, please have a look at this [support document][24].




* * *

[More articles in issue #10][25]

  * [Privacy policy][26]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-10/index.html
   [5]: https://twitter.com/hdrxs
   [6]: http://twitter.com/macguru17
   [7]: https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesigningForDocumentsIniCloud.html (Designing For Documents in the Cloud)
   [8]: http://www.objc.io/images/issue-10/Open.png
   [9]: http://www.ulyssesapp.com
   [10]: https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html#//apple_ref/doc/uid/TP40012094-CH6-SW13
   [11]: https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/nsfilemanager_class/reference/reference.html#//apple_ref/occ/instm/NSFileManager/URLForUbiquityContainerIdentifier:
   [12]: http://www.objc.io/images/issue-10/Mobile%20Documents.png
   [13]: https://developer.apple.com/library/ios/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileCoordinators/FileCoordinators.html#//apple_ref/doc/uid/TP40010672-CH11-SW1
   [14]: https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFileCoordinator_class/Reference/Reference.html
   [15]: https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html
   [16]: https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfp/NSFilePresenter/presentedItemOperationQueue
   [17]: https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfm/NSFilePresenter/savePresentedItemChangesWithCompletionHandler:
   [18]: https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfm/NSFilePresenter/presentedItemDidGainVersion:
   [19]: https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/nsfilemanager_class/reference/reference.html#//apple_ref/occ/instm/NSFileManager/startDownloadingUbiquitousItemAtURL:error:
   [20]: https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSFilePresenter_protocol/Reference/Reference.html#//apple_ref/occ/intfm/NSFilePresenter/relinquishPresentedItemToReader:
   [21]: https://github.com/hydrixos/DeadlockExample
   [22]: https://developer.apple.com/downloads
   [23]: https://developer.icloud.com/
   [24]: http://support.apple.com/kb/HT5824
   [25]: http://www.objc.io/issue-10
   [26]: http://www.objc.io/privacy.html
