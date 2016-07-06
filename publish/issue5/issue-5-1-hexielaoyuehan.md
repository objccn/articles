iOS 7 的发布给开发者的案头带来了很多新工具。其中一个就是 *TextKit*。TextKit 由许多新的 UIKit 类组成，顾名思义，这些类就是用来处理文本的。在这里，我们将介绍 TextKit 的来由、它的组成，以及通过几个例子解释开发者怎样将它派上大用场。

但是首先我们得先阐明一个观点：TextKit 可能是近期对 UIKit *最重要*的补充了。iOS 7 的新界面用纯文本按钮替换了大量的图标和边框。总的来说，文本和文本布局在新 OS 系统的视觉效果中所占有的重要性大大提高了。iOS7 的重新设计完全是被文本驱动，这样说也许并不夸张——而文本全部是 TextKit 来处理的。

告诉你这个变动到底有多大吧：iOS7 之前的所有版本，（几乎）所有的文本都是 WebKit 来处理的。对：WebKit，web 浏览器引擎。所有 `UILabel`、`UITextField`，以及 `UITextView` 都在后台以某种方式使用 web views 来进行文本布局和渲染。为了新的界面风格，它们全都被重新设计以使用 TextKit。

## iOS 上文本的简短历史

这些新类并不是用来替换开发者以前使用的类。对 SDK 来说，TextKit 提供的是全新的功能。iOS 7 之前，TextKit 提供的功能必须都手动完成。这是现有框架缺失的功能。

长期以来，只有一个基本的文本布局和渲染框架：*CoreText*。同样也只有一个途径读取用户的键盘输入：`UITextInput` 协议。在 iOS6 中，为了简单地获取系统的文本选择，也只有一个选择：继承 `UITextView`。

（这可能就是为什么我要公开自己十年开发文本编辑器的经验的原因了）在渲染文本和读取键盘输入之间存在着巨大（跟我读：巨大）的缺口。这个缺口可能也是导致很少有富文本或者语法高亮编辑器的原因了——毫无疑问，开发一个好用的文本编辑器得耗费几个月的时间。

就这样——如下是 iOS 文本（不那么）简短历史的简短概要：

**iOS 2**：这是第一个公开的 SDK，包括一个简单的文本显示组件（`UILabel`），一个简单的文本输入组件（`UITextField`），以及一个简单的、可滚动、可编辑的并且支持更大量文本的组件：`UITextView`。这些组件都只支持纯文本，没有文本选择支持（仅支持插入点），除了设置字体和文本颜色外几乎没有其他可定制功能。

**iOS 3**：新特性有复制和粘贴，以及复制粘贴所需要的文本选择功能。数据探测器（Data Detector）为文本视图提供了一个高亮电话号码和链接的方法。然而，除了打开或关闭这些特性外，开发者基本上没有什么别的事情可以做。

**iOS 3.2**：iPad 的出现带来了 CoreText，也就是前面提到的低级文本布局和渲染引擎（从Mac OS X 10.5 移植过来的），以及 `UITextInput`，就是前面也提到的键盘存取协议。Apple 将 Pages 作为移动设备上文本编辑功能的样板工程[^1]。然而，由于我前面提到的框架缺口，只有很少的应用使用它们。

**iOS 4**：iOS 3.2 发布仅仅几个月后就发布了，文本方面没有一丁点新功能。_（个人经历：在 WWDC，我走近工程师们，告诉他们我想要一个完善的 iOS 文本布局系统。回答是：“哦…提交个请求。”不出所料…）_

**iOS 5**：文本方面没啥变化。_（个人经历：在 WWDC，我和工程师们谈及 iOS 上文本系统。回答是：“我们没有看到太多这方面的请求…” 靠！）_

**iOS 6**：有些动作了：属性文本编辑被加入了 `UITextView`。很不幸的是，它很难定制。默认的 UI 有粗体、斜体和下划线。用户可以设置字体大小和颜色。粗看起来相当不错，但还是没法控制布局或者提供一个便利的途径来定制文本属性。然而对于（文本编辑）开发者，有一个大的新功能：可以继承 `UITextView` 了，这样的话，除了以前版本提供的键盘输入外，开发者可以“免费”获得文本选择功能。而在这以前，开发者必须实现一个完全自定义的文本选择功能，这可能是很多非纯文本工具的开发半途而废的原因。_（个人经历：我，WWDC，工程师们。我想要一个 iOS 的文本系统。回答：“嗯。吖。是的。也许？看，它只是不执行…” 所以毕竟还是有希望，对吧？）_

