---
layout: post
title:  "SQLite Database Support in Android"
category: "11"
date: "2014-04-01 07:00:00"
tags: article
author: "<a href=\"https://twitter.com/jwkelso\">James Kelso</a>"
---


## Out of the Box
## 跳出思维定式


Most of us are familiar with at least some of the persistence features Core Data offers us out of the box. Unfortunately, many of those things aren't automatic on the Android platform. For instance, Core Data abstracts away most of the SQL syntax and database normalization concerns facing database engineers every day. Since Android only provides a thin client to SQLite, you'll still need to write SQL and ensure your database tables are appropriately normalized.

我们大多数人都至少熟悉某些Core Data提供给我们的不拘泥于形式的持久特性。 然而不幸的是，许多这种情况在Android平台上并不是自动化的。 例如，Core Data抽象出大部分数据库的SQL语法和数据库标准，这些语法和标准都是数据库工程师们每天面对的问题。 因为Android仅对瘦客户端提供SQLite， 所以你扔需要写SQL并且确保你的数据库表被适当的标准化了。

Core Data allows us to think in terms of objects. In fact, it handles marshaling and unmarshaling objects automatically. It manages to perform very well on mobile devices because it provides record-level caching. It doesn't create a separate instance of an object each time the same piece of data is requested from the store. Observation of changes to an object are possible without requiring a refresh each time the object is inspected. 

Core Data 允许我们在对象方面考虑。 实际上，它能自动处理列集和散集对象。 它在移动设备上管理起来效果甚好，因为它提供记录层的缓存。每次从存储中请求同样的数据段时，它不用再创建另外一个的对象实例。每当一个对象被检查时不需要刷新就能对该对象的变化能观察到。

This isn't the case for Android. You are completely responsible for writing objects into and reading them from the database. This means you must also implement object caching (if desired), manage object instantiation, and manually perform dirty checking of any objects already in existence.

Android不是这种情况。你要完全负责你写入或者读取数据库中的对象。这意味着你需要实现对象缓存（需要的话），来管理对象初始化和手动实现对任何已存在对象的垃圾清理检测。

With Android, you'll need to watch out for version-specific functionality. Different versions of Android ship with different implementations of SQLite. This means the exact same database instructions may give wildly different results across platform versions. A query may perform much differently based on which version of SQLite is executing it.

在Android中，你需要注意版本特定的功能。不同版本的Android使用不同的SQLite实现。这意味着同一个数据库指令可能在其他平台版本上产生完全不同的结果。根据你执行的SQLite版本不同，一个查询语句也会执行得各不相同。

## Bridging the Gap
## 弥补缺憾

