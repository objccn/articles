插件是给你已经发布的 App 增加功能的一个好办法，Mac上的 App 支持插件已经有很长的历史了，比如Adobe Photoshop，在 1991 年的 version 2.0 就开始支持了。

在以前的OS X系统中，给你的 App 在运行时动态载入可执行代码比较困难。现在，在 `NSBundle` 的帮助和你的一些前瞻性思维的帮助下下，它从未如此简单。 

## Bundles 和 接口

如果你打开 Xcode5 并且创建一个新项目，你会看见 OS X 选项卡下有一个 "Application Plug-in" 的分类和 "System Plug-in" 的分类，从 Screen Savers 到 Image Units，在Xcode里面一共有12中不同的模板可以编写 App 的插件。如果你点击“Framework & Library”的选项卡，你将可以看见一个Bundle条目。这是一个非常简单的，并且是我会在今天带大家探索的项目，在一个修改过的 TextEdit 里面加入加载 bundle 的功能。



> 注意：Apple 称这些为 plug-ins ，而通常大家更喜欢用 plugins 称呼。为了一致性，在开发和UI相关的东西的时候，我想用和平台一致的 plug-in 称呼会更好。但是在这个文章的代码里面，我会用 plugin 。（同时我偶尔会混用 bundle 和 plugin 这两个词汇。）(译者注：本文中会把 plugin 翻译成插件)


什么是 bundle ？如果你创建一个 Xcode 的 bundle 模版项目，你会发现它内容并不多。当构建它的时候你会得到一个很像构建 App 产生的目录 —— 一个包含 Info.plist 和 Resource 目录的内容目录。 如果你在你的项目下加入了新的类，你可以看见包含一个可执行文件的 MacOS 目录。Bundle工程里缺少的一个东西是 main 函数。它是被宿主App调用执行的。


## 为 TextEdit 加入 Plugin 支持


我会介绍两种插件的方式，第一个用最少的工作来为你的 app 加入插件支持，希望让你知道实现这个有多简单。

第二个技术有点复杂，它展现来一个一个合理的为你的 app 加入插件的合理的方式。

