[Source](http://www.objc.io/issue-2/low-level-concurrency-apis.html "Permalink to Low-Level Concurrency APIs - Concurrent Programming - objc.io issue #2 ")

# Low-Level Concurrency APIs - Concurrent Programming - objc.io issue #2 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# Low-Level Concurrency APIs

[Issue #2 Concurrent Programming][4], July 2013

By [Daniel Eggert][5]

In this article we’ll talk about some low-level APIs available on both iOS and OS X. Except for `dispatch_once`, we generally discourage using any of this.

But we wanted to show what’s available under the covers. These low-level APIs provide a huge amount of flexibility, yet with that flexibility comes a lot of complexity and responsibility. The higher-level APIs and patterns that we mention in our [article about common background practices][6] let you focus on your task at hand and save you a lot of trouble. And generally, the higher-level APIs will provide better performance unless you can afford the time and effort to tweak and debug code that uses lower-level APIs.

Knowing how things work further down the software stack is good, though. We hope this article will give you a better understanding of the platform, and at the same time, will make you appreciate the higher-level APIs more.

First, we’ll go through most of the bits and pieces that make up _Grand Central Dispatch_. It’s been around for some years and Apple keeps adding to it and improving it. Apple has open sourced it, which means it’s available for other platforms, too. Finally, we’ll take a look at [atomic operations][7] – another set of low-level building blocks.

Probably the best book ever written about concurrent programming is _M. Ben-Ari_: “Principles of Concurrent Programming”, [ISBN 0-13-701078-8][8]. If you’re doing anything with concurrent programming, you need to read this. It’s more than 30 years old, and is still unsurpassed. Its concise writing, excellent examples, and exercises take you through the fundamental building blocks of concurrent programming. It’s out of print, but there are still some copies floating around. There’s a new version called “Principles of Concurrent and Distributed Programming”, [ISBN 0-321-31283-X][9] that seems to cover much of the same, but I haven’t read it myself.

## Once Upon a Time…

Probably the most widely used and misused feature in GCD is `dispatch_once`. Correctly used, it will look like this:


    %2B (UIColor *)boringColor;
    {
        static UIColor *color;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            color = [UIColor colorWithRed:0.380f green:0.376f blue:0.376f alpha:1.000f];
        });
        return color;
    }

The block will only get run once. And during successive calls, the check is very performant. You can use this to initialize global data such as singletons. Beware that using `dispatch_once_t` makes testing very difficult – singletons and testing don’t go well together.

Make sure that the `onceToken` is declared `static` or has global scope. Anything else causes undefined behavior. In other words: Do **not** put a `dispatch_once_t` as a member variable into an object or the like.

Back in ancient times (i.e. a few years ago), people would use `pthread_once`, which you should never use again, as `dispatch_once` is easier to use and less error-prone.

## Delaying / After

Another common companion is `dispatch_after`. It lets you do work _a little bit later_. It’s powerful, but beware: You can easily get into a lot of trouble. Common usage looks like this:


    - (void)foo
    {
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self bar];
        });
    }

This looks awesome at first sight. There are a few drawbacks, though. We can’t (directly) cancel the block we’re submitting to `dispatch_after`. It will run.

Another thing to note is there’s a problematic tendency where people use `dispatch_after` to work around timing bugs they have in their code. Some code gets run too early and you may not know why, so you put it inside a `dispatch_after`. Now everything works. But some weeks later it stops working and since you have no clear indication of in which order your code runs, debugging turns into a nightmare. Don’t do this. Most of the time, you’re better of putting your code into the right place. If inside `-viewWillAppear` is too early, perhaps `-viewDidAppear` is the right place.

You’ll save yourself a lot of trouble by creating direct calls (analogous to `-viewDidAppear`) in your own code instead of relying on `dispatch_after`.

If you need something to run at a specific point in time, `dispatch_after` may be the right thing, though. Be sure to check out `NSTimer`, too. That API is a tiny bit more cumbersome, but it allows you to cancel the firing of the timer.

## Queues

