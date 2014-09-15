##热烈欢迎结构体和值类型


If you've stuck to Objective-C—and languages like Ruby, Python, or JavaScript—the prominence of structs in Swift might seem especially alien. Classes are the traditional unit of structure in object-oriented languages. Indeed, in contrast to structs, Swift classes support implementation inheritance, (limited) reflection, deinitializers, and multiple owners.

如果你曾经使用过 Objective-C 或者像 Ruby，Python，JavaScript 这样的语言，可能会觉得 Swift 里的结构体就像外星人一样奇异。类是面向对象编程语言中传统的结构单元。的确，和结构体相比，Swift 的类支持实现继承，(受限的)反射，析构函数和多所有者。


If classes are so much more powerful than structs, why use structs? Well, it's exactly their limited scope that makes them such flexible building blocks. In this article, you'll learn how structs and other value types can radically improve your code's clarity, flexibility, and reliability.

既然类比结构体强大这么多，为什么还要使用结构体？正是因为它的使用范围受限，使得结构体在构建代码块(blocks)的时候非常灵活。在本文中，你将会学习到结构体和其他的值类型是如何大幅提高代码的清晰度、灵活性和可读性的。

###Value Types and Reference Types
###值类型和引用类型

A small distinction in behavior drives the architectural possibilities at play here: structs are *value types* and classes are *reference types*.

行为驱动架构上的一个细微的区别可能在这：结构体是*值类型*的，而类是*引用类型*的。

Instances of value types are copied whenever they're assigned or used as a function argument. Numbers, strings, arrays, dictionaries, enums, tuples, and structs are value types. For example:

值类型的实例，不管是在赋值或是作为函数参数的时候，都是被复制的。数字，字符串，数组，字典，枚举，元组和结构体都是值类型。比如：

	var a = "Hello"
	var b = a
	b.extend(", world")
	println("a: \(a); b: \(b)") // a: Hello; b: Hello, world
	
Instances of reference types (chiefly: classes) can have multiple owners. When assigning a reference to a new variable or passing it to a function, those locations all point to the same instance. This is the behavior you're used to with objects. For instance:

引用类型的实例(主要是类)可以有多个所有者。将一个引用赋值给一个新的变量或者传递给一个函数的时候，它们都指向同一个实例。这是你熟悉的对象的行为。比如：

	var a = UIView()
	var b = a
	b.alpha = 0.5
	println("a: \(a.alpha); b: \(b.alpha)") // a: 0.5; b: 0.5
	
The distinction between these two categories seems small, but the choice between values and references can have huge ramifications for your system's architecture.

这两种类型的区别看起来似乎不大，但是选择值类型还是选择引用类型会给你的系统架构带来很大的差异。

###Building Our Intuition
###培养我们的直觉

Now that we understand the differences between how value and reference types *behave*, let's talk about the differences between how we might use them.

既然我们已经知道了值类型和引用类型*行为*上的区别，现在让我们讨论一下使用上的区别。

Swift might someday have reference types other than objects, but for this discussion, we'll focus on objects as the exemplar reference types.

Swift 将来除了对象可能还会有其他的引用类型，但是就这次讨论，我们只将对象作为引用类型的范例。

We reference objects in code the same way we reference objects in the real world. Books often use a real-world metaphor to teach people object-oriented programming: you can make a `Dog` class, then instantiate it to define `fido`. If you pass `fido` around to different parts of the system, they're all still talking about the same `fido`. That makes sense, since if you actually had a dog named Fido, whenever you would talk about him in conversation, you'd be transmitting his *name*—not the dog itself, whatever that would mean. You'd be relying on everyone else having some idea of who Fido is. When you use objects, you're passing 'names' of instances around the system.

我们在代码中引用对象和我们在现实生活中引用对象是一样的。编程书籍经常使用一个现实世界的隐喻来教授人们面向对象编程：你可以创建一个 `Dog` 类，然后将它实例化来定义 `fido`(译注：狗的名字)。如果你将 `fido` 在系统的不同部分之间传递，他们谈论的仍然是同一个 `fido`。这是有意义的，因为如果你的确有一只叫 Fido 的狗，无论何时你谈到它时，你将会使用它的*名字*进行信息传输——而不是狗本身。你可能依赖于其他人知道 Fido 是谁。当你使用对象的时候，你是在系统内传递着实例的`名字`。 

Values are like data. If you send someone a table of expenses, you're not sending that person a label that represents that information—you're sending the *information itself*. Without talking to anyone else, the listener could calculate a total, or write the expenses down to consult later. If the listener prints out the expenses and modifies them, that doesn't modify the table you still have.

