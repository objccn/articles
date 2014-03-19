[Source](http://www.objc.io/issue-5/view-controller-transitions.html "Permalink to View Controller Transitions - iOS 7 - objc.io issue #5 ")

# View Controller Transitions - iOS 7 - objc.io issue #5 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# View Controller Transitions

[Issue #5 iOS 7][4], October 2013

By [Chris Eidhof][5]

## Custom Animations

One of the most exciting iOS 7 features for me is the new View Controller Transitioning API. Before iOS 7, I would also create custom transitions between view controllers, but doing this was not really supported, and a bit painful. Making those transitions interactive, however, was harder.

Before we continue with the article, I’d like to issue a warning: this is a very new API, and while we normally try to write about best practices, there are no clear best practices yet. It’ll probably take a few months, at least, to figure them out. This article is not so much a recommendation of best practices, but rather an exploration of a new feature. Please contact us if you find out better ways of using this API, so we can update this article.

Before we look at the API, note how the default behavior of navigation controllers in iOS 7 changed: the animation between two view controllers in a navigation controller looks slightly different, and it is interactive. For example, to pop a view controller, you can now pan from the left edge of the screen and interactively drag the current view controller to the right.

That said, let’s have a look at the API. What I found interesting is the heavy use of protocols and not concrete objects. While it felt a bit weird at first, I prefer this kind of API. It gives us as programmers much more flexibility. First, let’s try to do a very simple thing: having a custom animation when pushing a view controller in a navigation controller (the [sample project][6] for this article is on github). To do this, we have to implement one of the new `UINavigationControllerDelegate` methods:


    - (id)
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

We can look at the kind of operation (either push or pop) and return a different animator based on that. Or, if we want to share code, it might be the same object, and we might store the operation in a property. We might also create a new object for each operation. There’s a lot of flexibility here.

To perform the animation, we create a custom object that implements the `UIViewControllerAnimatedTransitioning` protocol:


    @interface Animator : NSObject 

    @end

The protocol requires us to implement two methods, one for the animation duration:


    - (NSTimeInterval)transitionDuration:(id )transitionContext
    {
        return 0.25;
    }

and one that performs the animation:


    - (void)animateTransition:(id)transitionContext
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

Here, you can see how the protocols are used: instead of giving a concrete object with properties, this methods gets a transition context that is of type `id`. The only thing that’s extremely important, is that we call `completeTransition:` after we’re done with the animation. This tells the animation context that we’re done and updates the view controller’s state accordingly. The other code is standard; we ask the transition context for the two view controllers, and just use plain `UIView` animations. That’s really all there is to it, and now we have a custom zooming animation.

Note that we only have specified a custom transition for the push animation. For the pop animation, iOS falls back to the default sliding animation. Also, by implementing this method, the transition is not interactive anymore. Let’s fix that.

## Interactive Animations

Making this animation interactive is really simple. We need to override another new navigation controller delegate method:


    - (id )navigationController:(UINavigationController*)navigationController
                              interactionControllerForAnimationController:(id )animationController
    {
        return self.interactionController;
    }

Note that, in a non-interactive animation, this will return nil.

The interaction controller is an instance of `UIPercentDrivenInteractionTransition`. No further configuration or setup is necessary. We create a pan recognizer, and here’s the code that handles the panning:


    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (location.x >  CGRectGetMidX(view.bounds)) {
            navigationControllerDelegate.interactionController = [[UIPercentDrivenInteractiveTransition alloc] init];
            [self performSegueWithIdentifier:PushSegueIdentifier sender:self];
        }
    }

Only when the user is on the right-hand side of the screen, do we set the next animation to be interactive (by setting the `interactionController` property). Then we just perform the segue (or if you’re not using storyboards, push the view controller). To drive the transition, we call a method on the interaction controller:


    else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGFloat d = (translation.x / CGRectGetWidth(view.bounds)) * -1;
        [interactionController updateInteractiveTransition:d];
    }

This will set the percentage based on how much we have panned. The really cool thing here is that the interaction controller cooperates with the animation controller, and because we used a normal `UIView` animation, it controls the progression of the animation. We don’t need to connect the interaction controller to the animation controller, as all of this happens automatically in a decoupled way.

Finally, when the gesture recognizer ends or is canceled, we need to call the appropriate methods on the interaction controller:


    else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if ([panGestureRecognizer velocityInView:view].x < 0) {
            [interactionController finishInteractiveTransition];
        } else {
            [interactionController cancelInteractiveTransition];
        }
        navigationControllerDelegate.interactionController = nil;
    }

