[Source](http://www.objc.io/issue-10/sync-case-study.html "Permalink to A Sync Case Study - Syncing Data - objc.io issue #10 ")

# A Sync Case Study - Syncing Data - objc.io issue #10 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# A Sync Case Study

[Issue #10 Syncing Data][4], March 2014

By [Florian Kugler][5]

A while ago I was working together with [Chris][6] on an enterprise iPad application that was to be deployed in a large youth sports organization. We chose to use Core Data for our persistency needs and built a custom data synchronization solution around it that fit our needs. In the syncing grid explained in [Drew’s article][7], this solution uses the asynchronous client-server approach.

In this article, I will lay out the decision and implementation process as a case study for rolling out your own syncing solution. It’s not a perfect or a universally applicable one, but it fit our needs at the time.

Before we dive into it: if you’re interested in the topic of data syncing solutions, (which you probably are if you’re reading this), you should definitely also head over to [Brent’s blog][8] and follow his Vesper sync series. It’s a great read, following along his thinking while implementing sync for Vesper.

## Use Case

Most syncing solutions today focus on the problem of syncing a user’s data across multiple personal devices, e.g. [iCloud Core Data sync][9] or the [Dropbox Datastore API][10]. Our syncing needs were a bit different, though. The app we were building was to be deployed within an organization with approximately 50 devices in total. We needed to sync the data between all those devices, each device belonging to a different staff member, with everybody working off the same data set.

The data itself had a moderately complex structure with approximately a dozen entities and many relationships between them. But we needed to handle quite a bit of data. In production, the number of records would quickly grow into the six figures.

While Wi-Fi access would be available for most of the staff members most of the time, the quality of the network connection was pretty poor. But being able to access and work with the app most of the time wouldn’t have been good enough anyway, so we needed to make sure that people could also interact with the data offline.

## Requirements

With this usage scenario in mind, the requirements for our syncing architecture were pretty clear:

  1. Each device has to have the whole data set available, with and without an Internet connection.
  2. Due to the mediocre network connection, syncing has to happen with as few requests as possible.
  3. Changes are only accepted if they were made based off the most recent data, because nobody should be able to override somebody else’s prior changes without being aware of them.

## Design

### API

Due to the nested structure of the data model and potential high latency in the network connection, a traditional REST-style API wouldn’t have been a very good fit. For example, to show a typical dashboard view in the application, several layers of the data hierarchy would have to have been traversed in order to collect all the necessary data: teams, team-player associations, players, screens, and screen items. If we were to query all these entity types separately, we would have ended up with many requests until all the data was up to date.

Instead, we chose to use something more atomic, with a much higher data-to-request ratio. The client interacts with the sync server via a single API endpoint: `/sync`.

In order to achieve this, we needed a custom format of exchanging data between the client and the server that would transport all the necessary information for the sync process and handle it in one request.

### Data Format

The client and the server exchange data via a custom JSON format. The same format is used in both directions – the client talks to the server in the same way the server talks back to the client. A simple example of this format looks like this:


    {
        "maxRevision": 17382,
        "changeSets: [
            ...
        ]
    }

On the top level, the JSON data has two keys: `maxRevision` and `changeSets`. `maxRevision` is a simple revision number that unambiguously identifies the revision of the data set currently available on the client that sends this request. The `changeSets` key holds an array of change set objects that look something like this:


    {
        "types": [ "users" ],
        "users": {
            "create": [],
            "update": [ 1013 ],
            "delete": [],
            "attributes": {
                "1013": {
                    "first_name": "Florian",
                    "last_name": "Kugler",
                    "date_of_birth": "1979-09-12 00:00:00.000%2B00"
                    "revision": 355
                }
            }
        }
    }

The top level, `types`, key lists all the entity types that are contained in this change set. Each entity type then is described by its own change object, which contains the keys `create`, `update`, and `delete`, which are arrays of record IDs – as well as `attributes`, which actually holds the new or updated data for each changed record.

This data format carries a little bit of legacy cruft from a previously existing web application where this particular structure was beneficial for processing in the client-side framework used at the time. But it serves the purpose of the syncing solution described here equally well.

Let’s have a look at a slightly more complex example. We have entered some new screening data for one of the players on a device, which now should be synced up to the server. The request would look something like this:


    {
        "maxRevision": 1000,
        "changeSets": [
            {
                "types": [ "screen_instances", "screen_instance_items" ],
                "screen_instances": {
                    "create": [ -10 ],
                    "update": [],
                    "delete": [],
                    "attributes": {
                        "-10": {
                            "screen_id": 749,
                            "date": "2014-02-01 13:15:23.487%2B01",
                            "comment": ""
                        }
                    }
                },
                "screen_instance_items: {
                    "create": [ -11, -12 ],
                    "update": [],
                    "delete": [],
                    "attributes": {
                        "-11": {
                            "screen_instance_id": -10,
                            "numeric_value": 2
                        },
                        "-12": {
                            ...
                        }
                    }
                }
            }
        ]
    }

Notice how the records being sent have negative IDs. That’s because they are newly created records. The new `screen_instance` record has the ID `-10`, and the `screen_instance_items` records reference this record by their foreign keys.

