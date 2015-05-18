---
title:  "The Audio Processing Dog House"
category: "24"
date: "2015-05-11 11:00:00"
tags: article
illustrations: true
stylesheets: "issue-24/style.css"
author: "<a href=\"https://twitter.com/JackSchaedler\">Jack Schaedler</a>"
---

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

<script type="text/javascript" src="/javascripts/issue-24/d3.min.js"></script>

I'm not sure if this concept is universal, but in North America, the archetypal project for a young and aspiring carpenter is the creation of a dog house; when children become curious about construction and want to fiddle around with hammers, levels, and saws, their parents will instruct them to make one. In many respects, the dog house is a perfect project for the enthusiastic novice. It's grand enough to be inspiring, but humble enough to preclude a sense of crushing defeat if the child happens to screw it up or lose interest halfway through. The dog house is appealing as an introductory project because it is a miniature "Gesamtwerk." It requires design, planning, engineering, and manual craftsmanship. It's easy to tell when the project is complete. When Puddles can overnight in the dog house without becoming cold or wet, the project is a success.

我不知道这种观念是不是普遍的，但在北美，一个年轻而有抱负的木匠典型的项目是建立一个狗屋；当孩子对建筑变得好奇，想要反复折腾锤子，水平仪，锯子时，他们的父母会指导他们做一个。在很多方面，狗屋对热情的新手来说是理想的项目。项目大小足以鼓舞人心，但也足够简单以避免孩子恰好搞砸了或中途就失去兴趣造成惨败的结果。狗屋作为一个入门项目是很有吸引力的，因为它是一个微型“全集”。它需要设计，规划，工程和手工工艺。很容易知道什么时候该项目已经完成。当汪星人可以整夜待在狗房子而没有变冷或潮湿，这个项目就是成功的。


<img src="/images/issue-24/pic1.png"></img>

I'm certain that most earnest and curious developers — the kind that set aside their valuable time on evenings and weekends to read a periodical like objc.io — often find themselves in a situation where they're attempting to evaluate tools and understand new and difficult concepts without having an inspiring or meaningful project handy for application. If you're like me, you've probably experienced that peculiar sense of dread that follows the completion of a "Hello World!" tutorial. The jaunty phase of editor configuration and project setup comes to a disheartening climax when you realize that you haven't the foggiest idea what you actually want to <i>make</i> with your new tools. What was previously an unyielding desire to learn Haskell, Swift, or C++ becomes tempered by the utter absence of a compelling project to keep you engaged and motivated.

我敢肯定，最认真，最好奇的开发者 - 那些用他们晚上和周末的宝贵时间去阅读一些像 objccn.io 这样期刊的人 - 常常会发现他们在一个缺乏激发灵感的或有意义的实在的应用程序项目的情况下去试图评估一些工具和了解一些新的难懂的概念。如果你像我一样，你可能已经经历了完成 “Hello World!” 教程的那种特殊的恐惧感。编辑配置和项目设置的时候还挺潇洒的，但当你意识到你已经对你真正想要用你的新工具 _做_ 什么变得很模糊的时候，会变得非常的沮丧。以前那种学习 Haskell，Swift，或 C++ 的不屈不挠的精神在没有一个强制的项目的激励下变的可有可无。

In this article, I want to propose a "dog house" project for audio signal processing. I'm making an assumption (based on the excellent track record of objc.io) that the other articles in this issue will address your precise technical needs related to XCode and Core Audio configuration. I'm viewing my role in this issue of objc.io as a platform-agnostic motivator, and a purveyor of fluffy signal processing theory. If you're excited about digital audio processing but haven't a clue where to begin, read on.

在这篇文章中，我想提出一个音频信号处理的“狗屋”项目。我在做一个假设（基于 objccn.io 的优良记录），在这个问题上的其他文章将让你对 XCode 和 Core Audio 配置相关的问题有强烈的技术需求。在 objccn.io  的这个问题上，我把我自己定位成一个与平台无关的激励者，一个基础信号处理理论的传播者。如果你对数字音频处理有强烈的兴趣，但不知道从何开始，那么，我们开始吧。

## Before We Begin

## 开始之前

Earlier this year, I authored a 30-part interactive essay on basic signal processing. You can find it <a href="https://jackschaedler.github.io/circles-sines-signals/index.html">here</a>. I humbly suggest that you look it over before reading the rest of this article. It will help to explicate some of the basic terminology and concepts you might find confusing if you have a limited background in digital signal processing. If terms like "Sample," "Aliasing," or "Frequency" are foreign to you, that's totally OK, and this resource will help get you up to speed on the basics.

