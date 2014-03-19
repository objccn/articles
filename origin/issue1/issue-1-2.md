[Source](http://www.objc.io/issue-1/table-views.html "Permalink to Clean table view code - Lighter View Controllers - objc.io issue #1 ")

# Clean table view code - Lighter View Controllers - objc.io issue #1 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# Clean table view code

[Issue #1 Lighter View Controllers][4], June 2013

By [Florian Kugler][5]

Table views are an extremely versatile building block for iOS apps. Therefore, a lot of code is directly or indirectly related to table view tasks, including supplying data, updating the table view, controlling its behavior, and reacting to selections, to name just a few. In this article, we will present techniques to keep this code clean and well-structured.

## UITableViewController vs. UIViewController

Apple provides `UITableViewController` as dedicated view controller class for table views. Table view controllers implement a handful of very useful features which can help you to avoid writing the same boilerplate code over and over. On the flip side, table view controllers are restricted to managing exactly one table view, which is presented full screen. However, in many cases, this is all you need, and if it’s not, there are ways to work around this, as we will show below.

### Features of Table View Controllers

Table view controllers help you with loading the table view’s data when it is shown for the first time. More specifically, it helps with toggling the table view’s editing mode, with reacting to the keyboard notifications, and with a few small tasks like flashing the scroll indicator and clearing the selection. In order for these features to work, it is important that you call super on any view event methods (such as `viewWillAppear:` and `viewDidAppear:`) that you may override in your custom subclass.

Table view controllers have one unique selling point over standard view controllers, and that’s the support for Apple’s implementation for “pull to refresh.” At the moment, the only documented way of using `UIRefreshControl` is within a table view controller. There are ways to make it work in other contexts, but these could easily not work with the next iOS update.

The sum of all these elements provides much of the standard table view interface behavior as Apple has defined it. If your app conforms to these standards, it is a good idea to stick with table view controllers in order to avoid writing boilerplate code.

### Limitations of Table View Controllers

The view property of table view controllers always has to be set to a table view. If you decide later on that you want to show something else on the screen aside from the table view (e.g. a map), you are out of luck if you don’t want to rely on awkward hacks.

If you have defined your interface in code or using a .xib file, then it is pretty easy to transition to a standard view controller. If you’re using storyboards, then this process involves a few more steps. With storyboards, you cannot change a table view controller to a standard view controller without recreating it. This means you have to copy all the contents over to the new view controller and wire everything up again.

Finally, you need to add back the features of table view controller that you lost in this transition. Most of them are simple single-line statements in `viewWillAppear` or `viewDidAppear`. Toggling the editing state requires implementing an action method which flips the table view’s `editing` property. The most work lies in recreating the keyboard support.

Before you go down this route though, here is an easy alternative that has the additional benefit of separating concerns:

### Child View Controllers

Instead of getting rid of the table view controller entirely, you could also add it as a child view controller to another view controller (see the [article about view controller containment][6] in this issue). Then the table view controller continues to manage only the table view and the parent view controller can take care of whatever additional interface elements you might need.


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

If you use this solution you have to create a communication channel from the child to the parent view controller. For example, if the user selects a cell in the table view, the parent view controller needs to know about this in order to push another view controller. Depending on the use case, often the cleanest way to do this is to define a delegate protocol for the table view controller, which you then implement on the parent view controller.


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

As you can see, this construction comes with the price of some overhead to communicate between the view controllers in return for a clean separation of concerns and better reusability. Depending on the specific use case, this can either end up making things more simple or more complex than necessary. That’s for you to consider and decide.

## Separating Concerns

When dealing with table views there are a variety of different tasks involved which cross the borders between models, controllers, and views. In order to prevent view controllers from becoming the place for all these tasks, we will try to isolate as many of these tasks as possible in more appropriate places. This helps readability, maintainability, and testability.

The techniques described here extend and elaborate upon the concepts demonstrated in the article [Lighter view controllers][7]. Please refer to this article for how to factor our data source and model logic. In the context of table views, we will specifically look at how to separate concerns between view controllers and views.

### Bridging the Gap Between Model Objects and Cells

At some point we have to hand over the data we want to display into the view layer. Since we still want to maintain a clear separation between the model and the view, we often offload this task to the table view’s data source:


    - (UITableViewCell *)tableView:(UITableView *)tableView
             cellForRowAtIndexPath:(NSIndexPath *)indexPath
    {
        PhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PhotoCell"];
        Photo *photo = [self itemAtIndexPath:indexPath];
        cell.photoTitleLabel.text = photo.name;
        NSString* date = [self.dateFormatter stringFromDate:photo.creationDate];
        cell.photoDateLabel.text = date;
    }

This kind of code clutters the data source with specific knowledge about the design of the cell. We are better off factoring this out into a category of the cell class:


    @implementation PhotoCell (ConfigureForPhoto)

    - (void)configureForPhoto:(Photo *)photo
    {
        self.photoTitleLabel.text = photo.name;
        NSString* date = [self.dateFormatter stringFromDate:photo.creationDate];
        self.photoDateLabel.text = date;
    }

    @end

With this in place, our data source method becomes very simple.


    - (UITableViewCell *)tableView:(UITableView *)tableView
             cellForRowAtIndexPath:(NSIndexPath *)indexPath
    {
        PhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:PhotoCellIdentifier];
        [cell configureForPhoto:[self itemAtIndexPath:indexPath]];
        return cell;
    }

In our example code, the data source for this table view is [factored out into its own controller object][8], which gets initialized with a cell configuration block. In this case, the block becomes as simple as this:


    TableViewCellConfigureBlock block = ^(PhotoCell *cell, Photo *photo) {
        [cell configureForPhoto:photo];
    };

### Making Cells Reusable

In cases where we have multiple model objects that can be presented using the same cell type, we can even go one step further to gain reusability of the cell. First, we define a protocol on the cell to which an object must conform in order to be displayed by this cell type. Then we simply change the configure method in the cell category to accept any object conforming to this protocol. These simple steps decouple the cell from any specific model object and make it applicable to different data types.

### Handling Cell State Within the Cell

If we want to do something beyond the standard highlighting or selection behavior of table views, we could implement two delegate methods, which modify the tapped cell in the way we want. For example:


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

However, the implementation of these two delegate methods relies again on specific knowledge about how the cell is implemented. If we want to swap out the cell or redesign it in a different way, we also have to adapt the delegate code. The implementation details of the view are complected with the implementation of the delegate. Instead, we should move this logic into the cell itself.


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

Generally speaking, we strive to separate the implementation details of the view layer from the implementation details of the controller layer. A delegate has to know about the different states a view can be in, but it shouldn’t have to know how to modify the view tree or which attributes to set on some subviews in order to get it into the right state. All this logic should be encapsulated within the view, which then provides a simple API to the outside.

### Handling Multiple Cell Types

If you have multiple different cell types within one table view, the data source methods can quickly get out of hand. In our example app we have two different cell types for the photo details table: one cell to display a star rating, and a generic cell to display a key-value pair. In order to separate the code dealing with these different cell types, the data source method simply dispatches the request to specialized methods for each cell type.


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

### Table View Editing

Table views provide easy-to-use editing features, which allow for reordering and deletion of cells. In case of these events, the table view’s data source gets notified via [delegate methods][9]. Therefore, we often see domain logic in these delegate methods that performs the actual modification on the data.

Modifying data is a task that clearly belongs in the model layer. The model should expose an API for things like deletion and reordering, which we can then call from the data source methods. This way, the controller plays the role of a coordinator between the view and the model, but does not have to know about the implementation details of the model layer. As an added benefit, the model logic also becomes easier to test, because it is not interweaved with other tasks of view controllers anymore.

## Conclusion

Table view controllers (and other controller objects!) should mostly have a [coordinating and mediating role][10] between model and view objects. They should not be concerned with tasks that clearly belong to the view or the model layer. If you keep this in mind, the delegate and data source methods will become much smaller and mostly contain simple boilerplate code.

This not only reduces the size and complexity of table view controllers, but it puts the domain logic and view logic in much more appropriate places. Implementation details below and above the controller layer are encapsulated behind a simple API, which ultimately makes it much easier to understand the code and to work on it collaboratively.

### Further Reading

  * [Blog: Skinnier Controllers using View Categories][11]
  * [Table View Programming Guide][12]
  * [Cocoa Core Competencies: Controller Object][10]




* * *

[More articles in issue #1][13]

  * [Privacy policy][14]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-1/index.html
   [5]: http://twitter.com/floriankugler
   [6]: http://www.objc.io/issue-1/containment-view-controller.html
   [7]: http://www.objc.io/issue-1/lighter-view-controllers.html
   [8]: http://www.objc.io/issue-1/lighter-view-controllers.html#controllers
   [9]: http://developer.apple.com/library/ios/#documentation/uikit/reference/UITableViewDataSource_Protocol/Reference/Reference.html%23//apple_ref/occ/intfm/UITableViewDataSource/tableView:commitEditingStyle:forRowAtIndexPath:
   [10]: http://developer.apple.com/library/mac/#documentation/General/Conceptual/DevPedia-CocoaCore/ControllerObject.html
   [11]: http://www.sebastianrehnby.com/blog/2013/01/01/skinnier-controllers-using-view-categories/
   [12]: http://developer.apple.com/library/ios/#documentation/userexperience/conceptual/tableview_iphone/AboutTableViewsiPhone/AboutTableViewsiPhone.html
   [13]: http://www.objc.io/issue-1
   [14]: http://www.objc.io/privacy.html
