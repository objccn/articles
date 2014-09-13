在写任何东西之前我需要承认我是带有偏见的：我爱Swift。 我认为这是从我开始接触Cocoa生态系统以来这个平台上发生的最好的事情。 我想通过分享我在Swift, Objective-C和Haskell上的经验让大家知道我为何这样认为。写这片文章并不是为了介绍一些最好的实践（写这篇文章的时候Swift还太年轻，还没最好实践被总结出来), 而是举几个关于Swift 强大之处的例子。

给大家一些我的个人背景： 在成为全职iOS/Mac工程师之前我花了几年的时间做Haskell（包括一些其他函数性编程语言)开发。我仍然认为Haskell是我所有使用过的语言中最棒的之一。 然而我转战到了Objective-C因为我相信iOS是最令人激动的平台。 刚开始接触Objective-C的时候我有些许沮丧， 但我慢慢地学会去欣赏它。 

当苹果在WWDC发布Swift的时候我非常的激动。 我已经很久没有对新科技的发布感的如此兴奋了。 在看过文档之后我意识的Swift使我们能够将现有的函数性编程知识和Cocoa API无缝地整合到一起。 我觉得这两者的组合非常独特：没有任何其他的语言将它们融合地如此完美。就拿Haskell来说，使用Objective-C API相当的困难。同样，用Objective-C去做函数性编程也是十分困难。

在Utrecht大学期间我学会了函数性编程。因为是在很学术的环境下学习所以并没有觉得很多复杂的术语（moands, applicative functors以及很多其他的东西）有多么难懂。我觉得对很多想学习函数性编程的人来说这些名称是一个很大的阻碍。 

不仅仅名称很不同，风格也不一样。最为Objective-C程序员， 我们很习惯于面向对象编程。 而且因为大多数语言不是面对对象编程就是与之类似，我们可以看懂很多不同语言的代码。 阅读函数性编程语言的时候则大不相同 - 如果你没有习惯的话看起来简直莫名其妙。 

那么， 为什么你要使用函数性编程呢？ 它很奇怪，很多人都不习惯而且学习他要花费大量的时间。并且对于大多数问题面向对象编程都能解决， 所以没有必要去学习任何新的东西对吧？

对于我来说，函数性编程只是工具箱中的一件工具。它是一个改变了我对编程的理解的强大工具。 在解决问题的时候它非常强大。对于大多数问题面向对象编程都很棒。 但是对于其他一些问题应用函数性编程会给你带来巨大的时间/精力的节省。

开始学习函数性编程或许有些痛苦。 第一， 你必须放手一些老的模式。而因为我们很多人常年用面对对象的方式去思考， 做到这一点是很困难的。 在函数性编程当中你想的是不变的数据结构以及那些转换它们的函数。 在面对对象编程当中你考虑的是互相发送信息的对象。 如果你没有马上理解functional编程，这是一个好的信号。你的大脑很可能已经完全适应了用面对对象的方法来解决问题。 

##例子

我最喜欢的Swift功能之一是对optionals的使用。 optionals让我们能够应对有可能存在也有可能不存在的值。在Objective-C里我们必须在文档中清晰地说明nil是否是允许的。 optionals让我们将这份责任交给了类系统。 如果你有一个可选值(optional value)你知道它可以是nil。如果它不是可选的，你知道它不可能是nil。

举个例子， 看看下面一小段Objective-C代码

```
- (NSAttributedString *)attributedString:(NSString *)input 
{
    return [[NSAttributedString alloc] initWithString:input];
}
```

看上去没有什么问题，但是如果参数是nil, 它就会崩溃。 这种问题你只能在运行的时候才能发现。 取决于你如何使用它， 你可能很快能发现问题，但是你也有可能在发布应用之后才发现， 导致用户正在使用的应用崩溃。 

用相同的Swift的API来做对比。
```
extension NSAttributedString {
    init(string str: String)
}
```
看起来像对Objective-C的直接翻译，但是Swift不允许这样。 如果要达到这个目的API需要变成这个样子：
```
extension NSAttributedString {
    init(string str: String?)
}
```
注意新加上的问号。这意味着你可以使用一个值或者是nil。类非常的精确：只需要看一眼我们就知道什么值是允许的。 使用optionals一段时间之后你会发现你只需要看类而不用再去看文档了。 如果犯了一个错误， 你会得到一个编译时警告而不是一个运行时错误。 

##建议
如果可能的话避免使用optionals。 Optionals对于使用你API的人们来说是一个多余的负担。 话虽如此， 还是有很多地方可以很好使用它们。 如果你有一个函数会因为一个明显的原因失败你可以返回一个optional。 举例来说， 比如将一个 #00ff00字符串转换成颜色。 如果你的参数不符合正确的格式你应该返回一个nil.

