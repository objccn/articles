现在看来习惯性的查看我们的设备上的信息几乎成了我们的另一种本能。几乎每小时我们都会拿出我们的手机，看看状态栏有没新的消息，然后放回我们的口袋。尤其对 Android 用户来说更是如此，因为这是他们与设备之间的主要交互方式之一。 解锁屏幕，读封邮件，接受好友请求，为你的好友的签到点个赞，随便访问几个不同的应用，所有这些操作都可以通过通知栏完成。

对一些人来说则是另一个完全不同的世界。尤其是相对于 iOS 在历史上曾一度无法获取通知，而现在 iOS 开发者也无法像 Android 一样细粒度的定制他们的应用通知。甚至在之前都无法接收静默通知，虽然这些在 iOS 7 上得到了改善，但一经细嚼仍然相当糟糕，很多 Android 开发者玩转多年的关键特性在 iOS 系统中仍然是空白。

Android 从最开始就可以接收通知这一点已经被吹捧了很长一段时间。所有的通知都集中在系统栏电量和信号图标的旁边，但是要想了解 Android 通知系统为何可以做到这些，究其根源，我们需要了解 Android 系统的演变。

因为 Android 允许开发者们自由控制他们的后台进程，他们可以在任何时候以任何理由创建并显示通知。它从来没有传递通知给应用程序或状态栏的概念。它被送到任何你想要它去的地方。 

你可以随时随地访问通知。由于大多数应用没有强迫去实现一个全屏的设计，用户在他们需要的时候可以下拉通知‘抽屉’。对多数人来说，Android 是他们的第一个智能手机，它改变了人们过往查看通知的惯例，过去你需要打开一个个单独的应用去查看你是否错过了电话，短信或者邮件。


Android 1.6 中的通知 (Donut): 

![Notifications in Android 1.6](/images/issues/issue-11/android-g1-50.jpg) 

Android 4.4 的通知 (KitKat):

![Notifications in Android 4.4](/images/issues/issue-11/modern_notes.png)


## 简史

从 Android 在2008年登上舞台开始，通知系统走过了漫长的道路。

### Android 1.5 - 2.3 

这是对大多数人来说的 Android 的开始（包括我）。我们有一些可以定制的功能，比如应用图标，标题，描述以及时间。如果你需要加入自定义的控件，比如，一个音乐播放器当然也可以。系统会维护所需的宽高限制，而你则可以加入你想要的视图。在通知中使用自定义的布局是当时大多数音乐播放器实现自定义控件的方式：

    private void showNotification() {
      // 创建基本通知（the R.drawable 参考自 png 图片）
      Notification notification = new Notification(R.drawable.stat_notify_missed_call,
          "Ticket text", System.currentTimeMillis());

      // 创建 Intent
      Intent intent = new Intent(this, Main.class);

      // 让 intent 等待直到他准备好。
      PendingIntent pi = PendingIntent.getActivity(this, 1, intent, 0);

      // 设置最后的事件信息
      notification.setLatestEventInfo(this, "Content title", "Content subtext", pi);

      // 获取通知 manager 的实例
      NotificationManager noteManager = (NotificationManager)
          getSystemService(Context.NOTIFICATION_SERVICE);

      // 发布到系统栏
      noteManager.notify(1, notification);
    }

代码：这段是如何在1.5-2.3中实现通知功能。

Android 1.6 中的运行的结果:

![Notifications in Donut 1.6](/images/issues/issue-11/donut.png) 

Android 2.3 中的运行结果:

![Notifications in Gingerbread 2.3](/images/issues/issue-11/gingerbread_resized.png)


### Android 3.0 - 3.2

