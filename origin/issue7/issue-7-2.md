[Source](http://www.objc.io/issue-7/value-objects.html "Permalink to Value Objects - Foundation - objc.io issue #7 ")

# Value Objects - Foundation - objc.io issue #7 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# Value Objects

[Issue #7 Foundation][4], December 2013

By [Chris Eidhof][5]

In this article, we’ll look at how to write [value objects][6] in Objective-C. In doing that, we’ll touch upon important protocols and methods in Objective-C. A value object is an object that holds some values, and can be compared for equality. Often, value objects can be used as model objects. For example, consider a simple `Person` object:


    @interface Person : NSObject

    @property (nonatomic,copy) NSString* name;
    @property (nonatomic) NSDate* birthDate;
    @property (nonatomic) NSUInteger numberOfKids;

    @end

Creating these kinds of objects is the bread and butter of our work, and while these objects look deceivingly simple, there are a lot of subtleties involved.

One thing that a lot of us learned the hard way is that these objects should be immutable. Once you create a `Person` object, it’s impossible to change it anymore. We’ll touch upon mutability later in this issue.

## Properties

The first thing to notice is that we use properties to define the attributes that a `Person` has. Creating the properties is quite mechanical: for normal properties, you make them `nonatomic`. By default, object properties are `strong`, and scalar properties are `assign`. There’s one exception: for properties that have a mutable counterpart, you want to define them as `copy`. For example, the `name` property is of type `NSString`. What could happen is that somebody creates a `Person` object and assigns a value of type `NSMutableString`. Then, sometime later, he or she might change the mutable string. If our property would have been `strong` instead of `copy`, our `Person` object would have changed too, which is not what we want. It’s the same for containers, such as arrays or dictionaries.

Be aware that the copy is shallow; the containers might still contain mutable objects. For example, if you have an `NSMutableArray* a` containing `NSMutableDictionary` elements, then [`a copy]` will give you an immutable array, but the elements will be the same `NSMutableDictionary` objects. As we’ll see later, copy for immutable objects is free, but it increases the retain count.

In older code, you might not see properties, as they are a relatively recent addition to Objective-C. Instead of properties, you might see custom getters and setters, or plain instance variables. For modern code, it seems most people agree on using properties, which is also what we recommend.

##### More Reading

[`NSString`: `copy` or `retain`][7]

## Initializers

If we want immutable objects, we should make sure that they can’t be modified after being created. We can do this by adding an initializer and making our properties readonly in the interface. Our interface then looks like this:


    @interface Person : NSObject

    @property (nonatomic,readonly) NSString* name;
    @property (nonatomic,readonly) NSDate* birthDate;
    @property (nonatomic,readonly) NSUInteger numberOfKids;

    - (instancetype)initWithName:(NSString*)name
                       birthDate:(NSDate*)birthDate
                    numberOfKids:(NSUInteger)numberOfKids;

    @end

Then, in our implementation, we have to use instance variables instead of properties:


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

Now, we can construct new `Person` objects, but not modify them anymore. This is very helpful; when writing other classes that work with `Person` objects, we know that these values won’t change as we are working with them. Also note that `copy` is not part of the interface anymore: it is now an implementation detail.

## Comparing for Equality

To compare for equality, we have to implement the `isEqual:` method. We want the `isEqual:` method to be true if and only if all properties are equal. There are two good articles by Mike Ash ([Implement Equality and Hashing][8]) and NSHipster ([Equality][9]) that explain how to do this. First, let’s write `isEqual:`:


    - (BOOL)isEqual:(id)obj
    {
        if(![obj isKindOfClass:[Person class]]) return NO;

        Person* other = (Person*)obj;

        BOOL nameIsEqual = self.name == other.name || [self.name isEqual:other.name];
        BOOL birthDateIsEqual = self.birthDate == other.birthDate || [self.birthDate isEqual:other.birthDate];
        BOOL numberOfKidsIsEqual = self.numberOfKids == other.numberOfKids;
        return nameIsEqual && birthDateIsEqual && numberOfKidsIsEqual;
    }

Now, we check if we’re the same kind of class. If not, we’re definitely not equal. Then, for each object property, we check if the pointer is equal. The left operand of the `||` might seem superfluous, but it’s there to return `YES` if both properties are `nil`. To compare scalar values like `NSUInteger` for equality, we can just use `==`.

One thing that’s good to note: here, we split up the different properties into their own `BOOL`s. In practice, it might make more sense to combine them into one big clause, because then you get the lazy evaluation for free. In the example above, if the `name` is not equal, we don’t need to check any of the other properties. By combining everything into one if statement we get that optimization for free.

Next, as [per the documentation][10], we need to implement a hash function as well. Apple says:

> If two objects are equal, they must have the same hash value. This last point is particularly important if you define isEqual: in a subclass and intend to put instances of that subclass into a collection. Make sure you also define hash in your subclass.

First, we can try to run the following code, without having a `hash` function implemented:


    Person* p1 = [[Person alloc] initWithName:name birthDate:start numberOfKids:0];
    Person* p2 = [[Person alloc] initWithName:name birthDate:start numberOfKids:0];
    NSDictionary* dict = @{p1: @"one", p2: @"two"};
    NSLog(@"%@", dict);

The first time I ran the above code, everything was sort of okay, and there were two items in the dictionary. The second time, there was only one. Things just get very unpredictable, so let’s just do as the documentation says.

As you might remember from your computer science classes, writing a good hash function is not easy. A good hash function needs to be _deterministic_ and _uniform_. Deterministic means that the same input needs to generate the same hash value. Uniform means that the result of the hash function should map the inputs uniformly over the output range. The more uniform your output, the better the performance when you use these objects in a collection.

First, just for kicks, let’s have a look at what happens when we don’t have a hash function, and we try to use `Person` objects as keys in a dictionary:


    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];

    NSDate* start = [NSDate date];
    for (int i = 0; i < 50000; i%2B%2B) {
        NSString* name = randomString();
        Person* p = [[Person alloc] initWithName:name birthDate:[NSDate date] numberOfKids:i%2B%2B];
        [dictionary setObject:@"value" forKey:p];
    }
    NSLog(@"%f", [[NSDate date] timeIntervalSinceDate:start]);

This takes 29 seconds on my machine. In comparison, when we implement a basic `hash` function, the same code runs in 0.4 seconds. These are not proper benchmarks, but do give a very good indication of why it’s important to implement a proper `hash` function. For the `Person` class, we can start with a hash function like this:


    - (NSUInteger)hash
    {
        return self.name.hash ^ self.birthDate.hash ^ self.numberOfKids;
    }

This will take the three hashes from our properties and `XOR` them. In this case, it’s good enough for our purposes, because the `NSString` hashing function is good for short strings (it used to only perform well for strings [up to 96 characters][11], but now that has changed. See [CFString.c][12], look for `hash`). For serious hashing, your hashing function depends on the data you have. This is covered in [Mike Ash’s article][8] and [elsewhere][13].

In [the documentation][14] for `hash`, there’s the following paragraph:

> If a mutable object is added to a collection that uses hash values to determine the object’s position in the collection, the value returned by the hash method of the object must not change while the object is in the collection. Therefore, either the hash method must not rely on any of the object’s internal state information or you must make sure the object’s internal state information does not change while the object is in the collection. Thus, for example, a mutable dictionary can be put in a hash table but you must not change it while it is in there. (Note that it can be difficult to know whether or not a given object is in a collection.)

This is another very important reason to make sure your objects are immutable. Then you don’t even have to worry about this problem.

##### More Reading

  * [A hash function for CGRect][15]
  * [A Hash Function for Hash Table Lookup][16]
  * [SpookyHash: a 128-bit noncryptographic hash][13]
  * [Why do hash functions use prime numbers?][17]

## NSCopying

To make sure our objects are useful, it’s convenient to have implemented the `NSCopying` protocol. This allows us, for example, to use them in container classes. For a mutable variant of our class, `NSCopying` can be implemented like this:


    - (id)copyWithZone:(NSZone *)zone
    {
        Person* p = [[Person allocWithZone:zone] initWithName:self.name
                                                    birthDate:self.birthDate
                                                 numberOfKids:self.numberOfKids];
        return p;
    }

However, in the protocol documentation, they mention another way to implement `NSCopying`:

> Implement NSCopying by retaining the original instead of creating a new copy when the class and its contents are immutable.

So, for our immutable version, we can just do this:


    - (id)copyWithZone:(NSZone *)zone
    {
        return self;
    }

## NSCoding

If we want to serialize our objects, we can do that by implementing `NSCoding`. This protocol exists of two required methods:


    - (id)initWithCoder:(NSCoder *)decoder
    - (void)encodeWithCoder:(NSCoder *)encoder

Implementing this is equally straightforward as implementing the equals methods, and also quite mechanical:


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

Read more about it on [NSHipster][18] and [Mike Ash’s blog][19]. By the way, don’t use `NSCoding` when dealing with untrusted sources, such as data coming from the network, because the data may be tampered with. By [modifying the archived data][20], it’s very possible to perform a remote code execution attack. Instead, use [`NSSecureCoding`][21] or a custom format like JSON.

## Mantle

Now, we’re left with the question: can we automate this? It turns out we can. One way would be code generation, but luckily there’s a better alternative: [Mantle][22]. Mantle uses introspection to generate `isEqual:` and `hash`. In addition, it provides methods that help you create dictionaries, which can then be used to write and read JSON. Of course, doing this generically and at runtime will not be as efficient as writing your own, but on the other hand, doing it automatically is a process that is much less prone to errors.

## Mutability

In C, and also in Objective-C, mutable values are the default. In a way, they are very convenient, in that you can change anything at anytime. When building smaller systems, this is mostly not a problem. However, as many of us learned the hard way, when building larger systems, it is much easier when things are immutable. In Objective-C, we’ve had immutable objects for a long time, and now other languages are also starting to add it.

We’ll look at two problems with mutable objects. One is that they might change when you don’t expect it, and the other one is when using mutable objects in a multithreading context.

### Unexpected Changes

Suppose we have a table view controller, which has a `people` property:


    @interface ViewController : UITableViewController

    @property (nonatomic) NSArray* people;

    @end

And in our implementation, we just map each array element to a cell:


     - (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
     {
         return 1;
     }

     - (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
     {
         return self.people.count;
     }

Now, in the code that sets up the above view controller, we might have code like this:


    self.items = [NSMutableArray array];
    [self loadItems]; // Add 100 items to the array
    tableVC.people = self.items;
    [self.navigationController pushViewController:tableVC animated:YES];

The table view will start firing methods like `tableView:numberOfRowsInSection:`, and at first, everything will be fine. But suppose that, at some point, we do the following:


    [self.items removeObjectAtIndex:1];

This changes our `items` array, but it _also_ changes the `people` array in our table view controller. If we do this without any further communication to the table view controller, the table view will still think there are 100 items, whereas our array will only contain 99. Bad things will happen. Instead, what we should have done is declare our property as `copy`:


     @interface ViewController : UITableViewController

     @property (nonatomic, copy) NSArray* items;

     @end

Now, whenever we assign a mutable array to items, an immutable copy will be made. If we assign a regular (immutable) array value, the copy operation is free, and it only increases the retain count.

### Multithreading

Suppose we have a mutable object, `Account`, representing a bank account, that has a method `transfer:to:`:


    - (void)transfer:(double)amount to:(Account*)otherAccount
    {
        self.balance = self.balance - amount;
        otherAccount.balance = otherAccount.balance %2B amount;
    }

Multithreaded code can go wrong in many ways. For example, if thread A reads `self.balance`, thread B might be modifying it before thread A continues. For a good explanation of all the dangers involved, see our [second issue][23].

If we have immutable objects instead, things are much easier. We cannot modify them, and this forces us to provide mutability at a completely different level, yielding much simpler code.

### Caching

Another thing where immutability can help is when caching values. For example, suppose you’ve parsed a markdown document into a tree structure with nodes for all the different elements. If you want to generate HTML out of that, you can cache the value, because you know no children will ever change. If you have mutable objects, you would need to either generate the HTML from scratch every time, or build optimizations and observe every single object. With immutability, you don’t have to worry about invalidating caches. Of course, this might come with a performance penalty. In almost all cases, however, the simplicity will outweigh the slight decrease in performance.

### Immutability in Other Languages

Immutable objects are one of the concepts inspired by functional programming languages like [Haskell][24]. In Haskell, values are immutable by default. Haskell programs typically have a [purely functional][25] core, where there are no mutable objects, there is no state, and there are no side-effects like I/O.

We can learn from this in Objective-C programming. By having immutable objects where possible, our programs become much easier to test. There’s a great [talk by Gary Bernhardt][26] that shows how having immutable objects helps us write better software. In the talk he uses Ruby, but the concepts apply equally well to Objective-C.

##### Further Reading

  * [Cocoa Encyclopedia: Object Mutability][27]
  * [Mutability and Caching][28]




* * *

[More articles in issue #7][29]

  * [Privacy policy][30]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-7/index.html
   [5]: http://twitter.com/chriseidhof
   [6]: http://en.wikipedia.org/wiki/Value_object
   [7]: http://stackoverflow.com/questions/387959/nsstring-property-copy-or-retain
   [8]: http://www.mikeash.com/pyblog/friday-qa-2010-06-18-implementing-equality-and-hashing.html
   [9]: http://nshipster.com/equality/
   [10]: https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/Protocols/NSObject_Protocol/Reference/NSObject.html#//apple_ref/occ/intfm/NSObject/isEqual:
   [11]: http://www.abakia.de/blog/2012/12/05/nsstring-hash-is-bad/
   [12]: http://www.opensource.apple.com/source/CF/CF-855.11/CFString.c
   [13]: http://www.burtleburtle.net/bob/hash/spooky.html
   [14]: https://developer.apple.com/library/mac/documentation/cocoa/Reference/Foundation/Protocols/NSObject_Protocol/Reference/NSObject.html#//apple_ref/occ/intfm/NSObject/hash
   [15]: https://gist.github.com/steipete/6133152
   [16]: http://www.burtleburtle.net/bob/hash/doobs.html
   [17]: http://computinglife.wordpress.com/2008/11/20/why-do-hash-functions-use-prime-numbers/
   [18]: http://nshipster.com/nscoding/
   [19]: http://www.mikeash.com/pyblog/friday-qa-2013-08-30-model-serialization-with-property-lists.html
   [20]: https://developer.apple.com/library/mac/documentation/security/conceptual/securecodingguide/Articles/ValidatingInput.html#//apple_ref/doc/uid/TP40007246-SW9
   [21]: http://nshipster.com/nssecurecoding/
   [22]: https://github.com/github/Mantle
   [23]: http://www.objc.io/issue-2/
   [24]: http://www.haskell.org/
   [25]: http://en.wikipedia.org/wiki/Purely_functional
   [26]: https://www.destroyallsoftware.com/talks/boundaries
   [27]: https://developer.apple.com/library/mac/documentation/General/Conceptual/CocoaEncyclopedia/ObjectMutability/ObjectMutability.html#//apple_ref/doc/uid/TP40010810-CH5-SW1
   [28]: http://garbagecollective.quora.com/Mutability-aliasing-and-the-caches-you-didnt-know-you-had
   [29]: http://www.objc.io/issue-7
   [30]: http://www.objc.io/privacy.html
