[Source](http://www.objc.io/issue-4/core-data-fetch-requests.html "Permalink to Fetch Requests - Core Data - objc.io issue #4 ")

# Fetch Requests - Core Data - objc.io issue #4 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# Fetch Requests

[Issue #4 Core Data][4], September 2013

By [Daniel Eggert][5]

A way to get objects out of the store is to use an `NSFetchRequest`. Note, though, that one of the most common mistakes is to fetch data when you don’t need to. Make sure you read and understand [Getting to Objects][6]. Most of the time, traversing relationships is more efficient, and using an `NSFetchRequest` is often expensive.

There are usually two reasons to perform a fetch with an `NSFetchRequest`: (1) You need to search your entire object graph for objects that match specific predicates. Or (2), you want to display all your objects, e.g. in a table view. There’s a third, less-common scenario, where you’re traversing relationships but want to pre-fetch more efficiently. We’ll briefly dive into that, too. But let us first look at the main two reasons, which are more common and each have their own set of complexities.

## The Basics

We won’t cover the basics here, since the Xcode Documentation on Core Data called [Fetching Managed Objects][7] covers a lot of ground already. We’ll dive right into some more specialized aspects.

## Searching the Object Graph

In our [sample with transportation data][8], we have 12,800 stops and almost 3,000,000 stop times that are interrelated. If we want to find stop times with a departure time between 8:00 and 8:30 for stops close to 52° 29’ 57.30” North, %2B13° 25’ 5.40” East, we don’t want to load all 12,800 _stop_ objects and all three million _stop time_ objects into the context and then loop through them. If we did, we’d have to spend a huge amount of time to simply load all objects into memory and then a fairly large amount of memory to hold all of these in memory. Instead what we want to do is have SQLite narrow down the set of objects that we’re pulling into memory.

### Geo-Location Predicate

Let’s start out small and create a fetch request for stops close to 52° 29’ 57.30” North, %2B13° 25’ 5.40” East. First we create the fetch request:


    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[Stop entityName]]

We’re using the `%2BentityName` method that we mention in [Florian’s data model article][9]. Next, we need to limit the results to just those close to our point.

We’ll simply use a (not quite) square region around our point of interest. The actual math is [a bit complex][10], because the Earth happens to be somewhat similar to an ellipsoid. If we cheat a bit and assume the earth is spherical, we get away with this formula:


    D = R * sqrt( (deltaLatitude * deltaLatitude) %2B
                  (cos(meanLatitidue) * deltaLongitude) * (cos(meanLatitidue) * deltaLongitude))

We end up with something like this (all approximate):


    static double const R = 6371009000; // Earth readius in meters
    double deltaLatitude = D / R * 180 / M_PI;
    double deltaLongitude = D / (R * cos(meanLatitidue)) * 180 / M_PI;

Our point of interest is:


    CLLocation *pointOfInterest = [[CLLocation alloc] initWithLatitude:52.4992490
                                                             longitude:13.4181670];

We want to search within ±263 feet (80 meters):


    static double const D = 80. * 1.1;
    double const R = 6371009.; // Earth readius in meters
    double meanLatitidue = pointOfInterest.latitude * M_PI / 180.;
    double deltaLatitude = D / R * 180. / M_PI;
    double deltaLongitude = D / (R * cos(meanLatitidue)) * 180. / M_PI;
    double minLatitude = pointOfInterest.latitude - deltaLatitude;
    double maxLatitude = pointOfInterest.latitude %2B deltaLatitude;
    double minLongitude = pointOfInterest.longitude - deltaLongitude;
    double maxLongitude = pointOfInterest.longitude %2B deltaLongitude;

(This math is broken when we’re close to the 180° meridian. We’ll ignore that since our traffic data is for Berlin which is far, far away.)


    request.result = [NSPredicate predicateWithFormat:
                      @"(%@ 