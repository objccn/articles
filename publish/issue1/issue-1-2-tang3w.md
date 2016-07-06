Table view 是 iOS 应用程序中非常通用的组件。许多代码和 table view 都有直接或间接的关系，随便举几个例子，比如提供数据、更新 table view，控制它的行为以及响应选择事件。在这篇文章中，我们将会展示保持 table view 相关代码的整洁和良好组织的技术。

## UITableViewController vs. UIViewController

Apple 提供了 `UITableViewController` 作为 table views 专属的 view controller 类。Table view controllers 实现了一些非常有用的特性，来帮你避免一遍又一遍地写那些死板的代码！但是话又说回来，table view controller 只限于管理一个全屏展示的 table view。大多数情况下，这就是你想要的，但如果不是，还有其他方法来解决这个问题，就像下面我们展示的那样。

### Table View Controllers 的特性

Table view controllers 会在第一次显示 table view 的时候帮你加载其数据。另外，它还会帮你切换 table view 的编辑模式、响应键盘通知、以及一些小任务，比如闪现侧边的滑动提示条和清除选中时的背景色。为了让这些特性生效，当你在子类中覆写类似 `viewWillAppear:` 或者 `viewDidAppear:` 等事件方法时，需要调用 super 版本。

Table view controllers 相对于标准 view controllers 的一个特别的好处是它支持 Apple 实现的“下拉刷新”。目前，文档中唯一的使用 `UIRefreshControl` 的方式就是通过 table view controller ，虽然通过努力在其他地方也能让它工作（[见此处][2]），但很可能在下一次 iOS 更新的时候就不行了。

这些要素加一起，为我们提供了大部分 Apple 所定义的标准 table view 交互行为，如果你的应用恰好符合这些标准，那么直接使用 table view controllers 来避免写那些死板的代码是个很好的方法。

### Table View Controllers 的限制

Table view controllers 的 view 属性永远都是一个 table view。如果你稍后决定在 table view 旁边显示一些东西（比如一个地图），如果不依赖于那些奇怪的 hacks，估计就没什么办法了。

如果你是用代码或 .xib 文件来定义的界面，那么迁移到一个标准 view controller 将会非常简单。但是如果你使用了 storyboards，那么这个过程要多包含几个步骤。除非重新创建，否则你并不能在 storyboards 中将 table view controller 改成一个标准的 view controller。这意味着你必须将所有内容拷贝到新的 view controller，然后再重新连接一遍。

最后，你需要把迁移后丢失的 table view controller 的特性给补回来。大多数都是 `viewWillAppear:` 或 `viewDidAppear:` 中简单的一条语句。切换编辑模式需要实现一个 action 方法，用来切换 table view 的 `editing` 属性。大多数工作来自重新创建对键盘的支持。

在选择这条路之前，其实还有一个更轻松的选择，它可以通过分离我们需要关心的功能（关注点分离），让你获得额外的好处：

### 使用 Child View Controllers

和完全抛弃 table view controller 不同，你还可以将它作为 child view controller 添加到其他 view controller 中（[关于此话题的文章][3]）。这样，parent view controller 在管理其他的你需要的新加的界面元素的同时，table view controller 还可以继续管理它的 table view。


    - (void)addPhotoDetailsTableView
    {
        DetailsViewController *details = [[DetailsViewController alloc] init];
        details.photo = self.photo;
        details.delegate = self;
        [self addChildViewController:details];
        CGRect frame = self.view.bounds;
        frame.origin.y = 110;
        details.view.frame = frame;
        [self.view addSubview:details.view];
        [details didMoveToParentViewController:self];
    }


如果你使用这个解决方案，你就必须在 child view controller 和 parent view controller 之间建立消息传递的渠道。比如，如果用户选择了一个 table view 中的 cell，parent view controller 需要知道这个事件来推入其他 view controller。根据使用习惯，通常最清晰的方式是为这个 table view controller 定义一个 delegate protocol，然后到 parent view controller 中去实现。


    @protocol DetailsViewControllerDelegate
    - (void)didSelectPhotoAttributeWithKey:(NSString *)key;
    @end

    @interface PhotoViewController () 
    @end

    @implementation PhotoViewController
    // ...
    - (void)didSelectPhotoAttributeWithKey:(NSString *)key
    {
        DetailViewController *controller = [[DetailViewController alloc] init];
        controller.key = key;
        [self.navigationController pushViewController:controller animated:YES];
    }
    @end


