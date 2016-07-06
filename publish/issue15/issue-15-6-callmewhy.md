如何进行 UI 测试是 iOS 开发中很常见的问题 (我猜测 Mac 等其他 UI 驱动的平台也是这样)。很多人完全不做 UI 测试，问起来他们经常这样说：“你只应该测试你的业务逻辑。” 也有一部分人想做 UI 测试，但是觉得它太复杂于是便放弃了。

每当有人和我说 UI 测试很难的时候，我就会回想起在一次[测试小组讨论](http://www.meetup.com/CocoaPods-NYC/events/164278492/)中，[Landon Fuller](https://twitter.com/landonfuller) 谈到 [Paper (by 53)](https://www.fiftythree.com/paper) 项目的 UI 测试时说的一段话：

> 你在屏幕上看到的是各种数据和变化综合之后按照时间变化所得到的结果。如果你可以将这些**东西**分解成可供测试的单元的话，就意味着你可以将相对复杂的内容拆解成更容易理解的元素。

Paper 的 UI 相对来说算是复杂的了，当构建这样的 UI 的时候，可测试性一般不会被考虑在内。但是，用户的任何一个行为在代码中都是被建模处理的，在测试中模仿用户的行为是一件很容易的事情。而问题在于大多数框架，包括 UIKit，都没有公开的暴露测试所需要的底层结构。

知道 “测试什么” 和知道 “如何测试” 同等重要。我一直都在提及 “UI 测试”，因为这是一个被广为接受的概念，我即将深入讨论这类测试。实际上，我觉得你可以把 UI 测试分成两类：1) 行为 和 2) 外观.

