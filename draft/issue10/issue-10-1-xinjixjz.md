<br/>

> Think of sync or all you sync will sink.
>
> _Not Dr. Seuss_

同步是软件开发中的一项基本要素。它包括很多种形式，从强制使用不同设备上的时钟来协商它们之间的延迟，到使用 `@synchronized` 代码块来序列化访问多线程编程中的资源。

本文，我将要介绍多种 _数据同步_ 的方法，接下来本文将使用 _同步_ ( sync )代替数据同步( data synchronization )。简单来说，问题就在于：如何存储时间和空间上分离的两部分数据，让这两部分的数据尽可能的相同。

我个人的兴趣要追溯到早期的 iOS App Store，那时，同步在我的生活中扮演了重要的角色。当时，我是学习卡片应用程序  [Mental Case](http://mentalcaseapp.com) 的开发者。由于包括 Mac 版、 iPad 版和 iPhone 版， Mental Case 更像是一套而不是单个应用，并且它的一大特色就是能够在不同的设备之间同步你的学习资料。最初，在以数据为中心的年代。 Mental Case 将 Mac 作为中心，通过本地 Wi-Fi 网络，和一个或者多个 iOS 设备同步数据。现在， Mental Case 系列应用通过 iCloud 进行对等( peer-to-peer )的数据同步。

合理地实现数据同步是有挑战的，但是更大的问题是专业化而不是开发一个通用的 Web 服务，然后这就要考虑更专业的解决方案。比如，当一类 Web 服务总是需要服务端的开发的时候，使用一种同步框架能够在你现有的代码基础上做最少的改变，并且完全不需要服务端的代码。

在下文中，我将介绍在移动设备早期出现的多种数据同步的方法，在高级层面上解释它们的工作原理，并给出一些他们的最佳使用指导。我还将根据当今的形势，描绘一些数据同步领域的新趋势。

## 简史

在开始介绍多种数据同步方法的细节之前，有必要了解它的演变过程以及如何适应早期的技术带来的限制的。

就消费设备而言，数据同步始于有线连接。上世纪90年代末和21世纪初，像 [Palm Pilot](http://en.wikipedia.org/wiki/PalmPilot) 和 [iPod](http://en.wikipedia.org/wiki/IPod) 这样的外围设备能够通过火线(Firewire)或者USB和Mac或者PC进行同步。苹果的数字中心策略正是基于这种方法。后来，由于网速的提升，Wi-Fi和蓝牙在一定程度上增补了有线连接，但是iTunes现在仍然使用这种方式。

由于21世纪云服务的飞速发展，由 Mac 或者 PC 作为中心的方式已经逐步转向了云。云的优势在于无论什么时候，只要设备有网络，它就可以使用。有了基于云的数据同步，你再也不用呆在家里的电脑旁边进行同步数据了。

上面提到的每一种方式都在设备间利用了我称之为 _同步通讯_( Synchronous Communication, SC )的概念。你的 iPhone 上的一个应用直接和一台 Mac 或者云服务通讯，然后实时地接收返回的数据。

现在，出现了一种新兴的基于 _异步通讯_( Asynchronous Communication, AC )的数据同步方式。应用不再直接和云“通话”，而是和一个框架或者本地的文件系统交换数据。应用程序不再期望立刻得到回应，取而代之的是，数据是在后台和云端进行交互了。

这种方式将应用程序代码和数据同步过程解耦，将开发者从精确操纵数据同步中解放出来。遵循这一新趋势的产品范例有苹果的 [Core Data&mdash;iCloud framework](https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesignForCoreDataIniCloud.html)，[Dropbox Datastore API](https://www.dropbox.com/developers/datastore)，甚至像 [TouchDB](http://labs.couchbase.com/TouchDB-iOS/) (基于 [CouchDB project](http://couchdb.apache.org))那样的文件存储。

数据同步的这段历史并不是遵循一个单一的线性路径。每个阶段都是先遵循，后使用，再创新的更迭演化。今天，所有的这些技术仍然存在并且仍在使用，并且他们中的每一个都有可能是你的某个特定问题的合适的解决方案。

## 同步网格

我们已经知道数据同步的方式可以根据它们是否使用了同步通讯来分类，但是也能够根据与客户端交互是否使用了“智能”服务器，或者同步过程是否采用以客户端处理复杂事情的对等方式。下面这个简单的表格列出了所有的同步技术:

<table>
<tr><td></td> <td><strong>同步</strong></td> <td><strong>异步</strong></td> </tr>
<tr>
	<td style="margin-right:1em"><strong>客户端-服务端</strong></td> 
		<td style="margin-right:1em">
		<a href="https://parse.com">Parse</a><br/>
		<a href="https://www.stackmob.com">StackMob</a><br/>
		<a href="http://www.windowsazure.com/en-us/services/mobile-services/">Windows Azure Mobile Services</a><br/>
		<a href="http://helios.io">Helios</a><br/>
		Custom Web Service
		</td> 
		<td>
		<a href="https://www.dropbox.com/developers/datastore">Dropbox Datastore</a><br/>
		<a href="http://labs.couchbase.com/TouchDB-iOS/">TouchDB</a><br />
		<a href="http://www.wasabisync.com">Wasabi Sync</a><br/>
		<a href="http://zumero.com">Zumero</a>
		</td>
</tr>
<tr>
	<td><strong>对等方式</strong></td> 
		<td>
			iTunes/iPod<br />
			Palm Pilot<br />
		</td>
		<td>
		<a href="https://developer.apple.com/library/ios/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesignForCoreDataIniCloud.html">Core Data with iCloud</a><br/>
		<a href="https://github.com/nothirst/TICoreDataSync">TICoreDataSync</a><br/>
		<a href="https://github.com/drewmccormack/ensembles">Core Data Ensembles</a><br />
		</td>
</tr>
</table>

同步对等网络( Synchronous Peer-to-Peer, S-P2P )是实际上第一个被广泛接收的方式，并被用于像 iPod 和 PDA 这样的外围设备。S-P2P 实现简单并且本地网络速度快。由于 iTunes 需要传输大量的媒体介质，所以 iTunes 仍然使用这种方式。

![Synchronous Peer-to-Peer](http://img.objccn.io/issue-10/sp2p.png)<br />
*Synchronous Peer-to-Peer (S&ndash;P2P)*

同步客户端服务器( Synchronous Client-Server, S-CS )方式随着网络的发展以及像[亚马逊云服务](http://aws.amazon.com) ( AWS ) 这样的云服务的流行而变得流行起来。S-CS 可能是当今最常用的同步方式。站在实现的立场上，它和开发任何其他的 web 服务非常相似。典型地，一个自定义的云应用程序使用某种语言开发，该全栈式开发框架可能和客户端程序无关，比如 [Ruby on Rails](http://rubyonrails.org), [Django](https://www.djangoproject.com)， [Django](https://www.djangoproject.com)，或者 [Node.js](http://nodejs.org)。与云通讯的速度要比本地网络慢，但是 S-CS 有一个优势叫做“始终在线”，因此，只要网络保持连接，客户端可以在任何位置同步数据。


![Synchronous Client-Server](http://img.objccn.io/issue-10/scs.png)<br />
*Synchronous Client-Server (S&ndash;CS)*

对于异步客户端服务器( Asynchronous Client-Server, A-CS )方式，开发者使用数据存储的 API，存取本地备份的数据。同步数据的过程透明地发生在后台，应用程序代码通过回调机制被告知是否发生变化。采用这种方式的的例子包括 [Dropbox Datastore API](https://www.dropbox.com/developers/datastore)，以及对 Core Data 开发者来说的 [Wasabi Sync](http://www.wasabisync.com) 服务。

异步 _冗余同步_ 方式的一个优点是当网络不可用的时候，应用程序可以继续工作并能够存取用户数据。另一个优点是开发者不用再关注通讯和同步的细节，可以集中精力在应用程序的其他方面，数据存储看上去就好像是在设备本地进行的。

![Asynchronous Client-Server](http://img.objccn.io/issue-10/acs.png)<br />
*Asynchronous Client-Server (A&ndash;CS)*

异步对等方式( Asynchronous Peer-to-Peer, A-P2P )目前尚在初期，并且没有被广泛地使用。A-P2P 将所有的负载分发到客户端程序上，并且不使用直接通讯。开发一个 A-P2P 框架是比较复杂的，并且导致了一些众所周知的问题，包括苹果早期想让 iCloud 支持 Core Data (现在已经支持的很好了)。和 S-CS 一样，每一个设备都有一份数据存储的完整副本。通过交换不同设备之间的文件的变化来实现数据同步，这些文件通常被称为 _事务日志_ 。事务日志被上传到云端，然后从云端通过一个基本的文件处理服务器(比如 iCloud, Dropbox)分发给其他设备，这一过程不需要知道日志的具体内容。

![Asynchronous Peer-to-Peer](http://img.objccn.io/issue-10/ap2p.png)<br />
*Asynchronous Peer-to-Peer (A&ndash;P2P)*

鉴于开发 A-P2P 系统的复杂性，你也许会问为什么我们还要自找麻烦地去开发。A-P2P 框架的一个主要优势是它抽离了对智能服务器的需求。开发者能够不用考虑服务端的开发，并可以利用多种可用的文件传输服务的优势，他们其中的大多数是免费的。而且，由于 A-P2P 系统不连接到一个特定的服务，也就没有了供应商被锁定的危险。

## 数据同步的要素

介绍完了不同种类的数据同步算法，我现在想介绍一下这些算法的常用组件。你可以想一想如何操控一个孤立的应用程序。

所有的同步方法都有一些共同的要素，包括：
* 能够在整个存储中识别出相应的对象
* 确定自上一次同步之后发生了哪些变化 
* 解决由并发变化引起的冲突

在接下来的部分，在继续介绍如何实现这些算法细节之前，我想先介绍这些要素。

### 识别

在只有一个数据存储的独立应用程序中，对象的识别典型地可以使用数据库表的行索引，或者在 Core Data 中与之类似的东西，比如 `NSManagedObjectID`，这些识别的方法只特定地适用于本地存储，并不适合在不同的设备之间识别相应的对象。当应用程序同步的时候，很重要的一点就是在不同存储中的对象能够与其他的对象相互关联，因此需要 _全局标识符_ 。

全局标识符通常就是 [Universally Unique Identifiers (UUIDs)](http://en.wikipedia.org/wiki/Universally_unique_identifier)；不同存储中的对象，如果具有相同全局标识符，则可以认为在逻辑上代表一个单一实例。对一个对象的修改最后会导致相应的对象也会被更新。( UUIDs 可以由 Cocoa 最近添加的 `NSUUID` 类来创建，或者经常被遗忘的 `NSProcessInfo` 类的 `globallyUniqueString` 方法)。

UUIDs 并不是对所有的对象都适用。比如，它就不太适合那些有固定成员集合的类的对象。一个一般的例子是一个单例对象，只有一个可能的对象被允许。另外一个例子是唯一表示是字符串的类标签( tag-like )对象。

但是一个类决定了对象标识，重要的是它能在全局标识符中被反映出来。逻辑上相同的对象在不同的存储中应该具有相同的标识符，并且不相同的对象应该具有不相同的标识符。

### 变化追踪

_变化追踪_ 用来描述同步算法如何确定自上一次同步后，数据发生了哪些变化，然后本地存储应该如何修改。对象的每一次修改(通常成为 _增量_)通常是一个 [CRUD](http://en.wikipedia.org/wiki/Create,_read,_update_and_delete) 操作：创建( creation )，读取( read )，更新( update )，删除( deletion )。

我们面临的第一个选择就是要选择记录粒度的大小。当任何单个属性变化的时候，是应该更新实体里的全部属性呢？还是只记录被修改的属性。正确的选择也许不同；我将会在研究细节的时候更多地讨论这一话题。

在任何一种情况下，你需要一种方法来记录变化。在最简单的情形下，本地存储里可能就是一个 `Boolean` 型属性来标识一个对象是不是新的，或者自上一次更新后有没有被更新。在更高级的算法中，变化被记录在主存储之外，以字典的方式记录被修改的属性并有一个与之相关联的时间戳。

### 冲突解决

当逻辑上相同的数据集有两个或更多的存储时，潜在的 _冲突_ 就可能出现。没有同步的情况下，修改一个存储里某个对象，与修改另一个存储中与之相对应的对象，这两件事可能同时发生。这些改变同时发生，一些行为可能就会留下一些冲突的对象，一旦数据同步，合法的状态就会出现在所有的存储中。

在最简单的世界里，读写存储可以被认为是原子操作，因此解决冲突就可以简单地看成选择什么版本的存储。这也许比你想的要普通的多。比如，iCloud 对文档的同步就是用的这种方式：当发生冲突的时候，将询问用户希望存储哪个版本—这没有合并有冲突的存储之间的变化。

当解决冲突的时候，有很多种方法来决定优先考虑哪些变化。如果你使用了一个中央服务器，那么最直接的方式就是假设最近的一次同步操作级别最高。所有在这一次同步操作中的变化将覆盖之前存储的数据。复杂一点的系统会比较冲突发生的时候的时间戳然后选择最近的一次。

冲突解决可能会比较棘手，如果你已经有了选择，你应该避免设计一个模型仅仅是让他们变得合法。在一个新的项目中，这比思考所有可能出现的的无效状态要容易的多。

关系可能是非常麻烦的(这可不是对人际交往的评价)。拿一个实体 `A` 和实体 `B` 之间简单的一对一的关系举例。假设 `设备1`和 `设备2` 都拥有对象 `A[1]`，和与之相关的对象 `B[1]`。`设备1` 创建了一个对象 `B[2]`，并将 `A[1]` 和`B[2]` 相关联，然后删除 `B[1]`。同时，`设备2` 也删除 `B[1]`，但是创建了 `B[3]`，并将 `B[3]` 和 `A[1]` 关联。

![Orphaned object](http://img.objccn.io/issue-10/orphan.png)<br />
*Orphaned object arising from conflicting changes to a one-to-one relationship.*

同步之后，将会出现一个额外的，孤立的，不和任何对象A相关联的对象B。如果关系需要一个验证规则，那么你就得到了一个无效对象图。而这仅仅是你能想到的最简单的一种关系。当涉及到更复杂的关系时，还可能会出现更多的问题。

但是这样的冲突都解决了，对我们的信息还是有决定性重大帮助的。如果同样的场景发生在两台不同的设备上，就应该使用同样的办法解决。

这看上去可能显而易见，但是很容易出错。还是上面那个例子，如果你的方案是随机的选择对象 `B` 中的一个删除，某种情况下，两个设备会删除不同的对象，那么最后就没有了对象 `B`。你应该在每个设备中尽力删除对应的对象 `B`。这是可以实现的，可以首先对对象排序，然后总是选择相同的对象。

## 对等同步通讯（ S-P2P ）

既然我们已经了解了所有同步算法的基本要素，接下来，就更详细的看一看之前介绍的每一种特定的方式，首先介绍同步( SC )通讯方法。

我们从最简单的可工作的 S-P2P 方案开始。假设我们有一个像 iTunes 那样的 Mac 应用程序，它可以通过 USB、蓝牙或者 Wi-Fi 和 iPhone 进行同步通讯。凭借快速的本地网络，我们不用太在意限制数据传输，所以我们可以在这方面偷点懒。

当 iPhone 第一次同步的时候，两个应用程序通过 Bonjour 发现对方，然后 Mac 应用程序将它的所有存储数据压缩，通过套接字将压缩后的文件传递给 iPhone 应用程序，然后 iPhone 将其解压并安装。

现在假设用户使用 iPhone 对已经存在的对象做了修改(比如，给一首歌打了星级)。该设备上的应用程序给该对象设置了一个 Boolean 型的标记(比如， `changedSinceSync`)，用来表示该对象是新的还是已经被修改过的。

当下一次同步发生的时候，iPhone 应用程序将它的所有数据存储压缩并回发给 Mac。Mac 装载这些数据，寻找被修改的实例，然后更新它自己对应的数据。然后 Mac 又将更新后的数据存储的完整拷贝发送给 iPhone，用来替代 iPhone 已经存在的数据存储，然后整个流程又重新开始。

虽然还有很多变化和改进的可能，但是这的确是一个可行的方案，并且适用于很多应用程序。总结来说，同步操作需要设备能够向其他设备传输数据，并且能够决定哪些被修改、合并，然后回传更新后的数据。你保证了这两个设备同步之后具有相同的数据，所以，有很强的健壮性。

## 客户端-服务器同步通讯（ S-CS ）

当等式中加入了服务器的时候，事情变得微妙起来。服务器是为了能够更加灵活地同步数据，但是它是以数据传输和存储为代价的。我们需要尽可能地减少通讯开销，所以来回地拷贝整个数据是不可行的。

这一次，我还是把重点放在最简单可行的方案上。假设数据存储在服务器上的数据库中，并且每一个对象都有一个最后更新的时间戳。当客户端程序第一次同步的时候，它以序列化(比如 JSON )的形式下载所有的数据，然后建立一个本地存储。它同样也在本地记录了同步的时间戳。

当客户端程序发生改变的时候，它会更新对象的最后更新时间戳。服务器也会做同样的事情，其他设备也应该在这个过渡期里同步。

当下一次同步发生的时候，客户端会决定自上一次同步后，哪些对象做了修改，然后仅把被修改的对象发送给服务器。服务器会合并这些修改。如果服务器对某一个对象的拷贝被另一个客户端做了修改，那么它会以最近的时间戳为准来保存修改。

然后服务器会回传所有比上一次从客户端发来的时间戳新的变化。这需要考虑到合并的问题，删除所有覆盖的变化。

也许有很多不同的方法。比如，你可以为每一个个人属性引入一个时间戳，然后在粒度级去追踪变化。或者你可以在客户端合并所有的数据，然后将合并后的结果发回给服务器，这实际上是互换了角色。但是，基本说来，一个设备发送修改结果给其他设备，然后接收方合并并回发合并后的结果。

删除需要考虑更多。因为一旦你删除了一个对象，你就不可能跟踪它了。一种选择是使用 _软删除_ ，也就是对象并不是被真正的删除，而是标记为删除(比如使用一个 Boolean 属性)。(这和在Finder中删除一个文件类似。只有当你清空的垃圾桶之后，它才被永久地删除。)

## 客户端-服务器异步通讯 ( A-CS )

异步的数据同步框架和服务的吸引力在于它们提供了现成的解决方案。上文提到的同步的数据同步方案是要定制的—也就是说你不得不为每一个应用程序写很多的自定义代码。另外，使用S-CS架构，你不得不在所有的平台间复制类似的功能，来保持服务器的操作。而这需要的技能是大多数 Objective-C 开发者所不具备的。

异步服务(比如， [Dropbox Datastore API](https://www.dropbox.com/developers/datastore) 和 [Wasabi Sync](http://www.wasabisync.com) 通常提供的框架，让应用程序开发者用起来好像是本地数据存储。这些框架在本地保存修改，然后在后台控制与服务器的同步。

A-CS和S-CS的一个最主要的区别在于，A-CS框架额外提供的抽象层，屏蔽了直接参与同步的客户端代码。这也意味着，同一服务可以用于所有的数据模型，而不是特定的一种模型。

## 对等异步通讯（ A-P2P ）

A-P2P 是最没有被充分开发的方式，因为它也是最难实现的。但是它的承诺是伟大的，因为它比 A-CS 在后端更加抽象，使得一个独立的应用程序能够通过不同的服务进行同步。

尽管没有被充分开发，但还是有应用程序已经在使用这种方式。比如，著名的待办事项软件 [Clear](http://realmacsoftware.com/clear) 就自己实现了 A-P2P，通过 iCloud 进行同步，并且有[在线文档](http://blog.helftone.com/clear-in-the-icloud/)。还有一些框架像苹果的Core Data—iCloud integration， [TICoreDataSync](https://github.com/nothirst/TICoreDataSync) 以及 [Core Data Ensembles](https://github.com/drewmccormack/ensembles)均采用这种方式并且逐渐被使用。

作为一个应用程序开发者，你不需要过多关心一个 A-P2P 系统是如何工作的—错综复杂的事物应该尽可能被隐藏起来—但是还是值得在基本层面了解它是如何工作的，以及所涉及的各种挑战。

在最简单的情形下，每一个设备将它的 CRUD 修改保存到事务日志文件中，然后将它们上传到云端。每一个修改都包括一个有序参数，比如一个时间戳，然后当设备从其他设备接收到新的更改时，作为回应，它会建立一个数据存储的本地拷贝。

如果每一个设备一直写事务日志，云端的数据会 _无限制地_ 增长。重定基准技术可以用来压缩旧的变化集然后设置一个新的 _基准线_ 。实际上，由所有旧变化的结束到新对象的产生代表了存储的初始化状态。这减少了历史遗留的冗余的日志。比如，如果删除了一个对象，所有与这个对象相关的修改都被删除了。

## A-P2P 是复杂的

这一段简短的描述也许使 A-P2P 看起来是简单的算法，但是上面的描述隐藏了许多许多复杂的东西。A-P2P 是复杂的，甚至比其他数据同步的形式都要复杂

A-P2P 最大的一个风险是发散( divergence )。由于没有中央服务器，没有不同设备间的直接通讯，随着时间的推移，一个不良的实现很容易导致不一致性。(我敢打赌，作为一个应用程序开发者，你绝对不想处理像[蝴蝶效应](http://en.wikipedia.org/wiki/The_Butterfly_Effect)那样的问题。)

如果你能保证在云端永久存储着全部数据存储的最新副本，A-P2P 也就没那么难了。但是，每一次存储都拷贝数据需要大量的数据传输，所以 A-P2P 的应用程序需要以块为单位接收数据，而且它们也不能及时的知道其他数据和设备。修改甚至会不按顺序到达，或者期望从其他设备发来的修改还没有来到。你可以从字面上期望看到还没有被创建的对象发生的改变。

不仅仅是变化可能无序到达，甚至决定顺序应该是怎样的都是有挑战性的。时间戳通常是不可信的，特别是在 iPhone 这样的客户端上。如果你不小心，接受了一个将来时间的时间戳，这可能会使你不能添加新的改变。使用更健壮的方式使事件及时按序到达是可行的(比如，[Lamport Timestamps](http://en.wikipedia.org/wiki/Lamport_timestamps) 和 [Vector Clocks](http://en.wikipedia.org/wiki/Vector_clock))，但是还是有代价的：那就只能近似的使事件及时按序地到达。

类似这样的细节还有很多，他们都给 A-P2P 的实现带来了挑战。但是那不意味着我们不要应该尝试。回报—后端未知的同步存储—是有价值的目标，而且能够降低在应用程序中实现同步的困难。

## 一个已解决的问题？

我经常听到人们说同步是一个已经解决了的问题。我多么希望事实如听上去那样简单，因为那样每一个应用程序都会支持同步。事实上，只有很少的应用程序支持同步。更准确来说，同步的方案不易被接纳，代价高，或者在某些方面受限。

我们已经知道数据同步算法有很多不同的形式，而且确实没有普适的方法。你使用的方案取决于你的应用程序的需要，你的资源，以及你的编程水平。

你的应用是否需要处理大量的媒体数据？除非你有大量的启动资金，否则你最好在本地网络使用好用的老式的 S-P2P，就像 iTunes 那样。

想让单个数据模型扩展到社交网络或者实现跨平台？自定义 Web 服务的 S-CS 也许是一个选择。

正在开发一个新的应用程序，重点是要无论在任何地方都能够同步，但是你又不想花费太多的时间在这方面？那么就使用像 [Dropbox Datastore API](http://www.dropbox.com/developers/datastore) 这样的 A-CS 方案吧。

又或者你已经有了一个基于 Core Data 的应用程序，不想和服务器混在一起，而且又不想被某个供应商锁起来？那么像 [Ensembles](https://github.com/drewmccormack/ensembles) 这样的 A-P2P 方案就是你最好的选择。(好吧，我承认，我是Ensembles项目的创立者和主要程序员。)

总之，做选择的时候，要明智一点儿。:)

---

[话题 #10 下的更多文章](http://objccn.io/issue-10)

原文 [Data Synchronization](http://www.objc.io/issue-10/data-synchronization.html)