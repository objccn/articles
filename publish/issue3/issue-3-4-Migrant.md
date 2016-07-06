本文将讨论一些自定义视图、控件的诀窍和技巧。我们先概述一下 UIKit 向我们提供的控件，并介绍一些渲染技巧。随后我们会深入到视图和其所有者之间的通信策略，并简略探讨辅助功能，本地化和测试。

## 视图层次概览

如果你观察一下 UIView 的子类，可以发现 3 个基类: `reponders` (响应者)，`views` (视图)和 `controls` (控件)。我们快速重温一下它们之间发生了什么。

### UIResponder

`UIResponder` 是 `UIView` 的父类。`responder` 能够处理触摸、手势、远程控制等事件。之所以它是一个单独的类而没有合并到 `UIView` 中，是因为 `UIResponder` 有更多的子类，最明显的就是 `UIApplication` 和 `UIViewController`。通过重写 `UIResponder` 的方法，可以决定一个类是否可以成为第一响应者 (first responder)，例如当前输入焦点元素。

当 touches (触摸) 或 motion (指一系列运动传感器) 等交互行为发生时，它们被发送给第一响应者 (通常是一个视图)。如果第一响应者没有处理，则该行为沿着响应链到达视图控制器，如果行为仍然没有被处理，则继续传递给应用。如果想监测晃动手势，可以根据需要在这3层中的任意位置处理。

`UIResponder` 还允许自定义输入方法，从 `inputAccessoryView` 向键盘添加辅助视图到使用 `inputView` 提供一个完全自定义的键盘。

### UIView

`UIView` 子类处理所有跟内容绘制有关的事情以及触摸时间。只要写过 "Hello, World" 应用的人都知道视图，但我们重申一些技巧点:

一个普遍错误的概念：视图的区域是由它的 frame 定义的。实际上 frame 是一个派生属性，是由 `center` 和 `bounds` 合成而来。不使用 Auto Layout 时，大多数人使用 frame 来改变视图的位置和大小。小心些，[官方文档][1]特别详细说明了一个注意事项:

> 如果 transform 属性不是 identity transform 的话，那么这个属性的值是未定义的，因此应该将其忽略

另一个允许向视图添加交互的方法是使用手势识别。注意它们对 responders 并不起作用，而只对视图及其子类奏效。

### UIControl

`UIControl` 建立在视图上，增加了更多的交互支持。最重要的是，它增加了 target / action 模式。看一下具体的子类，我们可以看一下按钮，日期选择器 (Date pickers)，文本框等等。创建交互控件时，你通常想要子类化一个 `UIControl`。一些常见的像 bar buttons (虽然也支持 target / action) 和 text view (这里需要你使用代理来获得通知) 的类其实并不是 `UIControl`。

## 渲染

现在，我们转向可见部分：自定义渲染。正如 Daniel 在他的[文章][2]中提到的，你可能想避免在 CPU 上做渲染而将其丢给 GPU。这里有一条经验：尽量避免 `drawRect:`，使用现有的视图构建自定义视图。

通常最快速的渲染方法是使用图片视图。例如，假设你想画一个带有边框的圆形头像，像下面图片中这样:

<img src="/images/issues/issue-3/issue-3-rounded-corners@2x.png" style="width:396px" alt="Rounded image view"/>

为了实现这个，我们用以下的代码创建了一个图片视图的子类:

    // called from initializer
    - (void)setupView
    {
        self.clipsToBounds = YES;
        self.layer.cornerRadius = self.bounds.size.width / 2;
        self.layer.borderWidth = 3;
        self.layer.borderColor = [UIColor darkGrayColor].CGColor;
    }
我鼓励各位读者深入了解 `CALayer` 及其属性，因为你用它能实现的大多数事情会比用 Core Graphics 自己画要快。然而一如既往，监测自己的代码的性能是十分重要的。

把可拉伸的图片和图片视图一起使用也可以极大的提高效率。在 [Taming UIButton][4] 这个帖子中，Reda Lemeden 探索了几种不同的绘图方法。在文章结尾处有一个很有价值的[来自 UIKit 团队的工程师 Andy Matuschak 的回复][5]，解释了可拉伸图片是这些技术中最快的。原因是可拉伸图片在 CPU 和 GPU 之间的数据转移量最小，并且这些图片的绘制是经过高度优化的。

处理图片时，你也可以让 GPU 为你工作来代替使用 Core Graphics。使用 Core Image，你不必用 CPU 做任何的工作就可以在图片上建立复杂的效果。你可以直接在 OpenGL 上下文上直接渲染，所有的工作都在 GPU 上完成。

### 自定义绘制

如果决定了采用自定义绘制，有几种不同的选项可供选择。如果可能的话，看看是否可以生成一张图片并在内存和磁盘上缓存起来。如果内容是动态的，也许你可以使用 Core Animation，如果还是行不通，使用 Core Graphics。如果你真的想要接近底层，使用 GLKit 和原生 OpenGL 也不是那么难，但是需要做很多工作。

