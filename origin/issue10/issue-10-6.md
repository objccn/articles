[Source](http://www.objc.io/issue-10/ip-tcp-http.html "Permalink to IP, TCP, and HTTP - Syncing Data - objc.io issue #10 ")

# IP, TCP, and HTTP - Syncing Data - objc.io issue #10 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# IP, TCP, and HTTP

[Issue #10 Syncing Data][4], March 2014

By [Daniel Eggert][5]

When an app communicates with a server, more often than not, that communication happens over HTTP. HTTP was developed for web browsers: when you enter http://www.objc.io into your browser, the browser talks to the server named www.objc.io using HTTP.

HTTP is an application protocol running at the application layer. There are several protocols layered on top of each other. The stack of layers is often depicted like this:


    Application Layer -- e.g. HTTP
    ----
    Transport Layer -- e.g. TCP
    ----
    Internet Layer -- e.g. IP
    ----
    Link Layer -- e.g. IEEE 802.2

The so-called [OSI (Open Systems Interconnection) model][6] defines seven layers. We’ll take a look at the application, transport, and Internet layers for the typical HTTP usage: HTTP, TCP, and IP. The layers below IP are the data link and physical layers. These are the layers that, e.g. implement Ethernet (Ethernet has a data link part and a physical part).

We will only look at the application, transport, and Internet layers, and in fact only look at one particular combination: HTTP running on top of TCP, which in turn runs on top of IP. This is the typical setup most of us use for our apps, day in and day out.

We hope that this will give you a more detailed understanding of how HTTP works under the hood, as well as what some common problems are, and how you can avoid them.

There are ways to send data through the Internet other than HTTP. One reason that HTTP has become so popular is that it will almost always work, even when the machine is behind a firewall.

Let’s start out at the lowest layer and take a look at IP, the Internet Protocol.

## IP — Internet Protocol

The **IP** in TCP/IP is short for [Internet Protocol][7]. As the name suggests, it is one of the fundamental protocols of the Internet.

IP implements [packet-switched networking][8]. It has a concept of _hosts_, which are machines. The IP protocol specifies how _datagrams_ (packets) are sent between these hosts.

A packet is a chunk of binary data that has a source host and a destination host. An IP network will then simply transmit the packet from the source to the destination. One important aspect of IP is that packets are delivered using _best effort_. A packet may be lost along the way and never reach the destination. Or it may get duplicated and arrive multiple times at the destination.

Each host in an IP network has an address – the so-called _IP address_. Each packet contains the source and destination hosts’ addresses. The IP is responsible for routing datagrams – as the IP packet travels through the network, each node (host) that it travels through looks at the destination address in the packet to figure out in which direction the packet should be forwarded.

Today, most packages are still IPv4 (Internet Protocol version 4), where each IPv4 address is 32 bits long. They’re most often written in [dotted-decimal][9] notation, like so: 198.51.100.42

The newer IPv6 standard is slowly gaining traction. It has a larger address space: its addresses are 128 bits long. This allows for easier routing as the packets travel through the network. And since there are more available addresses, tricks such as [network address translation][10] are no longer necessary. IPv6 addresses are represented in the hexadecimal system and divided into eight groups separated by colons, e.g. `2001:0db8:85a3:0042:1000:8a2e:0370:7334`.

### The IP Header

An IP packet consists of a header and a payload.

The payload contains the actual data to be transmitted, while the header is metadata.

#### IPv4 Header

An IPv4 header looks like this:


    IPv4 Header Format
    Offsets  Octet    0                       1                       2                       3
    Octet    Bit      0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31|
     0         0     |Version    |IHL        |DSCP            |ECN  |Total Length                                   |
     4        32     |Identification                                |Flags   |Fragment Offset                       |
     8        64     |Time To Live           |Protocol              |Header Checksum                                |
    12        96     |Source IP Address                                                                             |
    16       128     |Destination IP Address                                                                        |
    20       160     |Options (if IHL > 5)                                                                          |

The header is 20 bytes long (without options, which are rarely used).

The most interesting parts of the header are the source and destination IP addresses. Aside from that, the version field will be set to 4 – it’s IPv4. And the _protocol_ field specifies which protocol the payload is using. TCP’s protocol number is 6. The total length field specified is the length of the entire packet – header plus payload.

Check Wikipedia’s [article on IPv4][11] for all the details about the header and its fields.

#### IPv6 Header

IPv6 uses addresses that are 128 bits long. The IPv6 header looks like this:


    Offsets  Octet    0                       1                       2                       3
    Octet    Bit      0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31|
     0         0     |Version    |Traffic Class         |Flow Label                                                 |
     4        32     |Payload Length                                |Next Header            |Hop Limit              |
     8        64     |Source Address                                                                                |
    12        96     |                                                                                              |
    16       128     |                                                                                              |
    20       160     |                                                                                              |
    24       192     |Destination Address                                                                           |
    28       224     |                                                                                              |
    32       256     |                                                                                              |
    36       288     |                                                                                              |

The IPv6 header has a fixed length of 40 bytes. It’s a lot simpler than IPv4 – a few lessons were learned in the years that have passed since IPv4.

The source and destination addresses are again the most interesting fields. In IPv6, the _next header_ field specifies what data follows the header. IPv6 allows chaining of headers inside the packet. Each subsequent IPv6 header will also have a _next header_ field until the actual payload is reached. When the _next header_ field, for example, is 6 (TCP’s protocol number), the rest of the packet will be TCP data.

Again: Wikipedia’s [article on IPv6 packets][12] has a lot more detail.

### Fragmentation

In IPv4, packets (datagrams) can get [fragmented][13]. The underlying transport layer will have an upper limit to the length of packet it can support. In IPv4, a router may fragment a packet if it gets routed onto an underlying data link for which the packet would otherwise be too big. These packets will then get reassembled at the destination host. The sender can decide to disallow routers to fragment packets, in which case they’ll send a _Packet Too Big_ [ICMP][14] back to the sender.

In IPv6, a router will always drop the packet and send back a _Packet Too Big_ [ICMP6][15] message to the sender. The end points use this to do a [path MTU discovery][16] to figure out what the optimal so-called _maximum transfer unit_ (MTU) along the path between the two hosts is. Only when the upper layer has a minimum payload size that is too big for this MTU will IPv6 use [fragmentation][17]. With TCP over IPv6, this is not the case.

## TCP — Transmission Control Protocol

One of the most common protocols to run on top of IP is, by far, TCP. It’s so common that the entire suite of protocols is often referred to as TCP/IP.

The IP protocol allows for sending single packets (datagrams) between two hosts. Packets are delivered _best effort_ and may: reach the destination in a different order than the one in which they were sent, reach the destination multiple times, or never reach the destination at all.

TCP is built on top of IP. The Transmission Control Protocol provides reliable, ordered, error-checked delivery of a stream of data between programs. With TCP, an application running on one device can send data to an application on another device and be sure that the data arrives there in the same way that it was sent. This may seem trivial, but it’s really a stark contrast to how the raw IP layer works.

With TCP, applications establish connections between each other. A TCP connection is duplex and allows data to flow in both directions. The applications on either end do not have to worry about the data being split up into packets, or the fact that the packet transport is _best effort_. TCP guarantees that the data will arrive at the other end in pristine condition.

A typical use case of TCP is HTTP. Our web browser (application 1) connects to a web server (application 2). Once the connection is made, the browser can send a request through the connection, and the web server can send a response back through the same connection.

Multiple applications on the same host can use TCP simultaneously. To uniquely identify an application, TCP has a concept of _ports_. A connection between two applications has a source IP address and a source port on one end, and a destination IP address and a destination port at the other end. This pair of addresses, plus a port for either end, uniquely identifies the connection.

A web server using HTTPS will _listen_ on port 443. The browser will use a so-called _ephemeral port_ as the source port and then use TCP to establish a connection between the two address-port pairs.

TCP runs unmodified on top of both IPv4 and IPv6. The _Protocol_ (IPv4) or _Next Header_ (IPv6) field will be set to 6, which is the protocol number for TCP.

### TCP Segments

The data stream that flows between hosts is cut up into chunks, which are turned into TCP segments. The TCP segment then becomes the payload of an IP packet.

Each TCP segment has a header and a payload. The payload is the actual data chunk to be transmitted. The TCP segment header first and foremost contains the source and destination port number – the source and destination addresses are already present in the IP header.

The header also contains sequence and acknowledgement numbers and quite a few other fields which are all used by TCP to manage the connection.

We’ll go into more detail about sequence number in a bit. It’s basically a mechanism to give each segment a unique number. The first segment has a random number, e.g. 1721092979, and subsequent segments increase this number by 1: 1721092980, 1721092981, and so on. The acknowledgement numbers allow the other end to communicate back to the sender regarding which segments it has received so far. Since TCP is duplex, this happens in both directions.

### TCP Connections

Connection management is a central component of TCP. The protocol needs to pull a lot of tricks to hide the complexities of the unreliable IP layer. We’ll take a quick look at connection setup, the actual data flow, and connection termination.

The state transitions that a connection can go through are quite complex (c.f. [TCP state diagram][18]). But in most cases, things are relatively simple.

#### Connection Setup

In TCP, a connection is always established from one host to another. Hence, there are two different roles in connection setup: one end (e.g. the web server) is listening for connections, while the other end (e.g. our app) connects to the listening application (e.g. the web server). The server performs a so-called _passive open_ – it starts listening. The client performs a so-called _active open_ toward the server.

Connection setup happens through a three-way handshake. It works like this:

  1. The client sends a **SYN** to the server with a random sequence number, `A`
  2. The server replies with a **SYN-ACK** with an acknowledgment number of `A%2B1` and a random sequence number, `B`
  3. The client sends an **ACK** to the server with an acknowledgement number of `B%2B1` and a sequence number of `A%2B1`

**SYN** is short for _synchronize sequence numbers_. Once data flows between both ends, each TCP segment has a sequence number. This is how TCP makes sure that all parts arrive at the other end, and that they’re put together in the right order. Before communication can start, both ends need to synchronize the sequence number of the first segments.

**ACK** is short for _acknowledgment_. When a segment arrives at one of the ends, that end will acknowledge the receipt of that segment by sending an acknowledgment for the sequence number of the received segment.

If we run´:


    curl -4 http://www.apple.com/contact/

this will cause `curl` to create a TCP connection to www.apple.com on port 80.

The server www.apple.com / 23.63.125.15 is listening on port 80. Our own address in the output is `10.0.1.6`, and our _ephemeral port_ is `52181` (this is a random, available port). The output from `tcpdump(1)` for the three-way handshake looks like this:


    % sudo tcpdump -c 3 -i en3 -nS host 23.63.125.15
    18:31:29.140787 IP 10.0.1.6.52181 > 23.63.125.15.80: Flags [S], seq 1721092979, win 65535, options [mss 1460,nop,wscale 4,nop,nop,TS val 743929763 ecr 0,sackOK,eol], length 0
    18:31:29.150866 IP 23.63.125.15.80 > 10.0.1.6.52181: Flags [S.], seq 673593777, ack 1721092980, win 14480, options [mss 1460,sackOK,TS val 1433256622 ecr 743929763,nop,wscale 1], length 0
    18:31:29.150908 IP 10.0.1.6.52181 > 23.63.125.15.80: Flags [.], ack 673593778, win 8235, options [nop,nop,TS val 743929773 ecr 1433256622], length 0

That’s a lot of information right there. Let’s step through this bit by bit.

On the very left-hand side we see the system time. This was run in the evening at 18:31. Next, `IP` tells us that these are IP packets.

Next we see `10.0.1.6.52181 > 23.63.125.15.80`. This is the source and destination address-port pair. The first and third lines are from the client to the server, the second from the server to the client. `tcpdump` will simply append the port number to the IP address. `10.0.1.6.52181` means IP address 10.0.1.6, port 52181.

The `Flags` are flags in the TCP segment header: `S` for **SYN**, `.` for **ACK**, `P` for **PUSH**, and `F` for **FIN**. There are a few more we won’t see here. Note how these three lines have **SYN**, then **SYN-ACK**, then **ACK**: this is the three-way handshake.

The first line shows the client sending the random sequence number 1721092979 (A) to the server. The second line shows the server sending an acknowledgement for 1721092980 (A%2B1) and its random sequence number 673593777 (B). Finally, the third line shows the client acknowledging 673593778 (B%2B1).

#### Options

Another thing that happens during connection setup is for both ends to exchange additional options. In the first line, we see the client sending:


    [mss 1460,nop,wscale 4,nop,nop,TS val 743929763 ecr 0,sackOK,eol]

and on the second line, the server is sending:


    [mss 1460,sackOK,TS val 1433256622 ecr 743929763,nop,wscale 1]

The `TS val` / `ecr` are used by TCP to estimate the round-trip time (RTT). The `TS val` part is the _time stamp_ of the sender, and the (`ecr`) is the timestamp _echo reply_, which is (generally) the last timestamp that the sender has received. TCP uses the round-trip time for its congestion-control algorithms.

Both ends are sending `sackOK`. This will enable _Selective Acknowledgement_. It allows both ends to acknowledge receipt of byte ranges. Normally, the acknowledgement mechanism only allows acknowledging that the receiver has all data up to a specific byte count. SACK is outlined in [section 3 of RFC 2018][19].

The `mss` option specified the _Maximum Segment Size_, which is the maximum number of bytes that this end is willing to receive in a single segment. `wscale` is the _window scale factor_ that we’ll talk about in a bit.

#### Connection Data Flow

When the connection is created, both ends can send data to the other end. Each segment that is sent has a sequence number corresponding to the number of bytes sent so far. The receiving end will acknowledge packets as they are received by sending back segments with the corresponding **ACK** in the header.

If we were transmitting 10 bytes per segment and 5 bytes in the last segment, this may looks like:


    host A sends segment with seq 10
    host A sends segment with seq 20
    host A sends segment with seq 30    host B sends segment with ack 10
    host A sends segment with seq 35    host B sends segment with ack 20
                                        host B sends segment with ack 30
                                        host B sends segment with ack 35

This mechanism happens in both directions. Host A will keep sending packets. As they arrive at host B, host B will send acknowledgements for these packets back to host A. But host A will keep sending packets without waiting for host B to acknowledge them.

TCP incorporates flow control and a lot of sophisticated mechanisms for congestion control. These are all about figuring out (A) if segments got lost and need to be retransmitted, and (B) if the rate at which segments are sent needs to be adjusted.

Flow control is about making sure that the sending side doesn’t send data faster than the receiver (at either end) can process it. The receiver sends a so-called _receive window_, which tells the sender how much more data the receiver can buffer. There are some subtle details we’ll skip, but in the above `tcpdump` output, we see a `win 65535` and a `wscale 4`. The first is the window size, the latter a scale factor. As a result, the host at `10.0.1.6` says it has a receive window of 4·64 kB = 256 kB and the host at `23.63.125.15` advertises `win 14480` and `wscale 1`, i.e. roughly 14 kB. As either side receives data, it will send an updated receive window to the other end.

Congestion control is quite complex. The various mechanisms are all about figuring out at which rate data can be sent through the network. It’s a very delicate balance. On one hand, there’s the obvious desire to send data as fast as possible, but on the other hand, the performance will collapse dramatically when sending too much data. This is called [congestive collapse][20] and it’s a property inherent to packet-switched networks. When too many packets are sent, packets will collide with other packets and the packet loss rate will climb dramatically.

The congestion control mechanisms need to also make sure that they play well with other flows. Today’s congestion control mechanisms in TCP are outlined in detail in about 6,000 words in [RFC 5681][21]. The basic idea is that the sender side looks at the acknowledgments it gets back. This is a very tricky business and there are various tradeoffs to be made. Remember that the underlying IP packets can arrive out of order, not at all, or twice. The sender needs to estimate what the round-trip time is and use that to figure out if it should have received an acknowledgement already. Retransmitting packets is obviously costly, but not retransmitting causes the connection to stall for a while, and the load on the network is likely to be very dynamic. The TCP algorithms need to constantly adapt to the current situation.

The important thing to note is that a TCP connection is a very lively and flexible thing. Aside from the actual data flow, both ends constantly send hints and updates back and forth to continuously fine-tune the connection.

Because of this tuning, TCP connections that are short-lived can be very inefficient. When a connection is first created, the TCP algorithms still don’t know what the conditions of the network are. And toward the end of the connection lifetime, there’s less information flowing back to the sender, which therefore has a harder time estimating how things are moving along.

Above, we saw the first three segments between the client and the server. If we look at the remainder of the connection, it looks like this:


    18:31:29.150955 IP 10.0.1.6.52181 > 23.63.125.15.80: Flags [P.], seq 1721092980:1721093065, ack 673593778, win 8235, options [nop,nop,TS val 743929773 ecr 1433256622], length 85
    18:31:29.161213 IP 23.63.125.15.80 > 10.0.1.6.52181: Flags [.], ack 1721093065, win 7240, options [nop,nop,TS val 1433256633 ecr 743929773], length 0

The client at `10.0.1.6` sends the first segment with data `length 85` (the HTTP request, 85 bytes). The **ACK** number is left at the same value, because no data has been received from the other end since the last segment.

The server at `23.63.125.15` then acknowledges the receipt of that data (but doesn’t send any data): `length 0`. Since the connection is using _Selective acknowledgments_, the sequence number and acknowledgment numbers are byte ranges: 1721092980 to 1721093065 is 85 bytes. When the other end sends `ack 1721093065`, that means: I have everything up to byte 1721093065. The reason for these numbers being so large is because we’re starting out at a random number. The byte ranges are relative to that initial number.

This pattern continues until all data has been sent:


    18:31:29.189335 IP 23.63.125.15.80 > 10.0.1.6.52181: Flags [.], seq 673593778:673595226, ack 1721093065, win 7240, options [nop,nop,TS val 1433256660 ecr 743929773], length 1448
    18:31:29.190280 IP 23.63.125.15.80 > 10.0.1.6.52181: Flags [.], seq 673595226:673596674, ack 1721093065, win 7240, options [nop,nop,TS val 1433256660 ecr 743929773], length 1448
    18:31:29.190350 IP 10.0.1.6.52181 > 23.63.125.15.80: Flags [.], ack 673596674, win 8101, options [nop,nop,TS val 743929811 ecr 1433256660], length 0
    18:31:29.190597 IP 23.63.125.15.80 > 10.0.1.6.52181: Flags [.], seq 673596674:673598122, ack 1721093065, win 7240, options [nop,nop,TS val 1433256660 ecr 743929773], length 1448
    18:31:29.190601 IP 23.63.125.15.80 > 10.0.1.6.52181: Flags [.], seq 673598122:673599570, ack 1721093065, win 7240, options [nop,nop,TS val 1433256660 ecr 743929773], length 1448
    18:31:29.190614 IP 23.63.125.15.80 > 10.0.1.6.52181: Flags [.], seq 673599570:673601018, ack 1721093065, win 7240, options [nop,nop,TS val 1433256660 ecr 743929773], length 1448
    18:31:29.190616 IP 23.63.125.15.80 > 10.0.1.6.52181: Flags [.], seq 673601018:673602466, ack 1721093065, win 7240, options [nop,nop,TS val 1433256660 ecr 743929773], length 1448
    18:31:29.190617 IP 23.63.125.15.80 > 10.0.1.6.52181: Flags [.], seq 673602466:673603914, ack 1721093065, win 7240, options [nop,nop,TS val 1433256660 ecr 743929773], length 1448
    18:31:29.190619 IP 23.63.125.15.80 > 10.0.1.6.52181: Flags [.], seq 673603914:673605362, ack 1721093065, win 7240, options [nop,nop,TS val 1433256660 ecr 743929773], length 1448
    18:31:29.190621 IP 23.63.125.15.80 > 10.0.1.6.52181: Flags [.], seq 673605362:673606810, ack 1721093065, win 7240, options [nop,nop,TS val 1433256660 ecr 743929773], length 1448
    18:31:29.190679 IP 10.0.1.6.52181 > 23.63.125.15.80: Flags [.], ack 673599570, win 8011, options [nop,nop,TS val 743929812 ecr 1433256660], length 0
    18:31:29.190683 IP 10.0.1.6.52181 > 23.63.125.15.80: Flags [.], ack 673602466, win 7830, options [nop,nop,TS val 743929812 ecr 1433256660], length 0
    18:31:29.190688 IP 10.0.1.6.52181 > 23.63.125.15.80: Flags [.], ack 673605362, win 7830, options [nop,nop,TS val 743929812 ecr 1433256660], length 0
    18:31:29.190703 IP 10.0.1.6.52181 > 23.63.125.15.80: Flags [.], ack 673605362, win 8192, options [nop,nop,TS val 743929812 ecr 1433256660], length 0
    18:31:29.190743 IP 10.0.1.6.52181 > 23.63.125.15.80: Flags [.], ack 673606810, win 8192, options [nop,nop,TS val 743929812 ecr 1433256660], length 0
    18:31:29.190870 IP 23.63.125.15.80 > 10.0.1.6.52181: Flags [.], seq 673606810:673608258, ack 1721093065, win 7240, options [nop,nop,TS val 1433256660 ecr 743929773], length 1448
    18:31:29.198582 IP 23.63.125.15.80 > 10.0.1.6.52181: Flags [P.], seq 673608258:673608401, ack 1721093065, win 7240, options [nop,nop,TS val 1433256670 ecr 743929811], length 143
    18:31:29.198672 IP 10.0.1.6.52181 > 23.63.125.15.80: Flags [.], ack 673608401, win 8183, options [nop,nop,TS val 743929819 ecr 1433256660], length 0

#### Connection Termination

Finally the connection is torn down (or terminated). Each end will send a **FIN** flag to the other end to tell it that it’s done sending. This **FIN** is then acknowledged. When both ends have sent their **FIN** flags and they have been acknowledged, the connection is fully closed:


    18:31:29.199029 IP 10.0.1.6.52181 > 23.63.125.15.80: Flags [F.], seq 1721093065, ack 673608401, win 8192, options [nop,nop,TS val 743929819 ecr 1433256660], length 0
    18:31:29.208416 IP 23.63.125.15.80 > 10.0.1.6.52181: Flags [F.], seq 673608401, ack 1721093066, win 7240, options [nop,nop,TS val 1433256680 ecr 743929819], length 0
    18:31:29.208493 IP 10.0.1.6.52181 > 23.63.125.15.80: Flags [.], ack 673608402, win 8192, options [nop,nop,TS val 743929828 ecr 1433256680], length 0

Note how on the second line, `23.63.125.15` sends its **FIN**, and at the same time acknowledges the other end’s **FIN** with an **ACK** (dot), all in a single segment.

## HTTP — Hypertext Transfer Protocol

The [World Wide Web][22] of interlinked hypertext documents and a browser to browse this web started as an idea set forward in 1989 at [CERN][23]. The protocol to be used for data communication was the _Hypertext Transfer Protocol_, or HTTP. Today’s version is _HTTP/1.1_, which is defined in [RFC 2616][24].

### Request and Response

HTTP uses a simple request and response mechanism. When we enter http://www.apple.com/ into Safari, it sends an HTTP request to the server at `www.apple.com`. The server in turn sends back a (single) response which contains the document that was requested.

There’s always a single request and a single response. And both requests and responses follow the same format. The first line is the _request line_ (request) or _status line_ (response). This line is followed by headers. The headers end with an empty line. After that, an empty line follows the optional message body.

### A Simple Request

When [Safari][25] loads the HTML for http://www.objc.io/about.html, it sends an HTTP request to `www.objc.io` with the following content:


    GET /about.html HTTP/1.1
    Host: www.objc.io
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    If-None-Match: "a54907f38b306fe3ae4f32c003ddd507"
    Accept: text/html,application/xhtml%2Bxml,application/xml;q=0.9,*/*;q=0.8
    If-Modified-Since: Mon, 10 Feb 2014 18:08:48 GMT
    User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.74.9 (KHTML, like Gecko) Version/7.0.2 Safari/537.74.9
    Referer: http://www.objc.io/
    DNT: 1
    Accept-Language: en-us

The first line is the **request line**. It has three parts: the action, the resource, and the HTTP version.

In our example, the action is `GET`. The action is also often referred to as the [HTTP method][26]. The resources specify which resource the given action should be applied to. In our case it is `/about.html`, which tells the server that we want to _get_ the document at `/about.html`. The HTTP version will be `HTTP/1.1`.

Next, we have 10 lines with 10 HTTP headers. These are followed by an empty line. There’s no message body in this request.

The headers have very varying purposes. They convey additional information to the web server. Wikipedia has a nice list of [common HTTP header fields][27]. The first `Host: www.objc.io` header tells the server what server name the request is meant for. This mandatory request header allows the same physical server to serve multiple [domain names][28].

Let’s look at a few common ones:


    Accept: text/html,application/xhtml%2Bxml,application/xml;q=0.9,*/*;q=0.8
    Accept-Language: en-us

This tells the server what media type Safari would like to receive. A server may be able to send a response in various formats. The `text/html` strings are [Internet media types][29], sometimes also known as MIME types or Content-types. The `q=0.9` allows Safari to convey a quality factor which it associates with the given media types. `Accept-Language` tells the server which languages Safari would prefer. Again, this lets the server pick the matching languages, if available.


    Accept-Encoding: gzip, deflate

With this header, Safari tells the server that the response body can be sent compressed. If this header is not set, the server must send the data uncompressed. Particularly for text (such as HTML), compression rates can dramatically reduce the amount of data that has to be sent.


    If-Modified-Since: Mon, 10 Feb 2014 18:08:48 GMT
    If-None-Match: "a54907f38b306fe3ae4f32c003ddd507"

These two are due to the fact that Safari already has the resulting document in its cache. Safari tells the server only to send it if it has either changed since February 10, or if its so-called ETag doesn’t match `a54907f38b306fe3ae4f32c003ddd507`.

The `User-Agent` header tells the server what kind of client is making the request.

### A Simple Response

In response to the above, the server responds with:


    HTTP/1.1 304 Not Modified
    Connection: keep-alive
    Date: Mon, 03 Mar 2014 21:09:45 GMT
    Cache-Control: max-age=3600
    ETag: "a54907f38b306fe3ae4f32c003ddd507"
    Last-Modified: Mon, 10 Feb 2014 18:08:48 GMT
    Age: 6
    X-Cache: Hit from cloudfront
    Via: 1.1 eb67cb25620df959ba21a943fbc49ef6.cloudfront.net (CloudFront)
    X-Amz-Cf-Id: dDSBgR86EKBemW6el-pBI9kAnuYJEaPQYEqGmBnilD12CbixCuZYVQ==

The first line is the so-called _status line_. It contains the HTTP version, followed by a [status code][30] (304) and a status message.

HTTP defines a [list of status codes][31] and their meanings. In this case, we’re receiving **304**, which means that the resource we requested hasn’t been modified.

The response doesn’t contain any body message. It simply tells the receiver: _Your version is up to date._

### Caching Turned Off

Let’s do another request with `curl`:


    % curl http://www.apple.com/hotnews/ > /dev/null

`curl` doesn’t use a local cache. The entire request will now look like this:


    GET /hotnews/ HTTP/1.1
    User-Agent: curl/7.30.0
    Host: www.apple.com
    Accept: */*

This is quite similar to what Safari was requesting. This time, there’s no `If-None-Match` header, and the server will have to send the document.

Note how `curl` announces that it will accept any kind of media format: (`Accept: */*`).

The response from www.apple.com looks like this:


    HTTP/1.1 200 OK
    Server: Apache
    Content-Type: text/html; charset=UTF-8
    Cache-Control: max-age=424
    Expires: Mon, 03 Mar 2014 21:57:55 GMT
    Date: Mon, 03 Mar 2014 21:50:51 GMT
    Content-Length: 12342
    Connection: keep-alive

    
    
    
        

and continues on for quite a while. It now has a response body which contains the HTML document.

The response from Apple’s server contains a [status code][30] of _200_, which is the standard response for successful HTTP requests.

Apple’s server also tells us that the response’s media type is `text/html; charset=UTF-8`. The `Content-Length: 12342` tells us what the length of the message body is.

## HTTPS — HTTP Secure

[Transport Layer Security][32] is a cryptographic protocol that runs on top of TCP. It allows for two things: both ends can verify the identity of the other end, and the data sent between both ends is encrypted. Using HTTP on top of TLS gives you HTTP Secure, or simply, HTTPS.

Simply using HTTPS instead of HTTP will give you a huge improvement in security. There are some additional steps that you may want to take, though, both of which will additionally improve the security of your communication.

### TLS 1.2

You should set the `TLSMinimumSupportedProtocol` to `kTLSProtocol12` to require [TLS version 1.2][33] if your server supports that. This will make [man-in-the-middle attacks][34] more difficult.

### Certificate Pinning

There’s little point in the data we send being encrypted if we can’t be certain that the other end we’re talking to is actually who we think it is. The server’s certificate tells us who the server is. Only allowing a connection to a very specific certificate is called [certificate pinning][35].

When a client makes a connection over TLS to a server, the operating system will decide if it thinks the server’s certificate is valid. There are a few ways this can be circumvented, most notably by installing certificates onto the iOS device and marking them as trusted. Once that’s been done, it’s trivial to perform a [man-in-the-middle attack][34] against your app.

To prevent this from happening (or at least make it extremely difficult), we can use a method called certificate pinning. When then TLS connection is set up, we inspect the server’s certificate and check not only that it’s to be considered valid, but also that it is the certificate that we expect our server to have. This only works if we’re connecting to our own server and hence can coordinate an update to the server’s certificate with an update to the app.

To do this, we need to inspect the so-called _server trust_ during connection. When an `NSURLSession` creates a connection, the delegate receives a `-URLSession:didReceiveChallenge:completionHandler:` call. The passed `NSURLAuthenticationChallenge` has a `protectionSpace` property, which is an instance of `NSURLProtectionSpace`. This, in turn, has a `serverTrust` property.

The `serverTrust` is a `SecTrustRef` object. The Security framework has various methods to query the `SecTrustRef` object. The [`AFSecurityPolicy`][36] from the AFNetworking project is a good starting point. As always, when you build your own security-related code, have someone review it carefully. You don’t want to have a [`goto fail;`][37] bug in this part of your code.

## Putting the Pieces Together

Now that we know a bit about how all the pieces (IP, TCP, and HTTP) work, there are a few things we can do and be aware of.

### Efficiently Using Connections

There are two aspects of a TCP connection that are problematic: the initial setup, and the last few segments that are pushed across the connection.

#### Setup

The connection setup can be very time consuming. As mentioned above, TCP needs to do a three-way handshake. There’s not a lot of data that needs to be sent back and forth. But, particularly when on a mobile network, the time a packet takes to travel from one host (a user’s iPhone) to another host (a web server) can easily be around 250 ms – a quarter of a second. For a three-way handshake, we’ll often spend 750 ms just to establish the connection, before any payload data has been sent.

In the case of HTTPS, things are even more dramatic. With HTTPS we have HTTP running on top of TLS, which in turn runs on top of TCP. The TCP connection will still do its three-way handshake. Next up, the TLS layer does another three-way handshake. Roughly speaking, an HTTPS connection will thus take twice as long as a normal HTTP connection before sending any data . If the round-trip time is 500 ms (250 ms end-to-end), that adds up to 1.5 seconds.

This setup time is costly, regardless of if the connection will transfer a lot or just a small amount of data.

Another aspect of TCP affects connections on which we expect to transfer a larger amount of data. When sending segments into a network with unknown conditions, TCP needs to probe the network to determine the available capacity. In other words: it takes TCP a while to figure out how fast it can send data over the network. Only once it has figured this out can it send the data at the optimal speed. The algorithm that is used for this is called [slow-start][38]. On a side note, it’s worth pointing out that the slow-start algorithm doesn’t perform well on networks with poor data link layer transmission quality, as is often the case for wireless networks.

#### Tear Down

Another problem arises toward the end of the data transfer. When we do an HTTP request for a resource, the server will keep sending TCP segments to our host, and the host will respond with **ACK** messages as it receives the data. If a single packet is lost along the way, the server will not receive an **ACK** for that packet. It can therefore notice that the packet was lost and do what’s called a [fast retransmit][39].

When a packet is lost, the following packet will cause the receiver to send an **ACK** identical to the last **ACK** it sent. The receiver will hence receive a _duplicate ACK_. There are several network conditions that can cause a duplicate ACK even without packet loss. The sender therefore only performs a fast retransmit when it receives three duplicate ACKs.

The problem with this is at the end of the data transmission. When the sender stops sending segments, the receiver stops sending ACKs back. And there’s no way for the fast-retransmit algorithm to detect if a packet is lost within the last four segments being sent. On a typical network, that’s equivalent to 5.7 kB of data. Within the last 5.7 kB, the fast retransmit can’t do its job. If a packet is lost, TCP has to fall back to a more patient algorithm to detect packet loss. It’s not uncommon for a retransmit to take several seconds in such a case.

#### Keep-Alive and Pipelining

HTTP has two strategies to counter these problems. The simplest is called [HTTP persistent connection][40], sometimes also known as _keep-alive_. HTTP will simply reuse the same TCP connection once a single request-response pair is done. In the case of HTTPS, the same TLS connection will be reused:


    open connection
    client sends HTTP request 1 ->
                                
                                
                                
    client sends HTTP request 2 ->
    client sends HTTP request 3 ->
    client sends HTTP request 4 ->
                                