值就像数据一样。如果你向别人发出了一桌的费用，你发出的不是一个代表那个信息的标签——你是在传递*信息本身*。消息接收者可以在不和任何人交流的情况下，计算总和，或者把费用写下来供日后查阅。如果消息接收者打印了费用并且修改了它们，这也没有修改你的桌子的费用。

A value can be a number, perhaps representing a price, or a string—like a description. It could be a selection among options—an enum: was this expense for a dinner, for travel, or for materials? It could contain several other values in named positions, like the `CLLocationCoordinate2D` struct, which specifies a latitude and longitude. Or it could be a list of other values... and so on.

一个值可以是一个数字，也许代表一个价格，或是一个类似字符串的描述。它可以是枚举中的一个选项：这次的花费是因为一顿晚餐，还是旅行，还是材料？在指定的位置中还能包括一些其他的值，比如一个代表经度和纬度的 `CLLocationCoordinate2D` 结构体。或者它可以是一些其他值的列表等等。

Fido might run around and bark on his own accord. He might have special behavior that makes him different from every other dog. He might have relationships established with others. You can't just swap Fido out for another dog—your kids could tell the difference! But the table of expenses exists in isolation. Those strings and numbers don't do anything. They aren't going to change out from under you. No matter how many different ways you write the "6" in the first column, it's still just a "6."

Fido 可能在自己的地盘里来回跑叫。它也许会有特殊的行为使它区别于其他的狗。他可能会同其他的狗建立关系。你不能把 Fido 换成其他的狗——你的孩子们会发现的！但是一桌的花费是独立的。那些字符串和数字不会做任何事情。它们不会背着你私下改变。不管你用多少种不同的方式在第一列写入了一个`6`，它永远只会是一个`6`。

And that's what's so great about value types.

这就是值类型的伟大之处。


##The Advantages of Value Types
##值类型的优势

Objective-C and C had value types, but Swift allows you to use them in previously impractical scenarios. For instance, the generics system permits abstractions that handle value and reference types interchangeably: Array works equally well for Ints as for UIViews. Enums are vastly more expressive in Swift, since they can now carry values and specify methods. Structs can conform to protocols and specify methods.

Objective-C 和 C 具有值类型，但是 Swift 允许你在以前不能使用的场景下使用它们。比如，泛型系统允许抽象处理值和引用类型互换。数组存储整型数据和存储 `UIViews` 一样。Swift 中的枚举的表现更是大放异彩，因为它们现在可以携带值类型和指定的方法了。结构体可以遵守协议和指定的方法。

Swift's enhanced support for value types affords a tremendous opportunity: value types are an incredibly flexible tool for making your code simpler. You can use them to extract isolated, predictable components from fat classes. Value types enforce—or at least encourage—many properties that work together to create clarity by default.

Swift 增强了对值类型的支持，这提供了一个巨大的机会：值类型成为了使代码简单的一个非常灵活的工具。你可以使用它们将孤立的、可预见组件从臃肿的类中抽离出来。默认情况下，值类型被强制使用或者至少说被鼓励使用在属性上，来使得工作更清晰。


In this section, I'll describe some of the properties that value types encourage. It's worth noting that you can make objects that have these properties, but the language provides no pressure to do that. If you see an object in some code, you have no reasonable expectation of these properties, whereas if you see a value type, you do. It's true that not all value types have these properties—we'll cover that shortly—but these are reasonable generalizations.

在这部分，我会描述一些鼓励使用值类型属性的情形。值得注意的是，你可以使对象包含这些属性，但是语言本身并没有非要你那么做。如果你在代码里看到了一个对象，你对这些属性没有合理的期望，然而，如果你看到了一个值类型，那么你就会有合理的期望。诚然，不是所有的值类型都有这些属性——我们稍后会讨论这个——但是这是合理的概括。

###Value Types Want to Be Inert
###值类型是稳定的

A value type does not, in general, behave. It is typically inert. It stores data and exposes methods that perform computations using that data. Some of those methods might cause the value type to mutate itself, but control flow is strictly controlled by the single owner of the instance.

总的来说，值类型不具有行为。它是非常稳定的。它保存数据并暴露使用这些数据进行计算的方法。其中的一些方法可能会使值类型本身发生改变，但是控制流却还是严格地受控于该实例的唯一所有者。

And that's great! It's much easier to reason about code that will only execute when directly invoked by a single owner.

这太好了！这下更容易思考被唯一所有者直接调用才会执行的代码了。

