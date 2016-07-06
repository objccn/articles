在过去的时间里，人们对于设计 API 总结了很多通用的模式和最佳实践方案。一般情况下，我们总是可以从苹果的 Foundation、Cocoa、Cocoa Touch 和很多其他框架中总结出一些开发中的范例。毫无疑问，对于“特定情境下的 API 应该如何设计”这个问题，不同的人总是有着不同的意见，对于这个问题有很大的讨论空间。不过对于很多 Objective-C 的开发者来说，对于那些常用的模式早已习以为常。

随着 Swift 的出现，设计 API 引起了更多的问题。绝大多数情况下，我们只能继续做着手头的工作，然后把现有的方法翻译成 Swift 版本。不过，这对于 Swift 来说并不公平，因为和 Objective-C 相比，Swift 添加了很多新的特性。引用 Swift 创始人 [Chris Lattner](https://twitter.com/clattner_llvm) 的一段话：

> Swift 引入了泛型和函数式编程的思想，极大地扩展了设计的空间。

在这篇文章里，我们将会围绕 `Core Image` 进行 API 封装，以此为例，探索如何在 API 设计中使用这些新的工具。 `Core Image` 是一个功能强大的图像处理框架，但是它的 API 有时有点笨重。 `Core Image` 的 API 是弱类型的 - 它通过键值对 (key-value) 设置图像滤镜。这样在设置参数的类型和名字时很容易失误，会导致运行时错误。新的 API 将会十分的安全和模块化，通过使用类型而不是键值对来规避这样的运行时错误。

## 目标

我们的目标是构建一个 API ，让我们可以简单安全的组装自定义滤镜。举个例子，在文章的结尾，我们可以这样写：

    let myFilter = blur(blurRadius) >|> colorOverlay(overlayColor)
    let result = myFilter(image)

上面构建了一个自定义的滤镜，先模糊图像，然后再添加一个颜色蒙版。为了达到这个目标，我们将充分利用 Swift 函数是一等公民这一特性。项目源码可以在 Github 上的这个[示例项目](https://github.com/objcio/issue-16-functional-apis)中下载。

## Filter 类型

`CIFilter` 是 `Core Image` 中的一个核心类，用来创建图像滤镜。当实例化一个 `CIFilter` 对象之后，你 (几乎) 总是通过 `kCIInputImageKey` 来输入图像，然后通过 `kCIOutputImageKey` 获取返回的图像，返回的结果可以作为下一个滤镜的参数输入。

在我们即将开发的 API 里，我们会把这些键值对 (key-value) 对应的真实内容抽离出来，为用户提供一个安全的强类型 API。我们定义了自己的滤镜类型 `Filter`，它是一个可以传入图片作为参数的函数，并且返回一个新的图片。

    typealias Filter = CIImage -> CIImage

这里我们用 `typealias` 关键字，为 `CIImage -> CIImage`类型定义了我们自己的名字，这个类型是一个函数，它的参数是一个 `CIImage` ，返回值也是 `CIImage` 。这是我们后面开发需要的基础类型。

如果你不太熟悉函数式编程，你可能对于把一个函数类型命名为 `Filter` 感觉有点奇怪，通常来说，我们会用这样的命名来定义一个类。如果我们很想以某种方式来表现这个类型的函数式的特性，我们可以把它命名成 `FilterFunction` 或者一些其他的类似的名字。但是，我们有意识的选择了 `Filter` 这个名字，因为在函数式编程的核心哲学里，函数就是值，函数和结构体、整数、多元组、或者类，并没有任何区别。一开始我也不是很适应，不过一段时间之后发现，这样做确实很有意义。

## 构建滤镜

现在我们已经定义了 `Filter` 类型，接下来可以定义函数来构建特定的滤镜了。这些函数需要参数来设置特定的滤镜，并且返回一个类型为 `Filter` 的值。这些函数大概是这个样子：

    func myFilter(/* parameters */) -> Filter

注意返回的值 `Filter` 本身就是一个函数，在后面有利于我们将多个滤镜组合起来，以达到理想的处理效果。

为了让后面的开发更轻松一点，我们扩展了 `CIFilter` 类，添加了一个 convenience 的初始化方法，以及一个用来获取输出图像的计算属性：

    typealias Parameters = Dictionary<String, AnyObject>

    extension CIFilter {

        convenience init(name: String, parameters: Parameters) {
            self.init(name: name)
            setDefaults()
            for (key, value : AnyObject) in parameters {
                setValue(value, forKey: key)
            }
        }

        var outputImage: CIImage { return self.valueForKey(kCIOutputImageKey) as CIImage }

    }


这个 convenience 初始化方法有两个参数，第一个参数是滤镜的名字，第二个参数是一个字典。字典中的键值对将会被设置成新滤镜的参数。我们 convenience 初始化方法先调用了指定的初始化方法，这符合 Swift 的开发规范。

计算属性 `outputImage` 可以方便地从滤镜对象中获取到输出的图像。它查找 `kCIOutputImageKey` 对应的值并且将其转换成一个 `CIImage` 对象。通过提供这个属性， API 的用户不再需要对返回的结果手动进行类型转换了。

## 模糊

有了这些东西，现在我们就可以定义属于自己的简单滤镜了。高斯模糊滤镜只需要一个模糊半径作为参数，我们可以非常容易的完成一个模糊滤镜：

    func blur(radius: Double) -> Filter {
        return { image in
            let parameters : Parameters = [kCIInputRadiusKey: radius, kCIInputImageKey: image]
            let filter = CIFilter(name:"CIGaussianBlur", parameters:parameters)
            return filter.outputImage
        }
    }

就是这么简单，这个模糊函数返回了一个函数，新的函数的参数是一个类型为 `CIImage` 的图片，返回值 (`filter.outputImage`) 是一个新的图片 。这个模糊函数的格式是 `CIImage -> CIImage` ，满足我们前面定义的 `Filter` 类型的格式。

这个例子只是对 `Core Image` 中已有滤镜的一个简单的封装，我们可以多次重复同样的模式，创建属于我们自己的滤镜函数。

## 颜色蒙版

现在让我们定义一个颜色滤镜，可以在现有的图片上面加上一层颜色蒙版。 `Core Image` 默认没有提供这个滤镜，不过我们可以通过已有的滤镜组装一个。

我们使用两个模块来完成这个工作，一个是颜色生成滤镜 (`CIConstantColorGenerator`)，另一个是资源合成滤镜 (`CISourceOverCompositing`)。让我们先定义一个生成一个常量颜色面板的滤镜：

    func colorGenerator(color: UIColor) -> Filter {
        return { _ in
            let filter = CIFilter(name:"CIConstantColorGenerator", parameters: [kCIInputColorKey: color])
            return filter.outputImage
        }
    }

这段代码看起来和前面的模糊滤镜差不多，不过有一个较为明显的差异：颜色生成滤镜不会检测输入的图片。所以在函数里我们不需要给传入的图片参数命名，我们使用了一个匿名参数 `_` 来强调这个 filter 的图片参数是被忽略的。

接下来，我们来定义合成滤镜：

    func compositeSourceOver(overlay: CIImage) -> Filter {
        return { image in
            let parameters : Parameters = [ 
                kCIInputBackgroundImageKey: image, 
                kCIInputImageKey: overlay
            ]
            let filter = CIFilter(name:"CISourceOverCompositing", parameters: parameters)
            return filter.outputImage.imageByCroppingToRect(image.extent())
        }
    }

在这里我们将输出图像裁剪到和输入大小一样。这并不是严格需要的，要取决于我们想让滤镜如何工作。不过，在后面我们的例子中我们可以看出来这是一个明智之举。

    func colorOverlay(color: UIColor) -> Filter {
        return { image in
            let overlay = colorGenerator(color)(image)
            return compositeSourceOver(overlay)(image)
        }
    }

我们再一次返回了一个参数为图片的函数，`colorOverlay` 在一开始先调用了 `colorGenerator` 滤镜。`colorGenerator` 滤镜需要一个颜色作为参数，并且返回一个滤镜。因此 `colorGenerator(color)` 是 `Filter` 类型的。但是 `Filter` 类型本身是一个 `CIImage` 向 `CIImage` 转换的函数，我们可以在 `colorGenerator(color)` 后面加上一个类型为 `CIImage` 的参数，这样可以得到一个类型为 `CIImage` 的蒙版图片。这就是在定义 `overlay` 的时候发生的事情：我们用 `colorGenerator` 函数创建了一个滤镜，然后把图片作为一个参数传给了这个滤镜，从而得到了一张新的图片。返回值 `compositeSourceOver(overlay)(image)` 和这个基本相似，它由一个滤镜 `compositeSourceOver(overlay)` 和一个图片参数 `image` 组成。

## 组合滤镜

现在我们已经定义了一个模糊滤镜和一个颜色滤镜，我们在使用的时候可以把它们组合在一起：我们先将图片做模糊处理，然后再在上面放一个红色的蒙层。让我们先加载一张图片：

    let url = NSURL(string: "http://tinyurl.com/m74sldb");
    let image = CIImage(contentsOfURL: url)

现在我们可以把滤镜组合起来，同时应用到一张图片上：

    let blurRadius = 5.0
    let overlayColor = UIColor.redColor().colorWithAlphaComponent(0.2)
    let blurredImage = blur(blurRadius)(image)
    let overlaidImage = colorOverlay(overlayColor)(blurredImage)

我们又一次的通过滤镜组装了图片。比如在倒数第二行，我们先得到了模糊滤镜 `blur(blurRadius)` ，然后再把这个滤镜应用到图片上。

## 函数组装

不过，我们可以做的比上面的更好。我们可以简单的把两行滤镜的调用组合在一起变成一行，这是我脑海中想到的第一个能改进的地方：

    let result = colorOverlay(overlayColor)(blur(blurRadius)(image))

不过，这些圆括号让这行代码完全不具有可读性，更好的方式是定义一个函数来完成这项任务：

    func composeFilters(filter1: Filter, filter2: Filter) -> Filter {
        return { img in filter2(filter1(img)) }
    }

`composeFilters` 函数的两个参数都是 Filter ，并且返回了一个新的 Filter 滤镜。组装后的滤镜需要一个 `CIImage` 类型的参数，并且会把这个参数分别传给 `filter1` 和 `filter2` 。现在我们可以用 `composeFilters` 来定义我们自己的组合滤镜：

    let myFilter = composeFilters(blur(blurRadius), colorOverlay(overlayColor))
    let result = myFilter(image)

我们还可以更进一步的定义一个滤镜运算符，让代码更具有可读性，

    infix operator >|> { associativity left }

    func >|> (filter1: Filter, filter2: Filter) -> Filter {
        return { img in filter2(filter1(img)) }
    }

运算符通过 `infix` 关键字定义，表明运算符具有 `左` 和 `右` 两个参数。`associativity left` 表明这个运算满足左结合律，即：f1 >|> f2 >|> f3 等价于 (f1 >|> f2) >|> f3。通过使这个运算满足左结合律，再加上运算内先应用了左侧的滤镜，所以在使用的时候滤镜顺序是从左往右的，就像 Unix 管道一样。

剩余的部分是一个函数，内容和 `composeFilters` 基本相同，只不过函数名变成了 `>|>`。

接下来我们把这个组合滤镜运算器应用到前面的例子中：

    let myFilter = blur(blurRadius) >|> colorOverlay(overlayColor)
    let result = myFilter(image)

运算符让代码变得更易于阅读和理解滤镜使用的顺序，调用滤镜的时候也更加的方便。就好比是 `1 + 2 + 3 + 4` 要比 `add(add(add(1, 2), 3), 4)` 更加清晰，更加容易理解。

## 自定义运算符

很多 Objective-C 的开发者对于自定义运算符持有怀疑态度。在 Swift 刚发布的时候，这是一个并没有很受欢迎的特性。很多人在 C++ 中遭遇过自定义运算符过度使用 (甚至滥用) 的情况，有些是个人经历过的，有些是听到别人谈起的。

你可能对于前面定义的运算符 `>|>` 持有同样的怀疑态度，毕竟如果每个人都定义自己的运算符，那代码岂不是很难理解了？值得庆幸的是在函数式编程里有很多的操作，为这些操作定义一个运算符并不是一件很罕见的事情。

我们定义的滤镜组合运算符是一个[函数组合](http://en.wikipedia.org/wiki/Function_composition_%28computer_science%29)的例子，这是一个在函数式编程中广泛使用的概念。在数学里，两个函数 `f` 和 `g` 的组合有时候写做 `f ∘ g`，这样定义了一种全新的函数，将输入的 `x` 映射到 `f(g(x))` 上。这恰好就是我们的 `>|>` 所做的工作 (除了函数的逆向调用)。 

## 泛型

仔细想想，其实我们并没有必要去定义一个用来专门组装滤镜的运算符，我们可以用一个泛型的运算符来组装函数。目前我们的 `>|>` 是这样的：

    func >|> (filter1: Filter, filter2: Filter) -> Filter

这样定义之后，我们传入的参数只能是 `Filter` 类型的滤镜。

但是，我们可以利用 Swift 的通用特性来定义一个泛型的函数组合运算符：

    func >|> <A, B, C>(lhs: A -> B, rhs: B -> C) -> A -> C {
        return { x in rhs(lhs(x)) }
    }

这个一开始可能很难理解 -- 至少对我来说是这样。但是分开的看了各个部分之后，一切都变得清晰起来。

首先，我们来看一下函数名后面的尖括号。尖括号定义了这个函数适用的泛型类型。在这个例子里我们定义了三个类型：A、B 和 C。因为我们并没有指定这些类型，所以它们可以代表任何东西。

接下来让我们来看看函数的参数：第一个参数：lhs (left-hand side 的缩写)，是一个类型为 A -> B 的函数。这代表一个函数的参数为 A，返回值的类型为 B。第二个参数：rhs (right-hand side 的缩写)，是一个类型为 B -> C 的函数。参数命名为 lhs 和 rhs，因为它们分别对应操作符左边和右边的值。

重写了没有 `Filter` 的滤镜组合运算符之后，我们很快就发现其实前面实现的组合运算符只是泛型函数中的一个特殊情况：

    func >|> (filter1: CIImage -> CIImage, filter2: CIImage -> CIImage) -> CIImage -> CIImage

把我们脑海中的泛型类型 A、B、C 都换成 `CIImage`，这样可以清晰的理解用通用运算符的来替换滤镜组合运算符是多么的有用。

## 结论

至此，我们成功的用函数式 API 封装了 `Core Image`。希望这个例子能够很好的说明，对于 Objective-C 的开发者来说，在我们所熟知的 API 的设计模式之外有一片完全不同的世界。有了 Swift，我们现在可以动手探索那些全新的领域，并且将它们充分地利用起来。

---

 

原文 [Functional APIs with Swift](http://www.objc.io/issue-16/functional-swift-apis.html)
