## 简介

说起 Android，最大的特点莫过于运行其平台上的应用可以很容易的启动别的应用以及互相之间分享数据。回首 iOS 1.0 时代，应用之间是完全隔离的，无法进行通信（至少非 Apple 应用之间是这样的），甚至到了 iOS SDK 面世之时，这种状况也没有改变。

iOS 6 之前的系统，若要在编写邮件过程中直接加入照片或视频是件很麻烦的事。iOS 6 发布以后，这项功能才得到根本性的改善。但是在 Android 的世界里，自发布的第一天，这种功能就是天生携带的。

类似的系统平台层面的差异还有许多。比如有这样一个场景：拍一张照片，然后用某个图片处理 app 里编辑一下，接着将照片分享到 Instagram。

*注意：这里只是列举个别细节。*

iOS的做法是：

1. 打开系统拍照应用拍张照片。
2. 回到主界面，找到*图片编辑*应用，启动应用，选择已存在照片，从系统相册里选取照片，然后编辑。
3. 如果*图片编辑*应用恰好支持直接分享**且** Instagram 又在分享列表中，就此完成任务。
4. 如果第 3 点条件不满足，那就得先把编辑好的照片保存到系统相册。
5. 再一次回到主界面，找到 *Instagram* 然后打开它...
6. 导入之前编辑保存的照片，然后分享给 Instagram 上的潮友们。;)

至于 Android，就简单得多了：

1. 打开拍照应用，拍张照片。
2. 向右滑查看“相册”，然后点击分享按钮。选择想要使用的*图片编辑*应用，然后直接编辑。
3. 如果*图片编辑*应用支持直接分享（我还从来没见过哪个图片处理应用不支持直接分享的），点击分享然后选择 Instagram。假如这个应用不支持分享，直接卸载算了，换个靠谱的应用来处理，或者干脆用系统集成的图片编辑器。KitKat 之后的系统内建编辑器已经相当酷炫。

需要说明的是，对于那些提供分享功能的 iOS 应用来说，其处理流程和 Android 基本是一致的。根本性的差别是，如果应用本身不支持分享那就断绝了分享给其他应用的道路。与 Facebook 和 Twitter 一样，Instagram 这类热门应用还好，但是除此之外还有大量的应用，基本上没什么应用会集成针对它们的分享服务。

比如说你想把 Instagram 里的某张照片分享到 Path 上面（我知道，Path 比较小众，但是...）。如果是 Android 系统，直接从 *chooser dialog (选择对话框)* 中选择 Path 即可。就是这么简单。

还是说回正题，*Intents*。

## 什么是 Android Intent？

在英语词典里 Intent 的定义是：

    noun （名词）
    intention or purpose （意图、目的）
    

