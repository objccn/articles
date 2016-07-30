UICollectionView 在 iOS6 中第一次被引入，也是 UIKit [视图类中的一颗新星][1]。它和 UITableView 共享一套 API 设计，但也在 UITableView 上做了一些扩展。UICollectionView 最强大、同时显著超出 UITableView 的特色就是其完全灵活的布局结构。在这篇文章中，我们将会实现一个相当复杂的自定义 collection view 布局，并且顺便讨论一下这个类设计的重要部分。项目的示例代码在 [GitHub][2] 上。

## 布局对象 (Layout Objects)

UITableView 和 UICollectionView 都是 [data-source 和 delegate 驱动][3]的。它们在显示其子视图集的过程中仅扮演容器角色(`dumb containers`)，且对子视图集真正的内容毫不知情。

`UICollectionView` 在此之上进行了进一步抽象。它将其子视图的位置，大小和外观的控制权委托给一个单独的布局对象。通过提供一个自定义布局对象，你几乎可以实现任何你能想象到的布局。布局继承自 [`UICollectionViewLayout`][4] 抽象基类。iOS6 中以 [`UICollectionViewFlowLayout`][5] 类的形式提出了一个具体的布局实现。

我们可以使用 flow layout 实现一个标准的 grid view，这可能是在 collection view 中最常见的使用案例了。尽管大多数人都这么想，但是 Apple 很聪明，没有明确的命名这个类为 `UICollectionViewGridLayout`，而使用了更为通用的术语 flow layout，更好的描述了该类的功能：它通过一个接一个的放置 cell 来建立自己的布局，当需要的时候，插入横排或竖排的分栏符。通过自定义滚动方向，大小和 cell 之间的间距，flow layout 也可以在单行或单列中布局 cell。实际上，`UITableView` 的布局可以想象成 flow layout 的一种特殊情况。

在你准备自己写一个 `UICollectionViewLayout` 的子类之前，你需要问你自己，你是否能够使用 `UICollectionViewFlowLayout` 实现你心里的布局。这个类是[很容易定制][6]的，并且可以继承本身进行进一步的定制。感兴趣的看[这篇文章][7]。

## Cells 和其他 Views

为了适应任意布局，collection view 建立了一个类似、但比 table view 更灵活的视图层级（view hierarchy）。像往常一样，你的主要内容显示在 cell 中，cell 可以被任意分组到 section 中。Collection view 的 cell 必须是 `UICollectionViewCell` 的子类。除了 cell，collection view 额外管理着两种视图：supplementary views 和 decoration views。

collection view 中的 **Supplementary views** 相当于 table view 的 section header 和 footer views。像 cells 一样，他们的内容都由数据源对象驱动。然而和 table view 中用法不一样，supplementary view 并不一定会作为 header 或 footer view；他们的数量和放置的位置完全由布局控制。

**Decoration views** 纯粹为一个装饰品。他们完全属于布局对象，并被布局对象管理，他们并不从 data source 获取的 contents。当布局对象指定需要一个 decoration view 的时候，collection view 会自动创建，并将布局对象提供的布局参数应用到上面去。并不需要为自定义视图准备任何内容。

Supplementary views 和 decoration views 必须是 [UICollectionReusableView][8] 的子类。布局使用的每个视图类都需要在 collection view 中注册，这样当 data source 让它们从 reuse pool 中出列时，它们才能够创建新的实例。如果你是使用的 Interface Builder，则可以通过在可视编辑器中拖拽一个 cell 到 collection view 上完成 cell 在 collection view 中的注册。同样的方法也可以用在 supplementary view 上，前提是你使用了 `UICollectionViewFlowLayout`。如果没有，你只能通过调用 [`registerClass:`][9] 或者 [`registerNib:`][10] 方法手动注册视图类了。你需要在 `viewDidLoad` 中做这些操作。

## 自定义布局

作为一个非常有意义的自定义 collection view 布局的例子，我们不妨设想一个典型的日历应用程序中的周 (week) 视图。日历一次显示一周，星期中的每一天显示在列中。每一个日历事件将会在我们的 collection view 中以一个 cell 显示，位置和大小代表事件起始日期时间和持续时间。

![][11]
一般有两种类型的 collection view 布局：

