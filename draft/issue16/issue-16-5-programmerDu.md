---
layout: post
title:  "Playground快速原型制作"
category: "16"
date: "2014-9-19 23:16"
author: "<a href=\"https://twitter.com/bradlarson\">Brad Larson</a>"
tags: article
---

Many developers enjoy building Mac or iOS applications because of how quickly one can create a viable application using the Cocoa frameworks. Even complex applications can be designed and built by small teams, in large part because of the capabilities provided by the tools and frameworks on these platforms. Swift playgrounds build on this tradition of rapid development, and they have the potential to change the way that we design and write Mac and iOS applications. 

借助Cocoa框架能够快速地创建一个可用的应用，这让许多开发者都喜欢上了OS X或iOS开发。如今即使是小团队也能设计和开发复杂的应用，这很大程度上要归功于这些平台所提供的工具和框架。Swift的Playground不仅继承了快速开发的传统，并且有改变我们设计和编写OS X和iOS应用的潜力。

For those not familiar with the concept, Swift playgrounds are interactive documents where Swift code is compiled and run live as you type. Results of operations are presented in a step-by-step timeline as they execute, and variables can be logged and inspected at any point. Playgrounds can be created within an existing Xcode project or as standalone bundles that run by themselves.

对于那些不熟悉的概念，Swift的playground就像是一个可交互的文档，在其中你可以输入swift语言让它们立即编译执行。操作结果随着执行的时间线一步步被展示，开发者能在任何时候记录和监视变量。无论是在现有的Xcode工程还是由playground单独运行的包里都可以创建Playground。

