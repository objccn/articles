[Source](http://www.objc.io/issue-8/communicating-with-the-quadcopter.html "Permalink to Communicating with the Quadcopter - Quadcopter Project - objc.io issue #8 ")

# Communicating with the Quadcopter - Quadcopter Project - objc.io issue #8 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# Communicating with the Quadcopter

[Issue #8 Quadcopter Project][4], January 2014

By [Daniel Eggert][5]

The [AR Drone][6] [quadcopter][7] is a small, Linux-based computer. Its WiFi interface acts as a WiFi hotspot. Once we’ve joined that, we can read the drone over WiFi at the [IP address][8] `192.168.1.1`.

## UDP – User Datagram Protocol

The communication with the drone happens over UDP, which is short for [User Datagram Protocol][9]. UDP is one of the dominant [transport-layer][10] protocols in use today. The other is TCP.

Let us sidestep for a moment and look at TCP, or [Transmission Control Protocol][11]. Just about anything communicating through the internet uses TCP at the transport layer, and for a good reason, as using TCP is extremely convenient. The API for using TCP is rather straightforward, and TCP is well supported by all the hardware that the internet traffic has to travel through to get from one device on the internet to another. Using TCP is simple. Once you’ve opened a connection, you can write data into a so-called socket, and the other end can read that data from its socket. TCP makes sure that the exact data that is written in one end arrives at the other end. It hides a lot of complexity. TCP is based on top of [IP][12], and lower-level IP data may not arrive in the order it is sent. It may, in fact, never arrive. But TCP hides this complexity. It is modeled after normal [Unix pipes][13]. TCP also manages the throughput; it constantly adapts the rate at which data is transmitted to best utilize the available bandwidth. TCP does so much magic to pull off this trick that the de-facto standard books on TCP are three volumes with a total of more than 2,556 pages of detailed explanations: _TCP/IP Illustrated:_ [The Protocols][14], [The Implementation][15], [TCP for Transactions][16].

UDP, on the other hand, is a relatively simple protocol. But using it involves a lot of pain for the developer. When you send data over UDP, there’s no way to know if that data reaches the other end. There’s no way to know in which order data arrives. And there’s no way to know how rapidly you can send data without data starting to drop because the available bandwidth changes.

That said, UDP has a very simple model: UDP allows you to send so-called datagrams (packets) from one machine to another. These datagrams or packets are received at the other end as the same packets (unless they’ve been lost on the way).

In order to use UDP, an application uses a [datagram socket][17], which binds a combination of an IP address and a [service port][18] on both ends, and, as such, establishes host-to-host communication. Data sent on a given socket can be read on a matching socket on the receiving side.

Note, that UDP is a _connectionless_ protocol. There’s no connection setup on the network. The socket simply keeps track of where to send packets and when packets arrive, if they should be captured by that socket.

## UDP and AR Drone

The AR Drone interface is built on top of three UDP ports. As discussed above, using UDP is an arguable design choice, but [Parrot][19] chose to do so.

The IP address of the drone is `192.168.1.1` and there are three ports we can use to connect over UDP:

  * Navigation Data Port = 5554
  * On-Board Video Port = 5555
  * AT Command Port = 5556

We need to use the _AT Command Port_ to send commands to the drone. We can use the _Navigation Data Port_ to retrieve data back from the drone. We’ll talk about these two separately since they work quite differently. That said, they both rely on UDP sockets. Let’s first see how that is done.

## The UDP API

Apple doesn’t provide an Objective-C wrapper or helper to work with UDP. This may be surprising at first. After all, the protocol dates back to 1980. The main reason, though, is very likely that hardly anything is using UDP, and if we use UDP, accessing the Unix C API for UDP is going to be least part of our worries. TCP is what we’ll use in most cases, and for that, there are plenty of API options.

The C API we’ll use is defined in `sys/socket.h`, `netinet/in.h`, `arpa/inet.h`. And `ARPA` refers to _Advanced Research Projects Agency_, the guys who invented the internet.

### Creating a UDP Socket

First off, we’ll create a _socket_ with:


    int nativeSocket = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);

`PF_INET` is the domain of the socket. In this case, _internet_. `SOCK_DGRAM` specified that type to be a _datagram_ socket (as opposed to a stream socket). Finally, `IPPROTO_UDP` specifies that the protocol is _UDP_. This socket now works similarly to a file descriptor that we would have obtained by calling the `open(2)` function.

Next, we’ll create a `struct` with our own address and the address of the drone. The type is `struct sockaddr_in` – a socket address. We’ll use `sin_me` for _our_ address, and `sin_other` for the _other_ end’s address:


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

Initializing the `struct` with ` = {}` is a good practice in general, regardless of what struct you use, because it ensures that everything starts out being zero – otherwise the values would be undefined, based on whatever happens to be on the stack. We’d easily run into odd bugs that only happen sometimes.

Next, we’re setting the fields of the `struct sockaddr_in` to specify the _socket address_ to be used, with `sin_len` as the length of the structure. This allows support for multiple types of addresses. `sin_family` is the type of address. There’s a long list of address families, but when connecting over the internet, it’ll always be either `AF_INET` for [IPv4][20] or `AF_INET6` for [IPv6][21]. Then we’re setting the port and the IP address.

On _our_ side, we set the port to `0` and the address to `INADDR_ANY`. A port number of 0 means that a random port number will be assigned to _our_ side. `INADDR_ANY` results in the address that can route packets to the address of the other end (the drone).

The drone’s address is set with `inet_aton(3)`, which converts the C string `192.168.1.1` into the corresponding four bytes `0xc0`, `0xa2`, `0x1`, `0x1` – the IP address of the drone. Note that we’re calling `htons(3)` and `htonl(3)` on the address and the port number. `htons` is short for _host-to-network-short_ and `htonl` is short for _host-to-network-long_. The [endianness][22] of most data networking (including IP) is big-endian. To ensure that our data is of the right endianness, we need to call these two functions.

We now bind the socket to our socket address with:


    int r2 = bind(nativeSocket, (struct sockaddr *) &sin_me, sizeof(sin_me));

Finally, we connect the other end’s socket address with the socket:


    int r3 = connect(nativeSocket, (struct sockaddr *) &sin_other, sizeof(sin_other));

This last step is optional. We could also specify the destination address every time we send a packet.

In our sample code, this is implemented inside `-[DatagramSocket configureIPv4WithError:]`, which also has some error handling.

### Sending Data

Once we have a socket, sending data is a trivial matter. If we have an `NSData` object called `data`, we can call:


    ssize_t const result = sendto(nativeSocket, [data bytes], data.length, 0, NULL, 0);
    if (result < 0) {
        NSLog(@"sendto() failed: %s (%d)", strerror(errno), errno);
    } else if (result != data.length) {
        NSLog(@"sendto() failed to send all bytes. Sent %ld of %lu bytes.", result, (unsigned long) data.length);
    }

Note that [UDP][9] is unreliable by design. Once we’ve called `sendto(2)`, there’s nothing more we can do to know what’s happening to the data being transmitted over the internet.

### Receiving Data

Receiving data is, at its core, quite simple too. The function `recvfrom(2)` expects two arguments: the first argument is the socket address `sin_other`, which is the socket we want to receive data from. The second argument is a pointer to a buffer, into which the data will be written. Upon success, it returns the number of bytes read:


    NSMutableData *data  = [NSMutableData dataWithLength:65535];
    ssize_t count = recvfrom(nativeSocket, [data mutableBytes], [data length], 0, (struct sockaddr *) &sin_other, &length);
    if (count < 0) {
        NSLog(@"recvfrom() failed: %s (%d)", strerror(errno), errno);
        data = nil;
    } else {
        data.length = count;
    }

One thing to note, though, is that the `recvfrom(2)` call is blocking. The thread that calls it will wait until it can read data. Usually that’s not what we want. With [GCD][23], we can set up an event source that will fire whenever the socket has data available to be read. This is the recommended way to read data from a socket.

In our case, the `DatagramSocket` class implements this method to set up the event source:


    - (void)createReadSource
    {
        self.readEventSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, self.nativeSocket, 0, self.readEventQueue);
        __weak DatagramSocket *weakSelf = self;
        dispatch_source_set_event_handler(self.readEventSource, ^{
            [weakSelf socketHasBytesAvailable];
        });
        dispatch_resume(self.readEventSource);
    }

