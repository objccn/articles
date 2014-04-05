Notifications from our devices are almost second nature for us these days. Hardly an hour goes by that we aren’t pulling out our phones, checking our status bars, and then putting our phones back in our pockets. For Android users, this is especially true, as it is one of the primary ways of interacting with their devices. Unlock your screen, read a few emails, approve some friend requests, and like your buddy’s check-in, across three different applications, all directly from the notification bar.

现在看来习惯性的检查我们的设备上的信息几乎成了我们的另一种本能。几乎每小时我们都会拿出我们的手机，看看状态栏有没新的消息，然后放回我们的口袋。尤其对 Android 用户来说更是如此，因为这是他们与设备之间的主要交互方式之一。 解锁屏幕，读读邮件，接受好友请求，为你的好友的check-in点个赞，随便访问几个不同的应用，所有这些操作都可以通过通知栏完成。

But this is an entirely different world for some. Particularly, iOS has a long history of not getting notifications quite right, and iOS developers didn’t have the same kind of fine-grained control over their apps' notifications. It wasn’t possible to receive silent notifications, to possibly wait and post them later. Things have changed in iOS 7, but the bad taste still remains in the mouths of some, and notifications are still lacking some key features that Android developers have been enjoying for years.

对一些人来说这是另一个完全不同的世界。尤其是相对于历史悠久的在 iOS 上无法正确的获取的问题，以及 iOS 开发者无法像在 Android 上细粒度的定制他们的应用通知。甚至在之前无法接受静音的通知，虽然这些在 iOS 7 上得到了改善，但一经推敲仍有瑕疵，很多 Android 开发者玩转多年的关键特性在 iOS 系统中仍然是空白。

It’s been long touted that Android 'got' notifications right from the beginning. All of your notifications were centralized in one logical place on your phone, right in the system bar, next to your battery and signal strength settings. But to understand what Android’s notification system is capable of, it’s important to understand its roots, and how the system evolved.

Android 从最开始就可以接收通知这一点已经被吹捧了很长一段时间。所有的通知都集中在系统栏电量和信号图标的旁边，但是要想了解 Android 通知系统为何可以如此优秀，究其根源，我们需要了解 Android 系统的演变。

Since Android let developers fully control their own background processes, they were able to create and show notifications at any time, for any reason. There was never a notion of delivering a notification to the application or to the status bar. It was delivered wherever you wanted it.

自从 Android 允许开发者们自由控制他们的后台进程，他们可以在任何时候以任何理由创建并显示通知。它从来没有传递通知给应用程序或状态栏的概念。它被送到任何你想要它去的地方。 

You could access this from anywhere, at any time. Since the majority of applications didn’t force a fullscreen design, users could pull down the notification 'drawer' whenever they wanted. For many people, Android was their first smartphone, and this type of notification system deviated from the notification paradigm that existed before, one where you had to arduously open every single application that had information for you, whether it be missed calls, SMSes, or emails.

你你可以在任何时候任何地方访问通知。由于大多数应用没有强迫去实现一个全屏的设计，用户在他们需要的时候可以下拉通知‘抽屉’。对多数人来说，Android 是他们的第一个智能手机，并且改变了过往查看通知的惯例，过去你需要打开一个个单独的应用去查看你是否错过了电话，短信或者邮件。


Android 1.6 中的通知 (甜甜圈): 

