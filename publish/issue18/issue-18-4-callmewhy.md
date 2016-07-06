多点互联 ([Multipeer Connectivity](https://developer.apple.com/library/iOS/documentation/MultipeerConnectivity/Reference/MultipeerConnectivityFramework/index.html)，即 MPC) 是在 2013 年的 WDCC 中提出的，期间做过不少宣传，但是却很少有案例能够成功有效地使用它。接下来，就让我们来看一看如何正确使用 MPC，尤其是在游戏中的应用。

## 什么是多点互联

多点互联是苹果的一个传输无关的网络框架，提供网络的发现、创建和通信功能。可以说它是 [Bonjour](https://www.apple.com/support/bonjour) 的精神传承者， Bonjour 可以在 LAN 和 Wi-Fi 的网络下高效地识别设备。

MPC 的关键用途在于创建临时网络中的点对点连接，而不需要考虑天气、无线、蓝牙等各种因素，只需要有个人网络就行。一旦创建之后，各个节点可以安全地共享消息、数据和文件资源。

绝大部分 MPC 的功能在更高层的 [GameKit](https://developer.apple.com/LIBRARY/ios/documentation/GameKit/Reference/GameKit_Collection/index.html) 框架中都可以找到。使用 GameKit 可以让开发者接触到有用的游戏概念，抽离底层的网络协议。

大部分的游戏都更适合用 GameKit 开发，它有很多直接使用 MPC 实现的游戏相关的封装。不过作为 MPC 的进阶手册，本文主要涉及 MPC 的各种使用技巧。

## 什么时候该用

当你的游戏或应用需要在近距离的多台设备中进行连接的时候， MPC 可以大幅提高用户体验。不论你是想要建立一个远程控制还是多人游戏， MPC 都可以帮助你减少用户使用过程中的阻力，减少服务器的开销，甚至可以减少网络延时等问题。

比如一个远程控制的应用，如果它不需要用户进行任何设置，而是在安装后立即自动连接到被控制端上，那么应用的品质会得到很大的提升。不论这个远程控制针对的是游戏、软件展示、音频播放还是其他东西，都是这样。[DeckRocket](https://github.com/jpsim/DeckRocket) 就是一个很好的开源的例子，它是一个用来远程遥控 [DeckSet](http://www.decksetapp.com/) 幻灯片的 iOS 应用。

多用户游戏也可以从 MPC 的零配置和离线连接特性中受益。比如一个包含游戏逻辑、规则和存档功能的卡牌类游戏，可以在不联网的状态下让任意两名玩家进行即时对战。在这篇文章里，我们将会从 CardsAgainst 这个真实的应用中选取一些例子进行说明。 CardsAgainst 是著名游戏 [Cards Against Humanity](http://cardsagainsthumanity.com/) 的开源 iOS 版本，完整的项目源代码可以在 [Github](https://github.com/jpsim/CardsAgainst) 获取。

本文中的其他示例则选自 [PeerKit](https://github.com/jpsim/PeerKit)，一个 Github 上的开源框架，用来构建事件驱动且无需配置的 MPC 应用。

## 发现设备的相关设置

有很多种方法可以把 MPC 的设备侦测概念整合到应用中。接下来我们将介绍三种广泛使用的设计模式。

### 方法一：默认方式

苹果提供了一个内置的 ViewController ，可以很方便地进行匹配和初始化连接。只需要设置好 `serviceType` 和 `session` 并且弹出一个 [MCBrowserViewController](https://developer.apple.com/library/IOs/documentation/MultipeerConnectivity/Reference/MCBrowserViewController_class) 即可，MPC 会帮你做好剩下的事情。注意，`serviceType` 最多是 15 位 ASCII 字符。使用方法通常像逆向的 DNS 标记一样 (例如： io-objc-mpc)：

    let session = MCSession(peer: MCPeerID(displayName: "Mary"))
    let serviceType = "io-objc-mpc" // 最多 15 ASCII 字符
    window!.rootViewController = MCBrowserViewController(serviceType: serviceType, session: session)

![](/images/issues/issue-18/browser.png)

不过，我们无法轻易地对 `MCBrowserViewController` 进行自定义，而你有可能想设置自己的匹配原则，那么请移步下面的章节。

### 方法二：专门的公示者 (Advertiser) / 浏览者 (Browser)

如果你的游戏的匹配机制是先选取一个主节点来协调游戏逻辑，然后其他次节点和主节点进行连接，那么你应该充分利用这些信息，只需要从主节点进行公示，然后次节点进行浏览即可：

![](/images/issues/issue-18/dedicated.gif)

    // 主节点公示
    advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
    advertiser.delegate = self
    advertiser.startAdvertisingPeer()

    // 次节点浏览
    mcBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
    mcBrowser.delegate = self
    mcBrowser.startBrowsingForPeers()

但是，总是有那么一些情况，最好能在应用运行之前就建立好连接，而不用用户进行任何操作。下面的章节就展示了如何实现这样的功能。

### 方法三：零配置

MPC 能够极大地减少用户体验的阻力。当你以正确的方式把它整合到应用中时，你的用户可以在安装应用之后立即开始通信，而不用任何配置。这会是一件大快所有人心的大好事。

![](/images/issues/issue-18/zero-config.gif)

为了实现这个功能，我们需要同时对会话进行公示和查看，我们把这种行为称之为 收发 (transceiving = transmitting and receiving)。

在多节点进行收发的时候，竞争问题是一个重大的挑战，因为可能会有很多节点同时尝试连接彼此。这便是[领袖选举 (Leader Election)](http://en.wikipedia.org/wiki/Leader_election) 问题，这个问题已经被深入地讨论和研究，并且有一些很好地解决方案。

下面介绍一种简单而有效的方法。在邀请其他节点加入会话的时候，将每个节点的运行时间包含到元数据 (metadata) 里，公示的节点总是加入到最早的会话中：

    // 浏览者的委托代码
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        var runningTime = -timeStarted.timeIntervalSinceNow
        let context = NSData(bytes: &runningTime, length: sizeof(NSTimeInterval))
        browser.invitePeer(peerID, toSession: mcSession, withContext: context, timeout: 30)
    }

    // 公示者的委托代码
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        var runningTime = -timeStarted.timeIntervalSinceNow
        var peerRunningTime = NSTimeInterval()
        context.getBytes(&peerRunningTime)
        let isPeerOlder = (peerRunningTime > runningTime)
        invitationHandler(isPeerOlder, mcSession)
        if isPeerOlder {
            advertiser.stopAdvertisingPeer()
        }
    }

## 发送和接受

MPC 提供了几种发送和接收数据的方式，每种方式都有自己独有的特点和取舍。

### 发送数据

当发送少量事件驱动的数据 (最多几 kb) 的时候，比如游戏事件 (开始/暂停/退出)，使用这个方法：`sendData(_:toPeers:withMode:error:)`。

为了封装传输的数据，CardsAgainst 定义了一个游戏事件的枚举类型，在接下来对随行的数据进行序列化和反序列化的时候也会用到：

    // 所有的游戏事件
    enum Event: String {
        case StartGame = "StartGame",
        Answer = "Answer",
        CancelAnswer = "CancelAnswer",
        Vote = "Vote",
        NextCard = "NextCard",
        EndGame = "EndGame"
    }

    // 可靠地 (使用 .Reliable 模式) 向节点发送事件，有可能有随行数据
    func sendEvent(event: Event, object: AnyObject? = nil, toPeers peers: [MCPeerID] = session.connectedPeers as [MCPeerID]) {
        if peers.count == 0 {
            return
        }
        var rootObject: [String: AnyObject] = ["event": event.rawValue]
        if let object = object {
            rootObject["object"] = object
        }
        let data = NSKeyedArchiver.archivedDataWithRootObject(rootObject)
        session.sendData(data, toPeers: peers, withMode: .Reliable, error: nil)
    }

    // 使用例
    sendEvent(.StartGame, ["initialData": "hello objc.io!"])

具体内容可以参考 [ConnectionManager.swift](https://github.com/jpsim/CardsAgainst/blob/master/CardsAgainst/Controllers/ConnectionManager.swift) 的源代码。

#### 可靠传输 和 不可靠传输

就像是 [TCP/UDP](http://en.wikipedia.org/wiki/User_Datagram_Protocol#Comparison_of_UDP_and_TCP) 一样，MPC 有可靠传输和不可靠传输两种模式。[MCSessionSendDataMode](https://developer.apple.com/library/IOs/documentation/MultipeerConnectivity/Reference/MCSessionClassRef/index.html) 包含了这两种模式。

如果要在可靠模式 (.Reliable) 下发送数据：

    let message = "Hello objc.io!"
    let data = message.dataUsingEncoding(NSUTF8StringEncoding)!
    var error: NSError? = nil
    if !session.sendData(data, toPeers: peers, withMode: .Reliable, error: &error) {
        println("error: \(error!)")
    }

如果你发送的数据十分关键，直接关系到你的游戏能否正常运行，比如开始或者暂停游戏，使用可靠模式 (.Reliable)：

如果与准确性和有序性相比，速度的优先级更高，比如发送传感器的数据，那么不可靠模式 (.Unreliable) 可能更适合。务必权衡利弊，在考虑好[流](#streaming)的情况下，选择最适合你的方案。

### 发送文件

当你发送大量数据 (几百 kB 甚至几 MB) 的时候，比如文件，应该使用 `sendResourceAtURL(_:withName:toPeer:withCompletionHandler:)` 方法。它可以通过 `NSProgress` 对象让发送方和接收方同时监控传输进度。

这是 [DeckRocket](https://github.com/jpsim/DeckRocket/blob/96e875f784/OSX/DeckRocket/MultipeerClient.swift#L46-L56) 中的例子：

    pdfProgress = session!.sendResourceAtURL(url, withName: filePath.lastPathComponent, toPeer: peer) { error in
        dispatch_async(dispatch_get_main_queue()) {
            self.pdfProgress!.removeObserver(self, forKeyPath: "fractionCompleted", context: &ProgressContext)
            if error != nil {
                HUDView.show("Error!\n\(error.localizedDescription)")
            } else {
                HUDView.show("Success!")
            }
        }
    }
    pdfProgress!.addObserver(self, forKeyPath: "fractionCompleted", options: .New, context: &ProgressContext)

<a name="streaming"></a>
### 流

对于流数据，比如传感器的读数或者持续更新的用户坐标信息等等，可以使用 `startStreamWithName(_:toPeer:error:)` 方法把数据写到 `NSOutputStream` 中。接收者则通过 `NSInputStream` 读取数据流：

    // 接收者
    public func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        // 假设是一个 UInt8 的流
        var buffer = [UInt8](count: 8, repeatedValue: 0)

        stream.open()

        // 读取单个字节
        if stream.hasBytesAvailable {
            let result: Int = stream.read(&buffer, maxLength: buffer.count)
            println("result: \(result)")
        }
    }

## 挑战

虽然 MPC 很强大，但同时也面临不少挑战。下面列举一下你可能会遇到的问题。

### 可用性

MPC 只能用于 iOS 7、iOS 8 和 OS X 10.10 ，所以如果不是苹果的设备，或者不是最新的 OS X 发行版的话，那么请忘了 MPC 吧。跨平台的应用或者游戏需要依赖别的替代品。

### 可靠性

尽管在 iOS 7 之后苹果对 MPC 的可靠性做了很大的提升，可靠性依旧是 MPC 的痛处。不得不考虑到连接失败的情况，而且为了尽可能覆盖很多边界情况，还需要做不少额外的功课。

### 同步性和竞争条件

撇开因无线连接的损耗所导致的网络延时不谈，编写即时型网络的代码有点像是写本地的多线程代码。在假设事件发送成功之前，务必在合适的位置对关键传输加锁，从而确保所有节点确认接收关键事件。

游戏常常需要共享状态，比如游戏是否开始或暂停，玩家是否退出等等。如果玩家在对手即将发动致命一击的时候暂停游戏了会怎么样？ MPC 将异步的游戏逻辑竞争留给开发者来决定。使用 GameKit 这样的框架对集中逻辑很有帮助，但是同时也牺牲了一些灵活性作为代价。

## 替代选择

用 MPC 来写一个复杂的游戏无疑充满了挑战性。你可以了解一下其他选择再做决定。

### GameKit

苹果在 GameKit 中投入了很多想法。尽管它强制要求使用指定的模型和结构模式，并且还需要放弃会话连接过程中的一些控制，但是它确实抽离了很多底层的工作，减轻了工作量。

用 GameKit 开发游戏可以同时满足点对点模式和传统网络连接模式的需求。

### Websockets

WebSocket 协议 ([RFC 6455](http://tools.ietf.org/html/rfc6455)) 允许服务器端和客户端之间进行双向通信。每个节点需要建立一个新的 websocket 连接。该协议建立在 TCP 的基础上，所以不提供类似 MPC 的 `.Unreliable` 信息发送模式。不像 MPC，websocket 不提供任何网络创建或者设备检测功能，所以服务器端和客户端都必须连接在同一个网络上。它常用于和 [Bonjour](https://www.apple.com/support/bonjour) 关联使用。

如果是构建跨平台游戏或应用，那么 WebSocket 可以说是极具吸引力的，不过它需要一个有自定义后台的连接。

目前Swift ([starscream](https://github.com/daltoniam/starscream)) 和 Objective-C ([SocketRocket](https://github.com/square/SocketRocket)、[jetfire](https://github.com/acmacalister/jetfire)) 都有不少现成的 WebSocket 类库可供使用。

## 总结

把 MPC 整合到你的游戏或者应用中的过程不会很复杂，但是却能极大的提升用户体验，希望读完本文你也认同此观点。

如果想了解关于 MPC 的更多内容，下面的资料可能会有所帮助。

## 资料

[Multipeer Connectivity Reference](https://developer.apple.com/library/IOs/documentation/MultipeerConnectivity/Reference/MultipeerConnectivityFramework/index.html)

[Multipeer Connectivity WWDC 2013 Session](https://developer.apple.com/videos/enterprise/#15)

[GameKit Reference](https://developer.apple.com/LIBRARY/ios/documentation/GameKit/Reference/GameKit_Collection/index.html)

[NSHipster Article on Multipeer Connectivity](http://nshipster.com/multipeer-connectivity)

[PeerKit: An open-source Swift framework for building event-driven, zero-config MPC apps](https://github.com/jpsim/PeerKit)

[CardsAgainst: An open-source iOS game built with MPC](https://github.com/jpsim/CardsAgainst)

[DeckRocket: An open-source presentation remote control app for iOS/OSX built with MPC](https://github.com/jpsim/DeckRocket)


---

 

原文 [Multipeer Connectivity in Games](http://www.objc.io/issue-18/multipeer-connectivity-for-games.html)
