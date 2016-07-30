一个像素是如何绘制到屏幕上去的？有很多种方式将一些东西映射到显示屏上，他们需要调用不同的框架、许多功能和方法的结合体。这里我们大概的看一下屏幕之后发生的事情。当你想要弄清楚什么时候、怎么去查明并解决问题时，我希望这篇文章能帮助你理解哪一个 API 可以更好的帮你解决问题。我们将聚焦于 iOS，然而我讨论的大多数问题也同样适用于 OS X。

## 图形堆栈
当像素映射到屏幕上的时候，后台发生了很多事情。但一旦他们显示到屏幕上，每一个像素均由三个颜色组件构成：红，绿，蓝。三个独立的颜色单元会根据给定的颜色显示到一个像素上。在 iPhone5 的[液晶显示器][14]上有1,136×640=727,040个像素，因此有2,181,120个颜色单元。在15寸视网膜屏的 MacBook Pro 上，这一数字达到15.5百万以上。所有的图形堆栈一起工作以确保每次正确的显示。当你滚动整个屏幕的时候，数以百万计的颜色单元必须以每秒60次的速度刷新，这是一个很大的工作量。

## 软件组成

从简单的角度来看，软件堆栈看起来有点像这样：

![软件堆栈][1]

Display 的上一层便是图形处理单元 GPU，GPU 是一个专门为图形高并发计算而量身定做的处理单元。这也是为什么它能同时更新所有的像素，并呈现到显示器上。它并发的本性让它能高效的将不同纹理合成起来。我们将有一小块内容来更详细的讨论图形合成。关键的是，GPU 是非常专业的，因此在某些工作上非常高效。比如，GPU 非常快，并且比 CPU 使用更少的电来完成工作。通常 CPU 都有一个普遍的目的，它可以做很多不同的事情，但是合成图像在 CPU 上却显得比较慢。

GPU Driver 是直接和 GPU 交流的代码块。不同的GPU是不同的性能怪兽，但是驱动使他们在下一个层级上显示的更为统一，典型的下一层级有 OpenGL/OpenGL ES.

OpenGL([Open Graphics Library][15]) 是一个提供了 2D 和 3D 图形渲染的 API。GPU 是一块非常特殊的硬件，OpenGL  和 GPU 密切的工作以提高GPU的能力，并实现硬件加速渲染。对大多数人来说，OpenGL 看起来非常底层，但是当它在1992年第一次发布的时候(20多年前的事了)是第一个和图形硬件(GPU)交流的标准化方式，这是一个重大的飞跃，程序员不再需要为每个GPU重写他们的应用了。

OpenGL 之上扩展出很多东西。在 iOS 上，几乎所有的东西都是通过 Core Animation 绘制出来，然而在 OS X 上，绕过 Core Animation 直接使用 Core Graphics 绘制的情况并不少见。对于一些专门的应用，尤其是游戏，程序可能直接和 OpenGL/OpenGL ES 交流。事情变得使人更加困惑，因为 Core Animation 使用 Core Graphics 来做一些渲染。像 AVFoundation，Core Image 框架，和其他一些混合的入口。

要记住一件事情，GPU 是一个非常强大的图形硬件，并且在显示像素方面起着核心作用。它连接到 CPU。从硬件上讲两者之间存在某种类型的[总线][16]，并且有像 OpenGL，Core Animation 和 Core Graphics 这样的框架来在 GPU 和 CPU 之间精心安排数据的传输。为了将像素显示到屏幕上，一些处理将在 CPU 上进行。然后数据将会传送到 GPU，这也需要做一些相应的操作，最终像素显示到屏幕上。

这个过程的每一部分都有各自的挑战，并且许多时候需要做出折中的选择。

## 硬件参与者

![挑战][2]

正如上面这张简单的图片显示那些挑战：GPU 需要将每一个 frame 的纹理(位图)合成在一起(一秒60次)。每一个纹理会占用 VRAM(video RAM)，所以需要给 GPU 同时保持纹理的数量做一个限制。GPU 在合成方面非常高效，但是某些合成任务却比其他更复杂，并且 GPU在 16.7ms(1/60s)内能做的工作也是有限的。

下一个挑战就是将数据传输到 GPU 上。为了让 GPU 访问数据，需要将数据从 RAM 移动到 VRAM 上。这就是提及到的上传数据到 GPU。这看起来貌似微不足道，但是一些大型的纹理却会非常耗时。

最终，CPU 开始运行你的程序。你可能会让 CPU 从 bundle 加载一张 PNG 的图片并且解压它。这所有的事情都在 CPU 上进行。然后当你需要显示解压缩后的图片时，它需要以某种方式上传到 GPU。一些看似平凡的，比如显示文本，对 CPU 来说却是一件非常复杂的事情，这会促使 Core Text 和 Core Graphics 框架更紧密的集成来根据文本生成一个位图。一旦准备好，它将会被作为一个纹理上传到 GPU 并准备显示出来。当你滚动或者在屏幕上移动文本时，不管怎么样，同样的纹理能够被复用，CPU 只需简单的告诉 GPU 新的位置就行了,所以 GPU 就可以重用存在的纹理了。CPU 并不需要重新渲染文本，并且位图也不需要重新上传到 GPU。

这张图涉及到一些错综复杂的方面，我们将会把这些方面提取出来并深一步了解。

## 合成
在图形世界中，合成是一个描述不同位图如何放到一起来创建你最终在屏幕上看到图像的过程。在许多方面显得显而易见，而让人忘了背后错综复杂的计算。

让我们忽略一些难懂的事例并且假定屏幕上一切事物皆纹理。一个纹理就是一个包含 RGBA 值的长方形，比如，每一个像素里面都包含红、绿、蓝和透明度的值。在 Core Animation 世界中这就相当于一个 CALayer。

在这个简化的设置中，每一个 layer 是一个纹理，所有的纹理都以某种方式堆叠在彼此的顶部。对于屏幕上的每一个像素，GPU 需要算出怎么混合这些纹理来得到像素 RGB 的值。这就是合成大概的意思。

