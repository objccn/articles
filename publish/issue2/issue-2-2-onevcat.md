本文主要探讨一些常用后台任务的最佳实践。我们将会看看如何并发地使用 Core Data ，如何并行绘制 UI ，如何做异步网络请求等。最后我们将研究如何异步处理大型文件，以保持较低的内存占用。因为在异步编程中非常容易犯错误，所以，本文中的例子都将使用很简单的方式。因为使用简单的结构可以帮助我们看透代码，抓住问题本质。如果你最后把代码写成了复杂的嵌套回调的话，那么你很可能应该重新考虑自己当初的设计选择了。


## 操作队列 (Operation Queues) 还是 GCD ?

目前在 iOS 和 OS X 中有两套先进的同步 API 可供我们使用：[操作队列][6]和 [GCD][7] 。其中 GCD 是基于 C 的底层的 API ，而操作队列则是 GCD 实现的 Objective-C API。关于我们可以使用的并行 API 的更加全面的总览，可以参见 [并发编程：API 及挑战][8]。

操作队列提供了在 GCD 中不那么容易复制的有用特性。其中最重要的一个就是可以取消在任务处理队列中的任务，在稍后的例子中我们会看到这个。而且操作队列在管理操作间的依赖关系方面也容易一些。另一面，GCD 给予你更多的控制权力以及操作队列中所不能使用的底层函数。详细介绍可以参考[底层并发 API][9] 这篇文章。

扩展阅读：

* [StackOverflow: NSOperation vs. Grand Central Dispatch](http://stackoverflow.com/questions/10373331/nsoperation-vs-grand-central-dispatch)
* [Blog: When to use NSOperation vs. GCD](http://eschatologist.net/blog/?p=232)

**March 2015 更新**: 这篇文章是基于已经过时了的 Concurrency with Core Data 来编写的。

### 后台的 Core Data

在着手 Core Data 的并行处理之前，最好先打一些基础。我们强烈建议通读苹果的官方文档 [Concurrency with Core Data][10] 。这个文档中罗列了基本规则，比如绝对不要在线程间传递 managed objects等。这并不单是说你绝不应该在另一个线程中去更改某个其他线程的 managed object ，甚至是读取其中的属性都是不能做的。要想传递这样的对象，正确做法是通过传递它的 object ID ，然后从其他对应线程所绑定的 context 中去获取这个对象。

其实只要你遵循那些规则，并使用这篇文章里所描述的方法的话，处理 Core Data 的并行编程还是比较容易的。

Xcode 所提供的 Core Data 标准模版中，所设立的是运行在主线程中的一个存储调度 (persistent store coordinator)和一个托管对象上下文 (managed object context) 的方式。在很多情况下，这种模式可以运行良好。创建新的对象和修改已存在的对象开销都非常小，也都能在主线程中没有困难地完成。然后，如果你想要做大量的处理，那么把它放到一个后台上下文来做会比较好。一个典型的应用场景是将大量数据导入到 Core Data 中。

我们的方式非常简单，并且可以被很好地描述：

1. 我们为导入工作单独创建一个操作
2. 我们创建一个 managed object context ，它和主 managed object context 使用同样的 persistent store coordinator
3. 一旦导入 context 保存了，我们就通知 主 managed object context 并且合并这些改变

在[示例app][11]中，我们要导入一大组柏林的交通数据。在导入的过程中，我们展示一个进度条，如果耗时太长，我们希望可以取消当前的导入操作。同时，我们显示一个随着数据加入可以自动更新的 table view 来展示目前可用的数据。示例用到的数据是采用的 Creative Commons license 公开的，你可以[在此下载][12]它们。这些数据遵守一个叫做 [General Transit Feed][13] 格式的交通数据公开标准。

我们创建一个 `NSOperation` 的子类，将其叫做 `ImportOperation`，我们通过重写 `main` 方法，用来处理所有的导入工作。这里我们使用 `NSPrivateQueueConcurrencyType` 来创建一个独立并拥有自己的私有 dispatch queue 的 managed object context，这个 context 需要管理自己的队列。在队列中的所有操作必须使用 `performBlock` 或者 `performBlockAndWait` 来进行触发。这点对于保证这些操作能在正确的线程上执行是相当重要的。

    NSManagedObjectContext* context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = self.persistentStoreCoordinator;
    context.undoManager = nil;
    [self.context performBlockAndWait:^
    {
        [self import];
    }];

在这里我们重用了已经存在的 persistent store coordinator 。一般来说，初始化 managed object contexts 要么使用 `NSPrivateQueueConcurrencyType`，要么使用 `NSMainQueueConcurrencyType`。第三种并发类型 `NSConfinementConcurrencyType` 是为老旧代码准备的，我们不建议再使用它了。

在导入前，我们枚举文件中的各行，并对可以解析的每一行创建 managed object ：

    [lines enumerateObjectsUsingBlock:
      ^(NSString* line, NSUInteger idx, BOOL* shouldStop)
      {
          NSArray* components = [line csvComponents];
          if(components.count < 5) {
              NSLog(@"couldn't parse: %@", components);
              return;
          }
          [Stop importCSVComponents:components intoContext:context];
      }];

在 view controller 中通过以下代码来开始操作：

    ImportOperation* operation = [[ImportOperation alloc]
         initWithStore:self.store fileName:fileName];
    [self.operationQueue addOperation:operation];

至此为止，后台导入部分已经完成。接下来，我们要加入取消功能，这其实非常简单，只需要枚举的 block 中加一个判断就行了：

    if(self.isCancelled) {
        *shouldStop = YES;
        return;
    }

最后为了支持进度条，我们在 operation 中创建一个叫做 `progressCallback` 的属性。需要注意的是，更新进度条必须在主线程中完成，否则会导致 UIKit 崩溃。

    operation.progressCallback = ^(float progress)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^
        {
            self.progressIndicator.progress = progress;
        }];
    };