来自 Android [官方文档](http://developer.android.com/guide/components/intents-filters.html)的说明是，`Intent` 对象*主要解决 Androi d应用各项组件之间的通讯*。事实上，Intent 就是对将要执行的操作的一种抽象描述。

看起来很简单，实际上 Intent 的意义远不止于此。在 Android 世界中，Intent 几乎随处可见，无论你开发的 app 多么简单，也离不开 Intent；小到一个 Hello World 应用也是要使用 Intent 的。因为 Intent 最基础最常见的用法就是启动 `Activity`。[^1]

## 如何理解 Activities 和 Fragments

在iOS中，与 `Activity` 相比较，最相似的东西就是 `UIViewController` 了。切莫在 Android 中寻找 `ApplicationDelegate` 的等价物，因为没有。也许只有 `Application` 类稍微贴近于 `ApplicationDelegate` ，但是从架构上看，它们有着本质的区别。

由于厂商把手机屏幕越做越大，一个全新的概念 `Fragments`[^2]（碎片）随之而生。最典型的例子就是新闻阅读类应用。在小屏幕的手机上，一般用户只能先看到文章列表。选中一篇文章后，才会全屏显示文章内容。

没有 `Fragments` 的时候，开发者需要创建两个 activities（一个用于展示文章列表，另一个用于全屏展示文章详情），然后在两者来回切换。

在出现大屏幕的平板之前，这么都做没什么问题。因为原则上，同一时间只有**一个** activity 对用户可见，但自从 Android 团队引入了 `Fragments`，一个宿主 `Activity` 就可以同时展示多个 `Fragments` 了。

现在，完全可以用一个 `Activity` 嵌入**两个** `Fragments` 的方式来替代先前使用两个不同 `Activities` 的做法。一个 `Fragment` 用来展示文章列表，另一个用来展示详情。对于小屏幕的手机，可以用两个 `Fragments` 交替显示文章列表和详情。如果是平板设备，宿主 Activity 会同时显示两个 Fragments 的内容。类似的东西可以想像一下 iPad 中的邮件应用，在同一屏中，左边是收件箱，右边是邮件列表。

### 启动 Activities

Intents 最常见的用法就是用来启动 activities（以及在 activities 之间传递数据）。`Intent` 通过定义两个 activities 之间将要执行的动作从而将它们粘合起来。

然而启动一个 `Activity` 并不简单。Android 中有一个叫做 `ActivityManager` (活动管理器)的系统组建负责创建、销毁和管理 activities。这里不去过多探讨 `ActivityManager` 的细节，但是需要指出的是它承担全程监视已启动的 activities 以及在系统内发送广播通知的职责，比如说，启动过程结束这件事就是由 `ActivityManager` 来向安卓系统的其他部分发放通知的。

`ActivityManager` 是安卓系统的一个极重要的部分，同时它依靠 `Intents` 来完成大部分工作。

那么 Android 系统到底是如何利用 `Intent` 来启动 `Activity` 的呢？

如果你仔细挖掘一下 `Activity` 的类结构就会发现：它继承自 `Context`，里面恰好有个抽象方法 `startActivity()`，其定义如下：

    public abstract void startActivity(Intent intent, Bundle options);

`Activity` 实现了这个抽象方法。也就是说只要传递了正确的 `Intent`，可以对任意一个 `Activity` 执行启动操作。

比如说我们要启动一个名为 `ImageActivity` 的 `Activity`。

其中 `Intent` 的构造方法是这样的：

    public Intent(Context packageContext, Class<?> cls)

需要传递参数 `Context`（注意，可以认为每一个 `Activity` 都是一个有效的 `Context`）和 `Class` 类。

接下来：

    Intent i = new Intent(this, ImageActivity.class);
    startActivity(i);

这之后会触发一系列调用，如无意外，最终会成功启动一个新的 `Activity`，当前的 `Activity` 会进入 paused（暂停）或者 stopped（停止）状态。

Intents 还可以用来在 Activities 之间传递数据，比如我们将信息放入 *Extras* 来传递：

    Intent i = new Intent(this, ImageActivity.class);
    i.putExtra("A_BOOLEAN_EXTRA", true); //boolean extra
    i.putExtra("AN_INTEGER_EXTRA", 3); //integer extra
    i.putExtra("A_STRING_EXTRA", "three"); //integer extra
    startActivity(i);

*extras* 存储在 Android 的 `Bundle`[^3]中，`Bundle` 在这里可以被看做是一个可序列化的容器。

这样 `ImageActivity` 就可以通过 `Intent` 来接收信息，可以通过如下方式将信息取出：

     int value = getIntent().getIntExtra("AN_INTEGER_EXTRA", 0); //名称，默认值

上面就是如何在 Activities 之间传简单值。当然也可以传序列化对象。

假如一个对象已实现序列化接口 `Serializable`。接下来可以这么做：

    YourComplexObject obj = new YourComplexObject();
    Intent i = new Intent(this, ImageActivity.class);
    i.putSerializable("SOME_FANCY_NAME", obj); //使用接收序列化对象的方法
    startActivity(i);

其它的 `Activity` 也要使用相应的序列化取值方法获取值：

    YourComplexObject obj = (YourComplexObject) getIntent().getSerializableExtra("SOME_FANCY_NAME");

特别说明，*从 Intent 取值的时候请记得判空*：

    if (getIntent() != null ) {
             //确认Intent非空后，可以进行诸如从extras取值什么的…
    }

在 Java 的世界中对空指针很敏感。所以要多加防范。;)

