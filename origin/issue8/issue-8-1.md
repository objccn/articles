[Source](http://www.objc.io/issue-8/the-quadcopter-project.html "Permalink to The Project - Quadcopter Project - objc.io issue #8 ")

# The Project - Quadcopter Project - objc.io issue #8 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# The Project

[Issue #8 Quadcopter Project][4], January 2014

By [Florian Kugler][5]

## The Initial Plan

Our first idea was to do some sort of indoor navigation of the drone using Bluetooth beacons. With an iPhone attached to the drone, it should be possible to derive its current position using triangulation from a bunch of iBeacons positioned in the room. At least, so we thought…

However, our first experiments of measuring the distance between the beacon and the iPhone by evaluating the signal strength were very disappointing. The signal seemed too noisy to determine the distance more than two or three meters (approximately six to 10 feet) away from any beacon with reasonable accuracy.

We ditched this plan and started to look for alternatives.

## The Revised Plan

Since we didn’t want to let go of the core idea of attaching an iPhone to the drone and letting it autonomously do the navigation, we decided to give it a shot with plain old GPS. Of course, this meant that we needed to move outdoors for enough space and a good GPS signal. As it turned out, outdoor testing in Berlin during the winter is quite cold, and even light wind caused the drone to drift a lot…

The overall plan was to have one iPhone attached to the drone, connecting to it over WiFi. It measures its current location and orientation via Core Location and controls the drone toward some target coordinates.

To make it a bit more interesting, we added a second iPhone into the mix. This one connected to the iPhone on the drone via the new multipeer APIs, and sent its own location as the target location for the drone. The iPhone on the drone would then try to move the drone (and itself) toward the second iPhone. Additionally, take-off and landing commands could also be sent via this connection to the drone.

There is a running track close to Chris’s house, and the idea of running on the track and having the drone follow us was quite tempting. Unfortunately, we didn’t get quite so far; the cold temperatures and the wind outside equally affected the drone, the drone’s battery lifetime, and our ability to hit the right keys on the keyboard after a short while. (It wasn’t as bad for Chris – we strapped his iPhone to the drone, so he was constantly chasing after the thing to make sure it didn’t fly away with his phone!)

### The Drone

We used a standard AR Drone 2.0 for this project. To mount the iPhone to the drone, we simply wrapped the phone in some bubble wrap and duct-taped it to the drone’s body. Initially, we tried to attach it to the top of the drone, but this turned out to be too unstable. These drones have basically no payload capacity whatsoever, so even the light weight of the iPhone affected the flight stability significantly.

![iphone-above.jpg][6]

The drone drifted off after takeoff a couple of times, so we decided to strap the phone to the bottom of the drone, in order to lower the center of mass. This turned out to work really well. Since the lowest point of the whole drone now was the phone beneath it, we used the widespread [zip tie mod][7] to protect the phone in case the drone came crashing down somewhat harder (which probably was also a relief for the people living in the apartment below…).

![iphone-below.jpg][8]

 

### The Navigator App

As mentioned above, the iPhone attached to the drone is connected via WiFi to the drone itself. Over this connection we can send navigation commands via a UDP API. This all feels a bit obscure, but once we figured out the basics, it worked pretty well. Daniel goes more into detail in [his article][9] of how we used the Core Foundation networking classes to get this to work.

Along with the actual communication between the phone and the drone, the navigator app also has to deal with the navigation part. It uses Core Location to measure its current position and orientation and then calculates the distance to the target. More importantly, it also determines the angular deviation of its current orientation to the target. You can read more about how this was done in [Chris’s article][10].

Lastly, the navigator app has to connect to the client app via multipeer and receive some basic control commands and the target location for the navigation of the drone.

### The Client App

The client app’s only job is to transmit the target location coordinates to the phone attached to the drone, and to send basic commands like takeoff and land. It advertises itself for the multipeer connection and simply broadcasts its location to all connected peers.

![client-app.jpg][11]

Since we wanted to have a way to test the whole setup without running around too much, and since we also wanted to stay indoors, we added two different modes to this app. The first mode simply transmits the center location of a map view as its current location. This way, we could pan around the map and simulate changing target locations. The other mode transmits the phone’s real location as reported by Core Location.

We ended up using only the first mode in our short test flights due to time constraints and the very uncomfortable weather conditions outside. Therefore, our idea of the drone chasing somebody around the running track unfortunately didn’t work out.

Still, it was a fun project and we got to experiment with some interesting APIs. Check out the subsequent articles about [Core Foundation networking][9], the [navigator app][10], and the [client app][12] for more details.




* * *

[More articles in issue #8][13]

  * [Privacy policy][14]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-8/index.html
   [5]: https://twitter.com/floriankugler
   [6]: http://www.objc.io/images/issue-8/iphone-above.jpg (The iPhone mounted above the quadcopter)
   [7]: http://www.youtube.com/watch?v=wit3EmCo3Fs
   [8]: http://www.objc.io/images/issue-8/iphone-below.jpg (The iPhone mounted beneath the quadcopter)
   [9]: http://www.objc.io/issue-8/communicating-with-the-quadcopter.html
   [10]: http://www.objc.io/issue-8/the-quadcopter-navigator-app.html
   [11]: http://www.objc.io/images/issue-8/client-app.jpg (Screenshot of the client app)
   [12]: http://www.objc.io/issue-8/the-quadcopter-client-app.html
   [13]: http://www.objc.io/issue-8
   [14]: http://www.objc.io/privacy.html
