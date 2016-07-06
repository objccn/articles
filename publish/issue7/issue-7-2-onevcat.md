在这篇文章里，我们会看看如何用 Objective-C 写[值对象 (value objects)](http://en.wikipedia.org/wiki/Value_object)。在编写中，我们会接触到 Objective-C 中的一些重要的接口和方法。所谓值对象，就是指那些能够被判等的，持有某些数值的对象 (对它们判等时我们看重值是否相等，而对是否是同一个对象并不是那么关心)。通常来说，值对象会被用作 model 对象。比如像下面的 `Person` 对象就是一个简单的例子：

    @interface Person : NSObject
    
    @property (nonatomic,copy) NSString* name;
    @property (nonatomic) NSDate* birthDate;
    @property (nonatomic) NSUInteger numberOfKids;
    
    @end

创造这样的对象可以说是我们日复一日的基本工作了，虽然这些对象表面上看起来相当简单，但是其中暗藏玄机。

我们中有很多人会教条主义地认为这类对象就应该是不可变的 (immutable)。一旦你创建了一个 `Person` 对象，它就不可能在做任何改变了。我们在稍后会在本话题中涉及到可变性的问题。

## 属性

首先我们来看看定义一个 `Person` 时所用到的属性。创建属性是一件机械化的工作：对于一般的属性，你会将它们声明为 `nonatomic`。默认情况下，对象属性是 `strong` 的，标量属性是 `assign` 的。但是有一个例外，就是对于具有可变副本的属性，我们倾向于将其声明为 `copy`。比如说，`name` 属性的类型是 `NSString`，有可能有人创建了一个 `Person` 对象，并且给这个属性赋了一个 `NSMutableString` 的名字值。然后过了一会儿，这个可变字符串被变更了。如果我们的属性不是 `copy` 而是 `strong` 的话，随着可变字符串的改变，我们的 `Person` 对象也将发生改变，这不是我们希望发生的。对于类似数组或者字典这样的容器类来说，也是这样的情况。

要注意的是这里的 copy 是浅拷贝；容器里还是会包含可变对象。比如，如果你有一个 `NSMutableArray* a`，其中有一些 `NSMutableDictionary` 的元素，那么 `[a copy]` 将返回一个不可变的数组，但是里面的元素依然是同样的 `NSMutableDictionary` 对象。我们稍后会看到，对于不可变对象的 copy 是没有成本的，只会增加引用计数而已。

因为属性是相对最近才加入到 Objective-C 的，所以在较老的代码中，你有可能不会见到属性。取而代之，可能会有自定义的 getter 和 setter，或者直接是实例变量。对于最近的代码，看起来大家都赞同还是使用属性比较好，这也正是我们所推荐的。

##### 扩展阅读

[`NSString`: `copy` 还是 `retain`](http://stackoverflow.com/questions/387959/nsstring-property-copy-or-retain)

## 初始化方法 (Initializers)

如果我们需要的是不可变对象，那么我们要确保它在被创建后就不能再被更改。我们可以通过使用初始化方法并且在接口中将我们的属性声明为 readonly 来实现这一点。我们的接口看起来是这样的：


    @interface Person : NSObject
    
    @property (nonatomic,readonly) NSString* name;
    @property (nonatomic,readonly) NSDate* birthDate;
    @property (nonatomic,readonly) NSUInteger numberOfKids;
    
    - (instancetype)initWithName:(NSString*)name
                       birthDate:(NSDate*)birthDate
                    numberOfKids:(NSUInteger)numberOfKids;
    
    @end

在初始化方法的实现中，我们必须使用实例变量，而不是属性。

> <p><span class="secondary radius label">编者注</span> 在初始化方法或者是 dealloc 中最好不要使用属性，因为你无法确定 `self` 到底是不是确实调用的是你想要的实例


    @implementation Person
    
    - (instancetype)initWithName:(NSString*)name
                       birthDate:(NSDate*)birthDate
                    numberOfKids:(NSUInteger)numberOfKids
    {
        self = [super init];
        if (self) {
            _name = [name copy];
            _birthDate = birthDate;
            _numberOfKids = numberOfKids;
        }
        return self;
    }

    @end


现在我们就可以构建新的 `Person` 对象，并且不能再对它们做改变了。这一点很有帮助，在写和 `Person` 对象一起工作的其他类的时候，我们知道这些值是不会发生改变的。注意这里 `copy` 不再是接口的一部分了，现在它只和实现的细节相关。

## 判等

要比较相等，我们需要实现 `isEqual:` 方法。我们希望 `isEqual:` 方法仅在所有属性都相等的时候返回真。Mike Ash 的 [Implement Equality and Hashing](http://www.mikeash.com/pyblog/friday-qa-2010-06-18-implementing-equality-and-hashing.html) 和 NSHipster 的 [Equality](http://nshipster.com/equality/) 为我们很好地阐述了如何实现。首先，我们需要写一个 `isEqual:` 方法：

    - (BOOL)isEqual:(id)obj
    {
        if(![obj isKindOfClass:[Person class]]) return NO;
        
        Person* other = (Person*)obj;
    
        BOOL nameIsEqual = self.name == other.name || [self.name isEqual:other.name];
        BOOL birthDateIsEqual = self.birthDate == other.birthDate || [self.birthDate isEqual:other.birthDate];
        BOOL numberOfKidsIsEqual = self.numberOfKids == other.numberOfKids;
        return nameIsEqual && birthDateIsEqual && numberOfKidsIsEqual;
    }

如上，我们先检查输入和自身是否是同样的类。如果不是的话，那肯定就不相等了。然后对每一个对象属性，判断其指针是否相等。`||` 操作符的操作看起来好像是不必要的，但是如果我们需要处理两个属性都是 `nil` 的情形的话，它能够正确地返回 `YES`。比较像 `NSUInteger` 这样的标量是否相等时，则只需要使用 `==` 就可以了。

还有一件事情值得一提：这里我们将不同的属性比较的结果分开存储到了它们自己的 `BOOL` 中。在实践中，可能将它们放到一个大的判断语句中会更好，因为如果这么做的话你就可以避免一些不必要的取值和比较了。比如在上面的例子中，如果 `name` 已经不相等了的话，我们就没有必要再检查其他的属性了。将所有判断合并到一个 if 语句中我们可以自动地得到这样的优化。

接下来，按照[文档](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/Protocols/NSObject_Protocol/Reference/NSObject.html#//apple_ref/occ/intfm/NSObject/isEqual:)所说，我们还需要实现一个 hash 函数。苹果如是说：

> 如果两个对象是相等的，那么它们必须有同样的 hash 值。如果你在一个子类里定义了 isEqual: 方法，并且打算将这个子类的实例放到集合类中的话，那么你一定要确保你也在你的子类里定义了 hash 方法，这是非常重要的。

首先，我们来看看如果不实现 `hash` 方法的话，下面的代码会发生什么；

    Person* p1 = [[Person alloc] initWithName:name birthDate:start numberOfKids:0];
    Person* p2 = [[Person alloc] initWithName:name birthDate:start numberOfKids:0];
    NSDictionary* dict = @{p1: @"one", p2: @"two"};
    NSLog(@"%@", dict);

第一次运行上面的代码是，一切都很正常，字典中有两个条目。但是第二次运行的时候却只剩一个了。事情变得不可预测，所以我们还是按照文档说的来做吧。

可能你还记得你在计算机科学课程中学到过，编写一个好的 hash 函数是一件不太容易的事情。好的 hash 函数需要兼备*确定性*和*均布性*。确定性需要保证对于同样的输入总是能生成同样的 hash 值。均布性需要保证输出的结果要在输出范围内均匀地对应输入。你的输出分布越均匀，就意味着当你将这些对象用在集合中时，性能会越好。

首先我们得搞清楚到底发生了什么。让我们来看看没有实现 hash 函数时候的情况下，使用 `Person` 对象作为字典的键时的情况：

    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    
    NSDate* start = [NSDate date];
    for (int i = 0; i < 50000; i++) {
        NSString* name = randomString();
        Person* p = [[Person alloc] initWithName:name birthDate:[NSDate date] numberOfKids:i++];
        [dictionary setObject:@"value" forKey:p];
    }
    NSLog(@"%f", [[NSDate date] timeIntervalSinceDate:start]);

这在我的机子上花了 29 秒时间来执行。作为对比，当我们实现一个基本的 `hash` 方法的时候，同样的代码只花了 0.4 秒。这并不是精确的性能测试，但是却足以告诉我们实现一个正确的 `hash` 函数的重要性。对于 `Person` 这个类来说，我们可以从这样一个 hash 函数开始：

    - (NSUInteger)hash
    {
        return self.name.hash ^ self.birthDate.hash ^ self.numberOfKids;
    }

这将从我们的属性中取出三个 hash 值，然后将它们做 `XOR` (异或) 操作。在这里，这个方法对我们的目标来说已经足够好了，因为对于短字符串 (以前这个上限是 [96 个字符](http://www.abakia.de/blog/2012/12/05/nsstring-hash-is-bad/)，不过现在不是这样了，参见 [CFString.c](http://www.opensource.apple.com/source/CF/CF-855.11/CFString.c) 中 hash 的部分) 来说，`NSString` 的 hash 函数表现很好。对于更正式的 hash 算法，hash 函数应该依赖于你所拥有的数据。这在 [Mike Ash 的文章](http://www.mikeash.com/pyblog/friday-qa-2010-06-18-implementing-equality-and-hashing.html)和[其他一些地方](http://www.burtleburtle.net/bob/hash/spooky.html)有所涉及。

在 `hash` [文档](https://developer.apple.com/library/mac/documentation/cocoa/Reference/Foundation/Protocols/NSObject_Protocol/Reference/NSObject.html#//apple_ref/occ/intfm/NSObject/hash)中，有下面这样一段话：

> 如果一个被插入集合类的可变对象是依据其 hash 值来决定其在集合中的位置的话，这个对象的
> hash 函数所返回的值在该对象存在于集合中时是不允许改变的。因此，要么使用一个和对象内部
> 状态无关的 hash 函数，要么确保在对象处于集合中时其内部状态不发生改变。比如说，一个可
> 变字典可以被放到一个 hash table 中，但是只要这个字典还在 hash table 中时，你就不能
> 更改它。(注意，要知道一个给定对象是不是存在于某个集合中是一件很困难的事情。)

这也是你需要确保对象的不可变性的另一个重要原因。只要确保了这一点，你就不必再担心这个问题了。

##### 扩展阅读

* [A hash function for CGRect](https://gist.github.com/steipete/6133152)
* [A Hash Function for Hash Table Lookup](http://www.burtleburtle.net/bob/hash/doobs.html)
* [SpookyHash: a 128-bit noncryptographic hash](http://www.burtleburtle.net/bob/hash/spooky.html)
* [Why do hash functions use prime numbers?](http://computinglife.wordpress.com/2008/11/20/why-do-hash-functions-use-prime-numbers/)


## NSCopying

为了让我们的对象更有用，我们最好实现一下 `NSCopying` 接口。这能够使我们能在容器类中使用它们。对于我们的类的一个可变的变体，可以这么实现 `NSCopying`：

    - (id)copyWithZone:(NSZone *)zone
    {
        Person* p = [[Person allocWithZone:zone] initWithName:self.name
                                                    birthDate:self.birthDate
                                                 numberOfKids:self.numberOfKids];
        return p;
    }

然而，在接口的文档中，他们提到了另一种实现 `NSCopying` 的方式：

> 对于不可变的类和其内容来说，NSCopying 的实现应该保持原来的对象，而不是创建一份新的拷贝。

所以，对于我们的不可变版本，我们只需要这样就够了：

    - (id)copyWithZone:(NSZone *)zone
    {
        return self;
    }

## NSCoding

如果我们想要序列化对象，我们可以实现 `NSCoding`。这个接口中有两个 required 的方法：

    - (id)initWithCoder:(NSCoder *)decoder
    - (void)encodeWithCoder:(NSCoder *)encoder

实现这个和实现判等方法同样直接，也同样机械化：

    - (id)initWithCoder:(NSCoder *)aDecoder
    {
        self = [super init];
        if (self) {
            _name = [aDecoder decodeObjectForKey:@"name"];
            _birthDate = [aDecoder decodeObjectForKey:@"birthDate"];
            _numberOfKids = [aDecoder decodeIntegerForKey:@"numberOfKids"];
        }
        return self;
    }
    
    - (void)encodeWithCoder:(NSCoder *)aCoder
    {
        [aCoder encodeObject:self.name forKey:@"name"];
        [aCoder encodeObject:self.birthDate forKey:@"birthDate"];
        [aCoder encodeInteger:self.numberOfKids forKey:@"numberOfKids"];
    }

可以在 [NSHipster](http://nshipster.com/nscoding/) 和 [Mike Ash 的博客](http://www.mikeash.com/pyblog/friday-qa-2013-08-30-model-serialization-with-property-lists.html)上了解这方面的更多内容。顺带一提，在处理比如来自网络的数据这样不信任的来源的数据时，不要使用 `NSCoding`，因为数据可能被篡改过。通过[修改归档的数据](https://developer.apple.com/library/mac/documentation/security/conceptual/securecodingguide/Articles/ValidatingInput.html#//apple_ref/doc/uid/TP40007246-SW9)，很容易实施远程代码运行攻击。在处理这样的数据时，应该使用 [`NSSecureCoding`](http://nshipster.com/nssecurecoding/) 或者像 JSON 这样的自定义格式

## Mantle

现在，我们还有一个问题：这些能自动化么？答案是能。一种方式是1代码生成，但是幸运的是有一种更好的替代：[Mantle](https://github.com/github/Mantle)。Mantle 使用自举 (introspection) 的方法生成 `isEqual:` 和 `hash`。另外，它还提供了一些帮助你创建字典的方法，它们可以被用来读写 JSON。当然，一般来说在运行时做这些不如你自己写起来高效，但是另一方面，自动处理这个流程的话犯错的可能性要小得多。

## 可变性

在 C 中可变值是默认的，其实在 Objective-C 中也是这样的。一方面，这非常方便，因为你可以在任何时候改变它。在构建相对小的系统外，这一般不成问题。但是正如我们中很多人的经验一样，在构建较大的系统时，使用不可变的对象会容易得多。在 Objective-C 中，我们一直是使用不可变对象的，现在其他的语言也逐渐开始添加不可变对象了。

我们来看看使用可变对象的两个问题。其中一个是它们有可能在你不希望的时候发生改变，另一个是在多线程中使用可变对象。

### 不希望的改变

假设我们有一个 table view controller，其中有一个 `people` 属性：

    @interface ViewController : UITableViewController

    @property (nonatomic) NSArray* people;

    @end

在实现中，我们仅仅把数组中的每个元素映射到一个 cell 中：

     - (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
     {
         return 1;
     }
     
     - (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
     {
         return self.people.count;
     }


现在，在设定上面的 view controller 中，我们的代码可能是这样的：

    self.items = [NSMutableArray array];
    [self loadItems]; // Add 100 items to the array
    tableVC.people = self.items;
    [self.navigationController pushViewController:tableVC animated:YES];

table view 将开始执行 `tableView:numberOfRowsInSection:` 之类的方法，一开始，一切都 OK。但是假设在某个时候，我们进行了这样的操作：

    [self.items removeObjectAtIndex:1];

这改变了 `items` 数组，但是它*同时*也改变了我们的 table view controller 中的 `people` 数组。如果我们没有进一步地同 table view controller 进行通讯的话，table view 还会认为有 100 个元素需要显示，然而我们的数组却只包括 99 个元素。你大概知道我们会面临怎样的窘境了。在这里，我们应该做的是将属性声明为 `copy`：

     @interface ViewController : UITableViewController
     
     @property (nonatomic, copy) NSArray* items;
     
     @end

现在，我们在将可变数组设置给 items 的时候，会生成一个不可变的 copy。如果我们设定的是一个通常 (不可变) 的数组，那么 copy 操作是没有开销的，它仅仅只是增加了引用计数。

### 多线程

假设我们有一个用来表示银行账号的可变对象 `Account`，其有一个 `transfer:to:` 方法：

    - (void)transfer:(double)amount to:(Account*)otherAccount
    {
        self.balance = self.balance - amount;
        otherAccount.balance = otherAccount.balance + amount;
    }

多线程的代码可能会在以很多方式挂掉。比如线程 A 要读取 `self.balance`，线程 B 有可能在 A 继续之前就修改了这个值。对于这其中可能造成的各种风险，请参看我们的[话题二](http://objccn.io/issue-2/)。

如果我们使用的是不可变对象的话，事情就简单多了。我们不能改变它们，这个规则迫使我们在一个完全不一样的层级上来提供可变性，这将使代码简单得多。

### 缓存

不可变性还能在缓存数值方面帮助我们。比如，假设你已经将一个 markdown 文档解析成一个带有表示各种不同元素的结点的树结构了。在你想从这个结构中生成 HTML 的时候，因为你知道这些元素都不会再改变，所以可以该将这些值都缓存下来。如果你的对象是可变的，你可能就需要每次都从头开始生成 HTML，或者是为每一个对象做构建优化和观察操作。如果是不可变的话，你就不必担心缓存会失效了。当然，这可能会带来性能的下降，但是在绝大多数情况下，简单带来的好处相比于那一点轻微的性能下降是值得的。

### 其他语言的不可变性

不可变对象是从像 [Haskell](http://www.haskell.org/) 这样的函数式编程语言中借鉴过来的概念。在 Haskell 中，值默认都是不可变的。Haskell 程序一般都有一个[单纯函数式 (purely functional)](http://en.wikipedia.org/wiki/Purely_functional) 作为核心，在其中没有可变对象，没有状态，也没有像 I/O 这样的副作用。

在 Objective-C 程序中我们可以借鉴这些。在任何可能的地方使用不可变的对象，我们的程序会变得容易测试得多。Gary Bernhardt 做了一个很棒的[演讲](https://www.destroyallsoftware.com/talks/boundaries)，向我们展示了使用不可变对象如何帮助我们开发更好的软件。在演讲中他用的是 Ruby，但是在 Objective-C 中，概念其实是相通的。

##### 扩展阅读

 * [Cocoa Encyclopedia: Object Mutability](https://developer.apple.com/library/mac/documentation/General/Conceptual/CocoaEncyclopedia/ObjectMutability/ObjectMutability.html#//apple_ref/doc/uid/TP40010810-CH5-SW1)
* [Mutability and Caching](http://garbagecollective.quora.com/Mutability-aliasing-and-the-caches-you-didnt-know-you-had)

---

 

原文: [Value Objects](http://www.objc.io/issue-7/value-objects.html)
