在几乎每一种计算机程序语言中，解析字符串都是我们不得不面对的问题。有时这些字符串以一种简单的格式出现，有时它们又变得很复杂。我们将利用多种方法把字符串转换成我们需要的东西。下面，我们将讨论正则表达式、扫描器、解析器以及在什么时候使用它们。

### 正则法 vs. 上下文无关文法（Context-Free Grammars）

首先，介绍一点点背景知识：解析一个字符串，其实就是用特定的语言来描述它。例如：把 `@"42"` 解析成数字，我们会采用自然数来描述这个字符串。*语言*都是用语法来描述的，语法其实就是一些规则的集合，这些规则可以用字符串来描述。比如自然数，仅仅有一条规则：字符串的描述就是一个数字序列。这种语言也可以用标准 C 函数或者正则表达式来描述。如果我们用正则表达式来描述一种语言，我们就可以说它有*正则语法*。

假设我们有一个表达式："1 + 2 * 3"，解析它就不容易。像这种表达式，我们可以用归纳语法来描述。换句话说，就是有一种语法，它的规则就是指的是它们自己，有时候甚至是递归的方式。为了识别这种语法，我们有三个规则：

1. 任何数字都是语言的成员。
1. 如果 `x` 是语言的成员，同时 `y` 也是语言的成员，那么 `x+y` 也是语言的成员。
1. 如果 `x` 是语言的成员，同时 `y` 也是语言的成员，那么 `x*y` 也是语言的成员。

使用这种语法描述的语言称之为**上下文无关文法 (context-free grammars)**，或者简称 CFG [1]。需要注意的是这种语法不能使用正则表达式来解析（虽然一些正则表达式能实现，如 PCRE，但这远远超越了一般的正则语法）。一个经典的例子就是括号匹配，它可以用 CFG 来解析，却不能用正则表达式 [2]。

[1]: http://en.wikipedia.org/wiki/Chomsky_hierarchy
[2]: http://en.wikipedia.org/wiki/Context-free_grammar#Well-formed_parentheses

像数字，字符串和时间这些，就可以用正则语言来解析。意思是说你可以使用正则表达式（或者相似的技术）去解析它们。

像[邮箱地址][4]，JSON，XML 以及其它大多数的编程语言，都不能够使用正则表达式来解析 [3]。我们需要一个真正的解析器来解析它们。大多数时候，我们需要的解析器就有现成的。苹果就已经为我们提供了 XML 和 JSON 解析器，如果想要解析 XML 和 JSON，用苹果的就可以了。

[3]: http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx/
[4]: http://www.ex-parrot.com/~pdw/Mail-RFC822-Address.html

## 正则表达式

当你想要去识别一些简单的语言时，正则表达式是一个好工具。但是，它们经常被滥用在一些不适合它们的地方，比如 HTML 的解析。现在假定我们有一个文件, 其中包含一个简单的定义颜色的变量,设计者们可以利用该变量来改变你 iPhone app 中的颜色。格式如下:

	backgroundColor = #ff0000

想要解析这种格式，我们就可以用正则表达式。正则表达式中最重要的是**模式（`pattern`）**。如果你不知道什么是正则表达式，我们将很快的重新温习一下，但是完全的解释什么是正则表达式已经超出了这篇文章的范围。首先，我们来看一下 `\\w+`, 它的意思是匹配任何一个数字、字母或者是下划线至少一次（`\\w` 代表匹配任意一个数字、字母或者是下划线，`+` 代表至少匹配一次）。然后，为了确保我们以后可以使用匹配的结果，需要用括号将它括起来，创建一个**捕获组（capture group）**。接下来是一个空格符，一个等号，又一个空格符和一个 # 号。然后，我们需要匹配 6 个十六进制数字。`\\p{Hex_Digit}` 意思是匹配一个十六进制数字（`Hex_Digit` 是一个 [unicode 属性名](http://en.wikipedia.org/wiki/Unicode_character_property#Hexadecimal_digits)）。修饰符 `{6}` 意味着我们需要匹配 6 个，然后和之前一样，把这些一起用括号括起来，这样就创建了第二个捕获组:

    NSError *error = nil;
    NSString *pattern = @"(\\w+) = #(\\p{Hex_Digit}{6})";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                options:0
                                                                                  error:&error];
    NSTextCheckingResult *result = [expression firstMatchInString:string 
                                                          options:0
                                                            range:NSMakeRange(0, string.length)];
    NSString *key = [string substringWithRange:[result rangeAtIndex:1]];
    NSString *value = [string substringWithRange:[result rangeAtIndex:2]];
    