Event sources start out in a suspended state. That’s why we must call `dispatch_resume(3)`. Otherwise, no event would ever get delivered to the source. The `-socketHasBytesAvailable` then calls `recvfrom(2)` on the socket.

### Default Values

As a small sidestep, we’ll point out how the `nativeSocket` property:


    @property (nonatomic) int nativeSocket;

is implemented:


    @synthesize nativeSocket = _nativeSocket;
    - (void)setNativeSocket:(int)nativeSocket;
    {
        _nativeSocket = nativeSocket %2B 1;
    }

    - (int)nativeSocket
    {
        return _nativeSocket - 1;
    }

We’re subtracting one from the underlying instance variable. The reason for this is that, firstly, the Objective-C runtime guarantees all instance variables to be initialized to zero after `-alloc` has been called. And secondly, sockets are considered valid as long as they’re non-negative, i.e. zero and up are valid socket numbers.

By offsetting the value, we can safely check if the socket value has been set even before `-init` has been called.

### Putting It All Together

Our [`DatagramSocket` class][24] wraps all the low-level UDP socket workings. The `DroneCommunicator` class uses it to communicate with the drone on both the _Navigation Data Port_ 5554 and the _AT Command Port_ 5556, like this:


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

The delegate method then branches based on the socket:


    - (void)datagramSocket:(DatagramSocket *)datagramSocket didReceiveData:(NSData *)data;
    {
        if (datagramSocket == self.navigationDataSocket) {
            [self didReceiveNavigationData:data];
        } else if (datagramSocket == self.commandSocket) {
            [self didReceiveCommandResponseData:data];
        }
    }

