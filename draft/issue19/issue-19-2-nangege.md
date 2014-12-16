---
title:  "Dancing in the Debugger — A Waltz with LLDB"
category: "19"
date: "2014-12-08 10:00:00"
tags: article
author: "<a href=\"https://twitter.com/ari_grant\">Ari Grant</a>"
---
---
标题 ：与调试器共舞-LLDB的华尔兹
分类 : "19"
日期 : "2014-12-08 10:00:00"
标签 : article
作者: "<a href=\"https://twitter.com/ari_grant\">Ari Grant</a>"
---

Have you ever been stuck trying to understand your code and logged the contents of a variable?

    NSLog(@"%@", whatIsInsideThisThing);
    
Or skipped a function call to simplify the behavior of the program?
    
    NSNumber *n = @7; // theFunctionThatShouldReallyBeCalled();
    
Or short-circuited a logical check?
    
    if (1 || theBooleanAtStake) { ... }
    
Or faked the implementation of a function?
    

你是否曾经被理解你的代码困住，并且 log 一个变量的值？

    NSLog(@"%@", whatIsInsideThisThing);
    
或者跳过一个函数调用来简化程序的行为？

    NSNumber *n = @7; // theFunctionThatShouldReallyBeCalled();
    
或者短路一个逻辑检查？

    if (1 || theBooleanAtStake) { ... }