上面我们创建了一个正则表达式对象，让它匹配一个字符串对象 `string`，通过 `rangeAtIndex` 方法可以获取用括号捕获的两组数据。在匹配的结果对象中，索引 0 是正则表达式对象自己，索引 1 是第一个捕获组，索引 2 是第二个捕获组，依此类推。最后，我们获取到的 `key` 的值是 `backgroundColor`，`value` 的值是 `ff0000`。上面的正则表达式只解析了一行，下一步我们将要解析多行，并添加一些错误检查。比如，输入如下：

	backgroundColor = #ff0000
	textColor = #0000ff

首先，利用换行符将输入字符串分隔开，然后遍历返回的数组，并将解析的结果添加到我们的字典中，最后我们将生成这样一个字典：`@{@"backgroundColor": @"ff0000", @"textColor": @"0000ff"}`。下面是具体的代码：

    NSString *pattern = @"(\\w+) = #([\\da-f]{6})";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                options:0 
                                                                                  error:NULL];
    NSArray *lines = [input componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (NSString *line in lines) {
        NSTextCheckingResult *textCheckingResult = [expression firstMatchInString:line 
                                                                          options:0 
                                                                            range:NSMakeRange(0, line.length)];
        NSString* key = [line substringWithRange:[textCheckingResult rangeAtIndex:1]];
        NSString* value = [line substringWithRange:[textCheckingResult rangeAtIndex:2]];
        result[key] = value;
    }
    return result;
    
说句题外话，将字符串分解成数组，你还可以用 `componentsSeparatedByString:` 这个方法，或者用 `enumerateSubstringsInRange:options:usingBlock:` 这个方法来枚举子串，其中 option 这个参数应该传 `NSStringEnumerationByLines`。

假如某一行数据没有匹配上（比如，我们不小心忘记一个十六进制字符），我们可以检查 `textCheckingResult` 对象是否为 nil，如果为 nil，就抛出一个错误，代码如下：

     if (!textCheckingResult) {
         NSString* message = [NSString stringWithFormat:@"Couldn't parse line: %@", line]
         NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: message};
         *error = [NSError errorWithDomain:MyErrorDomain code:FormatError userInfo:errorDetail];
         return nil;
     }
     
## 扫描器（Scanner）

把一个字符串转化为一个字典，还有一种方式就是使用扫描器。幸运的是，Foundation 框架为我们提供了 `NSScanner`，一个易于使用的面向对象的API。首先，我们需要创建一个扫描器：

	NSScanner *scanner = [NSScanner scannerWithString:string];

默认情况下，扫描器会跳过所有空格符和换行符。但这里我们只希望跳过空格符：

	scanner.charactersToBeSkipped = [NSCharacterSet whitespaceCharacterSet];

