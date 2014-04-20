你是否曾经试着为 iOS 项目搭建一台支持[持续集成](http://en.wikipedia.org/wiki/Continuous_integration)的服务器，从我的个人经验而言，这可不是一个轻松的活。你需要准备一台 Mac 电脑，安装好全部所需的软件和插件。你要负责管理所有的用户账户，并提供安全保护。你需要授予访问存储库的权限，并配置所有的编译步骤和证书。在项目运行时期，你需要保持服务器的稳健和最新。

最后，原本你想节省的时间，最终你会发现你花费了大量的时间去维护这台服务器。不过如果你的项目托管在 [GitHub](https://github.com/)) 上，现在有了新的希望：[Travis CI](https://travis-ci.org/)。该服务可以为你的项目提供持续集成的支持，也就意味着它会负责好托管一个项目的所有细节。在 [Ruby](https://www.ruby-lang.org/) 的世界中，Travis CI 已久负盛名。从 2013 年 4 月起，Travis 也开始支持 iOS 和 Mac 平台。

在这篇文章中，我将向你展示如何一步步的在项目中集成 Travis。不仅包括项目的编译和单元测试的运行，还包括将应用部署到你所有的测试设备上。为了演示，我在 GitHub 上放了一个[示例项目](https://github.com/objcio/issue-6-travis-ci)。在这篇文章的最后，我会教你一些提示：如何用 Travis 去定位程序中的错误。

### GitHub 集成

我最喜欢 Travis 的一点就是它与 GitHub 的 Web UI 集成的非常好。譬如 pull 请求。Travis 会为每次请求都执行编译操作。如果一切正常，pull 请求在 GitHub 上看起来就像这样：

<img src="http://img.objccn.io/issue-6/github_ready_to_merge.jpg">

万一编译不成功，GitHub 页面会相应的改变颜色给予提醒：

<img src="http://img.objccn.io/issue-6/github_merge_with_caution.jpg">

## 链接 Travis 和 GitHub

让我们看一下如何将你的 GitHub 项目与 Travis 链接上。使用你的 GitHub 账号登录 [Travis 站点](https://travis-ci.org/)。对于私有仓库，你需要注册一个 [Travis 专业版账号](https://magnum.travis-ci.com)。

登陆成功后，你就可以为你的项目打开Travis支持。找到属性页面，在此列出了你的所有GitHub项目。不过要注意，如果你此后创建了一个新的工作目录，要使用Sync now按钮进行同步。Travis只会偶尔更新你的项目列表。

登录成功后，你需要为项目开启 Travis 支持。导航到找到[属性页面](https://travis-ci.org/profile)，该页面此列出了你的所有 GitHub 项目。不过要注意，如果你此后创建了一个新的仓库，要使用 `Sync now` 按钮进行同步。Travis 只会偶尔更新你的项目列表。

<img src="http://img.objccn.io/issue-6/objc_travis_flick.jpg">

现在只需要打开这个开关就可以为你的项目添加 Travis 服务。以后你会看到 Travis 会和 GitHub 项目设置相关联。下一步就是告诉 Travis 当它收到项目改动通知之后该做什么。

## 轻量级的项目配置

Travis CI需要你的项目的一些基本信息。在你项目的根目录创建一个名叫 `.travis.yml` 的文件，文件中的内容如下：

	language: objective-c

Travis 编译器运行在虚拟机环境下。该编译器已经利用 [Ruby](https://www.ruby-lang.org/en/)，[Homebrew](http://brew.sh/)，[CocoaPods](http://cocoapods.org/) 和[一些默认的编译脚本](https://github.com/jspahrsummers/objc-build-scripts)进行过[预配置](http://about.travis-ci.org/docs/user/osx-ci-environment/)。上述的配置项已经足够编译你的项目了。

预装的编译脚本会分析你的 Xcode 项目，并对每个 target 进行编译。如果所有文件都没有编译错误，以及测试也没有被打断，那么项目就编译成功了。现在可以将你的改动 Push 到 GitHub 中看看能否成功编译。

虽然上述配置过程真的很简单，不过对你的项目不一定适用。这里几乎没有什么文档来指导用户如何配置默认的编译行为。例如，有一次我没有用 `iphonesimulator` SDK 导致[代码签名错误](https://github.com/travis-ci/travis-ci/issues/1322)。如果刚刚那个轻量级的配置对你的项目不适用的话，让我们来看一下如何对 Travis 使用自定义的编译命令。

## 自定义编译命令

Travis 使用命令行对项目进行编译。因此，第一步就是使项目能够在本地编译。作为 Xcode 命令行工具的一部分，Apple 提供了 [`xcodebuild`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/xcodebuild.1.html) 命令。

打开终端并输入：

	xcodebuild --help

上述命令列出 `xcodebuild` 所有可用的参数。如果命令执行失败了，确保[命令行工具](http://stackoverflow.com/a/9329325)已经成功安装。一个常见的编译命令看起来像这样：

	xcodebuild -project {project}.xcodeproj -target {target} -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO

使用 `iphonesimulator` SDK 是为了避免签名错误。直到我们稍后引入证书之前，这一步必须的直到我们稍后引入证书为止。通过设置 `ONLY_ACTIVE_ARCH=NO` 我们可以确保利用模拟器架构编译工程。你也可以设置额外的属性，例如 `configuration`，输入 `man xcodebuild` 查看相关文档。

对于使用 `CocoaPods` 的项目，需要用下面的命令来指定 `workspace` 和 `scheme`：

	xcodebuild -workspace {workspace}.xcworkspace -scheme {scheme} -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO

Schemes 是由 Xcode 自动生成的，但这在服务器上不会发生。确保所有的 scheme 都被设为 `shared` 并加入到仓库中。否则它只会在本地工作而不会被 Travis CI 识别。

<img src="http://img.objccn.io/issue-6/objc_shared_schemes.jpg">

我们示例项目下的 `.travis.yml` 文件现在应该看起来像这样：

	language: objective-c
	script: xcodebuild -workspace TravisExample.xcworkspace -scheme TravisExample -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO

## 运行测试

对于测试来说，通常使用如下这个命令 (注意 `text` 属性)：

	xcodebuild test -workspace {workspace}.xcworkspace -scheme {test_scheme} -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO

不幸的是，`xcodebuild` 对于 iOS 来说，并不支持 target 和应用程序的测试。[这里有一些解决方案](http://www.raingrove.com/2012/03/28/running-ocunit-and-specta-tests-from-command-line.html)，不过我建议使用 Xctool。

### Xctool

[Xctool](https://github.com/facebook/xctool) 是来自 Facebook 的命令行工具，它可以简化程序的编译和测试。他的彩色输出信息比 `xcodebuild` 更加简洁直观。同时还添加了对逻辑测试，应用测试的支持。

Travis 中已经预装了 xctool。要在本地测试的话，需要用 [Homebrew](http://brew.sh/) 安装 xctool：

	brew update
	brew install xctool

xctool 用法非常简单，它使用跟 `xcodebuild` 相同的参数：

	xctool test -workspace TravisExample.xcworkspace -scheme TravisExampleTests -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO

一旦相关命令在本地能正常工作，那么就是时候把它们添加到 `.travis.yml` 中了：

	language: objective-c
	script:
	  - xctool -workspace TravisExample.xcworkspace -scheme TravisExample -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO
	  - xctool test -workspace TravisExample.xcworkspace -scheme TravisExampleTests -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO

目前我们所添加的配置已经足够编译一个框架类的应用。我们能够保证项目可以正常编译并通过测试。但对于真正的iOS应用来说，我们希望在真实的物理设备上进行测试。很显然，我们要借助Travis来帮我们自动部署。整个过程的第一步，我们需要给我们的应用签名。

到此为止，介绍的内容对于使用 Travis 的 library 工程来说，已经足够了。我们可以确保项目正常编译并测试通过。但对于 iOS 应用来说，我们希望能在真实的物理设备上进行测试。也就是说我们需要将应用部署到我们的所有测试设备上。当然，我们希望 Travis 能自动完成这项任务。首先，我们需要给程序签名。

## 应用程序的签名

为了在 Travis 中能给我们的程序签名，我们需要准备好所有必要的证书和配置文件。就像每个 iOS 开发人员知道的那样，这可能是最困难的一步。后面，我将写一些脚本在服务器上给应用程序签名。

### 证书和配置文件

**1. 苹果全球开发者关系认证**

从[苹果站点](http://developer.apple.com/certificationauthority/AppleWWDRCA.cer)下载证书，或者从钥匙串中导出。并将其保存到项目的目录 `scripts/certs/apple.cer` 中。

**2. iPhone 发布证书 + 私钥**

如果还没有发布证书的话，先创建一个。登录[苹果开发者账号](https://developer.apple.com/account/overview.action)，按照步骤，创建一个新的生产环境证书 (`Certificates` > `Production` > `Add` > `App Store and Ad Hoc`)。然后确保下载并安装证书。之后，可以在钥匙串中找到它。打开 Mac 中的 `钥匙串` 应用程序：

<img src="http://img.objccn.io/issue-6/dist_cert_keychain.jpg">

右键单击证书，选择 `Export...` 将证书导出至 `scripts/certs/dist.cer`。然后导出私钥并保存至 `scripts/certs/dist.p12`。记得输入私钥的密码。

由于 Travis 需要知道私钥密码，因此我们要把这个密码存储在某个地方。当然，我们不希望以明文的形式存储。我们可以用 [Travis 的安全环境变量](http://about.travis-ci.org/docs/user/build-configuration/#Secure-environment-variables)。打开终端，并定位到包含 `.travis.yml` 文件所在目录。首先用 `gem install travis` 命令安装 Travis gem。之后，用下面的命令添加密钥密码：

	travis encrypt "KEY_PASSWORD={password}" --add

这样就可以安装一个叫做 `KEY_PASSWORD` 的加密环境变量到 `.travis.yml` 配置文件中。这样就可以在被 Travis CI 执行的脚本中使用这个变量。

**3. iOS 配置文件 (发布)**

如果还没有用于发布的配置文件，那么就创建一个新的。根据开发者账号类型，可以选择创建 [Ad Hoc](https://developer.apple.com/library/ios/documentation/IDEs/Conceptual/AppDistributionGuide/TestingYouriOSApp/TestingYouriOSApp.html) 或 [In House](https://developer.apple.com/programs/ios/enterprise/gettingstarted/) 配置文件 (`Provisioning Profiles` > `Distribution` > `Add` > `Ad Hoc` or `In House`)。然后将其下载保存至 `scripts/profile/` 目录。

由于 Travis 需要访问这个配置文件，所以我们旭阳将这个文件的名字存储为一个全局环境变量。并将其添加至 `.travis.yml` 文件的全局环境变量 section中。例如，如果配置文件的名字是 `TravisExample_Ad_Hoc.mobileprovision`，那么按照如下进行添加：

	env:
	  global:
	  - APP_NAME="TravisExample"
	  - 'DEVELOPER_NAME="iPhone Distribution: {your_name} ({code})"'
	  - PROFILE_NAME="TravisExample_Ad_Hoc"

上面还声明了两个环境变量。第三行中的 `APP_NAME` 通常为项目默认 target 的名字。第四行的 `DEVELOPER_NAME` 是 Xcode 中，默认 target 里面 `Build Settings` 的 `Code Signing Identity` > `Release` 对应的名字。然后搜索程序的 `Ad Hoc` 或 `In House` 配置文件，将其中的黑体文件去掉。根据设置的不同，括弧中可能不会有任何信息。

## 加密证书和配置文件

If your GitHub project is public, you might want to encrypt your certificates and profiles, as they contain sensitive data. If you have a private repository, you can move on to the next section.

First, we have to come up with a password that encrypts all our files (the secret). In our example, let's choose "foo," but you should come up with a more secure password for your project. On the command line, encrypt all three sensitive files using `openssl`:

	openssl aes-256-cbc -k "foo" -in scripts/profile/TravisExample_Ad_Hoc.mobileprovision -out scripts/profile/TravisExample_Ad_Hoc.mobileprovision.enc -a
	openssl aes-256-cbc -k "foo" -in scripts/certs/dist.cer -out scripts/certs/dist.cer.enc -a
	openssl aes-256-cbc -k "foo" -in scripts/certs/dist.p12 -out scripts/certs/dist.cer.p12 -a

This will create encrypted versions of our files with the ending `.enc`. You can now remove or ignore the original files. At the very least, make sure not to commit them, otherwise they will show up on GitHub. If you accidentally committed or pushed them already, [get some help](https://help.github.com/articles/remove-sensitive-data).

Now that our files are encrypted, we need to tell Travis to decrypt them again. For that, Travis needs the secret. We use the same approach that we used already for the `KEY_PASSWORD`:

	travis encrypt "ENCRYPTION_SECRET=foo" --add

Lastly, we have to tell Travis which files to decrypt. Add the following commands to the `before-script` phase in the `.travis.yml`:

	before_script:
	- openssl aes-256-cbc -k "$ENCRYPTION_SECRET" -in scripts/profile/TravisExample_Ad_Hoc.mobileprovision.enc -d -a -out scripts/profile/TravisExample_Ad_Hoc.mobileprovision
	- openssl aes-256-cbc -k "$ENCRYPTION_SECRET" -in scripts/certs/dist.p12.enc -d -a -out scripts/certs/dist.p12
	- openssl aes-256-cbc -k "$ENCRYPTION_SECRET" -in scripts/certs/dist.p12.enc -d -a -out scripts/certs/dist.p12

With that, your files on GitHub will be secured, while Travis can still read and use them. There is only one security issue that you have to be aware of: You could (accidentally) expose a decrypted environment variable in the Travis build log. Note, however, that decryption is disabled for pull requests.

### Add Scripts

Now we have to make sure that the certificates get imported in the Travis CI keychain. To do this, we should add a new file, `add-key.sh`, in the `scripts` folder:

	#!/bin/sh
	security create-keychain -p travis ios-build.keychain
	security import ./scripts/certs/apple.cer -k ~/Library/Keychains/ios-build.keychain -T /usr/bin/codesign
	security import ./scripts/certs/dist.cer -k ~/Library/Keychains/ios-build.keychain -T /usr/bin/codesign
	security import ./scripts/certs/dist.p12 -k ~/Library/Keychains/ios-build.keychain -P $KEY_PASSWORD -T /usr/bin/codesign
	mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
	cp ./scripts/profile/$PROFILE_NAME.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/

Here we create a new temporary keychain called `ios-build` that will contain all the certificates. Note that we use the `$KEY_PASSWORD` here to import the private key. As a final step, the mobile provisioning profile is copied into the `Library` folder.

After creating this file, make sure to give it executable rights. On the command line, type `chmod a+x scripts/add-key.sh`. You have to do this for the following scripts as well.

Now that all certificates and profiles are imported we can sign our application. Please note that we have to build the app before we can sign it. As we need to know where the build is stored on disk, I recommend specifying the output folder by declaring `OBJROOT` and `SYMROOT` in the build command. Also, we should create a release version by setting the SDK to `iphoneos` and the configuration to `Release`:

	xctool -workspace TravisExample.xcworkspace -scheme TravisExample -sdk iphoneos -configuration Release OBJROOT=$PWD/build SYMROOT=$PWD/build ONLY_ACTIVE_ARCH=NO

If you run this command, you should find the app binary in the `build/Release-iphoneos` folder afterward. Now we can sign it and create the `IPA` file. Do this by creating a new script:

	#!/bin/sh
	if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
	  echo "This is a pull request. No deployment will be done."
	  exit 0
	fi
	if [[ "$TRAVIS_BRANCH" != "master" ]]; then
	  echo "Testing on a branch other than master. No deployment will be done."
	  exit 0
	fi

	PROVISIONING_PROFILE="$HOME/Library/MobileDevice/Provisioning Profiles/$PROFILE_NAME.mobileprovision"
	OUTPUTDIR="$PWD/build/Release-iphoneos"

	xcrun -log -sdk iphoneos PackageApplication "$OUTPUTDIR/$APPNAME.app" -o "$OUTPUTDIR/$APPNAME.ipa" -sign "$DEVELOPER_NAME" -embed "$PROVISIONING_PROFILE"

Lines two through nine are quite important. You don't want to create a new release while working on a feature branch. The same is true for pull requests. Builds for pull requests wouldn't work anyway, as secured environment variables [are disabled](http://about.travis-ci.org/docs/user/build-configuration/#Secure-environment-variables).

In line fourteen, we do the actual signing. This results in two new files in the `build/Release-iphoneos` folder: `TravisExample.ipa` and `TravisExample.app.dsym`. The first one contains the app which is ready to be delivered to your phone. The `dsym` file contains debug information of your binary. This is important for logging crashes on the devices. We will use both files later when we distribute the app.

The last script will remove the temporary keychain again and delete the mobile provisioning profile. It is not really necessary but helps when testing locally:

	#!/bin/sh
	security delete-keychain ios-build.keychain
	rm -f ~/Library/MobileDevice/Provisioning\ Profiles/$PROFILE_NAME.mobileprovision

As a last step, we have to tell Travis when to execute these three scripts. The keys should be added before the app is built and the signing and cleanup should happen afterwards. Add/replace the following steps in your `.travis.yml`:

	before_script:
	- ./scripts/add-key.sh
	- ./scripts/update-bundle.sh
	script:
	- xctool -workspace TravisExample.xcworkspace -scheme TravisExample -sdk iphoneos -configuration Release OBJROOT=$PWD/build SYMROOT=$PWD/build ONLY_ACTIVE_ARCH=NO
	after_success:
	- ./scripts/sign-and-upload.sh
	after_script:
	- ./scripts/remove-key.sh

With that done, we can push everything to GitHub and wait for Travis to sign our app. We can verify if it worked by investigating the Travis console on the project page. If everything works fine, we can have a look on how to distribute the signed app to our testers.

## Distributing the App

There are two well-known services that help you with distributing your app: [TestFlight](http://testflightapp.com) and [HockeyApp](http://hockeyapp.net). Choose whatever is more sufficient for your needs. Personally, I prefer HockeyApp, but I'll show how to integrate both services.

We will extend our existing shell script `sign-and-build.sh` for that. Let's create some release notes first:

	RELEASE_DATE=`date '+%Y-%m-%d %H:%M:%S'`
	RELEASE_NOTES="Build: $TRAVIS_BUILD_NUMBER\nUploaded: $RELEASE_DATE"

Note that we use a global environment variable set by Travis here (`TRAVIS_BUILD_NUMBER`).

### TestFlight

Create a [TestFlight account](https://testflightapp.com/register/) and set up your app. In order to use the TestFlight API, you need to get the [api_token](https://testflightapp.com/account/#api) and [team_token](https://testflightapp.com/dashboard/team/edit/?next=/api/doc/) first. Again, we have to make sure to encrypt them. On the command line execute:

	travis encrypt "TESTFLIGHT_API_TOKEN={api_token}" --add
	travis encrypt "TESTFLIGHT_TEAM_TOKEN={team_token}" --add

Now we can call the API accordingly. Add this to the `sign-and-build.sh`:

	curl http://testflightapp.com/api/builds.json \
	  -F file="@$OUTPUTDIR/$APPNAME.ipa" \
	  -F dsym="@$OUTPUTDIR/$APPNAME.app.dSYM.zip" \
	  -F api_token="$TESTFLIGHT_API_TOKEN" \
	  -F team_token="$TESTFLIGHT_TEAM_TOKEN" \
	  -F distribution_lists='Internal' \
	  -F notes="$RELEASE_NOTES"

Make sure NOT to use the verbose flag (`-v`), as this would expose your decrypted tokens!

### HockeyApp

Sign up for a [HockeyApp account](http://hockeyapp.net/plans) and create a new app. Then grab the `App ID` from the overview page. Next, we have to generate an API token. Go to [this page](https://rink.hockeyapp.net/manage/auth_tokens) and create one. If you want to automatically distribute new versions to all testers, choose the 'Full Access' version.

Encrypt both tokens:

	travis encrypt "HOCKEY_APP_ID={app_id}" --add
	travis encrypt "HOCKEY_APP_TOKEN={api_token}" --add

Then call their API from the `sign-and-build.sh` script:

	curl https://rink.hockeyapp.net/api/2/apps/$HOCKEY_APP_ID/app_versions \
	  -F status="2" \
	  -F notify="0" \
	  -F notes="$RELEASE_NOTES" \
	  -F notes_type="0" \
	  -F ipa="@$OUTPUTDIR/$APPNAME.ipa" \
	  -F dsym="@$OUTPUTDIR/$APPNAME.app.dSYM.zip" \
	  -H "X-HockeyAppToken: $HOCKEY_APP_TOKEN"

Note that we also upload the `dsym` file. If you integrate the [TestFlight](https://testflightapp.com/sdk/ios/doc/) or [HockeyApp SDK](http://hockeyapp.net/releases/), you can get human-readable crash reports without further ado.

## Troubleshooting Travis

Using Travis over the last month wasn't always flawless. It's important to know how to approach issues with your build without having direct access to the build environment.

As of writing this article, there are no VM images available for download. If your build doesn't work anymore, first try to reproduce the problem locally. Run the exact same build commands that Travis executes locally:

	xctool ...

For debugging the shell scripts, you have to define the environment variables first. What I did for this is create a new shell script that sets all the environment variables. This script is added to the `.gitignore` file because you don't want it exposed to the public. For the example project, my `config.sh` looks like this:

	#!/bin/bash

	# Standard app config
	export APP_NAME=TravisExample
	export DEVELOPER_NAME=iPhone Distribution: Mattes Groeger
	export PROFILE_NAME=TravisExample_Ad_Hoc
	export INFO_PLIST=TravisExample/TravisExample-Info.plist
	export BUNDLE_DISPLAY_NAME=Travis Example CI

	# Edit this for local testing only, DON'T COMMIT it:
	export ENCRYPTION_SECRET=...
	export KEY_PASSWORD=...
	export TESTFLIGHT_API_TOKEN=...
	export TESTFLIGHT_TEAM_TOKEN=...
	export HOCKEY_APP_ID=...
	export HOCKEY_APP_TOKEN=...

	# This just emulates Travis vars locally
	export TRAVIS_PULL_REQUEST=false
	export TRAVIS_BRANCH=master
	export TRAVIS_BUILD_NUMBER=0

In order to expose these environment variables, execute this (be sure `config.sh` has executable rights):

	. ./config.sh

Then try `echo $APP_NAME` to check if it worked. If it did, you can run any of your shell scripts locally without modifications.

If you get different build results locally, you might have different versions of your libraries and gems installed. Try to imitate the exact same setup as on the Travis VM. They have a list of their installed software versions [online](http://about.travis-ci.org/docs/user/osx-ci-environment/). You can also figure out the exact versions of all gems and libraries by putting debug information into your Travis config:

	gem cocoapod --version
	brew --version
	xctool -version
	xcodebuild -version -sdk

After you install the exact same versions locally, re-run the build.

If you still don't get the same results, try to do a clean checkout into a new directory. Also, make sure all caches are cleared. As Travis sets up a new virtual machine for each build, it doesn't have to deal with cache problems, but your local test environment might have to.

Once you can reproduce the exact same behavior as on the server, you can start to investigate what the problem is. It really depends, then, on your concrete scenario of how to approach it. Usually Google is a great help in figuring out what could be the cause of your problem.

If, after all, the problem seems to affect other projects on Travis as well, it might be an issue with the Travis environment itself. I saw this happening several times (especially in the beginning). In this case, try to contact their support. My experience is that they react super fast.

## Criticism

There are some limitations when using Travis CI compared to other solutions on the market. As Travis runs from a pre-configured VM, you have to install custom dependencies for every build. That costs additional time. They put [effort in providing caching mechanisms](http://about.travis-ci.org/docs/user/caching/) lately, though.

To some extent, you rely on the setup that Travis provides. For example, you have to deal with the currently installed version of Xcode. If you use a version that is newer than Travis CI, you probably won't be able to run your build on the server. It would be helpful if there were different VMs set up for each major Xcode version.

For complex projects, you might want to split up your build jobs into compiling the app, running integration tests, and so forth. This way, you get the build artifacts faster, without having to wait for all tests to be processed. There is [no direct support](https://github.com/travis-ci/travis-ci/issues/249) for dependent builds so far.

When pushing your project to GitHub, Travis gets triggered instantly. But builds usually won’t start right away. They will be put in a [global language-specific build queue](http://about.travis-ci.org/blog/2012-07-27-improving-the-quality-of-service-on-travis-ci/). However, the pro version allows more builds to be executed concurrently.

## Conclusion

Travis CI provides you with a fully functional continuous integration environment that builds, tests, and distributes your iOS apps. For open source projects, this service is even free. Community projects benefit from the great GitHub integration. You might have seen [buttons like this](http://about.travis-ci.org/docs/user/status-images/) already:

<img src="https://travis-ci.org/MattesGroeger/TravisExample-iOS.png?branch=master">

Even for commercial projects, their support for private GitHub repositories with Travis Pro opens up an easy and fast way to use continuous integration.

If you haven't tried Travis yet, go and do it now. It's awesome!

## 更多链接

* [示例工程](https://github.com/objcio/issue-6-travis-ci)
* [Travis CI](http://www.travis-ci.com/)
* [Travis CI 专业版](https://magnum.travis-ci.com/)
* [Xctool](https://github.com/facebook/xctool)
* [HockeyApp](http://hockeyapp.net/)
* [TestFlight](https://testflightapp.com/)

---

[话题 #6 下的更多文章](http://objccn.io/issue-6/)

原文: [Travis CI for iOS](http://www.objc.io/issue-6/travis-ci.html)

译文 [objc.io 第6期 为 iOS 建立 Travis CI](http://blog.jobbole.com/52116/)

精细校对 [@BeyondVincent](http://beyondvincent.com/)