1.**独立于内容的布局计算**。这正是你所知道的像 UITableView 和 UICollectionViewFlowLayout 这些情况。每个 cell 的位置和外观不是基于其显示的内容，但所有 cell 的显示顺序是基于内容的顺序。可以把默认的 flow layout 做为例子。每个 cell 都基于前一个 cell 放置(或者如果没有足够的空间，则从下一行开始)。布局对象不必访问实际数据来计算布局。

2.**基于内容的布局计算**。我们的日历视图正是这样类型的例子。为了计算显示事件的起始和结束时间，布局对象需要直接访问 collection view 的数据源。在很多情况下，布局对象不仅需要取出当前可见 cell 的数据，还需要从所有记录中取出一些决定当前哪些 cell 可见的数据。

在我们的日历示例中，布局对象如果访问某一个矩形内 cells 的属性，那就必须迭代数据源提供的所有事件来决定哪些位于要求的时间窗口中。 与一些相对简单，数据源独立计算的 flow layout 比起来，这足够计算出 cell 在一个矩形内的 index paths 了（假设网格中所有cells的大小都一样）。

如果有一个依赖内容的布局，那就是暗示你需要写自定义的布局类了，同时不能使用自定义的 `UICollectionViewFlowLayout`，所以这正是我们需要做的事情。

[UICollectionViewLayout的文档][12]列出了子类需要重写的方法。

### collectionViewContentSize

由于 collection view 对它的 content 并不知情，所以布局首先要提供的信息就是滚动区域大小，这样 collection view 才能正确的管理滚动。布局对象必须在此时计算它内容的总大小，包括 supplementary views 和 decoration views。注意，尽管大多数经典的 collection view 限制在一个轴方向上滚动（正如 `UICollectionViewFlowLayout` 一样），但这不是必须的。

在我们的日历示例中，我们想要视图垂直的滚动。比如，如果我们想要在垂直空间上一个小时占去 100 点，这样显示一整天的内容高度就是 2400 点。注意，我们不能够水平滚动，这就意味这我们 collection view 只能显示一周。为了能够在日历中的多个星期间分页，我们可以在一个独立（分页）的 scroll view （可以使用 [UIPageViewController][13]）中使用多个collection view（一周一个），或者坚持使用一个 collection view 并且返回足够大的内容宽度，这会使得用户感觉在两个方向上滑动自由。

    - (CGSize)collectionViewContentSize
    {
        // Don't scroll horizontally
        CGFloat contentWidth = self.collectionView.bounds.size.width;
        
        // Scroll vertically to display a full day
        CGFloat contentHeight = DayHeaderHeight + (HeightPerHour * HoursPerDay);
        
        CGSize contentSize = CGSizeMake(contentWidth, contentHeight);
        return contentSize;
    }
    
为了清楚起见，我选择布局在一个非常简单的模型上：假定每周天数相同，每天时长相同，也就是说天数用 0-6 表示。在一个真实的日历程序中，布局将会为自己的计算大量使用基于 `NSCalendaar` 的日期。

### layoutAttributesForElementsInRect:

这是任何布局类中最重要的方法了，同时可能也是最容易让人迷惑的方法。collection view 调用这个方法并传递一个自身坐标系统中的矩形过去。这个矩形代表了这个视图的可见矩形区域（也就是它的 bounds ），你需要准备好处理传给你的任何矩形。

你的实现必须返回一个包含 [`UICollectionViewLayoutAttributes`][14] 对象的数组，为每一个 cell 包含一个这样的对象，supplementary view 或 decoration view 在矩形区域内是可见的。`UICollectionViewLayoutAttributes` 类包含了 collection view 内 item 的所有相关布局属性。默认情况下，这个类包含 `frame`，`center`，`size`，`transform3D`，`alpha`，`zIndex` 和 `hidden`属性。如果你的布局想要控制其他视图的属性（比如背景颜色），你可以建一个 `UICollectionViewLayoutAttributes` 的子类，然后加上你自己的属性。

布局属性对象 (layout attributes objects) 通过 `indexPath` 属性和他们对应的 cell，supplementary view 或者 decoration view 关联在一起。collection view 为所有 items 从布局对象中请求到布局属性后，它将会实例化所有视图，并将对应的属性应用到每个视图上去。

注意！这个方法涉及到所有类型的视图，也就是 cell，supplementary views 和 decoration views。一个幼稚的实现可能会选择忽略传入的矩形，并且为 collection view 中的所有视图返回布局属性。在原型设计和开发布局阶段，这是一个有效的方法。但是，这将对性能产生非常坏的影响，特别是可见 cell 远少于所有 cell 数量的时候，collection view 和布局对象将会为那些不可见的视图做额外不必要的工作。

