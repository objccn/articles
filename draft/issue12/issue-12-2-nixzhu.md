---
layout: post
title:  "Animating Custom Layer Properties 自定义 Layer 属性的动画"
category: "12"
date: "2014-05-08 10:00:00"
tags: article
author: "<a href=\"http://twitter.com/nicklockwood\">Nick Lockwood</a>"
---

By default, almost every standard property of `CALayer` and its subclasses can be animated, either by adding a `CAAnimation` to the layer (explicit animation), or by specifying an action for the property and then modifying it (implicit animation).

默认情况下，`CALayer` 及其子类的绝大部分标准属性都可以执行动画，无论是添加一个 `CAAnimation` 到 Layer（显式动画），亦或是为属性指定一个动作然后修改它（隐式动画）。

But sometimes we may wish to animate several properties in concert as if they were a single animation, or we may need to perform an animation that cannot be implemented by applying animations to standard layer properties.

但有时候我们希望能同时为好几个属性添加动画，使它们看起来像是一个动画一样；或者，我们需要执行的动画不能通过使用标准 Layer 属性动画来实现。

In this article, we will discuss how to subclass `CALayer` and add our own properties to easily create animations that would be cumbersome to perform any other way.

在本文中，我们将讨论如何子类化 `CALayer` 并添加我们自己的属性，以便比较容易地创建那些如果以其他方式实现起来会很麻烦的动画效果。

Generally speaking, there are three types of animatable property that we might wish to add to a subclass of `CALayer`:

一般说来，我们希望添加到 `CALayer` 的子类上的可动画属性有三种类型：

* A property that indirectly animates one or more standard properties of the layer (or one of its sublayers). 能间接动画 Layer （或其子类）的一个或多个标准属性的属性。
* A property that triggers redrawing of the layer's backing image (the `contents` property). 能触发 Layer 的支持图像（backing image）（即 `contents` 属性）重绘的属性。
* A property that doesn't involve redrawing the layer or animating any existing properties. 不涉及 Layer 重绘或对任何已有属性执行动画的属性。

## Indirect Property Animation 间接属性动画

Custom properties that indirectly modify other standard layer properties are the simplest of these options. These are really just custom setter methods that convert their input into one or more different values suitable for creating the animation.

能间接修改其它标准 Layer 属性的自定义属性是这些选项中最简单的。它们真的只是自定义 setter 方法以将它们的输入转换为适用于创建动画的一个或多个不同的值。

We don't actually need to write any animation code at all if the properties we are setting already have standard animation actions set up, because if we modify those properties, they will inherit whatever animation settings are configured in the current `CATransaction`, and will animate automatically.

如果被我们设置的属性已经预设好标准动画，那我们完全不需要编写任何实际的动画代码，因为我们修改这些属性后，它们就会继承任何被配置在当前 `CATransaction` 上的动画设置，并且自动执行动画。

In other words, even if `CALayer` doesn't know how to animate our custom property, it can already animate all of the visible side effects that are caused by changing our property, and that's all we care about.

换句话说，即使 `CALayer` 不知道如何对我们自定义的属性进行动画，它依然能对因自定义属性被改变而引起的其它可见副作用进行动画，而这恰好就是我们所关心的全部内容。

To demonstrate this approach, let's create a simple analog clock where we can set the time using a `time` property of type `NSDate`. We'll start by creating our static clock face. The clock consists of three `CAShapeLayer` instances -- a circular layer for the face and two rectangular sublayers for the hour and minute hands:

