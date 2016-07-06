自定义 Core Data 迁移似乎是一个不太起眼的话题。苹果在这方面只提供了很少的文档，若是初次涉足此方面内容，很可能会变成一个可怕的经历。鉴于客户端程序的性质，你无法测试你的用户所生成的数据集的所有可能排列。此外，解决迁移过程中出现的问题会很困难，而因为极有可能你的代码依赖于最新的数据模型，所以回退并不是一个可选的处理办法。

在本文中，我们将走一遍搭建自定义 Core Data 迁移的过程，并着重于数据模型的重构。我们将探讨从旧模型中提取数据并使用这些数据来填充具有新的实体和关系的目标模型。此外，会有一个包含单元测试的[示例项目](https://github.com/objcio/issue-4-core-data-migration)用于演示两个自定义迁移。

需要注意的是，如果对数据模型的修改只有增加一个实体或可选属性，轻量级的迁移是一个很好的选择。它们非常易于设置，所以本文只会稍稍提及它们。若想知道轻量级迁移的应用场合，请查看[官方文档](https://developer.apple.com/library/ios/documentation/cocoa/conceptual/CoreDataVersioning/Articles/vmLightweightMigration.html)。

这就是说，如果你需要快速地在你的数据模型上进行相对复杂的改变，那么自定义迁移就是为你准备的。

## 映射模型 (Mapping Models)

当你要升级你的数据模型到新版，你将先选择一个基准模型。对于轻量级迁移，持久化存储会为你自动推断一个*映射模型*。然而，如果你对新模型所做的修改并不被轻量级迁移所支持，那么你就需要创建一个映射模型。一个映射模型需要一个源数据模型和一个目标数据模型。 `NSMigrationManager` 能够推断这两个模型间的映射模型。这使得它很诱人，可用来一路创建每一个以前的模型到最新模型之间的映射模型，但这很快就会变成一团乱麻。对于每一个新版模型，你需要创建的映射模型的量将线性增长。这可能看起来不是个大问题，但随之而来的是测试这些映射模型的复杂度大大提高了。

想像一下你刚刚部署一个包含版本 3 的数据模型的更新。你的某个用户已经有一段时间没有更新你的应用了，这个用户还在版本 1 的数据模型上。那么现在你就需要一个从版本 1 到版本 3 的映射模型。同时你也需要版本 2 到版本 3 的映射模型。当你添加了版本 4 的数据模型后，那你就需要创建三个新的映射模型。显然这样做的扩展性很差，那就来试试渐进式迁移吧。

## 渐进式迁移 (Progressive Migrations)

与其为每个之前的数据模型到最新的模型间都建立映射模型，还不如在每两个连续的数据模型之间创建映射模型。以前面的例子来说，版本 1 和版本 2 之间需要一个映射模型，版本 2 和版本 3 之间需要一个映射模型。这样就可以从版本 1 迁移到版本 2 再迁移到版本 3。显然，使用这种迁移的方式时，若用户在较老的版本上迁移过程就会比较慢，但它能节省开发时间并保证健壮性，因为你只需要确保从之前一个模型到新模型的迁移工作正常即可，而更前面的映射模型都已经经过了测试。

总的想法就是手动找出当前版本 v 和版本 v+1 之间的映射模型，在这两者间迁移，接着继续递归，直到持久化存储与当前的数据模型兼容。

这一过程看起来像下面这样（完整版可以在[示例项目](https://github.com/objcio/issue-4-core-data-migration)里找到）：

    - (BOOL)progressivelyMigrateURL:(NSURL *)sourceStoreURL
                             ofType:(NSString *)type
                            toModel:(NSManagedObjectModel *)finalModel
                              error:(NSError **)error
    {
        NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:type
                                                                                                  URL:sourceStoreURL
                                                                                                error:error];
        if (!sourceMetadata) {
            return NO;
        }
        if ([finalModel isConfiguration:nil
            compatibleWithStoreMetadata:sourceMetadata]) {
            if (NULL != error) {
                *error = nil;
            }
            return YES;
        }
        NSManagedObjectModel *sourceModel = [self sourceModelForSourceMetadata:sourceMetadata];
        NSManagedObjectModel *destinationModel = nil;
        NSMappingModel *mappingModel = nil;
        NSString *modelName = nil;
        if (![self getDestinationModel:&destinationModel
                          mappingModel:&mappingModel
                             modelName:&modelName
                        forSourceModel:sourceModel
                                 error:error]) {
            return NO;
        }
        // 我们现在有了一个映射模型，开始迁移
        NSURL *destinationStoreURL = [self destinationStoreURLWithSourceStoreURL:sourceStoreURL
                                                                       modelName:modelName];
        NSMigrationManager *manager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel
                                                                     destinationModel:destinationModel];
        if (![manager migrateStoreFromURL:sourceStoreURL
                                     type:type
                                  options:nil
                         withMappingModel:mappingModel
                         toDestinationURL:destinationStoreURL
                          destinationType:type
                       destinationOptions:nil
                                    error:error]) {
            return NO;
        }
        // 现在迁移成功了，把文件备份一下以防不测
        if (![self backupSourceStoreAtURL:sourceStoreURL
              movingDestinationStoreAtURL:destinationStoreURL
                                    error:error]) {
            return NO;
        }
        // 现在数据模型可能还不是“最新”版，所以接着递归
        return [self progressivelyMigrateURL:sourceStoreURL
                                      ofType:type
                                     toModel:finalModel
                                       error:error];
    }

这段代码主要来源于 [Marcus Zarra](https://twitter.com/mzarra)，他写了一本很棒的关于 Core Data 的书，[查看这里](http://pragprog.com/book/mzcd2/core-data)。

自 iOS 7 和 OS Mavericks以来，Apple 将 SQLite 的日志模式改写为预写式日志 (Write-Ahead Logging)， 这意味着数据库事务都被依附到一个 -wal 文件中。这有可能导致数据丢失和异常。为了数据的安全，我们会将日志模式改写为回溯模式。而如果我们想要迁移数据（或者为了以后备份），我们可以将一个字典传递给 `-addPersistentStoreWithType:configuration:URL:options:error:` 来完成改写。

    @{ NSSQLitePragmasOption: @{ @"journal_mode": @"DELETE” } }
    
与 `NSPersistentStoreCoordinator` 相关的代码可以在[这里](https://github.com/objcio/issue-4-core-data-migration/blob/master/BookMigration/MHWCoreDataController.m#L73-L84)找到。

## 迁移策略

`NSEntityMigrationPolicy` 是自定义迁移过程的核心。 [苹果的文档](https://developer.apple.com/library/ios/documentation/cocoa/Reference/NSEntityMigrationPolicy_class/NSEntityMigrationPolicy.html)中有这么一句话: 

>  `NSEntityMigrationPolicy` 的实例为一个实体映射自定义的迁移策略。

简单的说，这个类让我们不仅仅能修改实体的属性和关系，而且还能任意添加一些自定义的操作来完成每个实体的迁移。

### 迁移示例

假设我们有一个带有简单的数据模型的[书籍应用](https://github.com/objcio/issue-4-core-data-migration)。这个模型有两个实体： `User` 和 `Book` 。`Book` 实体有一个属性叫做 `authorName`。我们想改善这个模型，添加一个新的实体： `Author`。同时我们想为 `Book` 和 `Author` 建立一个多对多的关系，因为一本书籍可有多个作者，而一个作者也可写多本书籍。我们将从 `Book` 对象里取出 `authorName` 用于填充一个新的实体并建立关系。

一开始我们要做的是基于第一个数据模型增加一个新版模型。在这个例子里，我们添加了一个 `Author` 实体，它与 `Book` 还有多对多的关系。

<img src="/images/issues/issue-4/cdm-model-2.png" width="416" height="291">

现在数据模型已经是我们所需要的，但我们还需要迁移所有已存在的数据，这就该 `NSEntityMigrationPolicy` 出场了。我们创建 `NSEntityMigrationPolicy` 的一个子类---- `MHWBookToBookPolicy` 。在映射模型里，我们选择 `Book` 实体并设置它作为公共部分（Utilities section）中的自定义策略。

<img src="/images/issues/issue-4/cdm-book-to-book-policy.png" name="Custom NSEntityMigrationPolicy subclass" width="260" height="308">

同时我们使用 user info 字典来设置一个 `modelVersion` ，它将在未来的迁移中派上用场。

在 [`MHWBookToBookPolicy`](https://github.com/hwaxxer/BookMigration/blob/master/BookMigration/MHWBookToBookPolicy.m) 中，我们将重载 `-createDestinationInstancesForSourceInstance:entityMapping:manager:error:` 方法，它允许我们自定义如何迁移每个 Book  实例。如果 `modelVersion` 的值不是 2，我们将调用父类的实现，否则我们就要做自定义迁移。我们插入基于映射的目标实体的新 `NSManagedObject` 对象到目标上下文。然后我们遍历目标实例的属性键值并与来自源实例的值一起填充它们。这将保证我们保留现存数据并避免设置任何我们已经在目标实例中移除的值。

    NSNumber *modelVersion = [mapping.userInfo valueForKey:@"modelVersion"];
    if (modelVersion.integerValue == 2) {
        NSMutableArray *sourceKeys = [sourceInstance.entity.attributesByName.allKeys mutableCopy];
        NSDictionary *sourceValues = [sourceInstance dictionaryWithValuesForKeys:sourceKeys];
        NSManagedObject *destinationInstance = [NSEntityDescription insertNewObjectForEntityForName:mapping.destinationEntityName
                                                                             inManagedObjectContext:manager.destinationContext];
        NSArray *destinationKeys = destinationInstance.entity.attributesByName.allKeys;
        for (NSString *key in destinationKeys) {
            id value = [sourceValues valueForKey:key];
            // 避免value为空
            if (value && ![value isEqual:[NSNull null]]) {
                [destinationInstance setValue:value forKey:key];
            }
        }
    }

然后我们将基于源实例的值创建一个 `Author` 实体。但若多本书有同一个作者会发生什么呢？我们将使用 `NSMigrationManager`  的一个 category 方法来创建一个查找字典，确保对于同一个名字的作者，我们只会创建一个 `Author`。

    NSMutableDictionary *authorLookup = [manager lookupWithKey:@"authors"];
    // 检查该作者是否已经被创建了
    NSString *authorName = [sourceInstance valueForKey:@"author"];
    NSManagedObject *author = [authorLookup valueForKey:authorName];
    if (!author) {
        // 创建作者
        // ...

        // 更新避免重复
        [authorLookup setValue:author forKey:authorName];
    }
    [destinationInstance performSelector:@selector(addAuthorsObject:) withObject:author];

最后，我们需要告诉迁移管理器在源存储与目的存储之间关联数据：

    [manager associateSourceInstance:sourceInstance
             withDestinationInstance:destinationInstance
                    forEntityMapping:mapping];
    return YES;

`NSMigrationManager` 的 category 方法:

    @implementation NSMigrationManager (Lookup)

    - (NSMutableDictionary *)lookupWithKey:(NSString *)lookupKey
    {
        NSMutableDictionary *userInfo = (NSMutableDictionary *)self.userInfo;
        // 这里检查一下是否已经建立了 userInfo 的字典
        if (!userInfo) {
            userInfo = [@{} mutableCopy];
            self.userInfo = userInfo;
        }
        NSMutableDictionary *lookup = [userInfo valueForKey:lookupKey];
        if (!lookup) {
            lookup = [@{} mutableCopy];
            [userInfo setValue:lookup forKey:lookupKey];
        }
        return lookup;
    }

    @end

### 一个更复杂的迁移

过了一会，我们又想把 `fileURL` 这个属性从 `Book` 实体里提出来，放入一个叫做 `File` 的新实体里。同时我们还想修改实体之间的关系，以便 `User` 可与 `File` 有一对多的关系，而反过来 `File` 和 `Book` 有多对一的关系。

<img name="Our 3rd model" src="/images/issues/issue-4/cdm-model-3.png" width="552" height="260">

在之前的迁移中，我们只迁移了一个实体。而现在当我们添加了 `File` 后，事情变得有些复杂了。我们不能简单地在迁移一个 `Book`  时插入一个 `File` 实体并设置它与 `User` 的对应关系，因为此时 `User` 实体还没有被迁移，之间的关系也无从谈起。*我们必须考虑迁移的执行顺序*。在映射模型中，是可以改变实体映射的顺序的。具体到这里的例子，我们想将 `UserToUser` 映射放在 `BookToBook` 映射之上。这保证了 `User` 实体会比 `Book` 实体更早迁移。

<img name="Mapping model orders are important" src="/images/issues/issue-4/cdm-mapping-order.png">

添加一个 `File` 实体的途径和创建 `Author` 的过程相似。我们在 `MHWBookToBookPolicy` 中迁移 `Book` 实体时创建 `File` 对象。我们会查看源实例的 `User` 实体，为每个 `User` 实体创建一个新的 `File` 对象，并建立对应关系：

    NSArray *users = [sourceInstance valueForKey:@"users"];
    for (NSManagedObject *user in users) {

        NSManagedObject *file = [NSEntityDescription insertNewObjectForEntityForName:@"File"
                                                              inManagedObjectContext:manager.destinationContext];
        [file setValue:[sourceInstance valueForKey:@"fileURL"] forKey:@"fileURL"];
        [file setValue:destinationInstance forKey:@"book"];
        
        NSInteger userId = [[user valueForKey:@"userId"] integerValue];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
        request.predicate = [NSPredicate predicateWithFormat:@"userId = %d", userId];
        NSManagedObject *user = [[manager.destinationContext executeFetchRequest:request error:nil] lastObject];
        [file setValue:user forKey:@"user"];
    }

### 大数据集

如果你的存储包含了大量数据，以至到达一个临界点，迁移就会消耗过多内存，Core Data 提供了一个以数据块（chunks）的方式迁移的办法。[苹果的文档](https://developer.apple.com/library/ios/documentation/cocoa/Conceptual/CoreDataVersioning/Articles/vmCustomizing.html#//apple_ref/doc/uid/TP40004399-CH8-SW9)有简要地提到这件事。解决办法是使用多映射模型分开你的迁移并为每个映射模型迁移一次。这要求你有一个对象图（object graph），在其中，迁移可被分为两个或多个部分。为了支持这一点而需要添加的代码其实很少。

首先，我们更新迁移方法以支持使用多个映射模型来迁移。已知映射模型的顺序很重要，我们将通过代理方法请求它们：

    NSArray *mappingModels = @[mappingModel]; // 我们之前建立的那个模型
    if ([self.delegate respondsToSelector:@selector(migrationManager:mappingModelsForSourceModel:)]) {
        NSArray *explicitMappingModels = [self.delegate migrationManager:self
                                             mappingModelsForSourceModel:sourceModel];
        if (0 < explicitMappingModels.count) {
            mappingModels = explicitMappingModels;
        }
    }
    for (NSMappingModel *mappingModel in mappingModels) {
        didMigrate = [manager migrateStoreFromURL:sourceStoreURL
                                             type:type
                                          options:nil
                                 withMappingModel:mappingModel
                                 toDestinationURL:destinationStoreURL
                                  destinationType:type
                               destinationOptions:nil
                                            error:error];
    }
    
现在，我们如何知晓哪一个映射模型被用于这个特定的源模型呢？此处的 API 可能显得有些笨拙，但以下的解决方法确实完成了工作。在代理方法中，我们找出源模型的名字并返回相关的映射模型：

    - (NSArray *)migrationManager:(MHWMigrationManager *)migrationManager 
      mappingModelsForSourceModel:(NSManagedObjectModel *)sourceModel
    {
        NSMutableArray *mappingModels = [@[] mutableCopy];
        NSString *modelName = [sourceModel mhw_modelName];
        if ([modelName isEqual:@"Model2"]) {
            // 把该映射模型加入数组
        }
        return mappingModels;
    }

我们将为 `NSManagedObjectModel` 添加一个 category，以帮助我们找出它的文件名：
We’ll add a category on `NSManagedObjectModel` that helps us figure out its filename:

    - (NSString *)mhw_modelName
    {
        NSString *modelName = nil;
        NSArray *modelPaths = // get paths to all the mom files in the bundle
        for (NSString *modelPath in modelPaths) {
            NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
            NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
            if ([model isEqual:self]) {
                modelName = modelURL.lastPathComponent.stringByDeletingPathExtension;
                break;
            }
        }
        return modelName;
    }

由于 `User` 在前面的例子（没有源关系映射）中被从对象图中隔离，因此迁移 `User` 的过程将省事很多。我们将从第一个映射模型中移除 `UserToUser` 映射，然后创建一个仅有 `UserToUser` 的映射。不要忘记在映射模型列表中返回新的 `User` 映射模型，因为我们正在其它映射中设置新关系。

## 单元测试

为此应用建立单元测试异常简单：

1. 将相关数据填入旧存储\*。
2. 将产生的持久性存储文件复制到你的*测试目标*。
3. 编写测试断言符合最新的数据模型。
4. 运行测试，迁移数据到新的数据模型。

*\*这很容易完成，只需在模拟器里运行一下你应用最新的版本（production version）即可*

步骤 1 和 2 很简单。步骤 3 留给读者作为练习，然后我会引导你通过第 4 步。 

当持久化存储文件被添加到单元测试目标上时，我们需要告知迁移管理器把那个存储迁移至我们的目标存储。在示例项目中所示如下：

    - (void)setUpCoreDataStackMigratingFromStoreWithName:(NSString *)name
    {
        NSURL *storeURL = [self temporaryRandomURL];
        [self copyStoreWithName:name toURL:storeURL];

        NSURL *momURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
        self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];

        NSString *storeType = NSSQLiteStoreType;

        MHWMigrationManager *migrationManager = [MHWMigrationManager new];
        [migrationManager progressivelyMigrateURL:storeURL
                                           ofType:storeType
                                          toModel:self.managedObjectModel
                                            error:nil];

        self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        [self.persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                      configuration:nil
                                                                URL:storeURL
                                                            options:nil
                                                              error:nil];

        self.managedObjectContext = [[NSManagedObjectContext alloc] init];
        self.managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    }

    - (NSURL *)temporaryRandomURL
    {
        NSString *uniqueName = [NSProcessInfo processInfo].globallyUniqueString;
        return [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:uniqueName]];
    }

    - (void)copyStoreWithName:(NSString *)name toURL:(NSURL *)url
    {
        // 每次创建一个唯一的url以保证测试正常运行
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSFileManager *fileManager = [NSFileManager new];
        NSString *path = [bundle pathForResource:[name stringByDeletingPathExtension] ofType:name.pathExtension];
        [fileManager copyItemAtPath:path
                             toPath:url.path error:nil];
    }

把下面的代码放到一个父类，以便于在测试的类中复用：

    - (void)setUp
    {
        [super setUp];
        [self setUpCoreDataStackMigratingFromStoreWithName:@"Model1.sqlite"];
    }

## 结论

轻量级迁移是直接在 SQLite 内部发生。这相对于自定义迁移来说非常快速且有效率。自定义迁移要把源对象读入到内存中，然后拷贝值到目标对象，重新建立关系，最后插入到新的存储中。这样做不仅很慢，而且当迁移大数据集时，由于内存大小的限制，它还会引起系统强制回收内存问题。

### 添加数据前尽量考虑完全

在处理任何数据持久性问题时最重要的事情之一就是仔细思考你的模型。我们希望模型是可持续发展的。在最开始创建模型的时候尽量考虑完全。添加空属性或者空实体也比以后进行迁移时候创建好的多，因为迁移很容易出现错误，而未使用的数据就不会了。

### 调试迁移

测试迁移时一个有用的启动参数是 `-com.apple.CoreData.MigrationDebug`。设置为 1 时，你会在控制台收到关于迁移数据时特殊情况的信息。如果你熟悉 SQL 但不了解 Core Data，设置 `-com.apple.CoreData.SQLDebug` 为 1 可在控制台看到实际操作的 SQL 语句。

---

 

原文 [Custom Core Data Migrations](http://www.objc.io/issue-4/core-data-migration.html)

译文 [Core Data 之自定义迁移策略](http://iosinit.com/?p=1019)

校对 [xinjixjz](https://github.com/xinjixjz)
