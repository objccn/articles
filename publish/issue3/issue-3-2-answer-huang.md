可能你很难相信 [UIScrollView][1] 和一个标准的 [UIView][2] 差异并不大，scroll view 确实会多出一些方法，但这些方法只是和 UIView 的属性很好的结合到一起了。因此，在要想弄懂 UIScrollView 是怎么工作之前，你需要先了解一下 UIView，特别是视图渲染的两步过程。

## 光栅化和组合

渲染过程的第一部分是众所周知的光栅化(`rasterization`)，光栅化简单的说就是产生一组绘图指令并且生成一张图片。比如绘制一个圆角矩形、带图片、标题居中的 UIButtons。这些图片并没有被绘制到屏幕上去；取而代之的是，他们被自己的视图保持着留到下一个步骤使用。

一旦每个视图都产生了自己的光栅化图片，这些图片便被一个接一个的绘制，并产生一个屏幕大小的图片，这便是上文所说的组合。视图层级(view hierarchy)对于组合如何进行扮演了很重要的角色：一个视图的图片被组合在它父视图的图片上面。然后，组合好的图片被组合到父视图的父视图图片上面。视图层级最顶端是窗口(window)，它组合好的图片便是我们看到的东西了。

概念上，依次在每个视图上放置独立分层的图片并最终产生一个图片，单调的图像更容易被理解，特别是如果你以前使用过像 Photoshop 这样的工具。我们还有另外一篇文章详细解释了[像素是如何绘制到屏幕上去的][3]。

现在，回想一下，每个视图都有一个 [bounds][8] 和 [frame][9]。当布局一个界面时，我们需要处理视图的 frame。这允许我们放置并设置视图的大小。视图的 frame 和 bounds 的大小通常是一样的（虽然可以被 transforms 改变），但是他们的 origin 经常是不同的。弄懂这两个工作原理是理解 UIScrollView 的关键。

在光栅化步骤中，视图并不关心即将发生的组合步骤。也就是说，它并不关心自己的 frame (这是用来放置视图的图像)或自己在视图层级中的位置(这是决定组合的顺序)。这时视图只关心一件事就是绘制它自己的 content。这个绘制发生在每个视图的 [`drawRect:`][10] 方法中。

在 `drawRect:` 方法被调用前，会为视图创建一个空白的图片来绘制 content。这个图片的坐标系统是视图的 bounds。几乎每个视图 bounds 的 origin 都是 {0，0}。因此，当在光栅化图片左上角绘制一些东西的时候，你都会在 bounds 的 origin {x:0, y:0} 处绘制。在一个图片右下角的地方绘制东西的时候，你都会绘制在 {x:width, y:height} 处。如果你的绘制超出了视图的 bounds，那么超出的部分就不属于光栅化图片的部分了，并且会被丢弃。

![][4]

在组合的步骤中，每个视图将自己光栅化图片组合到自己父视图的光栅化图片上面。视图的 frame 决定了自己在父视图中绘制的位置，frame 的 origin 表明了视图光栅化图片左上角相对父视图光栅化图片左上角的偏移量。所以，一个 origin 为 {x:20, y:15} 的 frame 所绘制的图片左边距其父视图 20 点，上边距父视图 15 点。因为视图的 frame 和 bounds 矩形的大小总是一样的，所以光栅化图片组合的时候是像素对齐的。这确保了光栅化图片不会被拉伸或缩小。

![][5]

记住，我们才仅仅讨论了一个视图和它父视图之间的组合操作。一旦这两个视图被组合到一起，组合的结果图片将会和父视图的父视图进行组合，这是一个雪球效应。

考虑一下组合图片背后的公式。视图图片的左上角会根据它 frame 的 origin 进行偏移，并绘制到父视图的图片上：

    CompositedPosition.x = View.frame.origin.x - Superview.bounds.origin.x;

    CompositedPosition.y = View.frame.origin.y - Superview.bounds.origin.y;

正如之前所说的，如果一个视图 bounds 的 origin 是 {0,0}。那么，我们得到这个公式：

    CompositedPosition.x = View.frame.origin.x;

    CompositedPosition.y = View.frame.origin.y;
    
我们可以通过几个不同的 frames 看一下：

![][6]

这样做是有道理的，我们改变 button 的 `frame.origin `后，它会改变自己相对紫色父视图的位置。注意，如果我们移动 button 直到它的一部分已经在紫色父视图 bounds 的外面，当光栅化图片被截去时这部分也将会通过同样的绘制方式被截去。然而，技术上讲，因为 iOS 处理组合方法的原因，你可以将一个子视图渲染在其父视图的 bounds 之外，但是光栅化期间的绘制不可能超出一个视图的 bounds。