为了演示这种方法，让我们来创建一个简单的模拟时钟，之后我们可以使用被声明为 `NSDate` 类型 `time` 属性来设置它的时间。我会将从创建一个静态的时钟面盘开始。这个时钟包含三个 `CAShapeLayer` 实例——一个用于时钟面盘的圆形 Layer 和两个用于时针和分针的长方形 Sublayer。

    @interface ClockFace: CAShapeLayer

    @property (nonatomic, strong) NSDate *time;

    @end

    @interface ClockFace ()

    // 私有属性，译者注：这里申明的是 CALayer ，下面分配的却是 CAShapeLayer ，按照文字，应该都是 CAShapeLayer 才对
    @property (nonatomic, strong) CALayer *hourHand;
    @property (nonatomic, strong) CALayer *minuteHand;

    @end

    @implementation ClockFace

    - (id)init
    {
        if ((self = [super init]))
        {
            self.bounds = CGRectMake(0, 0, 200, 200);
            self.path = [UIBezierPath bezierPathWithOvalInRect:self.bounds].CGPath;
            self.fillColor = [UIColor whiteColor].CGColor;
            self.strokeColor = [UIColor blackColor].CGColor;
            self.lineWidth = 4;
            
            self.hourHand = [CAShapeLayer layer];
            self.hourHand.path = [UIBezierPath bezierPathWithRect:CGRectMake(-2, -70, 4, 70)].CGPath;
            self.hourHand.fillColor = [UIColor blackColor].CGColor;
            self.hourHand.position = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
            [self addSublayer:self.hourHand];
            
            self.minuteHand = [CAShapeLayer layer];
            self.minuteHand.path = [UIBezierPath bezierPathWithRect:CGRectMake(-1, -90, 2, 90)].CGPath;
            self.minuteHand.fillColor = [UIColor blackColor].CGColor;
            self.minuteHand.position = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
            [self addSublayer:self.minuteHand];
        }
        return self;
    }
          
    @end
    
We'll also set up a basic view controller with a `UIDatePicker` so we can test our layer (the date picker itself is set up in the Storyboard):

同时我们要设置一个基本的 View Controller ，它包含一个 `UIDatePicker` ，这样我们就能测试我们的 Layer （日期选择器在 Storyboard 里设置）了：

    @interface ViewController ()

    @property (nonatomic, strong) IBOutlet UIDatePicker *datePicker;
    @property (nonatomic, strong) ClockFace *clockFace;

    @end


    @implementation ViewController

    - (void)viewDidLoad
    {
        [super viewDidLoad];
        
        // 添加时钟面板 Layer
        self.clockFace = [[ClockFace alloc] init];
        self.clockFace.position = CGPointMake(self.view.bounds.size.width / 2, 150);
        [self.view.layer addSublayer:self.clockFace];
        
        // 设置默认时间
        self.clockFace.time = [NSDate date];
    }

    - (IBAction)setTime
    {
        self.clockFace.time = self.datePicker.date;
    }

    @end

Now we just need to implement the setter method for our `time` property. This method uses `NSCalendar` to break the time down into hours and minutes, which we then convert into angular coordinates. We then use these angles to generate a `CGAffineTransform` to rotate the hands:

现在我们只需要实现 `time` 属性的 setter 方法。这个方法使用 `NSCalendar` 将时间变为小时和分钟，之后我们将它们转换为角坐标。然后我们就可以使用这些角度去生成两个 `CGAffineTransform` 以旋转时针和分针。

    - (void)setTime:(NSDate *)time
    {
        _time = time;
        
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:time];
        self.hourHand.affineTransform = CGAffineTransformMakeRotation(components.hour / 12.0 * 2.0 * M_PI);
        self.minuteHand.affineTransform = CGAffineTransformMakeRotation(components.minute / 60.0 * 2.0 * M_PI);
    }
    
The result looks like this:

结果看起来像这样：

<img src="{{site.images_path}}/issue-12/clock.gif" width="320px">