然后,我们定义一个十六进制字符集。系统定义了很多字符集，但却没有十六进制字符集：

    NSCharacterSet *hexadecimalCharacterSet = 
      [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
      
我们先写一个没有错误检查的版本。扫描器的工作原理是这样的：它接收一个字符串，并将光标设置在字符串的开始处。然后调用扫描方法，像这样：`[sanner scanString:@"=" intoString:NULL]`。如果扫描成功，该方法会返回 `YES`，光标会自动后移。`scanCharactersFromSet:intoString:` 方法的工作原理和之前的相似，只不过它扫描的是字符集，并将扫描的结果放入第二个参数的字符串指针所指向的地址中。我们使用 `&&` 对不同的扫描方法进行 “与” 操作。这种方式的好处是只有与 `&&` 操作符左边的扫描成功时，`&&` 右边的扫描方法才会被调用。

    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    while (!scanner.isAtEnd) {
        NSString *key = nil;
        NSString *value = nil;
        NSCharacterSet *letters = [NSCharacterSet letterCharacterSet];
        BOOL didScan = [scanner scanCharactersFromSet:letters intoString:&key] &&
                       [scanner scanString:@"=" intoString:NULL] &&
                       [scanner scanString:@"#" intoString:NULL] &&
                       [scanner scanCharactersFromSet:hexadecimalCharacterSet intoString:&value] &&
                       value.length == 6;
        result[key] = value;
        [scanner scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] 
                            intoString:NULL]; // 继续扫描下一行
    }
    return result;

接下来添加一个有错误处理的版本，我们可以在 `didScan` 该行后面开始写。如果扫描不成功，我们就返回 nil，并设置相应的 `error` 参数。在解析文本时，当输入字符串格式不正确时，这个时候应该怎么办呢？是让解析器崩溃，将错误值呈现给用户，还是尝试从错误中恢复，这值得我们仔细地思考清楚：

        if (!didScan) {
            NSString *message = [NSString stringWithFormat:@"Couldn't parse: %u", scanner.scanLocation];
            NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: message};
            *error = [NSError errorWithDomain:MyErrorDomain code:FormatError userInfo:errorDetail];
            return nil;
        }
        
C 语言也提供了具有扫描器功能的函数,例如 `sscanf`（可以用 `man sscanf` 查看怎么使用）。它遵循和 `printf` 类似的语法，只不过操作是逆序的（它是解析一个字符串, 而不是生成一个）。

## 解析器

如果设计者希望像 `(100,0,255)` 这样来定义 RGB 颜色，该怎么办呢？我们必须让解析颜色的方法更智能一些。事实上，在完成后面的代码后，我们就已经会写一个基本的解析器了。

首先，我们将添加一些方法到我们类中，并声明一个属性，类型为 `NSScanner`。第一个方法是 `scanColor:`，其作用是扫描十六进制的颜色值（例如 `ff0000`）或者 RGB 元组，例如`(255,0,0)`：

	- (NSDictionary *)parse:(NSString *)string error:(NSError **)error
	{
	    self.scanner = [NSScanner scannerWithString:string];
	    self.scanner.charactersToBeSkipped = [NSCharacterSet whitespaceCharacterSet];
	    
	    NSMutableDictionary *result = [NSMutableDictionary dictionary];
	    NSCharacterSet *letters = [NSCharacterSet letterCharacterSet]
	    while (!self.scanner.isAtEnd) {
	        NSString *key = nil;
	        UIColor *value = nil;
	        BOOL didScan = [self.scanner scanCharactersFromSet:letters intoString:&key] &&
	                       [self.scanner scanString:@"=" intoString:NULL] &&
	                       [self scanColor:&value];
	        result[key] = value;
	        [self.scanner scanCharactersFromSet:[NSCharacterSet newlineCharacterSet]
	                                 intoString:NULL]; // 继续扫描下一行
	    }
	}
	
`scanColor:` 这个方法非常简单。首先，它试图扫描一个十六进制的颜色值，如果失败，它会尝试扫描 RGB 元组：

	- (BOOL)scanColor:(UIColor **)out
	{
	    return [self scanHexColorIntoColor:out] || [self scanTupleColorIntoColor:out];
	}
	
