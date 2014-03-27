---
layout: post
title: Core Data Overview
category: "4"
date: "2013-09-09 11:00:00"
author: "<a href=\"http://twitter.com/danielboedewadt\">Daniel Eggert</a>"
tags: article
---

{% include links-4.md %}


Core Data is probably one of the most misunderstood Frameworks on OS X and iOS. To help with that, we'll quickly go through Core Data to give you an overview of what it is all about, as understanding Core Data concepts is essential to using Core Data the right way. Just about all frustrations with Core Data originate in misunderstanding what it does and how it works. Let's dive in...
Core Data可能是OS X和iOS里面最容易被误解的框架之一，为了帮助大家理解，我们将快速的研究Core Data，让大家对它有一个初步的了解，对于想要正确使用Core Data的同学来说，理解它的概念是非常必要的。几乎所有对Core Data感到失望的原因都是因为对它工作机制的错误理解。让我们开始吧：

## What is Core Data?
## Core Data 是什么？

More than eight years ago, in April 2005, Apple released OS X version 10.4, which was the first to sport the Core Data framework. That was back when YouTube launched.
大概八年前，2005的四月份，Apple发布了OS X10.4，正是在这个版本中Core Data框架发布了。那个时候YouTube也刚发布。

Core Data is a model layer technology. Core Data helps you build the model layer that represents the state of your app. Core Data is also a persistent technology, in that it can persist the state of the model objects to disk. But the important takeaway is that Core Data is much more than just a framework to load and save data. It's also about working with the data while it's in memory.
Core Data 是一个模型层的技术。Core Data 帮助你建立代表程序状态的模型层。Core Data 也是一种持久化技术，它能将模型对象的状态持久化到磁盘，但它最重要的特点是：Core Data 不仅是一个加载、保存数据的框架，它还能和内存中的数据很好的共事。

