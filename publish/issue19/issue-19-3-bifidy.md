寻找 bug 非常耗费时间；几乎每一个有经验的开发者，都曾在某一个 bug 上花费过很多天。在一个平台上开发的时间越久，就会越容易找到 bug。然而，总有一些 bug 是难以找到与复现的。在最开始的时候，找到一种途径去复现 bug 总是很有用的。一旦你找到了某种途径，可以持续的复现 bug ，你就可以开始下一步工作，找到 bug。

这篇文章试图阐释的是我们在调试中经常遇到的一些相对常见的问题。当你遇到了一个 bug 时，你可以把本文当做一份核对清单。通过核对这份清单列出的一些问题，可能会使你更快的找到这个 bug。更理想的情况下，这里提到的一些技巧可以帮助我们在第一时间避免这些 bug 出现。

我们会从一系列引起 bug 的原因开始讲起，其中一大部分 bug 对大家都已经不算陌生。

## 回调是否在正确的线程进行？

一个引发意外行为的原因，是有些东西运行在错误的线程上。举个例子，当你在非主线程的其它线程上更新 UIKit 的对象时，事情会变的很糟糕。有的时候，更新会正常运转，但大多数情况下，发生的情况都很怪异，甚至会引起崩溃。在你的代码中，利用断言来检查你是否在主线程中的做法可以缓和这种情况。通常来说，可能（意外地）发生在后台线程中的回调，可以来自网络请求，计时器，文件读取，或者是外部库。

另一个解决方法是划分出一个线程独立的区域。举个例子，如果你正在构建一个基于网络 API 的封装，你可以把所有的线程都封装在那里进行处理。在后台线程中执行所有的网络请求，但把它们的回调全部转移到主线程中。如此一来，你就再也不必担心调用代码中会出现什么问题。一个简单的设计在开发中真的很有用。

## 这个对象的类是否正确？

这个问题基本上只存在于 Objective-C；在 Swift 中，有一个强壮的类型系统，可以精确的保证对象或值的类型安全。而在 Objective-C 中，偶然把对象的类型弄错是很常见的。

