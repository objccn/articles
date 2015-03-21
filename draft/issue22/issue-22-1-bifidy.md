# Inside Omni
# Omni 内部

The Omni Group is an employee-owned company where people bring their dogs to work.

Omni 工作组是一家员工持股的公司，在这里，人们可以带他们的狗来上班。


In other words: when you think about managing large projects, think about culture *first*. It almost doesn’t matter what the details are — how we’re organized, what we use for source control management, and so on — because a great culture makes for a happy team that will figure out how to work together. And Omni has done a *great* job with that.

换句话说：当你考虑如何管理大型项目时，**首先**得考虑文化 。“我们如何组织项目？用什么样的源代码控制管理？” 文化并不纠结于这些细节，一个优秀的文化会形成一个快乐的团队，他们将弄清楚如何一起工作。而 Omni 于文化的工作可谓**丰硕**。

Omni’s culture deserves an article of its own, but I’m not going to get into culture much. Instead, this is an engineering-centric tour of the details of how we manage our apps.

Omni 的文化可以另撰一篇长文，但在这里不打算涉及太多。相反，这里是一次围绕着技术的游历，着重于讨论我们如何管理自己的 App。

## Flat Organization

## 组织扁平化

All engineers report to Tim Wood, CTO and founder. Each product has a project manager.

所有的工程师向 Tim Wood 进行汇报，他是 Omni 的 CTO 和创始人。每个产品都有一个项目经理。


Teams for the various apps are fluid. They don’t change often or willy-nilly, but they do change.

各个 App 的项目组是流动的，他们不常变动，有时也被迫改变，不过它们终究是会变的。


## In-House Communication

## 内部交流

People talk face-to-face, since everybody works at the office. There are meetings from time to time, some regularly scheduled, some not. Everybody attends the weekly all-hands meeting, which lasts for around 20 minutes, where section heads and project managers report on how things are going. It’s followed by the weekly engineering meeting, which also lasts around 20 minutes. Most of the engineering reporting is about things of general interest (as opposed to catching up on what each person is doing, though there’s some of that too).

只要大家都在办公室工作，我们会面对面的沟通。有时会召开会议，一些安排好的，一些则是临时决定。每个人都会参加一周一次的全体员工大会，时间大约是20分钟。主要部门主管和项目经理说明接下来的工作方向。在之前还有每周的开发会议，这也持续约20分钟。讨论一些大家普遍关心的开发事项（用于规避逐个找人沟通，虽然有时还是不得不这样做）。

Face-to-face communication is helped by Omni’s core hours: people are expected to be in the office 11 a.m. to 4 p.m. every day, so you know that you can find people during that period. (Otherwise, you can come in and leave as early or late as you want, as long as you put in a full week of work.)

面对面的交流得益于 Omni 的核心工作时间：人们希望每天早上11点到下午4点的时间都在办公室内度过，所以你知道你可以在那个时间里找到想找的人。（不过，你也可以来的或早或晚，随你心意，只要你在工作上投入了一整周的时间。）

Then there’s email, including several mailing lists, and our internal chatroom-plus-direct-messages thing. (We recently replaced Messages and Jabber with a system that actually remembers history. And allows animated GIFs.)

其它途径的话，包括 E-mail，包括一些邮件列表，和我们内部的聊天室。（我们最近将 Message 和 Jabber 替换为了一套可以保存历史记录的系统，它还可以播放 GIF。）

## Bugs

## Bug

Every engineering organization larger than zero people revolves around its bug tracker. Omni uses a housemade Mac app named OmniBugZapper (OBZ) that has the features you’d expect. It’s not polished the same way the public apps are, but it is nevertheless an effective tool.

每一个开发组织都有至少一个人负责解决 Bug 追踪系统中反馈的问题。Omni 使用了一个内部的 Mac 应用 OmniBugZapper(OBZ) ，它具有那些你期望拥有的功能。它不像一些公开应用那样瞩目，但它却是一个很有用的工具。

A typical workflow goes like this: you look at the bugs in your current milestone, pick one with a high priority, and then open it so that people can see you’re working on it.

