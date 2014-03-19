[Source](http://www.objc.io/issue-5/collection-views-and-uidynamics.html "Permalink to UICollectionView + UIKit Dynamics - iOS 7 - objc.io issue #5 ")

# UICollectionView + UIKit Dynamics - iOS 7 - objc.io issue #5 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# UICollectionView %2B UIKit Dynamics

[Issue #5 iOS 7][4], October 2013

By [Ash Furrow][5]

UIKit Dynamics is the new physics-based animation engine in iOS 7 – it has been specifically designed to work well with collection views, which were first introduced in iOS 6. We’re going to take a tour of how you put these two together.

This article is going to discuss two examples of using collection views with UIKit Dynamics. The first example demonstrates how to reproduce the springy effect in the iOS 7 Messages app and is then amended to incorporate a tiling mechanism that makes the layout scalable. The second example shows how to use UIKit Dynamics to simulate a Newton’s Cradle where items can be added to the collection view one at a time, interacting with one another.

Before we get started, I’m going to assume that you have a baseline understanding of how `UICollectionView` works – see [this objc.io post][6] for all the details you’ll need. I’ll also assume that you understand how UIKit Dynamics works – see [this post][7] for more.

The two example projects for this article are on GitHub:

  * [`ASHSpringyCollectionView`][8] (based on [`UICollectionView` Spring Demo][9]
  * [Newtownian `UICollectionView`][10]

## The Dynamic Animator

The key component backing a `UICollectionView` that employes UIKit Dynamics is the `UIDynamicAnimator`. This class belongs inside a `UICollectionViewFlowLayout` object and should be strongly referenced by it (someone needs to retain the animator, after all).

When we create our dynamic animator, we’re not going to be giving it a reference view like we normally would. Instead, we’ll use a different initializer that requires a collection view layout as a parameter. This is critical, as the dynamic animator needs to be able to invalidate the collection view layout when the attributes of its behaviors’ items should be updated. In other words, the dynamic animator is going to be invalidating the layout a lot.

We’ll see how things are hooked up shortly, but it’s important to understand at a conceptual level how a collection view interacts with a dynamic animator. The collection view layout is going to add behaviors for each `UICollectionViewLayoutAttributes` object in the collection view (later, we’ll talk about tiling these). After adding these behaviors to the dynamic animator, the collection view layout is going to be queried by UIKit about the state of its collection view layout attributes. Instead of doing any calculations ourselves, we’re going to return the items provided by our dynamic animator. The animator is going to invalidate the layout whenever its simulation state changes. This will prompt UIKit to requery the layout, and the cycle continues until the simulation comes to a rest.

So to recap, the layout creates the dynamic animator and adds behaviors corresponding to the layout attributes for each of its items. When asked about layout information, it provides the information supplied by the dynamic animator.

## Subclassing UICollectionViewFlowLayout

We’re going to build a simple example of how to use UIKit Dynamics with a collection view layout. The first thing we need is, of course, a data source to drive our collection view. I know that you’re smart enough to provide your own data source, but for the sake of completeness, I’ve provided one for you:


    @implementation ASHCollectionViewController

    static NSString * CellIdentifier = @"CellIdentifier";

    -(void)viewDidLoad
    {
        [super viewDidLoad];
        [self.collectionView registerClass:[UICollectionViewCell class]
                forCellWithReuseIdentifier:CellIdentifier];
    }

    -(UIStatusBarStyle)preferredStatusBarStyle
    {
        return UIStatusBarStyleLightContent;
    }

    -(void)viewDidAppear:(BOOL)animated
    {
        [super viewDidAppear:animated];
        [self.collectionViewLayout invalidateLayout];
    }

    #pragma mark - UICollectionView Methods

    -(NSInteger)collectionView:(UICollectionView *)collectionView
        numberOfItemsInSection:(NSInteger)section
    {
        return 120;
    }

    -(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                     cellForItemAtIndexPath:(NSIndexPath *)indexPath
    {
        UICollectionViewCell *cell = [collectionView
            dequeueReusableCellWithReuseIdentifier:CellIdentifier
                                      forIndexPath:indexPath];

        cell.backgroundColor = [UIColor orangeColor];
        return cell;
    }

    @end

Notice that it’s invalidating the layout when the view first appears. That’s a consequence of not using Storyboards (the timing of the first invocation of the prepareLayout method is different when using Storyboards – or not – something they didn’t tell you in the WWDC video). As a result, we need to manually invalidate the collection view layout once the view appears. When we use tiling, this isn’t necessary.

Let’s create our collection view layout. We need to have a strong reference to a dynamic animator that will drive the attributes of our collection view layout. We’ll have a private property declared in the implementation file:


    @interface ASHSpringyCollectionViewFlowLayout ()

    @property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;

    @end

We’ll initialize our dynamic animator in the init method of the layout. We’ll also set up some of our properties belonging to `UICollectionViewFlowLayout`, our superclass:


    - (id)init
    {
        if (!(self = [super init])) return nil;

        self.minimumInteritemSpacing = 10;
        self.minimumLineSpacing = 10;
        self.itemSize = CGSizeMake(44, 44);
        self.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);

        self.dynamicAnimator = [[UIDynamicAnimator alloc] initWithCollectionViewLayout:self];

        return self;
    }

The next method we’ll implement is prepareLayout. We’ll need to call our superclass’s implementation first. Since we’re subclassing `UICollectionViewFlowLayout`, calling super’s prepareLayout method will position the collection view layout attributes for us. We can now rely on them being laid out and can ask for all of the attributes in a given rect. Let’s load _all_ of them.


    [super prepareLayout];

    CGSize contentSize = self.collectionView.contentSize;
    NSArray *items = [super layoutAttributesForElementsInRect:
        CGRectMake(0.0f, 0.0f, contentSize.width, contentSize.height)];

This is _really_ inefficient code. Since our collection view could have tens of thousands of cells, loading all of them at once is potentially an incredibly memory-intensive operation. We’re going to iterate over those elements in a moment, making this a time-intensive operation as well. An efficiency double-whammy! Don’t worry – we’re responsible developers so we’ll solve this problem shortly. For now, we’ll just continue on with a simple, naïve implementation.

After loading all of our collection view layout attributes, we need to check and see if they’ve already been added to our animator. If a behavior for an item already exists in the animator, then we can’t re-add it or we’ll get a very obscure runtime exception:


     (0.004987s) in
     \{\{0, 0}, \{0, 0\}\}:
    body  type: representedObject:
    [
    index path: ( {length = 2, path = 0 - 0});
    frame = (10 10; 300 44); ] 0xa2877c0
    PO:(159.999985,32.000000) AN:(0.000000) VE:(0.000000,0.000000) AV:(0.000000)
    dy:(1) cc:(0) ar:(1) rs:(0) fr:(0.200000) re:(0.200000) de:(1.054650) gr:(0)
    without representedObject for item 
    index path: ( {length = 2, path = 0 - 0});
    frame = (10 10; 300 44);

If you see this error, then it basically means that you’re adding two behaviors for identical `UICollectionViewLayoutAttributes`, which the system doesn’t know how to handle.

At any rate, once we’ve checked that we haven’t already added behaviors to our dynamic animator, we’ll need to iterate over each of our collection view layout attributes to create and add a new dynamic behavior:


    if (self.dynamicAnimator.behaviors.count == 0) {
        [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIAttachmentBehavior *behaviour = [[UIAttachmentBehavior alloc] initWithItem:obj
                                                                        attachedToAnchor:[obj center]];

            behaviour.length = 0.0f;
            behaviour.damping = 0.8f;
            behaviour.frequency = 1.0f;

            [self.dynamicAnimator addBehavior:behaviour];
        }];
    }

The code is very straightforward. For each of our items, we create a new `UIAttachmentBehavior` with the center of the item as the attachment point. We then set the length of our attachment behavior to zero so that it requires the cell to be centered under the behavior’s attachment point at all times. We then set the damping and frequency to some values that I determined experimentally to be visually pleasing and not over-the-top.

That’s it for prepareLayout. We now need to respond to two methods that UIKit will call to query us about the layout of collection view layout attributes, `layoutAttributesForElementsInRect:` and `layoutAttributesForItemAtIndexPath:`. Our implementations will forward these queries onto the dynamic animator, which has methods specifically designed to respond to these queries:


    -(NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
    {
        return [self.dynamicAnimator itemsInRect:rect];
    }

    -(UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
    {
        return [self.dynamicAnimator layoutAttributesForCellAtIndexPath:indexPath];
    }

## Responding to Scroll Events

What we’ve implemented so far will provide a static-feeling `UICollectionView` that scrolls normally; there is nothing special about the way that it works. That’s fine, but it’s not really _dynamic_, is it?

In order to behave dynamically, we need our layout and dynamic animator to react to changes in the scroll position of the collection view. Luckily there is a method perfectly suited for our task called `shouldInvalidateLayoutForBoundsChange:`. This method is called when the bounds of the collection view change and it provides us with an opportunity to adjust the behaviors’ items in our dynamic animator to the new [content offset][11]. After adjusting the behaviors’ items, we’re going to return NO from this method; since the dynamic animator will take care of invalidating our layout, there’s no need to invalidate it in this case:


    -(BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
    {
        UIScrollView *scrollView = self.collectionView;
        CGFloat delta = newBounds.origin.y - scrollView.bounds.origin.y;

        CGPoint touchLocation = [self.collectionView.panGestureRecognizer locationInView:self.collectionView];

        [self.dynamicAnimator.behaviors enumerateObjectsUsingBlock:^(UIAttachmentBehavior *springBehaviour, NSUInteger idx, BOOL *stop) {
            CGFloat yDistanceFromTouch = fabsf(touchLocation.y - springBehaviour.anchorPoint.y);
            CGFloat xDistanceFromTouch = fabsf(touchLocation.x - springBehaviour.anchorPoint.x);
            CGFloat scrollResistance = (yDistanceFromTouch %2B xDistanceFromTouch) / 1500.0f;

            UICollectionViewLayoutAttributes *item = springBehaviour.items.firstObject;
            CGPoint center = item.center;
            if (delta < 0) {
                center.y %2B= MAX(delta, delta*scrollResistance);
            }
            else {
                center.y %2B= MIN(delta, delta*scrollResistance);
            }
            item.center = center;

            [self.dynamicAnimator updateItemUsingCurrentState:item];
        }];

        return NO;
    }

Let’s go through this implementation in detail. First, we grab the scroll view (that’s our collection view) and calculate the change in the content offset’s y component (our collection view scrolls vertically in this example). Once we have the delta, we need to grab the location of the user’s touch. This is important because we want items closer to the touch to move more immediately while items further from the touch should lag behind.

For each behavior in our dynamic animator, we divide the sum of the x and y distances from the touch to the behavior’s item by a denominator of 1500, a value determined experimentally. Use a smaller denominator to make the collection view react with more spring. Once we have this “scroll resistance,” we move the behavior’s item’s center.y component by that delta, multiplied by the scrollResistance variable. Finally, note that we clamp the product of the delta and scroll resistance by the delta in case the scroll resistance exceeds the delta (meaning the item might begin to move in the wrong direction). This is unlikely since we’re using such a high denominator, but it’s something to watch out for in more bouncy collection view layouts.

That’s really all there is to it. In my experience, this naïve approach is effective for collection views with up to a few hundred items. Beyond that, the burden of loading all the items into memory at once becomes too great and you’ll begin to drop frames when scrolling.

![Springy Collection View][12]

## Tiling your Dynamic Behaviors for Performance

A few hundred cells is all well and good, but what happens when your collection view data source exceeds that size? Or what if you can’t predict exactly how large your data source will grow at runtime? Our naïve approach breaks down.

Instead of loading _all_ of our items in prepareLayout, it would be nice if we could be _smarter_ about which items we load. Say, just the items that are visible or are about to become visible. That’s exactly the approach that we’re going to take.

The first thing we need to do is keep track of all of the index paths that are currently represented by behaviors’ items in the dynamic animator. We’ll add a property to our collection view layout to do this:


    @property (nonatomic, strong) NSMutableSet *visibleIndexPathsSet;

We’re using a set because it features constant-time lookup for testing inclusion, and we’ll be testing for inclusion _a lot_.

Before we dive into a whole new prepareLayout method – one that tiles behaviors – it’s important to understand what tiling means. When we tile behaviors, we’re removing behaviors as their items leave the visible bounds of the collection view and adding behaviors as their items enter the visible bounds. There’s a big challenge though: when we create new behaviors, we need to create them _in flight_. That means creating them as though they were already in the dynamic animator and being modified by the `shouldInvalidateLayoutForBoundsChange:` method.

Since we’re creating these new behaviors in flight, we need to maintain some state of our current collection view. In particular, we need to keep track of the latest delta in our bounds change. This state will be used to create our behaviors in flight:


    @property (nonatomic, assign) CGFloat latestDelta;

After adding this property, we’ll add the following line to our `shouldInvalidateLayoutForBoundsChange:` method:


    self.latestDelta = delta;

That’s all we need to modify to our method that responds to scrolling events. Our two methods for relaying queries about the layout of items in the collection view to the dynamic animator remain completely unchanged. Actually, most of the time, when backing your collection view with a dynamic animator, you’ll have `layoutAttributesForElementsInRect:` and `layoutAttributesForItemAtIndexPath:` implemented the way we have them above.

The most complicated bit is now the tiling mechanism. We’re going to completely rewrite our prepareLayout.

The first step of this method is going to be to remove certain behaviors from the dynamic animator where those behaviors represent items whose index paths are no longer on screen. The second step is to add new behaviors for items that are _becoming_ visible. Let’s take a look at the first step.

Like before, we’re going to call [`super prepareLayout]` so that we can rely on the layout information provided by `UICollectionViewFlowLayout`, our superclass. Also like before, we’re going to be querying our superclass for the layout attributes for the elements in a rect. The difference is that instead of asking about attributes for elements in the _entire collection view_, we’re going to only query about elements in the _visible rect_.

So we need to calculate the visible rect. But not so fast! There’s one thing to keep in mind. Our user might scroll the collection view too fast for the dynamic animator to keep up, so we need to expand the visible rect slightly so that we’re including items that are _about_ to become visible. Otherwise, flickering could appear when scrolling quickly. Let’s calculate our visible rect:


    CGRect originalRect = (CGRect){.origin = self.collectionView.bounds.origin, .size = self.collectionView.frame.size};
    CGRect visibleRect = CGRectInset(originalRect, -100, -100);

I determined that insetting the actual visible rect by -100 points in both directions works for my demo. Double-check these values for your collection view, especially if your cells are really small.

Next we need to collect the collection view layout attributes which lie within the visible rect. Let’s also collect their index paths:


    NSArray *itemsInVisibleRectArray = [super layoutAttributesForElementsInRect:visibleRect];

    NSSet *itemsIndexPathsInVisibleRectSet = [NSSet setWithArray:[itemsInVisibleRectArray valueForKey:@"indexPath"]];

Notice that we’re using an NSSet. That’s because we’re going to be testing for inclusion within that set and we want constant-time lookup:

What we’re going to do is iterate over our dynamic animator’s behaviors and filter out the ones that represent items that are in our `itemsIndexPathsInVisibleRectSet`. Once we’ve filtered our behaviors, we’ll iterate over the ones that are no longer visible and remove those behaviors from the animator (along with the index paths from the `visibleIndexPathsSet` property):


    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(UIAttachmentBehavior *behaviour, NSDictionary *bindings) {
        BOOL currentlyVisible = [itemsIndexPathsInVisibleRectSet member:[[[behaviour items] firstObject] indexPath]] != nil;
        return !currentlyVisible;
    }]
    NSArray *noLongerVisibleBehaviours = [self.dynamicAnimator.behaviors filteredArrayUsingPredicate:predicate];

    [noLongerVisibleBehaviours enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
        [self.dynamicAnimator removeBehavior:obj];
        [self.visibleIndexPathsSet removeObject:[[[obj items] firstObject] indexPath]];
    }];

The next step is to calculate a list of `UICollectionViewLayoutAttributes` that are _newly_ visible – that is, ones whose index paths are in `itemsIndexPathsInVisibleRectSet` but not in our property `visibleIndexPathsSet`:


    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *item, NSDictionary *bindings) {
        BOOL currentlyVisible = [self.visibleIndexPathsSet member:item.indexPath] != nil;
        return !currentlyVisible;
    }];
    NSArray *newlyVisibleItems = [itemsInVisibleRectArray filteredArrayUsingPredicate:predicate];

Once we have our newly visible layout attributes, we can iterate over them to create our new behaviors and add their index paths to our `visibleIndexPathsSet` property. First, however, we’ll need to grab the touch location of our user’s finger. If it’s CGPointZero, then we know that the user isn’t scrolling the collection view and we can _assume_ that we don’t have to create new behaviors in flight:


    CGPoint touchLocation = [self.collectionView.panGestureRecognizer locationInView:self.collectionView];

This is a potentially dangerous assumption. What if the user has scrolled the collection view quickly and released his or her finger? The collection view would still be scrolling but our method wouldn’t create the new behaviors in flight. Luckily, that also means that the scroll view is scrolling too fast to notice! Huzzah! This might become a problem, however, for collection views using large cells. In this case, increase the bounds of your visible rect so you’re loading more items.

Now we need to enumerate our newly visible items and create new behaviors for them and add their index paths to our `visibleIndexPathsSet` property. We’ll also need to do some [math][13] to create the behavior in flight:


    [newlyVisibleItems enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *item, NSUInteger idx, BOOL *stop) {
        CGPoint center = item.center;
        UIAttachmentBehavior *springBehaviour = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:center];

        springBehaviour.length = 0.0f;
        springBehaviour.damping = 0.8f;
        springBehaviour.frequency = 1.0f;

        if (!CGPointEqualToPoint(CGPointZero, touchLocation)) {
            CGFloat yDistanceFromTouch = fabsf(touchLocation.y - springBehaviour.anchorPoint.y);
            CGFloat xDistanceFromTouch = fabsf(touchLocation.x - springBehaviour.anchorPoint.x);
            CGFloat scrollResistance = (yDistanceFromTouch %2B xDistanceFromTouch) / 1500.0f;

            if (self.latestDelta < 0) {
                center.y %2B= MAX(self.latestDelta, self.latestDelta*scrollResistance);
            }
            else {
                center.y %2B= MIN(self.latestDelta, self.latestDelta*scrollResistance);
            }
            item.center = center;
        }

        [self.dynamicAnimator addBehavior:springBehaviour];
        [self.visibleIndexPathsSet addObject:item.indexPath];
    }];