One of the basic building blocks of GCD is queues. Below, we’ll give a few examples on how you can put them to use. When using queues, you’ll do yourself a favor when giving them a good label. While debugging, this label is displayed within Xcode (and lldb), and will help you understand what your app is up to:


    - (id)init;
    {
        self = [super init];
        if (self != nil) {
            NSString *label = [NSString stringWithFormat:@"%@.isolation.%p", [self class], self];
            self.isolationQueue = dispatch_queue_create([label UTF8String], 0);

            label = [NSString stringWithFormat:@"%@.work.%p", [self class], self];
            self.workQueue = dispatch_queue_create([label UTF8String], 0);
        }
        return self;
    }

Queues can be either _concurrent_ or _serial_. By default, they’re serial, which means that only a single block runs at any given time. That’s how isolation queues work, which we’ll get to in a bit. Queues can also be concurrent, which allows multiple blocks to run at the same time.

GCD queues use threads internally. GCD manages these threads, and thus when using GCD you don’t need to create threads yourself. But the important takeaway is that GCD presents to you, the user of the API, a very different abstraction level. When you use GCD to do concurrent work, you don’t think in terms of threads, but instead in terms of queues and work items (blocks submitted to queues). While down below, there’re still threads, GCD’s abstraction level lends itself way better to how you’re usually writing code.

The queues and work items also solve a common problem of consecutive fanning out: If we’re using threads directly, and want to do something concurrently, we may split our work up into 100 smaller work items, and then create threads according to the number of available CPU cores, let’s say eight. We send the work items to those eight threads. As we process those items, we might call some function as part of our work. The person who wrote that function also wanted to use concurrency, and hence also creates eight threads when you call the function. Now you have 8 x 8 = 64 threads, even though you only have eight cores – i.e. only 12% of the threads can actually run at any point in time while the other 88% are not doing anything. With GCD you don’t have this problem, and GCD can even adjust the number of threads when the system turns off cores to save power.

GCD creates a so-called [thread pool][10] that roughly matches the number of cores. Remember that threads don’t come for free. Each thread ties up memory and kernel resources. There’s one problem though: If you’re submitting a block to GCD, and that code blocks the thread, this thread is no longer available at that point in time to do other work – it’s blocked. In order to keep processing work items (blocks) on the queues, GCD has to create a new thread and add it to the pool.

If your code is blocking many threads, that can become quite problematic. First off, threads consume resources, but moreover, it’s expensive to create them. And it takes some time. And during that time, GCD can’t process work items at full speed. There are quite a few things that can cause a thread to block, but the most common are I/O related, i.e. reading and writing from / to a file or the network. You should not do that on a GCD queue in a blocking manner for this very reason. Take a look at the [Input / Output section][11] below for information about how to do I/O in a way that plays nicely with GCD.

### Target Queue

You can set a **target queue** for any queue that you create. This can be very powerful. And it helps debugging.

It is generally considered good style for a class to create its own queue instead of using a global queue. This way you can set the name of that queue, which eases debugging a lot – Xcode lets you see the names of all queues in the Debug Navigator, or if you’re using `lldb` directly, `(lldb) thread list` will print out the queue names. Once you’re using a lot of async stuff, this is very valuable help.

Using a private queue also enforces encapsulation. It’s your queue; you get to decide how to use it.

By default, a newly created queue forwards into the default priority global queue. We’ll talk more about priorities in a bit.

You can change which queue your queue forwards into – you can set your queue’s target queue. This way you can chain multiple queues together. Your class `Foo` has a queue which forwards into the queue of class `Bar` which forwards into a global queue.

This can be very useful when you use a queue for isolation (which we’ll also talk about). `Foo` has an isolation queue, and by forwarding into `Bar`’s isolation queue, it will automatically be thread-safe with respect to the resources that `Bar`’s isolation queue protects.

Make sure to make your private queue concurrent if you want multiple blocks to run on it. And note that if a queue’s target queue is serial (i.e. non-concurrent), it effectively turns into a serial queue as well.

### Priorities

You change the priority of your own queue by setting its target queue to be one of the global queues. But you should refrain from the temptation to do so.

In most cases, changing the priority is not going to do what you intend. What may seem straightforward is actually a very complex problem. You’ll very easily run into what is known as [Priority Inversion][12]. Our [article about concurrency APIs and pitfalls][13] has more info on this problem which almost bricked NASA’s Pathfinder rover on Mars.

Furthermore, you need to be particularly careful with the `DISPATCH_QUEUE_PRIORITY_BACKGROUND` queue. Don’t use it unless you understand what _throttled I/O_ and _background status as per setpriority(2)_ mean. Otherwise the system might end up putting your app to a grinding halt. It is mostly intended for doing I/O in a way such that it doesn’t interfere with other parts of the system doing I/O. But combined with priority inversion, it can easily become a dangerous cocktail.

