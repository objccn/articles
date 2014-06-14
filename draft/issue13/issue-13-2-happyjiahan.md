---
layout: post
title:  "Avoiding Singleton Abuse"
category: "13"
date: "2014-06-09 10:00:00"
tags: article
author: "<a href=\"https://twitter.com/stephenpoletto\">Stephen Poletto</a>"
---

Singletons are one of the core design patterns used throughout Cocoa. In fact, Apple's Developer Library considers the singleton one of the "Cocoa Core Competencies." As iOS developers, we're familiar with interacting with singletons, from `UIApplication` to `NSFileManager`. We've seen countless examples of singleton usage in open-source projects, in Apple's code samples, and on StackOverflow. Xcode even has a default code snippet, the "Dispatch Once" snippet, which makes it incredibly easy to add a singleton to your code:

单例是整个Cocoa中被广泛使用的核心设计模式之一。事实上，苹果开发者库把单例作为"Cocoa核心竞争力"之一。作为一个iOS开发者，我们经常和单例打交道，比如`UIApplication`和`NSFileManager`等等。我们在开源项目、苹果示例代码和StackOverflow中见过了无数使用单例的例子。Xcode 甚至有一个默认的 "Dispatch Once" 代码片段(code snippet)，可以使我们异常简单在代码中添加一个单例：

    + (instancetype)sharedInstance
    {
        static dispatch_once_t once;
        static id sharedInstance;
        dispatch_once(&once, ^{
            sharedInstance = [[self alloc] init];
        });
        return sharedInstance;
    }


For these reasons, singletons are commonplace in iOS programming. The problem is that they're easy to abuse.
由于这些原因，单例在iOS开发中随处可见。问题是，它们很容易被滥用。

While others have called singletons an 'anti-pattern,' 'evil,' and ['pathological liars'][pathologicalLiars], I won't completely rule out the merit of singletons. Instead, I want to demonstrate a few problems with singletons so that the next time you're about to auto-complete that `dispatch_once` snippet, you think twice about the implications.

尽管有些人认为单例是 '反模式,' '魔鬼,' 和 ['病态的说谎者'][pathologicalLiars]，但是我不能完全的排除单例所带来的好处。相反，我会展示一些使用单例所带来的问题，这样下一次你使用 `dispatch_once` 代码片段的自动补全功能时，三思一下它的影响。

#Global State
#全局状态

Most developers agree that global mutable state is a bad thing. Statefulness makes programs hard to understand and hard to debug. We object-oriented programmers have much to learn from functional programming, in terms of minimizing the statefulness of code.
    
大多数的开发者都认同使用全局可变的状态是不好的行为。有状态使得程序难以理解和难以调试。我们这些面向对象的程序员在最小化代码的有状态性方面，有很多还需要向函数式编程学习的地方。

    @implementation SPMath {
        NSUInteger _a;
        NSUInteger _b;
    }

    - (NSUInteger)computeSum
    {
        return _a + _b;
    }
    
In the above implementation of a simple math library, the programmer is expected to set instance variables `_a` and `_b` to the proper values before invoking `computeSum`. There are a few problems here:
在上面这个简单的数学库的实现中，程序员需要在调用 `computeSum`前正确的设置实例变量`_a` and `_b`。这样有以下问题：

1. `computeSum` does not make the fact that it depends upon states `_a` and `_b` explicit by taking the values as parameters. Instead of inspecting the interface and understanding which variables control the output of the function, another developer reading this code must inspect the implementation to understand the dependency. Hidden dependencies are bad.

1. `computeSum` 没有显示的通过使用参数的形式声明它依赖于`_a` 和 `_b`的状态。与仅仅通过查看函数声明就可以知道这个函数的输出依赖于哪些变量不同的是，另一个开发者必须查看这个函数的具体实现才能明白这个函数依赖那些变量。隐藏依赖是不好的。

2. When modifying `_a` and `_b` in preparation for calling `computeSum`, the programmer needs to be sure the modification does not affect the correctness of any other code that depends upon these variables. This is particularly difficult in multi-threaded environments.