You can check out the project for yourself [on GitHub](https://github.com/objcio/issue-12-custom-layer-property-animations).

你可以 [从 GitHub 上](https://github.com/objcio/issue-12-custom-layer-property-animations) 下载这个项目看看。

As you can see, this is really not doing anything clever; we are not actually creating a new animated property, but merely setting several standard animatable layer properties from a single method. So what if we want to create an animation that doesn't map to any existing layer properties?

如你所见，我们实在没有做什么太费脑筋的事情；我们并没有创建一个新的可动画属性，而只是在单个方法里设置了几个标准可动画 Layer 属性而已。因此，如果我们想创建的动画并不能映射到任何已有的 Layer 属性上时，该怎么办呢？

## Animating Layer Contents 动画 Layer 内容

Suppose that instead of implementing our clock face using individual layers, we wanted to draw the clock using Core Graphics. (In general this will have inferior performance, but it's possible to imagine that there are complex drawing operations that we might want to implement that would be hard to replicate using ordinary layer properties and transforms.) How would we do that?

假设不使用几个分离的 Layer 来实现我们的时钟面板，那我们可以改用 Core Graphics 来绘制时钟。（这通常会降低性能，但我们可以假想我们所要实现的效果需要许多复杂的绘图操作，而它们很难用常规的 Layer 属性和 transform 来复制。）我们要怎么做呢？

Much like `NSManagedObject`, `CALayer` has the ability to generate dynamic setters and getters for any declared property. In our current implementation, we've allowed the compiler to synthesize the `time` property's ivar and getter method for us, and we've provided our own implementation for the setter method. But let's change that now by getting rid of our setter and marking the property as `@dynamic`. We'll also get rid of the individual hand layers since we'll now be drawing those ourselves:

很类似 `NSManagedObject` ， `CALayer` 具有为任何被声明的属性生成动态 setter 和 getter 的能力。在当前的实现中，我们是让编译器去合成 `time` 属性的 ivar 和 getter 方法，而我们自己实现了 setter 方法。但让我们来改变一下：丢弃我们的 setter 并将属性标记为 `@dynamic` 。同时我们也丢弃分离的时针和分针 Layer ，因为我们将自己去绘制它们。

译者注：没使用过 `@dynamic` 这样的高级货，心中还有点小激动呢！

    @interface ClockFace ()

    @end


    @implementation ClockFace

    @dynamic time;

    - (id)init
    {
        if ((self = [super init]))
        {
            self.bounds = CGRectMake(0, 0, 200, 200);
        }
        return self;
    }

    @end

Before we do anything else, we need to make one other slight adjustment: Unfortunately, `CALayer` doesn't know how to interpolate `NSDate` properties (i.e. it cannot automatically generate intermediate values between `NSDate` instances, as it can with numeric types and others such as `CGColor` and `CGAffineTransform`). We could keep our custom setter method and have it set another dynamic property representing the equivalent `NSTimeInterval` (which is a numeric value, and can be interpolated), but to keep the example simple, we'll replace our `NSDate` property with a floating-point value that represents hours on the clock, and update the user interface so it uses a simple `UITextField` to set the value instead of a date picker:

在我们开始做事之前，需要先做一个小调整：因为不幸的是，`CALayer` 不知道如何对 `NSDate` 属性进行插值（interpolate）（例如，它不能自动生成 `NSDate` 实例之间的中间值，虽然它可以处理数字类型和其它例如 `CGColor` 和 `CGAffineTransform` 这样的类型）。我们可以保留我们的自定义 setter 方法并用它设置另一个动态属性（它表示等价的 `NSTimeInterval`，这是一个数字值，可以被插值），但为了保持例子的简单性，我们会用一个浮点值替换 `NSDate` 属性来表征时钟的小时，为了更新用户界面，我们使用一个简单的 `UITextField` 来设置浮点值，不再使用日期选择器：

    @interface ViewController () <UITextFieldDelegate>

    @property (nonatomic, strong) IBOutlet UITextField *textField;
    @property (nonatomic, strong) ClockFace *clockFace;

    @end


    @implementation ViewController

    - (void)viewDidLoad
    {
        [super viewDidLoad];
        
        // 添加时钟面板 Layer
        self.clockFace = [[ClockFace alloc] init];
        self.clockFace.position = CGPointMake(self.view.bounds.size.width / 2, 150);
        [self.view.layer addSublayer:self.clockFace];
    }

    - (BOOL)textFieldShouldReturn:(UITextField *)textField
    {
        [textField resignFirstResponder];
        return YES;
    }

    - (void)textFieldDidEndEditing:(UITextField *)textField
    {
        self.clockFace.time = [textField.text floatValue];
    }

    @end
    
Now that we've removed our custom setter method, how are we going to know when our `time` property changes? We need a way to automatically notify the `CALayer` whenever the `time` property changes, so that it can redraw its contents. We do that by overriding the `+needsDisplayForKey:` method, as follows:

现在，既然我们已经移除了自定义的 setter 方法，那我们要如何才能知晓 `time` 属性的改变呢？我们需要一个无论何时 `time` 属性改变时都能自动通知 `CALayer` 的方式，这样它才好重绘它的内容。我们通过覆写 `+needsDisplayForKey:` 方法即可做到这一点，如下：

    + (BOOL)needsDisplayForKey:(NSString *)key
    {
        if ([@"time" isEqualToString:key])
        {
            return YES;
        }
        return [super needsDisplayForKey:key];
    }
    
This tells the layer that whenever the `time` property is modified, it needs to call the `-display` method. We'll now override the `-display` method as well, and add an `NSLog` statement to print out the value of `time`:

这就告诉了 Layer ，无论何时 `time` 属性被修改，它都需要调用 `-display` 方法。现在我们就覆写 `-display` 方法，添加一个 `NSLog` 语句打印出 `time` 的值：

    - (void)display
    {
        NSLog(@"time: %f", self.time);
    }
    
If we set the `time` property to 1.5, we'll see that display is called with the new value:

如果我们设置 `time` 属性为 1.5 ，我们就会看到 `-display` 被调用，打印出新值：

    2014-04-28 22:37:04.253 ClockFace[49145:60b] time: 1.500000

That isn't really what we want though; we want the `time` property to animate smoothly between its old and new values over several frames. To make that happen, we need to specify an animation (or "action") for our time property, which we can do by overriding the `-actionForKey:` method:

但这还不是我们真正想要的；我们希望 `time` 属性能在旧值和新值之间有多个帧长的平滑的过渡动画。为了实现这一点，我们需要为 `time` 属性指定一个动画（或“动作（action）”），而通过覆写 `-actionForKey:` 方法就能做到：

    - (id<CAAction>)actionForKey:(NSString *)key
    {
        if ([key isEqualToString:@"time"])
        {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:key];
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            animation.fromValue = @(self.time);
            return animation;
        }
        return [super actionForKey:key];
    }
    
Now, if we set the `time` property again, we see that `-display` is called multiple times. The number of times should equate to approximately 60 times per second, for the duration of the animation (which defaults to 0.25 seconds, or about 15 frames):

现在，如果我们再次设置 `time` 属性，我们就会看到 `-display` 被多次调用。调用的次数大约为每秒 60 次，至于动画的长度，默认为 0.25 秒，大约是 15 帧：

    2014-04-28 22:37:04.253 ClockFace[49145:60b] time: 1.500000
    2014-04-28 22:37:04.255 ClockFace[49145:60b] time: 1.500000
    2014-04-28 22:37:04.351 ClockFace[49145:60b] time: 1.500000
    2014-04-28 22:37:04.370 ClockFace[49145:60b] time: 1.500000
    2014-04-28 22:37:04.388 ClockFace[49145:60b] time: 1.500000
    2014-04-28 22:37:04.407 ClockFace[49145:60b] time: 1.500000
    2014-04-28 22:37:04.425 ClockFace[49145:60b] time: 1.500000
    2014-04-28 22:37:04.443 ClockFace[49145:60b] time: 1.500000
    2014-04-28 22:37:04.461 ClockFace[49145:60b] time: 1.500000
    2014-04-28 22:37:04.479 ClockFace[49145:60b] time: 1.500000
    2014-04-28 22:37:04.497 ClockFace[49145:60b] time: 1.500000
    2014-04-28 22:37:04.515 ClockFace[49145:60b] time: 1.500000
    2014-04-28 22:37:04.755 ClockFace[49145:60b] time: 1.500000

But for some reason when we log the `time` value at each of these intermediate points, we are still seeing the final value. Why aren't we getting the interpolated values? The reason is that we are looking at the wrong `time` property.

由于某些原因，当我们在每个中间点打印 `time` 值时，我们一直看到的是最终值。为何不能得到插值呢？因为我们查看的是错误的 `time` 属性。

When you set a property of a `CALayer`, you are really setting the value of the *model* layer -- the layer that represents the final state of the layer when any ongoing animations have finished. If you ask the model layer for its values, it will always tell you the last value that it was set to.

当你设置某个 `CALayer` 的某个属性，你实际设置的是 *model* Layer 的值——这里的 *model* Layer 表示正在进行的动画结束时， Layer 所达到的最终状态。如果你取 *model* Layer 的值，它就总是给你它被设置到的最终值。

But attached to the model layer is the *presentation* layer -- a copy of the model layer with values that represent the *current*, mid-animation state. If we modify our `-display` method to log the `time` property of the layer's `presentationLayer`, we will see the interpolated values we were expecting. (We'll also use the `presentationLayer`'s `time` property to get the starting value for our animation action, instead of `self.time`):

但连接到 *model* Layer 的是所谓的 *presentation* Layer ——它是 *model* Layer 的一个拷贝，但它的值所表示的是 *当前的*，中间动画状态。如果我们修改 `-display` 方法去打印 Layer 的 `presentationLayer` 的 `time` 属性，那我们就会看到我们所期望的插值。（同时我们也使用 `presentationLayer` 的 `time` 属性来获取动画的开始值，替代 `self.time` ）：

    - (id<CAAction>)actionForKey:(NSString *)key
    {
        if ([key isEqualToString:@"time"])
        {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:key];
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            animation.fromValue = @([[self presentationLayer] time]);
            return animation;
        }
        return [super actionForKey:key];
    }

    - (void)display
    {
        NSLog(@"time: %f", [[self presentationLayer] time]);
    }
    
And here are the values:

下面是打印出的值：

    2014-04-28 22:43:31.200 ClockFace[49176:60b] time: 0.000000
    2014-04-28 22:43:31.203 ClockFace[49176:60b] time: 0.002894
    2014-04-28 22:43:31.263 ClockFace[49176:60b] time: 0.363371
    2014-04-28 22:43:31.300 ClockFace[49176:60b] time: 0.586421
    2014-04-28 22:43:31.318 ClockFace[49176:60b] time: 0.695179
    2014-04-28 22:43:31.336 ClockFace[49176:60b] time: 0.803713
    2014-04-28 22:43:31.354 ClockFace[49176:60b] time: 0.912598
    2014-04-28 22:43:31.372 ClockFace[49176:60b] time: 1.021573
    2014-04-28 22:43:31.391 ClockFace[49176:60b] time: 1.134173
    2014-04-28 22:43:31.409 ClockFace[49176:60b] time: 1.242892
    2014-04-28 22:43:31.427 ClockFace[49176:60b] time: 1.352016
    2014-04-28 22:43:31.446 ClockFace[49176:60b] time: 1.460729
    2014-04-28 22:43:31.464 ClockFace[49176:60b] time: 1.500000
    2014-04-28 22:43:31.636 ClockFace[49176:60b] time: 1.500000
    
So now, all we have to do is draw our clock. We do this by using ordinary Core Graphics functions to draw to a Graphics Context, and then set the resultant image as our layer's `contents`. Here is the updated `-display` method:

所以现在我们所要做就是画出时钟。我们将使用普通的 Core Graphics 函数以绘制到一个 Graphics Context 上来做到这一点，然后将产生出图像设置为我们 Layer 的 `contents`。下面是更新后的 `-display` 方法：

    - (void)display
    {
        // 获取时间插值
        float time = [self.presentationLayer time];
        
        // 创建绘制上下文
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        // 绘制时钟面板
        CGContextSetLineWidth(ctx, 4);
        CGContextStrokeEllipseInRect(ctx, CGRectInset(self.bounds, 2, 2));
        
        // 绘制时针
        CGFloat angle = time / 12.0 * 2.0 * M_PI;
        CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
        CGContextSetLineWidth(ctx, 4);
        CGContextMoveToPoint(ctx, center.x, center.y);
        CGContextAddLineToPoint(ctx, center.x + sin(angle) * 80, center.y - cos(angle) * 80);
        CGContextStrokePath(ctx);
        
        // 绘制分针
        angle = (time - floor(time)) * 2.0 * M_PI;
        CGContextSetLineWidth(ctx, 2);
        CGContextMoveToPoint(ctx, center.x, center.y);
        CGContextAddLineToPoint(ctx, center.x + sin(angle) * 90, center.y - cos(angle) * 90);
        CGContextStrokePath(ctx);
        
        //set backing image 设置 contents 
        self.contents = (id)UIGraphicsGetImageFromCurrentImageContext().CGImage;
        UIGraphicsEndImageContext();
    }
    
The result looks like this:

结果看起来如下：

<img src="{{site.images_path}}/issue-12/clock2.gif" width="320px">

As you can see, unlike the first clock animation, the minute hand actually cycles through a full revolution for each hour that the hour hand moves (like a real clock would), instead of just moving to its final position via the shortest path. That's an advantage of animating in this way; because we are animating the `time` value itself instead of just the positions of the hands, the contextual information is preserved. 

如你所见，不同于第一个时钟动画，随着时针的变化，分针实际上对每一个小时都会转上满满一圈（就像一个真正的时钟那样），而不仅仅只是通过最短的路径移动到它的最终位置；因为我们正在动画的是 `time` 值本身而不仅仅是时针或分针的位置，所以上下文信息被保留了。

Drawing the clock in this way is not ideal because Core Graphics functions are not hardware accelerated, and may cause the frame rate of our animation to drop. An alternative to redrawing the `contents` image 60 times per second would be to store a number of pre-drawn images in an array and simply select the correct image based on the interpolated value. The code to do that might look like this:

通过这样的方式绘制一个时钟并不是很理想，因为 Core Graphics 函数没有硬件加速，可能会引起动画帧数的下降。另一种能每秒重绘 `contents` 图像 60 次的方式是用一个数组存储一些预先绘制好的图像，然后基于合适的插值简单的选择对应的图像即可。实现代码大概如下：

    const NSInteger hoursOnAClockFace = 12;

    - (void)display
    {
        // 获取时间插值 
        float time = [self.presentationLayer time] / hoursOnAClockFace;
        
        // 从之前定义好的图像数组里获取图像帧
        NSInteger numberOfFrames = [self.frames count];
        NSInteger index = round(time * numberOfFrames) % numberOfFrames;
        UIImage *frame = self.frames[index];
        self.contents = (id)frame.CGImage;
    }
    
This improves animation performance by avoiding the need for costly software drawing during each frame, but the tradeoff is that we need to store all of the pre-drawn animation frame images in memory, which -- for a complex animation -- might be prohibitively wasteful of RAM.

通过避免在每一帧里都用昂贵的软件绘制，我们能改善动画的性能，但代价是我们需要在内存里存储所有预先绘制的动画帧图像，对于一个复杂的动画来说，这可能造成惊人的内存浪费。
    
But this raises an interesting possibility. What happens if we don't update the `contents` image in our `-display` method at all? What if we do something else?

但这提出了一个有趣的可能性。如果我们完全不在 `-display` 里更新 `contents` 图像会发生什么？我们做一些其它的事情怎样？

## Animating Non-Visual Properties 非可视属性的动画

There would be no point in updating any other layer property from within `-display`, because we could simply animate any such property directly, as we did in the first clock-face example. But what if we set something else, perhaps something entirely unrelated to the layer?

在 `-display` 里更新其它 Layer 属性就是不必要的，因为我们可以很简单地直接对任何这样的属性做动画，如同我们在第一个时钟面板例子里所做的那样。但如果我们设置一些其它的东西，比如某些完全不和 Layer 相关的东西，会怎样呢？

The following code uses a `CALayer` combined with `AVAudioPlayer` to create an animated volume control. By tying the volume to a dynamic layer property, we can use Core Animation's property interpolation to smoothly ramp between different volume levels in the same way we might animate any cosmetic property of the layer:

下面的代码使用一个 `CALayer` 结合 `AVAudioPlayer` 来创建一个可动画的音量控制器。通过把音量调到动态 Layer 属性上，我们可以使用 Core Animation 的属性插值来平滑的在两个不同的音量之间渐变，以同样的方式我们可以动画 Layer 上的任何 cosmetic 属性：

    @interface AudioLayer : CALayer

    - (id)initWithAudioFileURL:(NSURL *)URL;

    @property (nonatomic, assign) float volume;

    - (void)play;
    - (void)stop;
    - (BOOL)isPlaying;

    @end


    @interface AudioLayer ()

    @property (nonatomic, strong) AVAudioPlayer *player;

    @end


    @implementation AudioLayer

    @dynamic volume;

    - (id)initWithAudioFileURL:(NSURL *)URL
    {
        if ((self = [self init]))
        {
            self.volume = 1.0;
            self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:URL error:NULL];
        }
        return self;
    }

    - (void)play
    {
        [self.player play];
    }

    - (void)stop
    {
        [self.player stop];
    }

    - (BOOL)isPlaying
    {
        return self.player.playing;
    }

    + (BOOL)needsDisplayForKey:(NSString *)key
    {
        if ([@"volume" isEqualToString:key])
        {
            return YES;
        }
        return [super needsDisplayForKey:key];
    }

    - (id<CAAction>)actionForKey:(NSString *)key
    {
        if ([key isEqualToString:@"volume"])
        {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:key];
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            animation.fromValue = @([[self presentationLayer] volume]);
            return animation;
        }
        return [super actionForKey:key];
    }

    - (void)display
    {
        // 设置音量值为合适的音量插值
        self.player.volume = [self.presentationLayer volume];
    }

    @end
    