## Scroll View 的 Content Offset

现在我们所讲的跟 UIScrollView 有什么关系呢？一切都和它有关！考虑一种我们可以实现的滚动：我们有一个拖动时 frame 不断改变的视图。这达到了相同的效果，对吗？如果我拖动我的手指到右边，那么拖动的同时我增大视图的 `origin.x` ，瞧，这货就是 scroll view。

当然，在 scroll view 中有很多具有代表性的视图。为了实现这个平移功能，当用户移动手指时，你需要时刻改变每个视图的 frames。当我们提到组合一个 view 的光栅化图片到它父视图什么地方时，记住这个公式：

    CompositedPosition.x = View.frame.origin.x - Superview.bounds.origin.x;

    CompositedPosition.y = View.frame.origin.y - Superview.bounds.origin.y;

我们减少 `Superview.bounds.origin` 的值(因为他们总是0)。但是如果他们不为0呢？我们用和前一个图例相同的 frames，但是我们改变了紫色视图 bounds 的 origin 为 {-30, -30}。得到下图：

![][7]

现在，巧妙的是通过改变这个紫色视图的 bounds，它每一个单独的子视图都被移动了。事实上，这正是 scroll view 工作的原理。当你设置它的 [contentOffset][11] 属性时它改变 `scroll view.bounds` 的 origin。事实上，contentOffset 甚至不是实际存在的。代码看起来像这样：

    - (void)setContentOffset:(CGPoint)offset
    {
        CGRect bounds = [self bounds];
        bounds.origin = offset;
        [self setBounds:bounds];
    }

注意前一个图例，只要足够的改变 bounds 的 origin，button 将会超出紫色视图和 button 组合成的图片的范围。这也是当你足够的移动 scroll view 时，一个视图会消失！

## 世界之窗：Content Size

现在，最难的部分已经过去了，我们再看看 UIScrollView 另一个属性：[contentSize][12]。
scroll view 的 content size 并不会改变其 bounds 的任何东西，所以这并不会影响 scroll view 如何组合自己的子视图。反而，content size 定义了可滚动区域。scroll view 的默认 content size 为 {w:0, h:0}。既然没有可滚动区域，用户是不可以滚动的，但是 scroll view 仍然会显示其 bounds 范围内所有的子视图。
当 content size 设置为比 bounds 大的时候，用户就可以滚动视图了。你可以认为 scroll view 的 bounds 为可滚动区域上的一个窗口：

![][13]

当 content offset 为 {x:0, y:0} 时，可见窗口的左上角在可滚动区域的左上角处。这也是 content offset 的最小值；用户不能再往可滚动区域的左边或上边移动了。那儿没啥，别滚了！

content offset 的最大值是 content size 和 scroll view size 的差(不同于 content size 和scroll view的 bounds 大小)。这也在情理之中：从左上角一直滚动到右下角，用户停止时，滚动区域右下角边缘和滚动视图 bounds 的右下角边缘是齐平的。你可以像这样记下 content offset 的最大值：

    contentOffset.x = contentSize.width - bounds.size.width;

    contentOffset.y = contentSize.height - bounds.size.height;

## 用 Content Insets 对窗口稍作调整

[contentInset][14] 属性可以改变 content offset 的最大和最小值，这样便可以滚动出可滚动区域。它的类型为 [UIEdgeInsets][15]，包含四个值：{top，left，bottom，right}。当你引进一个 inset 时，你改变了 content offset 的范围。比如，设置 content inset 顶部值为 10，则允许 content offset 的 y 值达到 -10。这介绍了可滚动区域周围的填充。

![][16]

这咋一看好像没什么用。实际上，为什么不仅仅增加 content size 呢？除非没办法，否则你需要避免改变scroll view 的 content size。想要知道为什么？想想一个 table view（UItableView是UIScrollView 的子类，所以它有所有相同的属性），table view 为了适应每一个cell，它的可滚动区域是通过精心计算的。当你滚动经过 table view 的第一个或最后一个 cell 的边界时，table view将 content offset 弹回并复位，所以 cells 又一次恰到好处的紧贴 scroll view 的 bounds。

当你想要使用 [UIRefreshControl][17] 实现拉动刷新时发生了什么？你不能在 table view 的可滚动区域内放置 UIRefreshControl，否则，table view 将会允许用户通过 refresh control 中途停止滚动，并且将 refresh control 的顶部弹回到视图的顶部。因此，你必须将 refresh control 放在可滚动区域上方。这将允许首先将 content offset 弹回第一行，而不是 refresh control。

