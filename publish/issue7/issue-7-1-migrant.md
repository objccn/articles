## NSArray, NSSet, NSOrderedSet 和 NSDictionary

基础集合类是每一个 Mac/iOS 应用的基本组成部分。在本文中，我们将对”老类” (`NSArray`, `NSSet`)和”新类” (`NSMapTable`, `NSHashTable`, `NSPointerArray`) 进行一个深入的研究，探索每一个的效率细节，并讨论其使用场景。

作者提示：本文包含一些参照结果，但它们并不意味着绝对精确，也没有进行均差分析及多次的测试。这些结果的目的是给出运行时统计，来帮助我们认识到通常来说用什么会更快。所有的测试基于 iPhone 5s，使用 Xcode 5.1b1 和 iOS 7.1b1 的 64 位程序。编译选项设置为 -Ofast 的发布构建。Vectorize loops 和 unroll loops (默认设置) 均设置为关闭。

## 大 O 符号，算法复杂度计量

首先，我们需要一些理论知识。效率通常用[大 O 符号](https://en.wikipedia.org/wiki/Big_O_notation)描述。它定义了一个函数的*极限特征*，通常被用于描绘其算法效率。O 定义了函数增长率的上限。不同量级的差异非常巨大，可以看看通常使用的 O 符号的量级以及它们所对应需要的操作数的关系。

![](/images/issues/issue-7/big-o-notation.png)

例如，如果用算法复杂度为 O(n^2)的算法对一个有 50 个元素的数组排序，需要 2,500 步的操作。而且，还有内部的系统开销和方法调用 — 所以是 250 0个操作的时间常量。 O(1)是理想的复杂度，代表着恒定的时间。[好的排序算法通常需要 O(n\*log n) 的时间](http://en.wikipedia.org/wiki/Sorting_algorithm#Comparison_of_algorithms)。

### 可变性

大多数的集合类存在两个版本:可变和不可变(默认)。这和其他大多数的框架有非常大的不同，一开始会让人觉得有一点奇怪。然而其他的框架现在也应用了这一特性：就在几个月前，[.NET公布了作为官方扩展的不可变集合](http://blogs.msdn.com/b/dotnet/archive/2013/09/25/immutable-collections-ready-for-prime-time.aspx)。

最大的好处是什么？**线程安全**。不可变的集合完全是线程安全的，可以同时在多个线程中迭代，避免各种转变时出现异常的风险。你的 API *绝不*应该暴露一个可变的集合。

当然从不可变到可变然后再回来是会有一定代价的 — 对象必须被拷贝两次，所有集合内的对象将被 retain/release。有时在内部使用一个可变的集合，而在访问时返回一个不可变的对象副本会更高效。

与其他框架不同的是，苹果没有提供一个线程安全的可变集合，`NSCache` 是例外，但它真的算不上是集合类，因为它不是一个通用的容器。大多数时候，你不会需要在集合层级的同步特性。想象一段代码，作用是检查字典中一个 key 是否存在，并根据检查结果决定设置一个新的 key 或者返回某些值 — 你通常需要把多个操作归类，这时线程安全的可变集合并不能对你有所帮助。

其实也有*一些*同步的，线程安全的可以使用的可变集合案例，它们往往只需要用几行代码，通过子类和组合的方法建立，比如这个 [`NSDictionary`](https://gist.github.com/steipete/7746843) 或这个 [`NSArray`](https://github.com/Cue/TheKitchenSync/blob/master/Classes/Collections/CueSyncArray.mm)。

需要注意的是，一些较新的集合类，如 `NSHashTable`，`NSMapTable` 和 `NSPointerArray` 默认就是可变的，它们并没有对应的不可变的类。它们用于类的内部使用，你基本应该不会能找到需要它们的不可变版本的应用场景。

## NSArray

`NSArray` 作为一个存储对象的有序集合，可能是被使用最多的集合类。这也是为什么它有自己的比原来的 `[NSArray arrayWithObjects:..., nil]` 简短得多的快速语法糖符号 `@[...]`。
`NSArray` 实现了 `objectAtIndexedSubscript:`，因为我们可以使用类 C 的语法 `array[0]` 来代替原来的 `[array objectAtIndex:0]`。

### 性能特征

关于 `NSArray` 的内容比你想象的要多的多。基于存储对象的多少，它使用各种内部的变体。最有趣的部分是苹果对于个别的对象访问并不保证 O(1) 的访问时间 — 正如你在 [CFArray.h CoreFoundation 头文件](http://www.opensource.apple.com/source/CF/CF-855.11/CFArray.h)中的关于算法复杂度的注解中可以读到的:

> 对于 array 中值的访问时间，不管是在现在还是将来，我们保证在任何一种实现下最坏情况是 O(lg N)。但是通常来说它会是 O(1) (常数时间)。线性搜索操作很可能在最坏情况下的复杂度为 O(N\*lg N)，但通常来说上限会更小一些。插入和删除操作耗时通常和数组中的值的数量成线性关系。但在某些实现的最坏情况下会是 O(N\*lg N) 。在数组中，没有对于性能上特别有优势的数据位置，也就是说，为了更快地访问到元素而将其设为在较低的 index 上，或者在较高的 index 上进行插入和删除，或者类似的一些做法，是没有必要的。

在测量的时候，`NSArray` 产生了一些[有趣的额外的性能特征](http://ridiculousfish.com/blog/posts/array.html)。在数组的开头和结尾插入/删除元素通常是一个 O(1)操作，而随机的插入/删除通常是 O(N) 的。

### 有用的方法

`NSArray` 的大多数方法使用 `isEqual:` 来检查对象间的关系(例如 `containsObject:` 中)。有一个特别的方法 `indexOfObjectIdenticalTo:` 用来检查指针相等，如果你确保在同一个集合中搜索，那么这个方法可以很大的提升搜索速度。
在 iOS 7 中，我们最终得到了与 `lastObject` 对应的公开的 `firstObject` 方法，对于空数组，这两个方法都会返回 `nil` — 而常规的访问方法会抛出一个 `NSRangeException` 异常。

关于构造（可变）数组有一个漂亮的细节可以节省代码量。如果你通过一个可能为 nil 的数组创建一个可变数组，通常会这么写:

    NSMutableArray *mutableObjects = [array mutableCopy];
    if (!mutableObjects) {
        mutableObjects = [NSMutableArray array];
    }

或者通过更简洁的[三元运算符](http://en.wikipedia.org/wiki/%3F:):

    NSMutableArray *mutableObjects = [array mutableCopy] ?: [NSMutableArray array];

更好的解决方案是使用`arrayWithArray:`，即使原数组为nil，该方法也会返回一个数组对象:

    NSMutableArray *mutableObjects = [NSMutableArray arrayWithArray:array];

这两个操作在效率上几乎相等。使用 `copy` 会快一点点，不过话说回来，这不太可能是你应用的瓶颈所在。提醒：不要使用 `[@[] mutableCopy]`。经典的`[NSMutableArray array]`可读性更好。

逆序一个数组非常简单：`array.reverseObjectEnumerator.allObjects`。我们使用系统提供的 `reverseObjectEnumerator`，每一个 `NSEnumerator` 都实现了 `allObjects`，该方法返回一个新数组。虽然没有原生的 `randomObjectEnumerator` 方法，你可以写一个自定义的打乱数组顺序的枚举器或者使用一些[出色的开源代码](https://github.com/mattt/TTTRandomizedEnumerator/blob/master/TTTRandomizedEnumerator/TTTRandomizedEnumerator.m)。

### 数组排序

有很多各种各样的方法来对一个数组排序。如果数组存储的是字符串对象，`sortedArrayUsingSelector:`是第一选择:

    NSArray *array = @[@"John Appleseed", @"Tim Cook", @"Hair Force One", @"Michael Jurewitz"];
    NSArray *sortedArray = [array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

下面的代码对存储数字的内容同样很好，因为 `NSNumber` 实现了 `compare:`:

    NSArray *numbers = @[@9, @5, @11, @3, @1];
    NSArray *sortedNumbers = [numbers sortedArrayUsingSelector:@selector(compare:)];

如果想更可控，可以使用基于函数指针的排序方法:

    - (NSData *)sortedArrayHint;
    - (NSArray *)sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))comparator
                              context:(void *)context;
    - (NSArray *)sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))comparator
                              context:(void *)context hint:(NSData *)hint;

苹果增加了一个方法来加速使用 `sortedArrayHint` 的排序。

>hinted sort 方式在你有一个已排序的大数组 (N 个元素) 并且只改变其中一小部分（P 个添加和删除，这里 P远小于 N）时，会非常有效。你可以重用原来的排序结果，然后在 N 个老项目和 P 个新项目进行一个概念上的归并排序。为了得到合适的 hint，你应该在原来的数组排序后使用 sortedArrayHint 来在你需要的时候(比如在数组改变后想重新排序时)保证持有它。
   
因为block的引入，也出现了一些基于block的排序方法:

    - (NSArray *)sortedArrayUsingComparator:(NSComparator)cmptr;
    - (NSArray *)sortedArrayWithOptions:(NSSortOptions)opts
                    usingComparator:(NSComparator)cmptr;

性能上来说，不同的方法间并没有太多的不同。有趣的是，基于 selector 的方式是最快的。[你可以在 GitHub 上找到测试用的源代码](https://github.com/steipete/PSTFoundationBenchmark):

> Sorting 1000000 elements. selector: 4947.90[ms] function: 5618.93[ms] block: 5082.98[ms].

### 二分查找

`NSArray` 从 iOS 4 / Snow Leopard 开始内置了[二分查找](http://en.wikipedia.org/wiki/Binary_search_algorithm)

    typedef NS_OPTIONS(NSUInteger, NSBinarySearchingOptions) {
        NSBinarySearchingFirstEqual     = (1UL << 8),
        NSBinarySearchingLastEqual      = (1UL << 9),
        NSBinarySearchingInsertionIndex = (1UL << 10),
    };

    - (NSUInteger)indexOfObject:(id)obj
              inSortedRange:(NSRange)r
                    options:(NSBinarySearchingOptions)opts
            usingComparator:(NSComparator)cmp;

为什么要使用这个方法？类似 `containsObject:` 和 `indexOfObject:` 这样的方法从 0 索引开始搜索每个对象直到找到目标 — 这样不需要数组被排序，但是却是 O(n)的效率特性。如果使用二分查找的话，需要数组事先被排序，但在查找时只需要 O(log n) 的时间。因此，对于 一百万条记录，二分查找法最多只需要 21 次比较，而传统的线性查找则平均需要 500,000 次的比较。

这是个简单的衡量二分查找有多快的数据:

    Time to search for 1000 entries within 1000000 objects. Linear: 54130.38[ms]. Binary: 7.62[ms]

作为比较，查找 `NSOrderedSet` 中的指定索引花费 0.23 毫秒 — 就算和二分查找相比也又快了 30 多倍。

记住排序的开销也是昂贵的。苹果使用复杂度为 O(n\*log n) 的归并排序，所以如果你执行一次 `indexOfObject:` 的话，就没有必要使用二分查找了。

通过指定 `NSBinarySearchingInsertionIndex`，你可以获得正确的插入索引，以确保在插入元素后仍然可以保证数组的顺序。

### 枚举和总览

作为测试，我们来看一个普通的使用场景。从一个数组中过滤出一些元素组成另一个数组。这些测试都包括了枚举的方法以及使用 API 进行过滤的方式：

    // 第一种方式，使用 `indexesOfObjectsWithOptions:passingTest:`.
    NSIndexSet *indexes = [randomArray indexesOfObjectsWithOptions:NSEnumerationConcurrent
                                                   passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return testObj(obj);
    }];
    NSArray *filteredArray = [randomArray objectsAtIndexes:indexes];

    // 使用 predicate 过滤，包括 block 的方式和文本 predicate 的方式
    NSArray *filteredArray2 = [randomArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bindings) {
        return testObj(obj);
    }]];

    // 基于 block 的枚举
    NSMutableArray *mutableArray = [NSMutableArray array];
    [randomArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (testObj(obj)) {
            [mutableArray addObject:obj];
        }
    }];

    // 传统的枚举
    NSMutableArray *mutableArray = [NSMutableArray array];
    for (id obj in randomArray) {
        if (testObj(obj)) {
            [mutableArray addObject:obj];
        }
    }

    // 使用 NSEnumerator，传统学院派
    NSMutableArray *mutableArray = [NSMutableArray array];
    NSEnumerator *enumerator = [randomArray objectEnumerator];
    id obj = nil;
    while ((obj = [enumerator nextObject]) != nil) {
        if (testObj(obj)) {
            [mutableArray addObject:obj];
        }
    }

    // 通过下标使用 objectAtIndex：
    NSMutableArray *mutableArray = [NSMutableArray array];
    for (NSUInteger idx = 0; idx < randomArray.count; idx++) {
        id obj = randomArray[idx];
        if (testObj(obj)) {
            [mutableArray addObject:obj];
        }
    }

<table><thead><tr><th style="text-align: left;padding-right:1em;">枚举方法 / 时间 [ms]</th><th style="text-align:right;padding-right:1em;">10.000.000 elements</th><th style="text-align:right;padding-right:1em;">10.000 elements</th></tr></thead><tbody><tr><td style="text-align: left;"><code>indexesOfObjects:</code>, concurrent</td><td style="text-align: right;padding-right:1em;">1844.73</td><td style="text-align: right;padding-right:1em;">2.25</td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>NSFastEnumeration</code> (<code>for in</code>)</td><td style="text-align: right;padding-right:1em;">3223.45</td><td style="text-align: right;padding-right:1em;">3.21</td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>indexesOfObjects:</code></td><td style="text-align: right;padding-right:1em;">4221.23</td><td style="text-align: right;padding-right:1em;">3.36</td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>enumerateObjectsUsingBlock:</code></td><td style="text-align: right;padding-right:1em;">5459.43</td><td style="text-align: right;padding-right:1em;">5.43</td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>objectAtIndex:</code></td><td style="text-align: right;padding-right:1em;">5282.67</td><td style="text-align: right;padding-right:1em;">5.53</td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>NSEnumerator</code></td><td style="text-align: right;padding-right:1em;">5566.92</td><td style="text-align: right;padding-right:1em;">5.75</td>
</tr><tr><td style="text-align: left;padding-right:1em;"><code>filteredArrayUsingPredicate:</code></td><td style="text-align: right;padding-right:1em;">6466.95</td><td style="text-align: right;padding-right:1em;">6.31</td>
</tr></tbody></table>

为了更好的理解这里的效率测量，我们首先看一下数组是如何迭代的。

`indexesOfObjectsWithOptions:passingTest:` 必须每次都执行一次 block 因此比传统的使用 `NSFastEnumeration` 技术的基于 for 循环的枚举要稍微低效一些。但是如果开启了并发枚举，那么前者的速度则会大大的超过后者几乎 2 倍。iPhone 5s 是双核的，所以这说得通。这里并没有体现出来的是 `NSEnumerationConcurrent` 只对大量的对象有意义，如果你的集合中的对象数量很少，用哪个方法就真的无关紧要。甚至 `NSEnumerationConcurrent` 上额外的线程管理实际上会使结果变得更慢。

最大的输家是 `filteredArrayUsingPredicate:`。`NSPredicate` 需要在这里提及是因为，人们可以写出[非常复杂的表达式](http://nshipster.com/nspredicate/)，尤其是用不基于 block 的变体。使用 Core Data 的用户应该会很熟悉。

为了比较的完整，我们也加入了 `NSEnumerator` 作为比较 — 虽然没有任何理由再使用它了。然而它竟出人意料的快(至少还是比基于 `NSPredicate` 的过滤要快)，它的运行时消耗无疑比快速枚举更多 — 现在它只用于向后兼容。甚至没有优化过的 `objectAtIndex:` 都要更快些。

### NSFastEnumeration

在OSX 10.5和iOS的最初版本中，苹果增加了 [`NSFastEnumeration`](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSFastEnumeration_protocol/Reference/NSFastEnumeration.html)。在此之前，只有每次返回一个元素的 `NSEnumeration` ，每次迭代都有运行时开销。而快速枚举，苹果通过 `countByEnumeratingWithState:objects:count:` 返回一个数据块。该数据块被解析成 `id` 类型的 C 数组。这就是更快的速度的原因；迭代一个 C 数组要快得多，而且可以被编译器更深一步的优化。手动的实现快速枚举是十分难办的，所以苹果的 [FastEnumerationSample](https://developer.apple.com/library/ios/samplecode/FastEnumerationSample/Introduction/Intro.html) 是一个不错的开始，还有一篇 [Mike Ash 的文章](http://www.mikeash.com/pyblog/friday-qa-2010-04-16-implementing-fast-enumeration.html)也很不错。

### 应该用arrayWithCapacity:吗?

初始化`NSArray`的时候，可以选择指定数组的预期大小。在检测的时候，结果是在效率上没有差别 — 至少在统计误差范围内的测量的时间几乎相等。有消息透漏说实际上苹果根本没有使用这个参数。然而使用 `arrayWithCapacity:` 仍然好处，它可以作为一种隐性的文档来帮助你理解代码:

> Adding 10.000.000 elements to NSArray. no count 1067.35[ms] with count: 1083.13[ms].

### 子类化注意事项

很少有理由去子类化基础集合类。大多数时候，使用 CoreFoundation 级别的类并且自定义回调函数定制自定义行为是更好的解决方案。
创建一个大小写不敏感的字典，一种方法是子类化 `NSDictionary` 并且自定义访问方法，使其将字符串始终变为小写(或大写)，并对排序也做类似的修改。更快更好的解决方案是提供一组不同的 `CFDictionaryKeyCallBacks` 集，你可以提供自定义的 `hash` 和 `isEqual:` 回调。你可以在[这里](https://gist.github.com/steipete/7739473)找到一个例子。这种方法的优美之处应该归功于 [toll-free 桥接](https://developer.apple.com/library/ios/documentation/General/Conceptual/CocoaEncyclopedia/Toll-FreeBridgin/Toll-FreeBridgin.html))，它仍然是一个简单的字典，因此可以被任何使用 `NSDictionary` 作为参数的API接受。

子类作用的一个例子是有序字典的用例。.NET 提供了一个 `SortedDictionary`，Java 有 `TreeMap`，C++ 有 `std::map`。虽然你*可以*使用 C++ 的 STL 容器，但却无法使它自动的 `retain/release` ，这会让使用起来笨拙得多。因为 `NSDictionary` 是一个[类簇](https://developer.apple.com/library/ios/documentation/general/conceptual/CocoaEncyclopedia/ClassClusters/ClassClusters.html)，所以子类化跟人们想象的相比非常不同。这已经超过了本文的讨论范畴，[这里](https://github.com/nicklockwood/OrderedDictionary/blob/master/OrderedDictionary/OrderedDictionary.m)有一个真实的有序字典的例子。

## NSDictionary

一个字典存储任意的对象键值对。 由于历史原因，初始化方法 `[NSDictionary dictionaryWithObjectsAndKeys:object, key, nil]` 使用了相反的值到键的顺序，而新的快捷语法则从 key 开始，`@{key : value, ...}`。

`NSDictionary` 中的键是被拷贝的并且需要是不变的。如果在一个键在被用于在字典中放入一个值后被改变的话，那么这个值就会变得无法获取了。一个有趣的细节是，在 `NSDictionary` 中键是被 copy 的，但是在使用一个 toll-free 桥接的 `CFDictionary` 时却只会被 retain。CoreFoundation 类没有通用的拷贝对象的方法，因此这时拷贝是不可能的(\*)。这只适用于你使用 `CFDictionarySetValue()` 的时候。如果你是通过 `setObject:forKey` 来使用一个 toll-free 桥接的 `CFDictionary` 的话，苹果会为其增加额外处理逻辑，使得键被拷贝。但是反过来这个结论则不成立 — 使用已经转换为 `CFDictionary` 的 `NSDictionary` 对象，并用对其使用 `CFDictionarySetValue()` 方法，还是会导致调用回 `setObject:forKey` 并对键进行拷贝。

> (\*)其实有一个现成的键的回调函数 `kCFCopyStringDictionaryKeyCallBacks` 可以拷贝字符串，因为对于 ObjC对象来说， `CFStringCreateCopy()` 会调用 `[NSObject copy]`，我们可以巧妙使用这个回调来创建一个能进行键拷贝的 `CFDictionary`。

### 性能特征

苹果在定义字典的计算复杂度时显得相当低调。唯一的信息可以在 [`CFDictionary` 的头文件](http://www.opensource.apple.com/source/CF/CF-855.11/CFDictionary.h)中找到:

> 对于字典中值的访问时间，不管是在现在还是将来，我们保证在任何一种实现下最坏情况是 O(N)。但通常来说它会是 O(1) (常数时间)。插入和删除操作一般来说也会是常数时间，但是在某些实现中最坏情况将为 O(N\*N)。通过键来访问值将比直接访问值要快（如果你有这样的操作要做的话）。对于同样数目的值，字典需要花费比数组多得多的内存空间。

跟数组相似的，字典根据尺寸的不同使用不同的实现，并在其中无缝切换。

### 枚举和总览

过滤字典有几个不同的方法:

    // 使用 keysOfEntriesWithOptions:passingTest:，可并行
    NSSet *matchingKeys = [randomDict keysOfEntriesWithOptions:NSEnumerationConcurrent
                                                   passingTest:^BOOL(id key, id obj, BOOL *stop)
    {
        return testObj(obj);
    }];
    NSArray *keys = matchingKeys.allObjects;
    NSArray *values = [randomDict objectsForKeys:keys notFoundMarker:NSNull.null];
    __unused NSDictionary *filteredDictionary = [NSDictionary dictionaryWithObjects:values
                                                                            forKeys:keys];

    // 基于 block 的枚举
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
    [randomDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (testObj(obj)) {
            mutableDictionary[key] = obj;
        }
    }];

    // NSFastEnumeration
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
    for (id key in randomDict) {
        id obj = randomDict[key];
        if (testObj(obj)) {
            mutableDictionary[key] = obj;
        }
    }

     // NSEnumeration
     NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
     NSEnumerator *enumerator = [randomDict keyEnumerator];
     id key = nil;
     while ((key = [enumerator nextObject]) != nil) {
           id obj = randomDict[key];
           if (testObj(obj)) {
               mutableDictionary[key] = obj;
           }
     }

    // 基于 C 数组，通过 getObjects:andKeys: 枚举
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
    id __unsafe_unretained objects[numberOfEntries];
    id __unsafe_unretained keys[numberOfEntries];
    [randomDict getObjects:objects andKeys:keys];
    for (int i = 0; i < numberOfEntries; i++) {
        id obj = objects[i];
        id key = keys[i];
        if (testObj(obj)) {
           mutableDictionary[key] = obj;
        }
     }
 
<table><thead><tr><th style="text-align: left;min-width:22em;">过滤/枚举方法</th><th style="text-align: right;">Time [ms], 50.000 elements</th><th style="text-align: right;">1.000.000 elements</th></tr></thead><tbody><tr><td style="text-align: left;"><code>keysOfEntriesWithOptions:</code>, concurrent</td><td style="text-align: right;">16.65</td><td style="text-align: right;">425.24</td>
</tr><tr><td style="text-align: left;"><code>getObjects:andKeys:</code></td><td style="text-align: right;">30.33</td><td style="text-align: right;">798.49*</td>
</tr><tr><td style="text-align: left;"><code>keysOfEntriesWithOptions:</code></td><td style="text-align: right;">30.59</td><td style="text-align: right;">856.93</td>
</tr><tr><td style="text-align: left;"><code>enumerateKeysAndObjectsUsingBlock:</code></td><td style="text-align: right;">36.33</td><td style="text-align: right;">882.93</td>
</tr><tr><td style="text-align: left;"><code>NSFastEnumeration</code></td><td style="text-align: right;">41.20</td><td style="text-align: right;">1043.42</td>
</tr><tr><td style="text-align: left;"><code>NSEnumeration</code></td><td style="text-align: right;">42.21</td><td style="text-align: right;">1113.08</td>
</tr></tbody></table>

(\*)使用 `getObjects:andKeys:` 时需要注意。在上面的代码例子中，我们使用了[可变长度数组](http://gcc.gnu.org/onlinedocs/gcc/Variable-Length.html)这一 C99 特性(通常，数组的数量需要是一个固定值)。这将在栈上分配内存，虽然更方便一点，但却有其限制。上面的代码在元素数量很多的时候会崩溃掉，所以我们使用基于 `malloc/calloc` 的分配 (和 `free`) 以确保安全。

为什么这次 `NSFastEnumeration` 这么慢？迭代字典通常需要键和值两者，快速枚举只能枚举键，我们必须每次都自己获取值。使用基于 block 的 `enumerateKeysAndObjectsUsingBlock:` 更高效，因为两者都可以更高效的被提前获取。

这次测试的胜利者又是通过 `keysOfEntriesWithOptions:passingTest:` 和 `objectsForKeys:notFoundMarker:` 的并发迭代。代码稍微多了一点，但是可以用 category 进行漂亮的封装。

### 应该用 dictionaryWithCapacity: 吗?

到现在你应该已经知道该如何测试了，简单的回答是不，`count` 参数没有改变任何事情:

> Adding 10000000 elements to NSDictionary. no count 10786.60[ms] with count: 10798.40[ms].

### 排序

关于字典排序没有太多可说的。你只能将键数组排序为一个新对象，因此你可以使用任何正规的 `NSArray` 的排序方法:

    - (NSArray *)keysSortedByValueUsingSelector:(SEL)comparator;
    - (NSArray *)keysSortedByValueUsingComparator:(NSComparator)cmptr;
    - (NSArray *)keysSortedByValueWithOptions:(NSSortOptions)opts
                          usingComparator:(NSComparator)cmptr;

### 共享键

从 iOS 6 和 OS X 10.8 开始，新建的字典可以使用一个预先生成好的键集，使用 `sharedKeySetForKeys:` 从一个数组中创建键集，然后用 `dictionaryWithSharedKeySet:` 创建字典。共享键集会复用对象，以节省内存。根据 [Foundation Release Notes](https://developer.apple.com/library/mac/releasenotes/Foundation/RN-FoundationOlderNotes/)，`sharedKeySetForKeys:` 中会计算一个最小完美哈希，这个哈希值可以取代字典查找过程中探索循环的需要，因此使键的访问更快。

虽然在我们有限的测试中没有发现苹果在 `NSJSONSerialization` 中使用这个特性，但毫无疑问，在处理 JSON 的解析工作时这个特性可以发挥得淋漓尽致。(使用共享键集创建的字典是 `NSSharedKeyDictionary` 的子类；通常的字典是 `__NSDictionaryI` / `__NSDictionaryM`，I / M 表明可变性；可变和不可变的的字典在 toll-free 桥接后对应的都是 `_NSCFDictionary` 类。)

**有趣的细节：**共享键字典**始终是可变的**，即使对它们执行了”copy”命令后也是。这个行为文档中并没有说明，但很容易被测试:

    id sharedKeySet = [NSDictionary sharedKeySetForKeys:@[@1, @2, @3]]; // 返回 NSSharedKeySet
    NSMutableDictionary *test = [NSMutableDictionary dictionaryWithSharedKeySet:sharedKeySet];
    test[@4] = @"First element (not in the shared key set, but will work as well)";
    NSDictionary *immutable = [test copy];
    NSParameterAssert(immutable.count == 1);
    ((NSMutableDictionary *)immutable)[@5] = @"Adding objects to an immutable collection should throw an exception.";
    NSParameterAssert(immutable.count == 2);

## NSSet

`NSSet` 和它的可变变体 `NSMutableSet` 是无序对象集合。检查一个对象是否存在通常是一个 O(1) 的操作，使得比 `NSArray` 快很多。`NSSet` 只在被使用的哈希方法平衡的情况下能高效的工作；如果所有的对象都在同一个哈希筐内，`NSSet` 在查找对象是否存在时并不比 `NSArray` 快多少。

`NSSet` 还有变体 `NSCountedSet`，以及非 toll-free 计数变体 `CFBag` / `CFMutableBag`。

`NSSet` 会 retain 它其中的对象，但是根据 set 的规定，对象应该是不可变的。添加一个对象到 set 中随后改变它会导致一些奇怪的问题并破坏 set 的状态。

`NSSet` 的方法比 `NSArray` 少的多。没有排序方法，但有一些方便的枚举方法。重要的方法有 `allObjects`，将对象转化为 `NSArray`，`anyObject` 则返回任意的对象，如果 set 为空，则返回 nil。

### Set 操作

`NSMutableSet` 有几个很强大的方法，例如 `intersectSet:`，`minusSet:` 和 `unionSet:`。

![img](/images/issues/issue-7/set.png)

### 应该用setWithCapacity:吗?

我们再一次测试当创建 set 时给定容量大小是否会有显著的速度差异:

> Adding 1.000.000 elements to NSSet. no count 2928.49[ms] with count: 2947.52[ms].

在统计误差范围内，结果没有显著差异。有一份证据表明[至少在上一个 runtime 版本中，有很多的性能上的影响](http://www.cocoawithlove.com/2008/08/nsarray-or-nsset-nsdictionary-or.html)。

### NSSet 性能特征

苹果在 [CFSet 头文件](http://www.opensource.apple.com/source/CF/CF-855.11/CFSet.h)中没有提供任何关于算法复杂度的注释。

<table><thead><tr><th style="text-align: left;">类 / 时间 [ms]</th><th style="text-align: right;">1.000.000 elements</th></tr></thead><tbody><tr><td style="text-align: left;"><code>NSMutableSet</code>, adding</td><td style="text-align: right;">2504.38</td>
</tr><tr><td style="text-align: left;"><code>NSMutableArray</code>, adding</td><td style="text-align: right;">1413.38</td>
</tr><tr><td style="text-align: left;"><code>NSMutableSet</code>, random access</td><td style="text-align: right;">4.40</td>
</tr><tr><td style="text-align: left;"><code>NSMutableArray</code>, random access</td><td style="text-align: right;">7.95</td>
</tr></tbody></table>

这个检测非常符合我们的预期：`NSSet` 在每一个被添加的对象上执行 `hash` 和 `isEqual:` 方法并管理一系列哈希值，所以在添加元素时耗费了更多的时间。set的随机访问比较难以测试，因为这里执行的都是 `anyObject`。

这里没有必要包含 `containsObject:` 的测试，set 要快几个数量级，毕竟这是它的特点。

### NSOrderedSet

`NSOrderedSet` 在 iOS 5 和 Mac OS X 10.7 中第一次被引入，除了 Core Data，几乎没有直接使用它的 API。看上去它综合了 `NSArray` 和 `NSSet` 两者的好处，对象查找，对象唯一性，和快速随机访问。

`NSOrderedSet` 有着优秀的 API 方法，使得它可以很便利的与其他 set 或者有序 set 对象合作。合并，交集，差集，就像 `NSSet` 支持的那样。它有 `NSArray` 中除了比较陈旧的基于函数的排序方法和二分查找以外的大多数排序方法。毕竟 `containsObject:` 非常快，所以没有必要再用二分查找了。

`NSOrderedSet` 的 `array` 和 `set` 方法分别返回一个 `NSArray` 和 `NSSet`，这些对象表面上是不可变的对象，但实际上在 NSOrderedSet 更新的时候，它们也会更新自己。如果你在不同线程上使用这些对象并发生了诡异异常的时候，知道这一点是非常有好处的。本质上，这些类使用的是 `__NSOrderedSetSetProxy` 和 `__NSOrderedSetArrayProxy`。

附注：如果你想知道为什么 `NSOrderedSet` 不是 `NSSet` 的子类，[NSHipster 上有一篇非常好的文章解释了可变/不可变类簇的缺点](http://nshipster.com/nsorderedset/)。

### NSOrderedSet 性能特征

如果你看到这份测试，你就会知道 `NSOrderedSet` 代价高昂了，毕竟天下没有免费的午餐:

<table><thead><tr><th style="text-align: left;">类 / 时间 [ms]</th><th style="text-align: right;">1.000.000 elements</th></tr></thead><tbody><tr><td style="text-align: left;"><code>NSMutableOrderedSet</code>, adding</td><td style="text-align: right;"><strong>3190.52</strong></td>
</tr><tr><td style="text-align: left;"><code>NSMutableSet</code>, adding</td><td style="text-align: right;">2511.96</td>
</tr><tr><td style="text-align: left;"><code>NSMutableArray</code>, adding</td><td style="text-align: right;">1423.26</td>
</tr><tr><td style="text-align: left;"><code>NSMutableOrderedSet</code>, random access</td><td style="text-align: right;"><strong>10.74</strong></td>
</tr><tr><td style="text-align: left;"><code>NSMutableSet</code>, random access</td><td style="text-align: right;">4.47</td>
</tr><tr><td style="text-align: left;"><code>NSMutableArray</code>, random access</td><td style="text-align: right;">8.08</td>
</tr></tbody></table>

这个测试在每一个集合类中添加自定义字符串，随后随机访问它们。

`NSOrderedSet` 比 `NSSet` 和 `NSArray` 占用更多的内存，因为它需要同时维护哈希值和索引。

### NSHashTable

`NSHashTable` 效仿了 `NSSet`，但在对象/内存处理时更加的灵活。可以通过自定义 `CFSet` 的回调获得 `NSHashTable` 的一些特性，哈希表可以保持对对象的弱引用并在对象被销毁之后正确的将其移除，有时候如果手动在 NSSet 中添加的话，想做到这个是挺恶心的一件事。它是默认可变的 — 并且这个类没有相应的不可变版本。

`NSHashTable` 有 ObjC 和原始的 C API，C API 可以用来存储任意对象。苹果在 10.5 Leopard 系统中引入了这个类，但是 iOS 的话直到最近的 iOS 6 中才被加入。足够有趣的是它们只移植了 ObjC API；更多强大的 C API 没有包括在 iOS 中。

`NSHashTable` 可以通过 `initWithPointerFunctions:capacity:` 进行大量的设置 — 我们只选取使用预先定义的 `hashTableWithOptions:` 这一最普遍的使用场景。其中最有用的选项有利用 `weakObjectsHashTable` 来使用其自身的构造函数。

### NSPointerFunctions

这些指针函数可以被用在 `NSHashTable`，`NSMapTable `和 `NSPointerArray` 中，定义了对存储在这个集合中的对象的获取和保留行为。这里只介绍最有用的选项。完整列表参见 `NSPointerFunctions.h`。

有两组选项。内存选项决定了内存管理，个性化定义了哈希和相等。

`NSPointerFunctionsStrongMemory` 创建了一个r etain/release 对象的集合，非常像常规的 `NSSet` 或 `NSArray`。

`NSPointerFunctionsWeakMemory` 使用和 `__weak` 等价的方式来存储对象并自动移除被销毁的对象。

`NSPointerFunctionsCopyIn` 在对象被加入到集合前拷贝它们。

`NSPointerFunctionsObjectPersonality` 使用对象的 `hash` 和 `isEqual:` (默认)。

`NSPointerFunctionsObjectPointerPersonality` 对于 `isEqual:` 和 `hash` 使用直接的指针比较。

### NSHashTable 性能特征

<table><thead><tr><th style="text-align: left;">类 / 时间 [ms]</th><th style="text-align: right;">1.000.000 elements</th></tr></thead><tbody><tr><td style="text-align: left;"><code>NSHashTable</code>, adding</td><td style="text-align: right;">2511.96</td>
</tr><tr><td style="text-align: left;"><code>NSMutableSet</code>, adding</td><td style="text-align: right;">1423.26</td>
</tr><tr><td style="text-align: left;"><code>NSHashTable</code>, random access</td><td style="text-align: right;">3.13</td>
</tr><tr><td style="text-align: left;"><code>NSMutableSet</code>, random access</td><td style="text-align: right;">4.39</td>
</tr><tr><td style="text-align: left;"><code>NSHashTable</code>, containsObject</td><td style="text-align: right;">6.56</td>
</tr><tr><td style="text-align: left;"><code>NSMutableSet</code>, containsObject</td><td style="text-align: right;">6.77</td>
</tr><tr><td style="text-align: left;"><code>NSHashTable</code>, NSFastEnumeration</td><td style="text-align: right;">39.03</td>
</tr><tr><td style="text-align: left;"><code>NSMutableSet</code>, NSFastEnumeration</td><td style="text-align: right;">30.43</td>
</tr></tbody></table>

如果你只是需要 `NSSet` 的特性，请坚持使用 `NSSet`。`NSHashTable` 在添加对象时花费了将近2倍的时间，但是其他方面的效率却非常相近。

### NSMapTable

`NSMapTable` 和 `NSHashTable` 相似，但是效仿的是 `NSDictionary`。因此，我们可以通过 `mapTableWithKeyOptions:valueOptions:` 分别控制键和值的对象获取/保留行为。存储弱引用是 `NSMapTable` 最有用的特性，这里有4个方便的构造函数:

* `strongToStrongObjectsMapTable`
* `weakToStrongObjectsMapTable`
* `strongToWeakObjectsMapTable`
* `weakToWeakObjectsMapTable`

注意，除了使用 `NSPointerFunctionsCopyIn`，任何的默认行为都会 retain (或弱引用)键对象而不会拷贝它，这与 `CFDictionary` 的行为相同而与 `NSDictionary` 不同。当你需要一个字典，它的键没有实现 `NSCopying` 协议的时候（比如像 `UIView`），这会非常有用。

如果你好奇为什么苹果”忘记”为 `NSMapTable` 增加下标，你现在知道了。下标访问需要一个 `id<NSCopying>` 作为 key，对 `NSMapTable` 来说这不是强制的。如果不通过一个非法的 API 协议或者移除 `NSCopying` 协议来削弱全局下标，是没有办法给它增加下标的。

你可以通过 `dictionaryRepresentation` 把内容转换为普通的 `NSDictionary`。不像 `NSOrderedSet`，这个方法返回的是一个常规的字典而不是一个代理。

### NSMapTable 性能特征

<table><thead><tr><th style="text-align: left;">类 / 时间 [ms]</th><th style="text-align: right;">1.000.000 elements</th></tr></thead><tbody><tr><td style="text-align: left;"><code>NSMapTable</code>, adding</td><td style="text-align: right;">2958.48</td>
</tr><tr><td style="text-align: left;"><code>NSMutableDictionary</code>, adding</td><td style="text-align: right;">2522.47</td>
</tr><tr><td style="text-align: left;"><code>NSMapTable</code>, random access</td><td style="text-align: right;">13.25</td>
</tr><tr><td style="text-align: left;"><code>NSMutableDictionary</code>, random access</td><td style="text-align: right;">9.18</td>
</tr></tbody></table>

`NSMapTable` 只比 `NSDictionary` 略微慢一点。如果你需要一个不 retain 键的字典，放弃 `CFDictionary` 而使用它吧。

### NSPointerArray

`NSPointerArray`类是一个稀疏数组，工作起来与 `NSMutableArray` 相似，但可以存储 `NULL` 值，并且 `count` 方法会反应这些空点。可以用 `NSPointerFunctions` 对其进行各种设置，也有应对常见的使用场景的快捷构造函数 `strongObjectsPointerArray` 和 `weakObjectsPointerArray`。

在能使用 `insertPointer:atIndex:` 之前，我们需要通过直接设置 `count` 属性来申请空间，否则会产生一个异常。另一种选择是使用 `addPointer:`，这个方法可以自动根据需要增加数组的大小。

你可以通过 `allObjects` 将一个 `NSPointerArray` 转换成常规的 `NSArray`。这时所有的 `NULL` 值会被去掉，只有真正存在的对象被加入到数组 — 因此数组的对象索引很有可能会跟指针数组的不同。注意：如果向指针数组中存入任何非对象的东西，试图执行 `allObjects` 都会造成 `EXC_BAD_ACCESS` 崩溃，因为它会一个一个地去 retain ”对象”。

从调试的角度讲，`NSPointerArray`没有受到太多欢迎。`description`方法只是简单的返回了`<NSConcretePointerArray: 0x17015ac50>`。为了得到所有的对象需要执行`[pointerArray allObjects]`，当然，如果存在`NULL`的话会改变索引。

## NSPointerArray 性能特征
在性能方面，	`NSPointerArray` 真的非常非常慢，所以当你打算在一个很大的数据集合上使用它的时候一定要三思。在本测试中我们比较了使用 `NSNull` 作为空标记的 `NSMutableArray` ，而对 `NSPointerArray` 我们用 `NSPointerFunctionsStrongMemory` 来进行设置 (这样对象会被适当的 retain)。在一个有 10,000 个元素的数组中，我们每隔十个插入一个字符串 ”Entry %d”。此测试包括了用 `NSNull.null` 填充 `NSMutableArray` 的总时间。对于 `NSPointerArray`，我们使用 `setCount:` 来代替:

<table><thead><tr><th style="text-align: left;">类 / 时间 [ms]</th><th style="text-align: right;">10.000 elements</th></tr></thead><tbody><tr><td style="text-align: left;"><code>NSMutableArray</code>, adding</td><td style="text-align: right;">15.28</td>
</tr><tr><td style="text-align: left;"><code>NSPointerArray</code>, adding</td><td style="text-align: right;"><strong>3851.51</strong></td>
</tr><tr><td style="text-align: left;"><code>NSMutableArray</code>, random access</td><td style="text-align: right;">0.23</td>
</tr><tr><td style="text-align: left;"><code>NSPointerArray</code>, random access</td><td style="text-align: right;">0.34</td>
</tr></tbody></table>

注意 `NSPointerArray` 需要的时间比 `NSMutableArray` 多了超过** 250 倍(!)** 。这非常奇怪和意外。跟踪内存是比较困难的，所以按理说 `NSPointerArray` 会更高效才对。不过由于我们使用的是同一个 `NSNull` 来标记空对象，所以除了指针也没有什么更多的消耗。

## NSCache

`NSCache` 是一个非常奇怪的集合。在 iOS 4 / Snow Leopard 中加入，默认为可变并且线程安全的。这使它很适合缓存那些创建起来代价高昂的对象。它自动对内存警告做出反应并基于可设置的”成本”清理自己。与 `NSDictionary` 相比，键是被 retain 而不是被 copy 的。

`NSCache` 的回收方法是不确定的，在文档中也没有说明。向里面放一些类似图片那样超大的对象并不是一个好主意，有可能它在能回收之前就更快地把你的 cache 给填满了。(这是在 [PSPDFKit](http://pspdfkit.com/) 中很多跟内存有关的 crash 的原因，在使用自定义的基于 LRU 的链表缓存的代码之前，我们起初使用了 `NSCache` 存储事先渲染的图片。)

可以对 `NSCache` 进行设置，这样它就能自动回收那些实现了 `NSDiscardableContent` 协议的对象。实现了该属性的一个比较常用的类是同时间加入的 `NSPurgeableData`，但是[在 OS X 10.9 之前，它是非完全线程安全的 (也没有信息表明这个变化也影响到了 iOS，或者说在 iOS 7 中被修复了)](https://developer.apple.com/library/mac/releasenotes/Foundation/RN-Foundation/index.html#//apple_ref/doc/uid/TP30000742)。

### NSCache 性能

那么相比起 `NSMutableDictionary` 来说，`NSCache` 表现如何呢？加入的线程安全必然会带来一些消耗。处于好奇，我也加入了一个自定义的线程安全的字典的子类 ([PSPDFThreadSafeMutableDictionary](https://gist.github.com/steipete/5928916))，它通过 `OSSpinLock` 实现同步的访问。

<table><thead><tr><th style="text-align: left;min-width:28em;">类 / 时间 [ms]</th><th style="text-align: right;">1.000.000 elements</th><th style="text-align: right;">iOS 7x64 Simulator</th><th style="text-align: right;">iPad Mini iOS 6</th></tr></thead><tbody><tr><td style="text-align: left;"><code>NSMutableDictionary</code>, adding</td><td style="text-align: right;">195.35</td><td style="text-align: right;">51.90</td><td style="text-align: right;">921.02</td>
</tr><tr><td style="text-align: left;"><code>PSPDFThreadSafeMutableDictionary</code>, adding</td><td style="text-align: right;">248.95</td><td style="text-align: right;">57.03</td><td style="text-align: right;">1043.79</td>
</tr><tr><td style="text-align: left;"><code>NSCache</code>, adding</td><td style="text-align: right;">557.68</td><td style="text-align: right;">395.92</td><td style="text-align: right;">1754.59</td>
</tr><tr><td style="text-align: left;"><code>NSMutableDictionary</code>, random access</td><td style="text-align: right;">6.82</td><td style="text-align: right;">2.31</td><td style="text-align: right;">23.70</td>
</tr><tr><td style="text-align: left;"><code>PSPDFThreadSafeMutableDictionary</code>, random access</td><td style="text-align: right;">9.09</td><td style="text-align: right;">2.80</td><td style="text-align: right;">32.33</td>
</tr><tr><td style="text-align: left;"><code>NSCache</code>, random access</td><td style="text-align: right;">9.01</td><td style="text-align: right;"><strong>29.06</strong></td><td style="text-align: right;">53.25</td>
</tr></tbody></table>

`NSCache` 表现的相当好，随机访问跟我们自定义的线程安全字典一样快。如我们预料的，添加更慢一些，因为 `NSCache` 要多维护一个决定何时回收对象的成本系数。就这一点来看这不是一个非常公平的比较。有趣的是，在模拟器上运行效率要慢了几乎 10 倍。无论对 32 或 64 位的系统都是这样。而且看起来这个类已经在 iOS 7 中优化过，或者是受益于 64 位 runtime 环境。当在老的设备上测试时，使用 `NSCache` 的性能消耗就明显得多。

iOS 6(32 bit) 和 iOS 7(64 bit) 的区别也很明显，因为 64 位运行时使用[标签指针 (tagged pointer)](http://www.mikeash.com/pyblog/friday-qa-2012-07-27-lets-build-tagged-pointers.html)，因此我们的 `@(idx)` boxing 要更为高效。

## NSIndexSet

有些使用场景下 `NSIndexSet` (和它的可变变体，`NSMutableIndexSet`) 真的非常出色，对它的使用贯穿在 Foundation 中。它可以用一种非常高效的方法存储一组无符号整数的集合，尤其是如果只是一个或少量范围的时候。正如 set 这个名字已经暗示的那样，每一个 `NSUInteger` 要么在索引 set 中，要么不在。如果你需要存储任意非唯一的数的时候，最好使用 `NSArray`。

下面是如何把一个整数数组转换为 `NSIndexSet`:

    NSIndexSet *PSPDFIndexSetFromArray(NSArray *array) {
        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
        for (NSNumber *number in array) {
            [indexSet addIndex:[number unsignedIntegerValue]];
        }
        return [indexSet copy];
    }   

如果不使用block，从索引set中拿到所有的索引有点麻烦，`getIndexes:maxCount:inIndexRange:` 是最快的方法，其次是使用 `firstIndex` 并迭代直到 `indexGreaterThanIndex:` 返回 `NSNotFound`。随着 block 的到来，使用 `NSIndexSet` 工作变得方便的多:

    NSArray *PSPDFArrayFromIndexSet(NSIndexSet *indexSet) {
        NSMutableArray *indexesArray = [NSMutableArray arrayWithCapacity:indexSet.count];
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
           [indexesArray addObject:@(idx)];
        }];
        return [indexesArray copy];
    }

### NSIndexSet性能

Core Foundation 中没有和 `NSIndexSet` 相当的类，苹果也没有对性能做出任何承诺。`NSIndexSet` 和 `NSSet` 之间的比较也相对的不公平，因为常规的 set 需要对数字进行包装。为了缓解这个影响，这里的测试准备了实现包装好的 `NSUintegers` ，并且在两个循环中都会执行 `unsignedIntegerValue`:

<table class=""><thead><tr><th style="text-align: left;min-width:20em;">类 / 时间 [ms]</th><th style="text-align: right;">#1.000</th><th style="text-align: right;">#10.000</th><th style="text-align: right;">#1.000.000</th><th style="text-align: right;">#10.000.000</th><th style="text-align: right;">#1.000.000, iPad Mini iOS 6</th></tr></thead><tbody><tr><td style="text-align: left;"><code>NSIndexSet</code>, adding</td><td style="text-align: right;">0.28</td><td style="text-align: right;">4.58</td><td style="text-align: right;">98.60</td><td style="text-align: right;">9396.72</td><td style="text-align: right;">179.27</td> </tr><tr><td style="text-align: left;"><code>NSSet</code>, adding</td><td style="text-align: right;">0.30</td><td style="text-align: right;">2.60</td><td style="text-align: right;">8.03</td><td style="text-align: right;">91.93</td><td style="text-align: right;">37.43</td> </tr><tr><td style="text-align: left;"><code>NSIndexSet</code>, random access</td><td style="text-align: right;">0.10</td><td style="text-align: right;">1.00</td><td style="text-align: right;">3.51</td><td style="text-align: right;">58.67</td><td style="text-align: right;">13.44</td> </tr><tr><td style="text-align: left;"><code>NSSet</code>, random access</td><td style="text-align: right;">0.17</td><td style="text-align: right;">1.32</td><td style="text-align: right;">3.56</td><td style="text-align: right;">34.42</td><td style="text-align: right;">18.60</td> </tr></tbody></table>

我们看到在一百万左右对象的时候，`NSIndexSet` 开始变得比 `NSSet` 慢，但只是因为新的运行时和标签指针。在 iOS 6 上运行相同的测试表明，甚至在更高数量级实体的条件下，`NSIndexSet` 更快。实际上，在大多数应用中，你不会添加太多的整数到索引 set 中。还有一点这里没有测试，就是 `NSIndexSet` 跟 `NSSet` 比无疑有更好的内存优化。

## 结论

本文提供了一些真实的测试，使你在使用基础集合类的时候做出有根据的选择。除了上面讨论的类，还有一些不常用但确实有用的类，尤其是 `NSCountedSet`，[`CFBag`](http://nshipster.com/cfbag/)，[`CFTree`](https://developer.apple.com/library/mac/documentation/corefoundation/Reference/CFTreeRef/Reference/reference.html)，[`CFBitVector`](https://developer.apple.com/library/mac/documentation/corefoundation/Reference/CFBitVectorRef/Reference/reference.html)和[`CFBinaryHeap`](https://developer.apple.com/library/mac/documentation/corefoundation/Reference/CFBinaryHeapRef/Reference/reference.html)。

---

 

原文：[The Foundation Collection Classes](http://www.objc.io/issue-7/collections.html)

译文：[基础集合类](http://objcio.com/blog/2014/01/20/the-foundation-collection-classes/)

校对：[FANWENBIN](http://fanwenbin.com)，[onevcat](http://im.onevcat.com)
