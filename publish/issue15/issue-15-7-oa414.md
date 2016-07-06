开发者对于为自己的应用写测试有自己的动机。虽然我认为应该写测试，但是这篇文章不是来劝说你来做这个的。

为一个 app 的表现层写测试是一件棘手的工作。Apple 对于对象的逻辑测试已经有内建的支持，但是却没有支持测试那些界面代码的结果。这个功能上的鸿沟实际上造成了很多开发者因为界面测试的复杂性而选择忽视它。

当 Facebook 发布 [`FBSnapshotTestCase`][fbsnapshot] 到 [CocoaPods][cocoapods] 的时候，我起初还因为这个理由忽视了它， 还好我的同事没有。

基于界面的测试意味着验证你用户最终看到的是不是你希望用户看到的。测试界面可以保证不同版本，不同状态的视图看起来可以保持一致。界面测试可以用来提供一个高级别的测试，这涵盖了很多相关对象的用例。

### 它如何运行

`FBSnapShotTestCase` 将一个 `UIView` 或者 `CALayer` 的子类渲染为一个 `UIImage`。这个截图被用和一个已经保存了的截图进行比对，从而创建测试并生成测试的版本。当测试失败的时候，将创建一个失败的测试的参考图片，并且创建一个另外的图像来表现两者的不同之处。

这是一个失败的测试的例子，原因是我们的一个 View Controller 中 gird 元素比预期的要少：

<img src="/images/issues/issue-15/snapshots-reference.png" style="width:100%" alt="Snapshots examples"/>

它通过将 view 或者 layer 以及已经存在的截图渲染到两个 `CGContextRefs`，并且用 C 函数 `memcmp()` 来进行内存比较。这样的比较会非常快，我在一台 MacBook Air 上生成 iPad 或者 iPhone 的全屏截图并进行测试，每张图耗时在 0.013 到 0.086 秒之间。

当配置好以后，它默认会将参考图片存储到你项目的 `[Project]Tests` 目录里面的一个叫 `ReferenceImages` 的子文件夹里。文件夹中是根据你的测试用例的类名建立的文件夹，在测试例文件夹中是每个测试的参考图片。当一个测试失败的时候，它会将失败的结果存储下来，另外再存储一张这个结果和参考图片的差异对比所生成图片。三张图片都会放到应用的 tmp 目录下，截图测试同时会用 `NSLog` 在控制台输出一条命令，你可以用这条命令来启动 [Kaleidoscope][kaleidoscope] 并进行可视化的比较。

### 安装

我们就不在这里兜圈子了：你应该在使用 [CocoaPods][cocoapods] 吧，所以安装仅仅需要在你的 Podfile 的测试 target 里面加入 `pod "FBSnapshotTestCase"`。运行 `pod install`  就可以安装这个库了。

### 带截图的 XCTest

默认的截图测试需要继承 `FBSnapshotTestCase` 而不是 `XCTestCase`，然后使用 `FBSnapshotVerifyView(viewOrLayer, "optional identifier")` 宏来和已经存在的图片验证比较。这里的子类有一个 `recordMode` 的 boolean 属性。当设置了这个值的时候，会录制一个新的截图而不是把结果和参考图片做比较。


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

没有事情是完美的。让我们谈谈不好的一面吧。

* 测试异步的代码很困难。这是在 Cocoa 的测试中经常出现的问题。我有两个解决方案。你可以使用像 [Specta][specta] 或者像 [Kiwi][kiwi] 这样的测试框架，它提供了多次运行断言直到超时或者成功。这意味着你可以给它 0.5 秒的时间运行，同时测试可能被重复多次。或者，你还可以在开发你的应用代码的过程中，让异步的代码在做了标记的时候同步运行。
* 有些组件测试起来很困难。有两个需要注意的例子：在测试中一些 `UIView` 类不能在没有 frame 的时候初始化，所以请总是给你的 view 一个 frame 来避免 `<Error>: CGContextAddRect: invalid context 0x0. [..]` 这样的错误信息。 如果你使用了很多 Auto Layout 代码，那么就不会那么简单了。基于 `CATiledLayer` 的 view 需要在 main screen 上并且在渲染瓦片 (tiles) 前被展现出来。它们同样是异步渲染的。我一般为这些测试加入 [两秒等待][arimagetiletest]。
* 苹果的操作系统补丁会改变部件的渲染方式。比如 Apple 在 iOS 7.1 悄悄改变了字体微调 (font hinting)，所有使用到 `UILabels` 的截图都需要重新录制。
* 每一个截图是一个存在你仓库里面的 PNG 文件，对我的情况来说，每个文件通常大小在 30-100kb 之间。我用 "@2x" 模式记录了所有的测试。截图随着被记录的 view 的增多而增长。 