2. 当修改`_a` and `_b`的数值为调用 `computeSum`做准备时，程序员需要保证这些修改不会影响任何其他依赖于这两个变量的代码的正确性。而这在多线程的环境中是尤其困难的。

Contrast the above example with this: 
把下面的代码和上面的例子做对比: 
  
    + (NSUInteger)computeSumOf:(NSUInteger)a plus:(NSUInteger)b
    {
        return a + b;
    }


Here, the dependency on `a` and `b` is made explicit. We don't need to mutate instance state in order to call this method. And we don't need to worry about leaving behind persistent side effects as a result of calling this method. As a note to the reader of this code, we can even make this method a class method to indicate that it does not modify instance state.

这里，对变量`a` 和 `b` 的依赖被显示的声明了。我们不需要为了调用这个方法而去改变实例变量的状态。并且我们也不需要担心调用这个函数会留下持久的副作用。我们甚至可以把这个方法声明为类方法，这样就显示的告诉了代码的阅读者这个方法不会修改任何实例的状态。

So how does this example relate to singletons? In the words of Miško Hevery, ["Singletons are global state in sheep’s clothing."][sheepsClothing] A singleton can be used anywhere, without explictly declaring the dependency. Just like `_a` and `_b` were used in `computeSum` without the depedency being made explict, any module of the program can call `[SPMySingleton sharedInstance]` and get access to the singleton. This means any side effects of interacting with the singleton can affect arbitrary code elsewhere in the program.

那么，这个例子和单例相比又有什么关系呢？用 Miško Hevery 的话来说，["单例就是披着羊皮的全局状态"][sheepsClothing] 。一个单例可以在不需要显示声明对其依赖的情况下，被使用在任何地方。就像变量`_a` 和 `_b` 在 `computeSum` 内部被使用了，却没有被显示声明一样，程序的任意模块都可以调用`[SPMySingleton sharedInstance]` 并且访问这个单例。这意味着任何和这个单例交互产生的副作用都会影响程序其他地方的任意代码。


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
    
In the example above, `SPConsumerA` and `SPConsumerB` are two completely independent modules of the program. Yet `SPConsumerB` is able to affect the behavior of `SPConsumerA` through the shared state provided by the singleton. This should only be possible if consumer B is given an explicit reference to A, making clear the relationship between the two. The singleton here, due to its global and stateful nature, causes hidden and implicit coupling between seemingly unrelated modules.
在上面的代码中，`SPConsumerA` and `SPConsumerB`是两个完全独立的模块。但是`SPConsumerB` 可以通过使用单例提供的共享状态来影响 `SPConsumerA` 的行为。这种情况应该只能发生在consumer B显示引用了A，显示建立了它们两者之间的关系时。由于这里使用了单例，单例的全局性和有状态性，导致隐式的在两个看起来完全不相关的模块之间建立了耦合。

