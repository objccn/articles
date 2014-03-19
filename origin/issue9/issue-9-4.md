[Source](http://www.objc.io/issue-9/string-parsing.html "Permalink to String Parsing - Strings - objc.io issue #9 ")

# String Parsing - Strings - objc.io issue #9 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# String Parsing

[Issue #9 Strings][4], February 2014

By [Chris Eidhof][5]

In almost every computer program, we have to parse strings. Sometimes these strings follow a very simple format, and sometimes they are very complicated. We will look at multiple ways to convert these strings into something we can reason and work with. We’ll discuss regular expressions and scanners and parsers, as well as when to apply them.

### Regular vs. Context-Free Grammars

First, a little bit of background theory: if we parse a string, we interpret the string in a specific _language_. For example, if we want to parse the string `@"42"` to a number, we interpret the string in the language of natural numbers. A grammar is used to describe a _language_: it is the collection of rules according to which a string can be interpreted. In the case of natural numbers, there can be only one rule: a string can be interpreted, if and only if it is a sequence of digits. This language could be described using some standard C functions, or using a regular expression. If we can describe a language using regular expressions, it is said to have a _regular grammar_.

If we consider expressions like “1 %2B 2 * 3”, parsing becomes a bit more difficult. For these expressions, the language can be described using an inductive grammar. In other words, this is a grammar that has rules that refer to themselves, possibly even in a recursive way. For example, to recognize this language, we could have three rules:

  1. Any number is part of the language
  2. If `x` is a member of the language, and `y` is a member, then `x %2B y` is also a member
  3. If `x` is a member of the language, and `y` is a member, then `x * y` is also a member

The languages that can be described using these kinds of grammars are called _context-free_ grammars, or CFG [1][6]. Note that they cannot be parsed using regular expressions (although some regular expression implementations, such as PCRE, can express more than regular grammars). The classical example of languages that can be parsed with CFG but not with regular expressions is that of matching parentheses [2][7].

Some examples of things that can be parsed using regular languages are numbers, strings, and dates. This means that you can use a regular expression (or a similar technique) to parse them.

Some things that cannot be parsed using regular languages, are e-mail addresses [2][8], JSON, XML, or most programming languages. To parse these, we need an actual parser. Often times, these parsers are already written for us. Apple provides parsers for XML and JSON, so if we want to parse those, it’s easiest to just use Apple’s format.

## Regular Expressions

When you want to recognize simple languages, regular expressions are often the right tool for the job. However, they are also frequently misused for things like HTML parsing, where they are not a good fit. Let’s suppose we have a file containing simple variable definitions for colors that designers can use to change the colors in your iPhone app. The format looks like this:


    backgroundColor = #ff0000

If we want to parse a single line using this format, we can use a regular expression, like below. The `pattern` is the most important thing. If you don’t know regular expressions, we will quickly go over what this means, but explaining regular expressions completely is way beyond the scope of this article. The first thing to look at is `\w%2B`, which matches a word character (defined by `\w`), one or more times (defined by the `%2B`). Then, to make sure we can later use the result of that match, we put it in parentheses, creating a _capture group_. Next, there’s a literal space character, followed by an equals sign, another space character, and a pound. Then, we need to match six hexadecimal numbers. The `\p{Hex_Digit}` matches a hexadecimal digit (`Hex_Digit` is a [unicode property name][9]). The modifier `{6}` means that we expect six of those characters, and again, we put it in parentheses to create a second capture group:


    NSError *error = nil;
    NSString *pattern = @"(\w%2B) = #(\p{Hex_Digit}{6})";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                options:0
                                                                                  error:&error];
    NSTextCheckingResult *result = [expression firstMatchInString:string
                                                          options:0
                                                            range:NSMakeRange(0, string.length)];
    NSString *key = [string substringWithRange:[result rangeAtIndex:1]];
    NSString *value = [string substringWithRange:[result rangeAtIndex:2]];

We create a regular expression and ask the expression to match the string `string`. Then we extract the two groups captured by the parentheses by using `rangeAtIndex`. The entire regular expression is at index 0, the first capture group is at index 1, the second capture group is at index 2, and so on. Now `key` is `backgroundColor` and `value` is `ff0000`. This regular expression parses a single line; a next step would be to parse multiple lines and add some error checking. For example, the input:


    backgroundColor = #ff0000
    textColor = #0000ff

should produce the following dictionary: `@{@"backgroundColor": @"ff0000", @"textColor": @"0000ff"}`. The code to do that is simple. We split the string into lines, iterate over them, and add them to our dictionary:


    NSString *pattern = @"(\w%2B) = #([\da-f]{6})";
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

As an aside: to separate the string into components, we could have also used `componentsSeparatedByString:` or enumerated them using `enumerateSubstringsInRange:options:usingBlock:` with the option `NSStringEnumerationByLines`.

To see if a line doesn’t match (for example, if we accidentally forget one of the hexadecimal characters), we can check if `textCheckingResult` is nil, and throw an error:


     if (!textCheckingResult) {
         NSString* message = [NSString stringWithFormat:@"Couldn't parse line: %@", line]
         NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: message};
         *error = [NSError errorWithDomain:MyErrorDomain code:FormatError userInfo:errorDetail];
         return nil;
     }

