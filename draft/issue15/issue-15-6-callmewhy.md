One question often asked about iOS (and I guess Mac, and every other UI-driven platform) is how to test UIs. A lot of us don't do it at all, often saying things like: “you should only test your business logic.” Others want to test the UI, but deem it too complex.

如何进行UI测试是iOS开发中很常见的问题(我猜测Mac等其他UI驱动的平台也是这样)。很多人完全不做UI测试，问起来他们经常这样说：“你只应该测试你的业务逻辑。”也有一部分人想做UI测试，但是觉得它太复杂于是便放弃了。


Whenever someone tells me UI testing is hard, I think back to something [Landon Fuller](https://twitter.com/landonfuller) said about testing the UI of [Paper (by 53)](https://www.fiftythree.com/paper) during a [panel about testing](http://www.meetup.com/CocoaPods-NYC/events/164278492/) that we were both part of:

每当有人告诉我UI测试很难的时候，我就会回想起在一次[测试小组讨论](http://www.meetup.com/CocoaPods-NYC/events/164278492/)中，[Landon Fuller](https://twitter.com/landonfuller)谈到[Paper (by 53)](https://www.fiftythree.com/paper)项目的UI测试时说的一段话：

> What you see on the screen is the culmination of a variety of data and transforms applied to that data over time ... Being able to decompose those things into testable units means you can break...down \[things\] that are relatively complex into more easily understood elements.

> 你在屏幕上看到的是各种数据和变化综合之后的结果。如果你可以将这些东西分解成可供测试的单元，这就意味着你可以将相对复杂的内容拆解成更容易理解的元素。


Paper’s UI is relatively complex. Testability is usually not something taken into account when building such a UI. However, any action taken by the user is modeled in code somewhere; it’s always possible to fake the user’s action in a test. The problem is that most frameworks, including UIKit, often don’t publicly expose the necessary lower-level constructs.

Paper的UI相对来说算是复杂的了，当构建这样的UI的时候，可测试性一般不会被考虑在内。但是，用户的任何一个行为在代码中都是被建模处理的，在测试中模仿用户的行为是一件很容易的事情。而问题在于大多数框架，包括UIKit，都没有公开的暴露底层的结构。

Knowing what to test is as important as knowing how to test. I've been referring to “UI testing” because that's the accepted term for the type of testing I'm going to discuss. In truth, I think you can split UI testing into two categories: 1) behavior and 2) aesthetics.

知道“测试什么”和知道“如何测试”同等重要。我一直都在提及“UI测试”，因为这是一个被广为接受的概念，我即将深入讨论这类测试。实际上，我觉得你可以把UI测试分成两类：行为 和 美感.

There is no way to deterministically say that aesthetics are correct, as they tend to change very often. You don't want to have to change your tests every time you're tweaking the UI. That's not to say that you can't test the aesthetics at all. I have no experience with it, but verifying aesthetics could be done with snapshots. Read Orta’s article to learn more [about this method]().

我们无法确定的说这种美感是正确的，因为审美这种东西总是在频繁的变化着。你肯定不想每次修改UI都重新进行UI测试。这并不意味着你无法测试美感。我对于这个方面没有任何经验，但是我们可以用截屏的方式检验美感。如果想进一步的了解，可以阅读Orta关于这方面的[文章](http://www.objc.io/issue-15/snapshot-testing.html)。

The remainder of this article will be about testing user behavior. I've provided a project on [GitHub](https://github.com/klaaspieter/objc-io-issue-15-ux-testing) that includes some practical examples. It’s written for iOS using Objective-C, but the underlying principles can be applied to the Mac and other UI frameworks.

在开始之前友情提示各位，这篇文章将会探讨用户行为测试相关的内容。我在Github上提供了一个[项目](https://github.com/klaaspieter/objc-io-issue-15-ux-testing)，里面包含了一些实际的例子，虽然是使用Objective-C编写的iOS项目，但是背后的原理是可以应用于Mac和其他UI框架的。

The number one principle I apply to testing user experience is to make it appear to your code as if the user has triggered the action. This can be tricky because, as said before, frameworks don't always expose all of the necessary lower-level APIs.

在我测试用户行为时的第一条原则是：如果用户触发了某个事件，将它用代码的形式呈现出来。这个可能会有点困难，因为正如前面所说，并不是所有的框架都会公开底层接口。

Projects like [KIF][], [Frank][], and [Calabash][] solve this problem, but at the cost of introducing an additional layer of complexity—and we should always use the simplest possible solution that gets the job done. You want your tests to be deterministic. They need to fail or pass consistently. The worst test suites are those that fail at random. I prefer not to use these solutions because, in my experience, they introduce too much complexity at the cost of reliability and stability.

[KIF]: https://github.com/kif-framework/KIF
[Frank]: http://www.testingwithfrank.com/
[Calabash]: http://calaba.sh/

类似于[KIF](https://github.com/kif-framework/KIF)、[Frank](http://www.testingwithfrank.com/)和[Calabash](http://calaba.sh/)的一类项目解决了这个问题，但是代价就是需要插入一个较为复杂的额外层，而我们应当始终使用最简单的可行方案。一般来说都期望测试的结果是确定的，而结果恰恰相反，使用以上项目需要经历不断的失败和变化。最糟糕的测试方案是那些随机失败的，完全无法重现出错的情景。我不想用这些方案，因为从我的经验来看，它们牺牲了可靠性和稳定性而让项目变得错综复杂。

Note that I've used [Specta][] and [Expecta][] in the example project. Technically, this isn't the simplest possible solution—XCTest is. But there are various reasons why [I prefer them](http://www.annema.me/why-i-prefer-testing-with-specta-expecta-and-ocmockito), and I know from experience that they don't affect the reliability and stability of my test. As a matter of fact, I'd wager that they make my tests better (a safe bet to make, since _better_ is ambiguous).

[Specta]: https://github.com/specta/specta
[Expecta]: https://github.com/specta/expecta

注意到在示例项目中我使用了[Specta](https://github.com/specta/specta)和[Expecta ](https://github.com/specta/expecta)，严格来讲这并不是最简单的解决方案，最简单的解决方案是XCText。但是又有很多原因让我不得不[提及它们](http://www.annema.me/why-i-prefer-testing-with-specta-expecta-and-ocmockito)。并且从我自己的开发经验来看，它们并不会影响测试的可靠性和稳定性。事实上，我敢打赌它们让我的测试更好(一个安全的赌，因为*好*是个模糊的概念的^_^)。

Regardless of your method of testing, when testing user behavior, you want to stay as close to the user as possible. You want to make it appear to your code as if the user is interacting with it. Imagine the user is looking at a view controller, and then taps a button, which presents a new view controller. You'll want your test to present the initial view controller, tap the button, and verify that the new view controller was presented.

不管测试方法是什么，当测试用户行为的时候，我们总是想尽可能接近于用户的真实操作。当用户与应用交互的时候，我们往往希望能够用代码重现出来。想象一下，当用户看着一个ViewController，然后点击了一个按钮，弹出了一个新的ViewController。你应该是希望测试可以展示原始的ViewConnector，并且实现点击按钮操作，然后确保呈现一个新的ViewController。

By focusing on exercising your code as if the user had interacted with your app, you verify multiple things at once. Most importantly, you verify the expected behavior. As a side effect, you're also simultaneously testing that controls are initialized and their actions set.

专注于运用代码模拟用户交互，你每次都需要核实很多东西。最重要的是，你需要核实期望的行为。作为一个副作用，你也同时测试了初始化和他们的行为序列。

For example, consider a test in which an action method is called directly. This unnecessarily couples your test to what the button should do, and not what it will do. If the target or action method for the button is changed, your test will still pass. You want to verify that the button does what you expect. Which action the button uses, and on which target, should not concern your tests.

举个例子，在某个测试中，直接调用了一个行为方法，它把你的测试和按钮将会做的事情连接了起来，而不是它应该做的事，显然这完全是不必要。如果目标或者方法改变了，你的测试依旧可以通过。你希望证实，按钮在按照你的计划行事。而至于按钮调用什么方法，针对什么对象，这都不是在测试中该考虑的内容。

UIKit provides the very useful `sendActionsForControlEvents:` method on `UIControl`, which we can use to fake user events. For example, use it to tap a button:

UIKit在UIControl里提供了非常有用的`sendActionsForControlEvents:`方法，我们可以用来模仿用户操作。比如，用它来点击按钮：

    [_button sendActionsForControlEvent: UIControlEventTouchUpInside];




Similarly, use it to change the selection of a `UISegmentedControl`:

或者简单的调用这个函数来切换UISegmentedControl的选项卡：

    segments.selectedSegmentIndex = 1;
    [segments sendActionsForControlEvent: UIControlEventValueChanged];



Notice that it's not just sending `UIControlValueChanged`. When a user interacts with the control, it will first change its selected index, then send the `UIControlEventValueChanged`. This is a good example of doing some extra work to make it appear to your code as if the user is interacting with the control. 

注意到，并不只是发送了`UIControlValueChanged`这个消息。当一个用户和control交互的时候，它会先改变选中的index值，然后在发送`UIControlValueChanged`消息。这是一个非常好的例子，示范了如何通过代码模拟用户行为。


Not all controls in UIKit have a method equivalent to `sendActionsForControlEvents:`, but with a bit of creativity, it's often possible to find a workaround. As said before, the most important thing is to make it appear to your code as if the user triggered the action.

UIKit中并不是所有的control都有一个等价于`sendActionsForControlEvents`的方法。但是只要有创造力，总能找到变通的方法。正如前面所说，最重要的是告诉代码用户触发了这个事件。

For example, there is no method on `UITableView` to select a cell _and_ have it call its delegate or perform its associated segue. The sample project shows two ways of working around this. 

举个例子，`UITableView`并没有函数用来选中单元格并且让它去调用对应的一系列委托方法。在示例项目中通过两种方式实现了这个功能。

The first method is specific to storyboards: it works by manually triggering the segue you want the table view cell to perform. Unfortunately, this does not verify that the table view cell is associated with that segue:

第一种方法是针对StoryBoard的：需要手动触发你希望单元格调用的segue。不幸的是，并不能确保单元格都是和segue关联的：

    [_tableViewController performSegueWithIdentifier:@"TableViewPushSegue" sender:nil];

Another option that does not require storyboards is to call the `tableView:didSelectRowAtIndexPath:` delegate method manually from your test code. If you're using storyboards, you can still use segues, but you have to trigger them from the delegate method manually:

另一个则不需要StoryBoard的参与，在测试代码里手动调用`tableView:didSelectRowAtIndexPath:`这个委托方法。如果你使用StoryBoard，你可以依旧使用segue，但是你需要从委托方法中手动调用：

    [_viewController.tableView.delegate tableView:_viewController.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    expect(_viewController.navigationController.topViewController).to.beKindOf([PresentedViewController class]);

I prefer the second option. It completely decouples the test from how the view controller is presented. It could be a custom segue, like a `presentViewController:animated:completion`, or some way that Apple hasn't invented yet. Yet all the test cares about is that at the end, the `topViewController` property is what it expects. The best option would be to ask the table view to select a row and perform the associated action, but that's not currently possible.

我更提倡第二种选择，完全将测试从ViewController的呈现方式中解耦。它可以是一个自定义的segue，例如`presentViewController:animated:completion`，或者是其他的一些东西。不过，测试所关心的往往是最后`topViewController`的属性是不是像预期的一样。最好的选择是让TableView自己去选中一行数据并且触发对应的响应事件，不过这显然是不可行的。

As a final example of testing controls, I want to present the special case of `UIBarButtonItem`s. They don't have a `sendActionsForControlEvent:` method because they're not descendents of `UIControl`. Let's figure out how we can send the button action and, to our code, make it look like the user tapped it.

作为测试控制的最后一个示例，我想展示一下UIBarButtonItems的特殊情况。它们没有`sendActionsForControlEvent:`方法，因为它们没有继承自UIControl类。让我们看看对于这样的情况，如何发送按钮事件，以及，对于我们的代码而言，如何让它看起来像是被用户点击了。

A `UIBarButtonItem`, unlike `UIControl`, can only have one target and one action associated with it. Performing the action can be as simple as:
`UIBarButtonItem`并不是UIControl，它只有一个关联关系，那就是target和action。调用这个事件很简单：

    [_viewController.barButton.target  performSelector:_viewController.barButton.action
                                             withObject:_viewController.barButton];

If you're using ARC, the compiler will complain because it can't infer the memory management semantics from an unknown selector. This solution is unacceptable to me because I treat warnings as errors.

如果你使用ARC那么编译器会提议因为它并没有从未知的selector中推断出内存管理含义。这种状况对我而言是不可接受的，因为在我眼里warning就是error。

One option is to use [#pragma directive](http://nshipster.com/pragma/#inhibiting-warnings) to hide the warning. Another alternative is to use the runtime directly:
一个选择是用[#pragma directive](http://nshipster.com/pragma/#inhibiting-warnings)来隐藏warning，另一个选择就是使用直接使用runtime：

    #import <objc/message.h>

    objc_msgSend(_viewController.barButton.target, _viewController.barButton.action, _viewController.barButton);

I prefer the runtime method because I dislike cluttering my test code with pragma directives, and also because it gives me an excuse to use the runtime.

我更喜欢runtime的方式因为我不喜欢我的代码被pragma directives搞得一团糟。而且也因为它给了我一个用runtime的借口。

To be honest, I'm not 100% certain these 'solutions' can't cause issues. This doesn't solve the underlying warning. Tests are usually short lived, so any memory issues that do occur are unlikely to cause problems. It's been working well for me for quite some time, but this is a case I don't fully understand, and it could turn into a bug that randomly fails at some point. I'm interested in [hearing about any potential issues](https://twitter.com/klaaspieter).

说句实话，我并不百分百的确定这些解决方案不会出问题。这并没有解决根本的warning。测试的生命周期往往是短暂的，所以任何在测试操作中发生的内存缺陷都不足以引起内存问题。虽然在我使用的这段时间一直没什么问题，但是其实我对这种情况也不是十分清楚，而且它有可能会随机的在某个问题报出异常。如果有任何建议，欢迎在这里[提出来](https://twitter.com/klaaspieter)。

I want to end with view controllers. View controllers are likely the most important component of any iPhone application. They're the abstraction used to mediate between the view and your business logic. In order to test the behavior as best as possible, we're going to have to present the view controllers. However, presenting view controllers in test cases quickly leads me to conclude they weren't built with testing in mind. 

在文章的最后，我想再说一说ViewController。ViewController可能是iOS应用中最重要的部分，它被抽象出来调节视图和业务逻辑的关系。为了能更好的测试用户行为，我们不得不呈现ViewController。但是，在测试用例中呈现ViewController让我很快得出结论：并不会考虑测试它们。

Presenting and dismissing view controllers is the best way to make sure every test has a consistent start state. Unfortunately, doing so in rapid succession—like a test runner does—will quickly result in error messages like:

显示和隐藏ViewController是确保每个测试都有一个不变的初始状态的最好方式。但是，在连续快速的这样做之后-就像是一个运行的测试案例-很快就会导致下面的错误信息：

- Warning: Attempt to dismiss from view controller \<UINavigationController: 0x109518bd0\> while a presentation or dismiss is in progress!
- Warning: Attempt to present \<PresentedViewController: 0x10940ba30\> on \<UINavigationController: 0x109518bd0\> while a presentation is in progress!
- Unbalanced calls to begin/end appearance transitions for \<UINavigationController: 0x109518bd0\>
- nested push animation can result in corrupted navigation bar

A test suite should be as fast as possible. Waiting for each presentation to finish is not an option. It turns out, the checks raising these warnings are on a per-window basis. Presenting each view controller in its own window gives you a consistent start state for your test, while also keeping it fast. By presenting each in its own window, you never have to wait for a presentation or dismissal to finish.

一套测试应该尽可能的快，最好不要一直等到每一个ViewController的展示结束。结果表明这些warning都是基于单窗口基础的。在独立的窗口展示每一个ViewController可以给你的测试一个始终一致的开始状态，也保证它运行起来足够的快。通过在每个窗口展示页面，你永远不需要等到展示或者消失过程的结束。

There are more issues with view controllers. For example, pushing to a navigation controller happens on the next run loop, while presenting a view controller modally doesn't. If you're interested in trying out this way of testing, I recommend you take a look at my [view controller test helper](https://github.com/klaaspieter/KPAViewControllerTestHelper), which solves these problems for you.

对于ViewController还有一些话题。比如，在下一个循环中push到NavigationController中，而模态化的弹出窗口并不会这样做。如果你想尝试一下这种测试方式，我建议你看一下我的ViewController测试助手，它会帮你解决这个问题。

When testing behavior, often you need to ensure that, through some interaction, a new view controller was presented. In other words, you need to verify the current state of the view controller hierarchy. UIKit does a great job providing the methods needed to verify this. For example, this is how you would make sure that a view controller was modally presented:

当测试行为的时候，你经常需要证实，在某个交互之后，一个新的ViewController可以正常的弹出来。换句话说，你需要证实当前ViewController结构的状态。UIKit在这个方面做的很好，它提供了一系列必要的方法，帮助你完成这个工作。比如下面这个例子，它可以让你确定ViewController有没有正确的模态化弹出：
    expect(_viewController.presentedViewController).to.beKindOf([PresentedViewController class]);

Or pushed to a navigation controller:

或者对于push进navigation控制器也是这样：

    expect(_viewController.navigationController.topViewController).to.beKindOf([PresentedViewController class]);

Testing the UI isn't hard. Just be aware of what you're testing. You want to test user behavior, not application aesthetics. With creativity and persistence, most of the framework shortcomings can be worked around without sacrificing the stability and maintainability of your test suite. Just always remember to write tests to exercise the code as if the user is performing the action.

UI测试其实并不难，只需要清楚你需要测试的内容就行。你需要测试的是用户交互，而不是应用的美观。如果你有足够的创造力和耐力，大多数框架的缺点都是可以通过变通的方法解决的，而不用牺牲系统的稳定性和可维护性。时刻记着，让你的测试尽可能接近用户的真实操作。