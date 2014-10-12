TODO ： 替换图片URL

# 收据验证

# Receipt Validation


## 关于收据

## About Receipts


收据 (Receipts) 是在 OS X 10.6.6 更新后，和 Mac App Store 一起出现的。 iOS 在内购的时候总是需要向服务器提供收据，而在 iOS7 之后， iOS 和 OS X 的收据格式开始统一。

Receipts were introduced alongside the release of the Mac App Store, as part of the OS X 10.6.6 update. While iOS has always provided server-side receipts for in-app purchases, it was only with iOS 7 that iOS and OS X began to share the same receipt format.


一个收据意味着一个一次可信任的购买记录，包括所有内购的记录，有点像是去超市购物后拿到的那一张纸质收据一样。

A receipt is meant to be a trusted record of a purchase, along with any in-app purchases that the user has made — much like a paper receipt that you get when shopping in a store.


关于收据，有以下几个关键的概念：

Here are some key points about receipts:


- 收据是苹果公司通过 App Store 创建和授权的。
- 收据是针对某个指定版本的应用和某个指定的设备发放的。
- 收据存储在设备中。
- 每次的安装和更新操作都会发放新的收据。

A receipt is created and signed by Apple through the App Store.
A receipt is issued for a specific version of an application and a specific device.
A receipt is stored locally on the device.
A receipt is issued each time an installation or an update occurs.


- 安装应用之后，将会发放与应用和设备匹配的收据。
- 更新应用之后，将会发放与最新版本相匹配的收据。

When an application is installed, a receipt that matches the application and the device is issued.
When an application is updated, a receipt that matches the new version of the application is issued.


- 下列的任何一项交易都会发放收据：

A receipt is issued each time a transaction occurs:


- 当你通过内购付款购买的时候，将会发放收据用来验证购买记录。
- 当你恢复以前的交易记录时，将会发放用来验证购买记录的收据。

When an in-app purchase occurs, a receipt is issued so that it can be accessed to verify that purchase.
When previous transactions are restored, a receipt is issued so that it can be accessed to verify those purchases.


## 关于验证

## About Validation


验证收据是保障收入的重要途径，同时也可以加强应用的业务模式

Verifying receipts is a mechanism that helps you to protect your revenue and enforce your business model directly in your application.


你可能会感觉到很困惑，为什么苹果不提供简单点的 API 来验证收据。为了便于理解这个问题，我们不妨假设存在这样一个方法 (比如：`[[NSBundle mainBundle] validateReceipt]`) 。黑客可以轻易的搜索到这个方法，并且通过代码跳过验证。如果所有开发者都用同样的验证方法，那将会很容易受到攻击。

You may wonder why Apple hasn’t provided a simple API to validate the receipt. For the sake of demonstration, imagine that such a method exists (for example, [[NSBundle mainBundle] validateReceipt]). An attacker would simply look for this selector inside the binary and patch the code to skip the call. Since every developer would use the same validation method, hacking would be too easy.