By contrast, an object might register itself as a target of a timer. It might receive events from the system. These kinds of interactions require reference types' multiple-owner semantics. Because value types can only have a single owner and they don't have deinitializers, it's awkward to write value types that perform side effects on their own.

相比之下，一个对象可能将它自己注册为一个定时器的 target。它可能会接收到来自系统的事件。这样的交互需要引用类型的多所有者语意。因为值类型只能有一个所有者并且没有析构函数，使用值类型让它们对自己产生副作用是不明智的。

###Value Types Want to Be Isolated
###值类型是孤立的

A typical value type has no implicit dependencies on the behavior of any external components. Its interactions with its one owner are vastly easier to understand at a glance than a reference type's interactions with an unknowable number of owners. It is isolated.

一个典型的值类型对任何外部组件的行为都没有隐式的依赖。一眼看上去，与引用类型和引用类型的未知个数的所有者之间的交互相比，值类型和它的唯一所有者之间的交互要简单多了。它是孤立的。

If you're accessing a reference to a mutable instance, you have an implicit dependency on all its other owners: they could change it out from under you at any time.

如果你正在获取一个可变实例的引用，那么你对该实例的所有其他所有者都产生了隐式依赖：它们可能在任何时刻背着你偷偷改变它。

###Value Types Want to Be Interchangeable
###值类型是可交换的

Because a value type is copied every time it's assigned to a new variable, all of those copies are completely interchangeable.
因为每次将值类型赋给一个新变量的时候，该值类型都是被复制的，所以，所有的这些副本都是可交换的。


You can safely store a value that's passed to you, then later use that value as if it were 'new.' No one can compare that instance with another using anything but the data contained within it. Interchangeability also means that it doesn't matter how a given value was constructed—as long as it compares equal via ==, it's equivalent for all purposes.

你可以安全地存储传递给你的值，然后在将来就像使用`新`值一样使用它们。人们区分该实例和其他实例的唯一依据就是实例所包含的数据。可交换还意味着不管一个给定的值是是由构造而来还是使用 == 比较而来，所有情形下都是相等的。

So if you use value types to communicate between components in your system, you can readily shift around your graph of components. Do you have a view that paints a sequence of touch samples? You can compensate for touch latency without touching the view's code by making a component that consumes a sequence of touch samples, appends an estimate of where the user's finger will move based on previous samples, and returns a new sequence. You can confidently give your new component's output to the view—it can't tell the difference.

所以如果你使用值类型同系统里的组件进行通信，你可以很容易地改变你的组件图。你有没有一个视图用来描绘触摸采样的序列？你不用触及视图代码，只通过一个触摸采样序列的组件，就可以补偿触摸延迟，依据前一次的采样，追加用户手指将要移动位置的预测，然后返回一个新的序列。你可以自信地将另一个新的组件的输出传给视图——因为它分辨不出区别。

There's no need for a fancy mocking framework to write unit tests that deal with value types. You can directly construct values indistinguishable from the 'live' instances flowing through your app. The touch-predicting component described above is easy to unit test: predictable value types in; predictable value types out; no side effects.

为值类型编写单元测试不需要花哨的模拟(mocking)框架。你可以直接从应用程序中的`活的`实例中构造出无分别的值。上面提到的触摸预测组件很容易进行单元测试：可预测的值类型输入；可预测的值类型输出；没有副作用。

This is a huge advantage. In a traditional architecture of objects that behave, you have to test the interactions between the object you're testing and the rest of the system. That typically means awkward mocking or extensive setup code establishing those relationships. Value types want to be isolated, inert, and interchangeable, so you can directly construct a value, call a method, and examine the output. Simpler tests with greater coverage mean code that's easier to change.

这是巨大的优势。在以对象行为主导的传统架构中，你必须要测试与正被测试的对象的交互以及与系统的其他部分之间的交互。那通常意味着笨拙的模拟，或者为了建立那样的关系而添加了大量的设置代码。值类型是孤立的，稳定的和可交换的，所以你可以直接地构建一个值，调用一个方法，然后检查输出。更简单的测试，更大的覆盖范围意味着代码更容易修改。

###Not All Value Types Have These Properties
###不是所有的值类型都有这些属性

While the structure of value types encourages these properties, you can certainly make value types that violate them.

虽然结构体的值类型鼓励这些属性，但是你也可以使值类型违反这些属性。

Value types containing code that executes without being called by its owner are often unpredictable and should generally be avoided. For example: a struct initializer might call `dispatch_after` to schedule some work. But passing an instance of this struct to a function would duplicate the scheduled effect, inexplicitly, since a copy would be made. Value types should be inert.

