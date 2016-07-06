Key-value coding (KVC) 和 key-value observing (KVO) 是两种能让我们驾驭 Objective-C 动态特性并简化代码的机制。在这篇文章里，我们将接触一些如何利用这些特性的例子。

## 观察 model 对象的变化

在 Cocoa 的模型-视图-控制器 (Model-view-controller)架构里，控制器负责让视图和模型同步。这一共有两步：当 model 对象改变的时候，视图应该随之改变以反映模型的变化；当用户和控制器交互的时候，模型也应该做出相应的改变。

*KVO* 能帮助我们让视图和模型保持同步。控制器可以观察视图依赖的属性变化。

让我们看一个例子：我们的模型类 `LabColor` 代表一种 [Lab色彩空间](https://zh.wikipedia.org/wiki/Lab%E8%89%B2%E5%BD%A9%E7%A9%BA%E9%97%B4)里的颜色。和 RGB 不同，这种色彩空间有三个元素 *L*, *a*, *b*。我们要做一个用来改变这些值的滑块和一个显示颜色的方块区域。

我们的模型类有以下三个用来代表颜色的属性：

    @property (nonatomic) double lComponent;
    @property (nonatomic) double aComponent;
    @property (nonatomic) double bComponent;

### 依赖的属性

我们需要从这个类创建一个 `UIColor` 对象来显示出颜色。我们添加三个额外的属性，分别对应 R, G, B：

    @property (nonatomic, readonly) double redComponent;
    @property (nonatomic, readonly) double greenComponent;
    @property (nonatomic, readonly) double blueComponent;

    @property (nonatomic, strong, readonly) UIColor *color;

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

这些代码没什么令人激动的地方。有趣的是 `greenComponent` 属性依赖于 `lComponent` 和 `aComponent`。不论何时设置 `lComponent` 的值，我们需要让 RGB 三个 component 中与其相关的成员以及 `color` 属性都要得到通知以保持一致。这一点这在 KVO 中很重要。

Foundation 框架提供的表示属性依赖的机制如下：

    + (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key

更详细的如下：

    + (NSSet *)keyPathsForValuesAffecting<键名>

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

现在我们完整的表达了属性之间的依赖关系。请注意，我们可以把这些属性链接起来。打个比方，如果我们写一个子类去 override `redComponent` 方法，这些依赖关系仍然能正常工作。

### 观察变化

现在让我们目光转向控制器。 `NSViewController` 的子类拥有 `LabColor`  model 对象作为其属性。

    @interface ViewController ()

    @property (nonatomic, strong) LabColor *labColor;

    @end
    
我们把视图控制器注册为观察者来接收 KVO 的通知，这可以用以下 `NSObject` 的方法来实现：

    - (void)addObserver:(NSObject *)anObserver
             forKeyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
                context:(void *)context

这会让以下方法：

    - (void)observeValueForKeyPath:(NSString *)keyPath
                          ofObject:(id)object
                            change:(NSDictionary *)change
                           context:(void *)context

在当 `keyPath` 的值改变的时候在观察者 `anObserver` 上面被调用。这个 API 看起来有一点吓人。更糟糕的是，我们还得记得调用以下的方法

    - (void)removeObserver:(NSObject *)anObserver
                forKeyPath:(NSString *)keyPath

来移除观察者，否则我们我们的 app 会因为某些奇怪的原因崩溃。

对于大多数的应用来说，*KVO* 可以通过辅助类用一种更简单优雅的方式实现。我们在视图控制器添加以下的*观察记号（Observation token）*属性：

    @property (nonatomic, strong) id colorObserveToken;

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

[`KeyValueObserver` 辅助类](https://github.com/objcio/issue-7-lab-color-space-explorer/blob/master/Lab%20Color%20Space%20Explorer/KeyValueObserver.m) 封装了 `-addObserver:forKeyPath:options:context:`，`-observeValueForKeyPath:ofObject:change:context:`和`-removeObserverForKeyPath:` 的调用，让视图控制器远离杂乱的代码。

### 整合到一起

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

所有的代码都在我们的 GitHub [示例代码](https://github.com/objcio/issue-7-lab-color-space-explorer) 中找到。

## 手动通知 vs 自动通知

我们刚才所做的事情有点神奇，但是实际上发生的事情是，当 `LabColor` 实例的 `-setLComponent:` 等方法被调用的时候以下方法：

    - (void)willChangeValueForKey:(NSString *)key

和：

    - (void)didChangeValueForKey:(NSString *)key

会在运行 `-setLComponent:` 中的代码之前以及之后被自动调用。如果我们写了 `-setLComponent:` 或者我们选择使用自动 synthesize 的 `lComponent` 的 accessor 到时候就会发生这样的事情。

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

我们关闭了 `-willChangeValueForKey:` 和 `-didChangeValueForKey:` 的自动调用，然后我们手动调用他们。我们只应该在关闭了自动调用的时候我们才需要在 setter 方法里手动调用 `-willChangeValueForKey:` 和 `-didChangeValueForKey:`。大多数情况下，这样优化不会给我们带来太多好处。

如果我们在 accessor 方法之外改变实例对象（如 `_lComponent` ），我们要特别小心地和刚才一样封装 `-willChangeValueForKey:` 和 `-didChangeValueForKey:`。不过在多数情况下，我们只用 accessor 方法的话就可以了，这样代码会简洁很多。

## KVO 和 context

有时我们会有理由不想用 `KeyValueObserver` 辅助类。创建另一个对象会有额外的性能开销。如果我们观察很多个键的话，这个开销可能会变得明显。

如果我们在实现一个类的时候把它自己注册为观察者的话：

    - (void)addObserver:(NSObject *)anObserver
             forKeyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
                context:(void *)context

一个*非常*重要的点是我们要传入一个这个类唯一的 `context`。我们推荐把以下代码

    static int const PrivateKVOContext;

写在这个类 `.m` 文件的顶端，然后我们像这样调用 API 并传入 `PrivateKVOContext` 的指针：

    [otherObject addObserver:self forKeyPath:@"someKey" options:someOptions context:&PrivateKVOContext];

然后我们这样写 `-observeValueForKeyPath:...` 的方法：

    - (void)observeValueForKeyPath:(NSString *)keyPath
                          ofObject:(id)object
                            change:(NSDictionary *)change
                           context:(void *)context
    {
        if (context == &PrivateKVOContext) {
            // 这里写相关的观察代码
        } else {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }

这将确保我们写的子类都是正确的。如此一来，子类和父类都能安全的观察同样的键值而不会冲突。否则我们将会碰到难以 debug 的奇怪行为。

## 进阶 KVO

我们常常需要当一个值改变的时候更新 UI，但是我们也要在第一次运行代码的时候更新一次 UI。我们可以用 KVO 并添加 `NSKeyValueObservingOptionInitial` 的选项 来一箭双雕地做好这样的事情。这将会让 KVO 通知在调用 `-addObserver:forKeyPath:...` 到时候也被触发。

### 之前和之后

当我们注册 KVO 通知的时候，我们可以添加 `NSKeyValueObservingOptionPrior` 选项，这能使我们在键值改变之前被通知。这和`-willChangeValueForKey:`被触发的时间相对应。

如果我们注册通知的时候附加了 `NSKeyValueObservingOptionPrior` 选项，我们将会收到两个通知：一个在值变更前，另一个在变更之后。变更前的通知将会在 `change` 字典中有不同的键。我们可以像以下这样区分通知是在改变之前还是之后被触发的：

    if ([change[NSKeyValueChangeNotificationIsPriorKey] boolValue]) {
        // 改变之前
    } else {
        // 改变之后
    }

### 值

如果我们需要改变前后的值，我们可以在 KVO 选项中加入 `NSKeyValueObservingOptionNew` 和/或 `NSKeyValueObservingOptionOld`。

更简单的办法是用 `NSKeyValueObservingOptionPrior` 选项，随后我们就可以用以下方式提取出改变前后的值：

    id oldValue = change[NSKeyValueChangeOldKey];
    id newValue = change[NSKeyValueChangeNewKey];

通常来说 KVO 会在 `-willChangeValueForKey:` 和 `-didChangeValueForKey:` 被调用的时候存储相应键的值。

### 索引

KVO 对一些集合类也有很强的支持，以下方法会返回集合对象：

    -mutableArrayValueForKey:
    -mutableSetValueForKey:
    -mutableOrderedSetValueForKey:

我们将会详细解释这是怎么工作的。如果你使用这些方法，change 字典里会包含键值变化的类型（添加、删除和替换）。对于有序的集合，change 字典会包含受影响的 index。

集合代理对象和变化的通知在用于更新UI的时候非常有效，尤其是处理大集合的时候。但是它们需要花费你一些心思。

## KVO 和线程

一个需要注意的地方是，KVO 行为是同步的，并且发生与所观察的值发生变化的同样的线程上。没有队列或者 Run-loop 的处理。手动或者自动调用 `-didChange...` 会触发 KVO 通知。

所以，当我们试图从其他线程改变属性值的时候我们应当十分小心，除非能确定所有的观察者都用线程安全的方法处理 KVO 通知。通常来说，我们不推荐把 KVO 和多线程混起来。如果我们要用多个队列和线程，我们不应该在它们互相之间用 KVO。

KVO 是同步运行的这个特性非常强大，只要我们在单一线程上面运行（比如主队列 main queue），KVO 会保证下列两种情况的发生：

首先，如果我们调用一个支持 KVO 的 setter 方法，如下所示：

    self.exchangeRate = 2.345;

KVO 能保证所有 `exchangeRate` 的观察者在 setter 方法返回前被通知到。

其次，如果某个键被观察的时候附上了 `NSKeyValueObservingOptionPrior` 选项，直到 `-observe...` 被调用之前， `exchangeRate` 的 accessor 方法都会返回同样的值。

## KVC

最简单的 KVC 能让我们通过以下的形式访问属性：

    @property (nonatomic, copy) NSString *name;

取值：

    NSString *n = [object valueForKey:@"name"]

设定：

    [object setValue:@"Daniel" forKey:@"name"]

值得注意的是这个不仅可以访问作为对象属性，而且也能访问一些标量（例如 `int` 和 `CGFloat`）和 struct（例如 `CGRect`）。Foundation 框架会为我们自动封装它们。举例来说，如果有以下属性：

    @property (nonatomic) CGFloat height;

我们可以这样设置它：

    [object setValue:@(20) forKey:@"height"]

KVC 允许我们用属性的字符串名称来访问属性，字符串在这儿叫做*键*。有些情况下，这会使我们非常灵活地简化代码。我们下一节介绍例子*简化列表 UI*。

KVC 还有更多可以谈的。集合（`NSArray`，`NSSet` 等）结合 KVC 可以拥有一些强大的集合操作。还有，对象可以支持用 KVC 通过代理对象访问非常规的属性。


### 简化列表 UI

假设我们有这样一个对象：

    @interface Contact : NSObject

    @property (nonatomic, copy) NSString *name;
    @property (nonatomic, copy) NSString *nickname;
    @property (nonatomic, copy) NSString *email;
    @property (nonatomic, copy) NSString *city;

    @end

还有一个 detail 视图控制器，含有四个对应的 `UITextField` 属性：

    @interface DetailViewController ()

    @property (weak, nonatomic) IBOutlet UITextField *nameField;
    @property (weak, nonatomic) IBOutlet UITextField *nicknameField;
    @property (weak, nonatomic) IBOutlet UITextField *emailField;
    @property (weak, nonatomic) IBOutlet UITextField *cityField;

    @end

我们可以简化更新 UI 的逻辑。首先我们需要两个方法：一个返回 model 里我们用到的所有键的方法，一个把键映射到对应的文本框的方法：

    - (NSArray *)contactStringKeys;
    {
        return @[@"name", @"nickname", @"email", @"city"];
    }

    - (UITextField *)textFieldForModelKey:(NSString *)key;
    {
        return [self valueForKey:[key stringByAppendingString:@"Field"]];
    }

有了这个，我们可以从 model 里更新文本框，如下所示：

    - (void)updateTextFields;
    {
        for (NSString *key in self.contactStringKeys) {
            [self textFieldForModelKey:key].text = [self.contact valueForKey:key];
        }
    }

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

注意：我们之后会添加验证输入的部分，在[*键值验证*](#key-value-validation)里会提到。

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

有了这个，我们的 [detail 视图控制器](https://github.com/objcio/issue-7-contact-editor/blob/master/Contact%20Editor/DetailViewController.m) 就能正常工作了。

整个项目可以在 [GitHub](https://github.com/objcio/issue-7-contact-editor) 上找到。它也用了我们后面提到的[*键值验证*](#key-value-validation)。

### 键路径（Key Path）

KVC 同样允许我们通过关系来访问对象。假设 `person` 对象有属性 `address`，`address` 有属性 `city`，我们可以这样通过 `person` 来访问 `city`：

    [person valueForKeyPath:@"address.city"]

值得注意的是这里我们调用 `-valueForKeyPath:` 而不是 `-valueForKey:`。

### Key-Value Coding Without `@property`

### 不需要 `@property` 的 KVC

我们可以实现一个支持 KVC 而不用 `@property` 和 `@synthesize` 或是自动 synthesize 的属性。最直接的方式是添加 `-<key>` 和 `-set<Key>:` 方法。例如我们想要 `name` ，我们这样做：

    - (NSString *)name;
    - (void)setName:(NSString *)name;

这完全等于 `@property` 的实现方式。

但是当标量和 struct 的值被传入 `nil` 的时候尤其需要注意。假设我们要 `height` 属性支持 KVC 我们写了以下的方法：

    - (CGFloat)height;
    - (void)setHeight:(CGFloat)height;

然后我们这样调用：

    [object setValue:nil forKey:@"height"]

这会抛出一个 exception。要正确的处理 `nil`，我们要像这样 override `-setNilValueForKey:`

    - (void)setNilValueForKey:(NSString *)key
    {
        if ([key isEqualToString:@"height"]) {
            [self setValue:@0 forKey:key];
        } else
            [super setNilValueForKey:key];
    }

我们可以通过 override 这些方法来让一个类支持 KVC：

    - (id)valueForUndefinedKey:(NSString *)key;
    - (void)setValue:(id)value forUndefinedKey:(NSString *)key;


这也许看起来很怪，但这可以让一个类动态的支持一些键的访问。但是这两个方法会在性能上拖后腿。

附注：Foundation 框架支持直接访问实例变量。请小心的使用这个特性。你可以去查看 `+accessInstanceVariablesDirectly` 的文档。这个值默认是 `YES` 的时候，Foundation 会按照 `_<key>`, `_is<Key>`, `<key>` 和 `is<Key>` 的顺序查找实例变量。


### 集合的操作

一个常常被忽视的 KVC 特性是它对集合操作的支持。举个例子，我们可以这样来获得一个数组中最大的值：

    NSArray *a = @[@4, @84, @2];
    NSLog(@"max = %@", [a valueForKeyPath:@"@max.self"]);

或者说，我们有一个 `Transaction` 对象的数组，对象有属性 `amount` 的话，我们可以这样获得最大的 `amount`：

    NSArray *a = @[transaction1, transaction2, transaction3];
    NSLog(@"max = %@", [a valueForKeyPath:@"@max.amount"]);

当我们调用 `[a valueForKeyPath:@"@max.amount"]` 的时候，它会在数组 `a` 的每个元素中调用 `-valueForKey:@"amount"` 然后返回最大的那个。

KVC 的苹果官方文档有一个章节 [Collection Operators](https://developer.apple.com/library/ios/documentation/cocoa/conceptual/KeyValueCoding/Articles/CollectionOperators.html) 详细的讲述了类似的用法。


### 通过集合代理对象来实现 KVC

虽然我们可以像对待一般的对象一样用 KVC 深入集合内部（`NSArray` 和 `NSSet` 等），但是通过集合代理对象， KVC 也让我们实现一个兼容 KVC 的集合。这是一个颇为高端的技巧。

当我们在对象上调用 `-valueForKey:` 的时候，它可以返回 `NSArray`，`NSSet` 或是 `NSOrderedSet` 的集合代理对象。这个类没有实现通常的 `-<Key>` 方法，但是它实现了代理对象所需要使用的很多方法。

如果我们希望一个类支持通过代理对象的 `contacts` 键返回一个 `NSArray`，我们可以这样写：

    - (NSUInteger)countOfContacts;
    - (id)objectInContactsAtIndex:(NSUInteger)idx;

这样做的话，当我们调用 `[object valueForKey:@"contacts”]` 的时候，它会返回一个由这两个方法来代理*所有*调用方法的 `NSArray` 对象。这个数组支持所有正常的对 `NSArray` 的调用。换句话说，调用者并不知道返回的是一个真正的 `NSArray`， 还是一个代理的数组。

对于 `NSSet` 和 `NSOrderedSet`，如果要做同样的事情，我们需要实现的方法是：

<table><thead><tr><th style="text-align:left;padding-right:1em;">NSArray</th><th style="text-align:left;padding-right:1em;">NSSet&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</th><th style="text-align:left;padding-right:1em;">NSOrderedSet&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</th></tr></thead><tbody><tr><td style="text-align:left;padding-right:1em;"><code>-countOf&lt;Key&gt;</code></td><td style="text-align:left;padding-right:1em;"><code>-countOf&lt;Key&gt;</code></td><td style="text-align:left;padding-right:1em;"><code>-countOf&lt;Key&gt;</code></td>
</tr><tr><td style="text-align:left;padding-right:1em;"></td><td style="text-align:left;padding-right:1em;"><code>-enumeratorOf&lt;Key&gt;</code></td><td style="text-align:left;padding-right:1em;"><code>-indexIn&lt;Key&gt;OfObject:</code></td>
</tr><tr><td style="text-align:left;padding-right:1em;">以下两者二选一</td><td style="text-align:left;padding-right:1em;"><code>-memberOf&lt;Key&gt;:</code></td><td style="text-align:left;padding-right:1em;">
</td></tr><tr><td style="text-align:left;padding-right:1em;"><code>-objectIn&lt;Key&gt;AtIndex:</code></td><td style="text-align:left;padding-right:1em;"></td><td style="text-align:left;padding-right:1em;">以下两者二选一</td>
</tr><tr><td style="text-align:left;padding-right:1em;"><code>-&lt;key&gt;AtIndexes:</code></td><td style="text-align:left;padding-right:1em;"></td><td style="text-align:left;padding-right:1em;"><code>-objectIn&lt;Key&gt;AtIndex:</code></td>
</tr><tr><td style="text-align:left;padding-right:1em;"></td><td style="text-align:left;padding-right:1em;"></td><td style="text-align:left;padding-right:1em;"><code>-&lt;key&gt;AtIndexes:</code></td>
</tr><tr><td style="text-align:left;padding-right:1em;">可选（增强性能）</td><td style="text-align:left;padding-right:1em;"></td><td style="text-align:left;padding-right:1em;">
</td></tr><tr><td style="text-align:left;padding-right:1em;"><code>-get&lt;Key&gt;:range:</code></td><td style="text-align:left;padding-right:1em;"></td><td style="text-align:left;padding-right:1em;">可选（增强性能）</td>
</tr><tr><td style="text-align:left;padding-right:1em;"></td><td style="text-align:left;padding-right:1em;"></td><td style="text-align: left;"><code>-get&lt;Key&gt;:range:</code></td>
</tr></tbody></table>


*可选* 的一些方法可以增强代理对象的性能。

虽然只有特殊情况下我们用这些代理对象才会有意义，但是在这些情况下代理对象非常的有用。想象一下我们有一个很大的数据结构，调用者不需要（一次性）访问所有的对象。

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

我们将会运行以下代码：

    Primes *primes = [[Primes alloc] init];
    NSLog(@"The last prime is %@", [primes.primes lastObject]);

这将会调用一次 `-countOfPrimes` 和一次传入参数 `idx` 作为最后一个索引的 `-objectInPrimesAtIndex:`。为了只取出最后一个值，它*不需要*先把所有的数封装成 `NSNumber` 然后把它们都导入 `NSArray`。

在一个复杂一点的例子中，[*通讯录编辑器*示例 app](https://github.com/objcio/issue-7-contact-editor) 用同样的方法把 C++ `std::vector` 封装以来。它详细说明了应该怎么利用这个方法。


#### 可变的集合

我们也可以在可变集合（例如 `NSMutableArray`，`NSMutableSet`，和 `NSMutableOrderedSet`）中用集合代理。

访问这些可变的集合有一点点不同。调用者在这儿需要调用以下其中一个方法：

    - (NSMutableArray *)mutableArrayValueForKey:(NSString *)key;
    - (NSMutableSet *)mutableSetValueForKey:(NSString *)key;
    - (NSMutableOrderedSet *)mutableOrderedSetValueForKey:(NSString *)key;

一个窍门：我们可以让一个类用以下方法返回可变集合的代理：

    - (NSMutableArray *)mutableContacts;
    {
        return [self mutableArrayValueForKey:@"wrappedContacts"];
    }

然后在实现键 `wrappedContacts` 的一些方法。

我们需要实现上面的不变集合的两个方法，还有以下的几个：

<table><thead><tr><th style="text-align:left;padding-right:1em;">NSMutableArray&nbsp;/&nbsp;NSMutableOrderedSet&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</th><th style="text-align:left;padding-right:1em;">NSMutableSet&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</th></tr></thead><tbody><tr><td style="text-align: left;">至少实现一个插入方法和一个删除方法</td><td style="text-align: left;padding-right:1em;">至少实现一个插入方法和一个删除方法</td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>-insertObject:in&lt;Key&gt;AtIndex:</code></td><td style="text-align: left;padding-right:1em;"><code>-add&lt;Key&gt;Object:</code></td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>-removeObjectFrom&lt;Key&gt;AtIndex:</code></td><td style="text-align: left;padding-right:1em;"><code>-remove&lt;Key&gt;Object:</code></td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>-insert&lt;Key&gt;:atIndexes:</code></td><td style="text-align: left;padding-right:1em;"><code>-add&lt;Key&gt;:</code></td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>-remove&lt;Key&gt;AtIndexes:</code></td><td style="text-align: left;padding-right:1em;"><code>-remove&lt;Key&gt;:</code></td>
</tr><tr><td style="text-align: left;padding-right:1em;"></td><td style="text-align: left;padding-right:1em;">
</td></tr><tr><td style="text-align: left;padding-right:1em;">可选（增强性能）以下方法二选一</td><td style="text-align: left;padding-right:1em;">可选（增强性能）</td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>-replaceObjectIn&lt;Key&gt;AtIndex:withObject:</code></td><td style="text-align: left;padding-right:1em;"><code>-intersect&lt;Key&gt;:</code></td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>-replace&lt;Key&gt;AtIndexes:with&lt;Key&gt;:</code></td><td style="text-align: left;padding-right:1em;"><code>-set&lt;Key&gt;:</code></td>
</tr></tbody></table>


上面提到，这些可变集合代理对象和 KVO 结合起来也十分强大。KVO 机制能在这些集合改变的时候把详细的变化放进 change 字典中。

有批量更新（需要传入多个对象）的方法，也有只改变一个对象的方法。我们推荐选择相对于给定任务来说最容易实现的那个来写，虽然我们有一点点倾向于选择批量更新的那个。

在实现这些方法的时候，我们要对自动和手动的 KVO 之间的差别十分小心。Foundation 默认自动发出十分详尽的变化通知。如果我们要手动实现发送详细通知的话，我们得实现这些：

    -willChange:valuesAtIndexes:forKey:
    -didChange:valuesAtIndexes:forKey:

或者这些：

    -willChangeValueForKey:withSetMutation:usingObjects:
    -didChangeValueForKey:withSetMutation:usingObjects:

我们要保证先把自动通知关闭，否则每次改变 KVO 都会发出两次通知。


### 常见的 KVO 错误

首先，KVO 兼容是 API 的一部分。如果类的所有者不保证某个属性兼容 KVO，我们就不能保证 KVO 正常工作。苹果文档里有 KVO 兼容属性的文档。例如，`NSProgress` 类的大多数属性都是兼容 KVO 的。

当做出改变*以后*，有些人试着放空的 `-willChange` 和 `-didChange` 方法来强制 KVO 的触发。KVO 通知虽然会生效，但是这样做破坏了有依赖于 `NSKeyValueObservingOld` 选项的观察者。详细来说，这影响了 KVO 对观察键路径 (key path) 的原生支持。KVO 在观察键路径 (key path) 时依赖于 `NSKeyValueObservingOld` 属性。

我们也要指出有些集合是不能被观察的。KVO 旨在观察*关系 (relationship)* 而不是集合。我们不能观察 `NSArray`，我们只能观察一个对象的属性——而这个属性有可能是 `NSArray`。举例说，如果我们有一个 `ContactList` 对象，我们可以观察它的 `contacts` 属性。但是我们不能向要观察对象的 `-addObserver:forKeyPath:...` 传入一个 `NSArray`。

相似地，观察 `self` 不是永远都生效的。而且这不是一个好的设计。


### 调试 KVO

你可以在 `lldb` 里查看一个被观察对象的所有观察信息。

    (lldb) po [observedObject observationInfo]

这会打印出有关谁观察谁之类的很多信息。

这个信息的格式不是公开的，我们不能让任何东西依赖它，因为苹果随时都可以改变它。不过这是一个很强大的排错工具。


<a name="key-value-validation"> </a>

## 键值验证 (KVV)

最后提示，KVV 也是 KVC API 的一部分。这是一个用来验证属性值的 API，只是它光靠自己很难提供逻辑和功能。

如果我们写能够验证值的 model 类的话，我们就应该实现 KVV 的 API 来保证一致性。用 KVV 验证 model 类的值是 Cocoa 的惯例。

让我们在一次强调一下：KVC 不会做任何的验证，也不会调用任何 KVV 的方法。那是你的控制器需要做的事情。通过 KVV 实现你自己的验证方法会保证它们的一致性。

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

它强大之处在于，当 model 类（`Contact`）验证 `name` 的时候，会有机会去处理名字。

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

[*通讯录*示例](https://github.com/objcio/issue-7-contact-editor) 里的 `DetailViewController` 和 `Contact` 类详解了这个用法。

---

 

原文 [Key-Value Coding and Observing](http://www.objc.io/issue-7/key-value-coding-and-observing.html)