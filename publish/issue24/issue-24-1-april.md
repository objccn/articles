<style type="text/css">
.controls {
    text-align: center;
  font-size: 0.8em;
}

.svgWithText {
    font-size: 0.7em;

    user-select: none;
    -moz-user-select: none;
  -webkit-user-select: none;
}

.axis {}

.axis path,
.axis line {
         fill: none;
    stroke: #333333;
    shape-rendering: crispEdges;
}
.gridAxis path,
.gridAxis line {
         fill: none;
    stroke: #dddddd;
    stroke-width: 1;
    shape-rendering: crispEdges;
}

.buttonholder {
    padding: 10px;
}


.buttonholder button {
  margin-left: 5px;
  margin-top: 5px;
  cursor: pointer;
  padding: 5px 10px;
  border-radius: 5px;
  border: solid 1px #ccc;
  color: #333;
  background: #fff;
  bottom: 20px;
  left: 20px;
  font-size: 0.8em;
}

.buttonholder button:hover {
  border-color: #777;
  color: #000;
}

.buttonholder button:focus {
  outline: none;
}
</style>

<script type="text/javascript" src="/assets/js/issue-24/d3.min.js">

</script>

我不知道这种观念是不是普遍的，但在北美，一个年轻而有抱负的木匠典型的项目是建立一个狗屋；当孩子对建筑变得好奇，想要反复折腾锤子，水平尺，锯子时，他们的父母会指导他们做一个狗屋。在很多方面，狗屋对热情的新手来说是理想的项目。项目大小足以鼓舞人心，但也足够简单以避免孩子恰好搞砸了或中途就失去兴趣造成惨败的结果。狗屋作为一个入门项目是很有吸引力的，因为它是一个微型“全集”。它需要设计，规划，工程和手工制造。很容易知道什么时候该项目已经完成。当汪星人可以整夜整夜待在狗屋而没有变冷或变湿，那这个项目就是成功的。

<img src="/images/issues/issue-24/pic1.png"></img>

我敢肯定，最认真，最好奇的开发者 - 那些用他们晚上和周末的宝贵时间来阅读一些像 objccn.io 这样期刊的人 - 常常会发现他们在一个缺乏激发灵感的或有意义的实在的应用程序项目的情况下，去试图评估一些工具和了解一些新的难懂的概念。如果你像我一样，你可能已经经历了完成 “Hello World!” 教程时的那种特殊的恐惧感。在经历了愉快地配置编辑器和设置项目的潇洒阶段后，你会意识到你对你真正想要用你的新工具**做**什么这件事一无所知，这让你会跌到沮丧的谷底。以前那种学习 Haskell，Swift，或 C++ 的不屈不挠的精神在没有一个强制的项目的激励下变的可有可无。

在这篇文章中，我想提出一个音频信号处理的“狗屋”项目。我假设 (基于 objccn.io 的优良记录) 在这个专题里的其他文章将会满足你对 Xcode 和 Core Audio 配置相关的问题的技术需求。在 objccn.io 的这个专题里，我把我自己定位成一个与平台无关的促动者，一个基础信号处理理论的传播者。如果你对数字音频处理有强烈的兴趣，但不知道从何开始，那么，继续阅读吧。

## 开始之前

