Although Objective-C has some strange-looking syntax compared to other programming languages, the method syntax is pretty straightforward once you get the hang of it. Here is a quick throwback:  

虽然 Objective-C 的语法相对于其他编程语言来说写法有点奇怪，但是当你真正使用的时候它的语法还是相当的简单。下面有一些例子：

```objectivec

+ (void)mySimpleMethod
{
    // class method
    // 类方法
    // no parameters 
    // 无参数方法
    // no return values
    // 无返回值
}

- (NSString *)myMethodNameWithParameter1:(NSString *)param1 parameter2:(NSNumber *)param2
{
    // instance method
    //  实例方法
    // one parameter of type NSString pointer, one parameter of type NSNumber pointer
    // 其中一个参数是 NSString 指针 类型，另一个是 NSNumber 指针类型
    // must return a value of type NSString pointer
    // 必须返回一个 NSString 指针类型的值
    return @"hello, world!";
}
```

In contrast, while Swift syntax looks a lot more like other programming languages, it can also get a lot more complicated and confusing than Objective-C. 

相比而言，Swift 的语法与其他编程语言有更多相似的地方，同时也比 Objective-C 更加复杂和令人费解。

Before I continue, I want to clarify the difference between a Swift *method* and *function*, as I'll be using both terms throughout this article. Here is the definition of Methods, according to Apple's [Swift Programming Language Book](https://developer.apple.com/library/prerelease/mac/documentation/Swift/Conceptual/Swift_Programming_Language/Methods.html):

在继续之前，我需要澄清 Swift 中**方法**和**函数**之间的不同，因为在本文中我们将使用这两个术语。按照 Apple 的 [Swift Programming Language Book](https://developer.apple.com/library/prerelease/mac/documentation/Swift/Conceptual/Swift_Programming_Language/Methods.html) 里面的方法定义：

> Methods are functions that are associated with a particular type. Classes, structures, and enumerations can all define instance methods, which encapsulate specific tasks and functionality for working with an instance of a given type. Classes, structures, and enumerations can also define type methods, which are associated with the type itself. Type methods are similar to class methods in Objective-C.

> 方法是与某些特定类型相关联的函数。类、结构体、枚举都可以定义实例方法；实例方法为给定类型的实例封装了具体的任务与功能。类、结构体、枚举也可以定义类型方法；类型方法与类型本身相关联。类型方法与 Objective-C 中的类方法（class methods）相似。

TL;DR: Functions are standalone, while methods are functions that are encapsulated in a class, struct, or enum. 
TL;DR (译者注：the phrase too long; didn't read。意思就是太长了，别读了。这里应该是总结成一句话): 函数是独立的，而方法是函数封装在类，结构或者枚举中。

## Anatomy of Swift Functions

## 剖析 Swift 函数

Let's start with a simple "Hello, World!" Swift function: 

让我们从简单的 “Hello，World” Swift 函数开始：

```swift
func mySimpleFunction() {
    println("hello, world!")
}
```

If you've ever programmed in any other language aside from Objective-C, the above function should look very familiar. 

如果你曾在 Objective-C 之外的语言进行过编程，上面的这个函数你会非常熟悉

* The `func` keyword denotes that this is a function.
* The name of this function is `mySimpleFunction`.
* There are no parameters passed in—hence the empty `( )`.
* There is no return value.
* The function execution happens between the `{ }`.

* `func` 表示这是一个函数。
* 函数的名称是 `mySimpleFunction`。
* 这个函数没有参数传入 - 因此是`( )`。
* 函数没有返回值
* 函数是在`{ }`中执行

Now on to a slightly more complex function: 

现在让我们看一个稍稍复杂的例子：

```swift
func myFunctionName(param1: String, param2: Int) -> String {
    return "hello, world!"
}
```

This function takes in one parameter named `param1` of type `String` and one parameter named `param2` of type `Int` and returns a `String` value. 

这个函数有一个 `String` 类型且名为 `param1` 的参数和一个 `Int` 类型名为 `param2` 的参数并且返回值是 `String`  类型。

## Calling All Functions

调用所有函数

One of the big differences between Swift and Objective-C is how parameters work when a Swift function is called. If you love the verbosity of Objective-C, like I do, keep in mind that parameter names are not included externally by default when a Swift function is called: 

Swift 和 Objective-C 之间其中一个巨大的差别就是当 Swift 函数被调用的时候参数工作方式。如果你喜欢 Objective-C 冗长的命名方式，如我一般，那么请记住，在默认情况下 Swift 函数被调用时参数名不被外部包含在内。

```swift
func hello(name: String) {
    println("hello \(name)")
}

hello("Mr. Roboto")
```

This might not seem so bad until you add a few more parameters to your function: 

在你增加更多参数到函数之前，一切看起来不是那么糟糕：

```swift
func hello(name: String, age: Int, location: String) {
    println("Hello \(name). I live in \(location) too. When is your \(age + 1)th birthday?")
}

hello("Mr. Roboto", 5, "San Francisco")
```

From reading just `hello("Mr. Roboto", 5, "San Francisco")`, you would have a hard time knowing what each parameter actually is. 

如果仅阅读 `hello("Mr. Roboto", 5, "San Francisco")`，你可能很难知道每一个参数代表什么。

In Swift, there is a concept of an *external parameter name*  clarify this confusion: 

在 Swift 中，有一个概念称为 **外部参数名称* * 用来阐明困惑之处：

```swift
func hello(fromName name: String) {
    println("\(name) says hello to you!")
}

hello(fromName: "Mr. Roboto")
```

In the above function, `fromName` is an external parameter, which gets included when the function is called, while `name` is the internal parameter used to reference the parameter inside the function execution. 

上面函数中，`fromName` 是一个外部参数，是在函数被调用的时候，被内部参数 `name` 引用去执行函数。

If you want the external and internal parameter names to be the same, you don't have to write out the parameter name twice: 

如果你希望外部参数和内部参数相同，你不需要写两次参数名：

```swift
func hello(name name: String) {
    println("hello \(name)")
}

hello(name: "Robot")
```

Instead, just add a `#` in front of the parameter name as a shortcut: 

相反的，只需要在参数前面添加 `#` 的快捷方式： 

```swift
func hello(#name: String) {
    println("hello \(name)")
}

hello(name: "Robot")
```

And of course, the rules for how parameters work are slightly different for Methods...

当然，对于方法而言参数的工作方式略有不同...

## Calling On Methods

## 调用方法

When encapsulated in a class (or struct or enum), the first parameter name of a method is *not* included externally, while all following parameter names are included externally when the method is called:

当分装在类（或者结构，枚举）中，方法的第一个参数名**不**被外部包含，反而后面的参数在方法调用时候被外部包含：

```swift
class MyFunClass {
    
    func hello(name: String, age: Int, location: String) {
        println("Hello \(name). I live in \(location) too. When is your \(age + 1)th birthday?")
    }
    
}

let myFunClass = MyFunClass()
myFunClass.hello("Mr. Roboto", age: 5, location: "San Francisco")
```

It is therefore best practice to include your first parameter name in your method name, just like in Objective-C: 

因此最佳实践是方法名包含第一个参数名，就像 Objective-C 那样：

```swift
class MyFunClass {
    
    func helloWithName(name: String, age: Int, location: String) {
        println("Hello \(name). I live in \(location) too. When is your \(age + 1)th birthday?")
    }
    
}

let myFunClass = MyFunClass()
myFunClass.helloWithName("Mr. Roboto", age: 5, location: "San Francisco")
```

Instead of calling my function "hello," I renamed it to `helloWithName` to make it very clear that the first parameter is a name. 

相对于调用函数 “hello”，我重命名为 `helloWithName` 使得更清晰的知道第一个参数是 name。

If for some special reason you want to skip the external parameter names in your function (I'd recommend having a very good reason for doing so), use an `_` for the external parameter name: 

如果出于一些原因你希望在函数中跳过外部参数名（我建议你需要一个非常好的理由这样做），为外部函数添加 `_` 来解决：

```swift
class MyFunClass {
    
    func helloWithName(name: String, _ age: Int, _ location: String) {
        println("Hello \(name). I live in \(location) too. When is your \(age + 1)th birthday?")
    }
    
}

let myFunClass = MyFunClass()
myFunClass.helloWithName("Mr. Roboto", 5, "San Francisco")
```

### Instance Methods Are Curried Functions

### 实例方法是局部调用函数

One cool thing to note is that [instance methods are actually curried functions in Swift](http://oleb.net/blog/2014/07/swift-instance-methods-curried-functions/).

需要注意一个非常酷的是 [Swift 中实例方法是局部调用函数](http://oleb.net/blog/2014/07/swift-instance-methods-curried-functions/)。

> The basic idea behind currying is that a function can be partially applied, meaning that some of its parameter values can be specified (bound) before the function is called. Partial function application yields a new function.
> 局部调用背后的基本想法是函数可以局部应用，意思是一些参数值可以在函数之前被指定或者绑定。部分函数应用 yields 一个新的函数。

So given that I have a class: 

因此我有一个类：

```swift
class MyHelloWorldClass {
    
    func helloWithName(name: String) -> String {
        return "hello, \(name)"
    }
}
```

I can create a variable that points to the class's `helloWithName` function: 

我可以建立一个变量指向类中的 `helloWithName` ：

```swift
let helloWithNameFunc = MyHelloWorldClass.helloWithName
// MyHelloWorldClass -> (String) -> String
``` 
My new `helloWithNameFunc` is of type `MyHelloWorldClass -> (String) -> String`, a function that takes in an instance of my class and returns another function that takes in a String value and returns a String value. 

我新的 `helloWithNameFunc` 是 `MyHelloWorldClass -> (String) -> String` 类型，函数接受我的类的一个实例并返回另一个函数，它接受一个字符串值，并返回一个字符串值。

So I can actually call my function like this: 

所以实际上我可以这样调用我的函数

```swift
let myHelloWorldClassInstance = MyHelloWorldClass()

helloWithNameFunc(myHelloWorldClassInstance)("Mr. Roboto") 
// hello, Mr. Roboto
```

## Init: A Special Note
## 初始化：一个特殊注意的地方

A special `init` method is called when a class, struct, or enum is initialized. In Swift, you can define initialization parameters, just like with any other method: 

特殊的 `init` 方法是在类，结构体或者枚举初始化的时候调用。在 Swift 中你可以像其他方法那样定义初始化参数：

```swift
class Person {
    
    init(name: String) {
        // your init implementation
        // 你的初始化方法实现
    }
    
}

Person(name: "Mr. Roboto")
```

Notice that, unlike other methods, the first parameter name of an init method is required externally when the class is instantiated. 

注意下，不像其他方法，初始化方法的第一个参数必须在实例时必须是外部的。

It is best practice in most cases to add a different external parameter name—`fromName` in this case—to make the initialization more readable: 

大多数情况下的最佳实践是添加一个不同的外部参数名 — 本例中的 `fromName` —让初始化更具有阅读性：

```swift
class Person {
    
    init(fromName name: String) {
        // your init implementation
        // 你的初始化方法实现
    }
    
}

Person(fromName: "Mr. Roboto")
```

And of course, just like with other methods, you can add an `_` if you want your init method to skip the external parameter name. I love the readability and power of this initialization example from the [Swift Programming Language Book](https://developer.apple.com/library/prerelease/mac/documentation/Swift/Conceptual/Swift_Programming_Language/Initialization.html#//apple_ref/doc/uid/TP40014097-CH18-XID_306): 

当然，就像其他方法那样，如果你想让方法调过外部参数名可以添加 `_`。我喜欢  [Swift Programming Language Book](https://developer.apple.com/library/prerelease/mac/documentation/Swift/Conceptual/Swift_Programming_Language/Initialization.html#//apple_ref/doc/uid/TP40014097-CH18-XID_306) 初始化例子的强大和可读性。

```swift
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
// boilingPointOfWater.temperatureInCelsius is 100.0

let freezingPointOfWater = Celsius(fromKelvin: 273.15)
// freezingPointOfWater.temperatureInCelsius is 0.0

let bodyTemperature = Celsius(37.0)
// bodyTemperature.temperatureInCelsius is 37.0
```

Skipping the external parameter can also be useful if you want to abstract how your class / enum / struct gets initialized. I love the use of this in [David Owen's](https://twitter.com/owensd) [json-swift library](https://github.com/owensd/json-swift/blob/master/src/JSValue.swift): 

如果你希望抽象类/枚举/结构体的初始化，跳过外部参数可以非常有用。我喜欢在  [David Owen's](https://twitter.com/owensd) 的 [json-swift library](https://github.com/owensd/json-swift/blob/master/src/JSValue.swift) 中这样使用。

```swift
public struct JSValue : Equatable {
    
    // ... truncated code
    // ... 截断的部分代码

    /// Initializes a new `JSValue` with a `JSArrayType` value.
    /// 初始化 `JSValue` 包含初始化参数 `JSArrayType`。 
    public init(_ value: JSArrayType) {
        self.value = JSBackingValue.JSArray(value)
    }

    /// Initializes a new `JSValue` with a `JSObjectType` value.
    /// 初始化 `JSValue` 包含初始化参数 `JSObjectType`。 
    public init(_ value: JSObjectType) {
        self.value = JSBackingValue.JSObject(value)
    }

    /// Initializes a new `JSValue` with a `JSStringType` value.
    /// 初始化 `JSValue` 包含初始化参数 `JSStringType`。
    public init(_ value: JSStringType) {
        self.value = JSBackingValue.JSString(value)
    }

    /// Initializes a new `JSValue` with a `JSNumberType` value.
    /// 初始化 `JSValue` 包含初始化参数 `JSNumberType`。
    public init(_ value: JSNumberType) {
        self.value = JSBackingValue.JSNumber(value)
    }

    /// Initializes a new `JSValue` with a `JSBoolType` value.
    /// 初始化 `JSValue` 包含初始化参数 `JSBoolType`。
    public init(_ value: JSBoolType) {
        self.value = JSBackingValue.JSBool(value)
    }

    /// Initializes a new `JSValue` with an `Error` value.
    /// 初始化 `JSValue` 包含初始化参数 `Error`。
    init(_ error: Error) {
        self.value = JSBackingValue.Invalid(error)
    }

    /// Initializes a new `JSValue` with a `JSBackingValue` value.
    /// 初始化 `JSValue` 包含初始化参数 `JSBackingValue`。
    init(_ value: JSBackingValue) {
        self.value = value
    }
}
```

## Fancy Parameters
## 华丽的参数
Compared to Objective-C, Swift has a lot of extra options for what type of parameters can be passed in. Here are some of examples. 
相较于 Objective-C，Swift 有很多额外的选项用来指定可以传入的参数类型，下面是一些例子

### Optional Parameter Types
### 可选参数类型

In Swift, there is a new concept of [optional types](https://developer.apple.com/library/prerelease/mac/documentation/Swift/Conceptual/Swift_Programming_Language/TheBasics.html): 

在 Swift 中有一个新的概念称之为  [optional types](https://developer.apple.com/library/prerelease/mac/documentation/Swift/Conceptual/Swift_Programming_Language/TheBasics.html): 

> Optionals say either “there is a value, and it equals x” or “there isn’t a value at all.” Optionals are similar to using nil with pointers in Objective-C, but they work for any type, not just classes. Optionals are safer and more expressive than nil pointers in Objective-C and are at the heart of many of Swift’s most powerful features.
> 可选表示“那儿有一个值，并且它等于 x ”或者“那儿没有值”。可选有点像在 Objective-C 中使用nil，但是它可以用在任何类型上，不仅仅是类。可选类型比 Objective-C 中的nil指针更加安全也更具表现力，它是 Swift 许多强大特性的重要组成部分。

To indicate that a parameter type is optional (can be nil), just add a question mark after the type specification: 
表明一个参数是可选（可以是 nil），可以在类型规范后添加一个问号：

```swift
func myFuncWithOptionalType(parameter: String?) {
    // function execution
}

myFuncWithOptionalType("someString")
myFuncWithOptionalType(nil)
```

When working with optionals, don't forget to unwrap!
使用可选时候不要忘记拆包！

```swift
func myFuncWithOptionalType(optionalParameter: String?) {
    if let unwrappedOptional = optionalParameter {
        println("The optional has a value! It's \(unwrappedOptional)")
    } else {
        println("The optional is nil!")
    }
}

myFuncWithOptionalType("someString")
// The optional has a value! It's someString

myFuncWithOptionalType(nil)
// The optional is nil
```

Coming from Objective-C, getting used to working with optionals definitely takes some time!

如果学习过 Objective-C，那么习惯使用可选肯定需要一些时间！

### Parameters with Default Values
### 默认参数值

```swift
func hello(name: String = "you") {
    println("hello, \(name)")
}

hello(name: "Mr. Roboto")
// hello, Mr. Roboto

hello()
// hello, you
```

Note that a parameter with a default value automatically has an external parameter name. 
值得注意的是有默认值的参数自动包含一个外部参数名

And since parameters with a default value can be skipped when the function is called, it is best practice to put all your parameters with default values at the end of a function's parameter list. Here is a note from the [Swift Programming Language Book](https://developer.apple.com/library/prerelease/mac/documentation/Swift/Conceptual/Swift_Programming_Language/Functions.html) on the topic:  

由于参数的默认值可以在函数被调用时调过，所以最佳时间是把含有默认值的参数放在函数参数列表的最后。[Swift Programming Language Book](https://developer.apple.com/library/prerelease/mac/documentation/Swift/Conceptual/Swift_Programming_Language/Functions.html) 包含相关的内容介绍

> Place parameters with default values at the end of a function’s parameter list. This ensures that all calls to the function use the same order for their non-default arguments, and makes it clear that the same function is being called in each case.
> 把含有默认值的参数放在参数列表最后，是确保所有无默认值参数使用了相同的顺序，而且清晰表述了在不同情况下相同函数被调用。

I'm a huge fan of default parameters, mostly because it makes code easy to change and backward compatible. You might start out with two parameters for your specific use case at the time, such as a function to configure a custom `UITableViewCell,` and if another use case comes up that requires another parameter (such as a different text color for your cell's label), just add a new parameter with a default value—all the other places where this function has already been called will be fine, and the new part of your code that needs the parameter can just pass in the non-default value!
我是默认参数的粉丝，主要使得代码容易改变而且向后兼容。你可以在你的用例中用两个参数开始，比如配置一个自定义的 `UITableViewCell,`，如果另一个用例出现，需要另一个参数(如你的 Cell 的 label 含有不同文字颜色)，只需要添加一个包含新默认值的参数 — 函数的其他部分已经被正确调用，并且你代码最新部分仅需要参数传入一个非默认值。

### Variadic Parameters 
### 可变参数

Variadic parameters are simply a more readable version of passing in an array of elements. In fact, if you were to look at the type of the internal parameter names in the below example, you'd see that it is of type `[String]` (Array of Strings): 

可变参数是传入数组元素的一个更加可读的版本。实际上，比如下面例子中的内部参数名类型，你可以看到是 `[String]` 类型 (Array of Strings): 


```swift
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
```

The catch here is to remember that it is possible to pass in 0 values, just like it is possible to pass in an empty array, so don't forget to check for the empty array if needed:

异常捕获在这里需要记住可以传入 0 值，就像传入一个空数组，所以如果需要不要忘记检查空数组：

```swift
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
```

Another note about variadic parameters—the variadic parameter must be the *last* parameter in your function's parameter list! 

可变参数另一个要注意的地方是 — 可变参数必须是在函数列表的**最后**一个！

### Inout Parameters
### 输入输出参数

With inout parameters, you have the ability to manipulate external variables (aka pass by reference):
利用输入输出参数，你有能力操纵外部变量（即经过引用）:

```swift
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
``` 

This is a very common pattern in Objective-C for handling error scenarios. `NSJSONSerialization` is just one example: 
这是 Objective-C 中非常常见的模式用来处理错误场景。 `NSJSONSerialization` 只是其中一个例子：

```objectivec
- (void)parseJSONData:(NSData *)jsonData
{
    NSError *error = nil;
    id jsonResult = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (!jsonResult) {
        NSLog(@"ERROR: %@", error.description);
    }
}
```

Since Swift is so new, there aren't clear conventions on handling errors just yet, but there are definitely a lot of options beyond inout parameters! Take a look at David Owen's recent blog post on [error handling in Swift](http://owensd.io/2014/08/22/error-handling-take-two.html). More on this topic should also be covered in [Functional Programming in Swift](http://www.objc.io/books/). 

Swift 非常之新，所以这里没有一个明确的处理错误的方案，但是在输入输出参数之下肯定有非常多的选择！看看 David Owen's  最新的博客 [Swfit 中的错误处理](http://owensd.io/2014/08/22/error-handling-take-two.html). 以及更多相关内容已经在 [Functional Programming in Swift](http://www.objc.io/books/) 中涵盖. 


### Generic Parameter Types
### 泛型参数类型

I'm not going to get too much into generics in this post, but here is a very simple example for how you can make a function accept parameters of different types while making sure that both parameters are of the same type:

我不会在本文中提到过多的泛型参数，但是这里有个简单的例子来阐述你一个函数中如果接受不同类型的参数来确保两个参数相同：

```swift
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
```

For a lot more information on Generics, I recommend taking a look at the [Generics section](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Generics.html) of the Swift Programming Language book. 

更多的泛型知识，我建议你阅读下 Swift Programming Language book 中的[泛型章节](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Generics.html)

### Variable Parameters
### 变量参数

By default, parameters that are passed into a function are constants, so they cannot be manipulated within the scope of the function. If you would like to change that behavior, just use the var keyword for your parameters:

默认情况下，参数传入函数是一个常量，所以他在函数范围内不能被操纵，如果你想修改这个行为，只需要在你的参数使用 var 关键字：

```swift
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
```

Note that this is different than an inout parameter—variable parameters do not change the external passed-in variable!
值得注意的是这个和 inout 参数不同 — 变量参数不会修改外部传入变量！


### Functions as Parameters
### 函数既参数

In Swift, functions can be passed around just like variables. For example, a function can have another function passed in as a parameter:
在 Swift 中，函数可以被用来当做变量传递。比如，一个函数含有一个被用来当做参数的函数：

```swift
func luckyNumberForName(name: String, #lotteryHandler: (String, Int) -> String) -> String {
    let luckyNumber = Int(arc4random() % 100)
    return lotteryHandler(name, luckyNumber)
}

func defaultLotteryHandler(name: String, luckyNumber: Int) -> String {
    return "\(name), your lucky number is \(luckyNumber)"
}

luckyNumberForName("Mr. Roboto", lotteryHandler: defaultLotteryHandler)
// Mr. Roboto, your lucky number is 38
```

Note that only the function reference gets passed in—`defaultLotteryHandler` in this case. The function gets executed later as decided by the receiving function. 
注意下只有函数的引用被传入 —`defaultLotteryHandler` 在本例子中。这个函数的执行由传入函数决定。

Instance methods can also be passed in a similar way: 
实例方法也可以用类似的方法传入：

```swift
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
```

To make your function definition a bit more readable, consider type-aliasing your function (similar to typedef in Objective-C): 
让你的函数定义更具可读性，考虑你函数的类型别名（类似于 Objective-C 中的 typedef）：

```swift
typealias lotteryOutputHandler = (String, Int) -> String

func luckyNumberForName(name: String, #lotteryHandler: lotteryOutputHandler) -> String {
    let luckyNumber = Int(arc4random() % 100)
    return lotteryHandler(name, luckyNumber)
}
```

You can also have a function without a name as a parameter type (similar to blocks in Objective-C): 
你也可以有一个不包含名为 name 参数的函数（类似于 Objective-C 中的 blocks）：

```swift
func luckyNumberForName(name: String, #lotteryHandler: (String, Int) -> String) -> String {
    let luckyNumber = Int(arc4random() % 100)
    return lotteryHandler(name, luckyNumber)
}

luckyNumberForName("Mr. Roboto", lotteryHandler: {name, number in
    return "\(name)'s' lucky number is \(number)"
})
// Mr. Roboto's lucky number is 74
```

In Objective-C, using blocks as parameters is popular for completion and error handlers in methods that execute an asynchronous operation. This should continue to be a popular pattern in Swift as well. 
在 Objective-C 中，使用 blocks 作为参数是异步操作完成和错误处理的常见方式，这一方式在 Swift 中得到了很好的延续。


## Access Controls
## 权限控制

Swift has three levels of [Access Controls](https://developer.apple.com/library/prerelease/mac/documentation/Swift/Conceptual/Swift_Programming_Language/AccessControl.html): 
Swift 有三个级别的[权限控制](https://developer.apple.com/library/prerelease/mac/documentation/Swift/Conceptual/Swift_Programming_Language/AccessControl.html): 

- **Public access** enables entities to be used within any source file from their defining module, and also in a source file from another module that imports the defining module. You typically use public access when specifying the public interface to a framework.
- **Internal access** enables entities to be used within any source file from their defining module, but not in any source file outside of that module. You typically use internal access when defining an app’s or a framework’s internal structure.
- **Private access** restricts the use of an entity to its own defining source file. Use private access to hide the implementation details of a specific piece of functionality.
- **Public access** 可以访问自己模块或应用中源文件里的任何实体，别人也可以访问引入该模块中源文件里的所有实体。通常情况下，某个接口或 Framework 是可以被任何人使用时，你可以将其设置为 public 级别
- **Internal access** 可以访问自己模块或应用中源文件里的任何实体，但是别人不能访问该模块中源文件里的实体。通常情况下，某个接口或 Framework 作为内部结构使用时，你可以将其设置为 internal 级别。
- **Private access** 只能在当前源文件中使用的实体，称为私有实体。使用 private 级别，可以用作隐藏某些功能的实现细节。

By default, every function and variable is internal—if you want to change that, you have to use the `private` or `public` keyword in front of every single method and variable: 
默认情况下，每个函数和变量是内部的—如果你希望修改他们，你需要使用 `private` 或者 `public` 关键字在每个方法和变量的前面：

```swift
public func myPublicFunc() {
    
}

func myInternalFunc() {
    
}

private func myPrivateFunc() {
    
}

private func myOtherPrivateFunc() {
    
}
```

Coming from Ruby, I prefer to put all my private functions at the bottom of my class, separated by a landmark: 

Ruby 带来的习惯，我喜欢把所有的私有函数放在类的最下面，利用一个 //MARK 来区分：

```swift 
class MyFunClass {
    
    func myInternalFunc() {
        
    }
    
    // MARK: Private Helper Methods
    
    private func myPrivateFunc() {
        
    }
    
    private func myOtherPrivateFunc() {
        
    }
}
```

Hopefully future releases of Swift will include an option to use one private keyword to indicate that all methods below it are private, similar to how access controls work in other programming languages.
希望 Swift 在将来的版本中包含一个选项可以用一个私有关键字来表明以下所有的方法都是私有的，类似于其他语言那样做访问控制


## Fancy Return Types
## 华丽的返回类型

In Swift, function return types and values can get a bit more complex than we're used to in Objective-C, especially with the introduction of optionals and multiple return types. 
在 Swift 中，函数的返回类型和返回值相较于 Objective-C 而言更加复杂，尤其是引入可选和多个返回类型。

### Optional Return Types
### 可选返回类型

If there is a possibility that your function could return a nil value, you need to specify the return type as optional: 
如果你的函数有可能返回一个 nil 值，你需要指定返回类型为可选：

```swift
func myFuncWithOptonalReturnType() -> String? {
    let someNumber = arc4random() % 100
    if someNumber > 50 {
        return "someString"
    } else {
        return nil
    }
}

myFuncWithOptonalReturnType()
```

And of course, when you're using the optional return value, don't forget to unwrap:
当然，当你使用可选返回值，不要忘记拆包：

```swift
let optionalString = myFuncWithOptonalReturnType()

if let someString = optionalString {
    println("The function returned a value: \(someString)")
} else {
    println("The function returned nil")
}
```

The best explanation I've seen of optionals is from a [tweet by @Kronusdark](https://twitter.com/Kronusdark/status/496444128490967041): 
对我而言最好的可选的解释来自于  [tweet by @Kronusdark](https://twitter.com/Kronusdark/status/496444128490967041): 

> I finally get @SwiftLang optionals, they are like Schrödinger's cat! You have to see if the cat is alive before you use it.


### Multiple Return Values
### 多重返回值

One of the most exciting features of Swift is the ability for a function to have multiple return values:
Swift 其中一个令人兴奋的功能是函数可以有多重返回值

```swift 
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
```

As you can see, the multiple return values are returned in a tuple, a very simple data structure of grouped values. There are two ways to use the multiple return values from the tuple: 
就像你看到的那样，在一个元组中返回多个值，一个非常简单的数据结构的组合值。有两种方法可以使用多重返回值的元组:

```swift
let range = findRangeFromNumbers(1, 234, 555, 345, 423)
println("From numbers: 1, 234, 555, 345, 423. The min is \(range.min). The max is \(range.max).")
// From numbers: 1, 234, 555, 345, 423. The min is 1. The max is 555.

let (min, max) = findRangeFromNumbers(236, 8, 38, 937, 328)
println("From numbers: 236, 8, 38, 937, 328. The min is \(min). The max is \(max)")
// From numbers: 236, 8, 38, 937, 328. The min is 8. The max is 937
```  

### Multiple Return Values and Optionals
### 多返回值与可选

The tricky part about multiple return values is when the return values can be optional, but there are two ways to handle dealing with optional multiple return values. 
多重返回值的有一部分非常棘手，当返回值是可选的时候，对于这种情况有两种解决办法。

In the above example function, my logic is flawed—it is possible that no values could be passed in, so my program would actually crash if that ever happened. If no values are passed in, I might want to make my whole return value optional: 
在上面的例子函数中，我的逻辑是有缺陷的—它有可能没有值传入，所以我的代码有可能在没有值传入的时候崩溃，所以我希望我整个返回值是可选的：

```swift
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
```

In other cases, it might make sense to make each return value within a tuple optional, instead of making the whole tuple optional: 
另一种做法是对元组中的每个返回值设为可选来代替整体的元组可选：

```swift
func componentsFromUrlString(urlString: String) -> (host: String?, path: String?) {
    let url = NSURL(string: urlString)
    return (url.host, url.path)
}
``` 

If you decide that some of your tuple values could be optionals, things become a little bit more difficult to unwrap, since you have to consider every single combination of optional values: 
如果你决定你元组值中一些值是可选，拆包时候会变的有些复杂，你需要考虑没中单独的可选返回值的组合：

```swift
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
```

As you can see, this is not your average Objective-C way of doing things!
如你所见，它和 Objective-C 的处理方式完全不同！

### Return a Function
### 返回一个函数

Any function can also return a function in Swift: 
Swift 中函数可以返回一个函数：

```swift
func myFuncThatReturnsAFunc() -> (Int) -> String {
    return { number in
        return "The lucky number is \(number)"
    }
}

let returnedFunction = myFuncThatReturnsAFunc()

returnedFunction(5) // The lucky number is 5
```

To make this more readable, you can of course use type-aliasing for your return function: 
为了更具有可读性，你当然可以为你的返回函数定义一个别名：

```swift
typealias returnedFunctionType = (Int) -> String

func myFuncThatReturnsAFunc() -> returnedFunctionType {
    return { number in
        return "The lucky number is \(number)"
    }
}

let returnedFunction = myFuncThatReturnsAFunc()

returnedFunction(5) // The lucky number is 5
```

## Nested Functions
## 嵌套函数
And in case you haven't had enough of functions from this post, it's always good to know that in Swift you can have a function inside a function:
如果在这篇文章中你没对函数有足够的体会，那么了解下 Swift 可以在函数中定义函数也是不错的。

```swift
func myFunctionWithNumber(someNumber: Int) {

    func increment(var someNumber: Int) -> Int {
        return someNumber + 10
    }
    
    let incrementedNumber = increment(someNumber)
    println("The incremeted number is \(incrementedNumber)")
}

myFunctionWithNumber(5)
// The incremeted number is 15
``` 

## @end
## @end
Swift functions have a lot of options and a lot of power. As you start writing in Swift, remember: with great power comes great responsibility. Optimize for READABILITY over cleverness! 

Swift 函数有更多的选项以及更为强大功能。从你开始利用 Swift 编程，记住：能力越强责任越强。机智的优化可读性！

Swift best practices haven't been fully established yet, and the language is still constantly changing, so get your code reviewed by friends and co-workers. I've found that people who've never seen Swift before sometimes teach me the most about my Swift code.

Swift 的最佳事件还没被确立，这门语言也在不断的进化，所以让你的代码被同事和朋友审查，因为我发现一些从来没见过 Swift 在我的 Swift 代码中提供了很大帮助。

Happy Swifting!