如果你真的选择了重写 `drawRect:`，确保检查内容模式。默认的模式是将内容缩放以填充视图的范围，这在当视图的 frame 改变时并不会重新绘制。

## 自定义交互

正如之前所说的，自定义控件的时候，你几乎一定会扩展一个 UIControl 的子类。在你的子类里，可以使用 target action 机制触发事件，如下面的例子:

    [self sendActionsForControlEvents:UIControlEventValueChanged];


为了响应触摸，你可能更倾向于使用手势识别。然而如果想要更接近底层，仍然可以重写 `touchesBegan`， `touchesMoved` 和 `touchesEnded` 方法来访问原始的触摸行为。但虽说如此，创建一个手势识别的子类来把手势处理相关的逻辑从你的视图或者视图控制器中分离出来，在很多情况下都是一种更合适的方式。

创建自定义控件时所面对的一个普遍的设计问题是向拥有它们的类中回传返回值。比如，假设你创建了一个绘制交互饼状图的自定义控件，想知道用户何时选择了其中一个部分。你可以用很多种不同的方法来解决这个问题，比如通过 target action 模式，代理，block 或者 KVO，甚至通知。

### 使用 Target-Action

经典学院派的，通常也是最方便的做法是使用 target-action。在用户选择后你可以在自定义的视图中做类似这样的事情:

    [self sendActionsForControlEvents:UIControlEventValueChanged];

如果有一个视图控制器在管理这个视图，需要这样做:

    - (void)setupPieChart
    {
        [self.pieChart addTarget:self 
                      action:@selector(updateSelection:)
            forControlEvents:UIControlEventValueChanged];
    }
 
    - (void)updateSelection:(id)sender
    {
        NSLog(@"%@", self.pieChart.selectedSector);
    }


这么做的好处是在自定义视图子类中需要做的事情很少，并且自动获得多目标支持。

### 使用代理

如果你需要更多的控制从视图发送到视图控制器的消息，通常使用代理模式。在我们的饼状图中，代码看起来大概是这样:

    [self.delegate pieChart:self didSelectSector:self.selectedSector];

在视图控制器中，你要写如下代码:

    @interface MyViewController <PieChartDelegate>

     ...

    - (void)setupPieChart
    {
        self.pieChart.delegate = self;
    }
 
    - (void)pieChart:(PieChart*)pieChart didSelectSector:(PieChartSector*)sector
    {
        // 处理区块
    }

当你想要做更多复杂的工作而不仅仅是通知所有者值发生了变化时，这么做显然更合适。不过虽然大多数开发人员可以非常快速的实现自定义代理，但这种方式仍然有一些缺点：你必须检查代理是否实现了你想要调用的方法 (使用 `respondsToSelector:`)，最重要的，通常你只有一个代理 (或者需要创建一个代理数组)。也就是说，一旦视图所有者和视图之间的通信变得稍微复杂，我们几乎总是会采取这种模式。

### 使用 Block

另一个选择是使用 block。再一次用饼状图举例，代码看起来大概是这样:


    @interface PieChart : UIControl

    @property (nonatomic,copy) void(^selectionHandler)(PieChartSection* selectedSection);

    @end

在选取行为的代码中，你只需要执行它。在此之前检查一下block是否被赋值非常重要，因为执行一个未被赋值的 block 会使程序崩溃。

    if (self.selectionHandler != NULL) {
        self.selectionHandler(self.selectedSection);
    }

这种方法的好处是可以把相关的代码整合在视图控制器中:

    - (void)setupPieChart
    {
        self.pieChart.selectionHandler = ^(PieChartSection* section) {
            // 处理区块
        }
    }

就像代理，每个动作通常只有一个 block。另一个重要的限制是不要形成引用循环。如果你的视图控制器持有饼状图的强引用，饼状图持有 block，block 又持有视图控制器，就形成了一个引用循环。只要在 block 中引用 self 就会造成这个错误。所以通常代码会写成这个样子：

    __weak id weakSelf = self;
    self.pieChart.selectionHandler = ^(PieChartSection* section) {
        MyViewController* strongSelf = weakSelf;
        [strongSelf handleSectionChange:section];
    }

一旦 block 中的代码要失去控制 (比如 block 中要处理的事情太多，导致 block 中的代码过多)，你还应该将它们抽离成独立的方法，这种情况的话可能用代理会更好一些。

### 使用 KVO

如果喜欢 KVO，你也可以用它来观察。这有一点神奇而且没那么直接，但当应用中已经使用，它是很好的解耦设计模式。在饼状图类中，编写代码:


    self.selectedSegment = theNewSelectedSegment;

当使用合成属性，KVO 会拦截到该变化并发出通知。在视图控制器中，编写类似的代码:


    - (void)setupPieChart
    {
        [self.pieChart addObserver:self forKeyPath:@"selectedSegment" options:0 context:NULL];
    }

    - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
    {
        if(object == self.pieChart && [keyPath isEqualToString:@"selectedSegment"]) {
            // 处理改变
        }
    }

根据你的需要，在 `viewWillDisappear:` 或 `dealloc` 中，还需要移除观察者。对同一个对象设置多个观察者很容易造成混乱。有一些技术可以解决这个问题，比如 [ReactiveCocoa][6] 或者更轻量级的 [`THObserversAndBinders`][7]。

