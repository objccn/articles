开始测试之旅并不是一件轻松的事，特别是在没有人帮助的情况下。如果之前你曾经做过类似的尝试，然后你印象中会有那么一个时刻：“就是它，我等不及要开始测试。我听闻 TDD 是多么有益，所以我现在必须开始使用它。”

于是你坐在电脑前，打开 IDE, 为你其中一个组件建立了第一个测试文件。

然后它就一片空白，也许你写了一些基本功能的测试，但是你总觉得哪里不对。有个问题始终潜伏在脑海深处。这个问题在真正前行之前必须要回答。

我**应该测试些什么**

要回答这个问题并没有那么简单，实际上。这是一个非常复杂的问题。值得庆幸的是你不是第一个有此疑问的人，也绝对不是最后一个。

但是你依然希望按照你的想法进行测试。所以你写的测试仅仅调用了你的方法 (单元测试对不对？)。

	-(void)testDownloadData;

像这样的测试有一个根本的问题：它们不会告诉你应该发生什么。它们也不会告诉你实际的预期是什么。它不**清楚**需求到底是什么。

此外，当一个测试失败，你必须深入代码并且**理解**为什么失败。这就需要大量额外不必要的认知负荷。在理想世界里，你不应该需要仅仅为了弄明白哪里出错了这种事情而花费如此大量的时间和精力。

这就是为什么会有行为驱动开发 (BDD)，它旨在解决具体问题，帮助开发人员确定**应该测试些什么**。此外，它提供了一个 DSL（译者注: Domain-specific language，域特定语言）鼓励开发者弄**清楚**他们的需求，并且它引入了一个通用语言帮助你轻易**理解**测试的目的。

## 我应该测试什么？

如此深刻的问题的答案却惊人的简单，但是它需要改变你的对测试套件的看法。BDD 的第一个单词就表明了这一点，你不应该关注于**测试**，而是应该关注**行为**。这个看似毫无意义的变化提供了应该测试什么的准确答案：你应该测试行为。

但是什么是行为？好吧，为了回答这个问题，我们需要更技术一点。

让我们思考你设计的 app 中的一个对象。它有一个接口定义了其方法和依赖关系。这些方法和依赖，声明了你对象的约定。它们定义了如何与你应用的其他部分交互，以及它的功能是什么。它们定义了对象的**行为**。

同时这也应该是你的目标：测试你对象的行为方式。

## BDD DSL

在我们讨论 BDD DSL 优势之前，让我们首先过一遍它的基本原理，并看一个 `Car` 类的简单测试套件应该怎么写：

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

`SpecBegin` 声明了一个名为 `CarSpec` 测试类. `SpecEnd` 结束了类声明。

`describe` 块声明了一组实例。

`context` 块的行为类似于 `describe` (语法糖)。

`it` 是一个单一的例子 (单一测试)。

`beforeEach` 是一个运行于所有同级块和嵌套块之前的块。

可能你已经注意到，几乎在这种 DSL 中定义的所有组件由两部分都组成：一个字符串值定义了什么被测试，以及一个包含了测试其本身或者更多组件的块。这些字符串有两个非常重要的功能。

首先，在 `describe` 块内，这些字符串将联系紧密的被测试的一部分特性的行为进行分组描述 (例如，移动一辆汽车)。因为你可以按意愿指定任意多的嵌套块，你可以基于对象或者它们的依赖关系的上下文来编写的不同的测试。

这就是正在发生在 `move to` 的 `describe` 块里的事情：我们建立了两个 `contex` 块来提供 `Car` 内基于不同状态的不同期望  (发动机启动或关闭)。这说明了 BDD DSL 鼓励弄**清楚**对象在给定条件下应该如何表现这一要求。

接下来，这些字符串创建了测试失败时用来通知你的句子。例如，让我们假设“引擎未启动时进行移动”这一测试用例失败了。我们将收到 "Car move to when engine is not running should not move to given position" 的错误信息。这些语句对我们**理解**失败和预期的行为提供了非常大的帮助，重点是不需要阅读任何实际代码，因此它们减少了认知负荷。此外，它提供了一个标准语言来帮助你了解你团队的每一个成员，即便他们技术略差。