Let's take a look at a more concrete example, and expose one additional problem with global mutable state. Let's say we want to build a web viewer inside our app. To support this web viewer, we build a simple URL cache:
让我们来看一个更具体的例子，并且暴露一个使用全局可变状态的额外问题。我们想要在我们的应用中构建一个网页查看器(web viewer)。我们构建了一个简单的 URL cache来支持这个网页查看器：

    @interface SPURLCache

    + (SPCache *)sharedURLCache;

    - (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request;
    
    @end    


The developer working on the web viewer starts writing some unit tests to make sure the code works as expected in a few different situations. First, he or she writes a test to make sure the web viewer shows an error when there's no device connectivity. Then he or she writes a test to make sure the web viewer handles server failures properly. Finally, he or she writes a test for the basic success case, to make sure the returned web content is shown properly. The developer runs all of the tests, and they work as expected. Nice!
这个开发者开始写了一些单元测试来保证代码在不同的情况下都能达到预期。首先，他写了一个测试用例来保证网页查看器在没有设备链接时能够展示出错误信息。然后他写了一个测试用例来保证网页查看器能够正确的处理服务器错误。最后，他为成功情况时写了一个测试用例，来保证返回的网络内容能够被正确的显示出来。这个开发者运行了所有的测试用例，并且它们都如预期一样正确。赞！

A few months later, these tests start failing, even though the web viewer code hasn't changed since it was first written! What happened?
几个月以后，这些测试用例开始出现失败，尽管网页查看器的代码从它写完后就从来没有再改动过！到底发生了什么？

It turns out someone changed the order of the tests. The success case test is running first, followed by the other two. The error cases are now succeeding unexpectedly, because the singleton URL cache is caching the response across the tests.
原来，有人改变了测试的顺序。处理成功的那个测试用例首先被运行，然后再运行其他两个。处理错误的那两个测试用例现在竟然成功了，和预期不一样，因为 URL cache 这个单例把不同测试用例之间的response缓存起来了。

Persistent state is the enemy of unit testing, since unit testing is made effective by each test being independent of all other tests. If state is left behind from one test to another, then the order of execution of tests suddenly matters. Buggy tests, especially when a test succeeds when it shouldn't, are a very bad thing.
持久化状态是单元测试的敌人，因为单元测试在各个测试用例相互独立的情况下才有效。如果状态从一个测试用例传递到了另外一个，这样就和测试用例的执行顺序就有关系了。有bug的测试用例是非常糟糕的事情，特别是那些有时候能通过测试，有时候又不能通过测试的。

#Object Lifecycle
#对象的生命周期

The other major problem with singletons is their lifecycle. When adding a singleton to your program, it's easy to think, "There will only ever be one of these." But in much of the iOS code I've seen in the wild, that assumption can break down.
另外一个关键问题就是单例的生命周期。当你在程序中添加一个单例时，很容易会认为 “它们永远只能有一个实例”。但是在很多我看到过的iOS代码中，这种假定都可能被打破。

For example, suppose we're building an app where users can see a list of their friends. Each of their friends has a profile picture, and we want the app to be able to download and cache those images on the device. With the `dispatch_once` snippet handy, we might find ourselves writing an `SPThumbnailCache` singleton:
比如，假设我们正在构建一个应用，在这个应用里用户可以看到他们的好友列表。他们的每个朋友都有一张个人信息的图片，并且我们想使我们的应用能够下载并且在设备上缓存这些图片。 使用`dispatch_once` 代码片段，我们可以写一个`SPThumbnailCache`单例：

    @interface SPThumbnailCache : NSObject

    + (instancetype)sharedThumbnailCache;

    - (void)cacheProfileImage:(NSData *)imageData forUserId:(NSString *)userId;
    - (NSData *)cachedProfileImageForUserId:(NSString *)userId;

    @end
    

We continue building out the app, and all seems well in the world, until one day, when we decide it's time to implement the 'log out' functionality, so users can switch accounts inside the app. Suddenly, we have a nasty problem on our hands: user-specific state is stored in a global singleton. When the user signs out of the app, we want to be able to clean up all persistent states on disk. Otherwise, we'll leave behind orphaned data on the user's device, wasting precious disk space. In case the user signs out and then signs into a new account, we also want to be able to have a new `SPThumbnailCache` for the new user.
我们继续构建我们的应用，一切看起来都很正常，直到有一天，当我们决定去实现‘注销’功能时，这样用户可以在应用中进行账号切换。突然我们发现我们将要面临一个讨厌的问题：用户相关的状态存储在全局单例中。当用户注销后，我们希望能够清理掉所有的硬盘上的持久化状态。否则，我们将会把这些被遗弃的数据残留在用户的设备上，浪费宝贵的硬盘空间。对于用户登出又登录了一个新的账号这种情况，我们也想能够对这个新用户使用一个全新的`SPThumbnailCache` 实例。

The problem here is that singletons, by definition, are assumed to be "create once, live forever" instances. You could imagine a few solutions to the problem outlined above. Perhaps we could tear down the singleton instance when the user signs out:
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

This is a flagrant abuse of the singleton pattern, but it will work, right?
这是一个明显的对单例模式的滥用，但是它可以工作，对吧？


We could certainly make this solution work, but the cost is far too great. For one, we've lost the simplicity of the `dispatch_once` solution, a solution which guarentees thread safety and that all code calling `[SPThumbnailCache sharedThumbnailCache]` only ever gets the same instance. We now need to be extremely careful about the order of code execution for code that utilizes the thumbnail cache. Suppose while the user is in the process of signing out, there's some background task that is in the process of saving an image into the cache: 
我们当然可以使用这种方式去解决，但是代价实在是太大了。我们不能使用简单的、能够保证线程安全和所有的调用 `[SPThumbnailCache sharedThumbnailCache]` 的地方都会访问同一个实例的`dispatch_once`解决方案了。现在我们需要对使用thumbnail cache时的代码的执行顺序非常小心。假设当用户正在执行登出操作时，有一些后台任务正在执行把图片保存到缓存中的操作: 

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[SPThumbnailCache sharedThumbnailCache] cacheProfileImage:newImage forUserId:userId];
    });


