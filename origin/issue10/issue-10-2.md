[Source](http://www.objc.io/issue-10/icloud-core-data.html "Permalink to iCloud and Core Data - Syncing Data - objc.io issue #10 ")

# iCloud and Core Data - Syncing Data - objc.io issue #10 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# iCloud and Core Data

[Issue #10 Syncing Data][4], March 2014

By [Matthew Bischoff][5] & [Brian Capps][6]

When Steve Jobs first introduced [iCloud][7] at WWDC 2011, the promise of seamless syncing seemed too good to be true. And if you tried to implement iCloud [Core Data][8] syncing in [iOS 5][9] or [iOS 6][10], you know very well that it was.

Problems with syncing [library-style applications][11] continued as [many][12] [developers][13] [abandoned][14] iCloud in favor of alternatives like [Simperium][15], [TICoreDataSync][16], and [WasabiSync][17].

In early 2013, after years of struggling with Apple’s opaque and buggy implementation of iCloud Core Data sync, the issues reached a breaking point when developers [called out][18] the service’s shortcomings, culminating in a [pointed article][19] by Ellis Hamburger at The Verge.

## WWDC

It was clear something had to change, and Apple took notice. At WWDC 2013, [Nick Gillett][20] announced that the Core Data team had spent a year focusing on fixing some of the biggest frustrations with iCloud in iOS 7, promising a vastly improved and simpler implementation for developers. “We’ve significantly reduced the amount of complex code developers have to write,” Nick said on stage at the [“What’s New in Core Data and iCloud”][21] session. With iOS 7, Apple focused on the speed, reliability, and performance of iCloud, and it shows.

Let’s take a look at what’s changed and how you can implement iCloud Core Data in your iOS 7 app.

## Setup

To set up an iCloud Core Data app, you must first request access to iCloud in your application’s [entitlements][22], which will give your app the ability to read and write to one or more ubiquity containers. You can do this easily from the new [“Capabilities”][23] screen in Xcode 5, accessible from your application’s target.

Inside a ubiquity container, the Core Data framework will store transaction logs – records of changes made to your persistent store – in order to sync data across devices. Core Data uses a technique called [multi-master replication][24] to sync data across multiple iOS devices and/or Macs. The persistent store file itself is stored on each device in a Core Data-managed directory called `CoreDataUbiquitySupport`, inside your application sandbox. As a user changes iCloud accounts, the Core Data framework will manage multiple stores within this directory without your application having to observe the [`NSUbiquityIdentityDidChangeNotification`][25].

Each transaction log is a `plist` file that keeps track of insertions, deletions, and updates to your entities. These logs are occasionally automatically coalesced by the system in a process known as [baselining][26].

To set up your persistent store for iCloud, there are a few [options][27] you need to be aware of to pass when calling [`addPersistentStoreWithType:configuration:URL:options:error:`][28] or [`migratePersistentStore:toURL:options:withType:error:`][29]:

  * `NSPersistentStoreUbiquitousContentNameKey` (`NSString`)
Specifies the name of the store in iCloud (e.g. `@"MyAppStore"`)
  * `NSPersistentStoreUbiquitousContentURLKey` (`NSString`, optional in iOS 7)
Specifies the subdirectory path for the transaction logs (e.g. `@"Logs"`)
  * `NSPersistentStoreUbiquitousPeerTokenOption` (`NSString`, optional)
A per-application salt to allow multiple apps on the same device to share a Core Data store integrated with iCloud (e.g. `@"d70548e8a24c11e3bbec425861b86ab6"`)
  * `NSPersistentStoreRemoveUbiquitousMetadataOption` (`NSNumber` (Boolean), optional)
Used whenever you need to back up or migrate an iCloud store to strip the iCloud metadata (e.g. `@YES`)
  * `NSPersistentStoreUbiquitousContainerIdentifierKey` (`NSString`)
Specifies a container if your app has multiple ubiquity container identifiers in its entitlements (e.g. `@"com.company.MyApp.anothercontainer"`)
  * `NSPersistentStoreRebuildFromUbiquitousContentOption` (`NSNumber` (Boolean), optional)
Tells Core Data to erase the local store file and rebuild it from the iCloud data (e.g. `@YES`)

The only required option for an iOS 7-only application is the content name key, which lets Core Data know where to put its logs and metadata. As of iOS 7, the string value that you pass for `NSPersistentStoreUbiquitousContentNameKey` may not contain periods. If your application already uses Core Data for persistence but you haven’t implemented iCloud syncing, simply adding the content name key will prepare your store for iCloud, whether or not there is an active iCloud account.

Setting up a managed object context for your application is as simple as allocating an instance of `NSManagedObjectContext` and telling it about your persistent store, as well as including a merge policy. Apple recommends `NSMergeByPropertyObjectTrumpMergePolicy`, which will merge conflicts, giving priority to in-memory changes over the changes on disk.

While Apple hasn’t released official sample code for iCloud Core Data in iOS 7, an Apple engineer on the Core Data team provided this basic template [on the Developer Forums][30]. We’ve edited it slightly for clarity:


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

    - (void) persistentStoreDidImportUbiquitousContentChanges:(NSNotification *)changeNotification {
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
                    // perform error handling
                    NSLog(@"%@",[error localizedDescription]);
                }
            }

            [context reset];
        }];

        // Refresh your User Interface.
    }

    - (void)storesDidChange:(NSNotification *)notification {
        // Refresh your User Interface.
    }

