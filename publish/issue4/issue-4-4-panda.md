本文我们将会更加深入探讨Core Data 的 `models` 以及 `managed object` 的类 。本文绝不是对 Core Data 的简单概述，而是在实际运用中鲜为人知或不易记忆却可以发挥奇效的那一部分的合集。如果你需要的是更详细的概述，那么我推荐你去看 [“Apple's Core Data Programming Guide”][1]。

## 数据模型

Core Data数据模型（储存在 *.xcdatamodel 文件里）中定义了数据类型 (在 Core Data 里的“实体”中)。大多数情况下，我们更偏向通过 Xcode 的图形界面去定义一个数据模型，但同样我们可以使用纯代码去完成这个工作。首先，你需要创建一个 [`NSManagenObjectModel`][2] 对象，然后创建 [`NSEntitiyDesciption`][3] 对象来表示一组实体，该实体通过 [`NSAttributeDescription`][4] 和 [`NSRelationshipDescription`][5] 对象来表示实体属性和实体之间的关系。虽然你几乎不需要去处理这些事情，但是知道这些类总有好处。

### 属性 (Attributes)

一旦就创建了某个实体，我们就需要去定义该实体的一些属性。属性定义是非常简单的，但是接下来我们要深入的研究属性的某些特性。

#### 默认的/可选的

每个属性可被定义成可选的或者非可选（必须）的。如果一个被变更的对象的非可选属性没有设置的话，那么在存储时将会失败。同时，我们可以为每一个属性设置默认值。没有人阻止我们使用一个可选的属性并且给它赋一个默认的值，但是当你进行深入思考的时候，你会发现这么做并没有什么意义甚至引起混淆。所以，我们建议永远不要使用带有默认值的可选属性。

#### 瞬态 Transient

另一个经常被忽视的属性的特性选项是它的 `transient` 。被声明为 `transient` 的属性除了不被持久化到本地之外，其余所有行为都与正常属性类似。这也意味着可以对它们进行校验，撤销管理，故障处理等操作。当你将更复杂的数据模型逻辑映射到 `managed object subclasses` 的时候， `transient` 属性将会发挥出它的优势。我们将会在后面继续讨论这个特性，以及我们更倾向于使用 `transient` 属性而非实例变量的原因。

<a name="indexes"> </a>
#### 索引

如果你以前使用过关系数据库，那么你对索引应该并不陌生。如果没有，你可以认为属性的索引可以提供一种大幅提高检索速度的方法。但是有利有弊，[索引][6]在提高读取速度的同时却降低了写入速度，因为每当数据变更的时候，索引就需要进行相应的更新。

当把一个属性设置为 `indexed` 时，它将在 `SQLite` 中所对应的表的列中建立索引。我们能够为任何属性创建索引，但是请留意对写性能的潜在影响。Core Data 当然也支持创建复合索引（在 entity 的 检查器的 Indexs 部分中），就像那些横跨了多个属性的索引。当你在多属性的场景下使用复合索引来获取数据时可以对检索效率进行提升。Daniel 有一个使用复合索引获取数据的例子：[fetching data][7]。

#### 标量类型

Core Data 支持包括整形、浮点型、布尔型在内的许多常见数据类型。但是数据模型编辑器默认以 NSNumber 生成这些属性并内置于 `managed object` 子类中。这使得我们经常会在程序代码中用调用 `floatValue`，`boolValue`，`integerValue` 等 `NSNumber` 的方法。

当然，我们同样可以直接设置这些属性为想要的标量类型，如 `int64_t`，`float_t` 或是 `BOOL`，它们一样可以正常运作。Xcode甚至在生成 `NSManagedObject`（原始数据类型使用标量属性）对话框内有一个小选择框可以为你进行强类型匹配。
取而代之，不再会是：

	@property (nonatomic, strong) NSNumber *myInteger;

而会用如下声明替换：

	@property (nonatomic) int64_t myInteger;

这就是我们在 Core Data 中进行获取和保存标量类型所需要做的全部。在文档中，仍然规定 Core Data 将不能自动的为标量生成存取方法，现在看来文档似乎有点过时了。

#### 存储其他类型对象

Core Data 并没有约束我们只能对预定义类型进行存储。事实上，对于任何遵守 [`NSCoding`][8] 协议的对象甚至到任何包含了大量功能的结构对象，我们都可以对其进行轻松的存储。

我们可以通过使用 [`transformable attributes`][9] 来存储遵守 `NSCoding` 协议的对象。我们需要做的仅仅是在下拉菜单中选择 “Transformable” 选项。如果你生成了一个相应的 `managed object subclasses`，你就会看到一个类似如下的属性声明：

	@property (nonatomic, retain) id anObject;

我们可以手动将对象原有的 `id` 类型修改成任意我们想要储存的类型来使编辑器进行强类型检查。然而在使用 transformable 属性的时候我们会遇到一个陷阱：如果我们想使用默认转换器（最常用的），我们必须不能为它指定名字。甚至指定默认转换器名字为其原始名字（`NSKeyedUnarchiveFromDataTransformerName`）都将会导致[不好的事情][9]。

不仅限于此，我们还可以创建自定义的值转换器并使用它们去存储任意的对象类型。只要我们能够把要存储的东西转化为可支持的基本类型，我们就能存储它。为了储存比如结构体这种不支持的非对象的类型，基本的解决方式是创建一个未定义类型的 `transient` 属性和一个持久化的已支持类型的影子属性。然后，重写 `transient` 属性的存取方法，将值转化为上述的持久化类型。这是很重要的，因为这些存取方法需要遵从 `KVC/KVO`，同时还需要考虑到 Core Data 原始存取方法。请阅读苹果指南中的 [`non-standard persistent attributes`][10](非标准的持久属性)这一部分的[自定义代码][11]。

### 抓取属性 (Fetched Properties)

在多个持久化存储之间创建关系的时候我们经常会用到 `fetched` 属性。由于使用多个持久化存储本身已经是非常不常见、且高级的案例，因此 `fetched` 属性几乎也不会被使用。

当我们获取一个抓取属性的时候，Core Data 会在后端执行一个抓取请求并且缓存抓取结果。我们可以直接在 Xcode 中数据模型编辑器里通过指定目标实体类型和断言来对抓取请求进行配置。这里的断言是动态的而非静态的，其通过 $FETCH_SOURCE 和 $FETCHED_PROPERTY 两个变量在程序运行态进行配置。更多细节可以参考[苹果官方文档][12]。

### 关系 (Relationships)

实体间的关系应该总是被定义成双向的。这给予了 Core Data 足够的信息为我们全面管理类图。尽管定义双向的关系不是一个硬性要求，但我还是强烈建议这么去做。

如果你对实体之间的关系很了解，你也能将实体定义成单向的关系，Core Data 不会有任何警告。但是一旦这么做了，你就必须承担很多正常情况理应由 Core Data 管理的一些职责，包括确认图形对象的一致性，变化跟踪和撤销管理。举一个简单的例子，我们有“书”和“作者”两个实体，并设置了一个书到作者的单项关系。当我们删除了“作者”的时候，和这个“作者”有关联的“书”将无法收到这个“作者”被删除的消息。此后，我们仍旧可以使用这本书“作者”的关系，只是我们将会得到一个指向空的错误。

很明显单向关系带来的弊端绝对不会是你想要的。双向关系化可以让你摆脱这些不必要的麻烦。

### 数据类型设计

在为 Core Data 设计数据模型的时候，一定要牢记 Core Data 不是一个关系数据库。因此，我们在设计数据模型的时候只需要着眼于数据将要如何组织和展示即可，而不是像设计数据库表一样来进行设计。

在需要对某一数据进行展示的时候避免大规模的抓取该数据的关系数据，从这一点看通常数据模型的[非规范化][13]是有其价值的。再举个例子，假如现有一个“作者”实体中有一个一对多的关系指向“书”实体的话，如果我们只需要展示作者写的书的数量的话，再保存一个数字会是一个很好的做法。

这是因为，假设我们需要展示一张作者和其对应作品数量的表。如果取得每个作者名下作品的数量这条数据只能通过统计作者实体关联的书实体的数量来获取，则每一个作者单元格中必须进行一次抓取请求操作。这样做性能不佳。我们可以使用 [`relationshipKeyPathsForPrefetching`][14] 对书对象进行预抓取，但当保存的书数据量大的时候，这同样无法达到理想状态。所以，如果我们为每个作者添加一个属性来管理书籍数量，那么，一切所需信息都将在请求抓取作者信息的时候一并获得。

当然，为保持冗余数据的同步，非规范化也会带来额外的性能开销。我们需要根据实际情况来权衡是否需要这么做。有时这么做不会有什么感觉，但有时其带来的麻烦会让你头疼不已。这样做非常依赖于特定的数据模型，比如应用有没有需要去与后台交互，或者是否要在多个客户端之间使用点对点的形式同步数据。

通常情况下，这个数据模型已经被某个后台服务定义过了，我们可能只需要将数据模型复制到应用程序即可。然而，即使在这种情况下，我们仍有权利在客户端对数据模型进行一些修改，就比如我们可以为后台数据模型定义一个清晰的映射。再拿“书”和“作者”举例，仅在客户端执行向作者实体添加一个作品数量属性的小操作以实现检索性能的优化而无需通知服务器。如果我们做了一些本地修改或从服务器接收到了新的数据，我们需要更新这些属性并且保持其余的数据同步。

实际情况往往复杂的多，但就像上面的简单优化，却能缓解在处理标准关系数据库数据模型的性能时的瓶颈问题。

<a name="entity-vs-class-hierarchy"> </a>
### 实体层级 vs 类层级

Managed object models 可以允许创建实体层级，即我们可以指定一个实体继承另外一个实体。虽然，实体间可以通用一些都有的属性听起来不错，不过在实践中我们几乎不会这么去做。

这一切背后发生的事情其实是，Core Data 将所有带有相同父实体的实体存储在同一张表中。这样做会迅速的建成一个含有大量属性的数据表，并使性能降低。通常情况下，我们创建实体层级的目的仅仅是为了创建一个类层级，从而可以在实体基类中实现代码并分享到多个子类实体中。当然，我们还有更好的方法来实现这个需求。

实体层级与 `NSManagedObject` 父类层级是*相互独立*的。换言之，我们不需要去为了已有的实体层级而去创建一个类层级。

让我们继续用“作者”和“书”举例。他们两者间会有一些共有的字段，比如ID（`identifier`），创建时间(`createdAt`)，修改时间(`changedAt`)。我们可以为这个例子构建如下的结构：

	Entity hierarchy            Class hierarchy
	----------------            ---------------
	
	   BaseEntity                 BaseEntity
	    |      |                   |      |
	 Authors  Books             Authors  Books

然而，我们可以压缩实体的层级关系而保持类的层级关系不变。

	 Entity hierarchy            Class hierarchy
	 ----------------            ---------------
	
	  Authors  Books               BaseEntity
	                                |      |
	                             Authors  Books

这个类可能会被这样声明：

	 @interface BaseEntity : NSManagedObject
	 @property (nonatomic) int64_t identifier;
	 @property (nonatomic, strong) NSDate *createdAt;
	 @property (nonatomic, strong) NSDate *changedAt;
	 @end
	
	 @interface Author : BaseEntity
	 // Author specific code...
	 @end
	
	 @interface Book : BaseEntity
	 // Book specific code...
	 @end
 
这样做的好处是我们能够将共同的代码移动到父类中，同时避免了将所有实体放到放到一个表中引起的性能消耗。虽然我们在 Xcode 的管理对象生成器中无法根据实体层级来创建类层级，但是花费极少的代价去手动的去创建管理对象类将会给我们巨大好处，具体我们会在下面介绍。

### 配置与抓取请求模板

所有使用过 Core Data 的人肯定都与数据模型的“实体-模型”方面的功能打过交道。但是数据模型还有两个相对少见少用的领域：配置 (configurations) 和 抓取请求模板 (fetch request templates)。

配置用来定义是哪个实体需要保存在哪个持久化存储。持久化存储协调器使用 [`addPersistentStoreWithType:configuration:URL:options:error:`][15] 来添加持久化存储，其中配置参数定义了需要映射的持久化存储。在目前所有的应用场景中，我们只会使用一个持久化储存，因此不用考虑处理多个配置的情况。当创建好一个持久化存储的时候默认的配置就已经为我们配置好了。其实还是有多存储的极为少见的实例的，本话题的 [导入大数据集][16] 一文中对其进行了概述。

正如抓取请求模板的名字所暗示的那样：预定义的抓取请求以 `managed object model` 的形式存储，需要时可以执行 [`fetchRequestFormTemplateWithName:substitutionVariables`][17] 操作从而方便地使用。我们可以使用 Xcode 中数据模型编辑器或者代码来定义这些模板。虽然 Xcode 的编辑器还不能够支持 `NSFetchRequest` 的所有功能。

老实说我曾经有一段痛苦的经历去说服别人使用抓取请求模板。其实一个好处是抓取请求的断言将会被预先解析好，从而当你执行一条新的抓取请求的时候该步骤不用每次执行。虽然几乎没有什么联系，任何频繁的抓取都会使我们陷入麻烦之中。假如你在找一个定义你抓取请求的地方（你不应该将它们定义在视图控制器中），也许考虑将它们储存在于 `managed object model` 中将会是个不错的选择。

<a name="managed-objects"> </a>

## Managed Objects

任一使用 Core Data 的应用其核心就是 `managed objects`。`managed objects` 依赖 `managed object context` 而存在并反映我们的数据。`managed objects` 理应在程序中至少穿透 model-controller 的壁垒，甚至会穿透 controller-view 的壁垒，而被分发。尽管后者颇具争议但是我们可以[更好的通过一个例子][18]来进行抽象理解：定义一个协议，遵守该协议的对象可以被某个视图使用，或者是通过在视图的类别中实现配置方法来桥接数据对象与特定的视图之间的间隙。

不管怎么说我都不能将 `managed objects` 限定于数据层，当我们想分发数据的时候，应该将它们及时抓取出来并放入不同结构中去。`managed objects` 是 Core Data 应用中的一等公民，所以我们也要将它们用得适得其所。举个例子，`managed objects` 应该在两个视图控制器间进行传递，并为它们提供所需要的数据。

为了获取 `managed objects context` 我们经常在代码中看到如下代码：

	NSManagedObjectContext *context = 
	  [(MyApplicationDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
  
如果你已经给视图控制器传递了一个模型对象，可以直接通过对象来获取上下文：

	NSManagedObjectContext *context = self.myObject.managedObjectContext;

这么做移除了 `application delegate` 的隐性依赖并且增强了代码可读性以及更便于测试。

### 使用 Managed object 子类

类似的，`managed object` 的子类也应当这样被使用。我们可以在这些类中实现自定义业务逻辑，验证逻辑和辅助方法，同时创建层级以便于剥离出共同的代码放进父类中。后者的实现非常简单，因为类的层级和实体层级的解耦合在上面已经提过了。

你可能想知道，当 Xcode 在重新生成文件的时候总是覆盖它们，那么如何在`managed object` 子类中实现自定义代码。其实，这个答案十分简单，不要使用 Xcode 生成它们即可。如果你仔细想想，在这些类中被生成的代码很琐碎并且你自己也很容易能够实现，当然你也可以只生成一次然后保证手动更新就好。因为生成的只是一堆属性的声明。

当然还有一些其他的解决方案，如将自定义代码放到类别中，或者使用类似 [mogenerator][19] 这样的工具。mogenerator 可以为每个实体和子类创建一个可以支持用户代码的基础类。但是，上面的所有解决方案都不能根据实体层级灵活的创建类层级。所以我们还是建议你手动创建这些类，即使你需要自己去书写几行繁琐的代码。

<a name="ivars-in-managed-object-classes"> </a>
#### Managed Object 子类中的实例变量

当我们开始使用 `managed object` 子类来实现业务逻辑的时候，我们可能会需要创建一些实例变量来缓存计算结果之类的东西。为了方便的达到这个目的，我们可以使用 `transient` 。因为 `managed object` 的生命周期与一般的对象有一点不同。Core Data 经常会对那些不再需要的对象执行 [faults][20] 操作。如果我们要使用实例变量，就必须将其手动加入进程并且释放这些实例变量。然而，当我们换成 `transient` 属性，这一切都不再需要我们去做了。

<a name="creating-objects"> </a>
#### 创建新对象

在模型类中可以加入一个类方法来将新的对象插入到 managed object 上下文中，这是在模型类中添加有用辅助方法的一个好例子。Core Data 创建新对象的 API 并不是非常的直观：

	Book *newBook = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:context];

万幸的是，我们能够轻易地在我们的子类中以一个优雅的方式解决这个问题：

	@implementation Book
	// ...
	
	+ (NSString *)entityName
	{
	    return @"Book"
	}
	
	+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context
	{
	    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName]
	                                         inManagedObjectContext:context];
	}
	@end

