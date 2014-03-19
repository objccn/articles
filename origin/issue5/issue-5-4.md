[Source](http://www.objc.io/issue-5/from-nsurlconnection-to-nsurlsession.html "Permalink to From NSURLConnection to NSURLSession - iOS 7 - objc.io issue #5 ")

# From NSURLConnection to NSURLSession - iOS 7 - objc.io issue #5 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# From NSURLConnection to NSURLSession

[Issue #5 iOS 7][4], October 2013

By [Mattt Thompson][5]

One of the more significant changes in iOS 7 and Mac OS X 10.9 Mavericks was the overhaul of the Foundation URL Loading System.

As someone [steeped in Apple’s networking infrastructure][6], I thought it would be useful to share my thoughts and impressions of these new APIs, how they will change the way we build apps, and what they signify in terms of the evolution of API design philosophies.

`NSURLConnection` got its start a decade ago, with the original release of Safari in 2003, as an abstraction on top of the Core Foundation / CFNetwork APIs. The name `NSURLConnection` actually refers to a group of the interrelated components that form the Foundation URL Loading System: `NSURLRequest`, `NSURLResponse`, `NSURLProtocol`, `NSURLCache`, `NSHTTPCookieStorage`, `NSURLCredentialStorage`, and its namesake, `NSURLConnection`.

`NSURLRequest` objects are passed to an `NSURLConnection` object. The delegate (conforming to the erstwhile informal `` and `` protocols) responds asynchronously as an `NSURLResponse`, and any associated `NSData` are sent from the server.

Before a request is sent to the server, the shared cache is consulted, and depending on the policy and availability, a cached response may be returned immediately and transparently. If no cached response is available, the request is made with the option to cache its response for any subsequent requests.

In the process of negotiating a request to a server, that server may issue an authentication challenge, which is either handled automatically by the shared cookie or credential storage, or by the connection delegate. Outgoing requests could also be intercepted by a registered `NSURLProtocol` object to seamlessly change loading behavior as necessary.

For better or worse, `NSURLConnection` has served as the networking infrastructure for hundreds of thousands of Cocoa and Cocoa Touch applications, and has held up rather well, considering. But over the years, emerging use cases–on the iPhone and iPad, especially–have challenged several core assumptions, and created cause for refactoring.

At WWDC 2013, Apple unveiled the successor to `NSURLConnection`: `NSURLSession`.

* * *

Like `NSURLConnection`, `NSURLSession` refers to a group of interdependent classes, in addition to the eponymous class `NSURLSession`. `NSURLSession` is comprised of the same pieces as before, with `NSURLRequest`, `NSURLCache`, and the like, but replaces `NSURLConnection` with `NSURLSession`, `NSURLSessionConfiguration`, and three subclasses of `NSURLSessionTask`: `NSURLSessionDataTask`, `NSURLSessionUploadTask`, and `NSURLSessionDownloadTask`.

The most immediate improvement `NSURLSession` provides over `NSURLConnection` is the ability to configure per-session cache, protocol, cookie, and credential policies, rather than sharing them across the app. This allows the networking infrastructure of frameworks and parts of the app to operate independently, without interfering with one another. Each `NSURLSession` object is initialized with an `NSURLSessionConfiguration`, which specifies these policies, as well a number of new options specifically added to improve performance on mobile devices.

The other big part of `NSURLSession` is session tasks, which handle the loading of data, as well as uploading and downloading files and data between the client and server. `NSURLSessionTask` is most analogous to `NSURLConnection` in that it is responsible for loading data, with the main difference being that tasks share the common delegate of their parent `NSURLSession`.

We’ll dive into tasks first, and then talk more about session configuration later on.

## NSURLSessionTask

`NSURLSessionTask` is an abstract subclass, with three concrete subclasses that are used directly: `NSURLSessionDataTask`, `NSURLSessionUploadTask`, and `NSURLSessionDownloadTask`. These three classes encapsulate the three essential networking tasks of modern applications: fetching data, such as JSON or XML, and uploading and downloading files.

![NSURLSessionTask class diagram][7]

When an `NSURLSessionDataTask` finishes, it has associated data, whereas an `NSURLSessionDownloadTask` finishes with a temporary file path for the downloaded file. `NSURLSessionUploadTask` inherits from `NSURLSessionDataTask`, since the server response of an upload often has associated data. ￼￼￼ All tasks are cancelable, and can be paused and resumed. When a download task is canceled, it has the option to create _resume data_, which can then be passed when creating a new download task to pick up where it left off.

Rather than being `alloc-init`‘d directly, tasks are created by an `NSURLSession`. Each task constructor method has a version with and without a `completionHandler` property, for example `–dataTaskWithRequest:` and `–dataTaskWithRequest:completionHandler:`. Similar to `NSURLConnection -sendAsynchronousRequest:queue:completionHandler:`, specifying a `completionHandler` creates an implicit delegate to be used instead of the task’s session. For any cases where a session task delegate’s default behavior needs to be overridden, the less convenient non-`completionHandler` variant would need to be used.

### Constructors

In iOS 5, `NSURLConnection` added the method `sendAsynchronousRequest:queue:completionHandler:`, which greatly simplified its use for one-off requests, and offered an asynchronous alternative to `-sendSynchronousRequest:returningResponse:error:`:


     NSURL *URL = [NSURL URLWithString:@"http://example.com"];
     NSURLRequest *request = [NSURLRequest requestWithURL:URL];

     [NSURLConnection sendAsynchronousRequest:request
                                        queue:[NSOperationQueue mainQueue]
                            completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
         // ...
     }];

`NSURLSession` iterates on this pattern with its task constructor methods. Rather than running immediately, the task object is returned to allow for further configuration before being kicked off with `-resume`.

Data tasks can be created with either an `NSURL` or `NSURLRequest` (the former being a shortcut for a standard `GET` request to that URL):


     NSURL *URL = [NSURL URLWithString:@"http://example.com"];
     NSURLRequest *request = [NSURLRequest requestWithURL:URL];

     NSURLSession *session = [NSURLSession sharedSession];
     NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                             completionHandler:
         ^(NSData *data, NSURLResponse *response, NSError *error) {
             // ...
         }];

     [task resume];

