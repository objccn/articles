[Source](http://www.objc.io/issue-6/cocoapods-under-the-hood.html "Permalink to CocoaPods Under The Hood - Build Tools - objc.io issue #6 ")

# CocoaPods Under The Hood - Build Tools - objc.io issue #6 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# CocoaPods Under The Hood

[Issue #6 Build Tools][4], November 2013

By [Michele Titolo][5]

CocoaPods is a library dependency management tool for OS X and iOS applications. With CocoaPods, you can define your dependencies, called `pods`, and manage their versions easily over time and across development environments.

The philosophy behind CocoaPods is twofold. Firstly, including third-party code in your projects involves many hoops. For the beginning Objective-C developer, the project file is daunting. Going through the steps of configuring build phases and linker flags leaves a lot of room for human error. CocoaPods simplifies all of that, and automatically configures your compiler settings.

Secondly, CocoaPods makes it easy to discover new third-party libraries. Now, this doesn’t mean you should go and build a FrankenApp, where every part is written by somebody else and simply stitched together. It does mean that you can find really good libraries that shorten your development cycle and improve the quality of your software.

In this article, we will walk through the `pod install` process, and take a deeper look at what CocoaPods is doing behind the scenes.

## Core Components

CocoaPods is written in Ruby and actually is made of several Ruby Gems. The most important gems when explaining the integration process are [CocoaPods/CocoaPods][6], [CocoaPods/Core][7], and [CocoaPods/Xcodeproj][8] (yes, CocoaPods is a dependency manager that is built using a dependency manager!).

### CocoaPods/CocoaPod

This is the user-facing component and is activated whenever you call a `pod` command. It includes all the functionality you need to actually use CocoaPods, and makes use of all of the other gems to perform tasks.

### CocoaPods/Core

The Core gem provides support for working with the files that are involved with CocoaPods, mainly the Podfile and podspecs.

##### Podfile

The Podfile is the file that defines the pods you want to use. It is highly customizable, and you can be as specific as you’d like. For more information, check out [the Podfile guide][9].

#### Podspec

The `.podspec` is a file that determines how a particular pod is added to a project. It supports features such as listing source files, frameworks, compiler flags, and any other dependencies that a library requires, to name a few.

### CocoaPods/Xcodeproj

This gem handles all of the project file interactions. It has the ability to both create and modify `.xcodeproj` and `.xcworkspace` files. It is also useable as a standalone gem, so if you ever wanted to write scripts and easily modify the project file, this gem is for you.

## Running `pod install`

There is a lot that happens when `pod install` runs. The easiest insight into this is running the command with `\--verbose`. Run that command, `pod install --verbose` now, and then come back. It will look something like this:


    $ pod install --verbose

    Analyzing dependencies

    Updating spec repositories
    Updating spec repo `master`
      $ /usr/bin/git pull
      Already up-to-date.


    Finding Podfile changes
      - AFNetworking
      - HockeySDK

    Resolving dependencies of `Podfile`
    Resolving dependencies for target `Pods' (iOS 6.0)
      - AFNetworking (= 1.2.1)
      - SDWebImage (= 3.2)
        - SDWebImage/Core

    Comparing resolved specification to the sandbox manifest
      - AFNetworking
      - HockeySDK

    Downloading dependencies

    -> Using AFNetworking (1.2.1)

    -> Using HockeySDK (3.0.0)
      - Running pre install hooks
        - HockeySDK

    Generating Pods project
      - Creating Pods project
      - Adding source files to Pods project
      - Adding frameworks to Pods project
      - Adding libraries to Pods project
      - Adding resources to Pods project
      - Linking headers
      - Installing libraries
        - Installing target `Pods-AFNetworking` iOS 6.0
          - Adding Build files
          - Adding resource bundles to Pods project
          - Generating public xcconfig file at `Pods/Pods-AFNetworking.xcconfig`
          - Generating private xcconfig file at `Pods/Pods-AFNetworking-Private.xcconfig`
          - Generating prefix header at `Pods/Pods-AFNetworking-prefix.pch`
          - Generating dummy source file at `Pods/Pods-AFNetworking-dummy.m`
        - Installing target `Pods-HockeySDK` iOS 6.0
          - Adding Build files
          - Adding resource bundles to Pods project
          - Generating public xcconfig file at `Pods/Pods-HockeySDK.xcconfig`
          - Generating private xcconfig file at `Pods/Pods-HockeySDK-Private.xcconfig`
          - Generating prefix header at `Pods/Pods-HockeySDK-prefix.pch`
          - Generating dummy source file at `Pods/Pods-HockeySDK-dummy.m`
        - Installing target `Pods` iOS 6.0
          - Generating xcconfig file at `Pods/Pods.xcconfig`
          - Generating target environment header at `Pods/Pods-environment.h`
          - Generating copy resources script at `Pods/Pods-resources.sh`
          - Generating acknowledgements at `Pods/Pods-acknowledgements.plist`
          - Generating acknowledgements at `Pods/Pods-acknowledgements.markdown`
          - Generating dummy source file at `Pods/Pods-dummy.m`
      - Running post install hooks
      - Writing Xcode project file to `Pods/Pods.xcodeproj`
      - Writing Lockfile in `Podfile.lock`
      - Writing Manifest in `Pods/Manifest.lock`

    Integrating client project

There’s a lot going on here, but when broken down, it’s all very simple. Let’s walk through it.

### Reading the Podfile

If you’ve ever wondered why the Podfile syntax looks kind of weird, that’s because you are actually writing Ruby. It’s just a simpler DSL to use than the other formats available right now.

So, the first step during installation is figuring out what pods are both explicitly or implicitly defined. CocoaPods goes through and makes a list of all of these, and their versions, by loading podspecs. Podspecs are stored locally in `~/.cocoapods`.

#### Versioning and Conflicts

CocoaPods uses the conventions established by [Semantic Versioning][10] to resolve dependency versions. This makes resolving dependencies much easier, since the conflict resolution system can rely on non-breaking changes between patch versions. Say, for example, that two different pods rely on two versions of CocoaLumberjack. If one relies on `2.3.1` and another `2.3.3`, the resolver can use the newer version, `2.3.3`, since it should be backward compatible with `2.3.1`.

But this doesn’t always work. There are many libraries that don’t use this convention, which makes resolution difficult.

And of course, there will always be some manual resolution of conflicts. If one library depends on CocoaLumberjack `1.2.5` and another `2.3.1`, only the end user can resolve that by explicitly setting a version.

### Loading Sources

The next step in the process is actually loading the sources. Each `.podspec` contains a reference to files, normally including a git remote and tag. These are resolved to commit SHAs, which are then stored in `~/Library/Caches/CocoaPods`. The files created in these directories are the responsibility of the Core gem.

The source files are then downloaded to the `Pods` directory using the information from the `Podfile`, `.podspec`, and caches.

### Generating the Pods.xcodeproj

Every time `pod install` is run and changes are detected, the `Pods.xcodeproj` is updated using the Xcodeproj gem. If the file doesn’t exist, it’s created with some default settings. Otherwise, the existing settings are loaded into memory.

### Installing Libraries

When CocoaPods adds a library to the project, it adds a lot more than just the source. Since the change to each library getting its own target, for each library, several files are added. Each source needs:

  * An `.xcconfig` that contains the build settings
  * A private `.xcconfig` that merges these build settings with the default CocoaPods configuration
  * A `prefix.pch` which is required for building
  * A `dummy.m` which is also required for building

Once this is done for each pod target, the overall `Pods` target is created. This adds the same files, with the addition of a few more. If any source contains a resource bundle, instructions on adding that bundle to your app’s target will be added to `Pods-Resources.sh`. There’s also a `Pods-environment.h`, which has some macros for you to check whether or not a component comes from a pod. And lastly, two acknowledgement files are generated, one `plist`, one `markdown`, to help end users conform with licensing.

### Writing to Disk

Up until now, a lot of this work has been done using objects in memory. In order for this work to be reproducible, we need a file record of all of this. So the `Pods.xcodeproj` is written to disk, along with two other very important files, `Podfile.lock` and `Manifest.lock`.

#### Podfile.lock

This is one of the most important files that CocoaPods creates. It keeps track of all of the resolved versions of pods that need to be installed. If you are ever curious as to what version of a pod was installed, check this file. This also helps with consistency across teams if this file is checked in to source control, which is recommended.

#### Manifest.lock

This is a copy of the `Podfile.lock` that gets created every time you run `pod install`. If you’ve ever seen the error `The sandbox is not in sync with the Podfile.lock`, it’s because this file is no longer the same as the `Podfile.lock`. Since the `Pods` directory is not always under version control, this is a way of making sure that developers update their pods before running, as otherwise the app would crash, or the build would fail in another, less visible, way.

### xcproj

If you have [xcproj][11] installed on your system, which we recommend, it will `touch` the `Pods.xcodeproj` to turn it into the old ASCII plist format. Why? The writing of those files is no longer supported, and hasn’t been for a while, yet Xcode still relies on it. Without xcproj, your `Pods.xcodeproj` is written as an XML plist, and when you open it in Xcode, it will be rewritten, causing large file diffs.

## The Result

The finished product of running `pod install` is that a lot of files have been added to your project and created on the system. This process usually only takes a few seconds. And, of course, everything that CocoaPods does can be done without it. But it’ll take a lot longer than a few seconds.

## Sidenote: Continuous Integration

CocoaPods plays really well with Continuous Integration. And, depending on how you have your project set up, it’s still fairly easy to get these projects building.

### With a Version-Controlled Pods Folder

If you version control the `Pods` folder and everything inside it, you don’t need to do anything special for continuous integration. Just make sure to build your `.xcworkspace` with the correct scheme selected, as you need to specify a scheme when building with a workspace.

### Without a Pods Folder

When you do not version control your `Pods` folder, you need to do a few more things to get continuous integration working properly. At the very least, the `Podfile` needs to be checked in. It’s recommended that the generated `.xcworkspace` and `Podfile.lock` are also under version control for ease of use, as well as making sure that the correct pod versions are used.

Once you have that setup, the key with running CocoaPods on CI is making sure `pod install` is run before every build. On most systems, like Jenkins or Travis, you can just define this as a build step (in fact, Travis will do it automatically). With the release of [Xcode Bots, we haven’t quite figured out a smooth process as of writing][12], but are working toward a solution, and we’ll make sure to share it once we do.

## Wrapping Up

CocoaPods streamlines development with Objective-C, and our goal is to improve the discoverability of, and engagement in, third-party open-source libraries. Understanding what’s happening behind the scenes can only help you make better apps. We’ve walked through the entire process, from loading specs and sources and creating the `.xcodeproj` and all its components, to writing everything to disk. So next time, run `pod install --verbose` and watch the magic happen.




* * *

[More articles in issue #6][13]

  * [Privacy policy][14]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-6/index.html
   [5]: https://twitter.com/micheletitolo
   [6]: https://github.com/CocoaPods/CocoaPods/
   [7]: https://github.com/CocoaPods/Core
   [8]: https://github.com/CocoaPods/Xcodeproj
   [9]: http://guides.cocoapods.org/syntax/podfile.html
   [10]: http://semver.org/
   [11]: https://github.com/0xced/xcproj
   [12]: https://groups.google.com/d/msg/cocoapods/eYL8QB3XjyQ/10nmCRN8YxoJ
   [13]: http://www.objc.io/issue-6
   [14]: http://www.objc.io/privacy.html