通知系统在 Android 3.0 上实际有一丝退步， Android 平板，一个用来对抗 iPad 的版本，是 Android 在大屏幕运行的一次尝鲜。相对于单一的抽屉显示，Android 尝试用额外的控件带来新的通知体验，你依旧有一个抽屉类型的通知，同时你也可以接收像 [`growl`](http://growl.info) 那样的通知。幸运的是，与此同时 Android 提供了一个叫做 `NotificationBuilder` 的全新 API，允许我们利用[建造者模式](http://en.wikipedia.org/wiki/Builder_pattern) 去构建我们的通知。尽管略微复杂，但构造器会根据每个新版操作系统的不同来构建复杂的通知对象：

    // 创建 Intent 实例
    Intent intent = new Intent(this, Main.class);

    // 在准备好使用之前，持有intent
    PendingIntent pi = PendingIntent.getActivity(this, 1, intent, 0);

    Notification noti = new Notification.Builder(getContext())
      .setContentTitle("Honeycomb")
      .setContentText("Notifications in Honeycomb")
      .setTicker("Ticker text")
      .setSmallIcon(R.drawable.stat_notify_missed_call)
      .setContentIntent(pi)
      .build();

    // 获取通知 manager 的实例
    NotificationManager noteManager = (NotificationManager)
        getSystemService(Context.NOTIFICATION_SERVICE);

    // 发布到系统栏
    noteManager.notify(1, notification);

通知在 Android 3.2（蜂巢）接后的初始状态：

![Honeycomb notifications ticket text](/images/issues/issue-11/initially-received-hc.png)


当你在导航栏点击它时候的样式:

![Honeycomb notifications tapping notification](/images/issues/issue-11/selecting_notification_hc.png)

当你点击时钟看到的通知的样式:

![Honeycomb notifications tapping clock](/images/issues/issue-11/selecting_clock_hc.png)

各种冗余的通知让用户感到困惑不知道它们代表什么，这就对开发人员提出设计挑战，如何在恰当的时间返回恰当的信息给用户。

### 最终, 4.0-4.4

与其他系统相比，Android 从 4.0 之后真正充实和统一了通知体验。虽然在 4.0 没有带来任何激动人心的设计，但是 4.1 带来一种聚合的通知（一种全新的可视化，让一个 cell 中可以显示多个通知），可扩展的通知（比如，显示电子邮件的第一段），图片通知，以及可操作的通知。不用说，这提供了一种全新的方式可以带给用户 out-of-app 的体验。如果有人在 Facebook 加我为好友，我可以简单的在通知栏上点击“接受”，再也不用打开 Facebook 应用。如果我收到了一封垃圾邮件，我可以直接归档而不用再次查看。

这里有一些 [Tumblr 应用](https://play.google.com/store/apps/details?id=com.tumblr)利用了新的 4.0+ API 的例子，使用它们构建通知出人意料的简单；只需要你加入一些额外的通知风格到 `NotificationBuilder` 中就可以了。

#### 大文本通知

如果文字足够短，还有什么理由让我打开应用来阅读？大文本样式提供了更大的阅读空间来解决这个问题。再也不需要浪费时间打开一个应用

    Notification noti = new Notification.Builder()
      ... // 和之前一样的通知属性设置
      .setStyle(new Notification.BigTextStyle().bigText("theblogofinfinite replied..."))
      .build();

大文本通知折叠:

![Notifications in Cupcake 1.5](/images/issues/issue-11/shrunk_text.png)

大文本通知展开:

![Notifications in Cupcake 1.5](/images/issues/issue-11/bigtext.png)


#### 大图片通知

大图片通知提供了不需要打开应用就能够享受到内容优先的美妙体验。不仅可以提供大量的内容，也是一种优雅的交互方式。

    Notification noti = new Notification.Builder()
      ... // 同之前一样的属性设置方法
      .setStyle(new Notification.BigPictureStyle().bigPicture(mBitmap))
      .build();

![Big picture notification](/images/issues/issue-11/big_pic.png)


#### 聚合 (Roll-up) 通知

聚合通知是将多个通知放在一起，聚合有一点欺骗性因为它实际上并不堆栈现有的通知，你依然可以自己创造他们，所以这真的是一种很好展示通知的方式：

    Notification noti = new Notification.Builder()
      ... // The same notification properties as the others 和之前一样的属性设置
      .setStyle(new Notification.InboxStyle()
         .addLine("Soandso likes your post")
         .addLine("Soandso reblogged your post")
         .setContentTitle("3 new notes")
         .setSummaryText("+3 more"))
      .build();

![Rollup notification](/images/issues/issue-11/rollup.png)


#### 可操作通知

在通知中增加操作就和你想象的一样容易。建造者模式可以确保它能够使用任何系统默认的样式，使用户总是感觉在使用通知抽屉：

    Notification noti = new Notification.Builder()
      ... // The same notification properties as the others
      .addAction(R.drawable.ic_person, "Visit blog", mPendingBlogIntent)
      .addAction(R.drawable.ic_follow, "Follow", mPendingFollowIntent)
      .build();

![Action notification](/images/issues/issue-11/actions.png)

这类交互是一种对用户负责的设计，并且操作简单快速，受限于 Android 的缓慢性能，这种快捷操作的方式非常受欢迎，因为你实际上不需要打开应用就可以使用它。


### Android 穿戴设备

现在的科技圈对于任何一个人来说都已经不再像之前那么神秘，正因如此 Android 可穿戴设备也成为了科技设备中的一份子。它是否能够成功的成为一类消费品这件事情似乎仍然有待商榷，但是对于那些想要支持 Android 穿戴设备的开发者来说，仍然有很多不容忽视存在着的障碍。没有辜负 Android 系统传承下来的一些优势，其穿戴设备在与你的设备进行同步的时候似乎总可以接受正确的通知。但事实上，你的手机与 Android 穿戴设备连接后，它将会在没有代码修改的情况下对设备推送构造器创建的通知。能够简单使用建造者模式则意味着无论出现什么设备，只要它们能够支持 Android 系统和 Android 可穿戴设备，立即会有大量熟练使用 API 来收发数据的应用开发者出现。

<img style="display:inline;" alt="Action notification" src="/images/issues/issue-11/picture.png" width="40%"><img style="display:inline;margin-left:1em;" alt="Action notification" src="/images/issues/issue-11/hunkosis.png" width="40%">

NotificationBuilder 提供了 out-of-the-box 的 android 穿戴设备支持，不用写任何额外的代码！

## 自定义通知

虽然 Android 的 `NotificationBuilder` 支持高自由度定制，但有的时候依然无法满足人们的需求，这就是为何要引入自定义通知布局。很难想象当你拥有全部的通知系统的控制权限的时候。你将如何改变它，让它与众不同? 在诸多约束的情况下不断创新着实很难，但是许多 Android 开发者已经开始迎难而上。

自定义音乐播放器通知:

![Custom music player notification](/images/issues/issue-11/music_player.png) 

自定义天气通知:

![Custom weather notification](/images/issues/issue-11/weather.jpg) 

自定义电量通知:

![Custom battery notification](/images/issues/issue-11/battery_widget.png)

自定义通知仅限于视图组件所支持[远程视图](http://developer.android.com/reference/android/widget/RemoteViews.html)的一个子集，这些视图组件本身不能高度延伸或者被覆盖。虽然只能轻度定制，但是你依然可以利用基本组件构造复杂的通知。

然而创建这些自定义视图可能需要更多的工作。使用 Android 的 XML 创建自定义通知视图布局系统，你要确保在不同 Android 版本看起来依旧良好。这非常痛苦，但是当你看看这些美丽的通知，你会觉得一切又那么有价值:

    <?xml version="1.0" encoding="utf-8"?>
    <LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    	android:layout_width="match_parent"
    	android:layout_height="match_parent"
    	android:orientation="horizontal">

    	<ImageView
    		android:id="@+id/avatar"
    		android:layout_width="32dp"
    		android:layout_height="32dp"
    		android:layout_gravity="center_vertical" />

    	<TextView
    		android:layout_width="wrap_content"
    		android:layout_height="wrap_content"
    		android:layout_gravity="center_vertical"
    		android:text="You received a notification" />

    </LinearLayout>
    

这是一个非常基本的自定义通知布局，包含一张图片以及一段文字。

## 通知的行为

### 推送通知

现在我们已经了解了大量历史，接下来让我们看一些关于通知是如何工作的有趣行为。也许这部分内容我们已经提及，开发者可以
*完全*控制通知系统。就是说通知可以因为任何原因在任何时候显示或者消失。甚至不需要从 Google 推送服务接收一个通知。实际上，就算我们收到一个推送通知，它默认也不会显示在状态栏，你需要自己去捕捉推送通知并且决定如何去处理它。

举例来说，一个常规的通知交互应该是这个样子：

1. 接收远程推送通知
2. 检查 payload，根据 payload 建立一个后台服务去获取数据。
3. 获取并解析返回的数据
4. 构建并显示通知

比较有趣的是第二步和第三步，后台服务没有时间限制。如果推送通知告诉你要下载 1GB 的文件，好吧无所谓！在大多数情况下，如果一个后台进程用时非常短的话，系统并没有要求你必须显示一个通知。但长时间后台服务（比如音乐播放器）依旧需要在状态栏显示一个图标。对于开发者来说这是一种值得深思的做法，确保用户知道是何种服务在后台长时间运行。

虽然只有 4 个步骤，但是有一多半的开发者不愿意处理。如果我可以直接发送整个 payload 是不是会更简洁？[GCM (Google Cloud Messaging)](http://developer.android.com/google/gcm/index.html) 允许 payloads 控制在 4KB 之内，平均来说，它在 1,024 到 4,096 UTF-8 字符之间（取决于字符）。除非你要推送一张图片，不然你可以塞入任何你想要的内容。听起来多棒！

### 通知回调

那么开发人员是如何控制用户与通知之间的互动？当然，我们已经知道可以添加自定义控件和按钮，而且我们已经看到了如何实现一般的点击。但还有其他的么？实际上，当然有！有一个“删除”功能，当用户设置 `setDeleteIntent`，用户从抽屉中删除通知的时候将被逻辑删除。加入删除是一个伟大的进步，以确保我们不再次显示老旧信息:
    
    // 在 Android 中，我们可以创建任意名字让组件决定它们想要处理哪种操作    
    Intent clearIntent = new Intent("clear_all_notifications");
    PendingIntent clearNotesFromDb = PendingIntent.getBroadcast(aContext, 1, clearIntent, 0)

    Notification noti = new Notification.Builder(getContext())
      ...
      .setDeleteIntent(clearNotesFromDb)
      .build();

### 重建导航层次结构

让我们更深入地谈一谈通知的默认点击。现在你当然可以在点击通知后执行一些默认的行为。你可以仅仅打开那你的应用。用户可以自己找到他们想要去的页面。但是如果我们可以直接显示相关的页面那么体验会更加友好。如果我们收到一个邮件通知，我们直接跳转到邮件内容，如果我们的一个朋友在 Foursquare 上签到，我们直接可以打开应用显示这个他或者她所在的餐馆。允许通知指向到一个包含内容的深度链接是一个很棒的功能。但是更多时候，深度链接已经是你应用的一部分，你会遇到导航层次混乱的问题。你无法使用导航’返回‘。 Android 可以帮助你在开始之前创建视图堆栈来解决这个问题。这是通过 TaskStackBuilder 类来完成的。使用这个技术需要一些魔法并且需要一些应用架构方面的知识，但是有空你可以看看 Google 开发者网站，这里有一个[简要实现](http://developer.android.com/guide/topics/ui/notifiers/notifications.html#SimpleNotification).

用 Gmail 举例，我们告诉应用 "打开邮件应用，接着打开一份指定的邮件。" 来代替简单的打开邮件应用。用户将不会看到所有的视图创建，而只会看到最终的结果。这是多么的不可思议，因为现在我们点击返回按钮的时候，用户将不会退出应用，而只会退到应用的首页。

## 少了些了什么

我已经详细罗列了许多 Android 系统中通知的功能，同时也展示了它们有多么的强大。但是没有哪个系统是完美的，Android 的通知系统也有瑕疵。

### 标准

Android 用户面临的首要问题之一则是没有控制通知系统的功能。这就意味着如果一个应用有通知提示的时候，用户没法关闭它，唯有卸载这个应用。从 Android 4.1 开始，用户可以在设置中选择关掉指定程序的通知。这阻止了应用在状态栏的*所有*通知，这看起来是十分有用的功能，但是在用户实际使用中却受限很大，因为其实很少有人想要将所有的应用通知都关闭，他们很多时候只想关掉一些令人恼火的通知，比如 LED 提示灯闪烁或者是不停发出的提示音这类通知。

从 Android 4.1 开始，用户可以通过设置来关闭接收通知，但是这里没有一种方式来关闭 LEDs 或者声音，除非开发者显式地提供了关闭的方法。

### 显示什么

你也许认为我们已经将通知功能基本掌握了，但其实我们仍然有很大的进步空间。尽管现有的系统已经具备了一定的个性化定制功能，但我仍然希望看到它能够更上一层楼。正如早些时候我们看到的，`NotificationBuilder` 使你的通知形成一个特定的样子，也就是所有的系统通知都是一样的。如果你使用自定义布局并且建立自己的通知模式，也只有一小部分支持的组件来供你使用。如果有很复杂的组件需要定制，那出于安全考虑你的想法很有可能无法实现。如果你想做一些更高级的功能，比如帧动画，或者一个视频，请还是算了吧。

## 结论

Android 提供了给用户和开发者不少通知方面的功能。从一开始，Android 有意识的朝着更大胆的方向努力，即使从今天看来它依旧无以伦比。看看前进中的 Android 以及 Android 穿戴设备，很容易发现，通知管理 API 重点强调方便使用。虽然在细粒度的通知管理缺乏完整的 UI 控件方面有一些缺点，但是谨慎的说，如果你正在寻找一个通知优先的生态系统，Android 或许值得一试。

#### 参考

- [Android 简史](http://www.theverge.com/2011/12/7/2585779/android-history)
- [Android 通知文档](http://developer.android.com/guide/topics/ui/notifiers/notifications.html)
- [为 Android 穿戴设备创建通知](http://developer.android.com/wear/notifications/creating.html)

---

 
   
原文 [Android’s Notification Center](http://www.objc.io/issue-11/android-notifications.html)

