当乔布斯第一次在苹果全球开发大会上介绍 [iCloud](http://en.wikipedia.org/wiki/ICloud) 的时候，他将无缝同步的功能描述的太过完美，以至于让人怀疑其是否真的能实现。但当你在 [iOS 5](http://adcdownload.apple.com//videos/wwdc_2011__hd/session_303__whats_new_in_core_data_on_ios.m4v ) 和 [iOS 6](http://adcdownload.apple.com//videos/wwdc_2012__hd/session_227__using_icloud_with_core_data.mov) 系统中尝试使用 iCloud [Core Data](http://www.objc.io/issue-4/core-data-overview.html) 同步的时候你会对其真实情况了如指掌。

同步库风格应用(译者注:"盒子类型"，比如 iPhoto )的问题导致[很多](http://www.macworld.com/article/1167742/developers_dish_on_iclouds_challenges.html)[开发者](http://blog.caffeine.lu/problems-with-core-data-icloud-storage.html)[放弃](http://www.jumsoft.com/2013/01/response-to-sync-issues/)支持 iCloud，而选择一些其他的方案比如 [Simperium](http://simperium.com)，[TICoreDataSync](https://github.com/nothirst/TICoreDataSync) 和 [WasabiSync](http://www.wasabisync.com)。

2013年初，在经历了苹果公司不透明的折磨及 buggy 实施 iCloud Core Data 同步的多年挣扎后，开发者终于公开批判了服务的重大缺陷并将这个话题推上了[风口浪尖](http://arstechnica.com/apple/2013/03/frustrated-with-icloud-apples-developer-community-speaks-up-en-masse/)。 最终 Ellis Hamburger 在一篇[尖锐文章](http://www.theverge.com/2013/3/26/4148628/why-doesnt-icloud-just-work)提出。 

## WWDC

很明显这些事情必须改变，同时引起苹果的注意。在 WWDC 2013，[Nick Gillett](http://about.me/nickgillett) 宣布 Core Data 团队花了一年时间专注于解决 iOS 7中 iCloud 最令人挫败的漏洞，承诺大幅改善问题并且让开发者更简单的使用。“我们明显减少开发者编写复杂的代码。” Nick Gillett在 [“What’s New in Core Data and iCloud”] 舞台上讲到。 在 iOS 7中 Apple 专注于 iCloud 的速度，可靠性，和性能以及显示。

让我们看看是什么改变了，如何在 iOS 7应用程序实现 Core Data。


## 设置

设置一个 iCloud Core Data 应用，你首先需要在你的应用中请求 iCloud 的[访问权限](https://developer.apple.com/library/mac/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html)，让你的应用程序可以读写一个或多个开放性容器，在 Xcode 5中你可以在你应用 target 的选项卡 [“Capabilities”](https://developer.apple.com/xcode/) 中轻易完成着这一切。

在开放性容器内部，Core Data Framework 将会存储所有的事务日志 -- 记录你的所有持久化的存储 -- 为了跨设备同步数据做准备。 Core Data 使用了一个被称为[多源复制](http://en.wikipedia.org/wiki/Multi-master_replication)的技术来同步 iOS 和 Macs 之间的数据。可持久化存储的数据存在了每一个设备的 CoreDataUbiquitySupport 文件夹，你可以在应用沙盒中找到他。当用户修改了 iCloud accounts，Core Data framework 会管理多个账户并不需要你自己监听[`NSUbiquityIdentityDidChangeNotification`](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/nsfilemanager_class/Reference/Reference.html#//apple_ref/doc/uid/20000305-SW81)。

每一个事务日志都是一个`plist`文件，负责实体的跟踪插入，删除以及更新。这些日志会自动被系统按照一定[基准](http://mentalfaculty.tumblr.com/post/23788055417/under-the-sheets-with-icloud-and-core-data-seeding)合并。

在你设置iCloud的持久化存储的时候，调用[`addPersistentStoreWithType:configuration:URL:options:error:`](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSPersistentStoreCoordinator_Class/NSPersistentStoreCoordinator.html#//apple_ref/occ/instm/NSPersistentStoreCoordinator/addPersistentStoreWithType:configuration:URL:options:error:)或者 [`migratePersistentStore:toURL:options:withType:error:`](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSPersistentStoreCoordinator_Class/NSPersistentStoreCoordinator.html#//apple_ref/doc/uid/TP30001180-BBCFDEGA)的时候注意设置一些[选项](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSPersistentStoreCoordinator_Class/NSPersistentStoreCoordinator.html#//apple_ref/doc/constant_group/Store_Options):

- `NSPersistentStoreUbiquitousContentNameKey` (`NSString`)  
给 iCloud 存储空间指定一个名字（例如 @“MyAppStore”）

- `NSPersistentStoreUbiquitousContentURLKey` (`NSString`, optional in iOS 7)  
给事务日志指定一个二级目录(例如 @"Logs")

- `NSPersistentStoreUbiquitousPeerTokenOption` (`NSString`, optional)  
为每个程序设置一个盐，为了让不同应用可以在同一个集成 iCloud 的设备中分享 Core Data 数据 (比如`@"d70548e8a24c11e3bbec425861b86ab6"`)


- `NSPersistentStoreRemoveUbiquitousMetadataOption` (`NSNumber` (Boolean), optional)  
指定程序是否需要备份或迁移 iCloud 的元数据(例如 `@YES`)


- `NSPersistentStoreUbiquitousContainerIdentifierKey` (`NSString`)  
指定一个容器，如果你的应用有多个容器定义在 entitlements 中(例如 `@"com.company.MyApp.anothercontainer"`)


- `NSPersistentStoreRebuildFromUbiquitousContentOption` (`NSNumber` (Boolean), optional) 
告诉 Core Data 抹除本地存储数据并且用 iCoud 重建数据(例如 `@YES`)

只支持 iOS 7 的应用的唯一必填选项是 ContentNameKey，为了让 Core Data 知道把日志和元数据放在哪里。在 iOS 7中，你传入 NSPersistentStoreUbiquitousContentNameKey 的字符串值可以不包含'.'。 如果你的应用已经在使用 Core Data 去存储持久化数据，但是没有实现 iCloud 同步，你只需要简单加入 content name key 就可以为使用 iCloud，无需关注有没有活跃的 iCloud 账户。

为你的应用设置一个管理对象上下文简单到只需要实例化一个 `NSManagedObjectContext` 并告诉你的持久化存储，并且其中包含一个合并策略。苹果建议使用 `NSMergeByPropertyObjectTrumpMergePolicy`，他会合并冲突，并且在磁盘空间之前优先考虑内存变化。

而在 iOS 7 中苹果还没有官方发布的 iCloud Core Data 的示例代码，苹果的 Core Data 工程师团队在[开发者论坛](https://devforums.apple.com/message/828503#828503)提供了这个模板。我们稍微修改让他更清晰:
    #pragma mark - Notification Observers
    - (void)registerForiCloudNotifications {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    	
        [notificationCenter addObserver:self 
                               selector:@selector(storesWillChange:) 
                                   name:NSPersistentStoreCoordinatorStoresWillChangeNotification 
                                 object:self.persistentStoreCoordinator];
    
        [notificationCenter addObserver:self 
                               selector:@selector(storesDidChange:) 
                                   name:NSPersistentStoreCoordinatorStoresDidChangeNotification 
                                 object:self.persistentStoreCoordinator];
    
        [notificationCenter addObserver:self 
                               selector:@selector(persistentStoreDidImportUbiquitousContentChanges:) 
                                   name:NSPersistentStoreDidImportUbiquitousContentChangesNotification 
                                 object:self.persistentStoreCoordinator];
    }
    
    # pragma mark - iCloud Support
    
    /// Use these options in your call to -addPersistentStore:
    - (NSDictionary *)iCloudPersistentStoreOptions {
        return @{NSPersistentStoreUbiquitousContentNameKey: @"MyAppStore"};
    }
    
    - (void) persistentStoreDidImportUbiquitousContentChanges:(NSNotification *)notification {
        NSManagedObjectContext *context = self.managedObjectContext;
    	
        [context performBlock:^{
            [context mergeChangesFromContextDidSaveNotification:changeNotification];
        }];
    }
    
    - (void)storesWillChange:(NSNotification *)notification {
        NSManagedObjectContext *context = self.managedObjectContext;
    	
        [context performBlockAndWait:^{
            NSError *error;
    		
            if ([context hasChanges]) {
                BOOL success = [context save:&error];
                
                if (!success && error) {
                    // 执行错误处理
                    NSLog(@"%@",[error localizedDescription]);
                }
            }
            
            [context reset];
        }];
    
        // 刷新界面
    }
    
    - (void)storesDidChange:(NSNotification *)notification {
        // 刷新界面
    }

### 异步持久化设置

在 iOS 7 中，加入 iCloud 的参数并调用 `addPersistentStoreWithType:configuration:URL:options:error:` 它几乎瞬间返回数据。[^1] 其中内部设置了一个‘回滚’数据，利用本地存储作为一个占位符，而 iCloud 是由异步的事务日志和元数据构成。当它被添加到 coordinator 时更改后的回滚数据将被迁移到 iCloud 中。在回滚存储设置开始后控制台将会打印`Using local storage: 1` ，当 iCloud 完全设置完后你会看到‘Using local storage: 0’。 这句话的意思是 iCloud 存储已经启用。你可以通过监听`NSPersistentStoreDidImportUbiquitousContentChangesNotification`看到来自 iCloud 的内容。

如果你的应用关注存储迁移，需要监听 `NSPersistentStoreCoordinatorStoresWillChangeNotification` 以及/或者`NSPersistentStoreCoordinatorStoresDidChangeNotification`(将这些通知关联到你的 coordinator，这样就可以过滤其他和你无关的通知) 并且在 `userInfo` 中检查 `NSPersistentStoreUbiquitousTransitionTypeKey` 的值， 这个数值应该会在`NSPersistentStoreUbiquitousTransitionTypeInitialImportCompleted`发生改变的时候对NSNumber 的枚举数值装箱，[`NSPersistentStoreUbiquitousTransitionType`](https://developer.apple.com/library/ios/documentation/cocoa/Reference/CoreDataFramework/Classes/NSPersistentStoreCoordinator_Class/NSPersistentStoreCoordinator.html#//apple_ref/c/tdef/NSPersistentStoreUbiquitousTransitionType)

## 边缘情况

### Churn

最严重的一个问题是测试 iCloud iOS 5 和 iOS 6 时大量使用账户将遇到“混淆”，无法使用。同步将完全停止，甚至删除开放性数据使其不工作。在 [Lickability](http://lickability.com)，我们亲切地称为这种状态“f * \ \ * \ * ing bucket。”

在iOS 7中，系统提供了一个方法去移除全部的开放性存储内容: `+removeUbiquitousContentAndPersistentStoreAtURL:options:error:`，这个方法对测试很有帮助，在你应用中当你用户进入了一个不正常的状态需要删除所有数据重新来过的时候使用它。不过，需要指出的是：首先，这种方法是同步的。很可能长时间阻塞在网络操作，这种方法不会返回任何值直到完成为止。第二，绝对不能在有持久性存储 coordinators 活跃时执行此操作。这样会造成很严重的问题，你的应用程序可能进入一个不可恢复的状态，而且官方指导指出所有活跃的持久性存储 coordinators 应事先完全收回。


### 账户修改

iOS 5 系统中，用户在切换 iCloud 账户或者禁用账户时，`NSPersistentStoreCoordinator` 中的数据会在未知的情况下消失。事实上只有一种方法可以在改变账户时制止这种情况的发生。那就是在`NSFileManager`中调用`URLForUbiquityContainerIdentifier`。这个方法可以创建一个内容副本，并且迅速返回。在 iOS 6，这种情况随着引进`ubiquityIdentityToken`和相应的`NSUbiquityIdentityDidChangeNotification`之后迎刃而解，当身份进行转换的时候便会进行通知确认。这就可以对应用账户的变更进行有效的确认并及时的发出提示。

然而，iOS7 中这种转换的情况就变得简单许多，Core Data framework 支持账户的切换，因此只要你的程序能够正常响应`NSPersistentStoreCoordinatorStoresWillChangeNotification`和`NSPersistentStoreCoordinatorStoresDidChangeNotification`便可以在切换账户的时候流畅的更换信息，检查`userInfo`的字典中“NSPersistentStoreUbiquitousTransitionType 'key将对过渡类型提供更多的细节。

在应用沙箱中框架只能在每个账户中管理独立管理持久化存储，所以这就意味着如果用户回到之前的账户，它的数据就会仍然可用。Core Data 依旧在磁盘空间低位运行的情况下对这些文件的清理进行管理。


### iCloud 的启用与停用

在 iOS 7 中应用实现用一个开关用来切换启用关闭 iCloud 变的非常容易，虽然对大部分应用来说这个功能不是很需要，因为 API 现在已经支持在创建`NSPersistentStore`时候如果加入 iCloud 选项，那么将自动建立一个独立的文件结构，这意味着从一个 iCloud 存储到一个本地存储可以通过迁移 iCloud 持久存储到同一个URL相同的选项加上`NSPersistentStoreRemoveUbiquitousMetadataOption` 来完成。这个选项将把存储中的ubiquitous的元数据进行分离，并专门为这些类型创建了迁移或者复制的场景。下面是一个示例:

    - (void)migrateiCloudStoreToLocalStore {
        // 假设你只有一个存储单元
        NSPersistentStore *store = [[_coordinator persistentStores] firstObject]; 
        
        NSMutableDictionary *localStoreOptions = [[self storeOptions] mutableCopy];
        [localStoreOptions setObject:@YES forKey:NSPersistentStoreRemoveUbiquitousMetadataOption];
        
        NSPersistentStore *newStore =  [_coordinator migratePersistentStore:store 
                                                                      toURL:[self storeURL] 
                                                                    options:localStoreOptions 
                                                                   withType:NSSQLiteStoreType error:nil];
        
        [self reloadStore:newStore];
    }
    
    - (void)reloadStore:(NSPersistentStore *)store {
        if (store) {
            [_coordinator removePersistentStore:store error:nil];
        }
    
        [_coordinator addPersistentStoreWithType:NSSQLiteStoreType 
                                   configuration:nil 
                                             URL:[self storeURL] 
                                         options:[self storeOptions] 
                                           error:nil];
    }

切换一个本地存储到iCloud 存储是一个非常容易的事情，简单到只需启用 iCloud 选项，并且把拥有相同选项的可持久存储加入到 coordinator 中。

### 外部文件的引用

外部文件的应用是一个在 iOS 5中加入的 Core Data 新特性允许大的二进制自动存储在 SQLite 数据库之外的文件系统中。 在我们测试中，当它改变，iCloud 并不知道如何解决依赖关系以及抛出异常。如果您计划使用 iCloud同步 ,可以考虑在iCloud实体中取消这个选择:

![Core Data Modeler Checkbox](http://cloud.mttb.me/UBrx/image.png)

### Model版本

如果你计划使用 iCloud，存储的内容只能在未来兼容自动[轻量级迁移](https://developer.apple.com/library/ios/documentation/cocoa/conceptual/CoreDataVersioning/Articles/vmLightweightMigration.html)，
这意味着你不能提供自己的Core Data映射模型，并且它必须能够推断出映射。在未来只有简单的改变您的 Model，比如添加和重命名属性。在考虑是否使用 Core Data 同步时，一定要考虑到你的 app 的 Model 在未来版本中改变的情况。

### 合并冲突

在很多的同步系统中，服务器和客户端之前的文件冲突是不可避免的。不同于 [iCloud Data Document Syncing](https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesigningForDocumentsIniCloud.html#//apple_ref/doc/uid/TP40012094-CH2-SW1) APIs, iCloud 的 Core Data 整合并没有明确允许处理本地存储和事务日志之间的冲突。但是幸运的是 Core Data 以及通过继承 `NSMergePolicy` 的来自定义策合并策略。 如果你要处理冲突，创建`NSMergePolicy`的子类并且覆盖`resolveConflicts:error:` 来决定在冲突发生的时候做什么，然后在你的`NSManagedObjectContext`子类中，从`mergePolicy`返回一个你自定义的策略的实例。


### 界面更新

很多库风格应用同时显示集合对象和一个对象的详细信息。 视图是由 `NSFetchedResultsController` 实例自动从网络更新 Core Data 的数据改变。然而，您应该确保每一个详细视图正确监听变化对象并使自己保持最新。如果你不这样做, 将有显示陈旧的数据的风险或者更糟，你将覆盖其他设备修改的数据。

## 测试

### 本地网络和因特网同步

iCloud 守护进程可以跨设备同步数据两种方式中的一种：在你的本地网络或在因特网上。守护进程检测到两个设备时，也被称为对等网络，在同一个局域网，将在内网快速传输。然而，如果在不同的网络，该系统将传输回滚事务日志。这很重要，你必须测试这两种情况下大量开发，以确保您的应用程序正常运作。在这两种场景中，从备份存储同步更改或过渡到 iCloud 有时需要比预期更长的时间，所以如果有什么不工作，尝试给它点时间。

### 模拟器中使用 iCloud
	
在 iOS 7 中最有用的更新就是 iCloud 终于可以在[模拟器](https://developer.apple.com/library/mac/documentation/General/Conceptual/iCloudDesignGuide/Chapters/TestingandDebuggingforiCloud.html)中使用。在以往的版本中，你只能在设备中测试，这就限制了很难监听开发的同步进程。现在你可以在你的 Mac 和模拟器中同步数据。

在 Xcode 5 新增的 iCloud Debug 选项中，你可以看到在你的应用程序的开放性存储中的文件和检查他们的文件传输状态，比如 "Current，" "Excluded，" and "Stored in Cloud。"。 更多的编码测试，需要启用详细日志通过把`-com.apple.coredata.ubiquity.logLevel 3`加入到启动参数或者设置成用户默认，并考虑在iOS中安装 [iCloud存储调试日志配置文件](http://developer.apple.com/downloads) 以及新的 [`ubcontrol`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/Manpages/man1/ubcontrol.1.html)OS X的命令行工具提供高质量错误报告到Apple 。你可以在你的设备连入iTunes后获取这些工具生成的日志`~/Library/Logs/CrashReporter/MobileDevice/device-name/DiagnosticLogs`。

然而，iCloud Core Data 并不完全支持模拟器。测试设备和模拟器传输时，似乎 iCloud Core Data 模拟器只上传更改，而且从不把他们推送回去。这仍然是需要更大的进步空间，虽然不再使用一个额外的设备调试已经是一个巨大的进步，但是 iCloud Core Data 支持 iOS 模拟器上绝对没有完全成熟。


## 继续前行

在 iOS 7 中 APIs 和功能得到了极大的改善，在 iOS 5 和 iOS 6 分发带有 iCloud Core Data 的应用的后果依然不可预知。 仅从 API 角度来看他们完全不同（当然我们从功能角度也验证了这一点)，苹果建议不要在不同版本设备间的同步因为还没准备好**来自 [Apple Developer Forums](https://devforums.apple.com/thread/199983?start=0&tstart=0*) 的建议，数据不要在 iOS 7 和之前的设备同步之间同步**.

事实上，“任何时候你都不应该在 iOS 7 与 iOS 6 同步。iOS 6 将持续造成 bug 并且在 iOS 7修复，但在这样做会污染 iCloud 账户。“保证这种分离的最简单的方法是通过简单地改变你存储中的 `NSPersistentStoreUbiquitousContentNameKey`，为每一次改变设置单独的名字，这样保证从旧版本保证数据同步的方法是孤立的，并允许开发人员完全舍弃旧的数据。

## 分发
 
分发一个 iCloud Core Data 应用仍旧有很大的风险，你需要对所有的环节进行测试：账户转换，iCloud 存储空间耗尽，各种设备的测试和修复，Model 的升级。尽管 iCloud debug 选项和 [developer.icloud.com](http://developer.icloud.com) 对这些有所帮助，但依靠一个你完全无法控制的服务来发布一个应用仍然需要那种纵身一跃入深渊的信念。

正如 brent simmon [提到](http://inessential.com/2013/03/27/why_developers_shouldnt_use_icloud_sy)的，分发任意一种 iCloud Syncing 发布的应用都会被限制，
所以需要事先了解一下成本。像 [day one](http://dayoneapp.com) 和 [1password](https://agilebits.com/onepassword) 这样的程序，会选择让使用者用 iCloud 或者 Dropbox 来同步他们的数据。对于很多使用者来说，没什么可以比一个独立的账户更加简易，但是一部分动手能力强的人喜欢更好的更全面的控制他们的数据。对于开发者而言，维持这种全异性[数据库同步系统](https://www.dropbox.com/developers/datastore)在开发和测试的过程当中是十分繁琐和超负荷的。


## Bugs 

一旦你测试并且分发了你的 iCloud Core Data 应用，你将很会遇到很多框架里的错误，最好的办法是反馈这些 bug 的详细信息到 [Apple](http://bugreport.apple.com)，其中需要包含一下信息：

1. 完整的重现步骤
2. 输出到控制台的级别为3的 iCloud 调试日志和 iCloud 调试配置文件安装。
3. 完整的开放性存储内容 zip 压缩文件


## 结论

在 iOS 5 和 6 中 iCloud Core Data 功能性差异已经是不是一个秘密， 来自苹果的程序员承认“有重大的长期稳定性和可靠性问题与在 iOS 5/6 当使用 Core Data 以及 iCloud…，真的真的真的真的，需要在 iOS 7 中提高“高端的程序员比如 [Agile Tortoise](http://agiletortoise.com) 以及 [Realmac Software](http://realmacsoftware.com) 现在可以在他们的应用中信任 iCloud Core Data，并有足够的[考量](https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/Introduction.html)以及测试，你也应该如此。

*特别感谢 Andrew Harrison, Greg Pierce, and Paul Bruneau 对这篇文章的帮助*

[^1]: 在之前的 OS 版本中，这个方法将不会任何值直到 iCloud 数据下载并合并到持久化存储中。这将造成严重的延误，这意味着任何需要调用方法需要在一个后台的队列中，值得庆幸的这不需要很长时间。
