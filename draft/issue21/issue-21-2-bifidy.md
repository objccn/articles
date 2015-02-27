## Storing Data

## 数据存储

Storing text on a computer is easy. We have letters/characters as a fundamental unit, and there is a fairly straightforward mapping from a number to the character it encodes. This is not the case with graphical information. There are different ways to represent images, all with different pros and cons.

在计算机上存储文本很容易。我们以字母或字符作为一个基本单元，建立了一个从数字到字符编码的简单映射。图形信息则不同，有很多不同的方式来表示图像，每种方式的优点和缺点也都各有不同。

Text is also linear, and one-dimensional. Leaving aside the question of what the text direction is, all we need is to know what the next item in the sequence is.

文本是线性且一维的。撇开文字方向的问题，我们只需要知道序列中的下一个元素是什么就可以有效的存储文字。

Images are more complicated. For a start, they are two-dimensional, so we need to think about identifying where in our image a particular value is. Then, we need to consider what a value is. Depending on what we want to capture, there are different ways of encoding graphical data. The most intuitive way these days seems to be as bitmap data, but that would not be very efficient if you wanted to deal with a collection of geometrical figures. A circle can be represented by three values (two coordinates and the radius), whereas a bitmap would not only be much larger in size, but also only a rough approximation.

图像则更复杂。首先，他们是二维的，所以我们需要考虑如何表示图像中某个特定位置的值。然后，我们需要考虑具体的值应该如何量化。另外，根据我们捕捉图像的途径，也会有不同的方式来编码图形数据。一般来说，最直观的方式是将其存为位图数据，可如果你想处理一组几何图形，效率就会偏低。一个圆形可以只由三个值（两个坐标和半径）来表示，使用位图会使文件更大，却只能做粗略的近似。

This, then, leads us to the first distinction between different image formats: bitmaps versus vector images. While bitmaps store values in a grid, vector formats store instructions for drawing an image. This is obviously much more efficient when dealing with sparse images which can be reduced to a few geometric shapes; it does not really work well for photographic data. An architect designing a house would want to use a vector format. Vector formats do not have to be restricted to line drawings, as gradient or pattern fills can also be represented, so a realistic rendering of the resulting house could still be produced from a line drawing fairly efficiently.

以上所说的问题向我们展示了不同图像格式之间的第一个区别：位图与矢量图像。不同于位图根据像素存值，矢量格式存储了图像的绘图指令。在处理一些可以被归纳为几何形状的简单图像时，这样做显然更有效率；但面对照片数据时矢量储存就会显得乏力了。建筑师设计房屋更倾向于使用矢量的方式，因为矢量格式并不仅仅局限于线条的绘制，也可以用渐变或图案的填充作为展示，所以利用矢量方式完全可以生成房屋的拟真渲染图。

