我们不是迷信测试，但它应该帮助我们加快开发进度，并且让事情变得更有趣。

## 让事情保持简单

测试简单的事情很简单，同样，测试复杂的事会很复杂。就像我们在其他文章中指出的那样，让事情保持简单小巧总是好的。除此之外，它还有利于我们测试。这是件双赢的事。让我们来看看[测试驱动开发][2]（简称 TDD），有些人喜欢它，有些人则不喜欢。我们在这里不深入讨论，只是如果用 TDD，你得在写代码之前先写好测试。如果你好奇的话，可以去找 Wikipedia 上的文章看看。同时，我们也认为重构和测试可以很好地结合在一起。

测试 UI 部分通常很麻烦，因为它们包含太多活动部件。通常，view controller 需要和大量的 model 和 view 类交互。为了使 view controller 便于测试，我们要让任务尽量分离。

幸好，我们在[更轻量的 view controller][3] 这篇文章中的阐述的技术可以让测试更加简单。通常，如果你发现有些地方很难做测试，这就说明你的设计出了问题，你应该重构它。你可以重新参考[更轻量的 view controller][3] 这篇文章来获得一些帮助。总的目标就是有清晰的关注点分离。每个类只做一件事，并且做好。这样就可以让你只测试这件事。

记住：测试越多，回报的增长趋势越慢。首先你应该做简单的测试。当你觉得满意时，再加入更多复杂的测试。

## Mocking

当你把一个整体拆分成小零件（比如更小的类）时，我们可以针对每个小的类来进行测试。但由于我们测试的类会和其他类交互，这里我们用一个所谓的 `mock` 或 `stub` 来绕开它。把 `mock` 对象看成是一个占位符，我们测试的类会跟这个占位符交互，而不是真正的那个对象。这样，我们就可以针对性地测试，并且保证不依赖于应用程序的其他部分。

在示例程序中，我们有个包含数组的 data source 需要测试。这个 data source 会在某个时候从 table view 中取出（dequeue）一个 cell。在测试过程中，还没有 table view，但是我们传递一个 `mock` 的 table view，这样即使没有 table view，也可以测试 data source，就像下面你即将看到的。起初可能有点难以理解，多看几次后，你就能体会到它的强大和简单。

Objective-C 中有个用来 mocking 的强大工具叫做 [OCMock][4]。它是一个非常成熟的项目，充分利用了 Objective-C 运行时强大的能力和灵活性。它使用了一些很酷的技巧，让通过 mock 对象来测试变得更加有趣。

本文后面有 data source 测试的例子，它更加详细地展示了这些技术如何工作在一起。

## SenTestKit

> <span class="secondary radius label">编者注</span> 这一节有一些过时了。在 Xcode 5 中 SenTestingKit 已经被 XCTest 完全取代，不过两者使用上没有太多区别，我们可以通过 Xcode 的 `Edit` -> `Refactor` -> `Convert to XCTest` 选项来切换到新的测试框架

我们将要使用的另一个工具是一个测试框架，开发者工具的一部分：[Sente][5] 的 SenTestingKit。这个上古神器从 1997 年起就伴随在 Objective-C 开发者左右，比第一款 iPhone 发布还早 10 年。现在，它已经集成到 Xcode 中了。SenTestingKit 会运行你的测试。通过 SenTestingKit，你将测试组织在类中。你需要给每一个你想测试的类创建一个测试类，类名以 `Tests` 结尾，它反应了这个类是干什么的。

这些*测试类*里的方法会做具体的测试工作。方法名必须以 `test` 开头来作为触发一个测试运行的条件。还有特殊的 `-setUp` 和 `-tearDown` 方法，你可以重载它们来设置各个测试。记住，你的测试类就是个类而已：只要对你有帮助，可以按需求在里面加 properties 和辅助方法。

做测试时，为测试类创建基类是个不错的模式。把通用的逻辑放到基类里面，可以让测试更简单和集中。可以通过[示例程序][6]中的例子来看看这样带来的好处。我们没有使用 Xcode 的测试模板，为了让事情简单有效，我们只创建了单独的 `.m` 文件。通过把类名改成以 `Tests` 结尾，类名可以反映出我们在对什么做测试。


> <span class="secondary radius label">编者注</span> Xcode 5 中 默认的测试模板也不再会自动创建 `.h` 文件了 


## 与 Xcode 集成

测试会被 build 成一个 bundle，其中包含一个动态库和你选择的资源文件。如果你要测试某些资源文件，你得把它们加到测试的 target 中，Xcode 就会将它们打包到一个 bundle 中。接着你可以通过 NSBundle 来定位这些资源文件，示例项目实现了一个 `-URLForResource:withExtension:` 方法来方便的使用它。

