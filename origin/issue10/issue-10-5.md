[Source](http://www.objc.io/issue-10/networked-core-data-application.html "Permalink to A Networked Core Data Application - Syncing Data - objc.io issue #10 ")

# A Networked Core Data Application - Syncing Data - objc.io issue #10 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# A Networked Core Data Application

[Issue #10 Syncing Data][4], March 2014

By [Chris Eidhof][5]

One of the things almost every app developer has to do in his or her life is import things from a web service into Core Data. This article describes how to do that. Everything we discuss here has been described before in previous articles, and by Apple in its documentation. However, it is still instructive to have a look at how to do from start to finish.

The full source of the app is [available on GitHub][6].

## Plan

We will build a small read-only app that shows a list of all the CocoaPods specifications. They are displayed in a table view, and all the pod specifications are fetched from a web service that returns them as JSON objects, in a paginated fashion.

We proceed as follows:

  1. First, we create a `PodsWebservice` class that fetches all the specs from the web service.
  2. Next, we create an `Importer` object that takes the specs, and imports them into Core Data.
  3. Finally, we show how to make the import work on a background thread.

## Getting Objects from the Web Service

First, it is nice to create a separate class that imports things from the web service. We have written a [small example web server][7] that takes the CocoaPods specs repository and generates JSON from that; getting the URL `/specs` returns a list of pod specifications in alphabetic order. The web service is paginated, so we need to request each page separately. An example response looks like this:


    {
      "number_of_pages": 559,
      "result": [{
        "authors": { "Ash Furrow": "ash@ashfurrow.com" },
        "homepage": "https://github.com/500px/500px-iOS-api",
        "license": "MIT",
        "name": "500px-iOS-api",
      ...

We want to create a class that has only one method, `fetchAllPods:`, that takes a callback block, which gets called for every page. It could also have been done using delegation; why we chose to have a block is something you can read in the article on [communication patterns][8]:


    @interface PodsWebservice : NSObject
    - (void)fetchAllPods:(void (^)(NSArray *pods))callback;
    @end

This callback gets called for every page. Implementing this method is easy. We create a helper method, ` fetchAllPods:page:`, that fetches all pods for a page, and then calls itself once it has loaded a page. Note that, for brevity, we’ve left out the error handling here, but if you look at the full project on GitHub, you’ll see that we added it there. It’s important to always check for errors, and at least log them so that you can quickly see if something isn’t working as expected:


    - (void)fetchAllPods:(void (^)(NSArray *pods))callback page:(NSUInteger)page
    {
        NSString *urlString = [NSString stringWithFormat:@"http://localhost:4567/specs?page=%d", page];
        NSURL *url = [NSURL URLWithString:urlString];
        [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:
          ^(NSData *data, NSURLResponse *response, NSError *error) {
            id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            if ([result isKindOfClass:[NSDictionary class]]) {
                NSArray *pods = result[@"result"];
                callback(pods);
                NSNumber* numberOfPages = result[@"number_of_pages"];
                NSUInteger nextPage = page %2B 1;
                if (nextPage < numberOfPages.unsignedIntegerValue) {
                    [self fetchAllPods:callback page:nextPage];
                }
            }
        }] resume];
    }

That’s all there is to it. We parse the JSON, do some very rough checking (verifying that the result is a dictionary), and then call our callback.

## Putting Objects into Core Data

Now we can load the JSON results into our Core Data store. To separate things, we create an `Importer` object that calls the web service and creates or updates objects. It’s nice to have this in a separate class, because that way our web service and the Core Data parts are completely decoupled. If we would ever want to feed the store with a different web service, or reuse the web service somewhere, we now don’t have to manually detangle the two. Also, not having this logic in a view controller makes it easier to reuse the components in a different app.

Our importer has two methods:


    @interface Importer : NSObject
    - (id)initWithContext:(NSManagedObjectContext *)context
               webservice:(PodsWebservice *)webservice;
    - (void)import;
    @end

Injecting the context into the object via the constructor is a powerful trick. When writing tests, we could easily inject a different context. The same holds for the web service: we could easily have a different object mock the web service.

The `import` method is the one that has the logic. We call the `fetchAllPods:` method, and for each batch of pod specifications, we import them into the context. By wrapping the logic into a `performBlock:`, the context makes sure that everything happens on the correct thread. We then iterate over the specs, and for each one, we generate a unique identifier (this can be anything that uniquely determines a model object, as also explained in [Drew’s article][9]). We then try to find the model object, or create it if it doesn’t exist. The method `loadFromDictionary:` takes the JSON dictionary and updates the model object with the values contained in the dictionary:


    - (void)import
    {
        [self.webservice fetchAllPods:^(NSArray *pods)
        {
            [self.context performBlock:^
            {
                for(NSDictionary *podSpec in pods) {
                    NSString *identifier = [podSpec[@"name"] stringByAppendingString:podSpec[@"version"]];
                    Pod *pod = [Pod findOrCreatePodWithIdentifier:identifier inContext:self.context];
                    [pod loadFromDictionary:podSpec];
                }
            }];
        }];
    }

There are some more things to note about the code above. First of all, the find-or-create method is very inefficient. In production code, you would batch up the pods and find all of them at the same time, as explained in the section [Efficiently Importing Data][10] in the Core Data Programming Guide.

Second, we created the `loadFromDictionary:` directly in the `Pod` class (which is the managed object subclass). This means that now our model object knows about the web service. In real code, we would probably put this into a category so that the two are nicely separated. For this example, it doesn’t matter.

## Creating a Separate Background Stack

In writing the code above, we started by having everything on the main managed object context. Our app displays a list of all the pods in a table view controller, using a fetched results controller. The fetched results controller automatically updates the data model when things change in the managed object context. However, also having the importing being done on the main managed object context is not optimal. The main thread might get blocked, and the UI unresponsive. Most of the time, the work being done on the main thread is so minimal that it is hardly noticeable. If this is the case in your situation, it might be fine to leave it like that. However, if we put in some extra effort, we can make the import happen in a background thread.

In the WWDC sessions and in the section [Concurrency with Core Data][11] of the Core Data Programming Guide, Apple recommends two options for concurrent Core Data. Both involve separate managed object contexts, and they can either share the same persistent store coordinator, or not. Having separate persistent store coordinators provides the best performance when doing a lot of changes, because the only locks needed are on the sqlite level. Having a shared persistent store coordinator also means having a shared cache. When you’re not making a lot of changes, this can be much faster. So, depending on your use case, you should measure what’s best and then choose whether you want a shared persistent store coordinator or not. In the case where the main context is read-only (such as in the app described so far), no locking is required at all, because sqlite in iOS7 has write-ahead logging enabled and supports multiple readers and a single writer. However, for our demonstration purposes, we’ll use the approach with completely separate stacks. To set up a managed object context, we use the following code:


    - (NSManagedObjectContext *)setupManagedObjectContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
    {
        NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:concurrencyType];
        managedObjectContext.persistentStoreCoordinator =
                [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        NSError* error;
        [managedObjectContext.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                      configuration:nil
                                                                                URL:self.storeURL
                                                                            options:nil
                                                                              error:&error];
        if (error) {
            NSLog(@"error: %@", error.localizedDescription);
        }
        return managedObjectContext;
    }

Then we call this method twice — once for the main managed object context, and once for the background managed object context:


    self.managedObjectContext = [self setupManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType];
    self.backgroundManagedObjectContext = [self setupManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType];

Note that passing in the parameter `NSPrivateQueueConcurrencyType` tells Core Data to create a separate queue, which ensures that the background managed object context operations happen on a separate thread.

Now there’s only one more step left: whenever the background context is saved, we need to update the main thread. We described how to do this in a [previous article][12] in issue #2. We register to get a notification whenever a context saves, and if it’s the background context, call the method `mergeChangesFromContextDidSaveNotification:`. That’s all there is to it:


    [[NSNotificationCenter defaultCenter]
            addObserverForName:NSManagedObjectContextDidSaveNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification* note) {
        NSManagedObjectContext *moc = self.managedObjectContext;
        if (note.object != moc) {
            [moc performBlock:^(){
                [moc mergeChangesFromContextDidSaveNotification:note];
            }];
        }
     }];

Again, there is a small caveat: the `mergeChangesFromContextDidSaveNotification:` happens inside the `performBlock:`. In our case, the `moc` is the main managed object context, and hence, this will block the main thread.

Note that your UI (even if it’s read-only) has to be able to deal with changes to objects, or even deletions. Brent Simmons recently wrote about [why to use a custom notification for deletion][13] and [deleting objects in Core Data][14]. These explanations show how to deal with the fact that, if you’re displaying an object in your UI, changes might happen or the object might get deleted as you’re displaying it.

## Implementing Writes from the UI

You might think the above looks very simple, and that’s because the only writing is done in the background thread. In our current application, we don’t deal with merging in the other direction; there are no changes coming from the main managed object context. In order to add this, you could take multiple strategies. This is best described in [Drew’s article][9].

Depending on your requirements, one very simple pattern that might work is this: whenever the user changes something in the UI, you don’t change the managed object context. Instead, you call the web service. If this succeeds, you get the diff from the web service, and update your background context. The changes will then propagate to the main context. There are two drawbacks with this: it might take a while before the user sees the changes in the UI, and if the user is not online, he or she can’t change anything. In [Florian’s article][15], we describe how we used a different strategy that also works offline.

If you’re dealing with merges, you will also need to define a merge policy. This is again something very specific to your use case. You may want to throw an error if a merge fails, or always give priority to one managed object context. The [NSMergePolicy][16] class describes the possibilities.

## Conclusion

We’ve seen how to implement a simple read-only application that imports a large set of data from a web service into Core Data. By using a background managed object context, we’ve built an app that doesn’t block the main UI (except when merging the changes).




* * *

[More articles in issue #10][17]

  * [Privacy policy][18]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-10/index.html
   [5]: https://twitter.com/chriseidhof
   [6]: https://github.com/objcio/issue-10-core-data-network-application
   [7]: https://gist.github.com/chriseidhof/725946f0d02b17ced209
   [8]: http://www.objc.io/issue-7/communication-patterns.html
   [9]: http://www.objc.io/issue-10/data-synchronization.html
   [10]: http://www.objc.io/issue-4/importing-large-data-sets-into-core-data.html
   [11]: https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreData/Articles/cdConcurrency.html
   [12]: http://www.objc.io/issue-2/common-background-practices.html
   [13]: http://inessential.com/2014/02/25/why_use_a_custom_notification_for_note_d
   [14]: http://inessential.com/2014/02/25/more_about_deleting_objects_in_core_data
   [15]: http://www.objc.io/issue-10/sync-case-study.html
   [16]: https://developer.apple.com/library/mac/documentation/CoreData/Reference/NSMergePolicy_Class/Reference/Reference.html
   [17]: http://www.objc.io/issue-10
   [18]: http://www.objc.io/privacy.html
