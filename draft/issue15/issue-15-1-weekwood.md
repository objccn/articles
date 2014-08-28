Starting your adventure with testing is not an easy task, especially if you don't have someone to help you out. If you've ever tried it, then you probably remember that moment when you thought: "This is it. I am starting testing now. I've heard so much about TDD and how beneficial it is, so I'm starting doing it right now."

开始测试之旅并不是一件轻松的事，特别是在没有人帮助的情况下。如果之前你曾经做过类似的尝试，然后你印象中会有那么一个时刻：“就是它，我等不及要开始测试。我听闻 TDD 是多么有益，所以我现在必须开始使用它。”

Then you sat down in front of your computer. You opened your IDE. You created a new test file for one of your components.

于是你坐在电脑前，打开 IDE, 为你其中一个组件建立了第一个测试文件。

And then void. You might have written a few tests that check some basic functionality, but you felt that something was wrong. You felt there was a question lurking somewhere in your head. A question that needed answering before you could really move forward.

然后它就一片空白，也许你写了一些基本功能的测试，但是你总觉得哪里不对。有个问题始终潜伏在脑海深处。这个问题在真正前行之前必须要回答。

**What should I test?**

**我应该测试些什么**

The answer to that question is not simple. In fact, it is a rather complicated issue. The good news is that you were not the first one to ask. And definitely not the last one. 

要回答这个问题并没有那么简单，实际上。这是一个非常复杂的问题。值得庆幸的是你不是第一个有此疑问的人，也绝对不是最后一个。

But you still wanted to pursue the idea of having tests. So you wrote tests that just called your methods (unit testing right?).

但是你依然希望按照你的想法进行测试。所以你写的测试仅仅调用了你的方法（单元测试对不对？）。

	-(void)testDownloadData;

There is one fundamental issue with tests like this: they don't really tell you what should happen. They don't tell you what is actually being expected. It is not *clear* what the requirements are. 

这些测试有一个根本的问题：它们不会告诉你会发生什么。它们也不会告诉你实际的预期是什么。它不*清楚*需求到底是什么。

Moreover, when one of these tests fails, you have to dive into the code and *understand* why it failed. That requires a lot of additional unnecessary cognitive load. In an ideal world, you shouldn't have to do that in order to know what broke. 

此外，当一个测试失败，你必须深入代码并且*理解*为什么失败。这就需要大量额外不必要的认知负荷。在理想世界里，为了知道什么造成中断，你不应该这样做。

This is where behavior-driven development (BDD) comes it. It aims at solving these exact issues by helping developers determine *what* should be tested. Moreover, it provides a DSL that encourages developers to *clarify* their requirements, and it introduces an ubiquitous language that helps you to easily *understand* what the purpose of a test is. 

这就是行为驱动开发 (BDD)，它旨在解决具体问题，帮助开发人员确定*应该测试什么*。此外，它提供了一个DSL（译者注: Domain-specific language，域特定语言）鼓励开发者*理清*他们的需求，并且它引入了一个通用语言帮助您轻易*理解*测试的目。

## What Should I Test?

## 我应该测试什么？

The answer to this profound question is strikingly simple, however it does require a shift in how you perceive your test suite. As the first word in BDD suggests, you should no longer focus on *tests*, but you should instead focus on *behaviors*. This seemingly meaningless change provides an exact answer to the question: you should test behaviors.

如此深刻的问题的答案却惊人的简单，但是它需要改变你的对测试套件的看法。BDD 的第一个单词就表明了这一点，你不应该关注于*测试*，而是应该关注*行为*。这个看似毫无意义的变化提供了应该测试什么的准确答案：你应该测试行为。

But what is a behavior? Well, to answer this question, we have to get a little bit more technical. 

但是什么是行为？好吧，为了回答这个问题，我们需要得到一点点技术。

Let's consider an object that is a part of an app you wrote. It has an interface that defines its methods and dependencies. These methods, these dependencies, declare *contract* of your object. They define how it should interact with the rest of your application and what capabilities and functionalities it has. They define its *behavior*.

让我们思考你设计的 app 中的一个对象。它有一个接口定义了其方法和依赖关系。这些方法和依赖，声明了你对象的约定。它们定义了如何与你应用的其他部分交互，以及它的功能和性能是什么。它们定义了对象的*行为*。

And that is what you should be aiming at: testing how your object behaves. 

同时这也是你应该针对的地方：测试你对象的行为方式。

## BDD DSL

## BDD DSL

Before we talk about benefits of BDD DSL, let's first go through its basics and see how a simple test suite for class `Car` looks:

在我们讨论 BDD DSL 优势之前，让我们首先通过基本原理来看一个 `Car` 类的简单测试套件：

	SpecBegin(Car)
		describe(@"Car", ^{
		
			__block Car *car;
		
			// Will be run before each enclosed it
			beforeEach(^{
				car = [Car new];
			});
			
			// Will be run after each enclosed it
			afterEach(^{
				car = nil;
			});
		
			// An actual test
			it(@"should be red", ^{
				expect(car.color).to.equal([UIColor redColor]);
			});
			
			describe(@"when it is started", ^{
			
				beforeEach(^{
					[car start];
				});
			
				it(@"should have engine running", ^{
					expect(car.engine.running).to.beTruthy();
				});
			});
			
			describe(@"move to", ^{
				
				context(@"when the engine is running", ^{
				
					beforeEach(^{
						car.engine.running = YES;
						[car moveTo:CGPointMake(42,0)];
					});
					
					it(@"should move to given position", ^{
						expect(car.position).to.equal(CGPointMake(42, 0));
					});
				});
			
				context(@"when the engine is not running", ^{
				
					beforeEach(^{
						car.engine.running = NO;
						[car moveTo:CGPointMake(42,0)];
					});
					
					it(@"should not move to given position", ^{
						expect(car.engine.running).to.beTruthy();
					});
				});
			});
		});
	SpecEnd
	
`SpecBegin` declares a test class named `CarSpec`. `SpecEnd` closes that class declaration. 

`SpecBegin` 声明了一个名为 `CarSpec` 测试类. `SpecEnd` 结束了类声明。

The `describe` block declares a group of examples.

`describe` 块声明了一组实例。

The `context` block behaves similarly to `describe` (syntax sugar).

`context` 块的行为类似于 `describe`  （语法糖）。

`it` is a single example (a single test). 

