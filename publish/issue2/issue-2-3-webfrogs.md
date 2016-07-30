这篇文章里，我们将会讨论一些 iOS 和 OS X 都可以使用的底层 API。除了 `dispatch_once` ，我们一般不鼓励使用其中的任何一种技术。

但是我们想要揭示出表面之下深层次的一些可利用的方面。这些底层的 API 提供了大量的灵活性，随之而来的是大量的复杂度和更多的责任。在我们的文章[常见的后台实践](http://objccn.io/issue-2-2/)中提到的高层的 API 和模式能够让你专注于手头的任务并且免于大量的问题。通常来说，高层的 API 会提供更好的性能，除非你能承受起使用底层 API 带来的纠结于调试代码的时间和努力。

尽管如此，了解深层次下的软件堆栈工作原理还是有很有帮助的。我们希望这篇文章能够让你更好的了解这个平台，同时，让你更加感谢这些高层的 API。

首先，我们将会分析大多数组成 *Grand Central Dispatch* 的部分。它已经存在了好几年，并且苹果公司持续添加功能并且改善它。现在苹果已经将其开源，这意味着它对其他平台也是可用的了。最后，我们将会看一下[原子操作](#atomic_operations)——另外的一种底层代码块的集合。

或许关于并发编程最好的书是 *M. Ben-Ari* 写的《Principles of Concurrent Programming》,[ISBN 0-13-701078-8](https://en.wikipedia.org/wiki/Special:BookSources/0-13-701078-8)。如果你正在做任何与并发编程有关的事情，你需要读一下这本书。这本书已经30多年了，仍然非常卓越。书中简洁的写法，优秀的例子和练习，带你领略并发编程中代码块的基本原理。这本书现在已经绝版了，但是它的一些复印版依然广为流传。有一个新版书，名字叫《Principles of Concurrent and Distributed Programming》,[ISBN 0-321-31283-X](https://en.wikipedia.org/wiki/Special:BookSources/0-321-31283-X),好像有很多相同的地方，不过我还没有读过。

## 从前...

或许GCD中使用最多并且被滥用功能的就是 `dispatch_once` 了。正确的用法看起来是这样的：


	+ (UIColor *)boringColor;
	{
	    static UIColor *color;
	    static dispatch_once_t onceToken;
	    dispatch_once(&onceToken, ^{
	        color = [UIColor colorWithRed:0.380f green:0.376f blue:0.376f alpha:1.000f];
	    });
	    return color;
	}


上面的 block 只会运行一次。并且在连续的调用中，这种检查是很高效的。你能使用它来初始化全局数据比如单例。要注意的是，使用 `dispatch_once_t` 会使得测试变得非常困难（单例和测试不是很好配合）。

要确保 `onceToken` 被声明为 `static` ，或者有全局作用域。任何其他的情况都会导致无法预知的行为。换句话说，**不要**把 `dispatch_once_t` 作为一个对象的成员变量，或者类似的情形。

退回到远古时代（其实也就是几年前），人们会使用 `pthread_once` ，因为 `dispatch_once_t` 更容易使用并且不易出错，所以你永远都不会再用到 `pthread_once` 了。


## 延后执行

另一个常见的小伙伴就是 `dispatch_after` 了。它使工作延后执行。它是很强大的，但是要注意：你很容易就陷入到一堆麻烦中。一般用法是这样的：

	- (void)foo
	{
	    double delayInSeconds = 2.0;
	    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delayInSeconds * NSEC_PER_SEC));
	    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
	        [self bar];
	    });
	}


第一眼看上去这段代码是极好的。但是这里存在一些缺点。我们不能（直接）取消我们已经提交到 `dispatch_after` 的代码，它将会运行。

另外一个需要注意的事情就是，当人们使用 `dispatch_after` 去处理他们代码中存在的时序 bug 时，会存在一些有问题的倾向。一些代码执行的过早而你很可能不知道为什么会这样，所以你把这段代码放到了 `dispatch_after` 中，现在一切运行正常了。但是几周以后，之前的工作不起作用了。由于你并不十分清楚你自己代码的执行次序，调试代码就变成了一场噩梦。所以不要像上面这样做。大多数的情况下，你最好把代码放到正确的位置。如果代码放到 `-viewWillAppear` 太早，那么或许 `-viewDidAppear` 就是正确的地方。

通过在自己代码中建立直接调用（类似 `-viewDidAppear` ）而不是依赖于  `dispatch_after` ，你会为自己省去很多麻烦。

如果你需要一些事情在某个特定的时刻运行，那么 `dispatch_after` 或许会是个好的选择。确保同时考虑了 `NSTimer`，这个API虽然有点笨重，但是它允许你取消定时器的触发。


## 队列

GCD 中一个基本的代码块就是队列。下面我们会给出一些如何使用它的例子。当使用队列的时候，给它们一个明显的标签会帮自己不少忙。在调试时，这个标签会在 Xcode (和 lldb)中显示，这会帮助你了解你的 app 是由什么决定的：

    - (id)init;
    {
        self = [super init];
        if (self != nil) {
            NSString *label = [NSString stringWithFormat:@"%@.isolation.%p", [self class], self];
            self.isolationQueue = dispatch_queue_create([label UTF8String], 0);
            
            label = [NSString stringWithFormat:@"%@.work.%p", [self class], self];
            self.workQueue = dispatch_queue_create([label UTF8String], 0);
        }
        return self;
    }


队列可以是并行也可以是串行的。默认情况下，它们是串行的，也就是说，任何给定的时间内，只能有一个单独的 block 运行。这就是隔离队列（原文：isolation queues。译注）的运行方式。队列也可以是并行的，也就是同一时间内允许多个 block 一起执行。