While a lot of attention has been focused on Swift playgrounds for their utility in learning this new language, you only need to look at similar projects like [IPython notebooks](http://ipython.org) to see the broader range of potential applications for interactive coding environments. IPython notebooks are being used today for tasks ranging from [scientific research](https://github.com/ipython/ipython/wiki/Research-at-UC-Berkeley-using-IPython) to [experimenting with machine vision](http://pyvideo.org/video/1796/simplecv-computer-vision-using-python). They're also being used to explore other language paradigms, such as [functional programming with Haskell](https://github.com/gibiansky/IHaskell).

Swift的playground主要还是作为学习这门语言的工具而被重视，然而我们只要关注一下类似项目，如[IPython的notebooks](http://ipython.org)，就能看到交互编程环境在更广阔的范围内的潜在作用。从[科学研究](https://github.com/ipython/ipython/wiki/Research-at-UC-Berkeley-using-IPython)到[机器视觉实验](http://pyvideo.org/video/1796/simplecv-computer-vision-using-python)，这些任务现在都使用了IPython notebooks。它们也被用来探索其他语言的范例，如[Haskell的函数式编程](https://github.com/gibiansky/IHaskell)。

We'll explore the use of Swift playgrounds for documentation, testing, and rapid prototyping. All Swift playgrounds used for this article can be [downloaded here](https://github.com/objcio/PersonalSwiftPlaygrounds).

接下来我们将探索Swift的playground在文档、测试和快速原型方面的用途。本文使用的所有Swift playground源码可以在[这里下载](https://github.com/objcio/PersonalSwiftPlaygrounds)。

## Playgrounds for Documentation and Testing

## 将Playground用于文档和测试

Swift is a brand new language, and many people are using playgrounds to understand its syntax and conventions. In addition to the language, we were provided with a new standard library. The functions in this standard library at present aren't documented particularly well, so resources like [the practicalswift.org list of standard library functions](http://practicalswift.com/2014/06/14/the-swift-standard-library-list-of-built-in-functions/) have sprung up.

Swift是一个全新的语言，许多人都使用playground来了解其语法和约定。不光是语言，Swift还提供了一个新的标准库。目前这个标准库的文档中对于方法的说明不太详细，所以雨后春笋般的涌现了许多像[practicalswift.org标准库方法列表](http://practicalswift.com/2014/06/14/the-swift-standard-library-list-of-built-in-functions/)这样的资源。

However, it's one thing to read about what a function should do and another to see it in action. In particular, many of these functions perform interesting actions on the new Swift collection classes, and it would be informative to examine how they act on these collections. 

不过通过文档知道方法的作用是一回事，在代码中实际调用又是另一回事。特别是许多方法在新语言Swift的collection class中能表现出有趣的特性，因此如果能在collections里实际检验它们的作用将非常有帮助。

Playgrounds provide a great opportunity to document functions and library interfaces by showing syntax and live execution against real data sets. For the case of the collection functions, we've created the [CollectionOperations.playground](https://github.com/objcio/PersonalSwiftPlaygrounds), which contains a list of these functions, all run against sample data that can be changed live.

Playgrounds展示语法和实时执行真实数据集的特性，为编写方法和库接口的文档提供了很好的机会。为了介绍Collection方法的使用，我们创建了一个叫[CollectionOperations.playground](https://github.com/objcio/PersonalSwiftPlaygrounds)的例子，其中包含了一系列collection方法的例子，所有的样例数据都能实时修改。

As a sample, we create our initial array using this:

例如，我们创建了如下的初始化数组：

```swift
let testArray = [0, 1, 2, 3, 4]
```

We then want to demonstrate the filter() function, so we write the following:

然后调用filter()方法：

```swift
let odds = testArray.filter{$0 % 2 == 1}
odds
```

The last line triggers the display of the array that results from this operation: `[1, 3]`. You get syntax, an example, and an illustration of how the function works, all in a live document.

最后一行显示当前数组为： `[1, 3]`。通过实时编译我们能了解语法、写出例子以及获得方法如何使用的说明，所有这些就如一个活的文档展示在眼前。

This is effective for other Apple or third-party frameworks as well. For example, Scene Kit is an excellent framework that Apple provides for quickly building 3D scenes on Mac and iOS, and you might want to show someone how to get started with it. You could provide a sample application, but that requires a build and compile cycle to demonstrate. 

这对于苹果框架和第三方库都奏效。 例如，你可能想给其他人展示如何使用Scene Kit，这是苹果提供的一个非常棒的框架，它能在Mac和iOS上快速构建3D场景。或许你会写一个示例应用，不过这样验证的时候就要构建和编译。

In the [SceneKitMac.playground](https://github.com/objcio/PersonalSwiftPlaygrounds), we've built a fully functional 3D scene with an animating torus. You will need to show the Assistant Editor (View \| Assistant Editor \| Show Assistant Editor) to display the 3D view, which will automatically render and animate. This requires no compile cycle, and someone could play around with this to change colors, geometry, lighting, or anything else about the scene, and see it be reflected live. It documents and presents an interactive example for how to use this framework.

在例子[SceneKitMac.playground](https://github.com/objcio/PersonalSwiftPlaygrounds) 中，我们已经建立了一个功能完备带动画的3D圆环。你需要打开Assistant Editor （在菜单上依次点击View | Assistant Editor | Show Assistant Editor），3D效果和动画将会被自动渲染。Playground不需要编译，而且任何的改动，比如改变颜色、几何形状、亮度等，都能实时反映出来。使用它能在一个交互例子中很好的记录和介绍如何使用框架。

In addition to documenting functions and their operations, you'll also note that we can verify that a function still operates as it should by looking at the results it provides, or even whether it still is parsed properly when we load the playground. It's not hard to envision adding assertions and creating real unit tests within a playground. Taken one step further, tests could be created for desired conditions, leading to a style of test-driven-development as you type.

除了记录方法和方法的操作，你还会注意到通过检查输出的结果，我们可以验证一个方法的执行是否正确，甚至在加载playground的时候就能判断方法是否被解析。不难想象我们也可以添加断言，在playground里创建真正的单元测试。或者更进一步，创建出符合条件的测试，从而让测试驱动开发按照你的方式进行。

In fact, in the [July 2014 issue of the PragPub magazine](http://www.swaine.com/pragpub/), Ron Jeffries has this to say in his article, "Swift from a TDD Perspective": 

事实上，在[2014年7月号的PragPub杂志](http://www.swaine.com/pragpub/)中，罗恩·杰弗里斯在他的文章“从测试驱动开发角度来看Swift”中提到过这一观点：

> The Playground will almost certainly have an impact on how we TDD. I think we’ll go faster, by using Playground’s ability to show us quickly what we can do. But will we go *better*, with the same solid scaffolding of tests that we’re used to with TDD? Or will we take a hit in quality, either through defects or less refactoring?


> Playground很大程度上会对我们如何执行测试驱动开发产生影响。Playground能够快速展示我们所能做的东西，因此我们将比之前走的更快。但是同过去的测试驱动开发框架结合在一起时，能否走的更好{/0}？或者无论是从缺陷还是重构数量上分析，我们的质量都能一炮打响？

While the question about code quality is for others to answer, let's take a look at how playgrounds can speed up development through rapid prototyping.

关于代码质量的问题还是留给别人回答吧，接下来我们一起来看看playground如何加快快速原型的开发。

## Prototyping Accelerate—Optimized Signal Processing
## 创建Accelerate的原型---经过优化的信号处理机制

The Accelerate framework contains powerful functions for parallel processing of large data sets. These functions take advantage of the vector-processing instructions present in modern CPUs, such as the SSE instruction set in Intel chips, or the NEON ones on ARM. However, for their power, their interfaces can seem opaque and documentation on their use is a little sparse. As a result, not as many developers take advantage of the libraries under Accelerate's umbrella.

Accelerate framework包括了许多功能强大的平行处理大型数据集的方法。这些方法利用现代CPU中矢量处理指令的优势，例如Intel芯片中的SSE指令集，或者ARM的NEON技术。然而，相较于功能的强大，Accelerate接口似乎有点不透明，其使用的文档也有点缺乏。这就导致许多开发者无法享用Accelerate这个保护伞所带来的便利。

Swift presents opportunities to make it much easier to interact with Accelerate through function overloading and the creation of wrappers around the framework. Chris Liscio has been experimenting with this in [his SMUGMath library](https://github.com/liscio/SMUGMath-Swift), which acted as the inspiration for this prototype.

Swift提供了一个机会，使得通过方法重载或包装器与Accelerate交互更加容易。这已经在Chris Liscio的库[SMUGMath](https://github.com/liscio/SMUGMath-Swift)的实践中被证实，swift作为灵感原型而存在。

Let's say you had a series of data samples that made up a sine wave, and you wanted to determine the frequency and amplitude of that sine wave. How would you do this? One way to find these values is by means of a Fourier transform, which can extract frequency and amplitude information from one or many overlapping sine waves. Accelerate provides a version of this, called a Fast Fourier Transform (FFT), for which a great explanation (with an IPython notebook) can be found [here](http://jakevdp.github.io/blog/2013/08/28/understanding-the-fft/).

假设你有一系列正弦波的数据样本，然后想通过这些数据来确定这个正弦波的频率和幅度。你会怎么做呢？一个解决方案是通过傅里叶变换来算出这些值，傅里叶变换能从一个或多个重叠的正弦波提取频率和幅度信息。Accelerate framework提供了另一个解决方案，叫做FFT（快速傅里叶变换(），关于这个方案[这里](http://jakevdp.github.io/blog/2013/08/28/understanding-the-fft/)有很好的解释（基于IPython notebook）。

To prototype this process, we'll be using the [AccelerateFunctions.playground](https://github.com/objcio/PersonalSwiftPlaygrounds), so you can follow along using that. Make sure you expose the Assistant Editor (View \| Assistant Editor \| Show Assistant Editor) to see the graphs generated at each stage.

我们在例子[AccelerateFunctions.playground](https://github.com/objcio/PersonalSwiftPlaygrounds)中实现了这个原型，你可以对照这个例子来看下面的内容。请确认你已经打开Assistant Editor（在菜单上依次点击View | Assistant Editor | Show Assistant Editor）以查看每一阶段所产生的图形。

The first thing to do is to generate some sample waveforms for us to experiment with. An easy way to do that is by the use of Swift's map() operator:

首先我们要产生一些用于实验的示例波形。使用Swift的map()方法可以很容易地实现：

```swift
let sineArraySize = 64

let frequency1 = 4.0
let phase1 = 0.0
let amplitude1 = 2.0
let sineWave = (0..<sineArraySize).map {
    amplitude1 * sin(2.0 * M_PI / Double(sineArraySize) * Double($0) * frequency1 + phase1)
}
```

For later use in the FFT, our starting waveform array sizes need to be powers of two. Adjusting the `sineArraySize` to values like 32, 128, or 256 will vary the resolution of the graphs presented later, but it won't change the fundamental results of the calculations.

为了便于之后使用FFT，我们的初始数组大小必须容得下两个完整的正弦波。把`sineArraySize`值改为32，128，或256将改变之后显示的图像的密度，但它不会改变计算的基本结果。

To plot our waveforms, we'll use the new XCPlayground framework (which needs to be imported first) and the following helper function:

要绘制我们的波形，我们将使用新的XCPlayground framework（需先导入到工程中）和以下辅助函数：

```swift
func plotArrayInPlayground<T>(arrayToPlot:Array<T>, title:String) {
    for currentValue in arrayToPlot {
        XCPCaptureValue(title, currentValue)
    }
}
```

When we do this:

当我们执行：

```swift
plotArrayInPlayground(sineWave, "Sine wave 1")
```

We see a graph that looks like the following:

我们可以看到如下所示的图表：

<img src="{{ site.images_path }}/issue-16/Sine1.png" style="width:563px"/>

That's a sine wave with a frequency of 4.0, amplitude of 2.0, and phase of 0.0. Let's make this more interesting by creating a second sine wave to add to the first, this time of frequency 1.0, amplitude 1.0, and a phase of pi / 2.0:

这是一个频率为4、振幅为2、相位为0的正弦波。为了变得更有趣一些，我们创建了第二个正弦波，它的频率为1.0、振幅为1.0、相位为π/2，然后把它叠加到第一个正弦波上。

```swift
let frequency2 = 1.0
let phase2 = M_PI / 2.0
let amplitude2 = 1.0
let sineWave2 = (0..<sineArraySize).map {
    amplitude2 * sin(2.0 * M_PI / Double(sineArraySize) * Double($0) * frequency2 + phase2)
}
```

<img src="{{ site.images_path }}/issue-16/Sine2.png" style="width:563px"/>

Now we want to combine them. This is where Accelerate starts to help us. Adding two arrays of independent floating-point values is well-suited to parallel processing. Accelerate's vDSP library has functions for just this sort of thing, so let's put them to use. For the fun of it, let's set up a Swift operator to use for this vector addition. Unfortunately, + is already used for array concatenation (perhaps confusingly so), and ++ is more appropriate as an increment operator, so we'll define a +++ operator for this vector addition:

现在我们要将两个波叠加。从这里开始Accelerate将为app贡献力量。刚刚增加的两个互相独立的浮点数组非常适合并行处理。这里我们要使用到Accelerate的vDSP库，它正好有这类功能的方法。为了让这一切更有趣，我们将重载一个Swift操作符用于向量叠加。不巧的是+这个操作符已经用于数组连接（可能容易被混淆），而++更适合作为递增运算符，因此我们将定义+++作为向量叠加的运算符。

```swift
infix operator  +++ {}
func +++ (a: [Double], b: [Double]) -> [Double] {
    assert(a.count == b.count, "Expected arrays of the same length, instead got arrays of two different lengths")

    var result = [Double](count:a.count, repeatedValue:0.0)
    vDSP_vaddD(a, 1, b, 1, &result, 1, UInt(a.count))
    return result
}
```

This sets up an operator that takes in two Swift arrays of `Double` values and outputs a single combined array from their element-by-element addition. Within the function, a blank result array is created at the size of our inputs (asserted to be the same for both inputs). Because Swift arrays of scalar values map directly to C arrays, we can just pass our input arrays of `Doubles` to the `vDSP_vaddD()` function and prefix our result array with `&`.

上文重载了一个操作符，操作符能将两个`Double`类型的Swift数组中的元素依次合并成一个数组。重载的运算符中创建了一个和输入的数组长度相等的空白数组（假设输入的两个数组长度相等）。由于Swift的一维数组直接映射成C语言的数组，因此我们只需要将作为参数的`Doubles`类型数组直接传递给`vDSP_vaddD()`方法，并在我们的数组结果前加前缀`&`。

To verify that this is actually performing a correct addition, we can graph the results of our sine wave combination using a for loop and our Accelerate function:

为了验证上述叠加是否被正确执行，我们可以使用for循环以及Accelerate方法来绘制合并后的正弦波的结果。

```swift
var combinedSineWave = [Double](count:sineArraySize, repeatedValue:0.0)
for currentIndex in 0..<sineArraySize {
    combinedSineWave[currentIndex] = sineWave[currentIndex] + sineWave2[currentIndex]
}

let combinedSineWave2 = sineWave +++ sineWave2

plotArrayInPlayground(combinedSineWave, "Combined wave (loop addition)")
plotArrayInPlayground(combinedSineWave2, "Combined wave (Accelerate)")
```

<img src="{{ site.images_path }}/issue-16/SineCombined.png" style="width:563px"/>

Sure enough, they're the same.

果然，结果是一致的。

Before moving on to the FFT itself, we will need another vector operation to work on the results from that calculation. All of the values provided from Accelerate's FFT implementation are squares, so we'll need to take their square root. We need to apply a function like `sqrt()` over each element in that array, so this sounds like another opportunity to use Accelerate.

在继续回到FFT本身之前，我们需要另一个向量运算符来处理之前的计算结果。Accelerate的FFT实现中获取的所有结果都是平方之后的，所以我们需要对他们做平方根操作。我们需要对数组中的所有元素调用类似`sqrt()`方法，这听上去又是一个使用Accelerate的机会。

Accelerate's vecLib library has parallel equivalents of many mathematical functions, including square roots in the form of `vvsqrt()`. This is a great case for the use of function overloading, so let's create a version of `sqrt()` that works on arrays of `Double` values:

Accelerate的vecLib库中有很多等价的数学方法，包括平方根的`vvsqrt()`。这是个使用方法重载的好例子，让我们来创建一个新版本的`sqrt()`，使其能处理`Double`类型的数组。

```swift
func sqrt(x: [Double]) -> [Double] {
    var results = [Double](count:x.count, repeatedValue:0.0)
    vvsqrt(&results, x, [Int32(x.count)])
    return results
}
```

Like with our addition operator, this takes in a `Double` array, creates a blank `Double` array for output values, and passes those directly into the `vvsqrt()` Accelerate function. We can verify that this works by typing the following into the playground:

和我们的叠加运算符一样，重载的平方函数输入一个`Double`数组，为输出创建了一个`Double`类型的数组，并将输入数组中的所有参数直接传递给Accelerate中的`vvsqrt()`。通过在playground中输入以下代码，我们可以验证刚刚重载的方法。

```swift
sqrt(4.0)
sqrt([4.0, 3.0, 16.0])
```

You'll see that the standard `sqrt()` function returns 2.0, and our new overload gives back [2.0, 1.73205080756888, 4.0]. In fact, this is such an easy-to-use overload, you can imagine repeating this for all the vecLib functions to create parallel versions of the math functions (and Mattt Thompson [has done just that](https://github.com/mattt/Surge)). For a 100000000-element array on a 15" mid-2012 i7 MacBook Pro, our Accelerate-based `sqrt()` runs nearly twice as fast as a simple array iteration using the normal scalar `sqrt()`.

我们能看到，标准`sqrt()`函数返回2.0，而我们的新建的重载方法返回了[2.0 1.73205080756888，4.0]。这的确是一个非常易用的重载方法，你甚至可以想象照以上方法使用vecLib为所有的数学方法写一个并行的版本（不过Mattt汤普森[已经做到了这一点](https://github.com/mattt/Surge) ）。在一台15寸的MacBook Pro中处理一个有一亿个元素的数组，使用基于Accelerate的`sqrt()`方法的运行速度比迭代使用一维的`sqrt()`快将近一倍。

With that done, let's implement the FFT. We're not going to go into extensive detail on the setup of this, but this is our FFT function:

完成了重载，我们来实现FFT。我们并不打算在FFT设置的细节上花费大量时间，以下是我们的FFT方法：

```swift
let fft_weights: FFTSetupD = vDSP_create_fftsetupD(vDSP_Length(log2(Float(sineArraySize))), FFTRadix(kFFTRadix2))

func fft(var inputArray:[Double]) -> [Double] {
    var fftMagnitudes = [Double](count:inputArray.count, repeatedValue:0.0)
    var zeroArray = [Double](count:inputArray.count, repeatedValue:0.0)
    var splitComplexInput = DSPDoubleSplitComplex(realp: &inputArray, imagp: &zeroArray)
    
    vDSP_fft_zipD(fft_weights, &splitComplexInput, 1, vDSP_Length(log2(CDouble(inputArray.count))), FFTDirection(FFT_FORWARD));
    vDSP_zvmagsD(&splitComplexInput, 1, &fftMagnitudes, 1, vDSP_Length(inputArray.count));

    let roots = sqrt(fftMagnitudes) // vDSP_zvmagsD returns squares of the FFT magnitudes, so take the root here
    var normalizedValues = [Double](count:inputArray.count, repeatedValue:0.0)

    vDSP_vsmulD(roots, vDSP_Stride(1), [2.0 / Double(inputArray.count)], &normalizedValues, vDSP_Stride(1), vDSP_Length(inputArray.count))
    return normalizedValues
}
```

As a first step, we set up the FFT weights that need to be used for a calculation of the array size we're working with. These weights are used later on in the actual FFT calculation, but can be calculated via `vDSP_create_fftsetupD()` and reused for arrays of a given size. Since this array size remains constant in this document, we calculate the weights once as a global variable and reuse them in each FFT.

第一步，我们创建了一个fft_weights变量，用于存储计算结果。稍后将被用于FFT计算的fft_weights，由`vDSP_create_fftsetupD()`方法返回和并且被确定大小的数组重复利用。由于该数组的大小仍然是本文档中的常量，我们计算的权重，一旦作为一个全局变量和重用他们每个FFT。

Within the FFT function, the `fftMagnitudes` array is initialized with zeroes at the size of our waveform in preparation for it holding the results of the operation. An FFT operation takes complex numbers as input, but we only care about the real part of that, so we initialize `splitComplexInput` with the input array as the real components, and zeroes for the imaginary components. Then `vDSP_fft_zipD() and vDSP_zvmagsD()` perform the FFT and load the `fftMagnitudes` array with squares of the magnitudes from the FFT.

在FFT方法中，初始化了一个用于存放操作结果的数组`fftMagnitudes`，数组的初始元素都为0，大小为之前正弦波的大小。FFT运算的输入参数都是复杂的数字，但我们真正关心的只是一小部分内容，因此我们初始化`splitComplexInput`的时候输入了数组作为实数分类，而零作为虚数分量。然后`vDSP_fft_zipD()`和`vDSP_zvmagsD()`执行FFT，并使用FFT中的平方值来加载`fftMagnitudes`数组。

At this point, we use the previously mentioned Accelerate-based array `sqrt()` operation to take the square root of the squared magnitudes, returning the actual magnitudes, and then normalize the values based on the size of the input array.

在这里我们使用了之前提到的基于Accelerate的`sqrt()`方法来计算平方根、返回实际大小，然后在输入数组的基础上正常化返回值。

The results from this entire operation look like this for the individual sine waves:

以上所有操作的的结果就是产生了如下的单一正弦波：

<img src="{{ site.images_path }}/issue-16/FFT12.png" style="width:563px"/>

And they look like this for the combined sine wave:

叠加的正弦波看起来像这样：

<img src="{{ site.images_path }}/issue-16/FFTCombined.png" style="width:563px"/>

As a very simplified explanation of these values: The results represent 'bins' of sine wave frequencies, starting at the left, with the values in those bins corresponding to the amplitude of the wave detected at that frequency. They are symmetric about the center, so you can ignore the values on the right half of that graph.

对这些值一个简单的解释是：这些结果表示了正弦波频率的集合，从左边开始，集合中的值表示了在该频率下的波的振幅。它们关于中心对称，因此你可以忽略图中右半部分的值。

What you can observe is that for the frequency 4.0, amplitude 2.0 wave, we see a value of 2.0 binned in bin number 4 in the FFT. Likewise, for the frequency 1.0, amplitude 1.0 wave, we see a 1.0 value in bin number 1 of the FFT. The FFT of the combined sine waves, despite the complex shape of that resultant wave, clearly pulls out the amplitude and frequency of both component waves in their separate bins as if the FFTs themselves were added.

可以观察到对于频率为4振幅为2的波，在FFT中2对应的值为4。同样对于频率为1振幅为1的波，在FFT中1对应的值为1。尽管叠加后的正弦波得到的FFT波形比较复杂，但是依然能够清晰地区分合并的两个波在各自集合内的振幅和频率，就仿佛它们的FFT分别加入一样。

Again, this is a simplification of the FFT operation, and there are shortcuts taken in the above FFT code, but the point is that we can explore even a complex signal processing operation easily using step-by-step creation of functions in a playground and testing each operation with immediate graphical feedback.

再次强调，这是FFT运算的简化版本，在上文的FFT代码中有简化操作，但关键是在playground中通过一步步创建方法，我们能轻松地探索一个复杂的信号处理操作，并且每一步操作的测试都能立即得到图形反馈。

## The Case for Rapid Prototyping Using Swift Playgrounds
## 使用Swift Playgrounds快速创建原型的案例

Hopefully, these examples have demonstrated the utility of Swift playgrounds for experimentation with new libraries and concepts. 

我们希望这些例子能够证明Swift playground在实践新类库和新概念上的作用。

At each step in the last case study, we could glance over to the timeline to see graphs of our intermediate arrays as they were processed. That would take a good amount of effort to set up in a sample application and display in an interface of some kind. All of these graphs also update live, so you can go back and tweak a frequency or amplitude value for one of our waveforms and see it ripple through these processing steps. That shortens the development cycle and helps to provide a gut feel for how calculations like this behave.

上一个例子中的每一步里，我们都能在执行时通过时间线中的图案来观察中间数组的状态。这对于一个示例程序来说作用非常大，而且也以某种方式为程序提供了界面。所有这些图像都实时更新，因此你能随时回退并修改其中一个波的频率或振幅，然后看着波形随着处理步骤变化。这缩短了开发周期，并且对计算过程的体验提供了巨大帮助。

This kind of interactive development with immediate feedback makes an excellent case for prototyping even complex algorithms in a playground before deployment in a full application.

这种立即反馈的交互式开发为部署前在playground中快速开发完整的应用甚至是复杂的算法提供了极好的案例。