### Asynchronous Persistent Store Setup

In iOS 7, calling `addPersistentStoreWithType:configuration:URL:options:error:` with iCloud options now returns a store almost immediately.[1][31] It does this by first setting up an internal ‘fallback’ store, which is a local store that serves as a placeholder, while the iCloud store is being asynchronously built from transaction logs and ubiquitous metadata. Changes made in the fallback store will be migrated to the iCloud store when it’s added to the coordinator. `Using local storage: 1` will be logged to the console when the fallback store is set up, and after the iCloud store is fully set up you should see `Using local storage: 0`. This means that the store is iCloud enabled, and you’ll begin seeing imports of content from iCloud via the `NSPersistentStoreDidImportUbiquitousContentChangesNotification`.

If your application is interested in when this transition between stores occurs, observe the new `NSPersistentStoreCoordinatorStoresWillChangeNotification` and/or `NSPersistentStoreCoordinatorStoresDidChangeNotification` (scoped to your coordinator in order to filter out internal notification noise) and inspect the `NSPersistentStoreUbiquitousTransitionTypeKey` value in its `userInfo` dictionary. The value will be an NSNumber boxing an `enum` value of type [`NSPersistentStoreUbiquitousTransitionType`][32], which will be `NSPersistentStoreUbiquitousTransitionTypeInitialImportCompleted` when this transition has occurred.

## Edge Cases

### Churn

One of the worst problems with testing iCloud on iOS 5 and 6 was when heavily used accounts would encounter ‘churn’ and become unusable. Syncing would completely stop, and even removing all ubiquitous data wouldn’t make it work. At [Lickability][33], we affectionately dubbed this state “f***ing the bucket.”

In iOS 7, there is a system-supported way to truly remove all ubiquitous content: `%2BremoveUbiquitousContentAndPersistentStoreAtURL:options:error:`. This method is great for testing, and may even be relevant for your application if the user gets into an inconsistent state and needs to remove all content and start over. There are a few caveats, though. First, this method is synchronous. Even while performing network operations and possibly taking a significant length of time, this method will not return until it is finished. Second, there should be absolutely no persistent store coordinators active when performing this operation. There are serious issues that can put your app into an unrecoverable state, and the official guidance is that all active persistent store coordinators should be completely deallocated beforehand.

### Account Changes

In iOS 5, when a user switched iCloud accounts or disabled iCloud, the data in the `NSPersistentStoreCoordinator` would completely vanish without letting the application know. In fact, the only way to check if an account had changed was to call `URLForUbiquityContainerIdentifier` on `NSFileManager` – a method that can set up the ubiquitous content folder as a side effect, and take seconds to return. In iOS 6, this was remedied with the introduction of `ubiquityIdentityToken` and its corresponding `NSUbiquityIdentityDidChangeNotification`, which is posted when there is a change to the ubiquity identity. This effectively notifies the app of account changes.

