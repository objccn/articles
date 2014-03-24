在这篇文章中，我们将把之前提到过的部分整合起来组成我们的导航器应用，这个 iPhone 应用将控制我们的无人机，你可以在 [Github](https://github.com/objcio/issue-8-quadcopter-navigator) 签出我们的应用，即使应用程序没有直接交互，在测试过程中我们做了一个小的 UI 显示无人机的状态，并允许我们手动执行命令。

## High-Level Overview 总览

在我们的应用中，我们有几个类它们分别是:

* `DroneCommunicator` 这个类负责利用 UDP 和无人机通讯。关于这个话题全部在 [Daniel 的文章](http://objccn.io/issue-8-2)中详细介绍过

* `RemoteClient` 使用[Multipeer Connectivity ](https://developer.apple.com/library/ios/documentation/MultipeerConnectivity/Reference/MultipeerConnectivityFramework/_index.html)和我们的远程客户端进行交互，具体客户端发生什么事情，请看 [Florian 的文章](http://objccn.io/issue-8-4)。
* `Navigator` 用来指定目标位置以及计算飞行航线，并且计算飞行距离。
* `DroneController` 用来导航，并且把导航的距离和方向发送命令到无人机。
* `ViewController`有一个简单的界面，用来设置其他的类并把它们连接起来，这部分可以用不同的类来完成，但是在我们的设想中，我们的app足够简单所以放到一个类就可以了。

## View Controller

view controller 中最重要的一个部分是设置方法，在这里我们创建了 communicator， navigator， drone controller 以及remote client 实例，换句话说我们建立了整个桥梁用来沟通无人机和我们的客户端app。

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
 
View controller 同时是 `RemoteClient` 的委托。 这就说明无论我们的客户端发送了一个新位置，或者着陆，重置或者关机的命令，我们都需要在这里处理它。举个例子，当我们收到一个新的位置的命令的时候，我们这样来做:

	- (void)remoteClient:(RemoteClient *)client didReceiveTargetLocation:(CLLocation *)location
	    {
	        self.droneController.droneActivity = DroneActivityFlyToTarget;
	        self.navigator.targetLocation = location;
	    }
	 
这里确保无人机开始飞行（而不是徘徊）并且更新目标位置。

## Navigator

导航类用来计算从当前位置到给定目标位置的距离以及无人机应当飞行的距离，为了完成整个工作我们首先需要监听 core location 的改变：

    - (void)startCoreLocation
    {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        [self.locationManager startUpdatingLocation];
        [self.locationManager startUpdatingHeading];
    }
    
在我们的导航器类中，我们有两个不同的方向，绝对方向和相对方向，绝对方向是两个地点之间的方向。举个例子，从阿姆斯特丹到柏林的绝对方向几乎是正东的。相对方向也要考虑我们的指南针，当我们想从阿姆斯特丹向东移动到柏林，我们的相对位置是零。为了旋转无人机，我们需要一个相对方向，如果他是零，飞机是直线飞行，如果他小于零，我们向右旋转，如果他大于零，我们向左旋转。

计算到目的地的绝对方向，我们需要创建一个基于 `CLLocation` 的助手类用来计算两个点的方向:

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
 
在导航器中，我们将得到位置和航向的回调，然后我们把这两个值存到属性中，举个例子，计算我们需要飞行的两点之间的距离，我们需要将绝对航向减去当前航向（这与你看指南针上的值是一样的意思），然后将结果换算到 -180 度和 180  度之间。如果你希望知道为什么我们要减去 90 度，那是因为我们 iPhone 和无人机之间有 90 度的夹角。

    - (CLLocationDirection)directionDifferenceToTarget;
    {
        CLLocationDirection result = (self.direction.heading - self.lastKnownSelfHeading.trueHeading - 90);
        // Make sure the result is in the range -180 -> 180
        result = fmod(result + 180. + 360., 360.) - 180.;
        return result;
    }
    
这就是我们导航器做的事情。基于当前的位置和航向，计算出到目标的距离和无人机应当飞行的方向。并且观察这两个属性。

## Drone Controller
Drone controller 用来初始化 navigator 和 communicator，基于距离和方向，它发送命令到无人机，因为命令需要持续发送所以我们创建一个计时器：

    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                        target:self
                                                      selector:@selector(updateTimerFired:)
                                                      userInfo:nil
                                                       repeats:YES];

当计时器触发后且我们正飞向一个目标，我们需要发送给无人机适当的指令，如果我们足够近，那么无人机盘旋，否则，我们转向目标，在我们大致方向正确的情况下飞过去！

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

Remote Client 类负责和我们的[客户端通讯](http://objccn.io/issue-8-4)，我们利用了一个很方便 [Multipeer Connectivity 框架](https://developer.apple.com/library/ios/documentation/MultipeerConnectivity/Reference/MultipeerConnectivityFramework/_index.html)。首先，我们需要和附近的一个服务浏览器创建一个会话:

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

我们需要加入 `MCNearbyServiceBrowserDelegate` 和 `MCSessionDelegate` 的委托中的方法，否则这个应用将会崩溃。唯一一个方法我们需要实现的是 `session:didReceiveData:fromPeer:` 。我们解析对等客户端发送来的命令并且调用合适的委托方法，在我们简易的应用中，view controller实现了这些委托，当我们接收到了新的位置我们更新导航器，并且让无人机飞向新的位置。

## Conclusion

这篇文章描述了这个简易的 app ，最初我们把所有的委托和代码都加入到了 view controller 中，这是被证明最简单的编码和测试方式，其实写代码是一个容易的事情，但是阅读代码非常困难。因此我们需要重构所有的代码让其合理的分配到不同类中。

硬件方面的工作，测试非常的耗时，举个例子，在我们的 quadcopter 项目中，需要一段时间来启动设备，发送命令，并让它飞起来。因此我们尽可能多的测试离线状况下的事情。我们还添加了大量的的日志语句，这样我们调试起来更加方便。

[话题 #8 下的更多文章][1]

   [1]: http://objccn.io/issue-8
   
原文 [The Navigator App](http://www.objc.io/issue-8/the-quadcopter-navigator-app.html)