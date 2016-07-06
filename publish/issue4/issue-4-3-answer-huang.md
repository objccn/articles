凭良心讲，我不能告诉你不去使用 Core Data。它不错，而且也在变得更好，并且它被很多其他 Cocoa 开发者所理解，当有新人加入你的团队或者需要别人接手你的 app 的时候，这点很重要。

更重要的是，不值得花时间和精力去写自己的系统去代替它。使用 Core Data 吧。真的。

## 为什么我不使用Core Data

[Mike Ash 写到](http://www.mikeash.com/pyblog/friday-qa-2013-08-30-model-serialization-with-property-lists.html)：

> 就个人而言，我不是个狂热粉丝。我发现 (Core Data 的) API 是笨拙的，并且框架本身对于超过一定数量级的数据的处理是极其缓慢的。

### 一个实际的例子：10,000 个条目

想象一个 RSS 阅读器，一个用户可以在一个 feed 上点击右键，并且选择标记所有为已读。

实际实现上，我们有一个带有 `read` 属性的 Article 实体。把所有条目标记为已读，app 需要加载这个 feed 的所有文章 (可能通过一对多的关系)，然后设置 read 属性为 YES。

大部分时候这样是没问题的。但是设想那个 feed 有 200 篇文章，为了避免阻塞主线程，你可能考虑在后台线程里做这个工作 (尤其是如果这个 app 是一个 iPhone app)。一旦你开始使用 Core Data 多线程的时候，事情就开始变得不好处理了。

这可能还没这么糟糕，至少不值得抛弃使用 Core Data。

但是，再添加同步。

我用过两个不同的 RSS 同步 API，它们返回已读文章的 uniqueID 数组。其中一个返回近 10,000 个 ID。

你不会打算在主线程中加载 10,000 篇文章，然后设置 `read` 为 NO。你大概也不会想在后台线程里加载 10,000 篇文章，即使很小心地管理内存。这里有太多的工作（如果你频繁的这么做，想一下对电池寿命的影响）。

概念上来说，你真正想要做的是，让数据库将 uniqueID 列表里的每一篇文章的 `read` 设置为 YES。

SQLite 可以做到这个，只用一次调用。如果 `uniqueID` 上有索引，这会很快。而且你可以在后台线程执行，这和在主线程执行一样容易。

### 另一个例子：快速启动

我的另一个 app，我想减少启动时间 — 不只是 app 的启动时间，还有数据显示之前所需要的时间。

这是个类似 Twitter 的 app (虽然它不是)：它显示消息的时间轴。显示时间轴意味着获取消息，并加载相关用户。它很快，但是在启动的时候，会填充 UI，**然后**填充数据。

关于 iPhone app（或者所有应用），我的理论是，启动时间比其他大部分开发者想的都要重要。启动时间很慢的 app 是不太可能被启动的，因为人们潜意识里会记住，并且在启动那个应用这件事情上形成一种抵抗心理。减少启动时间可以减少这种阻力，用户也会更愿意使用你的应用，并且把它推荐给其他人。这是你让你的 app 成功的一部分。

因为我不使用 Core Data，我手头有一个简单的，保守的解决方案。我把时间轴（消息和人物对象）通过 `NSCoding` 保存到一个 plist 文件中。启动的时候它读取这个文件，创建消息和人物对象，UI 一出现就显示时间轴。

这明显的减少了延迟。

把消息和人物对象作为 `NSManagedObject` 的实例对象，这是不可能的。（假设我已经编码并且存储对象的 IDs，但是那意味着读取 plist 文件，**之后**再涉及数据库。这种方式我完全避免了数据库）。

（在更新更快的机器出来后, 我去掉了那些代码。回顾过去，我希望我可以把它留下来。）

### 我怎么考虑这个问题

当考虑是否使用 Core Data，我考虑下面这些事情：

#### 会有难以置信数量的数据吗？

对于一个 RSS 阅读器或者 Twitter app，答案显而易见：是的。有些人关注上百个人。一个人可能订阅了上千个 feed。

即使你的应用不从网络获取数据，用户仍然有可能自动添加数据。如果你用一个支持 AppleScript 的 Mac，有人会写脚本去加载非常多的数据。如果通过 web API 去添加数据也是一样的。

#### 会有一个 Web API 包含类似于数据库的结果吗（对比于类似对象的结果）？

一个 RSS 同步 API 能够返回一个已读文章的 uniqueID 列表。一个笔记的应用的一个同步 API 可能返回已存档的和已删除的笔记的 uniqueID 列表。

#### 用户可能通过操作处理大量对象吗？

在底层，需要考虑和之前一样的问题。当有人删除所有已经下载的 5,000 个面食食谱，你的食谱 app 性能如何？（在 iPhone 上？）

如果我决定使用 Core Data（我已经发布过使用 Core Data 的应用），我会特别注意我如何使用它。结果为了得到好的性能，我发现我把它当做了一个奇怪接口的 SQL 数据库在使用，然后我就知道了，我应该舍弃 Core Data，而去直接使用 SQLite。

## 我如何使用 SQLite

我通过 [FMDB Wrapper](https://github.com/ccgus/fmdb) 来使用 SQLite，FMDB 来自 Flying Meat Software，由 Gus Mueller 开发。

### 基本操作

在使用 iPhone 和 Core Data 之前，我就使用过 SQLite。这里有关于它如何工作的要点：

* 所有数据库访问 - 读和写 - 发生在一个后台线程的连续的队列里。在主线程中触及数据库是**从来**不被允许的。使用一个连续队列来保证每一件事是按顺序发生的。
* 我大量使用 blocks 使得异步编程容易些。
* 模型对象只存在在主线程（但有两个重要的例外），改变会触发一个后台保存。
* 模型对象列出来它们在数据库中存储的属性。这可能在代码里或者在 plist 文件里。
* 有些模型对象是唯一的，有些不是。取决于 app 的需要（大部分情况是唯一的）。
* 对关系型数据，我尽可能避免创建查询表。
* 一些对象类型在启动的时候就完全读入内存，另一些对象类型我可能创建和维护的只有它们 uniqueID 的一个 NSMutableSet，所以我可以在不去碰数据库的情况下就知道什么存在、什么不存在。
* Web API 的调用发生在后台线程，它们使用“分离“的模型对象。

我会使用我[目前的 app](http://vesperapp.co/) 的代码来描述。

### 数据库更新

在我最近的 app 中，有一个单一的数据库控制器 - `VSDatabaseController`，它通过 FMDB 来与 SQLite 对话。

FMDB 区分更新和查询。更新数据库，app 调用：

    -[VSDatabaseController runDatabaseBlockInTransaction:(VSDatabaseUpdateBlock)databaseBlock]

`VSDatabaseUpdateBlock`很简单：

    typedef void (^VSDatabaseUpdateBlock)(FMDatabase *database);

`runDatabaseBlockInTransaction`也很简单：

    - (void)runDatabaseBlockInTransaction:(VSDatabaseUpdateBlock)databaseBlock {
        dispatch_async(self.serialDispatchQueue, ^{
            @autoreleasepool {
                [self beginTransaction];
                databaseBlock(self.database);
                [self endTransaction];
            }
        });
    }

（注意我用的自己的连续 dispatch 队列。Gus 建议看一下 `FMDatabaseQueue`，这也是一个连续调度队列。因为它比 FMDB 剩下的其他东西都要新，所以我自己还没有去看过。）

`beginTransaction` 和 `endTransaction` 的调用是可嵌套的（在我的数据库控制器里）。在合适的时候他们会调用 `-[FMDatabase beginTransaction]` 和 `-[FMDatabase commit]`。（使用 transactions 是让 SQLite 变快的一大关键。）提示：我在 `-[NSThread threadDictionary]` 中存储当前的 transaction 的计数。这对于针对每个线程的数据来说是很方便的，我也几乎从不用它做其他的事情。

这儿有个调用更新数据库的简单例子：

    - (void)emptyTagsLookupTableForNote:(VSNote *)note {
        NSString *uniqueID = note.uniqueID;
        [self runDatabaseBlockInTransaction:^(FMDatabase *database) {
            [database executeUpdate:
                @"delete from tagsNotesLookup where noteUniqueID = ?;", uniqueID];
        }];
    }

这说明了不少事情。首先， SQL 并不可怕。即使你从没见过它，你也知道这行代码做了什么。

像 `VSDatabaseController` 的所有其他公共接口一样，`emptyTagsLookupTableForNote` 也应该在主线程中被调用。模型对象只能在主线程中被引用，所以在 block 中使用 `uniqueID` ，而不是 VSNote 对象。

注意在这种情况下，我更新了一个查询表。Notes 和 tags 有一个多对多关系，一种表现方式是用一个数据库表映射 note uniqueIDs 和 tag uniqueIDs。这些表不会很难维护，但是如果可能，我尽量避免使用它们。

注意在更新字符串中的 `?`。`-[FMDatabase executeUpdate:]` 是一个可变参数函数。SQLite 支持使用占位符 - ? 字符 - 所以你不需要把实际的值放入字符串中去。这是一个安全上的考量：它可以守护程序避免 SQL 注入。它也可以帮助你减少必须 escape 值这样的不必要的麻烦。

最后，注意在 tagsNotesLookup 表中，有一个 noteUniqueID 的索引（索引是 SQLite 性能的又一个关键）。这行代码在每次启动时都调用：


    [self.database executeUpdate:
        @"CREATE INDEX if not exists noteUniqueIDIndex on tagsNotesLookup (noteUniqueID);"];


### 数据库获取

要获取对象，app 调用：

    -[VSDatabaseController runFetchForClass:(Class)databaseObjectClass 
                                 fetchBlock:(VSDatabaseFetchBlock)fetchBlock 
                          fetchResultsBlock:(VSDatabaseFetchResultsBlock)fetchResultsBlock];

这两行代码做了大部分工作：


    FMResultSet *resultSet = fetchBlock(self.database);
    NSArray *fetchedObjects = [self databaseObjectsWithResultSet:resultSet 
                                                           class:databaseObjectClass];


用 FMDB 查找数据库返回一个 `FMResultSet`. 通过 resultSet 你可以逐句循环，创建模型对象。

我建议写通用的代码去将数据库中的行转换为对象。一种我已经使用的方法是在 app 中用一个 plist 文件，将列的名字映射到模型对象的属性上去。它也包含类型，所以你知道是调用 `-[FMResultSet dateForColumn:]`还是 `-[FMResultSet stringForColumn:]`或是其他方法。

在我的最新 app 里我做的事情更简单。数据库行刚好对应模型对象属性的名字。除了那些名字以 “Date” 结尾的属性以外，所有属性都是字符串。简单，但是你可以看到所需要明显清晰的对应关系。

#### 唯一对象

创建模型对象的操作和从数据库获取数据操作在同样的后台线程进行。一但获取到，app 会把它们转到主线程。

通常我会使用**唯一**对象。数据库里的同一行，始终对应着同样的一个对象。

为了做到唯一，我使用 NSMapTable 创建了一个对象缓存，在 init 函数里：`_objectCache = [NSMapTable weakToWeakObjectsMapTable]`。我来解释一下：

例如，当你进行一个数据库获取操作并且把对象转交给一个视图控制器时，你希望在这个视图控制器使用完这些对象后，或者在一个不一样的视图控制器被显示后，这些对象可以消失。

如果你的对象缓存是一个 `NSMutableDictionary`，那你将需要做一些额外的工作来清空缓存中的对象。保证它只引用了那些其他地方有引用的对象是一件非常让人蛋疼的事情。而使用配合弱引用的`NSMapTable`，这个问题就被自动处理掉了。

所以：我们在主线程中让对象唯一。如果一个对象已经在对象缓存中存在，我们就用那个存在的对象。（因为主线程中对象可能有改变，因此在冲突时我们使用主线程的对象。）如果对象缓存中没有，它会被加上。

#### 保持对象在内存中

有很多次，把整个对象类型保留在内存中是有道理的。我最新的 app 有一个 VSTag 对象。虽然可能有成百上千篇笔记，但 tags 的数量很小，基本少于十个。一个 tag 只有 6 个属性：三个 BOOL，两个很小的 NSstring，还有一个 NSDate。

启动的时候，app 获取所有 tags 并且把它们保存在两个字典里，其中一个的键是 tag 的 uniqueID，另一个的键是 tag 名字的小写。

这简化了很多事，比如 tag 自动补全系统，就可以完全在内存中操作，而不需要从数据库获取了。

但是很多次，把所有数据保留在内存中是不实际的。比如我们不会在内存中保留所有笔记。

但是也有很多次，把所有对象保存在内存中是不可行的。当不能在内存中保留一个对象类型时，你可能会希望在内存中保留所有 uniqueID，你可以进行这样一个获取操作：

    FMResultSet *resultSet = [self.database executeQuery:@"select uniqueID from some_table"];

resultSet 只包含了 uniqueIDs， 你可以存储到一个 NSMutableSet 里。

我发现有时这个对 web APIs 很有用。想象一个 API 返回从某个确定的时间以后所创建笔记的 uniqueIDs 列表。如果我本地已经有了一个包含所有笔记 uniqueIDs 的 NSMutableSet，我可以 (通过 `-[NSMutableSet minusSet]`) 快速检查是否有漏掉的笔记，然后去调用另一个 API 下载那些漏掉的笔记。这些完全不需要触及数据库。

但是，像这样的事情应该小心处理。app 可以提供足够的内存吗？它真的简化编程*并且*提高性能了吗？

使用 SQLite 和 FMDB 来代替 Core Data，会给你带来大量的灵活性和使用更聪明的办法来解决问题的空间。记住有的时候聪明是好的，也有的时候聪明是一个大错误。

### Web APIs

我的 API 调用都跑在后台进程里（通常是用一个 `NSOperationQueue`，这样我可以取消操作）。模型对象只在主线程，然后将模型对象传递给我的 API 调用。

具体这么做：一个数据库对象有一个 `detachedCopy` 方法，可以复制数据库对象。这个复制的对象**不会**被我用来做唯一化的对象缓存所引用。唯一引用这个对象的地方是 API 调用，当 API 调用结束时，这个复制的对象也就消失了。

这是一个好的系统，因为它意味着我可以在 API 调用里使用模型对象。方法看起来像这样：

    - (void)uploadNote:(VSNote *)note {
        VSNoteAPICall *apiCall = [[VSNoteAPICall alloc] initWithNote:[note detachedCopy]];
        [self enqueueAPICall:apiCall];
    }

VSNoteAPICall 从分离出来的 `VSNote` 中获取值，并且创建 HTTP 请求，而不是将 note 包装成一个字典或其他表现形式。

#### 处理 Web API 的返回值

我对 web 的返回值做了一些类似的处理。我会对返回的 JSON 或者 XML 创建一个模型对象，这个模型对象也是分离的。它没有存储在唯一化模型缓存里。

这里有些事情是不确定的。有时我们需要用那个模型对象在在内存缓存**以及**数据库两个地方做本地修改。

数据库通常是容易的部分。比如：我的 app 已经有一个方法来保存笔记对象。它使用 SQL 的 `insert or replace` 命令。我只需用从 web API 返回值所生成的笔记对象来进行调用，数据库就会更新。

但是可能同样的对象在内存中还有一个版本，幸运的是我们很容易找到它：

    VSNote *cachedNote = [self.mapTable objectForKey:downloadedNote.uniqueID];

如果 cachedNote 存在，我会让它从 downloadedNote中 获取值（这部分可以共享 `detachedCopy` 方法的代码。），而不是直接替换它（这样可能违反唯一性）。

一旦 cachedNote 更新了，观察者会通过 KVO 察觉到变化，或者我会发送一个 `NSNotification`，或者两者都做。

Web API 调用也会返回一些其他值。我提到过 RSS 阅读器可能获得一个已读条目的大列表。这种情况下，我选择通过那个列表创建一个 `NSSet`，在内存的缓存中更新每一个缓存文章的 `read` 属性，然后调用 `-[FMDatabase executeUpdate:]`。

完成这个工作的关键是 `NSMapTable` 的查找是快速的。如果你找的对象在一个 NSArray 里，我们就得重新考虑考虑了。

## 数据库迁移

[当正常工作的时候](http://openradar.appspot.com/search?query=migration)，Core Data 的数据库迁移功能还是蛮酷的。

但是不可避免的，它在代码和数据库中加入了一层。如果你更直接一点，去使用 SQLite，那么更新数据库也就变得越直接。

你可以安全容易的做到这点。

比如加一个表：


    [self.database executeUpdate:@"CREATE TABLE if not exists tags "
        "(uniqueID TEXT UNIQUE, name TEXT, deleted INTEGER, deletedModificationDate DATE);"];


或添加一个索引


    [self.database executeUpdate:@"CREATE INDEX if not exists "
        "archivedSortDateIndex on notes (archived, sortDate);"];

或添加一列：

    [self.database executeUpdate:@"ALTER TABLE tags ADD deletedDate DATE"];

app 应该用类似上面这样的代码来首先对数据库进行设置。以后的改变就是添加对 executeUpdate 的调用 — 我让他们按顺序执行。因为我的数据库是我设计的，所以这不会有什么问题（我从没碰到性能问题，它很快）。

当然大的改变需要更多代码。如果你的数据通过 web 获取，有时你可以从一个新数据库模型开始，重新下载你需要的数据。

## 性能技巧

SQLite 可以非常非常快，但是也可以非常慢。完全取决于你怎么使用它。

### 事务

把更新包装在事务里。在更新前调用 `-[FMDatabase beginTransaction]`，更新后调用 `-[FMDatabase commit]`。

### 如果你不得不反规范化（ Denormalize）

[反规范化](http://en.wikipedia.org/wiki/Denormalization)让人很不爽。这个方法是，为了加速检索而添加冗余数据，但是它意味着你需要维护冗余数据。

我总是尽力避免它，直到这样能有严重的性能差异。然后我会尽可能少得这么做。

### 使用索引

我的 app 中 tags 表的创建语句像这样：

    CREATE TABLE if not exists tags 
      (uniqueID TEXT UNIQUE, name TEXT, deleted INTEGER, deletedModificationDate DATE);


uniqueID 列是自动索引的，因为它定义为 unique。但是如果我想用 name 来查询表，我可能会在name上创建一个索引，像这样：

    CREATE INDEX if not exists tagNameIndex on tags (name);

你可以一次性在多列上创建索引，像这样：

    CREATE INDEX if not exists archivedSortDateIndex on notes (archived, sortDate);

但是注意太多索引会降低你的插入速度。你只需要足够数量并且是正确的那些。

### 使用命令行应用

当我的 app 在模拟器里运行时，我会用 `NSLog` 输出数据库的路径。我可以通过 sqlite3 的命令行来打开数据库。（通过 man sqlite3 命令来了解这个应用的更多信息）。

打开数据库的命令：`sqlite3 path/to/database`。

打开以后，你可以输入 `.schema` 来查看 schema。

你可以更新和查询，这是在你的 app 使用 SQL 之前就将它们正确地准备妥当的很好的方式。

这里面最酷的一部分是，[SQLite Explain Query Plan 命令](http://www.sqlite.org/eqp.html)，你会希望确保你的语句执行的尽可能快。

### 真实的例子

我的 app 显示所有没有归档笔记的标签列表。每当笔记或者标签有变化，这个查询就会重新执行一次，所以它需要很快。

我可以用 [SQL join](http://en.wikipedia.org/wiki/Join_%28SQL%29) 来查询，但是这会很慢（join 都很慢）。

所以我放弃 sqlite3 并开始尝试别的方法。我又检查了一次我的 schema，意识到我可以反规范化。一个笔记的归档状态可以存储在 notes 表里，它也可以存储在 tagsNotesLookup 表。

然后我可以执行一个查询：

    select distinct tagUniqueID from tagsNotesLookup where archived=0;

我已经有了一个在 tagUniqueID 上的索引。所以我用 explain query plan 来告诉我当我执行这个查询的时候会发生什么。

    sqlite> explain query plan select distinct tagUniqueID from tagsNotesLookup where archived=0;
    0|0|0|SCAN TABLE tagsNotesLookup USING INDEX tagUniqueIDIndex (~100000 rows)

它用了一个索引，这很不错，但是 SCAN TABLE 听起来不太好，最好是一个 SEARCH TABLE 加上[覆盖索引](http://www.sqlite.org/queryplanner.html#covidx)的方式。

我在 tagUniqueID 和 archive 上建了索引：

    CREATE INDEX archivedTagUniqueID on tagsNotesLookup(archived, tagUniqueID);

再次执行 explain query plan:

    sqlite> explain query plan select distinct tagUniqueID from tagsNotesLookup where archived=0;
    0|0|0|SEARCH TABLE tagsNotesLookup USING COVERING INDEX archivedTagUniqueID (archived=?) (~10 rows)

现在好多了。

### 更多性能提示

FMDB 的某处加了缓存 statements 的能力，所以当创建或打开一个数据库的时候，我总是调用 `[self.database setShouldCacheStatements:YES]`。这意味着对每个调用你不需要再次编译每个 statement。

我从来没有找到关于使用 `vacuum` 的好的指引。如果数据库没有定期压缩，它会变得越来越慢。我的 app 会每周跑一次 vacuum。（在 NSUserDefaults 里存储上次 vacuum 的时间，然后在开始的时候检查是否过了一周）。

使用 `auto_vacuum` 可能会更好，可以参看 [pragma statements supported by SQLite](http://www.sqlite.org/pragma.html#pragma_auto_vacuum) 列表。

## 其他酷的东西

Gus Mueller 让我讲讲自定义 SQLite 方法的内容。我并没有真的使用过这些东西，不过既然他指出了，我可以放心的说我能找到它的用处。因为它很酷。

[在　Gus　的这个 gist 里](https://gist.github.com/ccgus/6324222)，有一个查询是这样的：

    select displayName, key from items where UTTypeConformsTo(uti, ?) order by 2;

SQLite 完全不知道 UTTypes 的事情。但是你可以通过代码块来添加核心方法，感兴趣的话，可以看看 `-[FMDatabase makeFunctionNamed:maximumArguments:withBlock:]` 方法。

你可以执行一个大的查询来替代，然后评估每个对象 - 但是那需要更多工作。最好在 SQL 级就过滤，而不是在将表格行转为对象以后再做这件事情。

## 最后

你真的应该使用 Core Data，我不是在开玩笑。

我用 SQLite 和 FMDB 一段时间了，我对多得到的好处感到很兴奋，也得到非同一般的性能。

但是记住设备在不断变快。也请记住，其他看你代码的人期望看到 Core Data，这是他们已经了解的 - 他们不打算看你的数据库代码如何工作。

所以请把这整篇文章看做一个疯子的叫喊，关于他为自己建立了充满细节又疯狂的世界 - 并把自己锁在了里面。

有点难过的摇头，并且请享受这个话题下那些超赞的 Core Data 的文章吧。

而对我来说，接下来在研究完 Gus 指出的自定义 SQLite 方法特性后，我会研究 SQLite 的 [全文搜索扩展](http://www.sqlite.org/fts3.html)。 总有更多的内容需要不断去学习。

---

 

原文 [On Using SQLite and FMDB Instead of Core Data](http://www.objc.io/issue-4/SQLite-instead-of-core-data.html)

译文 [谈谈用SQLite和FMDB而不用Core Data](http://blog.jobbole.com/52880/)

精细校对 [sjpsega](https://github.com/sjpsega)

