The idea of designing mobile games is a funny one. In theory, there isn't anything about making games for smartphones or tablets that's fundamentally different from any other form of game design. The formal properties of games as systems are the same across any genre or platform, and so the design process tends to look relatively similar, whether you're trying to make the next Farmville, Call of Duty, or chess.

设计手机游戏是一个有趣的主意，理论上，做智能手机或者平板电脑游戏与其他平台游戏设计没有根本的不同。手机游戏在传统系统属性上与其他类型以及平台极其相似，无论你想创造一个 Farmville，使命召唤或者国际象棋。

In practice, though, creating a successful mobile game can be a very different beast. So many different concerns — from market saturation and lack of discoverability, to usage patterns and form factor issues — can make it feel like making a good mobile game is like turning on "hard mode" as a designer.

但实践中，想要创建一个成功的手机游戏完全是另一回事。有很多其他的顾虑 - 市场饱和和难以被发现，使用模式或者形式因素等原因 - 作为一个设计师来说创造一个优秀的手机游戏就像在玩“困难模式”。

All of these various factors at play mean that most successful mobile games tend toward elegant rulesets. That is, they strive to be capable of deep, meaningful play, but that meaning needs to arise from a minimal set of simple rules. There's certainly a place for more ornate and baroque games, but very few successful mobile games tend to hew to that style, no matter what your metric for success is.

所有这些不同的因素集合一起意味着最成功的手机游戏倾向于优雅的规则集。也就是说，它们努力变的更深刻并有意义，这也意味需要产生一组最小的简单规则。肯定有更华丽的巴洛克式的游戏，但很少有成功的手机游戏坚持华丽风格，不管你的衡量标准是什么。

So how do we achieve these sorts of elegant designs we want in our games? Let's look at two defining characteristics of mobile games — play session length and methods of interaction — and see a few ways we might approach thinking about designing systems that suit the platform.

那么，我们如何在我们的游戏中实现这些优雅的设计？让我们来看看手机游戏的两个特征 — 游戏时长和交互方法 — 另外看下几种适用于移动平台的系统设计方法。

## Play Session Length
## 游戏会话时长

People play mobile games differently than most other kinds of games. Players demand games that are playable in short bursts, such as while they're waiting in line or on the toilet, but they also want the ability to partake in more meaningful, longer-term play sessions. Most studies peg the average iOS game session length at somewhere between one and two minutes, but at the same time, most mobile games are in actuality played at home rather than on the go. Striking a balance to make your game fun and rewarding in both situations is a *really* challenging problem.

玩家玩手机游戏相较于其他平台有很大不同。玩家需要在碎片化的时间内有游戏可玩，比如排队或者上厕所的时候，但是它们也希望游戏更加有意义，可以长时间玩下去。研究表明 iOS 游戏会话时长大多介于一到两分钟之间，与此同时，大多数手机游戏实际在家里玩的时间要比路上更多。想要让你的游戏在乐趣和奖励机制之间做到平衡是一个 **极有**挑战性问题。

To help us think about designing for both of these contexts, it's useful to think about a game as a collection of feedback loops. At any given moment of a game, you have a mental model of the game's system. Based on that, you're going to perform some action that will result in the game giving you feedback, which will in turn inform your mental model.

帮助我们思考设计这两种情景，构造一个游戏反馈循环的集合非常有用。在任何时候，你的游戏有一个心智模型。在这个基础上，你需要执行一些操作，让游戏给你反馈，同时反过来完善你的心智模型。

