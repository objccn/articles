## 数据存储

在计算机上存储文本很容易。我们以字母或字符作为一个基本单元，建立了一个从数字到字符编码的简单映射来进行编码。图形信息则不同，有很多不同的方式来表示图像，每种方式的优点和缺点也都各有不同。

文本是线性且一维的。撇开文字方向的问题，我们只需要知道序列中的下一个元素是什么就可以有效的存储文字。

图像则更复杂。首先，它们是二维的，所以我们需要考虑如何表示图像中某个特定位置的值。然后，我们需要考虑具体的值应该如何量化。另外，根据我们捕捉图像的途径，也会有不同的方式来编码图形数据。一般来说，最直观的方式是将其存为位图数据，可如果你想处理一组几何图形，效率就会偏低。一个圆形可以只由三个值 (两个坐标值和半径) 来表示，使用位图会使文件更大，却只能做粗略的近似。

以上所说的问题向我们展示了不同图像格式之间的第一个区别：位图与矢量图像。不同于位图把值存在阵列中，矢量格式存储的是绘图图像的指令。在处理一些可以被归纳为几何形状的简单图像时，这样做显然更有效率；但面对照片数据时矢量储存就会显得乏力了。建筑师设计房屋更倾向于使用矢量的方式，因为矢量格式并不仅仅局限于线条的绘制，也可以用渐变或图案的填充作为展示，所以利用矢量方式完全可以生成房屋的拟真渲染图。

