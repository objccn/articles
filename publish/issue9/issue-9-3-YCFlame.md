一个应用在进行多语言本地化的时候涉及到大量的工作。因为这一期的主题是字符串，所以本文主要探讨字符串的本地化。字符串本地化有两种方法：修改代码或修改 nib 文件和 storyboard。本文将专注于通过代码实现字符串的本地化。

## NSLocalizedString

`NSLocalizedString` 这个宏是字符串本地化的核心工具。它还有三个鲜为人知的变体：`NSLocalizedStringFromTable`、`NSLocalizedStringFromTableInBundle` 和 `NSLocalizedStringWithDefaultValue`。这些宏最终都调用 `NSBundle` 的 `localizedStringForKey:value:table:` 方法来完成任务。

使用这些宏有两个好处：一方面相比直接调用 `localizedStringForKey:value:table:` 方法，使用宏让代码简单易懂；另一方面，类似 [genstrings](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/genstrings.1.html) 这样的工具能够监测到这些宏，从而生成供你翻译使用的字符串文件。这些工具会解析 .c 和 .m 后缀的文件，然后为其中每一个需要进行本地化的字符串都生成对应条目，并写入到生成的 .strings 文件中。

如果想让 `genstrings` 检测自己项目中所有的 `.m` 后缀文件，可以执行如下命令：

```
find . -name *.m | xargs genstrings -o en.lproj
```

`-o` 选项指定了生成字符串文件的存放目录，默认情况下文件名是 `Localizable.strings`。需要注意的是，`genstrings` 默认会覆盖已存在的同名字符串文件。`-a` 选项可以让 `genstrings` 将生成的条目追加到已存在同名文件的末尾，而不会覆盖原文件。

不过一般情况下你也许想将生成文件放到另一个目录中，然后使用你喜欢的合并工具将它们与已有文件合并以保留已翻译好的条目。

字符串文件的格式非常简单，都是键值对的形式：

```
/* Insert new contact button */
"contact-editor.insert-new-contact-button" = "Insert contact";
/* Delete contact button */
"contact-editor.delete-contact-button" = "Delete contact";
```

更复杂的操作比如在需要本地化的字符串中插入格式化占位符等，我们将在稍后谈到。

