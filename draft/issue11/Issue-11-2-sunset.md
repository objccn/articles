---
layout: post
title:  "Android Intents"
category: "11"
date: "2014-04-01 10:00:00"
tags: article
author: "<a href=\"https://twitter.com/Gryzor\">Martin Marconcini</a>"
---


## Introduction

Perhaps a very distinctive thing about Android is the ability for applications to launch other apps or easily share content. Back in the days of iOS 1.0, it quickly became obvious that applications couldn't really talk to each other (at least non-Apple applications), even after the first iOS SDK was released.

Before iOS 6, attaching a photo or a video to an email you were already composing was definitely a chore. It was not until Apple added the ability in iOS 6 that this was really possible. Android, on the other hand, was designed to support this behavior since day one.

There are other simple examples where it really becomes clear how different both platforms behave. Imagine the following scenario: you take a picture and want to retouch it with some image editing app, and later share it on Instagram.

*Please note: this is just a example to illustrate a point.*

This is how you do it on iOS:

1. Open Camera App, and take the picture. 
2. Go to the Home Screen, find your *EditPhoto* app, launch it, open existing photo, find it in the Camera Roll, make your edits. 
3. If *EditPhoto* supports sharing **and** Instagram is on the list, you're good to go!
4. Otherwise, you will have to Save the image in the Photo Library.
5. Go to the Home Screen again, find *Instagram*, launch it…
6. Import the recently saved photo, and then share it on Instagram with your hipster friends. ;)

On Android, things are a lot easier:

1. Open Camera App, and take the picture. 
2. Swipe Right to see the 'Gallery,' and click the Share button. Pick your *EditPhoto* app and make your edits.
3. If *EditPhoto* supports sharing (I haven't seen a photo editing app that doesn't), tap it and select Instagram. If it doesn't, remove *EditPhoto* app and get a decent photo editor or use the built-in editor, which has gotten really good in KitKat. 

Notice that if iOS apps support sharing between them, the flow is similar. The biggest difference is that if the app is not supported, you just can't do it directly. Instagram is an easy and popular one, just like Facebook or Twitter, but there are dozens of other not-so-supported apps out there.

Let's say you have a picture in Instagram and you want to share it to Path (I know, not a lot of people use Path, but still…). In Android, you would likely find Path in the *chooser dialog*. As simple as that.

Let's get back on topic. *Intents*. 

## What is an Android Intent?

The English dictionary defines an Intent as:

    noun
    intention or purpose
    
According to the official Android [documentation](http://developer.android.com/guide/components/intents-filters.html), an `Intent` *is a messaging object you can use to request an action from another app component*. In truth, an Intent is an abstract description of an operation to be performed. 

This sounds interesting, but there's more than meets the eye. Intents are used everywhere, no matter how simple your app is; even your Hello World app will use an Intent. That's because the most common case for an Intent is to start an `Activity`.[^1]

## Activities and Fragments, What are You Talking About?

*The closest thing to an `Activity` in iOS would be a `UIViewController`. Don't go around looking for an Android equivalent of an `ApplicationDelegate`; there is none. Perhaps the closest thing would be the `Application` class in Android, but there are a lot architecture differences between them.*

As screens in devices grew bigger, the Android team added the concept of `Fragments`.[^2]  The typical example is the News Reader app. On a phone with a small screen, you only see the list of articles. When the user selects one, the article opens in fullscreen.

Before `Fragments`, you would have had to create two activities (one for the list, and one for the fullscreen article) and switch between them. 

This worked well, until tablets with big screens came. Since you can only have **one** activity visible at a time (by design), the Android team invented the concept of `Fragments`, where a hosting `Activity` can display more than one `Fragment` at the same time. 

Now, instead of having two different `Activities`, you can have one that will display **two** `Fragments` -- one for the list of articles and one that is capable of showing the selected article fullscreen. In phones or devices with small screens, you would simply swap the `Fragment` when the user selected an article, but on tablets, the same activity would host both at the same time. To visualize this, think of the Mail app on an iPad, where you see the inbox on the left and the mail list on the right. 

### Starting Activities

Intents are commonly used to start activities (and to pass data between them). An `Intent` will glue the two activities by defining an operation to be performed: launch an `Activity`.

Since starting an `Activity` is not a simple thing, Android has a system component called `ActivityManager` that is responsible for creating, destroying, and managing activities. I won't go into much more detail about the `ActivityManager`, but it's important to understand that it keeps track of all the open activities and delivers broadcasts across the system; for example, it notifies the rest of the Android system once the booting process is finished.

It's an important piece of the Android system and it relies on `Intents` to do much of its work.

So how does Android use an `Intent` to start an `Activity`?

If you dig through the `Activity` class hierarchy, you will find that it extends from a `Context`, which, in turn, contains a method called `startActivity()`, defined as:

    public abstract void startActivity(Intent intent, Bundle options);

This abstract method is implemented in `Activity`. This means you can start activities from any activity, but you need to pass an `Intent` to do so. How?

Let's imagine we want to launch an `Activity` called `ImageActivity`.

The `Intent` constructor is defined as:

    public Intent(Context packageContext, Class<?> cls)

So we need a `Context` (remember, any `Activity` is a valid `Context`) and a `Class` type. 

With that in mind:

    Intent i = new Intent(this, ImageActivity.class);
    startActivity(i);

This triggers a lot of code behind the scenes, but the end result is that if everything went well, your `Activity` will start its lifecycle and the current one will likely be paused and stopped. 

Since Intents can also be used to pass certain data between activities, we could use them to pass *Extras*. For example:

    Intent i = new Intent(this, ImageActivity.class);
    i.putExtra("A_BOOLEAN_EXTRA", true); //boolean extra
    i.putExtra("AN_INTEGER_EXTRA", 3); //integer extra
    i.putExtra("A_STRING_EXTRA", "three"); //integer extra
    startActivity(i);

Behind the scenes, the *extras* are stored in an Android `Bundle`,[^3] which is pretty much a glorified serializable container. 

The nice thing is that our `ImageActivity` will receive these values in the `Intent` and can easily do:

     int value = getIntent().getIntExtra("AN_INTEGER_EXTRA", 0); //name, default value

This is how you pass data between activities. If you can serialize it, you can pass it. 

Imagine you have an object that implements `Serializable`. You could then do this:

    YourComplexObject obj = new YourComplexObject();
    Intent i = new Intent(this, ImageActivity.class);
    i.putSerializable("SOME_FANCY_NAME", obj); //using the serializable constructor here
    startActivity(i);

And it would work the same way on the other `Activity`:

    YourComplexObject obj = (YourComplexObject) getIntent().getSerializableExtra("SOME_FANCY_NAME");
    

As a side note, *always check for null when retrieving the Intent*:

    if (getIntent() != null ) {
             // you have an intent, so go ahead and get the extras…
    }

This is Java, and Java doesn't like null references. Get used to it. ;)

When you start an activity with this method (`startActivity()`), your current activity is paused, stopped (in that order) and put in the task stack, so if the user presses the *back* button, it can be restored. This is usually OK, but there are certain *Flags* you can pass to the Intent to indicate the `ActivityManager` that you'd like to change this behavior. 

Although I will not go into detail because it's a rather extensive subject, you should take a look at the [Tasks and Back Stack official docs](http://developer.android.com/guide/components/tasks-and-back-stack.html) to understand what else *Intent Flags* can do for you.

So far, we've only used Intents to open other activities in our application, but what else can an `Intent` do?

There are two more things that are possible thanks to `Intents`: 

* Start (or send a command to) a `Service`.[^4]
* Deliver a `Broadcast`.

### Starting a Service
    
Since `Activities` cannot be put in the background (because they would be paused, stopped, and maybe destroyed), the alternative -- if you need to run a background process while there's no visible UI -- is to use a `Service`. Services are also a big subject, but the short version is they can perform tasks in the background, regardless of whether or not the UI is visible.

They are prone to be destroyed if memory is needed and they run on the UI thread, so any long-time running operation should spawn a thread, usually through an [AsyncTask](http://developer.android.com/reference/android/os/AsyncTask.html). If a `Service` needs to do something like media playback, it can request a *Foreground* status, which **forces** the application to show a permanent notification in the Notification Bar to indicate to the user that something is happening in the background. The app can cancel the foreground status (and therefore dismiss the notification), but by doing so, the `Service` loses its higher-priority status. 

`Services` are very powerful mechanisms that allow Android applications to perform the 'real multitasking' that so controversially affected battery life in the past. Back when iOS had virtually no multitasking, Android was already dancing with the stars. When correctly used, `Services` are an integral part of the platform. 

In the past, the biggest problem was that there were ways to request a `Service` foreground status **without** showing a notification. This behavior was abused by developers who left tasks running in the background without the user knowing about it. In Android 4.0 (Ice Cream Sandwich), Google finally fixed the 'hidden' notification, and now if your app is doing something in the background, the user **will see** the notification alongside your app's name and icon. You can even access the application information directly from the notification bar (and kill it!). Yes, Android's battery life is nowhere near as good as with iOS, but it's no longer because of hidden `Services`. ;)

How are `Intents` and `Services` related?

In order to start a service, you need to use an `Intent`. Once a `Service` is started, you can keep sending commands to the service, until it's stopped (in which case it will restart).

The easiest way to understand it is to see some code:

In some `Activity`, you could do:

    Intent i = new Intent(this, YourService.class);
    i.setAction("SOME_COMMAND");
    startService(i);
    
What happens next will depend on whether or not this was the first time you did that. If so, the service will be started (it's constructor, and `onCreate()` methods will be executed first). If it was already running, the `onStartCommand()` method will be directly called.

The signature is: `public int onStartCommand(Intent intent, int flags, int startId);`

Let's ignore the `flags` and `startId`, as they have nothing to do with the topic at hand, and concentrate on the `Intent`. 

We set an `Action` earlier with `setAction("SOME_COMMAND")`. This action is passed to the `Service` and we can retrieve it from the `onStartCommand()`. For example, in our `Service`, we could do:

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String action = intent.getAction();
        if (action.equals("SOME_COMMAND")) {
            // Do SOME COMMAND ;)
        }
        return START_NOT_STICKY; // Don't restart the Service if it's killed.
    }

If you are wondering what that `START_NOT_STICKY` thing is, the [Android docs](http://developer.android.com/reference/android/app/Service.html) are an excellent source of information.

**TL;DR:** if this `Service` gets killed, don't attempt to restart it. The opposite is `START_STICKY`, which means restart the `Service` should its process die. 

As you can see from the snippet above, you can retrieve the `Action` from the `Intent`. This is how you usually communicate with `Services`.

Let's imagine we are developing an application that can reproduce YouTube videos and stream them to a Chromecast (*the stock YouTube app already does this, but this is Android, so we want to make our own*).

The streaming would be implemented in a `Service` so the streaming doesn't stop if the user goes to another application while he or she is playing a video. You could have different actions defined, like:

    ACTION_PLAY, ACTION_PAUSE, ACTION_SKIP.

You could also have a `switch` or `if` statement in the `onStartCommand()` to deal with each case. 

The names can be anything you want, but you will usually want to use constants (as we will see later) and better names to avoid conflicts with other apps, usually full package names like: '`com.yourapp.somepackage.yourservice.SOME_ACTION_NAME`'. This can also be made private if you only want your own app to be able to communicate with your service, but it can be public, meaning you could let other apps use your `Service`. 

### Sending and Receiving Broadcasts

Part of the strength of the Android platform is that any application can broadcast an `Intent` and anyone can define a `BroadcastReceiver` to receive one. In fact, Android itself makes use of this mechanism to inform apps and the system about events. For example, if the network goes down, an Android component will broadcast an `Intent`. If you were interested in this, you could create a `BroadcastReceiver` with the right **filter** to intercept that and act accordingly. 

Think of this as a global channel you can subscribe to, add the filters you care for, and receive notifications when those broadcasts occur. You can define them privately if you want, meaning only your app will be able to receive them.

To continue with the previous example of our YouTube streaming service, if there were a problem with video playback, the service could *broadcast* an `Intent` saying, "Hey, there was a problem and I will now stop playback."

Your application could register a `BroadcastReceiver` to listen to your `Service` so it can react to that.

Let's see some code to illustrate. 

You have an `Activity` that is displaying the currently playing music track alongside with the media buttons (play, pause, stop, etc.). You are interested in knowing what your service is doing; if there's an error, you want to know (so you can show an error message, etc.). 

In your activity (or in its own .java file) you would create your broadcast receiver:

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
               // THERE HAS BEEN AN ERROR, PLAYBACK HAS STOPPED
            } else if (intent.getAction().equals("ACTION_PLAY")){
               // Playback has started
            }
            // etc…
        }
     }