GCD 队列的内部使用的是线程。GCD 管理这些线程，并且使用 GCD 的时候，你不需要自己创建线程。但是重要的外在部分 GCD 会呈现给你，也就是用户 API，一个很大不同的抽象层级。当使用 GCD 来完成并发的工作时，你不必考虑线程方面的问题，取而代之的，只需考虑队列和功能点（提交给队列的 block）。虽然往下深究，依然都是线程，但是 GCD 的抽象层级为你惯用的编码提供了更好的方式。

队列和功能点同时解决了一个连续不断的扇出的问题：如果我们直接使用线程，并且想要做一些并发的事情，我们很可能将我们的工作分成 100 个小的功能点，然后基于可用的 CPU 内核数量来创建线程，假设是 8。我们把这些功能点送到这 8 个线程中。当我们处理这些功能点时，可能会调用一些函数作为功能的一部分。写那个函数的人也想要使用并发，因此当你调用这个函数的时候，这个函数也会创建 8 个线程。现在，你有了 8 × 8 = 64 个线程，尽管你只有 8 个CPU内核——也就是说任何时候只有12%的线程实际在运行而另外88%的线程什么事情都没做。使用 GCD 你就不会遇到这种问题，当系统关闭 CPU 内核以省电时，GCD 甚至能够相应地调整线程数量。