Upload tasks can also be created with a request and either an `NSData` object for a URL to a local file to upload:


     NSURL *URL = [NSURL URLWithString:@"http://example.com/upload"];
     NSURLRequest *request = [NSURLRequest requestWithURL:URL];
     NSData *data = ...;

     NSURLSession *session = [NSURLSession sharedSession];
     NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                                fromData:data
                                                       completionHandler:
         ^(NSData *data, NSURLResponse *response, NSError *error) {
             // ...
         }];

     [uploadTask resume];

Download requests take a request as well, but differ in their `completionHandler`. Rather than being returned all at once upon completion, as data and upload tasks, download tasks have their data written to a local temp file. It’s the responsibility of the completion handler to move the file from its temporary location to a permanent location, which is then the return value of the block:


     NSURL *URL = [NSURL URLWithString:@"http://example.com/file.zip"];
     NSURLRequest *request = [NSURLRequest requestWithURL:URL];

     NSURLSession *session = [NSURLSession sharedSession];
     NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request
                                                             completionHandler:
        ^(NSURL *location, NSURLResponse *response, NSError *error) {
            NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            NSURL *documentsDirectoryURL = [NSURL fileURLWithPath:documentsPath];
            return [documentsDirectoryURL URLByAppendingPathComponent:[[response URL] lastPathComponent]];
        }];

     [downloadTask resume];

### NSURLSession & NSURLConnection Delegate Methods

Overall, the delegate methods of `NSURLSession` are a marked improvement over the rather ad-hoc pattern that emerged over the decade of `NSURLConnection`’s evolution. For a complete overview, check out this [mapping table][8].

A few specific observations:

NSURLSession has both session and task delegate methods for handling authentication challenge. The session delegate method handles connection level concerns, such as Server Trust and Client Certificate evaluation, NTLM, and Kerberos, while the task delegate handles request-based challenges, such as Basic, Digest, or Proxy authentication.

Whereas `NSURLConnection` has two methods that signal that a request has finished (`NSURLConnectionDataDelegate -connectionDidFinishLoading:` and `NSURLConnectionDelegate -connection:didFailWithError:`), there is a single delegate method for `NSURLSession` (`NSURLSessionTaskDelegate -URLSession:task:didCompleteWithError:`)

Delegate methods signaling the transfer of a certain number of bytes use parameters with the `int64_t` type in `NSURLSession`, as compared to `long long` used by `NSURLConnection`.

NSURLSession introduces a new pattern to Foundation delegate methods with its use of `completionHandler:` parameters. This allows delegate methods to safely be run on the main thread without blocking; a delegate can simply `dispatch_async` to the background, and call the `completionHandler` when finished. It also effectively allows for multiple return values, without awkward argument pointers. In the case of `NSURLSessionTaskDelegate -URLSession:task:didReceiveChallenge:completionHandler:`, for example, `completionHandler` takes two arguments: the authentication challenge disposition, and the credential to be used, if applicable.

> For more information about session tasks, check out [WWDC Session 705: “What’s New in Foundation Networking”][9]

## NSURLSessionConfiguration

`NSURLSessionConfiguration` objects are used to initialize `NSURLSession` objects. Expanding on the options available on the request level with `NSMutableURLRequest`, `NSURLSessionConfiguration` provides a considerable amount of control and flexibility on how a session makes requests. From network access properties, to cookie, security, and caching policies, as well as custom protocols, launch event settings, and several new properties for mobile optimization, you’ll find what you’re looking for with `NSURLSessionConfiguration`.

Sessions copy their configuration on initialization, and though `NSURLSession` has a `readonly` `configuration` property, changes made on that object have no effect on the policies of the session. Configuration is read once on initialization, and set in stone after that.

### Constructors

There are three class constructors for `NSURLSessionConfiguration`, which do well to illustrate the different use cases for which `NSURLSession` is designed.

`%2BdefaultSessionConfiguration` returns the standard configuration, which is effectively the same as the `NSURLConnection` networking stack, with the same shared `NSHTTPCookieStorage`, shared `NSURLCache`, and shared `NSURLCredentialStorage`.

`%2BephemeralSessionConfiguration` returns a configuration preset with no persistent storage for caches, cookies, or credentials. This would be ideal for a feature like private browsing.

`%2BbackgroundSessionConfiguration:` is unique in that it creates a _background session_. Background sessions differ from regular, run-of-the-mill sessions in that they can run upload and download tasks even when the app is suspended, exits, or crashes. The identifier specified during initialization is used to provide context to any daemons that may resume background transfers out of process.

> For more information about background sessions, check out [WWDC Session 204: “What’s New with Multitasking”][10]

### Properties

There are 20 properties on `NSURLSessionConfiguration`. Having a working knowledge of what they are will allow apps to make the most of its networking environments.

#### General

