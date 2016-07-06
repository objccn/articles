作为一个和 Core Audio 打过很长时间交道的工程师，苹果发布 Swift 让我感到兴奋又疑惑。兴奋是因为 Swift 是一个为性能打造的现代编程语言，但是我又不是非常确定函数式编程是否可以应用到 “我的世界”。幸运的是，很多人已经[探索和克服了][faust]这些问题，所以我决定将我从这些项目中学习到的东西应用到 Swift 编程语言中去。

## 信号

信号处理的基本当然是信号。在 Swift 中，我可以这样定义信号：

```swift
public typealias Signal = Int -> SampleType
```

你可以把 `Signal` 类想象成一个离散时间函数，这个函数会返回一个时间点上的信号值。在大多数信号处理的教科书中，这个会被写做 `x[t]`, 这样一来它就很符合我的世界观了。

现在我们来定义一个给定频率的正弦波：

```swift
public func sineWave(sampleRate: Int, frequency: ParameterType) -> Signal {
    let phi = frequency / ParameterType(sampleRate)
    return { i in
        return SampleType(sin(2.0 * ParameterType(i) * phi * ParameterType(M_PI)))
    }
}
```

`sineWave` 函数会返回一个 `Signal`，`Signal` 本身是一个将采样点的索引映射为输出样点的函数。我将这些不需要“输入”的信号称为信号发生器，因为它们不需要任何其他的东西就能创造信号。

但是我们正在讨论信号**处理**。那么如何更改一个信号呢？

任何关于信号处理的高层面的讨论，都不可能离开一个基础，那就是如何控制增益 (或者音量)：

```swift
public func scale(s: Signal, amplitude: ParameterType) -> Signal {
    return { i in
            return SampleType(s(i) * SampleType(amplitude))
    }
}
```

`scale` 函数接受一个名为 `s` 的 `Signal` 作为输入，然后返回一个施加了标量之后的新 `Signal`。每次调用这个经过 `scale` 后的信号，返回的值都是对应的 `s(i)` 然后通过所提供的 `amplitude` 进行加成，来作为输出。很容易对吧？但是很快这些构件就会变得混乱起来。来看看以下的例子：


```swift
public func mix(s1: Signal, s2: Signal) -> Signal {
    return { i in
        return s1(i) + s2(i)
    }
}
```

这让我们能够将两个信号混合成一个信号。我们甚至可以混合任意多个信号：

```swift
public func mix(signals: [Signal]) -> Signal {
    return { i in
        return signals.reduce(SampleType(0)) { $0 + $1(i) }
    }
}
```

这可以让我们干很多事情；但是一个 `Signal` 仅仅限于一个单一的音频频道，有些音效需要复杂的操作的组合同时发生才能做到。

## 处理 Block

我们如何才能以更灵活的方式在信号和处理器之间建立联系，来让信号处理更接近于我们所想呢？有很多流行的环境，比如说 [Max][max] 和 [PureData][pd]，这些环境会建立信号处理的 “blocks”，并以此来创造强大的音效和演奏工具。

[Faust][faust] 是一个为此设计出来的函数式编程语言，它是一个用来编写高度复杂 (而且高性能) 的信号处理代码的强大工具。Faust 定义了一系列运算符来让你建立 blocks (处理器)，这和信号流图像很相似。

类似地，我用同样的方式建立了一个可以高效工作的环境。

使用我们之前定义的 `Signal`，我们可以基于这个概念进行扩展。

```swift
public protocol BlockType {
    typealias SignalType
    var inputCount: Int { get }
    var outputCount: Int { get }
    var process: [SignalType] -> [SignalType] { get }

    init(inputCount: Int, outputCount: Int, process: [SignalType] -> [SignalType])
}
```

一个 `Block` 有多个输入，多个输出，和一个 `process` 函数，这个函数将信号从输入集合转换成输出集合。Blocks 可以有零个或多个输入，也可以有零个或多个输出。

你可以用以下的方法来建立串行的 blocks。

```swift
public func serial<B: BlockType>(lhs: B, rhs: B) -> B {
    return B(inputCount: lhs.inputCount, outputCount: rhs.outputCount, process: { inputs in
        return rhs.process(lhs.process(inputs))
    })
}
```

这个函数将 `lhs` block 的输出当做 `rhs` block 的输入，然后返回结果。就好像在两个 blocks 中间连起一根线一样。当你想要并行地执行多个 blocks 的时候，事情就变得有意思起来：

```swift
public func parallel<B: BlockType>(lhs: B, rhs: B) -> B {
    let totalInputs = lhs.inputCount + rhs.inputCount
    let totalOutputs = lhs.outputCount + rhs.outputCount

    return B(inputCount: totalInputs, outputCount: totalOutputs, process: { inputs in
        var outputs: [B.SignalType] = []

        outputs += lhs.process(Array(inputs[0..<lhs.inputCount]))
        outputs += rhs.process(Array(inputs[lhs.inputCount..<lhs.inputCount+rhs.inputCount]))

        return outputs
    })
}
```

一组并行运行的 blocks 将输入和输出结合在一起，并创建了一个更大的 block。比如一对产生的正弦波的 `Block` 组合在一起可以创建一个 [DTMF 音调][dtmf]，或者两个单频延迟的 `Block` 可以组成一个立体延迟 `Block` 等。这个概念在实践中是非常强大的。

那么混合器呢？我们如何从多个输入得到一个单频道的结果？我们可以用如下函数来将多个 block 合并在一起：

