---
layout: post
title:  "Android 101 for iOS Developers 为 iOS 开发者准备的 Android 入门"
category: "11"
date: "2014-04-01 11:00:00"
tags: article
author: "<a href=\"https://twitter.com/smbarne\">Stephen Barnes</a>"
---


As the mobile software industry evolves, it is becoming increasingly impractical to target only iOS for a mobile product. Android market share is approaching 80 percent for smartphones,[^1] and the number of potential users that it can bring to a product can hardly be ignored.

随着移动软件工业的发展，一个移动产品只局限于 iOS 系统变得越来越不切实际。 Android 目前占有近 80% 的智能手机份额，它能给一个产品带来的潜在用户数量实在不能被忽略了。

In this article, I will introduce the core concepts of Android development within the context of iOS development. Android and iOS work on similar problem sets, but they approach many of these problems in different ways. Throughout the article, I will be using a companion project (available on [GitHub](https://github.com/objcio/issue-11-android-101)) to illustrate how to accomplish the same tasks when developing for both platforms.

在本文中，我会在 iOS 的开发范围内介绍 Android 开发的核心内容。 Android 和 iOS 处理类似的问题集，但在大部分问题上，它们都有不同的解决方式。通过本文，我会使用一个配套项目（在[GitHub](https://github.com/objcio/issue-11-android-101)上）来说明如何在两个平台上开发以完成相同的任务。

In addition to a working knowledge of iOS development, I assume that you have a working knowledge of Java and are able to install and use the [Android Development Tools](http://developer.android.com/tools/index.html). Furthermore, if you are new to Android development, reading through the tutorial by Google about [building your first app](http://developer.android.com/training/basics/firstapp/index.html) could be very helpful.

除了 iOS 开发的相关知识，我假设你在 Java 上也有一定经验，能够安装和使用[ADT（Android Development Tools）](http://developer.android.com/tools/index.html)。此外，如果你最近才开始 Android 开发，读一遍 Google 编写的关于[创建你的第一个应用](http://developer.android.com/training/basics/firstapp/index.html)的教程会很有帮助。

### A Brief Word on UI Design UI设计概要

This article will not delve deeply into the user experience and design pattern differences between iOS and Android. However, it would be beneficial to understand some of the key UI paradigms in use on Android today: the action bar, the overflow menu, the back button, the share action, and more. If you are seriously considering Android development, I highly recommending looking into the [Nexus 5](https://play.google.com/store/devices/details?id=nexus_5_white_16gb) from the Google Play Store. Make it your full-time device for a week and force yourself to try the operating system to its fullest extent. A developer who doesn't know the key use patterns of his or her operating system is a liability to the product.

本文不会深入到介绍 iOS 和 Android 在用户体验和设计模式上的不同，这将有利于了解一些当今 Android 上使用的关键 UI 范式：Action Bar、Overflow Menu、Back Button、Share Action 等。如果你正在认真考虑 Android 开发，我推荐你使用来自 Google Play Store 的[Nexus 5](https://play.google.com/store/devices/details?id=nexus_5_white_16gb)作为你的首要设备，用满一周，强迫自己最大程度的体验这个操作系统。一个开发者若不清楚他/她的操作系的关键使用模式，则是对产品的不负责任。

## Language Application Structure 语言应用结构

### Java

There are many differences between Objective-C and Java, and while it may be tempting to bring some of Objective-C's styling into Java, it can lead to a codebase that heavily clashes with the primary framework that drives it. In brief, here are a few gotchas to watch for:

Objective-C 和 Java 之间有很多不同，虽然若能将 Objective-C 的方式带入 Java 可能会很有诱惑力，但这样做很可能导致代码库与驱动它的主要框架产生冲突。总之，有一些需要提防地陷阱：

- Leave class prefixes at home on Objective-C. Java has actual namespacing and package management, so there is no need for class prefixes here.
- 类前缀就留在Objective-C家里好了。Java有实在的命名空间和包管理，所以不再需要类前缀。
- Instance variables are prefixed with `m`, not `_`.- Take advantage of JavaDoc to write method and class descriptions for as much of your code as possible. It will make your life and the lives of others better.
- 实例变量的前缀是`m`，不是`_`。尽可能多的在代码里使用JavaDoc来写方法和类描述，它能让你和其他人的生活更好过。
- Null check! Objective-C gracefully handles message sending to nil objects, but Java does not.
- Null检查！Objective-C能妥善处理向nil发送消息，但Java不行。
- Say goodbye to properties. If you want setters and getters, you have to remember to actually create a getVariableName() method and call it explicitly. Referencing `this.object` will **not** call your custom getter. You must use `this.getObject`.
- 向属性说再见。如果你想要setter和getter，你只能实际地创建一个getVariableName()方法，并显式的调用它。引用`this.object`**不会**调用你自定义地getter，你必须使用`this.getObjct`。
- Similarly, prefix method names with `get` and `set` to indicate getters and setters. Java methods are typically written as actions or queries, such as `getCell()`, instead of `cellForRowAtIndexPath:`.
- 同样的，给方法名加上`get`和`set`前缀来更好的识别 getter 和 setter 。Java方法通常写为动作和查询，例如`getCell()`，而不是`cellForRowAtIndexPath:`。

   
### Project Structure 项目结构

Android applications are primarily broken into two sections, the first of which is the Java source code. The source code is structured via the Java package hierarchy, and it can be structured as you please. However, a common practice is to use top-level categories for activities, fragments, views, adapters, and data (models and managers).

Android 应用主要分为两个部分，第一部分是 Java 源代码。源代码结构通过 Java 包继承实现，所以可按照你的喜好来决定。然而一个常见的实践是为Activity、Fragment、View、Adapter 和 Data（模型和管理器）使用顶层的类别（top-level categories）。

The second major section is the `res` folder, short for 'resource' folder. The `res` folder is a collection of images, XML layout files, and XML value files that make up the bulk of the non-code assets. On iOS, images are either `@2x` or not, but on Android there are a number of screen density folders to consider.[^2] Android uses folders to arrange images, strings, and other values for screen density. The `res` folder also contains XML layout files that can be thought of as `xib` files. Lastly, there are other XML files that store resources for string, integer, and style resources.

第二个主要部分部分是`res`文件夹，也就是资源文件夹。`res`文件夹包含有图像、 XML 布局文件，以及 XML 值文件，它们构成了大部分非代码资源。在 iOS 上，图像可有`@2x`版本，但在 Android 上有好几种不同的屏幕密度文件夹要考虑。 Android 使用文件夹来组织文件、字符串以及其他与屏幕密度相关的值。`res`文件夹还包含有XML布局文件，就像`xib`文件一样。最后，还有其他XML文件存储了字符串、整数和样式资源。

One last correlation in project structure is the `AndroidManifest.xml` file. This file is the equivalent of the `Project-Info.plist` file on iOS, and it stores information for activities, application names, and set Intents[^3] (system-level events) that the application can handle.
 For more information about Intents, keep on reading, or head over to the [Intents](/issue-11/android-intents.html) article.
 
最后一个与项目结构相关的是`AndroidManifest.xml`文件。这个文件等同于iOS上的`Project-Info.plist`文件，它存储着 Activity 信息、应用名字，并设置应用能处理的 Intent（系统级事件）。关于 Intent 的更多信息，继续阅读本文，或者阅读[Intents](/issue-11/android-intents.html)这篇文章。

## Activities Activity（活动）

Activities are the basic visual unit of an Android app, just as `UIViewControllers` are the basic visual component on iOS. Instead of a `UINavigationController`, the Android OS keeps an activity stack that it manages. When an app is launched, the OS pushes the app's main activity onto the stack. Note that you can launch other apps' activities and have them placed onto the stack. By default, the back button on Android pops from the OS activity stack, so when a user presses back, he or she can go through multiple apps that have been launched.

Activity 是 Android 应用的基本虚拟单元，就像`UIViewController`是iOS的基本虚拟组组件一样。作为`UINavigationController`的替代，Android OS 将维护一个 Activity 栈。当应用完成加载，系统将应用的主 Activity（main activity）压（push）到栈上。注意你也可以加载其他应用的 Activity 并将它们放在栈里。默认，Android 上的返回（back）按钮将从 OS 的 Activity 栈中弹出（pop），所以当一个用户不停地按下返回，他或她可以见到多个曾经加载过的应用。

Activities can also initialize other activities with [Intents](http://developer.android.com/reference/android/content/Intent.html) that contain extra data.  Starting Activities with Intents is somewhat similar to creating a new `UIViewController` with a custom `init` method. Because the most common way to launch new activities is to create an Intent with data, a great way to expose custom initializers on Android is to create static Intent getter methods. Activities can also return results when finished (goodbye modal delegates!) by placing extra data on an Intent when the activity is finished.

在 Intent 包含有额外的数据时，Activity 同样可以初始化其他 Activity 。通过 Intent 启动 Activity 类似于通过自定义的`init`方法创建一个`UIViewController`。因为最常见的加载新 Activity 的方法是创建一个有数据的 Intent，在 Android 上暴露自定义初始化的一个非常棒的方式是创建一个静态 Intent getter 方法。Activity 同样能在完成时返回结果（再见，模态代理），在其完成时在 Intent 上放置额外数据即可。

One large difference between Android apps and iOS apps is that any activity can be an entrance point into your application if it registers correctly in the `AndroidManifest` file. Setting an Intent filter in the AndroidManifest.xml file for a `media intent` on an activity effectively states to the OS that this activity is able to be launched as an entry point with media data inside of the Intent. A good example might be a photo-editing activity that opens a photo, modifies it, and returns the modified image when the activity finishes.

Android 和 iOS的一大差别是任何 Activity 都可以作为你应用的入口，只要它们在`AndroidManifest`文件里正确注册即可。为一个 Activity 有效状态上的`media intent`在 AndroidManifest.xml 文件中设置一个 Intent 过滤器，此 Activity 就能在 Intent 中有媒体数据时作为一个入口。一个不错的例子可能是相片编辑 Activity ，它打开一个相片，修改，并在 Activity 完成时返回修改后的图片。

As a side note, model objects must implement the `Parcelable` interface if you want to send them between activities and fragments. Implementing the `Parcelable` interface is similar to conforming to the `<NSCopying>` protocol on iOS. Also note that `Parcelable` objects are able to be stored in an activity's or fragment's savedInstanceState, in order to more easily restore their states after they have been destroyed.

作为一个旁注，模型对象必须实现`Parcelable`接口，如果你想在 Activity 和 Fragment 之间发送它们。实现`Parcelable`接口很类似于 iOS 上实现`<NSCopying>`协议。同样要注意，当一个 Activity 或 Fragment 达到savedInstanceState 状态时`Parcelable`对象就能被存储，这是为了能更容易地在它们被销毁后存储它们的状态。

Let's next look at one activity launching another activity, and also responding to when the second activity finishes.

接下来就看看一个 Activity 启动另一个 Activity，同时能在第二个 Activity 完成时做出响应。

### Launching Another Activity for a Result 加载另一个Activity并得到结果

    // A request code is a unique value for returning activities
    private static final int REQUEST_CODE_NEXT_ACTIVITY = 1234;
    
    protected void startNextActivity() {
        // Intents need a context, so give this current activity as the context
        Intent nextActivityIntent = new Intent(this, NextActivity.class);
           startActivityForResult(nextActivityResult, REQUEST_CODE_NEXT_ACTIVITY);
    }
    
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        switch (requestCode) {
        case REQUEST_CODE_NEXT_ACTIVITY:
            if (resultCode == RESULT_OK) {
                // This means our Activity returned successfully. For now, Toast this text.  
                // This just creates a simple pop-up message on the screen.
                    Toast.makeText(this, "Result OK!", Toast.LENGTH_SHORT).show();
                }
                return;
            }    
            super.onActivityResult(requestCode, resultCode, data);
    }

### Returning a Result on Activity Finish() 在 Activity Finish() 上返回结果

    public static final String activityResultString = "activityResultString";
    
    /*
     * On completion, place the object ID in the intent and finish with OK.
     * @param returnObject that was processed
     */
    private void onActivityResult(Object returnObject) {
            Intent data = new Intent();
            if (returnObject != null) {
                data.putExtra(activityResultString, returnObject.uniqueId);
            }
        
            setResult(RESULT_OK, data);
            finish();        
    }

## Fragments Fragment（片段）

The [Fragment](http://developer.android.com/guide/components/fragments.html) concept is unique to Android and came around somewhat recently in Android 3.0. Fragments are mini controllers that can be instantiated to fill activities. They store state information and may contain view logic, but there may be multiple fragments on the screen at the same time -- putting the activity in a fragment controller role. Also note that fragments do not have their own contexts and they rely heavily on activities for their connection to the application's state.

[Fragment](http://developer.android.com/guide/components/fragments.html)的概念是 Android 独有的，它最近才随着在 Android 3.0 出现。Fragment 是一种迷你控制器，能够被实例化来填充 Activity。它们存储有状态信息还可能包含有视图逻辑，但同一时间里屏幕上可能有多个 Fragment ——将 Activity 放入 Fragment 控制器角色里。同时注意 Fragment 自身没有上下文，它们严重依赖 Activity 来将它们和应用的状态联系起来。

Tablets are a great fragment use case example: you can place a list fragment on the left and a detail fragment on the right.[^4] Fragments allow you to break up your UI and controller logic into smaller, reusable chunks. But beware! The fragment lifecycle, detailed below, is more nuanced.

平板是使用 Fragment 的绝好例子：你可以在左边放一个列表 Fragment，右边放一个详细信息 Fragment。Fragment 能让你将 UI 和控制器逻辑打破在更小、可重用的层面上。但要当心，Fragment 的生命周期，如下所示，有不少细微差别：

<img alt="A multi-pane activity with two fragments" src="{{ site.images_path }}/issue-11/multipane_view_tablet.png">
 
Fragments are the new way of structuring apps on Android, just like `UICollectionView` is the new way of structuring list data instead of `UITableview` for iOS.[^5]  While it is initially easier to avoid using fragments and instead use nothing but activities, you could regret this decision later on. That said, resist the urge to give up on activities entirely by swapping fragments on a single activity -- this can leave you in a bind when wanting to take advantage of intents and using multiple fragments on the same activity.

Fragment是App的新方式，就像在iOS上`UICollectionView`是可取代`UITableView`的构造列表数据的新方式。虽然在一开始避开 Fragment 而使用 Activity 会比较容易，但你之后可能会后悔。这就是说，抗拒冲动——完全放弃 Activity 转而在单个 Activity 上使用 Fragment ——将使你陷入困境，即当你想获得 Intent 的好处且想在同一个 Activity 上使用多个 Fragment 时。

Let's look at a sample `UITableViewController` and a sample `ListFragment` that show a list of prediction times for a subway trip, courtesy of the [MBTA](http://www.mbta.com/rider_tools/developers/default.asp?id=21898).

现在来看一个例子，`UITableViewController`和`ListFragment`如何显示一个地铁行程预测时刻表，courtesy of the [MBTA](http://www.mbta.com/rider_tools/developers/default.asp?id=21898)。

### Table View Controller Implementation Table View Controller 实现

&nbsp;

<img alt="TripDetailsTableViewController" src="{{ site.images_path }}/issue-11/IMG_0095.PNG" width="50%">

&nbsp;

    @interface MBTASubwayTripTableTableViewController ()
    
    @property (assign, nonatomic) MBTATrip *trip;
    
    @end
    
    @implementation MBTASubwayTripTableTableViewController
    
    - (instancetype)initWithTrip:(MBTATrip *)trip
    {
        self = [super initWithStyle:UITableViewStylePlain];
        if (self) {
            _trip = trip;
            [self setTitle:trip.destination];
        }
        return self;
    }
    
    - (void)viewDidLoad
    {
        [super viewDidLoad];
        
        [self.tableView registerClass:[MBTAPredictionCell class] forCellReuseIdentifier:[MBTAPredictionCell reuseId]];
        [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([MBTATripHeaderView class]) bundle:nil] forHeaderFooterViewReuseIdentifier:[MBTATripHeaderView reuseId]];
    }
    
    #pragma mark - UITableViewDataSource
    
    - (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
    {
        return 1;
    }
    
    - (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
    {
        return [self.trip.predictions count];
    }
    
    #pragma mark - UITableViewDelegate
    
    - (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
    {
        return [MBTATripHeaderView heightWithTrip:self.trip];
    }
    
    - (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
    {
        MBTATripHeaderView *headerView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:[MBTATripHeaderView reuseId]];
        [headerView setFromTrip:self.trip];
        return headerView;
    }
    
    - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[MBTAPredictionCell reuseId] forIndexPath:indexPath];
        
        MBTAPrediction *prediction = [self.trip.predictions objectAtIndex:indexPath.row];
        [(MBTAPredictionCell *)cell setFromPrediction:prediction];
        
        return cell;
    }
    
    - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
    {
        return NO;
    }
    
    - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    @end


### List Fragment Implementation List Fragment 实现

&nbsp;

<img alt="TripDetailFragment" src="{{ site.images_path }}/issue-11/Screenshot_2014-03-25-11-42-16.png" width="50%">

&nbsp;

    public class TripDetailFragment extends ListFragment {
    
        /**
         * The configuration flags for the Trip Detail Fragment.
         */
        public static final class TripDetailFragmentState {
            public static final String KEY_FRAGMENT_TRIP_DETAIL = "KEY_FRAGMENT_TRIP_DETAIL";
        }
    
        protected Trip mTrip;
    
        /**
         * Use this factory method to create a new instance of
         * this fragment using the provided parameters.
         *
         * @param trip the trip to show details
         * @return A new instance of fragment TripDetailFragment.
         */
        public static TripDetailFragment newInstance(Trip trip) {
            TripDetailFragment fragment = new TripDetailFragment();
            Bundle args = new Bundle();
            args.putParcelable(TripDetailFragmentState.KEY_FRAGMENT_TRIP_DETAIL, trip);
            fragment.setArguments(args);
            return fragment;
        }
    
        public TripDetailFragment() { }
    
        @Override
        public View onCreateView(LayoutInflater inflater, ViewGroup container,
                                 Bundle savedInstanceState) {
            Prediction[] predictions= mTrip.predictions.toArray(new Prediction[mTrip.predictions.size()]);
            PredictionArrayAdapter predictionArrayAdapter = new PredictionArrayAdapter(getActivity(), predictions);
            setListAdapter(predictionArrayAdapter);
            return super.onCreateView(inflater,container, savedInstanceState);
        }
    
        @Override
        public void onViewCreated(View view, Bundle savedInstanceState) {
            super.onViewCreated(view, savedInstanceState);
            TripDetailsView headerView = new TripDetailsView(getActivity());
            headerView.updateFromTripObject(mTrip);
            getListView().addHeaderView(headerView);
        }
    }

In the next section, let's decipher some of the unique Android components.

下一节，我们将研究一些 Android 独有的组件。

## Common Android Components 通用Android组件

### List Views and Adapters 列表视图与适配器

`ListViews` are the closest approximation to `UITableView` on Android, and they are one of the most common components that you will use. Just like `UITableView` has a helper view controller, `UITableViewController`, ListView also has a helper activity, `ListActivity`, and a helper fragment, `ListFragment`. Similar to `UITableViewController`, these helpers take care of the layout (similar to the xib) for you and provide convenience methods for managing adapters, which we'll discuss below. Our example above uses a `ListFragment` to display data from a list of `Prediction` model objects, similar to how the table view's datasource uses an array of `Prediction` model objects to populate the `ListView`.

`ListView`是 Android 上`UITableView`的近似物，也是最常使用的一种组件。就像`UITableView`有一个助手视图控制器`UITableViewController`，`ListView`也有一个助手 Activity 叫做`ListActivity`，还有一个助手 Fragment 叫做`ListFragment`。同`UITableViewController`类似，这些助手为你处理布局（类似xib）并提供管理适配器（下面将讨论）的简便方法。上面的例子使用一个`ListFragment`来显示来自一个`Prediction`模型对象列表的数据，类似于 UITableView 的 datasource 使用一个`Prediction`模型对象数组来填充`ListView`。

Speaking of datasources, on Android we don't have datasources and delegates for `ListView`. Instead, we have adapters. Adapters come in many forms, but their primary goal is similar to a datasource and table view delegate all in one. Adapters take data and adapt it to populate a `ListView` by instantiating views the `ListView` will display. Let's have a look at the array adapter used above:

说到 datasource，在 Android 上，我们没有用于`ListView`的 datasource 和 delegate。作为代替，我们有适配器。适配器有多种形式，但它们的主要目标类似于 datasource 和 delegate 合二为一。适配器拿到数据并通过实例化视图适配它去填充`ListView`，这样`ListView`就会显示出来了。让我们来看看上面使用的数组适配器：
     
    public class PredictionArrayAdapter extends ArrayAdapter<Prediction> {
    
        int LAYOUT_RESOURCE_ID = R.layout.view_three_item_list_view;
    
        public PredictionArrayAdapter(Context context) {
            super(context, R.layout.view_three_item_list_view);
        }
    
        public PredictionArrayAdapter(Context context, Prediction[] objects) {
            super(context, R.layout.view_three_item_list_view, objects);
        }
    
        @Override
        public View getView(int position, View convertView, ViewGroup parent)
        {
            Prediction prediction = this.getItem(position);
            View inflatedView = convertView;
            if(convertView==null)
            {
                LayoutInflater inflater = (LayoutInflater)getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
                inflatedView = inflater.inflate(LAYOUT_RESOURCE_ID, parent, false);
            }
    
            TextView stopNameTextView = (TextView)inflatedView.findViewById(R.id.view_three_item_list_view_left_text_view);
            TextView middleTextView = (TextView)inflatedView.findViewById(R.id.view_three_item_list_view_middle_text_view);
            TextView stopSecondsTextView = (TextView)inflatedView.findViewById(R.id.view_three_item_list_view_right_text_view);
    
            stopNameTextView.setText(prediction.stopName);
            middleTextView.setText("");
            stopSecondsTextView.setText(prediction.stopSeconds.toString());
    
            return inflatedView;
        }
    }

You'll note that the adapter has an important method named `getView`, which is very similar to `cellForRowAtIndexPath:`. Another similarity you'll notice is a pattern for reusing views, similar to iOS 6. Reusing views are just as important as on iOS, and this substantially helps performance! This adapter is rather simple, because it uses a built-in superclass, `ArrayAdapter<T>`, for adapters working with array data, but it illustrates how to populate a `ListView` from a dataset.

你会注意到此适配器有一个叫做`getView`的重要方法，它非常类似于`cellForRowAtIndexPath:`。另一个易被发现的相似点是一个重用视图的模式，类似于 iOS 6。视图重用同在 iOS 上的情况一样重要，因为它能非常显著地提高性能！这个适配器有点儿简单，因为它使用了内建的超类`ArrayAdapter<T>`，用于数组数据，但它依然说明了如何用一个数据集来填充一个`ListView`。
     
### AsyncTasks 异步任务

In place of Grand Central Dispatch on iOS, on Android we have access to `AsyncTasks`. `AsyncTasks` is a different take on exposing asynchronous tools in a more friendly way. `AsyncTasks` is a bit out of scope for this article, but I highly recommend looking over some of the [documentation](http://developer.android.com/reference/android/os/AsyncTask.html).

作为 iOS 上 GCD（Grand Central Dispatch）的替代，Android 上可以使用`AsyncTasks`。`AsyncTasks`是一个以更加友好的方式处理异步的工具。`AsyncTasks`有点超出本文的范围，但我强烈建议你阅读相关[文档](http://developer.android.com/reference/android/os/AsyncTask.html)。
 
## Activity Lifecycle Activity生命周期

One of the primary things to watch out for coming from iOS development is the Android lifecycle. Let's start by looking at the [Activity Lifecycle Documentation](http://developer.android.com/training/basics/activity-lifecycle/index.html):

从 iOS 开发而来，我们需要注意的首要事情之一是 Android 生命周期。让我们从查看 [Activity 生命周期文档](http://developer.android.com/training/basics/activity-lifecycle/index.html) 开始：

![Android Activity Lifecycle]({{ site.images_path }}/issue-11/Android-Activity-Lifecycle.png)

In essence, the activity lifecycle is very similar to the UIViewController lifecycle. The primary difference is that the Android OS can be ruthless with destroying activities, and it is very important to make sure that the data and the state of the activity are saved, so that they can be restored from the saved state if they exist in the `onCreate()`. The best way to do this is by using bundled data and restoring from the savedInstanceState and/or Intents. For example, here is the part of the `TripListActivity` from our sample project that is keeping track of the currently shown subway line:

从本质上看来，Activity 生命周期近似于 UIViewController 生命周期。主要的不同是 Android OS 在销毁 Activity 上比较无情，而且保证数据和 Activity 的状态被保存是非常重要的，因此它们才能从被保存的状态（如果在`onCreate()`里存在）里恢复。做到这个的最好方式是使用绑定数据（bundled data）并从 savedInstanceState 和/或 Intents 恢复。例如，下面是来自我们示例项目中`TripListActivity`的部分代码，它能一直跟踪当前显示的地铁线路：

 
    public static Intent getTripListActivityIntent(Context context, TripList.LineType lineType) {
        Intent intent = new Intent(context, TripListActivity.class);
        intent.putExtra(TripListActivityState.KEY_ACTIVITY_TRIP_LIST_LINE_TYPE, lineType.getLineName());
        return intent;
    }
    
    public static final class TripListActivityState {
        public static final String KEY_ACTIVITY_TRIP_LIST_LINE_TYPE = "KEY_ACTIVITY_TRIP_LIST_LINE_TYPE";
    }
        
    TripList.LineType mLineType;    
        
    @Override
    protected void onCreate(Bundle savedInstanceState) {
       super.onCreate(savedInstanceState);
       mLineType = TripList.LineType.getLineType(getIntent().getStringExtra(TripListActivityState.KEY_ACTIVITY_TRIP_LIST_LINE_TYPE));
    }    

A note on rotation: the lifecycle **completely** resets the view on rotation. That is, your activity will be destroyed and recreated when a rotation occurs. If data is properly saved in the saved instance state and the activity restores the state correctly after its creation, then the rotation will work seamlessly. Many app developers have issues with app stability when the app rotates, because an activity does not handle state changes properly. Beware! Do not lock your app's rotation to solve these issues, as this only hides the lifecycle bugs that will still occur at another point in time when the activity is destroyed by the OS.

注意旋转：在旋转时，生命周期会被**完全**重设。就是说，在旋转发生时，你的 Activity 将被摧毁并重建。如果数据被正确保存在保存实例状态（saved instance state）而且 Activity 能在重新创建后正确恢复，那么旋转看起来就会无缝平滑。许多应用开发者开发的应用因为一个 Activity 不能正确处理状态的改变，在旋转时就会有稳定性问题。小心！不要通过锁定屏幕旋转来避免这种问题，这样做只会掩盖生命周期 bug，它们依然会在将来的某个时间点冒出来，例如当 Activity 被 OS 摧毁时。

## Fragment Lifecycle Fragment生命周期

The [Fragment Lifecycle](http://developer.android.com/training/basics/fragments/index.html) is similar to the activity lifecycle, with a few additions. 

[Fragment 生命周期](http://developer.android.com/training/basics/fragments/index.html)相似于 Activity 生命周期，但有些附加的东西：

![Android Fragment Lifecycle]({{ site.images_path }}/issue-11/fragment_lifecycle.png)

One of the problems that can catch developers off guard is regarding issues communicating between fragments and activities. Note that the `onAttach()` happens **before** `onActivityCreated()`. This means that the activity is not guaranteed to exist before the fragment is created. The `onActivityCreated()` method should be used when you set interfaces (delegates) to the parent activity, if needed.

能让开发者措手不及的问题之一是 Fragment 和 Activity 之间的通信问题。注意`onAttach()`**先于**`onActivityCreated()`调用。这就意味着 Activity 不能保证在 Fragment 被创建前存在。`onActivityCreated()`方法应该被用于当你设置到父亲 Activity 的 interface（delegate）时，如果有必要。

Fragments are also created and destroyed aggressively by the needs of the operating system, and to keep their state, require the same amount of diligence as activities. Here is an example from our sample project, where the trip list fragment keeps track of the `TripList` data, as well as the subway line type:

Fragment 同样被操作系统积极地创建和销毁，为了保存它们地状态，需要同 Activity 一样多的劳动量。下面时来自示例项目的一个例子，此处的旅程列表 Fragment 一直追踪`TripList`数据，以及地铁线路类型：
 
    /**
     * The configuration flags for the Trip List Fragment.
     */
    public static final class TripListFragmentState {
        public static final String KEY_FRAGMENT_TRIP_LIST_LINE_TYPE = "KEY_FRAGMENT_TRIP_LIST_LINE_TYPE";
        public static final String KEY_FRAGMENT_TRIP_LIST_DATA = "KEY_FRAGMENT_TRIP_LIST_DATA";
    }
    
    /**
     * Use this factory method to create a new instance of
     * this fragment using the provided parameters.
     *
     * @param lineType the subway line to show trips for.
     * @return A new instance of fragment TripListFragment.
     */
    public static TripListFragment newInstance(TripList.LineType lineType) {
        TripListFragment fragment = new TripListFragment();
        Bundle args = new Bundle();
        args.putString(TripListFragmentState.KEY_FRAGMENT_TRIP_LIST_LINE_TYPE, lineType.getLineName());
        fragment.setArguments(args);
        return fragment;
    }
    
    protected TripList mTripList;
    protected void setTripList(TripList tripList) {
        Bundle arguments = this.getArguments();
        arguments.putParcelable(TripListFragmentState.KEY_FRAGMENT_TRIP_LIST_DATA, tripList);
        mTripList = tripList;
        if (mTripArrayAdapter != null) {
            mTripArrayAdapter.clear();
            mTripArrayAdapter.addAll(mTripList.trips);
        }
    }
    
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getArguments() != null) {
            mLineType = TripList.LineType.getLineType(getArguments().getString(TripListFragmentState.KEY_FRAGMENT_TRIP_LIST_LINE_TYPE));
            mTripList = getArguments().getParcelable(TripListFragmentState.KEY_FRAGMENT_TRIP_LIST_DATA);
        }
    }    

Notice that the fragment always restores its state from the bundled arguments in `onCreate`, and that the custom setter for the `TripList` model object adds the object to the bundled arguments as well. This ensures that if the fragment is destroyed and recreated, such as when the device is rotated, the fragment always has the latest data to restore from.

注意到Fragment总是用`onCreate`里的绑定参数（bundled arguments）来恢复它的状态，用于`TripList`模型对象的自定义的 setter 同样添加对象到绑定参数。这就保证了如果 Fragment 被销毁并重建，例如设备被旋转时，Fragment 总是有最新的数据并从中恢复。

## Layouts 布局

Similar to other parts of Android development, there are pros and cons to specifying layouts in Android versus iOS. [Layouts](http://developer.android.com/guide/topics/ui/declaring-layout.html) are stored as human-readable XML files in the `res/layouts` folder.  

类似于 Android 开发的其他部分，Android 对比 iOS，在指定布局这里同样有优点和缺点。[布局](http://developer.android.com/guide/topics/ui/declaring-layout.html)被存储为人类可读的 XML 文件，放在`res/layouts`文件夹中。

### Subway List View Layout 地铁列表视图布局

<img alt="Subway ListView" src="{{ site.images_path }}/issue-11/Screenshot_2014-03-24-13-12-00.png" width="50%">

    <RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
        xmlns:tools="http://schemas.android.com/tools"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        tools:context="com.example.androidforios.app.activities.MainActivity$PlaceholderFragment">
    
        <ListView
            android:id="@+id/fragment_subway_list_listview"
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            android:paddingBottom="@dimen/Button.Default.Height"/>
    
        <Button
            android:id="@+id/fragment_subway_list_Button"
            android:layout_width="match_parent"
            android:layout_height="@dimen/Button.Default.Height"
            android:minHeight="@dimen/Button.Default.Height"
            android:background="@drawable/button_red_selector"
            android:text="@string/hello_world"
            android:textColor="@color/Button.Text"
            android:layout_alignParentBottom="true"
            android:gravity="center"/>
    
    </RelativeLayout>

Here is the same view on iOS with a `UITableView` and a `UIButton` pinned to the bottom via Auto Layout in Interface Builder:

下面是 iOS 上在 Interface Builder 中用`UITableView`和一个通过 Auto Layout 钉在底部的`UIButton`实现的同一个视图：

<img alt="iOS Subway Lines UIViewController" src="{{ site.images_path }}/issue-11/iOS_Screen1.png" width="50%">

![Interface Builder Constraints]({{ site.images_path }}/issue-11/iOSConstraints.png)

You'll notice that the Android layout file is much easier to **read** and understand what is going on. There are many parts to laying out views in Android, but we'll cover just a few of the important ones.

你会注意到 Android 布局文件更易**阅读**和理解发生的情况。Android 中有许多不同的部分用来布局视图，但我们只会覆盖到少数几个重要的。

The primary structure that you will deal with will be subclasses of [ViewGroup](http://developer.android.com/reference/android/view/ViewGroup.html) -- [RelativeLayout](http://developer.android.com/reference/android/widget/RelativeLayout.html), [LinearLayout](http://developer.android.com/reference/android/widget/LinearLayout.html), and [FrameLayout](http://developer.android.com/reference/android/widget/FrameLayout.html) are the most common. These ViewGroups contain other views and expose properties to arrange them on screen.

你需要处理的主要结构就是子类化 [ViewGroup](http://developer.android.com/reference/android/view/ViewGroup.html)——[RelativeLayout](http://developer.android.com/reference/android/widget/RelativeLayout.html)、[LinearLayout](http://developer.android.com/reference/android/widget/LinearLayout.html)，以及 [FrameLayout](http://developer.android.com/reference/android/widget/FrameLayout.html)，这些就是最常见的。这些 ViewGroup 包含其他视图并暴露属性来安排它们显示在屏幕上。

A good example is the use of a `RelativeLayout` above. A relative layout allows us to use `android:layout_alignParentBottom="true"` in our layout above to pin the button to the bottom.

一个不错的例子是使用`RelativeLayout`，一个相对布局允许我们使用`android:layout_alignParentBottom="true"`在我们的布局上面以将按钮钉在底部。

Lastly, to link layouts to fragments or activities, simply use that layout's resource ID during the `onCreateView`:

最后，要连接布局到 Fragment 或 Activity，简单地在`onCreateView`上使用布局的资源ID即可：
 
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_subway_listview, container, false);
    }


### Layout Tips 布局小贴士

- Always work in dp ([density-independent pixels](http://developer.android.com/training/multiscreen/screendensities.html)) instead of pixels directly.
- 总是在dp（密度无关像素）下工作，而不是直接计算像素。
- Don't bother nudging items for layouts in the visual editor -- often the visual editor will put individual points of spacing on objects instead of adjusting the height and width as you might like. Your best bet is to adjust the XML directly.
- 不要在意虚拟编辑器里的 nudging items ——通常虚拟编辑器将在对象间放置分隔点而不是像你期望的那样调整高度和宽度。你最好的办法是直接调整 XML 文件。
- If you ever see the `fill_parent` value for a layout height or width, this value was depreciated years ago in API 8 and replaced with `match_parent`.
- 如果你曾看到`fill_parent`值用于布局的高或宽，这个值在好几年前的 API 8 中就被废弃并被`match_parent`取代了。

See the the [responsive android applications](/issue-11/responsive-android-applications.html) article for more tips on this.

查看看这篇[响应式 Android 应用](/issue-11/responsive-android-applications.html)的文章能得到更多布局小贴士。
 

## Data 数据

The [Data Storage Options](http://developer.android.com/guide/topics/data/data-storage.html) available on Android are also very similar to what is available on iOS:

Android 上可用的[数据存储选项](http://developer.android.com/guide/topics/data/data-storage.html)同样类似于 iOS 上可用的：

- [Shared Preferences](http://developer.android.com/guide/topics/data/data-storage.html#pref) <-> NSUserDefaults
- [共享首选项](http://developer.android.com/guide/topics/data/data-storage.html#pref)<-> NSUserDefaults
- In-memory objects
- 内存对象
- Saving to and fetching from file structure via the [internal](http://developer.android.com/guide/topics/data/data-storage.html#filesInternal) or [external](http://developer.android.com/guide/topics/data/data-storage.html#filesExternal) file storage <-> saving to the documents directory
- 通过[内部](http://developer.android.com/guide/topics/data/data-storage.html#filesInternal)或[外部](http://developer.android.com/guide/topics/data/data-storage.html#filesExternal)文件存储保存数据到文件结构和从文件结构获取数据 <-> 保存数据到 documents 目录

- [SQLite](http://developer.android.com/guide/topics/data/data-storage.html#db) <-> Core Data （这句不译！）
 
The primary difference is the lack of Core Data. Instead, Android offers straight access to the SQLite database and returns [cursor](http://developer.android.com/reference/android/database/Cursor.html) objects for results. Head over to the article in this issue about [using SQLite on Android](/issue-11/sqlite-database-support-in-android.html) for more details.

主要的不同是缺少 Core Data，相反，Android 提供了直接访问 SQLite 数据库并返回[游标](http://developer.android.com/reference/android/database/Cursor.html)对象作为结果。请看这篇[在 Android 上使用 SQLite ](/issue-11/sqlite-database-support-in-android.html)的文章获取更多此问题的细节。


## Android Homework Android家庭作业

What we've discussed so far barely scratches the surface. To really take advantage of some of the things that make Android special, I recommend checking out some of these features:

我们目前为止讨论的只是一些皮毛而已。要真正从一些 Android 特有的事物里获取好处，我建议关注以下这些特性：

- [Action Bar, Overflow Menu, and the Menu Button](http://developer.android.com/guide/topics/ui/actionbar.html) （不译！）
- [Cross-App Data Sharing](https://developer.android.com/training/sharing/index.html) 
- [跨应用数据分享](https://developer.android.com/training/sharing/index.html) 
- [Respond to common OS actions](http://developer.android.com/guide/components/intents-common.html)
- [响应常见的 OS 操作](http://developer.android.com/guide/components/intents-common.html)
- Take advantage of Java's features: generics, virtual methods and classes, etc.
- 从 Java 的特性获取好处：泛型、虚方法、虚类，等等。
- [Google Compatibility Libraries](http://developer.android.com/tools/support-library/index.html)
- [Google 兼容库](http://developer.android.com/tools/support-library/index.html)
- The Android Emulator: install the [x86 HAXM plugin](http://software.intel.com/en-us/android/articles/intel-hardware-accelerated-execution-manager) to make the emulator buttery smooth.
- Android 模拟器：安装 [x86 HAXM 插件](http://software.intel.com/en-us/android/articles/intel-hardware-accelerated-execution-manager)让模拟器像黄油般顺滑。

 
## Final Words 最后的话

Much of what was discussed in this article is implemented in the MBTA subway transit [sample project](https://github.com/objcio/issue-11-android-101) on GitHub. The project was built as a way to illustrate similar concepts such as application structure, handling data, and building UI on the same application for both platforms.

本文中我们讨论的大部分都实现在 MBTA 地铁交通[示例项目](https://github.com/objcio/issue-11-android-101)中，放在Github上。创建这个项目是为提供一个在两个平台上展示如应用结构、绑定数据、构建 UI 等相似内容的方式。

While some of the pure **implementation** details are very different on Android, it is very easy to bring problem-solving skills and patterns learned on iOS to bear. Who knows? Maybe understanding how Android works just a little bit better might prepare you for the next version of iOS.

虽然在 Android 上一些纯粹的**实现**细节非常不同，但将从 iOS 学来的问题解决技能和模式用于实践依然非常容易。谁知道呢？也许懂得为何 Android 工作得更好一点可能让你准备好面对下一版的 iOS。

[^1]: [Source](http://www.prnewswire.com/news-releases/strategy-analytics-android-captures-79-percent-share-of-global-smartphone-shipments-in-2013-242563381.html)

[^1]: [源代码](http://www.prnewswire.com/news-releases/strategy-analytics-android-captures-79-percent-share-of-global-smartphone-shipments-in-2013-242563381.html)

[^2]: See Google's documentation for supporting multiple screen sizes [here](http://developer.android.com/guide/practices/screens_support.html).

[^2]: [在此](http://developer.android.com/guide/practices/screens_support.html)查看Google的文档支持多种屏幕尺寸。
    
[^3]: [Intents documentation](http://developer.android.com/reference/android/content/Intent.html)

[^3]: [Intent 文档](http://developer.android.com/reference/android/content/Intent.html)

[^4]: See Google's documentation for [multi-pane tablet view](http://developer.android.com/design/patterns/multi-pane-layouts.html) for more information.

[^4]: 查看Google的文档获得更多[多窗格平板视图](http://developer.android.com/design/patterns/multi-pane-layouts.html)的信息。
    
[^5]: Thanks, [NSHipster](http://nshipster.com/uicollectionview/).

[^5]: 感谢，[NSHipster](http://nshipster.com/uicollectionview/).