Xcode 中的每个 `scheme` 定义了相应的测试 bundle 是哪个。通过 ⌘-R 运行程序，⌘-U 运行测试。

测试的运行依附于程序的运行，当程序运行时，测试 bundle 将被注入（`injected`）。测试时，你可能不想让你的程序做太多的事，那样会对测试造成干扰。可以把下面的代码加到 app delegate 中：


    static BOOL isRunningTests(void) __attribute__((const));

    - (BOOL)application:(UIApplication *)application
            didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
    {
        if (isRunningTests()) {
            return YES;
        }

        //
        // Normal logic goes here
        //

        return YES;
    }

    static BOOL isRunningTests(void)
    {
        NSDictionary* environment = [[NSProcessInfo processInfo] environment];
        NSString* injectBundle = environment[@"XCInjectBundle"];
        return [[injectBundle pathExtension] isEqualToString:@"octest"];
    }


编辑 Scheme 给了你极大的灵活性。你可以在测试之前或之后运行脚本，也可以有多个测试 bundle。这对大型项目来说很有用。最重要的是，可以打开或关闭个别测试，这对调试测试非常有用，只是要记得之后再把它们重新全部打开。

还要记住你可以为测试代码下断点，当测试执行时，调试器会在断点处停下来。

## 测试 Data Source

好了，让我们开始吧。我们已经通过拆分 view controller 让测试工作变得更轻松了。现在我们要测试 `ArrayDataSource`。首先我们新建一个空的，基本的测试类。我们把接口和实现都放到一个文件里；也没有哪个地方需要包含 `@interface`，放到一个文件会显得更加漂亮和整洁。


    #import "PhotoDataTestCase.h"

    @interface ArrayDataSourceTest : PhotoDataTestCase
    @end

    @implementation ArrayDataSourceTest
    - (void)testNothing;
    {
        STAssertTrue(YES, @"");
    }
    @end


这个类没做什么事，只是展示了基本的设置。当我们运行这个测试时，`-testNothing` 方法将会运行。特别地，`STAssert` 宏将会做琐碎的检查。注意，前缀 `ST` 源自于 `SenTestingKit`。这些宏和 Xcode 集成，会把失败显示到侧边面板的 _Issues_ 导航栏中。

## 第一个测试

我们现在把 `testNothing` 替换成一个简单、真正的测试：


    - (void)testInitializing;
    {
        STAssertNil([[ArrayDataSource alloc] init], @"Should not be allowed.");
        TableViewCellConfigureBlock block = ^(UITableViewCell *a, id b){};
        id obj1 = [[ArrayDataSource alloc] initWithItems:@[]
                                          cellIdentifier:@"foo"
                                      configureCellBlock:block];
        STAssertNotNil(obj1, @"");
    }


## 实践 Mocking

接着，我们想测试 `ArrayDataSource` 实现的方法：


    - (UITableViewCell *)tableView:(UITableView *)tableView
             cellForRowAtIndexPath:(NSIndexPath *)indexPath;


为此，我们创建一个测试方法：


    - (void)testCellConfiguration;


首先，创建一个 data source：


    __block UITableViewCell *configuredCell = nil;
    __block id configuredObject = nil;
    TableViewCellConfigureBlock block = ^(UITableViewCell *a, id b){
        configuredCell = a;
        configuredObject = b;
    };
    ArrayDataSource *dataSource = [[ArrayDataSource alloc] initWithItems:@[@"a", @"b"]
                                                          cellIdentifier:@"foo"
                                                      configureCellBlock:block];


注意，`configureCellBlock` 除了存储对象以外什么都没做，这可以让我们可以更简单地测试它。

然后，我们为 table view 创建一个 *mock 对象*：


    id mockTableView = [OCMockObject mockForClass:[UITableView class]];


Data source 将在传进来的 table view 上调用 `-dequeueReusableCellWithIdentifier:forIndexPath:` 方法。我们将告诉 mock object 当它收到这个消息时要做什么。首先创建一个 cell，然后设置 _mock_。


    UITableViewCell *cell = [[UITableViewCell alloc] init];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [[[mockTableView expect] andReturn:cell]
            dequeueReusableCellWithIdentifier:@"foo"
                                 forIndexPath:indexPath];


第一次看到它可能会觉得有点迷惑。我们在这里所做的，是让 mock *记录*特定的调用。Mock 不是一个真正的 table view；我们只是假装它是。`-expect` 方法允许我们设置一个 mock，让它知道当这个方法调用时要做什么。

另外，`-expect` 方法也告诉 mock 这个调用必须发生。当我们稍后在 mock 上调用 `-verify` 时，如果那个方法没有被调用过，测试就会失败。相应地，`-stub` 方法也用来设置 mock 对象，但它不关心方法是否被调用过。

