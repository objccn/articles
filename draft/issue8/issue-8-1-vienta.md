#项目


## 初始计划
我们第一个想法是利用蓝牙信号在室内去操控飞行器。在这个飞机器上搭载iPhone,这样可以通过获取从室内发送来的一些信号转化为三维坐标来获取它的当前位置。

然而，我们第一实验是用信号的强弱来测量信标和iPhone之间的距离，但是结果令人失望。当测量到两到三米多的距离(大约6到10英尺)的时候发现信号和正常准确的信号相差太远。

最后放弃了这个想法，转而开始寻找替代的方案。

## 修订计划
因为我们不想偏离让飞行器搭载iPhone自己导航的这个想法，所以我们决定试一下老的GPS设备。显然这个需要我们移动到户外这样才能更好的获取到GPS信号。事实证明。冬天在柏林的测试非常的寒冷，甚至有微风也影响了飞行器的飞行。

总体的计划就是有一个iPhone可以搭载在飞行器上，然后通过WiFi连接它，通过 Core Location可以知道当前位置和方向然后控制飞行器飞往它的目的地坐标。

为了让这个项目更有趣，我们又添加了一个iPhone，让这个iPhone通过使用新的multipeer APIs与搭载在飞行器上的iPhone建立联系，并且发送它自己的位置作为飞行器的目的地坐标。搭载iPhone的飞行器会朝着另外一个iPhone移动，另外通过连接上这个飞行器也可以发送起飞和降落的命令。

制定一个轨道通往Chris家，并且让飞行器在这个轨道上飞行，这个让飞行器能够受我们控制的想法很诱人。不幸的是，事情和预期还是有区别的，寒冷的温度和外面的风同样影响了飞行器，以及电池的寿命和我们要在很短时间按下正确的方向。（但是对于Chris来说这还不是糟糕的，我们把他的iPhone绑到了飞行器，所以通常我们测试的时候他都追着飞行器，生怕看不到他的iPhone。）

## 飞行器
在我们的项目中我们使用了标准的AR Drone 2.0，为了把iPhone安装到飞行器上，我们用了一些泡沫塑料裹着iPhone然后用胶带绑到飞行器上，最初我们是想把它绑在飞行器的顶部，但是这个不是很稳定。这个飞行器几乎不能搭载任何东西，以至于很轻的iPhone的都会很显著的影响飞行的稳定。

![iphone-above][1]

但是飞行器起飞后摇晃的很，所以我们决定把iPhone绑在飞行器的底部来降低重心，事实证明，这表现的很好，由于现在飞行器的最下面是iPhone，我们使用大量的拉链领带来保护iPhone，让这个飞行器不容易突然坠落。（这也是一种来方法来缓解Chris的顾虑）

![iphone-below][2]

##导航应用
就像上面提到的那样，搭载在飞行器上的iPhone的通过WiFi连接另外一个iPhone，通过这个连接我们可以通过UDP API来发送导航命令，虽然这一切看上去比较的晦涩，但是一旦我们搞清楚这个原理基础，就会工作的很好。Daniel在<a href="http://www.objc.io/issue-8/communicating-with-the-quadcopter.html" target="_blank">[这边文章]</a>中详细的介绍了Core Foundation networking这个类如何使用才能让它工作。

通过使用iPhone和飞行器之前的通讯，导航应用也需要处理导航部分内容，这个应用通过Core Location来处理它当前位置和方向然后计算它与目的地的距离，你可以通过<a href="http://www.objc.io/issue-8/the-quadcopter-navigator-app.html" target="_blank">[这篇文章]</a>了解它是如何工作的。

##客户端应用
这个客户端应用唯一的工作就是发送目的地坐标给搭载飞行器的iPhone和一些基础的命令例如起飞和降落。它会通过multipeer connection来通知它自己和简单的广播它的位置给所有连接的peers。

![connect_map][3]

因为我们想有一种方法不用飞行很多次就可以测试整个配置，而且我们也想待在室内，所以我们给这个应用添加了两种模式。第一种模式就是简单的发送地图上的中心位置作为它当前的位置。这种方法我们可以平移地图，模拟改变目的地坐标，另一种模式是通过Core Location发送真实的iPhone的位置。

在我们短暂的测试中由于时间的原因我们只使用第一种模式，并且由于恶劣的天气，我们某人追逐飞行器的不能够实现了。

其实这是一个非常有趣的项目，我们实验了很多有趣的APIs。您可以查看后续的关于<a href="http://www.objc.io/issue-8/communicating-with-the-quadcopter.html" target="_blank">[Core Foundation networking]</a>, <a href="http://www.objc.io/issue-8/the-quadcopter-navigator-app.html" target="_blank">[the navigator app]</a>, and<a href="http://www.objc.io/issue-8/the-quadcopter-client-app.html" target="_blank">[the client app]</a>的文章的具体细节。

   [1]: http://img.objccn.io/issue-8/iphone-above.jpg
   [2]: http://img.objccn.io/issue-8/iphone-below.jpg
   [3]: http://img.objccn.io/issue-8/client-app.jpg