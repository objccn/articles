---
title:  "Functional Signal Processing Using Swift"
category: "24"
date: "2015-05-11 10:00:00"
tags: article
author: "<a href=\"https://twitter.com/liscio\">Chris Liscio</a>"
---

As a long-time Core Audio programmer, Apple's introduction of Swift left me both excited and confused. I was excited by the prospect of a modern language built with performance in mind, but I wasn't entirely sure how functional programming could apply to "my world." Fortunately for me, many have [explored and conquered][faust] this problem set already, so I decided to apply some of what I learned from those projects to the Swift programming language.

作为一个和Core Audio打过很长时间交道的工程师，苹果发布Swift让我感到兴奋又疑惑。一个为性能打造的现代编程语言让我感到兴奋，但是我又不是非常确定函数性变成可以应用到“我的世界”。
幸运的是很多人已经[探索和克服了][faust]这些问题，所以我决定将我从这些项目中学习到的东西应用到Swift编程语言中去。



Signals
-------

The basic unit of signal processing is, of course, a signal. In Swift, I would declare a signal as follows:

信号
------

信号处理的基本当然是信号。在Swift中，我将信号写成这个样子：


```swift
public typealias Signal = Int -> SampleType
```

You can think of the `Signal` type as a discrete function in time that returns the value of the signal at that instant in time. In most signal processing texts, this is often denoted as `x[t]`, so it fits my world view.

你可以把'Signal'类想象成一个时间函数，这个函数会返回一个时间点上的信号值。在大多数信号处理的教科书中，这个会被写做'x[t]', 这样一来它就很符合我的世界观了。

Let's define a sine wave at a given frequency:

现在我们来定义一个一定平率的正弦波：

```swift
public func sineWave(sampleRate: Int, frequency: ParameterType) -> Signal {
    let phi = frequency / ParameterType(sampleRate)
    return { i in
        return SampleType(sin(2.0 * ParameterType(i) * phi * ParameterType(M_PI)))
    }
}
```

The `sineWave` function returns a `Signal`, which itself is a function that converts sample indices into output samples. I refer to these "inputless" signals as generators, since they generate signals out of nothing.

'sineWave'函数会返回一个'Signal', 'Signal'本身是一个将式样指数转换为输出式样的函数。我将这些不需要“输入”的信号成为生成器，因为他们不需要任何其他的东西来创造信号。

But I thought we were talking about signal _processing_? How do we modify a signal?

但是我们正在讨论信号_处理_。那么如何更改一个信号呢？

No high-level discussion about signal processing would be complete without demonstrating the application of gain (or a volume control):

对信号处理的高层面讨论少了展示增益（或者音量控制）的应用都是不全面的。

```swift
public func scale(s: Signal, amplitude: ParameterType) -> Signal {
    return { i in
            return SampleType(s(i) * SampleType(amplitude))
    }
}
```

The `scale` function takes an input `Signal` called `s`, and returns a new `Signal` with the scalar applied. Every call to the `scale`d signal would return the same output of `s(i)`, scaled by the supplied `amplitude`. Pretty straightforward stuff, right? Well, you can only go so far with this construct before it starts to get messy. Consider the following:

`scale`函数接受一个输入`Signal`叫做`s`，然后返回一个应用了标量之后的新'Signal'。每一次调用改变比例之后的信号都会返回相同的's(i)'，使用的比例用'amplitude'来表示。挺容易的对吧？但是很快这些构件就会变得很混乱起来。来看看以下的例子：


```swift
public func mix(s1: Signal, s2: Signal) -> Signal {
    return { i in
        return s1(i) + s2(i)
    }
}
```

This allows us to compose two signals down to a single signal. We can even compose arbitrary signals:

这个让我们能够将两种信号混合成一个信号。我们甚至可以任意混合信号：

```swift
public func mix(signals: [Signal]) -> Signal {
    return { i in
        return signals.reduce(SampleType(0)) { $0 + $1(i) }
    }
}
```

This can get us pretty far; however, a `Signal` is limited to a single "channel" of audio, and certain audio effects require much more complex combinations of operations to happen at once.

这个可以让我们干很多事情；但是一个‘Signal'仅仅限于一个单一的声频频道，有些声频效果需要复杂的组合同时发生来做到。

Processing Blocks
-----------------

What if we were able to make connections between signals and processors in a more flexible way, matching up more closely with the way we think about signal processing? There are popular environments, such as [Max][max] and [PureData][pd], which compose signal processing "blocks" to create powerful sound effects and performance tools.

我们如何灵活地在信号和处理器之间建立联系来符合我们思考信号出来的方式？有很多流行的环境，比如说[Max][max]和[PureData][pd]，这些环境会建立信号处理"blocks"来创造强大的音效和表演工具。