### 优点

* 我最终做到测试了。我通过对每个通过改变对象而得到的不同的 view 的状态编写了截图测试。这让我能够让在单次的测试中马上看到不同状态的变化。不用在我的 app 中进行点击来进入对应的视图，然后改变状态。我只需要看看 `FBSnapshotTestCase` 渲染的视图，这省去了很多开发时间。
* 截图测试在你运行其他测试的同时运行，不需要作为另外的测试 scheme 进行。它用和其他测试相同的语言书写。它们[大多数情况下](#disadvantages)可以在不将视图显示在屏幕上的时候运行。
* 截图可以让代码审查变得更具体。首先是测试，它们提供一种承诺，说明将要出现的变化。之后是截图，证明测试的承诺是正确的。最后是代码库中的变更。在这个时候，你已经知道变化的内容了，你不仅对内在的改变清楚明白，也对用户在外表上将看到的变化了然于胸。
* 让代码审查可视化，可以让设计师也参与其中。他们通过监测项目的仓库里面的图片控制变化。
* 我发现写截图测试可以提供更多的测试覆盖度。我不相信 100% 的单元测试覆盖度就是最优方案。我尽量做实用的测试，测试大多数引入的变化。截图测试在不用指定代码路径的时候就测试了很多代码路径。这是因为截图测试可以很容易地测试一系列系统元素结合的结果。通过比较截图可以方便的，你可以很快速地达到可观的测试覆盖率。
* 截图测试非常快，在 Macbook Air 中使用 retina 的 iPad 尺寸的图片平均每个测试需要运行 0.015 到 0.080 秒。一个应用里面运行上百个测试都没问题。[我在开发的应用][folio] 有数百个测试，但是它们能在 5 秒以内运行完毕。

### 工具

##### FBSnapShots + Specta + Expecta

我没有使用原生的 XCTest。我用的是 [Specta 和 Expecta][specta]，因为使用的时候更加简单，可读性也更强。这是你在创建一个[新 CocoaPod][newcocoapod] 的时候的初始配置。我是 [Expecta+Snapshots][expmatchers] 这个 pod 的贡献者，它为 `FBSnapshotTestCase` 提供了一个类似 Expecta 的 API。它会为截图命名，同时可以在视图的生命周期里面选择性运行。我的 Podfile 看起来是这样子的：

    target 'MyApp Tests', :exclusive => true do
        pod 'Specta','~> 1.0'
        pod 'Expecta', '~> 1.0'
        pod 'Expecta+Snapshots', '~> 1.0'
    end

然后，我的测试看起来会是这个样子的：

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

解析 console 里面的日志来找到图片要花不少力气，装载不同的失败测试到一个可视化的工具比如 [Kaleidoscope][kaleidoscope] 里，需要运行不少命令行程序。

为了处理几乎所有这些常见的场景，我写了一个 Xcode 插件 [Snapshots][snapshots]。它可以通过 [Alcatraz][alcatraz]  安装或者自己编译。它可以让在 Xcode 中失败测试的失败和成功的图片的比较变得非常容易。

### 总结

[`FBSnapshotTestCase`][fbsnapshot] 给你一个测试视图相关代码的方法，它可以用来测试视图相关的状态而不用依赖于模拟器。如果你使用 Xcode 的话，你可以考虑和我的插件 [Snapshots][snapshots] 一起使用它。有些时候它可能会让人很烦，但是这还是值得的。它可以让设计师参与代码审查阶段，也可以成为为现有项目写测试的简单的第一步，你可以试一试。

开源项目案例:

* [ARTiledImageView](https://github.com/dblock/ARTiledImageView)
* [NAMapKit](https://github.com/neilang/NAMapKit/)
* [ORStackView](https://github.com/orta/ORStackView/)
* [ARCollectionViewMasonryLayout](https://github.com/AshFurrow/ARCollectionViewMasonryLayout)

---

 

原文 [Snapshot Testing](http://www.objc.io/issue-15/snapshot-testing.html)


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