现在，我们要触发代码运行。我们就调用我们希望测试的方法。


    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    id result = [dataSource tableView:mockTableView
                cellForRowAtIndexPath:indexPath];


然后我们测试是否一切正常：


    STAssertEquals(result, cell, @"Should return the dummy cell.");
    STAssertEquals(configuredCell, cell, @"This should have been passed to the block.");
    STAssertEqualObjects(configuredObject, @"a", @"This should have been passed to the block.");
    [mockTableView verify];


`STAssert` 宏测试值的相等性。注意，前两个测试，我们通过比较指针来完成；我们不使用 `-isEqual:`，是因为我们实际希望测试的是 `result`，`cell` 和 `configuredCell` 都是同一个对象。第三个测试要用 `-isEqual:`，最后我们调用 mock 的 `-verify` 方法。

注意，在示例程序中，我们是这样设置 mock 的：


    id mockTableView = [self autoVerifiedMockForClass:[UITableView class]];


这是我们测试基类中的一个方便的封装，它会在测试最后自动调用 `-verify` 方法。

## 测试 UITableViewController

下面，我们转向 `PhotosViewController`。它是个 `UITableViewController` 的子类，它使用了我们刚才测试过的 data source。View controller 剩下的代码已经相当简单了。

我们想测试点击 cell 后把我们带到详情页面，即一个 `PhotoViewController` 的实例被 push 到 navigation controller 里面。我们再次使用 mocking 来让测试尽可能不依赖于其他部分。

首先我们创建一个 `UINavigationController` 的 mock：


    id mockNavController = [OCMockObject mockForClass:[UINavigationController class]];


接下来，我们要使用*部分 mocking*。我们希望 `PhotosViewController` 实例的 `navigationController` 返回 `mockNavController`。我们不能直接设置 navigation controller，所以我们简单地用 stub 来替换掉 `PhotosViewController` 实例这个方法，让它返回 `mockNavController` 就可以了。


    PhotosViewController *photosViewController = [[PhotosViewController alloc] init];
    id photosViewControllerMock = [OCMockObject partialMockForObject:photosViewController];
    [[[photosViewControllerMock stub] andReturn:mockNavController] navigationController];


现在，任何时候对 `photosViewController` 调用 `-navigationController` 方法，都会返回 `mockNavController`。这是个强大的技巧，OCMock 就有这样的本领。

接下来，我们要告诉 navigation controller mock 我们调用的期望，即，一个 photo 不为 nil 的 detail view controller。


    UIViewController* viewController = [OCMArg checkWithBlock:^BOOL(id obj) {
        PhotoViewController *vc = obj;
        return ([vc isKindOfClass:[PhotoViewController class]] &&
                (vc.photo != nil));
    }];
    [[mockNavController expect] pushViewController:viewController animated:YES];


现在，我们触发 view 加载，并且模拟一行被点击：


    UIView *view = photosViewController.view;
    STAssertNotNil(view, @"");
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [photosViewController tableView:photosViewController.tableView
            didSelectRowAtIndexPath:indexPath];


最后我们验证 mocks 上期望的方法被调用过：


    [mockNavController verify];
    [photosViewControllerMock verify];


现在我们有了一个测试，用来测试和 navigation controller 的交互，以及正确 view controller 的创建。

又一次地，我们在示例程序中使用了便捷的方法：


    - (id)autoVerifiedMockForClass:(Class)aClass;
    - (id)autoVerifiedPartialMockForObject:(id)object;


于是，我们不需要记住调用 `-verify`。

## 进一步探索

就像你从上面看到的那样，*部分 mocking* 非常强大。如果你看看 `-[PhotosViewController setupTableView]` 方法的源码，你就会看到它是如何从 app delegate 中取出 model 对象的。


    NSArray *photos = [AppDelegate sharedDelegate].store.sortedPhotos;


上面的测试依赖于这行代码。打破这种依赖的一种方式是再次使用 *部分 mocking*，让 app delegate 返回预定义的数据，就像这样：


    id storeMock; // 假设我们已经设置过了
    id appDelegate = [AppDelegate sharedDelegate]
    id appDelegateMock = [OCMockObject partialMockForObject:appDelegate];
    [[[appDelegateMock stub] andReturn:storeMock] store];


现在，无论何时调用 `[AppDelegate sharedDelegate].store` ，它将返回 `storeMock`。将这个技术使用好的话，可以确保让你的测试恰到好处地在保持简单和应对复杂之间找到平衡。

## 需要记住的事