If you've worked with [Object-relational mapping (O/RM)](https://en.wikipedia.org/wiki/Object-relational_mapping) before: Core Data is **not** an O/RM. It's much more. If you've been working with [SQL](https://en.wikipedia.org/wiki/Sql) wrappers before: Core Data is **not** an SQL wrapper. It does by default use SQL, but again, it's a way higher level of abstraction. If you want an O/RM or SQL wrapper, Core Data is not for you.
如果你之前曾经接触过 [Object-relational maping (O/RM)](https://en.wikipedia.org/wiki/Object-relational_mapping)：Core Data*不是*一个 O/RM，但它比 O/RM 能做的更多。如果你之前曾经接触过 [SQL](https://en.wikipedia.org/wiki/Sql) wrappers：Core Data *不是*一个 SQL wrapper。它默认使用 SQL，但是，它是一种更高级的抽象概念。如果你需要的是一个O/RM或者SQL wrapper，那么 Core Data 并不适合你。

One of the very powerful things that Core Data provides is its object graph management. This is one of the pieces of Core Data you need to understand and learn in order to bring the powers of Core Data into play.
对象图形管理是 Core Data 提供最强大的功能之一。为了更好利用Core Data，这是你需要理解的一块内容。

On a side note: Core Data is entirely independent from any UI-level frameworks. It's, by design, purely a model layer framework. And on OS X it may make a lot of sense to use it even in background daemons and the like.
还有一点要注意：Core Data 是完全独立于任何UI层级的框架。它是作为模型层框架被设计出来的。在OS X中，甚至在一些后台驻留程序中，Core Data都起着非常重要的意义。

## The Stack
## 堆栈

There are quite a few components to Core Data. It's a very flexible technology. For most uses cases, the setup will be relatively simple. 
Core Data 有相当多可用的组件。这是一个非常灵活的技术。在大多数的使用情况下，设置都相当简单。

When all components are tied together, we refer to them as the *Core Data Stack*. There are two main parts to this stack. One part is about object graph management, and this should be the part that you know well, and know how to work with. The second part is about persistence, i.e. saving the state of your model objects and retrieving the state again.
当所有的组件都捆绑到一起的时候，我们把它称作 *Core Data 堆栈*，这个堆栈有两个主要部分。一部分是关于对象图形管理，这正是你需要很好掌握的那一部分，并且知道怎么使用。第二部分是关于持久化，比如，保存你模型对象的状态，然后再恢复模型对象的状态。

In between the two parts, in the middle of the stack, sits the Persistent Store Coordinator (PSC), also known to friends as the *central scrutinizer*. It ties together the object graph management part with the persistence part. When one of the two needs to talk to the other, this is coordinated by the PSC.
在两个部分之间，即堆栈中间，是持久化存储协调器(PSC)，也被称为*中间审查者*。它将对象图形管理部分和持久化部分捆绑在一起，当它们两者中的任何一部分需要和另一部分交流时，这便需要PSC来调节了。

<img name="Complex core data stack" src="{{site.images_path}}/issue-4/stack-complex.png" width="624" height="652">

The *object graph management* is where your application's model layer logic will live. Model layer objects live inside a context. In most setups, there's one context and all objects live in that context. Core Data supports multiple contexts, though, for more advanced use cases. Note that contexts are distinct from one another, as we'll see in a bit. The important thing to remember is that objects are tied to their context. Each *managed* object knows which context it's in, and each context knows which objects it is managing.
*对象图形管理*是你程序模型层的逻辑存在的地方。模型层的对象存在于一个 context 内。在大多数的设置中，存在一个 context ，并且所有的对象存在于那个 context 中。Core Data 支持许多 contexts，不过对于更高级的使用情况才用。注意每个 context 和其他 context 都是完全独立的，一会儿我们将会谈到。需要记住的是，对象和他们的 context 是相关联的。每个*被管理*的对象都知道自己属于哪个 context，并且每个 context 都知道自己管理着哪些对象。

The other part of the stack is where persistency happens, i.e. where Core Data reads and writes from / to the file system. In just about all cases, the persistent store coordinator (PSC) has one so-called *persistent store* attached to it, and this store interacts with a [SQLite](https://www.sqlite.org) database in the file system. For more advanced setups, Core Data supports using multiple stores that are attached to the same persistent store coordinator, and there are a few store types than just SQL to choose from.
堆栈的另一部分就是持久化发生的地方了，即 Core Data 从文件系统中读或写的地方。每个持久化存储协调器(persistent store coordinator)都有一个属于自己的*持久化存储*，并且这个 store 在文件系统中与 [SQLite](https://www.sqlite.org) 数据库交互。为了支持更高级的设置，Core Data 可以将多个存储附属于同一个持久化存储协调器，并且除了存储 SQL 格式外，还有很多存储类型可供选择。

The most common scenario, however, looks like this:
最常见的解决方案如下图所示：

<img name="Simple core data stack" src="{{site.images_path}}/issue-4/stack-simple.png" width="550" height="293">

## How the Components Play Together
## 组件如何一起工作

Let's quickly walk through an example to illustrate how these components play together. In our article about a [full application using Core Data][400], we have exactly one *entity*, i.e. one kind of object: We have an *Item* entity that holds on to a title. Each item can have sub-items, hence we have a *parent* and a *child* relationship. 
让我们快速的看一个例子，看看组件是如何协同工作的。在我们的文章[full application using Core Data][400]中，正好有一个*实体*，即一种对象：我们有一个 *Item* 实体对应一个 title。每一个 item 可以拥有子 items，因此，我们有一个父子关系(parent、child)。

This is our data model. As we mention in the article about [Data Models and Model Objects][200], a particular *kind* of object is called an *Entity* in Core Data. In this case we have just one entity: an *Item* entity. And likewise, we have a subclass of `NSManagedObject` which is called `Item`. The *Item* entity maps to the `Item` class. The [data models article][200] goes into more detail about this.
这是我们的数据模型。正如我们[在Data Models and Model Objects][200]文章中提到的一样，在Core Data中有一*种*特别的对象——*实体*。在这种情况下，我们只有一个实体：*Item* 实体。同样的，我们有一个 `NSManagedObject` 的子类，叫做 `Item`。这个 *Item* 实体映射到 `Item` 类上。在[data models article][200]中会详细的谈到这个。

Our app has a single *root* item. There's nothing magical to it. It's simply an item we use to show the bottom of the item hierarchy. It's an item that we'll never set a parent on.
我们的程序仅有一个*根* Item。这并没有什么奇妙的地方。它是一个我们用来显示底层 item 等级的 item。它是一个我们永远不会为其设置父类的 Item。

When the app launches, we set up our stack as depicted above, with one store, one managed object context, and a persistent store coordinator to tie the two together.
当程序运行时，我们像上面图片描绘的一样设置我们的堆栈，一个存储，一个 managed object context，以及一个持久化存储协调器来将他们关联起来。

On first launch, we don't have any items. The first thing we need to do is to create the *root* item. You add managed objects by inserting them into the context.
在第一次运行时，我们并没有任何 items。我们需要做的第一件事就是创建*根* item。你通过将他们插入 context 来增加管理对象。

### Creating Objects
### 创建对象

It may seem cumbersome. The way to insert objects is with the
插入对象的方法似乎很笨重，我们通过NSEntityDescription的方法来插入：

    + (id)insertNewObjectForEntityForName:(NSString *)entityName 
                   inManagedObjectContext:(NSManagedObjectContext *)context

method on `NSEntityDescription`. We suggest that you add two convenience methods to your model class:
我们建议你增加两个方便的方法到你的模型类中：

    + (NSString *)entityName
    {
       return @“Item”;
    }
    
    + (instancetype)insertNewObjectInManagedObjectContext:(NSManagedObjectContext *)moc;
    {
       return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] 
                                            inManagedObjectContext:moc];
    }

Now, we can insert our root object like so:
现在，我们可以像这样插入我们的根对象了：

    Item *rootItem = [Item insertNewObjectInManagedObjectContext:managedObjectContext];

Now there's a single item in our managed object context (MOC). The context knows about this newly inserted *managed object* and the managed object `rootItem` knows about the context (it has a `-managedObjectContext` method).
现在，在我们的 managed object context(MOC) 中有一个唯一的 item。Context 知道这是一个新插入进来需要*被管理的对象*，并且被管理的对象 `rootItem` 知道这个 Context(它有一个 `-managedObjectContext` 方法)。

### Saving Changes
### 保存改变

At this point, though, we have not touched the persistent store coordinator or the persistent store, yet. The new model object, `rootItem`, is just in memory. If we want to save the state of our model objects (in this case just that one object), we need to *save* the context:
虽然我们已经谈到这了，可是我们还是没有接触到持久化存储协调器或持久化存储。新的模型对象—`rootItem`，仅仅在内存中。如果我们想要保存模型对象的状态(在这种情况下只是一个对象)，我们需要*保存* context：

    NSError *error = nil;
	if (! [managedObjectContext save:&error]) {
		// 啊，哦. 有错误发生了 :(
	}

At this point, a lot is going to happen. First, the managed object context figures out what has changed. It is the context's responsibility to track any and all changes you make to any managed objects inside that context. In our case, the only change we've made thus far is inserting one object, our `rootItem`.
这个时候，很多事情将要发生。首先发生的是 managed object context 计算出改变的内容。这是 context 的职责，追踪出任何你在 context 管理对象中做出的改变。在我们的例子中，我们到现在做出的唯一改变就是插入一个对象，即我们的 `rootItem`。

The managed object context then passes these changes on to the persistent store coordinator and asks it to propagate the changes through to the store. The persistent store coordinator coordinates with the store (in our case, an SQL store) to write our inserted object into the SQL database on disk. The `NSPersistentStore` class manages the actual interaction with SQLite and generates the SQL code that needs to be executed. The persistent store coordinator's role is to simply coordinate the interaction between the store and the context. In our case, that role is relatively simple, but complex setups can have multiple stores and multiple contexts.
Managed object context 将这些改变传给持久化存储协调器，让它将这些改变传给 store。持久化存储协调器会协调 store（在我们的例子中，store 是一个 SQL 数据库）来将我们插入的对象写入到磁盘上的SQL数据库。`NSPersistentStore` 类管理着和 SQLite 的实际交互，并且产生需要被执行的SQL代码。持久化存储协调器的角色就是简化调整 store 和 context之间的交互过程。在我们的例子中，这个角色相当简单，但是，复杂的设置可以有多个 stores 和多个 contexts。

### Updating Relationships
### 更新关系

The power of Core Data is managing relationships. Let's look at the simple case of adding our second item and making it a child item of the `rootItem`:
Core Data 的优势在于管理关系。让我们着眼于简单的情况：增加我们第二个item，并且使它成为 `rootItem` 的子 item：

    Item *item = [Item insertNewObjectInManagedObjectContext:managedObjectContext];
	item.parent = rootItem;
	item.title = @"foo";

That's it. Again, these changes are only inside the managed object context. Once we save the context, however, the managed object context will tell the persistent store coordinator to add that newly created object to the database file just like for our first object. But it will also update the relationship from our second item to the first and the other way around, from the first object to the second. Remember how the *Item* entity has a *parent* and a *children* relationship. These are reverse relationships of one another. Because we set the first item to be the parent of the second, the second will be a child of the first. The managed object context tracks these relationships and the persistent store coordinator and the store persist (i.e. save) these relationships to disk.
好了。同样的，这些改变仅仅存在于 managed object context 中。一旦我们保存了 context，managed object context 将会通知持久化存储协调器，像增加第一个对象一样增加新创建的对象到数据库文件中。但这也将会更新从第二个 item 到第一个 item 之间的关系，或从第一个 item 到第二个 item 的关系。记住 *Item* 实体是如何有一个*父**子*关系的。同时他们之间有相反的关系。因为我们设置第一个 item 为第二个 item 的父类时，第二个 item 将会变成第一个 item 的子类。Managed object context 追踪这些关系，持久化存储协调器和 store 保存这些关系到磁盘。

### Getting to Objects
### 弄清对象

Let's say we've been using our app for a while and have added a few sub-items to the root item, and even sub-items to the sub-items. Then we launch our app again. Core Data has saved the relationships of the items in the database file. The object graph is persisted. We now need to get to our *root* item, so we can show the bottom-level list of items. There are two ways for us to do that. We'll look at the simpler one first.
我们已经使用我们的程序一会儿了，并且已经为 rootItem 增加了一些 sub-items，甚至增加 sub-items 到 sub-items。然而，我们再次启动我们的程序。Core Data 已经将这些 items 之间的关系保存到了数据库文件。对象图形是持久化的。我们现在需要取出*根*item，所以我们可以显示底层 items 的列表。有两种方法可以达到这个效果。我们先看简单点的方法。

When we created our `rootItem` object, and once we've saved it, we can ask it for its `NSManagedObjectID`. This is an opaque object that uniquely represents that object. We can store this into e.g. `NSUSerDefaults`, like this:
当 `rootItem` 对象创建并保存之后我们可以向它请求它的 `NSManagedObjectID`。这是一个不透明的对象，可以唯一代表`rootItem`。我们可以保存这个对象到NSUSerDefaults，像这样：

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setURL:rootItem.managedObjectID.URIRepresentation forKey:@"rootItem"];