如果我们所拥有的是一个和屏幕大小一样并且和屏幕像素对齐的单一纹理，那么屏幕上每一个像素相当于纹理中的一个像素，纹理的最后一个像素也就是屏幕的最后一个像素。

如果我们有第二个纹理放在第一个纹理之上，然后GPU将会把第二个纹理合成到第一个纹理中。有很多种不同的合成方法，但是如果我们假定两个纹理的像素对齐，并且使用正常的混合模式，我们便可以用下面这个公式来计算每一个像素：

    R = S + D * ( 1 – Sa )

结果的颜色是源色彩(顶端纹理)+目标颜色(低一层的纹理)*(1-源颜色的透明度)。在这个公式中所有的颜色都假定已经预先乘以了他们的透明度。

显然相当多的事情在这发生了。让我们进行第二个假定，两个纹理都完全不透明，比如 alpha=1.如果目标纹理(低一层的纹理)是蓝色(RGB=0,0,1)，并且源纹理(顶层的纹理)颜色是红色(RGB=1,0,0)，因为 Sa 为1，所以结果为：

    R = S

结果是源颜色的红色。这正是我们所期待的(红色覆盖了蓝色)。

如果源颜色层为50%的透明，比如 alpha=0.5，既然 alpha 组成部分需要预先乘进 RGB 的值中，那么 S 的 RGB 值为(0.5, 0, 0)，公式看起来便会像这样:

                           0.5   0               0.5
    R = S + D * (1 - Sa) = 0   + 0 * (1 - 0.5) = 0
                           0     1               0.5

我们最终得到RGB值为(0.5, 0, 0.5),是一个紫色。这正是我们所期望将透明红色合成到蓝色背景上所得到的。

记住我们刚刚只是将纹理中的一个像素合成到另一个纹理的像素上。当两个纹理覆盖在一起的时候，GPU需要为所有像素做这种操作。正如你所知道的一样，许多程序都有很多层，因此所有的纹理都需要合成到一起。尽管GPU是一块高度优化的硬件来做这种事情，但这还是会让它非常忙碌。

## 不透明 VS 透明

当源纹理是完全不透明的时候，目标像素就等于源纹理。这可以省下 GPU 很大的工作量，这样只需简单的拷贝源纹理而不需要合成所有的像素值。但是没有方法能告诉 GPU 纹理上的像素是透明还是不透明的。只有当你作为一名开发者知道你放什么到 CALayer 上了。这也是为什么 CALayer 有一个叫做 opaque 的属性了。如果这个属性为 YES，GPU 将不会做任何合成，而是简单从这个层拷贝，不需要考虑它下方的任何东西(因为都被它遮挡住了)。这节省了 GPU 相当大的工作量。这也正是 Instruments 中 color blended layers 选项中所涉及的。(这在模拟器中的Debug菜单中也可用).它允许你看到哪一个 layers(纹理) 被标注为透明的，比如 GPU 正在为哪一个 layers 做合成。合成不透明的 layers 因为需要更少的数学计算而更廉价。

所以如果你知道你的 layer 是不透明的，最好确定设置它的 opaque 为 YES。如果你加载一个没有 alpha 通道的图片，并且将它显示在 UIImageView 上，这将会自动发生。但是要记住如果一个图片没有 alpha 通道和一个图片每个地方的 alpha 都是100%，这将会产生很大的不同。在后一种情况下，Core Animation 需要假定是否存在像素的 alpha 值不为100%。在 Finder 中，你可以使用 Get Info 并且检查 More Info 部分。它将告诉你这张图片是否拥有 alpha 通道。

## 像素对齐 VS 不重合在一起

到现在我们都在考虑像素完美重合在一起的 layers。当所有的像素是对齐的时候我们得到相对简单的计算公式。每当 GPU 需要计算出屏幕上一个像素是什么颜色的时候，它只需要考虑在这个像素之上的所有 layer 中对应的单个像素，并把这些像素合并到一起。或者，如果最顶层的纹理是不透明的(即图层树的最底层)，这时候 GPU 就可以简单的拷贝它的像素到屏幕上。

当一个 layer 上所有的像素和屏幕上的像素完美的对应整齐，那这个 layer 就是像素对齐的。主要有两个原因可能会造成不对齐。第一个便是缩放；当一个纹理放大缩小的时候，纹理的像素便不会和屏幕的像素排列对齐。另一个原因便是当纹理的起点不在一个像素的边界上。

在这两种情况下，GPU 需要再做额外的计算。它需要将源纹理上多个像素混合起来，生成一个用来合成的值。当所有的像素都是对齐的时候，GPU 只剩下很少的工作要做。

Core Animation 工具和模拟器有一个叫做 color misaligned images 的选项，当这些在你的 CALayer 实例中发生的时候，这个功能便可向你展示。

## Masks

一个图层可以有一个和它相关联的 mask(蒙板)，mask 是一个拥有 alpha 值的位图，当像素要和它下面包含的像素合并之前都会把 mask 应用到图层的像素上去。当你要设置一个图层的圆角半径时，你可以有效的在图层上面设置一个 mask。但是也可以指定任意一个蒙板。比如，一个字母 A 形状的 mask。最终只有在 mask 中显示出来的(即图层中的部分)才会被渲染出来。

## 离屏渲染(Offscreen Rendering)

离屏渲染可以被 Core Animation 自动触发，或者被应用程序强制触发。屏幕外的渲染会合并/渲染图层树的一部分到一个新的缓冲区，然后该缓冲区被渲染到屏幕上。

离屏渲染合成计算是非常昂贵的, 但有时你也许希望强制这种操作。一种好的方法就是缓存合成的纹理/图层。如果你的渲染树非常复杂(所有的纹理，以及如何组合在一起)，你可以强制离屏渲染缓存那些图层，然后可以用缓存作为合成的结果放到屏幕上。

如果你的程序混合了很多图层，并且想要他们一起做动画，GPU 通常会为每一帧(1/60s)重复合成所有的图层。当使用离屏渲染时，GPU 第一次会混合所有图层到一个基于新的纹理的位图缓存上，然后使用这个纹理来绘制到屏幕上。现在，当这些图层一起移动的时候，GPU 便可以复用这个位图缓存，并且只需要做很少的工作。需要注意的是，只有当那些图层不改变时，这才可以用。如果那些图层改变了，GPU 需要重新创建位图缓存。你可以通过设置 shouldRasterize 为 YES 来触发这个行为。

