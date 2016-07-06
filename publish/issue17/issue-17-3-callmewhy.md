## 关于收据

收据 (Receipts) 是在 OS X 10.6.6 更新后，和 Mac App Store 一起出现的。 iOS 在内购的时候总是需要向服务器提供收据，而在 iOS 7 之后， iOS 和 OS X 的收据格式开始统一。

一个收据意味着一次可信任的购买记录，每次应用内的购买都会得到一个收据，就像是去超市购物后会拿到一张纸质的收据一样。

关于收据，有以下几个关键的概念：

- 收据是苹果公司通过 App Store 创建和签名的。
- 收据是针对某个指定版本的应用和某个指定的设备发放的。
- 收据存储在本地设备中。
- 每次的安装和更新操作都会发放新的收据。

    

- 安装应用之后，将会发放与应用和设备匹配的收据。
- 更新应用之后，将会发放与最新版本相匹配的收据。

    

- 下列的任何一项交易都会发放收据：
    - 当你通过内购付款购买的时候，将会发放收据用来验证购买记录。
    - 当你恢复以前的交易记录时，将会发放用来验证购买记录的收据。


## 关于验证

验证收据是保障收入的重要途径，同时也可以加强应用的业务模式。

你可能会感觉到很困惑，为什么苹果不提供简单点的 API 来验证收据。为了便于理解这个问题，我们不妨假设存在这样一个方法 (比如：`[[NSBundle mainBundle] validateReceipt]`) 。黑客可以轻易地搜索到这个方法，并且通过代码跳过验证。要是所有开发者都用同样的验证方法，那将会很容易受到攻击。