**iOS 7**：终于来了，TextKit。

## 功能

所以我们来了。iOS7 带着 TextKit 登陆了。咱们看看它可以做什么！深入之前，我还想提一下，严格来说，这些新功能中的大部分以前都*可以*实现。如果你有大量的资源和时间来用 CoreText 构建一个文本引擎，这些都是可以实现的。但是在以前，构建一个完善的富文本编辑器可能花费你*几个月*的时间，现在却非常简单。你只需要到在 Xcode 里打开一个界面文件，然后将 `UITextView` 拖到你的视图控制器，就可以获得所有以下这些功能：

**字距调整（Kerning）**：所有的字符都有一个矩形的外边框，这些边框必须彼此相邻来放置，这样的想法已经过时了。例如，现代文本布局会考虑到一个大写的“T”的“两翼”下面有一些空白，所以它会把后面的小写字母向左移让它们更靠近点。这样做的结果大大提高了文本的易读性，特别是在更长的文字中：

![Kerning: the bounding box of the letter “a” (blue rect) clearly overlap the capital “T” when kerning is enabled.][1]

**连写**：我认为这主要是个艺术功能，但当某些字符组合（如“f”后面是“l”）使用组合符号（所谓的字形(glyph)）绘制时，有些文本确实看起来更好（更美观）。

![Ligatures: the “Futura” font family contains special symbols for character combinations like “fl”.][2]

**图像附件**：现在可以向 Text View 中添加图像了。

**断字**：编辑文本时没那么重要，但如果要以好看易读的方式展现文本时，这就相当重要。断字意味着在行边界处分割单词，从而为整体文本创建一个更整齐的排版和外观。_个人经历：_ iOS 7 之前，开发者必须直接使用 CoreText。像这样：首先以句子为基础检测文本语言，然后获取句子中每个单词可能的断字点，然后在每一个可能的断字点上插入定制的连字占位字符。准备好之后，运行 CoreText 的布局方法并手动将连字符插入到断行。如果你想得到好的效果，之后你得检查带有连字符的文本没有超出行边界，如果超出了，再运行一次行的布局方法，这一次不要使用上次使用的断字点。使用 TextKit 的话，就非常简单了，设置 `hyphenationFactor` 属性就可以启用断字。

![The text in this view would have looked much more compartmentalized without hyphenation.][3]

**可定制性**：对我来说，甚至比改进过的排版还多，这是个*全新*的功能。以前开发者必须在使用现有的功能和自己全部重头写之间做出选择。现在提供了一整套类，它们有代理协议，或者可以被覆盖从而改变*部分*行为。例如，不必重写整个文本组件，你现在就可以改变指定单词的断行行为。我认为这是个胜利。

**更多的富文本属性**：现在可以设置不同的下划线样式（双线、粗线、虚线、点线，或者它们的组合）。提高文本的基线非常容易，这可用来设置上标数字。开发者也不再需要自己为定制渲染的文本绘制背景颜色了（CoreText 不支持这些功能）。

**序列化**：过去没有内置的方法从磁盘读取带文本属性的字符串。或者再写回磁盘。现在有了。

**文本样式**：iOS 7 的界面引入了一个全局预定义的文本类型的新概念。这些文本类型分配了一个全局预定义的外观。理想情况下，这可以让整个系统的标题和连续文本具有一致的风格。通过设置应用，用户可以定义他们的阅读习惯（例如文本大小），那些使用文本样式的应用将自动拥有正确的文本大小和外观。

**文本效果**：最后也是最不重要的。iOS 7 有且仅有一个文本效果：凸版。使用此效果的文本看起来像是盖在纸上面一样。内阴影，等等。_个人观点：真的？靠…？在一个已经完全彻底不可饶恕地枪毙了所有无用的[怀旧装饰（skeuomorphism）][4]的 iOS 系统上，谁会需要这个像文本盖在纸上的效果？_

