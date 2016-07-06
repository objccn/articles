自动布局在 OS X 10.7 中被引进，一年后在 iOS 6 中也可以用了。不久在 iOS 7 中的程序将会有望设置全局字体大小，因此除了不同的屏幕大小和方向，用户界面布局也需要更大的灵活性。Apple 也在自动布局上花了很大功夫，所以如果你还没做过这一块，那么现在就是接触这个技术的好时机。

很多开发者在第一次尝试使用这个技术时都非常挣扎，因为用 Xcode 4 的 Interface Builder 建立 constraint-based layouts 体验非常糟糕，但不要因为这个而灰心。自动布局其实比现在 Interface Builder 所支持的要好很多。Xcode 5 在这块中将会带来重要的变化。

这篇文章不是用来介绍 Auto Layout 的。如果你还没用过它，那还是先去 WWDC 2012 看看基础教程吧。([202 – Introduction to Auto Layout for iOS and OS X][6], [228 – Best Practices for Mastering Auto Layout][7], [232 – Auto Layout by Example][8])。

相反我们会专注于一些高级的使用技巧和方法，这将会让你使用自动布局的时候效率更高，(开发)生活更幸福。大多数内容在 WWDC 会议中都有提到，但它们都是在日常工作中容易被忽视或遗忘的。

<a name="layout-process"> </a>
## 布局过程

首先我们总结一下自动布局将视图显示到屏幕上的步骤。当你根据自动布局尽力写出你想要的布局种类时，特别是高级的使用情况和动画，这有利于后退一步，并回忆布局过程是怎么工作的。

和 springs，struts 比起来，在视图被显示之前，自动布局引入了两个额外的步骤：更新约束 (updating constraints) 和布局视图 (laying out views)。每一步都是依赖前一步操作的；显示依赖于布局视图，布局视图依赖于更新约束。

第一步：更新约束，可以被认为是一个“计量传递 (measurement pass)”。这是自下而上（从子视图到父视图）发生的，它为布局准备好必要的信息，而这些布局将在实际设置视图的 frame 时被传递过去并被使用。你可以通过调用 setNeedsUpdateConstraints 来触发这个操作，同时，你对约束条件系统做出的任何改变都将自动触发这个方法。无论如何，通知自动布局关于自定义视图中任何可能影响布局的改变是非常有用的。谈到自定义视图，你可以在这个阶段重写 updateConstraints 来为你的视图增加需要的本地约束。

第二步：布局，这是个自上而下（从父视图到子视图）的过程，这种布局操作实际上是通过设置 frame（在 OS X 中）或者 center 和 bounds（在 iOS 中）将约束条件系统的解决方案应用到视图上。你可以通过调用 setNeedsLayout 来触发一个操作请求，这并不会立刻应用布局，而是在稍后再进行处理。因为所有的布局请求将会被合并到一个布局操作中去，所以你不需要为经常调用这个方法而担心。

你可以调用 `layoutIfNeeded` / `layoutSubtreeIfNeeded`（分别针对 iOS / OS X）来强制系统立即更新视图树的布局。如果你下一步操作依赖于更新后视图的 frame，这将非常有用。在你自定义的视图中，你可以重写 `layoutSubviews` / `layout` 来获得控制布局变化的所有权，我们稍后将展示使用方法。

最终，不管你是否用了自动布局，显示器都会自上而下将渲染后的视图传递到屏幕上，你也可以通过调用 `setNeedsDisplay` 来触发，这将会导致所有的调用都被合并到一起推迟重绘。重写熟悉的 `drawRect:`能够让我们获得自定义视图中显示过程的所有权。 

既然每一步都是依赖前一步操作的，如果有任何布局的变化还没实行的话，显示操作将会触发一个布局行为。类似地，如果约束条件系统中存在没有实行的改变，布局变化也将会触发更新约束条件。

需要牢记的是，这三步并不是单向的。基于约束条件的布局是一个迭代的过程，布局操作可以基于之前的布局方案来对约束做出更改，而这将再次触发约束的更新，并紧接另一个布局操作。这可以被用来创建高级的自定义视图布局，但是如果你每一次调用的自定义 `layoutSubviews` 都会导致另一个布局操作的话，你将会陷入到无限循环的麻烦中去。

## 为自定义视图启动自动布局

当创建一个自定义视图时，你需要知道关于自动布局的这些事情：具体指定一个恰当的固有内容尺寸 (intrinsic content size)，区分开视图的 frame 和 alignment rect，启动 baseline-aligned 布局，如何 hook 到布局过程中，我们将会逐一了解这些部分。

### 固有内容尺寸（Intrinsic Content Size ）

固有内容尺寸是一个视图期望为其显示特定内容得到的大小。比如，`UILabel` 有一个基于字体的首选高度，一个基于字体和显示文本的首选宽度。`UIProgressView` 仅有一个基于其插图的首选高度，但没有首选宽度。一个没有格式的 `UIView` 既没有首选宽度也没有首选高度。

