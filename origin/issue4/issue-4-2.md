[Source](http://www.objc.io/issue-4/full-core-data-application.html "Permalink to A Complete Core Data Application - Core Data - objc.io issue #4 ")

# A Complete Core Data Application - Core Data - objc.io issue #4 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# A Complete Core Data Application

[Issue #4 Core Data][4], September 2013

By [Chris Eidhof][5]

In this article, we will build a small but complete Core Data backed application. The application allows you to create nested lists; each list item can have a sub-list, allowing you to create very deep hierarchies of items. Instead of using the Xcode template for Core Data, we will build our stack by hand, in order to fully understand what’s going on. The example code for this application is on [GitHub][6].

### How Will We Build It?

First, we will create a `PersistentStack` object that, given a Core Data Model and a filename, returns a managed object context. Then we will build our Core Data Model. Next, we will create a simple table view controller that shows the root list of items using a fetched results controller, and add interaction step-by-step, by adding items, navigating to sub-items, deleting items, and adding undo support.

## Set Up the Stack

We will create a managed object context for the main queue. In older code, you might see [`[NSManagedObjectContext alloc] init]`. These days, you should use the `initWithConcurrencyType:` initializer to make it explicit that you’re using the queue-based concurrency model:


    - (void)setupManagedObjectContext
    {
        self.managedObjectContext =
             [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        self.managedObjectContext.persistentStoreCoordinator =
            [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        NSError* error;
        [self.managedObjectContext.persistentStoreCoordinator
             addPersistentStoreWithType:NSSQLiteStoreType
                          configuration:nil
                                    URL:self.storeURL
                                options:nil
                                  error:&error];
        if (error) {
            NSLog(@"error: %@", error);
        }
        self.managedObjectContext.undoManager = [[NSUndoManager alloc] init];
    }

It’s important to check the error, because this will probably fail a lot during development. When you change your data model, Core Data detects this and will not continue. You can also pass in options to instruct Core Data about what to do in this case, which Martin explains thoroughly in his article about [migrations][7]. Note that the last line adds an undo manager; we will need this later. On iOS, you need to explicitly add an undo manager, whereas on Mac it is there by default.

This code creates a really simple Core Data Stack: one managed object context, which has a persistent store coordinator, which has one persistent store. [More complicated setups][8] are possible; the most common is to have multiple managed object contexts (each on a separate queue).

## Creating a Model

Creating a model is simple, as we just add a new file to our project, choosing the Data Model template (under Core Data). This model file will get compiled to a file with extension `.momd`, which we will load at runtime to create a `NSManagedObjectModel`, which is needed for the persistent store. The source of the model is simple XML, and in our experience, you typically won’t have any merge problems when checking it into source control. It is also possible to create a managed object model in code, if you prefer that.

Once you create the model, you can add an `Item` entity with two attributes: `title`, which is a string, and `order`, which is an integer. Then, you add two relationships: `parent`, which relates an item to its parent, and `children`, which is a to-many relationship. Set the relationships as the inverse of one another, which means that if you set `a`’s parent to be `b`, then `b` will have `a` in its children automatically.

Normally, you could even use ordered relationships, and leave out the `order` property entirely. However, they don’t play together nicely with fetched results controllers (which we will use later on). We would either need to reimplement part of fetched results controllers, or reimplement the ordering, and we chose the latter.

Now, choose _Editor > Create NSManagedObject subclass…_ from the menu, and create a subclass of `NSManagedObject` that is tied to this entity. This creates two files: `Item.h` and `Item.m`. There is an extra category in the header file, which we will delete immediately (it is there for legacy reasons).

### Create a `Store` Class

For our model, we will create a root node that is the start of our item tree. We need a place to create this root node and to find it later. Therefore, we create a simple `Store` class, that does exactly this. It has a managed object context, and one method `rootItem`. In our app delegate, we will find this root item at launch and pass it to our root view controller. As an optimization, you can store the object id of the item in the user defaults, in order to look it up even faster:


    - (Item*)rootItem
    {
        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Item"];
        request.predicate = [NSPredicate predicateWithFormat:@"parent = %@", nil];
        NSArray* objects = [self.managedObjectContext executeFetchRequest:request error:NULL];
        Item* rootItem = [objects lastObject];
        if (rootItem == nil) {
            rootItem = [Item insertItemWithTitle:nil
                                          parent:nil
                          inManagedObjectContext:self.managedObjectContext];
        }
        return rootItem;
    }

Adding an item is mostly straightforward. However, we have to set the `order` property to be larger than any of the existing items with that parent. The invariant we will use is that the first child has an `order` of 0, and every subsequent child has an `order` value that is 1 higher. We create a custom method on the `Item` class where we put the logic:


    %2B (instancetype)insertItemWithTitle:(NSString*)title
                                 parent:(Item*)parent
                 inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
    {
        NSUInteger order = parent.numberOfChildren;
        Item* item = [NSEntityDescription insertNewObjectForEntityForName:self.entityName
                                                   inManagedObjectContext:managedObjectContext];
        item.title = title;
        item.parent = parent;
        item.order = @(order);
        return item;
    }

The number of children is a very simple method:


    - (NSUInteger)numberOfChildren
    {
        return self.children.count;
    }

To support automatic updates to our table view, we will use a fetched results controller. A fetched results controller is an object that can manage a fetch request with a big number of items and is the perfect Core Data companion to a table view, as we will see in the next section:


    - (NSFetchedResultsController*)childrenFetchedResultsController
    {
        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:[self.class entityName]];
        request.predicate = [NSPredicate predicateWithFormat:@"parent = %@", self];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];
        return [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                   managedObjectContext:self.managedObjectContext
                                                     sectionNameKeyPath:nil
                                                              cacheName:nil];
    }

## Add a Table-View Backed by Fetched Results Controller

Our next step is to create the root view controller: a table view, which gets its data from an `NSFetchedResultsController`. The fetched results controller manages your fetch request, and if you assign a delegate, it also notifies you of any changes in the managed object context. In practice, this means that if you implement the delegate methods, you can automatically update your table view when relevant changes happen in the data model. For example, if you synchronize in a background thread, and then you store the changes in the database, your table view will update automatically.

### Creating the Table View’s Data Source

In our article on [lighter view controllers][9], we demonstrated how to separate out the data source of a table view. We will do exactly the same for a fetched results controller; we create a separate class `FetchedResultsControllerDataSource` that acts as a table view’s data source, and by listening to the fetched results controller, updates the table view automatically.

We initialize the object with a table view, and the initializer looks like this:


    - (id)initWithTableView:(UITableView*)tableView
    {
        self = [super init];
        if (self) {
            self.tableView = tableView;
            self.tableView.dataSource = self;
        }
        return self;
    }

When we set the fetch results controller, we have to make ourselves the delegate, and perform the initial fetch. It is easy to forget the `performFetch:` call, and you will get no results (and no errors):


    - (void)setFetchedResultsController:(NSFetchedResultsController*)fetchedResultsController
    {
        _fetchedResultsController = fetchedResultsController;
        fetchedResultsController.delegate = self;
        [fetchedResultsController performFetch:NULL];
    }

Because our class implements the `UITableViewDataSource` protocol, we need to implement some methods for that. In these two methods we just ask the fetched results controller for the required information:


    - (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
    {
        return self.fetchedResultsController.sections.count;
    }

    - (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex
    {
        id section = self.fetchedResultsController.sections[sectionIndex];
        return section.numberOfObjects;
    }

However, when we need to create cells, it requires some simple steps: we ask the fetched results controller for the right object, we dequeue a cell from the table view, and then we tell our delegate (which will be a view controller) to configure that cell with the object. Now, we have a nice separation of concerns, as the view controller only has to care about updating the cell with the model object:


    - (UITableViewCell*)tableView:(UITableView*)tableView
            cellForRowAtIndexPath:(NSIndexPath*)indexPath
    {
        id object = [self.fetchedResultsController objectAtIndexPath:indexPath];
        id cell = [tableView dequeueReusableCellWithIdentifier:self.reuseIdentifier
                                                 forIndexPath:indexPath];
        [self.delegate configureCell:cell withObject:object];
        return cell;
    }

### Creating the Table View Controller

Now, we can create a view controller that displays a list of items using the class we just created. In the example app, we created a Storyboard, and added a navigation controller with a table view controller. This automatically sets the view controller as the data source, which is not what we want. Therefore, in our `viewDidLoad`, we do the following:


    fetchedResultsControllerDataSource =
        [[FetchedResultsControllerDataSource alloc] initWithTableView:self.tableView];
    self.fetchedResultsControllerDataSource.fetchedResultsController =
        self.parent.childrenFetchedResultsController;
    fetchedResultsControllerDataSource.delegate = self;
    fetchedResultsControllerDataSource.reuseIdentifier = @"Cell";

In the initializer of the fetched results controller data source, the table view’s data source gets set. The reuse identifier matches the one in the Storyboard. Now, we have to implement the delegate method:


    - (void)configureCell:(id)theCell withObject:(id)object
    {
        UITableViewCell* cell = theCell;
        Item* item = object;
        cell.textLabel.text = item.title;
    }

Of course, you could do a lot more than just setting the text label, but you get the point. Now we have pretty much everything in place for showing data, but as there is no way to add anything yet, it looks pretty empty.

## Adding Interactivity

We will add a couple of ways of interacting with the data. First, we will make it possible to add items. Then we will implement the fetched results controller’s delegate methods to update the table view, and add support for deletion and undo.

### Adding Items

To add items, we steal the interaction design from [Clear][10], which is high on my list of most beautiful apps. We add a text field as the table view’s header, and modify the content inset of the table view to make sure it stays hidden by default, as explained in Joe’s [scroll view article][11]. As always, the full code is on github, but here’s the relevant call to inserting the item, in `textFieldShouldReturn`:


    [Item insertItemWithTitle:title
                       parent:self.parent
       inManagedObjectContext:self.parent.managedObjectContext];
    textField.text = @"";
    [textField resignFirstResponder];

### Listening to Changes

The next step is making sure that your table view inserts a row for the newly created item. There are several ways to go about this, but we’ll use the fetched results controller’s delegate method:


    - (void)controller:(NSFetchedResultsController*)controller
       didChangeObject:(id)anObject
           atIndexPath:(NSIndexPath*)indexPath
         forChangeType:(NSFetchedResultsChangeType)type
          newIndexPath:(NSIndexPath*)newIndexPath
    {
        if (type == NSFetchedResultsChangeInsert) {
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }

The fetched results controller also calls these methods for deletions, changes, and moves (we’ll implement that later). If you have multiple changes happening at the same time, you can implement two more methods so that the table view will animate everything at the same time. For simple single-item insertions and deletions, it doesn’t make a difference, but if you choose to implement syncing at some time, it makes everything a lot prettier:


    - (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
    {
        [self.tableView beginUpdates];
    }

    - (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
    {
        [self.tableView endUpdates];
    }

#### Using a Collection View

It’s worth noting that fetched results controllers are not at all limited to table views; you can use them with any kind of view. Because they are index-path-based, they also work really well with collection views, although you unfortunately have to jump through some minor hoops in order to make it work perfectly, as a collection view doesn’t have a `beginUpdates` and `endUpdates` method, but rather a single method `performBatchUpdates`. To deal with this, you can collect all the updates you get, and then in the `controllerDidChangeContent`, perform them all inside the block. Ash Furrow wrote an example of [how you could do this][12].

#### Implementing Your Own Fetched Results Controller

You don’t have to use `NSFetchedResultsController`. In fact, in a lot of cases it might make sense to create a similar class that works specifically for your application. What you can do is subscribe to the `NSManagedObjectContextObjectsDidChangeNotification`. You then get a notification, and the `userInfo` dictionary will contain a list of the changed objects, inserted objects, and deleted objects. Then you can process them in any way you want.

### Passing Model Objects Around

Now that we can add and list items, it’s time to make sure we can make sub-lists. In the Storyboard, you can create a segue by dragging from a cell to the view controller. It’s wise to give the segue a name, so that it can be identified if we ever have multiple segues originating from the same view controller.

My pattern for dealing with segues looks like this: first, you try to identify which segue it is, and for each segue you pull out a separate method that prepares the destination view controller:


    - (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
    {
        [super prepareForSegue:segue sender:sender];
        if ([segue.identifier isEqualToString:selectItemSegue]) {
            [self presentSubItemViewController:segue.destinationViewController];
        }
    }

    - (void)presentSubItemViewController:(ItemViewController*)subItemViewController
    {
        Item* item = [self.fetchedResultsControllerDataSource selectedItem];
        subItemViewController.parent = item;
    }

The only thing the child view controller needs is the item. From the item, it can also get to the managed object context. We get the selected item from our data source (which looks up the table view’s selected item index and fetches the correct item from the fetched results controller). It’s as simple as that.

One pattern that’s unfortunately very common is having the managed object context as a property on the app delegate, and then always accessing it from everywhere. This is a bad idea. If you ever want to use a different managed object context for a certain part of your view controller hierarchy, this will be very hard to refactor, and additionally, your code will be a lot more difficult to test.

Now, try adding an item in the sub-list, and you will probably get a nice crash. This is because we now have two fetched results controllers, one for the topmost view controller, but also one for the root view controller. The latter one tries to update its table view, which is offscreen, and everything crashes. The solution is to tell our data source to stop listening to the fetched results controller delegate methods:


    - (void)viewWillAppear:(BOOL)animated
    {
        [super viewWillAppear:animated];
        self.fetchedResultsControllerDataSource.paused = NO;
    }

    - (void)viewWillDisappear:(BOOL)animated
    {
        [super viewWillDisappear:animated];
        self.fetchedResultsControllerDataSource.paused = YES;
    }

One way to implement this inside the data source is setting the fetched results controller’s delegate to nil, so that no updates are received any longer. We then need to add it after we come out of `paused` state:


    - (void)setPaused:(BOOL)paused
    {
        _paused = paused;
        if (paused) {
            self.fetchedResultsController.delegate = nil;
        } else {
            self.fetchedResultsController.delegate = self;
            [self.fetchedResultsController performFetch:NULL];
            [self.tableView reloadData];
        }
    }

The `performFetch` will then make sure your data source is up to date. Of course, a nicer implementation would be to not set the delegate to nil, but instead keep a list of the changes that happened while in paused state, and update the table view accordingly after you get out of paused state.

### Deletion

To support deletion, we need to take a few steps. First, we need to convince the table view that we support deletion, and second, we need to delete the object from core data and make sure our order invariant stays correct.

To allow for swipe to delete, we need to implement two methods in the data source:


         - (BOOL)tableView:(UITableView*)tableView
     canEditRowAtIndexPath:(NSIndexPath*)indexPath
     {
         return YES;
     }

      - (void)tableView:(UITableView *)tableView
     commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
      forRowAtIndexPath:(NSIndexPath *)indexPath {
         if (editingStyle == UITableViewCellEditingStyleDelete) {
             id object = [self.fetchedResultsController objectAtIndexPath:indexPath]
             [self.delegate deleteObject:object];
         }
     }

Rather than deleting immediately, we tell our delegate (the view controller) to delete the object. That way, we don’t have to share the store object with our data source (the data source should be reusable across projects), and we keep the flexibility to do any custom actions. The view controller simply calls `deleteObject:` on the managed object context.

However, there are two important problems to solve: what do we do with the children of the item that we delete, and how do we enforce our order variant? Luckily, propagating deletion is easy: in our data model, we can choose _Cascade_ as the delete rule for the children relationship.

For enforcing our order variant, we can override the `prepareForDeletion` method, and update all the siblings with a higher `order`:


    - (void)prepareForDeletion
    {
        NSSet* siblings = self.parent.children;
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"order > %@", self.order];
        NSSet* siblingsAfterSelf = [siblings filteredSetUsingPredicate:predicate];
        [siblingsAfterSelf enumerateObjectsUsingBlock:^(Item* sibling, BOOL* stop)
        {
            sibling.order = @(sibling.order.integerValue - 1);
        }];
    }

Now we’re almost there. We can interact with table view cells and delete the model object. The final step is to implement the necessary code to delete the table view cells once the model objects get deleted. In our data source’s `controller:didChangeObject:...` method we add another if clause:


    ...
    else if (type == NSFetchedResultsChangeDelete) {
        [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }

### Add Undo Support

One of the nice things about Core Data is that it comes with integrated undo support. We will add _the shake to undo_ feature, and a first step is telling the application that we can do this:


    application.applicationSupportsShakeToEdit = YES;

Now, whenever a shake is triggered, the application will ask the first responder for its undo manager, and perform an undo. In [last month’s article][13], we saw that a view controller is also in the responder chain, and this is exactly what we’ll use. In our view controller, we override the following two methods from the `UIResponder` class:


    - (BOOL)canBecomeFirstResponder {
        return YES;
    }

    - (NSUndoManager*)undoManager
    {
        return self.managedObjectContext.undoManager;
    }

Now, when a shake gesture happens, the managed object context’s undo manager will get an undo message, and undo the last change. Remember, on iOS, a managed object context doesn’t have an undo manager by default, (whereas on Mac, a newly created managed object context does have an undo manager), so we created that in the setup of the persistent stack:


    self.managedObjectContext.undoManager = [[NSUndoManager alloc] init];

And that’s almost all there is to it. Now, when you shake, you get the default iOS alert view with two buttons: one for undoing, and one for canceling. One nice feature of Core Data is that it automatically groups changes. For example, the `addItem:parent` will record as one undo action. For the deletion, it’s the same.

To make managing the undos a bit easier for the user, we can also name the actions, and change the first lines of `textFieldShouldReturn:` to this:


    NSString* title = textField.text;
    NSString* actionName = [NSString stringWithFormat:
        NSLocalizedString(@"add item \"%@\"", @"Undo action name of add item"), title];
    [self.undoManager setActionName:actionName];
    [self.store addItem:title parent:nil];

Now, when the user shakes, he or she gets a bit more context than just the generic label “Undo”.

### Editing

Editing is currently not supported in the example application, but is a matter of just changing properties on the objects. For example, to change the title of an item, just set the `title` property and you’re done. To change the parent of an item `foo`, just set the `parent` property to a new value `bar`, and everything gets updated: `bar` now has `foo` in its `children`, and because we use fetched results controllers the user interface also updates automatically.

### Reordering

Reordering cells is also not possible in the sample application, but is mostly straightforward to implement. Yet, there is one caveat: if you allow user-driven reordering, you will update the `order` property in the model, and then get a delegate call from the fetched results controller (which you should ignore, because the cells have already moved). This is explained in the [`NSFetchedResultsControllerDelegate` documentation][14]

## Saving

Saving is as easy as calling `save` on the managed object context. Because we don’t access that directly, we do it in the store. The only hard part is when to save. Apple’s sample code does it in `applicationWillTerminate:`, but depending on your use case it could also be in `applicationDidEnterBackground:` or even while your app is running.

## Discussion

In writing this article and the example application, I made an initial mistake: I chose to not have an empty root item, but instead let all the user-created items at root level have a `nil` parent. This caused a lot of trouble: because the `parent` item in the view controller could be `nil`, we needed to pass the store (or the managed object context) around to each child view controller. Also, enforcing the order invariant was harder, as we needed a fetch request to find an item’s siblings, thus forcing Core Data to go back to disk. Unfortunately, these problems were not immediately clear when writing the code, and some only became clear when writing the tests. When rewriting the code, I was able to move almost all code from the `Store` class into the `Item` class, and everything became a lot cleaner.




* * *

[More articles in issue #4][15]

  * [Privacy policy][16]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-4/index.html
   [5]: http://twitter.com/chriseidhof
   [6]: https://github.com/objcio/issue-4-full-core-data-application
   [7]: http://www.objc.io/issue-4/core-data-migration.html
   [8]: http://www.objc.io/issue-4/core-data-overview.html#complicated-stacks
   [9]: http://www.objc.io/issue-1/lighter-view-controllers.html
   [10]: http://www.realmacsoftware.com/clear/
   [11]: http://www.objc.io/issue-3/scroll-view.html
   [12]: https://github.com/AshFurrow/UICollectionView-NSFetchedResultsController
   [13]: http://www.objc.io/issue-3/custom-controls.html
   [14]: https://developer.apple.com/library/ios/documentation/CoreData/Reference/NSFetchedResultsControllerDelegate_Protocol/Reference/Reference.html#//apple_ref/doc/uid/TP40008228-CH1-SW14
   [15]: http://www.objc.io/issue-4
   [16]: http://www.objc.io/privacy.html
