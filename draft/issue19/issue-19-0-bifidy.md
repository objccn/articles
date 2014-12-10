Welcome to objc.io issue 19: all about debugging.

欢迎来到 objc.io 的第19期：本期的内容是调试。

We're all making mistakes, all the time. As such, debugging is a core part of what we do every day, and we've all developed debugging habits — our own way of approaching the all-too-common situation where something is not working as it should.

我们在任何情况下都会犯错误。以此想来，我们每个工作日的核心部分都该是调试。而且，总会有代码不按照预定的方式去工作，而这种情况又实在太普遍。我们自己寻找这些代码的方法，也已演变成了我们调试的习惯。

But there's always more to learn about debugging. Do you use LLDB to its full potential? Have you disassembled framework code to glance under the covers? Have you ever used the DTrace framework? Do you know about Apple's new activity tracing APIs? We're going to take a look at these topics and more in this issue.

不过关于调试，总是有更多东西可学。你是否已经发挥出 LLDB 所有的潜力了？你是否已经吃透了框架代码并且窥见了底层？你可曾用过 DTrace 框架？苹果新发布的活动追踪 API 你又了解多少？在本期内容中，我们将详尽探讨以上的命题，只多不少。

Peter starts off with a [debugging case study](/issue-19/debugging-case-study.html): he walks us through the workflow and the tools he used to track down a regression bug in UIKit, from first report to filed radar. Next, Ari shows us the [power of LLDB](/issue-19/lldb-debugging.html), and how you can leverage it to make debugging less cumbersome. Chris writes about his [debugging checklist](/issue-19/debugging-checklist.html), a list of the many things to consider when diagnosing bugs. Last but not least, Daniel and Florian talk about two powerful but relatively unknown debugging technologies: [DTrace](/issue-19/dtrace.html) and [Activity Tracing](/issue-19/activity-tracing.html).

Peter 会以一个[调试用例的研究][1]作为开始：他为我们带来的是他在捕捉一个 UIKit 自身的 bug 时所用到的工作流程和工具，他正是使用这些手段把最初的用户报告转变为了向 Apple 提交的 radar。接下来，Ari 会向我们展示 [LLDB 的力量][2]，你可以利用它，使调试不那么麻烦。Chris 写的内容基于他的[调试核对清单][3]。这份清单列出了许多值得被关注的内容，你可以利用它们来诊断 bug。结尾处，Daniel 和 Florian 会讲解两个强大但是名不见经传的调试工具，[DTrace][4] 和[活动追踪][5]。

We'd love for you to never need all of this — but since that's not going to happen, we at least hope you'll enjoy these articles! :-)

我们希望你永远用不到以上内容。但人生不如意十之八九，仅愿你可以享受本期的文章！:-)

Best from a wintry Berlin,

来自柏林深冬的美好祝福，

Chris, Daniel, and Florian.

Chris，Daniel，与 Florian。

[1]:http://objccn.io/issue-19-1
[2]:http://objccn.io/issue-19-2
[3]:http://objccn.io/issue-19-3
[4]:http://objccn.io/issue-19-4
[5]:http://objccn.io/issue-19-5
