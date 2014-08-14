开发者对于为自己的应用写测试有自己的动机。虽然我认为应该写测试，但是这篇文章不是来劝说你来做这个的。

一个 app 的表现层写测试是一个棘手的工作。Apple 对于对象的逻辑测试已经有内建的支持，但是却没有支持测试那些界面代码的结果。这个功能上的鸿沟意味着很多开发者因为界面测试的复杂性而忽视了它。

当 Facebook 发布 [`FBSnapshotTestCase`][fbsnapshot] 到 [CocoaPods][cocoapods] 的时候，我还因为这个理由忽视了它， 还好我的同事没有。

基于界面的测试意味着验证你用户最终看到的是不是希望用户看到的。测试界面可以保证不同版本，不同状态的视图可以保持一致。界面测试可以用来提供一个高级别的测试，涵盖了很多相关对象的用法。

### 它如何运行

`FBSnapShotTestCase` 采用一个 `UIView` 或者 `CALayer` 子类来渲染到一个 `UIImage`。这个截图用来创建一个进行对已经保存 了的截图进行比对的测试，当它失败的时候，它会创建一个失败测试的参考凸显，并且创建一个另外的图像来表现两者的不同。

这是一个因为我们的一个 View Controller 中 gird 元素比预期少而导致失败的例子 

<img src="http://img.objccn.io/issue-15/snapshots-reference.png" style="width:100%" alt="Snapshots examples"/>

它通过渲染 view 或者 layer 和已经存在的截图到两个 `CGContextRefs`，并且用 C 函数 `memcmp()` 来进行内存比较。 这样比较会非常快，我在一台 MacBook Air 上 测试生成一个 iPad 或者 iPhone 的全屏截图只要 0.013 到 0.086 秒之间。

当它配置完成的时候，它默认会将图片存储到你项目的 `[Project]Tests` 目录里面的一个叫 `ReferenceImages` 的子文件夹。文件夹中是根据你的单元测试的类名建立的文件夹，里面是每个参考图片的链接。 当一个测试失败的时候，它会将失败的结果和差异对比生成图片。三种图片都会存储到应用的 tmp 目录，截图同时会用 `NSLog` 将命令输出到控制台来用 [Kaleidoscope][kaleidoscope] 做可视化的比较。

### 安装

我们就不在这里兜圈子了：你需要使用 [CocoaPods][cocoapods]，所以安装仅仅需要在你的 Podfile 的测试 target 里面加入 `pod "FBSnapshotTestCase"`。运行 `pod install`  就可以安装这个库了。

### XCTest 和截图

默认的截图测试需要继承 `FBSnapshotTestCase` 而不是 `XCTestCase`，然后使用 `FBSnapshotVerifyView(viewOrLayer, "optional identifier")` 宏来验证比较已经存在的图片。这里的子类有一个 `recordMode` boolean 属性。当设置了这个值的时候，会录制一个新的截图而不是把结果和参考图片做比较。

# Headers

    @interface ORSnapshotTestCase : FBSnapshotTestCase
    @end
  
    @implementation ORSnapshotTestCase
  
    - (void)testHasARedSquare
    {
        // Removing this will verify instead of recording
        self.recordMode = YES;
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        view.backgroundColor = [UIColor redColor];
        FBSnapshotVerifyView(view, nil);
    }
  
    @end

<a name="disadvantages"> </a>

### 缺点

没有事情是完美的。让我们谈谈消极的一面吧。


* 测试异步的代码很困难。这是在 Cocoa 的测试中经常出现的问题。我有两个解决方案。你可以使用像 [Specta][specta] 或者像 [Kiwi][kiwi] 这样的测试框架，它提供了多次运行断言直到超时或者成功。这意味着你给了它 0.5 秒的时间运行，同时测试可能被重复多次。 此外。你还可以在开发你的应用代码的过程中，让异步的代码在做了标记的时候同步运行。
* 有些组成部分测试起来很困难。有两个需要注意的例子：一些 `UIView` 类不能在没有 frame 的时候初始化，所以请总是给你的 view 一个 frame 来避免 `<Error>: CGContextAddRect: invalid context 0x0. [..]` 这样的错误信息。 如果你使用了很多 Auto Layout 代码，那么就不会那么简单了。基于 `CATiledLayer` 的 view 需要在 main screen 上并且在渲染 tits（瓦片）前被展现出来。它同样是异步渲染的。我一般为这些测试加入 [two-second wait][arimagetiletest] 。
* 苹果的操作系统补丁会改变他们的渲染的优先级。当 Apple 在 iOS 7.1 悄悄改变了 font hinting（字体提示），任何关于 `UILabels` 的截图需要重新录制。
* 每一个截图是一个存在你仓库里面的　PNG 文件，我的每个文件通常大小在 30-100kb 之间。我用 "@2x." 模式记录了所有的测试。截图随 被记录的 view 大小而增长。 

### 优点


