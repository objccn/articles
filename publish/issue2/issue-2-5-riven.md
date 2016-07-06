在开发高质量应用程序的过程中，测试是一个很重要的工具。在过去，当并发并不是应用程序架构中重要组成部分的时候，测试就相对简单。随着这几年的发展，使用并发设计模式已愈发重要了，想要测试好并发应用程序，已成了一个不小的挑战。

测试并发代码最主要的困难在于程序或信息流不是反映在调用堆栈上。函数并不会立即返回结果给调用者，而是通过回调函数，Block，通知或者一些类似的机制，这些使得测试变得更加困难。

然而，测试异步代码也会带来一些好处，比如可以揭露较差的程序设计，让最终的实现变得更加清晰。


## 异步测试的问题

首先，我们来看一个简单的同步单元测试例子。两个数求和的方法：

    + (int)add:(int)a to:(int)b {
        return a + b;
    }

测试这个方法很简单，只需要比较该方法返回的值是否与期望的值相同，如果不相同，则测试失败。

    - (void)testAddition {
        int result = [Calculator add:2 to:2];
        STAssertEquals(result, 4, nil);
    }

接下来，我们利用 Block 将该方法改成异步返回结果。为了模拟测试失败，我们会在方法实现中故意添加一个 bug。

    + (int)add:(int)a to:(int)b block:(void(^)(int))block {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            block(a - b); // 带有bug的实现
        }];
    }

显然这是一个人为的例子，但是它却真实的反应了在编程中可能经常遇到的问题，只不过实际过程更复杂罢了。

测试上面的方法最简单的做法就是把断言放到 Block 中。尽管我们的方法实现中存在 bug，但是这种测试永远不会失败的:


	// 千万不要使用这些代码！
    - (void)testAdditionAsync {
        [Calculator add:2 to:2 block:^(int result) {
            STAssertEquals(result, 4, nil); // 永远不会被调用到
        }];
    }

这里的断言为什么没失败呢?


## 关于SenTestingKit

XCode4 所使用的测试框架是基于 [OCUnit][4]。为了理解之前所提到的异步测试问题，我们需要了解一下测试包中的各个部分之间的执行顺序。下图展示了一个简化的流程。

<img src="/images/issues/issue-2/SenTestingKit-call-stack.png" style="width:698px" alt="SenTestingKit call stack"/>

在测试框架在主 run loop 开始运行之后，主要执行了以下几个步骤：

1. 配置一个包含所有相关测试的测试包 (比如可以在工程的 scheme 中配置)。
2. 运行测试包，内部会调用所有以 _test_ 开头测试用例的方法。运行结束后会返回一个包含单个测试结果的对象。
3. 调用 `exit()` 退出测试。

这其中我们最感兴趣的是单个测试是如何被调用的。在异步测试中，包含断言的 Block 会被加到主 run loop。当所有的测试执行完毕后，测试框架就会退出，而 block 却从来没有被执行，因此不会引起测试失败。

当然我们有很多种方发来解决这个问题。但是所有的方法都必须在主 run loop 中运行，而且在测试方法返回和比较结果之前需要处理已入队所有操作。

[Kiwi][5] 使用探测轮询 (probe poller)，它可以在测试方法中被调用。 [GHUnit][6] 编写了一个单独的测试类，它必须在测试的方法内初始化，并在结束时接收一个通知。以上两种方式都是通过编写相应的代码来确保异步测试方法在测试结束之前都不会返回。


## SenTestingKit的异步扩展

我们对这个问题的解决方案是对 SenTestingKit 添加一个[扩展][2]，它在栈上使用同步执行，并把每个部分加入到主队列上。正如下图所见，在验证整个测试框架结果之前，报告异步测试成功或者失败的 Block 就被加入到队列。这种执行顺序允许我们开启一个测试并等待它的测试结果。

<img src="/images/issues/issue-2/SenTestingKitAsync-call-stack.png" style="width:531px" alt="SenTestingKitAsync call stack"/>

