追查出异步执行的代码中出现的错误往往是一件非常困难的事，因为栈追踪 (stack trace) 局限于发生崩溃的线程，这就意味着你无法获得全部的上下文信息。与此同时，编写异步代码却得益于 [libdispatch](http://objccn.io/issue-2-3/)，运行队列 (operation queues) 和 [XPC](http://objccn.io/issue-14-4/) 提供的 API 变得越发的简单。

活动追踪是一项 iOS 8 和 OS X 10.10 新引入的技术，它正是为了帮助我们更好地解决上面提到的这个问题。今年的 WWDC 有一个有关这个主题非常棒的 [session][wwdcsession]，不过我们认为在这里为它另外写一篇简介也是一个好主意，毕竟知道它的人还不多。

活动追踪技术最基本的思想是，用一个活动汇集响应某个用户交互行为或其他事件的全部工作，无论这些工作是同步的执行的还是被分配到其他队列和进程中去的。举个例子来说，如果用户在你的应用中触发了一个刷新然后崩溃了，即使这个崩溃是发生在其他的队列中或者有其他的代码路径也能运行到崩溃的代码，但你总能知道就是“刷新”这个特定的用户行为造成了接下来发生的崩溃。

活动追踪由三部分组成：活动，面包屑 (译者注：参考[面包屑导航](http://zh.wikipedia.org/wiki/%E9%9D%A2%E5%8C%85%E5%B1%91%E5%AF%BC%E8%88%AA)) 和追踪信息。我们会在接下来详细探讨这三部分，在这里先给出要点：活动可以在跨队列跨进程的情况下帮助你追踪出导致崩溃发生的事件。面包屑可以帮你跨越多个活动画出导致崩溃发生的事件轨迹。最后，追踪信息可以帮助你为当前活动添加更详细的信息。出现任何问题，这三种信息都会出现在最终的崩溃报告中。

在我们进入细节讲解之前，让我简单的提一下使用活动追踪过程中可能的坑：如果活动追踪信息没有显示出来，检查 `system.log` 中是否有 `diagnosticd` 这个守护进程 (译者注：参考[守护进程](http://zh.wikipedia.org/wiki/%E5%AE%88%E6%8A%A4%E8%BF%9B%E7%A8%8B)) 给出的类似 "Signature Validation Failed" 的信息，你可以会遇到代码签名的问题。此外，注意在 iOS 上活动追踪只能在真机上工作，在模拟器上不行。

## 活动

活动是这项新技术的核心部分。一个活动汇集了响应一个事件所需的全部代码运行过程，而无论代码是运行在哪个队列哪个进程中的。这样在代码运行过程中出现任何问题，都可以轻易地追踪回造成崩溃的源头的事件。

活动追踪集成在 AppKit 和 UIKit 中，所以每当一个用户界面事件通过 target-action 机制传递，一个活动会自动开启。对于不会向响应链发送事件的用户交互，例如点击 table view cell，你就需要自己手动初始化一个活动。

启动一个活动非常简单：

```
#import <os/activity.h>

os_activity_initiate("activity name", OS_ACTIVITY_FLAG_DEFAULT, ^{
    // do some work...
});
```

这个 API 会同步地执行 block，在 block 中运行的任何代码，即使是那些你分配到其他队列上去运行的工作或者进行了 XPC 调用，都会被归为这个活动中。第一个参数是活动的标记，必须赋予一个字符串常量 (活动追踪 API 中其他字符串参数也都必须是常量)。

第二个参数，`OS_ACTIVITY_FLAG_DEFAULT`，是你要新建一个全新活动的标识。如果你想在一个已经存在的活动中创建一个新的活动，那么必须使用 `OS_ACTIVITY_FLAG_DETACHED`。举例来说，当响应一个用户交互控件发送的行为信息时，AppKit 已经为你开启一个活动。如果你想在这个用户交互响应没有完成的时候开启一个活动，你就需要一个分离的活动。

There are other variants of this API that work in the same away — a function-based one (`os_activity_initiate_f`), and one that consists of a pair of macros:

这个 API 有几个同样功能的变体，一个基于函数 (`os_activity_initiate_f`)，一个由几个宏命令组成：

```
os_activity_t activity = os_activity_start("label", OS_ACTIVITY_FLAG_DEFAULT);
// do some work...
os_activity_end(activity);
```

注意你必须设置至少一个追踪信息，否则活动就不会出现在崩溃报告或者其他任何形式的查看方式中。在后面会有更多有关追踪信息的细节。

## 面包屑

面包屑所起到的作用就像它的名字所暗示的那样：当代码出现崩溃，你的代码会留下一个可以说明上下文信息的跨活动事件标记轨迹。添加面包屑非常的简单：

```
os_activity_set_breadcrumb("event description");
```

事件被存储在一个环形的缓冲区内，这个缓冲区只记录最近运行的50个事件。所以这个 API 只应该用来标记宏观的事件，比如像特定的用户交互行为。

注意调用这个 API 只能在一个活动过程当中时有效：将当前这个活动标记为一个面包屑。这也意味着每一个活动你只能标记一次，接下来的调用会被系统忽略。

## 追踪信息

追踪信息用来为活动添加附加的说明信息，就跟你使用 log 信息的目的一样。你可以用来向崩溃报告添加一些重要的说明信息，这样就可以使你更容易理解造成问题出现的根源。在一个活动中，一个简单的追踪信息可以这样添加：

```
#import <os/trace.h>

os_trace("my message");
```

除此之外，追踪信息可以起到更大的作用。`os_trace` 的第一个参数是一个格式化字符串，和你在 `printf` 或 `NSLog` 中的用法一样。不过 `os_trace` 有一些限制：格式化字符串最长只能包含 100 个字符和最多 7 个**标量**值的占位符。这就意味着你不能输出字符串，如果你尝试输出字符串，字符串会被一个占位符所替换。

下面是两个在 `os_trace` 中使用格式化字符串的例子：

```
os_trace("Received %d creates, %d updates, %d deletes", created, updated, deleted);
os_trace("Processed %d records in %g seconds", count, time);
```

我在尝试使用这个 API 时偶然发现了一个坑，那就是如果没有从发生崩溃的线程中发送出来追踪信息，那么所有的追踪信息都不会出现在崩溃报告中。

### 追踪信息的变体

在 `os_trace` 的基础上有好几个功能相似的 API。首先是 `os_trace_debug`，可以用来只在调试模式下输出追踪信息。在生产环境中这会很有帮助，可以减少环形缓冲区存储的无用追踪信息，这样你就可以得到最有价值的那些信息。要开启调试模式，需要设置环境变量 `OS_ACTIVITY_MODE` 为 `debug`。

除此之外，还有两个功能相近的宏命令可以输出追踪信息：`os_trace_error` 和 `os_trace_fault`。前者可以用来表明出现了未预料到的错误，后者用来表明出现了致命的错误，比如说马上就要崩溃了。

前面我们提到了，标准的 `os_trace` API 只接受一个限制长度和标量类型的格式化字符串。这样的设计是基于对隐私性，安全性和运行效率的考虑。但是，当你在调试一个问题的时候，总有一些情况下会想要得到更多的数据。这个时候带有负载 (payload) 的追踪信息就派上了用场了。

带有负载的追踪信息对应的 API 是 `os_trace_with_payload`，初看可能会有些奇怪：它类似于 `os_trace`，这个 API 接收一个格式化字符串，一个可变数量的参数值，和一个带有 `xpc_object_t` 类型参数的 block。这个 block 在生产环境中不会被调用，也就不会产生额外开销。不同的是，在调试的过程中你可以在 block 唯一的字典参数中存储任何你想要的数据。

```
os_trace_with_payload("logged in: %d", guid, ^(xpc_object_t xdict) {
    xpc_dictionary_set_string(xdict, "name", username);
});
```

这个 block 的参数类型之所以是 XPC 对象，是因为在活动追踪技术的底层使用了 `diagnosticd` 守护进程收集数据。通过 API `xpc_dictionary_set_*` 设置这个字典对象的值就是在与这个进程进行通信。你可以通过命令行工具 `ostraceutil` 来查看负载的数据，关于这个工具我们接下来会深入探讨。

我们之前讨论的所有与 `os_trace` 相似的宏命令都可以进行负载。与上面使用的 `os_trace_with_payload` 很像，我们还有 `os_trace_debug_with_payload`，`os_trace_error_with_payload`，和 `os_trace_fault_with_payload`。

## 查看活动追踪的进行

除了崩溃报告之外你还有两种办法可以查看活动追踪的输出。首先，活动追踪集成在调试器中。在 LLDB 的控制台中输入 `thread info`，你可以得到当前线程中当前进行的活动和追踪的信息。

```
(lldb) thread info
thread #1: tid = 0x19514a, 0x000000010000125b ActivityTracing2`__24-[ViewController crash:]_block_invoke_4(.block_descriptor=<unavailable>) + 27 at ViewController.m:26, queue = 'com.apple.main-thread', activity = 'crash button pressed', 1 messages, stop reason = EXC_BAD_ACCESS (code=1, address=0x0)

  Activity 'crash button pressed', 0x8e700000005

  Current Breadcrumb: button pressed

  1 trace messages:
    message1
```

另一种选择是使用命令行工具 `ostraceutil`，在终端中运行

```
sudo ostraceutil -diagnostic -process <pid> -quiet
```

(将 `<pid>` 替换为进程 id) 会输出如下信息 (有缩减)

```
Process:
==================
PID: 16992
Image_uuid: FE5A6C31-8710-330A-9203-CA56366876E6
Image_path: [...]

Application Breadcrumbs:
==================
Timestamp: 59740.861604, Breadcrumb ID = 6768, Name = 'Opened theme picker', Activity ID: 0x000008e700000001
Timestamp: 59742.202451, Breadcrumb ID = 6788, Name = 'button pressed', Activity ID: 0x000008e700000005

Activity:
==================
Activity ID: 0x000008e700000005
Activity Name: crash button pressed
Image Path: [...]
Image UUID: FE5A6C31-8710-330A-9203-CA56366876E6
Offset: 0x1031
Timestamp: 59742.202350
Reason: none detected

Messages:
==================
Timestamp: 59742.202508
FAULT
Activity ID: 0x000008e700000005
Trace ID: 0x0000c10000001ac0
Thread: 0x1951a8
Image UUID: FE5A6C31-8710-330A-9203-CA56366876E6
Image Path: [...]
Offset: 0x118d
Message: 'payload message'
----------------------
Timestamp: 59742.202508
RELEASE
Trace ID: 0x0000010000001aad
Offset: 0x114c
Message: 'message2'
----------------------
Timestamp: 59742.202350
RELEASE
Trace ID: 0x0000010000001aa4
Thread: 0x19514a
Offset: 0x10b2
Message: 'message1'
```

真正的输出会比 LLDB 控制台的输出多很多，因为还包括了面包屑轨迹和所有线程的追踪信息。

除了使用 `ostraceutil` 的 `-diagnostic` 参数之外，我们还可以使用 `-watch` 参数动态地查看追踪信息和面包屑的输出。在这种模式下，还会输出追踪信息的负载数据。

```
[...]
----------------------
Timestamp: 60059.327207
FAULT
Trace ID: 0x0000c10000001ac0
Offset: 0x118d
Message: 'payload message'
Payload: '<dictionary: 0x7fd2b8700540> { count = 1, contents =
	"test-key" => <string: 0x7fd2b87000c0> { length = 10, contents = "test-value" }
}'
----------------------
[...]
```

## 活动追踪和 Swift

在写下这篇文章的时候，Swift 还不能直接调用活动追踪 API。

如果你想在一个 Swift 项目中使用活动追踪，就必须创建一个 Objective-C 的封装，使得 Swift 可以通过桥接头文件 (bridging header) 来调用那些 API。注意活动追踪那些宏命令要求字符串是常量，也就是说你不能直接用封装函数的参数做活动追踪 API 的参数。为了说明这一点，下面这样的调用是不起作用的：

```
void sendTraceMessage(const char *msg) {
    os_trace(msg); // this doesn't work!
}
```

一种可能的解决方法是定义特定的辅助函数像这样：

```
void traceLogin(int guid) {
    os_trace("Login: %d", guid);
}
```

## 总结

活动追踪作为一个新的调试工具非常受欢迎，它使得我们更容易诊断异步代码中出现的错误。我们都应该将标记活动面包屑和追踪信息作为编码的新习惯。

对于那些已经在正式生产环境中使用 Swift 的人来说，目前最大的遗憾是 Swift 不能够直接调用。希望 Swift 的集成只是一个不会很久远的时间问题。

[wwdcsession]: https://developer.apple.com/videos/wwdc/2014/#714

---

 

原文 [Activity Tracing](http://www.objc.io/issue-19/activity-tracing.html)

