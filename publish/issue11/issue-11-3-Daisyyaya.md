## 引言

开发一款移动应用是一个创造性的过程。你一定会想要创作一款这样的应用，它美观实用，它在任何设备上都能运行流畅，它让用户觉得赏心悦目，它让自己引以为傲，下面我就会告诉你我是如何创作具有这些特性的安卓应用的。

对于安卓开发存在一个普遍的误解，那就是安卓设备尺寸的多样性使得开发出具有上述特性的应用变得十分棘手。 你肯定已经看过《安卓可视化碎片》这篇文章了( [Android Fragmentation Visualized](http://opensignal.com/reports/fragmentation.php))，文章列举出了惊人数目的不同安卓设备.

事实上，你确实需要在设计上花费很多心思，但绝对不必比在其他平台上花费得多。安卓开发者拥有高性能的工具去应对设备配置的多样性，并确保应用在所有设备上都能完美运行。

在这篇文章中，我主要会涉及三方面的内容，它们包括：安卓设备多样性的三个方面，以及这种多样性是如何影响开发的，还有安卓应用的设计。我会从一个较高的层次并从 iOS 开发者角度来谈论这些内容：

* 安卓开发者是怎样针对屏幕尺寸的微小差异进行优化的? 怎样处理不同设备的宽高差异? 
* 安卓开发者是怎样考虑屏幕密度差异（screen density variations）问题的?
* 应用怎样才能够被优化去适应不同的设备? 怎样才能制作一款在手机和平板上都完美运行的应用呢? 

## 屏幕尺寸 (Screen Size)

我们首先回顾一下 iOS 设备的屏幕尺寸。实际上有三种: 3.5 英寸 iPhone，4 英寸 iPhone，以及 iPad。尽管 iPad mini 比 iPad 小，但从开发者角度，这仅仅只是按比例缩小了。对许多应用来说，3.5 英寸和 4 英寸的设备屏幕尺寸的差别几乎没有影响，因为仅仅只是高度改变了。

iOS 绘画系统使用点（points）而不是像素（pixels），因此屏幕是否是视网膜屏不会影响页面布局。页面布局或是静态的 (针对每种设备用编程方式设计精确到点，或者使用设备相应的 xib 文件) 或动态的 (使用自动布局 Auto Layout 或者自适应 Autoresizing Masks)。

相比之下，在安卓平台上，有数量惊人的不同尺寸的屏幕需要支持。安卓开发者们是如何确保他们的应用在所有设备上都运行流畅呢？ 

在许多方面，安卓设计和网页设计很相似。网页设计必须支持任何可能存在的浏览器尺寸。类似的，安卓应用设计是建立在预期了屏幕尺寸改变的前提下的。我们设计的视图能够按照自身限制条件自动填充空间和内容。

既然你在设计时必须将不同的屏幕尺寸都考虑到，那么支持设备横屏也理所应当需要被考虑。当一款应用需要支持任何尺寸的屏幕大小时，横向仅仅就只是设备的一项附加配置。

### 布局文件

让我们深入到布局系统的更多细节中。布局文件是描述用户界面的 XML 文件。

如下图所示，我们创建了一个布局文件样本。这个文件被用作应用的登录视图: 

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

<img src="/images/issues/issue-11/image02.png" width="470"> 

<img style="margin-top:1em;" src="/images/issues/issue-11/image01.png">

在上面的布局文件中，`线性布局 LinearLayout` 被用来线性排列 `视图Views`。我们实例化了 `线性布局`中的三个视图: 一个用户名 `EditText`，一个密码 `EditText`，和一个登录按钮。

需要注意的是在布局文件中的每个视图的宽 `layout_width` 和高 `layout_height` 。这些属性被用来设置视图的具体宽高。我们使用两个常量来设置每个属性: `wrap_content` 和 `match_parent`。如果用 `wrap_content` 来设置视图的高度，那么那个视图会根据它需要呈现的内容调整至相应高度。如果用 `match_parent` 来设置视图的宽，那么那个视图会和它的父视图一样宽。

通过使用 `wrap_content` 和 `match_parent` 的值，我们设计了一款可以自动伸缩去适应任何屏幕的视图。

和 iOS 最重要的区别在于，布局 XML 文件和在其中设置的视图并未设置大小。事实上，在布局文件的视图被放置到屏幕上之前，并没有被设置任何大小相关联的值。

## 屏幕密度 (Screen Density)

安卓开发中视图可变性的另一个影响因素是屏幕密度。你怎样才能编写一款可以适应不同密度屏幕的应用的呢？

你应该知道，iOS 开发里会考虑到两种屏幕: 普通屏幕和 Retina 屏幕。如果文件名里 `@2x` 后缀被使用，系统会自动根据设备种类选择合适的图像。

安卓应用屏幕密度适配的原理和 iOS 相似，但是可变性更强。不同于 iOS 有两个图片容器 (image buckets)，安卓开发者有很多。我们标准的图片容器大小是 `mdpi` (Median Dots Per Inch)，或者称作中密度。这个 `mdpi` 容器和普通的iOS图片尺寸一致。然后，`hdpi` (High Dots Per Inch)，或者高密度，是中密度 `mdpi` 的 1.5 倍。最后，`xhdpi` (Extra High Dots Per Inch)，或称为超高密度，是普通尺寸的 2 倍，这和 iOS 的 Retina 高清屏尺寸一致。安卓还能利用其它的图像容器，包含 `xxhdpi` 和 `xxxhdpi`。

## 资源选定 (Resource Qualifiers)

我们对增添多种图片尺寸似乎无计可施，但是安卓使用了一种健壮的资源选定系统来挑选具体应该使用的资源。

下面，将介绍一个关于资源选定如何处理图片的例子。在一个安卓项目中，有一个 `res` 文件夹，这里放置 app 所要使用的所有资源。包含图片，以及布局文件，还有一些其他项目资源。

<img src="/images/issues/issue-11/image00.png" width="187">

这里，`ic_launcher.png` 图片重复出现在下面三个文件夹: `drawable-hdpi`，`drawable-mdpi`，和 `drawable-xhdpi`。当请求名为 `ic_launcher` 的图片时，系统运行时会根据设备配置自动选择适应的图片.

这能让我们根据不同屏幕尺寸最优化图片，但是重复存储的图片势必浪费资源。

这些屏幕密度就是模糊限制因素 (fuzzy qualifiers)。如果你使用和上面的例子中的带有 `xxhdpi` 屏幕的设备，系统将自动选择 `xhdpi` 版本的图像然后根据屏幕密度缩放图片。这种特性允许我们只须创建一个版本的图像就可以按需为其他密度的屏幕优化。

一个普遍模型是提供高密度的图片，然后让安卓去将图像缩小，以适应低屏幕密度的设备。

## 密度独立像素 (DIPs)

应对屏幕密度变化做出的最后调整是在布局文件里设置准确的尺寸。想像你希望你的应用支持屏幕外部填充。我们怎样设置元素值使得视图能够根据不同设备自动匹配屏幕密度?

好吧，iOS 开发者可以将这样的填充精确至像素点。在非 Retina 屏设备上，原像素值会被使用，而在 Retina 设备上，系统会自动 double 该像素值。

在安卓上，你也可以以原像素点为单位设置图像填充，但是那些值不会缩放以适用于高密度屏幕的设备。相反的，安卓开发者会设置在密度独立像素里的测量单元 (通常被称作密度独立像素，或者设备像素单元)。这些单元会像 iOS 自适应大小一样 根据设备密度自动做出缩放调整。

## 设备种类

最后需要考虑的一点是在安卓开发中不同种类的设备是怎样被管理的。值得注意的是 iOS 有两个独立的类: iPhone 和 iPad。但是，安卓截然不同，因为安卓拥有一系列不同的种类，而且手机和平板之间的差别可以是任意的。先前提到的资源选定体系被重度使用来支持这一范围的屏幕尺寸变化。

对于简单屏幕，它们可以基于设备大小尺寸并根据内容调整填充。例如，我们可以检验一下维度资源 (dimension resources).我们可以在一个普通的位置定义一个维度值并在我们的布局文件中引用它：

    <?xml version="1.0" encoding="utf-8"?>
    <LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_margin="@dimen/container_margin" >
        ...
    </LinearLayout>

注意 `@dimen/container_margin` 的值。这代表了一个存储在资源系统中的被命名值。我们能够定义一个基本的边距属性值作为默认值:

在 `res/values/dimens.xml` 里：

    <resouces>
	    <dimen name=”container_margin”>4dp</dimen>
    </resources>

然后，我们为平板创建一个合格版本的填充：

在 `res/values-w600dp/dimens.xml` 中：

    <resouces>
       <dimen name=”container_margin”>96dp</dimen>
    </resources>

现在，在宽度至少有 600 个设备点单元的设备上，较大的容器边缘间距值会被系统选择。这个多出来的边界可以调整我们的用户界面，这样一来，这款在手机上表现良好的应用，现在在平板上就不只是一个简单的拉伸版本而已了。

## 分割视图

上面的尺寸实例在某些情况下是一个很实用的工具，但是，常常会出现一种情况，那就是由于平板尺寸较大，有了放置额外的应用组件的空间，所以应用可以变得更为有用。

在 iOS 应用中，一个通常的方式是使用一个分离的视图控制器。UISplitViewController 允许你控制两个视图控制器，并将它们同时显示在 iPad 应用的一个屏幕上。

在安卓上，我们有一个相似的系统，但却可以有更多的控制和更多的选择用于扩展。你的应用的核心部件可以被分为可重用的部分，就是 fragments，类似于 iOS 里面的视图控制器。所有应用里的任一个单屏幕的控制逻辑都能够被以一个 fragment 的形式呈现出来。当在手机上的时候，我们向用户呈现一个 fragment。当在平板上时，我们可以向用户呈现两个 (或更多的) fragments。

我们可以再次依赖资源选定系统为手机或者平板供应一个独特的布局文件，这将允许我们在平板上控制两个 fragment，而在手机上控制一个。

例如，下面定义的布局文件会被用在手机设备上：

在 `res/layout/activity_home.xml` 中：

    <?xml version="1.0" encoding="utf-8"?>
    <FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
        android:id="@+id/container"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />

这个被 `container` ID 定义的 `FrameLayout` 会包含我们应用的主视图，并且会为其提供主 fragment 作为容器。

我们可以为平板设备创建这个文件的对应的版本：

在 `res/layout-sw600dp/activity_home.xml` 中：

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

现在，当我们在平板设备上使用 activity_home 布局文件时，我们会有两个窗口，而不是一个，这意味着我们能够支配两个 fragment 视图。我们现在可以几乎不用修改代码就能在一个屏幕上呈现主视图和详情视图。在运行时候，系统会根据设备的配置决定布局文件的使用版本。

## 结论

除了 `sw600dp` 资源选定以外，这篇文章提到的所有工具都可以供任何你支持的任何安卓设备使用。其实有一种在 `sw600dp` 加入之前就存在的更老，粒度更小的资源选定方式，一般用于那些更早的的设备上。

正如上面所示，安卓开发者拥有适用于任何设备的优化工具。你会发现一些安卓应用在许多设备上并不非常适合 (这种情况其实蛮常见)。我想要强调的是 从已有平台上把设计从既存的平台上强塞到安卓里这种行为其实并不合适。我强烈建议你重新思考一下你的设计并为你的用户提供一种更愉悦的体验.

---

 
   
原文 [Responsive Android Applications](http://www.objc.io/issue-11/responsive-android-applications.html)