## Isolation

Isolation queues are one of the most common patterns in GCD queue usage. There are two variations.

### Protecting a Resource

The most common scenario in multi-threaded programming is that you have a resource that only one thread is allowed to access at a time.

Our [article about concurrency techniques][14] talks a bit more about what _resource_ means in concurrent programming. It’s often a piece of memory or an object that only one thread must access at a time.

Let’s say we need to access a `NSMutableDictionary` from multiple threads (queues). We would do something like this:


    - (void)setCount:(NSUInteger)count forKey:(NSString *)key
    {
        key = [key copy];
        dispatch_async(self.isolationQueue, ^(){
            if (count == 0) {
                [self.counts removeObjectForKey:key];
            } else {
                self.counts[key] = @(count);
            }
        });
    }

    - (NSUInteger)countForKey:(NSString *)key;
    {
        __block NSUInteger count;
        dispatch_sync(self.isolationQueue, ^(){
            NSNumber *n = self.counts[key];
            count = [n unsignedIntegerValue];
        });
        return count;
    }

With this, only one thread will access the `NSMutableDictionary` instance.

Note four things:

  1. Don’t use this code. First read about [multiple readers, single writer][15] and also about [contention][16].

  2. We’re using `async` when storing a value. This is important. We don’t want to and don’t need to block the current thread for the _write_ to complete. When reading, we’re using `sync` since we need to return the result.

  3. According to the method interface, `-setCount:forKey:` takes an `NSString`, which we’re passing onto `dispatch_async`. The caller is free to pass in an `NSMutableString` and can modify it after the method returns, but before the block executes. Hence we _have_ to copy the string to guarantee that the method works correctly. If the passed-in string isn’t mutable (i.e. a normal `NSString`) the call to `-copy` is basically a no-op.

  4. The `isolationQueue` needs to have been created with a `dispatch_queue_attr_t` of `DISPATCH_QUEUE_SERIAL` (or `0`).

### One Resource, Multiple Readers, and a Single Writer

We can improve upon the above example. GCD has concurrent queues on which multiple threads can run. We can safely read from the `NSMutableDictionary` on multiple threads as long as we don’t mutate it at the same time. When we need to change the dictionary, we dispatch the block with a _barrier_. Such a block runs once all previously scheduled blocks have completed and before any following blocks are run.

We’ll create the queue with:


    self.isolationQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_CONCURRENT);

and then change the setter like this:


    - (void)setCount:(NSUInteger)count forKey:(NSString *)key
    {
        key = [key copy];
        dispatch_barrier_async(self.isolationQueue, ^(){
            if (count == 0) {
                [self.counts removeObjectForKey:key];
            } else {
                self.counts[key] = @(count);
            }
        });
    }

When you use concurrent queues, make sure that all _barrier_ calls are _async_. If you’re using `dispatch_barrier_sync` you’ll quite likely get yourself (or rather: your code) into a deadlock. Writes _need_ a barrier, and _can_ be async.

### A Word on Contention

First off, a word of warning here: The resource we’re protecting in this simple example is an `NSMutableDictionary`. This serves the purpose of an example very well. But in real code, it is important to put the isolation at the right complexity level.

If you’re accessing the `NSMutableDictionary` very frequently, you’ll be running into what’s known as lock contention. Lock contention is in no way specific to GCD or queues. Any form of locking mechanism will have the same problem – different locking mechanisms in different ways.

All calls to `dispatch_async`, `dispatch_sync`, etc. need to perform some form of locking – making sure that only one thread or specific threads run a given block. GCD can avoid locks to some extent and use scheduling instead, but at the end of the day the problem just shifts. The underlying problem remains: if you have a **lot** of threads hitting the same lock or queue at the same time, you’ll see performance hits. Performance can degrade severely.

You need to isolate at the right complexity level. When you see performance degrade, it’s a clear sign of a design problem in your code. There are two costs that you need to balance. First is the cost of being inside a critical section for so long that other threads are blocked from entering a critical section, and second is the cost of constantly entering and leaving critical sections. In the world of GCD, the first cost is describing the fact that if a block runs on your isolation queue, it may potentially block other code from running on your isolation queue. The second cost describes the fact that calling `dispatch_async` and `dispatch_sync`, while highly optimized, don’t come for free.

