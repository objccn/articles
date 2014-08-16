## Intro

In an ideal world, all of your tests would be high-level tests that run against your actual code. UI tests would simulate actual user input (as Klaas discusses in [his article](/issue-15/user-interface-testing.html)), etc. In practice, this isn't always a good idea. Hitting the database or spinning up a UI for every test can make your test suite too slow, which either slows down productivity or encourages you to not run your tests as often. If the code you're testing depends on a network connection, this requires that your test environment has network access, and also makes it difficult to simulate edge cases, like when a phone is in airplane mode.

# 简介

在理想情况下，你所做的所有测试都是能应对你实际代码的高级测试。例如，UI 测试将模拟实际的用户输入（Klaas 在[他的文章]中有讨论(/issue-15/user-interface-testing.html)）等等。实际上，这不是一个好想法。为每个测试用例都访问一次数据库或者旋转一次 UI 会使你的测试套件跑得非常慢，同时也会降低你的生产力，并促使你不去经常跑那些测试。若你测试的某段代码依赖于网络连接，这会要求你的测试环境具备网络接入条件，并且这也难以模拟一些特殊测试，比如当处于飞行模式情况下的来电测试。

Because of all that, it can often be useful to write tests that replace some of your actual code with fake code.
正因如此，我们可以用一些模拟代码替换你的实际代码来编写一些测试用例。

## When Would You Want to Use Some Sort of Mock Object?
# 什么时候你会需要用到一些模拟对象呢？

Let's start with some basic definitions of the different sorts of fake objects there are.
让我们从以下这些不同类型的模拟对象的基本定义开始。

A *double* is a general catch-all term for any sort of fake test object. In general, when you create any sort of test double, it's going to replicate an object of a specific class. 
*double* 是所有模拟测试对象的统称，我们也可以称它为替身。一般来说，当你创建一种模拟测试对象，它会复制产生一个指定类的对象。

A *stub* can be told to return a specified fake value when a given method is called. If your test subject requires a companion object to provide some sort of data, you can use a stub to "stub out" that data source and return consistent fake data in your test setup.
*stub* 可以理解为测试桩，它能实现当特定的方法被调用时，返回一个指定的模拟值，如果你的测试用例需要一个伴生对象来提供一些数据，可以使用 stub 来去掉数据源，在测试设置时可以指定需要返回一致的模拟数据。

A *spy* keeps track of what methods are called, and what arguments they are called with. You can use it to make test assertions, like whether a specific method was called or that it was called with the correct argument. This can be valuable for when you want to test the contract or relationship between two objects.
*spy* 可以理解为间谍，它负责汇报情况，它持续追踪什么方法被调用了，以及调用过程中传递了哪些参数。你能用它来实现测试断言，比如一个特定的方法是否被调用或者是否使用正确的参数调用。当你需要测试协议或者两个对象间的关系时这就显得非常有价值。

A *mock* is similar to a spy, but the way you use it differs slightly. Rather than just capturing all method calls and letting you write assertions on them after the fact, a mock typically requires you to set up expectations beforehand. You tell it what you expect it to happen, execute the code you're testing, and then verify that the correct behavior happened.
*mock* 与 spy 类似，但在使用上有些许不同。不仅仅是追踪所有的方法调用，并在事后让你写断言，mock 通常需要你事先设定期望。你告诉它你期望发生什么，然后执行测试代码并验证最后的结果与事先定义的期望是否一致。

A *fake* is an object that has a full working implementation and behaves like a real object of its type, but differs from the class it is faking in a way that makes things easier to test. A classic example would be a data persistence object that uses an in-memory database instead of hitting a real production database.
*fake* 是一个具备完整功能实现和行为的对象，好比一个它本身类型的真实对象，但不同于它所模拟的类，它使测试变得更加容易。一个典型的例子是使用内存中的一个持久化数据库对象，而不是去访问一个真正的生产数据库。

