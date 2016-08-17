iOS 7 和 Mac OS X 10.9 Mavericks 中一个显著的变化就是对 Foundation URL 加载系统的彻底重构。

现在已经有人在深入苹果的网络层基础架构的地方做研究了，所以我想是时候来分享一些对于我对于这些新的 API 的看法和心得了，新的 API 将如何影响我们编写程序，以及它们对于 API 设计理念的影响。

`NSURLConnection` 作为 Core Foundation / CFNetwork 框架的 API 之上的一个抽象，在 2003 年，随着第一版的 Safari 的发布就发布了。`NSURLConnection` 这个名字，实际上是指代的 Foundation 框架的 URL 加载系统中一系列有关联的组件：`NSURLRequest`、`NSURLResponse`、`NSURLProtocol`、 `NSURLCache`、 `NSHTTPCookieStorage`、`NSURLCredentialStorage` 以及同名类 `NSURLConnection`。

`NSURLRequest` 被传递给 `NSURLConnection`。被委托对象（遵守以前的非正式协议 `<NSURLConnectionDelegate>` 和 `<NSURLConnectionDataDelegate>`）异步地返回一个 `NSURLResponse` 以及包含服务器返回信息的 `NSData`。

在一个请求被发送到服务器之前，系统会先查询共享的缓存信息，然后根据**策略（policy）**以及**可用性（availability）**的不同，一个已经被缓存的响应可能会被立即返回。如果没有缓存的响应可用，则这个请求将根据我们指定的策略来缓存它的响应以便将来的请求可以使用。

在把请求发送给服务器的过程中，服务器可能会发出**鉴权查询（authentication challenge）**，这可以由共享的 cookie 或**机密存储（credential storage）**来自动响应，或者由被委托对象来响应。发送中的请求也可以被注册的 `NSURLProtocol` 对象所拦截，以便在必要的时候无缝地改变其加载行为。

不管怎样，`NSURLConnection` 作为网络基础架构，已经服务了成千上万的 iOS 和 Mac OS 程序，并且做的还算相当不错。但是这些年，一些用例——尤其是在 iPhone 和 iPad 上面——已经对 `NSURLConnection` 的几个核心概念提出了挑战，让苹果有理由对它进行重构。

在 2013 的 WWDC 上，苹果推出了 `NSURLConnection` 的继任者：`NSURLSession`。

---

和 `NSURLConnection` 一样，`NSURLSession` 指的也不仅是同名类 `NSURLSession`，还包括一系列相互关联的类。`NSURLSession` 包括了与之前相同的组件，`NSURLRequest` 与 `NSURLCache`，但是把 `NSURLConnection` 替换成了 `NSURLSession`、`NSURLSessionConfiguration` 以及 `NSURLSessionTask` 的 3 个子类：`NSURLSessionDataTask`，`NSURLSessionUploadTask`，`NSURLSessionDownloadTask`。

与 `NSURLConnection` 相比，`NSURLsession` 最直接的改进就是可以配置每个 session 的缓存，协议，cookie，以及**证书策略（credential policy）**，甚至跨程序共享这些信息。这将允许程序和网络基础框架之间相互独立，不会发生干扰。每个 `NSURLSession` 对象都由一个 `NSURLSessionConfiguration` 对象来进行初始化，后者指定了刚才提到的那些策略以及一些用来增强移动设备上性能的新选项。

`NSURLSession` 中另一大块就是 session task。它负责处理数据的加载以及文件和数据在客户端与服务端之间的上传和下载。`NSURLSessionTask` 与 `NSURLConnection` 最大的相似之处在于它也负责数据的加载，最大的不同之处在于所有的 task 共享其创造者 `NSURLSession` 这一**公共委托者（common delegate）**。

我们先来深入探讨 task，过后再来讨论 `NSURLSessionConfiguration`。

## NSURLSessionTask

`NSURLsessionTask` 是一个抽象类，其下有 3 个实体子类可以直接使用：`NSURLSessionDataTask`、`NSURLSessionUploadTask`、`NSURLSessionDownloadTask`。这 3 个子类封装了现代程序三个最基本的网络任务：获取数据，比如 JSON 或者 XML，上传文件和下载文件。

<img alt="NSURLSessionTask class diagram" src="/images/issues/issue-5/NSURLSession.png" width="612" height="294">

当一个 `NSURLSessionDataTask` 完成时，它会带有相关联的数据，而一个 `NSURLSessionDownloadTask` 任务结束时，它会带回已下载文件的一个临时的文件路径。因为一般来说，服务端对于一个上传任务的响应也会有相关数据返回，所以 `NSURLSessionUploadTask` 继承自 `NSURLSessionDataTask`。

所有的 task 都是可以取消，暂停或者恢复的。当一个 download task 取消时，可以通过选项来创建一个**恢复数据（resume data）**，然后可以传递给下一次新创建的 download task，以便继续之前的下载。