就像你看到的那样，这种结构为 view controller 之间的消息传递带来了额外的开销，但是作为回报，代码封装和分离非常清晰，有更好的复用性。根据实际情况的不同，这既可能让事情变得更简单，也可能会更复杂，需要读者自行斟酌和决定。

## 分离关注点（Separating Concerns）

当处理 table views 的时候，有许多各种各样的任务，这些任务穿梭于 models，controllers 和 views 之间。为了避免让 view controllers 做所有的事，我们将尽可能地把这些任务划分到合适的地方，这样有利于阅读、维护和测试。

这里描述的技术是文章[更轻量的 View Controllers][4] 中的概念的延伸，请参考这篇文章来理解如何重构 data source 和 model 的逻辑。结合 table views，我们来具体看看如何在 view controllers 和 views 之间分离关注点。

### 搭建 Model 对象和 Cells 之间的桥梁

有时我们需要将想显示的 model 层中的数据传到 view 层中去显示。由于我们同时也希望让 model 和 view 之间明确分离，所以通常把这个任务转移到 table view 的 data source 中去处理：


    - (UITableViewCell *)tableView:(UITableView *)tableView
             cellForRowAtIndexPath:(NSIndexPath *)indexPath
    {
        PhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PhotoCell"];
        Photo *photo = [self itemAtIndexPath:indexPath];
        cell.photoTitleLabel.text = photo.name;
        NSString* date = [self.dateFormatter stringFromDate:photo.creationDate];
        cell.photoDateLabel.text = date;
    }


但是这样的代码会让 data source 变得混乱，因为它向 data source 暴露了 cell 的设计。最好分解出来，放到 cell 类的一个 category 中。


    @implementation PhotoCell (ConfigureForPhoto)

    - (void)configureForPhoto:(Photo *)photo
    {
        self.photoTitleLabel.text = photo.name;
        NSString* date = [self.dateFormatter stringFromDate:photo.creationDate];
        self.photoDateLabel.text = date;
    }

    @end


有了上述代码后，我们的 data source 方法就变得简单了。


    - (UITableViewCell *)tableView:(UITableView *)tableView
             cellForRowAtIndexPath:(NSIndexPath *)indexPath
    {
        PhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:PhotoCellIdentifier];
        [cell configureForPhoto:[self itemAtIndexPath:indexPath]];
        return cell;
    }


在我们的示例代码中，table view 的 data source 已经[分解到单独的类中了][4]，它用一个设置 cell 的 block 来初始化。这时，这个 block 就变得这样简单了：


    TableViewCellConfigureBlock block = ^(PhotoCell *cell, Photo *photo) {
        [cell configureForPhoto:photo];
    };


### 让 Cells 可复用

有时多种 model 对象需要用同一类型的 cell 来表示，这种情况下，我们可以进一步让 cell 可以复用。首先，我们给 cell 定义一个 protocol，需要用这个 cell 显示的对象必须遵循这个 protocol。然后简单修改 category 中的设置方法，让它可以接受遵循这个 protocol 的任何对象。这些简单的步骤让 cell 和任何特殊的 model 对象之间得以解耦，让它可适应不同的数据类型。

### 在 Cell 内部控制 Cell 的状态

如果你想自定义 table views 默认的高亮或选择行为，你可以实现两个 delegate 方法，把点击的 cell 修改成我们想要的样子。例如：


    - (void)tableView:(UITableView *)tableView
            didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
    {
        PhotoCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.photoTitleLabel.shadowColor = [UIColor darkGrayColor];
        cell.photoTitleLabel.shadowOffset = CGSizeMake(3, 3);
    }

    - (void)tableView:(UITableView *)tableView
            didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath
    {
        PhotoCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.photoTitleLabel.shadowColor = nil;
    }