[Faust][faust] is a functional programming language that was designed with this idea in mind, and it is an incredibly powerful tool for building highly complex (and performant!) signal processing code. Faust defines a set of operators that allows you to compose blocks (or processors) together in a way that mimics signal flow diagrams.

[Faust][faust]是一个为此设计出来的函数性编程语言，它是一个用来写高度复杂（而且高性能）的信号处理代码的强大工具。Faust定义了一系列运算符来让你建立blocks（处理器），这和信号的流动图像很相似。

Similarly, I have created an environment that effectively works the same way.

同样的，我建立了一个工作起来非常类似的环境。

Using our earlier definition of `Signal`, we can expand on this concept:

运用我们之前定义的'Signal'，我们可以扩展这个概念。

```swift
public protocol BlockType {
    typealias SignalType
    var inputCount: Int { get }
    var outputCount: Int { get }
    var process: [SignalType] -> [SignalType] { get }

    init(inputCount: Int, outputCount: Int, process: [SignalType] -> [SignalType])
}
```

A `Block` has a number of inputs, a number of outputs, and a `process` function that transforms the `Signal`s on its inputs to a set of `Signal`s on its outputs. Blocks can have zero or more inputs, and zero or more outputs.

一个`Block`有多个输入，多个输出，和一个`处理`函数。这个函数将信号从输入转换成输出。Blocks可以有多个的输入和多个的输出。

To compose blocks serially, you could do the following:

你可以用以下的方法来建立连续的blocks。

```swift
public func serial<B: BlockType>(lhs: B, rhs: B) -> B {
    return B(inputCount: lhs.inputCount, outputCount: rhs.outputCount, process: { inputs in
        return rhs.process(lhs.process(inputs))
    })
}
```

This function effectively takes the output of the `lhs` block as the input to the `rhs` block and returns the result. It's like connecting a wire between two blocks. Things get a little more interesting when you run blocks in parallel:

这个函数将`lhs`block的输出当做'rhs'block的输入然后返回一个结果。就好像在两个blocks中间连起一根线一样。当你平行地执行多个blocks的时候事情就变得有意思起来。

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

A pair of blocks running in parallel combines inputs and outputs to create a larger block. Consider a pair of `Block`s that produces sine waves together to create a [DTMF tone][dtmf], or a stereo delay `Block` that is a composition of two single-channel delay `Block`s. This concept can be quite powerful in practice.

一组平行运行的blocks结合输入和输出可以创在一个更大的block。比如一对产生Blocks的正弦波一起可以创造一个[DTMF tone][dtmf]，或者两个频道延迟Blocks可以组成一个立体延迟Block。这个概念在实践中是非常强大的。

But what about a mixer? How would we achieve a single-channel result from multiple inputs? We can merge blocks together using the following function:

那么混合器呢？我们如何从多输入建立一个单频道的结果？我们可以用如下函数来将多个blocks融合在一起。

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

To borrow convention from Faust, inputs are multiplexed such that the inputs of the right-hand side block come from outputs on the left-hand side modulo the number of inputs. For instance, three stereo tracks with a total of six channels would go into a stereo output block such that output channels 0, 2, and 4 are mixed (i.e. added) into input channel 0, and 1, 3, and 5 are mixed into input channel 1.

从Faust借用一个惯例，输入的混合是这样做到的：右手边的block来源于左手边的block的输出mod输入的数量。比如说，总共有六个频道的三个立体声轨会变成一个立体输出block：输出频道0，2，4被混合（比如加入）进输入频道0，并且输出频道1，3，5会被混合进输入频道1。

Similarly, you can do the opposite and split the outputs of a block:
同样的，你可以用相反的方法将block的输出分开。

```swift
public func split<B: BlockType>(lhs: B, rhs: B) -> B {
    return B(inputCount: lhs.inputCount, outputCount: rhs.outputCount, process: { inputs in
        let leftOutputs = lhs.process(inputs)
        var rightInputs: [B.SignalType] = []

        // Replicate the channels from the lhs to each of the inputs
        let k = lhs.outputCount
        for i in 0..<rhs.inputCount {
            rightInputs.append(leftOutputs[i%k])
        }

        return rhs.process(rightInputs)
    })
}
```

Again, a similar convention is used with the outputs such that one stereo block being fed into three stereo blocks (accepting six total channels) would result in channel 0 going into the inputs 0, 2, and 4, with channel 1 going into inputs 1, 3, and 5.

一个相似的惯例是用一个立体block作为3个立体blocks的输入（接受总共6个频道），这样一来频道0会去到输入0,2,4而频道1会去到输入1,3,5。

Of course, we don't want to get stuck with having to write all of this with long-hand functions, so I came up with this collection of operators:

