---
title:  "Activity Tracing"
category: "19"
date: "2014-12-08 07:00:00"
tags: article
author: "<a href=\"https://twitter.com/floriankugler\">Florian Kugler</a>"
---


Tracking down crashes in asynchronous code is often very hard, because the stack trace is confined to the crashed thread and you're missing contextual information. At the same time, writing asynchronous code has become significantly easier with APIs like [libdispatch](/issue-2/low-level-concurrency-apis.html), operation queues, and [XPC](/issue-14/xpc.html).

追查出异步执行的代码中出现的错误往往是一件非常困难的事，因为栈追踪信息(stack trace)局限于发生崩溃的线程，这就意味着你无法获得全部的上下文信息。与此同时，编写异步代码却得益于 [libdispatch](/issue-2/low-level-concurrency-apis.html)，运行队列(operation queues)和 [XPC](/issue-14/xpc.html) 提供的 API 变得越发的简单。

Activity tracing is a new technology introduced in iOS 8 and OS X 10.10 that aims to alleviate this problem. This year's WWDC had an excellent [session][wwdcsession] about it, but we thought it would be a good idea to give another overview here, since it is not widely known yet.

活动追踪是一项 iOS 8 和 OS X 10.10 新引入的技术，他正是为了减轻上面我们提到的这个问题。今年的 WWDC 有一个有关这个主题非常棒的[会议][wwdcsession]，不过我们认为在这里为它写一篇简介也很必要，因为很多人应该还没有听说过这项技术。

The basic idea is that work done in response to user interactions or other events is grouped under an activity, no matter if the work is done synchronously or if it's dispatched to other queues or processes. For example, if the user triggers a refresh in your app, you'll know that this particular user interaction caused a subsequent crash, even if it happens on a different queue and several other code paths could have led to the crashing code as well.

活动追踪技术最基本的思想是，用一个活动汇集响应某个用户交互行为或其他事件的全部工作，无论这些工作是同步的执行或是被分配到其他队列和进程中去。举个例子来说，如果用户在你的应用中触发了一个刷新，那么你会知道就是这个特定的用户行为造成了接下来发生的崩溃，即使崩溃是发生在其他的队列中或者有其他用户行为也会触发同样的崩溃。

Activity tracing has three different parts to it: activities, breadcrumbs, and trace messages. We'll go into those in more detail below, but here's the gist of it: Activities allow you to trace the crashing code back to its originating event in a cross-queue and cross-process manner. With breadcrumbs, you can leave a trail of meaningful events across activities leading up to a crash. And finally, trace messages allow you to add further detail to the current activity. All this information will show up in the crash report in case anything goes wrong.

