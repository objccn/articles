## 简介

在理想情况下，你所做的所有测试都是能应对你实际代码的高级测试。例如，UI 测试将模拟实际的用户输入（Klaas 在[他的文章](http://objccn.io/issue-15-6)中有讨论）等等。实但际上，这并非永远都是个好主意。为每个测试用例都访问一次数据库或者旋转一次 UI 会使你的测试跑得非常慢，这会降低你的生产力，并导致你不去经常跑那些测试。若你测试的某段代码依赖于网络连接，这会要求你的测试环境具备网络接入条件，而且这也难以模拟某些特殊的测试，比如当电话处于飞行模式情况下的时候。

正因如此，我们可以用一些模拟代码替换你的实际代码来编写一些测试用例。

## 什么时候你会需要用到一些模拟 (mock) 对象呢？

让我们从以下这些不同类型的模拟对象的基本定义开始。

*double* 可以理解为置换，它是所有模拟测试对象的统称，我们也可以称它为替身。一般来说，当你创建任意一种测试置换对象时，它将被用来替代某个指定类的对象。

*stub* 可以理解为测试桩，它能实现当特定的方法被调用时，返回一个指定的模拟值。如果你的测试用例需要一个伴生对象来提供一些数据，可以使用 stub 来取代数据源，在测试设置时可以指定返回每次一致的模拟数据。

*spy* 可以理解为侦查，它负责汇报情况，持续追踪什么方法被调用了，以及调用过程中传递了哪些参数。你能用它来实现测试断言，比如一个特定的方法是否被调用或者是否使用正确的参数调用。当你需要测试两个对象间的某些协议或者关系时会非常有用。

*mock* 与 spy 类似，但在使用上有些许不同。*spy* 追踪所有的方法调用，并在事后让你写断言，而 mock 通常需要你事先设定期望。你告诉它你期望发生什么，然后执行测试代码并验证最后的结果与事先定义的期望是否一致。

*fake* 是一个具备完整功能实现和行为的对象，行为上来说它和这个类型的真实对象上一样，但不同于它所模拟的类，它使测试变得更加容易。一个典型的例子是使用内存中的数据库来生成一个数据持久化对象，而不是去访问一个真正的生产环境的数据库。

实践中，这些术语常常用起来不同于它们的定义，甚至可以互换。稍后我们在这篇文章中会看到一些库，它们自认为自己是 "mock 对象框架"，但是其实它们也提供 stub 的功能，而且验证行为的方式也类似于我描述的 "spy" 而不是 "mock"。所以不要太过于陷入这些词汇的细节；我下这些定义更多的是因为要在高层次上区分这些概念，并且它对考虑不同类型测试对象的行为会有帮助。

如果你对不同类型的模拟测试对象更多的细节讨论感兴趣，Martin Fowler 的文章 ["Mocks Aren't Stubs"](http://martinfowler.com/articles/mocksArentStubs.html) 被认为是关于这个问题的权威讨论。

### 模拟主义者 (Mockists) vs. 统计主义者 (Statists)

许多关于模拟对象的讨论主要是衍生自 Fowler 的文章的，它们讨论了两种不同类型的程序员，模拟主义者和统计主义者，所写的测试。

模拟主义的方式是测试对象之间的交互。通过使用模拟对象，你可以更容易地验证被测对象是否遵循了它与其他类已建立的协议，使得在正确的时间发生正确的外部调用。对于那些使用行为驱动 (behavior-driven) 的开发者来说，这种测试可以驱动出更好的生产代码，因为你需要明确模拟出特定的方法，这可以帮你设计出在两个对象之间使用的更优雅的API，这种想法与模拟驱动紧密联系在一起。因此模拟主义的测试更偏向于单元级别的测试，而不是完全的端到端 (end-to-end) 测试。

统计主义的方式是不使用模拟对象。这种思路是测试时只测试状态而不是行为，因此这种类型的测试更加健壮。使用模拟测试时，如果你更新了实际类的行为，模拟类也需要同步更新；如果你忘了这么做，你可能会遇到测试可以通过但是代码却不能正确工作的情况。通过强调在测试环境中只使用那些真正的代码，统计主义的测试可以帮助你减少测试代码和实现代码的耦合度，并降低出错率。这种类型的测试，您可能已经猜到，适合于更全面的端到端的测试。

当然，并不是说有两个对立的程序员学派；你不可能看到模拟主义和统计主义的当街对决。这种分歧是有用的，但是，得认识到 mock 在有些时候是你的工具箱里最好的工具，但是有时候又不是。不同类型的测试适用于不同的任务，并且最高效的测试套件往往是不同测试风格的集合体。仔细考虑你到底想要用单个测试来验证些什么，这能帮助你找到最合适的测试方式，而且能帮你决定对于当前工作来说，使用模拟测试对象是否是正确的工具。

## 深入代码

理论上谈起来所有一切都没什么问题，但让我们来看一个你需要用到 mock 的真实用例。

让我们试着测试一个对象，它上面有一个方法，是通过调用 `UIApplication` 的 `openURL:` 方法来打开另外一个应用程序。(这是我在测试我的 [IntentKit](http://intentkit.github.io) 库时遇到的一个真实问题。) 给这个用例写一个端到端的测试，就算是有可能做到，也是非常困难的，因为 '成功状态' 本身导致了应用程序的关闭。自然的选择是，模拟出一个 `UIApplication` 对象，并验证这个模拟对象是否确实调用了 `openURL` 方法打开正确的 URL。

假设这个对象有这样的方法：

    @interface AppLinker : NSObject
            - (instancetype)initWithApplication:(UIApplication *)application;
            - (void)doSomething:(NSURL *)url;
    @end

这是一个非常牵强的例子，但是请容忍我一下。在这个例子中，你会注意到我们使用了构造方法进行注入，当我们创建 `AppLinker` 的对象时将 `UIApplication` 对象注入到其中。大部分情况下，使用模拟对象要求使用某种形式的依赖注入。如果这个概念对你很陌生，请一定看看本期的 [Jon 的文章](http://objccn.io/issue-15-3/) 中的描述。

### OCMockito

[OCMockito](https://github.com/jonreid/OCMockito) 是一个非常轻量级的使用模拟对象的库：

    UIApplication *app = mock([UIApplication class]);
    AppLinker *linker = [AppLinker alloc] initWithApplication:app];
    NSURL *url = [NSURL urlWithString:@"https://google.com"];
    
    [linker doSomething:URL];
    
    [verify(app) openURL:url];

### OCMock

[OCMock](http://ocmock.org) 是另一个 Objective-C 的模拟对象库。和 OCMockito 类似，它提供了关于 stub 和 mock 的所有功能，并且包括了你可能需要的一切功能。它比 OCMockito 的功能更强，依赖于你的个人选择，各有利弊。

在最基本层面上，我们可以使用 OCMock 来重写出与之前非常类似的测试：

    id app = OCMClassMock([UIApplication class]);
    AppLinker *linker = [AppLinker alloc] initWithApplication:app];
    NSURL *url = [NSURL urlWithString:@"https://google.com"];
    
    [linker doSomething:url];
    
    OCMVerify([app openURL:url]);

这种在你测试后再验证调用方法的模拟测试风格被认为是一种 “运行后验证” 的方式。OCMock 只在最近 3.0 版本后增加了对该功能的支持。同时它也支持老版本的风格，即对期望运行的验证，在执行测试代码前先设定对测试结果的期望。最后，你只需要验证期望和实际结果是否对应：

    id app = OCMClassMock([UIApplication class]);

    AppLinker *linker = [AppLinker alloc] initWithApplication:app];
    NSURL *url = [NSURL urlWithString:@"https://google.com"];

    OCMExpect([app openURL:url]);

    [linker doSomething:url];
    
    OCMVerifyAll();
 
由于 OCMock 也支持对类方法的 stub，你也可以用这种方式来测试，如果 `doSomething` 方法通过 `[UIApplication sharedApplication]` 来实现而不是 `UIApplication` 对象的注入初始化：

    id app = OCMClassMock([UIApplication class]);
    OCMStub([app sharedInstance]).andReturn(app);

    AppLinker *linker = [AppLinker alloc] init];
    NSURL *url = [NSURL urlWithString:@"https://google.com"];
    
    [linker doSomething:url];
    
    OCMVerify([app openURL:url]);

你会发现 stub 类方法和 stub 实例方法看起来是一样的。

## 构建你自己的测试

对于像这种简单的用例，你也许不需要这么重量级的模拟对象测试库。通常，你只需要创建你自己的模拟对象来测试你关心的行为：

    @interface FakeApplication : NSObject
        @property (readwrite, nonatomic, strong) NSURL *lastOpenedURL;
        
        - (void)openURL:(NSURL *)url;
    @end
    
    @implementation FakeApplication
        - (void)openURL:(NSURL *)url {
            self.lastOpenedURL = url;
        }
    @end

以下是测试：

    FakeApplication *app = [[FakeApplication alloc] init];
    AppLinker *linker = [AppLinker alloc] initWithApplication:app];
    NSURL *url = [NSURL urlWithString:@"https://google.com"];
    
    [linker doSomething:url];
    
    XCAssertEqual(app.lastOpenedURL, url, @"Did not open the expected URL");

对于类似这个已经设计好的例子，就可能会出现这种情况，创造你自己的模拟对象只是增加了很多不必要的样板，但如果你觉得需要模拟更为复杂的对象交互，那么完全控制模拟对象的行为就会非常有价值。

### 使用哪一个？

选择哪一种方案完全依赖于你的具体测试情况以及你的个人偏好。OCMockito 和 OCMock 都可以通过 CocoaPods 安装，将它们集成到你现有的测试环境都非常简单，但需要注意的是，除非你需要，否则避免新增一些其他的依赖。另外除非真的需要，最好就都创建一些简单的模拟对象。

## 模拟测试时的注意事项

在任何形式的测试中你有可能碰到的最大的问题之一是写的测试和实现代码耦合过于紧密。测试中一个最重要的关键点是降低未来的变化所带来的成本；如果改变代码的实现细节破坏了当前的测试，则这种成本已经增加了。也就是说，其实为了最小化由于使用模拟测试所造成不利影响，其实你有很多可以做的。

### 依赖注入是你的好伙伴

如果你还没有使用[依赖注入](http://objccn.io/issue-15-3)，或许你会需要它。虽然有时候不使用依赖注入来模拟对象也是可以的的 (比如以上面使用 OCMock 模拟类方法)，但是通常是不太可能的。即使可能，设置测试所引入的复杂度也可能大于它能带来的好处。如果你使用依赖注入的话，你会发现使用 stub 和 mock 方式写测试要容易的多。

### 不要模拟你没有的

许多有经验的测试人员都会警告你“不要模拟你没有的东西”，意思是你应该只为你代码库本身拥有的对象创建 mock 或 stub，而不是为第三方依赖或一些库去创建。这里主要有两个原因，一个是基于实际情况的，一个是更具有哲学性的考虑。

对于你的代码库，你对它不同接口的稳定性和不稳定性大概会有一个感觉，所以你可以通过你的直觉来判断使用替换测试的方法是不是可能会导致测试过于脆弱。一般来说，你对第三方代码没有这样的把握。为了解决这个问题，一个通用的做法是为第三方代码创建包装类来抽象出它的行为。在某些情况下，仅仅是转移复杂性而不是降低复杂性往往是没什么意义的。但是在一些情况下，你会很经常使用你的第三方代码，这时这就是一个精简你测试的好方法。你的单元测试能模拟出自定义对象，并使用高层次的集成或功能测试来测试你的包装类本身。

iOS 和 OS X 开发世界的唯一性导致了事情稍微复杂一些。我们做的很多事情都依赖于 Apple 的框架，这个框架远远超过了其他语言的一些标准库。虽然 `NSUserDefaults` 不是一个“你拥有”对象，但是，如果你发现你有需要把它模拟出来，那就放心去做吧，苹果不太可能会在未来的 Xcode 的版本中推出打破这个 API 的变化。

另一个不要模拟第三方依赖库的原因更具哲学性。使用模拟主义风格书写测试的部分原因是通过这样的测试能比较容易的找到两个对象间最清晰可行的接口。但是如果是第三方依赖，你无法对其进行控制；API 协议中的一些详细信息已经被第三方库定死了，所以你无法通过测试来通过实验有效地验证接口是否有改进的余地。这本身不是问题，但在很多情况下，它降低了模拟测试的效果，直到把模拟测试的优点抹杀殆尽。

## 不要模仿我！

测试没有银弹；基于你的个人倾向和代码的具体特性，不同的情况下需要使用不同的策略。测试替身可能不适用所有的情况，但它们会是你测试工具箱中一个非常有效的工具。不管你倾向于使用框架在单元测试中模拟出一切，还是只是根据需要创建你自己的模拟对象，当你思考如何测试你的代码时，牢记模拟对象是非常有意义。

---

 

原文 [Test Doubles: Mocks, Stubs, and More](http://www.objc.io/issue-15/mocking-stubbing.html)