Sadly, there can be no general rule of what the right balance is: You need to measure and adjust. Spin up Instruments and see what your app is up to.

If we look at the example code above, our critical code section is only doing very simple things. That may or may not be good, depending on how it’s used.

In your own code, consider if you’re better off by protecting with an isolation queue on a higher level. For example, instead of the class `Foo` having an isolation queue and it itself protecting access to its `NSMutableDictionary`, you could have the class `Bar` that uses `Foo` have an isolation queue which protects all use of the class `Foo`. In other words: you would change `Foo` so that it is no longer thread-safe, (no isolation queue) and then inside `Bar`, use an isolation queue to make sure that only one thread is using `Foo` at any point in time.

### Going Fully Asynchronous

Let’s sidetrack a bit here. As you’ve seen above, you can dispatch a block, a work unit, both synchronously and asynchronously. A very common problem that we talk about in our [article about concurrency APIs and pitfalls][17] is [dead locks][18]. It’s quite easy to run into the problem with GCD with synchronous dispatching. The trivial case is:


    dispatch_queue_t queueA; // assume we have this
    dispatch_sync(queueA, ^(){
        dispatch_sync(queueA, ^(){
            foo();
        });
    });

Once we hit the second `dispatch_sync` we’ll deadlock: We can’t dispatch onto queueA, because someone (the current thread) is already on that queue and is never going to leave it. But there are more subtle ways:


    dispatch_queue_t queueA; // assume we have this
    dispatch_queue_t queueB; // assume we have this

    dispatch_sync(queueA, ^(){
        foo();
    });

    void foo(void)
    {
        dispatch_sync(queueB, ^(){
            bar();
        });
    }

    void bar(void)
    {
        dispatch_sync(queueA, ^(){
            baz();
        });
    }

Each call to `dispatch_sync()` on its own looks good, but in combination, they’ll deadlock.

This is all inherent to being synchronous. If we use asynchronous dispatching such as


    dispatch_queue_t queueA; // assume we have this
    dispatch_async(queueA, ^(){
        dispatch_async(queueA, ^(){
            foo();
        });
    });

things will work just fine. _Asynchronous calls will not deadlock_. It is therefore very desirable to use asynchronous calls whenever possible. Instead of writing a function or method that returns a value (and hence has to be synchronous), we use a method that calls a result block asynchronously. That way we’re less likely to run into problems with deadlocks.

The downside of asynchronous calls is that they’re difficult to debug. When we stop the code in the debugger, there’s no meaningful backtrace to look at.

Keep both of these in mind. Deadlocks are generally the tougher problem to deal with.

### How to Write a Good Async API

If you’re designing an API for others to use (or even for yourself), there are a few good practices to keep in mind.

As we just mentioned, you should prefer asynchronous API. When you create an API, you can get called in ways that are outside your control, and if your code could deadlock, it will.

You should write your functions or methods so that the function calls `dispatch_async()`. Don’t make the caller call it. The caller should be able to call into your function or method.

If your function or method has a result, deliver it asynchronously through a callback handler. The API should be such that your function or method takes both a result block and a queue to deliver the result on. The caller of your function should not have to dispatch onto the queue themself. The reason for this is quite simple: Almost all the time, the caller needs to be on a certain queue, and this way the code is easier to read. And your function will (should) call `dispatch_async()` anyhow to run the callback handler, so it might as well do that on the queue that the caller needs it to be on.

If you’re writing a class, it is probably a good option to let the user of the class set a queue that all callbacks will be delivered on. Your code would look like this:


    - (void)processImage:(UIImage *)image completionHandler:(void(^)(BOOL success))handler;
    {
        dispatch_async(self.isolationQueue, ^(void){
            // do actual processing here
            dispatch_async(self.resultQueue, ^(void){
                handler(YES);
            });
        });
    }

If you write your classes this way, it’s easy to make classes work together. If class A uses class B, it will set the callback queue of B to be its own isolation queue.

## Iterative Execution

If you’re doing some number crunching and the problem at hand can be dissected in smaller parts of identical nature, `dispatch_apply` can be very useful.