我们无法确定地说某种 UI 的外观是正确的，因为 UI 的外观总是在频繁的变化着。你肯定不想每次修改 UI 的时候都去修改 UI 的测试。但这并不意味着你无法测试外观。我对于这个方面没有任何经验，但是我们可以用截屏的方式检验外观。如果想进一步的了解，可以阅读 Orta 关于这方面的[文章](http://objccn.io/issue-15-7)。

在开始之前友情提示各位，这篇文章将会探讨用户行为测试相关的内容。我在Github上提供了一个[项目](https://github.com/klaaspieter/objc-io-issue-15-ux-testing)，里面包含了一些实际的例子，虽然是使用Objective-C编写的iOS项目，但是背后的原理是可以应用于Mac和其他UI框架的。

在我测试用户行为时的第一条原则是：使用代码的形式来模拟事件触发，并让它们就好像真的是由用户的行所触发的那样。这可能会有点困难，因为正如前面所说，并不是所有的框架都会公开底层接口。

类似于 [KIF](https://github.com/kif-framework/KIF)、[Frank](http://www.testingwithfrank.com/) 和 [Calabash](http://calaba.sh/) 的项目解决了这个问题，但是代价就是需要插入一个层额外的复杂度，而我们应当始终使用最简单的可行方案。一般来说都测试的结果应该是确定的，不修改的话要么就持续地失败，要么就持续地成功。最糟糕的测试套件就是那些会随机失败的测试。我不会选择去用那样的方案，因为从我的经验来看，它们牺牲了可靠性和稳定性而让项目变得错综复杂。

注意到在示例项目中我使用了 [Specta](https://github.com/specta/specta) 和 [Expecta](https://github.com/specta/expecta)，严格来讲这并不是最简单的解决方案，最简单的解决方案是 XCText。但是又有很多原因让我不得不[提及它们](http://www.annema.me/why-i-prefer-testing-with-specta-expecta-and-ocmockito)。并且从我自己的开发经验来看，它们并不会影响测试的可靠性和稳定性。事实上，我敢打赌它们让我的测试更好 (这是个安全的赌局，因为**好**是个模糊的概念的^_^)。

不管测试方法是什么，当测试用户行为的时候，我们总是想尽可能接近于用户的真实操作。当用户与应用交互的时候，我们往往希望能够用代码重现出来。想象一下，当用户看着一个 ViewController，然后点击了一个按钮，弹出了一个新的 ViewController。你应该是希望测试可以展示原始的 ViewConnector，并且实现点击按钮操作，然后确保呈现一个新的 ViewController。

专注于用代码来模拟用户交互，你可以一次验证多件事情。最重要的，你可以验证核实期望的行为。作为附赠，你也同时测试了控件正确被初始化以及它们的 action 是被正确设置的。

举个例子，比如在某个测试中，我们直接调用了一个行为方法。这并不需要把你的测试和按钮要做的事情连接起来，当然实际上这样的测试也不会去做这件事。但是如果按钮的 target 或者 action 改变了，你的测试依旧可以通过。你希望证实的其实是按钮在按照你的计划行事。而至于按钮调用什么方法，针对什么对象，这都不是在测试中该考虑的内容。

UIKit 在 `UIControl` 里提供了非常有用的 `sendActionsForControlEvents:` 方法，我们可以用来模仿用户操作。比如，用它来点击按钮：

    [_button sendActionsForControlEvent: UIControlEventTouchUpInside];

类似地，调用这个函数来切换 `UISegmentedControl` 的选项卡：

    segments.selectedSegmentIndex = 1;
    [segments sendActionsForControlEvent: UIControlEventValueChanged];

注意在这里并不只是发送了 `UIControlValueChanged` 这个消息。当一个用户和控件交互的时候，它会先改变选中的 index 值，然后再发送 `UIControlValueChanged` 消息。这是一个非常好的例子，示范了如何通过代码模拟用户行为。

UIKit 中并不是所有的控件都有一个等价于 `sendActionsForControlEvents:` 的方法。但是只要有创造力的话，总是能找到变通的方法的。正如前面所说，最重要的是使用代码去模拟用户触发了这个事件。

举个例子，`UITableView` 并没有函数用来选中单元格并且让它去调用对应的一系列委托方法。在示例项目中通过两种方式实现了这个功能。

第一种方法是针对 storyboard 的：它通过手动触发你希望的单元格来调用对应的 segue。不幸的是，这并不能验证单元格都是和 segue 关联的：

    [_tableViewController performSegueWithIdentifier:@"TableViewPushSegue" sender:nil];

另一个选择则不需要 storyboard 的参与，在测试代码里手动调用 `tableView:didSelectRowAtIndexPath:` 这个委托方法。如果你使用 storyboard，你可以依旧使用segue，但是你需要从委托方法中手动调用：

    [_viewController.tableView.delegate tableView:_viewController.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    expect(_viewController.navigationController.topViewController).to.beKindOf([PresentedViewController class]);

我更倾向于第二种选择，它完全将测试从 ViewController 的呈现方式中解耦。它可以是一个自定义的 segue，或者 `presentViewController:animated:completion`，或者是其他的甚至 Apple 还没发明的方式。不过，所有测试所关心的是最后的 `topViewController` 属性是不是像预期的一样。最好的选择是让 TableView 自己去选中一行数据并且触发对应的响应 action，不过现在这个方法行不通。

作为测试控件的最后一个示例，我想展示一下 `UIBarButtonItem` 的特殊情况。它们没有 `sendActionsForControlEvent:` 方法，因为它们没有继承自 `UIControl` 类。让我们看看对于这样的情况，如何发送按钮事件，以及，对于我们的代码而言，如何让它看起来像是被用户点击了。

`UIBarButtonItem` 并不像 `UIControl`，`UIBarButtonItem` 只拥有一个 target 和一个 action 与它关联。调用这个事件很简单：

    [_viewController.barButton.target  performSelector:_viewController.barButton.action
                                             withObject:_viewController.barButton];

如果你在使用 ARC 那么编译器会抱怨说无法从未知的 selector 中推断出内存管理的方式。这种状况对我而言是不可接受的，因为在我眼里警告就是错误。

一个选择是用 [#pragma directive](http://nshipster.com/pragma/#inhibiting-warnings) 来隐藏警告，另一个选择就是使用直接使用runtime：

    #import <objc/message.h>

    objc_msgSend(_viewController.barButton.target, _viewController.barButton.action, _viewController.barButton);

我更喜欢 runtime 的方式，因为我不喜欢我的代码被 pragma directives 搞得一团糟。而且也因为它给了我一个实际使用 runtime 的借口。

说句实话，我并不百分百的确定这些 "解决方案" 不会出问题，因为这并没有解决根本的警告。测试的生命周期往往是短暂的，所以任何在测试操作中发生的内存缺陷都不足以引起内存问题。虽然在我使用的这段时间一直没什么问题，但是其实我对这种情况也不是十分清楚，而且它有可能会随机的在某个问题报出异常。如果有任何建议，欢迎在这里[提出来](https://twitter.com/klaaspieter)。

在文章的最后，我想再说一说 ViewController。ViewController 可能是 iOS 应用中最重要的部分，它被抽象出来调节视图和业务逻辑的关系。为了能更好的测试用户行为，我们不得不呈现 ViewController。但是，在测试用例中呈现 ViewController 让我很快得出结论：在构建它们的过程中，适合测试并不在考虑之内。

Presenting and dismissing view controllers is the best way to make sure every test has a consistent start state. Unfortunately, doing so in rapid succession—like a test runner does—will quickly result in error messages like:

显示和隐藏 ViewController 是确保每个测试都有一个不变的初始状态的最好方式。但是不幸的是，在连续快速的这样做之后 -- 测试里肯定都这么做 -- 很快就会导致下面的错误信息：

- Warning: Attempt to dismiss from view controller &lt;UINavigationController: 0x109518bd0&gt; while a presentation or dismiss is in progress!
- Warning: Attempt to present &lt;PresentedViewController: 0x10940ba30&gt; on &lt;UINavigationController: 0x109518bd0&gt; while a presentation is in progress!
- Unbalanced calls to begin/end appearance transitions for &lt;UINavigationController: 0x109518bd0&gt;
- nested push animation can result in corrupted navigation bar

一套测试应该尽可能的快，一直等到每一个 ViewController 的展示结束是不可接受的。最终我们发现，这些警告都是基于单窗口的。只要在独立的窗口展示每一个 ViewController，就可以给你的测试一个始终一致的开始状态，也保证它运行起来足够的快。通过在每个独立的窗口展示分别，你就可以不需要等到展示或者消失过程结束了。

对于 ViewController 还有一些问题。比如，push 到导航控制器的操作发生在下一个 run loop，而使用 modal 的方式弹出窗口却不是这样。如果你想尝试一下这种测试方式，我建议你看一下我的 [ViewController 测试助手](https://github.com/klaaspieter/KPAViewControllerTestHelper)，它会帮你解决这些问题。

当测试行为的时候，你经常需要证实，在某个交互之后，一个新的 ViewController 可以正常的弹出来。换句话说，你需要证实当前 ViewController 结构的状态。UIKit 在这个方面做的很好，它提供了一系列必要的方法，帮助你完成这个工作。比如下面这个例子，它可以让你确定 ViewController 有没有正确地以 modal 形式弹出：

    expect(_viewController.presentedViewController).to.beKindOf([PresentedViewController class]);

或者以 push 进导航控制器：

    expect(_viewController.navigationController.topViewController).to.beKindOf([PresentedViewController class]);


UI测试其实并不难，只需要清楚你需要测试的内容就行。你需要测试的是用户交互，而不是应用的外观。通过创造力和不断的坚持，大多数框架的缺点都是可以通过变通的方法解决的，而不用牺牲测试套件的稳定性和可维护性。时刻记着，让你的测试尽可能接近用户的真实操作。

---

 

原文 [User Interface Testing](http://www.objc.io/issue-15/user-interface-testing.html)
