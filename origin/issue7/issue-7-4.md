[Source](http://www.objc.io/issue-7/communication-patterns.html "Permalink to Communication Patterns - Foundation - objc.io issue #7 ")

# Communication Patterns - Foundation - objc.io issue #7 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# Communication Patterns

[Issue #7 Foundation][4], December 2013

By [Florian Kugler][5]

Every application consists of multiple more or less loosely coupled objects that need to communicate with each other to get the job done. In this article we will go through all the available options, look at examples how they are used within Apple’s frameworks, and extract some best-practice recommendations regarding when you should use which mechanism.

Although this issue is about the Foundation framework, we will look beyond the communication mechanisms that are part of Foundation – KVO and Notifications – and also talk about delegation, blocks, and target-action.

Of course, there are cases where there is no definitive answer as to what pattern should be used, and the choice comes down to a matter of taste. But there are also many cases that are pretty clear cut.

In this article, we will often use the terms “recipient” and “sender.” What we mean with those in the context of communication patterns is best explained by a few examples: a table view is the sender, while its delegate is the recipient. A Core Data managed object context is the sender of the notifications it posts, and whatever picks them up is the recipient. A slider is the sender of a action message, and the responder that implements this action is the recipient. An object with a KVO-compliant property that changes is the sender, while the observer is the recipient. Getting the hang of it?

## Patterns

First we will have a look at the specific characteristics of each available communication pattern. Based on this, we will construct a flow chart in the next section that helps to choose the right tool for the job. Finally, we will go over some examples from Apple’s frameworks and reason why they decided to use specific patterns for certain use cases.

### KVO

KVO is a mechanism to notify objects about property changes. It is implemented in Foundation and many frameworks built on top of Foundation rely on it. To read more about best practices and examples of how to use KVO, please read Daniel’s [KVO and KVC article][6] in this issue.

KVO is a viable communication pattern if you’re only interested in changed values of another object. There are a few more requirements though. First, the recipient – the object that will receive the messages about changes – has to know about the sender – the object with values that are changed. Furthermore, the recipient also needs to know about the lifespan of the sender, because it has to unregister the observer before the sender object gets deallocated. If all these requirements are met, the communication can even be one-to-many, since multiple observers can register for updates from the object in question.

If you plan to use KVO on Core Data objects, you have to know that things work a bit differently here. This has to do with Core Data’s faulting mechanism. Once a managed object turns into a fault, it will fire the observers on its properties although their values haven’t changed.

### Notifications

Notifications are a very good tool to broadcast messages between relatively unrelated parts of your code, especially if the messages are more informative in kind and you don’t necessarily expect anyone to do something with them.

Notifications can be used to send arbitrary messages and they can even contain a payload in form of their `userInfo` dictionary or by subclassing `NSNotification`. What makes notifications unique is that the sender and the recipient don’t have to know each other. They can be used to send information between very loosely coupled modules. Therefore, the communication is one-way – you cannot reply to a notification.

### Delegation

Delegation is a widespread pattern throughout Apple’s frameworks. It allows us to customize an object’s behavior and to be notified about certain events. For the delegation pattern to work, the message sender needs to know about the recipient (the delegate), but not the other way around. The coupling is further loosened, because the sender only knows that its delegate conforms to a certain protocol.

Since a delegate protocol can define arbitrary methods, you can model the communication exactly to your needs. You can hand over payloads in the form of method arguments, and the delegate can even respond in terms of the delegate method’s return value. Delegation is a very flexible and straightforward communication pattern if you only need to communicate between two specific objects that are in relative proximity to each other in terms of their place in your app architecture.

But there’s also the danger of overusing the delegation pattern. If two objects are that tightly coupled to each other that one cannot function without the other, there’s no need to define a delegate protocol. In these cases, the objects can know of the other’s type and talk to each other directly. Two modern examples of this are `UICollectionViewLayout` and `NSURLSessionConfiguration`.

### Blocks

Blocks are a relatively recent addition to Objective-C, first available in OS X 10.6 and iOS 4. Blocks can often fulfill the role of what previously would have been implemented using the delegation pattern. However, both patterns have unique sets of requirements and advantages.

One pretty clear criterium of when not to use blocks has to do with the danger of creating [retain cycles][7]. If the sender needs to retain the block and cannot guarantee that this reference will be a nilled out, then every reference to `self` from within the block becomes a potential retain cycle.

Let’s assume we wanted to implement a table view, but we want to use block callbacks instead of a delegate pattern for the selection methods, like this:


    self.myTableView.selectionHandler = ^void(NSIndexPath *selectedIndexPath) {
        // handle selection ...
    };

The issue here is that `self` retains the table view, and the table view has to retain the block in order to be able to use it later. The table view cannot nil out this reference, because it cannot tell when it will not need it anymore. If we cannot guarantee that the retain cycle will be broken and we will retain the sender, then blocks are not a good choice.

`NSOperation` is a good example of where this does not become a problem, because it breaks the retain cycle at some point:


    self.queue = [[NSOperationQueue alloc] init];
    MyOperation *operation = [[MyOperation alloc] init];
    operation.completionBlock = ^{
        [self finishedOperation];
    };
    [self.queue addOperation:operation];

At first glance this seems like a retain cycle: `self` retains the queue, the queue retains the operation, the operation retains the completion block, and the completion block retains `self`. However, adding the operation to the queue will result in the operation being executed at some point and then being removed from the queue afterward. (If it doesn’t get executed, we have a bigger problem anyway.) Once the queue removes the operation, the retain cycle is broken.

Another example: let’s say we’re implementing a video encoder class, on which we call an `encodeWithCompletionHandler:` method. To make this non-problematic, we have to guarantee that the encoder object nils out its reference to the block at some point. Internally, this would have to look something like this:


    @interface Encoder ()
    @property (nonatomic, copy) void (^completionHandler)();
    @end

    @implementation Encoder

    - (void)encodeWithCompletionHandler:(void (^)())handler
    {
        self.completionHandler = handler;
        // do the asynchronous processing...
    }

    // This one will be called once the job is done
    - (void)finishedEncoding
    {
        self.completionHandler();
        self.completionHandler = nil; // 