* 我最早的时候放弃了测试。但是现在我为改变对象的时候每一个不同的视图状态进行了截图测试。它是我能够让在单独的测试中马上看到状态的变化。不用在我的 app 中进行点击来进入对应的视图，然后改变状态。我只需要看看 `FBSnapshotTestCase` 渲染的视图，这省去了很多编译的时间。
* 截图测试在你运行其他测试的同时运行，不需要作为另外的测试 scheme 进行。它用和其他测试相同的语言书写。它们 [几乎](#disadvantages) 可以在不在屏幕显示视图的时候运行。
* 截图可以让 code review 有了一个完整的过程。首先进行测试，保证提供将要出现的变化。之后是截图，保证测试是正确的。最后，展现变更的代码。当你做了变更的时候，你能保证内部的改变和用户看见的外部变化是一致的。
* 让 Code review 可视化，可以让设计师也参与其中。他们通过监测项目的仓库里面的图片控制变化。
* 截图测试是快的，现在的 Macbook Air 中使用 retina 的 iPad 尺寸的图片平均每个测试需要运行 0.015 到 0.080 秒。 每个应用里面运行上百个测试都没问题。[我在开发的应用][folio] 有数百个测试，但是能在 5 秒以内运行完毕。
* 我发现写截图测试的时候提供了更多的测试覆盖度。我不相信通过 100% 的单元测试覆盖度是好的。我尽量做实用的测试，测试大多数的变化。截图测试在不用指定代码路径的时候测试了很多代码路径。这是因为截图测试的结果是从一系列系统元素结合的。通过比较截图可以方便的轻量的覆盖测试。

### 工具


##### FBSnapShots + Specta + Expecta

我没有使用原生的 XCTest。我用的是 [Specta 和 Expecta][specta]，因为使用的时候更加简单，可读性也更强。这是你在创建一个 [新 CocoaPod][newcocoapod] 的时候的初始配置。我是 pod [Expecta+Snapshots][expmatchers] 的贡献者，它为  `FBSnapshotTestCase` 提供了一个类似 Expecta 的API。 它会为截图命名，同时可以在视图的生命周期里面选择性运行。我的 Podfile 看起来是这样子的：

    target 'MyApp Tests', :exclusive => true do
        pod 'Specta','~> 1.0'
        pod 'Expecta', '~> 1.0'
        pod 'Expecta+Snapshots', '~> 1.0'
    end



然后，我的测试看起来会是这个样子的：

# Headers

    SpecBegin(ORMusicViewController)
    
    it (@"notations in black and white look correct", ^{
        UIView *notationView = [[ORMusicNotationView alloc] initWithFrame:CGRectMake(0, 0, 80, 320)];
        notationView.style = ORMusicNotationViewStyleBlackWhite;
    
        expect(notationView).to.haveValidSnapshot();
    });
    
    it (@"Initial music view controller looks corrects", ^{
        id contoller = [[ORMusicViewController alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        controller.view.frame = [UIScreen mainScreen].bounds;
    
        expect(controller).to.haveValidSnapshot();
    });

    SpecEnd

### Snapshots Xcode 插件 

解析 console 里面的日志来找到图片要花不少力气，装载不同的失败测试到一个可视化的工具比如 [Kaleidoscope][kaleidoscope] 需要运行不少命令行程序。

为了处理这些常见的场景，我写了一个 Xcode 插件 [Snapshots][snapshots]。它可以通过 [Alcatraz][alcatraz]  安装或者自己编译。它可以让在Xcode中比较失败和成功的图片变得非常容易。

### 总结

[`FBSnapshotTestCase`][fbsnapshot] 给你一个测试视图相关代码的方法，它可以用来测试视图相关的状态而不用依赖于模拟器。如果你使用Xcode的话，你应该用我的插件[Snapshots][snapshots] 来使用它。有些时候它令人沮丧，但是同时它也是有效果的。它可以让设计师参与 code review 阶段。它可以成为为现有项目写测试的简单的第一步，你可以试一试。

开源项目案例:

* [ARTiledImageView](https://github.com/dblock/ARTiledImageView)
* [NAMapKit](https://github.com/neilang/NAMapKit/)
* [ORStackView](https://github.com/orta/ORStackView/)
* [ARCollectionViewMasonryLayout](https://github.com/AshFurrow/ARCollectionViewMasonryLayout)

[cocoapods]: http://cocoapods.org "CocoaPods homepage"

[fbsnapshot]: https://github.com/facebook/ios-snapshot-test-case "FBSnapshotTestCase Github Repo"

[specta]: http://github.com/specta/specta/ "Specta Github Repo"

[expmatchers]: https://github.com/dblock/ios-snapshot-test-case-expecta "EXPMatchers+FBSnapshotTest Github Repo"

[kiwi]: https://github.com/kiwi-bdd/Kiwi "Kiwi Github Repo"

[arimagetiletest]: https://github.com/dblock/ARTiledImageView/blob/master/IntegrationTests/ARTiledImageViewControllerTests.m#L31/ "Test example from ARTiledImageView"

[kaleidoscope]: http://www.kaleidoscopeapp.com "Kaleidoscope.app Web Site"

[snapshots]: http://github.com/orta/snapshots "Snapshots Github Repo"

[alcatraz]: http://alcatraz.io "Alcatraz the Xcode Plugin Manager"

[newcocoapod]: http://guides.cocoapods.org/making/using-pod-lib-create.html "CocoaPods Guide"

[folio]: http://orta.github.io/#folio-header-unit "Artsy Folio Website"
