由于使用 Cocoa 框架能够快速地创建一个可用的应用，这让许多开发者都喜欢上了 OS X 或 iOS 开发。如今即使是小团队也能设计和开发复杂的应用，这很大程度上要归功于这些平台所提供的工具和框架。Swift 的 Playground 不仅继承了快速开发的传统，并且有改变我们设计和编写 OS X 和 iOS 应用方式的潜力。

向那些还不熟悉这个概念的读者解释一下，Swift 的 playground 就像是一个可交互的文档，在其中你可以输入 Swift 代码让它们立即编译执行。操作结果随着执行的时间线一步步被展示，开发者能在任何时候输出和监视变量。Playground 既可以在现有的 Xcode 工程中进行创建，也能作为单独的包存在。

Swift 的 playground 主要还是作为学习这门语言的工具而被重视，然而我们只要关注一下类似项目，如 [IPython notebooks](http://ipython.org)，就能看到交互编程环境在更广阔的范围内的潜在应用。从[科学研究](https://github.com/ipython/ipython/wiki/Research-at-UC-Berkeley-using-IPython)到[机器视觉实验](http://pyvideo.org/video/1796/simplecv-computer-vision-using-python)，这些任务现在都使用了 IPython notebooks。这种方式也被用来探索其他语言的范例，如 [Haskell 的函数式编程](https://github.com/gibiansky/IHaskell)。

接下来我们将探索 Swift 的 playground 在文档、测试和快速原型方面的用途。本文使用的所有 Swift playground 源码可以在[这里下载](https://github.com/objcio/PersonalSwiftPlaygrounds)。

## 将 Playground 用于文档和测试

Swift 是一个全新的语言，许多人都使用 playground 来了解其语法和约定。不光是语言，Swift 还提供了一个新的标准库。目前这个标准库的文档中对于方法的说明不太详细，所以雨后春笋般的涌现了许多像 [practicalswift.org 标准库方法列表](http://practicalswift.com/2014/06/14/the-swift-standard-library-list-of-built-in-functions/)这样的资源。

> <p><span class="secondary radius label">编者注</span> 在<a href="http://swifter.natecook.com">这里</a>有一份自动生成和整理的 Swift 标准库文档，可以作为参考。

不过通过文档知道方法的作用是一回事，在代码中实际调用又是另一回事。特别是许多方法在新语言 Swift 的 collection class 中能表现出有趣的特性，因此如果能在 collections 里实际检验它们的作用将非常有帮助。

Playground 展示语法和实时执行真实数据的特性，为编写方法和库接口提供了很好的机会。为了介绍 Collection 方法的使用，我们创建了一个叫 [CollectionOperations.playground](https://github.com/objcio/PersonalSwiftPlaygrounds) 的例子，其中包含了一系列 collection 方法的例子，所有的样例数据都能实时修改。

例如，我们创建了如下的初始数组：

    let testArray = [0, 1, 2, 3, 4]

然后想试试 `filter()` 方法：

    let odds = testArray.filter{$0 % 2 == 1}

最后一行显示这个操作所得到的结果的数组为： `[1, 3]`。通过实时编译我们能了解语法、写出例子以及获得方法如何使用的说明，所有这些就如一个活的文档展示在眼前。

这对于其他的苹果框架和第三方库都奏效。 例如，你可能想给其他人展示如何使用 Scene Kit，这是苹果提供的一个非常棒的框架，它能在 Mac 和 iOS 上快速构建3D场景。或许你会写一个示例应用，不过这样展示的时候就要构建和编译。

在例子 [SceneKitMac.playground](https://github.com/objcio/PersonalSwiftPlaygrounds) 中，我们已经建立了一个功能完备带动画的 3D 场景。你需要打开 Assistant Editor (在菜单上依次点击 View | Assistant Editor | Show Assistant Editor)，3D 效果和动画将会被自动渲染。这不需要编译循环，而且任何的改动，比如改变颜色、几何形状、亮度等，都能实时反映出来。使用它能在一个交互例子中很好的记录和介绍如何使用框架。

除了展示方法和方法的操作，你还会注意到通过检查输出的结果，我们可以验证一个方法的执行是否正确，甚至在加载到 playground 的时候就能判断方法是否被正确解析。不难想象我们也可以在 playground 里添加断言，以及创建真正的单元测试。或者更进一步，创建出符合条件的测试，从而在你打字时就实现测试驱动开发。

事实上，在 [2014 年 7 月号的 PragPub 杂志](http://www.swaine.com/pragpub/)中，Ron Jeffries 在他的文章 “从测试驱动开发角度来看Swift” 中提到过这一观点：

> Playground 很大程度上会对我们如何执行测试驱动开发产生影响。Playground 能够快速展示我们所能做的东西，因此我们将比之前走得更快。但是同过去的测试驱动开发框架结合在一起时，能否走的更好？我们是否能提炼出更好的代码，以满足更少的缺陷数量和重构？

关于代码质量的问题还是留给别人回答吧，接下来我们一起来看看 playground 如何加快一个快速原型的开发。

## 创建 Accelerate 的原型 -- 经过优化的信号处理

Accelerate 框架包括了许多功能强大的并行处理大型数据集的方法。这些方法可以利用例如 Intel 芯片中的 SSE 指令集，或者 ARM 芯片中的 NEON 技术等，这样的现代 CPU 中矢量处理指令的优势。然而，相较于功能的强大，它们的接口似乎有点不透明，其使用的文档也有点缺乏。这就导致许多开发者无法使用 Accelerate 这个强大的工具所带来的优势。

Swift 提供了一个机会，通过方法重载或为 Accelerate 框架进行包装后，可以让交互更加容易。这已经在 Chris Liscio 的库 [SMUGMath](https://github.com/liscio/SMUGMath-Swift) 的实践中被证实，这也正是我们接下来将要创建的原型的灵感来源。

假设你有一系列正弦波的数据样本，然后想通过这些数据来确定这个正弦波的频率和幅度，你会怎么做呢？一个解决方案是通过傅里叶变换来算出这些值，傅里叶变换能从一个或多个重叠的正弦波提取频率和幅度信息。Accelerate 框架提供了另一个解决方案，叫做快速傅里叶变换 （FFT），关于这个方案[这里](http://jakevdp.github.io/blog/2013/08/28/understanding-the-fft/)有一个 (基于 IPython notebook 的) 很好的解释。

我们在例子 [AccelerateFunctions.playground](https://github.com/objcio/PersonalSwiftPlaygrounds) 中实现了这个原型，你可以对照这个例子来看下面的内容。请确认你已经打开 Assistant Editor (在菜单上依次点击 View | Assistant Editor | Show Assistant Editor) 以查看每一阶段所产生的图形。

首先我们要产生一些用于实验的示例波形。使用 Swift 的 `map()` 方法可以很容易地实现：


    let sineArraySize = 64

    let frequency1 = 4.0
    let phase1 = 0.0
    let amplitude1 = 2.0
    let sineWave = (0..<sineArraySize).map {
        amplitude1 * sin(2.0 * M_PI / Double(sineArraySize) * Double($0) * frequency1 + phase1)
    }

为了便于之后使用 FFT，我们的初始数组大小必须是 2 的幂次方。把 `sineArraySize` 值改为像 32，128 或 256 将改变之后显示的图像的密度，但它不会改变计算的基本结果。

要绘制我们的波形，我们将使用新的 XCPlayground 框架 (需要先导入) 和以下辅助函数：

    func plotArrayInPlayground<T>(arrayToPlot:Array<T>, title:String) {
        for currentValue in arrayToPlot {
            XCPCaptureValue(title, currentValue)
        }
    }

当我们执行：

    plotArrayInPlayground(sineWave, "Sine wave 1")

我们可以看到如下所示的图表：

<img src="/images/issues/issue-16/Sine1.png" style="width:563px"/>

这是一个频率为 4.0、振幅为 2.0、相位为 0 的正弦波。为了变得更有趣一些，我们创建了第二个正弦波，它的频率为 1.0、振幅为 1.0、相位为 π/2，然后把它叠加到第一个正弦波上：

    let frequency2 = 1.0
    let phase2 = M_PI / 2.0
    let amplitude2 = 1.0
    let sineWave2 = (0..<sineArraySize).map {
        amplitude2 * sin(2.0 * M_PI / Double(sineArraySize) * Double($0) * frequency2 + phase2)
    }

<img src="/images/issues/issue-16/Sine2.png" style="width:563px"/>

现在我们要将两个波叠加。从这里开始 Accelerate 将帮助我们完成工作。将两个个独立地浮点数数组相加非常适进行合并行处理。这里我们要使用到 Accelerate 的 vDSP 库，它正好有这类功能的方法。为了让这一切更有趣，我们将重载一个 Swift 操作符用于向量叠加。不巧的是 `+` 这个操作符已经用于数组连接 (其实挺容易混淆的)，而 `++` 更适合作为递增运算符，因此我们将定义 `+++` 作为相加的运算符。

    infix operator  +++ {}
    func +++ (a: [Double], b: [Double]) -> [Double] {
        assert(a.count == b.count, "Expected arrays of the same length, instead got arrays of two different lengths")

        var result = [Double](count:a.count, repeatedValue:0.0)
        vDSP_vaddD(a, 1, b, 1, &result, 1, UInt(a.count))
        return result
    }

上文定义了一个操作符，操作符能将两个 `Double` 类型的 Swift 数组中的元素依次合并为一个数组。在运算中创建了一个和输入的数组长度相等的空白数组（假设输入的两个数组长度相等）。由于 Swift 的一维数组可以直接映射成 C 语言的数组，因此我们只需要将作为参数的 `Doubles` 类型数组直接传递给 `vDSP_vaddD()` 方法，并在我们的数组结果前加前缀 `&`。

为了验证上述叠加是否被正确执行，我们可以使用 for 循环以及 Accelerate 方法来绘制合并后的正弦波的结果：

    var combinedSineWave = [Double](count:sineArraySize, repeatedValue:0.0)
    for currentIndex in 0..<sineArraySize {
        combinedSineWave[currentIndex] = sineWave[currentIndex] + sineWave2[currentIndex]
    }

    let combinedSineWave2 = sineWave +++ sineWave2

    plotArrayInPlayground(combinedSineWave, "Combined wave (loop addition)")
    plotArrayInPlayground(combinedSineWave2, "Combined wave (Accelerate)")

<img src="/images/issues/issue-16/SineCombined.png" style="width:563px"/>

果然，结果是一致的。

在继续 FFT 本身之前，我们需要另一个向量运算来处理计算的结果。Accelerate 的 FFT 实现中获取的所有结果都是平方之后的，所以我们需要对它们做平方根操作。我们需要对数组中的所有元素调用类似 `sqrt()` 方法，这听上去又是一个使用 Accelerate 的机会。

Accelerate 的 vecLib 库中有很多等价的数学方法，包括平方根的 `vvsqrt()`。这是个使用方法重载的好例子，让我们来创建一个新版本的 `sqrt()`，使其能处理 `Double` 类型的数组。

    func sqrt(x: [Double]) -> [Double] {
        var results = [Double](count:x.count, repeatedValue:0.0)
        vvsqrt(&results, x, [Int32(x.count)])
        return results
    }

和我们的叠加运算符一样，重载的平方函数输入一个 `Double` 数组，为输出创建了一个 `Double` 类型的数组，并将输入数组中的所有参数直接传递给 Accelerate 中的 `vvsqrt()`。通过在 playground 中输入以下代码，我们可以验证刚刚重载的方法。

    sqrt(4.0)
    sqrt([4.0, 3.0, 16.0])

我们能看到，标准 `sqrt()` 函数返回2.0，而我们的新建的重载方法返回了 [2.0, 1.73205080756888, 4.0]。这的确是一个非常易用的重载方法，你甚至可以想象照以上方法使用 vecLib 为所有的数学方法写一个并行的版本 (不过 Mattt Thompson [已经做了这件事](https://github.com/mattt/Surge))。在一台 15 寸的 2012 年中的 i7 版本 MacBook Pro 中处理一个有一亿个元素的数组，使用基于 Accelerate 的 `sqrt()` 方法的运行速度比迭代使用普通的一维 `sqrt()` 快将近一倍。

有了这个以后，我们来实现 FFT。我们并不打算在 FFT 设置的细节上花费大量时间，以下是我们的 FFT 方法：

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

第一步，我们设置了计算中需要使用到的 FFT 权重，它和我们要处理的数组大小相关。这些权重将在稍后实际的 FFT 计算中被使用到，它可以通过 `vDSP_create_fftsetupD()` 计算得到，并且对于给定大小的数组是可以重用的。因为在这里数组的大小是个恒定的常量，因此我们只需要计算一次权重，并将它作为全局变量并在每次 FFT 中重用即可。

在 FFT 方法中，我们初始化了一个用于存放操作结果的数组 `fftMagnitudes`，数组的初始元素都为 0，大小为之前正弦波的大小。FFT 运算的输入参数都是实部加上虚部的复数形式，但我们真正关心的只是它的实数部分，因此我们初始化 `splitComplexInput` 的时候使用输入数组作为实数部分，而将零作为虚数部分。然后 `vDSP_fft_zipD()` 和 `vDSP_zvmagsD()` 负责执行 FFT，并使用 `fftMagnitudes` 数组来存储 FFT 从  FFT 中得到的结果的平方数。

在这里，我们使用了之前提到的基于 Accelerate 的 `sqrt()` 方法来计算平方根，返回实际大小，然后基于输入数组的大小对值进行归一化。

对一个单一的正弦波，以上所有操作的的结果如下：

<img src="/images/issues/issue-16/FFT12.png" style="width:563px"/>

叠加的正弦波看起来像这样：

<img src="/images/issues/issue-16/FFTCombined.png" style="width:563px"/>

对这些值一个非常简单的解释是：这些结果表示了正弦波频率的集合，从左边开始，集合中的值表示了在该频率下检测到的波的振幅。它们关于中心对称，因此你可以忽略图中右半部分的值。

可以观察到对于频率为 4.0 振幅为 2.0 的波，在 FFT 中是一个 位于 4 对应于 2.0 的值。同样对于频率为 1.0 振幅为 1.0 的波，在 FFT 中是位于 1 对应值为 1.0 的点。尽管叠加后的正弦波得到的 FFT 波形比较复杂，但是依然能够清晰地区分合并的两个波在各自集合内的振幅和频率，就仿佛它们的 FFT 结果是分别被加入的一样。

再次强调，这是 FFT 运算的简化版本，在上文的 FFT 代码中有简化操作，但关键是在 playground 中通过一步步创建方法，我们能轻松地探索一个复杂的信号处理操作，并且每一步操作的测试都能立即得到图形反馈。

## 使用 Swift Playgrounds 快速创建原型的案例

我们希望这些例子能够说明 Swift playground 在实践新类库和新概念上的作用。

上一个例子中的每一步里，我们都能在执行时通过时间线中的图案来观察中间数组的状态。这对于一个示例程序来说作用非常大，而且也以某种方式为程序提供了界面。所有这些图像都实时更新，因此你能随时返回到实现中并修改其中一个波的频率或振幅，然后看着波形随着处理步骤变化。这缩短了开发周期，并且对计算过程的体验提供了巨大帮助。

这种立即反馈的交互式开发是为复杂的算法创建原型的很好的案例。在将这样的复杂算法部署到实际的应用之前，我们有机会在 playground 中对它进行验证和研究。

---

 

原文 [Rapid Prototyping in Swift Playgrounds](http://www.objc.io/issue-16/rapid-prototyping-in-swift-playgrounds.html)