另外，字符串文件现在可以[保存成 UTF-8 格式](http://gigliwood.com/blog/to-hell-with-utf-16-strings.html)了，因为 Xcode 在构建过程中能够将它们转换成所需的 UTF-16 格式。

### 应用中哪些字符串需要本地化？

一般而言，所有你想以某种形式展现在用户眼前的字符串都需要本地化，包括标签和按钮上的文本，或者在运行时通过格式化字符串和数据动态生成的字符串。

在本地化字符串时，根据语法规则为每一种类型的语句定义一个可本地化的字符串是非常重要的。假设你在应用中需要显示「Paul invited you」和「You invited Paul」，那么只本地化格式化字符串「%@ invited %@」看起来是个不错的选择，这样在合适的时候把「you」本地化之后插入进去就可以完成任务。

在英语中这种做法没什么问题，但是请谨记，当把这种小伎俩应用到其他语言中时基本都会以失败而告终。以德语为例，「Paul invited you」译为「Paul hat dich eingeladen」，而「You invited Paul」则译为「Du hast Paul eingeladen」。

正确的做法是定义两个可本地化字符串「%@ invited you」和「You invited %@」，只有这样翻译器才能正确处理其他语言的特殊语法规则。

永远不要将句子分解为几个部分，而要将它们作为一个完整的可本地化字符串。如果一个句子与另一个句子的语法规则并不完全一致，那么即使它们在你的母语中看起来极为相像，也要创建两个可本地化字符串。

### 字符串键值最佳实践

使用 `NSLocalizedString` 宏的时候，第一个参数就是为每个特殊字符串指定的**键值（key）**。程序员经常使用母语中的单词作为键值，这样乍一看是个便利的方案，但是实际上相当糟糕，会引发非常严重的错误。

在一个字符串文件中，键值需要具有唯一性，因此任何母语中字面上具有唯一性的单词在翻译为其他语言的时候也必须具有唯一性。这一点是无法满足的，因为一个单词翻译为其他语言时经常会有多种意思，需要对应到多种文字表示。

以英文单词「run」为例，作为名词表示「跑步」，作为动词表示「奔跑」，在翻译的时候要加以区别。而且根据上下文的不同，每种具体的译法在文字上可能还会有细微变化。

一个健身应用在不同的地方用到这个单词的不同意思是很正常的，但是如果你使用下面的方法来进行本地化：

```
NSLocalizedString(@"Run", nil)
```
无论第二个参数指定了注释内容还是留空，你在字符串文件中都只有一个「run」的条目。而在德语中，「run」作名词时应该译为「Lauf」，作动词时则应该译为「laufen」，或者在特定情况下译为完全不同的形式比如「loslaufen」和「Los geht’s」。

好的键值应该满足两个条件：首先键值必须在每个具体的上下文中保持唯一性，其次如果我们没有翻译特定的那个上下文，那么它们不会被其他情况覆盖到而被翻译。

本文推荐使用如下的命名空间方法：

```
NSLocalizedString(@"activity-profile.title.the-run", nil)
NSLocalizedString(@"home.button.start-run", nil)
```

这样的键值可以区分应用中不同地方出现的单词，同时提供具体的上下文，比如是标题中的或者按钮中的。上面的例子里我们为了简便忽略了第二个参数，实际使用中如果键值本身没有提供清晰的上下文说明，你可以将进一步的说明作为第二个参数传入。同时请确保键值中只含有 [ASCII](http://en.wikipedia.org/wiki/ASCII) 字符。

### 分割字符串文件

正如我们一开始提到的，`NSLocalizedString` 有一些变体能够提供更多字符串本地化的操作方式。`NSLocalizedStringFromTable` 接收 key、table 和 comment 这三个参数，其中 table 参数表示该字符串对应的一个表格，`genstrings` 会为表中的每一个条目生成一个以条目名称（假设为 table-item）命名的独立字符串文件 `table-item.strings`。

这样你就可以把字符串文件分割成几个小一些的文件。在一个庞大的项目或者团队中工作时，这一点显得尤为重要。同时这也让合并原有的和重新生成的字符串文件变得容易一些。

相比在每个地方调用下面的语句：

```
NSLocalizedStringFromTable(@"home.button.start-run", @"ActivityTracker", @"some comment..")
```
你可以自定义一个用于字符串本地化的函数来让工作变得轻松一些

```
static NSString * LocalizedActivityTrackerString(NSString *key, NSString *comment) {
    return [[NSBundle mainBundle] localizedStringForKey:key value:key table:@"ActivityTracker"];
}
```

为了给所有调用此函数的地方生成字符串文件，你可以在执行 `genstrings` 的时候加上 `-s` 选项：

```
find . -name *.m | xargs genstrings -o en.lproj -s LocalizedActivityTrackerString
```
`-s` 这个选项指定了本地化函数的共同前缀名称，如果你还定义了 `LocalizedActivityTrackerStringFromTable`，`LocalizedActivityTrackerStringFromTableInBundle`， `LocalizedActivityTrackerStringWithDefaultValue` 等函数，以上命令也会调用它们。

<a name="localized-format-strings"> </a>
### 运用格式化字符串

我们经常需要对一些在运行时才能最终确定下来的字符串进行本地化，格式化字符串可以完成这项工作。Foundation 在这方面提供了一些非常强大的特性。（可以参考[Daniel 的文章](http://www.objccn.io/issue-9-2)获得更多关于格式化字符串的细节）

以字符串「Run 1 out of 3 completed.」为例，我们可以这样构造格式化字符串:

```
NSString *localizedString = NSLocalizedString(@"activity-profile.label.run %lu out of %lu completed", nil);
self.label.text = [NSString localizedStringWithFormat:localizedString, completedRuns, totalRuns];
```
在翻译的时候经常需要对其中的格式化占位符进行顺序调整以符合语法，幸运的是我们可以在字符串文件中轻松地搞定：

```
"activity-profile.label.run %lu out of %lu completed" = "Von %2$lu Läufen hast du %1$lu absolviert";
```

上面的德文翻译得不是非常好，只是单纯用来说明调换占位符顺序的功能而已。

如果你需要对简单的整数或者浮点数进行本地化，你可以使用 `localizedStringWithFormat:` 这个变体。数字本地化的更高级用法涉及 `NSNumberFormatter`，会在本文后面讲到。

### 单复数与阴阳性

在 OS X 10.9 和 iOS 7 中，本地化字符串的时候可以使用比替换格式化字符串中的占位符更酷的特性：苹果官方想处理不同语言中对于名词复数和不同性别采取的不同变化。

让我们再看一下之前的例子：@”%lu out of %lu runs completed.” 这个翻译在「跑多次」的时候才是对的（译者注：即第二个 %lu 代表的数字大于 1），所以我们不得不定义两个不同的字符串来处理单次和多次的情况：

```
@"%lu out of one run completed"
@"%lu out of %lu runs completed"
```

这种做法在英语中是对的，但是在其他很多语言中会出错。比如希伯来语中名词有三种形式：第一种是单数和十的倍数，第二种是 2，第三种是其他的复数。克罗地亚语中，个位数为 1 的数字有单独的表示方法：「31 od 32 staze završene」，与之相对的是「5 od 8 staza završene」（注意其中「staze」和「staza」的差别）。很多语言针对非整型数也有不同的表达方式。

想全面了解这个问题可以参见[基于 Unicode 的语言复数规则](http://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html)。其中涵盖的变化之博大精深令人叹为观止。

为了在 10.9 和 iOS 7 平台上正确处理这个问题，我们需要如下构造可本地化字符串：

```
[NSString localizedStringWithFormat:NSLocalizedString(@"activity-profile.label.%lu out of %lu runs completed"), completedRuns, totalRuns];
```

然后我们在 `.strings` 后缀文件所处目录中创建一个同名的 `.stringsdict` 后缀的文件，如果前者名为 `Localizable.strings`，则后者为 `Localizable.stringsdict`。保留 `.strings` 后缀的字符串文件是必须的，即使它里面什么内容也没有。这个 `.stringsdict` 后缀的字符串字典文件是一个属性列表（`plist`）文件，比字符串文件复杂得多，换来的是正确处理所有语言的名词复数问题，而不需要将处理逻辑写在代码中。

下面是一个该文件的例子：

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>activity-profile.label.%lu out of %lu runs completed</key>
    <dict>
        <key>NSStringLocalizedFormatKey</key>
        <string>%lu out of %#@lu_total_runs@ completed</string>
        <key>lu_total_runs</key>
        <dict>
            <key>NSStringFormatSpecTypeKey</key>
            <string>NSStringPluralRuleType</string>
            <key>NSStringFormatValueTypeKey</key>
            <string>lu</string>
            <key>one</key>
            <string>%lu run</string>
            <key>other</key>
            <string>%lu runs</string>
        </dict>
    </dict>
</dict>
</plist>
```
顶层字典的键值即为待翻译的字符串（即 `activity-profile.label.%lu out of %lu runs completed` ），在下层字典中又指定了 `NSStringLocalizedFormatKey` 所需的格式化字符串。为了将不同的占位符替换为不同的数字，必须扩展格式化字符串的语法。所以我们可以定义类似 `%#@lu_total_runs@` 的格式化字符串，然后定义一个字典来解析它。在上面的字典中，我们通过将 `NSStringFormatSpecTypeKey` 设置为 `NSStringPluralRuleType` 表明这是一个处理名词复数的规则，指定了值的类型（在本例中是 lu，即无符号长整数），还定义了针对不同复数形式的不同输出（可以从「zero」、「one」、「few」、「many」和「others」中选择，上例中仅制定了「one」和「other」）。

这是一个非常强大的特性，不但可以处理其他语言中多种复数形式的问题，还可以为不同的数字定制不同的字面表示。

我们还可以更进一步定义递归的规则。为了让上面例子的输出更友好，我们需要覆盖如下几种自定义的字符串用例：

```
Completed runs    Total Runs    Output
------------------------------------------------------------------
0                 0+            No runs completed yet
1                 1             One run completed
1                 2+            One of x runs completed
2+                2+            x of y runs completed
```
我们可以通过字符串字典后缀文件来处理以上四种情况，而无需修改代码逻辑，如下所示：

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>scope.%lu out of %lu runs</key>
    <dict>
        <key>NSStringLocalizedFormatKey</key>
        <string>%1$#@lu_completed_runs@</string>
        <key>lu_completed_runs</key>
        <dict>
            <key>NSStringFormatSpecTypeKey</key>
            <string>NSStringPluralRuleType</string>
            <key>NSStringFormatValueTypeKey</key>
            <string>lu</string>
            <key>zero</key>
            <string>No runs completed yet</string>
            <key>one</key>
            <string>One %2$#@lu_total_runs@</string>
            <key>other</key>
            <string>%lu %2$#@lu_total_runs@</string>
        </dict>
        <key>lu_total_runs</key>
        <dict>
            <key>NSStringFormatSpecTypeKey</key>
            <string>NSStringPluralRuleType</string>
            <key>NSStringFormatValueTypeKey</key>
            <string>lu</string>
            <key>one</key>
            <string>run completed</string>
            <key>other</key>
            <string>of %lu runs completed</string>
        </dict>
    </dict>
</dict>
</plist>
```
调用 `localizedStringForKey:value:table:` 会返回根据字符串字典文件中的键值对进行初始化的字符串集合，这些字符串都是包含字符串字典文件中信息的的**代理对象（proxy objects）**。这些信息在调用 `copy` 和 `mutableCopy` 进行字符串拷贝的时候会被保留，但是一旦你修改了该字符串，这些额外信息就会丢失。更多细节请参见 OS X 10.9 的 [Foundation 发行说明](https://developer.apple.com/library/Mac/releasenotes/Foundation/RN-Foundation/index.html)。

## 字母大小写

如果你要修改一个用户可见字符串的大小写，请一定使用包含本地化功能的 `NSString` 方法变体：`lowercaseStringWithLocale:` 和 `uppercaseStringWithLocale:`。

调用这些方法的时候你需要传入区域设置参数 [locale](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSLocale_Class/Reference/Reference.html) ，这样就可以将大小写的改变应用到本地化之后的其他语言版本中。当你使用 `NSLocalizedString` 及其变体的那些宏时无须担心本地化后的大小写问题，因为在方法内部已经自动做了处理，而且在用户选择的语言不可用时会使用默认语言来代替。

为了用户界面的一致性，使用**区域设置（locale）**来本地化界面的其他部分是一个很好的方法，可以参见后面的小节[「选择正确的区域设置」](#choosing-the-right-locale)。

## 文件路径的本地化

一般而言你应该始终用 `NSURL` 来表现文件路径，因为这会让文件名的本地化变得容易：

```
NSURL *url = [NSURL fileURLWithPath:@"/Applications/System Preferences.app"];
NSString *name;
[url getResourceValue:&name forKey:NSURLLocalizedTypeDescriptionKey error:NULL];
NSLog(@"localized name: %@", name);

// output: System Preferences.app
```
以上输出在英语系统中是正确的，但是假设我们换到了阿拉伯语系统中，系统设置被称为「تفضيلات النظام.app」。

构造这样一个其他语言的文件名是否包含后缀需要参照用户 Finder 中的相关选项。如果你需要获取文件的类型，也可以这样调用 `NSURLLocalizedTypeDescriptionKey` 来从中获得。

本地化之后的文件名仅供显示使用，不能用来访问实际的文件资源，可以参考 [Daniel 关于常见字符串模式的文章](http://www.objccn.io/issue-9-2/) 以获取更多关于路径的细节。

## 格式器

在不同的语言中，数字和日期被表现为各种形式。幸好苹果官方已经提供了处理这些问题的方法，所以我们只需要使用 [NSNumberFormatter](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/Classes/NSNumberFormatter_Class/Reference/Reference.html) or [NSDateFormatter](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSDateFormatter_Class/Reference/Reference.html) 类来显示用户界面中的数字和日期即可。

请记住数字和日期的格式器是可变对象，因此并不线程安全。

### 格式化数字

数字格式器对象有很多配置选项，但大多数情况下你只要使用一种定义好的数字格式就好。毕竟使用数字格式器的原因就是不必再担心其他语言中特定的数字格式。

对于数字 `2.5`，在本文作者的机器上使用不同的格式器会得到不同的输出：

```
数字类型                              德语结果                      阿拉伯语结果
------------------------------------------------------------------------------------------------------
NSNumberFormatterNoStyle             2                             ٢
NSNumberFormatterDecimalStyle        2,5                           ٢٫٥
NSNumberFormatterCurrencyStyle       2,50 €                        ٢٫٥٠٠ د.أ.
NSNumberFormatterScientificStyle     2,5E0                         ٢٫٥اس٠
NSNumberFormatterPercentStyle        250 %                         ٢٥٠٪
NSNumberFormatterSpellOutStyle       zwei Komma fünf               إثنان فاصل خمسة
```

在上表中数字格式器的一个很好的特性无法直观地表现出来：在货币和百分数形式中，货币单位和百分号前面插入的不是一个普通空格，而是一个[不换行空格](http://zh.wikipedia.org/zh-cn/%E4%B8%8D%E6%8D%A2%E8%A1%8C%E7%A9%BA%E6%A0%BC)，因此实际显示的时候数字和后面的符号不会被显示在两行中。（而且这种加空格的显示不是很酷吗？）

默认情况下格式器会使用系统设置中指定的区域设置。在「字母大小写」一节中我们已经说过，根据特定用户界面的特定要求为格式器指定正确的区域设置是非常重要的，在[后面的小节](#choosing-the-right-locale)会进一步讨论这一点。

### 格式化日期

与数字的格式化一样，日期的格式化也非常复杂，因此我们有必要让 `NSDateFormatter` 来负责这一点。使用日期格式器的时候你可以选择苹果官方提供的适用于所有区域设置的[不同日期和时间格式](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSDateFormatter_Class/Reference/Reference.html#//apple_ref/doc/c_ref/NSDateFormatterStyle)。再强调一遍，选择匹配界面其他元素的[正确区域设置](#choosing-the-right-locale)。

有时你想用一种 `NSDateFormatter` 默认不支持的格式来显示日期，这时不要使用简单的格式化字符串（这样做在应用到其他语言中时几乎肯定会出错），而要使用 `NSDateFormatter` 提供的 `dateFormatFromTemplate:options:locale:` 方法。

假设你想只显示天和月份的缩写，系统并没有提供这样的默认风格的。所以我们可以自定义格式器：

```
NSString *format = [NSDateFormatter dateFormatFromTemplate:@"dMMM"
                                                   options:0
                                                    locale:locale];
NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
[dateFormatter setDateFormat:format];
NSString *output = [dateFormatter stringFromDate:[NSDate date]];
NSLog(@"Today's day and month: %@", output);
```
相比使用格式化字符串，调用这个方法的一大好处就在于输出结果在其他语言中也肯定是正确的。举例来说，在美国英语中，我们期望输出「Feb 2」，而在德语中则应该输出「2. Feb」。`dateFormatFromTemplate:options:locale:` 方法使用我们指定的模板和区域设置来构造正确的输出结果，在美国英语中将模板变为「MMM d」，在德语中则变为「d. MMM」。

想要深入了解模板字符串中可以使用的占位符，可以参考[Unicode 格式的区域设置数据标记语言文档](http://www.unicode.org/reports/tr35/tr35-25.html#Date_Format_Patterns).

### 缓存格式器对象

因为创建格式器对象是一个非常消耗资源的操作，所以最好将它缓存起来以供之后使用：

```
static NSDateFormatter *formatter;

- (NSString *)displayDate:(NSDate *)date
{
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterNoStyle;
    }
    return [formatter stringFromDate:date];
}
```
这里有一个小的陷阱需要注意：如果用户修改了区域设置，我们就需要废弃这个缓存。因此我们需要使用 `NSCurrentLocaleDidChangeNotification` 注册一个通知事件：

```
static NSDateFormatter *formatter;

- (void)setup
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(localeDidChange)
                               name:NSCurrentLocaleDidChangeNotification
                             object:nil];
}

- (NSString *)displayDate:(NSDate *)date
{
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterNoStyle;
    }
    return [formatter stringFromDate:date];
}