A lot of this code should look familiar. About half of it is from our naïve implementation of prepareLayout without tiling. The other half is from our `shouldInvalidateLayoutForBoundsChange:` method. We use our latestDelta property in lieu of a calculated delta from a bounds change and adjust the center point of our `UICollectionViewLayoutAttributes` appropriately so that the cell it represents will be “pulled” by the attachment behavior.

And that’s it. Really! I’ve tested this on a device displaying ten thousand cells and it works perfectly. Go [give it a shot][8].

## Beyond Flow Layouts

As usual, when working with `UICollectionView`, it’s easier to subclass `UICollectionViewFlowLayout` rather than `UICollectionViewLayout` itself. This is because _flow_ layouts will do a lot of the work for us. However, flow layouts are restricted to line-based, breaking layouts. What if you have a layout that doesn’t fit that criteria? Well, if you’ve already tried fitting it into a `UICollectionViewFlowLayout` and you’re sure that won’t work, then it’s time to break out the heavy-duty `UICollectionViewLayout` subclass.

This is true when dealing with UIKit Dynamics as well.

Let’s subclass `UICollectionViewLayout`. It’s very important to implement `collectionViewContentSize` when subclassing `UICollectionViewLayout`. Otherwise the collection view won’t have any idea how to display itself and nothing will be displayed at all. Since we want our collection view not to scroll at all, we’ll return our collection view’s frame’s size, minus its contentInset.top component:


    -(CGSize)collectionViewContentSize
    {
        return CGSizeMake(self.collectionView.frame.size.width,
            self.collectionView.frame.size.height - self.collectionView.contentInset.top);
    }