我们在枚举中来调用这个进度条更新的 block 的操作：

    self.progressCallback(idx / (float) count);

然而，如果你执行示例代码的话，你会发现它运行逐渐变得很慢，取消操作也有迟滞。这是因为主操作队列中塞满了要更新进度条的 block 操作。一个简单的解决方法是降低更新的频度，比如只在每导入一百行时更新一次：

    NSInteger progressGranularity = 100;

    if (idx % progressGranularity == 0) {
        self.progressCallback(idx / (float) count);
    }


### 更新 Main Context

在 app 中的 table view 是由一个在主线程上获取了结果的 controller 所驱动的。在导入数据的过程中和导入数据完成后，我们要在 table view 中展示我们的结果。

在让一切运转起来之前，还有一件事情要做。现在在后台 context 中导入的数据还不能传送到主 context 中，除非我们显式地让它这么去做。我们在 `Store` 类的设置 Core Data stack 的 `init` 方法中加入下面的代码：

    [[NSNotificationCenter defaultCenter]
        addObserverForName:NSManagedObjectContextDidSaveNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification* note)
    {
        NSManagedObjectContext *moc = self.mainManagedObjectContext;
        if (note.object != moc)
            [moc performBlock:^(){
                [moc mergeChangesFromContextDidSaveNotification:note];
            }];
        }];
    }];


如果 block 在主队列中被作为参数传递的话，那么这个 block 也会在主队列中被执行。如果现在你运行程序的话，你会注意到 table view 会在完成导入数据后刷新数据，但是这个行为会阻塞用户大概几秒钟。

要修正这个问题，我们需要做一些无论如何都应该做的事情：批量保存。在导入较大的数据时，我们需要定期保存，逐渐导入，否则内存很可能就会被耗光，性能一般也会更坏。而且，定期保存也可以分散主线程在更新 table view 时的工作压力。

合理的保存的次数可以通过试错得到。保存太频繁的话，可能会在 I/O 操作上花太多时间；保存次数太少的话，应用会变得无响应。在经过一些尝试后，我们设定每 250 次导入就保存一次。改进后，导入过程变得很平滑，它可以适时更新 table view，也没有阻塞主 context 太久。

### 其他考虑