Now when the app is relaunched, we can get back to the object like so:
现在，当程序重新运行时，我们可以像这样返回得到这个对象：

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSURL *uri = [defaults URLForKey:@"rootItem"];
	NSManagedObjectID *moid = [managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:uri];
	NSError *error = nil;
    Item *rootItem = (id) [managedObjectContext existingObjectWithID:moid error:&error];

Obviously, in a real app, we'd have to check if `NSUserDefaults` actually returns a valid value.
很明显，在一个真正的程序中，我们需要检查 `NSUserDefaults` 是否真正返回一个有效值。

What just happened is that the managed object context asked the persistent store coordinator to get that particular object from the database. The root object is now back inside the context. However, all the other items are not in memory, yet.
刚才的操作是 managed object context 要求持久化存储协调器从数据库取得指定的对象。根对象现在被恢复到 context 中。然而，其他所有的 items 仍然不在内存中。

The `rootItem` has a relationship called `children`. But there's nothing there, yet. We want to display the sub-items of our `rootItem`, and hence we'll call:
`rootItem` 有一个子关系叫做 `children`。但现在那儿还没有什么。我们想要显示 rootItem 的子 item，因此我们需要调用：

    NSOrderedSet *children = rootItem.children;

What happens now, is that the context notes that the relationship `children` from that `rootItem` is a so-called *fault*. Core Data has marked the relationship as something it still has to resolve. And since we're accessing it at this point, the context will now automatically coordinate with the persistent store coordinator to bring those child items into the context.
现在发生的是，context 标注这个 rootItem 的子 item 为所谓的*故障*。Core Data 已经标注这个关系为仍需要被解决。既然我们已经在这个时候访问了它，context 将会自动配合持久化存储协调器来将这些子 items 载入到 context 中。