GCD 通过创建所谓的[线程池](http://en.wikipedia.org/wiki/Thread_pool_pattern)来大致匹配 CPU 内核数量。要记住，线程的创建并不是无代价的。每个线程都需要占用内存和内核资源。这里也有一个问题：如果你提交了一个 block 给 GCD，但是这段代码阻塞了这个线程，那么这个线程在这段时间内就不能用来完成其他工作——它被阻塞了。为了确保功能点在队列上一直是执行的，GCD 不得不创建一个新的线程，并把它添加到线程池。

如果你的代码阻塞了许多线程，这会带来很大的问题。首先，线程消耗资源，此外，创建线程会变得代价高昂。创建过程需要一些时间。并且在这段时间中，GCD 无法以全速来完成功能点。有不少能够导致线程阻塞的情况，但是最常见的情况与 I/O 有关，也就是从文件或者网络中读写数据。正是因为这些原因，你不应该在GCD队列中以阻塞的方式来做这些操作。看一下下面的[输入输出](#input_output)段落去了解一些关于如何以 GCD 运行良好的方式来做 I/O 操作的信息。

### 目标队列

你能够为你创建的任何一个队列设置一个**目标队列**。这会是很强大的，并且有助于调试。

为一个类创建它自己的队列而不是使用全局的队列被普遍认为是一种好的风格。这种方式下，你可以设置队列的名字，这让调试变得轻松许多—— Xcode 可以让你在 Debug Navigator 中看到所有的队列名字，如果你直接使用 `lldb`。`(lldb) thread list` 命令将会在控制台打印出所有队列的名字。一旦你使用大量的异步内容，这会是非常有用的帮助。

使用私有队列同样强调封装性。这时你自己的队列，你要自己决定如何使用它。

默认情况下，一个新创建的队列转发到默认优先级的全局队列中。我们就将会讨论一些有关优先级的东西。

你可以改变你队列转发到的队列——你可以设置自己队列的目标队列。以这种方式，你可以将不同队列链接在一起。你的 `Foo` 类有一个队列，该队列转发到 `Bar` 类的队列，`Bar` 类的队列又转发到全局队列。

当你为了隔离目的而使用一个队列时，这会非常有用。`Foo` 有一个隔离队列，并且转发到 `Bar` 的隔离队列，与 `Bar` 的隔离队列所保护的有关的资源，会自动成为线程安全的。 

如果你希望多个 block 同时运行，那要确保你自己的队列是并发的。同时需要注意，如果一个队列的目标队列是串行的（也就是非并发），那么实际上这个队列也会转换为一个串行队列。


### 优先级

你可以通过设置目标队列为一个全局队列来改变自己队列的优先级，但是你应该克制这么做的冲动。

在大多数情况下，改变优先级不会使事情照你预想的方向运行。一些看起简单的事情实际上是一个非常复杂的问题。你很容易会碰到一个叫做[优先级反转][2]的情况。我们的文章[《并发编程：API 及挑战》][3]有更多关于这个问题的信息，这个问题几乎导致了NASA的探路者火星漫游器变成砖头。

此外，使用 `DISPATCH_QUEUE_PRIORITY_BACKGROUND` 队列时，你需要格外小心。除非你理解了 *throttled I/O* 和 *background status as per setpriority(2)* 的意义，否则不要使用它。不然，系统可能会以难以忍受的方式终止你的 app 的运行。打算以不干扰系统其他正在做 I/O 操作的方式去做 I/O 操作时，一旦和优先级反转情况结合起来，这会变成一种危险的情况。


## 隔离

隔离队列是 GCD 队列使用中非常普遍的一种模式。这里有两个变种。


### 资源保护

多线程编程中，最常见的情形是你有一个资源，每次只有一个线程被允许访问这个资源。

我们在[有关多线程技术的文章][4]中讨论了*资源*在并发编程中意味着什么，它通常就是一块内存或者一个对象，每次只有一个线程可以访问它。

举例来说，我们需要以多线程（或者多个队列）方式访问 `NSMutableDictionary` 。我们可能会照下面的代码来做：

    - (void)setCount:(NSUInteger)count forKey:(NSString *)key
    {
        key = [key copy];
        dispatch_async(self.isolationQueue, ^(){
            if (count == 0) {
                [self.counts removeObjectForKey:key];
            } else {
                self.counts[key] = @(count);
            }
        });
    }
    
    - (NSUInteger)countForKey:(NSString *)key;
    {
        __block NSUInteger count;
        dispatch_sync(self.isolationQueue, ^(){
            NSNumber *n = self.counts[key];
            count = [n unsignedIntegerValue];
        });
        return count;
    }

通过以上代码，只有一个线程可以访问 `NSMutableDictionary` 的实例。

注意以下四点：

1. 不要使用上面的代码，请先阅读[多读单写](#multiple_readers_single_writer)和[锁竞争](#contention)
2. 我们使用 `async` 方式来保存值，这很重要。我们不想也不必阻塞当前线程只是为了等待*写操作*完成。当读操作时，我们使用 `sync` 因为我们需要返回值。
3. 从函数接口可以看出，`-setCount:forKey:` 需要一个 `NSString` 参数，用来传递给 `dispatch_async`。函数调用者可以自由传递一个 `NSMutableString` 值并且能够在函数返回后修改它。因此我们*必须*对传入的字符串使用 *copy* 操作以确保函数能够正确地工作。如果传入的字符串不是可变的（也就是正常的 `NSString` 类型），调用*copy*基本上是个空操作。
4. `isolationQueue` 创建时，参数 `dispatch_queue_attr_t` 的值必须是*DISPATCH_QUEUE_SERIAL*（或者0）。

<a id='multiple_readers_single_writer' name='multiple_readers_single_writer'> </a>
### 单一资源的多读单写

我们能够改善上面的那个例子。GCD 有可以让多线程运行的并发队列。我们能够安全地使用多线程来从 `NSMutableDictionary` 中读取只要我们不同时修改它。当我们需要改变这个字典时，我们使用 *barrier* 来分发这个 block。这样的一个 block 的运行时机是，在它之前所有计划好的 block 完成之后，并且在所有它后面的 block 运行之前。

以如下方式创建队列：

    self.isolationQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_CONCURRENT);

并且用以下代码来改变setter函数：

    - (void)setCount:(NSUInteger)count forKey:(NSString *)key
    {
        key = [key copy];
        dispatch_barrier_async(self.isolationQueue, ^(){
            if (count == 0) {
                [self.counts removeObjectForKey:key];
            } else {
                self.counts[key] = @(count);
            }
        });
    }

当使用并发队列时，要确保所有的 *barrier* 调用都是 *async* 的。如果你使用 `dispatch_barrier_sync` ，那么你很可能会使你自己（更确切的说是，你的代码）产生死锁。写操作*需要*  barrier，并且*可以*是 async 的。

<a id='contention' name='contention'> </a>
### 锁竞争

首先，这里有一个警告：上面这个例子中我们保护的资源是一个  `NSMutableDictionary`，出于这样的目的，这段代码运行地相当不错。但是在真实的代码中，把隔离放到正确的复杂度层级下是很重要的。

如果你对 `NSMutableDictionary` 的访问操作变得非常频繁，你会碰到一个已知的叫做锁竞争的问题。锁竞争并不是只是在 GCD 和队列下才变得特殊，任何使用了锁机制的程序都会碰到同样的问题——只不过不同的锁机制会以不同的方式碰到。

所有对  `dispatch_async`，`dispatch_sync` 等等的调用都需要完成某种形式的锁——以确保仅有一个线程或者特定的线程运行指定的代码。GCD 某些程序上可以使用时序(译注：原词为 scheduling)来避免使用锁，但在最后，问题只是稍有变化。根本问题仍然存在：如果你有**大量**的线程在相同时间去访问同一个锁或者队列，你就会看到性能的变化。性能会严重下降。

你应该从直接复杂层次中隔离开。当你发现了性能下降，这明显表明代码中存在设计问题。这里有两个开销需要你来平衡。第一个是独占临界区资源太久的开销，以至于别的线程都因为进入临界区的操作而阻塞。第二个是太频繁出入临界区的开销。在 GCD 的世界里，第一种开销的情况就是一个 block 在隔离队列中运行，它可能潜在的阻塞了其他将要在这个隔离队列中运行的代码。第二种开销对应的就是调用 `dispatch_async` 和 `dispatch_sync` 。无论再怎么优化，这两个操作都不是无代价的。

令人忧伤的，不存在通用的标准来指导如何正确的平衡，你需要自己评测和调整。启动 Instruments 观察你的 app 忙于什么操作。

如果你看上面例子中的代码，我们的临界区代码仅仅做了很简单的事情。这可能是也可能不是好的方式，依赖于它怎么被使用。

在你自己的代码中，要考虑自己是否在更高的层次保护了隔离队列。举个例子，类 `Foo` 有一个隔离队列并且它本身保护着对 `NSMutableDictionary` 的访问，代替的，可以有一个用到了 `Foo` 类的 `Bar` 类有一个隔离队列保护所有对类 `Foo` 的使用。换句话说，你可以把类 `Foo` 变为非线程安全的（没有隔离队列），并在 `Bar` 中，使用一个隔离队列来确保任何时刻只能有一个线程使用 `Foo` 。

<a name="async" id="async"> </a>
### 全都使用异步分发

我们在这稍稍转变以下话题。正如你在上面看到的，你可以同步和异步地分发一个  block，一个工作单元。我们在[《并发编程：API 及挑战》][5]）中讨论的一个非常普遍的问题就是[死锁][6]。在 GCD 中，以同步分发的方式非常容易出现这种情况。见下面的代码：

    dispatch_queue_t queueA; // assume we have this
    dispatch_sync(queueA, ^(){
        dispatch_sync(queueA, ^(){
            foo();
        });
    });

一旦我们进入到第二个 `dispatch_sync` 就会发生死锁。我们不能分发到queueA，因为有人（当前线程）正在队列中并且永远不会离开。但是有更隐晦的产生死锁方式：

    dispatch_queue_t queueA; // assume we have this
    dispatch_queue_t queueB; // assume we have this
    
    dispatch_sync(queueA, ^(){
        foo();
    });
    
    void foo(void)
    {
        dispatch_sync(queueB, ^(){
            bar();
        });
    }
    
    void bar(void)
    {
        dispatch_sync(queueA, ^(){
            baz();
        });
    }

单独的每次调用 `dispatch_sync()` 看起来都没有问题，但是一旦组合起来，就会发生死锁。

这是使用同步分发存在的固有问题，如果我们使用异步分发，比如：

    dispatch_queue_t queueA; // assume we have this
    dispatch_async(queueA, ^(){
        dispatch_async(queueA, ^(){
            foo();
        });
    });


一切运行正常。*异步调用不会产生死锁*。因此值得我们在任何可能的时候都使用异步分发。我们使用一个异步调用结果 block 的函数，来代替编写一个返回值（必须要用同步）的方法或者函数。这种方式，我们会有更少发生死锁的可能性。

异步调用的副作用就是它们很难调试。当我们在调试器里中止代码运行，回溯并查看已经变得没有意义了。

要牢记这些。死锁通常是最难处理的问题。

### 如何写出好的异步 API

如果你正在给设计一个给别人（或者是给自己）使用的 API，你需要记住几种好的实践。

正如我们刚刚提到的，你需要倾向于异步 API。当你创建一个 API，它会在你的控制之外以各种方式调用，如果你的代码能产生死锁，那么死锁就会发生。

如果你需要写的函数或者方法，那么让它们调用 `dispatch_async()` 。不要让你的函数调用者来这么做，这个调用应该在你的方法或者函数中来做。

如果你的方法或函数有一个返回值，异步地将其传递给一个回调处理程序。这个 API 应该是这样的，你的方法或函数同时持有一个结果 block 和一个将结果传递过去的队列。你函数的调用者不需要自己来做分发。这么做的原因很简单：几乎所有时间，函数调用都应该在一个适当的队列中，而且以这种方式编写的代码是很容易阅读的。总之，你的函数将会（必须）调用 `dispatch_async()` 去运行回调处理程序，所以它同时也可能在需要调用的队列上做这些工作。

如果你写一个类，让你类的使用者设置一个回调处理队列或许会是一个好的选择。你的代码可能像这样：

    - (void)processImage:(UIImage *)image completionHandler:(void(^)(BOOL success))handler;
    {
        dispatch_async(self.isolationQueue, ^(void){
            // do actual processing here
            dispatch_async(self.resultQueue, ^(void){
                handler(YES);
            });
        });
    }
    

如果你以这种方式来写你的类，让类之间协同工作就会变得容易。如果类 A 使用了类 B，它会把自己的隔离队列设置为 B 的回调队列。

## 迭代执行

如果你正在倒弄一些数字，并且手头上的问题可以拆分出同样性质的部分，那么 `dispatch_apply` 会很有用。

如果你的代码看起来是这样的：

    for (size_t y = 0; y < height; ++y) {
        for (size_t x = 0; x < width; ++x) {
            // Do something with x and y here
        }
    }

小小的改动或许就可以让它运行的更快：

    dispatch_apply(height, dispatch_get_global_queue(0, 0), ^(size_t y) {
        for (size_t x = 0; x < width; x += 2) {
            // Do something with x and y here
        }
    });

代码运行良好的程度取决于你在循环内部做的操作。

block 中运行的工作必须是非常重要的，否则这个头部信息就显得过于繁重了。除非代码受到计算带宽的约束，每个工作单元为了很好适应缓存大小而读写的内存都是临界的。这会对性能会带来显著的影响。受到临界区约束的代码可能不会很好地运行。详细讨论这些问题已经超出了这篇文章的范围。使用 `dispatch_apply` 可能会对性能提升有所帮助，但是性能优化本身就是个很复杂的主题。维基百科上有一篇关于 [Memory-bound function](https://en.wikipedia.org/wiki/Memory_bound) 的文章。内存访问速度在 L2，L3 和主存上变化很显著。当你的数据访问模式与缓存大小不匹配时，10倍性能下降的情况并不少见。


## 组

很多时候，你发现需要将异步的 block 组合起来去完成一个给定的任务。这些任务中甚至有些是并行的。现在，如果你想要在这些任务都执行完成后运行一些代码，"groups" 可以完成这项任务。看这里的例子：

    dispatch_group_t group = dispatch_group_create();
    
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_group_async(group, queue, ^(){
        // Do something that takes a while
        [self doSomeFoo];
        dispatch_group_async(group, dispatch_get_main_queue(), ^(){
            self.foo = 42;
        });
    });
    dispatch_group_async(group, queue, ^(){
        // Do something else that takes a while
        [self doSomeBar];
        dispatch_group_async(group, dispatch_get_main_queue(), ^(){
            self.bar = 1;
        });
    });
    
    // This block will run once everything above is done:
    dispatch_group_notify(group, dispatch_get_main_queue(), ^(){
        NSLog(@"foo: %d", self.foo);
        NSLog(@"bar: %d", self.bar);
    });


需要注意的重要事情是，所有的这些都是非阻塞的。我们从未让当前的线程一直等待直到别的任务做完。恰恰相反，我们只是简单的将多个 block 放入队列。由于代码不会阻塞，所以就不会产生死锁。

同时需要注意的是，在这个小并且简单的例子中，我们是怎么在不同的队列间进切换的。


### 对现有API使用 dispatch_group_t

一旦你将  groups 作为你的工具箱中的一部分，你可能会怀疑为什么大多数的异步API不把 `dispatch_group_t` 作为一个可选参数。这没有什么无法接受的理由，仅仅是因为自己添加这个功能太简单了，但是你还是要小心以确保自己使用 groups 的代码是成对出现的。

举例来说，我们可以给 Core Data 的 `-performBlock:` API 函数添加上 groups，就像这样：

    - (void)withGroup:(dispatch_group_t)group performBlock:(dispatch_block_t)block
    {
        if (group == NULL) {
            [self performBlock:block];
        } else {
            dispatch_group_enter(group);
            [self performBlock:^(){
                block();
                dispatch_group_leave(group);
            }];
        }
    }

当 Core Data 上的一系列操作(很可能和其他的代码组合起来)完成以后，我们可以使用 `dispatch_group_notify` 来运行一个 block 。

很明显，我们可以给 `NSURLConnection` 做同样的事情：

    + (void)withGroup:(dispatch_group_t)group 
            sendAsynchronousRequest:(NSURLRequest *)request 
            queue:(NSOperationQueue *)queue 
            completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
    {
        if (group == NULL) {
            [self sendAsynchronousRequest:request 
                                    queue:queue 
                        completionHandler:handler];
        } else {
            dispatch_group_enter(group);
            [self sendAsynchronousRequest:request 
                                    queue:queue 
                        completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                handler(response, data, error);
                dispatch_group_leave(group);
            }];
        }
    }


为了能正常工作，你需要确保:

* `dispatch_group_enter()` 必须要在 `dispatch_group_leave()`之前运行。
* `dispatch_group_enter()` 和 `dispatch_group_leave()` 一直是成对出现的（就算有错误产生时）。


## 事件源

GCD 有一个较少人知道的特性：事件源 `dispatch_source_t`。

跟 GCD 一样，它也是很底层的东西。当你需要用到它时，它会变得极其有用。它的一些使用是秘传招数，我们将会接触到一部分的使用。但是大部分事件源在 iOS 平台不是很有用，因为在 iOS 平台有诸多限制，你无法启动进程（因此就没有必要监视进程），也不能在你的 app bundle 之外写数据（因此也就没有必要去监视文件）等等。

GCD 事件源是以极其资源高效的方式实现的。

### 监视进程

如果一些进程正在运行而你想知道他们什么时候存在，GCD 能够做到这些。你也可以使用 GCD 来检测进程什么时候分叉，也就是产生子进程或者传送给了进程的一个信号（比如 `SIGTERM`）。

    NSRunningApplication *mail = [NSRunningApplication 
      runningApplicationsWithBundleIdentifier:@"com.apple.mail"];
    if (mail == nil) {
        return;
    }
    pid_t const pid = mail.processIdentifier;
    self.source = dispatch_source_create(DISPATCH_SOURCE_TYPE_PROC, pid, 
      DISPATCH_PROC_EXIT, DISPATCH_TARGET_QUEUE_DEFAULT);
    dispatch_source_set_event_handler(self.source, ^(){
        NSLog(@"Mail quit.");
    });
    dispatch_resume(self.source);

当 Mail.app 退出的时候，这个程序会打印出 **Mail quit.**。

注意：在所有的事件源被传递到你的事件处理器之前，必须调用 `dispatch_resume()`。

<a name="watching_files" id="watching_files"> </a>
### 监视文件

这种可能性是无穷的。你能直接监视一个文件的改变，并且当改变发生时事件源的事件处理将会被调用。

你也可以使用它来监视文件夹，比如创建一个 *watch folder*：

    NSURL *directoryURL; // assume this is set to a directory
    int const fd = open([[directoryURL path] fileSystemRepresentation], O_EVTONLY);
    if (fd < 0) {
        char buffer[80];
        strerror_r(errno, buffer, sizeof(buffer));
        NSLog(@"Unable to open \"%@\": %s (%d)", [directoryURL path], buffer, errno);
        return;
    }
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, 
      DISPATCH_VNODE_WRITE | DISPATCH_VNODE_DELETE, DISPATCH_TARGET_QUEUE_DEFAULT);
    dispatch_source_set_event_handler(source, ^(){
        unsigned long const data = dispatch_source_get_data(source);
        if (data & DISPATCH_VNODE_WRITE) {
            NSLog(@"The directory changed.");
        }
        if (data & DISPATCH_VNODE_DELETE) {
            NSLog(@"The directory has been deleted.");
        }
    });
    dispatch_source_set_cancel_handler(source, ^(){
        close(fd);
    });
    self.source = source;
    dispatch_resume(self.source);

你应该总是添加 `DISPATCH_VNODE_DELETE` 去检测文件或者文件夹是否已经被删除——然后就停止监听。


### 定时器

大多数情况下，对于定时事件你会选择 `NSTimer`。定时器的GCD版本是底层的，它会给你更多控制权——但要小心使用。

需要特别重点指出的是，为了让 OS 节省电量，需要为 GCD 的定时器接口指定一个低的余地值(译注：原文leeway value)。如果你不必要的指定了一个低余地值，将会浪费更多的电量。

这里我们设定了一个5秒的定时器，并允许有十分之一秒的余地值：

    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 
      0, 0, DISPATCH_TARGET_QUEUE_DEFAULT);
    dispatch_source_set_event_handler(source, ^(){
        NSLog(@"Time flies.");
    });
    dispatch_time_t start
    dispatch_source_set_timer(source, DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC, 
      100ull * NSEC_PER_MSEC);
    self.source = source;
    dispatch_resume(self.source);