Once the server has processed this request (let’s assume there was no conflict or permission problem), it would respond with JSON data like this:


    {
        "maxRevision": 1001,
        "changeSets": [
            {
                "conflict": false,
                "types": [ "screen_instances", "screen_instance_items" ],
                "screen_instances": {
                    "create": [ 321 ],
                    "update": [],
                    "delete": [],
                    "attributes": {
                        "321": {
                            "__oldId__": -10
                            "revision": 1001
                            "screen_id": 749,
                            "date": "2014-02-01 13:15:23.487%2B01",
                            "comment": "",
                        }
                    }
                },
                "screen_instance_items: {
                    "create": [ 412, 413 ],
                    "update": [],
                    "delete": [],
                    "attributes": {
                        "412": {
                            "__oldId__": -11,
                            "revision": 1001,
                            "screen_instance_id": 321,
                            "numeric_value": 2
                        },
                        "413": {
                            "__oldId__": -12,
                            "revision": 1001,
                            ...
                        }
                    }
                }
            }
        ]
    }

The client sent the request with the revision number `1000`, and the server now responds with a revision number, `1001`, which is also assigned to all of the newly created records. (The fact that it is only incremented by one tells us that the client’s data set was up to date before this request was issued.)

The negative IDs have now been swapped by the sync server for the real ones. To preserve the relations between the records, the negative foreign keys have also been updated accordingly. However, the client can still map the previous temporary IDs to the permanent IDs, because the server sends the temporary IDs back as part of each record’s attributes.

If the client’s data set would not have been up to date at the time of the request (for example, the client’s revision number was `995`), then the server would respond with multiple change sets to bring the client up to date. The server would send back the change sets necessary to go from `995` to `1000`, plus the change set with the new revision number `1001` that represents the changes the client has just sent.

### Conflict Resolution

As stated above, in this scenario of many people working off the same data set, nobody should be able to override prior changes without being aware of them. The policy here is that whenever you have not seen the latest changes your colleagues have made to the data, you’re not allowed to override their changes unknowingly.

With the system of revision numbers in place, this policy is very straightforward to implement. Whenever the client commits updated records to the sync server, it includes the revision number of each record in the change set. Since revision numbers are never modified on the client side, they represent the state of the record when the client last talked to the server. The server can now look up the current revision number of the record the client is trying to apply a change to, and block the change if it’s not based on the latest revision.

The beauty of this system is that this data exchange format allows transactional changes. One change set in the JSON data can include several changes to different entity types. On the server side, a transaction is started for this change set, and if any of the change set’s records result in a conflict, the transaction is rolled back and the server marks the whole change set with a `conflict` flag when sending it back to the client.

A problem that arises on the client side whenever a conflict happens is the question of how to restore the correct state of the data. Since the changes could have been made while the client was offline and only were committed the next day, we’d have to keep an exact transaction log around (and persist it). This allows us to revert any change in case it creates a conflict during syncing.

In our case, we chose a different route: since the server is the ultimate authority for the ‘truth’ of the data, it just sends the correct data back in case a conflict occurs. On the server side, this turned out to be implemented very easily, whereas it would have required a major effort for the client.

If a client now, for example, deletes a record it is not allowed to delete, the server will respond with a change set marked with the `conflict` flag, and this change set contains the data that has been erroneously deleted, including related records to which the delete has cascaded. This way, the client can easily restore the data that has been deleted without keeping track of all transactions itself.

## Implementation

Now that we have discussed the basics of the syncing concept, let’s have a closer look at the actual implementation.

### Backend

The backend is a very lightweight application built with node.js, and it uses PostgreSQL to store structured data, as well as a Redis key-value store that caches all the change sets representing each database transaction. (In other words, each change set represents the changes that get you from revision number `x` to `x %2B 1`.) These change sets are used to be able to quickly respond with the last few change sets a client is missing when it makes a sync request, rather than having to query all different database tables for records with a revision number greater than `x`.

The implementation details of the backend are beyond the scope of this article. But honestly, there really isn’t too much exciting stuff there. The server simply goes through the change sets it receives, starts a database transaction for each of them, and tries to apply the changes to the database. If a conflict occurs, the transaction gets rolled back and a change set with the true state of the data is constructed. If everything goes smoothly, the server confirms the change with a change set containing the new revision number of the changed records.

After processing the changes the client has sent, it checks if the client’s highest revision number is trailing behind the server’s, and, if that’s the case, adds the change sets to the response, which enables the client to catch up.

### Core Data

The client application uses Core Data, so we need to hook into that to catch the changes the user is making and commit them to the sync server behind the scenes. Similarly, we need to process the incoming data from the sync server and merge it with the local data.

To achieve this, we use a main queue managed object context for everything UI related (this includes data input by the user), and an independent private queue context for importing data from the sync server.

Whenever the user makes a change to the data, the main context gets saved and we listen for its save notifications. From the save notification, we extract the inserted, updated, and deleted objects and construct a change set object that then gets added to a queue of change sets that are waiting to be synced with the server. This queue is persisted (the queue itself and the objects it holds implement `NSCoding`) so that we don’t lose any changes in the case that the app gets killed before it has a chance to talk to the sync server.