`HTTPAdditionalHeaders` specifies a set of default headers to be set on outbound requests. This is useful for information that is shared across a session, such as content type, language, user agent, and authentication:


    NSString *userPasswordString = [NSString stringWithFormat:@"%@:%@", user, password];
    NSData * userPasswordData = [userPasswordString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64EncodedCredential = [userPasswordData base64EncodedStringWithOptions:0];
    NSString *authString = [NSString stringWithFormat:@"Basic %@", base64EncodedCredential];
    NSString *userAgentString = @"AppName/com.example.app (iPhone 5s; iOS 7.0.2; Scale/2.0)";

    configuration.HTTPAdditionalHeaders = @{@"Accept": @"application/json",
                                            @"Accept-Language": @"en",
                                            @"Authorization": authString,
                                            @"User-Agent": userAgentString};

`networkServiceType` distinguishes between standard network traffic, VOIP, voice, video, and traffic used by a background process. Most applications won’t need to set this.

`allowsCellularAccess` and `discretionary` are used to save bandwidth over cellular connections. It is recommended that the `discretionary` property is used instead of `allowsCellularAccess` for background transfers, as it takes WiFi and power availability into account.

`timeoutIntervalForRequest` and `timeoutIntervalForResource` specify the timeout interval for the request as well as the resource. Many developers have used the `timeoutInterval` in an attempt to limit the total amount of time spent making the request, rather than what it actually represents: the amount of time between packets. `timeoutIntervalForResource` actually provides that overall timeout, which should only really be used for background transfers, rather than anything a user might actually want to wait for.

`HTTPMaximumConnectionsPerHost` is a new configuration option for the Foundation URL Loading System. It used to be that `NSURLConnection` would manage a private connection pool. Now with `NSURLSession`, developers can limit that number of concurrent connections to a particular host, should the need arise.

`HTTPShouldUsePipelining` can be found on `NSMutableURLRequest` as well, and can be used to turn on [HTTP pipelining][11], which can dramatically reduce loading times of requests, but is not widely supported by servers, and is disabled by default.

`sessionSendsLaunchEvents` is another new property that specifies whether the session should be launched from the background.

`connectionProxyDictionary` specifies the proxies used by connections in the sessions. Again, most consumer-facing applications don’t deal with proxies, so it’s unlikely that this property would need to be configured.

> Additional information about connection proxies can be found in the [`CFProxySupport` Reference][12].

#### Cookie Policies

`HTTPCookieStorage` is the cookie storage used by the session. By default, `NSHTTPCookieShorage %2BsharedHTTPCookieStorage` is used, which is the same as `NSURLConnection`.

`HTTPCookieAcceptPolicy` determines the conditions in which the session should accept cookies sent from the server.

`HTTPShouldSetCookies` specifies whether requests should use cookies from the session `HTTPCookieStorage`.

#### Security Policies

`URLCredentialStorage` is the credential storage used by the session. By default, `NSURLCredentialStorage %2BsharedCredentialStorage` is used, which is the same as `NSURLConnection`.

`TLSMaximumSupportedProtocol` and `TLSMinimumSupportedProtocol` determine the supported `SSLProtocol` versions for the session.

#### Caching Policies

`URLCache` is the cache used by the session. By default, `NSURLCache %2BsharedURLCache` is used, which is the same as `NSURLConnection`.

`requestCachePolicy` specifies when a cached response should be returned for a request. This is equivalent to `NSURLRequest -cachePolicy`.

#### Custom Protocols

`protocolClasses` is a session-specific array of registered `NSURLProtocol` classes.

## Conclusion

The changes to the URL Loading System in iOS 7 and Mac OS X 10.9 Mavericks are a thoughtful and natural evolution of `NSURLConnection`. Overall, the Foundation Team did an amazing job of identifying and anticipating the existing and emerging use cases of mobile developers, by creating genuinely useful APIs that lend themselves well to everyday tasks.

While certain decisions in the architecture of session tasks are a step backward in terms of composability and extensibility, `NSURLSession` nonetheless serves as a great foundation for higher-level networking functionality.




* * *

[More articles in issue #5][13]

  * [Privacy policy][14]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-5/index.html
   [5]: http://twitter.com/mattt
   [6]: http://afnetworking.com
   [7]: http://www.objc.io/images/issue-5/NSURLSession.png
   [8]: https://gist.github.com/dkduck/6870499
   [9]: http://asciiwwdc.com/2013/sessions/705
   [10]: http://asciiwwdc.com/2013/sessions/204
   [11]: http://en.wikipedia.org/wiki/HTTP_pipelining
   [12]: https://developer.apple.com/library/mac/documentation/CoreFoundation/Reference/CFProxySupport/Reference/reference.html
   [13]: http://www.objc.io/issue-5
   [14]: http://www.objc.io/privacy.html