![Notifications in Android 1.6](http://www.objc.io/images/issue-11/android-g1-50.jpg) 

Android 4.4 的通知 (奇巧巧克力):

![Notifications in Android 4.4](http://www.objc.io/images/issue-11/modern_notes.png)


## A Brief History 简史

Notifications on Android today have come a long way since their debut in 2008.

从 Android 在2008年登上舞台开始，通知系统走过了漫长的道路。

### Android 1.5 - 2.3 

This is where Android began for most of us (including me). We had a few options available to us, which consisted mainly of an icon, a title, a description, and the time. If you wanted to implement your own custom control, for example, for a music player, you could. The system maintained the desired width and height constraints, but you could put whatever views in there you wanted. Using these custom layouts is how the first versions of many custom music players implemented their custom controls in the notification:

这是对大多数人来说的 Android的开始（包括我）。我们有一些选项可以定制，比如应用图标，标题，描述以及时间。如果你需要加入自定义的控件，比如，一个音乐播放器当然也可以。系统可以维护所需的宽高，但是你需要加入你需要的视图。在通知中使用自定义的布局是大多数音乐播放器实现自定义控件的方式：

    private void showNotification() {
      // Create the base notification (the R.drawable is a reference fo a png file) 创建基本通知（the R.drawable 参考自 png 图片）
      Notification notification = new Notification(R.drawable.stat_notify_missed_call,
          "Ticket text", System.currentTimeMillis());

      // The action you want to perform on click 实现的点击方法
      Intent intent = new Intent(this, Main.class);

      // Holds the intent in waiting until it’s ready to be used  让 intent 等待直到他准备好。
      PendingIntent pi = PendingIntent.getActivity(this, 1, intent, 0);

      // Set the latest event info 设置最后的事件信息
      notification.setLatestEventInfo(this, "Content title", "Content subtext", pi);

      // Get an instance of the notification manager 获取通知manager的实例
      NotificationManager noteManager = (NotificationManager)
          getSystemService(Context.NOTIFICATION_SERVICE);

      // Post to the system bar 发布到系统栏
      noteManager.notify(1, notification);
    }

Code: Function on how notifications were created in 1.5-2.3.

代码：这段是如何在1.5-2.3中实现通知功能。

Android 1.6 中的运行的结果:

![Notifications in Donut 1.6](http://www.objc.io/images/issue-11/gb/donut.png) 

Android 2.3 中的运行结果:

![Notifications in Gingerbread 2.3](http://www.objc.io/images/issue-11/gb/gingerbread_resized.png)


###Android 3.0 - 3.2

Notifications in Android 3.0 actually took a slight turn for the worse. Android’s tablet version, in response to Apple’s iPad, was a fresh take on how to run Android on a large screen. Instead of a single unified drawer, Android tried to make use of its extra space and provide a separate notification experience, one where you still had a drawer, but you would also receive 'growl-like' notifications. Fortunately for developers, this also came with a brand new API, the `NotificationBuilder`, which allowed us to utilize a [builder pattern](http://en.wikipedia.org/wiki/Builder_pattern) to create our notifications. Even though it’s slightly more involved, the builder abstracts away the complexity of creating notification objects that differ ever so slightly with every new version of the operating system:

通知系统在 Android 3.0 上实际有一点退步， Android 平板版本，一个用来对抗 iPad 的版本，是 Android 在大屏幕运行的一次尝鲜。相对于单一的抽屉显示，Android 尝试用额外的控件带来新的通知体验，你依旧有一个抽屉类型的通知，同时你也可以接收 'growl-like' 的通知。幸运的是，同时提供了一个叫做 `NotificationBuilder` 的全新 API，允许我们利用[建造者模式](http://en.wikipedia.org/wiki/Builder_pattern) 去构建我们的通知。尽管略微复杂，但构造器会根据每个新版操作系统的不同来构建复杂的通知对象：

    // The action you want to perform on click 点击方法
    Intent intent = new Intent(this, Main.class);

    // Holds the intent in waiting until it’s ready to be used 让 intent 等待直到他准备好。

    PendingIntent pi = PendingIntent.getActivity(this, 1, intent, 0);

    Notification noti = new Notification.Builder(getContext())
      .setContentTitle("Honeycomb")
      .setContentText("Notifications in Honeycomb")
      .setTicker("Ticker text")
      .setSmallIcon(R.drawable.stat_notify_missed_call)
      .setContentIntent(pi)
      .build();

    // Get an instance of the notification manager 获取通知 manager 的实例
    NotificationManager noteManager = (NotificationManager)
        getSystemService(Context.NOTIFICATION_SERVICE);

    // Post to the system bar 发布到系统栏
    noteManager.notify(1, notification);

通知在 Android 3.2（蜂巢）中初始的样式：

![Honeycomb notifications ticket text](http://www.objc.io/images/issue-11/hc/initially-received-hc.png)


当你在导航栏点击他时候的样式:

![Honeycomb notifications tapping notification](http://www.objc.io/images/issue-11/hc/selecting_notification_hc.png)

当你点击时钟看到的通知的样子:

![Honeycomb notifications tapping clock](http://www.objc.io/images/issue-11/hc/selecting_clock_hc.png)


These redundant notifications led to user confusion about what notifications were representing, and presented many design challenges for the developer, who was trying to get to the right information to the user at the right time.

各种冗余的通知让用户感到困惑不知道它们代表什么，这是对开发人员的一种挑战，如何在恰当的时间返回恰当的信息给用户。

### Finally, 4.0-4.4

As with the rest of the operating system, Android began to really flesh out and unify its notification experience in 4.0 and beyond. While 4.0 in particular didn’t bring anything exciting to the table, 4.1 brought us roll-up notifications (a way to visualize more than one notification in a single cell), expandable notifications (for example, reading the first paragraph of an email), picture notifications, and actionable notifications. Needless to say, this created an entirely new way of enriching a user’s out-of-app experience. If someone ‘friended’ me on Facebook, I could simply press an 'accept friend request' button right from the notification bar, without ever opening the application. If I received an email I didn’t actually have to read, I could archive it immediately without ever opening my email.

与其他系统相比，Android 从4.0开始真正充实和统一通知体验。虽然在4.0没有带来任何激动人心的设计，但是4.1带来一种聚合的通知（一种全新的可视化，让一个cell中可以显示多个通知），可扩展的通知（比如，显示电子邮件的第一段），图片通知，以及可操作的通知。不用说这种提供了一种全新的方式可以带给用户 out-of-app 的体验。如果有人在 Facebook 加我为好友，我可以简单的在通知栏上点击“接受”，再也不用打开 Facebook 应用。如果我收到了一封垃圾邮件，我可以查看，直接归档。

Here are a few examples of the 4.0+ API’s that are utilized in the [Tumblr application for Android](https://play.google.com/store/apps/details?id=com.tumblr). Using these notifications is incredibly simple; it only requires adding an extra notification style onto the `NotificationBuilder`.

这里有一些[Tumblr 应用](https://play.google.com/store/apps/details?id=com.tumblr)利用了一些新的 4.0+ API的例子，使用这些通知非常简单；只需要你加入一些额外的通知风格到 `NotificationBuilder`中。

#### Big Text Notifications 大文本通知

If the text is short enough, why do I have to open the app to read it? Big text solves that problem by giving you some more room to read. No wasted application opens for no reason:

如果文字足够短，还有什么理由让我打开应用来阅读？大文本样式提供了更大的阅读空间来解决这个问题。再也不需要浪费时间打开一个应用

    Notification noti = new Notification.Builder()
      ... // The same notification properties as the others 和之前一样的通知属性设置
      .setStyle(new Notification.BigTextStyle().bigText("theblogofinfinite replied..."))
      .build();

大文本通知折叠:

![Notifications in Cupcake 1.5](http://www.objc.io/images/issue-11/ics/shrunk_text.png)

大文本通知展开:

![Notifications in Cupcake 1.5](http://www.objc.io/images/issue-11/ics/bigtext.png)


#### Big Picture Notifications 大图片通知

These wonderful notifications offer a content-first experience without ever requiring the user to open an application. This provides an immense amount of context, and is a beautiful way to interact with your notifications:

大图片通知提供了内容优先并且无需打开应用的美妙体验。这是一种优雅的方式在你的通知内来展示更多的上下文。

    Notification noti = new Notification.Builder()
      ... // The same notification properties as the others 同之前一样的属性设置方法
      .setStyle(new Notification.BigPictureStyle().bigPicture(mBitmap))
      .build();

![Big picture notification](http://www.objc.io/images/issue-11/ics/big_pic.png)


#### Roll-Up Notifications 聚合通知

Roll-up notification is bringing multiple notifications into one. The rollup cheats a little bit because it doesn’t actually stack existing notifications. You’re still responsible for building it yourself, so really it’s just more of a nice way of presenting it:

聚合通知是将多个通知放在一起，汇总有一点欺骗性因为它实际上并不堆栈现有的通知，你依然可以自己创造他们，所以这真的是一种很好展示通知的方式去：

    Notification noti = new Notification.Builder()
      ... // The same notification properties as the others 和之前一样的属性设置
      .setStyle(new Notification.InboxStyle()
         .addLine("Soandso likes your post")
         .addLine("Soandso reblogged your post")
         .setContentTitle("3 new notes")
         .setSummaryText("+3 more"))
      .build();

![Rollup notification](http://www.objc.io/images/issue-11/ics/rollup.png)


#### Action Notifications 可操作通知

Adding actions to a notification is just as easy as you’d imagine. The builder pattern ensures that it will use whatever default styles are suggested by the system, ensuring that the user always feels at home in his or her notification drawer:

在通知中增加操作就和你想象的一样容易。建造者模式可以确保它能够使用任何系统默认的样式，确保用户总是感觉在使用他或她的通知抽屉：

    Notification noti = new Notification.Builder()
      ... // The same notification properties as the others
      .addAction(R.drawable.ic_person, "Visit blog", mPendingBlogIntent)
      .addAction(R.drawable.ic_follow, "Follow", mPendingFollowIntent)
      .build();

![Action notification](http://www.objc.io/images/issue-11/ics/actions.png)

These sorts of interactions lent to an application design that put the user in charge, and made performing simple actions incredibly easier, and faster. At a time when Android had suffered from sluggish performance, these sorts of quick actions were greatly welcomed, since you didn’t actually have to open an application to still be able to use it.

这类交互是一种对用户负责的设计，并且操作简单快速，受限于 Android 的缓慢性能，这种快捷打开的方式非常受欢迎，因为你实际上不需要打开应用就可以使用它。


### Android Wear Android 穿戴设备

It’s no secret to anyone in the tech world right now that Android wear is a fascinating introduction into the wearables space. Whether or not it will succeed as a consumer product is certainly up for debate. What isn’t up for debate is the barrier to entry for developers who want to support Android Wear. Living up to its legacy, Android Wear appears to have gotten notifications correct, in regards to syncing with your device. As a matter of fact, if you phone is connected to an Android Wear device, it will push any notifications created with a builder directly to the device, with no code modification necessary. The ongoing simplicity of the `NotificationBuilder` pattern will ensure that whatever devices that come out and support Android or Android Wear will almost immediately have an breadth of app developers who are already comfortable using the APIs to send and receive data.

现在的科技圈对于任何一个人来说都已经不再像之前那么神秘，正因如此 Android 可穿戴设备也成为了科技设备中的一份子。它是否能够成功的成为一类消费品这件事情似乎仍然有待商榷，但是对于那些想要支持 Android 穿戴设备的开发者来说，仍然有很多障碍是不容忽视的存在着。没有辜负 Android 系统传承下来的一些优势，其穿戴设备在与你的设备进行同步的时候似乎总可以接受正确的通知。但事实上，你的手机与 Android 穿戴设备连接后，它将会在没有代码修改的情况下对设备推送构造器创建的通知。能够简单使用建造者模式则意味着无论出现什么设备，只要他们能够支持 Android 系统和 Android 可穿戴设备，立即会有大量熟练使用API来收发数据的应用开发者出现。

<img style="display:inline;" alt="Action notification" src="http://www.objc.io/images/issue-11/watch/picture.png" width="40%">
<img style="display:inline;margin-left:1em;" alt="Action notification" src="http://www.objc.io/images/issue-11/watch/hunkosis.png" width="40%">

NotificationBuilder provides out-of-the-box support for Android Wear, no code required!

NotificationBuilder 提供了 out-of-the-box 的 android 穿戴设备支持，不用写任何额外的代码！

## Custom Notifications 自定义通知布局

Even though Android’s `NotificationBuilder` provides an enormous level of customizability, sometimes that just isn’t enough, and that's where custom notification layouts come in. It’s hard to imagine what you would do if you had complete control over a notification. How would you change it, what would it really do beyond a normal notification? Thinking creatively within these constraints can be difficult, but many Android developers have stepped up to the plate.

虽然 Android 的 `NotificationBuilder` 支持高自由度定制，但有的时候依然无法满足人们的需求，这就是为何要引入自定义通知布局。很难想想当你拥有全部的通知系统的控制权限的时候。你将如何改变它，让它与众不同? 在诸多约束的情况下不断创新着实很难，但是许多 Android 开发者已经开始迎难而上。

自定义音乐播放器通知:

![Custom music player notification](http://www.objc.io/images/issue-11/custom/music_player.png) 

自定义天气通知:

![Custom weather notification](http://www.objc.io/images/issue-11/custom/weather.jpg) 

自定义电量通知:

![Custom battery notification](http://www.objc.io/images/issue-11/custom/battery_widget.png)

Custom notifications are limited to a subset of view components that are supported by [Remote Views](http://developer.android.com/reference/android/widget/RemoteViews.html), and those view components themselves cannot be extended or overridden too heavily. Regardless of this slight limitation, you can see that you can still create sophisticated notifications using these basic components.

自定义通知仅限于视图组件所支持[远程视图](http://developer.android.com/reference/android/widget/RemoteViews.html)的一个子集，这些视图组件本身不能不能高度延伸或者被覆盖。虽然只能轻度定制，但是你依然可以利用基本组件构造复杂的通知。

Creating these custom views takes a bit more work however. Custom notification views are created using Android's XML layout system, and you are responsible for making sure your notifications look decent on all the different versions of Android. It’s a pain, but when you see see some of these beautiful notifications, you can instantly understand their value:

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
    
An extremely basic custom-notification layout that shows an image, with some text beside it.

这是一个非常基本的自定义通知布局，包含一张图片以及一段文字。

## Notification Behavior 通知行为

### Push Notifications 推送通知

Now that we’ve had our extensive history lesson, let's get into some interesting behavior about how notifications work. As it might be apparent from the information we’ve already covered, developers have *complete* control over this notification system. That means notifications can be shown or dismissed at any time, for any reason. There is no need for this notification to be received from Google through a push notification service. In fact, even when receiving push notifications, they aren’t just shown in the status bar by default -- you have to catch that push notification and decide what to do with it.

现在我们已经有了大量的历史教训，让我们看一些关于通知是如何工作的有趣行为。也许这部分内容我们已经提及，开发者可以
*完全*控制通知系统。以及就是说通知可以因为任何原因在任何时候显示或者消失。甚至不需要从 Google 推送服务接收一个通知。实际上，就算我们收到一个推送通知，它默认也不会显示在状态栏，你需要自己去捕捉推送通知并且决定如何去处理它。

For example, a common notification interaction looks like this:

举例来说，一个常规的通知交互应该是这个样子：

1. Receive push notification from remote server
2. Inspect payload, fire off a background service to fetch data instructed by payload
3. Receive / parse response
4. Build and show notification

1. 接收远程推送通知
2. 检查 payload，根据 payload 建立一个后台服务去获取数据。
3. 获取并解析返回的数据
4. 构建并显示通知


What is interesting, however, is that for steps two and three, there is no time limit that is imposed on this background service. If the push notification told you to download a 1GB file, then that's OK! For most use cases, there is no requirement by the system to show you relatively short running services in the background. Long-running background services (think music player), however, do require an icon to be shown in the status bar. This was great forethought from the Android engineers to make sure that the user would know about anything that was doing background work for too long.

比较有趣的是第二步和第三步，后台服务没有时间限制。如果推送通知告诉你要下载 1GB 的文件，好吧无所谓！在大多数情况下，系统没有要求你必须显示一个通知如果它用时非常短。长时间后台服务（比如音乐播放器）依旧需要在状态栏显示一个图标。对于开发者来说这是一种深谋远虑的做法，确保用户知道是何种服务在后台长时间运行。

But even these four steps are more than an average developer would like to handle. Wouldn’t it be great if you could just send the whole payload? [GCM (Google Cloud Messaging)](http://developer.android.com/google/gcm/index.html) allows payloads of up to 4KB. On average, that's between 1,024 and 4,096 UTF-8 characters (depending on the characters). Unless you're pushing down images, you could probably fit whatever you wanted into a single push. Sounds great!

虽然只有4个步骤但是多数开发者不愿意处理。如果我可以直接发送整个 payload 是不是会更简洁？[GCM (Google Cloud Messaging)](http://developer.android.com/google/gcm/index.html) 允许 payloads 控制在 4KB 之内，平均来说，它在 1,024 到 4,096 UTF-8 字符之间（取决于字符）。 除非你要推送一张图片，不然你可以塞入任何你想要的内容。听起来真棒！

### Notification Callbacks 通知回调

So what kind of control do we have as developers over how the user is interacting with the notifications? Sure, we’ve seen that there is a possibility to add custom controls and buttons onto them, and we’ve already seen how to interact with a general click, but is there anything else? Actually, there is! There is a 'delete' action, `setDeleteIntent`, that gets fired when the user dismisses the notification from the drawer. Hooking into delete is a great way to make sure we don’t ever show the user this information again:

那么开发人员是如何控制用户与通知之间的互动，当然，我们已经知道可以添加自定义控件和按钮，而且我们已经看到了如何实现一般的点击？但还有其他的么？实际上，有！有一个“删除”功能，当用户设置 `setDeleteIntent`，用户从抽屉中删除通知的时候将被逻辑删除。加入删除是一个伟大的进步，以确保我们不再次显示老旧信息:

    // In Android, we can create arbitrary names of actions, and let
    // individual components decide if they want to receive these actions.
    
    // 在 Android 中，我们可以创建任意名字让组件决定它们想要处理哪种操作
    
    Intent clearIntent = new Intent("clear_all_notifications");
    PendingIntent clearNotesFromDb = PendingIntent.getBroadcast(aContext, 1, clearIntent, 0)

    Notification noti = new Notification.Builder(getContext())
      ...
      .setDeleteIntent(clearNotesFromDb)
      .build();

### Recreating the Navigation Hierarchy 重建导航层次结构

Let’s talk a little more about the default notification click. Now, you could certainly perform some sort of default behavior when clicking on a notification. You could just open the application, and be done with it. The user can figure out where to go from there. But it would be so much nicer if we opened up directly to the relevant screen. If we receive an email notification, let's jump directly to that email. If one of my friends checks in on Foursquare, let's open right to that restaurant and see where he or she is. This is a great feature because it allows your notifications to act as deep links into the content that they are referring to. But often, when deep linking into these parts of your application, you run into a problem where your navigation hierarchy is all out of order. You have no way of actually navigating 'back.' Android helps you solve this problem by allowing you to create a stack of screens before you start anything. This is accomplished via the help of the TaskStackBuilder class. Using it is a little magical and requires some prior knowledge to how applications are structured, but feel free to take a look at Google’s developer site for a
[brief implementation](http://developer.android.com/guide/topics/ui/notifiers/notifications.html#SimpleNotification).

让我们更深入的谈一谈通知的默认点击。现在你当然可以在点击通知后执行一些默认的行为。你可以仅仅打开那你的应用。用户可以自己找到他们想要去的页面。但是如果我们可以直接显示相关的页面那么会更加友好。如果我们收到一个邮件通知，我们直接跳转到邮件内容，如果我们的一个朋友在 Foursquare 上签到，我们直接可以打开应用显示这个他或者她所在的餐馆。这是一个很棒的功能因为它允许通知指向到一个包含内容的深度链接。但是更多时候，深度链接已经是你应用的一部分，你会遇到导航层次混乱的问题。你无法使用导航’返回‘。 Android 帮助你在开始之前创建视图堆栈来解决这个问题。这是通过 TaskStackBuilder 类来完成的。使用这个技术需要一些魔法并且需要一些应用架构方面的知识，但是有空你可以看看 Google 开发者网站，这里有一个[简要实现](http://developer.android.com/guide/topics/ui/notifiers/notifications.html#SimpleNotification).

For our Gmail example, instead of just telling our application that we want to open an email, we tell it, "Open the email app, and then open this specific email." The user will never see all of the screens being created; instead, he or she will only see the end result. This is fantastic, because now, when selecting back, the user doesn’t leave the application. He or she simply ends up returning to the apps home screen.

用 Gmail 举例，我们告诉应用 "打开邮件应用，接着打开一份指定的邮件。" 来代替简单的打开邮件应用。用户将不会看到所有的视图创建，替换，他或者她只会看到最终的结果。这是多么的不可思议，因为现在我们点击返回按钮的时候，用户将不会退出应用，他或者她只会退到应用的首页。


## What’s Missing 忽略了什么

I’ve detailed quite a bit about what notifications in Android have to offer, and I’ve even demonstrated how powerful they can be. But no system is perfect, and Android’s notification system is not without its shortcomings.

我已经详细罗列了许多 Android 系统中通知的功能，同时也展示了它们有多么的强大。但是没有哪个系统是完美的，Android的通知系统也有瑕疵。

### Standards 标准

One of the unfortunate problems Android users face is that there is no centralized control for how notifications work. This means that if there is an application prompting you with a notification, short of uninstalling the application, there isn’t much you can do. Starting in Android 4.1, users received a buried binary setting to 'Turn off notifications' for a specific app. This prevents this application from placing *any* notification in the status bar. While it may seem helpful, the user case is actually fairly limited, since rarely do you want to disable all of an application's notifications completely, but rather a single element of it, for instance the LED or the annoying sound.

Android 用户面临的首要问题之一则是通知系统工作时没有集中控制的功能。这就意味着如果一个应用有通知提示的时候，用户没法关闭它，唯有卸载这个应用。从 Android 4.1 开始，用户可以在设置中选择关掉指定程序的通知。这阻止了应用在状态栏的*所有*通知，这样看起来是十分有用的功能，用户所需的东西的相当有限的，其实很少有人会将所有的应用通知全部关闭，除非一些令人恼火的原因，比如LED提示灯或者是不停发出的提示音。

![Turn off notifications](http://www.objc.io/images/issue-11/disable_notifications.png)
Starting in Android 4.1, users received a binary setting to 'Turn off notifications,' but there is still no centralized way to disable LEDs or sounds unless provided explicitly by the developer.

从 Android 4.1 开始，用户可以通过设置来关闭接收通知，但是这里没有一种方式来关闭 LEDs 或者声音除非开发者提供了关闭的方法。

### What to Display 显示什么

You might think that we’re taking for granted all of the control that we have over notifications already, but certainly there is always room for more. While the current system offers a lot of functionality and customizability, I’d like to see it taken a step further. The `NotificationBuilder`, as we saw earlier, forces your notification into a certain structure that encourages all notifications to look and feel the same. And if you use a custom layout and build the notification yourself, there are only a handful of supported components that you are allowed to use. If you have a complex component that needs to be custom drawn, it’s probably safe to assume that you can’t do it. And if you wanted to do something next level, like incorporating frame animations, or even a video, forget about it.

你也许认为我们已经将通知功能基本掌握了，但其实我们仍然有很大的进步空间。尽管现有的系统已经具备了一定的个性化定制功能，但我仍然希望看到它能够更上一层楼。正如早些时候我们看到的，`NotificationBuilder` 使你的通知形成一个特定的样子，也就是所有的系统通知都是一样的。若果你使用用户布局并且建立自己的通知模式，那就只有一少部分支持组建来供你使用。如果有很复杂的组件需要定制，那出于安全考虑你的想法很有可能无法实现。如果你想做一些更高级的功能，比如帧动画，或者一个视频，请忘了它吧。

## Wrapping Up 结语

Android has quite a bit to offer its users and developers in terms of notifications. Right from the get-go, Android made a conscious effort to support notifications in a big and bold way, something that remains unrivaled, even today. Looking at how Android has approached Android Wear, it’s easy to see that there is a huge emphasis on easily accessible APIs for working with the notification manager. While there are some shortcomings around fine-grained notification management and lack of complete UI control, it’s seemingly safe to say that if you are looking for a notifications-first ecosystem, Android might be worth a shot.

Android 提供了给用户和开发者不少通知方面的功能。从一开始，Android 有意识的朝着更大胆的方向努力，即使从今天看来它依旧无以伦比。看看前进中的 Android 以及 Android 穿戴设备，很容易发现，有一个重点强调方便的 API 来处理通知管理。虽然在细粒度的通知管理缺乏完整的UI控件方面有一些缺点，但是谨慎的说，如果你正在寻找一个通知优先的生态系统， Android 或许值得一试。

#### References 引用

- [Android 简史](http://www.theverge.com/2011/12/7/2585779/android-history)
- [Android 通知文档](http://developer.android.com/guide/topics/ui/notifiers/notifications.html)
- [为 Android 穿戴设备创建通知](http://developer.android.com/wear/notifications/creating.html)

[话题 #11 下的更多文章][1]

   [1]: http://objccn.io/issue-11
   
原文 [Android’s Notification Center](http://www.objc.io/issue-11/android-notifications.html)

