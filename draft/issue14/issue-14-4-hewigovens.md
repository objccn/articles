## XPC
2014年7月第14期 [Back to the Mac](http://www.objc.io/issue-14/index.html)  
By [Daniel Eggert](http://twitter.com/danielboedewadt)

## 关于XPC

首先，XPC更多关注的是实现功能某种的方式，通常采用其他方式同样能够实现。并没有强调如果不使用XPC，无法实现某些功能。XPC目的是提高App的安全性和稳定性。

XPC让进程间通信变得更容易，让我们能够相对容易地将App拆分成多个进程的模式。更进一步的是, XPC帮我管理了这些进程的生命周期，当我们需要与子进程通信的时候，子进程已经被XPC运行给起来了。

我们将使用在头文件`NSXPCConnection.h`中声明的Foundation framework API，它是建立在头文件`xpc/xpc.h` 中声明的原始XPC API之上的。

XPC API原本是纯C实现的API，很好地集成了libdispatch（又名GCD）。

本文中我们将使用Foundation中的类，它们可以让我们使用XPC的几乎全部功能（真实的表现了实际底层C API是如何工作的），同时与C API相比, Foundation API使用起来会更加容易。


### 哪些地方用到了XPC？

Apple在操作系统的各个部分广泛使用了XPC，很多系统Framework也利用了XPC来实现其功能。

你可以在命令行运行如下搜索命令：

    % find /System/Library/Frameworks -name \*.xpc

结果显示Frameworks目录下有55个XPC service（注：在Yosemite下），范围从AddressBook到WebKit等等。

如果在`/Applications`目录下做同样的搜索 ，我们会发现从[iWork套件](https://www.apple.com/creativity-apps/mac/)到 Xcode，甚至是一些第三方应用程序都使用了XPC。

Xcode本身就是使用XPC的一个很好的例子：当你在Xcode中编辑Swift代码的时候，Xcode就是通过XPC与SourceKit通信的(注：实际进程名应该是SourceKitService)。 SourceKit是主要负责源代码解析，语法高亮，排版，自动完成等功能的XPC service。
更多详情可以参考[JP Simard的博客](http://www.jpsim.com/uncovering-sourcekit/).

其实XPC在iOS上应用的很广泛 - 但是目前只有Apple能够使用，第三方开发者还不能使用。

## 一个示例App

让我们来看一个简单的示例：一个在table view中显示多张图片的App。图片是从web上下载下来并保存为了JPEG格式。

App看起来是这样：


![image](http://img.objccn.io/issue-14/xpc-SuperfamousImages-window@2x.jpg)

`NSTableViewDataSource`会从`ImageSet`类加载图片 ，像这样：

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

`ImageSet`类有一个简单的属性：

    var images: NSImage![]

`ImageLoader`类会异步的填充这个图片数组。

### 不使用XPC

如果不使用XPC，我们可以这样实现`ImageLoader`类来下载并解压图片：


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

明确而且工作的很好。

### Fault Isolation(错误隔离)和Split Privileges(权限隔离)

我们的App做了三件不同的事情：从互联网上下载数据，解码为JPEG，然后显示。
如果把App拆分成三个独立的进程，我们就能给每个进程单独的权限了; UI进程并不需要访问网络的权限。
图片下载的进程的确需要访问网络，但它不需要访问文件的权限（可以只是转发数据，并不保存）。
而将JPEG图片解码为RGB数据的进程既不需要访问网络的权限，也不需要访问文件的权限。

通过这种方式，在我们的App中寻找安全漏洞的行为已经变得很困难了。
另一个好处是，我们的App会变得更稳定; 例如下载service因为bug导致的crash并不会影响App主进程的运行；而下载service会被重启。

架构图如下：

![image](http://img.objccn.io/issue-14/xpc-app-2-services@2x.png)

XPC的使用十分灵活，我们还可以这样设计：让App直接和两个service通信，由App来负责service之间的数据交互。后面我们会看到App是如何[找到XPC services](#service-lookup)的。

迄今为止，大部分安全相关的bug都出现在解析不受信数据的过程当中，例如数据是我们从互联网上接收到的，不受我们控制的。现实中HTTP协议和解析JPEG数据也需要处理这样的问题，而通过这样设计，我们将解析不受信数据的过程挪进了一个子进程，即一个XPC service。

### 在App中使用XPC Services

XPC service由两个部分组成：service本身，以及与之通信的代码。它们都很简单而且相似，算是个好消息。

在Xcode中有模板可以添加新的XPC service target。
每个service都需要一个bundle id，一个好的实践是将其设置为App的bundle id的*subdomain*(*子域*) 。

在我们的例子中，App的bundle id是`io.objc.Superfamous-Images`，我们可以把下载service的bundle id设为`io.objc.Superfamous-Images.ImageDownloader`。

在build过程中，Xcode会为service target创建一个独立bundle，这个bundle会被复制到`XPCServices`目录下，与`Resources`目录平级。

当App将数据发给`io.objc.Superfamous-Images.ImageDownloader`这个service时，XPC会自动启动这个service。

基于XPC的通信基本都是异步的。我们通过让App和service都使用的相同protocol来限定。

在我们的例子中：

    @objc(ImageDownloaderProtocol) protocol ImageDownloaderProtocol {
        func downloadImage(atURL: NSURL!, withReply: (NSData?)->Void)
    }

请注意`withReply:`这部分。它表明了消息是如何通过异步的方式回给调用方的。
若返回的消息带有数据，需要将函数签名最后一部分写成：`withReply:`并接受一个closure参数的形式。

在我们的例子中，service只提供了一个方法；但是我们可以在`protocol`里定义多个方法。

App到service的连接是通过创建`NSXPCConnection`对象来完成的，像这样：

    let connection = NSXPCConnection(serviceName: "io.objc.Superfamous-Images.ImageDownloader")
    connection.remoteObjectInterface = NSXPCInterface(`protocol`: ImageDownloaderProtocol.self)
    connection.resume()

我们可以把connection对象保存为`self.imageDownloadConnection`，这样之后就可以像这样和service进行通信了：

    let downloader = self.imageDownloadConnection.remoteObject as ImageDownloaderProtocol
    downloader.downloadImageAtURL(url) {
        (data) in
        println("Got \(data.length) bytes.")
    }

我们还应该给connection对象设置错误处理函数，像这样：

    let downloader = self.imageDownloadConnection.remoteObjectProxyWithErrorHandler {
        	(error) in NSLog("remote proxy error: %@", error)
    } as ImageDownloaderProtocol
    downloader.downloadImageAtURL(url) {
        (data) in
        println("Got \(data.length) bytes.")
    }

这就是App端的所有代码了。

### 监听service请求

XPC service通过`NSXPCListener`对象来监听从App传入的请求（这是`NSXPCListenerDelegate`中可选的方法）。listener对象会给每个来自App的请求在service端创建对应的connection对象。

在`main.swift` ，我们可以这样写：

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


我们创建了一个全局的`NSXPCListener`（相当于C或Objective-C中的`main`函数）对象，
并设置了它的delegate，这样传入连接就会调用我们的delegate方法了。

我们需要给connection设置App端中同样使用的`protocol`。最后我们设置实际上实现这个`protocol`的`ImageDownloader`对象实例给connection的`exportedObject`:

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

值得注意的一个重要是，`NSXPCListener`和`NSXPCConnection`默认是suspended(挂起)的。
我们设置好后需要调用它们的`resume`方法来启动。

在[GitHub](https://github.com/objcio/issue-14-xpc)上可以找到这个简单的示例App。


## Listener（监听者）, Connection（连接）,和 Exported Object(导出对象）

在App端，需要一个connection对象。每次将数据发给service，我们需要调用`remoteObjectProxyWithErrorHandler`方法来创建一个remote object proxy(远程对象代理)
而在service端，多了一层。首先需要一个listener，用来监听来自App的传入connection。

App可以创建多个connection，listener会在service端建立相应的connection对象。每个connection对象都有唯一的exported object，App端是通过remote object proxy发送消息给它的。

当App创建一个到XPC service的connection时，是XPC在管理这个service的生命周期，service的启动与停止都由XPC runtime完成，这对App来说是透明的。而且如果service因为某种原因crash了，也会透明的被重启。

App初始化XPC connection的时候，XPC service并不会启动，只到App实际发送的第一条消息到remote object proxy时才启动。如果当前没有未结束的响应，系统可能会因为内存压力或者XPC service已经闲置了一段时间而停止这个service。这种情况下，App持有的connection对象任然有效，下次再使用这个connection对象的时候，XPC系统会自动重启对应的XPC service。如果XPC service crash了，它也会被透明地重启，并且到它的connection还是有效的。

但是如果XPC service是在接收消息时crash了，App需用重新发送该消息才能接受到对应的响应。这就是为什么要调用`remoteObjectProxyWithErrorHandler`方法来设置错误处理函数了，它接受一个closure参数，在发生错误的时候被执行。

XPC API保证只有一个函数的closure会被执行：错误处理里的closure或者是消息响应里的closure；如果消息消息响应里的closure执行了，那么错误处理的closure就不会被执行，反之亦然。这样就使得资源清理变得容易了。

<a name="sudden-termination"> </a>
### Sudden Termination(突然终止)

XPC是通过跟踪那些是否有仍在处理请求来管理service的生命周期的，如果有请求正在*运行*，对应的service不会被停止。如果消息请求的响应还没有被发送，则这个请求会被认为是正在运行的。

对于那些没有`reply`的处理程序的请求，只要方法体还在运行，这个请求就会被认为是正在运行的。在某些情况下，我们可能想告诉XPC我们还有更多的工作要做，我们可以使用`NSProcessInfo`的API来实现这一点：

    func disableAutomaticTermination(reason: String!)
    func enableAutomaticTermination(reason: String!)

如果XPC service接受传入请求并需要在后台执行一些异步操作，这些API就能派上用场了（既告诉系统不希望被突然终止）。某些情况下我们还可能需要调整我们的[QoS服务质量](#quality-of-service)设置。


### Interruption(中断)和Invalidation(失效)

XPC的最常见的用法是App发消息给它的XPC service。XPC允许非常灵活的设置。我们通过下文会了解到，connection是双向的，它可以是anonymous listeners（匿名监听者）。如果另一端消失了（因为crash或者是正常的进程终止），这时连接将很有可能变得无效。我们可以给connection对象设置失效处理函数，如果XPC runtime无法重新创建这个connection，我们的失效处理函数将会被执行。

我们还可以给connection设置中断处理程序，会在connection被中断的时候会执行，尽管此时connection任然是有效的。

在`NSXPCConnection中`对应的两个属性：

    var interruptionHandler: (() -> Void)!
    var invalidationHandler: (() -> Void)!



## Bidirectional Connections(双向连接)

一个经常被忽略而又有意思的事实是：connection是双向的。但是只能通过App创建到service的初始连接。service不能主动创建到App的连接（见下文的[service lookup](#service-lookup)）。一旦连接已经建好了，两端都可以发起请求。

正如service端给connection对象设置了`exportedObject`，App端也可以这么做。这样可以让service端通过`remoteObjectProxy`来和App的exported object进行通信了。值得注意是，XPC service由系统管理其生命周期，如果没有未完成的请求，可能会被停止掉（参见上文的[Sudden Termination](#sudden-termination) ）。


<a name="service-lookup"> </a>
## Service Lookup(service查找)

当我们连接到XPC service的时候，我们需要*找到*连接的另一端。对于使用私有XPC service的App，XPC会在App的bundle范围内通过名字查找。

还有其他的方法来连接到XPC，让我们来看看所有的可能性。

### XPC Service

假如App使用：

    NSXPCConnection(serviceName: "io.objc.myapp.myservice")

XPC会在App自己的namespace(命名空间)查找名为`io.objc.myapp.myservice的service`的service，这样的service仅对当前App有效，其他App无法连接。XPC service bundle要么是位于App的bundle里或是该App使用的Framework的bundle里。

### Mach Service

另一个选择是使用：

    NSXPCConnection(machServiceName: "io.objc.mymachservice", options: NSXPCConnectionOptions(0))

这会在当前用户的login session（登录会话）中查找名为`io.objc.myservice`的service。
我们可以在`/Library/LaunchAgents`或`~/Library/LaunchAgents`目录下安装launch agent，这些launch agent也作为和App里的XPC service几乎相同的service。

由于launch agent会在per-login session中启动的，在同一个登录会话中运行的多个App可以和同一个launch agent进行通信。

这种方法很有用，例如[Status Bar(状态栏)](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/StatusBar/StatusBar.html#//apple_ref/doc/uid/10000073i)中的menu extra程序（即右上角只有菜单项的App）需要和UI App进行通信的时候。
普通App和menu extra程序都可以和同一个launch agent进行通信并交互数据。当你需要让两个以上的进程需要相互通信，XPC可以是一个非常优雅的方案。

假设我们要写一个天气类的App，我们可以把天气数据的抓取和解析做成launch agent方式的XPC service。我们可以分别创建menu extra程序，普通App，以及通知中心的Widget来显示同样的天气数据。
他们都可以通过`NSXPCConnection`和同一个launch agent进行通信。

与XPC service相同，launch agent的生命周期也可以完全由XPC掌控：按需启动，闲置或者系统内存不足的时候停止。

### Anonymous Listeners（匿名监听者）和 Endpoints（端点）


XPC有通过connection来传递被称为*listener endpoints*的能力。这个概念一开始会让人非常费解，但是它可以带来更大的灵活性。

比如说我们有两个App，我们希望它们能够过XPC来互相通信，每个App都不知道其他App的存在，但它们都知道相同的一个（共享）launch agent。

这两个App可以先连接到launch agent。App A创建一个被称为*anonymous listener*的对象，并通过XPC发送一个被称为*endpoint*，由anonymous listener创建的对象给launch agent。
App B可以通过XPC在同样的launch agent中拿到这个endpoint。这时，App B就可以直接连接到这个anonymous listener，即App A。


在App A创建一个anonymous listener：

    let listener = NSXPCListener.anonymousListener()

类似于XPC service创建普通的listener。然后从这个listener创建一个endpoint：

    let endpoint = listener.endpoint


这个endpoint可以通过XPC来传递（实现了NSSecureCoding协议 ）。
一旦App B获取到这个endpoint，它可以创建到App A的listener的一个connection：

	let connection = NSXPCConnection(listenerEndpoint: endpoint)

### Privileged Mach Service

最后一个选择是使用：

    NSXPCConnection(machServiceName: "io.objc.mymachservice", options: .Privileged)

这种方式和launch agent非常类似，不同的是创建了到launch daemon的connection。
launch agent进程是per user的，它们以用户的身份运行在用户的login session（登录会话）中。
Daemon（守护进程）则是 per machine的，即使当前多个用户登录，一个XPC daemon也只有一个实例运行。

如果要运行daemon，有很多安全相关的问题需要考虑。虽然以root权限运行daemon是可能的，但是最好是不要这么这么做。我们可能更希望它以一些独特的用户身份来运行。具体可以参考[TN2083 - Designing Secure Helpers and Daemons](https://developer.apple.com/library/mac/technotes/tn2083/_index.html)。大多数情况，我们并不需要root权限。


## File Access（文件访问）

假设我们要创建一个HTTP文件下载的service。我们需要允许service能发起对外的网络连接请求。
不太明显的是，我们可以让service下载写入文件而不需要访问任何文件。

它是如何做到的呢，首先我们在App中创建这个将被下载的文件，然后给这个文件创建一个file handle（文件句柄）：

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

然后将这个file handle传给remote object proxy，实际上就是通过XPC connection传给了service，service通过这个file handle写入内容，就可以保存到实际的文件中了。

同样，我们可以在一个进程中打开用于读取数据的`NSFileHandle`对象，然后传给另外一个进程，这样就可以做到那个进程不需要直接访问文件也能读取其内容了。

## Moving Data（移动数据）

虽然XPC非常高效，但是进程间消息传递并不是免费的。如果你需要通过XPC传递大量的二进制数据，你可以使用这些技巧。

正常情况下使用的`NSData`对象会在传递到另一端会被复制一份。对于较大的二进制数据，更有效的方法是使用*memory-mapped*(内存映射）数据。[WWDC 2013 session 702](https://developer.apple.com/videos/wwdc/2013/) 的slides从57页开始介绍了如何发送*大量数据*。

XPC有个技巧，能够保证数据在进程间传递不会被复制。诀窍就是利用`dispatch_data_t`和`NSData` 是toll-free bridged的。创建memory-mapped的`dispatch_data_t`实例与之配合，就可以高效的通过XPC来传递了。看上去是这样：

    let size: UInt = 8000
    let buffer = mmap(nil, size, PROT_READ | PROT_WRITE, MAP_ANON | MAP_SHARED, -1, 0)
    let ddata = dispatch_data_create(buffer, size, DISPATCH_TARGET_QUEUE_DEFAULT, _dispatch_data_destructor_munmap)
    let data = ddata as NSData


## Debugging（调试）

Xcode支持通过XPC方式的进程间通信的调试。如果你在内嵌在App的私有XPC service里设置一个断点，调试器将以你期望的方式在断点处停下来。

请务必看看 *Activity Tracing*。一组在头文件`os/activity.h`里声明的API，提供了一种能够跨越上下文执行和进程边界的传递方式，来查看式什么引起了需要执行的行为。（这句好难理解，=_+）
[WWDC 2014 session 714, Fix Bugs Faster Using Activity Tracing](https://developer.apple.com/videos/wwdc/2014/)，对此做了很好的介绍。


### Common Mistakes（常见错误）

一个最常见的错误是没有调用connection或者listener的resume方法。记得它们创建后都是suspended（挂起）状态。

如果connection无效，很大的可能是因为配置错误导致的。请检查bundle id是不是和service名字相匹配，代码中是否指定了正确的service名字。

### Debugging Daemons（调试守护进程）

调试Daemon会稍微复杂一些，但它仍然可以很好的工作。daemon会被`launchd`进程启动。
所以需要分两部设置：在开发过程中，修改我们daemon的[`launchd.plist`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/Manpages/man5/launchd.plist.5.html)，设置`WaitForDebugger`为true。然后在Xcode中，修改daemon的scheme，在**scheme editor** -> **Run** -> **Info** 页下可以修改**Launch**方式，从 “Automatically” 到 “Wait for executable to be launched.”

现在通过Xcode运行daemon，daemon不会被启动，但是调试器会一直等着直到它启动为止。一旦`launchd`启动了daemon，调试器会自动连接上，我们就可以开始干活了。


## Connection的安全属性

每个`NSXPCConnection`具有这些属性

    var auditSessionIdentifier: au_asid_t { get }
    var processIdentifier: pid_t { get }
    var effectiveUserIdentifier: uid_t { get }
    var effectiveGroupIdentifier: gid_t { get }

来描述这个connection。在listener端，如在agent或者daemon中，可以利用这些属性来查看谁在尝试进行连接，可以基于这些属性来决定是否允许这些连接。

对于在App bundle里的私有XPC service，上面的属性完全可以无视，因为只有当前App可以查找到这个service。

man page中[`xpc_connection_create(3)`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man3/xpc_connection_create.3.html) 的 有一章“Credentials”，介绍了一些使用这些API缺点，在使用时需要多加小心。


<a name="quality-of-service"> </a>
## QoS和Boosts

在OS X 10.10中，Apple提出了**Quality of Service** (QoS)概念。
可以用来辅助调解如给UI较高优先级，并降低后台行为的优先级。

当QoS遇到XPC service，事情就变得有趣了 - 想想XPC service一般是完成什么样的工作？

QoS会跨进程propagates（传染），在大多数情况下我们都不需要担心。当UI线程发起一个XPC调用时，service会以boosted QoS来运行；但是如果App中的后台线程发起XPC调用，这也会影响到service的QoS，它会以较低的QoS来运行。

[WWDC 2014 session 716, Power, Performance and Diagnostics](https://developer.apple.com/videos/wwdc/2014/) ，介绍了很多关于QoS的内容。其中它就提到了如何使用`DISPATCH_BLOCK_DETACHED`来分离当前的QoS，即如何防止QoS propagates。

所以当XPC service因为某些请求的副作用而开始一些不相关的工作时，必须确保它从QoS中**分离**。

## Lower-Level API（低阶API）

`NSXPCConnection` 所有的API都是建立C API之上，可以在[`xpc(3) man page`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/Manpages/man3/xpc.3.html)和子页面中找到它的文档。


我们可以使用C API来为App创建XPC service，只要两端都使用C API就好。
在概念上C API和Foundation的API很相似（注：实际上是C API在10.7中先引入），稍微令人困惑的一点是，C API中一个connection可以同时做为一个接受传入连接请求的**listener** ，或者是到另一个进程的connection。

### Event Streams（事件流）

目前只有C API提供的一个特性是，支持对于IOKit events，BSD notifications，或者Core Foundation的distributed notifications的launch-on-demand（按需启动）。这些在事件或者通知在launch agent/daemons也是可以使用的。

在[`xpc_events(3)` man page](https://developer.apple.com/library/mac/documentation/Darwin/Reference/Manpages/man3/xpc_events.3.html#//apple_ref/doc/man/3/xpc_events) 中列出了这些event stream。通过C API，可以相对简单的实现一个当特定的硬件连接后按需启动的一个launch agent（后台进程）。

---

[更多issue＃14文章](http://www.objc.io/issue-14)