---
layout: post
title:  "Communication Patterns"
category: "7"
date: "2013-12-09 08:00:00"
tags: article
author: "<a href=\"https://twitter.com/floriankugler\">Florian Kugler</a>"
---

iOS中消息的传递机制

Every application consists of multiple more or less loosely coupled objects that need to communicate with each other to get the job done. In this article we will go through all the available options, look at examples how they are used within Apple’s frameworks, and extract some best-practice recommendations regarding when you should use which mechanism.

每个应用或多或少都由一些需要相互传递消息的对象结合起来以完成任务。在这片文章里，我们将介绍所有可用的消息传递机制，并通过例子来介绍怎样在苹果的 framework 里使用。我们还会选择一些最佳范例来介绍什么时候该用什么机制。

Although this issue is about the Foundation framework, we will look beyond the communication mechanisms that are part of Foundation -- KVO and Notifications -- and also talk about delegation, blocks, and target-action.

虽然这一期的主题是关于 Foundation framework 的，但是我们会超出 Foundation 的消息传递机制 (KVO 和 通知) 来讲一讲 delegation，block 和 target-action 几种机制。

Of course, there are cases where there is no definitive answer as to what pattern should be used, and the choice comes down to a matter of taste. But there are also many cases that are pretty clear cut.

当然，有些情况下该使用什么机制没有唯一的答案，所以应该按照自己的喜好去试试。另外大多数情况下该使用什么机制应该是很清楚的。

In this article, we will often use the terms "recipient" and "sender.” What we mean with those in the context of communication patterns is best explained by a few examples: a table view is the sender, while its delegate is the recipient. A Core Data managed object context is the sender of the notifications it posts, and whatever picks them up is the recipient. A slider is the sender of a action message, and the responder that implements this action is the recipient. An object with a KVO-compliant property that changes is the sender, while the observer is the recipient. Getting the hang of it?

本文中，我们会常常提及“接收者”和“发送者”。它们在消息传递中的意思可以通过以下的例子解释：一个 table view 是发送者，它的 delegate 就是接收者。Core Data managed Object context 是它 notification 的发送者，获取 notification 的就是接收者。一个滑块 (slider) 是 action 消息的发送者，而实现这个 action （方法）的是它的接收者。任何修改一个支持 KVO 的对象的对象是发送者，这个 KVO 对象的观察者就是接收者。明白精髓了吗？

## Patterns

## 几种消息传递机制

First we will have a look at the specific characteristics of each available communication pattern. Based on this, we will construct a flow chart in the next section that helps to choose the right tool for the job. Finally, we will go over some examples from Apple's frameworks and reason why they decided to use specific patterns for certain use cases.

首先我们来看看每种机制的具体特点。在这个基础上，下一节我们会画一个流程表来帮我们在具体情况下正确选择应该使用的机制。最后，我们会介绍一些苹果 framework 李的例子并且解释为什么在那些用例中会选择特殊的机制。

### KVO

### KVO

KVO is a mechanism to notify objects about property changes. It is implemented in Foundation and many frameworks built on top of Foundation rely on it. To read more about best practices and examples of how to use KVO, please read Daniel's [KVO and KVC article](/issue-7/key-value-coding-and-observing.html) in this issue.

KVO 是提供对象属性被改变时的通知的机制。Foundation 里实现了 KVO，很多基于 Foundation framework 都依赖它。想要了解更多有关 KVO 的，请阅读本期 Daniel 写的 [KVO 和 KVC 文章](/issue-7/key-value-coding-and-observing.html)。
**我们可以在这里插入翻译过的文章链接**

KVO is a viable communication pattern if you're only interested in changed values of another object. There are a few more requirements though. First, the recipient -- the object that will receive the messages about changes -- has to know about the sender -- the object with values that are changed. Furthermore, the recipient also needs to know about the lifespan of the sender, because it has to unregister the observer before the sender object gets deallocated. If all these requirements are met, the communication can even be one-to-many, since multiple observers can register for updates from the object in question.

