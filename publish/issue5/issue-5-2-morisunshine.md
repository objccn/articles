UIKit Dynamics 是 iOS 7 中基于物理动画引擎的一个新功能--它被特别设计使其能很好地与 collection views 配合工作，而后者是在 iOS 6 中才被引入的新特性。接下来，我们要好好看看如何将这两个特性结合在一起。 

这篇文章将讨论两个结合使用 UIKit Dynamics 和 collection view 的例子。第一个例子展示了如何去实现像 iOS 7 里信息 app 中的消息泡泡的弹簧动效，然后再进一步结合平铺机制来实现布局的可伸缩性。第二个例子展现了如何用 UIKit Dynamics 来模拟[牛顿摆](http://zh.wikipedia.org/wiki/牛顿摆)，这个例子中物体可以一个个地加入到 collection view 中，并和其他物体发生相互作用。

在我们开始之前，我假定你们对 `UICollectionView` 是如何工作是有基本的了解——查看[这篇 objc.io 文章](http://www.objccn.io/issue-3-3/)会有你想要的所有细节。我也假定你已经理解了 `UIKit Dynamics` 的工作原理--阅读这篇[博客](http://www.teehanlax.com/blog/introduction-to-uikit-dynamics/)，可以了解更多 UIKit Dynamics 的知识。

> <span class="secondary radius label">编者注</span> 如果您阅读本篇文章感觉有点吃力的话，可以先来看看 [@onevcat](http://im.onevcat.com) 的[《UICollectionView 入门》](http://onevcat.com/2012/06/introducing-collection-views/) 和[《UIKit Dynamics 入门》](http://onevcat.com/2013/06/uikit-dynamics-started/)这两篇入门文章，帮助您快速补充相关知识。

文章中的两个例子项目都已经在 GitHub 中:

- [ASHSpringyCollectionView](https://github.com/objcio/issue-5-springy-collection-view)（基于 [UICollectionView Spring Demo](https://github.com/TeehanLax/UICollectionView-Spring-Demo)）
- [Newtownian UICollectionView](https://github.com/objcio/issue-5-newtonian-collection-view)


## 关于 UIDynamicAnimator

支持 `UICollectionView` 实现 UIKit Dynamics 的最关键部分就是 `UIDynamicAnimator`。要实现这样的 UIKit Dynamics 的效果，我们需要自己自定义一个继承于 `UICollectionViewFlowLayout` 的子类，并且在这个子类对象里面持有一个 UIDynamicAnimator 的对象。

当我们创建自定义的 dynamic animator 时，我们不会使用常用的初始化方法 `-initWithReferenceView:` ，因为我们不需要把这个 dynamic animator 关联一个 view ，而是给它关联一个 collection view layout。所以我们使用 `-initWithCollectionViewLayout:` 这个初始化方法，并把 collection view layout 作为参数传入。这很关键，当的 animator 的 behavior item 的属性应该被更新的时候，它必须能够确保 collection view 的 layout 失效。换句话说，dynamic animator 将会经常使旧的 layout 失效。

我们很快就能看到这些事情是怎么连接起来的，但是在概念上理解 collection view 如何与 dynamic animator 相互作用是很重要的。

Collection view layout 将会为 collection view 中的每个 `UICollectionViewLayoutAttributes` 添加 behavior（稍后我们会讨论平铺它们）。在将这些 behaviors 添加到 dynamic animator 之后，UIKit 将会向 collection view layout 询问 atrribute 的状态。我们此时可以直接将由 dynamic animator 所提供的 items 返回，而不需要自己做任何计算。Animator 将在模拟时禁用 layout。这会导致 UIKit 再次查询 layout，这个过程会一直持续到模拟满足设定条件而结束。

所以重申一下，layout 创建了 dynamic animator，并且为其中每个 item 的 layout attribute 添加对应的 behaviors。当 collection view 需要 layout 信息时，由 dynamic animator 来提供需要的信息。

## 继承 UICollectionViewFlowLayout

我们将要创建一个简单的例子来展示如何使用一个带 UIkit Dynamic 的 collection view layout。当然，我们需要做的第一件事就是，创建一个数据源去驱动我们的 collection view。我知道以你的能力完全可以独立实现一个数据源，但是为了完整性，我还是提供了一个给你:

    @implementation ASHCollectionViewController
    
    static NSString * CellIdentifier = @"CellIdentifier";
    
    -(void)viewDidLoad 
    {
        [super viewDidLoad];
        [self.collectionView registerClass:[UICollectionViewCell class] 
                forCellWithReuseIdentifier:CellIdentifier];
    }
    
    -(UIStatusBarStyle)preferredStatusBarStyle 
    {
        return UIStatusBarStyleLightContent;
    }
    
    -(void)viewDidAppear:(BOOL)animated 
    {
        [super viewDidAppear:animated];
        [self.collectionViewLayout invalidateLayout];
    }
    
    #pragma mark - UICollectionView Methods
    
    -(NSInteger)collectionView:(UICollectionView *)collectionView 
        numberOfItemsInSection:(NSInteger)section 
    {
        return 120;
    }
    
    -(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView 
                     cellForItemAtIndexPath:(NSIndexPath *)indexPath 
    {
        UICollectionViewCell *cell = [collectionView 
            dequeueReusableCellWithReuseIdentifier:CellIdentifier 
                                      forIndexPath:indexPath];
        
        cell.backgroundColor = [UIColor orangeColor];
        return cell;
    }
    
    @end


我们注意到当 view 第一次出现的时候，这个 layout 是被无效的。这是因为没有用 Storyboard 的结果（使用或不使用 Storyboard，调用 prepareLayout 方法的时机是不同的，苹果在 WWDC 的视频中并没有告诉我们这一点）。所以，当这些视图一出现我们就需要手动使这个 collection view layout 无效。当我们用平铺（后面会详细介绍）的时候，就不需要这样。

现在来创建自定义的 collection view layout 吧，我们需要强引用一个 dynamic animator，并且使用它来驱动我们的 collcetion view layout 的 attribute。我们在实现文件里定义了一个私有属性：

    @interface ASHSpringyCollectionViewFlowLayout ()
    
    @property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
    
    @end

我们将在 layout 的初始化方法中初始化我们的 dynamic animator。还要设置一些属于父类 `UICollectionViewFlowLayout` 中的属性:


	- (id)init 
	{
    	if (!(self = [super init])) return nil;
    
    	self.minimumInteritemSpacing = 10;
    	self.minimumLineSpacing = 10;
    	self.itemSize = CGSizeMake(44, 44);
    	self.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    
    	self.dynamicAnimator = [[UIDynamicAnimator alloc] initWithCollectionViewLayout:self];
    
    	return self;
    }


我们将实现的下一个方法是 prepareLayout。我们首先需要调用父类的方法。因为我们是继承 `UICollectionViewFlowLayout` 类，所以在调用父类的 prepareLayout 方法时，可以使 collection view layout 的各个 attribute 都放置在合适的位置。我们可以依靠父类的这个方法来提供一个默认的排布，并且能够使用 `[super layoutAttributesForElementsInRect:visibleRect];` 方法得到指定 rect 内的*所有* item 的 layout attributes。


	[super prepareLayout];

	CGSize contentSize = self.collectionView.contentSize;
	NSArray *items = [super layoutAttributesForElementsInRect:
    	CGRectMake(0.0f, 0.0f, contentSize.width, contentSize.height)];

这*真的*是效率低下的代码。因为我们的 collection view 中可能会有成千上万个 cell，一次性加载所有的 cell 是一个可能会产生难以置信的内存紧张的操作。我们要在一段时间内遍历所有的元素，这也成为耗时的操作。这真的是效率的双重打击！别担心——我们是负责任的开发者，所以我们会很快解决这个问题的。我们先暂时继续使用简单、粗暴的实现方式。

当加载完我们所有的 collection view layout attribute 之后，我们需要检查他们是否都已经被加载到我们的 animator 里了。如果一个 behavior 已经在 animator 中存在，那么我们就不能重新添加，否则就会得到一个非常难懂的运行异常提示:

	<UIDynamicAnimator: 0xa5ba280> (0.004987s) in 
	<ASHSpringyCollectionViewFlowLayout: 0xa5b9e60> \{\{0, 0}, \{0, 0\}\}: 
	body <PKPhysicsBody> type:<Rectangle> representedObject:
	[<UICollectionViewLayoutAttributes: 0xa281880> 
	index path: (<NSIndexPath: 0xa281850> {length = 2, path = 0 - 0}); 
	frame = (10 10; 300 44); ] 0xa2877c0  
	PO:(159.999985,32.000000) AN:(0.000000) VE:(0.000000,0.000000) AV:(0.000000) 
	dy:(1) cc:(0) ar:(1) rs:(0) fr:(0.200000) re:(0.200000) de:(1.054650) gr:(0) 
	without representedObject for item <UICollectionViewLayoutAttributes: 0xa3833e0> 
	index path: (<NSIndexPath: 0xa382410> {length = 2, path = 0 - 0}); 
	frame = (10 10; 300 44);

如果看到了这个错误，那么这基本表明你添加了两个 behavior 给同一个 `UICollectionViewLayoutAttribute`，这使得系统不知道该怎么处理。

无论如何，一旦我们已经检查好我们是否已经将 behavior 添加到 dynamic animator 之后，我们就需要遍历每个 collection view layout attribute 来创建和添加新的 dynamic animator：

    if (self.dynamicAnimator.behaviors.count == 0) {
        [items enumerateObjectsUsingBlock:^(id<UIDynamicItem> obj, NSUInteger idx, BOOL *stop) {
            UIAttachmentBehavior *behaviour = [[UIAttachmentBehavior alloc] initWithItem:obj 
                                                                        attachedToAnchor:[obj center]];
            
            behaviour.length = 0.0f;
            behaviour.damping = 0.8f;
            behaviour.frequency = 1.0f;
            
            [self.dynamicAnimator addBehavior:behaviour];
        }];
    }

这段代码非常简单。我们为每个 item 创建了一个以物体的中心为附着点的 `UIAttachmentBehavior` 对象。然后又设置了我们的 attachment behavior 的 length 为 0 以便约束这个 cell 能一直以 behavior 的附着点为中心。然后又给 `damping` 和 `frequency` 这两个参数设置一个比较合适的值。

这就是 `prepareLayout`。我们现在需要实现 `layoutAttributesForElementsInRect:` 和 `layoutAttributesForItemAtIndexPath:` 这两个方法，UIKit 会调用它们来询问 collection view 每一个 item 的布局信息。我们写的代码会把这些查询交给专门做这些事的 dynamic animator:

	-(NSArray *)layoutAttributesForElementsInRect:(CGRect)rect 
	{
        return [self.dynamicAnimator itemsInRect:rect];
    }

    -(UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath 
    {
        return [self.dynamicAnimator layoutAttributesForCellAtIndexPath:indexPath];
    }

# 响应滚动事件

我们目前实现的代码给我们展示的只是一个在正常滑动下只有静态感觉的 `UICollectionView`，运行起来没什么特别的。看上去很好，但不是真的*动态*，不是么？

为了使它表现地动态点，我们需要 layout 和 dynamic animator 能够对 collection view 中滑动位置的变化做出反应。幸好这里有个非常适合这个要求的方法 `shouldInvalidateLayoutForBoundsChange:`。这个方法会在 collection view 的 bound 发生改变的时候被调用，根据最新的 [content offset](http://www.objccn.io/issue-3-2/) 调整我们的 dynamic animator 中的 behaviors 的参数。在重新调整这些 behavior 的 item 之后，我们在这个方法中返回 NO；因为 dynamic animator 会关心 layout 的无效问题，所以在这种情况下，它不需要去主动使其无效：

	-(BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds 
	{
        UIScrollView *scrollView = self.collectionView;
        CGFloat delta = newBounds.origin.y - scrollView.bounds.origin.y;
        
        CGPoint touchLocation = [self.collectionView.panGestureRecognizer locationInView:self.collectionView];
        
        [self.dynamicAnimator.behaviors enumerateObjectsUsingBlock:^(UIAttachmentBehavior *springBehaviour, NSUInteger idx, BOOL *stop) {
            CGFloat yDistanceFromTouch = fabsf(touchLocation.y - springBehaviour.anchorPoint.y);
            CGFloat xDistanceFromTouch = fabsf(touchLocation.x - springBehaviour.anchorPoint.x);
            CGFloat scrollResistance = (yDistanceFromTouch + xDistanceFromTouch) / 1500.0f;
            
            UICollectionViewLayoutAttributes *item = springBehaviour.items.firstObject;
            CGPoint center = item.center;
            if (delta < 0) {
                center.y += MAX(delta, delta*scrollResistance);
            }
            else {
                center.y += MIN(delta, delta*scrollResistance);
            }
            item.center = center;
            
            [self.dynamicAnimator updateItemUsingCurrentState:item];
        }];
        
        return NO;
    }

让我们仔细查看这个代码的细节。首先我们得到了这个 scroll view（就是我们的 collection view ），然后计算它的 content offset 中 y 的变化（在这个例子中，我们的 collection view 是垂直滑动的）。一旦我们得到这个增量，我们需要得到用户接触的位置。这是非常重要的，因为我们希望离接触位置比较近的那些物体能移动地更迅速些，而离接触位置比较远的那些物体则应该滞后些。

对于 dynamic animator 中的每个 behavior，我们将接触点到该 behavior 物体的 x 和 y 的距离之和除以 1500，1500 是我根据经验设的。分母越小，这个 collection view 的的交互就越有弹簧的感觉。一旦我们拿到了这个“滑动阻力”的值，我们就可以用它的增量乘上 `scrollResistance` 这个变量来指定这个 behavior 物体的中心点的 y 值。最后，我们在滑动阻力大于增量的情况下对增量和滑动阻力的结果进行了选择（这意味着物体开始往错误的方向移动了）。在本例我们用了这么大的分母，那么这种情况是不可能的，但是在一些更具弹性的 collection view layout 中还是需要注意的。

就是这么一回事。以我的经验，这个方法对多达几百个物体的 collection view 来说也是是适用的。超过这个数量的话，一次性加载所有物体到内存中就会变成很大的负担，并且在滑动的时候就会开始卡顿了。

![Springy Collection View](/images/issues/issue-5/springyCollectionView.gif)

## 平铺（Tiling）你的 Dynamic Behaviors 来优化性能

当你的 collection view 中只有几百个 cell 的时候，他运行的很好，但当数据源超过这个范围的时候会发生什么呢？或者在运行的时你不能预测你的数据源有多大呢？我们的简单粗暴的方法就不管用了。

除了在 `prepareLayout` 中加载*所有*的物体，如果我们能*更聪明地*知道哪些物体会加载那该多好啊。是的，就是仅加载显示的和即将显示的物体。这正是我们要采取的办法。

我们需要做的第一件事就是是跟踪 dynamic animator 中的所有 behavior 物体的 index path。我在 collection view 中添加一个属性来做这件事:

	@property (nonatomic, strong) NSMutableSet *visibleIndexPathsSet;

我们用 set 是因为它具有常数复杂度的查找效率，并且我们*经常*地查找 `visibleIndexPathsSet` 中是否已经包含了某个 index path。

在我们实现全新的 `prepareLayout` 方法之前——有一个问题就是什么是**平铺 behavior** —— 理解平铺的意思是非常重要的。当我们平铺behavior 的时候，我们会在这些 item 离开 collection view 的可视范围的时候删除对应的 behavior，在这些 item 进入可视范围的时候又添加对应的 behavior。这是一个大麻烦：我们需要在*滚动中*创建新的 behavior。这就意味着让人觉得创建它们就好像它们本来就已经在 dynamic animator 里了一样，并且它们是在 `shouldInvalidateLayoutForBoundsChange:` 方法被修改的。

因为我们是在滚动中创建这些新的 behavior，所以我们需要维持现在 collection view 的一些状态。尤其我们需要跟踪最近一次我们 `bound` 变化的增量。我们会在滚动时用这个状态去创建我们的 behavior：

	@property (nonatomic, assign) CGFloat latestDelta;

添加完这个 property 后，我们将要在 `shouldInvalidateLayoutForBoundsChange:` 方法中添加下面这行代码：

	self.latestDelta = delta;

这就是我们需要修改我们的方法来响应滚动事件。我们的这两个方法是为了将 collection view 中 items 的 layout 信息传给 dynamic animator，这种方式没有变化。事实上，当你的 collection view 实现了 dynamic animator 的大部分情况下，都需要实现我们上面提到的两个方法 `layoutAttributesForElementsInRect:` 和 `layoutAttributesForItemAtIndexPath:`。

这里最难懂的部分就是平铺机制。我们将要完全重写我们的 prepareLayout。

这个方法的第一步是将那些物体的 index path 已经不在屏幕上显示的 behavior 从 dynamic animator 上删除。第二步是添加那些即将显示的物体的 behavior。

让我们先看一下第一步。

像以前一样，我们要调用 `super prepareLayout`，这样我们就能依赖父类 `UICollectionViewFlowLayout` 提供的默认排布。还像以前一样，我们通过父类获取一个矩形内的所有元素的 layout attribute。不同的是我们不是获取整个 collection view 中的元素属性，而只是获取显示范围内的。

所以我们需要计算这个显示矩形。但是别着急！有件事要记住。我们的用户可能会非常快地滑动 collection view，导致了 dynamic animator 不能跟上，所以我们需要稍微扩大显示范围，这样就能包含到那些将要显示的物体了。否则，在滑动很快的时候就会出现频闪现象了。让我们计算一下显示范围:

	CGRect originalRect = (CGRect){.origin = self.collectionView.bounds.origin, .size = self.collectionView.frame.size};
	CGRect visibleRect = CGRectInset(originalRect, -100, -100);

我确信在实际显示矩形上的每个方向都扩大100个像素对我的 demo 来说是可行的。仔细查看这些值是否适合你们的 collection view，尤其是当你们的 cell 很小的情况下。

接下来我们就需要收集在显示范围内的 collection view layout attributes。还有它们的 index paths:

	NSArray *itemsInVisibleRectArray = [super layoutAttributesForElementsInRect:visibleRect];

	NSSet *itemsIndexPathsInVisibleRectSet = [NSSet setWithArray:[itemsInVisibleRectArray valueForKey:@"indexPath"]];

注意我们是在用一个 NSSet。这是因为它具有常数复杂度的查找效率，并且我们经常的查找 `visibleIndexPathsSet` 是否已经包含了某个 index path:

接下来我们要做的就是遍历 dynamic animator 的 behaviors，过滤掉那些已经在 `itemsIndexPathsInVisibleRectSet` 中的 item。因为我们已经过滤掉我们的 behavior，所以我们将要遍历的这些 item 都是不在显示范围里的，我们就可以将这些 item 从 animator 中删除掉（连同 `visibleIndexPathsSet` 属性中的 index path）:

	NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(UIAttachmentBehavior *behaviour, NSDictionary *bindings) {
        BOOL currentlyVisible = [itemsIndexPathsInVisibleRectSet member:[[[behaviour items] firstObject] indexPath]] != nil;
        return !currentlyVisible;
    }]
    NSArray *noLongerVisibleBehaviours = [self.dynamicAnimator.behaviors filteredArrayUsingPredicate:predicate];
    
    [noLongerVisibleBehaviours enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
        [self.dynamicAnimator removeBehavior:obj];
        [self.visibleIndexPathsSet removeObject:[[[obj items] firstObject] indexPath]];
    }];

下一步就是要得到*新*出现 item 的 `UICollectionViewLayoutAttributes` 数组——那些 item 的 index path 在 `itemsIndexPathsInVisibleRectSet` 而不在 `visibleIndexPathsSet`：

    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *item, NSDictionary *bindings) {
        BOOL currentlyVisible = [self.visibleIndexPathsSet member:item.indexPath] != nil;
        return !currentlyVisible;
    }];
    NSArray *newlyVisibleItems = [itemsInVisibleRectArray filteredArrayUsingPredicate:predicate];

一旦我们有新的 layout attribute 出现，我就可以遍历他们来创建新的 behavior，并且将他们的 index path 添加到 `visibleIndexPathsSet` 中。首先，无论如何，我都需要获取到用户手指触碰的位置。如果它是 `CGPointZero` 的话，那就表示这个用户没有在滑动 collection view，这时我就*假定*我们不需要在滚动时创建新的 behavior 了：

    CGPoint touchLocation = [self.collectionView.panGestureRecognizer locationInView:self.collectionView];

这是一个潜藏危险的假定。如果用户很快地滑动了 collection view 之后释放了他的手指呢？这个 collection view 就会一直滚动，但是我们的方法就不会在滚动时创建新的 behavior 了。但幸运的是，那也就意味这时 scroll view 滚动太快很难被注意到！好哇！但是，对于那些拥有大型 cell 的 collection view 来说，这仍然是个问题。那么在这种情况下，就需要增加你的可视范围的 bounds 来加载更多物体以解决这个问题。

现在我们需要枚举我们刚显示的 item，为他们创建 behavior，再将他们的 index path 添加到 `visibleIndexPathsSet`。我们还需要在滚动时做些[数学运算](http://www.youtube.com/watch?v=gENVB6tjq_M)来创建 behavior：

    [newlyVisibleItems enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *item, NSUInteger idx, BOOL *stop) {
        CGPoint center = item.center;
        UIAttachmentBehavior *springBehaviour = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:center];
        
        springBehaviour.length = 0.0f;
        springBehaviour.damping = 0.8f;
        springBehaviour.frequency = 1.0f;
        
        if (!CGPointEqualToPoint(CGPointZero, touchLocation)) {
            CGFloat yDistanceFromTouch = fabsf(touchLocation.y - springBehaviour.anchorPoint.y);
            CGFloat xDistanceFromTouch = fabsf(touchLocation.x - springBehaviour.anchorPoint.x);
            CGFloat scrollResistance = (yDistanceFromTouch + xDistanceFromTouch) / 1500.0f;
            
            if (self.latestDelta < 0) {
                center.y += MAX(self.latestDelta, self.latestDelta*scrollResistance);
            }
            else {
                center.y += MIN(self.latestDelta, self.latestDelta*scrollResistance);
            }
            item.center = center;
        }
        
        [self.dynamicAnimator addBehavior:springBehaviour];
        [self.visibleIndexPathsSet addObject:item.indexPath];
    }];

大部分代码看起来还是挺熟悉的。大概有一半是来自没有实现平铺的 `prepareLayout`。另一半是来自 `shouldInvalidateLayoutForBoundsChange:` 这个方法。我们用 latestDelta 这个属性来表示 `bound` 变化的增量，适当地调整 `UICollectionViewLayoutAttributes` 使这些 cell 表现地就像被 attachment behavior “拉”着一样。

就这样就完成了，真的！我已经在真机上测试过显示上千个 cell 的情况了，它运行地非常完美。[去试试吧](https://github.com/objcio/issue-5-springy-collection-view)。

## 超越瀑布流布局

一般来说，当我们使用 `UICollectionView` 的时候，继承 `UICollectionViewFlowLayout` 会比直接继承 `UICollectionViewLayout` 更容易。这是因为 *flow* layout 会为我们做很多事。然而，瀑布流布局是严格基于它们的尺寸一个接一个的展现出来。如果你有一个布局不能适应这个标准怎么办？好的，如果你已经尝试用 `UICollectionViewFlowLayout` 来适应，而且你很确定它不能很好运行，那么就应该抛弃 `UICollectionViewFlowLayout` 这个定制性比较弱的子类，而应该直接在 `UICollectionViewLayout` 这个基类上进行定制。

这个原则在处理 UIKit Dynamic 时也是适用的。

让我们先创建 `UICollectionViewLayout` 的子类。当继承 `UICollectionViewLayout` 的时候需要实现 `collectionViewContentSize` 方法，这点非常重要。否则这个 collection view 就不知道如果去显示自己，也不会有显示任何东西。因为我们想要 collection view 不能滚动，所以这里要返回 collection view 的 frame 的 size，减去它的 `contentInset.top`：

    -(CGSize)collectionViewContentSize 
    {
        return CGSizeMake(self.collectionView.frame.size.width, 
            self.collectionView.frame.size.height - self.collectionView.contentInset.top);
    }

在这个（有点教学式）的例子中，我们的 collection view *总是会以零个cell开始*，物体通过 `performBatchUpdates:` 这个方法添加。这就意味着我们必须使用 `-[UICollectionViewLayout prepareForCollectionViewUpdates:]` 这个方法来添加我们的 behavior（即这个 collection view 的数据源总是以零开始）。

除了给各个 item 添加 attachment behavior 外，我们还将保留另外两个 behavior：重力和碰撞。对于添加在这个 collection view 中的每个 item 来说，我们必须把这些 item 添加到我们的碰撞和 attachment behavior 中。最后一步就是设置这些 item 的初始位置为屏幕外的某些地方，这样就有被 attachment behavior 拉入到屏幕内的效果了:

	-(void)prepareForCollectionViewUpdates:(NSArray *)updateItems
	{
        [super prepareForCollectionViewUpdates:updateItems];
    
        [updateItems enumerateObjectsUsingBlock:^(UICollectionViewUpdateItem *updateItem, NSUInteger idx, BOOL *stop) {
            if (updateItem.updateAction == UICollectionUpdateActionInsert) {
                UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes 
                    layoutAttributesForCellWithIndexPath:updateItem.indexPathAfterUpdate];
            
                attributes.frame = CGRectMake(CGRectGetMaxX(self.collectionView.frame) + kItemSize, 300, kItemSize, kItemSize);

                UIAttachmentBehavior *attachmentBehaviour = [[UIAttachmentBehavior alloc] initWithItem:attributes 
                                                                                      attachedToAnchor:attachmentPoint];
                attachmentBehaviour.length = 300.0f;
                attachmentBehaviour.damping = 0.4f;
                attachmentBehaviour.frequency = 1.0f;
                [self.dynamicAnimator addBehavior:attachmentBehaviour];
            
                [self.gravityBehaviour addItem:attributes];
                [self.collisionBehaviour addItem:attributes];
            }
        }];
    }

![Demo](/images/issues/issue-5/newtonianCollectionView.gif)

删除就有点复杂了。我们希望这些物体有“掉落”的效果而不是简单的消失。这就不仅仅是从 collection view 中删除个 cell 这么简单了，因为我们希望在它离开了屏幕之前还是保留它。我已经在代码中实现了这样的效果，但是做法有点取巧。

基本上我们要做的是在 layout 中提供一个方法，在它删除 attachment behavior 两秒之后，将这个 cell 从 collection view 中删除。我们希望在这段时间里，这个 cell 能掉出屏幕，但是这不一定会发生。如果没有发生，也没关系。只要淡出就行了。然而，我们必须保证在这两秒内既没有新的 cell 被添加，也没有旧的 cell 被删除。（我说了有点取巧。）

欢迎提交 pull request。

这个方法是有局限性的。我将 cell 数量的上限设为 10，但是即使这样，在像 iPad2 这样比较旧的设备中，动画就会运行地很慢。当然，这个例子只是为了展示如何模拟有趣的动力学的一个方法——它并不是一个可以解决任何问题的万金油。你个人在实践中如何来进行模拟，包括性能等各个方面，都取决于你自己了。

---

 

原文 [UICollectionView + UIKit Dynamics](http://www.objc.io/issue-5/collection-views-and-uidynamics.html)

译文 [objc.io 第5期 iOS 7 之 UICollectionView 与 UIKit Dynamics - iOS init](http://iosinit.com/?p=1022)
