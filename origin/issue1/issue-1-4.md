[Source](http://www.objc.io/issue-1/containment-view-controller.html "Permalink to View Controller Containment - Lighter View Controllers - objc.io issue #1 ")

# View Controller Containment - Lighter View Controllers - objc.io issue #1 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# View Controller Containment

[Issue #1 Lighter View Controllers][4], June 2013

By [Ricki Gregersen][5]

Before iOS 5, view controller containers were a privilege for Apple only. In fact, there was a passage in the view controller programming guide stating that you should not use them. The general advice from Apple on view controllers used to be that a view controller manages a screenful of content. This has since changed to a view controller manages a self-contained unit of content. Why didn’t Apple want us to build our own tab bar controllers and navigation controllers? Or put more precisely, what is the problem with:


    [viewControllerA.view addSubView:viewControllerB.view]

![Inconsistent view hierarchy][6]

The UIWindow, which serves as an app’s root view, is where rotation and initial layout messages originate from. In the illustration above, the child view controller, whose view was inserted in the root view controller view hierarchy, is excluded from those events. View event methods like `viewWillAppear:` will not get called.

The custom view controller containers built before iOS 5 would keep a reference to the child view controllers and manually relay all the view event methods called on the parent view controller, which is pretty difficult to get right.

## An Example

When you were a kid playing in the sand, did your parents ever tell you that if you kept digging with your little shovel you would end up in China? Mine did, and I made a small demo app called _Tunnel_ to test this claim. You can clone the [GitHub repo][7] and run the app, which will make it easier to understand the example code. _(Spoiler: digging through the earth from western Denmark lands you somewhere in the South Pacific Ocean.)_

![Tunnel screenshot][8]

To find the antipode, as the opposite location is called, move the little guy with the shovel around and the map will tell you where your exit location is. Tap the radar button and the map will flip to reveal the name of the location.

There are two map view controllers on screen. Each of them has to deal with dragging, annotation, and updating the map. Flipping these over reveals two new view controllers which reverse geocode the locations. All the view controllers are contained inside a parent view controller, which holds their views, and ensures that layout and rotation behaves as expected.

The root view controller has two container views. These are added to make it easier to layout and animate the views of child view controllers, as we will see later on.


    - (void)viewDidLoad
    {
        [super viewDidLoad];

        //Setup controllers
        _startMapViewController = [RGMapViewController new];
        [_startMapViewController setAnnotationImagePath:@"man"];
        [self addChildViewController:_startMapViewController];          //  1
        [topContainer addSubview:_startMapViewController.view];         //  2
        [_startMapViewController didMoveToParentViewController:self];   //  3
        [_startMapViewController addObserver:self
                                  forKeyPath:@"currentLocation"
                                     options:NSKeyValueObservingOptionNew
                                     context:NULL];

        _startGeoViewController = [RGGeoInfoViewController new];        //  4
    }

The `_startMapViewController`, which displays the starting position, is instantiated and set up with the annotation image.

  1. The `_startMapViewcontroller` is added as a child of the root view controller. This automatically calls the method `willMoveToParentViewController:` on the child.
  2. The child’s view is added as a subview of the first container view.
  3. The child is notified that it now has a parent view controller.
  4. The child view controller that does the geocoding is instantiated, but not inserted in any view or controller hierarchy yet.

## Layout

The root view controller defines the two container views, which determine the size of the child view controllers. The child view controllers do not know which container they will be added to, and therefore have to be flexible in size:


    - (void) loadView
    {
        mapView = [MKMapView new];
        mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleHeight;
        [mapView setDelegate:self];
        [mapView setMapType:MKMapTypeHybrid];

        self.view = mapView;
    }

Now they will layout using the bounds of their super view. This increases the reusability of the child view controller; if we were to push it on the stack of a navigation controller, it would still layout correctly.

## Transitions

Apple has made the view controller containment API so fine-grained that it is possible to construct and animate any containment scenario we can think of. Apple also provides a block-based convenience method for exchanging two controller views on the screen. The method `transitionFromViewController:toViewController:(...)` takes care of a lot of the details for us:


    - (void) flipFromViewController:(UIViewController*) fromController
                   toViewController:(UIViewController*) toController
                      withDirection:(UIViewAnimationOptions) direction
    {
        toController.view.frame = fromController.view.bounds;                           //  1
        [self addChildViewController:toController];                                     //
        [fromController willMoveToParentViewController:nil];                            //

        [self transitionFromViewController:fromController
                          toViewController:toController
                                  duration:0.2
                                   options:direction | UIViewAnimationOptionCurveEaseIn
                                animations:nil
                                completion:^(BOOL finished) {

                                    [toController didMoveToParentViewController:self];  //  2
                                    [fromController removeFromParentViewController];    //  3
                                }];
    }

  1. Before the animation we add the `toController` as a child and we inform the `fromController` that it will be removed. If the fromController’s view is part of the container’s view hierarchy, this is where `viewWillDisapear:` is called.
  2. `toController` is informed of its new parent, and appropriate view event methods will be called.
  3. The `fromController` is removed.

This convenience method for view controller transitions automatically swaps out the old view controller’s view for the new one. However, if you implement your own transition and you wish to only display one view at a time, you have to call `removeFromSuperview` on the old view and `addSubview:` for the new view yourself. Getting the sequence of method calls wrong will most likely result in an `UIViewControllerHierarchyInconsistency` warning. For example, this will happen if you call `didMoveToParentViewController:` before you added the view.

In order to be able to use the `UIViewAnimationOptionTransitionFlipFromTop` animation, we had to add the children’s views to our view containers instead of to the root view controller’s view. Otherwise the animation would result in the entire root view flipping over.

## Communication

View controllers should be reusable and self-contained entities. Child view controllers are no exception to this rule of thumb. In order to achieve this, the parent view controller should only be concerned with two tasks: laying out the child view controller’s root view, and communicating with the child view controller through its exposed API. It should never modify the child’s view tree or other internal state directly.

Child view controllers should contain the necessary logic to manage their view trees themselves – don’t treat them as dumb views. This will result in a clearer separation of concerns and better reusability.

In the Tunnel example app, the parent view controller observes a property called `currentLocation` on the map view controllers:


    [_startMapViewController addObserver:self
                              forKeyPath:@"currentLocation"
                                 options:NSKeyValueObservingOptionNew
                                 context:NULL];

When this property changes in response to moving the little guy with the shovel around on the map, the parent view controller communicates the antipode of the new location to the other map:


    [oppositeController updateAnnotationLocation:[newLocation antipode]];

Likewise, when you tap the radar button, the parent view controller sets the locations to be reverse geocoded on the new child view controllers:


    [_startGeoViewController setLocation:_startMapViewController.currentLocation];
    [_targetGeoViewController setLocation:_targetMapViewController.currentLocation];

Independent of the technique you choose to communicate from child to parent view controllers (KVO, notifications, or the delegate pattern), the goal always stays the same: the child view controllers should be independent and reusable. In our example we could push one of the child view controllers on a navigation stack, but the communication would still work through the same API.




* * *

[More articles in issue #1][9]

  * [Privacy policy][10]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-1/index.html
   [5]: https://twitter.com/rickigregersen
   [6]: http://www.objc.io/images/issue-1/view-insertion@2x.png
   [7]: https://github.com/RickiG/view-controller-containment
   [8]: http://www.objc.io/images/issue-1/tunnel-screenshot@2x.png
   [9]: http://www.objc.io/issue-1
   [10]: http://www.objc.io/privacy.html