In this (somewhat pedagogical) example, our collection view _always begins_ with zero cells and items are added via `performBatchUpdates:`. That means that we have to use the `-[UICollectionViewLayout prepareForCollectionViewUpdates:]` method to add our behaviors (i.e. the collection view data source always starts at zero).

Instead of just adding an attachment behavior for each individual item, we’ll also maintain two other behaviors: gravity and collision. For each item we add to the collection view, we’ll have to add these items to our collision and attachment behaviors. The final step is to set the item’s initial position to somewhere offscreen so that it’s pulled onscreen by the attachment behavior:


    -(void)prepareForCollectionViewUpdates:(NSArray *)updateItems
    {
        [super prepareForCollectionViewUpdates:updateItems];

        [updateItems enumerateObjectsUsingBlock:^(UICollectionViewUpdateItem *updateItem, NSUInteger idx, BOOL *stop) {
            if (updateItem.updateAction == UICollectionUpdateActionInsert) {
                UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes
                    layoutAttributesForCellWithIndexPath:updateItem.indexPathAfterUpdate];

                attributes.frame = CGRectMake(CGRectGetMaxX(self.collectionView.frame) %2B kItemSize, 300, kItemSize, kItemSize);

                UIAttachmentBehavior *attachmentBehaviour = [[UIAttachmentBehavior alloc] initWithItem:attributes
                                                                                      attachedToAnchor:attachmentPoint];
                attachmentBehaviour.length = 300.0f;
                attachmentBehaviour.damping = 0.4f;
                attachmentBehaviour.frequency = 1.0f;
                [self.dynamicAnimator addBehavior:attachmentBehaviour];

                [self.gravityBehaviour addItem:attributes];
                [self.collisionBehaviour addItem:attributes];
            }
        }];
    }