We need to be certain `tearDown` doesn't execute until after that background task completes. This ensures the `newImage` data will get cleaned up properly. Or, we need to make sure the background task is canceled when the thumbnail cache is shut down. Otherwise, a new thumbnail cache will be lazily created, and stale user state (the `newImage`) will be stored inside of it. 
我们需要保证在所有的后台任务完成前， `tearDown`一定不能被执行。这保证了`newImage`可以被正确的清理掉。或者，我们需要保证在thumbnail cache被移除时，后台缓存任务一定要被取消掉。否则，一个新的 thumbnail cache 的实例将会被延迟创建，并且之前用户的数据 (`newImage`对象)会被存储在它里面。


Since there's no distinct owner for the singleton instance (i.e. the singleton manages its own lifecycle), it becomes very difficult to ever 'shut down' a singleton.
由于对于单例实例来说它没有明确的所有者，(比如，单例自己管理自己的生命周期)，永远“关闭”一个单例变得非常的困难。

At this point, I hope you're saying, "The thumbnail cache shouldn't have ever been a singleton!" The problem is that an object's lifecycle may not be fully understood at the start of a project. As a concrete example, the Dropbox iOS app only ever had support for a single user account to be signed into. The app existed in this state for years, until one day when we wanted to support [multiple user accounts][twoDropboxes] (both personal and business accounts) to be signed in simultaneously. All of a sudden, assumptions that "there will only ever be a single user signed in at a time" started to break down. By assuming an object's lifecycle will match the lifecycle of your application, you'll limit the extensibility of your code, and you may need to pay for that assumption later when product requirements change.
分析到这里，我希望你能够意识到，“这个thumbnail cache从来就不应该作为一个单例”！问题在于一个对象得生命周期可能在项目的最初阶段没有被很好得考虑清楚。举一个具体的例子，Dropbox 的 iOS 客户端曾经只支持一个账号登录。它以这样的状态存在了数年，直到有一天我们希望能够同时支持[多个用户账号][twoDropboxes]登录(既包括个人账号也包括企业账号)。突然之间，我们以前的的假设“只能够同时有一个用户处于登录状态”就不成立了。 假定一个对象的生命周期和应用的生命周期一致，会限制你的代码的灵活扩展，早晚有一天当产品的需求产生变化时，你会为当初的这个假定付出代价的。

The lesson here is that singletons should be preserved only for state that is global, and not tied to any scope. If state is scoped to any session shorter than "a complete lifecycle of my app," that state should not be managed by a singleton. A singleton that's managing user-specific state is a code smell, and you should critically reevaluate the design of your object graph.
这里我们得到的教训是，单例应该只用来保存全局的状态，并且不能和任何作用域绑定。如果这些状态的作用域比一个完整的应用程序的生命周期要短，那么这个状态就不应该使用单例来管理。用一个单例来管理用户绑定的状态，是代码的坏味道，你应该认真的重新评估你的对象图的设计。


#Avoiding Singletons
#避免使用单例

