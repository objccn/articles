
单例是整个 Cocoa 中被广泛使用的核心设计模式之一。事实上，苹果开发者库把单例作为 "Cocoa 核心竞争力" 之一。作为一个iOS开发者，我们经常和单例打交道，比如 `UIApplication` 和 `NSFileManager` 等等。我们在开源项目、苹果示例代码和 StackOverflow 中见过了无数使用单例的例子。Xcode 甚至有一个默认的 "Dispatch Once" 代码片段，可以使我们非常简单地在代码中添加一个单例：

    + (instancetype)sharedInstance
    {
        static dispatch_once_t once;
        static id sharedInstance;
        dispatch_once(&once, ^{
            sharedInstance = [[self alloc] init];
        });
        return sharedInstance;
    }

由于这些原因，单例在 iOS 开发中随处可见。问题是，它们很容易被滥用。

尽管有些人认为单例是 '反模式'， '魔鬼' 以及 ['病态的说谎者'][pathologicalLiars]，我不会去完全否认单例所带来的的好处，而是会展示一些使用单例所带来的问题，这样下一次在使用 `dispatch_once` 代码片段的自动补全功能时，你可以对它的影响进行评估，三思而行。

# 全局状态
    
大多数的开发者都认同使用全局可变的状态是不好的行为。太多状态使得程序难以理解，难以调试。我们这些面向对象的程序员在最小化代码的状态复杂程度的方面，有很多需要向函数式编程学习的地方。

    @implementation SPMath {
        NSUInteger _a;
        NSUInteger _b;
    }

    - (NSUInteger)computeSum
    {
        return _a + _b;
    }

在上面这个简单的数学库的实现中，程序员需要在调用 `computeSum` 前正确的设置实例变量 `_a` 和 `_b`。这样有以下问题：

1. `computeSum` 没有显式地通过使用参数的形式声明它依赖于 `_a` 和 `_b` 的状态。与仅仅通过查看函数声明就可以知道这个函数的输出依赖于哪些变量不同的是，另一个开发者必须查看这个函数的具体实现才能明白这个函数依赖那些变量。隐藏依赖是不好的。

2. 当为调用 `computeSum` 做准备而修改 `_a` 和 `_b` 的数值时，程序员需要保证这些修改不会影响任何其他依赖于这两个变量的代码的正确性。而这在多线程的环境中是尤其困难的。

把下面的代码和上面的例子做对比：
  
    + (NSUInteger)computeSumOf:(NSUInteger)a plus:(NSUInteger)b
    {
        return a + b;
    }

这里，对变量 `a` 和 `b` 的依赖被显式地声明了。我们不需要为了调用这个方法而去改变实例变量的状态。并且我们也不需要担心调用这个函数会留下持久的副作用。我们甚至可以把这个方法声明为类方法，这样就告诉了代码的阅读者这个方法不会修改任何实例的状态。

那么，这个例子和单例又有什么关系呢？用 Miško Hevery 的话来说，["单例就是披着羊皮的全局状态"][sheepsClothing]。一个单例可以被使用在任何地方，而不需要显式地声明依赖。就像变量 `_a` 和 `_b` 在 `computeSum` 内部被使用了，却没有被显式声明一样，程序的任意模块都可以调用 `[SPMySingleton sharedInstance]` 并且访问这个单例。这意味着任何和这个单例交互产生的副作用都会影响程序其他地方的任意代码。


    @interface SPSingleton : NSObject

    + (instancetype)sharedInstance;

    - (NSUInteger)badMutableState;
    - (void)setBadMutableState:(NSUInteger)badMutableState;

    @end
    
    @implementation SPConsumerA

    - (void)someMethod
    {
        if ([[SPSingleton sharedInstance] badMutableState]) {
            // ...
        }
    }

    @end
    
    @implementation SPConsumerB

    - (void)someOtherMethod
    {
        [[SPSingleton sharedInstance] setBadMutableState:0];
    }

    @end


