Few have heard of DTrace, a little gem tucked away somewhere inside the OS. It's a debugging power tool — powerful because it's extremely flexible, and probably relatively unknown because it is so very different from other tools out there.

Quite often, real users or testers of your app will see some unexpected behavior. DTrace lets you answer arbitrary questions about the app, on a production version of the app, and without relaunching the app.

很少有人听过 DTrace，它是隐藏在 OS 中的小宝藏。DTrace 是强大的 debug 工具 - 因为极其灵活的特性。并且因为与其它工具差异很大而可能相对不那么有名。

许多时候你的 app 的真正的用户或测试人员会看到一些意外的行为。DTrace 可以让你无需重启 app 就能够在生产版本上回答关于 app 的任何问题。



## Dynamic Tracing

## 动态追踪

Almost 10 years ago, [Sun Microsystems](https://en.wikipedia.org/wiki/Sun_Microsystems) built DTrace, short for *Dynamic Trace*. And at the end of 2007, Apple integrated it into its [operating system](https://en.wikipedia.org/wiki/Mac_OS_X_Leopard).

大概 10 年前，[Sun Microsystems](https://en.wikipedia.org/wiki/Sun_Microsystems) 创建了 DTrace，它的名字是 *Dynamic Trace* 的缩写。2007 年底，苹果公司将它集成在自己的 [操作系统](https://en.wikipedia.org/wiki/Mac_OS_X_Leopard) 中。

DTrace is a dynamic tracing framework that provides *zero disable cost*, i.e. probes in code have no overhead when disabled — we can leave the probes in our code even for production builds. You only pay the cost of the probe when using it.

DTrace 是一个提供了 *zero disable cost* 的动态追踪框架，也就是说当代码中的探针关闭时没有额外的资源消耗 - 即使在生产版本中我们也可以将探针留在代码中。只有使用的时候才产生消耗。

DTrace is *dynamic*, which means that we can attach to an already running program and detach from it again without interrupting the program itself. No need to recompile or restart.

DTrace 是 *动态的*，也就是说我们可以将它附加在一个已经在运行的程序上，也可以不打断程序将它剥离。不需要重新编译或启动。

In this article, we’ll focus on using DTrace to investigate our own program, but it’s worth mentioning that DTrace is systemwide: a single script could, for example, watch  made by *all* processes on the system. Take a look inside `/usr/share/examples/DTTk` for some great examples.

本文我们将重点介绍如何使用 DTrace 检查我们的程序，但值得注意的是 DTrace 是系统级的: 例如，一个单独的脚本可以观察到系统中 *所有* 处理器的内存分配操作。可以查看 `/usr/share/examples/DTTk` 来深入了解一些非常好的例子。

### OS X vs. iOS

### OS X vs. iOS

As you might have guessed by now, DTrace is only available on OS X. Apple also uses DTrace on iOS, in order to power tools such as Instruments, but for third-party developers, it is only available on OS X or the iOS simulator.

正如你现在可能已经猜到的，DTrace 只能在 OS X 上运行。苹果也在 iOS 上使用 DTrace，用以支持像 Instruments 这样的工具，但对于第三方开发者，DTrace 只能运行于 OS X 或 iOS 模拟器。

At [Wire](https://www.wire.com), DTrace has been very helpful on iOS, even though we're limited to using it in the iOS simulator. If you're reading this article and think real DTrace support on iOS devices is a good idea, please file an [enhancement request](https://bugreport.apple.com/) with Apple.

在 [Wire](https://www.wire.com)，DTrace 在 iOS 上非常有用，即使我们被限制仅能在 iOS 模拟器上使用它。如果你读到本文并且认为在 iOS 设备上支持 DTrace 是个好提议，请提交 [enhancement request](https://bugreport.apple.com/) 给苹果。


### Probes and Scripts

### 探针和脚本

There are two parts to DTrace: the DTrace probes, and the DTrace scripts that attach to those probes.

DTrace 有两部分: DTrace 探针，及附加在上面的 DTrace 脚本。

#### Probes

#### 探针

There are build-in probes, and you can add (so-called static) probes to your code. IA probe looks very similar to a normal C function. At Wire, our syncing code has an internal state machine, and we define these two probes:

    provider syncengine_sync {
        probe strategy_go_to_state(int);
    }

Probes are grouped into so-called *providers*. The `int` argument is the state that we're entering. In our Objective-C (or Swift) code, we simply insert the following:

    - (void)goToState:(ZMSyncState *)state
    {
        [self.currentState didLeaveState];
        self.currentState = state;
        SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE(state.identifier);
        [self.currentState didEnterState];
    }

We'll talk about how to integrate all of this and clean it up [in a bit](#staticProbes).

你可以将内置 (所谓静态的) 的探针加入代码中。IA 探针看起来和普通的 C 函数非常相似。在 Wire，我们的同步代码有一个内部状态机器，我们定义了如下两个探针:

```objc
provider syncengine_sync {
    probe strategy_go_to_state(int);
}
```

探针被分组成所谓的 *providers*。参数 `int` 是输入的状态。在我们的 Objective-C (或 Swift) 代码中，简单的插入以下代码:

```objc
- (void)goToState:(ZMSyncState *)state
{
    [self.currentState didLeaveState];
    self.currentState = state;
    SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE(state.identifier);
    [self.currentState didEnterState];
}
```

我们[后面](#staticProbes)会讨论如何整合及清除。

#### Scripts

#### 脚本

We can now write a small DTrace script that shows us state transitions:

    syncengine_sync*:::strategy_go_to_state
    {
        printf("Transitioning to state %d\n", arg0);
    }

(We will go into more detail [below](#DProgrammingLanguage) about how DTrace scripts work.)

If we save this DTrace into `state.d`, we can then run it using the [`dtrace(1)` command line tool][dtrace1man]:
	
	% sudo dtrace -q -s state.d

We will see the following:

    Transitioning to state 1
    Transitioning to state 2
    Transitioning to state 5

Just as we'd expect. Nothing too exciting. Hit `^C` to exit DTrace.

现在我们可以编写一个 DTrace 小脚本来展示状态转变:

```objc
syncengine_sync*:::strategy_go_to_state
{
    printf("Transitioning to state %d\n", arg0);
}
```

([后面](#DProgrammingLanguage)我们会详细展示 DTrace 脚本如何工作。)

如果将 DTrace 保存进 `state.d`，接下来我们可以使用 [`dtrace(1)` command line tool][dtrace1man] 来运行它:

```objc
% sudo dtrace -q -s state.d
```

我们可以看到:

```objc
Transitioning to state 1
Transitioning to state 2
Transitioning to state 5
```

正如我们所期盼的。无需激动，使用 `^C` 退出 DTrace。

<a name="ATimingExample"></a>
### A Timing Example

### 一个定时例子

Since DTrace is very low cost, it's a perfect fit for measuring performance — even when times measured are very small. The resolution of the timers inside DTrace is in nanoseconds.

因为 DTrace 消耗非常小，所以非常适合用来测试性能 - 即使需要测试的时间非常短。DTrace 中的时间单位是纳秒。

If we extend the trivial example from above, we can output the time spent in each state:

    uint64_t last_state;
    uint64_t last_state_timestamp;
    
    dtrace:::BEGIN
    {
        syncState[4] = "EventProcessing";
        syncState[5] = "QuickSync1";
        syncState[6] = "QuickSync2";
    }
    
    syncengine_sync*:::strategy_go_to_state
    / last_state_timestamp != 0 /
    {
        t = (walltimestamp - last_state_timestamp) / 1000000;
        printf("Spent %d ms in state %s\n", t, syncState[last_state]);
    }
    
    syncengine_sync*:::strategy_go_to_state
    {
        printf("Transitioning to state %s\n", syncState[arg0]);
        last_state = arg0;
        last_state_timestamp = walltimestamp;
    }

This will output the following:

    Transitioning to state QuickSync1
    Spent 2205 ms in state QuickSync1
    Transitioning to state QuickSync2
    Spent 115 ms in state QuickSync2
    Transitioning to state EventProcessing
    
如果扩展上面的小例子，我们可以输出每个状态所花费的时间:

```objc
uint64_t last_state;
uint64_t last_state_timestamp;
    
dtrace:::BEGIN
{
    syncState[4] = "EventProcessing";
    syncState[5] = "QuickSync1";
    syncState[6] = "QuickSync2";
}
    
syncengine_sync*:::strategy_go_to_state
/ last_state_timestamp != 0 /
{
    t = (walltimestamp - last_state_timestamp) / 1000000;
    printf("Spent %d ms in state %s\n", t, syncState[last_state]);
}
    
syncengine_sync*:::strategy_go_to_state
{
    printf("Transitioning to state %s\n", syncState[arg0]);
    last_state = arg0;
    last_state_timestamp = walltimestamp;
}
```

这些代码会输出:

```objc
Transitioning to state QuickSync1
Spent 2205 ms in state QuickSync1
Transitioning to state QuickSync2
Spent 115 ms in state QuickSync2
Transitioning to state EventProcessing
```

There are a few new things in this script. The `dtrace:::BEGIN` clause will run when the script starts. There's a matching `END` probe for when the script exits.

脚本中有些新东西。`dtrace:::BEGIN` 语句在脚本开始时运行。脚本退出时有一个相应的 `END`。

We also added a predicate, `/ last_state_timestamp != 0 /`, to the first probe.

我们还给第一个探针增加了一个谓词，`/ last_state_timestamp != 0 /`。

Finally, we're using variables in the global scope to keep track of what the last state was, and at what point in time we entered it.

最后我们使用全局变量来追踪最后的状态，以及什么时候进入该状态。

The built-in `walltimestamp` variable returns the current number of nanoseconds since the Unix epoch.

内置的 `walltimestamp` 变量返回 Unix 当前的纳秒数。

There's another timestamp variable, `vtimestamp`, which is a virtualized timestamp, also in nanoseconds. It is the amount of time the current thread has been running on a CPU, minus the time spent in DTrace. Finally, `machtimestamp` corresponds to `mach_absolute_time()`.

还有一个虚拟的单位为纳秒的时间戳变量，`vtimestamp`。表示当前的线程在 CPU 上运行的时间减去在 DTrace 上花费的时间。最后，`machtimestamp` 对应 `mach_absolute_time()`。

For the above script, the order of execution is important. We have two so-called *clauses*, which match the same probe, (`syncengine_sync*:::strategy_go_to_state`). These will run in the order in which they appear in the D program.

对于上面的脚本，执行的顺序非常重要。我们有两个所谓的 *语句* 对应同一个探针，(`syncengine_sync*:::strategy_go_to_state`)。他们会在 D 程序中按顺序执行。

### Combining with System-Provided Probes

### 结合系统探针

The operating system, particularly the kernel, provides thousands of probes, all grouped into various providers. A lot of these are the ones documented by [Oracle's DTrace documentation][oracleDTraceProviders].

操作系统，尤其是 kernel，提供了数以千计的探针，被分成不同的 provider 组。其中的很多在 [Oracle's DTrace documentation][oracleDTraceProviders] 可以找到文档。

We can use the `ip` provider's `send` probe to check how many bytes are sent over the network before we transition to the next state with this script:

    uint64_t bytes_sent;
    
    syncengine_sync$target:::strategy_go_to_state
    {
        printf("Transitioning to state %d\n", arg0);
        printf("Sent %d bytes in previous state\n", bytes_sent);
        bytes_sent = 0;
    }
    
    ip:::send
    / pid == $target /
    {
        bytes_sent += args[2]->ip_plength;
    }
    
通过下面的脚本，我们可以用 `ip` 提供者中的 `send` 探针来检查转换到下一个状态之前通过网络发送了多少字节:

```objc
uint64_t bytes_sent;
    
syncengine_sync$target:::strategy_go_to_state
{
    printf("Transitioning to state %d\n", arg0);
    printf("Sent %d bytes in previous state\n", bytes_sent);
    bytes_sent = 0;
}
    
ip:::send
/ pid == $target /
{
    bytes_sent += args[2]->ip_plength;
}
```

This time, we are targeting a specific process — the `ip:::send` would otherwise match all processes on the system, while we're only interested in the `Wire` process. We run this script with the following:

    sudo dtrace -q -s sample-timing-3.d -p 198
    
这次我们的目标为某个特定的进程 - `ip:::send` 会匹配系统的所有进程，而我们只对 `Wire` 进程感兴趣。我们运行如下的脚本:

```objc
sudo dtrace -q -s sample-timing-3.d -p 198
```

Here, `198` is the process identifier (aka PID) of the process. We can find this number in the Activity Monitor app, or by using the [`ps(1)` command line tool][ps1man].

We'll get this:

    Transitioning to state 6
    Sent 2043 bytes in previous state
    Transitioning to state 4
    Sent 581 bytes in previous state
    
这里 `198` 是进程标识 (亦称 PID)。我们可以在 Activity Monitor 这个 app 中找到这个数字，或者使用 [`ps(1)` 命令行工具][ps1man]。

我们会得到:

```objc
Transitioning to state 6
Sent 2043 bytes in previous state
Transitioning to state 4
Sent 581 bytes in previous state
```


<a name="DProgrammingLanguage"></a>
## D Programming Language

## D 语言

Note: This is *not* [D by W. Bright and A. Alexandrescu](https://en.wikipedia.org/wiki/D_%28programming_language%29).

注意: 这*不是*[D by W. Bright and A. Alexandrescu](https://en.wikipedia.org/wiki/D_%28programming_language%29)。

Most parts of D are very similar to the C programming language, but the overall structure is different. Each DTrace script consists of multiple so-called *probe clauses*.

D 语言的大部分跟 C 语言都非常相似，但总体架构是不同的。每一个 Dtrace 脚本由多个所谓的 *探针语句* 组成。

In the above examples, we have seen a few of these *probe clauses*. They all follow this general form:

    probe descriptions
    / predicate /
    {
        action statements
    }

The *predicate* and the *action statement* parts are both optional.

在上面的例子中，我们已经看到了一些这种 *探针语句*。他们都复合如下的原则:

```objc
probe descriptions
/ predicate /
{
    action statements
}
```

*predicate* 和 *action statement* 部分是可选的。

### Probe Descriptions

### 探针描述

The probe description defines what probe the clause matches. These are all of the forms where parts can be left out:

    provider:module:function:name
    
探针描述定义了语句匹配什么探针。所有的部分都可以省略，形式如下:

```objc
provider:module:function:name
```

For example, `syscall:::` matches all probes by the `syscall` provider. We can use `*` to match any string so that `syscall::*lwp*:entry` matches all `entry` probes by the `syscall` provider, where the function name contains `lwp`.

A probe description can consist of multiple probes, such as this:

    syscall::*lwp*:entry, syscall::*sock*:entry
    {
        trace(timestamp);
    }
    
例如，`syscall:::` 匹配所有 `syscall` 提供者的探针。我们可以使用 `*` 匹配任何字符串，例如 `syscall::*lwp*:entry` 匹配所有 `syscall` 提供者的 `entry` 探针，函数名字包含 `lwp`。

一个探针描述可以包含多个探针，例如:

```objc
syscall::*lwp*:entry, syscall::*sock*:entry
{
    trace(timestamp);
}
```

### Predicates

### 谓词

We can use predicates to limit when the *action statements* are to be run. The predicates are evaluated when the specified probes fire. If the predicate evaluates to non-zero, the *action statements* will run, similar to an `if` statement in C.

We can list the same probe multiple times with different predicates. If multiples of them match, they will be run in the order that they appear in the D program.

当 *action statements* 开始运行时我们可以使用谓词来限制。当触发特定的探针时谓词被评估。如果谓词评估为非 0，*action statements* 将会运行，类似 C 语言中的 `if` 声明。

我们可以使用不同的谓词来判断同一个探针多次。如果有多个匹配，他们将会按照出现的顺序执行。

### Actions

### 动作

The actions are enclosed in curly braces. The D language is lightweight, small, and simple.

动作包含在花括号中。D 语言是轻量，精悍和简单的语言。

D does not support control flow, such as loops or branches. We can not define any user functions. And variable declaration is optional.

D 不支持控制流，比如循环和分支。我们不能定义任何用户函数。变量定义也是可选的。

This limits what we can do. But the simplicity also gives us a lot of flexibility once we know a few common patterns, which we'll look into in the next section. Be sure to also check out the [D Programming Language][DProgrammingLanguage] guide for details.

这限制了我们能做的事情。但是一旦知道了一些常见的模式，这种简单也给了我们很多灵活性，我们将在下一节详细讨论。在 [D Programming Language][DProgrammingLanguage] 可以查看更多的细节。


## Common D Programming Patterns

## 常见 D 语言模式

The following examples will give us a good feel for some of the things we can do.

下面的例子会给让我们认识一些我们能做的事情。

This example measures the accumulated time the *App Store* application spends inside any syscall (i.e. a system call, or a call into the kernel):

    syscall:::entry
    / execname == "App Store" /
    {
        self->ts = timestamp;
    }
    
    syscall:::return
    / execname == "App Store" && self->ts != 0 /
    {
        @totals[probefunc] = sum(timestamp - self->ts);
    }
    
这个例子统计了 *App Store* 应用在 syscall (也就是一个系统调用，或 kernel 中的调用) 中累计使用的时间。

```objc
syscall:::entry
/ execname == "App Store" /
{
    self->ts = timestamp;
}
    
syscall:::return
/ execname == "App Store" && self->ts != 0 /
{
    @totals[probefunc] = sum(timestamp - self->ts);
}
```

If we run this and launch the Mac *App Store* application, then exit the D Trace script with `^C`, we will get output like this:

    dtrace: script 'app-store.d' matched 980 probes
    ^C
    
      __disable_threadsignal                                         2303
      __pthread_sigmask                                              2438
      psynch_cvclrprepost                                            3216
      ftruncate                                                      3663
      bsdthread_register                                             3754
      shared_region_check_np                                         3939
      getpid                                                         4189
      getegid                                                        4276
      gettimeofday                                                   4285
      flock                                                          4825
      sigaltstack                                                    4874
      kdebug_trace                                                   5430
      kqueue                                                         5860
      workq_open                                                     6155
      sigprocmask                                                    6188
      setrlimit                                                      7085
      psynch_cvsignal                                                8909
      
      [...]
      
      stat64                                                      6451260
      read                                                        6657207
      fsync                                                       8231130
      rename                                                      8340468
      open_nocancel                                               8856035
      workq_kernreturn                                           15835068
      getdirentries64                                            17978504
      bsdthread_ctl                                              25418263
      open                                                       29503041
      psynch_mutexwait                                          453338483
      ioctl                                                    1049412360
      __semwait_signal                                         1373514528
      select                                                   1632760820
      kevent64                                                 3656884980
      
如果运行这个并且开启 *App Store* 应用，然后用 `^C` 退出 DTrace 脚本，可以得到像这样的输出:

```objc
dtrace: script 'app-store.d' matched 980 probes
^C
    
  __disable_threadsignal                                         2303
  __pthread_sigmask                                              2438
  psynch_cvclrprepost                                            3216
  ftruncate                                                      3663
  bsdthread_register                                             3754
  shared_region_check_np                                         3939
  getpid                                                         4189
  getegid                                                        4276
  gettimeofday                                                   4285
  flock                                                          4825
  sigaltstack                                                    4874
  kdebug_trace                                                   5430
  kqueue                                                         5860
  workq_open                                                     6155
  sigprocmask                                                    6188
  setrlimit                                                      7085
  psynch_cvsignal                                                8909
      
  [...]
      
  stat64                                                      6451260
  read                                                        6657207
  fsync                                                       8231130
  rename                                                      8340468
  open_nocancel                                               8856035
  workq_kernreturn                                           15835068
  getdirentries64                                            17978504
  bsdthread_ctl                                              25418263
  open                                                       29503041
  psynch_mutexwait                                          453338483
  ioctl                                                    1049412360
  __semwait_signal                                         1373514528
  select                                                   1632760820
  kevent64                                                 3656884980
```                        

In this example, the *App Store* spent 3.6 seconds of CPU time inside the `kevent64` syscall.

在这个例子中，*App Store* 在 `kevent64` 中花费了 3.6 秒。

There are two very interesting things inside this small script: thread local variables (`self->ts`) and aggregations.

这个脚本中有两个特别有意思的事情: 线程本地变量 (`self->ts`) 和集成。

### Scope of Variable

### 变量声明周期

D has three different scopes for variables: global, thread local, and probe clause local.

D 语言有 3 种变量生命周期: 全局，线程本地，和探针语句本地。

A global variable such as `foo` or `bar` is visible throughout the D program.

`foo` 或 `bar` 这样的全局变量在整个 D 语言中都是可见的。

Thread local variables are named `self->foo`, `self->bar`, etc., and are local to the specific thread.

线程本地变量命名为 `self->foo`，`self->bar` 等，并且存在与特定的线程中。

Probe clause local variables are similar to local variables in C or Swift. They can be useful for intermediate results.

探针语句本地变量与 C 或 Swift 中的本地变量类似。对于中间结果来说很有用。

In the script, we use the first probe clause to match when we enter a syscall. We set the thread local variable, `self->ts`, to the current timestamp:

    syscall:::entry
    / execname == "App Store" /
    {
        self->ts = timestamp;
    }
    
在这个脚本中，当输入 syscall 时我们使用第一个探针语句来匹配。我们将当前时间戳赋值给线程本地变量 `self->ts` :

```objc
syscall:::entry
/ execname == "App Store" /
{
    self->ts = timestamp;
}
```

The second clause matches when the thread returns from the syscall. It will be the same thread that entered, hence we can be sure that `self->ts` has the expected value, even when multiple threads do system calls at the same time.

第二个语句在从 syscall 中返回时匹配。和进入时是同一个线程，因此可以确定，即使有多个线程在同一时间进行系统调用， `self->ts` 也具有我们所期待的值。

We add `self->ts != 0` to the predicate to be sure that our script works, even if we attach to the application while it is inside a system call. Otherwise, `timestamp - self->ts` would result in a very large value, because `self->ts` would not have been set:

    syscall:::return
    / execname == "App Store" && self->ts != 0 /
    {
        @totals[probefunc] = sum(timestamp - self->ts);
    }
    
我们在谓词里加入了 `self->ts != 0` 来确保我们的脚本正确运行，即使在应用处于系统调用中时追加。否则，`timestamp - self->ts` 将会是一个非常大的值，因为 `self->ts` 不会被设置:

```objc
syscall:::return
/ execname == "App Store" && self->ts != 0 /
{
    @totals[probefunc] = sum(timestamp - self->ts);
}
```

For all the nitty-gritty details on variables, be sure to check the [Dynamic Tracing Guide, “Variables.”][DTraceGuideChapter3]

通过 [Dynamic Tracing Guide, “Variables.”][DTraceGuideChapter3] 可以查看关于变量的更多细节。

<a name="Aggregations"></a>
### Aggregations

### 集成

This line uses aggregations:

        @totals[probefunc] = sum(timestamp - self->ts);

This is an extremely powerful feature of DTrace.

这行代码使用了集成:

```objc
@totals[probefunc] = sum(timestamp - self->ts);
```

这是 DTrace 的一个极其强大的特性。

We're calling our aggregation variable `totals`. The `@` in front of the name turns it into an aggregation. `probefunc` is a built-in variable — it is the name of the probe function. For `syscall` probes, as in our case, `probefunc` is the name of the system call being made. 

我们调用集成变量 `totals`。变量名前面的 `@` 将它转变为集成。`probefunc` 是一个内置变量 - 它是探针函数的名字。对于 `syscall` 探针，`probefunc` 是正在运行的系统调用的名字。

`sum` is the aggregation function. In our case, the aggregation is summing up `timestamp - self->ts` for each `probefunc`.

`sum` 是集成函数。在这个例子中，该集成用来计算每一个 `probefunc` 对应的 `timestamp - self->ts` 的和。

The [DTrace Guide](https://docs.oracle.com/cd/E19253-01/817-6223/chp-aggs-trunc/index.html) shows this small example script that uses aggregations to print the number of system calls per second of the 10 applications that do the most system calls:

    #pragma D option quiet
    
    BEGIN
    {
    	last = timestamp;
    }
    
    syscall:::entry
    {
    	@func[execname] = count();
    }
    
    tick-10sec
    {
    	trunc(@func, 10);
    	normalize(@func, (timestamp - last) / 1000000000);
    	printa(@func);
    	clear(@func);
    	last = timestamp;
    }
    
[DTrace Guide](https://docs.oracle.com/cd/E19253-01/817-6223/chp-aggs-trunc/index.html) 展示了一个小例子，该例子使用集成来打印每秒钟调用系统最多的 10 个应用的系统调用的数量。

```objc
#pragma D option quiet
    
BEGIN
{
    last = timestamp;
}
    
syscall:::entry
{
    @func[execname] = count();
}
    
tick-10sec
{
    trunc(@func, 10);
    normalize(@func, (timestamp - last) / 1000000000);
    printa(@func);
    clear(@func);
    last = timestamp;
}
```

On a mostly idle OS X, it may show something like this:


    kextd                                                             7
    ntpd                                                              8
    mds_stores                                                       19
    cfprefsd                                                         20
    dtrace                                                           20
    UserEventAgent                                                   34
    launchd                                                          42
    Safari                                                          109
    cloudd                                                          115
    com.apple.WebKi                                                 177
    
    mds                                                               8
    Wire                                                              8
    Terminal                                                         10
    com.apple.iClou                                                  15
    dtrace                                                           20
    securityd                                                        20
    tccd                                                             37
    syncdefaultsd                                                    98
    Safari                                                          109
    com.apple.WebKi                                                 212

We see Safari, WebKit, and `cloudd` being active. 

在大多数空闲的 OS X 上，可能会显示如下:

```objc
kextd                                                             7
ntpd                                                              8
mds_stores                                                       19
cfprefsd                                                         20
dtrace                                                           20
UserEventAgent                                                   34
launchd                                                          42
Safari                                                          109
cloudd                                                          115
com.apple.WebKi                                                 177
    
mds                                                               8
Wire                                                              8
Terminal                                                         10
com.apple.iClou                                                  15
dtrace                                                           20
securityd                                                        20
tccd                                                             37
syncdefaultsd                                                    98
Safari                                                          109
com.apple.WebKi                                                 212
```

我们看到 Safari，WebKit 和 `cloudd` 处于活动状态。

Here is the total list of aggregation functions:

    Function Name     | Result 
    ------------------|---------
    count             | Number of times called
    sum               | Sum of the passed in values
    avg               | Average of the passed in values
    min               | Smallest of the passed in values
    max               | Largest of the passed in values
    lquantize         | Linear frequency distribution
    quantize          | Power-of-two frequency distribution
    
下表为所有集成函数:

```objc
Function Name     | Result 
------------------|---------
count             | Number of times called
sum               | Sum of the passed in values
avg               | Average of the passed in values
min               | Smallest of the passed in values
max               | Largest of the passed in values
lquantize         | Linear frequency distribution
quantize          | Power-of-two frequency distribution
```

The `quantize` and `lquantize` functions can be very helpful in providing an overview of what quantities are being passed:

    ip:::send
    {
        @bytes_sent[execname] = quantize(args[2]->ip_plength);
    }
    
`quantize` 和 `lquantize` 函数可以给出一个关于传入的数量的概览:

```objc
ip:::send
{
    @bytes_sent[execname] = quantize(args[2]->ip_plength);
}
```

The above will output something like this:

    discoveryd                                        
             value  ------------- Distribution ------------- count    
                16 |                                         0        
                32 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 2        
                64 |                                         0        
    
    syncdefaultsd                                     
             value  ------------- Distribution ------------- count    
               256 |                                         0        
               512 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 4        
              1024 |                                         0        
    
    kernel_task                                       
             value  ------------- Distribution ------------- count    
                 8 |                                         0        
                16 |@@@@@@@@@@@@@@                           37       
                32 |@@@@@@@@@@@@@@@@@@@@@@@@@@               67       
                64 |                                         0        
    
    com.apple.WebKi                                   
             value  ------------- Distribution ------------- count    
                16 |                                         0        
                32 |@@@@@@@@@@@@@@@@                         28       
                64 |@@@@                                     7        
               128 |@@@@                                     6        
               256 |                                         0        
               512 |@@@@@@@@@@@@@@@@                         27       
              1024 |                                         0        
              
上面的代码会输出类似这样的结果:

```objc
discoveryd                                        
         value  ------------- Distribution ------------- count    
            16 |                                         0        
            32 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 2        
            64 |                                         0        
    
syncdefaultsd                                     
         value  ------------- Distribution ------------- count    
           256 |                                         0        
           512 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 4        
          1024 |                                         0        
    
kernel_task                                       
         value  ------------- Distribution ------------- count    
             8 |                                         0        
            16 |@@@@@@@@@@@@@@                           37       
            32 |@@@@@@@@@@@@@@@@@@@@@@@@@@               67       
            64 |                                         0        
    
com.apple.WebKi                                   
         value  ------------- Distribution ------------- count    
            16 |                                         0        
            32 |@@@@@@@@@@@@@@@@                         28       
            64 |@@@@                                     7        
           128 |@@@@                                     6        
           256 |                                         0        
           512 |@@@@@@@@@@@@@@@@                         27       
          1024 |                                         0        
```

Be sure to check out [the samples from the Dynamic Tracing Guide](https://docs.oracle.com/cd/E19253-01/817-6223/chp-aggs-2/index.html) for information on how to use `lquantize`.

查看 [the samples from the Dynamic Tracing Guide](https://docs.oracle.com/cd/E19253-01/817-6223/chp-aggs-2/index.html) 来了解如何使用 `lquantize`。

### Associative Arrays

### 联合数组

Despite the name, arrays in D are more akin to dictionaries in Swift or Objective-C. In addition, they are multidimensional.

不管名字如何，D 语言中的数组更类似 Swift 或 Objective-C 中的字典。另外，它们都是可变的。

We can define an associative array with this:

    int x[unsigned long long, char];
    
我们可以这样定义一个联合数组:

```objc
int x[unsigned long long, char];
```

Then, we can assign to it, like so:

    BEGIN
    {
        x[123ull, ’a’] = 456;
    }
    
然后我们可以给它赋值:

```objc
BEGIN
{
    x[123ull, ’a’] = 456;
}
```

For the Wire app, we want to track the roundtrip times for [NSURLSessionTask][AppleDocNSURLSessionTask] instances. We fire a [statically defined probe](#staticProbes) when we resume such a task, and a second probe when it completes. With that, we can write a simple script like this:

    syncengine_sync$target:::operation_loop_enqueue
    / arg0 == 4 /
    {
        start_transport_request_timestamp[arg1] = timestamp;
    }
    
    syncengine_sync$target:::operation_loop_enqueue
    / arg0 == 6 && start_transport_request_timestamp[arg1] != 0 /
    {
        @time["time for transport request round-trip"] = quantize(timestamp - start_transport_request_timestamp[arg1]);
    }
    
对于 Wire 应用，我们想要追踪 [NSURLSessionTask][AppleDocNSURLSessionTask] 实例。当开始一个任务，我们触发一个 [静态定义探针](#staticProbes)，当完成时还有另一个探针。我们可以写一个简单的脚本:

```objc
syncengine_sync$target:::operation_loop_enqueue
/ arg0 == 4 /
{
    start_transport_request_timestamp[arg1] = timestamp;
}
    
syncengine_sync$target:::operation_loop_enqueue
/ arg0 == 6 && start_transport_request_timestamp[arg1] != 0 /
{
    @time["time for transport request round-trip"] = quantize(timestamp - start_transport_request_timestamp[arg1]);
}
```

We pass in the [`taskIdentifer`][AppleDocNSURLSessionTask_taskIdentifier] as `arg1`, and `arg0` is set to 4 when the task is resumed, and 6 when it completes.

我们传入 [`taskIdentifer`][AppleDocNSURLSessionTask_taskIdentifier] 作为 `arg1`，任务开始时 `arg0` 被设置为 4，任务完成时被设置为 6。

Associative arrays are also very helpful in providing a good description for `enum` values passed into a clause, as we've seen in the [first example, “A Timing Example,” above](#ATimingExample).

正如我们在第一个例子 [“A Timing Example”](#ATimingExample) 中看到的那样，联合数组在为传入语句的 `enum` 值提供描述时也非常有用。

## Probes and Providers

## 探针和提供者

Let's take a step back and look at the probes that are available.

让我们回过头看看可用的探针。

We can get a list of all available providers with this:

    sudo dtrace -l | awk '{ match($2, "([a-z,A-Z]*)"); print substr($2, RSTART, RLENGTH); }' | sort -u
    
可以使用如下的命令来获得一个可用探针的列表:

```objc
sudo dtrace -l | awk '{ match($2, "([a-z,A-Z]*)"); print substr($2, RSTART, RLENGTH); }' | sort -u
```

On OS X 10.10, there are 79 providers. Many of these are specific to the kernel and system calls.

在 OS X 10.10 中有 79 个提供者。其中许多都与 kernel 和系统调用相关。

Some of these providers are part of the original set documented in the [Dynamic Tracing Guide][oracleDTraceProviders]. Let's look at a few of those that are available to us.

其中一些提供者是 [Dynamic Tracing Guide][oracleDTraceProviders] 记录的原始集合中的一部分。让我们看看其中一些我们可用的。

### `dtrace` Provider

### `dtrace` 提供者

We mentioned the `BEGIN` and `END` probes [above](#ATimingExample). The `dtrace:::END` is particularly helpful for outputting summaries when running DTrace in the quiet mode. There's also an `ERROR` probe for when an error occurs.

我们[之前](#ATimingExample)提到过 `BEGIN` 和 `END` 探针。当以安静模式运行 DTrace 时，`dtrace:::END` 对于输出摘要尤其有用。错误发生时还有 `ERROR` 探针。

### `profile` Provider

### `profile` 提供者

The [`profile` provider][profileProvider] can be used for sampling in a way that should be familiar to users of Instruments. 

The [`profile` 提供者][profileProvider] 可以用来在某种程度上采样，这对于 Instruments 的用户来说应该非常熟悉。

We can sample the stack depth at 1001 Herz:

    profile-1001
    /pid == $1/
    {
    	@proc[execname] = lquantize(stackdepth, 0, 20, 1);
    }
    
我们可以采样 1001 Herz 的栈深:

```objc
profile-1001
/pid == $1/
{
    @proc[execname] = lquantize(stackdepth, 0, 20, 1);
}
```


The output will look something like this:

    Safari                                            
             value  ------------- Distribution ------------- count    
               < 0 |                                         0        
                 0 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     704      
                 1 |@                                        12       
                 2 |@@                                       30       
                 3 |@                                        17       
                 4 |                                         7        
                 5 |                                         6        
                 6 |                                         1        
                 7 |                                         2        
                 8 |                                         1        
                 9 |                                         7        
                10 |                                         5        
                11 |                                         1        
                12 |                                         0        
                
输出会是这样:

```objc
Safari                                            
         value  ------------- Distribution ------------- count    
           < 0 |                                         0        
             0 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     704      
             1 |@                                        12       
             2 |@@                                       30       
             3 |@                                        17       
             4 |                                         7        
             5 |                                         6        
             6 |                                         1        
             7 |                                         2        
             8 |                                         1        
             9 |                                         7        
            10 |                                         5        
            11 |                                         1        
            12 |                                         0        
```

Similarly, the `tick-` probes will fire every fixed interval at a high interrupt level. The `profile-` probes will fire on all CPUs, and the `tick-` probes only on a single CPU per interval. We used `tick-10sec` in our [aggregation](#Aggregations) example above.

类似的，`tick-` 探针会每隔固定的时间间隔，以很高打断的级别触发。`profile-` 探针会在所有 CPU 上触发，而 `tick-` 每个间隔只会在一个 CPU 上。我们在上面的 [aggregation](#Aggregations) 例子中使用 `tick-10sec` 。

### `pid` Provider

### `pid` 提供者

The `pid` provider is a bit of a brute force provider. In most cases, we should really use [static probes](#staticProbes) as described below.

`pid` 是一个有点野蛮的提供者。大多数时候，我们真的应该使用上面提到过的 [static probes](#staticProbes)。

`pid` is short for process identifier. It lets us probe on the function entry and exit of a process. This works in *most* cases. Note that function entry and return are not always well defined, particularly due to *tail-call optimization*. And some functions don’t have to create a stack frame, etc.

`pid` 是处理器标识的缩写。它可以让我们在进入函数和退出时探测。这在*大多数*情况下是可行的。注意函数的进入和返回并不总是可以很好的界定，尤其是因为 *tail-call optimization* 调用时。并且有些函数并不需要创建栈框架。

When you can't change the code to add [static probes](#staticProbes), `pid` is a powerful tool.

当你不能改变代码来增加 [static probes](#staticProbes)，`pid` 是一个强大的工具。

You can trace any function that's visible. For example, look at this probe:

    pid123:libSystem:printf:return
    
你可以追踪任何可见的函数。例如这个探针:

```objc
pid123:libSystem:printf:return
```

It would attach to `printf`, returning in the process with the process identifier (PID) 123.

这个探针会关联到 `printf`，返回处理器和处理器标识 (PID) 123。

### `objc` Provider

### `objc` 提供者

A direct counterpart to the `pid` provider is the `objc` provider. It provides probes for Objective-C method entry and exit. Again, using [static probes](#staticProbes) provides more flexibility.

`pid` 提供者的一个替代品是 `objc` 提供者。它为 Objective-C 方法的进入和退出提供了探针。还是使用 [static probes](#staticProbes) 可以提供更好的灵活性。

The format for `objc` probe specifiers is this:

    objcpid:[class-name[(category-name)]]:[[+|-]method-name]:[name]

And

    objc207:NSTableView:-*:entry

would match entry into all instance methods of `NSTableView` in the process with PID 207. Since the colon symbol `:` is part of the DTrace probe specifier scheme, `:` symbols in Objective-C method names need to be replaced with a question mark, `?`. For example, to match entry into `-[NSDate dateByAddingTimeInterval:]`, we'd use this:

    objc207:NSDate:-dateByAddingTimeInterval?:entry

For additional details, check the [`dtrace(1)` man page][dtrace1man].

`objc` 探针的格式如下:

```objc
objcpid:[class-name[(category-name)]]:[[+|-]method-name]:[name]
```

和

```objc
objc207:NSTableView:-*:entry
```

通过查看 [`dtrace(1)` man page][dtrace1man] 获得更多详细信息。

### `io` Provider

### `io` 提供者

To trace activity related to disk input and output, the [`io` provider][ioProvider] defines six probes:

    start
    done
    wait-start
    wait-done
    journal-start
    journal-done
    
为了追踪与磁盘输入输出相关的活动，[`io` 提供者][ioProvider] 定义了 6 个探针:

```objc
start
done
wait-start
wait-done
journal-start
journal-done
```

The sample from the [Oracle documentation][ioProvider] shows how this can be put to use:

    #pragma D option quiet
    
    BEGIN
    {
    	printf("%10s %58s %2s\n", "DEVICE", "FILE", "RW");
    }
    
    io:::start
    {
    	printf("%10s %58s %2s\n", args[1]->dev_statname,
    	    args[2]->fi_pathname, args[0]->b_flags & B_READ ? "R" : "W");
    }
    
[Oracle documentation][ioProvider] 的例子给出了如何使用:

```objc
#pragma D option quiet
    
BEGIN
{
    printf("%10s %58s %2s\n", "DEVICE", "FILE", "RW");
}
    
io:::start
{
    printf("%10s %58s %2s\n", args[1]->dev_statname,
    	    args[2]->fi_pathname, args[0]->b_flags & B_READ ? "R" : "W");
}
```

The above will output something like this:

    ??                   ??/com.apple.Safari.savedState/data.data  R
    ??            ??/Preferences/com.apple.Terminal.plist.kn0E7LJ  W
    ??                                            ??/vm/swapfile0  R
    ??              ??/Preferences/com.apple.Safari.plist.jEQRQ5N  W
    ??           ??/Preferences/com.apple.HIToolbox.plist.yBPXSnY  W
    ??       ??/fsCachedData/F2BF76DB-740F-49AF-94DC-71308E08B474  W
    ??                           ??/com.apple.Safari/Cache.db-wal  W
    ??                           ??/com.apple.Safari/Cache.db-wal  W
    ??       ??/fsCachedData/88C00A4D-4D8E-4DD8-906E-B1796AC949A2  W
    
上面的例子会输出类似这样的结果:

```objc
??                   ??/com.apple.Safari.savedState/data.data  R
??            ??/Preferences/com.apple.Terminal.plist.kn0E7LJ  W
??                                            ??/vm/swapfile0  R
??              ??/Preferences/com.apple.Safari.plist.jEQRQ5N  W
??           ??/Preferences/com.apple.HIToolbox.plist.yBPXSnY  W
??       ??/fsCachedData/F2BF76DB-740F-49AF-94DC-71308E08B474  W
??                           ??/com.apple.Safari/Cache.db-wal  W
??                           ??/com.apple.Safari/Cache.db-wal  W
??       ??/fsCachedData/88C00A4D-4D8E-4DD8-906E-B1796AC949A2  W
```

# `ip` Provider

# `ip` 提供者

There are two probes, `send` and `receive`, inside the [`ip` provider][ipProvider]. They are triggered whenever data is either sent or received over the IP. The arguments `arg0` to `arg5` provide access to the kernel structures related to the IP packet being sent or received.

[`ip` 提供者][ipProvider] 有 `send` 和 `receive` 两个探针。任何时候数据通过 IP 被发送或接收都会触发。参数 `arg0` 到 `arg5` 提供了与发送或接收的 IP 包相关的 kernel 结构体的访问入口。

This can be put together into very powerful network debugging tools. It will make using `tcpdump(1)` seem like yesteryear's trick. The `ip` provider lets you print exactly the information you are interested in, at the point in time that you're interested in it.

可以将二者放入非常强大的网络调试工具中。它可以使 `tcpdump(1)` 的看起来像过时的玩意。`ip` 提供者可以让我们在需要的时候精确的输出我们所需要的信息。

Check the [documentation][ipProvider] for some excellent examples.

查看 [documentation][ipProvider] 获得更多的示例。


<a name="staticProbes"></a>
## Defining Our Own Static Probes

## 自定义静态探针

DTrace lets us create our own probes, and with that, we can unlock the real power of DTrace for our own apps.

DTrace 允许我们创建自己的探针，通过这个，我们可以释放 DTrace 的真正威力。

These kinds of probes are called *static probes* in DTrace. We briefly talked about this in the [first examples](#ATimingExample). The [Wire app](https://itunes.apple.com/app/wire/id931134707?mt=12) defines its own provider with its own probe:

    provider syncengine_sync {
        probe strategy_go_to_state(int);
    }
    
这些在 DTrace 中被称作 *静态探针*。我们在 [第一个例子](#ATimingExample) 中曾经简短的提到过。[Wire](https://itunes.apple.com/app/wire/id931134707?mt=12) 定义了自己的提供者和探针:

```objc
provider syncengine_sync {
    probe strategy_go_to_state(int);
}
```

We then call this probe in the code:

    
    - (void)goToState:(ZMSyncState *)state
    {
        [self.currentState didLeaveState];
        self.currentState = state;
        SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE(state.identifier);
        [self.currentState didEnterState];
    }
    
然后我们在代码中调用探针:

```objc
- (void)goToState:(ZMSyncState *)state
{
    [self.currentState didLeaveState];
    self.currentState = state;
    SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE(state.identifier);
    [self.currentState didEnterState];
}
```

One might argue that we could have just used the `objc` provider; using our own probe gives us more flexibility. We can later change the Objective-C code without affecting the DTrace probes.

一个可能的争论就是我们本来可以干脆直接使用 `objc` 提供者; 使用我们自己的探针可以更具灵活性。以后我们可以修改 Objective-C 代码而不影响 DTrace 探针。

Additionally, the static probes give us easy access to the arguments. We saw above how we can use this both for timing and logging.

另外，静态探针给我们提供更方便的参数访问方式。通过上面我们可以看到我们如何利用它来追踪时间和输出日志。

The power of DTrace static probes is that they give us a stable interface to debug our code, and an interface that exists even in production code. When someone is seeing odd behavior, we can attach a DTrace script to the running app, even for a production build of that app. And the flexibility of DTrace allows us to use the same probes for multiple purposes.

DTrace 静态探针的强大之处在于给我们提供了稳定的接口来调试我们的代码，并且即便是在生产代码中也存在这个接口。即使对于应用的生产版本，当有人看到奇怪的行为，我们也可以给正在运行的应用附加一段 DTrace 脚本。DTrace 的灵活性还可以让我们复用探针。

We can use DTrace as a logging tool. But it also allows us to gather detailed quantitative information about timing, network requests, etc.

我们可以将 DTrace 作为日志工具使用。还可以用来收集与时间，网络，请求等有关的详细的量化信息。

The reason we can leave the probes in production code is that probes are *zero cost*, or to be fair, equivalent to a test-and-branch CPU instruction.

我们可以将探针留在生产代码中的原因是探针是 *zero cost* 的，或者公平点说，相当于一个测试和分支的 CPU 指令。

Let's take a look at how we add static probes to our project.

下面来看看如何将静态探针加入到我们的工程。

### Provider Description

### 提供者描述

First we need to create a `.d` file that defines the providers and probes. If we create a `provider.d` file with this content, we will have two providers:

    provider syncengine_sync {
        probe operation_loop_enqueue(int, int, intptr_t);
        probe operation_loop_push_channel_data(int, int);
        probe strategy_go_to_state(int);
        probe strategy_leave_state(int);
        probe strategy_update_event(int, int);
        probe strategy_update_event_string(int, char *);
    };
    
    provider syncengine_ui {
        probe notification(int, intptr_t, char *, char *, int, int, int, int);
    };

These providers are `syncengine_sync` and `syncengine_ui`. Within each one, we define a set of probes with their argument types.

首先我们需要创建一个 `.d` 文件并定义提供者和探针。如果我们创建了一个 `provider.d` 文件并写入以下内容，会得到两个提供者:

```objc
provider syncengine_sync {
    probe operation_loop_enqueue(int, int, intptr_t);
    probe operation_loop_push_channel_data(int, int);
    probe strategy_go_to_state(int);
    probe strategy_leave_state(int);
    probe strategy_update_event(int, int);
    probe strategy_update_event_string(int, char *);
};
    
provider syncengine_ui {
    probe notification(int, intptr_t, char *, char *, int, int, int, int);
};
```

提供者是 `syncengine_sync` 和 `syncengine_ui`。在每个提供者中，我们定义了一组探针。

### Creating a Header File

### 创建头文件

We now need to add the `provider.d` file to an Xcode target. It is important to make sure that the type is set to *DTrace source*. Xcode now automatically processes it when building. During this processing, DTrace creates a corresponding `provider.h` header file that we can include. It is important to add the `provider.d` file to both the Xcode project and the corresponding target.

现在我们需要将 `provider.d` 加入到 Xcode 的构建目标中。确保将类型设置为 *DTrace source* 十分重要。Xcode 现在会在构建时自动处理。在这个步骤中，DTrace 会创建一个对应的 `provider.h` 头文件，我们可以引入它。将 `provider.d` 同时加入 Xcode 工程和相应的构建目标非常重要。

Under the hood, Xcode calls the `dtrace(1)` tool:

    dtrace -h -s provider.d
    
Xcode 调用 `dtrace(1)` 工具:

```objc
dtrace -h -s provider.d
```

This will generate the corresponding header file. The header file ends up in the [`DERIVED_FILE_DIR][XcodeBuildDerivedFileDir], and can be imported with

    #import "provider.h"
    
这会生成相应的头文件。该文件以 [`DERIVED_FILE_DIR][XcodeBuildDerivedFileDir] 结尾。可以通过以下方式在任何工程内的远文件中引用

```objc
#import "provider.h"
```

in any source file in the project. Xcode has a built-in, so-called *build rule* for DTrace provider descriptions. Compare [objc.io issue #6, “The Build Process,”](/issue-6/build-process.html) for more information on build rules and the build process in general.

对于 DTrace 提供者描述，Xcode 有一个内置的所谓 *构建规则* 。比较 [objc.io issue #6, “The Build Process,”](/issue-6/build-process.html) 来获取关于构建规则和构建处理的更多的信息。


### Adding the Probe

### 增加探针

For each static probe, the header file will contain two macros:

    PROVIDER_PROBENAME()
    PROVIDER_PROBENAME_ENABLED()
    
对于每一个静态探针，头文件会包含两个宏:

```objc
PROVIDER_PROBENAME()
PROVIDER_PROBENAME_ENABLED()
```

The first one is the probe itself. The second one will evaluate to 0 when the probe is not enabled.

第一个是探针本身。第二个会在探针关闭时判断为 0。

The DTrace probes themselves are zero cost when not enabled, i.e. as long as no one attached to a probe, they're for free. Sometimes, however, we may want to pre-calculate / preprocess some data before sending it to a probe. In those rare cases, we can use the `_ENABLED()` macro, like so:

    if (SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE_ENABLED()) {
        argument = /* Expensive argument calculation code here */;
        SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE(argument);
    };
    
DTrace 探针自己本身是零消耗的，也就是说只要没有附加在探针上的东西，它们就不会产生消耗。然而有时，我们可能想要提前判断或将数据发送给探针之前做一些预处理。在这些不太常见的情况下，我们可以使用 `_ENABLED()` 宏:

```objc
if (SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE_ENABLED()) {
    argument = /* Expensive argument calculation code here */;
    SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE(argument);
};
```

### Wrapping DTrace Probes

### 包装 DTrace 探针

Code readability is very important. As we add more and more DTrace probes to our code, we need to make sure the code doesn't get cluttered and incomprehensible due to the probes. After all, the probes are here to help us, not to make things more difficult.

代码可读性非常重要。随着增加越来越多的探针到代码中，我们需要确保代码不会因此而变得乱七八糟和难以理解。毕竟探针的目的是帮助我们而不是将事情变得更复杂。

What we did was to add another simple wrapper. These wrappers both make the code a bit more readable and also add the `if (…_ENABLED*())` check in one go.

我们所需要做的就是增加另一个简单的包装器。这些包装器既使代码的可读性更好了一些，也增加了 `if (…_ENABLED*())` 检查。

If we go back to the state machine example, here is our probe macro:

    SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE(state);
    
回到状态机器的例子中，我们的探针宏是这样的:

```objc
SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE(state);
```

In order to make that a bit easier on the eye, we created another header which defines the following:

    static inline void ZMTraceSyncStrategyGoToState(int d) {
        SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE(d);
    }
    
为了使它变得更简单，我们创建另一个头文件并定义:

```objc
static inline void ZMTraceSyncStrategyGoToState(int d) {
    SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE(d);
}
```

With that, we can call the following:

    ZMTraceSyncStrategyGoToState(state);
    
之后我们就调用:

```objc
ZMTraceSyncStrategyGoToState(state);
```

That may seem like a small feat, but the [camel case](https://en.wikipedia.org/wiki/CamelCase) blends in better with normal Objective-C and Swift coding style.

这可以看成是一个小成就，[camel case](https://en.wikipedia.org/wiki/CamelCase) 在混合普通的 Objective-C 和 Swift 代码风格方面做的更好。

In other cases we went further. If we look at the 

    provider syncengine_ui {
        probe notification(int, intptr_t, char *, char *, int, int, int, int);
    };

we defined above, we have a long list of arguments. In the Wire app, we use this to log UI notifications.

更进一步的，如果我们看到上面定义的

```objc
provider syncengine_ui {
    probe notification(int, intptr_t, char *, char *, int, int, int, int);
};
```

有一长串的参数。在 Wire 中，我们用这个来记录 UI 通知日志。

This probe has a very long list of arguments. We decided that we wanted to use a single probe for a lot of different notifications that the syncing code sends to the UI to notify it about changes. The first argument, `arg0`, specifies what the notification is, and the second one specifies the `object` of the `NSNotification`. This makes it easy for our DTrace scripts to narrow in on those specific notifications of interest in the given situation.

这个探针有一长串的参数。我们决定只要一个探针来处理许多不同的同步代码发给 UI 用以提醒变化的通知。第一个参数，`arg0`，定义了是什么通知，第二个参数定义了 `NSNotification` 的 `object`。在这使得我们的 DTrace 脚本在那些具体的通知中很有好处。

The remainder of the arguments are less loosely defined on a per-notification basis, and we have multiple wrapper functions for the individual cases. When we want to pass two `NSUUID` instances, we call a wrapper function like this:

    ZMTraceUserInterfaceNotification_UUID(1, note.object,
        conversation.remoteIdentifier, participant.user.remoteIdentifier,
        wasJoined, participant.isJoined, currentState.connectionState, 0);
        
剩余的参数定义的稍微宽松些，而且对于各个单独情况我们有多个包装函数。当想要传入两个 `NSUUID` 对象的情况，我们调用类似这样的包装函数：

```objc
MTraceUserInterfaceNotification_UUID(1, note.object,
    conversation.remoteIdentifier, participant.user.remoteIdentifier,
        wasJoined, participant.isJoined, currentState.connectionState, 0);
```

This wrapper function is defined as this:

    static inline void ZMTraceUserInterfaceNotification_UUID(int d, NSObject *obj, NSUUID *remoteID1, NSUUID *remoteID2, int e, int f, int g, int h) {
        if (SYNCENGINE_UI_NOTIFICATION_ENABLED()) {
            SYNCENGINE_UI_NOTIFICATION(d, (intptr_t) (__bridge void *) obj, remoteID1.transportString.UTF8String, remoteID2.transportString.UTF8String, e, f, g, h);
        }
    }
    
这个包装函数是这样定义的:

```objc
static inline void ZMTraceUserInterfaceNotification_UUID(int d, NSObject *obj, NSUUID *remoteID1, NSUUID *remoteID2, int e, int f, int g, int h) {
    if (SYNCENGINE_UI_NOTIFICATION_ENABLED()) {
        SYNCENGINE_UI_NOTIFICATION(d, (intptr_t) (__bridge void *) obj, remoteID1.transportString.UTF8String, remoteID2.transportString.UTF8String, e, f, g, h);
    }
}
objc

As noted, this serves two purposes. For one, we don't clutter our code with things like `(intptr_t) (__bridge void *)`. Additionally, we don't spend CPU cycles converting an `NSUUID` to an `NSString` and then to a `char const *`, unless we need to because someone is attached to the probe.

正如之前提到的，我们有两个目的。第一，不让类似 `(intptr_t) (__bridge void *)` 这样的代码把我们的代码搞的乱七八糟。另外，我们无需花费 CPU 周期将一个 `NSUUID` 转换为 `NSString` 并进一步转换为 `char const *`，除非我们因为附加到探针的时候需要。

Along this pattern, we can define multiple wrapper / helper functions that funnel into the same DTrace probe.

根据这个模式，我们可以定义多个包装器 / 辅助函数来复用相同的 DTrace 探针。

### DTrace and Swift

### DTrace 和 Swift

Wrapping DTrace probes like this also gives us integration between Swift code and DTrace static probes. `static line` function can now be called directly from Swift code:

    func goToState(state: ZMSyncState) {
        currentState.didLeaveState()
        currentState = state
        currentState.didEnterState()
        ZMTraceSyncStrategyGoToState(state.identifier)
    }
    
像这样包装 DTrace 探针可以让我们整合 Swift 和 DTrace 静态探针。`static line` 函数现在可以在 Swift 代码中直接调用。

```objc
func goToState(state: ZMSyncState) {
    currentState.didLeaveState()
    currentState = state
    currentState.didEnterState()
    ZMTraceSyncStrategyGoToState(state.identifier)
}
```


## How DTrace Works

## DTrace 如何工作

The D programming language is a compiled language. When we run the `dtrace(1)` tool, it compiles the script we pass to it into byte code. This byte code is then passed down into the kernel. Inside the kernel, there's an interpreter that runs this byte code.

D 语言是编译型语言。当运行 `dtrace(1)` 工具时，我们传入的脚本被编译成字节码。接着字节码被传入 kernel。在 kernel 中有一个解释器来运行这些字节码。

That's one of the reasons why the programming language was kept simple. No one wants a bug in a DTrace script to put the kernel into an infinite loop and hang the system.

这就是为什么这种编程语言可以保持简单。没人希望 DTrace 脚本中的 bug 引起 kernel 的死循环并导致系统挂起。

When we add static probes to an executable (an app or a framework), these are added to the executable as `S_DTRACE_DOF` (DTrace Object Format) sections and loaded into the kernel when the executable runs. That is how DTrace knows about the static probes.

当将静态探针加入可执行程序 (一个 app 或 framework)，它们被作为 `S_DTRACE_DOF` (Dtrace Object Format) 部分被加入，并且在程序运行时被加载进 kernel。这样 DTrace 就知道当前的静态探针。




## Final Words

## 最后的话

It should be obvious that DTrace is extremely powerful and flexible. However, it is important to note that DTrace is not a replacement for tried and true tools such as `malloc_history`, `heap`, etc. As always, use the right tool for the job at hand.

毫无疑问 DTrace 非常强大和灵活。然而需要注意的是 DTrace 并不是一些经过考验和真正的工具的替代品，如 `malloc_history`，`heap` 等。记得始终使用正确的工具。

Also, DTrace is not magic. You still have to understand the problem you're trying to solve.

另外，DTrace 并不是魔法。你仍然需要知道你要解决的问题所在。

That said, DTrace can bring your development skills and abilities to a new level. It allows you to track down problems in production code which are otherwise difficult or even impossible to locate.

这就是说，DTrace 可以使你的开发技能和能力达到一个新的水准。它可以让你在生产代码中追踪那些很难或不可能定位的问题。

If you have code that has `#ifdef TRACING` or `#if LOG_LEVEL == 1` in it, these are probably good candidates for code to be replaced by DTrace.

如果你的代码中有 `#ifdef TRACING` 或 `#if LOG_LEVEL == 1`，使用 DTrace 或许是很好的主意。

Be sure to check out the [Dynamic Tracing Guide][DynamicTracingGuideHTML] ([PDF version][DynamicTracingGuidePDF]). And peek into your system's `/usr/share/examples/DTTk` directory for some inspiration.

记得查看 [Dynamic Tracing Guide][DynamicTracingGuideHTML] ([PDF version][DynamicTracingGuidePDF])。并且在你系统的 `/usr/share/examples/DTTk` 文件夹中获取更多的灵感。

Happy debugging!

debug 快乐！



[DynamicTracingGuidePDF]: https://docs.oracle.com/cd/E23824_01/pdf/E22973.pdf "Oracle Solaris Dynamic Tracing Guide"
[DynamicTracingGuideHTML]: https://docs.oracle.com/cd/E23824_01/html/E22973/toc.html "Oracle Solaris Dynamic Tracing Guide"

[dtrace1man]: https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/dtrace.1.html "dtrace - generic front-end to the DTrace facility"
[oracleDTraceProviders]: https://docs.oracle.com/cd/E23824_01/html/E22973/gkyal.html "Oracle: DTrace Providers"
[DProgrammingLanguage]: https://docs.oracle.com/cd/E23824_01/html/E22973/gkwpo.html#scrolltoc "D Programming Language"
[ps1man]: https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/ps.1.html
[DTraceGuideChapter3]: https://docs.oracle.com/cd/E19253-01/817-6223/chp-variables/index.html "Dynamic Tracing Guide, Variables"
[DTraceGuideChapter9]: https://docs.oracle.com/cd/E19253-01/817-6223/chp-aggs/index.html "Dynamic Tracing Guide, Aggregations"
[AppleDocNSURLSessionTask]: https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSessionTask_class/index.html "ADC: NSURLSessionTask"
[AppleDocNSURLSessionTask_taskIdentifier]: https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSessionTask_class/index.html#//apple_ref/occ/instp/NSURLSessionTask/taskIdentifier "-[NSURLSessionTask taskIdentifer]"
[XcodeBuildDerivedFileDir]: https://developer.apple.com/library/mac/documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW43 "DERIVED_FILE_DIR"
[ioProvider]: https://docs.oracle.com/cd/E19253-01/817-6223/chp-io/index.html "io Provider"
[profileProvider]: https://docs.oracle.com/cd/E19253-01/817-6223/chp-profile/index.html "profile Provider"
[ipProvider]: https://wikis.oracle.com/display/DTrace/ip+Provider "ip Provider"