今年早些时候，我撰写了 30 篇有关基本的信号处理的互动文章。你可以在[这儿](https://jackschaedler.github.io/circles-sines-signals/index.html)找到。我建议你在阅读这篇文章之前再看一遍。如果你在数字信号处理方面的背景有限，这将有助于消除一些基本的术语和概念给你带来的困惑。如果你对像 “样本”，“混叠” 或 “频率” 这样的术语感到陌生，那没有任何问题，这篇文章将帮助你很快的了解基础知识。

## 项目

作为学习音频信号处理的入门项目，我建议你**编写一个可以在音乐演奏中实时跟踪一个「单音」的音高的应用程序**。

在游戏 “Rock Band” 中，肯定有一个用于分析和评估歌手声音表现的算法。该算法必须从麦克风设备中得到数据并自动的计算歌手实时的歌唱频率。假设你身边有一个丰满的歌剧演唱者，我们希望该项目最终将看起来像是这样的：

<img src="/images/issues/issue-24/pic2.png"></img>

> 单音音高跟踪在你的信号处理工具集里是一种有用的技术。它是很多产品的核心，比如像 [Auto-Tune](http://en.wikipedia.org/wiki/Auto-Tune) 这样的应用，“Rock Band” 这样的游戏，吉他和乐器调音器，音乐转录程序，音频到 MIDI 的转换软件，或者哼歌识曲的应用程序等。

我刚才把单音这个词用重点标注出来是因为它是一个重要的词语。如果在任何给定的时间内只有一个音符被演奏，那么音乐表演就是**单音**的。单谱线演奏是单音。和弦或者和声则**不是**单音的，而是**多音**的。如果你在唱歌，或是吹着小号，吹着哨笛，或敲击着 Minimoog (一种单音模拟合成器)，那么你在表演一个单音的音乐作品。这些乐器不允许同时发出两个或两个以上的音符。而如果你是在弹钢琴或吉他，那么你很可能在生成一个和弦音频信号，除非你辛苦地确保在任何给定的时间内只有一根琴弦响起。

我们将在本文中讨论的音高检测技术只适用于**单音**的音频信号。如果你对多声道的音高检测话题有兴趣，跳到**资源**部分，在那儿我加了一些相关文献的链接。一般来说，单音的音高检测被认为是一个已经有解决办法的问题。而多音的音高检测仍然是一个活跃的研究领域。

> 每年，最好的音频信号处理研究人员都会把自己的算法拿出来在 [MIREX](http://www.music-ir.org/mirex/wiki/MIREX_HOME) (音乐信息检索评价交换) 竞赛上一决雌雄。来自世界各地的研究人员将他们旨在自动录制、标记、分段、分类记录音乐表演的算法提交上来。如果你看完这篇文章后开始着迷音频信号处理的话题，你可能也会想要提交你的算法到 2015 年 MIREX “K-POP 情绪分类” 比赛中去。如果你对翻唱乐队更感兴趣，你可以选择把能从翻唱乐队的录音中识别原唱的的算法提交到 “音频翻唱歌曲识别” 的竞赛去 (这比你想象的更加困难)。

在这篇文章中我不会给你提供代码片段。相反，我会给你介绍一些音高检测的理论，这应该可以让你开始尝试编写和实验自己的音高检测算法。这会比你想象中更快的得到一些令人信服的结果！只要你的应用能从麦克风或线路中获取到音频缓冲区里的数据，你应该马上就可以开始摆弄本文介绍的算法和技术了。

在下一节中，我将介绍波的**频率**的概念并开始深入研究音高检测的问题。

## 声音，信号和频率

<img src="/images/issues/issue-24/pic3.png"></img>

乐器通过快速振动产生声音。当一个物体振动的时候，它会生成一个 [纵向压力波](http://jackschaedler.github.io/circles-sines-signals/sound.html)，并辐射到周围的空气中。当这种压力波到达你的耳朵，你的听觉系统会把波动压力解释成声音。规律振动并周期性生成声音的物体，我们称之为音调或音符。非规则或以随机方式振动的物体产生无调或噪音。最简单的音调是正弦波。

<table width="630">
    <tr>
        <td>
        <svg id="sinecycle" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/assets/js/issue-24/sine_cycle.js">
        </script>
    </td>
    </tr>
</table>

这是数字可视化的抽象正弦声波。纵轴是波的振幅 (空气压力的强度)，横轴表示时间维度。这种可视化图通常被称为**波形图**，它让我们了解随着时间的推移波的幅度和频率是如何变化的。该波形越高，声音越大。波峰和波谷越紧凑，频率越高。

任何波的频率都是用**赫兹**衡量的。一赫兹被定义为每秒的一个**循环**。一个**循环**是波形的最小重复部分。如果我们知道横轴的宽度相当于一秒的持续时间，我们就可以通过简单地用可见的波周期的数量来计算该波频率的赫兹。

<table width="630">
<tr>
    <td>
    <svg id="sinecycle2" class="svgWithText" width="600" height="100"></svg>
    <script type="text/javascript" src="/assets/js/issue-24/sine_cycle2.js">
    </script>
        </td>
</tr>
</table>

在上图中，我用一个透明的框标出了正弦波的一个循环。当我们数一下该波在一秒内完成的循环数，就可以很清楚的知道，波的频率恰好是 4 赫兹，或每秒 4 个循环。下面的波每秒完成 8 个循环，因此，它具有 8 赫兹的频率。 

<table width="630">
    <tr>
        <td>
        <svg id="sinecycle3" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/assets/js/issue-24/sine_cycle3.js">
        </script>
            </td>
    </tr>
</table>

在进一步的讨论之前，我们需要对两个到现在为止一直在互换使用的术语做一些澄清。 **音高**是与人类声音感知相关的听觉概念，而**频率**是一个波形的物理的，可测量的属性。由于一个信号的音高与它的频率密切相关，我们常把两个概念联系到一起。对于简单的正弦来说，音高和频率差不多是等价的。对于更复杂的波形而言，音高对应的是波的**基本频率** (或简称基频，之后会进行更多的阐述)。将两个概念混为一谈可能会让你陷入困境。例如，给定两个具有相同的基频的声音，人类通常会认为音量较大的声音具有更高的音高。对于本文的其余部分，我会不加区分地交替使用这两个词。如果你对这个话题感兴趣，请到[这里](http://en.wikipedia.org/wiki/Pitch_%28music%29)继续你的课外学习。

## 音高检测

简单地说，音高检测的算法就是自动计算出任意波形的频率。从本质上说，这一切都归结为能够准确的识别给定波形的一个单一循环。这对人类来说是一个非常简单的任务，但对机器来说则是艰巨的。CAPTCHA 验证码机制正是因为难以写出一套算法来准确地识别任意样本数据的结构和模式，才能精确地工作。我自己用我的眼球来挑选出重复图案的波形并没有什么问题，而且我敢肯定，你也一样。关键是要搞清楚我们如何编程使得计算机也能迅速、实时、高效地做同样的事情。

> 我不知道这样的事情是否已经被尝试过了，但我认为将计算机视觉的技术运用到音高检测和自动谱曲的问题上的话，会是件非常有趣的事情。

## 零点交叉法

作为一个频率检测算法的出发点，我们可能会发现，任何正弦波都将在每个循环内两次穿越横轴。如果我们计算在给定时间段通过零点的次数，然后除以 2，我们就**应该**能够很容易的计算出波形中存在的循环数。例如，在下面的图中，在一秒的时间内可以数到八个零点交叉。这意味着，波里存在有四个周期，因此，我们可以推断，该信号的频率为 4 赫兹。

<table width="630">
    <tr>
        <td>
        <svg id="zerocrossings" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/assets/js/issue-24/zerocrossings.js">
        </script>
            </td>
    </tr>
</table>

我们可能会开始注意到这种方法的一些问题，所分析的信号周期数可能会有小数点存在。例如，如果波形的频率稍微增加，一秒的持续时间内将有 9 个过零点。这将导致我们错误地推断出紫色波的频率为 4.5 赫兹，但它其实是**4.6**赫兹。

<table width="630">
<tr>
    <td>
    <svg id="zerocrossings2" class="svgWithText" width="600" height="100"></svg>
    <script type="text/javascript" src="/assets/js/issue-24/zerocrossings2.js">
    </script>
        </td>
</tr>
</table>

我们可以通过调整我们的分析窗口的大小，进行一些巧妙的平均，或启发式地记住在前面的窗口通过零点的位置以预测未来零点交叉点的位置来缓解这个问题。我建议你多尝试去改进一下最初的计数方法，直到你感觉可以开始对音频样本缓冲区进行工作。如果你需要一些测试音频导入到你的 iOS 设备，你可以在[这个页面的底部](http://jackschaedler.github.io/circles-sines-signals/sound.html)找到一个正弦波发生器。

虽然零点交叉法对非常简单的信号可能是可行的，但它对复杂的信号进行分析时会以令人痛苦的方式失败。用下面表示出的信号来举个例子，这个波形仍然是每 0.25 秒完成一个循环，但每个循环通过零点的数目比我们看到的正弦波高得多。这个信号在每个周期产生了六个过零点，尽管该信号的基频仍为 4 赫兹。

<table width="630">
    <tr>
        <td>
        <svg id="zerocrossingscomplex" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/assets/js/issue-24/zerocrossingscomplex.js">
        </script>
            </td>
    </tr>
</table>

虽然零点交叉法作为一个超精密音高追踪算法并不是很理想，但把它用来作为一个快速和粗略的方式来大致测量信号内的噪声量还是有效的。零点交叉法在这里适用的原因是噪声信号会比更清洁和更单调的音调在每个单位时间产生更多的过零点。零点交叉的计数通常用在语音识别软件中，来区别语音和非语音片段。粗略地说，语音中通常包括元音，而非语音是由辅音产生的。然而，一些辅音，例如英文中的的 “Z” 是浊音 (试试说：“zeeeeee”)。

在我们介绍一个更强大的方式来检测音高之前，我们首先必须了解**基频**这个我在前面章节不停谈论的术语是什么意思。

## 基频

最自然的声音和波形**并不是**纯正弦波，而是多个正弦波的混合。虽然[傅立叶理论](http://jackschaedler.github.io/circles-sines-signals/dft_introduction.html)超出了本文的范围，但你必须接受的一个事实是，物理的声音是许多正弦波的总和 (至少是通过这样的总和来建模的)，并且每个正弦都可能有不同的频率和幅度。当这类混合的波形传入我们的算法时，它必须确定哪个正弦充当着**基音**或基本声音的组成部分，并计算出**那个**波的频率。

我喜欢把声音看做由旋转的圆圈组成。一个正弦波可以通过一个旋转的圆圈来描述，更复杂的波形可以由组合另外一些旋转圆圈的组合生成。试试点击下面的四个按钮来控制可视化图像，看看使用许多单独的正弦波的组合如何形成各种不同的波形。

> 我真的很不理解为什么青年学生们的早期教育都没有被展示过圆周运动和三角函数之间对应的优美关系。我认为大多数的学生第一次遇到正弦和余弦是在直角三角形里，这对更优美和和谐地去思考这些函数来说是一个约束。

<div id="phasorbuttons" class="buttonholder" style="margin-left: 200px; margin-bottom: 10px;">
</div>
<svg id="phasorSum2" class="svgWithText" width="600" height="300" style="margin-left: 10px"></svg>
<script type="text/javascript" src="/assets/js/issue-24/inverse_fourier_transform.js">
</script>

图中心的蓝色旋转圆圈代表了**基音**，额外的轨道圈描述基音的**泛音**。要注意的是，蓝圈的一次旋转精确对应了一个循环所生成的波形。换句话说，基音每旋转一圈产生一个单一循环中的波形。

> 你可能会想，如果添加额外的音调，从根本上使产生的声音变成和弦。在引言部分，我大费周章地把和弦信号从合法输入中排除掉，而现在我又让你考虑由许多单个的音调组成的波形。但事实证明，几乎每一个音符都由一个基音和[泛音](http://en.wikipedia.org/wiki/Overtone)组成。和弦只发生在有**多个基本**频率出现在一个声音信号的时候。如果你想了解更多，我在[这儿](http://jackschaedler.github.io/circles-sines-signals/sound2.html)写了一些关于这个话题文章。

我再次把每个波形的一个周期用灰色框标注了出来，这会让你进一步发现所有四个波形的基本频率是相同的。每个都具有 4 赫兹的基频。尽管在正方形，锯齿和摆动波形中存在多个正弦，但这四个波形的基频始终和蓝色正弦保持一致。蓝色部件成了信号的基础。

同样需要非常注意的是，基频并不必是信号的最大或最响亮的组件。如果你再看看“摆动 (wobble)”波形，你会发现第二泛音 (橙色圆圈) 实际上是这个信号最大组成部分。尽管有这个相当有优势的泛音，但基频仍保持不变。

> 实际上经常有给定音符的基频比其泛音更小声的情况。事实上，人类能够感知的基频甚至根本就不存在。这种奇怪的现象被称为[“消失的基频”](http://zh.wikipedia.org/wiki/消失的基頻)问题。

在下一节中，我们将重温一些大学数学，然后探讨另一种基频测量的方法，它应该有能力处理这些讨厌的复合波形。

## 点积和相关性

**点积**很可能是在音频信号处理中最常执行的操作了。两个信号的点积很容易在伪代码中使用一个简单的**for**循环来定义。假定两个信号 (阵列) 有相等的长度，它们的点积可表示为如下：

```swift
func dotProduct(signalA: [Float], signalB: [Float]) -> [Float] {
    return map(zip(signalA, signalB), *)
}
```

隐藏在这个相当简单的代码段里的是一个非常重要的知识点。点积可被用来计算两个信号之间的相似度或**相关度**。如果两个信号的点积解析为一个大的值，就知道这两个信号是正相关的。如果两个信号的点积是零，就知道这两个信号去相关的 - 它们不相似。一如往常，一图胜千言，我希望你可以花一些时间研究下面的图。

<svg id="sigCorrelationInteractive" class="svgWithText" width="600" height="380" style="margin-left: 10px; margin-top: 10px"></svg>
<script type="text/javascript" src="/assets/js/issue-24/square_correlation.js">
</script>

<script>
    var SQUARE_CORRELATION_OFFSET = 0.0;
    function updateSquareCorrelationOffset(value) {
        SQUARE_CORRELATION_OFFSET = (Math.PI + Math.PI) * (value / 100);
    }

    var SQUARE_CORRELATION_FREQ = 1.0;

</script>

<div class="controls" width="180">
    <label id="squareShift" for=squareCorrelationOffset>Shift</label><br/>
    <input type=range min=0 max=100 value=0 id=squareCorrelationOffset step=0.5 oninput="updateSquareCorrelationOffset(value);"
    onMouseDown="" onMouseUp="" style="width: 150px"><br/>
</div>

此图描绘了两个不同信号的点积的计算。在最上面一排是一个方波，我们将称之为信号 A。在第二行里，有一个正弦波，我们将称之为信号 B。绘制在最下面一行的波形描绘了这两个信号的乘积。这个信号是由信号 A 的每个点与它在信号 B 中垂直对应的点进行乘积所产生的。在图的最底部，显示了点积的最终值。点积的大小对应的是积分，也就是第三个曲线下方的区域。

当你滑动图底部的滑块，你会注意到当两个信号相关时 (更趋向于一起上下移动)，点积的绝对值就会变大，而这两个信号是不相关或反方向移动时就更小。信号 A 的行为更像信号 B 时，所产生的点积就越多。令人惊讶的是，点积允许我们很容易地计算两个信号之间的相似性。

在下一节中，我们将巧妙的应用点积来确定波形内循环，并制定一个简单的方法来确定一个复合波形的基频。

## 自相关

<img src="/images/issues/issue-24/pic5.png"></img>

自相关就像是一副自画像，或一本自传。这是一个信号与其**自身**的相关度。我们通过计算在各种位移或时间**滞后**的情况下，一个信号与自身的副本的点积来测算自相关性。假设我们有看起来像下面的图中所示的复合波形信号。

<table width="630">
    <tr>
        <td>
        <svg id="autosignal" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/assets/js/issue-24/autosignal.js">
        </script>
            </td>
    </tr>
</table>

我们制作一个信号的副本，并相对于原信号进行移动来计算自相关性。对于每个移动 (滞后)，我们计算这两个信号的点积并把这个值记录到我们的**自相关函数**里。自相关函数绘制在下图的第三行。对于每个可能的滞后，自相关函数的高度告诉我们原始信号和其副本之间有多少相似度。

<table>
    <tr>
        <td><br/>
            <svg id="sigCorrelationInteractiveTwoSines" class="svgWithText" width="600" height="300" style=""></svg>
            <script type="text/javascript" src="/assets/js/issue-24/sine_correlation.js">
            </script>

            <script>
                var SIMPLE_CORRELATION_OFFSET = 0.0;
                function updateSimpleCorrelationOffset(value) {
                    SIMPLE_CORRELATION_OFFSET = value * 1.0;
                }
            
            </script>

            <div class="controls" width="180">
                <label id="phaseShift" for=simpleCorrelationOffset>Lag: <b> -60</b></label><br/>
                <input type=range min=0 max=120 value=0 id=simpleCorrelationOffset step=1 oninput="updateSimpleCorrelationOffset(value);"
                onMouseDown="" onMouseUp="" style="width: 150px"><br/>
            </div>
            </td>
    </tr>
</table>

慢慢向右移动该图底部的滑块来探索自相关函数在各种滞后下的值。我希望你特别注意自相关函数的峰值 (局部最大值) 的位置。例如，请注意，自相关最高峰总会在没有滞后的时候发生。直观地看，这是很合理的，因为一个信号总是会同本身有最大的相关性。然而更重要的是，我们应该注意到，自相关函数的次高峰在该信号是一个循环的倍数偏移时出现。换句话说，我们每次偏移或滞后副本一个全周期时，自相关函数都会达到峰值，因为它再次与自身保持一致。

这种方法的关键是要确定自相关函数中连续主峰之间的距离。这个距离将与一个波形周期的长度精确的保持一致。峰之间的距离越长，波的周期时间越长，波的频率越低。峰之间的距离越短，波的周期越短，频率越高。对于我们的波形，我们可以看到，突出峰之间的距离为 0.25 秒。这意味着，我们的信号每秒完成 4 个周期，基频为 4 赫兹 - 正如我们之前目测的预期。

<table width="630">
<tr>
    <td>
    <svg id="autocorrelationinterpretation" class="svgWithText" width="600" height="150"></svg>
    <script type="text/javascript" src="/assets/js/issue-24/autocorrelationinterpretation.js">
    </script>
        </td>
</tr>
</table>

自相关是一种极好的测量音高的信号处理方法，但它也有缺点。一个明显的问题是，自相关函数在其左右边缘逐渐变平缓。这是由在计算点积时极端的滞后下非零点样本较少引起的。原始波形以外的样点被简单地认作是零，这导致点积整体大小的衰减。此效应被称为**偏差**。我们可以用很多方式来处理这个问题。在 Philip McLeod 的优秀论文[“一种更智能的寻找音高的方法”](http://www.objccn.io/issue-24/miracle.otago.ac.nz/tartini/papers/A_Smarter_Way_to_Find_Pitch.pdf)里，他设计了一种策略，用一种非显而易见的，但非常可靠的方法巧妙地消除了自相关函数的这种偏差。当你尝试实现了一个简单的自相关后，我建议你通过阅读这篇论文，看看如何用基本方法来完善和改进它。

源生的自相关算法是 <i>O(N<sup>2</sup>)</i> 复杂度的操作。这种复杂度还不足以实现我们打算实时运行的算法的期望。值得庆幸的是，有 <i>O(N log(N))</i> 时间下有效的计算自相关性的方式。该算法的理论依据远远超出了本文的范围，但如果你有兴趣，你应该知道，使用两个 FFT (快速傅立叶变换) 操作计算自相关函数是可行的。你可以在下面的注解中阅读到更多关于这项技术的内容。我会建议先写个源生版本，并以此为基石，来验证更复杂的基于 FFT 的实现。

> 自相关可以使用一对 FFT 和 IFFT 来计算。为了计算这篇文章自相关的方式 (线性自相关)，你必须在执行 FFT 之前首先把你的信号用两倍来[补零](http://jackschaedler.github.io/circles-sines-signals/zeropadding.html) (如果你的信号没有补零，你最终会实现一个所谓的**环形**自相关性)。线性自相关的公式在 MATLAB 或 Octave 中可以表示成这样：`linear_autocorrelation = ifft(abs(fft(signal)) .^ 2);`

## 延迟和等待游戏

<img src="/images/issues/issue-24/pic4.png"></img>

实时音频应用会把时间分成块或**缓存区**。在 iOS 和 OS X 的开发中，Core Audio 将从麦克风或音频输入插孔输入的音频导入到应用程序的缓冲区，并希望你能定期在渲染回调方法里提供音频的缓冲区。它可能看起来微不足道，但它对于帮助你理解你的应用程序的音频缓冲区大小与你的分析算法里需要考虑的音频材料的关系是非常重要的。

让我们来看一个简单的假想实验。假设你的应用程序采样率是 128 赫兹，而你的应用程序接收到的是存有 32 个样本的缓冲区。这样的话，如果你想检测一个 2 赫兹的基频，就必须至少捕捉一个两个输入样本的缓冲区，才能得到一个完整的 2 赫兹输入波形周期。

> 对音频来说，这样的采样率是很荒谬的。我只是使用它作为一个例子，因为它可以方便的可视化。正常的音频采样率是 44000 赫兹。事实上，在这整个文章中，我选择的频率和采样率都是为了可以轻松的可视化。

<table width="630">
    <tr>
        <td>
        <svg id="buffer1" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/assets/js/issue-24/buffer1.js">
        </script>
            </td>
    </tr>
    <tr>
        <td>
        <svg id="buffer2" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/assets/js/issue-24/buffer2.js">
        </script>
            </td>
    </tr>
</table>

实际上本文中讨论的音高检测技术需要输入信号的**两个或更多**的周期值，才能够准确地检测出音高。对于我们想象的应用程序，这意味着在能够准确计算该波形的音高之前，我们需要等待**另外**两个传入我们音频回调的音频缓冲区。

<table width="630">
    <tr>
        <td>
        <svg id="buffer3" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/assets/js/issue-24/buffer3.js">
        </script>
            </td>
    </tr>
    <tr>
        <td>
        <svg id="buffer4" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/assets/js/issue-24/buffer4.js">
        </script>
            </td>
    </tr>
</table>

这看起来已经很明显了，但它是非常重要的一点。编写音频分析算法时一个典型的错误就是生成一个在高频信号下有效，但对低频信号表现不佳的实现。导致发生这种情况的原因有很多，但它往往是由于算法无法在足够大的分析窗口下工作所造成的 - 也就是在执行你的分析之前没有等待到收集到足够的样本。高频信号可能不会揭示这样的问题，因为在高频输入波形的单个音频缓冲器里通常已经有足够多用于完全描述多个周期的样本。

<table width="630">
    <tr>
        <td>
        <svg id="buffer5" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/assets/js/issue-24/buffer5.js">
        </script>
    </td>
    </tr>
</table>

处理这种情况的最好办法是把每个传入音频缓冲区推入二次循环缓冲区。此循环缓冲器应足够大，以容纳要检测的最低音调的至少两个完整的周期。你应当避免简单地去增加应用程序的缓冲区的大小，这将导致你的应用程序增加整体的等待时间，即使你只需要为特定的分析任务分配更大的缓冲区。

你可以选择从你的检测范围中排除非常低的频率来降低延迟。例如，你在你的 OS X 或 iOS 的项目里运行 44,100 赫兹的采样率，如果你想检测低于 60 赫兹的基音，在进行自相关操作之前你将需要收集至少 2048 个采样。但如果你不关心低于 60 赫兹的基音，你可以仅仅只分析 1,024 个采样大小的缓冲区。

本节的要点是，**立刻**检测出音高是不可能的。任何一个音高跟踪方法都存在固有延迟，你只能等待。想要检测的频率越低，需要等待的时间就越长。频率覆盖和算法延迟之间的权衡实际上涉及到的是海森堡不确定性原理，并渗透到所有的信号处理理论中。在一般情况下，你越是了解信号的频率内容，你就越不知道它在时间上的位置。

# 参考和进一步阅读

我希望现在你有基频测量问题的一个足够坚固的理论立足点来开始编写自己的单音音调追踪器。从这篇文章粗略的说明开始工作，你应该能够实现一个简单的单音音调追踪器并挖掘到一些相关的学术著作。如果没有，我希望你至少对音频信号处理理论有一些基本概念并对可视化图和插图感到满意。

这篇文章中概述的音高检测方法在过去的几十年已经很大程度上被学术信号处理社区探索和改进完成了。在本文中，我们只展现了表面的东西，我建议你继续深入挖掘单音间距探测器的两个优秀的例子来完善你最初的实现和探索：SNAC 和 YIN 算法。

Philip McLeod 的 SNAC 间距检测算法是本文介绍的自相关方法的巧妙改进。McLeod 已经找到了一种方法来解决自相关函数的内在偏差。他的方法是性能卓越而且稳定。如果你想了解更多关于单音间距的检测，我强烈建议你阅读 McLeod 题为[“一种更智能的寻找音高的方法”](http://www.objccn.io/issue-24/miracle.otago.ac.nz/tartini/papers/A_Smarter_Way_to_Find_Pitch.pdf)的论文。这是关于这个问题的最平易近人的论文之一。[这里](http://www.katjaas.nl/helmholtz/helmholtz.html)还有关于 McLeod 的方法超赞的教程和评价。我 **强烈**建议围观这个作者的网站。

YIN 由 Cheveigné 和 Kawahahara 在 21 世纪初开发，并且仍然是基音检测技术的一个经典方法。它经常作为音频信号处理的研究生课程。如果你发现你对音高测量这个话题很有兴趣的话，我当然推荐去读下[原文](http://audition.ens.fr/adc/pdf/2002_JASA_YIN.pdf)。实现自己版本的 YIN 也是一个有趣的周末任务。

更近一步，如果你对**和弦**基频测量技术有兴趣，我建议你开始阅读 Anssi Klapuri 的优秀博士论文[自动谱曲](http://www.cs.tut.fi/sgn/arg/klap/phd/klap_phd.pdf)。在他的论文中，他列出了多基频测量的一些方法，并给出了自动谱曲的一个非常完整的概述。

如果你觉得对开始做自己的狗屋已经有了足够的启发，对这篇文章的内容有任何问题、抱怨或意见，都可以在 Twitter 上随时[与我联系](https://twitter.com/JackSchaedler)。祝你的狗屋建筑顺利！

<img src="/images/issues/issue-24/pic6.png"></img>

---


 

原文 [Audio API Overview](http://www.objc.io/issue-24/audio-dog-house.html)
