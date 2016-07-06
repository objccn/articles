## 开袋即食

我们大多数人都至少熟悉某些 Core Data 提供给我们的直接可用的持久化特性。然而不幸的是，它们中的很多在 Android 平台上并不是自动化的。 例如，Core Data 抽象出大部分数据库的 SQL 语法和数据库标准，这些语法和标准都是数据库工程师们每天面对的问题。 因为 Android 仅提供一个简单的 SQLite 客户端，所以你扔需要写 SQL 并且确保你的数据库表被适当的标准化了。

Core Data 允许我们在对象方面考虑。 实际上，它能自动处理列集和散集对象。 得益于其提供了记录层的缓存，所以它在移动设备上的性能很好。每次从存储中请求同样的数据段时，它不用再创建另外一个的对象实例。当观察一个对象的变化时，我们甚至不需要刷新那个被观察对象就能做到。

Android 上可不是这种情况。你要完全负责将对象写入数据库或者从中将它们读取。这意味着你要自己实现对象缓存（如果需要的话），管理对象实例化，以及手动对任何已存在对象进行是否需要变更的检测。

在 Android 中，你需要注意版本特定的功能。不同版本的 Android 使用不同的 SQLite 实现。这意味着同一个数据库指令可能在其他平台版本上产生完全不同的结果。根据你执行的 SQLite 版本不同，一个查询语句也会执行得各不相同。

## 填缺补空