## Scanners

There is a second way of taking this string and turning it into a dictionary, namely using scanners. Conveniently, Foundation provides us with `NSScanner`, which has an easy-to-use object-oriented API. First, we need to create a scanner:


    NSScanner *scanner = [NSScanner scannerWithString:string];

By default, a scanner skips all white space and newline characters. For our purposes, we don’t want to skip newlines, only white space:


    scanner.charactersToBeSkipped = [NSCharacterSet whitespaceCharacterSet];

Then, we define the set of hexadecimal characters. A lot of character sets are defined, but the hexadecimal set is not one of them:


    NSCharacterSet *hexadecimalCharacterSet =
      [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];

First, let’s write a version without error checking. A scanner works like this: it takes a string and sets its cursor to 0, the beginning of the string. You tell it to scan something specific, like [`sanner scanString:@"=" intoString:NULL]`. The method returns `YES` if the scan succeeds, and increases the cursor value to just after the scanned part. The method `scanCharactersFromSet:intoString:` works in a similar way: it keeps scanning characters from the set, and puts the result into the string pointer given by the second argument. Note that we combine the different scanning calls with `&&`. This way, the right-hand side of the `&&` is only scanned if the left-hand side succeeded:


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
                            intoString:NULL]; // scan an optional newline
    }
    return result;

To add error handling, we can write this code just after the `didScan` line. If scanning didn’t succeed, we just return nil and set the `error` parameter accordingly. When parsing text, it’s important to think about what you want to do in case a string is malformed, whether it is to crash, present the error to the user, try to recover from the error, etcetera:


        if (!didScan) {
            NSString *message = [NSString stringWithFormat:@"Couldn't parse: %u", scanner.scanLocation];
            NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: message};
            *error = [NSError errorWithDomain:MyErrorDomain code:FormatError userInfo:errorDetail];
            return nil;
        }

Note that C also provides you with scanner functions, such as `man 3 sscanf`. They follow a similar syntax to `printf`, but operate in the inverse order (parsing a string, rather than generating one).

## Parsers

What if our designers would also want to specify RGB colors, like this: `(100,0,255)`? We would have to make our method for parsing colors a bit smarter. As a matter of fact, after we’re done here, we will have written a very basic parser.

First, we will add a couple of more methods to our class, and store our scanner in a property. The first method we add is called `scanColor:`, and its job is to scan either a hex color (like `ff0000`) or an RGB tuple (e.g. `(255,0,0)`):


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
                                     intoString:NULL]; // scan an optional newline
        }
    }

The `scanColor:` method itself is very easy. First, it tries to scan a hex color, and if that doesn’t work, it tries an RGB tuple:


    - (BOOL)scanColor:(UIColor **)out
    {
        return [self scanHexColorIntoColor:out] || [self scanTupleColorIntoColor:out];
    }

Scanning a hex color is the same as before. The only difference is that we have now wrapped it in a method, and use the same pattern as `NSScanner` methods. It returns a `BOOL` indicating successful scanning, and stores the result in a pointer to a `UIColor`:


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

Scanning a tuple-based color is very similar; we have already looked at all the necessary methods for doing this. We scan tokens like `@"("`, interspersed by the integer components. In production code, we would need some more error checking, to, for example, make sure that the integers are in the range `0-255`:


    - (BOOL)scanTupleColorIntoColor:(UIColor **)out
    {
        NSInteger red, green, blue = 0;
        BOOL didScan = [self.scanner scanString:@"(" intoString:NULL]
                && [self.scanner scanInteger:&red]
                && [self.scanner scanString:@"," intoString:NULL]
                && [self.scanner scanInteger:&green]
                && [self.scanner scanString:@"," intoString:NULL]
                && [self.scanner scanInteger:&blue]
                && [self.scanner scanString:@")" intoString:NULL];
        if (didScan) {
            *out = [UIColor colorWithRed:(CGFloat)red/255.
                                   green:(CGFloat)green/255.
                                    blue:(CGFloat)blue/255. alpha:1];
            return YES;
        } else {
            return NO;
        }
    }

When we start to mix scanning things with logic–such as scanning multiple alternatives, and calling other methods–we are writing a parser. Parsers are a fascinating subject, and a very powerful tool in your arsenal. Once you know how to write a parser, you can invent small languages for anything: specifying style sheets, parsing constraints, querying your data model, describing business logic, and so on. An interesting book on this is Fowler’s [Domain Specific Languages][10].

## Tokenization

We have a very simple parser that can extract key/value pairs from a string (for example, coming from a file) and we can use those strings to generate `UIColor` objects. But we’re not done yet. What if the designers want to specify more things? For example, suppose we have a different file that contains some layout constraints, in the following form:


    myView.left = otherView.right * 2 %2B 10
    viewController.view.centerX %2B myConstant 