但是等等，如果你通过滚动足够多的距离初始化 pull-to-refresh 机制，因为 table view 设置了 content inset，这将允许 content offset 将 refresh control 弹回到可滚动区域。当刷新动作被初始化时，content inset 已经被校正过，所以 content offset 的最小值包含了完整的 refresh control。当刷新完成后，content inset 恢复正常，content offset 也跟着适应大小，这里并不需要为content size 做数学计算。(这里可能比较难理解，建议看看 EGOTableViewPullRefresh 这样的类库就应该明白了)

如何在自己的代码中使用 content inset？当键盘在屏幕上时，有一个很好的用途：你想要设置一个紧贴屏幕的用户界面。当键盘出现在屏幕上时，你损失了几百个像素的空间，键盘下面的东西全都被挡住了。

现在，scroll view 的 bounds 并没有改变，content size 也并没有改变(也不需要改变)。但是用户不能滚动 scroll view。考虑一下之前一个公式：content offset 的最大值是 content size 和 bounds 的差。如果他们相等，现在 content offset 的最大值是 {x:0, y:0}.

现在开始出绝招，将界面放入一个 scroll view。scroll view 的 content size 仍然和 scroll view 的 bounds 一样大。当键盘出现在屏幕上时，你设置 content inset 的底部等于键盘的高度。

![][18]

这允许在 content offset 的最大值下显示滚动区域外的区域。可视区域的顶部在 scroll view bounds 的外面，因此被截取了(虽然它在屏幕之外了，但这并没有什么)。

但愿这能让你理解一些滚动视图内部工作的原理，你对缩放感兴趣？好吧，我们今天不会谈论它，但是这儿有一个有趣的小窍门：检查 [`viewForZoomingInScrollView:`][20] 方法返回视图的 [transform][19] 属性。你将再次发现 scroll view 只是聪明的利用了 UIView 已经存在的属性。

相关链接(强烈推荐)：

[计算机图形渲染的流程][21]

---

 


   [1]: http://developer.apple.com/library/ios/#documentation/uikit/reference/UIScrollView_Class/Reference/UIScrollView.html
   [2]: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/UIView/UIView.html
   [3]: http://objccn.io/issue-3-1/
   [4]: /images/issues/issue-3/SV2.png
   [5]: /images/issues/issue-3/SV1.png
   [6]: /images/issues/issue-3/SV3.png
   [7]: /images/issues/issue-3/SV4.png
   [8]: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/UIView/UIView.html#//apple_ref/occ/instp/UIView/bounds
   [9]: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/UIView/UIView.html#//apple_ref/occ/instp/UIView/frame
   [10]: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/UIView/UIView.html#//apple_ref/occ/instm/UIView/drawRect:
   [11]: https://developer.apple.com/library/ios/documentation/uikit/reference/UIScrollView_Class/Reference/UIScrollView.html#//apple_ref/occ/instp/UIScrollView/contentOffset
   [12]: https://developer.apple.com/library/ios/documentation/uikit/reference/UIScrollView_Class/Reference/UIScrollView.html#//apple_ref/occ/instp/UIScrollView/contentSize
   [13]: /images/issues/issue-3/SV5.png
   [14]: https://developer.apple.com/library/ios/documentation/uikit/reference/UIScrollView_Class/Reference/UIScrollView.html#//apple_ref/occ/instp/UIScrollView/contentInset
   [15]: https://developer.apple.com/library/ios/documentation/uikit/reference/UIKitDataTypesReference/Reference/reference.html#//apple_ref/doc/c_ref/UIEdgeInsets
   [16]: /images/issues/issue-3/SV6.png  
   [17]: https://developer.apple.com/library/ios/documentation/uikit/reference/UIRefreshControl_class/Reference/Reference.html
   [18]: /images/issues/issue-3/SV7.png
   [19]: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/UIView/UIView.html#//apple_ref/occ/instp/UIView/transform
   [20]: http://developer.apple.com/library/ios/#documentation/uikit/reference/UIScrollViewDelegate_Protocol/Reference/UIScrollViewDelegate.html#//apple_ref/doc/uid/TP40006923-CH3-SW7
   [21]: http://bbs.weiphone.com/read-htm-tid-6880069.html
   [22]: http://objccn.io/issue-3/

原文 [Understanding Scroll Views](http://www.objc.io/issue-3/scroll-view.html)
   
译文 [理解Scroll View - answer-huang](http://answerhuang.duapp.com/index.php/2013/11/04/understanding-scroll-view/)