使用 `startActivity()` 启动了新的 activity 后，当前的 activity 会依次进入 paused 和 stopped 状态，然后进入任务堆栈，当用户点击 *back* 按钮后，activity 会再次恢复激活。正常情况下，这一系列流程没什么问题，不过还是可以通过向 Intent 传递一些 *Flags（标识）*来通知 `ActivityManager` 去改变既定行为。

由于这是一个很大很复杂的话题，此处就不做过多的展开了。可以参见文档 [任务和返回栈的官方文档](http://developer.android.com/guide/components/tasks-and-back-stack.html)来了解 *Intent Flags*。

下面看看 `Intents` 除了启动 Activity 还能做些什么。

`Intents` 还有两个重要职责：

* 启动 `Service`[^4]（或向其发送指令）。
* 发`Broadcast`（广播）。

### 启动服务

由于 `Activities` 不能在后台运行（因为在后台它们会进入 paused 态，stopped 态，甚至是 destroyed 销毁状态），如果想要执行的后台进程不需要 UI，可以使用 `Service` （服务）作为替代方案。Services 本身也是个很大的话题，简单的说它就是：没有界面或 UI 不可见的运行在后台的任务。

由于 Services 如无特殊处理是运行在UI线程上的，所以当系统内存紧张时，Services 极有可能被销毁。也就是说，如果 Services 所要执行的是一个耗时操作，那么就应该为 Services 开辟单独的线程，一般都是通过 [AsyncTask](http://developer.android.com/reference/android/os/AsyncTask.html) 来创建。比如一个 `Service` 要执行媒体播放任务，可以通过申请 *Foreground（前台）*服务状态来**强制**在通知栏中一直显示一个通知，给用户展示当前服务在做些什么。应用也可以取消前台状态（通知栏上的相应状态通知也会随之消失），但是这么做的话 `Service` 就失去了较高的状态优先级。

`Services` 机制是非常强大的，它也是 Android “多任务”处理的基础，而在早前，它被认为是影响电池用量的关键因素。其实早在 iOS 还未支持多任务的时代，Android 已经在自如的操纵多任务处理了。使用正确的话，`Services` 是平台必不可少的重要组成部分。

在以前，有一个很争议的问题，就是 `Service` 可以在**没有**任何通知的情况下转入前台运行。也就是说在用户不知情的情况下，后台可能会启动大量的服务来执行各种各样的任务。自 Android 4.0 (Ice Cream Sandwich) 之后，Google终于修复了这个“隐形”通知的问题，让无法杀掉进程且在后台静默运行的应用程序在通知栏上**“显形”**，用户甚至可以从通知栏中切换到应用内（然后杀掉应用）。虽然现在 Android 设备的续航还远不及 iOS 产品，但是至少后台静默 `Services` 已经不再是耗电的主因了。;)

`Intents` 和 `Services` 是怎么协作的呢？

首先需要一个 `Intent` 来启动 Service。而 `Service` 启动后，只要其处于非 stopped 状态，就可以持续地向它发送指令，直到它被停止（在这种情况下它将会重新启动）。

在某个 `Activity` 中启动服务：

    Intent i = new Intent(this, YourService.class);
    i.setAction("SOME_COMMAND");
    startService(i);

接下来程序执行情况取决于当下是否第一次启动服务。如果是，那么服务就会自然启动（首先执行构造方法和 `onCreate()` 方法）。如果该服务已经启动过，将会直接调用 `onStartCommand()` 方法。

方法的具体定义：`public int onStartCommand(Intent intent, int flags, int startId);`

此处重点关注 `Intent`。由于 `flags` 和 `startId` 与我们要探讨的话题相关性不大，这里直接忽略不赘述。

之前我们通过 `setAction("SOME_COMMAND")` 设置了一个 `Action`。`Service` 可以通过 `onStartCommand()` 来获取该 action。拿上面的例子来说，可以这么做：

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String action = intent.getAction();
        if (action.equals("SOME_COMMAND")) {
            // SOME_COMMAND 具体事件内容)
        }
        return START_NOT_STICKY; // 如果服务已被杀掉，不要重新启动服务
    }

