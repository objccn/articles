`UICollectionView` and the set of associated classes are extremely flexible and powerful. But with this flexibility comes a certain dose of complexity: a collection view is a good deal deeper and more capable than the good old `UITableView`.

`UICollectionView` 和相关类的设置非常灵活的和强大的。但这种灵活性也带来了一定的复杂性: `UICollectionView` 比老式的 `UITableView` 更有深度，能力也更强大。

It's so much deeper, in fact, that [Ole Begeman](http://oleb.net) and [Ash Furrow](https://twitter.com/ashfurrow) have written about [Custom Collection View Layouts](http://www.objc.io/issue-3/collection-view-layouts.html) and [Collection Views with UIKit Dynamics](http://www.objc.io/issue-5/collection-views-and-uidynamics.html) in objc.io previously, and I still have something to write about that they have not covered. In this post, I will assume that you're familiar with the basics of collection view layouts and have at least read Apple's excellent [programming guide](https://developer.apple.com/library/ios/documentation/WindowsViews/Conceptual/CollectionViewPGforIOS/Introduction/Introduction.html#//apple_ref/doc/uid/TP40012334) and Ole's [post](http://www.objc.io/issue-3/collection-view-layouts.html).

它非常有深度了，事实上，[Ole Begeman](http://oleb.net) 和 [Ash Furrow](https://twitter.com/ashfurrow) 之前曾在 objc.io 上发表过 [自定义 Collection View 布局](http://www.objc.io/issue-3/collection-view-layouts.html) 和 [UICollectionView + UIKit 力学](http://www.objc.io/issue-5/collection-views-and-uidynamics.html)，但是我依旧有一些他们没有提及的内容写。在这篇文章中，我假设你已经非常熟悉 `UICollectionView` 的基本布局并且阅读了苹果优秀的[编程指南](https://developer.apple.com/library/ios/documentation/WindowsViews/Conceptual/CollectionViewPGforIOS/Introduction/Introduction.html#//apple_ref/doc/uid/TP40012334)以及 Ole 之前的[文章](http://www.objc.io/issue-3/collection-view-layouts.html)。

The first section of this article will concentrate on how different classes and methods work together to animate a collection view layout with the help of a few common examples. In the second section, we will look at view controller transitions with collection views and see how to use `useLayoutToLayoutNavigationTransitions` for the cases when it works, and implement custom transitions for the cases when it does not.

本文的第一部分将集中讨论如何用不同的类和方法来共同帮助实现一些常见的 `UICollectionView` 动画的例子。在第二部分，我们将看一下 collection views 的 view 转场动画以及 `useLayoutToLayoutNavigationTransitions` 正常运行情况下如何工作，另一部分是如果不工作如何自定义转场动画。

The two example projects for this article are available on GitHub:

你可以在 GitHub 中找到本文提到的两个示例工程:

- [Layout Animations](https://github.com/objcio/issue-12-CollectionViewAnimations)
- [Custom Collection View Transitions](https://github.com/objcio/issue-12-CustomCollectionViewTransition)


##Collection View Layout Animations Collection View 布局动画

The standard `UICollectionViewFlowLayout` is very customizable except for its animations; Apple opted for the safe approach and implemented a simple fade animation as default for all layout animations. If you would like to have custom animations, the best way is to subclass the `UICollectionViewFlowLayout` and implement your animations at the appropriate locations. Let's go through a few examples to understand how various methods in your `UICollectionViewFlowLayout` subclasses should work together to deliver custom animations.

标准 `UICollectionViewFlowLayout` 除了动画是非常容易自定义动画的，苹果选择了一种安全的途径去实现一个简单的淡入淡出动画作为默认的布局动画。如果你想实现自定义动画，最好的办法是子类化 `UICollectionViewFlowLayout` 并且在适当的地方实现你的动画。让我们通过一些例子来了解 `UICollectionViewFlowLayout` 子类中的一些方法如何协助完成自定义动画。

###Inserting and Removing Items 插入删除元素

In general, layout attributes are linearly interpolated from the initial state to the final state to compute the collection view animations. However, for the newly inserted or removed items, there are no initial and final attributes to interpolate from. To compute the animations for such cells, the collection view will ask its layout object to provide the initial and final attributes through the `initialLayoutAttributesForAppearingItemAtIndexPath:` and `finalLayoutAttributesForAppearingItemAtIndexPath:` methods. The default Apple implementation returns the layout attributes corresponding to the normal position at the specific index path, but with an `alpha` value of 0.0, resulting in a fade-in or fade-out animation. If you would like to have something fancier, like having your new cells shoot up from the bottom of the screen and rotate while flying into place, you could implement something like this in your layout subclass:

一般来说，布局属性是用初始状态到结束状态的线性插值来计算 collection view 的动画，但是不管怎样，新插入或者删除的元素，没有最初和最终状态来进行插值。要计算 cells 的动画，Collection view 将要求其布局对象通过 `initialLayoutAttributesForAppearingItemAtIndexPath:` 以及 `finalLayoutAttributesForAppearingItemAtIndexPath:` 方法提供最初的和最后的属性。苹果默认实现了返回对应于特定指数的正常位置路径的布局属性，但 `alpha` 值为0.0，导致产生淡入或淡出动画。如果你想要更漂亮的效果，就像你新的 cells 从屏幕底部发射并且旋转飞到对应位置，你可以如下实现这样的布局子类：

    - (UICollectionViewLayoutAttributes*)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
    {
        UICollectionViewLayoutAttributes *attr = [self layoutAttributesForItemAtIndexPath:itemIndexPath];

        attr.transform = CGAffineTransformRotate(CGAffineTransformMakeScale(0.2, 0.2), M_PI);
        attr.center = CGPointMake(CGRectGetMidX(self.collectionView.bounds), CGRectGetMaxY(self.collectionView.bounds));

        return attr;
    }

Which results in this:

结果如下

![Insertion and Deletion](http://img.objccn.io//issue-12/2014-05-01-collectionview-animations-1-insertion.gif)

The corresponding `finalLayoutAttributesForAppearingItemAtIndexPath:` method for the shown animation is very similar, except that it assigns a different transform.

显示动画相对于 `finalLayoutAttributesForAppearingItemAtIndexPath:` 方法除了不同的 transform 几乎一致。

###Responding to Device Rotations 设备旋转响应

A device orientation change usually results in a bounds change for a collection view. The layout object is asked if the layout should be invalidated and recomputed with the method `shouldInvalidateLayoutForBoundsChange:`. The default implementation in `UICollectionViewFlowLayout` does the correct thing, but if you are subclassing `UICollectionViewLayout` instead, you should return `YES` on a bounds change:

设备方向变化通常会导致 collection view 的边界变化。布局对象如果询问布局无效，将通过 `shouldInvalidateLayoutForBoundsChange:` 重新计算。 `UICollectionViewFlowLayout` 默认实现正确处理了这个情况，但是如果你子类化 `UICollectionViewLayout`，你需要在边界变化时返回 `YES`。


    - (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
    {
        CGRect oldBounds = self.collectionView.bounds;
        if (!CGSizeEqualToSize(oldBounds.size, newBounds.size)) {
            return YES;
        }
        return NO;
    }

During the animation of the bounds change, the collection view acts as if the currently displayed items are removed and inserted again in the new bounds, resulting in a series of `finalLayoutAttributesForAppearingItemAtIndexPath:` and `initialLayoutAttributesForAppearingItemAtIndexPath:` calls for each index path.

在边界变化的动画中，Collection view 充当了如果删除所有元素并且重新插入能正确显示，导致了一系列的 `finalLayoutAttributesForAppearingItemAtIndexPath:` 和 `initialLayoutAttributesForAppearingItemAtIndexPath:` 对于每一个 IndexPath 的调用。


If you implemented some fancy animations for the insertion and deletion of items in the collection view, by now you should be seeing why Apple went with simple fade animations as a sensible default:

如果你在插入和删除的时候加入了非常炫的动画，现在你应该看看为何苹果明智的使用简单的淡入淡出动画作为默认效果

![设备旋转的错误反应](http://img.objccn.io/issue-12/2014-05-01-collectionview-animations-2-wrong-rotation.gif)

Oops…

噢...

To prevent such unwanted animations, the sequence of initial position -> removal animation -> insertion animation -> final position must be matched for each item in the collection view, so that they result in a smooth animation. In other words, `finalLayoutAttributesForAppearingItemAtIndexPath:` and `initialLayoutAttributesForAppearingItemAtIndexPath:` should be able to return different attributes depending on if the item in question is really disappearing or appearing, or if the collection view is going through a bounds change animation.

为了防止不必要的动画，初始化位置 -> 删除动画 -> 插入动画 -> 最终位置的序列必须完全匹配 collection view 的每一项，结果将会是一个平滑动画。换句话说，`finalLayoutAttributesForAppearingItemAtIndexPath:` 以及 `initialLayoutAttributesForAppearingItemAtIndexPath:` 应该可以在元素显示或者消失的时候返回不同的属性，如果 collection view 正在经历一系列的边界改变动画。

Luckily, the collection view tells the layout object which kind of animation is about to be performed. It does this by invoking the `prepareForAnimatedBoundsChange:` or `prepareForCollectionViewUpdates:` for bounds changes and item updates respectively. For the purposes of this example, we can use `prepareForCollectionViewUpdates:` to keep track of updated objects:

幸运的时，Collection view 告诉布局对象哪一种动画被执行。它对于边界变化和元素变更分别调用 `prepareForAnimatedBoundsChange:` 或者 `prepareForCollectionViewUpdates:` 。为了实现这个目的，我们可以使用 `prepareForCollectionViewUpdates:`  来跟踪对象变更：

    - (void)prepareForCollectionViewUpdates:(NSArray *)updateItems
    {
        [super prepareForCollectionViewUpdates:updateItems];
        NSMutableArray *indexPaths = [NSMutableArray array];
        for (UICollectionViewUpdateItem *updateItem in updateItems) {
            switch (updateItem.updateAction) {
                case UICollectionUpdateActionInsert:
                    [indexPaths addObject:updateItem.indexPathAfterUpdate];
                    break;
                case UICollectionUpdateActionDelete:
                    [indexPaths addObject:updateItem.indexPathBeforeUpdate];
                    break;
                case UICollectionUpdateActionMove:
                    [indexPaths addObject:updateItem.indexPathBeforeUpdate];
                    [indexPaths addObject:updateItem.indexPathAfterUpdate];
                    break;
                default:
                    NSLog(@"unhandled case: %@", updateItem);
                    break;
            }
        }  
        self.indexPathsToAnimate = indexPaths;
    }
    
And modify our item insertion animation to only shoot the item if it is currently being inserted into the collection view:

以及修改我们元素的插入动画只关注正确被插入 collection view 的元素。

    - (UICollectionViewLayoutAttributes*)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
    {
        UICollectionViewLayoutAttributes *attr = [self layoutAttributesForItemAtIndexPath:itemIndexPath];

        if ([_indexPathsToAnimate containsObject:itemIndexPath]) {
            attr.transform = CGAffineTransformRotate(CGAffineTransformMakeScale(0.2, 0.2), M_PI);
            attr.center = CGPointMake(CGRectGetMidX(self.collectionView.bounds), CGRectGetMaxY(self.collectionView.bounds));
            [_indexPathsToAnimate removeObject:itemIndexPath];
        }

        return attr;
    }

If the item is not being inserted, the normal attributes as reported by `layoutAttributesForItemAtIndexPath` will be returned, canceling any special appearance animations. Combined with the corresponding logic inside `finalLayoutAttributesForAppearingItemAtIndexPath:`, this will result in the items smoothly animating from their initial positions to their final positions in the case of a bounds change, creating a simple but cool animation:

如果这个元素没有正确被插入，这个正常的属性会通过 `layoutAttributesForItemAtIndexPath` 来反馈。取消任何特殊动画。在 `finalLayoutAttributesForAppearingItemAtIndexPath:` 内结合相应的逻辑，这将导致元素从初始位置到最后位置范围内的动画顺利变化的情况下,创建一个简单但很酷的动画

![Wrong reaction to device rotation](http://img.objccn.io/issue-12/2014-05-01-collectionview-animations-3-correct-rotation.gif)

###Interactive Layout Animations 交互式布局动画

Collection views make it quite easy to allow the user to interact with the layout using gesture recognizers. As [suggested](https://developer.apple.com/library/ios/documentation/WindowsViews/Conceptual/CollectionViewPGforIOS/IncorporatingGestureSupport/IncorporatingGestureSupport.html#//apple_ref/doc/uid/TP40012334-CH4-SW1) by Apple, the general approach to add interactivity to a collection view layout follows these steps:

Collection views 使它非常容易通过手势来与手势交互。来自苹果的[建议](https://developer.apple.com/library/ios/documentation/WindowsViews/Conceptual/CollectionViewPGforIOS/IncorporatingGestureSupport/IncorporatingGestureSupport.html#//apple_ref/doc/uid/TP40012334-CH4-SW1)，一般的方法添加交互性 Collection view 布局遵循这些步骤:

1. Create the gesture recognizer
2. Add the gesture recognizer to the collection view
3. Handle the recognized gestures to drive the layout animations  

1. 创建手势
2. 给 Collection view 添加手势
3. 通过手势来驱动布局动画

Let's see how we can build something where the user can pinch an item to zoom, and the item returns to original size as soon as the user releases his or her pinch.

让我们来看看我们可以建立一些用户可以放大捏合一个元素，以及一旦用户释放他们的捏合手势元素返回到原始大小。

Our handler method could look something like this:

我们的处理方式可能会是这样：

    - (void)handlePinch:(UIPinchGestureRecognizer *)sender {
        if ([sender numberOfTouches] != 2)
            return;


        if (sender.state == UIGestureRecognizerStateBegan ||
            sender.state == UIGestureRecognizerStateChanged) {
            // Get the pinch points.
            CGPoint p1 = [sender locationOfTouch:0 inView:[self collectionView]];
            CGPoint p2 = [sender locationOfTouch:1 inView:[self collectionView]];

            // Compute the new spread distance.
            CGFloat xd = p1.x - p2.x;
            CGFloat yd = p1.y - p2.y;
            CGFloat distance = sqrt(xd*xd + yd*yd);

            // Update the custom layout parameter and invalidate.
            FJAnimatedFlowLayout* layout = (FJAnimatedFlowLayout*)[[self collectionView] collectionViewLayout];

            NSIndexPath *pinchedItem = [self.collectionView indexPathForItemAtPoint:CGPointMake(0.5*(p1.x+p2.x), 0.5*(p1.y+p2.y))];
            [layout resizeItemAtIndexPath:pinchedItem withPinchDistance:distance];
            [layout invalidateLayout];

        }
        else if (sender.state == UIGestureRecognizerStateCancelled ||
                 sender.state == UIGestureRecognizerStateEnded){
            FJAnimatedFlowLayout* layout = (FJAnimatedFlowLayout*)[[self collectionView] collectionViewLayout];
            [self.collectionView
             performBatchUpdates:^{
                [layout resetPinchedItem];
             }
             completion:nil];
        }
    }

This pinch handler computes the pinch distance and figures out the pinched item, and tells the layout to update itself while the user is pinching. As soon as the pinch gesture is over, the layout is reset in a batch update to animate the return to the original size.

这个捏合计算捏合距离以及捏合元素的数据，并且在用户捏合的时候来更新布局自身。当捏合手势结束的时候，布局会做一个批量更新动画返回原始尺寸。

Our layout, on the other hand, keeps track of the pinched item and the desired size and provides the correct attributes for them when needed:

对我们的布局的另一方面，始终在跟踪捏合的元素以及期望尺寸并且在需要的时候提供正确的属性：

    - (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
    {
        NSArray *attrs = [super layoutAttributesForElementsInRect:rect];

        if (_pinchedItem) {
            UICollectionViewLayoutAttributes *attr = [[attrs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"indexPath == %@", _pinchedItem]] firstObject];

            attr.size = _pinchedItemSize;
            attr.zIndex = 100;
        }
        return attrs;
    }

###Summary 总结

We looked at how to build custom animations in collection view layout by using a few examples. Even though the `UICollectionViewFlowLayout` does not directly allow customization of its animations, it is clearly architected by Apple engineers to be subclassed to implement various custom behavior. Essentially, boundless custom layout and animations can be achieved by correctly reacting to signaling methods such as:

回顾我们之前利用一些例子来证明的如何在 collection view 创建自定义动画。虽然 `UICollectionViewFlowLayout` 并不直接允许定制他们的动画，但是苹果工程师提供了清晰的架构让你可以子类化去实现各种自定义行。从本质来说，无限的自定义布局和动画可以通过正确相应单例方法来实现：

- `prepareLayout`
- `prepareForCollectionViewUpdates:`
- `finalizeCollectionViewUpdates`
- `prepareForAnimatedBoundsChange:`
- `finalizeAnimatedBoundsChange`
- `shouldInvalidateLayoutForBoundsChange:`

in your `UICollectionViewLayout` subclass and returning the appropriate attributes from methods which return `UICollectionViewLayoutAttributes`. Even more engaging animations can be achieved by combining these techniques with UIKit Dynamics as introduced in objc.io [issue #5](http://www.objc.io/issue-5/collection-views-and-uidynamics.html).

在你的 `UICollectionViewLayout` 子类和从  `UICollectionViewLayoutAttributes` 返回的相应的属性。更引人入胜的动画可以在 objc.io 推的出 [issue #5](http://www.objc.io/issue-5/collection-views-and-uidynamics.html) 结合这些技术与动态的 UIKit 来实现。

## View Controller Transitions with Collection Views View controller 转场动画和 Collection views

One of the big improvements in iOS 7 was with the custom view controller transitions, as [Chris](https://twitter.com/chriseidhof) [wrote about](http://www.objc.io/issue-5/view-controller-transitions.html) in objc.io [issue #5](http://www.objc.io/issue-5/index.html). In parallel to the custom transitions, Apple also added the `useLayoutToLayoutNavigationTransitions` flag to `UICollectionViewController` to enable navigation transitions which reuse a single collection view. Apple's own Photos and Calendar apps on iOS represent a great example of what is possible using such transitions.

iOS 7 其中的一个重大更新是自定义 View controller 转场动画，就如 [Chris](https://twitter.com/chriseidhof) 之前在 objc.io 的[文章] (http://www.objc.io/issue-5/view-controller-transitions.html)。平行于自定义转场动画，苹果也在 `UICollectionViewController` 添加了 `useLayoutToLayoutNavigationTransitions` 标记来启用可复用的单个 collection view 的导航转场。苹果自己的照片和日历应用就是非常好的转场动画的代表作。


### Transitions Between UICollectionViewController Instances UICollectionViewController 实例之间的转场动画

Let's look at how we can achieve a similar effect using the same sample project from the previous section:

让我们来看看我们如何能够利用上一节相同的示例项目达到类似的效果：

![Layout to Layout Navigation Transitions](http://img.objccn.io/issue-12/2014-05-01-collectionview-animations-4-layout2layout.gif)

In order for the layout-to-layout transitions to work, the root view controller in the navigation controller must be a collection view controller, where `useLayoutToLayoutNavigationTransitions` is set to `NO`. When another `UICollectionViewController` instance with `useLayoutToLayoutNavigationTransitions` set to `YES` is pushed on top of this root view controller, the navigation controller replaces the standard push animation with a layout transition animation. One important detail to note here is that the root view controller's collection view instance is recycled for the collection view controller instances pushed on the navigation stack, i.e. these collection view controllers don't have their own collection views, and if you try to set any collection view properties in methods like `viewDidLoad`, they will not have any effect and you will not receive any warnings.

为了使布局到布局的转场动画工作，根视图控制器必须是一个 `useLayoutToLayoutNavigationTransitions` 设置为 `NO` 的 collection 视图控制器，当其他 `useLayoutToLayoutNavigationTransitions` 设置为 `YES` 的 `UICollectionViewController` 实例 push 到根视图控制器之上，导航控制器用布局转场动画代替标准转场动画。这里要注意一个重要的细节，根视图控制器的 collection view 实例被回收用于 push 在导航栈上 collection 控制器，如果你试图在 `viewDidLoad` 之类的方法中中设置 collection view 属性， 它们将不会有任何效果，你也不会受到任何警告。

Probably the most common gotcha of this behavior is to expect the recycled collection view to update its data source and delegate to reflect the top collection view controller. It does not: the root collection view controller stays the data source and delegate unless we do something about it.

这个行为可能最常见的陷阱是预计回收的 collection view 更新数据源和委托反应这个上层的 collection 视图控制器。它当然不会这样：根 collection 视图控制器会保持数据源和委托,除非我们做点什么。

The workaround for this problem is to implement the navigation controller delegate methods and correctly set the data source and the delegate of the collection view as needed by the current view controller at the top of the navigation stack. In our simple example, this can be achieved by:

在解决此问题的方法是实现导航控制器的委托方法并正确设置数据源，并根据需要通过在导航堆栈顶部的当前视图控制器 collection 视图的委托。在我们简单的例子中，这可以通过以下方式实现：



    - (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
    {
        if ([viewController isKindOfClass:[FJDetailViewController class]]) {
            FJDetailViewController *dvc = (FJDetailViewController*)viewController;
            dvc.collectionView.dataSource = dvc;
            dvc.collectionView.delegate = dvc;
            [dvc.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:_selectedItem inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
        }
        else if (viewController == self){
            self.collectionView.dataSource = self;
            self.collectionView.delegate = self;
        }
    }

When the detail collection view is pushed onto the stack, we set the collection view's data source to the detail view controller, which makes sure that only the selected color of cells is shown in the detail collection view. If we were not to do this, the layout would correctly transition but the collection would still be showing all cells. In a real-world app, the detail data source would usually be responsible for showing more detail about the data in such a transition.

当详细页面的 collection view 被推入导航栈，我们重新设置 collection view 的数据源到详细视图控制器，确保只有被选择的 cell 的颜色显示在详细页面的 collection view 中。如果我们不这样做，布局依然可以正确过度，但是将显示所有的 cells，在实际应用中，细节数据源通常负责在转场动画过程中显示详细数据。

### Collection View Layout Animations for General Transitions 

The layout-to-layout navigation transitions using the `useLayoutToLayoutNavigationTransitions` flag are quite useful, but limited to transitions where both view controllers are `UICollectionViewController` instances  only and the transition takes place between their top-level collection views. We need a custom view controller transition in order to achieve a similar transition between arbitrary collection views in arbitrary view controllers.

![Custom Collection View Transition]({{site.images_path}}/issue-12/2014-05-01-collectionview-animations-5-custom-transitions.gif)

An animation controller for such a custom transition could be designed along the following steps:

1. Make snapshots of all visible items in the initial collection view
2. Add the snapshots to the transitioning context container view
3. Compute the final positions using the layout of the target collection view
4. Animate the snapshots to the correct positions
5. Remove the snapshots while making the target collection view visible

The downside of such an animator design is two-fold: it can only animate the items visible in the initial collection view, since the [snapshot APIs](https://developer.apple.com/library/ios/documentation/uikit/reference/uiview_class/UIView/UIView.html#//apple_ref/doc/uid/TP40006816-CH3-SW198) only work for views already visible on the screen, and depending on the number of visible items, there could be a lot of views to correctly keep track of and to animate. On the other hand, the big advantage of this design would be that it would work for all kinds of `UICollectionViewLayout` combinations. The implementation of such a system is left as an exercise for the reader.

Another approach, which is implemented in the accompanying demo project, relies on a few quirks of the `UICollectionViewFlowLayout`.

The basic idea is that both the source and the destination collection views have valid flow layouts and the layout attributes of the source layout could act as the initial layout attributes for the items in the the destination collection view to drive the transition animation. Once this is set up, the collection view machinery would take care of keeping track of all items and animate them for us, even if they're not initially visible on the screen. Here is the core of the `animateTransition:` method of our animation controller:

        CGRect initialRect = [inView.window convertRect:_fromCollectionView.frame fromView:_fromCollectionView.superview];
        CGRect finalRect   = [transitionContext finalFrameForViewController:toVC];

        UICollectionViewFlowLayout *toLayout = (UICollectionViewFlowLayout*) _toCollectionView.collectionViewLayout;

        UICollectionViewFlowLayout *currentLayout = (UICollectionViewFlowLayout*) _fromCollectionView.collectionViewLayout;

        //make a copy of the original layout
        UICollectionViewFlowLayout *currentLayoutCopy = [[UICollectionViewFlowLayout alloc] init];

        currentLayoutCopy.itemSize = currentLayout.itemSize;
        currentLayoutCopy.sectionInset = currentLayout.sectionInset;
        currentLayoutCopy.minimumLineSpacing = currentLayout.minimumLineSpacing;
        currentLayoutCopy.minimumInteritemSpacing = currentLayout.minimumInteritemSpacing;
        currentLayoutCopy.scrollDirection = currentLayout.scrollDirection;

        //assign the copy to the source collection view
        [self.fromCollectionView setCollectionViewLayout:currentLayoutCopy animated:NO];

        UIEdgeInsets contentInset = _toCollectionView.contentInset;

        CGFloat oldBottomInset = contentInset.bottom;

        //force a very big bottom inset in the target collection view
        contentInset.bottom = CGRectGetHeight(finalRect)-(toLayout.itemSize.height+toLayout.sectionInset.bottom+toLayout.sectionInset.top);
        self.toCollectionView.contentInset = contentInset;

        //set the source layout for the destination collection view
        [self.toCollectionView setCollectionViewLayout:currentLayout animated:NO];

        toView.frame = initialRect;

        [inView insertSubview:toView aboveSubview:fromView];

        [UIView
         animateWithDuration:[self transitionDuration:transitionContext]
         delay:0
         options:UIViewAnimationOptionBeginFromCurrentState
         animations:^{
           //animate to the final frame
             toView.frame = finalRect;
             //set the final layout inside performUpdates
             [_toCollectionView
              performBatchUpdates:^{
                  [_toCollectionView setCollectionViewLayout:toLayout animated:NO];
              }
              completion:^(BOOL finished) {
                  _toCollectionView.contentInset = UIEdgeInsetsMake(contentInset.top,
                                                                    contentInset.left,
                                                                    oldBottomInset,
                                                                    contentInset.right);
              }];

         } completion:^(BOOL finished) {
             [transitionContext completeTransition:YES];
         }];

First, the animation controller makes sure that the destination collection view starts with the exact same frame and layout as the original. Then, it assigns the layout of the source collection view to the destination collection view, making sure that it does not get invalidated. At the same time, the layout is 'copied' into a new layout object, which gets assigned to the original collection view to prevent strange layout bugs when navigating back to the original view controller. We also force a large bottom content inset on the destination collection view to make sure that the layout stays on a single line for the initial positions for the animation. If you look at the logs, you will see the collection view complaining about this temporary condition because the item size plus the insets are larger than the non-scrolling dimension of the collection view. In this state, the behavior of the collection view is not defined, and we are only using this unstable state as the initial state for our transition animation. Finally, the convoluted animation block does its magic by first setting the frame of the destination collection view to its final position, and then performing a non-animated layout change to the final layout inside the updates block of `performBatchUpdates:completion:`, which is followed by the resetting of the content insets to the original values in the completion block.

###In Conclusion

We looked at two different approaches to achieve layout transitions between collection views. The first method, with the help of the built-in `useLayoutToLayoutNavigationTransitions`, looks quite impressive and is very easy to implement, but is limited in cases where it can be used. For the cases where `useLayoutToLayoutNavigationTransitions` is not applicable, a custom animator is required to drive the transition animation. In this post, we have seen an example of how such an animator could be implemented, however, since your app will almost certainly require a completely different animation between two different view hierarchies, as in this example, don't be reluctant about trying out a different approach and seeing if it works.