我们当然不想被这些很长的函数束缚住手脚，所以我写了这些运算符。

```swift
// Parallel
public func |-<B: BlockType>(lhs: B, rhs: B) -> B

// Serial
public func --<B: BlockType>(lhs: B, rhs: B) -> B

// Split
public func -<<B: BlockType>(lhs: B, rhs: B) -> B

// Merge
public func >-<B: BlockType where B.SignalType == Signal>(lhs: B, rhs: B) -> B
```

(I'm not quite happy with the "Parallel" operator definition, as it looks an awful lot like the symbol for "Perpendicular" in geometry, but I digress. Feedback is obviously welcome.)

（我觉得“Parallel”运算符的定义并不是特别好，因为它看上去和几何中的"Perpendicular"尤其相似，但是现在就这样，非常欢迎大家的意见）


Now, with these operators, you can build some interesting "graphs" of blocks and compose them together. For instance, consider this [DTMF tone][dtmf] generator:

现在有了这些运算符，你可以建立一些有趣的blocks“图像”。比如说[DTMF tone][dtmf]


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

The `dtmfTone` function runs two parallel sine generators and merges them into an "identity block," which just copies its input to its output. Remember, the return value of this function is itself a block, so you could now reference this block as part of a larger system.

`dtmfTone`函数用两个平行的正弦生成器然后将它们融合成一个"identity block"。"identity block"会将自己的输入复制到输出。记住这个函数的返回值本身就是一个block, 所以你可以在更大的系统中使用这个block。


As you can see, there is a lot of potential in this idea. By creating an environment in which we can build and describe increasingly complex systems with a more compact and understandable DSL (domain specific language), we can spend less time worrying about the details of each individual block and how everything fits together.

可以看得出来这个想法蕴含了很多的潜力。通过更紧凑和容易理解的DSL(domain specific language)来建立和描述越来越复杂的系统，这样的环境使得我们能够花更少的时间来思考单个block的细节以及如何把所有东西组合到一起。

Practicality
------------

If I were starting a project today that required the best possible performance and most rich set of functionality, I would run straight to [Faust][faust] to get going. I highly recommend that you spend some time with Faust if you are interested in pursuing this idea of functional audio programming.

如果我今天要开始做一个要求最高性能以及丰富功能的新项目，我会毫不犹豫的使用[Faust][faust]。如果你对函数性声频编程很感兴趣的话我极力推荐Faust。

With that said, the practicality of my ideas above rests heavily on Apple's ability to advance its compiler such that it can identify patterns in the blocks we define and turn them into smarter output code. Effectively, Apple needs to get Swift compiling more like Haskell does, where functional programming patterns can be collapsed down into vectorized operations on a given target CPU.

话虽如此，我一上提到想法的可行性很大程度上取决于苹果提升编译器来识别我们定义在block中的套路并输出更智能的代码的能力。也就是说，苹果需要像Haskell编译一样来编译Swift。在Haskell中函数性编程的套路会被压缩成某一个目标CPU的矢量化运算。

Frankly, I feel that Swift is in the right hands at Apple and we will see the powerful kinds of ideas I presented above become commonplace and performant in the future.

说实话，我觉得Swift在苹果的管理下是很好的，我们也会在将来看见我在以上呈现的想法会变得很常见，而且性能也会变得非常好。

Future Work
-----------

未来
-----------

I will keep this ["Functional DSP" project](http://github.com/liscio/FunctionalDSP) up at GitHub if you would like to follow along or contribute ideas as I play around with the concepts. I plan to investigate more complex blocks, such as those that require FFTs to calculate their output, or blocks that require "memory" in order to operate (such as FIR filters, etc.)

我会将这个["Functional DSP"项目](http://github.com/liscio/FunctionalDSP) 保留在Github上面。你可以跟踪进展并且做出贡献。我计划去研究更加复杂的blocks，比如说需要FFTs来计算输出的，或者需要"memory"来运行的（比方说FIR滤镜等等）

Bibliography
------------

While writing this article, I stumbled upon the following papers that I recommend you delve further into if you are interested in this area of research. There are many more out there, but in the limited time I had, these seemed like really good starting points.

书目
------------
在写这篇文章的过程当中，我研究过这个论文。如果你对科研领域有兴趣的话我建议阅读它们。因为我时间有限，尽管还有很多好的资源，但是这些是非常好的初始点。

* Thielemann, H. (2004). Audio Processing using Haskell.
* Cheng, E., & Hudak, P. (2009). Audio Processing and Sound Synthesis in Haskell.


[faust]: http://sourceforge.net/projects/faudiostream/
[max]: https://cycling74.com/products/max/
[pd]: http://puredata.info
[dtmf]: http://en.wikipedia.org/wiki/Dual-tone_multi-frequency_signaling
