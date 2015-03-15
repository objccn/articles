## Scaling Square Register
Over the six-year history of [Square Register](https://squareup.com/register), the codebase and the company have undergone significant changes, as the app has grown from a simple credit card terminal to a full-featured point-of-sale system. The company has grown from 10 people to more than 1,000, and we’ve had to scale quickly. Here are some of the things we’ve learned and the processes we’ve implemented along the way.

## Square Register 的扩张
在 [Square Register](https://squareup.com/register) 超过 6 年的历史中，代码库和公司都发生了显著的变化，由于应用程序已经从一个简单的刷卡终端成长为一个全功能销售终端（point-of-sale）系统。公司已经从 10 人发展到 1000 多人，而我们不得不迅速扩张。下面是一些我们在前进的道路上实现的流程和已经学到的东西。

## The Team
As we grew, we realized that once an engineering team reaches a certain size, it’s ineffective to organize the team by platform. Instead, we have “full-stack” teams that are responsible for specific sets of features within the app. These teams consist of iOS engineers, Android engineers, and server engineers. This gives teams more freedom and creates improved focus on building a deeper, more comprehensive product. We’ve organized feature-oriented teams around restaurants, retail stores, international support, hardware, and core components (to name a few). Giving full vertical ownership to a group allows those engineers to make more holistic technical decisions, and it gives them a tangible sense of ownership over the product.

## 团队
随着我们的成长，我们意识到，一旦开发团队达到一定规模，按平台来组织团队会很低效。相反，我们用“全方位”团队来负责应用程序中的特定功能集。这些团队包括 iOS 工程师，Android 工程师和服务器的工程师。这给了团队更多的自由来集中精力去创造一个更深入，更全面的产品。我们围绕着餐厅，零售商店，国际化支持，硬件和核心部件（仅举几例），组建了面向功能的团队。当团队拥有了足够的纵向所有权，就为工程师们做出更全面的技术决定留出了可能，并让他们拥有了对产品确定的归属感。


## Our Release Process

## 我们的发布流程

Before 2014, Register releases followed the waterfall methodology; we decided on a large set of features to build, set a future deadline (three to six months), and then worked to build these features.

2014 年之前，Register 的发布还遵循瀑布模型；我们规划一个大的功能集，然后设定一个未来的死线（三至六个月），然后努力实现这些功能。

This process did not scale well. Waterfall became laborious and slow as we added features and engineers to the product. Since all features developed during the release had to ship together, a single delayed or buggy feature would delay the entire release. To ensure that teams continued to stay autonomous, we looked for a different, more efficient approach.

这个流程没有很好地扩展。当我们为产品增加功能和工程师时瀑布模型变得费力和缓慢。由于发布版本的所有开发功能必须一起发布，某一个功能的延迟或有问题会耽误整个发布。为了确保团队持续保持自主性，我们找到了一个不同的，更有效的方法。

### All Aboard the Release Train
To stay efficient, we always want to make sure our processes match our size. Starting in 2014, we adopted a new model consisting of “release trains.” Release trains optimize for feature team autonomy while enabling continuous shipping. This means individual features can be released when they’re ready, without having to wait for other work to be completed.

### 都登上发布的列车
为了保持高效率，我们总是希望确保我们的流程符合我们的规模。从 2014 年开始，我们引进了一个由“发布列车”组成的新模式。发布列车优化了功能团队的自主权，同时支持持续发布。这意味着单个功能可以在他们准备好的时候就被发布，而不必等待其他工作的完成。

Switching to release trains required changes to our workflow:

切换到发布列车需要改变我们的工作流程：

- **Incremental Development** — Features are developed incrementally, rather than in long-lived isolated feature branches.
- **Isolation & Safety** — New features must be behind a server-controlled feature flag. The feature flag remains disabled outside of development until the feature is ready to ship.
- **No Regressions** — If a change introduces a regression in an existing feature, the regression must be fixed immediately.
- **Target a Timeframe** — Instead of attempting to ship a feature in a specific version, teams instead target a release timeframe that contains two to three features.

- **增量开发** - 功能是逐步发展的，而不是长期的被隔离的功能分支。
- **隔离和安全** - 新功能后面都有一个服务器控制的标志。该功能标志不由开发控制，直到准备发布之前都保持禁用状态。
- **无回退** - 如果某个改变在现有的功能上导致了回退，那这个回退必须被立即修复。
- **制定一个时限** - 团队在一个发布期限内可以包含两到三个功能而不是在某个特定版本仅发布一个功能。

This means that our master branch stays in a stable state. This is where the train part comes in.

这意味着，我们的主分支保持在一个稳定的状态。这就是所说的列车的一部分。

1. **Branch** — At the beginning of every month, a release branch is created off of the master branch.
2. **Board the Train** — If a feature is ready to ship (very few issues remaining), its feature flag is enabled. If it is not, it must wait for the next train.
3. **Test and Fix** — The rest of the month is spent fixing bugs in the release branch. If a team is not shipping anything in the train, it will continue to work on the master branch.
4. **Merge** — The changes in the release branch are continuously merged back down into the master branch.
5. **Ship** — We ship that release branch to the App Store at the end of the month.
6. **Repeat** — We repeat the process every month after that.

1. **分支** - 在每个月的月初，会从主分支创建一个发布分支。
2. **上车** - 如果一个功能准备发布（剩余很少的问题），它的功能标志被启用。如果不是，它必须等待下一班列车。
3. **测试和修复** - 每个月的其余时间花费在对发布分支的错误修正上。如果一个团队不需要发布任何东西，它会继续在主分支上工作。
4. **合并** - 发布分支上的变化会不断合并回主分支。
5. **发布** - 在月底我们会把发布分支发布到 App Store。
6. **重复** - 之后的每月重复上述过程。

This has several benefits:

这有很多的好处：

- There is no more than one month of code change between each release, leading to fewer bugs.
- Only bug fixes go into the train’s release branch. This means longer “bake time” to prove that changes are stable.
- There’s less need to ship bug fix releases; most bug fixes can wait until the next train.
- By building and merging features incrementally, we avoid large disruptive merges that destabilize the master branch.
- Regressions or high-priority bugs on the master branch are not acceptable. Fixing these are the team’s highest priority.
- There’s less pressure to ship features on a specific date. Instead of having to wait months for the next release, the feature can be included in next month’s train. This means that teams don’t need to rush through their work. They simply ship when they’re comfortable with the quality of their features. This improves team productivity, morale, and code quality.

- 每个版本之间不会有超过一个月的代码变更，导致错误更少。
- 只有 bug 修复会进入列车的发布分支。这意味着更长的“烘焙时间”来证明改变是稳定的。
- 会更少需要特别发布 bug 修复版本；因为大多数 bug 的修复都可以等到下一次发布。
- 通过逐步建立和合并功能，避免了可能会破坏主分支的破坏性大合并。
- 主分支是不接受回退或高优先级的错误的。修复这些是团队的最高优先级。
- 在某个具体日期发布的压力减少了。下一个版本不必等待数月，功能可以在下个月的发布中就包含进去。这意味着团队不需要急着赶工。他们只需在他们对功能的代码质量有信心的时候发布。这提高了团队的工作效率，士气和代码质量。

At the beginning of 2015, we refined this process even more: Release branches are now cut and shipped on two-week intervals. That means teams will have 26 opportunities to ship this year. Compared with just three or four releases per year in 2013 and earlier, this is a huge win. More opportunities to ship means more features delivered to customers.

在 2015 年年初，我们对这个流程做了进一步改进：现在发布分支和发布被分割成两个星期的时间间隔。这意味着团队在今年将有 26 次发布的机会。相比 2013 年及更早的每一年只有三个或四个发布版本而言，这是一个巨大的胜利。更多的发布机会意味着交付给客户更多的功能。

## Our Engineering Process
Square merchants rely on Register to run their businesses. As such, it needs to be reliable at all times. We have rigorous processes for ensuring quality at the design, implementation, and testing phases.

## 我们的开发进程
Square 的商人依靠 Register 来经营生意。因此，它在任何时候都必须是可靠的。我们有严格的流程，以确保设计、实施和测试阶段的质量。

### Large Engineering Changes Require Design and Review
_“Writing is nature’s way of letting you know how sloppy your thinking is” –Guindon_

### 大型工程变更需要设计和评审
_“写下来是让你知道你的思维有多草率的最自然的方式” -Guindon_

This is one of my favorite quotes, and it applies to building software too! If the software you’re building exists only in your head, that software will be flawed. The image in your head is very ambiguous and ephemeral; it’s constantly changing, and thus needs to be written down to be clarified and perfected.

这是我最喜欢的一句话之一，而且它也适用于软件构建！如果你只是在你的头脑里构建软件的话，该软件将是有缺陷的。在你脑袋里的形象是很模糊和短暂的；它总是持续变化的，因此需要写下来加以澄清和完善。

Every large change at Square must go through an engineering design review. This sounds daunting if you’ve never done it before, but it’s actually quite easy! The process generally involves writing up the following in a design document:

Square 里每一个大的变化，都要经过工程设计审查。如果你以前从来没有做过，这听起来会有点吓人，但它其实很简单！这个过程通常需要编写以下的设计文档：

- **Goals** — What are you trying to accomplish? What are the customer-facing effects of your change?
- **Non-Goals** — What aren’t you trying to accomplish? What are your boundaries?
- **Metrics** — How will you measure success or failure?
- **Investigations** — What other solutions (if any) did you investigate? Why didn’t you choose them?
- **Choice** — What have you decided to do? Why have you decided to do it?
- **Design** — What are the details of your chosen design? Include an API overview, technical details, and (potentially) some example headers, along with anything else you think will be useful. This is where you sell the design to yourself and your fellow engineers.

- **目标** - 你想实现什么？这个变化对客户有什么影响？
- **非目标** - 你没有实现什么？有什么界限？
- **度量** - 你将如何衡量成功或失败？
- **调查** - 你还调查过其他的什么解决方案（如果有的话）？你为什么没有选择它们呢？
- **选择** - 你决定了要做什么？你为什么决定这样做？
- **设计** - 你所选择的设计有些什么细节？包括 API 概述，技术细节，以及（可能的）一些头文件例子，以及其他任何你认为有用的东西。这是你把你的设计卖给你自己和你的同伴工程师们的地方。

We then include two to four reviewers who should review the document, ask questions, and make a final decision. These reviewers should be familiar with the system you’re extending.

然后，我们会有两到四个评审来审查文档，提出问题，并作出最后的决定。这些评审应该熟悉你要扩展的系统。

This may seem like a lot of work, but it’s well worth it. The end result will be a design that’s more robust and easier to understand. We consistently see fewer bugs and less complexity when a change goes through design review. Plus, as a side effect, we end up with peer-reviewed documentation of the system. Neat!

这似乎是大量的工作，但它是值得的。最终的结果将是一个更茁壮和更易理解的设计。我们不断地看到，当一个变化经过了设计审查，会使得错误更少，并降低了复杂性。另外，作为一个副产品，我们还得到了经过评审的系统文档。棒！

### Our Code Review Process
Our code review process is rigorous for a few reasons:

### 我们的代码审查过程
因为以下几个原因，我们的代码审查过程是很严谨的：

- **App Store Timing** — If we do ship a bug, the App Store review process delays delivering fixes to customers by about a week.
- **Register Is Critical** — Finding bugs is important because Register is a critical piece of restaurants, retail shops, and so on.
- **Large App** — Catching bugs post-merge in a large application like Register is difficult.

- **App Store 的时限** - 如果我们发布了一个 bug，由于 App Store 的审查过程会使得修复延迟约一个星期给客户。
- **Register 是至关重要的** - 查找错误很重要，因为 Register 对餐厅、零售商店来说很关键，依此类推。
- **大型应用程序** - 在一个像 Register 这样大的应用程序里找 bug 后合并是困难的。

What is our process for pull requests? Every PR must:

我们的 pull requests 流程是什么呢？每次 PR 必须满足：

- **Be Tracked** — Pair a PR with a JIRA issue.
- **Be Described** — There must be a clear description of the what and why behind the change.
- **Be Consumable** — Pull request diffs must be 500 lines or less. No large diffs are allowed. Reviewers will overlook bugs if a change is much larger than 500 lines.
- **Be Focused** — Do not pair a refactor or rename with a new feature. Do them separately.
- **Be Self-Reviewed** — All PR authors are expected to do a self-review of their change before adding outside reviewers. This is meant to catch stray NSLogs, missing tests, incomplete implementations, and so on.
- **Have Two Specific Approvers** — One of these reviewers must be an owner of the component being changed. We require explicitly listed reviewers to ensure engineers know exactly what is and isn’t in their review queue.
- **Be Tested** — Include tests that demonstrate the stability and correctness of the change. Non-tested pull requests are rejected.

- **被追踪了的** - 每一个 PR 都有对应的 JIRA。
- **被描述了的** - 每一个变化后面都必须有什么，为什么的一个清晰的描述。
- **是可以被评审的** - Pull request 的 diff 文件必须是 500 行以内。大型的 diff 是不允许的。如果一个 diff 比 500 行还多得多，评审很容易看不到错误。
- **集中** - 不要把重构或重命名跟一个新的功能放到一起做。把他们分别开来。
- **自我审查** - 在增加其他评审之前，所有 PR 的作者都要求对改动先做自我审查。这是为了避免杂散的 NSLogs，缺失的测试，不完整的实现方式之类的事情。
- **有两个具体的审批** - 评审员中的一个必须是被改变组件的所有者。我们需要明确的列出评审，以确保工程师们知道在他们的审核队列到底有些什么。
- **被测试了的** - 包括了改动的稳定性和正确性测试。没有测试的 pull request 会被拒绝。

Similarly, reviewers are expected to:

同样，评审们被要求：

- **Be Clear** — Comments must be clear and concise. For new engineers, reviewers should include examples to follow.
- **Explain** — Don’t just say “change X to Y”; also explain why the change should occur.
- **Not Nitpick Code Style** — This is what automated style formatters are for (more on this later).
- **Document** — Each code review comment must be marked as one of the following:
— Required _(“This must be fixed before merge.”)_
— Nice to have _(“This should be fixed eventually.”)_
— A personal preference _(“I would do this, but you don’t have to.”)_
— A question _(“What does this do?”)_
- **Be Helpful** — Reviewers must enter a code review in a helpful mindset. It is the job of a reviewer to help code be merged safety, not to block it.

- **清楚** - 意见必须清晰，简明。对于新的工程师，评审应包括可遵循的例子。
- **解释** - 不要只说 “把 X 改成 Y”；也要解释了为什么应该这样改。
- **不要挑剔代码风格** - 这是自动格式化干的事（接下来会讲）。
- **文档** - 每个代码审查意见必须被标记为下列之一：
— 必须有 _(“必须在合并前修复。”)_
— 最好有 _(“最终都需要修复。”)_
— 个人喜好 _(“我会这样做，但你不必。”)_
— 一个问题 _(“这是干嘛的？”)_
- **乐于帮忙的** - 评审必须有一个乐于帮忙的心态来进行代码审查。这是一个帮助代码安全合并，而不是阻止它的评审工作。

Before merging, all tests must pass. We block pull requests from being merged until a successful run of our unit tests and our automated integration tests (which use [KIF](https://github.com/kif-framework/KIF)).

在合并之前，所有的测试必须通过。单元测试和我们的自动化集成测试（使用[KIF](https://github.com/kif-framework/KIF)）跑成功前，需要合并的 pull request 都会被阻止。

## Some Process Tips
We’ve begun doing the following things to help streamline and accelerate the Register development process.

## 一些流程 Tips
我们已经开始在做下面的事情来帮助简化和加快 Register 的开发过程。

### Document Common Processes as Much as Possible
One thing we learned as the Register team grew was how poorly “word-of-mouth” knowledge scales. This isn’t a problem if you’re only onboarding a few engineers a year, but it quickly becomes time-consuming if you’re onboarding a few engineers a month, especially if they’re only on the project temporarily (e.g. a server engineer helping to build a particular feature). It becomes important to have an up-to-date document containing the standards and practices of the team. What should this document include?

### 尽可能地用文档通用流程
在 Register 团队的成长中我们学到的有一件事是“口头说说”是很糟糕的知识尺度。如果一年只有几个工程师入职的话，这不会是一个问题，但如果一个月就会入职几个工程师，尤其是如果他们只是针对临时项目（例如临时需要一个服务器工程师帮助建立一个特别的功能），这种尺度很快会变得很费时。一个具有标准和团队实践的保持更新的文档就变得很重要。这份文档应该包括哪些内容呢？

- Code review guidelines (for submitters and reviewers)
— _“How many reviewers do I need? When can I merge this?”_
- Design review guidelines
— _“How should I design this feature?”_
- Testing guidelines
— _“How do I test this? What testing frameworks do we use?”_
- Module/component owners
— _“Who can I talk to about X? Who built it?”_
- Issue tracking guidelines
— _“Where do I look up and track what I have to do?”_

- 代码审查指南（对于提交者和审查者）
— _“我需要多少个评审？我什么时候可以合并？“_
- 设计审查指南
— _“我应该如何设计这个功能？”_
- 测试指南
— _“我该如何测试呢？我们使用什么测试框架？“_
- 模块/组件所有者
— _“我可以跟谁讨论 X？谁建的呢？“_
- 问题跟踪指南
— _“我在哪里可以查找并跟踪我要做的？”_

You’ll likely notice a pattern here: anything that can be answered in 10 minutes or less should be clearly documented.

你可能会注意到这里的一个规律：凡是能在 10 分钟以内回答的问题都应清楚地记录下来。

### Automate as Many Inefficiencies as Possible
Manual processes that take a couple of minutes with a few engineers can take much longer with many engineers. Any time you see something trivial that eats up a lot of time, automate it if possible.

### 尽量把低效的工作自动化
需要几个工程师花数分钟的手动流程如果用更多工程师可能需要花更长的时间。任何时候你看到琐碎的东西花费了大量的时间，都应该尽可能让它自动化。

#### We Automated Our Style Guide
One of our biggest “automate it” wins recently has been our Objective-C style guide: We now use [clang-format](http://clang.llvm.org/docs/ClangFormat.html) to automatically format all code committed into Register and its submodules. This eliminates code review comments along the lines of “missing newline” or “too much whitespace,” meaning reviewers can focus on things that actually improve the quality of the product.

#### 我们把我们的代码风格指南自动化了
我们最近的一个最大的“自动化”成功案例是我们的 Objective-C 代码风格指南：我们现在使用 [clang-format](http://clang.llvm.org/docs/ClangFormat.html) 来自动格式化提交到 Register 及其子模块的所有代码。这消除了代码审查里面的各种“没有换行”或者“太多的空白”的意见，这意味着审阅者可以专注于真正提高产品质量的东西。

We merge many pull requests each day. These “style nit” comments used to take anywhere from 10–20 minutes per pull request (between the reviewer and the author). That means we’re saving two or more hours a day from style guide automation alone. That’s 10 hours a week. It adds up quickly!

我们每天都要合并很多的 pull requests。之前这些“挑剔风格”的意见会在每个 pull request 额外花 10-20 分钟（鉴于审查者和作者）。这意味着仅是风格指南的自动化都让我们每天节省了两小时或更长时间。也就是一个星期 10 个小时。增加太快了！

#### We Automated Visibility into Code Reviews
Another example of automation saving time is our new “Pull Request Status” email that gets sent out daily.

#### 我们把可视性代码评测自动化了
另一个自动化节省时间的例子是我们每天都会发送 “Pull Request 状态”的邮件。

Before this email existed, 10 to 15 of us would crowd around a stand-up table for 10 minutes each morning and assign reviewers to open pull requests. Instead, we now send out a morning email containing a list of all open PRs, along with who is assigned to review them. No more meeting needed. This means we’re getting back more than 2 hours of engineering time per day, or 10 hours per week.

在这个电子邮件存在之前，每天早晨我们当中的 10 到 15 个人会挤在一个桌前站 10 分钟，分配 pull requests 的审查。而现在，我们每天早上发出一个包含了所有开放 PR 列表的电子邮件，以及谁被分配来对其进行审查。不需要再额外开会了。这意味着我们又多了每天 2 个多小时或每周 10 小时的开发时间。

Another benefit of this daily PR status email is that we can easily track what’s happening with reviews: How long they take, which engineers are contributing the most, and which are reviewing the most. This helps to reveal time allocation issues which may be slowing the team down (e.g. Is one engineer doing half of the team’s reviews?).

这个每天 PR 状态电子邮件的另一个好处是，我们可以轻松地跟踪评审发生了什么事：他们需要多长时间，哪个工程师贡献最大，哪个工程师审查了最多。这有助于揭示那些可能拖累团队的时间分配问题（比如是否一名工程师做了团队一半的评审？）。

### Centralize on a Single Bug Tracker
It’s impossible to ship a bug-free product if your bugs are split across multiple trackers. It’s incredibly important to have one place where we can go to see everything pertaining to the current release: the number of bugs, the number of open bugs per engineer (is anyone overloaded?), and the overall trend of bugs (are we fixing them faster than they’re being opened?).

### 一个 Bug 用一个跟踪器
如果你的 bug 被分散在多个跟踪器上是不可能发布无缺陷的产品的。有一个地方可以让我们看到一切有关当前版本的信息是极其重要的：bug 的数量，每个工程师未解 bug 的数量（是否有谁忙不过来了？），以及 bug 的总体趋势（我们修复它们速度比他们被开的速度更快吗？）。

## Maintaining Quality in a Shared Codebase
When only a few engineers are working on a project, it’s easy to maintain quality: all engineers know the codebase well, and they all feel strong ownership over it. As a team scales to 5, 10, 20, or more engineers, maintaining this quality bar becomes more difficult. It’s important to ensure every component and feature has an explicit owner who is responsible for maintaining its quality.

## 保持共享代码库的质量
如果只有几个工程师在做同一个项目，可以很容易地保证质量：因为所有的工程师都清楚了解代码库，他们也都有强烈的归属感。但当一个团队扩展到 5、10、20 或更多的工程师的时候，维护这样的品质变得更加困难。重要的是要确保每个组件和功能有明确的负责维护它质量的所有者。

### Every Component Needs an Owner
In Register, we recently decided to have explicit owners for each logical component of the app. These owners are documented in a list for anyone to easily look up. What is a component? It might be a framework, it might be a customer-facing feature, or it might be some combination of the two. The exact separation isn’t important; what’s important is to ensure that every line of code in your app is owned by someone. What do these owners do?

### 每一个组件都需要一个所有者
在 Register，我们最近决定应用程序的每个逻辑组件都要有明确的所有者。这些所有者都记录在一个列表里以便查找。什么是一个组件？它可能是一个框架，它可能是一个面向客户的功能，它也可能是两者的某种组合。确切的分界并不重要；最重要的是确保应用程序的每一行代码都是有人所有的。这些所有者要干什么？

- They review and approve code changes and design documents.
- They know the “hard parts” and how to work around them.
- They can provide an overview for engineers new to the component.
- They ensure quality is always increasing.

- 他们审查和批准代码更改和文档设计。
- 他们了解“关键部位”，以及如何解决它们。
- 它们可以为新来的工程师提供组件的概述。
- 他们确保质量始终越来越好。

We’ve seen great results from electing explicit owners for components: code quality is consistently higher (and the bug rate is lower) in components which have owners versus those that are implicitly owned by everyone.

在选举组件明确所有者的时候得到了很好的结果：有明确所有者的组件和默认所有人为所有者的组件相比，代码质量是持续增高的（bug 率也较低）。

### Keep the Master Branch Shippable
This is another recent change for us: We’ve started enforcing a strict “no regressions” rule on the master branch. The benefit of this? Our master branch is now always very stable. If anyone finds a bug, there’s no question if it should be reported or not. It also reduces QA load, as less time is spent figuring out if issues should be filed, if they’re duplicates, etc. If a bug is found, an issue is filed.

### 保持主分支是可发布的
这是我们最近的另一项改变：我们已经开始在主分支上严格执行“不回退”的规则。这样做的好处是什么？我们的主分支现在一直都很稳定。如果有人发现了一个错误，不会有是否需要报告的问题。它也能减少 QA 的负载，因为会花更少的时间搞清楚问题是否应提交，它们是否重复等。如果发现了错误，就提 bug。

This policy goes hand in hand with the release train model: At nearly any time, we can cut a release branch from the master branch and be just a few days from shipping to the App Store. This is incredibly valuable for an app as large as Register, and it helps us move as fast as possible.

这一政策和发布列车模型是齐头并进的：几乎在任何时候，我们都可以从主分支拉一个发布分支，并在短短几天内发布到 App Store。这对一个像 Register 这样的一个大型应用程序是非常有价值的，它可以帮助我们尽可能快的做出行动。

Keeping the master branch in a shippable state also helps avoid the “broken windows” problem as we scale; fixing bugs as they’re discovered ensures engineers hold themselves to a higher standard.

鉴于我们的规模，保持主分支在可发布状态，也有助于避免“破窗效应（[broken windows](https://en.wikipedia.org/wiki/Broken_windows_theory)）”的问题；发现的时候就修正 bug，确保工程师让自己保持更高的标准。

### Build for Testability from the Beginning
It’s incredibly important to ensure every component within Register is built and designed with testability in mind. Without this, we would need to expand manual QA efforts exponentially: two features can interact in four ways, three features can interact in eight ways, etc. Obviously, this isn’t reasonable, reliable, or scalable.

### 从头建立可测性
确保 Register 里的每一个组件在建造和设计的时候都保持了可测试性的初衷是非常重要的。没有这一点，我们就需要成倍扩大手动 QA 的工作量：两个功能可以通过四种方式进行交互，三个功能可以在八个方面互动，等等。显然，这是不合理的、不可靠的，也是不可扩展的。

As we’re working through the engineering design for a feature, we’re constantly asking ourselves: “Is this testable? Am I making automated testing easy?”

当我们在为某个功能做工程设计工作的时候，我们不断地问自己：“这个可以测试吗？我在让自动化测试容易进行吗？“

Building for testability also has an additional benefit: It introduces a second consumer of all APIs (i.e. the tests themselves). This means engineers are forced to spend more time thinking through the design of an API, making sure it’s useful in more than one case. The result is that it will be easier for other engineers to reuse the API, saving time in the future.

建立可测试性也有一个额外的好处：它引入了所有 API 的二次使用（即测试本身）。这意味着工程师们不得不花更多的时间思考一个 API 的设计，确保它在多个情况下都是工作的。其结果是，这将使得其他工程师重用 API 变得更容易，节省了未来的时间。

For us, testing isn’t an option; it’s a requirement. If you’re committing code to Register, you need to include tests.

对我们来说，测试不是一种选择；这是一个需求。如果你在 Register 提交代码，必须包括测试。

### The Importance of CI on Pull Requests
A mental exercise: If an engineering organization has 365 engineers, each engineer only has to break the master branch once a year for it to be broken every single day. This obviously wouldn’t be acceptable, and would slow down and frustrate the engineering team greatly.

### CI 对 Pull Requests 的重要性
一个脑力练习：如果一个开发团队有 365 个工程师，而每位工程师每年只会弄坏一次主分支还是每天都弄坏一次。这显然是不能接受的，并且会极大的减慢和挫败的开发团队。

What’s an easy way to prevent the master branch from breaking? By not merging broken code in the first place, of course! This is where pull request CI comes in. Every Register pull request has a CI job that is kicked off for new commits. Around 15 minutes later, the engineer submitting the PR can feel confident that he or she is not introducing any regressions.

有什么简单的方法来防止主分支被破坏？首先当然是不合并错误的代码！这就是 pull request CI 需要做的，每个 Register 的 pull request 都有一个 CI 在有新提交的时候被触发。大约15分钟后，工程师就可以放心的提交 PR，因为他或她不会因此引入了任何导致回退问题。

This has been incredibly valuable as we onboard new engineers into the codebase. They can commit code without worrying that they’re going to introduce master-breaking changes.

当我们有新入职工程师的时候这会是非常有价值的。他们可以提交代码，而无需担心他们将引入让主分支不工作的改动。

## Some Observations as the Team Has Grown
These are some personal observations I’ve made as the Register iOS team has grown and expanded around me over the last three years.

## 队伍不断壮大时的一些观察
以下是在过去三年当 Register 的 iOS 团队不断壮大的一些个人看法。

### Not Everything Will Be Perfect
In a large app, you’ll have a lot of code. Some of this code will be old. But old doesn’t have to mean bad. As long as you have good test coverage, old code will continue to work just fine. Don’t spend time “cleaning up” code that is fulfilling its needs and isn’t slowing anyone down. The best you’d be able to do during this cleanup is not break anything. Spend this time building new features instead.

### 没有什么会是完美的
在一个大的应用程序里，你会有大量的代码。有些代码是很老的了。但老并不一定意味着坏。只要你有良好的测试覆盖率，旧代码将继续正常工作。不要把时间花在“清理”那些的履行了需求并且没有拖累任何人的代码。清理过程中你能做的最好的事情就是不要破坏任何东西。还是把这些时间花在兴建新的功能吧。

### Make Time to Learn Outside of Your Codebase
In a big codebase, it’s very easy to spend all your time working within it, and never learning from outside influences.

### 花时间来了解代码之外的东西
在一个大的代码库里，很容易把所有的时间都花在实现内部功能，并未从外界的影响中学习。

How do you fix this? Take time during the week (I set aside an hour every day) to learn from resources outside of your codebase. What can you learn from? Watch talks that sound interesting. Read papers on subjects you find interesting. You’ll be surprised by the parallels and benefits you’ll begin drawing back into your day-to-day work. Sometimes these little things make the biggest difference.

你怎么解决这个问题？每周花些时间（我每天预留一小时）从外界资源来了解你的代码库。你能从中学到什么？看看那些听起来有趣的讨论。阅读你觉得有兴趣的领域的文章。这样做对你每天工作的并行及优势会让你非常惊讶的。有时，这些小事情会有巨大的区别。

### Addressing Tech Debt Takes Time
There’s rarely an immediate solution to anything, and this includes technical debt. Don’t let yourself get frustrated if addressing tech debt takes a long time, especially in a large codebase.

### 技术累积是需要时间的
很少有可以立即解决的事情，包括技术累积。如果技术累积需要很长的时间，不要让自己感到沮丧，尤其是在一个大的代码库里。

Think about accumulating tech debt like gaining weight: you don’t gain 100 pounds overnight; it happens gradually. Like losing weight, it also takes a great deal of time and effort to eliminate tech debt — there is never an instantaneous solution. Track your progress while paying it off, and make sure it’s progressing downward at a reasonable pace.

想想像体重增加一样积累技术：你并不会一夜就增加一百磅；它是逐步显现的。就像减肥一样，也需要大量的时间和精力来消化技术 - 从来都不会有一个瞬时方案。在累积的同时跟踪你的进步，并确保它在一个合理的速度向下进展。

## That's All, Folks
If you have any questions, feel free to reach out to me at [k@squareup.com](mailto:k@squareup.com). Thanks for reading!

## 这就是全部了，亲们
如果你有任何问题，请随时通过 [k@squareup.com](mailto:k@squareup.com) 联系我。感谢您的阅读！

(Thanks to [Connor Cimowsky](https://twitter.com/connorcimowsky), [Charles Nicholson](https://twitter.com/c_nich), [Shuvo Chatterjee](https://twitter.com/shuvster), [Ben Adida](https://twitter.com/benadida), [Laurie Voss](https://twitter.com/seldo), and [Michael White](https://twitter.com/mwwhite) for reviewing.)

(感谢 [Connor Cimowsky](https://twitter.com/connorcimowsky), [Charles Nicholson](https://twitter.com/c_nich), [Shuvo Chatterjee](https://twitter.com/shuvster), [Ben Adida](https://twitter.com/benadida), [Laurie Voss](https://twitter.com/seldo), and [Michael White](https://twitter.com/mwwhite) 的审查。)


---

[话题 #22 下的更多文章](http://www.objccn.io/issue-22)
