---
title:  "React-Inspired Views"
category: "22"
date: "2015-03-10 8:00:00"
tags: article
author: "<a href=\"https://twitter.com/adamjernst\">Adam Ernst</a>"
---

# React-Inspired Views

User interfaces can be hard to get right in any application. Combining display and interaction in a little rectangle on the user's screen seems simple, but even for small applications, it's easy to end up with a tangled mess of view code. In complex products with many contributing engineers, like Facebook's News Feed, these views can be *especially* hard to develop and maintain over time.

Recently I've been working on a library called Components to make views simpler on iOS. It emphasizes a one-way data flow from [immutable models](https://code.facebook.com/posts/340384146140520/making-news-feed-nearly-50-faster-on-ios/) to immutable "components" that describe how views should be configured. It's heavily inspired by the [React Javascript library](http://facebook.github.io/react/) that has become popular on the web. Just like React, which abstracts away manipulation of the DOM using a concept called the "virtual DOM," Components abstracts away direct manipulation of `UIView` hierarchies.

In this post, I'll focus on some of the benefits of switching to Components for rendering News Feed on iOS and share lessons I've learned that you can apply to your own apps.

# 受React启发的视图

在任何应用当中将界面做好都不是一件容易的事情。在一个小小的四边形中呈现内容以及互动的结合看似容易，其实就算是在很小的应用当中也很容易写出混乱不堪的视图代码。在有很多工程师合作的复杂项目当中，比如Facebook的新鲜事页面，这些视图的开发和维护是有相当难度的。

最近我一直在开发一个叫做Components的库来简化iOS View的开发。它强调单项数据流动：从不可变的模型到不可变的”组件”，这些组件描述了Views应该如何被设置。React通过一个叫做”“虚拟DOM“的概念来抽象画对DOM处理，同样的，Components会抽象化对UIView层次的处理。

在这篇文章中我会着重说明使用Components在iOS上来呈现View的一些好处，并且分享一些我学习到的经验。相信在大家自己的应用中也能够用得上。


### No Layout Math

Suppose we have four subviews and want to stack them vertically, stretching them the full width horizontally. The classic way of doing this is to implement `-layoutSubviews` and `-sizeThatFits:`, which clocks in at around [52 lines of code](https://gist.github.com/adamjernst/c7bd7e5f98de5dc82e3a). There's a bunch of math and it's not immediately obvious at first glance that the code is vertically stacking views. There is a lot of duplication between the two methods, so it's easy for them to get out of sync in future refactors.

If we switch to Apple's Auto Layout APIs, we can do a little better: [34 lines of code](https://gist.github.com/adamjernst/2d52beb72506863f0ac5). There is no longer any math or duplication — hurrah! But we've traded that for a different set of problems: Auto Layout is hard to set up,[^1] is difficult to debug,[^2] and suffers from poor runtime performance on complex hierarchies.[^3]

Components draws inspiration from the [CSS Flexbox specification](http://www.w3.org/TR/css3-flexbox/) for its layout system. I won't get into the nuts and bolts; check out [Mozilla's fine tutorial](https://developer.mozilla.org/en-US/docs/Web/Guide/CSS/Flexible_boxes) to learn more. Flexbox makes layout so much easier that the equivalent in Components weighs in at only 18 lines of code. There is no math and no string-based visual format language.

Here's how you'd do the same vertically stacked layout in Components. To the unfamiliar eye, the syntax looks pretty weird — it'll be explained shortly:

```objc++
@implementation FBStoryComponent

+ (instancetype)newWithStory:(FBStory *)story
{
  return [super newWithComponent:
          [FBStackLayoutComponent
           newWithView:{}
           size:{}
           style:{.alignItems = FBStackLayoutAlignItemsStretch}
           children:{
             {[FBHeaderComponent newWithStory:story]},
             {[FBMessageComponent newWithStory:story]},
             {[FBAttachmentComponent newWithStory:story]},
             {[FBLikeBarComponent newWithStory:story]},
           }]];
}

@end
```
### 零数学布局

假设我们有四个子视图而且我们想将它们垂直的分布，水平方向上使用全宽。经典的办法是去实现-layoutSubviews和-sizeThatFits:这两个函数，[这样做需要52行代码](https://gist.github.com/adamjernst/c7bd7e5f98de5dc82e3a). 因为其中有很多数学运算，第一眼看上去不是很容易看出来是在竖直地摆放视图。在这两个函数中有点重复的地方，所以在未来的修改中保持同步并不容易。

如果我们使用苹果的自动布局API，我们可以获得小小的改进：[34行代码](https://gist.github.com/adamjernst/2d52beb72506863f0ac5).。同时数学运算以及重复的代码问题亦可以解决！但是我们却换来了另外一些问题：自动布局设置起来很困难，[^1] 调试起来也很费力，[^2] 并且复杂的层次会让运行时性能打一些折扣。[^3]

Components从[CSS Flexbox specification](http://www.w3.org/TR/css3-flexbox/)的布局系统中中吸取了灵感。我不会介绍太多的细节，如想进一步学习请参照 [Mozilla的高质量教程](https://developer.mozilla.org/en-US/docs/Web/Guide/CSS/Flexible_boxes) 。因为Flexbox大幅简化了布局，相对应的Components仅仅需要18行代码。你也不需要使用任何数学运算以及基于字符串的视觉格式语言。

这里是你如何用Components来做到同样的垂直摆放视图，对于不熟悉的人们来说，句型看上去可能会很奇怪 -- 稍后再来解释：

```objc++
@implementation FBStoryComponent

+ (instancetype)newWithStory:(FBStory *)story
{
  return [super newWithComponent:
          [FBStackLayoutComponent
           newWithView:{}
           size:{}
           style:{.alignItems = FBStackLayoutAlignItemsStretch}
           children:{
             {[FBHeaderComponent newWithStory:story]},
             {[FBMessageComponent newWithStory:story]},
             {[FBAttachmentComponent newWithStory:story]},
             {[FBLikeBarComponent newWithStory:story]},
           }]];
}

@end
```




### But All Those Braces!

Right. We use Objective-C++. [Aggregate initialization](http://en.cppreference.com/w/cpp/language/aggregate_initialization) gives us a great way to specify style structs in a terse and type-safe manner. Here are a few examples of other valid `style:` values:

```objc++
style:{} // default values
style:{.justifyContent = FBStackLayoutJustifyContentCenter}
style:{
  .direction = FBStackLayoutDirectionHorizontal,
  .spacing = 10,
}
```

Using STL containers like `std::vector` and `std::unordered_map` give us more type safety than Objective-C's corresponding containers. We also get the benefits of stack allocation for temporary view model data structures, boosting performance.

There are some other stylistic oddities in Components (the use of `+newWith...` instead of `-initWith...` for brevity, nonstandard indentation) that make sense with more context — a subject for another blog post. Back to the good stuff.

### 那些个波形括号！

没错，我们用的是Objective-C++。叠加实例化给我们一个简明并且类安全的方法来指明样式结构。以下是另外几个有效的style:值：

```objc++
style:{} // default values
style:{.justifyContent = FBStackLayoutJustifyContentCenter}
style:{
  .direction = FBStackLayoutDirectionHorizontal,
  .spacing = 10,
}
```
使用像std:vector和std:unordered_map这样的容器给我们比在Objective-C中相对应容器更强的类安全性。我们同时能够用栈来调用临时视图数据结构，提升性能。

Components在句型风格上还有另外一些有些奇怪的地方（未来简洁性运用+newWith...而不是-initWith..以及非常规的缩格）在更多的上下文中才解释的通 --- 这个话题单独可以在写一篇文章。现在我们回到主题。



### Declarative, Not Imperative

Even with the completely new syntax, it is pretty easy to observe what is happening in the Components version of our stacking view. There's one key reason why: it's *declarative*, not imperative.

Most iOS view code reads like a series of instructions:

- Create a header view.
- Store it to the `_headerView` ivar.
- Add it to the view.
- Add constraints that equate the header's left and right sides to the superview's.
- *... do similarly for other views*
- Add more constraints that stack the views.

Components code is declarative:

- A story is rendered with these four components stacked vertically and stretched horizontally.

Think about the distinction as the difference between a list of materials and directions to workers, and a full blueprint. To stretch the analogy a bit, the architect shouldn't run around a building site telling the workers exactly how to do their jobs — it would be far too chaotic. Declarative techniques focus on *what needs to be done*, not *how* it should be done; as a result, you can focus on intentions instead of specific implementation details.

With Components, there are no local variables or properties to keep track of. You don't need to jump around between the places where views are created, constraints are added, and views are configured with a model. Everything is right there in front of you.

My advice to you: always prefer declarative style to imperative code. It's easier to read and maintain.


### 宣言性而不是祈使性

就算是全新的句型，也不难看懂我们摆放视图的Components版本。用一个重要的原因：它是宣言性的而不是祈使性的。

大多数的iOS视图代码读起来感觉像是一系列的指令：
- 建立一个新的头视图。
- 将其存进_headerView实例变量。
- 加入视图中
- 加入限制将头视图的左右两边和超视图对齐。
- ...对其他视图做相似的操作。
- 加入更多摆放视图用的限制。

Components的代码是宣言性的：

一个故事是通过将四个组件垂直摆放并且左右拉升来做到的。

将这两者的区别想象成给工人们列有所有材料和指示的清单，和仅仅给他们一张蓝图。延伸一下这个比喻，一个建筑师不应该在工地上四处奔走来告诉建筑工人如何去干他们的活 -- 这样的话会太过于混乱。宣言性的技巧着重于什么需要被完成，而不是如何去完成它；结果是，你得以将精力集中在要解决的问题上而不是实现细节上。

使用Components的时候，不用去操心本地变量和特质。你不需要在创造视图的时候在创建视图的地方，添加限制的地方已经设置模型的地方来回跳跃。所有的事情就在你面前好好的放着。

我的建议是：永远倾向于宣言性风格而不是祈使性风格，这样一来代码更易于读懂，也更易于维护。

### Composition over Inheritance

Here's a quick quiz: what does the code below do?

```objc
- (void)loadView {
  self.view = [self newFeedView];
}

- (UIView *)newFeedView {
  return [[FBFeedView alloc] init];
}
```

With inheritance, it could do anything. Maybe `-newFeedView` was overridden in a subclass to return a completely different view. Maybe `-loadView` was overridden to call a different method. In large codebases, proliferating subclasses make it difficult to read code and understand what it is actually doing.[^4] Problems from inheritance cropped up often in News Feed before we used Components. For example, `FBHorizontalScrollerView` had many subclasses that overrode different methods, making the superclass difficult to read or refactor.

Components are always composed, never subclassed. Think of them as little building blocks that can be plugged together to make something great.

But heavy use of composition results in deep hierarchies, and deep `UIView` hierarchies slow scrolling to a crawl. So it's particularly handy that a component may specify that no view should be created for it at all.[^5] In practice, most components don't need a view. Take the `FBStackLayoutComponent` example from earlier; it stacks and flexes its children, but it doesn't need a `UIView` in the hierarchy to perform this task.

Even though Feed's *component* hierarchy is dozens of layers deep, the resulting *view* hierarchy is only about three layers deep. We get all the benefits of using lots of composition but don't have to pay the cost.

If there's one lesson I learned from scaling a large codebase, it's this: avoid inheritance! Find ways to use composition or other patterns instead.

### 混合优于继承

小小测验：以下代码是干什么的？

```objc
- (void)loadView {
  self.view = [self newFeedView];
}

- (UIView *)newFeedView {
  return [[FBFeedView alloc] init];
}
```
如果是在使用继承，它可以是在做任何事情。可能-newFeedView在子类中重写，返回了一个完全不同的视图。又或许-loadView被重写去启用一个不同的函数。在大规模的代码库中大量使用子类会使得代码阅读和理解起来很困难。[^4] 继承产生的问题在我们使用Components改写新鲜事页面之前经常发生，使得超类难以阅读和改进。

Components永远都是被混合的，从来不会被继承。将它们想象成小的基础模块，你可以将它们拼装在一起组成非常棒的东西。

但是对混合的大量使用会造成非常深得层次，而深得UIView层次会将滑动变得非常缓慢。所以指明没有视图需要被创造出来是非常方便的。[^5] 在现实中，但多是的组件是不需要视图的。 就拿FBStackLayoutComponent来作例子；它将它的子视图码放在一起，但是它并不需要UIView在层次中去执行这项任务。

尽管新鲜事页面的组件层次有好几十层，但是视图层其实才有三层。我们获取了所有混合带来的好处却没有付出任何的成本。

如果说我从庞大的代码库中学到一样东西的话，就是不要使用继承！转而使用混合或者其他的套路。


### Automatic Recycling

A key part of using `UITableView` is cell recycling: a small set of `UITableViewCell` objects are reused to render each row as you scroll. This is key to blazing-fast scroll performance.

Unfortunately, it's really hard to get everything right when recycling complex cells in a codebase shared by many engineers. Before adopting Components, we once added a feature to fade out part of a story but forgot to reset `alpha` upon recycling; other stories were randomly faded out too! In another case, forgetting to reset the `hidden` property properly resulted in random missing or overlapping content.

With Components, you never need to worry about recycling; it's handled by the library. Instead of writing imperative code to correctly configure a recycled view that may be in *any* state, you declare the state you want the view to be in. The library figures out the minimal set of changes that need to be made to the view.

### 自动回收

使用UITableView时的重要一步是cell的回收：少量的UITableViewCell实例会被反复地利用。这是实现惊人的滑动速度得以实现的重要原因。

但是，要想在多工程师分享的代码库中妥当地回收复杂的cells并不容易。在开始使用Components之前，我们曾添加一个功能来逐渐淡出一个故事的一部分界面但是我们忘记了在回收时重设透明度的值，这样一来其他的故事也被随机的淡化了！另一个例子，忘记妥善地重设hidden特质导致随机地丢失已经覆盖内容。

如果使用Components，你永远不需要担心回收。库会来很好地管理它。不同于写祈使性的代码来正确地设置可能在任何状态中得回收视图，你只需要指明一个视图状态即可。库会计算出完成这项任务所需的最少步骤。


### Optimize Once, Benefit Everywhere

Since all view manipulation is handled by Components code, we can speed up everything at once by optimizing a single algorithm. It's a lot more rewarding to optimize one place and see the results everywhere than to confront 400 subclasses of `UIView` and think "This is going to be a big project…."

For example, we were able to add an optimization that ensured we don't call property setters (like `-setText:`) when reconfiguring views unless the value has actually changed. This led to a boost in performance, even though most setters are efficient when the value hasn't changed. Another optimization ensured that we never reorder views (by calling `-exchangeSubviewAtIndex:withSubviewAtIndex:`) unless absolutely necessary, since this operation is relatively expensive.

Best of all, these optimizations don't require anyone to change the way code is written. Instead of taking time to learn about expensive operations and how to avoid them, developers can focus on getting work done — a big organizational benefit.

### 一次优化，处处受益

正因为所有处理视图的代码全都由Components完成，我们得以通过优化一个算法来提升各个地方的开发速度。相较于面对400个UIView子类并心中默念：”这可是一个庞大的项目“，优化一个地方并且处处受益要来的有意义的多。

比如说，我们加入了一个优化来确保在重新设置视图的时候不去使用特质设置器（比如-setText)，除非值确实被改变了。这样一来我们在性能上有了很大的提升，尽管大多数的设置器在值没哟变化的情况下还是非常有效率的。另外一个优化确保了只有在必要的情况下才重新整理视图（通过使用-exchangeSubviewAtIndex:withSubviewAtIndex:)，因为这项操作相对来说成本很高。

最好的部分是，这些优化并不需要任何人去改变写代码的方式。开发者们能够专注完成任务而不是了解高成本的操作并学会去避免他们 - 一个对整个团队来说非常大的帮助。

### The Challenge of Animation

No framework is a silver bullet. One challenging aspect of reactive UI frameworks is that animations can be more difficult to implement in comparison to traditional view frameworks.

A reactive approach to UI development encourages you to be explicit about transitioning between states. For example, imagine a UI that truncates text but allows the user to tap a button to expand inline and see all the text. This is easily modeled with two states: `{Collapsed, Expanded}`.

But if you want to animate the expansion of the text, or let the user drag and drop to control exactly how much text is visible, it's not possible to represent the UI with only two states. There are hundreds of states corresponding to exactly how much text is visible at any point in the animation. The very fact that reactive frameworks force you to reason about state changes upfront is exactly what makes it difficult to model these animations.

We've developed two techniques to manage animations in Components:

- Static animations can be expressed declaratively using an API called `animationsFromPreviousComponent:`. For example, a component may specify that it should be faded in when it appears for the first time.
- Dynamic animations are handled by providing an "escape hatch" back to traditional imperative and mutable code. You won't get the benefits of declarative code and explicit state management, but you'll have all the power of UIKit at your disposal.

Our hope is to develop powerful tools for expressing even dynamic animations in a simple and declarative way — we're just not there yet.

### 动画的挑战

没有一个模块能够解决所有的问题，Reactive界面模块中一个有挑战性的问题是实现动画相较于使用传统模块要更困难一些。

Reactive界面开发鼓励将状态之间的切换明确化。举个例子，有一个界面会删减一部分文本内容，但是允许用户按一个按钮来展开并且查看全部的文本。这个可以轻易通过两个状态来做到：{Collapsed, Expanded}。

但是如果你想把展开文本做成动画，或者让用户自己去精确地控制显示多少文本内容，那么就不可能只是用两个状态了。有数以百计的状态对应动画中多少文本会被显示出来。Reactive模块要求你在开始的时候就把状态变化安排好，正是因为这一点动画才变得如此困难。

我们开发了两种手段来管理Components中得动画：

- 可以使用一个叫做animationsFromPreviousComponent:的API来宣言性地表达静态的动画。比如说，一个组件可以指明在第一次出现的时候使用渐变的效果。

- 动态动画可以重新使用祈使性，可变的代码来完成。你不会得到宣言性代码和状态管理明确化带来的好处，但是你会享受到UIKit的威力。

我们的设想是开发强大的工具去用宣言性的代码来写出简约的动态动画，我们只是还没有完成这个计划而已。

### React Native

At Facebook, we recently announced [React Native](https://code.facebook.com/videos/786462671439502/react-js-conf-2015-keynote-introducing-react-native-/), a framework that uses the React Javascript library to manipulate `UIView` hierarchies in native apps instead of DOM elements on web pages. It may surprise you to hear that the Components library I'm describing is *not* React Native, but a separate project.

Why the distinction? It's simple: React Native hadn't been invented yet when we rebuilt News Feed in Components. Everyone at Facebook is excited about the future of React Native, and it's already been used to power both [Mobile Ads Manager](https://www.facebook.com/business/news/ads-manager-app) and [Groups](http://newsroom.fb.com/news/2014/11/introducing-the-facebook-groups-app/).

As always, there are tradeoffs; for example, Components' choice of Objective-C++ means better type safety and performance, but React Native's use of Javascript allows live reload while running an app under development. These projects often share ideas to bring both forward.

### 本地React

在Facebook, 我们最近发布了 [本地React](https://code.facebook.com/videos/786462671439502/react-js-conf-2015-keynote-introducing-react-native-/), 一个运用React Javascript库来处理本地应用中UIView层次的模块，这个库使用的是UIView而非网页中的DOM元素。告诉大家Components库并不是本地React而是一个单独的项目可能有些让人惊讶。

它们的区别是什么？其实很简单：当我们用Components重建新鲜事页面的时候本地React还没有被发明出来。在Facebook, 每一个人都非常看好本地React的前景。并且已经应用在[Mobile Ads Manager](https://www.facebook.com/business/news/ads-manager-app) and [Groups](http://newsroom.fb.com/news/2014/11/introducing-the-facebook-groups-app/)两个应用中。

取舍是正常的；比如说，Components选择使用Objective-C++是因为它的类安全性和性能，但是本地React对Javascript的运用让在开发环境下即使更新成为可能。这些项目经常会分享一些推动两者共同进步的创意。

### AsyncDisplayKit

So what about [AsyncDisplayKit](http://asyncdisplaykit.org), the UI framework developed to power Facebook's [Paper](https://www.facebook.com/paper)? It adds the ability to perform measurement and rendering on background threads, freeing you from UIKit's main thread shackles.

Philosophically, AsyncDisplayKit is much closer to UIKit than to React. Unlike React, AsyncDisplayKit doesn't emphasize declarative syntax, composition, or immutability.

Like AsyncDisplayKit, Components performs all component creation and layout off the main thread. (This is easy because both our model objects and components themselves are completely immutable — no race conditions!)

AsyncDisplayKit enables complex gesture-driven animations, precisely the area that is a weak spot for Components. This makes the choice easy: If you're designing a complex gesture-driven UI, AsyncDisplayKit might be right for you. If your interface looks more like Facebook's News Feed, Components could be a good fit.

###AsyncDisplayKit

那么用来驱动Facebook Paper应用的界面模块AsyncDisplayKit呢？它增添了在后台线程衡量和呈现的能力，让你无需面对使用UIKit主线程会遇到的麻烦。

从设计哲学的角度上来说，AsyncDisplayKit和UIKit的关联比和React要更强。不想React, AsyncDisplayKit没有强调使用宣言性句法，混合以及不可变性。

像AsyncDisplayKit一样，Components在后台线程进行组件创造和分布（这个很容易因为因为我们的模型对象和组件本身全都是不可变的 - 不可能出现竞态条件！）

AsyncDisplayKit能够进行复杂的手势驱动的动画，这一点正是Components的如向所在。这样一来做选择就很容易了：如果你在设计一个复杂的手势驱动的界面，AsyncDisplayKit应该是正确的选择。如果你的界面看起来和Facebook的新鲜事页面更类似，那么Components是恰当的选择。

### The Future of Components

The Components library has been adopted successfully in all feeds in the app (News Feed, Timeline, Groups, Events, Pages, Search, etc.) and is rapidly making its way to other parts of the Facebook app. Building UIs using simple, declarative, composable components is a joy.

You might think some of the ideas behind Components sound crazy. [Give it five minutes](https://signalvnoise.com/posts/3124-give-it-five-minutes) as you think it over; you may have to challenge some assumptions, but these ideas have worked well for us and might benefit you too. If you want to learn more, [watch this QCon talk](http://www.infoq.com/presentations/facebook-ios-architecture), which explains some more detail behind Components. The [Why React?](http://facebook.github.io/react/docs/why-react.html) blog post and the resources it links to are another great reference.

I'm excited to share the code behind Components with the community, and we're preparing to do so soon. If you have thoughts to share, [I'd love to hear from you](mailto:adamjernst@fb.com) any time — especially if you have ideas about animations!

###Components的未来

Components库在所有的显示大量信息的页面都会用到（新鲜事，时间线，群，事件，页面和搜索等等）并且正在快速地在Facebook应用的其他部分被应用起来。用简洁，宣言性，可混合的组件是很有趣的。

你可能觉得Components中的一些东西听起来很疯狂。[但是用点时间消化一下](https://signalvnoise.com/posts/3124-give-it-five-minutes)。你可能会自己挑战之前的一些假设，但是这些东西我们用着非常好而且对你们可能也有帮助。如果你想学习更多， [可以看看这个](http://www.infoq.com/presentations/facebook-ios-architecture)，会深入地讨论Components的一些细节。[为什么用React?](http://facebook.github.io/react/docs/why-react.html) 博文和它链接的资源都是非常好的参考。

我们非常想和社区分享Components背后的代码，而且我们马上要着手去做。如果你有想法要分享，[随时都可以联系我](mailto:adamjernst@fb.com) - 尤其是关于动画的想法！


[^1]: Interface Builder makes Auto Layout easier, but since XIBs are impractical to merge, you can't use them with large teams.

[^2]: There is no shortage of [articles](http://www.informit.com/articles/article.aspx?p=2041295) and [blog posts](https://medium.com/@NSomar/auto-layout-best-practices-for-minimum-pain-c130b2b1a0f6) about debugging Auto Layout.

[^3]: We prototyped a very simplified version of News Feed that was powered by Auto Layout and it was challenging to get it to 60fps.

[^4]: objc.io has [covered this topic before](http://www.objc.io/issue-13/subclassing.html), and the [Wikipedia article](http://en.wikipedia.org/wiki/Composition_over_inheritance) also does a good job of covering it.

[^5]: Similarly, in React, not every component results in the creation of a DOM element.


[^1]: 界面创造器简化了自动布局，但是因为XIBs文件难以融合，你很难在大的团队里面使用它们。

[^2]: 有很多关于如何调试自动布局的[文章](http://www.informit.com/articles/article.aspx?p=2041295)和 [博客](https://medium.com/@NSomar/auto-layout-best-practices-for-minimum-pain-c130b2b1a0f6

[^3]: 我们用自动布局制作了一个很简单的新鲜事页面，做到60帧每秒是非常的困难。

[^4]: objc.io在以前[介绍过这个主题](http://www.objc.io/issue-13/subclassing.html)，[这篇维基百科文章](http://en.wikipedia.org/wiki/Composition_over_inheritance) also does a good job of covering it.也做了很好地介绍。

[^5]:相同的，在React中，并非每一个组件都会创造一个相应的DOM元素。