## 结构

可能概览一个系统最好的方法是画一幅图。这是 UIKit 文本系统——TextKit 的简图：

![The structure of all essential TextKit classes. Highlighted with a “New” badge are classes introduced in iOS 7.][5]

从上图可以看出来，要让一个文本引擎工作，需要几个参与者。我们将从外到里介绍它们：

**字符串（String）**：要绘制文本，那么必然在某个地方有个字符串来存储这段文本。在默认的结构中，`NSTextStorage` 保存并管理这个字符串，在这种情况中，它可以远离绘制。但并不一定非得这样。使用 TextKit 时，文本可以来自任何适合的来源。例如，对于一个代码编辑器，字符串可以是一棵包含所有显示的代码的结构信息的注释语法树（annotated syntax tree，缩写为 AST）。使用一个自定义的 `NSTextStorage` 就可以让文本在稍后动态地添加字体或颜色高亮等文本属性装饰。这是第一次，开发者可以直接为文本组件使用自己的模型。要想实现这个功能，我们需要一个特别设计的 `NSTextStorage`，即：

`NSTextStorage`：如果你把文本系统看做一个模型-视图-控制器（MVC）架构，这个类代表的是模型。`NSTextStorage` 是一个中枢，它管理所有的文本和属性信息。系统只提供了两个存取器方法存取它们，并另外提供了两个方法来分别修改文本和属性。后面我们将进一步了解这些方法。现在重要的是你得理解 `NSTextStorage` 是从它的父类 `NSAttributedString` 继承了这些方法。这就很清楚了，`NSTextStorage`——从文本系统看来——仅仅是一个带有属性的字符串，附带一些扩展。这两者唯一的重大不同点是 `NSTextStorage` 包含了一个方法，可以把所有对其内容进行的修改以通知的形式发送出来。我们等一下会介绍这部分内容。

`UITextView`：堆栈的另一头是实际的视图。在 TextKit 中，有两个目的：第一，它是文本系统用来绘制的视图。文本视图它自己并*不*会做任何绘制；它仅仅提供一个供其它类绘制的区域。作为视图层级机构中唯一的组件，第二个目的是处理所有的用户交互。具体来说，Text View 实现 `UITextInput` 的协议来处理键盘事件，它为用户提供了一种途径来设置一个插入点或选择文本。它并不对文本做任何实际上的改变，仅仅将这些改变请求转发给刚刚讨论的 Text Storage。

`NSTextContainer`：每个 Text View 定义了一个文本可以绘制的区域。为此，每个 Text View 都有一个 Text Container，它精确地描述了这个可用的区域。在简单的情况下，这是一个垂直的无限大的矩形区域。文本被填充到这个区域，并且 Text View 允许用户滚动它。然而，在更高级的情况下，这个区域可能是一个特定大小的矩形。例如，当渲染一本书时，每一页都有最大的高度和宽度。 Text Container 会定义这个大小，并且不接受任何超出的文本。相同情况下，一幅图像可能占据了页面的一部分，文本应该沿着它的边缘重新排版。这也是由 Text Container 来处理的，我们会在后面的例子中看到这一点。

`NSLayoutManager`：Layout Manager 是中心组件，它把所有组件粘合在一起：

1. 这个管理器监听 Text Storage 中文本或属性改变的通知，一旦接收到通知就触发布局进程。
2. 从 Text Storage 提供的文本开始，它将所有的字符翻译为字形（Glyph）[^2]。
3. 一旦字形全部生成，这个管理器向它的 Text Containers 查询文本可用以绘制的区域。
4. 然后这些区域被行逐步填充，而行又被字形逐步填充。一旦一行填充完毕，下一行开始填充。
5. 对于每一行，布局管理器必须考虑断行行为（放不下的单词必须移到下一行）、连字符、内联的图像附件等等。
6. 当布局完成，文本的当前显示状态被设为无效，然后 Layout Manager 将前面几步排版好的文本设给 Text View。

**CoreText**：没有直接包含在 TextKit 中，CoreText 是进行实际排版的库。对于布局管理器的每一步，CoreText 被这样或那样的方式调用。它提供了从字符到字形的翻译，用它们来填充行，以及建议断字点。