### 取消

所有的事件源都允许你添加一个 *cancel handler* 。这对清理你为事件源创建的任何资源都是很有帮助的，比如关闭文件描述符。GCD 保证在 *cancel handle*  调用前，所有的事件处理都已经完成调用。

参考上面的[监视文件例子](#watching_files)中对 `dispatch_source_set_cancel_handler()` 的使用。

<a id='input_output' name='input_output'> </a>
## 输入输出

写出能够在繁重的 I/O 处理情况下运行良好的代码是一件非常棘手的事情。GCD 有一些能够帮上忙的地方。不会涉及太多的细节，我们只简单的分析下问题是什么，GCD 是怎么处理的。

习惯上，当你从一个网络套接字中读取数据时，你要么做一个阻塞的读操作，也就是让你个线程一直等待直到数据变得可用，或者是做反复的轮询。这两种方法都是很浪费资源并且无法度量。然而，`kqueue` 通过当数据变得可用时传递一个事件解决了轮询的问题，GCD 也采用了同样的方法，但是更加优雅。当向套接字写数据时，同样的问题也存在，这时你要么做阻塞的写操作，要么等待套接字直到能够接收数据。

在处理 I/O 时，还有一个问题就是数据是以数据块的形式到达的。当从网络中读取数据时，依据 MTU([]最大传输单元](https://en.wikipedia.org/wiki/Maximum_transmission_unit))，数据块典型的大小是在1.5K字节左右。这使得数据块内可以是任何内容。一旦数据到达，你通常只是对跨多个数据块的内容感兴趣。而且通常你会在一个大的缓冲区里将数据组合起来然后再进行处理。假设（人为例子）你收到了这样8个数据块：

    0: HTTP/1.1 200 OK\r\nDate: Mon, 23 May 2005 22:38
    1: :34 GMT\r\nServer: Apache/1.3.3.7 (Unix) (Red-H
    2: at/Linux)\r\nLast-Modified: Wed, 08 Jan 2003 23
    3: :11:55 GMT\r\nEtag: "3f80f-1b6-3e1cb03b"\r\nCon
    4: tent-Type: text/html; charset=UTF-8\r\nContent-
    5: Length: 131\r\nConnection: close\r\n\r\n<html>\r
    6: \n<head>\r\n  <title>An Example Page</title>\r\n
    7: </head>\r\n<body>\r\n  Hello World, this is a ve


如果你是在寻找 HTTP 的头部，将所有数据块组合成一个大的缓冲区并且从中查找 `\r\n\r\n` 是非常简单的。但是这样做，你会大量地复制这些数据。大量 *旧的* C 语言 API 存在的另一个问题就是，缓冲区没有所有权的概念，所以函数不得不将数据再次拷贝到自己的缓冲区中——又一次的拷贝。拷贝数据操作看起来是无关紧要的，但是当你正在做大量的 I/O 操作的时候，你会在 profiling tool(Instruments) 中看到这些拷贝操作大量出现。即使你仅仅每个内存区域拷贝一次，你还是使用了两倍的存储带宽并且占用了两倍的内存缓存。


### GCD 和缓冲区
最直接了当的方法是使用数据缓冲区。GCD 有一个 `dispatch_data_t` 类型，在某种程度上和 Objective-C 的 `NSData` 类型很相似。但是它能做别的事情，而且更通用。

注意，`dispatch_data_t` 可以被 retained 和 releaseed ，并且 `dispatch_data_t` *拥有*它持有的对象。

这看起来无关紧要，但是我们必须记住 GCD 只是纯 C 的 API，并且不能使用Objective-C。通常的做法是创建一个缓冲区，这个缓冲区要么是基于栈的，要么是  `malloc` 操作分配的内存区域 —— 这些都没有所有权。

`dispatch_data_t` 的一个相当独特的属性是它可以基于零碎的内存区域。这解决了我们刚提到的组合内存的问题。当你要将两个数据对象连接起来时：

    dispatch_data_t a; // Assume this hold some valid data
    dispatch_data_t b; // Assume this hold some valid data
    dispatch_data_t c = dispatch_data_create_concat(a, b);


数据对象 c 并不会将 a 和 b 拷贝到一个单独的，更大的内存区域里去。相反，它只是简单地 retain 了 a 和 b。你可以使用 `dispatch_data_apply` 来遍历对象 c 持有的内存区域：

    dispatch_data_apply(c, ^bool(dispatch_data_t region, size_t offset, const void *buffer, size_t size) {
        fprintf(stderr, "region with offset %zu, size %zu\n", offset, size);
        return true;
    });

类似的，你可以使用 `dispatch_data_create_subrange` 来创建一个不做任何拷贝操作的子区域。


### 读和写

在 GCD 的核心里，*调度 I/O*（译注：原文为 Dispatch I/O） 与所谓的*通道*有关。调度 I/O 通道提供了一种与从文件描述符中读写不同的方式。创建这样一个通道最基本的方式就是调用：

    dispatch_io_t dispatch_io_create(dispatch_io_type_t type, dispatch_fd_t fd, 
      dispatch_queue_t queue, void (^cleanup_handler)(int error));
      
这将返回一个持有文件描述符的创建好的通道。在你通过它创建了通道之后，你不准以任何方式修改这个文件描述符。

有两种从根本上不同类型的通道：流和随机存取。如果你打开了硬盘上的一个文件，你可以使用它来创建一个随机存取的通道（因为这样的文件描述符是可寻址的）。如果你打开了一个套接字，你可以创建一个流通道。

如果你想要为一个文件创建一个通道，你最好使用需要一个路径参数的 `dispatch_io_create_with_path` ，并且让 GCD 来打开这个文件。这是有益的，因为GCD会延迟打开这个文件以限制相同时间内同时打开的文件数量。

类似通常的 read(2)，write(2) 和 close(2) 的操作，GCD 提供了 `dispatch_io_read`，`dispatch_io_write` 和 `dispatch_io_close`。无论何时数据读完或者写完，读写操作调用一个回调 block 来结束。这些都是以非阻塞，异步 I/O 的形式高效实现的。

在这你得不到所有的细节，但是这里会提供一个创建TCP服务端的例子：

首先我们创建一个监听套接字，并且设置一个接受连接的事件源：

    _isolation = dispatch_queue_create([[self description] UTF8String], 0);
    _nativeSocket = socket(PF_INET6, SOCK_STREAM, IPPROTO_TCP);
    struct sockaddr_in sin = {};
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET6;
    sin.sin_port = htons(port);
    sin.sin_addr.s_addr= INADDR_ANY;
    int err = bind(result.nativeSocket, (struct sockaddr *) &sin, sizeof(sin));
    NSCAssert(0 <= err, @"");
    
    _eventSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, _nativeSocket, 0, _isolation);
    dispatch_source_set_event_handler(result.eventSource, ^{
        acceptConnection(_nativeSocket);
    });


当接受了连接，我们创建一个I/O通道：

    typedef union socketAddress {
        struct sockaddr sa;
        struct sockaddr_in sin;
        struct sockaddr_in6 sin6;
    } socketAddressUnion;
    
    socketAddressUnion rsa; // remote socket address
    socklen_t len = sizeof(rsa);
    int native = accept(nativeSocket, &rsa.sa, &len);
    if (native == -1) {
        // Error. Ignore.
        return nil;
    }
    
    _remoteAddress = rsa;
    _isolation = dispatch_queue_create([[self description] UTF8String], 0);
    _channel = dispatch_io_create(DISPATCH_IO_STREAM, native, _isolation, ^(int error) {
        NSLog(@"An error occured while listening on socket: %d", error);
    });
    
    //dispatch_io_set_high_water(_channel, 8 * 1024);
    dispatch_io_set_low_water(_channel, 1);
    dispatch_io_set_interval(_channel, NSEC_PER_MSEC * 10, DISPATCH_IO_STRICT_INTERVAL);
    
    socketAddressUnion lsa; // remote socket address
    socklen_t len = sizeof(rsa);
    getsockname(native, &lsa.sa, &len);
    _localAddress = lsa;


如果我们想要设置 `SO_KEEPALIVE`（如果使用了HTTP的keep-alive），我们需要在调用 `dispatch_io_create` 前这么做。

创建好 I/O 通道后，我们可以设置读取处理程序：

    dispatch_io_read(_channel, 0, SIZE_MAX, _isolation, ^(bool done, dispatch_data_t data, int error){
        if (data != NULL) {
            if (_data == NULL) {
                _data = data;
            } else {
                _data = dispatch_data_create_concat(_data, data);
            }
            [self processData];
        }
    });


如果所有你想做的只是读取或者写入一个文件，GCD 提供了两个方便的封装： `dispatch_read` 和 `dispatch_write` 。你需要传递给 `dispatch_read` 一个文件路径和一个在所有数据块读取后调用的 block。类似的，`dispatch_write` 需要一个文件路径和一个被写入的 `dispatch_data_t` 对象。

## 基准测试

在 GCD 的一个不起眼的角落，你会发现一个适合优化代码的灵巧小工具：

    uint64_t dispatch_benchmark(size_t count, void (^block)(void));


把这个声明放到你的代码中，你就能够测量给定的代码执行的平均的纳秒数。例子如下：

    size_t const objectCount = 1000;
    uint64_t n = dispatch_benchmark(10000, ^{
        @autoreleasepool {
            id obj = @42;
            NSMutableArray *array = [NSMutableArray array];
            for (size_t i = 0; i < objectCount; ++i) {
                [array addObject:obj];
            }
        }
    });
    NSLog(@"-[NSMutableArray addObject:] : %llu ns", n);

在我的机器上输出了：

    -[NSMutableArray addObject:] : 31803 ns

也就是说添加1000个对象到 NSMutableArray 总共消耗了31803纳秒，或者说平均一个对象消耗32纳秒。

正如 `dispatch_benchmark` 的[帮助页面](http://opensource.apple.com/source/libdispatch/libdispatch-84.5/man/dispatch_benchmark.3)指出的，测量性能并非如看起来那样不重要。尤其是当比较并发代码和非并发代码时，你需要注意特定硬件上运行的特定计算带宽和内存带宽。不同的机器会很不一样。如果代码的性能与访问临界区有关，那么我们上面提到的锁竞争问题就会有所影响。

不要把它放到发布代码中，事实上，这是无意义的，它是私有API。它只是在调试和性能分析上起作用。

访问帮助界面：

    curl "http://opensource.apple.com/source/libdispatch/libdispatch-84.5/man/dispatch_benchmark.3?txt" 
      | /usr/bin/groffer --tty -T utf8


<a id='atomic_operations' name='atomic_operations'> </a>
## 原子操作

头文件 `libkern/OSAtomic.h` 里有许多强大的函数，专门用来底层多线程编程。尽管它是内核头文件的一部分，它也能够在内核之外来帮助编程。

这些函数都是很底层的，并且你需要知道一些额外的事情。就算你已经这样做了，你还可能会发现一两件你不能做，或者不易做的事情。当你正在为编写高性能代码或者正在实现无锁的和无等待的算法工作时，这些函数会吸引你。

这些函数在 `atomic(3)` 的帮助页里全部有概述——运行 `man 3 atomic` 命令以得到完整的文档。你会发现里面讨论到了内存屏障。查看维基百科中关于[内存屏障](https://en.wikipedia.org/wiki/Memory_barrier)的文章。如果你还存在疑问，那么你很可能需要它。


### 计数器

`OSAtomicIncrement` 和 `OSAtomicDecrement` 有一个很长的函数列表允许你以原子操作的方式去增加和减少一个整数值 —— 不必使用锁（或者队列）同时也是线程安全的。如果你需要让一个全局的计数器值增加，而这个计数器为了统计目的而由多个线程操作，使用原子操作是很有帮助的。如果你要做的仅仅是增加一个全局计数器，那么无屏障版本的 `OSAtomicIncrement` 是很合适的，并且当没有锁竞争时，调用它们的代价很小。

类似的，`OSAtomicOr` ，`OSAtomicAnd`，`OSAtomicXor` 的函数能用来进行逻辑运算，而 `OSAtomicTest` 可以用来设置和清除位。

#### 比较和交换
`OSAtomicCompareAndSwap` 能用来做无锁的惰性初始化，如下：

    void * sharedBuffer(void)
    {
        static void * buffer;
        if (buffer == NULL) {
            void * newBuffer = calloc(1, 1024);
            if (!OSAtomicCompareAndSwapPtrBarrier(NULL, newBuffer, &buffer)) {
                free(newBuffer);
            }
        }
        return buffer;
    }

如果没有 buffer，我们会创建一个，然后原子地将其写到 `buffer` 中如果 `buffer` 为NULL。在极少的情况下，其他人在当前线程同时设置了 `buffer` ，我们简单地将其释放掉。因为比较和交换方法是原子的，所以它是一个线程安全的方式去惰性初始化值。NULL的检测和设置 `buffer` 都是以原子方式完成的。

明显的，使用 `dispatch_once()` 我们也可以完成类似的事情。


### 原子队列

`OSAtomicEnqueue()` 和 `OSAtomicDequeue()` 可以让你以线程安全，无锁的方式实现一个LIFO队列(常见的就是栈)。对有潜在精确要求的代码来说，这会是强大的代码。

还有  `OSAtomicFifoEnqueue()` 和 `OSAtomicFifoDequeue()` 函数是为了操作FIFO队列，但这些只有在头文件中才有文档 —— 阅读他们的时候要小心。


### 自旋锁

最后，`OSAtomic.h` 头文件定义了使用自旋锁的函数：`OSSpinLock`。同样的，维基百科有深入的有关[自旋锁](https://en.wikipedia.org/wiki/Spinlock)的信息。使用命令 `man 3 spinlock` 查看帮助页的 `spinlock(3)` 。当没有锁竞争时使用自旋锁代价很小。

在合适的情况下，使用自旋锁对性能优化是很有帮助的。一如既往：先测量，然后优化。不要做乐观的优化。

下面是 OSSpinLock 的一个例子：

    @interface MyTableViewCell : UITableViewCell
    
    @property (readonly, nonatomic, copy) NSDictionary *amountAttributes;
    
    @end
    
    
    
    @implementation MyTableViewCell
    {
        NSDictionary *_amountAttributes;
    }
    
    - (NSDictionary *)amountAttributes;
    {
        if (_amountAttributes == nil) {
            static __weak NSDictionary *cachedAttributes = nil;
            static OSSpinLock lock = OS_SPINLOCK_INIT;
            OSSpinLockLock(&lock);
            _amountAttributes = cachedAttributes;
            if (_amountAttributes == nil) {
                NSMutableDictionary *attributes = [[self subtitleAttributes] mutableCopy];
                attributes[NSFontAttributeName] = [UIFont fontWithName:@"ComicSans" size:36];
                attributes[NSParagraphStyleAttributeName] = [NSParagraphStyle defaultParagraphStyle];
                _amountAttributes = [attributes copy];
                cachedAttributes = _amountAttributes;
            }
            OSSpinLockUnlock(&lock);
        }
        return _amountAttributes;
    }


就上面的例子而言，或许用不着这么麻烦，但它演示了一种理念。我们使用了ARC的 `__weak` 来确保一旦 `MyTableViewCell` 所有的实例都不存在， `amountAttributes` 会调用 `dealloc` 。因此在所有的实例中，我们可以持有字典的一个单独实例。

这段代码运行良好的原因是我们不太可能访问到方法最里面的部分。这是很深奥的——除非你真正需要，不然不要在你的 App 中使用它。

---
 

   [1]: http://objccn.io/issue-2
   [2]: http://en.wikipedia.org/wiki/Priority_inversion
   [3]: http://objccn.io/issue-2-1/#priority_inversion
   [4]: http://objccn.io/issue-2-1/#shared_resources
   [5]: http://objccn.io/issue-2-1/#dead_locks
   [6]: http://zh.wikipedia.org/wiki/死锁

原文 [Low-Level Concurrency APIs](http://www.objc.io/issue-2/low-level-concurrency-apis.html)

译文 [Objc的底层并发API - webfrogs](http://webfrogs.me/2013/07/18/low-level_concurrency_apis/)