In iOS 7, however, this transition is even simpler. Account changes are handled by the Core Data framework, so as long as your application responds appropriately to both `NSPersistentStoreCoordinatorStoresWillChangeNotification` and `NSPersistentStoreCoordinatorStoresDidChangeNotification`, it will seamlessly transition when the user’s account changes. Inspecting the `NSPersistentStoreUbiquitousTransitionType`key in the `userInfo` dictionary of this notification will give more detail as to the type of transition.

The framework will manage one persistent store file per account inside the application sandbox, so if the user comes back to a previous account later, his or her data will still be available as it was left. Core Data now also manages the cleanup of these files when the user’s device is running low on disk space.

### iCloud On / Off Switch

Implementing a switch to enable or disable iCloud in your app is also much easier in iOS 7, although it probably isn’t necessary for most applications. Because the API now automatically creates a separate file structure when iCloud options are passed to the `NSPersistentStore` upon creation, we can have the same store URL and many of the same options between both local and iCloud stores. This means that switching from an iCloud store to a local store can be done by migrating the iCloud persistent store to the same URL with the same options, plus the `NSPersistentStoreRemoveUbiquitousMetadataOption`. This option will disassociate the ubiquitous metadata from the store, and is specifically designed for these kinds of migration or copying scenarios. Here’s a sample:


    - (void)migrateiCloudStoreToLocalStore {
        // assuming you only have one store.
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

Switching from a local store back to iCloud is just as easy; simply migrate with iCloud-enabled options, and add a persistent store with same options to the coordinator.

### External File References

External file references is a feature introduced for Core Data in iOS 5 that allows large binary data properties to be automatically stored outside the SQLite database on the file system. In our testing, when this occurs, iCloud does not always know how to resolve the relationship and can throw exceptions. If you plan to use iCloud syncing, consider unchecking this box in your iCloud entities:

![Core Data Modeler Checkbox][34]

### Model Versioning

If you are using iCloud, the contents of a store can only be migrated if the store is compatible with automatic [lightweight migration][35]. This means that Core Data must be able to infer the mapping and you cannot provide your own mapping model. Only simple changes to your model, like adding and renaming attributes, are supported. When considering whether to use Core Data syncing, be sure to think about how much your model may change in future versions of your app.

### Merge Conflicts

With any syncing system, conflicts between the server and the client are inevitable. Unlike [iCloud Data Document Syncing][36] APIs, iCloud Core Data integration does not specifically allow handling of conflicts between the local store and the transaction logs. That’s likely because Core Data already supports custom merge policies through subclassing of `NSMergePolicy`. To handle conflicts yourself, create a subclass of `NSMergePolicy` and override `resolveConflicts:error:` to determine what to do in the case of a conflict. Then, in your `NSManagedObjectContext` subclass, return an instance of your custom merge policy from the `mergePolicy` method.

### UI Updates

Many library-style applications display both collections of objects and detail views which display a single object. Views that are managed by `NSFetchedResultsController` instances will automatically update as the Core Data ubiquity system imports changes from the network. However, you should ensure that each detail view is properly observing changes to its object and keeping itself up to date. If you don’t, you risk accidentally showing stale data, or worse, saving edited values on top of newer changes from other peers.

## Testing

### Local Networks vs. Internet Syncing

The iCloud daemon can synchronize data across devices in one of two ways: on your local network or over the Internet. When the daemon detects that two devices, also known as peers, are on the same local area network, it will transfer the data over that presumably faster connection. If, however, the peers are on separate networks, the system will fall back to transferring transaction logs over the Internet. This is important to know, as you must test both cases heavily in development to make sure your application is functioning properly. In either scenario, syncing changes or transitioning from a fallback store to an iCloud store sometimes takes longer than expected, so if something isn’t working right away, try giving it time.

### iCloud in the Simulator

One of the most helpful changes to iCloud in iOS 7 is the ability to _finally_ [use iCloud in the iOS Simulator][37]. In previous versions, you could only test on a device, which limited how easy it was to observe the syncing process during development. Now, you can even sync data between your Mac and the simulator as two separate peers.

With the addition of the iCloud Debug Gauge in Xcode 5, you can see all files in your app’s ubiquity containers and examine their file transfer statuses, such as “Current,” “Excluded,” and “Stored in Cloud.” For more hardcore debugging, enable verbose console logging by passing `-com.apple.coredata.ubiquity.logLevel 3` as a launch argument or setting it as a user default. And consider installing the [iCloud Storage Debug Logging Profile][38] on iOS and the new [`ubcontrol`][39] command-line tool on OS X to provide high-quality bug reports to Apple. You can retrieve the logs that these tools generate from `~/Library/Logs/CrashReporter/MobileDevice/device-name/DiagnosticLogs` after syncing your device with iTunes.

However, iCloud Core Data is not fully supported in the simulator. When testing across devices and the simulator, it seems that iCloud Core Data on the simulator only uploads changes, and never pulls them back down. This is still a big improvement over needing separate test devices, and a nice convenience, but iCloud Core Data support on the iOS Simulator is definitely not fully baked yet.

## Moving On

With the clear improvements in both APIs and functionality in iOS 7, the fate of apps currently shipping iCloud Core Data on iOS 5 and iOS 6 is uncertain. Since the sync systems are so different from an API perspective (and, we’ve found out, from a functionality perspective), Apple’s recommendations haven’t been kind to apps that need legacy syncing. **Apple explicitly recommends [on the Developer Forums][40] that you sync absolutely no data between iOS 7 and any prior version of iOS**.

In fact, “at no time should your iOS 7 devices be allowed to communicate with iOS 6 peers. The iOS 6 peers will continue to exhibit bugs and issues that have been fixed in iOS 7 but in doing so will pollute the iCloud account.” The easiest way to guarantee this separation is by simply changing the `NSPersistentStoreUbiquitousContentNameKey` of your store, hopefully to comply with new guidance on periods within the name. This difference guarantees that the data from older versions is siloed from the new methods of syncing, and allows developers to make a completely clean break from old implementations.

## Shipping

Shipping an iCloud Core Data application is still risky. You need to perform tests for everything: account switching, running out of iCloud storage, many devices, model upgrades, and device restores. Although the iCloud Debug Gauge and [developer.icloud.com][41] can help, it’s still quite a leap of faith to ship an app relying on a service that’s completely out of your control.

As Brent Simmons [pointed out][42], shipping an app with any kind of iCloud syncing can be limiting, so be sure to understand the costs up front. Apps like [Day One][43] and [1Password][44] have opted to let users sync their data with either iCloud or Dropbox. For many users, nothing beats the simplicity of a single account, but some power users still demand full control over their data. And for developers, maintaining disparate [database syncing systems][45] can be quite taxing during development and testing.

## Bugs

Once you’ve tested and shipped an iCloud Core Data application, you will likely encounter bugs in the framework. The best way to report these bugs to Apple is to file detailed [Radars][46], which contain the following information:

  1. Complete steps to reproduce.
  2. The output to the console with [iCloud debug logging][47] on level three and the iCloud debugging profile installed.
  3. The full contents of the ubiquity container as a zip archive.

## Conclusion

It’s no secret that iCloud Core Data was fundamentally broken in iOS 5 and 6, with an Apple employee acknowledging that “there were significant stability and long term reliability issues with iOS 5 / 6 when using Core Data %2B iCloud…The way forward is iOS 7 only, really really really really.” High-profile developers like [Agile Tortoise][48] and [Realmac Software][49] are now comfortable trusting the iCloud Core Data integration in their applications, and with enough [consideration][50] and testing, you should be too.

_Special thanks to Andrew Harrison, Greg Pierce, and Paul Bruneau for their help with this article._

* * *

  1. In previous OS versions, this method wouldn’t return until iCloud data was downloaded and merged into the persistent store. This would cause significant delays, meaning that any calls to the method would need to be dispatched to a background queue. Thankfully, this is no longer necessary.

[↩][51]




* * *

[More articles in issue #10][52]

  * [Privacy policy][53]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-10/index.html
   [5]: https://twitter.com/mb
   [6]: https://twitter.com/bcapps
   [7]: http://en.wikipedia.org/wiki/ICloud
   [8]: http://www.objc.io/issue-4/core-data-overview.html
   [9]: http://adcdownload.apple.com//videos/wwdc_2011__hd/session_303__whats_new_in_core_data_on_ios.m4v
   [10]: http://adcdownload.apple.com//videos/wwdc_2012__hd/session_227__using_icloud_with_core_data.mov
   [11]: https://developer.apple.com/library/mac/documentation/General/Conceptual/MOSXAppProgrammingGuide/CoreAppDesign/CoreAppDesign.html#//apple_ref/doc/uid/TP40010543-CH3-SW3
   [12]: http://www.macworld.com/article/1167742/developers_dish_on_iclouds_challenges.html
   [13]: http://blog.caffeine.lu/problems-with-core-data-icloud-storage.html
   [14]: http://www.jumsoft.com/2013/01/response-to-sync-issues/
   [15]: http://simperium.com
   [16]: https://github.com/nothirst/TICoreDataSync
   [17]: http://www.wasabisync.com
   [18]: http://arstechnica.com/apple/2013/03/frustrated-with-icloud-apples-developer-community-speaks-up-en-masse/
   [19]: http://www.theverge.com/2013/3/26/4148628/why-doesnt-icloud-just-work
   [20]: http://about.me/nickgillett
   [21]: http://asciiwwdc.com/2013/sessions/207
   [22]: https://developer.apple.com/library/mac/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html
   [23]: https://developer.apple.com/xcode/
   [24]: http://en.wikipedia.org/wiki/Multi-master_replication
   [25]: https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/nsfilemanager_class/Reference/Reference.html#//apple_ref/doc/uid/20000305-SW81
   [26]: http://mentalfaculty.tumblr.com/post/23788055417/under-the-sheets-with-icloud-and-core-data-seeding
   [27]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSPersistentStoreCoordinator_Class/NSPersistentStoreCoordinator.html#//apple_ref/doc/constant_group/Store_Options
   [28]: https://developer.apple.com/library/ios/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSPersistentStoreCoordinator_Class/NSPersistentStoreCoordinator.html#//apple_ref/occ/instm/NSPersistentStoreCoordinator/addPersistentStoreWithType:configuration:URL:options:error:
   [29]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSPersistentStoreCoordinator_Class/NSPersistentStoreCoordinator.html#//apple_ref/doc/uid/TP30001180-BBCFDEGA
   [30]: https://devforums.apple.com/message/828503#828503
   [31]: http://www.objc.io#fn%3A1
   [32]: https://developer.apple.com/library/ios/documentation/cocoa/Reference/CoreDataFramework/Classes/NSPersistentStoreCoordinator_Class/NSPersistentStoreCoordinator.html#//apple_ref/c/tdef/NSPersistentStoreUbiquitousTransitionType
   [33]: http://lickability.com
   [34]: http://cloud.mttb.me/UBrx/image.png
   [35]: https://developer.apple.com/library/ios/documentation/cocoa/conceptual/CoreDataVersioning/Articles/vmLightweightMigration.html
   [36]: https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesigningForDocumentsIniCloud.html#//apple_ref/doc/uid/TP40012094-CH2-SW1
   [37]: https://developer.apple.com/library/mac/documentation/General/Conceptual/iCloudDesignGuide/Chapters/TestingandDebuggingforiCloud.html
   [38]: http://developer.apple.com/downloads
   [39]: https://developer.apple.com/library/mac/documentation/Darwin/Reference/Manpages/man1/ubcontrol.1.html
   [40]: https://devforums.apple.com/thread/199983?start=0&tstart=0*
   [41]: http://developer.icloud.com
   [42]: http://inessential.com/2013/03/27/why_developers_shouldnt_use_icloud_sy
   [43]: http://dayoneapp.com
   [44]: https://agilebits.com/onepassword
   [45]: https://www.dropbox.com/developers/datastore
   [46]: http://bugreport.apple.com
   [47]: http://www.freelancemadscience.com/fmslabs_blog/2012/3/28/debug-settings-for-core-data-and-icloud.html
   [48]: http://agiletortoise.com
   [49]: http://realmacsoftware.com
   [50]: https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/Introduction.html
   [51]: http://www.objc.io#fnref%3A1
   [52]: http://www.objc.io/issue-10
   [53]: http://www.objc.io/privacy.html