### Cocoa 文本系统

创建像 TextKit 这样庞大复杂的系统肯定不是件简单快速的事情，而且肯定需要丰富的经验和知识。在 iOS 的前面 6 个主版本中，一直没有提供一个“真正的”文本组件，这也说明了这一点。Apple 把它视为一个大的新特性，当然没啥问题。但是它真的是全新的吗？

这里有个数字：在 [UIKit 的 131 个公共类][14]中，只有 9 个的名字没有使用UI作为前缀。这 9 个类使用的是旧系统的、旧世界的（跟我读：Mac OS）前缀 NS。而且这九个类里面，有七个是用来处理文本的。巧合？好吧…

这是 Cocoa 文本系统的简图。不妨和上面 TextKit 的那幅图作一下对比。

![The structure of all essential classes of the Cocoa Text System as present on Mac OS today.][6]

惊人地相似。很明显，最起码主要部分，两者是相同的。很明显——除了右边部分以及 `NSTextView` 和 `UITextView` ——主要的类全部相同。TextKit 是（起码部分是）从 Cocoa 文本系统移植到 iOS。_（我之前一直请求的那个，耶！）_

进一步比较还是能看出一些不同的。最值得注意的有：

- 在 iOS 上没有 `NSTypesetter` 和 `NSGlyphGenerator` 这两个类。在 Mac OS 上有很多方法来定制排版，在 iOS 中被极大地简化了，去掉了一些抽象概念，并将这个过程合并到 `NSLayoutManager` 中来。保留下来的是少数的代理方法，以用来更改文本布局和断行行为。

- 这些 Cocoa 的类移植到 iOS 系统后新增了几个非常便利的功能。在 Cocoa 中，必须手工地将确定的区域从 Text Container 分离出来（见上）。而 UIKit 类提供了一个简单的 `exclusionPaths` 属性就可以做到这一点。

- 有些功能未能提供，比如，内嵌表格，以及对非图像的附件的支持。

尽管有这些区别，总的来说系统还是一样的。`NSTextStorage` 在两个系统是是一模一样的，`NSLayoutManager` 和 `NSTextContainer` 也没有太大的不同。这些变动，在没有太多去除对一些特例的支持的情况下，看来（某些情况下大大地）使文本系统的使用变得更为容易。我认为这是件好事。

_事后回顾我从 Apple 工程师那里得到的关于将 Cocoa 文本系统移植到 iOS 的答案，我们可以得到一些背景信息。拖到现在并削减功能的原因很简单：性能、性能、性能。文本布局可能是极度昂贵的任务——内存方面、电量方面以及时间方面——特别是在移动设备上。Apple 必须采用更简单的解决方案，并等到处理能力能够至少部分支持一个完善的文本布局引擎。_

## 示例

为了说明 TextKit 的能力，我创建了一个小的演示项目，你可以[在 GitHub 上找到它][7]。在这个演示程序中，我只完成了一些以前不容易完成的功能。我必须承认写这些代码只花了我礼拜天的一个上午的时间；如果以前要做同样的事情，我得花几天甚至几个星期。

TextKit 包括了超过 100 个方法，一篇文章根本没办法尽数涉及。而事实上，大多数时候，你需要的仅仅是一个正确的方法，TextKit 的使用和定制性也仍有待探索。所以我决定做四个更小的演示程序，而非一个大的演示程序来展示所有功能。每个演示程序中，我试着演示针对不同的方面和不同的类进行定制。

### 演示程序1：配置

让我们从最简单的开始：配置文本系统。正如你在上面 TextKit 简图中看到的，`NSTextStorage`、`NSLayoutManager` 和 `NSTextContainer` 之间的箭头都是有两个头的。我试图描述它们的关系是 1 对 N 的关系。就是那样：一个 Text Storage 可以拥有多个 Layout Manager，一个 Layout Manager 也可以拥有多个 Text Container。这些多重性带来了很好的特性：

