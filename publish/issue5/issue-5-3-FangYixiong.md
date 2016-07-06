## 自定义转场动画

iOS 7 中最让我激动的特性之一就是提供了新的 API 来支持自定义 view contrioller 之间的转场动画。iOS 7 发布之前，我自己写过一些 view controller 之间的转场动画，这是一个比较头疼的过程，而且这种做法并不被苹果完全地支持，尤其是如果你想让这个转场动画有交互式的效果就更难了。

在继续阅读之前，我需要先声明一下：这个 API 是新近才发布的，目前还没有所谓的最佳实践。通常来说，开发者需要探索几个月才能得出关于新 API 的最佳实践。因此请将本文看做对一个新 API 的探索，而非关于这个新 API 的最佳实践介绍。如果您有更好的关于这个 API 的实践，请不吝赐教，我们会把您的实践更新到这篇文章中。

在开始研究新的 API 之前，我们先来看看在 iOS 7 中 navigation controller 之间的默认的行为发生了那些改变：在 navigation controller 中，切换两个 view controller 的动画变得更有交互性。比方说你想要 pop 一个 view controller 出去，你可以用手指从屏幕的左边缘开始拖动，慢慢地把当前的 view controller 向右拖出屏幕去。

接下来，我们来看看这个新 API。很有趣的一个现象是，这部分 API 大量的使用了协议而不是具体的对象。这初看起来有点奇怪，但我个人更喜欢这样的 API 设计，因为这种设计给了我们这些开发者更大的灵活性。下面，让我们来做件简单的事情：在 Navigation Controller 中，实现一个自定义的 push 动画效果（本文中的[示例代码](https://github.com/objcio/issue5-view-controller-transitions)托管在 Github）。为了完成这个任务，需要实现 `UINavigationControllerDelegate` 中的新方法：

> <span class="secondary radius label">编者注</span> 原文的作者在 Github 上面的示例代码和文章中的代码有一些出入（比如下面这里是 Push，但是在示例代码中是 Pop）。如果需要，您也可以参考这个[修正版示例代码](https://github.com/FangYiXiong/ViewControllerTransitionsDemo/tree/master/issue5-demo1（Fixed）)，和文章的代码差异要小一点。

    - (id<UIViewControllerAnimatedTransitioning>)
                       navigationController:(UINavigationController *)navigationController
            animationControllerForOperation:(UINavigationControllerOperation)operation
                         fromViewController:(UIViewController*)fromVC
                           toViewController:(UIViewController*)toVC
    {
        if (operation == UINavigationControllerOperationPush) {
            return self.animator;
        }
        return nil;
    }

从上面的代码可以看出，我们可以根据不同的 operation（Push 或 Pop）返回不同的 animator。我们可以把 animator 存到一个属性中，从而在多个 operation 之间实现共享，或者我们也可以为每个 operation 都创建一个新的 animator 对象，这里的灵活性很大。

为了让动画运行起来，我们创建一个自定义类，并且实现 `UIViewControllerAnimatedTransitioning` 这个协议：

    @interface Animator : NSObject <UIViewControllerAnimatedTransitioning>
    
    @end

这个协议要求我们实现两个方法，其中一个定义了动画的持续时间：

    - (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
    {
        return 0.25;
    }

另一个方法描述整个动画的执行效果：

    - (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
    {
        UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        [[transitionContext containerView] addSubview:toViewController.view];
        toViewController.view.alpha = 0;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            fromViewController.view.transform = CGAffineTransformMakeScale(0.1, 0.1);
            toViewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            fromViewController.view.transform = CGAffineTransformIdentity;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
            
        }];

    }

从上面的例子中，你可以看到如何运用协议的：这个方法中通过接受一个类型为 `id<UIViewControllerContextTransitioning>` 的参数，来获取 transition context。值得注意的是，执行完动画之后，我们需要调用 transitionContext 的 `completeTransition:` 这个方法来更新 view controller 的状态。剩下的代码和 iOS 7 之前的一样了，我们从 transition context 中得到了需要做转场的两个 view controller，然后使用最简单的 `UIView` animation 来实现了转场动画。这就是全部代码了，我们已经实现了一个缩放效果的转场动画。

注意，这里只是为 Push 操作实现了自定义效果的转场动画，对于 Pop 操作，还是会使用默认的滑动效果，另外，上面我们实现的转场动画无法交互，下面我们就来看看解决这个问题。

## 交互式的转场动画

想要动画变地可以交互非常简单，我们只需要覆盖另一个 `UINavigationControllerDelegate` 的方法：

    - (id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController*)navigationController
                              interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>)animationController
    {
        return self.interactionController;
    }

注意，在非交互式动画效果中，该方法返回 nil。

这里返回的 interaction controller 是 `UIPercentDrivenInteractionTransition` 类的一个实例，开发者不需要任何配置就可工作。我们创建了一个**拖动手势（Pan Recognizer）**，下面是处理该手势的代码：

    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (location.x >  CGRectGetMidX(view.bounds)) {
            navigationControllerDelegate.interactionController = [[UIPercentDrivenInteractiveTransition alloc] init];
            [self performSegueWithIdentifier:PushSegueIdentifier sender:self];
        }
    } 