在导入操作时，我们将整个文件都读入到一个字符串中，然后将其分割成行。这种处理方式对于相对小的文件来说没有问题，但是对于大文件，最好采用惰性读取 (lazily read) 的方式逐行读入。本文最后的示例将使用输入流的方式来实现这个特性，在 [StackOverflow][14] 上 Dave DeLong 也提供了一段非常好的示例代码来说明这个问题。

在 app 第一次运行时，除开将大量数据导入 Core Data 这一选择以外，你也可以在你的 app bundle 中直接放一个 sqlite 文件，或者从一个可以动态生成数据的服务器下载。如果使用这些方式的话，可以节省不少在设备上的处理时间。

最后，最近对于 child contexts 有很多争议。我们的建议是不要在后台操作中使用它。如果你以主 context 的 child 的方式创建了一个后台 context 的话，保存这个后台 context 将[阻塞主线程][15]。而要是将主 context 作为后台 context 的 child 的话，实际上和与创建两个传统的独立 contexts 来说是没有区别的。因为你仍然需要手动将后台的改变合并回主 context 中去。

设置一个 persistent store coordinator 和两个独立的 contexts 被证明了是在后台处理 Core Data 的好方法。除非你有足够好的理由，否则在处理时你应该坚持使用这种方式。

扩展阅读：