So, if singletons are so bad for scoped state, how do we avoid using them?
既然单例对局部作用域的状态有这么多的坏处，那么我们应该怎样避免使用它们呢？

Let's revisit the example above. Since we have a thumbnail cache that caches state specific to an individual user, let's define a user object:
让我们来重温一下上面的例子。既然我们的 thumbnail cache 的缓存状态是和具体的用户绑定的，那么让我们来定义一个user对象吧：

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
    
We now have an object to model an authenticated user session, and we can store all user-specific state under this object. Now suppose we have a view controller that renders the list of friends:
我们现在用一个对象来作为一个经过认证的用户会话(authenticated user session)的模型类，并且我们可以把所有和用户相关的状态存储在这个对象中。现在假设我们有一个view controller来展现好友列表：

    @interface SPFriendListViewController : UIViewController

    - (instancetype)initWithUser:(SPUser *)user;

    @end
    
We can explicitly pass the authenticated user object into the view controller. This technique of passing a dependency into a dependent object is more formally referred to as [dependency injection,][dependencyInjection] and it has ton of advantages:
我们可以显示的把经过认证的 user 对象作为参数传递给这个view controller。这种把依赖性传递给依赖对象的技术正式的叫法是 [依赖注入,][dependencyInjection] 并且它有很多优点：

1. It makes clear to the reader of this interface that the `SPFriendListViewController` should only ever be shown when there's a signed-in user.
2. 对于阅读这个`SPFriendListViewController`头文件的读者来说，可以很清楚的知道它只有在有登录用户的情况下才会被展示。


2. The `SPFriendListViewController` can maintain a strong reference to the user object as long as it's being used. For instance, updating the earlier example, we can save an image into the thumbnail cache within a background task as follows:
3. 这个 `SPFriendListViewController`只要还在使用中，就可以强引用 user 对象。举例来说，对于前面的例子，我们可以像下面这样在后台任务中保存一个图片到thumbnail cache中：
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_user.thumbnailCache cacheProfileImage:newImage forUserId:userId];
        });
        
    With this background task still outstanding, code elsewhere in the application is able to create and utilize an entirely new `SPUser` object, without blocking further interaction while the first instance is being torn down.
这种后台任务仍然意义重大，当第一个实例失效时，应用其他地方的代码可以创建和使用一个全新的`SPUser`对象，而不会阻塞用户交互。
    
To demonstrate the second point a little further, let's visualize the object graph before and after using dependency injection.
为了更详细的说明一下第二点，让我们画一下在使用依赖注入之前和之后的对象图。

Suppose our `SPFriendListViewController` is currently the root view controller in the window. With the singleton model, we have an object graph that looks like this:
假设我们的`SPFriendListViewController`是当前window的root view controller。使用单例时，我们的对象图看起来如下所示：

<img src="{{ site.images_path }}/issue-13/Screen%20Shot%202014-06-02%20at%205.21.20%20AM.png" width="412" />

The view controller itself, along with a list of custom image views, interacts with the `sharedThumbnailCache`. When the user logs out, we want to clear the root view controller and take the user back to a sign-in screen:
view controller自己，以及自定义的image view，都会和`sharedThumbnailCache`产生交互。当用户登出后，我们想要清理root view controller并且退出到登录页面：

<img src="{{ site.images_path }}/issue-13/Screen%20Shot%202014-06-02%20at%205.53.45%20AM.png" width="612" />

The problem here is that the friend list view controller might still be executing code (due to background operations), and therefore may still have outstanding calls pending to the `sharedThumbnailCache`.
这里的问题在于这个friend list view controller可能仍然在执行代码(由于后台操作的原因)，并且可能因此仍然有一些调用被挂起到 `sharedThumbnailCache`上。

Contrast this with the solution that utilizes dependency injection:
和使用依赖注入的解决方案对比一下：

<img src="{{ site.images_path }}/issue-13/Screen%20Shot%202014-06-02%20at%205.38.59%20AM.png" width="412" />