> <span class="secondary radius label">编者注</span> 这里的代码有一点示意的意思，和实际代码有些出入，为了尊重原作者，我们没有进行修改，您可以参考原文在 Github 上的[示例代码](https://github.com/objcio/issue5-view-controller-transitions)进行对比，也可以参考这个[修正版示例代码](https://github.com/FangYiXiong/ViewControllerTransitionsDemo/tree/master/issue5-demo1（Fixed）)。

只有当用户从屏幕右半部分开始触摸的时候，我们才把下一次动画效果设置为交互式的（通过设置 `interactionController` 这个属性来实现），然后执行方法 `performSegueWithIdentifier:`（如果你不是使用的 storyboards，那么就直接调用 `pushViewController...` 这类方法）。为了让转场动画持续进行，我们需要调用 interaction controller 的一个方法：

    else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGFloat d = (translation.x / CGRectGetWidth(view.bounds)) * -1;
        [interactionController updateInteractiveTransition:d];
    } 

该方法会根据用户手指拖动的距离计算一个百分比，切换的动画效果也随着这个百分比来走。最酷的是，interaction controller 会和 animation controller 一起协作，我们只使用了简单的 `UIView` animation 的动画效果，但是interaction controller 却控制了动画的执行进度，我们并不需要把 interaction controller 和 animation controller 关联起来，因为所有这些系统都以一种解耦的方式自动地替我们完成了。

最后，我们需要根据用户手势的停止状态来判断该操作是结束还是取消，并调用 interaction controller 中对应的方法：

    else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if ([panGestureRecognizer velocityInView:view].x < 0) {
            [interactionController finishInteractiveTransition];
        } else {
            [interactionController cancelInteractiveTransition];
        }
        navigationControllerDelegate.interactionController = nil;
    }

注意，当切换完成或者取消的时候，记得把 interaction controller 设置为 nil。因为如果下一次的转场是非交互的， 我们不应该返回这个旧的 interaction controller。

现在我们已经实现了一个完全自定义的可交互的转场动画了。通过简单的手势识别和 UIKit 提供的一个类，用几行代码就达到完成了。对于大部分的应用场景，你读到这儿就够用了，使用上面提到的方法就可以达到你想要的动画效果了。但如果你想更对转场动画或者交互效果进行深度定制，请继续阅读下面一节。

###  使用 GPUImage 定制动画

