在本期中我们已经讨论了很多关于字符串不同的话题，从编码到本地化再到语法分析。但多数情况下，字符串最终还是需要被绘制到屏幕上供用户查看、交互。这篇文章涵盖了最基本、最好的练习，以及在用户界面上呈现字符串可能遇到的常见陷阱。

## 如何将字符串绘制到屏幕上

简单起见，我们先看看 UIKit 在字符串渲染方面为我们提供了哪些控件。之后我们将讨论一下对于字符串的渲染，iOS 和 OS X 系统中有哪些相似和不同。

UIKit 提供了很多可以在屏幕上显示和编辑文本的类。每一个类都是为特定使用情况准备的，所以为了避免不必要的问题，为你手上的任务挑选正确的工具是非常重要的。

## UILabel

[`UILabel`](https://developer.apple.com/library/ios/documentation/userexperience/conceptual/UIKitUICatalog/UILabel.html) 是将文本绘制到屏幕上最简单的方式。它是 `UIView` 的一个子类，用来显示少量的**只读**文本。文本可以被展示在一行或多行，如果文本不能适应指定的空间我们还可以使用不同的方式裁剪。尽管 label 使用的方式很简单，但是这里有几个技巧还是值得提一提的。

label 默认只显示一行，但是你可以将 `numberOfLines` 属性设为其他值来改变这一行为。将它设置为一个大于 `1` 的值，文本的行数将会被限制为这个指定的值；如果设置为 `0`，则是告诉 label 不管文本占多少行都显示出来。

通过设置 `text` 属性，Label 可以显示简单的纯文本，而设置 `attributedText` 属性则可以让 label 显示富文本。当使用纯文本的时候，你可以使用 label 的 `font`，`textColor`，`textAlignment`，`shadowColor` 和 `shadowOffset` 属性改变它的外观，如果你希望改变程序内所有 Label 的风格，你也可以使用 `[UILabel appearance]` 这个方法来进行全局的更改。

Attributed strings 提供了更加灵活的格式，字符串的不同部分可以使用不同的格式。让我们看看常见布局部分，下面给出  attributed strings 一些示例。（下文“常见布局”那一节给出了具体的关于  Attributed String 的一些例子。）

除了通过上文提到的那些属性来调整 `UILabel` 的显示风格外，你还可以通过设置 `UILabel` 的 `adjustsFontSizeToWidth`，`minimumScaleFactor`，`adjustsLetterSpacingToFitWidth` 这 3 个 `BOOL` 值的属性让 `UILabel` 根据所显示的文本的内容自动地进行调整。如果你非常在意用户界面的美观，那么你就不要开启这些属性，因为这会使文字的显示效果变得不那么美观，但是有的时候，比如在进行程序不同语言本土化的时候，你会遇到一些很棘手的问题，除了使用这些选项外很难找到别的解决办法。不信的话，你可以打开 iPhone，在设置中把系统语言改为德语，然后你就会发现苹果官方出品的程序里到处都是被压扁变了形的丑陋不堪的文本。这种处理方法并不完美，但有时却很有用。

如果你使用这些选项让 UIKit 压缩你的文本以适配，如果压缩的时候想让文本保持在同一条基线上或需要对齐到左上角，那么你可以定义 `baselineAdjustment` 属性。然而，这个选项只对单行 label 起作用。

当你使用上述方法让文本自动缩放以适配  UILabel 时，你可以使用 baselineAdjustment 这个属性来调整缩放时文本是水平对齐还是对齐到 Label 的左上角。注意，这个属性仅在单行的  Lable （即  numberOfLines 属性值为1时）中生效。

## UITextField

像 label 一样，[text fields](https://developer.apple.com/library/ios/documentation/userexperience/conceptual/UIKitUICatalog/UITextField.html#//apple_ref/doc/uid/TP40012857-UITextField-SW1) 可以处理纯文本或带属性的文本。但 label 只能**显示**文本而已，text field 还可以处理用户的**输入**。然而 text field 只限于单行文本。`UITextField` 是 `UIControl` 的一个子类，它会**挂钩 （hook into）**到响应链，并且当用户开始或结束编辑时**分发（deliver）**这些行为消息，如果想要得到更多的控制权，你可以实现 text field 的[代理](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UITextFieldDelegate_Protocol/UITextFieldDelegate/UITextFieldDelegate.html#//apple_ref/occ/intf/UITextFieldDelegate)。

Text field 有一系列控制文本输入行为的选项。`UITextField` 实现了 [`UITextInputTraits`](https://developer.apple.com/library/ios/documentation/uikit/reference/UITextInputTraits_Protocol/Reference/UITextInputTraits.html) 协议，这个协议需要你指定键盘外观和操作的各种细节，比如，需要显示哪种键盘，返回按钮的响应事件是什么。

当没有文本输入的时候 Text field 还可以显示一个占位符，在右手边显示一个标准的清除按钮，控制任意左右两个辅助视图。你还可以为其设置一个背景图片，这样我们就可以用一个可变大小的图片为  text field 自定义边框风格了。

但每当你需要输入多行文本的时候，你就需要使用到 `UITextField` 的大哥了...

## UITextView

[Text view](https://developer.apple.com/library/ios/documentation/userexperience/conceptual/UIKitUICatalog/UITextView.html) 是显示或编辑大量文本的理想选择。 `UITextView` 是 `UIScrollView` 的一个子类，所以它能允许用户前后滚动达到处理溢出文本的目的。和 text field 一样， text view 也能处理纯文本和带属性的文本。Text view 也实现了 [`UITextInputTraits`](https://developer.apple.com/library/ios/documentation/uikit/reference/UITextInputTraits_Protocol/Reference/UITextInputTraits.html) 协议来控制键盘的行为和外观。

text view 除了处理多行文本的能力外，它最大的卖点就是你可以使用、定制整个 [Text Kit](https://developer.apple.com/Library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/CustomTextProcessing/CustomTextProcessing.html) 堆栈。你可以为 [layout manager](https://developer.apple.com/library/ios/documentation/uikit/reference/NSLayoutManager_Class_TextKit/Reference/Reference.html)、[text container](https://developer.apple.com/library/ios/documentation/uikit/reference/NSTextContainer_Class_TextKit/Reference/Reference.html) 或 [text storage](https://developer.apple.com/library/ios/documentation/uikit/reference/NSTextStorage_Class_TextKit/Reference/Reference.html) 自定义行为或者替换为你自定义的子类。你可以看看 Max 的这篇 [Text Kit 方面的文章](http://www.objccn.io/issue-5-1/)。

不幸的是，`UITextView` 在 iOS 7 中还有些问题，目前还是 1.0 版本。它是基于 OS X Text Kit 从头开始重新实现的。在 iOS 7 之前，它是基于 Webkit 的，并且功能很少。我们可以看看 [Peter][1] 和 [Brent][2] 关于这方面的文章。

## Mac中又是什么情况呢？
现在我们已经讨论过了 UIKit 中基本的 text 类，下面继续解释一下这些类在 AppKit 中结构的不同之处。

首先，AppKit 中并没有类似 `UILabel` 的控件。而显示文本最基本的类是 `NSTextField`。我们将 text field 设为不可编辑、不可选择，这样便等同于 iOS 中的 `UILabel` 了。虽然 `NSTextField` 听起来类似于 `UITextField`，但 `NSTextField` 并不限制于单行文本。

`NSTextView`，换句话说，就是等同于 `UITextView`，它也为我们揭露了整个 [Cocoa Text System](https://developer.apple.com/library/mac/documentation/TextFonts/Conceptual/CocoaTextArchitecture/Introduction/Introduction.html) 堆栈。但它还包含了很多额外的功能。很大的原因是因为 Mac 是一个具有指针设备（鼠标）的电脑。最值得注意的是包含了设置、编辑制表符的标尺。

## Core Text
上面我们讨论的所有类最终都使用 [Core Text](https://developer.apple.com/library/mac/documentation/StringsTextFonts/Conceptual/CoreText_Programming/Introduction/Introduction.html) 布局、绘制真实的符号。Core Text 是一个非常强大的 framework ，它已经超出我们这篇文章讨论的范围。但是如果你曾经需要通过完全自定义的方式绘制文本（例如，贝塞尔曲线），那你需要详细的了解一下。

Core Text 在任何绘图方面都为你提供了充分的灵活性。然而，Core Text 非常难于操作。它是一个复杂的 Core Foundation / C API。Core Text 在排版方面给了你充分的访问权限。

## 在 Table View 中显示动态文本

可能和所有人都打过交道的字符串绘制就是最常见的可变高度的 table view cells。你能在社交媒体应用中见到这种。 table view 的 delegate 有一个方法：`tableView:heightForRowAtIndexPath:`，这便是用来计算高度的。iOS 7之前，很难通过一种可靠的方式使用它。

在我们的示例中，我们将会在 table view 中显示一列语录：

<img alt="Table view with quotes" height="50%" src="/images/issues/issue-9/uitableview-finished.png" width="50%">

首先，为了实现完全的自定义，我们创建一个 `UITableViewCell` 的子类。在这个子类中，我们需要亲自为我们的 label 布局：

    - (void)layoutSubviews
    {
        [super layoutSubviews];
        self.textLabel.frame = CGRectInset(self.bounds, 
                                           MyTableViewCellInset,
                                           MyTableViewCellInset);
    }

`MyTableViewCellInset` 被定义为一个常量，所以我们可以将它用在 table view 的 delegate 的高度计算中。最简单、准确计算高度的方法是将字符串转换成带属性的字符串，然后计算出带属性字符串的高度。我们使用 table view 的宽度减去两倍的 `MyTableViewCellInset` 常量（前面和后面的空间）。为了计算真实的高度，我们需要使用  `boundingRectWithSize:options:context:` 这个方法。

第一个参数是限制 text 大小的。我们只需要关心宽度的限制，因此我们为高度传一个最大值常量 `CGFLOAT_MAX`。第二个参数是非常重要的：如果你传一个其他值，bounding rect 无疑会出错。如果你想要调整字体缩放或进行追踪，你可以使用第三个参数。最终，一旦我们得到 `boundingRect`，我们需要再次加上 inset：

    - (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
    {
        CGFloat labelWidth = self.tableView.bounds.size.width - MyTableViewCellInset*2;
        NSAttributedString *text = [self attributedBodyTextAtIndexPath:indexPath];
        NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin |
                                         NSStringDrawingUsesFontLeading;
        CGRect boundingRect = [text boundingRectWithSize:CGSizeMake(labelWidth, CGFLOAT_MAX)
                                                 options:options
                                                 context:nil];
    
        return (CGFloat) (ceil(boundingRect.size.height) + MyTableViewCellInset*2);    
    }

对于 bounding rect 的结果还有两件敏感的事情，除非你读了文档，不然这两件事你不一定会知道：返回值 size 是小数，文档中让我们使用 ceil 将结果四舍五入。最终的结果可能是会比实际的大一点。

请注意，因为我们的 text 是纯文本，我们创建的 `attributedBodyTextAtIndexPath:` 方法也会在 `tableView:cellForRowAtIndexPath:` 中用到。这样，我们需要确保他们保持同步。

还有，通过阅读文档（如下截图），我们发现 iOS 7 发布后，很多方法都被弃用了。如果你通过查找网页或 StackOverflow，你会发现很多测量字符高度的变通方法。因为苹果对文本框架进行了重大检修（在内部实现中，所有的东西都使用 TextKit 进行绘制了，而不是 WebKit），所以请使用新方法。

![Deprecated string measuring methods](/images/issues/issue-9/deprecated-methods.png)

另一个动态调整 table view cell 大小的选择就是使用 Auto Layout，你可以在[这篇博文](http://blog.amyworrall.com/post/66085151655/using-auto-layout-to-calculate-table-cell-height)中找到更详细的说明。然后你可以利用 contained lables 的 `intrinsicContentSize`。然而，现在自动布局比手动计算要慢很多。可是对于原型开发，这很完美：它允许你快速调整 constraints 并且移动事物（特别当你 cell 中不止一个控件时这显得特别重要）。一旦你完成产品的设计迭代，然后你就可以用手动布局的方式重新编写代码。


## 使用 Text Kit 和 NSAttributedString 进行布局

使用 Text Kit，你将会拥有令人惊讶的灵活性来创建专业级别的文本布局。随着这些灵活性带来的是如何组合为数众多的选项来完成复杂的布局。

我们准备给出几个示例并强调一些常见的布局问题，同时给出解决方案。

## 经典的文本
首先，让我们看一些经典的文本。我们将会使用 Jacomy-Régnier 的 [Histoire des nombres et de la numération mécanique](http://www.gutenberg.org/ebooks/27936)，并设为 [Bodoni](http://www.myfonts.com/fonts/itc/bodoni-seventy-two/) 字体。最终截屏效果如下所示:

<img alt="Layout-Example-1" height="50%" src="/images/issues/issue-9/Layout-Example-1.png" width="50%">

这些都是由 Text Kit 完成的。两段文字之间的装饰也是文本，使用的是 [Bodoni Ornaments](http://www.myfonts.com/fonts/itc/bodoni-ornaments/) 字体。

我们为文体风格使用调整好的 text。第一段从最左边开始，接下来的段落都会插入[空格](https://en.wikipedia.org/wiki/Em_space).

这有三种不同的风格：**文体**风格，首行缩进的变化文体风格，装饰物风格。

让我们先设置 `body1stAttributes`：

    CGFloat const fontSize = 15;
    
    NSMutableDictionary *body1stAttributes = [NSMutableDictionary dictionary];
    body1stAttributes[NSFontAttributeName] = [UIFont fontWithName:@"BodoniSvtyTwoITCTT-Book" 
                                                             size:fontSize];
    NSMutableParagraphStyle *body1stParagraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    body1stParagraph.alignment = NSTextAlignmentJustified;
    body1stParagraph.minimumLineHeight = fontSize + 3;
    body1stParagraph.maximumLineHeight = body1stParagraph.minimumLineHeight;
    body1stParagraph.hyphenationFactor = 0.97;
    body1stAttributes[NSParagraphStyleAttributeName] = body1stParag
    raph;

将字体设置为 `BodoniSvtyTwoITCTT`。这是字体的 PostScript 名。如果想寻找字体名，我们可以使用 `+[UIFont familyNames]` 首先得到可用的字体系列集合。一个字体系列就是我们所熟知的字型。每个字型或字体系列有一个或多个字体。为了得到这些字体的名字，我们可以使用 `+[UIFont fontNamesForFamilyName:]`。注意一下，当你处理多样字体时，`UIFontDescriptor` 类非常有用，比如，当你想要知道一个给定的字体是什么版本的斜体。

许多设置位于 `NSParagraphStyle`。我们创建一个默认风格的可变拷贝并做些调整。在我们的例子中，我们将会为字体大小加上 3 [pt](https://en.wikipedia.org/wiki/Point_%28typography%29)。

接着，我们会为这些段落的属性创建一个拷贝并修改他们来创建 `boddyAttributes`，（注意，这是我们段落的属性，跟上文的 `body1stParagraph` 已经不是同一个了）：

    NSMutableDictionary *bodyAttributes = [body1stAttributes mutableCopy];
    NSMutableParagraphStyle *bodyParagraph = 
      [bodyAttributes[NSParagraphStyleAttributeName] mutableCopy];
    bodyParagraph.firstLineHeadIndent = fontSize;
    bodyAttributes[NSParagraphStyleAttributeName] = bodyParagraph;

我们简单的创建了一个属性字典的可变拷贝，同时为了改变段落风格我们也需要创建一个可变拷贝。将  `firstLineHeadIndent` 设为和字体大小一样，我们便会得到想要的[空格缩进](https://en.wikipedia.org/wiki/Em_space)。

接着，装饰段落风格：

    NSMutableDictionary *ornamentAttributes = [NSMutableDictionary dictionary];
    ornamentAttributes[NSFontAttributeName] = [UIFont fontWithName:@"BodoniOrnamentsITCTT"
                                                              size:36];
    NSMutableParagraphStyle *ornamentParagraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    ornamentParagraph.alignment = NSTextAlignmentCenter;
    ornamentParagraph.paragraphSpacingBefore = fontSize;
    ornamentParagraph.paragraphSpacing = fontSize;
    ornamentAttributes[NSParagraphStyleAttributeName] = ornamentParagraph;

这个很容易理解。我们使用装饰字体并将文本居中对齐。此外，在装饰字符的前后我们都要加空白段落。

## 数据表格

接下来是显示数字的 table。我们想要将分数的小数点对齐显示，即英语中的 “.”：

<img alt="Layout-Example-2" height="50%" src="/images/issues/issue-9/Layout-Example-2.png" width="50%">

为了达到这个目的，我们需要指定  table 将中心停在分隔符上。

对于上面这个示例，我们简单的做一下：

    NSCharacterSet *decimalTerminator = [NSCharacterSet 
      characterSetWithCharactersInString:decimalFormatter.decimalSeparator];
    NSTextTab *decimalTab = [[NSTextTab alloc] 
       initWithTextAlignment:NSTextAlignmentCenter
                    location:100
                     options:@{NSTabColumnTerminatorsAttributeName:decimalTerminator}];
    NSTextTab *percentTab = [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentRight
                                                            location:200
                                                             options:nil];
    NSMutableParagraphStyle *tableParagraphStyle = 
      [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    tableParagraphStyle.tabStops = @[decimalTab, percentTab];

## 列表

另一个常见的使用情况就像 list 这样：

<img alt="Layout-Example-3" height="50%" src="/images/issues/issue-9/Layout-Example-3.png" width="50%">

（图片来自 [Robert's Rules of Order](http://www.gutenberg.org/ebooks/9097)，作者为 Henry M. Robert）

缩进相对容易设置。我们需要确保序列号 “(1)” 和 text 或者着重号和 text 之间有一个制表符。然后我们像这样调整段落的风格：

    NSMutableDictionary *listAttributes = [bodyAttributes mutableCopy];
    NSMutableParagraphStyle *listParagraph = 
      [listAttributes[NSParagraphStyleAttributeName] mutableCopy];
    listParagraph.headIndent = fontSize * 3;
    listParagraph.firstLineHeadIndent = fontSize;
    NSTextTab *listTab = [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentNatural
                                                         location:fontSize * 3 
                                                          options:nil];
    listParagraph.tabStops = @[listTab];
    listAttributes[NSParagraphStyleAttributeName] = listParagraph;

我们将 `headIndent` 设置为真实文本的缩进，将 `firstLineHeadIndent` 设置为我们希望着重号具有的缩进。最终，和 `headIndent` 一样，我们需要在相同的位置增加一个制表符。着重号后的制表符会确保这行文本从正确的位置开始绘制。

---

 
 
原文 [String Rendering](http://www.objc.io/issue-9/string-rendering.html)

译文 [字符串渲染 - answer_huang](http://answerhuang.duapp.com/index.php/2014/03/07/string-rendering/)

[1]: http://petersteinberger.com/blog/2014/fixing-uitextview-on-ios-7/
[2]: http://inessential.com/2014/01/07/uitextview_the_solution