现在，创建一个“书”对象就简单得多。

	Book *book = [Book insertNewObjectIntoContext:context];

当然，如果我们将实际模型类从共同的父类中继承下来，我们就应当将 `insertNewObjectIntoContext:` 和 `entityName` 这两个方法移动到父类中。然后每个子类里面就只需要去重写 `entityName` 就可以了。

#### 一对多关系赋值

如果你用 Xcode 生成了一个含有一对多关系的 `managed object` 子类的话，系统将会为我们创建在这个关系中增删对象的方法。

	- (void)addBooksObject:(Book *)value;
	- (void)removeBooksObject:(Book *)value;
	- (void)addBooks:(NSSet *)values;
	- (void)removeBooks:(NSSet *)values;

我们有一个更加优雅的方法来替代这些赋值方法，尤其是在我们没有生成 `managed object` 子类的情况下。我们可以简单的使用 [`mutableSetValueForKey:`][21] 方法获取相关的可变对象的集合（或者对于有序关系的话，使用[`mutableOrderedSetValueForKey:`][22]）。这样可以封装成为一个更简单的存取方法：

	- (NSMutableSet *)mutableBooks
	{
	    return [self mutableSetValueForKey:@"books"];
	}

然后我们可以如同使用一般的集合那样使用这个可变集合。Core Data 将会捕捉到这些变换，并且帮我们处理剩下的事情。

	Book *newBook = [Book insertNewObjectIntoContext:context];
	[author.mutableBooks addObject:newBook];