Once the client can establish a connection to the sync server, it takes all the change set objects from the queue, converts them into the JSON format described above, and sends them off to the server together with its most current revision number.

Once the response comes in, the client goes through all change sets it received from the server and updates the local data accordingly in the private queue context. Only if this process has completed successfully and without errors, the client stores the current revision number it received from the server in a Core Data entity reserved especially for this purpose.

Last but not least, the changes made in the private queue context are now merged into the main context, so that the UI can update accordingly.

Once all that is complete, we can start over and send the next sync request if something new is in the sync queue.

#### Merge Policy

We have to safeguard against potential conflicts between the private queue context used to import data from the sync server and the main context. The user could easily make some edits in the main context while data is being imported in the background.

Since the data received from the server represents the ‘truth,’ the merge policy is set up so that changes in the persistent store trump in-memory changes when merging from the private to the main context.

This merge policy could, of course, lead to cases where a background change from the sync server, for example, deletes an object that is currently being edited in the user interface. We can give the UI a chance to react to this change before it happens by sending a custom notification about such events when the private queue has saved, but before the changes are merged into the main context.

#### Initial Data Import

Since we’re dealing with substantial amounts of data for mobile devices (in the six figures), it would take quite a bit of time to download all the data from the server and import it on an iOS device. Therefore, we’re shipping a recent snapshot of the data set with the app. These snapshots are simply generated by running the Simulator with a special flag that enables the download of all data from the server if it’s not present yet.

Then we take the SQLite database generated in this process, and run the following two commands on it:


    sqlite> PRAGMA wal_checkpoint;
    sqlite> VACUUM;

The first one makes sure that all changes from the write-ahead logging file are transferred to the main `.sqlite` file, while the second command makes sure that the file is not unnecessarily bloated.

Once the app is started the first time, the database is copied from the app bundle to its final location. For more information on this process and other ways to import data into Core Data, see [this article in objc.io #4][11].

Since the Core Data data model includes a special entity that stores the revision number, the database shipped with the app automatically includes the correct revision number of the data set used to seed the client.

### Compression

Since JSON is a pretty verbose data format, it is important to enable gzip compression for the requests to the server. Adding the `Accept-Encoding: gzip` header to the request allows the server to gzip its response. However, this only enables compression from the server to the client, but not the other way around.

The client including the `Accept-Encoding` header only signals to the server that it supports gzip compression and that the server should send the response compressed if the server supports it too. Usually the client doesn’t know at the time of the request if the server supports gzip or not, therefore it cannot send the request body in a compressed form by default.

In our case though we control the server and we can make sure that it supports gzip compression. Then we can simply gzip the data that should be sent to the server ourselves and add the `Content-Encoding: gzip` header, since we know that the server will be able to handle it. See [this `NSData` category][12] for an example of gzip compression.

### Temporary and Permanent IDs

When creating new records, the client assigns temporary IDs to those records so that it is able to express relations between them when sending them to the server. We simply use negative numbers as temporary IDs, starting with -1 and decreasing on each insert the clients make. The current temporary ID gets persisted in the standard user defaults.

Because of the way we’re handling temporary IDs, it’s very important that we’re only processing one sync request at a time, and also that we maintain a mapping of the client’s temporary IDs to the real IDs received back from the server.

Before sending a sync request, we check if we already have received permanent IDs from the server for records that are waiting to be committed in the queue of pending changes. If that’s the case, we swap out those IDs for their real counterparts and also update any foreign keys that might have used those temporary IDs. If we wouldn’t do this or instead send multiple requests in parallel, it could happen that we accidentally create a record multiple times instead of updating an existing one, because we’re sending it to the server multiple times with a temporary ID.

Since both the private queue context (when importing changes) as well as the main context (when committing changes) have to access this mapping, access to it is wrapped in a serial queue to make it thread-safe.

## Conclusion

Building your own syncing solution is not an easy task and probably will take longer than you think. At least, it took a while to iron out all the edge cases of the syncing system described here. But in return you gain a lot of flexibility and control. For example, it would be very easy to use the same backend for a web interface, or to do data analysis on the backend side.

If you’re dealing with less common syncing scenarios, like the use case described here – where we needed to sync the data set between the personal devices of many people – you might not even have a choice except to roll out your own custom solution. And while it might be painful from time to time to wrap your head around all the edge cases, it’s actually a very interesting project to work on.




* * *

[More articles in issue #10][13]

  * [Privacy policy][14]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-10/index.html
   [5]: https://twitter.com/floriankugler
   [6]: https://twitter.com/chriseidhof
   [7]: http://www.objc.io/issue-10/data-synchronization.html
   [8]: http://www.inessential.com
   [9]: http://www.objc.io/issue-10/icloud-core-data.html
   [10]: https://www.dropbox.com/developers/datastore
   [11]: http://www.objc.io/issue-4/importing-large-data-sets-into-core-data.html
   [12]: https://github.com/nicklockwood/GZIP
   [13]: http://www.objc.io/issue-10
   [14]: http://www.objc.io/privacy.html