This may sound very trivial, but there's actually a lot going on at this point. If any of the child objects happen to already be in memory, Core Data guarantees that it will reuse those objects. That's what is called *uniquing*. Inside the context, there's never going to be more than a single object representing a given item.
这听起来可能非常不重要，但是在这个时候真正发生了很多事情。如果任何子对象偶然发生在内存中，Core Data 保证会复用那些对象。这是Core Data *独一无二*的功能。在 context 内，从不会存在第二个相同的单一对象来代表一个给定的 item。

Secondly, the persistent store coordinator has its own internal cache of object values. If the context needs a particular object (e.g. a child item), and the persistent store coordinator already has the needed values in its cache, the object (i.e. the item) can be added to the context without talking to the store. That's important, because accessing the store means running SQL code, which is much slower than using values already in memory.
第二，持久化存储协调器有它自己内部对象值的缓存。如果 context 需要一个指定的对象(比如一个子 item)，并且持久化存储协调器在缓存中已经有需要的值，那么，对象（即这个 item）可以不通过 store 而被直接加到 context。这很重要，因为访问 store 就意味着执行 SQL 代码，这比使用内存中存在的值要慢很多。

As we continue to traverse from item to sub-item to sub-item, we're slowly bringing the entire object graph into the managed object context. Once it's all in memory, operating on objects and traversing the relationships is super fast, since we're just working inside the managed object context. We don't need to talk to the persistent store coordinator at all. Accessing the `title`, `parent`, and `children` properties on our `Item` objects is super fast and efficient at this point.
随着我们遍历 item 的子 item，以及子 item 的子 item，我们慢慢地把整个对象图形引用到了 managed object context。而这些对象都在内存中之后，操作对象以及传递关系就会变得非常快，因为我们只是在 managed object contex里操作。我们跟本不需要访问持久化存储协调 器。在我们的 Item 对象上访问 `title`，`parent` 和 `children` 是非常快而且高效的。

