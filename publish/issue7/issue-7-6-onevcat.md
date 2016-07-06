当我们处理自然语言（相对于程序语言而言）的时候会遇到一项挑战，即涵义模棱两可。程序语言是被设计成为有且只有一个可能解释的语言，而人类语言可能由于模糊性和不确定性衍生出很多问题。这是由于有时候你并不想确切地告诉别人你对某事物的想法。在社交场合这完全没有问题，但是当你试图使用计算机来处理人类语言的话，就会非常痛苦。

词法标识（token）就是一个简单的例子。程序语言的词法分析对于标识表示什么，它是什么类型（语句分隔符，标识符，保留关键字等等）是什么有着明确的规则。而自然语言则远不能如此清晰可辩。*can’t* 是一个还是两个标识？并且根据你做出的判断，*cannot* 或者 *can not* 这两个应该是相同意思的词又各是几个标识呢？很多复合词都可以写成一个词（比如：*bookshelf*），或者两个词（比如：*lawn mower*），甚至还可以用连字符来连接（比如：*life-cycle*）。有些字符 （比如说连字符或者右肩单撇号），可以有很多种解释，而如何选择正确字符往往取决于上下文语言环境（撇号在一个单词的最后是表示所有格符号还是后单引号？）

句子的情况同样不怎么好：如果简单认为句号是用来结束一个句子的话，在我们使用缩写或是序数的时候就悲剧了。虽然通常情况下，我们是可以解决这个问题的，但是对有些句子而言，除非将整个段落彻底分析，否则无法真正确定这些句子的意思。我们人类甚至也无法有意识地考虑这些问题。

不过我们希望能够处理人类语言，因为在跟软件交流的时候，使用人类语言对用户更加友好。我们更愿意直接告诉计算机要做什么，让计算机为我们分析报纸文章，并对我们感兴趣的新闻做个总结，而不是通过敲击键盘或者点击小小的按钮（或者在小小的虚拟键盘上打字）来让计算机为我们做这些事。其中有些还在我们的能力范围之外（至少在苹果为我们提供与 Siri 交互的  API 之前）。但是有些已经成为可能，那就是 `NSLinguisticTagger`。

`NSLinguisticTagger` 是 Foundation 框架中命名极为不当的类之一，这是因为它远远不止是一个小小的词性 tagger，而是集词法分析，分词器，命名实体识别及词性标注为一体的类。换句话说，它几乎可以满足你处理某些计算机语言处理的全部要求。

为了展示 `NSLinguisticTagger` 类的用法，我们会开发一个灵活的工具用来搜索。我们有一个充满了文本（比如新闻，电邮，或者其他的任意文本）的集合，然后我们输入一个单词，这个单词将返回所有包含这个单词的句子。我们会忽略功能词（比如 *the*，*of* 或者 *and*），因为它们在这个语言环境中太过于常见，没有什么用处。我们目前要实现的是第一步：从一个单独文件中提取相关单词。由此可以迅速地扩展到提供完整功能。