然而，这是一个权衡。第一，这可能会使事情变得更慢。创建额外的屏幕外缓冲区是 GPU 需要多做的一步操作，特殊情况下这个位图可能再也不需要被复用，这便是一个无用功了。然而，可以被复用的位图，GPU 也有可能将它卸载了。所以你需要计算 GPU 的利用率和帧的速率来判断这个位图是否有用。

离屏渲染也可能产生副作用。如果你正在直接或者间接的将mask应用到一个图层上，Core Animation 为了应用这个 mask，会强制进行屏幕外渲染。这会对 GPU 产生重负。通常情况下 mask 只能被直接渲染到帧的缓冲区中(在屏幕内)。

Instrument 的 Core Animation 工具有一个叫做 *Color Offscreen-Rendered Yellow* 的选项，它会将已经被渲染到屏幕外缓冲区的区域标注为黄色(这个选项在模拟器中也可以用)。同时记得检查 *Color Hits Green and Misses Red* 选项。绿色代表无论何时一个屏幕外缓冲区被复用，而红色代表当缓冲区被重新创建。

一般情况下，你需要避免离屏渲染，因为这是很大的消耗。直接将图层合成到帧的缓冲区中(在屏幕上)比先创建屏幕外缓冲区，然后渲染到纹理中，最后将结果渲染到帧的缓冲区中要廉价很多。因为这其中涉及两次昂贵的环境转换(转换环境到屏幕外缓冲区，然后转换环境到帧缓冲区)。

所以当你打开 *Color Offscreen-Rendered Yellow* 后看到黄色，这便是一个警告，但这不一定是不好的。如果 Core Animation 能够复用屏幕外渲染的结果，这便能够提升性能。

同时还要注意，rasterized layer 的空间是有限的。苹果暗示大概有屏幕大小两倍的空间来存储 rasterized layer/屏幕外缓冲区。

如果你使用 layer 的方式会通过屏幕外渲染，你最好摆脱这种方式。为 layer 使用蒙板或者设置圆角半径会造成屏幕外渲染，产生阴影也会如此。

至于 mask，圆角半径(特殊的mask)和 clipsToBounds/masksToBounds，你可以简单的为一个已经拥有 mask 的 layer 创建内容，比如，已经应用了 mask 的 layer 使用一张图片。如果你想根据 layer 的内容为其应用一个长方形 mask，你可以使用 contentsRect 来代替蒙板。

如果你最后设置了 shouldRasterize 为 YES，那也要记住设置 rasterizationScale 为 contentsScale。

## 更多的关于合成

像往常一样，维基百科上有更多关于[透明合成][17]的基础公式。当我们谈完像素后，我们将更深入一点的谈论红，绿，蓝和 alpha 是怎么在内存中表现的。

## OS X

如果你是在 OS X 上工作，你将会发现大多数 debugging 选项在一个叫做 *Quartz Debug* 的独立程序中，而不是在 Instruments 中。Quartz Debug 是 Graphics Tools 中的一部分，这可以在苹果的 [developer portal][18] 中下载到。

## Core Animation  OpenGL ES

正如名字所建议的那样，Core Animation 让你在屏幕上实现动画。我们将跳过动画部分，而集中在绘图上。需要注意的是，Core Animation 允许你做非常高效的渲染。这也是为什么当你使用 Core Animation 时可以实现每秒 60 帧的动画。

Core Animation 的核心是 OpenGL ES 的一个抽象物，简而言之，它让你直接使用 OpenGL ES 的功能，却不需要处理 OpenGL ES 做的复杂的事情。当我们上面谈论合成的时候，我们把 layer 和 texture 当做等价的，但是他们不是同一物体，可又是如此的类似。

Core Animation 的 layer 可以有子 layer，所以最终你得到的是一个图层树。Core Animation 所需要做的最繁重的任务便是判断出哪些图层需要被(重新)绘制，而 OpenGL ES 需要做的便是将图层合并、显示到屏幕上。

举个例子，当你设置一个 layer 的内容为 CGImageRef 时，Core Animation 会创建一个 OpenGL 纹理，并确保在这个图层中的位图被上传到对应的纹理中。以及当你重写 `-drawInContext` 方法时，Core Animation 会请求分配一个纹理，同时确保 Core Graphics 会将你所做的(即你在`drawInContext`中绘制的东西)放入到纹理的位图数据中。一个图层的性质和 CALayer 的子类会影响到 OpenGL 的渲染结果，许多低等级的 OpenGL ES 行为被简单易懂地封装到 CALayer 概念中。

Core Animation 通过 Core Graphics 的一端和 OpenGL ES 的另一端，精心策划基于 CPU 的位图绘制。因为 Core Animation 处在渲染过程中的重要位置上，所以你如何使用 Core Animation 将会对性能产生极大的影响。

## CPU 限制 VS GPU 限制

当你在屏幕上显示东西的时候，有许多组件参与了其中的工作。其中，CPU 和 GPU 在硬件中扮演了重要的角色。在他们命名中 P 和 U 分别代表了”处理”和”单元”，当需要在屏幕上进行绘制时，他们都需要做处理，同时他们都有资源限制(即 CPU 和 GPU 的硬件资源)。

为了每秒达到 60 帧，你需要确定 CPU 和 GPU 不能过载。此外，即使你当前能达到 60fps(frame per second),你还是要把尽可能多的绘制工作交给 GPU 做，而让 CPU 尽可能的来执行应用程序。通常，GPU 的渲染性能要比 CPU 高效很多，同时对系统的负载和消耗也更低一些。

既然绘图性能是基于 CPU 和 GPU 的，那么你需要找出是哪一个限制你绘图性能的。如果你用尽了 GPU 所有的资源，也就是说，是 GPU 限制了你的性能，同样的，如果你用尽了 CPU，那就是 CPU 限制了你的性能。

