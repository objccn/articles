几乎每一个应用开发者都需要经历的就是将从 web service 获取到的数据转变到 Core Data 中。这篇文章阐述了如何去做。我们在这里讨论的每一个问题在之前的文章中都已经描述过了，并且 Apple 在他们的文档中也提过。然而，从头到尾回顾一遍对我们来说还是很有益的。

程序所有的代码都[在 GitHub 上](https://github.com/objcio/issue-10-core-data-network-application)。

## 计划

我们将会建立一个简单、只读的应用程序，用来显示 CocoaPods 说明的完整列表。这些说明都显示在 table view 中，所有 pod 的说明都是以分页的形式，从 web service 取得，并以 JSON 对象返回。

我们这样来做

1. 首先，我们创建一个 `PodsWebservice` 类，用来从 web service 请求所有的说明。
2. 接着，创建一个 `Importer` 对象取出说明并将他们导入 Core Data。
3. 最终，我们展示如何让最重要的工作在后台线程中运行。

## 从 Web Service 取得对象

首先，创建一个单独的类从 web service 取得数据是很不错的。我们已经写了一个简单的 [web server 示例](https://gist.github.com/chriseidhof/725946f0d02b17ced209)，用来获取 CocoaPods 说明并将它们生成 JSON；请求 `/specs` 这个 URL 会返回一个按字母排序的 pod 说明列表。web service 是分页的，所以我们需要分开请求每一页。一个响应的示例如下：

    { 
      "number_of_pages": 559,
      "result": [{
        "authors": { "Ash Furrow": "ash@ashfurrow.com" },
        "homepage": "https://github.com/500px/500px-iOS-api",
        "license": "MIT",
        "name": "500px-iOS-api",
      ...

我们想要创建只有一个 `fetchAllPods:` 方法的类，它有一个回调 block，这将会被每一个页面调用。这也可以通过代理实现；但为什么我们选择用 block，你可以读一读这篇[有关消息传递机制的文章](http://www.objccn.io/issue-7-4/)。

	@interface PodsWebservice : NSObject
	- (void)fetchAllPods:(void (^)(NSArray *pods))callback;
	@end

这个回调会被每个页面调用。实现这个方法很简单。我们创建一个帮助方法，`fetchAllPods:page:`，它会为一个页面取得所有的 pods，一旦加载完一页就让它再调用自己。注意一下，为了简洁，我们这里不考虑处理错误，但是你可以在 GitHub 上完整的项目中看到。处理错误总是很重要的，至少打印出错误，这样你可以很快检查到哪些地方没有像预期一样工作：

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
                NSUInteger nextPage = page + 1;
                if (nextPage < numberOfPages.unsignedIntegerValue) {
                    [self fetchAllPods:callback page:nextPage];
                }
            }
        }] resume];
    }

要做的就是这些了。我们解析 JSON，做一些非常粗糙的检查（验证结果是一个字典），然后调用回调函数。

## 将对象装进 Core Data

现在我们可以将 JSON 装进我们的 Core Data store 中了。为了分清，我们创建一个 `Importer` 对象来调用 web service，并且创建或者更新对象。将这些放到一个单独的类中很不错，因为这样我们的 web service 和 Core Data 部分完全解耦。如果我们想要给 store 提供一个不同的 web service 或者在别的某个地方重用 web service，我们现在并不需要手动处理这两种情况。同时，不要在 view controller 中编写逻辑代码，以后我们可以在别的 app 中更容易复用这些组件。

我们的 `Importer` 有两个方法：
 
    @interface Importer : NSObject
    - (id)initWithContext:(NSManagedObjectContext *)context 
               webservice:(PodsWebservice *)webservice;
    - (void)import;
    @end

通过初始化方法将 context 注入到对象中是一个非常强有力的技巧。当编写测试的时候，我们可以很容易的注入一个不同的 context。同样适用于 web service：我们可以很容易的用一个不同的对象模拟 web service。

`import` 方法负责处理逻辑。我们调用 `fetchAllPods:` 方法，并且对于每一批 pod 说明，我们都会将它们导入到 context 中。通过将逻辑代码包装到 `performBlock:`，context 会确保所有的事情都在正确的线程中执行。然后我们迭代这些说明，并且会为每一个说明生成一个唯一标识符（这些标识符可以是任何独一无二的，只要能确定到唯一一个 model object，正如在 [Drew 的文章](http://objccn.io/issue-10-1/)中解释那样。然后我们试着找到 model object，如果不存在则创建一个。`loadFromDictionary:` 方法需要一个 JSON 字典，并根据字典中的值更新 model object：
 
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

上面的代码中有很多地方要注意。首先，查找或创建方法的效率是非常低下的。在生产环境的代码中，你需要批量处理 pods 并且同时找到他们，正如在《导入大数据集》中[「高效地导入数据」](http://objccn.io/issue-4-5/#efficient-importing)这一节中所解释的那样。

第二，我们直接在 `Pod` 类（managed object 的子类）中创建 `loadFromDictionary:`。这意味着我们的 model object 知道 web service。在真实的代码中，我们很有可能将这些放到一个类别中，这样这两个很完美的分开了。对于这个示例，这无关要紧。

## 创建一个独立的后台堆栈

在写上面的代码时，我们会先在在主 managed object context 中拥有一切需要的数据。我们的应用在 table view 控制器中使用一个 fetched results controller 来显示所有的 pods。当 managed object context 中的数据改变时，fetched results controller 自动更新 data model。然而，在主 managed object context 中处理导入数据并不是最优的。主线程可能被堵塞，UI 可能没有反应。大多数时候，在主线程中处理的工作应该是最小限度的，并且造成的延迟应当难以察觉。如果你的情况正是这样，那非常好。然而，如果我们想要做些额外的努力，我们可以在后台线程中处理导入操作。

Apple 在 WWDC 会议以及官方的《Core Data 编程指南》文档的[「Concurrency with Core Data」](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreData/Articles/cdConcurrency.html) 一节中，对于并发的 Core Data，推荐给开发者两种选择。这两种都需要独立的 managed object contexts，它们要么共享同样的 persistent store coordinator，要么不共享。在处理很多改变时，拥有独立的 persistent store coordinators 提供更出色的性能，因为仅需要的锁只是在 sqlite 级别。拥有共享的 persistent store coordinator 也就意味着拥有共享缓存，当你没有做出很多改变时，这会很快。所以，根据你的情况而定，你需要衡量哪种方案更好，然后选择是否需要一个共享的 persistent store coordinator。当主 context 是只读的情况下，根本不需要锁，因为 iOS 7 中的 sqlite 有写前记录功能并且支持多重读取和单一写入。然而，对于我们的示范目的，我们会使用完全独立堆栈的处理方式。我们使用下面的代码设置一个 managed object context：

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

然后我们调用这个方法两次，一次是为主 managed object context，一次是为后台 managed object context：

    self.managedObjectContext = [self setupManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType];
    self.backgroundManagedObjectContext = [self setupManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
注意传递的参数 `NSPrivateQueueConcurrencyType` 告诉 Core Data 创建一个独立队列，这将确保后台 managed object context 的运行发生在一个独立的线程中。

现在就剩一步了：每当后台 context 保存后，我们需要更新主线程。我们在[之前第 2 期的这篇文章](http://objccn.io/issue-2-2/)中描述了如何操作。我们注册一下，当 context 保存时得到一个通知，如果是后台 context，调用 `mergeChangesFromContextDidSaveNotification:` 方法。这就是我们要做的所有事情：

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

这儿还有一个小忠告：`mergeChangesFromContextDidSaveNotification:` 是在 `performBlock:`中发生的。在我们这个情况下，`moc` 是主 managed object context，因此，这将会阻塞主线程。

注意你的 UI（即使是只读的）必须有能力处理对象的改变，或者事件的删除。Brent Simmons 最近写了两篇文章，分别是 [《Why Use a Custom Notification for Note Deletion》](http://inessential.com/2014/02/25/why_use_a_custom_notification_for_note_d) 和 [《Deleting Objects in Core Data》](http://inessential.com/2014/02/25/more_about_deleting_objects_in_core_data)。这些文章解释说明了如何面对这些情况，如果你在你的 UI 中显示一个对象，这个对象有可能会发生改变或者被删除。

## 实现从 UI 进行的写入

你可能觉得上面讲的看起来非常简单，这是因为仅有的写操作是在后台线程进行的。在我们当前的应用中，我们没有处理其他方面的合并；并没有来自主 managed object context 中的改变。为了增加这个，你可以采用不少策略。[Drew 的这篇文章](http://objccn.io/issue-10-1/)很好的阐述了相关的方法。

根据你的需求，一个非常简单的模式或许是这样：不管用户何时改变 UI 中的某些东西，你并不改变 managed object context。相反，你去调用 web service。如果成功了，你可以从 web service 中得到改变，然后更新你的后台 context。这些改变随后回被传送到主 context。这样做有两个弊端：用户可能需要一段时间才能看到 UI 的改变，并且如果用户未联网，他将不能改变任何东西。在 [Florian 的文章](http://objccn.io/issue-10-4/)中，描述了我们如何使用不同策略让应用在离线时也能工作。

如果你正在处理合并，你也需要定义一个合并原则。这又是根据特定使用情况而定的。如果合并失败了你可能需要抛出一个错误，或者总是给某一个 managed object context 优先权。[NSMergePolicy](https://developer.apple.com/library/mac/documentation/CoreData/Reference/NSMergePolicy_Class/Reference/Reference.html) 类描述出了可能的选择。

## 结论

我们已经看到如何实现一个简单的只读应用，这个应用能将从 web service 取得的大量数据导入到 Core Data。通过使用后台 managed object context，我们已经建立了一个不会阻塞 UI（除非正在处理合并）的 Core Data 程序。

---

 

原文 [A Networked Core Data Application](http://www.objc.io/issue-10/networked-core-data-application.html)