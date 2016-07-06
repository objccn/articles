Instagram，Snapchat，Photoshop。

所有这些应用都是用来做图像处理的。图像处理可以简单到把一张照片转换为灰度图，也可以复杂到是分析一个视频，并在人群中找到某个特定的人。尽管这些应用非常的不同，但这些例子遵从同样的流程，都是从创造到渲染。

在电脑或者手机上做图像处理有很多方式，但是目前为止最高效的方法是有效地使用图形处理单元，或者叫 GPU。你的手机包含两个不同的处理单元，CPU 和 GPU。CPU 是个多面手，并且不得不处理所有的事情，而 GPU 则可以集中来处理好一件事情，就是并行地做浮点运算。事实上，图像处理和渲染就是在将要渲染到窗口上的像素上做许许多多的浮点运算。

通过有效的利用 GPU，可以成百倍甚至上千倍地提高手机上的图像渲染能力。如果不是基于 GPU 的处理，手机上实时高清视频滤镜是不现实，甚至不可能的。

着色器 (shader) 是我们利用这种能力的工具。着色器是用着色语言写的小的，基于 C 语言的程序。现在有很许多种着色语言，但你如果做 OS X 或者 iOS 开发的话，你应该专注于 OpenGL 着色语言，或者叫 GLSL。你可以将 GLSL 的理念应用到其他的更专用的语言 (比如 Metal) 上去。这里我们即将介绍的概念与和 Core Image 中的自定义核矩阵有着很好的对应，尽管它们在语法上有一些不同。

这个过程可能会很让人恐惧，尤其是对新手。这篇文章的目的是让你接触一些写图像处理着色器的必要的基础信息，并将你带上书写你自己的图像处理着色器的道路。

## 什么是着色器

我们将乘坐时光机回顾一下过去，来了解什么是着色器，以及它是怎样被集成到我们的工作流当中的。

如果你在 iOS 5 或者之前就开始做 iOS 开发，你或许会知道在 iPhone 上 OpenGL 编程有一个转变，从 OpenGL ES 1.1 变成了 OpenGL ES 2.0。