*部分 mock* 技术将会在 mocks 的存在期间替换并保持被 mocking 的对象，并且一直有效。你可以通过提前调用 `[aMock stopMocking]` 来终于这种行为。大多数时候，你希望 *部分 mock* 在整个测试期间都保持有效。如果要提前终止，请确保在测试方法最后放置 `[aMock verify]`。否则 ARC 会过早释放这个 mock，这样你就不能 `-verify` 了，这不太可能是你想要的结果。

## 测试 NIB 加载

`PhotoCell` 设置在一个 NIB 中，我们可以写一个简单的测试来检查 outlets 设置得是否正确。我们来回顾一下 `PhotoCell` 类：


    @interface PhotoCell : UITableViewCell

    + (UINib *)nib;

    @property (weak, nonatomic) IBOutlet UILabel* photoTitleLabel;
    @property (weak, nonatomic) IBOutlet UILabel* photoDateLabel;

    @end


我们的简单测试的实现看上去是这样：


    @implementation PhotoCellTests

    - (void)testNibLoading;
    {
        UINib *nib = [PhotoCell nib];
        STAssertNotNil(nib, @"");

        NSArray *a = [nib instantiateWithOwner:nil options:@{}];
        STAssertEquals([a count], (NSUInteger) 1, @"");
        PhotoCell *cell = a[0];
        STAssertTrue([cell isMemberOfClass:[PhotoCell class]], @"");

        // 检查 outlet 是否正确设置
        STAssertNotNil(cell.photoTitleLabel, @"");
        STAssertNotNil(cell.photoDateLabel, @"");
    }

    @end


非常基础，但是能出色完成工作。

值得一提的是，当有发生改变时，我们需要同时更新测试以及相应的类或 nib 。这是事实。你需要考虑改变类或者 nib 文件时可能会打破原有的 outlets 连接。如果你用了 `.xib` 文件，你可能要注意了，这是经常发生的事。

## 关于 Class 和 Injection

我们已经从*与 Xcode 集成*得知，测试 bundle 会注入到应用程序中。省略注入的如何工作的细节（它本身是个巨大的话题），简单地说：注入是把待注入的 bundle（我们的测试 bundle）中的 Objective-C 类添加到运行的应用程序中。这很好，因为这样允许我们运行测试了。

还有一件事会很让人迷惑，那就是如果我们同时把一个类添加到应用程序和测试 bundle中。如果在上面的示例程序中，我们（不小心）把 `PhotoCell` 类同时添加到测试 bundle 和应用程序里的话，在测试 bundle 中调用 `[PhotoCell class]` 会返回一个不同的指针（你应用程序中的那个类）。于是我们的测试将会失败：


    STAssertTrue([cell isMemberOfClass:[PhotoCell class]], @"");


再一次声明：注入很复杂。你应该确认的是：不要把应用程序中的 `.m` 文件添加到测试 target 中。否则你会得到预想不到的行为。

## 额外的思考

如果你使用一个持续集成 (CI) 的解决方案，让你的测试启动和运行是一个好主意。详细的描述超过了本文的范围。这些脚本通过 `RunUnitTests` 脚本触发。还有个 `TEST_AFTER_BUILD` 环境变量。

另一种有趣的选择是创建单独的测试 bundle 来自动化性能测试。你可以在测试方法里做任何你想做的。定时调用一些方法并使用 `STAssert` 来检查它们是否在特定阈值里面是其中一种选择。

### 扩展阅读

  * [Test-driven development][6]
  * [OCMock][8]
  * [Xcode Unit Testing Guide][11]
  * [Book: Test Driven Development: By Example][12]
  * [Blog: Quality Coding][13]
  * [Blog: iOS Unit Testing][14]
  * [Blog: Secure Mac Programing][15]

---

原文 [Testing View Controllers](http://www.objc.io/issue-1/testing-view-controllers.html)

译文 [测试 View Controllers - 言无不尽](http://tang3w.com/translate/objective-c/objc.io/2013/10/24/测试-view-controllers.html)

   [2]: https://en.wikipedia.org/wiki/Test-driven_development
   [3]: http://objccn.io/issue-1-1
   [4]: http://ocmock.org/
   [5]: http://www.sente.ch/
   [6]: https://github.com/objcio/issue-1-lighter-view-controllers/blob/master/PhotoDataTests/PhotoDataTestCase.h
   [7]: https://twitter.com/danielboedewadt
   [8]: http://ocmock.org
   [11]: https://developer.apple.com/library/ios/documentation/DeveloperTools/Conceptual/UnitTesting/
   [12]: http://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530
   [13]: http://qualitycoding.org
   [14]: http://iosunittesting.com
   [15]: http://blog.securemacprogramming.com/?s=testing&searchsubmit=Search
   [16]: http://objccn.io/issue-1