本文章的项目文件仍然会放在[GitHub](https://github.com/objcio/issue-14-plugins) 供大家参考。


### 在 TextEdit 里面加载 Bundle

请打开“01 TextEdit”目录下面的 TextEdit.xcodeproj 工程，同时浏览它里面包含的代码。

这个改写过的 TextEdit 里面有三个简单的组成部分：扫描 bundle，加载 bundle，并且加入调用 bundle 的UI

打开Controller.m，你可以看见 `-(void)loadPlugins` 方法(它被 `applicationDidFinishLaunching:` 调用)


`loadPlugins` 方法在你的界面菜单右侧加入了一个新的 `NSMenuItem`，来为你调用你的插件提供一个入口。（通常你会在 MainMenu.xib 做这件事情并且链接outlets，但是我们这次偷下懒）然后获得你的插件目录（在 ~/Library/Application Support/Text Edit/Plug-Ins/ ）下，并且扫描这个目录。

     NSString *pluginsFolder = [self pluginsFolder];
     NSFileManager *fm = [NSFileManager defaultManager];

     NSError *outErr;
     for (NSString *item in [fm contentsOfDirectoryAtPath:pluginsFolder error:&outErr]) {

         if (![item hasSuffix:@".bundle"]) {
             continue;
         }

         NSString *bundlePath = [pluginsFolder stringByAppendingPathComponent:item];

         NSBundle *b = [NSBundle bundleWithPath:bundlePath];

         if (!b) {
             NSLog(@"Could not make a bundle from %@", bundlePath);
             continue;
         }

         id <TextEditPlugin> plugin = [[b principalClass] new];

         NSMenuItem *item = [pluginsMenu addItemWithTitle:[plugin menuItemTitle] action:@selector(pluginMenuItemCalledAction:) keyEquivalent:@""];

         [item setRepresentedObject:plugin];

     }



到目前，看起来是非常简单的。扫描插件目录，确保它是一个 .bundle 文件（你当然不希望载入 .DS_Store 文件），然后用`NSBundle`载入你找到的 bundle 并且实例化里面的类。

你会注意到一个 TextEditPlugin 的 protocol 的引用。在 TextEditMisc.h 能找它的定义:


     @protocol TextEditPlugin <NSObject>
     - (NSString*)menuItemTitle;
     - (void)actionCalledWithTextView:(NSTextView*)textView inDocument:(id)document;
     @end



这说明你实例化的类需要响应这两个方法。你可以验证这个类是否响应这两个方法（这是一个好主意），但是简单起见，我们先不这样做。


Ok，你在 bundle 里面调用的 `principalClass` 方法是那一个？当你创建一个Bundle的时候，你可以在里面创建一个或者多个类，同时你需要让TextEdit知道哪一个类需要被实例化。为了帮助宿主App调用，你可以在info.plist文件加入一个 `NSPrincipalClass` 的键，同时设置它的值为实现插件方法的类的名字。你可以用`[NSBundle principalClass]` 方便的从 `NSPrincipalClass` 的值里面寻找并创建这个类。


继续在 Plug-Ins 菜单加入一个新的按钮，设置 action 为 `pluginMenuItemCalledAction:`，并且设置它表示你已经实例化的对象。

注意你没有在 menu item 里面设置一个target。如果一个menu item的目标是nil，那么它会寻找响应链，来寻找第一个实现  `pluginMenuItemCalledAction:` 方法的对象。如果它找不到，那么这个菜单选项将会不能用。


举一个例子，最好是在`Document`的窗口控制类实现 `pluginMenuItemCalledAction` 。打开DocumentWindowController.m，然后定位到到 `pluginMenuItemCalledAction`


    - (void)pluginMenuItemCalledAction:(id)sender {
        id <TextEditPlugin>plugin = [sender representedObject];
        [plugin actionCalledWithTextView:[self firstTextView] inDocument:[self document]];
    }


代码本身很清晰，搜集插件实例，调用`actionCalledWithTextView:inDocument: `方法（你定义在 protocol 里面的），运行你插件里面的代码。


### 插件一瞥


打开“01 MarkYellow” 工程看一下。这是一个 Xcode (通过OS X ▸ Framework & Library ▸ Bundle template 建立) 的标准工程，同时只有一个类：TEMarkYellow。


如果你打开MarkYellow-Info.plist，你可以看到`NSPrincipalClass` 的值设置成了上面提到的`TEMarkYellow`。


接着，打开TEMarkYellow.m，你将会看见定义在协议里面的方法。一个返回你插件的名字，就是在 menu 里面显示的那个，更有兴趣的是另外一个方法，它把所有选中的文字变成了黄色的背景。

    
    - (void)actionCalledWithTextView:(NSTextView*)textView inDocument:(id)document {
        if ([textView selectedRange].length) {
           
            NSMutableAttributedString *ats = [[[textView textStorage] attributedSubstringFromRange:[textView selectedRange]] mutableCopy];

            [ats addAttribute:NSBackgroundColorAttributeName value:[NSColor yellowColor] range:NSMakeRange(0, [ats length])];

            //  先测试text view是否能改变文字内容，这样可以自动做正确的撤销操作。

            By asking the text view if you can change the text first, it will automatically do the right thing to enable undoing of attribute changes
            if ([textView shouldChangeTextInRange:[textView selectedRange] replacementString:[ats string]]) {
                [[textView textStorage] replaceCharactersInRange:[textView selectedRange] withAttributedString:ats];
                [textView didChangeText];
            }
        }
    }




运行 TextEdit （它会创建Plug-Ins目录），然后构建 MarkYellow 工程。把 MarkYellow.bundle 丢到你的 ~/Library/Application Support/Text Edit/Plug-Ins/ 目录下面，重启你的 TextEdit 应用。

一切看起来还可以，扫描，加载，插入一个菜单，然后，当你的菜单项使用的时候，传递到参数到插件里面。试一试，点击 Plug-Ins ▸ Mark Selected Text Yellow，选择的文字的背景颜色就变成黄色的了。

当你选中菜单项的时候对应的就会变成黄色的了。

这真是令人惊叹，但是它是脆弱和不够好的。

所以关掉两个项目，忘掉它们吧。

## 好的，但是如何改进呢

上述的途径有什么问题？

Bundle 中只有一个方法被调用。对于插件的作者来说太不方便了。有没有更简单的方法为 bundle 加入更多功能和菜单按钮呢？

这不是一个有前瞻性的做法，在插件里面硬编码特定的方法固定了一些操作，让我们重新来写这个工程吧。

这一次，我们先从 bundle 开始探究。打开 02 MarkYellow 里面的 xcodeproj 工程，定位到 TEMarkYellow.m， 你马上可以看见这里有更多代码，但是同时它也做了更多事情。


这里实现了一个接收一个 interface 作为参数的`pluginDidLoad:`方法而不是返回插件名字的方法。你可以用它来告诉 TextEdit 你的方法名字和调用它的 selector ，以及一个帮助存储一些特别的文本操作的状态的user object ，

这个插件实现了三个操作：一个把你的文本变成黄色，一个把你的文字变成蓝色，一个把你选中的文本作为 AppleScript 运行。我们充分发挥了 userObject 这个参数的优点，所以只需需要实现两个方法。

这个方法比第一种有扩展性。同时，它也增加了 app 端的复杂度。

## 为TextEdit加入更多功能

打开 02 TextEdit 看看 Controler.m , 它没有做什么事情。但是它在 `applicationDidFinishLaunching:`设置了一个新的类，叫 PluginManager，打开PluginManager.m 并且导航到 `－loadPlugins` 里面。

这个和刚才的`-loadPlugins` 几乎一样，只不过加入菜单选项的地方在循环里面。从 bundle 里面实例化 principalClass 并且通过调用`pluginDidLoad:` 影响了 TextEdit 执行。


看一下`-addPluginsMenuWithTitle:…`，你将会看到创建了 menu item，并且这里不再设置menu item的`representedObject` 为插件实例本身，而是实例化一个 helper 类（PluginTarget），同时关联了对text aciton 和 friends 的引用，然后设置它为 menu item 的 representedObject。



然而，这个设置到 menu item 的selector还是`pluginMenuItemCalledAction:` - 在 DocumentWindowController.m 里面看看这个方法看看它干了什么:



    - (void)pluginMenuItemCalledAction:(id)sender {
        
        PluginTarget *p = [sender representedObject];

        NSMethodSignature *ms = [[p target] methodSignatureForSelector:[p action]];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:ms];
        
        NSTextView *tv = [self firstTextView];
        id document = [self document];
        id userObject = [p userObject];
        
        [invocation setTarget:[p target]];
        [invocation setSelector:[p action]];
        [invocation setArgument:&tv atIndex:2];
        [invocation setArgument:&document atIndex:3];
        [invocation setArgument:&userObject atIndex:4];
        [invocation invoke];
    }