That's your basic receiver. Notice how we added an `IntentFilter` with the `Actions` that we're interested in. We called them `ACTION_PLAY`, `ACTION_STOP`, and `ACTION_ERROR`.

Since we use Java and Android has some conventions, we'd call this:

`private ServiceReceiver mServiceReceiver;` as a field *member* of our `Activity`. In our `onCreate()` method we instantiate it with: `mServiceReceiver = new ServiceReciver();`

But creating this object is not enough. We also need to register it somewhere. Initially, you may think that a good place to do it would be the `onStart()` method of our `Activity`. When the `onStart()` method is executed, that means our `Activity` is visible to the user.

The signature for the method is (in `Context`):

    public abstract Intent registerReceiver(BroadcastReceiver receiver, IntentFilter filter);
 
*`Activities` and `Services` are also `Contexts`, so both implement this method. This means that either can register one or more `BroadcastReceivers`.*

The method needs a `BroadcastReceiver` and an `IntentFilter`. We've created both, so we pass them:

    @Override
    public void onStart() {
        onStart();
          registerReceiver(mServiceReceiver, mServiceReceiver.intentFilter);
    }
    
In order to be good Java/Android citizens, we want to unregister if our `Activity` is stopping:
    
    @Override
    public void onStop() {
        super.onStop();
        unregisterReceiver(mServiceReceiver);
    }

This approach is not incorrect, but you have to keep in mind that if the user navigates outside of your application, you will never receive the broadcast. This is because your `Activity` will be stopped, and because you are unregistering during `onStop()`. When designing `BroadcastReceivers`, you have to keep in mind whether or not this makes sense. There are other ways to implement them (outside an `Activity`) to act as independent objects.

When the `Service` detects an error, it can dispatch a broadcast that our `BroadcastReceiver` will receive in its `onReceive()` method.

Broadcast receivers are very powerful mechanisms and are core mechanisms in Android.

Astute readers may be wondering how *global* these broadcasts are and how to make them private or restricted to their own apps. 

There are two types of Intents: *explicit* and *implicit*.

The former will specify the component to start by the fully qualified name, something that you will always know for your own application. The latter declares a general action to perform, which allows a component from another app to handle it. And here is where things start to get interesting. 

Let's focus on *implicit Intents*, since we have already seen *explicit Intents* in action with our example above. 

The best way to see the power of *implicit intents* is by using a simple example. There are two ways to use a filter. The first approach is more iOS friendly, because iOS can define a custom URI scheme, for example: yourapp://some.example.com

If you have to support the same URI from both iOS and Android, then this will be your only choice. On the other hand, if you are able to use a regular URL (`http://your.domain.com/yourparams`) then you should try to do it this way on Android. This raises the big argument of whether using a custom URI is good or bad, and I'm not going to dive into that at this point, suffice to say that (and I quote): 

> This goes against the web standards for URI schemes, which attempts to rigidly control those names for good reason -- to avoid name conflicts between different entities. Once you put a link to your scheme on a web site, you have put that little name into the entire Internet's namespace, and should be following those standards.