如果对 `START_NOT_STICKY` 感兴趣，请参见此[安卓文档](http://developer.android.com/reference/android/app/Service.html)有很详尽的描述。

**简而言之**：如果 `Service` 已经被杀掉，不需要重启。与之相反的是 `START_STICKY`，这个表示应当执行重启。

从上面的代码段可知，能够从 `Intent` 中获取 `Action`。这就是比较常见的与 `Services` 的通讯方式。

假设我们要开发一个应用，将 Youtube 的视频以流式输送给 Chromecast (*虽然现有的Youtube应用已经具备这个功能了，但既然是 Android，我们还是希望自己做一个*)。

通过一个 `Service`来实现流式播放，这样当用户在播放视频的过程中切换到其它应用的时候，播放也不会停止。定义几种 actions：

    ACTION_PLAY, ACTION_PAUSE, ACTION_SKIP.

在 `onStartCommand()` 内，可以通过 `switch` 或者 `if` 条件判断，然后针对每一种情况做相应的处理。

理论上，服务可以随意命名，但通常情况下会使用常量（稍后会举例）来命名，良好的命名可以避免和其它应用的服务名产生冲突，比如说使用完整的包名 '`com.yourapp.somepackage.yourservice.SOME_ACTION_NAME`'。如果将服务名设为私有，那么服务只能和自己的应用通讯，否则要是想和其它应用通讯则需要将服务名公开。

### 发送和接收广播

Android 平台的强大特性之一就是：任何一个应用都可以广播一个 `Intent`，同时，任意应用可以通过定义一个 `BroadcastReceiver`（广播接收者）来接收广播。事实上，Android 本身就是采用这个机制来向应用和系统来发送事件通知的。比如说，网络突然变成不可用状态，Android 组件就会广播一个 `Intent`。如果对此感兴趣，可以创建一个 `BroadcastReceiver`，设置相应的**filter（过滤器）**来截获广播并作出适当的处理。

可以将这个过程解为订阅一个全局的频道，并且根据自己的喜好配置过滤条件，接下来会接收符合条件的广播信息。另外，若只是想要自己的应用接收广播，需要定义成私有。

继续前面的 Youtube 播放服务的例子，如果在播放的过程中出现了问题，服务可以发送一个 `Intent` *广播*来发布信息，比如“播放遇到问题，将要停止播放”。

应用可以注册一个 `BroadcastReceiver` 来监听 `Service`，以便对收到的广播做出处理。

下面看一些样例代码。

基于上面的例子，你可能会定义一个 `Activity` 用来展示和播放有关的信息和操作，比如当前的播放进度和媒体控制按钮（播放，暂停，停止等等）。你可能会非常关注当前服务的状态；一旦有错误发生，你需要及时知晓（可以向用户展示错误提示信息等等）。

在 activity（或者一个独立的 .java 文件）中可以创建一个广播接收器：

    private final class ServiceReceiver extends BroadcastReceiver {
        public IntentFilter intentFilter;
        public ServiceReceiver() {
            super();
            intentFilter = new IntentFilter();
            intentFilter.addAction("ACTION_PLAY");
            intentFilter.addAction("ACTION_STOP");
            intentFilter.addAction("ACTION_ERROR");
        }
        @Override
        public void onReceive(final Context context, final Intent intent) {
            if (intent.getAction().equals("ACTION_ERROR")) {
               // 由于有错误发生，播放停止
            } else if (intent.getAction().equals("ACTION_PLAY")){
               // 播放视频
            }
            // 等等…
        }
     }
 
 
receiver 的实现大概如此。这里需要注意下我们向 `IntentFilter` 中添加的 `Actions`。它们分别为 `ACTION_PLAY`（播放）， `ACTION_STOP`（停止）， 和 `ACTION_ERROR`（错误）。

由于我们使用的是 Java，列举一下 Android 的习惯用法：

`private ServiceReceiver mServiceReceiver;` 可以用此法将其定义为 Activity 的*成员变量*。然后在 `onCreate()` 方法中对其进行实例化，比如：`mServiceReceiver = new ServiceReciver();`。

当然，单单创建这样的一个对象是不够的。我们需要在某处进行注册。第一反应，你可能会认为可以在 `Activity` 的 `onStart()` 方法内注册。当 `onStart()` 执行的时候，意味着用户可以看到这个 `Activity` 了。

注册方法详情如下（定义在 `Context` 中）：

    public abstract Intent registerReceiver(BroadcastReceiver receiver, IntentFilter filter);

*由于 `Activities` 和 `Services` 都是 `Contexts`，所以它们本身都实现了这个方法。这表示它们都可以注册一个或多个 `BroadcastReceivers`。*

此方法需要参数 `BroadcastReceiver` 和 `IntentFilter`。之前已经创建好，可直接传参：

    @Override
    public void onStart() {
        onStart();
          registerReceiver(mServiceReceiver, mServiceReceiver.intentFilter);
    }

请养成良好的 Java / Android 开发习惯，当 `Activity` 停止的时候，请注销相应的注册信息：

    @Override
    public void onStop() {
        super.onStop();
        unregisterReceiver(mServiceReceiver);
    }

这种处理本身没什么问题，但是要提醒大家，一旦用户离开了当前应用，将不会再收到广播。这是由于 `Activity`即将停止，此处在 `onStop()` 这里注销了广播接收。所以当你设计 `BroadcastReceivers` 的时候，需要考虑清楚，这种处理方式是否适用。毕竟还有其它不依赖于 `Activity` 的实现方式可供选择。

每当 `Service` 侦测到错误发生，它都会发起一个广播，这样 `BroadcastReceiver` 可以在 `onReceive()` 方法中接收广播信息。

广播接收处理也是 Android 中非常重要非常强大非常核心的机制。

读到这里，爱思考的读者们可能会问这些广播到底可以 *全局*到什么程度？如何将广播设置为私有以及如何限制它们只和其所属应用通讯？

事实上 Intents 有两类：*显式的 (explicit) *和*隐式的 (implicit)*。

所谓显式 Intent 就是明确指出了目标组件名称的 Intent，由于不清楚其它应用的组件名称，显式 Intent 一般用于启动自己应用内部的组件。隐式 Intent 则表示不清楚目标组件的名称，通过给出一些对想要执行的动作的描述来寻找与之匹配的组件（通过定义过滤器来罗列一些条件用于匹配组件），隐式 Intent 常用于启动其它应用的组件。

鉴于之前给出的例子中使用的就是*显式 Intents*，这里将重点讨论一下*隐式 Intents*。

我们通过一个简单的例子来看看*隐式 Intents*的强大之处。定义过滤器 (filter) 有两种方式。第一种与 iOS 的自定义 URI 机制很类似，比如：yourapp://some.example.com。

如果你的设计是想 Android 和 iOS 都通用，那么别无他法只能使用 URI 策略。如果只是针对 Android 平台的话，建议尽量使用标准 URL 的方式（比如 http://your.domain.com/yourparams）。之所以这么说是因为这与如何看待自定义 URI 方案的利与弊有关，对这个问题不做具体的展开了，总而言之（下文引自 stackoverflow）：

> 为了避免不同实体之间的命名冲突，web 标准要求应严格要控制 URI 的命名。而使用自定义 URI 方案与其 web 标准相违背。一旦将自定义 URI 方案部署到互联网上，等于直接将方案名称投入到整个互联网的命名空间中去（会又很大的命名冲突可能性），所以应严格遵守相应的标准。

来源：[StackOverflow](http://stackoverflow.com/a/2449500/2684)

上述问题暂且放一边，下面看两个例子，一个是用标准 URL 来实现之前 YouTube app，另一个是在我们自己的 app 中采用自定义 URI方案。

因为每个Android都有配置文件`AndroidManifest.xml`，可以在其中定义`Activities`，`Services`，`BroadcastReceivers`，versions（版本信息），Intent filter等描述信息，所以实现起来比较简单。[详情见文档](http://developer.android.com/guide/topics/manifest/manifest-intro.html)。

Intent 过滤器的本质是系统依照过滤条件检索当前已安装的所有应用，看看有哪些应用可以处理指定的 URI。

如果某个 app 刚好匹配且是唯一能够匹配的 app，就会自动打开这个 app。否则的话，可以看到类似这样的一个选择对话框：

![image](/images/issues/issue-11/android-dialog-choser.jpg)

为什么 Youtube 的官方应用会出现在清单上呢？

我只是在 Facebook 的应用里点了一个 Youtube 的链接而已。为什么 Android 会知道我点的是 Youtube 的链接？*这其中有什么玄机*？

假设我们打开 Youtbube 应用的 `AndroidManifest.xml`，我们应该能看到类似如下的配置：

    1 <activity android:name=".YouTubeActivity">
    2     <intent-filter>
    3        <action android:name="android.intent.action.VIEW" />
    4       <category android:name="android.intent.category.DEFAULT" />
    5         <category android:name="android.intent.category.BROWSABLE" />
    6       <data
    7        android:scheme="http"
    8        android:host="www.youtube.com"
    9        android:pathPrefix="/" />
    10   </intent-filter>
    11 </activity>

接下来我们会逐行解释一下这段XML信息。

第 1 行是声明 activity（Android 中的每个 `activity` 都必须在配置文件中声明，而过滤器则不是必须的）。

第 2 行声明了 action。此处的 `VIEW` 是最常用的action，它表示会向用户展示数据。因为还存在一些受保护的只能用于系统级传输的 action。

第 4－5 行声明了类别 (categories)。隐式 Intents 要求至少有一个 action 和一个 category。categories 里主要定义 Intent 所要执行的 Action 的更多细节。在解析 Intent 的时候，只有满足 categories 中全部描述条件的 activities 才会被使用。Android 把所有传给 `startActivity()` 的隐式 Intent 当作它们包含至少一个 category `android.intent.category.DEFAULT` (CATEGORY_DEFAULT 常量)，想要接收隐式 Intent 的 `Activity` 必须在它们的 Intent Filter 中配置 `android.intent.category.DEFAULT`。

`android.intent.category.BROWSABLE` 是另一个敏感配置：

> 能通过浏览器安全调用的 Activity 必须支持这个 category。比如，用户从正在浏览的网页或者文本中点击了一个 e-mail 链接，接下来生成执行这个 link 的 Intent 会含有 BROWSABLE categroy 描述，所以只有支持这个 category 的 activities 才会有可能被匹配到。一旦承诺支持这个 category，在被 Intent 匹配调用后，必须保证没有恶意的行为或内容（至少是在用户不知情的情况下不可以有）。

来源：[Android Documentation（官方文档）](http://developer.android.com/reference/android/content/Intent.html#CATEGORY_BROWSEABLE)

这个点很关键，Android 通过它构建了一种机制，允许应用去响应任何的链接。利用这个机制你完全可以构建自己的浏览器去处理任何 URL 的请求，如果用户喜欢的话完全可以将你的浏览器设置成默认浏览器。

第 6-9 行声明了所要操作的数据*类型*。在本例中，我们使用 scheme（方案／策略）和 host（主机）来进行过滤，所以任何以 http://www.youtube.com/ 开头的链接均可处理，哪怕是在 web 浏览器里点击链接。

在 Youtube 应用内的 `AndroidManifest.xml` 里配置以上信息后，每当 *Intent 解析*的时候，Android 都会在系统已安装的应用中根据 `<intent-filter>` 内定义的信息来过滤和匹配 Intent（或者像我们的例子一样，从通过代码注册的 `BroadcastReceivers` 中寻找）。

Android `PackageManager`[^5] 会根据 `Intent` 信息（action，type 和 category）来寻找符合条件的组件来处理 Intent。如果找到唯一合适的组件，会自动调用，否则会像上面例子里那样弹出一个选择对话框，这样用户可以自行选择应用（或者根据默认设置中指定的应用）来处理 Intent 动作。

这个方案适用于大多数的应用，但是如果想要采取和 iOS 一样的 link 就只能使用自定义 URI。不过在 Android 中，两种方案是都支持的，而且还可以对同样的 activity 增加多种过滤条件。还是以 YoutubeActivity 为例，我们假定一个 Youtube URI 方案配置上去：

    1 <activity android:name=".YouTubeActivity">
    2     <intent-filter>
    3        <action android:name="android.intent.action.VIEW" />
    4       <category android:name="android.intent.category.DEFAULT" />
    5         <category android:name="android.intent.category.BROWSABLE" />
    6       <data
    7        android:scheme="http"
    8        android:host="www.youtube.com"
    9        android:pathPrefix="/" />
    10      <data android:scheme="youtube" android:host="path" />
    11   </intent-filter>
    12 </activity>

这个 filter 和先前配置的基本一致，除了在第 10 行增配了自定义的 URI 方案。

这样的话，应用可以支持打开诸如：`youtube://path.to.video` 的链接，也可以打开普通的 HTTP 链接。总之，你想给 `Activity` 中配置多少 filters 和 types 都可以。

#### 使用自定义 URI 方案到底有什么负面影响？

自定义 URI 方案的问题是它不符合 W3C 针对 URIs 制定的各项标准。当然这个问题也并不绝对，如果只是在应用包内使用自定义 URI 是 OK 的。但像前文所说，若公开自定义 URI 则会存在命名冲突的风险。假如定义一个 URI 为 `myapp://`，谁也不能保证别的应用不会定义同样的东西，这就会有问题。反过来说，使用域名就不存在这种冲突的隐患。拿我们之前构建了自己的 Youtube 播放 app 来说，Android 会提供选择是启用自己的 Youtube 播放器还是使用官方 app。

同时，浏览器可能无法解析某些自定义URL，比如 `yourapp://some.data`，极有可能报 404。这就是*违背*规则和不遵守标准的风险。

### 数据分享

可以通过 `Intent` 向其他应用*分享*信息，比如说向社交网网站*分享*个帖子，向图片编辑 app 传递一张图片，发邮件，发短息，或者通过即时通讯应用传些资源什么的等等都是再分享数据。目前为止，我们介绍了怎么创建 intent filters，还有如何将应用注册成广播接收者以便在收到可响应的通知时做出相应的处理。在本文的最后一部分，将要探讨一下如何*分享*内容。再一次：*所谓 Intent 就是对将要执行的动作的一种抽象描述*。

#### 分享到社交网站

在下面的例子中，我们会分享一个文本信息并且让用户做出最终的选择：

    1  Intent shareIntent = new Intent(Intent.ACTION_SEND);
    2  shareIntent.setType("text/plain");
    3  shareIntent.putExtra(Intent.EXTRA_TEXT, "Super Awesome Text!");
    4  startActivity(Intent.createChooser(shareIntent, "Share this text using…"));

第 1 行使用构造方法 `public Intent(String action)` 根据指定 action 创建了一个 `Intent`；

`ACTION_SEND` 表示会向别的应用*发送数据*。在本例中，要传递的信息是 “Super Awesome Text!”。但是目前为止还不知道要传给谁。最终，这将由用户决定。

第 2 行设置 MIME 数据的类型为 `text/plain`。

第 3 行将要传递的数据通过 `exstra` 放到 Intent 中去。

第 4 行会触发本例的用户选择功能。其中 `Intent.createChooser` 是将 Intent 重新封装，将其 action 指定为 `ACTION_CHOOSER`。

这里面没什么特别复杂的东西。这个 action 就是用来弹出选择界面的，也就是说让用户自己选择处理方式。某些场景下，你可能会设计呈现更加具体的选择（比如用户正在发送 email，可以直接给用户提供统默认的邮件客户端），但是就本例而言，任何能够处理我们要分享的文本的应用都会被纳入选择清单。

具体的运行效果（选择列表太长了，得滚动着来看）如下：

![image](/images/issues/issue-11/android-chooser.gif)

而后我选择了用 Google Translate 来处理文本，结果如下：

![image](/images/issues/issue-11/android-translate.jpg)

Google Translate 将刚刚的文本翻译成了意大利文。

## 再给出一个例子

总结之前，再看个例子。这次会展示如何分享和接收一张图片。也就是说，当用户分享图片时，让我们的 app 出现在用户的分享选择列表中。

在 `AndroidManifest` 做如下配置：

    1    <activity android:name="ImageActivity">
    2        <intent-filter>
    3            <action android:name="android.intent.action.SEND"/>
    4            <category android:name="android.intent.category.DEFAULT"/>
    5            <data android:mimeType="image/*"/>
    6        </intent-filter>
    7    </activity>

注意，至少要配置一个 action 和一个 category。

第 3 行将 action 配置为 `SEND`，表示可以配置 `SEND` 类型的 actions。

第 4 行声明 category 为 `DEFAULT`。当使用 `startActivity()` 的时候，会默认添加 category。

第 5 行很重要，是将 MIME 类型设置为*任何类型的图片*。

接下来，在 `ImageActivity` 中对Intent的处理如下：

    1    @Override
    2    protected void onCreate(Bundle savedInstanceState) {
    3        super.onCreate(savedInstanceState);
    4        setContentView(R.layout.main);
    5        
    6        // 处理intent（如果有intent）
    7        Intent intent = getIntent();
    8        if ( intent != null ) {
    9            if (intent.getType().indexOf("image/") != -1) {
    10                 Uri data = intent.getData();
    11                 //  处理image…
    12            } 
    13        }
    14    }

有关的处理代码在第 9 行，在检查 Intent 中是否包含图片数据。

接下来来看看*分享*图片的处理代码：

    1    Uri imageUri = Uri.parse("/path/to/image.png");
    2    Intent intent = new Intent(Intent.ACTION_SEND);
    3    intent.setType("image/png");    
    4    intent.putExtra(Intent.EXTRA_STREAM, imageUri);
    5    startActivity(Intent.createChooser(intent , "Share"));

关键代码在第 3 行，定义了 MIME 类型（只有 `IntentFilters` 匹配到的应用才会出现在选择列表中），第 4 行是将要分享的数据放入 Intent 中。

最后，第 5 行创建了之前看到过的*选择*对话框，其中只有能够处理 `image/png` 的应用才会出现在选择对话框的列表中。

## 总结

我们从大体上介绍了什么 Intent，它能做些什么，以及如何在 Android 中分享信息，但是还有很多内容本文没有涵盖。Intent 这种机制非常强大，相比较于 iOS 设备而言，Android 这个特性提供了非常便捷的用户体验。iOS 用户（包括我在内）会觉得频繁的返回主界面或者操作任务切换是非常低效的。

当然，这也并不意味着在应用之间分享数据这方面 Android 的技术就是更好的或者说其实现方式更高级。归根结底，这是个人喜好问题，就像有些 iOS 用户就不喜欢 Android 设备的*返回键*而 Android 用户却特别中意。理由是这些 Android 用户觉得返回键标准、高效且位置固定，总是在 *home* 键旁。

我记得我在西班牙生活的时候，曾经听过一个很棒的谚语： “Colors were created so we can all have different tastes”（“各花入各眼，存在即合理”）。

##延伸阅读

* [Intents and Filters](http://developer.android.com/guide/components/intents-filters.html)
* [Intents](http://developer.android.com/reference/android/content/Intent.html)
* [Common Intents](http://developer.android.com/guide/components/intents-common.html)
* [Integrating Application with Intents](http://android-developers.blogspot.com.es/2009/11/integrating-application-with-intents.html)
* [Sharing Simple Data](http://developer.android.com/training/sharing/index.html)

[^1]: Activities 是在你的应用中提供单个屏幕的用户界面的组件。

[^2]: Fragment 代表了一个 activity 中的行为或者一部分用户界面。

[^3]: 由字符串到 一组 Parcelable 类型的映射。

[^4]: Service 是这样一种应用组件：当用户与应用无交互时，它还可以执行长时间运行的操作，或者为其他应用提供某种功能。

[^5]: [PackageManager](http://developer.android.com/reference/android/content/pm/PackageManager.html): 是用来从当前安装在设备上的 package 中获取各类信息的类。

---

 
   
原文 [Android Intents](http://www.objc.io/issue-11/android-intents.html)
