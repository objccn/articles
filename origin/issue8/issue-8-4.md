[Source](http://www.objc.io/issue-8/the-quadcopter-client-app.html "Permalink to The Client App - Quadcopter Project - objc.io issue #8 ")

# The Client App - Quadcopter Project - objc.io issue #8 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# The Client App

[Issue #8 Quadcopter Project][4], January 2014

By [Florian Kugler][5]

The client app is the component in [this project][6] that sends the target location coordinates to the phone strapped to the drone. It’s a pretty simple task, but there are a few interesting bits to it, like the use of the new (as of iOS 7) Multipeer Connectivity APIs and [NSSecureCoding][7].

The app exposes a very simple – and not very pretty – interface:

![client-app.jpg][8]

## Multipeer Connectivity

In order to establish a connection between the client and the navigation app on the drone, we’re going to use the new Multipeer Connectivity APIs. For our purposes, we only need to connect two devices to each other, so the multipeer APIs are not used to their full potential here. But the code is actually the same if more clients were to join.

### Advertising

We decided to make the client app the advertiser, and the navigation app on the drone is the browser. The client starts advertising using the following simple statements:


    NSString *displayName = [UIDevice currentDevice].name;
    self.peer = [[MCPeerID alloc] initWithDisplayName:displayName];
    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peer discoveryInfo:nil serviceType:ServiceTypeIdentifier];
    self.advertiser.delegate = self;
    [self.advertiser startAdvertisingPeer];

Once another device that is browsing for clients with the same service type discovers the advertiser, we’ll receive a delegate callback in order to establish the connection:


    - (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler
    {
        self.session = [[MCSession alloc] initWithPeer:self.peer];
        self.session.delegate = self;
        invitationHandler(YES, self.session);
    }

Once we receive the invitation, we create a new session object, set ourselves as delegate of the session, and accept the invitation by calling the `invitationHandler` with `YES` and the session as arguments.

In order to be able to show the status of the connection on screen, we’re going to implement another session delegate method. Since we’re only connecting to one other device, we simply using the number of currently connected peers being greater than zero as indicator for being connected or not:


    - (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSString *notificationName = session.connectedPeers.count > 0 ? MultiPeerConnectionDidConnectNotification : MultiPeerConnectionDidDisconnectNotification;
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
        }];
    }

Since five of the six methods in the `MCSessionDelegate` protocol are required, we have to add all those too, although we don’t need them for our specific purposes.

At this point, the connection is established and we can use the session’s `sendData:toPeers:withMode:error:` method to send data. We’ll look more into this later on.

### Browsing

The navigation app running on the phone flying on the drone has to initiate the connection by sending the client an invitation. This is equally straightforward to do. The first step is to start browsing for peers:


    MCPeerID* peerId = [[MCPeerID alloc] initWithDisplayName:@"Drone"];
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peerId serviceType:ServiceTypeIdentifier];
    self.browser.delegate = self;
    [self.browser startBrowsingForPeers];

Once a peer is found, we get a delegate callback and can invite the peer into our session:


    - (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
    {
        self.session = [[MCSession alloc] initWithPeer:peerId];
        self.session.delegate = self;
        [browser invitePeer:peerID toSession:self.session withContext:nil timeout:0];
    }

Once the client sends some data, we’ll receive it via the session’s delegate method, `session:didReceiveData:fromPeer:`.

## Transmitting Data

Every peer in a multipeer session can very easily send data using the `sendData:toPeers:withMode:error:` method. We only have to figure out how to package the data in order to send it over the air.

One of the most common options would be to simply encode it as JSON. Although this would easily work for our purposes, we will do something a little bit more interesting by using [NSSecureCoding][7]. It doesn’t really make a difference for our example, but if you need to transmit more data, this is more efficient than encoding and decoding JSON.

First, we create a class to package the data we need to send in:


    @interface RemoteControlCommand : NSObject 

    %2B (instancetype)commandFromNetworkData:(NSData *)data;
    - (NSData *)encodeAsNetworkData;

    @property (nonatomic) CLLocationCoordinate2D coordinate;
    @property (nonatomic) BOOL stop;
    @property (nonatomic) BOOL takeoff;
    @property (nonatomic) BOOL reset;

    @end

In order to enable secure coding (ensuring that the received data is actually of the type we expect) we have to add the `supportsSecureCoding` class method to our implementation:


    %2B (BOOL)supportsSecureCoding;
    {
        return YES;
    }

Next up, we’ll add methods to encode an instance of this object and package it into a `NSData` object to be able to send it over the multipeer connection:


    - (NSData *)encodeAsNetworkData;
    {
        NSMutableData *data = [NSMutableData data];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        archiver.requiresSecureCoding = YES;
        [archiver encodeObject:self forKey:@"command"];
        [archiver finishEncoding];
        return data;
    }

    - (void)encodeWithCoder:(NSCoder *)coder;
    {
        [coder encodeDouble:self.coordinate.latitude forKey:@"coordinate.latitude"];
        [coder encodeDouble:self.coordinate.longitude forKey:@"coordinate.longitude"];
        [coder encodeBool:self.stop forKey:@"stop"];
        [coder encodeBool:self.stop forKey:@"takeoff"];
        [coder encodeBool:self.stop forKey:@"reset"];
    }

Now we can easily send a control command with a few lines of code:


    RemoteControlCommand *command = [RemoteControlCommand alloc] init];
    command.coordinate = self.location.coordinate;
    NSData *data = [command encodeAsNetworkData];
    NSError *error;
    [self.session sendData:data toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];

