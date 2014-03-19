[Source](http://www.objc.io/issue-5/multitasking.html "Permalink to Multitasking in iOS 7 - iOS 7 - objc.io issue #5 ")

# Multitasking in iOS 7 - iOS 7 - objc.io issue #5 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# Multitasking in iOS 7

[Issue #5 iOS 7][4], October 2013

By [David Caunt][5]

Prior to iOS 7, developers were pretty limited in what they could do when their apps left the foreground. Aside from VOIP and location-based features, the only way to execute code in the background was to use background tasks, restricted to running for a few minutes. If you wanted to download a large video for offline viewing, or backup a user’s photos to your server, you could only complete part of the work.

iOS 7 adds two new APIs for updating your app’s UI and content in the background. The first, Background Fetch, allows you to fetch new content from the network at regular intervals. The second, Remote Notifications, is a new feature leveraging Push Notifications to notify an app when an event has occurred. Both of these new mechanisms help you to keep your app’s interface up to date, and can schedule work on the new Background Transfer Service, which allows you to perform out-of-process network transfers (downloads and uploads).

Background Fetch and Remote Notifications are simple application delegate hooks with 30 seconds of wall-clock time to perform work before your app is suspended. They’re not intended for CPU intensive work or long running tasks, rather, they are for queuing up long-running networking requests, like a large movie download, or performing quick content updates.

From a user’s perspective, the only obvious change to multitasking is the new app switcher, which displays a snapshot of each app’s UI as it was when it left the foreground. But there’s a reason for displaying the snapshots – you can now update your app’s snapshot after you complete background work, showing a preview of new content. Social networking, news, or weather apps can now display the latest content without the user having to open the app. We’ll see how to update the snapshot later.

## Background Fetch

Background Fetch is a kind of smart polling mechanism which works best for apps that have frequent content updates, like social networking, news, or weather apps. The system wakes up the app based on a user’s behavior, and aims to trigger background fetches in advance of the user launching the app. For example, if the user always uses an app at 1 p.m., the system learns and adapts, performing fetches ahead of usage periods. Background fetches are coalesced across apps by the device’s radio in order to reduce battery usage, and if you report that new data was not available during a fetch, iOS can adapt, using this information to avoid fetches at quiet times.

The first step in enabling Background Fetch is to specify that you’ll use the feature in the [`UIBackgroundModes`][6] key in your info plist. The easiest way to do this is to use the new Capabilities tab in Xcode 5’s project editor, which includes a Background Modes section for easy configuration of multitasking options.

![A screenshot showing Xcode 5’s new Capabilities tab][7]

Alternatively, you can edit the key manually:


    UIBackgroundModes
    
        fetch
    

Next, tell iOS how often you’d like to fetch:


    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
    {
        [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

        return YES;
    }

The default fetch interval is never, so you’ll need to set a time interval or the app won’t ever be called in the background. The value of `UIApplicationBackgroundFetchIntervalMinimum` asks the system to manage when your app is woken, as often as possible, but you should specify your own time interval if this is unnecessary. For example, a weather app might only update conditions hourly. iOS will wait at least the specified time interval between background fetches.

If your application allows a user to logout, and you know that there won’t be any new data, you may want to set the `minimumBackgroundFetchInterval` back to `UIApplicationBackgroundFetchIntervalNever` to be a good citizen and to conserve resources.

The final step is to implement the following method in your application delegate:


    - (void)                application:(UIApplication *)application
      performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
    {
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];

        NSURL *url = [[NSURL alloc] initWithString:@"http://yourserver.com/data.json"];
        NSURLSessionDataTask *task = [session dataTaskWithURL:url
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

            if (error) {
                completionHandler(UIBackgroundFetchResultFailed);
                return;
            }

            // Parse response/data and determine whether new content was available
            BOOL hasNewData = ...
            if (hasNewData) {
                completionHandler(UIBackgroundFetchResultNewData);
            } else {
                completionHandler(UIBackgroundFetchResultNoData);
            }
        }];

        // Start the task
        [task resume];
    }

This is where you can perform work when you are woken by the system. Remember, you only have 30 seconds to determine whether new content is available, to process the new content, and to update your UI. This should be enough time to fetch data from the network and to fetch a few thumbnails for your UI, but not much more. When your network requests are complete and your UI has been updated, you should call the completion handler.

The completion handler serves two purposes. First, the system measures the power used by your process and records whether new data was available based on the `UIBackgroundFetchResult` argument you passed. Second, when you call the completion handler, a snapshot of your UI is taken and the app switcher is updated. The user will see the new content when he or she is switching apps. This completion handler snapshotting behavior is common to all of the completion handlers in the new multitasking APIs.

In a real-world application, you should pass the `completionHandler` to sub-components of your application and call it when you’ve processed data and updated your UI.

At this point, you might be wondering how iOS can snapshot your app’s UI when it is running in the background, and how the application lifecycle works with Background Fetch. If your app is currently suspended, the system will wake it before calling `application: performFetchWithCompletionHandler:`. If your app is not running, the system will launch it, calling the usual delegate methods, including `application: didFinishLaunchingWithOptions:`. You can think of it as the app running exactly the same way as if the user had launched it from Springboard, except the UI is invisible, rendered offscreen.

In most cases, you’ll perform the same work when the application launches in the background as you would in the foreground, but you can detect background launches by looking at the [`applicationState`][8] property of UIApplication:


    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
    {
        NSLog(@"Launched in background %d", UIApplicationStateBackground == application.applicationState);

        return YES;
    }

### Testing Background Fetch

There are two ways you can simulate a background fetch. The easiest method is to run your application from Xcode and click _Simulate Background Fetch_ under Xcode’s Debug menu while your app is running.

Alternatively, you can use a scheme to change how Xcode runs your app. Under the Xcode menu item Product, choose Scheme and then Manage Schemes. From here, edit or add a new scheme and check the _Launch due to a background fetch event_ checkbox as shown below.

![A screenshot showing Xcode 5’s scheme editor][9]

## Remote Notifications

Remote notifications allow you to notify your app when important events occur. You might have new instant messages to deliver, breaking news alerts to send, or the latest episode of your user’s favorite TV show ready for him or her to download for offline viewing. Remote notifications are great for sporadic but immediately important content, where the delay between background fetches might not be acceptable. Remote Notifications can also be much more efficient than Background Fetch, as your application only launches when necessary.

A Remote Notification is really just a normal Push Notification with the `content-available` flag set. You might send a push with an alert message informing the user that something has happened, while you update the UI in the background. But Remote Notifications can also be silent, containing no alert message or sound, used only to update your app’s interface or trigger background work. You might then post a local notification when you’ve finished downloading or processing the new content.

Silent push notifications are rate-limited, so don’t be afraid of sending as many as your application needs. iOS and the APNS servers will control how often they are delivered, and you won’t get into trouble for sending too many. If your push notifications are throttled, they might be delayed until the next time the device sends a keep-alive packet or receives another notification.

### Sending Remote Notifications

To send a remote notification, set the content-available flag in a push notification payload. The content-available flag is the same key used to notify Newsstand apps, so most push scripts and libraries already support remote notifications. When you’re sending a Remote Notification, you might also want to include some data in the notification payload, so your application can reference the event. This could save you a few networking requests and increase the responsiveness of your app.

I recommend using [Nomad CLI’s Houston][10] utility to send push messages while developing, but you can use your favorite library or script.

You can install Houston as part of the nomad-cli ruby gem:


    gem install nomad-cli

And then send a notification with the apn utility included in Nomad


    # Send a Push Notification to your Device
    apn push  -c /path/to/key-cert.pem -n -d content-id=42

Here the `-n` flag specifies that the content-available key should be included, and `-d` allows us to add our own data keys to the payload.

The resulting notification payload looks like this:


    {
        "aps" : {
            "content-available" : 1
        },
        "content-id" : 42
    }

iOS 7 adds a new application delegate method, which is called when a push notification with the content-available key is received:


    - (void)           application:(UIApplication *)application
      didReceiveRemoteNotification:(NSDictionary *)userInfo
            fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
    {
        NSLog(@"Remote Notification userInfo is %@", userInfo);

        NSNumber *contentID = userInfo[@"content-id"];
        // Do something with the content ID
        completionHandler(UIBackgroundFetchResultNewData);
    }

Again, the app is launched into the background and given 30 seconds to fetch new content and update its UI, before calling the completion handler. We could perform a quick network request as we did in the Background Fetch example, but let’s use the powerful new Background Transfer Service to enqueue a large download task and see how we can update our UI when it completes.

## NSURLSession and Background Transfer Service

While `NSURLSession `is a new class in iOS 7, it also refers to the new technology in Foundation networking. Intended to replace `NSURLConnection`, familiar concepts and classes such as `NSURL`, `NSURLRequest`, and `NSURLResponse` are preserved. You’ll work with `NSURLConnection`’s replacement, `NSURLSessionTask`, to make network requests and handle their responses. There are three types of session tasks – data, download, and upload – each of which add syntactic sugar to `NSURLSessionTask`, so you should use the appropriate one for your use case.

An `NSURLSession` coordinates one or more of these `NSURLSessionTask`s and behaves according to the `NSURLSessionConfiguration` with which it was created. You may create multiple `NSURLSession`s to group related tasks with the same configuration. To interact with the Background Transfer Service, you’ll create a session configuration using [`NSURLSessionConfiguration backgroundSessionConfiguration]`. Tasks added to a background session are run in an external process and continue even if your app is suspended, crashes, or is killed.

[`NSURLSessionConfiguration`][11] allows you to set default HTTP headers, configure cache policies, restrict cellular network usage, and more. One option is the `discretionary` flag, which allows the system to schedule tasks for optimal performance. What this means is that your transfers will only go over Wifi when the device has sufficient power. If the battery is low, or only a cellular connection is available, your task won’t run. The `discretionary` flag only has an effect if the session configuration object has been constructed by calling the [`backgroundSessionConfiguration:`][12] method and if the background transfer is initiated while your app is in the foreground. If the transfer is initiated from the background the transfer will _always_ run in discretionary mode.

Now we know a little about `NSURLSession`, and how a background session functions, let’s return to our Remote Notification example and add some code to enqueue a download on the background transfer service. When the download completes, we’ll notify the user that the file is available for use.

### NSURLSessionDownloadTask

First of all, let’s handle a Remote Notification and enqueue an `NSURLSessionDownloadTask` on the background transfer service. In `backgroundURLSession`, we create an `NURLSession` with a background session configuration and add our application delegate as the session delegate. The documentation advises against instantiating multiple sessions with the same identifier, so we use `dispatch_once` to avoid potential issues:


    - (NSURLSession *)backgroundURLSession
    {
        static NSURLSession *session = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSString *identifier = @"io.objc.backgroundTransferExample";
            NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];
            session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                    delegate:self
                                               delegateQueue:[NSOperationQueue mainQueue]];
        });

        return session;
    }

    - (void)           application:(UIApplication *)application
      didReceiveRemoteNotification:(NSDictionary *)userInfo
            fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
    {
        NSLog(@"Received remote notification with userInfo %@", userInfo);

        NSNumber *contentID = userInfo[@"content-id"];
        NSString *downloadURLString = [NSString stringWithFormat:@"http://yourserver.com/downloads/%d.mp3", [contentID intValue]];
        NSURL* downloadURL = [NSURL URLWithString:downloadURLString];

        NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
        NSURLSessionDownloadTask *task = [[self backgroundURLSession] downloadTaskWithRequest:request];
        task.taskDescription = [NSString stringWithFormat:@"Podcast Episode %d", [contentID intValue]];
        [task resume];

        completionHandler(UIBackgroundFetchResultNewData);
    }

