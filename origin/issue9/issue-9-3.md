[Source](http://www.objc.io/issue-9/string-localization.html "Permalink to String Localization - Strings - objc.io issue #9 ")

# String Localization - Strings - objc.io issue #9 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# String Localization

[Issue #9 Strings][4], February 2014

By [Florian Kugler][5]

Localizing apps into multiple languages comes with a variety of different tasks. Since this issue is all about strings, we’re going to take a look at the topic of string localization. String localization comes in two different flavors: strings in code and strings in nib files and storyboards. We’re going to focus on strings in code in this article.

## NSLocalizedString

At the heart of string localization is the macro `NSLocalizedString`. There are three more lesser-known variants of it: `NSLocalizedStringFromTable`, `NSLocalizedStringFromTableInBundle`, and `NSLocalizedStringWithDefaultValue`. All of them use `NSBundle`’s `localizedStringForKey:value:table:` method to do the heavy lifting.

The point of using those macros is twofold. First off, it makes the code easier to read. It’s a lot shorter than `NSBundle`’s `localizedStringForKey:value:table:`. Second, these macros get picked up by the [`genstrings`][6] tool that creates strings files you can then translate. It parses `.c` and `.m` source files and generates `.strings` files with one entry per unique localizable string key.

To run `genstrings` over all `.m` files in your project, you can invoke it, for example, like this:


    find . -name *.m | xargs genstrings -o en.lproj

The `-o` argument specifies the output directory where the `.strings` file will be written. By default, the strings file will be called `Localizable.strings`. Beware that `genstrings` is going to overwrite existing strings files. Specifying the `-a` option tells it to append to existing files rather than to overwrite them.

In general though, you probably want to generate the strings files in another directory and then merge them with existing files using your favorite merge tool, in order to preserve existing entries that are already translated.

Strings files are very simple text files mapping keys to values:


    /* Insert new contact button */
    "contact-editor.insert-new-contact-button" = "Insert contact";
    /* Delete contact button */
    "contact-editor.delete-contact-button" = "Delete contact";

You can do more complicated things like including format placeholders in localizable strings, but we’ll talk about this later.

By the way: strings files can now be [saved as UTF-8 files][7], because Xcode will convert them to UTF-16 during the build process.

### What’s a Localizable String?

Generally, all strings you want to show to the user in one form or another have to be localized. These can be simple labels or button titles, or more complex strings that are constructed at runtime from format strings and data.

When localizing strings, it is important to define one localizable string per instance, due to grammatical rules. For example, if you have an app where you need to show strings like “Paul invited you” and “You invited Paul,” it might be tempting to just localize the string “%@ invited %@” and then insert the localized string for “you” in the appropriate place.

This seems to work just fine in English, but it’s important to remember that these kinds of tricks that work in your language will almost always fail in other languages. In German, for example, “Paul invited you” would be translated as “Paul hat dich eingeladen,” whereas “You invited Paul” would be “Du hast Paul eingeladen”.

The correct approach would be to define two localizable strings: “%@ invited you” and “You invited %@.” Only then can translators account for the specific grammar rules of each language.

Never dissect sentences into parts, but always keep them together as one localizable string. And even if a second sentence appears to be constructed the same way in your language, create a second string if the grammatical structure is not exactly the same.

### String Key Best Practices

When using the `NSLocalizedString` macro, the first argument you have to specify is a key for this particular string. You’ll often see that developers simply use the term in their base language as key. While this might be convenient in the beginning, it is actually a really bad idea and can lead to very bad localizations.

Each key is unique within a localizable strings file. Hence, whatever term is unique in your language can only have one translation in every other language as well. This quickly fails because what’s expressed using one term in one language often requires different terms in another language.

For example consider the term “run.” In English, this term can refer to the noun “run” as well as to the verb “to run.” Both of these will probably translate differently. And even both of these (noun and verb) might translate differently based on context.

You can imagine a fitness app that uses this term in different places with different meanings. However, if you localize it as:


    NSLocalizedString(@"Run", nil)

you will end up with only one entry in the strings file, regardless of whether you specify different comments or no comment at all as the second argument. Let’s consider the German translation again: “run” in the sense of “the run” or “a run,” would be translated as “Lauf,” whereas “run” in the sense of “to run,” would be translated as “laufen,” or maybe something entirely different like “loslaufen,” “Los geht’s,” or whatever sounds good in the specific context.

Good localizable string keys have to fulfill two requirements: first, they must be unique for each context they’re used in, and second, they must stick out if we forgot to translate something.

We recommend using a name-spaced approach like this:


    NSLocalizedString(@"activity-profile.title.the-run", nil)
    NSLocalizedString(@"home.button.start-run", nil)

By defining the keys like that, you can create a nice separation between different parts of the app and immediately provide some context within the key, like specifying that a certain string is used as a title or as a button. We’re omitting the comments in this example for the sake of brevity, but you should use them if the key does not provide enough context. Be sure to only use [ASCII][8] characters in string keys.

### Splitting Up the String File

As we mentioned in the beginning, `NSLocalizedString` has a few siblings that allow for more control of string localization. `NSLocalizedStringFromTable` takes the key, the table, and the comment as arguments. The table argument refers to the string table that should be used for this localized string. `genstrings` will create one strings file per table identifier with the file name `.strings`.

This way, you can split up your strings files into several smaller files. This can be very helpful if you’re working on a large project or in a bigger team, and it can also make merging regenerated strings files with their existing counterparts easier.

Instead of calling:


    NSLocalizedStringFromTable(@"home.button.start-run", @"ActivityTracker", @"some comment..")

everywhere, you can make your life a bit easier by defining your own custom string localization functions:


    static NSString * LocalizedActivityTrackerString(NSString *key, NSString *comment) {
        return [[NSBundle mainBundle] localizedStringForKey:key value:key table:@"ActivityTracker"];
    }

In order to generate the strings file for all usages of this function, you have to call `genstrings` with the `-s` option:


    find . -name *.m | xargs genstrings -o en.lproj -s LocalizedActivityTrackerString

The `-s` argument specifies the base name of the localization functions. The previous call will also pick up the functions called `FromTable`, `FromTableInBundle`, and `WithDefaultValue`, if you choose to define and use those.

### Localized Format Strings

Often we have to localize strings that contain some data that can only be inserted at runtime. To achieve this, we can use format strings, and Foundation comes with some gems to make this feature really powerful. (See [Daniel’s article][9] for more details on format strings.)

A simple example would be to display a string like “Run 1 out of 3 completed.” We would build the string like this:


    NSString *localizedString = NSLocalizedString(@"activity-profile.label.run %lu out of %lu completed", nil);
    self.label.text = [NSString localizedStringWithFormat:localizedString, completedRuns, totalRuns];

Often translations will need to reorder those format specifiers in order to construct a grammatically correct sentence. Luckily, this can be done easily in the strings file:


    "activity-profile.label.run %lu out of %lu completed" = "Von %2$lu Läufen hast du %$1lu absolviert";

Admittedly, this German translation is actually not very good – I just made it up to demonstrate the reordering of format specifiers…

If you need simple localization of integers or floats, you can use the `%2BlocalizedStringWithFormat:` variant. For more advanced cases of number formatting, you should use `NSNumberFormatter` though; more on that later.

#### Plural and Gender Support

As of OS X 10.9 and iOS 7, localized format strings can do much cooler stuff than just simple replacement of format specifiers with numbers or strings. The problem Apple tries to address is that different languages handle plural and gender forms very differently.

Let’s have a look at the previous example again: @”%lu out of %lu runs completed.” This works as long as there is always more than one run to be completed. So we would have to define two different strings for the case of n = 1 and n > 1:


    @"%lu out of one run completed"
    @"%lu out of %lu runs completed"

Again, that works fine in English, but unfortunately it will fail for many other languages. For example, Hebrew has three different forms: one for when n = 1 or n is a multiple of ten, another one for when n = 2, and a third for all other cases. In Croatian, there’s one form for numbers that end with 1 (such as 1, 11, 21, …): “31 od 32 staze završene” as opposed to “5 od 8 staza završene” (“staze” vs. “staza”). Many languages also have special rules for non-integral numbers.

To see the whole scope of this problem, you really should take a look at this [Unicode Language Plural Rules][10] overview. It’s just stunning.

In order to do this the correct way (from 10.9 and iOS 7 onward), we’re going to refer to this localized string like this:


    [NSString localizedStringWithFormat:NSLocalizedString(@"activity-profile.label.%lu out of %lu runs completed"), completedRuns, totalRuns];

Then we create a `.stringsdict` file next to the normal `.strings` file. So if the strings file is called `Localizable.strings`, we need to create a `Localizable.stringsdict` file. It’s important to still have a `.strings` file around, even if it is just an empty file. The `.stringsdict` file is a property list (`plist`) file that is more complex than a normal string file, but in return it allows correct plural handling in all languages without any plural logic in our code.

An example looks like this:


    
    
    
    
        activity-profile.label.%lu out of %lu runs completed
        
            NSStringLocalizedFormatKey
            %lu out of %#@lu_total_runs@ completed
            lu_total_runs
            
                NSStringFormatSpecTypeKey
                NSStringPluralRuleType
                NSStringFormatValueTypeKey
                lu
                one
                %lu run
                other
                %lu runs
            
        
    
    

The keys of the top-level dictionary are simply the keys of the localized strings. Each dictionary then contains the `NSStringLocalizedFormatKey` entry that specifies the format string to be used for this localization. In order to substitute different values for different numbers, the format string syntax has been extended. So we can write something like `%#@lu_total_runs@` and then define a dictionary for the `lu_total_runs` key. Within this dictionary, we specify that this is a plural rule (setting `NSStringFormatSpecTypeKey` to `NSStringPluralRuleType`), designate the format specifier to use (in this case `lu`), and define the different values for the different plural variants. We can choose from “zero,” “one,” “two,” “few,” “many,” and “others.”

This is an extremely powerful feature. It can not only be used to account for the crazy amount of differences in plural forms for different languages, but also to use different wording for different numbers.

But we can go even further than that and define recursive rules. To make the output in our example nicer, there are a few cases we could provide customized strings for:


    Completed runs    Total Runs    Output
    ------------------------------------------------------------------
    0                 0%2B            No runs completed yet
    1                 1             One run completed
    1                 2%2B            One of x runs completed
    2%2B                2%2B            x of y runs completed

We can achieve this using the string dictionary file without writing a single line of code. The strings dictionary for this example looks like this:


    
    
    
    
        scope.%lu out of %lu runs
        
            NSStringLocalizedFormatKey
            %1$#@lu_completed_runs@
            lu_completed_runs
            
                NSStringFormatSpecTypeKey
                NSStringPluralRuleType
                NSStringFormatValueTypeKey
                lu
                zero
                No runs completed yet
                one
                One %2$#@lu_total_runs@
                other
                %lu %2$#@lu_total_runs@
            
            lu_total_runs
            
                NSStringFormatSpecTypeKey
                NSStringPluralRuleType
                NSStringFormatValueTypeKey
                lu
                one
                run completed
                other
                of %lu runs completed
            
        
    
    

Strings returned from `localizedStringForKey:value:table:` that were instantiated from a `.stringsdict` entry are proxy objects carrying the additional information contained in the strings dictionary file. This information is preserved through `copy` and `mutableCopy` calls. However, once you mutate such a string object, the additional localization information is lost. Please see the [Foundation release notes of OS X 10.9][11] for further details.

## Upper and Lower Casing

Whenever you need to uppercase or lowercase a string that should be presented to the user, you should use the localized versions of those `NSString` methods: `lowercaseStringWithLocale:` and `uppercaseStringWithLocale:`.

When using these methods you have to pass the [locale][12] that should be used to perform the uppercasing or lowercasing in a localized fashion. When using one of the `NSLocalizedString` macros, we don’t have to worry about this, since it will automatically do the right thing, also in terms of falling back to the default language if the user’s preferred language is not available.

To ensure a consistent appearance of the user interface, it can be a good idea to use the locale that is used to localize the rest of the interface. Please see the section below about [choosing the right locale][13].

## Localized File Path Names

In general, you should always use `NSURL` to represent file paths. Once you do this, it’s very easy to retrieve the localized file name:


    NSURL *url = [NSURL fileURLWithPath:@"http://www.objc.io/Applications/System Preferences.app"];
    NSString *name;
    [url getResourceValue:&name forKey:NSURLLocalizedTypeDescriptionKey error:NULL];
    NSLog(@"localized name: %@", name);

    // output: System Preferences.app

That’s exactly what we’d expect on an English system, but once we switch, for example, to Arabic, System Preferences now is called تفضيلات النظام.app.

Retrieving a file’s localized name like this also respects the user’s Finder setting of whether the file extension should be hidden or not. If you need to show which type the file is, you can use ask for the `NSURLLocalizedTypeDescriptionKey` in the same way.

Localized file names are only for user interface purposes, and cannot be used to actually access the file resource. Please see [Daniel’s article about common string patterns][9] to read more about working with file paths.

## Formatters

There is a huge variety of how numbers and dates are formatted in different languages. Luckily Apple has already done the heavy lifting for us, so that we only have to remember to always use the [`NSNumberFormatter`][14] or [`NSDateFormatter`][15] classes whenever we want to display a number or date in the user interface.

Keep in mind that number and date formatters are mutable objects and not thread-safe.

### Formatting Numbers

Number formatter objects are highly configurable, but mostly you will want to use one of the predefined number styles. After all, the main advantage of using a number formatter is not having to worry about the specifics of a certain language anymore.

Using the different number styles on my machine, which has its number format set to German, produces the following result for the number `2.5`:


    Number Style                        Result for German     Result for Arabic
    ---------------------------------------------------------------------------
    NSNumberFormatterNoStyle            2                          ٢
    NSNumberFormatterDecimalStyle       2,5                        ٢٫٥
    NSNumberFormatterCurrencyStyle      2,50 €                     ٢٫٥٠٠ د.أ.‏
    NSNumberFormatterScientificStyle    2,5E0                      ٢٫٥اس٠
    NSNumberFormatterPercentStyle       250 %                      ٢٥٠٪
    NSNumberFormatterSpellOutStyle      zwei Komma fünf            إثنان فاصل خمسة

There is a nice thing in the output of the number formatter you cannot see in this table: in the currency and percent number styles, it inserts not a normal space before the currency or percent symbol, but a non-breaking one. This way the number will never be separated from its symbol by a line break. (And isn’t the spell-out style cool?)

By default, a number formatter will use the system setting to determine the locale. As we already mentioned with uppercasing and lowercasing above, it is important to configure the number formatter with the right locale to match the rest of the user interface. Read more on this [below][13].

### Formatting Dates

As with numbers, date formatting is very complex and we really should hand this job over to `NSDateFormatter`. With date formatters, you can choose from a variety of different [date and time styles][16] that will come out correctly for all locales. Again, make sure to [choose the right locale][13] matching the rest of the interface.

Sometimes you might want to show a date in a way that’s not possible with the default date and time styles of `NSDateFormatter`. Instead of using a simple format string (which will most likely yield wrong results in many other languages), `NSDateFormatter` provides the `%2BdateFormatFromTemplate:options:locale:` method for this purpose.

For example, if you want to show only the day of the month and the short form of the month, there is no default style that provides this. So let’s build our own formatter:


    NSString *format = [NSDateFormatter dateFormatFromTemplate:@"dMMM"
                                                       options:0
                                                        locale:locale];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];

    NSString *output = [dateFormatter stringFromDate:[NSDate date]];
    NSLog(@"Today's day and month: %@", output);

The big advantage of this method compared to using plain format strings is that the result will still be correct in different locales. For example, in US English we would expect the date to be formatted as “Feb 2,” whereas in German it should be “2. Feb.” `dateFormatFromTemplate:options:locale:` returns the correct format string based on the template we specify and the locale argument. For US English it returns “MMM d,” and for German “d. MMM.”

For a full reference of the format specifiers that can be used in the template string, please refer to the date format patterns in the [Unicode locale data markup language][17] documentation.

### Cache Formatter Objects

Since creating a formatter object is a rather expensive operation, you should cache it for future use:


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

There’s one gotcha with this though: we need to invalidate this cached formatter object if the user changes his or her locale. In order to do this, we have to register for the `NSCurrentLocaleDidChangeNotification`:


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

Interesting side note from Apple’s [data formatting guide][18]:

> In theory you could use an auto-updating locale (autoupdatingCurrentLocale) to create a locale that automatically accounts for changes in the user’s locale settings. In practice this currently does not work with date formatters.

So we have to use the locale change notification for now. That’s quite a bit of code for “just” formatting dates. But if you use the formatter object very often, it can be worth the effort. As always, measure and improve.

Also, remember that formatters are not thread-safe. According to Apple’s documentation, you can use them from multiple threads, but you must not mutate them from multiple threads. If you would want to consolidate all formatters you use in a central object in order to make their invalidation on locale change easier, you would have to make sure that you create and update them only on one queue. For example, you could use a concurrent queue and `dispatch_sync` onto it to get the formatters, and use `dispatch_barrier_async` to update the formatters when the locale changes.

### Parsing User Input

Number and date formatters cannot only generate localized strings from number or date objects respectively – they can also work the other way round. Whenever you need to handle user input of numbers or dates, you should use the appropriate formatter class to parse it. That’s the only way to make sure that the input will be parsed correctly according to the user’s current locale.

#### Parsing Machine Input

While formatters are great to parse user input, they’re not the best choice to parse machine input where you know the format up front. The power of date and number formatters that are required to parse user input correctly in all locales comes with a performance cost.

For example, if you receive a lot of date strings from a server and you have to convert them into date objects, a date formatter is not the best tool for the job. As per Apple’s [date formatting guide][19] it’s much more efficient to use the UNIX `strptime_l(3)` function for fixed-format, non-localized dates:


    struct tm sometime;
    const char *formatString = "%Y-%m-%d %H:%M:%S %z";
    (void) strptime_l("2014-02-07 12:00:00 -0700", formatString, &sometime, NULL);
    NSLog(@"Issue #9 appeared on %@", [NSDate dateWithTimeIntervalSince1970: mktime(&sometime)]);
    // Output: Issue #9 appeared on 2014-02-07 12:00:00 -0700

Since even `strptime_l` is aware of the user’s locale, make sure to pass in `NULL` as the last parameter to select the standard POSIX locale. For the available format specifiers, please refer to the [`strftime` man page][20].

## Debugging Localized Strings

Making sure that everything looks right and works correctly becomes increasingly more difficult the more languages you support in your app. However, there are a few helpful user default options and tools that can help you with that.

You can use the `NSDoubleLocalizedStrings`, `AppleTextDirection`, and `NSForceRightToLeftWritingDirection` options to make sure your layout doesn’t break with longer strings or right-to-left languages. `NSShowNonLocalizedStrings` and `NSShowNonLocalizableStrings` help with finding strings where a localization is missing or which have not been specified using the string localization macros at all. (All these are user defaults options that can be set programmatically or as launch argument in Xcode’s Scheme Editor, e.g. `-NSShowNonLocalizedStrings YES`.)

Furthermore, there are two user defaults options that control the preferred language and the locale: `AppleLanguages` and `AppleLocale`. You can use those to start an app using a different preferred language or locale than current system settings, which can save you a lot of switching forth and back during testing. `AppleLanguages` takes an array of [ISO-639][21] language codes, for example:


    -AppleLanguages (de, fr, en)

`AppleLocale` takes a locale identifier as argument as defined by the [International Components for Unicode][22], for example:


    -AppleLocale en_US

or


    -AppleLocale en_GR

If your translated strings are not showing up, you might want to run the [plutil][23] command with its `-lint` option to check your string files for syntax errors. For example, if you forget a semicolon at the end of a line, it will warn you like this:


    $ plutil Localizable.strings
    2014-02-04 15:22:40.395 plutil[92263:507] CFPropertyListCreateFromXMLData(): Old-style plist parser: missing semicolon in dictionary on line 6. Parsing will be abandoned. Break on _CFPropertyListMissingSemicolon to debug.
    Localizable.strings: Unexpected character / at line 1

Once we fix this error, it signals to us that all is well:


    $ plutil Localizable.strings
    Localizable.strings: OK

Although it’s not about debugging, there’s another really helpful trick for multi-language apps: you can automatically generate your app screenshots (on iOS) for multiple languages. Since the app can be scripted using UIAutomation and the language can be set on launch using the `AppleLanguages` user defaults setting, the whole process can be automized. Check [this project on GitHub][24] for more details.

## Choosing the Right Locale

When using date and number formatters or methods like `-[NSString lowercaseStringWithLocale:]`, it’s important that you use the correct locale. If you want to use the user’s systemwide preferred language, you can retrieve the corresponding locale with [`NSLocale currentLocale]`. However, be aware that this might be a different locale than the one your app is running in.

Let’s say the user’s system is set to Chinese, but your app only supports English, German, Spanish, and French. In this case, the string localization will fall back to the default language, e.g. English. If you now use [`NSLocale currentLocale]` or formatter class methods that don’t specify any locale, like `%2B[NSNumberFormatter localizedStringFromNumber:numberStyle:]`, your data will formatted according to the Chinese locale, while the rest of the interface will be in English.

Ultimately it comes down to your judgment of what makes the most sense for a specific use case, but you might want the app’s interface to be localized consistently in some cases. In order to retrieve the locale your app is currently using instead of the user’s systemwide locale, we have to ask the main bundle for its preferred language:


    NSString *localization = [NSBundle mainBundle].preferredLocalizations.firstObject;
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:localization];

With this locale at hand, we can, for example, localize a date in a way that matches the current string localization of the interface:


    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = locale;
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.timeStyle = NSDateFormatterNoStyle;
    NSString *localizedDate = [formatter stringFromDate:[NSDate date]];

 

## Conclusion

When localizing strings, never assume that anything that works in your native language will work in other languages as well. The frameworks provide a lot of powerful tools to abstract away the complexities of different languages; we just have to use them consistently. It’s a little bit of extra work, but it will pay off big time once you start localizing your app into multiple languages.




* * *

[More articles in issue #9][25]

  * [Privacy policy][26]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-9/index.html
   [5]: https://twitter.com/floriankugler
   [6]: https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/genstrings.1.html
   [7]: http://gigliwood.com/blog/to-hell-with-utf-16-strings.html
   [8]: http://en.wikipedia.org/wiki/ASCII
   [9]: http://www.objc.io/issue-9/working-with-strings.html
   [10]: http://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html
   [11]: https://developer.apple.com/library/Mac/releasenotes/Foundation/RN-Foundation/index.html
   [12]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSLocale_Class/Reference/Reference.html
   [13]: http://www.objc.io#choosing-the-right-locale
   [14]: https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/Classes/NSNumberFormatter_Class/Reference/Reference.html
   [15]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSDateFormatter_Class/Reference/Reference.html
   [16]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSDateFormatter_Class/Reference/Reference.html#//apple_ref/doc/c_ref/NSDateFormatterStyle
   [17]: http://www.unicode.org/reports/tr35/tr35-25.html#Date_Format_Patterns
   [18]: https://developer.apple.com/library/mac/documentation/cocoa/conceptual/DataFormatting/Articles/dfDateFormatting10_4.html#//apple_ref/doc/uid/TP40002369-SW10
   [19]: https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/DataFormatting/Articles/dfDateFormatting10_4.html#//apple_ref/doc/uid/TP40002369-SW1
   [20]: https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man3/strftime.3.html#//apple_ref/doc/man/3/strftime
   [21]: http://www.loc.gov/standards/iso639-2/php/code_list.php
   [22]: http://userguide.icu-project.org/locale
   [23]: https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/plutil.1.html
   [24]: https://github.com/jonathanpenn/ui-screen-shooter
   [25]: http://www.objc.io/issue-9
   [26]: http://www.objc.io/privacy.html