（在OmniBugZapper中的）一个典型的工作流是：你在当前阶段发现了一个 Bug，将它的优先级调为高，然后打开它，使其他人可以看见你正在解决这个 Bug。

Once it’s finished, you add a note to the bug saying what you did to fix it, and perhaps add a note on how to test it, and you include the SCM revision number.

一旦问题解决，你在这个 Bug 上添加一条笔记说明你已经搞定了，或许也会说明如何去测试，然后你写上了 SCM 中的修改序号。

You switch the status to Verify — and then a tester takes over and makes sure the bug really is fixed. It could get reopened if it’s not actually fixed. If the fix creates a new bug, then a new bug is added to OBZ.

你将 Bug 的状态切换为“验证”，然后一位测试接收并确定 Bug 是否真的被修复了。如果没有被解决，它可能会重新被打开。如果修复衍生出了一个新的 Bug，一个新的 Bug 会被添加至 OmniBugZapper。

Once a bug in Verify status passes testing, it gets marked as Fixed.

一旦处于“验证”状态的 Bug 通过了测试，它会被标记为“已解决”。

(Worth noting: the relationship between engineers and testers is not adversarial, as I’ve heard it is in some companies. There are moments when you may think the testers want to kill you with work — but that’s normal and as it should be. It means they’re doing a great job. We all have the exact same goal, which is to ship great apps.)

（前方高能：开发者与测试者之间的关系并非敌对，虽然我已经在几家公司听说过类似的事情。有些时候当你觉得测试的工作就是折磨你，但这才该是常态。这意味着他们做了了不起的工作，我们都有着同样的目标，那就是做一个棒棒的应用出来。）

There are some bug fixes that require an engineer to verify, but these are relatively rare; most bugs are verified by testing. (The engineer who verifies a bug can’t be the same engineer who fixed it.)

有一些 Bug 的修复需要工程师来验证，但这比较少见。大部分 Bug 是通过测试来验证的。（验证的工程师与修复的工程师不可以是同一个人。）

Some bugs are never intended to be fixed or verified. There are discussion bugs, where we talk about a change or addition, and there are reference bugs, which document behavior and appearance of a feature.

有些 Bug 是不会被优先修复或者验证的。在我们讨论一些改动和开发增量时，有些 Bug 也在其中，有一些提及到的 Bug，会转变为预示新功能出现的记录。

## Milestones

## 阶段管理

OmniBugZapper has the concept of milestones, of course, and it has a Milestones Monitor window where you can see progress and status of current milestones.

OmniBugZapper 有阶段管理的功能，自然，它有一个阶段监视器窗口，我们可以看到当前阶段的进度和状态。

Each milestone has triage, planned, and verify categories. Bugs are triaged and become planned, or put off till later.

每一个阶段都划分为分析、计划和验证。Bug 会经过分析变为计划，或者留至以后解决。

The process of deciding which bugs and features go into which milestone and into which release is collaborative, and everybody who wants to participate does participate. That said, project managers make many (if not most) of the decisions. For the bigger issues, there is often more discussion, and we often reach consensus — but we don’t make design decisions by voting, and CEO Ken Case has the ultimate authority. Ken creates the roadmap.

决定一个 Bug 或者功能的开发阶段与发布版本是合作式的，每一个想要参与的人都可以参加。通常，项目经理会做大部分的决定。在比较大的问题上，会有更多的决定要做，我们一般会达成共识，不过我们不通过投票决定设计问题，我们的 CEO，Ken Case，有最终决定权。Ken 负责规划未来。

>译者注：Milestones 可被翻译为里程碑图，是项目管理中的一种工具。为明确其功能，此处翻译为阶段管理，而每一个 Milestone 则被翻译为阶段。

## SCM

##SCM （源代码控制管理）

We use Subversion. All the apps and the website are in one giant repository. I wouldn’t be surprised if everybody’s working copy is just a partial version, rather than the entire thing.

我们使用 SVN。所有的应用与网站都在一个巨型的代码仓库中。我丝毫不惊讶于每个人的开发副本只是其中的一部分，而非全部。

