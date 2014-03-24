[AR Drone](http://ardrone2.parrot.com/)[无人机](https://en.wikipedia.org/wiki/Quadcopter)是一个小型的linux电脑, 当我们加入它提供的 WiFi 热点的时候, 我们就可以进入 192.168.1.1 来读取无人机。

## 用户数据报协议

无人机的数据连接采用了 [UDP 协议](https://en.wikipedia.org/wiki/User_Datagram_Protocol)，UDP 是至今沿用并占有主导地位的[传输层](https://en.wikipedia.org/wiki/Transport_layer)协议之一，而另一个是 TCP。

来，我们停下来先看看 TCP ，或者我们称之为[传输控制协议](https://en.wikipedia.org/wiki/Transmission_Control_Protocol)， 现在几乎所有的网络连接都是通过 TCP 来完成，最有说服力的原因就是他极其方便。 使用 TCP 的 api 是相当简单的，并且TCP可以被所有硬件设备支持，需要从网上由一个设备传输到另一个设备上。 使用 TCP 非常简单，一旦你打开连接，你将把数据写入 socket， 另一台设备将从 socket 读取，TCP 会确保数据正确的写入并且传输给另一个设备。 它隐藏了很多复杂的东西，TCP  是基于 IP 层之上的，所有低于 IP 的 data 都不能按照其发送的顺序到达，事实上，它有可能永远都不会到达 。但是 TCP 隐藏了这个复杂性，它在 Unix 管道上建模，TCP 同时也管理着吞吐量； 它不断的适应并达到最大的带宽利用率，TCP 确实如此有魅力, TCP 有三册总页数超过 2556 的书来介绍。 TCP/IP Illustrated: [The Protocols](http://www.amazon.com/dp/0321336313), [The Implementation](http://www.amazon.com/dp/020163354X), [TCP for Transactions](http://www.amazon.com/dp/0201634953)。

UDP，是传输层的另一方面，也是一个相对简单的协议，但是使用 UDP 对开发者来说是一个很痛苦的事情，当你通过 UDP 发送数据的时候，永远不知道数据是否成功被接收，不知道数据到达的顺序，也永远不知道数据发送速度能到多快而又不会因为宽带变化导致数据丢失。

就是说，UDP 是一个非常简单的模型：UDP 允许你从一台机器发送所谓的数据包到另一个。这些数据报或分组在另一端为同一数据包被接收（除非他们已经在路上消失了）。

为了使用 UDP，一个应用使用了[数据报 socket](https://en.wikipedia.org/wiki/Datagram_socket)，它绑定了一个IP地址和[服务端口](https://en.wikipedia.org/wiki/Port_number)在通信两端，并且因此建立了一个主机到主机的通讯，发送数据给一个指定的 socket 可以从匹配的另一端 socket 接收。

注意，UDP 是一个连接协议，这里不需要设置连接，socket 对哪里发送数据和数据何时到达进行简单的跟踪，当然，建立在数据能够被 socket 捕捉的基础上。


## UDP 以及 AR DRONE

AR Drone 的接口建立在三个 UDP 端口上， 通过上面的讨论我们知道 UDP 是一个还有待讨论的设计方案，但是 [Parrot](http://www.parrot.com/usa/) 选择了去实现它。
 
无人机的ip地址是 192.168.1.1， 并且这里有三个端口我们可以用来连接 UDP

导航控制数据端口 = 5554

机载视频端口 = 5555

AT 指令端口 = 5556

我们需要利用*AT指令集端口*来发送命令到无人机，我们可以用导航数据端口来接收来自无人机的数据，我们需要分开讨论这两个因为他们完全不同，但是他们都依赖于 UDP socket，然后我们看看他如何工作 


## UDP API

首先非常奇怪的是，Apple 没提供一个 Objective-C 的 UD P封装，这个协议甚至可以追溯到 1980 年， 主要原因是几乎没有使用 UDP 的，并且如果我们使用 UDP，至少访问 UDP 的 Unix C API 将成为我们担忧的一部分。因此大多数情况下我们会使用 TCP，而且对其来说，有很多 API 可供选择。
C 语言的 API 我们使用了高级研究计划署（发明互联网的地方）定义在 `sys/socket.h`, `netinet/in.h`, `arpa/inet.h` 的方法。

## 创建 UDP socket

首先，用下面的语句来创建 socket

	int nativeSocket = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);

`PF_INET` 是 socket 的域名，在这个例子中是互联网，`SOCK_DGRAM` 定义了数据报的格式（相对于流式套接字）。最后，`IPPROTO_UDP` 定义了传输协议 UDP。socket 的工作方式类似于调用 [open(2) 方法](http://man7.org/linux/man-pages/man2/open.2.html)

接下来，我们创建了一个结构体，包括我们的地址和无人机的地址，结构体中的 `sockaddr_in` 是套接字的地址，我们使用 `sin_me` 来定义自己的地址，以及 `sin_other` 来定义另一端的地址

	struct sockaddr_in sin_me = {};
	sin_me.sin_len = (__uint8_t) sizeof(sin);
	sin_me.sin_family = AF_INET;
	sin_me.sin_port = htons(0);
	sin_me.sin_addr.s_addr = htonl(INADDR_ANY);
	
	struct sockaddr_in sin_other = {};
	sin_other.sin_len = (__uint8_t) sizeof(sin_other);
	sin_other.sin_family = AF_INET;
	sin_other.sin_port = htons(self.port);
	int r = inet_aton([self.address UTF8String], &sin_other.sin_addr)

用 `={}` 来初始化结构体，是一个很好的练习，可以不用考虑你使用什么结构，因为它确保一切开始时为零的 - 否则这些值将是不确定的基础上，无论发生什么事是在栈上。我们会很容易碰到奇怪的bug。

接下来，我们要给 `sockaddr_in` 赋值，并且指定 `sin_len` 来让其可用，这样允许多个地址，`sin_family` 是地址类型，这里很长的一个地址协议簇，当我们通过 internet 连接时候，总是用 [IPv4](https://en.wikipedia.org/wiki/Ipv4) 的 `AF_INET` 或者[IPv6](https://en.wikipedia.org/wiki/Ipv6) 的 `AF_INET6`，然后我们设置端口和 `IP` 地址。

在我们这边，我们指定端口为 0，并且地址是 `INADDR_ANY`，0 端口意思是一个随机的端口将会分配给我们的设备。 `INADDR_ANY` 的结果是路由数据包到另一端（无人机）

无人机的地址指定为 `inet_aton(3)`, 他将转换 C 字符串 192.168.1.1 成相应的四字节 0xc0, 0xa2, 0x1, 0x1 - 作为无人机的IP地址。

注意我们我们调用 `htons(3)` 和 `htonl(3)` 在地址和端口号。htons 是 host-to-network-short 的缩写，htonl 是 host-to-network-long 的缩写。 大多数数据网络（包括 IP ）是字节序是很大的部分，确保数据按照正确的字节序发送我们需要调用这两个方法。
现在我们绑定 socket 到我们的 socket 地址。

	int r2 = bind(nativeSocket, (struct sockaddr *) &sin_me, sizeof(sin_me));
	
最后, 我们通过下面的 socket 连到另一端 socket 地址:

	int r3 = connect(nativeSocket, (struct sockaddr *) &sin_other, sizeof(sin_other));


最后一步是可选的，在每次发送数据包的时候我们也可以指定目的地址。

在我们示例代码中， 这是在内部实现的-[DatagramSocket configureIPv4WithError:]，并且有一些错误处理

## 数据发送

当我们有一个可用的 socket 时，发送数据就很简单了。比如我们要发送一个叫做 `data` 的 `NSData` 对象时，我们需要调用：

	ssize_t const result = sendto(nativeSocket, [data bytes], data.length, 0, NULL, 0);
	if (result < 0) {
	    NSLog(@"sendto() failed: %s (%d)", strerror(errno), errno);
	} else if (result != data.length) {
	    NSLog(@"sendto() failed to send all bytes. Sent %ld of %lu bytes.", result, (unsigned long) data.length);
	}

注意，UDP 设计是不可靠的，一旦我们调用 `sendto(2)`，接下来互联网上传送的数据会发生什么就不是我们可以控制的了。

##  接收数据

接收数据的核心非常简单，这个方法叫做 `recvfrom(2)` 包括两个参数，第一个是 `sin_other` 指定了我们希望接受的数据的发送方，第二个参数是一个指向一个缓冲区，进入其中的数据将被写入。如果成功，则返回读取的字节数：

	NSMutableData *data  = [NSMutableData dataWithLength:65535];
	ssize_t count = recvfrom(nativeSocket, [data mutableBytes], [data length], 0, (struct sockaddr *) &sin_other, &length);
	if (count < 0) {
	    NSLog(@"recvfrom() failed: %s (%d)", strerror(errno), errno);
	    data = nil;
	} else {
	    data.length = count;
	}


一个值得注意的事情， `recvfrom(2)` 是一个阻塞方法，线程一旦调用这个方法他会等待直到数据全部读完。 正常情况下这个并不是我们想要的， 配合 GCD，我们可以设置一个事件源，每当 socket 有要读取的数据。这是推荐的方式来读取来自套接字的数据。
在我们的例子中， DatagramSocket 类实现了这个方法设置事件源

	- (void)createReadSource
	{
	    self.readEventSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, self.nativeSocket, 0, self.readEventQueue);
	    __weak DatagramSocket *weakSelf = self;
	    dispatch_source_set_event_handler(self.readEventSource, ^{
	        [weakSelf socketHasBytesAvailable];
	    });
	    dispatch_resume(self.readEventSource);
	}

数据源处于停止状态，这就是为什么我们必须使用 `calldispatch_resume(3)` 否则，将无法送达事件源，`-socketHasBytesAvailable` 之后调用 `recvfrom(2)`。

## 初始值

为了避免一个小问题，我们要重写 `nativeSocket` 的属性方法。

	@property (nonatomic) int nativeSocket;

这样来实现

	@synthesize nativeSocket = _nativeSocket;
	- (void)setNativeSocket:(int)nativeSocket;
	{
	    _nativeSocket = nativeSocket + 1;
	}
	
	- (int)nativeSocket
	{
	    return _nativeSocket - 1;
	}


我们从内部的实例变量里减 1， 原因是，Objective-C 运行时保证所有实例变量进行初始化为零后的 `-alloc` 被调用。其次，socket 被认为是有效的，只要它们是非负的，即0和至多是有效的套接字号。 

通过偏移值，我们可以安全地检查 socket 值已在初始化之前设置成偶数。

## 整合在一起

在我们 DatagramSocket 类中我们封装了所有低级的 UDP socket 的工作。

DroneCommunicator 类用来无人机的 导航数据端口 5554 和 AT 指令集端口 5556 的通讯，就像这样：

	NSError *error = nil;
	self.commandSocket = [DatagramSocket ipv4socketWithAddress:DroneAddress
	                                                      port:ATCommandPort
	                                           receiveDelegate:self
	                                              receiveQueue:[NSOperationQueue mainQueue]
	                                                     error:&error];
	
	self.navigationDataSocket = [DatagramSocket ipv4socketWithAddress:DroneAddress
	                                                             port:NavigationDataPort
	                                                  receiveDelegate:self
	                                                     receiveQueue:[NSOperationQueue mainQueue]
	                                                            error:&error];

这个委托方法基于 socket 分支


	- (void)datagramSocket:(DatagramSocket *)datagramSocket didReceiveData:(NSData *)data;
	{
	    if (datagramSocket == self.navigationDataSocket) {
	        [self didReceiveNavigationData:data];
	    } else if (datagramSocket == self.commandSocket) {
	        [self didReceiveCommandResponseData:data];
	    }
	}


在我们app 里需要处理的只有导航数据，他被 DroneNavigationState 处理


	- (void)didReceiveNavigationData:(NSData *)data;
	{
	    DroneNavigationState *state = [DroneNavigationState stateFromNavigationData:data];
	    if (state != nil) {
	        self.navigationState = state;
	    }
	}


## 发送命令

在UDP套接字创建并且运行后，发送的命令是相对明确的。所谓的命令端口接受纯 ASCII 命令， 看起来就像这样：

	AT*CONFIG=1,"general:navdata_demo","FALSE"
	AT*CONFIG=2,"control:altitude_max","1600"
	AT*CONFIG=3,"control:flying_mode","1000"
	AT*COMWDG=4
	AT*FTRIM=5


AR Drone SDK 包含了一个叫做 ARDrone Developer Guide 的 PDF 文档，里面详细介绍了所有的 AT 指令集。
我们创造了一系列方便 helper 方法在 DroneCommunicator 类中，使上述可以被发送：

	
	[self setConfigurationKey:@"general:navdata_demo" toString:@"FALSE"];
	[self setConfigurationKey:@"control:altitude_max" toString:@"1600"];
	[self setConfigurationKey:@"control:flying_mode" toString:@"1000"];
	[self sendCommand:@"COMWDG" arguments:nil];
	[self sendCommand:@"FTRIM" arguments:nil];


所有的无人机指令以 AT* 开头，跟着加上指令名以及 `=`，按到跟着被逗号隔开的参数，第一个参数是命令的序列号为了这个我们创建了一个方法叫做 `-sendCommand:arguments:{ 他会插入命令序列号在索引的开始


	- (int)sendCommand:(NSString *)command arguments:(NSArray *)arguments;
	{
	    NSMutableArray *args2 = [NSMutableArray arrayWithArray:arguments];
	    self.commandSequence++;
	    NSString *seq = [NSString stringWithFormat:@"%d", self.commandSequence];
	    [args2 insertObject:seq atIndex:0];
	    [self sendCommandWithoutSequenceNumber:command arguments:args2];
	    return self.commandSequence;
	}


并且依次调用 `-sendCommandWithoutSequenceNumber:arguments:` 以 AT* 为前缀开始串联命令和参数


	- (void)sendCommandWithoutSequenceNumber:(NSString *)command arguments:(NSArray *)arguments;
	{
	    NSMutableString *atString = [NSMutableString stringWithString:@"AT*"];
	    [atString appendString:command];
	    NSArray* processedArgs = [arguments valueForKey:@"description"];
	    if (0 < arguments.count) {
	        [atString appendString:@"="];
	        [atString appendString:[processedArgs componentsJoinedByString:@","]];
	    }
	    [atString appendString:@"\r"];
	    [self sendString:atString];
	}
	

最后我们完成的字符串串联成 `data` 并且传给socket


	- (void)sendString:(NSString*)string
	{
	    NSData *data = [string dataUsingEncoding:NSASCIIStringEncoding];
	    if (data != nil) {
	        [self.commandSocket asynchronouslySendData:data];
	    } else {
	        NSLog(@"Unable to convert string to ASCII: %@", string);
	    }
	}




## 浮点字符串编码

因为一些奇怪的原因，设计无人机协议的人决定，浮点值应作为发送具有相同的位模式的整数。这确实是奇怪的，但我们不得不一起玩。
我们需要让无人机的前进速度是相对随度0.5 这个浮点型0.5 在binary看起来是：

	0011 1111 0000 0000 0000 0000 0000 0000

我们诠释这个结果在32位整形中，它是1056964608，所以我们发送命令AT*PCMD=6,1,0,1056964608,0,0到无人机
在我们的例子中，我们用一个NSNumber的封装来完成，这个代码最终看起来像：
	
	NSNumber *number = (id) self.flightState[i];
	union {
	    float f;
	    int i;
	} u;
	u.f = number.floatValue;
	[result addObject:@(u.i)];

这里的技巧是使用联合 - C语言的一个鲜为人知的一部分。联合允许多个不同的类型（在这种情况下，整数和浮点型）驻留在同一存储单元。然后，我们将浮点值存储到u.f和从u.i读取


注意：使用像 int i = *((int *) &f) -这样的代码是不合法的，这不是正确的C代码,并且会导致未定义的行为。生成的代码有时会工作，但有时候不会。不要这样做。你可以通过阅读 llvm blog中的under Violating Type Rules来阅读更多。 可悲的是 *AR Drone Developer Guide* 有这个错误。

[话题 #8 下的更多文章][1]

   [1]: http://objccn.io/issue-8
   
原文 [Communicating with the Quadcopter](http://www.objc.io/issue-8/communicating-with-the-quadcopter.html)