很少有人听过 DTrace，它是隐藏在 OS 中的小宝藏。DTrace 是强大的 debug 工具 - 因为它拥有极其灵活的特性，并且因为与其它工具差异很大而可能相对不那么有名。

许多时候你的 app 的真正的用户或测试人员会看到一些意外的行为。DTrace 可以让你无需重启 app 就能够在生产版本上回答关于 app 的任何问题。

## 动态追踪

大概 10 年前，[Sun Microsystems](https://en.wikipedia.org/wiki/Sun_Microsystems) 创建了 DTrace，它的名字是 *Dynamic Trace* 的缩写。2007 年底，苹果公司将它集成在自己的 [操作系统](https://en.wikipedia.org/wiki/Mac_OS_X_Leopard) 中。

DTrace 是一个提供了 *zero disable cost* 的动态追踪框架，也就是说当代码中的探针关闭时，不会有额外的资源消耗 - 即使在生产版本中我们也可以将探针留在代码中。只有使用的时候才产生消耗。

DTrace 是**动态的**，也就是说我们可以将它附加在一个已经在运行的程序上，也可以不打断程序将它剥离。不需要重新编译或启动。

本文我们将重点介绍如何使用 DTrace 检查我们的程序，但值得注意的是 DTrace 是系统级的: 例如，一个单独的脚本可以观察到系统中**所有**进程的内存分配操作。可以查看 `/usr/share/examples/DTTk` 来深入了解一些非常好的例子。

### OS X vs. iOS

正如你现在可能已经猜到的，DTrace 只能在 OS X 上运行。苹果也在 iOS 上使用 DTrace，用以支持像 Instruments 这样的工具，但对于第三方开发者，DTrace 只能运行于 OS X 或 iOS 模拟器。

在 [Wire](https://www.wire.com)，即使我们被限制仅能在 iOS 模拟器上使用 DTrace，它也在 iOS 开发中非常有用。如果你读到本文并且认为在 iOS 设备上支持 DTrace 是个好提议，请提交 [enhancement request](https://bugreport.apple.com/) 给苹果。


### 探针和脚本

DTrace 有两部分：DTrace 探针，及附加在上面的 DTrace 脚本。

#### 探针

你可以将内置 (所谓静态的) 探针加入代码中。IA 探针看起来和普通的 C 函数非常相似。在 Wire，我们的同步代码有一个内部状态机器，我们定义了如下两个探针：

    provider syncengine_sync {
        probe strategy_go_to_state(int);
    }

探针被分组成所谓的 *providers*。参数 `int` 是正要进入的状态。在我们的 Objective-C (或 Swift) 代码中，简单的插入以下代码即可：

    - (void)goToState:(ZMSyncState *)state
    {
        [self.currentState didLeaveState];
        self.currentState = state;
        SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE(state.identifier);
        [self.currentState didEnterState];
    }

我们[后面](#staticProbes)会讨论如何整合并且把流程说清楚一些。

#### 脚本

现在我们可以编写一个 DTrace 小脚本来展示状态转变：

    syncengine_sync*:::strategy_go_to_state
    {
        printf("Transitioning to state %d\n", arg0);
    }

([后面](#DProgrammingLanguage)我们会详细展示 DTrace 脚本如何工作。)

如果将 DTrace 保存进 `state.d`，接下来我们可以使用 [`dtrace(1)` 命令行工具][dtrace1man] 来运行它：

    % sudo dtrace -q -s state.d

我们可以看到:

    Transitioning to state 1
    Transitioning to state 2
    Transitioning to state 5

正如我们所预期的，并没什么让人激动的。最后使用 `^C` 可以退出 DTrace。

<a name="ATimingExample"></a>
### 一个定时例子

因为 DTrace 消耗非常小，所以非常适合用来测试性能 - 即使需要测试的时间非常短。DTrace 中的时间单位是纳秒。

如果扩展上面的小例子，我们可以输出每个状态所花费的时间:

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

这些代码会输出:

    Transitioning to state QuickSync1
    Spent 2205 ms in state QuickSync1
    Transitioning to state QuickSync2
    Spent 115 ms in state QuickSync2
    Transitioning to state EventProcessing

脚本中有些新东西。`dtrace:::BEGIN` 语句在脚本开始时运行。脚本退出时有一个相应的 `END`。

我们还给第一个探针增加了一个断言 (predicate)，`/ last_state_timestamp != 0 /`。

最后我们使用全局变量来追踪最后的状态，以及什么时候进入该状态。

内置的 `walltimestamp` 变量返回当前时间相对于 Unix epoch 时间以来的纳秒数。

还有一个虚拟的单位为纳秒的时间戳变量，`vtimestamp`。它表示当前的线程在 CPU 上运行的时间减去在 DTrace 上花费的时间。最后，`machtimestamp` 对应 `mach_absolute_time()`。

对于上面的脚本，执行的顺序非常重要。我们有两个所谓的**语句**对应同一个探针，(`syncengine_sync*:::strategy_go_to_state`)。它们会按照在 D 程序中出现的顺序执行。

### 结合系统探针

操作系统，尤其是 kernel，提供了数以千计的探针，被分成不同的提供者 (provider) 组。其中的很多在 [Oracle 的 DTrace 文档][oracleDTraceProviders]中可以找到。
    
通过下面的脚本，我们可以用 `ip` 提供者中的 `send` 探针来检查转换到下一个状态之前通过网络发送了多少字节：

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
    
这次我们的目标为某个特定的进程 - `ip:::send` 会匹配系统的所有进程，而我们只对 `Wire` 进程感兴趣。我们运行如下的脚本：

    sudo dtrace -q -s sample-timing-3.d -p 198
    
这里 `198` 是进程标识 (亦称 PID)。我们可以在活动监视器这个 app 中找到这个数字，或者使用 [`ps(1)` 命令行工具][ps1man]。

我们会得到:

    Transitioning to state 6
    Sent 2043 bytes in previous state
    Transitioning to state 4
    Sent 581 bytes in previous state

<a name="DProgrammingLanguage"></a>
## D 语言

注意：这**不是**[W. Bright 和 A. Alexandrescu 的 D 语言](https://en.wikipedia.org/wiki/D_%28programming_language%29)。

D 语言的大部分跟 C 语言都非常相似，但总体架构是不同的。每一个 Dtrace 脚本由多个所谓的**探针语句**组成。

在上面的例子中，我们已经看到了一些这种**探针语句**。它们都符合如下的形式:

    probe descriptions
    / predicate /
    {
        action statements
    }

断言 (*predicate*) 和动作语句 (*action statement*) 部分都是可选的。

### 探针描述
    
探针描述定义了语句匹配什么探针。所有的部分都可以省略，形式如下：

    provider:module:function:name

例如，`syscall:::` 匹配所有 `syscall` 提供者的探针。我们可以使用 `*` 匹配任何字符串，例如 `syscall::*lwp*:entry` 匹配所有 `syscall` 提供者的 `entry`，并且函数名字包含 `lwp` 的探针。

一个探针描述可以包含多个探针，例如:

    syscall::*lwp*:entry, syscall::*sock*:entry
    {
        trace(timestamp);
    }

### 断言

当**动作语句**开始运行时我们可以使用断言来限制。当触发特定的探针时断言会被计算。如果断言结果为非 0，*action statements* 将会运行，这和 C 语言中的 `if` 语句类似。

我们可以使用不同的断言来判断同一个探针多次。如果有多个匹配，它们将会按照在 D 程序中的出现的顺序执行。

### 动作

动作包含在花括号中。D 语言是轻量，精悍而且简单的语言。

D 不支持控制流，比如循环和分支。我们不能定义任何用户函数。变量定义也是可选的。

这限制了我们能做的事情。但是一旦知道了一些常见的模式，这种简单也给了我们很多灵活性，我们将在下一节详细讨论。在 [D Programming Language][DProgrammingLanguage] 的指南中可以查看更多的细节。

## 常见 D 语言模式

下面的例子会给让我们认识一些我们能做的事情。
    
这个例子统计了 *App Store* 应用在 syscall (也就是一个系统调用，或对 kernel 中进行的调用) 中累计使用的时间。

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

如果运行这个并且开启 *App Store* 应用，然后用 `^C` 退出 DTrace 脚本，可以得到像这样的输出:

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

在这个例子中，*App Store* 在 `kevent64` 中花费了 3.6 秒。

这个脚本中有两个特别有意思的事情：线程本地变量 (`self->ts`) 和集积 (aggregation)。

### 变量作用域 (scope)

D 语言有 3 种变量作用域: 全局，线程本地，以及探针语句本地。

`foo` 或 `bar` 这样的全局变量在整个 D 语言中都是可见的。

线程本地变量命名为 `self->foo`，`self->bar` 等，并且存在与特定的线程中。

探针语句本地变量与 C 或 Swift 中的本地变量类似。对于中间结果来说很有用。

在这个脚本中，当进入 syscall 时我们使用第一个探针语句来匹配。我们将当前时间戳赋值给线程本地变量 `self->ts`：


    syscall:::entry
    / execname == "App Store" /
    {
        self->ts = timestamp;
    }

第二个语句在从 syscall 中返回时匹配。这个调用将和进入时是同一个线程，因此可以确定，即使有多个线程在同一时间进行系统调用，`self->ts` 也具有我们所期待的值。

我们在谓词里加入了 `self->ts != 0` 来确保即使脚本是在应用处于系统调用中的时候被追加的，它也能正确运行。否则，`timestamp - self->ts` 将会是一个非常大的值，因为这时 `self->ts` 是还没有被设置的初始值：

    syscall:::return
    / execname == "App Store" && self->ts != 0 /
    {
        @totals[probefunc] = sum(timestamp - self->ts);
    }

通过 [Dynamic Tracing Guide, “Variables.”][DTraceGuideChapter3] 可以查看关于变量的核心知识。

<a name="Aggregations"></a>
### 集积 (Aggregation)

这行代码使用了集积：

    @totals[probefunc] = sum(timestamp - self->ts);

这是 DTrace 的一个极其强大的特性。

我们将 `totals` 称为集积变量。变量名前面的 `@` 将它转变为集积行为。`probefunc` 是一个内置变量 - 它是探针函数的名字。对于 `syscall` 探针，`probefunc` 是正在运行的系统调用的名字。

`sum` 是集积函数。在这个例子中，该集积用来计算每一个 `probefunc` 对应的 `timestamp - self->ts` 的和。
    
[DTrace Guide](https://docs.oracle.com/cd/E19253-01/817-6223/chp-aggs-trunc/index.html) 展示了一个小例子，该例子使用集积来打印每秒钟调用系统最多的 10 个应用的系统调用的数量。

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

在大多数空闲的 OS X 上，可能会显示如下:

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

我们看到 Safari，WebKit 和 `cloudd` 很活跃。

下表为所有集积函数:

    Function Name     | Result 
    ------------------|---------
    count             | Number of times called
    sum               | Sum of the passed in values
    avg               | Average of the passed in values
    min               | Smallest of the passed in values
    max               | Largest of the passed in values
    lquantize         | Linear frequency distribution
    quantize          | Power-of-two frequency distribution

`quantize` 和 `lquantize` 函数可以给出一个关于传入的数量的概览:

    ip:::send
    {
        @bytes_sent[execname] = quantize(args[2]->ip_plength);
    }
              
上面的代码会输出类似这样的结果:

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

查看 [Dynamic Tracing Guide 的示例](https://docs.oracle.com/cd/E19253-01/817-6223/chp-aggs-2/index.html)来了解如何使用 `lquantize`。

### 联合数组

不管名字如何，D 语言中的数组更类似 Swift 或 Objective-C 中的字典。另外，它们都是可变的。

我们可以这样定义一个联合数组:

    int x[unsigned long long, char];

然后我们可以给它赋值:

    BEGIN
    {
        x[123ull, ’a’] = 456;
    }
    
对于 Wire 应用，我们想要追踪 [NSURLSessionTask][AppleDocNSURLSessionTask] 实例的往复时间。当开始一个任务时，我们触发一个[静态定义的探针](#staticProbes)，当完成时还有另一个探针。我们可以写一个简单的脚本：

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

我们传入 [`taskIdentifer`][AppleDocNSURLSessionTask_taskIdentifier] 作为 `arg1`，任务开始时 `arg0` 被设置为 4，任务完成时被设置为 6。

正如我们在第一个[定时的例子](#ATimingExample)中看到的那样，联合数组在为传入语句的 `enum` 值提供描述时也非常有用。

## 探针和提供者

让我们回过头看看可用的探针。
    
可以使用如下的命令来获得一个所有可用探针的列表:

    sudo dtrace -l | awk '{ match($2, "([a-z,A-Z]*)"); print substr($2, RSTART, RLENGTH); }' | sort -u

在 OS X 10.10 中有 79 个提供者。其中许多都与 kernel 和系统调用相关。

其中一些提供者是 [Dynamic Tracing Guide][oracleDTraceProviders] 文档中的原始集合中的一部分。让我们看看其中一些我们可用的。

### `dtrace` 提供者

我们[之前](#ATimingExample)提到过 `BEGIN` 和 `END` 探针。当以安静模式运行 DTrace 时，`dtrace:::END` 对于输出摘要尤其有用。错误发生时还有 `ERROR` 探针。

### `profile` 提供者

[`profile` 提供者][profileProvider]可以用来在某种程度上采样，这对于 Instruments 的用户来说应该非常熟悉。

我们可以以 1001 赫兹的频率来采样栈深度：

    profile-1001
    /pid == $1/
    {
        @proc[execname] = lquantize(stackdepth, 0, 20, 1);
    }

输出会是这样:

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

类似的，`tick-` 探针会每隔固定的时间间隔，以很高打断的级别触发。`profile-` 探针会在所有 CPU 上触发，而 `tick-` 每个间隔只会在一个 CPU 上。我们在上面的[集积](#Aggregations)例子中使用了 `tick-10sec` 。

### `pid` 提供者

`pid` 是一个有点野蛮的提供者。大多数时候，我们真的应该使用下面将要提到的[静态探针](#staticProbes)。

`pid` 是进程标识 (process identifier) 的缩写。它可以让我们在进入和退出进程时进行探测。这在**大多数**情况下是可行的。注意函数的进入和返回并不总是可以很好地界定，尤其是在**尾调用优化 (tail-call optimization)**时。另外还有某些函数并不需要创建栈帧等等情况。

当你不能改变代码来增加[静态探针](#staticProbes)时，`pid` 是一个强大的工具。

你可以追踪任何可见的函数。例如这个探针:

    pid123:libSystem:printf:return

这个探针会附加到进程标识 (PID) 为 123 的进程中的 `printf` 函数。

### `objc` 提供者

与 `pid` 提供者直接对应的是 `objc` 提供者。它为 Objective-C 方法的进入和退出提供了探针。还是使用[静态探针](#staticProbes)可以提供更好的灵活性。

`objc` 探针的格式如下：

    objcpid:[class-name[(category-name)]]:[[+|-]method-name]:[name]

举个例子：

    objc207:NSTableView:-*:entry

将匹配进程号 207 中的 `NSTableView` 的所有实例方法条目。因为冒号 (`:`) 在 DTrace 中表示探针的指定方案，因此 Objective-C 中方法名里的冒号需要用一个问号 (`?`) 来替代。比如要匹配 `-[NSDate dateByAddingTimeInterval:]` 的话，可以这么写：

    objc207:NSDate:-dateByAddingTimeInterval?:entry

通过查看 [`dtrace(1)` 帮助页面][dtrace1man]可以获得更多详细信息。

### `io` 提供者

为了追踪与磁盘输入输出相关的活动，[`io` 提供者][ioProvider] 定义了 6 个探针:

    start
    done
    wait-start
    wait-done
    journal-start
    journal-done

[Oracle 文档][ioProvider]中的例子展示了如何使用：

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

上面的例子会输出类似这样的结果：

    ??                   ??/com.apple.Safari.savedState/data.data  R
    ??            ??/Preferences/com.apple.Terminal.plist.kn0E7LJ  W
    ??                                            ??/vm/swapfile0  R
    ??              ??/Preferences/com.apple.Safari.plist.jEQRQ5N  W
    ??           ??/Preferences/com.apple.HIToolbox.plist.yBPXSnY  W
    ??       ??/fsCachedData/F2BF76DB-740F-49AF-94DC-71308E08B474  W
    ??                           ??/com.apple.Safari/Cache.db-wal  W
    ??                           ??/com.apple.Safari/Cache.db-wal  W
    ??       ??/fsCachedData/88C00A4D-4D8E-4DD8-906E-B1796AC949A2  W

# `ip` 提供者

[`ip` 提供者][ipProvider]有 `send` 和 `receive` 两个探针。任何时候数据通过 IP 被发送或接收都会触发。参数 `arg0` 到 `arg5` 提供了与发送或接收的 IP 包所相关的 kernel 结构体的访问入口。

可以将二者放入非常强大的网络调试工具中。它可以使 `tcpdump(1)` 的看起来像过时的玩意。`ip` 提供者可以让我们在需要的时候精确的输出我们所需要的信息。

查看[文档][ipProvider]获得更多很棒的示例。


<a name="staticProbes"></a>
## 定义自己的静态探针

DTrace 允许我们创建自己的探针，通过这个，我们可以为我们自己的 app 释放 DTrace 的真正威力。
    
这些在 DTrace 中被称作**静态探针**。我们在[第一个例子](#ATimingExample)中曾经简短的提到过。[Wire](https://itunes.apple.com/app/wire/id931134707?mt=12) 定义了自己的提供者和探针：

    provider syncengine_sync {
        probe strategy_go_to_state(int);
    }

然后我们在代码中调用探针:

    - (void)goToState:(ZMSyncState *)state
    {
        [self.currentState didLeaveState];
        self.currentState = state;
        SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE(state.identifier);
        [self.currentState didEnterState];
    }

一个可能的争论就是我们本来可以干脆直接使用 `objc` 提供者；使用我们自己的探针可以更具灵活性。以后我们可以修改 Objective-C 代码而不影响 DTrace 探针。

另外，静态探针给我们提供更方便的参数访问方式。通过上面我们可以看到我们如何利用它来追踪时间和输出日志。

DTrace 静态探针的强大之处在于给我们提供了稳定的接口来调试我们的代码，并且即便是在生产代码中这个接口也是存在的。即使对于应用的生产版本，当有人看到奇怪的行为，我们也可以给正在运行的应用附加一段 DTrace 脚本。DTrace 的灵活性还可以让我们将同一个探针用于其他目的。

我们可以将 DTrace 作为日志工具使用。还可以用来收集与时间，网络，请求等有关的详细的量化信息。

我们可以将探针留在生产代码中的原因是探针是**零损耗**的，或者公平点说，相当于一个测试和分支的 CPU 指令。

下面来看看如何将静态探针加入到我们的工程。

### 提供者描述

首先我们需要创建一个 `.d` 文件并定义提供者和探针。如果我们创建了一个 `provider.d` 文件并写入以下内容，会得到两个提供者:

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

提供者是 `syncengine_sync` 和 `syncengine_ui`。在每个提供者中，我们定义了一组探针。

### 创建头文件

现在我们需要将 `provider.d` 加入到 Xcode 的构建目标中。确保将类型设置为 *DTrace source*，这十分重要。Xcode 现在会在构建时自动处理。在这个步骤中，DTrace 会创建一个对应的 `provider.h` 头文件，我们可以引入它。将 `provider.d` 同时加入 Xcode 工程和相应的构建目标非常重要。

在处理时，Xcode 会调用 `dtrace(1)` 工具:

    dtrace -h -s provider.d

这会生成相应的头文件。该文件最后会出现在 [`DERIVED_FILE_DIR`][XcodeBuildDerivedFileDir] 中。可以通过以下方式在任何工程内的源文件中引用

    #import "provider.h"

Xcode 有一个内置的所谓 **build rule** 来处理 DTrace 提供者描述。比较 [objc.io Build 过程](http://objccn.io/issue-6-1)的内容来获取关于构建规则和构建处理的更多的信息。

### 增加探针

对于每一个静态探针，头文件会包含两个宏:


    PROVIDER_PROBENAME()
    PROVIDER_PROBENAME_ENABLED()

第一个是探针本身。第二个会在探针关闭时取值为 0。

DTrace 探针自己本身在没被启用时是零消耗的，也就是说只要没有附加在探针上的东西，它们就不会产生消耗。然而有时，我们可能想要提前判断或将数据发送给探针之前做一些预处理。在这些不太常见的情况下，我们可以使用 `_ENABLED()` 宏：

    if (SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE_ENABLED()) {
        argument = /* Expensive argument calculation code here */;
        SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE(argument);
    };

### 包装 DTrace 探针

代码可读性非常重要。随着增加越来越多的探针到代码中，我们需要确保代码不会因此而变得乱七八糟和难以理解。毕竟探针的目的是帮助我们而不是将事情变得更复杂。

我们所需要做的就是增加另一个简单的包装器。这些包装器既使代码的可读性更好了一些，也增加了 `if (…_ENABLED*())` 检查。
    
回到状态机器的例子中，我们的探针宏是这样的：

    SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE(state);
    
为了使它变得更简单，我们创建另一个头文件并定义：

    static inline void ZMTraceSyncStrategyGoToState(int d) {
        SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE(d);
    }
    
有了这个，之后我们就调用：

    ZMTraceSyncStrategyGoToState(state);

这看起来有点取巧，但是[驼峰式命名](https://en.wikipedia.org/wiki/CamelCase)确实能在混合普通的 Objective-C 和 Swift 代码风格方面做得更好。

更进一步的，如果我们看到上面定义的

    provider syncengine_ui {
        probe notification(int, intptr_t, char *, char *, int, int, int, int);
    };

有一长串的参数。在 Wire 中，我们用这个来记录 UI 通知日志。

这个探针有一长串的参数。我们决定只要一个探针来处理许多不同通知，这些通知都是同步代码发给 UI 用以提醒变化的。第一个参数，`arg0`，定义了是什么通知，第二个参数定义了 `NSNotification` 的 `object`。在这使得我们的 DTrace 脚本可以将感兴趣的范围限定在某几个指定的通知中。

剩余的参数定义根据预先的通知不同可以稍微宽松些，而且对于各个单独情况我们有多个包装函数。当想要传入两个 `NSUUID` 对象的情况，我们类似这样来调用包装函数：


    MTraceUserInterfaceNotification_UUID(1, note.object,
        conversation.remoteIdentifier, participant.user.remoteIdentifier,
            wasJoined, participant.isJoined, currentState.connectionState, 0);

这个包装函数是这样定义的:

    static inline void ZMTraceUserInterfaceNotification_UUID(int d, NSObject *obj, NSUUID *remoteID1, NSUUID *remoteID2, int e, int f, int g, int h) {
        if (SYNCENGINE_UI_NOTIFICATION_ENABLED()) {
            SYNCENGINE_UI_NOTIFICATION(d, (intptr_t) (__bridge void *) obj, remoteID1.transportString.UTF8String, remoteID2.transportString.UTF8String, e, f, g, h);
        }
    }

正如之前提到的，我们有两个目的。第一，不让类似 `(intptr_t) (__bridge void *)` 这样的代码把我们的代码搞的乱七八糟。另外，除非因为附加到探针的时候有需要，其他时候我们无需花费 CPU 周期将一个 `NSUUID` 转换为 `NSString` 并进一步转换为 `char const *`。

根据这个模式，我们可以定义多个包装器 / 辅助函数来复用相同的 DTrace 探针。

### DTrace 和 Swift

像这样包装 DTrace 探针可以让我们整合 Swift 和 DTrace 静态探针。`static line` 函数现在可以在 Swift 代码中直接调用。

    func goToState(state: ZMSyncState) {
        currentState.didLeaveState()
        currentState = state
        currentState.didEnterState()
        ZMTraceSyncStrategyGoToState(state.identifier)
    }

## DTrace 如何工作

D 语言是编译型语言。当运行 `dtrace(1)` 工具时，我们传入的脚本被编译成字节码。接着字节码被传入 kernel。在 kernel 中有一个解释器来运行这些字节码。

这就是为什么这种编程语言可以保持简单。没人希望 DTrace 脚本中的 bug 引起 kernel 的死循环并导致系统挂起。

当将静态探针加入可执行程序 (一个 app 或 framework)，它们被作为 `S_DTRACE_DOF` (Dtrace Object Format) 部分被加入，并且在程序运行时被加载进 kernel。这样 DTrace 就知道当前的静态探针。

## 最后的话

毫无疑问 DTrace 非常强大和灵活。然而需要注意的是 DTrace 并不是一些经过考验和真正的工具的替代品，如 `malloc_history`，`heap` 等。记得始终使用正确的工具。

另外，DTrace 并不是魔法。你仍然需要知道你要解决的问题所在。

这就是说，DTrace 可以使你的开发技能和能力达到一个新的水准。它可以让你在生产代码中追踪那些很难或不可能定位的问题。

如果你的代码中有 `#ifdef TRACING` 或 `#if LOG_LEVEL == 1`，使用 DTrace 替换它们或许是很好的主意。

记得查看 [Dynamic Tracing Guide][DynamicTracingGuideHTML] ([PDF version][DynamicTracingGuidePDF])。并且在你系统的 `/usr/share/examples/DTTk` 文件夹中获取更多的灵感。

调试快乐！

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

---

 

原文 [DTrace](http://www.objc.io/issue-19/dtrace.html)