- 将多个 Layout Manager 附加到同一个 Text Storage 上，可以产生*相同文本的多种视觉表现*，而且可以把它们放到一起来显示。每一个表现都有独立的位置和大小。如果相应的 Text View 可编辑，那么在某个 Text View 上做的所有修改都会马上反映到所有 Text View 上。
- 将多个 Text Container 附加到同一个 Layout Manager 上，这样可以将*一个文本分布到多个视图*展现出来。很有用的一个例子，基于页面的布局：每个页面包含一个单独的 Text View。所有这些视图的 Text Container 都引用同一个 Layout Manager，这时这个 Layout Manager 就可以将文本分布到这些视图上来显示。

在 Storyboard 或者 Interface 文件中实例化 `UITextView` 时，它会预配置一个文本系统：一个 Text Storage，引用一个 Layout Manager，而后者又引用一个 Text Container。同样地，一个文本系统栈也可以通过代码直接创建：

    NSTextStorage *textStorage = [NSTextStorage new];

    NSLayoutManager *layoutManager = [NSLayoutManager new];
    [textStorage addLayoutManager: layoutManager];

    NSTextContainer *textContainer = [NSTextContainer new];
    [layoutManager addTextContainer: textContainer];

    UITextView *textView = [[UITextView alloc] initWithFrame:someFrame
                                                                         textContainer:textContainer];

这是最简单的方式。手工创建一个文本系统，唯一需要记住的事情是你的 View Controller 必须 retain 这个 Text Storage。在栈底的 Text View 只保留了对 Text Storage 和 Layout Manager 的弱引用。当 Text Storage 被释放时，Layout Manager 也被释放了，这样留给 Text View 的就只有一个断开的 Text Container 了。

这个规则有一个例外。只有从一个 interface 文件或 storyboard 实例化一个 Text View 时，Text View 确实会*自动* retain Text Storage。框架使用了一些黑魔法以确保所有的对象都被 retain，而无需手动建立一个 retain 环。

记住这些之后，创建一个更高级的设置也非常简单。假设在一个视图里面依旧有一个从 nib 实例化的 Text View，叫做 `originalTextView`。增加对相同文本的第二个文本视图只需要复制上面的代码，并重用 `originalTextView` 的 Text Storage：

    NSTextStorage *sharedTextStorage = originalTextView.textStorage;

    NSLayoutManager *otherLayoutManager = [NSLayoutManager new];
    [sharedTextStorage addLayoutManager: otherLayoutManager];

    NSTextContainer *otherTextContainer = [NSTextContainer new];
    [otherLayoutManager addTextContainer: otherTextContainer];

    UITextView *otherTextView = [[UITextView alloc] initWithFrame:someFrame
                                                    textContainer:otherTextContainer];

将第二个 Text Container 附加到 Layout Manager 也差不多。比方说我们希望上面例子中的文本填充*两个* Text View，而非一个。简单：

    NSTextContainer *thirdTextContainer = [NSTextContainer new];
    [otherLayoutManager addTextContainer: thirdTextContainer];

    UITextView *thirdTextView = [[UITextView alloc] initWithFrame:someFrame
                                                    textContainer:thirdTextContainer];

但有一点需要注意：由于在 otherTextView 中的 Text Container 可以无限地调整大小，`thirdTextView` 永远不会得到任何文本。因此，我们必须指定文本应该从一个视图回流到其它视图，而不应该调整大小或者滚动：

    otherTextView.scrollEnabled = NO;

不幸的是，看来将多个 Text Container 附加到一个 Layout Manager 会禁用编辑功能。如果必须保留编辑功能的话，那么一个 Text Container 只能附加到一个 Layout Manager 上。

想要一个这个配置的可运行的例子的话，请在前面提到的 [TextKitDemo][7] 中查看 “Configuration” 标签页。

## 演示程序2：语法高亮

如果配置 Text View 不是那么令人激动，那么这里有更有趣的：语法高亮！

看看 TextKit 组件的责任划分，就很清楚语法高亮应该由 Text Storage 实现。因为 `NSTextStorage` 是一个类簇[^3]，创建它的子类需要做不少工作。我的想法是建立一个复合对象：实现所有的方法，但只是将对它们的调用转发给一个实际的实例，将输入输出参数或者结果修改为希望的样子。