Suppose, for simplicity, that the `SPApplicationDelegate` manages the `SPUser` instance (in practice, you probably want to offload such user state management to another object to keep your application delegate [lighter][lighterViewControllers]). When the friend list view controller is installed in the window, a reference to the user is passed. This reference can be funneled down the object graph to the profile image views as well. Now, when the user logs out, our object graph looks like this:
简单起见，假设 `SPApplicationDelegate` 管理`SPUser` 的实例 (在实践中，你可能会把这些用户状态的管理工作交给另外一个对象来做，这样可以使你的 application delegate [简化][lighterViewControllers])。当展现friend list view controller时，会传递进去一个user的引用。这个引用也会向下传递给profile image views。现在，当用户登出时，我们的对象图如下所示：

<img src="{{ site.images_path }}/issue-13/Screen%20Shot%202014-06-02%20at%205.54.07%20AM.png" width="612" />

The object graph looks pretty similar to the case in which we used a singleton. So what's the big deal?
这个对象图看起来和使用单例时很像。那么，这有什么大不了的呢？

The problem is scope. In the singleton case, the `sharedThumbnailCache` is still accessible to arbitrary modules of the program. Suppose the user quickly signs in to a new account. The new user will want to see his or her friends, too, which means interacting with the thumbnail cache again:

关键问题是作用域。在单例那种情况中，`sharedThumbnailCache` 仍然可以被程序的任意模块访问。假如用户快速的登录了一个新的账号。该用户也想看看他的好友列表，这也就意味着需要再一次的和 thumbnail cache 产生交互：

<img src="{{ site.images_path }}/issue-13/Screen%20Shot%202014-06-02%20at%205.59.25%20AM.png" width="612" />

When the user signs in to a new account, we should be able to construct and interact with a brand new `SPThumbnailCache`, with no attention paid to the destruction of the old thumbnail cache. The old view controllers and old thumbnail cache should be cleaned up lazily in the background on their own accord, based on the typical rules of object management. In short, we should isolate the state associated with user A from the state associated with user B:
当用户登录一个新账号，我们应该能够构建并且与全新的`SPThumbnailCache`交互，而不需要再在销毁老的thumbnail cache上花费精力。基于对象管理的典型规则，老的view controllers和老的 thumbnail cache 应该能够自己在后台延迟被清理掉。简而言之，我们应该隔离用户A相关联的状态和用户B相关联的状态：

<img src="{{ site.images_path }}/issue-13/Screen%20Shot%202014-06-02%20at%206.43.56%20AM.png" width="412" />

#Conclusion
#结论

Hopefully nothing in this article reads as particularly novel. People have been complaining about the abuse of singletons for years and we all know global state is bad. But in the world of iOS development, singletons are so commonplace that we can sometimes forget the lessons learned from years of object-oriented programmng elsewhere. 
希望这篇文章中的内容没有特别新奇之处。人们已经对单例的滥用抱怨了很多年了，并且我们也都知道全局状态是很不好的事情。但是在iOS开发的世界中，单例的使用是如此的普遍以至于我们有时候忘记了我们多年来在其他面向对象编程中学到的教训。

The key takeaway from all of this is that in object-oriented programming we want to minimize the scope of mutable state. Singletons stand in direct opposition to that, since they make mutable state accessible from anywhere in the program. The next time you think to use a singleton, I hope you consider dependency injection as an alternative.
这一切的关键点是，在面向对象编程中我们想要最小化可变状态的作用域。但是单例却站在了相反的对立面，因为它们使可变的状态可以被程序中的任何地方访问。下一次你想使用单例时，我希望你能够好好考虑一下使用依赖注入作为替代方案。


[pathologicalLiars]: http://misko.hevery.com/2008/08/17/singletons-are-pathological-liars/
[sheepsClothing]: http://misko.hevery.com/2008/08/25/root-cause-of-singletons/
[dependencyInjection]: http://en.wikipedia.org/wiki/Dependency_injection
[lighterViewControllers]: http://www.objc.io/issue-1/lighter-view-controllers.html
[twoDropboxes]: https://www.dropbox.com/business/two-dropboxes