要告诉你，如果是 GPU 限制了你的性能，你可以使用 OpenGL ES Driver instrument。点击上面那个小的 i 按钮，配置一下，同时注意勾选 Device Utilization %。现在，当你运行你的 app 时，你可以看到你 GPU 的负荷。如果这个值靠近 100%，那么你就需要把你工作的重心放在GPU方面了。

## Core Graphics / Quartz 2D

通过 Core Graphics 这个框架，Quartz 2D 被更为广泛的知道。

Quartz 2D 拥有比我们这里谈到更多的装饰。我们这里不会过多的讨论关于 PDF 的创建，渲染，解析，或者打印。只需要注意的是，PDF 的打印、创建和在屏幕上绘制位图的操作是差不多的。因为他们都是基于 Quartz 2D。

让我们简单的了解一下 [Quartz 2D][19] 主要的概念。有关详细信息可以到苹果的官方文档中了解。

放心，当 Quartz 2D 涉及到 2D 绘制的时候，它是非常强大的。有基于路径的绘制，反锯齿渲染，透明图层，分辨率，并且设备独立，可以说出很多特色。这可能会让人产生畏惧，主要因为这是一个低级并且基于 C 的 API。

主要的概念相对简单，UIKit 和 AppKit 都包含了 Quartz 2D 的一些简单 API，一旦你熟练了，一些简单 C 的 API 也是很容易理解的。最终你学会了一个能实现 Photoshop 和 Illustrator 大部分功能的绘图引擎。苹果把 iOS 程序里面的[股票应用][20]作为讲解 Quartz 2D 在代码中实现动态渲染的一个例子。

当你的程序进行位图绘制时，不管使用哪种方式，都是基于 Quartz 2D 的。也就是说，CPU 部分实现的绘制是通过 Quartz 2D 实现的。尽管 Quartz 可以做其它的事情，但是我们这里还是集中于位图绘制，在缓冲区(一块内存)绘制位图会包括 RGBA 数据。

比方说，我们要画一个[八角形][21]，我们通过 UIKit 能做到这一点

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(16.72, 7.22)];
    [path addLineToPoint:CGPointMake(3.29, 20.83)];
    [path addLineToPoint:CGPointMake(0.4, 18.05)];
    [path addLineToPoint:CGPointMake(18.8, -0.47)];
    [path addLineToPoint:CGPointMake(37.21, 18.05)];
    [path addLineToPoint:CGPointMake(34.31, 20.83)];
    [path addLineToPoint:CGPointMake(20.88, 7.22)];
    [path addLineToPoint:CGPointMake(20.88, 42.18)];
    [path addLineToPoint:CGPointMake(16.72, 42.18)];
    [path addLineToPoint:CGPointMake(16.72, 7.22)];
    [path closePath];
    path.lineWidth = 1;
    [[UIColor redColor] setStroke];
    [path stroke];

相对应的 Core Graphics 代码：

    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, 16.72, 7.22);
    CGContextAddLineToPoint(ctx, 3.29, 20.83);
    CGContextAddLineToPoint(ctx, 0.4, 18.05);
    CGContextAddLineToPoint(ctx, 18.8, -0.47);
    CGContextAddLineToPoint(ctx, 37.21, 18.05);
    CGContextAddLineToPoint(ctx, 34.31, 20.83);
    CGContextAddLineToPoint(ctx, 20.88, 7.22);
    CGContextAddLineToPoint(ctx, 20.88, 42.18);
    CGContextAddLineToPoint(ctx, 16.72, 42.18);
    CGContextAddLineToPoint(ctx, 16.72, 7.22);
    CGContextClosePath(ctx);
    CGContextSetLineWidth(ctx, 1);
    CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
    CGContextStrokePath(ctx);

需要问的问题是:这个绘制到哪儿去了？这正好引出所谓的 CGContext 登场。我们传过去的ctx参数正是在那个上下文中。而这个上下文定义了我们需要绘制的地方。如果我们实现了 CALayer 的 `-drawInContext:` 这时已经传过来一个上下文。绘制到这个上下文中的内容将会被绘制到图层的备份区(图层的缓冲区).但是我们也可以创建我们自己的上下文，叫做基于位图的上下文，比如 `CGBitmapContextCreate()`.这个方法返回一个我们可以传给 CGContext 方法来绘制的上下文。

注意 UIKit 版本的代码为何不传入一个上下文参数到方法中？这是因为当使用 UIKit 或者 AppKit 时，上下文是唯一的。UIkit 维护着一个上下文堆栈，UIKit 方法总是绘制到最顶层的上下文中。你可以使用 `UIGraphicsGetCurrentContext()` 来得到最顶层的上下文。你可以使用 `UIGraphicsPushContext()` 和 `UIGraphicsPopContext()` 在 UIKit 的堆栈中推进或取出上下文。

最为突出的是，UIKit 使用 `UIGraphicsBeginImageContextWithOptions()` 和 `UIGraphicsEndImageContext()` 方便的创建类似于 `CGBitmapContextCreate()` 的位图上下文。混合调用 UIKit 和 Core Graphics 非常简单：

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(45, 45), YES, 2);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, 16.72, 7.22);
    CGContextAddLineToPoint(ctx, 3.29, 20.83);
    ...
    CGContextStrokePath(ctx);
    UIGraphicsEndImageContext();

或者另外一种方法:

    CGContextRef ctx = CGBitmapContextCreate(NULL, 90, 90, 8, 90 * 4, space, bitmapInfo);
    CGContextScaleCTM(ctx, 0.5, 0.5);
    UIGraphicsPushContext(ctx);
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(16.72, 7.22)];
    [path addLineToPoint:CGPointMake(3.29, 20.83)];
    ...
    [path stroke];
    UIGraphicsPopContext(ctx);
    CGContextRelease(ctx);

你可以使用 Core Graphics 创建大量的非常酷的东西。一个很好的理由就是，苹果的文档有很多例子。我们不能得到所有的细节，但是 Core Graphics 有一个非常接近 [Adobe Illustrator][13] 和 [Adobe Photoshop][11] 如何工作的绘图模型，并且大多数工具的理念翻译成 Core Graphics 了。终究，他是起源于 [NeXTSTEP][12] 。(原来也是乔老爷的作品)。

