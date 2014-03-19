[Source](http://www.objc.io/issue-2/thread-safe-class-design.html "Permalink to Thread-Safe Class Design - Concurrent Programming - objc.io issue #2 ")

# Thread-Safe Class Design - Concurrent Programming - objc.io issue #2 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# Thread-Safe Class Design

[Issue #2 Concurrent Programming][4], July 2013

By [Peter Steinberger][5]

This article will focus on _practical_ tips, design patterns, and anti-patterns with regard to writing thread-safe classes and using Grand Central Dispatch (GCD).

## Thread Safety

### Apple’s Frameworks

First, let’s have a look at Apple’s frameworks. In general, unless declared otherwise, most classes are not thread-safe by default. For some this is expected; for others it’s quite interesting.

One of the most common mistakes even experienced iOS/Mac developers make is accessing parts of UIKit/AppKit on background threads. It’s very easy to make the mistake of setting properties like `image` from a background thread, because their content is being requested from the network in the background anyway. Apple’s code is performance-optimized and will not warn you if you change properties from different threads.

In the case of an image, a common symptom is that your change is picked up with a delay. But if two threads set the image at the same time, it’s likely that your app will simply crash, because the currently set image could be released twice. Since this is timing dependent, it usually will crash when used by your customers and not during development.

There are no _official_ tools to find such errors, but there are some tricks that will do the job just fine. The [UIKit Main Thread Guard][6] is a small source file that will patch any calls to UIView’s `setNeedsLayout` and `setNeedsDisplay` and check for being executed on the main thread before forwarding the call. Since these two methods are called for a lot of UIKit setters (including image), this will catch many thread-related mistakes. Although this trick does not use private API, we don’t recommend using this in production apps – it’s great during development though.

It’s a conscious design decision from Apple’s side to not have UIKit be thread-safe. Making it thread-safe wouldn’t buy you much in terms of performance; it would in fact make many things slower. And the fact that UIKit is tied to the main thread makes it very easy to write concurrent programs and use UIKit. All you have to do is make sure that calls into UIKit are always made on the main thread.

#### Why Isn’t UIKit Thread Safe?

Ensuring thread safety for a big framework like UIKit would be a major undertaking and would come at a great cost. Changing non-atomic to atomic properties would only be a tiny part of the changes required. Usually you want to change several properties at once, and only then see the changed result. For this, Apple would have to expose a method much like CoreData’s `performBlock:` and `performBlockAndWait:` to synchronize changes. And if you consider that most calls to UIKit classes are about _configuration_, it’s even more pointless to make them thread-safe.

However, even calls that are not about configuration shared internal state and thus weren’t thread-safe. If you already wrote apps back in the dark ages of iOS3.2 and before, you surely experienced random crashes when using NSString’s `drawInRect:withFont:` while preparing background images. Thankfully, with iOS4, [Apple made most drawing methods and classes like `UIColor` and `UIFont` usable on background threads][7].

Unfortunately, Apple’s documentation is lacking on the subject of thread safety. They recommend access on the main thread only, and even for drawing methods they don’t explicitly guarantee thread safety - so it’s always a good idea to read the [iOS Release Notes][7] as well.

For the most part, UIKit classes should be used only from the application’s main thread. This is particularly true either for classes derived from UIResponder or those that involve manipulating your application’s user interface in any way.

#### The Deallocation Problem

Another danger when using UIKit objects in the background is called “The Deallocation Problem.” Apple outlines the issue in [TN2109][8] and presents various solutions. The problem is that UI objects should be deallocated on the main thread, because some of them might perform changes to the view hierarchy in `dealloc`. As we know, such calls to UIKit need to happen on the main thread.

Since it’s common that a secondary thread, operation, or block retains the caller, this is very easy to get wrong and quite hard to find/fix. This was also [a long-standing bug in AFNetworking][9], simply because not a lot of people know about this issue and – as usual – it manifests itself in rare, hard-to-reproduce crashes. Consistent use of __weak and not accessing ivars in async blocks/operations helps.

#### Collection Classes

Apple has a good overview document for both [iOS and Mac][10] listing thread safety for the most common foundation classes. In general, immutable classes like `NSArray` are thread-safe, while their mutable variants like `NSMutableArray` are not. In fact, it’s fine to use them from different threads, as long as access is serialized within a queue. Remember that methods might return a mutable variant of a collection object even if they declare their return type as immutable. It’s good practice to write something like `return [array copy]` to ensure the returned object is in fact immutable.

Unlike in languages like [Java][11], the Foundation framework doesn’t offer thread-safe collection classes out of the box. This is actually very reasonable, because in most cases you want to apply your locks higher up anyway to avoid too many locking operations. A notable exception are caches, where a mutable dictionary might hold immutable data – here Apple added `NSCache` in iOS4 that not only locks access, but also purges its content in low-memory situations.

That said, there might be valid cases in your application where a thread-safe, mutable dictionary can be handy. And thanks to the class cluster approach, [it’s easy to write one][12].

### Atomic Properties

Ever wondered how Apple is handling atomic setting/getting of properties? By now you have likely heard about spinlocks, semaphores, locks, @synchronized - so what’s Apple using? Thankfully, [the Objective-C runtime is public][13], so we can take a look behind the curtain.

A nonatomic property setter might look like this:


    - (void)setUserName:(NSString *)userName {
          if (userName != _userName) {
              [userName retain];
              [_userName release];
              _userName = userName;
          }
    }

This is the variant with manual retain/release; however, the ARC-generated code looks similar. When we look at this code it’s obvious why this means trouble when `setUserName:` is called concurrently. We could end up releasing `_userName` twice, which can corrupt memory and lead to hard-to-find bugs.

What’s happening internally for any property that’s not manually implemented is that the compiler generates a call to [`objc_setProperty_non_gc(id self, SEL _cmd, ptrdiff_t offset, id newValue, BOOL atomic, signed char shouldCopy)`][14]. In our example, the call parameters would look like this:


    objc_setProperty_non_gc(self, _cmd,
      (ptrdiff_t)(&_userName) - (ptrdiff_t)(self), userName, NO, NO);`

The ptrdiff_t might look weird to you, but in the end it’s simple pointer arithmetic, since an Objective-C class is just another C struct.

`objc_setProperty` calls down to following method:


    static inline void reallySetProperty(id self, SEL _cmd, id newValue,
      ptrdiff_t offset, bool atomic, bool copy, bool mutableCopy)
    {
        id oldValue;
        id *slot = (id*) ((char*)self %2B offset);

        if (copy) {
            newValue = [newValue copyWithZone:NULL];
        } else if (mutableCopy) {
            newValue = [newValue mutableCopyWithZone:NULL];
        } else {
            if (*slot == newValue) return;
            newValue = objc_retain(newValue);
        }

        if (!atomic) {
            oldValue = *slot;
            *slot = newValue;
        } else {
            spin_lock_t *slotlock = &PropertyLocks[GOODHASH(slot)];
            _spin_lock(slotlock);
            oldValue = *slot;
            *slot = newValue;
            _spin_unlock(slotlock);
        }

        objc_release(oldValue);
    }

Aside from the rather funny name, this method is actually fairly straightforward and uses one of the 128 available spinlocks in `PropertyLocks`. This is a pragmatic and fast approach – the worst case scenario is that a setter might have to wait for an unrelated setter to finish because of a hash collision.

While those methods aren’t declared in any public header, it is possible to call them manually. I’m not saying this is a good idea, but it’s interesting to know and could be quite useful if you want atomic properties _and_ to implement the setter at the same time.


    // Manually declare runtime methods.
    extern void objc_setProperty(id self, SEL _cmd, ptrdiff_t offset,
      id newValue, BOOL atomic, BOOL shouldCopy);
    extern id objc_getProperty(id self, SEL _cmd, ptrdiff_t offset,
      BOOL atomic);

    #define PSTAtomicRetainedSet(dest, src) objc_setProperty(self, _cmd,
      (ptrdiff_t)(&dest) - (ptrdiff_t)(self), src, YES, NO)
    #define PSTAtomicAutoreleasedGet(src) objc_getProperty(self, _cmd,
      (ptrdiff_t)(&src) - (ptrdiff_t)(self), YES)

[Refer to this gist][15] for the full snippet including code to handle structs. But keep in mind that we don’t recommend using this.

#### What about @synchronized?

You might be curious why Apple isn’t using `@synchronized(self)` for property locking, an already existing runtime feature. Once you [look at the source][16], you’ll see that there’s a lot more going on. Apple is using [up to three lock/unlock sequences][17], partly because they also add [exception unwinding][18]. This would be a slowdown compared to the much faster spinlock approach. Since setting the property usually is quite fast, spinlocks are perfect for the job. `@synchonized(self)` is good when you need to ensure that exception can be thrown without the code deadlocking.

### Your Own Classes

Using atomic properties alone won’t make your classes thread-safe. It will only protect you against [race conditions][19] in the setter, but won’t protect your application logic. Consider the following snippet:


    if (self.contents) {
        CFAttributedStringRef stringRef = CFAttributedStringCreate(NULL,
          (__bridge CFStringRef)self.contents, NULL);
        // draw string
    }

I’ve made this mistake early on in [PSPDFKit][20]. From time to time, the application crashed with a EXC_BAD_ACCESS, when the `contents` property was set to nil after the check. A simple fix for this issue would be to capture the variable:


    NSString *contents = self.contents;
    if (contents) {
        CFAttributedStringRef stringRef = CFAttributedStringCreate(NULL,
          (__bridge CFStringRef)contents, NULL);
        // draw string
    }

This would solve the issue here, but in most cases it’s not that simple. Imagine that we also have a `textColor` property and we change both properties on one thread. Then our render thread could end up using the new content along with the old color value and we get a weird combination. This is one reason why Core Data binds model objects to one thread or queue.

There’s no one-size-fits-all solution for this problem. Using [immutable models][21] is a solution, but it has its own problems. Another way is to limit changes to existing objects to the main thread or a specific queue and to generate copies before using them on worker threads. I recommend Jonathan Sterling’s article about [Lightweight Immutability in Objective-C][22] for even more ideas on solving this problem.

The simple solution is to use @synchronize. Anything else is very, very likely to get you into trouble. Way smarter people have failed again and again at doing so.

#### Practical Thread-Safe Design

Before trying to make something thread-safe, think hard if it’s necessary. Make sure it’s not premature optimization. If it’s anything like a configuration class, there’s no point in thinking about thread safety. A much better approach is to throw some asserts in to ensure it’s used correctly:


    void PSPDFAssertIfNotMainThread(void) {
        NSAssert(NSThread.isMainThread,
          @"Error: Method needs to be called on the main thread. %@",
          [NSThread callStackSymbols]);
    }

Now there’s code that definitely should be thread-safe; a good example is a caching class. A good approach is to use a concurrent dispatch_queue as read/write lock to maximize performance and try to only lock the areas that are really necessary. Once you start using multiple queues for locking different parts, things get tricky really fast.

Sometimes you can also rewrite your code so that special locks are not required. Consider this snippet that is a form of a multicast delegate. (In many cases, using NSNotifications would be better, but there are [valid use cases for multicast delegates.][23])


    // header
    @property (nonatomic, strong) NSMutableSet *delegates;

    // in init
    _delegateQueue = dispatch_queue_create("com.PSPDFKit.cacheDelegateQueue",
      DISPATCH_QUEUE_CONCURRENT);

    - (void)addDelegate:(id)delegate {
        dispatch_barrier_async(_delegateQueue, ^{
            [self.delegates addObject:delegate];
        });
    }

    - (void)removeAllDelegates {
        dispatch_barrier_async(_delegateQueue, ^{
            self.delegates removeAllObjects];
        });
    }

    - (void)callDelegateForX {
        dispatch_sync(_delegateQueue, ^{
            [self.delegates enumerateObjectsUsingBlock:^(id delegate, NSUInteger idx, BOOL *stop) {
                // Call delegate
            }];
        });
    }

Unless `addDelegate:` or `removeDelegate:` is called thousand times per second, a simpler and cleaner approach is the following:


    // header
    @property (atomic, copy) NSSet *delegates;

    - (void)addDelegate:(id)delegate {
        @synchronized(self) {
            self.delegates = [self.delegates setByAddingObject:delegate];
        }
    }

    - (void)removeAllDelegates {
        self.delegates = nil;
    }

    - (void)callDelegateForX {
        [self.delegates enumerateObjectsUsingBlock:^(id delegate, NSUInteger idx, BOOL *stop) {
            // Call delegate
        }];
    }

Granted, this example is a bit constructed and one could simply confine changes to the main thread. But for many data structures, it might be worth it to create immutable copies in the modifier methods, so that the general application logic doesn’t have to deal with excessive locking. Notice how we still have to apply locking in `addDelegate:`, since otherwise delegate objects might get lost if called from different threads concurrently.

## Pitfalls of GCD

For most of your locking needs, GCD is perfect. It’s simple, it’s fast, and its block-based API makes it much harder to accidentally do imbalanced locks. However, there are quite a few pitfalls, some of which we are going to explore here.

### Using GCD as a Recursive Lock

GCD is a queue to serialize access to shared resources. This can be used for locking, but it’s quite different than `@synchronized`. GCD queues are not reentrant - this would break the queue characteristics. Many people tried working around this with using `dispatch_get_current_queue()`, which is [a bad idea][24], and Apple had its reasons for deprecating this method in iOS6.


    // This is a bad idea.
    inline void pst_dispatch_sync_reentrant(dispatch_queue_t queue,
      dispatch_block_t block)
    {
        dispatch_get_current_queue() == queue ? block()
                                              : dispatch_sync(queue, block);
    }

Testing for the current queue might work for simple solutions, but it fails as soon as your code gets more complex, and you might have multiple queues locked at the same time. Once you are there, you almost certainly will get a [deadlock][25]. Sure, one could use `dispatch_get_specific()`, which will traverse the whole queue hierarchy to test for specific queues. For that you would have to write custom queue constructors that apply this metadata. Don’t go that way. There are use cases where a `NSRecursiveLock` is the better solution.

### Fixing Timing Issues with dispatch_async

Having some timing-issues in UIKit? Most of the time, this will be the perfect “fix:”


    dispatch_async(dispatch_get_main_queue(), ^{
        // Some UIKit call that had timing issues but works fine
        // in the next runloop.
        [self updatePopoverSize];
    });

Don’t do this, trust me. This will haunt you later as your app gets larger. It’s super hard to debug and soon things will fall apart when you need to dispatch more and more because of “timing issues.” Look through your code and find the proper place for the call (e.g. viewWillAppear instead of viewDidLoad). I still have some of those hacks in my codebase, but most of them are properly documented and an issue is filed.

Remember that this isn’t really GCD-specific, but it’s a common anti-pattern and just very easy to do with GCD. You can apply the same wisdom for `performSelector:afterDelay:`, where the delay is 0.f for the next runloop.

### Mixing dispatch_sync and dispatch_async in Performance Critical Code

That one took me a while to figure out. In [PSPDFKit][20] there is a caching class that uses a LRU list to track image access. When you scroll through the pages, this is called _a lot_. The initial implementation used dispatch_sync for availability access, and dispatch_async to update the LRU position. This resulted in a frame rate far from the goal of 60 FPS.

When other code running in your app is blocking GCD’s threads, it might take a while until the dispatch manager finds a thread to perform the dispatch_async code – until then, your sync call will be blocked. Even when, as in this example, the order of execution for the async case isn’t important, there’s no easy way to tell that to GCD. Read/Write locks won’t help you there, since the async process most definitely needs to perform a barrier write and all your readers will be locked during that. Lesson: `dispatch_async` can be expensive if it’s misused. Be careful when using it for locking.

### Using dispatch_async to Dispatch Memory-Intensive Operations

We already talked a lot about NSOperations, and that it’s usually a good idea to use the more high-level API. This is especially true if you deal with blocks of work that do memory-intensive operations.

In an old version of PSPDFKit, I used a GCD queue to dispatch writing cached JPG images to disk. When the retina iPad came out, this started causing trouble. The resolution doubled, and it took much longer to encode the image data than it took to render it. Consequently, operations piled up in the queue and when the system was busy it could crash of memory exhaustion.

There’s no way to see how many operations are queued (unless you manually add code to track this), and there’s also no built-in way to cancel operations in case of a low-memory notification. Switching to NSOperations made the code a lot more debuggable and allowed all this without writing manual management code.

Of course there are some caveats; for example you can’t set a target queue on your `NSOperationQueue` (like `DISPATCH_QUEUE_PRIORITY_BACKGROUND` for throttled I/O). But that’s a small price for debuggability, and it also prevents you from running into problem like [priority inversion][26]. I even recommend against the nice `NSBlockOperation` API and suggest real subclasses of NSOperation, including an implementation of description. It’s more work, but later on, having a way to print all running/pending operations is insanely useful.




* * *

[More articles in issue #2][27]

  * [Privacy policy][28]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-2/index.html
   [5]: https://twitter.com/steipete
   [6]: https://gist.github.com/steipete/5664345
   [7]: http://developer.apple.com/library/ios/#releasenotes/General/WhatsNewIniOS/Articles/iPhoneOS4.html
   [8]: http://developer.apple.com/library/ios/#technotes/tn2109/_index.html
   [9]: https://github.com/AFNetworking/AFNetworking/issues/56
   [10]: https://developer.apple.com/library/ios/#documentation/Cocoa/Conceptual/Multithreading/ThreadSafetySummary/ThreadSafetySummary.html%23//apple_ref/doc/uid/10000057i-CH12-SW1
   [11]: http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/ConcurrentHashMap.html
   [12]: https://gist.github.com/steipete/5928916
   [13]: http://www.opensource.apple.com/source/objc4/
   [14]: https://github.com/opensource-apple/objc4/blob/master/runtime/Accessors.subproj/objc-accessors.mm#L127
   [15]: https://gist.github.com/steipete/5928690
   [16]: https://github.com/opensource-apple/objc4/blob/master/runtime/objc-sync.mm#L291
   [17]: http://googlemac.blogspot.co.at/2006/10/synchronized-swimming.html
   [18]: https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/Multithreading/ThreadSafety/ThreadSafety.html%23//apple_ref/doc/uid/10000057i-CH8-SW3
   [19]: http://www.objc.io/issue-2/concurrency-apis-and-pitfalls.html#shared_resources
   [20]: http://pspdfkit.com
   [21]: http://www.cocoawithlove.com/2008/04/value-of-immutable-values.html
   [22]: http://www.jonmsterling.com/posts/2012-12-27-a-pattern-for-immutability.html
   [23]: https://code.google.com/r/riky-adsfasfasf/source/browse/Utilities/GCDMulticastDelegate.h
   [24]: https://gist.github.com/steipete/3713233
   [25]: http://www.objc.io/issue-2/concurrency-apis-and-pitfalls.html#dead_locks
   [26]: http://www.objc.io/issue-2/concurrency-apis-and-pitfalls.html#priority_inversion
   [27]: http://www.objc.io/issue-2
   [28]: http://www.objc.io/privacy.html