* [Core Data Programming Guide: Efficiently importing data](http://developer.apple.com/library/ios/#documentation/Cocoa/Conceptual/CoreData/Articles/cdImporting.html)
* [Core Data Programming Guide: Concurrency with Core Data](http://developer.apple.com/library/ios/#documentation/Cocoa/Conceptual/CoreData/Articles/cdConcurrency.html#//apple_ref/doc/uid/TP40003385-SW1j)
* [StackOverflow: Rules for working with Core Data](http://stackoverflow.com/questions/2138252/core-data-multi-thread-application/2138332#2138332)
* [WWDC 2012 Video: Core Data Best Practices](https://developer.apple.com/videos/wwdc/2012/?id=214)
* [Book: Core Data by Marcus Zarra](http://pragprog.com/book/mzcd/core-data)

## 后台 UI 代码

首先要强调：UIKit 只能在主线程上运行。而那部分不与 UIKit 直接相关，却会消耗大量时间的 UI 代码可以被移动到后台去处理，以避免其将主线程阻塞太久。但是在你将你的 UI 代码移到后台队列之前，你应该好好地测量哪一部分才是你代码中的瓶颈。这非常重要，否则你所做的优化根本是南辕北辙。

如果你找到了你能够隔离出的昂贵操作的话，可以将其放到操作队列中去：

    __weak id weakSelf = self;
    [self.operationQueue addOperationWithBlock:^{
        NSNumber* result = findLargestMersennePrime();
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            MyClass* strongSelf = weakSelf;
            strongSelf.textLabel.text = [result stringValue];
        }];
    }];


如你所见，这些代码其实一点也不直接明了。我们首先声明了一个 weak 引用来参照 self，否则会形成循环引用（ block 持有了 self，私有的 `operationQueue` retain 了 block，而 self 又 retain 了 `operationQueue` ）。为了避免在运行 block 时访问到已被释放的对象，在 block 中我们又需要将其转回 strong 引用。

> <p><span class="secondary radius label">编者注</span> 这在 ARC 和 block 主导的编程范式中是解决 retain cycle 的一种常见也是最标准的方法。

### 后台绘制

如果你确定 `drawRect:` 是你的应用的性能瓶颈，那么你可以将这些绘制代码放到后台去做。但是在你这样做之前，检查下看看是不是有其他方法来解决，比如、考虑使用 core animation layers 或者预先渲染图片而不去做 Core Graphics 绘制。可以看看 Florian 对在真机上图像性能测量的[帖子][16]，或者可以看看来自 UIKit 工程师 Andy Matuschak 对个各种方式的权衡的[评论][17]。

如果你确实认为在后台执行绘制代码会是你的最好选择时再这么做。其实解决起来也很简单，把 `drawRect:` 中的代码放到一个后台操作中去做就可以了。然后将原本打算绘制的视图用一个 image view 来替换，等到操作执行完后再去更新。在绘制的方法中，使用 `UIGraphicsBeginImageContextWithOptions` 来取代 `UIGraphicsGetCurrentContext` ：


    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    // drawing code here
    UIImage *i = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return i;


通过在第三个参数中传入 0 ，设备的主屏幕的 scale 将被自动传入，这将使图片在普通设备和 retina 屏幕上都有良好的表现。

如果你在 table view 或者是 collection view 的 cell 上做了自定义绘制的话，最好将它们放入 operation 的子类中去。你可以将它们添加到后台操作队列，也可以在用户将 cell 滚动出边界时的 `didEndDisplayingCell` 委托方法中进行取消。这些技巧都在 2012 年的WWDC [Session 211 -- Building Concurrent User Interfaces on iOS][18]中有详细阐述。

除了在后台自己调度绘制代码，以也可以试试看使用 `CALayer` 的 `drawsAsynchronously` 属性。然而你需要精心衡量这样做的效果，因为有时候它能使绘制加速，有时候却适得其反。

## 异步网络请求处理

你的所有网络请求都应该采取异步的方式完成。

然而，在 GCD 下，有时候你可能会看到这样的代码

    // 警告：不要使用这些代码。
    dispatch_async(backgroundQueue, ^{
       NSData* contents = [NSData dataWithContentsOfURL:url]
       dispatch_async(dispatch_get_main_queue(), ^{
          // 处理取到的日期
       });
    });

乍看起来没什么问题，但是这段代码却有致命缺陷。你没有办法去取消这个同步的网络请求。它将阻塞住线程直到它完成。如果请求一直没结果，那就只能干等到超时（比如 `dataWithContentsOfURL:` 的超时时间是 30 秒）。

如果队列是串行执行的话，它将一直被阻塞住。假如队列是并行执行的话，GCD 需要重开一个线程来补凑你阻塞住的线程。两种结果都不太妙，所以最好还是不要阻塞线程。

要解决上面的困境，我们可以使用 `NSURLConnection` 的异步方法，并且把所有操作转化为 operation 来执行。通过这种方法，我们可以从操作队列的强大功能和便利中获益良多：我们能轻易地控制并发操作的数量，添加依赖，以及取消操作。

然而，在这里还有一些事情值得注意： `NSURLConnection` 是通过 run loop 来发送事件的。因为时间发送不会花多少时间，因此最简单的是就只使用 main run loop 来做这个。然后，我们就可以用后台线程来处理输入的数据了。

另一种可能的方式是使用像 [AFNetworking](http://afnetworking.com) 这样的框架：建立一个独立的线程，为建立的线程设置自己的 run loop，然后在其中调度 URL 连接。但是并不推荐你自己去实现这些事情。

要处理URL 连接，我们重写自定义的 operation 子类中的 `start` 方法：

    - (void)start
    {
        NSURLRequest* request = [NSURLRequest requestWithURL:self.url];
        self.isExecuting = YES;
        self.isFinished = NO;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^
        {
            self.connection = [NSURLConnectionconnectionWithRequest:request
                                                           delegate:self];
        }];
    }


由于重写的是 `start` 方法，所以我们需要自己要管理操作的 `isExecuting` 和 `isFinished` 状态。要取消一个操作，我们需要取消 connection ，并且设定合适的标记，这样操作队列才知道操作已经完成。

    - (void)cancel
    {
        [super cancel];
        [self.connection cancel];
        self.isFinished = YES;
        self.isExecuting = NO;
    }

当连接完成加载后，它向代理发送回调：

    - (void)connectionDidFinishLoading:(NSURLConnection *)connection
    {
        self.data = self.buffer;
        self.buffer = nil;
        self.isExecuting = NO;
        self.isFinished = YES;
    }


就这么多了。完整的代码可以参见[GitHub上的示例工程][20]。

总结来说，我们建议要么你花时间来把事情做对做好，要么就直接使用像 [AFNetworking][19] 这样的框架。其实 [AFNetworking][19] 还提供了不少好用的小工具，比如有个 `UIImageView` 的 category，来负责异步地从一个 URL 加载图片。在你的 table view 里使用的话，还能自动帮你处理取消加载操作，非常方便。

扩展阅读：

* [Concurrency Programming Guide](http://developer.apple.com/library/ios/#documentation/General/Conceptual/ConcurrencyProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008091-CH1-SW1)
* [NSOperation Class Reference: Concurrent vs. Non-Concurrent Operations](http://developer.apple.com/library/ios/#documentation/Cocoa/Reference/NSOperation_class/Reference/Reference.html%23http://developer.apple.com/library/ios/#documentation/Cocoa/Reference/NSOperation_class/Reference/Reference.html%23//apple_ref/doc/uid/TP40004591-RH2-SW15)
* [Blog: synchronous vs. asynchronous NSURLConnection](http://www.cocoaintheshell.com/2011/04/nsurlconnection-synchronous-asynchronous/)
* [GitHub: `SDWebImageDownloaderOperation.m`](https://github.com/rs/SDWebImage/blob/master/SDWebImage/SDWebImageDownloaderOperation.m)
* [Blog: Progressive image download with ImageIO](http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/)
* [WWDC 2012 Session 211: Building Concurrent User Interfaces on iOS](https://developer.apple.com/videos/wwdc/2012/)

## 进阶：后台文件 I/O

在之前我们的后台 Core Data 示例中，我们将一整个文件加载到了内存中。这种方式对于较小的文件没有问题，但是受限于 iOS 设备的内存容量，对于大文件来说的话就不那么友好了。要解决这个问题，我们将构建一个类，它负责一行一行读取文件而不是一次将整个文件读入内存，另外要在后台队列处理文件，以保持应用相应用户的操作。

为了达到这个目的，我们使用能让我们异步处理文件的 `NSInputStream` 。根据[官方文档][21]的描述：

> 如果你总是需要从头到尾来读/写文件的话，streams 提供了一个简单的接口来异步完成这个操作

不管你是否使用 streams，大体上逐行读取一个文件的模式是这样的：

1. 建立一个中间缓冲层以提供，当没有找到换行符号的时候可以向其中添加数据
2. 从 stream 中读取一块数据
3. 对于这块数据中发现的每一个换行符，取中间缓冲层，向其中添加数据，直到（并包括）这个换行符，并将其输出
4. 将剩余的字节添加到中间缓冲层去
5. 回到 2，直到 stream 关闭

为了将其运用到实践中，我们又建立了一个[示例应用][22]，里面有一个 `Reader` 类完成了这件事情，它的接口十分简单

    @interface Reader : NSObject
    - (void)enumerateLines:(void (^)(NSString*))block
                completion:(void (^)())completion;
    - (id)initWithFileAtPath:(NSString*)path;
    @end


注意，这个类不是 NSOperation 的子类。与 URL connections 类似，输入的 streams 通过 run loop 来传递它的事件。这里，我们仍然采用 main run loop 来分发事件，然后将数据处理过程派发至后台操作线程里去处理。


    - (void)enumerateLines:(void (^)(NSString*))block
                completion:(void (^)())completion
    {
        if (self.queue == nil) {
            self.queue = [[NSOperationQueue alloc] init];
            self.queue.maxConcurrentOperationCount = 1;
        }
        self.callback = block;
        self.completion = completion;
        self.inputStream = [NSInputStream inputStreamWithURL:self.fileURL];
        self.inputStream.delegate = self;
        [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                    forMode:NSDefaultRunLoopMode];
        [self.inputStream open];
    }

现在，input stream 将（在主线程）向我们发送代理消息，然后我们可以在操作队列中加入一个 block 操作来执行处理了：

    - (void)stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode
    {
        switch (eventCode) {
            ...
            case NSStreamEventHasBytesAvailable: {
                NSMutableData *buffer = [NSMutableData dataWithLength:4 * 1024];
                NSUInteger length = [self.inputStream read:[buffer mutableBytes]
                                                 maxLength:[buffer length]];
                if (0 < length) {
                    [buffer setLength:length];
                    __weak id weakSelf = self;
                    [self.queue addOperationWithBlock:^{
                        [weakSelf processDataChunk:buffer];
                    }];
                }
                break;
            }
            ...
        }
    }


处理数据块的过程是先查看当前已缓冲的数据，并将新加入的数据附加上去。接下来它将按照换行符分解成小的部分，并处理每一行。

数据处理过程中会不断的从buffer中获取已读入的数据。然后把这些新读入的数据按行分开并存储。剩余的数据被再次存储到缓冲区中：


    - (void)processDataChunk:(NSMutableData *)buffer
    {
        if (self.remainder != nil) {
            [self.remainder appendData:buffer];
        } else {
            self.remainder = buffer;
        }
        [self.remainder obj_enumerateComponentsSeparatedBy:self.delimiter
                                                usingBlock:^(NSData* component, BOOL last) {
            if (!last) {
                [self emitLineWithData:component];
            } else if (0 < [component length]) {
                self.remainder = [component mutableCopy];
            } else {
                self.remainder = nil;
            }
        }];
    }

现在你运行示例应用的话，会发现它在响应事件时非常迅速，内存的开销也保持很低（在我们测试时，不论读入的文件有多大，堆所占用的内存量始终低于 800KB）。绝大部分时候，使用逐块读入的方式来处理大文件，是非常有用的技术。

延伸阅读：

* [File System Programming Guide: Techniques for Reading and Writing Files Without File Coordinators](http://developer.apple.com/library/ios/#documentation/FileManagement/Conceptual/FileSystemProgrammingGUide/TechniquesforReadingandWritingCustomFiles/TechniquesforReadingandWritingCustomFiles.html)
* [StackOverflow: How to read data from NSFileHandle line by line?](http://stackoverflow.com/questions/3707427/how-to-read-data-from-nsfilehandle-line-by-line)

## 总结

通过我们所列举的几个示例，我们展示了如何异步地在后台执行一些常见任务。在所有的解决方案中，我们尽力保持了代码的简单，这是因为在并发编程中，稍不留神就会捅出篓子来。

很多时候为了避免麻烦，你可能更愿意在主线程中完成你的工作，在你能这么做事，这确实让你的工作轻松不少，但是当你发现性能瓶颈时，你可以尝试尽可能用最简单的策略将那些繁重任务放到后台去做。

我们在上面例子中所展示的方法对于其他任务来说也是安全的选择。在主队列中接收事件或者数据，然后用后台操作队列来执行实际操作，然后回到主队列去传递结果，遵循这样的原则来编写尽量简单的并行代码，将是保证高效正确的不二法则。

---

 

   [1]: http://objccn.io/issue-2
   [6]: http://developer.apple.com/library/ios/#documentation/Cocoa/Reference/NSOperationQueue_class/Reference/Reference.html
   [7]: https://developer.apple.com/library/ios/#documentation/Performance/Reference/GCD_libdispatch_Ref/Reference/reference.html
   [8]: http://www.objccn.io/issue-2-1/
   [9]: http://www.objccn.io/issue-2-3/
   [10]: https://developer.apple.com/library/mac/#documentation/cocoa/conceptual/CoreData/Articles/cdConcurrency.html
   [11]: https://github.com/objcio/issue-2-background-core-data
   [12]: http://stg.daten.berlin.de/datensaetze/vbb-fahrplan-2013
   [13]: https://developers.google.com/transit/gtfs/reference
   [14]: http://stackoverflow.com/questions/3707427/how-to-read-data-from-nsfilehandle-line-by-line/3711079#3711079
   [15]: http://floriankugler.com/blog/2013/4/29/concurrent-core-data-stack-performance-shootout
   [16]: http://floriankugler.com/blog/2013/5/24/layer-trees-vs-flat-drawing-graphics-performance-across-ios-device-generations
   [17]: https://lobste.rs/s/ckm4uw/a_performance-minded_take_on_ios_design/comments/itdkfh
   [18]: https://developer.apple.com/videos/wwdc/2012/
   [19]: http://afnetworking.com/
   [20]: https://github.com/objcio/issue-2-background-networking
   [21]: http://developer.apple.com/library/ios/#documentation/FileManagement/Conceptual/FileSystemProgrammingGUide/TechniquesforReadingandWritingCustomFiles/TechniquesforReadingandWritingCustomFiles.html
   [22]: https://github.com/objcio/issue-2-background-file-io

原文 [Common Background Practices](http://www.objc.io/issue-2/common-background-practices.html)
   
译文 [常见的后台实践](http://onevcat.com/2014/03/common-background-practices/)