`NSTextStorage` 继承自 `NSMutableAttributedString`，并且必须实现以下四个方法——两个 getter 和两个 setter：

    - (NSString *)string;
    - (NSDictionary *)attributesAtIndex:(NSUInteger)location
                         effectiveRange:(NSRangePointer)range;
    - (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str;
    - (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range;

一个类簇的子类的复合对象的实现也相当简单。首先，找到一个满足所有要求的*最简单*的类。在我们的例子中，它是 `NSMutableAttributedString`，我们用它作为实现自定义存储的实现：

    @implementation TKDHighlightingTextStorage
    {
        NSMutableAttributedString *_imp;
    }

    - (id)init
    {
        self = [super init];
        if (self) {
            _imp = [NSMutableAttributedString new];
        }
        return self;
    }

有了这个对象，只需要一行代码就可以实现两个 getter 方法：

    - (NSString *)string
    {
        return _imp.string;
    }

    - (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range
    {
        return [_imp attributesAtIndex:location effectiveRange:range];
    }

实现两个 setter 方法也几乎同样简单。但也有一个小麻烦：Text Storage 需要通知它的 Layout Manager 变化发生了。因此 settter 方法必须也要调用 `-edited:range:changeInLegth:` 并传给它变化的描述。听起来更糟糕，实现变成：

    - (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str
    {
        [_imp replaceCharactersInRange:range withString:str];
        [self edited:NSTextStorageEditedCharacters range:range
                                          changeInLength:(NSInteger)str.length - (NSInteger)range.length];
    }

    - (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range
    {
        [_imp setAttributes:attrs range:range];
        [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    }

就这样，我们在文本系统栈里面有了一个 Text Storage 的全功能替换版本。在从 Interface 文件中载入时，可以像这样将它插入文本视图——但是记住从一个实例变量引用 Text Storage：

    _textStorage = [TKDHighlightingTextStorage new];
    [_textStorage addLayoutManager: self.textView.layoutManager];

到目前为止，一切都很好。我们设法插入了一个自定义的文本存储，接下来我们需要真正高亮文本的某些部分了。现在，一个简单的高亮应该就是够了：我们希望将所有 iWords 的颜色变成红色——也就是那些以小写“i”开头，后面跟着一个大写字母的单词。

一个方便实现高亮的办法是覆盖 `-processEditing`。每次文本存储有修改时，这个方法都自动被调用。每次编辑后，`NSTextStorage` 会用这个方法来清理字符串。例如，有些字符无法用选定的字体显示时，Text Storage 使用一个可以显示它们的字体来进行替换。

和其它一样，为 iWords 增加一个简单的高亮也相当简单。我们覆盖 `-processEditing`，调用父类的实现，并设置一个正则表达式来查找单词：


    - (void)processEditing
    {
        [super processEditing];

        static NSRegularExpression *iExpression;
        NSString *pattern = @"i[\\p{Alphabetic}&&\\p{Uppercase}][\\p{Alphabetic}]+";
        iExpression = iExpression ?: [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:0
                                                                                 error:NULL];

然后，首先清除之前的所有高亮：

        NSRange paragaphRange = [self.string paragraphRangeForRange: self.editedRange];
        [self removeAttribute:NSForegroundColorAttributeName range:paragaphRange];

其次遍历所有的样式匹配项并高亮它们：

        [iExpression enumerateMatchesInString:self.string
                                      options:0 range:paragaphRange
                                   usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
        {
            [self addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:result.range];
        }];
    }

就是这样。我们创建了一个支持语法高亮的动态 Text View。当用户键入时，高亮将被*实时*应用。而且这只需几行代码。酷吧？

![A screenshot from the TextKitDemo project showing the text view with iWords highlighted.][8]

请注意仅仅使用 *edited range* 是不够的。例如，当手动键入 iWords，只有一个单词的第三个字符被键入后，正则表达式才开始匹配。但那时 `editedRange` 仅包含第三个字符，因此所有的处理只会影响这一个字符。通过重新处理整个段落可以解决这个问题，这样既完成高亮功能，又不会太过影响性能。

想要一个可以运行的 Demo 的话，请在前面提到的 [TextKitDemo][7] 中查看“Highlighting”标签页。

## 演示程序3：布局修改

如前所述，Layout Manager 是核心的布局主力。Mac OS 上 `NSTypesetter` 的高度可定制功能被并入 iOS 上的 `NSLayoutManager`。虽然 TextKit 不具备像 Cocoa 文本系统那样的完全可定制性，但它提供很多代理方法来允许做一些调整。如前所述，TextKit 与 CoreText 更紧密地集成在一起，主要是基于性能方面的考虑。但是两个文本系统的理念在一定程度上是不一样的：

**Cocoa 文本系统**：在 Mac OS上，性能不是问题，设计考量的全部是灵活性。可能是这样：“这个东西可以做这个事情。如果你想的话，你可以覆盖它。性能不是问题。你也可以提供完全由自己实现的字符到字形的转换，去做吧…”

**TextKit**：性能看来真是个问题。理念（起码现在）更多的是像这样：“我们用简单但是高性能的方法实现了这个功能。这是结果，但是我们给你一个机会去更改它的一些东西。但是你只能在不太损害性能的地方进行修改。”

理念的东西就讲这么多，现在让我们来搞些实际的东西。例如，调整行高如何？听起来不可思议，但是在之前的 iOS 发布版上调整行高需要[使用黑科技或者私有 API][9]。幸运的是，现在（再一次）不用那么费脑子了。设置 Layout Manager 的代理并实现仅仅一个方法即可：

    - (CGFloat)      layoutManager:(NSLayoutManager *)layoutManager
      lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex
      withProposedLineFragmentRect:(CGRect)rect
    {
        return floorf(glyphIndex / 100);
    }

在以上的代码中，我修改了行间距，让它与文本长度同时增长。这导致顶部的行比底部的行排列得更紧密。我承认这没什么实际的用处，但是它是可以做到的（而且肯定会有更实用的用例的）。

好，来一个更现实的场景。假设你的文本中有链接，你不希望这些链接被断行分割。如果可能的话，一个 URL 应该始终显示为一个整体，一个单一的文本片段。没有什么比这更简单的了。

首先，就像前面讨论过的那样，我们使用自定义的 Text Storage。但是，它寻找链接并将其标记，而不是检测 iWords，如下：

    static NSDataDetector *linkDetector;
    linkDetector = linkDetector ?: [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:NULL];

    NSRange paragaphRange = [self.string paragraphRangeForRange: NSMakeRange(range.location, str.length)];
    [self removeAttribute:NSLinkAttributeName range:paragaphRange];

    [linkDetector enumerateMatchesInString:self.string
                                   options:0
                                     range:paragaphRange
                                usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
    {
        [self addAttribute:NSLinkAttributeName value:result.URL range:result.range];
    }];

有了这个，改变断行行为就只需要实现一个 Layout Manager 的代理方法：

    - (BOOL)layoutManager:(NSLayoutManager *)layoutManager shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger)charIndex
    {
        NSRange range;
        NSURL *linkURL = [layoutManager.textStorage attribute:NSLinkAttributeName
                                                      atIndex:charIndex
                                               effectiveRange:&range];

        return !(linkURL && charIndex > range.location && charIndex <= NSMaxRange(range));   

想要一个可运行的例子的话，请在前面提到的 [TextKitDemo][7] 中查看“Layout”标签页。以下是截屏：

![A screenshot from the TextKitDemo project showing altered line break behavior for link URLs.][10]

顺便说一句，上面截屏里面的绿色轮廓线是无法用 TextKit 实现的。在这个演示程序中，我用了个小技巧来在 Layout Manager 的子类中给文本画轮廓线。以特定的方法来扩展 TextKit 的绘制功能也不是件难事，你一定要看看！

### 演示程序4：文本交互

前面已经涉及到了 `NSTextStorage` 和 `NSLayoutManager`，最后一个演示程序将涉及 `NSTextContainer`。这个类并不复杂，而且它除了指定文本可不可以放置在某个地方外，什么都没做。

不要将文本放置在某些区域，这是很常见的需求，例如，在杂志应用中。对于这种情况，iOS 上的 `NSTextContainer` 提供了一个 Mac 开发者梦寐以求的属性：`exclusionPaths`，它允许开发者设置一个 `NSBezierPath` 数组来指定不可填充文本的区域。要了解这到底是什么东西，看一眼下面的截屏：

![A screenshot from the TextKitDemo project showing text revolving around an excluded oval view.][11]

正如你所看到的，所有的文本都放置在蓝色椭圆外面。在 Text View 里面实现这个行为很简单，但是有个小麻烦：Bezier Path 的坐标必须使用容器的坐标系。以下是转换方法：

    - (void)updateExclusionPaths 
    {
	    CGRect ovalFrame = [self.textView convertRect:self.circleView.bounds 
               				                 fromView:self.circleView];

    	ovalFrame.origin.x -= self.textView.textContainerInset.left;
    	ovalFrame.origin.y -= self.textView.textContainerInset.top;

    	UIBezierPath *ovalPath = [UIBezierPath bezierPathWithOvalInRect:ovalFrame];
    	self.textView.textContainer.exclusionPaths = @[ovalPath];
    }

在这个例子中，我使用了一个用户可移动的视图，它可以被自由移动，而文本会实时地围绕着它重新排版。我们首先将它的 bounds（`self.circleView.bounds`）转换到 Text View 的坐标系统。

因为没有 inset，文本会过于靠近视图边界，所以 `UITextView` 会在离边界还有几个点的距离的地方插入它的文本容器。因此，要得到以容器坐标表示的路径，必须从 origin 中减去这个插入点的坐标。

在此之后，只需将 Bezier Path 设置给 Text Container 即可将对应的区域排除掉。其它的过程对你来说是透明的，TextKit 会自动处理。

想要一个可运行的例子的话，请在前面提到的 [TextKitDemo][7] 中查看“Interaction”标签页。作为一个小噱头，它也包含了一个跟随当前文本选择的视图。因为，你也知道，没有一个小小的丑陋的烦人的回形针挡住你的话，那还是一个好的文本编辑器演示程序吗？

[^1]:   Pages 确实——据 Apple 声称——绝对没有使用私有 API。*咳* 我的理论：它要么使用了一个 TextKit 的史前版本，要么复制了 UIKit 一半的私有源程序。或者两者的混合。

[^2]:   _字形（Glyphs）_：如果说字符是一个字母的“语义”表达，字形则是它的可视化表达。取决于所使用的字体，字形要么是贝塞尔路径，或者位图图像，它定义了要绘制出来的形状。也请参考卓越的 Wikipedia 上关于字形的[这篇文章][12]。

[^3]:   在一个类簇中，只有一个抽象的父类是公共的。分配一个实例实际上就是创建其中一个私有类的对象。因此，你总是为一个抽象类创建子类，并且需要实现所有的方法。也请参考 [class cluster documentation][13]。

---

 

   [1]: /images/issues/issue-5/kerning.png
   [2]: /images/issues/issue-5/ligature.png
   [3]: /images/issues/issue-5/Screen%20Shot%202013-09-29%20at%2022.19.58.png
   [4]: http://en.wikipedia.org/wiki/Skeuomorph
   [5]: /images/issues/issue-5/TextKit.png
   [6]: /images/issues/issue-5/CocoaTextSystem.png
   [7]: https://github.com/objcio/issue-5-textkit
   [8]: /images/issues/issue-5/SyntaxHighlighting.png
   [9]: http://stackoverflow.com/questions/3760924/set-line-height-in-uitextview/3914228
   [10]: /images/issues/issue-5/LineBreaking.png
   [11]:  /images/issues/issue-5/ReflowingTextAndClippy.png
   [12]: http://en.wikipedia.org/wiki/Glyph
   [13]: https://developer.apple.com/library/ios/documentation/general/conceptual/CocoaEncyclopedia/ClassClusters/ClassClusters.html 
   [14]: https://developer.apple.com/library/ios/documentation/uikit/reference/UIKit_Framework/_index.html
   [15]: http://objccn.io/issue-5
   
原文 [Getting to Know TextKit](http://www.objc.io/issue-5/getting-to-know-textkit.html)

译文 [iOS 7系列译文：认识 TextKit - 博客 - 伯乐在线](http://blog.jobbole.com/51965/)