因为你要处理更多信息，所以这个版本相比之前的实现有一点复杂，创建一个 NSInvocation，设置它的参数，然后从 插件的实例里面调用它。


host端需要更多工作，但是对于插件的作者来说写插件更加灵活了。


## 下一步干什么

基于这个接口，你可以写一个插件，加载其他插件。假设你想要加入用户用 Javascript 写插件的功能，那么在 `pluginDidLoad` 调用之后，扫描指定目录下面的 js 文件，在 `addPluginsMenuWithTitle:…`中为每一个 js 文件增加对应的条目，然后，当插件被调用的时候，可以用 JavaScriptCore 来执行对应的脚本 。你也可以用 Python，Ruby，Lu a来做这些事情（我之前做过这些事情）。


## 最后关于安全的笔记


“插件让安全的人抽搐” — 匿名

一个显而易见但是容易被忽略的事情是安全。当你在你的进程里面加载一个可执行的 bundle 
的时候，你相当于在说：“这里有一把我房间的钥匙，确保走的时候关上灯灯，不要喝牛奶，无论你干什么都请把火盆放在外面。” 你要相信插件的作者不会犯错，但是有可能事与愿违。


可能会发生什么糟糕的情况呢？一个实现的不好的的插件可以占用所有可用的内存，让CPU占用始终保持 100%，crash 一大堆东西。或许有的家伙写了一个看起来很好的插件，但是一个月以后，它的代码把你的联系人数据库偷偷发给第三方……
 
如何解决这个问题？你可以在单独的地址空间运行你的插件（解决 crash 问题，同时可能解决内存和 cpu 问题），同时强制插件到沙盒里面运行。（如果你正确地确认插件的权限，那么你的联系人数据库就不会被读取了）。我一时就能想到很多方法，但是最好的解决方法是使用苹果的XPC。

我把探索的过程留给读者，但是你在处理插件的时候应该一直有安全性的观念。当然，把一个插件放在沙盒里面或者另外一个进程里面会缺少一些乐趣，并且增加一些工作量。所以这对于你的App或许没那么重要。





