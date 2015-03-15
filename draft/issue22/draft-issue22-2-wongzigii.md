The Artsy mobile team is small, especially in contrast to the other teams in this issue of objc.io. Despite this, we’re notable for our impact on the community. Members of our iOS development team are — and have been — involved in almost all major open-source projects in the Cocoa community.

与 objc.io 的其他团队规模相比，Astsy 的团队组成比较简单。尽管如此，我们却有着一定的影响力。我们的团队成员都参加过著名和大型的 Cocoa 社区开源项目。

Artsy is striving toward a technology culture of what we call [Open Source by Default](http://code.dblock.org/2015/02/09/becoming-open-source-by-default.html). We’re [not the only ones](http://todogroup.org/blog/why-we-run-an-open-source-program-walmart-labs/). Something being open source may sound like a purely technical distinction, but it affects culture more than you might think. Open source isn’t just a setting on a GitHub repository — it’s a sentiment shared by everyone on our team.

Artsy 团队内部充满了我们称之为 [Open Source by Default](http://code.dblock.org/2015/02/09/becoming-open-source-by-default.html) 的技术氛围。我们不是[绝无仅有的一个](http://todogroup.org/blog/why-we-run-an-open-source-program-walmart-labs/)。开源一个项目有时候听起来更像获得了一个技术勋章，但是这个项目所影响到的东西可能会超出你的想象。开源不单单是创建一个 GitHub repository -- 同时也是我们团队成员的情感分享。

Our team intrinsically believes in the ideas of open source. Though our individual motivations vary — from a conviction in the power of education to a determination to help others see from giants’ shoulders — we all maintain the value of open source.

我们团队都信奉开源。尽管不同的东西使我们聚在一起 - 从坚信教育的力量到帮助其他人站在巨人的肩膀上看得更远 - 我们都从开源中受益匪浅。

Everyone on our team believes that unless there is a good reason to keep something secret, it should be open. That doesn’t just apply to code, either. We hold regular meetings on Google Hangouts On Air and invite anyone to join and ask questions. Our team is also [organized](https://github.com/artsy/mobile) using an open-source repository.

我们团队的每个人相信，除非的确有一个理由让你保密，否则你就应该把它开源。这种精神不单单对于代码。我们在 Google Hangouts On Air 定期举办交流会，邀请其他人参与进来和讨论问题。我们的团队也用一个开源的 repository 来[组织活动](https://github.com/artsy/mobile)。

--------

Our small team makes a conscious effort to contribute significantly to the Cocoa developer community. We do this in three ways:

我们这个小团队为 Cocoa 开发者社区作出了显著的贡献。我们以这三种方式贡献自己的力量：

1.We actively try to release components of our application that may be useful to others as open-source libraries.

1.我们经常会发布一些应用的组件，这些组件作为开源库可能会帮助其他开发者。

2.We use others’ libraries while sending feedback, bug reports, and pull requests.

2.在使用其他的库的同时，我们发送反馈，bug report 和 pull request。

3.We encourage all team members to be active in the broader community, through speaking, blog posts, or books.

3.我们鼓励所有的团队成员积极参加社区活动，包括演讲，写博客或者阅读相关的技术文章。

There are well-understood reasons to reduce the size and complexity of any given codebase. By writing small, well-tested components, we increase the overall stability and cohesion of our apps. Additionally, by writing reusable libraries, we reduce effort when building multiple apps.

有几个很好理解的原因为什么我们想要减少基本代码的规模和复杂度。我们通过编写小而稳定的组件来提高应用整体的稳定性和完整性。另外，通过可重用的库，我们在编写其他应用时也减少了工作量。

Artsy has three main iOS applications, along with some smaller side projects, so not having to reinvent the wheel with each new project saves time. Improvements or bug fixes to a library written for one app are easily shared with the others. We’ve done well in leveraging this strategy of reuse so far, but there is still room to improve.

Artsy 主要有三个应用，同时还维护着一些小的项目，当有新的项目时，可以避免重复造轮子从而节省时间。对于为了一个应用而创造的库来说，维护和修复漏洞是一件很值得分享的事。我们过去在代码重用的策略做得很好，但是仍然有很大提升的空间。

Dividing our applications into small, reusable pieces has a lot of technical advantages, but it also allows us to create distinct owners for the different components. When we do this, we need to make sure that we consciously spread knowledge to other team members. On both libraries and main codebases, we use peer code reviews on pull requests, ensuring that teammates are familiar with as much of our code as possible. This is really important; when a member of our team was suddenly and unexpectedly summoned for three months of jury duty, we didn’t have to panic because we were not in a situation where that developer was the only person who was familiar with certain parts of our codebase.

如果将我们的应用拆分成小而且可重用的几部分的话，会有很多技术上的优点，但同时这页允许我们为不同的组件而明确分工。当我们这样做的时候，我们需要确保我们的确把知识分享给团队成员，来保证团队成员们对我们的代码尽可能的熟悉。这一点是非常重要的；当我们团队里的某一个成员突然被法院传召三个月，我们不需要苦恼，因为他不是唯一的对特定部分代码熟悉的人。

Beyond practical improvements to our team management, encouraging developers to explore different aspects of iOS development helps them grow as people and professionals. While we are certainly specialists in iOS, exposure to [other languages](https://github.com/orta/cocoapods-keys/pull/31) helps us stay sharp, relax, and discover new ways to solve familiar problems.

除了团队实际的管理外，鼓励开发者去探索 iOS 开发的不同的方向，能帮助他们更专业，更全面。像我们的 iOS 开发技术炉火纯青的时候，学习[其他编程语言](https://github.com/orta/cocoapods-keys/pull/31)能帮助我们更加直接地，创新地解决相似的问题。

We work remotely; our team has not yet been all in the same room together. By operating like an open-source community, we embrace — not fight against — the asynchronicity and flexibility inherent within our team structure.

我们远程工作；我们的团队到目前为止还没有同时呆在一个屋子里过。通过像一个开源社区来工作，团队结构更加灵活和可伸缩，而不是像传统的团队一样。

--------

At the start of 2015, we finished open sourcing the Artsy iOS app, [eigen](http://github.com/artsy/eigen). This is a process that took many months; we needed to take considered, incremental steps both to prove that there was business value in open sourcing our consumer-facing app, and to disprove any concerns around letting others see how the sausage is made. This wasn’t a hard decision for our company, because sharing knowledge is a core value that everyone in our company believes in.

2015 年初，我们完成了 Artsy 的 iOS 应用 [eigen](http://github.com/artsy/eigen) 的开源工作。这是一个持续了很多个月的项目；我们会保持关注，并逐渐地证明，开源一个面向消费者的应用的确会有它的商业价值，还有反驳那些质疑我们的。

The first steps toward open sourcing eigen were already complete; we had open sourced as much generic code from the application as we could. Most of our time preparing was spent ensuring that sensitive details in our git history and GitHub issues didn’t leak. In the end, we decided that creating a new repository with a fresh history and issue list was the safest route.

开源 eigen 的第一步工作已经完成得差不多了；我们已经尽可能地从我们的应用中开源代码。我们的大部分的准备工作都是在确保代码中敏感的细节不会通过 git 历史记录和 GitHub 的 issue 泄露出去。最后，我们决定用一个全新的 repository，还有完全空白的历史记录以及 issue。

Earlier, we said that being open source by default means that everything stays open unless there is a good reason to keep it secret. The code we do share isn’t what makes Artsy unique or valuable. There is code at Artsy that will necessarily stay closed forever. Practical examples include the use of a [commercially licensed](https://github.com/artsy/eigen/blob/e52f3e1fa30f7bae6fb1d6332f37e5309463df41/Podfile#L63-L67) font or the recommendation engine that powers the [Art Genome Project](https://www.artsy.net/theartgenomeproject).

在前面，我说过如果开源则意味着全部对外开放，除非确实有一个理由想让它保密。所以并不是那些我们开源的代码使 Artsy 特别或具有价值。如果没有特殊情况， Artsy 的代码将会一直开源。实际的例子中包括一个[商业许可](https://github.com/artsy/eigen/blob/e52f3e1fa30f7bae6fb1d6332f37e5309463df41/Podfile#L63-L67)用途的字体，还有 [Art Genome Project](https://www.artsy.net/theartgenomeproject) 所用到的引擎。

After setting the gears in motion to open an existing app, the next step was to build an app entirely in the open — from scratch. This gave us the opportunity to figure out how we could deal with project management, tooling issues, and actual development in the open. The experience felt very similar to working on a community-run open-source project.

做完前期开源工作的准备后，接下来就是用原型简单地搭建一个完整的开源应用。通过这样从而管理项目，工具还有实际的开发。这类似于社区维护的开源项目。

We didn’t lay out a strict roadmap during initial development (something we’ve since fixed). This was partially due to a rush to complete the project on time, as well as lots of communication in our private Slack channel. Over time, we’ve tried to move more and more of our interactions into the public repository.

在前期我们不会有明确的布局或线路图。这部分程度上归咎于为了准时完成项目，像很多加入了我们的私人 Slack 频道的开发者一样。将来，我们会更多资源放入公共项目中。

Developing a complex iOS application in the open is something that not many companies have done. As a result, there were gaps in tooling that we’ve had to address. The most significant was keeping our API tokens a secret. In the process of solving this problem, we’ve made a [new](https://github.com/orta/cocoapods-keys), more secure way to store these keys.

开发并开源一个复杂的 iOS 应用不是很多公司都想做的一件事。在开发工具方面，我们还有些欠缺，这也是必须努力的方向。最常见莫过于 API tokens 的保密。为了解决这个问题，我们创造了一个[新的](https://github.com/orta/cocoapods-keys)，更加安全的方法来保存这些 keys。

Artsy is a design-driven company, and our designers are frequent collaborators during the development process. With very little help, our designers were able to adjust to working in the open. They were already familiar with using GitHub to provide feedback asynchronously, so moving their remaining contributions to the open was fairly easy. They have similar ideals about giving back to the design community and consider working in the open to be as much a step forward for themselves as for us developers.

Artsy 是一个设计驱动型的公司，我们的设计师在我们开发工作进行时经常参加进来。我们的设计师能够很容易地参加到开源项目中。他们已经对如何使用 GitHub 来反馈相当熟悉，所以他们参加到开源项目的贡献中是一件再简单不过的事了。他们都有着关于回馈设计社区的想法，和像我们对开发者社区一样。

--------

Now that we’ve covered the hand-wavey, philosophical stuff, let’s talk about the nitty gritty of day-to-day work in the open.

我们上面提及过了那些无关紧要的东西，现在说一下我们真实的日常工作。

Working in the open isn’t so different from typical software development. We open issues, submit pull requests, and communicate over GitHub. When we see an opportunity to create a new library, the developer responsible for that library creates it under his or her own GitHub account, not Artsy’s.

开源工作并不像典型的软件开发那样有很大的差别。我们 open issues， 提交 pull requests 还有在 GitHub 上讨论交流。当我们有机会创造一个新的开源库的时候，那么这个库就是大家的努力成果，而不单单是属于 Artsy 的。

This encourages a sense of product ownership. If a team member has a question about this library six months down the road, it’s clear who to turn to. Likewise, that developer now feels personal ownership of that code, helping to cultivate a fulfilling and joyful work environment. Finally, developers know that the code they make belongs to them, and they can continue to use it after leaving Artsy.

这是一种产品归属感。如果一个团队成员对这个库接下来六个月的时间保持疑问，我们可以很快地寻找解决的办法。同样地，开发者会有归属感，并且帮助我们营造令人满足和愉悦的工作环境。最后，开发者们了解到这些由他们创造的代码是属于他们的，这样他们可以继续使用他们，即使他们离开了 Artsy。

Let’s take a look at an example.

让我们来看一个例子吧。

Like responsible developers, we try and automate as much of our jobs as possible. That includes using continuous integration to minimize the introduction of new bugs and regressions. Currently, we use [Travis](https://travis-ci.org/) for our CI needs, but other solutions exist.

像很多可靠的开发者一样，我们在尽可能地尝试自动化我们的工作。这其中包括使用持续集成来减少新的 bugs 的产生。目前，我们使用 [Travis](https://travis-ci.org/) 来持续集成，当然，也有其他办法可以选择。

Many of our [tests](https://github.com/artsy/eigen/tree/master/Artsy%20Tests) are based on Facebook’s [iOS Snapshot Test Case](https://github.com/facebook/ios-snapshot-test-case) library. This allows us to construct a view (or view controller), simulate some interaction, and take a snapshot of the view hierarchy for reference. Later, when running our tests, we perform the same setup and snapshot the same view class. This time, we compare the generated snapshot to the earlier reference file.

我们很多的[测试方案](https://github.com/artsy/eigen/tree/master/Artsy%20Tests)都是基于 Facebook 的 [iOS Snapshot Test Case](https://github.com/facebook/ios-snapshot-test-case) 库。这个库可以构造一个 view (或者 ViewController)，来模拟交互，以及如果需要作为参考的话，还可以将视图层次结构截图。然后，当我们测试的时候，我们进行相同的操作和截图，从而与之前的截图作对比。

A problem we were facing involved the use of Travis. Sometimes, snapshot tests would fail remotely on CI but pass locally. Snapshot test failures leave behind reference and failed images that you can compare with [Kaleidoscope](http://www.kaleidoscopeapp.com/) to determine the problem. However, on CI, we didn’t have access to these snapshots files. What could we do?

我们所遇到的另一个问题是关于 Travis 的使用。有时候，snapshot 测试会在 CI （持续集成）不通过，但本地会通过。Snapshot 测试可以通过与 [Kaleidoscope](http://www.kaleidoscopeapp.com/) 提供的参考和不通过的截图，从而诊断出原因。但是，如果在 CI （持续集成），我们可能无法取得截图，那我们应该怎么办呢？

During a weekend hike in Vienna, Orta and Ash discussed possible solutions to this problem. We ended up building a tool called [Second Curtain](https://github.com/ashfurrow/second_curtain) that would parse xcodebuild output. If it detects any failures, the failing snapshot and the reference snapshot are uploaded to an S3 bucket where they can be [diff’d visually](https://eigen-ci.s3.amazonaws.com/snapshots/50119516/index.html). This tool was the first time Ash had built something non-trivial in Ruby, giving him the chance to improve our tooling and to expand his knowledge.

在维也纳的周末旅行中，Orta 和 Ash 一起讨论了可能的解决办法。最后我们决定搭建一个叫 [Second Curtain](https://github.com/ashfurrow/second_curtain) ，可以解析 `xcodebuild` 输出的工具。如果它检测到任何不通过，那么有关不通过的截图和参考文件截图将会被上传到一个 S3 bucket，并可以比较出[不同的地方](https://eigen-ci.s3.amazonaws.com/snapshots/50119516/index.html)。这是 Ash 第一次用 Ruby 写的比较重量级的工具，给了他一个机会来发展我们的配置工具，还有拓展他的知识。

--------

People often ask why we operate in the open as we do. We’ve already discussed our technical motivations, as well as the sense of purpose it gives individual team members, but honestly, working in the open is just smart business. For example, we’re working on a single open-source library to handle [authentication](https://github.com/artsy/Artsy_Authentication) with our API. Not only does this make writing apps against our API easier for us, but it makes it easier for everyone else. Huzzah!

经常有人会问我们为什么把项目都开源。我们已经讨论过了我们的技术上德目的，就像它给予我们团体每个成员的感受一样，但坦白说，开源其实是一件很值得做的事。例如，我们正在编写一个单独的开源库的处理[身份验证](https://github.com/artsy/Artsy_Authentication)的 API。这项工作不单单会让那些针对我们 API 的开发工作更简单，同时它也使每个人的开发更轻松。这真是太爽啦。

There is a tendency, particularly in iOS developer communities, to eschew third-party dependencies. Developers fall victim to “Not Invented Here” syndrome and end up wasting valuable hours of development time tackling the same problems others have already solved for them. On our mobile team, we vehemently reject NIH syndrome and instead favor the philosophy of “Proudly Discovered Elsewhere” (a phrase we appropriated from [another developer](https://twitter.com/jasonbrennan), naturally).

对于开发者，经常有特意避开第三方依赖库的倾向，这种现象在 iOS 开发社区尤为明显。他们经常有不是在这里制造的受害倾向，并浪费很多时间来调试，而不是使用那些已经为他们解决了相似问题的库。在我们团队，我们非常反感这种现象，反而，我们更欣赏那种 “Proudly Discovered Elsewhere” 的思想，（[一个开发者](https://twitter.com/jasonbrennan)说过的话）。

In our field, personal and professional growth are expected from employers; however, these processes are not just checkboxes on some HR form. If you’re doing them right, they should be daily activities that are intrinsic to your work. We accomplish this by working as an open-source team.

在我们的公司里，我们都会认真评估应聘者的个人素质和技术水平；但是，这些指标不单单是 HR 手里的表格上面的几个选项这么简单。如果你确实很优秀，那么这些东西会潜移默化地融入你的日常生活和工作中。而我们，正是由于呆在这么一个开源项目的团队里而身体力行。

By developing our software in the open, the larger developer community is able to offer feedback on our work and we get to work with awesome developers all around the world. Sharing knowledge with others also helps cultivate an amazing workplace culture — one we’ve become known for — which in turn attracts great developers to work with. You can never have too much of a reputation, after all.

通过将我们的软件开源，庞大的开发者社群能够对我们的工作提供反馈，让我们有机会与全世界那些出色的开发者一起交流。与别人分享知识同时也帮助我们培养良好的工作氛围 -- 当我们出名以后 -- 反过来会吸引那些好的开发者加入我们。毕竟，我们从来没有得到如此多的尊敬和声望。

We often codify the knowledge we’ve gained on our blog or in presentations at conferences. Not only do these artifacts help to spread our knowledge to developers outside Artsy, but they also facilitate in bringing new members of our mobile team up to speed with how we work and the tools we use. We’ve even shared our experience sharing our knowledge, one of our more meta endeavors.

开会的时候，我们经常整理那些从博客或者演讲中获得的技术知识和技术笔记。他们不仅会帮助我们将见解和技术传给团队外部的开发者，同时便利了那些加入我们团队的新成员，让他们更加迅速地了解到我们的工作，以及我们所使用的工具。我们甚至分享那些关于如何分享知识的经验，这也是其中一件我们正努力去做的事。

Working in the open isn’t all rainbows and puppy dogs, but the problems we’ve encountered have been minor. A common concern in open sourcing a codebase is the potential embarrassment of allowing others to see less-than-perfect code. However, we believe the best way to improve is by opening oneself up to critique. Critique is not a reason to feel embarrassed — and really, every developer understands that when you have to ship on a deadline, sometimes hacky code makes it into production.

开源工作不总是一帆风顺的，但是我们遇到的困难仍然不值一提。一种普遍的关于开源的看法是，让别人看到自己不完美的代码会很尴尬。但我们认为，提高水平最好的办法就是让别人看你的代码，让别人评论你的代码。这不应该成为让你尴尬的原因 -- 同时，几乎，所有开发者都明白，截止日期快要来的时候，项目里那些迫不得已的 hacky 代码必定会缺乏可读性和优雅性。

We do know that some of our competitors use our code, because they offer their fixes back to us. We do the same. In reality, the biggest challenge to a business open sourcing a project is the obligation of stewardship. This responsibility is mostly a matter of working with people and needs to be managed correctly — especially if a project gains enough popularity. Most projects don’t get large enough for their stewardship to become burdensome.

我们的一些竞争对手在使用我们的代码，因为他们反馈了一些改进给我们。我们也一样。实际上，开源一个商业项目最大的挑战在于管理者。这种责任关系是处理人际关系最重要的部分，也是需要认真处理好的 -- 特别是当一个项目得到了足够多的好名声。所以大部分的项目都没有足够的管理使它获得足够的沉淀。

It’s easy to release code and then either abandon the project or ignore the community, but we gladly accept the obligations tied to running a project in the open.

发布完代码，将项目抛之脑外，并忽视开发者的反馈是一件很常见的事情，但是我们却乐于接受开源项目的责任，并努力继续把项目开源。

The extra time necessary to create and maintain open-source code often helps us unwind and relax from our day-to-day tasks, and over-communicating on GitHub has helped the remote members of our team.

那些需要额外花费我们时间来开发和维护的开源项目，经常能帮助从日常的任务中解放出来，并且， GitHub 帮助我们的团队成员能够远程地讨论，交流。

In our experience working as a small team in a company that believes in open source, any risks or costs associated with Open Source by Default are negligible. If actual disadvantages even exist, they are far, far outweighed by the technical advantages, business prospects, and personal joy of working in the open.

可以在一个拥抱开源的公司里作为一个小的团队而工作，让那些由于开源而要承担的各种风险微不足道。如果这个影响确实存在的话，技术好处，商业前景以及开源项目所带来的乐趣要比它们大，大得多。

There is a fundamental difference between releasing a library to the open and creating an open-source library — the same difference between the technical distinction of open source and the mentality of open source. The difference is summed up by answering the following question:

而开源一个库，以及创造一个开源的库，这其中仍然有一些基本的不同点 -- 技术上的难度，还有开源一个项目的心态。回答下面这个问题会让你了解到其中的不同点：

Are you opening code only for your benefit, or are you doing it for the sake of everyone?

你是为了你自己，还是为了其他开发者呢？