We can test this using a simple view controller with play, stop, volume up, and volume down buttons:

我们可以通过使用一个简单的有着播放、停止、音量增大以及音量减小按钮的 View Controller 来做测试：

    @interface ViewController ()

    @property (nonatomic, strong) AudioLayer *audioLayer;

    @end


    @implementation ViewController

    - (void)viewDidLoad
    {
        [super viewDidLoad];
        
        NSURL *musicURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"music" ofType:@"caf"]];
        self.audioLayer = [[AudioLayer alloc] initWithAudioFileURL:musicURL];
        [self.view.layer addSublayer:self.audioLayer];
    }

    - (IBAction)playPauseMusic:(UIButton *)sender
    {
        if ([self.audioLayer isPlaying])
        {
            [self.audioLayer stop];
            [sender setTitle:@"Play Music" forState:UIControlStateNormal];
        }
        else
        {
            [self.audioLayer play];
            [sender setTitle:@"Pause Music" forState:UIControlStateNormal];
        }
    }

    - (IBAction)fadeIn
    {
        self.audioLayer.volume = 1;
    }

    - (IBAction)fadeOut
    {
        self.audioLayer.volume = 0;
    }

    @end

Note: even though our layer has no visual appearance, it still needs to be added to the onscreen view hierarchy in order for the animations to work correctly.

注意：尽管我们的 Layer 没有可见的外观，但它依然需要被添加到屏幕上的视图层级里，以便动画能正常工作。
    
## Conclusion 结论
    
`CALayer`'s dynamic properties provide a simple mechanism to implement any sort of animation-- not just the built-in ones -- and by overriding the `-display` method, we can use those properties to control anything we like, even something like sound volume.

`CALayer` 的动态属性提供了一个简单的机制来实现任何形式的动画——不仅仅只是内建的那些——而通过覆写 `-display` 方法，我们可以使用这些属性去控制任何我们想控制的东西，甚至是音量值这样的东西。

By using these properties, we not only avoid reinventing the wheel, but we ensure that our custom animations work with the standard animation timing and control functions, and can easily be synchronized with other animated properties.

通过使用这些属性，我们不仅仅避免了重复造轮子，同时还确保了我们的自定义动画能与标准动画的时机和控制函数协同工作，以此就能非常容易地与其它动画属性同步。