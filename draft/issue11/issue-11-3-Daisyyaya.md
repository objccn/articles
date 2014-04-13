---
layout: post
title:  "响应式安卓应用"
category: "11"
date: "2014-04-01 09:00:00"
tags: article
author: "<a href=\"https://twitter.com/Cstew\">Chris Stewart</a>"
---

## 引言

开发一款移动应用是一个创造性的过程.若你想要创作或美观实用的,或在任何设备上都运行流畅的,或让用户赏心悦目的,或让自己引以为傲的作品, 下面我会告诉你我是如何创作具有这些特性的安卓应用的. 

对于安卓开发存在一个普遍的误解, 那就是安卓设备尺寸的多样性使得开发出具有上述特性的应用变得十分棘手.  你肯定已经看过《安卓可视化碎片》这篇文章了([Android Fragmentation Visualized](http://opensignal.com/reports/fragmentation.php)), 文章列举出了惊人数目的不同安卓设备.

事实上, 你需要在设计上花费很多心思, 但绝对不必比在其他设备上花费的多. 安卓开发者拥有高性能的工具去应对设备配置（device configuration）的多样性，并确保应用在所有设备上都能完美运行. 

在这篇文章中, 我主要讲了安卓设备多样性的三个方面，以及这种多样性是如何影响开发的，还有安卓应用的设计这三方面内容. 我会从一个较高的层次并从iOS开发者角度来谈论这些内容: 

* 安卓开发者是怎样针对屏幕尺寸的微小差异进行优化的? 怎样处理不同设备的宽高差异? 
* 安卓开发者是怎样考虑屏幕密度差异（screen density variations）问题的?
* 应用怎样才能够被优化去适应不同的设备? 怎样才能制作一款在手机和平板上都完美运行的应用呢? 

## 屏幕尺寸 (Screen Size)

我们首先回顾一下iOS设备的屏幕尺寸. 实际上有三种: 3.5-英寸 iPhone, 4-英寸 iPhone, and iPad. 尽管, 当然, iPad mini比iPad小, 但从开发者角度, 这仅仅只是按比例缩小了. 对许多应用来说, 3.5-英寸和4-英寸的设备屏幕尺寸的差别几乎没有影响, 因为仅仅只是高度改变了.

iOS 绘画系统使用点（points）而不是像素（pixels）, 因此屏幕是否是视网膜屏不会影响页面布局. 页面布局或是静态的 (针对每种设备用编程方式设计精确到点, 或者使用设备相应的xib文件) 或动态的(使用自动布局Auto Layout或者自适应Autoresizing Masks).

相比之下, 在安卓平台上, 有数量惊人的不同尺寸的屏幕需要支持. 安卓开发者们是如何确保他们的应用在所有设备上都运行流畅呢? 

在许多方面, 安卓设计和网页设计很相似. 网页设计必须支持任何可能存在的浏览器尺寸. 类似的, 安卓应用设计是建立在预期了屏幕尺寸改变的前提下的. 我们设计的视图能够按照自身限制条件自动填充空间和内容.

既然你在设计时必须将不同的屏幕尺寸都考虑到, 那么支持设备横屏也理所应当需要被考虑. 当一款应用需要支持任何尺寸的屏幕大小时, 横向仅仅就只是设备的一项附加配置. 

### 布局文件

让我们深入到布局系统的更多细节中. 布局文件是描述用户接口的XML文件. 

如下图所示, 我们创建了一个布局文件样本. 这个文件被用作应用的登录视图: 

    <?xml version="1.0" encoding="utf-8"?>
    <LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
                  android:orientation="vertical"
                  android:layout_width="match_parent"
                  android:layout_height="match_parent"
                  android:padding="14dp">
        <EditText
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:hint="username"/>
        <EditText
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:hint="password"/>
        <Button
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:hint="Login"/>
    </LinearLayout>

<img src="{{ site.images_path }}/issue-11/image02.png" width="470"> 

<img style="margin-top:1em;" src="{{ site.images_path }}/issue-11/image01.png">

在上面的布局文件中, `线性布局LinearLayout` 被用来线性排列 `视图Views`. 我们实例化了 `线性布局LinearLayout`中的三个视图: 一个用户名 `EditText`, 一个密码 `EditText`, 和一个登录按钮. 

需要注意的是在布局文件中的每个视图的宽 `layout_width` 和高 `layout_height` . 这些属性被用来设置视图的具体宽高. 我们使用两个常量来设置每个属性: `wrap_content` and `match_parent`. 如果用 `wrap_content` 来设置视图的高度, 那么那个视图会根据它需要呈现的内容调整至相应高度. 如果用 `match_parent` 来设置视图的宽, 那么那个视图会和它的父视图一样宽. 

通过使用 `wrap_content` 和 `match_parent` 的值, 我们设计了一款可以自动伸缩去适应任何屏幕的视图. 

和iOS最重要的区别在于, 布局XML文件和在其中设置的视图并未设置大小. 事实上, 在布局文件的视图被放置到屏幕上之前, 并没有被设置任何大小相关联的值.

## 屏幕密度 (Screen Density)

Another aspect of variability in Views on Android is screen density. How do you write an app that works on any density screen?

As you know, iOS developers are concerned with two sizes: normal and retina. If the `@2x` suffix on the filename is used, the system will automatically choose the appropriate image, depending on the device. 

Android screen density works in a similar way but with more variability. Rather than two image buckets, Android developers have many. Our standard image bucket size is `mdpi`, or medium dpi. This `mdpi` bucket is the same as iOS’s normal image size. Then, `hdpi`, or high dpi, is 1.5 times the size of `mdpi`. Finally, `xhdpi`, or extra high dpi, is 2 times the normal size, the same as iOS’s retina size. Android developers can take advantage of other image buckets, including `xxhdpi` and `xxxhdpi`.

## 资源管理器 (Resource Qualifiers)

The addition of many buckets may seem overwhelming, but Android makes use of a robust resource qualification system to specify how a particular resource can be used. 

Below, you see an example of resource qualifiers for images. In an Android project, we have a `res` folder, which is where we store any resources that the app is going to use. This includes images, but also our layout files, as well as a few other project resources. 

<img src="{{ site.images_path }}/issue-11/image00.png" width="187">

Here, `ic_launcher.png` is duplicated in the following three folders: `drawable-hdpi`, `drawable-mdpi`, and `drawable-xhdpi`. We can ask for the image named `ic_launcher` and the system will automatically choose the appropriate image at runtime, depending on the device configuration.

This allows us to optimize these images for multiple screen sizes but can be somewhat wasteful since the image will be duplicated multiple times. 

These screen density buckets are fuzzy qualifiers. If you’re using a device with an `xxhdpi` screen in the example above, the system will automatically choose the `xhdpi` version of the image and scale the image for your screen density. This feature allows us to create one version of our images and optimize them for other screen densities as needed. 

A common pattern is to supply a high density image and allow Android to downscale that image for devices with a lower screen density. 

## 设备独立像素(DIPs)

One final adjustment to consider for screen density variation is specification of exact dimensions in your layout files. Imagine that you want to supply padding to the outside of a screen in your app. How can we specify dimension values that also scale relative to the device’s screen density?

Well, iOS developers would specify this padding in point values. On a non-retina device, the raw pixel value would be used, and on retina devices, the system will automatically double that pixel size. 

On Android, you can specify this padding in raw pixel values as well, but those values will not scale on devices with high-density screens. Instead, Android developers specify dimension units in density-independent pixels (typically called dip, or dp units). These units will scale relative to the device's density in the same way that iOS automatically performs the scaling. 

## 设备种类(Device Category)

A final detail to consider is how device categories are managed on Android. Note that iOS has two distinct categories: iPhone and iPad. However, Android is very different, as it has a spectrum of device categories, and the distinction between a phone and tablet can be arbitrary. The resource qualification system mentioned earlier is used heavily to support this spectrum of screen sizes. 

For simple screens, padding can be adjusted around content, based on the size of the device. For example, let’s examine dimension resources. We can define a dimension value in a common location and reference it in our layout files: 

    <?xml version="1.0" encoding="utf-8"?>
    <LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_margin="@dimen/container_margin" >
        ...
    </LinearLayout>

Notice the `@dimen/container_margin` value. This refers to a named value stored in the resources system. We can define a base margin-dimension value that is used by default:

In `res/values/dimens.xml`:

    <resouces>
	    <dimen name=”container_margin”>4dp</dimen>
    </resources>

Then, we create a qualified version of this padding for tablets:

In `res/values-w600dp/dimens.xml`:

    <resouces>
       <dimen name=”container_margin”>96dp</dimen>
    </resources>

Now, on devices that have a minimum width of 600 dp units, the larger container margin value will be selected by the system. This additional margin will tweak our user interface so that the app is not just a stretched-out version of the application that looks great on phones.

## 分割检视 (Split Views)

The above dimension example is a useful tool for some situations, but it is often the case that an application will become more useful on a tablet because there is more space for additional application components. 

A common pattern in universal iOS applications is the use of a split view controller. UISplitViewController allows you to host two view controllers that would typically each be visible by themselves in a single screen of your app on an iPad. 

On Android, we have a similar system, but with more control and additional options for expansion. Core pieces of your application can be abstracted into reusable components called fragments, which are similar to view controllers in iOS. All of the controller logic for a single screen of your application can be specified in a fragment. When on a phone, we present one fragment to the user. When on a tablet, we can present two (or more) fragments to the user. 

We can rely again on the resource qualification system to supply a distinct layout file for phones and tablets, which will allow us to host two fragments on a tablet and one on a phone. 

For example, the layout file defined below is intended to be used on phone devices:

In `res/layout/activity_home.xml`:

    <?xml version="1.0" encoding="utf-8"?>
    <FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
        android:id="@+id/container"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />

This `FrameLayout` defined by the `container` ID will contain the master view for our application and will host the view for our master fragment. 

We can create a qualified version of this same file for tablet devices: 

In `res/layout-sw600dp/activity_home.xml`:

    <?xml version="1.0" encoding="utf-8"?>
    <LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
        android:orientation="horizontal"
        android:layout_width="match_parent"
        android:layout_height="match_parent">
    		<FrameLayout 
    	    android:id="@+id/container"
    	    android:layout_width="250dp"
    	    android:layout_height="match_parent" />
    		<FrameLayout 
    	    android:id="@+id/detail_container"
    	    android:layout_weight="1"
    	    android:layout_width="0dp"
    	    android:layout_height="match_parent" />
    	</LinearLayout>

Now, when we use the activity_home layout file on a tablet, we will have two panes in our layout instead of one, which means we can host two fragment views. We can now display the master and the detail view in the same screen with very little code modification. At runtime, the system will decide which version of the layout file to use based on the configuration of the device. 

## 结论

With the exception of the `sw600dp` resource qualifier, all of the tools in this article are available on any Android device that you would support. There is an older and less granular resource qualifier that existed prior to the addition of `sw600dp`, available for those older devices. 

As described above, Android developers have the tools needed to optimize for any type of device. You will see some Android applications that don’t adapt very well to many devices (I wouldn’t call this uncommon). I want to stress that shoehorning a design from an existing platform just won’t work on Android. I challenge you to rethink your design and provide a delightful experience for your users.