Many Android developers come from the enterprise world. For many years, [object-relational mapping](http://en.wikipedia.org/wiki/Object-relational_mapping) libraries have been available on server platforms to ease the pain of interfacing with databases. Sadly, these libraries are much too performance intensive to be used out of the box in a mobile setting. Recognizing this, a few developers set out to solve this issue by creating mobile-friendly ORM libraries.

许多Android开发者来自企业。许多年来，[对象关系型映射](http://en.wikipedia.org/wiki/Object-relational_mapping) 库一直在服务器平台上用于减轻与数据库的交互。然而，这些库因为性能过于集中使得很难在移动环境下有新的使用。意识到这一点，一些开发者组织起来制作了移动端友好化的ORM库来解决这一问题。

One popular option for adding ORM support to SQLite on Android is [OrmLite](http://ormlite.com). OrmLite proffers automatic marshaling and unmarshaling of your persistent objects. It removes the need to write most SQL and provides a programmatic interface for querying, updating, and deleting objects. Another option in the ORM arena is [greenDAO](http://greendao-orm.com). It provides many of the same features as OrmLite, but promises better performance (according to its [website](http://greendao-orm.com/features/#performance)) at the cost of functionality, such as annotation-based setup.

在Android上给SQLite添加ORM支持的其中一个使用广泛的的方法是[OrmLite](http://ormlite.com)。OrmLite提供对持久化对象的自动列集和散集化。它不用写大量的SQL，并且提供程序接口来查询，更新，删除对象。另一个个方法是[greenDAO](http://greendao-orm.com)。它提供许多鱼OrmLite类似的功能，但是承诺在方法上有更好的性能(根据它的[网站](http://greendao-orm.com/features/#performance))，例如基于注释的设置。

A common complaint about third-party libraries is the extra layer of complexity and performance bloat they can add to a project. One developer felt this pain and decided to write [Cupboard](https://bitbucket.org/qbusict/cupboard), a thin wrapper around the Android SQLite framework. Its stated goals are to provide persistence of Java objects without using ContentValues and parsing Cursors, to be simple and lightweight, and to integrate with core Android classes without any hassle. You'll still need to manage creation of the database, but querying objects becomes a lot simpler.

对第三方库通常都是抱怨都是加到项目中以后造成了额外的复杂度并且使得性能臃肿。当一个开发者抛开烦恼并且决定写下[Cupboard](https://bitbucket.org/qbusict/cupboard)，一个轻量的Android SQLite框架的包裹类。它声称的目标是在不使用ContentValues和不解析Cursors的情况下提供Java对象的持久保存，而且简单轻量，对与核心Android类整合没有任何影响。你仍将需要管理数据库的创建，但是查询对象会变得非常简单。

Another developer decided to scrap SQLite entirely and created [Perst](http://www.mcobject.com/perst). It was designed from the beginning to interface with object-oriented languages. It's good at marshaling and unmarshaling objects and performs well in benchmarks. The concern for a solution like this is the fact that it's completely replacing a portion of the Android framework. This means you wouldn't be able to replace it in the future with a different solution.

另一个开发者已经决定完全废弃SQLite并且做出了[Perst](http://www.mcobject.com/perst)。它从开始到接口都是用面向对象语言设计的。它善于散集列集化对象，并且在评分中表现很好。这种解决方法确实是完全替换了部分Android框架。这说明你不能再在以后替换成不同方案了。

With these options and many more available, why would anyone choose to develop with the plain vanilla Android database framework? Well, frameworks and wrappers can sometimes introduce more problems than they solve. For instance, in one project, we were simultaneously writing to the database and instantiating so many objects that it caused our ORM library to slow to a crawl. It wasn't designed to handle the kind of punishment we were putting it through. 

有了这些还有更多可用的选择，为啥大家都选择在纯净的vanilla Android数据库框架下开发？这么说吧，框架和包裹类有时候能带来更多麻烦。例如，在一个项目中，我们同时写入数据库且实例化很多对象，这就会导致我们的ORM库慢得像爬一样。这并不是为了在我们使用它的时候来惩罚我们的。

When evaluating frameworks and libraries, check to see whether they make use of Java reflection. Reflection in Java is comparatively expensive and should be used judiciously. Additionally, if your project is pre-Ice Cream Sandwich, evaluate whether your library is using Java annotations. A recently fixed [bug](https://code.google.com/p/android/issues/detail?id=7811) was present in the runtime that caused annotations to be a drag on performance. 

在评估框架和库的时候，检查看看有没有使用Java的反射机制。反射机制在Java中代价相对较大，并且要谨慎使用。另外，如果你的项目是Ice Cream Sandwich前的版本，还要看看你的库是否在使用Java   最近解决的[bug](https://code.google.com/p/android/issues/detail?id=7811) 就在运行时能让annotations降低性能。

Finally, evaluate whether the addition of a framework will significantly increase the complexity level of your project. If you collaborate with other developers, remember that they'll have to work to learn the complexities of the library. It's extremely important to understand how stock Android handles data persistence before you decide whether or not to use a third-party solution.

最后，还要评估添加框架会不会显著的增加项目的复杂度。如果你与其他开发者共同开发，记住，他们必须了解到该库的复杂性。知道在你决定使用第三方方案的时候时刻意识到Android处理数据持久问题很不给力是非常重要的。

### Opening the Database
### 打开数据库


Android has made creating and opening a database relatively easy. It provides this through the [SQLiteOpenHelper](http://developer.android.com/reference/android/database/sqlite/SQLiteOpenHelper.html) class, which you must subclass. In the default constructor, you'll specify a database name. If a file with the specified name already exists, it's opened. If not, it's created. An application may have any number of separate database files. Each should be represented by a separate subclass of `SQLiteOpenHelper`.

Android上创建和打开数据库相对简单。你必须子类化 [SQLiteOpenHelper](http://developer.android.com/reference/android/database/sqlite/SQLiteOpenHelper.html) ，通过它来使用。默认的构造方法中，你要制定数据库名字。如果该数据库已经存在，就打开它。如果不存在，就创建一个。应用能有许多单独的数据库文件。每个数据库都必须表示为单独的`SQLiteOpenHelper`子类。

Database files are private to your application. They are stored in a subfolder of your application's section of the file system, and are protected by Linux file system permissions. Regrettably, the database files aren't encrypted.

数据库文件对你的应用来说是私有的。他们存在文件系统中你的应用的子文件夹下，并且受Linux文件访问权限保护。可惜的是，数据库文件没有加密。

Creating the database file isn't enough, though. In your `SQLiteOpenHelper` subclass, you'll have to override the `onCreate()` method to execute an SQL statement to create your database tables, views, and anything else in your database schema. You can override other methods such as `onConfigure()` to enable/disable database features like write-ahead logging or foreign key support.

但是创建数据库文件是不够的，在你的`SQLiteOpenHelper`子类中，你要重写`onCreate()`方法执行SQL语句建表，视图以及任何数据库模式中的东西。你能重写其他例如`onConfigure()` 的方法来使诸如预写日志或外键支持等功能可用或不可用。

### Changing the Schema
### 改变数据库模式

In addition to specifying database name in the constructor of your `SQLiteOpenHelper` subclass, you'll need to specify a database version number. This version number must be constant for any given release, and it's required by the framework to be monotonically increasing.

除了在`SQLiteOpenHelper`子类的构造方法中指定数据库名字，你还要指定数据库版本号。版本号必须是release版本的常数，而且需要根据框架增加。

`SQLiteOpenHelper` will use the version number of your database to decide if it needs to be upgraded or downgraded. In the hooks for upgrade or downgrade, you'll use the provided `oldVersion` and `newVersion` arguments to determine which [ALTER](http://www.w3schools.com/sql/sql_alter.asp) statements need to be run to update your schema. It's good practice to provide a separate statement for each new database version, in order to handle upgrading across multiple database versions at the same time.

`SQLiteOpenHelper` 使用数据库的版本号来决定是否需要升级或降级。在升级或降级的回调方法中，你将使用`oldVersion` 和 `newVersion`参数来决定哪个[ALTER](http://www.w3schools.com/sql/sql_alter.asp) 语句需要执行来更新模式。为不同新数据库版本提供单独的语句是一种很好的方法，以此同时处理各种数据库版本的升级。

### Connecting to the Database
###连接到数据库

Database queries are managed by the  [SQLiteDatabase](http://developer.android.com/reference/android/database/sqlite/SQLiteDatabase.html) class. Calling `getReadableDatabase()` or `getWritableDatabase()` on your `SQLiteOpenHelper` subclass will return an instance of `SQLiteDatabase`. Note that both of these methods usually return the exact same object. The only exception is `getReadableDatabase()`, which will return a read-only database if there's a problem, such as a full disk, that would prevent writing to the database. Since disk problems are a rare occurrence, some developers only call `getWritableDatabase()` in their implementation. 

数据库查询是由[SQLiteDatabase](http://developer.android.com/reference/android/database/sqlite/SQLiteDatabase.html) 类来管理。 在你的`SQLiteOpenHelper` 子类调用 `getReadableDatabase()` 或 `getWritableDatabase()`  会返回一个`SQLiteDatabase`实例。要注意这些方法通常会返回同一个对象。唯一一个例外是`getReadableDatabase()`，如果有问题它会返回一个制度的数据库，例如磁盘空间满的时候，这时会阻止写入数据库。犹豫磁盘问题很少发生，许多开发者开发过程中只调用`getWritableDatabase()`。

Database creation and database schema changes are lazy and don't occur until you obtain an `SQLiteDatabase` instance for the first time. Because of this, it's important you never request an instance of `SQLiteDatabase` on the main thread. Your `SQLiteOpenHelper` subclass will almost always return the exact same instance of `SQLiteDatabase`. This means a call to `SQLiteDatabase.close()` on any thread will close all `SQLiteDatabase` instances throughout your application. This can cause a number of difficult-to-diagnose bugs. In fact, some developers choose to open their `SQLiteDatabase` during application startup and only call `close()` when the application terminates.

数据库创建和模式转换是在你第一次获得 `SQLiteDatabase` 实例后才进行的。因此，你不能在主线程请求 `SQLiteDatabase` 实例。你的`SQLiteOpenHelper`子类几乎都会返回同样的`SQLiteDatabase`实例。这意味着在任何线程调用`SQLiteDatabase.close()`都会关闭你应用中得所有`SQLiteDatabase`实例。这就导致一大堆难于查找的bug。实际上，有些开发者选择只在程序启动打开`SQLiteDatabase`和程序关闭调用`close()`。

### Querying the Data
###查询数据


`SQLiteDatabase` provides methods for querying, inserting, updating, and deleting from your database. For simple queries, this means you don't have to write any SQL. For more advanced queries, though, you'll find yourself writing SQL. SQLiteDatabase exposes `rawQuery()` and `execSQL()` methods, which take raw SQL as an argument to perform advanced queries, such as unions and joins. You can use an [SQLiteQueryBuilder](http://developer.android.com/reference/android/database/sqlite/SQLiteQueryBuilder.html) to assist in constructing the appropriate queries.

`SQLiteDatabase`提供了许多方法来增删改查。对于检点的查询，你不用写任何SQL。但对于更高级的查询，你要自己写SQL。SQLiteDatabase 开放 `rawQuery()` 和 `execSQL()` 方法, 这能把整个SQL当做参数来执行高级查询，例如unions和joins。你能使用[SQLiteQueryBuilder](http://developer.android.com/reference/android/database/sqlite/SQLiteQueryBuilder.html)来协助你完成适当的查询。

Both `query()` and `rawQuery()` return [Cursor](http://developer.android.com/reference/android/database/Cursor.html) objects. It's tempting to keep references to your Cursor objects and pass them around your application, but Cursor objects take many more system resources to keep around than a Plain Old Java Object (POJO). Because of this, Cursor objects should be unmarshaled into POJOs as soon as possible. After they are unmarshaled, you should call the `close()` method to free up the resources.

`query()` 和 `rawQuery()` 都返回 [Cursor](http://developer.android.com/reference/android/database/Cursor.html)对象。保持Cursor对象的引用并且在应用中传递是非常好用的，但是Cursor对象和Plain Old Java Object (POJO)相比需要更多的系统资源。因此，Cursor对象需要尽快散集化到POJO。在散集化之后你需要调用`close()`方法释放资源。

Database transactions are supported in SQLite. You can start a transaction by calling `SQLiteDatabase.beginTransaction()`. Transactions can be nested by calling `beginTransaction()` while inside a transaction. When the outer transaction has ended, all work done in the transaction and all the nested transactions will be committed or rolled back. Changes are rolled back if any transaction ends without being marked as clean, using `setTransactionSuccessful()`.

SQLite中支持事务。你可以`SQLiteDatabase.beginTransaction()`开启事务。事务能通过调用`beginTransaction()` 嵌套。当外层事务结束后所有内部完成的工作或嵌套的事务都要提交或回滚。如果任何事务在没有用`setTransactionSuccessful()`方法标记完成的情况下都会回滚。

### Data Access Objects
###数据访问对象

As mentioned earlier, Android doesn't provide any method of marshaling or unmarshaling objects. This means we are responsible for writing the logic to take data from a Cursor to a POJO. This logic should be encapsulated by a [Data Access Object](http://en.wikipedia.org/wiki/Data_access_object) (DAO).

如前面提到的，Android不提供任何列集和散集对象的方法。这意味着我们要负责管理从Cursor中取数据到POJO中的逻辑。这套逻辑应该用[Data Access Object](http://en.wikipedia.org/wiki/Data_access_object) (DAO)封装好。

The DAO pattern is very familiar to practitioners of Java and, by extension, Android developers. Its main purpose is to abstract the application's interaction with the persistence layer without exposing the details of how persistence is implemented. This insulates the application from database schema changes. It also makes moving to a third-party database library less risky to the core application logic. All of your application's interaction with the database should be performed through a DAO.

DAO模式是Java从业者，还有Android开发者非常熟悉的。它主要是用于抽象与持久数据的应用接口，也不会暴露持久层的实现细节。这就把应用从数据模式中隔离出来。这页使得第三方数据库库文件添加到核心应用逻辑的时候风险更小。应用程序中所有与数据库的交互都应该通过DAO实现。

### Loading Data Asynchronously
###异步加载数据

Acquiring a reference to `SQLiteDatabase` can be an expensive operation and should never be performed on the main thread. By extension, database queries shouldn't be performed on the main thread either. To assist with this, Android provides [Loaders](http://developer.android.com/guide/components/loaders.html). They allow an activity or a fragment to load data asynchronously. Loaders solve the issue of data persistence across configuration changes, and also monitor the data source to deliver new results when content changes. Android provides the [CursorLoader](http://developer.android.com/reference/android/content/CursorLoader.html) to provide for loading data from a database.

获取`SQLiteDatabase`的应用会是一个代价巨大的操作，而且永远不要在主线程执行。相关的，数据库查询也不要在主线程执行。Android 提供 [Loaders](http://developer.android.com/guide/components/loaders.html)来帮助实现这一点。这允许activity或fragment异步加载数据。Loaders解决配置改变中数据持久的问题，也能在内容改变的时候检测数据也来发送新结果。Android 提供[CursorLoader](http://developer.android.com/reference/android/content/CursorLoader.html) 来从数据库中加载数据。

### Sharing Data with Other Applications

###与其他应用程序共享数据

The database is private to the application that created it. Android, however, provides a method of sharing data with other applications. [Content Providers](http://developer.android.com/guide/topics/providers/content-providers.html) provide a structured interface with which other applications can read and possibly even modify your data. Much like `SQLiteDatabase`, Content Providers expose methods such as `query()`, `insert()`, `update()`, and `delete()` to work with the data. Data are returned in the form of a `Cursor`, and access to the Content Provider is synchronized by default to make access thread-safe.

对创建数据库的应用来说它是私有的。但是Android提供与其他应用程序共享数据的一个方法。[Content Providers](http://developer.android.com/guide/topics/providers/content-providers.html)提供一个结构化的接口，能使其他应用读取甚至可能修改你的数据。比如`SQLiteDatabase`, Content Providers开放出`query()`, `insert()`, `update()`, 和 `delete()`这些方法来操作数据。数据返回到`Cursor`表格中，而且默认访问Content Provider是同步的以使访问是线程安全的。

## Conclusion

###总结

Android databases are much more implementation-heavy than their iOS counterparts. It's important, though, to avoid using a third-party library solely to avoid the boilerplate. A thorough understanding of the Android database framework will guide you in your choice of whether or not to use a third-party library, and if so, which library to choose. The [Android Developer Site](http://developer.android.com) provides two sample projects for working with SQLite databases. Check out the [NotePad](http://developer.android.com/resources/samples/NotePad/index.html) and [SearchableDictionary](http://developer.android.com/resources/samples/SearchableDictionary/index.html) projects for more information.

Android数据库跟对手iOS相比实现更加复杂。但是,为了避免单独使用一个第三方的库来避免样板是很重要的。对于Android数据库框架的彻底理解会让你知道该不该选择使用第三方库，使用的话使用什么库。[Android Developer Site](http://developer.android.com) 提供了两个操作SQLite数据库的样例工程。Check out [NotePad](http://developer.android.com/resources/samples/NotePad/index.html) 和 [SearchableDictionary](http://developer.android.com/resources/samples/SearchableDictionary/index.html) 两个项目可以查看更多信息。