[GitHub](https://github.com/objcio/issue-7-linguistic-tagging) 上有源代码和样本文本。这是《卫报》上一篇关于中英贸易的文章。当用软件分析这份文本时，你会发现，它并不是总是运行良好，不过，出现运行故障完全正常：人类语言和任何正式语言都不同，人类语言凌乱复杂，无法简单划归到整齐划一的规则系统。很多理论问题（哪怕就像词性一样基础的问题）在某种程度上是无法解决的，这是由于我们仍然对如何才能最好地描述语言还所知甚少。比如说，词的分类是以拉丁语为依据的，但这并不意味着就必定适合英语。它们充其量只是大概近似而已。不过从很多实际的目的来看，这样就已经足够了，不需要让人怎么担心了。

## 标签体系 (Tag Schemes)

注释和标记文本的核心方法就是标签体系的核心方法。以下是几个可用的标签体系：

* `NSLinguisticTagSchemeTokenType`
* `NSLinguisticTagSchemeLexicalClass`
* `NSLinguisticTagSchemeNameType`
* `NSLinguisticTagSchemeNameTypeOrLexicalClass`
* `NSLinguisticTagSchemeLemma`
* `NSLinguisticTagSchemeLanguage`
* `NSLinguisticTagSchemeScript`

`NSLinguisticTagger` 实例扫描文本中的所有条目，并调用一个包含被请求的标签体系值的 block。最基础的是 `NSLinguisticTagSchemeTokenType`：词，标点，空格，或是“其他”。我们可以使用这个来识别哪些是真正的词，那么我们在应用程序中就可以简单地忽略其他那些不是有效词的语素。`NSLinguisticTagSchemeLexicalClass` 和词性有关，是一组非常基础的标签（就严格意义上的语言分析而言，这组标签还远远不够精细），我们可以使用这组标签来分辨我们想要的实词（名词，动词，形容词，副词）和我们想忽略的虚词（连词，介词，冠词等等）。在 `NSLinguisticTagger` 类的[文档](https://developer.apple.com/library/mac/documentation/cocoa/reference/NSLinguisticTagger_Class/Reference/Reference.html)中写明了全套可能值。

`NSLinguisticTagSchemeNameType` 是指命名实体识别：我们可以知道一个词是不是表示人物，地点或者组织。同样的，这相对于自然语言的处理而言是相当基本，但却非常有用的，比如说你想搜索一个特定的人物或者地点。还有一种潜在的应用是“给我一份文本中所提到的所有政治家的名录”，你可以浏览这份文本中的人名，然后查阅数据库（比如维基）来核对他们是否确实是政治家。这也可以跟 lexical 类相结合，因为这往往包含一个分类叫做“名字”。

`NSLinguisticTagSchemeLemma` 是词汇的标准形式，或者说是其基本形式。对英语而言，这不是什么大问题，不过对于其它语言而言却重要得多。原型基本上就是你在词典中查的到的那个形式。比如说，*tables* 是一个复数名词，它的基本形式是单数的 *table*。同样的，动词 *running* 是由 *run* 变形而来的不定式。如果你想要以同样的方式处理各种词类的变形，使用原形就非常有用，事实上这也是我们要为我们的示例应用程序所做的 (因为这可以有助于保持索引不过于庞大)。

`NSLinguisticTagSchemeLanguage` 和我们所使用的语言相关。如果你使用iOS（截至iOS7），目前只能处理英语。使用OS X（截至10.9 / Mavericks）你可以稍微多几种语言可以选择。`+[NSLinguisticTagger availableTagSchemesForLanguage:]` 方法为我们列举了对于给定语言的所有可用体系。对于在 iOS 中对应语言数量限制的原因很可能是资源文件要占用大量空间。在笔记本或者台式电脑上不是什么大问题，但是在手机或者平板上的话就不太妙了。

`NSLinguisticTagSchemeScript` 是书写体系，比如拉丁字母 (Latin)，西里尔字母 (Cyrillic) 等等。对于英语，我们将使用拉丁字母。如果你知道你将处理哪种语言，使用 `setOrthography` 方法可以改善标签的结果，特别对相对较短的字符而言更是如此。

## 标签选项

目前我们已经知道 `NSLinguisticTagger` 可以为我们识别什么了，我们需要告诉它我们想要什么，以及我们想如何获得。这里有几个可以定义 tagger 行为的选项，它们都是 `NSUInteger` 类型的，并且可以使用位运算 OR 组合使用。

第一个选项是“省略单词”，除非你只想看标点或者其它非词类，否则这个选项毫无意义。比较有用的是下面的三个选项：“省略标点（omit punctuation）”，“省略空格（omit whitespace）”以及“省略其他（omit other）”。除非你想要对文本做全面语言分析，否则你基本上只会对单词感兴趣，而对其中的逗号句号则兴趣不大。有了这些选项，就可以轻轻松松让 tagger 对单词作出限制，再也不用挂虑在心。最后一个选项是“连接名字（join names）”，因为名字有时不仅仅是一个标识。这个选项会将它们结合在一起，作为一个独立的语言单位来处理。这个选项可能不会总是用得上，但是确实非常有用。举个例子，在样本文本中，字符串“Owen Patterson”被识别为一个名称，并且作为一个独立的语言单位被返回。

## 处理架构

程序会给一定数量的文本在独立文件中建立索引（我们假设是使用UTF-8编码）。我们将使用一个 `FileProcessor` 类来处理一个单独文件，将文件内容分为一个一个单词，再把这些单词传递给另一类来进行处理。后一个类将实现 `WordReceiver` 接口，其中包括一个方法：

    -(void)receiveWord:(NSDictionary*)word

我们不是使用 `NSString` 来表示单词，而是使用字典，这是因为一个单词会有很多属性，包括实际标识，词性或名称类型，原型，所在句子的数目，句子中的位置等。为了建立索引，我们还想储存文件名。调用 `FileProcessor` 的这个方法：

    - (BOOL)processFile:(NSString*)filename

将触发分析，如果一切进行顺利的话，返回 `YES`，在出现错误的时候返回 `NO`。它首先由文件创建一个 `NSString`，然后将其传递给一个 `NSLinguisticTagger` 实例来处理。

`NSLinguisticTagger` 主要做的是的在一个 `NSString` 中进行扫描并对寻找到的每一个元素调用 block。为了稍作简化，我们首先将文本分解为一个个的句子，然后分别扫描每一个句子。这样比较容易追踪句子的 ID。至于标签，我们会处理大量的 `NSRange`，它们可以被用来界定源文件中文本的注解。我们从在第一个句子范围内创建一个搜索范围开始，并使用其在最大程度上获得初始语句的标签。

    NSRange currentSentence = [tagger sentenceRangeForRange:NSMakeRange(0, 1)];

一旦句子处理结束，就检查是否成功完成全部的文本，或者是否还有更多的句子等待处理：

    if (currentSentence.location + currentSentence.length == [fileContent length]) {
        currentSentence.location = NSNotFound;
    } else {
        NSRange nextSentence = NSMakeRange(currentSentence.location + currentSentence.length + 1, 1);
        currentSentence = [tagger sentenceRangeForRange:nextSentence];
    }

如果已经到了文本的末尾，我们将使用 `NSNotFound` 来对 `while` 循环发出终止信号。如果我们使用一个超出文本之外的范围，`NSLinguisticTagger` 将抛出一个异常并且直接崩溃。

句子处理循环中的主要方法调用如下：

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
            tokenPosition++;
        }];
    }

