在写任何东西之前我需要承认我是带有偏见的：我爱 Swift。我认为这是从我开始接触 Cocoa 生态系统以来这个平台上发生的最好的事情。我想通过分享我在 Swift，Objective-C 和 Haskell 上的经验让大家知道我为何这样认为。写这篇文章并不是为了介绍一些最好的实践 (写这些的时候 Swift 还太年轻，还没最好实践被总结出来)，而是举几个关于 Swift 强大之处的例子。

给大家一些我的个人背景：在成为全职 iOS/Mac 工程师之前我花了几年的时间做 Haskell (包括一些其他函数式编程语言) 开发。我仍然认为 Haskell 是我所有使用过的语言中最棒的之一。然而我转战到了 Objective-C，是因为我相信 iOS 是最令人激动的平台。刚开始接触 Objective-C 的时候我有些许沮丧，但我慢慢地学会了欣赏它。

当苹果在 WWDC 发布 Swift 的时候我非常的激动。我已经很久没有对新技术的发布感的如此兴奋了。在看过文档之后我意识到 Swift 使我们能够将现有的函数式编程知识和 Cocoa API 无缝地整合到一起。我觉得这两者的组合非常独特：没有任何其他的语言将它们融合地如此完美。就拿 Haskell 来说，想要用它来使用 Objective-C API 相当的困难。同样，想用 Objective-C 去做函数式编程也是十分困难的。

在 Utrecht 大学期间我学会了函数式编程。因为是在很学术的环境下学习所以并没有觉得很多复杂的术语 (moands，applicative functors 以及很多其他的东西) 有多么难懂。我觉得对很多想学习函数式编程的人来说这些名称是一个很大的阻碍。

不仅仅名称很不同，风格也不一样。作为 Objective-C 程序员，我们很习惯于面向对象编程。而且因为大多数语言不是面对对象编程就是与之类似，我们可以看懂很多不同语言的代码。阅读函数式编程语言的时候则大不相同 -- 如果你没有习惯的话看起来简直莫名其妙。

那么，为什么你要使用函数式编程呢？它很奇怪，很多人都不习惯而且学习它要花费大量的时间。并且对于大多数问题面向对象编程都能解决，所以没有必要去学习任何新的东西对吧？

对于我来说，函数式编程只是工具箱中的一件工具。它是一个改变了我对编程的理解的强大工具。在解决问题的时候它非常强大。对于大多数问题面向对象编程都很棒，但是对于其他一些问题应用函数式编程会给你带来巨大的时间/精力的节省。

开始学习函数式编程或许有些痛苦。第一，你必须放手一些老的模式。而因为我们很多人常年用面对对象的方式去思考，做到这一点是很困难的。在函数式编程当中你想的是不变的数据结构以及那些转换它们的函数。在面对对象编程当中你考虑的是互相发送信息的对象。如果你没有马上理解函数式编程，这是一个好的信号。你的大脑很可能已经完全适应了用面对对象的方法来解决问题。

## 例子

我最喜欢的 Swift 功能之一是对 optionals 的使用。Optionals 让我们能够应对有可能存在也有可能不存在的值。在 Objective-C 里我们必须在文档中清晰地说明 nil 是否是允许的。Optionals 让我们将这份责任交给了类型系统。如果你有一个可选值，你就知道它可以是 nil。如果它不是可选值，你知道它不可能是 nil。

举个例子，看看下面一小段 Objective-C 代码

```
- (NSAttributedString *)attributedString:(NSString *)input 
{
    return [[NSAttributedString alloc] initWithString:input];
}
```

看上去没有什么问题，但是如果 `input` 是 nil, 它就会崩溃。这种问题你只能在运行的时候才能发现。取决于你如何使用它，你可能很快能发现问题，但是你也有可能在发布应用之后才发现，导致用户正在使用的应用崩溃。

用相同的 Swift 的 API 来做对比。

```
extension NSAttributedString {
    init(string str: String)
}
```

看起来像对Objective-C的直接翻译，但是 Swift 不允许 `nil` 被传入。如果要达到这个目的，API 需要变成这个样子：

