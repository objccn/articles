随着移动软件工业的发展，一个移动产品只局限于 iOS 系统变得越来越不切实际。 Android 目前占有近 80% 的智能手机份额[^1]，它能给一个产品带来的潜在用户量实在不能再被忽略了。

在本文中，我会在 iOS 的开发范围内介绍 Android 开发的核心内容。 Android 和 iOS 处理类似的问题集，但在大部分问题上，它们都有不同的解决方式。通过本文，我会使用一个配套项目（在 [GitHub](https://github.com/objcio/issue-11-android-101) 上）来说明如何在两个平台上开发以完成相同的任务。

除了 iOS 开发的相关知识，我假设你在 Java 上也有一定经验，能够安装和使用[ADT（Android Development Tools）](http://developer.android.com/tools/index.html)。此外，如果你最近才开始 Android 开发，读一遍 Google 编写的关于[创建你的第一个应用](http://developer.android.com/training/basics/firstapp/index.html)的教程会很有帮助。

### UI设计概要

本文不会深入到介绍 iOS 和 Android 在用户体验和设计模式上的不同。然而，了解一些当今 Android 上使用的关键 UI 范式，比如 Action Bar、Overflow Menu、Back Button、Share Action 等，还是会很有好处的。如果你正在认真考虑 Android 开发，我推荐你从 Google Play Store 买个 [Nexus 5](https://play.google.com/store/devices/details?id=nexus_5_white_16gb)，将它作为你的主要设备，用满一周，强迫自己最大程度的去体验这个操作系统。一个开发者若不清楚要为之开发的操作系的关键使用模式，就那是对产品的不负责任。

## 语言应用结构

### Java

Objective-C 和 Java 之间有很多不同，虽然若能将 Objective-C 的方式带入 Java 可能会很有诱惑力，但这样做很可能导致代码库与驱动它的主要框架产生冲突。总之，有一些需要提防地陷阱：

- 类前缀就留在 Objective-C 里不要带过来了。Java 有实在的命名空间和包管理，所以不再需要类前缀。
- 实例变量的前缀是 `m`，不是 `_`。尽可能多的在代码里使用JavaDoc来写方法和类描述，它能让你和其他人更舒服些。
- Null 检查！Objective-C能妥善处理向nil发送消息，但Java不行。
- 向属性说再见。如果你想要 setter 和 getter，你只能实际地创建一个 getVariableName()方法，并显式的调用它。使用 `this.object` **不会**调用你自定义地getter，你必须使用 `this.getObjct`。
- 同样的，给方法名加上 `get` 和 `set` 前缀来更好的识别 getter 和 setter 。Java 方法通常写为动作和查询，例如 `getCell()`，而不是 `cellForRowAtIndexPath:`。

### 项目结构

Android 应用主要分为两个部分，第一部分是 Java 源代码。源代码通过 Java 包的方式进行组织，所以可按照你的喜好来决定。然而一个常见的实践是为 Activity、Fragment、View、Adapter 和 Data（模型和管理器）使用顶层的类别（top-level categories）。

第二个主要部分是 `res` 文件夹，也就是资源文件夹。`res` 文件夹包含有图像、 XML 布局文件，以及 XML 值文件，它们构成了大部分非代码资源。在 iOS 上，图像可有 `@2x` 版本，但在 Android 上有好几种不同的屏幕密度文件夹要考虑[^2]。Android 使用文件夹来组织文件、字符串以及其他与屏幕密度相关的值。`res` 文件夹还包含有 XML 布局文件，就像 `xib` 文件一样。最后，还有其他 XML 文件存储了字符串、整数和样式资源。
 
最后一个与项目结构相关的是 `AndroidManifest.xml` 文件。这个文件等同于 iOS 上的 `Project-Info.plist` 文件，它存储着 Activity 信息、应用名字，并设置应用能处理的 Intent [^3]（系统级事件）。关于 Intent 的更多信息，继续阅读本文，或者阅读 [Intents](http://objccn.io/issue-11-2) 这篇文章。

## Activity

Activity 是 Android 应用的基本显示单元，就像 `UIViewController` 是iOS的基本显示组件一样。作为 `UINavigationController` 的替代，Android 由系统来维护一个 Activity 栈。当应用完成加载，系统将应用的主 Activity（main activity）压到栈上。注意你也可以加载其他应用的 Activity 并将它们放在栈里。默认，Android 上的返回（back）按钮将从系统的 Activity 栈中弹出 Activity，所以当用户不停地按下返回时，他可以见到多个曾经加载过的应用。

通过使用包含有额外的数据 Intent，Activity 同样可以初始化其他 Activity 。通过 Intent 启动 Activity 类似于通过自定义的 `init` 方法创建一个 `UIViewController`。因为最常见的加载新 Activity 的方法是创建一个有数据的 Intent，在 Android 上暴露自定义初始化方法的一个非常棒的方式是创建一个静态 Intent getter 方法。Activity 同样能在完成时返回结果（再见，modal 代理），当其完成时在 Intent 上放置额外数据即可。

Android 和 iOS 的一大差别是任何 Activity 都可以作为你应用的入口，只要它们在 `AndroidManifest`文件里正确注册即可。在 AndroidManifest.xml 文件中，为一个 Activity 设置一个 `media intent` 的 Intent 过滤器的话，就能让系统知道这个 Activity 可以作为包含有媒体数据的 Intent 的入口。一个不错的例子是相片编辑  Activity ，它打开一个相片，修改它，并在 Activity 完成时返回修改后的图片。

作为一个旁注，如果你想在 Activity 和 Fragment 之间发送模型对象的话，它们必须实现 `Parcelable` 接口。实现 `Parcelable` 接口很类似于 iOS 上实现 `<NSCopying>` 协议。同样值得一提的是，`Parcelable` 对象可以存储在 activity 或者 fragment 的 savedInstanceState 里，这是为了能更容易地在它们被销毁后恢复它们的状态。

接下来就看看一个 Activity 启动另一个 Activity，同时能在第二个 Activity 完成时做出响应。

### 加载另一个Activity并得到结果

    // request code 是为返回 activities 所设置的特定值
    private static final int REQUEST_CODE_NEXT_ACTIVITY = 1234;
    
    protected void startNextActivity() {
        // Intents 需要一个 context, 所以将当前的 activity 作为 context 给入
        Intent nextActivityIntent = new Intent(this, NextActivity.class);
           startActivityForResult(nextActivityResult, REQUEST_CODE_NEXT_ACTIVITY);
    }
    
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        switch (requestCode) {
        case REQUEST_CODE_NEXT_ACTIVITY:
            if (resultCode == RESULT_OK) {
                // 这表示我们的 activity 成功返回了。现在显示一段提示文字
                // 这里在屏幕上创建了一个简单的 pop-up 消息框
                    Toast.makeText(this, "Result OK!", Toast.LENGTH_SHORT).show();
                }
                return;
            }    
            super.onActivityResult(requestCode, resultCode, data);
    }

### 在 Activity finish() 上返回结果

    public static final String activityResultString = "activityResultString";
    
    /*
     * 结束时调用, 在 intent 上设置 object ID 并调用成功结束
     * @param returnObject 是要处理的对象
     */
    private void onActivityResult(Object returnObject) {
            Intent data = new Intent();
            if (returnObject != null) {
                data.putExtra(activityResultString, returnObject.uniqueId);
            }
        
            setResult(RESULT_OK, data);
            finish();        
    }

## Fragments

[Fragment](http://developer.android.com/guide/components/fragments.html) 的概念是 Android 独有的，它最近才随着 Android 3.0 的问世而出现。Fragment 是一种迷你控制器，能够被实例化来填充 Activity。它们可以存储状态信息，还有可能包含视图逻辑，但区别 Activity 和 Fragment 的最大不同在于。同一时间里屏幕上可能有多个 Fragment。同时注意 Fragment 自身没有上下文，它们严重依赖 Activity 来将它们和应用的状态联系起来。

平板是使用 Fragment 的绝好场景：你可以在左边放一个列表 Fragment，右边放一个详细信息 Fragment。[^4]Fragment 能让你将 UI 和控制器逻辑分割到更小、可重用的层面上。但要当心，Fragment 的生命周期有不少细微差别，我们会在后面详细谈到。

![一个含有两个 fragment 的多面板 activity](/images/issues/issue-11/multipane_view_tablet.png)

Fragment 是实现 App 的新方式，就像在 iOS 上 `UICollectionView` 是可取代 `UITableView` 的构造列表数据的新方式。[^5] 虽然在一开始避开 Fragment 而使用 Activity 会比较容易，但你之后可能会为之后悔。然而，我们也要抗拒那种想完全放弃 Activity，转而只在单个 Activity 上使用 Fragment 的冲动，因为如果那么做了，那么当你想获得 Intent 的好处且想在同一个 Activity 上使用多个 Fragment 时，你将陷入困境。

现在来看一个例子，`UITableViewController` 和 `ListFragment` 是如何分别显示一个地铁行程预测时刻表，数据由 [MBTA](http://www.mbta.com/rider_tools/developers/default.asp?id=21898) 所提供。


### Table View Controller 实现

&nbsp;

<img alt="TripDetailsTableViewController" src="/images/issues/issue-11/IMG_0095.png" width="50%">

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


### List Fragment 实现

&nbsp;

<img alt="TripDetailFragment" src="/images/issues/issue-11/Screenshot_2014-03-25-11-42-16.png" width="50%">

&nbsp;

    public class TripDetailFragment extends ListFragment {
    
        /**
         * Trip Detail Fragment的配置标识.
         */
        public static final class TripDetailFragmentState {
            public static final String KEY_FRAGMENT_TRIP_DETAIL = "KEY_FRAGMENT_TRIP_DETAIL";
        }
    
        protected Trip mTrip;
    
        /**
         * 根据提供的参数使用这个工厂方法来创建 fragment 的新的实例
         *
         * @param trip trip的详细信息
         * @return fragment TripDetailFragment 的新实例.
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


下一节，我们将研究一些 Android 独有的组件。

## 通用Android组件

### 列表视图与适配器

`ListView` 是 Android 上 `UITableView` 的近似物，也是最常使用的一种组件。就像 `UITableView` 有一个助手 View Controller `UITableViewController` 那样，`ListView` 也有一个助手 Activity 叫做 `ListActivity`，它还有一个助手 Fragment 叫做 `ListFragment`。同`UITableViewController`类似，这些助手为你处理布局（类似 xib）并提供管理适配器（下面将讨论）能够使用的简便方法。上面的例子使用一个 `ListFragment` 来显示来自一个 `Prediction` 模型对象列表的数据，类比一下，其实就相当于 UITableView 的 datasource 提供了一个 `Prediction` 模型对象数组，并用它来填充 `ListView`。

说到 datasource，在 Android 上，我们没有用于 `ListView` 的 datasource 和 delegate。作为代替，我们有适配器 (adapters)。适配器有多种形式，但它们的主要目标类似于将 datasource 和 delegate 合二为一。适配器拿到数据并通过实例化视图适配它去填充 `ListView`，这样 `ListView` 就会显示出来了。让我们来看看上面使用的数组适配器：
     
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


你会注意到此适配器有一个叫做 `getView` 的重要方法，它非常类似于 `cellForRowAtIndexPath:` 。另一个易被发现的相似点是一个重用视图的模式，类似于 iOS 6。视图重用同在 iOS 上的情况一样重要，因为它能非常显著地提高性能！这个适配器有点儿简单，因为它使用了内建的父类 `ArrayAdapter<T>` ，用于数组数据，但它依然说明了如何用一个数据集来填充一个 `ListView`。
     
### AsyncTasks

作为 iOS 上 GCD（Grand Central Dispatch）的替代，Android 上可以使用 `AsyncTasks`。`AsyncTasks` 是一个以更加友好的方式处理异步的工具。`AsyncTasks`有点超出本文的范围，但我强烈建议你阅读相关[文档](http://developer.android.com/reference/android/os/AsyncTask.html)。
 
## Activity 生命周期

从 iOS 开发转过来时候，我们需要注意的首要事情之一是安卓的生命周期。让我们从查看 [Activity 生命周期文档](http://developer.android.com/training/basics/activity-lifecycle/index.html) 开始：

![安卓 Activity 生命周期](/images/issues/issue-11/Android-Activity-Lifecycle.png)

从本质上看来，Activity 生命周期近似于 UIViewController 生命周期。主要的不同是 Android 系统在销毁 Activity 上比较无情，因此保证数据和 Activity 的状态的保存是非常重要的，因此只有这样它们才能在 `onCreate()` 中从被保存的状态里恢复。做到这个的最好方式是使用绑定数据（bundled data）并从 savedInstanceState 和/或 Intents 中恢复。例如，下面是来自我们示例项目中 `TripListActivity` 的部分代码，它能跟踪当前显示的地铁线路：

 
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


注意旋转：在旋转时，生命周期会被**完全**重设。就是说，在旋转发生时，你的 Activity 将被摧毁并重建。如果数据被正确保存在 savedInstanceState 里，而且 Activity 能在重新创建后正确恢复的话，那么旋转看起来就会无缝平滑。许多应用开发者开发的应用因为  Activity 没有正确处理状态的改变，导致在旋转时出现稳定性问题。小心！不要通过锁定屏幕旋转来避免这种问题，这样做只会掩盖生命周期 bug，它们依然会在 Activity 被系统摧毁的时候冒出来。

## Fragment 生命周期

[Fragment 生命周期](http://developer.android.com/training/basics/fragments/index.html)相似于 Activity 生命周期，但有些附加的东西：

![Android Fragment 生命周期](/images/issues/issue-11/fragment_lifecycle.png)

能让开发者措手不及的问题之一是 Fragment 和 Activity 之间的通信问题。注意 `onAttach()` **先于** `onActivityCreated()` 调用。这就意味着 Activity 不能保证在 Fragment 被创建前存在。`onActivityCreated()` 方法应该在有必要的时候用于将 interface（delegate）设置到父亲 Activity 上。

Fragment 同样被操作系统积极地创建和销毁，为了保存它们的状态，需要同 Activity 一样多的劳动量。下面是来自示例项目的一个例子，此处的旅程列表 Fragment 一直追踪`TripList`数据，以及地铁线路类型：
 
    /**
     * Trip List Fragment 的配置标识.
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

注意到 Fragment 总是用 `onCreate` 里的绑定参数（bundled arguments）来恢复它的状态，用于 `TripList` 模型对象的自定义的 setter 会将对象添加到绑定参数中去。这就保证了如果 Fragment 在例如设备被旋转时被销毁并重建的话，Fragment 总是有最新的数据并从中恢复。

## 布局

类似于 Android 开发的其他部分，Android 对比 iOS，在指定布局这里同样有优点和缺点。[布局](http://developer.android.com/guide/topics/ui/declaring-layout.html)被存储为人类可读的 XML 文件，放在 `res/layouts` 文件夹中。

### 地铁列表视图布局

<img alt="Subway ListView" src="/images/issues/issue-11/Screenshot_2014-03-24-13-12-00.png" width="50%">

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


下面是 iOS 上在 Interface Builder 中用`UITableView`和一个通过 Auto Layout 钉在底部的 `UIButton` 实现的同一个视图：

<img alt="iOS Subway Lines UIViewController" src="/images/issues/issue-11/iOS_Screen1.png" width="50%">

![Interface Builder 约束](/images/issues/issue-11/iOSConstraints.png)

你会注意到 Android 布局文件更易**阅读**和理解。Android 中的布局视图有许多不同的部分，但这里我们只会覆盖到少数几个重要的部分。

你需要处理的主要结构就是 [ViewGroup](http://developer.android.com/reference/android/view/ViewGroup.html) 的子类，比如 [RelativeLayout](http://developer.android.com/reference/android/widget/RelativeLayout.html)、[LinearLayout](http://developer.android.com/reference/android/widget/LinearLayout.html)，以及 [FrameLayout](http://developer.android.com/reference/android/widget/FrameLayout.html)，这些就是最常见的。这些 ViewGroup 包含其他视图并暴露属性来在屏幕上安排它们。

一个不错的例子是使用上面提到的 `RelativeLayout`，一个相对布局允许我们在布局中使用 `android:layout_alignParentBottom="true"` 这样的语句来将按钮钉在底部。

最后，要将布局连接到 Fragment 或 Activity，只需要简单地在 `onCreateView` 上使用布局的资源 ID 即可：
 
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_subway_listview, container, false);
    }


### 布局小贴士

- 总是去处理 dp（密度无关的像素）的情况，而不是直接使用像素。
- 不要在可视化编辑器里去调整的部件 - 通常来说可视化编辑器会在部件之间加间隔，而不是像你所期望的那样去调整高宽。最佳选择应该是直接在 XML 文件中进行编辑。
- 如果你曾看到 `fill_parent` 值用于布局的高或宽，这个值在好几年前的 API 8 中就被废弃并被 `match_parent` 取代了。

查看看这篇[响应式 Android 应用](http://objccn.io/issue-11-3)的文章能得到更多布局小贴士。

## 数据

Android 上可用的[数据存储选项](http://developer.android.com/guide/topics/data/data-storage.html)同样类似于 iOS 上可用的：

- [Shared Preferences](http://developer.android.com/guide/topics/data/data-storage.html#pref) <-> NSUserDefaults
- 内存对象
- 通过[内部](http://developer.android.com/guide/topics/data/data-storage.html#filesInternal)或[外部](http://developer.android.com/guide/topics/data/data-storage.html#filesExternal)文件存储将数据保存到文件结构或是从文件结构获取数据 <-> 保存数据到 documents 目录
- [SQLite](http://developer.android.com/guide/topics/data/data-storage.html#db) <-> Core Data

主要的不同是缺少 Core Data，作为替代，Android 提供了直接访问 SQLite 数据库的方式，并返回一个[游标 (cursor)](http://developer.android.com/reference/android/database/Cursor.html) 对象作为结果。请看这篇[在 Android 上使用 SQLite ](htttp://objccn.io/issue-11-5)的文章获取更多此问题的细节。

## Android 家庭作业

我们目前为止讨论的只是一些皮毛而已。要真正从一些 Android 特有的事物里获取好处，我建议关注以下这些特性：

- [Action Bar, Overflow Menu, 和 Menu Button](http://developer.android.com/guide/topics/ui/actionbar.html)
- [跨应用数据分享](https://developer.android.com/training/sharing/index.html) 
- [响应常见的 OS 操作](http://developer.android.com/guide/components/intents-common.html)
- 从 Java 的特性获取好处：泛型、虚方法、虚类，等等。
- [Google 兼容库](http://developer.android.com/tools/support-library/index.html)
- Android 模拟器：安装 [x86 HAXM 插件](http://software.intel.com/en-us/android/articles/intel-hardware-accelerated-execution-manager)让模拟器像黄油般顺滑。

> <p><span class="secondary radius label">编者注</span> 关于模拟器，个人推荐<a href="http://www.genymotion.com">GenyMotion</a>的相关解决方案

## 最后的话

本文中我们讨论的大部分都实现在 MBTA 地铁交通[示例项目](https://github.com/objcio/issue-11-android-101)中，并放在了Github上。创建这个项目的目的是在两个平台上展示应用的结构、绑定数据、构建 UI 等相似内容的方式。

虽然在 Android 上一些纯粹的**实现**细节非常不同，但将从 iOS 学来的问题解决技能和模式用于实践依然非常容易。也许懂得一些 Android 的工作方式可能可以让你准备好面对下一版的 iOS，谁又知道会怎样呢？

[^1]: [ 消息来源](http://www.prnewswire.com/news-releases/strategy-analytics-android-captures-79-percent-share-of-global-smartphone-shipments-in-2013-242563381.html)

[^2]: [ 在此](http://developer.android.com/guide/practices/screens_support.html)查看Google的文档支持多种屏幕尺寸。

[^3]: [ Intent 文档](http://developer.android.com/reference/android/content/Intent.html)

[^4]: [ 查看Google的文档获得更多多窗格平板视图](http://developer.android.com/design/patterns/multi-pane-layouts.html)的信息。

[^5]: [ 感谢，NSHipster](http://nshipster.com/uicollectionview/)

---

 
   
原文 [Android 101 for iOS Developers](http://www.objc.io/issue-11/android_101_for_ios_developers.html)