Source: [StackOverflow](http://stackoverflow.com/a/2449500/2684)

Arguments aside, let's take a look at two examples, one for YouTube using a regular URL, and then define our own custom URI scheme for our own app.

It's simpler than it looks because Android has a configuration file called `AndroidManifest.xml`, where it stores metadata about your `Activities`, `Services`, `BroadcastReceivers`, versions, Intent filters, and more. Every application has this file -- you can read more about it [here](http://developer.android.com/guide/topics/manifest/manifest-intro.html).

The idea behind an Intent filter is that the system will check for installed apps to see if there's one (or more) that can handle a particular URI.

If your app matches and it's the only one, it will be automatically open. Otherwise, you will see a dialog like this:

![image]({{ site.images_path }}/issue-11/android-dialog-choser.jpg)

So how did the official YouTube app end up in that list?

I tapped on a YouTube link in the Facebook App. How did Android know that it was YouTube? *What kind of sorcery is this?*

If we had access to YouTube's `AndroidManifest.xml`, we would likely see something like this: 

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

Let's examine this simple XML line by line.

Line 1 declares the activity (you must declare each `Activity` in Android, regardless of the Intent filters).

Line 3 declares the action. In this case, `VIEW` is the most common action, indicating that data will be displayed to the user. Some actions can only be sent by the system because they are protected.

Lines 4-5 declare the categories. Implicit Intents require at least one action and one category. Categories provide additional detail about the action the Intent performs. When resolving an Intent, only activities that provide all of the requested categories will be used. `android.intent.category.DEFAULT` is applied to every `Activity` by Android when you use `startActivity()`, so if you want your activity to receive implicit Intents, it must include it.

`android.intent.category.BROWSABLE` is a different beast:

> Activities that can be safely invoked from a browser must support this category. For example, if the user is viewing a web page or an e-mail and clicks on a link in the text, the Intent generated execute that link will require the BROWSABLE category, so that only activities supporting this category will be considered as possible actions. By supporting this category, you are promising that there is nothing damaging (without user intervention) that can happen by invoking any matching Intent.

Source: [Android Documentation](http://developer.android.com/reference/android/content/Intent.html#CATEGORY_BROWSEABLE)

This is an interesting point, and this gives Android a very powerful mechanism for apps to respond to any link. You could create your own web browser and it will respond to any URL; the user could set it as default if he or she wishes.

Lines 6-9 declare the data to operate on. This is part of the *type*. In this simple example, we're filtering by scheme and host, so any http://www.youtube.com/ link will work, even if tapped on a WebBrowser.

By adding these lines to YouTube's `AndroidManifest.xml`, when it's time to perform an *Intent resolution*, Android performs a matching of an Intent against all of the `<intent-filter>` descriptions in the installed application packages (or `BroadcastReceivers` registered via code, like our example above).

The Android `PackageManager`[^6] will be queried using the `Intent` information (the action, type, and category), for a component that can handle it. If there's one, it will be automatically invoked, otherwise the above dialog will be presented to the user, so he or she can chose (and maybe set as default) a particular app or package to handle the type of Intent.

This works well for many apps, but sometimes you need to use the same iOS link (where your only choice is to use a custom URI). In Android, you could support both, since you can add more filters to the same activity. To continue with the YouTubeActivity, let's add now an imaginary YouTube URI scheme:

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


The filter is almost the same, except we added a new line 10, specifying our own scheme. 

The app can now open links like: `youtube://path.to.video.` and normal HTTP links. You can add as many filters and types to an `Activity` as you wish.

#### How Bad is it to Use my Custom URI Scheme?

The problem is that it doesn't follow the standard rules for URIs defined by the W3C, at least according to purists. The truth is that this is not entirely true or a real problem. You are OK to use custom URI schemes, as long as you restrict them to your own internal packages. The biggest problem with a custom (public) URI scheme is name conflict. If I define a `myapp://`, nothing stops the next app from doing the same, and we have a problem. Domains, on the other hand, are never going to clash, unless I'm trying to create my own YouTube player, in which case, it's fine for Android to give me the choice to use my own YouTube player or the official Android app. 

Meanwhile, a custom URL like `yourapp://some.data` may not be understood by a web browser and it can lead to 404 errors. You're *bending* the rules and standard conventions. 


### Sharing Data

`Intents` are used when you have something you want to *share* with other apps, such as a post in a social network, sending a picture to an image editor, or sending an email, an SMS, or something via any other instant messaging service. So far, we have seen how to create intent filters and register our app to be notified when we are capable of handling certain types of data. In this final section, we'll see how to tell Android that we have something to *share*. Remember what an `Intent` is: *an abstract description of an operation to be performed*. 

#### Posting to Social Networks

In the following example, we're going to share a text and let the user make the final decision:

    1  Intent shareIntent = new Intent(Intent.ACTION_SEND);
    2  shareIntent.setType("text/plain");
    3  shareIntent.putExtra(Intent.EXTRA_TEXT, "Super Awesome Text!");
    4  startActivity(Intent.createChooser(shareIntent, "Share this text using…"));
        

Line 1 creates an `Intent` and passes an action using the constructor: `public Intent(String action);`

`ACTION_SEND` is used when you want to *deliver some data to someone else*. In this case, the data is our "Super Awesome Text!" But we don't know who that 'someone else' is yet. It will be up to the user to decide that. 

Line 2 sets an explicit MIME data type of `text/plain`.

Line 3 adds the data (the text) to this Intent using an extra.

Line 4 is where the magic happens. `Intent.createChooser` is a convenience function that wraps your original Intent in a new one with an action, `ACTION_CHOOSER`.

There's no rocket science going on here. The action is designed so an activity chooser is displayed, allowing the user to pick what he or she wants before proceeding. Sometimes you want to be explicit (so if the user is sending an email, you may want to use the default email client directly), but in this case, we want the user to select any app to handle this text. 

This is what I see when I use it (the list is longer -- it's a scrollable list):

![image]({{ site.images_path }}/issue-11/android-chooser.gif)

I have decided to send it to Google Translate. Here's the result:

![image]({{ site.images_path }}/issue-11/android-translate.jpg)

The results attempting to do it in Google Translate speak in Italian. 

## An Extra Example

Before wrapping up, let's see another example. This time, we'll see how to share and receive an image. We want the app to appear in the chooser when the user shares an image.

We need to do something like this in our `AndroidManifest`:

    1    <activity android:name="ImageActivity">
    2        <intent-filter>
    3            <action android:name="android.intent.action.SEND"/>
    4            <category android:name="android.intent.category.DEFAULT"/>
    5            <data android:mimeType="image/*"/>
    6        </intent-filter>
    7    </activity>

Remember, we need at least one action and one category. 

Line 3 sets the action as `SEND`, so we will match `SEND` actions.

Line 4 declares the `DEFAULT` category. This category gets added by default when you use `startActivity()`. 

Line 5 is they key that sets the MIME type as *any type of image*.

Now, in our `ImageActivity`, we handle the Intent like this:

    1    @Override
    2    protected void onCreate(Bundle savedInstanceState) {
    3        super.onCreate(savedInstanceState);
    4        setContentView(R.layout.main);
    5        
    6        // Deal with the intent (if any)
    7        Intent intent = getIntent();
    8        if ( intent != null ) {
    9            if (intent.getType().indexOf("image/") != -1) {
    10                 Uri data = intent.getData();
    11                 // handle the image…
    12            } 
    13        }
    14    }

The relevant code is in line 9, where we're actually checking if the Intent contains image data.

Now, let's do the opposite. This is how we *share* an image:

    1    Uri imageUri = Uri.parse("/path/to/image.png");
    2    Intent intent = new Intent(Intent.ACTION_SEND);
    3    intent.setType("image/png");    
    4    intent.putExtra(Intent.EXTRA_STREAM, imageUri);
    5    startActivity(Intent.createChooser(intent , "Share"));

The interesting code is in line 3, where we define the MIME type (so only `IntentFilters` capable of dealing with this type will be shown), and in line 4, where we actually place the data that will be shared.

Finally, line 5 creates the *chooser* dialog we've seen before, but only containing apps that can handle `image/png`.
    

## Summary

We have scratched the surface regarding what Intents can do and how information can be shared in Android, but there's a lot more to see. It's a very powerful mechanism and one aspect that makes Android users frown when they use iOS devices. They (myself included) find the process of always going home and/or using the Task Switcher in iOS very inefficient. 

This doesn't really mean Android is technically better or that the Android method is superior when it comes to sharing data between applications. In the end, everything is a matter of preference, just like the *back* button some iOS users loathe when they grab an Android device. On the other hand, Android users love that button. It's standard and efficient and it's always in the same place, next to the *home* button. 

When I lived in Spain, I remember they had a very good saying: "Colors were created so we can all have different tastes" (or something like that). ;) 

## Further Reading

* [Intents and Filters](http://developer.android.com/guide/components/intents-filters.html)
* [Intents](http://developer.android.com/reference/android/content/Intent.html) 
* [Common Intents](http://developer.android.com/guide/components/intents-common.html)
* [Integrating Application with Intents](http://android-developers.blogspot.com.es/2009/11/integrating-application-with-intents.html)
* [Sharing Simple Data](http://developer.android.com/training/sharing/index.html)





[^1]: Activities are the components that provide a user interface for a single screen in your application.
[^2]: A fragment represents a behavior or a portion of user interface in an activity. 
[^3]: A mapping from string values to various Parcelable types.
[^4]: A service is an application component representing an application's desire to either perform a longer-running operation while not interacting with the user, or to supply functionality for other applications to use.
[^6]: [PackageManager](http://developer.android.com/reference/android/content/pm/PackageManager.html): class for retrieving various kinds of information related to the application packages that are currently installed on the device.



<link type="text/css" media="screen" href="http://www.objc.io/css/fonts.css" rel="stylesheet"></link>

<link media="screen" type="text/css" rel="stylesheet" href="http://www.objc.io/assets/global-4f8291937b6a6b2068441ea12a09c3d8.css"></link>

#Android Intents

[Issue #11 Android](http://www.objc.io/issue-11/index.html), April 2014
<br>By [Martin Marconcini](https://twitter.com/Gryzor)</br>

##简介

说起Android，最大的特点莫过于运行其平台上的应用可以很容易的启动别的应用以及互相之间分享数据。回首iOS 1.0时代，应用之间是完全隔离的，无法进行通信（至少非apple应用之间是这样的），甚至到了iOS SDK面世之时，这种状况也没有改变。

iOS6之前的系统，若要在编写邮件过程中直接加入照片或视频是件很麻烦的事。iOS6发布以后，这项功能才得到根本性的改善。但是在Android的世界里，自发布的第一天，这种功能就是天生携带的。

类似的系统平台层面的差异还有许多。比如有这样一个场景：拍一张照片，然后用某个图片处理app里编辑一下，接着将照片分享到Instagram。

*注意：这里列举个别细节。*

iOS的做法是：

1.打开系统拍照应用拍张照片。
2.回到主界面，找到*图片编辑*应用，启动应用，选择已存在照片，从系统相册里选取照片，然后编辑。
3.如果*图片编辑*应用恰好支持直接分享且Instagram又在分享列表中，就此完成任务。
4.如果第3点条件不满足，那就得先把编辑好的照片保存到系统相册。
5.再一次回到主界面，找到*Instagram*然后打开它...
6.导入之前编辑保存的照片，然后分享给Instagram上的潮友们。;)

至于Android，就简单得多了：

1.打开拍照应用，拍张照片。
2.向右滑查看“相册”，然后点击分享按钮。选择想要使用的*图片编辑*应用，然后直接编辑。
3.如果*图片编辑*应用支持直接分享（我还从来没见过哪个图片处理应用不支持直接分享的），点击分享然后选择Instagram。假如这个应用不支持分享，直接卸载算了，换个靠谱的应用来处理，或者干脆用系统集成的图片编辑器。KitKat之后的系统内建编辑器已经相当酷炫。

需要说明的是，对于那些提供分享功能的iOS 应用来说，其处理流程和android基本是一致的。根本性的差别是，如果应用本身不支持分享那就断绝了分享给其他应用的道路。与Facebook和Twitter一样，Instagram这类热门应用还好，但是除此之外还有大量的应用，基本上没什么应用会集成针对它们的分享服务。

比如说你想把Instagram里的某张照片分享到Path上面（我知道，Path比较小众，但是...）。如果是Android系统，直接从*chooser dialog(选择对话框)*中选择Path即可。就是这么简单。

还是说回正题——*Intents*。

##什么是Android Intent？

在英语词典里Intent的定义是：

<pre><code class=" hljs ">noun (名词)
intention or purpose (意图、目的)</code></pre>

来自Android[官方文档](http://developer.android.com/guide/components/intents-filters.html)的说明是，<code>Intent</code>*对象主要是解决Android应用各项组件之间的通讯*。事实上，Intent就是对将要执行的操作的一种抽象描述。

看起来很简单，实际上Intent的意义远不止于此。在Android世界中，Intent几乎随处可见，无论你开发的app都么简单，也离不开Intent；小到一个Hello World应用也是要使用Intent的。因为Intent最基础最常见的用法就是启动<code>Activity</code>。<sup id="fnref:1"><a href="#fn:1" rel="footnote">[1](#fn:1)</a></sup>

##如何理解Activities和Fragments

*在iOS中，与<code>Activity</code>相比较，最相似的东西就是<code>UIViewController</code>了。切莫在Android中寻找<code>ApplicationDelegate</code>的等价物，因为没有。也许只有<code>Application</code>类稍微贴近于<code>ApplicationDelegate</code>，但是从架构上看，它们有着本质的区别。*

由于厂商把手机屏幕越做越大，一个全新的概念<code>Fragments</code><sup id="fnref:2"><a href="#fn:2" rel="footnote">[2](#fn:2)</a></sup>（碎片）随之而生。最典型的例子就是新闻阅读类应用(News Reader app)。在小屏幕的手机上，一般用户只能先看到文章列表。选中一篇文章后，才会全屏显示文章内容。

没有<code>Fragments</code>的时候，开发者需要创建两个activities（一个用于展示文章列表，另一个用于全屏展示文章详情），然后在两者来回切换。

如果不考虑大屏幕手机，这么做没有问题。因为原则上，同一时间只有一个activity对用户可见，但自从Android团队引入了<code>Fragments</code>，一个宿主<code>Activity</code>同时可以展示多个<code>Fragments</code>。

现在，完全可以用一个<code>Activity</code>嵌入两个<code>Fragments</code>的方式来替代先前使用两个不同<code>Activities</code>的做法。一个<code>Fragment</code>用来展示文章列表，另一个用来展示详情。对于小屏幕的手机，可以用两个<code>Fragments</code>交替显示文章列表和详情。如果是平板设备，宿主Activity会同时显示两个Fragments的内容。类似的东西可以想像一下iPad中的邮件应用，在同一屏中，左边是收件箱，右边是邮件列表。

###启动Activities

Intent最常见的用法就是用来启动activities（以及在activities之间传递数据）。<code>Intent</code>通过定义两个activities之间将要执行的动作从而将它们粘合起来。

然而启动一个<code>activity</code>并不简单。Android中有一个叫做ActivityManager(活动管理器)的系统组建负责创建、销毁和管理activities。这里不去过多探讨ActivityManager的细节，但是需要指出的是它承担全程监视已启动的activities以及在系统内发送广播通知的职责，比如说，系统启动过程结束这件事就是由ActivityManger来发放通知。

ActivityManager是安卓系统的一个极重要的部分，同时它依靠<code>Intents</code>来完成大部分工作。

那么Android系统到底是如何利用<code>Intent</code>来启动<code>Activity</code>的呢？

如果你仔细挖掘一下Activity的类结构就会发现：它继承自<code>Context</code>，里面恰好有个抽象方法<code>startActivity()</code>，其定义如下：

<pre><code class=" hljs java"><span class="hljs-keyword">public</span> <span class="hljs-keyword">abstract</span> <span class="hljs-keyword">void</span> <span class="hljs-title">startActivity</span>(Intent intent, Bundle options);</code></pre>

<code>Activity</code>实现了这个抽象方法。也就是说只要传递了正确的Intent，可以对任意一个<code>Activity</code>执行启动操作。

比如说我们要启动一个<code>Activity</code> ImageActivity.

其中<code>Intent</code>的构造方法是这样的：

<pre><code class=" hljs java"><span class="hljs-keyword">public</span> <span class="hljs-title">Intent</span>(Context packageContext, Class&lt;?&gt; cls)</code></pre>

需要传递参数<code>Context</code>（注意，可以认为每一个Activity都是一个有效的<code>Context</code>）和<code>Class</code>类。

接下来：

<pre><code class=" hljs java">Intent i = <span class="hljs-keyword">new</span> Intent(<span class="hljs-keyword">this</span>, ImageActivity.class);
startActivity(i);</code></pre>

这之后会触发一系列调用，如无意外，最终会成功启动一个新的<code>Activity</code>，当前的<code>Activity</code>会进入paused（暂停）或者stopped（停止）状态。

Intents还可以帮Activities之间传递数据，比如我们将信息放入*Extras*来传递：

<pre><code class=" hljs java">Intent i = <span class="hljs-keyword">new</span> Intent(<span class="hljs-keyword">this</span>, ImageActivity.class);
i.putExtra(<span class="hljs-string">"A_BOOLEAN_EXTRA"</span>, <span class="hljs-keyword">true</span>); <span class="hljs-comment">//boolean extra</span>
i.putExtra(<span class="hljs-string">"AN_INTEGER_EXTRA"</span>, <span class="hljs-number">3</span>); <span class="hljs-comment">//integer extra</span>
i.putExtra(<span class="hljs-string">"A_STRING_EXTRA"</span>, <span class="hljs-string">"three"</span>); <span class="hljs-comment">//integer extra</span>
startActivity(i);</code></pre>

*extras*存储在可序列化容器Android Bundle<sup id="fnref:3"><a href="#fn:2" rel="footnote">[3](#fn:3)</a></sup>中。

这样<code>ImageActivity</code>就可以通过<code>Intent</code>来接收信息，可以通过如下方式将信息取出：

<pre><code class=" hljs java"> <span class="hljs-keyword">int</span> value = getIntent().getIntExtra(<span class="hljs-string">"AN_INTEGER_EXTRA"</span>, <span class="hljs-number">0</span>); <span class="hljs-comment">//名称，默认值</span></code></pre>

上面就是如何在Activities之间传简单值。当然也可以传序列化对象。

假如一个对象已实现序列化接口<code>Serializable</code>。接下来可以这么做：

<pre><code class=" hljs java">YourComplexObject obj = <span class="hljs-keyword">new</span> YourComplexObject();
Intent i = <span class="hljs-keyword">new</span> Intent(<span class="hljs-keyword">this</span>, ImageActivity.class);
i.putSerializable(<span class="hljs-string">"SOME_FANCY_NAME"</span>, obj); <span class="hljs-comment">//这里使用接收序列化值方法</span>
startActivity(i);</code></pre>

其它的<code>Activity</code>也要使用相应的序列化取值方法获取值：
<pre><code class=" hljs java">YourComplexObject obj = (YourComplexObject) getIntent().getSerializableExtra(<span class="hljs-string">"SOME_FANCY_NAME"</span>);</code></pre>

特别说明，*从Intent取值的时候请记得判空*：

<pre><code class=" hljs java"><span class="hljs-keyword">if</span> (getIntent() != <span class="hljs-keyword">null</span> ) {
         <span class="hljs-comment">// 确认Intent非空后，可以进行诸如从extras取值什么的…</span>
}</code></pre>

在Java的世界中对空指针很敏感。所以要多加防范。;)

使用<code>startActivity()</code>启动了新的activity后，当前的activity会依次进入paused和stopped状态，然后进入任务堆栈，当用户点击*返回*按钮后，activity会再次恢复激活。正常情况下，这一系列流程没什么问题，不过还是可以通过向Intent传递一些*Flags（标识）*来通知ActivityManager去改变既定行为。

由于这是一个很大很复杂的话题，此处就不做过多的展开了。可以参见文档[Tasks and Back Stack official docs](http://developer.android.com/guide/components/tasks-and-back-stack.html)来了解*Intent Flags*。

下面看看Intents除了启动Activity还能做些什么。

Intents还有两个重要职责：

* 启动服务<sup id="fnref:4"><a href="#fn:4" rel="footnote">[4](#fn:4)</a></sup>（或向服务发送指令）。
* 发Broadcast（广播）。

###启动服务
由于<code>Activities</code>不能在后台运行（因为在后台它们会进入paused态，stopped态，甚至是destroyed销毁状态），如果想要执行的后台进程不需要UI，可以使用<code>Service</code>（服务）作为替代方案。Services本身也是个很大的话题，简单的说它就是：没有界面或UI不可见的运行在后台的任务。

由于Services如无特殊处理是运行在UI线程上的，所以当系统内存紧张时，Services极有可能被销毁。也就是说，如果Services所要执行的是一个耗时操作，那么就应该为Services开辟单独的线程，一般都是通过[AsyncTask](http://developer.android.com/reference/android/os/AsyncTask.html)来创建。像一个<code>Service</code>如果执行媒体播放任务，可以通过申请*Foreground（前台）*服务状态来**强制**的在通知栏中“显形”，始终给用户展示当前服务在做些什么。应用也可以取消前台状态（通知栏上的相应状态通知也会随之消失），但是这么做的话<code>Service</code>就失去了较高的状态优先级。

<code>Services</code>机制是非常强大的，它也是Android“多任务”处理的基础，而在早前，它被认为是影响电池用量的关键因素。其实早在iOS还未支持多任务的时代，Android已经在自如的操纵多任务处理了。<code>Services</code>已经成为该平台必不可少的重要组成部分了。

在以前，有一个很争议的问题，就是<code>Service</code>可以在**没有**任何通知的情况下转入前台运行。也就是说在用户不知情的情况下，后台可能会启动大量的服务来执行各种各样的任务。自Android 4.0（Ice Cream Sandwich）之后，Google终于修复了这个“隐形”通知的问题，让无法杀掉进程且在后台静默运行的应用程序在通知栏上*“显形”*，用户甚至可以从通知栏中切换到应用内（然后杀掉应用）。虽然现在Android设备的续航还远不及iOS产品，但是至少后台静默<code>Services</code>已经不再是耗电的主因了。;)

<code>Intents</code>和<code>Services</code>是怎么协作的呢？

首先需要一个<code>Intent</code>来启动Service。而<code>Service</code>启动后，只要其处于非stopped状态，就可以持续地向service发送指令（如果是stopped态，service会重启）。

在某个Activity中启动服务：

<pre><code class=" hljs java">Intent i = <span class="hljs-keyword">new</span> Intent(<span class="hljs-keyword">this</span>, YourService.class);
i.setAction(<span class="hljs-string">"SOME_COMMAND"</span>);
startService(i);</code></pre>

接下来程序执行情况取决于当下是否第一次启动服务。如果是，那么服务就会自然启动（首先执行构造方法和onCreate()方法）。如果该服务已经启动过，将会直接调用onStartCommand()方法。

方法的具体定义：public int onStartCommand(Intent intent, int flags, int startId);

此处重点关注<code>Intent</code>。由于<code>flags</code>和<code>startId</code>与我们要探讨的话题相关性不大，这里直接忽略不赘述。

之前我们通过<code>setAction("SOME_COMMAND")</code>设置了一个<code>Action</code>。<code>Service</code>可以通过<code>onStartCommand()</code>来获取该action。拿上面的例子来说，可以这么做：

<pre><code class=" hljs java"><span class="hljs-annotation">@Override</span>
<span class="hljs-keyword">public</span> <span class="hljs-keyword">int</span> <span class="hljs-title">onStartCommand</span>(Intent intent, <span class="hljs-keyword">int</span> flags, <span class="hljs-keyword">int</span> startId) {
    String action = intent.getAction();
    <span class="hljs-keyword">if</span> (action.equals(<span class="hljs-string">"SOME_COMMAND"</span>)) {
        <span class="hljs-comment">// Do SOME COMMAND ;)</span>
    }
    <span class="hljs-keyword">return</span> START_NOT_STICKY; <span class="hljs-comment">// 如果服务已被杀掉，不要重新启动服务</span>
}</code></pre>

如果对START_NOT_STICKY感兴趣，请参见此[安卓文档](http://developer.android.com/reference/android/app/Service.html)有很想尽地描述。

简而言之：如果<code>Service</code>已经被杀掉，不需要重启。与之相反的是START_STICKY，这个表示应当执行重启。

从上面的代码段可知，能够从<code>Intent</code>中获取<code>Action</code>。这就是比较常见的与<code>Services</code>的通讯方式。

假设我们要开发一个应用，将Youtube的视频以流式输送给Chromecast(*虽然现有的Youtube应用已经具备这个功能了，但既然是Android吗，我们还是希望自己做一个*)。

通过一个<code>Service</code>来实现流式播放，这样当用户在播放视频的过程中切换到其它应用的时候，播放也不会停止。定义几种actions：

<pre><code class=" hljs ">ACTION_PLAY, ACTION_PAUSE, ACTION_SKIP.</code></pre>

在onStartCommand()内，可以通过<code>switch</code>或者<code>if</code>条件判断，然后针对每一种情况做相应的处理。

理论上，服务可以随意命名，但通常情况下会使用常量（稍后会举例）来命名，良好的命名可以避免和其它应用的服务名产生冲突，比如说使用完整的包名’com.yourapp.somepackage.yourservice.SOME_ACTION_NAME’。如果将服务名设为私有，那么服务只能和自己的应用通讯，否则要是想和其它应用通讯则需要将服务名公开。

###发送和接收广播

Android平台的强大特性之一就是：任何一个应用都可以广播一个<code>Intent</code>，同时，任意应用可以通过定义一个<code>BroadcastReceiver</code>（广播接收者）来接收广播。事实上，Android本身就是采用这个机制来向应用和系统来发送事件通知的。比如说，网络突然变成不可用状态，Android组件就会广播一个<code>Intent</code>。如果对此感兴趣，可以创建一个<code>BroadcastReceiver</code>，设置相应的**filter（过滤器）**来截获广播并作出适当的处理。

可以将这个过程解为订阅一个全局的频道，并且根据自己的喜好配置过滤条件，接下来会接收符合条件的广播信息。另外，若只是想要自己的应用接收广播，需要定义成私有。

继续前面的Youtube播放服务的例子，如果在播放的过程中出现了问题，服务可以发送一个<code>Intent</code>*广播*来发布信息，比如“播放遇到问题，将要停止播放”。

应用可以注册一个<code>BroadcastReceiver</code>来监听播放服务的广播，以便对收到的广播做出处理。

下面看一些样例代码。

基于上面的例子，你可能会定义一个Activity用来展示和播放有关的信息和操作，比如当前的播放进度和媒体控制按钮（播放，暂停，停止等等）。你可能会非常关注当前服务的状态；一旦有错误发生，你需要及时知晓（可以向用户展示错误提示信息等等）。

在activity（或者一个独立的.java文件）中可以创建一个广播接收器：

<pre><code class=" hljs java"><span class="hljs-keyword">private</span> <span class="hljs-keyword">final</span> <span class="hljs-class"><span class="hljs-keyword">class</span> <span class="hljs-title">ServiceReceiver</span> <span class="hljs-keyword">extends</span> <span class="hljs-title">BroadcastReceiver</span> {</span>
    <span class="hljs-keyword">public</span> IntentFilter intentFilter;
    <span class="hljs-keyword">public</span> <span class="hljs-title">ServiceReceiver</span>() {
        <span class="hljs-keyword">super</span>();
        intentFilter = <span class="hljs-keyword">new</span> IntentFilter();
        intentFilter.addAction(<span class="hljs-string">"ACTION_PLAY"</span>);
        intentFilter.addAction(<span class="hljs-string">"ACTION_STOP"</span>);
        intentFilter.addAction(<span class="hljs-string">"ACTION_ERROR"</span>);
    }
    <span class="hljs-annotation">@Override</span>
    <span class="hljs-keyword">public</span> <span class="hljs-keyword">void</span> <span class="hljs-title">onReceive</span>(<span class="hljs-keyword">final</span> Context context, <span class="hljs-keyword">final</span> Intent intent) {
        <span class="hljs-keyword">if</span> (intent.getAction().equals(<span class="hljs-string">"ACTION_ERROR"</span>)) {
           <span class="hljs-comment">// THERE HAS BEEN AN ERROR, PLAYBACK HAS STOPPED</span>
        } <span class="hljs-keyword">else</span> <span class="hljs-keyword">if</span> (intent.getAction().equals(<span class="hljs-string">"ACTION_PLAY"</span>)){
           <span class="hljs-comment">// Playback has started</span>
        }
        <span class="hljs-comment">// etc…</span>
    }
 }</code></pre>
 
 
接收器的实现大概如此。这里需要注意下我们向<code>IntentFilter</code>中添加的Actions。他们分别为ACTION_PLAY（播放）, ACTION_STOP（停止）, and ACTION_ERROR（错误）。

由于我们使用的是Java，列举一下Android的习惯用法：

<code>private ServiceReceiver mServiceReceiver;</code>；可以用此法将其定义为Activity的域成员。然后在<code>onCreate()</code>方法中对其进行实例化，比如：<code>mServiceReceiver = new ServiceReciver();</code>。

当然，单单创建这样的一个对象是不够的。我们需要在某处将其注册为BroadcastReceiver。第一反应，你可能会认为可以在Activity的<code>onStart()</code>方法内注册。当<code>onStart()</code>执行的时候，意味着用户可以看到这个Activity了。

注册方法详情如下（定义在<code>Context</code>中）：

<pre><code class=" hljs java"><span class="hljs-keyword">public</span> <span class="hljs-keyword">abstract</span> Intent <span class="hljs-title">registerReceiver</span>(BroadcastReceiver receiver, IntentFilter filter);</code></pre>

*由于<code>Activities</code>和<code>Services</code>都是Contexts，所以它们本身都实现了这个方法。这表示它们都可以注册一个或多个BroadcastReceivers*

此方法需要参数<code>BroadcastReceiver</code>和<code>IntentFilter</code>。之前已经创建好，可直接传参：

<pre><code class=" hljs java"><span class="hljs-annotation">@Override</span>
<span class="hljs-keyword">public</span> <span class="hljs-keyword">void</span> <span class="hljs-title">onStart</span>() {
    onStart();
      registerReceiver(mServiceReceiver, mServiceReceiver.intentFilter);
}</code></pre>

请养成良好的Java/Android开发习惯，当Activity停止的时候，请注销相应的注册信息：

<pre><code class=" hljs java"><span class="hljs-annotation">@Override</span>
<span class="hljs-keyword">public</span> <span class="hljs-keyword">void</span> <span class="hljs-title">onStop</span>() {
    <span class="hljs-keyword">super</span>.onStop();
    unregisterReceiver(mServiceReceiver);
}</code></pre>

这种处理本身没什么问题，但是要提醒大家，一旦用户离开了当前应用，将不会再收到广播。这是由于<code>Activity</code>即将停止，此处在onStop()这里注销了广播接收。所以当你设计<code>BroadcastReceivers</code>的时候，需要考虑清楚，这种处理方式是否适用。毕竟还有其它不依赖于Activity的实现方式可供选择。

每当<code>Service</code>侦测到错误发生，它都会发起一个广播，这样<code>BroadcastReceiver</code>可以在<code>onReceive()</code>方法中接收广播信息。

广播接收处理也是Android中非常重要非常强大非常核心的机制。

读到这里，爱思考的读者们可能会问这些广播到底可以*全局*到什么程度？如何将广播设置为私有以及如何限制它们只和其所属应用通讯？

事实上Intents有两类：*explicit（显式的）*和 *implicit（隐式的）*。

所谓显式Intent就是明确指出了目标组件名称的Intent，由于不清楚其它应用的组件名称，显式Intent一般用于启动自己应用内部的组件。隐式Intent则表示不清楚目标组件的名称，通过给出一些对想要执行的动作的描述来寻找与之匹配的组件（通过定义过滤器来罗列一些条件用于匹配组件），隐式Intent常用于启动其它应用的组件。

鉴于之前给出的例子中使用的就是*显式 Intents*，这里将重点讨论一下*隐式 Intents*。

我们通过一个简单的例子来看看*隐式 Intents*的强大之处。定义filter（过滤器）有两种方式。第一种与iOS的自定义URI机制很类似，比如：yourapp://some.example.com。

如果你的设计是想Android和iOS都通用，那么别无他法只能使用URI策略。如果只是针对Android平台的话，建议尽量使用标准URL的方式（比如http://your.domain.com/yourparams）。之所以这么说是因为这与如何看待自定义URI方案的利与弊有关，对这个问题不做具体的展开了，总而言之（下文引自stackoverflow）：

<blockquote><p>为了避免不同实体之间的命名冲突，web标准要求应严格要控制URI的命名。而使用自定义URI方案与其web标准相违背。一旦将自定义URI方案部署到互联网上，等于直接将方案名称投入到整个互联网的命名空间中去（会又很大的命名冲突可能性），所以应严格遵守相应的标准。</p></blockquote>

来源：[StackOverflow](http://stackoverflow.com/a/2449500/2684)

上述问题暂且放一边，下面看两个例子，一个是用标准URL来实现之前YouTube app，另一个是在我们自己的app中采用自定义URI方案。

因为每个Android都有配置文件AndroidManifest.xml，可以在其中定义<code>Activities</code>，<code>Services</code>，<code>BroadcastReceivers</code>，版本信息，<code>Intent filter</code>等描述信息，所以实现起来比较简单。[详情见文档](http://developer.android.com/guide/topics/manifest/manifest-intro.html)。

Intent过滤器的本质是系统依照过滤条件检索当前已安装的所有应用，看看有哪些应用可以处理指定的URI。

如果某个app刚好匹配且是唯一能够匹配的app，就会自动打开这个app。否则的话，可以看到类似这样的一个选择对话框：

<p><img alt="image" src="http://www.objc.io/images/issue-11/android-dialog-choser.jpg"></p>

为什么Youtube的官方应用会出现在清单上呢？

我只是在Facebook的应用里点了一个Youtube的链接而已。为什么Android会知道我点的是Youtube的链接？*这其中有什么玄机*？

假设我们打开Youtbube应用的<code>AndroidManifest.xml</code>，我们应该能看到类似如下的配置：

<pre><code class=" hljs ">1 &lt;activity android:name=".YouTubeActivity"&gt;
2     &lt;intent-filter&gt;
3        &lt;action android:name="android.intent.action.VIEW" /&gt;
4       &lt;category android:name="android.intent.category.DEFAULT" /&gt;
5         &lt;category android:name="android.intent.category.BROWSABLE" /&gt;
6       &lt;data
7        android:scheme="http"
8        android:host="www.youtube.com"
9        android:pathPrefix="/" /&gt;
10   &lt;/intent-filter&gt;
11 &lt;/activity&gt;</code></pre>

接下来我们会逐行解释一下这段XML信息。

第1行是声明activity（Android中的每个activity都必须在配置文件中声明，而过滤器则不是必须的）。

第2行声明了action。此处的VIEW是最常用的action，它表示会向用户展示数据。因为还存在一些受保护的只能用于系统级传输的action。

第4－5行声明了categories（类别）。隐式Intents要求至少有一个action和一个category。categories里主要定义Intent所要执行的Action的更多细节。在解析Intent的时候，只有满足categories中全部描述条件的activities才会被使用。Android把所有传给<code>startActivity()</code>的隐式Intetn当作他们包含至少一个category <code>android.intent.category.DEFAULT(CATEGORY_DEFAULT常量)</code>，想要接收隐式Intent的<code>Activity</code>必须在它们的Intent Filter中配置<code>android.intent.category.DEFAULT</code>。

<code>android.intent.category.BROWSABLE</code>是另一个敏感配置：

<blockquote><p>能通过浏览器安全调用的Activity必须支持这个category。比如，用户从正在浏览的网页或者文本中点击了一个e-mail链接，接下来生成执行这个link的Intent会含有BROWSABLE categroy描述，所以只有支持这个category的activities才会有可能被匹配到。一旦承诺支持这个category，在被Intent匹配调用后，必须保证没有恶意的行为或内容（至少是在用户不知情的情况下不可以有）。</p></blockquote>

来源：[Android Documentation（官方文档）](http://developer.android.com/reference/android/content/Intent.html#CATEGORY_BROWSEABLE)

这个点很关键，Android通过它构建了一种机制，允许应用去响应任何的链接。利用这个机制你完全可以构建自己的浏览器去处理任何URL的请求，如果用户喜欢的话完全可以将你的浏览器设置成默认浏览器。

第6-9行声明了所要操作的数据类型。在本例中，我们使用scheme（方案／策略）和host（主机）来进行过滤，所以任何以http://www.youtube.com/开头的链接均可处理，哪怕是在web浏览器里点击链接。

在Youtube应用内的AndroidManifest.xml里配置以上信息后，每当*Intent解析*的时候，Android都会在系统已安装的应用中根据<code><intent-filter></code>内定义的信息来过滤和匹配Intent（或者像我们的例子一样，从通过代码注册的<code>BroadcastReceivers</code>中寻找）。

Android <code>PackageManager<sup id="fnref:5"><a href="#fn:5" rel="footnote">[5](#fn:5)</a></sup></code>会根据Intent信息（action，type和category）来寻找符合条件的组件来处理Intent。如果找到唯一合适的组件，会自动调用，否则会像上面例子里那样弹出一个选择对话框，这样用户可以自行选择应用（或者根据默认设置中指定的应用）来处理Intent动作。

这个方案适用于大多数的应用，但是如果想要采取和iOS一样的link就只能使用自定义URI。不过在Android中，两种方案是都支持的，而且还可以对同样的activity增加多种过滤条件。还是以YoutubeActivity为例，我们假定一个Youtube URI方案配置上去：

<pre><code class=" hljs ">1 &lt;activity android:name=".YouTubeActivity"&gt;
2     &lt;intent-filter&gt;
3        &lt;action android:name="android.intent.action.VIEW" /&gt;
4       &lt;category android:name="android.intent.category.DEFAULT" /&gt;
5         &lt;category android:name="android.intent.category.BROWSABLE" /&gt;
6       &lt;data
7        android:scheme="http"
8        android:host="www.youtube.com"
9        android:pathPrefix="/" /&gt;
10      &lt;data android:scheme="youtube" android:host="path" /&gt;
11   &lt;/intent-filter&gt;
12 &lt;/activity&gt;</code></pre>

这个filter和先前配置的基本一致，除了在第10行增配了自定义的URI方案。

这样的话，应用可以支持打开诸如：<code> youtube://path.to.video</code>的链接，也可以打开普通的HTTP链接。总之，你想给<code>Activity</code>中配置多少filters和types都可以。

####使用自定义URI方案到底有什么负面影响？

自定义URI方案的问题是它不符合W3C针对URIs制定的各项标准。当然这个问题也并不绝对，如果只是在应用包内使用自定义URI是OK的。但像前文所说，若公开自定义URI会存在命名冲突的风险。假如定义一个URI为myapp://，谁也不能保证别的应用不会定义同样的东西，这就会有问题。反过来说，使用域名就不存在这种冲突的隐患。拿我们之前构建了自己的Youtube播放app来说，Android会提供选择是启用自己的Youtube播放器还是使用官方app。

同时，浏览器可能无法解析某些自定义URL，比如yourapp://some.data，极有可能报404。这就是*违背*规则和不遵守标准的风险。

###数据分享

可以通过<code>Intent</code>向其他应用*分享*信息，比如说向社交网网站分享个帖子，向图片编辑app传递一张图片，发邮件，发短息，或者通过即时通讯应用传些资源什么的等等都是再分享数据。目前为止，我们介绍了怎么创建intent filters，还有如何将应用注册成广播接收者以便在收到可响应的通知时做出相应的处理。在本文的最后一部分，将要探讨一下如何分享内容。再一次：所谓Intent就是对将要执行的动作的一种抽象描述。


####分享到社交网站

在下面的例子中，我们会分享一个文本信息并且让用户做出最终的选择：

<pre><code class=" hljs java"><span class="hljs-number">1</span>  Intent shareIntent = <span class="hljs-keyword">new</span> Intent(Intent.ACTION_SEND);
<span class="hljs-number">2</span>  shareIntent.setType(<span class="hljs-string">"text/plain"</span>);
<span class="hljs-number">3</span>  shareIntent.putExtra(Intent.EXTRA_TEXT, <span class="hljs-string">"Super Awesome Text!"</span>);
<span class="hljs-number">4</span>  startActivity(Intent.createChooser(shareIntent, <span class="hljs-string">"Share this text using…"</span>));</code></pre>

第1行使用构造方法<code>public Intent(String action)</code>根据指定action创建了一个<code>Intent</code>；

ACTION_SEND表示会向别的应用*发送数据*。在本例中，要传递的信息是“Super Awesome Text!（超酷的文本）”。但是目前为止还不知道要传给谁。最终，这将由用户决定。

第2行设置MIME数据的类型为text/plain。

第3行将要传递的数据(超酷文本)通过<code>exstra</code>放到Intent中去。

第4行会触发本例的用户选择功能。其中<code>Intent.createChooser</code>是将Intent重新封装，将其action指定为ACTION_CHOOSER。

这里面没什么特别复杂的东西。这个action就是用来弹出选择界面的，也就是说让用户自己选择处理方式。某些场景下，你可能会设计呈现更加具体的选择（比如用户正在发送email，可以直接给用户提供统默认的邮件客户端），但是就本例而言，任何能够处理我们要分享的文本的应用都会被纳入选择清单。

具体的运行效果（选择列表太长了，得滚动着来看）如下：

<p><img alt="image" src="http://www.objc.io/images/issue-11/android-chooser.gif"></p>

而后我选择了用Google Translate来处理文本，结果如下：

<p><img alt="image" src="http://www.objc.io/images/issue-11/android-translate.jpg"></p>

Google Translate将刚刚的“超酷文本”翻译成了意大利文。

##再给出一个例子

总结之前，再看个例子。这次会展示如何分享和接收一张图片。也就是说，当用户分享图片时，让我们的app出现在用户的分享选择列表中。

在<code>AndroidManifest</code>做如下配置：

<pre><code class=" hljs ">1    &lt;activity android:name="ImageActivity"&gt;
2        &lt;intent-filter&gt;
3            &lt;action android:name="android.intent.action.SEND"/&gt;
4            &lt;category android:name="android.intent.category.DEFAULT"/&gt;
5            &lt;data android:mimeType="image/*"/&gt;
6        &lt;/intent-filter&gt;
7    &lt;/activity&gt;</code></pre>

注意，至少要配置一个action和一个category。

第3行将action配置为SEND，表示可以配置SEND类型的actions。

第4行声明category为DEFAULT。当使用<code>startActivity()</code>的时候，会默认添加category。

第5行很重要，是将MIME type设置为*任何类型的图片*。

接下来，在<code>ImageActivity</code>中对Intent的处理如下：

<pre><code class=" hljs java"><span class="hljs-number">1</span>    <span class="hljs-annotation">@Override</span>
<span class="hljs-number">2</span>    <span class="hljs-keyword">protected</span> <span class="hljs-keyword">void</span> <span class="hljs-title">onCreate</span>(Bundle savedInstanceState) {
<span class="hljs-number">3</span>        <span class="hljs-keyword">super</span>.onCreate(savedInstanceState);
<span class="hljs-number">4</span>        setContentView(R.layout.main);
<span class="hljs-number">5</span>        
<span class="hljs-number">6</span>        <span class="hljs-comment">// Deal with the intent (if any)</span>
<span class="hljs-number">7</span>        Intent intent = getIntent();
<span class="hljs-number">8</span>        <span class="hljs-keyword">if</span> ( intent != <span class="hljs-keyword">null</span> ) {
<span class="hljs-number">9</span>            <span class="hljs-keyword">if</span> (intent.getType().indexOf(<span class="hljs-string">"image/"</span>) != -<span class="hljs-number">1</span>) {
<span class="hljs-number">10</span>                 Uri data = intent.getData();
<span class="hljs-number">11</span>                 <span class="hljs-comment">// handle the image…</span>
<span class="hljs-number">12</span>            } 
<span class="hljs-number">13</span>        }
<span class="hljs-number">14</span>    }</code></pre>

有关的处理代码在第9行，在检查Intent中是否包含图片数据。

接下来来看看*分享*图片的处理代码：

<pre><code class=" hljs java"><span class="hljs-number">1</span>    Uri imageUri = Uri.parse(<span class="hljs-string">"/path/to/image.png"</span>);
<span class="hljs-number">2</span>    Intent intent = <span class="hljs-keyword">new</span> Intent(Intent.ACTION_SEND);
<span class="hljs-number">3</span>    intent.setType(<span class="hljs-string">"image/png"</span>);    
<span class="hljs-number">4</span>    intent.putExtra(Intent.EXTRA_STREAM, imageUri);
<span class="hljs-number">5</span>    startActivity(Intent.createChooser(intent , <span class="hljs-string">"Share"</span>));</code></pre>

关键代码在第3行，定义了MIME类型（只有IntentFilters匹配到的应用才会出现在选择列表中），第4行是将要分享的数据放入Intent中。

最后，第5行创建了之前看到过的*选择*对话框，其中只有能够处理<code>image/png</code>的应用才会出现在选择对话框的列表中。

##总结

我们从大体上介绍了什么Intent，它能做些什么，以及如何在Android中分享信息，但是还有很多内容本文没有涵盖。Intent这种机制非常强大，相比较于iOS设备而言，Android这个特性提供了非常便捷的用户体验。iOS用户（包括我在内）会觉得频繁的返回主界面或者操作任务切换是非常低效的。

当然，这也并不意味着在应用之间分享数据这方面Android的技术就是更好的或者说其实现方式更高级。归根结底，这是个人喜好问题，就像有些iOS用户就不喜欢Android设备的*返回键*而Android用户却特别中意。理由是这些Android用户觉得返回键标准、高效且位置固定，总是在*home*键旁。

我记得我在西班牙生活的时候，曾经听过一个很棒的谚语： “Colors were created so we can all have different tastes”（大概是说“各花入各眼，存在即合理”）。

##延伸阅读

* [Intents and Filters](http://developer.android.com/guide/components/intents-filters.html)
* [Intents](http://developer.android.com/reference/android/content/Intent.html)
* [Common Intents](http://developer.android.com/guide/components/intents-common.html)
* [Integrating Application with Intents](http://android-developers.blogspot.com.es/2009/11/integrating-application-with-intents.html)
* [Sharing Simple Data](http://developer.android.com/training/sharing/index.html)

<div class="footnotes"><hr><ol><li id="fn:1">
<p>Activities are the components that provide a user interface for a single screen in your application.</p>
<a href="#fnref:1" rev="footnote">↩</a></li><li id="fn:2">
<p>A fragment represents a behavior or a portion of user interface in an activity.</p>
<a href="#fnref:2" rev="footnote">↩</a></li><li id="fn:3">
<p>A mapping from string values to various Parcelable types.</p>
<a href="#fnref:3" rev="footnote">↩</a></li><li id="fn:4">
<p>A service is an application component representing an application’s desire to either perform a longer-running operation while not interacting with the user, or to supply functionality for other applications to use.</p>
<a href="#fnref:4" rev="footnote">↩</a></li><li id="fn:5">
<p><a href="http://developer.android.com/reference/android/content/pm/PackageManager.html">PackageManager</a>: class for retrieving various kinds of information related to the application packages that are currently installed on the device.</p>
<a href="#fnref:5" rev="footnote">↩</a></li></ol></div>



















































































