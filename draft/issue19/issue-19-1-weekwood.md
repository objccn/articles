Nobody writes perfect code, and debugging is something every one of us should be able to do well. Instead of providing a random list of tips about the topic, I'll walk you through a bug that turned out to be a regression in UIKit, and show you the workflow I used to understand, isolate, and ultimately work around the issue.

没人写的代码是完美的，而调试我们都应该做好的。相对于提供一个关于本话题的随机小建议，我选择带你亲身经历一个 bug 修复的过程，回归到 UIKit 之中， 展示我用来理解，隔离最终解决这个问题的流程。

## The Issue
## 问题

We received a bug report where quickly tapping on a button that presented a popover dismissed the popover but also the *parent* view controller. Thankfully, a sample was included, so the first part — of reproducing the bug — was already taken care of:

我收到了一个 bug 反馈报告，当快速点击一个按钮来弹出一个 popover 并 dismiss popover 同时**父类**视图控制器也会 dismiss。谢天谢地，一个样本已经形成，所以第一步 -- 重现 bug -- 我们已经顾及到：

![](http://img.objccn.io/issue-19/dismiss-issue-animated.gif)

My first guess was that we might have code that dismisses the view controller, and we wrongfully dismiss the parent. However, when using Xcode's integrated view debugging feature, it was clear that there was a global `UIDimmingView` that was the first responder for touch input:

我的第一个猜测是，我们可能包含了 dismiss 视图控制器的代码，我们错误的 dismiss 了他们的父类。然而，当使用 Xcode 集成的试图调试功能，很明显有一个全局 `UIDimmingView` 类来相应点击事件：

![](http://img.objccn.io/issue-19/xcode-view-debugging.png)

Apple added the [Debug View Hierarchy](https://developer.apple.com/library/ios/recipes/xcode_help-debugger/using_view_debugger/using_view_debugger.html) feature in Xcode 6, and it's likely that this move was inspired by the popular [Reveal](http://revealapp.com/) and [Spark Inspector](http://sparkinspector.com/) apps, which, in many ways, are still better and more feature rich than the Xcode feature.

苹果在 Xcode 6 中添加了 [调试视图层次结构](https://developer.apple.com/library/ios/recipes/xcode_help-debugger/using_view_debugger/using_view_debugger.html)，这一举动很可能是收到了非常受欢迎的应用  [Reveal](http://revealapp.com/) 和 [Spark Inspector](http://sparkinspector.com/) 的启发。相对于 Xcode 它们在许多方面表现更好，更多功能。

## Using LLDB
## 使用 LLDB

Before there was visual debugging, the common way to inspect the hierarchy was using `po [[UIWindow keyWindow] recursiveDescription]` in LLDB, which prints out [the whole view hierarchy in text form](https://gist.github.com/steipete/5a3c7a3b6e80d2b50c3b). 

在虚拟调试器之前，最常见的做法是在 LLDB 使用 `po [[UIWindow keyWindow] recursiveDescription]` 来检查层次结构。打印的[完整层次结构](https://gist.github.com/steipete/5a3c7a3b6e80d2b50c3b)。

Similar to inspecting the view hierarchy, we can also inspect the view controller hierarchy using `po [[[UIWindow keyWindow] rootViewController] _printHierarchy]`. This is a [private helper](https://github.com/nst/iOS-Runtime-Headers/blob/a8f9f7eb4882c9dfc87166d876c547b75a24c5bb/Frameworks/UIKit.framework/UIViewController.h#L365) on `UIViewController` that Apple silently added in iOS 8:

类似于检查视图层次，我们也可以用 `po [[[UIWindow keyWindow] rootViewController] _printHierarchy]` 来检查视图控制器。这是一个苹果默默在  iOS 8 中为 `UIViewController` 添加的[私有 helper](https://github.com/nst/iOS-Runtime-Headers/blob/a8f9f7eb4882c9dfc87166d876c547b75a24c5bb/Frameworks/UIKit.framework/UIViewController.h#L365) 。

```
(lldb) po [[[UIWindow keyWindow] rootViewController] _printHierarchy]
<PSPDFNavigationController 0x7d025000>, state: disappeared, view: <UILayoutContainerView 0x7b3218d0> not in the window
   | <PSCatalogViewController 0x7b3100d0>, state: disappeared, view: <UITableView 0x7c878800> not in the window
   + <UINavigationController 0x8012c5d0>, state: appeared, view: <UILayoutContainerView 0x8012b7a0>, presented with: <_UIFullscreenPresentationController 0x80116c00>
   |    | <PSPDFViewController 0x7d05ae00>, state: appeared, view: <PSPDFViewControllerView 0x80129640>
   |    |    | <PSPDFContinuousScrollViewController 0x7defa8e0>, state: appeared, view: <UIView 0x7def1ce0>
   |    + <PSPDFNavigationController 0x7d21a800>, state: appeared, view: <UILayoutContainerView 0x8017b490>, presented with: <UIPopoverPresentationController 0x7f598c60>
   |    |    | <PSPDFContainerViewController 0x8017ac40>, state: appeared, view: <UIView 0x7f5a1380>
   |    |    |    | <PSPDFStampViewController 0x8016b6e0>, state: appeared, view: <UIView 0x7f3dbb90>
```

LLDB is quite powerful and can also be scripted. Facebook released [a collection of python scripts named Chisel](https://github.com/facebook/chisel) that help a lot with daily debugging. `pviews` and `pvc` are the equivalents for view and view controller hierarchy printing. Chisel's view controller tree is similar, but also displays the view rects. I often use it to inspect the [responder chain](https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/event_delivery_responder_chain/event_delivery_responder_chain.html), and while you could manually loop over `nextResponder` on the object you're interested in, or [add a category helper](https://gist.github.com/n-b/5420684), typing `presponder object` is by far the quickest way.

LLDB 非常强大并且可以脚本化。 Facebook 发布了一组名为 [Chisel 的脚本集合](https://github.com/facebook/chisel) 对日常调试提供了非常多的帮助。`pviews` 和 `pvc` 等价于视图和视图控制器的层次打印。Chisel 的视图控制器树也很相似，但是同时也显示了视图的 rect。
我通常用他来检查[响应链](https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/event_delivery_responder_chain/event_delivery_responder_chain.html)，虽然你可以对你感兴趣的对象手动循环执行`nextResponder`，或者[添加一个类别 helper](https://gist.github.com/n-b/5420684)，输入 `presponder object` 是迄今为止最快的方法。

## Adding Breakpoints
## 添加断点

Let's first figure out what code is actually dismissing our view controller. The most obvious action is setting a breakpoint on `viewWillDisappear:` to see the stack trace:

我们首先要找出实际 dismiss 我们视图控制器的代码。最显著的动作是在 `viewWillDisappear:` 设置一个断点来进行堆栈跟踪：

```
(lldb) bt
* thread #1: tid = 0x1039b3, 0x004fab75 PSPDFCatalog`-[PSPDFViewController viewWillDisappear:](self=0x7f354400, _cmd=0x03b817bf, animated='\x01') + 85 at PSPDFViewController.m:359, queue = 'com.apple.main-thread', stop reason = breakpoint 1.1
  * frame #0: 0x004fab75 PSPDFCatalog`-[PSPDFViewController viewWillDisappear:](self=0x7f354400, _cmd=0x03b817bf, animated='\x01') + 85 at PSPDFViewController.m:359
    frame #1: 0x033ac782 UIKit`-[UIViewController _setViewAppearState:isAnimating:] + 706
    frame #2: 0x033acdf4 UIKit`-[UIViewController __viewWillDisappear:] + 106
    frame #3: 0x033d9a62 UIKit`-[UINavigationController viewWillDisappear:] + 115
    frame #4: 0x033ac782 UIKit`-[UIViewController _setViewAppearState:isAnimating:] + 706
    frame #5: 0x033acdf4 UIKit`-[UIViewController __viewWillDisappear:] + 106
    frame #6: 0x033c46a1 UIKit`-[UIViewController(UIContainerViewControllerProtectedMethods) beginAppearanceTransition:animated:] + 200
    frame #7: 0x03380ad8 UIKit`__56-[UIPresentationController runTransitionForCurrentState]_block_invoke + 594
    frame #8: 0x033b47ab UIKit`__40+[UIViewController _scheduleTransition:]_block_invoke + 18
    frame #9: 0x0327a0ce UIKit`___afterCACommitHandler_block_invoke + 15
    frame #10: 0x0327a079 UIKit`_applyBlockToCFArrayCopiedToStack + 415
    frame #11: 0x03279e8e UIKit`_afterCACommitHandler + 545
    frame #12: 0x060669de CoreFoundation`__CFRUNLOOP_IS_CALLING_OUT_TO_AN_OBSERVER_CALLBACK_FUNCTION__ + 30
    frame #20: 0x032508b6 UIKit`UIApplicationMain + 1526
    frame #21: 0x000a119d PSPDFCatalog`main(argc=1, argv=0xbffcd65c) + 141 at main.m:15
(lldb) 
```

With LLDB's `bt` command, you can print the breakpoint. `bt all` will do the same, but it prints the state of all threads, and not just the current one.

利用 LLDB 的 `bt` 命令，你可以打印断点。`bt all` 可以达到一样的效果。但是打印全部线程的状态，而不仅是当前的线程。

Looking at the stack trace, we notice that the view controller is already dismissing, as we're called from a scheduled animation, so we need to add a breakpoint earlier. In this case, we are interested in calls to `-[UIViewController dismissViewControllerAnimated:completion:]`. We add a *symbolic breakpoint* to Xcode's breakpoint list and run the sample again. 

看看这个堆栈，我们注意到视图控制器已经被 dismiss，但我们已经执行了预定的动画，所以我们需要在更早的地方增加断点。在这个例子中，我们兴趣在于调用了 `-[UIViewController dismissViewControllerAnimated:completion:]`。我们添加*符号断点* 到 Xcode 的断点列表，并且重新执行示例代码。

The Xcode breakpoint interface is very powerful, allowing you to add [conditions, skip counts, or even custom actions like playing a sound effect and automatically continuing](http://www.peterfriese.de/debugging-tips-for-ios-developers/). We don't need these features here, but they can save quite a bit of time:

Xcode 的断点界面非常强大，允许你添加[条件，跳过计数，或者自定义动作比如添加音效和自动继续]。这里我们不需要这些特性。但是他们可以节省相当多的时间：

```
(lldb) bt
* thread #1: tid = 0x1039b3, 0x033bb685 UIKit`-[UIViewController dismissViewControllerAnimated:completion:], queue = 'com.apple.main-thread', stop reason = breakpoint 7.1
  * frame #0: 0x033bb685 UIKit`-[UIViewController dismissViewControllerAnimated:completion:]
    frame #1: 0x03a7da2c UIKit`-[UIPopoverPresentationController dimmingViewWasTapped:] + 244
    frame #2: 0x036153ed UIKit`-[UIDimmingView handleSingleTap:] + 118
    frame #3: 0x03691287 UIKit`_UIGestureRecognizerSendActions + 327
    frame #4: 0x0368fb04 UIKit`-[UIGestureRecognizer _updateGestureWithEvent:buttonEvent:] + 561
    frame #5: 0x03691b4d UIKit`-[UIGestureRecognizer _delayedUpdateGesture] + 60
    frame #6: 0x036954ca UIKit`___UIGestureRecognizerUpdate_block_invoke661 + 57
    frame #7: 0x0369538d UIKit`_UIGestureRecognizerRemoveObjectsFromArrayAndApplyBlocks + 317
    frame #8: 0x03689296 UIKit`_UIGestureRecognizerUpdate + 3720
    frame #9: 0x032a226b UIKit`-[UIWindow _sendGesturesForEvent:] + 1356
    frame #10: 0x032a30cf UIKit`-[UIWindow sendEvent:] + 769
    frame #21: 0x032508b6 UIKit`UIApplicationMain + 1526
    frame #22: 0x000a119d PSPDFCatalog`main(argc=1, argv=0xbffcd65c) + 141 at main.m:15
```

Now we're talking! As expected, the fullscreen `UIDimmingView` receives our touch and processes it in `handleSingleTap:`, then forwarding it to `UIPopoverPresentationController`'s `dimmingViewWasTapped:`, which dismisses the controller (as it should). However, when we tap quickly, this breakpoint is called twice. Is there a second dimming view? Is it called on the same instance? We only have the assembly on this breakpoint, so calling `po self` will not work.

现在如我们所说！正如预期的，全屏 `UIDimmingView` 接收到我们的触摸并且在 `handleSingleTap:` 中处理，接着转发到 `UIPopoverPresentationController` 中的 `dimmingViewWasTapped:` 方法来 dismiss 视图控制器（就像它该做的那样），然而。当我们快速点击，断点被调用两次。这里有第二个 dimming 视图？他们调用了相同的实例？我们只有断点时候的程序集，所以调用 `po self` 是无效的。

## Calling Conventions 101
## 调用约定 101

With some basic knowledge of assembly and function-calling conventions, we can still get the value of `self`. The [iOS ABI Function Call Guide](http://developer.apple.com/library/ios/#documentation/Xcode/Conceptual/iPhoneOSABIReference/Introduction/Introduction.html) and the [Mac OS X ABI Function Call Guide](http://developer.apple.com/library/mac/#documentation/DeveloperTools/Conceptual/LowLevelABI/000-Introduction/introduction.html) that is used in the iOS Simulator are both great resources.

根据程序集和 function-calling 约定的一些基本知识，我们依然可以拿到 `self`  的值。[iOS ABI Function Call Guide](http://developer.apple.com/library/ios/#documentation/Xcode/Conceptual/iPhoneOSABIReference/Introduction/Introduction.html) 和 [Mac OS X ABI Function Call Guide](http://developer.apple.com/library/mac/#documentation/DeveloperTools/Conceptual/LowLevelABI/000-Introduction/introduction.html) 都是在 iOS 模拟器中调试极好的资源。

We know that every Objective-C method has two implicit parameters: `self` and `_cmd`. So what we need is the first object on the stack. For the **32-bit** architecture, the stack is saved in `$esp`, so you can use `po *(int*)($esp+4)` to get `self`, and `p (SEL)*(int*)($esp+8)` to get `_cmd` in Objective-C methods. The first value in `$esp` is the return address. Subsequent variables are in `$esp+12`, `$esp+16`, and so on.

我们知道每个 Objective-C 有两个隐式参数： `self` 和 `_cmd`。他们是我们在堆栈上需要的第一个对象。在 **32-bit** 架构中，堆栈信息保存在 `$esp`，所以在 Objective- C 方法中你可以你可以使用 `po *(int*)($esp+4)` 来获取 `self`，以及使用 `p (SEL)*(int*)($esp+8)` 来获取 `_cmd`。`$esp` 的第一个值是返回地址。随后变量保存在 `$esp+12`, `$esp+16`, 等等。

The **x86-64** architecture (iPhone Simulator for devices that have an arm64 chip) offers many more registers, so variables are placed in `$rdi`, `$rsi`, `$rdx`, `$rcx`, `$r8`, `$r9`. All subsequent variables land on the stack in `$rbp`, starting with `$rbp+16`, `$rbp+24`, etc.

**x86-64** 架构 (iPhone 设备模拟器包含 arm64 芯片)提供了更多寄存器，所以变量放置在`$rdi`，`$rsi`， `$rdx`， `$rcx`， `$r8`， `$r9`。所有后续的变量在 `$rbp` 堆栈上。开始于 `$rbp+16`， `$rbp+24` 等。

The **armv7** architecture generally places variables in `$r0`, `$r1`, `$r2`, `$r3`, and then moves the rest on the stack `$sp`:

**armv7** 架构通常放置变量在 `$r0`， `$r1`， `$r2`， `$r3`，接着移动到 `$sp` 堆栈上：

```
(lldb) po $r0
<PSPDFViewController: 0x15a1ca00 document:<PSPDFDocument 0x15616e70 UID:amazondynamososp2007_0c7fb1fc6c0841562b090b94f0c1c890 files:1 pageCount:16 isValid:1> page:0>

(lldb) p (SEL)$r1
(SEL) $1 = "dismissViewControllerAnimated:completion:"
```

**Arm64** is similar to armv7, however, since there are more registers available, the whole range of `$x0` to `$x7` is used to pass over variables, before falling back to the stack register `$sp`.

**Arm64** 类似于 armv7，然而，有了更多的寄存器。整个范围 `$x0` 到 `$x7` 用来存放变量，之后回到堆栈寄存器 `$sp`。

You can learn more about stack layout for [x86](http://eli.thegreenplace.net/2011/02/04/where-the-top-of-the-stack-is-on-x86/) and [x86-64](http://eli.thegreenplace.net/2011/09/06/stack-frame-layout-on-x86-64/), and also by reading the [AMD64 ABI Draft](http://www.x86-64.org/documentation/abi.pdf).

你可以学到更多关于[x86](http://eli.thegreenplace.net/2011/02/04/where-the-top-of-the-stack-is-on-x86/)，[x86-64](http://eli.thegreenplace.net/2011/09/06/stack-frame-layout-on-x86-64/)，以及阅读[AMD64 ABI Draft](http://www.x86-64.org/documentation/abi.pdf)的堆栈布局。

## Using the Runtime
## 使用 Runtime

Another technique to track method execution is overriding the methods with a log statement before calling super. However, manually swizzling just to be able to debug more conveniently isn't really time efficient. A while back, I wrote a small library called [*Aspects*](http://github.com/steipete/Aspects) that does exactly that. It can be used in production code, but I mostly use it for debugging and to write test cases. (If you're curious about Aspects, you can [learn more here.](https://speakerdeck.com/steipete/building-aspects))

跟踪方法执行的另一种做法是在调用超类之前重写方法并加入日志。然而，手动 swizzling 调试起来更加方便但是效率不高。言到于此，我写了一个很小库叫做 [*Aspects*](http://github.com/steipete/Aspects) 确实做到了这件事。它可以用于生产模式代码，但是我大部分时候用于调试和写测试用例。（如果你好奇 Aspects，你可以[在这里了解更多相关知识。](https://speakerdeck.com/steipete/building-aspects))

```objc
#import "Aspects.h"

[UIPopoverPresentationController aspect_hookSelector:NSSelectorFromString(@"dimmingViewWasTapped:") 
                                         withOptions:0 
                                          usingBlock:^(id <AspectInfo> info, UIView *tappedView) {
    NSLog(@"%@ dimmingViewWasTapped:%@", info.instance, tappedView);
} error:NULL];
```

This hooks into `dimmingViewWasTapped:`, which is private — thus we use `NSSelectorFromString`. You can verify that this method exists, and also look up all other private and public methods of pretty much every framework class, by using the [iOS Runtime Headers](https://github.com/nst/iOS-Runtime-Headers). This project uses the fact that one can't really hide methods at runtime to query all classes and create a more complete header than what Apple gives us. (Of course, actually calling a private API is not a good idea — this is just to better understand what's going on.)

为 `dimmingViewWasTapped:` 添加钩子，他是私有方法 — 我们使用 `NSSelectorFromString`。你需要验证方法是否存在，并通过使用 [iOS Runtime Headers](https://github.com/nst/iOS-Runtime-Headers) 查找每个框架类的其他私有方法和公共方法。本项目采用的方式不是在运行时隐藏所有类，而创建一个比苹果给我们更完整的头文件。（当然，调用私有 API 并不是一个好主意 — 这里只是用来便于理解事情如何发生）

With the log message in the hooked method, we get the following output:

在钩子方法的日志中，我们获得如下输出：

```
PSPDFCatalog[84049:1079574] <UIPopoverPresentationController: 0x7fd09f91c530> dimmingViewWasTapped:<UIDimmingView: 0x7fd09f92f800; frame = (0 0; 768 1024)>
PSPDFCatalog[84049:1079574] <UIPopoverPresentationController: 0x7fd09f91c530> dimmingViewWasTapped:<UIDimmingView: 0x7fd09f92f800; frame = (0 0; 768 1024)>
```

We see that the object address is the same, so our poor dimming view really is called twice. We can use Aspects again to see on which controller the dismiss is actually called:

我们看到对象地址完全相同，所以我们的 dimming 视图真的被调用了两次，我们可以使用 Aspects 来查看具体哪个控制器 dismiss 方法被调用：

```objc
[UIViewController aspect_hookSelector:@selector(dismissViewControllerAnimated:completion:)
                          withOptions:0
                           usingBlock:^(id <AspectInfo> info) {
    NSLog(@"%@ dismissed.", info.instance);
} error:NULL];
```

```
2014-11-22 19:24:51.900 PSPDFCatalog[84210:1084883] <UINavigationController: 0x7fd673789da0> dismissed.
2014-11-22 19:24:52.209 PSPDFCatalog[84210:1084883] <UINavigationController: 0x7fd673789da0> dismissed.
```

Both times, the dimming view calls dismiss on our main navigation controller. UIViewControllers's `dismissViewControllerAnimated:completion:` will forward the view controller dismissal request to its immediate child controller, if there is one, otherwise it will dismiss itself. So the first time, the dismiss request goes to the popover, and the second time, the navigation controller itself gets dismissed.

同一时间，dimming 视图调用主导航控制器的 dismiss 方法。视图控制器的 `dismissViewControllerAnimated:completion:` 会转发视图控制器的 dismiss 请求到它的子视图控制器，如果只有一个将 dismiss。所以第一次 dismiss 请求执行于 popover，第二次，导航控制器本身被 dismiss。

## Finding a Workaround
## 查找解决方案

We now know what is happening — so let's move to the *why*. UIKit is closed source, but we can use a disassembler like [Hopper](http://www.hopperapp.com/) to read the UIKit assembly and take a closer look what's going on in `UIPopoverPresentationController`. You'll find the binary under `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/UIKit.framework`. Use File -> Read Executable to Disassemble... and select this in Hopper, and watch how it crawls through the binary and symbolicates code. The 32-bit disassembler is the most mature one, so you'll get the best results selecting the 32-bit file slice. [IDA by Hex-Rays](https://www.hex-rays.com/products/ida/) is another very powerful and expensive disassembler, which often provides [even better results](https://twitter.com/steipete/status/537565877332639744):

现在我们知道发生了什么事情 — 所以我们可以进入*为何发生* 环节。UIKit 是闭源代码，但是我们使用反汇编就像 [Hopper](http://www.hopperapp.com/) 来解读 UIKit 程序集并且仔细看看 `UIPopoverPresentationController` 发生了什么事情。你可以找到二进制文件 `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/UIKit.framework`。使用 File -> Read Executable to Disassemble... 然后使用 Hopper，看他如何遍历二进制并且 symbolicates 代码。 32-bit  反汇编是最成熟的一个。所以你选择 32-bit 文件可以拿到最好的结果。[IDA by Hex-Rays](https://www.hex-rays.com/products/ida/) 是另一个很强大很昂贵的反汇编程序，通常提供[更好的结果](https://twitter.com/steipete/status/537565877332639744):

![](http://img.objccn.io/issue-19/hopper-dimmingView.png)

Some basics in assembly are quite useful when reading through the code. However, you can also use the pseudo-code view to get something more C-like:

程序集的一些基本阅读代码时非常有用。然而，你也可以使用伪代码视图来得到比 C-like 更多的东西:

![](http://img.objccn.io/issue-19/pseudo-code.png)

Reading the pseudo-code is quite eye-opening. There are two code paths — one if the delegate implements `popoverPresentationControllerShouldDismissPopover:`, and one if it doesn't — and the code paths are actually quite different. While the one reacting to the delegate basically has an `if (controller.presented && !controller.dismissing)`, the other code path (that we currently fall into) doesn't, and always dismisses. With that inside knowledge, we can attempt to work around this bug by implementing our own `UIPopoverPresentationControllerDelegate`:

阅读伪代码结果是令人膛目的。有两个代码路径 — 其中一个是代理方法实现`popoverPresentationControllerShouldDismissPopover:`，如果不进入 — 代码路径实际上相当不同。而一个反应基本代表代理方法包含 `if (controller.presented && !controller.dismissing)`，另一个代码路径（我们实际进入），总是被 dismiss。通过内部信息，我们可以尝试通过实现我们自己的 `UIPopoverPresentationControllerDelegate` 来解决这个 bug：

```
- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    return YES;
}
```

My first attempt was to set this to the main view controller that creates the popover. However, that broke `UIPopoverController`. While not documented, the popover controller sets itself as the delegate in `_setupPresentationController`, and taking the delegate away will break things. Instead, I used a `UIPopoverController` subclass and added the above method directly. The connection between these two classes is not documented, and our fix relies on this undocumented behavior; however, the implementation matches the default and exists purely to work around this issue, so it's future-proof code.

我的第一次尝试是设置的主要视图控制器创建 popover。然而它破坏了  `UIPopoverController` 。没有文档化，popover 控制器在 `_setupPresentationController` 中设置代理，并且拿走委托将打破东西。相反，我使用 `UIPopoverController` 子类来直接添加上面的方法。这两个类之间的联系没有文档化，和我们确定依赖于这种非法行为；然而，实现匹配存在违约，纯粹为了解决这个问题，所以它是不会过时的代码。

## Reporting a Radar
## 反馈 Radar

Now please don't stop here. You should always properly document such workarounds, and most importantly, file a radar with Apple. As an additional benefit, this allows you to verify that you actually understood the bug, and that no other side effects from your application play a role — and if you drop an iOS version, it's easy to go back and test if the radar is still valid:

现在请不要停下。我们通常需要使用文档内的方法来解决问题，相当重要的是，写一个bug report 给 Apple，额外的好处是，这样你能够真正理解错误，并且在你的程序中没有其他副作用 — 如果你下降一个 iOS 版本，很容易测试 radar 是否有效。

```
// The UIPopoverController is the default delegate for the UIPopoverPresentationController
// of it's contentViewController.
//
// There is a bug when someone double-taps on the dimming view, the presentation controller invokes
// dismissViewControllerAnimated:completion: twice, thus also potentially dismissing the parent controller.
//
// Simply implementing this delegate runs a different code path that properly checks for dismissing.
// rdar://problem/19053416
// The UIPopoverController 是默认的 UIPopoverPresentationController
// 的 contentViewController 委托方法.
//
// 这里有一个 bug 当双击 diming 视图，调用 preset 视图控制器
// dismissViewControllerAnimated:completion: 将执行两次，并 dismiss 父类控制器.
//
// 简单实现委托方法执行在不同的路径下将正确检查 dismiss 是否调用.
// rdar://problem/19053416
- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    return YES;
}
```

Writing radars is actually quite a fun challenge, and doesn't take as much time as you might think. With an example, you'll help out some overworked Apple engineer, and without it, the engineers will most likely push back and not even consider the radar. I managed to create a sample in about 50 LOC, including some comments and the workaround. The Single View Template is usually the quickest way to create an example.

写一个 Radar 实际上是非常有趣的挑战，不像你想象的那么多时间。用一个示例，您将帮助一些劳累苹果工程师，没有它，工程师将最有可能推迟，甚至不考虑 radar。我设法创建一个示例在大约 50 LOC，包括一些意见和解决方案。一个视图模板通常是最快创建一个示例的方式。

Now, we all know that Apple's RadarWeb application isn't great, however, you don't have to use it. [QuickRadar](http://www.quickradar.com/) is a great Mac front-end that can submit the radar for you, and also automatically sends a copy to [OpenRadar](http://openradar.appspot.com). Furthermore, it makes duping radars extremely convenient. You should download it right away and dupe rdar://19053416 if you feel like this bug should be fixed.

现在，我们知道了苹果的RadarWeb 并没有想象的那么好，然而你可以不使用它。[QuickRadar](http://www.quickradar.com/) 是一个有非常优秀 Mac 前端来提交 radar，同时提交一个副本到 [OpenRadar](http://openradar.appspot.com)。此外，给 rader 投票极其方便。你应该马上下载它，并投票给 rdar://19053416 如果你觉得这样的错误值得被修复。

Not every issue can be solved with such a simple workaround, however, many of these steps will help you find better solutions to issues, or at least improve your understanding of why something is happening. 

并不是所有问题都可以用一些简单的解决方案，然这些步骤将帮助您找到更好的解决问题，或者至少帮助你的理解为什么事情会发生。

## References
## 参考

*  [iOS Debugging Magic (TN2239)](https://developer.apple.com/library/ios/technotes/tn2239/_index.html)
*  [iOS Runtime Headers](https://github.com/nst/iOS-Runtime-Headers)
*  [Debugging Tips for iOS Developers](http://www.peterfriese.de/debugging-tips-for-ios-developers/)
*  [Hopper — a reverse engineering tool](http://www.hopperapp.com/)
*  [IDA by Hex-Rays](https://www.hex-rays.com/products/ida/)
*  [Aspects — Delightful, simple library for aspect-oriented programming.](http://github.com/steipete/Aspects)
*  [Building Aspects](https://speakerdeck.com/steipete/building-aspects)
*  [Event Delivery: The Responder Chain](https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/event_delivery_responder_chain/event_delivery_responder_chain.html)
*  [Chisel — a collection of LLDB commands to assist debugging iOS apps](https://github.com/facebook/chisel)
*  [Where the top of the stack is on x86](http://eli.thegreenplace.net/2011/02/04/where-the-top-of-the-stack-is-on-x86/)
*  [Stack frame layout on x86-64](http://eli.thegreenplace.net/2011/09/06/stack-frame-layout-on-x86-64)
*  [AMD64 ABI draft](http://www.x86-64.org/documentation/abi.pdf)
*  [ARM 64-bit Architecture](http://infocenter.arm.com/help/topic/com.arm.doc.ihi0055b/IHI0055B_aapcs64.pdf)
*  [Decompiling assembly: IDA vs Hopper](https://twitter.com/steipete/status/537565877332639744)