然而，这两个 delegate 方法的实现又基于了 view controller 知晓 cell 实现的具体细节。如果我们想替换或重新设计 cell，我们必须改写 delegate 代码。View 的实现细节和 delegate 的实现交织在一起了。我们应该把这些细节移到 cell 自身中去。


    @implementation PhotoCell
    // ...
    - (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
    {
        [super setHighlighted:highlighted animated:animated];
        if (highlighted) {
            self.photoTitleLabel.shadowColor = [UIColor darkGrayColor];
            self.photoTitleLabel.shadowOffset = CGSizeMake(3, 3);
        } else {
            self.photoTitleLabel.shadowColor = nil;
        }
    }
    @end


总的来说，我们在努力把 view 层和 controller 层的实现细节分离开。delegate 肯定得清楚一个 view 该显示什么状态，但是它不应该了解如何修改 view 结构或者给某些 subviews 设置某些属性以获得正确的状态。所有这些逻辑都应该封装到 view 内部，然后给外部提供一个简单的 API。

### 控制多个 Cell 类型

如果一个 table view 里面有多种类型的 cell，data source 方法很快就难以控制了。在我们示例程序中，photo details table 有两种不同类型的 cell：一种用于显示几个星，另一种用来显示一个键值对。为了划分处理不同 cell 类型的代码，data source 方法简单地通过判断 cell 的类型，把任务派发给其他指定的方法。


    - (UITableViewCell *)tableView:(UITableView *)tableView
             cellForRowAtIndexPath:(NSIndexPath *)indexPath
    {
        NSString *key = self.keys[(NSUInteger) indexPath.row];
        id value = [self.photo valueForKey:key];
        UITableViewCell *cell;
        if ([key isEqual:PhotoRatingKey]) {
            cell = [self cellForRating:value indexPath:indexPath];
        } else {
            cell = [self detailCellForKey:key value:value];
        }
        return cell;
    }

    - (RatingCell *)cellForRating:(NSNumber *)rating
                        indexPath:(NSIndexPath *)indexPath
    {
        // ...
    }

    - (UITableViewCell *)detailCellForKey:(NSString *)key
                                    value:(id)value
    {
        // ...
    }


### 编辑 Table View

Table view 提供了易于使用的编辑特性，允许你对 cell 进行删除或重新排序。这些事件都可以让 table view 的 data source 通过 [delegate 方法][6]得到通知。因此，通常我们能在这些 delegate 方法中看到对数据的进行修改的操作。

修改数据很明显是属于 model 层的任务。Model 应该为诸如删除或重新排序等操作暴露一个 API，然后我们可以在 data source 方法中调用它。这样，controller 就可以扮演 view 和 model 之间的协调者，而不需要知道 model 层的实现细节。并且还有额外的好处，model 的逻辑也变得更容易测试，因为它不再和 view controllers 的任务混杂在一起了。

## 总结

Table view controllers（以及其他的 controller 对象！）应该在 model 和 view 对象之间扮演[协调者和调解者的角色][10]。它不应该关心明显属于 view 层或 model 层的任务。你应该始终记住这点，这样 delegate 和 data source 方法会变得更小巧，最多包含一些简单的样板代码。

这不仅减少了 table view controllers 那样的大小和复杂性，而且还把业务逻辑和 view 的逻辑放到了更合适的地方。Controller 层的里里外外的实现细节都被封装成了简单的 API，最终，它变得更加容易理解，也更利于团队协作。

### 扩展阅读

  * [Blog: Skinnier Controllers using View Categories][11]
  * [Table View Programming Guide][12]
  * [Cocoa Core Competencies: Controller Object][10]
  

---

   [2]: http://stackoverflow.com/questions/12805003/uirefreshcontrol-issues
   [3]: http://objccn.io/issue-1-4
   [4]: http://objccn.io/issue-1-1
   [6]: http://developer.apple.com/library/ios/#documentation/uikit/reference/UITableViewDataSource_Protocol/Reference/Reference.html#//apple_ref/occ/intfm/UITableViewDataSource/tableView:commitEditingStyle:forRowAtIndexPath:
   [8]: http://objccn.io/issue-1
   [10]: http://developer.apple.com/library/mac/#documentation/General/Conceptual/DevPedia-CocoaCore/ControllerObject.html
   [11]: http://www.sebastianrehnby.com/blog/2013/01/01/skinnier-controllers-using-view-categories/
   [12]: http://developer.apple.com/library/ios/#documentation/userexperience/conceptual/tableview_iphone/AboutTableViewsiPhone/AboutTableViewsiPhone.html

  
原文[Clean table view code](http://www.objc.io/issue-1/table-views.html)

译文[整理 Table View 的代码 - 言无不尽](http://tang3w.com/translate/objective-c/objc.io/2013/10/23/整理-table-view-的代码.html)