所以苹果并没有这样做，而是选择了使用标准加密和编码技术来解决这个问题，并且在 [官方文档](https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Introduction.html) 和 [WWDC 视屏](https://developer.apple.com/videos/wwdc/2014/#305) 里提供了一些帮助，从而开发者可以实现自己独有的的收据验证代码。但是，整个流程并不简单，并且需要很好的密码学基础和各种信息安全方面的技术。

Instead, Apple made the choice to use standard cryptography and encoding techniques, and to provide some help — in the form of documentation and WWDC sessions — for implementing your own receipt validation code. However, this is not an easy process, and it requires a good understanding of cryptography and of a variety of secure coding techniques.


当然，有一些已经实现好的现成代码 (比如在 [Github](https://github.com/search?utf8=%E2%9C%93&q=receipt+validation) 上) ，但是它们只是参考实现，并且如果大家都用同样的代码，还是会有前面的问题：黑客将会很容易攻击验证部分的代码。所以，开发一套既独特又安全从而能够抵御普通攻击的安全方案是十分重要的。

Of course, there are several off-the-shelf implementations available (for example, on GitHub), but they are often just reference implementations and suffer from the same problem outlined above if everybody uses them: it becomes very easy for attackers to crack the validation code. So it’s important to develop a solution that is unique and secure enough to resist common attacks.


补充说明一下，我是 [Receigen](http://receigen.etiemble.com/) 这个 Mac 应用的作者， Receigen 可以生成安全且变化的收据验证代码。在这篇文章里，我们将会学习收据验证的技巧和最佳实践方案。

In the interest of full disclosure, I’m the author of Receigen, a Mac app used to generate secure and changing receipt validation code. In this article, we’ll take a look at the mechanics and best practices of receipt validation.



## 收据解析

## Anatomy of a Receipt


让我们从技术的角度来看一下收据文件。文件结构大概是这样的：

Let’s take a technical look at the receipt file. Its structure looks like this:


![](http://img.objccn.io/issue-17/ReceiptStructure.png)

收据文件由一个已注册的 [PKCS #7](https://www.ietf.org/rfc/rfc2315.txt) 容器组成，内嵌 [DER](http://en.wikipedia.org/wiki/X.690#DER_encoding) 编码的 [ASN.1](http://www.itu.int/ITU-T/recommendations/rec.aspx?id=9608) 负载区，一个证书链，和一个签名。

A receipt file consist of a signed PKCS #7 container that embeds a DER-encoded ASN.1 payload, a certificate chain, and a digital signature.


- **负载区** 是包含着收据信息的一组属性，每个属性都包含了一个类型、一个版本号和一个值。在属性的值里，你可以找到这个收据所对应的 bundle 的标识符和版本号。
- **证书链** 是一组用来验证签名摘要的证书 - 其中的叶证书是用来注册负载区的。
- **签名** 是对负载区编码后的摘要。通过验证这个摘要，你可以验证负载区是否被篡改过。

The payload is a set of attributes that contains the receipt information; each attribute contains a type, a version, and a value. Among the attribute values, you find the bundle identifier and the bundle version for which the receipt was issued.
The certificate chain is the set of certificates required to properly verify the signature digest — the leaf certificate is the certificate that has been used to sign the payload.
The signature is the encrypted digest of the payload. By checking this digest, you can verify that the payload has not been tampered with.



### 容器

### The Container


收据的容器是一个 PKC #7 信封，它的证书需要通过苹果签名。容器的签名保证了负载区的可靠性和完整性。 

The receipt container is a PKCS #7 envelope, which is signed by Apple with a dedicated certificate. The container’s signature guarantees the authenticity and the integrity of the encapsulated payload.


验证签名需要有以下两个步骤：

To verify the signature, two checks are needed:


- 证书链需要通过苹果证书授权根证书的验证 - 用来检查**可靠性**。
- 通过证书链计算生成签名，和容器签名对比 - 用来检查**完整性**。

The certificate chain is validated against the Apple Certificate Authority Root certificate — this is the authenticity check.
A signature is computed using the certificate chain and compared to the one found in the container — this is the integrity check.


### 负载区

### The Payload

ASN.1 负载区的结构如下：

The ASN.1 payload is defined by the following structure:


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

A receipt attribute has three fields:


- **类型域** 通过类型区分各个属性。苹果公布了 [公开属性列表](https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html) ，用来从收据中取出信息。在分析收据的时候你有可能也会遇到不在这个列表中的属性，最好的应对方案就是忽略它们 (很有可能是苹果为以后预留的属性类型)。
- **版本域** 现在还没有使用。
- **值域** 包含了一组字节数据 (虽然从名字来看这并不是一个字符串)。

The type field identifies each attribute by its type. Apple has published a list of public attributes that can be used to extract information from the receipt. You may also find unlisted attributes while parsing a receipt, but it’s best to simply ignore them (mostly because they are reserved by Apple for future use).
The version field is not used for now.
The value field contains the data as an array of bytes (even if its name may suggest it, this is not a string).


负载区使用 DER ([分布式编码规则](http://en.wikipedia.org/wiki/X.690#DER_encoding)) 进行编码，这种编码方式可以生成准确且压缩的 ASN.1 结构。 DER 使用一种叫做 [TLV](http://en.wikipedia.org/wiki/Type-length-value) 的格式，每个类型的标签都有字节常量。

The payload is encoded using DER (Distinguished Encoding Rules). This kind of encoding provides an unequivocal and compact result for ASN.1 structures. DER uses a pattern of type-length-value triplets and byte constants for each type tag.


为了更好地说明这个概念，接下来我们举一些在收据中使用 DER 编码的例子。下面的图表展示了一个收据模块是如何被编码的：

To better illustrate the concept, here are some concrete examples of DER-encoded content applied to a receipt. The figure below shows how a receipt module is encoded:


- 第一个字节用来标记这个 ASN.1 集合。
- 接下来的三个字节对集合内容的长度进行编码。
- 集合的内容就是收据的属性。

The first byte identifies an ASN.1 set.
The three following bytes encode the length of the set’s content.
The contents of the set are the receipt attributes.

![](http://img.objccn.io/issue-17/ASN.1-DER-Receipt.png)


接下来的一张图展示了收据的属性是如何进行编码的：

The next figure shows how a receipt’s attributes are encoded:


- 第一个字节标记这个 ASN.1 序列。
- 第二个字节对序列内容的长度进行编码。


The first byte identifies an ASN.1 sequence.
The second byte encodes the length of the sequence’s content.


- 序列的内容如下：

The content of the sequence is:


- 属性的类型被编码成了一个 ASN.1 INTEGER (第一个字节用来标记，第二个字节加密长度，第三个字节存放值) 。
- 属性的版本也被编码成了一个 ASN.1 INTEGER (第一个字节用来标记，第二个字节加密长度，第三个字节存放值) 。
- 属性的值被编码成了一个 ASN.1 OCTET-STRING (第一个字节用来标记，第二个字节加密长度，剩下来的字节用来保存数据) 。

The attribute’s type encoded as an ASN.1 INTEGER (the first byte identifies an ASN.1 INTEGER, the second byte encodes its length, and the third byte contains the value).
The attribute’s version encoded as an ASN.1 INTEGER (the first byte identifies an ASN.1 INTEGER, the second byte encodes its length, and the third byte contains the value).
The attribute’s value encoded as an ASN.1 OCTET-STRING (the first byte identifies an ASN.1 OCTET-STRING, the second byte encodes its length, and the remaining bytes contain the data).

![](http://img.objccn.io/issue-17/ASN.1-DER-Attribute-OCTETSTRING.png)


通过使用 ASN.1 OCTET-STRING 来存储属性值，我们很容易嵌入各种各样的值，比如 UTF-8 、 ASCII 或者数字。在内购中，属性值也可以包含收据模块。下面的是一些图例：

By using an ASN.1 OCTET-STRING for the attribute’s value, it is very easy to embed various values like UTF-8 strings, ASCII strings, or numbers. The attribute’s value can also contain a receipt module in the case of in-app purchases. Some examples are shown in the figures below:


![](http://img.objccn.io/issue-17/ASN.1-DER-Attribute-INTEGER.png)

![](http://img.objccn.io/issue-17/ASN.1-DER-Attribute-IA5STRING.png)

![](http://img.objccn.io/issue-17/ASN.1-DER-Attribute-UTF8STRING.png)

![](http://img.objccn.io/issue-17/ASN.1-DER-Attribute-SET.png)


## 验证收据

## Validating the Receipt


验证收据的步骤如下：

The steps to validate a receipt are as follows:


- 定位收据。如果没有找到收据。验证失败。
- 验证收据的可靠性和完整性，收据必须是通过苹果签名认证且未被篡改。
- 解析收据，获取相关属性比如 bundle 标识符， bundle 版本等等。
- 验证收据中 bundle 的标识符和版本号是否和应用中的相匹配。
- 计算设备 GUID 的哈希值，不同的设备会有不同的计算结果。
- 如果是大量采购的 (Volume Purchase Program) ，则需要验证收据的截止日期。

Locate the receipt. If no receipt is found, then the validation fails.
Verify the receipt authenticity and integrity. The receipt must be properly signed by Apple and must not be tampered with.
Parse the receipt to extract attributes such as the bundle identifier, the bundle version, etc.
Verify that the bundle identifier found inside the receipt matches the bundle identifier of the application. Do the same for the bundle version.
Compute the hash of the GUID of the device. The computed hash is based on device-specific information.
Check the expiration date of the receipt if the Volume Purchase Program is used.


注释：接下来的部分演示了如何进行验证操作。代码片段是用于演示，并不是唯一的方案。

NOTE: The following sections describe how to perform the various steps of the validation. The code snippets are meant to illustrate each step; do not consider them the only solutions.



### 定位证书

### Locating the Receipt


在 OS X 和 iOS 中，证书的位置并不一样，如下图所示：

The location of the receipt differs between OS X and iOS, as shown in the following figure:

![](http://img.objccn.io/issue-17/ReceiptLocation.png)


在 OS X 中，收据文件在应用程序的安装包 (bundle) 里，路径是 Contents/_MASReceipt 。而在 iOS 里，收据文件在应用的数据沙盒中，在 StoreKit 文件夹下。

On OS X, the receipt file is located inside the application bundle, under the Contents/_MASReceipt folder. On iOS, the receipt file is located in the application’s data sandbox, under the StoreKit folder.


定位时必须确保收据存在：如果收据在正确的目录下，那么可以正常加载；如果不存在收据，那么就会验证失败。

Once located, you must ensure that the receipt is present: If the receipt exists at the correct place, it can be loaded. If the receipt does not exist, this is considered a validation failure.


在 OS X 10.7 和 iOS 7 之后，代码是这样的：

On OS X 10.7 and later or iOS 7 and later, the code is straightforward:


    // OS X 10.7 and later / iOS 7 and later
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *receiptURL = [mainBundle appStoreReceiptURL];
    NSError *receiptError;
    BOOL isPresent = [receiptURL checkResourceIsReachableAndReturnError:&receiptError];
    if (!isPresent) {
        // Validation fails
    }

但是如果在 OS X 10.6 里， `appStoreReceiptURL` 这个 selector 是不存在的，你需要手动构建收据路径：

But if you target OS X 10.6, the appStoreReceiptURL selector is not available, and you have to manually build the URL to the receipt:


    // OS X 10.6 and later
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *bundleURL = [mainBundle bundleURL];
    NSURL *receiptURL = [bundleURL URLByAppendingPathComponent:@"Contents/_MASReceipt/receipt"];
    NSError *receiptError;
    BOOL isPresent = [receiptURL checkResourceIsReachableAndReturnError:&receiptError];
    if (!isPresent) {
        // Validation fails
    }



### 加载收据

### Loading the Receipt


加载收据很简单，下面是通过 [OpenSSL](https://www.openssl.org/)加载并解析 PKCS #7 包的方法：

Loading the receipt is pretty straightforward. Here is the code to load and parse the PKCS #7 envelope with OpenSSL:

    // Load the receipt file
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];

    // Create a memory buffer to extract the PKCS #7 container
    BIO *receiptBIO = BIO_new(BIO_s_mem());
    BIO_write(receiptBIO, [receiptData bytes], (int) [receiptData length]);
    PKCS7 *receiptPKCS7 = d2i_PKCS7_bio(receiptBIO, NULL);
    if (!receiptPKCS7) {
        // Validation fails
    }

    // Check that the container has a signature
    if (!PKCS7_type_is_signed(receiptPKCS7)) {
        // Validation fails
    }

    // Check that the signed container has actual data
    if (!PKCS7_type_is_data(receiptPKCS7->d.sign->contents)) {
        // Validation fails
    }

### 验证收据签名

### Verifying the Receipt Signature


当加载完收据之后，我们要做的第一件事情是确保它是完整的且未被篡改。下面是通过 [OpenSSL](https://www.openssl.org/)验证 PKCS #7 签名的方法：

Once the receipt is loaded, the first thing to do is make sure that it is authentic and unaltered. Here is the code to check the PKCS #7 signature with OpenSSL:


    // Load the Apple Root CA (downloaded from https://www.apple.com/certificateauthority/)
    NSURL *appleRootURL = [[NSBundle mainBundle] URLForResource:@"AppleIncRootCertificate" withExtension:@"cer"];
    NSData *appleRootData = [NSData dataWithContentsOfURL:appleRootURL];
    BIO *appleRootBIO = BIO_new(BIO_s_mem());
    BIO_write(appleRootBIO, (const void *) [appleRootData bytes], (int) [appleRootData length]);
    X509 *appleRootX509 = d2i_X509_bio(appleRootBIO, NULL);

    // Create a certificate store
    X509_STORE *store = X509_STORE_new();
    X509_STORE_add_cert(store, appleRootX509);

    // Be sure to load the digests before the verification
    OpenSSL_add_all_digests();

    // Check the signature
    int result = PKCS7_verify(receiptPKCS7, NULL, store, NULL, NULL, 0);
    if (result != 1) {
        // Validation fails
    }



### 解析收据

### Parsing the Receipt


在验证完收据之后，接下来就是解析收据的负载区了。下面的例子展示了如何通过 [OpenSSL](https://www.openssl.org/) 解码 DER 编码的 ASB.1 格式负载区：

Once the receipt envelope has been verified, it is time to parse the receipt’s payload. Here’s an example of how to decode the DER-encoded ASN.1 payload with OpenSSL:

    // Get a pointer to the ASN.1 payload
    ASN1_OCTET_STRING *octets = receiptPKCS7->d.sign->contents->d.data;
    const unsigned char *ptr = octets->data;
    const unsigned char *end = ptr + octets->length;
    const unsigned char *str_ptr;

    int type = 0, str_type = 0;
    int xclass = 0, str_xclass = 0;
    long length = 0, str_length = 0;

    // Store for the receipt information
    NSString *bundleIdString = nil;
    NSString *bundleVersionString = nil;
    NSData *bundleIdData = nil;
    NSData *hashData = nil;
    NSData *opaqueData = nil;
    NSDate *expirationDate = nil;

    // Date formatter to handle RFC 3339 dates in GMT time zone
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    // Decode payload (a SET is expected)
    ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
    if (type != V_ASN1_SET) {
        // Validation fails
    }

    while (ptr < end) {
        ASN1_INTEGER *integer;

        // Parse the attribute sequence (a SEQUENCE is expected)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_SEQUENCE) {
            // Validation fails
        }

        const unsigned char *seq_end = ptr + length;
        long attr_type = 0;
        long attr_version = 0;

        // Parse the attribute type (an INTEGER is expected)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_INTEGER) {
            // Validation fails
        }
        integer = c2i_ASN1_INTEGER(NULL, &ptr, length);
        attr_type = ASN1_INTEGER_get(integer);
        ASN1_INTEGER_free(integer);

        // Parse the attribute version (an INTEGER is expected)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_INTEGER) {
            // Validation fails
        }
        integer = c2i_ASN1_INTEGER(NULL, &ptr, length);
        attr_version = ASN1_INTEGER_get(integer);
        ASN1_INTEGER_free(integer);

        // Check the attribute value (an OCTET STRING is expected)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_OCTET_STRING) {
            // Validation fails
        }

        switch (attr_type) {
            case 2:
                // Bundle identifier
                str_ptr = ptr;
                ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                if (str_type == V_ASN1_UTF8STRING) {
                    // We store both the decoded string and the raw data for later
                    // The raw is data will be used when computing the GUID hash
                    bundleIdString = [[NSString alloc] initWithBytes:str_ptr length:str_length encoding:NSUTF8StringEncoding];
                    bundleIdData = [[NSData alloc] initWithBytes:(const void *)ptr length:length];
                }
                break;

            case 3:
                // Bundle version
                str_ptr = ptr;
                ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                if (str_type == V_ASN1_UTF8STRING) {
                    // We store the decoded string for later
                    bundleVersionString = [[NSString alloc] initWithBytes:str_ptr length:str_length encoding:NSUTF8StringEncoding];
                }
                break;

            case 4:
                // Opaque value
                opaqueData = [[NSData alloc] initWithBytes:(const void *)ptr length:length];
                break;

            case 5:
                // Computed GUID (SHA-1 Hash)
                hashData = [[NSData alloc] initWithBytes:(const void *)ptr length:length];
                break;

            case 21:
                // Expiration date
                str_ptr = ptr;
                ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                if (str_type == V_ASN1_IA5STRING) {
                    // The date is stored as a string that needs to be parsed
                    NSString *dateString = [[NSString alloc] initWithBytes:str_ptr length:str_length encoding:NSASCIIStringEncoding];
                    expirationDate = [formatter dateFromString:dateString];
                }
                break;

                // You can parse more attributes...

            default:
                break;
        }

        // Move past the value
        ptr += length;
    }

    // Be sure that all information is present
    if (bundleIdString == nil ||
        bundleVersionString == nil ||
        opaqueData == nil ||
        hashData == nil) {
        // Validation fails
    }



### 验证收据信息

### Verifying Receipt Information


收据包含了对应包的标识符和版本号，你需要确保这两个数据和应用里的完全一致：

The receipt contains the bundle identifier and the bundle version for which the receipt was issued. You need to make sure that both match the data of your application:

    // Check the bundle identifier
    if (![bundleIdString isEqualTo:@"io.objc.myapplication"]) {
        // Validation fails
    }

    // Check the bundle version
    if (![bundleVersionString isEqualTo:@"1.0"]) {
        // Validation fails
    }


十分重要：在发放收据的时候，bundle 的版本号是从 Info.plist 文件获取的：

IMPORTANT: When the receipt is issued, the bundle version is taken from the Info.plist file:


- 在 OS X 里，版本号来自 `CFBundleShortVersionString` 的值。
- 在 iOS 里，版本号来自 `CFBundleVersion` 值。

On OS X, the version comes from the CFBundleShortVersionString value.
On iOS, the version comes from the CFBundleVersion value.


在设置这些值的时候千万要小心，因为分发收据的时候会用到。

You should be careful when setting these values, as they will be picked up when a receipt is issued.



### 计算 GUID 哈希值

### Computing the GUID Hash


在分发收据的时候，会用到以下三个值来生成 SHA-1 哈希值：设备的 GUID (只能在设备上获取) ，一个不太清楚起什么作用的值 （type 4)，还有 bundle 的标识符 (type 2)。 SHA-1 哈希值是基于这三个值计算出来的，并且存储在收据中 (type 5)。

When the receipt is issued, three values are used to generate a SHA-1 hash: the device GUID (only available on the device), an opaque value (the type 4 attribute), and the bundle identifier (the type 2 attribute). A SHA-1 hash is computed on the concatenation of these three values and stored into the receipt (type 5 attribute).


在验证的时候将会采用相同的计算方案，如果计算的哈希值一致，那么这个收据是有效的，下图描述了整个计算的流程：

During the validation, the same computation must be done. If the resulting hash matches, then the receipt is valid. The figure below describes the computation:

![](http://img.objccn.io/issue-17/GUIDComputation.png)


为了计算这个哈希值，你需要获取设备的 GUID。

In order to compute this hash, you need to retrieve the device GUID.


#### 设备的 GUID (OS X)

#### Device GUID (OS X)


在 OS X 里，设备的 GUID 是私有网卡的 Mac 地址。获取的方法之一是使用 IOKit 框架：

On OS X, the device GUID is the MAC address of the primary network card. A way to retrieve it is to use the IOKit framework:


    #import <IOKit/IOKitLib.h>

    // Open a MACH port
    mach_port_t master_port;
    kern_return_t kernResult = IOMasterPort(MACH_PORT_NULL, &master_port);
    if (kernResult != KERN_SUCCESS) {
        // Validation fails
    }

    // Create a search for primary interface
    CFMutableDictionaryRef matching_dict = IOBSDNameMatching(master_port, 0, "en0");
    if (!matching_dict) {
        // Validation fails
    }

    // Perform the search
    io_iterator_t iterator;
    kernResult = IOServiceGetMatchingServices(master_port, matching_dict, &iterator);
    if (kernResult != KERN_SUCCESS) {
        // Validation fails
    }

    // Iterate over the result
    CFDataRef guid_cf_data = nil;
    io_object_t service, parent_service;
    while((service = IOIteratorNext(iterator)) != 0) {
        kernResult = IORegistryEntryGetParentEntry(service, kIOServicePlane, &parent_service);
        if (kernResult == KERN_SUCCESS) {
            // Store the result
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

#### Device GUID (iOS)


在 iOS 里，设备的 GUID 是一个独一无二的纯字母字符串，和应用的开发者相关：

On iOS, the device GUID is an alphanumeric string that uniquely identifies the device, relative to the application’s vendor:

    UIDevice *device = [UIDevice currentDevice];
    NSUUID *uuid = [device identifierForVendor];
    uuid_t uuid;
    [identifier getUUIDBytes:uuid];
    NSData *guidData = [NSData dataWithBytes:(const void *)uuid length:16];


#### 哈希计算

#### Hash Computation 

现在我们已经获取了设备的 GUID 值，接下来就可以计算哈希值了。计算哈希值需要用到 ASN.1 属性的原始值 (比如， OCTET-STRING 的二进制数据) ，而不是处理后的值。下面是一个 SHA-1 哈希值的计算过程和一个与 [OpenSSL](https://www.openssl.org/) 的对比：

Now that we have retrieved the device GUID, we can calculate the hash. The hash computation must be done using the ASN.1 attribute’s raw values (i.e. the binary data of the OCTET-STRING), and not on the interpreted values. Here’s an example to perform the SHA-1 hashing, and the comparison with OpenSSL:

    unsigned char hash[20];

    // Create a hashing context for computation
    SHA_CTX ctx;
    SHA1_Init(&ctx);
    SHA1_Update(&ctx, [guidData bytes], (size_t) [guidData length]);
    SHA1_Update(&ctx, [opaqueData bytes], (size_t) [opaqueData length]);
    SHA1_Update(&ctx, [bundleIdData bytes], (size_t) [bundleIdData length]);
    SHA1_Final(hash, &ctx);

    // Do the comparison
    NSData *computedHashData = [NSData dataWithBytes:hash length:20];
    if (![computedHashData isEqualToData:hashData]) {
        // Validation fails
    } 


### 批量购买

### Volume Purchase Program


如果应用支持批量购买，那么还需要验证另一个东西：收据的失效日期。我们可以在 type 21 属性里找到这个日期：

If your app supports the Volume Purchase Program, another check is needed: the receipt’s expiration date. This date can be found in the type 21 attribute:

    // If an expiration date is present, check it
    if (expirationDate) {
        NSDate *currentDate = [NSDate date];
        if ([expirationDate compare:currentDate] == NSOrderedAscending) {
            // Validation fails
        }
    }



## 处理验证结果

## Handling the Validation Result


到目前为止，如果所有的校验全部通过，那么验证的流程就算是通过了。如果任何一个步骤验证失败，那么收据就是无效的。在完成验证之后，根据平台和时间的不同，有很多种方法去处理无销收据：

So far, if all the checks are OK, then the validation passes. If any check fails, the receipt must be considered invalid. There are several ways to handle an invalid receipt, depending on the platform and the time when the validation is done.


### OS X 中的解决方案

### Handling on OS X


在 OS X 里，收据的验证过程必须在应用刚开始运行的时候完成，也就是说要在 main 方法前面。如果收据无效 (没有收据，收据不正确，收据被篡改) ，那么应用必须退出并返回 173 错误码。这个特殊的值告诉系统这个应用需要获取收据。当收到了新的收据的时候，这个应用将会重新运行。

On OS X, a receipt validation must be performed at application startup, before the main method is called. If the receipt is invalid (missing, incorrect, or tampered with), the application must exit with code 173. This particular code tells the system that the application needs to retrieve a receipt. Once the new receipt has been issued, the application is restarted.


在收到应用退出并返回代码 173 的时候， App Store 将会弹框提示登录，需要联网才能重新获取到收据。

Note that when the application exits with code 173, an App Store credential dialog will be displayed to sign in. This requires an active Internet connection, so the receipt can be issued and retrieved.


你也可以在应用的生命周期里进行收据验证，你可以自己决定如何处理无效收据：忽视，禁用，或是闪退。

You can also perform receipt validation during the lifetime of the application. It is up to you to decide how the application will handle an invalid receipt: ignore it, disable features, or crash in a bad way.


### iOS 中的解决方案

### Handling on iOS


在 iOS 里，收据验证可以在任何时候进行。如果没找到收据，你可以出发一个刷新收据的请求，告诉系统你的应用需要获取新的收据。收到了这个请求之后， App Store 会弹窗提示登录，在联网状态下会请求并获取到新的收据。

On iOS, the receipt validation can be performed at any time. If the receipt is missing, you can trigger a receipt refresh request in order to tell the system that the application needs to retrieve a new receipt. Note that after triggering a receipt refresh, an App Store credential dialog will be displayed to sign in. This requires an active Internet connection, so the receipt can be issued and retrieved.


你可以决定如何处置无销数据：忽视或是警用。

It is up to you to decide how the application will handle an invalid receipt: ignore it or disable features.


## 测试

## Testing


在测试的时候，主要的障碍是如何获取沙盒中的测试收据。

When it comes to testing, the major hurdle is to retrieve a test receipt in the sandbox environment.


苹果通过应用的证书区分生产环境和沙盒环境：

Apple is making a distinction between the production and the sandbox environment by looking at the certificate used to sign the application:


- 如果应用是开发者证书，那么收据请求会定向到沙盒环境中。
- 如果应用是苹果证书，那么收据请求会定向到生产环境中。

If the application is signed with a developer certificate, then the receipt request will be directed to the sandbox environment.
If the application is signed with an Apple certificate, then the receipt request will be directed to the production environment.


使用有效的开发者证书是非常重要的，要不然 storeagent 后台程序 (负责和 App Store 交互)无法确认你的应用是 App Store 的应用。

It is important to code sign your application with a valid developer certificate; otherwise, the storeagent daemon (the daemon responsible for communicating with the App Store) will not recognize your application as an App Store application.


### 设置测试用户

### Configuring Test Users


为了模拟沙盒环境下的真实用户，你需要定义测试用户。测试用户的操作和真实用户完全一样，唯一的区别就是买东西不用掏钱。

In order to simulate real users in the sandbox environment, you have to define test users. The test users behave the same way as real users, except that nobody gets charged when they make a purchase.


测试用户可以通过 [iTunes Connext](http://itunesconnect.apple.com/) 创建和设置。你可以定义任意数量的测试用户，每个测试用户都需要一个有效的邮箱地址，并且不能是真实的 iTunse 账号。如果邮箱供应商支持 + 号，那么你可以用邮箱别名作为测试账号：foo+us@objc.io 、 foo+uk@objc.io 和 foo+fr@objc.io 都会发送到 foo@objc.io 这个邮箱里。

Test users can be created and configured through iTunes Connect. You can define as many test users you want. Each test user requires a valid email address that must not be a real iTunes account. If your email provider supports the + sign in email addresses, you can use email aliases for the test accounts: foo+us@objc.io, foo+uk@objc.io, and foo+fr@objc.io emails will be sent to foo@objc.io.


### OS X 上的测试

### Testing on OS X


为了测试 OS X 上的收据验证，我们需要以下步骤：

To test receipt validation on OS X, go through the following steps:


- 在 Finder 中启动应用，**不要**在 Xcode 里启动，要不然启动的后台程序无法获取收据。
- 如果没有收据，必须返回 173 的错误码。这样会触发一个新的收据请求，会弹出 App Store 的登陆框，输入测试用户的账号密码登陆来获取新的测试收据。
- 如果验证通过，并且 bundle 的信息也匹配，那么就会生成收据并安装在应用包里。在获取到收据之后，应用会自动重新加载。

Launch the application from the Finder. Do not launch it from Xcode, otherwise the launchd daemon cannot trigger the receipt retrieval.
The missing receipt should make the application exit with code 173. This will trigger the request for a valid receipt. An App Store login window should appear; use the test account credentials to sign in and retrieve the test receipt.
If the credentials are valid and the bundle information matches the one you entered, then a receipt is generated and installed in the application bundle. After the receipt is retrieved, the application is relaunched automatically.


当收据重新获取之后，你可以在 Xcode 里运行你的应用，进行错误排查或者验证收据的代码的微调工作。

Once a receipt has been retrieved, you can launch the application from Xcode to debug or fine-tune the receipt validation code.


### iOS 上的测试

### Testing on iOS


为了测试 iOS 上的收据验证，需要以下步骤：

To test receipt validation on iOS, go through the following steps:


- 记得在真机上运行应用，而不是在虚拟机上。模拟机没有请求证书的 API 。
- 如果没有收据，应用会发起一个刷新收据的请求， App Store 会弹出一个登录窗口，使用测试账号登陆并获取收据。
- 如果验证通过且 buldle 的信息也和你输入的信息相一致，证书将会自动生成并且安装在应用的沙盒中。获取到收据之后，你可以进行其他校验进行确认。

Launch the application on a real device. Do not launch it in the simulator. The simulator lacks the API required to issue receipts.
The missing receipt should make the application trigger a receipt refresh request. An App Store login window should appear; use the test account credentials to sign in and retrieve the test receipt.
If the credentials are valid and the bundle information matches the one you entered, then a receipt is generated and installed in the application sandbox. After the receipt is retrieved, you can perform another validation to ensure that everything is OK.


当收据重新获取之后，你可以在 Xcode 里运行你的应用，进行错误排查或者验证收据的代码的微调工作。

Once a receipt has been retrieved, you can launch the application from Xcode to debug or fine-tune the receipt validation code.


## 安全

## Security


验证收据的代码部分必须高度精密。如果被避开或者攻击，你就失去了核实用户权限的能力，并且无法验证用户是否购买。因为，让验证收据的代码能够承受黑客的攻击变得至关重要。

The receipt validation code must be considered highly sensitive code. If it is bypassed or hacked, you lose the ability to check if the user has the right to use your application, or if he or she has paid for it. This is why it is important to protect the validation code against attackers.


注意：攻击应用的方式多种多样，所以不要尝试完全抵御所有攻击。原则很简单：尽一切可能提高攻击应用的成本。

NOTE: There are many ways of attacking an application, so don’t try to be fully hacker-proof. The rule is simple: make the hack of your application as costly as possible.


### 攻击的种类

Kinds of Attacks


所有的攻击都是从分析目标开始的：

All attacks begin with an analysis of the target:


- **静态分析** 是针对应用的二进制文件，常见的工具有： strings、 otool 、 disassembler 等等。

- **动态分析** 是通过监测应用运行时的行为进行分析，比如嵌入 debugger ，以及对已知方法嵌入断点。

Static analysis is performed on the binaries that compose your application. It uses tools like strings, otool, disassembler, etc.
Dynamic analysis is performed by monitoring the behavior of the application at runtime, for example, by attaching a debugger and setting breakpoints on known functions.


分析结束之后则会进行一些常见的攻击来绕开或者破解你的收据验证代码：

Once the analysis is done, some common attacks can be performed against your application to bypass or hack the receipt validation code:


- **替换收据** - 如果你未能成功验证收据，黑客可以用其他应用的合法收据。
- **替换字符串** - 如果你没有隐藏/混淆验证中的代码 (比如：`en0` ， `_MASReceipt` ， bundle 标识符 ， bundle 版本号) ，黑客就有机会用自己的字符串替换原始字符串。
- **绕过代码** - 如果验证收据的代码是大家都熟悉的函数或者模式，黑客可以轻松的定位收据验证的代码并且进行篡改，绕过验证。
- **替换公共库** - 如果在加密时使用了一些第三方公共库 (比如 OpenSSL) ，黑客可以用自己的库替换原始库，从而绕过所有基于这类加密方法的验证。
- **函数重载/注入** - 主要是在运行时进行攻击，通过在共有库目录里添加自己的库来给已知函数 (用户的或者系统的) 添加补丁，这个 [mach_override](https://github.com/rentzsch/mach_override) 项目让一切都变得简单。

Receipt replacement — if you fail to properly validate the receipt, an attacker can use a receipt from another application that appears to be legitimate.
Strings replacement — if you fail to hide/obfuscate the strings involved in the validation (i.e. en0, _MASReceipt, bundle identifier, or bundle version), you give the attacker the ability to replace your strings with his or her strings.
Code bypass — if your validation code uses well-known functions or patterns, an attacker can easily locate the place where the application validates the receipt and bypass it by modifying some assembly code.
Shared library swap — if you are using an external shared library for cryptography (like OpenSSL), an attacker can replace your copy of OpenSSL with his or her copy and thus bypass anything that relies on the cryptographic functions.
Function override/injection — this kind of attack consists of patching well-known functions (user or system ones) at runtime by prepending a shared library to the application’s shared library path. The mach_override project makes that dead simple.


### 安全准则

### Secure Practices

当进行收据验证的时候，需要在心中牢记以下几点安全准则：

While implementing receipt validation, there are some secure practices to follow. Here are a few things to keep in mind:


#### 必须要做

#### Dos


- **多次验证** - 在应用刚开启的时候验证一次，在应用运行期间也周期性的验证几次。验证的代码越多，你被攻击成功的概率就越低。
- **混淆字符串** - 千万不要让你验证中用到的代码对外清晰可见，这会让黑客轻易的定位并攻击验证代码。字符串混淆的手段有很多，xor-ing 、 value shifting 、 bit masking ，以及很多其他方式，让字符串变得无法阅读。
- **混淆收据验证结果** - 不要把验证结果清晰可见的展示出来 (比如："en0" ， "AppleCertificateRoot" 这种) ，这样会帮助黑客定位到你的验证代码。为了混淆字符串，你可以用一些前面提到的算法进行处理，让结果看起来是一些随机的字节。
- **控制流复杂化** - 用一个 [无实际意义的断言](http://en.wikipedia.org/wiki/Opaque_predicate) (比如一个只有运行时才有的状态) 来让别人很难跟踪你的你的代码流。这个无意义的断言通常来源于某个编译时不知道的函数运行结果。你也可以在通常不需要的地方加上一些循环， goto 语句，静态变量，或者其他任何控制流的结构。
- **使用静态库** - 如果你包含第三方的代码，尽量通过静态链接的方式加进项目中。静态代码很难篡改，更何况你也不需要会变动的代码。
- **敏感函数防止篡改** - 确保你的敏感函数没有被替换或者修改。函数有可能基于输入的参数进行各种操作，所以要做好参数的验证工作。如果函数既没有返回错误也没有返回正确的结果，那它有可能被替换或者修改过了。

Validate several times — validate the receipt at startup and periodically during the application lifetime. The more validation code you have, the more an attacker has to work.
Obfuscate strings — never leave the strings used in validation in clear form, as this can help an attacker locate or hack the validation code. String obfuscation can use xor-ing, value shifting, bit masking, or anything else that makes the string human unreadable.
Obfuscate the result of receipt validation — never leave the literal strings used in validation in clear form (i.e. "en0", "AppleCertificateRoot", etc.) as this can help an attacker locate or hack the validation code. In order to obfuscate strings, you can use apply algorithms like xor-ing, value shifting, bit masking, or anything else that makes the result appears as random bytes.
Harden the code flow — use an opaque predicate (i.e. a condition only known at runtime) to make your validation code flow hard to follow. Opaque predicates are typically made of function call results which are not known at compile time. You can also use loops, goto statements, static variables, or any control flow structure where you’d usually not need one.
Use static libraries — if you include third-party code, link it statically whenever it is possible; static code is harder to patch, and you do not depend on external code that can change.
Tamper-proof the sensitive functions — make sure that sensitive functions have not been replaced or patched. As a function can have several behaviors based on its input arguments, make calls with invalid arguments; if the function does not return an error or the correct return code, then it may be have been replaced, patched, or tampered with.


#### 千万别做

#### Don'ts


- **避免 Objective-C** - Objective-C 有很多运行时的信息，很容易被利用，进行解析/注入/替换。
- **通过安全代码使用共享库** - 共享的类库有可能会被替换或者更改。
- **使用独立代码** - 把验证的代码从业务逻辑中分离出来，从而加大定位和篡改的难度。
- **考虑收据验证** - 变化、复制、倍增验证代码，避免被侦测。
- **低估黑客的决心** - 有了足够的时间和资源，黑客肯定会成功破解你的应用。你能做的是让这个过程尽量的艰难，增大黑客攻击的成本。


Avoid Objective-C — Objective-C carries a lot of runtime information that makes it vulnerable to symbol analysis/injection/replacement. If you still want to use Objective-C, obfuscate the selectors and the calls.
Use shared libraries for secure code — a shared library can be swapped or patched.
Use separate code — bury the validation code into your business logic to make it hard to locate and patch.
Factor receipt validation — vary, duplicate, and multiply validation code implementations to avoid pattern detection.
Underestimate the determination of attackers — with enough time and resources, an attacker will ultimately succeed in cracking your application. What you can do is make the process more painful and costly.














---

原文 [Receipt Validation](http://www.objc.io/issue-17/receipt-validation.html)
