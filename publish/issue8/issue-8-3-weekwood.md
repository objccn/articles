在这篇文章中，我们将把前面提到过的内容组织起来构成我们的导航器应用，这个 iPhone 应用将装载在我们的的无人机上，你可以在 [Github](https://github.com/objcio/issue-8-quadcopter-navigator) 下载应用的源码，尽管这个应用是计划在没有直接的交互操作下来使用的，但在测试过程中我们做了一个简单的 UI 界面来显示其无人机状态并方便我们手动操作。

## 概要

在我们的应用中，我们有几个类它们分别是:

* `DroneCommunicator` 这个类关注于利用 UDP 和无人机通讯。这个话题全部在 [Daniel 的文章](http://objccn.io/issue-8-2)中详细介绍过

* `RemoteClient` 使用 [Multipeer Connectivity](https://developer.apple.com/library/ios/documentation/MultipeerConnectivity/Reference/MultipeerConnectivityFramework/_index.html) 技术和我们的远程客户端进行交互，具体客户端的操作，请看 [Florian 的文章](http://objccn.io/issue-8-4)。
* `Navigator` 用来设定目标位置，计算飞行航线，以及飞行距离。
* `DroneController` 用来把从 `Navigator` 获取的导航的距离和方向发送命令到`DroneCommunicator`。
* `ViewController` 有一个简单的界面，用来初始化其他的类并把它们连接起来，这部分应该用不同的类来完成，但是在我们的设想中，我们的app足够简单所以放到一个类就可以了。

## View Controller

View Controller 中最重要的一个部分是初始化方法，在这里我们创建了 `DroneCommunicator`， `Navigator`， `DroneController` 以及`RemoteClient` 的实例化对象，换句话说：我们建立了无人机和我们的客户端应用沟通的整个桥梁。

    - (void)setup
    {
        self.communicator = [[DroneCommunicator alloc] init];
        [self.communicator setupDefaults];
        
        self.navigator = [[Navigator alloc] init];
        self.droneController = [[DroneController alloc] initWithCommunicator:self.communicator navigator:self.navigator];
        self.droneController.delegate = self;
        self.remoteClient = [[RemoteClient alloc] init];
        [self.remoteClient startBrowsing];
        self.remoteClient.delegate = self;
    }
 
View Controller 同时是 `RemoteClient` 的委托。 这就说明无论我们的客户端发送了一个新位置或者着陆，重置以及关机的命令，我们都需要在这里处理它。举个例子，当我们收到一个新的位置的命令的时候，我们这样来做:

	- (void)remoteClient:(RemoteClient *)client didReceiveTargetLocation:(CLLocation *)location
	    {
	        self.droneController.droneActivity = DroneActivityFlyToTarget;
	        self.navigator.targetLocation = location;
	    }
	 
这段代码是用来确保无人机开始飞行（而不是徘徊）并且更新目标位置。

## Navigator

导航类用来指定目标位置，并且计算从当前位置到目标位置的距离，为了完成整个工作我们首先需要监听 core location 的改变：

    - (void)startCoreLocation
    {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        [self.locationManager startUpdatingLocation];
        [self.locationManager startUpdatingHeading];
    }
    
在我们的导航类中，我们有两种方向，绝对和相对方向，绝对方向是两个地点之间的方向。比如说，阿姆斯特丹和柏林间的绝对方向几乎处于同一纬度，相对位置则是我们在参考指南针后可以得出的路线方向，要从阿姆斯特丹一直向东到柏林，两地之间的相对方向为零。在操作无人机的时候我们就需要使用相对方向。方向值为零，飞机直行；方向角度小于零，飞机向右倾斜转弯；方向角度大于零，飞机则向左倾斜转弯。

计算到目的地的绝对方向，我们需要创建一个基于 `CLLocation` 的Helper方法用来计算两个点的方向:

	- (OBJDirection *)directionToLocation:(CLLocation *)otherLocation;
    {
        return [[OBJDirection alloc] initWithFromLocation:self toLocation:otherLocation];
    }
	    
由于我们的无人机只能飞很小的距离（电池只能支持10分钟），所以我们需要一个几何的假设，我们是在一个平面而不是在地球表面:

    - (double)heading;
    {
        double y = self.toLocation.coordinate.longitude - self.fromLocation.coordinate.longitude;
        double x = self.toLocation.coordinate.latitude - self.fromLocation.coordinate.latitude;
        
        double degree = radiansToDegrees(atan2(y, x));
        return fmod(degree + 360., 360.);
    }
 
在导航器中，我们将得到位置和航向的回调，然后我们把这两个值存到属性中，比如，计算我们需要飞行的两点之间的距离，我们需要将绝对航向减去当前航向（这与你看到指南针上的值是一样的意思），然后将结果换算到 -180 度和 180  度之间。如果你希望知道为什么我们要减去 90 度，那是因为我们 iPhone 和无人机之间有 90 度的夹角。

    - (CLLocationDirection)directionDifferenceToTarget;
    {
        CLLocationDirection result = (self.direction.heading - self.lastKnownSelfHeading.trueHeading - 90);
        // Make sure the result is in the range -180 -> 180
        result = fmod(result + 180. + 360., 360.) - 180.;
        return result;
    }
    
这就是我们导航做的事情。基于当前的位置和航向，计算出到目标的距离和无人机应当飞行的方向。并且监听这两个属性。

## Drone Controller
Drone controller 用来初始化 navigator 和 communicator，并且发送距离和方向的命令到无人机，因为命令需要持续发送，所以我们创建一个计时器：

    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                        target:self
                                                      selector:@selector(updateTimerFired:)
                                                      userInfo:nil
                                                       repeats:YES];

当计时器触发后，假设我们飞向一个目标，我们需要发送给无人机适当的指令，如果我们足够近，无人机盘旋，否则，我们转向目标，在大致方向正确的情况下飞过去！

    - (void)updateDroneCommands;
    {
        if (self.navigator.distanceToTarget < 1) {
            self.droneActivity = DroneActivityHover;
        } else {
            static double const rotationSpeedScale = 0.01;
            self.communicator.rotationSpeed = self.navigator.directionDifferenceToTarget * rotationSpeedScale;
            BOOL roughlyInRightDirection = fabs(self.navigator.directionDifferenceToTarget) < 45.;
            self.communicator.forwardSpeed = roughlyInRightDirection ? 0.2 : 0;
        }
    }
    
## Remote Client

Remote Client 类关注于和我们的[客户端通讯](http://objccn.io/issue-8-4)，我们利用了一个很方便 [Multipeer Connectivity 框架](https://developer.apple.com/library/ios/documentation/MultipeerConnectivity/Reference/MultipeerConnectivityFramework/_index.html)。首先，我们需要和附近的创建一个会话以及 `MCNearbyServiceBrowser` :

    - (void)startBrowsing
    {
        MCPeerID* peerId = [[MCPeerID alloc] initWithDisplayName:@"Drone"];
    
        self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peerId serviceType:@"loc-broadcaster"];
        self.browser.delegate = self;
        [self.browser startBrowsingForPeers];
    
        self.session = [[MCSession alloc] initWithPeer:peerId];
        self.session.delegate = self;
    }
    
在我们的项目中，我们不需要处理单独设备的安全问题，因为我们总是邀请所有的对等网络的设备。
    
    - (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
    {
        [browser invitePeer:peerID toSession:self.session withContext:nil timeout:0];
    }

我们需要加入 `MCNearbyServiceBrowserDelegate` 和 `MCSessionDelegate` 全部的协议方法，否则这个应用将会崩溃。唯一一个方法我们需要实现的是 `session:didReceiveData:fromPeer:` 。我们解析对等客户端发送来的命令并且调用合适的委托方法，在我们简易的应用中，View Controller 实现了这些委托，当我们接收到了新的位置我们更新导航，并且让无人机飞向新的位置。

## 总结

这篇文章描述了这个简易的 app ，最初我们把所有的委托和代码都加入到了 View Controller 中，这是被证明最简单的编码和测试方式，其实写代码是一个容易的事情，但是阅读代码非常困难。因此我们需要重构所有的代码让其合理的分配到不同类中。

硬件方面的工作，测试非常的耗时，比如，在我们的 quadcopter 项目中，需要一段时间来启动设备，发送命令，并让它飞起来。因此我们尽可能多在离线状况下测试。我们还添加了大量的的日志语句，这样我们调试起来更加方便。

 

   [1]: http://objccn.io/issue-8
   
原文 [The Navigator App](http://www.objc.io/issue-8/the-quadcopter-navigator-app.html)