You might think Subversion is unfrozen caveman engineer stuff, and it wouldn’t surprise you to learn that people have thought about switching. But Subversion gets the job done, and there’s something to be said for the simplicity of managing one big repository for everything.

你可能会觉得 SVN 是一个还未封印的史前工程师产物，并好奇人们关于切换工具的考虑。不过 SVN 干的还不错，如何简单的管理一个大型仓库的一切，总有些值得讨论的事情。

We have a number of scripts that help with this. For instance, when I want to get the latest changes to OmniFocus, I type <code>./Update OmniFocus</code> and it updates my working copy (I usually do this once a day, first thing). I don’t have OmniGraffle in my working copy, since I haven’t had a need to look at it. But I could get it by typing <code>./Update OmniGraffle</code>.

我们有很多个脚本帮助我们做这些工作。比如，当我想得到 OmniFocus 的最后一次更改，我输入`./Update OmniFocus`，然后它会更新我的开发副本（通常我每天第一件事就是做这个）。我的开发副本中没有 OmniGraffle，只因为我不需要关注它。但我也可以使用 `./Update OmniGraffle`。

Subversion may not make branching as easy as Git and Mercurial do, but it’s not like it’s crazily difficult, either. We make a branch when an app gets close to release, in order to protect it from other changes. People make private branches and directories whenever they want to for whatever reason.

SVN 创建分支可能不像 Git 与 Mercurial 那样方便，但也没有那么困难。每当我们的应用接近发布时，我们会建立一个分支，用于隔离其它的变动。人们可以出于各种目的随时创建私人分支与目录。

Commit messages are sent via email to engineers and everybody else who wants them.

提交信息通过 E-mail 发送给工程师和其它关注项目的人。

## Crashes

## 崩溃

Since apps sit at the top of a mountain of system frameworks that have their own bugs, and since apps run not on an ideal machine but on actual people’s computers, there’s no way to guarantee that an app will never crash.

由于应用被置于大量有着自身缺陷的系统框架上层，而实际用户的电脑并非应用的理想运行环境，所以无法保证一个应用从来不会崩溃。

But it’s our job to make sure that *our* code doesn’t crash — and that if we note a crashing bug in system frameworks, we find a way to work around it.

不过我们的工作就是确保**自己的**代码不会崩溃，如果我们发现系统框架中有一个会导致崩溃的 Bug，我们需要找到方法绕过它，以让代码正常工作。

We have stats and graphs that show us how long an app goes, on average, before crashing. There’s another homemade app called OmniCrashSorter, where we can look at symbolicated crash logs, including exception backtraces and any notes from the user about what was happening when it crashed.

我们使用了一些图形化的统计来展示一个应用在崩溃之前的平均运行时间。我们还有一个内部应用叫做 OmniCrashSorter，我们可以看到一些被标记出来的崩溃日志，包括异常的追踪回执，与一些用户崩溃场景的记录。

Here’s the thing about crashes: unfortunately, apps never crash for the people writing the code (this seems to be a natural law of software development). This makes crash logs from users — and steps to reproduce — absolutely critical. So we collect these and make them easy to get to.

关于崩溃有这么一个扫兴的问题：崩溃永远不会在开发时出现（这似乎是一个软件开发中的铁律）。
这使得用户的崩溃报告需要事无巨细，以求得崩溃能够被复现。所以我们采集这些报告的同时，也需要让它们易于被查看。

And: we crash on exceptions, on purpose. Since our apps autosave, it’s safer to crash rather than try to recover and possibly corrupt data.

有时，我们会刻意使崩溃发生在异常中。因为我们的应用使用自动保存，崩溃会比可能出现的脏数据覆写更为安全。

## Code

## 代码

We have a small style guide, on our internal wiki, and I’ve already internalized it so I forget what it says.

我们有一点代码风格规范放在我们内部的 wiki 上，而我因为早已熟练的应用，反而忘了它说的是什么。

Except for this one thing. Methods should start like this:

