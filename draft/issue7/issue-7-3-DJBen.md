---
layout: post
title: "Key-Value Coding and Observing"
category: "7"
date: "2013-12-09 09:00:00"
tags: article
author: "<a href=\"http://twitter.com/danielboedewadt\">Daniel Eggert</a>"
---


Key-value coding and key-value observing are two formalized mechanisms that allow us to simplify our code by harnessing the dynamic and introspective properties of the Objective-C language. In this article, we’ll take a look at some examples on how to put this to use.

Key-value coding (KVC) 和 key-value observing (KVO) 是两种能让我们驾驭 Objective-C 动态特性并简化我们的代码的机制。在这篇文章里，我们将接触一些能让我们利用这些特性的例子。

## Observing Changes to Model Objects

## 观察 model 对象的变化

In Cocoa, the Model-View-Controller pattern, a controller's responsibility is to keep the view and the model synchronized. There are two parts to this: when the model object changes, the views have to be updated to reflect this change, and when the user interacts with controls, the model has to be updated accordingly.

在 Cocoa 的模型-视图-控制器 (Model-view-controller)架构里，控制器负责让视图和模型同步。这一共有两步：当 model 对象改变的时候，视图应该随之改变以反映模型的变化；当用户和控制器交互的时候，模型也应该做出相应的改变。

*Key-Value Observing* helps us update the views to reflect changes to model objects. The controller can observe changes to those property values that the views depend on.

*KVO* 能帮助我们让视图和模型保持同步。控制器可以观察视图依赖的属性变化。

Let's look at a sample: Our model class `LabColor` is a color in the [Lab color space](https://en.wikipedia.org/wiki/Lab_color_space) where the components are *L*, *a*, and *b* (instead of red, green, and blue). We want sliders to change the values and a big rectangle that shows the color.