我们让 tagger 处理 `NSLinguisticTagSchemeNameTypeOrLexicalClass`，指定一组选项（连接名字，省略标点和空格）。然后我们获取这个标签，以及搜索到的每一项条目的范围，并进一步检索信息。标识（token）是字符串一部分，仅仅由字符范围来描述。lemma 是基本形式，如果不可能用的这个值会是 `nil`，所以我们需要做检查，并使用标识字符串作为候补值。一旦收集到这个信息，我们就可以将其打包到一个字典中，然后发送给 delegate 进行处理。

在我们的示例应用中，我们仅仅输出了我们接收到的单词，但是我们在这里基本上可以做任何我们想做的一切。为了实现搜索，我们可以过滤掉除了名词，动词，形容词，副词和名字以外的所有词，并且在索引数据库中储存这些单词的位置。使用原形，而不使用标识值，可以使我们合并各种词的变形 (*pig* 和 *pigs*)，这可以保持索引不过于庞大，并且与仅只匹配实际标识词相比，也可以检索出更相关的词。请记住，你可能还要将所有查询按照原形变化进行归类，否则，搜索 *pigs* 的话将不会返回任何结果。

为了更加真实，我在样本文本头部信息中加进了一些基本 HTML 标签，比如确定标题，署名，日期。在通过 tagger 运行的时候出现一个问题，即 `NSLinguisticTagger` 是不知道关于 HTML 的东西的，并试图将这些 HTML 标记当做文本来处理。下面是最前面的三个检索词。


    {
        filename = "/Users/oliver/tmp/guardian-article.txt";
        lemma = "<";
        position = 0;
        postag = Particle;
        sentence = 0;
        token = "<";
    }
    {
        filename = "/Users/oliver/tmp/guardian-article.txt";
        lemma = h1;
        position = 1;
        postag = Verb;
        sentence = 0;
        token = h1;
    }
    {
        filename = "/Users/oliver/tmp/guardian-article.txt";
        lemma = ">";
        position = 2;
        postag = Adjective;
        sentence = 0;
        token = ">";
    }

不仅仅是标签被分成了几个部分，被当做词来处理，而且还得到了奇怪和完全错误的标签。所以，如果你在处理包含标记的文件，最好先将其过滤出来。或许，你想要识别出标签，并返回覆盖标签区域的 `NSRange`，而不是像我们之前处理示例应用一样将整个文本分成一个个句子。或者说，如果存在内嵌标签（比如加粗，斜体，超链接），将标签全部剔除出来会更好些。

## 结果

就算是用 tagger 来处理通用语言，其表现也出人意料的优秀。如果你仅仅处理某一个领域（比如技术文本）的话，你可以做出一些在处理不受限制的文本时无法做到的假设。但是苹果的 tagger 必须在无法预知会遇到什么的情况下也能工作，鉴于如此，它偶尔也会出错，不过相对来说是非常少的。很显然，很多名称无法识别，比如说 *Chengdu* 这样的地名。但另一方面，文本中大多数人名的处理都是非常不错的。由于某些原因，日期（*Wednesday 4 December 2013 10.35 GMT*）被当做了人名来处理，可能是来源于鲁宾逊•克鲁索的命名习惯吧。环境大臣 *Owen Patterson* 可以被识别出来，但是，一般被认为更加重要的首相 *David Cameron* 却没有被识别出来，尽管 *David* 是个更为常见的名字。

这是概率 tagger 的问题：有时候很难理解为什么某些词以特定的方式被加上标签。也没有什么像钩子一样的东西可以挂靠 tagger，可以让你提供比如说已知的地点，人物或者组织的名称列表。你只能用默认设置进行处理。因此，最好使用大量数据来测试那些带有 tagger 的应用程序，通过观察结果，你可以大概知道哪些可以正常运行，哪些会遇到问题。

## 概率