除了这个之外，方法应当像这样开头：

```
- (void)someMethod;
{
```

It may not be widely known that that semicolon is allowed in Objective-C. It is.

或许并不是很多人都知道，在 Objective-C 中允许这样使用分号。不过它确实是允许的。

One of the points of this style is that it makes it easy to copy a prototype to the header file or class extension. Another is that you can select the entire line, cmd-E, and then do a find to look it up in the header file (or .m file if you’re going the other direction).

这种方式比较好的地方在于，它可以使我们很容易的将类的声明拷贝到头文件或者类的拓展当中。而且，你可以选择一整行，Command+E，然后查找包含它的头文件（或者回到你实现它的 .m 文件）。


I don’t love this. To me — a compulsive simplifier — the semicolon is an extra thing, and all extra things must be carved away. (How satisfying to imagine my X-ACTO blade slowly drawing a line around the ; and then, with a northeast flick, throwing it in the air, off the side of the desk, where it then flutters into the recycling bin.)

我不喜欢这个方式。对我这样一个极简主义强迫症来说，分号太多余了，而所有多余的事情都应该被去掉。（想象我的 X-ACTO 刻刀慢慢的绕着一个分号刻上一圈，伴随着一阵东北风，把它刮到空气中，离开我的桌子，然后散落进垃圾桶里，真是说不出的畅快。）

But this is just me idly complaining. The point — which I’m on board with, completely — is that we *have* a style guide, and everybody uses it, and we can read each other’s code without being tempted to argue the fine points of semicolon placement. We don’t get tempted to waste time reformatting existing code just to match our tastes.

不过这只是我闲暇时的想法。我想说的重点在于，我们**需要**一个代码规范，而且每个人都使用它。然后我们在阅读彼此的代码时，就不会被引诱着去争论关于分号的问题。我们不应该只为了比拼彼此的口味，把时间浪费在重新格式化已经写好的代码上。

### Shared Frameworks

### 共享框架

