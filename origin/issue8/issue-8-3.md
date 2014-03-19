[Source](http://www.objc.io/issue-8/the-quadcopter-navigator-app.html "Permalink to The Navigator App - Quadcopter Project - objc.io issue #8 ")

# The Navigator App - Quadcopter Project - objc.io issue #8 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# The Navigator App

[Issue #8 Quadcopter Project][4], January 2014

By [Chris Eidhof][5]

In this article, we’ll tie together all the different parts of our system and build the navigator app. This is the app that will run on the iPhone that’s attached to our drone; you can check out the app [on GitHub][6]. Even though the app is meant to be used without direct interaction, during testing we made a small UI that showed us the drone’s state and allowed us to perform commands manually.

## High-Level Overview

In our app, we have a couple of classes:

  * The `DroneCommunicator` takes care of all the communication with the drone over UDP. This is all explained in [Daniel’s article][7].
  * The `RemoteClient` is the class that takes care of communicating with our remote client over Multipeer Connectivity. What happens on the client’s side is explained in [Florian’s][8] article.
  * The `Navigator` takes a target location and calculates the direction we need to fly in, as well as the distance to the target.
  * The `DroneController` talks with the navigator and sends commands to the drone communicator based on the navigator’s direction and distance.
  * The `ViewController` has a small UI, and takes care of setting up the other classes and connecting them. This last part could be done in a different class, but for our purposes, everything is simple enough to keep it in the view controller.

## View Controller

The most important part of our view controller is the setup method. Here, we create a communicator, a navigator, a drone controller, and a remote client. In other words: we set up the whole stack needed for communicating with the drone and the client app and start the navigator:


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

The view controller also is the `RemoteClient`’s delegate. This means that whenever our client app sends a new location or land/reset/takeoff commands, we need to handle that. For example, when we receive a new location, we do the following:


    - (void)remoteClient:(RemoteClient *)client didReceiveTargetLocation:(CLLocation *)location
    {
        self.droneController.droneActivity = DroneActivityFlyToTarget;
        self.navigator.targetLocation = location;
    }

This makes sure the drone starts flying (as opposed to hovering) and updates the navigator’s target location.

## Navigator

The navigator is the class that, given a target location, calculates distance from the current location and the distance in which the drone should fly. To do this, we first need to start listening to core location events:


    - (void)startCoreLocation
    {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;

        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        [self.locationManager startUpdatingLocation];
        [self.locationManager startUpdatingHeading];
    }

In our navigator, we will have two different directions: an absolute direction and a relative direction. The absolute direction is between two locations. For example, the absolute direction from Amsterdam to Berlin is almost straight east. The relative direction also takes our compass into account; given that we want to move from Amsterdam to Berlin, and we’re looking to the east, our relative direction is zero. For rotating the drone, we will use the relative direction. If it’s zero, we can fly straight ahead. If it’s less than zero, we rotate to the right, and if it’s larger than zero, we rotate to the left.

To calculate the absolute direction to our target, we created a helper method on `CLLocation` that calculates the direction between two locations:


    - (OBJDirection *)directionToLocation:(CLLocation *)otherLocation;
    {
        return [[OBJDirection alloc] initWithFromLocation:self toLocation:otherLocation];
    }

As our drone can only fly very small distances (the battery is drained within 10 minutes), we can take a geometrical shortcut and pretend we are on a flat plane, instead of on the earth’s surface:


    - (double)heading;
    {
        double y = self.toLocation.coordinate.longitude - self.fromLocation.coordinate.longitude;
        double x = self.toLocation.coordinate.latitude - self.fromLocation.coordinate.latitude;

        double degree = radiansToDegrees(atan2(y, x));
        return fmod(degree %2B 360., 360.);
    }

In the navigator, we will get callbacks with the location and the heading, and we just store those two values in a property. For example, to calculate the distance in which we should fly, we take the absolute heading, subtract our current heading (this is the same thing as you see in the compass value), and clamp the result between -180 and 180. In case you’re wondering why we’re subtracting 90 as well, this is because we taped the iPhone to our drone at an angle of 90 degrees:


    - (CLLocationDirection)directionDifferenceToTarget;
    {
        CLLocationDirection result = (self.direction.heading - self.lastKnownSelfHeading.trueHeading - 90);
        // Make sure the result is in the range -180 -> 180
        result = fmod(result %2B 180. %2B 360., 360.) - 180.;
        return result;
    }

That’s pretty much all our navigator does. Given the current location and heading, it calculates the distance to the target and the direction in which the drone should fly. We made both these properties observable.

## Drone Controller

The drone controller is initialized with the navigator and the communicator, and based on the distance and direction, it sends commands to the drone. Because these commands need to be sent almost continuously, we create a timer:


    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                        target:self
                                                      selector:@selector(updateTimerFired:)
                                                      userInfo:nil
                                                       repeats:YES];

When the timer fires, and when we’re flying toward a target, we have to send the drone the appropriate commands. If we’re close enough, we just hover. Otherwise, we rotate toward the target, and if we’re headed roughly in the right direction, we fly forward as well:


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

This is the class that takes care of the communication with our [client][8]. We use the Multipeer Connectivity framework, which turned out to be very convenient. First, we need to create a session and a nearby service browser:


    - (void)startBrowsing
    {
        MCPeerID* peerId = [[MCPeerID alloc] initWithDisplayName:@"Drone"];

        self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peerId serviceType:@"loc-broadcaster"];
        self.browser.delegate = self;
        [self.browser startBrowsingForPeers];

        self.session = [[MCSession alloc] initWithPeer:peerId];
        self.session.delegate = self;
    }

In our case, we don’t care a single bit about security, and we always invite all the peers:


    - (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
    {
        [browser invitePeer:peerID toSession:self.session withContext:nil timeout:0];
    }

We need to implement all the methods of both `MCNearbyServiceBrowserDelegate` and `MCSessionDelegate`, otherwise the app crashes. The only method where we do something is `session:didReceiveData:fromPeer:`. We parse the commands that our peer sends us and call the appropriate delegate methods. In our simple app, the view controller is the delegate, and when we receive a new location, we update the navigator. This will make the drone fly toward that new location.

## Conclusion

This article describes the simple app. Originally, we put most of the code in the app delegate and in our view controller. This proved to be easiest for quick hacking and testing. However, as always, writing the code is the simple part, and reading the code is the hard part. Therefore, we refactored everything neatly into separate logical classes.

When working with hardware, it can be quite time-consuming to test everything. For example, in the case of our quadcopter, it takes a while to start the device, send the commands, and run after the device when it’s flying. Therefore, we tested as many things offline as we could. We also added a plethora of log statements, so that we could always debug things.




* * *

[More articles in issue #8][9]

  * [Privacy policy][10]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-8/index.html
   [5]: https://twitter.com/chriseidhof
   [6]: https://github.com/objcio/issue-8-quadcopter-navigator
   [7]: http://www.objc.io/issue-8/communicating-with-the-quadcopter.html
   [8]: http://www.objc.io/issue-8/the-quadcopter-client-app.html
   [9]: http://www.objc.io/issue-8
   [10]: http://www.objc.io/privacy.html