The only data that our sample app processes is the navigation data. This is done by the `DroneNavigationState` class, like this:


    - (void)didReceiveNavigationData:(NSData *)data;
    {
        DroneNavigationState *state = [DroneNavigationState stateFromNavigationData:data];
        if (state != nil) {
            self.navigationState = state;
        }
    }

## Sending Commands

With the UDP socket up and running, sending commands is relatively straightforward. The so-called _AT Command Port_ accepts plain ASCII commands, which look something like this:


    AT*CONFIG=1,"general:navdata_demo","FALSE"
    AT*CONFIG=2,"control:altitude_max","1600"
    AT*CONFIG=3,"control:flying_mode","1000"
    AT*COMWDG=4
    AT*FTRIM=5

The [AR Drone SDK][25] contains a PDF document called _ARDrone Developer Guide_, which describes all AT commands in more detail.

We created a series of convenience and helper methods inside the `DroneCommunicator` class, so that the above can be sent with:


    [self setConfigurationKey:@"general:navdata_demo" toString:@"FALSE"];
    [self setConfigurationKey:@"control:altitude_max" toString:@"1600"];
    [self setConfigurationKey:@"control:flying_mode" toString:@"1000"];
    [self sendCommand:@"COMWDG" arguments:nil];
    [self sendCommand:@"FTRIM" arguments:nil];

All drone commands start with `AT*`, followed by the command name, and `=`, followed by the arguments separated by commas. The first argument is the sequence number of the command.

For this, we created `-sendCommand:arguments:`, which inserts the command sequence number at index 0:


    - (int)sendCommand:(NSString *)command arguments:(NSArray *)arguments;
    {
        NSMutableArray *args2 = [NSMutableArray arrayWithArray:arguments];
        self.commandSequence%2B%2B;
        NSString *seq = [NSString stringWithFormat:@"%d", self.commandSequence];
        [args2 insertObject:seq atIndex:0];
        [self sendCommandWithoutSequenceNumber:command arguments:args2];
        return self.commandSequence;
    }