<a name="validation"> </a>
#### 验证

Core Data 支持多种数据验证的方式。Xcode 的数据模型编辑器让我们为属性制定一些基本的需求，就像一个字符串的最大和最小长度，或者是一对多关系中最多和最少的对象个数。除此之外，使用代码我们可以做更多的事情。

文档中 [“Managed Object Validation”][23] 一节对本主题有更加深入的介绍。Core Data 通过实现 `validate<Key>:error:` 方法支持属性层级验证，以及通过 [`validateForInsert:`][24], [`validateForUpdate:`][25]，和 [`validateForDelete:`][26] 方法进行属性内验证。验证将会在保存前自动进行，当然我们也可以在属性层使用 [`validateValue:forKey:error:`][27]方法手动触发。

## 总结

Core Data 应用依赖于数据模型与模型对象。我们鼓励大家不要去直接使用便利的封装，而是去拥抱 `managed object` 子类和对象。当使用 Core Data 的时候，值得非常注意的是要十分清楚发生了什么，否则的话一旦你的应用变得复杂的时候，事情就会很糟糕了。

我们希望已阐述的几个简单的技术可以使你更容易的使用 `managed objects`。另外我们还初步了解了几个非常高级的特性，以便大家在使用数据对象的时候对我们能做到些什么有个大致的概念。请谨慎地运用这些技术，因为到头来其实往往还是简单才是王道。

  [1]: https://developer.apple.com/library/mac/documentation/cocoa/Conceptual/CoreData/cdProgrammingGuide.html#//apple_ref/doc/uid/TP30001200-SW1
  [2]: https://developer.apple.com/library/ios/documentation/cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectModel_Class/Reference/Reference.html
  [3]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSEntityDescription_Class/NSEntityDescription.html
  [4]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSAttributeDescription_Class/reference.html
  [5]: https://developer.apple.com/library/ios/documentation/cocoa/Reference/CoreDataFramework/Classes/NSRelationshipDescription_Class/NSRelationshipDescription.html
  [6]: http://en.wikipedia.org/wiki/Database_index
  [7]: http://objccn.io/issue-4-6
  [8]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Protocols/NSCoding_Protocol/Reference/Reference.html
  [9]: https://developer.apple.com/library/ios/documentation/cocoa/conceptual/CoreData/Articles/cdNSAttributes.html#//apple_ref/doc/uid/TP40001919-SW7
  [10]: https://developer.apple.com/library/ios/documentation/cocoa/conceptual/CoreData/Articles/cdNSAttributes.html#//apple_ref/doc/uid/TP40001919-SW1
  [11]: https://developer.apple.com/library/ios/documentation/cocoa/conceptual/CoreData/Articles/cdNSAttributes.html#//apple_ref/doc/uid/TP40001919-SW8
  [12]: https://developer.apple.com/library/ios/documentation/cocoa/conceptual/CoreData/Articles/cdRelationships.html#//apple_ref/doc/uid/TP40001857-SW7
  [13]: http://en.wikipedia.org/wiki/Denormalization
  [14]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSFetchRequest_Class/NSFetchRequest.html#//apple_ref/occ/instm/NSFetchRequest/relationshipKeyPathsForPrefetching
  [15]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSPersistentStoreCoordinator_Class/NSPersistentStoreCoordinator.html#//apple_ref/occ/instm/NSPersistentStoreCoordinator/addPersistentStoreWithType:configuration:URL:options:error:
  [16]: http://objccn.io/issue-4-5
  [17]: https://developer.apple.com/library/ios/documentation/cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectModel_Class/Reference/Reference.html#//apple_ref/occ/instm/NSManagedObjectModel/fetchRequestFromTemplateWithName:substitutionVariables:
  [18]: http://objccn.io/issue-1-2
  [19]: https://github.com/rentzsch/mogenerator
  [20]: https://developer.apple.com/library/ios/documentation/cocoa/conceptual/CoreData/Articles/cdFaultingUniquing.html#//apple_ref/doc/uid/TP30001202-CJBDBHCB
  [21]:https://developer.apple.com/library/mac/documentation/cocoa/Reference/Foundation/Protocols/NSKeyValueCoding_Protocol/Reference/Reference.html#//apple_ref/occ/instm/NSObject/mutableSetValueForKey:
  [22]:https://developer.apple.com/library/mac/documentation/cocoa/Reference/Foundation/Protocols/NSKeyValueCoding_Protocol/Reference/Reference.html#//apple_ref/occ/instm/NSObject/mutableOrderedSetValueForKey:
  [23]:https://developer.apple.com/library/ios/documentation/cocoa/conceptual/CoreData/Articles/cdValidation.html#//apple_ref/doc/uid/TP40004807-SW1
  [24]:https://developer.apple.com/library/ios/DOCUMENTATION/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObject_Class/Reference/NSManagedObject.html#//apple_ref/occ/instm/NSManagedObject/validateForInsert:
  [25]:https://developer.apple.com/library/ios/DOCUMENTATION/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObject_Class/Reference/NSManagedObject.html#//apple_ref/occ/instm/NSManagedObject/validateForUpdate:
  [26]: https://developer.apple.com/library/ios/DOCUMENTATION/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObject_Class/Reference/NSManagedObject.html#//apple_ref/occ/instm/NSManagedObject/validateForDelete:
  [27]: https://developer.apple.com/library/ios/DOCUMENTATION/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObject_Class/Reference/NSManagedObject.html#//apple_ref/occ/instm/NSManagedObject/validateValue:forKey:error:

---

原文：[Data Models and Model Objects](http://www.objc.io/issue-4/core-data-models-and-model-objects.html#ivars-in-managed-object-classes)

译文：[Core Data 中的模型与对象](http://iosinit.com/?p=949)
