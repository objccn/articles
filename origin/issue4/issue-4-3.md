[Source](http://www.objc.io/issue-4/SQLite-instead-of-core-data.html "Permalink to On Using SQLite and FMDB Instead of Core Data - Core Data - objc.io issue #4 ")

# On Using SQLite and FMDB Instead of Core Data - Core Data - objc.io issue #4 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# On Using SQLite and FMDB Instead of Core Data

[Issue #4 Core Data][4], September 2013

By [Brent Simmons][5]

I can’t in good conscience tell you not to use Core Data. It’s good and getting better, and it’s understood by many other Cocoa developers, which is important when you add people to your team or when someone else takes over your app.

More importantly, it’s simply not worth the time and effort to write your own system instead. Use Core Data. Really.

## Why I Don’t Use Core Data

[Mike Ash writes][6]:

> Personally, I’m not a big fan. I find the API to be unwieldy and the framework itself to be painfully slow for anything more than a small amount of data.

### A Real-Life Example: 10,000 Items

Picture an RSS reader. A user can right-click on a feed and choose Mark All As Read.

Under the hood, there’s an Article entity with a `read` attribute. To mark all items as read, the app has to load all of the articles for the feed (probably via a to-many relationship) and then set the `read` attribute to YES.

Most of the time that’s okay. But suppose there are 200 articles in that feed, and you might consider doing this work in a background thread so you don’t block the main thread (especially if the app is an iPhone app). As soon as you start working with multi-threaded Core Data, things start to get tricky.

That’s probably not so bad, or at least not worth switching away from Core Data.

But then add syncing.

I worked with two different RSS sync APIs that returned arrays of uniqueIDs of articles that had been read. One of those returned up to 10,000 IDs.

You’re not going to load 10,000 articles on the main thread and set `read` to NO. You don’t even want to load 10,000 articles on a background thread, even with careful memory management. It’s just too much work. (Think of the effect on battery life if this is done frequently.)

What you really want to do, conceptually, is this: tell the database to set `read` to YES for each article in an array of unique IDs.

With SQLite you can do that. With one call. And, assuming an index on `uniqueID`, it’s fast. And you can do it on a background thread as easily as on the main thread.

### Another Example: Fast Startup

With another app of mine I wanted to reduce the start-up time — not just the time for the app to launch, but the amount of time before data is displayed.

It was kind of like a Twitter app (though it wasn’t): it displayed a timeline of messages. To display that timeline meant fetching the messages and loading the associated users. It was pretty fast, but still, at start-up, the UI would fill in and _then_ the data would fill in.

My theory about iPhone apps (or any app, really) is that start-up time matters more than most developers think. Apps where start-up time is slower are less likely to get launched, because people remember subconsciously and develop a resistance to launching that app. Reducing start-up time reduces friction and makes it more likely people will continue to use your app, as well as recommend it to other people. It’s part of how you make your app successful.

Since I wasn’t using Core Data I had an easy, old-school solution at hand. I saved the timeline (messages and people objects) to a plist file (via `NSCoding`). At start-up it read the file, created the message and people objects, and displayed the timeline as soon as the UI appeared.

This noticeably reduced latency.

Had the messages and people objects been instances of `NSManagedObject`, this wouldn’t have been possible. (I suppose I could have encoded and stored the object IDs, but that would have meant reading the plist and _then_ hitting the database. This way I avoided the database entirely.)

(Later on I ended up removing that code after newer, faster devices came out. In retrospect, I wish I’d left it in.)

### How I Think About It

When deciding whether or not to use Core Data, I consider a few things:

#### Could There Be an Incredible Amount of Data?

With an RSS reader or Twitter app, the answer is obviously yes. Some people follow hundreds of people. A person might subscribe to thousands of feeds.

Even if your app doesn’t grab data from the web, it’s still possible that a person might automate adding data. If you do a Mac version with AppleScript support, somebody will write a script that loads crazy amounts of data. This is the same if it has a web API for adding data.

#### Could There Be a Web API that Includes Database-Like Endpoints (as Opposed to Object-Like Endpoints)?

An RSS sync API could return a list of the uniqueIDs of read articles. A sync API for a note-taking app might return lists of the uniqueIDs of archived and deleted notes.

#### Could a User Take Actions that Cut Across Large Numbers of Objects?

Under the hood, it’s the same issue as the previous consideration. How well does your recipes app perform when someone deletes all 5,000 pasta recipes the app has downloaded? (On an iPhone?)

If I do decide to use Core Data - (and I have: I’ve shipped Core Data apps) - I pay careful attention to how I’m using it. If, in order to get decent performance, I find that I’m using it as a weird interface to a SQL database, then I know I should drop Core Data and use SQLite more directly.

## How I Use SQLite

I use SQLite with the excellent [FMDB wrapper][7] from Flying Meat Software, by Gus Mueller.

### Basic Operation

I’ve been using SQLite since before iPhones, since before Core Data. Here’s the gist of how it works:

  * All database access — reading and writing — happens in a serial queue, in a background thread. Hitting the database on the main thread is _never_ allowed. Using a serial queue ensures that everything happens in order.
  * I use blocks extensively to make async programming simpler.
  * Model objects exist on the main thread only (with two important exceptions). Changes trigger a background save.
  * Model objects list their database-stored attributes. It might be in code or might in a plist file.
  * Some model objects are uniqued and some aren’t. It depends on the needs of the app. (They’re usually unique.)
  * For relationships I avoid creating lookup tables as much as possible.
  * Some object types are read entirely into memory at start-up. For other object types I may create and maintain an NSMutableSet of just their uniqueIDs, so I know what exists and what doesn’t without having to hit the database.
  * Web API calls happen in background threads, and they get to use “detached” model objects.

I’ll elaborate, using code from my [current app][8].

### Database Updating

I have a single database controller — `VSDatabaseController` in my latest app — that talks to SQLite via FMDB.

FMDB differentiates between updates and queries. To update the database the app calls:


    -[VSDatabaseController runDatabaseBlockInTransaction:(VSDatabaseUpdateBlock)databaseBlock]

`VSDatabaseUpdateBlock` is simple:


    typedef void (^VSDatabaseUpdateBlock)(FMDatabase *database);

`runDatabaseBlockInTransaction` is also simple:


    - (void)runDatabaseBlockInTransaction:(VSDatabaseUpdateBlock)databaseBlock {
        dispatch_async(self.serialDispatchQueue, ^{
            @autoreleasepool {
                [self beginTransaction];
                databaseBlock(self.database);
                [self endTransaction];
            }
        });
    }

(Note that I’m using my own serial dispatch queue. Gus recommends checking out `FMDatabaseQueue`, which is also a serial dispatch queue. I just haven’t gotten around to checking it out yet, since it’s newer than much of the rest of FMDB.)

Calls to `beginTransaction` and `endTransaction` are nestable (in my database controller). At the appropriate time they call `-[FMDatabase beginTransaction]` and `-[FMDatabase commit]`. (Using transactions is a big key to making SQLite fast.) Tip: I store the current transaction count in `-[NSThread threadDictionary]`. That’s a handy spot for per-thread data, which I almost never use for anything else. Almost.

Here’s a simple example of a call to update the database:


    - (void)emptyTagsLookupTableForNote:(VSNote *)note {
        NSString *uniqueID = note.uniqueID;
        [self runDatabaseBlockInTransaction:^(FMDatabase *database) {
            [database executeUpdate:
                @"delete from tagsNotesLookup where noteUniqueID = ?;", uniqueID];
        }];
    }

This illustrates a few things. The first is that SQL isn’t that scary. Even if you’ve never seen it before, you know what’s going on in that line.

`emptyTagsLookupTableForNote`, like every other public interface for `VSDatabaseController`, should be called from the main thread. Model objects may only be referenced on the main thread, and so the block references `uniqueID` but not the `VSNote` object.

Note that in this case I’m updating a lookup table. Notes and tags have a many-to-many relationship, and one way to represent that is with a database table that maps note uniqueIDs and tag uniqueIDs. These tables aren’t hard to maintain, but I do try to avoid their use when possible.

Note the ? in the update string. `-[FMDatabase executeUpdate:]` is a variadic function. SQLite supports using placeholders — ? characters — so you don’t have to put the actual value in the string. This is a security issue: it helps guard against SQL injection. It also saves you the trouble of having to escape values.

And, finally, note that there is an index on noteUniqueID in the tagsNotesLookup table. (Indexes are another key to SQLite performance.) This line of code runs at each launch:


    [self.database executeUpdate:
        @"CREATE INDEX if not exists noteUniqueIDIndex on tagsNotesLookup (noteUniqueID);"];

### Database Fetching

To fetch objects, the app calls:


    -[VSDatabaseController runFetchForClass:(Class)databaseObjectClass
                                 fetchBlock:(VSDatabaseFetchBlock)fetchBlock
                          fetchResultsBlock:(VSDatabaseFetchResultsBlock)fetchResultsBlock];

These two lines do much of the work:


    FMResultSet *resultSet = fetchBlock(self.database);
    NSArray *fetchedObjects = [self databaseObjectsWithResultSet:resultSet
                                                           class:databaseObjectClass];

A database fetch using FMDB returns an `FMResultSet`. With that resultSet you can step through and create model objects.

I recommend writing general code for turning database rows into objects. One way I’ve used is to include a plist with the app that maps column names to model object properties. It also includes types, so you know whether or not to call `-[FMResultSet dateForColumn:]` versus `-[FMResultSet stringForColumn:]` versus something else.

In my latest app I did something simpler. The database rows map exactly to model object property names. All the properties are strings, except for those properties whose names end in “Date.” Simple, but you can see how an explicit map might be needed.

#### Uniquing Objects

Creation of model objects happens in the same background thread that fetches from the database. Once fetched, the app turns these over to the main thread.

Usually I have the objects _uniqued_. The same database row will always result in the same object.

To do the uniquing, I create an object cache, an NSMapTable, in the init method: `_objectCache = [NSMapTable weakToWeakObjectsMapTable]`. I’ll explain:

When, for instance, you do a database fetch and turn the objects over to a view controller, you want those objects to disappear after the view controller is finished with them, or once a different view controller is displayed.

If your object cache is an `NSMutableDictionary`, you’ll have to do some extra work to empty objects from the object cache. It becomes a pain to be sure that it references only objects that have a reference somewhere else. NSMapTable with weak references handles this automatically.

So: we unique the objects on the main thread. If an object already exists in the object cache, we use that existing object. (Main thread wins, since it might have newer changes.) If it doesn’t exist in the object cache, it’s added.

#### Keeping Objects in Memory

There are times when it makes sense to keep an entire object type in memory. My latest app has a `VSTag` object. While there may be many hundreds or thousands of notes, the number of tags is small, often less than 10. And a tag has just six properties: three BOOLs, two very small NSStrings, and one NSDate.

At start-up, the app fetches all the tags and stores them in two dictionaries: one keyed by tag uniqueID, and another keyed by the lowercase tag name.

This simplifies a bunch of things, not least is the tag auto-completion system, which can operate entirely in memory and doesn’t require a database fetch.

However, there are times when keeping all objects in memory is impractical. We don’t keep all notes in memory, for instance.

There are times, though, when for an object type that you can’t keep in memory, you will want to keep all the uniqueIDs in memory. You’d do a fetch like this:


    FMResultSet *resultSet = [self.database executeQuery:@"select uniqueID from some_table"];

The resultSet would contain just uniqueIDs, which you’d then store in an NSMutableSet.

I’ve found this useful sometimes with web APIs. Picture an API call that returns a list of the uniqueIDs of notes created since a certain date and time. If I had an NSMutableSet containing all the uniqueIDs of notes known locally, I could check quickly (via `-[NSMutableSet minusSet]`) to see if there are any missing notes, and then make another API call to download any missing notes. All without hitting the database at all.

But, again, things like this should be done carefully. Can the app afford the memory? Does it really simplify programming _and_ help performance?

Using SQLite and FMDB instead of Core Data allows for a ton of flexibility and makes room for clever solutions. The thing to remember is that sometimes clever is good — and sometimes clever is a big mistake.

### Web APIs

My API calls all happen in a background thread (usually with an `NSOperationQueue`, so I can cancel operations). Model objects are main-thread only — and yet I pass model objects to my API calls.

Here’s how: a database object has a `detachedCopy` method which copies the database object. That copy is _not_ referenced in the object cache I use for uniquing. The only thing that references that object is the API call. When the API call is finished, that object, the detached copy, goes away.

This is a nice system, because it means I can still use model objects with the API calls. A method might look like this:


    - (void)uploadNote:(VSNote *)note {
        VSNoteAPICall *apiCall = [[VSNoteAPICall alloc] initWithNote:[note detachedCopy]];
        [self enqueueAPICall:apiCall];
    }

And VSNoteAPICall would pull values from the detached `VSNote` and create the HTTP request, rather than having a dictionary or some other representation of the note.

#### Handling Web API Return Values

I do something similar with values returned from the web. I’ll create a model object with the returned JSON or XML or whatever, and that model object is also detached. That is, it’s not stored in the object cache used for uniquing.

Here’s where things get dicey. It is sometimes necessary to use that model object to make local changes in two places: the in-memory cache _and_ in the database.

The database is generally the easy part. For instance: there’s already a method in my app which saves a note object. It uses a SQL `insert or replace into` string. I just call that with a note object generated from a web API return value and the database is updated.

But there might also be an in-memory version of that same object. Luckily this is easy to find:


    VSNote *cachedNote = [self.mapTable objectForKey:downloadedNote.uniqueID];

If the cachedNote exists, rather than replace it (which would violate uniquing), I have it pull values from the `downloadedNote`. (This can share code with the `detachedCopy` method.)

Once that cachedNote is updated, observers will note the change via KVO, or I’ll have it post an `NSNotification` of some kind. Or both.

There are other return values from web API calls; I mentioned the big list of read items that an RSS reader might get. In this case, I’d create an `NSSet` out of that list, update the `read` property for each article cached in memory, then call `-[FMDatabase executeUpdate:]`.

The key to making this work is that an NSMapTable lookup is fast. If you find yourself looking for objects inside an NSArray, it’s time to re-think.

## Database Migration

Core Data’s database migration is pretty cool, [when it works][9].

But it is, inescapably, a layer between the code and the database. If you’re using SQLite more directly, you update the database directly.

You can do this safely and easily.

To add a table, for instance:


    [self.database executeUpdate:@"CREATE TABLE if not exists tags "
        "(uniqueID TEXT UNIQUE, name TEXT, deleted INTEGER, deletedModificationDate DATE);"];

Or add an index:


    [self.database executeUpdate:@"CREATE INDEX if not exists "
        "archivedSortDateIndex on notes (archived, sortDate);"];

Or add a column:


    [self.database executeUpdate:@"ALTER TABLE tags ADD deletedDate DATE"];

The app should set up the database in code in the first place using lines like the above. Any changes added later are just added executeUpdate calls — I leave them all in and have them run in order. Since it’s my database that I designed, this isn’t a problem. (And I’ve never seen a performance issue here. It’s fast.)

Bigger changes take more code, of course. But if your data is available via the web, sometimes you can start with a fresh database model and re-download what you need. Sometimes.

## Performance Tips

SQLite can be very, very fast. It can be very slow, too. It’s all in how you use it.

### Transactions

Wrap updates in transactions. Use `-[FMDatabase beginTransaction]` before your updates and `-[FMDatabase commit]` after the updates.

### Denormalize If You Have To

[Denormalization][10] is a bummer. The idea is that you add redundant data in order to speed up queries, but, of course, it also means maintaining redundant data.

I avoid it like crazy, right up until it makes a serious performance difference. And then I do it as minimally as possible.

### Use Indexes

The create table statement for my app’s tags table looks like this:


    CREATE TABLE if not exists tags
      (uniqueID TEXT UNIQUE, name TEXT, deleted INTEGER, deletedModificationDate DATE);

The uniqueID column is automatically indexed, since it’s defined as unique. But if I wanted to query that table by name, I might make an index on the name, like this:


    CREATE INDEX if not exists tagNameIndex on tags (name);

You can do indexes on multiple columns at once, like this:


    CREATE INDEX if not exists archivedSortDateIndex on notes (archived, sortDate);

But note that too many indexes can slow down your inserts. You need just enough amount and just the right ones.

### Use the Command Line App

I have an `NSLog` that runs when my app launches in the simulator. It prints the path to the database, so I can open it using the command-line sqlite3 app. (Do a man sqlite3 for info about the app.)

To open the database: `sqlite3 path/to/database`.

Once open, you can look at the schema: type `.schema`.

You can do updates and run queries; it’s a great way to get your SQL correct before using it in your app.

One of the coolest parts is the [SQLite Explain Query Plan command][11]. You want to make sure your queries run as quickly as possible.

### Real-Life Example

My app displays a table listing all the tags of non-archived notes. This query is re-run whenever a note or tag changes, and it needs to be super fast.

I was able to do the query with a [SQL join][12], but it was slow. (Joins are slow.)

So I fired up sqlite3 and started experimenting. I looked again at my schema and realized I could denormalize. While the archived status of a note is stored in the notes table, it could also be stored in the tagsNotesLookup table.

Then I could do a query like this:


    select distinct tagUniqueID from tagsNotesLookup where archived=0;

I already had an index on tagUniqueID. So I used explain query plan to tell me what would happen when I ran that query.


    sqlite> explain query plan select distinct tagUniqueID from tagsNotesLookup where archived=0;
    0|0|0|SCAN TABLE tagsNotesLookup USING INDEX tagUniqueIDIndex (~100000 rows)

It’s nice that it’s using an index, but SCAN TABLE sounds ominous. Better yet would be a SEARCH TABLE and a [covering index][13].

I added an index on tagUniqueID and archive:


    CREATE INDEX archivedTagUniqueID on tagsNotesLookup(archived, tagUniqueID);

I ran explain query plan again:


    sqlite> explain query plan select distinct tagUniqueID from tagsNotesLookup where archived=0;
    0|0|0|SEARCH TABLE tagsNotesLookup USING COVERING INDEX archivedTagUniqueID (archived=?) (~10 rows)

_Way_ better.

### More Performance Tips

Somewhere along the line FMDB, added the ability to cache statements, so I always call [`self.database setShouldCacheStatements:YES]` when creating/opening a database. This means you don’t have to re-compile each statement for every call.

I’ve never found good guidance on using `vacuum`. If the database isn’t compacted periodically, it gets slower and slower. I have my app run a vacuum about once a week. (It stores the last vacuum date in NSUserDefaults, and checks at start if it’s been a week.)

It’s possible that auto_vacuum would be better — see the list of [pragma statements supported by SQLite][14].

## Bonus Cool Thing

Gus Mueller asked me to cover custom SQLite functions. This isn’t something I’ve actually used, but now that he’s pointed it out, it’s a safe bet I’ll find a use for it. Because it’s cool.

[Gus posted a Gist][15] where a query looks like this:


    select displayName, key from items where UTTypeConformsTo(uti, ?) order by 2;

SQLite doesn’t know anything about UTTypes. But you can add Core functions as a block — see `-[FMDatabase makeFunctionNamed:maximumArguments:withBlock:]`.

You could instead do a larger query, and then evaluate each object — but that’s a bunch more work. Better to do the filtering at the SQL level instead of after turning table rows into objects.

## Finally

You really should use Core Data. I’m not kidding.

I’ve been using SQLite and FMDB for a long time, and I get a particular thrill out of going the extra mile (or two or ten) and getting exceptional performance.

But remember that devices are getting faster. And also remember that anybody else who looks at your code is going to expect Core Data, which he or she already knows — someone else isn’t going to know how your database code works.

So please treat this entire article as a madman’s yelling about the detailed and crazy world he’s created for himself — and locked himself into.

Just shake your head a little sadly, and please enjoy the awesome Core Data articles in this issue.

Up next for me, after checking out the custom SQLite functions feature Gus pointed out, is investigating SQLite’s [full-text search extension][16]. There’s always more to learn.




* * *

[More articles in issue #4][17]

  * [Privacy policy][18]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-4/index.html
   [5]: http://inessential.com/
   [6]: http://www.mikeash.com/pyblog/friday-qa-2013-08-30-model-serialization-with-property-lists.html
   [7]: https://github.com/ccgus/fmdb
   [8]: http://vesperapp.co/
   [9]: http://openradar.appspot.com/search?query=migration
   [10]: http://en.wikipedia.org/wiki/Denormalization
   [11]: http://www.sqlite.org/eqp.html
   [12]: http://en.wikipedia.org/wiki/Join_%28SQL%29
   [13]: http://www.sqlite.org/queryplanner.html#covidx
   [14]: http://www.sqlite.org/pragma.html#pragma_auto_vacuum
   [15]: https://gist.github.com/ccgus/6324222
   [16]: http://www.sqlite.org/fts3.html
   [17]: http://www.objc.io/issue-4
   [18]: http://www.objc.io/privacy.html