![Demo][14]

Deletion is far more complicated. We want the item to “fall off” instead of simply disappearing. This involves more than just removing the cell from the collection view, as we want it to remain in the collection view until it moves offscreen. I’ve implemented something to that effect in the code, but it is a bit of a cheat.

What we basically do is provide a method in the layout that removes the attachment behavior, then, after two seconds, removes the cell from the collection view. We’re hoping that in that time, the cell can fall offscreen, but that’s not necessarily going to happen. If it doesn’t, that’s OK. It’ll just fade away. However, we also have to prevent new cells from being added and old cells from being deleted during this two-second interval. (I said it was a cheat.)

Pull requests welcome.

This approach is somewhat limited. I’ve capped the number of cells at ten, but even then the animation is slow on older hardware like the second-generation iPad. However, this example is supposed to be demonstrative of the approach you can take for interesting dynamics simulations – it’s not meant to be a turn-key solution for any data set. The individual aspects of your simulation, including its performance, are up to you.




* * *

[More articles in issue #5][15]

  * [Privacy policy][16]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-5/index.html
   [5]: https://twitter.com/ashfurrow
   [6]: http://www.objc.io/issue-3/collection-view-layouts.html
   [7]: http://www.teehanlax.com/blog/introduction-to-uikit-dynamics/
   [8]: https://github.com/objcio/issue-5-springy-collection-view
   [9]: https://github.com/TeehanLax/UICollectionView-Spring-Demo
   [10]: https://github.com/objcio/issue-5-newtonian-collection-view
   [11]: http://www.objc.io/issue-3/scroll-view.html#scroll_views_content_offset
   [12]: http://www.objc.io/images/issue-5/springyCollectionView.gif
   [13]: http://www.youtube.com/watch?v=gENVB6tjq_M
   [14]: http://www.objc.io/images/issue-5/newtonianCollectionView@2x.gif
   [15]: http://www.objc.io/issue-5
   [16]: http://www.objc.io/privacy.html
