将对象从存储中取出来的方法之一是使用 `NSFetchRequest`。但是请注意，一个最常见的错误是在你不需要的时候去读取数据。请确保你已经阅读并理解了[获取对象](http://objccn.io/issue-4-1/#getting-to-objects)一节中的内容。大多数时候，遍历关系更加有效，而使用 `NSFetchRequest` 往往成本很高。

通常有两个原因使用 `NSFetchRequest` 来执行数据获取：(1) 你需要为匹配特定谓词 (predicate) 的对象搜索整个对象图；或者 (2) 你想要在比如 table view 这样的地方显示所有的对象。其实还有第三种，也是一个较不常见的情况，就是在遍历关系的同时却想要更高效地预先获取数据。我们也将简单深入这个问题。不过我们先来看看两个主要原因，它们更加常见并且每个都具有自己的复杂性。

## 基础

在这里我们不会涉及基础内容，因为一个关于 Core Data 的名为 [Fetching Managed Objects](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CoreData/Articles/cdFetching.html) 的 Xcode 文档已经涵盖了大量基本原理。我们将深入到一些更专业的方面。

## 搜索对象图

在我们的 [交通数据的例子](https://github.com/objcio/issue-4-importing-and-fetching) 中，我们有 12,800 个车站，其中有接近 3,000,000 个停留时间相互关联。对接近北纬 52° 29' 57.30"，东经 +13° 25' 5.40" 的车站，如果我们想要按照发车时间介于 8：00 和 8：30 之间的条件来进行查找，我们不会想要在这个 context 中加载所有的 12,800 个 `车站` 对象和所有三百万的 `停留时间` 对象，然后再对它们进行循环访问。如果我们这样做，将不得不花费大量时间以及相当大的存储空间以将所有的对象加载到存储器中。取而代之，我们想要的是使用 SQLite 来缩减进入内存的的对象的数量。

让我们从小处开始，为位置接近北纬 52° 29' 57.30" 东经 +13° 25' 5.40" 的车站创建一个 fetch 请求。首先我们创建这个 fetch 请求：
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[Stop entityName]]

我们使用 [Florian 的 data model 文章中](http://objccn.io/issue-4-4/#creating-objects) 中提到的 `+entityName` 方法。然后，我们需要将结果限定为那些接近我们的点的结果。

我们可以简单的用一个 (不完全) 正方形区域围绕我们的兴趣点。实际在数学上这[有些复杂](https://en.wikipedia.org/wiki/Geographical_distance)，因为地球恰好有点类似于一个椭球。但是如果我们假设地球是球体，则可以得到这个公式：

    D = R * sqrt( (deltaLatitude * deltaLatitude) +
	              (cos(meanLatitidue) * deltaLongitude) * (cos(meanLatitidue) * deltaLongitude))

我们最后可以得到以下内容 (均为近似值)：

    static double const R = 6371009000; // 地球半径（单位：米）
    double deltaLatitude = D / R * 180 / M_PI;
    double deltaLongitude = D / (R * cos(meanLatitidue)) * 180 / M_PI;

我们的感兴趣的点是：

    CLLocation *pointOfInterest = [[CLLocation alloc] initWithLatitude:52.4992490 
                                                             longitude:13.4181670];

我们想在 ±263 英尺（80 米）内进行搜索：

    static double const D = 80. * 1.1;
    double const R = 6371009.; // 地球半径（单位：米）
    double meanLatitidue = pointOfInterest.latitude * M_PI / 180.;
    double deltaLatitude = D / R * 180. / M_PI;
    double deltaLongitude = D / (R * cos(meanLatitidue)) * 180. / M_PI;
    double minLatitude = pointOfInterest.latitude - deltaLatitude;
    double maxLatitude = pointOfInterest.latitude + deltaLatitude;
    double minLongitude = pointOfInterest.longitude - deltaLongitude;
    double maxLongitude = pointOfInterest.longitude + deltaLongitude;

（当我们接近 180° 经线的时候，这个运算不成立。由于我们的交通数据源于离 180° 经线很远很远的柏林，所以我们忽略这个问题。）

    request.result = [NSPredicate predicateWithFormat:
                      @"(%@ <= longitude) AND (longitude <= %@)"
                      @"AND (%@ <= latitude) AND (latitude <= %@)",
                      @(minLongitude), @(maxLongitude), @(minLatitude), @(maxLatitude)];

指定一种排序描述符毫无意义，因为我们会在内存中做第二次遍历。不过我们将让 Core Data 在返回对象里填上所有值。

    request.returnsObjectsAsFaults = NO;

如果不做这个设置，Core Data 将把值取入持久化存储协调器的行缓存 (row cache) 中，而不是填充实际对象。通常来说这是没问题的，不过由于我们将立刻访问所有对象，所以我们并不希望出现这种行为。

> <p><span class="secondary radius label">编者注</span> 把属性值先取入缓存中，在对象需要的时候再进行一次访问，这在 Core Data 中是默认行为，这种技术称为 Faulting。这么做可以避免降低内存开销，但是如果你确定将访问结果对象的具体属性值时，可以禁用 Faults 以提高获取性能。

为安全防范考虑，最好加上：

    request.fetchLimit = 200;

执行这条 fetch 请求

    NSError *error = nil;
    NSArray *stops = [moc executeFetchRequest:request error:&error];
    NSAssert(stops != nil, @"Failed to execute %@: %@", request, error);

获取操作失败唯一 (可能) 的原因是储存器损坏（文件被删除等等），否则就是 fetch 请求中出现了语法错误。所以在这里使用 `NSAssert()` 
是安全的。

我们现在使用 Core Locations，对内存中的数据做第二次遍历。

    NSPredicate *exactPredicate = [self exactLatitudeAndLongitudePredicateForCoordinate:self.location.coordinate];
    stops = [stops filteredArrayUsingPredicate:exactPredicate];

和：

    - (NSPredicate *)exactLatitudeAndLongitudePredicateForCoordinate:(CLLocationCoordinate2D)pointOfInterest;
    {
        return [NSPredicate predicateWithBlock:^BOOL(Stop *evaluatedStop, NSDictionary *bindings) {
            CLLocation *evaluatedLocation = [[CLLocation alloc] initWithLatitude:evaluatedStop.latitude longitude:evaluatedStop.longitude];
            CLLocationDistance distance = [self.location distanceFromLocation:evaluatedLocation];
            return (distance < self.distance);
        }];
    }

至此我们完成了全部设置。

#### 地理定位性能

使用装载了 SSD 硬盘的新一代 MacBook Pro 读取这些数据平均约需要 360µs，也就是说，你每秒可以做大约 2800 次请求。iPhone 5 平均约需要 1.67ms，每秒 600 次请求。

如果加上 `-com.apple.CoreData.SQLDebug1` 作为启动参数传递给应用程序，我们将得到如下输出：

    sql: SELECT 0, t0.Z_PK, t0.Z_OPT, t0.ZIDENTIFIER, t0.ZLATITUDE, t0.ZLONGITUDE, t0.ZNAME FROM ZSTOP t0 WHERE (? <=  t0.ZLONGITUDE AND  t0.ZLONGITUDE <= ? AND ? <=  t0.ZLATITUDE AND  t0.ZLATITUDE <= ?)  LIMIT 100
    annotation: sql connection fetch time: 0.0008s
    annotation: total fetch execution time: 0.0013s for 15 rows.

除开一些 (对于存储本身的) 统计信息外，实际为读取数据而生成的 SQL 是：

    SELECT 0, t0.Z_PK, t0.Z_OPT, t0.ZIDENTIFIER, t0.ZLATITUDE, t0.ZLONGITUDE, t0.ZNAME FROM ZSTOP t0
    WHERE (? <=  t0.ZLONGITUDE AND  t0.ZLONGITUDE <= ? AND ? <=  t0.ZLATITUDE AND  t0.ZLATITUDE <= ?)
    LIMIT 200

这正是我们所期望的。如果我们想要对这个性能进行调查研究，我们可以使用 SQL [`EXPLAIN` 命令](https://www.sqlite.org/eqp.html)。为此，我们可以像下面这样使用命令行 `sqlite3` 来打开数据库：

    % cd TrafficSearch
    % sqlite3 transit-data.sqlite
    SQLite version 3.7.13 2012-07-17 17:46:21
    Enter ".help" for instructions
    Enter SQL statements terminated with a ";"
    sqlite> EXPLAIN QUERY PLAN SELECT 0, t0.Z_PK, t0.Z_OPT, t0.ZIDENTIFIER, t0.ZLATITUDE, t0.ZLONGITUDE, t0.ZNAME FROM ZSTOP t0
    ...> WHERE (13.30845219672199 <=  t0.ZLONGITUDE AND  t0.ZLONGITUDE <= 13.33441458422844 AND 52.42769566863058 <=  t0.ZLATITUDE AND  t0.ZLATITUDE <= 52.44352370653525)
    ...> LIMIT 100;
    0|0|0|SEARCH TABLE ZSTOP AS t0 USING INDEX ZSTOP_ZLONGITUDE_INDEX (ZLONGITUDE>? AND ZLONGITUDE<?) (~6944 rows)

这告诉我们 SQLite 为 `(ZLONGITUDE>? AND ZLONGITUDE<?)` 条件使用了 `ZSTOP_ZLONGITUDE_INDEX`。我们像 [model 文章](http://objccn.io/issue-4-4/#indexes) 中描述的那样使用*复合索引*则会做的更好。由于我们总是同时搜索经度和纬度的组合，这么做会更高效，而且我们可以去掉经度和纬度各自的索引。

这将使输出像下面这样：

    0|0|0|SEARCH TABLE ZSTOP AS t0 USING INDEX ZSTOP_ZLONGITUDE_ZLATITUDE (ZLONGITUDE>? AND ZLONGITUDE<?) (~6944 rows)

在我们的简单案例中，加上复合索引几乎不影响性能。

就像在 [SQLite 文档](https://www.sqlite.org/eqp.html)中的说明一样，如果你的输出里含有 `SCAN TABLE` 的话，你就要提高警惕了，这基本上意味着 SQLite 需要遍历 *所有的* 记录来看看那些是相匹配的。除非你只存储了很少的几个对象，否则你都应该使用 index。

### 子查询

假设我们只想要那些接近我们的且在接下来 20 分钟之内提供服务的车站。

我们可以像这样为 *StopTimes* 的实体创建一个谓词：

    NSPredicate *timePredicate = [NSPredicate predicateWithFormat:@"(%@ <= departureTime) && (departureTime <= %@)",
                                  startDate, endDate];

但是如果我们想要的谓词是可以基于与 *StopTimes 停留时间* 对象的关系而过滤出那些 *Stop 车站* 对象，而不是 *停留时间* 对象本身的话，我们可以使用一个这样的 `子查询` ：

    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"(SUBQUERY(stopTimes, $x, (%@ <= $x.departureTime) && ($x.departureTime <= %@)).@count != 0)",
                              startDate, endDate];

请注意，如果接近午夜，这个逻辑是稍有瑕疵的，因为我们应当将谓词一分为二。不过该逻辑在这个例子中是可行的。

对于限制数据在关系之上的，子查询非常有用。在 Xcode 文档 [`-[NSExpression expressionForSubquery:usingIteratorVariable:predicate:]`](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/Classes/NSExpression_Class/Reference/NSExpression.html#//apple_ref/occ/clm/NSExpression/expressionForSubquery:usingIteratorVariable:predicate:) 中有更多信息。

我们可以简单的使用 `and` 或者 `&&` 来组合两个谓词，例如：

    [NSPredicate predicateWithFormat:@"(%@ <= departureTime) && (SUBQUERY(stopTimes ....

或者在代码中使用 [`+[NSCompoundPredicate andPredicateWithSubpredicates:]`](https://developer.apple.com/library/ios/DOCUMENTATION/Cocoa/Reference/Foundation/Classes/NSCompoundPredicate_Class/Reference/Reference.html#//apple_ref/occ/clm/NSCompoundPredicate/andPredicateWithSubpredicates:)。

我们用一个像这样的谓词来作为结束：

    (lldb) po predicate
    (13.39657778010461 <= longitude AND longitude <= 13.42266155792719
        AND 52.63249629924865 <= latitude AND latitude <= 52.64832433715332)
        AND SUBQUERY(
            stopTimes, $x, CAST(-978250148.000000, "NSDate") <= $x.departureTime 
            AND $x.departureTime <= CAST(-978306000.000000, "NSDate")
        ).@count != 0

#### 子查询性能

如果我们看一下生成的 SQL，它会像下面这样：

    sql: SELECT 0, t0.Z_PK, t0.Z_OPT, t0.ZIDENTIFIER, t0.ZLATITUDE, t0.ZLONGITUDE, t0.ZNAME FROM ZSTOP t0
         WHERE ((? <=  t0.ZLONGITUDE AND  t0.ZLONGITUDE <= ? AND ? <=  t0.ZLATITUDE AND  t0.ZLATITUDE <= ?)
                AND (SELECT COUNT(t1.Z_PK) FROM ZSTOPTIME t1 WHERE (t0.Z_PK = t1.ZSTOP AND ((? <=  t1.ZDEPARTURETIME AND  t1.ZDEPARTURETIME <= ?))) ) <> ?)
         LIMIT 200

这个 fetch 请求在新一代 MacBook Pro 上运行大约需要 12.3 ms。在 iPhone 5 上，大约需要 110 ms。请注意，我们有 300 万 个停留时间 和将近 13,000 个车站。

explan 这个查询，结果如下：

    sqlite> EXPLAIN QUERY PLAN SELECT 0, t0.Z_PK, t0.Z_OPT, t0.ZIDENTIFIER, t0.ZLATITUDE, t0.ZLONGITUDE, t0.ZNAME FROM ZSTOP t0
       ...> WHERE ((13.37190946378911 <=  t0.ZLONGITUDE AND  t0.ZLONGITUDE <= 13.3978625285315 AND 52.41186440524024 <=  t0.ZLATITUDE AND  t0.ZLATITUDE <= 52.42769244314491) AND
       ...> (SELECT COUNT(t1.Z_PK) FROM ZSTOPTIME t1 WHERE (t0.Z_PK = t1.ZSTOP AND ((-978291733.000000 <=  t1.ZDEPARTURETIME AND  t1.ZDEPARTURETIME <= -978290533.000000))) ) <> ?)
       ...> LIMIT 200;
    0|0|0|SEARCH TABLE ZSTOP AS t0 USING INDEX ZSTOP_ZLONGITUDE_ZLATITUDE (ZLONGITUDE>? AND ZLONGITUDE<?) (~3472 rows)
    0|0|0|EXECUTE CORRELATED SCALAR SUBQUERY 1
    1|0|0|SEARCH TABLE ZSTOPTIME AS t1 USING INDEX ZSTOPTIME_ZSTOP_INDEX (ZSTOP=?) (~2 rows)

请注意，我们如何对谓词排序非常重要。我们希望把经纬度放在前面，因为代价低，而子查询由于代价高则放在语句最后。

### 文本搜索

搜索文本是一种常见的情况。在我们的例子中，来看看使用名称来搜索 *车站* 实体。

柏林有个被称为 "U Görlitzer Bahnhof (Berlin)" 的车站。一种很傻很天真的搜索该站的方法如下：

    NSString *searchString = @"U Görli";
    predicate = [NSPredicate predicateWithFormat:@"name BEGINSWITH %@", searchString];

如果你想按照如下所示做的话，事情会变得更糟 (比如进行一项大小写和（或）音调不敏感的查询。)：

    name BEGINSWITH[cd] 'u gorli'

事实上，事情并不是那么简单。Unicode 非常复杂，并且有很多陷阱。首要的是很多字符可以通过多种方式来表示。
[U+00F6](http://unicode.org/charts/PDF/U0080.pdf) 和 [U+006F](http://www.unicode.org/charts/PDF/U0000.pdf)都代表 [U+0308](http://unicode.org/charts/PDF/U0300.pdf) 都可以表示 "ö."。如果你身处 ASCII 码的世界之外时，像大写 / 小写这样的概念就会非常复杂。

SQLite 会为你减轻负担，但它是要付出代价的。虽然它看起来很直接，但事实并非如此。对于字符串搜索，我们想做的是在我们有一个*规范化*的版本可以在其中进行搜索。我们将消除音调符号，把字符串变成小写字母，然后将其放入一个 `normalizedName` 字段中。然后我们将对用于搜索的字符串做同样的事情。然后 SQLite 就不必考虑音调和大小写，在大小写和音调不敏感的情况下，搜索就仍会很快。但是我们必须先完成一系列繁重的任务。

在新一代 MacBook Pro 上，使用示例代码使用 `BEGINSWITH[cd]` 和示例的字符串搜索需要 7.6ms (130 次搜索 / 秒)，在 iPhone 5 上这个数字是每次搜索 47ms，每秒进行 21 次搜索。

为了将字符串转换为小写并移除其音调，我们可以使用 `CFStringTransform()`：

    @implementation NSString (SearchNormalization)
    
    - (NSString *)normalizedSearchString;
    {
        // 参考 <http://userguide.icu-project.org/transforms>
        NSString *mutableName = [self mutableCopy];
        CFStringTransform((__bridge CFMutableStringRef) mutableName, NULL, 
                          (__bridge CFStringRef)@"NFD; [:Nonspacing Mark:] Remove; Lower(); NFC", NO);
        return mutableName;
    }
    
    @end

我们将更新 `Stop` 类来自动更新 `normalizedName`：

    @interface Stop (CoreDataForward)
    
    @property (nonatomic, strong) NSString *primitiveName;
    @property (nonatomic, strong) NSString *primitiveNormalizedName;
    
    @end
    
    
    @implementation Stop
    
    @dynamic name;
    - (void)setName:(NSString *)name;
    {
        [self willAccessValueForKey:@"name"];
        [self willAccessValueForKey:@"normalizedName"];
        self.primitiveName = name;
        self.primitiveNormalizedName = [name normalizedSearchString];
        [self didAccessValueForKey:@"normalizedName"];
        [self didAccessValueForKey:@"name"];
    }
    
	// ...
	
    @end

有了这些，我们就可以用 `BEGINSWITH` 代替 `BEGINSWITH[cd]` 来搜索了：

    predicate = [NSPredicate predicateWithFormat:@"normalizedName BEGINSWITH %@", [searchString normalizedSearchString]];

在新一代 MacBook Pro 上，使用示例代码中的示例字符串搜索 `BEGINSWITH`
需要 6.2ms（160 次搜索 / 秒），在 iPhone 5 大约上需要 40ms，25 次搜索 / 秒。

#### 自由文本搜索

我们的搜索还只能在字符串的开头和搜索字符串相匹配的情况下有效。要解决这个问题就要创建另一个用来搜索的*实体*。我们称这个实体为 `SearchTerm`，给其一个 `normalizedWord` 属性，以及一个和 `Stop` 的关系。对于每个`车站` 我们将规范它们的名称，并将其拆分成一个个词。例如：

        "Gedenkstätte Dt. Widerstand (Berlin)"
    ->  "gedenkstatte dt. widerstand (berlin)"
    ->  "gedenkstatte", "dt", "widerstand", "berlin"

对于每个词。我们创建一个 `SearchTerm` 和一个从 `Stop` 到它的所有 `SearchTerm` 对象的关系。当用户输入一个字符串，我们用以下代码在 `SearchTerm` 对象的 `normalizedWord` 上搜索：

    predicate = [NSPredicate predicateWithFormat:@"normalizedWord BEGINSWITH %@", [searchString normalizedSearchString]]

这也可以在 `Stop` 对象中直接用子查询完成。

## 获取所有对象

如果我们的获取请求中没有设置谓词，我们将为获取到给定 *实体* 的所有对象。如果我们对 `StopTimes` 实体这样做的话，我们将会牵涉 300 万个对象。这将会变得缓慢，以及占用大量内存。然而有时候，我们就是需要获取所有对象。常见的例子是我们想要在一个 table view 中显示所有对象。

在这种情况中，我们要做的是设置批处理量：

    request.fetchBatchSize = 50;

当我们设置了批处理量运行 `-[NSManagedObjectContext executeFetchRequest:error:]` 的时候，我们仍然会得到一个返回的数组。我们可以查询它的元素数量（对于 `StopTimes` 实体而言，这将接近 300 万），不过 Core Data 将只会随着我们对数组的循环访问将对象填充进去。如果这些对象不再被访问，Core Data 则会再次清理对象。简单来说，数组的批处理量为 50（在这个例子中）。Core Data 将一次获取 50 个对象。一旦有超过一定数量的批量对象，Core Data 将释放最旧一批对象。于是，你就可以在这样的数组中循环访问所有对象，而无需在存储器中同时存所有 300 万个对象。

在 iOS 中，如果你使用 `NSFetchedResultsController` 且有很多对象，请确保你的 fetch 请求中设置了 `fetchBatchSize`。你需要实际实验以确定多少的处理量更适合你。一般来说，将其设置为你要显示的数目的两倍，会是一个不错的开始。

---

 

原文 [Fetch Requests](http://www.objc.io/issue-4/core-data-fetch-requests.html)

译文 [Fetch 请求](https://github.com/answer-huang/objcio_cn/blob/master/%E7%BF%BB%E8%AF%91%E5%AE%8C%E6%88%90/Fetch%20Request)

校对 [Ckitakishi](http://ckitakishi.com)