The key thing about these feedback loops is that they're fractal in nature; at any given moment, there could be any number of nested feedback loops at play. As an example, let's think about what is happening when you play a game of [Angry Birds](https://www.angrybirds.com).

关于这些反馈循环的关键一点是，他们是分形性质；在任何给定的时刻，可能有任意数量的嵌套的反馈循环。比如，让我们思考下玩[愤怒的小鸟](https://www.angrybirds.com)发生了什么。

![如何玩愤怒的小鸟](http://img.objccn.io/issue-18/AngryBirds.png)

Let's start at the level of each individual move you make. Flinging an individual bird across the map gives you the satisfaction of accomplishing something, but it also gives you feedback: did you destroy the blocks or pigs you thought you would? Did the arc your bird took (still visible onscreen after the bird has landed) mirror what you thought it would? This information informs your future shots.

让我们通过一个动作来开始，弹射小鸟到地图预计目标时也给了你相应的反馈：你破坏了你想要的箱子或者小猪？小鸟的弹射轨道在镜头内是否出乎你的意料 （轨道在鸟降落后依然可见）？这些信息决定了未来弹射的方向。

Taking a step back, the next most atomic unit of measurement is the level. Each level also acts as its own closed system of feedback and rewards: clearing it gives you anywhere from one to three stars, encouraging you to develop the skills necessary to truly 'beat' it.

退一步来说，最原子的度量单位是关卡。每个关卡还充当它自己的反馈和奖励的封闭系统： 通关让你获得一到三颗星星，鼓励你发展必要的技能来真正是 '战胜' 它。

In aggregate, all of the levels themselves form a feedback loop and narrative arc, giving you a clear sense of progression over time, in addition to providing you with a sense of your skill, relative to the overall system.

总的来说，所有的关卡本身形成一个反馈循环和叙事模式，随着时间的推移相对于整体系统的进展，给你一个清晰的发展，另外也为您提供你的技能。

We could keep going with examples, but I think the concept is clear. Again, this isn't a game design concept that is unique to mobile games; if either the moment-to-moment experience of playing your game or the overarching sense of personal progression is lacking, your game likely has room for improvement, no matter the platform.

这个例子我们可以继续延伸，但我认为基本概念是明确的。再次声明，这不是一个游戏设计常规概念，而是独一无二的手机游戏的理念，如果缺乏想时时刻刻的玩你的游戏的冲动或是总体意义上的个人发展，不管何种平台，你的游戏还有很大的改进余地。

This becomes particularly relevant when thinking about the problem of play session length, though. It's possible to have a game with fun moment-to-moment gameplay, while still having the smallest systemic loops be sufficiently long that trying to pick it up for a minute or two while in line wouldn't be fun. That same minute or two in Angry Birds lets you experience multiple full iterations of some of the game's feedback loops, giving a sense of fun even in such a short playtime. The existence of higher-level feedback loops means that these atomic micro-moments of fun don't come at the expense of ruining the potential for longer-term meaningful play.

这样来想游戏会话时长的问题，变得尤为重要。它可能是一个即时反馈乐趣的游戏，同时还具有足够长的最小系统性循环，试图把它捡起来一两分钟，依然有趣。在玩愤怒的小鸟一两分钟内，让您体验游戏反馈循环的多个完整的迭代，即使是在如此短的会话时长内依然给人一种畅快感。上级反馈循环的存在意味着不以这些微瞬间的乐趣为代价破坏长期有意义游戏。

## The Controller Conundrum
## 控制器难题

Most platforms for digital games — game consoles, PCs, and even arcade cabinets — have a larger number of inputs than smartphones or tablets. Many great mobile games find unique ways to use multitouch or the iPhone's accelerometer, rather than throwing lots of virtual buttons on the screen, but that still leaves iOS devices with far less discrete inputs than most other forms of digital games. The result is a difficult design challenge: how can we make interesting, meaningful, and deep game systems when our input is constrained? This is a relatively frequent topic of discussion for game design students — creating a one-button game is a classic educational exercise for aspiring designers — but the restrictions of iOS frequently make it more than an academic concern. Ultimately, it's a similar problem to that of gameplay session length: how do you create something that's simple and immediately approachable without giving up the depth and meaningful play that other forms of games exhibit?

数字游戏的平台 — 游戏控制器，PC 电脑，甚至商场柜机 — 相较于智能手机或平板电脑来说有大量的输入端。许多伟大的手机游戏找到独特的方式来使用多点触控或 iPhone 的加速器，而不是把大量的虚拟按钮显示在屏幕上，但这仍然留给 iOS 设备远大于其他形式数字游戏的输入方式的空间。其结果是一个艰难的设计挑战：怎么才能让在有限输入端游戏系统有趣，有意义并更深入？这是游戏设计专业的学生相讨论对频繁的主题 - 对有抱负的设计师创建一个一键式的游戏是永恒的课题 - 但 iOS 的限制，常常使其比一个学术需要关注更多。归根结底，这是一个类似游戏会话时长的问题：你如何创造东西，很简单，在不放弃的深度和意义的前提下平易近人，就像其他平台展示的那样？

One useful way for framing interactions in a game is to reduce the formal elements of the game down to 'nouns' and 'verbs.' Let's take the original Super Mario Bros. as an example. Mario has two main verbs: he can *run* and he can *jump*. The challenge in Mario comes from the way the game introduces and arranges nouns to shape these verbs over the course of the game, giving you different obstacles that require you to apply and combine these two verbs in interesting and unique ways.

在游戏中的框架交互的一个常用的方法是减少的 '名词' 和 '动词'。 让我们用超级马里奥来举例。马里奥包含两个‘动词’：他可以**跑**和**跳**。马里奥的挑战来自于游戏介绍和安排好的名词来塑造动词，给你不同的障碍来创造又独特又有趣的动词组合。

Of course, Mario would be much more boring if you could only run *or* jump. But even the six buttons required to play Mario (a four-directional d-pad and discrete 'run' and 'jump' buttons) are in many ways too complex an input for an ideal touchscreen game; there's a reason there are few successful traditional 2D platformers on iOS.

当然，马里奥如果只会跑**或者**跳那将非常无聊。但是玩转马里奥依然需要6个按键（4个方向键和跑跳键）在触屏上实现在很多方面非常复杂，这也就是为什么很少有 2D 游戏成功移植到 iOS 平台。

So how can we add depth and complexity to a game while minimizing the types of input? Within this framework of nouns and verbs, there are essentially three ways we can add complexity to a game. We can add a new input, we can add a new verb that uses an existing input, or we can take an existing verb and add more nouns that color that verb with new meaning. The first option is generally going to add complexity in the way we don't want, but the other two can be very effective when done right. Let's look at some examples of mobile games that use each of these ways to layer in additional depth without muddying the core game interactions.

所以如何让游戏在有限的输入下更有内涵也更复杂？在这个框架前提下的名词和动词，基本上有三种方式来增加游戏复杂性。我们可以添加一个新的输入，我们可以使用现有的输入添加一个新的动词或者我们可以把现有的动词赋给更多的名词，用新的意义来渲染动词。第一个选项是通常会增加了复杂性这不是我们希望看到的，但是其他两个处理恰当的时候可以非常有效。让我们看看一些手机游戏的例子，使用这些方法后在没有改变核心游戏交互情况下增加了额外的深度。

### Hundreds
The game [Hundreds](http://playhundreds.com)[^1] is a great example of adding in new verbs without complicating the way you perform the game's verbs.

[Hundreds](http://playhundreds.com)[^1]就是一个很好的例子，在不增加游戏动词复杂性下增加新的动词。

![Hundreds in action](http://img.objccn.io/issue-18/Hundreds.png)

Initially, the only verb at your disposal is "touch a bubble to grow it." As the game progresses, new types of objects are introduced: bubbles that slowly deflate over time, spiky gears that puncture anything they touch, ice balls that freeze bubbles in place. It would be easy for this to become overwhelming to the player, but crucially, nothing ever breaks the input model of "tap an object to do something to it." Even though the number of possible verbs balloons to a pretty large number, they cohere in a way that keeps it simple. The interaction between these elements is rich — moments such as using the ice balls to freeze the dangerous gears, rendering them harmless, are particularly satisfying — but the fundamental way you interact with the system stays simple.

最初，”触摸气泡使增长。”是唯一一个需要处理的动词，随着游戏的发展，介绍了新类型的对象：气泡，慢慢地随着时间时间推移而缩小，齿轮会刺穿他触碰到的物体，冰球会冻结气泡。很容易就会压倒玩家，但至关重要的是，没有打破“点击一个对象去做什么的规则”，尽管可能气球的动词数量级相当大，他们凝聚的方式却令其简单。这些元素丰富，时刻交互，比如使用冰球冻结危险的齿轮，使其无害，尤其令人满意，但与系统交互的基本方法依然相当简单。

### Threes
The puzzle game [Threes](http://asherv.com/threes/)[^2] exemplifies the other approach, managing to layer in complexity and strategy without making any changes to the things you can do in the game.

益智游戏 [Threes](http://asherv.com/threes/)[^2] 体现了另一种方法，管理层在复杂性和策略在比赛中你能做的事情没有做出任何改变，

![How to play Threes](http://img.objccn.io/issue-18/THREES_trailer.gif)

Throughout the game, its rules remain completely constant. From beginning to end, the only verb in your tool belt is "swipe to shift blocks over," with no variation at all. Because of the way the rules of the system create new objects at a predictable rate, complexity emerges naturally as a result of progression. When the screen only has a few low-numbered blocks at the beginning of the game, decisions are easy. When you're balancing building up lower-level numbers with managing a cluster of higher numbers, that same one verb suddenly has a lot more meaning and nuance behind it.

在这个游戏中，它的规则保持不变，从开始到结束，唯一的变量是“滑动滑块”，除此之外没有任何变化。这是因为系统规则在可预测速度以及复杂性下创建新的对象出现的自然结果。当游戏开始的时候屏幕上只有少量小数字的方块，做决定非常容易。当你开始平衡底层数字建立新的更高数字的时候，同样一个动词背后就有了更多意义和细微差别。

Both of these are great examples of games that manage to offer simplicity on the surface but great depth underneath by carefully managing where and how they add complexity and meaning to their verbs. The approach between the two might be different, but both do a laudable job of shifting some of that complexity away from the lowest levels of the game to make them more accessible.

这两个都是伟大的游戏，能提供表面简单但极有深度下通过精心的管理，以及他们如何增加了复杂性和意义的动词。两者之间的方法可能不同，但都做一个值得称赞的工作转移一些复杂性使其远离入门级别，使它们更容易上手。

## Elegance
## 优雅

We've now explored two different lenses we can use to think about designing games. Thinking about your systems in terms of nested feedback loops, and managing the relative lengths of one iteration of each loop, can help you design something that is fun for both 10 seconds and an hour at a time. Being cognizant of the way you add complexity to your game through the way you handle your game's verbs can help you increase your game's strategic depth without sacrificing accessibility to new players.

现在我们已经通过两个不同的角度探索了设计游戏。思考你系统的反馈循环，以及管理相对长度的迭代，可以帮助设计不管是10秒钟还是1个小时都很有趣的东西。你增加了对复杂性的认识，通过处理你游戏的动词可以帮助你不牺牲获取新玩家的前提下，增加战略深度。

Ultimately, these two concepts explore similar ground: the idea that gameplay depth and systemic complexity, while related, are not necessarily equivalent. Being conscious about at what layer of your game the complexity lies can help make your games as accessible as possible to new players, and encourage short pick-up-and-play game sessions without sacrificing depth or long-term engagement.

最终，这两个概念展示了类似的结果：游戏的深度和系统性的复杂性，虽然相关，却不一定是等价。关注在你的游戏的复杂性在于可以帮助使你的游戏尽可能多的获得新玩家，并鼓励游戏[拿起就玩](http://gaming.wikia.com/wiki/Pick_up_and_play)却不失深度或者长时间娱乐。

Again, neither of these concepts is particularly new to the world of game design. In particular, design blogger Dan Cook talks a lot about nested feedback loops in his article, ["The Chemistry of Game Design,"](http://www.gamasutra.com/view/feature/129948/the_chemistry_of_game_design.php) and Anna Anthropy and Naomi Clark's book, ["A Game Design Vocabulary,"](http://www.amazon.com/Game-Design-Vocabulary-Foundational-Principles/dp/0321886925) has an insightful exploration of what it means to conceptualize your game in terms of verbs.

再次声明，这些概念在游戏设计世界并不是新东西。特别是，设计博客作者 Dan Cook 在他的文章 ["The Chemistry of Game Design,"](http://www.gamasutra.com/view/feature/129948/the_chemistry_of_game_design.php) 中谈到了很多嵌套反馈循环以及 Anna Anthropy and Naomi Clark's book 的书  ["A Game Design Vocabulary,"](http://www.amazon.com/Game-Design-Vocabulary-Foundational-Principles/dp/0321886925) 中提到深入探索游戏的动词概念化背后意味着什么。

But these problems are exacerbated on mobile. The mobile context makes it vital to keep your lowest-level loops and arcs as short and self-contained as possible, without losing sight of the bigger picture. The practicalities of touchscreen controls make adding complexity and nuance at the input level difficult, making it that much more important that your more higher-level systems can still provide rewarding advanced play for experienced players. The unforgiving nature of mobile games means that elegance in design isn't merely ideal, but a necessity; recognizing that simple doesn't have to equal shallow is vital to designing good mobile games.

但这些问题在移动平台更恶化。移动平台背景使它重要的让你的最低层级循环和弧在没有损失的更大的场景下尽可能短而独立的。触摸屏控制的实用性使增加的复杂性和微差别在困输入级难，使它更加重要，你更高级的系统仍然可以提供有益的先进经验丰富的玩家。手机游戏的无情的本质意味着优雅的设计并不仅仅是理想的，但是必要的；认识到简单并不等于浅设计好的手机游戏至关重要。


[^1]: The basic concept of Hundreds is simple: each level has a bunch of bubbles bouncing around, each with a number inside it. The larger the number, the bigger the bubble. While you are touching a bubble with your finger, it turns red, grows larger, and its number increases. When you stop touching it, it stops growing and turns black again, but it maintains its new number and size. Once the sum of all on-screen bubbles is at least 100, you've beaten the level. However, if a circle touches another circle while it is red (i.e. being touched), you need to restart.

[^1]: Hundreds 的概念非常简单，每一关你有一群气泡可以互相碰撞，每一个里面包含了一个数字，数量越大，气泡越大。当你用手指触摸一个气泡，它变成红色同时变得增大，其数字持续增加。当你停止触摸，它停止增大并且再次变成黑色，并停在在现有数字和规模，一旦屏幕上的泡沫的总和至少100，表示你过关了。然而，如果一个圆接触另一个圆虽然是红色的(比如触摸)，您需要重新开始。

[^2]: If you don't know Threes, you might instead be familiar with the more popular clone, [2048](http://gabrielecirulli.github.io/2048/). Threes presents you with a 4x4 game grid with a few numbered squares, where every square's number is either a 1, a 2, or a 3, doubled some number of times (3, 6, 12, 24, etc.). When you swipe in any direction, every square that is capable of doing so will shift over one space in that direction, with a new square being pushed onto the game board in an empty square from the appropriate side. If two squares of the same number are pushed into each other, they will become one square whose number is the sum of them together (1s and 2s are different; you must combine a 1 and a 2 to get a 3). When you can no longer move, your score is calculated based on the numbers visible on the board, with higher numbers being worth disproportionately more than lower ones.

[^2]: 如果你不知道什么是 Three, 你也许知道另一个很成功的复制游戏， [2048](http://gabrielecirulli.github.io/2048/)，Three 在一个 4x4 的网格中进行，其中包含一些含有数字的方块，数字可能是1，2或者3，翻了一倍的数字(3, 6, 12, 24, 等。)当你手朝任何方向滑动，每个方块朝着对应的方向移动，一个新的方块会被推到适当的空白处。如果两个方块是相同数字那么它们将相加合并并推到角落（1s 和 2 s 是不同的，你必须结合一个1和一个2来获得一个3）。如果你无处可移，那么你的分数将是面板上分数的总和，更大的数字的价值远远大于小的数字。