今年早些时候，我撰写了基本信号处理的 30 部分的互动文章。你可以在[这儿](https://jackschaedler.github.io/circles-sines-signals/index.html)找到。我建议你在阅读这篇文章之前再看一遍。如果你在数字信号处理的背景有限，这将有助于消除一些基本的术语和概念给你带来的困惑。如果你对像“样本”，“别名”，或“频率”这样的术语感到陌生，那没有任何问题，这篇文章将帮助你很快的了解基础知识。

## The Project

## 项目

As an introductory project to learn audio signal processing, I suggest that you <b>write an application that can track the pitch of a <i>monophonic</i> musical performance in real time</b>.

作为学习音频信号处理的入门项目，我建议你*编写一个可以跟踪一个 _单音_ 音高的实时音乐表演的应用程序*。

Think of the game "Rock Band" and the algorithm that must exist in order to analyze and evaluate the singing player's vocal performance. This algorithm must listen to the device microphone and automatically compute the frequency at which the player is singing, in real time. Assuming that you have a plump opera singer at hand, we can only hope that the project will end up looking something like this:[^1a]

想想游戏 “Rock Band” 以及用于分析和评估歌手声音表现而必须存在的算法。该算法必须从设备的麦克风得到数据并自动的计算歌手实时的歌唱频率。假设你身边有一个丰满的歌剧演唱者，我们希望该项目最终将看起来像是这样的：[^1a]

<img src="/images/issue-24/pic2.png"></img>

I've italicized the word monophonic because it's an important qualifier. A musical performance is <i>monophonic</i> if there is only ever a single note being played at any given time. A melodic line is monophonic. Harmonic and chordal performances are <i>not</i> monophonic, but instead <i>polyphonic</i>. If you're singing, playing the trumpet, blowing on a tin whistle, or tapping on the keyboard of a Minimoog, you are performing a monophonic piece of music. These instruments do not allow for the production of two or more simultaneous notes. If you're playing a piano or guitar, it's quite likely that you are generating a polyphonic audio signal, unless you're taking great pains to ensure that only one string rings out at any given time.

我刚才把单音这个词用斜体标注是因为它是一个重要的参数。如果在任何给定的时间内只有一个音符被演奏，那么音乐表演就是_单音_的。旋律是单音。和旋和和声 _不是_ 单音的，而是 _多音的_。如果你在唱歌，或是吹着小号，吹着哨笛，或敲击着 Minimoog，那么你在表演一个单音的音乐作品。这些乐器不允许同时发出两个或两个以上的音符。而如果你是在弹钢琴或吉他，那么你很可能在生成一个和弦音频信号，除非你辛苦的确保在任何给定的时间内只有一个字符响起。

The pitch detection techniques that we will discuss in this article are only suitable for <i>monophonic</i> audio signals. If you're interested in the topic of polyphonic pitch detection, skip to the <i>resources</i> section, where I've linked to some relevant literature. In general, monophonic pitch detection is considered something of a solved problem. Polyphonic pitch detection is still an active and energetic field of research.[^1b]

我们将在本文中讨论的音高检测技术只适用于 _单音_ 的音频信号。如果你对多声道的音高检测话题有兴趣，跳到 _资源_ 部分，在那儿我加了一些相关文献的链接。一般来说，单音的音高检测被认为是一个已经有解决办法的问题。而复音的音高检测仍然是一个活跃的研究领域。[^1b]

I will not be providing you with code snippets in this article. Instead, I'll give you some introductory theory on pitch estimation, which should allow you to begin writing and experimenting with your own pitch tracking algorithms. It's easier than you might expect to quickly achieve convincing results! As long as you've got buffers of audio being fed into your application from the microphone or line-in, you should be able to start fiddling around with the algorithms and techniques described in this article immediately.

在这篇文章中我不会给你提供代码片段。相反，我会给你介绍一些音高检测的理论，这应该可以让你开始尝试编写和实验自己的音高跟踪算法。这会比你想象中更快的得到一些令人信服的结果！只要你有从麦克风或线路的音频缓存用来传入你的应用，你应该马上就可以开始摆弄本文介绍的算法和技术了。

In the next section, I'll introduce the notion of wave <i>frequency</i> and begin to dig into the problem of pitch detection in earnest.

在下一节中，我将介绍波 _频_ 的概念并开始深入研究音高检测的问题。

## Sound, Signals, and Frequency

## 声音，信号和频率

<img src="/images/issue-24/pic3.png"></img>

Musical instruments generate sound by rapidly vibrating. As an object vibrates, it generates a <a href="http://jackschaedler.github.io/circles-sines-signals/sound.html">longitudinal pressure wave</a>, which radiates into the surrounding air. When this pressure wave reaches your ear, your auditory system will interpret the fluctuations in pressure as a sound. Objects that vibrate regularly and periodically generate sounds which we interpret as tones or notes. Objects that vibrate in a non-regular or random fashion generate atonal or noisy sounds. The most simple tones are described by the sine wave.

乐器通过快速振动产生声音。当一个物体振动的时候，它会生成一个 [纵向压力波](http://jackschaedler.github.io/circles-sines-signals/sound.html)，并辐射到周围的空气中。当这种压力波到达你的耳朵，你的听觉系统会把波动压力解释成声音。规律振动并周期性生成声音的物体，我们称之为铃声或音符。非规则或以随机方式振动的物体产生无调或噪音。最简单的音调是正弦波。

<table width="630">
    <tr>
        <td>
        <svg id="sinecycle" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/javascripts/issue-24/sine_cycle.js"></script>
    </td>
    </tr>
</table>

This figure visualizes an abstract sinusoidal sound wave. The vertical axis of the figure refers to the amplitude of the wave (intensity of air pressure), and the horizontal axis represents the dimension of time. This sort of visualization is usually called a <i>waveform drawing</i>, and it allows us to understand how the amplitude and frequency of the wave changes over time. The taller the waveform, the louder the sound. The more tightly packed the peaks and troughs, the higher the frequency. 

这是数字可视化的抽象正弦声波。纵轴是波的振幅（空气压力的强度），横轴表示时间维度。这种可视化图通常被称为 _波形绘制_，它让我们了解随着时间的推移波的幅度和频率是如何变化的。该波形越高，声音越大。波峰和波谷越紧凑，频率越高。

The frequency of any wave is measured in <i>hertz</i>. One hertz is defined as one <i>cycle</i> per second. A <i>cycle</i> is the smallest repetitive section of a waveform. If we knew that the width of the horizontal axis corresponded to a duration of one second, we could compute the frequency of this wave in hertz by simply counting the number of visible wave cycles.

任何波的频率都是用 _赫兹_ 衡量的。一赫兹被定义为每秒的一个 _循环_。一个 _循环_ 是波形的最小重复部分。如果我们知道横轴的宽度相当于一秒的持续时间，我们就可以通过简单地用可见波周期的数量来计算该波频率的赫兹。

<table width="630">
<tr>
    <td>
    <svg id="sinecycle2" class="svgWithText" width="600" height="100"></svg>
    <script type="text/javascript" src="/javascripts/issue-24/sine_cycle2.js"></script>
        </td>
</tr>
</table>

In the figure above, I've highlighted a single cycle of our sine wave using a transparent box. When we count the number of cycles that are completed by this waveform in one second, it becomes clear that the frequency of the wave is exactly 4 hertz, or four cycles per second. The wave below completes eight cycles per second, and therefore has a frequency of 8 hertz. 

在上图中，我已经用一个透明的框标出了正弦波的一个循环。当我们数一下该波在一秒内完成的循环数，就可以很清楚的知道，波的频率恰好是 4 赫兹，或每秒 4 个循环。下面的波每秒完成 8 个循环，因此，它具有 8 赫兹的频率。 

<table width="630">
    <tr>
        <td>
        <svg id="sinecycle3" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/javascripts/issue-24/sine_cycle3.js"></script>
            </td>
    </tr>
</table>

Before proceeding any further, we need some clarity around two terms I have been using interchangeably up to this point. <i>Pitch</i> is an auditory sensation related to the human perception of sound. <i>Frequency</i> is a physical, measurable property of a waveform. We relate the two concepts by noting that the pitch of a signal is very closely related to its frequency. For simple sinusoids, the pitch and frequency are more or less equivalent. For more complex waveforms, the pitch corresponds to the <i>fundamental</i> frequency of the waveform (more on this later). Conflating the two concepts can get you into trouble. For example, given two sounds with the same fundamental frequency, humans will often perceive the louder sound to be higher in pitch. For the rest of this article, I will be sloppy and use the two terms interchangeably. If you find this topic interesting, continue your extracurricular studies <a href="http://en.wikipedia.org/wiki/Pitch_%28music%29">here</a>.

在进一步的讨论之前，我们需要围绕两个我一直在互换使用的术语做一些澄清。 _音高_ 是与人类声音感知相关的听觉。_频率_ 是一个波形物理的，可测量的属性。由于一个信号的间距与它的频率密切关系，我们常把两个概念联系到一起。对于简单的正弦来说，音高和频率差不多是相同的。对于更复杂的波形而言，间距对应的是波形 _基本_ 的频率（之后会更多的阐述）。将两个概念混为一谈可能会让你陷入困境。例如，给定两个具有相同的基频的声音，人类通常首先感知到的更响亮的声音是音高较高的那个。对于本文的其余部分，我会草率和交替使用这两个词。如果你对这个话题感兴趣，请到[这里](http://en.wikipedia.org/wiki/Pitch_%28music%29)继续你的课外学习。


## Pitch Detection

## 音高检测

Stated simply, algorithmic pitch detection is the task of automatically computing the frequency of some arbitrary waveform. In essence, this all boils down to being able to robustly identify a single cycle within a given waveform. This is an exceptionally easy task for humans, but a difficult task for machines. The CAPTCHA mechanism works precisely because it's quite difficult to write algorithms that are capable of robustly identifying structure and patterns within arbitrary sets of sample data. I personally have no problem picking out the repeating pattern in a waveform using my eyeballs, and I'm sure you don't either. The trick is to figure out how we might program a computer to do the same thing quickly, in a real-time, performance-critical environment.[^1c]

简单地说，音高检测的算法就是自动计算出任意波形的频率。从本质上说，这一切都归结为能够准确的识别给定波形的一个单一循环。这对人类来说是一个非常简单的任务，但对机器来说则是艰巨的。CAPTCHA 机制正是因为它能够准确识别任意样本数据范围内的结构和模式才能精确地工作，这是相当难写的算法。我自己用我的眼球来挑选出重复图案的波形并没有什么问题，而且我敢肯定，你也一样。关键是要搞清楚我们如何编程使得计算机能迅速的，实时的，性能关键的环境下做同样的事情。[^1c]


## The Zero-Crossing Method

## 通过零点法

As a starting point for algorithmic frequency detection, we might notice that any sine wave will cross the horizontal axis two times per cycle. If we count the number of zero-crossings that occur over a given time period, and then divide that number by two, we <i>should</i> be able to easily compute the number of cycles present within a waveform. For example, in the figure below, we count eight zero-crossings over the duration of one second. This implies that there are four cycles present in the wave, and we can therefore deduce that the frequency of the signal is 4 hertz.

作为一个频率检测算法的出发点，我们可能会发现，任何正弦波都将在每个循环内两次穿越横轴。如果我们计算在给定时间段通过零点的次数，然后除以 2，我们就 _应该_ 能够很容易的计算出波形中存在的循环数。例如，在下面的图中，在一秒的时间内可以数到八个过零点。这意味着，波里存在有四个周期，因此，我们可以推断，该信号的频率为 4 赫兹。

<table width="630">
    <tr>
        <td>
        <svg id="zerocrossings" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/javascripts/issue-24/zerocrossings.js"></script>
            </td>
    </tr>
</table>

We might begin to notice some problems with this approach when fractional numbers of cycles are present in the signal under analysis. For example, if the frequency of our waveform increases slightly, we will now count nine zero-crossings over the duration of our one-second window. This will lead us to incorrectly deduce that the frequency of the purple wave is 4.5 hertz, when it's really more like <i>4.6</i> hertz.

我们可能会开始注意到这种方法的一些问题，所分析的信号周期数可能会有小数点存在。例如，如果波形的频率逐渐增加，一秒的持续时间内将有 9 个过零点。这将导致我们错误地推断出紫色波的频率为 4.5 赫兹，但它看起来更像 _4.6_ 赫兹。

<table width="630">
<tr>
    <td>
    <svg id="zerocrossings2" class="svgWithText" width="600" height="100"></svg>
    <script type="text/javascript" src="/javascripts/issue-24/zerocrossings2.js"></script>
        </td>
</tr>
</table>

We can alleviate this problem a bit by adjusting the size of our analysis window, performing some clever averaging, or introducing heuristics that remember the position of zero-crossings in previous windows and predict the position of future zero-crossings. I'd recommend playing around a bit with improvements to the naive counting approach until you feel comfortable working with a buffer full of audio samples. If you need some test audio to feed into your iOS device, you can load up the sine generator at the bottom of <a href="http://jackschaedler.github.io/circles-sines-signals/sound.html">this page</a>.

我们可以通过调整我们的分析窗口的大小，巧妙的均衡一些，或启发式的记住在前面的窗口通过零点的位置以预测未来过零点的位置来缓解这个问题。我建议你多尝试去改进一下笨拙的计数方法，直到你可以感觉可以开始音频样本缓冲区的工作。如果你需要一些测试音频导入到你的 iOS 设备，你可以在[此页面底部](http://jackschaedler.github.io/circles-sines-signals/sound.html)加载正弦波发生器。

While the zero-crossing approach might be workable for very simple signals, it will fail in more distressing ways for complex signals. As an example, take the signal depicted below. This wave still completes one cycle every 0.25 seconds, but the number of zero-crossings per cycle is considerably higher than what we saw for the sine wave. The signal produces six zero-crossings per cycle, even though the fundamental frequency of the signal is still 4 hertz.

通过零点法对非常简单的信号可能是可行的，但它对复杂的信号进行分析时会以令人痛苦的方式失败。用下面表示出的信号来举个例子，这个波形仍然是每 0.25 秒完成一个循环，但每个循环通过零点的数目比我们看到的正弦波高得多。这个信号在每个周期产生了六个过零点，尽管该信号的基波频率仍为 4 赫兹。

<table width="630">
    <tr>
        <td>
        <svg id="zerocrossingscomplex" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/javascripts/issue-24/zerocrossingscomplex.js"></script>
            </td>
    </tr>
</table>

While the zero-crossing approach isn't really ideal for use as a hyper-precise pitch tracking algorithm, it can still be incredibly useful as a quick and dirty way to roughly measure the amount of noise present in a signal. The zero-crossing approach is appropriate in this context because noisy signals will produce more zero-crossings per unit time than cleaner, more tonal sounds. Zero-crossing counting is often used in voice recognition software to distinguish between voiced and unvoiced segments of speech. Roughly speaking, voiced speech usually consists of vowels, where unvoiced speech is produced by consonants. However, some consonants, like the English "Z," are voiced (think of saying "zeeeeee").

虽然通过零点法作为一个超精密音高跟踪算法并不是很理想，但把它用来作为一个快速和粗略的方式来大致测量信号内的噪声量还是有效的。通过零点法在这里适用的原因是噪声信号比更清洁，更单调的声音在每单位时间产生更多的过零点。过零计数通常用于语音识别软件来区别语音和非语音。粗略地说，语音中通常包括元音，而非语音是由辅音产生的。然而，一些辅音，例如英文中的的 “Z” 是浊音（试试说：“zeeeeee”）。

Before we move on to introducing a more robust approach to pitch detection, we first must understand what is meant by the term I bandied about in earlier sections. Namely, the <i>fundamental frequency</i>.

在我们介绍一个更强大的方式来检测音高之前，我们首先必须了解我在前面章节不停谈论的这个术语是什么意思。也就是，_基频_。

## The Fundamental Frequency

## 基频

Most natural sounds and waveforms are <i>not</i> pure sinusoids, but amalgamations of multiple sine waves. While <a href="http://jackschaedler.github.io/circles-sines-signals/dft_introduction.html">Fourier Theory</a> is beyond the scope of this article, you must accept the fact that physical sounds are (modeled by) summations of many sinusoids, and each constituent sinusoid may differ in frequency and amplitude. When our algorithm is fed this sort of compound waveform, it must determine which sinusoid is acting as the <i>fundamental</i> or foundational component of the sound and compute the frequency of <i>that</i> wave.

最自然的声音和波形 _不是_ 纯正弦波，而是多个正弦波的混合。虽然[傅立叶理论](http://jackschaedler.github.io/circles-sines-signals/dft_introduction.html)超出了本文的范围，但你必须接受的一个事实是，物理的声音是（模型化）许多正弦波的和，并且每个正弦都可能有不同的频率和幅度。当我们的算法传入这类混合的波形，它必须确定哪个正弦充当着 _基音_ 或基本声音的组成部分，并计算出 _那个_ 波的频率。

I like to think of sounds as compositions of spinning, circular forms. A sine wave can be described by a spinning circle, and more complex wave shapes can be created by chaining or summing together additional spinning circles.[^1d] Experiment with the visualization below by clicking on each of the four buttons to see how various compound waveforms can be composed using many individual sinusoids.

我喜欢把声音看做由旋转的圆圈组成。一个正弦波可以通过一个旋转的圆圈来描述，更复杂的波形可以由组合或另外一些旋转圆圈的组合生成。[^1d]试试点击下面的四个按钮来控制可视化图像，看看使用许多单独的正弦波的组合如何形成各种不同的波形。

<div id="phasorbuttons" class="buttonholder" style="margin-left: 200px; margin-bottom: 10px;">
</div>
<svg id="phasorSum2" class="svgWithText" width="600" height="300" style="margin-left: 10px"></svg>
<script type="text/javascript" src="/javascripts/issue-24/inverse_fourier_transform.js"></script>

The blue spinning circle at the center of the diagram represents the <i>fundamental</i>, and the additional orbiting circles describe <i>overtones</i> of the fundamental. It's important to notice that one rotation of the blue circle corresponds precisely to one cycle in the generated waveform. In other words, every full rotation of the fundamental generates a single cycle in the resulting waveform.[^1d][^1e]

图中心的蓝色旋转圆圈代表了 _基音_，额外的轨道圈描述基音的 _泛音_。要注意的是，蓝圈的一次旋转精确对应了一个循环所生成的波形。换句话说，基音每旋转一圈产生一个单一循环中的波形。[^1d][^1e]

I've again highlighted a single cycle of each waveform using a grey box, and I'd encourage you to notice that the fundamental frequency of all four waveforms is identical. Each has a fundamental frequency of 4 hertz. Even though there are multiple sinusoids present in the square, saw, and wobble waveforms, the fundamental frequency of the four waveforms is always tied to the blue sinusoidal component. The blue component acts as the foundation of the signal.

我再次把每个波形的一个周期用灰色框标注了出来，这会让你进一步发现所有四个波形的基本频率是相同的。每个都具有 4 赫兹的基频。即使有多个正弦存在于正方形，锯齿，和摆动波形，四个波形的基频始终和蓝色正弦保持一致。蓝色部件成了信号的基础。

It's also very important to notice that the fundamental is not necessarily the largest or loudest component of a signal. If you take another look at the "wobble" waveform, you'll notice that the second overtone (orange circle) is actually the largest component of the signal. In spite of this rather dominant overtone, the fundamental frequency is still unchanged.[^1f]

同样需要非常注意的是，基频并不必是信号的最大或最响亮的组件。如果你再看看“抖动”波形，你会发现第二泛音（橙色圆圈）实际上是这个信号最大组成部分。尽管有这个相当有优势的泛音，但基频仍保持不变。[^1f]

In the next section, we'll revisit some university math, and then investigate another approach for fundamental frequency estimation that should be capable of dealing with these pesky compound waveforms.

在下一节中，我们将重温一些大学数学，然后探讨另一种基频测量的方法，它应该有能力处理这些讨厌的复合波形。


## The Dot Product and Correlation

## 点积和相关性

The <i>dot product</i> is probably the most commonly performed operation in audio signal processing. The dot product of two signals is easily defined in pseudo-code using a simple <i>for</i> loop. Given two signals (arrays) of equal length, their dot product can be expressed as follows:

_点积_ 很可能是在音频信号处理中最常执行的操作了。两个信号的点积很容易在伪代码中使用一个简单的 _for_ 循环来定义。假定两个信号（阵列）有相等的长度，它们的点积可表示为如下：


```swift
func dotProduct(signalA: [Float], signalB: [Float]) -> [Float] {
    return map(zip(signalA, signalB), *)
}
```

Hidden in this rather pedestrian code snippet is a truly wonderful property. The dot product can be used to compute the similarity or <i>correlation</i> between two signals. If the dot product of two signals resolves to a large value, you know that the two signals are positively correlated. If the dot product of two signals is zero, you know that the two signals are decorrelated — they are not similar. As always, it's best to scrutinize such a claim visually, and I'd like you to spend some time studying the figure below.

隐藏在这个相当简单的代码段里的是一个非常重要的知识点。点积可被用来计算两个信号之间的相似度或 _相关度_。如果两个信号的点积解析为一个大的值，就知道这两个信号是正相关的。如果两个信号的点积是零，就知道这两个信号去相关的 - 它们不相似。一如往常，一图胜千言，我希望你可以花一些时间研究下面的图。

<svg id="sigCorrelationInteractive" class="svgWithText" width="600" height="380" style="margin-left: 10px; margin-top: 10px"></svg>
<script type="text/javascript" src="/javascripts/issue-24/square_correlation.js"></script>

<script>
    var SQUARE_CORRELATION_OFFSET = 0.0;
    function updateSquareCorrelationOffset(value) {
        SQUARE_CORRELATION_OFFSET = Math.PI * 2 * (value / 100);
    }

    var SQUARE_CORRELATION_FREQ = 1.0;
</script>

<div class="controls" width="180">
    <label id="squareShift" for=squareCorrelationOffset>Shift</label><br/>
    <input type=range min=0 max=100 value=0 id=squareCorrelationOffset step=0.5 oninput="updateSquareCorrelationOffset(value);"
    onMouseDown="" onMouseUp="" style="width: 150px"><br/>
</div>

This visualization depicts the computation of the dot product of two different signals. On the topmost row, you will find a depiction of a square wave, which we'll call Signal A. On the second row, there is a sinusoidal waveform we'll refer to as Signal B. The waveform drawn on the bottommost row depicts the product of these two signals. This signal is generated by multiplying each point in Signal A with its vertically aligned counterpart in Signal B. At the very bottom of the visualization, we're displaying the final value of the dot product. The magnitude of the dot product corresponds to the integral, or the area underneath this third curve. 

此图描绘了两个不同信号的点积的计算。在最上面一排，你会发现一个方波，我们将称之为信号 A。在第二行里，有一个正弦波，我们将称之为信号 B。绘制在最下面一行的波形描绘了这两个信号的乘积。这个信号是由信号 A 的每个点与它在信号 B 中对应垂直排列的乘积产生。在图的最底部，显示了点积的最终值。点积的大小对应的积分，就是第三个曲线下方的区域。

As you play with the slider at the bottom of the visualization, notice that the absolute value of the dot product will be larger when the two signals are correlated (tending to move up and down together), and smaller when the two signals are out of phase or moving in opposite directions. The more that Signal A behaves like Signal B, the larger the resulting dot product. Amazingly, the dot product allows us to easily compute the similarity between two signals.

当你滑动图底部的滑块，你会注意到当两个信号相关时（更趋向于一起上下移动），点积的绝对值就会变大，而这两个信号是不相关或反方向移动时就更小。该信号 A 的行为更像信号 B 时，所产生的点积就越多。令人惊讶的是，点积允许我们很容易地计算两个信号之间的相似性。

In the next section, we'll apply the dot product in a clever way to identify cycles within our waveforms and devise a simple method for determining the fundamental frequency of a compound waveform.

在下一节中，我们将巧妙的应用点积来确定波形内循环，并制定一个简单的方法来确定一个复合波形的基频。

## Autocorrelation

## 自相关

<img src="/images/issue-24/pic5.png"></img>

The autocorrelation is like an auto portrait, or an autobiography. It's the correlation of a signal with <i>itself</i>. We compute the autocorrelation by computing the dot product of a signal with a copy of itself at various shifts or time <i>lags</i>. Let's assume that we have a compound signal that looks something like the waveform shown in the figure below.

自相关就像是一个自动的画像，或一本自传。这是一个信号与 _自身_ 的相关度。我们通过在各种位移或时间 _滞后_ 下计算信号与自身的副本的点积来测算自相关性。假设我们有看起来像下面的图中所示的复合波形信号。

<table width="630">
    <tr>
        <td>
        <svg id="autosignal" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/javascripts/issue-24/autosignal.js"></script>
            </td>
    </tr>
</table>


We compute the autocorrelation by making a copy of the signal and repeatedly shifting it alongside the original. For each shift (lag), we compute the dot product of the two signals and record this value into our <i>autocorrelation function</i>. The autocorrelation function is plotted on the third row of the following figure. For each possible lag, the height of the autocorrelation function tells us how much similarity there is between the original signal and its copy.

我们制作一个信号的副本，并反复同原稿一起移动来计算自相关性。对于每个移动（滞后），我们计算这两个信号的点积并把这个值记录到我们的 _自相关函数_ 里。自相关函数绘制在下图的第三行。对于每个可能的滞后，自相关函数的高度告诉我们原始信号和其副本之间有多少相似度。

<table>
    <tr>
        <td><br/>
            <svg id="sigCorrelationInteractiveTwoSines" class="svgWithText" width="600" height="300" style=""></svg>
            <script type="text/javascript" src="/javascripts/issue-24/sine_correlation.js"></script>

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


Slowly move the slider at the bottom of this figure to the right to explore the values of the autocorrelation function for various lags. I'd like you to pay particular attention to the position of the peaks (local maxima) in the autocorrelation function. For example, notice that the highest peak in the autocorrelation will always occur when there is no lag. Intuitively, this should make sense because a signal will always be maximally correlated with itself. More importantly, however, we should notice that the secondary peaks in the autocorrelation function occur when the signal is shifted by a multiple of one cycle. In other words, we get peaks in the autocorrelation every time that the copy is shifted or lagged by one full cycle, since it once again "lines up" with itself.

慢慢向右移动该图底部的滑块来探索自相关函数在各种滞后下的值。我希望你特别注意自相关函数的峰值（局部最大值）的位置。例如，请注意，自相关最高峰总会在没有滞后的时候发生。直观地看，这是很合理的，因为一个信号总是会同本身有最大的相关性。然而更重要的是，我们应该注意到，自相关函数的次高峰在该信号是一个循环的倍数偏移时出现。换句话说，我们每次偏移或滞后副本一个全周期时，自相关函数都会达到峰值，因为它再次与自身保持一致。

The trick behind this approach is to determine the distance between consecutive prominent peaks in the autocorrelation function. This distance will correspond precisely to the length of one waveform cycle. The longer the distance between peaks, the longer the wave cycle and the lower the frequency. The shorter the distance between peaks, the shorter the wave cycle and the higher the frequency. For our waveform, we can see that the distance between prominent peaks is 0.25 seconds. This means that our signal completes four cycles per second, and the fundamental frequency is 4 hertz — just as we expected from our earlier visual inspection.

这种方法的关键是要确定自相关函数中连续主峰之间的距离。这个距离将与一个波形周期的长度精确的保持一致。峰之间的距离越长，波的周期时间越长，波的频率越低。峰之间的距离越短，波的周期越短，频率越高。对于我们的波形，我们可以看到，突出峰之间的距离为 0.25 秒。这意味着，我们的信号每秒完成 4 个周期，基频为 4 赫兹 - 正如我们之前目测的预期。

<table width="630">
<tr>
    <td>
    <svg id="autocorrelationinterpretation" class="svgWithText" width="600" height="150"></svg>
    <script type="text/javascript" src="/javascripts/issue-24/autocorrelationinterpretation.js"></script>
        </td>
</tr>
</table>

The autocorrelation is a nifty signal processing trick for pitch estimation, but it has its drawbacks. One obvious problem is that the autocorrelation function tapers off at its left and right edges. The tapering is caused by fewer non-zero samples being used in the calculation of the dot product for extreme lag values. Samples that lie outside the original waveform are simply considered to be zero, causing the overall magnitude of the dot product to be attenuated. This effect is known as <i>biasing</i>, and can be addressed in a number of ways. In his excellent paper, <a href="miracle.otago.ac.nz/tartini/papers/A_Smarter_Way_to_Find_Pitch.pdf">"A Smarter Way to Find Pitch,"</a> Philip McLeod devises a strategy that cleverly removes this biasing from the autocorrelation function in a non-obvious but very robust way. When you've played around a bit with a simple implementation of the autocorrelation, I would suggest reading through this paper to see how the basic method can be refined and improved.

自相关是一个极好的测量音高的信号处理伎俩，但它也有缺点。一个明显的问题是，自相关函数在其左右边缘逐渐变平缓。这是由于在计算点积时极端的滞后值下非零点样本较少引起的。原始波形以外的样本被简单地认作是零，导致点积的整体大小被衰减。此效应被称为 _偏差_，并且可以以多种方式来解决。在 Philip McLeod 的优秀论文 [“一个更智能的方式找到音高”](http://www.objccn.io/issue-24/miracle.otago.ac.nz/tartini/papers/A_Smarter_Way_to_Find_Pitch.pdf) 里，他设计了一种策略，用一种非显而易见的，但非常可靠的方法巧妙地消除了自相关函数的这种偏差。当你尝试实现过一个简单的自相关性，我建议你通过阅读本文，看看如何用基本方法来完善和改进它。

Autocorrelation as implemented in its naive form is an <i>O(N<sup>2</sup>)</i> operation. This complexity class is less than desirable for an algorithm that we intend to run in real time. Thankfully, there is an efficient way to compute the autocorrelation in <i>O(N log(N))</i> time. The theoretical justification for this algorithmic shortcut is far beyond the scope of this article, but if you're interested, you should know that it's possible to compute the autocorrelation function using two FFT (Fast Fourier Transform) operations. You can read more about this technique in the footnotes.[^1g] I would suggest writing the naive version first, and using this implementation as a ground truth to verify a fancier, FFT-based implementation. 

自相关是用简单的 <i>O(N<sup>2</sup>)</i> 操作实现的。这种复杂的类还不足以实现我们打算实时运行的算法的期望。值得庆幸的是，在 <i>O(N log(N))</i> 时间下有有效的计算自相关性的方式。该算法的理论依据远远超出了本文的范围，但如果你有兴趣，你应该知道，使用两个 FFT（快速傅立叶变换）操作计算自相关函数是可行的。你可以在脚注阅读到更多关于这项技术的内容。[^1g]我会建议先写个初级版本，并用此实现作为基础来验证基于 FFT 的实现。

## Latency and the Waiting Game

## 延迟和等待的游戏

<img src="/images/issue-24/pic4.png"></img>


Real-time audio applications partition time into chunks or <i>buffers</i>. In the case of iOS and OS X development, Core Audio will deliver buffers of audio to your application from an input source like a microphone or input jack and expect you to regularly provide a buffer's worth of audio in the rendering callback. It may seem trivial, but it's important to understand the relationship of your application's audio buffer size to the sort of audio material you want to consider in your analysis algorithms.

实时音频应用会把时间分成块或 _缓存区_。在 iOS 和 OS X 的开发中，Core Audio 将从像麦克风或音频输入插孔的输入源的音频导入到应用程序的缓冲区，并希望你能定期在渲染回调方法里提供音频的缓冲区。它可能看起来微不足道，但它对于帮助你理解你的应用程序的音频缓冲区大小与你的分析算法里需要考虑的音频材料的关系是非常重要的。

Let's walk through a simple thought experiment. Pretend that your application is operating at a sampling rate of 128 hertz,[^1h] and your application is being delivered buffers of 32 samples. If you want to be able to detect fundamental frequencies as low as 2 hertz, it will be necessary to collect two buffers worth of input samples before you've captured a whole cycle of a 2 hertz input wave.

让我们来看一个简单的假想实验。假装你的应用程序运行环境是 128 赫兹，[^1h]而你的应用程序得到了传来的 32 个样本的缓冲区。如果你想检测低至 2 赫兹的基频，在捕捉到一个 2 赫兹输入波的整个周期之前收集两个输入样本的缓冲器的值将是必要的。

<table width="630">
    <tr>
        <td>
        <svg id="buffer1" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/javascripts/issue-24/buffer1.js"></script>
            </td>
    </tr>
    <tr>
        <td>
        <svg id="buffer2" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/javascripts/issue-24/buffer2.js"></script>
            </td>
    </tr>
</table>


The pitch detection techniques discussed in this article actually need <i>two or more</i> cycles worth of input signal to be able to robustly detect a pitch. For our imaginary application, this means that we'd have to wait for two <i>more</i> buffers of audio to be delivered to our audio input callback before being able to accurately report a pitch for this waveform.

本文中讨论的音高检测技术在实际中需要输入信号 _两个或更多_ 的周期值，才能够准确地检测出音高。对于我们想象的应用程序，这意味着在能够准确计算该波形的音高之前，我们将不得不等待 _另外_ 两个传入我们音频回调的音频缓冲区。

<table width="630">
    <tr>
        <td>
        <svg id="buffer3" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/javascripts/issue-24/buffer3.js"></script>
            </td>
    </tr>
    <tr>
        <td>
        <svg id="buffer4" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/javascripts/issue-24/buffer4.js"></script>
            </td>
    </tr>
</table>


This may seem like stating the obvious, but it's a very important point. A classic mistake when writing audio analysis algorithms is to create an implementation that works well for high-frequency signals, but performs poorly on low-frequency signals. This can occur for many reasons, but it's often caused by not working with a large enough analysis window — by not waiting to collect enough samples before performing your analysis. High-frequency signals are less likely to reveal this sort of problem because there are usually enough samples present in a single audio buffer to fully describe many cycles of a high-frequency input waveform.

这看起来已经很明显了，但它是非常重要的一点。编写音频分析算法时一个典型的错误就是生成一个在高频信号下有效，但对低频信号表现不佳的实现。可能发生这种情况的原因有很多，但它往往由于没有测试过足够大的分析窗口造成 - 在执行你的分析之前没有等待到收集到足够的样本。高频信号可能不会揭示这样的问题，因为在高频输入波形的单个音频缓冲器里通常已经有足够多用于完全描述多个周期的样本。

<table width="630">
    <tr>
        <td>
        <svg id="buffer5" class="svgWithText" width="600" height="100"></svg>
        <script type="text/javascript" src="/javascripts/issue-24/buffer5.js"></script>
    </td>
    </tr>
</table>

The best way to handle this situation is to push every incoming audio buffer into a secondary circular buffer. This circular buffer should be large enough to accommodate at least two full cycles of the lowest pitch you want to detect. Avoid the temptation to simply increase the buffer size of your application. This will cause the overall latency of your application to increase, even though you only require a larger buffer for particular analysis tasks.

处理这种情况的最好办法是把每个传入音频缓冲区推入二次循环缓冲区。此循环缓冲器应足够大，以容纳要检测的最低音调的至少两个完整的周期。避免简单地增加应用程序的缓冲区大小的诱惑。这将导致你的应用程序增加整体的等待时间，即使你只需要为特定的分析任务分配更大的缓冲区。

You can reduce latency by choosing to exclude very bassy frequencies from your detectable range. For example, you'll probably be operating at a sample rate of 44,100 hertz in your OS X or iOS project, and if you want to detect pitches beneath 60 hertz, you'll need to collect at least 2,048 samples before performing the autocorrelation operation. If you don't care about pitches beneath 60 hertz, you can get away with an analysis buffer size of 1,024 samples.

你可以选择从你的检测范围中排除非常低的频率来降低延迟。例如，你可能会在你的 OS X 或 iOS 的项目里运行 44,100 赫兹的采样率，如果你想检测低于 60 赫兹的基音，在进行自相关操作之前你将需要收集至少 2048 个样品。如果你不关心低于 60 赫兹的基音，你可以抛开需要分析 1,024 个样品大小的缓冲区。

The important takeaway from this section is that it's impossible to <i>instantly</i> detect pitch. There's an inherent latency in any pitch tracking approach, and you must simply be willing to wait. The lower the frequencies you want to detect, the longer you'll have to wait. This tradeoff between frequency coverage and algorithmic latency is actually related to the Heisenberg Uncertainty Principle, and permeates all of signal processing theory. In general, the more you know about a signal's frequency content, the less you know about its placement in time.

本节的要点是，_立刻_ 检测出音高是不可能的。在任何一个音高跟踪方法都是有延迟的，你必须愿意等待。想要检测的频率越低，等待的时间越长。频率覆盖和算法延迟之间的权衡实际上涉及到的是海森堡不确定性原理（Heisenberg Uncertainty Principle），并渗透到所有的信号处理理论中。在一般情况下，你越是了解信号的频率内容，你越不知道它在时间上的位置。

# References and Further Reading

＃参考和进一步阅读

I hope that by now you have a sturdy enough theoretical toehold on the problem of fundamental frequency estimation to begin writing your own monophonic pitch tracker. Working from the cursory explanations in this article, you should be able to implement a simple monophonic pitch tracker and dig into some of the relevant academic literature with confidence. If not, I hope that you at least got a small taste for audio signal processing theory and enjoyed the visualizations and illustrations.

我希望现在你有基频测量问题的一个足够坚固的理论立足点来开始编写自己的单音音调追踪器。从这篇文章粗略的说明开始工作，你应该能够实现一个简单的单音音调追踪器并挖掘到一些相关的学术著作。如果没有，我希望你至少对音频信号处理理论有一些基本概念并对可视化图和插图感到满意。

The approaches to pitch detection outlined in this article have been explored and refined to a great degree of finish by the academic signal processing community over the past few decades. In this article, we've only scratched the surface, and I suggest that you refine your initial implementations and explorations by digging deeper into two exceptional examples of monophonic pitch detectors: the SNAC and YIN algorithms.

这篇文章中概述的音高检测方法在过去的几十年已经很大程度上被学术信号处理社区探索和改进完成了。在本文中，我们只展现了表面的东西，我建议你继续深入挖掘单音间距探测器的两个优秀的例子来完善你最初的实现和探索：SNAC 和 YIN 算法。

Philip McLeod's SNAC pitch detection algorithm is a clever refinement of the autocorrelation method introduced in this article. McLeod has found a way to work around the inherent biasing of the autocorrelation function. His method is performant and robust. I highly recommend reading McLeod's paper titled <a href="miracle.otago.ac.nz/tartini/papers/A_Smarter_Way_to_Find_Pitch.pdf">"A Smarter Way to Find Pitch"</a> if you want to learn more about monophonic pitch detection. It's one of the most approachable papers on the subject. There is also a wonderful tutorial and evaluation of McLeod's method available <a href="http://www.katjaas.nl/helmholtz/helmholtz.html">here</a>. I <i>highly</i> recommend poking around this author's website. 

Philip McLeod 的 SNAC 间距检测算法是本文介绍的自相关方法的巧妙改进。McLeod 已经找到了一种方法来解决自相关函数的内在偏差。他的方法是高性能和强大的。如果你想了解更多关于单音间距的检测，我强烈建议你阅读 McLeod 题为 [“一个更智能的方式找到音高”](http://www.objccn.io/issue-24/miracle.otago.ac.nz/tartini/papers/A_Smarter_Way_to_Find_Pitch.pdf) 的论文。这是关于这个问题的最平易近人的论文之一。[这里](http://www.katjaas.nl/helmholtz/helmholtz.html)还有关于 McLeod 的方法超赞的教程和评价。我 _强烈_ 建议围观这个作者的网站。

YIN was developed by Cheveigné and Kawahahara in the early 2000s, and remains a classic pitch estimation technique. It's often taught in graduate courses on audio signal processing. I'd definitely recommend reading <a href="audition.ens.fr/adc/pdf/2002_JASA_YIN.pdf">the original paper</a> if you find the topic of pitch estimation interesting. Implementing your own version of YIN is a fun weekend task.

YIN 由 Cheveigné 和 Kawahahara 在 21 世纪初开发，并且仍然是基音检测技术的一个经典。它经常作为音频信号处理研究生课程。我当然推荐阅读[原文](audition.ens.fr/adc/pdf/2002_JASA_YIN.pdf)。如果你发现音高测量这个话题还挺有趣。实现自己版本的 YIN 也是一个有趣的周末任务。

If you're interested in more advanced techniques for <i>polyphonic</i> fundamental frequency estimation, I suggest that you begin by reading Anssi Klapuri's excellent Ph.D. thesis on <a href="www.cs.tut.fi/sgn/arg/klap/phd/klap_phd.pdf">automatic music transcription</a>. In his paper, he outlines a number of approaches to multiple fundamental frequency estimation, and gives a great overview of the entire automatic music transcription landscape.

如果你对更先进的 _和弦_ 基频测量技术有兴趣，我建议你开始阅读  Anssi Klapuri 的优秀博士论文 [自动音乐转录](www.cs.tut.fi/sgn/arg/klap/phd/klap_phd.pdf)。在他的论文中，他列出了多基频测量的一些方法，并给出了自动音乐转录的一个非常完整的概述。

If you're feeling inspired enough to start on your own dog house, feel free to <a href="https://twitter.com/JackSchaedler">contact me</a> on Twitter with any questions, complaints, or comments about the content of this article. Happy building!

如果你觉得对开始做自己的狗屋已经有了足够的启发，对这篇文章的内容有任何问题，抱怨或意见，都可以在 Twitter 上随时 [与我联系](https://twitter.com/JackSchaedler)。祝你的狗屋建筑顺利！

<img src="/images/issue-24/pic6.png"></img>

## Footnotes

## 脚注

[^1a]: Monophonic pitch tracking is a useful technique to have in your signal processing toolkit. It lies at the heart of applied products like <a href="http://en.wikipedia.org/wiki/Auto-Tune">Auto-Tune</a>, games like "Rock Band," guitar and instrument tuners, music transcription programs, audio-to-MIDI conversion software, and query-by-humming applications.

[^1a]：单音音高跟踪在你的信号处理工具集里是一种有用的技术。它是应用产品的核心，比如 [Auto-Tune](http://en.wikipedia.org/wiki/Auto-Tune)，游戏里的 “Rock Band”，吉他和乐器调谐器，音乐转录程序，音频到 MIDI 转换软件，和哼歌识曲的应用程序。

[^1b]: Every year, the best audio signal processing researchers algorithmically battle it out in the <a href="http://www.music-ir.org/mirex/wiki/MIREX_HOME">MIREX</a> (Music Information Retrieval Evaluation eXchange) competition. Researchers from around the world submit algorithms designed to automatically transcribe, tag, segment, and classify recorded musical performances. If you become enthralled with the topic of audio signal processing after reading this article, you might want to submit an algorithm to the 2015 MIREX "K-POP Mood Classification" competition round. If cover bands are more your thing, you might instead choose to submit an algorithm that can identify the original title from a recording of a cover band in the "Audio Cover Song Identification" competition (this is much more difficult than you might expect).

[^1b]：每年，最好的音频信号处理研究人员都会把自己的算法拿出来在 [MIREX](http://www.music-ir.org/mirex/wiki/MIREX_HOME)（音乐信息检索评价交换）竞赛上一决雌雄。来自世界各地的研究人员将他们旨在自动录制、标记、分段、分类记录音乐表演的算法提交上来。如果你看完这篇文章后开始着迷音频信号处理的话题，你可能也会想要提交你的算法到 2015 年 MIREX “K-POP 情绪分类” 比赛单元。如果你对翻唱乐队更感兴趣，你可以选择把可以从翻唱乐队的录音中识别原唱的的算法提交到 “音频翻唱歌曲识别” 的竞赛去（这比你想象的更加困难）。

[^1c]: I'm not sure if such a thing has been attempted, but I think an interesting weekend could be spent applying techniques in computer vision to the problem of pitch detection and automatic music transcription.

[^1c]：我不知道这样的事情是否已经被尝试过了，但我认为一个有趣的周末可以用来把计算机视觉技术应用到音调检测和自动音乐转录的问题上去。

[^1d]: It's baffling to me why young students aren't shown the beautiful correspondence between circular movement and the trigonometric functions in early education. I think that most students first encounter sine and cosine in relation to right triangles, and this is an unfortunate constriction of a more generally beautiful and harmonious way of thinking about these functions.

[^1d]：我真的很不理解为什么青年学生们的早期教育都没有被展示过圆周运动和三角函数之间对应的优美关系。我认为大多数的学生第一次遇到正弦和余弦是在直角三角形里，这对更优美和和谐的去思考这些功能的方式来说是一个约束。

[^1e]: You may be wondering if adding additional tones to a fundamental makes the resulting sound polyphonic. In the introductory section, I made a big fuss about excluding polyphonic signals from our allowed input, and now I'm asking you to consider waveforms that consist of many individual tones. As it turns out, pretty much every musical note is composed of a fundamental and <a href="http://en.wikipedia.org/wiki/Overtone">overtones</a>. Polyphony occurs only when you have <i>multiple fundamental</i> frequencies present in a sound signal. I've written a bit about this topic <a href="http://jackschaedler.github.io/circles-sines-signals/sound2.html">here</a> if you want to learn more.

[^1e]：你可能会想，如果添加额外的音调，从根本上使产生的声音变成和弦。在引言部分，我大费周章的把和弦信号从合法输入中排除掉，而现在我希望你考虑的波形是由许多单个的音调组成。事实证明，几乎每一个音符都由一个基音和 [泛音](http://en.wikipedia.org/wiki/Overtone) 组成。复音只发生在 有_多个基本_ 频率出现在一个声音信号的时候。如果你想了解更多，我在 [这儿](http://jackschaedler.github.io/circles-sines-signals/sound2.html) 写了一些关于这个话题文章。

[^1f]: It's actually often the case that the fundamental frequency of a given note is quieter than its overtones. In fact, humans are able to perceive fundamental frequencies that do not even exist. This curious phenomenon is known as the <a href="http://en.wikipedia.org/wiki/Missing_fundamental">"Missing Fundamental"</a> problem.

[^1f]：实际上在通常的情况下，给定音符的基频比其泛音更小声。事实上，人类能够感知的基频甚至根本就不存在。这种奇怪的现象被称为 [“基频缺失”](http://en.wikipedia.org/wiki/Missing_fundamental) 问题。

[^1g]: The autocorrelation can be computed using an FFT and IFFT pair. In order to compute the style of autocorrelation shown in this article (linear autocorrelation), you must first <a href="http://jackschaedler.github.io/circles-sines-signals/zeropadding.html">zero-pad</a> your signal by a factor of two before performing the FFT (if you fail to zero-pad the signal, you will end up implementing a so-called <i>circular</i> autocorrelation). The formula for the linear autocorrelation can be expressed like this in MATLAB or Octave: `linear_autocorrelation = ifft(abs(fft(signal)) .^ 2);`

[^1g]：自相关可以使用一对 FFT 和 IFFT 来计算。为了计算这篇文章自相关的方式（线性自相关），你必须在执行 FFT 之前首先把你的信号用两倍来 [补零](http://jackschaedler.github.io/circles-sines-signals/zeropadding.html) （如果你的信号没有补零，你最终会实现一个所谓的_环形_自相关性）。线性自相关的公式用 MATLAB 或 Octave 可以表示成这样：`linear_autocorrelation = ifft(abs(fft(signal)) .^ 2);`

[^1h]: This sample rate would be ridiculous for audio. I'm using it as a toy example because it makes for easy visualizations. The normal sampling rate for audio is 44,000 hertz. In fact, throughout this whole article I've chosen frequencies and sample rates that make for easy visualizing.

[^1h]：音频的采样率是很荒谬的。我只是使用它作为一个例子，因为它可以方便的可视化。正常采样率的音频是 44000 赫兹。事实上，在这整个文章中，我选择的频率和采样率都是为了可以轻松的可视化。

---


[话题 #24 下的更多文章](http://www.objccn.io/issue-24)

原文 [Audio API Overview](http://www.objc.io/issue-24/audio-dog-house.html)