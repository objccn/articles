这篇文章将专注于实用技巧，设计模式，以及对于写出线程安全类和使用 GCD 来说所特别需要注意的一些[反面模式](http://zh.wikipedia.org/wiki/反面模式)。

## 线程安全

### Apple 的框架

首先让我们来看看 Apple 的框架。一般来说除非特别声明，大多数的类默认都不是线程安全的。对于其中的一些类来说，这是很合理的，但是对于另外一些来说就很有趣了。

就算是在经验丰富的 iOS/Mac 开发者，也难免会犯从后台线程去访问 UIKit/AppKit 这种错误。比如因为图片的内容本身就是从后台的网络请求中获取的话，顺手就在后台线程中设置了 `image` 之类的属性，这样的错误其实是屡见不鲜的。Apple 的代码都经过了性能的优化，所以即使你从别的线程设置了属性的时候，也不会产生什么警告。

在设置图片这个例子中，症结其实是你的改变通常要过一会儿才能生效。但是如果有两个线程在同时对图片进行了设定，那么很可能因为当前的图片被释放两次，而导致应用崩溃。这种行为是和时机有关系的，所以很可能在开发阶段没有崩溃，但是你的用户使用时却不断 crash。

现在没有**官方**的用来寻找类似错误的工具，但我们确实有一些技巧来避免这个问题。[UIKit Main Thread Guard](https://gist.github.com/steipete/5664345) 是一段用来监视每一次对 `setNeedsLayout` 和 `setNeedsDisplay` 的调用代码，并检查它们是否是在主线程被调用的。因为这两个方法在 UIKit 的 setter （包括 image 属性）中广泛使用，所以它可以捕获到很多线程相关的错误。虽然这个小技巧并不包含任何私有 API， 但我们还是不建议将它是用在发布产品中，不过在开发过程中使用的话还是相当赞的。

Apple没有把 UIKit 设计为线程安全的类是有意为之的，将其打造为线程安全的话会使很多操作变慢。而事实上 UIKit 是和主线程绑定的，这一特点使得编写并发程序以及使用 UIKit 十分容易的，你唯一需要确保的就是对于 UIKit 的调用总是在主线程中来进行。

#### 为什么 UIKit 不是线程安全的？

对于一个像 UIKit 这样的大型框架，确保它的线程安全将会带来巨大的工作量和成本。将 non-atomic 的属性变为 atomic 的属性只不过是需要做的变化里的微不足道的一小部分。通常来说，你需要同时改变若干个属性，才能看到它所带来的结果。为了解决这个问题，苹果可能不得不提供像 Core Data 中的 `performBlock:` 和 `performBlockAndWait:` 那样类似的方法来同步变更。另外你想想看，绝大多数对 UIKit 类的调用其实都是以**配置**为目的的，这使得将 UIKit 改为线程安全这件事情更显得毫无意义了。

然而即使是那些与配置共享的内部状态之类事情无关的调用，其实也不是线程安全的。如果你做过 iOS 3.2 或之前的黑暗年代的 app 开发的话，你肯定有过一边在后台准备图像时一边使用 NSString 的 `drawInRect:withFont:` 时的随机崩溃的经历。值得庆幸的事，在 iOS 4 中 [苹果将大部分绘图的方法和诸如 `UIColor` 和 `UIFont` 这样的类改写为了后台线程可用](http://developer.apple.com/library/ios/#releasenotes/General/WhatsNewIniOS/Articles/iPhoneOS4.html)。

但不幸的是 Apple 在线程安全方面的文档是极度匮乏的。他们推荐只访问主线程，并且甚至是绘图方法他们都没有明确地表示保证线程安全。因此在阅读文档的同时，去读读 [iOS 版本更新说明](http://developer.apple.com/library/ios/#releasenotes/General/WhatsNewIniOS/Articles/iPhoneOS4.html)会是一个很好的选择。

对于大多数情况来说，UIKit 类确实只应该用在应用的主线程中。这对于那些继承自 UIResponder 的类以及那些操作你的应用的用户界面的类来说，不管如何都是很正确的。

#### 内存回收 (deallocation) 问题

另一个在后台使用 UIKit 对象的的危险之处在于“内存回收问题”。Apple 在技术笔记 [TN2109](http://developer.apple.com/library/ios/#technotes/tn2109/_index.html) 中概述了这个问题，并提供了多种解决方案。这个问题其实是要求 UI 对象应该在主线程中被回收，因为在它们的 `dealloc` 方法被调用回收的时候，可能会去改变 view 的结构关系，而如我们所知，这种操作应该放在主线程来进行。

因为调用者被其他线程持有是非常常见的（不管是由于 operation 还是 block 所导致的），这也是很容易犯错并且难以被修正的问题。在 [AFNetworking 中也一直长久存在这样的 bug](https://github.com/AFNetworking/AFNetworking/issues/56)，但是由于其自身的隐蔽性而鲜为人知，也很难重现其所造成的崩溃。在异步的 block 或者操作中一致使用 `__weak`，并且不去直接访问局部变量会对避开这类问题有所帮助。

#### Collection 类

Apple 有一个[针对 iOS 和 Mac 的很好的总览性文档](https://developer.apple.com/library/ios/#documentation/Cocoa/Conceptual/Multithreading/ThreadSafetySummary/ThreadSafetySummary.html#//apple_ref/doc/uid/10000057i-CH12-SW1)，为大多数基本的 foundation 类列举了其线程安全特性。总的来说，比如 `NSArry` 这样不可变类是线程安全的。然而它们的可变版本，比如 `NSMutableArray` 是线程不安全的。事实上，如果是在一个队列中串行地进行访问的话，在不同线程中使用它们也是没有问题的。要记住的是即使你申明了返回类型是不可变的，方法里还是有可能返回的其实是一个可变版本的 collection 类。一个好习惯是写类似于 `return [array copy]` 这样的代码来确保返回的对象事实上是不可变对象。

与和[Java]()这样的语言不一样，Foundation 框架并不提供直接可用的 collection 类，这是有其道理的，因为大多数情况下，你想要的是在更高层级上的锁，以避免太多的加解锁操作。但缓存是一个值得注意的例外，iOS 4 中 Apple 添加的 `NSCache` 使用一个可变的字典来存储不可变数据，它不仅会对访问加锁，更甚至在低内存情况下会清空自己的内容。

也就是说，在你的应用中存在可变的且线程安全的字典是可以做到的。借助于 class cluster 的方式，我们也很容易[写出这样的代码](https://gist.github.com/steipete/5928916)。

### 原子属性 (Atomic Properties)

你曾经好奇过 Apple 是怎么处理 atomic 的设置/读取属性的么？至今为止，你可能听说过自旋锁 (spinlocks)，信标 (semaphores)，锁 (locks)，@synchronized 等，Apple 用的是什么呢？因为 [Objctive-C 的 runtime 是开源](http://www.opensource.apple.com/source/objc4/)的，所以我们可以一探究竟。

一个非原子的 setter 看起来是这个样子的：

    - (void)setUserName:(NSString *)userName {
          if (userName != _userName) {
              [userName retain];
              [_userName release];
              _userName = userName;
          }
    }
    
这是一个手动 retain/release 的版本，ARC 生成的代码和这个看起来也是类似的。当我们看这段代码时，显而易见要是 `setUserName:` 被并发调用的话会造成麻烦。我们可能会释放 `_userName` 两次，这回使内存错误，并且导致难以发现的 bug。

对于任何没有手动实现的属性，编译器都会生成一个 [`objc_setProperty_non_gc(id self, SEL _cmd, ptrdiff_t offset, id newValue, BOOL atomic, signed char shouldCopy)`](https://github.com/opensource-apple/objc4/blob/master/runtime/Accessors.subproj/objc-accessors.mm#L127) 的调用。在我们的例子中，这个调用的参数是这样的：

    objc_setProperty_non_gc(self, _cmd, 
      (ptrdiff_t)(&_userName) - (ptrdiff_t)(self), userName, NO, NO);`
      
`ptrdiff_t` 可能会吓到你，但是实际上这就是一个简单的指针算术，因为其实 Objective-C 的类仅仅只是 C 结构体而已。

`objc_setProperty` 调用的是如下方法：

    static inline void reallySetProperty(id self, SEL _cmd, id newValue, 
      ptrdiff_t offset, bool atomic, bool copy, bool mutableCopy) 
    {
        id oldValue;
        id *slot = (id*) ((char*)self + offset);
    
        if (copy) {
            newValue = [newValue copyWithZone:NULL];
        } else if (mutableCopy) {
            newValue = [newValue mutableCopyWithZone:NULL];
        } else {
            if (*slot == newValue) return;
            newValue = objc_retain(newValue);
        }
    
        if (!atomic) {
            oldValue = *slot;
            *slot = newValue;
        } else {
            spin_lock_t *slotlock = &PropertyLocks[GOODHASH(slot)];
            _spin_lock(slotlock);
            oldValue = *slot;
            *slot = newValue;        
            _spin_unlock(slotlock);
        }
    
        objc_release(oldValue);
    }
    
除开方法名字很有趣以外，其实方法实际做的事情非常直接，它使用了在 `PropertyLocks` 中的 128 个自旋锁中的 1 个来给操作上锁。这是一种务实和快速的方式，最糟糕的情况下，如果遇到了哈希碰撞，那么 setter 需要等待另一个和它无关的 setter 完成之后再进行工作。

虽然这些方法没有定义在任何公开的头文件中，但我们还是可用手动调用他们。我不是说这是一个好的做法，但是知道这个还是蛮有趣的，而且如果你想要同时实现原子属性**和**自定义的 setter 的话，这个技巧就非常有用了。

    // 手动声明运行时的方法
    extern void objc_setProperty(id self, SEL _cmd, ptrdiff_t offset, 
      id newValue, BOOL atomic, BOOL shouldCopy);
    extern id objc_getProperty(id self, SEL _cmd, ptrdiff_t offset, 
      BOOL atomic);

    #define PSTAtomicRetainedSet(dest, src) objc_setProperty(self, _cmd, 
      (ptrdiff_t)(&dest) - (ptrdiff_t)(self), src, YES, NO) 
    #define PSTAtomicAutoreleasedGet(src) objc_getProperty(self, _cmd, 
      (ptrdiff_t)(&src) - (ptrdiff_t)(self), YES)
      
      
[参考这个 gist](https://gist.github.com/steipete/5928690) 来获取包含处理结构体的完整的代码，但是我们其实并不推荐使用它。

#### 为何不用 @synchronized ？

你也许会想问为什么苹果不用 `@synchronized(self)` 这样一个已经存在的运行时特性来锁定属？？你可以看看[这里的源码](https://github.com/opensource-apple/objc4/blob/master/runtime/objc-sync.mm#L291)，就会发现其实发生了很多的事情。Apple 使用了[最多三个加/解锁序列](http://googlemac.blogspot.co.at/2006/10/synchronized-swimming.html)，还有一部分原因是他们也添加了[异常开解(exception unwinding)](https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/Multithreading/ThreadSafety/ThreadSafety.html#//apple_ref/doc/uid/10000057i-CH8-SW3)机制。相比于更快的自旋锁方式，这种实现要慢得多。由于设置某个属性一般来说会相当快，因此自旋锁更适合用来完成这项工作。`@synchonized(self)` 更适合使用在你
需要确保在发生错误时代码不会死锁，而是抛出异常的时候。

### 你自己的类

单独使用原子属性并不会使你的类变成线程安全。它不能保护你应用的逻辑，只能保护你免于在 setter 中遭遇到[竞态条件](http://objccn.io/issue-3-1)的困扰。看看下面的代码片段：

    if (self.contents) {
        CFAttributedStringRef stringRef = CFAttributedStringCreate(NULL, 
          (__bridge CFStringRef)self.contents, NULL);
        // 渲染字符串
    }
    
我之前在 [PSPDFKit](http://pspdfkit.com) 中就犯了这个错误。时不时地应用就会因为 `contents` 属性在通过检查之后却又被设成了 nil 而导致 EXC_BAD_ACCESS 崩溃。捕获这个变量就可以简单修复这个问题；

    NSString *contents = self.contents;
    if (contents) {
        CFAttributedStringRef stringRef = CFAttributedStringCreate(NULL, 
          (__bridge CFStringRef)contents, NULL);
        // 渲染字符串
    }


在这里这样就能解决问题，但是大多数情况下不会这么简单。想象一下我们还有一个 `textColor` 的属性，我们在一个线程中将两个属性都做了改变。我们的渲染线程有可能使用了新的内容，但是依旧保持了旧的颜色，于是我们得到了一组奇怪的组合。这其实也是为什么 Core Data 要将 model 对象都绑定在一个线程或者队列中的原因。

对于这个问题，其实没有万用解法。使用 [不可变模型](http://www.cocoawithlove.com/2008/04/value-of-immutable-values.html)是一个可能的方案，但是它也有自己的问题。另一种途径是限制对存在在主线程或者某个特定队列中的既存对象的改变，而是先进行一次拷贝之后再在工作线程中使用。对于这个问题的更多对应方法，我推荐阅读 Jonathan Sterling 的关于 [Objective-C 中轻量化不可变对象](http://www.jonmsterling.com/posts/2012-12-27-a-pattern-for-immutability.html)的文章。

一个简单的解决办法是使用 `@synchronize`。其他的方式都非常非常可能使你误入歧途，已经有太多聪明人在这种尝试上一次又一次地以失败告终。

#### 可行的线程安全设计

在尝试写一些线程安全的东西之前，应该先想清楚是不是真的需要。确保你要做的事情不会是过早优化。如果要写的东西是一个类似配置类 (configuration class) 的话，去考虑线程安全这种事情就毫无意义了。更正确的做法是扔一个断言上去，以保证它被正确地使用：

    void PSPDFAssertIfNotMainThread(void) {
        NSAssert(NSThread.isMainThread, 
          @"Error: Method needs to be called on the main thread. %@", 
          [NSThread callStackSymbols]);
    }
    

对于那些肯定应该线程安全的代码（一个好例子是负责缓存的类）来说，一个不错的设计是使用并发的 `dispatch_queue` 作为读/写锁，并且确保只锁着那些真的需要被锁住的部分，以此来最大化性能。一旦你使用多个队列来给不同的部分上锁的话，整件事情很快就会变得难以控制了。

于是你也可以重新组织你的代码，这样某些特定的锁就不再需要了。看看下面这段实现了一种多委托的代码（其实在大多数情况下，用 NSNotifications 会更好，但是其实也还是有[多委托的实用例子](https://code.google.com/r/riky-adsfasfasf/source/browse/Utilities/GCDMulticastDelegate.h)）的

    // 头文件
    @property (nonatomic, strong) NSMutableSet *delegates;

    // init方法中
    _delegateQueue = dispatch_queue_create("com.PSPDFKit.cacheDelegateQueue", 
      DISPATCH_QUEUE_CONCURRENT);
    
    - (void)addDelegate:(id<PSPDFCacheDelegate>)delegate {
        dispatch_barrier_async(_delegateQueue, ^{
            [self.delegates addObject:delegate];
        });
    }
    
    - (void)removeAllDelegates {
        dispatch_barrier_async(_delegateQueue, ^{
            self.delegates removeAllObjects];
        });
    }
    
    - (void)callDelegateForX {
        dispatch_sync(_delegateQueue, ^{
            [self.delegates enumerateObjectsUsingBlock:^(id<PSPDFCacheDelegate> delegate, NSUInteger idx, BOOL *stop) {
                // 调用delegate
            }];
        });
    }
    
    
除非 `addDelegate:` 或者 `removeDelegate:` 每秒要被调用上千次，否则我们可以使用一个相对简洁的实现方式：

    // 头文件
    @property (atomic, copy) NSSet *delegates;
    
    - (void)addDelegate:(id<PSPDFCacheDelegate>)delegate {
        @synchronized(self) {
            self.delegates = [self.delegates setByAddingObject:delegate];
        }
    }
    
    - (void)removeAllDelegates {
        @synchronized(self) {
            self.delegates = nil;
        }
    }
    
    - (void)callDelegateForX {
        [self.delegates enumerateObjectsUsingBlock:^(id<PSPDFCacheDelegate> delegate, NSUInteger idx, BOOL *stop) {
            // 调用delegate
        }];
    }


就算这样，这个例子还是有点理想化，因为其他人可以把变更限制在主线程中。但是对于很多数据结构，可以在可变更操作的方法中创建不可变的拷贝，这样整体的代码逻辑上就不再需要处理过多的锁了。

## GCD 的陷阱

对于大多数上锁的需求来说，GCD 就足够好了。它简单迅速，并且基于 block 的 API 使得粗心大意造成非平衡锁操作的概率下降了不少。然后，GCD 中还是有不少陷阱，我们在这里探索一下其中的一些。

### 将 GCD 当作递归锁使用

GCD 是一个对共享资源的访问进行串行化的队列。这个特性可以被当作锁来使用，但实际上它和 `@synchronized` 有很大区别。 GCD队列并非是[可重入](http://zh.wikipedia.org/w/index.php?title=可重入&variant=zh-cn)的，因为这将破坏队列的特性。很多有试图使用 `dispatch_get_current_queue()` 来绕开这个限制，但是这是一个[糟糕的做法](https://gist.github.com/steipete/3713233)，Apple 在 iOS6 中将这个方法标记为废弃，自然也是有自己的理由。

    // This is a bad idea.
    inline void pst_dispatch_sync_reentrant(dispatch_queue_t queue, 
      dispatch_block_t block) 
    {
        dispatch_get_current_queue() == queue ? block() 
                                              : dispatch_sync(queue, block);
    }
    

对当前的队列进行测试也许在简单情况下可以行得通，但是一旦你的代码变得复杂一些，并且你可能有多个队列在同时被锁住的情况下，这种方法很快就悲剧了。一旦这种情况发生，几乎可以肯定的是你会遇到[死锁](http://objccn.io/issue-2-1/#dead_locks)。当然，你可以使用 `dispatch_get_specific()`，这将截断整个队列结构，从而对某个特定的队列进行测试。要这么做的话，你还得为了在队列中附加标志队列的元数据，而去写自定义的队列构造函数。嘛，最好别这么做。其实在实用中，使用 `NSRecursiveLock` 会是一个更好的选择。

### 用 dispatch_async 修复时序问题

在使用 UIKit 的时候遇到了一些时序上的麻烦？很多时候，这样进行“修正”看来非常完美：

    dispatch_async(dispatch_get_main_queue(), ^{
        // Some UIKit call that had timing issues but works fine 
        // in the next runloop.
        [self updatePopoverSize];
    });
    
千万别这么做！相信我，这种做法将会在之后你的 app 规模大一些的时候让你找不着北。这种代码非常难以调试，并且你很快就会陷入用更多的 dispatch 来修复所谓的莫名其妙的"时序问题"。审视你的代码，并且找到合适的地方来进行调用（比如在 viewWillAppear 里调用，而不是 viewDidLoad 之类的）才是解决这个问题的正确做法。我在自己的代码中也还留有一些这样的 hack，但是我为它们基本都做了正确的文档工作，并且对应的 issue 也被一一记录过。

记住这不是真正的 GCD 特性，而只是一个在 GCD 下很容易实现的常见反面模式。事实上你可以使用 `performSelector:afterDelay:` 方法来实现同样的操作，其中 delay 是在对应时间后的 runloop。

### 在性能关键的代码中混用 dispatch_sync 和 dispatch_async

这个问题我花了好久来研究。在 [PSPDFKit](http://pspdfkit.com) 中有一个使用了 LRU（最久未使用）算法列表的缓存类来记录对图片的访问。当你在页面中滚动时，这个方法将被调用**非常多次**。最初的实现使用了 `dispatch_sync` 来进行实际有效的访问，使用 `dispatch_async` 来更新 LRU 列表的位置。这导致了帧数远低于原来的 60 帧的目标。

当你的 app 中的其他运行的代码阻挡了 GCD 线程的时候，dispatch manager 需要花时间去寻找能够执行 dispatch_async 代码的线程，这有时候会花费一点时间。在找到合适的执行线程之前，你的同步调用就会被 block 住了。其实在这个例子中，异步情况的执行顺序并不是很重要，但没有能将这件事情告诉 GCD 的好办法。读/写锁这里并不能起到什么作用，因为在异步操作中基本上一定会需要进行顺序写入，而在此过程中读操作将被阻塞住。如果误用了 `dispatch_async` 代价将会是非常惨重的。在将它用作锁的时候，一定要非常小心。

### 使用 dispatch_async 来派发内存敏感的操作

我们已经谈论了很多关于 NSOperations 的话题了，一般情况下，使用这个更高层级的 API 会是一个好主意。当你要处理一段内存敏感的操作的代码块时，这个优势尤为突出、

在 PSPDFKit 的老版本中，我用了 GCD 队列来将已缓存的 JPG 图片写到磁盘中。当 retina 的 iPad 问世之后，这个操作出现了问题。ß因为分辨率翻倍了，相比渲染这张图片，将它编码花费的时间要长得多。所以，操作堆积在了队列中，当系统繁忙时，甚至有可能因为内存耗尽而崩溃。

我们没有办法追踪有多少个操作在队列中等待运行（除非你手动添加了追踪这个的代码），我们也没有现成的方法来在接收到低内存通告的时候来取消操作、这时候，切换到 NSOperations 可以使代码变得容易调试得多，并且允许我们在不添加手动管理的代码的情况下，做到对操作的追踪和取消。

当然也有一些不好的地方，比如你不能在你的 `NSOperationQueue` 中设置目标队列（就像 `DISPATCH_QUEUE_PRIORITY_BACKGROUND` 之于 缓速 I/O 那样）。但这只是为了可调试性的一点小代价，而事实上这也帮助你避免遇到[优先级反转](http://objccn.io/issue-2-1/#priority_inversion)的问题。我甚至不推荐直接使用已经包装好的 `NSBlockOperation` 的 API，而是建议使用一个 NSOperation 的真正的子类，包括实现其 description。诚然，这样做工作量会大一些，但是能输出所有运行中/准备运行的操作是及其有用的。

---

 

   [1]: http://objccn.io/issue-2


原文 [Thread-Safe Class Design](http://www.objc.io/issue-2/thread-safe-class-design.html)