在上面的例子中，`SPConsumerA` 和 `SPConsumerB` 是两个完全独立的模块。但是 `SPConsumerB` 可以通过使用单例提供的共享状态来影响 `SPConsumerA` 的行为。这种情况应该只能发生在 consumer B 显式引用了 A，并表明了两者之间的关系时。这里使用了单例，由于其具有全局和多状态的特性，导致隐式地在两个看起来完全不相关的模块之间建立了耦合。

让我们来看一个更具体的例子，并且暴露一个使用全局可变状态的额外问题。比如我们想要在我们的应用中构建一个网页查看器。为了支持这个查看器，我们构建了一个简单的 URL cache：

    @interface SPURLCache

    + (SPCache *)sharedURLCache;

    - (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request;
    
    @end    


这个开发者开始写一些单元测试来保证代码在一些不同的情况下都能达到预期。首先，他写了一个测试用例来保证网页查看器在设备没有连接时能够展示出错误信息。然后他写了一个测试用例来保证网页查看器能够正确的处理服务器错误。最后，他为成功情况时写了一个测试用例，来保证返回的网络内容能够被正确的显示出来。这个开发者运行了所有的测试用例，并且它们都如预期一样正确。赞！

几个月以后，这些测试用例开始出现失败，尽管网页查看器的代码从它写完后就从来没有再改动过！到底发生了什么？

原来，有人改变了测试的顺序。处理成功的那个测试用例首先被运行，然后再运行其他两个。处理错误的那两个测试用例现在竟然成功了，和预期不一样，因为 URL cache 这个单例把不同测试用例之间的 response 缓存起来了。

持久化状态是单元测试的敌人，因为单元测试在各个测试用例相互独立的情况下才有效。如果状态从一个测试用例传递到了另外一个，这样就和测试用例的执行顺序就有关系了。有 bug 的测试用例，尤其是那些本来不应该通过的测试用例，是非常糟糕的事情。

# 对象的生命周期

另外一个关键问题就是单例的生命周期。当你在程序中添加一个单例时，很容易会认为 “永远只会有一个实例”。但是在很多我看到过的 iOS 代码中，这种假定都可能被打破。

比如，假设我们正在构建一个应用，在这个应用里用户可以看到他们的好友列表。他们的每个朋友都有一张个人信息的图片，并且我们想使我们的应用能够下载并且在设备上缓存这些图片。 使用 `dispatch_once` 代码片段，我们可以写一个 `SPThumbnailCache` 单例：

    @interface SPThumbnailCache : NSObject

    + (instancetype)sharedThumbnailCache;

    - (void)cacheProfileImage:(NSData *)imageData forUserId:(NSString *)userId;
    - (NSData *)cachedProfileImageForUserId:(NSString *)userId;

    @end
    

我们继续构建我们的应用，一切看起来都很正常，直到有一天，我们决定去实现‘注销’功能，这样用户可以在应用中进行账号切换。突然我们发现我们将要面临一个讨厌的问题：用户相关的状态存储在全局单例中。当用户注销后，我们希望能够清理掉所有的硬盘上的持久化状态。否则，我们将会把这些被遗弃的数据残留在用户的设备上，浪费宝贵的硬盘空间。对于用户登出又登录了一个新的账号这种情况，我们也想能够对这个新用户使用一个全新的 `SPThumbnailCache` 实例。

问题在于按照定义单例被认为是“创建一次，永久有效”的实例。你可以想到一些对于上述问题的解决方案。或许我们可以在用户登出时移除这个单例：

    static SPThumbnailCache *sharedThumbnailCache;

    + (instancetype)sharedThumbnailCache
    {
        if (!sharedThumbnailCache) {
            sharedThumbnailCache = [[self alloc] init];
        }
        return sharedThumbnailCache;
    }
    
    + (void)tearDown
    {
        // The SPThumbnailCache will clean up persistent states when deallocated
        sharedThumbnailCache = nil;
    }

这是一个明显的对单例模式的滥用，但是它可以工作，对吧？

我们当然可以使用这种方式去解决，但是代价实在是太大了。我们不能使用简单的的 `dispatch_once` 方案了，而这个方案能够保证线程安全以及所有调用 `[SPThumbnailCache sharedThumbnailCache]` 的地方都能访问到同一个实例。现在我们需要对使用缩略图 cache 的代码的执行顺序非常小心。假设当用户正在执行登出操作时，有一些后台任务正在执行把图片保存到缓存中的操作: 

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[SPThumbnailCache sharedThumbnailCache] cacheProfileImage:newImage forUserId:userId];
    });