`it` 是一个单一的例子（单一测试）

`beforeEach` is a block that gets called before every block that is nested on the same level as or below it. 

`beforeEach` 是一个块运行于所有同级块和嵌套块之前。

As you probably noticed, nearly all components defined in this DSL consists of two parts: a string value that defines what is being tested, and a block that either has the test itself or more components. These strings have two very important functions.

可能你已经注意到，几乎在这种 DSL 中定义的所有组件由两部分都组成：一个字符串值定义了什么被测试，以及一个块测试其本身或者多个组件。这些字符串有两个非常重要的功能。

First of all, in `describe` blocks, these strings group behaviors that are tied to a certain part of tested functionality (for instance, moving a car). Since you can specify as many nested blocks as you wish, you can write different specifications based on contexts in which the object or its dependencies are. 

首先，在 `describe` 块内，这些字符串组绑定到测试功能特定的一部分（例如，移动一辆汽车）。因为你可以按意愿尽可能多的指定嵌套块。你可以在对象或者它们的依赖关系中编写基于上下文的不同规范。

That is exactly what happens in the `move to:` `describe` block: we created two `context` blocks to provide different expectations based on different states (engine either running or not) in which `Car` could be. This is an example of how BDD DSL encourages the defining of *clear* requirements of how the given object should behave in the given conditions. 

这就是正在发生在 `move to` 的事情：`describe` 块：我们建立了两个  `context`  块来提供 `Car` 内基于不同状态的不同期望（发动机启动或关闭）。这说明了 BDD DSL 鼓励*理清*对象应该如何在给定的条件下表现需求的例子。

Second of all, these strings are used to create sentences that inform you which test failed. For instance, let's assume that our test for moving with engine not started failed. We would then receive the `Car move to when engine is not running should not move to given position` error message. These sentences really help us with *understanding* what has failed and what was the expected behavior, without actually reading any code, and thus they minimize cognitive load. Moreover, they provide a standard language that is easily understandable by each member of your team, even those who are less technical. 

接下来，这些字符串被用来创建哪些测试失败的句子。例如，让我们假设引擎启动的测试用例失败了。我们将收到 `Car move to when engine is not running should not move to given position` 的错误信息。这些语句对我们理解失败和预期行为提供了非常大的帮助，重点是不需要阅读任何实际代码，因此它们减少了认知负荷。此外，它提供了一个标准语言来帮助你了解你团队的每一个成员，即便他们技术略差。

Remember that you can also write tests with clear requirements and understandable names without BDD-style syntax (XCtest for instance). However, BDD has been built from ground up with these capabilities in mind and it provides syntax and functionality that will make such an approach easier.

记住你可以编写不包含 BDD-style 语法但有着明确需求和易于理解命名的测试（例如 XCtest）。然而，BDD 已经从头建立了这些功能和语法，使得测试更加容易。
	
