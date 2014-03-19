[Source](http://www.objc.io/issue-7/collections.html "Permalink to The Foundation Collection Classes - Foundation - objc.io issue #7 ")

# The Foundation Collection Classes - Foundation - objc.io issue #7 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# The Foundation Collection Classes

[Issue #7 Foundation][4], December 2013

By [Peter Steinberger][5]

## NSArray, NSSet, NSOrderedSet, and NSDictionary

Foundation’s collection classes are the basic building blocks of every Mac/iOS application. In this article, we’re going to have an in-depth look at both the “old” (`NSArray`, `NSSet`) and the “new” (`NSMapTable`, `NSHashTable`, `NSPointerArray`) classes, explore detailed performance of each of them, and discuss when to use what.

Author Note: This article contains several benchmark results, however they are by no means meant to be exact and there’s no variation/multiple runs applied. Their goal is to give you a direction of what’s faster and general runtime statistics. All tests have been made on an iPhone 5s with Xcode 5.1b1 and iOS 7.1b1 and a 64-bit binary. Compiler settings were release built with -Ofast. Vectorize loops and unroll loops (default settings) have both been disabled .

### Big O Notation

First, we need some theoretical background. Performance is usually described with the [Big O Notation][6]. It defines the _limiting behavior_ of a function and is often used to characterize algorithms on their performance. O defines the upper bound of the growth rate of the function. To see just how big the difference is, see commonly used O notations and the number of operations needed.

![][7]

For example, if you sort an array with 50 elements, and your sorting algorithm has a complexity of O(n^2), there will be 2,500 operations necessary to complete the task. Furthermore, there’s also overhead in internal management and calling that method - so it’s 2,500 operations times constant. O(1) is the ideal complexity, meaning constant time. [Good sorting algorithms usually need O(n*log n) time.][8]

### Mutability

Most collection classes exist in two versions: mutable and immutable (default). This is quite different than most other frameworks and feels a bit weird at first. However, others are now adopting this as well: [.NET introduced immutable collections as an official extension][9] only a few months ago.

What’s the big advantage? **Thread safety**. Immutable collections are fully thread safe and can be iterated from multiple threads at the same time, without any risk of mutation exceptions. Your API should _never_ expose mutable collections.

Of course there’s a cost when going from immutable and mutable and back - the object has to be copied twice, and all objects within will be retained/released. Sometimes it’s more efficient to hold an internal mutable collection and return a copied, immutable object on access.

Unlike other frameworks, Apple does not provide thread-safe mutable variants of its collection classes, with the exception of `NSCache` \- which really doesn’t count since it’s not meant to be a generic container. Most of the time, you really don’t want synchronization at the collection level, but rather higher up in the hierarchy. Imagine some code that checks for the existence of a key in a dictionary, and depending on the result, sets a new key or returns something else - you usually want to group multiple operations together, and a thread-safe mutable variant would not help you here.

There are _some_ valid use cases for a synchronized, thread-safe mutable collection, and it takes only a few lines to build something like that via subclassing and composition, e.g. for [`NSDictionary`][10] or [NSArray][11].

Notably, some of the more modern collection classes like `NSHashTable`, `NSMapTable`, and `NSPointerArray` are mutable by default and don’t have immutable counterparts. They are meant for internal class use, and a use case where you would want those immutable would be quite unusual.

## NSArray

`NSArray` stores objects as ordered collections and is probably the most-used collection class. That’s why it even got its own syntactic sugar syntax with the shorthand-literal `@[...]`, which is much shorter than the old [`NSArray arrayWithObjects:..., nil]`.

`NSArray` implements `objectAtIndexedSubscript:` and thus we can use a C-like syntax like `array[0]` instead of the older [`array objectAtIndex:0]`.

### Performance Characteristics

There’s a lot more to `NSArray` than you might think, and it uses a variety of internal variants depending on how many objects are being stored. The most interesting part is that Apple doesn’t guarantee O(1) access time on individual object access - as you can read in the note about Computational Complexity in the [CFArray.h CoreFoundation header][12]:

> The access time for a value in the array is guaranteed to be at worst O(lg N) for any implementation, current and future, but will often be O(1) (constant time). Linear search operations similarly have a worst case complexity of O(N*lg N), though typically the bounds will be tighter, and so on. Insertion or deletion operations will typically be linear in the number of values in the array, but may be O(N*lg N) clearly in the worst case in some implementations. There are no favored positions within the array for performance; that is, it is not necessarily faster to access values with low indices, or to insert or delete values with high indices, or whatever.

When measuring, it turns out that `NSArray` has some [additional interesting performance characteristics][13]. Inserting/deleting elements at the beginning/end is usually an O(1) operation, where random insertion/deletion usually will be O(N).

### Useful Methods

Most methods of `NSArray` use `isEqual:` to check against other objects (like `containsObject:`). There’s a special method named `indexOfObjectIdenticalTo:` that goes down to pointer equality, and thus can speed up searching for objects a lot - if you can ensure that you’re searching within the same set.

With iOS 7, we finally got a public `firstObject` method, which joins `lastObject`, and both simply return `nil` for an empty array - regular access would throw an `NSRangeException`.

There’s a nice detail about the construction of (mutable) arrays that can be used to save code. If you are creating a mutable array from a source that might be nil, you usually have some code like this:


    NSMutableArray *mutableObjects = [array mutableCopy];
    if (!mutableObjects) {
        mutableObjects = [NSMutableArray array];
    }

or via the more concise [ternary operator][14]:


    NSMutableArray *mutableObjects = [array mutableCopy] ?: [NSMutableArray array];

The better solution is to use the fact that `arrayWithArray:` will return an object in either way - even if the source array is nil:


    NSMutableArray *mutableObjects = [NSMutableArray arrayWithArray:array];

The two operations are almost equal in performance. Using `copy` is a bit faster, but then again, it’s highly unlikely that this will be your app bottleneck. **Side Note:** Please don’t use [`@[] mutableCopy]`. The classic [`NSMutableArray array]` is a lot better to read.

Reversing an array is really easy: `array.reverseObjectEnumerator.allObjects`. We’ll use the fact that `reverseObjectEnumerator` is pre-supplied and every `NSEnumerator` implements `allObjects`, which returns a new array. And while there’s no native `randomObjectEnumerator`, you can write a custom enumerator that shuffles the array or use [some great open source options][15].

### Sorting Arrays

There are various ways to sort an array. If it’s string based, `sortedArrayUsingSelector:` is your first choice:


    NSArray *array = @[@"John Appleseed", @"Tim Cook", @"Hair Force One", @"Michael Jurewitz"];
    NSArray *sortedArray = [array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

This works equally well for number-based content, since `NSNumber` implements `compare:` as well:


    NSArray *numbers = @[@9, @5, @11, @3, @1];
    NSArray *sortedNumbers = [numbers sortedArrayUsingSelector:@selector(compare:)];

For more control, you can use the function-pointer-based sorting methods:


    - (NSData *)sortedArrayHint;
    - (NSArray *)sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))comparator
                                  context:(void *)context;
    - (NSArray *)sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))comparator
                                  context:(void *)context hint:(NSData *)hint;

Apple added an (opaque) way to speed up sorting using `sortedArrayHint`.

> The hinted sort is most efficient when you have a large array (N entries) that you sort once and then change only slightly (P additions and deletions, where P is much smaller than N). You can reuse the work you did in the original sort by conceptually doing a merge sort between the N “old” items and the P “new” items. To obtain an appropriate hint, you use `sortedArrayHint` when the original array has been sorted, and keep hold of it until you need it (when you want to re-sort the array after it has been modified).

Since blocks are around, there are also the newer block-based sorting methods:


    - (NSArray *)sortedArrayUsingComparator:(NSComparator)cmptr;
    - (NSArray *)sortedArrayWithOptions:(NSSortOptions)opts
                        usingComparator:(NSComparator)cmptr;

Performance-wise, there’s not much difference between the different methods. Interestingly, the selector-based approach is actually the fastest. [You’ll find the source code the benchmarks used here on GitHub.][16]:

`Sorting 1000000 elements. selector: 4947.90[ms] function: 5618.93[ms] block: 5082.98[ms].`

### Binary Search

`NSArray` has come with built-in [binary search][17] since iOS 4 / Snow Leopard:


    typedef NS_OPTIONS(NSUInteger, NSBinarySearchingOptions) {
            NSBinarySearchingFirstEqual     = (1UL 