或者伪造一个函数实现？

	int calculateTheTrickyValue {
	  return 9;
	  
	  /*
	   Figure this out later.
	   ...
    }
 
    
And had to recompile, and start over each time?

并且每次必须重新编译，从头开始？
    
Building software is complicated and bugs will always appear. A common fix cycle is to modify the code, compile, run again, and wish for the best.

构建软件是复杂的，并且Bug总是出现。一个常见的修复周期就是修改代码，编译，重新运行，并且祈祷出现最好的结果。

It doesn't have to be that way. You can use the debugger! And even if you already know how to inspect values, there is a lot more it is capable of.

但是不一定要这么做。你可以使用调试器。而且即使你已经知道如何使用调试器检查变量，它可以做的还有很多。

This article intends to challenge your knowledge of debugging, explain the basics in a bit more detail than you likely know, and then show you a collection of fun examples. Let's take it for a spin and see where we end up.

这篇文章试图挑战你多调试的认知，详细的解释一些你可能不了的基本原理，然后展示一系列有趣的例子。让我们开始兜风之旅，看看会在哪里停止。

## LLDB

[LLDB](http://lldb.llvm.org/) is an [open-source](http://lldb.llvm.org/source.html) debugger that features a REPL, along with C++ and Python plugins. It comes bundled inside Xcode and lives in the console at the bottom of the window. A debugger allows you to pause a program at a specific moment of its execution, inspect the values of variables, execute custom instructions, and then manipulate the advancement of the program as you see fit. ([Here](http://eli.thegreenplace.net/2011/01/23/how-debuggers-work-part-1.html) is one explanation of how debuggers work in general.)


[LLDB](http://lldb.llvm.org/)是一个有着REPL的特性和 C++ ,python 插件的[开源](http://lldb.llvm.org/source.html)调试器。LLDB绑定在xcode内部，存在于主窗口底部的控制台窗口中。调试器允许你在程序运行的特定时间暂停它，查看变量的值，执行特定的指令，然后以您任务合适的步骤来操作程序的进展。([这里](http://eli.thegreenplace.net/2011/01/23/how-debuggers-work-part-1.html) 有一个关于调试器如何工作的总体的解释。

It's likely that you have used a debugger before, even if only in Xcode's UI to add breakpoints. But with a few tricks, there are some pretty cool things that you can do. The [GDB to LLDB](http://lldb.llvm.org/lldb-gdb.html) reference is a great bird's-eye view of the available commands, and you might also want to install [Chisel](https://github.com/facebook/chisel), an open-source collection of LLDB plugins that make debugging even more fun!

你有可能已经使用过调试器，即使只是在xcode的界面上打一些断点。但是通过一些小的技巧，你可以做一些非常酷的事情。[GDB to LLDB](http://lldb.llvm.org/lldb-gdb.html)参考是一个非常好的调试器命令行的总览。你也可以安装[Chisel](https://github.com/facebook/chisel) ，它是一个开源的LLDB插件汇总，使调试更加有意思。


In the meantime, let's begin our journey and start with how to print variables in the debugger.

与此同时，让我们以在调试器中打印变量来开始我们的旅程吧。

## The Basics

## 基础

Here is a small, simple program that logs a string. Notice that a breakpoint has been added on line 8, which was made by clicking in the gutter in the source view in Xcode:

<img src="http://img.objccn.io/issue-19/Image_2014-11-20_at_10.01.46_PM.png" width="400" />

这里有一个简单的小程序，它会打印一个字符串。注意断点已经被加在第8行。断点是通过点击 xcode 的源码窗口的侧边槽创建的。

<img src="http://img.objccn.io/issue-19/Image_2014-11-20_at_10.01.46_PM.png" width="400" />

The program will pause its execution at that line and the console will open, allowing us to interact with the debugger. What shall we type?


程序会在这一行停止运行，并且控制台会被打开，允许我们和调试器交互。那我们应该打些什么呢？

### _help_

### _help_

The easiest command to try is `help`, which will list all the commands. And if you ever forget what a command does or want to know more, then you can read all the details with `help <command>`, e.g. `help print` or `help thread`. If you ever forget what the `help` command does, then you can try `help help`, but if you know enough to do that, then maybe you haven't entirely forgotten what the command does after all. &#128539;

最简单命令是 `help` ,它会列举出所有的命令。如果你忘记了一个命令是做什么的，或者想知道更多，你可以通过 `help <command>`，例如 `help print` 或者 `help thread `来了解更多细节。如果你甚至忘记了 `help`命令，你可以试试`help help`.不过如果知道这么做，那么你或许还没有忘光这个命令。&#128539;

### _print_

### _print_

Printing values is easy; just try the `print` command:

<img src="http://img.objccn.io/issue-19/Image_2014-11-20_at_10.09.38_PM.png" width="600" />

打印值很简单；只要试试 `print` 命令:

<img src="http://img.objccn.io/issue-19/Image_2014-11-20_at_10.09.38_PM.png" width="600" />

LLDB actually does prefix matching, so you would be fine to try `prin`, `pri`, or `p`. You can't use `pr`, since LLDB can't disambiguate it from the `process` command (luckily for us, `p` has been disambiguated).

LLDB实际上会作前缀匹配。所以你也可以使用`prin`,`pri`,或者`p`.但你不能使用`pr`, 因为LLDB不能消除和`process`的歧义（幸运的是，`p` 没有歧义）.

You'll also notice that the result has a `$0` in it. You can actually use this to reference the result! Try `print $0 + 7` and you'll see `106`. Anything starting with a dollar sign is in LLDB's namespace and exists to help you.


你或许会注意到，结果中有个 `$0`,实际上你可以使用它来指向这个结果。试试 `print $0 + 7`，你会看到 `106`。任何已美元符开头的东西都是存在于LLDB的命名空间的，其主要是为了帮助你而存在。

### _expression_

### _expression_

What if you want to modify a value? _Modify_, you say? Yes, modify! That's where the handy `expression` command comes in:

<img src="http://img.objccn.io/issue-19/Image_2014-11-20_at_10.15.01_PM.png" width="240" />

如果想改变一个值怎么办？你或许会猜_Modify_.是的，就是 modify。 这是`expression`命令的方便之处。

<img src="http://img.objccn.io/issue-19/Image_2014-11-20_at_10.15.01_PM.png" width="240" />

This doesn't just modify the value in the debugger. It actually modifies the value in the program! If you resume the program at this point, it will print `42 red balloons`. Magic.

这不仅会改变调试器中的值。实际上这改变了程序中的值。这时候继续执行程序，将会打印`42 red balloons`。神奇吧。

Note that from now on, we will be lazy with the number of characters, and replace `print` and `expression` with `p` and `e`, respectively.


注意，从现在开始，我们将会偷懒分别以`p`和`e`来代替`print`和`expression`。

### What is the _print_ Command?

### 什么是 _print_ 命令

Here's a fun expression to consider: `p count = 18`. If we execute that command and then print the contents of `count`, we’ll see that it behaves exactly as if we had run `expression count = 18`.

考虑一个有意思的表达式：`p count = 18`。如果我们运行这条命令，然后打印 `count` 的内容。我们将看到它表现得和我们运行了 `expression count = 18` 一样。

The difference is that the `print` command takes no arguments, unlike the `expression` command. Consider `e -h +17`. It is not clear if it means to execute `+17` as input, only with the `-h` flag, or if it intends to compute the difference between `17` and `h`. It finds that hyphen quite confusing indeed; you may not get the result that you like.

和 `expression` 不同的是，`print` 命令不需要参数。考虑 `e -h +17`,你很难区分是以 `+17` 为输入仅仅以`-h`标志，还是计算 `17` 和 `h` 的差值。连字符确实很让人困惑。你或许得不到自己想要的结果。

Luckily, the solution is quite simple. Use `--` to signify the end of the flags and the beginning of the input. Then if you want the `-h` flag, you would do `e -h -- +17`, and if you want the difference, you would do `e -- -h +17`. Since passing no flags is quite common, there is an alias for `e --`. It is called `print`.

幸运的是，解决方案很简单。用 `--` 来表征标示的结束，输入的开始。如果想要 `-h` 标示，就用`e -h -- +17`,如果想计算他们的差值，就是用  `e -- -h +17`。因为不使用标示是很常见的，所有 `e --`就有了一个 `print` 的别名。 

If you type `help print` and scroll all the way down, it will say:

    'print' is an abbreviation for 'expression --'.
    
打 `help print`,然后向下滚动。上面会写：

    'print' is an abbreviation for 'expression --'.   (print是 `expression --`的缩写)
    

### Printing Objects

### 打印对象

If we try

    p objects
    
尝试着打

    p objects

then the output is a bit verbose:

    (NSString *) $7 = 0x0000000104da4040 @"red balloons"
   
输出会有点啰嗦

    (NSString *) $7 = 0x0000000104da4040 @"red balloons"

It's even worse if we try to print a more complex structure:

    (lldb) p @[ @"foo", @"bar" ]

    (NSArray *) $8 = 0x00007fdb9b71b3e0 @"2 objects"
    
如果我们尝试打印结构更复杂的对象，结果甚至会更糟

    (lldb) p @[ @"foo", @"bar" ]

    (NSArray *) $8 = 0x00007fdb9b71b3e0 @"2 objects" 

Really, we want to see the `description` method of the object. We need to tell the `expression` command to print the result as an _object_, using the `-O` flag (that's an "oh"):

    (lldb) e -O -- $8
    <__NSArrayI 0x7fdb9b71b3e0>(
    foo,
    bar
    )
    
实际上，我们想看的是对象的 `description` 方法的结果。我么需要使用 `- O`（ `oh` 的简写）标志告诉`expression` 命令以 `对象` 来打印结果。 
    
    (lldb) e -O -- $8
    <__NSArrayI 0x7fdb9b71b3e0>(
    foo,
    bar
    )

Luckily, `e -O --` is aliased as `po` (for **p**rint **o**bject), and we can just use that:

    (lldb) po $8
    <__NSArrayI 0x7fdb9b71b3e0>(
    foo,
    bar
    )
    (lldb) po @"lunar"
    lunar
    (lldb) p @"lunar"
    (NSString *) $13 = 0x00007fdb9d0003b0 @"lunar"

    
幸运的是，`e -o --` 有个 `po` (**p**rint **o**bject 的缩写)的别名，我们可以使用它（来简化打字）：

    (lldb) po $8
    <__NSArrayI 0x7fdb9b71b3e0>(
    foo,
    bar
    )
    (lldb) po @"lunar"
    lunar
    (lldb) p @"lunar"
    (NSString *) $13 = 0x00007fdb9d0003b0 @"lunar"
    

### Print Variations

### 打印变量

There are many different formats that you can specify for the `print` command. They are written in the style `print/<fmt>`, or simply `p/<fmt>`. Following are some examples.

可以给`print` 指定不同的打印格式。它们都是以 `print/<fmt>` 或者简化的 `p/<fmt>` 格式书写。下面是一些例子：

The default format:

    (lldb) p 16
    16
    
默认的格式

    (lldb) p 16
    16

Hexadecimal:

    (lldb) p/x 16
    0x10  

十六进制:
   
    (lldb) p/x 16
    0x10

Binary (the `t` stands for **t**wo):

    (lldb) p/t 16
    0b00000000000000000000000000010000
    (lldb) p/t (char)16
    0b00010000
    
二进制 (`t` 代表 **t**wo)：

    (lldb) p/t 16
    0b00000000000000000000000000010000
    (lldb) p/t (char)16
    0b00010000

You can also do `p/c` for a character, or `p/s` for a string, as a null-terminated `char *`. [Here](https://sourceware.org/gdb/onlinedocs/gdb/Output-Formats.html) is the complete list of formats.

你也可以使用 `p/c` 打印字母,或者 `p/s` 打印以空终止的字符串(译者注：以 '\0' 结尾的字符串)。  
[这里](https://sourceware.org/gdb/onlinedocs/gdb/Output-Formats.html) 是格式的完整清单。

### Variables

### 变量

Now that you can print objects and simple types, and modify them in the debugger with the `expression` command, let's use some variables to reduce how much typing we need to do. Just as you might declare a variable in C as `int a = 0`, you can do the same thing in LLDB. However, to be used, the variable **must** start with a dollar sign:

    (lldb) e int $a = 2
    (lldb) p $a * 19
    38
    (lldb) e NSArray *$array = @[ @"Saturday", @"Sunday", @"Monday" ]
    (lldb) p [$array count]
    2
    (lldb) po [[$array objectAtIndex:0] uppercaseString]
    SATURDAY
    (lldb) p [[$array objectAtIndex:$a] characterAtIndex:0]
    error: no known method '-characterAtIndex:'; cast the message send to the method's return type
    error: 1 errors parsing expression

既然你已经可以打印对象和简单类型，并且知道如何使用 `expression` 命令在调试器中修改它们。让我们使用一些变量来减少打字量。就像你可以再 C 语言中像 `int a = 0` 这样声明一个变量一样，你也可以在LLDB中做同样的事情。不过为了能使用声明的变量，变量 **必须** 以美元符开头。

    (lldb) e int $a = 2
    (lldb) p $a * 19
    38
    (lldb) e NSArray *$array = @[ @"Saturday", @"Sunday", @"Monday" ]
    (lldb) p [$array count]
    2
    (lldb) po [[$array objectAtIndex:0] uppercaseString]
    SATURDAY
    (lldb) p [[$array objectAtIndex:$a] characterAtIndex:0]
    error: no known method '-characterAtIndex:'; cast the message send to the method's return type
    error: 1 errors parsing expression

Awww. LLDB couldn't figure out the types involved. This happens at times. Just give it a hint:

    (lldb) p (char)[[$array objectAtIndex:$a] characterAtIndex:0]
    'M'
    (lldb) p/d (char)[[$array objectAtIndex:$a] characterAtIndex:0]
    77
    
悲剧了，LLDB无法确定涉及的类型（译者注：返回的类型）。这种事情常常发生，给个说明就好了：

    (lldb) p (char)[[$array objectAtIndex:$a] characterAtIndex:0]
    'M'
    (lldb) p/d (char)[[$array objectAtIndex:$a] characterAtIndex:0]
    77

Variables make the debugger much easier to work with. Who would have thunk? &#128521;
    
变量使调试器变的更加容易使用。谁想得到呢？&#128521;
    

### Flow Control

### 流程控制

When you insert a breakpoint in the gutter in the source editor in Xcode (or add a breakpoint through one of the means below), the program will come to a stop when it hits the breakpoint.

当你通过xcode的源码编辑器的侧边槽(或者通过下面的方法加入一个断点) 插入一个断点，程序到达断点时会停止运行。

Then there are four buttons in the debug bar that you can use to control the flow of execution of the program:

<img src="http://img.objccn.io/issue-19/Image_2014-11-22_at_10.37.45_AM.png" width="200" />

调试条上会出现四个你可以用来控制程序的执行流程的按钮。

<img src="http://img.objccn.io/issue-19/Image_2014-11-22_at_10.37.45_AM.png" width="200" />

The buttons are, in order from left to right: continue, step over, step into, step out.

从左到右，四个按钮分别是：continue, step over, step into, step out。

The first, continue, will unpause the program and allow it to continue execution normally (perhaps forever, or until it hits another breakpoint). In LLDB, you can execute this command as `process continue`, which is aliased to `continue`, and thus, just `c`.

第一个，continue 按钮，会取消程序的暂停，允许程序正常执行（或者永远，或者到达下一个断点）。在 LLDB 中，你可以使用 `process continue` 来执行这个命令，别名为 `continue` ,因此也可以缩写为 `c`.

The second, step over, will execute a line of code as if it were a black box. If the line you are at is a function call, then it will **not** go inside the function, but instead execute the function and keep going. LLDB makes this available as `thread step-over`, `next`, or `n`.

第二个，step over 按钮，会以黑盒的方式执行一行代码。如果所在这行代码是一个函数，那么就**不会**跳进这个函数，而是会执行这个函数，然后继续。LLDB则可以使用`thread step-over`, `next`, 或者 `n`命令。

If you do want to step inside a function call in order to debug or examine its execution, then use the third button, step in, available in LLDB as `thread step-in`, `step`, and `s`. Notice that `next` and `step` behave the same when the current line of code is not a function call.

如果你确实想跳进一个函数调用来调试或者检查程序的执行情况，那就用第三个按钮，step in，或者在LLDB中使用 `thread step in `,`step`,或者 `s`命令。注意，当前行不是函数调用时，`next` 和 `step` 效果是一样的。

Most people know `c`, `n`, and `s`. But then there is the fourth button, step out. If you ever accidentally step into a function when you meant to step over it, then the typical response is to run `n` repeatedly until the function returns. Step out is your savior here. It will continue execution until the next `return` statement (until a stack frame is popped), and then stop again.


大多数人知道 `c`,`n`，和 `s`,但是其实还有第四个按钮，step out。如果你曾经不小心跳进一个函数，但实际上你想跳过它，常见的反应是重复的运行 `n` 直到函数返回。 这种情况，step out 按钮是你的救世主。它会继续执行，直到下一个返回语句（直到一个堆栈帧结束）才再次停止。

#### Example

#### 例子

Consider this partial program:

考虑下面一段程序：

<img src="http://img.objccn.io/issue-19/Image_2014-11-22_at_10.53.52_AM.png" width="320" />

<img src="http://img.objccn.io/issue-19/Image_2014-11-22_at_10.53.52_AM.png" width="320" />

Say we run the program, allow it to stop at the breakpoint, and then execute this sequence of commands:

    p i
    n
    s
    p i
    finish
    p i
    frame info
    
假如我们运行程序，让它停止在断点，然后执行下面一些列命令：

    p i
    n
    s
    p i
    finish
    p i
    frame info

Here, `frame info` will tell you the current line number and source file, among other things; look at `help frame`, `help thread`, and `help process` for more information. So what will the output be? Think about it before reading the answer!

	(lldb) p i
	(int) $0 = 99
	(lldb) n
	2014-11-22 10:49:26.445 DebuggerDance[60182:4832768] 101 is odd!
	(lldb) s
	(lldb) p i
	(int) $2 = 110
	(lldb) finish
	2014-11-22 10:49:35.978 DebuggerDance[60182:4832768] 110 is even!
	(lldb) p i
	(int) $4 = 99
	(lldb) frame info
	frame #0: 0x000000010a53bcd4 DebuggerDance`main + 68 at main.m:17
	
这里，`frame info` 或告诉你当前的行数和源码文件，以及其他一些信息；查看 `help frame`, `help thread`, and `help process`  来获得更多信息。结果会是什么？看答案之前想一想。

	(lldb) p i
	(int) $0 = 99
	(lldb) n
	2014-11-22 10:49:26.445 DebuggerDance[60182:4832768] 101 is odd!
	(lldb) s
	(lldb) p i
	(int) $2 = 110
	(lldb) finish
	2014-11-22 10:49:35.978 DebuggerDance[60182:4832768] 110 is even!
	(lldb) p i
	(int) $4 = 99
	(lldb) frame info
	frame #0: 0x000000010a53bcd4 DebuggerDance`main + 68 at main.m:17

The reason that it is still on line 17 is because the `finish` command ran until the `return` of the `isEven()` function, and then stopped immediately. Note that even though it is on line 17, it has already executed the line!

它始终在 17 行的原因是 `finish` 命令一直运行到 `isEven()` 函数的 `return`，然后立刻停止。注意即使它还在 17行，其实已经执行过这行。

#### Thread Return

#### Thread Return

There is one more awesome function that you can use to control program flow when debugging: `thread return`. It takes an optional argument, loads that into the return register, and immediately executes the return command, jumping out of the current stack frame. This means that the rest of the function **is not executed**. This could cause problems with ARC's reference counting/tracking, or prevent any cleanup you have inside a function. However, executing this command right at the start of a function is a great way to "stub" the function and fake it returning another value.

调试时，还有一个很棒的函数可以用来控制程序流程：`thread return` 。它有一个可选参数，把可选参数加载进返回寄存器，然后立刻执行返回命令，跳出当前栈帧。这意味这函数剩余的部分**不会被执行**。这会给 ARC 的引用计数造成一些问题，或者会使函数内的清理失效。但是在函数的开头执行这个命令，是个非常好的隔离这个函数，假造返回值的方式 。

Let's run a sightly modified set of commands with the same snippet of code above:

    p i
    s
    thread return NO
    n
    p even0
    frame info

让我们运行一个上面代码段的漂亮修改：

    p i
    s
    thread return NO
    n
    p even0
    frame info

Think about it before you read the answer. OK, here's the answer:

	(lldb) p i
	(int) $0 = 99
	(lldb) s
	(lldb) thread return NO
	(lldb) n
	(lldb) p even0
	(BOOL) $2 = NO
	(lldb) frame info
	frame #0: 0x00000001009a5cc4 DebuggerDance`main + 52 at main.m:17
	

看答案前思考一下。下面是答案：

	(lldb) p i
	(int) $0 = 99
	(lldb) s
	(lldb) thread return NO
	(lldb) n
	(lldb) p even0
	(BOOL) $2 = NO
	(lldb) frame info
	frame #0: 0x00000001009a5cc4 DebuggerDance`main + 52 at main.m:17

## Breakpoints

## 断点

We have all used breakpoints as a way to bring a program to a stop, inspect the current state, and hunt down bugs. But if we change our interpretation of breakpoints, a lot more becomes possible.

我们都把断点作为一个停止程序运行，检查当前状态，追踪 bug 的方式。但是如果我们改变和断点交互的方式，很多事情都变成可能。

> A breakpoint allows you to instruct a program when to stop, and then allows the running of commands.

Consider putting a breakpoint at the start of a function, using `thread return` to override the behavior of the function, and then continuing. Now imagine automating this process. Sounds yummy, doesn't it?

> 断点允许控制程序什么时候停止，然后允许命令的运行。

想象把断点放在函数的开头，然后用 `thread return ` 命令重写函数的行为，然后继续。想象自动化这个过程，听起来不错，不是吗？


### Managing Breakpoints

### 管理断点

Xcode offers a bunch of tools for creating and manipulating breakpoints. We'll go through each and describe the equivalent commands in LLDB that would create the same breakpoint (yes, you can add breakpoints from *inside* the debugger).

xcode 提供一系列工具来创建个管理断点。我们会一个个看过来并介绍 LLDB 中等价的命令（是的，你可以在调试器**内部**添加断点）。

In the left pane in Xcode, there is a collection of buttons. One looks like a breakpoint. Clicking it opens the breakpoint navigator, a pane where you can manipulate all of your breakpoints at a glance:

<img src="http://img.objccn.io/issue-19/Image_2014-11-22_at_11.38.24_AM.png" width="620" />

在 xcode 的左面板，有一组按钮。一个看起来像断点。点击它打开断点导航，一个可以快速管理所有断点的窗口。

<img src="http://img.objccn.io/issue-19/Image_2014-11-22_at_11.38.24_AM.png" width="620" />

Here you can see all of your breakpoints — `breakpoint list` (or `br li`) in LLDB. You can also click on an individual breakpoint to turn it on or off — `breakpoint enable <breakpointID>` and `breakpoint disable <breakpointID>` in LLDB:

	(lldb) br li
	Current breakpoints:
	1: file = '/Users/arig/Desktop/DebuggerDance/DebuggerDance/main.m', line = 16, locations = 1, resolved = 1, hit count = 1

	  1.1: where = DebuggerDance`main + 27 at main.m:16, address = 0x000000010a3f6cab, resolved, hit count = 1

	(lldb) br dis 1
	1 breakpoints disabled.
	(lldb) br li
	Current breakpoints:
	1: file = '/Users/arig/Desktop/DebuggerDance/DebuggerDance/main.m', line = 16, locations = 1 Options: disabled

	  1.1: where = DebuggerDance`main + 27 at main.m:16, address = 0x000000010a3f6cab, unresolved, hit count = 1

	(lldb) br del 1
	1 breakpoints deleted; 0 breakpoint locations disabled.
	(lldb) br li
	No breakpoints currently set.
	
这里你可以看到所有的断点 - 在 LLDB 中通过 `breakpoint list` (或者 `br li`) 命令。你也可以点击单个断点来开启或关闭 - 在 LLDB 中使用 `breakpoint enable <breakpointID>` 和 `breakpoint disable <breakpointID>`：

	(lldb) br li
	Current breakpoints:
	1: file = '/Users/arig/Desktop/DebuggerDance/DebuggerDance/main.m', line = 16, locations = 1, resolved = 1, hit count = 1

	  1.1: where = DebuggerDance`main + 27 at main.m:16, address = 0x000000010a3f6cab, resolved, hit count = 1

	(lldb) br dis 1
	1 breakpoints disabled.
	(lldb) br li
	Current breakpoints:
	1: file = '/Users/arig/Desktop/DebuggerDance/DebuggerDance/main.m', line = 16, locations = 1 Options: disabled

	  1.1: where = DebuggerDance`main + 27 at main.m:16, address = 0x000000010a3f6cab, unresolved, hit count = 1

	(lldb) br del 1
	1 breakpoints deleted; 0 breakpoint locations disabled.
	(lldb) br li
	No breakpoints currently set.

### Creating Breakpoints

### 创建断点

In the example we have been using, we clicked on "16" in the gutter in the source view to create a breakpoint. To remove it, you can drag the breakpoint out of the gutter and let go of the mouse (it will vanish with a cute poof animation). You can also select a breakpoint in the breakpoint navigator and then press the delete key to remove it.

在上面的例子中，我们通过在源码页面器的滚槽 `16` 上点击来创建断点。你可以通过把断点拖拽出滚槽，然后释放鼠标来删除断点（消失时会有一个非常可爱的动画）。你也可以在断点导航页选择断点，然后按下删除键删除。

To create a breakpoint in the debugger, use the `breakpoint set` command:

	(lldb) breakpoint set -f main.m -l 16
	Breakpoint 1: where = DebuggerDance`main + 27 at main.m:16, address = 0x000000010a3f6cab
	
使用 `breakpoint set` 命令在调试器中创建断点。

	(lldb) breakpoint set -f main.m -l 16
	Breakpoint 1: where = DebuggerDance`main + 27 at main.m:16, address = 0x000000010a3f6cab

The shortest abbreviation you can use is `br`. As it turns out, `b` is an entirely different command (an alias for `_regexp-break`), but it is robust enough to allow the same breakpoint as above:

    (lldb) b main.m:17
    Breakpoint 2: where = DebuggerDance`main + 52 at main.m:17, address = 0x000000010a3f6cc4
    
也可以使用缩写形式 `br`，即使 `b` 是一个完全不同的命令（`_regexp-break` 的缩写），也可以实现上面同样的效果。

    (lldb) b main.m:17
    Breakpoint 2: where = DebuggerDance`main + 52 at main.m:17, address = 0x000000010a3f6cc4

You can also put a breakpoint on a symbol (a C function), without having to specify the line number:

	(lldb) b isEven
	Breakpoint 3: where = DebuggerDance`isEven + 16 at main.m:4, address = 0x000000010a3f6d00
	(lldb) br s -F isEven
	Breakpoint 4: where = DebuggerDance`isEven + 16 at main.m:4, address = 0x000000010a3f6d00
	
也可以在一个符号(c 语言函数)上创建断点，而完全不用指定哪一行 

	(lldb) b isEven
	Breakpoint 3: where = DebuggerDance`isEven + 16 at main.m:4, address = 0x000000010a3f6d00
	(lldb) br s -F isEven
	Breakpoint 4: where = DebuggerDance`isEven + 16 at main.m:4, address = 0x000000010a3f6d00

These breakpoints will now stop exactly at the start of the function, and this works for Objective-C methods too:

	(lldb) breakpoint set -F "-[NSArray objectAtIndex:]"
	Breakpoint 5: where = CoreFoundation`-[NSArray objectAtIndex:], address = 0x000000010ac7a950
	(lldb) b -[NSArray objectAtIndex:]
	Breakpoint 6: where = CoreFoundation`-[NSArray objectAtIndex:], address = 0x000000010ac7a950
	(lldb) breakpoint set -F "+[NSSet setWithObject:]"
	Breakpoint 7: where = CoreFoundation`+[NSSet setWithObject:], address = 0x000000010abd3820
	(lldb) b +[NSSet setWithObject:]
	Breakpoint 8: where = CoreFoundation`+[NSSet setWithObject:], address = 0x000000010abd3820
	
这些断点会准确的停止在函数的开始。Objective-C 的方法也完全可以：

	(lldb) breakpoint set -F "-[NSArray objectAtIndex:]"
	Breakpoint 5: where = CoreFoundation`-[NSArray objectAtIndex:], address = 0x000000010ac7a950
	(lldb) b -[NSArray objectAtIndex:]
	Breakpoint 6: where = CoreFoundation`-[NSArray objectAtIndex:], address = 0x000000010ac7a950
	(lldb) breakpoint set -F "+[NSSet setWithObject:]"
	Breakpoint 7: where = CoreFoundation`+[NSSet setWithObject:], address = 0x000000010abd3820
	(lldb) b +[NSSet setWithObject:]
	Breakpoint 8: where = CoreFoundation`+[NSSet setWithObject:], address = 0x000000010abd3820

If you want to create a symbolic breakpoint in Xcode's UI, then click the `+` button at the bottom left of the breakpoint navigator:

<img src="http://img.objccn.io/issue-19/Image_2014-11-22_at_11.52.50_AM.png" width="300" />

如果想在 xcode 的UI上创建符号断点，你可以点击断点栏左侧的 `+` 按钮。

<img src="http://img.objccn.io/issue-19/Image_2014-11-22_at_11.52.50_AM.png" width="300" />

Then choose the third option:

<img src="http://img.objccn.io/issue-19/Image_2014-11-22_at_11.54.44_AM.png" width="430" />

然后选择第三个选项：

<img src="http://img.objccn.io/issue-19/Image_2014-11-22_at_11.54.44_AM.png" width="430" />

A popover will appear where you can enter in a symbol such as `-[NSArray objectAtIndex:]`, and then the breakpoint will cause the program to stop **any time** that method is called, whether from your code or Apple's!

在可以添加符号断点的地方，例如 `-[NSArray objectAtIndex:]`，会出现一个弹出框。这样**每次**调用这个函数的时候，程序都会停止，不管是你调用还是苹果调用。

If we look at the other options, we can see that there are some enticing options, which are also available for **any** breakpoint if you right click it in Xcode's UI and select the "Edit Breakpoint" option:

<img src="http://img.objccn.io/issue-19/Image_2014-11-22_at_11.58.06_AM.png" width="570" />

如果你正确的在 Xcode 的UI 上点击 然后选择 "Edit Breakpoint" 选项，看看其他的选项，有一些适用所有断点的选项，也都非常诱人。

<img src="http://img.objccn.io/issue-19/Image_2014-11-22_at_11.58.06_AM.png" width="570" />

Here, the breakpoint has been modified to **only** stop when `i` is `99`. You can also use the "ignore" option to tell the breakpoint to not stop the first `n` times it is called (and the condition is true).

这里，断点已经被修改为**只有**当`i` 是 `99` 的时候才会停止。你也可以使用 "ignore" 选项来告诉断点最初的  `n` 被调用的时候不要停止(并且条件为真的时候)。

And then there is that "Add Action" button...

接下来是 'Add Action' 按钮。

### Breakpoint Actions

### 断点 actions

Perhaps in the example breakpoint above, you want to know the value of `i` every time the breakpoint is hit. We can use the action `p i`, and then when the breakpoint is hit and we enter the debugger, it will execute that command before giving you control:

<img src="http://img.objccn.io/issue-19/Screen_Shot_2014-11-22_at_12.01.32_PM.png" width="600" />

上面的例子中，你或许想知道每一次到达断点的时候 `i` 的值。我们可以使用 `p i` action ，这样每次到达断点的时候，都会自动运行这个命令。

<img src="http://img.objccn.io/issue-19/Screen_Shot_2014-11-22_at_12.01.32_PM.png" width="600" />

You can also add multiple actions, which can be debugger commands, shell commands, or more robust printing:

<img src="http://img.objccn.io/issue-19/Image_2014-11-22_at_12.06.34_PM.png" width="400" />

你也可以添加多个 action，可以是调试器命令，shell 命令，也可以是更粗鲁的打印：

<img src="http://img.objccn.io/issue-19/Screen_Shot_2014-11-22_at_12.01.32_PM.png" width="600" />

You can see that it printed `i`, then it said that sentence aloud (!), and then printed the custom expression.

可以看到它打印 `i`,然后大声念出那个句子。接着自定义的表达式。

Here's what some of this looks like when done in LLDB instead of Xcode's UI:

	(lldb) breakpoint set -F isEven
	Breakpoint 1: where = DebuggerDance`isEven + 16 at main.m:4, address = 0x00000001083b5d00
	(lldb) breakpoint modify -c 'i == 99' 1
	(lldb) breakpoint command add 1
	Enter your debugger command(s).  Type 'DONE' to end.
	> p i
	> DONE
	(lldb) br li 1
	1: name = 'isEven', locations = 1, resolved = 1, hit count = 0
	    Breakpoint commands:
	      p i

	Condition: i == 99

	  1.1: where = DebuggerDance`isEven + 16 at main.m:4, address = 0x00000001083b5d00, resolved, hit count = 0 

下面是在 LLDB 而不是 Xcode 的 UI 中做这些的时候，看起来的样子。

	(lldb) breakpoint set -F isEven
	Breakpoint 1: where = DebuggerDance`isEven + 16 at main.m:4, address = 0x00000001083b5d00
	(lldb) breakpoint modify -c 'i == 99' 1
	(lldb) breakpoint command add 1
	Enter your debugger command(s).  Type 'DONE' to end.
	> p i
	> DONE
	(lldb) br li 1
	1: name = 'isEven', locations = 1, resolved = 1, hit count = 0
	    Breakpoint commands:
	      p i

	Condition: i == 99

	  1.1: where = DebuggerDance`isEven + 16 at main.m:4, address = 0x00000001083b5d00, resolved, hit count = 0 

Automation, here we come!

自动化，我们来了。

### Continuing after Evaluation

### 赋值后继续运行

If you look at the bottom of the edit breakpoint popover, you'll see one more option: *"Automatically continue after evaluation actions."* It's just a checkbox, but it holds immense power. If you check it, the debugger will evaluate all of your commands and then continue running the program. It won't even be apparent that it executed the breakpoint at all (unless the breakpoint fires a lot and your commands take a while, in which case, your program will slow down). 

看编辑断点弹出窗口的底部，你还会看到一个选项： *"Automatically continue after evaluation actions."*  。它仅仅是一个复选框，但是很强大。选中他，调试器会运行你所有的命令，然后继续运行。看起来就像没有执行任何断点一样（除非断点太多，运行需要一段时间，拖慢了你的程序）。

This checkbox is the same as having the last breakpoint action be `continue`, but having a checkbox just makes it easier. And here it is in the debugger:

	(lldb) breakpoint set -F isEven
	Breakpoint 1: where = DebuggerDance`isEven + 16 at main.m:4, address = 0x00000001083b5d00
	(lldb) breakpoint command add 1
	Enter your debugger command(s).  Type 'DONE' to end.
	> continue
	> DONE
	(lldb) br li 1
	1: name = 'isEven', locations = 1, resolved = 1, hit count = 0
	    Breakpoint commands:
	      continue

	  1.1: where = DebuggerDance`isEven + 16 at main.m:4, address = 0x00000001083b5d00, resolved, hit count = 0
	 
这个选项框的效果和让最后一个断点 action `继续` 运行一样。复选框只是让这个变得更简单。调试器的输出是：

	(lldb) breakpoint set -F isEven
	Breakpoint 1: where = DebuggerDance`isEven + 16 at main.m:4, address = 0x00000001083b5d00
	(lldb) breakpoint command add 1
	Enter your debugger command(s).  Type 'DONE' to end.
	> continue
	> DONE
	(lldb) br li 1
	1: name = 'isEven', locations = 1, resolved = 1, hit count = 0
	    Breakpoint commands:
	      continue

	  1.1: where = DebuggerDance`isEven + 16 at main.m:4, address = 0x00000001083b5d00, resolved, hit count = 0
	  
Automatically continuing after evaluating a breakpoint allows you to modify your program solely through the use of breakpoints! You could stop at a line, run an `expression` command to change a variable, and then continue.

执行断点后自动继续运行，允许你完全通过断点来修改程序！你可以在某一行停止，运行一个 `语句` 来改变变量，然后继续运行。

#### Examples

#### 例子

Consider the infamous "print-debug" technique. Instead of

    NSLog(@"%@", whatIsInsideThisThing);
    
想想臭名昭著的"打印调试"技术,不要：

    NSLog(@"%@", whatIsInsideThisThing);
    
replace this log statement with a breakpoint that prints the variable and then continues.

而是用个打印变量的断点替换 log 语句，然后继续运行。
    
Instead of
    
	int calculateTheTrickyValue {
	  return 9;
	  
	  /*
	   Figure this out later.
	   ...
    }
    
不要：

	int calculateTheTrickyValue {
	  return 9;
	  
	  /*
	   Figure this out later.
	   ...
    }
    
add a breakpoint that uses `thread return 9` and then have it continue.

而是加一个使用 `thread return 9` 命令的断点，然后让他继续运行。

Symbolic breakpoints with actions are really powerful. You can also add them to your friends' Xcode projects and have actions that speak things aloud. See how long it takes them to figure out what is going on. &#128516;  
 
符号断点加上 action 真的很强大。你也可以在你朋友的 Xcode 工程上添加一些断点。然后加上一些很强大的 action。看看他们花多久可以弄明白发生了什么。&#128516;

### Full Execution in the Debugger

### 完全在调试器内运行

There is one more idea to look at before we start dancing. You really can run just about any C/Objective-C/C++/Swift command in the debugger. The one weak spot is that it cannot create new functions... which means no new classes, blocks, functions, C++ classes with virtual methods, etc. Other than that, it can do it all!

带开始舞蹈之前，还有一件事要看一看。实际上你可以在调试器中执行任何 C/Objective-C/C++/Swift 的命令。唯一的缺点就是不能创建新函数... 这意味着不能创建新的类，block,函数，有虚拟函数的 C++ 类。除此之外，它都可以做。

We can malloc some bytes:

	(lldb) e char *$str = (char *)malloc(8)
	(lldb) e (void)strcpy($str, "munkeys")
	(lldb) e $str[1] = 'o'
	(char) $0 = 'o'
	(lldb) p $str
	(char *) $str = 0x00007fd04a900040 "monkeys"
	
我们可以申请分配一些字节：

	(lldb) e char *$str = (char *)malloc(8)
	(lldb) e (void)strcpy($str, "munkeys")
	(lldb) e $str[1] = 'o'
	(char) $0 = 'o'
	(lldb) p $str
	(char *) $str = 0x00007fd04a900040 "monkeys"
	
Or we can inspect some memory (using the `x` command) to see **4 bytes** of our new array:

	(lldb) x/4c $str
	0x7fd04a900040: monk
	
我们可以查看内存（使用 `x` 命令），来看看新数组中的四个字节：

	(lldb) x/4c $str
	0x7fd04a900040: monk
	
We can also look 3 bytes down (the `x` command requires backticks, since it only takes a memory address and not actually an expression; see `help x` for more information):
	
	(lldb) x/1w `$str + 3`
	0x7fd04a900043: keys
	
我们也可以去掉3个字节( `x` 命令需要斜引号，因为它只有一个内存地址的参数，而不是表达式使用 `help x` 来获得更多信息）：。
	
	(lldb) x/1w `$str + 3`
	0x7fd04a900043: keys

But when you are all done, be sure to free the memory so that you don't leak (lol... we are in the debugger):

	(lldb) e (void)free($str)

做完了之后，一定不要忘了释放内存，这样才不会内存泄露。(额，我们在调试器中)：

	(lldb) e (void)free($str)
    
## Let's Dance

Now that we know the basic steps, it's time to dance and do some crazy things. I once wrote a blog post on [looking at the internals of `NSArray`](http://arigrant.com/blog/2014/1/19/adventures-in-the-land-of-nsarray). The post uses a lot of `NSLog` statements, but I actually did all the exploration in the debugger. It may be a fun exercise to see if you can figure out how.

## 让我们起舞

已经知道基本的步骤，是时候跳舞和玩一些疯狂的事情了。我曾经写过一篇[looking at the internals of `NSArray`](http://arigrant.com/blog/2014/1/19/adventures-in-the-land-of-nsarray)的博客 。这篇博客用了 很多`NSLog` 语句，实际上我实在调试器中做了所有的探索。看看你能不能弄明白怎么做的，这可能是一个有意思的测试。

### Poking around without a Breakpoint

### 不用断点调试

When an application is running, the debug bar in Xcode's UI shows a pause button instead of a continue one:

<img src="http://img.objccn.io/issue-19/Screen_Shot_2014_11_22_at_1_50_56_PM.png" width="300" />


程序运行时，Xcode 的调试条上出现暂停按钮，而不是继续按钮：

<img src="http://img.objccn.io/issue-19/Screen_Shot_2014_11_22_at_1_50_56_PM.png" width="300" />

Clicking that button will pause the app (it runs `process interrupt`, since LLDB is always attached behind the scenes). This will then give you access to the debugger, but it might not look like you can do much, since there are no variables in scope, and there is no specific area of the code to look at.

点击按钮会暂 app（这会运行 `process interrupt` 命令，因为 LLDB 总是在背后运行）。这会让你可以访问调试器。但看起来可以做的事情不多，因为在当前作用域没有变量，也没有特定的代码让你看。

That's where things get fun. If you are running an iOS app, you could try this (since globals are available)

    (lldb) po [[[UIApplication sharedApplication] keyWindow] recursiveDescription]
    <UIWindow: 0x7f82b1fa8140; frame = (0 0; 320 568); gestureRecognizers = <NSArray: 0x7f82b1fa92d0>; layer = <UIWindowLayer: 0x7f82b1fa8400>>
       | <UIView: 0x7f82b1d01fd0; frame = (0 0; 320 568); autoresize = W+H; layer = <CALayer: 0x7f82b1e2e0a0>>
       
这就是有意思的地方。如果你正在运行IOS app ,你可以试试这个：（因为全局变量是可访问的）
        
        (lldb) po [[[UIApplication sharedApplication] keyWindow] recursiveDescription]
    <UIWindow: 0x7f82b1fa8140; frame = (0 0; 320 568); gestureRecognizers = <NSArray: 0x7f82b1fa92d0>; layer = <UIWindowLayer: 0x7f82b1fa8400>>
       | <UIView: 0x7f82b1d01fd0; frame = (0 0; 320 568); autoresize = W+H; layer = <CALayer: 0x7f82b1e2e0a0>>
       
and see the entire hierarchy! [Chisel](https://github.com/facebook/chisel) implements this as `pviews`.
       
你可以看到整个层次。[Chisel](https://github.com/facebook/chisel) 中 `pviews`. 实现这个功能。
       

### Updating the UI

### 更新UI

Then, given the above output, we could stash the view:

    (lldb) e id $myView = (id)0x7f82b1d01fd0
    
有了上面的输出，我们可以获取这个 view：

    (lldb) e id $myView = (id)0x7f82b1d01fd0

Then modify it in the debugger to change its background color:

    (lldb) e (void)[$myView setBackgroundColor:[UIColor blueColor]]
    
然后在 debugger 中改变他的背景色：
 
    (lldb) e (void)[$myView setBackgroundColor:[UIColor blueColor]]
    
However, you won't see any changes until you continue the program again. This is because the changes need to be sent over to the render server and then the display will be updated.

但是只有程序继续运行之后才会看到界面的变化。因为改变的内容必须被发送到 render server 然后显示才会被更新。

The render server is actually another process (called `backboardd`), and even though the containing process of what we are debugging is interrupted, `backboardd` is not!

render server 实际上在另外的进程（被称作 `backboardd`）。即使我们正在调试的内容所在进程被打断了,`backboardd` 也不会。

This means that without continuing, you can execute the following:

    (lldb) e (void)[CATransaction flush]
    
这意味着你可以运行下面的命令，而不用继续运行程序，：

    (lldb) e (void)[CATransaction flush]
    
The UI will update live in the simulator or on the device while you are still in the debugger! [Chisel](https://github.com/facebook/chisel) provides an alias for this called `caflush`, and it is used to implement other shortcuts like `hide <view>`, `show <view>`, and many, many others. All of [Chisel](https://github.com/facebook/chisel)'s commands have documentation, so feel free to run `help show` after installing it to see more information. 
    
即使你仍然在调试器中，UI也会在模拟器或者真机上实时更新。[Chisel](https://github.com/facebook/chisel) 为此提供了一个别名叫做 `caflush`，这个命令被用来实现其他的快捷命令，例如 `hide <view>`, `show <view>` 以及其他很多命令。所有[Chisel](https://github.com/facebook/chisel)'s 的命令都有文档，所以安装后随意运行 `help show` 来看更多信息。

### Pushing a View Controller

### pushing 一个 View Controller

Imagine a simple application with a `UINavigationController` at the root. You could get it pretty easily in the debugger by executing the following:

    (lldb) e id $nvc = [[[UIApplication sharedApplication] keyWindow] rootViewController]
    
想象一个以`UINavigationController` 为 root ViewController 的应用。你可以通过下面的命令，轻松地获取它：
    
    (lldb) e id $nvc = [[[UIApplication sharedApplication] keyWindow] rootViewController]
    
Then push a child view controller:

    (lldb) e id $vc = [UIViewController new]
    (lldb) e (void)[[$vc view] setBackgroundColor:[UIColor yellowColor]]
    (lldb) e (void)[$vc setTitle:@"Yay!"]
    (lldb) e (void)[$nvc pushViewContoller:$vc animated:YES]
    
然后 push 一个 child view controller:
 
    (lldb) e id $vc = [UIViewController new]
    (lldb) e (void)[[$vc view] setBackgroundColor:[UIColor yellowColor]]
    (lldb) e (void)[$vc setTitle:@"Yay!"]
    (lldb) e (void)[$nvc pushViewContoller:$vc animated:YES]
    
Finally, execute the following:

    (lldb) caflush // e (void)[CATransaction flush]
    
最后运行下面的命令：

    (lldb) caflush // e (void)[CATransaction flush]
    
You will see the navigation controller pushed right before your very eyes!
   
navigation Controller 就会立刻就被 push 到你眼前。

### Finding the Target of a Button

### 查找按钮的 target

Imagine you have a variable in the debugger, `$myButton`, that you got from creating it, grabbing it from the UI, or simply having it as a variable in scope when you are stopped at a breakpoint. You might wonder who receives the actions when you tap on it. Here's how easy it is:

	(lldb) po [$myButton allTargets]
	{(
	    <MagicEventListener: 0x7fb58bd2e240>
	)}
	(lldb) po [$myButton actionsForTarget:(id)0x7fb58bd2e240 forControlEvent:0]
	<__NSArrayM 0x7fb58bd2aa40>(
	_handleTap:
	)
	
想象你在调试器中有一个 `$myButton` 的变量，可以是创建出来的，也可以是从 UI 上抓取出来的，或者是你停止在断点时的一个局部变量。你想知道，按钮按下的时候谁会接受到 actions.非常简单：
    
	(lldb) po [$myButton allTargets]
	{(
	    <MagicEventListener: 0x7fb58bd2e240>
	)}
	(lldb) po [$myButton actionsForTarget:(id)0x7fb58bd2e240 forControlEvent:0]
	<__NSArrayM 0x7fb58bd2aa40>(
	_handleTap:
	)


Now you might want to add a breakpoint for when that happens. Just set a symbolic breakpoint on `-[MyEventListener _handleTap:]`, in LLDB or Xcode, and you are all set to go!

现在你或许想加一个断点来搞清楚什么时候会发生。在 `-[MyEventListener _handleTap:]` 设置一个符号断点就可以了，在xcode和LLDB中都可以，所有的都设置好了。

### Observing an Instance Variable Changing

### 观察实例变量的变化

Imagine a hypothetical case where you have a `UIView` that was somehow having its `_layer` instance variable being overwritten (uh oh!). Since there might not be a method involved, we can't use a symbolic breakpoint. Instead, we want to *watch* when an address is written to.

假设你有一个 `UIView`，不知道为什么它的 `_layer` 实例变量被重写了（糟糕）。因为有可能并不涉及到方法，我们不能使用符号断点。相反的，我们想 `观察` 什么时候这个地址被写入

First we would need to find out where in the object the "_layer" ivar is:

    (lldb) p (ptrdiff_t)ivar_getOffset((struct Ivar *)class_getInstanceVariable([MyView class], "_layer"))
    (ptrdiff_t) $0 = 8
    
首先，我们需要找到 `_layer` 这个变量在对象上的相对位置：

    (lldb) p (ptrdiff_t)ivar_getOffset((struct Ivar *)class_getInstanceVariable([MyView class], "_layer"))
    (ptrdiff_t) $0 = 8
    
Now we know that `($myView + 8)` is the memory address being written to:

	(lldb) watchpoint set expression -- (int *)$myView + 8
	Watchpoint created: Watchpoint 3: addr = 0x7fa554231340 size = 8 state = enabled type = w
	    new value: 0x0000000000000000
	    
现在我们知道 `($myView + 8)` 是被写入的内存地址：
    
	(lldb) watchpoint set expression -- (int *)$myView + 8
	Watchpoint created: Watchpoint 3: addr = 0x7fa554231340 size = 8 state = enabled type = w
	    new value: 0x0000000000000000
	    
This was added to [Chisel](https://github.com/facebook/chisel) as `wivar $myView _layer`.

这被以 `wivar $myView _layer` 加入到[Chisel](https://github.com/facebook/chisel)中 。

### Symbolic Breakpoints on Non-Overridden Methods

### 非重写方法的符号断点。

Imagine that you want to know when `-[MyViewController viewDidAppear:]` is called. What would happen if `MyViewController` didn't actually implement that method, but its superclass did? We can try setting a breakpoint and see:

	(lldb) b -[MyViewController viewDidAppear:]
	Breakpoint 1: no locations (pending).
	WARNING:  Unable to resolve breakpoint to any actual locations.
	
假设你想知道 `-[MyViewController viewDidAppear:]` 什么时候被调用。如果这个方法并没有在`MyViewController` 中实现，而是在其父类中实现的，该怎么办呢？试着设置一个断点，会出现以下结果：
    
	(lldb) b -[MyViewController viewDidAppear:]
	Breakpoint 1: no locations (pending).
	WARNING:  Unable to resolve breakpoint to any actual locations.
	
Since LLDB is looking for a *symbol*, it won't find it, and your breakpoint will never fire. What you need to do is set a condition, `[self isKindofClass:[MyViewController class]]`, and then put the breakpoint on `UIViewController`. Normally, setting a condition like this will work, however, here it doesn’t since we don’t own the implementation of the superclass.

因为LLDb会查找一个 *符号* ,但是找不到，断点也永远不会触发。你需要做的是设置一个条件，`[self isKindofClass:[MyViewController class]]` 然后把断点放在 `UIViewController` 上。正常情况下这样设置一个条件可以正常工作。但是这里不会，因为我们没有父类的实现。

`viewDidAppear:` is a method that Apple wrote, and thus, there are no symbols for it; there is no `self` when inside that method. If you wanted to use `self` in a symbolic breakpoint, you would have to know where it is (it could be in the registers or on the stack; in x86 you’ll find it at `$esp+4`). This is a pain though, because there are already at least four architectures you’d have to know (x86, x86-64, armv7, armv64). Oof! You can imagine taking the time to learn the instruction set and [calling convention](http://en.m.wikipedia.org/wiki/Calling_convention) for each one, and then writing a command that will set a breakpoint for you on the correct super class and with the correct condition. Luckily, this has already been done in [Chisel](https://github.com/facebook/chisel), and is called `bmessage`:


	(lldb) bmessage -[MyViewController viewDidAppear:]
	Setting a breakpoint at -[UIViewController viewDidAppear:] with condition (void*)object_getClass((id)$rdi) == 0x000000010e2f4d28
	Breakpoint 1: where = UIKit`-[UIViewController viewDidAppear:], address = 0x000000010e11533c
	
`viewDidAppear:` 是苹果实现的方法，因此没有它的符号；在方法内没有 `self` 。如果想使用 `self` ，你必须知道他在那里（它可能在寄存器上，也可能在栈上；在 x86 上，你可以在 `$esp+4` 找到它）。但是这是很痛苦的，因为你必须至少知道四种体系结构(x86,x86-64,armv7,armv64)。想象你需要花多少时间去学习命令集以及他们每一个的[约定调用](http://en.m.wikipedia.org/wiki/Calling_convention)，然后正确的写一个在你的超类上设置断点并且条件正确的命令。幸运的是，这个在 [Chisel](https://github.com/facebook/chisel) 被解决了。这被成为`bmessage`:

	(lldb) bmessage -[MyViewController viewDidAppear:]
	Setting a breakpoint at -[UIViewController viewDidAppear:] with condition (void*)object_getClass((id)$rdi) == 0x000000010e2f4d28
	Breakpoint 1: where = UIKit`-[UIViewController viewDidAppear:], address = 0x000000010e11533c

### LLDB and Python

### LLDB 和 python

LLDB has full, built-in [Python support](http://lldb.llvm.org/python-reference.html). If you type `script` in LLDB, it will open a Python REPL. If you type `script` in LLDB, it will open a Python REPL. You can also pass a line of Python to the `script command` and have it executed without entering the REPL:

    (lldb) script import os
    (lldb) script os.system("open http://www.objc.io/")
    
LLDB 有一个完全的，内建的[Python 支持](http://lldb.llvm.org/python-reference.html).在LLDB中打入 `script`，它会打开一个 python REPL。你也可以输入一行 python 语句到 `script 命令` 这样就可以运行代码而不进入REPL:

    (lldb) script import os
    (lldb) script os.system("open http://www.objc.io/")
    
This allows you to create all sorts of cool commands. Put this in a file, `~/myCommands.py`:

    def caflushCommand(debugger, command, result, internal_dict):
      debugger.HandleCommand("e (void)[CATransaction flush]")
      
这样就允许你创造各种酷的命令。把下面的语句放到文件 `~/myCommands.py` 中：

    def caflushCommand(debugger, command, result, internal_dict):
      debugger.HandleCommand("e (void)[CATransaction flush]")

Then, in LLDB, run the following:

    command script import ~/myCommands.py
    
然后再LLDB中运行：

    command script import ~/myCommands.py
    
Or, put the line in `/.lldbinit` to have it executed every time LLDB starts. [Chisel](https://github.com/facebook/chisel) is nothing more than a collection of Python scripts that concatenate strings, and then tells LLDB to execute them. Simple, huh?

或者把这行命令放在 `/.lldbinit` 里，这样每次进入LLDB中都会自动运行。[Chisel](https://github.com/facebook/chisel)是一个python脚本的集合，这些脚本拼接（命令）字符串 ，然后让 LLDB 执行。很简单，不是吗？
      

## Wield the Debugger

## 使用调试器

There is a lot that LLDB is capable of. Most of us are used to `p`, `po`, `n`, `s`, and `c`, but there is so much more it can do. Mastering all of its commands (there really are not that many) will give you so much more power in unraveling the runtime behavior of your code, finding bugs, forcing specific execution paths, and even prototyping simple interacts — what would happen if a modal view controller opened right now? Try it!

LLDB可以做的又很多。大多数人习惯于使用 `p`,`po`,`n`,`s`,和 `c`,但实际上LLDB可以做的还有很多。掌握所有的命令(实际上也不是很多),会让你在解开代码运行时的运行状态，找bug，强制执行特定的运行路径时获得更大的能力，甚至于构建简单的交互原型 - 一个Model view Controller 现在打开怎么样？试一试吧。

This article was meant to show you a glimpse of the full power that it has and encourage you to be a bit more adventurous with what you type into the console.

这篇文章是为了想你展示 LLDB 的强大之处，并且鼓励你多去探索在控制台打得命令。

Open up LLDB, type `help`, and see the list of all of the commands. How many have you tried? How many do you use?

打开LLDB，打 `help` ，看一看列举的命令。你尝试过多少？用了多少？

Hopefully `NSLog` doesn't really seem that cool any more. At least it had a run for a while.

但愿 `NSLog` 看起来不再那么神奇。至少那必须运行一会儿。

Happy debugging!

调试愉快！