- (void)localeDidChange
{
    formatter = nil;
}

- (void)dealloc
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self
                                  name:NSCurrentLocaleDidChangeNotification
                                object:nil];
}
```
苹果官方的[数据格式化指南](https://developer.apple.com/library/mac/documentation/cocoa/conceptual/DataFormatting/Articles/dfDateFormatting10_4.html#//apple_ref/doc/uid/TP40002369-SW10)中对此做了注解：

>理论上来说你应该使用自动更新的区域设置（`autoupdatingCurrentLocale`），这样就可以在用户做更改时生成对应的区域设置文件，但是这一招对日期格式器不适用。

所以我们不得不使用为区域设置的变更设置通知机制。相比格式化日期的那一小段代码，这一段有点长，但是如果你频繁使用日期格式器，这样做是值得的。始终牢记在权衡利弊之后再进行改进。

再次强调，格式器不是线程安全的。苹果官方文档中写道，你可以在多线程环境下使用格式器，但是不能有多个线程同时修改格式器。如果你想将用到的所有格式器集中在一个对象中，以便在区域设置更改时更方便地废弃缓存，你必须保证只使用一个队列存放它们从而依次创建和更新。比如你可以使用**并发队列（concurrent queue）**和 `dispatch_sync` 来获取格式器，在区域设置更改时使用 `dispatch_barrier_async` 来更新格式器。

### 解析用户输入数据

数字和日期格式器不止可以根据数字和日期对象生成可本地化字符串，还能以其他方式工作。每当你需要处理用户输入中的数字或日期时，都应该使用合适的格式器类来解析。这是唯一能够保证用户输入能够按照当前区域设置正确解析的方法。

### 解析机器生成数据

虽然格式器在处理用户输入时很好用，在已知格式的情况下处理机器生成的数据有更好的方法，因为为所有区域设置生成正确输出的数字和日期格式器有性能上的损失。

举例来说，如果你从服务器接收到很多日期字符串，在你将它们转换成日期对象时，日期格式器并不是最好的选择。苹果官方的[日期格式化指南](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/DataFormatting/Articles/dfDateFormatting10_4.html#//apple_ref/doc/uid/TP40002369-SW1)中提到对于这些固定格式且无需进行本地化的日期，使用 UNIX 提供的 `strptime_l(3)` 函数更高效：

```
struct tm sometime;
const char *formatString = "%Y-%m-%d %H:%M:%S %z";
(void) strptime_l("2014-02-07 12:00:00 -0700", formatString, &sometime, NULL);
NSLog(@"Issue #9 appeared on %@", [NSDate dateWithTimeIntervalSince1970: mktime(&sometime)]);
// Output: Issue #9 appeared on 2014-02-07 12:00:00 -0700
```
因为 `strptime_l` 函数也可以感知用户的区域设置，所以确保最后一个参数传入 `NULL` 以使用标准 POSIX 区域设置。函数中可用的占位符请参考 [strftime 用户手册](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man3/strftime.3.html#//apple_ref/doc/man/3/strftime)。


## 调试本地化字符串

应用支持的语言版本越多，确保所有元素都正确显示就越难。但是这里有一些默认的用户选项和工具可以减轻你的负担。

你可以使用 `NSDoubleLocalizedStrings`、`AppleTextDirection` 和 `NSForceRightToLeftWritingDirection` 选项保证你的布局不会因为长字符串或者从右往左读的语言而混乱。`NSShowNonLocalizedStrings` 和 `NSShowNonLocalizableStrings` 则可以帮助你找到没有翻译的字符串和根本没有制定字符串本地化宏的字符串。（所有这些工具的选项都可以通过程序设置或者作为 Xcode 的 Scheme 编辑器启动选项，如 `-NSShowNonLocalizedStrings YES`）

还有两个选项可以控制语言和区域设置：`AppleLanguages` 和 `AppleLocale`。你可以配置这两个选项让应用以不同于当前系统的语言或者区域设置启动，让你在测试时不用频繁对系统设置进行切换。`AppleLanguages` 选项接收符合 [ISO-639](http://www.loc.gov/standards/iso639-2/php/code_list.php) 标准的语言代码列表作为参数，如下所示：

```
-AppleLanguages (de, fr, en)
```
`AppleLocale` 则接收符合[Unicode 国际组件标准（International Components for Unicode）](http://userguide.icu-project.org/locale) 的区域设置标识符作为参数，如下：

```
-AppleLocale en_US
```
或

```
-AppleLocale en_GR
```
如果你翻译的字符串没有正确显示，你可以带上 `-lint` 选项运行 [plutil](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/plutil.1.html) 命令来检查一下字符串文件是否有语法错误。例如你在行尾漏写了分号，plutil 会输出如下警告：

```
$ plutil Localizable.strings
2014-02-04 15:22:40.395 plutil[92263:507] CFPropertyListCreateFromXMLData(): Old-style plist parser: missing semicolon in dictionary on line 6. Parsing will be abandoned. Break on _CFPropertyListMissingSemicolon to debug.
Localizable.strings: Unexpected character / at line 1
```
当我们修正了这个错误后，plutil 会告诉我们一切正常：

```
$ plutil Localizable.strings
Localizable.strings: OK
```
对于支持多种语言的应用，还有一个与调试无关的小技巧：你可以在 iOS 上自动生成应用在多种语言下的屏幕截图。因为可以使用 `UIAutomation` 来控制应用，使用 `AppleLanguages` 在启动时设置语言，所以整个测试过程可以自动化。[GitHub 上的这个项目](https://github.com/jonathanpenn/ui-screen-shooter)中可以找到更多细节。

<a name="choosing-the-right-locale"> </a>

## 选择正确的区域设置

在使用日期和数字格式器或者类似 `[NSString lowercaseStringWithLocale:]` 的方法调用时，确保你使用了正确的区域设置是很重要的。如果你想使用系统当前的区域设置，你可以使用 `[NSLocale currentLocale]` 获得，但是要注意这不一定与你的应用实际运行时使用的相同。

假设用户的系统是中文的，但是你的应用只支持英语、德语、西班牙语和法语。这种情况下字符串本地化会使用默认的英语来进行，如果你现在使用 `[NSLocale currentLocale]` 或者使用 `[NSNumberFormatter localizedStringFromNumber:numberStyle:]` 这种未指定区域设置的格式器类，那么这些数据会根据中文的区域设置来进行格式化，而界面上的其他字符串则都是英语。

最终需要你来决定特定情况下什么最重要，但是你会想要应用的界面在一些情况下保持一致。为了获取应用实际使用的而非当前系统的区域设置，我们必须获取 `mainBundle` 中的语言属性来构造区域设置：

```
NSString *localization = [NSBundle mainBundle].preferredLocalizations.firstObject;
NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:localization];
```
在这样的区域设置下，我们可以将日期格式化为与界面其他元素一致的形式：

```
NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
formatter.locale = locale;
formatter.dateStyle = NSDateFormatterShortStyle;
formatter.timeStyle = NSDateFormatterNoStyle;
NSString *localizedDate = [formatter stringFromDate:[NSDate date]];
```

## 结论

任何适用于自己母语的规律都不一定适用于其他语言，在本地化字符串时要牢记这一点。众多框架提供了很多强大的工具将不同语言的复杂性抽象出来，我们只需要一以贯之地运用它们。这会带来一些额外的工作，但是会为你在制作自己应用的其他语言版本时节约大量的时间。

---

 
 
原文 [String Localization](http://www.objc.io/issue-9/string-localization.html)

译文 [objc.io 第9期之字符串的本地化 - iOS init](http://iosinit.com/?p=1097)