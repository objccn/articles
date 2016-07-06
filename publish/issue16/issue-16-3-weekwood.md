虽然 Objective-C 的语法相对于其他编程语言来说写法有点奇怪，但是当你真正使用的时候它的语法还是相当的简单。下面有一些例子：

    + (void)mySimpleMethod
    {
        // 类方法
        // 无参数
        // 无返回值
    }

    - (NSString *)myMethodNameWithParameter1:(NSString *)param1 parameter2:(NSNumber *)param2
    {
        // 实例方法
        // 其中一个参数是 NSString 指针类型，另一个是 NSNumber 指针类型
        // 必须返回一个 NSString 指针类型的值
        return @"hello, world!";
    }

相比而言，虽然 Swift 的语法看起来与其他编程语言有更多相似的地方，但是它也可以比 Objective-C 更加复杂和令人费解。

在继续之前，我需要澄清 Swift 中**方法**和**函数**之间的不同，因为在本文中我们将使用这两个术语。按照 Apple 的 [Swift Programming Language Book](https://developer.apple.com/library/prerelease/mac/documentation/Swift/Conceptual/Swift_Programming_Language/Methods.html) 里面的方法定义：

> 方法是与某些特定类型相关联的函数。类、结构体、枚举都可以定义实例方法；实例方法为给定类型的实例封装了具体的任务与功能。类、结构体、枚举也可以定义类型方法，类型方法与类型本身相关联。类型方法与 Objective-C 中的类方法（class methods）相似。

以上是长文慎读。一句话：函数是独立的，而方法是函数封装在类，结构或者枚举中的函数。

## 剖析 Swift 函数

让我们从简单的 “Hello，World” Swift 函数开始：

    func mySimpleFunction() {
        println("hello, world!")
    }

如果你曾在 Objective-C 之外的语言进行过编程，上面的这个函数你会非常熟悉

* `func` 表示这是一个函数。
* 函数的名称是 `mySimpleFunction`。
* 这个函数没有参数传入 - 因此是`( )`。
* 函数没有返回值
* 函数是在`{ }`中执行

现在让我们看一个稍稍复杂的例子：

    func myFunctionName(param1: String, param2: Int) -> String {
        return "hello, world!"
    }

这个函数有一个 `String` 类型且名为 `param1` 的参数和一个 `Int` 类型名为 `param2` 的参数并且返回值是 `String 类型。

## 调用所有函数

Swift 和 Objective-C 之间其中一个巨大的差别就是当 Swift 函数被调用的时候参数工作方式。如果你像我一样喜欢 Objective-C 超长的命名方式，那么请记住，在默认情况下 Swift 函数被调用时参数名是不被外部调用包含在内的。

    func hello(name: String) {
        println("hello \(name)")
    }

    hello("Mr. Roboto")

在你增加更多参数到函数之前，一切看起来不是那么糟糕。但是：

    func hello(name: String, age: Int, location: String) {
        println("Hello \(name). I live in \(location) too. When is your \(age + 1)th birthday?")
    }

    hello("Mr. Roboto", 5, "San Francisco")

如果仅阅读 `hello("Mr. Roboto", 5, "San Francisco")`，你可能很难知道每一个参数代表什么。

在 Swift 中，有一个概念称为 **外部参数名称* * 用来解决这个困惑：

    func hello(fromName name: String) {
        println("\(name) says hello to you!")
    }

    hello(fromName: "Mr. Roboto")

上面函数中，`fromName` 是一个外部参数，在函数被调用的时候将被包括在调用中。在函数内执行时，使用 `name` 这个内部参数来对输入进行引用。

如果你希望外部参数和内部参数相同，你不需要写两次参数名：

    func hello(name name: String) {
        println("hello \(name)")
    }

    hello(name: "Robot")

只需要在参数前面添加 `#` 的快捷方式： 

    func hello(#name: String) {
        println("hello \(name)")
    }

    hello(name: "Robot")

当然，对于方法而言参数的工作方式略有不同...

## 调用方法

当被封装在类 (或者结构，枚举) 中时，方法的第一个参数名**不**被外部包含，同时所有的后面的参数在方法调用时候被外部包含：

    class MyFunClass {
        
        func hello(name: String, age: Int, location: String) {
            println("Hello \(name). I live in \(location) too. When is your \(age + 1)th birthday?")
        }
        
    }

    let myFunClass = MyFunClass()
    myFunClass.hello("Mr. Roboto", age: 5, location: "San Francisco")

因此最佳实践是在方法名里包含第一个参数名，就像 Objective-C 那样：

    class MyFunClass {
    
        func helloWithName(name: String, age: Int, location: String) {
            println("Hello \(name). I live in \(location) too. When is your \(age + 1)th birthday?")
        }
    
    }

    let myFunClass = MyFunClass()
    myFunClass.helloWithName("Mr. Roboto", age: 5, location: "San Francisco")

相对于调用函数 “hello”，我将其重命名为 `helloWithName`，这使得第一个参数 `name` 变得很清晰。 

如果出于一些原因你希望在函数中跳过外部参数名 (我建议如果要这么做的话，你需要一个非常好的理由)，为外部函数添加 `_` 来解决：

    class MyFunClass {
        
        func helloWithName(name: String, _ age: Int, _ location: String) {
            println("Hello \(name). I live in \(location) too. When is your \(age + 1)th birthday?")
        }
        
    }

    let myFunClass = MyFunClass()
    myFunClass.helloWithName("Mr. Roboto", 5, "San Francisco")

### 实例方法是柯里化 (currying) 函数

需要注意一个非常酷的是 [Swift 中实例方法是柯里化函数](http://oleb.net/blog/2014/07/swift-instance-methods-curried-functions/)。

> 柯里化背后的基本想法是函数可以局部应用，意思是一些参数值可以在函数调用之前被指定或者绑定。这个部分函数的调用会返回一个新的函数。

如果我有一个类：


    class MyHelloWorldClass {
        
        func helloWithName(name: String) -> String {
            return "hello, \(name)"
        }
    }

我可以建立一个变量指向类中的 `helloWithName` 函数：

    let helloWithNameFunc = MyHelloWorldClass.helloWithName
    // MyHelloWorldClass -> (String) -> String

我新的 `helloWithNameFunc` 是 `MyHelloWorldClass -> (String) -> String` 类型，这个函数接受我的类的实例并返回另一个函数。新函数接受一个字符串值，并返回一个字符串值。

所以实际上我可以这样调用我的函数：

    let myHelloWorldClassInstance = MyHelloWorldClass()

    helloWithNameFunc(myHelloWorldClassInstance)("Mr. Roboto") 
    // hello, Mr. Roboto

## 初始化：一个特殊注意的地方

在类，结构体或者枚举初始化的时候将调用一个特殊的 `init` 方法。在 Swift 中你可以像其他方法那样定义初始化参数：

    class Person {
        
        init(name: String) {
            // your init implementation
            // 你的初始化方法实现
        }
        
    }

    Person(name: "Mr. Roboto")

注意下，不像其他方法，初始化方法的第一个参数必须在实例时必须是外部的。

大多数情况下的最佳实践是添加一个不同的外部参数名 — 本例中的 `fromName` —让初始化更具有可读性：

    class Person {
        
        init(fromName name: String) {
            // your init implementation
            // 你的初始化方法实现
        }
        
    }

    Person(fromName: "Mr. Roboto")

当然，就像其他方法那样，如果你想让方法跳过外部参数名的话，可以添加 `_`。我喜欢  [Swift Programming Language Book](https://developer.apple.com/library/prerelease/mac/documentation/Swift/Conceptual/Swift_Programming_Language/Initialization.html#//apple_ref/doc/uid/TP40014097-CH18-XID_306) 初始化例子的强大和可读性。

    struct Celsius {
        var temperatureInCelsius: Double
        init(fromFahrenheit fahrenheit: Double) {
            temperatureInCelsius = (fahrenheit - 32.0) / 1.8
        }
        init(fromKelvin kelvin: Double) {
            temperatureInCelsius = kelvin - 273.15
        }
        init(_ celsius: Double) {
            temperatureInCelsius = celsius
        }
    }

    let boilingPointOfWater = Celsius(fromFahrenheit: 212.0)
    // boilingPointOfWater.temperatureInCelsius 是 100.0

    let freezingPointOfWater = Celsius(fromKelvin: 273.15)
    // freezingPointOfWater.temperatureInCelsius 是 0.0

    let bodyTemperature = Celsius(37.0)
    // bodyTemperature.temperatureInCelsius 是 37.0 

如果你希望抽象类/枚举/结构体的初始化，跳过外部参数可以非常有用。我喜欢在 [David Owen](https://twitter.com/owensd) 的 [json-swift library](https://github.com/owensd/json-swift/blob/master/src/JSValue.swift) 中对这项技术的使用：

    public struct JSValue : Equatable {
        
        // ... 截断的部分代码

        /// 使用 `JSArrayType` 来初始化 `JSValue`。 
        public init(_ value: JSArrayType) {
            self.value = JSBackingValue.JSArray(value)
        }

        /// 使用 `JSObjectType` 来初始化 `JSValue`。 
        public init(_ value: JSObjectType) {
            self.value = JSBackingValue.JSObject(value)
        }

        /// 使用 `JSStringType` 来初始化 `JSValue`。 
        public init(_ value: JSStringType) {
            self.value = JSBackingValue.JSString(value)
        }

        /// 使用 `JSNumberType` 来初始化 `JSValue`。
        public init(_ value: JSNumberType) {
            self.value = JSBackingValue.JSNumber(value)
        }

        /// 使用 `JSBoolType` 来初始化 `JSValue`。
        public init(_ value: JSBoolType) {
            self.value = JSBackingValue.JSBool(value)
        }

        /// 使用 `Error` 来初始化 `JSValue`。
        init(_ error: Error) {
            self.value = JSBackingValue.Invalid(error)
        }

        /// 使用 `JSBackingValue` 来初始化 `JSValue`。
        init(_ value: JSBackingValue) {
            self.value = value
        }
	}

## 华丽的参数

相较于 Objective-C，Swift 有很多额外的选项用来指定可以传入的参数的类型，下面是一些例子。

### 可选参数类型

在 Swift 中有一个新的概念称之为 [optional types](https://developer.apple.com/library/prerelease/mac/documentation/Swift/Conceptual/Swift_Programming_Language/TheBasics.html)：

> 可选表示 “那儿有一个值，并且它等于 x ” 或者 “那儿没有值”。可选有点像在 Objective-C 中使用 nil，但是它可以用在任何类型上，不仅仅是类。可选类型比 Objective-C 中的 nil 指针更加安全也更具表现力，它是 Swift 许多强大特性的重要组成部分。

表明一个参数是可选 (可以是 nil)，可以在类型规范后添加一个问号：

    func myFuncWithOptionalType(parameter: String?) {
        // function execution
    }

    myFuncWithOptionalType("someString")
    myFuncWithOptionalType(nil)

使用可选时候不要忘记拆包！

    func myFuncWithOptionalType(optionalParameter: String?) {
        if let unwrappedOptional = optionalParameter {
            println("The optional has a value! It's \(unwrappedOptional)")
        } else {
            println("The optional is nil!")
        }
    }

    myFuncWithOptionalType("someString")
    // optional has a value! It's someString

    myFuncWithOptionalType(nil)
    // The optional is nil

如果学习过 Objective-C，那么习惯使用可选值肯定需要一些时间！

### 参数默认值

    func hello(name: String = "you") {
        println("hello, \(name)")
    }

    hello(name: "Mr. Roboto")
    // hello, Mr. Roboto

    hello()
    // hello, you

值得注意的是有默认值的参数自动包含一个外部参数名

由于参数的默认值可以在函数被调用时调过，所以最佳实践是把含有默认值的参数放在函数参数列表的最后。[Swift Programming Language Book](https://developer.apple.com/library/prerelease/mac/documentation/Swift/Conceptual/Swift_Programming_Language/Functions.html) 包含相关的内容介绍：

> 把含有默认值的参数放在参数列表最后，可以确保对它的调用中所有无默认值的参数顺序一致，而且清晰表述了在不同情况下调用的函数是相同的。

我是默认参数的粉丝，主要是它使得代码容易改变而且向后兼容。比如配置一个自定义的 `UITableViewCell` 的函数里，你可以在你的某个用例中用两个参数开始，如果另一个用例出现，需要另一个参数 (比如你的 Cell 的 label 含有不同文字颜色)，只需要添加一个包含新默认值的参数 — 函数的其他部分已经被正确调用，并且你代码最新部分仅需要参数传入一个非默认值。

### 可变参数

可变参数是传入数组元素的一个更加可读的版本。实际上，比如下面例子中的内部参数名类型，你可以看到它是 `[String]` 类型 (String 数组): 


    func helloWithNames(names: String...) {
        for name in names {
            println("Hello, \(name)")
        }
    }

    // 2 names
    helloWithNames("Mr. Robot", "Mr. Potato")
    // Hello, Mr. Robot
    // Hello, Mr. Potato

    // 4 names
    helloWithNames("Batman", "Superman", "Wonder Woman", "Catwoman")
    // Hello, Batman
    // Hello, Superman
    // Hello, Wonder Woman
    // Hello, Catwoman

这里要特别记住的是可以传入 0 个值，就像传入一个空数组一样，所以如果有必要的话，不要忘记检查空数组：


    func helloWithNames(names: String...) {
        if names.count > 0 {
            for name in names {
                println("Hello, \(name)")
            }
        } else {
            println("Nobody here!")
        }
    }

    helloWithNames()
    // Nobody here!

可变参数另一个要注意的地方是 — 可变参数必须是在函数列表的**最后**一个！

###  输入输出参数 inout

利用 inout 参数，你有能力 (经过引用来) 操纵外部变量：


    var name1 = "Mr. Potato"
    var name2 = "Mr. Roboto"

    func nameSwap(inout name1: String, inout name2: String) {
        let oldName1 = name1
        name1 = name2
        name2 = oldName1
    }

    nameSwap(&name1, &name2)

    name1
    // Mr. Roboto

    name2
    // Mr. Potato

这是 Objective-C 中非常常见的用来处理错误的模式。 `NSJSONSerialization` 是其中一个例子：

    - (void)parseJSONData:(NSData *)jsonData
    {
        NSError *error = nil;
        id jsonResult = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        
        if (!jsonResult) {
            NSLog(@"ERROR: %@", error.description);
        }
    }

Swift 非常之新，所以这里没有一个公认的处理错误的方式，但是在 inout 参数之外肯定有非常多的选择！看看 David Owen's  最新的博客 [Swfit 中的错误处理](http://owensd.io/2014/08/22/error-handling-take-two.html)。关于这个话题的更多内容已经在 [Functional Programming in Swift](http://www.objc.io/books/) 中被涵盖. 

### 泛型参数类型

我不会在本文中大篇幅介绍泛型，但是这里有个简单的例子来阐述如何在一个函数中接受两个类型不定的参数，但确保这两个参数类型是相同的：

    func valueSwap<T>(inout value1: T, inout value2: T) {
        let oldValue1 = value1
        value1 = value2
        value2 = oldValue1
    }

    var name1 = "Mr. Potato"
    var name2 = "Mr. Roboto"

    valueSwap(&name1, &name2)

    name1 // Mr. Roboto
    name2 // Mr. Potato

    var number1 = 2
    var number2 = 5

    valueSwap(&number1, &number2)

    number1 // 5
    number2 // 2

更多的泛型知识，我建议你阅读下 Swift Programming Language book 中的[泛型章节](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Generics.html)。

### 变量参数 var

默认情况下，参数传入函数是一个常量，所以它们在函数范围内不能被操作。如果你想修改这个行为，只需要在你的参数前使用 var 关键字：

    var name = "Mr. Roboto"

    func appendNumbersToName(var name: String, #maxNumber: Int) -> String {
        for i in 0..<maxNumber {
            name += String(i + 1)
        }
        return name
    }

    appendNumbersToName(name, maxNumber:5)
    // Mr. Robot12345

    name
    // Mr. Roboto

值得注意的是这个和 inout 参数不同 — 变量参数不会修改外部传入变量！

### 作为参数的函数

在 Swift 中，函数可以被用来当做变量传递。比如，一个函数可以含有一个函数类型的参数：

    func luckyNumberForName(name: String, #lotteryHandler: (String, Int) -> String) -> String {
        let luckyNumber = Int(arc4random() % 100)
        return lotteryHandler(name, luckyNumber)
    }

    func defaultLotteryHandler(name: String, luckyNumber: Int) -> String {
        return "\(name), your lucky number is \(luckyNumber)"
    }

    luckyNumberForName("Mr. Roboto", lotteryHandler: defaultLotteryHandler)
    // Mr. Roboto, your lucky number is 38

注意下只有函数的引用被传入 — 在本例中是 `defaultLotteryHandler`。这个函数之后是否执行是由接收的函数决定。

实例方法也可以用类似的方法传入：

    func luckyNumberForName(name: String, #lotteryHandler: (String, Int) -> String) -> String {
        let luckyNumber = Int(arc4random() % 100)
        return lotteryHandler(name, luckyNumber)
    }

    class FunLottery {
        
        func defaultLotteryHandler(name: String, luckyNumber: Int) -> String {
            return "\(name), your lucky number is \(luckyNumber)"
        }
        
    }

    let funLottery = FunLottery()
    luckyNumberForName("Mr. Roboto", lotteryHandler: funLottery.defaultLotteryHandler)
    // Mr. Roboto, your lucky number is 38

为了让你的函数定义更具可读性，可以考虑为你函数的类型创建别名 (类似于 Objective-C 中的 typedef)：

    typealias lotteryOutputHandler = (String, Int) -> String

    func luckyNumberForName(name: String, #lotteryHandler: lotteryOutputHandler) -> String {
        let luckyNumber = Int(arc4random() % 100)
        return lotteryHandler(name, luckyNumber)
    }

你也可以使用不包含参数名的函数 (类似于 Objective-C 中的 blocks)：

    func luckyNumberForName(name: String, #lotteryHandler: (String, Int) -> String) -> String {
        let luckyNumber = Int(arc4random() % 100)
        return lotteryHandler(name, luckyNumber)
    }

    luckyNumberForName("Mr. Roboto", lotteryHandler: {name, number in
        return "\(name)'s' lucky number is \(number)"
    })
    // Mr. Roboto's lucky number is 74

在 Objective-C 中，使用 blocks 作为参数是异步操作是操作结束时的回调和错误处理的常见方式，这一方式在 Swift 中得到了很好的延续。

## 权限控制

Swift 有三个级别的[权限控制](https://developer.apple.com/library/prerelease/mac/documentation/Swift/Conceptual/Swift_Programming_Language/AccessControl.html)：

- **Public 权限** 可以为实体启用定义它们的模块中的源文件的访问，另外其他模块的源文件里只要导入了定义模块后，也能进行访问。通常情况下，Framework 是可以被任何人使用的，你可以将其设置为 public 级别
- **Internal 权限** 可以为实体启用定义它们的模块中的源文件的访问，但是在定义模块之外的任何源文件中都不能访问它。通常情况下，app 或 Framework 的内部结构使用 internal 级别。
- **Private 权限** 只能在当前源文件中使用的实体。使用 private 级别，可以隐藏某些功能的特地的实现细节。

默认情况下，每个函数和变量是 internal 的 —— 如果你希望修改他们，你需要在每个方法和变量的前面使用 `private` 或者 `public` 关键字：

    public func myPublicFunc() {
        
    }

    func myInternalFunc() {
        
    }

    private func myPrivateFunc() {
        
    }

    private func myOtherPrivateFunc() {
        
    }

Ruby 带来的习惯，我喜欢把所有的私有函数放在类的最下面，利用一个 `//MARK` 来区分：

    class MyFunClass {
        
        func myInternalFunc() {
            
        }
        
        // MARK: Private Helper Methods
        
        private func myPrivateFunc() {
            
        }
        
        private func myOtherPrivateFunc() {
            
        }
    }

希望 Swift 在将来的版本中包含一个选项可以用一个私有关键字来表明以下所有的方法都是私有的，类似于其他语言那样做访问控制。

## 华丽的返回类型

在 Swift 中，函数的返回类型和返回值相较于 Objective-C 而言更加复杂，尤其是引入可选和多个返回类型。

### 可选返回类型

如果你的函数有可能返回一个 nil 值，你需要指定返回类型为可选：

    func myFuncWithOptonalReturnType() -> String? {
        let someNumber = arc4random() % 100
        if someNumber > 50 {
            return "someString"
        } else {
            return nil
        }
    }

    myFuncWithOptonalReturnType()

当然，当你使用可选返回值，不要忘记拆包：

    let optionalString = myFuncWithOptonalReturnType()

    if let someString = optionalString {
        println("The function returned a value: \(someString)")
    } else {
        println("The function returned nil")
    }

The best explanation I've seen of optionals is from a [tweet by @Kronusdark](https://twitter.com/Kronusdark/status/496444128490967041): 
对我而言最好的可选值的解释来自于 [@Kronusdark](https://twitter.com/Kronusdark/status/496444128490967041) 的一条推特：

> 我终于弄明白 @SwiftLang 的可选值了，它们就像薛定谔的猫！在你使用之前，你必须先看看猫是死是活。

### 多返回值

Swift 其中一个令人兴奋的功能是函数可以有多个返回值

    func findRangeFromNumbers(numbers: Int...) -> (min: Int, max: Int) {

        var min = numbers[0]
        var max = numbers[0]
        
        for number in numbers {
            if number > max {
                max = number
            }
            
            if number < min {
                min = number
            }
        }
        
        return (min, max)
    }

    findRangeFromNumbers(1, 234, 555, 345, 423)
    // (1, 555)

就像你看到的那样，在一个元组中返回多个值，这一个非常简单的将值进行组合的数据结构。有两种方法可以使用多返回值的元组:

    let range = findRangeFromNumbers(1, 234, 555, 345, 423)
    println("From numbers: 1, 234, 555, 345, 423. The min is \(range.min). The max is \(range.max).")
    // From numbers: 1, 234, 555, 345, 423. The min is 1. The max is 555.

    let (min, max) = findRangeFromNumbers(236, 8, 38, 937, 328)
    println("From numbers: 236, 8, 38, 937, 328. The min is \(min). The max is \(max)")
    // From numbers: 236, 8, 38, 937, 328. The min is 8. The max is 937

### 多返回值与可选值

当返回值是可选的时候，多返回值就比较棘手。对于多个可选值的返回，有两种办法解决这种情况。

在上面的例子函数中，我的逻辑是有缺陷的 —— 它有可能没有值传入，所以我的代码有可能在没有值传入的时候崩溃，所以我希望我整个返回值是可选的：

    func findRangeFromNumbers(numbers: Int...) -> (min: Int, max: Int)? {

        if numbers.count > 0 {
            
            var min = numbers[0]
            var max = numbers[0]
            
            for number in numbers {
                if number > max {
                    max = number
                }
                
                if number < min {
                    min = number
                }
            }
            
            return (min, max)
        } else {
            return nil
        }
    }

    if let range = findRangeFromNumbers() {
        println("Max: \(range.max). Min: \(range.min)")
    } else {
        println("No numbers!")
    }
    // No numbers!

另一种做法是对元组中的每个返回值设为可选来代替整体的元组可选：

    func componentsFromUrlString(urlString: String) -> (host: String?, path: String?) {
        let url = NSURL(string: urlString)
        return (url.host, url.path)
    }

如果你决定你元组值中一些值是可选，拆包时候会变得有些复杂，你需要考虑每中单独的可选返回值的组合：

    let urlComponents = componentsFromUrlString("http://name.com/12345;param?foo=1&baa=2#fragment")

    switch (urlComponents.host, urlComponents.path) {
    case let (.Some(host), .Some(path)):
        println("This url consists of host \(host) and path \(path)")
    case let (.Some(host), .None):
        println("This url only has a host \(host)")
    case let (.None, .Some(path)):
        println("This url only has path \(path). Make sure to add a host!")
    case let (.None, .None):
        println("This is not a url!")
    }
    // This url consists of host name.com and path /12345

如你所见，它和 Objective-C 的处理方式完全不同！

### 返回一个函数

Swift 中函数可以返回一个函数：

    func myFuncThatReturnsAFunc() -> (Int) -> String {
        return { number in
            return "The lucky number is \(number)"
        }
    }

    let returnedFunction = myFuncThatReturnsAFunc()

    returnedFunction(5) // The lucky number is 5

为了更具有可读性，你当然可以为你的返回函数定义一个别名：

    typealias returnedFunctionType = (Int) -> String

    func myFuncThatReturnsAFunc() -> returnedFunctionType {
        return { number in
            return "The lucky number is \(number)"
        }
    }

    let returnedFunction = myFuncThatReturnsAFunc()

    returnedFunction(5) // The lucky number is 5

## 嵌套函数

如果在这篇文章中你没对函数有足够的体会，那么了解下 Swift 可以在函数中定义函数也是不错的。

    func myFunctionWithNumber(someNumber: Int) {

        func increment(var someNumber: Int) -> Int {
            return someNumber + 10
        }
        
        let incrementedNumber = increment(someNumber)
        println("The incremeted number is \(incrementedNumber)")
    }

    myFunctionWithNumber(5)
    // The incremeted number is 15

## @end

Swift 函数有更多的选项以及更为强大功能。从你开始利用 Swift 编程时，记住：能力越强责任越大。请一定要巧妙地优化可读性！

Swift 的最佳实践还没被确立，这门语言也在不断地进化，所以请朋友和同事来审查你的代码。我发现一些从来没见过 Swift 的人反而在我的 Swift 代码中提供了很大帮助。

Swift 编码快乐！

---

 

原文 [The Many Faces of Swift Functions](http://www.objc.io/issue-16/swift-functions.html)

