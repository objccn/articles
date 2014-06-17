It's well known in the field of architecture that we shape our buildings, and afterward our buildings shape us. As all programmers eventually learn, this applies just as well to building software.

众所周知建筑领域流行这样一句话，“我们虽然在营造建筑，但建筑也会重新塑造我们”。正如所有开发者最终领悟到的，这句话同样适用于构建软件。


It's important to design our code so that each piece is easily identifiable, has a specific and obvious purpose, and fits together with other pieces in a logical fashion. This is what we call software architecture. Good architecture is not what makes a product successful, but it does make a product maintainable and helps preserve the sanity of the people maintaining it!

编写代码至关重要，其过程需要使每一部分容易被识别，赋有一个特定而明显的目，,并与其他部分在逻辑关系中完美契合。这就是我们所说的软件架构。好的架构不仅让一个产品成功投入使用，还可以让产品具有可维护性，并让人不断头脑清醒的对它进行维护！

In this article, we will introduce an approach to iOS application architecture called [VIPER](http://mutualmobile.github.io/blog/2013/12/04/viper-introduction/). VIPER has been used to build many large projects, but for the purposes of this article we will be showing you VIPER by building a to-do list app. You can follow along with the example project [here on GitHub](https://github.com/objcio/issue-13-viper):

在这篇文章中，我们介绍了一种称之为 [VIPER](http://mutualmobile.github.io/blog/2013/12/04/viper-introduction/) 的 iOS 应用架构的方式。VIPER 已经在很多大型的项目上成功实践，但是出于本文的目的我们将通过一个待办事项清单 [to-do app] 来介绍 VIPER 。你可以在 [GitHub](https://github.com/objcio/issue-13-viper) 上关注这个项目。

<video style="display:block;max-width:316px;height:auto;border:0;" poster="{{site.images_path}}/issue-13/2014-06-07-viper-screenshot.png" controls="1">
  <source src="http://img.objccn.io//issue-13/2014-06-07-viper-preview.mp4"></source>
</video>

## What is VIPER?  什么是 VIPER？
Testing was not always a major part of building iOS apps. As we embarked on a quest to improve our testing practices at [Mutual Mobile](https://github.com/mutualmobile/), we found that writing tests for iOS apps was difficult. We decided that if we were going to improve the way we test our software, we would first need to come up with a better way to architect our apps. We call that method VIPER.

测试永远不是构建 iOS 应用的主要部分。当我们 ([Mutual Mobile](https://github.com/mutualmobile/)) 着手改善我们的测试实践，不难发现给 iOS 应用写测试代码非常困难，因此如果想要设法改变测试的现状，我们首先需要一个更好的方式来架构应用，我们称之为 VIPER。

VIPER is an application of [Clean Architecture](http://blog.8thlight.com/uncle-bob/2012/08/13/the-clean-architecture.html) to iOS apps. The word VIPER is a backronym for View, Interactor, Presenter, Entity, and Routing. Clean Architecture divides an app’s logical structure into distinct layers of responsibility. This makes it easier to isolate dependencies (e.g. your database) and to test the interactions at the boundaries between layers:

VIPER 是一个创建 iOS 应用简明构架的程序。VIPER 可以理解为视图，交互器，主持人，实体以及路由。简明架构将一个应用程序的逻辑结构划分为不同的责任层。这使得它更容易隔离依赖项(如数据库)和测试边界处各层间的交互项:
<img alt="VIPER stands for View Interactor Presenter Entity Routing." src="http://img.objccn.io/issue-13/2014-06-07-viper-intro.jpg">

Most iOS apps are architected using MVC (model–view–controller). Using MVC as an application architecture can guide you to thinking every class is either a model, a view, or a controller. Since much of the application logic does not belong in a model or view, it usually ends up in the controller. This leads to an issue known as a [Massive View Controller](https://twitter.com/Colin_Campbell/status/293167951132098560), where the view controllers end up doing too much. [Slimming down](http://www.objc.io/issue-1/lighter-view-controllers.html) these massive view controllers is not the only challenge faced by iOS developers seeking to improve the quality of their code, but it is a great place to start.

大部分 iOS 应用利用 MVC 构建，使用 MVC 应用程序架构可以引导你将每一个类看做一个模型，视图或控制器。但貌似大部分应用程序逻辑不会存在于模型或视图，因此通常最终总是实现在控制器。这就导致一个问题称为[重量级视图控制器](https://twitter.com/Colin_Campbell/status/293167951132098560)，在这里，视图控制器收尾工作太多。[缩水](http://www.objc.io/issue-1/lighter-view-controllers.html)这些重量级视图控制器并不是 iOS 开发者寻求提高代码的质量所要面临的唯一挑战，但至少这是一个伟大的开端。

VIPER's distinct layers help deal with this challenge by providing clear locations for application logic and navigation-related code. With VIPER applied, you'll notice that the view controllers in our to-do list example are lean, mean, view controlling machines. You'll also find that the code in the view controllers and all of the other classes is easy to understand, easier to test, and as a result, also easier to maintain.

VIPER 的不同层提供了明确的程序逻辑以及导航控制代码来应对这个挑战，利用 VIPER ，你会注意到在我们的待办事项示例清单中的视图控制器是基于精益，意义明确的视图控制。你也会发现视图控制器中代码和所有的其他类很容易理解，容易测试，也更易维护。

## Application Design Based on Use Cases 用例应用设计
Apps are often implemented as a set of use cases. Use cases are also known as acceptance criteria, or behaviors, and describe what an app is meant to do. Maybe a list needs to be sortable by date, type, or name. That's a use case. A use case is the layer of an application that is responsible for business logic. Use cases should be independent from the user interface implementation of them. They should also be small and well-defined. Deciding how to break down a complex app into smaller use cases is challenging and requires practice, but it's a helpful way to limit the scope of each problem you are solving and each class that you are writing.

应用总是一些用户用例的集合。用例也被称为验收标准，或行为集以及描述应用的用途。清单可以根据时间，类型以及名字排序，这就是一个用例。用例是应用程序中用来负责业务逻辑的一层，应独立于用户界面的实现，同时要足够小并有效定义。决定如何将一个复杂的应用分解成较小的用例非常具有挑战性，并且需要长期实践，但这却是限制你解决的问题及完成的每个类的内容范围的有效途径。

Building an app with VIPER involves implementing a set of components to fulfill each use case. Application logic is a major part of implementing a use case, but it's not the only part. The use case also affects the user interface. Additionally, it's important to consider how the use case fits together with other core components of an application, such as networking and data persistence. Components act like plugins to the use cases, and VIPER is a way of describing what the role of each of these components is and how they can interact with one another.

利用 VIPER 建立一个应用需要实施一组套件来满足所有的用例，应用逻辑是实现用例的主要组成部分，但却不是唯一。用例也会影响用户界面。另一个重要的方面，是要考虑用例如何与其他应用程序的核心组件相互配合，例如网络和数据持久性。组件就好比用例的插件，VIPER 则用来描述这些组件的作用是什么，如何相互影响。

One of the use cases or requirements for our to-do list app was to group the to-dos in different ways based on a user's selection. By separating the logic that organizes that data into a use case, we are able to keep the user interface code clean and easily wrap the use case in tests to make sure it continues to work the way we expect it to.

我们其中一个用例，或者说待办事项清单中其中的一个需求是可以基于用户的选择来分组。通过分离的逻辑将数据组织成一个用例，我们能够在测试时使用户界面代码保持干净，用例更易组装，从而确保它如我们预期的方式工作。

## Main Parts of VIPER VIPER 的主要部分
The main parts of VIPER are:

VIPER 的主要部分是：

- _View_: displays what it is told to by the Presenter and relays user input back to the Presenter.
- _Interactor_: contains the business logic as specified by a use case.
- _Presenter_: contains view logic for preparing content for display (as received from the Interactor) and for reacting to user inputs (by requesting new data from the Interactor).
- _Entity_: contains basic model objects used by the Interactor.
- _Routing_: contains navigation logic for describing which screens are shown in which order.

- 视图： 显示主持人的具体要求并将用户输入反馈主持人。
- 交互器：包含由用例指定的业务逻辑。
- 主持人：包含为显示（从交互器接受的内容）做的准备工作的相关视图逻辑，并对用户输入进行反馈（根据交互器的更新数据）。
- 实体：包含交互器运用的基本模型对象。
- 路由：包含用来描述银幕显示顺序的导航逻辑。

This separation also conforms to the [Single Responsibility Principle](http://www.objectmentor.com/resources/articles/srp.pdf). The Interactor is responsible to the business analyst, the Presenter represents the interaction designer, and the View is responsible to the visual designer.

这种分隔形式同样遵循[单一责任原则](http://www.objectmentor.com/resources/articles/srp.pdf)。交互器负责业务分析的部分，主持人代表交互设计师，而视图就像视觉设计师。

Below is a diagram of the different components and how they are connected:
以下则是不同组件的相关图解，并展示了他们之间是如何关联的：

<img alt="VIPER breaks down an app into different components based around use cases, including components that create the user interface and the logic that powers it." src="http://img.objccn.io/issue-13/2014-06-07-viper-wireframe.png">

While the components of VIPER can be implemented in an application in any order, we've chosen to introduce the components in the order that we recommend implementing them. You'll notice that this order is roughly consistent with the process of building an entire application, which starts with discussing what the product needs to do, followed by how a user will interact with it.

当 VIPER 的组件在程序中可以以任何形式实现的时候，我们已经选择介绍那些我们建议的实现进程的相关组件。 你会注意到这个顺序与构建整个应用的进程大致符合，这将引发有关产品所需的功能的热议及用户如何与之进行交互。

### Interactor 交互器
An Interactor represents a single use case in the app. It contains the business logic to manipulate model objects (Entities) to carry out a specific task. The work done in an Interactor should be independent of any UI. The same Interactor could be used in an iOS app or an OS X app.

交互器在应用中代表着一个独立的用例。它具有业务逻辑以操纵模型对象（实体）执行特定的任务。交互器中此项工作的完成必须独立与任何用户界面，同样的交互器可以同时运用于 iOS 应用或者 OS X 应用中。

Because the Interactor is a PONSO (Plain Old `NSObject`) that primarily contains logic, it is easy to develop using TDD.

由于交互器是一个 PONSO （纯旧式 'NSObject'）,它主要包含了逻辑，因此很容易开发使用 TDD 。

The primary use case for the sample app is to show the user any upcoming to-do items (i.e. anything due by the end of next week). The business logic for this use case is to find any to-do items due between today and the end of next week and assign a relative due date: today, tomorrow, later this week, or next week.

初级实验样板的主要用例是为了展示给用户所有的待办事项（比如任何截止于下周末的任务）。此类用例的业务逻辑主要是为了找出今天至下周末之间将要到期的待办事项然后分配一个相对的截止日期，比如今年，明天，这周末，或者下周。


Below is the corresponding method from the VTDListInteractor:

以下是来自 VTDListInteractor 的对应方法：

    - (void)findUpcomingItems
    {
        __weak typeof(self) welf = self;
        NSDate* today = [self.clock today];
        NSDate* endOfNextWeek = [[NSCalendar currentCalendar] dateForEndOfFollowingWeekWithDate:today];
        [self.dataManager todoItemsBetweenStartDate:today endDate:endOfNextWeek completionBlock:^(NSArray* todoItems) {
            [welf.output foundUpcomingItems:[welf upcomingItemsFromToDoItems:todoItems]];
        }];
    }

### Entity 实体
Entities are the model objects manipulated by an Interactor. Entities are only manipulated by the Interactor. The Interactor never passes entities to the presentation layer (i.e. Presenter).

实体是被交互器操纵的模型对象，并且他们只被交互器所操纵。交互器永远不会传输实体至表现层(比如说主持人)。

Entities also tend to be PONSOs. If you are using Core Data, you will want your managed objects to remain behind your data layer. Interactors should not work with NSManageObjects.

实体往往是 PONSOs。如果你使用核心数据，你会希望你的托管对象保持在你的数据层，而交互器不应与 NSManageObjects 一同工作。


Here is the Entity for our to-do item:

这就是为我们的待办事项服务的实体：

    @interface VTDTodoItem : NSObject
    
    @property (nonatomic, strong)   NSDate*     dueDate;
    @property (nonatomic, copy)     NSString*   name;
    
    + (instancetype)todoItemWithDueDate:(NSDate*)dueDate name:(NSString*)name;

    @end

Don’t be surprised if your entities are just data structures. Any application-dependent logic will most likely be in an Interactor.

不要诧异于你的实体仅仅是数据结构，任何一个依赖于逻辑的应用都有可能存在于交互器中。

### Presenter 主持人
The Presenter is a PONSO that mainly consists of logic to drive the UI. It knows when to present the user interface. It gathers input from user interactions so it can update the UI and send requests to an Interactor.

主持人是一个主要包含了运行用户界面的程序的 PONSO ，它总是知道何时呈现用户界面。基于其收集来自用户交互的输入功能，它可以时刻更新用户界面并向交互器发送需求。

When the user taps the + button to add a new to-do item, `addNewEntry` gets called. For this action, the Presenter asks the wireframe to present the UI for adding a new item:

当用户点击 “+” 键新建待办事项，`addNewEntry` 被调用。对于此项操作，主持人会要求线框图显示用户界面来增加新项目：

    - (void)addNewEntry
    {
        [self.listWireframe presentAddInterface];
    }

The Presenter also receives results from an Interactor and converts the results into a form that is efficient to display in a View.

主持人还会从交互器接收结果并将结果转换成另一种能够在视图中有效显示的形式。

Below is the method that receives upcoming items from the Interactor. It will process the data and determine what to show to the user:

下面是如何从交互器接受待办事项的过程，其中包含了处理数据的过程并确定展现给用户哪些内容：

    - (void)foundUpcomingItems:(NSArray*)upcomingItems
    {
        if ([upcomingItems count] == 0)
        {
            [self.userInterface showNoContentMessage];
        }
        else
        {
            [self updateUserInterfaceWithUpcomingItems:upcomingItems];
        }
    }

Entities are never passed from the Interactor to the Presenter. Instead, simple data structures that have no behavior are passed from the Interactor to the Presenter. This prevents any 'real work' from being done in the Presenter. The Presenter can only prepare the data for display in the View.

实体永远不会由交互器传输给主持人，而那些简单无行为的数据结构则会从交互器传输到主持人那里。这就防止了那些“真正的工作”在主持人那里进行，主持人只能负责准备那些在视图里显示的数据。

### View 视图
The View is passive. It waits for the Presenter to give it content to display; it never asks the Presenter for data. Methods defined for a View (e.g. LoginView for a login screen) should allow a Presenter to communicate at a higher level of abstraction, expressed in terms of its content, and not how that content is to be displayed. The Presenter does not know about the existence of `UILabel`, `UIButton`, etc. The Presenter only knows about the content it maintains and when it should be displayed. It is up to the View to determine how the content is displayed.

视图一般是被动的，它通常等待主持人下发需要显示的内容，而不会向其索取数据。根据视图定义的途径（例如登录界面的登录视图控件）将允许主持人在高度抽象的层次进行交流，依据其内容进行表达，而不是那些内容所显示的样子。主持人一般不知道 `UILabel`，`UIButton` 等的存在，它只知道其中包含的内容和何时需要显示。一般情况下都会根据视图来确定何时内容被显示。

The View is an abstract interface, defined in Objective-C with a protocol. A `UIViewController` or one of its subclasses will implement the View protocol. For example, the 'add' screen from our example has the following interface:

视图是一个抽象的界面，在 Objective-C 中根据协议被定义。一个`UIViewController`或者它的一个子类会实现视图协议。比如我们的示例中 “添加” 界面会有以下显示：

    @protocol VTDAddViewInterface <NSObject>

    - (void)setEntryName:(NSString *)name;
    - (void)setEntryDueDate:(NSDate *)date;

    @end

Views and view controllers also handle user interaction and input. It's easy to understand why view controllers usually become so large, since they are the easiest place to handle this input to perform some action. To keep our view controllers lean, we need to give them a way to inform interested parties when a user takes certain actions. The view controller shouldn't be making decisions based on these actions, but it should pass these events along to something that can.

视图和视图控制器同样会操纵用户界面和相关输入。这就不难理解为什么视图控制器总是这么大，他们往往处于最易操作输入指令来执行一些操作的位置。为了使视图控制器保持精益的状态，我们需要使他们在用户进行相关操作的时候可以有路径来通知相关部分。视图控制器不应当根据这些行为进行相关决定，但是他应当将发生的事件传递到能够做决定的部分。

In our example, Add View Controller has an event handler property that conforms to the following interface:

在我们的实例中，添加视图控制器有一个符合以下界面的事件处理程序属性：

    @protocol VTDAddModuleInterface <NSObject>
    
    - (void)cancelAddAction;
    - (void)saveAddActionWithName:(NSString *)name dueDate:(NSDate *)dueDate
    
    @end

When the user taps on the cancel button, the view controller tells this event handler that the user has indicated that it should cancel the add action. That way, the event handler can take care of dismissing the add view controller and telling the list view to update.

当用户点击取消键的时候，视图控制器告知此项事件处理程序用户已经表明它应该取消添加动作。这样一来，事件处理程序便可以注意到隐藏添加视图控制器和并告知列表视图进行更新。

The boundary between the View and the Presenter is also a great place for [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa). In this example, the view controller could also provide methods to return signals that represent button actions. This would allow the Presenter to easily respond to those signals without breaking separation of responsibilities.

视图和主持人之间边界处对于使用 [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) 同样是个好地方。在这个示例中，视图控制器同样会对返回信号也就是代表按钮动作提供路径，这就意味着主持人可以在不打破职责分离的情况下轻松回应那些信号。

### Routing 路由
Routes from one screen to another are defined in the wireframes created by an interaction designer. In VIPER, the responsibility for Routing is shared between two objects: the Presenter, and the wireframe. A wireframe object owns the `UIWindow`, `UINavigationController`, `UIViewController`, etc. It is responsible for creating a View/ViewController and installing it in the window. 

屏幕间的路径会在交互设计师创建的线框里进行定义。在 VIPER 中，路由是由两个部分来负责的：主持人和线框。一个线框对象包括 `UIWindow`，`UINavigationController`，`UIViewController` 等部分，它负责创建视图/视图控制器并将其安装在窗口中。

Since the Presenter contains the logic to react to user inputs, it is the Presenter that knows when to navigate to another screen, and which screen to navigate to. Meanwhile, the wireframe knows how to navigate. So, the Presenter will use the wireframe to perform the navigation. Together, they describe a route from one screen to the next. 

由于主持人能够对用户的输入进行有关的逻辑反应，它就拥有知晓何时导航至另一个屏幕以及具体是哪一个屏幕的能力。同样的，线框也有导航的功能。因此在两者结合起来的情况下，主持人可以使用线框来进行实现导航功能，从而描述一个路线从一个屏幕至另一个。

The wireframe is also an obvious place to handle navigation transition animations. Take a look at this example from the add wireframe:

线框是一个很重要的处理导航过渡动画的位置，我们可以看一看添加线框图这个例子：

    @implementation VTDAddWireframe
    
    - (void)presentAddInterfaceFromViewController:(UIViewController *)viewController 
    {
        VTDAddViewController *addViewController = [self addViewController];
        addViewController.eventHandler = self.addPresenter;
        addViewController.modalPresentationStyle = UIModalPresentationCustom;
        addViewController.transitioningDelegate = self;
    
        [viewController presentViewController:addViewController animated:YES completion:nil];
    
        self.presentedViewController = viewController;
    }
    
    #pragma mark - UIViewControllerTransitioningDelegate Methods
    
    - (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed 
    {
        return [[VTDAddDismissalTransition alloc] init];
    }
    
    - (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                      presentingController:(UIViewController *)presenting
                                                                          sourceController:(UIViewController *)source 
    {
        return [[VTDAddPresentationTransition alloc] init];
    }
    
    @end

The app is using a custom view controller transition to present the add view controller. Since the wireframe is responsible for performing the transition, it becomes the transitioning delegate for the add view controller and can return the appropriate transition animations. 

这个应用使用了一个定制的视图控制器过渡到添加视图控制器。由于线框负责执行这个转换过程，它就可以作为添加视图控制器的过渡代表，并且可以反馈适当的转换动画。

## Application Components Fitting in with VIPER 利用 VIPER 安装应用组件
An iOS application architecture needs to be considerate of the fact that UIKit and Cocoa Touch are the main tools that apps are built on top of. Architecture needs to coexist peacefully with all the components of the application, but it also needs to provide guidelines for how some parts of the frameworks are used and where they live.

一个 iOS 应用的构架需要考虑到 UIKit 和 Cocoa Touch 是应用建立的重要工具。架构需要和应用的所有组件都能够和平相处，但又需要为如何使用部分框架和他们具体在什么位置提供一些指导和建议。

The workhorse of an iOS app is `UIViewController`. It would be easy to assume that a contender to replace MVC would shy away from making heavy use of view controllers. But view controllers are central to the platform: they handle orientation change, respond to input from the user, integrate well with system components like navigation controllers, and now with iOS 7, allow customizable transitions between screens. They are extremely useful.

iOS 应用程序的主力是 `UIViewController`，我们不难想象一个竞争者来取代 MVC 可以避免制作大量的视图控制器。但视图控制器又是平台的核心：他们处理方向的变化，回应用户的指令，像导航控制器一样集成系统组件，而现在在 iOS 7 中又能实现自定义屏幕之间的转换，功能实在是太强大了。

With VIPER, a view controller does exactly what it was meant to do: it controls the view. Our to-do list app has two view controllers, one for the list screen, and one for the add screen. The add view controller implementation is extremely basic because all it has to do is control the view:

有了 VIPER，视图控制器便可以大显身手：控制视图。 我们的待办事项应拥有两个视图控制器，一个是列表视图，另一个是新建窗口，由于控制视图是它的首要任务，因此添加视图控制器的实现是非常基础的项目。

    @implementation VTDAddViewController
    
    - (void)viewDidAppear:(BOOL)animated 
    {
        [super viewDidAppear:animated];
    
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(dismiss)];
        [self.transitioningBackgroundView addGestureRecognizer:gestureRecognizer];
        self.transitioningBackgroundView.userInteractionEnabled = YES;
    }
    
    - (void)dismiss 
    {
        [self.eventHandler cancelAddAction];
    }
    
    - (void)setEntryName:(NSString *)name 
    {
        self.nameTextField.text = name;
    }
    
    - (void)setEntryDueDate:(NSDate *)date 
    {
        [self.datePicker setDate:date];
    }
    
    - (IBAction)save:(id)sender 
    {
        [self.eventHandler saveAddActionWithName:self.nameTextField.text
                                         dueDate:self.datePicker.date];
    }
    
    - (IBAction)cancel:(id)sender 
    {
        [self.eventHandler cancelAddAction];
    }
    
    
    #pragma mark - UITextFieldDelegate Methods
    
    - (BOOL)textFieldShouldReturn:(UITextField *)textField 
    {
        [textField resignFirstResponder];
    
        return YES;
    }
    
    @end

Apps are usually much more compelling when they are connected to the network. But where should this networking take place and what should be responsible for initiating it? It's typically up to the Interactor to initiate a network operation, but it won't handle the networking code directly. It will ask a dependency, like a network manager or API client. The Interactor may have to aggregate data from multiple sources to provide the information needed to fulfill a use case. Then it's up to the Presenter to take the data returned by the Interactor and format it for presentation.

应用一般在能够连网的时候更有说服力，但是究竟该在什么时候联网呢？又由谁来负责启动网络连接呢？这是典型的由交互器来启动网络连接操作的项目，但是它不会直接处理网络代码，一般会寻求一个依赖项，就像一个网管或者 API 客户。交互器可能聚合来自多个源的数据来提供所需的信息，从而完成一个用例。最终，就由主持人来采集交互器反馈的数据从而形成可显示的图像。

A data store is responsible for providing entities to an Interactor. As an Interactor applies its business logic, it will need to retrieve entities from the data store, manipulate the entities, and then put the updated entities back in the data store. The data store manages the persistence of the entities. Entities do not know about the data store, so entities do not know how to persist themselves.

数据库负责提供实体给交互器。正如交互器要运用其业务逻辑，它需要从数据存储中检索实体，操纵实体，然后将更新后的实体重置进数据库中。数据库不断管理着实体的持久性，实体却数据库全然不了解，正因如此，实体不知道如何让自己变得长久。
 

The Interactor should not know how to persist the entities either. Sometimes the Interactor may want to use a type of object called a data manager to facilitate its interaction with the data store. The data manager handles more of the store-specific types of operations, like creating fetch requests, building queries, etc. This allows the Interactor to focus more on application logic and not have to know anything about how entities are gathered or persisted. One example of when it makes sense to use a data manager is when you are using Core Data, which is described below. 

交互器同样不需要知道如何将实体变得更加长久，有时交互器更希望使用某类对象，我们称之为数据管理器，来促进其与数据库的交互作用。数据管理器可以操作更多的库内特定类型的操作，比如创建获取请求，构建查询等等。这就使交互器能够将更多的注意力放在应用逻辑上，而不必在了解如何聚集或持久化实体。一个实例可以说明使用数据管理器时间有意义的，那就是当你使用核心数据，可以产生以下描述：

Here's the interface for the example app's data manager:

这是示例应用程序的数据管理器的界面：

    @interface VTDListDataManager : NSObject
    
    @property (nonatomic, strong) VTDCoreDataStore *dataStore;
    
    - (void)todoItemsBetweenStartDate:(NSDate *)startDate endDate:(NSDate *)endDate completionBlock:(void (^)(NSArray *todoItems))completionBlock;
    
    @end

When using TDD to develop an Interactor, it is possible to switch out the production data store with a test double/mock. Not talking to a remote server (for a web service) or touching the disk (for a database) allows your tests to be faster and more repeatable.

当使用 TDD 来开发一个交互器时，是可以用一个测试双/模拟来代替生产数据库。不能与远程控制器说话（网络服务）或者接触磁盘（对于一个数据库）可以加快你测试的速度并加强其可重复性。

One reason to keep the data store as a distinct layer with clear boundaries is that it allows you to delay choosing a specific persistence technology. If your data store is a single class, you can start your app with a basic persistence strategy, and then upgrade to SQLite or Core Data later if and when it makes sense to do so, all without changing anything else in your application's code base.

将数据库保持为一个界限清晰的特定层的原因之一是它可以让你延迟选择一个特定的持久性技术。如果你的数据库是一个独立的类，那你就可以利用一个基本的持久性策略来启动你的应用，然后等到有意义的时候升级至SQLite 或者 Core Data，这样在你的应用代码库中就不需要改变任何东西。

Using Core Data in an iOS project can often spark more debate than architecture itself. However, using Core Data with VIPER can be the best Core Data experience you've ever had. Core Data is a great tool for persisting data while maintaining fast access and a low-memory footprint. But it has a habit of snaking its `NSManagedObjectContext` tendrils all throughout an app's implementation files, particularly where they shouldn't be. VIPER keeps Core Data where it should be: at the data store layer. 

在 iOS 的项目中使用核心数据经常比构架本身还容易引起更多争议。然而，利用 VIPER 来使用核心数据将是你前所未有的体验。当你可以保持快速存取和低内存占用的时候核心数据将是持久化数据的神器，但是有个怪癖，它会将触须般的 `NSManagedObjectContext`  延伸至你所有的应用实现文件中，特别是他们不该呆的地方。 VIPER 可以使核心数据待在正确的地方：数据存储层。

In the to-do list example, the only two parts of the app that know that Core Data is being used are the data store itself, which sets up the Core Data stack, and the data manager. The data manager performs a fetch request, converts the NSManagedObjects returned by the data store into standard PONSO model objects, and passes those back to the business logic layer. That way, the core of the application is never dependent on Core Data, and as a bonus, you never have to worry about stale or poorly threaded NSManagedObjects gunking up the works.

在待办事项示例中，应用仅有的两部分知道使用核心数据是数据存储本身建立了核心数据堆栈和数据管理器。数据管理器执行了一个获取请求，将数据库反馈的 NSManagedObjects 转换为标准的 PONSO 模型对象，最终传输回业务逻辑层。这样一来，应用程序核心将不再依赖于核心数据，可喜可贺的是，你也再也不用担心过期和螺纹不良的 NSManagedObjects 糟蹋了你的工作成果了。

Here's what it looks like inside the data manager when a request gets made to access the Core Data store:

这里是在请求得以访问核心数据存储时数据管理器呈现的样子：

    @implementation VTDListDataManager
    
    - (void)todoItemsBetweenStartDate:(NSDate *)startDate endDate:(NSDate*)endDate completionBlock:(void (^)(NSArray *todoItems))completionBlock
    {
        NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(date >= %@) AND (date <= %@)", [calendar dateForBeginningOfDay:startDate], [calendar dateForEndOfDay:endDate]];
        NSArray *sortDescriptors = @[];
    
        __weak typeof(self) welf = self;
        [self.dataStore
         fetchEntriesWithPredicate:predicate
         sortDescriptors:sortDescriptors
         completionBlock:^(NSArray* entries) {
             if (completionBlock)
             {
                 completionBlock([welf todoItemsFromDataStoreEntries:entries]);
             }
         }];
    }
    
    - (NSArray*)todoItemsFromDataStoreEntries:(NSArray *)entries
    {
        return [entries arrayFromObjectsCollectedWithBlock:^id(VTDManagedTodoItem *todo) {
            return [VTDTodoItem todoItemWithDueDate:todo.date name:todo.name];
        }];
    }
    
    @end

Almost as controversial as Core Data are UI Storyboards. Storyboards have many useful features, and ignoring them entirely would be a mistake. However, it is difficult to accomplish all of the goals of VIPER while employing all the features that a storyboard has to offer.

想核心数据一样极富争议的恐怕就是 UI 故事板了。故事板具有很多有用的功能，如果完全忽视它将会是一个错误，然而，调用故事版所能提供的所有功能来完成 VIPER 的所有目标仍然是很困难的。

The compromise we tend to make is to choose not to use segues. There may be some cases where using the segue makes sense, but the danger with segues is they make it very difficult to keep the separation between screens -- as well as between UI and application logic -- intact. As a rule of thumb, we try not to use segues if implementing the prepareForSegue method appears necessary.

我们所能做出的妥协就是选择不使用 segues 。有时候使用 segues 是有效的，但是使用 segues 的危险性在于他们很难原封不动的保持屏幕之间的距离，同时，和 UI 及应用逻辑之间的距离。一般来说，如果实现 prepareForSegue 方法显得必要，我们尽量不使用 segues。

Otherwise, storyboards are a great way to implement the layout for your user interface, especially while using Auto Layout. We chose to implement both screens for the to-do list example using a storyboard, and use code such as this to perform our own navigation:

另一方面，故事板是一个实现用户界面布局有效方法，特别是在使用自动布局的时候。我们选择在实现待办事项两个界面的实例中使用故事板，并且使用这样的代码来执行自己的导航操作。

    static NSString *ListViewControllerIdentifier = @"VTDListViewController";
    
    @implementation VTDListWireframe
    
    - (void)presentListInterfaceFromWindow:(UIWindow *)window 
    {
        VTDListViewController *listViewController = [self listViewControllerFromStoryboard];
        listViewController.eventHandler = self.listPresenter;
        self.listPresenter.userInterface = listViewController;
        self.listViewController = listViewController;
    
        [self.rootWireframe showRootViewController:listViewController
                                          inWindow:window];
    }
    
    - (VTDListViewController *)listViewControllerFromStoryboard 
    {
        UIStoryboard *storyboard = [self mainStoryboard];
        VTDListViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:ListViewControllerIdentifier];
        return viewController;
    }
    
    - (UIStoryboard *)mainStoryboard 
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle:[NSBundle mainBundle]];
        return storyboard;
    }
    
    @end

## Using VIPER to Build Modules 使用 VIPER 建立模块
Often when working with VIPER, you will find that a screen or set of screens tends to come together as a module. A module can be described in a few ways, but usually it's best thought of as a feature. In a podcasting app, a module might be the audio player or the subscription browser. In our to-do list app, the list and add screens are each built as separate modules.

一般在使用 VIPER 的时候，你会发现屏幕或一组屏幕倾向于聚在一起作为一个模块。模块可以以多种形式体现，但一般被认为是一种特性。在播客应用中，一个模块可能是音频播放器或订阅浏览器。然而在待办事项中，列表和添加屏幕都将作为单独的模块被建立。

There are a few benefits to designing your app as a set of modules. One is that modules can have very clear and well-defined interfaces, as well as be independent of other modules. This makes it much easier to add/remove features, or to change the way your interface presents various modules to the user.

将你的应用作为一组模块来设计有一些优势，其中之一就是模块可以有非常明确和定义良好的界面，并且独立于其他的模块，这就使增加或者移除特性变得更加简单，或者更加容易向用户展示各种可变的界面。

We wanted to make the separation between modules very clear in the to-do list example, so we defined two protocols for the add module. The first is the module interface, which defines what the module can do. The second is the module delegate, which describes what the module did. Example:

我们希望能否将待办事项中各模块之间分隔更加明确，这样就可以为添加模块定义两个协议。一个是模块界面，用来定义模块的功能；另一个则是模块指令，用来描述该模块做了什么。例如：

    @protocol VTDAddModuleInterface <NSObject>

    - (void)cancelAddAction;
    - (void)saveAddActionWithName:(NSString *)name dueDate:(NSDate *)dueDate;

    @end

    
    @protocol VTDAddModuleDelegate <NSObject>

    - (void)addModuleDidCancelAddAction;
    - (void)addModuleDidSaveAddAction;

    @end

Since a module has to be presented to be of much value to the user, the module's Presenter usually implements the module interface. When another module wants to present this one, its Presenter will implement the module delegate protocol, so that it knows what the module did while it was presented.

对于用户来说一个模型的展示不得不体现出它的价值，这样一来模型的主持人通常需要实现模型界面。当另一个模型想要展现在这个区域时，它的主持人就会实现模型的委托协议，从而得知模型在显示的时候进行过什么行为。

A module might include a common application logic layer of entities, interactors, and managers that can be used for multiple screens. This, of course, depends on the interaction between these screens and how similar they are. A module could just as easily represent only a single screen, as is shown in the to-do list example. In this case, the application logic layer can be very specific to the behavior of its particular module.

一个模块会包括一个常见的应用程序逻辑层的实体，交互器和管理器，这些通常可用于多个屏幕。当然，这同样取决于这些屏幕之间的交互器及他们的相似度。一个模型可以像在待办事项列表里面一样，简单的只代表一个屏幕。这样一来应用逻辑层对于特定模块的行为来说就变得极为特殊。

Modules are also just a good simple way to organize code. Keeping all of the code for a module tucked away in its own folder and group in Xcode makes it easy to find when you need to change something. It's a great feeling when you find a class exactly where you expected to look for it.

模块同样是组织代码的简便途径。将模块所有的编码都藏在其自身的文件夹中并集合成 Xcode 会更加容易发现你应当进行变化的时机。当你正满怀期待寻找一个类的时候它就出现的感觉真是无法形容的棒。

Another benefit to building modules with VIPER is they become easier to extend to multiple form factors. Having the application logic for all of your use cases isolated at the Interactor layer allows you to focus on building the new user interface for tablet, phone, or Mac, while reusing your application layer.

另一个利用 VIPER 建立模块的优势就是扩展到多种形式因素变得更加简单，对于你独立在交互层的所有用例来说，拥有应用逻辑可以帮助你集中建立新的针对平板电脑，移动电话或者苹果笔记本的用户界面，并且还可以反复利用你的应用层。

Taking this a step further, the user interface for iPad apps may be able to reuse some of the views, view controllers, and presenters of the iPhone app. In this case, an iPad screen would be represented by 'super' presenters and wireframes, which would compose the screen using existing presenters and wireframes that were written for the iPhone. Building and maintaining an app across multiple platforms can be quite challenging, but good architecture that promotes reuse across the model and application layer helps make this much easier.

进一步来说，iPad 应用的用户界面能够将部分 iPhone 应用的视图，视图控制器及主持人进行再利用。在这项实例中，iPad 屏幕需要由‘超级’主持人和线框进行代表，这样可以利用 iPhone 使用过的主持人和线框来组成屏幕。建立进而维护一个跨多平台的应用是一个巨大的挑战，但是好的构架可以对整个模型和应用层的再利用有大幅度的提升，并使其实现起来更加容易。

## Testing with VIPER 利用 VIPER 进行测试
Following VIPER encourages a separation of concerns that makes it easier to adopt TDD. The Interactor contains pure logic that is independent of any UI, which makes it easy to drive with tests. The Presenter contains logic to prepare data for display and is independent of any UIKit widgets. Developing this logic is also easy to drive with tests.

VIPER 的出现激发了一个关注点的分离，这使得采用 TDD 变得更加简便。交互器包含独立与任何 UI 的纯粹逻辑使测试更加简单化，同时主持人包含的用来为显示器准备数据的逻辑，并且它也独立于任何一个 UIKit 小部件。开发这个逻辑也很容易启动测试。

Our preferred method is to start with the Interactor. Everything in the UI is there to serve the needs of the use case. By using TDD to test drive the API for the Interactor, you will have a better understanding of the relationship between the UI and the use case.

我们更倾向于先启动交互器这个方法。用户界面里所有部分都服务于用例，而通过采用 TDD 来测试驱动交互器的 API 可以让你对用户界面和用例之间的关系有一个更好的了解。

As an example, we will look at the Interactor responsible for the list of upcoming to-do items. The policy for finding upcoming items is to find all to-do items due by the end of next week and classify each to-do item as being due today, tomorrow, later this week, or next week.

比如说，我们要看一下负责待办事项列表的交互器。寻找待办事项的准则为找出所有的将在下一周末前截止的项目，并将这些项目分别归类至截止于今天，明天，本周末或者下周。

The first test we write is to ensure the Interactor finds all to-do items due by the end of next week:

我们编写的第一个测试是为了保证交互器能够找到所有的截止于下周末的待办事项：


    - (void)testFindingUpcomingItemsRequestsAllToDoItemsFromTodayThroughEndOfNextWeek
    {
        [[self.dataManager expect] todoItemsBetweenStartDate:self.today endDate:self.endOfNextWeek completionBlock:OCMOCK_ANY];
        [self.interactor findUpcomingItems];
    }

Once we know that the Interactor asks for the appropriate to-do items, we will write several tests to confirm that it allocates the to-do items to the correct relative date group (e.g. today, tomorrow, etc.):

一旦知道了交互器找到了正确的待办事项后，我们就需要编写几个小测试用来确认它确实将待办事项分配到了正确的相对日期组内（比如说今天，明天，等等）。

    - (void)testFindingUpcomingItemsWithOneItemDueTodayReturnsOneUpcomingItemsForToday
    {
        NSArray *todoItems = @[[VTDTodoItem todoItemWithDueDate:self.today name:@"Item 1"]];
        [self dataStoreWillReturnToDoItems:todoItems];
    
        NSArray *upcomingItems = @[[VTDUpcomingItem upcomingItemWithDateRelation:VTDNearTermDateRelationToday dueDate:self.today title:@"Item 1"]];
        [self expectUpcomingItems:upcomingItems];
    
        [self.interactor findUpcomingItems];
    }

Now that we know what the API for the Interactor looks like, we can develop the Presenter. When the Presenter receives upcoming to-do items from the Interactor, we will want to test that we properly format the data and display it in the UI:

既然我们已经知道了交互器的 API 长什么样，接下来就是开发主持人。一旦主持人接收到了交互器传来的待办事项，我们就需要知道我们是否适当的将数据进行格式化并且在用户界面中正确的显示它。

    - (void)testFoundZeroUpcomingItemsDisplaysNoContentMessage
    {
        [[self.ui expect] showNoContentMessage];
    
        [self.presenter foundUpcomingItems:@[]];
    }
    
    - (void)testFoundUpcomingItemForTodayDisplaysUpcomingDataWithNoDay
    {
        VTDUpcomingDisplayData *displayData = [self displayDataWithSectionName:@"Today"
                                                              sectionImageName:@"check"
                                                                     itemTitle:@"Get a haircut"
                                                                    itemDueDay:@""];
        [[self.ui expect] showUpcomingDisplayData:displayData];
    
        NSCalendar *calendar = [NSCalendar gregorianCalendar];
        NSDate *dueDate = [calendar dateWithYear:2014 month:5 day:29];
        VTDUpcomingItem *haircut = [VTDUpcomingItem upcomingItemWithDateRelation:VTDNearTermDateRelationToday dueDate:dueDate title:@"Get a haircut"];
    
        [self.presenter foundUpcomingItems:@[haircut]];
    }
    
    - (void)testFoundUpcomingItemForTomorrowDisplaysUpcomingDataWithDay
    {
        VTDUpcomingDisplayData *displayData = [self displayDataWithSectionName:@"Tomorrow"
                                                              sectionImageName:@"alarm"
                                                                     itemTitle:@"Buy groceries"
                                                                    itemDueDay:@"Thursday"];
        [[self.ui expect] showUpcomingDisplayData:displayData];
    
        NSCalendar *calendar = [NSCalendar gregorianCalendar];
        NSDate *dueDate = [calendar dateWithYear:2014 month:5 day:29];
        VTDUpcomingItem *groceries = [VTDUpcomingItem upcomingItemWithDateRelation:VTDNearTermDateRelationTomorrow dueDate:dueDate title:@"Buy groceries"];
    
        [self.presenter foundUpcomingItems:@[groceries]];
    }

We also want to test that the app will start the appropriate action when the user wants to add a new to-do item:

同样需要测试的是应用是否在用户想要新建待办事项时正确启动了相应操作：

    - (void)testAddNewToDoItemActionPresentsAddToDoUI
    {
        [[self.wireframe expect] presentAddInterface];
    
        [self.presenter addNewEntry];
    }

We can now develop the View. When there are no upcoming to-do items, we want to show a special message:

这时我们可以开发视图功能了，并且在没有待办事项的时候我们想要展示一个特殊的信息。

    - (void)testShowingNoContentMessageShowsNoContentView
    {
        [self.view showNoContentMessage];
    
        XCTAssertEqualObjects(self.view.view, self.view.noContentView, @"the no content view should be the view");
    }

When there are upcoming to-do items to display, we want to make sure the table is showing:

有待办事项出现时，我们要确保桌面有所提示：

    - (void)testShowingUpcomingItemsShowsTableView
    {
        [self.view showUpcomingDisplayData:nil];
    
        XCTAssertEqualObjects(self.view.view, self.view.tableView, @"the table view should be the view");
    }

Building the Interactor first is a natural fit with TDD. If you develop the Interactor first, followed by the Presenter, you get to build out a suite of tests around those layers first and lay the foundation for implementing those use cases. You can iterate quickly on those classes, because you won't have to interact with the UI in order to test them. Then, when you go to develop the View, you'll have a working and tested logic and presentation layer to connect to it. By the time you finish developing the View, you might find that the first time you run the app everything just works, because all your passing tests tell you it will work.

首先建立交互器是一种符合 TDD 的自然规律。如果你首先开发交互器，紧接着是主持人，你就可以首先建立一个位于这些层的套件测试，并且为实现这是实例奠定基础。由于你不需要为了测试他们而与用户界面进行交互，那这些类可以进行快速迭代。在你需要开发视图的时候，你会进行测试逻辑和表现层用来与其进行连接。在快要完成对视图的开发时，你会发现第一次运行程序一切都是有效地，因为你所有的通过测试已经告知你它会有效地。

## Conclusion 结论
We hope you have enjoyed this introduction to VIPER. Many of you may now be wondering where to go next. If you wanted to architect your next app using VIPER, where would you start?

我们希望你能够通过这篇介绍对 VIPER 能够有所了解。或许你们都很好奇接下来还会有什么，如果你希望通过 VIPER 来对你下一个应用进行设计，该从哪里开始呢？

This article and our example implementation of an app using VIPER are as specific and well-defined as we could make them. Our to-do list app is rather straightforward, but it should also accurately explain how to build an app using VIPER. In a real-world project, how closely you follow this example will depend on your own set of challenges and constraints. In our experience, each of our projects have varied the approach taken to using VIPER slightly, but all of them have benefited greatly from using it to guide their approaches.

这篇文章和我们利用 VIPER 实现的应用实例就像我们在制作他们的时候一样明确并且进行了很好的定义。我们的待办事项里列表程序相当简单，但是仍需要详细阐述如何利用 VIPER 来建立一个应用。在实际的项目中，你如何密切的跟进这个案例取决于你自己的挑战能力和约束条件。根据以往的经验，我们的每个项目在采取各种各样的方法时都多少使用了 VIPER，但他们无一例外的都从中得益，找到了正确的方向。

There may be cases where you wish to deviate from the path laid out by VIPER for various reasons. Maybe you have run into a warren of ['bunny'](http://inessential.com/2014/03/16/smaller_please) objects, or your app would benefit from using segues in Storyboards. That's OK. In these cases, consider the spirit of what VIPER represents when making your decision. At its core, VIPER is an architecture based on the [Single Responsibility Principle](http://en.wikipedia.org/wiki/Single_responsibility_principle). If you are having trouble, think about this principle when deciding how to move forward.

很多情况下由于某些原因，你可能会想要偏离 VIPER 所指引的道路。可能你误入了很多['bunny'](http://inessential.com/2014/03/16/smaller_please)项目，或者你的应用会受益于故事板中的 segues 。没关系的，在这些实例中，你只需要在做决定时稍微考虑下 VIPER 所代表的精神就好。VIPER 的核心在于它是建立在[单一责任原则](http://en.wikipedia.org/wiki/Single_responsibility_principle)上的架构。如果你碰到了些许麻烦，想想这些原则再考虑如何前进。

You may also be wondering if it's possible to use VIPER in your existing app. In this scenario, consider building a new feature with VIPER. Many of our existing projects have taken this route. This allows you to build a module using VIPER, and also helps you spot any existing issues that might make it harder to adopt an architecture based on the Single Responsibility Principle.

你一定想知道在现有的应用中能否只用 VIPER 。在这种情况下，你可以考虑使用 VIPER 建立一个新功能，许多现有项目都使用了这个方法。你可以利用 VIPER 建立一个模块，这能帮助你发现许多建立在单一责任原则基础上造成难以运用架构的现有问题。

One of the great things about developing software is that every app is different, and there are also different ways of architecting any app. To us, this means that every app is a new opportunity to learn and try new things. If you decide to try VIPER, we think you'll learn a few new things as well. Thanks for reading.

软件开发最伟大的事情之一就是每个应用程序都是不同的，而设计每个应用的架构的方式也是不同的。这就意味着每个应用对于我们来说都是一个学习和尝试的机遇，如果你决定开始使用 VIPER，你会受益匪浅。感谢你的阅读。

## Swift Addendum Swifit 补遗
Last week at WWDC Apple introduced the [Swift](https://developer.apple.com/swift/) programming language as the future of Cocoa and Cocoa Touch development. It's too early to have formed complex opinions about the Swift language, but we do know that languages have a major influence on how we design and build software. We decided to [rewrite our VIPER TODO example app using Swift](https://github.com/objcio/issue-13-viper-swift) to help us learn what this means for VIPER. So far, we like what we see. Here are a few features of Swift that we feel will improve the experience of building apps using VIPER.

苹果上周在 WWDC 介绍了一门称之为 [Swift](https://developer.apple.com/swift/) 的编程语言来代替 Cocoa 和 Cocoa Touch 开发。现在发表关于 Swift 的意见还言之尚早，但众所周知编程语言对我们如何设计和构建应用有着重大影响。我们决定利用 Swift 重写我们的[待办事项清单](https://github.com/objcio/issue-13-viper-swift)，帮助我们学习 VIPER 的理念。至今为止，收获颇丰。Swift 中的一些特性对于构建应用的体验有着显著的提升。


### Structs 结构体
In VIPER we use small, lightweight, model classes to pass data between layers, such as from the Presenter to the View. These PONSOs are usually intended to simply carry small amounts of data, and are usually not intended to be subclassed. Swift structs are a perfect fit for these situations. Here's an example of a struct used in the VIPER Swift example. Notice that this struct needs to be equatable, and so we have overloaded the == operator to compare two instances of its type:

在 VIPER 中我们使用小型，轻量级的模块类来在不同层中传递数据，例如从主持人到视图。这些 PONSOs 通常是为了处理少量的数据，并且通常这些类不会被继承。Swift 的结构体完美的诠释了这个情况，下面的结构体的例子来自 VIPER Swift。这个结构体需要被判断是否相等，所以我们重载了 == 操作符来比较两个实例。


    struct UpcomingDisplayItem : Equatable, Printable {
        let title : String = ""
        let dueDate : String = ""
    
        var description : String { get {
            return "\(title) -- \(dueDate)"
        }}
    
        init(title: String, dueDate: String) {
            self.title = title
            self.dueDate = dueDate
        }
    }

    func == (leftSide: UpcomingDisplayItem, rightSide: UpcomingDisplayItem) -> Bool {
        var hasEqualSections = false
        hasEqualSections = rightSide.title == leftSide.title
    
        if hasEqualSections == false {
            return false
        }
    
        hasEqualSections = rightSide.dueDate == rightSide.dueDate
    
        return hasEqualSections
    }

### Type Safety 类型安全
Perhaps the biggest difference between Objective-C and Swift is how the two deal with types. Objective-C is dynamically typed and Swift is very intentionally strict with how it implements type checking at compile time. For an architecture like VIPER, where an app is composed of multiple distinct layers, type safety can be a huge win for programmer efficiency and for architectural structure. The compiler is helping you make sure containers and objects are of the correct type when they are being passed between layer boundaries. This is a great place to use structs as shown above. If a struct is meant to live at the boundary between two layers, then you can guarantee that it will never be able to escape from between those layers thanks to type safety.

也许 Objective-C 和 Swift 的最大区别是类型的不同。 Objective-C 是动态类型，而 Swift 是故意在编译器做了严格的类型检查。对于一个类似 VIPER 的架构， 应用由不同层构成，类型安全是提升程序员效率和设计架构的一个巨大的胜利为。编译器帮助你确保正确类型的容器和对象在层的边界传递。这是一个使用结构体的好地方，如上所示。如果一个结构体的意义是为了存在于在两层之间，然后你就可以保证它将永远无法摆脱这些层之间由于类型安全。

## Further Reading 扩展阅读
- [VIPER TODO, article example app](https://github.com/objcio/issue-13-viper)
- [VIPER SWIFT, article example app built using Swift](https://github.com/objcio/issue-13-viper-swift)
- [Counter, another example app](https://github.com/mutualmobile/Counter)
- [Mutual Mobile Introduction to VIPER](http://mutualmobile.github.io/blog/2013/12/04/viper-introduction/)
- [Clean Architecture](http://blog.8thlight.com/uncle-bob/2011/11/22/Clean-Architecture.html)
- [Lighter View Controllers](http://www.objc.io/issue-1/lighter-view-controllers.html)
- [Testing View Controllers](http://www.objc.io/issue-1/testing-view-controllers.html)
- [Bunnies](http://inessential.com/2014/03/16/smaller_please)

- [VIPER TODO, 文章示例](https://github.com/objcio/issue-13-viper)
- [VIPER SWIFT, 基于 Swift 的文章示例](https://github.com/objcio/issue-13-viper-swift)
- [另一个计数器应用](https://github.com/mutualmobile/Counter)
- [Mutual Mobile 关于 VIPER 的介绍](http://mutualmobile.github.io/blog/2013/12/04/viper-introduction/)
- [简明架构](http://blog.8thlight.com/uncle-bob/2011/11/22/Clean-Architecture.html)
- [更轻量的 View Controllers](http://www.objc.io/issue-1/lighter-view-controllers.html)
- [测试 View Controllers](http://www.objc.io/issue-1/testing-view-controllers.html)
- [Bunnies](http://inessential.com/2014/03/16/smaller_please)