and in turn calls `-sendCommandWithoutSequenceNumber:arguments:`, which prefixes the `AT*` and concatenates the command and arguments:


    - (void)sendCommandWithoutSequenceNumber:(NSString *)command arguments:(NSArray *)arguments;
    {
        NSMutableString *atString = [NSMutableString stringWithString:@"AT*"];
        [atString appendString:command];
        NSArray* processedArgs = [arguments valueForKey:@"description"];
        if (0 < arguments.count) {
            [atString appendString:@"="];
            [atString appendString:[processedArgs componentsJoinedByString:@","]];
        }
        [atString appendString:@""];
        [self sendString:atString];
    }

Finally, the completed string is converted to data and passed to the socket by:


    - (void)sendString:(NSString*)string
    {
        NSData *data = [string dataUsingEncoding:NSASCIIStringEncoding];
        if (data != nil) {
            [self.commandSocket asynchronouslySendData:data];
        } else {
            NSLog(@"Unable to convert string to ASCII: %@", string);
        }
    }

### Encoding Floating Point Values

For some strange reason, the people that engineered the drone protocol decided that floating point values should be sent as the integers that have the same bit pattern. This is truly odd, but we have to play along.

Let’s say we’d want to tell the drone to move forward at the relative speed 0.5. The `float` value 0.5 looks like this in binary:


    0011 1111 0000 0000 0000 0000 0000 0000

If we reinterpret this value as a 32-bit integer, it’s 1056964608. Hence, we’d send:


    AT*PCMD=6,1,0,1056964608,0,0

to the drone.

In our case, we’re using numbers wrapped in `NSNumber` and the resulting code looks like this:


    NSNumber *number = (id) self.flightState[i];
    union {
        float f;
        int i;
    } u;
    u.f = number.floatValue;
    [result addObject:@(u.i)];

The trick here is to use a `union` – a lesser-known part of the C language. Unions allow multiple different types (in this case, `int` and `float`) to reside at the same memory location. We then store the floating point value into `u.f` and read the integer value from `u.i`.

_Note:_ It is illegal to use code like `int i = *((int *) &f)` – this is not correct C code and results in undefined behavior. The resulting code will sometimes work, but it sometimes won’t. Do not do this. You can read more about this on the [llvm blog][26] under _Violating Type Rules_. Sadly the _AR Drone Developer Guide_ gets this wrong.




* * *

[More articles in issue #8][27]

  * [Privacy policy][28]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-8/index.html
   [5]: http://twitter.com/danielboedewadt
   [6]: http://ardrone2.parrot.com
   [7]: https://en.wikipedia.org/wiki/Quadcopter
   [8]: https://en.wikipedia.org/wiki/Ip_address
   [9]: https://en.wikipedia.org/wiki/User_Datagram_Protocol
   [10]: https://en.wikipedia.org/wiki/Transport_layer
   [11]: https://en.wikipedia.org/wiki/Transmission_Control_Protocol
   [12]: https://en.wikipedia.org/wiki/Internet_Protocol
   [13]: https://en.wikipedia.org/wiki/Pipeline_%28Unix%29
   [14]: http://www.amazon.com/dp/0321336313
   [15]: http://www.amazon.com/dp/020163354X
   [16]: http://www.amazon.com/dp/0201634953
   [17]: https://en.wikipedia.org/wiki/Datagram_socket
   [18]: https://en.wikipedia.org/wiki/Port_number
   [19]: http://www.parrot.com/
   [20]: https://en.wikipedia.org/wiki/Ipv4
   [21]: https://en.wikipedia.org/wiki/Ipv6
   [22]: https://en.wikipedia.org/wiki/Endianness
   [23]: https://developer.apple.com/library/ios/documentation/Performance/Reference/GCD_libdispatch_Ref
   [24]: https://github.com/objcio/issue-8-quadcopter-navigator/blob/master/DatagramSocket.m
   [25]: https://projects.ardrone.org/projects/show/ardrone-api
   [26]: http://blog.llvm.org/2011/05/what-every-c-programmer-should-know.html
   [27]: http://www.objc.io/issue-8
   [28]: http://www.objc.io/privacy.html