## CGLayer
我们最初指出 CGLayer 可以用来提升重复绘制相同元素的速度。正如 [Dave Hayden指出][8]，这些[小道消息][9]不再可靠。

## 像素

屏幕上的像素是由红，绿，蓝三种颜色组件构成的。因此，位图数据有时也被叫做 RGB 数据。你可能会对数据如何组织在内存中感到好奇。而事实是，有很多种不同的方式在内存中展现RGB位图数据。

稍后我们将会谈到压缩数据，这又是一个完全不同的概念。现在，我们先看一下RGB位图数据，我们可以从颜色组件:红，绿，蓝中得到一个值。而大多数情况下，我们有第四个组件:透明度。最终我们从每个像素中得到四个单独的值。

## 默认的像素布局

在 iOS 和 OS X 上最常见的格式就是大家所熟知的 32bits-per-pixel(bpp), 8bits-per-componet(bpc),透明度会首先被乘以到像素值上(就像上文中提到的那个公式一样),在内存中，像下面这样:

      A   R   G   B   A   R   G   B   A   R   G   B  
    | pixel 0       | pixel 1       | pixel 2   
      0   1   2   3   4   5   6   7   8   9   10  11 ...

这个格式经常被叫做 ARGB。每个像素占用 4 字节(32bpp),每一个颜色组件是1字节(8bpc).每个像素有一个 alpha 值，这个值总是最先得到的(在RGB值之前)，最终红、绿、蓝的值都会被预先乘以 alpha 的值。预乘的意思就是 alpha 值被烘烤到红、绿、蓝的组件中。如果我们有一个橙色，他们各自的 8bpc 就像这样: 240,99,24.一个完全不透明的橙色像素拥有的 ARGB 值为: 255，240，99，24，它在内存中的布局就像上面图示那样。如果我们有一个相同颜色的像素，但是 alpha 值为 33%，那么他的像素值便是:84，80，33，8.

另一个常见的格式便是 32bpp，8bpc，跳过第一个 alpha 值，看起来像下面这样：

      x   R   G   B   x   R   G   B   x   R   G   B  
    | pixel 0       | pixel 1       | pixel 2   
      0   1   2   3   4   5   6   7   8   9   10  11 ...
这常被叫做 xRGB。像素并没有任何 alpha 值(他们都被假定为100%不透明)，但是内存布局是一样的。你应该想知道为什么这种格式很流行，当我们每一个像素中都有一个不用字节时，我们将会省下 25% 的空间。事实证明，这种格式更容易被现代的 CPU 和绘图算法消化，因为每一个独立的像素都对齐到 32-bit 的边界。现代的 CPU 不喜欢装载(读取)不对齐的数据，特别是当将这种数据和上面没有 alpha 值格式的数据混合时，算法需要做很多挪动和蒙板操作。

当处理 RGB 数据时，Core Graphics 也需要支持把alpha 值放到最后(另外还要支持跳过)。有时候也分别称为 RGBA 和 RGBx，假定是 8bpc，并且预乘了 alpha 值。

## 深奥的布局

大多数时候，当处理位图数据时，我们也需要处理 Core Graphics/Quartz 2D。有一个非常详细的列表列出了他支持的混合组合。但是让我们首先看一下剩下的 RGB 格式：

另一个选择是 16bpp，5bpc，不包含 alpha 值。这个格式相比之前一个仅占用 50% 的存储大小(每个像素2字节)，但将使你存储它的 RGB 数据到内存或磁盘中变得困难。既然这种格式中，每个颜色组件只有 5bits(原文中写的是每个像素是5bits，但根据上下文可知应该是每个组件)，这样图形(特别是平滑渐变的)会造成重叠在一起的假象。

还有一个是 64bpp，16bpc，最终为 128bpp，32bpc，浮点数组件(有或没有 alpha 值)。它们分别使用 8 字节和 16 字节，并且允许更高的精度。当然，这会造成更多的内存使用和昂贵的计算。

整件事件中，Core Graphics 也支持一些像灰度模式和 [CMYK][10] 格式，这些格式类似于仅有 alpha 值的格式(蒙板)。

## 二维数据

当颜色组件(红、绿、蓝、alpha)混杂在一起的时候，大多数框架(包括 Core Graphics )使用像素数据。正是这种情况下我们称之为二维数据，或者二维组件。这个意思是：每一个颜色组件都在它自己的内存区域，也就是说它是二维的。比如 RGB 数据，我们有三个独立的内存区域，一个大的区域包含了所有像素的红颜色的值，一个包含了所有绿颜色的值，一个包含了所有蓝颜色的值。

在某些情况下，一些视频框架便会使用二维数据。

## YCbCr

当我们处理视频数据时，[YCbCr][7] 是一种常见的格式。它也是包含了三种(Y,Cb和Cr)代表颜色数据的组件。但是简单的讲，它更类似于通过人眼看到的颜色。人眼对 Cb 和 Cr 这两种组件的色彩度不太能精确的辨认出来，但是能很准确的识别出 Y 的亮度。当数据使用 YCbCr 格式时，在同等的条件下，Cb 和 Cr 组件比 Y 组件压缩的更紧密。

出于同样的原因，JPEG 图像有时会将像素数据从 RGB 转换到 YCbCr。JPEG 单独的压缩每一个二维颜色。当压缩基于 YCbCr 的平面时，Cb 和 Cr 能比 Y 压缩得更完全。

## 图片格式

当你在 iOS 或者 OS X 上处理图片时，他们大多数为 JPEG 和 PNG。让我们更进一步观察。

## JPEG

每个人都知道 JPEG。它是相机的产物。它代表着照片如何存储在电脑上。甚至你妈妈都听说过 JPEG。

一个很好的理由，很多人都认为 JPEG 文件仅是另一种像素数据的格式，就像我们刚刚谈到的 RGB 像素布局那样。这样理解离真相真是差十万八千里了。

