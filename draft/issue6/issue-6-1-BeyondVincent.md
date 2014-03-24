近些日子我们被宠坏了 -- 我们只需要单击 Xcode 中的一个按钮，这个按钮看起来有点像是在播放一些音乐的动作，过几秒钟之后，我们的程序就会运行起来了，直到遇到一些错误，这非常的神奇。

在本文中，我们将从更高级别的角度来解读 Build 过程，并探索一下在 Xcode 界面中暴露出的 project setting 信息与 Build 过程有什么关系。为了更加深入的探索 Build 过程中，每一步实际执行的工作，我会在本文中引入一些别的文章。


## 解密Build日志

为了了解 Xcode build 过程的内部工作原理，我们首先把突破口瞄准完整的 log 文件上。打开 Log Navigator ，从列表中选择一个 Build ，Xcode 会将 log 文件很完美的展现出来。

![Xcode build log navigator](http://img.objccn.io/issue-6/build-log.png)

默认情况下，上面的 Xcode 界面中隐藏了大量的信息，我们通过选择任务，然后点击右边的展开按钮，就能看到每个任务的详细信息。另外一种可选的方案就是选中列表中的一个或者多个任务，然后选择组合键 Cmd-C，这将会把所有的纯文本信息拷贝至粘贴板。最后，我们还可以选择 Editor 菜单中的"Copy transcript for shown results"，以此将所有的 log 信息拷贝到粘贴板中。

本文给出的示例中，log 信息将近有10,000行(其实大多数的 log 信息是编译 OpenSSL 时生成的，并不是我们自己所写的代码生成的)。下面我们就开始吧！

注意观察输出的 log 信息，首先会发现 log 信息被分为不同的几大块，它们与我们工程中的targets相互对应着：

    Build target Pods-SSZipArchive
    ...
    Build target Makefile-openssl
    ...
    Build target Pods-AFNetworking
    ...
    Build target crypto
    ...
    Build target Pods
    ...
    Build target ssl
    ...
    Build target objcio

本文涉及到的工程有几个依赖项：其中 AFNetworking 和 SSZipArchive 包含在 Pods 中， 而 OpenSSL则以子工程的形式包含在工程中。

针对工程中的每个 target，Xcode 都会执行一系列的操作，将相关的源码，根据所选定的平台，转换为机器可读的二进制文件。下面我们详细的了解一下第一个 target：SSZipArchive。

在针对这个 target 输出的 log 信息中，我们可以看到每个任务被执行的详细情况。例如第一个任务是处理一个预编译头文件(为了增强 log 信息的可读性，我省略了许多细节)：

    (1) ProcessPCH /.../Pods-SSZipArchive-prefix.pch.pch Pods-SSZipArchive-prefix.pch normal armv7 objective-c com.apple.compilers.llvm.clang.1_0.compiler
        (2) cd /.../Dev/objcio/Pods
            setenv LANG en_US.US-ASCII
            setenv PATH "..."
        (3) /.../Xcode.app/.../clang 
                (4) -x objective-c-header 
                (5) -arch armv7 
                ... configuration and warning flags ...
                (6) -DDEBUG=1 -DCOCOAPODS=1 
                ... include paths and more ...
                (7) -c 
                (8) /.../Pods-SSZipArchive-prefix.pch 
                (9) -o /.../Pods-SSZipArchive-prefix.pch.pch

在 build 处理过程中，每个任务都会出现类似上面的这些 log 信息，我们就通过上面的 log 信息进一步了解详情。

1. 类似上面的每个 log 信息块都会利用一行 log 信息来描述相关的任务作为起点。
2. 接着输出带缩进的3行 log 信息，列出了该任务执行的语句。此处，工作目录发生了改变，并对PANG和PATH环境变量进行设置。
3. 这里是发生奇迹的地方。为了处理一个`.pch`文件，调用了 clang，并附带了许多可选项。下面跟着输出的 log 信息显示了显示了完整的调用过程，以及所有的参数。我们看看其中的几个参数...
4. `-x`标示符用来指定所使用的语言，此处是`objective-c-header`。
5. 目标架构指定为`armv7`。
6. 暗示`#define`s的内容已经被添加了。
7. `-c`标示符用来告诉 clang 具体该如何做。`-c`表示：运行预处理器、词法分析器、类型检查、LLVM 的生成和优化，以及target指定汇编代码的生成阶段，最后，运行汇编器以产出一个`.o`的目标文件。
8. 输入文件。
9. 输出文件。

虽然有大量的 log 信息，不过我不会对每个任务做详细的介绍。我们的重点是让你全面的了解在整个 build 过程中，哪些工具会被调用，以及背后会使用到了哪些参数。

针对这个 target ，虽然只有一个.pch文件，但实际上这里对`objective-c-header`文件的处理有两个任务。通过观察具体输出的 log 信息，我们可以知道详情：

    ProcessPCH /.../Pods-SSZipArchive-prefix.pch.pch Pods-SSZipArchive-prefix.pch normal armv7 objective-c ...
    ProcessPCH /.../Pods-SSZipArchive-prefix.pch.pch Pods-SSZipArchive-prefix.pch normal armv7s objective-c ...

从上面的 log 信息中，可以明显的看出 target 针对两种架构做了 build -- armv7 和armv7s -- 因此clang 对文件做了两次处理，每次针对一种架构。

在处理预编译头文件之后，可以看到针对 SSZipArchive target 有另外的几个任务类型。

    CompileC ...
    Libtool ...
    CreateUniversalBinary ...

顾名思义：`CompileC`用来编译 `.m` 和 `.c`文件，`Libtool`用来从目标文件中构建 library，而`CreateUniversalBinary`则将上一阶段产生的两个`.a`文件(每个文件对应一种架构)合并为一个通用的二进制文件，这样就能同时在 armv7 和 armv7s上面运行。

接着，在工程中其它一些依赖项也会发生于此类似的步骤。AFNetworking 被编译之后，会与 SSZipArchive进行链接，以当做 pod library。 OpenSSL 编译之后，会接着处理 crypto 和 ssl target。

当所有的依赖项都 build 完成之后，就轮到我们程序的 target 了。Build 该target时，输出的 log 信息会包含一些非常有价值，并且之前没有出现过的内容：

    PhaseScriptExecution ...
    DataModelVersionCompile ...
    Ld ...
    GenerateDSYMFile ...
    CopyStringsFile ...
    CpResource ...
    CopyPNGFile ...
    CompileAssetCatalog ...
    ProcessInfoPlistFile ...
    ProcessProductPackaging /.../some-hash.mobileprovision ...
    ProcessProductPackaging objcio/objcio.entitlements ...
    CodeSign ...

在上面的任务列表中，根据名称不能区分的唯一任务可能就是 `Ld`，`Ld`是一个 linker 工具的名称，与 `libtool`非常相似。实际上，`libtool`也是简单的调用 `ld` 和 `lipo`。'ld'被用来构建可执行文件，而`libtool`则用来构建 library 文件。阅读[Daniel](http://www.objc.io/issue-6/mach-o-executables.html) 和 [Chris](http://www.objc.io/issue-6/compiler.html)两篇文章，可以了解到更多关于编译和链接的工作原理。

上面每一个步骤，实际上都会调用相关的命令行工具来做实际的工作，这跟之前我们看到的的 `ProcessPCH` 类似。至此，我将不会继续介绍这些 log 信息了，我将带领大家从另外一个不同的角度来继续探索这些任务：Xcode是如何知道哪些任务需要被执行？


##Build过程的控制

当你选中在Xcode 5中的一个工程时，project editor会在顶部显示出6个tabs：General, Capabilities, Info, Build Settings, Build Phases 以及 Build Rules。如下图所示：

![](/images/2013/11/42.png)

其中最后3项与build过程的相关度最大。

####Build Phases####

Build Phases代表着将代码构建为一个可执行文件的规则。它描述了build过程中必须执行的不同任务。

![](/images/2013/11/43.png)

首先，指定了target的依赖项。这将告诉build系统在当前target可以build之前，必须先build target的依赖项。实际上这并不属于真正的build phase，在这里，Xcode只不过将其与build phase显示到一块罢了。

接着是一个CocoaPods相关的脚本需要在build phase执行——更多CocoaPods相关信息可以查看[Michele的文章](http://www.objc.io/issue-6/cocoapods-under-the-hood.html)。

然后在`Compile Sources`中指定了所有必须进行编译的文件。更多相关内容我们将在build rules和build settings中研究。在`Compile Sources`中指定的文件将根据这些rule和setting被处理。

当编译结束，下一步就是将所有的内容链接到一块：`Link Binary with Libraries`。在这里面列出了所有的静态库和动态库，这些库会与上面编译阶段生成的目标文件进行链接。实际上静态库和动态库的处理过程有非常大的区别，相关内容可以参考Daniel的文章 [Mach-O executables](http://www.objc.io/issue-6/mach-o-executables.html)。

当链接完成之后，build phase中最后需要处理的就是将静态资源（例如图片和字体）拷贝到app bundle中。需要注意的是，如果图片资源是PNG格式，那么不仅仅对其进行拷贝，还会做一些优化(如果build settings中的PNG优化是打开的)。

虽然静态资源的拷贝是build phase中的最后一步，但这并不代表build过程已经完成了。例如，还没有进行code signing(这并不是build phase考虑的范畴)，code signing属于build步骤中的最后一步`Packaging`。


####定制Build Phases####

至此，你已经完全可以掌控build phases相关内容(先不考虑默认的设置项)，例如，你可以在build phases中添加运行自定义脚本，就像[CocoaPods](http://www.objc.io/issue-6/cocoapods-under-the-hood.html)使用的一样，来做额外的工作。当然也可以添加一些资源的拷贝任务，当你需要将某些确定的资源拷贝到制定的target目录中，这非常有用。

另外你可以通过定制build phase来添加带有水印(包括版本号和commit hash)的app icon。只需要在build phase中添加一个`Run Script`，然后用下面的命令来获取版本号和commit hash：

```objc
version=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}"`
commit=`git rev-parse --short HEAD`
```

然后可以使用ImageMagick来修改app icon。这里有一个[完整的示例](https://github.com/krzysztofzablocki/IconOverlaying)，可以参考。

如果你希望编写的代码比较简洁点，那么可以添加一个`Run Script`，如果一个源文件超过指定行数，就发出警告。如下代码所示，设置的行数为200。

```objc
find "${SRCROOT}" \( -name "*.h" -or -name "*.m" \) -print0 | xargs -0 wc -l | awk '$1 > 200 && $2 != "total" { print $2 ":1: warning: file more than 200 lines" }'
```


####Build Rules####

Build rules指定了不同文件类型该如何编译。一般来说，开发者并不需要修改这里面的内容。如果你需要对特定的文件类型添加处理方法，那么可以在此处天剑一条新的规则。

一条build rule指定了其应用于那种文件类型，该文件类型是如何被处理的，以及输出内容被放置到何处。比方说，我们创建了一条预处理规则，该规则将Objective-C的实现文件当做输入，然后解析文件内部的注释内容，最后再输出一个.m文件，文件中包含了生成的代码。由于我们不能将.m文件既当做输入又当做输出，所以我使用了.mal后缀，定制的build rule如下所示：

![](/images/2013/11/44.png)

上面的规则应用于所有后缀为*.mal的文件，这些文件会被自定义的脚本处理(调用我们的预处理器，并附带上输入和输出参数)。最后，该规则告诉build system在哪里可以找到此规则的输出文件。

由于这里的输出是一个.m文件，那么build使这些.m文件会被编译处理(就如刚开始介绍的那些预处理步骤)。

在脚本中，我使用了少量的变量来指定正确的路径和文件名。在苹果的[Build Setting Reference.](https://developer.apple.com/library/mac/documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW105)文档中可以找到所有可用的变量。build过程中，要想观察所有已存在的环境变量，你可以添加一个`Run Script` build phase，并勾选上`Show environment variables in build log`。

####Build Settings####

至此，我们已经了解到build phases是如何被用来定义build 过程的步骤，以及build rules是如何指定哪些文件类型在编译阶段需要被预处理。在build settings中，我们可以配置每个任务(之前在build log输出中看到的任务)的详细内容。

在这里，你会发现build 过程的每一个阶段，都有许多选项：从编译、链接一直到code signing和packaging。注意，settings被分割为不同的部分，大部分会于build phases有关联，有时候也会指定编译的文件类型。

这些选项基本都有不错的文档介绍，你可以在右边面板中的quick help inspector或者 [Build Setting Reference](https://developer.apple.com/library/mac/documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW105)中查看到。

###<a id="3"></a>工程文件

上面我们介绍的所有内容都被保存在工程文件(.pbxproj)中，除了其它一些工程相关信息(例如file groups)，我们很少会深入该文件内部，除非在代码merge时发生冲突，或许会进去看看。

我建议你用文本编辑器打开一个工程文件，从头到尾的看一遍里面的内容。它的可读性非常高，里面的许多内容一看就知道什么意思了，不会存在太大的问题。通过阅读并完全理解工程文件，这对于合并工程文件的冲突非常有帮助。

首先，我们来看看文件中叫做`rootObject`的entry。在我的工程中，如下所示：

```objc
rootObject = 1793817C17A9421F0078255E /* Project object */;
```

根据这个ID(1793817C17A9421F0078255E)，我们可以找到main工程的定义：

```objc
/* Begin PBXProject section */
    1793817C17A9421F0078255E /* Project object */ = {
        isa = PBXProject;
...
```
在这部分section中包含了一些keys，顺从这些key，我们可以了解到更多关于这个工程文件的组成。例如，`mainGroup`指向了root file group。如果你按照这个思路，你可以快速了解到在.pbxproj文件中工程的结构。下面我要来介绍一些与build过程相关的内容。其中`target` key指向了build target的定义：

```objc
targets = (
    1793818317A9421F0078255E /* objcio */,
    170E83CE17ABF256006E716E /* objcio Tests */,
);
```

根据第一个id，我们找到一个target的定义：

```objc
1793818317A9421F0078255E /* objcio */ = {
    isa = PBXNativeTarget;
    buildConfigurationList = 179381B617A9421F0078255E /* Build configuration list for PBXNativeTarget "objcio" */;
    buildPhases = (
        F3EB8576A1C24900A8F9CBB6 /* Check Pods Manifest.lock */,
        1793818017A9421F0078255E /* Sources */,
        1793818117A9421F0078255E /* Frameworks */,
        1793818217A9421F0078255E /* Resources */,
        FF25BB7F4B7D4F87AC7A4265 /* Copy Pods Resources */,
    );
    buildRules = (
    );
    dependencies = (
        1769BED917CA8239008B6F5D /* PBXTargetDependency */,
        1769BED717CA8236008B6F5D /* PBXTargetDependency */,
    );
    name = objcio;
    productName = objcio;
    productReference = 1793818417A9421F0078255E /* objcio.app */;
    productType = "com.apple.product-type.application";
};
```

其中`buildConfigurationList`指向了可用的配置项，一般包括`Debug`和`Release`。根据debug对应的id，我们可以找到build setting tab中所有选项存储的位置：

```objc
179381B717A9421F0078255E /* Debug */ = {
    isa = XCBuildConfiguration;
    baseConfigurationReference = 05D234D6F5E146E9937E8997 /* Pods.xcconfig */;
    buildSettings = {
        ALWAYS_SEARCH_USER_PATHS = YES;
        ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME = LaunchImage;
        CODE_SIGN_ENTITLEMENTS = objcio/objcio.entitlements;
...
```

而`buildPhases`属性则简单的列出了在Xcode中定义的所有build phases。这非常容易识别出来(Xcode中的参数使用了它们原本真正的名字，并以C风格进行注释)。

`buildRules`属性是空的：因为在该工程中，我没有自定义build rules。

`dependencies`列出了在Xcode build phase tab中列出的target依赖项。

没那么吓人，不是吗？工程中剩下的内容就留给你去当做练习来了解吧。只需要顺着ID走，即可，一旦你找到了敲门，理解了Xcode中工程设置的不同section，那么对于merge工程文件的冲突时，将变得非常简单。甚至可以在GitHub中就能阅读工程文件，而不用将工程文件clone到本地，并用Xcode打开。

###<a id="4"></a>小结

当今的软件是都用其它复杂的一些软件和资源开发出来的，例如library和build工具等。反过来，这些工具是构建于底层架构的，这犹如剥洋葱一样，一层包着一层。虽然这样一层一层的，给人感觉太复杂，但是你完全可以去深入了解它们，这非常有助于你对软件的深入理解，实际上当你了解之后，这并没有想象中的那么神奇，只不过它是一层一层堆砌起来的，每一层都是基于下一层构建起来的。

在这里，我们只是轻微的探究了一下build过程，当我们点击Xcode中的允许按钮时，并没必要深入了解内部具体发生了什么。只需要了解到build的过程，以及可控的一些操作顺序即可。当然，要想进一步深入了解，可以试着阅读其它一些文章。

从柏林发来最诚挚的祝福!

Chris, Daniel 和 Florian，2013年11月。

---

[话题 #6 下的更多文章](http://objccn.io/issue-6/)

原文: [Editorial](http://www.objc.io/issue-6/editorial.html)

译文 [objc.io 第6期 编译工具 卷首语 - iOS init](http://iosinit.com/?p=943)

精细校对 [@BeyondVincent](http://beyondvincent.com/)