许多Android开发者来自企业。许多年来，[对象关系型映射](http://en.wikipedia.org/wiki/Object-relational_mapping)库一直在服务器平台上用于减轻与数据库的交互的难度。然而，这些库因为性能问题而导致无法在移动端直接使用。意识到这一点，一些开发者组织起来制作了面向移动端的 ORM 库来解决这一问题。

在 Android 上给 SQLite 添加 ORM 支持的其中一个使用广泛的的方法是 [OrmLite](http://ormlite.com)。OrmLite 提供对持久化对象的自动列集和散集化。它不用写大量的 SQL，并且提供程序接口来查询，更新，删除对象。在 ORM 中另一个竞争者是 [greenDAO](http://greendao-orm.com)。它提供许多与 OrmLite 类似的功能，但是承诺具有更好的性能(根据它的[网站](http://greendao-orm.com/features/#performance)上说)，例如基于注解的设置。

对第三方库通常都是抱怨都是加到项目中以后造成了额外的复杂度并且使得性能臃肿。有开发者觉得这实在很蛋疼，于是他写了一个叫 [Cupboard](https://bitbucket.org/qbusict/cupboard) 的轻量级 Android SQLite 框架的封装。它声称的目标是在不使用 ContentValues 和不解析 Cursors 的情况下为 Java 对象的提供持久化存储，它将会简单轻量，并整合时不会对核心 Android 类造成任何影响。你仍将需要管理数据库的创建，但是查询对象会变得简单很多。

还有开发者决定完全废弃 SQLite 并且创建了 [Perst](http://www.mcobject.com/perst)。它从开始到接口都是用面向对象语言设计的。它善于列集和散集对象，并且在性能跑分中表现很好。这种解决方法确实是完全替换了部分 Android 框架，但是也存在一定风险，因为你可能很难再在以后将其替换成不同方案了。

有这些甚至是更多可用的选择，为什么大家还都选择在原始的 Android 数据库框架下开发呢？这么说吧，框架和封装相较于它们所解决的问题，有时候能带来更多麻烦。例如，在一个项目中，我们同时写入数据库且实例化很多对象，这就会导致我们的 ORM 库慢得像爬一样。因为这个库不是设计用来让我们以这样的方式使用的。

在评估框架和库的时候，检查看看有没有使用 Java 的反射机制。反射机制在 Java 中代价相对较大，因此要谨慎使用。另外，如果你的项目是 Ice Cream Sandwich 前的版本，还要看看你的库是否在使用 Java 最近解决的一个 [bug](https://code.google.com/p/android/issues/detail?id=7811)，它会导致在运行时因为注解而导致的性能下降。

最后，还要评估添加框架会不会显著的增加项目的复杂度。如果你与其他开发者共同开发，记住，他们也必须花时间来学习该库。在你决定要不要使用一个第三方解决方案之前，弄明白 Android 到底是如何处理数据存储的这一问题，是非常重要的。

### 打开数据库

Android 上创建和打开数据库相对简单。你必须通过子类化 [SQLiteOpenHelper](http://developer.android.com/reference/android/database/sqlite/SQLiteOpenHelper.html) 来进行实现。默认的构造方法中，你要制定数据库名字。如果该数据库已经存在，它会被打开。如果不存在，则会被创建。应用能有许多单独的数据库文件。每个数据库都必须表示为单独的 `SQLiteOpenHelper` 子类。

数据库文件对你的应用来说是私有的，它们存在文件系统中你的应用的子文件夹下，并且受Linux文件访问权限保护。可惜的是，数据库文件没有加密。

但是创建数据库文件是不够的，在你的 `SQLiteOpenHelper` 子类中，你要重写 `onCreate()` 方法执行SQL语句创建表，视图以及任何数据库模式（schema）中的东西。你可以重写例如 `onConfigure()` 之类的其他方法来启用或禁用数据库功能，比如预写日志或外键支持等。

### 改变数据库模式 (schema)

除了在 `SQLiteOpenHelper` 子类的构造方法中指定数据库名字，你还要指定数据库版本号。版本号对于任意一个给定的 release 版本必须是不变的，而且根据框架的要求，这个数需要是只增不减的。

`SQLiteOpenHelper` 使用数据库的版本号来决定是否需要升级或降级。在升级或降级的回调方法中，你将使用提供给你的 `oldVersion` 和 `newVersion` 参数来决定哪个 [ALTER](http://www.w3schools.com/sql/sql_alter.asp) 语句需要执行来更新 schema。为每个新数据库版本提供单独的语句是一种很好的方法，这样就可以处理数据库的跨版本升级了。

### 连接到数据库

数据库查询是由 [SQLiteDatabase](http://developer.android.com/reference/android/database/sqlite/SQLiteDatabase.html) 类来管理的。 在你的 `SQLiteOpenHelper` 子类调用 `getReadableDatabase()` 或 `getWritableDatabase()` 时，会返回一个 `SQLiteDatabase` 实例。要注意这些方法通常会返回同一个对象。唯一一个例外是 `getReadableDatabase()`，在遇到诸如磁盘空间已满之类的问题时，它会返回一个只读的数据库，这时会阻止写入数据库。由于磁盘问题其实很少发生，许多开发者开发过程中只调用 `getWritableDatabase()`。

数据库创建和模式改变是在你第一次获得 `SQLiteDatabase` 实例后才会进行的。因此，你不能在主线程请求 `SQLiteDatabase` 实例。你的 `SQLiteOpenHelper` 子类几乎都会返回同样的 `SQLiteDatabase` 实例。这意味着在任何线程调用 `SQLiteDatabase.close()` 都会关闭你应用中所有的 `SQLiteDatabase` 实例。这就导致一大堆难于查找的 bug。实际上，有些开发者选择只在程序启动时打开 `SQLiteDatabase` ，只在程序关闭调用 `close()`。

### 查询数据

`SQLiteDatabase` 提供了对数据库进行查询，插入，更新及删除的方法。对于简单的查询，你不用写任何 SQL。但对于更高级的查询，你还要得自己写 SQL。SQLiteDatabase 有一个 `rawQuery()` 和 `execSQL()` 方法, 这能把整个 SQL 当做参数来执行高级查询，例如使用 unions 和 joins 命令。你可以使用 [SQLiteQueryBuilder](http://developer.android.com/reference/android/database/sqlite/SQLiteQueryBuilder.html) 来协助你完成适当的查询。

`query()` 和 `rawQuery()` 都返回 [Cursor](http://developer.android.com/reference/android/database/Cursor.html) 对象。保持 Cursor 对象的引用并且在应用中传来传去听起来十分诱人，但是 Cursor 对象比 单纯的 Java 对象 (Plain Old Java Object, POJO) 耗费更多的系统资源。因此，Cursor 对象需要尽快散集化到 POJO。在散集化之后你需要调用 `close()` 方法释放资源。

SQLite 中支持事务 (transactions)。你可以通过调用 `SQLiteDatabase.beginTransaction()` 开启一个事务。事务能通过调用 `beginTransaction()` 嵌套。当外层事务结束后所有在这个事务中完成的工作，以及所有嵌套的事务都需要提交或回滚。所有那些没有用 `setTransactionSuccessful()` 方法标记为完成的事务中的变更都会被回滚。

### 数据访问对象 (Data Access Object)

如前面提到的，Android 不提供任何列集和散集对象的方法。这意味着我们要负责管理从 Cursor 中取数据到 POJO 中的逻辑。这套逻辑应该用 [Data Access Object](http://en.wikipedia.org/wiki/Data_access_object) (DAO) 封装好。

Java 从业者，顺带上 Android 开发者，应该都对 DAO 模式很熟悉了。它的主要目的是将应用的交互从持久化层中抽象出来，而不暴露持久化的实现细节。这可以把应用从数据模式中隔离出来。这也使得迁移到第三方的数据库实现时，对应用的核心逻辑造成的风险能更小。你的应用中的所有与数据库的交互都应该通过 DAO 实现。

### 异步加载数据

获取 `SQLiteDatabase` 的参照是一个昂贵的操作，因此永远不要在主线程执行它。扩展来说，数据库查询也不要在主线程执行。Android 提供 [Loaders](http://developer.android.com/guide/components/loaders.html) 来帮助实现这一点。它们允许 activity 或 fragment 异步加载数据。Loaders 可以解决配置改变时数据持久的问题，也能检测数据并在内容改变的时候发送新的结果。Android 提供 [CursorLoader](http://developer.android.com/reference/android/content/CursorLoader.html) 来从数据库中加载数据。

### 与其他应用程序共享数据

虽然数据库对于创建它们的应用来说是私有的，但是 Android 也提供与其他应用程序共享数据的方法。[Content Providers](http://developer.android.com/guide/topics/providers/content-providers.html) 提供一个结构化的接口，能使其他应用读取甚至可能修改你的数据。和 `SQLiteDatabase` 类似, Content Providers 开放出 `query()`，`insert()`，`update()` 和 `delete()` 这些方法来操作数据。数据以 `Cursor` 的形式返回，而且对 Content Provider 的访问默认是同步的，这样可以使访问是线程安全的。

### 总结

Android 数据库与 iOS 上类似的功能相比，实现更加复杂。但是切记，不要只是为了减少模板代码而去使用第三方库。对于 Android 数据库框架的彻底理解会让你知道该不该选择使用第三方库，以及使用什么样的第三方库。[Android Developer 网站](http://developer.android.com) 提供了两个操作 SQLite 数据库的样例工程。你可以详细看看 [NotePad](http://developer.android.com/resources/samples/NotePad/index.html) 和 [SearchableDictionary](http://developer.android.com/resources/samples/SearchableDictionary/index.html) 这两个项目可以获得更多信息。

---

 
   
原文 [SQLite Database Support in Android](http://www.objc.io/issue-11/sqlite-database-support-in-android.html)