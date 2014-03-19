[Source](http://www.objc.io/issue-9/working-with-strings.html "Permalink to Working with Strings - Strings - objc.io issue #9 ")

# Working with Strings - Strings - objc.io issue #9 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# Working with Strings

[Issue #9 Strings][4], February 2014

By [Daniel Eggert][5]

We use strings in various places in every single app. Here we’ll quickly take a look at some of the common ways to work with strings; it’s a walkthrough of some best practices for common operations.

## Sorting, Comparing, and Searching Strings

Sorting and comparing strings is more complex than first meets the eye. Not only can strings contain _surrogate pairs_ (see [Ole’s article on Unicode][6]) but sorting also depends on the locale. The corner cases are quite tricky.

Apple’s _String Programming Guide_ has a section called [“Characters and Grapheme Clusters”][7], which mentions a few of the pitfalls. For example, for sorting purposes, some European languages consider the sequence “ch” a single letter. In some languages, “ä” is considered equal to `a`, while in others it should be sorted after `z`.

`NSString` has methods to help us with this complexity. First off, there’s:


    - (NSComparisonResult)compare:(NSString *)aString options:(NSStringCompareOptions)mask range:(NSRange)range locale:(id)locale

which gives us full flexibility. Then there are a slew of convenience functions that all map to the aforementioned method.

The available options for comparison are:


    NSCaseInsensitiveSearch
    NSLiteralSearch
    NSNumericSearch
    NSDiacriticInsensitiveSearch
    NSWidthInsensitiveSearch
    NSForcedOrderingSearch

These can be or’d together.

`NSCaseInsensitiveSearch`: “A” is the same as “a,” though in some locales more complex things happen. For example, in German, “ß” and “SS” would be equal.

`NSLiteralSearch`: Unicode point for Unicode-point comparison. This will only return equal (`NSOrderedSame`) when all characters are composed in the exact same way. `LATIN CAPITAL LETTER A` and `COMBINING RING ABOVE` is not the same as `LATIN CAPITAL LETTER A WITH RING ABOVE`.

`NSNumericSearch`: This orders numbers inside strings, so that “Section 9” < “Section 20” < “Section 100.”

`NSDiacriticInsensitiveSearch`: “A” is the same as “Å” and the same as “Ä.”

`NSWidthInsensitiveSearch`: Some East Asian scripts (Hiragana and Katakana) have characters in full-width and half-width forms.

It’s worth mentioning `-localizedStandardCompare:`, which sorts items the same way that the Finder does. It corresponds to setting the option to `NSCaseInsensitiveSearch`, `NSNumericSearch`, `NSWidthInsensitiveSearch`, and `NSForcedOrderingSearch`. If we’re displaying a list of files in any UI, this is what we should use.

Case-insensitive compare and diacritic-insensitive compare are relatively complicated and expensive operations. If we need to compare strings too many times that it becomes a bottleneck (e.g. sorting large datasets), a common solution is to store both the original string and a folded string. For example, our `Contact` class would have a normal `name` property and internally it would also have a `foldedName` property that would get updated automatically when the name is changed. We can then use `NSLiteralSearch` to compare the folded version of the name. `NSString` has a method to create such a folded version:


    - (NSString *)stringByFoldingWithOptions:(NSStringCompareOptions)options locale:(NSLocale *)locale

### Searching

When searching for a substring inside a string, the method with the most flexibility is:


    - (NSRange)rangeOfString:(NSString *)aString options:(NSStringCompareOptions)mask range:(NSRange)searchRange locale:(NSLocale *)locale

Again, there are quite a few convenience methods, all of which end up calling into this one. We can pass the same options listed above, as well as these additional ones:


    NSBackwardsSearch
    NSAnchoredSearch
    NSRegularExpressionSearch

`NSBackwardsSearch`: Start at the end of the string.

`NSAnchoredSearch`: Only consider the start of the string, or (if combined with `NSBackwardsSearch`) only at the end of the string. This can be used to check for a prefix or suffix, as well as use case-insensitive and/or diacritic-insensitive comparison.

`NSRegularExpressionSearch`: Uses regular expression. See Chris’s article for more information about using regular expressions.

In addition, there’s also a method called:


    - (NSRange)rangeOfCharacterFromSet:(NSCharacterSet *)aSet options:(NSStringCompareOptions)mask range:(NSRange)aRange

Instead of searching for a string, it searches for the first character in the given character set. Even though this only searches for one character, the length of the returned range can be larger than one due to composed character sequences.

## Lower and Upper Case

We must never use `-uppercaseString` or `-lowercaseString` for strings that are supposed to be displayed in the UI. Instead, we must use `-uppercaseStringWithLocale:`, like so:


    NSString *name = @"Tómas";
    cell.text = [name uppercaseStringWithLocale:[NSLocale currentLocale]];

## Formatting Strings

Analogous to the C function `sprintf()` (part of the ANSI C89 standard), Objective C’s `NSString` class has these methods:


    -initWithFormat:
    -initWithFormat:arguments:
    %2BstringWithFormat:

Note that these formatting methods are _non-localized_. They should _not_ be used for strings to be shown in the UI. For that we need to use:


    -initWithFormat:locale:
    -initWithFormat:locale:arguments:
    %2BlocalizedStringWithFormat:

Florian’s article about [string localization][8] talks about this in more detail.

The man page for [printf(3)][9] has all the gory details on how format strings work. The format string is copied verbatim, except for the so-called conversion specification, which starts with a `%` character:


    double a = 25812.8074434;
    float b = 376.730313461;
    NSString *s = [NSString stringWithFormat:@"%g :: %g", a, b];
    // "25812.8 :: 376.73"

We’re formatting two floating point values. Note that both single-precision `float` and double-precision `double` can be formatted with the same conversion specifications.

### Objects

In addition to the conversion specifications from `printf(3)`, we can use `%@` to output an object. As noted in [Object Description][10], if the object responds to `-descriptionWithLocale:`, that gets called. Otherwise `-description` gets called. The %@ sequence is then replaced with the result.

### Integer Values

When using integer numbers, there are a few things to be aware of. First, there are conversion specifications for signed (`d` and `i`) and unsigned (`o`, `u`, `x`, and `X`). Then there are modifiers that specify what the type of these are.

If we’re using something that’s not in the list of types that printf knows about, we have to typecast the value. The same thing goes for types such as `NSUInteger`, which is not the same on 64-bit and 32-bit platforms. Here’s an example that works for both 32-bit and 64-bit platforms:


    uint64_t p = 2305843009213693951;
    NSString *s = [NSString stringWithFormat:@"The ninth Mersenne prime is %llu", (unsigned long long) p];
    // "The ninth Mersenne prime is 2305843009213693951"

Modifier d, i o, u, x, X

hh
signed char
unsigned char

h
short
unsigned short

(none)
int
unsigned int

l (ell)
long
unsigned long

ll (ell ell)
long long
unsigned long long

j
intmax_t
uintmax_t

t
ptrdiff_t

z
size_t

The conversion specifiers for integer numbers work like this:


    int m = -150004021;
    uint n = 150004021U;
    NSString *s = [NSString stringWithFormat:@"d:%d i:%i o:%o u:%u x:%x X:%X", m, m, n, n, n, n];
    // "d:-150004021 i:-150004021 o:1074160465 u:150004021 x:8f0e135 X:8F0E135"

`%d` and `%i` both do the same thing. They simply print the signed decimal value. `%o` is slightly obscure: it uses the [octal][11] notation. `%u` gives us the unsigned decimal value – it’s what we usually want. Finally, `%x` and `%X` use hexadecimal notation – the latter with capital letters.

For `%x` and `%X`, we can use a `#` flag to prefix `0x` in front of the string to make it more obvious that it’s a hexadecimal value.

And we can pass a minimum field width and a minimum number of digits (both are zero if omitted), as well as left / right alignment. Check the man page for details. Here are some samples:


    int m = 42;
    NSString *s = [NSString stringWithFormat:@"'%4d' '%-4d' '%%2B4d' '%4.3d' '%04d'", m, m, m, m, m];
    // "[  42] [42  ] [ %2B42] [ 042] [0042]"
    m = -42;
    NSString *s = [NSString stringWithFormat:@"'%4d' '%-4d' '%%2B4d' '%4.3d' '%04d'", m, m, m, m, m];
    // "[ -42] [-42 ] [ -42] [-042] [-042]"

`%p` is what we’d use to print pointer values – it’s similar to `%#x` but does the correct thing on both 32-bit and 64-bit platforms.

### Floating Point Values

There are eight conversion specifiers for floating-point values: `eEfFgGaA`. But we’ll hardly ever need anything except for ‘%f’ and ‘%g’. The uppercase version uses an uppercase `E`, while the the lowercase version uses a lowercase `e` for exponential components.

Usually `%g` is the go-to conversion specifier for floating-point values. The difference to `%f` is best illustrated with this sample:


    double v[5] = {12345, 12, 0.12, 0.12345678901234, 0.0000012345678901234};
    NSString *s = [NSString stringWithFormat:@"%g %g %g %g %g", v[0], v[1], v[2], v[3], v[4]];
    // "12345 12 0.12 0.123457 1.23457e-06"
    NSString *s = [NSString stringWithFormat:@"%f %f %f %f %f", v[0], v[1], v[2], v[3], v[4]];
    // "12345.000000 12.000000 0.120000 0.123457 0.000001"

Like with integer values, we can specify a minimum field width and a minimum number of digits.

### Specifying Positions

The format string allows the parameters to be _consumed_ in another order:


    [NSString stringWithFormat:@"%2$@ %1$@", @"1st", @"2nd"];
    // "2nd 1st"

We simply have to put the 1-based index of the parameter and a `$` sign after the `%`. This is mostly relevant for localized strings, because the order in which certain parts occur in the string might be different for other languages.

### NSLog()

The `NSLog()` function works the same way as `%2BstringWithFormat:`. When we call:


    int magic = 42;
    NSLog(@"The answer is %d", magic);

the code will construct the string in the same way as:


    int magic = 42;
    NSString *output = [NSString stringWithFormat:@"The answer is %d", magic];

Obviously `NSLog()` will then also output the string. And it prefixes it with a timestamp, process name, process identifier, and thread identifier.

### Implementing Methods that take Format Strings

It’s sometimes convenient to provide a method on our own class that also takes a format string. Let’s say we’re implementing a To Do app which has an `Item` class. We want to provide:


    %2B (instancetype)itemWithTitleFormat:(NSString *)format, ...

so we can use it with:


    Item *item = [Item itemWithFormat:@"Need to buy %@ for %@", food, pet];

This kind of method, which takes a variable number of arguments, is called a _variadic_ method. We have to use the macros defined in `stdarg.h` to use these. An implementation of the above method would look like this:


    %2B (instancetype)itemWithTitleFormat:(NSString *)format, ...;
    {
        va_list ap;
        va_start(ap, format);
        NSString *title = [[NSString alloc] initWithFormat:format locale:[NSLocale currentLocale] arguments:ap];
        va_end(ap);
        return [self itemWithTitle:title];
    }

Additionally, we should add `NS_FORMAT_FUNCTION` to the method definition (in the header file), like so:


    %2B (instancetype)itemWithTitleFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

The `NS_FORMAT_FUNCTION` expands to a method `__attribute__`, which tells the compiler that the argument at index **1** is a format string, and that the arguments start at index **2**. This allows the compiler to check the format string and output warnings in the same way it would do for `NSLog()` and `-[NSString stringWithFormat:]`.

## Characters and String Components

Given a string like “bird,” it is straightforward to know what the individual letters are. The second letter is an “i” (Unicode: `LATIN SMALL LETTER I`). For a string like [Åse][12], it’s not that simple.

What looks like three characters can be represented in several ways, e.g.


    A    LATIN CAPITAL LETTER A
     ̊    COMBINING RING ABOVE
    s    LATIN SMALL LETTER S
    e    LATIN SMALL LETTER E

or


    Å    LATIN CAPITAL LETTER A WITH RING ABOVE
    s    LATIN SMALL LETTER S
    e    LATIN SMALL LETTER E

Read more about combining marks in [Ole’s article on Unicode][6]. Other scripts have more complicated surrogate pairs.

If we need to work on the character level of a string, we need to be careful. Apple’s _String Programming Guide_ has a section called [“Characters and Grapheme Clusters”][7] that goes into more detail about this.

`NSString` has these two methods:


    -rangeOfComposedCharacterSequencesForRange:
    -rangeOfComposedCharacterSequenceAtIndex:

that help us if we need to, for example, split a string, to make sure that we don’t split so-called _surrogate pairs_. The range can then be passed to `-substringWithRange:`.

If we need to need to work with the characters of a string, `NSString` has a method called:


    -enumerateSubstringsInRange:options:usingBlock:

Passing `NSStringEnumerationByComposedCharacterSequences` as the option will allow us to scan through all characters. For example, with the below method, we’d turn the string “International Business Machines” into “IBM”:


    - (NSString *)initials;
    {
        NSMutableString *result = [NSMutableString string];
        [self enumerateSubstringsInRange:NSMakeRange(0, self.length) options:NSStringEnumerationByWords | NSStringEnumerationLocalized usingBlock:^(NSString *word, NSRange wordRange, NSRange enclosingWordRange, BOOL *stop1) {
            __block NSString *firstLetter = nil;
              [self enumerateSubstringsInRange:NSMakeRange(0, word.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *letter, NSRange letterRange, NSRange enclosingLetterRange, BOOL *stop2) {
                  firstLetter = letter;
                  *stop2 = YES;
              }];
              if (letter != nil) {
                  [result appendString:letter];
            };
        }];
        return result;
    }

As noted in the documentation, word and sentence boundaries may also change depending on the locale. Hence the `NSStringEnumerationLocalized` option.

## Multi-Line String Literals

An admittedly obscure feature of the compiler is that it will join several string literals separated by nothing but white space. What does that mean? These two are identical:


    NSString *limerick = @"A lively young damsel named Menzies
    "
    @"Inquired: «Do you know what this thenzies?»
    "
    @"Her aunt, with a gasp,
    "
    @"Replied: "It's a wasp,
    "
    @"And you're holding the end where the stenzies.
    ";

and:


    NSString *limerick = @"A lively young damsel named Menzies
    Inquired: «Do you know what this thenzies?»
    Her aunt, with a gasp,
    Replied: "It's a wasp,
    And you're holding the end where the stenzies.
    ";

The former is easier on the eye. Just be sure not to insert a semicolon or comma at the end of any lines.

We can also do things like


    NSString *string = @"The man " @"who knows everything " @"learns nothing" @".";

The pieces are concatenated at compile time. It’s merely a convenience provided by our friend, the compiler.

## Mutable Strings

There are two common scenarios where mutable strings are useful: (1) when piecing strings together from smaller parts, and (2) when replacing parts of a string.

### Building Strings

Mutable strings make your code easier when you need to build up your string from multiple pieces:


    - (NSString *)magicToken
    {
        NSMutableString *string = [NSMutableString string];
        if (usePrefix) {
            [string appendString:@">>>"];
        }
        [string appendFormat:@"%d--%d", self.foo, self.bar];
        if (useSuffix) {
            [string appendString:@">>>"];
        }
        return string;
    }

Also note how we’re simply returning an instance of `NSMutableString` to the caller.

### Replacing Substrings

Aside from appending, `NSMutableString` also has these four methods:


    -deleteCharactersInRange:
    -insertString:atIndex:
    -replaceCharactersInRange:withString:
    -replaceOccurrencesOfString:withString:options:range:

These are similar to the `NSString` methods:


    -stringByReplacingOccurrencesOfString:withString:
    -stringByReplacingOccurrencesOfString:withString:options:range:
    -stringByReplacingCharactersInRange:withString:

but they don’t create a new string – they mutate the string in place. This can make your code easier to read and will most likely also improve performance:


    NSMutableString *string; // assume we have this
    // Remove prefix string:
    NSString *prefix = @"WeDon’tWantThisPrefix"
    NSRange r = [string rangeOfString:prefix options:NSAnchoredSearch range:NSMakeRange(0, string.length) locale:nil];
    if (r.location != NSNotFound) {
        [string deleteCharactersInRange:r];
    }

## Joining Components

A seemingly trivial, yet common case is joining strings. Let’s say we have a few strings:


    Hildr
    Heidrun
    Gerd
    Guðrún
    Freya
    Nanna
    Siv
    Skaði
    Gróa

and we want to create the string:


    Hildr, Heidrun, Gerd, Guðrún, Freya, Nanna, Siv, Skaði, Gróa

We can do this with:


    NSArray *names = @["Hildr", @"Heidrun", @"Gerd", @"Guðrún", @"Freya", @"Nanna", @"Siv", @"Skaði", @"Gróa"];
    NSString *result = [names componentsJoinedByString:@", "];

If we were to display this to users, we’d want to use the locale and make sure we replace the last part with “, and”:


    @implementation NSArray (ObjcIO_GroupedComponents)

    - (NSString *)groupedComponentsWithLocale:(NSLocale *)locale;
    {
        if (self.count < 1) {
            return @"";
        } else if (self.count < 2) {
            return self[0];
        } else if (self.count < 3) {
            NSString *joiner = NSLocalizedString(@"joiner.2components", @"");
            return [NSString stringWithFormat:@"%@%@%@", self[0], joiner, self[1]];
        } else {
            NSString *joiner = [NSString stringWithFormat:@"%@ ", [locale objectForKey:NSLocaleGroupingSeparator]];
            NSArray *first = [self subarrayWithRange:NSMakeRange(0, self.count - 1)];
            NSMutableString *result = [NSMutableString stringWithString:[first componentsJoinedByString:joiner]];

            NSString *lastJoiner = NSLocalizedString(@"joiner.3components", @"");
            [result appendString:lastJoiner];
            [result appendString:self.lastObject];
            return result;
        }
    }

    @end

and then have:


    "joiner.2components" = " and ";
    "joiner.3components" = ", and ";

for US English or:


    "joiner.2components" = " und ";
    "joiner.3components" = " und ";

for German.

The inverse of joining components can be done with the `-componentsSeparatedByString:` method, which turns a string into an array, e.g. “12|5|3” into “12,” “5,” and “3.”

## Object Description

In many object-oriented programming languages, it’s common for objects to have a `toString()` or similarly named method. In Objective C, this method is:


    - (NSString *)description

along with its sibling:


    - (NSString *)debugDescription

It is good practice to override `-description` for model objects in such a way that the return value can be used to display the object in UI. Let’s say we have a `Contact` class. It would make sense to implement:


    - (NSString *)description
    {
        return self.name;
    }

which would allow us to use format strings, like so:


    label.text = [NSString stringWithFormat:NSLocalizedString(@"%@ has been added to the group “%@”.", @""), contact, group];

Since this string is for the UI, we may need access to the locale. If that’s the case, we can instead override:


    - (NSString *)descriptionWithLocale:(NSLocale *)locale;

The format sequence `%@` looks for `-descriptionWithLocale:` first, and falls back to `-description`.

Inside the debugger, we can print and object with `po` (short for print object):


    (lldb) po contact

This will call `-debugDescription` on the object. By default, `-debugDescription` calls `-description`. If we want to output different info, simply override both. In most cases (particularly for non-model objects) simply overriding `-description` will fit the bill.

The de-facto standard output format for objects is:


    - (NSString *)description;
    {
        return [NSString stringWithFormat:@"", self.class, self];
    }

This is what `NSObject` will return to us. When we override this method, it most likely makes sense to use this as a starting point. If we have a `DetailViewController` that controls UI to display a `contact`, we might want to implement it, like so:


    - (NSString *)description;
    {
        return [NSString stringWithFormat:@" contact = %@", self.class, self, self.contact.debugDescription];
    }

### Description of `NSManagedObject` Subclasses

We should take special care when adding `-description` / `-debugDescription` to subclasses of `NSManagedObject`. Core Data’s faulting mechanism allows for objects to be around without their data. We most likely don’t want to alter the state of our application when calling `-debugDescription`, hence we should make sure to check `isFault`. For example, we might implement it like this:


    - (NSString *)debugDescription;
    {
        NSMutableString *description = [NSMutableString stringWithFormat:@"", self.class, self];
        if (! self.isFault) {
            [description appendFormat:@" %@ \"%@\" %gL", self.identifier, self.name, self.metricVolume];
        }
        return description;
    }

Again, since these are model objects, it makes sense to override `-description` to simply return the property that describes the instance such as the `name`.

## File Paths

The short story is that we shouldn’t use `NSString` for file paths. As of OS X 10.7 and iOS 5, `NSURL` is just as convenient to use, and is more efficient, as it’s able to cache file system properties.

Additionally, `NSURL` has eight methods for accessing so-called _resource values_, which give a stable interface to get and set various properties of files and directories, such as localized file name (`NSURLLocalizedNameKey`), file size (`NSURLFileSizeKey`), and creation date (`NSURLCreationDateKey`), to name a few.

Particularly when enumerating directory content, using `-[NSFileManager enumeratorAtURL:includingPropertiesForKeys:options:errorHandler:]` with the list of _keys_, and then retrieving them with `-getResourceValue:forKey:error:`, can give substantial performance boosts.

Here’s a short example on how to put this together:


    NSError *error = nil;
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSURL *documents = [fm URLForDirectory:NSDocumentationDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:&error];
    NSArray *properties = @[NSURLLocalizedNameKey, NSURLCreationDateKey];
    NSDirectoryEnumerator *dirEnumerator = [fm enumeratorAtURL:documents
                                    includingPropertiesForKeys:properties
                                                       options:0
                                                  errorHandler:nil];
    for (NSURL *fileURL in dirEnumerator) {
        NSString *name = nil;
        NSDate *creationDate = nil;
        if ([fileURL getResourceValue:&name forKey:NSURLLocalizedNameKey error:NULL] &&
            [fileURL getResourceValue:&creationDate forKey:NSURLCreationDateKey error:NULL])
        {
            NSLog(@"'%@' was created at %@", name, creationDate);
        }
    }

We’re passing the keys for properties into the `-enumeratorAtURL:...` method, which will make sure they’re fetched in a very efficient manner as we enumerate the directory content. Inside the loop, the calls to `-getSourceValue:...` will then simply get the already cached values from that `NSURL` without having to touch the file system.

## Passing Paths to UNIX APIs

Because Unicode is very complex and can represent the same letter in multiple ways, we need to be careful when passing paths to UNIX APIs. We must absolutely not use `UTF8String` in these cases. The correct thing is to use the `-fileSystemRepresentation` method, like so:


    NSURL *documentURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL];
    documentURL = [documentURL URLByAppendingPathComponent:name];
    int fd = open(documentURL.fileSystemRepresentation, O_RDONLY);

The very same thing goes for `NSString` as for `NSURL`. If we fail to do this, we’ll see random failure when opening files that have any composed characters in their name or anywhere in their path. On OS X, this is particularly bad when the user’s short name happens to contain composed characters, e.g. `tómas`.

Common cases where we need a `char const *` version of a path are the UNIX `open()` and `close()` commands. But this also occurs with GCD / libdispatch’s I/O API:


    dispatch_io_t
    dispatch_io_create_with_path(dispatch_io_type_t type,
    	const char *path, int oflag, mode_t mode,
    	dispatch_queue_t queue,
    	void (^cleanup_handler)(int error));

If we want to use this with an `NSString`, we need to make sure to do it like this:


    NSString *path = ... // assume we have this
    io = dispatch_io_create_with_path(DISPATCH_IO_STREAM,
        path.fileSystemRepresentation,
        O_RDONLY, 0, queue, cleanupHandler);

What `-fileSystemRepresentation` does is that it first converts the string to the file system’s [normalization form][13] and then encodes it as UTF-8.




* * *

[More articles in issue #9][14]

  * [Privacy policy][15]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-9/index.html
   [5]: http://twitter.com/danielboedewadt
   [6]: http://www.objc.io/issue-9/unicode.html#peculiar-unicode-features
   [7]: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Strings/Articles/stringsClusters.html
   [8]: http://www.objc.io/issue-9/string-localization.html#localized-format-strings
   [9]: https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man3/printf.3.html
   [10]: http://www.objc.io#object-description
   [11]: https://en.wikipedia.org/wiki/Octal
   [12]: https://en.wikipedia.org/wiki/%C3%85se
   [13]: http://www.objc.io/issue-9/unicode.html#normalization-forms
   [14]: http://www.objc.io/issue-9
   [15]: http://www.objc.io/privacy.html
