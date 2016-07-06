当为应用添加 AppleScript 支持的时候 - OS X 10.10 中也可以是 JavaScript 支持（译者注：10.10 中我们可以使用 JavaScript 作为脚本语言了），最好以应用的数据作为开始。这里的脚本并不是说自动按钮点击什么的；而是在说将你的 model 层暴露给那些会在自己的工作流程中使用你的应用的人。

有的用户会向朋友和家人推荐应用，虽然通常像这样的用户极少，但是他们是超级用户。他们的博客和 twitter 上有关于应用的内容，人们关注了他们。他们会成为你的应用的最大传播者。

总体而言，添加脚本支持最重要的原因是它使得应用更加专业，而这所能得到的回报是值得我们努力的。

## Noteland

Noteland 是一个除了空白窗口之外没有任何 UI 的应用，但是它有 model 层，并且可以脚本化。你可以在 [GitHub](https://github.com/objcio/issue-14-scriptable-apps) 上找到它。

Noteland 支持 AppleScript（10.10上还支持 JavaScript）。它是在 Xcode 5.1.1 中用 Objective-C 写的。我们最初试图使用 Swift 和 Xcode 6 Beta 2，但是出现了困难。这完全可能是我们自己的错误，因为毕竟我们仍然在学习 Swift。

### Noteland 的对象模型

有两个类，notes（笔记） 和 tags（标签）。可能有多个笔记，而且一个笔记也许有多个标签。

NLNote.h 声明了几个属性: `uniqueID`，`text`，`creationDate`，`archived`，`tags` 和一个只读的 `title` 属性。

Tags 类更加简单。NLTag.h 声明了两个可脚本属性: `uniqueID` 和 `name`。

我们希望用户能够创建，编辑和删除笔记和标签，并且能够访问和改变除了只读以外的属性。

### 脚本定义文件 (.sdef)

第一个步骤是定义脚本接口，概念上可以理解为为脚本创建一个 .h 文件，但是是以 AppleScript 能够识别的格式进行创建。

过去，我们需要创建和编辑 aete 资源（“aete” 代表 Apple Event Terminology）。现在容易了很多：我们可以创建一个 sdef（scripting definition 脚本定义）XML 文件。

你可能更倾向于使用 JSON 或者 plist，但是 XML 在这里会更加合适，至少它毫无疑问战胜了 aete 资源。事实上，曾有一段时间有 plist 版本，但是它要求你保持 *两个* 不同的 plist 同步，这非常痛苦。

原来的资源的名字 (aete，Apple Event Terminology) 其实没什么特别的意思。Apple event 是由 AppleScript 生成，发送和接受的低级别消息。这本身是一种很有趣的技术，而且有脚本支持以外的用途。而且实际上，它从 90 年代初的 System 7 开始就一直存在，而且在过渡到 OS X 的过程中存活了下来。

（猜测：Apple event 的存活是由于很多印刷出版商依赖于 AppleScript，在 90 年代中后期的 '黑暗日子' 中，出版商们是 Apple 最忠实的用户。）

一个 sdef 文件总是以同样的头部作为开始：

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE dictionary SYSTEM "file://localhost/System/Library/DTDs/sdef.dtd">

顶级项是字典 (dictionary)，“字典” 是 AppleScript 中专指一个脚本接口的词。在字典中你会发现一个或多个套件 (suite)。

（提示：打开 AppleScript Editor，然后选择 File > Open Dictionary...你会看到有脚本字典的应用列表。如果你选择 iTunes 作为例子，你会看到类，属性和 iTunes 能识别的命令。）

    <dictionary title="Noteland Terminology">

#### 标准套件

标准套件定义了应用应该支持的所有类和操作。其中包括退出，关闭窗口，创建和删除对象，查询对象等等。

将它添加到你的 sdef 文件，从位于 `/System/Library/ScriptingDefinitions/CocoaStandard.sdef` 的标准套件中复制和粘贴。

从 `<suite name="Standard Suite"`, 从头到尾且包括结尾 `</suite>` 复制所有东西。

将它粘贴到你的 sdef 文件中 `dictionary` 元素的正下方。

然后，在你的 sdef 文件中，遍历并删除所有没有用到的东西。Noteland 不基于文档且无需打印，所以我们去掉了打开和保存命令，文件类，以及与打印有关的一切。

（建议：Xcode 在 XML 的缩进方面做得很好，为了重新缩进，选中所有文本并且选择 Editor > Structure > Re-Indent。）

当你完成编辑后，使用命令行 xmllint 程序 `xmllint path/to/noteland.sdef` 以确保 XML 是正常的。如果它只显示了 XML，没有错误和警告，那么就是正确的。（记住你可以在 Xcode 的窗口标题栏拖拽文件的代理图标到终端，然后会粘贴文件的路径。）

#### Noteland 套件

一个单一的应用定义套件通常是最好的，虽然并不强制：当确实合情合理的时候，你可以有超过一个的套件。Noteland 只定义一个，下面是 Noteland 套件：

    <suite name="Noteland Suite" code="Note" description="Noteland-specific classes.">

脚本字典所期望的是某些部件被包含在其他东西中。顶级容器是应用程序对象本身。

在 Noteland 中，它的类名是 `NLApplication`。对于应用的类你应该总是使用 `capp` 作为编码 (code) 值：这是一个标准的 Apple event 编码。（注意它也存在于标准套件中。）

    <class name="application" code="capp" description="Noteland’s top level scripting object." plural="applications" inherits="application">
        <cocoa class="NLApplication"/>

该应用包含一个笔记的数组。区分元素（这里可以有不止一项）和属性非常重要。换句话说，编码中的数据应该作为你字典中的一个元素。

    <element type="note" access="rw">
        <cocoa key="notes"/>
    </element>`

Cocoa 脚本使用 KVC，字典用来指定键的名称。

#### Note 类

    <class name="note" code="NOTE" description="A note" inherits="item" plural="notes">
        <cocoa class="NLNote"/>`

上面的编码是 `NOTE`。这几乎可以是任何东西，但是请注意，Apple 保留所有的小写编码供自己使用，所以 `note` 是不被允许的。它可以是 `NOT*`, 或 `NoTe`, 或 `XYzy`，或者任何你想要的。（理想情况下自己的编码不会与其他应用的编码冲突。但是我们没有办法确保这一点，所以我们只能够 *猜测*。也就是说， 猜想 `NOTE` 可能并不是一个很好的选择。）

你的类应该继承自 `item`。（理论上，你可以让一个类继承自你的另一个类，不过我们没有做过这个尝试。）

note 类有多个属性：

    <property name="id" code="ID  " type="text" access="r" description="The unique identifier of the note.">
        <cocoa key="uniqueID"/>
    </property>
    <property name="name" code="pnam" type="text" description="The name of the note — the first line of the text." access="r">
        <cocoa key="title"/>
    </property>
    <property name="body" code="body" description="The plain text content of the note, including first line and subsequent lines." type="text" access="rw">
        <cocoa key="text"/>
    </property>
    <property name="creationDate" code="CRdt" description="The date the note was created." type="date" access="r"/>
    <property name="archived" code="ARcv" description="Whether or not the note has been archived." type="boolean" access="rw"/>

如果可能，最好为你的对象提供独一无二的 ID。否则，脚本不得不依赖于可能发生改变的名字和位置。对唯一的 ID 使用编码 'ID  '。（注意有两个空格；编码应该是四个字符。）而这个唯一 ID 的名字必须是 `id`。

只要有意义，提供 `name` 属性就是标准的做法，编码应该是 `pnam`。在 Noteland 中它是一个只读属性，因为名称只是笔记中文本的第一行，而且笔记的文本通过可读写的 `body` 属性编辑。 

对于 `creationDate` 和 `archived`，我们并不需要提供 Cocoa 的键元素，因为键和属性名字相同。

注意类型：text, date 和 boolean。AppleScript 支持它们和其它几个，详细地在[本文档中列出](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ScriptableCocoaApplications/SApps_about_apps/SAppsAboutApps.html#//apple_ref/doc/uid/TP40001976-SW12)。

笔记可以有标签，下面是一个标签元素：

    <element type="tag" access="rw">
        <cocoa key="tags"/>
    </element>
    </class>`

#### Tag 类

Tags 是 `NLTap` 对象：

    <class name="tag" code="TAG*" description="A tag" inherits="item" plural="tags">
        <cocoa class="NLTag"/>`

Tags 只有两个属性，`id` 和 `name`：

    <property name="id" code="ID  " type="text" access="r" description="The unique identifier of the tag.">
        <cocoa key="uniqueID"/>
    </property>
    <property name="name" code="pnam" type="text" access="rw">
        <cocoa key="name"/>
    </property>
    </class>

下面的代码是 Noteland 套件和整个字典的结束：

        </suite>
    </dictionary>

### 应用程序配置

应用不是默认就能脚本化的。我们在 Xcode 中，需要编辑应用的 Info.plist。

因为应用使用了一个自定义的 `NSApplication` 子类，用来提供顶级容器，我们编辑主体类 (`NSPrincipalClass`) 来声明 `NLApplication` (Noteland 的 `NSApplication` 子类名字)。

我们还添加了一个脚本化的键（`OSAScriptingDefinition`）并且设置它为 YES。最后，我们添加一个名为（`OSAScriptingDefinition`） 的键来表示脚本定义文件的名字，并将它设置为 sdef 的文件命名为：noteland.sdef。

### 代码

#### NSApplication 子类

你可能会惊讶竟然只需要写那么少的代码。

参见 Noteland 工程中的 NLApplication.m 文件。它惰性地创建了一个笔记数组且提供了一些 dummy 数据。说惰性只是因为它没有连接脚本支持。

（注意这里没有对象持久化，因为我想让 Noteland 尽可能自由，而不仅仅是脚本支持。你可以使用 Core Data 或 archiever（归档）或者其它东西来保存数据。）

它也可以跳过 dummy 数据并提供一个数组。

在本例中，数组是 `NSMutableArray` 类型的。它可以不必是 `NSMutableArray`，而是一个 `NSArray`，但这样的话 Cocoa 脚本在笔记数组发生改变时将会替换整个数组。但是如果我们让它作为 `NSMutableArray` 数组 *且* 提供下面两个方法的话，这个数组就不必被替换。取而代之，对象将会被添加到可变数组中，以及从中移除。 

    - (void)insertObject:(NLNote *)object inNotesAtIndex:(NSUInteger)index {
        [self.notes insertObject:object atIndex:index];
    }

    - (void)removeObjectFromNotesAtIndex:(NSUInteger)index {
        [self.notes removeObjectAtIndex:index];
    }

另外需要注意，笔记数组在类扩展的 .m 文件中被声明。不需要将它放到 .h 文件中。因为 Cocoa 脚本使用 KVC，而且不关心你的header，它会找到这个属性的。

#### NLNote 类

NLNote.h 声明了笔记的各个属性：`uniqueID`，`text`，`creationDate`，`archived`，`title` 和 `tags`。

在 `init` 方法中设置 `uniqueID` 和 `creationDate`，以及将标签数组设为空的 `NSArray`。这次我们使用 `NSArray` 而不是 `NSMutableArray`，仅仅为了说明它也可以达到目的。

`tilte` 方法返回一个计算后的值：笔记中文本的第一行。（回想一下，这会成为脚本字典的 `name`。）

要注意 `objectSpecifier` 方法。这是你的类的关键；脚本支持需要这个使其能够理解你的对象。

幸运的是，这个方法很容易实现。虽然对象说明符 (object specifiers) 有不同类型，通常情况下最好使用 `NSUniqueIDSpecifier`，因为它很稳定。（其它选项包括：`NSNameSpecifier`, `NSPositionalSpecifier` 等。）

对象说明符需要了解容器相关的东西，而且容器是顶级应用的对象。

代码如下所示：

    NSScriptClassDescription *appDescription = (NSScriptClassDescription *)[NSApp classDescription];
    return [[NSUniqueIDSpecifier alloc] initWithContainerClassDescription:appDescription containerSpecifier:nil key:@"notes" uniqueID:self.uniqueID];

`NSApp` 是全局应用的对象；我们获取它的 `classDescription`。键为 `@"notes"`，`containerSpecifier` 为 nil 指的是顶级（应用）的容器， `uniqueID` 是笔记的 `uniqueID`。

#### Note 作为容器

我们需要超前考虑一点。标签也会需要 `objectSpecifier`，而且标签是包含在笔记中的，所以标签需要引用包含它的笔记。

Cocoa 脚本处理标签的创建，但是我们可以重写让自己自定义行为的方法。

NSObjectScripting.h 定义了 `-newScriptingObjectOfClass:forValueForKey: withContentsValue:properties:`。这正是我们需要的。在 NLNote.m 中，它看起来是这样的：

    NLTag *tag = (NLTag *)[super newScriptingObjectOfClass:objectClass forValueForKey:key withContentsValue:contentsValue properties:properties];
    tag.note = self;
    return tag;

我们使用父类的实现来创建标签，然后设置标签的 `note` 属性为该笔记。为了避免可能的循环引用，NLTag.h 的 note 是 weak 属性。

（你可能认为这并不太不优雅，我们同意这么说。我们希望取代那种为了子类的 `objectSpecifiers` 而需要存在的容器。像是 `objectSpecifierForScriptingObject:` 这样可能会更好。我们提出了一个 bug [rdar://17473124](rdar://17473124)。）

#### NLTag 类

`NLTag` 有 `uniqueID`, `name`, 和 `note` 属性。

`NLTag` 的 `objectSpecifier` 在概念上和 `NLNote`中的代码相同，除了容器是笔记而不是顶级应用类。

它看起来像下面这样：

    NSScriptClassDescription *noteClassDescription = (NSScriptClassDescription *)[self.note classDescription];
    NSUniqueIDSpecifier *noteSpecifier = (NSUniqueIDSpecifier *)[self.note objectSpecifier];
    return [[NSUniqueIDSpecifier alloc] initWithContainerClassDescription:noteClassDescription containerSpecifier:noteSpecifier key:@"tags" uniqueID:self.uniqueID];

就是这样。完成了。并没有太多代码，大量的工作都是设计接口和编辑 sdef 文件。

在过去，你需要编写 Apple event 处理程序，并与 Apple event 描述符和各种一团乱麻的玩意儿一起工作。换句话说，要完成这些你需要走很长的路。值得庆幸的是，现在已经不是过去的日子了。 

接下来才是有趣的东西。

### AppleScript Editor

启动 Noteland。启动 /Applications/Utilities/AppleScript Editor.app。

运行下面的脚本：

    tell application "Noteland"
        every note
    end tell

在底部的结果窗口中，你会看到下面这样的信息：

    {note id "0B0A6DAD-A4C8-42A0-9CB9-FC95F9CB2D53" of application "Noteland", note id "F138AE98-14B0-4469-8A8E-D328B23C67A9" of application "Noteland"}

当然，ID 会有所不同，但是这些迹象表明，它在工作。

试一试这个脚本：

    tell application "Noteland"
        name of every note
    end tell

你会在结果窗中看到 `{"Note 0", "Note 1"}`。

再试一下这个脚本：

    tell application "Noteland"
        name of every tag of note 2
    end tell

结果：`{"Tiger Swallowtails", "Steak-frites"}`。

（请注意 AppleScript 数组是基于 1 的，所以 2 指的是第二个笔记。当我们明白这个以后，就一点也不奇怪了）

你也可以创建笔记：

    tell application "Noteland"
        set newNote to make new note with properties {body:"New Note" & linefeed & "Some text.", archived:true}
        properties of newNote
    end tell

结果将会是类似这样的（详细信息有相应改变）：

    {creationDate:date "Thursday, June 26, 2014 at 1:42:08 PM", archived:true, name:"New Note", class:note, id:"49D5EE93-655A-446C-BB52-88774925FC62", body:"New Note\nSome text."}`

你还可以创建新的标签：

    tell application "Noteland"
        set newNote to make new note with properties {body:"New Note" & linefeed & "Some text.", archived:true}
        set newTag to make new tag with properties {name:"New Tag"} at end of tags of newNote
        name of every tag of newNote
    end tell

结果会是：`{"New Tag"}`。

完美工作！

### 扩展学习

将对象模型脚本化只是添加脚本支持的一部分；你也可以为命令添加支持。例如，Noteland 可以有一个将笔记写到硬盘文件的导出命令。RSS 阅读器可能有一个刷新命令，邮件应用可能有下载邮件命令，等等。

Matt Neuburg 的 [AppleScript 权威指南](http://www.amazon.com/AppleScript-Definitive-Guide-Matt-Neuburg/dp/0596102119/ref=la_B001H6OITU_1_1?s=books&ie=UTF8&qid=1403816403&sr=1-1) 值得一读，尽管它是 2006 年出版的，但是从那以后并没有发生太大的改变。Matt 还写有一篇 [Cocoa 应用添加脚本支持的教程](http://www.apeth.net/matt/scriptability/scriptabilityTutorial.html)。该教程绝对值得一读，它比这篇文章更加详细。

这有一个 [WWDC 2014 Session 的视频](https://developer.apple.com/videos/wwdc/2014/)，是关于 JavaScript 的自动化的，其中谈到了新的 JavaScript OSA 语言。（多年以前 Apple 曾提出，总有一天会出现 AppleScript 的程序员的特有语言，因为自然语言对写 C 和 C 类语言的人说略有一点怪。JavaScript 可以被认为是程序员的特有语言。）

当然，Apple 有关于这些技术的文档：

- [Cocoa 脚本指南](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ScriptableCocoaApplications/SApps_intro/SAppsIntro.html#//apple_ref/doc/uid/TP40002164)
- [AppleScript 概览](https://developer.apple.com/library/mac/documentation/applescript/conceptual/applescriptx/AppleScriptX.html#//apple_ref/doc/uid/10000156-BCICHGIE)

此外，请参阅 Apple 的 Sketch 应用，它实现了脚本化。

---

 
 
原文 [Making Your Mac App’s Data Scriptable](http://www.objc.io/issue-14/scripting-data.html)
