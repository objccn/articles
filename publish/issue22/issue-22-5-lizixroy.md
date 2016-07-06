# 响应式视图

在任何应用当中将界面做好都不是一件容易的事情。在一个小小的四边形中呈现内容以及互动的结合看似容易，其实就算是在很小的应用当中也很容易写出混乱不堪的视图代码。在有很多工程师合作的复杂项目当中，比如 Facebook 的新鲜事页面，这些视图的开发和维护是有**相当**难度的。

最近我一直在开发一个叫做 Components 的库来简化 iOS View 的开发。它强调单项数据流动：从[不可变的模型](https://code.facebook.com/posts/340384146140520/making-news-feed-nearly-50-faster-on-ios/)到不可变的”组件”，这些组件描述了视图应该如何被设置。这个库从现在网络开发中很流行的 [React Javascript 库](http://facebook.github.io/react/) 中汲取了很多灵感。React 通过一个叫做 “虚拟 DOM” 的概念来抽象化对 DOM 处理。同样地，Components 会抽象化对 `UIView` 层次的处理。

在这篇文章中我会着重说明使用 Components 在 iOS 上来呈现视图的一些好处，并且分享一些我学习到的经验。相信在大家自己的应用中也能够用得上。

### 零数学布局

假设我们有四个子视图而且我们想将它们垂直的分布，水平方向上使用全宽。经典的办法是去实现 `-layoutSubviews` 和 `-sizeThatFits:` 这两个函数，[这样做需要 52 行代码](https://gist.github.com/adamjernst/c7bd7e5f98de5dc82e3a). 因为其中有很多数学运算，第一眼看上去不是很容易看出来是在竖直地摆放视图。在这两个函数中有点重复的地方，所以在未来的修改中保持同步并不容易。

如果我们使用苹果的自动布局 API，我们可以获得小小的改进：[34行代码](https://gist.github.com/adamjernst/2d52beb72506863f0ac5).。同时数学运算以及重复的代码问题亦可以解决！但是我们却换来了另外一些问题：自动布局设置起来很困难，[^1] 调试起来也很费力，[^2] 并且复杂的层次会让运行时性能打一些折扣。[^3]

> ^1 Interface Builder 简化了自动布局，但是因为 XIBs 文件难以融合，你很难在大的团队里面使用它们。
>
> ^2 有很多关于如何调试自动布局的[文章](http://www.informit.com/articles/article.aspx?p=2041295)和[博客](https://medium.com/@NSomar/auto-layout-best-practices-for-minimum-pain-c130b2b1a0f6)
> 
> ^3 我们用自动布局制作了一个很简单的新鲜事页面，做到 60 帧每秒是非常的困难。

Components 从 [CSS Flexbox specification](http://www.w3.org/TR/css3-flexbox/) 的布局系统中中吸取了灵感。我不会介绍太多的细节，如想进一步学习请参照 [Mozilla 的高质量教程](https://developer.mozilla.org/en-US/docs/Web/Guide/CSS/Flexible_boxes) 。因为 Flexbox 大幅简化了布局，相对应的 Components 仅仅需要18行代码。你也不需要使用任何数学运算以及基于字符串的视觉格式语言。

用下面的代码就可以依靠 Components 来做到同样的垂直摆放视图，对于不熟悉的人们来说，句型看上去可能会很奇怪 -- 稍后再来解释：

```
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

### 那些个波形括号！

没错，我们用的是 Objective-C++。[聚合实例化](http://en.cppreference.com/w/cpp/language/aggregate_initialization)给我们一个简明并且类安全的方法来指明样式结构。以下是另外几个有效的 `style:` 值：

```
style:{} // default values
style:{.justifyContent = FBStackLayoutJustifyContentCenter}
style:{
  .direction = FBStackLayoutDirectionHorizontal,
  .spacing = 10,
}
```

使用像 `std:vector` 和 `std:unordered_map` 这样的标准库中的容器比我们在 Objective-C 中使用相对应容器有更强的类型安全性。我们同时能够用栈来调用临时视图数据结构，提升性能。

Components 在句型风格上还有另外一些有些奇怪的地方 (为了简介而使用 `+newWith...` 代替 `-initWith...`，以及非常规的缩进等)，这要在更多的上下文中才解释得通 --- 这个话题单独可以再写一篇文章。现在我们回到主题。

### 声明式而不是命令式

就算是全新的句型，也不难看懂我们摆放视图的 Components 版本。用一个重要的原因是：它是**声明式的**而不是命令式的。

大多数的 iOS 视图代码读起来感觉像是一系列的指令：

- 建立一个新的 header 视图。
- 将其存进 `_headerView` 实例变量。
- 加入视图中
- 加入限制将头视图的左右两边和父视图对齐。
- **...对其他视图做相似的操作**
- 加入更多摆放视图用的限制

而 Components 的代码是声明式的：

- 一个 story 视图是通过将四个组件垂直摆放并且左右拉升来做到的。

将这两者的区别想象成给工人们列出所有材料和指示的清单，和仅仅给他们一张蓝图的区别。延伸一下这个比喻，一个建筑师不应该在工地上四处奔走来告诉建筑工人如何去干他们的活 -- 这样的话会太过于混乱。宣言性的技巧着重于什么需要被完成，而不是如何去完成它；结果是，你得以将精力集中在要解决的问题上而不是实现细节上。

使用 Components 的时候，不用去操心本地变量和属性。你不需要在创建视图的地方，添加限制的地方和使用模型来配置视图的地方来回跳跃。所有的事情就在你面前好好的放着。

我的建议是：永远倾向于声明式风格而不是命令式风格，这样一来代码更易于读懂，也更易于维护。

### 混合优于继承

小小测验：以下代码是干什么的？

```
- (void)loadView {
  self.view = [self newFeedView];
}

- (UIView *)newFeedView {
  return [[FBFeedView alloc] init];
}
```

如果使用了继承，那它可以是在做任何事情。可能 `-newFeedView` 在子类中被重写了，返回了一个完全不同的视图。又或许 `-loadView` 被重写去调用了一个不同的函数。在大规模的代码库中大量使用子类会使得阅读代码和理解它们实际做了什么变得困难。[^4] 继承产生的问题在我们使用 Components 改写新鲜事页面之前经常发生，比如 `FBHorizontalScrollerView` 有很多子类重写了不同的方法，这使得超类难以阅读和重构。

> ^4 objc.io 在以前[介绍过这个主题](http://objccn.io/issue-13-4)，[这篇维基百科文章](http://en.wikipedia.org/wiki/Composition_over_inheritance) 也做了很好地介绍。

Components 永远都是被混合的，从来不会被继承。将它们想象成小的基础模块，你可以将它们拼装在一起组成非常棒的东西。

但是对混合的大量使用会造成非常深的层次，而深的 UIView 层次会将滑动变得非常缓慢。有一点需要特别指明的是，其实是存在那种完全不需要为其创建视图的 component 的。[^5] 在实践中，大多数的组件是不需要视图的。 就拿 `FBStackLayoutComponent` 来作例子；它将它的子视图码放在一起，但是它并不需要在层级中的一个视图去执行这项任务。

> ^5 相同地，在 React 中，也并非每一个组件都会创造一个相应的 DOM 元素。

尽管新鲜事页面的组件层次有好几十层，但是得到的**视图层**其实才有三层。我们获取了所有混合带来的好处却没有付出什么代价。

如果说我从庞大的代码库中学到一样东西的话，就是不要使用继承！转而使用混合或者其他的模式。

### 自动回收

使用 `UITableView` 时的重要一步是 cell 的回收：少量的 `UITableViewCell` 实例会被反复地利用。这是实现惊人的滑动速度得以实现的重要原因。

但是，要想在多工程师分享的代码库中妥当地回收复杂的 cells 并不容易。在开始使用 Components 之前，我们曾添加一个功能来逐渐淡出一个故事的一部分界面，但是我们忘记了在回收时重设 `alpha` 的值，这样一来其他的故事也被随机的淡化了！另一个例子，忘记妥善地重设 `hidden` 属性导致随机地丢失或者覆盖某些内容。

如果使用 Components，你永远不需要担心回收。库会来很好地管理它。不同于写祈使性的代码来正确地设置可能在**任何**状态中所回收的视图，你只需要指明一个视图状态即可。库会计算出完成这项任务所需的最少步骤。

### 一次优化，处处受益

因为所有对视图的处理全都由 Components 的代码完成，我们得以通过优化一个算法来提升各个地方的速度。相较于修改 400 个 `UIView` 子类并心中默念：“这可是一个庞大的项目”来说，优化一个地方并且处处受益要来的有意义的多。

比如说，我们加入了一个优化来确保在重新设置视图的时候，除非值确实被改变了，否则不去使用属性的 setter (比如 `-setText`)。尽管大多数的 setter 在值没有变化的情况下还是非常有效率的，但我们还是在性能上得到了提升。另外一个优化确保了只有在必要的情况下才重新排序视图 (通过使用 `-exchangeSubviewAtIndex:withSubviewAtIndex:`)，因为这项操作相对来说成本很高。

最好的部分是，这些优化并不需要任何人去改变写代码的方式。开发者们能够专注完成任务而不是了解高成本的操作并学会去避免他们 - 这是一个对整个团队来说非常大的帮助。

### 动画的挑战

没有一个框架能够解决所有的问题，响应式 (reactive) 的界面框架中一个有挑战性的问题是实现动画相较于使用传统视图框架要更困难一些。

响应式的界面开发鼓励将状态之间的切换明确化。举个例子，有一个界面会删减一部分文本内容，但是允许用户按一个按钮来展开并且查看全部的文本。这个可以轻易通过两个状态来做到：`{Collapsed, Expanded}`。

但是如果你想把展开文本做成动画，或者让用户自己通过拖拽去精确地控制显示多少文本内容，那么就不可能只是用两个状态了。有数以百计的状态对应着动画中某个时刻有多少文本会被显示出来。响应式框架要求你在开始的时候就把状态变化安排好，正是因为这一点动画才变得如此困难。

我们开发了两种手段来管理 Components 中的动画：

- 可以使用一个叫做 `animationsFromPreviousComponent:` 的 API 来宣言性地表达静态的动画。比如说，一个组件可以指明在第一次出现的时候使用渐入的效果。
- 动态动画可以通过使用一个 “逃出窗” 来回到传统的祈使和可变的代码来完成。你不会得到宣言性代码和状态管理明确化带来的好处，但是你可以自由地使用 `UIKit` 的威力。

我们的设想是开发强大的工具去用宣言性的代码来写出简约的动态动画，我们只是还没有完成这个计划而已。

### React Native

在 Facebook，我们最近宣布了 [React Native](https://code.facebook.com/videos/786462671439502/react-js-conf-2015-keynote-introducing-react-native-/)，一个运用 React Javascript 库来处理本地应用中 `UIView` 层次的框架，与网页版不同，这个库使管理的是 `UIView` 而非网页中的 `DOM` 元素。要告诉大家的是，Components 库**并不是** React Native，而是一个单独的项目，虽然这可能让人有些惊讶。

它们的区别是什么？其实很简单：当我们用 Components 重建新鲜事页面的时候 React Native 还没有被发明出来。在 Facebook, 每一个人都非常看好 React Native 的前景。并且已经应用在[Mobile Ads Manager](https://www.facebook.com/business/news/ads-manager-app) 和 [Groups](http://newsroom.fb.com/news/2014/11/introducing-the-facebook-groups-app/)两个应用中使用了。

和所有框架一样，也存在取舍；比如说，Components 选择使用 Objective-C++ 是因为它的类型安全性和性能，但是 React Native 对 Javascript 的运用让在开发环境下即时更新成为可能。这些项目经常会分享一些推动两者共同进步的创意。

###AsyncDisplayKit

那么用来驱动 Facebook Paper 应用的 UI 框架 AsyncDisplayKit 呢？它增添了在后台线程计算和渲染的能力，让你无需面对使用 UIKit 主线程会遇到的麻烦。

从设计哲学的角度上来说，AsyncDisplayKit 和 UIKit 的关联比和 React 要更强。不像 React，AsyncDisplayKit 没有强调使用宣言性句法，混合以及不可变性。

像 AsyncDisplayKit 一样，Components 在后台线程进行组件创造和分布 (这个很容易，因为我们的模型对象和组件本身全都是不可变的 - 不可能出现竞态条件！)

AsyncDisplayKit 能够进行复杂的手势驱动的动画，这一点正是 Components 的弱项所在。这样一来做选择就很容易了：如果你在设计一个复杂的手势驱动的界面，AsyncDisplayKit 应该是正确的选择。如果你的界面看起来和 Facebook 的新鲜事页面更类似，那么 Components 是恰当的选择。

### Components 的未来

Components 库在所有的显示大量信息的页面都会用到 (新鲜事，时间轴，群，事件，页面和搜索等等) 并且正在快速地在 Facebook 应用的其他部分被应用起来。用简洁，宣言性，可混合的组件是非常有趣的。

你可能觉得 Components 中的一些东西听起来很疯狂。[但是用点时间消化一下](https://signalvnoise.com/posts/3124-give-it-five-minutes)，你可能会自己挑战之前的一些假设，但是这些东西我们用着非常好而且对你们可能也有帮助。如果你想学习更多，[可以看看这个](http://www.infoq.com/presentations/facebook-ios-architecture)演讲，它深入地讨论了 Components 的一些细节。[为什么用 React?](http://facebook.github.io/react/docs/why-react.html) 的博文和它链接的资源都是非常好的参考。

我们非常想和社区分享 Components 背后的代码，而且我们马上要着手去做。如果你有想法要分享，[随时都可以联系我](mailto:adamjernst@fb.com) - 尤其是关于动画的想法！

---

 

原文 [React-Inspired Views](http://www.objc.io/issue-22/facebook.html)
