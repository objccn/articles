当 iOS 7 刚发布的时候，全世界的苹果开发人员都立马尝试着去编译他们的 app，接着再花上数月的时间来修复任何出现的错误，甚至从头开始重建这个 app。这样的结果，使得人们根本无暇去探究 iOS 7 所带来的新思想。除开一些明显而细微的更新，比如说 NSArray 的 `firstObject` 方法——这个方法可追溯到 iOS 4 时代，现在被提为公有 API——还有很多隐藏的技巧等着我们去挖掘。

## 平滑淡入淡出动画

我在这里要讨论的并非新的弹性动画 API 或者 UIDynamics，而是一些更细微的东西。CALayer 增加了两个新方法：`allowsGroupOpacity` 和 `allowsEdgeAntialiasing`。现在，组不透明度（group opacity）不再是什么新鲜的东西了。iOS 会多次使用存在于 Info.plist 中的键 `UIViewGroupOpacity` 并可在应用程序范围内启用或禁用它。对于大多数 app 而言，这（译注：启用）并非所期望的，因为它会降低整体性能。在 iOS 7 中，用 SDK 7 所链接的程序，这项属性默认是启用的。当它被启用时，一些动画将会变得不流畅，它也可以在 layer 层上被控制。

一个有趣的细节，如果 `allowsGroupOpacity` 启用的话，`_UIBackdropView`（被用作 `UIToolbar` 或者 `UIPopoverView` 的背景视图）不能对其模糊进行动画处理，所以当你做一个 alpha 转换时，你可能会临时禁用这项属性。因为这会降低动画体验，你可以回到旧的方式然后在动画期间临时启用 `shouldRasterize`。别忘了设置适当的 `rasterizationScale`，否则在 retina 的设备上这些视图会成锯齿状（pixelerated）。

如果你想要复制 Safari 显示所有选项卡时的动画，那么边缘抗锯齿属性将变得非常有用。

## 阻塞动画

有一个小但是非常有用的新方法 `[UIView performWithoutAnimation:]`。它是一个简单的封装，先检查动画当前是否启用，如果是则停用动画，执行块语句，然后重新启用动画。一个需要说明的地方是，它并 *不会* 阻塞基于 CoreAnimation 的动画。因此，不用急于将你的方法调用从：

	    [CATransaction begin];
        [CATransaction setDisableActions:YES];
        view.frame = CGRectMake(...);
        [CATransaction commit];

替换成:

        [UIView performWithoutAnimation:^{
	        view.frame = CGRectMake(...);
        }];

但是，绝大多数情况下这样也能工作得很好，只要你不直接跟 CALayer 打交道。

iOS 7 中，我有很多代码路径（主要是 `UITableViewCells`）需要额外保护以防止意外的动画，例如，如果一个弹窗（popover）的大小调整了，与此同时其中的表视图将因为高度的变化而加载新的 cell。我通常的做法是将整个 `layoutSubviews` 的代码包扎到一个动画块中：

    - (void)layoutSubviews 
    {
        // 否则在 iOS 7 的传统模式下弹窗动画会渗入我们的单元格
        [UIView performWithoutAnimation:^{
            [super layoutSubviews];
            _renderView.frame = self.bounds;
        }];
    }


## 处理长的表视图

`UITableView` 非常快速高效，除非你开始使用 `tableView:heightForRowAtIndexPath:`，它会开始为你表中 *每一个* 元素调用此方法，即便没有可视对象——这是为了让其下层的 `UIScrollView` 能获取正确的 `contentSize`。此前有一些变通方法，但都不好用。iOS 7 中，苹果公司终于承认这一问题，并添加了  `tableView:estimatedHeightForRowAtIndexPath:`，这个方法把绝大部分计算成本推迟到实际滚动的时候。如果你完全不知道一个 cell 的大小，返回 `UITableViewAutomaticDimension` 就行了。

对于段头/尾（section headers/footers），现在也有类似的 API 了。

## UISearchDisplayController