It's important to understand how data is fetched in these cases, since it affects performance. In our particular case, it doesn't matter too much, since we're not touching a lot of data. But as soon as you do, you'll need to understand what goes on under the hood.
由于它会影响性能，所以了解数据在这些情况下怎么取出来是非常重要的。在我们特定的情况下，由于我们并没接触到太多的数据，所以这并不算什么，但是一旦你接触了，你将需要了解在背后发生了什么。

When you traverse a relationship (such as `parent` or `children` in our case) one of three things can happen: (1) the object is already in the context and traversing is basically for free. (2) The object is not in the context, but the persistent store coordinator has its values cached, because you've recently retrieved the object from the store. This is reasonably cheap (some locking has to occur, though). The expensive case is (3) when the object is accessed for the first time by both the context and the persistent store coordinator, such that is has to be retrieved by store from the SQLite database. This last case is much more expensive than (1) and (2).

If you know you have to fetch objects from the store (because you don't have them), it makes a huge difference when you can limit the number of fetches by getting multiple objects at once. In our example, we might want to fetch all child items in one go instead of one-by-one. This can be done by crafting a special `NSFetchRequest`. But we must take care to only to run a fetch request when we need to, because a fetch request will also cause option (3) to happen; it will always access the SQLite database. Hence, when performance matters, it makes sense to check if objects are already around. You can use [`-[NSManagedObjectContext objectRegisteredForID:]`](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html#//apple_ref/occ/instm/NSManagedObjectContext/objectRegisteredForID:) for that.


### Changing Object Values

Now, let's say we are changing the `title` of one of our `Item` objects:

    item.title = @"New title";

When we do this, the items title changes. But additionally, the managed object context marks the specific managed object (`item`) as changed, such that it will be saved through the persistent store coordinator and attached store when we call `-save:` on the context. One of the key responsibilities of the context is *change tracking*.

The context knows which objects have been inserted, changed, and deleted since the last save. You can get to those with the `-insertedObjects`, `-updatedObjects`, and `-deletedObjects` methods. Likewise, you can ask a managed object which of its values have changed by using the `-changedValues` method. You will probably never have to. But this is what Core Data uses to be able to push changes you make to the backing database.

When we inserted new `Item` objects above, this is how Core Data knew it had to push those to the store. And now, when we changed the `title`, the same thing happened.

Saving values needs to coordinate with both the persistent store coordinator and the persistent store, which, in turn, accesses the SQLite database. As when retrieving objects and values, accessing the store and database is relatively expensive when compared to simply operating on objects in memory. There's a fixed cost for a save, regardless of how many changes you're saving. And there's a per-change cost. This is simply how SQLite works. When you're changing a lot of things, you should therefore try to batch changes into reasonably sized batches. If you save for each change, you'd pay a high price, because you have to save very often. If you save to rarely, you'd have a huge batch of changes that SQLite would have to process.

It is also important to note that saves are atomic. They're transactional. Either all changes will be committed to the store / SQLite database or none of the changes will be saved. This is important to keep in mind when implementing custom [`NSIncrementalStore`](https://developer.apple.com/library/ios/DOCUMENTATION/CoreData/Reference/NSIncrementalStore_Class/Reference/NSIncrementalStore.html) subclasses. You have to either guarantee that a save will never fail (e.g. due to conflicts), or your store subclass has to revert all changes when the save fails. Otherwise, the object graph in memory will end up being inconsistent with the one in the store.

Saves will normally never fail if you use a simple setup. But Core Data allows multiple contexts per persistent store coordinator, so you can run into conflicts at the persistent store coordinator level. Changes are per-context, and another context may have introduced conflicting changes. And Core Data even allows for completely separate stacks both accessing the same SQLite database file on disk. That can obviously also lead to conflicts (i.e. one context trying to update a value on an object that was deleted by another context). Another reason why a save can fail is validation. Core Data supports complex validation policies for objects. It's an advanced topic. A simple validation rule could be that the `title` of an `Item` must not be longer than 300 characters. But Core Data also supports complex validation policies across properties.

## Final Words
## 结束语

If Core Data seems daunting, that's most likely because its flexibility allows you to use it in very complex ways. As always: try to keep things as simple as possible. It will make development easier and save you and your user from trouble. Only use the more complex things such as background contexts if you're certain they will actually help.
如果 Core Data 看起来让人害怕，这最有可能是因为它的灵活性允许你可以通过非常复杂的方法使用它。始终记住：尽可能保持简单。它会让开发变得更容易，并且把你和你的用户从麻烦中拯救出来。除非你确信它会带来帮助，才去使用更复杂的东西，比如说是 background contexts。

When you're using a simple Core Data stack, and you use managed objects the way we've tried to outline in this issue, you'll quickly learn to appreciate what Core Data can do for you, and how it speeds up your development cycle.
当你开始使用一个简单的 Core Data 堆栈，并且使用我们在这篇文章中讲到的知识吧，你将很快会真正体会到 Core Data 能为你做什么，并且学到它是怎么缩短你开发周期的。