All of Omni’s apps are one big app, in a way; there are lots of shared frameworks they depend on. A bunch of them are open source, and you can [read about them](http://www.omnigroup.com/developer/) and [get the code from GitHub](https://github.com/omnigroup/OmniGroup). There are additional internal frameworks — some used by every app, some used by just some apps.

Omni 所有的应在某种程度上是同一个大型应用，因为它们依赖于很多个共享的框架。这些框架一部分是开源的，你可以[阅读相关的信息](http://www.omnigroup.com/developer/)，并[在GitHub上获取源码](https://github.com/omnigroup/OmniGroup)。还有一些额外的内部框架，一部分用在每一个应用中，还有一些则只用在部分应用里。

Shared frameworks make it easier to develop a bunch of different apps, and they make it easier to switch teams, since so much will be the same.

共享的框架使开发一些不同的应用变的更容易，而且开发组的替换也变的方便，毕竟大部分框架都是相同的。

There’s a downside, of course, which is that a change to a framework could break a bunch of apps all at once. But the only way to deal with that is to deal with it. Bugs are bugs.

当然，有一点不好的地方，是某个框架发生了变化可能一次性影响多个应用。不过解决这个问题的唯一方法就是解决它，Bug 就是 Bug。

(Since we do a branch when an app gets close to release, we have protection against framework changes during those last few weeks of development.)

（当项目快要发布时，我们会建立一个新分支，用来防止在接下来的几周中框架开发中产生的变化。）

### ARC

### ARC

New code is usually ARC code. There is plenty of older code that hasn’t been converted — and that’s mostly fine, because making changes to working, debugged code is something you do only when you need to. But sometimes it’s worth doing the conversion. (I’ve done some and will do more. I think it’s easier to write crash-free code using ARC.)

新的代码往往是基于 ARC 的。虽然有大量的旧代码还未被转换，但这是允许的。毕竟随着运行情况的变化，被调校的代码只应该是那些需要被校正的。不过有些时候它们依旧应该被转换。（我已经做过一部分关于转换的工作，以后还会做更多。我觉得使用 ARC 写出不会发生崩溃的代码会更容易一些。）

### Swift

### Swift

Though a bunch of engineers have written Swift code, Swift has yet to appear in any apps or frameworks.

虽然一批工程师已经开始编写 Swift 的代码，Swift 目前尚未出现在一些应用和框架中。

This could change tomorrow, or it might take a year. Or two. Or it might have changed by the time you’re reading this.

不过这也说不准，或许在一两年之后，或者就在你阅读本篇文章的当下，改变就会发生。

### Tests

### 测试

OmniFocus has unit tests that cover the model classes; other apps have more or less similar test coverage. The problem we face is the same problem other OS X and iOS developers face, which is that so much of each app is UI, and doing automated UI testing is difficult. Our solution for our Mac apps is AppleScript-based tests. (That’s one of the best reasons for making sure an app supports AppleScript, and writing tests is a good way to make sure that the support makes sense and works.)

OmniFocus 中有一个覆盖模型类的单元测试；其他应用也有差不太多的测试覆盖率。我们与其他 OS X 和 iOS 开发者面对面临的问题是相同的，每个应用的 UI 元素都很多，而做自动化的 UI 测试却很困难。我们的 Mac 应用的解决方案是基于 AppleScript 的测试。（这是确保应用支持 AppleScript 的主要原因之一，而为了确保该支持的功能状态正常，编写测试是一种很好的办法）

Tests will never be quite as important to Cocoa developers as to Ruby, JavaScript, and Python developers, since the compiler and static analyzer catch so many things that the compilers for scripting languages don’t catch.

对于 Cocoa 的开发者来说，测试并不像在 Ruby，JavaScrpit 以及 Python 的开发中那么重要，这主要是因为编译器和静态分析可以捕获到很多脚本语言捕获不到的问题。

But they’re important nevertheless.

不过它们依旧很重要。

### Assertions

### 断言

You can see a bunch of the assertions we use — OBASSERT_NOT_REACHED, OBPRECONDITION, OBASSERT, and friends — [in our repository](https://github.com/omnigroup/OmniGroup/blob/master/Frameworks/OmniBase/assertions.h).

你可以在[我们的代码](https://github.com/omnigroup/OmniGroup/blob/master/Frameworks/OmniBase/assertions.h)中看到我们正在使用的一些断言：OBASSERT_NOT_REACHED, OBPRECONDITION, OBASSERT，等等。

We use these to document assumptions and intentions. They’re for later versions of ourselves and for other engineers, and we use them liberally.

我们使用这些断言来表示一些推测和意图。它们是为了我们自己的以及其它工程师开发的后续版本中而编写的，我们大量的使用它们。


The downside to so many assertions is that you get failures, and you have to figure out why. Why is the code not working as expected? Is the assertion just wrong, or does it need to be extended or modified?

很多断言不好的地方在于你获取到失败的判定时，你不得不找到原因。为什么代码没有按照期望运行？是因为断言使用错误，还是代码需要被拓展或者修改？

There are moments when I look at a bunch of console spew and wonder if it’s a good idea. It is.

我花了一段时间查看了许多的控制台输出记录来确定这是不是个好方法，结论是，它是。

## Builds

## 构建 

### Xcode Organization

### Xcode 结构组织

Each app has a workspace file that includes OS X and iOS projects and embeds the various frameworks that it uses.

每一个 App 都有一个 workspace 文件，里面包括了 OS X 和 iOS 的项目，并嵌入了许多项目中使用的框架。

### Config Files

### 配置文件

We use .xcconfig files pretty heavily. You can see a bunch of them [in our repository](https://github.com/omnigroup/OmniGroup/tree/master/Configurations).

我们大量的使用 .xconfig 文件。你可以在[我们的代码](https://github.com/omnigroup/OmniGroup/tree/master/Configurations)中看到一大堆。

This is one of those things I haven’t used in the past, and haven’t had to even look at in my several months at Omni. They just work.

在 Omni 中，这是我之前没有使用过的东西，甚至好几个月都不曾看过，只知道它们可以正常的被使用。

### Debug Builds

### 调试构建

With OmniFocus, debug builds use a separate database and set of preferences, so developers don’t have to subject their real data to the contortions they put debug data through.

OmniFocus 使用独立的数据库和一些偏好设置进行调试版本的构建，所以开发者不需要担心真实数据被调试数据污染。

(Our other apps are document-based apps, so the exact same issue doesn’t apply, but some apps aside from OmniFocus also use separate app IDs for the debug builds.)

（我们其它的应用是基于文档的应用，所以并不完全适合上述方法，不过 OmniFocus 之外的应用也会使用独立的 App ID 来构建调试版本。）（译者注：防止 iCloud Drive 污染？）
### Static Analyzer

### 静态分析

Analysis is set to deep, even for debug builds. This is as it should be.

Analysis 按照其使用方式进行了深度配置，包括调试版本的构建。

### Automated Builds

### 自动构建

We have a build server, of course, and we’re alerted when builds break. There’s another in-house Mac app, OmniAutoBuild, where we can see the status of the various builds and see where they broke when they break.

我们有一个用于构建的服务器，当然，我们会在构建失败的时候得到提醒。OmniAutoBuild 是另一个内部使用的 Mac App，我们可以在软件中查看是什么导致了构建的失败。

Building full, releasable applications is done with scripts. And we can set flags so that builds go to the staging server, so external beta testers can download the latest test versions.

构建完整的、可发布的程序是由脚本完成的。我们会设置标记将构建好的版本放在演示服务器上，所以外部的试用版测试者可以下载最新的测试版本。

iOS betas go out through TestFlight.

iOS 的试用版则使用 TestFlight。

## No Magic

## 没有魔法

I wish I could say there are some secret incantations — I could just tell you what they are.

真希望我可以说自己有一些秘密咒语，这样我就可以把它们告诉你。

But, instead, managing large projects at Omni is like you think it is. Communication, defined broadly — talking in person, chatting, using OmniBugZapper, using assertions, doing code reviews, following coding guidelines — is the big thing.

不过，实际上，在 Omni 管理大型项目与你所想像的方式没什么差别。详细的沟通与定义 - 交流到人，聊天，使用 OmniBugZapper，使用断言，做 code review，遵守编码规范 - 这些很重要。

The next thing is automation: make computers do the things computers do best.

接下来的事情是自动化：让电脑做最擅长的事情。

But, again, the zeroth thing — the thing that comes before choosing a bug tracker or SCM system or anything — is company culture. Build one based on trust and respect, with great people, and they’ll want to work together on large projects, and they’ll make good decisions, and they’ll learn from the bad ones.

不过，回到最初，有一些事情是在选择 bug 追踪系统、 SCM 系统或者其它什么事情之前的，那就是公司文化。与优秀的人一起建立一个基于信任、尊重的环境，他们会做出更好的决定，并从坏决定中吸取教训。

The good news is that it’s all just work.

好消息是这些事情都还在进行中。

And lunches. Work *and* lunches. We all eat together. It makes a difference.

还有午餐，工作**与**午餐。我们都在一起吃饭，这会产生一些区别。

P.S. Many thanks to the folks at Omni who read drafts of this article and provided feedback: [Rachael Worthington](https://twitter.com/nothe), [Curt Clifton](https://twitter.com/curtclifton), [Jim Correia](https://twitter.com/jimcorreia), [Tim Ekl](https://twitter.com/timothyekl), [Tim Wood](https://twitter.com/tjw), and [Ken Case](https://twitter.com/kcase). Anything weird or wrong is my fault, not theirs.

另及，非常感谢 Omni 中阅读过这篇文章草稿并提出反馈的人们，[Rachael Worthington](https://twitter.com/nothe), [Curt Clifton](https://twitter.com/curtclifton), [Jim Correia](https://twitter.com/jimcorreia), [Tim Ekl](https://twitter.com/timothyekl), [Tim Wood](https://twitter.com/tjw), and [Ken Case](https://twitter.com/kcase)。如果有什么奇怪的错误，一定是我犯了错，不是他们。