将 JPEG 数据转换成像素数据是一个非常复杂的过程，你通过一个周末的计划都不能完成，甚至是一个非常漫长的周末(原文的意思好像就是为了表达这个过程非常复杂，不过老外的比喻总让人拎不清)。对于每一个二维颜色，JPEG 使用一种基于[离散余弦变换][6](简称 DCT 变换)的算法，将空间信息转变到频域.这个信息然后被量子化，排好序，并且用一种[哈夫曼编码][5]的变种来压缩。很多时候，首先数据会被从 RGB 转换到二维 YCbCr，当解码 JPEG 的时候，这一切都将变得可逆。

这也是为什么当你通过 JPEG 文件创建一个 UIImage 并且绘制到屏幕上时，将会有一个延时，因为 CPU 这时候忙于解压这个 JPEG。如果你需要为每一个 tableviewcell 解压 JPEG，那么你的滚动当然不会平滑(原来 tableviewcell 里面最要不要用 JPEG 的图片)。

那究竟为什么我们还要用 JPEG 呢？答案就是 JPEG 可以非常非常好的压缩图片。一个通过 iPhone5 拍摄的，未经压缩的图片占用接近 24M。但是通过默认压缩设置，你的照片通常只会在 2-3M 左右。JPEG 压缩这么好是因为它是失真的，它去除了人眼很难察觉的信息，并且这样做可以超出像 gzip 这样压缩算法的限制。但这仅仅在图片上有效的，因为 JPEG 依赖于图片上有很多人类不能察觉出的数据。如果你从一个基本显示文本的网页上截取一张图，JPEG 将不会这么高效。压缩效率将会变得低下，你甚至能看出来图片已经压缩变形了。

## PNG

[PNG][4]读作”ping”。和 JPEG 相反，它的压缩对格式是无损的。当你将一张图片保存为 PNG，并且打开它(或解压)，所有的像素数据会和最初一模一样，因为这个限制，PNG 不能像 JPEG 一样压缩图片，但是对于像程序中的原图(如buttons，icons)，它工作的非常好。更重要的是，解码 PNG 数据比解码 JPEG 简单的多。

在现实世界中，事情从来没有那么简单，目前存在了大量不同的 PNG 格式。可以通过维基百科查看详情。但是简言之，PNG 支持压缩带或不带 alpha 通道的颜色像素(RGB)，这也是为什么它在程序原图中表现良好的另一个原因。

## 挑选一个格式

当你在你的程序中使用图片时，你需要坚持这两种格式: JPEG 或者 PNG。读写这种格式文件的压缩和解压文件能表现出很高的性能，另外，还支持并行操作。同时 Apple 正在改进解压缩并可能出现在将来的新操作系统中，届时你将会得到持续的性能提升。如果尝试使用另一种格式，你需要注意到，这可能对你程序的性能会产生影响，同时可能会打开安全漏洞，经常，图像解压缩算法是黑客最喜欢的攻击目标。

已经写了很多关于优化 PNGs，如果你想要了解更多，请到互联网上查询。非常重要的一点，注意 Xcode 优化 PNG 选项和优化其他引擎有很大的不同。

当 Xcode 优化一个 PNG 文件的时候，它将 PNG 文件变成一个从技术上讲不再是[有效的PNG文件][3]。但是 iOS 可以读取这种文件，并且这比解压缩正常的 PNG 文件更快。Xcode 改变他们，让 iOS 通过一种对正常 PNG 不起作用的算法来对他们解压缩。值得注意的重点是，这改变了像素的布局。正如我们所提到的一样，在像素之下有很多种方式来描绘 RGB 数据，如果这不是 iOS 绘制系统所需要的格式，它需要将每一个像素的数据替换，而不需要加速来做这件事。

让我们再强调一遍，如果你可以，你需要为原图设置 resizable images。你的文件将变得更小，因此你只需要从文件系统装载更少的数据。

## UIKit 和 Pixels

每一个在 UIKit 中的 view 都有它自己的 CALayer。依次，这些图层都有一个叫像素位图的后备存储，有点像一个图像。这个后备存储正是被渲染到显示器上的。

## With –drawRect:

如果你的视图类实现了 `-drawRect:`，他们将像这样工作:

当你调用 `-setNeedsDisplay`，UIKit 将会在这个视图的图层上调用 `-setNeedsDisplay`。这为图层设置了一个标识，标记为 dirty(直译是脏的意思，想不出用什么词比较贴切,污染？)，但还显示原来的内容。它实际上没做任何工作，所以多次调用 `-setNeedsDisplay`并不会造成性能损失。

下面，当渲染系统准备好，它会调用视图图层的-display方法.此时，图层会装配它的后备存储。然后建立一个 Core Graphics 上下文(CGContextRef)，将后备存储对应内存中的数据恢复出来，绘图会进入对应的内存区域，并使用 CGContextRef 绘制。

当你使用 UIKit 的绘制方法，例如: `UIRectFill()` 或者 `-[UIBezierPath fill]` 代替你的 `-drawRect:` 方法，他们将会使用这个上下文。使用方法是，UIKit 将后备存储的 CGContextRef 推进他的 graphics context stack，也就是说，它会将那个上下文设置为当前的。因此 `UIGraphicsGetCurrent()` 将会返回那个对应的上下文。既然 UIKit 使用 `UIGraphicsGetCurrent()` 绘制方法，绘图将会进入到图层的后备存储。如果你想直接使用 Core Graphics 方法，你可以自己调用 `UIGraphicsGetCurrent()` 得到相同的上下文，并且将这个上下文传给 Core Graphics 方法。

从现在开始，图层的后备存储将会被不断的渲染到屏幕上。直到下次再次调用视图的 `-setNeedsDisplay` ，将会依次将图层的后备存储更新到视图上。

## 不使用 -drawRect:

当你用一个 UIImageView 时，事情略有不同，这个视图仍然有一个 CALayer，但是图层却没有申请一个后备存储。取而代之的是使用一个 CGImageRef 作为他的内容，并且渲染服务将会把图片的数据绘制到帧的缓冲区，比如，绘制到显示屏。

在这种情况下，将不会继续重新绘制。我们只是简单的将位图数据以图片的形式传给了 UIImageView，然后 UIImageView 传给了 Core Animation，然后轮流传给渲染服务。