### 使用通知

作为最后一个选择，如果你想要一个非常松散的耦合，可以使用通知来使其他对象得知变化。对于饼状图来说你几乎肯定不想这样，不过为了讲解的完整，这里介绍如何去做。在饼状图的的头文件中：

    extern NSString* const SelectedSegmentChangedNotification;

在实现文件中：


    NSString* const SelectedSegmentChangedNotification = @"selectedSegmentChangedNotification";

    ...

    - (void)notifyAboutChanges
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:SelectedSegmentChangedNotification object:self];
    }

现在订阅通知，在视图控制器中：

    - (void)setupPieChart
    {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                           selector:@selector(segmentChanged:) 
                                               name:SelectedSegmentChangedNotification
                                              object:self.pieChart];

    }

    ...

    - (void)segmentChanged:(NSNotification*)note
    {
    }

当添加了观察者，你可以不将饼状图作为参数 `object`，而是传递 `nil`，以接收所有饼状图对象发出的通知。就像 KVO 通知，你也需要在恰当的地方退订这些通知。

这项技术的好处是完全的解耦。另一方面，你失去了类型安全，因为在回调中你得到的是一个通知对象，而不像代理，编译器无法检查通知发送者和接受者之间的类型是否匹配。

## 辅助功能 (Accessibility)

苹果官方提供的标准 iOS 控件均有辅助功能。这也是推荐用标准控件创建自定义控件的另一个原因。

这或许可以作为一整期的主题，但是如果你想编写自定义视图，[Accessibility Programming Guide][8] 说明了如何创建辅助控制器。最为值得注意的是，如果有一个视图中有多个需要辅助功能的元素，但它们并不是该视图的子视图，你可以让视图实现 `UIAccessibilityContainer` 协议。对于每一个元素，返回一个描述它的 `UIAccessibilityElement` 对象。

## 本地化

创建自定义视图时，本地化也同样重要。像辅助功能一样，这个可以作为一整期的话题。本地化自定义视图的最直接工作就是字符串内容。如果使用 `NSString`，你不必担心编码问题。如果在自定义视图中展示日期或数字，使用日期和数字格式化类来展示它们。使用 `NSLocalizedString` 本地化字符串。

另一个本地化过程中很有用的工具是 Auto Layout。例如，有在英文中很短的词在德语中可能会很长。如果根据英文单词的长度对视图的尺寸做硬编码，那么当翻译成德文的时候几乎一定会遇上麻烦。通过使用 Auto Layout，让标签控件自动调整为内容的尺寸，并向依赖元素添加一些其他的限制以确保重新设置尺寸，使这项工作变得非常简单。苹果为此提供了一个很好的 [介绍][9]。另外，对于类似希伯来语这种顺序从右到左的语言，如果你使用了 leading 和 trailing 属性，整个视图会自动按照从右到左的顺序展示，而不是硬编码的从左至右。

## 测试

最后，让我们考虑测试视图的问题。对于单元测试，你可以使用 Xcode 自带的工具或者其它第三方框架。另外，可以使用 UIAutomation 或者其它基于它的工具。为此，你的视图完全支持辅助功能是必要的。UIAutomation 并未充分得到利用的一个功能是截图；你可以用它[自动对比][10]视图和设计以确保两者每一个像素都分毫不差。(插一个无关的小提示：你还可以使用它来为应用上架 App Store [自动生成截图][11]，这在你有多个多国语言的应用时会特别有用)。

[1]: https://developer.apple.com/library/ios/#documentation/UIKit/Reference/UIView_Class/UIView/UIView.html#//apple_ref/occ/instp/UIView/frame
[2]: http://www.objccn.io/issue-3-1/
[3]: /images/issues/issue-3/issue-3-rounded-corners.png
[4]: http://robots.thoughtbot.com/post/33427366406/designing-for-ios-taming-uibutton
[5]: https://news.ycombinator.com/item?id=4645585
[6]: https://github.com/ReactiveCocoa/ReactiveCocoa
[7]: https://github.com/th-in-gs/THObserversAndBinders
[8]: http://developer.apple.com/library/ios/#documentation/UserExperience/Conceptual/iPhoneAccessibility/Accessibility_on_iPhone/Accessibility_on_iPhone.html#//apple_ref/doc/uid/TP40008785-CH100-SW3
[9]: http://developer.apple.com/library/ios/#referencelibrary/GettingStarted/RoadMapiOS/chapters/InternationalizeYourApp/InternationalizeYourApp/InternationalizeYourApp.html
[10]: http://jeffkreeftmeijer.com/2011/comparing-images-and-creating-image-diffs/
[11]: http://www.smallte.ch/blog-read_en_29001.html

---

 

原文 [Custom Controls](http://www.objc.io/issue-3/custom-controls.html)
   
译文 [自定义控件 - Migrant](http://objcio.com/blog/2014/03/10/custom-controls/)

校对 [answer-huang](http://answerhuang.duapp.com)