我们需要保证在所有的后台任务完成前， `tearDown` 一定不能被执行。这确保了 `newImage` 数据可以被正确的清理掉。或者，我们需要保证在缩略图 cache 被移除时，后台缓存任务一定要被取消掉。否则，一个新的缩略图 cache 的实例将会被延迟创建，并且之前用户的数据 (`newImage` 对象) 会被存储在它里面。

由于对于单例实例来说它没有明确的所有者，(因为单例自己管理自己的生命周期)，“关闭”一个单例变得非常的困难。

分析到这里，我希望你能够意识到，“这个缩略图 cache 从来就不应该作为一个单例！”。问题在于一个对象得生命周期可能在项目的最初阶段没有被很好得考虑清楚。举一个具体的例子，Dropbox 的 iOS 客户端曾经只支持一个账号登录。它以这样的状态存在了数年，直到有一天我们希望能够同时支持[多个用户账号][twoDropboxes]登录 (同时登陆私人账号和工作账号)。突然之间，我们以前的的假设“只能够同时有一个用户处于登录状态”就不成立了。如果假定了一个对象的生命周期和应用的生命周期一致，那你的代码的灵活扩展就受到了限制，早晚有一天当产品的需求产生变化时，你会为当初的这个假定付出代价的。

这里我们得到的教训是，单例应该只用来保存全局的状态，并且不能和任何作用域绑定。如果这些状态的作用域比一个完整的应用程序的生命周期要短，那么这个状态就不应该使用单例来管理。用一个单例来管理用户绑定的状态，是代码的坏味道，你应该认真的重新评估你的对象图的设计。

# 避免使用单例

既然单例对局部作用域的状态有这么多的坏处，那么我们应该怎样避免使用它们呢？

让我们来重温一下上面的例子。既然我们的缩略图 cache 的缓存状态是和具体的用户绑定的，那么让我们来定义一个user对象吧：

    @interface SPUser : NSObject

    @property (nonatomic, readonly) SPThumbnailCache *thumbnailCache;

    @end

    @implementation SPUser

    - (instancetype)init
    {
        if ((self = [super init])) {
            _thumbnailCache = [[SPThumbnailCache alloc] init];
    
            // Initialize other user-specific state...
        }
        return self;
    }

    @end
    
我们现在用一个对象来作为一个经过认证的用户会话的模型类，并且我们可以把所有和用户相关的状态存储在这个对象中。现在假设我们有一个view controller来展现好友列表：

    @interface SPFriendListViewController : UIViewController

    - (instancetype)initWithUser:(SPUser *)user;

    @end
    

我们可以显式地把经过认证的 user 对象作为参数传递给这个 view controller。这种把依赖性传递给依赖对象的技术正式的叫法是[依赖注入][dependencyInjection]，它有很多优点：

1. 对于阅读这个 `SPFriendListViewController` 头文件的读者来说，可以很清楚的知道它只有在有登录用户的情况下才会被展示。
2. 这个 `SPFriendListViewController` 只要还在使用中，就可以强引用 user 对象。举例来说，对于前面的例子，我们可以像下面这样在后台任务中保存一个图片到缩略图 cache 中：
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_user.thumbnailCache cacheProfileImage:newImage forUserId:userId];
        });
    
    就算后台任务还没有完成，应用其他地方的代码也可以创建和使用一个全新的 `SPUser` 对象，而不会在清理第一个实例时阻塞用户交互。

