[Source](http://www.objc.io/issue-1/testing-view-controllers.html "Permalink to Testing View Controllers - Lighter View Controllers - objc.io issue #1 ")

# Testing View Controllers - Lighter View Controllers - objc.io issue #1 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# Testing View Controllers

[Issue #1 Lighter View Controllers][4], June 2013

By [Daniel Eggert][5]

Let’s not be religious about testing. It should help us speed up development and make things more fun.

## Keeping Things Simple

Testing simple things is simple, and testing complex things is complex. As we point out in the other articles, keeping things small and simple is good in general. And as a side effect, it also helps testing. It’s a win-win. Take a look at [test-driven development][6] (known as TDD among friends) – some people love it, some don’t. We won’t go into detail about it here, but we will say that with TDD, you write the test for your code before you write the code. Check out the Wikipedia article if you’re curious. We would also like to note that refactoring and testing go very well together.

Testing UI components is often tricky because there are too many moving parts involved. More often than not, the view controller interacts with a lot of classes from both the model and the view layer. In order to be able to test the view controller, we need things to work in isolation.

There’s hope, though: The techniques we describe to make [lighter view controllers][7] also make testing easier. Generally, if you find something difficult to test, that’s a hint that your design may be broken and that you should refactor some of it. Again, refer to the article about [lighter view controllers][7] for some hints. An overall design goal is to have clear separation of concerns. Each class should do only one thing, and do that one thing well. That will then allow for testing of that one thing.

Remember: You’ll get diminishing returns as you add more tests. First and foremost, add simple tests. Branch into more sophisticated territory as you start to feel comfortable with it.

## Mocking

When we break things up into small components (i.e. small classes), we can test each class on its own. The class that we’re testing interacts with other classes. We get around this by using a so-called _mock_ or _stub_. Think of a _mock object_ as a placeholder. The class we’re testing will interact with placeholders instead of real objects. That way, we focus our test and ensure that it doesn’t depend on other parts of our app.

The example app has an array data source that we’ll test. The data source will at some point dequeue a cell from a table view. During testing, we don’t have a table view, but by passing a _mock_ table view, we can test the data source without a _real_ table view, as you’ll see below. It’s a bit confusing at first, but very powerful and straightforward once you’ve seen it a few times.

The power tool for mocking in Objective-C is called [OCMock][8]. It’s a very mature project that leverages the power and flexibility of the Objective-C runtime. It pulls some cool tricks to make testing with mock objects fun.

The data source test below shows, in more detail, how all of this plays out together.

## SenTestKit

The other tool we’ll use is the test framework that comes as part of the developer tools: SenTestingKit by [Sente][9]. This dinosaur has been around for Objective-C developers since 1997 – ten years before the iPhone was released. Today, it’s built into Xcode.

SenTestingKit is what will run your tests. With SenTestingKit, you organize tests into classes. You create one test class for each class you want to test. This class will have a name ending in `Tests`, and the name reflects what the class is about.

The methods inside each of these _tests_ classes will do the actual testing. The method name has to start with `test`, as that’s what triggers it to get run as a test. There are special `-setUp` and `-tearDown` methods you can override to set up each test. Remember that your test class is just a class: If it helps you structure your tests, feel free to add properties and helper methods.

A nice pattern when testing is to create a custom base class for the tests. We then put convenience logic in there to make our tests easier and more focused. Check out the [example project][10] for some samples of when this might be useful. We’re also not using the Xcode templates for tests – we’re going for something simpler and more efficient: We add a single `.m` file. By convention the tests class have a name ending in `Tests`. The name should reflect what we’re testing.

## Integration with Xcode

Tests are built into a bundle of a dynamic library plus resources of your choice. If you need particular resource files for your testing, add them to the test target, and Xcode will put them inside the bundle. You can then locate them with `NSBundle`. The example project implements a `-URLForResource:withExtension:` method to make it easy to use.

Each _scheme_ in Xcode defines what the corresponding test bundle should be. While ⌘-R runs your app, ⌘-U will run your tests.

The way the tests are run, your app is actually launched, and the test bundle is _injected_. You probably don’t want your app to do much, as it may interfere with the testing. Put something like this into your app delegate:


    static BOOL isRunningTests(void) __attribute__((const));

    - (BOOL)application:(UIApplication *)application
            didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
    {
        if (isRunningTests()) {
            return YES;
        }

        //
        // Normal logic goes here
        //

        return YES;
    }

    static BOOL isRunningTests(void)
    {
        NSDictionary* environment = [[NSProcessInfo processInfo] environment];
        NSString* injectBundle = environment[@"XCInjectBundle"];
        return [[injectBundle pathExtension] isEqualToString:@"octest"];
    }

Editing your scheme in Xcode gives you a great deal of flexibility. You can run scripts before and after the tests, and you can have multiple test bundles. This can be useful for larger projects. Most importantly, you can turn on and off individual tests. This can be useful for debugging tests – just remember to turn them all back on.

Also remember that you can set breakpoints in your code and in test cases and the debugger will stop there as the tests are executed.

##  Testing a Data Source

Let’s get started. We’ve made testing easier by splitting up the view controller. Now we’ll test the `ArrayDataSource`. First, we create a new and empty basic setup. We put both the interface and implementation into the same file; no one needs to include the `@interface` anywhere else, as it’s all nice and tidy inside one file:


    #import "PhotoDataTestCase.h"

    @interface ArrayDataSourceTest : PhotoDataTestCase
    @end

    @implementation ArrayDataSourceTest
    - (void)testNothing;
    {
        STAssertTrue(YES, @"");
    }
    @end

This will not do much. It shows the basic test setup. When we run the tests, the `-testNothing` method will run. The special `STAssert` macro will do its trivial check. Note that `ST` originates from SenTestingKit. These macros integrate with Xcode and will make failures show up in the _Issues_ navigator.

## Our First Test

We’ll now replace the `testNothing` method with a simple, but real test:


    - (void)testInitializing;
    {
        STAssertNil([[ArrayDataSource alloc] init], @"Should not be allowed.");
        TableViewCellConfigureBlock block = ^(UITableViewCell *a, id b){};
        id obj1 = [[ArrayDataSource alloc] initWithItems:@[]
                                          cellIdentifier:@"foo"
                                      configureCellBlock:block];
        STAssertNotNil(obj1, @"");
    }

## Putting Mocking into Practice

Next, we want to test the


    - (UITableViewCell *)tableView:(UITableView *)tableView
             cellForRowAtIndexPath:(NSIndexPath *)indexPath;

method that the ArrayDataSource implements. For that we create a


    - (void)testCellConfiguration;

test method.

First we create a data source:


    __block UITableViewCell *configuredCell = nil;
    __block id configuredObject = nil;
    TableViewCellConfigureBlock block = ^(UITableViewCell *a, id b){
        configuredCell = a;
        configuredObject = b;
    };
    ArrayDataSource *dataSource = [[ArrayDataSource alloc] initWithItems:@[@"a", @"b"]
                                                          cellIdentifier:@"foo"
                                                      configureCellBlock:block];

Note that the `configureCellBlock` doesn’t do anything except store the objects that it was called with. This allows us to easily test it.

Next, we’ll create a _mock object_ for a table view:


    id mockTableView = [OCMockObject mockForClass:[UITableView class]];

The data source is going to call `-dequeueReusableCellWithIdentifier:forIndexPath:` on the passed-in table view. We’ll tell the mock object what to do when it gets this message. We first create a `cell` and then set up the _mock_:


    UITableViewCell *cell = [[UITableViewCell alloc] init];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [[[mockTableView expect] andReturn:cell]
            dequeueReusableCellWithIdentifier:@"foo"
                                 forIndexPath:indexPath];

This will look a bit confusing at first. What’s going on here, is that the mock is _recording_ this particular call. The mock is not a table view; we’re just pretending that it is. The special `-expect` method allows us to set up the mock so that it knows what to do when this method gets called on it.

In addition, the `-expect` method tells the mock that this call _must_ happen. When we later call `-verify` on the mock, the test will fail if the method didn’t get called. The corresponding `-stub` method also sets up the mock object, but doesn’t care if the method will get called.

Now we’ll trigger the code to get run. We’ll call the method we want to test:


    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    id result = [dataSource tableView:mockTableView
                cellForRowAtIndexPath:indexPath];

and then we’ll test that things went well:


    STAssertEquals(result, cell, @"Should return the dummy cell.");
    STAssertEquals(configuredCell, cell, @"This should have been passed to the block.");
    STAssertEqualObjects(configuredObject, @"a", @"This should have been passed to the block.");
    [mockTableView verify];

The `STAssert` macros test that the values are identical. Note that we use pointer comparison for the first two tests; we don’t want to use `-isEqual:`. We actually want to test that `result` and `cell` and `configuredCell` all are the very same object. The third test uses `-isEqual:`, and finally we call `-verify` on our mock.

Note that in the example, we’re setting up the mock with


    id mockTableView = [self autoVerifiedMockForClass:[UITableView class]];

This is a convenience wrapper in our base test class which automatically calls `-verify` at the end of the test.

## Testing a UITableViewController

Next, we turn toward the `PhotosViewController`. It’s a `UITableViewController` subclass and it uses the data source we’ve just tested. The code that remains in the view controller is pretty simple.

We want to test that tapping on a cell takes us to the detail view, i.e. an instance of `PhotoViewController` is pushed onto the navigation controller. We’ll again use mocking to make the test depend as little as possible on other parts.

First we create a `UINavigationController` mock:


    id mockNavController = [OCMockObject mockForClass:[UINavigationController class]];

Next up, we’ll use _partial mocking_. We want our `PhotosViewController` instance to return the `mockNavController` as its `navigationController`. We can’t set the navigation controller directly, so we’ll simply stub only that method to return our `mockNavController` and forward everything else to the `PhotosViewController` instance:


     PhotosViewController *photosViewController = [[PhotosViewController alloc] init];
     id photosViewControllerMock = [OCMockObject partialMockForObject:photosViewController];
     [[[photosViewControllerMock stub] andReturn:mockNavController] navigationController];

Now, whenever the `-navigationController` method is called on `photosViewController`, it will return the `mockNavController`. This is a very powerful trick that OCMock has up its sleeve.

We now tell the navigation controller mock what we expect to be called, i.e. a detail view controller with `photo` set to a non-nil value:


    UIViewController* viewController = [OCMArg checkWithBlock:^BOOL(id obj) {
        PhotoViewController *vc = obj;
        return ([vc isKindOfClass:[PhotoViewController class]] &&
                (vc.photo != nil));
    }];
    [[mockNavController expect] pushViewController:viewController animated:YES];

Now we trigger the view to be loaded and simulate the row to be tapped:


    UIView *view = photosViewController.view;
    STAssertNotNil(view, @"");
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [photosViewController tableView:photosViewController.tableView
            didSelectRowAtIndexPath:indexPath];

Finally we verify that the expected method was called on the mocks:


    [mockNavController verify];
    [photosViewControllerMock verify];

We now have a test that tests interaction with the navigation controller and creation of the correct view controller.

Again, in the example project, we’re using our own convenience methods


    - (id)autoVerifiedMockForClass:(Class)aClass;
    - (id)autoVerifiedPartialMockForObject:(id)object;

and hence we don’t have to remember to call `-verify`.

## Further Possibilities

As you’ve seen above, _partial mocking_ is extremely powerful. If you take a look at the source code of the `-[PhotosViewController setupTableView]` method, you’ll see how it gets the model objects through the app delegate:


     NSArray *photos = [AppDelegate sharedDelegate].store.sortedPhotos;

The above test depends on this. One way to break this dependency would be to again use _partial mocking_ to make the app delegate return predefined data like so:


    id storeMock; // assume we've set this up
    id appDelegate = [AppDelegate sharedDelegate]
    id appDelegateMock = [OCMockObject partialMockForObject:appDelegate];
    [[[appDelegateMock stub] andReturn:storeMock] store];

Now whenever [`AppDelegate sharedDelegate].store` gets called, it will return the `storeMock`. This can be taken to extremes. Make sure to keep your tests as simple as possible and only as complex as needed.

## Things to Remember

Partial mocks alter the object they’re mocking for as long as they’re around. You can stop that behavior early by calling [`aMock stopMocking]`. Most of the time, you want the partial mock to stay active for the entire duration of the test. Make sure that happens by putting a [`aMock verify]` at the end of the test method. Otherwise ARC might dealloc the mock early. And you probably want that `-verify` anyway.

## Testing NIB Loading

The `PhotoCell` is setup in a NIB. We can write a simple test that checks that the outlets are set up correctly. Let’s review the `PhotoCell` class:


     @interface PhotoCell : UITableViewCell

     %2B (UINib *)nib;

     @property (weak, nonatomic) IBOutlet UILabel* photoTitleLabel;
     @property (weak, nonatomic) IBOutlet UILabel* photoDateLabel;

     @end

Our simple test implementation looks like this


    @implementation PhotoCellTests

    - (void)testNibLoading;
    {
        UINib *nib = [PhotoCell nib];
        STAssertNotNil(nib, @"");

        NSArray *a = [nib instantiateWithOwner:nil options:@{}];
        STAssertEquals([a count], (NSUInteger) 1, @"");
        PhotoCell *cell = a[0];
        STAssertTrue([cell isMemberOfClass:[PhotoCell class]], @"");

        // Check that outlets are set up correctly:
        STAssertNotNil(cell.photoTitleLabel, @"");
        STAssertNotNil(cell.photoDateLabel, @"");
    }

    @end

Very basic, but it does its job.

One may argue that we now need to update both the test and the class / nib when we change things. That’s true. We need to weigh this against the likelihood of breaking the outlets. If you’ve worked with `.xib` files, you’ve probably noticed that this is a commonly occurring thing.

## Side Note About Classes and Injection

As we noted under _Integration with Xcode_ the test bundle gets injected into the app. Without getting into too much detail about how injection works (it’s a huge topic in its own right): Injection adds the Objective-C classes from the injected bundle (our test bundle) to the running app. That’s good, because it allows us to run our tests.

One thing that can be very confusing, though, is if we add a class to both the app and the test bundle. If we, in the above example, would (by accident) have added the `PhotoCell` class to both the test bundle and the app, then the call to [`PhotoCell class]` would return a different pointer when called from inside our test bundle - that from within the app. And hence our test


    STAssertTrue([cell isMemberOfClass:[PhotoCell class]], @"");

would fail. Again: Injection is complex. Your take away should be: Don’t add `.m` files from your app to your test target. You’ll get unexpected behavior.

## Additional Thoughts

If you have a Continuous Integration solution, getting your tests up and running there is a great idea. Details are outside the scope of this article. The scripts are triggered by the `RunUnitTests` script, and there’s a `TEST_AFTER_BUILD` environment variable.

Another interesting option is to create an independent test bundle for automated performance tests. You’re free to do whatever you want inside your test methods. Timing certain calls and using `STAssert` to check that they’re within a certain threshold would be one option.

### Further Reading

  * [Test-driven development][6]
  * [OCMock][8]
  * [Xcode Unit Testing Guide][11]
  * [Book: Test Driven Development: By Example][12]
  * [Blog: Quality Coding][13]
  * [Blog: iOS Unit Testing][14]
  * [Blog: Secure Mac Programing][15]




* * *

[More articles in issue #1][16]

  * [Privacy policy][17]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-1/index.html
   [5]: https://twitter.com/danielboedewadt
   [6]: https://en.wikipedia.org/wiki/Test-driven_development
   [7]: http://www.objc.io/issue-1/lighter-view-controllers.html
   [8]: http://ocmock.org
   [9]: http://www.sente.ch
   [10]: https://github.com/objcio/issue-1-lighter-view-controllers/blob/master/PhotoDataTests/PhotoDataTestCase.h
   [11]: https://developer.apple.com/library/ios/documentation/DeveloperTools/Conceptual/UnitTesting/
   [12]: http://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530
   [13]: http://qualitycoding.org
   [14]: http://iosunittesting.com
   [15]: http://blog.securemacprogramming.com/?s=testing&searchsubmit=Search
   [16]: http://www.objc.io/issue-1
   [17]: http://www.objc.io/privacy.html
