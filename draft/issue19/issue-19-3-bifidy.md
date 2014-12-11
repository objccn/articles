Finding bugs can be very time-consuming; almost every experienced developer can
relate to having spent days on a single bug. As you become more experienced on a
platform, it becomes easier to find bugs. However, some bugs will always be
hard to find or reproduce. As a first step, it is always useful to find a way
to reproduce the bug. Once you have a way to reproduce it consistently, you can
get to the next stage: finding the bug.

寻找 bug 非常耗费时间；几乎每一个有经验的开发者都可以讲出一个花费了自己许多天的 bug 。在一个平台上开发的时间越久，就越容易找到 bug。当然，总有一些 bug 是难以找到与复现的。在第一阶段，找到一个方法去复现 bug 总是很有用的。一旦你找到了复现的方法 始终，你就可以进入下一步，找到 bug。



This article tries to sketch a number of common problems that we usually run into when
debugging. You could use this as a checklist when you encounter a bug, and
maybe by checking some of these things, you'll find that bug way sooner.
And hopefully, some of the techniques help to prevent the bugs in the first place.

这篇文章试图描绘一系列常见问题 我们常常在调试中 经历。你可以把它们当做一个核对清单 当你 遇到了一个 bug，而当你核对列表中的其中一部分时，你可能会更快的发现这个 bug。值得庆幸的是，一些技术可以帮助我们在第一时间阻止 bug。

We'll start off with a couple of very common sources of bugs that happen to us a lot.

我们将从一系列常见的 bug 的源头 很多 发生在我们身上。

## Are Your Callbacks on the Right Thread?

## 你是否在正确的线程中进行回调呢？

One source of unexpected behavior is when things are happening on the wrong thread. For example, when you update UIKit objects from any other thread than the main thread, things could break. Sometimes updating works, but mostly you will get strange behavior, or even crashes. One thing you can do to mitigate this is having assertions in your code that check whether or not you're on the main thread. Common callbacks that might (unexpectedly) happen on a background thread could be coming from network calls, timers, file reading, or external libraries.

一个源头不希望的行为 是 当 事情正在发生 在错误的线程上。举个例子，当你更新 UIKit 的对象优先在其它线程 主线程，它就会搞破坏。有时更新会工作，但更多的情况是你会得到奇怪的行为，甚至崩溃。一件事你可以做去缓和这个是利用断言 在你的代码中 它可以检查 是否你在主线程中。通常回调可能（不被欢迎的）发生在一个后台线程 比如来自一个网络请求，计时器，文件阅读器，或额外的库。

Another solution is to keep the places where threading happens very isolated. As an example, if you are building a wrapper around an API on the network, you could handle all threading in that wrapper. All network calls will happen on a background thread, but all callbacks could happen on the main thread, so that you'll never have to worry about that occurring in the calling code. Having a simple design really helps.

另一个解决方法是保持一个地方 哪里 线程 发生 独立。 举个例子，如果你正建立一个封装 基于 网络 API，你可以把所有线程都封装在那里处理。所有的网络请求会发生在后台线程，但是所有的回调会发生在主线程，所以你再也不会得到一个错误 存在于调用代码中。有一个简单的设计很实用。

## Is This Object Really the Right Class?

## 这个对象的类是否正确？

This is mostly an Objective-C problem; in Swift, there's a stronger type system with more precise guarantees about the type of an object or value. However, in Objective-C, it's fairly common to accidentally have objects of the wrong class.

这大多是 Objective-C 的问题；在 Swift 中，有强制类型系统 与 更精确的保证关于一个对象或者值的类型。然而，在 Objective=C 中，这常见 偶然的 有错误类的对象。