```
extension NSAttributedString {
    init(string str: String?)
}
```

注意新加上的问号。这意味着你可以使用一个值或者是 nil。类非常的精确：只需要看一眼我们就知道什么值是允许的。使用 optionals 一段时间之后你会发现你只需要阅读类型而不用再去看文档了。如果犯了一个错误，你会得到一个编译时警告而不是一个运行时错误。

## 建议

如果可能的话避免使用 optionals。Optionals 对于使用你 API 的人们来说是一个多余的负担。话虽如此，还是有很多地方可以很好使用它们。如果你有一个函数会因为一个明显的原因失败你可以返回一个 optional。举例来说，比如将一个  #00ff00 字符串转换成颜色。如果你的参数不符合正确的格式，你应该返回一个 `nil` 。

```
func parseColorFromHexString(input: String) -> UIColor? {
    // ...
}
```

如果你需要阐明错误信息，你可以使用 `Either` 或者 `Result` 类型 (不在标准库里面)。当失败的原因很重要的时候，这种做法会非常有用。[“Error Handling in Swift”](http://nomothetis.svbtle.com/error-handling-in-swift) 一文中有个很好的例子。

## Enums

Enums 是一个随 Swift 推出的新东西，它和我们在 Objective-C 中见过的东西都大不相同。在 Objective-C 里面我们有一个东西叫做 enums, 但是它们差不多就是升级版的整数。
 
我们来看看布尔类型。一个布尔值是两种可能性 -- true 或者 false -- 中的一个。很重要的一点是没有办法再添加另外一个值 -- 布尔类型是**封闭的**。布尔类型的封闭性的好处是每当使用布尔值的时候我们只需要考虑 true 或者 false 这两种情况。

在这一点上面 optionals 是一样的。总共只有两种情况：`nil` 或者有值。在 Swift 里面布尔和 optional 都可以被定义为 enums。但有一个不同点：在 optional enum 中有一种可能性有一个相关值。我们来看看它们不同的定义：

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

它们非常的相似。如果你把它们的名称改成一样的话，那么唯一的区别就是括号里的相关值。如果你给 optional 中的 `Nil`  情况也加上一个值，你就会得到一个 `Either` 类型：

```
enum Either<A,B> {
    case Left<A>
    case Right<B>
}
```

在函数式编程当中，在你想表示两件事情之间的选择时候你会经常用到 `Either` 类型。举个例子：如果你有一个函数返回一个整数或者一个错误，你就可以用 `Either<Int, NSError>`。如果你想在一个字典中储存布尔值或者字符串，你就可以使用 `Either<Bool,String>` 作为键。

>理论旁白：有些时候 enums 被称为 **sum 类型**，因为它们是几个不同类型的总和。在 `Either` 类型的例子中，它们表达的是 `A` 类型和 `B` 类型的和。Structs 和 tuples 被称为 **product 类型**，因为它们代表几个不同类型的乘积。参见[“algebraic data types.”](http://en.wikipedia.org/wiki/Algebraic_data_type)

理解什么时候使用 enums 什么时候使用其他的数据类型 (比如 [class 或者 structs](http://objccn.io/issue-16-2))会有一些难度。当你有一个固定数量的值的集合的时候，enum 是最有用的。比如说，如果我们设计一个 Github API 的 wrapper，我们可以用 enum 来表示端点。比如有一个不需要任何参数的 `/zen` 的 API 端点。再比如为了获取用户的资料我们需要提供用户名。最后我们显示用户的仓库时，我们需要提供用户名以及一个值去说明是否从小到大地排列结果。

```
enum Github {
    case Zen
    case UserProfile(String)
    case Repositories(username: String, sortAscending: Bool)
}
```

定义 API 端点是很好的使用 enum 的场景。API 的端点是有限的，所以我们可以为每一个端点定义一个情况。如果我们在对这些端点使用 switch 的时候没有包含所有情况的话，我们会被给予警告。所以说当我们需要添加一个情况的时候我们需要更新每一个用到这个 enum 的函数。

除非能够拿到源代码，其他使用我们 enum 的人不能添加新的情况，这是一个非常有用的限制。想想要是你能够加一种新情况到 `Bool` 或者 `Optional` 里会怎么样吧 -- 所有用到 它的函数都需要重写。

比如说我们正在开发一个货币转换器。我们可以将货币给定义成 enum：

```
enum Currency {
    case Eur
    case Usd
}
```

我们现在可以做一个获取任何货币符号的函数：

```
func symbol(input: Currency) -> String {
    switch input {
        case .Eur: return "€"
        case .Usd: return "$"
    }
}
```

最后，我们可以用我们的 `symbol` 函数，来依据系统本地设置得到一个很好地格式化过的字符串：

```
func format(amount: Double, currency: Currency) -> String {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .CurrencyStyle
    formatter.currencySymbol = symbol(currency)
    return formatter.stringFromNumber(amount)
}
```

这样一来有一个很大的限制。我们可能会想让我们 API 的使用者在将来可以修改一些情况。在 Objective-C 当中向一个接口里添加更多类型的常见解决方法是子类化。在 Objective-C 里面理论上你可以子类化任何一个类，然后通过这种办法来扩展它。在 Swift 里面你仍然可以使用子类化，但是只能对 `class` 使用，对于 `enum` 则不行。然而，我们可以用另一种技术来达到目的 (这种办法在 Objetive-C 和 Swift 的 protocol 中都可行）。

假设我们定义一个货币符号的协议：

```
protocol CurrencySymbol {
    func symbol() -> String
}
```

现在我们让 `Currency` 类型遵守这个协议。注意我们可以将 `input` 参数去掉，因为这里它被作为 self 隐式地进行传递：

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

现在我们可以重写 `format` 方法来格式化任何遵守我们协议的类型：

```
func format(amount: Double, currency: CurrencySymbol) -> String {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .CurrencyStyle
    formatter.currencySymbol = currency.symbol()
    return formatter.stringFromNumber(amount)
}
```

这样一来我们将我们代码的可延展性大大提升类 -- 任何遵守 `CurrencySymbol` 协议的类型都可以被格式化。比如说，我们建立一个新的类型来储存比特币，我们可以立刻让它拥有格式化功能：

```
struct Bitcoin : CurrencySymbol {
    func symbol() -> String {
        return "B⃦"
    }
}
```

这是一种写出具有延展性函数的很好的方法。通过使用一个需要遵守协议，而不是一个实实在在的类型，你的 API 的用户能够加入更多的类型。你仍然可以利用 enum 的灵活性，但是通过让它们遵守协议，你可以更好地表达自己的意思。根据你的具体情况，你现在可以轻松地选择是否开放你的 API。

## 类型安全

我认为类型的安全性是 Swift 一个很大的优势。就像我们在讨论 optionals 时看见的一样，我们可以用一些聪明的手段将某些检测从运行时转移到编译时。Swift 中数组的工作方式就是一个例子：一个数组是泛型的，它只能容纳一个类型的对象。将一个整数附加在一个字符组数组后面是做不到的。这样以来就消灭了一个类的潜在 bug。(值得注意的是如果你需要同时将字符串或者整数放到一个数组里的话，你可以使用上面谈到过的 `Either` 类型。)

再比如说，我们要将我们到货币转换器延展为一个通用的单位换算器。如果我们使用 `Double` 去表示数量，会有一点点误导性。比如说，100.0 可以表示 100 美元，100 千克或者任何能用 100 表示的东西。我们可以借助类型系统来制作不同的类型来表示不同的物理上的数量。比如说我们可以定义一个类型来表示钱：

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

现在我们就消除了不小心将 `Money`  和 `Mass` 相加的可能性。基于你应用的特质有时候将一些简单的类型包装成这样是很有效的。不仅如此，阅读代码也会变得更加简单。假设我们遇到一个 `pounds` 函数：

```
func pounds(input: Double) -> Double
```

光看类型定义很难看出来这个函数的功能。它将欧元装换成英镑？还是将千克转换成磅？ (英文中英镑和磅均为 pound) 我们可以用不同的名字，或者可以建立文档 (都是很好的办法)，但是我们有第三种选择。我们可以将这个类型变得更明确：

```
func pounds(input: Mass) -> Double
```

我们不仅让这个函数的用户能够立刻理解这个函数的功能，我们也防止了不小心传入其他单位的参数。如果你试图将 `Money` 作为参数来使用这个函数，编译器是不会接受的。另外一个可能的提升是使用一个更精确的返回值。现在它只是一个 `Double`。

## 不可变性

Swift 另外一个很棒的功能是内置的不可变性。在 Cocoa 当中很多的 API 都已经体现出了不可变性的价值。想了解这一点为什么如此重要，[“Error Handling in Swift”](http://nomothetis.svbtle.com/error-handling-in-swift) 是一个很好的参考。比如，作为一个 Cocoa 开发者，我们使用很多成对的类 (`NSString` vs. `NSMutableString`，`NSArray` vs. `NSMutableArray`)。当你得到一个字符串值，你可以假设它不会被改变。但是如果你要完全确信，你依然要复制它。然后你才知道你有一份不可变的版本。

在 Swifit 里面，不可变性被直接加入这门语言。比如说如果你想建立一个可变的字符串，你可以如下的代码：

```
var myString = "Hello"
```

然而，如果你想要一个不可变的字符串，你可以做如下的事情：

```
let myString = "Hello"
```

不可变的数据在创建可能会被未知用户使用的 API 时会给你很大的帮助。比如说，你有一个需要字符串作为参数的函数，在你迭代它的时候，确定它不会被改变是很重要的。在 Swift 当中这是默认的行为。正是因为这个原因，在写多线程代码的时候使用不可变资料会使难度大大降低。

还有另外一个巨大的优势。如果你的函数只使用不可变的数据，你的类型签名就会成为很好的文档。在 Objective-C 当中则不然。比如说，假设你准备在 OS X 上使用 `CIFilter`。在实例化之后你需要使用 `setDefaults` 方法。这一点在文档中有提到。有很多这样类都是这个样子。在实例化之后，在你使用它之前你必须要使用另外一个方法。问题在于，如果不阅读文档的话，经常会不清楚哪些函数需要被使用，最后你有可能遇到很奇怪的状况。

当使用不可变资料的时候，类型签名让事情变得很清晰。比如说，`map` 的类签名。我们知道有一个可选的 `T` 值，而且有一个将 `T` 转换成 `U` 的函数。结果是一个可选的 `U` 值。原始值是不可能改变的：

```
func map<T, U>(x: T?, f: T -> U) -> U?
```

对于数组的 `map` 来说是一样的。它被定义成一个数组的延伸，所以参数本身是 `self`。我们可以看到它用一个函数将 `T` 转化成 `U`，并且生成一个 `U` 的数组。因为它是一个不可变的函数，我们知道原数组是不会变化的，而且我们知道结果也是不会改变的。将这些限制内置在l类型系统中，并有编译器来监督执行，让我们不再需要去查看文档并记住什么会变化。

```
extension Array {
    func map<U>(transform: T -> U) -> [U]
}
```

## 总结

Swift 带来了很多有趣的可能性。我尤其喜欢的一点是过去我们需要手动检测或者阅读文档的事情现在编译器可以帮我们来完成。我们可以选择在合适的时机去使用这些可能性。我们依然会用我们现有的，成熟的办法去写代码，但是我们可以在合适的时候在我们代码的某些地方应用这些新的可能性。

我预测：Swift 会很大程度上改变我们写代码的方式，而且是向好的方向改变。脱离 Objective-C 会需要几年的时间，但是我相信我们中的大多数人会做出这个改变并且不会后悔。有些人会很快的适应，对另外一些人可能会花上很长的时间。但是我相信总有一天绝大多数人会看到 Swift 带给我们的种种好处。

---

 

原文 [The Power of Swift](http://www.objc.io/issue-16/power-of-swift.html)