活动追踪由三部分组成：活动，面包屑[(参考面包屑导航)](http://zh.wikipedia.org/wiki/%E9%9D%A2%E5%8C%85%E5%B1%91%E5%AF%BC%E8%88%AA)，追踪信息。我们会在接下来详细探讨这三部分，在这里先给出要点：活动可以在跨队列跨进程的情况下帮助你追踪出导致崩溃发生的事件。面包屑可以帮你跨越多个活动画出导致崩溃发生的事件轨迹。最后，追踪信息可以帮助你为当前活动添加更详细的信息。出现任何问题，这三种信息都会出现在最终的崩溃报告中。

Before we go into more detail, let me just quickly mention a potential pitfall when trying to get activity tracing to work: if the activity messages are not showing up, check the `system.log` for any messages from the `diagnosticd` daemon, like "Signature Validation Failed" — you might be running into code signing issues. Also, note that on iOS, activity tracing only works on a real device, and not in the simulator.

在我们进入细节讲解之前，让我简单的提一下使用活动追踪过程中可能的坑：如果活动追踪信息没有显示出来，检查 `system.log` 中是否有守护进程([参考守护进程](http://zh.wikipedia.org/wiki/%E5%AE%88%E6%8A%A4%E8%BF%9B%E7%A8%8B))`diagnosticd` 给出的类似 "Signature Validation Failed" 的信息，你可以会遇到代码签名的问题。此外，注意在 iOS 上活动追踪只能在真机上工作，在模拟器上不行。

## Activities

## 活动

Activities are at the heart of this new technology. An activity groups together the code executing in response to a certain event, no matter on what queues and in what processes the code is executing. This way, if anything goes wrong in the middle, the crash can be traced back to the original event.

活动是这项新技术的核心部分。一个活动汇集了响应一个事件所需的全部代码运行过程，无论代码是运行在哪个队列哪个进程中。这样在代码运行过程中出现任何问题，都可以轻易地追踪回造成崩溃的源头。

Activity tracing is integrated into AppKit and UIKit, so that an activity is started automatically whenever a user interface event is sent through the target-action mechanism. In case of user interactions that don't send events through the responder chain (like a tap on a table view cell), you'll have to initiate an activity yourself.

活动追踪集成在 AppKit 和 UIKit 中，所以每当一个用户界面事件通过目标-行为机制传递，一个活动会自动开启。对于不会向响应链(responder chain)发送事件的用户交互，例如点击 table view cell，你就需要自己手动初始化一个活动。

Starting an activity is very simple:

启动一个活动非常简单：

```
#import <os/activity.h>

os_activity_initiate("activity name", OS_ACTIVITY_FLAG_DEFAULT, ^{
    // do some work...
});
```

This API executes the block synchronously, and everything you do within the block will be scoped under this activity, even if you dispatch work onto other queues or do XPC calls. The first parameter is the label of the activity, and has to be provided as a constant string (like all string parameters of the activity tracing API).

这个 API 会同步地执行 block，在 block 中运行的任何代码都会被归为这个活动中，即使你将一些工作分配到其他队列上去运行或者进行了 XPC 调用。第一个参数是活动的标记，必须赋予一个字符串常量(活动追踪 API 中其他字符串参数也都必须是常量)。

The second parameter, `OS_ACTIVITY_FLAG_DEFAULT`, is the activity flag you use to create an activity from scratch. If you want to create a new activity within the scope of an existing activity, you have to use `OS_ACTIVITY_FLAG_DETACHED`. For example, when reacting to an action message of a user interface control, AppKit has already started an activity for you. If you want to start an activity from here that is not the direct result of the user interaction, that's when you'd use a detached activity.

第二个参数，`OS_ACTIVITY_FLAG_DEFAULT`，是你要新建一个全新活动的标识。如果你想在一个已经存在的活动中创建一个新的活动，那么必须使用 `OS_ACTIVITY_FLAG_DETACHED`。举例来说，当响应一个用户交互组件发送的行为信息时，AppKit 已经为你开启一个活动。如果你想在这个没有完成用户交互响应的时候开启一个活动，这个时候你就需要一个分离的活动。

There are other variants of this API that work in the same away — a function-based one (`os_activity_initiate_f`), and one that consists of a pair of macros:

这个 API 有几个同样功能的变体，一个基于函数(`os_activity_initiate_f`)，一个由几个宏命令组成：

```
os_activity_t activity = os_activity_start("label", OS_ACTIVITY_FLAG_DEFAULT);
// do some work...
os_activity_end(activity);
```

Note that activities will not show up in crash reports (or other ways of inspecting them) if you don't set at least one trace message. See below for more details on trace messages.

注意如果你没有设置至少一个追踪信息，活动就不会出现在崩溃报告或者其他任何形式的查看方式中。在后面会有更多有关追踪信息的细节。


## Breadcrumbs

## 面包屑

Breadcrumbs are used for what the name suggests: your code leaves a trail of labeled events while it executes in order to provide context across activities in case a crash happens. Adding a breadcrumb is very simple:

面包屑所起到的作用就像他的名字所暗示的那样：当代码出现崩溃，你的代码会留下一个可以说明上下文信息的跨活动事件标记轨迹。添加面包屑非常的简单：

```
os_activity_set_breadcrumb("event description");
```

The events are stored in a ring buffer that only holds the last 50 events. Therefore, this API should be used to indicate macro-level events, like meaningful user interactions.

事件被存储在一个环形的缓冲区内，这个缓冲区只记录最近运行的50个事件。所以这个 API 只应该用来标记宏观的事件，比如像特定的用户交互行为。

Note that this API only has an effect from within the scope of an activity: it marks the current activity as a breadcrumb. This also means that you can only do this once per activity; subsequent calls will be ignored.

注意调用这个 API 只能在一个活动过程当中时有效：将当前这个活动标记为一个面包屑。这也意味着每一个活动你只能标记一次，接下来的调用会被系统忽略。


## Trace Messages

## 追踪信息

Trace messages are used to add additional information to activities, very similar to how you would use log messages. You can use them to add valuable information to crash reports, in order to more easily understand the root cause of the problem. Within an activity, a very simple trace message can be set like this:

追踪信息用来为活动添加附加的说明信息，就跟你使用 log 信息的目的一样。你可以用来向崩溃报告添加一些重要的说明信息，这样就可以使你更容易理解造成问题出现的根源。在一个活动中，一个简单的追踪信息可以这样添加：

```
#import <os/trace.h>

os_trace("my message");
```

Trace messages can do more than that though. The first argument to `os_trace` is a format string, similar to what you'd use with `printf` or `NSLog`. However, there are some restrictions to this: the format string can be a maximum of 100 characters long and can contain a placeholder for up to seven *scalar* values. This means that you cannot log strings. If you try to do so, the strings will be replaced by a placeholder.

除此之外，追踪信息可以起到更大的作用。`os_trace` 的第一个参数是一个格式化字符串，和你在 `printf` 或 `NSLog` 中的用法一样。不过 `os_trace` 有一些限制：格式化字符串最长只能包含100个字符和最多7个标量值的占位符。这就意味着你不能传入字符串作为输出，如果你传入了一个字符串，字符串会被占位符所替换。

Here are two examples of using format strings with `os_trace`:

下面是两个在 `os_trace` 中使用格式化字符串的例子：

```
os_trace("Received %d creates, %d updates, %d deletes", created, updated, deleted);
os_trace("Processed %d records in %g seconds", count, time);
```

One caveat that I stumbled upon while experimenting with this API is that trace messages don't show up in crash reports if no trace messages are sent from the crashing thread.

在我尝试使用这个 API 时偶然发现了一个坑，那就是如果没有从发生崩溃的线程中发送出来追踪信息，那么所有的追踪信息都不会出现在崩溃报告中。


### Trace Message Variants

### 追踪信息的变体

There are several variants to the basic `os_trace` API. First, there's `os_trace_debug`, which you can use to output trace messages that only show up in debug mode. This can be helpful to reduce the amount of trace messages in production, so that you will only see the most meaningful ones, and don't flood the limited ring buffer that's used to storing those messages with less useful information. To enable debug mode, set the environment variable `OS_ACTIVITY_MODE` to `debug`.

`os_trace` 有好几个功能相似的 API。首先是 `os_trace_debug`，可以用来只在调试模式下输出追踪信息。在生产环境中这会很有帮助，减少环形缓冲区存储的无用追踪信息，你就可以得到最有价值的那些。要开启调试模式，需要设置环境变量 `OS_ACTIVITY_MODE` 为 `debug`。

Additionally, there are two more variants of these macros to output trace messages: `os_trace_error` and `os_trace_fault`. The first one can be used to indicate unexpected errors, and the second one to indicate catastrophic failures, i.e. that you're about to crash.

除此之外，还有两个可以功能相近的宏命令可以输出追踪信息：`os_trace_error` 和 `os_trace_fault`。前者可以用来表明出现了未预料到的错误，后者用来表明出现了致命的错误，也就是马上就要崩溃了。

As discussed above, the standard `os_trace` API only accepts a constant format string of limited length and scalar values. This is done for privacy, security, and performance reasons. However, there are situations where you'd like to see more data when debugging a problem. This is where payload trace messages come in.

前面我们提到了，标准的 `os_trace` API 只接受一个限制长度和变量类型的格式化字符串。这样的设计是基于对隐私性安全性和运行效率的考虑。但是，当你在调试一个问题的时候，总有一些情况下会想要得到更多的数据。这个时候带有负载的追踪信息就派上了用场。

The API for this is `os_trace_with_payload`, and may seem a bit weird at first: similar to `os_trace`, it takes a format string, a variable number of value arguments, and a block with a parameter of type `xpc_object_t`. This block will not be called in production mode, and therefore poses no overhead. However, when debugging, you can store whatever data you want in the dictionary that the block receives as its first and only argument:

带有负载的追踪信息对应的 API 是 `os_trace_with_payload`，初看可能会有些奇怪：类似于 `os_trace`，这个 API 接收一个格式化字符串，一个可变数量的参数值，和一个带有 `xpc_object_t` 类型参数的 block。这个 block 在生产环境中不会被调用，也就不会产生额外开销。不同的是，在调试的过程中你可以在 block 唯一的字典参数中存储任何你想要的数据。

```
os_trace_with_payload("logged in: %d", guid, ^(xpc_object_t xdict) {
    xpc_dictionary_set_string(xdict, "name", username);
});
```

The reason that the argument to the block is an XPC object is that activity tracing works with the `diagnosticd` daemon under the hood to collect the data. By setting values in this dictionary using the `xpc_dictionary_set_*` APIs, you're communicating with this daemon. To inspect the payload data, you can use the `ostraceutil` command line utility, which we will look at in more detail below.

这个 block 的参数类型之所以是 XPC 对象，是因为在活动追踪技术的底层使用了 `diagnosticd` 守护进程收集数据。通过 API `xpc_dictionary_set_*` 设置这个字典对象的值就是在与这个进程进行通信。你可以通过命令行工具 `ostraceutil` 来查看负载的数据，关于这个工具我们接下来会深入探讨。

You can use payloads with all previously discussed variants of the `os_trace` macro. Next to `os_trace_with_payload` (which we used above), there's also `os_trace_debug_with_payload`, `os_trace_error_with_payload`, and `os_trace_fault_with_payload`.

我们之前讨论的所有与 `os_trace` 相似的宏命令都可以进行负载。与上面使用的 `os_trace_with_payload` 很像，我们还有 `os_trace_debug_with_payload`，`os_trace_error_with_payload`，和 `os_trace_fault_with_payload`。


## Inspecting Activity Tracing

## 查看活动追踪的进行


There are two ways you can get to the output of activity tracing aside from crash reports. First, activity tracing is integrated into the debugger. By typing `thread info` into the LLDB console, you can inspect the current activity and the trace messages from the current thread:

除了崩溃报告之外你还有两种办法可以查看活动追踪的输出。首先，活动追踪集成在调试器中。在 LLDB 的控制台中输入 `thread info`，你可以得到当前线程中当前进行的活动和追踪的信息。

```
(lldb) thread info
thread #1: tid = 0x19514a, 0x000000010000125b ActivityTracing2`__24-[ViewController crash:]_block_invoke_4(.block_descriptor=<unavailable>) + 27 at ViewController.m:26, queue = 'com.apple.main-thread', activity = 'crash button pressed', 1 messages, stop reason = EXC_BAD_ACCESS (code=1, address=0x0)

  Activity 'crash button pressed', 0x8e700000005

  Current Breadcrumb: button pressed

  1 trace messages:
    message1
```

Another option is to use the `ostraceutil` command line utility. Executing

另一种选择是使用命令行工具 `ostraceutil`，在终端中运行

```
sudo ostraceutil -diagnostic -process <pid> -quiet
```

from the command line (replace `<pid>` with the process id) yields the following (shortened) information:

(`<pid>` 代表进程 id)会输出如下信息(有缩减)

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

The output is more extensive than the one from the LLDB console, since it also contains the breadcrumb trail, as well as the trace messages from all threads.

真正的输出会比 LLDB 控制台的输出多很多，因为还包括了面包屑轨迹和所有线程的追踪信息。

Instead of using `ostraceutil` with the `-diagnostic` flag, we can also use the `-watch` flag to put it into a live mode where we can see the trace messages and breadcrumbs coming in as they happen. In this mode, we can also see the payload data of trace messages:

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


## Activity Tracing and Swift

## 活动追踪和 Swift

At the time of writing, activity tracing is not accessible from Swift.

在写下这篇文章的时候，Swift 还不能直接调用活动追踪 API。

If you want to use it now within a Swift project, you would have to create an Objective-C wrapper around it and make this API accessible in Swift using the bridging header. Note that activity tracing macros expect strings to be constant, i.e. you can't pass a string argument of your wrapper function to the activity tracing API. To illustrate this point, the following doesn't work:

如果你想在一个 Swift 项目中使用活动追踪，就必须创建一个 Objective-C 的封装，使得 Swift 可以通过桥接头文件(bridging header)来调用那些 API。注意活动追踪那些宏命令要求字符串是常量，也就是说你不能直接用封装函数的参数做活动追踪 API 的参数。为了说明这一点，下面这样的调用是没有作用的

```
void sendTraceMessage(const char *msg) {
    os_trace(msg); // this doesn't work!
}
```

One possible workaround is to define specific helper functions like this:

一种可能的解决方法是定义特定的辅助函数像这样：

```
void traceLogin(int guid) {
    os_trace("Login: %d", guid);
}
```


## Conclusion

## 小结

Activity tracing is a very welcome addition to our debugging toolkit and makes diagnosing crashes in asynchronous code so much easier. We really should make it a habit to add activities, breadcrumbs, and trace messages to our code.

活动追踪作为一个新的调试工具非常受欢迎，他使得我们更容易诊断异步代码中出现的错误。我们都应该将标记活动面包屑和追踪信息作为编码的新习惯。

The most painful point at this time is the missing Swift integration, at least for those of us who already use Swift in production code. Hopefully it is just a matter of (a not too long) time until this will change.

对于那些已经在正式生产环境中使用 Swift 的人来说，目前最大的遗憾是 Swift 不能够直接调用。希望 Swift 的集成只是一个不会很久远的时间问题。


[wwdcsession]: https://developer.apple.com/videos/wwdc/2014/#714