如果只对某个对象的值的改变感兴趣的话，就可以使用 KVO 消息传递。不过有一些前提：第一，接收者（接收对象改变的通知的对象）需要知道发送者 （值会改变的对象）；第二，接收者需要知道发送者的生命周期，因为他需要在发送者被销毁前注销观察者身份。如果这两个要去符合的话，这个消息传递机制可以一对多（多个观察者可以注册观察同一个对象的变化）

If you plan to use KVO on Core Data objects, you have to know that things work a bit differently here. This has to do with Core Data's faulting mechanism. Once a managed object turns into a fault, it will fire the observers on its properties although their values haven't changed.

如果要在 Core Data 上使用 KVO 的话，方法会有些许差别。这和 Core Data 的报错机制有关。一旦一个 managed object 出错，尽管它的属性没有被改变，它还是会触发相应的观察者。

### Notifications

### 通知

Notifications are a very good tool to broadcast messages between relatively unrelated parts of your code, especially if the messages are more informative in kind and you don't necessarily expect anyone to do something with them.

要在两个不相关的模块中传递消息应当使用通知机制。通知机制广播消息，当消息内容丰富而且无需指望接收者关注的话这一招特别有用。

Notifications can be used to send arbitrary messages and they can even contain a payload in form of their `userInfo` dictionary or by subclassing `NSNotification`. What makes notifications unique is that the sender and the recipient don't have to know each other. They can be used to send information between very loosely coupled modules. Therefore, the communication is one-way -- you cannot reply to a notification.

通知可以用来发送任意消息，甚至可以包含一个 `userInfo` 字典。你也可以继承 `NSNotification` 写一个自己的通知类来自定义行为。通知的独特之处在于，发送者和接收者不需要相互知道对方，所以通知可以被用来在不同的相隔很远的模块之间传递消息。这就意味着这种消息传递是单向的，我们不能回复一个通知。

### Delegation

### Delegation

Delegation is a widespread pattern throughout Apple's frameworks. It allows us to customize an object's behavior and to be notified about certain events. For the delegation pattern to work, the message sender needs to know about the recipient (the delegate), but not the other way around. The coupling is further loosened, because the sender only knows that its delegate conforms to a certain protocol.

Delegation 在苹果的 framework 中广泛存在。它让我们能自定义对象的行为，并收到一些触发的事件。要使用 delegation 模式的话，发送者需要知道接收者，但是反过来没有要求。因为发送者只需要知道接收者符合一定的协议，所以它们两者结合的很松。

Since a delegate protocol can define arbitrary methods, you can model the communication exactly to your needs. You can hand over payloads in the form of method arguments, and the delegate can even respond in terms of the delegate method's return value. Delegation is a very flexible and straightforward communication pattern if you only need to communicate between two specific objects that are in relative proximity to each other in terms of their place in your app architecture.

因为 delegate 协议可以定义任何的方法，我们可以照着自己的需求来传递消息。可以用函数参数来传递消息内容，delegate 可以通过返回值的形式来给发送者作出回应。如果只要在相对接近的两个模块间传递消息，Delgation 是很灵活很直接的消息传递机制。

But there's also the danger of overusing the delegation pattern. If two objects are that tightly coupled to each other that one cannot function without the other, there's no need to define a delegate protocol. In these cases, the objects can know of the other's type and talk to each other directly. Two modern examples of this are `UICollectionViewLayout` and `NSURLSessionConfiguration`.

过度使用 delegation 也会带来风险。如果两个对象结合得很紧密，任何其中一个对象都不能单独运转，那么就不需要用 delegate 协议了。这些情况下，对象已经知道各自的类型，可以直接交流。两个比较新的例子是 `UICollectionViewLayout` 和 `NSURLSessionConfiguration`。

<a name="blocks"> </a>

### Blocks

### Block