你的实现需要做这几步：

1. 创建一个空的可变数组来存放所有的布局属性。

2. 确定 index paths 中哪些 cells 的 frame 完全或部分位于矩形中。这个计算需要你从 collection view 的数据源中取出你需要显示的数据。然后在循环中调用你实现的 `layoutAttributesForItemAtIndexPath: ` 方法为每个 index path 创建并配置一个合适的布局属性对象，并将每个对象添加到数组中。

3. 如果你的布局包含 supplementary views，计算矩形内可见 supplementary view 的 index paths。在循环中调用你实现的 `layoutAttributesForSupplementaryViewOfKind:atIndexPath:` ，并且将这些对象加到数组中。通过为 kind 参数传递你选择的不同字符，你可以区分出不同种类的supplementary views（比如headers和footers）。当需要创建视图时，collection view 会将 kind 字符传回到你的数据源。记住 supplementary 和 decoration views 的数量和种类完全由布局控制。你不会受到 headers 和 footers 的限制。

4. 如果布局包含 decoration views，计算矩形内可见 decoration views 的 index paths。在循环中调用你实现的 `layoutAttributesForDecorationViewOfKind:atIndexPath:` ，并且将这些对象加到数组中。

5. 返回数组。

我们自定义的布局没有使用 decoration views，但是使用了两种 supplementary views（column headers和row headers）:

    - (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
    {
        NSMutableArray *layoutAttributes = [NSMutableArray array];
        // Cells
        // We call a custom helper method -indexPathsOfItemsInRect: here
        // which computes the index paths of the cells that should be included
        // in rect.
        NSArray *visibleIndexPaths = [self indexPathsOfItemsInRect:rect];
        for (NSIndexPath *indexPath in visibleIndexPaths) {
            UICollectionViewLayoutAttributes *attributes =
            [self layoutAttributesForItemAtIndexPath:indexPath];
            [layoutAttributes addObject:attributes];
        }

        // Supplementary views
        NSArray *dayHeaderViewIndexPaths = [self indexPathsOfDayHeaderViewsInRect:rect];
        for (NSIndexPath *indexPath in dayHeaderViewIndexPaths) {
            UICollectionViewLayoutAttributes *attributes =
            [self layoutAttributesForSupplementaryViewOfKind:@"DayHeaderView"
                                                 atIndexPath:indexPath];
            [layoutAttributes addObject:attributes];
        }

        NSArray *hourHeaderViewIndexPaths = [self indexPathsOfHourHeaderViewsInRect:rect];
        for (NSIndexPath *indexPath in hourHeaderViewIndexPaths) {
            UICollectionViewLayoutAttributes *attributes =
            [self layoutAttributesForSupplementaryViewOfKind:@"HourHeaderView"
                                                 atIndexPath:indexPath];
            [layoutAttributes addObject:attributes];
        }
        return layoutAttributes;
    }

### layoutAttributesFor…IndexPath

有时，collection view 会为某个特殊的 cell，supplementary 或者 decoration view 向布局对象请求布局属性，而非所有可见的对象。这就是当其他三个方法开始起作用时，你实现的  [`layoutAttributesForItemAtIndexPath:`][15] 需要创建并返回一个单独的布局属性对象，这样才能正确的格式化传给你的 index path 所对应的 cell。

你可以通过调用 [`+[UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:]`][16]这个方法，然后根据 index path 修改属性。为了得到需要显示在这个 index path 内的数据，你可能需要访问 collection view 的数据源。到目前为止，至少确保设置了 frame 属性，除非你所有的 cell 都位于彼此上方。

    - (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
    {
        CalendarDataSource *dataSource = self.collectionView.dataSource;
        id event = [dataSource eventAtIndexPath:indexPath];
        UICollectionViewLayoutAttributes *attributes =
        [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        attributes.frame = [self frameForEvent:event];
        return attributes;
    }
    
如果你正在使用自动布局，你可能会感到惊讶，我们正在直接修改布局参数的 frame 属性，而不是和约束共事，但这正是 UICollectionViewLayout 的工作。尽管你可能使用自动布局来定义collection view 的 frame 和它内部每个 cell 的布局，但 cells 的 frames 还是需要通过老式的方法计算出来。

类似的，`layoutAttributesForSupplementaryViewOfKind:atIndexPath:` 和 `layoutAttributesForDecorationViewOfKind:atIndexPath:` 方法分别需要为 supplementary 和 decoration views 做相同的事。只有你的布局包含这样的视图你才需要实现这两个方法。`UICollectionViewLayoutAttributes` 包含另外两个工厂方法，[`+layoutAttributesForSupplementaryViewOfKind:withIndexPath:`][17] 和 
[`+layoutAttributesForDecorationViewOfKind:withIndexPath:`][18]，用他们来创建正确的布局属性对象。

### shouldInvalidateLayoutForBoundsChange:

最后，当 collection view 的 bounds 改变时，布局需要告诉 collection view 是否需要重新计算布局。我的猜想是：当 collection view 改变大小时，大多数布局会被作废，比如设备旋转的时候。因此，一个幼稚的实现可能只会简单的返回 YES。虽然实现功能很重要，但是 scroll view 的 bounds 在滚动时也会改变，这意味着你的布局每秒会被丢弃多次。根据计算的复杂性判断，这将会对性能产生很大的影响。

当 collection view 的宽度改变时，我们自定义的布局必须被丢弃，但这滚动并不会影响到布局。幸运的是，collection view 将它的新 bounds 传给 `shouldInvalidateLayoutForBoundsChange:` 方法。这样我们便能比较视图当前的bounds 和新的 bounds 来确定返回值：

    - (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
    {
        CGRect oldBounds = self.collectionView.bounds;
        if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
            return YES;
        }
            return NO;
    }

## 动画

### 插入和删除

UITableView 中的 cell 自带了一套非常漂亮的插入和删除动画。但是当为 UICollectionView 增加和删除 cell 定义动画功能时，UIKit 工程师遇到这样一个问题：如果 collection view 的布局是完全可变的，那么预先定义好的动画就没办法和开发者自定义的布局很好的融合。他们提出了一个优雅的方法：当一个 cell （或者supplementary或者decoration view）被插入到 collection view 中时，collection view 不仅向其布局请求 cell 正常状态下的布局属性，同时还请求其初始的布局属性，比如，需要在开始有插入动画的 cell。collection view 会简单的创建一个 animation block，并在这个 block 中，将所有 cell 的属性从初始（initial）状态改变到常态（normal）。

通过提供不同的初始布局属性，你可以完全自定义插入动画。比如，设置初始的 alpha 为 0 将会产生一个淡入的动画。同时设置一个平移和缩放将会产生移动缩放的效果。

同样的原理应用到删除上，这次动画是从常态到一系列你设置的最终布局属性。这些都是你需要在布局类中为initial或final布局参数实现的方法.

* initialLayoutAttributesForAppearingItemAtIndexPath:

* initialLayoutAttributesForAppearingSupplementaryElementOfKind:atIndexPath:

* initialLayoutAttributesForAppearingDecorationElementOfKind:atIndexPath:

* finalLayoutAttributesForDisappearingItemAtIndexPath:

* finalLayoutAttributesForDisappearingSupplementaryElementOfKind:atIndexPath:

* finalLayoutAttributesForDisappearingDecorationElementOfKind:atIndexPath:

### 布局间切换
可以通过类似的方式将一个 collection view 布局动态的切换到另外一个布局。当发送一个 `setCollectionViewLayout:animated:` 消息时，collection view 会为 cells 在新的布局中查询新的布局参数，然后动态的将每个 cell（通过index path在新旧布局中判断出相同的cell）从旧参数变换到新的布局参数。你不需要做任何事情。

## 结论

根据自定义 collection view 布局的复杂性，写一个通常很不容易。确切的说，本质上这和从头写一个完整的实现相同布局自定义视图类一样困难了。因为所涉及的计算需要确定哪些子视图当前是可见的，以及它们的位置。尽管如此，使用 `UICollectionView` 还是给你带来了一些很好的效果，比如 cell 重用，自动支持动画，更不要提整洁的独立布局，子视图管理，以及数据提供架构规定（data preparation its architecture prescribes.）。

自定义 collection view 布局也是向[轻量级 view controller][19] 迈出很好的一步，正如你的 view controller 不要包含任何布局代码。正如 Chris 的文章中解释的一样，将这一切和一个独立的 datasource 类结合在一起，collection view 的视图控制器将很难再包含任何代码。

每当我使用 `UICollectionView` 的时候，我被其简洁的设计所折服。对于一个有经验的 Apple 工程师，为了想出如此灵活的类，很可能需要首先考虑 `NSTableView` 和 `UITableView`。

### 扩展阅读

* [Collection View Programming Guide](http://developer.apple.com/library/ios/documentation/WindowsViews/Conceptual/CollectionViewPGforIOS/Introduction/Introduction.html#//apple_ref/doc/uid/TP40012334-CH1-SW1).
* [NSHipster on `UICollectionView`](http://nshipster.com/uicollectionview/).
* [`UICollectionView`: The Complete Guide](http://ashfurrow.com/uicollectionview-the-complete-guide/), e-book by Ash Furrow.
* [`MSCollectionViewCalendarLayout`](https://github.com/monospacecollective/MSCollectionViewCalendarLayout) by Eric Horacek is an excellent and more complete implementation of a custom layout for a week calendar view.

---

 

   [1]: http://oleb.net/blog/2012/09/uicollectionview/
   [2]: https://github.com/objcio/issue-3-collection-view-layouts
   [3]: http://developer.apple.com/library/ios/#documentation/general/conceptual/CocoaEncyclopedia/DelegatesandDataSources/DelegatesandDataSources.html
   [4]: http://developer.apple.com/library/ios/#documentation/uikit/reference/UICollectionViewLayout_class/Reference/Reference.html
   [5]: https://developer.apple.com/library/ios/documentation/uikit/reference/UICollectionViewFlowLayout_class/Reference/Reference.html#//apple_ref/occ/cl/UICollectionViewFlowLayout
   [6]: https://developer.apple.com/library/ios/documentation/uikit/reference/UICollectionViewFlowLayout_class/Reference/Reference.html#//apple_ref/occ/cl/UICollectionViewFlowLayout
   [7]: https://developer.apple.com/library/ios/documentation/WindowsViews/Conceptual/CollectionViewPGforIOS/UsingtheFlowLayout/UsingtheFlowLayout.html#//apple_ref/doc/uid/TP40012334-CH3-SW4
   [8]: http://developer.apple.com/library/ios/#documentation/uikit/reference/UICollectionReusableView_class/Reference/Reference.html#//apple_ref/occ/cl/UICollectionReusableView
   [9]: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UICollectionView_class/Reference/Reference.html#//apple_ref/occ/instm/UICollectionView/registerClass:forCellWithReuseIdentifier:
   [10]: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UICollectionView_class/Reference/Reference.html#//apple_ref/occ/instm/UICollectionView/registerNib:forCellWithReuseIdentifier:
   [11]: http://www.objc.io/images/issue-3/calendar-collection-view-layout.png
   [12]: https://developer.apple.com/library/ios/documentation/uikit/reference/UICollectionViewLayout_class/Reference/Reference.html
   [13]: https://developer.apple.com/library/ios/documentation/uikit/reference/UIPageViewControllerClassReferenceClassRef/UIPageViewControllerClassReference.html
   [14]: http://developer.apple.com/library/ios/#documentation/uikit/reference/UICollectionViewLayoutAttributes_class/Reference/Reference.html
   [15]: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UICollectionViewLayout_class/Reference/Reference.html#//apple_ref/occ/instm/UICollectionViewLayout/layoutAttributesForItemAtIndexPath:
   [16]: https://developer.apple.com/library/ios/documentation/uikit/reference/UICollectionViewLayoutAttributes_class/Reference/Reference.html#//apple_ref/occ/clm/UICollectionViewLayoutAttributes/layoutAttributesForCellWithIndexPath:
   [17]: https://developer.apple.com/library/ios/documentation/uikit/reference/UICollectionViewLayoutAttributes_class/Reference/Reference.html#//apple_ref/occ/clm/UICollectionViewLayoutAttributes/layoutAttributesForSupplementaryViewOfKind:withIndexPath:
   [18]: https://developer.apple.com/library/ios/documentation/uikit/reference/UICollectionViewLayoutAttributes_class/Reference/Reference.html#//apple_ref/occ/clm/UICollectionViewLayoutAttributes/layoutAttributesForDecorationViewOfKind:withIndexPath:
   [19]: http://objccn.io/issue-1-1/
   [20]: http://objccn.io/issue-3/
  
原文 [Custom Collection View Layouts](http://www.objc.io/issue-3/collection-view-layouts.html)

译文 [自定义Collection View布局 - answser_huang](http://answerhuang.duapp.com/index.php/2013/11/20/custom_collection_view_layouts/)