用于填充的图案单元则更适合被储存为一个位图，在这种情况下，我们可能需要一个混合格式。一个非常普遍的混合格式的一个例子是 [PostScript](https://en.wikipedia.org/wiki/PostScript)，(或者时下比较流行的衍生格式，[PDF](https://en.wikipedia.org/wiki/Portable_Document_Format))，它基本上是一个用于绘制图像的描述语言。上述格式主要针对印刷业，而 NeXT 和 Adobe 开发的 [Display Postscript](http://en.wikipedia.org/wiki/Display_PostScript) 则是进行屏幕绘制的指令集。PostScript 能够排布字母，甚至位图，这使得它成为了一个非常灵活的格式。

### 矢量图像

矢量格式的一大优点是缩放。矢量格式的图像其实是一组绘图指令，这些指令通常是独立于尺寸的。如果你想扩大一个圆形，只需在绘制前扩大它的半径就可以了。位图则没这么容易。最起码，如果扩大的比例不是二的倍数，就会涉及到重绘图像，并且各个元素都只是简单地增加尺寸，成为一个色块。由于我们不知道这图像是一个圆形，所以无法确保弧线的准确描绘，效果看起来肯定不如按比例绘制的线条那样好。也因此，在像素密度不同的设备中，矢量图像作为图形资源会非常有用。位图的话，同样的图标，在视网膜屏幕之前的 iPhone 上看起来并没有问题，在拉伸两倍后的视网膜屏幕上看起来就会发虚。就好像仅适配了 iPhone 的 App 运行在 iPad 的 2x 模式下就不再那么清晰了。

虽然 Xcode 6 已经支持了 PDF 格式，但迄今仍不完善，只是在编译时将其创建成了位图图像。最常见的矢量图像格式为 [SVG](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics)，在 iOS 中也有一个渲染 SVG 文件的库，[SVGKit](https://github.com/SVGKit/SVGKit)。

### 位图

大部分图像都是以位图方式处理的，从这里开始，我们就将重点放在如何处理它们上。第一个问题，是如何表示两个维度。所有的格式都以一系列连续的行作为单元，而每一行则水平地按顺序存储了每个像素。大多数格式会按照行的顺序进行存储，但是这并不绝对，比如常见的交叉格式，就不严格按照行顺序。其优点是当图像被部分加载时，可以更好的显示预览图像。在互联网初期，这是一个问题，随着数据的传输速度提升，现在已经不再被当做重点。

表示位图最简单的方法是将二进制作为每个像素的值：一个像素只有开、关两种状态，我们可以在一个字节中存储八个像素，效率非常高。不过，由于每一位只有最多两个值，我们只能储存两种颜色。考虑到现实中的颜色数以百万计，上述方法听起来并不是很有用。不过有一种情况还是需要用到这样的方法：遮罩。比如，图像的遮罩可以被用于透明性，在 iOS 中，遮罩被应用在 tab bar 的图标上 (即便实际图标不是单像素位图)。

如果要添加更多的颜色，有两个基本的选择：使用一个查找表，或直接用真实的颜色值。[GIF](https://en.wikipedia.org/wiki/GIF) 图像有一个颜色表 (或色彩面板)，可以存储最多 256 种颜色。存储在位图中的值是该查询列表中的索引值，对应着其相应的颜色。所以，GIF 文件仅限于 256 色。对于简单的线条图或纯色图，这是一种不错的解决方法。但对于照片来说，就会显示的不够真实，照片需要更精细的颜色深度。进一步的改进是 [PNG](https://en.wikipedia.org/wiki/Portable_Network_Graphics) 文件，这种格式可以使用一个预置的色板或者独立的通道，它们都支持可变的颜色深度。在一个通道中，每个像素的颜色分量 (红，绿，蓝，即 RGB，有时添加透明度值，即RGBA) 是直接指定的。

GIF 和 PNG 对于具有大面积相同颜色的图像是最好的选择，因为它们使用的 (主要是基于游程长度编码的) 压缩算法可以减少存储需求。这种压缩是无损的，这意味着图像质量不会被压缩过程影响。

一个有损压缩图像格式的例子是 [JPEG](https://en.wikipedia.org/wiki/JPEG)。创建 JPEG 图像时，通常会指定一个与图像质量相关的压缩比值参数，压缩程度过高会导致图像质量恶化。JPEG 不适用于对比鲜明的图像 (如线条图)，其压缩方式对类似区域的图像质量损害会相对严重。如果某张截图中包含了文本，且保存为 JPEG 格式，就可以清楚地看到：生成的图像中字符周围会出现杂散的像素点。在大部分照片中不存在这个问题，所以照片主要使用 JPEG 格式。

总结：就放大缩小而言，矢量格式 (如 SVG) 是最好的。对比鲜明且颜色数量有限的线条图最适合 GIF 或 PNG (其中 PNG 更为强大)，而照片，则应该使用 JPEG。当然，这些都不是不可逾越的规则，不过通常而言，对一定的图像质量与图像尺寸而言，遵守规则会得到最好的结果。

## 处理图像数据

在 iOS 中有几个类是用来处理位图数据的：`UIImage` (UIKit)，`CGImage` (Core Graphics) 和 `CIImage` (Core Image)。在创建以上类的实例之前，由 `NSData` 持有实际的数据。获得一个 `UIImage` 最简单的方法是使用 `imageWithContentsOfFile:` 方法，或者根据其来源，也可以使用 `imageWithCGImage:`，`imageWithCIImage:` 或者 `imageWithData:`。有多个不同却相似的类看起来有点多余，部分原因是因为它们来自不同的框架，对于图像储存的优化方式也各有侧重，通常情况下，不同类型之间是可以轻松转换的。

## 从相机捕获图像

为了从相机得到一个图像，我们需要创建一个 `AVCaptureStillImageOutput` 对象。然后，我们可以使用 `captureStillImageAsynchronouslyFromConnection: completionHandler:` 方法。它的 `handler` 是以一个 `CMSampleBufferRef` 类型为参数的 block。我们可以利用 `AVCaptureStillImageOutput` 中的类方法 `jpegStillImageNSDataRepresentation:` 将其转换为一个 `NSData` 对象, 接着，我们使用 `imageWithData:` (上文提到过) 来得到一个 `UIImage`。在这个过程中，有许多参数可以调整，例如曝光控制或聚焦设定，光补偿，闪光灯，甚至 ISO 设置 (仅 iOS 8)。设置会被应用到一个 `AVCaptureDevice`，这个对象代表着一个存在于设备上的相机。

## 用程序操作图像

简单的图像处理方法是使用 UIKit 的 `UIGraphicsBeginImageContext` 方法。调用之后，你就可以在当前图形上下文中绘制一些内容，当然也包括图像本身。在我自己的 App —— Stereogram 中，我使用这个方法把两个方形的图像拼接，并在图片上方添加了一个区域，放置了两个点用于强调。代码如下：

```
-(UIImage*)composeStereogramLeft:(UIImage *)leftImage right:(UIImage *)rightImage
{
    float w = leftImage.size.width;
    float h = leftImage.size.height;
    UIGraphicsBeginImageContext(CGSizeMake(w * 2.0, h + 32.0));
    [leftImage drawAtPoint:CGPointMake(0.0, 32.0)];
    [rightImage drawAtPoint:CGPointMake(w, 32.0)];
    float leftCircleX = (w / 2.0) - 8.0;
    float rightCircleX = leftCircleX + w;
    float circleY = 8.0;
    [[UIColor blackColor] setFill];
    UIRectFill(CGRectMake(0.0, 0.0, w * 2.0, 32.0));

    [[UIColor whiteColor] setFill];
    CGRect leftRect = CGRectMake(leftCircleX, circleY, 16.0, 16.0);
    CGRect rightRect = CGRectMake(rightCircleX, circleY, 16.0, 16.0);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:leftRect];
    [path appendPath:[UIBezierPath bezierPathWithOvalInRect:rightRect]];
    [path fill];
    UIImage *savedImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return savedImg;
}
```

在画布上排布好图像并添加了两个实心圆后，我们就可以调用一个方法把之前绘制好的图形环境转换成一个 `UIImage`。该方法的输出如下所示：

![Stereogram output](/images/issues/issue-21/stereogram-output.jpg)

这张图片由两台位置稍有不同的相机拍摄的两张照片，以及一条具有两个中心白点的用来辅助观察的黑色条带合成而来。

相较而言，将实际的像素混合排布是一件麻烦的事情。在一张立体图像中，我们有两张相邻的照片，我们需要使我们的眼睛 (有时可以靠斗眼) 看到 3D 效果。还有一种选择是所谓的 [红蓝 3D](http://www.3dtv.at/knowhow/anaglyphcomparison_en.aspx)(Anaglyphs)，你可以使用彩色 3D 眼镜观看的红/绿图像。(下面列出的函数，实现了链接中的 Optimized Anaglyphs 方法。)

在以这种方式处理单独的像素时，我们要使用 `CGBitmapContextCreate` 方法创建一个位图绘制环境，它包括一个颜色空间 (例如 RGB)。然后，我们可以遍历位图 (包括左边和右边的照片)，并获得在各个颜色通道值。例如，我们维持一张图片中绿色和蓝色的原值，然后将蓝色和绿色的值按一定方式计算后赋值给另一张图片的红色值：

```
UInt8 *rightPtr = rightBitmap;
UInt8 *leftPtr = leftBitmap;
UInt8 r1, g1, b1;
UInt8 r2, g2, b2;
UInt8 ra, ga, ba;

for (NSUInteger idx = 0; idx < bitmapByteCount; idx += 4) {
    r1 = rightPtr[0]; g1 = rightPtr[1]; b1 = rightPtr[2];
    r2 = leftPtr[0]; g2 = leftPtr[1]; b2 = leftPtr[2];

    // r1/g1/b1 右侧图像，用于计算合并值
    // r2/g2/b2 左侧图像，用于被合并值赋值
    // ra/ga/ba 合并后的像素

    ra = 0.7 * g1 + 0.3 * b1;
    ga = b2;
    ba = b2;

    leftPtr[0] = ra;
    leftPtr[1] = ga;
    leftPtr[2] = ba;
    rightPtr += 4; // 指向下一个像素 (4字节, 包括透明度 alpha 值)
    leftPtr += 4;
}

CGImageRef composedImage = CGBitmapContextCreateImage(_leftContext);
UIImage *retval = [UIImage imageWithCGImage:composedImage];
CGImageRelease(composedImage);
return retval;
```

在这个方法中，我们可以访问实际的像素的所有信息，做任何我们喜欢的事情。不过，最好先查询 [Core Image](http://objccn.io/issue-21-6/) 中是否已经有滤镜可用，因为它们使用更容易，并且在通常情况下，它们比一些单像素值的处理方式更优。

## 元数据

用于存储图像信息的标准格式是 [Exif](https://en.wikipedia.org/wiki/Exchangeable_image_file_format)(可交换图像文件格式)。在照片中，通常会捕获照相的日期和时间，快门速度和光圈，如果设备支持，还包括 GPS 坐标。这是基于 [TIFF](https://en.wikipedia.org/wiki/Tagged_Image_File_Format)(标签图像文件格式) 的一种标签系统。虽然它有很多缺陷，可作为一个现行标准，确实没有更好的选择。通常情况下，有些方式会设计的更好，但我们大家所使用的相机都不支持。

在 iOS 中，可以使用 `CGImageSourceCopyPropertiesAtIndex` 方法访问 Exif 信息。这个方法会返回一个包含所有相关信息的字典。不过，不要过于依赖这些附加的信息。由于供应商定义的扩展约定 (这不是一个通用的标准) 错综复杂，数据经常被丢失或损坏，尤其是当图像经过许多不同的应用程序 (如图像编辑器等) 处理过后。一般来说，当图像被上传到网络服务器上时，这些信息也会被抹掉；这些信息中有一些属于敏感信息，例如 GPS 数据。出于对隐私的保护，这些信息常常会被删除。显然，NS​​A (美国国家安全局) 就在收割它们 [XKeyscore 程序](https://en.wikipedia.org/wiki/XKeyscore)中的 Exif 数据。

## 总结

处理图像在有些时候是一个相当复杂的问题。图像处理这个问题已经存在了一段时间，所以针对不同方面，会存在许多不同的框架。有时候，你不得不深入底层的 C 函数调用，解决随之而来的手动内存管理问题。再者，图像的来源很多，每个来源都会需要处理特定且不同的边界问题。不过，iOS 中最大的问题其实是内存：随着相机和屏幕分辨率越来越好，图像的尺寸也开始变大。iPhone 5S 有一个 800 万像素的摄像头；如果每个像素被存储在4个字节 (分别用于三个颜色信道，加上一个不透明性)，就会产生 32 兆的数据。如果需要添加几个工作副本或图像的预览，我们会很快在处理​​多张图片或幻灯片时遇到麻烦。再加上文件系统的写入也并不是非常快，所以很有必要进行一些优化，以确保你的 iOS 应用程序运行流畅。

---

 

原文 [Image Formats](http://www.objc.io/issue-21/image-formats.html)