包含不是由所有者调用而执行的代码的值类型，通常是不可预测的并且通常情况下应该是要避免使用的。比如：一个结构体的构造函数可能调用 `dispatch_after` 来安排一些工作。但是将该结构体的一个实例传递给函数会不经意地二次影响安排的工作，这是因为进行了一次复制。值类型应该是稳定的。

Value types containing references are not necessarily isolated and should generally be avoided: they carry a dependency on all other owners of that referent. These value types are also not readily interchangeable, since that external reference might be connected to the rest of your system in some complex way.

包含引用的值类型通常都不是孤立的，并且应该避免使用它们：他们携带了对那个对象的所有其他所有者的依赖。这些值类型也不是易交换的，因为外部引用可能以复杂的方式与系统的其他部分相联系。

##The Object of Objects
##对象们的对象

I am emphatically not suggesting that we build everything out of inert values.

我当然不是建议使用稳定的值类型来构建所有的事情。

Objects are useful precisely because they do not have the properties I described above. An object is an acting entity in the system. It has identity. It can *behave*, often independently.

更精确地讲，对象也是有用的，因为它们不包含我上面所说的属性。一个对象在系统中扮演着实体的角色。它有身份，具有*行为*，通常也是独立的。

That behavior is often complex and difficult to reason about, but some of the details can usually be represented by simple values and isolated functions involving those values. Those details don't need to be entangled with the complex behavior of the object. By separating them, the behavior of the object becomes clearer itself.

那种行为通常复杂并且不容易思考，但是其中一些细节通常可以由简单的值和孤立地函数调用表现出来。那些细节不会和对象的复杂的行为交织在一起。通过将它们分离，对象的行为变得清晰了。

Think of objects as a thin, imperative layer above the predictable, pure value layer.

将对象看成是一个薄的、命令式的层，它位于可预测的、纯值类型的层之上。

Objects maintain state, defined by values, but those values can be considered and manipulated independently of the object. The value layer doesn't really have state; it just represents and transmutes data. That data may or may not have higher-level meaning as state, depending on the context in which the value's used.

对象保持状态，通过值来定义，但是那些值可以在对象里被思考和操控。值层(value layer)实际上没有状态；它仅仅用来表示和变换数据。那些数据作为状态可能有(也可能没有)高层的意味，这取决于使用值的上下文。

Objects perform side effects like I/O and networking, but data, computations, and non-trivial decisions ultimately driving those side effects all exist at the value layer. The objects are like the membrane, channeling those pure, predictable results into the impure realm of side effects.

对象就像 I/O 和网络一样会有副作用，但是数据，计算和重要的决策最后都驱动这些副作用存在于值类型层。对象就像薄膜，通过这一层薄膜，将那些纯净的、可预测的结果进入副作用的不纯净的领域。

Objects can communicate with other objects, but they generally send values, not references, unless they truly intend to create a persistent connection at the outer, imperative layer.

对象可以和其他对象通信，但是通常它们发送的是值，而不是引用，除非它们确实想要和外部不可或缺的层创建一个持久的连接。

##A Summarizing Pitch for Value Types
##值类型的总结

Value types enable you to make typical architectures significantly clearer, simpler, and more testable.

值类型能够使你构建非常清晰，简单，更容易测试的典型架构。

Value types typically have fewer or no dependencies on outside state, so there's less you have to consider when reasoning about them.

值类型与外部状态通常没有依赖或者只有很少的依赖，所以当你思考他们的时候，你只需要考虑很少的一部分。

Value types are inherently more composable and reusable because they're interchangeable.

值类型是内在可组合的和可重用的，因为它们是可交换的。

Finally, a value layer allows you to isolate the active, behaving elements from the inert business logic of your application. As you make more code inert, your system will become easier to test and change over time.

最后，一个值类型层允许你从应用程序稳定的业务逻辑中独立出活动的行为元素。代码越稳定，你的系统会变得越容易测试和修改。

##References
##参考文献

* [Boundaries](https://www.destroyallsoftware.com/talks/boundaries), by Gary Bernhardt, proposes a similar two-level architecture and elaborates on its benefits for concurrency and testing.

* [Are We There Yet?](http://www.infoq.com/presentations/Are-We-There-Yet-Rich-Hickey), by Rich Hickey, elaborates on the distinctions between value, state, and identity.

* [The Structure and Interpretation of Computer Programs](http://mitpress.mit.edu/sicp/), by Harry Abelson and Gerald Sussman, illustrates just how much can be represented with simple values.