下面我们就来看看如何真正的，彻底的定制动画效果。这一次我们不使用 UIView animation，甚至连 Core Animation 也不用，完全自己来实现所有的动画效果。在 [Letterpress-style](http://www.macstories.net/featured/a-conversation-with-loren-brichter) 这个项目中，刚开始我尝试使用 Core Image 来做动画效果，但是在我的 iPhone 4 上，动画的渲染最高只能达到 9 帧/秒，离我想要的 60 帧/秒差得很远。

但是当我使用了 [GPUImage](https://github.com/BradLarson/GPUImage) 之后，实现一个非常漂亮的动画变的异常简单。这里我们要实现的转场效果是：两个 view controller 像素化，然后相互消融在一起。实现方法是先对两个 view controller 进行截屏，然后再用 GPUImage 的图片**滤镜（filter）**处理这两张截图。

首先，我们先创建一个自定义类，这个类实现了 `UIViewControllerAnimatedTransitioning` 和 `UIViewControllerInteractiveTransitioning` 这两个协议：

    @interface GPUImageAnimator : NSObject
      <UIViewControllerAnimatedTransitioning,
       UIViewControllerInteractiveTransitioning>
    
    @property (nonatomic) BOOL interactive;
    @property (nonatomic) CGFloat progress;
    
    - (void)finishInteractiveTransition;
    - (void)cancelInteractiveTransition;
    
    @end

为了加速动画的运行，我们可以把图片一次加载到 GPU 中，然后所有的处理和绘图都直接在 GPU 上执行，不需要再传送到 CPU 处理（这种数据传输非常慢）。通过使用 GPUImageView，我们就可以直接使用 OpenGL 画图（我们不需要手写 OpenGL 这种底层的代码，只要继续使用 GPUImage 封装好的接口就可以）。

创建**滤镜链（filter chain）**也非常的直观，我们可以直接在样例代码的 `setup` 方法中看到如何构造它。比较有挑战的是如何让滤镜也“动”起来。GPUImage 没有直接提供给我们动画效果，因此我们需要每渲染一帧就更新一下滤镜来实现动态的滤镜效果。使用 `CADisplayLink` 可以完成这个工作：

> <span class="secondary radius label">编者注</span> 原文中的示例代码中缺少了这一章的内容，我在原作者的 Github Gist 上找到了相关的源码，整理之后放到了 Github 上，您可以在[这里](https://github.com/FangYiXiong/ViewControllerTransitionsDemo/tree/master/issue5-demo2（GPUImage）)找到它。

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(frame:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

在 `frame` 方法中，我们可以根据时间来更新动画进度，并相应地更新滤镜：

    - (void)frame:(CADisplayLink*)link
    {
        self.progress = MAX(0, MIN((link.timestamp - self.startTime) / duration, 1));
        self.blend.mix = self.progress;
        self.sourcePixellateFilter.fractionalWidthOfAPixel = self.progress *0.1;
        self.targetPixellateFilter.fractionalWidthOfAPixel = (1- self.progress)*0.1;
        [self triggerRenderOfNextFrame];
    }

好了，基本上这样就完成了。如果你想要实现交互式的转场效果，那么在这里，就不能使用时间，而是要根据手势来更新动画进度，其他的代码基本差不多。

这个功能非常强大，你可以使用 GPUImage 中任何已有的滤镜，或者写一个自己的 OpenGL **着色器（shader）**来达到你想要的效果。

## 结论

本文只探讨了在 navigation controller 中的两个 view controller 之间的转场动画，但是这些做法在 tab bar controller 或者任何你自己定义的 view controller 容器中也是通用的。另外，在 iOS 7 中，`UICollectionViewController` 也进行了扩展，现在你可以在布局之间进行自动以及交互的动画切换，背后使用的也是同样的机制。这真是太强大了。

在和 [Orta](https://twitter.com/orta) 讨论这个 API 的时候，他提到他已经在大量地使用这些机制以创建更轻量的 view controller。与其在一个 view controller 中维护各种状态，不如再创建一个新的 view controller，使用自定义的转场动画，然后在这个转场动画中来移动你的各种 view。

## 扩展阅读

* [WWDC: Custom Transitions using View Controllers](http://asciiwwdc.com/2013/sessions/218)
* [Custom UIViewController transitions](http://www.teehanlax.com/blog/custom-uiviewcontroller-transitions/)
* [iOS 7: Custom Transitions](http://www.doubleencore.com/2013/09/ios-7-custom-transitions/)
* [Custom View Controller Transitions with Orientation](http://whoisryannystrom.com/2013/10/01/View-Controller-Transition-Orientation/)

---

 

原文 [View Controller Transitions](http://www.objc.io/issue-5/view-controller-transitions.html)