苹果的 search controller 使用了新的技巧来简化移动 search bar 到 navigation bar 的过程。启用 `displaysSearchBarInNavigationBar` 就可以了（除非你还在用 scope bar，那你就太不幸了）。我倒是很喜欢这么做，但遗憾的是，iOS 7 上的 `UISearchDisplayController` 貌似被破坏得相当严重，尤其在 iPad 上。苹果公司看上去像是没时间处理这个问题，对于显示的搜索结果并不会隐藏实际的表视图。在 iOS 7 之前，这不算问题，但是现在 `searchResultsTableView` 有一个透明的背景色，使它看上去相当糟糕。作为一种变通方法，你可以设置不透明背景色或者采取一些[更富于技巧的手段](http://petersteinberger.com/blog/2013/fixing-uisearchdisplaycontroller-on-ios-7/)来获得你期望的效果。关于这个控件我碰到过各种各样的结果，当使用 `displaysSearchBarInNavigationBar` 时甚至 *根本* 不会显示搜索表视图。

你的结果可能有所不同，但我依赖于一些手段（severe hacks）来让 `displaysSearchBarInNavigationBar` 工作：

	- (void)restoreOriginalTableView 
    {
	    if (PSPDFIsUIKitFlatMode() && self.originalTableView) {
	        self.view = self.originalTableView;
	    }
	}

	- (UITableView *)tableView 
    {
	    return self.originalTableView ?: [super tableView];
	}

	- (void)searchDisplayController:(UISearchDisplayController *)controller 
      didShowSearchResultsTableView:(UITableView *)tableView 
    {
	    // HACK: iOS 7 依赖于重度的变通来显示搜索表视图
	    if (PSPDFIsUIKitFlatMode()) {
	        if (!self.originalTableView) self.originalTableView = self.tableView;
	        self.view = controller.searchResultsTableView;
	        controller.searchResultsTableView.contentInset = UIEdgeInsetsZero; // 移除 64 像素的空白
	    }
	}

	- (void)searchDisplayController:(UISearchDisplayController *)controller 
      didHideSearchResultsTableView:(UITableView *)tableView 
    {
	    [self restoreOriginalTableView];
	}

另外，别忘了在 `viewWillDisappear` 中调用 `restoreOriginalTableView`，否则程序会 crash。
记住这只是一种解决办法；可能还有不那么激进的方法，不用替换视图本身，但这个问题确实应该由苹果公司来修复。（TODO: RADAR!）

## 分页

`UIWebView` 现在可以对带有 `paginationMode` 的网站进行自动分页。有一大堆与此功能相关的新属性：

	@property (nonatomic) UIWebPaginationMode paginationMode NS_AVAILABLE_IOS(7_0);
	@property (nonatomic) UIWebPaginationBreakingMode paginationBreakingMode NS_AVAILABLE_IOS(7_0);
	@property (nonatomic) CGFloat pageLength NS_AVAILABLE_IOS(7_0);
	@property (nonatomic) CGFloat gapBetweenPages NS_AVAILABLE_IOS(7_0);
	@property (nonatomic, readonly) NSUInteger pageCount NS_AVAILABLE_IOS(7_0);

目前而言，虽然这不一定对大多数网站都有用，但它肯定是生成简单的电子书阅读器或者显示文本的一种更好的方式。加点乐子的话，请尝试将它设置为 `UIWebPaginationModeBottomToTop`。

## 会飞的 Popover

想知道为什么你的 popover 疯了一样到处乱飞？在 `UIPopoverControllerDelegate` 协议中有一个新的代理方法让你能控制它：

    -  (void)popoverController:(UIPopoverController *)popoverController
      willRepositionPopoverToRect:(inout CGRect *)rect 
                           inView:(inout UIView **)view

当 popover 锚点是指向一个 `UIBarButtonItem` 时，`UIPopoverController` 会做出合适的展现，但是如果你让它在一个 view 或者 rect 中显示，你可能就需要实现此方法并正常返回。一个花费了我相当长时间来验证的问题——如果你通过改变 `preferredContentSize` 来动态调整你的 popover，那么这个方法就尤其需要实现。苹果公司现在对改变 popover 大小的请求更严格，如果没有预留足够的空间，popover 将会到处移动。

## 键盘支持

苹果公司不只为我们提供了[全新的 framework 用于游戏控制器](https://developer.apple.com/library/ios/documentation/ServicesDiscovery/Conceptual/GameControllerPG/Introduction/Introduction.html)，它也给了我们这些键盘爱好者一些关注！你会发现新定义的公用键，比如  `UIKeyInputEscape` 或 `UIKeyInputUpArrow`，可以使用全新的 [`UIKeyCommand`](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIKeyCommand_class/Reference/Reference.html#//apple_ref/occ/instp/UIKeyCommand/input) 类截查。在 iOS 7 之前，只能通过一些[难以言表的手段来处理键盘命令](http://petersteinberger.com/blog/2013/adding-keyboard-shortcuts-to-uialertview/)，现在，就让我们操起蓝牙键盘试试看我们能用这个做什么！

开始之前，你需要对响应链（responder chain）有个了解。你的 `UIApplication` 继承自  `UIResponder`，`UIView` 和 `UIViewController` 也是如此。如果你曾经处理过 `UIMenuItem`  并且没有使用[我的基于块的包装](https://github.com/steipete/PSMenuItem)的话，那么你对此已经有所了解。事件先被发送到最上层的响应者，然后一级级往下传递直到 UIApplication。为了捕获按键命令，你需要告诉系统你关心哪些按键命令（而不是全捕获）。为了完成这个，你需要重写 `keyCommands` 这个新属性：

    - (NSArray *)keyCommands 
    {
        return @[[UIKeyCommand keyCommandWithInput:@"f"
                                     modifierFlags:UIKeyModifierCommand  
                                            action:@selector(searchKeyPressed:)]];
    }

    - (void)searchKeyPressed:(UIKeyCommand *)keyCommand 
    {
        // 响应事件
    }


<img src="/images/issues/issue-5/responder-chain.png" name="工作中的响应者链" width="472" height="548">

现在可别太激动，需要注意的是，这个方法只在键盘可见时有效（比如有类似 `UITextView` 这样的对象作为第一响应者时）。对于全局热键，你仍然需要用上面提到的 hack 方法。除去那些，这个解决途径还是很优雅的。不要覆盖类似 cmd-V 这种系统的快捷键，它会被自动映射到 `paste:` 方法。

还有一些新的预定义的响应者行为：

	- (void)increaseSize:(id)sender NS_AVAILABLE_IOS(7_0);
	- (void)decreaseSize:(id)sender NS_AVAILABLE_IOS(7_0);

它们分别对应 cmd+ 和 cmd- 命令，用来放大/缩小内容。

## 匹配键盘背景

苹果公司终于公开了 [`UIInputView`](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIInputView_class/Reference/Reference.html)，其中提供了一种方式——使用 `UIInputViewStyleKeyboard` 来匹配键盘样式。这使得你能编写自定义的键盘或者适应默认样式的默认键盘的扩展（工具条）。这个类[一开始](https://github.com/nst/iOS-Runtime-Headers/commits/master/Frameworks/UIKit.framework/UIInputView.h)就存在了，不过现在我们终于可以绕过私有API的方式来使用它了。

如果 `UIInputView` 是一个 `inputView` 或者 `inputAccessoryView` 的*根视图*，它将只显示一个背景，否则它将是透明的。遗憾的是，这并不能让你实现一个未填充的分离态的键盘，但它仍然比用一个简单的 UIToolbar 要好。我还没看到苹果在何处使用这个新 API，看上去 Safari 里仍然使用着 `UIToolbar`。

## 了解你的无线电通信

虽然早在 iOS 4 的时候，大部分的运营商信息已经在 CTTelephony 暴露了，但它通常只用于特定场景并非十分有用。iOS 7 中，苹果公司为其添加了一个方法，其中最有用的：`currentRadioAccessTechnology`。这个方法能告诉你手机是处于较慢的 GPRS 还是高速的 LTE 或者介于其中。目前还没有方法得到连接速度（当然手机本身也无法获取这个），但是这足以用来优化一个下载管理器，让其在 EDGE 下不用尝试 *同时* 去下载6张图片了。

现在还没有 `currentRadioAccessTechnology` 的相关文档，为了让它工作，会遇到一些麻烦和错误。当你想要获取当前网络信号值，你应当注册一个 `CTRadioAccessTechnologyDidChangeNotification` 通知而不是去轮询这个属性。为了确切的使 iOS 发送这些通知，你需要持有一个 `CTTelephonyNetworkInfo` 的实例，但不要在通知中创建  `CTTelephonyNetworkInfo` 的实例，否则会 crash。

在这个简单的例子中，因为在 block 中捕获 `telephonyInfo` 将会持有它，所以我就这么用了：

    CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
    NSLog(@"Current Radio Access Technology: %@", telephonyInfo.currentRadioAccessTechnology);
    [NSNotificationCenter.defaultCenter addObserverForName:CTRadioAccessTechnologyDidChangeNotification 
                                                    object:nil 
                                                     queue:nil 
                                                usingBlock:^(NSNotification *note) 
    {
        NSLog(@"New Radio Access Technology: %@", telephonyInfo.currentRadioAccessTechnology);
    }];

当手机从 Edge 环境切换到 3G，日志输出应该像这样：

	iOS7Tests[612:60b] Current Radio Access Technology: CTRadioAccessTechnologyEdge
	iOS7Tests[612:1803] New Radio Access Technology: (null)
	iOS7Tests[612:1803] New Radio Access Technology: CTRadioAccessTechnologyHSDPA

苹果导出了所有字符串符号，因此可以很简单的比较和检测当前的网络信息。

## Core Foundation，Autorelease 和你

Core Foundation 中出现了一个新的辅助方法，它被用于私有调用已有数年时间：

	CFTypeRef CFAutorelease(CFTypeRef CF_RELEASES_ARGUMENT arg)

它的确做了你所期望的事，让人费解的是苹果花了这么长时间才把它公开。ARC 下，大多数人在处理返回 Core Foundation 对象时是通过转换成对等的 NS 对象来完成的，如返回一个  `NSDictionary`，虽然它是一个 `CFDictionaryRef`，简单地使用 `CFBridgingRelease()` 就行了。这样通常没问题，除非你返回的没有可用的对等 NS 对象，如 `CFBagRef`。你要么使用 id，这样会失去类型安全性，要么你将你的方法重命名为 `createMethod` 并考虑所有的内存语义，最后使用 CFRelease。还有一些手段，比如[这个](http://favstar.fm/users/AndrePang/status/18099774996)，使用 non-ARC-file 参数你才能编译它，但终归得使用 CFAutorelease()。另外：不要编写使用苹果公司命名空间的代码，所有这些自定义的 CF-宏将来都会被打破的。

## 图片解压缩

当通过 `UIImage` 展示一张图片时，在显示之前需要解压缩（除非图片源已经像素缓存了）。对于 JPG/PNG 文件这会占用相当可观的时间并会造成卡顿。iOS 6 以前，通常是通过创建一个位图上下文，然后在其中画图来解决。[（参见 AFNetworking 如何处理这个问题）](https://github.com/AFNetworking/AFNetworking/blob/09658b352a496875c91cc33dd52c3f47b9369945/AFNetworking/AFURLResponseSerialization.m#L442-518)。

从 iOS 7 开始，你可以使用 `kCGImageSourceShouldCacheImmediately`: 强制图片在创建时直接解压缩：

	+ (UIImage *)decompressedImageWithData:(NSData *)data 
    {
	    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
	    CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, 0, (__bridge CFDictionaryRef)@{(id)kCGImageSourceShouldCacheImmediately: @YES});
	    
	    UIImage *image = [UIImage imageWithCGImage:cgImage];
	    CGImageRelease(cgImage);
	    CFRelease(source);
	    return image;
	}

刚发现这一点时我很很兴奋，但不要高兴得太早。在我的测试中，开启即时缓存后性能实际上有所 *降低*。要么这个方法最终是在主线程中被调用的（好像不太可能），要么感官上的性能下降是因为其在方法 `copyImageBlockSetJPEG` 中锁住了，因为这个方法也被用在主线程显示非加密的图片时。在我的 app 中，我在主线程中加载小的预览图，在后台线程中加载大型图，使用了 `kCGImageSourceShouldCacheImmediately` 后小小的解压缩阻塞了主线程，同时在后台处理大量开销昂贵的操作。	

<img src="/images/issues/issue-5/image-decompression.png" name="Image Decompression Stack Trace" width="662" height="1008">


还有更多关于图片解压缩的却不是 iOS 7 中的新东西，像 `kCGImageSourceShouldCache`，它用来控制系统自动卸载解压缩图片数据的能力。确保你将它设置为 YES，否则所有的工作都将没有意义。有趣的是，苹果在 64-bit 运行时的系统中将 `kCGImageSourceShouldCache` 的 *默认值* 从 NO 改为了 YES。
	
## 盗版检查

苹果添加了一个方式，通过 NSBunble 上的新方法 [`appStoreReceiptURL`](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSBundle_Class/Reference/Reference.html#//apple_ref/occ/instm/NSBundle/appStoreReceiptURL) 来获取和验证 Lion 系统上 App Store 的收据，现在终于也移植到了 iOS 上了。这使得你可以检查你的应用是合法购买的还是被破解了的。检查收据还有另一个重要的原因，它包含了 *初始购买日期*，这点对于把你的应用从付费模式迁移到免费+应用内付费模式很有帮助。你可以根据这个初始购买日期来决定额外内容对于你的用户是免费（因为他们已经付过费了）还是收费的。

收据还允许你检查应用程序是否通过批量购买计划购买以及该许可证是否仍有效，有一个名为  `SKReceiptPropertyIsVolumePurchase` 的属性标示了该值。

当你调用 `appStoreReceiptURL` 时，你需要特别注意，因为在 iOS 6 上，它还是一个私有 API，你应该在用户代码中先调用 `doesNotRecognizeSelector:`，在调用前检查运行（基础）版本。在开发期间，这个方法返回的 URL 不会指向一个文件。你可能需要使用 StoreKit 的 [`SKReceiptRefreshRequest`](https://developer.apple.com/library/ios/documentation/StoreKit/Reference/SKReceiptRefreshRequest_ClassRef/SKReceiptRefreshRequest.html)，这也是 iOS 7 中的新东西，用它来下载证书。使用一个至少有过一次购买的测试用户，否则它将没法工作：

    // 刷新收据
    SKReceiptRefreshRequest *request = [[SKReceiptRefreshRequest alloc] init];
    [request setDelegate:self];
    [request start];

验证收据需要大量的代码。你需要使用 OpenSSL 和内嵌的[苹果根证书](http://www.apple.com/certificateauthority/)，并且你还要了解一些基本的东西像是证书、[PCKS 容器](http://en.wikipedia.org/wiki/PKCS)以及 [ASN.1](http://de.wikipedia.org/wiki/Abstract_Syntax_Notation_One)。这里有一些[样例代码](https://github.com/rmaddy/VerifyStoreReceiptiOS)，但是你不应该让它这么简单——尤其是对那些有“高尚意图”的人，别只是拷贝现有的验证方法，至少做点修改或者编写你自己的，你应该不希望一个普通的补丁程序就能在数秒内瓦解你的努力吧。

你绝对应该读读苹果的指南——[验证 Mac App 商店收据](https://developer.apple.com/library/mac/releasenotes/General/ValidateAppStoreReceipt/index.html#//apple_ref/doc/uid/TP40010573-CH1-SW6)，这里面的大多数都适用于 iOS。苹果在 [WWDC 2013 的 Session 308 “Using Receipts to Protect Your Digital Sales”](https://developer.apple.com/wwdc/videos/) 中详述了通过新加入的“Grand Unified Receipt”而带来的变动。
 
## Comic Sans MS

承认吧，你是怀念 Comic Sans MS 的。在 iOS 7 中，Comic Sans MS 终于回来了。iOS 6 中添加了可下载字体，但那时的字体列表很少也不见得有趣。在 iOS 7 中苹果添加了不少字体，包括 “famous”，它和 [PT Sans](http://www.fontsquirrel.com/fonts/PT-Sans) 或 [Comic Sans MS](http://sixrevisions.com/graphics-design/comic-sans-the-font-everyone-loves-to-hate/) 有些类似。`kCTFontDownloadableAttribute` 并没有在 iOS 6 中声明，所以 iOS 7 之前它并不真正可用，但苹果确是在 iOS 6 的时候就已经做了私有声明了。

<img src="/images/issues/issue-5/comic-sans-ms.png" name="Who doesn't love Comic Sans MS" width="414" height="559">

字体列表是[动态变化](http://mesu.apple.com/assets/com_apple_MobileAsset_Font/com_apple_MobileAsset_Font.xml)的，以后可能就会发生变动。苹果在 [Tech Note HT5484](http://support.apple.com/kb/HT5484) 中罗列了一些可用的字体，但这个文档已经过时了，并不能反映 iOS 7 的变化。

这里显示了你该如何获取一个用 `CTFontDescriptorRef` 标示的可下载的字体数组：

	CFDictionary *descriptorOptions = @{(id)kCTFontDownloadableAttribute : @YES};
	CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes((CFDictionaryRef)descriptorOptions);
	CFArrayRef fontDescriptors = CTFontDescriptorCreateMatchingFontDescriptors(descriptor, NULL);

系统不会检查字体是否已存在于磁盘上而将直接返回同样的列表。另外，这个方法可能会启用网络并造成阻塞，你不应该在主线程中使用它。

使用如下基于块的 API 来下载字体：	

	bool CTFontDescriptorMatchFontDescriptorsWithProgressHandler(
	         CFArrayRef                          descriptors,
	         CFSetRef                            mandatoryAttributes,
	         CTFontDescriptorProgressHandler     progressBlock)

这个方法能操作网络并传递下载进度信息来调用你的 `progressBlock` 方法直到下载成功或者失败。参考苹果的 [DownloadFont 样例](https://developer.apple.com/library/ios/samplecode/DownloadFont/Listings/DownloadFont_ViewController_m.html)看看如何使用它。    

有一些值得注意的地方，这里的字体只在当前程序运行时有效，下次运行将被重新载入内存。因为字体存放在共享空间中，你不能依赖于它们是否可用。很有可能但不能保证地说，系统会清理这个目录，或者你的程序被拷贝到没有这个字体的新设备中，同时你又没有网络。在 Mac 或是模拟器上，你能根据 `kCTFontURLAttribute` 获得字体的绝对路径，加载速度也会提升，但是在 iOS 上是不行的，因为这个目录在你的程序之外，你需要再次调用 `CTFontDescriptorMatchFontDescriptorsWithProgressHandler`。

你也可以注册新的 `kCTFontManagerRegisteredFontsChangedNotification` 通知来跟踪新字体在何时被载入到了字体注册表中。你可以在 [WWDC 2013 的 Session 223 “Using Fonts with TextKit”](https://developer.apple.com/wwdc/videos/)中查找更多信息。

## 这还不够?

没关系，iOS 7 的新东西远不止如此！了解一下 [NSHipster](http://nshipster.com/ios7/) 你将明白语音合成相关的东西，base64、全新的 `NSURLComponents`、`NSProgress`、条形码扫描、阅读列表以及 `CIDetectorEyeBlink`。还有很多我们没有涵盖到的，比如苹果的 [iOS 7 API 变化](https://developer.apple.com/library/ios/releasenotes/General/iOS70APIDiffs/index.html#//apple_ref/doc/uid/TP40013203)，[What's new in iOS](https://developer.apple.com/library/ios/releasenotes/General/WhatsNewIniOS/Articles/iOS7.html)指南以及 [Foundation Release Notes](https://developer.apple.com/library/prerelease/mac/releasenotes/Foundation/RN-Foundation/index.html#//apple_ref/doc/uid/TP30000742)（这些都是基于 OS X的，但是代码都是共享的，很多也同样适用于 iOS）。很多新方法都还没形成文档，等着你来探究和写成博客。

---

 

原文 [iOS 7: Hidden Gems and Workarounds](http://www.objc.io/issue-5/iOS7-hidden-gems-and-workarounds.html)

译文 [iOS 7: 隐藏的特性和解决之道](http://test-0x01.logdown.com/posts/159702-ios-7-hidden-gems-and-workarounds)

精细校对 [unblue](https://github.com/uncleblue)