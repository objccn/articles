---
layout: post
title:  "Custom Container View Controller Transitions"
category: "12"
date: "2014-05-08 09:00:00"
tags: article
author: "<a href=\"https://twitter.com/osteslag\">Joachim Bondo</a>"
---

In [issue #5](http://www.objc.io/issue-5/index.html), [Chris Eidhof](http://twitter.com/chriseidhof) took us through the new custom [View Controller Transitions](http://www.objc.io/issue-5/view-controller-transitions.html) in iOS 7. He [concluded](http://www.objc.io/issue-5/view-controller-transitions.html#conclusion) (emphasis mine):

> We only looked at animating between two view controllers in a navigation controller, but **you can do the same for** tab bar controllers or **your own custom container view controllers**…

在[话题 #5](http://www.objc.io/issue-5/index.html), [Chris Eidhof](http://twitter.com/chriseidhof) 向我们介绍了iOS7引入的新特性 [View Controller 转场](http://www.objc.io/issue-5/view-controller-transitions.html). 他给出了一个 [结论](http://www.objc.io/issue-5/view-controller-transitions.html#conclusion) :

> 我们在本文只探讨了在 navigation controller 中的两个 view controller 之间的转场动画，但是这些做法在 tab bar controller 或者**任何你自己定义的 view controller 容器**中**也是通用的**… 


While it is technically true that you can customize the transition between two view controllers in custom containment, if you're using the iOS 7 API, it is not supported out of the box. Far from. 

尽管从技术角度来讲，使用iOS 7 的API，你可以对自定义容器中的view controllers做自定义转场，但是至少目前看来，实现这种效果还是不那么容易的。

Note that I am talking about custom container view controllers as direct subclasses of `UIViewController`, not `UITabBarController` or `UINavigationController` subclasses.

请注意我正在讨论的自定义视图控制器容器(container view controllers)都是 `UIViewController`的直接子类，而不是`UITabBarController` 或者 `UINavigationController` 的子类。

There is no ready-to-use API for your custom container `UIViewController` subclass that allows an arbitrary *animation controller* to automatically conduct the transition from one of your child view controllers to another, interactively or non-interactively. I am tempted to say it was not even Apple’s intention to support it. What is supported are the following transitions:

- Navigation controller pushes and pops
- Tab bar controller selection changes
- Modal presentations and dismissals


对于你自定义的继承于`UIViewController`的容器子类，并没有现成可用的API允许一个任意的*动画控制器(animation controller)* 从一个子视图控制器(child view controller)自动转场到另外一个, 不管是可交互式的转场还是不可交互式的转场。 我甚至都觉着苹果根本就不想支持这种方式。苹果支持下面的这几种转场方式:

- Navigation controller 推入和推出页面
- Tab bar controller 选择某一项
- 模态页面的展示和消失

In this chapter I will demonstrate how you *can* build a custom container view controller yourself while supporting third-party animation controllers.

在本文中，我将向你展示如何自定义视图控制器容器(container view controller)，并且使其支持第三方的动画控制器(animation controllers)。

If you need to brush up on view controller containment, introduced in iOS 5, make sure to read [Ricky Gregersen](https://twitter.com/rickigregersen)’s “[View Controller Containment](http://www.objc.io/issue-1/containment-view-controller.html)” in the very [first issue](http://www.objc.io/issue-1/).

如果你需要复习一下iOS 5 引入的视图控制器容器，请阅读[话题＃1](http://www.objc.io/issue-1/)中[Ricky Gregersen](https://twitter.com/rickigregersen)写的文章 “[View Controller Containment](http://www.objc.io/issue-1/containment-view-controller.html)” 。

## Before We Begin
## 预热准备


You may ask yourself a question or two at this point, so let me answer them for you:

*Why not just subclass `UINavigationController` or `UITabBarController` and get the support for free?*

看到这里，你可能对上文我们说到的一些问题犯嘀咕，让我来告诉你答案吧:

*为什么我们不直接继承 `UINavigationController` or `UITabBarController` , 并且使用它们提供的功能的 ?*

Well, sometimes that’s just not what you want. Maybe you want a very specific appearance or behavior, far from what these classes offer, and therefore would have to resort to tricky hacking, risking it to break with any new version of the framework. Or maybe you just want to be in total control of your containment and avoid having to support specialized functionality.

有些时候这是你不想要的。可能你想要一个非常特殊的外观或者行为，和这些类能够提供给你的差别非常大，因此你必须使用一些黑客式的手段去达到你想要的结果，同时还要担心系统框架(framework)的版本更新后这些黑客式的手段是否还仍然有效。或者，你就是想完全控制你的视图控制器容器，避免不得不支持一些特定的功能。


*OK, but then why not just use `transitionFromViewController:toViewController:duration:options:animations:completion:` and be over with it?*

*好吧, 那么为什么不使用  `transitionFromViewController:toViewController:duration:options:animations:completion:` 去实现呢?*


Another good question, and you may just want to do that. But perhaps you care about your code and want to encapsulate the transition. So why not use a now-established and well-proven design pattern? And, heck, as a bonus, have support for third-party transition animations thrown in for free.

这又是一个好问题，你可能想用这种方式去实现，但是或许你对代码的整洁性比较在意，想把这种转场相关的代码封装在内部。那么为什么不使用一个新提出的、被良好验证的设计模式呢？这种设计模式可以非常方便的支持第三方的转场动画。


## Introducing the API
## 介绍相关的API


Now, before we start coding – and we will in a minute, I promise – let's set the scene.

在我们开始写代码之前，让我们先花一分钟的时间来简单看一下我们需要的组件吧。


The components of the iOS 7 custom view controller transition API are mostly protocols which make them extremely flexible to work with, because you can very easily plug them into your existing class hierarchy. The five main components are:

iOS 7自定义视图控制器转场的API基本上都是以协议的方式提供的，这也使其可以非常灵活的使用，因为你可以很简单的在你的类中实现它们。 最主要的5个组件如下:


1. **Animation Controllers** conforming to the `UIViewControllerAnimatedTransitioning` protocol and in charge of performing the actual animations.

1. **动画控制器(Animation Controllers)** 遵从`UIViewControllerAnimatedTransitioning`协议，并且负责执行动画。



2. **Interaction Controllers** controlling the interactive transitions by conforming to the `UIViewControllerInteractiveTransitioning` protocol.

2. **交互控制器(Interaction Controllers)** 通过遵从`UIViewControllerInteractiveTransitioning` 协议来控制可交互式的转场。



3. **Transitioning Delegates** conveniently vending animation and interaction controllers, depending on the kind of transition to be performed.

3. **转场代理(Transitioning Delegates)** 根据不同的转场类型方便的提供需要的动画控制器和交互控制器(animation and interaction controllers)。



4. **Transitioning Contexts** defining metadata about the transition, such as properties of the view controllers and views participating in the transition. These objects conform to the `UIViewControllerContextTransitioning` protocol, *and are created and provided by the system*.

4. **转场上下文(Transitioning Contexts)** 定义了转场时需要的元数据(metadata), 比如在转场过程中所参与的视图控制器和视图的相关属性。 转场上下文(Transitioning Contexts)对象遵从 `UIViewControllerContextTransitioning` 协议, *并且是由系统负责生成和提供的*。


5. **Transition Coordinators** providing methods to run other animations parallel to the transition animations. They conform to the `UIViewControllerTransitionCoordinator` protocol.

5. **转场协调器(Transition Coordinators)** 可以在运行转场动画时，并行的运行其他动画。 转场协调器(Transition Coordinators)遵从 `UIViewControllerTransitionCoordinator` 协议。



As you know, from other reading this publication, there are interactive and non-interactive transitions. In this article, we will concentrate on non-interactive transitions. These are the simplest, so they're a great place to start. This means that we will be dealing with *animation controllers*, *transitioning delegates*, and *transitioning contexts* from the list above.

正如你从其他的阅读材料中得知的那样，转场有不可交互式和可交互式两种方式。在本文中，我们将集中精力于不可交互的转场。这种转场是最简单的转场，也是我们学习的一个好的开始。这意味着我们需要处理上面提到的*动画控制器(animation controllers)*, *转场代理(transitioning delegates)* 和 *转场上下文(transitioning contexts)*。


Enough talk, let’s get our hands dirty…

闲话少说，让我们开始动手吧…


## The Project
## 工程


In three stages, we will be creating a sample app featuring a custom container view controller, which implements support for custom child view controller transition animations.

通过三个阶段，我们将要实现一个简单自定义的视图控制器容器(container view controller)，并且可以对子视图控制器(child view controller)提供自定义的转场动画的支持。

The Xcode project, in its three stages, is put in a [repository on GitHub](https://github.com/objcio/issue-12-custom-container-transitions).

你可以在[这里](https://github.com/objcio/issue-12-custom-container-transitions)找到这三个阶段的Xcode工程的源代码。

### Stage 1: The Basics
### 阶段 1: 基础


The central class in our app is `ContainerViewController`, which hosts an array of `UIViewController` instances -- in our case, trivial `ChildViewController` objects. The container view controller sets up a private subview with tappable icons representing each child view controller:

![Stage 1: no animation]({{site.images_path}}/issue-12/2014-05-01-custom-container-view-controller-transitions-stage-1.gif)

我们应用中的核心类是`ContainerViewController`，它持有一个`UIViewController`实例的数组，每个实例代表一个`ChildViewController`。当点击代表子视图控制器(child view controller)的图标时，容器视图控制器会创建一个子视图(subview):

![Stage 1: no animation](http://img.objccn.io/issue-12/2014-05-01-custom-container-view-controller-transitions-stage-1.gif)


To switch between child view controllers, tap the icons. At this stage, there is no transition animation when switching child view controllers.

我们通过点击图标在不同的子视图控制器(child view controller)之间切换。在这一阶段，子视图控制器(child view controller)之间切换时是没有转场动画的。

Check out the [stage-1](https://github.com/objcio/issue-12-custom-container-transitions/tree/stage-1) tag to see the code for the basic app.

你可以在这里查看[阶段－1](https://github.com/objcio/issue-12-custom-container-transitions/tree/stage-1)的源代码。



### Stage 2: Animating the Transition
### Stage 2: 转场动画


When adding a transition animation, we want to support *animation controllers* conforming to `UIViewControllerAnimatedTransitioning`. The protocol defines these three methods, the first two of which are required:

    - (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext;
    - (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext;
    - (void)animationEnded:(BOOL)transitionCompleted;        

当我们添加转场动画时，我们想要使*动画控制器(animation controllers)*遵从`UIViewControllerAnimatedTransitioning`协议。这个协议声明了3个方法，前面的2个方法是必须实现的：

    - (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext;
    - (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext;
    - (void)animationEnded:(BOOL)transitionCompleted;  

This tells us everything we need to know. When our container view controller is about to perform the animation, we can query the animation controller for the duration and ask it to perform the actual animation. When it is done, we can call `animationEnded:` on the the animation controller, if it implements that optional method.

通过这些方法，我们可以获得我们所需的所有东西。当我们的视图控制器容器(container view controller)准备做动画时，我们可以从动画控制器(animation controller)中获取动画的持续时间，并让其去执行真正的动画。当动画执行完毕后，如果动画控制器(animation controller)实现了可选的 `animationEnded:`方法，我们可以调用动画控制器(animation controller)中的 `animationEnded:`方法。


However, there is one thing we need to figure out first. As you can see from the method signatures above, the two required ones take a *transitioning context* parameter, i.e., an object conforming to `UIViewControllerContextTransitioning`. Normally, when using the built-in classes, the framework creates and passes on this context to our animation controller for us. But in our case, since we are acting as the framework, *we* need to create that object.

但是，首先我们必须把一件事情搞清楚。正如你在上面的方法签名中看到的那样，上面两个必须实现的方法需要一个*转场上下文(transitioning context)*参数，这是一个需要实现`UIViewControllerContextTransitioning`协议的对象。通常情况下，当我们使用系统内建的类时，系统框架为我们创建了*转场上下文(transitioning context)*对象，并把它传递给动画控制器(animation controller)。但是在我们这种情况下，我们需要自定义转场动画，所以我们自己便需要承担系统框架的责任，*自己*去创建这个*转场上下文(transitioning context)*对象。


This is where the convenience of the heavy use of protocols comes in. Instead of having to override a private class, which obviously is a no-go, we can make our own and just have it conform to the documented protocol.

这就是大量使用协议的方便之处。我们可以不用必须复写一个私有类，而复写私有类这种方法是明显不可行的。我们可以定义自己的类，并使其遵从相应的协议就可以了。


There are a [lot of methods](https://developer.apple.com/library/ios/documentation/uikit/reference/UIViewControllerContextTransitioning_protocol/Reference/Reference.html), though, and they are all required. But we can ignore some of them for now, because we are currently only supporting non-interactive transitions.

尽管在`UIViewControllerContextTransitioning`协议中声明了[很多方法](https://developer.apple.com/library/ios/documentation/uikit/reference/UIViewControllerContextTransitioning_protocol/Reference/Reference.html)，而且它们都是必须要实现(required)的，但是我们现在可以暂时忽略它们中的一些方法，因为我们现在仅仅支持不可交互的转场(non-interactive transitions)。


Just like UIKit, we define a private `NSObject <UIViewControllerContextTransitioning>` class. In our specialized case, it is the `PrivateTransitionContext` class, and the initializer is implemented like this:

    - (instancetype)initWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController goingRight:(BOOL)goingRight {
        NSAssert ([fromViewController isViewLoaded] && fromViewController.view.superview, @"The fromViewController view must reside in the container view upon initializing the transition context.");
        
        if ((self = [super init])) {
            self.presentationStyle = UIModalPresentationCustom;
            self.containerView = fromViewController.view.superview;
            self.viewControllers = @{
                UITransitionContextFromViewControllerKey:fromViewController,
                UITransitionContextToViewControllerKey:toViewController,
            };
            
            CGFloat travelDistance = (goingRight ? -self.containerView.bounds.size.width : self.containerView.bounds.size.width);
            self.disappearingFromRect = self.appearingToRect = self.containerView.bounds;
            self.disappearingToRect = CGRectOffset (self.containerView.bounds, travelDistance, 0);
            self.appearingFromRect = CGRectOffset (self.containerView.bounds, -travelDistance, 0);
        }
        
        return self;
    }

同UIKit类似，我们定义了一个私有类 `NSObject <UIViewControllerContextTransitioning>`。在我们的例子中，这个私有类是 `PrivateTransitionContext`，它的初始化方法如下实现：

    - (instancetype)initWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController goingRight:(BOOL)goingRight {
        NSAssert ([fromViewController isViewLoaded] && fromViewController.view.superview, @"The fromViewController view must reside in the container view upon initializing the transition context.");
        
        if ((self = [super init])) {
            self.presentationStyle = UIModalPresentationCustom;
            self.containerView = fromViewController.view.superview;
            self.viewControllers = @{
                UITransitionContextFromViewControllerKey:fromViewController,
                UITransitionContextToViewControllerKey:toViewController,
            };
            
            CGFloat travelDistance = (goingRight ? -self.containerView.bounds.size.width : self.containerView.bounds.size.width);
            self.disappearingFromRect = self.appearingToRect = self.containerView.bounds;
            self.disappearingToRect = CGRectOffset (self.containerView.bounds, travelDistance, 0);
            self.appearingFromRect = CGRectOffset (self.containerView.bounds, -travelDistance, 0);
        }
        
        return self;
    }



We basically capture state, including initial and final frames, for the appearing and disappearing views.

我们把视图(views)的出现和消失时的状态记录了下来，比如初始状态和最终状态的frame。

Notice, our initializer requires information about whether we are going right or not. In our specialized `ContainerViewController` context, where buttons are arranged horizontally next to each other, the transition context is recording information about their positional relationship by setting the respective frames. The animation controller, or *animator*, can choose to use this when composing the animation. 

请注意一点，我们的初始化方法需要我们提供我们是在向右切换还是向左切换。在我们的 `ContainerViewController` 中，按钮是一个接一个水平排列的，转场上下文通过每个的frame来记录它们之间的位置关系。动画控制器(animation controller)或者说*动画生成器(animator)*，在生成动画(composing the animation)时可以使用这些frame。

We could gather this information in other ways, but it would require the animator to know about the `ContainerViewController` and its view controllers, and we don’t want that. The animator should only concern itself with the context, which is passed to it, because that would, ideally, make the animator reusable in other contexts.

我们也可以通过另外的方式去获取这些信息，但是那样的话，就会使动画生成器(animator)和`ContainerViewController` 及其视图控制器(view controllers)耦合在一起了，这是不好的，我们并不想这样。动画生成器(animator)应该只关心它自己以及传递给它的上下文(context)，因为这样，在理想情况下，可以使动画生成器(animator)可以在不同的上下文(context)中得到复用。

We will keep this in mind when making our own animation controller next, now that we have the transition context available to us.

在下一步实现我们自己的动画控制器(animation controller)时，我们应该时刻记住这一点，现在让我们来实现转场上下文(transition context)吧。

You probably remember that this was exactly what we did in [View Controller Transitions](http://www.objc.io/issue-5/view-controller-transitions.html), [issue #5](http://www.objc.io/issue-5/). So why not just use that? In fact, because of the extensive use of protocols in this framework, we can take the animation controller, the `Animator` class, from that project and plug it right in to ours – without any modifications.

你可能记得我们在 [issue #5](http://www.objc.io/issue-5/)中的[View Controller 转场](http://www.objc.io/issue-5/view-controller-transitions.html)已经做过相同的事情了，为什么我们不使用它呢？事实上，由于使用了非常灵活的协议，我们可以直接把那个工程中的动画控制器(animation controller)，也就是 `Animator` 类直接拿过来使用，不需要任何修改。

Using an `Animator` instance to animate our transition essentially looks like this:

    [fromViewController willMoveToParentViewController:nil];
    [self addChildViewController:toViewController];

    Animator *animator = [[Animator alloc] init];

    NSUInteger fromIndex = [self.viewControllers indexOfObject:fromViewController];
    NSUInteger toIndex = [self.viewControllers indexOfObject:toViewController];
    PrivateTransitionContext *transitionContext = [[PrivateTransitionContext alloc] initWithFromViewController:fromViewController toViewController:toViewController goingRight:toIndex > fromIndex];

    transitionContext.animated = YES;
    transitionContext.interactive = NO;
    transitionContext.completionBlock = ^(BOOL didComplete) {
        [fromViewController.view removeFromSuperview];
        [fromViewController removeFromParentViewController];
        [toViewController didMoveToParentViewController:self];
    };

    [animator animateTransition:transitionContext];

使用 `Animator` 类的实例来做转场动画的核心代码如下所示：

    [fromViewController willMoveToParentViewController:nil];
    [self addChildViewController:toViewController];

    Animator *animator = [[Animator alloc] init];

    NSUInteger fromIndex = [self.viewControllers indexOfObject:fromViewController];
    NSUInteger toIndex = [self.viewControllers indexOfObject:toViewController];
    PrivateTransitionContext *transitionContext = [[PrivateTransitionContext alloc] initWithFromViewController:fromViewController toViewController:toViewController goingRight:toIndex > fromIndex];

    transitionContext.animated = YES;
    transitionContext.interactive = NO;
    transitionContext.completionBlock = ^(BOOL didComplete) {
        [fromViewController.view removeFromSuperview];
        [fromViewController removeFromParentViewController];
        [toViewController didMoveToParentViewController:self];
    };

    [animator animateTransition:transitionContext];


Most of this is the required container view controller song and dance, and finding out whether we going left or right. Doing the animation is basically three lines of code: 1) creating the animator, 2) creating the transition context, and 3) triggering the animation.

这其中的大部分是在对视图控制器容器(container view controller)的操作，计算出我们是在向左切换还是向右切换。做动画的部分基本上只有3行代码：1) 创建动画生成器(animator), 2) 创建转场上下文(transition context), 和 3) 触发动画执行。



With that, the transition now looks like this:

![Stage 2: third-party animation]({{site.images_path}}/issue-12/2014-05-01-custom-container-view-controller-transitions-stage-2.gif)

有了上面的代码，转场效果看起来如下图所示:

![Stage 2: third-party animation](http://img.objccn.io/issue-12/2014-05-01-custom-container-view-controller-transitions-stage-2.gif)


Pretty cool. We haven’t even written any animation code ourselves!

非常酷，我们甚至没有写一行动画相关的代码。

This is reflected in the code with the [stage-2](https://github.com/objcio/issue-12-custom-container-transitions/tree/stage-2) tag. To see the full extent of the stage 2 changes, check the [diff against stage 1](https://github.com/objcio/issue-12-custom-container-transitions/compare/stage-1...stage-2).

你可以在[阶段-2](https://github.com/objcio/issue-12-custom-container-transitions/tree/stage-2)标签下看到这部分代码的变化。在[于阶段－1的对比](https://github.com/objcio/issue-12-custom-container-transitions/compare/stage-1...stage-2)这里你可以看到阶段 2和阶段 1相对比的完整的代码改变。

### Stage 3: Shrink-Wrapping
### Stage 3: 封装


One last thing I think we should do is shrink-wrapping `ContainerViewController` so that it:

我想我们最后要做的一件事情是封装 `ContainerViewController` ，使其能够：

1. comes with its own default transition animation, and. 
1. 提供默认的转场动画。

2. supports a delegate for vending alternative animation controllers.
2. 提供替换默认动画控制器的代理。

This entails conveniently removing the dependency to the `Animator` class, as well as creating a delegate protocol.

这意味着我们需要把对 `Animator` 类的依赖移除，同时需要创建一个代理协议。

We define our protocol as:

    @protocol ContainerViewControllerDelegate <NSObject>
    @optional
    - (void)containerViewController:(ContainerViewController *)containerViewController didSelectViewController:(UIViewController *)viewController;
    - (id <UIViewControllerAnimatedTransitioning>)containerViewController:(ContainerViewController *)containerViewController animationControllerForTransitionFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController;
    @end

我们如下定义这个协议:

    @protocol ContainerViewControllerDelegate <NSObject>
    @optional
    - (void)containerViewController:(ContainerViewController *)containerViewController didSelectViewController:(UIViewController *)viewController;
    - (id <UIViewControllerAnimatedTransitioning>)containerViewController:(ContainerViewController *)containerViewController animationControllerForTransitionFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController;
    @end


The `containerViewController:didSelectViewController:` method just makes it easier to integrate `ContainerViewController` into more feature-complete apps. 

方法 `containerViewController:didSelectViewController:` 使`ContainerViewController`可以很容易的集成于功能齐全的应用中。 


The interesting method is `containerViewController:animationControllerForTransitionFromViewController:toViewController:`, of course, which can be compared to the following container view controller delegate protocol methods in UIKit:

- `tabBarController:animationControllerForTransitionFromViewController:toViewController:` (`UITabBarControllerDelegate`)
- `navigationController:animationControllerForOperation:fromViewController:toViewController:` (`UINavigationControllerDelegate`)

有趣的方法是`containerViewController:animationControllerForTransitionFromViewController:toViewController:`，当然，你可以把它和下面的UIKit中的视图控制器容器(container view controller)的代理协议做对比:

- `tabBarController:animationControllerForTransitionFromViewController:toViewController:` (`UITabBarControllerDelegate`)
- `navigationController:animationControllerForOperation:fromViewController:toViewController:` (`UINavigationControllerDelegate`)



All these methods return an `id<UIViewControllerAnimatedTransitioning>` object.

所有的这些方法都返回一个 `id<UIViewControllerAnimatedTransitioning>` 对象。


Instead of always using an `Animator` object, we can now ask our delegate for an animation controller:

    id<UIViewControllerAnimatedTransitioning>animator = nil;
    if ([self.delegate respondsToSelector:@selector (containerViewController:animationControllerForTransitionFromViewController:toViewController:)]) {
        animator = [self.delegate containerViewController:self animationControllerForTransitionFromViewController:fromViewController toViewController:toViewController];
    }
    animator = (animator ?: [[PrivateAnimatedTransition alloc] init]);

与之前一直使用一个 `Animator` 对象不同, 我们现在可以从我们的代理那里获取一个动画控制器(animation controller):

    id<UIViewControllerAnimatedTransitioning>animator = nil;
    if ([self.delegate respondsToSelector:@selector (containerViewController:animationControllerForTransitionFromViewController:toViewController:)]) {
        animator = [self.delegate containerViewController:self animationControllerForTransitionFromViewController:fromViewController toViewController:toViewController];
    }
    animator = (animator ?: [[PrivateAnimatedTransition alloc] init]);


If we have a delegate and it returns an animator, we will use that. Otherwise, we will create our own private default animator of class `PrivateAnimatedTransition`. We will implement this next.

如果我们有代理并且它返回了一个动画生成器(animator)，那么我们就使用这个动画生成器(animator)。否则，我们使用内部私有类`PrivateAnimatedTransition`创建一个默认的动画生成器(animator)。稍后我们将实现`PrivateAnimatedTransition`类。

Although the default animation is somewhat different than that of `Animator`, the code looks surprisingly similar. Here is the full implementation:

    @implementation PrivateAnimatedTransition

    static CGFloat const kChildViewPadding = 16;
    static CGFloat const kDamping = 0.75f;
    static CGFloat const kInitialSpringVelocity = 0.5f;

    - (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
        return 1;
    }

    - (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
        
        UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        
        // When sliding the views horizontally, in and out, figure out whether we are going left or right.
        BOOL goingRight = ([transitionContext initialFrameForViewController:toViewController].origin.x < [transitionContext finalFrameForViewController:toViewController].origin.x);
        
        CGFloat travelDistance = [transitionContext containerView].bounds.size.width + kChildViewPadding;
        CGAffineTransform travel = CGAffineTransformMakeTranslation (goingRight ? travelDistance : -travelDistance, 0);
        
        [[transitionContext containerView] addSubview:toViewController.view];
        toViewController.view.alpha = 0;
        toViewController.view.transform = CGAffineTransformInvert (travel);
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:kDamping initialSpringVelocity:kInitialSpringVelocity options:0x00 animations:^{
            fromViewController.view.transform = travel;
            fromViewController.view.alpha = 0;
            toViewController.view.transform = CGAffineTransformIdentity;
            toViewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            fromViewController.view.transform = CGAffineTransformIdentity;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }

    @end

尽管默认的动画和`Animator`有一些不同，但是代码看起来惊人的相似。下面是完整的代码实现:

    @implementation PrivateAnimatedTransition

    static CGFloat const kChildViewPadding = 16;
    static CGFloat const kDamping = 0.75f;
    static CGFloat const kInitialSpringVelocity = 0.5f;

    - (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
        return 1;
    }

    - (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
        
        UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        
        // When sliding the views horizontally, in and out, figure out whether we are going left or right.
        BOOL goingRight = ([transitionContext initialFrameForViewController:toViewController].origin.x < [transitionContext finalFrameForViewController:toViewController].origin.x);
        
        CGFloat travelDistance = [transitionContext containerView].bounds.size.width + kChildViewPadding;
        CGAffineTransform travel = CGAffineTransformMakeTranslation (goingRight ? travelDistance : -travelDistance, 0);
        
        [[transitionContext containerView] addSubview:toViewController.view];
        toViewController.view.alpha = 0;
        toViewController.view.transform = CGAffineTransformInvert (travel);
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:kDamping initialSpringVelocity:kInitialSpringVelocity options:0x00 animations:^{
            fromViewController.view.transform = travel;
            fromViewController.view.alpha = 0;
            toViewController.view.transform = CGAffineTransformIdentity;
            toViewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            fromViewController.view.transform = CGAffineTransformIdentity;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }

    @end


Note that even if the view frames haven’t been set to reflect the positional relationships, the code would still work, though it would always transition in the same direction. This class can therefore still be used in other codebases.

需要注意的一点是，上面的代码没有通过设置视图的frame来反应它们之间的位置关系，但是代码仍然可以正常工作，只不过转场总是在同一个方向上。因此，这个类也可以被其他的代码库使用。


The transition animation now looks like this:

![Stage 3: third-party animation]({{site.images_path}}/issue-12/2014-05-01-custom-container-view-controller-transitions-stage-3.gif)

转场动画现在看起来如下所示:

![Stage 3: third-party animation](http://img.objccn.io/issue-12/2014-05-01-custom-container-view-controller-transitions-stage-3.gif)


In the code with the [stage-3](https://github.com/objcio/issue-12-custom-container-transitions/tree/stage-3) tag, setting the delegate in the app delegate has been [commented out](https://github.com/objcio/issue-12-custom-container-transitions/blob/stage-3/Container%20Transitions/AppDelegate.m#L41) in order to see the default animation in action. Set it back in to use `Animator` again. You may want to check out the [full diff against stage-2](https://github.com/objcio/issue-12-custom-container-transitions/compare/stage-2...stage-3).

为了看看默认的动画，在[阶段-3](https://github.com/objcio/issue-12-custom-container-transitions/tree/stage-3) 的代码中, 在app delegate中设置代理的部分被 [注释掉了](https://github.com/objcio/issue-12-custom-container-transitions/blob/stage-3/Container%20Transitions/AppDelegate.m#L41) 。 你可以将其设置回再使用 `Animator`类。 你可能想查看 [同阶段－2相比所有的修改](https://github.com/objcio/issue-12-custom-container-transitions/compare/stage-2...stage-3)。


We now have a self-contained `ContainerViewController` with a nicely animated default transition that developers can override with their own, iOS 7 custom animation controller (`UIViewControllerAnimatedTransitioning`) objects – even without needing access to our source code.

我们现在有一个提供了默认转场动画的 `ContainerViewController` 类，这个默认的转场动画可以被开发者自己定义的iOS 7 自定义动画控制器 (`UIViewControllerAnimatedTransitioning`) 的对象代替，甚至都可以不用关心我们的源代码就可以方便的替换。

## Conclusion
## 结论


In this article we looked at making our custom container view controller a first-class UIKit citizen by integrating it with the Custom View Controller Transitions, new in iOS 7.

在本文中我们通过使用iOS 7提供的自定义视图控制器转场的新特性，使我们自定义的视图控制器容器(container view controller)成为了UIKit的一等公民。


This means you can apply your own non-interactive transition animation to our custom container view controller. We saw that because we could take an existing transition class, from seven issues ago, and plug it right in – without modification.

这意味着你可以把自定义的非交互式的转场动画(transition animation)应用到自定义的视图控制器容器(container view controller)中。你可以看到我们把7个话题前使用的转场类直接拿过来使用，而且没有做任何修改。
><span class="secondary radius label">译者注</span> 即[issue #5](http://www.objc.io/issue-5/)中的[View Controller 转场](http://www.objc.io/issue-5/view-controller-transitions.html)中的`Animator`类。

This is perfect if you are distributing your custom container view controller as part of a library or framework, or just want your code to be reusable.

如果你想让自己的容器视图控制器作为一个类库或者框架，或者仅仅想使你的代码得到更好的复用，这将是非常好的。

Note that we only support non-interactive transitions so far. The next step is supporting interactive transitions as well.

我们现在仅仅支持非交互式的转场，下一步就是对交互式的转场也提供支持。

I will leave that as an exercise for you. It is somewhat more complex because we are basically mimicking the framework behavior, which is all guesswork, really.

我把它留给你当作一个练习。它有一些复杂，因为我们基本上是要模仿系统的行为，而这真的全是猜测性的工作。

## Further Indulgence
## 扩展资料

- iOS 7 Tech Talks Videos, 2014: [“Architecting Modern Apps, Part 1”](https://developer.apple.com/tech-talks/videos/index.php?id=3#3) (07:23-31:27)
- Full code on [GitHub](https://github.com/objcio/issue-12-custom-container-transitions).