你需要根据想要显示的内容来决定你的自定义视图是否具有一个固有内容尺寸，如果有的话，它是在哪个尺度上固有。

为了在自定义视图中实现固有内容尺寸，你需要做两件事：重写  [`intrinsicContentSize`][9] 为内容返回恰当的大小，无论何时有任何会影响固有内容尺寸的改变发生时，调用 [`invalidateIntrinsicContentSize`][10]。如果这个视图只有一个方向的尺寸设置了固有尺寸，那么为另一个方向的尺寸返回 `UIViewNoIntrinsicMetric` / `NSViewNoIntrinsicMetric`。

需要注意的是，固有内容尺寸必须是独立于视图 frame 的。例如，不可能返回一个基于 frame 高度或宽度的特定高宽比的固有内容尺寸。

### 压缩阻力 (Compression Resistance) 和 内容吸附 (Content Hugging)

> <p><span class="secondary radius label">译者注</span> 我理解为压缩阻力和内容吸附性，实在是想不到更贴切的名称了。压缩阻力是控制视图在两个方向上的收缩性，内容吸附性是当视图的大小改变时，它会尽量让视图靠近它的固有内容尺寸

每个视图在两个方向上都分配有内容压缩阻力优先级和内容吸附性优先级。只有当视图定义了固有内容尺寸时这些属性才能起作用，如果没有定义内容大小，那就没法阻止被压缩或者吸附了。

在后台中，固有内容尺寸和这些优先值被转换为约束条件。一个固有内容尺寸为 `{100，30}` 的 label，水平/垂直压缩阻力优先值为 `750`，水平/垂直的内容吸附性优先值为 `250`，这四个约束条件将会生成：

    H:[label(<=100@250)]
    H:[label(>=100@750)]
    V:[label(<=30@250)]
    V:[label(>=30@750)]

如果你不熟悉上面约束条件所使用的可视格式语言，你可以到 [Apple 文档][11] 中了解。记住，这些额外的约束条件对了解自动布局的行为产生了隐式的帮助，同时也更好理解它的错误信息。

### Frame 和 Alignment Rect

自动布局并不会操作视图的 frame，但能作用于视图的 alignment rect。大家很容易忘记它们之间细微的差别，因为在很多情况下，它们是相同的。但是alignment rect 实际上是一个强大的新概念：从一个视图的视觉外观解耦出视图的 layout alignment edges。

比如，一个自定义 icon 类型的按钮比我们期望点击目标还要小的时候，这将会很难布局。当插图显示在一个更大的 frame 中时，我们将不得不了解它显示的大小，并且相应调整按钮的 frame，这样 icon 才会和其他界面元素排列好。当我们想要在内容的周围绘制像 badges，阴影，倒影的装饰时，也会发生同样的情况。

我们可以使用 alignment rect 简单的定义需要用来布局的矩形。在大多数情况下，你仅需要重写 [`alignmentRectInsets`][12] 方法，这个方法允许你返回相对于 frame 的 edge insets。如果你需要更多控制权，你可以重写 [`alignmentRectForFrame:`][13] 和 [`frameForAlignmentRect:`][14]。如果你不想减去固定的 insets，而是计算基于当前 frame 的 alignment rect，那么这两个方法将会非常有用。但是你需要确保这两个方法是互为可逆的。

关于这点，回忆上面提及到的视图固有内容尺寸引用它的 alignment rect，而不是 frame。这是有道理的，因为自动布局直接根据固有内容尺寸产生压缩阻力和内容吸附约束条件。

### 基线对齐 (Baseline Alignment)

为了让使用 `NSLayoutAttributeBaseline` 属性的约束条件对自定义视图奏效，我们需要做一些额外的工作。当然，这只有我们讨论的自定义视图中有类似基准线的东西时，才有意义。

在 iOS 中，可以通过实现 [`viewForBaselineLayout`][15] 来激活基线对齐。在这里返回的视图底边缘将会作为 基线。默认实现只是简单的返回自己，然而自定义的实现可以返回任何子视图。在 OS X 中，你不需要返回一个子视图，而是重新定义 [`baselineOffsetFromBottom`][16] 返回一个从视图底部边缘开始的 offset，这和在 iOS 中一样，默认实现都是返回 0。

### 控制布局

在自定义视图中，你能完全控制它子视图的布局。你可以增加本地约束；根据内容变化需要，你可以改变本地约束；你可以为子视图调整布局操作的结果；或者你可以选择抛弃自动布局。

但确保你明智的使用这个权利。大多数情况下可以简单地通过为你的子视图简单的增加本地约束来处理。

#### 本地约束

如果我们想用几个子视图组成一个自定义视图，我们需要以某种方式布局这些子视图。在自动布局的环境中，自然会想到为这些视图增加本地约束。然而，需要注意的是，这将会使你自定义的视图是基于自动布局的，这个视图不能再被使用于未启用自动布局的 windows 中。最好通过实现 [`requiresConstraintBasedLayout`][17] 返回 YES 明确这个依赖。

