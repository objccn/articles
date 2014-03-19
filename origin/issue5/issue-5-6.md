[Source](http://www.objc.io/issue-5/iOS7-hidden-gems-and-workarounds.html "Permalink to iOS 7: Hidden Gems and Workarounds - iOS 7 - objc.io issue #5 ")

# iOS 7: Hidden Gems and Workarounds - iOS 7 - objc.io issue #5 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# iOS 7: Hidden Gems and Workarounds

[Issue #5 iOS 7][4], October 2013

By [Peter Steinberger][5]

When iOS 7 was first announced, Apple developers all over the world tried to compile their apps, and spent the next few months fixing whatever was broken, or even rebuilding the app from scratch. As a result, there wasn’t much time to take a closer look at what’s new in iOS 7. Apart from the obvious great small tweaks like NSArray’s `firstObject`, which has been retroactively made public all the way back to iOS 4, there are a lot more hidden gems waiting to be discovered.

## Smooth Fade Animations

I’m not talking about the new spring animation APIs or UIDynamics, but something more subtle. CALayer gained two new methods: `allowsGroupOpacity` and `allowsEdgeAntialiasing`. Now, group opacity isn’t something particularly new. iOS was evaluating the `UIViewGroupOpacity` key in the Info.plist for quite some time and enabled/disabled this application-wide. For most apps, this was unwanted, as it decreases global performance. In iOS 7, this now is enabled by default for applications that link against SDK 7 - and since certain animations will be slower when this is enabled, it can also be controlled on the layer.

An interesting detail is that `_UIBackdropView` (which is used as the background view inside `UIToolbar` or `UIPopoverView`) can’t animate its blur if `allowsGroupOpacity` is enabled, so you might want to temporarily disable this when you do an alpha transform. Since this degrades the animation experience, you can fall back to the old way and temporarily enable `shouldRasterize` during the animation. Don’t forget setting the appropriate `rasterizationScale` or the view will look pixelerated on retina devices.

The edge antialiasing property can be useful if you want to replicate the animation that Safari does when showing all tabs.

## Blocking Animations

A small but very useful addition is [`UIView performWithoutAnimation:]`. It’s a simple wrapper that checks if animations are currently enabled, disables them, executes the block, and re-enables animations. One caveat is that this will _not_ block CoreAnimation-based animations. So don’t be too eager in replacing all your calls from:


        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        view.frame = CGRectMake(...);
        [CATransaction commit];

to:


        [UIView performWithoutAnimation:^{
            view.frame = CGRectMake(...);
        }];

However, most of the time this will do the job just fine, as long as you don’t deal with CALayers directly.

In iOS 7, I had quite a few code paths (mostly `UITableViewCells`) that needed additional protection against accidental animations, for example, if a popover is resized and at the same time the displayed table view loads up new cells because of the height change. My usual workaround is wrapping the entire `layoutSubviews` into the animation-block-method:


    - (void)layoutSubviews
    {
        // Otherwise the popover animation could leak into our cells on iOS 7 legacy mode.
        [UIView performWithoutAnimation:^{
            [super layoutSubviews];
            _renderView.frame = self.bounds;
        }];
    }

## Dealing with Long Table Views

`UITableView` is very efficient and fast, unless you begin using `tableView:heightForRowAtIndexPath:`, where it starts calling this for _every_ element in your table, even the non-visible ones - just so that the underlying `UIScrollView` can get the correct `contentSize`. There were some workarounds before, but nothing great. In iOS 7, Apple finally acknowledged the problem and added `tableView:estimatedHeightForRowAtIndexPath:`, which defers most of the cost down to actual scrolling time. If you don’t know the size of a cell at all, simply return `UITableViewAutomaticDimension`.

There’s now a similar API for section headers/footers as well.

## UISearchDisplayController

Apple’s search controller learned a new trick to simplify moving the search bar into the navigation bar. Enable `displaysSearchBarInNavigationBar` for that (unless you also use a scope bar - then you’re out of luck.) Now I would love to write that that’s it, but sadly, `UISearchDisplayController` seems to be terribly broken on iOS 7, especially on iPad. Apple seems to have run out of time, so showing the search results will not hide the actual table view. Before 7, this wasn’t an issue, but since the `searchResultsTableView` has a transparent background color, it looks pretty bad. As a workaround, you can either set an opaque background color, or move to some [more sophisticated ways of hacking][6] to get what you expect. I’ve had very mixed results with this control, including it not showing the search table view _at all_ when using `displaysSearchBarInNavigationBar`.

Your results may vary, but I’ve required some severe hacks to get `displaysSearchBarInNavigationBar` working:


    - (void)restoreOriginalTableView
    {
        if (PSPDFIsUIKitFlatMode() && self.originalTableView) {
            self.view = self.originalTableView;
        }
    }

    - (UITableView *)tableView
    {
        return self.originalTableView ?: [super tableView];
    }

    - (void)searchDisplayController:(UISearchDisplayController *)controller
      didShowSearchResultsTableView:(UITableView *)tableView
    {
        // HACK: iOS 7 requires a cruel workaround to show the search table view.
        if (PSPDFIsUIKitFlatMode()) {
            if (!self.originalTableView) self.originalTableView = self.tableView;
            self.view = controller.searchResultsTableView;
            controller.searchResultsTableView.contentInset = UIEdgeInsetsZero; // Remove 64 pixel gap
        }
    }

    - (void)searchDisplayController:(UISearchDisplayController *)controller
      didHideSearchResultsTableView:(UITableView *)tableView
    {
        [self restoreOriginalTableView];
    }

Also, don’t forget calling `restoreOriginalTableView` in `viewWillDisappear`, or things will crash badly. Remember that this is only one solution; there might be less radical ways that don’t replace the view itself, but this really should be fixed by Apple. (TODO: RADAR!)

## Pagination

`UIWebView` learned a new trick to automatically paginate websites with `paginationMode`. There are a whole bunch of new properties related to this feature:


    @property (nonatomic) UIWebPaginationMode paginationMode NS_AVAILABLE_IOS(7_0);
    @property (nonatomic) UIWebPaginationBreakingMode paginationBreakingMode NS_AVAILABLE_IOS(7_0);
    @property (nonatomic) CGFloat pageLength NS_AVAILABLE_IOS(7_0);
    @property (nonatomic) CGFloat gapBetweenPages NS_AVAILABLE_IOS(7_0);
    @property (nonatomic, readonly) NSUInteger pageCount NS_AVAILABLE_IOS(7_0);

Now while this might not be useful for most websites, it certainly is to build simple ebook readers or display text in a nicer way. For added fun, try setting it to `UIWebPaginationModeBottomToTop`.

## Flying Popovers

Wonder why your popovers are flying around like crazy? There’s a new delegate in the `UIPopoverControllerDelegate` protocol which allows you to control the madness:


    -     (void)popoverController:(UIPopoverController *)popoverController
      willRepositionPopoverToRect:(inout CGRect *)rect
                           inView:(inout UIView **)view

`UIPopoverController` will behave if anchored to a `UIBarButtonItem`, but if you’re showing it with a view and rect, you might have to implement this method and return something sane. This took me quite a long time to figure out - it’s especially required if you dynamically resize your popovers via changing `preferredContentSize`. Apple now takes those sizing requests more serious and will move the popover around if there’s not enough space left.

## Keyboard Support

Apple didn’t only give us [a whole new framework for game controllers][7], it also gave us keyboard-lovers some attention! You’ll find new defines for common keys like `UIKeyInputEscape` or `UIKeyInputUpArrow` that can be intercepted using the all-new [`UIKeyCommand`][8] class. Before iOS 7, [unspeakable hacks were necessary to react to keyboard commands][9]. Now, let’s grab a bluetooth keyboard and see what we can do with this new hotness!

Before starting, you need some basic understanding for the responder chain. Your `UIApplication` inherits from `UIResponder`, and so does `UIView` and `UIViewController`. If you’ve ever had to deal with `UIMenuItem` and weren’t using [my block-based wrapper][10], you know this already. So events will be sent to the topmost responder and then trickle down level by level until they end at UIApplication. To capture key commands, you need to tell the system what key commands you’re interested in (there’s no catch-all). To do so, override the new `keyCommands` property:


    - (NSArray *)keyCommands
    {
        return @[[UIKeyCommand keyCommandWithInput:@"f"
                                     modifierFlags:UIKeyModifierCommand
                                            action:@selector(searchKeyPressed:)]];
    }

    - (void)searchKeyPressed:(UIKeyCommand *)keyCommand
    {
        // Respond to the event
    }

![responder-chain.png][11]

Now don’t get too excited; there are some caveats. This only works when the keyboard is visible (if there’s some first responder like `UITextView`.) For truly global hotkeys, you still need to revert to the above-linked hackery. But apart from that, the routing is very elegant. Don’t try overriding system shortcuts like cmd-V, as those will be mapped to `paste:` automatically.

There are also some new predefined responder actions like:


    - (void)increaseSize:(id)sender NS_AVAILABLE_IOS(7_0);
    - (void)decreaseSize:(id)sender NS_AVAILABLE_IOS(7_0);

which are called for cmd%2B and cmd- respectively, to increase/decrease content size.

## Match the Keyboard Background

Apple finally made [`UIInputView`][12] public, which provides a way to match the keyboard style with using `UIInputViewStyleKeyboard`. This allows you to write custom keyboards or (toolbar) extensions for the default keyboards that match the default style. This class has existed since the [dawn of time][13], but now we can finally use it without resorting to hacks.

`UIInputView` will only show a background if it’s the the _root view_ of your `inputView` or `inputAccessoryView` \- otherwise it will be transparent. Sadly, this doesn’t enable you to implement a split keyboard without fill, but it’s still better than using a simple UIToolbar. I haven’t yet seen a spot where Apple uses this new API - it still seems to use a `UIToolbar` in Safari.

## Know your Radio

While most of the carrier information has been exposed in CTTelephony as early as iOS 4, it was usually special-case and not useful. With iOS 7, Apple added one method here, the most useful of them all: `currentRadioAccessTechnology`. This allows you to know if the phone is on dog-slow GPRS, on lighting-fast LTE, or on anything in between. Now there’s no method that would give you the connection speed (since the phone can’t really know that), but it’s good enough to fine-tune a download manager to not try downloading six images _simultaneously_ when the user’s on EDGE.

Now there’s absolutely no documentation around `currentRadioAccessTechnology`, so it took some trial and error to make this work. Once you have the current value, you should register for the `CTRadioAccessTechnologyDidChangeNotification` instead of polling the property. To actually get iOS to emit those notifications, you need to carry an instance of `CTTelephonyNetworkInfo` around. Don’t try to create a new instance of `CTTelephonyNetworkInfo` inside the notification, or it’ll crash.

In this simple example, I am abusing the fact that capturing `telephonyInfo` in a block will retain it:


    CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
    NSLog(@"Current Radio Access Technology: %@", telephonyInfo.currentRadioAccessTechnology);
    [NSNotificationCenter.defaultCenter addObserverForName:CTRadioAccessTechnologyDidChangeNotification
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification *note)
    {
        NSLog(@"New Radio Access Technology: %@", telephonyInfo.currentRadioAccessTechnology);
    }];

The log output can look something like this, when the phone’s moving from Edge to 3G:


    iOS7Tests[612:60b] Current Radio Access Technology: CTRadioAccessTechnologyEdge
    iOS7Tests[612:1803] New Radio Access Technology: (null)
    iOS7Tests[612:1803] New Radio Access Technology: CTRadioAccessTechnologyHSDPA

Apple exported all string symbols so it’s easy to compare and detect the current technology.

## Core Foundation, Autorelease and You.

There’s a new helper in Core Foundation that people have been missing and hacking around for years:


    CFTypeRef CFAutorelease(CFTypeRef CF_RELEASES_ARGUMENT arg)

It does exactly what you expect it to do, and it’s quite puzzling how long it took Apple to make it public. With ARC, most people solved returning Core Foundation objects via casting them to their NS-equivalent - like returning an `NSDictionary`, even though it’s a `CFDictionaryRef` and simply using `CFBridgingRelease()`. This works well, until you need to return methods where no NS-equivalent is available, like `CFBagRef`. Then you either use id and lose any type safety, or you rename your method to `createMethod` and have to think about all the memory semantics and using CFRelease afterward. There were also hacks like [this one][14], using a non-ARC-file so you can compile it, but using CFAutorelease() is really the way to go. Also: Don’t write code using Apple’s namespace. All those custom CF-Macros are programmed to break sooner or later.

## Image Decompression

When showing an image via `UIImage`, it might need to be decompressed before it can be displayed (unless the source is a pixel buffer already). This can take significant time for JPG/PNG files and result in stuttering. Before iOS 6, this was usually solved by creating a new bitmap context and drawing the image into it. [(See how AFNetworking solves this)][15].

Starting with iOS 7, you can now force decompression directly at image creation time with the new `kCGImageSourceShouldCacheImmediately`:


    %2B (UIImage *)decompressedImageWithData:(NSData *)data
    {
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
        CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, 0, (__bridge CFDictionaryRef)@{(id)kCGImageSourceShouldCacheImmediately: @YES});

        UIImage *image = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        CFRelease(source);
        return image;
    }

I was very excited when I first found out about this, but you really shouldn’t be. In my tests, performance actually _decreased_ when I enabled immediate caching. Either this method calls up to the main thread (unlikely) or perceived performance is simply worse because it locks in `copyImageBlockSetJPEG`, which is also used when showing a non-decrypted image on the main thread. In my app, I load small preview thumbnails from the main thread, and load the large page images from a background thread. Using `kCGImageSourceShouldCacheImmediately` now blocks the main thread where only a tiny decompression would take place, with a much more expensive operation on the background thread.

![image-decompression.png][16]

There’s a lot more to image decompression which isn’t new to iOS 7, like `kCGImageSourceShouldCache`, which controls the ability where the system can automatically unload decompressed image data. Make sure you’re setting this to YES, otherwise all the extra work could be pointless. Interesting detail: Apple changed the _default_ of `kCGImageSourceShouldCache` from NO to YES with the 64-bit runtime.

## Piracy Check

Apple added a way to evaluate the App Store receipt in Lion with the new [`appStoreReceiptURL`][17] method on `NSBundle`, and finally also ported this to iOS. This allows you to check if your app was legitimately purchased or cracked. There’s another important reason for checking the receipt. It contains the _initial purchase date_, which can be very useful when moving your app from a paid model to free and in-app purchases. You can use this initial purchase date to determine if your users get the extra content free (because they already paid for it), or if they have to purchase it.

The receipt also lets you check if the app was purchased via the volume purchase program and if that license wasn’t revoked, there’s a property named `SKReceiptPropertyIsVolumePurchase` indicating that.

You need to take special care when calling `appStoreReceiptURL`, since it exists as private API on iOS 6, but will call `doesNotRecognizeSelector:` when called from user code. Check the running (foundation) version before calling. During development, there won’t be a file at the URL returned from this method. You will need to use StoreKit’s [`SKReceiptRefreshRequest`][18], also new in iOS 7, to download the certificate. Use a test user who made at least one purchase, or else it won’t work:


    // Refresh the Receipt
    SKReceiptRefreshRequest *request = [[SKReceiptRefreshRequest alloc] init];
    [request setDelegate:self];
    [request start];

Verifying the receipt requires a lot of code. You need to use OpenSSL and embed the [Apple Root Certificate][19], and you should understand some basics about certificates, [PCKS containers][20], and [ASN.1][21]. There’s some [sample code][22] out there, but you shouldn’t make it too easy for someone with less honorable intents - don’t just copy the existing validation methods, at least modify them or write your own. You don’t want a generic patcher app to undo your hard work in seconds.

You should definitely read Apple’s guide on [Validating Mac App Store Receipts][23] \- a lot of this applies to iOS as well. Apple also details the changes with its new “Grand Unified Receipt” in [Session 308 “Using Receipts to Protect Your Digital Sales” @ WWDC 2013][24].

## Comic Sans MS

Admit it. You’ve missed Comic Sans MS. With iOS 7, you can finally get it back. Now, downloadable fonts have been added to iOS 6, but back then the list of fonts was pretty small and not really interesting. Apple added some more fonts in iOS 7, including “famous” ones like [PT Sans][25] or [Comic Sans MS][26]. The `kCTFontDownloadableAttribute` was not declared in iOS 6, so this wasn’t really usable until iOS 7, but Apple retroactively declared this property to be available on iOS 6 upward.

![comic-sans-ms.png][27]

The list of fonts is [dynamic][28] and might change in the future. Apple lists some of the available fonts in [Tech Note HT5484][29], but the document is outdated and doesn’t yet reflect the changes on iOS 7.

Here’s how you get an array of fonts that can be downloaded with `CTFontDescriptorRef`:


    CFDictionary *descriptorOptions = @{(id)kCTFontDownloadableAttribute : @YES};
    CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes((CFDictionaryRef)descriptorOptions);
    CFArrayRef fontDescriptors = CTFontDescriptorCreateMatchingFontDescriptors(descriptor, NULL);

The system won’t check if the font is already on disk and will return the same list. Additionally, this method might do a network call and thus block. You don’t want to call this from the main thread.

To download the font, use this block-based API:


    bool CTFontDescriptorMatchFontDescriptorsWithProgressHandler(
             CFArrayRef                          descriptors,
             CFSetRef                            mandatoryAttributes,
             CTFontDescriptorProgressHandler     progressBlock)

This method handles the network call and calls your `progressBlock` with progress information until the download either succeeds or fails. Refer to Apple’s [DownloadFont Example][30] to see how this can be used.

There are a few gotchas here. This font will only be available during the current app run, and has to be loaded again into memory on the next run. Since fonts are saved in a shared place, you can’t rely on them being available. They most likely will be, but it’s not guaranteed and the system might clean this folder, or your app is being copied to a new device where the font doesn’t yet exist, and you might run without a working network. On the Mac or in the Simulator you can obtain the `kCTFontURLAttribute` to get the absolute path of the font and speed up loading time, but this won’t work on iOS, since the folder is outside of your app - you need to call `CTFontDescriptorMatchFontDescriptorsWithProgressHandler` again.

You can also subscribe to the new `kCTFontManagerRegisteredFontsChangedNotification` to be notified whenever new fonts are loaded into the font registry. You can find out more in [Session 223 “Using Fonts with TextKit” @ WWDC 2013][24].

## Can’t Get Enough?

Don’t worry - there’s a lot more new in iOS 7! [Over at NSHipster][31] you’ll learn about speech synthesis, base64, the all-new `NSURLComponents`, `NSProgress`, bar codes, reading lists, and, of course, `CIDetectorEyeBlink`. And there’s a lot more waiting we couldn’t cover - study Apple’s [iOS 7 API Diffs][32], the [What’s new in iOS][33] guide, and the [Foundation Release Notes][34] (those are for OS X - but since this is shared code, a lot applies to iOS as well). Many of the new methods don’t even have documentation yet, so it’s up to you to play around and blog about it!




* * *

[More articles in issue #5][35]

  * [Privacy policy][36]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-5/index.html
   [5]: https://twitter.com/steipete
   [6]: http://petersteinberger.com/blog/2013/fixing-uisearchdisplaycontroller-on-ios-7/
   [7]: https://developer.apple.com/library/ios/documentation/ServicesDiscovery/Conceptual/GameControllerPG/Introduction/Introduction.html
   [8]: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIKeyCommand_class/Reference/Reference.html#//apple_ref/occ/instp/UIKeyCommand/input
   [9]: http://petersteinberger.com/blog/2013/adding-keyboard-shortcuts-to-uialertview/
   [10]: https://github.com/steipete/PSMenuItem
   [11]: http://www.objc.io/images/issue-5/responder-chain.png
   [12]: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIInputView_class/Reference/Reference.html
   [13]: https://github.com/nst/iOS-Runtime-Headers/commits/master/Frameworks/UIKit.framework/UIInputView.h
   [14]: http://favstar.fm/users/AndrePang/status/18099774996
   [15]: https://github.com/AFNetworking/AFNetworking/blob/09658b352a496875c91cc33dd52c3f47b9369945/AFNetworking/AFURLResponseSerialization.m#L442-518
   [16]: http://www.objc.io/images/issue-5/image-decompression.png
   [17]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSBundle_Class/Reference/Reference.html#//apple_ref/occ/instm/NSBundle/appStoreReceiptURL
   [18]: https://developer.apple.com/library/ios/documentation/StoreKit/Reference/SKReceiptRefreshRequest_ClassRef/SKReceiptRefreshRequest.html
   [19]: http://www.apple.com/certificateauthority/
   [20]: http://en.wikipedia.org/wiki/PKCS
   [21]: http://de.wikipedia.org/wiki/Abstract_Syntax_Notation_One
   [22]: https://github.com/rmaddy/VerifyStoreReceiptiOS
   [23]: https://developer.apple.com/library/mac/releasenotes/General/ValidateAppStoreReceipt/index.html#//apple_ref/doc/uid/TP40010573-CH1-SW6
   [24]: https://developer.apple.com/wwdc/videos/
   [25]: http://www.fontsquirrel.com/fonts/PT-Sans
   [26]: http://sixrevisions.com/graphics-design/comic-sans-the-font-everyone-loves-to-hate/
   [27]: http://www.objc.io/images/issue-5/comic-sans-ms.png
   [28]: http://mesu.apple.com/assets/com_apple_MobileAsset_Font/com_apple_MobileAsset_Font.xml
   [29]: http://support.apple.com/kb/HT5484
   [30]: https://developer.apple.com/library/ios/samplecode/DownloadFont/Listings/DownloadFont_ViewController_m.html
   [31]: http://nshipster.com/ios7/
   [32]: https://developer.apple.com/library/ios/releasenotes/General/iOS70APIDiffs/index.html#//apple_ref/doc/uid/TP40013203
   [33]: https://developer.apple.com/library/ios/releasenotes/General/WhatsNewIniOS/Articles/iOS7.html
   [34]: https://developer.apple.com/library/prerelease/mac/releasenotes/Foundation/RN-Foundation/index.html#//apple_ref/doc/uid/TP30000742
   [35]: http://www.objc.io/issue-5
   [36]: http://www.objc.io/privacy.html