For example, in [Deckset](http://www.decksetapp.com), we were adding a new feature that had to do with fonts. One of the objects had a `fonts` array property, and I assumed the objects in the array were of type `NSFont`. As it turned out, the array contained `NSString` objects (the font names). It took quite a while to figure this out, because, for the most part, things worked as expected. In Objective-C, one way to check this is by having assertions. Another way to help yourself is to encode type information in the name (e.g. this array could have been named `fontNames`). In Swift, these errors can be prevented by having precise types (e.g. `[NSFont]` rather than `[AnyObject]`).

举个例子，在 [Deckset][Deckset]，我们加入了一个新的特性 不得不做与字体。一个类有一个 `fonts` 的数组属性，而且我 假设 数组中的对象类型为 `NSFont`。当它 穿戴好，数组包含 `NSString` 对象（字体名）。需要花费一点时间去弄明白，因为，在大多数部分，事情会按照预计的情况工作。在 Objective-C 中，一种方法去检查是利用断言。另一种方法去帮助你自己是 在命名时假如类型信息（如这个数组可以命名为 `fontNames`）。在 Swift 中，这些错误可以因为明确类型而避免（如使用 `[NSFont]` 而非 `[AnyObject]`）。 

When unsure about whether the object is of the right type, you can always print it in the debugger. It is also useful to have assertions that check whether or not an object is the right class using `isKindOfClass:`. In Swift, rather than force casting with the `as` keyword, rely on having optionals and use `as?` to typecast whenever you need to. This will let you minimize the chances of errors.

当不确定一个对象是否是正确的类型，你可以打印它的类型 在 调试中。断言也是一种很有用 的方法，去检查 是否 一个对象的类是否正确 使用 `isKindOfClass:`。在 Swift 中，比利用 关键字 `as` force casting 更好的办法，可以靠 使用一个可选值 使用 `as?`做类型适配 当你需要的时候。这可以使你 大大减少出错的概率。

## Build-Specific Settings

## 某个 Build 设置


Another common source of bugs that are hard to find is when there are settings that differ between builds. For example, sometimes optimizations that happen in the compiler could cause bugs in production builds that never show up during debugging. This is relatively uncommon, although there are reports of this happening with the the current Swift releases.

另一个常见的原因是 他们难以发现 当 build 中的设置有区别。比如，有时 编译器的优化 可以 使 production build 中的 bug 根本不会出现在调试时。这个情况相对来说并不常见，不过 有 报告出现在当前的Swift发布版中。

Another source of bugs is where certain variables or macros are defined differently. For example, some code might be commented out during development. We had an instance where we were writing incorrect (crashing) analytics code, but during development we turned off analytics, so we never saw these crashes when developing the app. 

还有一个bug的原因是 某个确定的变量或宏定义被重新定义。举例，一些代码可能会在开发中注释出来。我们一个实例 我们写在 错误的（引发崩溃的）analytics 代码，但在开发中我们关掉了 analytics，所以我们不会看到这些崩溃当我们开发 app 时。

These kinds of bugs can be hard to detect during development. As such, you should always thoroughly test the release build of your app. Of course, it's even better if someone else (e.g. a QA department) can test it.

这几种 bug 会难以在开发中被发现。所以，你应该总是彻底的测试 在 发布版 你的 app。当然，如果有其他人（比如 QA 组）可以测试它再好不过。

## Different Devices

## 不同的设备

Meanwhile, there are many different devices with different capabilities. If you have only tested on a limited number of devices, this is a potential cause of bugs. The classic scenario is just testing on the simulator without having the real device. But even when you do test with a real device, you need to account for different capabilities. For example, when dealing with the built-in camera, always use methods like `isSourceTypeAvailable:` to check whether you can use a specific input source. You might have a working camera on your device, but it might not be available on the user's device. 

不同的设备，性能会有所不同。如果你只在有限数量的设备上进行测试，未覆盖到的设备就会成为可能的 bug 原因之一。经典的剧情 是只在模拟其中测试而从未使用真机。不过即便你在真机上做了测试，你需要考虑到不同的设备与性能。比如，当处理内置摄像头时，总是使用类似 `isSourceTypeAvailable:`这样的方法来检测你是否可以使用某个输入源。在你的设备上或许有一个可以工作的摄像头，但是在用户的设备上却并不存在。（译者注：比如坑爹的iTouch 5 16G版）

## Mutability

## 可变对象

Mutability is also a common source of bugs that can be very hard to track down. For example, if you share an object between two threads, and they both modify it at the same time, you might get very unexpected behavior. The tough thing about these kinds of bugs is that they can be very hard to reproduce.

可变对象也是一个很常见的难以追踪的原因。比如，如果你在两个线程中共享了一个对象，且它们同时修改了该对象，你会得到很意外的行为。这类 bug 的痛点在于它们很难复现。

One way to deal with this is to have immutable objects. This way, once you have access to an object, you know that it'll never change its state. There is so much to say about this, but for more information, we'd rather direct you to read the following: [A Warm Welcome to Structs and Value Types](/issue-16/swift-classes-vs-structs.html), [Value Objects](/issue-7/value-objects.html), [Object Mutability](https://developer.apple.com/library/mac/documentation/General/Conceptual/CocoaEncyclopedia/ObjectMutability/ObjectMutability.html), and [About Mutability](http://www.bignerdranch.com/blog/about-mutability/).
TODO:替换URL
有一种解决方法是创建不可变对象。这样，就算你访问对象，你知道它无法改变自己的状态。关于这点有太多可讲，不过更多的信息，我们建议你阅读以下文章：[issue-16-][issue-16-]，[issue-7-][issue-7-]，[对象的可变性][Object Mutability]，和[关于可变性][About Mutability]。

## Nullability

## 空对象

As Objective-C programmers, we sometimes make fun of Java programmers because of their `NullPointerException`s. For the most part, we can safely send messages to nil and not have any problems. Still, there are some tricky bugs that might arise out of this. If you are writing Swift instead of Objective-C, you can safely skip most of this section, because Swift optionals are a solution to many of these problems.

在 Objective-C 的语法中，我们有时会因为 JAVA 语法中的 `NullPointerException` 找乐子。在很多情况下，我们可以安全的发送消息给 nil 不出现什么问题。如此，有一些棘手的 bug 可能因此出现。如果你写 Swift 代替 Objective-C，你可以安全的跳过这节内容的大部分，因为 Swift 的可选值是这其中大部分问题的解决方法。

### Does the Method You Call Take `nil` Parameters?

### 你是否使用 `nil` 做为参数调用了函数？

This is a common source of bugs. Some methods will crash when you call them with a nil parameter. For example, consider the following fragment:

这是一个很常见的原因。一些方法会因为你传入了 `nil` 参数而崩溃。举例，考虑以下片段：

```objectivec
NSString *name = @"";
NSAttributedString *string = [[NSAttributedString alloc] initWithString:name];
```

If `name` is nil, this code will crash. The tricky thing is when this is an edge case that you might not discover (e.g. `myObject` is non-nil in most of the cases). When writing your own methods, you can add a custom attribute to inform the compiler about whether or not you expect nil parameters:

如果 `name` 是 nil，这段代码将崩溃。复杂的地方在于当这是一个边际情况所以你可能没能发现（如 `myObject` 在大多数情况下是不可能为 nil 的）。当写你自己的方法时，你可以加一个本地 属性 去 通知 编译器 你是否允许 nil 参数：

```objectivec
- (void)doSomethingWithRequiredString:(NSString *)requiredString
                                  bar:(NSString *)optionalString
        __attribute((nonnull(1)));
```

(Source: [StackOverflow](http://stackoverflow.com/a/19186298))

（来自：[StackOverflow](http://stackoverflow.com/a/19186298))

Adding this attribute will give a compiler warning when you try to pass in a nil parameter. This is nice, because now you don't have to think about this edge case anymore: you can leverage the compiler infrastructure to have this checked for you.

加入这个标记将 引起 编译器 警告 当你 尝试 传入一个 nil 参数。这挺好，因为你再也不用考虑边际情况：你可以让 编译器 基础设施 根据这个 帮助你检查。

Another possible way around this is to invert the flow of messages. For example, you could create a custom category on `NSString` which has an instance method `attributedString`:

另一种可行的方法是倒置信息流。比如，你可以创建一个自定义分类 在 `NSString` 有一个`attributedString`的实例方法 ：

```objectivec
@implementation NSString (Attributes)

- (NSAttributedString*)attributedString {
    return [[NSAttributedString alloc] initWithString:self];
}

@end
```

The nice thing about the above code is that you can now safely construct an `attributedString`. You could write `[@"John" attributedString]`, but you can also send this message to nil (`[nil attributedString]`), and rather than a crash, you get a nil result. For some more ideas about this, see Graham Lee's article on [reversing the polarity of the message flow](http://www.sicpers.info/2014/10/reversing-the-polarity-of-the-message-flow/).

这段代码的好处是你现在可以安全的构造一个 `attributedString`。你可以写 `[@"John" attributedString]`，但你也可以将这个消息发送给 nil（`[nil attributedString]`），不仅不会崩溃，你会得到一个 nil 的结果。想看到关于这点的更多信息，请查阅 Graham Lee 的文章 [反转信息流](http://www.sicpers.info/2014/10/reversing-the-polarity-of-the-message-flow/)。

If you want to capture more constraints that need to be true (e.g. a parameter should always be a certain class), you can use [`NSParameterAssert`](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Functions/#//apple_ref/c/macro/NSParameterAssert) as well.

如果你希望捕捉更多的限制 必须成立（如一个参数必须为一个确定的类），你也可以使用 [`NSParameterAssert`](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Functions/#//apple_ref/c/macro/NSParameterAssert)。

### Are You Sure You Can Send the Message to `nil`?

### 你是否确定你可以向 `nil` 发送消息？

This is a rather uncommon source of bugs, but it happened to us in a real app. Sometimes when dealing with scalar values, sending a message to nil might produce an unexpected result. Consider the following innocent-looking snippet of code:

这其实是一个不太常见的原因，但是他会发生在一个真正的 app 中。有时处理 纯值，发送一个消息给 nil 可能产生意外的结果。考虑一下下面的 无辜的前瞻性 片段 代码：

```objectivec
NSString *greeting = @"Hello objc.io";
NSRange range = [greeting rangeOfString:@"objc.io"];
if (range.location != NSNotFound) {
  NSLog(@"Found the keyword!");
}
```

If `greeting` contains the string `"objc.io"`, a message is logged. If `greeting` does not contain this string, no message is logged. But what if greeting is `nil`? Then the `range` will be a struct with zeroes, and the `location` will be zero. Because `NSNotFound` is defined as `-1`, this will log the message. So whenever you deal with scalar values and `nil`, be sure to take extra care. Again, this is not an issue in Swift because of optionals.

当 `greeting` 包含了 字符串 `"objc.io"`，消息会被打印。如果 `greeting` 不包含这个字符串，则不会有消息被打印。不过当 `greeting` 为 nil 时会发生什么呢？`range` 会变成一个全是0的结构体，而 `location` 会变成0。因为 `NSNotFound` 被定义为`-1`，所以会打印后面的消息。所以无论你处理纯值和 `nil`时，要确保考虑了更多情况。同样的，Swift的可选值避免了个这个问题。

## Is There Anything in the Class That's Not Initialized?

##是不是类中的某个实例没有初始化？

Sometimes when working with an object, you might end up working with a half-initialized object. Because it's uncommon to do any work in `init`, sometimes you need to call some methods on the object before you can start working with it. If you forget to call these methods, the class might not be initialized completely and weird behavior might occur. Therefore, always make sure that after the designated initializer is run, the class is in a usable state. If you absolutely need your designated initializer to run, and can't construct a working class using just the `init` method, you can still override the `init` method and crash. This way, when you do accidentally instantiate an object using `init`, you'll hopefully find out about it early.

有时当一个对象工作时，你可能结束工作因为一个未完全初始化的对象。因为偶尔需要在 `init` 中做一些事，有时你需要调用一些方法在对象在你开始让他工作之前。如果你忘记了调用这些方法，这个类可能无法完全的初始化而一些奇怪的特性可能会出现。所以，总是确定在指定的初始化开始时，类已经处于可用状态。如果必须让这些指定的初始化方法运行，又不能构建一个只使用 `init` 方法的类，你依旧可以不管 `init` 和崩溃。这种方法，当你偶尔的用 `init` 实例化了一个对象，你会希望更早找到原因。
 
## Key-Value Observing

## KVO

Another common source of bugs is when you're using key-value observing (KVO) incorrectly. Unfortunately, it's not that hard to make mistakes, but luckily, there are a couple of ways to avoid them.

一个常见的原因是当你错误的使用 KVO。不幸的是，犯错误并不难，但幸运的是，有一系列方法去避免。

### Are You Cleaning Up Your Observers?

### 你是否清除了你的观察者？

An easy-to-make mistake is adding an observer, but then never cleaning it up. This way, KVO will keep sending messages, but the receiver might have dealloc'ed, so there will be a crash. One way around this is to use a full-blown framework like [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa), but there are some lighter approaches as well.

一个简单的错误是添加观察者，但不清除它们。这种情况， KVO 将持续的发送消息，但接收者可能已经被释放了，于是引发了崩溃。绕开它的一种方法是使用成熟的框架 如 [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa)，但有一些轻量级的接近也。

One such way is, whenever you create a new observer, immediately write a line in dealloc that removes it. However, this process can be automated. Rather than adding the observer directly, you can create a custom object that adds it for you. This custom object adds the observer and removes it in its own dealloc. The advantage of this is that the lifetime of your observer is the same as the lifetime of the object. This means that creating this object adds the observer. You can then store it in a property, and whenever the containing object is dealloc'ed, the property will automatically be set to nil, thus removing the observer.

有这么一种方法，无论你何时创建了一个新观察者，立刻在析构函数里写一个移除。然而，这个过程可以自动执行。比直接添加观察者更好的办法是，你可以创建一个自定义对象 帮你添加它。这个对象添加观察者和移除 在它自己的析构函数里。这样做的优势是你的观察者的生命周期和这个对象的生命周期一样。这意味着创建这个对象添加了一个观察者。然后你可以将它存为一个属性，当容器对象被析构，属性会自动被设置为nil，然后移除观察者。

A slightly longer explanation of this technique, including sample code, can be found [here](http://chris.eidhof.nl/posts/lightweight-key-value-observing.html). A tiny library that does this is [THObserversAndBinders](https://github.com/th-in-gs/THObserversAndBinders), or you could look at Facebook's [KVOController](https://github.com/facebook/KVOController).

有一点相对详细的关于这种技术的解释，包括一段简单的代码，可以在[这里](http://chris.eidhof.nl/posts/lightweight-key-value-observing.html)被找到。一个小巧的库做了这件事，[THObserversAndBinders](https://github.com/th-in-gs/THObserversAndBinders)，或者你可以看看 Facebook 的 [KVOController](https://github.com/facebook/KVOController)。

Another problem with KVO is that callbacks might arrive on a different thread than you expected (just like we described in the beginning). Again, by using an object to deal with this (as described above), you can make sure that all callbacks get delivered on a specific thread.

另一个关于 KVO 的问题是回调可能会从你预料之外的线程上返回（就像我们在开头描述的那样）。又一次的，使用一个对象来解决这个问题（如以上所说），你可以确保所有的回调会在一个确定的线程上返回。

### Dependent Key Paths

### 依赖键的路径

If you're observing properties that depend on other properties, you need to make sure that you [register dependent keys](https://developer.apple.com/library/ios/DOCUMENTATION/Cocoa/Conceptual/KeyValueObserving/Articles/KVODependentKeys.html). Otherwise, you might not get callbacks when your properties change. A while ago, I created a recursive dependency (a property dependent on itself) in my dependent key declarations, and strange things happened.

如果你观察属性依赖于另一个树型，你需要确保你[注册依赖键](https://developer.apple.com/library/ios/DOCUMENTATION/Cocoa/Conceptual/KeyValueObserving/Articles/KVODependentKeys.html)。另一方面，你可能不会拿到回调，当你的属性变化。不久之前，我创建了一个递归依赖（属性依赖于自己）在我的依赖键声明，然后奇怪的事情发生了。

## Views

## 视图

### Outlets and Actions

### Outlet 和 Action

A common mistake when using Interface Builder is to forget to wire up outlets and actions. This is now often indicated in the code (you can see small circles next to outlets and actions). Also, it's very possible to add unit tests that test whether everything is connected as you expect (but it might be too much of a maintenance burden).

一个常见的错误 使用 Interface Builder 是 忘记 链接 outlet 和 action。现在经常在代码中指示（你可以看到小的圆圈在 outlet 和 action 旁边）。同样，这很可能去添加单元测试 测试是否所有连接都和预想的一样（但是这可能会变成很严重的维护负担）。

Here, you could also use asserts like [`NSAssert`](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Functions/#//apple_ref/c/macro/NSAssert) to verify that your outlets are not nil, in order to make sure you fail fast whenever this happens.

这里，你也可以使用 断言 像 [`NSAssert`](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Functions/#//apple_ref/c/macro/NSAssert) 去验证你的 outlet 不是 nil，为了确保很快失败无论这种情况在何时发生。

### Retaining Objects

### 未释放的对象

When you use Interface Builder, you need to make sure that your object graph that you load from a nib file stays retained. There are [good pointers on this by Apple](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/LoadingResources/CocoaNibs/CocoaNibs.html#//apple_ref/doc/uid/10000051i-CH4-SW6). Be sure to read that section and follow the advice, otherwise your objects might either disappear underneath you, or get over-retained. There are differences between plain XIB files and Storyboards; be sure to account for that.

当你使用了 Interface Builder，你需要确保你的对象的图形 你载入的 从一个 被保持的 nib 文件。有一些[苹果关于这个问题的好点子](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/LoadingResources/CocoaNibs/CocoaNibs.html#//apple_ref/doc/uid/10000051i-CH4-SW6)。确定读了那一节且遵从那些建议，要么你的对象可能在你眼皮底下消失，或者被过分 保持。有一些不同 在简单的 XIB 文件和 Storyboard，明确你明确它们。

### View Lifecycle

### 视图的生命周期

When dealing with views, there are many potential bugs that can arise. One common mistake is to work with views when they are not yet initialized. Alternatively, you might work with initialized views that don't have a size yet. The key here is to do things at the right point in [the view lifecycle](http://developer.apple.com/library/ios/#documentation/uikit/reference/UIViewController_Class/Reference/Reference.html#//apple_ref/doc/uid/TP40006926-CH3-SW58). Investing the time in understanding exactly how this works will almost certainly pay off in decreased debugging time.

当处理视图的时候，有很多可能的 bug 会出现。一个常见的错误是在视图还没有初始化的时候使用它们。或者，你可能在一个视图只是初始化，却还没有设置尺寸。 这里的关键是在正确的时间去做一些事情在[视图生命周期](http://developer.apple.com/library/ios/#documentation/uikit/reference/UIViewController_Class/Reference/Reference.html#//apple_ref/doc/uid/TP40006926-CH3-SW58)。花时间去明确的理解它们是如何工作 将 肯定的 清偿 在 减少的 调试时间。

When you port an existing app to the iPad, this might also be a common source of bugs. All of a sudden, you might need to worry about whether a view controller is a child view controller, how it responds to rotation events, and many other subtle differences. Here, auto layout might be helpful, as it can automatically respond to many of these changes.

当你确定了一个已经存在的 app 在 iPad 上，这可能会变成一个常见的 bug 原因。突如其来的，你可能需要担心是否一个视图控制器是一个子视图控制器，他们如何响应旋转事件，和一些其它的细微的不同。这里，自动布局可能会有帮助，它可以自动响应很多这样的变化。

One common mistake that we keep making is creating a view, adding some constraints, and then adding it to the superview. In order for most constraints to work, the view needs to be in the superview hierarchy. Luckily, most of the time this will crash your code, so you'll find the bug fast.

一个常见的错误是我们总是创建一个视图，添加一些约束，然后将它添加进父视图里。为了让大部分约束能够工作，视图需要在父视图的视图层级里。幸运的是，大部分情况这会直接让你的代码崩溃，然后你可以很快的找到 bug。

## Finally

## 最后

The techniques above are hopefully helpful to get rid of bugs or prevent them completely. There is also automated help available: turning on all warning messages in Clang can show you a lot of possible bugs, and running the static analyzer will almost certainly find some bugs (unless you run it on a regular basis).

但愿以上的技术会帮助你摆脱 bug 或者完全的避免它们。有一些自动的帮助是可用的：打开所有的警告消息 在 Clang 中 可以向你展示很多可能的 bug，然后运行静态分析一定能找到一些 bug（除非定期的运行它）。