A brick pattern would be more easily stored as a bitmap, so in this case we might have a hybrid format. An example for a very common hybrid format is [PostScript](https://en.wikipedia.org/wiki/PostScript), (or the nowadays more popular follow-up, [PDF](https://en.wikipedia.org/wiki/Portable_Document_Format)), which is basically a description language for drawing images. The target is mainly paper, but NeXT and Adobe developed [Display Postscript](http://en.wikipedia.org/wiki/Display_PostScript) as an instruction set for drawing on screens. PostScript is also capable of placing letters, and even bitmaps, which makes it a very versatile format.

用于填充的图案单元则更适合被储存为一个位图，在这种情况下，我们可能需要一个混合格式。一个非常普遍的混合格式的一个例子是 [PostScript](https://en.wikipedia.org/wiki/PostScript)，（或者时下比较流行的衍生格式，[PDF](https://en.wikipedia.org/wiki/Portable_Document_Format)），它基本上是一个用于绘制图像的描述语言。上述格式主要针对印刷业，而 NeXT 和 Adobe 开发的 [Display Postscript](http://en.wikipedia.org/wiki/Display_PostScript) 则是进行屏幕绘制的指令集。PostScript 能够排布字母，甚至位图，这使得它成为了一个非常灵活的格式。

### Vector Images

### 矢量图像

A big advantage of vector formats is scaling. As the image is a set of drawing instructions, it is generally independent of size. If you want to enlarge your circle, you simply scale up the radius before drawing it. With a bitmap, this is not easily possible. For a start, scaling to any factor that is not a multiple of two involves mangling the image, and the individual elements would simply increase in size, leading to a blocky image. As we do not know that the image is a circle, we cannot smooth the circular lines properly, and it will not look as good as a line drawn to scale. This is why vector images are very useful as graphical assets on devices with different pixel density. The same icon which looks OK on a pre-Retina iOS device will not look as crisp when scaled up twice for display on a Retina iPhone—just like an iPhone-only app does not look as good when run in 2x mode on an iPad.

矢量格式的一大优点是缩放。将图像作为一组绘图指令时，它的文件大小通常是独立的。如果你想扩大一个圆形，只需在被绘制出来前扩大它的半径。位图则没这么容易。最起码，如果扩大的比例不是二的倍数，就会涉及到重绘图像，并且各个元素都会增加尺寸，成为一个图块。由于我们不知道这图像是一个圆形，所以无法确保弧线的准确描绘，看起来或许还不如按比例绘制的线条。也因此，在象素密度不同的设备中，矢量图像作为图形资源会非常有用。同样的图标，在视网膜屏幕之前的 iPhone 上看起来并没有问题，在拉升两倍后的视网膜屏幕上看起来就会发虚。就好像仅适配了 iPhone 的 App 运行在 iPad 的 2x 模式下就不再那么清晰了。

There is support for PDF assets in Xcode 6, but it seems to be rather sketchy at the moment, and still creates bitmap images at compile time on iOS. The most common vector image format is [SVG](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics), and there is a library for rendering SVG files on iOS, [SVGKit](https://github.com/SVGKit/SVGKit).

虽然 Xcode 6 已经支持了 PDF 格式，但迄今仍不完善，只是 iOS 在其编译时将其创建成了位图图像。最常见的矢量图像格式为 [SVG](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics)，在 iOS 中也有一个渲染 SVG 文件的库，[SVGKit](https://github.com/ SVGKit / SVGKit)。

### Bitmaps

### 位图

Most image work deals with bitmaps, and from now on, we will focus on how they can be handled. The first question is how to represent the two dimensions. All formats use a sequence of rows for that, whereas pixels are stored in a horizontal sequence. Most formats then store rows sequentially, but that is by no means the only way—interleaved formats, where the rows are not in strict sequential order, are also common. Their advantage is that a better preview of the image can be shown when it is partially loaded. With increasing data transmission speeds, that is now less of an issue than it was in the early days of the web.

大部分图像都是以位图方式处理的，从这里开始，我们就将重点放在如何处理它们上。第一个问题，是如何表示两个维度。所有的格式都以水平行为单元，而每一行则按顺序存储了该水平序列的每个像素。大多数格式会按照行的顺序进行存储，但是这并不绝对，比如常见的交叉格式，就不严格按照行顺序。其优点是当图像被部分加载时，可以更好的显示预览图像。在互联网初期，这是一个问题，随着数据的传输速度提升，现在已经不再被当做重点。

The simplest way to represent bitmaps is as binary pixels: a pixel is either on, or off. We can then store eight pixels in a byte, which is very efficient. However, we can only have two colors, one for each state of a bit. While this does not sound very useful in the age of millions of colors, there is one application where this is still all that is needed: masking. Image masks can, for example, be used for transparency, and in iOS they are used in tab bar icons (even though the actual icons are not one-pixel bitmaps).

表示位图最简单的方法是将二进制作为每个像素的值：一个像素只有开、关两种状态，我们可以在一个字节中存储八个像素，性价比很高。不过，由于每一位只有最多两个值，我们只能储存两种颜色。考虑到现实中的颜色数以百万计，上述方法听起来并不是很有用。不过有一种情况还是需要用到这样的方法：遮罩。比如，图像的遮罩可以被用于透明性，在 iOS 中，遮罩被应用在标签栏的图标上（即便实际图标不是单像素位图）。

For adding more colors, there are two basic options: a look-up table, or actual color values. [GIF](https://en.wikipedia.org/wiki/GIF) images have a color table (or a palette), which can store up to 256 colors. The values stored in the bitmap are indices into this look-up table, which specifies their respective color. As a result, GIFs are limited to 256 colors only. This is fine for simple line drawings or diagrams with filled colors, but not really enough for photos, which require a greater color depth. A further improvement are [PNG](https://en.wikipedia.org/wiki/Portable_Network_Graphics) files, which can either use a palette or separate channels, both supporting a variety of color depths. In a channel, the color components of each pixel (red, green, and blue, RGB, sometimes adding opacity/alpha, RGBA) are specified directly.

如果要添加更多的颜色，有两个基本的选择：一个用于查询的列表，或真实的颜色值。[GIF](https://en.wikipedia.org/wiki/GIF) 图像有一个颜色表（或色彩面板），可以存储多达256种颜色。存储在位图中的值是该查询列表中的索引值，对应着其相应的颜色。所以，GIF 文件也仅限于256色。作为简单的线条图或纯色图，这是一种不错的解决方法。但对于照片来说，就会显示的不够真实，照片需要更精细的颜色深度。进一步的改进是 [PNG](https://en.wikipedia.org/wiki/Portable_Network_Graphics) 文件，这种格式可以使用一个预置的色板或独立的通道，且它们都支持多种颜色深度。在一个通道中，每个像素的颜色分量（红，绿，蓝，即 RGB，有时添加透明度值，即RGBA）是直接指定的。

GIF and PNG are best for images with large areas of identical color, as they use compression algorithms (mainly based on run-length encoding) to reduce the storage requirements. The compression is lossless, which means that the image quality is not affected by the process.

GIF 和 PNG 对于具有大面积相同颜色的图像是最好的选择，因为它们使用的压缩算法（主要是基于游程长度编码）可以减少存储需求。这种压缩是无损的，这意味着图像质量不会被压缩过程影响。

An example for an image format that has lossy compression is [JPEG](https://en.wikipedia.org/wiki/JPEG). When creating JPEG images, it is often possible to specify a parameter for quality/compression ratio, and here, a better compression leads to a deterioration in the image quality. JPEG is not suited for images with sharp contrasts (such as line drawings), as the compression leads to artifacts around such areas. This can clearly be seen when a screenshot containing rendered text is saved in JPEG format: the resulting image will have stray pixels around the letters. This is not a problem with most photos, and photos are the main use case for JPEGs.

一个有损压缩图像格式的例子是 [JPEG](https://en.wikipedia.org/wiki/JPEG)。创建JPEG图像时，通常会指定一个与图像质量相关的压缩比值参数，压缩程度过高会导致图像质量恶化。JPEG不适用于对比鲜明的图像（如线条图），其压缩方式对类似区域的图像质量损害会相对严重。如果某张截图中包含了文本，且保存为JPEG格式，就可以清楚地看到：生成的图像中字符周围会出现杂散的像素点。在大部分照片中这类情况是可以接受的，所以照片主要使用JPEG格式。

To summarize: for scalability, vector formats (such as SVG) are best. Line drawings with sharp contrast and limited amount of colors work best for GIF or PNG (where PNG is the more powerful format), and for photos, you should use JPEG. Of course, these are not unbreakable laws, but generally lead to the best results in terms of quality/image size.

总结：就放大缩小而言，矢量格式（如 SVG）是最好的。对比鲜明且颜色数量有限的线条图最适合 GIF 或 PNG（其中 PNG 更为强大），而照片，则应该使用 JPEG。当然，这些都不是不可逾越的规则，不过通常而言，最好的结果取决于图像质量与图像尺寸的比值。

## Handling Image Data

##处理图像数据

There are several classes for handling bitmap data in iOS: `UIImage` (UIKit), `CGImage` (Core Graphics), and `CIImage` (Core Image). There is also `NSData` for holding the actual data before creating one of those classes. Getting a `UIImage` is easy enough using the `imageWithContentsOfFile:` method, and for other sources we have `imageWithCGImage:`, `imageWithCIImage:`, and `imageWithData:`. This large number of different-but-similar classes seems somewhat superfluous, but it is partly caused by optimizing aspects of image storage for different purposes across the different frameworks, and it is generally possible to easily convert between the different types.

在 iOS 中有几个类是用来处理位图数据的：`UIImage`（UIKit），`CGImage`（Core Graphics），和 `CIImage`（Core Image）。在创建以上类的实例之前，还有 `NSData` 持有实际的数据。获得一个`UIImage`，最简单的是使用 `imageWithContentsOfFile:` 方法，或者根据其来源，也可以使用 `imageWithCGImage:`，`imageWithCIImage:` 或者 `imageWithData:`。有多个不同却相似的类看起来有点多余，实际上它们来自不同的框架，对于图像储存的优化方式也不相同，通常情况下，不同类型之间是可以轻松转换的。


## Capturing an Image from the Camera

## 从相机捕获图像

To get an image from the camera, we need to set up an `AVCaptureStillImageOutput` object. We can then use the `captureStillImageAsynchronouslyFromConnection:completionHandler:` method. Its handler is a block that is called with a `CMSampleBufferRef` parameter. We can convert this into an `NSData` object with `AVCaptureStillImageOutput`'s `jpegStillImageNSDataRepresentation:` class method, and then, in turn, we use the method `imageWithData:` (mentioned above) to get to a `UIImage`. There are a number of parameters that can be tweaked in the process, such as exposure control or the focus setting, low-light boost, flash, and even the ISO setting (from iOS 8 only). The settings are applied to an `AVCaptureDevice`, which represents the camera on devices which have one.

为了从相机得到一个图像，我们需要创建一个 `AVCaptureStillImageOutput`对象。然后，我们可以使用 `captureStillImageAsynchronouslyFromConnection: completionHandler:` 方法。它的 `handler` 是以一个 `CMSampleBufferRef` 类型为参数的 block。我们可以利用 `AVCaptureStillImageOutput` 中的类方法 `jpegStillImageNSDataRepresentation:` 将其转换为一个 `NSData` 对象, 接着，我们使用 `imageWithData:` (上文提到过) 来得到一个 `UIImage`。在这个过程中，有许多参数可以调整，例如曝光控制或聚焦设定，光补偿，闪光灯，甚至 ISO 设置（仅 iOS 8）。设置会被应用到一个 `AVCaptureDevice`，它表示在一个存在于设备上的相机。

## Manipulating Images Programmatically

## 图像操作编程

A straightforward way to manipulate images is to use UIKit's `UIGraphicsBeginImageContext` function. You can then draw in the current graphics context, and also include images directly. In one of my own apps, Stereogram, I use this to place two square images next to each other, and add a region above them with two dots for focusing. The code for that is as follows:

简单的图像处理方法是使用UIKit的 `UIGraphicsBeginImageContext` 方法。那么你就可以在当前图形环境下绘制，也包括图像本身。在我自己的 App —— Stereogram 中，我使用这个把两个方形的图像拼接，并在图片上面添加了一个区域，放置了两个点用于集中。代码如下：

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

After placing the images on the canvas and adding two filled circles, we can turn the graphics context into a `UIImage` with a single method call. The output of that method looks as follows:

在画布上排布好图像并添加了两个实心圆后，我们就可以调用一个方法把之前绘制好的图形环境转换成一个 `UIImage`。该方法的输出如下所示：

![Stereogram output](/images/issue-21/stereogram-output.jpg)

![Stereogram output](http://img.objccn.io/issue-21/stereogram-output.jpg)

It is composed of the two photos taken from slightly different camera positions, and a black strip with two centered white dots to aid the viewing process.

这张图片由两台位置稍有不同的相机拍摄的两张照片，以及一条具有两个中心白点的黑色条带，用来辅助观察。

It is a bit more complex if we want to mess with the actual pixel values. With a stereogram, we have two photos next to each other, and we need to align our eyes (or go cross-eyed) to see the 3D effect. An alternative to this is a so-called [anaglyph](http://www.3dtv.at/knowhow/anaglyphcomparison_en.aspx), a red/green image that you use colored 3D glasses to look at. (The function listed below implements the Optimized Anaglyphs method on that page.)

将实际的像素值重新排布是一件比较麻烦的事情。在一张立体图像中，我们有两张相邻的照片，我们需要使我们的眼睛（有时可以靠斗眼）看到 3D 效果。有一种选择是所谓的 [anaglyph（浮雕）](http://www.3dtv.at/knowhow/anaglyphcomparison_en.aspx)，你可以使用彩色3D眼镜观看的红/绿图像。（下面列出的函数，实现了链接中的 Optimized Anaglyphs 方法。）

For working with individual pixels in this way, we have to create a context with `CGBitmapContextCreate`, which includes a color space (such as RGB). We can then iterate over the bitmaps (left and right photos), and get at the individual color channel values. For example, we keep the green and blue values of one image as they were, and merge the green and blue values of the other photo into the red value:

对于以这种方式单独的像素的工作中，我们要使用 `CGBitmapContextCreate` 方法创建一个位图绘制环境，它包括一个颜色空间（例如 RGB）。然后，我们可以遍历位图（包括左边和右边的照片），并获得在各个颜色通道值。例如，我们维持一张图片中绿色和蓝色的原值，然后将蓝色和绿色的值按一定方式计算后赋值给另一张图片的红色值：

```
UInt8 *rightPtr = rightBitmap;
UInt8 *leftPtr = leftBitmap;
UInt8 r1, g1, b1;
UInt8 r2, g2, b2;
UInt8 ra, ga, ba;

for (NSUInteger idx = 0; idx < bitmapByteCount; idx += 4) {
    r1 = rightPtr[0]; g1 = rightPtr[1]; b1 = rightPtr[2];
    r2 = leftPtr[0]; g2 = leftPtr[1]; b2 = leftPtr[2];

    // r1/g1/b1 is the right hand side photo, which is merged in
    // r1/g1/b1 右侧图像，用于计算合并值
    // r2/g2/b2 is the left hand side photo which the other is merged into
    // r2/g2/b2 左侧图像，用于被合并值赋值
    // ra/ga/ba is the merged pixel
    // ra/ga/ba 合并后的像素

    ra = 0.7 * g1 + 0.3 * b1;
    ga = b2;
    ba = b2;

    leftPtr[0] = ra;
    leftPtr[1] = ga;
    leftPtr[2] = ba;
    rightPtr += 4; // move to the next pixel (4 bytes, includes alpha value)
    // 指向下一个像素 (4字节, 包括透明度 alpha 值)
    leftPtr += 4;
}
CGImageRef composedImage = CGBitmapContextCreateImage(_leftContext);
UIImage *retval = [UIImage imageWithCGImage:composedImage];
CGImageRelease(composedImage);
return retval;
```

With this method, we have full access to the actual pixels, and can do with them whatever we like. However, it is worth checking whether there are already filters available via [Core Image](/issue-21/core-image-intro.html), as they will be much easier to use and generally more optimized than any processing of individual pixel values.

在这个方法中，我们已经开始操作实际的像素，做任何我们喜欢的事情。不过，最好先查询 [Core Image](http://objccn.io/issue-21-6/) 中是否已经有滤镜可用，因为它们使用更容易，并且在通常情况下，它们比一些单像素值的处理方式更优。

## Metadata

## 元数据

The standard format for storing information about an image is [Exif](https://en.wikipedia.org/wiki/Exchangeable_image_file_format) (Exchangeable image file format). With photos, this generally captures date and time, shutter speed and aperture, and GPS coordinates if available. It is a tag-based system, based on [TIFF](https://en.wikipedia.org/wiki/Tagged_Image_File_Format) (Tagged Image File Format). It has a lot of faults, but as it's the de facto standard, there isn't really a better alternative. As is often the case, there are other methods available which are better designed, but not supported by the cameras we all use.

用于存储图像信息的标准格式是 [Exif](https://en.wikipedia.org/wiki/Exchangeable_image_file_format)（可交换图像文件格式）。在照片中，通常会捕获照相的日期和时间，快门速度和光圈，如果设备支持，还包括 GPS 坐标。这些都基于 [TIFF](https://en.wikipedia.org/wiki/Tagged_Image_File_Format)（标签图像文件格式），它是一个基于标签的系统。虽然它有很多缺陷，可作为一个现行标准，确实没有更好的选择。通常情况下，有些方式会设计的更好，但我们使用的所有相机都不支持。

Under iOS, it is possible to access the Exif information using `CGImageSourceCopyPropertiesAtIndex`. This returns a dictionary containing all the relevant information. However, do not rely on any information being attached. Due to the complexities of vendor-specific extensions to the convention (it's not a proper standard), the data is often missing or corrupted, especially when the image has passed through a number of different applications (such as image editors, etc.). Usually the information is also stripped when an image is uploaded to a web server; some of it can be sensitive, for example, GPS data. For privacy reasons, this is often removed. Apparently the NSA is harvesting Exif data in its [XKeyscore program](https://en.wikipedia.org/wiki/XKeyscore).

在 iOS 中，可以使用 `CGImageSourceCopyPropertiesAtIndex` 方法访问 Exif 信息。这个方法会返回一个包含所有相关信息的字典。不过，不要过于依赖这些附加的信息。由于供应商定义的扩展约定（这不是一个通用的标准）错综复杂，数据经常被丢失或损坏，尤其是当图像经过许多不同的应用程序（如图像编辑器等）处理过后。一般来说，当图像被上传到网络服务器上时，这些信息也会被抹掉；这些信息中有一些属于敏感信息，例如 GPS 数据。出于对隐私的保护，这些信息常常会被删除。显然，NS​​A（国家安全局）就在搜集它们 [XKeyscore 程序](https://en.wikipedia.org/wiki/XKeyscore)中的 Exif 数据。

## Summary

## 总结

Handling images can be a fairly complex issue. Image processing has been around for some time, so there are many different frameworks concerned with different aspects of it. Sometimes you have to dig down into C function calls, with the associated manual memory management. Then there are many different sources for images, and they can all handle certain edge cases differently. The biggest problem on iOS, however, is memory: as cameras and screen resolutions get better, images grow in size. The iPhone 5s has an 8-megapixel camera; if each pixel is stored in 4 bytes (one each for the three color channels, plus one for opacity), we have 32 MB. Add a few working copies or previews of the image, and we quickly run into trouble when handling multiple images or slideshows. Writing to the file system is also not very fast, so there are a lot of optimizations necessary to ensure your iOS app runs smoothly.

处理图像在有些时候是一个相当复杂的问题。图像处理这个问题已经存在了一段时间，所以针对不同方面，会存在许多不同的框架。有时候，你不得不深入底层的 C 函数调用，解决随之而来的手动内存管理。再者，图像的来源很多，每个框架处理特殊情况的方式也都有所不同。不过，iOS 中最大的问题其实是内存：随着相机和屏幕分辨率越来越好，图像的尺寸也开始变大。iPhone 5S 有一个800万像素的摄像头；如果每个像素被存储在4个字节（分别用于三个颜色信道，加上一个不透明性），就会产生32兆的数据。如果需要添加几个工作副本或图像的预览，我们会很快在处理​​多张图片或幻灯片时遇到麻烦。再加上文件系统的写入也并不是非常快，所以很有必要进行一些优化，以确保你的iOS应用程序运行流畅。