记住你也可以在编写不包含 BDD-style 语法的时候书写有着明确需求和易于理解命名的测试 (例如 XCtest)。然而，BDD 已经从头建立了这些功能和语法，使得测试更加容易。

如果你希望学更多的 BDD 语法，你应该看看 [Specta guide for writing specs](https://github.com/specta/specta#writing-specs).

### BDD 框架

对于 iOS 或者 Mac 开发者，你可以从这些 BDD 框架之中选取其一：

* [Specta](https://github.com/specta/specta)
* [Kiwi](https://github.com/kiwi-bdd/Kiwi)
* [Cedar](https://github.com/pivotal/cedar)

当涉及到语法，所有这些框架几乎是相同的。它们之间的主要区别在于它们的可配置能力和绑定的组件。

**Cedar** 捆绑了[匹配 (mathers)](https://github.com/pivotal/cedar/wiki/Writing-specs#matchers)和[置换 (doubles)](https://github.com/pivotal/cedar/wiki/Writing-specs#doubles)。在这篇文章里，让我们把置换就当作 mocks 吧，虽然这么认为并不是非常准确 (你可以在[这篇文章中](http://objccn.io/issue-15-5) 学习置换和 mocks 的区别)。

除了这些辅助工具，Ceder 还包含了额外的配置功能：集中测试。集中测试的意思是 Ceder 将只执行一个测试或者一组测试。想要启用集中测试，可以在  `it`，`describe` 或者 `context` 块的前面添加  `f`，

同样 Ceder 提供了反向配置能力：你可以添加 `x` 添加到测试中来关闭它。XCTest 有类似的配置能力，然而它们是通过操作 schemes 实现 (或者手动点击 "Run this test")。Cedar 配置更加更简单快速。

Cedar 用了一点黑客技术才能与 XCTest 集成，如果 Apple 决定改变 XCTest 内部实现的话，那么 Cedar 非常容易失效。然而从用户角度来看， Cedar 工作起来就像集成 XCTest 一样容易。

**Kiwi** 同样捆绑了[匹配模块](https://github.com/kiwi-bdd/Kiwi/wiki/Expectations)以及 [stubs 和 mocks](https://github.com/kiwi-bdd/Kiwi/wiki/Mocks-and-Stubs)。与 Cedar 不同的是， Kiwi 紧紧与 XCTest 结合在一起，然而，它缺乏像 Cedar 一样的可配置性功能。

**Specta** 用另一种途径来达到测试工具的目的，因为它缺少匹配，也没有 mocks 或者 stubs。它紧密地与 XCTest 结合在一起并且提供了近似 Cedar 的可配置性的能力。

正如前面提到过的，Cedar，Kiwi，以及 Specta 提供类似语法，我不能说其中一个框架要比其他所有都好；它们各有利弊。选择 BDD 框架归根结底来自个人偏好。

另外值得一提的是已经有两个 Swift 专用的 BDD 框架。

* [Sleipnir](https://github.com/railsware/Sleipnir)
* [Quick](https://github.com/Quick/Quick)

## 举例说明

还有最后一件事我想在举例前指出。记住，编写好的行为测试代码最重要的方面是识别依赖关系 (你可以在[依赖注入](http://objccn.io/issue-15-3)中阅读更多相关主题) 以及将它们暴露给你的接口。

你的大部分测试将基于你测试对象的状态，来断言一个特定交互是否发生，或者一个特定值是否返回 (或者传递给另一个对象)。将依赖提取出来，这可以允许你轻松 mock 值或者状态。此外，它将大大简化断言一个特定动作的发生或者特定值是否被计算。

记住，你不应该将对象**所有**的依赖关系和属性都暴露在接口之中 (特别是当你开始测试的时候，虽然这样很诱人)。你的接口只应该清楚的表述设计需求，而如果过多暴露依赖和属性，必将减少你的对象的可读性和目的的清晰度。

#### 消息格式化

让我们从一个简单的例子开始。我们将构建一个组件，负责为给定的事件对象进行文本消息格式化：

	@interface EventDescriptionFormatter : NSObject
	@property(nonatomic, strong) NSDateFormatter *dateFormatter;
	
	- (NSString *)eventDescriptionFromEvent:(id <Event>)event;
	
	@end

这就是我们接口的样子。Event 协议定义了一个事件的三个基本属性：

	@protocol Event <NSObject>
	
	@property(nonatomic, readonly) NSString *name;
	
	@property(nonatomic, readonly) NSDate *startDate;
	@property(nonatomic, readonly) NSDate *endDate;
	
	@end

我们的目标是测试 `EventDescriptionFormatter` 是否返回像 "My Event starts at Aug 21, 2014, 12:00 AM and ends at Aug 21, 2014, 1:00 AM." 这样的格式化后的描述。

请注意，这里 (以及本文中其他例子) 采用了 mocking 框架。如果你之前没有用过 mocking 框架，你应该向[置换测试：Mock，Stub 和其他](http://objccn.io/issue-15-5)这篇文章请教。

我们将先 mock 我们组件内的时间格式化器 (date formatter) 这个唯一依赖，我们将用创建的 mock 来返回开始和结束日期的固定字符串。然后我们检查从事件的格式化器里构造返回的字符串是否使用了我们先前 mock 的值。

    __block id mockDateFormatter;
    __block NSString *eventDescription;
    __block id mockEvent;

    beforeEach(^{
                    //  准备 mock date formatter
        mockDateFormatter = mock([NSDateFormatter class]);
        descriptionFormatter.dateFormatter = mockDateFormatter;

        NSDate *startDate = [NSDate mt_dateFromYear:2014 month:8 day:21];
        NSDate *endDate = [startDate mt_dateHoursAfter:1];

                    // 准备 mock 事件
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


注意我们在这里仅仅测试  `EventDescriptionFormatter` 是否用 `NSDateFormatter` 来格式化时间，我们并没有实际测试格式化的样式。因此，要严格测试组件，我们需要增加额外两个测试来检查格式化样式：

    it(@"should have appropriate date style on date formatter", ^{
        expect(descriptionFormatter.dateFormatter.dateStyle).to.equal(NSDateFormatterMediumStyle);
    });

    it(@"should have appropriate time style on date formatter", ^{
        expect(descriptionFormatter.dateFormatter.timeStyle).to.equal(NSDateFormatterMediumStyle);
    });

虽然现在我们拥有了经过完整测试的组件，我们也写了一些测试，但是这真的是一个很小的组件，不是吗？让我们从一个稍微不同的角度来尝试看看这个问题吧。

上面这个例子并没有确切地测试 `EventDescriptionFormatter` 的**行为**。它主要通过 mock `NSDateFormatter` 来测试其内部实现。我们实际上并不关心内部是否有个日期格式化器。从接口的角度来看，我们完全可以手动地只使用日期来进行格式化。在这里，我们关心的重点是我们是否能正确获取字符串。我们需要测试的其实是这个行为。

我们可以通过不 mock `NSDateFormatter` 来轻松达到这个目标。就像之前说的，我们不需要关心它是否存在，让我们从接口中去掉它：

	@interface EventDescriptionFormatter : NSObject
	
	- (NSString *)eventDescriptionFromEvent:(id <Event>)event;
	
	@end

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

我们测试变的非常简单。我们仅仅有一个简约的设置块来准备数据模型和调用测试方法。通过更多地专注于行为的结果，而不是它实际工作方式，我们简化了测试套件，同时仍然保留对我们对象功能的测试覆盖。这正是 BDD 的思想 -- 尝试思考行为的结果，而不是实际的实现。

#### 数据下载

在这个例子中，我们建立一个简单的数据下载器。我们特别专注在我们数据下载这个单一行为：发出请求和取消下载。让我们从定义接口开始吧：

	@interface CalendarDataDownloader : NSObject
	
	@property(nonatomic, weak) id <CalendarDataDownloaderDelegate> delegate;
	
	@property(nonatomic, readonly) NetworkLayer *networkLayer;
	
	- (instancetype)initWithNetworkLayer:(NetworkLayer *)networkLayer;
	
	- (void)updateCalendarData;
	
	- (void)cancel;
	
	@end

当然，下面是我们的网络层接口

	@interface NetworkLayer : NSObject
	
        // 传入标识符来取消请求
	- (id)makeRequest:(id <NetworkRequest>)request completion:(void (^)(id <NetworkRequest>, id, NSError *))completion;
	
	- (void)cancelRequestWithIdentifier:(id)identifier;
	
	@end

首先我们检查实际下载是否发生。 mock 的网络层已经在 `describe` 之前被创建并注入：

    describe(@"update calendar data", ^{
        beforeEach(^{
            [calendarDataDownloader updateCalendarData];
        });

        it(@"should make a download data request", ^{
            [verify(mockNetworkLayer) makeRequest:instanceOf([CalendarDataRequest class]) completion:anything()];
        });
    });

这部分相当简单，下一步是检查在我们调用取消方法之后请求是否被取消。我们需要确保在没有标识符的情况下我们不调用取消方法。这种行为的测试看起来像这样：

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

请求标识符是 `CalendarDataDownloader` 其中一个私有属性，所以我们需要使得它暴露在我们的测试中：

	@interface CalendarDataDownloader (Specs)
	@property(nonatomic, strong) id identifier;
	@end

你大概可以衡量这些测试中有一些错误。尽管对于检查特定行为这样是有效的，但它们暴露了 `CalendarDataDownloader` 内部的工作。这里不需要测试 `CalendarDataDownloader` 如何持有它的请求标识符。让我们看看我们如何在不暴露我们内部实现的情况下描述我们的测试：

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

我们通过 stub `makeRequest:completion:` 方法开始。我们返回一个固定的标识符。在相同的 `describe` 块内，我们定义了取消请求的 `describe` 块，用以在 `CalendarDataDownloader` 类中调用 `cancel` 方法。接着我们检查我们的固定字符串是否传入到我们所 mock 的网络层中的 `cancelRequestWithIdentifier:` 方法。

请注意，在这里我们实际上并不需要测试检查网络请求是否被执行 - 如果没有执行的话，我们就不会得到一个标识符并且 `cancelRequestWithIdentifier:` 也永远不会被调用。然而，我们保留了那个测试，来确保在当功能被破坏的时候我们能知道发生了什么。

我们已经设法在不暴露 `CalendarDataDownloader` 内部实现的同时测试了相同的行为。此外，我们用三个测试代替了之前四个。我们利用 BDD DSL 嵌套能力来束缚模拟的多重行为 -- 我们首先模拟下载，接着，在相同的 `describe` 块内，我们模拟取消请求。

### 测试视图控制器

在 iOS 开发者中对于测试视图控制器的最常见的态度是看不到价值所在。这让我觉得奇怪，控制器经常代表应用程序的核心。它们是将所有组件粘合在一起的地方，它们是建立了用户界面和应用逻辑及模型之间的联系的地方。因此，不经意的变化可能造成巨大的破坏。

这就是为什么我坚信视图控制器也必须被测试。然而，测试视图控制器并不是一件简单的工作。接下来的上传图片和登录视图控制器例子会帮助理解，如何利用 BDD 简化构建视图控制器测试套件。

#### 上传图片视图控制器

在这个例子中，我们需要建立一个简单的上传图片控制器，它包含一个 `rightBarButtonItem` 按钮。在按钮点击后，视图控制器将通知上传图片组件，应该上传图片。

是不是很简单？让我们从 `PhotoUploaderViewController` 接口开始：

	@interface PhotoUploadViewController : UIViewController
	@property(nonatomic, readonly) PhotoUploader *photoUploader;
	
	- (instancetype)initWithPhotoUploader:(PhotoUploader *)photoUploader;
	
	@end

在这里我们除了定义了一个 `PhotoUploader` 的额外依赖外并没有做其他事情。我们的实现也同样非常简单，为了简单起见，我们并不会实际选取照片；我们只是建立一个空的 `UIImage`：

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

但是我们仅仅完成了测试功能的一半：我们现在确保了当按钮按下的时候适当的方法被执行，但是我们无法确定适当的动作被执行 (我们实际上甚至不知道这个方法有没有被创建)。接下来让我们开始测试这些：

    describe(@"tapping right bar button item", ^{
        beforeEach(^{
            [photoUploadViewController didTapUploadButton:nil];
        });

        it(@"should tell the mock photo uploader to upload the photo", ^{
            [verify(mockPhotoUploader) uploadPhoto:instanceOf([UIImage class])
                                        completion:anything()];
        });
    });

不幸的是，`didTapUploadButton:` 在接口中不可见，我们可以在测试中通过定义一个可见类别暴露方法来解决问题。

	@interface PhotoUploadViewController (Specs)
	- (void)didTapUploadButton:(UIBarButtonItem *)uploadButton;
	@end

这个时候，我们可以说 `PhotoUploadViewController` 被完全测试了。

但是以上例子有什么问题？问题是我们测试了 `PhotoUploadViewController` 内部实现。我们不应该实际**关心**按钮上 target/action 的值，我们应该专注于它被点击时会发生什么。其他都是实现细节。

让我们回头看看 `PhotoUploadViewController`，并讨论如何重写测试确保我们只测试我们的界面，而不是实现。

首先，我们不需要知道 `didTapUploadButton:` 方法存在与否。它只是实现细节。我们应该只关心行为：当用户点击上传按钮，`UploadManager` 应该收到一个 `uploadPhoto:` 消息。这太好了，因为这表示我们不再需要在 `PhotoUploadViewController` 中添加 `Specs` 类别

接下来，我们不需要知道 `rightBarButtonItem` 中的 target/action 的定义。我们**仅只**需要关注当点击的时候发生了什么。让我们在测试中模拟这个动作，我们可以为 `UIBarButtonItem` 创建一个 helper 类别来完成这件事情：

	@interface UIBarButtonItem (Specs)
	
	- (void)specsSimulateTap;
	
	@end

这个实现相当简单，就只是在 `UIBarButtonItem` 的 `target` 中执行 `action`：

	@implementation UIBarButtonItem (Specs)
	
	- (void)specsSimulateTap {
	    [self.target performSelector:self.action withObject:self];
	}
	
	@end

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

值得注意的是我们设法消除了两个测试后我们仍然拥有一个严格测试的组件。此外，我们的测试套件不易被打破，我们不再依赖于 `didTapUploadButton:` 方法。最后同样重要的，我们更关注我们控制器行为，而不是它的内部实现。

### 登录视图控制器

在这个例子中，我们将构建一个简单的应用程序,要求用户输入用户名和密码以登录到一个抽象的服务。

我们将通过构建一个包含两个文本框以及一个登录按钮的  `SignInViewController` 。应该确保我们的控制器尽可能的轻量级，所以我们把负责登录的组件抽象到一个称为 `SignInManager` 的单独的类中。

我们的需求如下：当用户点击登录按钮，并且用户名和密码已经填写，我们的视图控制器将告诉 `SignInManager` 利用用户名和密码来执行登录。如果没有填写用户名或者密码 (或者两者都没填写)，app 将在文本框上方显示一个错误信息。

我们需要测试的视图部分是：

	@interface SignInViewController : UIViewController
	
	@property(nonatomic, readwrite) IBOutlet UIButton *signInButton;
	
	@property(nonatomic, readwrite) IBOutlet UITextField *usernameTextField;
	@property(nonatomic, readwrite) IBOutlet UITextField *passwordTextField;
	
	@property(nonatomic, readwrite) IBOutlet UILabel *fillInBothFieldsLabel;
	
	@property(nonatomic, readonly) SignInManager *signInManager;
	
	- (instancetype)initWithSignInManager:(SignInManager *)signInManager;
	
	- (IBAction)didTapSignInButton:(UIButton *)signInButton;
	
	@end

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

上面的例子中提到的代码有相当多的问题。首先我们暴露了过多 `SignInViewController` 内部实现，包括按钮，文本框以及方法。事实是，我们并不真正需要把所有这一切都做一遍。

让我们看看如何重构这些测试来确保没有触碰到内部实现。我们将通过删除登录按钮的 target 和 method 的钩子来开始:

	@interface UIButton (Specs)
	
	- (void)specsSimulateTap;
	
	@end
	
	@implementation UIButton (Specs)
	
	- (void)specsSimulateTap {
	    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
	}
	
	@end

现在我们可以仅通过调用我们的按钮上的这个方法，并断言 `SignInManager` 是否收到相应的消息。但是我们依然可以改善这个测试的写法。

让我们假设我们不想知道谁拥有这个登录按钮，也许这是一个视图控制器视图的子视图，又或者我们将它封装在了单独的视图里并将自己作为它的代理。我们实际上不应该关心它在哪；我们应该只关心它是否在我们视图控制器视图的某个地方，并且当我们点击时候会发生什么。我们可以用一个辅助方法来抓取登录按钮，而不用关心它在哪：

	@interface UIView (Specs)
	
	- (UIButton *)specsFindButtonWithTitle:(NSString *)title;
	
	@end

我们的方法将遍历视图中的所有子视图并返回第一个和我们 title 参数匹配的按钮，我们可以为文本框或标签写类似的方法:

	@interface UIView (Specs)
	
	- (UITextField *)specsFindTextFieldWithPlaceholder:(NSString *)placeholder;
	- (UILabel *)specsFindLabelWithText:(NSString *)text;
	
	@end

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

看起来是不是更简单？我们通过 "Sign in" 的标题来寻找按钮的同时，也测试了这个按钮是否存在。此外，通过模拟一个点击请求，我们测试了动作是否被正确连接。最后，通过断言 `SignInManager` 被调用与否，我们测试这部分功能有没有正确被实现 -- 所有这些都用三个简单的测试实现了。

另一件很棒的事是我们不再需要暴露任何内部属性。事实上，我们的接口可能非常简单,比如:

	@interface SignInViewController : UIViewController
	
	@property(nonatomic, readonly) SignInManager *signInManager;
	
	- (instancetype)initWithSignInManager:(SignInManager *)signInManager;
	
	@end

另外一件好事是这些测试我们利用了 BDD DSL 的功能。注意我们使用 `context` 块为 `SignInViewController` 根据不同的需求行为来定义其文本字段状态。这是一个如何使用 BDD 来在保持测试功能特性的同时将它们变得简单可读的好例子。

## 结论

行为驱动开发看起来并不像最初那么困难。所有你需要的只是改变你的思维方式 -- 更多思考一个对象的行为 (它的接口应该如何) 并且减少对实现的关注。通过这样做，你将拥有更健壮的代码，以及同样杰出的测试套件。此外，你的测试在生产代码修改时失效的可能性会降低，它们将专注于测试对象的行为而不是内部实现。

并且 iOS 社区提供了如此杰出的工具，这让你可以立即开始对你 app 的行为驱动开发。同时你知道了应该测试什么，没有任何借口不这样做了，不是吗？

### 链接

如果你对 BDD 的起源很感兴趣，如何产生的，你绝对应该读一下[这篇文章](http://dannorth.net/introducing-bdd/)。
对于那些了解 TDD 的用户，但是不确切知道它和 BDD 的区别的用户，我建议[这篇文章](http://blog.mattwynne.net/2012/11/20/tdd-vs-bdd/)。
最后最重要的，你可以在[这里](https://github.com/objcio/issue-15-bdd)找到本文出现的测试例子。  

---

---

 

原文 [Behavior-Driven Development](http://www.objc.io/issue-15/behavior-driven-development.html)