为了更详细的说明一下第二点，让我们画一下在使用依赖注入之前和之后的对象图。

假设我们的 `SPFriendListViewController` 是当前 window 的 root view controller。使用单例时，我们的对象图看起来如下所示：

<img src="/images/issues/issue-13/Screen%20Shot%202014-06-02%20at%205.21.20%20AM.png" width="412" />

view controller 自己，以及自定义的 image view 的列表，都会和 `sharedThumbnailCache` 产生交互。当用户登出后，我们想要清理 root view controller 并且退出到登录页面：

<img src="/images/issues/issue-13/Screen%20Shot%202014-06-02%20at%205.53.45%20AM.png" width="612" />

这里的问题在于这个好友列表的 view controller 可能仍然在执行代码 (由于后台操作的原因)，并且可能因此仍然有一些没有执行的涉及到 `sharedThumbnailCache` 的调用。

和使用依赖注入的解决方案对比一下：

<img src="/images/issues/issue-13/Screen%20Shot%202014-06-02%20at%205.38.59%20AM.png" width="412" />

简单起见，假设 `SPApplicationDelegate` 管理 `SPUser` 的实例 (在实践中，你可能会把这些用户状态的管理工作交给另外一个对象来做，这样可以使你的 application delegate [简化][lighterViewControllers])。当展现好友列表 view controller 时，会传递进去一个 user 的引用。这个引用也会向下传递给 profile image views。现在，当用户登出时，我们的对象图如下所示：

<img src="/images/issues/issue-13/Screen%20Shot%202014-06-02%20at%205.54.07%20AM.png" width="612" />

这个对象图看起来和使用单例时很像。那么，区别是什么呢？

关键问题是作用域。在单例那种情况中，`sharedThumbnailCache` 仍然可以被程序的任意模块访问。假如用户快速的登录了一个新的账号。该用户也想看看他的好友列表，这也就意味着需要再一次的和缩略图 cache 产生交互：

<img src="/images/issues/issue-13/Screen%20Shot%202014-06-02%20at%205.59.25%20AM.png" width="612" />

当用户登录一个新账号，我们应该能够构建并且与全新的 `SPThumbnailCache` 交互，而不需要再在销毁老的缩略图 cache 上花费精力。基于对象管理的典型规则，老的 view controllers 和老的缩略图 cache 应该能够自己在后台延迟被清理掉。简而言之，我们应该隔离用户 A 相关联的状态和用户 B 相关联的状态：

<img src="/images/issues/issue-13/Screen%20Shot%202014-06-02%20at%206.43.56%20AM.png" width="412" />

# 结论

希望这篇文章中的内容读起来不像奇幻小说那样难以理解。人们已经对单例的滥用抱怨了很多年了，并且我们也都知道全局状态是很不好的事情。但是在 iOS 开发的世界中，单例的使用是如此的普遍以至于我们有时候忘记了我们多年来在其他面向对象编程中学到的教训。

这一切的关键点是，在面向对象编程中我们想要最小化可变状态的作用域。但是单例却因为使可变的状态可以被程序中的任何地方访问，而站在了对立面。下一次你想使用单例时，我希望你能够好好考虑一下使用依赖注入作为替代方案。


[pathologicalLiars]: http://misko.hevery.com/2008/08/17/singletons-are-pathological-liars/
[sheepsClothing]: http://misko.hevery.com/2008/08/25/root-cause-of-singletons/
[dependencyInjection]: http://en.wikipedia.org/wiki/Dependency_injection
[lighterViewControllers]: http://www.objc.io/issue-1/lighter-view-controllers.html
[twoDropboxes]: https://www.dropbox.com/business/two-dropboxes

---
 

原文 [Avoiding Singleton Abuse](http://www.objc.io/issue-13/singletons.html)