In practice, these terms are often used differently than these definitions, or even interchangeably. The libraries we'll be looking at later in this article consider themselves to be "mock object frameworks"—even though they also provide stubbing capabilities, and the way you verify behavior more resembles what I've described as "spies" rather than "mocks." But don't get too caught up on the specifics of the vocabulary; I give these definitions more because it's useful to think about different types of test object behaviors as distinct concepts at a high level.
实践中，这些术语常常用起来不同于他们的定义，甚至可以互换。稍后我们在这篇文章中会看到一些库，考虑到它们本身是“模拟对象框架”，即使也提供 stub 的功能，且验证行为的方式类似于我描述的“间谍”（spy）而不是“模仿”（mock）。但不要太过于陷入这些词汇的细节；我下这些定义更多的是因为要在高层次上区分这些概念，并且它对考虑不同类型测试对象的行为非常有用。

If you're interested in a more in-depth discussion about the different types of fake test objects, Martin Fowler's article, ["Mocks Aren't Stubs,"](http://martinfowler.com/articles/mocksArentStubs.html) is considered the definitive article on the subject.
如果你对不同类型的模拟测试对象更多的细节讨论感兴趣，Martin Fowler 的文章["Mocks Aren't Stubs,"](http://martinfowler.com/articles/mocksArentStubs.html) 被认为是关于这个问题的权威讨论。

### Mockists vs. Statists
## Mockists vs. Statists

Many discussions of mock objects, mostly deriving from the Fowler article, talk about two different types of programmers who write tests: mockists and statists. 
许多关于模拟对象的讨论，主要是衍生自 Fowler 的文章，讨论两种不同类型的程序员写的测试：mockists和statists。

The mockist way of doing things is about testing the interaction between objects. By using mock objects, you can more easily verify that the subject under test follows the contract it has established with other classes, making the correct external calls at the correct time. For those who practice behavior-driven development, this is intricately tied in with the idea that your tests can help drive out better production code, as needing to explicitly mock out specific method calls can help you design a more elegant API contract between two objects. This sort of testing lends itself more to unit-level tests than full end-to-end tests.
Mockist 的方式是有关测试对象之间的交互。通过使用模拟对象，你可以更容易地验证被测对象是否遵循了它与其他类已建立的协议，使得在正确的时间发生正确的外部调用。对于那些实行行为驱动（behavior-driven）的开发，这是复杂的联系与想法，你的测试可以驱动出更好的生产代码，明确模拟出特定的方法，可以帮你设计出在两个对象之间使用的更优雅的API。这种类型的测试更适合于比较充分的端到端的单元测试。

The statist way of doing things doesn't use mock objects. The idea is that your tests should test state, rather than behavior, as that sort of test will be more robust. Mocking out a class requires you to update your mock if you update the actual class behavior; if you forget to do so, you can get into situations where your tests pass but your code doesn't work. By emphasizing only using real collaborators in your test environment, statist testing can help minimize tight coupling of your tests and your implementation, and reduce false negatives. This sort of testing, as you might guess, lends itself to more full end-to-end tests.
Statist 的方式不使用模拟对象。这种思路是测试时只测试状态而不是行为，这种类型的测试更加健壮。如果你更新了实际类的行为，当模拟类时需要同步更新模拟对象；如果你忘了这么做，你可以到你测试没有通过的代码出进行修改，但此时你的代码不能正常工作。强调在测试环境中真正的合作者，statist 测试可以帮助减少你的测试和实现的耦合度，降低出错率。这种类型的测试，您可能已经猜到，适合于更全面的端到端的测试。

Naturally, it's not like these are two rival schools of programmers; you'd be hard-pressed to see a mockist and a statist dueling it out on the street. This dichotomy is useful, though, in terms of recognizing that there are times when mocks are and are not the most appropriate tools in your tool belt. Different kinds of tests are useful for different tasks, and the most effective test suites will tend to have a blend of different testing styles. Thinking about what you are trying to accomplish with an individual test can help you figure out the best approach to take, and whether or not fake test objects might be the right tool for the job.
当然，它不像是两个对立学校的程序员；你很难看到 mockist 和 statist 当场决斗。这种分歧是有用的，但是，得认识到有些时候 mock 并不是最合适的工具。不同类型的测试适用于不同的任务，并且，最高效的测试套件往往是不同测试风格的集合体。考虑你要完成的单元测试能帮助你找到最合适的测试方式，并且，对于当前工作来说，是否使用模拟测试对象也只是一个工具而已。

## Diving into Code
# 深入代码

Talking about this theoretically is all well and good, but let's look at a real-word use case where you'd need to use mocks.
理论上谈起来所有的都是好的，但让我们来看一个用到 mock 的真实用例。

Let's say we're trying to test an object with a method that opens another application by calling `UIApplication`'s `openURL:` method. (This is a real problem I faced while testing my [IntentKit](http://intentkit.github.io)  library.) Writing an end-to-end test for this is difficult (if not impossible), since 'success' involves closing your application. The natural choice is to mock out a `UIApplication` object, and assert that the code in question calls `openURL` on that object, with the correct URL.
让我们试着测试一个对象的方法，通过调用 `UIApplication` 的 `openURL:`方法来打开另外一个应用程序。（这是我在测试我的 [IntentKit](http://intentkit.github.io) 库时遇到的一个真实问题。）给这个用例写一个端到端的测试是困难的（如果有可能的话），因为成功状态时本身就包含了关闭应用程序。自然的选择是，模拟出一个 `UIApplication` 对象，并用这个模拟对象来调用 `openURL` 方法打开正确的 URL。

Imagine the object in question has a single method:
假设这个对象有一个单独的方法：

    @interface AppLinker : NSObject
            - (instancetype)initWithApplication:(UIApplication *)application;
            - (void)doSomething:(NSURL *)url;
    @end

This is a pretty contrived example, but bear with me. In this case, you'll notice we're using constructor injection to inject a `UIApplication` object when we create our instance of `AppLinker`. In most cases, using mock objects is going to require some form of dependency injection. If this is a foreign concept to you, definitely check out [Jon's article](/issue-15/dependency-injection.html) in this issue.
这是一个非常牵强的例子，但是请容忍我一下。在这个例子中，你会注意到我们使用了构造器注入，当我们创建 `AppLinker` 的对象时将它注入到 `UIApplication` 对象。大部分情况下，使用模拟对象要求使用某种形式的依赖注入。如果这个概念对你很陌生，你可以看看在 [Jon的文章](/issue-15/dependency-injection.html) 中的描述。

### OCMockito

[OCMockito](https://github.com/jonreid/OCMockito) is a very lightweight mocking library: 
[OCMockito](https://github.com/jonreid/OCMockito) 是一个非常轻量级的使用模拟对象的库：

    UIApplication *app = mock([UIApplication class]);
    AppLinker *linker = [AppLinker alloc] initWithApplication:app];
    NSURL *url = [NSURL urlWithString:@"https://google.com"];
    
    [linker doSomething:URL];
    
    [verify(app) openURL:url];

### OCMock

[OCMock](http://ocmock.org) is another Objective-C mock object library. Like OCMockito, it provides full functionality for stubs, mocks, and just about everything else you might want. It has a lot more functionality than OCMockito, which, depending on your personal preference, could be a benefit or a drawback.
[OCMock](http://ocmock.org) 是另一个 Objective-C 的模拟对象库。和 OCMockito 类似，它提供了关于 stub 和 mock 的所有功能，并且包括了你可能需要的一切功能。它比 OCMockito 的功能更强，依赖于你的个人选择，各有利弊。

At the most basic level, we can rewrite the previous test using OCMock in a way that will look very familiar:
在最基本层面上，我们可以使用 OCMock 来重写出与之前非常类似的测试：

    id app = OCMClassMock([UIApplication class]);
    AppLinker *linker = [AppLinker alloc] initWithApplication:app];
    NSURL *url = [NSURL urlWithString:@"https://google.com"];
    
    [linker doSomething:url];
    
    OCMVerify([app openURL:url]);

This style of mocking, where you verify that a method was called after your test, is known as a "verify after running" approach. OCMock just added support for this in its recent 3.0 release. It also supports an older style, known as expect-run-verify, that has you setting up your expectations before executing the code you are testing. At the end, you simply verify that the expectations were met:
这种验证在你测试后调用方法的模拟测试风格被认为是一种“验证后运行”的方式。OCMock 只在3.0版本后增加了对该功能的支持。同时它也支持老版本的风格，即验证运行期望，在执行测试代码前先设定对测试结果的期望。最后，你只需要验证期望和实际结果是否对应：

    id app = OCMClassMock([UIApplication class]);

    AppLinker *linker = [AppLinker alloc] initWithApplication:app];
    NSURL *url = [NSURL urlWithString:@"https://google.com"];

    OCMExpect([app openURL:url]);

    [linker doSomething:url];
    
    OCMVerifyAll();


Because OCMock lets you stub out class methods, you could also test this using OCMock, if your implementation of `doSomething` uses `[UIApplication sharedApplication]` rather than the `UIApplication` object injected in the initializer: 
由于 OCMock 也支持对类方法的 stub，你也可以用这种方式来来测试，如果 `doSomething` 方法通过 `[UIApplication sharedApplication]` 来实现而不是 `UIApplication` 对象的注入初始化：

    id app = OCMClassMock([UIApplication class]);
    OCMStub([app sharedInstance]).andReturn(app);

    AppLinker *linker = [AppLinker alloc] init];
    NSURL *url = [NSURL urlWithString:@"https://google.com"];
    
    [linker doSomething:url];
    
    OCMVerify([app openURL:url]);

You'll notice that stubbing out class methods looks exactly the same as stubbing out instance methods.
你会发现 stub 出类方法和 stub 的实例方法看起来是一样的。

## Roll Your Own
# 构建你自己的测试

For a simple use case like this, you might not need the full weight of a mock object library. Often, you can just as easily create your own fake object to test the behavior you care about:
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

And then the test:
以下是测试：

    FakeApplication *app = [[FakeApplication alloc] init];
    AppLinker *linker = [AppLinker alloc] initWithApplication:app];
    NSURL *url = [NSURL urlWithString:@"https://google.com"];
    
    [linker doSomething:url];
    
    XCAssertEqual(app.lastOpenedURL, url, @"Did not open the expected URL");

For a contrived example such as this, it might appear that creating your own fake object just adds in a lot of unnecessary boilerplate, but if you find yourself needing to simulate more complex object interactions, having full control over the behavior of your mock object can be very valuable.
对于类似这个已经设计好的例子，就可能会出现这种情况，创造你自己的模拟对象只是增加了很多不必要的样板，但如果你觉得需要模拟更为复杂的对象交互，完全控制你的模拟对象的行为是非常有价值的。

### Which to Use?
## 使用哪一个？

Which approach you take depends completely on both the specifics of what you're testing and your own personal preference. OCMockito and OCMock are both installable via CocoaPods, so they're easy to integrate with your existing test setup, but there is also something to be said for avoiding adding dependencies and creating simple mock objects until you need something more. 
选择哪一种方案完全依赖于你的具体测试情况以及你的个人偏好。OCMockito 和 OCMock都需要通过 CocoaPods 安装，集成它们到你现有的测试环境都非常简单，但需要注意的是，除非你需要，否则避免新增一些其他的依赖和创建一些模拟对象。

## Things to Watch Out for While Mocking
# 模拟测试时的注意事项

One of the biggest problems you run into with any form of testing is writing tests that are too tightly coupled to the implementation of your code. One of the biggest points of testing is to reduce the cost of future change; if changing the implementation details of some of your code breaks your tests, you've increased that cost. That said, there are a number of things you can do to minimize the possible negative effects of using test fakes.
在任何形式的测试中你有可能碰到的最大的问题之一是写的测试和实现代码耦合过于紧密。测试中一个最重要的关键点是降低未来的变化所带来的成本；如果改变代码的实现细节破坏了当前的测试，则这种成本已经增加了。也就是说，你能做一些事情来来最小化由于使用模拟测试所造成不利影响。

### Dependency Injection Is Your Friend
##依赖注入是你的好伙伴

If you're not already using [dependency injection](/issue-15/dependency-injection.html), you probably want to. While there are sometimes sensible ways to mock out objects without DI (typically by mocking out class methods, as seen in the OCMock example above), it's often flat out not possible. Even when it is possible, the complexity of the test setup might outweigh the benefits. If you're using dependency injection consistently, you'll find writing tests using stubs and mocks will be much easier.

如果你还没有使用[依赖注入](/issue-15/dependency-injection.html)，或许你会需要它。有时候不使用依赖注入来模拟对象是明智的（以上面使用 OCMock 模拟类方法为例），通常是不太可能的。即使是可能的，测试设置的复杂性也可能大于好处。如果你坚持使用依赖注入，你会发现使用 stub 和 mock 方式写测试要容易的多。

### Don't Mock What You Don't Own
## 不要模拟你没有的
Many experienced testers warn that you "shouldn't mock what you don't own," meaning that you should only create mocks or stubs of objects that are part of your codebase itself, rather than third-party dependencies or libraries. There are two main reasons for this, one practical and one more philosophical.
许多有经验的测试人员都会警告你“不要模拟你没有的”，意思是你应该只创建你代码库本身的模拟方法或对象，而不是第三方依赖或一些库。这里主要有两个原因，一个是基于实际情况的，一个是更具有哲学性的考虑。

With your codebase, you probably have a sense of how stable or volatile different interfaces are, so you can use your gut feeling about when using a double might lead to brittle tests. You generally have no such guarantee with third-party code. A common way to get around this is to create your own wrapper class to abstract out the third-party code's behavior. This can, in some situations, amount to little more than just shifting your complexity elsewhere without decreasing it meaningfully, but in cases where your third-party library is used very frequently, it can be a great way to clean up your tests. Your unit tests can mock out your own custom object, leaving your higher-level integration or functional tests to test the implementation of your wrapper itself. 
基于你的代码库，你或许对它不同接口的稳定性和不稳定性有一个感觉，所以你可以通过你的直觉来判断使用这两种方法可能会导致的脆弱测试。通常你对第三方代码没有十足的把握，关于这个问题，一个通用的做法是为第三方代码创建包装类来抽象出它的行为。在某些情况下，仅仅是转移复杂性而不是降低复杂性往往是没有意义的，但是一些情况下使用第三方的代码非常频繁，这就是一个精简你测试的好方法。你的单元测试能模拟出自定义对象，将高级集成或功能测试与包装类本身分离开。

The uniqueness of the iOS and OS X development world complicates things a bit, though. So much of what we do is dependent on first-party frameworks, which tend to be more overreaching than the standard library in many other languages. Although `NSUserDefaults` is an object you 'don't own,' for example, if you find yourself needing to mock it out, it's a fairly safe bet that Apple won't introduce breaking API changes in a future Xcode release.
由于 iOS 和 OS X 开发世界的唯一性有点复杂。我们做的很多事情都依赖于自身的框架，这往往超过其他语言的一些标准库。虽然 `NSUserDefaults` 是一个“你没有的”对象，例如，如果你发现你需要把它模拟出来，那这就是一个相当可靠的打赌，苹果不会在未来 Xcode 的更新中推出打破这项 API 的变化。

The other reason to not mock out third-party dependencies is more philosophical. Part of the reason to write tests in a mockist style is to make it easier to find the cleanest possible interface between your two objects. But with a third-party dependency, you don't have control over that; the specifics of the API contract are already set in stone by a third party, so you can't effectively use tests as an experiment to see if things could be improved. This isn't a problem, per se, but in many cases, it reduces the effectiveness of mocking to the point that it's no longer worth it.
另一个不要模拟第三方依赖库的原因是更具哲学性的。部分原因是通过 Mock 的风格写测试能比较容易的找到两个对象间最清晰可行的接口。但是如果是第三方依赖，你无法控制这种情况；API 协议中的一些详细信息已经被第三方库设定了，所以你无法通过测试做一个有效的实验来验证。这本身不是问题，但在很多情况下，它降低了模拟的有效性，这是不值得的。

## Don't Mock Me!
# 不要模仿我！
There is no silver bullet in testing; different strategies are needed for different situations, based both on your personal proclivities and the specifics of your code. While they might not be appropriate for every situation, test doubles are a very effective tool to have in your testing tool belt. Whether your inclination is to mock out everything in your unit tests using a framework, or to just create your own fake objects as needed, it's worth keeping mock objects in mind as you think about how to test your code.
测试没有高招；不同的情况下使用不同的策略，基于你的个人倾向和代码的具体特性。它们可能不适用所有的情况，测试替身会是你测试工具盒中一个非常有效的工具。不管你是否是使用一个框架在单元测试中模拟出一切，或者只是根据需要创建模拟对象，当你思考如何测试你的代码时，牢记模拟对象是非常值得的。