OpenGL ES 1.1 没有使用着色器。作为替代，OpenGL ES 1.1 使用被称为固定功能管线 (fixed-function pipeline) 的方式。有一系列固定的函数用来在屏幕上渲染对象，而不是创建一个单独的程序来指导 GPU 的行为。这样有很大的局限性，你不能做出任何特殊的效果。如果你想知道着色器在工程中可以造成怎样的不同，[看看这篇 Brad Larson 写的他用着色器替代固定函数重构 Molecules 应用的博客](http://www.sunsetlakesoftware.com/2011/05/08/enhancing-molecules-using-opengl-es-20)

OpenGL ES 2.0 引入了可编程管线。可编程管线允许你创建自己的着色器，给了你更强大的能力和灵活性。

在 OpenGL ES 中你必须创建两种着色器：顶点着色器 (vertex shaders) 和片段着色器 (fragment shaders)。这两种着色器是一个完整程序的两半，你不能仅仅创建其中任何一个；想创建一个完整的着色程序，两个都是必须存在。

顶点着色器定义了在 2D 或者 3D 场景中几何图形是如何处理的。一个顶点指的是 2D 或者 3D 空间中的一个点。在图像处理中，有 4 个顶点：每一个顶点代表图像的一个角。顶点着色器设置顶点的位置，并且把位置和纹理坐标这样的参数发送到片段着色器。

然后 GPU 使用片段着色器在对象或者图片的每一个像素上进行计算，最终计算出每个像素的最终颜色。图片，归根结底，实际上仅仅是数据的集合。图片的文档包含每一个像素的各个颜色分量和像素透明度的值。因为对每一个像素，算式是相同的，GPU 可以流水线作业这个过程，从而更加有效的进行处理。使用正确优化过的着色器，在 GPU 上进行处理，将使你获得百倍于在 CPU 上用同样的过程进行图像处理的效率。

把东西渲染到屏幕上从一开始就是一个困扰 OpenGL 开发者的问题。仅仅让屏幕呈现出非黑色就要写很多样板代码和设置。开发者必须跳过很多坑 ，而这些坑所带来的沮丧感以及着色器测试方法的匮乏，让很多人放弃了哪怕是尝试着写着色器。

幸运的是，过去几年，一些工具和框架减少了开发者在尝试着色器方面的焦虑。

- [GPUImage](https://github.com/BradLarson/GPUImage)
- [ShaderToy](https://www.shadertoy.com/)
- [Shaderific](http://www.shaderific.com/)
- Quartz Composer

下面我将要写的每一个着色器的例子都是从开源框架 GPUImage 中来的。如果你对 OpenGL/OpenGL ES 场景如何配置，从而使其可以使用着色器渲染感到好奇的话，可以 clone 这个仓储。我们不会深入到怎样设置 OpenGL/OpenGL ES 来使用着色器渲染，这超出了这篇文章的范围。

## 我们的第一个着色器的例子

### 顶点着色器

好吧，关于着色器我们说的足够多了。我们来看一个实践中真实的着色器程序。这里是一个 GPUImage 中一个基础的顶点着色器：

```glsl
attribute vec4 position;
attribute vec4 inputTextureCoordinate；

varying vec2 textureCoordinate;

void main()
{
    gl_position = position;
    textureCoordinate = inputTextureCoordinate.xy;
}
```

我们一句一句的来看:

```glsl
attribute vec4 position;
```

像所有的语言一样，着色器语言的设计者也为常用的类型创造了特殊的数据类型，例如 2D 和 3D 坐标。这些类型是向量，稍后我们会深入更多。回到我们的应用程序的代码，我们创建了一系列顶点，我们为每个顶点提供的参数里的其中一个是顶点在画布中的位置。然后我们必须告诉我们的顶点着色器它需要接收这个参数，我们稍后会将它用在某些事情上。因为这是一个 C 程序，我们需要记住要在每一行代码的结束使用一个分号，所以如果你正使用 Swift 的话，你需要把在末尾加分号的习惯捡回来。

```glsl
attribute vec4 inputTextureCoordinate;
```

现在你或许很奇怪，为什么我们需要一个纹理坐标。我们不是刚刚得到了我们的顶点位置了吗？难道它们不是同样的东西吗？

其实它们并非一定是同样的东西。纹理坐标是纹理映射的一部分。这意味着你想要对你的纹理进行某种滤镜操作的时候会用到它。左上角坐标是 (0,0)。右上角的坐标是 (1,0)。如果我们需要在图片内部而不是边缘选择一个纹理坐标，我们需要在我们的应用中设定的纹理坐标就会与此不同，像是 (.25, .25) 是在图片左上角向右向下各图片高宽 1/4 的位置。在我们当前的图像处理应用里，我们希望纹理坐标和顶点位置一致，因为我们想覆盖到图片的整个长度和宽度。有时候你或许会希望这些坐标是不同的，所以需要记住它们未必是相同的坐标。在这个例子中，顶点坐标空间从 -1.0 延展到 1.0，而纹理坐标是从 0.0 到 1.0。

```glsl
varying vec2 textureCoordinate;
```

因为顶点着色器负责和片段着色器交流，所以我们需要创建一个变量和它共享相关的信息。在图像处理中，片段着色器需要的唯一相关信息就是顶点着色器现在正在处理哪个像素。

```glsl
gl_Position = position;
```
`gl_Position` 是一个内建的变量。GLSL 有一些内建的变量，在片段着色器的例子中我们将看到其中的一个。这些特殊的变量是可编程管道的一部分，API 会去寻找它们，并且知道如何和它们关联上。在这个例子中，我们指定了顶点的位置，并且把它从我们的程序中反馈给渲染管线。

```glsl
textureCoordinate = inputTextureCoordinate.xy;
```

最后，我们取出这个顶点中纹理坐标的 X 和 Y 的位置。我们只关心 `inputTextureCoordinate` 中的前两个参数，X 和 Y。这个坐标最开始是通过 4 个属性存在顶点着色器里的，但我们只需要其中的两个。我们拿出需要的属性，然后赋值给一个将要和片段着色器通信的变量，而不是把更多的属性反馈给片段着色器。

在大多数图像处理程序中，顶点着色器都差不多，所以，这篇文章接下来的部分，我们将集中讨论片段着色器。

### 片段着色器

看过了我们简单的顶点着色器后，我们再来看一个可以实现的最简单的片段着色器：一个直通滤镜：

```glsl
varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
}
```

这个着色器实际上不会改变图像中的任何东西。它是一个直通着色器，意味着我们输入每一个像素，然后输出完全相同的像素。我们来一句句的看：

```glsl
varying highp vec2 textureCoordinate;
```

因为片段着色器作用在每一个像素上，我们需要一个方法来确定我们当前在分析哪一个像素/片段。它需要存储像素的 X 和 Y 坐标。我们接收到的是当前在顶点着色器被设置好的纹理坐标。

```glsl
uniform sampler2D inputImageTexture;
```

为了处理图像，我们从应用中接收一个图片的引用，我们把它当做一个 2D 的纹理。这个数据类型被叫做 `sampler2D` ，这是因为我们要从这个 2D 纹理中采样出一个点来进行处理。

```glsl
gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
```

这是我们碰到的第一个 GLSL 特有的方法：`texture2D`，顾名思义，创建一个 2D 的纹理。它采用我们之前声明过的属性作为参数来决定被处理的像素的颜色。这个颜色然后被设置给另外一个内建变量，`gl_FragColor`。因为片段着色器的唯一目的就是确定一个像素的颜色，`gl_FragColor` 本质上就是我们片段着色器的返回语句。一旦这个片段的颜色被设置，接下来片段着色器就不需要再做其他任何事情了，所以你在这之后写任何的语句，都不会被执行。

就像你看到的那样，写着色器很大一部分就是了解着色语言。即使着色语言是基于 C 语言的，依然有很多怪异和细微的差别让它和普通的 C 语言有不同。

## GLSL 数据类型和运算

各式着色器都是用 OpenGL 着色语言 (GLSL) 写的。GLSL 是一种从 C 语言导出的简单语言。它缺少 C 语言的高级功能，比如动态内存管理。但是，它也包含一些在着色过程中常用的数学运算函数。

在负责 OpenGL 和 OpenGL ES 实现的 Khronos 小组的网站上有一些有用的参考资料。在你开始之前，一件你可以做的最有价值的事情就是获取 OpenGL 和 OpenGL ES 的快速入门指导：

- [OpenGL ES](https://www.khronos.org/opengles/sdk/docs/reference_cards/OpenGL-ES-2_0-Reference-card.pdf)
- [OpenGL](https://www.khronos.org/files/opengl-quick-reference-card.pdf)

通过查看这些参考卡片，你可以快速简单地了解在写 OpenGL 应用时需要的着色语言函数和数据类型。

尽早用，经常用。

即使在这么简单的着色器的例子里，也有一些地方看起来很怪异，不是吗？看过了基础的着色器之后，是时候开始解释其中一些内容，以及它们为什么存在于 GLSL 中。

## 输入，输出，以及精度修饰 (Precision Qualifiers)

看一看我们的直通着色器，你会注意到有一个属性被标记为 “varying”，另一个属性被标记为 “uniform”。

这些变量是 GLSL 中的输入和输出。它允许从我们应用的输入，以及在顶点着色器和片段着色器之间进行交流。

在 GLSL 中，实际有三种标签可以赋值给我们的变量：

- Uniforms
- Attributes
- Varyings

Uniforms 是一种外界和你的着色器交流的方式。Uniforms 是为在一个渲染循环里不变的输入值设计的。如果你正在应用茶色滤镜，并且你已经指定了滤镜的强度，那么这些就是在渲染过程中不需要改变的事情，你可以把它作为 Uniform 输入。 Uniform 在顶点着色器和片段着色器里都可以被访问到。

Attributes 仅仅可以在顶点着色器中被访问。Attribute 是在随着每一个顶点不同而会发生变动的输入值，例如顶点的位置和纹理坐标等。顶点着色器利用这些变量来计算位置，以它们为基础计算一些值，然后把这些值以 varyings 的方式传到片段着色器。

最后，但同样重要的，是 varyings 标签。Varying 在顶点着色器和片段着色器都会出现。Varying 是用来在顶点着色器和片段着色器传递信息的，并且在顶点着色器和片段着色器中必须有匹配的名字。数值在顶点着色器被写入到 varying ，然后在片段着色器被读出。被写入 varying 中的值，在片段着色器中会被以插值的形式插入到两个顶点直接的各个像素中去。

回看我们之前写的简单的着色器的例子，在顶点着色器和片段着色器中都用 varying 声明了 `textureCoordinate`。我们在顶点着色器中写入 varying 的值。然后我们把它传入片段着色器，并在片段着色器中读取和处理。

在我们继续之前，最后一件要注意的事。看看创建的这些变量。你会注意到纹理坐标有一个叫做 highp 的属性。这个属性负责设置你需要的变量精度。因为 OpenGL ES 被设计为在处理能力有限的系统中使用，精度限制被加入进来可以提高效率。

如果不需要非常高的精度，你可以进行设定，这或许会允许在一个时钟循环内处理更多的值。相反的，在纹理坐标中，我们需要尽可能的确保精确，所以我们具体说明确实需要额外的精度。

精度修饰存在于 OpenGL ES 中，因为它是被设计用在移动设备中的。但是，在老版本的桌面版的 OpenGL 中则没有。因为 OpenGL ES 实际上是 OpenGL 的子集，你几乎总是可以直接把 OpenGL ES 的项目移植到 OpenGL。如果你这样做，记住一定要在你的桌面版着色器中去掉精度修饰。这是很重要的一件事，尤其是当你计划在 iOS 和 OS X 之间移植项目时。

## 向量

在 GLSL 中，你会用到很多向量和向量类型。向量是一个很棘手的话题，它们表面上看起来很直观，但是因为它们有很多用途，这使我们在使用它们时常常会感到迷惑。

在 GLSL 环境中，向量是一个类似数组的特殊的数据类型。每一种类型都有固定的可以保存的元素。深入研究一下，你甚至可以获得数组可以存储的数值的精确的类型。但是在大多数情况下，只要使用通用的向量类型就足够了。

有三种向量类型你会经常看到：

- `vec2`
- `vec3`
- `vec4`

这些向量类型包含特定数量的浮点数：`vec2` 包含两个浮点数，`vec3` 包含三个浮点数，`vec4` 包含四个浮点数。 

这些类型可以被用在着色器中可能被改变或者持有的多种数据类型中。在片段着色器中，很明显 X 和 Y 坐标是的你想保存的信息。 (X,Y) 存储在 `vec2` 中就很合适。

在图像处理过程中，另一个你可能想持续追踪的事情就是每个像素的 R，G，B，A 值。这些可以被存储在 `vec4` 中。

## 矩阵

现在我们已经了解了向量，接下来继续了解矩阵。矩阵和向量很相似，但是它们添加了额外一层的复杂度。矩阵是一个浮点数数组的数组，而不是单个的简单浮点数数组。

类似于向量，你将会经常处理的矩阵对象是：

- `mat2`
- `mat3`
- `mat4`

`vec2` 保存两个浮点数，`mat` 保存相当于两个 `vec2` 对象的值。将向量对象传递到矩阵对象并不是必须的，只需要有足够填充矩阵的浮点数即可。在 `mat2` 中，你需要传入两个 `vec2` 或者四个浮点数。因为你可以给向量命名，而且相比于直接传浮点数，你只需要负责两个对象，而不是四个，所以非常推荐使用封装好的值来存储你的数字，这样更利于追踪。对于 `mat4` 会更复杂一些，因为你要负责 16 个数字，而不是 4 个。

在我们 `mat2` 的例子中，我们有两个 `vec2` 对象。每个 `vec2` 对象代表一行。每个 `vec2` 对象的第一个元素代表一列。构建你的矩阵对象的时候，确保每个值都放在了正确的行和列上是很重要的，否则使用它们进行运算肯定得不到正确的结果。

既然我们有了矩阵也有了填充矩阵的向量，问题来了：“我们要用它们做什么呢？“ 我们可以存储点和颜色或者其他的一些的信息，但是要如果通过修改它们来做一些很酷的事情呢？

## 向量和矩阵运算，也就是初等线性代数

我找到的最好的关于线性代数和矩阵是如何工作的资源是这个网站的[更好的解释](http://betterexplained.com/articles/linear-algebra-guide/)。我从这个网站<del>偷来</del>借鉴的一句引述就是：

> 线性代数课程的幸存者都成为了物理学家，图形程序员或者其他的受虐狂。

矩阵操作总体来说并不“难”；只不过它们没有被任何上下文解释，所以很难概念化地理解究竟为什么会有人想要和它们打交道。我希望能在给出一些它们在图形编程中的应用背景后，我们可以了解它们怎样帮助我们实现不可思议的东西。

线性代数允许你一次在很多值上进行操作。假想你有一组数，你想要每一个数乘以 2。你一般会一个个地顺次计算数值。但是因为对每一个数都进行的是同样的操作，所以你完全可以并行地实现这个操作。

我们举一个看起来可怕的例子，`CGAffineTransforms`。仿射转化是很简单的操作，它可以改变具有平行边的形状 (比如正方形或者矩形) 的大小，位置，或者旋转角度。

在这种时候你当然可以坐下来拿出笔和纸，自己去计算这些转化，但这么做其实没什么意义。GLSL 有很多内建的函数来进行这些庞杂的用来计算转换的函数。了解这些函数背后的思想才是最重要的。

## GLSL 特有函数

这篇文章中，我们不会把所有的 GLSL 内建的函数都过一遍，不过你可以在 [Shaderific](http://www.shaderific.com/glsl-functions) 上找到很好的相关资源。很多 GLSL 函数都是从 C 语言数学库中的基本的数学运算导出的，所以解释 sin 函数是做什么的真的是浪费时间。我们将集中阐释一些更深奥的函数，从而达到这篇文章的目的，解释怎样才能充分利用 GPU 的性能的一些细节。

**`step()`:** GPU 有一个局限性，它并不能很好的处理条件逻辑。GPU 喜欢做的事情是接受一系列的操作，并将它们作用在所有的东西上。分支会在片段着色器上导致明显的性能下降，在移动设备上尤其明显。`step()` 通过允许在不产生分支的前提下实现条件逻辑，从而在某种程度上可以缓解这种局限性。如果传进 `step()` 函数的值小于阈值，`step()` 会返回 0.0。如果大于或等于阈值，则会返回 1.0。通过把这个结果和你的着色器的值相乘，着色器的值就可以被使用或者忽略，而不用使用 `if()` 语句。

**`mix()`:**  mix 函数将两个值 (例如颜色值) 混合为一个变量。如果我们有红和绿两个颜色，我们可以用 `mix()` 函数线性插值。这在图像处理中很常用，比如在应用程序中通过一组独特的设定来控制效果的强度等。

**`clamp()`:* GLSL 中一个比较一致的方面就是它喜欢使用归一化的坐标。它希望收到的颜色分量或者纹理坐标的值在 0.0 和 1.0 之间。为了保证我们的值不会超出这个非常窄的区域，我们可以使用 `clamp()` 函数。 `clamp()` 会检查并确保你的值在 0.0 和 1.0 之间。如果你的值小于 0.0，它会把值设为 0.0。这样做是为了防止一些常见的错误，例如当你进行计算时意外的传入了一个负数，或者其他的完全超出了算式范围的值。 

## 更复杂的着色器的例子

我知道数学的洪水一定让你快被淹没了。如果你还能跟上我，我想举几个优美的着色器的例子，这会更有意义，这样你又有机会淹没在 GLSL 的潮水中。

### 饱和度调整

![实践中的饱和度滤镜](/images/issues/issue-21/Saturation.png)

这是一个做饱和度调节的片段着色器。这个着色器出自 《[图形着色器：理论和实践](http://www.amazon.com/Graphics-Shaders-Theory-Practice-Second/dp/1568814348/ref=sr_1_1?s=books&ie=UTF8&qid=1422557718&sr=1-1&keywords=graphics+shaders+theory+and+practice)》一书，我强烈推荐整本书给所有对着色器感兴趣的人。

饱和度是用来表示颜色的亮度和强度的术语。一件亮红色的毛衣的饱和度要远比北京雾霾时灰色的天空的饱和度高得多。

在这个着色器上，参照人类对颜色和亮度的感知过程，我们有一些优化可以使用。一般而言，人类对亮度要比对颜色敏感的多。这么多年来，压缩软件体积的一个优化方式就是减少存储颜色所用的内存。

人类不仅对亮度比颜色要敏感，同样亮度下，我们对某些特定的颜色反应也更加灵敏，尤其是绿色。这意味着，当你寻找压缩图片的方式，或者以某种方式改变它们的亮度和颜色的时候，多放一些注意力在绿色光谱上是很重要的，因为我们对它最为敏感。

```glsl
varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform lowp float saturation;

const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

void main()
{
   lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
   lowp float luminance = dot(textureColor.rgb, luminanceWeighting);
   lowp vec3 greyScaleColor = vec3(luminance);

	gl_FragColor = vec4(mix(greyScaleColor, textureColor.rgb, saturation), textureColor.w);

}
```

我们一行行的看这个片段着色器的代码：

```glsl
varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform lowp float saturation;
```

再一次，因为这是一个要和基础的顶点着色器通信的片段着色器，我们需要为输入纹理坐标和输入图片纹理声明一个 varyings 变量，这样才能接收到我们需要的信息，并进行过滤处理。这个例子中我们有一个新的 uniform 的变量需要处理，那就是饱和度。饱和度的数值是一个我们从用户界面设置的参数。我们需要知道用户需要多少饱和度，从而展示正确的颜色数量。

```glsl
const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
```

这就是我们设置三个元素的向量，为我们的亮度来保存颜色比重的地方。这三个值加起来要为 1，这样我们才能把亮度计算为 0.0 - 1.0 之间的值。注意中间的值，就是表示绿色的值，用了 70% 的颜色比重，而蓝色只用了它的 10%。蓝色对我们的展示不是很好，把更多权重放在绿色上是很有意义的。

```glsl
lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
```

我们需要取样特定像素在我们图片/纹理中的具体坐标来获取颜色信息。我们将会改变它一点点，而不是想直通滤镜那样直接返回。

```glsl
lowp float luminance = dot(textureColor.rgb, luminanceWeighting);
```

这行代码会让那些没有学过线性代数或者很早以前在学校学过但是很少用过的人看起来不那么熟悉。我们是在使用 GLSL 中的点乘运算。如果你记得在学校里曾用过点运算符来相乘两个数字的话，那么你就能明白是什么回事儿了。点乘计算以包含纹理颜色信息的 `vec4` 为参数，舍弃 `vec4` 的最后一个不需要的元素，将它和相对应的亮度权重相乘。然后取出所有的三个值把它们加在一起，计算出这个像素综合的亮度值。

```glsl
lowp vec3 greyScaleColor = vec3(luminance);
```

我们创建一个三个值都是亮度信息的 `vec3`。如果你只指定一个值，编译器会帮你把该将向量中的每个分量都设成这个值。

```glsl
gl_FragColor = vec4(mix(greyScaleColor, textureColor.rgb, saturation), textureColor.w);
```

最后，我们把所有的片段组合起来。为了确定每个新的颜色是什么，我们使用刚刚学过的很好用的 mix 函数。mix 函数会把我们刚刚计算的灰度值和初始的纹理颜色以及我们得到的饱和度的信息相结合。

这就是一个很棒的，好用的着色器，它让你用主函数里的四行代码就可以把图片从彩色变到灰色，或者从灰色变到彩色。还不错，不是吗？

### 球形折射

最后，我们来看一个很漂亮的滤镜，你可以用来向你的朋友炫耀，或者吓唬你的敌人。这个滤镜看起来像是有一个玻璃球在你的图片上。这会比之前的看起来更复杂。但我相信我们可以完成它。

![实践中的球形折射滤镜！](/images/issues/issue-21/sphereRefraction.png)

```glsl
varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform highp vec2 center;
uniform highp float radius;
uniform highp float aspectRatio;
uniform highp float refractiveIndex;

void main()
{
    highp vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
    highp float distanceFromCenter = distance(center, textureCoordinateToUse);
    lowp float checkForPresenceWithinSphere = step(distanceFromCenter, radius);

    distanceFromCenter = distanceFromCenter / radius;

    highp float normalizedDepth = radius * sqrt(1.0 - distanceFromCenter * distanceFromCenter);
    highp vec3 sphereNormal = normalize(vec3(textureCoordinateToUse - center, normalizedDepth));

    highp vec3 refractedVector = refract(vec3(0.0, 0.0, -1.0), sphereNormal, refractiveIndex);

    gl_FragColor = texture2D(inputImageTexture, (refractedVector.xy + 1.0) * 0.5) * checkForPresenceWithinSphere;
}
```

再一次，看起来很熟悉...

```glsl
uniform highp vec2 center;
uniform highp float radius;
uniform highp float aspectRatio;
uniform highp float refractiveIndex;
```

我们引入了一些参数，用来计算出图片中多大的区域要通过滤镜。因为这是一个球形，我们需要一个中心点和半径来计算球形的边界。宽高比是由你使用的设备的屏幕尺寸决定的，所以不能被硬编码，因为 iPhone 和 iPad 的比例是不相同的。我们的用户或者程序员会决定折射率，从而确定折射看起来是什么样子的。GPUImage 中折射率被设置为 0.71.

```glsl
highp vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
```

图像的纹理坐标是在归一化的 0.0-1.0 的坐标空间内。归一化的坐标空间意味着考虑屏幕是一个单位宽和一个单位长，而不是 320 像素宽，480 像素高。因为手机的高度比宽度要长，我们需要为球形计算一个偏移率，这样球就是圆的而不是椭圆的。

![我们希望正确的宽高比](/images/issues/issue-21/aspectRatio.png)


```glsl
highp float distanceFromCenter = distance(center, textureCoordinateToUse);
```

我们需要计算特定的像素点距离球形的中心有多远。我们使用 GLSL 内建的 `distance()` 函数，它会使用勾股定律计算出中心坐标和长宽比矫正过的纹理坐标的距离。

```glsl
lowp float checkForPresenceWithinSphere = step(distanceFromCenter, radius);
```

这里我们计算了片段是否在球体内。我们计算当前点距离球形中心有多远以及球的半径是多少。如果当前距离小于半径，这个片段就在球体内，这个变量被设置为 1.0。否则，如果距离大于半径，这个片段就不在球内，这个变量被设置为 0.0 。

![像素在球内或者球外](/images/issues/issue-21/distanceFromCenter2.png)

```glsl
distanceFromCenter = distanceFromCenter / radius;
```

By dividing it by the radius, we are making our math calculations easier in the next few lines of code.

既然我们已经计算出哪些像素是在球内的，我们接着要对这些球内的像素进行计算并做些事情。再一次，我们需要标准化到球心的距离。我们直接重新设置 `distanceFromCenter` 的值，而不是新建一个变量，因为那会增加我们的开销。 通过将它与半径相除，我们可以让之后几行计算代码变得简单一些。

```glsl
highp float normalizedDepth = radius * sqrt(1.0 - distanceFromCenter * distanceFromCenter);
```

因为我们试图模拟一个玻璃球，我们需要计算球的“深度”是多少。这个虚拟的球，不论怎样，在 Z 轴上，将会延伸图片表面到观察者的距离。这将帮助计算机确定如何表示球内的像素。还有，因为球是圆的，距离球心不同的距离，会有不同的深度。由于球表面方向的不同，球心处和边缘处对光的折射会不相同：

![球有多深?](/images/issues/issue-21/normalizedDepth.png)

```glsl
highp vec3 sphereNormal = normalize(vec3(textureCoordinateToUse - center, normalizedDepth));
```

这里我们又进行了一次归一化。为了计算球面某个点的方向，我们用 X ，Y 坐标的方式，表示当前像素到球心的距离，然后把这些和计算出的球的深度结合。然后把结果向量进行归一化。

想想当你正在使用 Adobe Illustrator 这样的软件时，你在 Illustrator 中创建一个三角形，但是它太小了。你按住 option 键，放大三角形，但是它现在太大了。你然后把它缩小到你想要的尺寸：

![什么是角?](/images/issues/issue-21/sphereNormal.png)

```glsl
highp vec3 refractedVector = refract(vec3(0.0, 0.0, -1.0), sphereNormal, refractiveIndex);
```

`refract()` 是一个很有趣的 GLSL 函数。`refract()` 以我们刚才创建的球法线和折射率来计算当光线通过这样的球时，从任意一个点看起来是怎样的。

```glsl
gl_FragColor = texture2D(inputImageTexture, (refractedVector.xy + 1.0) * 0.5) * checkForPresenceWithinSphere;
```

最后，通过所有这些障碍后，我们终于凑齐了计算片段使用的颜色所需要的所有信息。折射光向量用来查找读取的输入位于图片哪个位置的，但是因为在那个向量中，坐标是从 -1.0 到 1.0 的，我们需要把它调整到 0.0-1.0 的纹理坐标空间内。

我们然后把我们的结果和球边界检查的值相乘。如果我们的片段没有在球内，一个透明的像素 (0.0, 0.0, 0.0, 0.0) 将被写入。如果片段在球形内，这个结果被使用，然后返回计算好的颜色值。这样我们在着色器中可以就避免昂贵的条件逻辑。

## 调试着色器

着色器调试不是一件直观的工作。普通的程序中，如果程序崩溃了，你可以设置一个断点。这在每秒会被并行调用几百万次的运算中是不可能的。在着色器中使用 `printf()` 语句来调试哪里出错了也是不可能的，因为输出到哪里呢？考虑你的着色器运行在黑盒中，你怎么才能打开它然后看看为什么它们不工作呢？

你有一个可以使用的输出：我们的老朋友 `gl_FragColor`。`gl_FragColor` 会给你一个输出，换一种思路想一想，你可以用它来调试你的代码。

所有你在屏幕上看到的颜色都是由一系列的数字表示的，这些数字是每一个像素的红绿蓝和透明度的百分比。你可以用这些知识来测试着色器的每一部分是不是像你构建的那样工作，从而确定它是不是按照你想的那样在运行。和一般调试不同，你不会得到一个可以打印的值，而是拿到一个颜色以及和它相关的某个指定值，依靠这些你可以进行逆向反推。
 
如果想知道你的一个在 0 和 1 之间的值，你可以把它设置给一个将要传入 `gl_FragColor` 的 `vec4` 中。假设你把它设置进第一部分，就是红色值。这个值会被转换然后渲染到屏幕上，这时候你就可以检查它来确定原始的传进去的值是什么。

你会有几种方法来捕捉到这些值。从着色器输出的图片可以被捕获到然后作为图片写进磁盘里 (最好用户没有压缩过的格式)。这张图片之后就可以放进像 Photoshop 这样的应用，然后检查像素的颜色。

为了更快一些，你可以将图片用 OS X 的程序或者 iOS 的模拟器显示到屏幕上。在你的应用程序文件夹下的实用工具里有一个“数码测色计”的工具可以用来分析这些渲染过的视图。把鼠标放在桌面的任何一个像素点上，它都会精确的展示这个像素点 RGB 的值。因为 RGB 值在数码测色计和 Photoshop 中是从 0 到 255 而不是 从 0 到 1，你需要把你想要的值除以 255 来获得一个近似的输入值。

回顾下我们的球形折射着色器。简直无法想象没有任何测试就可以写下整个程序。我们有很大一块代码来确定当前处理的像素是不是在这个圆形当中。那段代码的结尾用 `step()` 函数来设置像素的这个值为 0.0 或者 1.0 。

把一个 `vec4` 的红色分量设为 `step()` 的输出，其他两个颜色值设为 0，然后传入`gl_FragColor` 中去。如果你的程序正确的运行，你将看到在黑色的屏幕上一个红色的圈。如果整个屏幕都是黑色，或者都是红色，那么肯定是有什么东西出错了。

## 性能调优

性能测试和调优是非常重要的事情。尤其是你想让你的应用在旧的 iOS 设备上也能流畅运行时。

测试着色器性能很重要，因为你总是不能确定一个东西的性能会怎样。着色器性能变化的很不直观。你会发现 Stack Overflow 上一个非常好的优化方案并不会加速你的着色器，因为你没有优化代码的真正瓶颈。即使仅只是调换你工程里的几行代码都有可能非常大的减少或增加渲染的时间。

分析的时候，我建议测算帧渲染的时间，而不是每秒钟渲染多少帧。帧渲染时间随着着色器的性能线性的增加或减少，这会让你观察你的影响更简单。FPS 是帧时间的倒数，在调优的时候可能会难于理解。最后，如果你使用 iPhone 的相机捕捉图像，它会根据场景的光亮来调整 FPS ，如果你依赖于此，会导致不准确的测量。

帧渲染时间是帧从开始处理到完全结束并且渲染到屏幕或者一张图片所花费的时间。许多移动 GPU 用一种叫做 “延迟渲染” 的技术，它会把渲染指令批量处理，并且只会在需要的时候才会处理。所以，需要计算整个渲染过程，而不是中间的操作过程，因为它们或许会以一种与你想象不同的顺序运行。

不同的设备上，桌面设备和移动设备上，优化也会很不相同。你或许需要在不同类型的设备上进行分析。例如，GPU 的性能在移动 iOS 设备上有了很大的提升。iPhone 5S 的 CPU 比 iPhone 4 快了接近十倍，而 GPU 则快上了好几百倍。

如果你在有着 A7 芯片或者更高的设备上测试你的应用，相比于 iPhone 5 或者更低版本的设备，你会获得非常不同的结果。[Brad Larson 测试了高斯模糊在不同的设备上花费的时间，并且非常清晰的展示了在新设备上性能有着令人惊奇的提升:](http://www.sunsetlakesoftware.com/2013/10/21/optimizing-gaussian-blurs-mobile-gpu)

<table><thead>
<tr>
<th>iPhone 版本</th>
<th> 帧渲染时间 (毫秒)</th>
</tr>
</thead><tbody>
<tr>
<td>iPhone 4</td>
<td>873</td>
</tr>
<tr>
<td>iPhone 4S</td>
<td>145</td>
</tr>
<tr>
<td>iPhone 5</td>
<td>55</td>
</tr>
<tr>
<td>iPhone 5S</td>
<td>3</td>
</tr>
</tbody></table>

你可以下载一个工具，[Imagination Technologies PowerVR SDK](http://community.imgtec.com/developers/powervr/)，它会帮助你分析你的着色器，并且让你知道着色器渲染性能的最好的和最坏的情况 。为了保持高帧速率，使渲染着色器所需的周期数尽可能的低是很重要的。如果你想达成 60 帧每秒，你只有 16.67 毫秒来完成所有的处理。

这里有一些简单的方式来帮助你达成目标：

- **消除条件逻辑:** 有时候条件逻辑是必须得，但尽量最小化它。在着色器中使用像 `step()`  函数这样的变通方法可以帮助你避免一些昂贵的条件逻辑。

- **减少依赖纹理的读取:** 在片段着色器中取样时，如果纹理坐标不是直接以 varying 的方式传递进来，而是在片段着色器中进行计算时，就会发生依赖纹理的读取。依赖纹理的读取不能使用普通的纹理读取的缓存优化，会导致读取更慢。例如，如果你想从附近的像素取样，而不是计算和片段着色器中相邻像素的偏差，最好在顶点着色器中进行计算，然后把结果以 varying 的方式传入片段着色器。在 [Brad Larson的文章](http://objccn.io/issue-21-8)中关于索贝尔边缘检测的部分有一个这方面的例子。

- **让你的计算尽量简单:** 如果你在避免一个昂贵的操作情况下可以获得一个近似的足够精度的值，你应该这样做。昂贵的计算包括调用三角函数 (像`sin()`, `cos()`, 和 `tan()`)。

- **如果可以的话，把工作转移到顶点着色器:**  之前讲的关于依赖纹理的读取就是把纹理坐标计算转移到顶点着色器的很有意义的一种情况。如果一个计算在图片上会有相同的结果，或者线性的变化，看看能不能把计算移到顶点着色器进行。顶点着色器对每个顶点运行一次，片段着色器在每个像素上运行一次，所以在前者上的计算会比后者少很多。

- **在移动设备上使用合适的精度** 在特定的移动设备上，在向量上使用低精度的值会变得更快。在这些设备上，两个 `lowp vec4` 相加的操作可以在一个时钟周期内完成，而两个 `highp vec4` 相加则需要四个时钟周期。但是在桌面 GPU 和最近的移动 GPU 上，这变得不再那么重要，因为它们对低精度值的优化不同。

## 结论和资源

着色器刚开始看起来很吓人，但它们也仅仅是改装的 C 程序而已。创建着色器相关的所有事情，我们大多数都在某些情况下处理过，只不过在不同的上下文中罢了。

对于想深入了解着色器的人，我非常推荐的一件事就是回顾下三角学和线性代数。做相关工作的时候，我遇到的最大的阻力就是忘了很多大学学过的数学，因为我已经很长时间没有实际使用过它们了。

如果你的数学有些生疏了，我有一些书可以推荐给你：

- [3D Math Primer for Graphics and Game Development](http://www.amazon.com/Math-Primer-Graphics-Game-Development/dp/1568817231/ref=sr_1_1?ie=UTF8&qid=1422837187&sr=8-1&keywords=3d+math+primer+for+graphics+and+game+development)
- [The Nature of Code](http://natureofcode.com)
- [The Computational Beauty of Nature](http://www.amazon.com/Computational-Beauty-Nature-Explorations-Adaptation/dp/0262561271/ref=sr_1_1?s=books&ie=UTF8&qid=1422837256&sr=1-1&keywords=computational+beauty+of+nature)

也有数不清的关于GLSL书和特殊着色器被我们行业突出的人士创造出来：

- [Graphics Shaders: Theory and Practice](http://www.amazon.com/Graphics-Shaders-Theory-Practice-Second/dp/1568814348/ref=sr_1_1?s=books&ie=UTF8&qid=1422837351&sr=1-1&keywords=graphics+shaders+theory+and+practice)
- [The OpenGL Shading Language](http://www.amazon.com/OpenGL-Shading-Language-Randi-Rost/dp/0321637631/ref=sr_1_1?s=books&ie=UTF8&qid=1422896457&sr=1-1&keywords=opengl+shading+language)
- [OpenGL 4 Shading Language Cookbook](http://www.amazon.com/OpenGL-Shading-Language-Cookbook-Second/dp/1782167021/ref=sr_1_2?s=books&ie=UTF8&qid=1422896457&sr=1-2&keywords=opengl+shading+language)
- [GPU Gems](http://http.developer.nvidia.com/GPUGems/gpugems_part01.html)
- [GPU Pro: Advanced Rendering Techniques](http://www.amazon.com/GPU-Pro-Advanced-Rendering-Techniques/dp/1568814720/ref=sr_1_4?s=books&ie=UTF8&qid=1422837427&sr=1-4&keywords=gpu+pro)

还有，再一次强调，[GPUImage](https://github.com/BradLarson/GPUImage)是一个开源的资源，里面有一些非常酷的着色器。一个非常好的学习着色器的方式，就是拿一个你觉得很有意思的着色器，然后一行一行看下去，搜寻任何你不理解的部分。GPUImage 还有一个[着色器设计](https://github.com/BradLarson/GPUImage/tree/master/examples/Mac/ShaderDesigner)的 Mac 端应用，可以让你测试着色器而不用准备 OpenGL 的代码。

学习有效的在代码中实现着色器可以给你带来很大的性能提升。不仅如此，着色器也使你可以做以前不可能做出来的东西。

学习着色器需要一些坚持和好奇心，但是并不是不可能的。如果一个 33 岁的还在康复中的新闻专业的人都能够克服她对数学的恐惧来处理着色器的话，那么你肯定也可以。

---

 

原文 [GPU-Accelerated Image Processing](http://www.objc.io/issue-21/gpu-accelerated-image-processing.html)

