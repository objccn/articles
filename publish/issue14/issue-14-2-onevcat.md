Mac 应用间的脚本在桌面生态系统中已经存在很长时日了。它最早于 1993 年 10 月作为 System 7 的一部分，用来为像 QuarkXPress 这样的出版相关应用创建复杂的工作流，以方便使用。从那以后，很多应用通过使用脚本字典来支持 AppleScript ([Brent 的文章](http://objccn.io/issue-14-1/)向你展示了如何实现)。在这篇文章里，我会解释如何使用脚本字典里的命令和对象来与其他的应用进行通讯。

但在我们开始之前，我们需要看看最近在 Mac 平台发生的一些事情。在 2010 年底 Mac App Store 开张之后，Apple 宣布所有开发者所提交的应用必须在 2011 年 11 月之前跑在沙盒里。这个最后期限被推迟了数次，最后他在 2012 年的六月一号成为了现实。

想让 Mac 应用运行在沙盒中实属不易，相信这一点从不断被推迟的最后期限中你就可以寻得蛛丝马迹。与之相对，iOS 应用一直就需要运行在沙盒里。一些资深的开发者会明白，一个安全的环境同时也意味着他们的应用要做重大的改变。我从一个 Apple 的负责安全的工程师那里听到过一句话：“我们正在试图把打开的潘多拉盒子关上，这可不是一件容易事儿。”

其中一个主要的挑战就是要处理那些使用了 AppleScript 的应用。很多本来很简单的功能突然就变得很困难了，有些事情甚至完全不可能完成。造成这么让人沮丧的主要原因是应用不再能任意地通过脚本来控制其他的应用了。为了安全考虑，有非常多的理由可以证明允许这么做并不是什么好主意。但是从开发者或者顾客的视角来看的话，就是很多东西用不了了。

起初，Apple 通过在应用的权限声明里引入并许可'暂时例外'的方式来帮助过渡。这些例外可以允许应用维持本来已经应该丧失了的功能。但是也正如名字所示，它们中的很多特例也正在消失，因为在最近版本的 OS X 中，一些作为替代手段的控制别的应用的方法已经可以使用了。

这个教程将向您展示现在使用 AppleScript 来控制别的应用的最佳方式。我也会告诉您一些小技巧以帮助您和您的用户用最小的努力就架设起 AppleScript。

## 第一步

你需要学习的第一件事是如何在你自己的应用里跑 AppleScript。通常来说，最困难的部分是写出 AppleScript 的代码。来看看吧：

	on chockify(inputString)
		set resultString to ""
	
		repeat with inputStringCharacter in inputString
			set asciiValue to (ASCII number inputStringCharacter)
			if (asciiValue > 96 and asciiValue < 123) then
				set resultString to resultString & (ASCII character (asciiValue - 32))
			else
				if ((asciiValue > 64 and asciiValue < 91) or (asciiValue = 32)) then
					set resultString to resultString & inputStringCharacter
				else
					if (asciiValue > 47 and asciiValue < 58) then
						set numberStrings to {"ZERO", "ONE", "TWO", "THREE", "FOR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE"}
						set itemIndex to asciiValue - 47
						set numberString to item itemIndex of numberStrings
						set resultString to resultString & numberString & " "
					else
						if (asciiValue = 33) then
							set resultString to resultString & " DUH"
						else
							if (asciiValue = 63) then
								set resultString to resultString & " IF YOU KNOW WHAT I MEAN"
							end if
						end if
					end if
				end if
			end if
		end repeat
	
		resultString
	end chockify

在我看来，AppleScript 最大的优点并不在于它的语法，也不是它在处理字符串上的能力，虽然这些都做得超级棒。

当开发像这样的脚本時，我通常会去查阅 [AppleScript 脚本指南](https://developer.apple.com/library/mac/documentation/applescript/conceptual/applescriptlangguide/introduction/ASLR_intro.html#//apple_ref/doc/uid/TP40000983-CH208-SW1)。好消息是与其他应用进行通讯的脚本一般来说都很短，也容易理解。AppleScript 可以被想做一种传送的机制，而不是一种处理环境。上面展示的脚本就很典型。

一旦你写好了脚本并且完成了测试，你就可以回到你的 Objective-C 的舒适的小窝了。你可能会写下的第一行代码会将你通过时光旅行带回到 Carbon 年代：

	#import <Carbon/Carbon.h> // for AppleScript definitions

放轻松，你不需要做一些比如将整个 Carbon 框架导入项目的疯狂举动。你所需要的只是 Carbon.h，因为它有关于所有的 AppleEvent 的定义。记住，这些代码已经在那儿超过 20 年了！

在有了定义之后，你就可以创建事件描述符 (event descriptor) 了。这是可以在你的脚本和应用之间互相传递的一个数据块。现在的话，你可以把它想象成一个封装好的会去执行某个事件的目标，一个将被调用的函数，以及这个函数的参数。在这里我们为上面的 "chockify" 创建了事件描述符，使用一个 `NSString` 作为参数：

	- (NSAppleEventDescriptor *)chockifyEventDescriptorWithString:(NSString *)inputString
	{
		// parameter
		NSAppleEventDescriptor *parameter = [NSAppleEventDescriptor descriptorWithString:inputString];
		NSAppleEventDescriptor *parameters = [NSAppleEventDescriptor listDescriptor];
		[parameters insertDescriptor:parameter atIndex:1]; // you have to love a language with indices that start at 1 instead of 0
	
		// target
		ProcessSerialNumber psn = {0, kCurrentProcess};
		NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
		// function
		NSAppleEventDescriptor *function = [NSAppleEventDescriptor descriptorWithString:@"chockify"];
	
		// event
		NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
		[event setParamDescriptor:function forKeyword:keyASSubroutineName];
		[event setParamDescriptor:parameters forKeyword:keyDirectObject];
	
		return event;
	}

_注意：_ 这些代码放在了 [GitHub](https://github.com/objcio/issue-14-sandbox-scripting) 上。`Automation.scpt` 文件包含了 chockify 函数和本教程中用到的其他脚本。Objective-C 的代码全都在 `AppDelegate.m` 中。

现在你有一个事件描述符了。它用来告诉 AppleScript 你想做的事情，你还得让它有个什么去处吧。这意味着你需要从你的应用包 (application bundle) 里加载 AppleScript。

	NSURL *URL = [[NSBundle mainBundle] URLForResource:@"Automation" withExtension:@"scpt"];
	if (URL) {
		NSAppleScript *appleScript = [[NSAppleScript alloc] initWithContentsOfURL:URL error:NULL];
	
		NSAppleEventDescriptor *event = [self chockifyEventDescriptorWithString:[self.chockifyInputTextField stringValue]];
		NSDictionary *error = nil;
		NSAppleEventDescriptor *resultEventDescriptor = [appleScript executeAppleEvent:event error:&error];
		if (! resultEventDescriptor) {
			NSLog(@"%s AppleScript run error = %@", __PRETTY_FUNCTION__, error);
		}
		else {
			NSString *string = [self stringForResultEventDescriptor:resultEventDescriptor];
			[self updateChockifyTextFieldWithString:string];
		}
	}

通过应用包的一个 URL 可以创建 `NSAppleScript` 的实例。而反过来，脚本也要和上面创建的 chockify 事件描述符一起使用、如果一切正常的话，你会得到另一个事件描述符。如果出错了，你会得到一个包含了描述错误信息的字典。虽说这个模式和很多其他 Foundation 类很相似，但是返回的错误**并不是**一个 `NSError` 的实例。

现在就剩从描述符中抽取出你想要的结果了：

	- (NSString *)stringForResultEventDescriptor:(NSAppleEventDescriptor *)resultEventDescriptor
	{
		NSString *result = nil;
	
		if (resultEventDescriptor) {
			if ([resultEventDescriptor descriptorType] != kAENullEvent) {
				if ([resultEventDescriptor descriptorType] == kTXNUnicodeTextData) {
					result = [resultEventDescriptor stringValue];
				}
			}
		}
	
		return result;
	}

InputString 输入可以被正确整形输出，并且你现在也看到想在你的应用里运行 AppleScripts 的方法了。


## 曾经的方式

曾经有一段时间你是可以将 AppleEvents 发送到任意应用的，而不仅仅是当前运行的应用，就像我们上面的 chockify 里做的那样。

比如你想知道 Safari 里现在最前面的窗口加载的 URL 地址是什么，你需要做的就是通过 `tell application "Safari"` 告诉 Safari 要做什么。

	on safariURL()
		tell application "Safari" to return URL of front document
	end safariURL

现在的话，可能得到的就只有 Debug Console 中的下面的输出了：

	AppleScript run error = {
		NSAppleScriptErrorAppName = Safari;
		NSAppleScriptErrorBriefMessage = "Application isn\U2019t running.";
		NSAppleScriptErrorMessage = "Safari got an error: Application isn\U2019t running.";
		NSAppleScriptErrorNumber = "-600";
		NSAppleScriptErrorRange = "NSRange: {0, 0}";
	}

就算其实 Safari 是在运行的。买了个表..

## 沙盒限制

这是因为正尝试在应用的沙盒中运行脚本。考虑到在沙盒里，Safari 事实上确实没有在运行。

问题在于没有人授予你访问 Safari 的权限。这其实和一个很大的安全漏洞相关：一段脚本可以轻易地拿到浏览器当前页面上的内容，甚至是在任意标签和窗口运行 JavaScript。想象一下如果这些页面里有你的银行账号，或者包含你的信用卡信息什么的。好疼..

这也就是为什么从 Mac App Store 获取的应用的脚本不能随便执行的原因。

不过事情在最近的 OS X 版本中有所改善。在 10.8 山狮中， Apple 引入了一个新的抽象类 `NSUserScriptTask`。有三个具体的子类实现让你分别可以运行 Unix shell 命令 (`NSUserUnixTask`)，Automator 工作流 (`NSUserAutomatorTask`) 以及我们最喜爱的 AppleScript(`NSUserAppleScriptTask`)。教程的接下来的部分将会专注于最后一类，因为这也是最常用的类。

对于沙盒应用，Apple 所提倡的是通过用户的需要来驱动安全策略。实际操作上来说，这意味着用户需要决定是否想要运行你的脚本。这些脚本可能是来自互联网，也可能是你的应用的一部分，这并不关键。唯一相关的事情是你的用户表示“好的，我想要运行这个脚本”。一旦得到了权限，脚本就可以以一种受限的方式与系统其他部分进行交互了。`NSUserScriptTask` 类使这一切变得可能。

## 安装脚本

那么，想要运行脚本的应用要怎么向用户请求许可呢？

机制超级简单：你的应用只能从用户的账户里的一个特定的文件夹中运行脚本。而脚本想要进入这个文件夹的唯一方式就是用用户把它们复制到那里。本质上来说，OS X 将这些脚本通过只读的方式提供给你使用。

现在的挑战是：这个特定的文件夹是 User > Library > Application Scripts 然后跟着是应用的 bundle identifier。对于我们的 [Scriptinator](https://github.com/chockenberry/Scriptinator)，文件夹的名字大概只有程序员会喜欢：`com.iconfactory.Scriptinator`。两者对用户都很不友好，特别是 Library 文件夹在 OS X 里默认还是隐藏的。

解决这个问题的一个方法是实现一些代码来为用户打开这个隐藏文件夹，比如：

	NSError *error;
	NSURL *directoryURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
	[[NSWorkspace sharedWorkspace] openURL:directoryURL];

这对于用户自己写的脚本来说是个很好的解决方案。用户可以通过你的应用的某个控件打开这个文件夹，然后进行编辑。

但是有时候你想要帮助最终用户将你已经写好的脚本安装到这个目录里。很自然的，作为程序员，你的编程水平应该比你的用户的平均水平要强吧，你也更明白应该如何写代码让你的应用与用户的其他应用更好地工作在一起。很自然地，存放这些你自己的脚本的理想的地方是应用包里，但是要怎么样才能把这些脚本放到用户的脚本文件夹离去呢？

解决的方法是获取对这个文件夹的写入权限。在 Xcode 里，你需要更新你的应用的 Capabilities，让其包括 "User Selected File to Read/Write"。你可以在 App Sandbox > File Access 里找到相关选项。再一次，用户的意愿是关键，因为你需要获取权限以将脚本添加到文件夹：

	NSError *error;
	NSURL *directoryURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setDirectoryURL:directoryURL];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setPrompt:@"Select Script Folder"];
	[openPanel setMessage:@"Please select the User > Library > Application Scripts > com.iconfactory.Scriptinator folder"];
	[openPanel beginWithCompletionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			NSURL *selectedURL = [openPanel URL];
			if ([selectedURL isEqual:directoryURL]) {
				NSURL *destinationURL = [selectedURL URLByAppendingPathComponent:@"Automation.scpt"];
				NSFileManager *fileManager = [NSFileManager defaultManager];
				NSURL *sourceURL = [[NSBundle mainBundle] URLForResource:@"Automation" withExtension:@"scpt"];
				NSError *error;
				BOOL success = [fileManager copyItemAtURL:sourceURL toURL:destinationURL error:&error];
				if (success) {
					NSAlert *alert = [NSAlert alertWithMessageText:@"Script Installed" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The Automation script was installed succcessfully."];
					[alert runModal];
				}
				else {
					NSLog(@"%s error = %@", __PRETTY_FUNCTION__, error);
					if ([error code] == NSFileWriteFileExistsError) {
						// this is where you could update the script, by removing the old one and copying in a new one
					}
					else {
						// the item couldn't be copied, try again
						[self performSelector:@selector(installAutomationScript:) withObject:self afterDelay:0.0];
					}
				}
			}
			else {
				// try again because the user changed the folder path
				[self performSelector:@selector(installAutomationScript:) withObject:self afterDelay:0.0];
			}
		}
	}];

这么一来，应用包中的 `Automation.scpt` 文件现在暴露在常规的文件系统中了。

在整个流程中让你的用户确实知道他们在做什么是很重要的。你必须记住，是你的用户在控制你的脚本，而不是你。用户可能会决定将所有脚本清理出脚本文件夹，而你必须做对应的处理。你可能会需要禁用某些依赖于这个脚本的特性，或者解释为什么脚本需要在再次安装。

_注意：_ [Scriptinator](https://github.com/chockenberry/Scriptinator) 的示例代码包括了上面两种策略。如果你想看看现实的例子，不妨研究下 [Overlay](http://xscopeapp.com/guide#overlay) [xScope](http://xscopeapp.com/) 的免费试用版。应用里有一个对用户很友好的脚本设置步骤，以使应用能够呵用户的网页浏览器进行通讯。还有一个好处是，你也许会发现 xScope 真的是一个进行开发的很棒的工具！（译者注：本文作者是 xScope 的合作开发者，同时也是 Twitterrific 的开发者，所以这里也算个小的软广告）

## 脚本任务

现在你的自动化脚本在正确的位置了，你可以开始使用它们了。

在下面的代码中，我们在上面创建的事件描述符没有改变，唯一不一样的是它们是如何被运行的：你需要使用 `NSUserAppleScriptTask` 来替代 `NSAppleScript`。

你大概会经常用到这些脚本任务。文档警告说对于给定的类的某个实例， `NSUserAppleScriptTask` 不应该被执行多次。所以写一个工厂函数来在需要的时候创建任务会是一个好主意：

	- (NSUserAppleScriptTask *)automationScriptTask
	{
		NSUserAppleScriptTask *result = nil;
	
		NSError *error;
		NSURL *directoryURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
		if (directoryURL) {
			NSURL *scriptURL = [directoryURL URLByAppendingPathComponent:@"Automation.scpt"];
			result = [[NSUserAppleScriptTask alloc] initWithURL:scriptURL error:&error];
			if (! result) {
				NSLog(@"%s no AppleScript task error = %@", __PRETTY_FUNCTION__, error);
			}
		}
		else {
			// NOTE: if you're not running in a sandbox, the directory URL will always be nil
			NSLog(@"%s no Application Scripts folder error = %@", __PRETTY_FUNCTION__, error);
		}

		return result;
	}

如果你正在写一个同时适用于沙盒和非沙盒的 Mac 应用的话，在获取 `directoryURL` 时你需要特别小心。`NSApplicationScriptsDirectory` 只在沙盒中有效。

在创建脚本任务后，你需要使用 AppleEvent 并提供一个结束处理来执行它：

	NSUserAppleScriptTask *automationScriptTask = [self automationScriptTask];
	if (automationScriptTask) {
		NSAppleEventDescriptor *event = [self safariURLEventDescriptor];
		[automationScriptTask executeWithAppleEvent:event completionHandler:^(NSAppleEventDescriptor *resultEventDescriptor, NSError *error) {
			if (! resultEventDescriptor) {
				NSLog(@"%s AppleScript task error = %@", __PRETTY_FUNCTION__, error);
			}
			else {
				NSURL *URL = [self URLForResultEventDescriptor:resultEventDescriptor];
				// NOTE: The completion handler for the script is not run on the main thread. Before you update any UI, you'll need to get
				// on that thread by using libdispatch or performing a selector.
				[self performSelectorOnMainThread:@selector(updateURLTextFieldWithURL:) withObject:URL waitUntilDone:NO];
			}
		}];
	}

对于用户写的脚本，用户可能期望你的应用只是简单地'运行'脚本 (而不去调用事件描述符中指定的函数)。在这种情况下，你可以为 event 传递一个 `nil`，脚本就会像用户在 Finder 中双击那样的行为进行执行。

`NSUserAppleScriptTask` 中很好的一个东西就是结束时候的回调处理。脚本是异步执行的，所以你的用户界面并不会被一个 (比较长) 的脚本锁住。要小心你在结束回调中做的事情，因为它并不是跑在主线程上的，所以你不能在那儿对你的用户界面做更新。


## 幕后

背后发生了些什么事情呢？

也许你从脚本只能异步地运行一次这个事实中猜到了，这些代码现在是通过 XPC 执行的。就像 iOS 8 中使用 XPC 来确保扩展不会影响调用应用那样，在 Mac 应用中运行的脚本也无法访问调用应用的内存地址空间。

如果你看看接收的事件描述符的 `keySenderPIDAttr` 属性的话，你会发现进程 ID 属于 `/usr/libexec/lsboxd`，而不是你的应用程序。这个迷之进程大概是 Launch Services 的沙盒守护进程。无论怎样，你向其他进程的请求肯定基本都是要被封送 (marshalling) 的。

如果想在更高层级理解关于应用沙盒的安全目标的内容，我推荐看看 Ivan Krstić 在 [WWDC 2012](https://developer.apple.com/videos/wwdc/2012/) 的 _"The OS X App Sandbox"_ 的演讲、很出乎意料的是，这个演讲非常有意思，在 36 分钟的演讲中，他介绍了在上面提到的关于自动化的改变。同一次大会中，Sal Soghoian 和 Chris Nebel 带来的 _"Secure Automation Techniques in OS X"_ 深入讲解了自动化的改变。如果你只想学习关于应用运行的用户脚本方面的内容，你可以跳过前 35 分钟的内容。

在这些演讲中讨论了另一个很重要的安全方面的内容是访问组 (access group)，我们在这个教程中并没有涉及这方面的内容。如果你想要用脚本控制像邮件或者 iTunes 这样的系统应用，你绝对需要特别关注一下上面提到的视频中有关这方面的内容。

## 同步

正如我上面提到的，`NSAppleScript` 和 `NSUserAppleScriptTask` 有一个微妙的区别：新的机制是异步执行的。对于大部分情况，使用一个结束回调来处理会是一个好得多的方式，因为这样就不会因为执行脚本而阻碍你的应用。

然而有时候如果你想带有依赖地来执行任务的时候，事情就变得有些取巧了。比方说一个任务需要在另一个任务开始之前必须完成。这种情况下你就会想念 `NSAppleScript` 的同步特性了。

要获得传统方式的行为，一种简单的方法是使用一个信号量 (semaphore) 来确保同时只有一个任务运行、在你的类或者应用的初始化方法中，使用 `libdispatch` 创建一个信号量：

	self.appleScriptTaskSemaphore = dispatch_semaphore_create(1);

接下来在初始化脚本任务之前，简单地等待信号量。当任务完成时，标记相同的这个信号量：

	// wait for any previous tasks to complete before starting a new one — remember that you're blocking the main thread here!
	dispatch_semaphore_wait(self.appleScriptTaskSemaphore, DISPATCH_TIME_FOREVER);
	
	// run the script task
	NSAppleEventDescriptor *event = [self openNetworkPreferencesEventDescriptor];
	[automationScriptTask executeWithAppleEvent:event completionHandler:^(NSAppleEventDescriptor *resultEventDescriptor, NSError *error) {
		if (! resultEventDescriptor) {
			NSLog(@"%s AppleScript task error = %@", __PRETTY_FUNCTION__, error);
		}
		else {
			[self performSelectorOnMainThread:@selector(showNetworkAlert) withObject:nil waitUntilDone:NO];
		}
		
		// the task has completed, so let any pending tasks proceed
		dispatch_semaphore_signal(self.appleScriptTaskSemaphore);
	}];

再强调一下，除非确实有所需要，否则最好别这么做。


## 你能写什么样的脚本

在最后这个例子中，系统偏好设置面板中的网络面板通过下面的 AppleScript 代码可以被打开：

	tell application "System Preferences"
		launch
		activate
		
		reveal pane id "com.apple.preference.network"
	end tell

很棒，但是你是怎么知道这些各种面板的 ID 的？如果想打开的不是网络面板，辅助功能或者是安全性与隐私面板的话，要怎么做呢？

正如你在 Brent 的文章中看到的那样，每一个支持 AppleScript 的应用都有一个脚本字典。这个字典描述了应用数据模型的对象和属性。所以我们只需要查看数据模型就可以找到你想要的东西了！

首先从你的 应用 > 其他 文件夹中打开脚本编辑器。然后从文件菜单中，选取"打开字典..."。在这里，所有支持 AppleScript 的应用都会被陈列出来 - 可能比你想象的要多！选择系统偏好设置，并且点选"选取"。

在这里，你将看到一个标准套件 (Standard Suite) 和系统偏好设置 (System Preferences) 的树形浏览器。标准套件里列出了像 "open" 这样的命令，"window" 这样的类，以及其他一些对大多数脚本字典来说都通用的东西。有意思的是另一个脚本套件：System Preferences。当你选择它后，你会看到一个叫做 "reveal" 的命令以及三个类 (对象类型)，分别叫做 "application"，"pane" 和 "anchor"。

当你查看 "application" 的话，你会看到两个东西：元素 (elements) 和属性 (properties)。元素是被所选对象管理的一组对象集合。属性列出了备选对象所维护的数据。

<img src="/images/issues/issue-14/Scripting_Dictionary.png" />

applicaiton 里含有 panes，听起来就是它。在一个新的脚本编辑器窗口中，创建一个简单的脚本来显示所有的面板对象：

	tell application "System Preferences"
		panes
	end tell

我们的目标是打开辅助功能界面的安全面板，于是我们可以在输出结果中查找，知道我们看到类似这样的有用的东西：

	pane id "com.apple.preference.security" of application "System Preferences"

查看它的 "localized name" 属性：

	tell application "System Preferences"
		localized name of pane id "com.apple.preference.security"
	end tell

输出为 Security & Privacy。就是它！现在我们尝试使用之前见过的 "reveal" 命令和 "pane id" 另外写一个脚本

	tell application "System Preferences"
		reveal pane id "com.apple.preference.security"
	end tell

系统偏好设置为我们打开了这个面板。现在让我们来看看怎么打开特定的 tab 视图。首先通过 pane 里包含的唯一的元素，anchor 对象，来查询一下：

	tell application "System Preferences"
		anchors of pane "com.apple.preference.security"
	end tell

哈哈，我们看到：

	anchor "Privacy_Accessibility" of pane id "com.apple.preference.security" of application "System Preferences"

这就是我们想要的。这里也显示了系统偏好设置的结构：一个应用含有 pane，而 pane 含有 anchors。我们调整一下我们的脚本：


	tell application "System Preferences"
		reveal anchor "Privacy_Accessibility" of pane id "com.apple.preference.security"
	end tell

完成！现在想象一下如果你的应用需要用户赋予控制电脑的权限的时候，比起告诉用户如何在偏好设置面板里打开对应面板，你现在直接为用户打开了这个面板，干得漂亮。


## 总结

你学到了通过你自己的应用去控制别的应用的时候所需要知道的一切。不管你是想让用户可以创建他们自己的自动化工作流，还是只是想在你的应用中启用一些内部功能，就算只能运行在沙盒里，AppleScript 依旧都是每个 Mac 应用的强有力的部件。希望这篇教程能给你带来新的工具和视野，并且在之后你自己的项目中使用这些特性时有所帮助。

---

 

原文 [Scripting from a Sandbox](http://www.objc.io/issue-14/sandbox-scripting.html)

