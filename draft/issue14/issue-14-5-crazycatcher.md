The Mac is not only a great platform to develop on — it's also a great platform to develop *for*. Last year we started building our first [Mac app](http://decksetapp.com), and it was a great experience to finally build something for the platform we're working on all day. However, we also had some difficulties discovering the peculiarities of the Mac compared to developing for iOS. In this article, we'll summarize what we've learned from this transition to hopefully give you a head start on your first Mac app.

Mac 不仅是一个强大的生产平台，也十分值得你*为其*开发一些东西。去年我们开始构建我们的第一款 [Mac 应用](http://decksetapp.com)，成功为我们日常工作所在的平台开发点东西是一次十分美好的体验。但是，和为 iOS 系统开发应用相比，在我们了解 Mac 特性的过程中也遇到了一些困难。这篇文章总结了我们从这一过渡中得到的经验，希望能启发你们去开发自己的第一个 Mac 应用。

In this article, we will assume OS X Yosemite to be the default platform we're talking about, as Apple made some significant strides this year to harmonize the platforms from a developer's perspective. However, we'll also point out what only applies to Yosemite, and what the situation was prior to this release.

在这篇文章中，我们假定 OS X Yosemite 为我们默认谈论的系统。今年，为了融合 iOS 和 OS X，苹果站在开发者的角度对 OS X 做出了巨大的改进。不过，我们会指出哪些特性仅适用于 Yosemite，而哪些特性也适用于之前的系统版本。

## What's Similar // 相似点

Although iOS and OS X are separate operating systems, they share a lot of commonalities, starting with the development environment — same language, same IDE. So you'll feel right at home. 

尽管 iOS 和 OS X 是两个独立的系统，它们却有很多共性。先就开发环境而言，他们使用同样的开发语言，同样的IDE。所以你会对这一切都感到非常熟悉。

More importantly though, OS X also shares a lot of the frameworks that you're already familiar with from iOS, like Foundation, Core Data, and Core Animation. This year, Apple harmonized the platforms further and brought frameworks to the Mac that were previously only on iOS, one example being Multipeer Connectivity. Also, on a lower level, you'll immediately see the APIs you're familiar with: Core Graphics, Core Text, libdispatch, and many more.

更重要的是，OS X 和你已经熟悉的 iOS 共用许多框架，像 Foundation，Core Data 和 Core Animation。今年，Apple 进一步整合两个平台，并给 Mac 带来了一些之前仅能在 iOS 上面使用的框架，其中一个例子就是 Multipeer Connectivity。在更底层的地方，你立刻可以看到你熟悉的 API：Core Graphics，Core Text，libdispatch 等等。

The UI framework is where things really start to diverge — UIKit feels like a slimmed down and modernized version of the AppKit that has been around and evolving since the NeXT days. The reason why, is when Apple introduced the iPhone, there was the chance to start from a clean slate and take what had been learned from AppKit: bring over the concepts and pieces that had proven to work well, and improve those that were less fortunate designs.

真正开始有区别的是 UI 框架 — AppKit 早在 NeXT 时代就已面世并不断进化，而 UIKit 就像是简约版及现代版的 AppKit。出现这种情况的原因，是当 Apple 推出 iPhone 时可以从头开始，并吸取 AppKit 的经验：把已证实过可行的概念和部件拿过来用，并改进不够精良的设计。

If you're interested in how this transition came about, check out these excellent episodes of the Debug podcast with [Nitin Ganatra](https://twitter.com/nitinganatra), former iOS apps director at Apple: [System 7 to Carbon](http://www.imore.com/debug-39-nitin-ganatra-episode-i-system-7-carbon), [OS X to iOS](http://www.imore.com/debug-40-nitin-ganatra-epsiode-ii-os-x-ios), and [iPhone to iPad](http://www.imore.com/debug-41-nitin-ganatra-episode-iii-iphone-ipad).

如果你对这个转换是怎么发生的感兴趣，请观看前 Apple iOS 应用总监 [Nitin Ganatra](https://twitter.com/nitinganatra) 播客上的精彩剧集：[System 7 to Carbon](http://www.imore.com/debug-39-nitin-ganatra-episode-i-system-7-carbon)，[OS X to iOS](http://www.imore.com/debug-40-nitin-ganatra-episode-ii-os-x-ios)，以及 [iPhone to iPad](http://www.imore.com/debug-41-nitin-ganatra-episode-iii-iphone-ipad)。

With this in mind, it's no wonder that UIKit and AppKit still share a lot of concepts. The UI is constructed out of windows and views, with messages being sent over the responder chain just as on iOS. Furthermore, `UIView` is `NSView`, `UIControl` is `NSControl`, `UIImage` is `NSImage`, `UIViewController` is `NSViewController`, `UITextView` is `NSTextView`... The list goes on and on.

考虑到这一点，也难怪 UIKit 和 AppKit 仍旧共享许多概念。UI 是基于 window 和 view 构建起来的，消息像 iOS 一样通过响应者链传递。此外，`UIView` 是 `NSView`，`UIControl` 是 `NSControl`，`UIImage` 是 `NSImage`，`UIViewController` 是 `NSViewController`，`UITextView` 是 `NSTextView`...这样的例子不胜枚举。

It's tempting to assume that you can use these classes in the same way, just by replacing `UI` with `NS`. But that's not going to work in many cases. The similarity is more on the conceptual level than in the implementation. You'll pretty much know about the building blocks to look for to construct your user interface, which is a great help. And a lot of the design patterns, such as delegation, will be similar. But the devil is in the details — you really need to read the documentation and learn how these classes should be used.

假设你仅需把 `UI` 前缀替换为 `NS` 前缀，你就可以用同样的方法使用这些类。但事实是在很多情况下这并不奏效。它们在实现上并没有在概念上那么相似。你在 iOS 上的经验至多能帮你大致了解构建用户界面的基础，并且很多设计模式，比如代理，都是类似的。但是细节是魔鬼 — 你真的应该通过阅读文档来学习如果使用这些类。

In the next section, we'll take a look at some of the pitfalls we fell into the most.

下一节，我们来看看那些常见的陷阱。

## What's Different // 不同点

### Windows and Window Controllers // Window 和 Window Controller

While you almost never interact with windows on iOS (since they take up the whole screen anyway), windows are key components on the Mac. Historically, Mac applications had multiple windows, each with its own role, very similar to view controllers on iOS. As a result, AppKit has an `NSWindowController` class that traditionally took on many of the tasks that you would handle in a view controller on iOS. View controllers are a relatively new addition to AppKit, and up until now, they did not receive actions by default, and missed a lot of the lifecycle methods, view controller containment, and other features you're used to from UIKit.

虽然在 iOS 上你几乎从来不用与 window 交互（因为它们占据了整个屏幕），window 在 Mac 上却是一个关键组件。从历史上看， Mac 应用包含多个 window，每个 window 有其自己的角色，非常类似于 iOS 上面的 view controller。因此, AppKit 有 `NSWindowController`，接管很多在 iOS 上你会在 view controller 里面处理的任务。view controller 被添加到 AppKit 的时间并不长，而且直到现在，它们默认不接受 action，并且缺失很多生命周期的方法，view controller 容器，以及很多你在 UIKit 上熟悉的特性。

But AppKit has changed, since Mac apps are relying more and more on a single window. As of OS X 10.10 Yosemite, the `NSViewController` is similar in many ways to `UIViewController`. It is also part of the responder chain by default. Just remember that if you target your Mac app to OS X 10.9 or earlier, window controllers on the Mac are much more akin to what you're used to as view controllers from iOS. As [Mike Ash writes](https://www.mikeash.com/pyblog/friday-qa-2013-04-05-windows-and-window-controllers.html), a good pattern to instantiate windows on the Mac is to have one nib file and one window controller per window type.

但 AppKit 框架已经改变，因为 Mac 应用越来越依赖于一个单一的 window。就 OS X 10.10 Yosemite 而言，`NSViewController` 在许多方面与 `UIViewController` 类似。它也默认是响应者链中的一环。但要记住，如果你的 Mac 应用需要兼容 OS X 10.9 或更早版本的系统，Mac 上的 window controller 更类似于 iOS 上你熟悉的 view controller。正如 [Mike Ash所言](https://www.mikeash.com/pyblog/friday-qa-2013-04-05-windows-and-window-controllers.html)，在 Mac 上实例化窗口的一个好的模式是：每个窗口类型对应一个 nib 文件和一个 window controller。

Furthermore, `NSWindow` is not a view subclass as is the case for `UIWindow`. Instead, each window holds a reference to its top-level view in the `contentView` property. 

此外，`NSWindow` 并不像 `UIWindow` 一样是一个 view 的子类。相反，每个窗口用 `contentView` 属性持有一个指向其顶层 view 的指针。

### Responder Chain // 响应者链

If you're developing for OS X 10.9 or lower, be aware that view controllers are not part of the responder chain by default. Instead, events will bubble up through the view tree and then go straight to the window and the window controller. In this instance, if you want a view controller to handle events, you will have to add it to the responder chain [manually](http://www.cocoawithlove.com/2008/07/better-integration-for-nsviewcontroller.html).

如果你在为 OS X 10.9 或者更低版本的系统开发，请注意在默认情况下 view controller 并不是响应者链的一环。相反，事件会沿着视图树向上传递然后直接到达 window 和 window controller。在这种情况下，如果你想在 view controller 处理事件，你需要[手动](http://www.cocoawithlove.com/2008/07/better-integration-for-nsviewcontroller.html)把它添加到响应者链中。

In addition to the difference in the responder chain, AppKit also has a stricter convention as to the method signature of actions. In AppKit, an action method always looks like this:

除了在响应者链方面的不同，AppKit 在 action 的命名方法上还有一个严格的惯例，一个 action 方法看起来总是类似这样子的：

    - (void)performAction:(id)sender;
    
The variants that are permissible on iOS with no arguments at all, or with a sender and an event argument, don't work on OS X. Furthermore, in AppKit, controls usually hold a reference to one target and an action pair, whereas you can associate multiple target-action pairs with a control on iOS using the `addTarget:action:forControlEvents:` method.

以上方法在 iOS 上面所允许的没有参数，或者有一个 sender 和 一个 event 参数的变体在 OS X 上面是无效的。此外，control（译者注：指 NSControl 及其子类）在 AppKit 中通常对应一个 target 和一个 action，而不像在 iOS 上可以通过 `addTarget:action:forControlEvents:` 方法为一个 control（译者注：指 UIControl 及其子类）关联多个 target-action 对。

### Views // View

The view system works very differently on the Mac, for historic reasons. On iOS, views were backed by Core Animation layers by default from the beginning. But AppKit predates Core Animation by decades. When AppKit was designed, there was no such thing as a GPU as we know it today. Therefore, the view system heavily relied on the CPU doing the work. 

因为历史遗留问题，Mac 的视图系统和 iOS 的视图系统有很大区别。iOS 上的 view 一开始就由 Core Animation layer 驱动。但是 AppKit 比 Core Animation 早了数十年，当 Apple 设计 AppKit 时，我们现在熟知的 GPU 还没有出现。因此，那时视图系统相关的任务主要靠 CPU 处理。

When you're getting started with development on the Mac, we strongly recommend you check out Apple's [Introduction to View Programming Guide for Cocoa](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CocoaViewsGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40002978). Furthermore, there are two excellent WWDC sessions you should watch: [Layer-Backed Views: AppKit + Core Animation](https://developer.apple.com/videos/wwdc/2012/#217) and [Optimizing Drawing and Scrolling](https://developer.apple.com/videos/wwdc/2013/#215).

当你要开始进行 Mac 相关的开发，我们强烈推荐你查看 Apple 的 [Introduction to View Programming Guide for Cocoa](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CocoaViewsGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40002978)。此外，你还应该看一下这两个精彩的 WWDC session：[Layer-Backed Views: AppKit + Core Animation](https://developer.apple.com/videos/wwdc/2012/#217) 和 [Optimizing Drawing and Scrolling](https://developer.apple.com/videos/wwdc/2013/#215)。

#### Layer-Backed Views // Layer-Backed View

By default, AppKit views are not backed by Core Animation layers; layer-backing support has been integrated into AppKit retroactively. But while you never have to worry about this with UIKit, with AppKit there are decisions to make. AppKit differentiates between layer-backed and layer-hosting views, and layer backing can be turned on and off on a per-view-tree basis. 

默认情况下，AppKit 的 view 不是由 Core Animation layer 驱动的；AppKit 整合 layer-backing 是 iOS 反哺的结果。一些在 AppKit 需要做的决定你在 UIKit 从来不需要关心。AppKit 区分 layer-backed view 和 layer-hosting view，可以在每个视图树的根节点启用或者禁用 layer backing。

The most straightforward approach to enable layer backing is to set the `wantsLayer` property to `YES` on the window's content view. This will cause all views in the window's view tree to have their own backing layers, so there's no need to repeatedly set this property on each individual view. This can be done in code or simply in Interface Builder's View Effects Inspector.

把窗口的 contentView 的 `wantsLayer` 属性设置为 `YES` 是启用 layer backing 最简单的方法。这会导致 window 的视图树中所有的 view 都启用 layer backing，这样就没必要反复设置每个 view 的 wantsLayer 属性了。这个操作可以用代码或者在 Interface Builder 的 View Effects Inspector 面板完成。

In contrast to iOS, on the Mac you should treat the backing layers as an implementation detail. This means you should not try to interact with the layers directly, as AppKit owns those layers. For example, on iOS you could simply say:

和 iOS 相比而言，在 Mac 上你应该把 backing layer 看做是一个实现细节。这意味着你不应该和这些 layer 直接交互，因为 AppKit 才是这些 layer 的拥有者。举个例子，在 iOS 上你可以随意编写这样的代码：

    self.layer.backgroundColor = [UIColor redColor].CGColor;
    
But in AppKit, you shouldn't touch the layer. If you want to interact with the layer in such ways, then you have to go one step further. Overriding `NSView`'s `wantsUpdateLayer` method to return `YES` enables you to change the layer's properties. If you do this though, AppKit will no longer call the view's `drawRect:` method. Instead, `updateLayer` will be called during the view update cycle, and this is where you can modify the layer. 

但是在 AppKit，你不应该直接修改这些 layer。如果想用这种方式和 layer 交互，你还有一步工作要做。重写 `NSView` 的 `wantsUpdateLayer` 方法并返回 `YES` 能让你可以改变 layer 的属性。如果你这样做，AppKit 将不会再调用 view 的 `drawRect:` 方法。取而代之，`updateLayer` - 你可以修改 layer 的地方 - 会在 view 的更新周期中被调用。

You can use this, for example, to implement a very simple view with a uniform background color (yes, `NSView` has no `backgroundColor` property):

举个例子，你可以用这方法去实现一个非常简单的有纯色背景的 view（没错，`NSView` 没有 `backgroundColor` 属性）：

    @interface ColoredView: NSView
    
    @property (nonatomic) NSColor *backgroundColor;
    
    @end
    
    
    @implementation ColoredView
    
    - (BOOL)wantsUpdateLayer
    {
        return YES;
    }
    
    - (void)updateLayer
    {
        self.layer.backgroundColor = self.backgroundColor.CGColor;
    }
    
    - (void)setBackgroundColor:(NSColor *)backgroundColor
    {
        _backgroundColor = backgroundColor;
        [self setNeedsDisplay:YES];
    }
    
    @end

This example assumes that layer backing is already enabled for the view tree where you'll insert this view. The alternative to this would be to simply override the `drawRect:` method to draw the colored background. 

这个例子的前提是这个 view 的父 view 已经为其视图树启用了 layer backing。另一种可行的实现则只需要重写 `drawRect:` 方法并在其中绘制背景颜色。

##### Coalescing Layers // 合并 Layer

Opting into layer-backed views will increase the amount of memory needed (each layer has its own backing store, probably overlapping with other views' backing stores) and introduce a potentially costly compositing step of all the layers. Since OS X 10.9, you have been able to tell AppKit to coalesce the contents of a view tree into one common backing layer by using the `canDrawSubviewsIntoLayer` property. This can be a good option if you know that you will not need to animate subviews individually. 

进入、选择、退出 layer-backed view 都会带来巨大的内存消耗（每一个 layer 有其自己的 backing store，还有可能和其他 view 的 backing store 重复）而且会带来潜在的合成这些 layer 的消耗。从 OS X 10.9 开始，你可以通过设置 `canDrawSubviewsIntoLayer` 属性来让 AppKit 合并一个视图树中所有 layer 的内容到一个共有的 layer。如果你不需要单独对一个 view 中的子 view 做动画，这将是一个很好的选择。

All subviews that are implicitly layer-backed (i.e. you didn't explicitly set `wantsLayer = YES` on these sub views) will now get drawn into the same layer. However, subviews that do have `wantsLayer` set to `YES` will still have their own backing layer and their `drawRect:` method will be called, no matter what `wantsUpdateLayer` returns.

所有隐式 layer-backed 的子 view（比如，你没有显式地对这些子 view 设置 `wantsLayer = YES`）将不会被绘制到同一个 layer 中。不过，`wantsLayer` 设置为 `YES` 的子 view 仍然持有它们自己的 backing layer， 而且不管 `wantsUpdateLayer` 返回什么，它们的 `drawRect:` 方法仍然会被调用。

##### Layer Redraw Policy // Layer 重绘策略

Another gotcha that's important to know is the fact that layer-backed views have their redraw policy set to `NSViewLayerContentsRedrawDuringViewResize` by default. This resembles the behavior of non-layer-backed views, but it might be detrimental to animation performance if a drawing step is introduced for each frame of the animation.

另外一个需要注意的地方：layer-backed view 会默认设置重绘策略为 `NSViewLayerContentsRedrawDuringViewResize`。这类似于非 layer-backed view，不过如果动画的每一帧都引入一次绘制的话可能会对动画的性能造成不利影响。

To avoid this, you can set the `layerContentsRedrawPolicy` property to `NSViewLayerContentsRedrawOnSetNeedsDisplay`. This way, you have control over when the layer contents need to be redrawn. A frame change will not automatically trigger a redraw anymore; you are now responsible for triggering it by calling `-setNeedsDisplay:`.

为了避免这个问题，你可以把 `layerContentsRedrawPolicy` 属性设置为 `NSViewLayerContentsRedrawOnSetNeedsDisplay` 。这样子的话，便由你来决定 layer 的内容何时需要重绘。帧的改变将不再自动触发重绘；现在你要负责调用 `-setNeedsDisplay:` 来触发重绘操作。

Once you change the redraw policy in this way, you might also want to look into the [`layerContentsPlacement`](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSView_Class/Reference/NSView.html#//apple_ref/occ/instm/NSView/layerContentsPlacement) property, which is the view's equivalent to the layer's `contentGravity` property. This allows you to specify how the existing layer content will be mapped into the layer as it is resized.

一旦你这样更改了重绘策略，你也许会想了解下 view 中和 layer 的 `contentGravity` 属性等价的 [`layerContentsPlacement`](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSView_Class/Reference/NSView.html#//apple_ref/occ/instm/NSView/layerContentsPlacement) 属性。这个属性允许你指定在调整大小的时候当前的 layer 内容该怎么映射到 layer 上。

#### Layer-Hosting Views // Layer-Hosting View

`NSView`'s layer story doesn't end here, though. There is a whole different option to work with Core Animation layers — called layer-hosting views. In short, with a layer-hosting view, you can do with the layer and its sublayers whatever you want. The price you pay for this is that you cannot add any subviews to this view anymore. A layer-hosting view is a leaf node in the view tree. 

`NSView` 的 layer 故事并没有完结。你可以用另一种完全不一样的方式来使用 Core Animation layer — 称为 layer-hosting view。简单来说，你可以对一个 layer-hosting view 的 layer 及其子 layer 做任何操作，代价是你再也不能给该 view 添加任何子 view。layer-hosting view 是视图树中的叶节点。

To create a layer-hosting view, you first have to assign a layer object to the `layer` property, and then set the `wantsLayer` to `YES`. Note that the sequence of these steps is crucial:

要创建一个 layer-hosting view，你首先要为 view 的 `layer` 属性分配一个 layer 对象，然后把 `wantsLayer` 设置为 `YES`。注意，这些步骤的顺序是非常关键的：

    - (instancetype)initWithFrame:(NSRect)frame
    {
        self = [super initWithFrame:frame];
        if (self) {
            self.layer = [[CALayer alloc] init];
            self.wantsLayer = YES;
        }
    }
    
It's important that you set `wantsLayer` *after* you've set your custom layer.

在你设置了你自定义的 layer *之后*才设置 `wantsLayer` 是非常重要的。

#### Other View-Related Gotchas // 其他与 View 相关的陷阱

By default, the view's coordinate system origin is located at the lower left on the Mac, not the upper left as on iOS. This can be confusing at first, but you can also decide to restore the behavior you're used to by overriding `isFlipped` to return `YES`.

默认情况下，Mac 上视图的坐标系统原点位于左下角，而不是像 iOS 的左上角。刚开始这可能会让人混乱，不过你可以通过重写 `isFlipped` 并返回 `YES` 来恢复到你熟悉的左上角。

As AppKit views don't have background color properties that you can set to `[NSColor clearColor]` in order to let the background shine through, many `NSView` subclasses like `NSTextView` or `NSScrollView` have a `drawsBackground` property that you have to set to `NO` if you want the view to be transparent. 

由于 AppKit 中的 view 没有背景颜色属性可以让你直接设置为 `[NSColor clearColor]` 来让其变得透明，许多 `NSView` 的子类比如 `NSTextView` 和 `NSScrollView` 开放了一个 `drawsBackground` 属性，如果你想让这一类 view 透明，你必须设置该属性为 `NO`。

In order to receive events for the mouse cursor entering or exiting the view or being moved within the view, you need to create a tracking area. There's a special override point in `NSView` called `updateTrackingAreas`, which you can use to do this. A common pattern looks like this:

为了能接收光标进出一个 view 或者在 view 里面移动的事件，你需要创建一个追踪区域。你可以在 `NSView` 中指定的 `updateTrackingAreas` 方法中来做这件事情。一个通用的写法看起来是这样子的：

    - (void)updateTrackingAreas
    {
        [self removeTrackingArea:self.trackingArea];
        self.trackingArea = [[NSTrackingArea alloc] initWithRect:CGRectZero 
                                                         options:NSTrackingMouseEnteredAndExited|NSTrackingInVisibleRect|NSTrackingActiveInActiveApp
                                                           owner:self 
                                                        userInfo:nil];
        [self addTrackingArea:self.trackingArea];
    }

AppKit controls have been traditionally backed by `NSCell` subclasses. These cells should not be confused with table view cells or collection view cells in UIKit. AppKit originally made the distinction between views and cells in order to save resources — views would delegate all their drawing to a more lightweight cell object that could be reused for all views of the same type. 

AppKit 的 control（译者注：指 NSControl 及其子类）之前是由 `NSCell` 的子类驱动的。不要混淆这些 cell 和 UIKit 里 table view 的 cell 及 collection view 的 cell。AppKit 最初区分 view 和 cell 是为了节省资源 - view 应该把所有的绘制工作代理给更轻量级的可以被所有同类型的 view 重用的 cell 对象。

Apple is deprecating this approach step by step, but you'll still encounter it from time to time. For example, if you would want to create a custom button, you would subclass `NSButton` *and* `NSButtonCell`, implement your custom drawing in the cell subclass, and then assign your cell subclass to be used for the custom button by overriding the  `+[NSControl cellClass]` method. 

Apple 正在一步步地抛弃这样的实现方法了，但是你还是会时不时碰到这样的问题。举个例子，如果你想创建一个自定义的按钮，你首先要继承 `NSButton` *和* `NSButtonCell`，然后在这个 cell 子类里面进行你自定义的绘制，然后通过重写 `+[NSControl cellClass]` 方法告诉自定义按钮使用你的 cell 子类。

Lastly, if you ever wonder how to get to the current Core Graphics context when implementing your own `drawRect:` method, it's the `graphicsPort` property on `NSGraphicsContext`. Check out the [Cocoa Drawing Guide](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CocoaDrawingGuide/) for more details.

最后，如果你想知道在你自己的 `drawRect:` 方法里怎么获取当前的 Core Graphics 上下文，答案是 `NSGraphicsContext` 的 `graphicsPort` 属性。详细内容请查看 [Cocoa Drawing Guide](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CocoaDrawingGuide/)。

### Animations // 动画

As a consequence of the differences in the view system discussed above, animations also work quite differently on the Mac. For a good overview, watch the WWDC session on [Best Practices for Cocoa Animation](https://developer.apple.com/videos/wwdc/2013/#213).

由于上面提到的视图系统的差异，动画在 Mac 上的运作方式也十分不同。想要一个好的概述，请观看 WWDC session：
[Best Practices for Cocoa Animation](https://developer.apple.com/videos/wwdc/2013/#213)

If your views are not layer-backed, then naturally, animations will be a CPU-intensive process, as every step of the animation has to be drawn accordingly in the window-backing store. Since nowadays you'd mostly want to animate layer-backed views to get really smooth animations, we'll focus on this case here.

如果你的 view 不是由 layer 驱动的，那你的动画自然是完全由 CPU 处理，这意味着动画的每一步都必须相应地绘制到 window-backing store 上。既然现今你主要想对 layer-backed view 做动画以获得流畅的动画效果，那我们就专注于这种情况。

As mentioned above, you should never touch the backing layers of layer-backed views in AppKit (see the section "Rules for Modifying Layers on OS X" at the bottom of [this page of the Core Animation Programming Guide](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreAnimation_guide/CreatingBasicAnimations/CreatingBasicAnimations.html#//apple_ref/doc/uid/TP40004514-CH3-SW18). The layers are managed by AppKit, and — contrary to iOS — the views' geometry properties are not just a reflection of the corresponding layer properties, but AppKit actually syncs the view geometry internally to the layer geometry. 

正如上面说的，在 AppKit 中你不应该修改 layer-backed view 中的 layer (看 [Core Animation Programming Guide](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreAnimation_guide/CreatingBasicAnimations/CreatingBasicAnimations.html#//apple_ref/doc/uid/TP40004514-CH3-SW18) 这篇文档底部 “Rules for Modifying Layers in OS X” 那一节）。这些 layer 由 AppKit 管理，而且和 iOS 相反，view 的几何属性并不仅仅是对应的 layer 的几何属性的映射，但 AppKit 却会把 view 内部的几何属性同步到 layer。

There are a few different ways you can trigger an animation on a view. First, you can use the [animator proxy](file:///Users/florian/Library/Developer/Shared/Documentation/DocSets/com.apple.adc.documentation.AppleOSX10.9.CoreReference.docset/Contents/Resources/Documents/documentation/Cocoa/Reference/NSAnimatablePropertyContainer_protocol/Introduction/Introduction.html#//apple_ref/occ/intfm/NSAnimatablePropertyContainer/animator):

你可以用几种不同的方法对一个 view 进行动画。第一种，你可以使用 [animator proxy](file:///Users/florian/Library/Developer/Shared/Documentation/DocSets/com.apple.adc.documentation.AppleOSX10.9.CoreReference.docset/Contents/Resources/Documents/documentation/Cocoa/Reference/NSAnimatablePropertyContainer_protocol/Introduction/Introduction.html#//apple_ref/occ/intfm/NSAnimatablePropertyContainer/animator)：

    view.animator.alphaValue = .5;
    
Behind the scenes, this will enable implicit animations on the backing layer, set the alpha value, and disable the implicit animations again.

在幕后，这句代码会启用 layer 的隐式动画，设置其透明度，然后再次禁用 layer 的隐式动画。

You can also wrap this into an [animation context](https://developer.apple.com/library/mac/documentation/cocoa/reference/NSAnimationContext_class/Introduction/Introduction.html) in order to get a completion handler callback:

你还可以把这句代码封装到一个 [animation context](https://developer.apple.com/library/mac/documentation/cocoa/reference/NSAnimationContext_class/Introduction/Introduction.html) 中，这样你就能得到它的结束回调：

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
        view.animator.alphaValue = .5;
    } completionHandler:^{
        // ...
    }]; 

In order to influence the duration and the timing function, we have to set these values on the animation context:

如果想改变 `duration` 和 `timingFunction`，我们必须对其动画上下文进行设置：

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
        context.duration = 1;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        view.animator.alphaValue = .5;
    } completionHandler:^{
        // ...
    }]; 

If you don't need the completion handler, you can also use the shorthand form:

如果你不需要结束回调，你可以用这种简化形式：

    [NSAnimationContext currentContext].duration = 1;
    view.animator.alphaValue = .5;    

Lastly, you can also enable implicit animations, so that you don't have to explicitly use the animator proxy each time:

最后，你可以启用隐式动画，这样你就不必每次都明确地使用 animator proxy 了：

    [NSAnimationContext currentContext].allowsImplicitAnimations = YES;
    view.alphaValue = .5;

For more control over the animation, you can also use `CAAnimation` instances. Contrary to on iOS, you don't add them directly to the layer (as you're not supposed to touch the layer yourself), but you use the API defined in the [`NSAnimatablePropertyContainer`](https://developer.apple.com/library/mac/documentation/cocoa/reference/NSAnimatablePropertyContainer_protocol/Introduction/Introduction.html), which is implemented by `NSView` and `NSWindow`. For example:

要更全面地控制动画，你可以使用 `CAAnimation` 实例。和 iOS 相反，你不能直接把它们加到 layer 上（因为 layer 不应该由你来修改），不过你可以使用 [`NSAnimatablePropertyContainer`](https://developer.apple.com/library/mac/documentation/cocoa/reference/NSAnimatablePropertyContainer_protocol/Introduction/Introduction.html) 协议中定义的 API，`NSView` 和 `NSWindow` 已经实现了该协议。举个例子：

    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.values = @[@1, @.9, @.8, @.7, @.6];
    view.animations = @{@"alphaValue": animation};
    view.animator.alphaValue = .5;

For `frame` animations, it's important to set the view's `layerContentsRedrawPolicy` to `NSViewLayerContentsRedrawOnSetNeedsDisplay`, because the view's content will otherwise be redrawn on every frame.

对于`帧`动画来说，把 view 的 `layerContentsRedrawPolicy` 设置为 `NSViewLayerContentsRedrawOnSetNeedsDisplay` 是非常重要的，不然的话 view 的内容在每一帧都会被重绘。

Unfortunately, `NSView` doesn't expose all animatable properties of Core Animation layers, `transform` being the most important example. Check out [this article](http://jwilling.com/osx-animations) by [Jonathan Willings](https://twitter.com/willing) for a description of how you can work around this limitation. Just be aware that you're leaving officially sanctioned territory here.

很遗憾，`NSView` 没有开放 Core Animation layer 所有可以进行动画的属性，`transform` 是其中最重要的例子。看看 [Jonathan Willings](https://twitter.com/willing) 的[这篇文章](http://jwilling.com/osx-animations)，它描述了你可以如何解决这些限制。不过注意，文章中的解决方案是不受官方支持的。

All the things mentioned above apply to *layer-backed* views. If you have a *layer-hosting* view, you can use `CAAnimation`s directly on the view's layer or sublayers, since you own them.

上面提到的所有东西都适用于 *layer-backed* view。对于 *layer-hosting* view 来说，你可以直接对 view 的 layer 或者子 layer 使用 `CAAnimations`，因为你拥有它们的控制权。

### Collection View

Although AppKit comes with an `NSCollectionView` class, its capabilities lag far behind its UIKit counterpart. Since `UICollectionView` is such a versatile building block on iOS, depending on your UI concept, it's a tough pill to swallow that there is nothing like it in AppKit. So when you're planning your user interface, take into account that it might be a lot of work to create grid layouts that are otherwise very easy to achieve on iOS.

尽管 AppKit 有 `NSCollectionView` 类，它的功能却比 UIKit 里对应的类滞后很多。鉴于 `UICollectionView` 是 iOS 上一个如此多功能的控件（当然，这取决于你的 UI 观念），很难忍受 AppKit 里对应的控件一点都不像它。所以当你要规划你的用户界面的时候，要考虑构建一个网格布局有可能会非常麻烦，相反，在 iOS 上这很容易实现。

### Images // 图像

Coming from iOS, you'll be familiar with `UIImage`, and conveniently, there is a corresponding `NSImage` class in AppKit. But you'll quickly notice that these classes are vastly different. `NSImage` is, in many ways, a more powerful class than `UIImage`, but this comes at the cost of increased complexity. Apple's [Cocoa Drawing Guide](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Images/Images.html#//apple_ref/doc/uid/TP40003290-CH208-BCIBBFGJ) has a good introduction of how to work with images in AppKit.

来自 iOS，你对 `UIImage` 非常熟悉，正巧，AppKit 也有一个对应的 `NSImage` 类。不过很快你就会意识到这两个类简直是天差地别。从很多方面来说，`NSImage` 都比 `UIImage` 强大很多，但这是建立在复杂性增加的代价上的。Apple 的 [Cocoa Drawing Guide](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Images/Images.html#//apple_ref/doc/uid/TP40003290-CH208-BCIBBFGJ) 很好地介绍了如何使用 AppKit 中的图像。

The most important conceptual difference is that `NSImage` is backed by one or more image representations. AppKit comes with some `NSImageRep` subclasses, like `NSBitmapImageRep`, `NSPDFImageRep`, and `NSEPSImageRep`. For example, one `NSImage` object could hold a thumbnail, a full-size, and a PDF representation for printing of the same content. When you draw the image, an image representation matching the current graphics context and drawing dimensions will be picked based on the color space, dimensions, resolution, and depth. 

概念上最重要的不同是 `NSImage` 由一个或者多个图像表示（译者注：这里的图像表示为名词，可以参考[百度百科](http://baike.baidu.com/view/4301255.htm)，本节下同）驱动，这些图像表示在 AppKit 表现为一些 `NSImageRep` 的子类，像 `NSBitmapImageRep`，`NSPDFImageRep` 和 `NSEPSImageRep`。举个例子，一个 `NSImage` 对象为了打印同样的内容可以持有缩略图，全尺寸和 PDF 三个图像表示。当你绘制图像时，图像表示会匹配当前的图形上下文，而绘图尺寸会根据颜色空间，维度，分辨率以及绘图深度得出。

Furthermore, images on the Mac have the notion of resolution in addition to size. An image representation has three properties that play into that: `size`, `pixelsWide`, and `pixelsHigh`. The size property determines the size of the image representation when being rendered, whereas the pixel width and height values specify the raw image size as derived from the image data itself. Together, those properties determine the resolution of the image representation. The pixel dimensions can be different from the representation's size, which in turn can be different from the size of the image the representation belongs to. 

此外，Mac 上的图像除了尺寸还有分辨率的概念。图像表示的分辨率由三个属性构成：`size`，`pixelsWide` 以及 `pixelsHigh`。size 属性决定了图像表示被渲染时的尺寸，而 pixelsWide 和 pixelsHigh 指定了源于图像数据的原始尺寸。这三个属性共同决定了图像表示的分辨率。像素尺寸可以和**图像表示**的尺寸不一样，正如**图像表示**的尺寸可以和它所属的图片的尺寸不一样。

Another difference from `UIImage` is that `NSImage` will cache the result when it's drawn to the screen (this behavior is configurable via the [`cacheMode`](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSImage_Class/Reference/Reference.html#//apple_ref/occ/instm/NSImage/cacheMode) property). When you change an underlying image representation, you have to call `recache` on the image for the change to take effect.

另外一个和 `UIImage` 不一样的地方是当它被绘制到屏幕上时 `NSImage` 会缓存绘制结果（可以通过 [`cacheMode`](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSImage_Class/Reference/Reference.html#//apple_ref/occ/instm/NSImage/cacheMode) 属性配置）。当你改变底层的图像表示，你必须对图像调用 `recache` 才能使其生效。

But working with images on the Mac isn't always more complex than on iOS. `NSImage` provides a very easy way to draw a new image, whereas on iOS you would have to create a bitmap context, then create a `CGImage` from that, and finally use it to initialize an `UIImage` instance. With `NSImage`, you can simply do:

不过在 Mac 上面处理图像并不总是比 iOS 复杂。`NSImage` 提供了一个很简单的方法去绘制一个新图像，而在 iOS 上，你需要创建一个位图上下文，然后用位图上下文创建 `CGImage`，最终用该 CGImage 初始化一个 `UIImage` 实例。用 `NSImage` 你仅需：

    [NSImage imageWithSize:(NSSize)size 
                flipped:(BOOL)drawingHandlerShouldBeCalledWithFlippedContext 
         drawingHandler:^BOOL (NSRect dstRect) 
    {
        // your drawing commands here...
    }];


### Colors // 颜色

The Mac supports fully color-calibrated workflows, so anything having to do with colors is potentially more complicated. Color management is a complex topic, and we're not even going to pretend that we're experts in this. Instead, we're going to refer you to Apple's guides on the topic: [Introduction to Color Programming Topics for Cocoa](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/DrawColor/DrawColor.html#//apple_ref/doc/uid/10000082-SW1) and [Introduction to Color Management](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/csintro/csintro_intro/csintro_intro.html#//apple_ref/doc/uid/TP30001148).

Mac 支持完全的 color-calibrated 工作流，所有跟颜色相关的任何东西都有可能变得更复杂。颜色管理是一个复杂的主题，我们也不精通这方面的东西。所以，我们希望你看看 Apple 关于这方面的指南： [Introduction to Color Programming Topics for Cocoa](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/DrawColor/DrawColor.html#//apple_ref/doc/uid/10000082-SW1) 和 [Introduction to Color Management](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/csintro/csintro_intro/csintro_intro.html#//apple_ref/doc/uid/TP30001148)。

A common task is to use a color in your app that your designers have specified for you. In order to get the correct color, it's important to pick the color from the design template using the same color space as the one you use to programatically specify it. The standard system color picker has a drop-down menu, where you can choose the color space you want to use. We suggest to use the device-independent sRGB color space, and then later use the `+[NSColor colorWithSRGBRed:green:blue:alpha:]` class method to create the color in code.

你经常需要在你的应用里使用一个你的设计师给你指定的颜色。要取得正确的颜色，设计模板使用的颜色空间和你以编程方式指定的颜色空间保持一致是非常重要的。系统标准的颜色选择器有一个下拉菜单，你可以在这里选择你想要的颜色空间。我们建议使用 device-independent sRGB 颜色空间，然后在代码里面用 `+[NSColor colorWithSRGBRed:green:blue:alpha:]` 类方法来创建颜色。

![](http://img.objccn.io/issue-14/color-picker.png)


### Text System // 文字系统

With [TextKit](http://www.objc.io/issue-5/getting-to-know-textkit.html), iOS 7 finally got an equivalent to what has been around on the Mac for ages as the [Cocoa Text System](https://developer.apple.com/library/mac/documentation/TextFonts/Conceptual/CocoaTextArchitecture/TextSystemArchitecture/ArchitectureOverview.html). But Apple didn't just transfer the system from the Mac to iOS; instead, Apple made some significant changes to it. 

有了 [TextKit](http://objccn.io/issue-5-1/)，iOS 7 终于有了和 Mac 上早就有了的 [Cocoa Text System](https://developer.apple.com/library/mac/documentation/TextFonts/Conceptual/CocoaTextArchitecture/TextSystemArchitecture/ArchitectureOverview.html) 等效的东西。但 Apple 并不仅仅是把文字系统从 Mac 上转移到 iOS；相反，Apple 对其做了些显著的改变。

For example, AppKit exposes the `NSTypesetter` and `NSGlyphGenerator`, both of which you can subclass to customize their behaviors. On iOS, those classes are not exposed, but some of the hooks for customization are available via the `NSLayoutManagerDelegate` protocol. 

举个例子，AppKit 开放 `NSTypesetter` 和 `NSGlyphGenerator`，你可以通过继承这两者来自定义它们的一些特性。iOS 并不开放这些类，但是你可以通过 `NSLayoutManagerDelegate` 协议达到定制的目的。

Overall, it's still pretty similar, and you'll be able to do everything on the Mac that you can do on iOS (and more), but for some things, you will have to look for the appropriate hooks in different places. 

总体来说，两个平台的文字系统还是非常相似的，所有你在 iOS 上能做的在 Mac 上都可以做（甚至更多），但对于一些东西，你必须从不同的地方寻找合适的方法实现。

### Sandboxing // 沙盒

If you want to sell your Mac app through the Mac App Store, it has to be sandboxed. You might wonder why we're mentioning this here, since sandboxing has been the norm on iOS from day one (so you're very much familiar with it). However, we're so used to what apps were able to do on the Mac before sandboxing appeared on the radar, that it's sometimes easy to overlook the fact that a feature you want to implement might get you into conflict with the sandboxing restrictions.

符合沙盒机制的 Mac 应用才能通过 Mac App Store 销售。鉴于沙盒从一开始就是 iOS 的基本规范（所以你会对它非常熟悉），你可能会好奇我们为什么要在这里提起它。然而，我们已经习惯了沙盒机制还没出现之前的 Mac 开发环境，所以有时候会忽视一些你想要实现的功能会和沙盒的限制出现冲突。

The file system has always been exposed to the user on the Mac, so sandboxed apps are able to get access to files outside of their containers if the user signals clear intent to do so. It's the same model that has since come to iOS 8. However, whereas this approach enhances the prior possibilities on iOS, it restricts the prior possibilities on the Mac. That makes it easy to oversee or forget.

Mac 的文件系统是一直对用户开放的，所以如果用户明确表示，沙盒应用可以访问自身应用外的文件。同样的机制同时引进了 iOS 8。不过，和通过这种方式放宽对 iOS 的限制相反，它却加强了对 Mac 的限制。这让它容易被忽视和遗忘。

We're guilty of this ourselves, which is why we hope to be able to prevent you from falling into the same trap. When we started development of [Deckset](http://decksetapp.com) — an app that transforms simple Markdown into presentation slides — we never thought that we might run into sandboxing issues. After all, we only needed read access to the Markdown file. 

对此我们也十分惭愧，所以希望能阻止你犯同样的错误。当我们开始开发 [Deckset](http://decksetapp.com) — 一款把简单 Markdown 文件转换为演示幻灯片的应用 — 时，我们从来没想过我们会碰到什么关于沙盒的问题。毕竟，我们只需要读 Markdown 文件的权限。

What we forgot about is that we also needed to display the images that are referenced in the Markdown. And although you type the path to the image in your Markdown file, that's not a user intent that counts within the sandboxing system. In the end, we 'solved' the problem by adding a notification UI in the app that prompts the user to allow us access to the files by explicitly opening the common ancestor folder of all images in the file once.

我们忘记了我们还要显示 Markdown 文件中引用的图片。尽管你在 Markdown 文件中输入了图片文件的路径，但沙盒系统并不认为这是用户的意图。最后，我们通过一个像通知中心一样的 UI 来提示用户授权我们访问 Markdown 文件中的所有图片‘解决’了该问题。

Take a look at Apple's [sandboxing guides](https://developer.apple.com/app-sandboxing/) early in the development process so that you don't get tripped up later on.

及早看一下 Apple 的 [sandboxing guides](https://developer.apple.com/app-sandboxing/) 以防以后在相关的问题上犯错误。

## What's Unique // 独有特性

There are many things you can only do on the Mac, mostly either due to its different interaction model or to its more liberal security policies. In this issue, we have articles covering some of these things in depth: [cross-process communication](/issue-14/xpc.html), [making an app scriptable](/issue-14/scripting-data.html), [scripting other apps in the sandbox](/issue-14/sandbox-scripting.html), and creating a [plugin infrastructure](/issue-14/plugins.html) for your apps.

有很多事情你只能在 Mac 上做，这主要是因为它不同的交互模型和它更为宽松的安全策略。在本期话题中，我们有一些文章深入探讨了其中的一些内容：[进程间通讯](http://objccn.io/issue-14-4/)，[使 Mac 应用脚本化](http://objccn.io/issue-14-1/), [在沙盒中脚本化其他应用](http://objccn.io/issue-14-2/), [为你的应用构建插件](http://objccn.io/issue-14-3/)。

Of course, that's just a small subset of features unique to the Mac, but it gives you a good idea of the aspects that iOS 8 just starts to scratch the surface of in terms of extensibility and communication between apps. There's, of course, much more to explore: Drag and Drop, Printing, Bindings, OpenCL, to name just a few examples.

当然，这只是 Mac 独有特性中很小的一部分，但这给了你一个很好的视角看待 iOS 8 从头开始打造其可扩展性和 app 间通讯。最后，还有很多东西等待你去探索：Drag and Drop，Printing，Bindings，OpenCL，这里仅仅是举几个例子。
