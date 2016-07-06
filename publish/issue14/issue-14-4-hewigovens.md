## 关于 XPC

XPC 是 OS X 下的一种 IPC (进程间通信) 技术, 它实现了权限隔离, 使得 App Sandbox 更加完备.

首先，XPC 更多关注的是实现功能某种的方式，通常采用其他方式同样能够实现。并没有强调如果不使用 XPC，无法实现某些功能。

XPC 目的是提高 App 的安全性和稳定性。XPC 让进程间通信变得更容易，让我们能够相对容易地将 App 拆分成多个进程的模式。更进一步的是，XPC 帮我管理了这些进程的生命周期，当我们需要与子进程通信的时候，子进程已经被 XPC 给运行起来了。

我们将使用在头文件 `NSXPCConnection.h` 中声明的 Foundation framework API，它是建立在头文件 `xpc/xpc.h` 中声明的原始 XPC API 之上的。XPC API 原本是纯 C 实现的 API，很好地集成了 libdispatch（又名 GCD）。本文中我们将使用Foundation 中的类，它们可以让我们使用 XPC 的几乎全部功能（真实的表现了实际底层 C API 是如何工作的），同时与 C API 相比，Foundation API 使用起来会更加容易。

### 哪些地方用到了 XPC ？

Apple 在操作系统的各个部分广泛使用了 XPC，很多系统 Framework 也利用了 XPC 来实现其功能。你可以在命令行运行如下搜索命令：

    % find /System/Library/Frameworks -name \*.xpc

结果显示 Frameworks 目录下有 55 个 XPC service（译者注：在 Yosemite 下），范围从 AddressBook 到 WebKit 等等。