If you have some code like this


    for (size_t y = 0; y < height; %2B%2By) {
        for (size_t x = 0; x < width; %2B%2Bx) {
            // Do something with x and y here
        }
    }

you may be able to speed it up by simply changing it to


    dispatch_apply(height, dispatch_get_global_queue(0, 0), ^(size_t y) {
        for (size_t x = 0; x < width; x %2B= 2) {
            // Do something with x and y here
        }
    });

How well this works depends a lot on exactly what you’re doing inside that loop.

The work done by the block must be non trivial, otherwise the overhead is too big. Unless the code is bound by computational bandwidth, it is critical that the memory that each work unit needs to read from and write to fits nicely into the cache size. This can have dramatic effects on performance. Code bound by critical sections may not perform well at all. Going into detail about these problems is outside the scope of this article. Using `dispatch_apply` may help performance, yet performance optimization is a complex topic on its own. Wikipedia has an article about [Memory-bound function][19]. Memory access speed changes dramatically between L2, L3, and main memory. Seeing a performance drop of 10x is not uncommon when your data access pattern doesn’t fit within the cache size.

## Groups

Quite often, you’ll find yourself chaining asynchronous blocks together to perform a given task. Some of these may even run in parallel. Now, if you want to run some code once this task is complete, i.e. all blocks have completed, “groups” are the right tool. Here’s a sample:


    dispatch_group_t group = dispatch_group_create();

    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_group_async(group, queue, ^(){
        // Do something that takes a while
        [self doSomeFoo];
        dispatch_group_async(group, dispatch_get_main_queue(), ^(){
            self.foo = 42;
        });
    });
    dispatch_group_async(group, queue, ^(){
        // Do something else that takes a while
        [self doSomeBar];
        dispatch_group_async(group, dispatch_get_main_queue(), ^(){
            self.bar = 1;
        });
    });

    // This block will run once everything above is done:
    dispatch_group_notify(group, dispatch_get_main_queue(), ^(){
        NSLog(@"foo: %d", self.foo);
        NSLog(@"bar: %d", self.bar);
    });

The important thing to note is that all of this is entirely non-blocking. At no point are we telling the current thread to wait until something else is done. Quite contrary, we’re simply enqueuing multiple blocks. Since this code pattern doesn’t block, it’s not going to cause a deadlock.

Also note how we’re switching between different queues in this small and simple example.

### Using dispatch_group_t with Existing API

Once you’ve added groups to your tool belt, you’ll be wondering why most async API doesn’t take a `dispatch_group_t` as an optional argument. But there’s no reason to despair: It’s easy to add that yourself, although you have to be more careful to make sure your code is _balanced_.

We can, for example, add it to Core Data’s `-performBlock:` API like this:


    - (void)withGroup:(dispatch_group_t)group performBlock:(dispatch_block_t)block
    {
        if (group == NULL) {
            [self performBlock:block];
        } else {
            dispatch_group_enter(group);
            [self performBlock:^(){
                block();
                dispatch_group_leave(group);
            }];
        }
    }

This allows us to use `dispatch_group_notify` to run a block when a set of operations on Core Data (possibly combined with other blocks) completes.

We can obviously do the same for `NSURLConnection`:


    %2B (void)withGroup:(dispatch_group_t)group
            sendAsynchronousRequest:(NSURLRequest *)request
            queue:(NSOperationQueue *)queue
            completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
    {
        if (group == NULL) {
            [self sendAsynchronousRequest:request
                                    queue:queue
                        completionHandler:handler];
        } else {
            dispatch_group_enter(group);
            [self sendAsynchronousRequest:request
                                    queue:queue
                        completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                handler(response, data, error);
                dispatch_group_leave(group);
            }];
        }
    }

In order for this to work, you need to make sure that

  * `dispatch_group_enter()` is guaranteed to run before `dispatch_group_leave()`
  * Calls to `dispatch_group_enter()` and `dispatch_group_leave()` are always balanced (even when errors happen)

## Sources

One of the lesser-known features of GCD is the event sources `dispatch_source_t`.

Just like most of GCD, this is pretty low-level stuff. When you need it, it can be extremely useful, though. Some of it is extremely esoteric, and we’ll just touch upon a few of the uses. A lot of this isn’t very useful on iOS where you can’t launch processes (hence no point in watching them) and you can’t write outside your app bundle (hence no need to watch files), etc.