所以苹果并没有这样做，而是选择了使用标准加密和编码技术来解决这个问题，并且在[官方文档](https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Introduction.html)和 [WWDC 视频](https://developer.apple.com/videos/wwdc/2014/#305)里提供了一些帮助，从而使开发者可以实现自己独有的的收据验证代码。但是，整个流程并不简单，并且需要很好的密码学基础和各种信息安全方面的技术。

当然，有一些已经实现好的现成代码 (比如在 [Github](https://github.com/search?utf8=%E2%9C%93&q=receipt+validation) 上) ，但是它们只是参考实现，并且如果大家都用同样的代码，还是会有前面的问题：黑客将会很容易攻击验证部分的代码。所以，开发一套既独特又安全从而能够抵御普通攻击的安全方案是十分重要的。

补充说明一下，我是 [Receigen](http://receigen.etiemble.com/) 这个 Mac 应用的作者， Receigen 可以生成安全且变化的收据验证代码。在这篇文章里，我们将会学习收据验证的技巧和最佳实践方案。

## 收据解析

让我们从技术的角度来看一下收据文件。文件结构大概是这样的：

![](/images/issues/issue-17/ReceiptStructure.png)

收据文件由一个经过签名的 [PKCS #7](https://www.ietf.org/rfc/rfc2315.txt) 容器组成，这个容器内嵌 [DER](http://en.wikipedia.org/wiki/X.690#DER_encoding) 编码的 [ASN.1](http://www.itu.int/ITU-T/recommendations/rec.aspx?id=9608) 负载区 (payload)，一个证书链，和一个数字签名。

- **负载区** 是包含着收据信息的一组属性，每个属性都包含了一个类型、一个版本号和一个值。在属性的值里，你可以找到这个收据所对应的 bundle id 和版本号。
- **证书链** 是一组用来验证签名摘要的证书 - 其中的叶证书 (leaf certificate) 是用来对负载区进行签名的。
- **数字签名** 是对负载区加密编码后的摘要。通过验证这个摘要，你可以验证负载区是否被篡改过。

### 容器

收据的容器是一个 PKC #7 信封，它由苹果通过一个专门的证书进行签名。容器的签名保证了负载区的可靠性和完整性。

验证这个签名需要有以下两个步骤：

- 证书链需要通过苹果证书授权根证书 (Apple Certificate Authority Root certificate) 的验证 - 用来检查**可靠性**。
- 通过证书链计算出一个签名，并和容器签名对比 - 用来检查**完整性**。

### 负载区

ASN.1 负载区的结构如下：

    ReceiptModule DEFINITIONS ::=
    BEGIN

    ReceiptAttribute ::= SEQUENCE {
        type    INTEGER,
        version INTEGER,
        value   OCTET STRING
    }

    Payload ::= SET OF ReceiptAttribute

    END


收据的属性由以下三个字段组成：

- **类型域** 通过类型区分各个属性。苹果公布了[公开属性列表](https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html)，用来从收据中取出信息。在分析收据的时候你有可能也会遇到不在这个列表中的属性，最好的应对方案就是忽略它们 (很有可能是苹果为以后预留的属性类型)。
- **版本域** 现在还没有使用。
- **值域** 包含了一组字节数据 (虽然从名字来看是字符串，但其实并不是)。

负载区使用 DER ([分布式编码规则](http://en.wikipedia.org/wiki/X.690#DER_encoding)) 进行编码，这种编码方式可以生成准确且压缩的 ASN.1 结构。 DER 使用一种叫做 [TLV](http://en.wikipedia.org/wiki/Type-length-value) 的格式，每个类型的标签都有字节常量。

为了更好地说明这个概念，接下来我们举一些在收据中使用 DER 编码的例子。下面的图表展示了一个收据模块是如何被编码的：

- 第一个字节用来标记这个 ASN.1 集合。
- 接下来的三个字节对集合内容的长度进行编码。
- 集合的内容就是收据的属性。

![](/images/issues/issue-17/ASN.1-DER-Receipt.png)

接下来的一张图展示了收据的属性是如何进行编码的：

- 第一个字节标记这个 ASN.1 序列。
- 第二个字节对序列内容的长度进行编码。

- 序列的内容如下：
    - 属性的类型被编码成了一个 ASN.1 INTEGER (第一个字节用来标记一个 ASN.1 INTEGER 类型，第二个字节编码长度，第三个字节存放值) 。
    - 属性的版本也被编码成了一个 ASN.1 INTEGER (第一个字节用来标记一个 ASN.1 INTEGER 类型，第二个字节编码长度，第三个字节存放值) 。
    - 属性的值被编码成了一个 ASN.1 OCTET-STRING (第一个字节用来标记一个 ASN.1 OCTET-STRING 类型，第二个字节编码长度，剩下来的字节用来保存数据) 。

![](/images/issues/issue-17/ASN.1-DER-Attribute-OCTETSTRING.png)

通过使用 ASN.1 OCTET-STRING 来存储属性值，我们很容易嵌入各种各样的值，比如 UTF-8 、 ASCII 或者数字。在内购中，属性值也可以包含收据模块。下面的是一些图例：

![](/images/issues/issue-17/ASN.1-DER-Attribute-INTEGER.png)

![](/images/issues/issue-17/ASN.1-DER-Attribute-IA5STRING.png)

![](/images/issues/issue-17/ASN.1-DER-Attribute-UTF8STRING.png)

![](/images/issues/issue-17/ASN.1-DER-Attribute-SET.png)


## 验证收据

验证收据的步骤如下：

- 定位收据。如果没有找到收据。验证失败。
- 验证收据的可靠性和完整性，收据必须是通过苹果签名认证且未被篡改。
- 解析收据，获取相关属性比如 bundle id， bundle 版本等等。
- 验证收据中 bundle id 和版本号是否和应用中的相匹配。
- 计算设备 GUID 的哈希值，不同的设备会有不同的计算结果。
- 如果是大量采购的 (Volume Purchase Program) ，则需要验证收据的截止日期。

注释：接下来的部分演示了如何进行验证操作。代码片段是用于演示，并不是唯一的方案。

### 定位收据

在 OS X 和 iOS 中，收据的位置并不一样，如下图所示：

![](/images/issues/issue-17/ReceiptLocation.png)

在 OS X 中，收据文件在应用程序的 bundle 里，路径是 Contents/_MASReceipt 。而在 iOS 里，收据文件在应用的数据沙盒中，在 StoreKit 文件夹下。

定位时必须确保收据存在：如果收据在正确的目录下，那么可以正常加载；如果不存在收据，那么就会验证失败。

在 OS X 10.7 和 iOS 7 之后，代码是这样的：

    // OS X 10.7 或之后 / iOS 7 或之后
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *receiptURL = [mainBundle appStoreReceiptURL];
    NSError *receiptError;
    BOOL isPresent = [receiptURL checkResourceIsReachableAndReturnError:&receiptError];
    if (!isPresent) {
        // 验证失败
    }

但是如果在 OS X 10.6 里， `appStoreReceiptURL` 这个 selector 是不存在的，你需要手动构建收据路径：

    // OS X 10.6
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *bundleURL = [mainBundle bundleURL];
    NSURL *receiptURL = [bundleURL URLByAppendingPathComponent:@"Contents/_MASReceipt/receipt"];
    NSError *receiptError;
    BOOL isPresent = [receiptURL checkResourceIsReachableAndReturnError:&receiptError];
    if (!isPresent) {
        // 验证失败
    }

### 加载收据

加载收据很简单，下面是通过 [OpenSSL](https://www.openssl.org/) 加载并解析 PKCS #7 包的方法：

    // 加载收据文件
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];

    // 创建内存缓冲，以提取 PKCS #7 容器
    BIO *receiptBIO = BIO_new(BIO_s_mem());
    BIO_write(receiptBIO, [receiptData bytes], (int) [receiptData length]);
    PKCS7 *receiptPKCS7 = d2i_PKCS7_bio(receiptBIO, NULL);
    if (!receiptPKCS7) {
        // 验证失败
    }

    // 检查容器是否带有签名
    if (!PKCS7_type_is_signed(receiptPKCS7)) {
        // 验证失败
    }

    // 检查已签名容器是否含有实际的数据
    if (!PKCS7_type_is_data(receiptPKCS7->d.sign->contents)) {
        // 验证失败
    }

### 验证收据签名

当加载完收据之后，我们要做的第一件事情是确保它是完整的且未被篡改。下面是通过 [OpenSSL](https://www.openssl.org/) 验证 PKCS #7 签名的方法：

    // 加载 Apple 根证书 (从 https://www.apple.com/certificateauthority/ 下载)
    NSURL *appleRootURL = [[NSBundle mainBundle] URLForResource:@"AppleIncRootCertificate" withExtension:@"cer"];
    NSData *appleRootData = [NSData dataWithContentsOfURL:appleRootURL];
    BIO *appleRootBIO = BIO_new(BIO_s_mem());
    BIO_write(appleRootBIO, (const void *) [appleRootData bytes], (int) [appleRootData length]);
    X509 *appleRootX509 = d2i_X509_bio(appleRootBIO, NULL);

    // 创建证书存储
    X509_STORE *store = X509_STORE_new();
    X509_STORE_add_cert(store, appleRootX509);

    // 确认在验证前加载了摘要
    OpenSSL_add_all_digests();

    // 检查签名
    int result = PKCS7_verify(receiptPKCS7, NULL, store, NULL, NULL, 0);
    if (result != 1) {
        // 验证失败
    }

### 解析收据

在验证完收据之后，接下来就是解析收据的负载区了。下面的例子展示了如何通过 [OpenSSL](https://www.openssl.org/) 解码 DER 编码的 ASB.1 格式负载区：

    // 获取指向 ASN.1 负载的指针
    ASN1_OCTET_STRING *octets = receiptPKCS7->d.sign->contents->d.data;
    const unsigned char *ptr = octets->data;
    const unsigned char *end = ptr + octets->length;
    const unsigned char *str_ptr;

    int type = 0, str_type = 0;
    int xclass = 0, str_xclass = 0;
    long length = 0, str_length = 0;

    // 收据信息的存储
    NSString *bundleIdString = nil;
    NSString *bundleVersionString = nil;
    NSData *bundleIdData = nil;
    NSData *hashData = nil;
    NSData *opaqueData = nil;
    NSDate *expirationDate = nil;

    // 处理 GMT 时区 的 RFC 3339 日期的日期格式器
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    // 解码负载区 (应该得到一个 SET)
    ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
    if (type != V_ASN1_SET) {
        // 验证失败
    }

    while (ptr < end) {
        ASN1_INTEGER *integer;

        // 解析属性序列 (应该得到一个 SEQUENCE)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_SEQUENCE) {
            // 验证失败
        }

        const unsigned char *seq_end = ptr + length;
        long attr_type = 0;
        long attr_version = 0;

        // 解析属性类型 (应该得到一个 INTEGER)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_INTEGER) {
            // 验证失败
        }
        integer = c2i_ASN1_INTEGER(NULL, &ptr, length);
        attr_type = ASN1_INTEGER_get(integer);
        ASN1_INTEGER_free(integer);

        // 解析属性版本 (应该得到一个 INTEGER)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_INTEGER) {
            // 验证失败
        }
        integer = c2i_ASN1_INTEGER(NULL, &ptr, length);
        attr_version = ASN1_INTEGER_get(integer);
        ASN1_INTEGER_free(integer);

        // 解析属性的值 (应该得到一个 OCTET STRING)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_OCTET_STRING) {
            // 验证失败
        }

        switch (attr_type) {
            case 2:
                // Bundle id
                str_ptr = ptr;
                ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                if (str_type == V_ASN1_UTF8STRING) {
                    // 我们同时存储了解码后的字符串和原始数据以备后用
                    // 原始数据将用在计算 GUID 哈希值上
                    bundleIdString = [[NSString alloc] initWithBytes:str_ptr length:str_length encoding:NSUTF8StringEncoding];
                    bundleIdData = [[NSData alloc] initWithBytes:(const void *)ptr length:length];
                }
                break;

            case 3:
                // Bundle 版本
                str_ptr = ptr;
                ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                if (str_type == V_ASN1_UTF8STRING) {
                    // 我们存储了解码后的字符串以备后用
                    bundleVersionString = [[NSString alloc] initWithBytes:str_ptr length:str_length encoding:NSUTF8StringEncoding];
                }
                break;

            case 4:
                // 非透明值
                opaqueData = [[NSData alloc] initWithBytes:(const void *)ptr length:length];
                break;

            case 5:
                // 计算得到的 GUID (SHA-1 哈希)
                hashData = [[NSData alloc] initWithBytes:(const void *)ptr length:length];
                break;

            case 21:
                // 过期日期
                str_ptr = ptr;
                ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                if (str_type == V_ASN1_IA5STRING) {
                    // 日期被存储为一个需要被解析的字符串
                    NSString *dateString = [[NSString alloc] initWithBytes:str_ptr length:str_length encoding:NSASCIIStringEncoding];
                    expirationDate = [formatter dateFromString:dateString];
                }
                break;

                // 你可以解析更多其他属性...

            default:
                break;
        }

        // 移动到下一个值
        ptr += length;
    }

    // 确保所有值都存在
    if (bundleIdString == nil ||
        bundleVersionString == nil ||
        opaqueData == nil ||
        hashData == nil) {
        // 验证失败
    }



### 验证收据信息

收据包含了 bundle id 和版本号，你需要确保这两个数据和应用里的完全一致：

    // 检查 bundle id
    if (![bundleIdString isEqualTo:@"io.objc.myapplication"]) {
        // 验证失败
    }

    // 检查 bundle 版本
    if (![bundleVersionString isEqualTo:@"1.0"]) {
        // 验证失败
    }


十分重要：在发放收据的时候，bundle 的版本号是从 Info.plist 文件获取的：

- 在 OS X 里，版本号来自 `CFBundleShortVersionString` 的值。
- 在 iOS 里，版本号来自 `CFBundleVersion` 值。

在设置这些值的时候千万要小心，因为分发收据的时候会用到。

### 计算 GUID 哈希值

在分发收据的时候，会用到以下三个值来生成 SHA-1 哈希值：设备的 GUID (只能在设备上获取) ，一个非透明值 （type 4)，还有 bundle id (type 2)。 SHA-1 哈希值是基于这三个值计算出来的，并且存储在收据中 (type 5)。

在验证的时候将会采用相同的计算方案，如果计算的哈希值一致，那么这个收据是有效的，下图描述了整个计算的流程：

![](/images/issues/issue-17/GUIDComputation.png)

为了计算这个哈希值，你需要获取设备的 GUID。

#### 设备的 GUID (OS X)

在 OS X 里，设备的 GUID 是私有网卡的 Mac 地址。获取的方法之一是使用 IOKit 框架：

    #import <IOKit/IOKitLib.h>

    // 打开一个 MACH 端口
    mach_port_t master_port;
    kern_return_t kernResult = IOMasterPort(MACH_PORT_NULL, &master_port);
    if (kernResult != KERN_SUCCESS) {
        // 验证失败
    }

    // 为主接口创建搜索
    CFMutableDictionaryRef matching_dict = IOBSDNameMatching(master_port, 0, "en0");
    if (!matching_dict) {
        // 验证失败
    }

    // 进行搜索
    io_iterator_t iterator;
    kernResult = IOServiceGetMatchingServices(master_port, matching_dict, &iterator);
    if (kernResult != KERN_SUCCESS) {
        // 验证失败
    }

    // 迭代结果
    CFDataRef guid_cf_data = nil;
    io_object_t service, parent_service;
    while((service = IOIteratorNext(iterator)) != 0) {
        kernResult = IORegistryEntryGetParentEntry(service, kIOServicePlane, &parent_service);
        if (kernResult == KERN_SUCCESS) {
            // 存储结果
            if (guid_cf_data) CFRelease(guid_cf_data);
            guid_cf_data = (CFDataRef) IORegistryEntryCreateCFProperty(parent_service, CFSTR("IOMACAddress"), NULL, 0);
            IOObjectRelease(parent_service);
        }
        IOObjectRelease(service);
        if (guid_cf_data) {
            break;
        }
    }
    IOObjectRelease(iterator);

    NSData *guidData = [NSData dataWithData:(__bridge NSData *) guid_cf_data];


#### 设备的 GUID (iOS)

在 iOS 里，设备的 GUID 是一个独一无二的纯字母字符串，和应用的开发者相关：

    UIDevice *device = [UIDevice currentDevice];
    NSUUID *uuid = [device identifierForVendor];
    uuid_t uuid;
    [identifier getUUIDBytes:uuid];
    NSData *guidData = [NSData dataWithBytes:(const void *)uuid length:16];


#### 哈希计算

现在我们已经获取了设备的 GUID 值，接下来就可以计算哈希值了。计算哈希值需要用到 ASN.1 属性的原始值 (比如 OCTET-STRING 的二进制数据)，而不是处理后的值。下面是一个 SHA-1 哈希值的计算过程和一个与 [OpenSSL](https://www.openssl.org/) 的对比：

    unsigned char hash[20];

    // 为计算创建哈希上下文
    SHA_CTX ctx;
    SHA1_Init(&ctx);
    SHA1_Update(&ctx, [guidData bytes], (size_t) [guidData length]);
    SHA1_Update(&ctx, [opaqueData bytes], (size_t) [opaqueData length]);
    SHA1_Update(&ctx, [bundleIdData bytes], (size_t) [bundleIdData length]);
    SHA1_Final(hash, &ctx);

    // 进行比较
    NSData *computedHashData = [NSData dataWithBytes:hash length:20];
    if (![computedHashData isEqualToData:hashData]) {
        // 验证失败
    } 


### 批量购买

如果应用支持批量购买，那么还需要验证另一个东西：收据的失效日期。我们可以在 type 21 属性里找到这个日期：

    // 如果存在过期日期，则检查之
    if (expirationDate) {
        NSDate *currentDate = [NSDate date];
        if ([expirationDate compare:currentDate] == NSOrderedAscending) {
            // 验证失败
        }
    }

## 处理验证结果

到目前为止，如果所有的校验全部通过，那么验证的流程就算是通过了。如果任何一个步骤验证失败，那么收据就是无效的。在完成验证之后，根据平台和时间的不同，有很多种方法去处理无效的收据：

### OS X 中的处理方式

在 OS X 里，收据的验证过程必须在应用刚开始运行的时候完成，也就是说要在 main 方法前面。如果收据无效 (没有收据，收据不正确，收据被篡改) ，那么应用必须退出并返回 173 错误码。这个特殊的值告诉系统这个应用需要获取收据。当收到了新的收据的时候，这个应用将会重新运行。

在收到应用退出并返回代码 173 的时候， App Store 将会弹框提示登录，需要联网才能重新获取到收据。

你也可以在应用的生命周期里进行收据验证，你可以自己决定如何处理无效收据：忽视，禁用功能，或是直接来个闪退。

### iOS 中的处理方式

在 iOS 里，收据验证可以在任何时候进行。如果没找到收据，你可以出发一个刷新收据的请求，告诉系统你的应用需要获取新的收据。收到了这个请求之后， App Store 会弹窗提示登录，在联网状态下会请求并获取到新的收据。

你可以决定如何处置无效收据：忽视或是禁用。

## 测试

在测试的时候，主要的障碍是如何获取沙盒中的测试收据。

苹果通过应用的证书区分生产环境和沙盒环境：

- 如果应用是开发者证书签名的，那么收据请求会定向到沙盒环境中。
- 如果应用是苹果证书签名的，那么收据请求会定向到生产环境中。

使用有效的开发者证书是非常重要的，要不然 storeagent 后台程序 (负责和 App Store 交互)无法确认你的应用是 App Store 的应用。

### 设置测试用户

为了模拟沙盒环境下的真实用户，你需要定义测试用户。测试用户的操作和真实用户完全一样，唯一的区别就是买东西不用掏钱。

测试用户可以通过 [iTunes Connect](http://itunesconnect.apple.com/) 创建和设置。你可以定义任意数量的测试用户，每个测试用户都需要一个有效的邮箱地址，并且不能是真实的 iTunse 账号。如果邮箱供应商支持 + 号，那么你可以用邮箱别名作为测试账号：foo+us@objc.io 、 foo+uk@objc.io 和 foo+fr@objc.io 都会发送到 foo@objc.io 这个邮箱里。

### OS X 上的测试

为了测试 OS X 上的收据验证，我们需要以下步骤：

- 在 Finder 中启动应用，**不要**在 Xcode 里启动，要不然 launchd 后台进程无法触发和进行收据获取。
- 如果没有收据，应该返回 173 的错误码。这样会触发一个新的收据请求，会弹出 App Store 的登陆框，输入测试用户的账号密码登陆来获取新的测试收据。
- 如果验证通过，并且 bundle 的信息也匹配，那么就会生成收据并安装在应用包里。在获取到收据之后，应用会自动重新启动。

当收据重新获取之后，你可以在 Xcode 里运行你的应用，进行错误排查或者验证收据的代码的微调工作。

### iOS 上的测试

为了测试 iOS 上的收据验证，需要以下步骤：

- 记得在真机上运行应用，而不是在虚拟机上。模拟机没有请求证书的 API 。
- 如果没有收据，应用会发起一个刷新收据的请求， App Store 会弹出一个登录窗口，使用测试账号登陆并获取收据。
- 如果验证通过，并且 buldle 的信息也和你输入的信息相一致，系统将会生成收据并且安装在应用的沙盒中。获取到收据之后，你可以再次进行校验以确认。

当收据重新获取之后，你可以在 Xcode 里运行你的应用，进行错误排查或者验证收据的代码的微调工作。

## 安全

验证收据的代码部分必须在安全方面高度敏感。如果被避开或者攻击，你就失去了核实用户权限的能力，并且无法验证用户是否购买。因为，让验证收据的代码能够承受黑客的攻击变得至关重要。

注意：攻击应用的方式多种多样，所以不要尝试完全抵御所有攻击。原则很简单：尽一切可能提高攻击应用的成本。

### 攻击的种类

所有的攻击都是从分析目标开始的：

- **静态分析** 是针对应用的二进制文件，常见的工具有：strings、otool、disassembler 等等。

- **动态分析** 是通过监测应用运行时的行为进行分析，比如嵌入 debugger，以及对已知方法嵌入断点。

分析结束之后则会进行一些常见的攻击来绕开或者破解你的收据验证代码：

- **替换收据** - 如果你未能正确地验证收据，黑客可以用其他应用的合法收据。
- **替换字符串** - 如果你没有隐藏/混淆验证中用到的字符串 (比如：`en0`，`_MASReceipt`，bundle id，bundle 版本号)，黑客就有机会用自己的字符串替换原始字符串。
- **绕过代码** - 如果验证收据的代码是大家都熟悉的函数或者模式，黑客可以轻松的定位收据验证的代码并且篡改汇编码，绕过验证。
- **替换公共库** - 如果在加密时使用了一些第三方公共库 (比如 OpenSSL)，黑客可以用自己的库替换原始库，从而绕过所有基于这类加密方法的验证。
- **函数重载/注入** - 主要是在运行时进行攻击，通过在共有库目录里添加自己的库来给已知函数 (用户的或者系统的) 添加补丁，这个 [mach_override](https://github.com/rentzsch/mach_override) 项目让这一切都变得简单。

### 安全准则

当进行收据验证的时候，需要在心中牢记以下几点安全准则：

#### 必须要做

- **多次验证** - 在应用刚开启的时候验证一次，在应用运行期间也周期性的验证几次。验证的代码越多，你被攻击成功的概率就越低。
- **混淆字符串** - 千万不要让你验证中用到的代码对外清晰可见，这会让黑客轻易的定位并攻击验证代码。字符串混淆的手段有很多，xor-ing、value shifting、bit masking，以及很多其他方式，让字符串变得无法阅读。
- **混淆收据验证结果** - 不要把验证结果清晰可见的展示出来 (比如："en0"，"AppleCertificateRoot" 这种) ，这样会帮助黑客定位到你的验证代码。为了混淆字符串，你可以用一些前面提到的算法进行处理，让结果看起来是一些随机的字节。
- **控制流复杂化** - 用一个 [无实际意义的断言](http://en.wikipedia.org/wiki/Opaque_predicate) (比如一个只有运行时才有的状态) 来让别人很难跟踪你的你的代码流。这个无意义的断言通常来源于某个编译时不知道的函数运行结果。你也可以在通常不需要的地方加上一些循环， goto 语句，静态变量，或者其他任何控制流的结构。
- **使用静态库** - 如果你包含第三方的代码，尽量通过静态链接的方式加进项目中。静态代码很难篡改，更何况你也不需要会变动的代码。
- **敏感函数防止篡改** - 确保你的敏感函数没有被替换或者修改。函数有可能基于输入的参数进行各种操作，所以要做好参数的验证工作。如果函数既没有返回错误也没有返回正确的结果，那它有可能被替换或者修改过了。

#### 千万别做

- **避免 Objective-C** - Objective-C 有很多运行时的信息，很容易被利用，进行解析/注入/替换。如果还是想要用 Objective-C 的话，记得混淆 selector 和调用。
- **使用共享库来实现安全代码** - 共享的类库有可能会被替换或者更改。
- **使用独立代码** - 你应该把验证的代码埋在业务逻辑里去，从而加大定位和篡改的难度。
- **模式化收据验证** - 最好变化、复制、倍增验证代码的实现，避免验证模式被侦测。
- **低估黑客的决心** - 有了足够的时间和资源，黑客肯定会成功破解你的应用。你能做的是让这个过程尽量的艰难，增大黑客攻击的成本。

---

 

原文 [Receipt Validation](http://www.objc.io/issue-17/receipt-validation.html)












