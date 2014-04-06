凭良心讲，我不能告诉你不去使用 Core Data。它不错，而且也在变得更好，并且它被很多其他 Cocoa 开发者所理解，当有新人加入你的团队或者需要别人接手你的 app 的时候，这点很重要。

更重要的是，不值得花时间和精力去写自己的系统去代替它。使用 Core Data 吧。真的。

## 为什么我不使用Core Data

[Mike Ash写到](http://www.mikeash.com/pyblog/friday-qa-2013-08-30-model-serialization-with-property-lists.html)：
> 就个人而言，我不是个狂热粉丝。我发现API是笨拙的，并且框架本身对于超过一定数量级数据的处理是极其缓慢的。

### 一个实际的例子：10,000条目

想象一个 RSS 阅读器，一个用户可以在一个 feed 上点击右键，并且选择标记所有为已读。

在引擎下，有一个带有 `read` 属性的 Article 实体。把所有条目标记为已读，app 需要加载这个 feed 的所有文章(可能通过一对多的关系)，然后设置 read 属性为 YES。

大部分时候这样是没问题的。但是设想那个 feed 有200篇文章，为了避免阻塞主线程，你可能考虑在后台线程里做这个工作(尤其是如果这个 app 是一个 iPhone app)。一旦你开始使用 Core Data 多线程的时候，事情就开始变的不好处理了。

这可能还没这么糟糕，至少不值得切换走 Core Data。

但是，再添加同步。

我用过两种不同的获取已读文章 uniqueID 列表的 RSS 同步接口。其中一个返回近10,000个 ID。

你不会打算在主线程中加载10,000篇文章，然后设置 read 为 NO。你甚至不想在后台线程里加载10,000篇文章，即使很小心的管理内存。这有太多的工作（如果你频繁的这么做，想一下对电池寿命的影响）。

你真正想要做的是，让数据库给在 uniqueID 列表里的每一篇文章设置 read 为 YES。

SQLite 可以做到这个，只用一次调用。假设 uniqueID 上有索引，这会很快。而且你可以在后台线程执行像在主线程执行一样容易。

### 另一个例子：快速启动

我的另一个 app，我想减少启动时间 — 不只是 app 的启动时间，还有数据显示之前的时间量。

这是个类似 Twitter 的 app(虽然它不是)：它显示消息的时间轴。显示时间轴意味着获取消息，并加载相关用户。它很快，但是在启动的时候，会填充 UI，然后填充数据。

关于 iPhone app（或者所有应用），我的理论是，启动时间比其他大部分开发者想的都要重要。启动时间很慢的 app 是不太可能发布的，因为人们潜意识里记得，并且会产生阻止启动应用的想法（because people remember subconsciously and develop a resistance to launching that app）。减少启动时间就减少了摩擦（Reducing start-up time reduces friction），让用户更有可能继续使用你的应用，并且推荐给其他人。这是你让你的 app 成功的一部分。

因为我不使用 Core Data，我手头有一个简单的，保守的解决方案。我把时间轴（消息和人物对象）通过NSCoding保存到一个 plist 文件中。启动的时候它读取这个文件，创建消息和人物对象，UI一出现就显示时间轴。

这明显的减少了延迟。

把消息和人物对象作为 NSManagedObject 的实例对象，这是不可能的。（假设我已经编码并且存储的IDs对象，但是那意味着读取 plist 文件，然后触及数据库。这种方式我完全避免了数据库）。

（在更新更快的机器出来后, 我去掉了那些代码。回顾过去，我希望我可以把它留下来。）

## 我怎么考虑这个问题

当考虑是否使用 Core Data，我考虑下面这些事情：

### 会有难以置信数量的数据吗？

对于一个 RSS 阅读器或者 Twitter app，答案显而易见：是的。有些人关注上百个人。一个人可能订阅了上千个 feed。

即使你的应用不从网络获取数据，仍然有可能让用户自动添加数据。如果你用一个支持 AppleScript 的 Mac，有人会写脚本去加载非常多的数据。如果通过 web API 去加载数据也是一样的。

### 会有一个 Web API 包含类似于数据库的终端吗（对比类对象终端）？

一个 RSS 同步 API 能够返回一个已读文章的 uniqueID 列表。一个笔记的应用的一个同步 API 可能返回已存档的和已删除的笔记的 uniqueID 列表。

### 用户可能通过操作处理大量对象吗？

在底层，需要考虑和之前一样的问题。当有人删除所有已经下载的5，000个面食食谱，你的食谱 app 会表现如何？（在 iPhone 上？）

如果我决定使用 Core Data（我已经发布过使用 Core Data 的应用），我会特别注意我如何使用它。为了得到好的性能，我发现我把它当做一个 SQL 数据库的一个奇怪接口来使用，然后我知道我应该舍弃 Core Data，直接使用 SQLite。

## 我如何使用 SQLite

我通过 [FMDB Wrapper](https://github.com/ccgus/fmdb) 来使用 SQLite，FMDB 来自 Flying Meat Software，由 Gus Mueller 开发。

### 基本操作

在使用 iPhone 和 Core Data 之前，我就使用过 SQLite。这里一些要点：

* 所有数据库访问 - 读和写 - 发生在一个后台线程的连续的队列里。在主线程中触及数据库是从来不被允许的。使用一个连续队列来保证每一件事是按顺序发生的。
* 我大量使用blocks使得异步程序容易点。
* 模型对象只存在在主线程（但有两个重要的例外），改变会触发一个后台保存。
* 模型对象列出来他们在数据库中存储的属性。这可能在代码里或者在plist文件里。
* 有些模型对象是唯一的，有些不是。取决于 app 的需要（大部分情况是唯一的）。
* 对关系型数据，我尽可能避免创建查询表（I avoid creating lookup tables as much as possible）。
* 一些对象类型在启动的时候就完全读入内存，另一些对象类型我可能创建和维护的只有他们 uniqueID 的一个 NSMutableSet，所以我知道什么存在、什么不存在，不需要去触及数据库。
* Web API 的调用发生在后台线程，他们使用“分离“的模型对象。

我会使用我[目前的 app](http://vesperapp.co/) 的代码来描述。

### 数据库更新

在我最近的 app 中，有一个单一的数据库控制器 - `VSDatabaseController`，它通过 FMDB 来与 SQLite 对话。

FMDB 区分更新和查询。更新数据库，app 调用：

~~~
-[VSDatabaseController runDatabaseBlockInTransaction:(VSDatabaseUpdateBlock)databaseBlock]
~~~

`VSDatabaseUpdateBlock`很简单：

~~~
typedef void (^VSDatabaseUpdateBlock)(FMDatabase *database);
~~~

`runDatabaseBlockInTransaction`也很简单：

~~~
- (void)runDatabaseBlockInTransaction:(VSDatabaseUpdateBlock)databaseBlock {
    dispatch_async(self.serialDispatchQueue, ^{
        @autoreleasepool {
            [self beginTransaction];
            databaseBlock(self.database);
            [self endTransaction];
        }
    });
}
~~~

（注意我用自己的连续调度队列。Gus 建议看一下 `FMDatabaseQueue`，也是一个连续调度队列。我还没有去看一下，因为它比 FMDB 的其他东西都要新。）

`beginTransaction` 和 `endTransaction` 的调用是可嵌套的（在我的数据库控制器里）。在合适的时候他们会调用 `-[FMDatabase beginTransaction]` 和 `-[FMDatabase commit]`。（使用事务是让 SQLite变快的关键。）提示：我存储当前的事务计数在 `-[NSThread threadDictionary]`。它很好获取每一个线程的数据，我几乎从不用其他的。

这儿有个调用更新数据库的简单例子：

~~~
- (void)emptyTagsLookupTableForNote:(VSNote *)note {
    NSString *uniqueID = note.uniqueID;
    [self runDatabaseBlockInTransaction:^(FMDatabase *database) {
        [database executeUpdate:
            @"delete from tagsNotesLookup where noteUniqueID = ?;", uniqueID];
    }];
}
~~~

这说明一些事情。首先 SQL 并不可怕。即使你从没见过它，你也知道这行代码做了什么。

像 `VSDatabaseController` 的所有其他公共接口，`emptyTagsLookupTableForNote` 应该在主线程中被调用。模型对象只能在主线程中被引用，所以在 block 中使用 `uniqueID` ，而不是 VSNote 对象。

注意在这种情况下，我更新了一个查询表。Notes 和tags 有一个多对多关系，一种表现方式是用一个数据库表映射 note uniqueIDs 和 tag uniqueIDs。这些表不会很难维护，但是如果可能，我尽量避免使用他们。

注意在更新字符串中的?。`-[FMDatabase executeUpdate:]` 是一个可变参数函数。SQLite 支持使用占位符 - ? - 所以你不需要把真实的值放入字符串。这儿有一个安全问题：它帮助守护程序避免 SQL 注入。如果你需要避开某些值，它也为你省了麻烦。这可以减少您必须转换数值的麻烦。

最后，在 tagsNotesLookup 表中，注意有一个 noteUniquelID 的索引（索引是 SQLite 性能的又一个关键）。这行代码在每次启动时都调用：

~~~
[self.database executeUpdate:
    @"CREATE INDEX if not exists noteUniqueIDIndex on tagsNotesLookup (noteUniqueID);"];
~~~

### 数据库获取

要获取对象，app 调用：

~~~
-[VSDatabaseController runFetchForClass:(Class)databaseObjectClass 
                             fetchBlock:(VSDatabaseFetchBlock)fetchBlock 
                      fetchResultsBlock:(VSDatabaseFetchResultsBlock)fetchResultsBlock];
~~~

这两行代码做了大部分工作：

~~~
FMResultSet *resultSet = fetchBlock(self.database);
NSArray *fetchedObjects = [self databaseObjectsWithResultSet:resultSet 
                                                       class:databaseObjectClass];
~~~

用 FMDB 查找数据库返回一个 `FMResultSet`. 通过 resultSet 你可以逐句循环，创建模型对象。

我建议写通用的代码去转换数据库行到对象。一种我已经使用的方法是在 app 中用一个plist文件，映射列名字到对象属性。它也包含类型，所以你知道是否需要调用 `-[FMResultSet dateForColumn:]`， `-[FMResultSet stringForColumn:]`或其他方法。

在我的最新 app 里我使得一些事情变得更加简单。数据库行刚好对应模型对象属性的名字。所有属性都是s trings ，除了那些名字以“Date”结尾的属性。很简单，但是你可以看到需要一个清晰的对应关系。

### 唯一对象

创建的模型对象和从数据库获取数据在同一个后台线程。一但获取到，app 会把他们转到主线程。

通常我有唯一对象。同一个数据库行结果始终对应同一个对象。

为了做到唯一，我创建了一个对象缓存，一个 NSMapTable，在 init 函数里：`_objectCache = [NSMapTable weakToWeakObjectsMapTable]`。我来解释一下：

例如，当你做一个数据库获取并且把对象转交给一个视图控制器，你希望在视图控制器使用完这些对象后，或者一个不一样的视图控制器显示了，这些对象可以消失。

如果你的对象缓存是一个 NSMutableDictionary，你将需要做一些额外的工作来清空缓存中的对象。确定它对应的对象在别的地方是否有引用就变的很痛苦。NSMapTable是弱引用，就会自动处理这个问题。

所以：我们在主线程中让对象唯一。如果一个对象已经在对象缓存中存在，我们就用那个存在的对象。（主线程胜出，因为它可能有新的改变。）如果对象缓存中没有，它会被加上。

### 保持对象在内存中

有很多次，把整个对象类型保留在内存中是有道理的。我最新的 app 有一个 VSTag 对象。虽然可能有成百上千篇笔记，但 tags 的数量很小，基本少于10。一个 tag 只有6个属性：3个 BOOL，两个很小的 NSstring，还有一个 NSDate。

启动的时候，app 获取所有 tags 并且把他们保存在两个字典里，一个主键是 tag 的 uniqueID，另一个主键是 tag 名字的小写。

这简化了很多事，不只是 tag 自动补全系统，这个可以完全在内存中操作，不需要数据库获取。

但是很多次，把所有数据保留在内存中是不实际的。比如我们不会在内存中保留所有笔记。

但是也有很多次，当不能在内存中保留一个对象类型时，你希望在内存中保留所有 uniqueIDs。你会像这样做一个获取：

~~~
FMResultSet *resultSet = [self.database executeQuery:@"select uniqueID from some_table"];
~~~

resultSet 只包含了 uniqueIDs， 你可以存储到一个 NSMutableSet 里。

我发现有时这个对 web APIs 很有用。想象一个 API 调用返回从某个确定的时间以后的，已创建笔记的 uniqueIDs 列表。如果我本地已经有了一个包含所有笔记 uniqueIDs 的 NSMutableSet，我可以快速检查(通过 `-[NSMutableSet minusSet]`)是否有漏掉的笔记，然后去调用另一个 API 下载那些漏掉的笔记。这些完全不需要触及数据库。

但是，像这样的事情应该小心处理。app 可以提供足够的内存吗？它真的简化编程并且提高性能了吗？

使用 SQLite 和 FMDB 来代替 Core Data，给你带来大量的灵活性和聪明解决办法的空间。记住有的时候聪明是好的，也有的时候聪明是一个大错误。

### Web APIs

我的 API 调用都在后台进程（经常用一个 NSOperationQueue，所以我可以取消操作）。模型对象只在主线程，但是我还传递模型对象给我的 API 调用。

是这样的：一个数据库对象有一个 `detachedCopy` 方法，可以复制数据库对象。这个复制对象不是我用来唯一化的对象缓存的引用。唯一引用那个对象的地方是 API 调用，当 API 调用结束，那个复制的对象就消失了。

这是一个好的系统，因为它意味着我可以在 API 调用里使用模型对象。方法看起来像这样：

~~~
- (void)uploadNote:(VSNote *)note {
    VSNoteAPICall *apiCall = [[VSNoteAPICall alloc] initWithNote:[note detachedCopy]];
    [self enqueueAPICall:apiCall];
}
~~~

VSNoteAPICall从分离的 `VSNote` 获取值，并且创建 HTTP 请求，而不是一个字典或其他笔记的表现形式。

### 处理 Web API 的返回值

我对 web 的返回值做了一些类似的处理。我会对返回的 JSON 或者 XML 创建一个模型对象，这个模型对象也是分离的。它不是存储在为了唯一性的模型缓存里。

这儿有些事情是不确定的。有时有必要用那个模型对象在两个地方做本地修改：在内存缓存和数据库。

数据库通常是容易的部分。比如：我的 app 已经有一个方法来保存笔记对象。它用一个 SQL insert 或者replace 字符串。我只需调用那个从 web API 返回值生成的笔记对象，数据库就会更新。

但是可能那个对象有一个在内存中的版本，幸运的是我们很容易找到：

~~~
VSNote *cachedNote = [self.mapTable objectForKey:downloadedNote.uniqueID];
~~~

如果 cachedNote 存在，我会让它从 downloadedNote中 获取值，而不是替换它（这样可能违反唯一性）。（这可以共享 detachedCopy 方法的代码。）

一旦 cachedNote 更新了，观察者会通过 KVO 察觉到变化，或者我会发送一个 NSNotification，或者两者都做。

Web API 调用也会返回一些其他值。我提到过 RSS 阅读器可能获得一个已读条目的大列表。这种情况下，我用那个列表创建了一个 NSSet，在内存中更新每一个缓存文章的 read 属性，然后调用 `-[FMDatabase executeUpdate:]`。

完成这个工作的关键是 NSMapTable 的查找是快速的。如果你找的对象在一个 NSArray 里，我们该重新考虑。

## 数据库迁移

Core Data 的数据库迁移很酷，[当它可靠的时候](http://openradar.appspot.com/search?query=migration)。

但是不可避免的，它是代码和数据库中的一层。如果你越直接使用 SQLite，你更新数据库越直接。

你可以安全容易的做到这点。

比如加一个表：

~~~
[self.database executeUpdate:@"CREATE TABLE if not exists tags "
    "(uniqueID TEXT UNIQUE, name TEXT, deleted INTEGER, deletedModificationDate DATE);"];
~~~

或添加一个索引

~~~
[self.database executeUpdate:@"CREATE INDEX if not exists "
    "archivedSortDateIndex on notes (archived, sortDate);"];
~~~

或添加一列：

~~~
[self.database executeUpdate:@"ALTER TABLE tags ADD deletedDate DATE"];
~~~

app 应该在代码的第一个地方用上面这些代码设置数据库。以后的改变只需添加 executeUpdate 的调用 — 我让他们按顺序执行。因为我的数据库是我设计的，不会有什么问题（我从没碰到性能问题，它很快）。

当然大的改变需要更多代码。如果你的数据通过 web 获取，有时你可以从一个新数据库模型开始，重新下载你需要的数据。

## 性能技巧

SQLite 可以非常非常快，它也可以非常慢。完全取决于你怎么使用它。

### 事务

把更新包装在事务里。在更新前调用 `-[FMDatabase beginTransaction]`，更新后调用 `-[FMDatabase commit]`。

### 如果你不得不反规范化（ Denormalize）

[反规范化](http://en.wikipedia.org/wiki/Denormalization)让人很不爽。这个方法是，为了加速检索而添加冗余数据，但是它意味着你需要维护冗余数据。

我总是尽力避免它，直到这样能有严重的性能差异。然后我会尽可能少得这么做。

### 使用索引

我的 app 中 tags 表的创建语句像这样：

~~~
CREATE TABLE if not exists tags 
  (uniqueID TEXT UNIQUE, name TEXT, deleted INTEGER, deletedModificationDate DATE);
~~~

uniqueID 列是自动索引的，因为它定义为 unique。但是如果我想用 name 来查询表，我可能会在name上创建一个索引，像这样：

~~~
CREATE INDEX if not exists tagNameIndex on tags (name);
~~~

你可以一次性在多列上创建索引，像这样：

~~~
CREATE INDEX if not exists archivedSortDateIndex on notes (archived, sortDate);
~~~

但是注意太多索引会降低你的插入速度。你只需要足够数量并且是正确的那些。

### 使用命令行应用

当我的 app 在模拟器里运行时，我会用 NSLog 输出数据库的路径。我可以通过 sqlite3 的命令行来打开数据库。（通过 man sqlite3 命令来了解这个应用的更多信息）。

打开数据库的命令：sqlite3 path/to/database。

打开以后，你可以看 schema: type .schema。

你可以更新和查询，这是在使用你的app之前检查SQL是否正确的很好的方式。

这里面最酷的一部分是，[SQLite Explain Query Plan command](http://www.sqlite.org/eqp.html)，你会希望确保你的语句执行的尽可能快。

### 真实的例子

我的 app 显示所有没有归档笔记的标签列表。每当笔记或者标签有变化，这个查询就会重新执行一次，所以它需要很快。

我可以用 [SQL join](http://en.wikipedia.org/wiki/Join_%28SQL%29) 来查询，但是很慢（joins都很慢）。

所以我放弃 sqlite3 并开始尝试别的方法。我又看了一次我的 schema，意识到我可以反规范化。一个笔记的归档状态可以存储在 notes 表里，它也可以存储在 tagsNotesLookup 表。

然后我可以执行一个查询：

~~~
select distinct tagUniqueID from tagsNotesLookup where archived=0;
~~~

我已经有了一个在 tagUniqueID 上的索引。所以我用 explain query plan 来告诉我当我执行这个查询的时候会发生什么。

~~~
sqlite> explain query plan select distinct tagUniqueID from tagsNotesLookup where archived=0;
0|0|0|SCAN TABLE tagsNotesLookup USING INDEX tagUniqueIDIndex (~100000 rows)
~~~

它用了一个索引很不错，但是 SCAN TABLE 听起来不太好，最好是一个 SEARCH TABLE 并且[覆盖索引](http://www.sqlite.org/queryplanner.html#covidx)。
我在 tagUniqueID 和 archive 上建了索引：

~~~
CREATE INDEX archivedTagUniqueID on tagsNotesLookup(archived, tagUniqueID);
~~~

再次执行 explain query plan:

~~~
sqlite> explain query plan select distinct tagUniqueID from tagsNotesLookup where archived=0;
0|0|0|SEARCH TABLE tagsNotesLookup USING COVERING INDEX archivedTagUniqueID (archived=?) (~10 rows)
~~~

好多了。

### 更多性能提示

FMDB 的某处加了缓存 statements 的能力，所以当创建或打开一个数据库的时候，我总是调用 `[self.database setShouldCacheStatements:YES]`。这意味着对每个调用你不需要再次编译每个 statement。

我从来没有找到使用 `vacuum` 的好的指引，如果数据库没有定期压缩，它会越来越慢。我的 app 会每周跑一个 vacuum。（它在NSUserDefaults里存储上次vacuum的时间，然后在开始的时候检查是否过了一周）。


如果能 `auto_vacuum` 那更好，看 [pragma statements supported by SQLite](http://www.sqlite.org/pragma.html#pragma_auto_vacuum) 列表。

## 其他酷的东西

Gus Mueller 让我涉及自定义 SQLite 方法的内容。我并没有真的使用这些东西，既然他指出了，我可以放心的说我能找到它的用处。因为它很酷。

[在Gus的帖子里](https://gist.github.com/ccgus/6324222)，有一个查询是这样的：

~~~
select displayName, key from items where UTTypeConformsTo(uti, ?) order by 2;
~~~

SQLite 完全不知道 UITypes。但是你可以添加核心方法，查看 `-[FMDatabase makeFunctionNamed:maximumArguments:withBlock:]`。

你可以执行一个大的查询来替代，然后评估每个对象 - 但是那需要更多工作。最好在 SQL 级就过滤，而不是在将表格行转为对象以后。

## 最后

你真的应该使用Core Data，我不是在开玩笑。

我用 SQLite 和 FMDB 一段时间了，我对多得的好处感到很兴奋，也得到非同一般的性能。

但是记住机器在变快。也请记住，其他看你代码的人期望看到 Core Data，这是他们已经了解的 - 另一些人不打算看你的数据库代码如何工作。

所以请把这整篇文章看做一个疯子的叫喊，关于他为自己建立的细节和疯狂的世界 - 并把自己锁在里面。

有点难过的摇头，并且请享受这个问题中了不起的 Core Data 的文章。

接下来，在研究完 Gus 指出的自定义 SQLite 方法特性后，我会研究 SQLite 的 [full-text search extension](http://www.sqlite.org/fts3.html)。 总有更多的内容需要去学习。