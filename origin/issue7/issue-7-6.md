[Source](http://www.objc.io/issue-7/linguistic-tagging.html "Permalink to Linguistic Tagging - Foundation - objc.io issue #7 ")

# Linguistic Tagging - Foundation - objc.io issue #7 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# Linguistic Tagging

[Issue #7 Foundation][4], December 2013

By [Oliver Mason][5]

One of the main challenges when handling natural language (as opposed to programming languages) is ambiguity. While programming languages are designed to have one and only one possible interpretation, human languages derive a lot of their power from being vague and unspecific, because sometimes you don’t want to tell someone exactly how you feel about something. This is perfectly fine for social interaction, but it’s a real pain when trying to process human language with a computer.

A straightforward example of this is the use of tokens. A tokeniser for a programming language has unambiguous rules about what constitutes a token, and what type it is (statement separator, identifier, reserved keyword, etc.). In languages, this is far from obvious. Is _can’t_ one token or two? And, depending on your answer, what about _cannot_ or _can not_, which presumably should be the same? Various compound words can be written as one word (_bookshelf_), two words (_lawn mower_), or separated by a hyphen (_life-cycle_). Certain characters (such as the hyphen or the apostrophe) can have various interpretations, and choosing the correct one often depends on context (‘is this apostrophe at the end of the word a possessive marker or a closing single quote from the beginning of the sentence?’).

Sentences are equally bad: Simply assuming a full stop terminates a sentence fails miserably when we use abbreviations or ordinal numbers. Often it is possible to find a solution, but some sentences are genuinely impossible to identify unless we do a full-scale analysis of a paragraph. This is the stuff that we humans don’t even consciously think about.

But we want to be able to handle human language, as it is a more user-friendly way to interact with our software.Instead of tapping or clicking on small buttons (or typing on a tiny virtual keyboard) we would want to just tell the computer what to do, or get the computer to analyze newspaper articles for us, and give us a brief summary of the issues we are interested in. Some of this is still out of our reach (at least until Apple provides us with an API to interact with Siri), but some things are already possible now. Enter `NSLinguisticTagger`.

`NSLinguisticTagger` is one of the worst-named classes in Foundation, as it is far more than a mere part-of-speech tagger. It is a tokeniser, a sentence splitter, a named-entity recognizer, a lemmatizer, and a part-of-speech tagger. In other words, it is almost all you need to do some serious computational linguistics processing.

To illustrate the use of the `NSLinguisticTagger` class, we’ll develop a quick tool for finding stuff: we have a directory full of texts (such as news articles, or emails, or whatever else), and we’ll be able to type in a word which will return to us all the sentences that contain the word. We will ignore function words (such as _the_, _of_, or _and_), as they are too common to be useful in this context. What we will actually implement for now is the first step only: extracting the relevant words from a single file. But this can easily be extended to provide the full functionality.

The source code is on [GitHub][6], and a sample text is also included. This is a Guardian article on a trade deal between the UK and China. When running the text through the software, you will notice that it does not always work perfectly, but that is to be expected: human language, unlike any formal language, is messy and does not easily fit into clean systems of rules. A lot of theoretical issues (even as basic as parts of speech) are somewhat unsolved, as we still know very little about how languages can best be described. The word classes, for example, are based on Latin, but that does not mean they are necessarily appropriate for English. At best, they are a rough approximation. But for many practical purposes, it’s kind of good enough to not have to worry about it too much.

## Tag Schemes

The central approach to annotating or labeling text is that of the tag scheme. There are a number of available tag schemes:

  * `NSLinguisticTagSchemeTokenType`
  * `NSLinguisticTagSchemeLexicalClass`
  * `NSLinguisticTagSchemeNameType`
  * `NSLinguisticTagSchemeNameTypeOrLexicalClass`
  * `NSLinguisticTagSchemeLemma`
  * `NSLinguisticTagSchemeLanguage`
  * `NSLinguisticTagSchemeScript`

An `NSLinguisticTagger` instance iterates over all items in a text and calls a block with the requested tag-scheme values. The most basic one is the token type: word, punctuation, white space, or ‘other’. We can use this to identify which items are actual words, and for our application, we simply discard anything that is not a word. Lexical class refers to part of speech. This is a fairly basic set of labels (which would not be fine-grained enough for a proper linguistic analysis) which we can use to distinguish between the content words we want (nouns, verbs, adjectives, and adverbs) and the function words we want to ignore (conjunctions, prepositions, determiners, etc.). A full set of possible values is available from the [`NSLinguisticTagger` class documentation][7].

Name type refers to named entity recognition; we can see whether something refers to a person, a place, or an organization. Again, this is quite basic compared to what is used in natural language processing, but it can be very useful, if, for example, you want to search for references to particular people or locations. A potential use case for this could be “give me a list of all the politicians which are mentioned in this text,” where you scan the text for the names of persons, which you then look up in a database (such as Wikipedia) to check whether they are in fact politicians or not. This can also be combined with lexical class, as it often implies a class of ‘name’.

A lemma is the canonical form of a word, or its base form. This is not that much of an issue for English, but much more important for other languages. It is basically the form you would look up in a dictionary. For example, the word _tables_ is a plural noun, and its lemma is _table_, the singular. Similarly, the verb _running_ is transformed into the infinitive, _run_. This can be very useful if you want to treat variant forms in the same way, and that is actually what we will be doing for our sample application (as it helps keep the index size down).

Language concerns the language we are dealing with. If you’re on iOS, then you are currently (as of iOS 7) limited to English only. On OS X (as of 10.9/Mavericks) you have a slightly larger list available; the method `%2B[NSLinguisticTagger availableTagSchemesForLanguage:]` lists all schemes available for a given language. The likely reason for limiting the number on iOS is that the resource files take up a lot of space, which is fine on a laptop or desktop machine, but not so good on a phone or tablet.

Script is the writing system, such as Latin, Cyrillic, etc. For English, we’ll use ‘Latin.’ If you know what language you will be dealing with, setting it using the `setOrthography` method will improve tagging results, especially for relatively short segments.

## Tag Options

Now that we have identified what the `NSLinguisticTagger` can recognize for us, we have to tell it what we want and how we want it. There are a number of options which define the tagger’s behavior. These are all of type `NSUInteger` and can be combined with a bitwise OR.

The first one is ‘omit words,’ which seems somewhat pointless, unless you want to only look at punctuation or other non-words. More useful are the next three, ‘omit punctuation,’ ‘omit whitespace,’ and ‘omit other.’ Unless you want to do a full-scale linguistic analysis of the text, you will mainly be interested in the words, and not so much in all the commas and full-stops in between them. With these options, you can simply tell the tagger to suppress them and you will not have to worry about them any more. The final option, ‘join names,’ reflects that names can sometimes be more than one token. With this option chosen, they will be combined so you can treat them as a single unit. You might not always want to do this, but it can be useful. In the sample text, for example, the string “Owen Patterson” is recognized as a name, and is returned as a single unit.

## Processing Architecture

Our program will index a number of texts held in separate files (which we assume are encoded in UTF-8). We will have a `FileProcessor` class which handles a single file, chopping it up into words and passing those on to another class that does something with them. That latter class will implement the `WordReceiver` protocol, which contains a single method:


    -(void)receiveWord:(NSDictionary*)word

We represent the word not as an `NSString`, but as a dictionary, as it will have several attributes attached to it: the actual token, its part of speech or name type, its lemma, the number of the sentence it is in, and the position within that sentence. We also want to store the filename itself for indexing purposes. The `FileProcessor` is called with:


    - (BOOL)processFile:(NSString*)filename

which triggers the analysis and returns `YES` if all went well, and `NO` in case of an error. It first creates an `NSString` from the file, and then passes it to an instance of `NSLinguisticTagger` for processing.

The main `NSLinguisticTagger` method iterates over a range within an `NSString` and calls a block for every element that has been found. In order to simplify this a little, we will first split the text into sentences, and then iterate over each sentence separately. This makes it easier to keep track of sentence IDs. For the tagging, we will work a lot with `NSRange` items, which are used to demarcate a region in the source text that an annotation applies to. We start off by creating a range that has to be within the first sentence and use it to get the full extent of the initial sentence for tagging:


    NSRange currentSentence = [tagger sentenceRangeForRange:NSMakeRange(0, 1)];

Once we have finished dealing with this sentence, we check whether we have successfully completed our text, or whether there are more sentences available:


    if (currentSentence.location %2B currentSentence.length == [fileContent length]) {
        currentSentence.location = NSNotFound;
    } else {
        NSRange nextSentence = NSMakeRange(currentSentence.location %2B currentSentence.length %2B 1, 1);
        currentSentence = [tagger sentenceRangeForRange:nextSentence];
    }

If we have reached the end of the text, `NSNotFound` is used to signal to the `while` loop that it should terminate. If we use a range that is outside of the text, `NSLinguisticTagger` simply crashes ungraciously with an exception.

The main work then happens within a single method call in our sentence-processing loop:


    while (currentSentence.location != NSNotFound) {
        __block NSUInteger tokenPosition = 0;
        [tagger enumerateTagsInRange:currentSentence
                              scheme:NSLinguisticTagSchemeNameTypeOrLexicalClass
                             options:options
                          usingBlock:^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop)
        {
            NSString *token = [fileContent substringWithRange:tokenRange];
            NSString *lemma = [tagger tagAtIndex:tokenRange.location
                                          scheme:NSLinguisticTagSchemeLemma
                                      tokenRange: NULL
                                   sentenceRange:NULL];
            if (lemma == nil) {
                lemma = token;
            }
            [self.delegate receiveWord:@{
                @"token": token,
                @"postag": tag,
                @"lemma": lemma,
                @"position": @(tokenPosition),
                @"sentence": @(sentenceCounter),
                @"filename": filename
            }];
            tokenPosition%2B%2B;
        }];
    }

We ask the tagger for name types or lexical classes, given a set of options (joining names, omitting punctuation, and white space). We then get the tag and extent of each item found, and retrieve further information about it. The token is the actual part of the string, simply described by the character range. Lemma is the base form, which will be `nil` if unavailable, so we need to check for that and use the token string as a fallback. Once we have collected that information, we package it up in a dictionary and send it to our delegate for processing.

In our sample app, we simply log all the words we are receiving, but we can basically do whatever we want here. To allow searching, we could filter out all words that are not nouns, verbs, adjectives, adverbs, or names, and store their location in an index database. Using the lemma instead of the token value, we can conflate inflected variants (_pig_ and _pigs_), which will keep the index size smaller and also retrieve more relevant words than if we were only looking up the actual token. Bear in mind that you then probably also want to lemmatize any queries, otherwise a search of _pigs_ would turn up nothing.

To make it more realistic, I have added some basic HTML tags around the header information of the sample text, identifying the title, byline, and date, for example. Running this through the tagger comes up with the problem that `NSLinguisticTagger` is not aware of HTML, and tries to process the mark-up as text. Here are the first three received words:


    {
        filename = "http://www.objc.io/Users/oliver/tmp/guardian-article.txt";
        lemma = "";
    }

Not only are tags split into parts and treated as words, but they also get weird and completely wrong tags. So, if you are processing files that contain mark-up, it is best to filter that out first. Maybe, instead of splitting the whole text into sentences as we have done in the sample app, you would want to identify tags and return an `NSRange` that covers the area between tags. Or, strip them out completely, which is a better option if there are in-line tags (such as bold/italics or hyperlinks).

## Results

The performance of the tagger is surprisingly good, given that it has to work with general language. If you are only dealing with a restricted domain (such as texts about technology), you can make assumptions which are not possible when handling unrestricted texts. But Apple’s tagger has to work without any knowledge of what gets thrown at it, so given that, it makes comparatively few errors. Obviously, some names will not be recognized, such as the place name _Chengdu_. But on the other hand, the tagger copes fine with most of the names of people in the text. For some reason, the date (_Wednesday 4 December 2013 10.35 GMT_) is taken as a personal name, presumably based on Robinson Crusoe’s naming conventions. And while the Environment Secretary, _Owen Patterson_, is recognized, the arguably more important Prime Minister, _David Cameron_, is not, despite _David_ being a more common name.

That is one problem with a probabilistic tagger: it sometimes is hard to understand why words are tagged in a particular way. And there are no hooks into the tagger that would allow you, for example, to provide a list of known names of places, people, or organizations. You just have to make do with the default settings. For that reason, it is always best to test any application using the tagger with plenty of data, as by inspecting the results you can then get a feel for what works and what does not.

## Probabilities

There are several ways to implement a part-of-speech tagger: the two main approaches are rule-based and stochastic. Both have a (reasonably large) set of rules that tell you that after an adjective you can have a noun, but not a determiner, or you have a matrix of probabilities that gives you the likelihood for a particular tag occurring in a specific context. You can also have both a probabilistic base model which uses a few rules to correct recurring typical errors and a so-called hybrid tagger. As developing rule sets for different languages is much more effort than automatically training a stochastic language model, my guess is that `NSLinguisticTagger` is purely probabilistic. This implementation detail is also exposed by the:


    - (NSArray *)possibleTagsAtIndex:(NSUInteger)charIndex
                              scheme:(NSString *)tagScheme
                          tokenRange:(NSRangePointer)tokenRange
                       sentenceRange:(NSRangePointer)sentenceRange
                              scores:(NSArray **)scores

method. This accounts for the fact that sometimes (or most times, actually) there is more than one possible tag value, and the tagger has to make a choice which could potentially be wrong. With this method, you can get a list of the possible options, together with their probability scores. The highest-scoring word will have been chosen by the tagger, but here you can also have access to the second and subsequent alternatives, in case you do want to perhaps build a rule-based post-processor to improve the tagger’s performance.

One caveat with this method is that it did have a bug in it, in that it did not actually return any scores. This bug was fixed in OS X 10.9/Mavericks, so if you need to support, earlier versions be aware that you cannot use this method. It also works fine on iOS7.

Here is some example output for _When is the next train…_:

Whenisthenexttrain

Pronoun, 0.9995162
Verb, 1
Determiner, 0.9999986
Adjective, 0.9292629
Noun, 0.8741992

Conjunction, 0.0004337671
Adverb, 1.344403e-06
Adverb, 0.0636334
Verb, 0.1258008

Adverb, 4.170838e-05
Preposition, 0.007003677

Noun, 8.341675e-06
Noun, 0.0001000525

As you can see, the correct tag has, by far, the highest probability in this case. For most applications, you can thus keep it simple and just accept the tag provided by the tagger, without having to drill down into the probabilities. But it is good to know that you have access to them in case you want to accept that the tagger gets it wrong occasionally and have a backup. Of course, you will not know when the tagger does get it wrong without checking it yourself! One clue, however, could be the probability differential: if the probabilities are fairly close (unlike in the example above), then that might indicate a likely error.

## Conclusion

Processing natural language is hard, and Apple provides us with a decent tool that will easily support most use cases without being too complex to use. Of course, it is not perfect, but then so are none of the state-of-the-art language processing tools. While on iOS, currently only English is supported, that might change as specs improve and more memory becomes available for storing the (undoubtedly rather large) language models. Until then, we are a bit limited, but there are still loads of possibilities of adding language support to your applications, be it simply highlighting verbs in a text editor, making sense of typed user input, or processing external data files. `NSLinguisticTagger` will help you with that.




* * *

[More articles in issue #7][8]

  * [Privacy policy][9]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-7/index.html
   [5]: https://twitter.com/ojmason
   [6]: https://github.com/objcio/issue-7-linguistic-tagging
   [7]: https://developer.apple.com/library/mac/documentation/cocoa/reference/NSLinguisticTagger_Class/Reference/Reference.html
   [8]: http://www.objc.io/issue-7
   [9]: http://www.objc.io/privacy.html
