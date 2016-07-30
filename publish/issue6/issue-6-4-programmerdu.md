CocoaPods 是开发 OS X 和 iOS 应用程序的一个第三方库的依赖管理工具。利用 CocoaPods，可以定义自己的依赖关系 (称作 `pods`)，并且随着时间的变化，以及在整个开发环境中对第三方库的版本管理非常方便。

CocoaPods 背后的理念主要体现在两个方面。首先，在工程中引入第三方代码会涉及到许多内容。针对 Objective-C 初级开发者来说，工程文件的配置会让人很沮丧。在配置 build phases 和 linker flags 过程中，会引起许多人为因素的错误。CocoaPods 简化了这一切，它能够自动配置编译选项。

其次，通过 CocoaPods，可以很方便的查找到新的第三方库。当然，这并不是说你可以简单的将别人提供的库拿来拼凑成一个应用程序。它的真正作用是让你能够找到真正好用的库，以此来缩短我们的开发周期和提升软件的质量。

本文中，我们将通过分析 `pod 安装 (`pod install`)` 的过程，一步一步揭示 CocoaPods 背后的技术。

## 核心组件

CocoaPods是用 Ruby 写的，并由若干个 Ruby 包 (gems) 构成的。在解析整合过程中，最重要的几个 gems 分别是： [CocoaPods/CocoaPods](https://github.com/CocoaPods/CocoaPods/), [CocoaPods/Core](https://github.com/CocoaPods/Core), 和 [CocoaPods/Xcodeproj](https://github.com/CocoaPods/Xcodeproj) (是的，CocoaPods 是一个依赖管理工具 -- 利用依赖管理进行构建的！)。

> <p><span class="secondary radius label">编者注</span> CocoaPods 是一个 objc 的依赖管理工具，而其本身是利用 ruby 的依赖管理 gem 进行构建的


### CocoaPods/CocoaPod

这是是一个面向用户的组件，每当执行一个 `pod` 命令时，这个组件都将被激活。该组件包括了所有使用 CocoaPods 涉及到的功能，并且还能通过调用所有其它的 gems 来执行任务。

### CocoaPods/Core

Core 组件提供支持与 CocoaPods 相关文件的处理，文件主要是 Podfile 和 podspecs。

##### Podfile

Podfile 是一个文件，用于定义项目所需要使用的第三方库。该文件支持高度定制，你可以根据个人喜好对其做出定制。更多相关信息，请查阅 [Podfile 指南](http://guides.cocoapods.org/syntax/podfile.html)。

#### Podspec

`.podspec` 也是一个文件，该文件描述了一个库是怎样被添加到工程中的。它支持的功能有：列出源文件、framework、编译选项和某个库所需要的依赖等。

### CocoaPods/Xcodeproj

这个 gem 组件负责所有工程文件的整合。它能够对创建并修改 `.xcodeproj` 和 `.xcworkspace` 文件。它也可以作为单独的一个 gem 包使用。如果你想要写一个脚本来方便的修改工程文件，那么可以使用这个 gem。

## 运行 `pod install` 命令

当运行 `pod install` 命令时会引发许多操作。要想深入了解这个命令执行的详细内容，可以在这个命令后面加上 `--verbose`。现在运行这个命令 `pod install --verbose`，可以看到类似如下的内容：

	$ pod install --verbose

	Analyzing dependencies

	Updating spec repositories
	Updating spec repo `master`
	  $ /usr/bin/git pull
	  Already up-to-date.


	Finding Podfile changes
	  - AFNetworking
	  - HockeySDK

	Resolving dependencies of `Podfile`
	Resolving dependencies for target `Pods' (iOS 6.0)
	  - AFNetworking (= 1.2.1)
	  - SDWebImage (= 3.2)
	    - SDWebImage/Core

	Comparing resolved specification to the sandbox manifest
	  - AFNetworking
	  - HockeySDK

	Downloading dependencies

	-> Using AFNetworking (1.2.1)

	-> Using HockeySDK (3.0.0)
	  - Running pre install hooks
	    - HockeySDK

	Generating Pods project
	  - Creating Pods project
	  - Adding source files to Pods project
	  - Adding frameworks to Pods project
	  - Adding libraries to Pods project
	  - Adding resources to Pods project
	  - Linking headers
	  - Installing libraries
	    - Installing target `Pods-AFNetworking` iOS 6.0
	      - Adding Build files
	      - Adding resource bundles to Pods project
	      - Generating public xcconfig file at `Pods/Pods-AFNetworking.xcconfig`
	      - Generating private xcconfig file at `Pods/Pods-AFNetworking-Private.xcconfig`
	      - Generating prefix header at `Pods/Pods-AFNetworking-prefix.pch`
	      - Generating dummy source file at `Pods/Pods-AFNetworking-dummy.m`
	    - Installing target `Pods-HockeySDK` iOS 6.0
	      - Adding Build files
	      - Adding resource bundles to Pods project
	      - Generating public xcconfig file at `Pods/Pods-HockeySDK.xcconfig`
	      - Generating private xcconfig file at `Pods/Pods-HockeySDK-Private.xcconfig`
	      - Generating prefix header at `Pods/Pods-HockeySDK-prefix.pch`
	      - Generating dummy source file at `Pods/Pods-HockeySDK-dummy.m`
	    - Installing target `Pods` iOS 6.0
	      - Generating xcconfig file at `Pods/Pods.xcconfig`
	      - Generating target environment header at `Pods/Pods-environment.h`
	      - Generating copy resources script at `Pods/Pods-resources.sh`
	      - Generating acknowledgements at `Pods/Pods-acknowledgements.plist`
	      - Generating acknowledgements at `Pods/Pods-acknowledgements.markdown`
	      - Generating dummy source file at `Pods/Pods-dummy.m`
	  - Running post install hooks
	  - Writing Xcode project file to `Pods/Pods.xcodeproj`
	  - Writing Lockfile in `Podfile.lock`
	  - Writing Manifest in `Pods/Manifest.lock`

	Integrating client project

可以上到，整个过程执行了很多操作，不过把它们分解之后，再看看，会发现它们都很简单。让我们逐步来分析一下。

### 读取 Podfile 文件

你是否对 Podfile 的语法格式感到奇怪过，那是因为这是用 Ruby 语言写的。相较而言，这要比现有的其他格式更加简单好用一些。

在安装期间，第一步是要弄清楚显示或隐式的声明了哪些第三方库。在加载 podspecs 过程中，CocoaPods 就建立了包括版本信息在内的所有的第三方库的列表。Podspecs 被存储在本地路径 `~/.cocoapods` 中。

#### 版本控制和冲突

CocoaPods 使用[语义版本控制 - Semantic Versioning](http://semver.org/) 命名约定来解决对版本的依赖。由于冲突解决系统建立在非重大变更的补丁版本之间，这使得解决依赖关系变得容易很多。例如，两个不同的 pods 依赖于 CocoaLumberjack 的两个版本，假设一个依赖于 `2.3.1`，另一个依赖于 `2.3.3`，此时冲突解决系统可以使用最新的版本 `2.3.3`，因为这个可以向后与 `2.3.1` 兼容。

但这并不总是有效。有许多第三方库并不使用这样的约定，这让解决方案变得非常复杂。

当然，总会有一些冲突需要手动解决。如果一个库依赖于 CocoaLumberjack 的 `1.2.5`，另外一个库则依赖于 `2.3.1`，那么只有最终用户通过明确指定使用某个版本来解决冲突。

### 加载源文件

CocoaPods 执行的下一步是加载源码。每个 `.podspec` 文件都包含一个源代码的索引，这些索引一般包裹一个 git 地址和 git tag。它们以 commit SHAs 的方式存储在 `~/Library/Caches/CocoaPods` 中。这个路径中文件的创建是由 Core gem 负责的。

CocoaPods 将依照 `Podfile`、`.podspec` 和缓存文件的信息将源文件下载到 `Pods` 目录中。

### 生成 Pods.xcodeproj

每次 `pod install` 执行，如果检测到改动时，CocoaPods 会利用 Xcodeproj gem 组件对 `Pods.xcodeproj` 进行更新。如果该文件不存在，则用默认配置生成。否则，会将已有的配置项加载至内存中。

### 安装第三方库

当 CocoaPods 往工程中添加一个第三方库时，不仅仅是添加代码这么简单，还会添加很多内容。由于每个第三方库有不同的 target，因此对于每个库，都会有几个文件需要添加，每个 target 都需要：

- 一个包含编译选项的 `.xcconfig` 文件
- 一个同时包含编译设置和 CocoaPods 默认配置的私有 `.xcconfig` 文件
- 一个编译所必须的 `prefix.pch` 文件
- 另一个编译必须的文件 `dummy.m`

一旦每个 pod 的 target 完成了上面的内容，整个 `Pods` target 就会被创建。这增加了相同文件的同时，还增加了另外几个文件。如果源码中包含有资源 bundle，将这个 bundle 添加至程序 target 的指令将被添加到 `Pods-Resources.sh` 文件中。还有一个名为 `Pods-environment.h` 的文件，文件中包含了一些宏，这些宏可以用来检查某个组件是否来自 pod。最后，将生成两个认可文件，一个是 `plist`，另一个是 `markdown`，这两个文件用于给最终用户查阅相关许可信息。

### 写入至磁盘

直到现在，许多工作都是在内存中进行的。为了让这些成果能被重复利用，我们需要将所有的结果保存到一个文件中。所以 `Pods.xcodeproj` 文件被写入磁盘，另外两个非常重要的文件：`Podfile.lock` 和 `Manifest.lock` 都将被写入磁盘。

#### Podfile.lock

这是 CocoaPods 创建的最重要的文件之一。它记录了需要被安装的 pod 的每个已安装的版本。如果你想知道已安装的 pod 是哪个版本，可以查看这个文件。推荐将 Podfile.lock 文件加入到版本控制中，这有助于整个团队的一致性。

#### Manifest.lock

这是每次运行 `pod install` 命令时创建的 `Podfile.lock` 文件的副本。如果你遇见过这样的错误 `沙盒文件与 Podfile.lock 文件不同步 (The sandbox is not in sync with the Podfile.lock)`，这是因为 Manifest.lock 文件和 `Podfile.lock` 文件不一致所引起。由于 `Pods` 所在的目录并不总在版本控制之下，这样可以保证开发者运行 app 之前都能更新他们的 pods，否则 app 可能会 crash，或者在一些不太明显的地方编译失败。

### xcproj

如果你已经依照我们的建议在系统上安装了 [xcproj](https://github.com/0xced/xcproj)，它会对 `Pods.xcodeproj` 文件执行一下 `touch` 以将其转换成为旧的 ASCII plist 格式的文件。为什么要这么做呢？虽然在很久以前就不被其它软件支持了，但是 Xcode 仍然依赖于这种格式。如果没有 xcproj，你的 `Pods.xcodeproj` 文件将会以 XML 格式的 plist 文件存储，当你用 Xcode 打开它时，它会被改写，并造成大量的文件改动。

## 结果

运行 `pod install` 命令的最终结果是许多文件被添加到你的工程和系统中。这个过程通常只需要几秒钟。当然没有 Cocoapods 这些事也都可以完成。只不过所花的时间就不仅仅是几秒而已了。

## 补充：持续集成

CocoaPods 和持续集成在一起非常融洽。虽然持续集成很大程度上取决于你的项目配置，但 Cocoapods 依然能很容易地对项目进行编译。

### Pods 文件夹的版本控制

如果 Pods 文件夹和里面的所有内容都在版本控制之中，那么你不需要做什么特别的工作，就能够持续集成。我们只需要给 `.xcworkspace` 选择一个正确的 scheme 即可。

### 不受版本控制的 Pods 文件夹

如果你的 `Pods` 文件夹不受版本控制，那么你需要做一些额外的步骤来保证持续集成的顺利进行。最起码，`Podfile` 文件要放入版本控制之中。另外强烈建议将生成的 `.xcworkspace` 和 `Podfile.lock` 文件纳入版本控制，这样不仅简单方便，也能保证所使用 Pod 的版本是正确的。

一旦配置完毕，在持续集成中运行 CocoaPods 的关键就是确保每次编译之前都执行了 `pod install` 命令。在大多数系统中，例如 Jenkins 或 Travis，只需要定义一个编译步骤即可 (实际上，Travis 会自动执行 `pod install` 命令)。对于 [Xcode Bots，在书写这篇文章时我们还没能找到非常流畅的方式](https://groups.google.com/d/msg/cocoapods/eYL8QB3XjyQ/10nmCRN8YxoJ)，不过我们正朝着解决方案努力，一旦成功，我们将会立即分享。

## 结束语

CocoaPods 简化了 Objective-C 的开发流程，我们的目标是让第三方库更容易被发现和添加。了解 CocoaPods 的原理能让你做出更好的应用程序。我们沿着 CocoaPods 的整个执行过程，从载入 specs 文件和源代码、创建 `.xcodeproj` 文件和所有组件，到将所有文件写入磁盘。所以接下来，我们运行 `pod install --verbose`，静静观察 CocoaPods 的魔力如何显现。

---

 

原文: [CocoaPods Under The Hood](http://www.objc.io/issue-6/cocoapods-under-the-hood.html)

译文 [objc.io 第6期 深入理解 CocoaPods](http://blog.jobbole.com/53365/)

精细校对 [@BeyondVincent](http://beyondvincent.com/)