例如，在 [Deckset](http://www.decksetapp.com)中，我们加入了一个与字体相关的新特性。其中，有一个对象的某个数组属性命名为 `fonts`，然后我假定这个数组中的对象类型都为 `NSFont`。可事实证明，数组里其实包含的是 `NSString` 类型的对象（字体名）。我花费了一些时间才找到了原因，这是因为，在大多数部分情况下，程序是正常工作的。在 Objective-C 中，一种检查类型问题的方法是利用断言。另一种可以帮到自己的方法，是在命名时添加类型信息（如：这个数组可以命名为 `fontNames`）。在 Swift 中，确定类型就可以避免这些错误（如：使用 `[NSFont]` 而非 `[AnyObject]`）。 

当不确定一个对象的类型是否正确时，你可以在调试器中将类型打印出来。另外，使用 `isKindOfClass:`的断言去检查一个对象的类是否正确也很实用。在 Swift 中，因为可选值的存在，你还可以使用关键字 `as?` 在任何需要的地方去做类型适配， 这比直接用 `as` 做强制转换好用的多。以上的方法会让你大大减少错误的概率。

## 具体的 Build 设置

另一个常见的原因，是 build 设置中不同的配置间有一些不易被发现的出入。比如，有时编译器译器会做一些优化，这使在调试中根本不会出现的 bug 却在产品发布版本中的存在。这个情况相对来说并不常见，不过在当前的 Swift 发布版中，就有报告表明类似问题的存在。

还有一种原因，是某个确定的变量或宏定义被不同的方式定义。比如，一些代码可能会在开发中被注释起来。我们在一个实例中写了一些错误的（足以引发崩溃的）用户行为统计代码，但在开发中我们关掉了统计，所以我们在开发 app 时永远看不到这些崩溃。

这几种 bug 在开发中是很难被发现的。所以，一定要详细且彻底的测试你的发布版 app。当然，如果有其他人（比如 QA 组）可以测试它再好不过。

## 不同的设备

不同的设备，可用性会有所不同。如果你只在有限数量的设备上进行测试，未覆盖到的设备就会成为可能的 bug 原因之一。经典的剧情 是只在模拟中测试而从未使用真机。不过即便你在真机上做了测试，你也需要考虑到不同的设备与可用性。比如，在处理内置摄像头时，总是使用类似 `isSourceTypeAvailable:` 这样的方法来检测你是否可以使用某个输入源。在你的设备上或许有可以工作的摄像头，但是在用户的设备上却并不总是存在。（译者注：比如坑爹的老版本 iPod Touch 5 16G 版就没有后置摄像头）

## 可变性

可变性也是一个很常见的难以追踪的原因。比如，如果你在两个线程中共享了一个对象，且它们同时修改了该对象，就可能出现很意外的情况。这类 bug 的痛点在于它们很难复现。

有一种解决方法是创建不可变对象。这样，当你访问对象时，你就知道这个操作是无法改变它的状态的。关于这点有太多可讲，不过更多的信息，我们建议你阅读以下文章：[结构体和值类型][issue-16-2]，[值对象][issue-7-2]，[对象的可变性](https://developer.apple.com/library/mac/documentation/General/Conceptual/CocoaEncyclopedia/ObjectMutability/ObjectMutability.html)和[关于可变性](http://www.bignerdranch.com/blog/about-mutability/)。

## 是否为空 (nil)

作为 Objective-C 的编程者，我们有时会因为 `NullPointerException` 取笑 JAVA 程序员。在很多情况下，我们可以安全的发送消息给 nil 不出现什么问题。不过，也有一些棘手的 bug 可能因此出现。如果你写 Swift 代替 Objective-C，你可以安全的跳过这节内容的大部分，因为 Swift 的可选值足以解决这其中大部分的问题。

### 你是否以 `nil` 做为参数调用了函数？

这个原因挺常见。一些方法会因为你传入了 `nil` 参数而崩溃。举例，考虑以下片段：

```
NSString *name = @"";
NSAttributedString *string = [[NSAttributedString alloc] initWithString:name];
```

如果 `name` 是 nil，这段代码将崩溃。复杂的地方在于当这可能是一个你没有发现的边界用例（如 `myObject` 在大多数情况下是不可能为 nil 的）。当写你自己的方法时，你可以添加一个自定义标记，用来通知编译器你是否允许 nil 参数：

```
- (void)doSomethingWithRequiredString:(NSString *)requiredString
                                  bar:(NSString *)optionalString
        __attribute((nonnull(1)));
```

（来自：[StackOverflow](http://stackoverflow.com/a/19186298))

在添加这个标记之后，当你尝试传入一个 nil 参数时，会出现一个编译器警告 。这挺好，因为你再也不用考虑这个边界用例：你可以利用编译器提供的功能替你做这样的检查。

另一种可行的方法是倒置信息流。比如，你可以创建一个自定义分类，比如在 `NSString` 添加一个 `attributedString` 的实例方法 ：

```
@implementation NSString (Attributes)

- (NSAttributedString*)attributedString {
    return [[NSAttributedString alloc] initWithString:self];
}

@end
```

这段代码的好处是你现在可以安全的构造一个 `attributedString`。你可以写 `[@"John" attributedString]`，但你也可以将这个消息发送给 nil（`[nil attributedString]`），这样做并不会崩溃，而是得到一个 nil 的结果。想看到关于这点的更多信息，请查阅 Graham Lee 的文章[反转信息流](http://www.sicpers.info/2014/10/reversing-the-polarity-of-the-message-flow/)。

如果你想捕捉到更多必须成立的条件（如一个参数必须为某个确定的类），你也可以使用 [`NSParameterAssert`](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Functions/#//apple_ref/c/macro/NSParameterAssert)。

### 你是否确定你可以向 `nil` 发送消息？

这其实不是一个太常见的原因，但是它却在一个真实的 app 中出现过。有时，当我们处理标量时，发送一个消息给 nil 可能产生意外的结果。来看看下面这段看起来没什么问题的代码片段：

```
NSString *greeting = @"Hello objc.io";
NSRange range = [greeting rangeOfString:@"objc.io"];
if (range.location != NSNotFound) {
  NSLog(@"Found the keyword!");
}
```

如果 `greeting` 包含了字符串 `"objc.io"`，消息会被打印。如果 `greeting` 不包含这个字符串，则不会有消息被打印。不过，当 `greeting` 为 nil 时会发生什么呢？`range` 会变成一个值全部为0的结构体，而 `location` 会变成0。因为 `NSNotFound` 被定义为`-1`，所以之后的消息会被打印出来。所以，任何时候，当你处理纯值和 `nil`时，要确保考虑了更多情况。同样的，Swift 可以使用可选值避免这个问题。

## 是不是类中的有什么东西没有初始化？

有时，当代码运行到某个对象相关的部分时，可能因为调用了一个未完全初始化的对象而被中断。因为在 `init` 中加入一些额外的代码并不常见，所以，有时在你使用某个对象之前，你需要提前调用这个对象的一些方法。如果你忘记了调用这些方法，这个类就可能因为无法完全的初始化而出现一些奇怪的情况。所以，一定要确保在指定的初始化方法运行之后，类已经处于可用状态。如果你确实需要指定的带参数的初始化方法被运行，同时又无法构建出一个只使用 `init` 方法的就能完成初始化的类的话，你也可以选择重载 `init` 来让它崩溃。不过，当你之后偶尔不小心用到 `init` 来实例化对象的时候，你可能会浪费一点时间来进行修改。

## KVO

一个常见的原因是错误的使用 KVO。坏消息是，犯错误并不难，但好消息是，有一系列方法去避免。

### 你是否清除了你的观察者？

一个简单的错误是添加观察者对象，但不清除它们。在这种情况下，KVO 将持续的发送消息，但接收者可能已经被释放了，于是引发了崩溃。绕开它的一种方法是使用成熟的框架如 [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa)，还有一些轻量级的库用起来也不错。

还有一种方法是，无论你何时创建了一个新观察者，立刻在 dealloc 里写一个移除。然而，这个过程可以自动执行：比直接添加观察者更好的办法是，你可以创建一个自定义对象来让它帮你进行添加。这个对象负责添加观察者并在它自己的 dealloc 里移除它。这样做的优势是你的观察者的生命周期会和这个对象的生命周期一样。这意味着创建这个对象等价于添加了一个观察者。然后你可以将它存为一个属性，当容器对象被析构，属性会自动被设置为 nil，然后移除观察者。

有一点相对详细的关于这种技术的解释，包括一段简单的代码，可以在[这里](http://chris.eidhof.nl/posts/lightweight-key-value-observing.html)被找到。一个小巧的库可以实现这个功能，那就是 [THObserversAndBinders](https://github.com/th-in-gs/THObserversAndBinders)，或者你可以看看 Facebook 的 [KVOController](https://github.com/facebook/KVOController)。

另一个关于 KVO 的问题是回调可能会从你预料之外的线程上返回 (就像我们在开头线程部分描述的那样)。同样的方案，使用一个对象来解决这个问题 (如以上所说)，你可以确保所有的回调会在一个确定的线程上返回。

### 依赖键（Dependent Key）的路径

如果你观察的属性基于于另一个属性，你需要确保你[注册了依赖键](https://developer.apple.com/library/ios/DOCUMENTATION/Cocoa/Conceptual/KeyValueObserving/Articles/KVODependentKeys.html)。否则，当你的属性变化时，你可能不会得到回调。不久之前，我在我的依赖键声明里创建了一个递归依赖 (属性依赖于自己)，然后奇怪的事情就发生了。

## 视图

### Outlet 和 Action

在使用 Interface Builder 时有一个常见的错误，那就是忘记了连接 outlet 和 action。现在它们通常会被标记在代码旁 (你可以在 outlet 和 action 旁边看到小的圆圈)。当然，想测试是否所有连接都和预想的一样的话，可以通过添加单元测试来达到目的 (但是这可能会变成很严重的维护负担)。

另外，为了确保无论这种情况在何时发生，你都能尽快发现，你也可以使用断言。比如用 [`NSAssert`](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Functions/#//apple_ref/c/macro/NSAssert) 去验证你的 outlet 不是 nil。

### 未释放的对象

当你使用了 Interface Builder，你需要确保从一个 nib 文件中载入的对象图不会被释放。有一些[苹果关于处理这个问题的要点](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/LoadingResources/CocoaNibs/CocoaNibs.html#//apple_ref/doc/uid/10000051i-CH4-SW6)。最好读读这篇文章且遵从那些建议，要么你的对象可能在你眼皮底下消失，或者过度持有。在简单的 XIB 文件和 Storyboard  中也有一些不同，请确保你已经倒背如流。

### 视图的生命周期

当处理视图的时候，有很多可能的 bug 会出现。一个常见的错误是在视图还没有初始化的时候就使用它们。或者，你可能在一个视图只是初始化，却还没有设置尺寸时使用就使用它们。这里的关键是在[视图生命周期](http://developer.apple.com/library/ios/#documentation/uikit/reference/UIViewController_Class/Reference/Reference.html#//apple_ref/doc/uid/TP40006926-CH3-SW58)中，找到合适的节点去安排代码。花时间去深入理解它们是如何工作，相对于以后调试的时间来说，绝对是稳赚不赔的。

当你往 iPad 上 移植一个已有的 app 时，这有时也是一个常见的 bug 原因。与此前不曾遇到的情况不同，你现在可能需要担心一个视图控制器是否是一个子视图控制器，它们如何响应旋转事件，还有一些细微区别。针对这种情况，自动布局可能会有一些帮助，它可以自动响应很多类似的变化。

一个常见的错误是我们总是创建一个视图，添加一些约束，然后将它添加进父视图里。不过，为了让大部分约束能够工作，这个视图是需要添加在父视图的视图层级中的。勉强算作好消息的是，大部分情况下这会直接让你的代码崩溃，然后你可以很快的找到 bug。

## 最后

但愿以上的技术会帮助你摆脱 bug 或者完全的避免它们。还有一些自动的帮助是可用的：在 Clang 设置中打开所有的警告消息，这可以向你展示很多可能的 bug。另外，使用静态分析肯定能找到一些 bug (当然你得定期的运行它)。

[issue-7-2]:http:/objccn.io/issue-7-2

[issue-16-2]:http://objccn.io/issue-16-2

---

 

原文 [Debugging Checklist](http://www.objc.io/issue-19/debugging-checklist.html)