GCD sources are implemented in an extremely resource-efficient way.

### Watching Processes

If some process is running and you want to know when it exits, GCD has you covered. You can also use it to check when that process forks, i.e. spawns child processes or a signal was delivered to the process (e.g. `SIGTERM`).


    NSRunningApplication *mail = [NSRunningApplication
      runningApplicationsWithBundleIdentifier:@"com.apple.mail"];
    if (mail == nil) {
        return;
    }
    pid_t const pid = mail.processIdentifier;
    self.source = dispatch_source_create(DISPATCH_SOURCE_TYPE_PROC, pid,
      DISPATCH_PROC_EXIT, DISPATCH_TARGET_QUEUE_DEFAULT);
    dispatch_source_set_event_handler(self.source, ^(){
        NSLog(@"Mail quit.");
    });
    dispatch_resume(self.source);

This will print **Mail quit.** when the Mail.app exits.

Note that you must call `dispatch_resume()` before any events will be delivered to your event handler.

### Watching Files

The possibilities seem near endless. You can watch a file directly for changes, and the source’s event handler will get called when a change happens.

You can also use this to watch a directory, i.e. create a _watch folder_:


    NSURL *directoryURL; // assume this is set to a directory
    int const fd = open([[directoryURL path] fileSystemRepresentation], O_EVTONLY);
    if (fd < 0) {
        char buffer[80];
        strerror_r(errno, buffer, sizeof(buffer));
        NSLog(@"Unable to open \"%@\": %s (%d)", [directoryURL path], buffer, errno);
        return;
    }
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd,
      DISPATCH_VNODE_WRITE | DISPATCH_VNODE_DELETE, DISPATCH_TARGET_QUEUE_DEFAULT);
    dispatch_source_set_event_handler(source, ^(){
        unsigned long const data = dispatch_source_get_data(source);
        if (data & DISPATCH_VNODE_WRITE) {
            NSLog(@"The directory changed.");
        }
        if (data & DISPATCH_VNODE_DELETE) {
            NSLog(@"The directory has been deleted.");
        }
    });
    dispatch_source_set_cancel_handler(source, ^(){
        close(fd);
    });
    self.source = source;
    dispatch_resume(self.source);

You should probably always add `DISPATCH_VNODE_DELETE` to check if the file or directory has been deleted – and then stop monitoring it.

### Timers

In most cases, `NSTimer` is your go-to place for timer events. GCD’s version is lower-level. It gives you more control – use that carefully.

It is extremely important to point out that specifying a low _leeway_ value for GCD timers interferes with the OS’s attempt to conserve power. You’ll be burning more battery if you unnecessarily specify a low leeway value.

Here we’re setting up a timer to fire every 5 seconds and allow for a leeway of 1/10 of a second:


    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
      0, 0, DISPATCH_TARGET_QUEUE_DEFAULT);
    dispatch_source_set_event_handler(source, ^(){
        NSLog(@"Time flies.");
    });
    dispatch_time_t start
    dispatch_source_set_timer(source, DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC,
      100ull * NSEC_PER_MSEC);
    self.source = source;
    dispatch_resume(self.source);

### Canceling

All sources allow you to add a _cancel handler_. This can be useful to clean up any resources you’ve created for the event source, such as closing file descriptors. GCD guarantees that all calls to the event handler have completed before the cancel handler gets called.

See the use of `dispatch_source_set_cancel_handler()` in the above [example for a watch folder][20].

## Input / Output

Writing code that performs well while doing heavy I/O is extremely tricky. GCD has a few tricks up its sleeve to help. Without going into too much detail, we’ll shortly touch upon what these problems are, and how GCD approaches them.

Traditionally when you were reading data from a network socket, you’d be either do a blocking read, i.e. parking a thread until data became available, or you’d have to repeatedly poll. Both approaches are wasteful and don’t scale. However, `kqueue` solved the polling by posting an event once data became available, and GCD uses the same approach, although more elegantly. When writing data to a socket, the identical problems exist, where you have to either perform a blocking write, or wait for the socket to be able to accept data.