We create a download task using the `NSURLSession` class method and configure its request, and provide a description for use later. You must remember to call [`task resume]` to actually start the task, as all session tasks begin in the suspended state.

Now we need to implement the `NSURLSessionDownloadDelegate` methods to receive callbacks when the download completes. You may also need to implement `NSURLSessionDelegate` or `NSURLSessionTaskDelegate` methods if you need to handle authentication or other events in the session lifecycle. You should consult Apple’s document [Life Cycle of a URL Session with Custom Delegates][13], which explains the full life cycle across all types of session tasks.

None of the `NSURLSessionDownloadDelegate` delegate methods are optional, though the only one where we need to take action in this example is [`NSURLSession downloadTask:didFinishDownloadingToURL:]`. When the task finishes downloading, you’re provided with a temporary URL to the file on disk. You must move or copy the file to your app’s storage, as it will be removed from temporary storage when you return from this delegate method.


    #Pragma Mark - NSURLSessionDownloadDelegate

    - (void)         URLSession:(NSURLSession *)session
                   downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didFinishDownloadingToURL:(NSURL *)location
    {
        NSLog(@"downloadTask:%@ didFinishDownloadingToURL:%@", downloadTask.taskDescription, location);

        // Copy file to your app's storage with NSFileManager
        // ...

        // Notify your UI
    }

    - (void)  URLSession:(NSURLSession *)session
            downloadTask:(NSURLSessionDownloadTask *)downloadTask
       didResumeAtOffset:(int64_t)fileOffset
      expectedTotalBytes:(int64_t)expectedTotalBytes
    {
    }

    - (void)         URLSession:(NSURLSession *)session
                   downloadTask:(NSURLSessionDownloadTask *)downloadTask
                   didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten
      totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
    {
    }

If your app is still running in the foreground when the background session task completes, the above code will be sufficient. In most cases, however, your app won’t be running, or it will be suspended in the background. In these cases, you must implement two application delegates methods so the system can wake your application. Unlike previous delegate callbacks, the application delegate is called twice, as your session and task delegates may receive several messages. The app delegate method `application: handleEventsForBackgroundURLSession:` is called before these `NSURLSession` delegate messages are sent, and `URLSessionDidFinishEventsForBackgroundURLSession` is called afterward. In the former method, you store a background `completionHandler`, and in the latter you call it to update your UI:


    - (void)                  application:(UIApplication *)application
      handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
    {
        // You must re-establish a reference to the background session,
        // or NSURLSessionDownloadDelegate and NSURLSessionDelegate methods will not be called
        // as no delegate is attached to the session. See backgroundURLSession above.
        NSURLSession *backgroundSession = [self backgroundURLSession];

        NSLog(@"Rejoining session with identifier %@ %@", identifier, backgroundSession);

        // Store the completion handler to update your UI after processing session events
        [self addCompletionHandler:completionHandler forSession:identifier];
    }

    - (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
    {
        NSLog(@"Background URL session %@ finished events.
    ", session);

        if (session.configuration.identifier) {
            // Call the handler we stored in -application:handleEventsForBackgroundURLSession:
            [self callCompletionHandlerForSession:session.configuration.identifier];
        }
    }

    - (void)addCompletionHandler:(CompletionHandlerType)handler forSession:(NSString *)identifier
    {
        if ([self.completionHandlerDictionary objectForKey:identifier]) {
            NSLog(@"Error: Got multiple handlers for a single session identifier.  This should not happen.
    ");
        }

        [self.completionHandlerDictionary setObject:handler forKey:identifier];
    }

    - (void)callCompletionHandlerForSession: (NSString *)identifier
    {
        CompletionHandlerType handler = [self.completionHandlerDictionary objectForKey: identifier];

        if (handler) {
            [self.completionHandlerDictionary removeObjectForKey: identifier];
            NSLog(@"Calling completion handler for session %@", identifier);

            handler();
        }
    }

This two-stage process is necessary to update your app UI if you aren’t already in the foreground when the background transfer completes. Additionally, if the app is not running at all when the background transfer finishes, iOS will launch it into the background, and the preceding application and session delegate methods are called after `application:didFinishLaunchingWithOptions:`.

### Configuration and Limitation

We’ve briefly touched on the power of background transfers, but you should explore the documentation and look at the `NSURLSessionConfiguration` options that best support your use case. For example, `NSURLSessionTasks` support resource timeouts through the `NSURLSessionConfiguration`’s `timeoutIntervalForResource` property. You can use this to specify how long you want to allow for a transfer to complete before giving up entirely. You might use this if your content is only available for a limited time, or if failure to download or upload the resource within the given timeInterval indicates that the user doesn’t have sufficient Wifi bandwidth.

In addition to download tasks, `NSURLSession` fully supports upload tasks, so you might upload a video to your server in the background and assure your user that he or she no longer needs to leave the app running, as might have been done in iOS 6. A nice touch would be to set the `sessionSendsLaunchEvents` property of your `NSURLSessionConfiguration` to `NO`, if your app doesn’t need launching in the background when the transfer completes. Efficient use of system resources keeps both iOS and the user happy.

Finally, there are a couple of limitations in using background sessions. As a delegate is required, you can’t use the simple block-based callback methods on `NSURLSession`. Launching your app into the background is relatively expensive, so HTTP redirects are always taken. The background transfer service only supports HTTP and HTTPS and you cannot use custom protocols. The system optimizes transfers based on available resources and you cannot force your transfer to progress in the background at all times.

Also note that `NSURLSessionDataTasks` are not supported in background sessions at all, and you should only use these tasks for short-lived, small requests, not for downloads or uploads.

## Summary

The powerful new multitasking and networking APIs in iOS 7 open up a whole range of possibilities for both new and existing apps. Consider the use cases in your app which can benefit from out-of-process network transfers and fresh data, and make the most of these fantastic new APIs. In general, implement background transfers as if your application is running in the foreground, making appropriate UI updates, and most of the work is already done for you.

  * Use the appropriate new API for your app’s content.
  * Be efficient, and call completion handlers as early as possible.
  * Completion handlers update your app’s UI snapshot.

## Further Reading

  * [WWDC 2013 session “What’s New with Multitasking”][14]
  * [WWDC 2013 session “What’s New in Foundation Networking”][15]
  * [URL Loading System Programming Guide][16]




* * *

[More articles in issue #5][17]

  * [Privacy policy][18]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-5/index.html
   [5]: https://twitter.com/dcaunt
   [6]: https://developer.apple.com/library/ios/documentation/general/Reference/InfoPlistKeyReference/Articles/iPhoneOSKeys.html#//apple_ref/doc/uid/TP40009252-SW22
   [7]: http://www.objc.io/images/issue-5/capabilities-on-bgfetch.jpg
   [8]: https://developer.apple.com/library/ios/documentation/uikit/reference/UIApplication_Class/Reference/Reference.html#//apple_ref/doc/uid/TP40006728-CH3-SW77
   [9]: http://www.objc.io/images/issue-5/edit-scheme-simulate-background-fetch.png
   [10]: http://nomad-cli.com/#houston
   [11]: https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSessionConfiguration_class/Reference/Reference.html
   [12]: https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSessionConfiguration_class/Reference/Reference.html#//apple_ref/occ/clm/NSURLSessionConfiguration/backgroundSessionConfiguration:
   [13]: https://developer.apple.com/library/ios/documentation/cocoa/Conceptual/URLLoadingSystem/NSURLSessionConcepts/NSURLSessionConcepts.html#//apple_ref/doc/uid/10000165i-CH2-SW42
   [14]: https://developer.apple.com/wwdc/videos/?id=204
   [15]: https://developer.apple.com/wwdc/videos/?id=705
   [16]: https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html#//apple_ref/doc/uid/10000165i
   [17]: http://www.objc.io/issue-5
   [18]: http://www.objc.io/privacy.html
