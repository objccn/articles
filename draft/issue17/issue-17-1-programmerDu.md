---
title: Why Security Still Matters Today
category: "17"
date: "2014-10-10 11:00:00"
author: "<a href=\"http://twitter.com/secboffin\">Graham Lee</a>"
tags: article
---


As this article was being written, systems administrators were rushing to ensure their networks were robust against [CVE-2014-6271](http://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2014-6271), also known as "Shellshock." The vulnerability report on this bug describes the ability to get the `bash` shell, installed on most Linux and OS X systems (and, though most people are unlikely to use it there, on iOS too), to run functions under the attacker's control. Considering that security has been a design consideration in software systems at least since the [Compatible Time-Sharing System](http://publications.csail.mit.edu/lcs/pubs/pdf/MIT-LCS-TR-016.pdf) (CTTS) of the 1960s, why isn't it a solved problem? Why do software systems still have security problems, and why are we app developers told we have to do something about it?

在写这篇文章的时候，系统管理员们正忙于确保自己的网络足以应对[CVE-2014-6271](http://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2014-6271)，也就是所谓的“Shellshock”漏洞。攻击报告表明通过漏洞可以获得`bash`shell的权限，因此bash可以在攻击者的控制下运行功能。而bash shell广泛存在在大多数Linux以及OS X系统中（在iOS中也有安装，虽然大部分人都不太可能使用）。既然从1960年代设计[相容分时系统](http://publications.csail.mit.edu/lcs/pubs/pdf/MIT-LCS-TR-016.pdf)（CTTS）时就已经开始考虑安全性，为何到现在这个问题都没有解决？为什么软件系统仍有安全问题？又是为什么我们应用开发者被告知我们在安全上必须有所行动？

## Our Understanding Has Changed
## 我们所了解的已经变化

The big challenge faced by CTSS — which informed architectural decisions in later systems, including the UNIX system from which OS X and iOS are derived — was to allow multiple people to access the same computer without getting in each other's way. The solution was that each user runs his or her own tasks in an environment that looks like a real computer, but in fact is a sandbox carved out of a shared computer.

CTSS所面临的最大挑战是允许多用户访问同一台计算机而互不干扰，这也影响了之后系统的架构设计，其中也包括衍生了OS X和IOS的UNIX系统。解决的办法是，每个用户在一个仿佛是真实电脑的环境中独立运行任务，但实际上却使用的是共享计算机生成的一个沙箱。

When one user needs substantial computing resources, the program shouldn't adversely affect the resources of the other users. This is the model that leads to multiple user accounts, with quotas and resource usages and accounting systems. It works pretty well: in 2006, I was using the same system to give more than 1,000 users access to a shared OS X computer.

当一个用户需要大量资源，这一解决方案应避免对其他用户的资源产生不利影响。而这个方案也导致了拥有配额资源的多用户账户以及账户管理系统的出现。这种想法颇为有效：在2006年，我使用了同一个系统，让超过1000名用户访问了共享的OS X电脑。

Unfortunately, that view of the problem is incomplete. Technical countermeasures to stop one _account_ from using the resources allocated to another account often do not, in fact, stop one _user_ from using resources allocated to another user. If one user can gain access to the account of another, or can convince the other user to run his or her programs, then the accounting and permissions system is circumvented. That is the root problem exposed in the Shellshock vulnerability: one user can get another to run his or her program with the permissions and resources normally available to the victim.

不幸的是，当初对这个问题的看法并不完整。那些防止一个 _账户_ 使用分配给其他账号的资源的技术手段，往往并不能防止一个 _用户_ 使用分配给其他用户的资源。如果一个用户可以获得其他账户的权限，或者能说服其他用户运行自己的程序，那账户和权限系统将可以被规避。这也是Shellshock漏洞所暴露的问题的根源：攻击者可以获得受害者的权限和资源来运行自己的程序。

## The Problem Has Changed
## 问题也已经变化

In the time since UNIX was designed, computers have become smaller, faster, and better connected. They've also found uses in more and more situations that weren't foreseen when the software that supports those situations was created. Electronic mail as an effectively public, plain-text system was OK when every user of the mail system worked for the same university, and every terminal was owned by that university. However, supporting communication between people in different organizations, in different locations, and on different networks is a different problem and requires different solutions.

从UNIX设计的时代开始，计算机就开始变得更小、更快和更容易连接。但他们还发现越来越多情况是软件创建时所没有遇见的。当电子邮件的所有用户都在同一所大学，且所有终端都归大学所有时，作为一个有效且公开的纯文本系统，它能良好的运行。但是当它要支持来自不同组织、不同地点甚至不同网络的人进行沟通时，就需要不一样的解决方案了。

In one way, iOS is still a multi-user system. Unlike the environment in which UNIX was designed, all of the users have access to the same account that's operated by the phone's owner. Those users are the owners themselves: you, me, all the other app developers whose products are installed on the phone, and Apple.

在某种程度上，iOS仍然算是一个多用户系统。与UNIX设计的环境不同，iOS所有用户访问的都是和手机持有者同样的账户。所有这些用户都是手机的持有者自己，他们包括：你、我、手机上所装应用的开发者以及苹果。

That's actually a bit of an oversimplification, because many apps aren't the sole work of the developers who submitted them to the store. SDKs, remote services like analytics, and open-source components mean that many apps actually contain code from multiple organizations, and must communicate over networks that are potentially being surveilled. The game is no longer to protect different people at the same computer from each other, but to protect one person's different _tasks_ from each other.

这的确有点过于简单粗暴，毕竟许多应用的功能不止局限于开发者提交到应用商店的那些。SDK、远程分析服务以及开源组件意味着许多应用中实际上包含了来自多个机构的源码，并且必须通过网络进行通信就有潜在被监视的风险。游戏规则已经不再保护不同的人彼此使用同一台计算机，而是保证同一个人的不同 _任务_ 不会互相干扰。

This all sounds pretty negative, perhaps like a mild form of paranoia. The reality is that security can be an _enabling_ force, because it reduces the risks of new scenarios and processes to make them accessible to people in a wider range of contexts. Imagine how much more risky mobile banking would be without the availability of cryptography, and how few people (or even banks) would participate.

这些听起来都很消极，就像是一个温和的偏执狂。现实情况是，安全 _能够_ 成为推动力量，因为它减少了在新的场景和过程中的风险，为人们进入更广阔的空间提供了可能。想象一下没有使用密码学，移动银行业务将会增加多少风险，而又会有多少人（甚至包括银行）将会开展这项业务。

## …While Some Things Stayed the Same
## ......尽管有些事情依然没变

The only reason that UNIX is still at all relevant to modern discussions of software security is that we haven't gotten rid of it, which is mainly because we've never tried. The history of computing is full of examples of systems that were shown to suffer from significant security problems, but which are still in use because the industry is collectively bad at cleaning up its own mess. Even on the latest version of iOS, using the latest tools and the latest programming language, we can use functions like those in the C string library that have been known to be broken for decades.

UNIX仍然与现代的软件安全讨论息息相关的唯一原因是，我们仍然没有摆脱这个系统，这主要是因为我们从来都没有尝试过。计算的历史充满了这样的例子，明明有些系统已经暴露出重大的安全问题，但它依然在使用，因为这个行业在清理自己烂摊子方面集体表现都很差。即使是最新版本的iOS，拥有最新的工具和最新的编程语言，我们在其中所调用的方法，例如C语言的字符串库，也被认为在几十年前就需要被重构。

At almost every step in the evolution of software systems, patches over existing, broken technology have been accepted in favor of reinventions designed to address the problems that have been discovered. While we like to claim that we're inventing the future, in fact, we spend a lot of time and resources in clinging onto the past. Of course, maybe _replacing_ these systems would reintroduce a lot of the problems that we _have_ already fixed.

在软件系统的演变史中，几乎每一步所产生的补丁都比现有的要多，接受不完整的技术有利于定位已发现的问题。虽然我们喜欢声称我们发明了未来，而实际上，我们花费了大量时间和资源来坚守过去。当然，也许 _更换_ 这些系统也会引入许多我们 _已经_ 修复的问题。

## Apple Can't Solve Your Problems
## 苹果不能解决我们的问题

Apple tells us that each version of iOS is more secure than the last, and publishes a white paper [detailing the security features of its systems](https://www.apple.com/privacy/docs/iOS_Security_Guide_Sept_2014.pdf). Apple explains how it's using ever-newer (and hopefully more advanced) cryptographic algorithms and protocols, stronger forms of identification, and more. Why isn't this enough?

苹果告诉我们每一个版本的iOS都比过去更安全，甚至公布了一份系统安全特性细则的白皮书。在其中苹果介绍它如何使用了不断更新的（希望是更加先进的）加密算法和协议，更健壮的鉴定表单以及其他技术。难道这样不就够了吗？

The operating system security features can only make provisions that apply to _any_ app; they cannot do everything required to support _your_ app. While Apple can tell you that your app connected to a server that presented _some_ valid identity, it cannot tell you whether it is [an identity _you_ trust](http://www.securemacprogramming.com/SSL_handout.pdf).

操作系统只能提供适用 _任何_ 应用的安全特性；但不能提供 _你的_ 应用所需的一切。虽然苹果能告诉你，你的app连接到了一个提供了一些有效身份证明的服务器，但它不能告诉你这是否是一个[值得你信任的身份](http://www.securemacprogramming.com/SSL_handout.pdf)。

Apple can provide file protection to encrypt your data, and unlock it when requested. It cannot tell you _when_ it's appropriate to make that request.

苹果可以提供文件保护来加密你的数据，并且在收到请求时解锁。但它不会告诉你 _什么时候_ 适合进行请求。

Apple can limit the ways in which apps can communicate, so that data is only exchanged over controlled channels like URL schemes. It can neither decide what _level_ of control is appropriate for your app, nor can it tell what _forms_ of data your app should accept, or what forms are inappropriate.

苹果可以限制应用之间的沟通方式，使得数据只能在受控的方式如URL scheme中进行。苹果既不能决定哪个 _级别_ 的控制适合你的应用，也不能告诉你你的应用应该接受什么 _形式_ 的数据，以及不合适什么形式的数据。

## You Can't Either (Not Entirely, Anyway)
## 你不能不管（至少不能完全不管）

Similar to operating system features, popularity charts of [mobile app vulnerabilities](https://www.owasp.org/index.php/Projects/OWASP_Mobile_Security_Project_-_Top_Ten_Mobile_Risks) tell you what problems are encountered by _many_ apps, but not which are relevant to _your_ app, or _how_ they manifest. They certainly say nothing about vulnerabilities that are specific to the uses to which _your customers_ are putting _your app_ — vulnerabilities that emerge from the tasks and processes your customers are completing, and the context and environment in which they are doing so.

和操作系统的特性相似，[移动应用程序漏洞](https://www.owasp.org/index.php/Projects/OWASP_Mobile_Security_Project_-_Top_Ten_Mobile_Risks)排行榜能告诉你哪些问题是 _许多_ 应用都遇到的，但却不能告诉你具体哪些和 _你的_ 应用相关，以及它们是 _如何_ 暴露的。它们也绝对不会告诉你当 _你的用户_ 使用 _你的应用程序_ 时漏洞被利用的详细情况---漏洞从执行的任务、上下文和环境中产生并且随着用户操作的过程中执行。

Security is a part of your application architecture: a collection of constraints that your proposed solution must respect as it respects response time, scale of the customer base, and compatibility with external systems. This means that you have to design it into your application as you design the app to operate within the other constraints.

安全是你应用程序架构的一部分：它是一个约束集合，它尊重响应时间、客户群规模并兼容外部系统，因而你提出的方案也必须尊重它。这意味着你必须将安全模块设计到你的应用中，就像你设计应用时遵循的其他约束条件一样。

A common design technique used in considering application security is [threat modeling](http://msdn.microsoft.com/en-us/magazine/cc163519.aspx): identify the reasons people would want to attack your system, the ways in which they would try to do that with the resources at their disposal, and the vulnerabilities in the system's design that could be exploited to make the attack a success.

一个评估应用安全常用的设计技巧是[风险建模](http://msdn.microsoft.com/en-us/magazine/cc163519.aspx) ：找到黑客们想要攻击你系统的原因，查出他们在使用现有的资源下的攻击方式，以及探索在系统设计中的可能被成功攻击的漏洞。

Even once you've identified the vulnerabilities, there are multiple ways to deal with them. As a real-world analogy, imagine that you're booking a holiday, but there's a possibility that your employer will need you to be on call that week to deal with emergencies, and ready to show up in the office. You could deal with that by:

 - accepting the risk — book the holiday anyway, but be ready to accept that you might not get to go.
 - preventing the risk — quit your job, so you definitely won't be on call.
 - reacting to the risk — try to deal with it once it arises, rather than avoiding it in advance.
 - transferring the risk — buy insurance for your holiday so you can reschedule or get a refund if you end up being called in.
 - withdraw from the activity — give up on the idea of going on holiday.
 
 即便你已经确定了漏洞，还是要使用许多方法来应对。拿个现实生活中的例子打比方，假设你正申请一个假期，但在这周你老板仍有需要你保持联系甚至随时准备出现在办公室以应对紧急情况的可能性。你可以做如下应对：

接受风险 - 无论如何仍然申请假期，但愿意接受你可能去不了的风险。
预防风险 - 辞掉工作，这样你绝对不会被电话骚扰。
对风险作出反应 - 风险发生的时候试着马上解决它，而不是提前回避它。
转移风险 - 为你的假期购买保险，如果它因为接到电话而结束，你可以重新安排一个假期或者获得退款。
放弃行动 - 放弃度假的想法。

All of these possibilities are available in software security, too. You can select one, or combine multiple approaches. The goal is usually not to _obviate_ the risk, but to _mitigate_ it. How much mitigation is acceptable? That depends on how much residual risk you, your business, your customers, and your partners are willing to accept.

所有这些可能性也都可以在软件安全中使用。你可以选择一个或者结合多个方法。我们的目标通常是不是 _规避_ 风险，而是 _减轻_ 风险。风险减轻到多少是合理的？这取决于你、你的公司、你的客户和你的合作伙伴能够接受剩余多少风险。

Your mitigation technique also depends on your goals: What are you trying to achieve in introducing any security countermeasure? Are you trying to protect your customers' privacy, ensure the continued availability of your service, or comply with applicable legislation? If these goals come into conflict, you will need to choose which is most important. Your decision will probably depend on the specific situation, and may not be something you can design out in advance. Plenty of contingency plans are created so that people know what to do when something bad happens…_again_.

你缓解风险的技术同样取决于你的目标：当你可以引入任何安全对策时你想要达到什么目标？你们是要保护客户隐私、保证服务的持续可用性还是只要遵循相应的法律？如果这些目标冲突，你需要比较它们的优先级。你的决定可能取决于具体情况，未必是你能提前设计出来的。建立充足的应急预案能让大家在又发生不好的事的时候知道如何处理。

## Conclusion
## 结论

Despite advances and innovations in software security technology and the security capabilities of systems like iOS, risk analysis and designing security countermeasures are still the responsibility of app developers. There are threats and risks to the use of our applications that cannot possibly be addressed by operating system vendors or framework developers. These threats are specific to the uses to which our apps are put, and to the environments and systems in which they are deployed.

尽管软件安全技术和系统（比如iOS）的安全保障能力一直在进步和创新，但风险分析和设计安全对策依然是应用开发者们的责任。那些使用我们应用时所产生的风险是不可能通过操作系统供应商或者框架开发人员解决的。这些风险是由应用所提供给用户的功能，或者应用部署的环境或系统中产生。

With the security and cryptography features of the iOS SDK, Apple has led us to the water. It's up to us to drink.

苹果用iOS SDK中的安全和加密功能帮助我们找到了水源。而喝水的事情，得靠我们自己。
