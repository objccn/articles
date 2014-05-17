在2007年，斯蒂芬乔布斯在第一次介绍iPhone的时候，iPhone的触摸屏交互简直就像是一种魔法。最好的例子就是在他[第一次滑动TableView的展示上](https://www.youtube.com/watch?v=t4OEsI0Sc_s&t=16m9s)。你可以感受到当时观众的反应是多么惊讶，但是对于现在的我们来说早已习以为常。在展示的后面一部分，他特别指出当他给别人看了这个滑动例子，别人说的一句话: [“当这个界面滑动的时候我就已经被征服了”](https://www.youtube.com/watch?v=t4OEsI0Sc_s&t=16m9s).

是什么样的滑动能让人有‘哇哦’的效果呢？

滑动是最完美地展示了通过触摸屏直接操作的例子。滚动视图遵从于你的手指，当你的手指离开屏幕的时它，视图会自然地继续滑动直到该停止的时候停止。它用自然的方式减速，甚至在快到界限的时候也能表现出细腻的弹力效果。

##动画的状态

在iOS中的大部分动画仍然没有按照最初iPhone指定的滑动标准实现。这里有很多动画一旦他们运行就不能交互（比如说解锁动画，主界面中打开文件夹和关闭文件夹的动画，和导航栏切换的动画，还有很多）。

然而现在有一些apps给我一种始终在控制动画的体验，我们可以直接操作那些我在用的动画。当我们将这些应用和其他的应用相比较之后，我们就能感觉到明显的区别。这些应用中最优秀的有最初的Twitter iPad app， 和现在的facebook paper。但目前，使用直接操作为主并且可以中断动画的应用仍然很少。这就给我们做出更好的应用提供了机会，让我们的应用有更不同的，更高质量的体验。

##真实交互式动画的挑战

当我们用UIView 或者 CAAnimation 来实现交互式动画时会有两个大问题: 这些动画会将屏幕上的试图和layer上的实际动画内容分离开来，并且他们直接操作这些实际动画内容。

###分离模型和表示

Core Animation 是通过分离layer的模型和屏幕上的界面(表示层)的方式来实现，这就导致我们很难去创建一个可以在任何时候能交互的动画，因为在动画时，模型和界面已经不能匹配了。这时，我们不得不通过手动的方式来同步这两个的状态，来达到改变动画的效果:


    view.layer.center = view.layer.presentationLayer.center;
    [view.layer removeAnimationForKey:@"animation"];
    // 添加新动画


###直接控制 vs 间接控制

更大的问题是`CAAnimation` 是直接在实际动画层上进行操作的。这意味着什么呢？比如我们想指定一个layer从坐标为（100，100）的位置运动到（300，300）的位置，但是我突然在它运动到中间的时候，我们想它停下来并且让它回到它原来的位置，如果用CAAnimation来实现的话这个过程就非常复杂了。如果你只是简单地删除当前的动画然后再添加一个新的，那么这个layer的速率就会不连续。

![image](http://www.objc.io/images/issue-12/abrupt.png)

我们想要的只不过是一个漂亮的，流畅地减速和加速的动画。

![image](http://www.objc.io/images/issue-12/smooth.png)

只有通过间接操作动画才能达到上面的效果，比如通过模拟力在界面上的表现。新的动画需要用layer的当前速率矢量作为参数传入来达到流畅的效果。

看一下UIView 中关于spring animations 的动画API （`animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:`），你会注意到这个速率是个CGFloat。所以当我们给一个动画运动的方向上加一个初始的速率，这个动画根本不知道这个速率是在界面的哪个位置开始的，就好像我们现在沿着新动画方向的垂直方向移动。为了使这个方式成为可能，这个速率需要用矩形来表示。

##解决方案

让我们看一下我们怎样来实现一个可交互并且可以中断的动画。为了实现这个效果，我们要做一个类似于控制中心板的东西:

<video controls="1" style="display:block;max-width:100%;height:auto;border:0;">
  <source src="http://www.objc.io/images/issue-12/interactive-animation.mov">
</video>

这个控制板有两个状态：打开和关闭。你可以通过点击来切换这两个状态，或者通过上下拖动来调调整它向上或向下。我要将这个控制板中每个东西都做到可以交互，甚至是在动画的过程中也可以，这是一个很大的挑战。比如，当你在这个控制板还没有切换到打开状态的动画过程中，你点击了它，那么它应该从现在这个点的位置马上回到关闭状态的位置。在现在很多的应用中，大部分都是用默认的动画API，你必须要等一个动画结束之后你才能做自己想做的事情。或者，你不需要等，但是你会看到一个不连续的速率曲线。我们要解决这个问题。

###UIKit 力学

随着iOS7的发布，苹果向我们展示了一个叫UIKit 力学的动画框架(可以参见WWDC 2013 sessions [206](https://developer.apple.com/videos/wwdc/2013/index.php?id=206) and [221](https://developer.apple.com/videos/wwdc/2013/index.php?id=221))。UIKit 力学是一个基于模拟物理引擎的框架，只要你添加指定的行为到动画对象上来实现[UIDynamicItem](https://developer.apple.com/library/ios/documentation/uikit/reference/UIDynamicItem_Protocol/Reference/Reference.html)协议就能实现很多动画。这个框架非常强大并且它能够将很多物体像附着行为和碰撞行为一样结合起来，让我们简单地看一下[动力学目录](https://developer.apple.com/library/ios/samplecode/DynamicsCatalog/Introduction/Intro.html)，看看有什么可以给我们启发。

因为UIKit动力学中的的动画是被间接驱动的，就像我在上面提到的，这为我们实现真实的交互式动画成为可能，它能在任何时候被中断并且可以展示流畅的动画。同时，UIKit动力学在物理层的抽象上能完全胜任我们一般情况下在用户界面中的所需要的所有动画。其实在大部分情况下，我们只会用到其中的一小部分功能。

####定义行为

为了实现我们的控制板的行为，我们将使用UIkit动力学中的两个不同行为:[UIAttachmentBehavior](https://developer.apple.com/library/ios/documentation/uikit/reference/UIAttachmentBehavior_Class/Reference/Reference.html) 和 [UIDynamicItemBehavior](https://developer.apple.com/library/ios/documentation/uikit/reference/UIDynamicItemBehavior_Class/Reference/Reference.html)。这个连接行为用来实现弹簧行为，拖动我们的界面会朝向它的目标点运动。在另一方面，我们用动态item behvaior定义了界面的内置属性，像它的摩擦系数。

我创建了一个我们自己的行为子类，并将这两个行为封装到我们的控制板上:

    @interface PaneBehavior : UIDynamicBehavior

    @property (nonatomic) CGPoint targetPoint;
    @property (nonatomic) CGPoint velocity;

    - (instancetype)initWithItem:(id <UIDynamicItem>)item;

    @end

我们通过一个dynamic item 来初始化这个行为，然后就可以设置他的目标点和我们想要的任何速率。再深入的话，我们创建了连接行为和dynamic item 行为，并且将这些行为添加到我们自定义的行为中:

    - (void)setup
    {
        UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.item attachedToAnchor:CGPointZero];
        attachmentBehavior.frequency = 3.5;
        attachmentBehavior.damping = .4;
        attachmentBehavior.length = 0;
        [self addChildBehavior:attachmentBehavior];
        self.attachmentBehavior = attachmentBehavior;
        
        UIDynamicItemBehavior *itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.item]];
        itemBehavior.density = 100;
        itemBehavior.resistance = 10;
        [self addChildBehavior:itemBehavior];
        self.itemBehavior = itemBehavior;
    }


为了用`targetPoint` 和 `velocity`来影响这些dynamic item的behavior，我们需要重写他们的setters方法，并且修改在连接行为中对应的property和还有item behaviors。我们对目标点的Setter方法做了简单的修改:

    - (void)setTargetPoint:(CGPoint)targetPoint
    {
        _targetPoint = targetPoint;
        self.attachmentBehavior.anchorPoint = targetPoint;
    }

对于`velocity`这个property，我们需要多做一些工作，因为dynamic item behavior 只允许改变相对速度。这就意味如果我们要设置这个`velocity`为绝对值，首先我们就需要得到当前的速度，然后再加上速度差才能得到我们的目标速度。

    - (void)setVelocity:(CGPoint)velocity
    {
        _velocity = velocity;
        CGPoint currentVelocity = [self.itemBehavior linearVelocityForItem:self.item];
        CGPoint velocityDelta = CGPointMake(velocity.x - currentVelocity.x, velocity.y - currentVelocity.y);
        [self.itemBehavior addLinearVelocity:velocityDelta forItem:self.item];
    }

###将Behavior投入使用

我们的控制板有三个不同状态：在结束位置的静止状态，被用户拖动的状态和在没有用户控制时运动到结束位置的动画状态。

我们还有很多其他的事要做才能将从直接操作状态（用户拖动这个滑动板）过渡到动画状态这个过程做的流畅。但用户停止拖动控制板时，它会发送一个消息到它的delegate。根据这个方法，我们可以知道这个板应该朝哪个方向运动，然后在结束位置上添加我们自定义的`PaneBehavior`，为了确保从拖动操作到动画状态这个过程能够非常流畅，我们需要给它一个初始速度，这一点非常重要。

    - (void)draggableView:(DraggableView *)view draggingEndedWithVelocity:(CGPoint)velocity
    {
        PaneState targetState = velocity.y >= 0 ? PaneStateClosed : PaneStateOpen;
        [self animatePaneToState:targetState initialVelocity:velocity];
    }

    - (void)animatePaneToState:(PaneState)targetState initialVelocity:(CGPoint)velocity
    {
        if (!self.paneBehavior) {
            PaneBehavior *behavior = [[PaneBehavior alloc] initWithItem:self.pane];
            self.paneBehavior = behavior;
        }
        self.paneBehavior.targetPoint = [self targetPointForState:targetState];
        if (!CGPointEqualToPoint(velocity, CGPointZero)) {
            self.paneBehavior.velocity = velocity;
        }
        [self.animator addBehavior:self.paneBehavior];
        self.paneState = targetState;
    }

一旦用户用他的手指再次触动控制板时，我必须要将所有的dynamic behavior从animator删除，这样控制板才能响应拖动手势:


    - (void)draggableViewBeganDragging:(DraggableView *)view
    {
        [self.animator removeAllBehaviors];
    }

我不仅仅允许控制板可以被拖动，还要允许它可以被点击，让它可以从一个位置跳转到另一个位置以达到开关的效果。一旦点击事件发生，我们就会立即调整这个滑动板的目标位置。因为我们不能直接控制动画，但是通过弹力和摩擦力，我们的动画可以非常流畅地执行这个动作：

    - (void)didTap:(UITapGestureRecognizer *)tapRecognizer
    {
        PaneState targetState = self.paneState == PaneStateOpen ? PaneStateClosed : PaneStateOpen;
        [self animatePaneToState:targetState initialVelocity:CGPointZero];
    }

这样就实现了我们的大部分功能了。你可以在[GitHub](https://github.com/objcio/issue-12-interactive-animations-uidynamics)上查看完整的例子。

重申一点：UIKit 动力学可以通过在界面上模拟力来间接地驱动动画（我们的例子中，使用的是弹力和摩擦力）。这就使我们在流畅动画的过程中与界面交互成为可能。

现在我们已经通过UIKit 动力学来实现了整个交互，让我们回顾一下这个场景。这个例子的动画中我们只用了UIkit动力学中一小部分功能，并且它的实现方式也非常简单。对于我们来说这是一个去理解它其中的过程的很好的例子，但是如果我们使用的环境中没有UIKit 动力学（比如说在Mac上）或者你的使用场景中不能很好的适用UIkit动力学呢。

##自己操作动画

至于在你的应用中大部分时间会用的动画，比如简单的弹力动画，我们控制它真的不难。我们可以做一个练习，通过举起一个使用UIKit动力学的巨大黑色箱子，看它是如何实现简单的手动交互。这个想法非常简单：我们只要每秒修改这个黑色箱子的frame。每次修改箱子的frame时，我们都要基于当前的速率和当前作用在箱子上的力来调整箱子的frame。

###物理原理

首先让我们看一下我们需要知道的基础物理知识，这样我们才能实现刚才使用UIKit动力学实现的弹力动画效果。特别指出的是，我们先实现一维的情况（在我们的例子中就是这样的情况）因为直接介绍第二维会很难消化。

这个对象是用来计算控制板的新位置，而新位置是基于控制板的当前位置和从上一次动画开始到现在的时间来决定的。我们可以把它表示成这样：

    y = y0 + Δy

这个位置的偏移量可以通过速率和时间的函数来表达：

    Δy = v ⋅ Δt

这个速率可以通过前一次的速率加上速率偏移量算出来，这个速率是由力在界面上的作用引起的。

    v = v0 + Δv

速率的变化可以通过作用在这个界面上的作用力计算出来：

    Δv = (F ⋅ Δt) / m

现在，让我们看一下作用在这个界面上的力。为了得到弹力效果，我们必须要将摩擦力和弹力结合起来：

    F = F_spring + F_friction

弹力的计算方法我们可以从任何一本教科书中得到：

    F_spring = k ⋅ x

k是弹力系数，x是界面到目标结束位置的距离（也就是弹力的长度）。因此，我们可以把它写成这样：

    F_spring = k ⋅ abs(y_target - y0)

摩擦力和速率成正比：

    F_friction = μ ⋅ v

μ是一个简单的摩擦系数。你可以通过别的方式来计算摩擦力，但是这个方法能很好地做出我们想要的动画效果。

将上面的表达式放在一起，我们就可以算出作用在界面上的力：

    F = k ⋅ abs(y_target - y0) + μ ⋅ v

为了实现起来更简单点些，我们将view的质量设为1，这样我们就能计算在一维上的变化：

    Δy = (v0 + (k ⋅ abs(y_target - y0) + μ ⋅ v) ⋅ Δt) ⋅ Δt

###实现动画

为了实现这个动画，我们首先需要创建我们自己的`Animator`类，它将扮演驱动动画的角色。这个类使用了`CADisplayLink`，`CADisplayLink`是指定在渲染时同步屏幕的刷新频率的定时器。换句话说，如果你的动画是流畅的，这个定时器就会每秒调用你的方法60次。接下来，我们需要实现`Animation`协议来和我们的`Animator`一起工作。这个协议只有一个方法，`animationTick:finished:`。屏幕每次被刷新时都会调用这个方法，并且在方法中会得到两个参数：第一个参数是前一个frame的持续时间，第二个参数是一个bool值，当我们设置这个bool值为YES时，我们就可以又回到我们刚才已经结束动画的`Animator`:

    @protocol Animation <NSObject>
    - (void)animationTick:(CFTimeInterval)dt finished:(BOOL *)finished;
    @end


我们会在下面实现这个方法。首先，根据时间间隔我们来计算由弹力和摩擦力的相结合的力。然后根据速率来更新这个力，再调整界面的中心位置。最后，当这个界面开始减速并且即将到达结束位置时，我们就停止这个动画：

    - (void)animationTick:(CFTimeInterval)dt finished:(BOOL *)finished
    {
        static const float frictionConstant = 20;
        static const float springConstant = 300;
        CGFloat time = (CGFloat) dt;

        //摩擦力 = 速率 * 摩擦系数
        CGPoint frictionForce = CGPointMultiply(self.velocity, frictionConstant);
        //弹力 = (目标位置 - 当前位置) * 弹力系数
        CGPoint springForce = CGPointMultiply(CGPointSubtract(self.targetPoint, self.view.center), springConstant);
        //力 = 弹力 - 摩擦力
        CGPoint force = CGPointSubtract(springForce, frictionForce);

        //速率 = 当前速率 + 力 * 时间 / 质量
        self.velocity = CGPointAdd(self.velocity, CGPointMultiply(force, time));
        //位置 = 当前位置 + 速率 * 时间
        self.view.center = CGPointAdd(self.view.center, CGPointMultiply(self.velocity, time));

        CGFloat speed = CGPointLength(self.velocity);
        CGFloat distanceToGoal = CGPointLength(CGPointSubtract(self.targetPoint, self.view.center));
        if (speed < 0.05 && distanceToGoal < 1) {
            self.view.center = self.targetPoint;
            *finished = YES;
        }
    }

这就是这个方法里的全部内容。我们把这个方法封装到一个SpringAnimation对象中。除了这个方法之外，这个对象中还有一个初始化方法，他指定了界面中心的目标位置（在我们的例子中，就是打开状态时界面的中心位置，或者关闭状态时界面的中心位置）和初始的速率。

###将动画添加到界面上

我们的界面类刚好和使用UIDynamic的例子一样：它有一个拖动手势，并且根据拖动手势来更新中心位置。它也有两个同样的delegate方法，这两个方法会实现动画的初始化。首先，一旦用户开始拖动控制板时，我们就取消所有动画：

    - (void)draggableViewBeganDragging:(DraggableView *)view
    {
        [self cancelSpringAnimation];
    }

一旦停止拖动，我们就根据从拖动手势中得到的最后一个速率值来开始我们的动画。我们根据拖动状态计算出动画的结束位置：

    - (void)draggableView:(DraggableView *)view draggingEndedWithVelocity:(CGPoint)velocity
    {
        PaneState targetState = velocity.y >= 0 ? PaneStateClosed : PaneStateOpen;
        self.paneState = targetState;
        [self startAnimatingView:view initialVelocity:velocity];
    }

    - (void)startAnimatingView:(DraggableView *)view initialVelocity:(CGPoint)velocity
    {
        [self cancelSpringAnimation];
        self.springAnimation = [UINTSpringAnimation animationWithView:view target:self.targetPoint velocity:velocity];
        [view.animator addAnimation:self.springAnimation];
    }

剩下来要做的就是添加点击动画了，这很简单。一旦我们触发这个状态，就开始动画。如果这里有个弹力动画，我们就用速率来启动它。如果这个弹力动画是nil，那么这个开始速率就是CGPointZero。想要知道为什么这个动画依然会有，就去看`animationTick:finished:`里的代码。当这个起始速率为0的时候，弹力就会使速率缓慢地增长，直到拖动到结束位置：

    - (void)didTap:(UITapGestureRecognizer *)tapRecognizer
    {
        PaneState targetState = self.paneState == PaneStateOpen ? PaneStateClosed : PaneStateOpen;
        self.paneState = targetState;
        [self startAnimatingView:self.pane initialVelocity:self.springAnimation.velocity];
    }

###动画驱动者

最后，我们需要一个Animator，也就是动画的驱动者。Animator是displayLink的封装者。因为每个displayLink都链接一个指定的`UIScreen`。我们根据这个指定的UIScreen来初始化我们的Animator。我们初始化一个DisplayLink，并且将它加入到RunLoop。因为现在还没有动画，所以我们是停止状态开始的：

    - (instancetype)initWithScreen:(UIScreen *)screen
    {
        self = [super init];
        if (self) {
            self.displayLink = [screen displayLinkWithTarget:self selector:@selector(animationTick:)];
            self.displayLink.paused = YES;
            [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
            self.animations = [NSMutableSet new];
        }
        return self;
    }

一旦我们添加了这个动画，我们就肯定这个DisplayLink已经不再是停止状态：

    - (void)addAnimation:(id<Animation>)animation
    {
        [self.animations addObject:animation];
        if (self.animations.count == 1) {
            self.displayLink.paused = NO;
        }
    }

我们创建了这个DisplayLink来调用`animationTick:`方法，在每个Tick中，我们都遍历它的动画数组，并且给这些动画数组中的每个动画发送一个消息。如果这个动画数组中已经没有动画了，我们就停止这个DisplayLink。

     - (void)animationTick:(CADisplayLink *)displayLink
     {
         CFTimeInterval dt = displayLink.duration;
         for (id<Animation> a in [self.animations copy]) {
             BOOL finished = NO;
             [a animationTick:dt finished:&finished];
             if (finished) {
                 [self.animations removeObject:a];
             }
         }
         if (self.animations.count == 0) {
             self.displayLink.paused = YES;
         }
     }

完整的项目在[GitHub](https://github.com/objcio/issue-12-interactive-animations)中。

###权衡

我们是通过DisplayLink在系统的权衡下来驱动动画，记住这一点非常重要（就像我们刚才演示的例子，或者我们使用UIkit动力学来做的例子，或者像Facebook的Pop框架。就像[Andy Matuschar指出的](https://twitter.com/andy_matuschak/status/464790108072206337)UIView和CAAnimation动画比其他任务更少受系统的影响，因为在你的应用中渲染处于更高的优先级。

##回到Mac

现在Mac中还没有UIKit动力学。如果你想在Mac中创建一个真实的交互式动画，你必须自己去实现这些动画。我们已经向你展示了如何在iOS中实现这些动画，所以在OS X中实现相似的功能也是非常简单的。你可以查看在GitHub中的[完整项目](https://github.com/objcio/issue-12-interactive-animations-osx)，如果你想要应用到OS X中，这里还有一些地方需要修改：

- 第一个要修改的就是Animator。在Mac中没有`CADisplayLink`，但是取而代之的有`CVDisplayLink`，它是以C语言为基础的API。创建它需要做更多的工作，但也是很简单。

- iOS中的弹力动画是基于调整界面的中心位置来实现的。而OS X中的`NSView`类没有中心点这个property，所以我们用fram中的origin来代替。

- 在Mac中是没有手势识别，所以我要在我们自定义的View子类中实现`mouseDown:`, `mouseUp:`, 和 `mouseDragged`方法。

上面就是我们需要在Mac中使用我们的动画效果在代码所需要做的修改。对于像这样的简单界面，它能很好的胜任。但对于更复杂的动画，你可能就不会想通过改变界面的frame来实现了，我们可以用transform来代替，浏览Jonathan Willing写的关于[OS X动画](http://jwilling.com/osx-animations)的以前博客你会获益良多。

###Facebook的POP框架

上个星期围绕着Facebook的[POP框架](https://github.com/facebook/pop)讨论络绎不绝。POP框架是Paper应用背后支持的动画引擎。它的操作非常像我们上面讲的驱动动画的例子，但是它封装到一个非常灵巧的程序包中。

让我们动手用Pop来驱动我们的动画吧。因为我们自己的类中已经封装了弹力动画，但这些改变和POP相比真的微不足道了。接下来我们所要做的就是用一个POP动画来代替我们刚才做的动画，将下面这段代码加入到界面类中：

    - (void)animatePaneWithInitialVelocity:(CGPoint)initialVelocity
    {
        [self.pane pop_removeAllAnimations];
        POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewCenter];
        animation.velocity = [NSValue valueWithCGPoint:initialVelocity];
        animation.toValue = [NSValue valueWithCGPoint:self.targetPoint];
        animation.springSpeed = 15;
        animation.springBounciness = 6;
        [self.pane pop_addAnimation:animation forKey:@"animation"];
        self.animation = animation;
    }

你可以在[GitHub](https://github.com/objcio/issue-12-interactive-animations-pop)中找到使用POP框架的完整例子。

使用它非常简单，并且通过它我们可以实现很多更复杂的动画。但是它真正强大的地方在于它能够实现真正的可交互和可中断的动画，就像我们上面提到的那样，因为它支持以速率作为参数来满足需求。如果你打算从一开始到被中断这过程中的任何时候都能交互，像POP这样的框架就能帮你实现这些动画，并且它能始终保持动画的流畅性。

如果你不满足于用`POPSpringAnimation`和`POPDecayAnimation`来处理的话，POP来还提供了`POPCustomAnimation`类，它在每次动画Tick时会调用一个回调block来实现用封装的DisplayLink驱动动画的转变。

##展望未来

随着iOS7中从对拟物化的关注转变到如今对交互行为的关注，真实交互式动画通向未来的大道变得越来越明显。我们还有很多方法可以将最初iPhone中滑动行为的魔力延伸到交互的每个方面。为了让这些魔力成为现实，我们就不能在开发过程中才想到这些动画，而是应该在设计时就要考虑这些交互，这一点非常重要。

非常感谢[Loren Brichter](https://twitter.com/lorenb)给这篇文章提出的一些意见。


[话题12下的更多文章](http://objccn.io/issue-12/)

原文 [Interactive Animations](http://www.objc.io/issue-12/interactive-animations.html)