In order for the receiving end to be able to decode the data, we’re adding another class method to our `RemoteControlCommand` class:


    %2B (instancetype)commandFromNetworkData:(NSData *)data;
    {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        unarchiver.requiresSecureCoding = YES;
        RemoteControlCommand *result = [unarchiver decodeObjectOfClass:self forKey:@"command"];
        return result;
    }

Lastly, we need to implement `initWithCoder:` so that the encoded object can get decoded from the data:


    - (id)initWithCoder:(NSCoder *)coder;
    {
        self = [super init];
        if (self != nil) {
            CLLocationCoordinate2D coordinate = {};
            coordinate.latitude = [coder decodeDoubleForKey:@"coordinate.latitude"];
            coordinate.longitude = [coder decodeDoubleForKey:@"coordinate.longitude"];
            self.coordinate = coordinate;
            self.stop = [coder decodeBoolForKey:@"stop"];
            self.takeoff = [coder decodeBoolForKey:@"takeoff"];
            self.reset = [coder decodeBoolForKey:@"reset"];
        }
        return self;
    }

## Tying It All Together

Now that we have the multipeer connection in place and we can encode and decode the remote control commands, we’re ready to actually send location coordinates or control commands over the air. For the sake of example, we will only look at transmitting coordinates, since it’s exactly the same for the other commands.

As discussed in the [project overview][6], this client app can either send its current geolocation, or alternatively, a position picked on a map, in order to make testing the drone navigation easier. For the first case, we just need to implement `CLLocationManager`’s delegate method `locationManager:didUpdateLocations:` and store the current location in a property:


    - (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
    {
        self.location = locations.lastObject;
    }

To send the current location on a regular basis, we set up a timer:


    - (void)startBroadcastingLocation
    {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(broadcastLocation) userInfo:nil repeats:YES];
    }

And last but not least, the `broadcastLocation` method that’s now getting called once per second will create a `RemoteControlCommand` object and send it off to connected peers:


    - (void)broadcastLocation
    {
        RemoteControlCommand *command = [RemoteControlCommand alloc] init];
        command.coordinate = self.location.coordinate;
        NSData *data = [command encodeAsNetworkData];
        NSError *error;
        [self.session sendData:data toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
        if (error) {
            NSLog(@"Error transmitting location: %@", error);
        }
    }

And that’s pretty much it. Follow along the other articles about the [navigation app on the drone][9] and the [Core Foundation networking APIs][10] used to communicate with the drone to see how the receiving end of these commands interacts with the drone and actually makes it fly!




* * *

[More articles in issue #8][11]

  * [Privacy policy][12]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-8/index.html
   [5]: https://twitter.com/floriankugler
   [6]: http://www.objc.io/issue-8/the-quadcopter-project.html
   [7]: https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSSecureCoding_Protocol_Ref/content/NSSecureCoding.html
   [8]: http://www.objc.io/images/issue-8/client-app.jpg (Screenshot of the client app)
   [9]: http://www.objc.io/issue-8/the-quadcopter-navigator-app.html
   [10]: http://www.objc.io/issue-8/communicating-with-the-quadcopter.html
   [11]: http://www.objc.io/issue-8
   [12]: http://www.objc.io/privacy.html