如果在 `/Applications` 目录下做同样的搜索，我们会发现从 [iWork 套件](https://www.apple.com/creativity-apps/mac/)到 Xcode，甚至是一些第三方应用程序都使用了 XPC。

Xcode 本身就是使用 XPC 的一个很好的例子：当你在 Xcode 中编辑 Swift 代码的时候，Xcode 就是通过 XPC 与 SourceKit 通信的（译者注：实际进程名应该是SourceKitService）。SourceKit 是主要负责源代码解析，语法高亮，排版，自动完成等功能的 XPC service。更多详情可以参考 [JP Simard 的博客](http://www.jpsim.com/uncovering-sourcekit/).

其实 XPC 在 iOS 上应用的很广泛 - 但是目前只有 Apple 能够使用，第三方开发者还不能使用。

## 一个示例 App

让我们来看一个简单的示例：一个在 table view 中显示多张图片的 App。图片是以 JPEG 格式从网络服务器上下载下来的。

App看起来是这样：

![image](/images/issues/issue-14/xpc-SuperfamousImages-window.jpg)

`NSTableViewDataSource` 会从 `ImageSet` 类加载图片 ，像这样：

    func tableView(tableView: NSTableView!, viewForTableColumn tableColumn: NSTableColumn!, row: Int) -> NSView! {
        let cellView = tableView.makeViewWithIdentifier("Image", owner: self) as NSTableCellView
        var image: NSImage? = nil
        if let c = self.imageSet?.images.count {
            if row < c {
                image = self.imageSet?.images[row]
            }
        }
        cellView.imageView.image = image
        return cellView
    }

`ImageSet` 类有一个简单的属性：

    var images: NSImage![]

`ImageLoader` 类会异步的填充这个图片数组。

### 不使用XPC

如果不使用XPC，我们可以这样实现 `ImageLoader` 类来下载并解压图片：


    class ImageLoader: NSObject {
        let session: NSURLSession
    
        init()  {
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            session = NSURLSession(configuration: config)
        }
    
        func retrieveImage(atURL url: NSURL, completionHandler: (NSImage?)->Void) {
            let task = session.dataTaskWithURL(url) {
                maybeData, response, error in
                if let data: NSData = maybeData {
                    dispatch_async(dispatch_get_global_queue(0, 0)) {
                        let source = CGImageSourceCreateWithData(data, nil).takeRetainedValue()
                        let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil).takeRetainedValue()
                        var size = CGSize(
                            width: CGFloat(CGImageGetWidth(cgImage)),
                            height: CGFloat(CGImageGetHeight(cgImage)))
                        let image = NSImage(CGImage: cgImage, size: size)
                        completionHandler(image)
                    }
                }
            }
            task.resume()
        }
    }

明确而且工作得很好。

### 错误隔离 (Fault Isolation) 和 权限隔离 (Split Privileges)

我们的 App 做了三件不同的事情：从互联网上下载数据，解码为 JPEG，然后显示。

如果把 App 拆分成三个独立的进程，我们就能给每个进程单独的权限了；UI 进程并不需要访问网络的权限。图片下载的进程的确需要访问网络，但它不需要访问文件的权限（它只是转发数据，并不做保存）。而将 JPEG 图片解码为 RGB 数据的进程既不需要访问网络的权限，也不需要访问文件的权限。

通过这种方式，在我们的 App 中寻找安全漏洞的行为已经变得很困难了。另一个好处是，我们的 App 会变得更稳定；例如下载 service 因为 bug 导致的 crash 并不会影响 App 主进程的运行；而下载 service 会被重启。

架构图如下：

![image](/images/issues/issue-14/xpc-app-2-services.png)

XPC 的使用十分灵活，我们还可以这样设计：让 App 直接和两个 service 通信，由 App 来负责 service 之间的数据交互。后面我们会看到 App 是如何[找到 XPC services](#service-lookup)的。

迄今为止，大部分安全相关的 bug 都出现在解析不受信数据的过程当中，例如数据是我们从互联网上接收到的，不受我们控制的。现实中 HTTP 协议和解析 JPEG 数据也需要处理这样的问题，而通过这样设计，我们将解析不受信数据的过程挪进了一个子进程，即一个 XPC service。

### 在 App 中使用 XPC Services

XPC service 由两个部分组成：service 本身，以及与之通信的代码。它们都很简单而且相似，算是个好消息。

在 Xcode 中有模板可以添加新的 XPC service target。
每个 service 都需要一个 bundle id，一个好的实践是将其设置为 App 的 bundle id 的 *subdomain*(*子域*)。

在我们的例子中，App 的 bundle id 是 `io.objc.Superfamous-Images`，我们可以把下载 service 的 bundle id 设为 `io.objc.Superfamous-Images.ImageDownloader`。

在 build 过程中，Xcode 会为 service target 创建一个独立 bundle，这个 bundle 会被复制到 `XPCServices` 目录下，与 `Resources` 目录平级。

当 App 将数据发给 `io.objc.Superfamous-Images.ImageDownloader` 这个 service 时，XPC 会自动启动这个 service。

基于 XPC 的通信基本都是异步的。我们通过一个 App 和 service 都使用的 protocol 来进行定义。在我们的例子中：

    @objc(ImageDownloaderProtocol) protocol ImageDownloaderProtocol {
        func downloadImage(atURL: NSURL!, withReply: (NSData?)->Void)
    }

请注意 `withReply:` 这部分。它表明了消息是如何通过异步的方式回给调用方的。若返回的消息带有数据，需要将函数签名最后一部分写成：`withReply:` 并接受一个闭包参数的形式。

在我们的例子中，service 只提供了一个方法；但是我们可以在 protocol 里定义多个方法。

App 到 service 的连接是通过创建 `NSXPCConnection` 对象来完成的，像这样：

    let connection = NSXPCConnection(serviceName: "io.objc.Superfamous-Images.ImageDownloader")
    connection.remoteObjectInterface = NSXPCInterface(`protocol`: ImageDownloaderProtocol.self)
    connection.resume()

我们可以把 connection 对象保存为 `self.imageDownloadConnection`，这样之后就可以像这样和 service 进行通信了：

    let downloader = self.imageDownloadConnection.remoteObject as ImageDownloaderProtocol
    downloader.downloadImageAtURL(url) {
        (data) in
        println("Got \(data.length) bytes.")
    }

我们还应该给 connection 对象设置错误处理函数，像这样：

    let downloader = self.imageDownloadConnection.remoteObjectProxyWithErrorHandler {
        	(error) in NSLog("remote proxy error: %@", error)
    } as ImageDownloaderProtocol
    downloader.downloadImageAtURL(url) {
        (data) in
        println("Got \(data.length) bytes.")
    }

这就是 App 端的所有代码了。

### 监听service请求

XPC service 通过 `NSXPCListener` 对象来监听从 App 传入的请求（译者注：这是 `NSXPCListenerDelegate` 中可选的方法）。listener 对象会给每个来自 App 的请求在 service 端创建对应的 connection 对象。

在 `main.swift` 中，我们可以这样写：

    class ServiceDelegate : NSObject, NSXPCListenerDelegate {
        func listener(listener: NSXPCListener!, shouldAcceptNewConnection newConnection: NSXPCConnection!) -> Bool {
            newConnection.exportedInterface = NSXPCInterface(`protocol`: ImageDownloaderProtocol.self)
            var exportedObject = ImageDownloader()
            newConnection.exportedObject = exportedObject
            newConnection.resume()
            return true
        }
    }
    
    // Create the listener and run it by resuming:
    let delegate = ServiceDelegate()
    let listener = NSXPCListener.serviceListener()
    listener.delegate = delegate;
    listener.resume()


我们创建了一个全局（相当于 C 或 Objective-C 中的 `main` 函数）的 `NSXPCListener` 对象，并设置了它的 delegate，这样传入连接就会调用我们的 delegate 方法了。我们需要给 connection 设置 App 端中同样使用的 protocol。最后我们设置 `ImageDownloader` 实例，它实际上实现了接口：

    class ImageDownloader : NSObject, ImageDownloaderProtocol {
        let session: NSURLSession
    
        init()  {
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            session = NSURLSession(configuration: config)
        }
    
        func downloadImageAtURL(url: NSURL!, withReply: ((NSData!)->Void)!) {
            let task = session.dataTaskWithURL(url) {
                data, response, error in
                if let httpResponse = response as? NSHTTPURLResponse {
                    switch (data, httpResponse) {
                    case let (d, r) where (200 <= r.statusCode) && (r.statusCode <= 399):
                        withReply(d)
                    default:
                        withReply(nil)
                    }
                }
            }
            task.resume()
        }
    }

值得注意的一个重要是，`NSXPCListener` 和 `NSXPCConnection` 默认是挂起 (suspended) 的。我们设置好后需要调用它们的 `resume` 方法来启动。

在[GitHub](https://github.com/objcio/issue-14-xpc)上可以找到这个简单的示例App。

## 监听者 (Listener)，连接 (Connection) 和导出对象 (Exported Object)

在 App 端，我们有一个 connection 对象。每次将数据发给 service 时，我们需要调用 `remoteObjectProxyWithErrorHandler` 方法来创建一个远程对象代理 (remote object proxy)。

而在service端，则多了一层。首先需要一个 listener，用来监听来自 App 的传入 connection。App 可以创建多个 connection，listener 会在 service 端建立相应的 connection 对象。每个 connection 对象都有唯一的 exported object，在 App 端，通过 remote object proxy 发送的消息就是给它的。

当 App 创建一个到 XPC service 的 connection 时，是 XPC 在管理这个 service 的生命周期，service 的启动与停止都由 XPC runtime 完成，这对 App 来说是透明的。而且如果 service 因为某种原因 crash 了，也会透明地被重启。

App 初始化 XPC connection 的时候，XPC service 并不会启动，直到 App 实际发送的第一条消息到 remote object proxy 时才启动。如果当前没有未结束的响应，系统可能会因为内存压力或者 XPC service 已经闲置了一段时间而停止这个 service。这种情况下，App 持有的 connection 对象任然有效，下次再使用这个 connection 对象的时候，XPC 系统会自动重启对应的 XPC service。

如果 XPC service crash 了，它也会被透明地重启，并且其对应的 connection 也会一直有效。但是如果 XPC service 是在接收消息时 crash 了的话，App 需用重新发送该消息才能接受到对应的响应。这就是为什么要调用 `remoteObjectProxyWithErrorHandler` 方法来设置错误处理函数了。

这个方法接受一个闭包作为参数，在发生错误的时候被执行。XPC API 保证在错误处理里的闭包或者是消息响应里的闭包之中，只有一个会被执行；如果消息消息响应里的闭包被执行了，那么错误处理的就不会被执行，反之亦然。这样就使得资源清理变得容易了。

<a name="sudden-termination"> </a>
### 突然终止 (Sudden Termination)

XPC 是通过跟踪那些是否有仍在处理请求来管理 service 的生命周期的，如果有请求正在*运行*，对应的 service 不会被停止。如果消息请求的响应还没有被发送，则这个请求会被认为是正在运行的。对于那些没有 `reply` 的处理程序的请求，只要方法体还在运行，这个请求就会被认为是正在运行的。

在某些情况下，我们可能想告诉 XPC 我们还有更多的工作要做，我们可以使用 `NSProcessInfo` 的 API 来实现这一点：

    func disableAutomaticTermination(reason: String!)
    func enableAutomaticTermination(reason: String!)

如果 XPC service 接受传入请求并需要在后台执行一些异步操作，这些 API 就能派上用场了（即告诉系统不希望被突然终止）。某些情况下我们还可能需要调整我们的 [QoS (服务质量)](#quality-of-service)设置。

### 中断 (Interruption) 和失效 (Invalidation)

XPC 的最常见的用法是 App 发消息给它的 XPC service。XPC 允许非常灵活的设置。我们通过下文会了解到，connection 是双向的，它可以是匿名监听者 (anonymous listeners)。如果另一端消失了（因为 crash 或者是正常的进程终止），这时连接将很有可能变得无效。我们可以给 connection 对象设置失效处理函数，如果 XPC runtime 无法重新创建这个 connection，我们的失效处理函数将会被执行。

我们还可以给 connection 设置中断处理程序，会在 connection 被中断的时候会执行，尽管此时 connection 仍然是有效的。

在 `NSXPCConnection中` 对应的两个属性是：

    var interruptionHandler: (() -> Void)!
    var invalidationHandler: (() -> Void)!

## 双向连接 (Bidirectional Connections)

一个经常被忽略而又有意思的事实是：connection 是双向的。但是只能通过 App 创建到 service 的初始连接。service 不能主动创建到 App 的连接（见下文的 [service lookup](#service-lookup)）。一旦连接已经建好了，两端都可以发起请求。

正如 service 端给 connection 对象设置了 `exportedObject`，App 端也可以这么做。这样可以让 service 端通过  `remoteObjectProxy` 来和 App 的 exported object 进行通信了。值得注意是，XPC service 由系统管理其生命周期，如果没有未完成的请求，可能会被停止掉（参见上文的 [Sudden Termination](#sudden-termination)）。


<a name="service-lookup"> </a>
## 服务查找 (Service Lookup)

当我们连接到 XPC service 的时候，我们需要*找到*连接的另一端。对于使用私有 XPC service 的 App，XPC 会在 App 的 bundle 范围内通过名字查找。还有其他的方法来连接到 XPC，让我们来看看所有的可能性。

### XPC Service

假如 App 使用：

    NSXPCConnection(serviceName: "io.objc.myapp.myservice")

XPC 会在 App 自己的命名空间 (namespace) 查找名为 `io.objc.myapp.myservice` 的service，这样的 service 仅对当前 App 有效，其他 App 无法连接。XPC service bundle 要么是位于 App 的 bundle 里，要么是在该 App 使用的 Framework 的 bundle 里。

### Mach Service

另一个选择是使用：

    NSXPCConnection(machServiceName: "io.objc.mymachservice", options: NSXPCConnectionOptions(0))

这会在当前用户的登录会话 (login session) 中查找名为 `io.objc.mymachservice` 的service。
我们可以在 `/Library/LaunchAgents` 或 `~/Library/LaunchAgents` 目录下安装 launch agent，这些 launch agent 也以与 App 里的 XPC service 几乎相同的方式来提供 service。由于 launch agent 会在 per-login session 中启动的，在同一个登录会话中运行的多个 App 可以和同一个 launch agent 进行通信。

这种方法很有用，例如[状态栏 (Status Bar)](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/StatusBar/StatusBar.html#//apple_ref/doc/uid/10000073i) 中的 menu extra 程序（即右上角只有菜单项的 App）需要和 UI App 进行通信的时候。普通 App 和 menu extra 程序都可以和同一个 launch agent 进行通信并交互数据。当你需要让两个以上的进程需要相互通信，XPC 可以是一个非常优雅的方案。

假设我们要写一个天气类的 App，我们可以把天气数据的抓取和解析做成 launch agent 方式的 XPC service。我们可以分别创建 menu extra 程序，普通 App，以及通知中心的 Widget 来显示同样的天气数据。它们都可以通过 `NSXPCConnection` 和同一个 launch agent 进行通信。

与 XPC service 相同，launch agent 的生命周期也可以完全由 XPC 掌控：按需启动，闲置或者系统内存不足的时候停止。

### 匿名监听者 (Anonymous Listeners) 和端点 (Endpoints)

XPC 有通过 connection 来传递被称为 *listener endpoints* 的能力。这个概念一开始会让人非常费解，但是它可以带来更大的灵活性。

比如说我们有两个 App，我们希望它们能够过 XPC 来互相通信，每个 App 都不知道其他 App 的存在，但它们都知道相同的一个（共享）launch agent。

这两个 App 可以先连接到 launch agent。App A 创建一个被称为 *匿名监听者 (anonymous listener)* 的对象，并通过 XPC 发送一个*端点 (endpoint)*，并由匿名监听者创建的对象给 launch agent。App B 可以通过 XPC 在同样的 launch agent 中拿到这个 endpoint。这时，App B 就可以直接连接到这个匿名监听者，即 App A。


在 App A 创建一个 anonymous listener：

    let listener = NSXPCListener.anonymousListener()

类似于 XPC service 创建普通的 listener。然后从这个 listener 创建一个 endpoint：

    let endpoint = listener.endpoint

这个 endpoint 可以通过 XPC 来传递（实现了 `NSSecureCoding` 协议 ）。一旦 App B 获取到这个 endpoint，它可以创建到 App A 的 listener 的一个 connection：

	let connection = NSXPCConnection(listenerEndpoint: endpoint)

### Privileged Mach Service

最后一个选择是使用：

    NSXPCConnection(machServiceName: "io.objc.mymachservice", options: .Privileged)

这种方式和 launch agent 非常类似，不同的是创建了到 launch daemon 的 connection。launch agent 进程是 per user 的，它们以用户的身份运行在用户的登录会话 (login session) 中。守护进程 (Daemon) 则是 per machine 的，即使当前多个用户登录，一个 XPC daemon 也只有一个实例运行。

如果要运行 daemon 的话，有很多安全相关的问题需要考虑。虽然以 root 权限运行 daemon 是可能的，但是最好是不要这么这么做。我们可能更希望它以一些独特的用户身份来运行。具体可以参考 [TN2083 - Designing Secure Helpers and Daemons](https://developer.apple.com/library/mac/technotes/tn2083/_index.html)。大多数情况，我们并不需要 root 权限。

## 文件访问 (File Access)

假设我们要创建一个 HTTP 文件下载的 service。我们需要允许 service 能发起对外的网络连接请求。不太明显的是，我们可以让 service 下载写入文件而不需要访问任何文件。

它是如何做到的呢，首先我们在 App 中创建这个将被下载的文件，然后给这个文件创建一个文件句柄 (file handle)：

    let fileURL = NSURL.fileURLWithPath("/some/path/we/want/to/download/to")
    if NSData().writeToURL(fileURL, options:0, error:&error) {
        let maybeHandle = NSFileHandle.fileHandleForWritingToURL(url:fileURL, error:&error)
        if let handle = maybeHandle {
            self.startDownload(fromURL:someURL, toFileHandle: handle) {
                self.downloadComplete(url: someURL)
            }
        }
    }


    func startDownload(fromURL: NSURL, toFileHandle: NSFileHandlehandle, completionHandler: (NSURL)->Void) -> Void

然后将这个文件句柄传给 remote object proxy，实际上就是通过 XPC connection 传给了 service，service 通过这个文件句柄写入内容，就可以保存到实际的文件中了。

同样，我们可以在一个进程中打开用于读取数据的 `NSFileHandle` 对象，然后传给另外一个进程，这样就可以做到那个进程不需要直接访问文件也能读取其内容了。

## 移动数据 (Moving Data)

虽然 XPC 非常高效，但是进程间消息传递并不是免费的。如果你需要通过 XPC 传递大量的二进制数据，你可以使用这些技巧。

正常情况下使用的 `NSData` 对象会在传递到另一端会被复制一份。对于较大的二进制数据，更有效的方法是使用 *内存映射 (memory-mapped)* 数据。[WWDC 2013 session 702](https://developer.apple.com/videos/wwdc/2013/) 的slides 从 57 页开始介绍了如何发送*大量数据*。

XPC 有个技巧，能够保证数据在进程间传递不会被复制。诀窍就是利用 `dispatch_data_t` 和 `NSData` 是 toll-free bridged 的。创建内存映射的 `dispatch_data_t` 实例与之配合，就可以高效的通过 XPC 来传递了。看上去是这样：

    let size: UInt = 8000
    let buffer = mmap(nil, size, PROT_READ | PROT_WRITE, MAP_ANON | MAP_SHARED, -1, 0)
    let ddata = dispatch_data_create(buffer, size, DISPATCH_TARGET_QUEUE_DEFAULT, _dispatch_data_destructor_munmap)
    let data = ddata as NSData


## 调试 (Debugging)

Xcode 支持通过 XPC 方式的进程间通信的调试。如果你在内嵌在 App 的私有 XPC service 里设置一个断点，调试器将以你期望的方式在断点处停下来。

请务必看看 *Activity Tracing*。这组 API 定义在在头文件 `os/activity.h` 中，提供了一种能够跨越上下文执行和进程边界的传递方式，来查看到底是什么引起了所需要执行的行为。[WWDC 2014 session 714, Fix Bugs Faster Using Activity Tracing](https://developer.apple.com/videos/wwdc/2014/)，对此做了很好的介绍。

### 常见错误 (Common Mistakes)

一个最常见的错误是没有调用 connection 或者 listener 的 resume 方法。记得它们创建后都是被挂起状态。

如果 connection 无效，很大的可能是因为配置错误导致的。请检查 bundle id 是不是和 service 名字相匹配，代码中是否指定了正确的 service 名字。

### 调试守护进程 (Debugging Daemons)

调试 daemon 会稍微复杂一些，但它仍然可以很好的工作。daemon会被 `launchd` 进程启动。所以需要分两部设置：在开发过程中，修改我们 daemon 的 [`launchd.plist`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/Manpages/man5/launchd.plist.5.html)，设置 `WaitForDebugger` 为true。然后在 Xcode 中，修改 daemon 的 scheme，在 **scheme editor** -> **Run** -> **Info** 页下可以修改 **Launch** 方式，从 “Automatically” 改到 “Wait for executable to be launched.”

现在通过 Xcode 运行 daemon，daemon 不会被启动，但是调试器会一直等着直到它启动为止。一旦 `launchd` 启动了 daemon，调试器会自动连接上，我们就可以开始干活了。

## Connection 的安全属性

每个 `NSXPCConnection` 具有这些属性

    var auditSessionIdentifier: au_asid_t { get }
    var processIdentifier: pid_t { get }
    var effectiveUserIdentifier: uid_t { get }
    var effectiveGroupIdentifier: gid_t { get }

来描述这个 connection。在 listener 端，如在 agent 或者 daemon 中，可以利用这些属性来查看谁在尝试进行连接，可以基于这些属性来决定是否允许这些连接。对于在 App bundle 里的私有 XPC service，上面的属性完全可以无视，因为只有当前 App 可以查找到这个 service。

[`xpc_connection_create(3)`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man3/xpc_connection_create.3.html) 的 man page 中有一章 “Credentials”，介绍了一些使用这些 API 缺点，在使用时需要多加小心。

<a name="quality-of-service"> </a>
## QoS 和 Boosts

在 OS X 10.10 中，Apple 提出了 **Quality of Service** (QoS) 概念。可以用来辅助调解如给 UI 较高优先级，并降低后台行为的优先级。当 QoS 遇到 XPC service，事情就变得有趣了 - 想想 XPC service 一般是完成什么样的工作？

QoS 会跨进程传送 (propagates)，在大多数情况下我们都不需要担心。当 UI 线程发起一个 XPC 调用时，service 会以 boosted QoS 来运行；但是如果 App 中的后台线程发起 XPC 调用，这也会影响到 service 的 QoS，它会以较低的 QoS 来运行。

[WWDC 2014 session 716, Power, Performance and Diagnostics](https://developer.apple.com/videos/wwdc/2014/) ，介绍了很多关于 QoS 的内容。其中它就提到了如何使用 `DISPATCH_BLOCK_DETACHED` 来分离当前的QoS，即如何防止 QoS propagates。

所以当 XPC service 因为某些请求的副作用而开始一些不相关的工作时，必须确保它从 QoS 中**分离**。

## 低阶API (Lower-Level API)

`NSXPCConnection` 所有的 API 都是建立 C API 之上，可以在 [`xpc(3) man page`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/Manpages/man3/xpc.3.html) 和子页面中找到它的文档。

我们可以使用 C API 来为 App 创建 XPC service，只要两端都使用 C API 就好。

在概念上 C API 和 Foundation 的 API 很相似（译者注：实际上是 C API 在 10.7 中被率先引入），稍微令人困惑的一点是，C API 中一个 connection 可以同时做为一个接受传入连接请求的 **listener** ，或者是到另一个进程的 connection。

### 事件流 (Event Streams)

目前只有 C API 提供的一个特性是，支持对于 IOKit events，BSD notifications，或者 Core Foundation 的distributed notifications 的 launch-on-demand（按需启动）。这些在事件或者通知在 launch agent/daemons 也是可以使用的。

在 [`xpc_events(3)` man page](https://developer.apple.com/library/mac/documentation/Darwin/Reference/Manpages/man3/xpc_events.3.html#//apple_ref/doc/man/3/xpc_events) 中列出了这些事件流。通过 C API，可以相对简单的实现一个当特定的硬件连接后按需启动的一个后台进程 (launch agent)。

---

 

原文 [XPC](http://www.objc.io/issue-14/xpc.html)