If you wish to learn more about BDD syntax, you should check out the [Specta guide for writing specs](https://github.com/specta/specta#writing-specs).

如果你希望学更多的 BDD 语法，你应该看看 [Specta guide for writing specs](https://github.com/specta/specta#writing-specs).

### BDD Frameworks

### BDD 框架

As an iOS or Mac developer, you can choose from a variety of BDD frameworks:

对于 iOS 或者 Mac 开发者，你应该从多样的 BDD 框架中选取其一：

* [Specta](https://github.com/specta/specta)
* [Kiwi](https://github.com/kiwi-bdd/Kiwi)
* [Cedar](https://github.com/pivotal/cedar)

When it comes to syntax, all these frameworks are nearly the same. The main difference between them lies in their configurability and bundled components. 

当涉及到语法，所有这些框架几乎是相同的。它们之间的主要区别在于他们的可配置能力和绑定组件。

**Cedar** comes bundled with [matchers](https://github.com/pivotal/cedar/wiki/Writing-specs#matchers) and [doubles](https://github.com/pivotal/cedar/wiki/Writing-specs#doubles). Though it's not exactly true, for the sake of this article, let's consider doubles as mocks (you can learn the difference between mocks and doubles [here](/issue-15/mocking-stubbing.html). 

**Cedar** 捆绑了 [matchers](https://github.com/pivotal/cedar/wiki/Writing-specs#matchers) 和 [doubles](https://github.com/pivotal/cedar/wiki/Writing-specs#doubles)。尽管这不是真的，为了这篇文章。让我们考虑 doubles 作为 mocks (你可以在[这篇文章中] (/issue-15-5) 学习 doubles 和 mocks 的区别)

Apart from these helpers, Cedar has an additional configuration feature: focusing tests. Focusing tests means that Cedar will execute only that test or a test group. Focusing can be achieved by adding an `f` before the `it`, `describe`, or `context` block. 

除了这些 helpers，Ceder 包含了额外的配置功能：集中测试。集中测试的意思是 Ceder 将只执行一个测试或者一组测试。主要可以通过在  `it`，`describe` 或者 `context` 前面添加  `f`，

There's an opposite configuration capability: you can `x`' a test to turn it off. XCTest has similar configuration capabilities, however, they are achieved by operating on schemes (or by manually pressing "Run this test"). Cedar configuration capabilities are simpler and faster to configure.

同样 Ceder 提供了反向配置能力：你可以添加 `x` 到测试中来关闭它。XCTest 有类似的配置能力，然而他们是通过操作 schemes 实现 (或者手动点击 "Run this test")。Cedar 配置能力可以更简单快速去配置。

Cedar uses a bit of hackery when it comes to integration with XCTest, and thus it's prone to breaking, should Apple decide to change some of its internal implementation. However, from a user perspective, Cedar will work just as if it was integrated with XCTest.

Cedar 用了一点黑客技术才能与 XCTest 集成，如果 Apple 决定改变 XCTest 内部实现的话，那么 Cedar 非常容易失灵，然而从用户角度来看， Cedar 工作起来就像集成 XCTest 一样容易。

**Kiwi** also comes bundled with [matchers](https://github.com/kiwi-bdd/Kiwi/wiki/Expectations), as well as [stubs and mocks](https://github.com/kiwi-bdd/Kiwi/wiki/Mocks-and-Stubs). Unlike Cedar, Kiwi is tightly integrated with XCTest, however, it lacks the configuration capabilities available in Cedar. 

**Kiwi** 同样捆绑了 [matchers](https://github.com/kiwi-bdd/Kiwi/wiki/Expectations) 以及  [stubs and mocks](https://github.com/kiwi-bdd/Kiwi/wiki/Mocks-and-Stubs)。与 Cedar 不同的是， Kiwi 紧紧与 XCTest 结合在一起，然而，它缺乏像 Cedar 一样的可配置性功能。

**Specta** offers a different approach when it comes to testing tools, as it lacks any matchers, mocks, or stubs. It is tightly integrated with XCTest and offers configuration capabilities similar to Cedar. 

**Specta** 用另一种途径来达到测试工具的目的，虽然它缺少 matchers，mocks，或者 stubs。它紧密的与 XCTest 结合在一起并且提供了近似 Cedar 的可配置性的能力。

As mentioned before, Cedar, Kiwi, and Specta offer similar syntax. I would not say that there is a framework that is better than all the others; they all have their small pros and cons. Choosing a BDD framework to work with comes down to personal preference. 

正如前面提到过的，Cedar，Kiwi，以及 Specta 提供类似语法，我不能说其中一个框架要比其他所有都好；它们各有利弊。选择 BDD 框架归根结底来自个人偏好。

It is also worth mentioning that there are already two BDD frameworks that are dedicated to Swift:

另外值得一提的是已经有两个 Swift 专用的 BDD 框架。

* [Sleipnir](https://github.com/railsware/Sleipnir)
* [Quick](https://github.com/Quick/Quick)

## Examples

## 举例说明

There's one last thing I'd like to point out before we move to examples. Remember that one of key aspect of writing good behavioral tests is identifying dependencies (you can read more on this subject [here](/issue-15/dependency-injection.html)) and exposing them in your interface. 

还有最后一件事我想在举例前指出。记住，编写好的行为测试代码最重要的方面是识别依赖关系（你可以在[依赖注入](/issue-15-3)中阅读更多相关主题）

Most of your tests will either assert whether a specific interaction happened, or whether a specific value was returned (or passed to another object), based on your tested object state. Extracting dependencies will allow you to easily mock values and states. Moreover, it will greatly simplify asserting whether a specific action happened or a specific value was calculated.

大部分你的测试将断言一个特定交互的发生，或者一个特定值是否返回（或者传递给另一个对象），基于你测试对象的状态。提取依赖允许你轻松 mock 值或者状态。此外，它将大大简化断言一个特定动作的发生或者特定值是否被计算。

Keep in mind that you shouldn't put *all* of your object dependencies and properties in the interface (which, especially when you start testing, is really tempting). This will decrease the readability and clarity of purpose of your object, whereas your interface should clearly state what it was designed for. 

记住，你不应该将对象*所有*的依赖关系和属性暴露在接口之中（特别是当你开始测试的时候，虽然这样很诱人）。这将减少你对象的可读性和清晰的目的性，鉴于你的界面应该清楚的表述设计需求。

#### Message Formatter

#### 消息格式

Let's start with a simple example. We'll build a component that is responsible for formatting a text message for a given event object: 

让我们从一个简单的例子开始。我们将构建一个组件,负责对给定事件对象格式化文本消息:

	@interface EventDescriptionFormatter : NSObject
	@property(nonatomic, strong) NSDateFormatter *dateFormatter;
	
	- (NSString *)eventDescriptionFromEvent:(id <Event>)event;
	
	@end

This is how our interface looks. The event protocol defines three basic properties of an event:

这就是我们接口的样子。这个事件协议定义了一个事件的三个基本属性：

	@protocol Event <NSObject>
	
	@property(nonatomic, readonly) NSString *name;
	
	@property(nonatomic, readonly) NSDate *startDate;
	@property(nonatomic, readonly) NSDate *endDate;
	
	@end

Our goal is to test whether `EventDescriptionFormatter` returns a formatted description that looks like `My Event starts at Aug 21, 2014, 12:00 AM and ends at Aug 21, 2014, 1:00 AM.`. 

我们的目标是测试 `EventDescriptionFormatter` 是否返回像 `My Event starts at Aug 21, 2014, 12:00 AM and ends at Aug 21, 2014, 1:00 AM.` 一样格式化后的描述。

Please note that this (and all other examples in this article) use mocking frameworks. If you've never used a mocking framework before, you should consult [this article](/issue-15/mocking-stubbing.html).

请注意，这里（或者本文中其他例子）采用了 mocking 框架。如果你之前没有用过 mocking 框架，你应该向[置换测试: Mock, Stub 和其他](/issue-15-5)这篇文章请教。

We'll start by mocking our only dependency in the component, which is the date formatter. We'll use the created mock to return fixture strings for the start and end dates. Then we'll check whether the string returned from the event formatter is constructed using the values that we have just mocked: 

我们将先 mocking 我们组件内时间格式化的这个唯一依赖，我们将用创建的 mock 来返回开始和结束日期的固定字符串。然后我们检查从事件格式化程序构造返回的字符串是否和我们先前 mocked 有一样的值。

    __block id mockDateFormatter;
    __block NSString *eventDescription;
    __block id mockEvent;

    beforeEach(^{
    	// Prepare mock date formatter //  准备 mock date formatter
        mockDateFormatter = mock([NSDateFormatter class]);
        descriptionFormatter.dateFormatter = mockDateFormatter;

        NSDate *startDate = [NSDate mt_dateFromYear:2014 month:8 day:21];
        NSDate *endDate = [startDate mt_dateHoursAfter:1];

	    // Pepare mock event // 准备 mock 事件
        mockEvent = mockProtocol(@protocol(Event));
        [given([mockEvent name]) willReturn:@"Fixture Name"];
        [given([mockEvent startDate]) willReturn:startDate];
        [given([mockEvent endDate]) willReturn:endDate];

        [given([mockDateFormatter stringFromDate:startDate]) willReturn:@"Fixture String 1"];
        [given([mockDateFormatter stringFromDate:endDate]) willReturn:@"Fixture String 2"];

        eventDescription = [descriptionFormatter eventDescriptionFromEvent:mockEvent];
    });

    it(@"should return formatted description", ^{
        expect(eventDescription).to.equal(@"Fixture Name starts at Fixture String 1 and ends at Fixture String 2.");
    });
        
Note that we have only tested whether our `EventDescriptionFormatter` uses its `NSDateFormatter` for formatting the dates. We haven't actually tested the format style. Thus, to have a fully tested component, we need to add two more tests that check format style:

注意我们在这里仅仅测试  `EventDescriptionFormatter` 是否用 `NSDateFormatter` 来格式化时间，我们并没有实际测试格式化的风格。因此，要严格测试组件，我们需要增加额外两个测试来检查格式化风格：

    it(@"should have appropriate date style on date formatter", ^{
        expect(descriptionFormatter.dateFormatter.dateStyle).to.equal(NSDateFormatterMediumStyle);
    });

    it(@"should have appropriate time style on date formatter", ^{
        expect(descriptionFormatter.dateFormatter.timeStyle).to.equal(NSDateFormatterMediumStyle);
    });
    
Even though we have a fully tested component, we wrote quite a few tests. And this is a really small component, isn't it? Let's try approaching this issue from a slightly different angle.

即使我们拥有了严格的测试组件，我们写了一些测试，不是吗？让我们从一个稍微不同的角度来尝试解决这个问题。

The example above doesn't exactly test *behavior* of `EventDescriptionFormatter`. It mostly tests its internal implementation by mocking the `NSDateFormatter`. In fact, we don't actually care whether there's a date formatter underneath at all. From an interface perspective, we could've been formatting the date manually by using date components. All we care about at this point is whether we got our string right. And that is the behavior that we want to test.

上面这个例子并没有确切测试 `EventDescriptionFormatter` 的*行为*。它主要通过 mocking `NSDateFormatter` 来测试其内部实现。我们实际上并不关心是否下面有日期格式化程序。从一个接口角度来看，我们可以一直使用日期组件手动格式化日期。此时，我们关心的重点是我们否正确获取字符串。这个行为是我们需要测试的。

We can easily achieve this by not mocking the `NSDateFormatter`. As said before, we don't even care whether its there, so let's actually remove it from the interface: 

我们可以通过不 mocking `NSDateFormatter` 来轻松实现这个功能。就像之前说的，我们不需要关系是否存在，让我们从接口中去掉它。

	@interface EventDescriptionFormatter : NSObject
	
	- (NSString *)eventDescriptionFromEvent:(id <Event>)event;
	
	@end
	
The next step is, of course, refactoring our tests. Now that we no longer need to know the internals of the event formatter, we can focus on the actual behavior:

下一步当然是重构我们的测试。现在我们不再需要知道事件内部的 formatter，我们只需要专注于实际的行为：

    describe(@"event description from event", ^{

       __block NSString *eventDescription;
       __block id mockEvent;

       beforeEach(^{
           NSDate *startDate = [NSDate mt_dateFromYear:2014 month:8 day:21];
           NSDate *endDate = [startDate mt_dateHoursAfter:1];

           mockEvent = mockProtocol(@protocol(Event));
           [given([mockEvent name]) willReturn:@"Fixture Name"];
           [given([mockEvent startDate]) willReturn:startDate];
           [given([mockEvent endDate]) willReturn:endDate];

           eventDescription = [descriptionFormatter eventDescriptionFromEvent:mockEvent];
       });

       it(@"should return formatted description", ^{
           expect(eventDescription).to.equal(@"Fixture Name starts at Aug 21, 2014, 12:00 AM and ends at Aug 21, 2014, 1:00 AM.");
       });
   });

Note how simple our test has become. We only have a minimalistic setup block where we prepare a data model and call a tested method. By focusing more on the result of behavior, rather than the way it actually works, we have simplified our test suite while still retaining functional test coverage of our object. This is exactly what BDD is about—trying to think about results of behaviors, and not the actual implementation.

注意我们测试变的多么简单。我们仅仅有一个简约的设置块来准备数据模型和调用测试方法。更多的专注于行为测试的结果，而不是它实际工作方式，我们简化测试套件，同时仍然保留对我们对象功能的覆盖。这正是 BDD 想尝试思考行为的结果，而不是实际实现。

#### Data Downloader

#### 数据下载

In this example, we will build a simple data downloader. We will specifically focus on one single behavior of our data downloader: making a request and canceling the download. Let's start with defining our interface:

在这个例子中，我们建立一个简单的数据下载器。我们特别专注在我们数据下载这个单一行为：发出请求和取消下载。

	@interface CalendarDataDownloader : NSObject
	
	@property(nonatomic, weak) id <CalendarDataDownloaderDelegate> delegate;
	
	@property(nonatomic, readonly) NetworkLayer *networkLayer;
	
	- (instancetype)initWithNetworkLayer:(NetworkLayer *)networkLayer;
	
	- (void)updateCalendarData;
	
	- (void)cancel;
	
	@end
	
And of course, the interface for our network layer: 

当然，下面是我们的网络层接口

	@interface NetworkLayer : NSObject
	
	// Returns an identifier that can be used for canceling a request. // 传入标识符来取消请求
	- (id)makeRequest:(id <NetworkRequest>)request completion:(void (^)(id <NetworkRequest>, id, NSError *))completion;
	
	- (void)cancelRequestWithIdentifier:(id)identifier;
	
	@end

We will first check whether the actual download took place. The mock network layer has been created and injected in a `describe` block above: 

首先我们检查是否实际下载。mock 网络层在 `describe` 之前创建并注入。

    describe(@"update calendar data", ^{
        beforeEach(^{
            [calendarDataDownloader updateCalendarData];
        });

        it(@"should make a download data request", ^{
            [verify(mockNetworkLayer) makeRequest:instanceOf([CalendarDataRequest class]) completion:anything()];
        });
    });
    
This part was pretty simple. The next step is to check whether that request was canceled when we called the cancel method. We need to make sure we don't call the cancel method with no identifier. Specifications for such behavior can look like this:

这部分相当简单，下一步是检查在我们调用取消方法之后请求是否被取消。我们需要确定在没有标识符的前提下不调用取消方法。规范后这种行为看起来像这样：

    describe(@"cancel ", ^{
        context(@"when there's an identifier", ^{
            beforeEach(^{
                calendarDataDownloader.identifier = @"Fixture Identifier";
                [calendarDataDownloader cancel];
            });

            it(@"should tell the network layer to cancel request", ^{
                [verify(mockNetworkLayer) cancelRequestWithIdentifier:@"Fixture Identifier"];
            });

            it(@"should remove the identifier", ^{
                expect(calendarDataDownloader.identifier).to.beNil();
            });
        });

        context(@"when there's no identifier", ^{
            beforeEach(^{
                calendarDataDownloader.identifier = nil;
                [calendarDataDownloader cancel];
            });

            it(@"should not ask the network layer to cancel request", ^{
                [verifyCount(mockNetworkLayer, never()) cancelRequestWithIdentifier:anything()];
            });
        });
    });
    
The request identifier is a private property of `CalendarDataDownloader`, so we will need to expose it in our tests:

请求标识符是 `CalendarDataDownloader` 其中一个私有属性，所以我们需要使得它暴露在我们的测试中：

	@interface CalendarDataDownloader (Specs)
	@property(nonatomic, strong) id identifier;
	@end
	
You can probably gauge that there's something wrong with these tests. Even though they are valid and they check for specific behavior, they expose the internal workings of our `CalendarDataDownloader`. There's no need for our tests to have knowledge of how the `CalendarDataDownloader` holds its request identifier. Let's see how we can write our tests without exposing internal implementation:

你大概可以衡量这些测试中有一些错误。尽管对于检查特定行为这样是有效的，它们暴露了 `CalendarDataDownloader` 内部的工作。这里不需要测试 `CalendarDataDownloader`  如何持有它的请求标识符。让我们看看我们如何在不暴露我们内部实现的情况下描述我们的测试：


    describe(@"update calendar data", ^{
        beforeEach(^{
            [given([mockNetworkLayer makeRequest:instanceOf([CalendarDataRequest class])
                                      completion:anything()]) willReturn:@"Fixture Identifier"];
            [calendarDataDownloader updateCalendarData];
        });

        it(@"should make a download data request", ^{
            [verify(mockNetworkLayer) makeRequest:instanceOf([CalendarDataRequest class]) completion:anything()];
        });

        describe(@"canceling request", ^{
            beforeEach(^{
                [calendarDataDownloader cancel];
            });

            it(@"should tell the network layer to cancel previous request", ^{
                [verify(mockNetworkLayer) cancelRequestWithIdentifier:@"Fixture Identifier"];
            });

            describe(@"canceling it again", ^{
                beforeEach(^{
                    [calendarDataDownloader cancel];
                });

                it(@"should tell the network layer to cancel previous request", ^{
                    [verify(mockNetworkLayer) cancelRequestWithIdentifier:@"Fixture Identifier"];
                });
            });
        });
    });
    
We started by stubbing the `makeRequest:completion:` method. We returned a fixture identifier. In the same `describe` block, we defined a cancel `describe` block, which calls the `cancel` method on our `CalendarDataDownloader` object. We then check whether out the fixture string was passed to our mocked network layer `cancelRequestWithIdentifier:` method. 

我们通过 stubbing `makeRequest:completion:` 方法开始。我们返回一个固定的标识符。在相同的 `describe` 块内，我们定义了取消请求的 `describe` 块，用以在`CalendarDataDownloader` 类中调用 `cancel` 方法。接着我们检查我们的固定字符串是否传入到我们 mocked 的网络层中的 `cancelRequestWithIdentifier:` 方法。

Note that at this point we don't actually need a test that checks whether the network request was made—we would not get an identifier and the `cancelRequestWithIdentifier:` would never be called. However, we retained that test to make sure we know what happened should that functionality break.

请注意，在这一点上我们没有实际测试网络请求是否被执行 - 我们不会得到一个标识符并且 `cancelRequestWithIdentifier:`  永远不会被调用。然而，我们保留测试来确保我们知道功能什么时候被中断。

We've managed to test the exact same behavior without exposing the internal implementation of `CalendarDataDownloader`. Moreover, we've done so with only three tests instead of four. And we've leveraged BDD DSL nesting capabilities to chain simulation of behaviors—we first simulated the download, and then, in the same `describe` block, we simulated the canceling of a request. 

我们已经设法测试了与暴露 `CalendarDataDownloader` 内部实现相同的行为。此外，我们用三个测试代替了之前四个。我们利用 BDD DSL 嵌套能力来束缚模拟的多重行为 - 我们首先模拟下载，接着，在相同的 `describe` 块内，我们模拟取消请求。

### Testing View Controllers

### 测试视图控制器

It seems that the most common attitude to testing view controllers among iOS developers is that people don't see value in it—which I find odd, as controllers often represent the core aspect of an application. They are the place where all components are glued together. They are the place that connects the user interface with the application logic and model. As a result, damage caused by an involuntary change can be substantial. 

在 iOS 开发者中对于测试视图控制器的最常见的态度是看不到价值所在。这让我觉得奇怪，控制器经常代表应用程序的核心。他们帮助所有组件粘合在一起。它们建立了用户界面和应用逻辑和模型之间的联系。因此，不经意的变化可能造成巨大的破坏。

This is why I strongly believe that view controllers should be tested as well. However, testing view controllers is not an easy task. The following upload photo and sign-in view controller examples should help with understanding how BDD can be leveraged to simplify building view controllers test suites.

这就是为什么我坚信测试视图控制器也必须被测试。然而，测试视图控制器并不是一个简单的工作。接下来的上传图片和登录视图控制器例子会帮助理解，如何利用 BDD 简化构建视图控制器测试套件。

#### Upload Photo View Controller

#### 上传图片视图控制器

In this example, we will build a simple photo uploader view controller with a send button as `rightBarButtonItem`. After the button is pressed, the view controller will inform its photo uploader component that a photo should be uploaded.

在这个例子中，我们需要建立一个简单的上传图片控制器包含一个 `rightBarButtonItem` 按钮。在按钮点击后，视图控制器将通知上传图片组件，应该上传图片。

Simple, right? Let's start with the interface of `PhotoUploaderViewController`:

是不是很简单？让我们从 `PhotoUploaderViewController` 接口开始：

	@interface PhotoUploadViewController : UIViewController
	@property(nonatomic, readonly) PhotoUploader *photoUploader;
	
	- (instancetype)initWithPhotoUploader:(PhotoUploader *)photoUploader;
	
	@end
	
There's not much happening here, as we're only defining an external dependency on `PhotoUploader`. Our implementation is also pretty simple. For the sake of simplicity, we won't actually grab a photo from anywhere; we'll just create an empty `UIImage`: 

在这里我们除了在 `PhotoUploader` 中定义一个额外的依赖外并没有做其他事情。我们的实现也同样非常简单。为了简单起见，我们并不会实际选取照片；我们只是建立一个空的  `UIImage`: 


	@implementation PhotoUploadViewController
	
	- (instancetype)initWithPhotoUploader:(PhotoUploader *)photoUploader {
	    self = [super init];
	    if (self) {
	        _photoUploader = photoUploader;
	
	        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Upload", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(didTapUploadButton:)];
	    }
	
	    return self;
	}
	
	#pragma mark -
	
	- (void)didTapUploadButton:(UIBarButtonItem *)uploadButton {
	    void (^completion)(NSError *) = ^(NSError* error){};
	    [self.photoUploader uploadPhoto:[UIImage new] completion:completion];
	}
	
	@end

Let's see how we could test this component. First of all, we'll need to check whether our bar button item is properly set up by asserting that the title, target, and action have been properly initialized: 

让我们看下如何测试这个组件，首先，需要断言我们这个 bar 按钮是否初始化了 title，target 和 action 属性：

    describe(@"right bar button item", ^{

        __block UIBarButtonItem *barButtonItem;

        beforeEach(^{
            barButtonItem = [[photoUploadViewController navigationItem] rightBarButtonItem];
        });

        it(@"should have a title", ^{
            expect(barButtonItem.title).to.equal(@"Upload");
        });

        it(@"should have a target", ^{
            expect(barButtonItem.target).to.equal(photoUploadViewController);
        });

        it(@"should have an action", ^{
            expect(barButtonItem.action).to.equal(@selector(didTapUploadButton:));
        });
    });
    
But this is only half of what actually needs to be tested: we are now sure that the appropriate method will be called when the button is pressed, but we're not sure whether the appropriate action will be taken (in fact, we don't even know whether that method actually exists). So let's test that as well:

但是我们仅仅完成了测试功能的一半：我们现在需要确保当按钮按下的时候适当的方法被执行，但是我们无法确定适当的动作被执行（我们实际上也不知道这个方法有没有被创建）。接下来让我们开始测试：

    describe(@"tapping right bar button item", ^{
        beforeEach(^{
            [photoUploadViewController didTapUploadButton:nil];
        });

        it(@"should tell the mock photo uploader to upload the photo", ^{
            [verify(mockPhotoUploader) uploadPhoto:instanceOf([UIImage class])
                                        completion:anything()];
        });
    });

Unfortunately for us, the `didTapUploadButton:` is not visible in the interface. We can work around this issue by defining a category visible in our tests that exposes this method:

不幸的是，`didTapUploadButton:` 对于接口不可见，我们在测试中通过定义一个可见类别暴露方法来解决问题。

	@interface PhotoUploadViewController (Specs)
	- (void)didTapUploadButton:(UIBarButtonItem *)uploadButton;
	@end
	
At this point, we can say that `PhotoUploadViewController` is fully tested. 

这个时候，我们可以说 `PhotoUploadViewController` 被严格测试。

But what is wrong with the example above? The problem is that we are testing the internal implementation of `PhotoUploadViewController`. We shouldn't actually *care* what the target/action values on the bar button item are. We should only care about what happens when it is pressed. Everything else is an implementation detail.

但是以上例子有什么问题？问题是我们测试了 `PhotoUploadViewController` 内部实现。我们不应该实际*关心*按钮上 target/action 的值，我们应该专注于它被点击过。其他都是实现细节。

Let's go back to our `PhotoUploadViewController` and see how we could rewrite our tests to make sure we're testing our interface, and not implementation.

让我们回头看看 `PhotoUploadViewController` 如何重写测试确保我们只测试我们的界面，而不是实现。

First of all, we don't need to know that the `didTapUploadButton:` method exists at all. It is just an implementation detail. We care only for the behavior: when the user taps the upload button, the `UploadManager` should receive an `uploadPhoto:` message. This is great, as it means we don't really need our `Specs` category on `PhotoUploadViewController`. 

首先，我们不需要知道 `didTapUploadButton:` 方法存在与否。它只是实现细节。我们应该只关心行为：当用户点击上传按钮，`UploadManager` 应该收到一个 `uploadPhoto:` 消息。了不起，我们不再需要在 `PhotoUploadViewController` 中添加 `Specs` 类别
 
Second of all, we don't need to know what target/action is defined on our `rightBarButtonItem`. Our *only* concern is what happens when it is tapped. Let's simulate that action in tests. We can use a helper category on `UIBarButtonItem` to do this:

接下来，我们不需要知道 `rightBarButtonItem` 中的 target/action 的定义。我们仅需要关注当点击的时候发生了什么。让我们在测试中模拟这个动作，我们可以为 `UIBarButtonItem` 创建一个 helper 类别来完成这件事情：

	@interface UIBarButtonItem (Specs)
	
	- (void)specsSimulateTap;
	
	@end
	
Its implementation is pretty simple, as we're performing `action` on the `target` of the `UIBarButtonItem`:

这个实现相当简单，当我们在 `UIBarButtonItem` 的 `target` 中执行 `action`：

	@implementation UIBarButtonItem (Specs)
	
	- (void)specsSimulateTap {
	    [self.target performSelector:self.action withObject:self];
	}
	
	@end

Now that we have a helper method that simulates a tap, we can simplify our tests to one top-level `describe` block:

现在我们已经创建了 helper 方法模拟点击，我们可以在最上级的 `describe` 块中简化测试：

    describe(@"right bar button item", ^{

        __block UIBarButtonItem *barButtonItem;

        beforeEach(^{
            barButtonItem = [[photoUploadViewController navigationItem] rightBarButtonItem];
        });

        it(@"should have a title", ^{
            expect(barButtonItem.title).to.equal(@"Upload");
        });

        describe(@"when it is tapped", ^{
            beforeEach(^{
                [barButtonItem specsSimulateTap];
            });

            it(@"should tell the mock photo uploader to upload the photo", ^{
                [verify(mockPhotoUploader) uploadPhoto:instanceOf([UIImage class])
                                            completion:anything()];
            });
        });
    });

Note that we have managed to remove two tests and we still have a fully tested component. Moreover, our test suite is less prone to breaking, as we no longer rely on the existence of `didTapUploadButton:` method. Last but not least, we have focused more on the behavioral aspect of our controller, rather than its internal implementation.

值得注意的是我们设法消除了两个测试后我们仍然拥有一个严格测试的组件。此外，我们的测试套件不易被打破，我们不再依赖于 `didTapUploadButton:` 方法。最后同样重要的，我们更关注我们控制器行为，而不是它的内部实现。

#### Sign In View Controller

### 登录视图控制器

In this example, we will build a simple app that requires users to enter their username and password in order to sign in to an abstract service.  

在这个例子中，我们将构建一个简单的应用程序,要求用户输入用户名和密码以登录到一个抽象的服务。

We will start out by building a `SignInViewController` with two text fields and a sign-in button. We want to keep our controller as small as possible, so we will abstract a class responsible for signing in to a separate component called `SignInManager`. 

我们将通过构建一个 `SignInViewController` 包含两个文本框以及一个登录按钮。应该确保我们的控制器尽可能的轻量级，所以我们将抽象一个类负责登录到称为  `SignInManager` 的单独的组件中。
	
Our requirements are as follows: when the user presses our sign-in button, and when the username and password are present, our view controller will tell its sign-in manager to perform the sign in with the password and username. If there is no username or password (or both are gone), the app will show an error label above text fields. 

我们的需求如下：当用户点击登录按钮，并且用户名和密码已经填写，我们的视图控制器将告诉 `SignInManager` 利用用户名和密码来执行登录。如果没有填写用户名和密码（或者它们都消失了），app 将在文本框上显示一个错误信息。

The first thing that we will want to test is the view part:

首先我们需要测试的视图部分是：

	@interface SignInViewController : UIViewController
	
	@property(nonatomic, readwrite) IBOutlet UIButton *signInButton;
	
	@property(nonatomic, readwrite) IBOutlet UITextField *usernameTextField;
	@property(nonatomic, readwrite) IBOutlet UITextField *passwordTextField;
	
	@property(nonatomic, readwrite) IBOutlet UILabel *fillInBothFieldsLabel;
	
	@property(nonatomic, readonly) SignInManager *signInManager;
	
	- (instancetype)initWithSignInManager:(SignInManager *)signInManager;
	
	- (IBAction)didTapSignInButton:(UIButton *)signInButton;
	
	@end
	
First, we will check some basic information about our text fields:

首先，我们会检查一些基本的文本字段

        beforeEach(^{
            // Force view load from xib
            [signInViewController view];
        });

        it(@"should have a placeholder on user name text field", ^{
            expect(signInViewController.usernameTextField.placeholder).to.equal(@"Username");
        });

        it(@"should have a placeholder on user name text field", ^{
             expect(signInViewController.passwordTextField.placeholder).to.equal(@"Password");
        });
        
Next, we will check whether the sign-in button is correctly configured and has it actions wired:

接着，我们需要检查登录按钮是否正确配置而且 action 已经连接：

        describe(@"sign in button", ^{

            __block UIButton *button;

            beforeEach(^{
                button = signInViewController.signInButton;
            });

            it(@"should have a title", ^{
                expect(button.currentTitle).to.equal(@"Sign In");
            });

            it(@"should have sign in view controller as only target", ^{
                expect(button.allTargets).to.equal([NSSet setWithObject:signInViewController]);
            });

            it(@"should have the sign in action as action for login view controller target", ^{
                NSString *selectorString = NSStringFromSelector(@selector(didTapSignInButton:));
                expect([button actionsForTarget:signInViewController forControlEvent:UIControlEventTouchUpInside]).to.equal(@[selectorString]);
            });
        });
        
And last, but not least, we will check how our controller behaves when the button is tapped:

最后同样重要的是，我们检查当按钮被按下时候的控制器的行为：

	describe(@"tapping the logging button", ^{
         context(@"when login and password are present", ^{

             beforeEach(^{
                 signInViewController.usernameTextField.text = @"Fixture Username";
                 signInViewController.passwordTextField.text = @"Fixture Password";

                 // Make sure state is different than the one expected //确保状态与预期不同
                 signInViewController.fillInBothFieldsLabel.alpha = 1.0f;

                 [signInViewController didTapSignInButton:nil];
             });

             it(@"should tell the sign in manager to sign in with given username and password", ^{
                 [verify(mockSignInManager) signInWithUsername:@"Fixture Username" password:@"Fixture Password"];
             });
         });

         context(@"when login or password are not present", ^{
             beforeEach(^{
                 signInViewController.usernameTextField.text = @"Fixture Username";
                 signInViewController.passwordTextField.text = nil;

                 [signInViewController didTapSignInButton:nil];
             });

             it(@"should tell the sign in manager to sign in with given username and password", ^{
                 [verifyCount(mockSignInManager, never()) signInWithUsername:anything() password:anything()];
             });
         });

         context(@"when neither login or password are present", ^{
             beforeEach(^{
                 signInViewController.usernameTextField.text = nil;
                 signInViewController.passwordTextField.text = nil;

                 [signInViewController didTapSignInButton:nil];
             });

             it(@"should tell the sign in manager to sign in with given username and password", ^{
                 [verifyCount(mockSignInManager, never()) signInWithUsername:anything() password:anything()];
             });
         });
     });

The code presented in the example above has quite a few issues. First of all, we've exposed a lot of internal implementation of `SignInViewController`, including buttons, text fields, and methods. The truth is that we didn't really need to do all of this. 

例子中提到的代码有相当多的问题。首先我们暴露了过多 `SignInViewController` 内部实现，包括按钮，文本框以及方法。事实是，我们并不真正需要所有这一切。

Let's see how we can refactor these tests to make sure we are not touching internal implementation. We will start by removing the need to actually know what target and method are hooked to the sign-in button:

让我们看看如何重构这些测试来确保没有触碰到内部实现。我们将通过删除登录按钮的 target 和 method 的钩子来开始:

	@interface UIButton (Specs)
	
	- (void)specsSimulateTap;
	
	@end
	
	@implementation UIButton (Specs)
	
	- (void)specsSimulateTap {
	    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
	}
	
	@end

Now we can just call this method on our button and assert whether the sign-in manager received the appropriate message. But we can still improve how this test is written. 

现在我们已经调用了这个按钮的方法和断言 `SignInManager` 是否收到相应的消息。但是我们已然可以改善这个测试的写法。

Let's assume that we do not want to know who has the sign-in button. Perhaps it is a direct subview of the view controller's view. Or perhaps we encapsulated it within a separate view that has its own delegate. We shouldn't actually care where it is; we should only care whether it is somewhere within our view controller's view and what happens when it is tapped. We can use a helper method to grab the sign-in button, no matter where it is:

让我们假设我们不想知道谁拥有这个登录按钮，也许这是一个视图控制器视图的子视图。或者我们封装在单独的视图包含自己的代理。我们实际上不应该关系它在哪；我们应该只关心它在我们视图控制器视图的某个地方并且当我们点击时候发生什么。我们可以用 helper 方法来抓取登录按钮，不用关心它在哪：

	@interface UIView (Specs)
	
	- (UIButton *)specsFindButtonWithTitle:(NSString *)title;
	
	@end
	
Our method will traverse subviews of the view and return the first button that has a title that matches the title argument. We can write similar methods for text fields or labels:

我们的方法将遍历视图中的所有子视图并返回第一个和我们 title 参数匹配的按钮，我们可以写类似的方法用于文本字段或标签:

	@interface UIView (Specs)
	
	- (UITextField *)specsFindTextFieldWithPlaceholder:(NSString *)placeholder;
	- (UILabel *)specsFindLabelWithText:(NSString *)text;
	
	@end
	
Let's see how our tests look now:

让我们看看现在测试的样子：


	describe(@"view", ^{

        __block UIView *view;
        
        beforeEach(^{
            view = [signInViewController view];
        });

        describe(@"login button", ^{

            __block UITextField *usernameTextField;
            __block UITextField *passwordTextField;
            __block UIButton *signInButton;

            beforeEach(^{
                signInButton = [view specsFindButtonWithTitle:@"Sign In"];
                usernameTextField = [view specsFindTextFieldWithPlaceholder:@"Username"];
                passwordTextField = [view specsFindTextFieldWithPlaceholder:@"Password"];
            });

            context(@"when login and password are present", ^{
                beforeEach(^{
                    usernameTextField.text = @"Fixture Username";
                    passwordTextField.text = @"Fixture Password";

                    [signInButton specsSimulateTap];
                });

                it(@"should tell the sign in manager to sign in with given username and password", ^{
                    [verify(mockSignInManager) signInWithUsername:@"Fixture Username" password:@"Fixture Password"];
                });
            });

            context(@"when login or password are not present", ^{
                beforeEach(^{
                    usernameTextField.text = @"Fixture Username";
                    passwordTextField.text = nil;

                    [signInButton specsSimulateTap];
                });

                it(@"should tell the sign in manager to sign in with given username and password", ^{
                    [verifyCount(mockSignInManager, never()) signInWithUsername:anything() password:anything()];
                });
            });

            context(@"when neither login or password are present", ^{
                beforeEach(^{
                    usernameTextField.text = nil;
                    passwordTextField.text = nil;

                    [signInButton specsSimulateTap];
                });

                it(@"should tell the sign in manager to sign in with given username and password", ^{
                    [verifyCount(mockSignInManager, never()) signInWithUsername:anything() password:anything()];
                });
            });
        });
    });
    
Looks much simpler, doesn't it? Note that by looking for a button with 'Sign In' as the title, we also tested whether such a button exists at all. Moreover, by simulating a tap, we tested whether the action is correctly hooked up. And in the end, by asserting that our `SignInManager` should be called, we tested whether or not that part is correctly implemented—all of this using three simple tests.

看起来是不是更简单？注意它通过 title 来寻找按钮，我们同样也要测试这个按钮是否被创建。此外，模拟一个点击请求，我们测试动作是否被正确连接。最后，断言 `SignInManager` 被调用与否，我们测试这部分有没有正确被实施要通过以上三个测试来实现。

What is also great is that we no longer need to expose any of those properties. As a matter of fact, our interface could be as simple as this:

非常棒的是我们不再需要暴露任何内部属性。事实上,我们的接口可能非常简单,比如:

	@interface SignInViewController : UIViewController
	
	@property(nonatomic, readonly) SignInManager *signInManager;
	
	- (instancetype)initWithSignInManager:(SignInManager *)signInManager;
	
	@end
	
What is also great about these tests is that we have leveraged the capabilities of BDD DSL. Note how we used `context` blocks to define different requirements for how `SignInViewController` should behave based on its text fields state. This is a great example of how you can use BDD to make your tests simpler and more readable while retaining their functionality.

另外极好的是这些测试我们利用了 BDD DSL 的功能。注意我们使用 `context` 块为 `SignInViewController` 根据不同的需求行为来定义其文本字段状态。

## Conclusion

## 结论

Behavior-driven development is not as hard as it might initially look. All you need to do is change your mindset a bit—think more of how an object should behave (and how its interface should look) and less of how it should be implemented. By doing so, you will end up with a more robust codebase, along with a great test suite. Moreover, your tests will become less prone to breaking during refactors, and they will focus on testing the contract of your object rather than its internal implementation.

行为驱动开发看起来并不像最初那么困难。所有你需要的只是改变你的思维方式 - 更多思考一个对象的表现（它的接口应该如何）并且减少对实现的关注。通过这样做，你将拥有更健壮的代码。以及同样杰出的测试套件。此外，你的测试在生产代码修改时失效的可能性降低，它们将专注于测试对象的行为而不是内部实现。

And with the great tools provided by the iOS community, you should be able to start BDDing your apps in no time. Now that you know *what* to test, there's really no excuse, is there?

并且 iOS 社区提供了如此杰出的工具，你应该立即开始对你 app 的行为驱动开发。同时你知道了应该测试什么，没有任何借口不这样做，不是吗？

### Links

### 连接

If you're interested in the roots of BDD and how it came to be, you should definitely read [this article](http://dannorth.net/introducing-bdd/).
For those of you who understand TDD, but don't exactly know how this differs from TDD, I recommend [this article](http://blog.mattwynne.net/2012/11/20/tdd-vs-bdd/).
Last but not least, you can find an example project with the tests presented above [here](https://github.com/objcio/issue-15-bdd).

如果你对 BDD 的起源很感兴趣，如何产生的，你绝对应该读一下[这篇文章](http://dannorth.net/introducing-bdd/)。
对于那些了解 TDD 的用户，但是不完全知道其中的不同的用户，我建议[这篇文章](http://blog.mattwynne.net/2012/11/20/tdd-vs-bdd/)。
最后最重要的，你可以从[这里](https://github.com/objcio/issue-15-bdd)找到本文出现的测试例子。  