```
func parseColorFromHexString(input: String) -> UIColor? {
    // ...
}
```
如果你需要阐明错误信息，你可以使用Either或者Result类（不在标准库里面）。这个在失败原因很重要的时候非常有用。 一个很好的例子参见 [“Error Handling in Swift.”](http://nomothetis.svbtle.com/error-handling-in-swift)

##Enums
 Enums是一个随Swift推出的新东西。它和我们在Objective-C中见过的东西都大不相同。 在Objective-C里面我们有一个东西叫做enums, 但是它们差不多就是升级版的整数。 
 
我们来看看boolean类。 一个boolean是两种可能性的一种：true或者false。 很重要的一点是没有办法再添加另外一个值 - boolean类是关闭的。boolean关闭的好处是每当使用boolean的时候我们只需要考虑true或者false这两种情况。 

在这一点上面optionals是一样的。总共只有两种情况：nil或者值。 在Swift里面boolean和optional都可以被定义为enums。有一个不同点：在optional enum中有一种可能性有一个相关值。 我们来看看它们不同的定义：

```
enum Boolean {
    case False
    case True
}

enum Optional<A> {
    case Nil
    case Some(A)
}
```
他们非常的相似。 如果改变他们到名称唯一到区别就是相关值。 如果你optional中的nil情况加上一个值，你最后会得到一个Either类：
```
enum Either<A,B> {
    case Left<A>
    case Right<B>
}
```
在函数性编程当中，在你想表示两件事情之间的选择时候你会经常用到Either类。 举个例子：如果你有一个函数return integer或者一个错误， 你可以用Either<Int, NSError>。 如果你想在一个字典中储存boolean或者字符串， 你可以使用Either<Bool,String>作为键。


>理论旁白： 有些时候enums被称为sum类因为它们是几个不同类到总和（sum）。Structs 和 tuples 被称为product类因为它们代表几个不同类到乘积（product)。参见[“algebraic data types.”](http://en.wikipedia.org/wiki/Algebraic_data_type)


理解什么时候使用enums什么时候使用其他到数据类（比如class或者structs）会有一些难度。 当你有一个固定数量的值的集合的时候enum是最有用的。比如说，如果我们设计一个Github API的wrapper,我们可以用enum来表示端点。 有一个不需要任何参数的/zen端点。为了获取用户的资料我们需要提供用户名。最后我们显示用户的repositorie，我们需要提供用户名以及一个值去说明是否从小到大地排列结果。


定义API端点是很好的使用enum的机会。 API的端点是有限的，所以我们可以为每一个端点定义一个情况。 如果我们在对这些端点使用switch的时候没有包含情况我们会被给予警告。 所以说当我们需要添加一个情况的时候我们需要更新每一个用到这个enum的函数。


除非能够拿到源代码，其他使用我们enum的人不能添加新的情况。 这是一个非常有用的限制。想想如果你能够加一种新情况到Bool或者Optional - 这样一来所有用到Bool或Optional的函数都需要重写。

比如说我们正在开发一个货币转换器。我们可以将货币给定义成enum: 

```
enum Currency {
    case Eur
    case Usd
}
```
我们现在可以做一个获取任何货币符号的函数:
```
func symbol(input: Currency) -> String {
    switch input {
        case .Eur: return "€"
        case .Usd: return "$"
    }
}
```

最后，我们可以用我们的symbol函数来做一个依据系统本地设置来很好地格式化之后的字符串
```
func format(amount: Double, currency: Currency) -> String {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .CurrencyStyle
    formatter.currencySymbol = symbol(currency)
    return formatter.stringFromNumber(amount)
}
```
这样以来有一个很大到限制。对于所有到货币我们可能会想让我们API的用户在将来可以修改一些情况。在Objective-C当中常见解决方法是通过subclassing来增加interface里面到类。 在Objective-C里面理论上你可以subclass任何一个类， 然后通过这种办法来扩展。在Swift里面你任然可以subclass类但对enum则不行。 但是我们可以用另一种办法(这种办法在Objetive-C和Swift的协议中都可行）。


假设我们定义一个货币符号到协议：
```
protocol CurrencySymbol {
    func symbol() -> String
}
```
现在我们将货币类作为我们协议到一个实例。注意我们可以将input参数去掉。因为这里明确地使用了self。
```
extension Currency : CurrencySymbol {
   func symbol() -> String {
        switch self {
            case .Eur: return "€"
            case .Usd: return "$"
        }
    }
}
```
现在我们可以重写format函数来格式化任何遵守我们协议的类:
```
func format(amount: Double, currency: CurrencySymbol) -> String {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .CurrencyStyle
    formatter.currencySymbol = currency.symbol()
    return formatter.stringFromNumber(amount)
}
```
这样一来我们将我们代码的可延展性大大提升类 - 任何遵守CurrencySymbol协议的类都可以被格式化。 比如说， 我们建立一个新的类来储存比特币（bitcoins），我们可以立刻让它拥有格式化功能：
```
struct Bitcoin : CurrencySymbol {
    func symbol() -> String {
        return "B⃦"
    }
}
```
这是一种写具有延展性函数的很好到方法。 通过使用需要遵守一个协议的值 ，而不是一个实实在在的类 ， 你的API用户能够加入更多的类。 你任然可以利用enum的灵活性，但是通过让他们遵守协议，你可以更好地表达自己的意思。根据你的具体情况，你现在可以轻松地选择是否开放你的API。

##类的安全性
我认为类的安全性是Swift一个很大到优势。就像我们在讨论optionals时看见的一样，我们可以用一些聪明的手段将某些检测从运行时转移到编译时。Swift中数组的工作方式是另外一个例子: 一个数组是泛型的，它只能容纳一个类的对象。 将一个整数附加在一个字符组数组后面是做不到的。 这样以来就消灭了一个大类的潜在bug。（值得注意的是如果你需要字符串或者整数你可以使用上面谈到过的Either类。）

再比如说，我们要将我们到货币转换器延展为一个通用的单位换算器。 如果我们使用Double去表示数量， 会有一点点误导性。 比如说，100可以表示100美元， 100千克或者任何能用100表示到东西。我们可以借助类系统来制作不同的类去表示不同的数量。 比如说我们可以定义一个类来表示钱：
```
struct Money {
    let amount : Double
    let currency: Currency
}
```
我们可以定义另外一个结构来表示质量：
```
struct Mass {
    let kilograms: Double
}
```
现在我们就消除了不小心将钱和质量相加的可能性。 基于你应用的特质有时候将一些简单的类包装成这样是很有效的。不仅如此，阅读代码也会变得更加简单。 假设我们遇到一个pounds函数：

```
func pounds(input: Double) -> Double
```
光看类定义很难看出来这个函数的功能。 他将欧元装换成英镑？还是将千克转换成磅？（英文中英镑和磅均为pound) 我们可以用不同的名字，或者可以建立文档（都是很好的办法），但是我们有第三种选择。我们可以将这个类变得更明确：
```
func pounds(input: Mass) -> Double
```
我们不仅让这个函数的用户能够立刻理解这个函数的功能，我们也防止了不小心传入其他单位的参数。如果你试图将钱作为参数来使用这个函数，编译器是不会接受的。 另外一个可能的提升是使用一个更精确的返回值。现在他只是一个Double。

##不可变性
Swift另外一个很棒的功能是内置的不可变性。 在Cocoa当中很多的API都已经体现出了不可变性的价值。 想了解这一点为什么如此重要 [“Error Handling in Swift.”](http://nomothetis.svbtle.com/error-handling-in-swift)是一个很好的参考。 比如，作为一个Cocoa开发者，我们使用很多成对的类(NSString vs. NSMutableString, NSArray vs. NSMutableArray)。当你得到一个字符串值，你可以假设它不会被改变。但是如果你要完全确信，你依然要复制它。然后你才知道你有一份不可变的版本。

在Swifit里面，不可变性被直接加入这门语言。 比如说如果你想建立一个可变的字符串，你可以如下的代码：
```
var myString = "Hello"
```
然而，如果你想要一个不可变的字符串，你可以做如下的事情：
```
let myString = "Hello"
```

不可变的资料在写会被未知用户使用的API时会给你很大的帮助。比如说，你有一个需要字符串作为参数的函数，在你迭代它的时候，确定它不会被改变是很重要的。在Swift当中这是默认的行为。正是因为这个原因，在写多线程代码的时候使用不可变资料会使难度大大降低。

还有另外一个巨大的优势。如果你的函数只使用不可变的资料，你的类签名就会成为很好的文档。 在Objective-C当中则不然。比如说， 假设你准备在OS X上使用CIFilter。 在实例化之后你需要使用setDefaults函数。 这一点在文档中有提到。 有很多这样类都是这个样子。 在实例化之后，在你使用它之前你必须要使用另外一个函数。问题在于，如果不阅读文档，经常不清楚那些函数需要被使用。 最后你有可能遇到很奇怪的状况。 

当使用不可变资料的时候，类签名让事情变得很清晰。 比如说， map的类签名。我们知道有一个可选的T值，而且有一个将Ts转换成Us的函数。 结果是一个可选的U值。 原始值是不可能改变的:

```
func map<T, U>(x: T?, f: T -> U) -> U?
```
对于数组的map来说是一样的。 它被定义成一个数组的延伸，所以参数本身是self。我们可以看到它用一个函数将T转化成U，别且生成一个U的数组。因为它是一个不可变的函数，我们知道原数组是不会变化的，而且我们知道结果也是不会改变的。将这些限制内置在类系统中， 并有编译器来监督执行，让我们不再需要去查看文档并记住什么会变化。 

```
extension Array {
    func map<U>(transform: T -> U) -> [U]
}
```

##总结
Swift带来了很多有趣的可能性。 我尤其喜欢的一点是过去我们需要手动检测或者阅读文档的事情现在编译器可以帮我们来完成。 我们可以选择在合适的时机去使用这些可能性。 我们依然会用我们现有的，成熟的办法去写代码，但是我们可以在合适的时候在我们代码的某些地方应用这些新的可能性。

我预测：Swift会很大程度上改变我们写代码的方式，而且是像好的方向改变。 脱离Objective-C会需要几年的时间，但是我相信我们中的大多数人会做出这个改变并且不会后悔。 有些人会很快的适应，对另外一些人可能会花上很长的时间。但是我相信总有一天绝大多数人Swift带给我们的种种好处。 