```swift
public func merge<B: BlockType where B.SignalType == Signal>(lhs: B, rhs: B) -> B {
    return B(inputCount: lhs.inputCount, outputCount: rhs.outputCount, process: { inputs in
        let leftOutputs = lhs.process(inputs)
        var rightInputs: [B.SignalType] = []

        let k = lhs.outputCount / rhs.inputCount
        for i in 0..<rhs.inputCount  {
            var inputsToSum: [B.SignalType] = []
            for j in 0..<k {
                inputsToSum.append(leftOutputs[i+(rhs.inputCount*j)])
            }
            let summed = inputsToSum.reduce(NullSignal) { mix($0, $1) }
            rightInputs.append(summed)
        }

        return rhs.process(rightInputs)
    })
}
```

从 Faust 借用一个惯例，输入的混合是这样进行的：右手边 block 的输入来自于左手边对输入取模后的输出。举个例子，将六个频道的三个立体声轨变成一个立体输出的 block：输出频道 0，2，4 被混合 (比如相加) 进输入频道 0，然后输出频道 1，3，5 会被混合进输入频道 1。

同样的，你可以用相反的方法将 block 的输出分开。

```swift
public func split<B: BlockType>(lhs: B, rhs: B) -> B {
    return B(inputCount: lhs.inputCount, outputCount: rhs.outputCount, process: { inputs in
        let leftOutputs = lhs.process(inputs)
        var rightInputs: [B.SignalType] = []

        // 从 lhs 将频道逐个复制输入中
        let k = lhs.outputCount
        for i in 0..<rhs.inputCount {
            rightInputs.append(leftOutputs[i%k])
        }

        return rhs.process(rightInputs)
    })
}
```

对于输出我们也使用一个类似的惯例，一个立体声 block 作为三个立体声 block 的输入 (总共接受六个声道)，也就是说，频道 0 作为输入 0，2，4，而频道 1 作为 1，3，5 的输入。

我们当然不想被这些很长的函数束缚住手脚，所以我写了这些运算符：

```swift
// 并行
public func |-<B: BlockType>(lhs: B, rhs: B) -> B

// 串行
public func --<B: BlockType>(lhs: B, rhs: B) -> B

// 分割
public func -<<B: BlockType>(lhs: B, rhs: B) -> B

// 合并
public func >-<B: BlockType where B.SignalType == Signal>(lhs: B, rhs: B) -> B
```

(我觉得“并行”运算符的定义并不是特别好，因为它看上去和几何中的“垂直”尤其相似，但是现在就这样，非常欢迎大家的意见)

现在有了这些运算符，你可以建立一些有趣的 blocks “图”。比如说 [DTMF 音调][dtmf]发生器：


```swift
let dtmfFrequencies = [
    ( 941.0, 1336.0 ),

    ( 697.0, 1209.0 ),
    ( 697.0, 1336.0 ),
    ( 697.0, 1477.0 ),

    ( 770.0, 1209.0 ),
    ( 770.0, 1336.0 ),
    ( 770.0, 1477.0 ),

    ( 852.0, 1209.0 ),
    ( 852.0, 1336.0 ),
    ( 852.0, 1477.0 ),
]

func dtmfTone(digit: Int, sampleRate: Int) -> Block {
    assert( digit < dtmfFrequencies.count )
    let (f1, f2) = dtmfFrequencies[digit]

    let f1Block = Block(inputCount: 0, outputCount: 1, process: { _ in [sineWave(sampleRate, f1)] })
    let f2Block = Block(inputCount: 0, outputCount: 1, process: { _ in [sineWave(sampleRate, f2)] })

    return ( f1Block |- f2Block ) >- Block(inputCount: 1, outputCount: 1, process: { return $0 })
}
```

`dtmfTone` 函数处理两个并行的正弦发生器，然后将它们融合成一个 “单位元 block”，这个 block 只是将自己的输入复制到输出。记住这个函数的返回值本身就是一个 block，所以你可以在更大的系统中使用这个block。

可以看得出来这个想法蕴含了很多的潜力。通过创建可以使用更紧凑和容易理解的 DSL (domain specific language) 来描述复杂系统的环境，我们可以花更少的时间来思考单个 block 的细节，并轻易地把所有东西组合到一起。

## 实践

如果我今天要开始做一个要求最高性能以及丰富功能的新项目，我会毫不犹豫的使用 [Faust][faust]。如果你对函数式音频编程感兴趣的话，我极力推荐 Faust。

话虽如此，我一上提到想法的可行性很大程度上依赖于苹果对编译器的改进，编译器需要具有能识别我们定义在 block 中的模式，并输出更智能的代码的能力。也就是说，苹果需要像编译 Haskell 一样来编译 Swift。在 Haskell 中函数式编程模式会被压缩成某一个目标 CPU 的矢量运算。

说实话，我觉得 Swift 在苹果的管理下是很好的，我们也会在将来看见我在以上呈现的想法会变得很常见，而且性能也会变得非常好。

## 未来

我会将这个[“函数式 DPS”项目](http://github.com/liscio/FunctionalDSP) 保留在 GitHub 上面。你可以跟踪进展并且做出贡献。我计划去研究更加复杂的 block，比如说那些需要 FFT 来计算输出，或者需要 “存储” 来运行 (比方说 FIR 滤镜等等) 的block。

## 参考文献

在写这篇文章的过程当中，我研究过下列论文。如果你对这方面研究有兴趣的话我建议阅读它们。尽管还有很多好的资源，但因为我时间有限所以不能一一列举，但是这些会是非常好的起点。

* Thielemann, H. (2004). Audio Processing using Haskell.
* Cheng, E., & Hudak, P. (2009). Audio Processing and Sound Synthesis in Haskell.

[faust]: http://sourceforge.net/projects/faudiostream/
[max]: https://cycling74.com/products/max/
[pd]: http://puredata.info
[dtmf]: http://zh.wikipedia.org/wiki/双音多频

---


 

原文 [Functional Signal Processing Using Swift](http://www.objc.io/issue-24/functional-signal-processing.html)