如果测试方法以 __Async__ 结尾，框架就会认为该方法是异步测试。此外，在异步测试中，我们必须手动地报告测试成功，同时为了防止 Block 永远不会被调用，我们还需添加了一个超时方法。之前的错误的测试方法修改后如下所示：

    - (void)testAdditionAsync {
        [Calculator add:2 to:2 block^(int result) {
            STAssertEquals(result, 4, nil);
            STSuccess(); // 通过调用这个宏来判断是否测试成功
        }];
        STFailAfter(2.0, @"Timeout");
    }


## 设计异步测试

就像同步测试一样，异步测试也应该比被测试的功能简单许多。复杂的测试并不会改进代码的质量，反而会给测试本身带来更多的 Bug。在以测试驱动开发的情况下，简单的测试会让我们对组件，接口以及架构的行为有更清醒的认识。


### 示例工程

为了运用到实际中，我们创建了一个示例框架：[PinacotecaCore][3]，它从一个虚拟的服务器获取图像信息。框架中包含一个资源管理器，它对外提供一个可以根据图像 Id 获取图像对象的接口。该接口的工作原理是资源管理器从虚拟服务器获取图片对象的信息，并更新到数据库。

虽然这个示例框架只是为了演示，但在我们自己开发的许多应用中也使用了这种模式。

<img src="/images/issues/issue-2/PinacotecaCore.png" style="width:699px" alt="PinacotecaCore architecture"/>

从上图我们可以知道，示例框架有三个组件我们需要测试：

1. 模型层
2. 模拟服务器请求的服务器接口控制器（API Controller）
3. 管理 core data 堆栈以及连接模型层和服务接口控制器的资源管理器

### 模型层

测试应该尽量使用同步的方式进行，而模型层就是一个很好的实例。只要不同的被托管对象上下文 (managed object contexts) 之间没有复杂的依赖关系，测试用例都应该根据上下文在主线程上设置它自己的 core data 堆栈，并在其中执行各自的操作。

在这个[测试实例][7]中，我们就是在 `setUp` 方法中设置 core data 堆栈，然后检查 `PCImage` 实体的描述是否存在，如果不存在就构造一个，并更新它的值。当然这和异步测试没有关系，我们就不深入细说了。

### 服务器接口控制器

框架中的第二个组件就是服务器接口控制器。它主要处理服务器请求以及服务器 API 到模型的映射关系。让我们来看一下下面这个方法：

    - [PCServerAPIController fetchImageWithId:queue:completionHandler:]

调用它需要三个形参：一个图片对象 Id，所在的执行队列以及一个完成后的回调方法。

因为服务器根本不存在，一个比较好的做法就是伪造一个代理服务器，正好 [OHHTTPStubs][8] 可以解决这个问题。在它的最新版本中，可以在示例的请求响应中包含一个 bundle，发送给客户端。

为了能 stub 请求，OHHTTPStubs 需要在测试类初始化时或者 setUp 方法中进行配置。首先，我们需要加载一个包含请求响应对象（response）的 bundle：

    NSURL *url = [[NSBundle bundleForClass:[self class]]
                            URLForResource:@"ServerAPIResponses"
                             withExtension:@"bundle"];
                                                 
    NSBundle *bundle = [NSBundle url];

然后我们从 bundle 加载 response 对象，作为请求的响应值：
    
    OHHTTPStubsResponse *response;
    response = [OHHTTPStubsResponse responseNamed:@"images/123"
                                       fromBundle:responsesBundle
                                     responseTime:0.1];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES /* 如果所返回的request是我们所期望的，就返回YES */;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return response;
    }];
    
通过如上的设置之后，简化版的[测试服务器接口控制器][9]如下：

    - (void)testFetchImageAsync
    {
        [self.server
            fetchImageWithId:@"123"
                       queue:[NSOperationQueue mainQueue]
           completionHandler:^(id imageData, NSError *error) {
              STAssertEqualObjects([NSOperationQueue currentQueue], queue, nil);
              STAssertNil(error, [error localizedDescription]);
              STAssertTrue([imageData isKindOfClass:[NSDictionary class]], nil);
                    
              // 检查返回的字典中的值.
                    
              STSuccess();
           }];
        STFailAfter(2.0, nil);    
    }


### 资源管理器