The second problem when performing I/O is that data arrives in small chunks; when reading from a network, the chunk size is typically around 1.5k bytes due to the MTU – [maximum transmission unit][21]. This can be anything, though. Once this data arrives, you’re often interested in data that spans multiple chunks, and traditionally you would concatenate the data into one larger buffer and then process that. Let’s say (contrived example), you receive these eight chunks


    0: HTTP/1.1 200 OK
    Date: Mon, 23 May 2005 22:38
    1: :34 GMT
    Server: Apache/1.3.3.7 (Unix) (Red-H
    2: at/Linux)
    Last-Modified: Wed, 08 Jan 2003 23
    3: :11:55 GMT
    Etag: "3f80f-1b6-3e1cb03b"
    Con
    4: tent-Type: text/html; charset=UTF-8
    Content-
    5: Length: 131
    Connection: close

    
    6:
    
      An Example Page

    7: 
    
      Hello World, this is a ve

If you were looking for an HTTP header, it’d be much simpler to concatenate all data chunks into a larger buffer and then scan for ` `. But in doing so, you’d be copying around data a lot. The other problem with a lot of the _old_ C APIs is that there’s no ownership of buffers so that functions had to copy data into their own buffers – another copy. Copying data may seem trivial, but when you’re doing a lot of I/O you’ll see those copies show up in your profiling tool (Instruments). Even if you only copy each memory region once, you’re incurring twice the memory bandwidth and you’re burning through twice the amount of memory cache.

### GCD and Buffers

The more straightforward piece is about data buffers. GCD has a `dispatch_data_t` type that to some extent is similar to what `NSData` does for Objective-C. It can do other things, though, and is more generic.

Note that `dispatch_data_t` can be retained and released, and the `dispatch_data_t` object _owns_ the buffer it holds onto.

This may seem trivial, but we have to remember that GCD is a plain C API, and can’t use Objective-C. The traditional way was to have a buffer either backed by the stack or a `malloc`‘d memory region – these don’t have ownership.

One relatively unique property of `dispatch_data_t` is that it can be backed by disjoint memory regions. That solves the concatenation problem we just mentioned. When you concatenate two data objects with


    dispatch_data_t a; // Assume this hold some valid data
    dispatch_data_t b; // Assume this hold some valid data
    dispatch_data_t c = dispatch_data_create_concat(a, b);

the data object `c` will _not_ copy `a` and `b` into a single, larger memory region. Instead it will simply retain both `a` and `b`. You can then traverse the memory regions represented by `c` with `dispatch_data_apply`:


    dispatch_data_apply(c, ^(dispatch_data_t region, size_t offset, const void *buffer, size_t size) {
        fprintf(stderr, "region with offset %zu, size %zu
    ", offset, size);
        return true;
    });

Similarly you can create a subrange with `dispatch_data_create_subrange` that won’t do any copying.

### Reading and Writing

At its core, _Dispatch I/O_ is about so-called _channels_. A dispatch I/O channel provides a different way to read and write from a file descriptor. The most basic way to create such a channel is by calling


    dispatch_io_t dispatch_io_create(dispatch_io_type_t type, dispatch_fd_t fd,
      dispatch_queue_t queue, void (^cleanup_handler)(int error));

This returns the created channel which then _owns_ the file descriptor. You must not modify the file descriptor in any way after you’ve created a channel from it.

There are two fundamentally different _types_ of channels: streams and random access. If you open a file on disk, you can use it to create a random access channel (because such a file descriptor is `seek`able). If you open a socket, you can create a stream channel.

If you want to create a channel for a file, you’re better off using `dispatch_io_create_with_path`, which takes a path, and lets GCD open the file. This is beneficial, since GCD can postpone opening the file – hence limiting the number of files that are open at the same time.

Analogous to the normal `read(2)`, `write(2)`, and `close(2)`, GCD offers `dispatch_io_read`, `dispatch_io_write`, and `dispatch_io_close`. Reading and writing is done via a callback block that is called whenever data is read or written. This effectively implements non-blocking, fully async I/O.

We can’t go into all details here, but here’s an example for setting up a TCP server:

First we create a listening socket and set up an event source for incoming connections:


    _isolation = dispatch_queue_create([[self description] UTF8String], 0);
    _nativeSocket = socket(PF_INET6, SOCK_STREAM, IPPROTO_TCP);
    struct sockaddr_in sin = {};
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET6;
    sin.sin_port = htons(port);
    sin.sin_addr.s_addr= INADDR_ANY;
    int err = bind(result.nativeSocket, (struct sockaddr *) &sin, sizeof(sin));
    NSCAssert(0 