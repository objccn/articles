在这篇文章中，我们将建立一个小型但却全面支持 Core Data 的应用。此应用允许你创建嵌套的列表；每个列表的 item 都可以有子列表，这将允许你创建非常深层次的 items。为了让大家完整的了解发生了什么，我们将通过使用手动创建堆栈的方式来代替 Xcode 中 Core Data 的模板。这个应用的代码放到了 [GitHub](https://github.com/objcio/issue-4-full-core-data-application) 上。

### 我们将怎么建立？

首先，我们创建一个 PersistentStack 对象，为其提供一个 Core Data 模型和一个文件名，PersistentStack 会返回一个 managed object context。然后，我们将要创建我们的 Core Data 模型。接着，我们将创建一个简单的 table view controller 来显示使用 fetched results controller 取回的 item 根目录，并且通过增加 items，sub-items 的导航，删除 items，增加 undo 支持，来一步一步进行交互。

## 设置堆栈

我们将为主队列创建一个 managed object context。在比较老的代码中，你可能见到 `[[NSManagedObjectContext alloc] init]`。而目前，你应该用 `initWithConcurrencyType:` 初始化，以明确你是使用基于队列的并发模型。

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

检查错误是非常重要的，因为在开发过程中，这很有可能经常出错。当 Core Data 发现你改变了数据模型时，就会暂停操作。你也可以通过设置选项来告诉 Core Data 在遇到这种情况后怎么做，这在 Martin 关于 [迁移](http://objccn.io/issue-4-7) 的文章中彻底的解释了。注意，最后一行增加了一个 undo manager；我们将在稍后用到。在 iOS 中，你需要明确的去增加一个 undo manager，但是在 Mac 中，undo manager 是默认有的。

这段代码建立了一个真正简单的 Core Data 堆栈：一个拥有持久化存储协调器的 managed object context，其拥有一个持久化存储。[更复杂的设置](http://objccn.io/issue-4-1/#complicated-stacks)都是可能的；最常见的是拥有多个 managed object context（每一个都在单独的队列中）。

## 创建一个模型

创建模型比较简单，我们只需要增加一个新文件到我们的项目，在 Core Data 选项中选择 Data Model template。这个模型文件将会被编译成后缀名为 `.momd` 类型的文件，我们将会在运行时加载这个文件来为持久化存储创建需要用的 `NSManagedObjectModel`，模型的源码是简单的 XML，根据我们的经验，一般来说当你 check 到代码版本管理中时，应该不会有任何 merge 的困难。如果你愿意，你还可以在代码中创建一个 managed object model。

一旦你创建了模型，你就可以增加 Item 实体，这个实体有两个属性：字符串类型的 `title` 和 integer 类型的 `order`。然后，增加两个关系：一个叫做 `parent`，表示这个 item 的父 item；另一个叫 `children`，是一个一对多的关系。设置它们为彼此相反的关系，也就是说，你设置 a 的 parent 为 b，那么 b 就会自动有一个 children 为 a。

通常，你甚至可以完全抛开 order 属性，而去使用排序好的关系。然而，它们并不能很好的和 fetched results controllers（后面会用到）集成在一起工作。我们要么需要重新实现 fetched results controller 的一部分，要么重新实现排序，通常我们都会选择后者。

现在，从菜单中选择 *Editor > NSManagedObject subclass...*，创建一个绑定到实体的 NSManagedObject 的子类，这将会创建两个文件：`Item.h` 和 `Item.m`。在头文件中，会有一个额外的类别，我们需要将其删除（这是遗留原因导致的）。

### 创建一个 Store 类

对于我们的模型，我们将创建一个根节点作为我们 item 树的开始。我们需要一个地方来创建这个根节点，并且方便以后找到。因此，我们可以通过创建一个简单的存储类来达到这个目的。存储类有一个 managed object context，还有一个 `rootItem` 方法。在 app delegate 中，我们将会在程序启动时查找这个 root item，并且传给了 root view controller。作为一种优化，为了查找这个 item 变得更快，你可以将 item 对象的 id 存储到 user defaults 中：

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

大多数情况下，增加一个 item 都是简单的。然而，我们需要设置 order 属性值比任何其父节点的子节点的值更大。我们将会设置第一个子节点的 order 值 为0，随后每一个子节点都会增加1。我们在 `Item` 类中创建一个自定义的方法来实现：

    + (instancetype)insertItemWithTitle:(NSString*)title
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

获得子节点数量的方法很简单：

    - (NSUInteger)numberOfChildren
    {
        return self.children.count;
    }

为了支持自动更新我们的 table view，我们需要使用 fetched results controller。Fetched results controller 是一个可以管理取出大量 item 请求的对象，同时对使用 Core Data 的 table view 来说，它也是一个完美的小伙伴，在下一节中我们将会用到：

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

### 增加一个支持 Table-View 的 Fetched Results Controller

我们下一步是创建一个 root view controller：一个从 `NSFetchedResultsController` 读取数据的 table view。Fetched results controller 管理你的读取请求，如果你为它分配一个 delegate，那么在 managed object context 中发生的任何改变都会通知你。实际上，这意味着如果你实现了 delegate 方法，当数据模型中发生相关变化时，你可以自动更新你的 table view。比如，你在后台线程同步，并且把变化存储到数据库中，那么你的 table view 将会自动更新。

### 创建 Table View 的 Data Source

在 [更轻量的 View Controllers](http://objccn.io/issue-1-1/) 这篇文章中，我们演示了怎么从 table view 中分离出 data source。这里，我们将会用同样的方法创建一个 fetched results controller。我们创建一个分离出的 `FetchedResultsControllerDataSource` 类，它扮演了 table view 的 data source，通过监听 fetched results controller，自动更新 table view。

我们初始化一个 table view 对象，初始化方法如下：

    - (id)initWithTableView:(UITableView*)tableView
    {
        self = [super init];
        if (self) {
            self.tableView = tableView;
            self.tableView.dataSource = self;
        }
        return self;
    }

当我们设置 fetch results controller 时，我们需要设置自己为 delegate，并且执行初始化的 fetch 操作。`performFetch:` 方法经常容易被忘了调用，那么你将得不到结果（并且不会出错）：

    - (void)setFetchedResultsController:(NSFetchedResultsController*)fetchedResultsController
    {
        _fetchedResultsController = fetchedResultsController;
        fetchedResultsController.delegate = self;
        [fetchedResultsController performFetch:NULL];
    }

因为我们的类实现了 `UITableViewDataSource` 协议，我们需要实现相关的方法。在这两个方法中，我们只需要向 fetched results controller 请求需要的信息：

    - (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
    {
        return self.fetchedResultsController.sections.count;
    }

    - (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex
    {
        id<NSFetchedResultsSectionInfo> section = self.fetchedResultsController.sections[sectionIndex];
        return section.numberOfObjects;
    }

然而，当我们需要创建 cell 的时候，只需要一些简单的步骤：向 fetched results controller 请求正确的对象，从 table view 出列一个cell，然后告诉 delegate (即一个 view controller) 用相应的对象配置这个 cell。作为 view controller，只会关心用模型对象更新cell：

    - (UITableViewCell*)tableView:(UITableView*)tableView 
            cellForRowAtIndexPath:(NSIndexPath*)indexPath
    {
        id object = [self.fetchedResultsController objectAtIndexPath:indexPath];
        id cell = [tableView dequeueReusableCellWithIdentifier:self.reuseIdentifier
                                                 forIndexPath:indexPath];
        [self.delegate configureCell:cell withObject:object];
        return cell;
    }

### 创建 Table View Controller

现在，我们可以创建一个 view controller，使用刚刚创建的类显示 item 列表。在示例程序中，我们创建一个 Storyboard，并且增加一个拥有 table view controller 的 navigation controller。这会自动设置 view controller 作为数据源，而这不是我们想要的效果。因此，在我们的viewDidLoad中，我们做下面的操作:

    fetchedResultsControllerDataSource =
        [[FetchedResultsControllerDataSource alloc] initWithTableView:self.tableView];
    self.fetchedResultsControllerDataSource.fetchedResultsController = 
        self.parent.childrenFetchedResultsController;
    fetchedResultsControllerDataSource.delegate = self;
    fetchedResultsControllerDataSource.reuseIdentifier = @"Cell";

在初始化 fetched results controller data source 时，table view 的数据源可以被设置。reuse 标识符匹配在 Storyboard 中相对应的对象。现在，我们需要实现 delegate 方法：

    - (void)configureCell:(id)theCell withObject:(id)object
    {
        UITableViewCell* cell = theCell;
        Item* item = object;
        cell.textLabel.text = item.title;
    }

当然，除了设置 text 的 label 外，你还可以做更多的事情，但是你应该已经明白了要领。现在我们已经为显示数据准备好了相当多的事情，但是却仍然没有增加数据的方法，这看起来非常空。

## 增加互动

我们将会增加两种和数据交互的方法。首先，我们需要实现增加 items。然后我们需要实现 fetched results controller 的 delegate 方法去更新 table view，并且增加删除和 undo 支持。

### 增加 Items

为了增加 items，我们借鉴 [Clear](http://www.realmacsoftware.com/clear/) 的交互设计，这是我认为最漂亮的应用之一。我们增加一个 text field 作为 table view 的头，并修改 table view 的 content inset，确保它默认保持隐藏，正如 Joe 在 [scroll view](http://www.objc.io/issue-3/scroll-view.html) 这篇文章中解释一样。像往常一样，所有的代码都在 github 上，这里是插入 item 相关的代码，在 `textFieldShouldReturn:`

    [Item insertItemWithTitle:title 
                       parent:self.parent
       inManagedObjectContext:self.parent.managedObjectContext];
    textField.text = @"";
    [textField resignFirstResponder];

### 监听改变

下一步是确保 table view 会为新创建的 item 插入一行。有好几种方法可以做到，但是我们将会使用 fetched results controller 的代理方法：

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

fetched results controller 也会在删除、改变和移动时调用一些方法（我们将在稍后实现）。如果你一次有很多改变，你可以多实现两个方法，那么 table view 将会动画地展现所有的改变。对于单个 item 的插入和删除，这并不会有任何不同，但是如果你选择实现同时同步，那么将会变得更漂亮：

    - (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
    {
        [self.tableView beginUpdates];
    }

    - (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
    {
        [self.tableView endUpdates];
    }

### 使用 Collection View

值得注意的是，fetched results controllers 并非只能用于 table views；你可以将它只用在任何 view 中。因为它们是基于 indexPath 的，所以它们能与 collection views 很好的一起工作。由于 collection view 没有 `beginUpdates` 和 `endUpdates` 方法，却有一个 `performBatchUpdates` 方法，所以我们需要稍加改变。你可以收集你得到的所有更新，然后在 `controllerDidChangeContent` 中，用 block 执行所有的更新。Ash Furrow 写了一个关于如何做的[例子](https://github.com/AshFurrow/UICollectionView-NSFetchedResultsController)。

#### 实现你自己的 Fetched Results Controller

你不必使用 `NSFetchedResultsController`。实际上，在很多情况下，为你的程序创建一个类似的类将显得更有意义。你可以做的是注册 `NSManagedObjectContextObjectsDidChangeNotification`。然后你就可以得到一个 `notification`，`userInfo` 字典将会包含改变对象，插入对象，删除对象的列表，然后你可以按你喜欢的方式执行这些操作。

### 传递 Model 对象

现在我们可以增加并且列出 items 了，现在我们需要确定能够创建 sub-lists。在 Storyboard 中，你可以通过拖拽一个 cell 到 view controller 中来创建一个 segue。最好给 segue 指定一个名字，这样，如果一个 view controller 中有多个 segues 的话，我们就可以将其区分开了。

我处理 segues 的模式看起来像这样：首先，你尝试识别出这个 segue，对于每一个 segue，你为它的目标 view controller 单独写一个方法：

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

子 view controller 需要唯一的东西就是item。通过 item，也可以得到 managed object context。我们从 data source 中得到选中的 item（通过 table view 选中的 item 的 index 值，从 fetched results controller 中取出正确的 item），就这么简单。

很不幸的是，在 app delegate 中，将 managed object context 作为一个属性，然后总是在任何地方访问它，这是模式非常常见。这其实是一个坏主意。如果你想要为你 view controller 中的一部分使用一个不同的 managed object context时，将很难重构，此外，你的代码将变得很难测试。

现在，尝试在 sub-list 中增加一个 item，你很有可能得到一个 crash。这是因为我们现在有两个 fetched results controllers，一个是 topmost view controller，还有一个是root view controller。后者尝试去更新它的 table view，而它的table view是离屏的(offscreen),就这样所有的操作都crash了。解决方案是告诉我们的data source停止监听fetched results controller的代理方法：

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

一种方法就是在 data source 中设置 fetched results controller 的代理为 `nil`，这样就再也不会收到更新通知了。当我们离开 `paused` 状态时，还需要加上去：

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

这样 `performFetch` 就会确保你的 data source 保持最新的。当然，更好的实现方法并不是设置代理为 `nil`，而是记录每一个在 paused 状态下的改变，相应的，在离开 paused 状态后，更新 table view。

### 删除

为了支持删除，我们需要花费几步操作。首先，我们需要确信我们的 table view 支持删除。第二，我们需要从 core data 中删除对象，并且保证我们的排序是正确的。

为了支持滑动删除，我们需要在 data source 中实现两个方法：

    - (BOOL)tableView:(UITableView*)tableView
     canEditRowAtIndexPath:(NSIndexPath*)indexPath
    {
        return YES;
    }
     
    - (void)tableView:(UITableView *)tableView 
     commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
         if (editingStyle == UITableViewCellEditingStyleDelete) {
            id object = [self.fetchedResultsController objectAtIndexPath:indexPath];
            [self.delegate deleteObject:object];
         }
    }

我们需要通知代理（the view controller）删除对象，而不是直接删除。这样，我们不需要将 store object 分配给data source（data source 在整个项目中都必须可重用），并且保持自定义操作的灵活性。view controller 只需在 managed object context 中简单的调用 `deleteObject:`。

然而，还有两个重要的问题需要被解决：我们怎么处理被删除 item 的子 item，怎么强制我们的 order 变化？幸运的是，传播删除是很简单的：在我们的数据模型中，我们可以选择 *Cascade* 作为子关系的删除规则。

为了强制我们的 order 变化，我们可以重写 `prepareForDeletion` 方法，用更高一级的 `order` 更新所有兄弟节点。

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

现在我们几乎快完成了。我们可以与 table view 的 cell 交互，并且可以删除模型对象。最后一步是实现一旦模型对象被删除后，删除 table view cell 的必要的代码。在 data sources 的方法 `controller:didChangeObject:...` 中，我们增加另一个 if 语句：

    ...
    else if (type == NSFetchedResultsChangeDelete) {
        [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }

### 增加 Undo 支持

Core Data 优点之一就是集成了 undo 支持。我们将为增加*晃动撤销*功能，第一步就是告诉程序我们可以这么做：

    application.applicationSupportsShakeToEdit = YES;

现在，这个功能可以被任何抖动触发，程序将会向 first responder 请求 undo manager，并且执行一次 undo 操作。在[上个月的文章](http://objccn.io/issue-3-4)中，我们了解了，一个 view controller 也在响应链中（responder chain），这也正是我们将要使用的。在我们的 view controller 中，我们重写来自 `UIResponder` 类中的两个方法：

    - (BOOL)canBecomeFirstResponder {
        return YES;
    }

    - (NSUndoManager*)undoManager
    {
        return self.managedObjectContext.undoManager;
    }

现在，当一个抖动发生时，managed object context 的 undo manager 将会得到一个undo消息，并且撤销最后一次改变。记住，在 iOS 中，managed object context 默认并没有一个 undo manager，（而在 Mac 中，新建的 managed object context 默认是有的），所以我们需要在持久化堆栈中设置：

    self.managedObjectContext.undoManager = [[NSUndoManager alloc] init];

基本上就是这样了。现在，当你抖动时，你将得到 iOS 默认有两个按钮的提醒框：一个是 undo 按钮，一个 cancel 按钮。Core Data 的一个非常好的特性是将改变自动分组。比如，`addItem:parent` 将会记录作为一个 undo 处理。关于删除，也是一样的。

为了让用户管理 undo 操作更容易一些，我们可以给操作命名，并且将 textFieldShouldReturn: 的第一行修改成这样：

    NSString* title = textField.text;
    NSString* actionName = [NSString stringWithFormat:
        NSLocalizedString(@"add item \"%@\"", @"Undo action name of add item"), title];
    [self.undoManager setActionName:actionName];
    [self.store addItem:title parent:nil];

现在，当用户抖动时，除了普通的 "Undo" 标签外，他将得到更多的上下文环境。

### 编辑

编辑目前在示例程序中并不支持，但是这只是一个改变对象属性的问题。比如，改变一个 item 的 title，只需要设置 `title` 属性就好了。改变 `foo` item 的 parent，只需要设置 `parent` 属性为一个新值 `bar`，所有的东西都将得到更新，`bar` 现在有一个 `children` 为 `foo`，因为我们使用 fetched results controllers，用户界面同样也会自动更新。

### 重新排序

重新排序 cell，在现有程序中也是不可行的，但是这实现起来很简单。但是，还有一个需要注意的地方：如果你允许用户重新排序，你将需要在 model 中更新 `order` 属性，并且从 fetched results controller 得到一个 delegate call（你需要忽略这个调用，因为cell已经被移动了）。这在 [NSFetchedResultsControllerDelegate 的文档](https://developer.apple.com/library/ios/documentation/CoreData/Reference/NSFetchedResultsControllerDelegate_Protocol/Reference/Reference.html#//apple_ref/doc/uid/TP40008228-CH1-SW14)中有解释。

## 保存

保存非常简单，就是在 managed object context 中调用 `save` 而已。因为我们并不直接访问 managed object context，所以是在 store 中进行保存。唯一的困难的是什么时候去保存。Apple 的示例代码在 `applicationWillTerminate:` 中执行这个操作，但是这取决于你的使用情况，这也有可能在 `applicationDidEnterBackground:` 中，甚至当你程序运行时调用。

## 讨论

在写这篇文章和示例程序时，我初始时就犯了一个错误：我没有选择使用一个空的根 item 来作为所有用户创建的 item 的 parent，而是让它们都指向了一个 `nil`。这将造成很多问题：因为 view controller 中的父 item 可能是 `nil`，我们需要将 store（或 managed object context） 传给每一个子 view controller。同样的，强制 order 重新排序也非常困难，因为我们需要查找出一个 item 的所有兄弟节点，这样会迫使 Core Data 到磁盘上读取数据。不幸的是，当写这些代码时，这些问题并没有立刻弄明白，一些问题只是在写测试时才变得清晰。当我重新写代码的时候，我知道了将 `Store` 类中大部分代码移到 `Item` 类中，就这样，事情变得清楚多了。

---

 

原文: [A Complete Core Data Application](http://www.objc.io/issue-4/full-core-data-application.html)

译文 [一个完整的 Core Data 应用](http://answerhuang.duapp.com/index.php/2013/09/17/full-core-data-application/)

精细校对 [@itouch2](http://itouch2.github.io/)