扫描一个十六进制颜色和之前是一样的。唯一的区别是我们将其封装在一个方法中, 并且使用的都是 `NSScanner` 的方法。它会返回一个 `BOOL` 值表示扫描成功，并将结果存储到一个指向 `UIColor` 对象的指针：

    - (BOOL)scanHexColorIntoColor:(UIColor **)out
    {
        NSCharacterSet *hexadecimalCharacterSet = 
           [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
        NSString *colorString = NULL;
        if ([self.scanner scanString:@"#" intoString:NULL] &&
            [self.scanner scanCharactersFromSet:hexadecimalCharacterSet 
                                     intoString:&colorString] &&
            colorString.length == 6) {
            *out = [UIColor colorWithHexString:colorString];
            return YES;
        }
        return NO;
    }
    
扫描基于 RGB 元组的颜色值也非常相似。在扫描 `@"("` 时，我们进行了与操作。在生产环境代码中，我们可能需要更多的错误检查，例如确保整数的范围 `0-255`：

	- (BOOL)scanTupleColorIntoColor:(UIColor **)out
	{
	    NSInteger red, green, blue = 0;
	    BOOL didScan = [self.scanner scanString:@"(" intoString:NULL] &&
	                   [self.scanner scanInteger:&red] &&
	                   [self.scanner scanString:@"," intoString:NULL] &&
	                   [self.scanner scanInteger:&green] &&
	                   [self.scanner scanString:@"," intoString:NULL] &&
	                   [self.scanner scanInteger:&blue] &&
	                   [self.scanner scanString:@")" intoString:NULL];
	    if (didScan) {
	        *out = [UIColor colorWithRed:(CGFloat)red/255.
	                               green:(CGFloat)green/255.
	                                blue:(CGFloat)blue/255. 
	                               alpha:1];
	        return YES;
	    } else {
	        return NO;
	    }
	}
	
写一个扫描器，就是在逻辑上将多个可变的扫描值混合起来，并调用其它的一些方法。解析器不仅是一个非常吸引人的主题，还是一个强大的工具。一旦你知道如何编写一个解析器，你就可以发明一些小语言，如定义样式表、解析约束、查询数据模型、描述业务逻辑，等等。关于这个话题 Fowler 写了一本非常有趣的书，名为[《领域特定语言》](http://martinfowler.com/books/dsl.html)。

## 标记化（Tokenization）

我们已经有一个非常简单的解析器，它可以从一个文件中的字符串中提取键值对，我们也可以使用这些字符串生成 `UIColor` 对象。但是还没有完。要是设计者想要定义更多的事情，怎么办？比如，假设我们有不同的文件，其中包含一些布局的约束，格式如下：

	myView.left = otherView.right * 2 + 10
	viewController.view.centerX + myConstant <= self.view.centerX

我们该如何解析这个呢？实践证明正则表达式并不是最好的方法。

在我们进行解析之前，先把这个字符串进行*标记化*是一个不错的主意。标记化就是将一个字符串转换成一连串**标记 (token)**的过程。 例如，`myConstant = 100` 被标记化的结果可能会是 `@[@"myConstant", @"=", @100]`。在大多数程序语言中, 标记化就是删除空白符并将相关的字符解析成标记。在我们的语言中，标记可以是标识符（如 `myConstant` 或 `centerX`），操作符（如 `.`，`+` 或 `=`）或数字（如 `100`）。在标记化之后，标记会继续被解析。

为了实现标记化（有时也称为词法分析 *lexing* 或扫描 *scanning*），我们可以重用 `NSScanner` 类。首先，我们可以专注于解析只包含操作符的字符串：

    NSScanner *scanner = [NSScanner scannerWithString:contents];
    NSMutableArray *tokens = [NSMutableArray array];
    while (![scanner isAtEnd]) {
      for (NSString *operator in @[@"=", @"+", @"*", @">=", @"<=", @"."]) {
          if ([scanner scanString:operator intoString:NULL]) {
              [tokens addObject:operator];
          }
      }
    }
    
下一步是识别像 `myConstant` 和 `viewController` 这样的标识符。为了简单起见，标识符只包含字母（没有数字）。如下：

    NSString *result = nil;
    if ([scanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] 
                            intoString:&result]) {
        [tokens addObject:result];
    }
    
如果这些字符被找到，`scanCharactersFromSet:intoString:` 这个方法会返回 `YES`，然后我们将这些找到的字符添加到我们的标记数组。我们快要完成了，唯一剩下的事情就是是解析数字了。幸运的是，`NSScanner` 也提供了一些方法。我们可以使用 `scanDouble:` 方法来扫描 `double` 类型数据，并将其封装成 `NSNumber` 对象然后添加到标记数组：

    double doubleResult = 0;
    if ([scanner scanDouble:&doubleResult]) {
        [tokens addObject:@(doubleResult)];
    }
    
现在我们的解析器完成了，下面我们来进行测试：

    NSString* example = @"myConstant = 100\n"
                        @"\nmyView.left = otherView.right * 2 + 10\n"
                        @"viewController.view.centerX + myConstant <= self.view.centerX";
    NSArray *result = [self.scanner tokenize:example];
    NSArray *expected = @[@"myConstant", @"=", @100, @"myView", @".", @"left", 
                          @"=", @"otherView", @".", @"right", @"*", @2, @"+", 
                          @10, @"viewController", @".", @"view", @".", 
                          @"centerX", @"+", @"myConstant", @"<=", @"self", 
                          @".", @"view", @".", @"centerX"];
    XCTAssertEqualObjects(result, expected);
    
我们的扫描器可以对操作符，姓名，以及被封装成 `NSNumber` 对象的数字创建独立的标记。完成这些之后,我们准备进行第二步：把这个标记数组解析成更有意义的一些东西。

### 语法解析（Parsing）

我们之所以不能用正则表达式或扫描器来解决上述问题，是因为解析有可能失败。假定我们现在有一个标记：`@“myConstant”`。在我们的解析函数中，我们并不知道这是约束表达式的开始还是一个常数定义。我们需要两个都试一下，看看哪一个成功。我们可以手工来写这个解析代码，难倒是不难，但是写出来的代码就像一坨屎；或者我们可以使用更合适的工具：**语法解析库（parsing library）**。

首先，我们需要语法分析库能理解的方式来描述我们的语言。下面的代码就是专为我们那个布局约束语言写的解析语法，使用的是**扩展的巴科斯范式**（[EBNF](http://en.wikipedia.org/wiki/Extended_Backus–Naur_Form)）写法：

    constraint = expression comparator expression
    comparator = "=" | ">=" | "<="
    expression = keyPath "." attribute addMultiplier addConstant
    keyPath = identifier | identifier "." keyPath
    attribute = "left" | "right" | "top" | "bottom" | "leading" | "trailing" | "width" | "height" | "centerX" | "centerY" | "baseline"
    addMultiplier = "*" atom
    addConstant = "+" atom
    atom = number | identifier

有许多的 Objective-C 库用于语法解析（参见 [CocoaPods](http://cocoapods.org/?q=parse)）。像 [CoreParse](https://github.com/beelsebob/CoreParse) 就提供了很多 Objective-C 的 API。然而，我们并不能直接将我们的语法应用在它上面。CoreParse 一次仅仅只有一个解析器工作。这意味着每当解析器需要在两个规则之间做决定（比如 `keyPath` 规则）的时候，它会根据下一个标记来做决定。如果事后我们发现它选错了，那麻烦就大了。当然有的解析器允许更模糊的语法，但性能损失很大。

为了确保能够兼容语法分析库，可以对我们的语法做一些重构。 我们也可以将它转换成**标准的巴科斯范式**（[BNF](http://en.wikipedia.org/wiki/Backus–Naur_Form)），下面的代码就是 CoreParse 支持的格式：

    NSString* grammarString = [@[
        @"Atom ::= num@'Number' | ident@'Identifier';",
        @"Constant ::= name@'Identifier' '=' value@<Atom>;",
        @"Relation ::= '=' | '>=' | '<=';",
        @"Attribute ::= 'left' | 'right' | 'top' | 'bottom' | 'leading' | 'trailing' | 'width' | 'height' | 'centerX' | 'centerY' | 'baseline';",
        @"Multiplier ::= '*' num@'Number';",
        @"AddConstant ::= '+' num@'Number';",
        @"KeypathAndAttribute ::= 'Identifier' '.' <AttributeOrRest>;",
        @"AttributeOrRest ::= att@<Attribute> | 'Identifier' '.' <AttributeOrRest>;",
        @"Expression ::= <KeypathAndAttribute> <Multiplier>? <AddConstant>?;",
        @"LayoutConstraint ::= lhs@<Expression> rel@<Relation> rhs@<Expression>;",
        @"Rule ::= <Atom> | <LayoutConstraint>;",
    ] componentsJoinedByString:@"\n"];
    
如果一个规则被匹配了，那么这个解析器就试图找到具有同样名称的类（如 `Expression`）。如果这个类实现了 `initWithSyntaxTree:` 方法，那么该方法就会被调用。另外，解析器还有一个委托，当有一个规则被匹配上或者发生错误时，委托都会被调用。举例来说，我们先来看一下 `CPSyntaxTree` 类，它的第一个子节点是一个关键字标记（调用 `keyword` 方法获取），它可能包含 `@"="`，`@">="` 或者 `@"<="` 中的任意一个。属性 `layoutAttributes` 是一个字典，它的 `key` 是一个字符串，`value` 是一个关于布局的 `NSNumber` 对象：

    - (id)parser:(CPParser *)parser didProduceSyntaxTree:(CPSyntaxTree *)syntaxTree
        NSString *ruleName = syntaxTree.rule.name;
        if ([ruleName isEqualToString:@"Attribute"]) {
            return self.layoutAttributes[[[syntaxTree childAtIndex:0] keyword]];
        }
        ...
        
解析器的完整代码在 [GitHub](https://github.com/objcio/issue-9-string-parsing)，其中有一个类，大约 100 行代码，我们可以用它解析复杂的布局约束，如:

	viewController.view.centerX + 20 <= self.view.centerX * 0.5
	
我们会得到下面这样的结果，它可以很容易地转换成一个 `NSLayoutConstraint` 对象：

    (<Expression: self.keyPath=(viewController, view), 
                  self.attribute=9,
                  self.multiplier=1, 
                  self.constant=20> 
     -1 
     <Expression: self.keyPath=(self, view), 
                  self.attribute=9,
                  self.multiplier=0.5,
                  self.constant=0>)
                  
## 其他的工具

除了 Objective-C 的库，其他的一些工具比如 [Bison](http://www.gnu.org/software/bison/)，[Yacc](http://dinosaur.compilertools.net/yacc/)，[Ragel](http://www.complang.org/ragel/)，以及 [Lemon](http://www.hwaci.com/sw/lemon/lemon.html)，都是用 C 语言实现的。

另一件你可以做的事就是在 Build 时使用这些解析器生成一部分自己的代码。例如，一旦你有了一种语言的解析器，你就可以创建一个简单的命令行转换工具。添加一个 Xcode 的 [Build 规则](http://www.objccn.io/issue-6-1/)，每一次 Build 时，你自己的语言就会被一起编译。

## 关于语法分析的思考

语法分析看起来有一点奇怪，而且创建基于字符串的语言似乎并不是 Objective-C 的风格。但事实恰恰相反，苹果一直广泛使用着基于字符串的语言。如 `NSLog` 格式化字符串，`NSPredicate` 字符串，可视化的布局约束格式语言，甚至是 KVC。所有这些都用了一些小的内部解析器来解析字符串，并将其变成对象和方法。通常你不必自己编写一个解析器，这大大节省了工作时间：常见的语言如 JSON 和 XML 都有通用的解析器。但是如果你想要编写一个计算器，一种[图形语言](https://github.com/damelang/nile)，甚至是一个嵌入式的 Smalltalk，解析器大有帮助。

---

 
 
原文 [String Parsing](http://www.objc.io/issue-9/string-parsing.html)

译文 [objc.io 第9期之字符串解析 - iOS init](http://iosinit.com/?p=960)