It’s important that we set the interaction controller to nil after the transition was completed or cancelled. If the next transition is non-interactive, we don’t want to return our old interaction controller.

Now we have a fully interactive custom transition. Using just plain gesture recognizers and a concrete object provided by UIKit, we achieve this in only a few lines of code. For most custom transitions, you can probably stop reading here and do everything with the methods described above. However, if you want to have completely custom animations or interactions, this is also possible. We’ll look at that in the next section.

## Custom Animation Using GPUImage

One of the cool things we can do now is completely custom animations, bypassing UIView and even Core Animation. Just do all the animation yourself, [Letterpress-style][7]. In a first attempt, I did this with Core Image, however, on my old iPhone 4 I only managed to get around 9 FPS, which is definitely too far off the 60 FPS I wanted.

However, after bringing in [GPUImage][8], it was simple to have a custom animation with really nice effects. The animation we want is pixelating and dissolving the two view controls into each other. The approach is to take a snapshot of the two view controllers, and apply GPUIImage’s image filters on the two snapshots.

First, we create a custom class that implements both the animation and interactive transition protocols:


    @interface GPUImageAnimator : NSObject
      

    @property (nonatomic) BOOL interactive;
    @property (nonatomic) CGFloat progress;

    - (void)finishInteractiveTransition;
    - (void)cancelInteractiveTransition;

    @end

To make the animations perform really fast, we want to upload the images to the GPU once, and then do all the processing and drawing on the GPU, without going back to the CPU (the data transfer will be very slow). By using a GPUImageView, we can do the drawing in OpenGL (without having to do manual OpenGL code; we can keep writing high-level code).

Creating the filter chain is very straightforward. Have a look at `setup` in the sample code to see how to do it. A bit more challenging is animating the filters. With GPUImage, we don’t get automatic animation, so we want to update our filters at each frame that’s rendered. We can use the `CADisplayLink` class to do this:


    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(frame:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

In the `frame:` method, we can update our progress based on how much time has elapsed, and update the filters accordingly:


    - (void)frame:(CADisplayLink*)link
    {
        self.progress = MAX(0, MIN((link.timestamp - self.startTime) / duration, 1));
        self.blend.mix = self.progress;
        self.sourcePixellateFilter.fractionalWidthOfAPixel = self.progress *0.1;
        self.targetPixellateFilter.fractionalWidthOfAPixel = (1- self.progress)*0.1;
        [self triggerRenderOfNextFrame];
    }

And that’s pretty much all we need to do. In case of interactive transitions, we need to make sure that we set the progress based on our gesture recognizer, not based on time, but the rest of the code is pretty much the same.

This is really powerful, and you can use any of the existing filters in GPUImage, or write your own OpenGL shaders to achieve this.

## Conclusion

We only looked at animating between two view controllers in a navigation controller, but you can do the same for tab bar controllers or your own custom container view controllers. Also, the `UICollectionViewController` is now extended in such a way that you can automatically and interactively animate between layouts, using the same mechanism. This is really powerful.

When talking to [Orta][9] about this API, he mentioned that he already uses it a lot to create lighter view controllers. Instead of managing state within your view controller, you can just create a new view controller and have a custom animation between the two, moving views between the two view controllers during the transition.

## More Reading

  * [WWDC: Custom Transitions using View Controllers][10]
  * [Custom UIViewController transitions][11]
  * [iOS 7: Custom Transitions][12]
  * [Custom View Controller Transitions with Orientation][13]




* * *

[More articles in issue #5][14]

  * [Privacy policy][15]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-5/index.html
   [5]: http://twitter.com/chriseidhof
   [6]: https://github.com/objcio/issue5-view-controller-transitions
   [7]: http://www.macstories.net/featured/a-conversation-with-loren-brichter/
   [8]: https://github.com/BradLarson/GPUImage
   [9]: https://twitter.com/orta
   [10]: http://asciiwwdc.com/2013/sessions/218
   [11]: http://www.teehanlax.com/blog/custom-uiviewcontroller-transitions/
   [12]: http://www.doubleencore.com/2013/09/ios-7-custom-transitions/
   [13]: http://whoisryannystrom.com/2013/10/01/View-Controller-Transition-Orientation/
   [14]: http://www.objc.io/issue-5
   [15]: http://www.objc.io/privacy.html
