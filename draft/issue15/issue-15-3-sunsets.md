#依赖注入

[Issue #15 Testing](http://www.objc.io/issue-15/index.html), August 2014

By [Jon Reid](http://qualitycoding.org/about/)

从一个例子开始，比如说写了这样一个方法：

`- (NSNumber *)nextReminderId
{
    NSNumber *currentReminderId = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentReminderId"];
    if (currentReminderId) {
        // Increment the last reminderId
        currentReminderId = @([currentReminderId intValue] + 1);
    } else {
        // Set to 0 if it doesn't already exist
        currentReminderId = @0;
    }
    // Update currentReminderId to model
    [[NSUserDefaults standardUserDefaults] setObject:currentReminderId forKey:@"currentReminderId"];

    return currentReminderId;
}`

如何针对这个方法编写单元测试（unit tests）呢？这里需要注意一点，该方法中有操作一个不属于其控制的对象`NSUserDefaults`。

容我赘述，就这个例子展开说，现在问题已经由“如何去测试一个操作了`NSUserDefaults`的方法？”演化为“若一个对象对[快速且可重复](http://pragprog.com/magazines/2012-01/unit-tests-are-first)的测试有着直接影响，它又不受某个方法控制但又被该方法操作，如何对这样的方法进行单元测试呢？”。

目前单元测试的最大障碍是，如何处理需要进行单元测试的代码和其所涉及的外部代码的依赖关系。依赖注入(dependency injection)简称DI这一范畴内有一系列方法专门用于解决此类问题。

##依赖注入的几种形式

其实一提到DI，很多人会直接想到依赖注入框架或者是控制反转(Inversion of Control简称IoC)容器。请把这些概念都暂且搁置，我会在后面的FAQ（常见问题）中做说明。

现行有很多技术可以处理在依赖中注入某些东西这件事情。比如说Objective-C runtime中的swizzling就是其一，swizzling可以在运行时动态的对方法进行替换。当然也有人提出质疑，他们觉得[swizzling的存在让DI变得无关紧要](http://sharpfivesoftware.com/2013/03/20/dependency-injection-is-not-a-virtue-in-objective-c/)，甚至应尽量避免使用DI。但是我更倾向于那些使依赖关系能够清晰化的代码，因为这样更便于观察它们（并且促使我们去处理那些由于依赖过于复杂而导致的腐烂代码味道，或者是错误的代码）。

接下来我们快速了解一下DI的形式。除一个例外，以下列举的形式均出自Mark Seemann的*[Dependency Injection in .Net](http://www.amazon.com/Dependency-Injection-NET-Mark-Seemann/dp/1935182501)*

###构造器注入

*注意：尽管Objective-C本身没有所谓的构造器而是使用初始化方法，但因为构造器注入是DI的标准概念，放到各种语言中也是普遍适用的，所以我还是准备用构造器注入来代指初始化注入。*

构造器注入，即将某个依赖（对象）传入到构造器中（在Objective-C中指特定的初始化方法）并存储起来，以便在后续过程中适用：

`@interface Example ()`
`@property (nonatomic, strong, readonly) NSUserDefaults *userDefaults;
@end`

`@implementation Example
- (instancetype)initWithUserDefaults:(NSUserDefaults *userDefaults)
{
    self = [super init];
    if (self) {
        _userDefaults = userDefaults;
    }
    return self;
}
@end`

可以用实例变量或者是属性来存储依赖对象。上面的例子中用一个只读的属性来存储，防止依赖对象被篡改。

对`NSUserDefaults`进行注入看起来会比较怪，这可能也是这个例子的不足之处。注意，`NSUserDefaults`作为依赖对象，脸上就写着“麻烦制造者”这几个字。其实用一个抽象类型的对象（像id<protocol>这种）来作为依赖可能会比指定某个具体类型要更好一些，但本文就不做更多展开了。还是继续以`NSUserDefaults`来说明。

至此，Example类中每一处要使用单例`[NSUserDefaults standardUserDefaults]`的地方，都可以用`self.userDefaults`来替代：

`- (NSNumber *)nextReminderId
{
    NSNumber *currentReminderId = [self.userDefaults objectForKey:@"currentReminderId"];
    if (currentReminderId) {
        currentReminderId = @([currentReminderId intValue] + 1);
    } else {
        currentReminderId = @0;
    }
    [self.userDefaults setObject:currentReminderId forKey:@"currentReminderId"];
    return currentReminderId;
}`

###属性注入

属性注入，下面例子中的`nextReminderId`也是同样的要引用`self.userDefaults`，这次不是将依赖对象传递给初始化方法，而是采用属性赋值方式：

`@interface Example
@property (nonatomic, strong) NSUserDefaults *userDefaults;
- (NSNumber *)nextReminderId;
@end`

可在单元测试中创建一个对象，然后通过属性setter为`userDefaults`赋值。这里需要在getter中做懒初始化操作为其设置一个适当的默认值，这样即使从未对`userDefaults`这个属性赋非nil值或者赋了nil值，也都能保证始终可以通过getter拿到一个确切的值：

`- (NSUserDefaults *)userDefaults
{
    if (!_userDefaults) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return _userDefaults;
}`

这样的话，对`userDefaults`来说，如果在使用者取值之前做过赋值操作，那么从`self.userDefaults`得到的就是通过setter赋的值。如果这个属性在使用前未被赋值，从`self.userDefaults`得到的就是`[NSUserDefaults standardUserDefaults]`。

###方法注入

如果依赖对象只在某一个方法中被使用，则可以利用方法参数做注入：

`- (NSNumber *)nextReminderIdWithUserDefaults:(NSUserDefaults *)userDefaults
{
    NSNumber *currentReminderId = [userDefaults objectForKey:@"currentReminderId"];
    if (currentReminderId) {
        currentReminderId = @([currentReminderId intValue] + 1);
    } else {
        currentReminderId = @0;
    }
    [userDefaults setObject:currentReminderId forKey:@"currentReminderId"];
    return currentReminderId;
}`

再一次说明，这样看起来可能会很奇怪，并不是所有的例子中`NSUserDefaults`作为依赖都显得恰如其分。比如说这个例子中，如果使用`NSDate`做注入参数传入可能更会彰显其特点（后面对每种注入方式的优点做阐述的时候会有更深入的探讨）。

###环境上下文

当通过一个类方法（例如单例）来访问依赖对象时，在单元测试中可以通过两种方式来控制依赖对象：

* 如果可以控制单例本身，则可以通过**公开其属性**来控制其状态。

* 如果上述方式无效或者所有操作的单例不归自己管理，**此时就该运用swizzle了：**直接替换类方法，让其返回你所期望的返回值。


这里不会给出具体的swizzling的例子；相关的资源有很多，感兴趣的朋友可以自行查找。这边要说明的就是swizzling*可以*用于DI。以上就是对DI形式的简单介绍，后面会对他们各自的优缺点做进一步的对比分析。请大家继续阅读。

###利用抽取和复写进行调用

接下来要说的这个技术点不在Seemann书中所涉及的DI形式讨论范畴。关于抽象和复写的调用来自于Michael Feathers的[Working Effectively With Legacy Code](http://www.amazon.com/Working-Effectively-Legacy-Michael-Feathers/dp/0131177052)。下面介绍一下如何将这个概念应用到我们的`NSUserDefaults`例子中去，具体分为三步：

步骤1：随便找一处对`[NSUserDefaults standardUserDefaults]`的调用。利用IDE（Xcode或者AppCode都可以）的自动重构(automated refactoring)功能将其抽取成一个新的方法。

步骤2：将其他所有对`[NSUserDefaults standardUserDefaults]`的调用均替换成步骤1中抽取的方法（注意不要把已抽取的方法中的`[NSUserDefaults standardUserDefaults]`替换成方法自身，囧）。

修改后的代码如下：

`- (NSNumber *)nextReminderId
{
    NSNumber *currentReminderId = [[self userDefaults] objectForKey:@"currentReminderId"];
    if (currentReminderId) {
        currentReminderId = @([currentReminderId intValue] + 1);
    } else {
        currentReminderId = @0;
    }
    [[self userDefaults] setObject:currentReminderId forKey:@"currentReminderId"];
    return currentReminderId;
}`

`- (NSUserDefaults *)userDefaults
{
    return [NSUserDefaults standardUserDefaults];
}`

妥当完成后，进入最后一步：

步骤3:创建一个专门的**测试子类，**复写刚刚抽取的方法：


`@interface TestingExample : Example
@end`

`@implementation TestingExample`

`- (NSUserDefaults *)userDefaults
{
    // Do whatever you want!
}`

`@end`

这样就不用直接初始化Example，而是利用创建`TestingExample`来进行测试，至此就可以全权掌控任何对`[self userDefaults]`的调用结果了。

##“究竟该选择使用哪种形式？”

现在，一共提到了五种DI的形式。每一种都有其自身的优缺点和适用场景。

###构造器注入

基本上，构造器注入应该作为首选武器存在。其优势就是**让所涉及的依赖非常清晰**。

其缺点便是，乍一看会给人一种非常笨重的感觉。当初始化方法包含了一大堆依赖对象作为参数的时候尤甚。但这恰巧揭示了前文所提及的腐烂代码味道的问题：这个类的依赖对象是否也*太多了些*?它可能已经违背了[单一职能](https://cleancoders.com/episode/clean-code-episode-9/show)原则。

###属性注入

属性注入的长处是将初始化与注入分离，这在不能改变调用者部分的时候非常有用。那么它的劣势又是什么呢？还是将初始化与注入分离！是的，你没看错。属性注入使得初始化不充分。它的最佳应用场景是为依赖对象有默认值，换句话说就是确知依赖对象可以在某个时点被DI框架赋值。

属性注入看似容易，**实则不然** ：

* 必须防范属性被任意重设值。需要复写系统默认为属性生成的setter，要保证相应的实例变量为nil以及传入参数的为非nil。
* getter是否应为线程安全？如果需要，那么与需要兼顾效率和线程安全的getter相比，使用构造器注入就显得容易多了。

由于人们经常会对特定实例存在着固有认识，所以还应尽量避免潜意识中对使用属性注入的倾向性。另外，**请确定默认值不会引用到其他的library。**否则，当前的类的使用者还必须得去引用对应的library，这样的设计就违背了松耦合原则（用Seemann的概念来解释就是，这属于内部默认和外部默认的区别）。

###方法注入

假如所依赖的对象针对每次调用都会有所不同。也就是说对调用点来说，可能会涉及到特定应用上下文条件。比如基于一个随机数，或者是当前时间等。

好比一个方法依赖于当前时间。不建议直接调用`[NSDate date]`，最好在这个方法中增加一个`NSDate`参数。这么做也许会增加一点点的调用复杂度，但是方法的灵活性得到了增强。

(推荐大家阅读一下J.B. Rainsberger的["Beyond Mock Objects"](http://blog.thecodewhisperer.com/2013/11/23/beyond-mock-objects/)，这篇文章从一个有趣的应用场景出发，由一个日期注入问题引发了一系列关于设计和重用的很详实的讨论。其实对Objective-C来说，不需要使用procotols也能很好的利用测试替身(test doubles)做重复性测试。)

###环境上下文

如果依赖对象在底层有多处应用，这就极有可能产生横切问题。若继续将依赖对象向上层传递，尤其是还无法预知这个对象将会在什么时候使用的话，便会促生干扰代码。举几个可能产生这样问题的例子：

* 日志处理（Logging）
* `[NSUserDefaults standardUserDefaults]`
* `[NSDate date]`

这类场景下推荐适用环境上下文方式。由于是影响全局的上下文，使用完毕后，别忘了要将其还原。比如你用swizzle替换了一个方法，需要在`tearDown`或者`afterEach`（取决于所使用的测试框架）中对被替换的原始方法进行还原。

尽量不要自己去swizzling，推荐使用那些现成的、专注于解决与你要处理的问题类似的环境上下文的library。比如：

* Networking—[Nocilla](https://github.com/luisobo/Nocilla) or [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs)
* NSDate—[TUDelorean](https://github.com/tuenti/TUDelorean)

###利用抽取和重写的调用

鉴于抽取和重写的调用使用简单，效果强大，你可能会采取能用则用的态度。但是由于这种方式需要配备特定的测试子类，这样就会相应的增加了测试的脆弱性。

因为可以避免对依赖对象的调用点进行修改，通常来说，这种方式对历史代码非常有效。

##FAQ

###“该用哪种DI框架？”

我对那些刚开始使用mock对象的朋友们的建议是应尽量避免使用mock框架，这样你会对各个步骤和细节有更好的理解。同样地，我建议那些刚开始使用DI的朋友也不要使用任何DI框架。在不依靠DI框架的情况下，对DI的理解会更纯粹，会更明白自己该做什么，怎么做。

事实上，很可能不知不觉中你已经在使用DI框架了！**它就是Interface Builder。**IB其实不仅仅是UI设计器，任何属性都可以通过将其声明为IBOutlets来赋值。当通过IB创建的View初始化的时候，可以一并创建通过IB声明的Object（因为利用IB不仅可以创建UI对象还可以创建“Object”(NSObject类型，代表icon是个纯黄色立方体)，那么当IB文件初始化的时候，IB上定义的对象也会随之初始化）。2009年，Eric Smith在其文章[“Dependency Inversion Principle and iPhone”](http://blog.8thlight.com/eric-smith/2009/04/16/dependency-inversion-principle-and-iphone.html)中写到Interface Builder是自己“一直以来最偏爱的DI框架”，文中同时给出了如何用Interface Builder做依赖注入的例子。

如果你觉得Interface Builder还不足以应付DI工作，还需要使用其他DI框架，怎么选择才合适呢？我的建议是：**慎选那些需要改变你自己的代码才能使用的框架。**比如说继承某个东西，comfirm某个protocol，或者添加什么注解等等，这些都会将你的代码和某种特定实现捆绑在一起（这与DI的根本设计哲学相悖）。反过来，应尽量去用那些不需要浸染你的类即可以*外部化*链接的框架，至于说是DSL方式还是代码方式都无所谓。

###“不想公开全部的Hooks”

对于以上几种公开注入点的注入方式，比如说初始化注入，属性注入，以及方法参数注入等都会让人有一种破坏程序封装性的感觉。我们总有一种想要掩盖依赖注入衔接点的想法，这是可以理解的，因为我们知道这些衔接点是为单元测试准备的，因为它们并不属于API业务范畴。所以可以将他们声明在category中，并且放到一个单独的头文件里。以上面的Example.h为例，再添加一个单独的头文件ExampleInternal.h。这个头文件只会被Example.m和相应的测试代码引用。

在采纳这个方法去实践之前，我还要讨论一下关于DI会导致破坏程序封装原则的这个问题。其实DI的目标就是让依赖更加显示化。我们界定了组件的边界和他们之间的组装方式。举例来说，如果一个类的某个初始化方法中含有一个类型为`id<foo>`的参数，也就是说需要提供一个满足`Foo` protocol的对象方可初始化这个类。好比说如果你在某个类中定义了一组插头(sockets)，同时也要为其匹配相应的插头（plugs）。

如果觉得公开依赖会很繁冗，先看看是否符合以下的场景：

* 公开对Apple对象的依赖是不是不太好？Apple提供的东西不就等于暗示是可用的吗，对于其他的代码是不是也应同等对待？其实不然！还是拿我们的`NSUserDefaults`例子来说：假如说基于某种原因，你决定避免使用`NSUserDefaults`会怎么样？若将其作为显式依赖对象而不是某个内部的实现细节，你是否会觉得这是一个需要检查整个组件的信号？你可以想想使用`NSUserDefaults`是否真的违反了你在设计上的约束。

* 是不是觉得为了达到测试目标不得已公开了许多不应公开的内部实现？首先，需要判断一下基于你的代码中现行所公开的API是否能够支撑完成测试代码编写(快速且确切)。如果不可以，并且你需要去操作那些本来是隐式的依赖对象，这说明很可能有其他的类也需要操作它。所以应该大胆将其抽象，把它当作依赖对象使用并进行单独测试。

##DI不仅仅是测试

我最初决定钻研DI是因为在执行测试驱动开发（TDD），而在TDD的过程中有一个很纠结的问题会时常跳出来：“对于这个实现，如何编写单元测试？”。后来我发现其实DI本身是在彰显一个更高层面的概念：**代码组成了模块，模块拼接构建成了应用本身。**

使用这种方法有很多益处。Graham Lee在文章"[ependency Injection, iOS and You](http://www.bignerdranch.com/blog/dependency-injection-ios/)"中这样描述：“适应...新需求，解决bug，增加新功能，单独测试组件。”。

所以当我们在编写单元测试的时候用到DI，应该回想一下上文所提到的更高层面的概念。请将*可插拔模块*牢记吧。它会影响你的很多设计决策，并且引导你去理解更多的DI模式和原则。

































