不同于直接使用 `alloc-init` 初始化方法，task 是由一个 `NSURLSession` 创建的。每个 task 的构造方法都对应有或者没有 `completionHandler` 这个 block 的两个版本，例如：有这样两个构造方法 `–dataTaskWithRequest:` 和 `–dataTaskWithRequest:completionHandler:`。这与 `NSURLConnection` 的 `-sendAsynchronousRequest:queue:completionHandler:` 方法类似，通过指定 `completionHandler` 这个 block 将创建一个隐式的 delegate，来替代该 task 原来的 delegate——session。对于需要 override 原有 session task 的 delegate 的默认行为的情况，我们需要使用这种不带 `completionHandler` 的版本。

### NSURLSessionTask 的工厂方法

在 iOS 5 中，`NSURLConnection` 添加了 `sendAsynchronousRequest:queue:completionHandler:` 这一方法，对于一次性使用的 request， 大大地简化代码，同时它也是 `sendSynchronousRequest:returningResponse:error:` 这个方法的异步替代品：

     NSURL *URL = [NSURL URLWithString:@"http://example.com"];
     NSURLRequest *request = [NSURLRequest requestWithURL:URL];
     
     [NSURLConnection sendAsynchronousRequest:request
                                        queue:[NSOperationQueue mainQueue]
                            completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
         // ...
     }];

`NSURLSession` 在 task 的构造方法上延续了这一模式。不同的是，这里不会立即运行 task，而是将该 task 对象先返回，允许我们进一步的配置，然后可以使用 `resume` 方法来让它开始运行。

Data task 可以通过 `NSURL` 或 `NSURLRequest` 创建（使用前者相当于是使用一个对于该 URL 进行标准 `GET` 请求的 `NSURLRequest`，这是一种快捷方法）：

     NSURL *URL = [NSURL URLWithString:@"http://example.com"];
     NSURLRequest *request = [NSURLRequest requestWithURL:URL];
     
     NSURLSession *session = [NSURLSession sharedSession];
     NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                             completionHandler:
         ^(NSData *data, NSURLResponse *response, NSError *error) {
             // ...
         }];
         
     [task resume];

Upload task 的创建需要使用一个 request，另外加上一个要上传的 `NSData` 对象或者是一个本地文件的路径对应的 `NSURL`：

     NSURL *URL = [NSURL URLWithString:@"http://example.com/upload"];
     NSURLRequest *request = [NSURLRequest requestWithURL:URL];
     NSData *data = ...;
     
     NSURLSession *session = [NSURLSession sharedSession];
     NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                                fromData:data
                                                       completionHandler:
         ^(NSData *data, NSURLResponse *response, NSError *error) {
             // ...
         }];
         
     [uploadTask resume];

Download task 也需要一个 request，不同之处在于 `completionHandler` 这个 block。Data task 和 upload task 会在任务完成时一次性返回，但是 Download task 是将数据一点点地写入本地的临时文件。所以在 `completionHandler` 这个 block 里，我们需要把文件从一个临时地址移动到一个永久的地址保存起来：

     NSURL *URL = [NSURL URLWithString:@"http://example.com/file.zip"];
     NSURLRequest *request = [NSURLRequest requestWithURL:URL];
     
     NSURLSession *session = [NSURLSession sharedSession];
     NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request
                                                             completionHandler:
        ^(NSURL *location, NSURLResponse *response, NSError *error) {
            NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            NSURL *documentsDirectoryURL = [NSURL fileURLWithPath:documentsPath];
            NSURL *newFileLocation = [documentsDirectoryURL URLByAppendingPathComponent:[[response URL] lastPathComponent]];
            [[NSFileManager defaultManager] copyItemAtURL:location toURL:newFileLocation error:nil];
        }];
        
     [downloadTask resume];
     
