[Source](http://www.objc.io/issue-3/collection-view-layouts.html "Permalink to Custom Collection View Layouts - Views - objc.io issue #3 ")

# Custom Collection View Layouts - Views - objc.io issue #3 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# Custom Collection View Layouts

[Issue #3 Views][4], August 2013

By [Ole Begemann][5]

Introduced in iOS 6, `UICollectionView` is [the new star among view classes][6] in UIKit. It shares its API design with `UITableView` but extends the latter in a few fundamental ways. The most powerful feature of `UICollectionView` and the point where it significantly exceeds `UITableView`’s capabilities is its completely flexible layout architecture. In this article, we will implement a fairly complex custom collection view layout and discuss important aspects of the class’s design along the way.

The [example project][7] for this article is on GitHub.

## Layout Objects

Both `UITableView` and `UICollectionView` are [data-source- and delegate-driven][8]. They act as dumb containers for the collection of subviews they are displaying, knowing nothing about their actual contents.

`UICollectionView` takes the abstraction one step further. It delegates the control over its subviews’ positions, sizes, and appearances to a separate layout object. By providing a custom layout object, you can achieve pretty much any layout you can imagine. Layouts inherit from the abstract base class [`UICollectionViewLayout`][9]. iOS 6 comes with one concrete layout implementation in the form of the [`UICollectionViewFlowLayout` class][10].

A flow layout can be used to implement a standard grid view, which is probably the most common use case for a collection view. Apple was smart enough to not actually name the class `UICollectionView`**`Grid`**`Layout`, even if that is how most of us think about it. The more generic term, _flow layout_, describes the class’s capabilities much better: it builds its layout by placing cell after cell, inserting line or column breaks when needed. By customizing the scroll direction, sizing, and spacing of the cells, a flow layout can also layout cells in a single row or column. In fact, `UITableView`’s layout can be thought of as a special case of flow layout.

Before you consider writing your own `UICollectionViewLayout` subclass, you should always ask yourself if you can achieve the layout you have in mind with `UICollectionViewFlowLayout`. The class is [remarkably customizable][11] and can also be subclassed itself for further customization. See [Knowing When to Subclass the Flow Layout][12] in the Collection View Programming Guide for tips.

## Cells and Other Views

To accommodate arbitrary layouts, collection views set up a view hierarchy that is similar to, but more flexible than, that of a table view. As usual, your main content is displayed in **cells**, which can optionally be grouped into sections. Collection view cells must be subclasses of [`UICollectionViewCell`][13]. In addition to cells, collection views manage two more kinds of views: supplementary views and decoration views.

**Supplementary views** in a collection view correspond to a table view’s section header and footer views in that they display information about a section. Like cells, their contents are driven by the data source object. Unlike their usage in table views, however, supplementary views are not bound to being header or footer views; their number and placement are entirely controlled by the layout.

**Decoration views** act as pure ornamentation. They are owned and managed entirely by the layout object and do not get their contents from the data source. When a layout object specifies that it requires a decoration view, the collection view creates it automatically and applies the layout attributes provided by the layout object. Any customization of the view’s contents is not intended.

Supplementary and decoration views must be subclasses of [`UICollectionReusableView`][14]. Each view class that your layout uses must be registered with the collection view to enable it to create new instances when its data source asks it to dequeue a view from its reuse pool. If you are using Interface Builder, registering cells with a collection view can be done directly inside the visual editor by dragging a cell onto a collection view. The same method works for supplementary views, but only if you are using a `UICollectionViewFlowLayout`. If not, you have to manually register the view classes with the collection view in code by calling one of its [`registerClass:…`][15] or [`registerNib:…`][16] methods. The `viewDidLoad` method in your view controller is the correct place to do this.

## Custom Layouts

As an example of a non-trivial custom collection view layout, consider a week view in a typical calendar app. The calendar displays one week at a time, with the days of the week arranged in columns. Each calendar event will be displayed by a cell in our collection view, positioned and sized so as to represent the event start date/time and duration.

![Screenshot of our custom calendar collection view layout][17]

There are two general types of collection view layouts:

  1. **Layouts whose computations are independent of the content.** This is the “simple” case you know from `UITableView` and `UICollectionViewFlowLayout`. The position and appearance of each cell does not depend on the content it displays but on its order in the list of all cells. Consider the default flow layout as an example. Each cell is positioned next to its predecessor (or at the beginning of the next line if there is no space left). The layout object does not need to access the actual data to compute the layout.

  2. **Layouts that need to do content-dependent computations.** Our calendar view is an example of this type. It requires the layout object to ask the collection view’s data source directly for the start and end dates of the events it is supposed to display. In many cases, the layout object not only requires data about the currently visible cells but needs some information from _all_ records in order to determine which cells are currently visible in the first place.

In our calendar example, the layout object – if asked for the attributes of the cells inside a certain rectangle – must iterate over all events provided by the data source to determine which ones lie in the requested time window. Contrast this with a flow layout where some relatively simple and data-source-independent math is sufficient to compute the index paths of the cells that lie in a certain rectangle (assuming that all cells in the grid have the same size).

Having a content-dependent layout is a strong indication that you will need to write your own custom layout class and won’t get by with customizing `UICollectionViewFlowLayout`. So that’s exactly what we are going to do.

The [documentation for `UICollectionViewLayout`][9] lists the methods that subclasses should override.

### collectionViewContentSize

Since the collection view does not know anything about its content, the first piece of information the layout must provide is the size of the scroll area so that the collection view can properly manage scrolling. The layout object must compute the total size of its contents here, including all supplementary and decoration views. Note that although most “classic” collection views limit scrolling to one axis (and so does `UICollectionViewFlowLayout`), this is not a requirement.

In our calendar example, we want the view to scroll vertically. For instance, if we want one hour to take up 100 points of vertical space, the content height to display an entire day should be 2,400 points. Notice that we do not enable horizontal scrolling, which means that our collection view displays only one week. To enable paging between multiple weeks in the calendar, we could embed multiple collection views (one per week) in a separate (paged) scroll view (possibly using [`UIPageViewController`][18] for the implementation), or stick with just one collection view and return a content width that is large enough to let the user scroll freely in both directions. This is beyond the scope of this article, though.


    - (CGSize)collectionViewContentSize
    {
        // Don't scroll horizontally
        CGFloat contentWidth = self.collectionView.bounds.size.width;

        // Scroll vertically to display a full day
        CGFloat contentHeight = DayHeaderHeight %2B (HeightPerHour * HoursPerDay);

        CGSize contentSize = CGSizeMake(contentWidth, contentHeight);
        return contentSize;
    }

Note that for clarity reasons, I have chosen to model the layout on a very simple model that assumes a constant number of days per week and hours per day and represents days just as indices from 0 to 6. In a real calendar application, the layout would make heavy use of `NSCalendar`-based date calculations for its computations.

### layoutAttributesForElementsInRect:

This is the central method in any layout class and possibly the one that is most confusing. The collection view calls this method and passes a rectangle in its own coordinate system. This rectangle will typically be the visible rectangle of the view (that is, its bounds) but that is not necessarily the case. You should be prepared to handle any rectangle that gets passed to you.

Your implementation must return an array of [`UICollectionViewLayoutAttributes`][19] objects, containing one such object for each cell, supplementary, or decoration view that is visible in the rectangle. The `UICollectionViewLayoutAttributes` class encapsulates all layout-related properties of an item in the collection view. By default, the class has properties for the `frame`, `center`, `size`, `transform3D`, `alpha`, `zIndex`, and `hidden` attributes. If your layout wants to control other attributes of a view (for example, the background color), you can subclass `UICollectionViewLayoutAttributes` and add your own properties.

The layout attributes objects are associated with their corresponding cell, supplementary view, or decoration view through an `indexPath` property. After the collection view has asked the layout object for the layout attributes of all items, it will instantiate the views and apply the respective attributes to them.

Note that this one method is concerned with all types of views, that is, cell, supplementary, and decoration views. A naive implementation might opt to ignore the passed-in rectangle and just return the layout attributes for _all_ views in the collection view. This is a valid approach during prototyping and developing your layout. But note that this can have a bad impact on performance, especially if the number of total cells is much larger than those that are visible at any one time, as the collection view and the layout object will have to perform additional unnecessary work for these invisible views.

Your implementation should perform these steps:

  1. Create an empty mutable array to contain all the layout attributes.

  2. Identify the index paths of all cells whose frames lie entirely or partly within the rectangle. This computation may require you to ask the collection view’s data source for information about the data you want to display. Then call your implementation of [`layoutAttributesForItemAtIndexPath:`][20] in a loop to create and configure a proper layout attributes object for each index path. Add each object to the array.

  3. If your layout includes supplementary views, compute the index paths of the ones that are visible inside the rectangle. Call your implementation of [`layoutAttributesForSupplementaryViewOfKind:atIndexPath:`][20] in a loop and add those objects to the array. By passing different strings of your choice for the `kind` argument, you can distinguish between different types of supplementary views (such as headers and footers). The collection view will pass the `kind` string back to your data source when it needs to create the view. Remember that the number and kind of supplementary and decoration views is entirely controlled by the layout. You are not restricted to headers and footers.

  4. If your layout includes decoration views, compute the index paths of the ones that are visible inside the rectangle. Call your implementation of [`layoutAttributesForDecorationViewOfKind:atIndexPath:`][20] in a loop and add those objects to the array.

  5. Return the array.

Our custom layout uses no decoration views but two kinds of supplementary views (column headers and row headers):


    - (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
    {
        NSMutableArray *layoutAttributes = [NSMutableArray array];

        // Cells
        // We call a custom helper method -indexPathsOfItemsInRect: here
        // which computes the index paths of the cells that should be included
        // in rect.
        NSArray *visibleIndexPaths = [self indexPathsOfItemsInRect:rect];
        for (NSIndexPath *indexPath in visibleIndexPaths) {
            UICollectionViewLayoutAttributes *attributes =
                [self layoutAttributesForItemAtIndexPath:indexPath];
            [layoutAttributes addObject:attributes];
        }

        // Supplementary views
        NSArray *dayHeaderViewIndexPaths =
            [self indexPathsOfDayHeaderViewsInRect:rect];
        for (NSIndexPath *indexPath in dayHeaderViewIndexPaths) {
            UICollectionViewLayoutAttributes *attributes =
                [self layoutAttributesForSupplementaryViewOfKind:@"DayHeaderView"
                                                     atIndexPath:indexPath];
            [layoutAttributes addObject:attributes];
        }
        NSArray *hourHeaderViewIndexPaths =
            [self indexPathsOfHourHeaderViewsInRect:rect];
        for (NSIndexPath *indexPath in hourHeaderViewIndexPaths) {
            UICollectionViewLayoutAttributes *attributes =
                [self layoutAttributesForSupplementaryViewOfKind:@"HourHeaderView"
                                                     atIndexPath:indexPath];
            [layoutAttributes addObject:attributes];
        }

        return layoutAttributes;
    }

### layoutAttributesFor…IndexPath

Sometimes, the collection view will ask the layout object for the layout attributes of one specific cell, supplementary, or decoration view rather than the list of all visible ones. This is when three other methods come into play. Your implementation of [`layoutAttributesForItemAtIndexPath:`][21] should create and return a single layout attributes object that is properly formatted for the cell identified by the index path that is passed to you.

You do this by calling the [`%2B[UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:]`][22] factory method. Then modify the attributes according to the index path. You may need to ask the collection view’s data source for information about the data object that is displayed at this index path to get the data you need. Make sure to at least set the `frame` property here unless all your cells should sit on top of each other.


    - (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:
        (NSIndexPath *)indexPath
    {
        CalendarDataSource *dataSource = self.collectionView.dataSource;
        id event = [dataSource eventAtIndexPath:indexPath];
        UICollectionViewLayoutAttributes *attributes =
            [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        attributes.frame = [self frameForEvent:event];
        return attributes;
    }

If you are using Auto Layout, you may be surprised that we are modifying the `frame` property of the layout attributes directly rather than working with constraints, but that is how `UICollectionViewLayout` works. Although you would use Auto Layout to define the collection view’s frame and the internal layout of each cell, the frames of the cells have to be computed the old-fashioned way.

Similarly, the methods `layoutAttributesForSupplementaryViewOfKind:atIndexPath:` and `layoutAttributesForDecorationViewOfKind:atIndexPath:` should do the same for supplementary and decoration views, respectively. Implementing these two methods is only required if your layout includes such views. `UICollectionViewLayoutAttributes` contains two more factory methods, [`%2BlayoutAttributesForSupplementaryViewOfKind:withIndexPath:`][23] and [`%2BlayoutAttributesForDecorationViewOfKind:withIndexPath:`][24], to create the correct layout attributes object.

### shouldInvalidateLayoutForBoundsChange:

Lastly, the layout must tell the collection view if it needs to recompute the layout when the collection view’s bounds change. My guess is that most layouts need to be invalidated when the collection view resizes, for example during device rotation. Hence, a naive implementation of this method would simply return `YES`. It is important to realize, however, that a scroll view’s bounds also change during scrolling, which means your layout could be invalidated several times per second. Depending on the complexity of the computations, this could have a sizable performance impact.

Our custom layout must be invalidated when the collection view’s width changes but is not affected by scrolling. Fortunately, the collection view passes its new bounds to the `shouldInvalidateLayoutForBoundsChange:` method. This enables us to compare the view’s current bounds to the new value and only return `YES` if we have to:


    - (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
    {
        CGRect oldBounds = self.collectionView.bounds;
        if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
            return YES;
        }
        return NO;
    }

## Animation

### Insertions and Deletions

`UITableView` comes with a set of very nice pre-defined animations for cell insertions and deletions. When adding animation functionality for adding and removing cells to `UICollectionView`, UIKit engineers were faced with a problem: if the collection view’s layout is entirely flexible, there is no way some pre-defined animations will play well with developers’ custom layouts. The solution they came up with is very elegant: when a cell (or supplementary or decoration view) gets inserted into a collection view, the view asks its layout object not only for the cell’s “normal” layout attributes but also for its _initial_ layout attributes, i.e., the attributes the cell should have at the beginning of the insertion animation. The collection view then simply creates an animation block in which it changes all cell’s attributes from their _initial_ to their “normal” state.

By supplying different _initial_ layout attributes, you can completely customize the insertion animation. For example, setting the _initial_ `alpha` to `0` will create a fade-in animation. Setting a translation and scale transform at the same time will move and zoom the cell into place.

The same principle is applied to deletions, this time animating from the “normal” state to a set of _final_ layout attributes you provide. These are the methods you have to implement in your layout class to provide the initial/final layout attributes:

  * `initialLayoutAttributesForAppearingItemAtIndexPath:`
  * `initialLayoutAttributesForAppearingSupplementaryElementOfKind:atIndexPath:`
  * `initialLayoutAttributesForAppearingDecorationElementOfKind:atIndexPath:`
  * `finalLayoutAttributesForDisappearingItemAtIndexPath:`
  * `finalLayoutAttributesForDisappearingSupplementaryElementOfKind:atIndexPath:`
  * `finalLayoutAttributesForDisappearingDecorationElementOfKind:atIndexPath:`

### Switching Between Layouts

Changes from one collection view layout to another can be animated in a similar manner. When sent a `setCollectionViewLayout:animated:` method, the collection view will query the new layout for the new layout attributes of the cells and then animate each cell (identified by the same index path in the old and the new layout) from its old to its new attributes. You don’t have to do a thing.

## Conclusion

Depending on the complexity of a custom collection view layout, writing one is often not easy. In fact, it is essentially just as difficult as writing a totally custom view class that implements the same layout from scratch, since the computations that are involved to determine which subviews are currently visible and where they are positioned are identical. Nevertheless, using `UICollectionView` gives you some nice benefits such as cell reuse and automatic support for animations, not to mention the clean separation of layout, subview management, and data preparation its architecture prescribes.

A custom collection view layout is also a nice step toward a [lighter view controller][25] as your view controller does not contain any layout code. Combine this with a separate datasource class as explained in Chris’ article and the view controller for a collection view will hardly contain any code at all.

Whenever I use `UICollectionView`, I feel a certain admiration for its clean design. `NSTableView` and `UITableView` probably needed to come first in order for an experienced Apple engineer to come up with such a flexible class.

### Further Reading

  * [Collection View Programming Guide][26].
  * [NSHipster on `UICollectionView`][27].
  * [`UICollectionView`: The Complete Guide][28], e-book by Ash Furrow.
  * [`MSCollectionViewCalendarLayout`][29] by Eric Horacek is an excellent and more complete implementation of a custom layout for a week calendar view.




* * *

[More articles in issue #3][30]

  * [Privacy policy][31]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-3/index.html
   [5]: http://oleb.net
   [6]: http://oleb.net/blog/2012/09/uicollectionview/
   [7]: https://github.com/objcio/issue-3-collection-view-layouts
   [8]: http://developer.apple.com/library/ios/#documentation/general/conceptual/CocoaEncyclopedia/DelegatesandDataSources/DelegatesandDataSources.html
   [9]: http://developer.apple.com/library/ios/#documentation/uikit/reference/UICollectionViewLayout_class/Reference/Reference.html
   [10]: http://developer.apple.com/library/ios/#documentation/uikit/reference/UICollectionViewFlowLayout_class/Reference/Reference.html%23//apple_ref/occ/cl/UICollectionViewFlowLayout
   [11]: http://developer.apple.com/library/ios/documentation/WindowsViews/Conceptual/CollectionViewPGforIOS/UsingtheFlowLayout/UsingtheFlowLayout.html#//apple_ref/doc/uid/TP40012334-CH3-SW2
   [12]: http://developer.apple.com/library/ios/documentation/WindowsViews/Conceptual/CollectionViewPGforIOS/UsingtheFlowLayout/UsingtheFlowLayout.html#//apple_ref/doc/uid/TP40012334-CH3-SW4
   [13]: http://developer.apple.com/library/ios/#documentation/uikit/reference/UICollectionViewCell_class/Reference/Reference.html
   [14]: http://developer.apple.com/library/ios/#documentation/uikit/reference/UICollectionReusableView_class/Reference/Reference.html%23//apple_ref/occ/cl/UICollectionReusableView
   [15]: http://developer.apple.com/library/ios/documentation/UIKit/Reference/UICollectionView_class/Reference/Reference.html#//apple_ref/occ/instm/UICollectionView/registerClass:forCellWithReuseIdentifier:
   [16]: http://developer.apple.com/library/ios/documentation/UIKit/Reference/UICollectionView_class/Reference/Reference.html#//apple_ref/occ/instm/UICollectionView/registerNib:forCellWithReuseIdentifier:
   [17]: http://www.objc.io/images/issue-3/calendar-collection-view-layout.png
   [18]: http://developer.apple.com/library/ios/#documentation/uikit/reference/UIPageViewControllerClassReferenceClassRef/UIPageViewControllerClassReference.html
   [19]: http://developer.apple.com/library/ios/#documentation/uikit/reference/UICollectionViewLayoutAttributes_class/Reference/Reference.html
   [20]: http://www.objc.io/issue-3/collection-view-layouts.html#layout-attributes-for-...-at-index-path
   [21]: http://developer.apple.com/library/ios/documentation/UIKit/Reference/UICollectionViewLayout_class/Reference/Reference.html#//apple_ref/occ/instm/UICollectionViewLayout/layoutAttributesForItemAtIndexPath:
   [22]: http://developer.apple.com/library/ios/documentation/uikit/reference/UICollectionViewLayoutAttributes_class/Reference/Reference.html#//apple_ref/occ/clm/UICollectionViewLayoutAttributes/layoutAttributesForCellWithIndexPath:
   [23]: http://developer.apple.com/library/ios/documentation/uikit/reference/UICollectionViewLayoutAttributes_class/Reference/Reference.html#//apple_ref/occ/clm/UICollectionViewLayoutAttributes/layoutAttributesForSupplementaryViewOfKind:withIndexPath:
   [24]: http://developer.apple.com/library/ios/documentation/uikit/reference/UICollectionViewLayoutAttributes_class/Reference/Reference.html#//apple_ref/occ/clm/UICollectionViewLayoutAttributes/layoutAttributesForDecorationViewOfKind:withIndexPath:
   [25]: http://www.objc.io/issue-1/lighter-view-controllers.html
   [26]: http://developer.apple.com/library/ios/documentation/WindowsViews/Conceptual/CollectionViewPGforIOS/Introduction/Introduction.html#//apple_ref/doc/uid/TP40012334-CH1-SW1
   [27]: http://nshipster.com/uicollectionview/
   [28]: http://ashfurrow.com/uicollectionview-the-complete-guide/
   [29]: https://github.com/monospacecollective/MSCollectionViewCalendarLayout
   [30]: http://www.objc.io/issue-3
   [31]: http://www.objc.io/privacy.html