有很多种方法来实现词性标签：两个主要的途径，一个是规则性的，一个是随机性。两种途径都有一套相当庞大的规则来告诉你，形容词的后面是名词，而不是冠词，或者有一个概率矩阵告诉你某一个特定的标签会出现在一个特定的语言环境中的可能性有多大。你也可以使用基于概率性的模型，同时添加一些规则来修正反复出现的典型错误，这就是所谓的混合 tagger。由于为不同语言开发规则集比自动学习随机语言模型的成本要高得多，所以我猜测 `NSLinguisticTagger` 应该是基于完全的随机模型。这个实现细节也可以从下面的方法中窥探一二：

    - (NSArray *)possibleTagsAtIndex:(NSUInteger)charIndex 
                              scheme:(NSString *)tagScheme 
                          tokenRange:(NSRangePointer)tokenRange 
                       sentenceRange:(NSRangePointer)sentenceRange 
                              scores:(NSArray **)scores

这说明了一个事实，那就是有时候（其实是大多数时候）会出现多个可能的标签值，tagger 必须判断哪个可能是错误的。使用这个方法，你可以获得一份选项列表和概率得分。得分最高的词则被 tagger 选中，但是如果你想要创建一套基于规则的后处理来改善 tagger 工作，你依然可以访问得分第二的词或者其他候选项。

对于这个方法要提高警惕，其中有个 bug，实际上它并没有返回任何的分数。不过在 OS X 10.9 / Mavericks 中这个 bug 已被修复。所以，如果你需要支持 OS X 10.9 / Mavericks 之前的版本，会提示你无法使用这个方法。顺带一提，在 iOS 7 中这个方法可以良好运行。

下面是几个 *When is the next train…:* 的输出案例：

<table><thead><tr><th style="text-align: left;padding-right:1em;">When</th><th style="text-align: left;padding-right:1em;">is</th><th style="text-align: left;padding-right:1em;">the</th><th style="text-align: left;padding-right:1em;">next</th><th style="text-align: left;padding-right:1em;">train</th></tr></thead><tbody><tr><td style="text-align: left;padding-right:1em;">Pronoun, 0.9995162</td><td style="text-align: left;padding-right:1em;">Verb, 1</td><td style="text-align: left;padding-right:1em;">Determiner, 0.9999986</td><td style="text-align: left;padding-right:1em;">Adjective, 0.9292629</td><td style="text-align: left;padding-right:1em;">Noun, 0.8741992</td>
</tr><tr><td style="text-align: left;padding-right:1em;">Conjunction, 0.0004337671</td><td style="text-align: left;padding-right:1em;"></td><td style="text-align: left;padding-right:1em;">Adverb, 1.344403e-06</td><td style="text-align: left;padding-right:1em;">Adverb, 0.0636334</td><td style="text-align: left;padding-right:1em;">Verb, 0.1258008</td>
</tr><tr><td style="text-align: left;padding-right:1em;">Adverb, 4.170838e-05</td><td style="text-align: left;padding-right:1em;"></td><td style="text-align: left;padding-right:1em;"></td><td style="text-align: left;padding-right:1em;">Preposition, 0.007003677</td><td style="text-align: left;padding-right:1em;">
</td></tr><tr><td style="text-align: left;padding-right:1em;">Noun, 8.341675e-06</td><td style="text-align: left;padding-right:1em;"></td><td style="text-align: left;padding-right:1em;"></td><td style="text-align: left;padding-right:1em;">Noun, 0.0001000525</td><td style="text-align: left;padding-right:1em;">
</td></tr></tbody></table>

正如你所见，在这个例子中到现在为止，正确的 tag 拥有最高的概率。对于大多数应用程序而言，你可以保持程序简单，并认可 tagger 所提供的标签，而不对概率进行深究。不过你得承认 tagger 偶然也是会出错的，而你也可以访问到这些识别结果，并做出相应处理。 当然，如果你不亲自检查的话，你就不会知道 tagger 什么时候会出错。然而，其中一个线索是概率差：如果概率非常接近（和上面的例子不同），说不定就表示可能出错了。

## 结论

处理自然语言是很困难的，苹果给我们提供了一个非常好的工具，这个工具可以简便地支持绝大多数使用情况。当然，它也不是完美无缺的，即使最先进的语言处理工具也不是完美无缺的。iOS 目前只支持英语，不过随着技术改善，以及如果有足够大的内存来储存（毫无疑问会很大的）语言模型的话，这将有所改变。在此之前，我们会受到一些限制。不过还是有很多方法可以给应用程序添加语言支持。在文本编辑器中突出动词，理解用户键入的内容，或者处理外部数据文件等工作还是很简单的，`NSLinguisticTagger` 可以帮助你做到这一点。

---

 

原文 [Linguistic Tagging](http://www.objc.io/issue-7/linguistic-tagging.html)