> <span class="secondary radius label">编者注</span> 原文中这块代码以及上文的表述中存有一些问题，详见这个 [issue](https://github.com/objcio/articles/issues/24)，本文已进行更正，如果您有不同意见，欢迎在 [Github](https://github.com/objccn/articles) 上给我们反馈。

### NSURLSession 与 NSURLConnection 的 delegate 方法

总体而言，`NSURLSession` 的 delegate 方法是 `NSURLConnection` 的演化的十年中对于 ad-hoc 模式的一个显著改善。您可以查看这个[映射表](https://gist.github.com/floriankugler/6870499)来进行一个完整的概览。

以下是一些具体的观察：

`NSURLSession` 既拥有 seesion 的 delegate 方法，又拥有 task 的 delegate 方法用来处理鉴权查询。session 的 delegate 方法处理连接层的问题，诸如服务器信任，客户端证书的评估，[NTLM](http://en.wikipedia.org/wiki/NTLM) 和 [Kerberos](http://zh.wikipedia.org/wiki/Kerberos) 协议这类问题，而 task 的 delegate 则处理以网络请求为基础的问题，如 Basic，Digest，以及**代理身份验证（Proxy authentication）**等。

在 `NSURLConnection` 中有两个 delegate 方法可以表明一个网络请求已经结束：`NSURLConnectionDataDelegate` 中的 `-connectionDidFinishLoading:` 和 `NSURLConnectionDelegate` 中的 `-connection:didFailWithError:`，而在 `NSURLSession` 中改为一个 delegate 方法：`NSURLSessionTaskDelegate` 的 `-URLSession:task:didCompleteWithError:`

`NSURLSession` 中表示传输多少字节的参数类型现在改为 `int64_t`，以前在 `NSURLConnection` 中相应的参数的类型是 `long long`。

由于增加了 `completionHandler:` 这个 block 作为参数，`NSURLSession` 实际上给 Foundation 框架引入了一种全新的模式。这种模式允许 delegate 方法可以安全地在主线程与运行，而不会阻塞主线程；Delgate 只需要简单地调用 `dispatch_async` 就可以切换到后台进行相关的操作，然后在操作完成时调用 `completionHandler` 即可。同时，它还可以有效地拥有多个返回值，而不需要我们使用笨拙的参数指针。以 `NSURLSessionTaskDelegate` 的 `-URLSession:task:didReceiveChallenge:completionHandler:` 方法来举例，`completionHandler` 接受两个参数：`NSURLSessionAuthChallengeDisposition` 和 `NSURLCredential`，前者为应对鉴权查询的策略，后者为需要使用的证书（仅当前者——应对鉴权查询的策略为使用证书，即 `NSURLSessionAuthChallengeUseCredential` 时有效，否则该参数为 `NULL`）

> 想要查看更多关于 session task 的信息，可以查看 [WWDC Session 705: "What’s New in Foundation Networking"](http://asciiwwdc.com/2013/sessions/705)


## NSURLSessionConfiguration

`NSURLSessionConfiguration` 对象用于对 `NSURLSession` 对象进行初始化。`NSURLSessionConfiguration` 对以前 `NSMutableURLRequest` 所提供的[网络请求层的设置选项](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSMutableURLRequest_Class/Reference/Reference.html)进行了扩充，提供给我们相当大的灵活性和控制权。从指定可用网络，到 cookie，安全性，缓存策略，再到使用自定义协议，启动事件的设置，以及用于移动设备优化的几个新属性，你会发现使用 `NSURLSessionConfiguration` 可以找到几乎任何你想要进行配置的选项。

`NSURLSession` 在初始化时会把配置它的 `NSURLSessionConfiguration` 对象进行一次 copy，并保存到自己的 `configuration` 属性中，而且这个属性是只读的。因此之后再修改最初配置 session 的那个 configuration 对象对于 session 是没有影响的。也就是说，configuration 只在初始化时被读取一次，之后都是不会变化的。

### NSURLSessionConfiguration 的工厂方法

`NSURLSessionConfiguration` 有三个类工厂方法，这很好地说明了 `NSURLSession` 设计时所考虑的不同的使用场景。

`+defaultSessionConfiguration` 返回一个标准的 configuration，这个配置实际上与 `NSURLConnection` 的**网络堆栈（networking stack）**是一样的，具有相同的共享 `NSHTTPCookieStorage`，共享 `NSURLCache` 和共享 `NSURLCredentialStorage`。

`+ephemeralSessionConfiguration` 返回一个预设配置，这个配置中不会对缓存，Cookie 和证书进行持久性的存储。这对于实现像秘密浏览这种功能来说是很理想的。

`+backgroundSessionConfiguration:(NSString *)identifier` 的独特之处在于，它会创建一个*后台 session*。后台 session 不同于常规的，普通的 session，它甚至可以在应用程序挂起，退出或者崩溃的情况下运行上传和下载任务。初始化时指定的标识符，被用于向任何可能在进程外恢复后台传输的**守护进程（daemon）**提供上下文。

想要查看更多关于后台 session 的信息，可以查看 [WWDC Session 204: "What's New with Multitasking"](http://asciiwwdc.com/2013/sessions/204)


### 配置属性

`NSURLSessionConfiguration` 拥有 20 个配置属性。熟练掌握这些配置属性的用处，可以让应用程序充分地利用其网络环境。

#### 基本配置

`HTTPAdditionalHeaders` 指定了一组默认的可以设置**出站请求（outbound request）**的数据头。这对于跨 session 共享信息，如内容类型，语言，用户代理和身份认证，是很有用的。

    NSString *userPasswordString = [NSString stringWithFormat:@"%@:%@", user, password];
    NSData * userPasswordData = [userPasswordString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64EncodedCredential = [userPasswordData base64EncodedStringWithOptions:0];
    NSString *authString = [NSString stringWithFormat:@"Basic %@", base64EncodedCredential];
    NSString *userAgentString = @"AppName/com.example.app (iPhone 5s; iOS 7.0.2; Scale/2.0)";
    
    configuration.HTTPAdditionalHeaders = @{@"Accept": @"application/json",
                                            @"Accept-Language": @"en",
                                            @"Authorization": authString,
                                            @"User-Agent": userAgentString};

`networkServiceType` 对标准的网络流量，网络电话，语音，视频，以及由一个后台进程使用的流量进行了区分。大多数应用程序都不需要设置这个。
 
 `allowsCellularAccess` 和 `discretionary` 被用于节省通过蜂窝网络连接的带宽。对于后台传输的情况，推荐大家使用 `discretionary` 这个属性，而不是 `allowsCellularAccess`，因为前者会把 WiFi 和电源的可用性考虑在内。

`timeoutIntervalForRequest` 和 `timeoutIntervalForResource` 分别指定了对于请求和资源的超时间隔。许多开发人员试图使用 `timeoutInterval` 去限制发送请求的总时间，但其实它真正的含义是：**分组（packet）**之间的时间。实际上我们应该使用 `timeoutIntervalForResource` 来规定整体超时的总时间，但应该只将其用于后台传输，而不是用户实际上可能想要去等待的任何东西。

`HTTPMaximumConnectionsPerHost` 是 Foundation 框架中 URL 加载系统的一个新的配置选项。它曾经被 `NSURLConnection` 用于管理私有的连接池。现在有了 `NSURLSession`，开发者可以在需要时限制连接到特定主机的数量。

`HTTPShouldUsePipelining` 这个属性在 `NSMutableURLRequest` 下也有，它可以被用于开启 **HTTP 管线化（[HTTP pipelining](http://en.wikipedia.org/wiki/HTTP_pipelining)）**，这可以显着降低请求的加载时间，但是由于没有被服务器广泛支持，默认是禁用的。

`sessionSendsLaunchEvents` 是另一个新的属性，该属性指定该 session 是否应该从后台启动。

`connectionProxyDictionary` 指定了 session 连接中的代理服务器。同样地，大多数面向消费者的应用程序都不需要代理，所以基本上不需要配置这个属性。

> 关于连接代理的更多信息可以在 [`CFProxySupport` Reference](https://developer.apple.com/library/mac/documentation/CoreFoundation/Reference/CFProxySupport/Reference/reference.html) 找到。


#### Cookie 策略


`HTTPCookieStorage` 存储了 session 所使用的 cookie。默认情况下会使用 `NSHTTPCookieShorage` 的 `+sharedHTTPCookieStorage` 这个单例对象，这与 `NSURLConnection` 是相同的。

`HTTPCookieAcceptPolicy` 决定了什么情况下 session 应该接受从服务器发出的 cookie。

`HTTPShouldSetCookies` 指定了请求是否应该使用 session 存储的 cookie，即 `HTTPCookieSorage` 属性的值。

#### 安全策略

`URLCredentialStorage` 存储了 session 所使用的证书。默认情况下会使用 `NSURLCredentialStorage` 的 `+sharedCredentialStorage` 这个单例对象，这与 `NSURLConnection` 是相同的。

`TLSMaximumSupportedProtocol` 和 `TLSMinimumSupportedProtocol` 确定 session 是否支持 [SSL 协议](http://zh.wikipedia.org/wiki/安全套接层)。

#### 缓存策略

`URLCache` 是 session 使用的缓存。默认情况下会使用 `NSURLCache` 的 `+sharedURLCache` 这个单例对象，这与 `NSURLConnection` 是相同的。

`requestCachePolicy` 指定了一个请求的缓存响应应该在什么时候返回。这相当于 `NSURLRequest` 的 `-cachePolicy` 方法。

#### 自定义协议

`protocolClasses` 用来配置特定某个 session 所使用的自定义协议（该协议是 `NSURLProtocol` 的子类）的数组。


## 结论

iOS 7 和 Mac OS X 10.9 Mavericks 中 URL 加载系统的变化，是对 `NSURLConnection` 进行深思熟虑后的一个自然而然的进化。总体而言，苹果的 Foundation 框架团队干了一件令人钦佩的的工作，他们研究并预测了移动开发者现有的和新兴的用例，创造了能够满足日常任务而且非常好用的 API 。

尽管在这个体系结构中，某些决定对于可组合性和可扩展性而言是一种倒退，但是 `NSURLSession` 仍然是实现更高级别网络功能的一个强大的基础框架。

---

 

原文 [From NSURLConnection to NSURLSession](http://www.objc.io/issue-5/from-nsurlconnection-to-nsurlsession.html)