Blocks are a relatively recent addition to Objective-C, first available in OS X 10.6 and iOS 4. Blocks can often fulfill the role of what previously would have been implemented using the delegation pattern. However, both patterns have unique sets of requirements and advantages.

Block 是最近才加入 Objective-C 的，首次出现在 OS X 10.6 和 iOS 4 平台上。Block 通常可以满足使用 delegation 实现的消息传递机制。不过这两种机制都有他们自己的独特需求和优势。

One pretty clear criterium of when not to use blocks has to do with the danger of creating [retain cycles](https://developer.apple.com/library/mac/documentation/cocoa/conceptual/memorymgmt/Articles/mmPractical.html#//apple_ref/doc/uid/TP40004447-1000810). If the sender needs to retain the block and cannot guarantee that this reference will be a nilled out, then every reference to `self` from within the block becomes a potential retain cycle.

一个不使用 block 的理由通常是 block 会导致 retain 环 ([retain cycles](https://developer.apple.com/library/mac/documentation/cocoa/conceptual/memorymgmt/Articles/mmPractical.html#//apple_ref/doc/uid/TP40004447-1000810))。如果发送者需要 retain block 但又不能确保引用在什么时候被赋值为 `nil`， 那么所有在block内对 `self` 的引用就会发生潜在的 retain 环。

Let's assume we wanted to implement a table view, but we want to use block callbacks instead of a delegate pattern for the selection methods, like this:

假设我们要实现一个用 block 回调而不是 delegate 机制的 table view 里的选择方法，如下所示：

    self.myTableView.selectionHandler = ^void(NSIndexPath *selectedIndexPath) {
        // handle selection ...
        // 处理选择
    };

The issue here is that `self` retains the table view, and the table view has to retain the block in order to be able to use it later. The table view cannot nil out this reference, because it cannot tell when it will not need it anymore. If we cannot guarantee that the retain cycle will be broken and we will retain the sender, then blocks are not a good choice.

这儿的问题是，`self` 会 retain table view，table view 为了让 block 之后可以使用而需要 retain 这个 block。然而 table view 不能把这个引用设为 nil，因为它不知道什么时候不需要这个 block 了。如果我们不能保证打破 retain 环并且我们需要 retain 发送者，那么 block 就不是我们的好选择。

`NSOperation` is a good example of where this does not become a problem, because it breaks the retain cycle at some point:

`NSOperation` 是使用 block 的一个好范例。因为它在一定的地方打破了 retain 环，解决了上述的问题。

    self.queue = [[NSOperationQueue alloc] init];
    MyOperation *operation = [[MyOperation alloc] init];
    operation.completionBlock = ^{
        [self finishedOperation];
    };
    [self.queue addOperation:operation];

At first glance this seems like a retain cycle: `self` retains the queue, the queue retains the operation, the operation retains the completion block, and the completion block retains `self`. However, adding the operation to the queue will result in the operation being executed at some point and then being removed from the queue afterward. (If it doesn't get executed, we have a bigger problem anyway.) Once the queue removes the operation, the retain cycle is broken.

一眼看来好像上面的代码有一个 retain 环：`self` retain 了 queue，queue retain 了 operation， operation retain 了 completionBlock， 而 completionBlock retain 了 `self`。然而，把 operation 加入 queue 中会使 operation 在一定时间执行，然后被从 queue 中移除。（如果没被执行，问题就大了。）一旦 queue 把 operation 移除，retain 环就被打破了。

Another example: let's say we're implementing a video encoder class, on which we call an `encodeWithCompletionHandler:` method. To make this non-problematic, we have to guarantee that the encoder object nils out its reference to the block at some point. Internally, this would have to look something like this:

另一个例子是：我们在写一个视频编码器的类，在类里面我们会调用一个 `encodeWithCompletionHandler:` 的方法。为了不出问题，我们需要保证编码器对象在某个时间点会释放对 block 的引用。其代码如下所示：

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
        self.completionHandler = nil; // <- Don't forget this!
    }

    @end

Once our job is done and we've called the completion block, we nil it out.

一旦任务完成，completion block 调用过了以后，我们就应该把它设为 `nil`。

Blocks are a very good fit if a message we call has to send back a one-off response that is specific to this method call, because then we can break potential retain cycles. Additionally, if it helps readability to have the code processing the message together with the message call, it's hard to argue against the use of blocks. Along these lines, a very common use case of blocks are completion handlers, error handlers, and the like.

如果一个被调用的方法需要发送一个一次性的消息作为回复，那么使用 block 是很好的选择， 因为这样做我们可以打破潜在的 retain 环。

### Target-Action

### Target-Action

Target-Action is the typical pattern used to send messages in response to user-interface events. Both `UIControl` on iOS and `NSControl`/`NSCell` on the Mac have support for this pattern. Target-Action establishes a very loose coupling between the sender and the recipient of the message. The recipient of the message doesn't know about the sender, and even the sender doesn't have to know up front what the recipient will be. In case the target is `nil`, the action will travel up the [responder chain](https://developer.apple.com/library/ios/documentation/general/conceptual/Devpedia-CocoaApp/Responder.html) until it finds an object that responds to it. On iOS, each control can even be associated with multiple target-action pairs.

Target-Action 是回应 UI 事件时典型的消息传递方式。iOS 上的 `UIControl` 和 Mac 上的 `NSControl`/`NSCell` 都支持这个机制。Target-Action 在消息的发送者和接收者之间建立了一个松散的关系。消息的接收者不知道发送者，甚至消息的发送者预先也不知道消息的接收者。如果 target 是 `nil`，action 会在[响应链 (responder chain)](https://developer.apple.com/library/ios/documentation/general/conceptual/Devpedia-CocoaApp/Responder.html)中被传递下去，知道找到了一个相应它的对象。在 iOS 中，每个 `UIControl` 可以和多个 target-action 关联。

A limitation of target-action-based communication is that the messages sent cannot carry any custom payloads. On the Mac action methods always receive the sender as first argument. On iOS they optionally receive the sender and the event that triggered the action as arguments. But beyond that, there is no way to have a control send other objects with the action message.

基于 target-action 传递机制的一个局限是，发送的消息不能携带自定义的信息。在 Mac 平台上 action 方法的第一个参数永远接收者。iOS 中，可以选择性的把发送者和触发 action 的事件作为参数。除此之外就没有别的控制 action 消息内容的方法了。

## Making the Right Choice

## 做出正确的选择

Based on the characteristics of the different patterns outlined above, we have constructed a flowchart that helps to make good decisions of which pattern to use in what situation. As a word of warning: the recommendation of this chart doesn't have to be the final answer; there might be other alternatives that work equally well. But in most cases it should guide you to the right pattern for the job.

基于上述对不同消息传递机制的特点，我画了一个流程图来帮助我们在不同情境下做出不同的选择。一句忠告：流程图的建议不代表最终答案。有些时候别的选择依然能达到应有的效果。只不过大多数情况下这张图能引导你做出正确的决定。

<img src="{{ site.images_path }}/issue-7/communication-patterns-flow-chart.png" title="Decision flow chart for communication patterns in Cocoa" width="585" height="688">

There are a few other details in this chart which deserve further explanation:

图中有些细节值得深究：

One of the boxes says, *sender is KVO compliant*. This doesn't mean only that the sender sends KVO notifications when the value in question changes, but also that the observer knows about the lifespan of the sender. If the sender is stored in a weak property, it can get nilled out at any time and the observer will leak.

有个框中说到： *发送者支持 KVO*。这不仅仅说明发送者会在值改变的时候发送 KVO 通知，而且说明观察者需要知道发送者的生命周期。如果发送者被存在一个 weak 属性中，那么发送者有可能会自己变成 nil，那时观察者会导致内存泄露。

Another box in the bottom row says, *message is direct response to method call*. This means that the receiver of the method call needs to talk back to the caller of the method as a direct response of the method call. It mostly also means that it makes sense to have the code processing this message in the same place as the method call.

一个在最后一行的框里说，*消息直接相应方法调用*。也就是说方法调用的接收者需要给调用者一个消息作为方法调用的直接反馈。这就等于处理消息的代码和调用方法的代码必须在同一个地方。

Lastly, in the lower right, a decision question states, *sender can guarantee to nil out reference to block?*. This refers to the discussion [above](#blocks) about block-based APIs and potential retain cycles. If the sender cannot guarantee that the reference to the block it’s holding will be nilled out at some point, you're asking for trouble with retain cycles.

最后在右下角的地方，一个选择分支这样说：*发送者能确保释放对 block 的引用吗？*这涉及到了我们[之前](#block)讨论 block 的 API 存在潜在的 retain 环的问题。如果发送者不能保证在某个时间点会释放对 block 的引用，那么你会找上 retain 环的麻烦。

## Framework Examples

## Framework 示例

In this section, we will go through some examples from Apple's frameworks to see if the decision flow outlined before actually makes sense, and why Apple chose the patterns as they are.

本节我们通过一些苹果 framework 里的例子来验证流程图的选择是否有道理，同时解释为什么苹果会选择用这些机制。

### KVO

### KVO

`NSOperationQueue` uses KVO to observe changes to the state properties of its operations (`isFinished`, `isExecuting`, `isCancelled`). When the state changes, the queue gets a KVO notification. Why do operation queues use KVO for this?

`NSOperationQueue` 用了 KVO 观察队列中的 operation 状态属性的改变情况 (`isFinished`，`isExecuting`，`isCancelled`)。当状态改变的时候，队列会收到 KVO 通知。为什么 operation 队列要用 KVO 呢？

The recipient of the messages (the operation queue) clearly knows the sender (the operation) and controls its lifespan by retaining it. Furthermore, this use case only requires a one-way communication mechanism. When it comes to the question of if the operation queue is only interested in value changes of the operation, the answer is less clear. But we can at least say that what has to be communicated (the change of state) can be modeled as value changes. Since the state properties are useful to have beyond the operation queue's need to be up to date about the operation's status, using KVO is a logical choice in this scenario.

消息的接收者（operation 队列）知道消息的发送者（operation），并 retain 它来控制后者的生命周期。另外，在这种情况下只需要单向的消息传递机制。当然如果考虑到 oepration 队列只关心 operation 值改变情况的话，还不足以说服大家使用 KVO。但我们可以这么理解：被传递的消息可以被当成值的改变来处理。因为 state 属性在 operation 队列以外也是有用的，所以这里适合用 KVO。
<img src="{{ site.images_path }}/issue-7/kvo-flow-chart.png" title="Decision flow chart for communication patterns in Cocoa" width="585" height="678">

KVO is not the only choice that would work though. We could also imagine that the operation queue becomes the operation's delegate, and the operation would call methods like `operationDidFinish:` or `operationDidBeginExecuting:` to signal changes in its state to the queue. This would be less convenient though, because the operation would have to keep its state properties up to date in addition to calling these methods. Furthermore, the queue would have to keep track of the state of all its operations, because it cannot ask for them anymore.

当然 KVO 不是唯一的选择。我们也可以想象 operation 队列成为 operation 的 delegate，operation 会调用类似 `operationDidFinish:` 或者 `operationDidBeginExecuting:` 把它的 state 传递给 queue。这样就不太方便了，因为 operation 要保存 state 属性，以便于调用这些 delegate 方法。另外，由于 queue 不能主动获取 state 信息，所以 queue 也必须保存所有 operation 的 state。

### Notifications

### Notifications

Core Data uses notifications to communicate events like changes within a managed object context (`NSManagedObjectContextObjectsDidChangeNotification`).

Core Data 使用 notification 传递事件（例如一个 managed object context 内部的改变————`NSManagedObjectContextObjectsDidChangeNotification`）

The change notification is sent by managed object contexts, so that we cannot assume that the recipient of this message necessarily knows about the sender. Since the origin of the message is clearly not a UI event, multiple recipients might be interested in it, and all it needs is a one-way communication channel, notifications are the only feasible choice in this scenario.

改变的 notification 是由 managed object contexts 发出的，所以我们不能假定消息的接收者知道消息的发送者。因为消息的源头不是一个 UI 事件，所以很多接收者可能在关注着此消息，并且消息传递是单向的，那么 notification 是最好的选择。

<img src="{{ site.images_path }}/issue-7/notification-flow-chart.png" title="Decision flow chart for communication patterns in Cocoa" width="585" height="687">


### Delegation

### Delegation

Table view delegates fulfill a variety of functions, from managing accessory views over editing to tracking the cells that are on screen. For the sake of this example, we'll look at the `tableView:didSelectRowAtIndexPath:` method. Why is this implemented as a delegate call? Why not as a target-action pattern?

Table view 的 delegate 有多重功能，它可以管理 accessory view，也可以追踪在屏幕上显示的cell。例如我们可以看看 `tableView:didSelectRowAtIndexPath:` 方法。为什么用 delegate 实现而不是 target-action 机制？

As we've outlined in the flowchart above, target-action only works if you don't have to transport any custom payloads. In the selection case, the collection view tells us not only that a cell got selected, but also which cell got selected by handing over its index path. If we maintain this requirement to send the index path, our flowchart guides us straight to the delegation pattern.

正如我们在上述流程图中看到的，用 target-action 时，不能传递自定义的数据。而选中 table view 的某个 cell 时，collection view 不仅需要告诉我们一个 cell 被选中了，也要通过 index path 告诉我们哪个 cell 被选中了。如果我们照着这个思路，流程图会引导我们使用 delegation 机制。

<img src="{{ site.images_path }}/issue-7/delegation-flow-chart.png" title="Decision flow chart for communication patterns in Cocoa" width="585" height="687">

What about the option to not send the index path with the selection message, but rather retrieve it by asking the table view about the selected cells once we've received the message? This would be pretty inconvenient, because then we would have to do our own bookkeeping of which cells are currently selected in order to tell which cell was newly selected in the case of multiple selection.

如果不在消息传递中包含选中 cell 的 index path 而让选中项改变时我们主动选中 cell 的相关信息，会怎样呢？这会非常不方便，因为我们必须记住当前选中项的数据来获取被选中的 cell。

Similarly, we could envision being notified about a changed selection by simply observing a property with selected index paths on the table view. However, we would run into the same problem as outlined above, where we couldn’t distinguish which cell was recently selected/deselected without doing our own bookkeeping of it.

同理，我们可以想象通过观察 table view 选中项的 index path 属性，当该值发生改变的时候，获得一个选中项改变的通知。不过我们会遇到上述相似问题：不做记录的话我们就不能分辨哪一个 cell 被选择或取消选择了。

### Blocks

### Block

For a block-based API we're going to look at `-[NSURLSession dataTaskWithURL:completionHandler:]` as an example. What is the communication back from the URL loading system to the caller of it like? First, as caller of this API, we know the sender of the message, but we don't retain it. Furthermore, it's a one way-communication that is a directly coupled to the `dataTaskWithURL:` method call. If we apply all these factors into the flowchart, we directly end up at the block-based communication pattern.

我们用 `-[NSURLSession dataTaskWithURL:completionHandler:]` 来作为一个 block API 的介绍。那么从 URL 加载部分返回给调用者是怎么传递消息的呢？首先，作为 API 的调用者，我们知道纤细的发送者，但是我们并没有 retain 它。另外，这是个单向的消息传递————它直接调用 `dataTaskWithURL:` 的方法。如果我们对照流程图，会发现这属于 block 消息传递机制。

<img src="{{ site.images_path }}/issue-7/block-flow-chart.png" title="Decision flow chart for communication patterns in Cocoa" width="585" height="688">

Are there other options? For sure, Apple's own `NSURLConnection` is the best example. `NSURLConnection` was crafted before Objective-C had blocks, so they needed to take a different route and implemented this communication using the delegation pattern. Once blocks were available, Apple added the method `sendAsynchronousRequest:queue:completionHandler:` to `NSURLConnection` in OS X 10.7 and iOS 5, so that you didn't need the delegate any longer for simple tasks.

有其他的选项吗？当然，苹果自己的 `NSURLConnection` 就是最好的例子。`NSURLConnection`在 block 问世之前就存在了，所以它并没有用 block 来实现消息传递，而是使用 delegation 来完成。当 block 出现以后，苹果就在 OS X 10.7 和 iOS 5 平台上的 `NSURLConnection` 中加了 `sendAsynchronousRequest:queue:completionHandler:`，所以我们不再在简单的任务中使用 delegate 了。

Since `NSURLSession` is a very modern API that was just added in OS X 10.9 and iOS 7, blocks are now the pattern of choice to do this kind of communication (`NSURLSession` still has a delegate, but for other purposes).

因为 `NSURLSession` 是个最近在 OS X 10.9 和 iOS 7 才出现的 API，所以它们使用 block 来实现消息传递机制（`NSURLSession` 有一个 delegate，但用于其他目的）。

### Target-Action

### Target-Action

An obvious use case for the target-action pattern are buttons. Buttons don't have to send any information except that they have been clicked (or tapped). For this purpose, target-action is a very flexible pattern to inform the application of this user interface event.

一个明显的 target-action 用例是按钮。按钮在不被按下的时候不需要发送任何的信息。为了这个目的，target-action 是 UI 中消息传递的最佳选择。

<img src="{{ site.images_path }}/issue-7/target-action-flow-chart.png" title="Decision flow chart for communication patterns in Cocoa" width="585" height="678">

If the target is specified, the action message gets sent straight to this object. However, if the target is `nil`, the action message bubbles up the responder chain to look for an object that can process it. In this case, we have a completely decoupled communication mechanism where the sender doesn't have to know the recipient, and the other way around.

如果 target 是明确指定的，那么 action 消息会发送给指定的对象。如果 target 是 `nil`， action 消息会一直在响应链中被传递下去，直到找到一个能处理它的对象。在这种情况下，我们有一个完全解耦的消息传递机制：发送者不需要知道接收者，反之亦然。

The target-action pattern is perfect for user interface events. No other communication pattern can provide the same functionality. Notifications come the closest in terms of total decoupling of sender and recipient, but what makes target-action special is the use of the responder chain. Only one object gets to react to the action, and the action travels a well-defined path through the responder hierarchy until it gets picked up by something.

Target-action 机制非常适合响应 UI 的事件。没有其他的消息传递机制能够提供相同的功能。虽然 notification 在发送者和接收者的松散关系上最接近它，但是 target-action 可以用于响应链——只有一个对象获得 action 并响应，action 在响应链中传递，直到能遇到响应这个 action 的对象。

## Conclusion

## 小结

The number of patterns available to communicate information between objects can be overwhelming at first. The choice of which pattern to use often feels ambiguous. But once we investigate each pattern more closely, they all have very unique requirements and capabilities.

一开始接触这么多的消息传递机制的时候，我们可能有些无所适从，觉得所有的机制都可以被选用。不过一旦我们仔细分析每个机制的时候，他们各自都很特殊，都有不同的前提和能力。

The decision flowchart is a good start to create clarity in the choice of a particular pattern, but of course it's not the end to all questions. We're happy to hear from you if it matches up with the way you're using these patterns, or if you think there's something missing or misleading.

文中的选择流程图是帮助你清楚认识这些机制的好的开始，当然它不是所有问题的答案。如果你觉得这和你自己选择机制的方式相似或是有任何缺漏，欢迎来信指正。