添加本地约束的地方是 [`updateConstraints`][18]。确保在你的实现中增加任何你需要布局子视图的约束条件**之后**，调用一下 `[super updateConstraints]`。在这个方法中，你不会被允许禁用何约束条件，因为你已经进入上面所描述的[布局过程](#layout-process)的第一步了。如果尝试着这样做，将会产生一个友好的错误信息 “programming error”。

如果稍后一个失效的约束条件发生了改变的话，你需要立刻移除这个约束并调用 [`setNeedsUpdateConstraints`][19]。事实上，仅在这种情况下你需要触发更新约束条件的操作。

#### 控制子视图布局

如果你不能利用布局约束条件达到子视图预期的布局，你可以进一步在 iOS 里重写 [`layoutSubviews`][20] 或者在 OS X 里面重写 [`layout`][21]。通过这种方式，当约束条件系统得到解决并且结果将要被应用到视图中时，你便已经进入到[布局过程](#layout-process)的第二步。

最极端的情况是不调用父类的实现，自己重写全部的 `layoutSubviews / layout`。这就意味着你在这个视图里的视图树里抛弃了自动布局。从现在起，你可以按喜欢的方式手动放置子视图。

如果你仍然想使用约束条件布局子视图，你需要调用 `[super layoutSubviews]` / `[super layout]`，然后对布局进行微调。你可以通过这种方式创建那些通过定于约束无法实现的布，比如，由到视图大小之间的关系或是视图之间间距的关系来定义的布局。

这方面另一个有趣的使用案例就是创建一个布局依赖的视图树。当自动布局完成第一次传递并且为自定义视图的子视图设置好 frame 后，你便可以检查子视图的位置和大小，并为视图层级和（或）约束条件做出调整。[WWDC session 228 – Best Practices for Mastering Auto Layout][5] 有一个很好的例子。

你也可以在第一次布局操作完成后再决定改变约束条件。比如，如果视图变得太窄的话，将原来排成一行的子视图转变成两行。

    - layoutSubviews
    {
        [super layoutSubviews];
        if (self.subviews[0].frame.size.width <= MINIMUM_WIDTH)
        {
            [self removeSubviewConstraints];
            self.layoutRows += 1; [super layoutSubviews];
        }
    }

    - updateConstraints
    {
        // 根据 self.layoutRows 添加约束...
        [super updateConstraints];
    }

## 多行文本的固有内容尺寸

`UILabel` 和 `NSTextField` 对于多行文本的固有内容尺寸是模糊不清的。文本的高度取决于行的宽度，这也是解决约束条件时需要弄清的问题。为了解决这个问题，这两个类都有一个叫做 [`preferredMaxLayoutWidth`](http://developer.apple.com/library/ios/documentation/uikit/reference/UILabel_Class/Reference/UILabel.html#//apple_ref/occ/instp/UILabel/preferredMaxLayoutWidth) 的新属性，这个属性指定了行宽度的最大值，以便计算固有内容尺寸。

因为我们通常不能提前知道这个值，为了获得正确的值我们需要先做两步操作。首先，我们让自动布局做它的工作，然后用布局操作结果的 frame 更新给首选最大宽度，并且再次触发布局。

    - (void)layoutSubviews
    {
        [super layoutSubviews];
        myLabel.preferredMaxLayoutWidth = myLabel.frame.size.width;
        [super layoutSubviews];
    }

第一次调用 `[super layoutSubviews]` 是为了获得 label 的 frame，而第二次调用是为了改变后更新布局。如果省略第二个调用我们将会得到一个 `NSInternalInconsistencyException` 的错误，因为我们改变了更新约束条件的布局操作，但我们并没有再次触发布局。

我们也可以在 label 子类本身中这样做：

    @implementation MyLabel
    - (void)layoutSubviews
    {
        self.preferredMaxLayoutWidth = self.frame.size.width;
        [super layoutSubviews];
    }
    @end

在这种情况下，我们不需要先调用 `[super layoutSubviews]`，因为当 `layoutSubviews` 被调用时，label 就已经有一个 frame 了。

为了在视图控制器层级做出这样的调整，我们用挂钩到 viewDidLayoutSubviews。这时候第一个自动布局操作的 frame 已经被设置，我们可以用它们来设置首选最大宽度。

    - (void)viewDidLayoutSubviews
    {
        [super viewDidLayoutSubviews];
        myLabel.preferredMaxLayoutWidth = myLabel.frame.size.width;
        [self.view layoutIfNeeded];
    }

最后，确保你没有给 label 设置一个比 label 内容压缩阻力优先级还要高的具体高度约束。否则它将会取代根据内容计算出的高度。

## 动画

说到根据自动布局的视图动画，有两个不同的基本策略：约束条件自身动态化；以及改变约束条件重新计算 frame，并使用 Core Animation 将 frame 插入到新旧位置之间。

这两种处理方法不同的是：约束条件自身动态化产生的布局结果总是符合约束条件系统。与此相反，使用 Core Animation 插入值到新旧 frame 之间会临时违反约束条件。

直接使用约束条件动态化只是在 OS X 上的一种可行策略，并且这对你能使用的动画有局限性，因为约束条件一旦创建后，只有其常量可以被改变。在 OS X 中你可以在约束条件的常量中使用动画代理来驱动动画，而在 iOS 中，你只能手动进行控制。另外，这种方法明显比 Core Animation 方法慢得多，这也使得它暂时不适合移动平台。

当使用 Core Animation 方法时，即使不使用自动布局，动画的工作方式在概念上也是一样的。不同的是，你不需要手动设置视图的目标 frames，取而代之的是修改约束条件并触发一个布局操作为你设置 frames。在 iOS 中，代替：

    [UIView animateWithDuration:1 animations:^{
        myView.frame = newFrame;
    }];

你现在需要写：

    // 更新约束
    [UIView animateWithDuration:1 animations:^{
        [myView layoutIfNeeded];
    }];

请注意，使用这种方法，你可以对约束条件做出的改变并不局限于约束条件的常量。你可以删除约束条件，增加约束条件，甚至使用临时动画约束条件。由于新的约束只被解释一次来决定新的 frames，所以更复杂的布局改变都是有可能的。

需要记住的是：Core Animation 和 Auto Layout 结合在一起产生视图动画时，自己不要接触视图的 frame。一旦视图使用自动布局，那么你已经将设置 frame 的责任交给了布局系统。你的干扰将造成怪异的行为。

这也意味着，如果使用的视图变换 (transform) 改变了视图的 frame 的话，它和自动布局是无法一起正常使用的。考虑下面这个例子：

    [UIView animateWithDuration:1 animations:^{
        myView.transform = CGAffineTransformMakeScale(.5, .5);
    }];

通常我们期望这个方法在保持视图的中心时，将它的大小缩小到原来的一半。但是自动布局的行为是根据我们建立的约束条件种类来放置视图的。如果我们将其居中于它的父视图，结果便像我们预想的一样，因为应用视图变换会触发一个在父视图内居中新 frame 的布局操作。然而，如果我们将视图的左边缘对齐到另一个视图，那么这个 alignment 将会粘连住，并且中心点将会移动。

不管怎么样，即使最初的结果跟我们预想的一样，像这样通过约束条件将转换应用到视图布局上并不是一个好主意。视图的 frame 没有和约束条件同步，也将导致怪异的行为。

如果你想使用 transform 来产生视图动画或者直接使它的 frame 动态化，最干净利索的技术是将这个视图嵌入到一个视图容器内，然后你可以在容器内重写 layoutSubviews，要么选择完全脱离自动布局，要么仅仅调整它的结果。举个例子，如果我们在我们的容器内建立一个子视图，它根据容器的顶部和左边缘自动布局，当布局根据以上的设置缩放转换后我们可以调整它的中心：

    - (void)layoutSubviews
    {
        [super layoutSubviews];
        static CGPoint center = {0,0};
        if (CGPointEqualToPoint(center, CGPointZero)) {
            // 在初次布局后获取中心点
            center = self.animatedView.center;
        } else {
            // 将中心点赋回给动画视图
            self.animatedView.center = center;
        }
    }

如果我们将 animatedView 属性暴露为 IBOutlet，我们甚至可以使用 Interface Builder 里面的容器，并且使用约束条件放置它的的子视图，同时还能够根据固定的中心应用缩放转换。

## 调试

当谈到调试自动布局，OS X 比 iOS 还有一个重要的优势。在 OS X 中，你可以利用 Instrument 的 Cocoa Layout 模板，或者是 `NSWindow` 的 [visualizeConstraints:][23] 方法。而且 `NSView` 有一个 [identifier][24] 属性，为了获得更多可读的自动布局错误信息，你可以在 Interface Builder 或代码里面设置这个属性。

### 不可满足的约束条件

如果我们在 iOS 中遇到不可满足的约束条件，我们只能在输出的日志中看到视图的内存地址。尤其是在更复杂的布局中，有时很难辨别出视图的哪一部分出了问题。然而，在这种情况下，还有几种方法可以帮到我们。

首先，当你在不可满足的约束条件错误信息中看到 `NSLayoutResizingMaskConstraints` 时，你肯定忘了为你某一个视图设定 `translatesAutoResizingMaskIntoConstraints` 为 NO。Interface Builder 中会自动设置，但是使用代码时，你需要为所有的视图手动设置。

如果不是很明确是哪个视图导致的问题，你就需要通过内存地址来辨认视图。最简单的方法是使用调试控制台。你可以打印视图本身或它父视图的描述，甚至递归描述的树视图。这通常会提示你需要处理哪个视图。

    (lldb) po 0x7731880
    $0 = 124983424 <UIView: 0x7731880; frame = (90 -50; 80 100); 
    layer = <CALayer: 0x7731450>>

    (lldb) po [0x7731880 superview]
    $2 = 0x07730fe0 <UIView: 0x7730fe0; frame = (32 128; 259 604); 
    layer = <CALayer: 0x7731150>>

    (lldb) po [[0x7731880 superview] recursiveDescription]
    $3 = 0x07117ac0 <UIView: 0x7730fe0; frame = (32 128; 259 604); layer = <CALayer: 0x7731150>>
       | <UIView: 0x7731880; frame = (90 -50; 80 100); layer = <CALayer: 0x7731450>>
       | <UIView: 0x7731aa0; frame = (90 101; 80 100); layer = <CALayer: 0x7731c60>>

一个更直观的方法是在控制台修改有问题的视图，这样你可以在屏幕上标注出来。比如，你可以改变它的背景颜色：

    (lldb) expr ((UIView *)0x7731880).backgroundColor = [UIColor purpleColor]

确保重新执行你的程序，否则改变不会在屏幕上显示出来。还要注意将内存地址转换为 `(UIView *)` ，以及额外的圆括号，这样我们就可以使用点操作。另外，你当然也可以通过发送消息来实现：

    (lldb) expr [(UIView *)0x7731880 setBackgroundColor:[UIColor purpleColor]]

另一种方法是使用 Instrument 的 allocation 模板，根据图表分析。一旦你从错误消息中得到内存地址（运行 Instruments 时，你从 Console 应用中获得的错误消息），你可以将 Instrument 的详细视图切换到 Objects List 页面，并且用 Cmd-F 搜索那个内存地址。这将会为你显示分配视图对象的方法，这通常是一个很好的暗示（至少对那些由代码创建的视图来说是这样的）。

你也可以通过改进错误信息本身，来更容易地在 iOS 中弄懂不可满足的约束条件错误到底在哪里。我们可以在一个 category 中重写 `NSLayoutConstraint` 的描述，并且将视图的 tags 包含进去：

    @implementation NSLayoutConstraint (AutoLayoutDebugging)
    #ifdef DEBUG
    - (NSString *)description
    {
        NSString *description = super.description;
        NSString *asciiArtDescription = self.asciiArtDescription;
        return [description stringByAppendingFormat:@" %@ (%@, %@)", 
            asciiArtDescription, [self.firstItem tag], [self.secondItem tag]];
    }
    #endif
    @end

如果整数的 `tag` 属性信息不够的话，我们还可以得到更多新奇的东西，并且在视图类中增加我们自己命名的属性，然后可以打印到错误消息中。我们甚至可以在 Interface Builder 中，使用 identity 检查器中的 “User Defined Runtime Attributes” 为自定义属性分配值。

    @interface UIView (AutoLayoutDebugging)
    - (void)setAbc_NameTag:(NSString *)nameTag;
    - (NSString *)abc_nameTag;
    @end

    @implementation UIView (AutoLayoutDebugging)
    - (void)setAbc_NameTag:(NSString *)nameTag
    {
        objc_setAssociatedObject(self, "abc_nameTag", nameTag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    - (NSString *)abc_nameTag
    {
        return objc_getAssociatedObject(self, "abc_nameTag");
    }
    @end

    @implementation NSLayoutConstraint (AutoLayoutDebugging)
    #ifdef DEBUG
    - (NSString *)description
    {
        NSString *description = super.description;
        NSString *asciiArtDescription = self.asciiArtDescription;
        return [description stringByAppendingFormat:@" %@ (%@, %@)", asciiArtDescription, [self.firstItem abc_nameTag], [self.secondItem abc_nameTag]];
    }
    #endif
    @end

通过这种方法错误消息变得更可读，并且你不需要找出内存地址对应的视图。然而，对你而言，你需要做一些额外的工作以确保每次为视图分配的名字都是有意义。

[Daniel][25] 提出了另一个很巧妙的方法，可以为你提供更好的错误消息并且不需要额外的工作：对于每个布局约束条件，都需要将调用栈的标志融入到错误消息中。这样就很容易看出来问题涉及到的约束了。要做到这一点，你需要 swizzle UIView 或者 NSView 的 `addConstraint:` / `addConstraints:` 方法，以及布局约束的 `description` 方法。在添加约束的方法中，你需要为每个约束条件关联一个对象，这个对象描述了当前调用栈堆栈的第一个栈顶信息（或者任何你从中得到的信息）：

    static void AddTracebackToConstraints(NSArray *constraints)
    {
        NSArray *a = [NSThread callStackSymbols];
        NSString *symbol = nil;
        if (2 < [a count]) {
            NSString *line = a[2];
            // Format is
            //               1         2         3         4         5
            //     012345678901234567890123456789012345678901234567890123456789
            //     8   MyCoolApp                           0x0000000100029809 -[MyViewController loadView] + 99
            //
            // Don't add if this wasn't called from "MyCoolApp":
            if (59 <= [line length]) {
                line = [line substringFromIndex:4];
                if ([line hasPrefix:@"My"]) {
                    symbol = [line substringFromIndex:59 - 4];
                }
            }
        }
        for (NSLayoutConstraint *c in constraints) {
            if (symbol != nil) {
                objc_setAssociatedObject(c, &ObjcioLayoutConstraintDebuggingShort, 
                    symbol, OBJC_ASSOCIATION_COPY_NONATOMIC);
            }
            objc_setAssociatedObject(c, &ObjcioLayoutConstraintDebuggingCallStackSymbols, 
                a, OBJC_ASSOCIATION_COPY_NONATOMIC);
        }
    }

    @end
        

一旦你为每个约束对象提供这些信息，你可以简单的修改 `UILayoutConstraint` 的描述方法将其包含到输出日志中。

    - (NSString *)objcioOverride_description {
        // call through to the original, really
        NSString *description = [self objcioOverride_description];
        NSString *objcioTag = objc_getAssociatedObject(self, &ObjcioLayoutConstraintDebuggingShort);
        if (objcioTag == nil) {
            return description;
        }
        return [description stringByAppendingFormat:@" %@", objcioTag];
    }

检出这个[GitHub][26]仓库，了解这一技术的代码示例。

### 有歧义的布局

另一个常见的问题就是有歧义的布局。如果我们忘记添加一个约束条件，我们经常会想为什么布局看起来不像我们所期望的那样。`UIView` 和 `NSView` 提供三种方式来查明有歧义的布局：[`hasAmbiguousLayout`][27]，[`exerciseAmbiguityInLayout`][28]，和私有方法 `_autolayoutTrace`。

顾名思义，如果视图存在有歧义的布局，那么 `hasAmbiguousLayout` 返回YES。如果我们不想自己遍历视图层并记录这个值，可以使用私有方法 _autolayoutTrace。这将返回一个描述整个视图树的字符串：类似于 [`recursiveDescription`][37] 的输出（当视图存在有歧义的布局时，这个方法会告诉你）。

由于这个方法是私有的，确保正式产品里面不要包含调用这个方法的任何代码。为了防止你犯这种错误，你可以在视图的category中这样做：

    @implementation UIView (AutoLayoutDebugging)
    - (void)printAutoLayoutTrace {
        #ifdef DEBUG
        NSLog(@"%@", [self performSelector:@selector(_autolayoutTrace)]);
        #endif
    }
    @end
    
`_autolayoutTrace` 打印的结果如下：

	2013-07-23 17:36:08.920 FlexibleLayout[4237:907] 
	*<UIWindow:0x7269010>
	|   *<UILayoutContainerView:0x7381250>
	|   |   *<UITransitionView:0x737c4d0>
	|   |   |   *<UIViewControllerWrapperView:0x7271e20>
	|   |   |   |   *<UIView:0x7267c70>
	|   |   |   |   |   *<UIView:0x7270420> - AMBIGUOUS LAYOUT
	|   |   <UITabBar:0x726d440>
	|   |   |   <_UITabBarBackgroundView:0x7272530>
	|   |   |   <UITabBarButton:0x726e880>
	|   |   |   |   <UITabBarSwappableImageView:0x7270da0>
	|   |   |   |   <UITabBarButtonLabel:0x726dcb0>

正如不可满足约束条件的错误消息一样，我们仍然需要弄明白打印出的内存地址所对应的视图。

另一个标识出有歧义布局更直观的方法就是使用 `exerciseAmbiguityInLayout`。这将会在有效值之间随机改变视图的 frame。然而，每次调用这个方法只会改变 frame 一次。所以当你启动程序的时候，你根本不会看到改变。创建一个遍历所有视图层级的辅助方法是一个不错的主意，并且让所有包含歧义布局的视图“晃动 (jiggle)”。


    @implementation UIView (AutoLayoutDebugging)
    - (void)exerciseAmiguityInLayoutRepeatedly:(BOOL)recursive {
        #ifdef DEBUG
        if (self.hasAmbiguousLayout) {
            [NSTimer scheduledTimerWithTimeInterval:.5
                                         target:self
                                       selector:@selector(exerciseAmbiguityInLayout)
                                       userInfo:nil
                                        repeats:YES];
        }
        if (recursive) {
            for (UIView *subview in self.subviews) {
                [subview exerciseAmbiguityInLayoutRepeatedly:YES];
            }
        }
        #endif
    } @end
    
### NSUserDefault选项

有几个有用的 `NSUserDefault` 选项可以帮助我们调试、测试自动布局。你可以在[代码中][29]设定，或者你也可以在 [scheme editor][30] 中指定它们作为启动参数。

顾名思义，`UIViewShowAlignmentRects`和 `NSViewShowAlignmentRects` 设置视图可见的 alignment rects。`NSDoubleLocalizedStrings` 简单的获取并复制每个本地化的字符串。这是一个测试更长语言布局的好方法。最后，设置 `AppleTextDirection` 和 `NSForceRightToLeftWritingDirection` 为 `YES`，来模拟从右到左的语言。

> <p><span class="secondary radius label">编者注</span> 如果你不知道怎么在 scheme 中设置类似 `NSDoubleLocalizedStrings`，这里有一张图来说明；

> ![pic][31]

## 约束条件代码

当在代码中设置视图和它们的约束条件时候，一定要记得将 [`translatesAutoResizingMaskIntoConstraints`][32] 设置为 NO。如果忘记设置这个属性几乎肯定会导致不可满足的约束条件错误。即使你已经用自动布局一段时间了，但还是要小心这个问题，因为很容易在不经意间发生产生这个错误。

当你使用 [可视化结构语言 (visual format language, VFL)][33] 设置约束条件时， `constraintsWithVisualFormat:options:metrics:views:` 方法有一个很有用的 `option` 参数。如果你还没有用过，请参见文档。这不同于格式化字符串只能影响一个视图，它允许你调整在一定范围内的视图。举个例子，如果用可视格式语言指定水平布局，那么你可以使用 `NSLayoutFormatAlignAllTop` 排列可视语言里所有视图为上边缘对齐。

还有一个使用可视格式语言在父视图中居中子视图的小技巧，这技巧利用了不均等约束和可选参数。下面的代码在父视图中水平排列了一个视图：

    UIView *superview = theSuperView;
    NSDictionary *views = NSDictionaryOfVariableBindings(superview, subview);
    NSArray *c = [NSLayoutConstraint 
                    constraintsWithVisualFormat:@"V:[superview]-(<=1)-[subview]"]
                                        options:NSLayoutFormatAlignAllCenterX
                                        metrics:nil
                                          views:views];
    [superview addConstraints:c];

这利用了 `NSLayoutFormatAlignAllCenterX` 选项在父视图和子视图间创建了居中约束。格式化字符串本身只是一个虚拟的东西，它会产生一个指定的约束，通常情况下只要子视图是可见的，那么父视图底部和子视图顶部边缘之间的空间就应该小于等于1点。你可以颠倒示例中的方向达到垂直居中的效果。

使用可视格式语言另一个方便的辅助方法就是我们在上面例子中已经使用过的 NSDictionaryFromVariableBindings 宏指令，你传递一个可变数量的变量过去，返回得到一个键为变量名的字典。

为了布局任务，你需要一遍一遍的调试，你可以方便的创建自己的辅助方法。比如，你想要垂直地排列一系列视图，想要它们垂直方向间距一致，水平方向上所有视图以它们的左边缘对齐，用下面的方法将会方便很多：

    @implementation UIView (AutoLayoutHelpers)
    + leftAlignAndVerticallySpaceOutViews:(NSArray *)views 
                                 distance:(CGFloat)distance 
    {
        for (NSUInteger i = 1; i < views.count; i++) {
            UIView *firstView = views[i - 1];
            UIView *secondView = views[i];
            firstView.translatesAutoResizingMaskIntoConstraints = NO;
            secondView.translatesAutoResizingMaskIntoConstraints = NO;

            NSLayoutConstraint *c1 = constraintWithItem:firstView
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:secondView
                                              attribute:NSLayoutAttributeTop
                                             multiplier:1
                                               constant:distance];
                                               
            NSLayoutConstraint *c2 = constraintWithItem:firstView
                                              attribute:NSLayoutAttributeLeading
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:secondView
                                              attribute:NSLayoutAttributeLeading
                                             multiplier:1
                                               constant:0];
                                                   
            [firstView.superview addConstraints:@[c1, c2]];
        }
    }
    @end
    
同时也有许多不同的自动布局的库采用了不同的方法来简化约束条件代码。

## 性能

自动布局是布局过程中额外的一个步骤。它需要一组约束条件，并把这些约束条件转换成 frame。因此这自然会产生一些性能的影响。你需要知道的是，在绝大数情况下，用来解决约束条件系统的时间是可以忽略不计的。但是如果你正好在处理一些性能关键的视图代码时，最好还是对这一点有所了解。

例如，有一个 collection view，当新出现一行时，你需要在屏幕上呈现几个新的 cell，并且每个 cell 包含几个基于自动布局的子视图，这时你需要注意你的性能了。幸运的是，我们不需要用直觉来感受上下滚动的性能。启动 Instruments 真实的测量一下自动布局消耗的时间。当心 `NSISEngine` 类的方法。

另一种情况就是当你一次显示大量视图时可能会有性能问题。将约束条件转换成视图的 frame 时，用来[计算约束的算法][38]是[超线性复杂][36]的。这意味着当有一定数量的视图时，性能将会变得非常低下。而这确切的数目取决于你具体使用情况和视图配置。但是，给你一个粗略的概念，在当前 iOS 设备下，这个数字大概是 100。你可以读这两个[博客][34][帖子][35]了解更多的细节。

记住，这些都是极端的情况，不要过早的优化，并且避免自动布局潜在的性能影响。这样大多数情况便不会有问题。但是如果你怀疑这花费了你决定性的几十毫秒，从而导致用户界面不完全流畅的话，分析你的代码，然后你再去考虑用回手动设置 frame 有没有意义。此外，硬件将会变得越来越能干，并且Apple也会继续调整自动布局的性能。所以现实世界中极端情况的性能问题也将随着时间减少。

## 结论

自动布局是一个创建灵活用户界面的强大功能，这种技术不会消失。刚开始使用自动布局时可能会有点困难，但总会有柳暗花明的一天。一旦你掌握了这种技术，并且掌握了排错的小技巧，便可庖丁解牛，恍然大悟：这太符合逻辑了。

  [1]: http://bcs.duapp.com/answerhuang/blog/horizontal.png
  [2]: http://bcs.duapp.com/answerhuang/blog/vertical.png
  [3]: http://www.raywenderlich.com/20897/beginning-auto-layout-part-2-of-2
  [4]: http://weibo.com/n/onevcat
  [5]: http://onevcat.com/2012/09/autoayout/
  [6]: https://developer.apple.com/videos/wwdc/2012/?id=202
  [7]: https://developer.apple.com/videos/wwdc/2012/?id=228
  [8]: https://developer.apple.com/videos/wwdc/2012/?id=232
  [9]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSView_Class/Reference/NSView.html#//apple_ref/occ/instm/NSView/intrinsicContentSize
  [10]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSView_Class/Reference/NSView.html#//apple_ref/occ/instm/NSView/invalidateIntrinsicContentSize
  [11]: https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/AutolayoutPG/VisualFormatLanguage/VisualFormatLanguage.html
  [12]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSView_Class/Reference/NSView.html#//apple_ref/occ/instm/NSView/alignmentRectInsets
  [13]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSView_Class/Reference/NSView.html#//apple_ref/occ/instm/NSView/alignmentRectForFrame:
  [14]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSView_Class/Reference/NSView.html#//apple_ref/occ/instm/NSView/frameForAlignmentRect:
  [15]: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/UIView/UIView.html
  [16]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSView_Class/Reference/NSView.html#//apple_ref/occ/instm/NSView/baselineOffsetFromBottom
  [17]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSView_Class/Reference/NSView.html#//apple_ref/occ/clm/NSView/requiresConstraintBasedLayout
  [18]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSView_Class/Reference/NSView.html#//apple_ref/occ/instm/NSView/updateConstraints
  [19]: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/UIView/UIView.html
  [20]: http://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/UIView/UIView.html#//apple_ref/occ/instm/UIView/layoutSubviews
  [21]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSView_Class/Reference/NSView.html#//apple_ref/occ/instm/NSView/layout
  [23]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSWindow_Class/Reference/Reference.html#//apple_ref/occ/instm/NSWindow/visualizeConstraints:
  [24]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSUserInterfaceItemIdentification_Protocol/Introduction/Introduction.html#//apple_ref/occ/intfp/NSUserInterfaceItemIdentification/identifier
  [25]: https://twitter.com/danielboedewadt
  [26]: https://github.com/objcio/issue-3-auto-layout-debugging
  [27]: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/UIView/UIView.html#//apple_ref/occ/instm/UIView/hasAmbiguousLayout
  [28]: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/UIView/UIView.html#//apple_ref/occ/instm/UIView/exerciseAmbiguityInLayout
  [29]: http://stackoverflow.com/questions/11721656/how-to-set-nsconstraintbasedlayoutvisualizemutuallyexclusiveconstraints/13044693#13044693
  [30]: http://stackoverflow.com/questions/11721656/how-to-set-nsconstraintbasedlayoutvisualizemutuallyexclusiveconstraints/13138933#13138933
  [31]: /images/issues/issue-3/NSDoubleLocalizedStrings.png
  [32]: http://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/UIView/UIView.html#//apple_ref/occ/instm/UIView/translatesAutoresizingMaskIntoConstraints
  [33]: http://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/UIView/UIView.html#//apple_ref/occ/instm/UIView/translatesAutoresizingMaskIntoConstraints
  [34]: http://floriankugler.com/blog/2013/4/21/auto-layout-performance-on-ios
  [35]: http://pilky.me/36/
  [36]: http://zh.wikipedia.org/wiki/P_(%E8%A4%87%E9%9B%9C%E5%BA%A6)
  [37]: http://developer.apple.com/library/ios/#technotes/tn2239/_index.html#//apple_ref/doc/uid/DTS40010638-CH1-SUBSECTION34
  [38]: ttp://www.cs.washington.edu/research/constraints/cassowary/

---

 

原文 [Advanced Auto Layout Toolbox](http://www.objc.io/issue-3/advanced-auto-layout-toolbox.html)
   
译文 [先进的自动布局工具箱 - answer-huang](http://answerhuang.duapp.com/index.php/2013/10/11/advanced-auto-layout-toolbox/)
