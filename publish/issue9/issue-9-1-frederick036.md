当你在处理文本时，如果你不是在写一些非常**古老的代码（legacy code）**，那么你一定要使用 [Unicode](http://en.wikipedia.org/wiki/Unicode)。幸运的是，苹果和 NeXT 一直致力于推动 Unicode 标准的建立，而 NeXT 在 [1994 年](http://blog.securemacprogramming.com/2013/10/happy-19th-birthday-cocoa/)推出的 [Foundation Kit](http://www.cilinder.be/docs/next/NeXTStep/3.3/nd/Foundation/IntroFoundation.htmld/index.html) 则是所有编程语言中最先基于 Unicode 的标准库之一。但是，即使 [`NSString`](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/Classes/NSString_Class/Reference/NSString.html) 完全支持 Unicode，还替你干了大部分的重活儿，处理各种语言、各种书写系统的文本仍然是一个非常复杂的事情。作为一个程序员，有些事情你应该知道。

这篇文章里，我会先向你简单地讲一下 Unicode 这个标准，然后解释 `NSString` 是怎么处理它的，再讨论一下你可能会遇到的一些常见问题。

## 历史

计算机没法直接处理文本，它只和数字打交道。为了在计算机里用数字表示文本，我们指定了一个从字符到数字的映射。这个映射就叫做[**编码（encoding）**](http://en.wikipedia.org/wiki/Character_encoding)。

最有名的一个字符编码是 [ASCII](http://en.wikipedia.org/wiki/ASCII)。ASCII 码是 7 位的，它将英文字母，数字 0-9 以及一些标点符号和控制字符映射为 0-127 这些整型。随后，人们创造了许多不同的 8 位编码来处理英语以外的其他语言。它们大多都是基于 ASCII 编码的，并且使用了 ASCII 没有使用的第 8 位来编入其它字母、符号甚至是整个字母表（比如西里尔字母和希腊字母）。

当然，这些编码系统相互之间并不兼容，并且，由于 8 位的空间对于欧洲的文字来说都不够，更不用说全世界的书写系统了，因此这种不兼容是肯定会出现的了。这对于当时基于文本的操作系统来说是很麻烦的，因为那时操作系统只能同时使用一种编码（也叫做内码表，[code page](http://www.i18nguy.com/unicode/codepages.html)）。如果你在一台机器上写了一段文字，然后在另一台使用了不同的内码表的机器上打开，那么在 128-255 这个范围内的字符就会显示错误。

诸如中文、日文和韩文的东亚文字又让情况更加复杂。这些书写系统里包含的字符实在是太多了，以至于 8 位的数字所能提供的 256 个位置远远不够。结果呢，人们开发了更加通用的编码（通常是 16 位的）。当你开始纠结于如何处理一个字节装不下的值时，如何把它存储到内存或者硬盘里就变得十分关键了。这时，就必须再进行第二次映射，以此来确定[字节的顺序]( http://en.wikipedia.org/wiki/Endianness)。而且，最好使用[可变长度](http://en.wikipedia.org/wiki/Variable-width_encoding)的编码而不是固定长度的。请注意，第二次映射其实是另一种形式的“编码”。我们把这两个映射都叫做“编码”很容易造成误解。这个在下面 UTF-8 和 UTF-16 的部分里会再作讨论。

现代操作系统都已经不再局限于只能同时使用一种内码表了，因此只要每个文档都清楚地标明自己使用的是哪种编码，处理几十甚至上百种编码系统尽管很讨厌，也完全是有可能的。真正不可能的是在一个文档里_混合_使用多种编码系统，因此撰写多语言的文档也不可能了，而正是这一点终结了在 Unicode 编码出现之前，多种编码混战的局面。

[1987 年](http://www.unicode.org/history/summary.html)，来自几个大的科技公司（其中包括苹果和 NeXT）的工程师们开始合作致力于开发一种能在全世界所有书写系统中通用的字符编码系统，于 1991 年 10 月发布的 1.0.0 版本的 Unicode 标准就是这一努力的成果。

## Unicode 概要

### 基本介绍

简单地来说，Unicode 标准为世界上几乎所有的[^1]书写系统里所使用的每一个字符或符号定义了一个唯一的数字。这个数字叫做**码点（code points）**，以 `U+xxxx` 这样的格式写成，格式里的 `xxxx` 代表四到六个十六进制的数。比如，U+0041（十进制是 65）这个码点代表拉丁字母表（和 ASCII 一致）里的字母 A；U+1F61B 代表名为“伸出舌头的脸”的 [emoji](http://en.wikipedia.org/wiki/Emoji)，也就是 😛（顺便说一下，字符的名字也是 Unicode 标准的一部分。）。你可以用官方的 [Code Charts](http://www.unicode.org/charts/index.html) 或者 OS X 里自带的字符显示程序（快捷键是 <kbd>Control</kbd> + <kbd>Option</kbd> + 空格键）来查码点。

> <span class="secondary radius label">编者注</span> 原文中的这个快捷键已经过时了，在最新的 OS X Mavericks 系统中，字符显示程序的快捷键应该是 <kbd>Control</kbd> + <kbd>Cmd</kbd> + 空格键。

![The Character Viewer in OS X showing a table of Emoji and Unicode character information](/images/issues/issue-9/os-x-character-viewer-emoji.png)

就像上文提到的其它编码一样，Unicode 以抽象的方式代表一个字符，而不规定这个字符应该如何**呈现（render）**。如此一来，Unicode 对中文、日文和韩文（CJK）里使用的汉字（也就是所谓的[统一汉字](http://en.wikipedia.org/wiki/Han_unification)）都使用完全相同的码点（这一决定颇具争议），尽管在这些书写系统里，每个汉字都发展出了独特的**字形（glyph）**变体。

最初，Unicode 编码是被设计为 16 位的，提供了 65,536 个字符的空间。当时人们认为这已经大到足够编码世界上现代文本里所有的文字和字符了。不再使用的和罕见的字符本应在需要时被编入 [Private Use Areas](http://en.wikipedia.org/wiki/Private_Use_Areas)，这是 65,536 个字符的空间里一个指定的区域，各个机构可以用它来定义自己的字符映射（这有可能导致冲突）。苹果在这个区域里编入了一些自定义符号和控制字符（文档在[这里](http://www.unicode.org/Public/MAPPINGS/VENDORS/APPLE/CORPCHAR.TXT)），虽然大多数已经不再使用了，但是苹果的 logo 是个著名的例外：，它的码点是 U+F8FF。（你可能看到的是另一个不同的字符，这取决于你阅读本文的平台）。

[后来](http://www.unicode.org/faq/utf_bom.html#gen0)，考虑到要编码历史上的文字以及一些很少使用的日本汉字和中国汉字[^2]，Unicode 编码扩展到了 21 位（从 U+0000 到 U+10FFFF）。这一点很重要：不管接下来的 `NSString` 的内容是什么样的，**Unicode 不是 16 位的编码！**它是 21 位的。这 21 位提供了 1,114,112 个码点，其中，只有大概 10% 正在使用，所以还有相当大的扩充空间。

编码空间被分成 17 个**平面**（[plane](http://en.wikipedia.org/wiki/Plane_%28Unicode%29)），每个平面有 65,536 个字符。0 号平面叫做**「基本多文种平面」（Basic Multilingual Plane, BMP）**，涵盖了几乎所有你能遇到的字符，除了 emoji。其它平面叫做补充平面，大多是空的。

<a name="peculiar-unicode-features"> </a>
### Unicode 的一些特性

最好将 Unicode 看做是已有的各编码系统（它们大多是 8 位的）的统一，而不是一个**通用**的编码。考虑到要兼容一些古老的编码系统，这个标准包含了一些需要注意的地方，你需要了解它们才能在你的代码里正确地处理 Unicode 字符串。

#### 组合字符序列

为了和已有的标准兼容，某些字符可以表示成以下两种形式之一：一个单一的码点，或者两个以上连续的码点组成的序列。例如，有重音符号的字母 é 可以直接表示成 U+00E9（「有尖音符号的小写拉丁字母 e」），或者也可以表示成由 U+0065（「小写拉丁字母 e」）再加 U+0301（「尖音符号」）组成的分解形式。这两个形式都是[组合字符序列](http://en.wikipedia.org/wiki/Precomposed_character)的变体。组合字符序列不仅仅出现在西方文字里；例如，在[谚文**](http://en.wikipedia.org/wiki/Hangul)（朝鲜、韩国的文字）中，가 这个字可以表示成一个码点（U+AC00），或者是 ᄀ + ᅡ （U+1100，U+1161）这个序列。

在 Unicode 的语境下，两种形式**并不相等**（因为两种形式包含不同的码点），但是符合**「标准等价」**（[canonically equivalent](http://en.wikipedia.org/wiki/Unicode_equivalence)），也就是说，它们有着相同的外观和意义。

#### 重复的字符

许多看上去一样的字符都在不同的码点编码了多次，以此来代表不同的含义。例如，拉丁字母 A（U+0041）就与[西里尔字母 A](http://en.wikipedia.org/wiki/A_%28Cyrillic%29)（U+0410）完全同形，但事实上，它们是不同的。把它们编入不同的码点不仅简化了与老的编码系统的转换，而且能让 Unicode 的文本保留字符的含义。

但也有极少数真正的重复，这些完全相同的字符在不同的码点上定义了多次。例如，Unicode 联盟就[列举](http://www.unicode.org/standard/where/#Duplicates)出了字母 Å（「上面带个圆圈的大写拉丁字母 A」，U+00C5）和字符 Å（「埃米」（长度单位）符号，U+212B）。考虑到「埃米」符号其实就是被定义成这个瑞典大写字母的，因此这两个字符是完全相同的。在 Unicode 里，它们也符合标准等价但不相等。

还有更多的字符和序列是更广意义上的「重复」，在 Unicode 标准里叫做**「相容等价」**（[compatibility equivalence](http://en.wikipedia.org/wiki/Unicode_equivalence)）。相容的序列代表着相同的字符，但有着不同的外观和表现。例子包括很多被用作数学和技术符号的希腊字母，还有，尽管已经有了从 U+2160 到 U+2183 这个范围里的标准拉丁字母，罗马数字也被单独编入 Unicode。其它关于相容等价的典型例子就是**连字**（[ligature](http://en.wikipedia.org/wiki/Typographic_ligature)）：字母 ff（小写拉丁连字 ff，U+FB00）和 ff 的序列（小写拉丁字母 f + 小写拉丁字母 f，U+0066 U+0066）就符合相容等价但不符合标准等价，虽然它们也可能以完全一致的样子呈现出来，这取决于环境、字体以及文本的渲染系统。

<a name="normalization-forms"> </a>
#### 正规形式

从上面可以看出，在 Unicode 里，字符串的等价性并不是一个简单的概念。除了一个码点一个码点地比较两个字符串以外，我们还需要另一种方式来鉴定标准等价和相容等价。为此，Unicode 定义了几个**正规化**（[normalization](http://en.wikipedia.org/wiki/Unicode_normalization#Normalization)）算法。正规化一个字符串的意思是：为了能使它与另一个正规化了的字符串进行二进制比较（binary-compare），将其转化成有且仅有的唯一一个表示形式，这个形式由等价字符的序列组成。

Unicode 标准里包含了四个正规形式，分别是 C、D、KD 和 KC。它们可以放入一个 2*2 的矩阵里（下面还列举出了 `NSString` 提供的对应方法）：  

<table>
  <thead>
    <tr>
      <th colspan="2" rowspan="2">Unicode 正规形式（NF）</th>
      <th colspan="2">字符形式</th>
    </tr>
    <tr>
      <th>合成形式（é）</th>
      <th>分解形式（e + ´）</th>
    </tr>
  </thead>
  <tr>
    <th rowspan="2">等价<br>类别</th>
    <th>标准等价</th>
    <td>
      <p>C</p>
      <p><a href="https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/precomposedStringWithCanonicalMapping"><code>precomposed​String​With​Canonical​Mapping</code></a></p>
    </td>
    <td>
      <p>D</p>
      <p><a href="https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/decomposedStringWithCanonicalMapping"><code>decomposed​String​With​Canonical​Mapping</code></a></p>
    </td>
  </tr>
  <tr>
    <th>相容等价</th>
    <td>
      <p>KC</p>
      <p><a href="https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/precomposedStringWithCompatibilityMapping"><code>precomposed​String​With​Compatibility​Mapping</code></a></p>
    </td>
    <td>
      <p>KD</p>
      <p><a href="https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/decomposedStringWithCompatibilityMapping"><code>decomposed​String​With​Compatibility​Mapping</code></a></p>
    </td>
  </tr>
</table>


仅仅为了比较的话，先把字符串正规化成分解形式（D）还是合成形式（C）并不重要。但 C 形式的算法包含两个步骤：先分解字符再重新组合起来，因此 D 形式要更快一些。如果一个字符序列里含有多个组合标记，那么组合标记的顺序在分解后会是唯一的。另一方面，Unicode 联盟[推荐 C 形式](http://www.unicode.org/faq/normalization.html#2)用于存储，因为它能和从旧的编码系统转换过来的字符串更好地兼容。

两种等价对于字符串比较来说都很有用，尤其在排序和查找时。但是，要记住，如果要永久保存一个字符串，一般情况下不应该用相容等价的方式去将它正规化，因为[这样会改变文本的含义](http://zhuanlan.zhihu.com/)：

>不要对任意文本都盲目地使用 KC 或 KD 这两种正规形式，这样会清除很多格式上的差异。它们能防止与许多老旧的字符集之间的循环转化，与此同时，除非有格式标记代替，否则 KC 和 KD 还会清除许多对文本的语义很重要的差异。最好把这些正规形式想成字母大写与小写之间的映射：有时在需要辨认很重要的意思时很有用，但也会不恰当地修改文本。

#### 字形变体

有些字体会为一个字符提供多个字形（[glyph](http://en.wikipedia.org/wiki/Glyph)）变体。Unicode 提供了一个叫做「变体序列」（[variation sequences](http://en.wikipedia.org/wiki/Variant_form_%28Unicode%29)）的机制，它允许用户选择其中一个变体。这和组合字符序列的工作机制完全一样：一个基准字符加上 256 个变体选择符（VS1-VS256，U+FE00 到 U+FE0F，还有 U+E0100 到 U+E01EF）中的一个。Unicode 标准对「标准化变体序列」（[Standardized Variation Sequences](http://unicode.org/Public/UCD/latest/ucd/StandardizedVariants.html)，在 Unicode 标准中定义）和「象形文字变体序列」（[Ideographic Variation Sequences](http://www.unicode.org/ivd/)，是由第三方提交给 Unicode 联盟的，一旦注册，它可以被任何人使用）做出了区分。技术上来讲，两者并无区别。

emoji 的样式就是一个标准化变体序列的例子。许多 emoji 和一些「正常」的字符都有两种风格：一种是彩色的「emoji 风格」，另一种是黑白的，更像是符号的「文本风格」。例如，「有雨滴的伞」这个字符（U+2614）可能是这样：☔️ (U+2614 U+FE0F) ，也可能是这样的： ☔︎ (U+2614 U+FE0E)。

### Unicode 转换格式

从上文可以看到，字符和码点之间的映射只完成了一半工作，还需要定义另一种编码来确定码点在内存和硬盘中要如何表示。Unicode 标准为此定义了几种映射，叫做「Unicode 转换格式」（Unicode Transformation Formats，简称 UTF）。日常工作中，人们就直接把它们叫做「编码」—— 因为按照定义，如果是用 UTF 编码的，那么就要使用 Unicode，所以也就没必要明确区分这两个步骤了。

### UTF-32

最清楚明了的一个 UTF 就是 [UTF-32](http://en.wikipedia.org/wiki/UTF-32)：它在每个码点上使用整 32 位。32 大于 21，因此每一个 UTF-32 值都可以直接表示对应的码点。尽管简单，UTF-32却几乎从来不在实际中使用，因为每个字符占用 4 字节太浪费空间了。

### UTF-16 以及「代理对」（Surrogate Pairs）的概念

[UTF-16](http://en.wikipedia.org/wiki/UTF-16) 要常见得多，而且在下文我们会看到，它与我们讨论 `NSString` 对 Unicode 的实现息息相关。它是根据有 16 位固定长度的**码元（code units）**定义的。UTF-16 本身是一种长度可变的编码。基本多文种平面（BMP）中的每一个码点都直接与一个码元相映射。鉴于 BMP 几乎囊括了所有常见字符，UTF-16 一般只需要 UTF-32 一半的空间。其它平面里很少使用的码点都是用两个 16 位的码元来编码的，这两个合起来表示一个码点的码元就叫做**代理对（surrogate pair）**。

为了避免用 UTF-16 编码的字符串里的字节序列产生歧义，以及能使检测代理对更容易，Unicode 标准限制了 U+D800 到 U+DFFF 范围内的码点用于 UTF-16，这个范围内的码点值不能分配给任何字符。当程序在一个 UTF-16 编码的字符串里发现在这个范围内的序列时，就能立刻知道这是某个代理对的一部分。实际的编码算法很简单，[维基百科上 UTF-16 的文章](http://en.wikipedia.org/wiki/UTF-16)里有更多介绍。UTF-16 的这种设计也是为什么码点最长也只有奇怪的 21 位的原因。UTF-16 下，U+10FFFF 是能编码的最高值。

和所有多字节长度的编码系统一样，UTF-16（以及 UTF-32）还得解决[字节顺序](http://en.wikipedia.org/wiki/Endianness)的问题。在内存里存储字符串时，大多数实现方式自然都采用自己运行平台的 CPU 的**字节序（endianness）**；而在硬盘里存储或者通过网络传输字符串时，UTF-16 允许在字符串的开头插入一个「字节顺序标记」（[Byte Order Mask](http://en.wikipedia.org/wiki/Byte_Order_Mark)，简称 BOM）。字节顺序标记是一个值为 U+FEFF 的码元，通过检查文件的头两个字节，解码器就可以识别出其字节顺序。字节顺序标记不是必须的，Unicode 标准把**高字节顺序（big-endian byte order）**定为默认情况。UTF-16 需要指明字节顺序，这也是为什么 UTF-16 在文件格式和网络传输方面不受欢迎的一个原因，不过微软和苹果都在自己的操作系统内部使用它。

#### UTF-8

由于 Unicode 的前 256 个码点（U+0000 到 U+00FF）和常见的 [ISO-8859-1](http://en.wikipedia.org/wiki/ISO/IEC_8859-1)(Latin 1) 编码完全一致，UTF-16 还是在常用的英文和西欧文本上浪费了大量的空间：每个 16 位的码点的高 8 位的值都会是 0[^3]。也许更重要的是，UTF-16 对一些老旧的代码造成了挑战，这些代码常常会假定文本是用 ASCII 编码的。Ken Thompson（他在 Unix 社区很有名） 和 Rob Pike 开发了 [UTF-8](http://en.wikipedia.org/wiki/UTF-8) 来弥补这些不足[^4]。它的设计很出色，请务必阅读 [Rob Pike 对 UTF-8 创造过程的讲述](http://www.cl.cam.ac.uk/~mgk25/ucs/utf-8-history.txt)。

UTF-8 使用一到四个[^5]字节来编码一个码点。从 0 到 127 的这些码点直接映射成 1 个字节（对于只包含这个范围字符的文本来说，这一点使得 UTF-8 和 ASCII 完全相同）。接下来的 1,920 个码点映射成 2 个字节，在 BMP 里所有剩下的码点需要 3 个字节。Unicode 的其他平面里的码点则需要 4 个字节。UTF-8 是基于 8 位的码元的，因此它并不需要关心字节顺序（不过仍有一些程序会在 UTF-8 文件里加上多余的 BOM）。

有效率的空间使用（仅就西方语言来讲），以及不需要操心字节顺序问题使得 UTF-8 成为存储和交流 Unicode 文本方面的最佳编码。它也已经是文件格式、网络协议以及 Web API 领域里**事实上**的标准了。

## NSString 和 Unicode

`NSString` 是完全建立在 Unicode 之上的。但是，这方面苹果解释得并不好。这是[苹果的文档对 `CFString` 对象的说明](https://developer.apple.com/library/ios/documentation/CoreFoundation/Conceptual/CFStrings/Articles/UnicodeBasis.html)（`CFString` 也包含了 `NSString` 的底层实现）：

>从概念上来讲，CFString 代表了一个 Unicode 字符组成的数组和一个字符总数的计数。……\[Unicode\] 标准定义了一个通用、统一的编码方案，其中**每个字符 16 位**。  

强调是我（原文作者）加的。这完全是错误的！我们已经了解了 Unicode 是一种 **21 位**的编码方案。但是有了这样的文档，难怪很多人都认为它是 16 位的呢。

[`NSString` 的文档](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/Classes/NSString_Class/Reference/NSString.html)同样误导人：

>一个字符串对象代表着一个 Unicode 字符组成的数组…… 可以用 `length` 方法来获得一个字符串对象所包含的字符数；用 `characterAtIndex:` 方法取得特定的字符。这两个简单的方法为访问字符串对象提供了基本的途径。  

这段话初读起来似乎好一些了，它没有又扯淡地讲 Unicode 字符是 16 位的。但深究后就会发现，[`characterAtIndex:`](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/characterAtIndex:) 这个方法的返回值 [`unichar`](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/uid/20000154-SW40) 不过是个 16 位的无符号整型罢了。显然，它不够用来表示 21 位的 Unicode 字符：

	typedef unsigned short unichar;

事实是这样的，`NSString` 对象代表的其实是**用 UTF-16 编码的码元**组成的数组。相应地，[`length`](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/length) 方法的返回值也是字符串包含的码元个数（而不是字符个数）。`NSString` 还在开发的时候（它最初是作为 Foundation Kit 的一部分在 1994 年发布的），Unicode 还是 16 位的；更广的范围和 UTF-16 的代理字符机制则是于 1996 年随着 Unicode 2.0 引入的。从现在的角度来看，`unichar` 这个类型和 `characterAtIndex:` 这个方法的命名都很糟糕，因为它们使程序员对于 Unicode 字符（码点）和 UTF-16 码元两个概念困惑的情况更加严重。如果像 `codeUnitAtIndex:` 这样来命名则要好得多。

关于 `NSString`，最需要记住的是：`NSString` 代表的是用 UTF-16 编码的文本，长度、索引和范围都基于 UTF-16 的码元。除非你知道字符串的内容，或者你提前有所防范，不然 `NSString` 类里的方法都是基于上述概念的，无法给你提供可靠的信息。每当文档提及「字符」（character）或者 `unichar` 时，它其实都说的是码元。事实上，在 String Programming Guide 里之后一个章节中，文档的表述是正确的，但继续错误地使用「字符」（character）这个词。强烈建议你阅读 [Characters and Grapheme Clusters](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Strings/Articles/stringsClusters.html) 这一章，里面很好地解释了真实的情况。

请注意，尽管在概念上 `NSString` 是基于 UTF-16 的，但这并不意味着这个类总是能与 UTF-16 编码的数据很好地工作。它不保证内部的实现（你可以子类化 `NSString` 来写你自己的实现）。事实上，在保证快速的（时间复杂度 O(1) 级别）与 UTF-16 码元转换的同时，`CFString` [尽可能有效率地利用内存](https://developer.apple.com/library/ios/documentation/CoreFoundation/Conceptual/CFStrings/Articles/StringStorage.html)，这取决于字符串的内容。你可以阅读 [CFString 的源代码](http://www.opensource.apple.com/source/CF/CF-855.11/CFString.c)来自己验证。

### 常见的陷阱

了解了 `NSString` 和 Unicode，你现在应该能辨别出哪些操作对字符串有潜在的危险。我们来看看这些操作，以及如何避免出现问题。但首先，我们得知道怎么用任意的 Unicode 字符序列创建字符串。

默认情况下，Clang 会把源文件看作以 UTF-8 编码的。只要你确保 Xcode 以 UTF-8 编码保存文件，你就可以直接用字符显示程序插入任意字符。如果你更喜欢用码点，最大到 U+FFFF 这个范围内的码点你可以以 `@"\u266A"`（♪）的方式输入，BMP 外其它平面的码点则以 `@"\U0001F340"`（🍀）的方式输入。有意思的是，[C99 不允许](http://c0x.coding-guidelines.com/6.4.3.html)标准 C 字符集里的字符用**通用字符名**（universal character name）来指定，因此不能这样写：

    NSString *s = @"\u0041"; // Latin capital letter A
    // error: character 'A' cannot be specified by a universal character name

我认为应该避免使用[格式化占位符](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) %C（使用 `unichar` 类型）来创建字符串变量，因为这样很容易混淆码元和码点。但是在输出 log 信息时 %C 很有用。

#### 长度

`-[NSString length]` 返回字符串里 `unichar` 的个数。我们已经了解了三个可能导致这个返回值与实际（可见）字符数不符的 Unicode 特性。

1. 基本多文种平面外的字符：记住，BMP 里所有的字符在 UTF-16 里都可以用一个码元表示。所有其余的字符都需要两个码元（一个代理对）。基本上所有现代使用的字符都在 BMP 里，因此在实际中很难遇到代理对。然而，几年前随着 emoji 被引入 Unicode（在 1 号平面），这种情况已经有所变化。emoji 已经变得十分普遍，你的代码必须能够正确处理它们：

        NSString *s = @"\U0001F30D"; // earth globe emoji 🌍  
        NSLog(@"The length of %@ is %lu", s, [s length]);
        // => The length of 🌍 is 2  

	可以用一个小花招解决这个问题，直接计算字符串在 UTF-32 编码下所需要的字节数，再除以 4：  

		NSUInteger realLength =
		[s lengthOfBytesUsingEncoding:NSUTF32StringEncoding] / 4;  
		NSLog(@"The real length of %@ is %lu", s, realLength);  
		// => The real length of 🌍 is 1  

2. 组合字符序列：如果字母 é 是以分解形式（e + ´）编码的，算作两个码元：

	    NSString *s = @"e\u0301"; // e + ´  
	    NSLog(@"The length of %@ is %lu", s, [s length]);
	    // => The length of é is 2  

	这个字符串包含了两个 Unicode 字符，在这个意义上，返回值 `2` 是正确的，但显然正常人都不会这么去数。可以用 `precomposedStringWithCanonicalMapping:` 把字符串正规化成 C 形式（合成形式）来得到更好的结果：  

		NSString *n = [s precomposedStringWithCanonicalMapping];
    	NSLog(@"The length of %@ is %lu", n, [n length]);
    	// => The length of é is 1  

	不巧的是，并不是所有情况都能这样做，因为只有最常见的组合字符序列有合成形式——其它基础字符与标记的组合即便是经过正规化后，也会保持原样。如果你想知道字符串真正的字符个数，你只能遍历字符串自己数。后面循环那一节会继续讨论有关细节。

3. 变体序列：它们和分解形式的组合字符序列的工作方式一样，因此变体选择符也算作单独的字符。

#### 随机访问

用 `characterAtIndex:` 方法以索引方式直接访问 `unichar` 会有同样的问题。字符串可能会包含组合字符序列、代理对或变体序列。苹果把这些都叫做**合成字符序列**（composed character sequence），这些术语就变得容易混淆。注意不要把合成字符序列（苹果的术语）和组合字符序列（Unicode 术语）搞混。后者是前者的子集。可以用 [`rangeOfComposedCharacterSequenceAtIndex:`](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/rangeOfComposedCharacterSequenceAtIndex:) 来确定特定位置的 `unichar` 是不是代表单个字符（可能由多个码点组成）的码元序列的一部分。每当给另一个方法传入一个内容未知的字符串的范围作参数时都应该这样做，确保 Unicode 字符不会被从中间分开。

#### 循环

使用 `rangeOfComposedCharacterSequenceAtIndex:` 的时候，可以写一个代码套路来正确地循环字符串里所有的字符，但每次要遍历一个字符串时都得这样做太不方便了。幸运的是，`NSString` 有更好地方式：[`enumerateSubstringsInRange:options:usingBlock:`](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/enumerateSubstringsInRange:options:usingBlock:) 方法。这个方法把 Unicode 抽象的地方隐藏了，能让你轻松地循环字符串里的组合字符串、单词、行、句子或段落。你甚至可以加上 `NSStringEnumerationLocalized` 这个选项，这样可以在确定词语间和句子间的边界时把用户所在的区域考虑进去。要遍历单个字符，把参数指定为 `NSStringEnumerationByComposedCharacterSequences`：

    NSString *s = @"The weather on \U0001F30D is \U0001F31E today.";  
    // The weather on 🌍 is 🌞 today.  
    NSRange fullRange = NSMakeRange(0, [s length]);  
    [s enumerateSubstringsInRange:fullRange  
                          options:NSStringEnumerationByComposedCharacterSequences  
                       usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop)
	{
		NSLog(@"%@ %@", substring, NSStringFromRange(substringRange));
	}];

这个奇妙的方法表明，苹果想让我们把字符串看做子字符串的集合，而不是（苹果意义上的）字符的集合，因为  

1. 单个 `unichar` 太小，不足以代表一个真正的 Unicode 字符；
2. 一些（普遍意义上的）字符由多个 Unicode 码点组成。  

请注意，这个方法的加入相对晚一些（在 OS X 10.6 和 iOS 4.0 的时候）。在之前，按字符循环一个字符串要麻烦得多。

#### 比较

除非你手动执行，否则字符串对象不会自己正规化。这意味着直接比较包含组合字符序列的字符串可能会得出错误的结果。[`isEqual:`](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Protocols/NSObject_Protocol/Reference/NSObject.html#//apple_ref/occ/intfm/NSObject/isEqual:) 和 [`isEqualToString:`](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/isEqualToString:) 这两个方法都是一个字节一个字节地比较的。如果希望字符串的合成和分解的形式相吻合，得先自己正规化：

	NSString *s = @"\u00E9"; // é  
	NSString *t = @"e\u0301"; // e + ´
	BOOL isEqual = [s isEqualToString:t];
	NSLog(@"%@ is %@ to %@", s, isEqual ? @"equal" : @"not equal", t);  
	// => é is not equal to é

	// Normalizing to form C  
	NSString *sNorm = [s precomposedStringWithCanonicalMapping];  
	NSString *tNorm = [t precomposedStringWithCanonicalMapping];  
	BOOL isEqualNorm = [sNorm isEqualToString:tNorm];  
	NSLog(@"%@ is %@ to %@", sNorm, isEqualNorm ? @"equal" : @"not equal", tNorm);  
	// => é is equal to é

另一个选择是使用 [`compare:`](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/compare:) 方法（或者它的其它变形方法，比如：[`localizedCompare:`](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/localizedCompare:)），这个方法返回一个和它相容等价的字符串。对此，苹果没有很好地写入文档。请注意，你常常还需要作标准等价的比较。`compare:` 没法作这个比较。

	NSString *s = @"ff"; // ff  
	NSString *t = @"\uFB00"; // ﬀ ligature  
	NSComparisonResult result = [s localizedCompare:t];  
	NSLog(@"%@ is %@ to %@", s, result == NSOrderedSame ? @"equal" : @"not equal", t);  
	// => ff is equal to ﬀ

如果你只想用 `compare:` 比较而不考虑等价关系，[`compare:options`](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/compare:options:) 这个方法变体可以让你指定 `NSLiteralSearch` 作为参数，这能让比较更快。

#### 从文件或网络读取文本

总地来说，只有当你知道文本所用的编码时文本数据才是有用的。当从服务器下载文本数据时，通常你都知道或者可以从 HTTP 的头文件中得知编码类型。之后，再用 `-[NSString initWithData:encoding:]` 这个方法创建字符串对象就很简单了。

> <span class="secondary radius label">编者注</span> 这一段和下一段的这两个 `NSString` 的方法均为实例方法而非类方法，即应该先 `alloc` 后再调用，原文这样写估计只是为了简洁，请读者知会。

虽然文本文件本身并不包含编码信息，但 `NSString` 常常可以通过查看**扩展文件属性**（extended file attributes）或者通过规律进行试探性的猜测的方法（比如，一个有效的 UTF-8 文件里就不会出现某些特定的二进制序列）来确定文件的编码。可以使用 [`-[NSString initWithContentsOfURL:encoding:error:]`](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/) 这个方法，来从编码已知的文件里读取文本。要读取编码未知的文件，苹果提出了以下原则：

>如果你不得不猜测文件的编码（注意，没有明确信息，就只有猜测）：

>1. 试试这两个方法：`stringWithContentsOfFile:usedEncoding:error: ` 或者 `initWithContentsOfFile:usedEncoding:error: ` （或者这两个方法参数为 URL 的等价方法）。  
这些方法会尝试猜测资源的编码，如果猜测成功，会以引用的形式带回所用的编码。
>2. 如果 1 失败了，试着用 UTF-8 读取资源。
>3. 如果 2 失败了，试试合适的老的编码。  
这里「合适的」取决于具体情况。它可以是默认的 C 语言字符串编码，也可以是 ISO 或者 Windows Latin 1 编码，亦或者是其它的，取决于你的数据来源。  
>4. 最终，还可以试试 Application Kit 里 `NSAttributedString` 类的载入方法（比如：`initWithFileURL:options:documentAttributes:error:`）。这些方法会尝试纯文本文件，然后返回使用的编码。可以用这些方法打开任意的文档。如果你的程序并不是专业处理文本的程序，这些方法也值得考虑。对于 Foundation 级别的工具，或者不是自然语言的文本来说，这些方法可能不太合适。  

> <span class="secondary radius label">编者注</span> 第 4 条中 `NSAttributedString` 的方法名原文拼写有误，本译文已更正。

#### 把文本写入文件

我已经提到过，纯文本文件，和文件格式或者网络协议应该选择 UTF-8 编码，除非有特别的需要只能用其它的编码。要向文件中写入文本，使用
[`writeToURL:atomically:encoding:error:`](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/writeToURL:atomically:encoding:error:)
这个方法。

这个方法会在 UTF-16 或 UTF-32 编码的文件上自动加上字节顺序标记。它还会把文件的编码存储在名为 `com.apple.TextEncoding` 的[扩展文件属性](http://nshipster.com/extended-file-attributes/)里。鉴于 `initWithContentsOf…: usedEncoding:error:` 方法知道有这个属性，当你从文件里载入文本时，使用标准的 `NSString` 方法就能让确保使用正确的编码更加容易。

## 结语

文本很复杂。尽管 Unicode 已经极大地改善了软件处理文本的方式，程序员还是需要了解其中的运作机制以便能正确处理它。今天，几乎每一个应用都要处理多文种文本。即使你的应用不需要为中文或阿拉伯文做本地化，只要有**任何一处**需要用户进行输入，你还是得和 Unicode 的整个机制打交道。

你可以用全世界的语言来作完整的字符串处理测试，这意味着你需要测试输入为非英语的情况。确保在你的单元测试里用大量的 emoji 和 非拉丁文字作为测试用例。如果你不知道怎么输入某种文字，维基百科可以帮助你。这里有[各种语言版本的维基百科](http://meta.wikimedia.org/wiki/List_of_Wikipedias)，选择某种语言，随机选取一篇文章，拷贝里面的一些字词，然后尽情地测试吧。


## 扩展阅读

*   Joel Spolsky: [关于 Unicode 和字符集，每个程序员绝对、必须要了解的一点内容](http://www.joelonsoftware.com/articles/Unicode.html)。这篇文章已经有 10 年了，而且不仅限于 Cocoa 编程，但是值得一读。
*   [Ross Carter](https://twitter.com/RossT) 在 2012 年 NSCoference 上做了一次名叫「[你也可以讲 Unicode](https://vimeo.com/86030221)」 的精彩演讲。演讲很有意思，强烈推荐观看。这篇文章的一部分就是基于 Ross 的演讲稿的。[NSConference](http://nsconference.com/) 的 Scotty 人很好，让 objc.io 的读者可以观看这次视频。谢了！
*   [维基百科上关于 Unicode 的文章](http://en.wikipedia.org/wiki/Unicode)很棒。
*   [unicode.org](http://unicode.org) 是 Unicode 联盟的官网，上面不仅有完整的标准和码表索引，还有其它很有意思的信息。扩展部分 [FAQ](http://www.unicode.org/faq/) 也很棒。


[^1]: 最新的 6.3.0 版本的 Unicode 标准支持 100 种文字和 15 种符号集，比如数学符号和麻将牌。在还没有提供支持的文字中，有 12 种「仍有人使用的文字」以及 31 种「古老的」或者「已经消亡的」文字。

[^2]: 如今，Unicode 编码了超过 70,000 个统一的中日韩文字（CJK），单单这些文字就已经远远超过了 16 位所提供的空间。

[^3]: 就连用其它文字写成的文档里也会包含大量这个范围里的字符。假设有一个 HTML 文档，它的内容全部是中文，但这个文档的字符里仍将有极大的比例是由 HTML 标记、CSS 样式、Javascript 代码、空格、换行符等组成的。

[^4]: 我（原文作者，下同）在 2012 年的一篇博文里质疑了[让 UTF-8 兼容 ASCII 的决定是否正确](http://oleb.net/blog/2012/09/utf-8/)。事实上，我现在知道了，UTF-8 的核心目标之一就是这个兼容性，以明确避免与不支持 Unicode 的文件系统之间的问题。不过我还是觉得太多的向前兼容最后往往会成为累赘，因为即使在今天，这个特性仍然会把一些漏洞掩盖在没有充分测试的处理 Unicode 的代码里。

[^5]: UTF-8 最初是设计用来编码最长达 31 位的码点的，而这需要最多达 6 字节的序列。后来为了遵守 UTF-16 的约束，将它限制到了 21 位。现在，最长的 UTF-8 字节序列是 4 字节的。

---

 

原文 [NSString and Unicode](http://www.objc.io/issue-9/unicode.html)

译文 [NSString & Unicode - 没名儿呢 - 知乎专栏](http://zhuanlan.zhihu.com/cbbcd/19687727)
