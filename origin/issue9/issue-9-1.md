[Source](http://www.objc.io/issue-9/unicode.html "Permalink to NSString and Unicode - Strings - objc.io issue #9 ")

# NSString and Unicode - Strings - objc.io issue #9 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# NSString and Unicode

[Issue #9 Strings][4], February 2014

By [Ole Begemann][5]

If you write any non-legacy code that deals with text today and you aren’t using [Unicode][6] everywhere, you’re doing it wrong. Fortunately for us, Apple and NeXT have been among the driving forces behind the creation of the Unicode standard and NeXT’s [Foundation Kit][7], [introduced in 1994][8], was one of the first standard libraries based on Unicode for any programming language. But even though [`NSString`][9] fully supports Unicode and does most of the difficult work for you, handling text in hundreds of different languages and writing systems remains a very complex topic, and there are some things you as a programmer should be aware of.

In this article, I want to give you an overview of the Unicode standard and then explain how the `NSString` class handles it, as well as discuss some common problems you may encounter.

## History

Computers cannot handle text directly; they can only deal with numbers. To represent text (a string of characters) as (a string of) numbers in a computer, we specify a mapping from characters into numbers. This is called an _[encoding_][10].

The best-known character encoding is [ASCII][11]. ASCII is a 7-bit code that maps the English alphabet, the digits 0-9, and some punctuation and control characters into the integers 0 to 127. Subsequently, many different 8-bit encodings were created to make computers work with languages other than English. They were mostly based on ASCII and utilized the unused eighth bit to encode additional letters, symbols, or entire alphabets (such as Cyrillic or Greek).

These encodings were all incompatible with each other, of course — and necessarily so, since eight bits did not provide enough room for all characters used even in the common European scripts, not to mention all of the world’s writing systems. This was a big problem for the text-based computer systems of the time because only one encoding (also called a [code page][12]) could be active at a time; if you wrote a text on one machine and then opened it on another computer that used a different code page, all characters in the 128-255 range would be interpreted incorrectly.

East Asian scripts such as Chinese, Japanese, and Korean presented another problem. They have so many characters that the mapping requires much more than the 256 slots provided by 8-bit numbers. As a result, wider encodings (usually 16 bits) were developed. And as soon as you’re dealing with values that do not fit into one byte, the question of how these numbers should be stored in memory or on disk becomes non-trivial. You have to perform a second mapping that defines rules for [byte order][13] and possibly applies a [variable-length][14] encoding instead of a simple fixed-width variant. Note that this second mapping step is just another form of encoding, and the fact that we can use the same word for both is a common source of confusion. I’ll get back to this in the discussion of UTF-8 and UTF-16.

Modern operating systems are no longer limited to using only one code page at a time, so as long as every document correctly reported the encoding it was written in, dealing with dozens or hundreds of different encodings would be entirely possible, if annoying. What is not possible is _mixing_ multiple encodings in one document and thus writing multilingual documents, and this really puts the final nail in the coffin of the pre-Unicode state of the world.

[Beginning in 1987][15], people from major tech companies, including Apple and NeXT, started working together on a universal character encoding for all the world’s writing systems, which resulted in the release of version 1.0.0 of the [Unicode Standard][16] in October 1991.

## Unicode Overview

### The Basics

At its most basic level, the Unicode standard defines a unique number for every character or symbol that is used in writing, for nearly all[1][17] of the world’s writing systems. The numbers are called _code points_ and are written in the form `U%2Bxxxx` where the `xxxx` are four to six hexadecimal digits. For example, the code point U%2B0041 (65decimal) stands for the letter A in the Latin alphabet (same as ASCII) and U%2B1F61B represents the [emoji][18] named FACE WITH STUCK-OUT TONGUE, or 😛. (The names of the characters are an official part of the Unicode standard, by the way.) You can use the [official code charts][19] or the Character Viewer on OS X (Control %2B Option %2B Space) to look up the code points.

![The Character Viewer in OS X showing a table of Emoji and Unicode character information][20]

Like the other encodings I mentioned above, Unicode represents characters in an abstract way and says nothing about how they should be rendered. This goes so far that Unicode uses identical code points for the Han characters used in Chinese, Japanese, and Korean (CJK) scripts (the so-called [Han unification][21]) although these writing systems have each developed unique glyph variants of the characters — a controversial decision.

Unicode was originally conceived as a 16-bit encoding, providing room for 65,536 characters. This was deemed big enough to encode all scripts and characters used in modern text around the world. Obsolete or rare characters were supposed to go into [Private Use Areas][22] when needed — designated regions within the 65,536 character space that organizations could use to define their own mappings (which could potentially conflict with each other). Apple encodes a substantial number of custom symbols and control characters in the Private Use Areas, ([documented here][23]), though most of them are deprecated. A notable exception is the Apple logo at U%2BF8FF:  (depending on the platform you are reading this on, you may see a completely different character here).

The Unicode code space was [later][24] extended to 21 bits (U%2B0000 to U%2B10FFFF) to allow for the encoding of historic scripts and rarely-used Kanji or Chinese characters.[2][25] This is an important point: despite what we are going to learn about `NSString`, Unicode is _not a 16-bit encoding!_ It’s 21 bits wide. These 21 bits provide room for 1,114,112 code points. Only approximately 10 percent of those are currently in use, so there is plenty of room to grow.

The code space is divided into 17 [planes][26] with 65,536 characters each. Plane 0 is called the _Basic Multilingual Plane (BMP)_ and it is where almost all characters you will encounter in the wild reside, with the notable exception of emoji. The other planes are called _supplementary planes_ and are largely empty.

### Peculiar Unicode Features

It helps to think of Unicode as a unification of existing (mostly 8-bit) encodings, rather than a _universal_ code. Mostly for compatibility reasons with legacy encodings, the standard includes a number of subtleties you have to be aware of to correctly handle Unicode strings in your code.

#### Combining Character Sequences

For compatibility with preexisting standards, certain characters can be represented either as a single code point or as sequences of two or more code points. For example, the accented letter é can be represented as the precomposed character U%2B00E9 (LATIN SMALL LETTER E WITH ACUTE), or it can be encoded in a decomposed form as U%2B0065 (LATIN SMALL LETTER E) followed by U%2B0301 (COMBINING ACUTE ACCENT). The two forms are variants of a _[combining (or composite) character sequence_][27]. Combining character sequences are not only observed in western scripts; in [Hangul][28], for example, the syllable 가 can be represented as a single code point (U%2BAC00) or as the sequence ᄀ %2B ᅡ (U%2B1100 U%2B1161).

In Unicode parlance, the two forms are _not equal_ (because they contain different code points) but _[canonically equivalent_][29]: that is, they have the same appearance and meaning.

#### Duplicate Characters

Many seemingly identical characters are encoded multiple times at different code points, representing different meanings. For example, the Latin character A (U%2B0041) is identical in shape to the [Cyrillic character A][30] (U%2B0410) but they are, in fact, different. Encoding these as separate code points not only simplifies conversion from legacy encodings, but also allows Unicode text to retain the characters’ meaning.

But there are also rare instances of “real” duplication, where the same character is defined under multiple code points. As an example, the Unicode Consortium [lists][31] the letter Å (LATIN CAPITAL LETTER A WITH RING ABOVE, U%2B00C5) and the character Å (ANGSTROM SIGN, U%2B212B). Since the Ångström sign is, in fact, defined to be the Swedish capital letter, these characters are truly identical. In Unicode, they too are not equal but canonically equivalent.

More characters and sequences fall under a broader definition of “duplicate,” called _[compatibility equivalence_][29] in the Unicode standard. Compatible sequences represent the same abstract character, but may have a different visual appearance or behavior. Examples include many Greek letters, which are also used as mathematical and technical symbols, and the Roman numerals, which are encoded in addition to the standard Latin letters in the range from U%2B2160 to U%2B2183. Other good examples of compatibility equivalence are [ligatures][32]: the character ﬀ (LATIN SMALL LIGATURE FF, U%2BFB00) is compatible with (but not canonically equivalent to) the sequence ff (LATIN SMALL LETTER F %2B LATIN SMALL LETTER F, U%2B0066 U%2B0066), although both may be rendered identically, depending on the context, typeface, and the capabilities of the text rendering system.

#### Normalization Forms

We have seen that string equality is not a simple concept in Unicode. Aside from comparing two strings, code point for code point, we also need a way to test for canonical equivalence or compatibility equivalence. Unicode defines several _[normalization_][33] algorithms for this. Normalizing a string means converting it to a form that guarantees a unique representation of equivalent character sequences, so that it can then be binary-compared to another normalized string.

The Unicode standard includes four normalization forms labeled C, D, KD, and KC, which can be arranged in a two-by-two matrix (I have also listed the `NSString` methods that perform the normalizations):

Unicode Normalization Forms (NF) Character Form

Composed (é) Decomposed (e %2B ´)

Equivalence
Class Canonical

C

[`precomposed​String​With​Canonical​Mapping`][34]

D

[`decomposed​String​With​Canonical​Mapping`][35]

Equivalence

KC

[`precomposed​String​With​Compatibility​Mapping`][36]

KD

[`decomposed​String​With​Compatibility​Mapping`][37]

For the purpose of comparing strings, it does not matter whether you normalize them all to the decomposed (D) form or to the composed (C) form. Form D should be faster, since the algorithm for form C involves two steps: characters are first decomposed and then recomposed. If one character sequence includes multiple combining marks, the ordering of the combining marks will be unique after decomposition. On the other hand, the Unicode Consortium [recommends form C][38] for storage due to better compatibility with strings converted from legacy encodings.

Both equivalence classes can be handy for string comparisons, especially in the context of sorting and searching. Keep in mind, though, that you should generally not normalize a string with compatibility equivalence that is supposed to be stored permanently, as [it can alter the text’s meaning][39]:

> Normalization Forms KC and KD must not be blindly applied to arbitrary text. Because they erase many formatting distinctions, they will prevent round-trip conversion to and from many legacy character sets, and unless supplanted by formatting markup, they may remove distinctions that are important to the semantics of the text. It is best to think of these Normalization Forms as being like uppercase or lowercase mappings: useful in certain contexts for identifying core meanings, but also performing modifications to the text that may not always be appropriate.

#### Glyph Variants

Some fonts provide multiple shape variants ([glyphs][40]) for a single character, and Unicode provides a mechanism named [variation sequences][41] that allows the author to select a certain variant. It works exactly like combining character sequences: a base character is followed by one of 256 variation selectors (VS1-VS256, U%2BFE00 to U%2BFE0F, and U%2BE0100 to U%2BE01EF). The standard distinguishes between [Standardized Variation Sequences][42] (defined in the Unicode standard) and [Ideographic Variation Sequences][43] (submitted by third parties to the Unicode consortium; once registered, they can be used by anyone). From a technical perspective, there is no difference between the two.

An example of standardized variation sequences is emoji styles. Many emoji and some “normal” characters come in two fashions, a colorful “emoji style” and a black and white, more symbol-like “text style.” For instance, the UMBRELLA WITH RAIN DROPS character (U%2B2614) can look like this: ☔️ (U%2B2614 U%2BFE0F) or this: ☔︎ (U%2B2614 U%2BFE0E).

### Unicode Transformation Formats

As we have seen above, mapping characters to code points only gets us half of the way. We have to define another encoding that determines how code point values are to be represented in memory or on disk. The Unicode Standard defines several of these mappings and calls them _transformation formats (UTF)_. In the real world, most people just call them _encodings_ — if something is encoded in a UTF, it uses Unicode by definition, so there is no need to distinguish between the two steps.

#### UTF-32

The most straightforward UTF is [UTF-32][44]: it uses exactly 32 bits for each code point, and since 32 > 21, every UTF-32 value can be a direct representation of its code point. Despite its simplicity, UTF-32 is almost never used in the wild because using four bytes per character is very space inefficient.

#### UTF-16 and the Concept of Surrogate Pairs

[UTF-16][45] is a lot more common and, as we will see, very relevant for the discussion of `NSString`’s Unicode implementation. It is defined in terms of so-called _code units_ that have a fixed width of 16 bits. UTF-16 itself is a variable-width encoding. Each code point in the BMP is directly mapped to one code unit. Since the BMP encompasses almost all common characters, UTF-16 typically requires only half the memory of UTF-32. The rarely used code points in other planes are encoded with two 16-bit code units. The two code units that together represent one code point are called a _surrogate pair_.

To avoid ambiguous byte sequences in a UTF-16-encoded string, and to make detection of surrogate pairs easy, the Unicode standard has reserved the range from U%2BD800 to U%2BDFFF for the use of UTF-16. Code point values in this range will never be assigned a character. When a program sees a bit sequence that falls into this range in a UTF-16 string, it knows right away that it has encountered part of a surrogate pair. The actual encoding algorithm is simple, and you can read more about it in the [Wikipedia article for UTF-16][45]. The design of UTF-16 is also the reason for the seemingly weird 21-bit range for code points. U%2B10FFFF is the highest value you can encode with this scheme.

Like all multibyte encoding schemes, UTF-16 (and UTF-32) must also take care about [byte order][13]. For strings in memory, most implementations naturally adopt the endianness of the CPU they run on. For storage on disk or transmission over the network, UTF-16 allows implementations to insert a [Byte Order Mark][46] (BOM) at the beginning of the string. The BOM is a code unit with the value U%2BFEFF, and by examining the first two bytes of a file, the decoding machine can recognize its byte order. The BOM is optional, and the standard prescribes big-endian byte order as the default. The complexity introduced by the need to specify byte order is one reason why UTF-16 is not a popular encoding for file formats or transmission over the network, although OS X and Windows both use it internally.

#### UTF-8

Because the first 256 Unicode code points (U%2B0000 to U%2B00FF) are identical to the common [ISO-8859-1][47] (Latin 1) encoding, UTF-16 still wastes a lot of space for typical English and western European text: the upper 8 bits of each 16-bit code unit would be 0.[3][48] Perhaps more importantly, UTF-16 presented challenges to legacy code that often assumed text to be ASCII-encoded. [UTF-8][49] was developed by Ken Thompson (of Unix fame) and Rob Pike to remedy these deficiencies.[4][50] It is a great design and you should definitely read [Rob Pike’s account of how it was created][51].

UTF-8 uses between one and four[5][52] bytes to encode a code point. The code points from 0-127 are mapped directly to one byte (making UTF-8 identical to ASCII for texts that only contain these characters). The following 1,920 code points are encoded with two bytes, and all remaining code points in the BMP need three bytes. Code points in other Unicode planes require four bytes. Since UTF-8 is based on 8-bit code units, it does not need to care about byte ordering (some programs add a superfluous BOM to UTF-8 files, though).

The space efficiency (for western languages) and lack of byte order issues make UTF-8 the best encoding for the storage and exchange of Unicode text. It has become the _de facto_ standard for file formats, network protocols, and Web APIs.

## NSString and Unicode

`NSString` is fully built on Unicode. However, Apple does a bad job explaining this correctly. This is what [Apple’s documentation has to say about `CFString` objects][53] (which provides the implementation for `NSString`, too):

> Conceptually, a CFString object represents an array of Unicode characters (`UniChar`) along with a count of the number of characters. … The [Unicode] standard defines a universal, uniform encoding scheme that is _16 bits per character_.

Emphasis mine. This is completely and utterly wrong! We have already learned that Unicode is a _21-bit_ encoding scheme, but with documentation like this, it’s no wonder so many people believe it’s 16 bits.

The [`NSString` documentation][9] is equally misleading:

> A string object presents itself as an array of Unicode characters …. You can determine how many characters a string object contains with the `length` method and can retrieve a specific character with the `characterAtIndex:` method. These two “primitive” methods provide basic access to a string object.

This sounds better at first glance because it does not repeat the bullshit about Unicode characters being 16 bits wide. But dig a little deeper and you’ll see that [`unichar`][54], the return type of the [`characterAtIndex:`][55] method, is just a 16-bit unsigned integer. Obviously, that’s not enough to represent 21-bit Unicode characters:


    typedef unsigned short unichar;

The truth is that an `NSString` object actually represents an array of _UTF-16-encoded code units_. Accordingly, the [`length`][56] method returns the number of code units (not characters) in the string. At the time when `NSString` was developed (it was first published in 1994 as part of Foundation Kit), Unicode was still a 16-bit encoding; the wider range and UTF-16’s surrogate character mechanism were introduced with Unicode 2.0 in 1996. From today’s perspective, the `unichar` type and the `characterAtIndex:` method are terribly named because they tend to promote any confusion a programmer may have between Unicode characters (code points) and UTF-16 code units. `codeUnitAtIndex:` would be a vastly better method name.

If you only remember one thing about `NSString`, make it this: `NSString` represents UTF-16-encoded text. Length, indices, and ranges are all based on UTF-16 code units. Methods based on these concepts provide unreliable information unless you know the contents of the string or take appropriate precautions. Whenever the documentation mentions characters or `unichar`s, it really talks about code units. The Apple documentation actually expresses this correctly in a later section of the String Programming Guide, though Apple continues to assign the wrong meaning to the word _character_. I highly recommend you read the section titled [Characters and Grapheme Clusters][57], which explains very well what is really going on.

Note that although strings are conceptually based on UTF-16, that does not imply that the class always works with UTF-16-encoded data internally. It makes no promise about the internal implementation (and you could write your own by subclassing `NSString`). As a matter of fact, `CFString` [attempts to be as memory-efficient as possible][58], depending on the string’s content, while still retaining the capability for O(1) conversion to UTF-16 code units. You can read the [CFString source code][59] to verify this for yourself.

### Common Pitfalls

Knowing what you now know about `NSString` and Unicode, you should be able to recognize potentially dangerous string operations. Let’s check some of them out and see how we can avoid problems. But first, we need to know how to create strings with any Unicode character sequence.

By default, Clang expects source files to be UTF-8-encoded. As long as you make sure that Xcode saves your files in UTF-8, you can directly insert any character from the Character Viewer. If you prefer to work with code points, you can enter them as `@"\u266A"` (♪) for code points up to U%2BFFFF or `@"\U0001F340"` (🍀) for code points outside the BMP. Interestingly, [C99 does not allow][60] these _universal character names_ for characters in the standard C character set, so this fails:


    NSString *s = @"\u0041"; // Latin capital letter A
    // error: character 'A' cannot be specified by a universal character name

I think you should avoid using the [format specifier][61] %C, which takes a `unichar`, for the purpose of creating string variables, as it can easily lead to confusion between code units and code points. It can be useful for log output, though.

#### Length

`-[NSString length]` returns the number of `unichar`s in a string. We have seen three Unicode features why this value may be different than the actual number of (visible) characters:

  1. Characters outside the Basic Multilingual Plane: Remember that all characters in the BMP can be expressed as a single code unit in UTF-16. All other characters require two code units (a surrogate pair). Since virtually all characters in modern use reside in the BMP, surrogate pairs were very rare encounters in the real world. However, this has changed a few years ago, with the inclusion of emoji into Unicode, which are in Plane 1. Emoji have become so common that your code must be able to handle them correctly:

         NSString *s = @"\U0001F30D"; // earth globe emoji 🌍
     NSLog(@"The length of %@ is %lu", s, [s length]);
     // => The length of 🌍 is 2

The simplest solution for this problem is a small hack. You can just ask the string to calculate the number of bytes the string would need in UTF-32 and divide by 4:

         NSUInteger realLength =
         [s lengthOfBytesUsingEncoding:NSUTF32StringEncoding] / 4;
     NSLog(@"The real length of %@ is %lu", s, realLength);
     // => The real length of 🌍 is 1

  2. Combining character sequences: If an é is encoded in its decomposed form (e %2B ´), it counts as two code units:

         NSString *s = @"e\u0301"; // e %2B ´
     NSLog(@"The length of %@ is %lu", s, [s length]);
     // => The length of é is 2

The result of `2` is correct in the sense that the string really contains two Unicode characters, but it does not represent the apparent length as a person would count it. You can use the method `precomposedStringWithCanonicalMapping` to normalize the string to normalization form C (precomposed characters) to get a better result:

         NSString *n = [s precomposedStringWithCanonicalMapping];
     NSLog(@"The length of %@ is %lu", n, [n length]);
     // => The length of é is 1

Unfortunately, this will not work in all cases because only the most common combining character sequences are available in precomposed form — other combinations of base character and combining marks will remain as they are, even after normalization. If you really need to know the apparent length of a string as counted by a person, you must iterate over the string and count it yourself. See the section about looping for details.

  3. Variation sequences: These behave like decomposed combining character sequences, so the variation selector counts as a separate character.

#### Random Access

Accessing a `unichar` directly by its index with the `characterAtIndex:` method presents the same problems. The string may contain combining character sequences, surrogate pairs, and/or variation sequences. Apple uses the term _composed character sequence_ to refer to all these features. The terminology gets really confusing here; be careful not to confound composed character sequences (the Apple term) with combining character sequences (the Unicode term). The latter are only a subset of the former. Use the [`rangeOfComposedCharacterSequenceAtIndex:`][62] method to find out if the `unichar` at a given index is part of a sequence of code units that represents a single character (which, in turn, can consist of multiple code points). You should do this whenever you need to pass a range of a string with unknown contents to another method to make sure that Unicode characters don’t get torn apart.

#### Looping

Using `rangeOfComposedCharacterSequenceAtIndex:`, you could write a routine that correctly loops over all characters in a string, but it would be quite inconvenient to have to do this every time you want to iterate over a string. Fortunately, `NSString` has a better way in the form of the [`enumerateSubstringsInRange:options:usingBlock:`][63] method. This method abstracts away the peculiarities of Unicode and allows you to loop over composed character sequences, words, lines, sentences, or paragraphs in a string very easily. You can even add the `NSStringEnumerationLocalized` option, which takes the user’s locale into account for determining the boundaries of words and sentences. To iterate over characters, specify `NSStringEnumerationByComposedCharacterSequences`:


    NSString *s = @"The weather on \U0001F30D is \U0001F31E today.";
        // The weather on 🌍 is 🌞 today.
    NSRange fullRange = NSMakeRange(0, [s length]);
    [s enumerateSubstringsInRange:fullRange
                          options:NSStringEnumerationByComposedCharacterSequences
                       usingBlock:^(NSString *substring, NSRange substringRange,
                                    NSRange enclosingRange, BOOL *stop)
    {
        NSLog(@"%@ %@", substring, NSStringFromRange(substringRange));
    }];

This wonderful method emphasizes that Apple wants us to think of a string as a collection of substrings, rather than characters (in the Apple sense), because (a) a single `unichar` is too small a unit to represent a true Unicode character, and (b) some characters (in the common sense) are composed of multiple Unicode code points. Note that it was only added relatively recently (in OS X 10.6 and iOS 4.0). Before, looping over the characters in a string was a lot less fun.

#### Comparisons

String objects are not normalized unless you perform that step manually. This means that comparing strings that contain combining character sequences can potentially lead to wrong results. Both [`isEqual:`][64] and [`isEqualToString:`][65] compare strings byte for byte. If you want precomposed and decomposed variants to match, you must normalize the strings first:


    NSString *s = @"\u00E9"; // é
    NSString *t = @"e\u0301"; // e %2B ´
    BOOL isEqual = [s isEqualToString:t];
    NSLog(@"%@ is %@ to %@", s, isEqual ? @"equal" : @"not equal", t);
    // => é is not equal to é

    // Normalizing to form C
    NSString *sNorm = [s precomposedStringWithCanonicalMapping];
    NSString *tNorm = [t precomposedStringWithCanonicalMapping];
    BOOL isEqualNorm = [sNorm isEqualToString:tNorm];
    NSLog(@"%@ is %@ to %@", sNorm, isEqualNorm ? @"equal" : @"not equal", tNorm);
    // => é is equal to é

Your other option is to use the [`compare:`][66] method (or one of its variants like [`localizedCompare:`][67]), which returns a match for strings that are _compatibility equivalent_. This is not documented well by Apple. Note that you will often want to compare for _canonical_ equivalence instead. `compare:` does not give you that choice:


    NSString *s = @"ff"; // ff
    NSString *t = @"\uFB00"; // ﬀ ligature
    NSComparisonResult result = [s localizedCompare:t];
    NSLog(@"%@ is %@ to %@", s, result == NSOrderedSame ? @"equal" : @"not equal", t);
    // => ff is equal to ﬀ

If you need to use `compare:` but don’t want to take equivalence into account, the [`compare:options:`][68] variants allow you to specify `NSLiteralSearch`, which also speeds things up.

#### Reading Text from Files or the Network

In general, text data is only useful if you know how that text is encoded. When you download text data from a server, you usually know its encoding or can retrieve it from the HTTP header. It is then trivial to create a string object from the data with the method [`-[NSString initWithData:encoding:]`][69].

Text files do not include their encoding in the file data itself, but `NSString` can often determine the encoding of a text file by looking at extended file attributes or by using heuristics (for example, certain binary sequences are guaranteed to not appear in a valid UTF-8 file). To read text from a file with a known encoding, use [`-[NSString initWithContentsOfURL:encoding:error:]`][70]. To read files with unknown encoding, [Apple provides this guideline][71]:

> If you are forced to guess the encoding (and note that in the absence of explicit information, it is a guess):
>
>   1. Try `stringWithContentsOfFile:usedEncoding:error:` or `initWithContentsOfFile:usedEncoding:error:` (or the URL-based equivalents).
>
> These methods try to determine the encoding of the resource, and if successful return by reference the encoding used.
>
>   2. If (1) fails, try to read the resource by specifying UTF-8 as the encoding.
>
>   3. If (2) fails, try an appropriate legacy encoding.
>
> “Appropriate” here depends a bit on circumstances; it might be the default C string encoding, it might be ISO or Windows Latin 1, or something else, depending on where your data are coming from.
>
>   4. Finally, you can try `NSAttributedString`’s loading methods from the Application Kit (such as `initWithURL:options:documentAttributes:error:`).
>
> These methods attempt to load plain text files, and return the encoding used. They can be used on more-or-less arbitrary text documents, and are worth considering if your application has no special expertise in text. They might not be as appropriate for Foundation-level tools or documents that are not natural-language text.

#### Writing Text to Files

I have already mentioned that your encoding of choice for plain text files, as well as your own file formats or network protocols, should be UTF-8 unless a specification prescribes something else. To write a string to a file, use the [`writeToURL:​atomically:​encoding:​error:`][72] method.

This method will automatically add a byte order mark to the file for UTF-16 or UTF-32. It will also store the file’s encoding in an [extended file attribute][73] under the name `com.apple.TextEncoding`. Since the `initWithContentsOf…:usedEncoding:error:` methods obviously know about this attribute, just using the standard `NSString` methods gets you a long way in making sure you are using the correct encoding when loading text from a file.

## Conclusion

Text is complicated. And although Unicode has vastly improved the way software deals with text, it does not absolve developers from knowing how it works. Today, virtually every app has to deal with multilingual text. Even if your app is not localized into Chinese or Arabic, as soon as you accept _any_ input from your users, you must be prepared to deal with the whole spectrum of Unicode.

You owe the rest of the world to test your string handling routines thoroughly, and that means testing them with inputs other than plain English. Be sure to use lots of emoji and words from non-Latin scripts in your unit tests. If you don’t know how to write in a certain script, I have found Wikipedia to be very useful. Just copy words from a random article in the [Wikipedia of your choice][74].

## Further Reading

  * Joel Spolsky: [The Absolute Minimum Every Software Developer Absolutely, Positively Must Know About Unicode and Character Sets][75]. This is more than 10 years old and not specific to Cocoa, but still a very good overview.
  * [Ross Carter][76] gave a wonderful talk at NSConference 2012 titled [You too can speak Unicode][77]. It’s a very entertaining talk and I highly recommend watching it. I based part of this article on Ross’s presentation. Scotty from [NSConference][78] was kind enough to make the video available to all objc.io readers. Thanks!
  * The [Wikipedia article on Unicode][6] is great.
  * [unicode.org][79], the website of the Unicode Consortium, not only has the full standard and code chart references, but also a wealth of other interesting information. The extensive [FAQ section][80] is excellent.

* * *

  1. The current Unicode standard 6.3.0 [supports 100 scripts and 15 symbol collections][81], such as mathematical symbols or mahjong tiles. Among the [yet unsupported scripts][82], it specifically lists 12 scripts in current use in living communities and 31 archaic or ‘dead’ scripts.

[↩][83]
  2. Today, Unicode encodes more than 70,000 unified CJK characters, easily blasting the 16-bit boundary with these alone.

[↩][84]
  3. And even documents in other scripts can contain a lot of characters from that range. Consider an HTML document, the content of which is entirely in Chinese. A significant percentage of its total character count will consist of HTML tags, CSS styles, Javascript code, spaces, line terminators, etc.

[↩][85]
  4. In a 2012 blog post, I wondered whether [making UTF-8 ASCII-compatible was the right decision][86]. As I now know, this was, in fact, one of the central goals of the scheme, specifically to avoid problems with non-Unicode-aware file systems. I still think that too much backward compatibility can often turn out to be a hindrance, because this feature still hides bugs in poorly tested Unicode-handling code today.

[↩][87]
  5. UTF-8 was originally designed to encode code points up to 31 bits, which required sequences of up to 6 bytes. It was later restricted to 21 bits in order to match the constraints set by UTF-16. The longest UTF-8 byte sequence is now 4 bytes.

[↩][88]




* * *

[More articles in issue #9][89]

  * [Privacy policy][90]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-9/index.html
   [5]: http://oleb.net
   [6]: http://en.wikipedia.org/wiki/Unicode
   [7]: http://www.cilinder.be/docs/next/NeXTStep/3.3/nd/Foundation/IntroFoundation.htmld/index.html
   [8]: http://blog.securemacprogramming.com/2013/10/happy-19th-birthday-cocoa/
   [9]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/Classes/NSString_Class/Reference/NSString.html
   [10]: http://en.wikipedia.org/wiki/Character_encoding
   [11]: http://en.wikipedia.org/wiki/ASCII
   [12]: http://www.i18nguy.com/unicode/codepages.html
   [13]: http://en.wikipedia.org/wiki/Endianness
   [14]: http://en.wikipedia.org/wiki/Variable-width_encoding
   [15]: http://www.unicode.org/history/summary.html
   [16]: http://www.unicode.org/standard/standard.html
   [17]: http://www.objc.io#fn%3A1
   [18]: http://en.wikipedia.org/wiki/Emoji
   [19]: http://www.unicode.org/charts/index.html
   [20]: http://www.objc.io/images/issue-9/os-x-character-viewer-emoji.png
   [21]: http://en.wikipedia.org/wiki/Han_unification
   [22]: http://en.wikipedia.org/wiki/Private_Use_Areas
   [23]: http://www.unicode.org/Public/MAPPINGS/VENDORS/APPLE/CORPCHAR.TXT
   [24]: http://www.unicode.org/faq/utf_bom.html#gen0
   [25]: http://www.objc.io#fn%3A2
   [26]: http://en.wikipedia.org/wiki/Plane_%28Unicode%29
   [27]: http://en.wikipedia.org/wiki/Precomposed_character
   [28]: http://en.wikipedia.org/wiki/Hangul
   [29]: http://en.wikipedia.org/wiki/Unicode_equivalence
   [30]: http://en.wikipedia.org/wiki/A_%28Cyrillic%29
   [31]: http://www.unicode.org/standard/where/#Duplicates
   [32]: http://en.wikipedia.org/wiki/Typographic_ligature
   [33]: http://en.wikipedia.org/wiki/Unicode_normalization#Normalization
   [34]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/precomposedStringWithCanonicalMapping
   [35]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/decomposedStringWithCanonicalMapping
   [36]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/precomposedStringWithCompatibilityMapping
   [37]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/decomposedStringWithCompatibilityMapping
   [38]: http://www.unicode.org/faq/normalization.html#2
   [39]: http://unicode.org/reports/tr15/
   [40]: http://en.wikipedia.org/wiki/Glyph
   [41]: http://en.wikipedia.org/wiki/Variant_form_%28Unicode%29
   [42]: http://unicode.org/Public/UCD/latest/ucd/StandardizedVariants.html
   [43]: http://www.unicode.org/ivd/
   [44]: http://en.wikipedia.org/wiki/UTF-32
   [45]: http://en.wikipedia.org/wiki/UTF-16
   [46]: http://en.wikipedia.org/wiki/Byte_Order_Mark
   [47]: http://en.wikipedia.org/wiki/ISO/IEC_8859-1
   [48]: http://www.objc.io#fn%3A3
   [49]: http://en.wikipedia.org/wiki/UTF-8
   [50]: http://www.objc.io#fn%3A4
   [51]: http://www.cl.cam.ac.uk/~mgk25/ucs/utf-8-history.txt
   [52]: http://www.objc.io#fn%3A5
   [53]: https://developer.apple.com/library/ios/documentation/CoreFoundation/Conceptual/CFStrings/Articles/UnicodeBasis.html
   [54]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/uid/20000154-SW40
   [55]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/characterAtIndex:
   [56]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/length
   [57]: https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Strings/Articles/stringsClusters.html
   [58]: https://developer.apple.com/library/ios/documentation/CoreFoundation/Conceptual/CFStrings/Articles/StringStorage.html
   [59]: http://www.opensource.apple.com/source/CF/CF-855.11/CFString.c
   [60]: http://c0x.coding-guidelines.com/6.4.3.html
   [61]: https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html
   [62]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/rangeOfComposedCharacterSequenceAtIndex:
   [63]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/enumerateSubstringsInRange:options:usingBlock:
   [64]: https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Protocols/NSObject_Protocol/Reference/NSObject.html#//apple_ref/occ/intfm/NSObject/isEqual:
   [65]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/isEqualToString:
   [66]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/compare:
   [67]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/localizedCompare:
   [68]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/compare:options:
   [69]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/initWithData:encoding:
   [70]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/initWithContentsOfURL:encoding:error:
   [71]: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Strings/Articles/readingFiles.html#//apple_ref/doc/uid/TP40003459-SW4
   [72]: https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSString_Class/Reference/NSString.html#//apple_ref/occ/instm/NSString/writeToURL:atomically:encoding:error:
   [73]: http://nshipster.com/extended-file-attributes/
   [74]: http://meta.wikimedia.org/wiki/List_of_Wikipedias
   [75]: http://www.joelonsoftware.com/articles/Unicode.html
   [76]: https://twitter.com/RossT
   [77]: https://vimeo.com/86030221
   [78]: http://nsconference.com
   [79]: http://www.unicode.org
   [80]: http://www.unicode.org/faq/
   [81]: http://www.unicode.org/standard/supported.html
   [82]: http://www.unicode.org/standard/unsupported.html
   [83]: http://www.objc.io#fnref%3A1
   [84]: http://www.objc.io#fnref%3A2
   [85]: http://www.objc.io#fnref%3A3
   [86]: http://oleb.net/blog/2012/09/utf-8/
   [87]: http://www.objc.io#fnref%3A4
   [88]: http://www.objc.io#fnref%3A5
   [89]: http://www.objc.io/issue-9
   [90]: http://www.objc.io/privacy.html
