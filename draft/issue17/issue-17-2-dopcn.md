---
title: Inside Code Signing
category: "17"
date: "2014-10-10 10:00:00"
author: "<a href=\"https://thomas.kollba.ch/\">Thomas 'toto' Kollbach</a>"
tags: article
---

> "Users appreciate code signing."  
>  – Apple Developer Library: [Code Signing Guide](https://developer.apple.com/library/mac/documentation/Security/Conceptual/CodeSigningGuide/Introduction/Introduction.html)


>"用户会感激代码签名带来的好处"
> – Apple Developer Library: [Code Signing Guide](https://developer.apple.com/library/mac/documentation/Security/Conceptual/CodeSigningGuide/Introduction/Introduction.html)


There are many nice APIs you might encounter while building apps for iOS or OS X. You could do [beautiful animations](http://www.objc.io/issue-12/), [test your app](http://www.objc.io/issue-15) really well, or store your data safely in [Core Data](http://www.objc.io/issue-4). But at some point, you will encounter code signing and provisioning. And more often than not, this is when you will start cursing. 

在 iOS 或 OS X 平台上进行应用开发时，你所需要使用的 API 大多设计得简洁明了。你可以轻易地实现[酷炫的动画效果](http://www.objccn.io/issue-12/)，便捷地进行[应用发布前测试](http://www.objccn.io/issue-15)，或是用 [Core Data](http://www.objccn.io/issue-4) 将数据安全的存储在本地。但是总有一天，你会碰上代码签名(code signing)和配置文件(provisioning)，大多数情况下，这会是你在心里问候某些人祖宗的开始。

If you have ever developed an application for iOS, you have probably fought with code signing or device provisioning at some point. Even as an OS X developer, you cannot avoid signing your code anymore, at least not if you want to be on the Mac App Store or are part of the Developer ID program. 

如果你已经在 iOS 上开发发布过应用，那么你多半已经与代码签名(code signing)或设备配置文件(device provisioning)打过交道了。即使是 OS X 开发者，如果你想发布自己的应用到 Mac App Store 上去或者想参与苹果的开发者项目，那么也不得不开始为自己的代码设置签名。

Most of the time, code signing seems like a magical machine that is hard to understand. I will try to shed some light on this machine.

对于大多数人来说代码签名(code signing)看上去像是一个难以理解的神秘黑盒。在这篇文章里我会尽可能揭示盒子内部的运作机理。

While the process and many of the internals are wrapped inside the iOS system and SDK, we can get a glance by looking at the infrastructure used to sign the app, in addition to looking at how OS X code signing works. Since under the hood, iOS is very similar to OS X, one can figure out a lot by looking both places.

通常来说，我们无法直接看到代码签名的运作过程，它们隐藏在 iOS 系统内部和 SDK 之中。但我们可以通过观察设置代码签名所需工具的运作方式，来找出一些线索。除此之外，我们还可以参考 OS X 上的代码签名运作方式，毕竟 iOS 和 OS X 系出同源，我们可以从他们的对比之中得到很多有用的信息。

The APIs and technology for signing executable code on OS X appeared on Mac OS X Leopard 10.5 around the time the first iPhone was released. This seems no coincidence, since on the iPhone OS itself, code signing is even more crucial. The iPhone was one of the first mass-market computing platforms after game consoles that relied on code signing from the ground up; iOS simply runs no unsigned code unless the device is jailbroken. Jailbreaking basically disables all the code signing and sandboxing security infrastructure, which is a very dangerous thing to do.  

OS X 上代码签名技术和相应的 API 是在 Mac OS X Leopard 10.5 上首次出现，刚好是第一台 iPhone 发布的时候。这并非巧合，因为在 iOS 上，代码签名起到的作用更加重要。iPhone 是在众多游戏主机之后第一个大规模出售并且从头就开始使用代码签名的计算平台。只有在越狱之后，iOS 才能运行没有签名的代码。越狱使应用可以绕过代码签名和沙盒安全机制的全部限制，这会是一个非常危险的行为。


## Certificates and Keys

## 证书和密匙

As an iOS developer, chances are you have a certificate, a public key, and a private key on your development machine. These are at the core of the code signing infrastructure. Code signing, like SSL, relies on [public-key cryptography](https://en.wikipedia.org/wiki/Public-key_cryptography) based on the X.509 standard.  

作为一个 iOS 开发者，在你开发使用的机器上应该已经有一个证书，一个公钥，一个私钥。这些是代码签名机制的核心。像 SSL 一样，代码签名也依赖于采用 [X.509 标准](http://zh.wikipedia.org/wiki/X.509)的[公开密钥加密](http://zh.wikipedia.org/wiki/%E5%85%AC%E5%BC%80%E5%AF%86%E9%92%A5%E5%8A%A0%E5%AF%86)。


The main utility to manage the X.509 infrastructure on OS X is the Keychain Access utility. In the "My Certificates" section of your development machine, you will find the certificates you have the private key for. To use a certificate for signing, you need the private key, so that your code signing certificates will show up in this list. If you have a private key for a certificate, you can unfold the certificate to show the private key:

在 OS X 上， X.509 的基本组成部分（译者注：例如证书等）都是由一个叫**钥匙串访问**的工具来进行管理。打开你开发机器上的**钥匙串访问**应用，选择类别选项下的“我的证书（My Certificates）”，你可以看到所有你持有的私钥相对应的证书。要用一个证书设置代码签名，你必须拥有私钥，所以所有你拥有私钥的证书都会被列在这里。如果你拥有一个证书的私钥，你可以展开证书显示出它的私钥来：

![iOS Developer Certificate in the OS X keychain](http://img.objccn.io/issue-17/iphone-developer-keychain.png)

If you export the certificate, e.g. for backing it up (which you should really do), it is important to remember to unfold the private key and select both rows. 

如果你要导出证书，例如为了备份（强烈建议进行），一定要记得展开证书那一条显示出私钥并将两行都选中。

Another way to quickly get a glance at the identities on your system that can be used for signing code is with the very versatile `security` command line tool:

为了对代码签名的过程有一个初步的了解，我们还可以使用一个工具，那就是用途广泛的命令行工具 `security`

```
$ security find-identity -v -p codesigning                       
  1) 01C8E9712E9632E6D84EC533827B4478938A3B15 "iPhone Developer: Thomas Kollbach (7TPNXN7G6K)"
```

A certificate is — very broadly speaking — a public key combined with a lot of additional information that was itself signed by some authority (also called a Certificate Authority, or CA) to state that the information in the certificate is correct. In this case, the authority is Apple's authority for developer stuff, the Apple Worldwide Developer Relations CA. This signature expires at some point, which means that anybody checking the certificate will also have to have a clock that is set correctly. This is one of the reasons why setting your system clock back in time can wreak havoc on a lot of things on iOS. 

概括的讲，一个证书（certificate）是一个公钥加上许多附加信息，这些附加信息都是被某个认证机构（Certificate Authority 简称 CA）进行签名认证过的，认证这个证书中的信息是准确无误的。对于 iOS 开发来说这个认证机构就是苹果的认证部门 Apple Worldwide Developer Relations CA。认证的签名有固定的有效期，这就意味着当前系统时间需要被正确设置，因为证书是基于当前时间进行核对。这也是为什么将系统时间设定到过去会对 iOS 造成多方面破坏的原因之一。

![iOS Developer Certificate in detail](http://img.objccn.io/issue-17/ios-dev-certificate.png)

For iOS development, you usually have two certificates: one prefixed with `iPhone Developer`, and one prefixed with `iPhone Distribution`. The first one is the one you use to build apps for your devices, and the other one is used to submit apps. This fact is baked into certificates. If you open the certificate in Keychain Utility, you will see a lot of extension entries. Look for the last one, labeled `Apple Developer Certificate (Submission) `, or `Apple Developer Certificate (Development)`, depending on the type of certificate — iOS uses this extension to determine if your app runs in development mode or distribution mode, and based on this, which rules that apply.

对于 iOS 开发来说，一般会有两个证书：一个带有前缀 `iPhone Developer`，另一个带有前缀 `iPhone Distribution`。前者用于使应用可以在你的测试设备上运行，后者是在提交应用到 APP store 时用到。一个证书的用途取决于它所包含的内部信息，在钥匙串访问中双击打开一个证书文件，你可以看到许多详细条目，拖动到最下面有一条标记着`Apple Developer Certificate (Submission) `， 或者 `Apple Developer Certificate (Development)`，具体你会看到哪一种，取决于你所打开的证书是哪一种类型，iOS 系统会利用这个信息来判断你的应用是运行在开发模式下还是发布模式，并据此判断以切换应用运行规则。

In addition to the certificate with the signed public key in it, we also need the private key. This private key is what you use to sign the binaries with. Without the private key, you cannot use the certificate and public key to sign anything.  

为了让拥有公钥的证书起作用，我们需要有私钥。私钥是你在为组成应用的二进制字符进行签名时派上用场的。没有私钥，你无法用证书和公钥对任何东西设置签名。

The signing itself is performed by the `codesign` command line tool. If you compile an application with Xcode, it will be signed by calling `codesign` after building the application — and `codesign` is also the tool that gives you so many nice and helpful error messages. You set the code signing identity in the project settings: 

签名的过程是由命令行命令 `codesign` 来完成的。如果你在 Xcode 中编译一个应用，这个应用构建完成之后会自动调用 `codesign` 命令进行签名，`codesign` 也正是给你提供了许多格式友好并且有用错误信息的那一个工具。你可以在 Xcode 的 project settings 中设置代码签名信息。

![Set up of the code signing identity in Xcode project settings](http://img.objccn.io/issue-17/xcode-code-signing-idenity.png)

Note that Xcode only lets you pick code signing identities in this setting if you have a public and private key in your keychain. So if you expect one to be there, but it isn't, the first thing to check is if you have the private key in your keychain next to your certificate. Here, you also see the division between the development and distribution profiles. If you want to debug an app, you need to sign it with a key pair for development. If you want to distribute it either to testers or the App Store, you need to sign it with a key pair for distribution.

需要注意的是 Xcode 只允许你在有限的选项中进行选择，这些选项都是你既拥有公钥也拥有私钥的证书。所以如果在选项中没有出现你想要的那一个，那么你需要检查的第一件事情就是你是否拥有这个证书的私钥。在这里你需要区分开用于开发测试还是用于发布，如果你想要在机器上测试你的应用，你需要用用于开发测试的那一对密匙来进行签名，如果你是要发布应用，无论是给测试人员还是发布到 APP Store，你需要用用于发布的那一对密匙来进行签名。

For a long time, this was the only setting regarding code signing, short of turning it off. 

一直以来，以上这些就是代码签名需要设置的全部，设置了这些就几乎完成了。

With Xcode 6, the option of setting a provisioning profile appeared in the project settings. If you set a provisioning profile, you can only choose the key pair that has a public key embedded in the certificate of your provisioning profile, or you can have Xcode pick the correct one automatically. But more on that later; let's look at code signing first.

但是在 Xcode 6 的 project settings 中出现了设置配置文件(provisioning profile)的选项。如果你选择了某一个配置文件，你必须选择这个配置文件的证书中所包含的公钥所对应的那个密匙对，或者你可以选择让 Xcode 自动完成正确的设置。关于这方面我们稍后再详细说明，首先还是回到代码签名。

## Anatomy of a Signed App

## 一个已签名应用的组成

The signature for any signed executable is embedded inside the Mach-O binary file format, or in the extended file system attributes if it's a non-Mach-O executable, such as a shell script. This way, any executable binary on OS X and iOS can be signed: dynamic libraries, command line tools, and .app bundles. But it also means that the process of signing your program actually modifies the executable file to place the signature data inside the binary file.

一个已签名的可执行文件的签名包含在文件的 [Mach-O](http://zh.wikipedia.org/wiki/Mach-O) 文件格式中，对于非可执行文件例如脚本就存放在该文件属性的扩展特性中。这种做法使得在 OS X 和 iOS 上的任何可执行二进制文件都可以被设置签名，不论是动态库，命令行工具，还是以 .app 后缀的程序包。这也意味着设置签名的过程实际上会改动可执行文件的文件内容，将签名数据写入二进制文件中。

If you have a certificate and its private key, it's simple to sign a binary by using the `codesign` tool. Let's sign `Example.app` with the identity listed above:

如果你拥有一个证书和它的私钥，那么用 `codesign` 来设置签名非常简单，我们现在尝试用下面列出的这个证书来为 `Example.app` 设置签名

`$ codesign -s 'iPhone Developer: Thomas Kollbach (7TPNXN7G6K)' Example.app`

This can be useful, for example, if you have an app bundle that you want to re-sign. For that, you have to add the `-f` flag, and `codesign` will replace an existing signature with the one you choose:

如果你想为某一个 APP 程序包重新设置签名，那么这个过程会帮助你了解要怎么做。为了重新设置签名，你必须带上 `-f` 参数，有了这个参数 `codesign` 会用你选择的签名替换掉已经存在的那一个。

`$ codesign -f -s 'iPhone Developer: Thomas Kollbach (7TPNXN7G6K)' Example.app`

The `codesign` tool also gives you information about the code signing status of an executable, something that can be especially helpful if things go wrong. 
For example, `$ codesign -vv -d Example.app` will tell you a few things about the code signing status of `Example.app`:

`codesign` 还可以为你提供有关一个可执行文件签名状态的信息，这些信息在出现不明错误时会提供巨大的帮助。举例来说，`$ codesign -vv -d Example.app` 会列出一些有关 `Example.app` 的签名信息：

```
Executable=/Users/toto/Library/Developer/Xcode/DerivedData/Example-cfsbhbvmswdivqhekxfykvkpngkg/Build/Products/Debug-iphoneos/Example.app/Example
Identifier=ch.kollba.example
Format=bundle with Mach-O thin (arm64)
CodeDirectory v=20200 size=26663 flags=0x0(none) hashes=1324+5 location=embedded
Signature size=4336
Authority=iPhone Developer: Thomas Kollbach (7TPNXN7G6K)
Authority=Apple Worldwide Developer Relations Certification Authority
Authority=Apple Root CA
Signed Time=29.09.2014 22:29:07
Info.plist entries=33
TeamIdentifier=DZM8538E3E
Sealed Resources version=2 rules=4 files=120
Internal requirements count=1 size=184
```

The first thing you can look at is the three lines starting with `Authority`. These tell you which certificate it was that actually signed this app. In this case, it was my certificate, the `iPhone Developer: Thomas Kollbach (7TPNXN7G6K)` certificate, which in turn was signed by `Apple Worldwide Developer Relations Certification Authority`, which is signed by, you guessed it, the `Apple Root CA`.

你需要查看的第一件事是以 `Authority` 开头的那三行。这三行告诉你到底是哪一个证书为这个 APP 设置了签名。在这里当然是我的证书，`iPhone Developer: Thomas Kollbach (7TPNXN7G6K)`。这个证书是被证书 `Apple Worldwide Developer Relations Certification Authority` 设置了签名的，以此类推这个证书则是被证书 `Apple Root CA` 设置了签名。

It also tells you something about the code in `Format`: it's not just a bare executable, but a bundle that contains an `arm64` binary. As you can see from the `Executable` path, this is a debug build, so it's a `thin` binary. 

在 `Format` 中也包含了一些关于代码的信息：`Example.app` 并不单单是一个可执行文件，它是一个程序包，其中包含了一个 `arm64` 二进制文件。从 `Executable` 中的路径信息你可以看出，这是一个以测试为目的的打包，所以只是一个比较简单的二进制文件。

Included among a bit of other diagnostics information are two more interesting entries. `Identifier` is the bundle identifier I set in Xcode. `TeamIdentifier` identifies my team (this is what is used by the system to see that apps are published by the same developer). Note that iOS distribution certificates have this very identifier in their names as well, which is useful if you want to distinguish many certificates under the same name. 

在一堆诊断信息中还包含了两个非常有趣的条目。 `Identifier` 是我在 Xcode 中设置的 bundle identifier。 `TeamIdentifier` 用于验证我的工作组（系统会用这个来判断应用是否是由同一个开发者发布）。此外用于发布应用的证书中也包含这种标识，这种标识在区分同一名称下的不同证书时非常有用。

Now the binary is signed with a certificate. This seals the application, much like a seal of wax sealed an envelope in the Middle Ages. So let's check if the seal is unbroken:

现在这个二进制文件已经用证书设置好签名。就像中世纪人用蜡来封印信封一样，签名就这样封印了这个应用。下面我们来检查一下封印是否完好：

```
$ codesign --verify Example.app
$ 
```

This, like any good UNIX tool, tells you the signature is OK by printing nothing. So let's break the seal by modifying the binary: 

就像大多数 UNIX 工具一样，没有任何输出代表签名是完好的。那么我下面破坏这个封印，只要修改一下这个二进制文件：

```
$ echo 'lol' >> Example.app/Example
$ codesign --verify Example.app
Example.app: main executable failed strict validation
```

So code signing works as expected. Mess with the signed app and the seal is broken.

修改已经签名的应用会破坏封印，从命令行输出我们可以看到代码签名正如我们所预期一样起到了作用。

### Bundles and Resources

### 程序包和其他资源文件

For command line tools or scripts, a single executable file is signed, but iOS and OS X applications and frameworks are bundled together with the resources they need. These resources can include images or translation files, but also more critical application components such as XIB/NIB files, archives, or even certificates. Therefore, when signing a bundled application, the resources are signed as well. 

对于命令行工具和脚本来说，只是一个可执行文件被设置签名，但是 iOS 和 OS X 的应用(application)和框架(framework)是包含了他们所需要的资源在其中的。这些资源包括图片和不同的语言文件，资源中也包括很重要的应用组成部分例如 XIB/NIB 文件，存档文件(archives)，甚至是证书文件。所以为一个程序包设置签名时，这个包中的所有资源文件也都会被设置签名。

For this purpose, the signing process creates a `_CodeSignatue/CodeResources` file inside the bundle. This file is used to store the signature of all files in the bundle that are signed. You can take a look at the list for yourself, as this is just a property list file. 

为了达到为所有文件设置签名的目的，签名的过程中会在程序包中新建一个叫做 `_CodeSignatue/CodeResources` 的文件，这个文件中存储了被签名的程序包中所有文件的签名。你可以自己去查看这个签名列表文件，它仅仅是一个 plist 格式文件。

In addition to the list of files and their signatures, this property list contains a set of rules about which resources should be considered in code signing. With the release of OS X 10.10 DP 5 and 10.9.5, Apple changed the code signing format, especially regarding these resource rules. If you use the `codesign` tool on 10.9.5 or later, you will find four sections in the `CodeResources` file: two named `rules` and `files` for older versions, and two named `files2` and `rules2` for the new version 2 code signing. The main change is that now you cannot exclude resources from being signed. You used to be able to use a file called `ResourceRules.plist` inside of the signed bundle to specify files which should not be considered when checking if the seal of a bundle was broken. As of the version 2 code signing, this does not work anymore. All code and resources must be signed — no exceptions. With version 2, the rules only specify that executable bundles inside of a bundle, such as extensions, are signed bundles themselves, and should be checked individually.  

这个列表文件中不光包含了文件和他们的签名列表，还包含了一系列规则，这些规则决定了哪些资源文件应当被设置签名。伴随 OS X 10.10 DP 5 和 10.9.5 版本的发布，苹果改变了代码签名的格式，也改变了有关资源的规则。如果你使用10.9.5或者更高版本的 `codesign` 工具，在 `CodeResources` 文件中会有4个不同区域，其中的 `rules` 和 `files` 是为老版本准备的，而 `files2` 和 `rules2`是为新版本的代码签名准备的。最主要的区别是在新版本中你无法再将某些资源文件排除在代码签名之外，在过去你是可以的，只要在被设置签名的程序包中添加一个名为 `ResourceRules.plist` 的文件，这个文件会规定哪些资源文件在检查代码签名是否完好时应该被忽略。但是在新版本的代码签名中，这种做法不再有效。所有的代码文件和资源文件都必须设置签名，不再可以有例外。在新版本的代码签名规定中，一个程序包中的可执行程序包，例如扩展(extension)，是一个独立的需要设置签名的个体，在检查签名是否完整时应当被单独对待。

## Entitlements and Provisioning 
## 授权和配置文件

Up to this point, we have assumed that all certificates are created equally, and that — if we have a valid certificate — code signing is validated against this. But of course this is not the only rule that is applied. The system always evaluates certain rules to see if your code is allowed to run. 

到目前为止，我们都假设所有的证书起到的作用都是一样的，并且假设如果我们有了一个有效的证书代码签名也就相应的有效。然而这当然不是唯一的标准。操作系统有许多标准来检测你的代码是否允许运行。

These rules are not always the same in all cases. For example, Gatekeeper on OS X can be configured to apply a different policy when starting an application, which is done by changing the setting in the security preferences. Setting this to "Trusted Developers & Mac App Store" requires the apps to be signed by a certificate issued to either a Mac App Store developer for app distribution or a Developer ID certificate. This is controlled by a system tool called `spctl`, which manages the system's security assessment policy.

这些标准并不是一成不变的。举例来说，在 OS X 上一个应用是否允许被开启是由 Gatekeeper 的选项决定的，你可以在系统设置的安全选项中改变选项。在 Gatekeeper 选项中选择“受信任的开发者或者来自 Mac App Store” 会要求被打开的应用必须被证书签名，可以是 Mac App Store 开发者的应用发布证书也可以是开发者 ID 证书。这些选项是由一个系统工具 `spctl` 来管理的，它管理着系统的所有安全评估政策。

On iOS, however, the rules are different. Neither user nor developer can change them: you need an Apple developer or distribution certificate to run an app on iOS. 

在 iOS 上规则是不一样的，无论是用户还是开发者都不能改变应用开启政策，你必须有一个开发者帐号或者应用发布证书才能让应用运行在 iOS 系统上。

But even if you can run an app, there are restrictions on what your app can do. These restrictions are managed by the sandbox. It is important to realize the distinction between the sandbox and the code signing infrastructure. Code signing is used to ensure that the application actually contains only what it says on the box — nothing more and nothing less. The sandbox restricts access to system resources. Both systems work hand in hand, both can keep your code from running, and both can cause strange errors in Xcode. But in everyday development, the sandbox is what gets in your way more often than code signing. When it does, it is mostly due to a mechanism called entitlements.

即使你可以让应用运行起来，在 iOS 上你的应用能做什么依然是受限制的。这些限制是沙盒决定的。沙盒和代码签名机制是不同的，这很重要。代码签名保证了这个应用里所包含的内容正如它所说的那样不多不少，而沙盒则是限制了应用访问系统的资源。这两种技术是相互合作来发挥作用的，他们都能阻止你的应用运行，也都能在 Xcode 中引起奇怪的问题。但是在日常开发过程中，沙盒可能会更经常引起问题。至于沙盒为什么会引起一些问题，大多数情况下都是由于一个叫做授权的机制决定的。

### Entitlements
### 授权机制

Entitlements specify which resources of the system an app is allowed to use, and under what conditions. Basically, it is a configuration list for the sandbox on what to allow and what to deny your application. 

授权机制决定了哪些系统资源在什么情况下允许被一个应用使用。简单的说它就是一个沙盒的配置列表，上面列出了哪些行为被允许，哪些会被拒绝。

Entitlements are specified in — you might have guessed it at this point — a plist format. Xcode provides them to the `codesign` command using the `--entitlements` option. The format looks like this:

很可能你已经猜到授权机制也是按照 plist 文件格式来列出的。Xcode 会将这个文件作为 `--entitlements` 参数的内容传给 `codesign` ，这个文件内部格式如下：

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>application-identifier</key>
        <string>7TPNXN7G6K.ch.kollba.example</string>
        <key>aps-environment</key>
        <string>development</string>
        <key>com.apple.developer.team-identifier</key>
        <string>7TPNXN7G6K</string>
        <key>com.apple.developer.ubiquity-container-identifiers</key>
        <array>
                <string>7TPNXN7G6K.ch.kollba.example</string>
        </array>
        <key>com.apple.developer.ubiquity-kvstore-identifier</key>
        <string>7TPNXN7G6K.ch.kollba.example</string>
        <key>com.apple.security.application-groups</key>
        <array>
                <string>group.ch.kollba.example</string>
        </array>
        <key>get-task-allow</key>
        <true/>
</dict>
</plist>
```

This is the XML generated by Xcode after clicking around in the `Capabilities` tab and enabling a few things. Xcode automatically generates an `.entitlements` file and adds entries to it, as needed. This file is also provided to the codesign tool when building this app, and is the reference on the entitlements your app requests. These entitlements should all be enabled in the developer center's App ID, and embedded in the provisioning profile, but more on that later. The entitlements file used when building the app can be set up in the *Code Signing Entitlements* build setting.

在 Xcode 的 Capabilities 选项卡下选择一些选项之后，Xcode 就会生成这样一段 XML。 Xcode 会自动生成一个 `.entitlements` 文件，然后在需要的时候往里面添加条目。当构建整个应用时，这个文件也会提交给 `codesign` 充当应用拥有哪些授权的参考。这些授权信息必须都在开发者中心的 App ID 中启用，并且包含在配置文件中，稍后我们会详细讨论这一点。在构建应用时需要使用的授权文件可以在 Xcode build setting 中的 code signing entitlements 中设置。

I configured this application to use iCloud key-value storage (`com.apple.developer.ubiquity-kvstore-identifier`) and iCloud document storage (`com.apple.developer.ubiquity-container-identifiers`), added it to an App Group (e.g. for sharing data with extensions, `com.apple.security.application-groups`), and enabled push notifications (`aps-environment`). This is also a development build, so I want to attach the debugger, which means setting `get-task-allow` to `true` is required. In addition to that, it includes the app identifier, which is the bundle identifier prefixed by the team identifier, also listed separately. 

在这个应用中我启用了 iCloud 键值对存储(key-value storage) (`com.apple.developer.ubiquity-kvstore-identifier`) ， iCloud 文档存储 (`com.apple.developer.ubiquity-container-identifiers`)。并将应用添加进一个 App 组 (比如说为了与扩展(extensions)共享数据, `com.apple.security.application-groups`)， 最后开启了推送功能 (`aps-environment`).

Of course, you cannot just claim entitlements as you wish. There are certain rules in place that determine if you can use a certain entitlement or not. For example, an app with `get-task-allow` set to `true` is only allowed to run if the app is signed with a development certificate. The same is true for the `aps-environment` that you are allowed to use.

当然你并不能随心所欲的取得授权，你的应用能否得到某一项授权是由特定的规定的。举例来说，当 `get-task-allow` 被设定为 `ture` 时，应用只能在用于开发的证书签名下运行。你可以使用的推送环境(aps-environment)也存在类似的限制。

The list of entitlements that are available varies betweens OS versions, so an exhaustive list is hard to come by. At least all of the capabilities mentioned in the [Adding Capabilities](https://developer.apple.com/library/mac/documentation/IDEs/Conceptual/AppDistributionGuide/AddingCapabilities/AddingCapabilities.html) section of the Xcode documentation require entitlements. 

根据操作系统版本的不同我们可选的授权项目是不一样的，所以很难有一份列表可以详尽地列出所有条目。至少在文档 [Adding Capabilities](https://developer.apple.com/library/mac/documentation/IDEs/Conceptual/AppDistributionGuide/AddingCapabilities/AddingCapabilities.html) 中提到的所有功能都是需要经过授权的。

The specific entitlements will be embedded in the signature of an application. If you are having trouble, it can help to look at what the signature actually says about the entitlements: `$ codesign -d --entitlements - Example.app` will show an XML property list similar to the one above. You could use this to add it to a build script to ensure that the built app always contains the push notification entitlement, and is therefore able to register for push notifications. The more of Apple's infrastructure you use, the more important this gets. Since Xcode 6, the entitlements list you specify is also embedded in the app bundle as `Example.app.xcent`. As far as I can tell, this is used for providing more helpful error messages when provisioning errors occur.

授权信息会被包含在应用的签名信息中。如果你在这方面遇到了问题，可以尝试查看签名信息中具体包含了什么授权信息： `$ codesign -d --entitlements - Example.app` 会列出一个 XML 格式的 plist 文件，和前面那个很像。你可以将这个文件的内容添加进一个脚本，每次构建应用时用脚本检查是否包含了推送服务的授权信息，以此确保推送服务工作正常。在这里推送服务只是一个例子，你使用的服务越多，这样的检查越重要。在新版本的 Xcode 6 之后，授权信息列表会以类似 `Example.app.xcent` 文件的形式包含在应用包中。在我看来，这么做是为了在出现配置错误时提供更加有用的错误信息。

### Provisioning Profiles
### 配置文件

There is one component of the code signing and sandbox machinery that binds signing, entitlements, and the sandbox together: provisioning profiles.

在整个代码签名和沙盒机制中有一个组成部分将签名，授权和沙盒联系了起来，那就是配置文件(provisioning profiles)。

Every iOS developer has probably spent a lot of hours fixing the provisioning profiles setup, and this is where a lot of problems start.

每一个 iOS 开发者可能都花费过相当的时间研究如何安装配置文件，这个环节也正是会经常出问题的地方。

A provisioning profile is a container for the information needed by the operating system to decide if it can let your app run. This means that if there is trouble with your provisioning profiles, it can become really annoying to fix.  

一个配置文件中存放了系统用于判断你的应用是否允许运行的信息，这就意味着如果你的配置文件有问题，修复起来会相当烦人。

A provisioning profile is a collection of all the components needed to determine if a particular app can run on a particular device. Provisioning profiles are used to enable app debugging on development devices, and also for ad-hoc and enterprise distribution. Xcode will embed the provisioning profile you select in the project settings within the app. As mentioned before, this selection has only been possible since Xcode 6. With Xcode 5 and before, the profile was picked by Xcode based on the certificate you chose when signing the app. As you can have multiple provisioning profiles with the same certificate, this can be a non-deterministic process, so it's always a good idea to select your provisioning profile, now that the option exists. 

一个配置文件是一组信息的集合，这组信息决定了某一个应用是否能够在某一个特定的设备上运行。配置文件可以用于让应用在你的设备上运行，也可以用于内部测试应用的发布(ad-hoc)和企业级应用的发布。Xcode 会将你在 project setting 中选择的配置文件打包进应用。前面提到了，选择配置文件是 Xcode 6 才提供的功能，在 Xcode 5 或更早版本中，配置文件是 Xcode 根据你选择的签名证书来选择的。事实上同一个证书可以拥有多个不同的配置文件，因此让 Xcode 自行选择可能存在一些不确定性，最好的方式是你自主去选择，在 Xcode 6 中终于提供了这个功能。

![Project settings for selecting the provisioning profile](http://img.objccn.io/issue-17/xcode-provisioning-profile.png)

So let's have a closer look at a provisioning profile. If you are looking for a file to play with, look inside `~/Library/MobileDevices/Provisioning Profiles`, which is where Xcode keeps all the profiles downloaded from Apple's developer portal.

我们下面来仔细研究一下配置文件。如果你要在自己的机器上找到配置文件，在这个目录下`~/Library/MobileDevices/Provisioning Profiles` （系统语言是英文）你可以找到 Xcode 从开发者中心下载的全部配置文件。

A provisioning profile is — you might be surprised at this point — not a property list. It is a file encoded in the Cryptographic Message Syntax (or CMS for short, but that is a really bad search keyword), which you might have encountered if you've ever dealt with S/MIME mail or certificates. It is specified in detail by the Internet Engineering Task force in [RFC 3852](http://tools.ietf.org/html/rfc3852). 

不要惊讶，配置文件并不是一个 plist 文件，它是一个根据密码讯息语法(Cryptographic Message Syntax)加密的文件（下文中会简称 CMS，但不要用这个简写 Google，你很可能 Google 不到）。如果你处理过 S/MIME 邮件或者证书你会对这种加密比较熟悉，详细信息可以查看 Internet Engineering Task Force 制定的[RFC 3852](http://tools.ietf.org/html/rfc3852)。

Using the CMS format to encode a provisioning profile allows the profile to be signed, so that it cannot be changed once it has been issued by Apple. This signature is not the same as the code signature of the app itself. Instead, it is signed directly by Apple after being generated by the developer portal.

采用 CMS 格式进行加密使得配置文件仍然可以设置签名，所以在苹果给你这个文件之后文件就不能被改变了。配置文件的签名和应用的签名不是一回事，它是由苹果直接在开发者中心(developer portal)中设置好了的。

You can read this format with some versions of OpenSSL, but not the one that ships with OS X. Luckily for us, the `security` command line utility supports decoding the CMS format. So let's have a look at a `.mobileprovision` file:

某些版本的 OpenSSL 可以读取这种格式，但是 OS X 自带那个版本并不行。幸运的是命令行工具 `security` 也可以读取，那么我们就用 security 来看看一个 `.mobileprovision` 文件内部是什么样子：

`$ security cms -D -i example.mobileprovision`

This will output the contents of the signed message to standard output. If you follow along, you will, once again, see XML of a property list. 

这个命令会输出签名信息中的内容，如果你亲自试一下，接下来你会得到一个 XML 格式的 plist 文件内容输出。

This property list is the actual provisioning profile that iOS uses to determine if your app can run on a particular device. A provisioning profile is identified by its `UUID`. This is the reference that Xcode uses when you select a particular provisioning profile in the build settings in Xcode. 

这个列表中的内容是 iOS 用于判断你的应用是否能运行在某个设备上真正需要的配置信息，每一个配置文件都有它自己的 `UUID` 。Xcode 会用这个 `UUID` 来作为标识，记录你在 build settings 中选择了哪一个配置文件。

The first key is to look at `DeveloperCertificates`, which is a list of all certificates that an app using this provisioning profile can be signed with. If you sign the app with a certificate not in this list, it will not run, no matter if the certificate used for signing is valid or not. The certificates are Base64 encoded and in PEM format (Privacy Enhanced Mail, [RFC 1848](http://tools.ietf.org/html/rfc1848)). To take a closer look at one, copy and paste the encoded text into a file, like this:

首先来看`DeveloperCertificates` 这项，这一项是一个列表，包含了可以为使用这个配置文件的应用签名的所有证书。如果你用了一个不在这个列表中的证书进行签名，那么这个应用就无法运行，无论这个证书是否有效。所有的证书都是基于 Base64 编码符合 PEM (Privacy Enhanced Mail, [RFC 1848](http://tools.ietf.org/html/rfc1848)) 格式的。要查看一个证书的详细内容，将编码过的文件内容复制粘贴到一个文件中去，像下面这样：

```
-----BEGIN CERTIFICATE-----
MIIFnjCCBIagAwIBAgIIE/IgVItTuH4wDQYJKoZIhvcNAQEFBQAwgZYxCzA…
-----END CERTIFICATE-----`
```

Then let OpenSSL do the hard work: `openssl x509 -text -in file.pem`.

然后让 OpenSSL 来处理 `openssl x509 -text -in file.pem`。

Going further along the provisioning profile, you might notice that the key `Entitlements` contains the entitlements for your app, with the same keys as documented in the `Entitlements` section. 

回到配置文件中继续往下看，你可能会注意到在 `Entitlements` 一项中包含了你的应用的所有授权信息，和之前在授权那节看到的一模一样。

These are the entitlements as configured on the developer portal in the App ID section when downloading your provisioning profile. Ideally, they should be in sync with the ones Xcode adds when signing the app, but this can break. And when it does, it is one of the most annoying things to fix.

这些授权信息是你在开发者中心下载配置文件时在 App ID 中设置的，理想的情况下，这个文件应该和 Xcode 为应用设置签名时使用的那一个同步，但这种同步并不能得到保证。这个文件的不一致是比较难发现的问题之一。

For example, if you add an iCloud key-value store entitlement (`com.apple.developer.ubiquity-kvstore-identifier`) in Xcode, but do not update, re-download, and reconfigure the provisioning profile, the provisioning profile states that you do not have this entitlement. If you want to use it, iOS will refuse to let you run your application. This is the reason why a profile will be shown as invalid when you edit the capabilities of your App ID on the developer portal. 

举例来说，如果你在 Xcode 中添加了 iCloud 键值对存储授权 (`com.apple.developer.ubiquity-kvstore-identifier`)，但是没有更新，重新设置并下载新的配置文件，旧的配置文件规定你的应用并没有这一项授权。那么如果你的应用使用了这个功能，iOS 就会拒绝你的应用运行。这也是为什么当你在开发者中心编辑了应用的授权，那个配置文件就会被标记为无效。

If you are looking at a development certificate, you will also find a `ProvisionedDevices` key, which contains a list of all the devices you set up for this provisioning profile. Because the profile needs to be signed by Apple, you need to download a new one each time you add a device to the developer portal. 

如果你打开的是一个用于开发测试的证书，你会看到一项 `ProvisionedDevices`，在这一项里包含了所有可以用于测试的设备列表。因为配置文件需要被苹果签名，所以每次你添加了新的设备进去就要重新下载新的配置文件。

## Conclusion
## 小结

The code signing and provisioning machinery might be one of the most complex things an iOS developer has to deal with, short of coding. It's certainly a very different experience then just compiling and running your code like you would on a Mac or PC. 

代码签名和配置文件这一套大概是一个 iOS 开发者会遇到的最复杂的问题之一，仅次于编码。与在 Mac 或 PC 上直接的编译运行你的代码不同，处理这些问题会是非常不同的经历。

While it helps to understand the components at work, it still can get very cumbersome to keep all settings and tools under control — especially when working in teams, passing around certificates and profiles can be a very unwieldy task. While Apple tried to improve things in the last few releases of Xcode, I'm not sure every change is an improvement for the better. It certainly is a big dent in any developer's productivity to deal with code signing. 

虽然了解每一个部分是怎么运作的很有帮助，但是要控制好所有这些设置和工具其实是一件很消耗时间的事情，特别是在一个开发团队中，到处发送证书和配置文件显然很不方便。虽然苹果在最近几次发布的 Xcode 中都尝试改善，但是我不是很确定每一项改动都起到了好的作用。处理代码签名是每个开发者必过的大坑。

Although all of this effort is very tedious for the developer, it has made iOS arguably one of the most secure end-user computing platforms out there. If you keep an eye on the security-related news, each time there is a new Trojan or malware, such as the infamous [FinFisher](https://en.wikipedia.org/wiki/FinFisher) that claims to work on iOS, look at the fine print. I have yet to encounter iOS-targeted malware where it did not say "requires jailbreak" in the fine print. 

虽然处理代码签名对于开发者来说非常繁琐，但不可否认正是它使得 iOS 对于用户来说是一个非常安全的操作系统。如果你注意安全相关的新闻，每一次出现号称能在 iOS 上运行的木马或者恶意软件，例如不怎么出名的 [FinFisher](https://en.wikipedia.org/wiki/FinFisher)，我还没有发现一个不注明“需要越狱”的，当然这个注明可以不那么明显。

So going through all this hassle isn't for naught.

所以为代码签名和配置文件进行的这些麻烦设置并不是徒劳无功。