## 实现-drawRect: 还是不实现 -drawRect:

这听起来貌似有点低俗，但是最快的绘制就是你不要做任何绘制。

大多数时间，你可以不要合成你在其他视图(图层)上定制的视图(图层)，这正是我们推荐的，因为 UIKit 的视图类是非常优化的 (就是让我们不要闲着没事做,自己去合并视图或图层) 。

当你需要自定义绘图代码时，Apple 在[WWDC 2012’s session 506][25]:Optimizing 2D Graphics and Animation Performance 中展示了一个很好的例子:”finger painting”。

另一个地方需要自定义绘图的就是 iOS 的股票软件。股票是直接用 Core Graphics 在设备上绘制的，注意，这仅仅是你需要自定义绘图，你并不需要实现 `-drawRect:` 方法。有时，通过 `UIGraphicsBeginImageContextWithOptions()` 或者 `CGBitmapContextCeate()` 创建位图会显得更有意义，从位图上面抓取图像，并设置为 `CALayer` 的内容。下面我们将给出一个例子来测试，检验。

## 单一颜色

如果我们看这个例子：

    // Don't do this
    - (void)drawRect:(CGRect)rect
    {
        [[UIColor redColor] setFill];
        UIRectFill([self bounds]);
    }

现在我们知道这为什么不好:我们促使 Core Animation 来为我们创建一个后备存储，并让它使用单一颜色填充后备存储，然后上传给 GPU。

我们跟本不需要实现 `-drawRect:`，并节省这些代码工作量，只需简单的设置这个视图图层的背景颜色。如果这个视图有一个 CAGradientLayer 作为图层，那么这个技术也同样适用于此（渐变图层）。

## 可变尺寸的图像

类似的，你可以使用可变尺寸的图像来降低绘图系统的压力。让我们假设你需要一个 300×50 点的按钮插图，这将是 600×100=60k 像素或者 60kx4=240kB 内存大小需要上传到 GPU，并且占用 VRAM。如果我们使用所谓的可变尺寸的图像，我们只需要一个 54×12 点的图像，这将占用低于 2.6k 的像素或者 10kB 的内存，这样就变得更快了。

Core Animation 可以通过 CALayer 的 [`contentsCenter`][22] 属性来改变图像，大多数情况下，你可能更倾向于使用，[`-[UIImage resizableImageWithCapInsets:resizingMode:]`][23]。

同时注意，在第一次渲染这个按钮之前，我们并不需要从文件系统读取一个 60k 像素的 PNG 并解码，解码一个小的 PNG 将会更快。通过这种方式，你的程序在每一步的调用中都将做更少的工作，并且你的视图将会加载的更快。

## 并发绘图

上一次 [objc.io][24] 的话题是关于并发的讨论。正如你所知道的一样，UIKit 的线程模型是非常简单的：你仅可以从主队列(比如主线程)中调用 UIKit 类(比如视图),那么并发绘图又是什么呢？

如果你必须实现 `-drawRect:`，并且你必须绘制大量的东西，这将占用时间。由于你希望动画变得更平滑，除了在主队列中，你还希望在其他队列中做一些工作。同时发生的绘图是复杂的，但是除了几个警告，同时发生的绘图还是比较容易实现的。

我们除了在主队列中可以向 CALayer 的后备存储中绘制一些东西，其他方法都将不可行。可怕的事情将会发生。我们能做的就是向一个完全断开链接的位图上下文中进行绘制。

正如我们上面所提到的一样，在 Core Graphics 下，所有 Core Graphics 绘制方法都需要一个上下文参数来指定绘制到那个上下文中。UIKit 有一个当前上下文的概念(也就是绘制到哪儿去)。这个当前的上下文就是 per-thread.

为了同时绘制，我们需要做下面的操作。我们需要在另一个队列创建一个图像，一旦我们拥有了图像，我们可以切换回主队列，并且设置这个图像为 UIImageView 的图像。这个技术在 [WWDC 2012 session 211][26] 中讨论过。(异步下载图片经常用到这个)

增加一个你可以在其中绘制的新方法：


    - (UIImage *)renderInImageOfSize:(CGSize)size
    {
    	UIGraphicsBeginImageContextWithOptions(size, NO, 0);

    	// do drawing here

    	UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    	UIGraphicsEndImageContext();
    	return result;
    }

这个方法通过 `UIGraphicsBeginImageContextWithOptions()` 方法，并根据给定的大小创建一个新的 CGContextRef 位图。这个方法也会将这个上下文设置为*当前UIKit*的上下文。现在你可以在这里做你想在 `-drawRect:` 中做的事了。然后我们可以通过 `UIGraphicsGetImageFromCurrentImageContext()`,将获得的这个上下文位图数据作为一个 UIImage，最终移除这个上下文。

很重要的一点就是，你在这个方法中所做的所有绘图的代码都是线程安全的，也就是说，当你访问属性等等，他们需要线程安全。因为你是在另一个队列中调用这个方法的。如果这个方法在你的视图类中，那就需要注意一点了。另一个选择就是创建一个单独的渲染类，并设置所有需要的属性，然后通过触发来渲染图片。如果这样，你可以通过使用简单的 UIImageView 或者 UITableViewCell。

要知道，所有 UIKit 的绘制 API 在使用另一个队列时，都是安全的。只需要确定是在同一个操作中调用他们的，这个操作需要以 `UIGraphicsBeginImageContextWithOptions()` 开始，以 `UIGraphicsEndIamgeContext()` 结束。

你需要像下面这样触发渲染代码：

    UIImageView *view; // assume we have this
    NSOperationQueue *renderQueue; // assume we have this
    CGSize size = view.bounds.size;
    [renderQueue addOperationWithBlock:^(){
            UIImage *image = [renderer renderInImageOfSize:size];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^(){
                view.image = image;
            }];
    }];

要注意，我们是在主队列中调用 view.image = image.这是一个非常重要的细节。你不可以在任何其他队列中调用这个代码。

像往常一样，同时绘制会伴随很多问题，你现在需要取消后台渲染。并且在渲染队列中设置合理的同时绘制的最大限度。

