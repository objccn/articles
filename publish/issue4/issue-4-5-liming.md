往 Core Data 应用中导入大数据集是个很常见的问题。鉴于数据的特点你可以采用以下几种方法：

1. 从 web 服务器上下载数据 (例如 JSON 数据)，然后插入到 Core Data 中。
2. 从 web 服务器上下载预先生成的 Core Data SQLite 数据库文件。
3. 把一个预先生成好的 Core Data SQLite 数据库文件传到应用程序包中。

对某些应用场景后两种选择作为可行的方案经常被忽视了。因此，在本文中我们将进一步的了解他们，并总结一下如何高效地把web服务上的数据导入到一个动态的应用中。


## 传输预先生成的 SQLite 文件

当用大量数据来填充 Core Data 时，通过传输或下载预先生成的 SQLite 文件是一个可行的方案，并且比在客户端创建数据更加高效。如果源数据库包含静态数据，并且能够相对独立地与潜在的用户产生的数据共存，这就是该技术的使用场景。

Core Data 框架在 iOS 和 OS X 间是共用的，因此，我们可以创建 OS X 上的命令行工具来产生 SQLite 数据库文件，并且将该文件用在 iOS 应用中。

在我们的例子中 (你可以在 [Github](https://github.com/objcio/issue-4-importing-and-fetching) 上找到)，我们创建了一个命令行工具，它接受两个柏林城市的[数据集](http://stg.daten.berlin.de/datensaetze/vbb-fahrplan-2013)文件作为输入，并把它们插入到 Core Data SQLite 数据库中。这个数据集包含大约 13,000 逗留记录及三百万逗留时间记录。

对于该技术最重要的是，命令行工具和客户端应用使用了相同的数据模型。如果数据模型随着时间发生了改变，当你更新应用并传输新的源数据时，你要仔细地管理数据模型的版本。有一个好的建议就是不要复制.xcdatamodel文件，而是从命令行工具项目中把它链接到客户端应用项目。

另一个有用的步骤是在产生的 SQLite 文件上执行 `VACUUM` 命令。它会减小文件大小，因此根据你传输文件方式的不同，应用程序包的尺寸，或是要下载的数据库的尺寸也会相应减小。

除了这些，对于该过程真的没有别的方法了；在我们的[案例项目](https://github.com/objcio/issue-4-importing-and-fetching)中你也看到了，它就是些简单的标准 Core Data 代码。既然生成 SQLite 文件不是性能关键的任务，你也没必要花大力气去优化它的性能。如果你想让它更快，后面针对[高效地导入大数据集到动态应用中](#efficient-importing)所作的总结规则同样适用。


<a name="user-generated-data"> </a>

### 用户产生的数据

我们经常会有这样的场景，希望有一个可用的大的源数据集，但是也想能存储和修改一些用户产生的数据。同样，有几种方法来解决这个问题。

首先要考虑的是，用户产生的数据是否真的需要用 Core Data 来存储。如果我们能把这些数据存储到 plist 文件中，就不要乱动已建好的 Core Data 数据库。

如果我们想用 Core Data 来存储，另一个需要考虑的问题是，在将来是否需要通过传输更新的预先建好的 SQLite 文件来更新源数据集。如果这种情况不会发生，我们可以安全地把用户生产的数据包含到相同的数据模型和配置中。然而，如果我们想传输一个新源数据库，我们必须要分离源数据与用户产生的数据。

这个完全可以通过建立第二个完全独立的，使用自己的数据模型的 Core Data 来实现，或者通过在两个持久性存储间分发相同有数据模型的数据。对此，我们需要在同一个数据模型中创建第二个[配置](https://developer.apple.com/library/ios/documentation/cocoa/conceptual/CoreData/Articles/cdMOM.html#//apple_ref/doc/uid/TP40002328-SW3)，它保存用户产生的数据的实体。当配置 Core Data 栈时，我们将实例化两个持久化存储，其中一个包含 URL 和源数据库的配置，另一个包含 URL 和用户产生数据的数据库的配置。

使用两个独立的 Core Data 栈是一种更简单明了的方法。如果这个方法恰好能解决你的问题的话，我们强烈推荐使用它。然而，如果你想在用户产生的数据与源数据间建立关系，Core Data 不能帮你实现。即使你把所有的东西包含在一个扩展到两个持久化存储的数据模型中，你依然不能像通常那样在这些实体间定义关系，但是当获取某一特定属性时，你可以用 Core Data 中的 [fetched properties](https://developer.apple.com/library/ios/documentation/cocoa/conceptual/CoreData/Articles/cdRelationships.html#//apple_ref/doc/uid/TP40001857-SW7) 从不同的存储中自动获取对象。

### 应用 Bundle 中的 SQLite 文件

如果我们想往应用程序里传输一个预先生成的 SQLite 文件，我们必须检测出最新更新的应用是否是第一次打开，并把程序外部的数据库文件复制到目标目录：

    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError *error;

    if([fileManager fileExistsAtPath:self.storeURL.path]) {
        NSURL *storeDirectory = [self.storeURL URLByDeletingLastPathComponent];
        NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:storeDirectory
                                              includingPropertiesForKeys:nil
                                                                 options:0
                                                            errorHandler:NULL];
        NSString *storeName = [self.storeURL.lastPathComponent stringByDeletingPathExtension];
        for (NSURL *url in enumerator) {
            if (![url.lastPathComponent hasPrefix:storeName]) continue;
            [fileManager removeItemAtURL:url error:&error];
        }
        // 处理错误
    }

    NSString* bundleDbPath = [[NSBundle mainBundle] pathForResource:@"seed" ofType:@"sqlite"];
    [fileManager copyItemAtPath:bundleDbPath toPath:self.storeURL.path error:&error];


注意我们首先要删除之前的数据库文件。这不像你想的那样简单明了，因为可能会存在不同的附属文件（如日志或写前日志文件）与主要的 `.sqlite` 文件相关。因此我们必须遍历目录里的每一项，删除所有的与存储文件名字匹配不带扩展名的文件。

然而，我们也需要一个方法确保这件事我们只做了一次。一个很明显的方法就是从程序中把源数据库删除。虽然在模拟器上管用，但是因为权限的问题，在真机上会失败。有很多方案来解决这个问题，如在 user defaults 中设置一个 key，它包含了最新导入的数据的版本信息:

    NSString* bundleVersion = [infoDictionary objectForKey:(NSString *)kCFBundleVersionKey];
    NSString *seedVersion = [[NSUserDefaults standardUserDefaults] objectForKey@"SeedVersion"];
    if (![seedVersion isEqualToString:bundleVersion]) {
        // 复制源数据库
    }

    // ... 导入成功后
    NSDictionary *infoDictionary = [NSBundle mainBundle].infoDictionary;
    [[NSUserDefaults standardUserDefaults] setObject:bundleVersion forKey:@"SeedVersion"];


或者举个例子，我们也可以复制存在的数据库到一个包含源版本的路径来检测它是否存在, 从而避免做两个相同的导入。有很多可行的方法供你选择，这取决于你的应用场景最重要的是什么。


## 下载预先生成的 SQLite 文件

如果出于某些原因我们不想把源数据库包放在应用程序中(如，它会导致程序大小超过手机下载的阈值)，我们可以从 web 服务器上下载。过程与我们把数据库文件放在设备上是一样的。但是得保证，服务器提供的数据库版本要与客户端的数据模型兼容，因为不同的应用版本数据模型可能会改变。

这不仅仅是通过下载来替换应用程序中的一个文件，这个方案也使得填充更多的数据而不导致在客户端动态地导入数据引发的性能与电量损耗成为可能。

为了产生马上可用的 SQLite 文件，我们可以像前面那样在 (OS Ｘ) 服务器上运行类似的命令行导入程序。无可否认地，鉴于数据集的大小及要服务的请求数，对每一个请求该操作所需的计算资源可能不允许。一个可行的替代方案是定期地生成SQLite文件，给客户端发送这些现成的文件。

为了提供 SQLite 下载的 API，在服务器端及客户端当然需要额外的逻辑，SQLite 的下载可以为自上次源文件生成后已经发生改变的客户端提供数据。整个过程有点复杂，但是可以让你更容易的用任意大小的动态数据来填充 Core Data，而且没有性能问题(除了带宽限制)。


## 从 Web 服务导入数据

最后，让我们看看如何从 web 服务器上导入大量的数据，如 JSON 格式的数据。

如果我们要导入有关系的不同对象类型，我们需要在处理它们间的关系前先独立地导入所有的对象。如果我们能在 server 端保证客户端是以正确的顺序收到的对象，我们可以马上处理它们间的关系，而且不用为此担心。但大部分情况这是不可能的。

为在不影响用户界面响应前提下进行导入操作，我们必须在后台线程中执行导入操作。在第二期中，Chris写了一篇[在后台使用 Core Data](http://objccn.io/issue-2-2/) 的简单方式。如果做的正确，多核设备可以在不影响用户界面响应的情况下在后台执行导入操作。注意，并发地使用 Core Data 也有可能在不同的托管对象的上下文间产生冲突。你需要提出一种[策略](http://thermal-core.com/2013/09/07/in-defense-of-core-data-part-I.html)来预防或处理这些情况。

在本文中，理解 Core Data 的并发工作是很重要的。因为我们已经在两个线程上建立了两个被管理对象上下文，这并不表示它们两个会同时去访问数据库。从托管对象上下文发出的每个请求会对上下文的对象及 SQLite 文件加上锁。例如，如果你在主上下文的一个子上下文中触发了一个读请求，为了执行这个请求，主上下文，持久化存储协调器，持久化存储，以及 SQLite 文件都会被加锁（尽管加在 [SQLite 文件上的锁比其他对象要去除的快](http://developer.apple.com/wwdc/videos/?id=211)）。在此期间，其他在 Core Data 栈上每个对象会被阻塞等着这个请求的完成。

在后台上下文中大量导入数据的例子中，这意味着导入操作的保存请求会不断地在持久化存储协调器上加锁。在此期间，像为了更新用户界面而进行的读取请求，是不能在主上下文中执行的，而必须等待保存请求完成。因为 Core Data 的 API 是同步的，因此主线程会被阻塞，用户界面的响应会受影响。

如果在你的应用场景中这是个问题，你应该考虑为后台上下文使用带有自己的持久化存储协调器的独立 Core Data 栈。在这种情况下，在后台上下文与主上下文间唯一共享的资源就是 SQLite 文件，锁竞争会比之前有所减少。特别地，当 SQLite 文件以 [write-ahead loggin](http://www.qlite.org/draft/wal.html) 的方式执行 (在 iOS7 和 OS X 10.9 是默认的) 时，即使在 SQLite 文件级别，你也会得到真正并发。多个读和一个写可以同时来访问数据库(看这里 [WWDC 2013 session "What's New in Core Data and iCloud"](https://developer.apple.com/wwdc/videos/?id=207) )

最后，在大量导入数据时，实时地把修改通知合并到主上下文中一般不会是个好的做法。如果用户界面对这些变化自动响应的话（通过使用`NSFetchResultsController`），应用界面会陷入停顿。其实，我们可以在整个导入完成时发送一个自定义通知，让用户界面重新加载数据。

如果应用场景是想在导入数据期间就实时的更新UI界面，我们可以考虑过滤掉特定实体类型的保存通知，把它们按批聚集起来，或是其他减少界面更新频率的方式，来确保界面可以响应。然而，在大多数情况下并不值得这么做，因为对界面的频繁更新会让用户觉得更加迷惑，而非更有帮助。

在通过实际的导入例子讲述了设置方法和操作手法后，我们再来看一些让它尽可能高效的特殊方法。

<a name="efficient-importing"> </a>

### 高效地导入

为了高效导入数据，我们的第一个建议就是通读 [Apple 关于这个主题的指导](https://developer.apple.com/library/ios/documentation/cocoa/conceptual/CoreData/Articles/cdImporting.html)。我们也会强调该文档中经常容易被忘记的几个方面。

首先，你要在用于导入的上下文中把 `undoManager` 置为 `nil`。尽管这个只适用于 OS X，因为在 iOS 上，上下文默认没有 undo manager。把 `undoManager` 属性置空会带来重大的性能提升。

其次，访问具有**相互引用**关系的对象会产生引用环。如果你使用了设计良好的自动释放池后，还是看到在导入过程中内存使用不断增加，那就应该注意导入部分代码中的陷阱了。苹果在[这里](https://developer.apple.com/library/ios/documentation/cocoa/conceptual/CoreData/Articles/cdMemory.html#//apple_ref/doc/uid/TP40001860-SW3)描述了如何使用[`refreshObject:mergeChanges:`](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html#//apple_ref/occ/instm/NSManagedObjectContext/refreshObject:mergeChanges:)来去掉这些环。

当你导入可能已经在数据库中存在的数据时，你需要实现一些查找及创建的算法，以防止产生重复。对每一个对象执行读取请求效率很低，因为每个读取请求都需要 Core Data 到硬盘上从存储文件里读取数据。然而，通过按批导入数据并使用在上面提到的文档中 Apple 提供的高效查找创建算法，可以很容易避免这个问题。

当建立新导入的对象间的关系时，类似的问题也经常产生。用一个读取请求独立地获得每一个相关的对象是非常低效的。有两种可能的解决方法：一是像按批导入数据那样按批处理它们间的关系，二是缓存已经导入的对象的ID。

按批处理关系可以使我们大大地减少一次获取大量相关对象的读取请求次数。不用担心可能很长的查询语句，如：

    [NSPredicate predicateWithFormat:@"identifier IN %@", identifiersOfRelatedObjects];
    
处理一个在`IN (...)`从句中带有很多标识符的查询语句，总是比去硬盘上单独地读取每个对象更高效。

然而，也有一种可以完全避免读取请求的方法，(前提是你只需要在刚导入的对象间建立关系)。如果你缓存导入的所有对象的 IDs (实际上在大多数情况下数据量也不大)，之后你可以用 `objectWithID:` 方法为相关的对象建立关系。

    // 在一堆对象已经被导入并保存之后
    for (MyManagedObject *object in importedObjects) {
        objectIDCache[object.identifier] = object.objectID;
    }
    
    // ... 之后在解决关系时
    NSManagedObjectID objectID = objectIDCache[object.foreignKey];
    MyManagedObject *relatedObject = [context objectWithID:objectId];
    object.toOneRelation = relatedObject;
    
注意，这个例子假设 `identifier` 属性在所有的实体类型中是唯一的，否则，我们就得为我们多缓存的不同类型的对象 IDs 创建重复的标识符。

## 结论

当你遇到需要导入大量数据到 Core Data 中时，在做大量 JSON 数据的实时导入前，尽量先不要按常规来思考。特别是如果你能控制客户端和服务器端，经常会有很多解决该问题的高效方法。但是如果你不得不忍痛做大量后台导入工作，保证尽可能与主线程一样独立高效地进行。

---

 

原文 [Core Data Overview](http://www.objc.io/issue-4/importing-large-data-sets-into-core-data.html)