最后一个部分是资源管理器，它不但把服务器接口控制器和模型层联系起来, 还管理着 core data 堆栈。下面我们想测试获取一个图片对象的方法：

    -[PCResourceManager imageWithId:usingManagedObjectContext:queue:updateHandler:]

该方法根据 id 返回一个图片对象。如果图片在数据库中不存在，它会创建一个只包含 id 的新对象，然后通过服务器接口控制器获取图片对象的详细信息。

由于资源管理器的测试不应该依赖于服务器接口控制器，所以我们可以用 [OCMock][10] 来模拟，如果要做方法的部分 stub，它是一个理想的框架。如以下的 [资源管理器测试][11] :

    OCMockObject *mo;
    mo = [OCMockObject partialMockForObject:self.resourceManager.server];
    
    id exp = [[serverMock expect] 
                 andCall:@selector(fetchImageWithId:queue:completionHandler:)
                onObject:self];
    [exp fetchImageWithId:OCMOCK_ANY queue:OCMOCK_ANY completionHandler:OCMOCK_ANY];

上面的代码实际上它并没有真正调用服务器接口控制器的方法，而是调用我们写在测试类中的方法。

用上面的做法，对资源管理的测试就变得很直观。当我们调用资源管理器获取资源时，实际上调用的是我们模拟的服务器接口控制器的方法。这样我们也能检查调用服务器接口控制器时参数是否正确。在调用了获取图像对象的方法后，资源管理器会更新模型，然后调用验证测试成功与否的宏。

    - (void)testGetImageAsync
    {
        NSManagedObjectContext *ctx = self.resourceManager.mainManagedObjectContext;
        __block PCImage *img;
        img = [self.resourceManager imageWithId:@"123"
                      usingManagedObjectContext:ctx
                                          queue:[NSOperationQueue mainQueue]
                                  updateHandler:^(NSError *error) {
                                           // 检查error是否为空以及image是否已经被更新 
                                           STSuccess();
                                       }];    
        STAssertNotNil(img, nil);
        STFailAfter(2.0, @"Timeout");
    }


## 总结

刚开始时候，使用并发设计模式测试应用程序是具有一定的挑战性，但是一旦你理解了它们的不同，并建立最佳实践，一切都会变得简单而有趣。

在 [nxtbgthng][1] 项目中，我们用 [SenTestingKitAsync][2] 框架来测试。但是像 [Kiwi][5] 和 [GHUnit][6]  也都是不错的异步测试框架。建议你都可以尝试下，然后找到合适自己的测试工具并开始使用它。

---

 

[1]: http://nxtbgthng.com  "nxtbgthng"
[2]: https://github.com/nxtbgthng/SenTestingKitAsync "SenTestingKitAsync"
[3]: https://github.com/objcio/issue-2-async-testing "Pinacoteca Core: Cocoa Framework for an Imaginary Image Service"
[4]: http://www.sente.ch/software/ocunit/ "OCUnit"
[5]: https://github.com/allending/Kiwi "Kiwi"
[6]: https://github.com/gabriel/gh-unit/ "GHUnit"
[7]: https://github.com/objcio/issue-2-async-testing/blob/master/PinacotecaCore/PinacotecaCoreTests/PCModelLayerTests.m "Pinacoteca Core Model Layer Tests"
[8]: https://github.com/AliSoftware/OHHTTPStubs "OHHTTPStubs"
[9]: https://github.com/objcio/issue-2-async-testing/blob/master/PinacotecaCore/PinacotecaCoreTests/PCServerAPIControllerTests.m "Pinacoteca Core Server API Controller Tests"
[10]: http://ocmock.org "OCMock"
[11]: https://github.com/objcio/issue-2-async-testing/blob/master/PinacotecaCore/PinacotecaCoreTests/PCResourceManagerTests.m "Pinacoteca Core Resource Manager Tests"
[12]: http://objccn.io/issue-2

原文 [Testing Concurrent Applications](http://www.objc.io/issue-2/async-testing.html)
   
译文 [iOS系列译文：测试并发程序](http://blog.jobbole.com/53377/)

精细校对 [xinjixjz](https://github.com/xinjixjz)