为了支持这一切，最简单的就是在一个 NSOperation 子类内部实现 `-renderInImageOfSize:`。

最终，需要指出，设置 UITableViewCell 内容为异步是非常困难的。单元格很有可能在完成异步渲染前已经被复用了。尽管单元格已经被其他地方复用，但你只需要设置内容就行了。

## CALayer

到现在为止，你需要知道在 GPU 内，一个 CALayer 在某种方式上和一个纹理类似。图层有一个后备存储，这便是被用来绘制到屏幕上的位图。

通常，当你使用 CALayer 时，你会设置它的内容为一个图片。这到底做了什么？这样做会告诉 Core Animation 使用图片的位图数据作为纹理。如果这个图片(JPEG或PNG)被压缩了，Core Animation 将会这个图片解压缩，然后上传像素数据到 GPU。

尽管还有很多其他种类的图层，如果你是用一个简单的没有设置上下文的 CALayer，并为这个 CALayer 设置一个背景颜色，Core Animation 并不会上传任何数据到 GPU，但却能够不用任何像素数据而在 GPU 上完成所有的工作，类似的，对于渐变的图层，GPU 是能创建渐变的，而且不需要 CPU 做任何工作，并且不需要上传任何数据到 GPU。

## 自定义绘制的图层

如果一个 CALayer 的子类实现了 `-drawInContext:` 或者它的代理，类似于 `-drawLayer:inContest:`, Core Animation 将会为这个图层申请一个后备存储，用来保存那些方法绘制进来的位图。那些方法内的代码将会运行在 CPU 上，结果将会被上传到 GPU。

## 形状和文本图层

形状和文本图层还是有些不同的。开始时，Core Animation 为这些图层申请一个后备存储来保存那些需要为上下文生成的位图数据。然后 Core Animation 会讲这些图形或文本绘制到后备存储上。这在概念上非常类似于，当你实现 `-drawInContext:` 方法，然后在方法内绘制形状或文本，他们的性能也很接近。

在某种程度上，当你需要改变形状或者文本图层时，这需要更新它的后备存储，Core Animation 将会重新渲染后备存储。例如，当动态改变形状图层的大小时，Core Animation 需要为动画中的每一帧重新绘制形状。

## 异步绘图

CALayer 有一个叫做 drawsAsynchronously 的属性，这似乎是一个解决所有问题的高招。注意，尽管这可能提升性能，但也可能让事情变慢。

当你设置 drawsAsynchronously 为 YES 时，发生了什么？你的 `-drawRect:/-drawInContext:` 方法仍然会被在主线程上调用。但是所有调用 Core Graphics 的操作都不会被执行。取而代之的是，绘制命令被推迟，并且在后台线程中异步执行。

这种方式就是先记录绘图命令，然后在后台线程中重现。为了这个过程的顺利进行，更多的工作需要被做，更多的内存需要被申请。但是主队列中的一些工作便被移出来了(大概意思就是让我们把一些能在后台实现的工作放到后台实现，让主线程更顺畅)。

对于昂贵的绘图方法，这是最有可能提升性能的，但对于那些绘图方法来说，也不会节省太多资源。

---

 

   [1]: /images/issues/issue-3/pixels-software-stack.png
   [2]: /images/issues/issue-3/pixels%2C%20hardware.png
   [3]: https://developer.apple.com/library/ios/qa/qa1681/_index.html
   [4]: https://zh.wikipedia.org/wiki/PNG
   [5]: https://zh.wikipedia.org/wiki/%E9%9C%8D%E5%A4%AB%E6%9B%BC%E7%BC%96%E7%A0%81
   [6]: https://zh.wikipedia.org/wiki/%E7%A6%BB%E6%95%A3%E4%BD%99%E5%BC%A6%E5%8F%98%E6%8D%A2
   [7]: https://zh.wikipedia.org/wiki/YCbCr
   [8]: http://iosptl.com/posts/cglayer-no-longer-recommended/
   [9]: http://iosptl.com/posts/cglayer-no-longer-recommended/
   [10]: https://zh.wikipedia.org/wiki/%E5%8D%B0%E5%88%B7%E5%9B%9B%E5%88%86%E8%89%B2%E6%A8%A1%E5%BC%8F
   [11]: https://zh.wikipedia.org/wiki/Adobe_Photoshop
   [12]: https://zh.wikipedia.org/wiki/NEXTSTEP
   [13]: https://zh.wikipedia.org/wiki/Adobe_Illustrator
   [14]: https://zh.wikipedia.org/wiki/%E6%A9%AB%E5%90%91%E9%9B%BB%E5%A0%B4%E6%95%88%E6%87%89%E9%A1%AF%E7%A4%BA%E6%8A%80%E8%A1%93
   [15]: http://zh.wikipedia.org/wiki/OpenGL
   [16]: https://zh.wikipedia.org/wiki/I/O%E6%80%BB%E7%BA%BF
   [17]: https://en.wikipedia.org/wiki/Alpha_compositing
   [18]: https://developer.apple.com/downloads/
   [19]: https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Introduction/Introduction.html
   [20]: https://developer.apple.com/videos/wwdc/2011/?id=129
   [21]: https://zh.wikipedia.org/wiki/%E5%85%AB%E8%BE%B9%E5%BD%A2
   [22]: https://developer.apple.com/library/mac/documentation/graphicsimaging/reference/CALayer_class/Introduction/Introduction.html#//apple_ref/occ/instp/CALayer/contentsCenter
   [23]: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIImage_Class/Reference/Reference.html#//apple_ref/occ/instm/UIImage/resizableImageWithCapInsets:resizingMode:
   [24]: http://objccn.io/issue-2/
   [25]: https://developer.apple.com/videos/wwdc/2012/?id=506
   [26]: https://developer.apple.com/videos/wwdc/2012/?id=211
   [27]: http://objccn.io/issue-3/

原文 [Getting Pixels onto the Screen](http://www.objc.io/issue-3/moving-pixels-onto-the-screen.html)

译文 [将像素绘制到屏幕上去 - answer-huang](http://answerhuang.duapp.com/index.php/2013/09/04/pixels-get-onto-the-screen/)