让我们看一个例子：我们的模型类 `LabColor` 代表一种 [Lab色彩空间](https://zh.wikipedia.org/wiki/Lab%E8%89%B2%E5%BD%A9%E7%A9%BA%E9%97%B4)里的颜色。和 RGB 不同，这种色彩空间有三个元素 *L*, *a*, *b*。我们要做一个用来改变这些值的滑块和一个显示颜色的方块区域。

Our model class will have three properties for the components:

我们的模型类有以下三个用来代表颜色的属性：

    @property (nonatomic) double lComponent;
    @property (nonatomic) double aComponent;
    @property (nonatomic) double bComponent;

### Dependent Properties

## 依赖的属性

We need to create a `UIColor` from this that we can use to display the color. We'll add three additional properties for the red, green, and blue components and another property for the `UIColor`:

我们需要从这个类创建一个 `UIColor` 对象来显示出颜色。我们添加三个额外的属性，分别对应 R, G, B：

    @property (nonatomic, readonly) double redComponent;
    @property (nonatomic, readonly) double greenComponent;
    @property (nonatomic, readonly) double blueComponent;

    @property (nonatomic, strong, readonly) UIColor *color;

With this, we have all we need for our class interface:

有了这些以后，我们就可以创建这个类的接口了：

    @interface LabColor : NSObject

    @property (nonatomic) double lComponent;
    @property (nonatomic) double aComponent;
    @property (nonatomic) double bComponent;

    @property (nonatomic, readonly) double redComponent;
    @property (nonatomic, readonly) double greenComponent;
    @property (nonatomic, readonly) double blueComponent;

    @property (nonatomic, strong, readonly) UIColor *color;

    @end

The math for calculating the red, green, and blue components is outlined [on Wikipedia](https://en.wikipedia.org/wiki/Lab_color_space#CIELAB-CIEXYZ_conversions). It looks something like this:

[维基百科](https://zh.wikipedia.org/wiki/Lab%E8%89%B2%E5%BD%A9%E7%A9%BA%E9%97%B4#XYZ.E4.B8.8ECIE_L.2Aa.2Ab.2A.28CIELAB.29.E7.9A.84.E8.BD.AC.E6.8D.A2)提供了转换 RGB 到 Lab 色彩空间的算法。写成方法之后如下所示：


    - (double)greenComponent;
    {
        return D65TristimulusValues[1] * inverseF(1./116. * (self.lComponent + 16) + 1./500. * self.aComponent);
    }

    [...]

    - (UIColor *)color
    {
        return [UIColor colorWithRed:self.redComponent * 0.01 green:self.greenComponent * 0.01 blue:self.blueComponent * 0.01 alpha:1.];
    }

Nothing too exciting here. What's interesting to us is that this `greenComponent` property depends on the `lComponent` and `aComponent` properties. This is important to key-value observing; whenever we set the `lComponent` property we want anyone interested in either of the red-green-blue components or the `color` property to be notified.

这些代码没什么令人激动的地方。有趣的是 `greenComponent` 属性依赖于 `lComponent` 和 `aComponent`。这在之后的 KVO 中很重要：如果我们要设置 `lComponent` 的值，我们要让 RGB 三个 component 和 `color` 属性都要得到通知以保持一致。

The mechanism that the Foundation framework provides for expressing dependencies is:

Foundation 框架提供的表示属性依赖的机制如下：

    + (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key

and more specifically:

更详细的如下：

    + (NSSet *)keyPathsForValuesAffecting<Key>

    + (NSSet *)keyPathsForValuesAffecting<键名>

In our concrete case, that'll look like so:

在我们的例子中如下：

    + (NSSet *)keyPathsForValuesAffectingRedComponent
    {
        return [NSSet setWithObject:@"lComponent"];
    }

    + (NSSet *)keyPathsForValuesAffectingGreenComponent
    {
        return [NSSet setWithObjects:@"lComponent", @"aComponent", nil];
    }

    + (NSSet *)keyPathsForValuesAffectingBlueComponent
    {
        return [NSSet setWithObjects:@"lComponent", @"bComponent", nil];
    }

    + (NSSet *)keyPathsForValuesAffectingColor
    {
        return [NSSet setWithObjects:@"redComponent", @"greenComponent", @"blueComponent", nil];
    }

We have now fully expressed the dependencies. Note that we're able to do chaining of these dependencies. For example, this would allow us to safely subclass and override the `redComponent` method and the dependency would continue to work.

现在我们完整的表达了属性之间的依赖关系。请注意，我们可以把这些属性链接起来。打个比方，如果我们写一个子类去 override `redComponent` 方法，这些依赖关系仍然能正常工作。

### Observing Changes

### 观察变化

Let's turn toward the view controller. The `NSViewController` subclass owns the model object `LabColor` as a property:

现在让我们目光转向控制器。 `NSViewController` 的子类拥有 `LabColor`  model 对象作为其属性。

    @interface ViewController ()

    @property (nonatomic, strong) LabColor *labColor;

    @end

We want to register the view controller to receive key-value observation notifications. The method on `NSObject` to do this is:

我们把视图控制器注册为观察者来接收 KVO 的通知，这可以用以下 `NSObject` 的方法来实现：

    - (void)addObserver:(NSObject *)anObserver
             forKeyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
                context:(void *)context

This will cause:
这会让以下方法

    - (void)observeValueForKeyPath:(NSString *)keyPath
                          ofObject:(id)object
                            change:(NSDictionary *)change
                           context:(void *)context

to get called on `anObserver` whenever the value of `keyPath` changes. This API can seem a bit daunting. To make things worse, we have to remember to call:

在当 `keyPath` 的值改变的时候在观察者 `anObserver` 上面被调用。这个 API 看起来有一点吓人。更糟糕的是，我们还得记得调用以下的方法

    - (void)removeObserver:(NSObject *)anObserver
                forKeyPath:(NSString *)keyPath

to remove the observer, otherwise our app will crash in strange ways.

来移除观察者，否则我们我们的 app 会因为某些奇怪的原因崩溃。

For most intents and purposes, *key-value observing* can be done in a much simpler and more elegant way by using a helper class. We'll add a so-called *observation token* property to our view controller:

对于大多数的应用来说，*KVO* 可以通过辅助类用一种更简单优雅的方式实现。我们在视图控制器添加以下的*观察印记 (Observation token) *属性：

    @property (nonatomic, strong) id colorObserveToken;

and when the `labColor` gets set on the view controller, we'll simply observe changes to its `color` by overriding the setter for `labColor`, like so:

当 `labColor` 在视图控制器中被设置时，我们只要 override `labColor` 的 setter 方法就行了：

    - (void)setLabColor:(LabColor *)labColor
    {
        _labColor = labColor;
        self.colorObserveToken = [KeyValueObserver observeObject:labColor
                                                         keyPath:@"color"
                                                          target:self
                                                        selector:@selector(colorDidChange:)
                                                         options:NSKeyValueObservingOptionInitial];
    }

    - (void)colorDidChange:(NSDictionary *)change;
    {
        self.colorView.backgroundColor = self.labColor.color;
    }

The [`KeyValueObserver` helper class](https://github.com/objcio/issue-7-lab-color-space-explorer/blob/master/Lab%20Color%20Space%20Explorer/KeyValueObserver.m) simply wraps the calls to `-addObserver:forKeyPath:options:context:`, `-observeValueForKeyPath:ofObject:change:context:` and `-removeObserverForKeyPath:` and keeps the view controller code free of clutter.

[`KeyValueObserver` 辅助类](https://github.com/objcio/issue-7-lab-color-space-explorer/blob/master/Lab%20Color%20Space%20Explorer/KeyValueObserver.m) 封装了 `-addObserver:forKeyPath:options:context:`，`-observeValueForKeyPath:ofObject:change:context:`和`-removeObserverForKeyPath:` 的调用，让视图控制器远离杂乱的代码。

### Tying it Together

### 整合到一起

The view controller finally needs to react to changes of the *L*, *a*, and *b* sliders:

视图控制器需要对 *L*，*a*，*b* 的滑块控制做出反应：

    - (IBAction)updateLComponent:(UISlider *)sender;
    {
        self.labColor.lComponent = sender.value;
    }

    - (IBAction)updateAComponent:(UISlider *)sender;
    {
        self.labColor.aComponent = sender.value;
    }

    - (IBAction)updateBComponent:(UISlider *)sender;
    {
        self.labColor.bComponent = sender.value;
    }

The entire code is available as a [sample project](https://github.com/objcio/issue-7-lab-color-space-explorer) on our GitHub repository.

所有的代码都在我们的 GitHub [示例代码][sample project](https://github.com/objcio/issue-7-lab-color-space-explorer) 中找到。

## Manual vs. Automatic Notification

## 自动通知 vs 手动通知

What we did above may seem a bit like magic, but what happens is that calling `-setLComponent:` etc. on a `LabColor` instance will automatically cause:

我们刚才所做的事情有点神奇，但是当 `LabColor` 实例的 `-setLComponent:` 等方法被调用的时候以下方法

    - (void)willChangeValueForKey:(NSString *)key

and:

还有

    - (void)didChangeValueForKey:(NSString *)key

to get called prior to or after running the code inside the `-setLComponent:` method. This happens both if we implement `-setLComponent:` and if we (as in our case) choose to auto-synthesize the accessors for `lComponent`.

会在运行 `-setLComponent:` 之前被调用。如果我们写了 `-setLComponent:` 并且我们选择自动合成 `lComponent` 的 accessor 到时候就会发生这样的事情。

There are cases when we want or need to override `-setLComponent:` and control whether change notifications are sent out, like so:

有些情况下当我们需要 override `-setLComponent:` 并且我们要控制是否发送键值改变的通知的时候，我们要做以下的事情：

    + (BOOL)automaticallyNotifiesObserversForLComponent;
    {
        return NO;
    }

    - (void)setLComponent:(double)lComponent;
    {
        if (_lComponent == lComponent) {
            return;
        }
        [self willChangeValueForKey:@"lComponent"];
        _lComponent = lComponent;
        [self didChangeValueForKey:@"lComponent"];
    }

We disable automatic invocation of `-willChangeValueForKey:` and `-didChangeValueForKey:`, and then call it ourselves. We should only call `-willChangeValueForKey:` and `-didChangeValueForKey:` inside the setter if we've disabled automatic invocation. And in most cases, this optimization doesn't buy us much.

我们关闭了 `-willChangeValueForKey:` 和 `-didChangeValueForKey:` 的自动调用，然后我们手动调用他们。我们只应该在关闭了自动调用的时候我们才需要在 setter 方法里手动调用 `-willChangeValueForKey:` 和 `-didChangeValueForKey:`。大多数情况下，这样优化不会给我们带来太多好处。

If we modify the instance variables (e.g. `_lComponent`) outside the accessor, we need to be careful to similarly wrap those changes in `-willChangeValueForKey:` and `-didChangeValueForKey:`. But in most cases, the code stays simpler if we make sure to always use the accessors.

如果我们在 accessor 方法之外改变实例对象（如 `_lComponent` ），我们要特别小心地和刚才一样封装 `-willChangeValueForKey:` 和 `-didChangeValueForKey:`。不过在多数情况下，我们只用 accessor 方法的话就可以了，这样代码会简洁很多。

## Key-Value Observing and the Context

## KVO 和 context

There may be reasons why we don't want to use the `KeyValueObserver` helper class. There's a slight overhead of creating another object. If we're observing a lot of keys, that might be noticeable, however unlikely that is.

有时我们会有理由不想用 `KeyValueObserver` 辅助类。创建另一个对象会有额外的性能开销。如果我们观察很多个键的话，这个开销可能会变得明显。

If we're implementing a class that registers itself as an observer with:

如果我们在实现一个类的时候把它自己注册为观察者的话：

    - (void)addObserver:(NSObject *)anObserver
             forKeyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
                context:(void *)context

it is *very* important that we pass a `context` that's unique to this class. We recommend putting:

一个*非常*重要的点是我们要传入一个这个类唯一的 `context`。我们推荐把以下代码

    static int const PrivateKVOContext;

at the top of the class' `.m` file and then calling the API with a pointer to this `PrivateKVOContext` as the context, like so:

写在这个类 `.m` 文件的顶端，然后我们像这样调用 API 并传入 `PrivateKVOContext` 的指针：

    [otherObject addObserver:self forKeyPath:@"someKey" options:someOptions context:&PrivateKVOContext];

and then implement the `-observeValueForKeyPath:...` method like so

然后我们这样写 `-observeValueForKeyPath:...` 的方法：

    - (void)observeValueForKeyPath:(NSString *)keyPath
                          ofObject:(id)object
                            change:(NSDictionary *)change
                           context:(void *)context
    {
        if (context == &PrivateKVOContext) {
            // Observe values here
        } else {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }

This ensures that subclassing works. With this pattern, both superclasses and subclasses can safely observe the same keys on the same objects without clashing. Otherwise, we'll end up running into odd behavior that's very difficult to debug.

这将确保我们写的子类都是正确的。如此以来，子类和父类都能安全的观察同样的键值而不会冲突。否则我们将会碰到难以 debug 的奇怪行为。

## Advanced Key-Value Observing

## 进阶 KVO

We often want to update some UI when a value changes, but we also need to initially run the code to update the UI once. We can use KVO to do both by specifying the `NSKeyValueObservingOptionInitial`. That will cause the KVO notification to trigger during the call to `-addObserver:forKeyPath:...`.

我们常常需要当一个值改变的时候更新 UI，但是我们也要在第一次运行代码的时候更新一次 UI。我们可以用 KVO 并添加 `NSKeyValueObservingOptionInitial` 的选项 来一箭双雕地做好这样的事情。这将会让 KVO 通知在调用 `-addObserver:forKeyPath:...` 到时候也被触发。

### Before and After the Fact

### 之前和之后

When we register for KVO, we can also specify `NSKeyValueObservingOptionPrior`. This allows us to be notified before the value is changed. This directly corresponds to the point in time when `-willChangeValueForKey:` gets called.

当我们注册 KVO 通知的时候，我们可以添加 `NSKeyValueObservingOptionPrior` 选项，这能使我们在键值改变之前被通知。这和`-willChangeValueForKey:`被触发的时间相对应。

If we register with `NSKeyValueObservingOptionPrior` we will receive two notifications: one before the change and one after the change. The first one will have another key in the `change` dictionary, and we can test if it's the notification prior to the change or the one after, like so:

如果我们注册通知的时候附加了 `NSKeyValueObservingOptionPrior` 选项，我们将会收到两个通知：第一个通知将会在 `change` 字典中有不同的键。我们可以像以下这样区分通知是在改变之前还是之后被触发的：

    if ([change[NSKeyValueChangeNotificationIsPriorKey] boolValue]) {
        // Before the change
    } else {
        // After the change
    }

### Values

### 值

If we need either the old or the new value (or both) of the key, we can ask KVO to pass those as part of the notification by specifying `NSKeyValueObservingOptionNew` and/or `NSKeyValueObservingOptionOld`.

如果我们需要改变前后的值，我们可以在 KVO 选项中加入 `NSKeyValueObservingOptionNew` 或 `NSKeyValueObservingOptionOld`。

This is often easier and better that using `NSKeyValueObservingOptionPrior`. We would extract the old and new values with:

更简单的办法是用 `NSKeyValueObservingOptionPrior` 选项，随后我们就可以用以下方式提取出改变前后的值：

    id oldValue = change[NSKeyValueChangeOldKey];
    id newValue = change[NSKeyValueChangeNewKey];

KVO basically stores the values for the corresponding key at the point in time where `-willChangeValueForKey:` and `-didChangeValueForKey:` were called, respectively.

通常来说 KVO 会在 `-willChangeValueForKey:` 和 `-didChangeValueForKey:` 被调用的时候存储相应键的值。

### Indexes

### 索引

KVO also has very powerful support for notifying about changes to collections. These are returned for collection proxy objects returned by:

KVO 对一些集合类也有很强的支持，以下方法会返回集合对象：

    -mutableArrayValueForKey:
    -mutableSetValueForKey:
    -mutableOrderedSetValueForKey:

We'll describe how these work further below. If you use these, the change dictionary will contain information about the change kind (insertion, removal, or replacement) and for ordered relations, the change dictionary also contains information about the affected indexes.

我们将会详细解释这是怎么工作的。如果你使用这些方法，change 字典里会包含键值变化的类型（添加、删除和替换）。对于有序的集合，change 字典会包含受影响的 index。

The combination of collection proxy objects and these detailed change notifications can be used to efficiently update the UI when presenting large collections, but they require quite a bit of work.

集合代理对象和变化的通知在用于更新UI的时候非常有效，尤其是处理大集合的时候。但是他们需要花费你一些心思。

## Key-Value Observing and Threading

## KVO 和线程

It is important to note that KVO happens synchronously and on the same thread as the actual change. There's no queuing or run-loop magic going on. The manual or automatic call to `-didChange...` will trigger the KVO notification to be sent out.

一个需要注意的地方是，KVO 和视图在同一个线程上。没有队列或者运行环（Run loop）。手动或者自动调用 `-didChange...` 会触发 KVO 通知。

Hence, we must be very careful about not making changes to properties from another thread unless we can be sure that everybody observing that key can handle the change notification in a thread-safe manner. Generally speaking, we cannot recommend mixing KVO and multithreading. If we are using multiple queues or threads, we should not be using KVO between queues or threads.

所以，当我们试图改变其他线程的时候我们应当十分小心，除非能确定所有的观察者都用线程安全的方法处理 KVO 通知。通常来说，我们不推荐把 KVO 和多线程混起来。如果我们要用多个队列和线程，我们不应该在它们互相之间用 KVO。

The fact that KVO happens synchronously is very powerful. As long as we're running on a single thread (e.g. the main queue) KVO ensures two important things.

同步的 KVO 已经十分的强大了，只要我们在单一线程上面运行（主队列 main queue），KVO 会保证下列两种情况的发生：

First, if we call a KVO compliant setter, like:

首先，如果我们调用一个支持 KVO 的 setter 方法，如下所示：

    self.exchangeRate = 2.345;

we are guaranteed that all observers of `exchangeRate` have been notified by the time the setter returns.

KVO 能保证所有 `exchangeRate` 的观察者在 setter 方法返回时被通知到。

Second, if the key path is observed with `NSKeyValueObservingOptionPrior`, someone accessing the `exchangeRate` property will stay the same until the `-observe...` method is called.

其次，如果某个键被观察的时候附上了 `NSKeyValueObservingOptionPrior` 选项，直到 `-observe...` 被调用之前， `exchangeRate` 的 accessor 方法都会返回同样的值。

## Key-Value Coding

## KVC

Key-value coding in its simplest form allows us to access a property like:

最简单的 KVC 能让我们通过以下的形式访问属性：

    @property (nonatomic, copy) NSString *name;

through:

    NSString *n = [object valueForKey:@"name"]

and:

    [object setValue:@"Daniel" forKey:@"name"]

Note that this works for properties with object values, as well as scalar types (e.g. `int` and `CGFloat`) and structs (e.g. `CGRect`). Foundation will automatically do the wrapping and unwrapping for us. For example, if the property is:

值得注意的是这个不仅可以访问作为对象属性，而且也能访问一些标量（例如 `int` 和 `CGFloat`）和 struct（例如 `CGRect`）。Foundation 框架会为我们自动封装它们。举例来说，如果有以下属性：

    @property (nonatomic) CGFloat height;

we can set it with:

我们可以这样设置它：

    [object setValue:@(20) forKey:@"height"]

Key-value coding allows us to access properties using strings to identify properties. These strings are called *keys*. In certain situations, this will give us a lot of flexibility which we can use to simplify our code. We'll look at an example in the next section, *Simplifying Form-Like User Interfaces*.

KVC 允许我们用字符串的名称访问属性，字符串在这儿叫做*键*。有些情况下，这会使我们非常灵活地简化代码。我们下一节介绍例子*简化列表 UI*。

But there's more to key-value coding. Collections (`NSArray`, `NSSet`, etc.) have powerful collection operators which can be used with key-value coding. And finally, an object can support key-value coding for keys that are not normal properties e.g. through proxy objects.

KVC 还有更多可以谈的。集合（`NSArray`，`NSSet` 等）有着强大的集合操作。还有，对象可以支持用 KVC 通过代理对象访问非常规的属性。

### Simplifying Form-Like User Interfaces

## 简化列表 UI

Let's say we have an object:

假设我们有这样一个对象：

    @interface Contact : NSObject

    @property (nonatomic, copy) NSString *name;
    @property (nonatomic, copy) NSString *nickname;
    @property (nonatomic, copy) NSString *email;
    @property (nonatomic, copy) NSString *city;

    @end

and a detail view controller that has four corresponding `UITextField` properties:

还有一个 detail 视图控制器，含有四个对应的 `UITextField` 属性：

    @interface DetailViewController ()

    @property (weak, nonatomic) IBOutlet UITextField *nameField;
    @property (weak, nonatomic) IBOutlet UITextField *nicknameField;
    @property (weak, nonatomic) IBOutlet UITextField *emailField;
    @property (weak, nonatomic) IBOutlet UITextField *cityField;

    @end

We can now simplify the update logic. First, we need two methods that return us all model keys of interest to use and that map those keys to the keys of their corresponding text field respectively:

我们可以简化更新 UI 的逻辑。首先我们需要两个方法：一个返回 model 里我们用到的所有键的方法，一个把键映射到对应的文本框的方法：

    - (NSArray *)contactStringKeys;
    {
        return @[@"name", @"nickname", @"email", @"city"];
    }

    - (UITextField *)textFieldForModelKey:(NSString *)key;
    {
        return [self valueForKey:[key stringByAppendingString:@"Field"]];
    }

With this, we can update the text field from the model, like so:

有了这个，我们可以从 model 里更新文本框，如下所示：

    - (void)updateTextFields;
    {
        for (NSString *key in self.contactStringKeys) {
            [self textFieldForModelKey:key].text = [self.contact valueForKey:key];
        }
    }

We can also use a single-action method for all four text fields to update the model:

我们也可以用一个 action 方法让四个文本框都能实时更新 model：

    - (IBAction)fieldEditingDidEnd:(UITextField *)sender
    {
        for (NSString *key in self.contactStringKeys) {
            UITextField *field = [self textFieldForModelKey:key];
            if (field == sender) {
                [self.contact setValue:sender.text forKey:key];
                break;
            }
        }
    }

Note: We will add validation to this later, as pointed out at [*Key-Value Validation*](#key-value-validation).

注意：我们之后会添加验证输入的部分，在[*键值验证*](#key-value-validation)里会提到。

Finally, we need to make sure the text fields get updated when needed:

最后，我们需要确认文本框在需要的时候被更新：

    - (void)viewWillAppear:(BOOL)animated;
    {
        [super viewWillAppear:animated];
        [self updateTextFields];
    }

    - (void)setContact:(Contact *)contact
    {
        _contact = contact;
        [self updateTextFields];
    }

And with this, our [detail view controller](https://github.com/objcio/issue-7-contact-editor/blob/master/Contact%20Editor/DetailViewController.m) is working.

有了这个，我们的 [detail 视图控制器](https://github.com/objcio/issue-7-contact-editor/blob/master/Contact%20Editor/DetailViewController.m) 就能正常工作了。

Check out the entire project on our [GitHub repository](https://github.com/objcio/issue-7-contact-editor). It also uses [*Key-Value Validation*](#key-value-validation) as discussed further below.

整个 project 可以在 [GitHub](https://github.com/objcio/issue-7-contact-editor) 上找到。它也用了我们后面提到的[*键值验证*](#key-value-validation)。

### Key Paths

### 键路径（Key Path）

Key-value coding also allows you to go through relations, e.g. if `person` is an object that has a property called `address`, and `address` in turn has a property called `city`, we can retrieve that through:

KVC 同样允许我们通过关系来访问对象。假设 `person` 对象有属性 `address`，`address` 有属性 `city`，我们可以这样通过 `person` 来访问 `city`：

    [person valueForKeyPath:@"address.city"]

Note that we’re calling `-valueForKeyPath:` instead of `-valueForKey:` in this case.

值得注意的是这里我们调用 `-valueForKeyPath:` 而不是 `-valueForKey:`。

### Key-Value Coding Without `@property`

### 不需要 `@property` 的 KVC

We can implement a key-value coding-compliant attribute without `@property` and `@synthesize` / auto-synthesize. The most straightforward example would be to simply implement the `-<key>` and `-set<Key>:` methods. For example, if we want to support setting `name`, we would implement:

我们可以实现一个支持 KVC 而不用 `@property` 和 `@synthesize` 或是自动合成的属性。最直接的方式是添加 `-<key>` 和 `-set<Key>:` 方法。例如我们想要 `name` ，我们这样做：

    - (NSString *)name;
    - (void)setName:(NSString *)name;

This is straightforward, and identical to how `@property` works.

这完全等于 `@property` 的实现方式。

One thing to be aware of, though, is how `nil` is handled for scalar and struct values. Let's say we want to support key-value coding for `height` by implementing:

当标量和 struct 的属性被传入 `nil` 值的时候尤其需要注意。假设我们要 `height` 属性支持 KVC 我们写了以下的方法：

    - (CGFloat)height;
    - (void)setHeight:(CGFloat)height;

When we call:

然后我们这样调用：

    [object setValue:nil forKey:@"height"]

this would throw an exception. In order to be able to handle `nil` values, we need to make sure to override `-setNilValueForKey:`, like so:

这会抛出一个 exception。要正确的处理 `nil`，我们要像这样 override `-setNilValueForKey:`

    - (void)setNilValueForKey:(NSString *)key
    {
        if ([key isEqualToString:@"height"]) {
            [self setValue:@0 forKey:key];
        } else
            [super setNilValueForKey:key];
    }

We can make a class support key-value coding by overriding:

我们可以通过 override 这些方法来让一个类支持 KVC：

    - (id)valueForUndefinedKey:(NSString *)key;
    - (void)setValue:(id)value forUndefinedKey:(NSString *)key;

This may seem odd, but it allows a class to dynamically support certain keys. Using these two methods comes with a performance hit, though.

这也许看起来很怪，但这可以让一个类动态的支持一些键的访问。但是这两个方法会在性能上拖后腿。

As a side note, it is worth mentioning that Foundation supports accessing instance variables directly. Use that feature sparingly. Check the documentation for `+accessInstanceVariablesDirectly`. It defaults to `YES`, which causes Foundation to look for an instance variable called `_<key>`, `_is<Key>`, `<key>`, or `is<Key>`, in that order.

附注：Foundation 框架支持直接访问实例变量。请小心的使用这个特性。你可以去查看 `+accessInstanceVariablesDirectly` 的文档。这个值默认是 `YES` 的时候，Foundation 会按照 `_<key>`, `_is<Key>`, `<key>` 和 `is<Key>` 的顺序查找实例变量。


### Collection Operators

### 集合的操作

An oft-overlooked feature of key-value coding is its support for collection operators. For example, we can get the maximum value from an array with:

一个常常被忽视的 KVC 特性是它对集合操作的支持。举个例子，我们可以这样来获得一个数组中最大的值：

    NSArray *a = @[@4, @84, @2];
    NSLog(@"max = %@", [a valueForKeyPath:@"@max.self"]);

or, if we have an array of `Transaction` objects that have an `amount` property, we can get the maximum `amount` with:

或者说，我们有一个 `Transaction` 对象的数组，对象有属性 `amount` 的话，我们可以这样获得最大的 `amount`：

    NSArray *a = @[transaction1, transaction2, transaction3];
    NSLog(@"max = %@", [a valueForKeyPath:@"@max.amount"]);

When we call `[a valueForKeyPath:@"@max.amount"]`, this will call `-valueForKey:@"amount"` on each element in the array `a` and then return the maximum of those.

当我们调用 `[a valueForKeyPath:@"@max.amount"]` 的时候，它会在数组 `a` 的每个元素中调用 `-valueForKey:@"amount"` 然后返回最大的那个。

Apple's documentation for key-value coding has a section called [Collection Operators](https://developer.apple.com/library/ios/documentation/cocoa/conceptual/KeyValueCoding/Articles/CollectionOperators.html) that describes this in detail.

KVC 的苹果官方文档有一个章节 [Collection Operators](https://developer.apple.com/library/ios/documentation/cocoa/conceptual/KeyValueCoding/Articles/CollectionOperators.html) 详细的讲述了类似的用法。


### Key-Value Coding Through Collection Proxy Objects

### 通过集合代理对象来实现 KVC

We can expose collections (`NSArray`, `NSSet`, etc.) in the same way as normal objects. But key-value coding also allows us to implement a key-value coding-compliant collection though proxy objects. This is an advanced technique. We'll rarely find use for it, but it's a powerful trick to have in the tool chest.

虽然我们可以像对待一般的对象一样用 KVC 深入集合内部（`NSArray` 和 `NSSet` 等），但是通过集合代理对象， KVC 也让我们实现一个兼容 KVC 的集合。这是一个颇为高端的技巧。

When we call `-valueForKey:` on an object, that object can return collection proxy objects for an `NSArray`, an `NSSet`, or an `NSOrderedSet`. The class doesn't implement the normal `-<Key>` method but instead implements a number of methods that the proxy uses.

当我们在对象上调用 `-valueForKey:` 的时候，它可以返回 `NSArray`，`NSSet` 或是 `NSOrderedSet` 的集合代理对象。这个类通常没有 `-<Key>` 方法，但是它可以实现代理对象使用的很多方法。

If we want the class to be able to support returning an `NSArray` through a proxy object for the key `contacts`, we could implement:

如果我们希望一个类支持通过代理对象的 `contacts` 键返回一个 `NSArray`，我们可以这样写：

    - (NSUInteger)countOfContacts;
    - (id)objectInContactsAtIndex:(NSUInteger)idx;

Doing so, when we call `[object valueForKey:@"contacts”]`, this will return an `NSArray` that proxies all calls to those two methods. But the array will support *all* methods on `NSArray`. The proxying is transparent to the caller. In other words, the caller doesn't know if we return a normal `NSArray` or a proxy.

这样做的话，当我们调用 `[object valueForKey:@"contacts”]` 的时候，它会返回通过这两个方法代理*所有*调用方法的 `NSArray`。这个数组支持正常的所有调用。换句话说，调用者不知道返回的是一个真正的 `NSArray` 还是一个代理的数组。

We can do the same for an `NSSet` and `NSOrderedSet`. The methods that we have to implement are:

<table><thead><tr><th style="text-align:left;padding-right:1em;">NSArray</th><th style="text-align:left;padding-right:1em;">NSSet&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</th><th style="text-align:left;padding-right:1em;">NSOrderedSet&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</th></tr></thead><tbody><tr><td style="text-align:left;padding-right:1em;"><code>-countOf&lt;Key&gt;</code></td><td style="text-align:left;padding-right:1em;"><code>-countOf&lt;Key&gt;</code></td><td style="text-align:left;padding-right:1em;"><code>-countOf&lt;Key&gt;</code></td>
</tr><tr><td style="text-align:left;padding-right:1em;"></td><td style="text-align:left;padding-right:1em;"><code>-enumeratorOf&lt;Key&gt;</code></td><td style="text-align:left;padding-right:1em;"><code>-indexIn&lt;Key&gt;OfObject:</code></td>
</tr><tr><td style="text-align:left;padding-right:1em;">One of</td><td style="text-align:left;padding-right:1em;"><code>-memberOf&lt;Key&gt;:</code></td><td style="text-align:left;padding-right:1em;">
</td></tr><tr><td style="text-align:left;padding-right:1em;"><code>-objectIn&lt;Key&gt;AtIndex:</code></td><td style="text-align:left;padding-right:1em;"></td><td style="text-align:left;padding-right:1em;">One of</td>
</tr><tr><td style="text-align:left;padding-right:1em;"><code>-&lt;key&gt;AtIndexes:</code></td><td style="text-align:left;padding-right:1em;"></td><td style="text-align:left;padding-right:1em;"><code>-objectIn&lt;Key&gt;AtIndex:</code></td>
</tr><tr><td style="text-align:left;padding-right:1em;"></td><td style="text-align:left;padding-right:1em;"></td><td style="text-align:left;padding-right:1em;"><code>-&lt;key&gt;AtIndexes:</code></td>
</tr><tr><td style="text-align:left;padding-right:1em;">Optional (performance)</td><td style="text-align:left;padding-right:1em;"></td><td style="text-align:left;padding-right:1em;">
</td></tr><tr><td style="text-align:left;padding-right:1em;"><code>-get&lt;Key&gt;:range:</code></td><td style="text-align:left;padding-right:1em;"></td><td style="text-align:left;padding-right:1em;">Optional (performance)</td>
</tr><tr><td style="text-align:left;padding-right:1em;"></td><td style="text-align:left;padding-right:1em;"></td><td style="text-align: left;"><code>-get&lt;Key&gt;:range:</code></td>
</tr></tbody></table>


The *optional* methods can improve performance of the proxy object.

*可选*的一些方法可以增强代理对象的性能。

Using these proxy objects only makes sense in special situations, but in those cases it can be very helpful. Imagine that we have a very large existing data structure and the caller doesn't need to access all elements (at once).

虽然只有特殊情况下我们用这些代理对象才会有意义，但是在这些情况下代理对象非常的有用。想象一下我们有一个很大的数据结构，调用者不需要（一次性）访问所有的对象。

As a (perhaps contrived) example, we could write a class that contains a huge list of primes, like so:

举一个（也许比较做作的）例子说，我们想写一个包含有很长一串质数的类。如下所示：

    @interface Primes : NSObject

    @property (readonly, nonatomic, strong) NSArray *primes;

    @end



    @implementation Primes

    static int32_t const primes[] = {
        2, 101, 233, 383, 3, 103, 239, 389, 5, 107, 241, 397, 7, 109,
        251, 401, 11, 113, 257, 409, 13, 127, 263, 419, 17, 131, 269,
        421, 19, 137, 271, 431, 23, 139, 277, 433, 29, 149, 281, 439,
        31, 151, 283, 443, 37, 157, 293, 449, 41, 163, 307, 457, 43,
        167, 311, 461, 47, 173, 313, 463, 53, 179, 317, 467, 59, 181,
        331, 479, 61, 191, 337, 487, 67, 193, 347, 491, 71, 197, 349,
        499, 73, 199, 353, 503, 79, 211, 359, 509, 83, 223, 367, 521,
        89, 227, 373, 523, 97, 229, 379, 541, 547, 701, 877, 1049,
        557, 709, 881, 1051, 563, 719, 883, 1061, 569, 727, 887,
        1063, 571, 733, 907, 1069, 577, 739, 911, 1087, 587, 743,
        919, 1091, 593, 751, 929, 1093, 599, 757, 937, 1097, 601,
        761, 941, 1103, 607, 769, 947, 1109, 613, 773, 953, 1117,
        617, 787, 967, 1123, 619, 797, 971, 1129, 631, 809, 977,
        1151, 641, 811, 983, 1153, 643, 821, 991, 1163, 647, 823,
        997, 1171, 653, 827, 1009, 1181, 659, 829, 1013, 1187, 661,
        839, 1019, 1193, 673, 853, 1021, 1201, 677, 857, 1031,
        1213, 683, 859, 1033, 1217, 691, 863, 1039, 1223, 1229,
    };

    - (NSUInteger)countOfPrimes;
    {
        return (sizeof(primes) / sizeof(*primes));
    }

    - (id)objectInPrimesAtIndex:(NSUInteger)idx;
    {
        NSParameterAssert(idx < sizeof(primes) / sizeof(*primes));
        return @(primes[idx]);
    }

    @end

We would be able to run:

我们将会运行以下代码：

    Primes *primes = [[Primes alloc] init];
    NSLog(@"The last prime is %@", [primes.primes lastObject]);

This would call `-countOfPrimes` once and then `-objectInPrimesAtIndex:` once with `idx` set to the last index. It would *not* have to wrap all the integers into an `NSNumber` first and then wrap all those into an `NSArray`, only to then extract the last object.

这将会调用一次 `-countOfPrimes` 和一次传入参数 `idx` 作为最后一个索引的 `-objectInPrimesAtIndex:`。为了只取出最后一个值，它*不需要*先把所有的数封装成 `NSNumber` 然后把它们都导入 `NSArray`。

The [*Contacts Editor* sample app](https://github.com/objcio/issue-7-contact-editor) uses the same method to wrap a C++ `std::vector` -- in a contrived example. But it illustrates how this method can be used.

在一个复杂一点的例子中，[*通讯录编辑器*示例 app](https://github.com/objcio/issue-7-contact-editor) 用同样的方法把 C++ `std::vector` 封装以来。它详细说明了应该怎么利用这个方法。

#### Mutable Collections

#### 可变的集合

We can even use collection proxies for mutable collections, i.e. `NSMutableArray`, `NSMutableSet`, and `NSMutableOrderedSet`.

我们也可以在可变集合（例如 `NSMutableArray`，`NSMutableSet`，和 `NSMutableOrderedSet`）中用集合代理。

Accessing such a mutable collection works slightly differently. The caller now has to call one of these methods:

访问这些可变的集合有一点点不同。调用者在这儿需要调用以下其中一个方法：

    - (NSMutableArray *)mutableArrayValueForKey:(NSString *)key;
    - (NSMutableSet *)mutableSetValueForKey:(NSString *)key;
    - (NSMutableOrderedSet *)mutableOrderedSetValueForKey:(NSString *)key;

As a trick, we can have the class return a mutable collection proxy through:

一个窍门：我们可以让一个类用以下方法返回可变集合的代理：

    - (NSMutableArray *)mutableContacts;
    {
        return [self mutableArrayValueForKey:@"wrappedContacts"];
    }

and then implement the correct methods for the key `wrappedContacts`.

然后在实现键 `wrappedContacts` 的一些方法。

We would have to implement both the method listed above for the immutable collection, as well as these:

我们需要实现上面的不变集合的两个方法，还有以下的几个：

<table><thead><tr><th style="text-align:left;padding-right:1em;">NSMutableArray&nbsp;/&nbsp;NSMutableOrderedSet&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</th><th style="text-align:left;padding-right:1em;">NSMutableSet&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</th></tr></thead><tbody><tr><td style="text-align: left;">At least 1 insertion and 1 removal method</td><td style="text-align: left;padding-right:1em;">At least 1 addition and 1 removal method</td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>-insertObject:in&lt;Key&gt;AtIndex:</code></td><td style="text-align: left;padding-right:1em;"><code>-add&lt;Key&gt;Object:</code></td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>-removeObjectFrom&lt;Key&gt;AtIndex:</code></td><td style="text-align: left;padding-right:1em;"><code>-remove&lt;Key&gt;Object:</code></td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>-insert&lt;Key&gt;:atIndexes:</code></td><td style="text-align: left;padding-right:1em;"><code>-add&lt;Key&gt;:</code></td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>-remove&lt;Key&gt;AtIndexes:</code></td><td style="text-align: left;padding-right:1em;"><code>-remove&lt;Key&gt;:</code></td>
</tr><tr><td style="text-align: left;padding-right:1em;"></td><td style="text-align: left;padding-right:1em;">
</td></tr><tr><td style="text-align: left;padding-right:1em;">Optional (performance) one of</td><td style="text-align: left;padding-right:1em;">Optional (performance)</td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>-replaceObjectIn&lt;Key&gt;AtIndex:withObject:</code></td><td style="text-align: left;padding-right:1em;"><code>-intersect&lt;Key&gt;:</code></td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>-replace&lt;Key&gt;AtIndexes:with&lt;Key&gt;:</code></td><td style="text-align: left;padding-right:1em;"><code>-set&lt;Key&gt;:</code></td>
</tr></tbody></table>


As noted above, these mutable collection proxy objects are also very powerful in combination with key-value observing. The KVO mechanism will put detailed change information into the change dictionary when these collections are mutated.

上面提到，这些可变集合代理对象和 KVO 结合起来也十分强大。KVO 机制能在这些集合改变的时候把详细的变化放进 change 字典中。

There are batch-change methods (taking multiple objects) and ones that only take a single object. We recommend picking the one that's the easiest to implement for the given task -- with a slight favor for the batch update ones.

有批量更新（需要传入多个对象）的方法，也有只改变一个对象的方法。我们推荐选择相对于你的 project 最容易实现的那个来写，虽然我们倾向于选择批量更新的那个。

If we implement these methods, we need to be careful about automatic versus manual KVO compliance. By default, Foundation assumes automatic notifications and will send out fine-grained change notifications. If we choose to implement the fine-grained notifications ourselves through:

在实现这些方法的时候，我们要对自动和手动的 KVO 之间的差别十分小心。Foundation 默认自动发出十分详尽的变化通知。如果我们要手动实现发送详细通知的话，我们得这样做：

    -willChange:valuesAtIndexes:forKey:
    -didChange:valuesAtIndexes:forKey:

or:
或者这样做：

    -willChangeValueForKey:withSetMutation:usingObjects:
    -didChangeValueForKey:withSetMutation:usingObjects:

we need to make sure to turn automatic notifications off, otherwise KVO will send out two notifications for every change.

我们要保证先把自动通知关闭，否则每次改变 KVO 都会发出两次通知。

### Common Key-Value Observing Mistakes

### 常见的 KVO 错误

First and foremost, KVO compliance is part of an API. If the owner of a class doesn't promise that the property is KVO compliant, we cannot make any assumption about KVO to work. Apple does document which properties are KVO compliant. For example, the `NSProgress` class lists most of its properties to be KVO compliant.

首先，KVO 兼容是 API 的一部分。如果类的所有者不保证某个属性兼容 KVO，我们就不能保证 KVO 正常工作。苹果文档里有 KVO 兼容属性的文档。例如，`NSProgress` 类的大多数属性都是兼容 KVO 的。

Sometimes people try to trigger KVO by putting `-willChange` and `-didChange` pairs with nothing in between *after* a change was made. This will cause a KVO notification to be posted, but it breaks observers relying on the `NSKeyValueObservingOld` option. Namely this affects KVO's own support for observing key paths. KVO relies on the `NSKeyValueObservingOld` property to support observing key paths.

当做出改变*以后*，有些人试着放空的 `-willChange` 和 `-didChange` 方法来强制 KVO 的触发。KVO 通知虽然会生效，但是这样做破坏了有依赖于 `NSKeyValueObservingOld` 选项的观察者。详细来说，这影响了 KVO 对观察键路径 (key path) 的原生支持。KVO 在观察键路径 (key path) 时依赖于 `NSKeyValueObservingOld` 属性。

We would also like to point out that collections as such are not observable. KVO is about observing *relationships* rather than collections. We cannot observe an `NSArray`; we can only observe a property on an object -- and that property may be an `NSArray`. As an example, if we have a `ContactList` object, we can observe its `contacts` property, but we cannot pass an `NSArray` to `-addObserver:forKeyPath:...` as the object to be observed.

我们也要指出这些不能被观察的集合。KVO 旨在观察*关系 (relationship)* 而不是集合。我们不能观察 `NSArray`，我们只能观察一个对象的属性——而这个属性有可能是 `NSArray`。举例说，如果我们有一个 `ContactList` 对象，我们可以观察它的 `contacts` 属性。但是我们不能向要观察对象的 `-addObserver:forKeyPath:...` 传入 `NSArray`。

Likewise, observing `self` doesn't always work. It's probably not a good design pattern, either.

相似地，观察 `self` 不是永远都生效的。而且这不是一个好的设计。

### Debugging Key-Value Observing

### 排错 KVO

Inside `lldb` you can dump the observation info of an observed object, like so:

你可以在 `lldb` 里查看一个被观察对象的所有观察信息。

    (lldb) po [observedObject observationInfo]

This prints lots of information about who's observing what.

这会打印出有关谁观察谁之类的很多信息。

The format is private and we mustn't rely on anything about it -- Apple is free to change it at any point in time. But it's a very powerful debugging tool.

这个信息的格式不是公开的，我们不能让任何东西依赖它，因为苹果随时都可以改变它。不过这是一个很强大的排错工具。

<a name="key-value-validation"> </a>

## Key-Value Validation

## 键值验证 (KVV)

On a final note, key-value validation is also part of the key-value coding API. It's a consistent API for validation property values, but it hardly provides any logic or functionality on its own.

最后提示，KVV 也是 KVC API 的一部分。这是一个用来验证属性值的 API，只是它光靠自己很难提供逻辑和功能。

But if we're writing model classes that can validate values, we should implement the API the way set forward by key-value validation to make sure it's consistent. Key-value validation is the Cocoa convention for validating values in model classes.

如果我们写能够验证值的 model 类的话，我们就应该实现 KVV 的 API 来保证一致性。用 KVV 验证 model 类的值是 Cocoa 的惯例。

Let us stress this again: key-value coding will not do any validation, and it will not call the key-value validation methods. Your controller will have to do that. Implementing your validation methods according to key-value validation will make sure they're consistent, though.

让我们在一次强调一下：KVC 不会做任何的验证，也不会调用任何 KVV 的方法。那是你的控制器需要做的事情。通过 KVV 实现你自己的验证方法会保证它们的一致性。

A simple example would be:

以下是一个简单的例子：

    - (IBAction)nameFieldEditingDidEnd:(UITextField *)sender;
    {
        NSString *name = [sender text];
        NSError *error = nil;
        if ([self.contact validateName:&name error:&error]) {
            self.contact.name = name;
        } else {
            // Present the error to the user
        }
        sender.text = self.contact.name;
    }

The powerful thing is that we're asking the model class (`Contact` in this case) to validate the `name`, and at the same time we're giving the model class an opportunity to sanitize the name.

它强大之处在于，当 model 类（`Contact`）验证 `name` 到时候，会有机会去净化名字。

If we want to make sure the name doesn't have any leading white space, that's logic which should live inside the model object. The `Contact` class would implement the key-value validation method for the `name` property like this:

如果我们想让名字不要有前后的空白字符，我们应该把这些逻辑放在 model 对象里面。`Contact` 类可以像这样实现 KVV：

    - (BOOL)validateName:(NSString **)nameP error:(NSError * __autoreleasing *)error
    {
        if (*nameP == nil) {
            *nameP = @"";
            return YES;
        } else {
            *nameP = [*nameP stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            return YES;
        }
    }

The [*Contact Editor* sample](https://github.com/objcio/issue-7-contact-editor) illustrates this in the `DetailViewController` and `Contact` class.

[*通讯录*示例](https://github.com/objcio/issue-7-contact-editor) 里的 `DetailViewController` 和 `Contact` 类详解了这个用法。
