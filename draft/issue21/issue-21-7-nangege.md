---
title: "GPU-Accelerated Image Processing"
category: "21"
date: "2015-02-10 06:00:00"
author: "<a href=\"https://twitter.com/RedQueenCoder\">Janie Clayton</a>"
tags: article
---

Instagram. Snapchat. Photoshop.

Instagram,Snapchat,Photoshop。

All of these applications are used to do image processing. Image processing can be as simple as converting a photo to grayscale and as complex as analyzing a video of a crowd for a specific person. In spite of how divergent these applications are, both of these examples go through the same process from creation to rendering.

所有这些应用都是用来做图像处理的。图像处理可以简单到把一张照片转换为灰度图，也可以复杂到是分析一个视频，在人群中找到某个特定的人。尽管这些应用非常的不同，这些例子遵从同样的流程，都是从创造到渲染。

There are many ways to process images on your computer or mobile phone, but by far the most efficient is effectively using your Graphics Processing Unit, or GPU. Your phone contains two different processing units, the CPU and the GPU. The CPU is a generalist that has to deal with everything, while your GPU can focus on doing one thing really well, which is doing floating point math in parallel. It turns out that image processing and rendering is nothing more than doing a lot of floating-point math on the values for the pixels that render to your screen.

在电脑或者手机上做图像处理有很多方式，但是目前为止最有效的方法是有效的使用图形处理单元，或者叫GPU。你的手机包含两个不同的处理单元，CPU和GPU。CPU是个多面手，并且不得不处理所有的事情，而GPU则可以集中来处理好一件事情，就是并行的做浮点运算。事实上，图像处理和渲染就是在将要渲染到窗口上的像素上做许许多多的浮点运算。

By effectively utilizing your GPU, you can increase graphics-rendering performance on your phone by a hundred fold, if not a thousand fold. Being able to filter high-quality live video on your phone is impractical or even impossible without GPU-based processing.

通过有效的利用GPU，可以上百倍甚至上千倍的提高手机上的图像渲染能力。如果不是基于GPU的处理，手机上实时高清视频滤镜是不现实，甚至不可能的。

The tool we use to take advantage of this power is a shader. A shader is a small, C-based program written in a shading language. There are many shading languages out there on the market, but the one you should focus on if you are doing OS X or iOS development is the OpenGL Shading Language, or GLSL. You can take the concepts from GLSL and apply them to other, more proprietary languages like the Metal Shading Language. The concepts we are going over here even map well to custom kernels in Core Image, although they use a slightly different syntax.

着色器(shader)是我们利用这种能力的工具。着色器是用着色语言写的小的，C语言基础的程序。市场上有很许多种着色语言。但你如果做 OS X 或者 IOS 开发的话，你应该专注于 OpenGL着色语言，或者叫GLSL。你可以应用GLSL的理念到其他的更专用的语言，像 Metal 着色语言。这里我们即将介绍的概念甚至和Core Image 中的自定义内核很好的对应，尽管他们在语法上有一些不同。

This process can be incredibly daunting, especially to newer developers. The purpose of this article is to get your feet wet with some foundation information necessary to get you going on your journey to writing your own image processing shaders.

这个过程可能会很让人恐惧，尤其是对新手。这篇文章的目的是让你接触一些写图像处理着色器的必要的基础信息。

## What is a Shader?

## 什么是着色器

We're going to take a short trip in The Wayback Machine to get an overview of what a shader is and how it came to be an integral part of our workflow.

我们将回顾一下过去，从而了解什么是着色器，以及它是怎样被集成到我们的工作流当中的。

If you've been doing iOS programming since at least iOS 5, you might be aware that there was a shift in OpenGL programming on the iPhone, from OpenGL ES 1.1 to OpenGL ES 2.0.

如果你在 IOS 5 或者之前就开始做 IOS 开发，你或许会知道在 iPhone 上 OpenGL 编程有一个转变，从 OpenGL ES 1.1 到 openGL ES 2.0。

OpenGL ES 1.1 did not use shaders. Instead, OpenGL ES 1.1 used what is called a fixed-function pipeline. Instead of creating a separate program to direct the operation of the GPU, there was a set of fixed functions that you used to render objects on the screen. This was incredibly limiting, and you weren't able to get any specialized effects. If you want a good example of how much of a difference shaders can make in a project, [check out this blog post Brad Larson wrote about refactoring his Molecules app using shaders instead of the fixed-function pipeline.](http://www.sunsetlakesoftware.com/2011/05/08/enhancing-molecules-using-opengl-es-20)

OpenGL ES 1.1 没有使用着色器。作为替代，OpenGL ES 1.1 使用被称为固定功能(fixed-function) 管线的方式。有一系列固定的函数用来在屏幕上渲染对象，而不是创建一个单独的程序来指导 GPU 的行为。这样有很大的局限性，你不能做出任何特殊的效果。如果你想知道着色器在工程中可以造成怎样的不同，[看看这篇Brad Larson写的他用着色器替代固定函数重构 Molecules App 的博客](http://www.sunsetlakesoftware.com/2011/05/08/enhancing-molecules-using-opengl-es-20)

OpenGL ES 2.0 introduced the programmable pipeline. The programmable pipeline allowed you to go in and write your own shaders, giving you far more power and flexibility.

OpenGL ES 2.0 引入可编程管线。可编程管线允许你写自己的着色器，给你更强大的能力和灵活性。

There are two kinds of shader files that you must create in OpenGL ES: vertex shaders and fragment shaders. These shaders are two halves of a whole program. You can't just create one or the other; both must be present to comprise a whole shader program.

在 OpenGL ES 中你必须创建两种着色器：顶点着色器（vertex shaders）和片段着色器（fragment shaders）。这两种着色器在整个程序中的两半，你不能仅仅创建其中任何一个；创建一个完整的着色程序，两个都是必须得。

Vertex shaders customize how geometry is handled in a 2D or 3D scene. A vertex is a point in 2D or 3D space. In the case of image processing, we have four vertices: one for each corner of your image. The vertex shader sets the position of a vertex and sends parameters like positions and texture coordinates to the fragment shader.

顶点着色器定义了在2D或者3D场景中几何图形是如何处理的。顶点是 2D 或者 3D 空间中的一个点。在图像处理中，有4个顶点：每一个顶点代表图像的一个角。顶点着色器设置顶点的位置，并且把位置和纹理坐标这样的参数发送到片段着色器。

Your GPU then uses a fragment shader to perform calculations on each pixel in an object or image, ending with the final color for that pixel. An image, when you get right down to it, is simply a collection of data. The image document contains parameters for the value of each pixel, for each color component, and for the pixel's opacity. Because the equations are the same for each pixel, the GPU is able to streamline the process and do it more efficiently. If you are optimizing your shader properly, you can process image data on the GPU more than 100 times faster than if you were to run the same process on the CPU.

然后 GPU 使用片段着色器在对象或者图片的每一个像素上进行计算，最终计算出每个像素的最终颜色。图片，归根结底，实际上仅仅是数据的集合。图片的文档包含每一个像素的各个颜色分量和像素透明度的值。因为对每一个像素，算式是相同的，GPU可以流水线作业这个过程，从而更加有效的进行处理。正确的的优化着色器，进行同样的处理，在GPU上，你将获得百倍于CPU的图像处理效率。

One issue that has plagued OpenGL developers from the beginning is just being able to render anything on the screen. There is a lot of boilerplate code and setup that needs to be done just to get a screen that isn't black. The frustration and the inability to test out shaders because of all the hoops developers had to jump through in the past has discouraged a lot of people from even trying to get involved in writing shaders.

把东西渲染到屏幕上从一开始就是一个困扰 OpenGL 开发者的问题。仅仅让屏幕变成不是黑色就要写很多样板代码和设置。开发者必须跳过很多坑 ，由此带来的沮丧感以及没办法测试着色器，让很多人放弃了哪怕是尝试着写着色器。

Fortunately, in the last few years, several tools and frameworks have been made available to take some of the anxiety out of trying out shaders:

- [GPUImage](https://github.com/BradLarson/GPUImage)
- [ShaderToy](https://www.shadertoy.com/)
- [Shaderific](http://www.shaderific.com/)
- Quartz Composer

幸运的是，过去几年，一些工具和框架减少了开发者在尝试着色器方面的焦虑。

- [GPUImage](https://github.com/BradLarson/GPUImage)
- [ShaderToy](https://www.shadertoy.com/)
- [Shaderific](http://www.shaderific.com/)
- Quartz Composer

Each of the shader examples I am going through here comes from the open-source GPUImage framework. If you are more curious about how an OpenGL/OpenGL ES scene is configured to render using shaders, feel free to clone the repository. I will not be going into how to set up OpenGL/OpenGL ES to render using shaders like this, as it is beyond the scope of the article.

下面我将要写的每一个着色器的例子都是从开源框架 GPUImage 中来的。如果你对 OpenGL/OpenGL ES 场景如何配置，从而使其可以使用着色器渲染感到好奇，随意 clone 这个仓储。我们不会深入到怎样设置 OpenGL/OpenGL ES 来使用着色器渲染，这超出了这篇文章的范围。


## Our First Shader Example ##

## 我们的第一个着色器的例子 ##

### The Vertex Shader ###

### 顶点着色器 ###

Alright, enough talking about shaders. Let’s see an actual shader program in action. Here is the baseline vertex shader in GPUImage:

```glsl
attribute vec4 position;
attribute vec4 inputTextureCoordinate;

varying vec2 textureCoordinate;

void main()
{
    gl_Position = position;
    textureCoordinate = inputTextureCoordinate.xy;
}
```


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


Let's take this piece by piece:

```glsl
attribute vec4 position;
```

我们一句一句的来看:

```glsl
attribute vec4 position;
```

Like all languages, the designers of our shading language knew to create special data types for commonly used types, such as 2D and 3D coordinates. These types are vectors, which we will go into more depth with a little later. Back in our application code, we are creating a list of vertices, and one of the parameters we provide per vertex is its position within our canvas. We then have to tell our vertex shader that it needs to take that parameter and that we are going to use it for something. Since this is a C program, we need to remember to use a semicolon at the end of each line of code, so if you are coding in Swift you need to remember to pick the semicolon habit back up.

像所有的语言一样，着色器语言的设计者知道怎样为常用的类型创造特殊的数据类型，例如 2D 和 3D 坐标。这些类型是向量，稍后我们会深入更多。回到我们的应用程序的代码，我们创建了一列顶点，我们为每个顶点提供的参数中的一个是顶点在画布中的位置。然后我们必须告诉我们的顶点着色器它需要接收这个参数，我们稍后会将它用在某些事情上。因为这是一个 c 程序，我们需要记住要在没一行代码的结束使用一个分号，所以如果你正使用 swift,你需要把在末尾加分号的习惯捡起来。

```glsl
attribute vec4 inputTextureCoordinate;
```
```glsl
attribute vec4 inputTextureCoordinate;
```

At this point you might be wondering why we are getting a texture coordinate. Didn't we just get our vertex position? Aren't these the same thing?

现在你或许很奇怪，为什么我们需要一个纹理坐标。我们不是刚刚得到了我们的顶点位置了吗？他们不是同样的东西吗？

No, not necessarily. A texture coordinate is part of a texture map. What this means is that you have the image you want to filter, which is your texture. The upper left-hand corner has a coordinate space of (0, 0). The upper right-hand corner has a coordinate space of (1,0). If we wanted to select a texture coordinate that was inside the image and not at the edges, we would specify that the texture coordinate was something else in our base application, like (.25, .25), which would be located a quarter of the way in and down on our image. In our current image processing application, we want the texture coordinate and the vertex position to line up because we want to cover the entire length and breadth of our image. There are times where you might want these positions to be different, so it's important to remember that they don't necessarily need to be the same coordinate. Also, the coordinate space for vertices in this example extends from −1.0 to 1.0, where texture coordinates go from 0.0 to 1.0.

是的，其实不是必须得。纹理坐标是纹理地图的一部分。这意味着你有自己想要过滤的图片，那就是你的纹理。左上角坐标是 (0,0)。右上角的坐标是 (1,0).如果我们需要在图片内部而不是边缘选择一个纹理坐标，我们需要在我们的应用中指出纹理坐标是其他的坐标,像 (.25,.25),这是在图片里的一个方形。在当前的图像处理应用里，我们希望纹理坐标和顶点位置一致，因为我们想覆盖到图片的整个长度和宽度。有时候你或许会希望这些坐标是不同的，所以需要记住他们未必是相同的坐标。在这个例子中，顶点坐标空间从 -1.0 延展到 1.0，而纹理坐标是从 0.0 到 1.0。

```glsl
varying vec2 textureCoordinate;
```
```glsl
varying vec2 textureCoordinate;
```

Since the vertex shader is responsible for communicating with the fragment shader, we need to create a variable that will share pertinent information with it. With image processing, the only piece of pertinent information it needs from the vertex shader is what pixel is it currently working on.

因为顶点着色器负责和片段着色器交流，我们需要创建一个变量和它共享相关的信息。在图像处理中，它需要的唯一顶点着色器的共享信息就是他现在作用在哪个像素上。

```glsl
gl_Position = position;
```

```glsl
gl_Position = position;
```

`gl_Position` is a built-in variable. GLSL has a few built-in variables, one of which we will see in the fragment shader example. These are special variables that are a part of the programmable pipeline that the API knows to look for and knows how to associate. In this case, we are specifying the vertex position and feeding that from our base program to the render pipeline.

`gl_Position` 是一个内建的变量。GLSL 有一些内建的变量，在片段着色器的例子中我们将看到其中的一个。有一些特殊的变量是可编程管道的一部分， API 会去寻找他们以及如何知道和它们关联上。在这个例子中，我们指定顶点的位置，并且把它从我们的程序中反馈给渲染管线。

```glsl
textureCoordinate = inputTextureCoordinate.xy;
```

```glsl
textureCoordinate = inputTextureCoordinate.xy;
```

Finally, we are extracting the X and Y positions of the texture coordinate at this vertex. We only care about the first two components of `inputTextureCoordinate`, X and Y. The coordinate was initially fed into the vertex shader with four attributes, but we only care about two of them. Instead of feeding more attributes than we need to to our fragment shader, we are stripping out the ones we need and assigning them to a variable type that will talk to the fragment shader.

最后，我们取出这个顶点中，纹理坐标的 x 和 y 的位置。我们只关心 `inputTextureCoordinate`中的前两个参数，X 和 Y。这个坐标最开始是通过4个属性存在顶点着色器里，但我们只需要其中的两个。我们拿出需要的属性，然后赋值给一个将要和片段着色器通信的变量，而不是把更多的属性反馈给片段着色器。

This vertex shader stays pretty much the same for all of our various image filter programs, so the rest of the shaders we will be focusing on for this article will be fragment shaders.

在大多数图像处理程序中，顶点着色器都差不多，所以，这篇文章接下来的部分，我们将集中在片段着色器。

### The Fragment Shader ###

### 片段着色器 ###

Now that we have gone over our simple vertex shader, let's take a look at the simplest fragment shader you can implement: a passthrough filter:

```glsl
varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
}
```

看过了我们简单的顶点着色器后，我们再来看一个可以实现的最简单的片段着色器：一个直通过滤器：

```glsl
varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
}
```

This shader isn’t really changing anything in our image. It’s a passthrough shader, which pretty much means we are inputting each pixel and outputting the exact same one. Let’s also go through this piece by piece:

```glsl
varying highp vec2 textureCoordinate;
```

这个着色器实际上不会改变图像中的任何东西。它是一个直通过滤器，意味着我们输入每一个像素，然后输出完全相同的像素。我们来一句句的看：

```glsl
varying highp vec2 textureCoordinate;
```

Since the fragment shader works on each and every pixel, we need a way to determine which pixel/fragment we are currently analyzing. It needs to store both the X and the Y coordinate for the pixel. We are receiving the current texture coordinate that was set up in the vertex shader.

因为片段着色器作用在每一个像素上，我们需要一个方法来确定我们当前在分析哪一个像素/片段。它需要存储像素 X 和 Y 坐标。我们接收当前在顶点着色器被设置好的纹理坐标。

```glsl
uniform sampler2D inputImageTexture;
```

In order to process an image, we are receiving a reference to the image from the application, which we are treating as a 2D texture. The reason this data type is called a `sampler2D` is because we are using the shader to go in and pluck out a point in that 2D texture to process.

```glsl
uniform sampler2D inputImageTexture;
```

为了处理图像，我们从应用中接收一个图片的引用，我们把它当做一个2D 的纹理。这个数据类型被叫做`sampler2D` ，因为我们我们用这个着色器在这个 2D 纹理中找到一个点来处理。

```glsl
gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
```

This is our first encounter with a GLSL-specific function: `texture2D` is a function that, just as it sounds, creates a 2D texture. It takes our properties declared above as parameters to determine the exact color of the pixel being analyzed. This is then set to our other built-in variable, `gl\_FragColor`. Since the only purpose of a fragment shader is to determine what color a pixel is, `gl\_FragColor` essentially acts as a return statement for our fragment shader. Once the fragment color is set, there is no longer any point in continuing to do anything else in a fragment shader, so if you write any code after this line, it will not be processed.

```glsl
gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
```
这是我们碰到的第一个 GLSL 特有的方法：`texture2D`，顾名思义，创建一个 2D 的纹理。它采用我们之前声明过的属性作为参数来决定被处理的像素的颜色。这个颜色然后被设置给其他的内建变量，`gl\_FragColor`。因为片段着色器的唯一目的就是确定一个像素的颜色，`gl\_FragColor` 本质上是我们片段着色器返回语句。一旦这个片段的颜色被设置，接下来片段着色器不会做其他的任何事情，所以你在这之后写任何的语句，都不会被执行。


As you can see, a vital part of writing shaders is to understand the shading language. Even though the shading language is based on C, there are lots of quirks and nuances that differentiate it from plain, vanilla C.

就像你看到的那样，写着色器很大一部分就是了解着色语言。即使着色语言是基于 C 语言的，依然有很多怪异和细微的差别让它和普通的 C 语言有不同。


## GLSL Data Types and Operations ##

## GLSL 数据类型和运算 ##

Shaders of all flavors are written in the OpenGL Shading Language (GLSL). GLSL is a simple language derived from C. It is lacking in some of the more advanced features of C, such as dynamic memory management. However, it also contains a lot of specialized functionality to process commonly used mathematical functions in the shading process.

所有着色器都是用 OpenGL 着色语言 (GLSL) 写的。GLSL 是一种从 C 语言导出的简单语言。它缺少 C 语言的高级功能，比如动态内存管理。但是，它也包含一些在着色过程中常用的数学运算函数。

The Khronos Group, which is responsible for maintaining OpenGL and OpenGL ES, has reference materials for both available through its website. One of the most valuable things you can do for yourself when you are starting out is obtaining the Language Quick Reference cards for OpenGL ES and OpenGL:

- [OpenGL ES](https://www.khronos.org/opengles/sdk/docs/reference_cards/OpenGL-ES-2_0-Reference-card.pdf)
- [OpenGL](https://www.khronos.org/files/opengl-quick-reference-card.pdf)

负责 OpenGL 和 OpenGL ES 实现的 Khronos 小组，通过它的网站，指出了一些有用的材料。在你开始之前，一件你可以做的最有价值的事情就是获取 OpenGL 和 OpenGL ES 的快速入门指导：

- [OpenGL ES](https://www.khronos.org/opengles/sdk/docs/reference_cards/OpenGL-ES-2_0-Reference-card.pdf)
- [OpenGL](https://www.khronos.org/files/opengl-quick-reference-card.pdf)


These cards contain a quick and easy way to look over the language for the function or data type information you need to write an OpenGL application.

这些卡片包含查看写 OpenGL 应用需要的着色语言函数和数据类型的快速简单的方法。

Use these early. Use them often.

尽早用，经常用。

There are quite a few things in even that simple shader that look completely alien, aren’t there? Now that we’ve had a chance to take a look at a very basic shader, it’s time to start explaining what some of its contents are, and why we have them in GLSL.

即使在这么简单的着色器的例子里，也有一些看起来很怪异，不是吗？看过了基础的着色器之后，是时候开始解释其中一些内容，以及他们为什么存在于 GLSL 中。

## Inputs, Outputs, and Precision Qualifiers ##

## 输入，输出，以及 精度修饰 ##

If you look at our passthrough shader, you will notice that we had one property that was labeled “varying,” and another one that was labeled “uniform.”

看一看我们的直通着色器，你会注意到有一个属性被标记为 “varying,”，另一个属性被标记为 “uniform.”

These variables are our inputs and outputs in GLSL. They allow input from our application and communication from the vertex shader to the fragment shader.

这些变量是 GLSL 中的输入和输出。它允许从我们应用的输入，以及顶点着色器和片段着色器的交流。

There are actually three labels we can assign to our variables in GLSL:

- Uniforms
- Attributes
- Varyings

在 GLSL 中，实际有三种标签可以赋值个我们的变量：

- Uniforms
- Attributes
- Varyings


Uniforms are one way for the outside world to communicate with your shaders. Uniforms are designed for input values that aren't going to change within a render cycle. If you are applying a sepia filter and you need to specify the strength of the filter, this is something that isn't going to change within a render pass, so you'd send it in as a uniform. Uniforms can be accessed in both the vertex and the fragment shader.

Uniforms 是一种外界和你的着色器交流的方式。Uniforms 是为在一个渲染循环里不变的输入值设计的。如果你正在应用棕色着色器，并且你需要指定过滤器的强度，这个强度就是在渲染过程中不需要改变的事情，你需要把它作为 Uniform 输入。 Uniform 在顶点着色器和片段货色器都可以被访问。

Attributes are only available in the vertex shader. Attributes are the input values that change with each vertex, such as its position and texture coordinate. The vertex shader takes in these values and either uses them to calculate the position, or passes values based on them along to the fragment shader in varyings.

Attributes 仅仅可以在顶点着色器中被访问。Attribute 是在每一个顶点中都会变动的输入值，例如它的位置和纹理坐标。顶点着色器利用这些变量来计算位置，以他们为基础计算一些值，然后把这些值以 varyings 的方式传到片段着色器。

Last, but not least, we have varyings. Varyings are present in both the vertex and the fragment shader. Varyings are used to pass information from the vertex shader to the fragment shader, and must have matching names in both. Values are written to varyings in the vertex shader and read in the fragment shader. Values written into varyings are interpolated between vertices for each of the between-vertex pixels acted on by a fragment shader.

最后，但同样重要的，我们有 varyings。Varying  在顶点着色器和片段着色器都会出现。Varying是用来在顶点着色器和片段着色器传递信息的，并且在定点着色器和片段着色器中必须有匹配的名字。数值在顶点着色器被写入到 varying ，然后在片段着色器被读出。写入 varying 中的值，在片段着色器中被插入到每一个顶点像素中间。

If you look back at our simple shader example, we had a varying declared in both the vertex and the fragment shader: `textureCoordinate`. We wrote the value of that varying in the vertex shader. We then passed it to the fragment shader, where it was read and processed.

回看我们之前写的简单的着色器的例子，在顶点着色器和片段着色器中都有 varying 的声明：`textureCoordinate `。我们在顶点着色器中写入 varying 的值。然后我们把它传入片段着色器，在片段着色器中被读取和处理。

One last quick thing to mention before we move on. Look at those variables you created. You will notice that your texture coordinate has an attribute called “highp.” This attribute is setting the precision you need for this variable. Since OpenGL ES was designed to be on systems with limited processing power, precision qualifiers were added for efficiency.

在我们继续之前，最后一件要注意的事。看看创建的这些变量。你会注意到纹理坐标有一个叫做 highp 的变量。这个属性是设置你需要的变量精度的。因为 OpenGL ES被设计为在处理能力有限的系统中使用，精度限制被加入进来以提高效率。

If you have something that doesn’t have to be very precise, you can indicate that and possibly allow more of these values to be operated on in a single clock cycle. On the other hand, in the case of the texture coordinate, we care a great deal about making sure this is as precise as possible, so we specify that we do indeed need this extra precision.

如果不需要非常高的精度，你可以指出来，这或许会允许在一个时钟循环内更多的值被处理。相反的，在纹理坐标中，我们需要尽可能的确保精确，所以我们具体说明确实需要额外的精度。

Precision qualifiers exist in OpenGL ES because they are geared toward mobile devices. However, they are missing in older versions of desktop OpenGL. Since OpenGL ES is effectively a subset of OpenGL, you can almost always directly port an OpenGL ES project to OpenGL. If you do that, however, you do need to remember to strip the precision qualifiers out of your desktop shaders. This is an important thing to keep in mind, especially if you are planning to port your application between iOS and OS X.

精度修饰存在于 OpenGL ES 中，因为它是被设计用在移动设备中的。但是，在老版本的桌面版的 OpenGL 中则没有。因为OpenGL ES 实际上是 OpenGL的子集，你几乎总是可以直接把 OpenGL ES 的项目移植到 OpenGL。如果你这样做，记住一定要在你的桌面版着色器中去掉精度修饰。这是很重要的一件事，尤其是当你计划在 IOS 和 OS X之间移植项目。

## Vectors ##

## 向量 ##

You are going to work with a lot of vectors and vector types in GLSL. Vectors are a slightly tricky topic in that they are seemingly straightforward, but since they are so versatile, there is a lot of information out there that can be confusing about them.

在 GLSL 中，你会用到很多向量和向量类型。向量是一个很棘手的话题，因为他们表面上很直观，但是因为他们有很多用途，有很多信息使他们很迷惑。

In the context of GLSL, vectors are a specialized data type similar to an array. Each type has a fixed value of elements that it can hold. If you dig in a little further, you can get even more specialized about the exact type of number value the array can hold, but for most purposes, sticking to the generic vector types will work just fine.

在 GLSL 环境中，向量是一个类似数组的特殊的数据类型。每一种类型都有固定的可以保存的元素。深入研究一下，你甚至可以获得数组可以存储的数值的精确的类型。但是在大多数情况下，集中在通用的向量类型就足够了。

There are three vector types you will see over and over again:

- `vec2`
- `vec3`
- `vec4`

有四种向量类型你会经常看到：

- `vec2`
- `vec3`
- `vec4`

These vector types contain a specified number of floating-point values: `vec2` contains two floating-point values, `vec3` contains three floating-point values, and `vec4` contains four floating-point values.

这些向量类型包含特定数量的浮点数： `vec2` 包含两个浮点数，`vec3` 包含三个浮点数，`vec4` 包含四个浮点数。 

These types can be applied to several kinds of data you want to modify and persist in your shaders. One of the more obvious things you would want to keep track of is the X and Y coordinates of your fragment. An (X,Y) would fit quite nicely into the `vec2` data type.

这些类型可以被用在多种在你的着色器中想改变或者持有的数据。在片段着色器中，很明显 X 和 Y 坐标是的你想保存的信息。 (X,Y) 存储在 `vec2` 中很合适。

Another thing that you tend to keep track of in graphics processing are the red, green, blue, and alpha values of each pixel. Those can be nicely stored in a `vec4` data type.

在图像处理过程中，另一个你可能想持续追踪的事情就是每个像素的 R，G，B ,A 值。这些可以被存储在 `vec4` 中。

## Matrices ##

## 矩阵 ##

Now that we have a handle on vectors, let’s move on to matrices. Matrices are very similar to vectors, but they add an additional layer of complexity. Instead of simply being an array of floating-point values, matrices are an array of an array of floating-point values.

现在我们已经了解了向量，接下来继续了解矩阵。矩阵和向量很相似，但是他们添加了额外一层的复杂度。矩阵是一个浮点数数组的数组，而不是一个简单的浮点数数组。

As with vectors, the matrix objects you are going to deal with most often are:

- `mat2`
- `mat3`
- `mat4`

类似于向量，你将会经常处理的矩阵对象是：

- `mat2`
- `mat3`
- `mat4`


Where `vec2` holds two floating-point values, `mat2` holds the equivalent of two `vec2` objects. You don’t need to pass vector objects into your matrix objects, as long as you account for the correct number of floating-point elements needed to fill the matrix. In the case of the `mat2` object, you would either need to pass in two `vec2` objects or four floating-point values. Since you can name your vectors and you would only be responsible for two objects instead of four, it is highly encouraged for you to encapsulate your numbers in values that you can keep track of more easily. This only gets more complex when you move on to the `mat4` object and you are responsible for 16 numbers instead of four!

`vec2` 保存两浮点数，`mat` 保存相当于两个 `vec2` 对象的值。你不需要传递向量对象到矩阵对象，只需要足够填充矩阵的浮点数即可。在 `mat2` 中，你需要传入两个 `vec2` 或者四个浮点数，因为可以给向量命名，你只需要负责两个对象，而不是四个，非常推荐用更容易追踪的值来存储你的数字。对于 `mat4` 会更复杂一些，因为你要负责16个数字，而不是4个。


In our `mat2` example, we have two sets of `vec2` objects. Each `vec2` object represents a row. The first element of each `vec2` represents a column. It’s very important to make sure that you are placing each value in the correct row and column when you are constructing your matrix object, or else the operations you perform on them will not work successfully.

在我们 `mat2` 的例子中，我们有两个 `vec2` 对象。每个 `vec2` 对象代表一行。每个 `vec2` 对象的第一个元素代表一列。构建你的矩阵对象的时候，确保每个值都放在了正确的行和列上是很重要的，否则在它们上进行运算不会成功奏效。

So now that we have matrices and vectors to fill the matrices, the important question is: “What do we do with these?” We can store points and colors and other bits of information, but how does that get us any closer to making something cool by modifying them?

既然我们有了矩阵也有了填充矩阵的向量，问题来了：“我们用他们做什么呢？“ 我们可以存储点和颜色或者其他的一些的信息，但是通过修改他们怎么会让我们做一些很酷的事情呢？

## Vector and Matrix Operations, AKA Linear Algebra 101 ##

## 向量和矩阵运算，AKA线性运算101##

One of the best resources I have found out there to simply explain how linear algebra and matrices work is the site [Better Explained](http://betterexplained.com/articles/linear-algebra-guide/). One of the quotes I have stolen, er, borrowed from this site is the following:

> The survivors of linear algebra classes are physicists, graphics programmers, and other masochists.

我找到的最好的关于线性运算和矩阵是如何工作的资源是这个网站[更好的解释](http://betterexplained.com/articles/linear-algebra-guide/).我从这个网站偷，额，借得一句引述就是：

> 线性运算课的幸存者是物理学家，图形程序员或者其他的受虐狂。

Matrix operations generally aren’t “hard”; they just are not explained with any kind of context, so it’s difficult to conceptualize why on earth anyone would want to work with them. Hopefully by giving a little bit of context insofar as how they are utilized in graphics programming, we can get a sense of how they can help us implement awesome stuff.

矩阵操作总体来说并不“难”；只不过他们没有被任何上下文解释，所以很难概念化到底为什么会有人想要和他们工作。希望给一些他们是怎样应用在图形编程中的背景后，我们可以了解他们怎样帮助我们实现不可思议的东西。

Linear algebra allows you to perform an action on many values at the same time. Let’s say you have a group of numbers and you want to multiply each of them by two. You are transforming each number in a consistent way. Since the same operation is being done to each number, you can implement this operation in parallel.

线性运算允许你一次在很多数据上操作。假想你有一组数，你想要每一个数乘以2。你是用一种固定的方式转化数值。因为同样的操作作用在每一个数上，你可以并行的实现这个操作。

One example we should be using but seem to be afraid of is that of `CGAffineTransforms`. An affine transform is simply an operation that changes the size, position, or rotation of a shape with parallel sides, like a square or a rectangle.

我们举一个看起来可怕的例子，`CGAffineTransforms`。仿射转化是很简单的操作，它改变具有平行边的形状，例如正方形和矩形的大小，位置，或者角度。

It isn’t super important at this juncture to break out the old slide rule and be able to sit down with a pad of graph paper and a pencil and calculate your own transforms. GLSL has a lot of built-in functions that do the messy work of calculating out your transforms for you. It’s just important to have an idea of how these functions are working under the hood.

在这个时候能够坐下来拿出笔和值，自己计算转化不是那么重要。GLSL有很多内建的函数来做这些庞杂的用来计算转换的函数。了解这些函数背后是怎样运行的才是重要的。

## GLSL-Specific Functions ##

## GLSL 特有的函数 ##

We’re not going to go over all of the built-in functions for GLSL in this article, but a good resource for this can be found at [Shaderific](http://www.shaderific.com/glsl-functions). The vast majority of the GLSL functions are derived from basic math operations that are present in the C Math Library, so it isn’t really a good use of time to explain what the sin function does. We’re going to stick to some of the more esoteric functions for the purposes of this article, in order to explain some of the nuances of how to get the best performance out of your GPU.

这篇文章中，我们不会一一的看所有的GLSL内建的函数，不过关于这些在[着色器专有](http://www.shaderific.com/glsl-functions)有很好的资源。很多GLSL函数都是从C 语言数学库中的基本的数学运算导出的，所以解释sin函数式做什么的真的是浪费时间。我们将集中在一些难解的函数，从而达到这篇文章的目的，解释怎样才能充分利用GPU的性能的一些细节。

**`step()`:** One limitation that your GPU has is that it doesn’t really deal well with conditional logic. The GPU likes to take a bunch of operations and just apply them to everything. Branching can lead to significant slowdowns in fragment shaders, particularly on mobile devices. `step()` works around this limitation somewhat by allowing conditional logic without branching. If a variable passed into a `step()` function is less than a threshold value, `step()` returns 0.0. If the variable is greater or equal, it returns 1.0. By multiplying this result times values in your shader, values can be used or ignored based on conditional logic, all without an `if()` statement.

**`step()`:** GPU有一个局限性，它并不能很好的处理条件逻辑。GPU喜欢一系列的操作作用在所有的事情上。分支会在片段着色器上导致明显的性能下降，在移动设备上尤其明显。`step()` 通过允许条件逻辑不产生分支，从而从某种程度上可以缓解这种局限性。如果传进 `step()` 函数的值小于阈值，`step()` 会返回 0.0。如果大于或等于阈值，则会返回1.0。通过把这个结果和你的着色器的值相乘，着色器的值就可以被使用或者忽略，而不用使用  `if()`  语句。

**`mix()`:** The mix function blends two values (such as colors) to a variable degree. If we had two colors of red and green, we could linearly interpolate between them using a `mix()` function. This is commonly used in image processing to control the strength of an effect in response to a uniform set by the application.

**`mix()`:**  mix 函数混合两个值（例如颜色值）到可变的程度。如果我们有两个颜色红和绿，我们可以用mix函数线性差值。这在图像处理中很常用，用在应用程序控制的一些全局的设置，比如特效的强度。

**`clamp()`:** One of the consistent aspects of GLSL is that it likes to use normalized coordinates. It wants and expects to receive values between 0.0 and 1.0 for things like color components or texture coordinates. In order to make sure that our values don't stray outside of this very narrow parameter, we can implement the `clamp()` function. The `clamp()` function checks to make sure your value is between 0.0 and 1.0. If your value is below 0.0, it will set its value to 0.0. This is done to avoid any general wonkiness that might arise if you are trying to do calculations and you accidentally receive a negative number or something that is entirely beyond the scope of the equation.

**`clamp()`:* GLSL中一个比较一致的方面就是它喜欢使用归一化的坐标。它希望收到的颜色分量或者纹理坐标的值在 0.0 和 1.0 之间。为了保证我们的值不会超出这个非常窄的区域，我们可以实现 `clamp()` 函数。 `clamp()` 会检查并确保你的值在 0.0 和 1.0 之间。如果你的值小于 0.0，它会把值设为 0.0。这样做是为了防止计一些常见的错误，例如当你进行计算但是你意外的传入了一个负数，或者其他的完全超出了算式范围的值。 

## More Complex Shader Examples

## 更复杂的着色器的例子 ##

I realize that deluge of math must have felt very overwhelming. If you’re still with me, I want to walk through a couple of neat shader examples that will make a lot more sense now that you’ve have a chance to wade into the GLSL waters.

我知道数学的洪水一定让你快被淹没了。如果你还能跟上我，我想举几个优美的着色器的例子，这会更有意义，这样你又有机会淹没在 GLSL 的潮水中。

### Saturation Adjustment

### 饱和度调整

![Saturation Filter in Action](/images/issue-21/Saturation.png)

![实践中的饱和度过滤器](http://img.objccn.io/issue-21/Saturation.png)

This is a fragment shader that does saturation adjustment. This shader is based off of code from the book "[Graphics Shaders: Theory and Practice](http://www.amazon.com/Graphics-Shaders-Theory-Practice-Second/dp/1568814348/ref=sr_1_1?s=books&ie=UTF8&qid=1422557718&sr=1-1&keywords=graphics+shaders+theory+and+practice)," which I highly recommend to anyone interested in learning more about shaders.

这是一个做饱和度调节的片段着色器。这个着色器出自 "[图形着色器：理论和实践](http://www.amazon.com/Graphics-Shaders-Theory-Practice-Second/dp/1568814348/ref=sr_1_1?s=books&ie=UTF8&qid=1422557718&sr=1-1&keywords=graphics+shaders+theory+and+practice),"，我强烈推荐整本书给所有对着色器感兴趣的人。

Saturation is the term used to describe how bright and intense a color is. A bright red sweater is far more saturated than the gloomy, gray winter skies in rural Wisconsin.

饱和度是用来表示颜色的亮度和强度的术语。一个亮红色的毛衣要比威斯康星州冬季灰色的天空的饱和度更高。

There are some optimizations we can utilize in this shader that work with the way that human beings perceive color and contrast. Generally speaking, human beings are far more sensitive to brightness than we are to color. One optimization made over the years to our compression software is to pare back the amount of memory used to store color.

在这个着色器上，我们有一些优化可以使用，就像人类对颜色和亮度的感知那样。一般而言，人类对亮度要比对颜色敏感的多。这么多年来，压缩软件体积的一个优化方式就是减少存储颜色所用的内存。

Not only are humans more sensitive to brightness than color, but we are also more responsive to certain colors within the brightness spectrum, specifically green. This means that when you are calculating out ways of compressing your photos or modifying their brightness or color in some way, it’s important to put more emphasis on the green part of the spectrum, because that is the one that we respond to the most:

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

人类不仅对亮度比颜色要敏感，同样亮度下，我们队某些特定的颜色反应也更加灵敏，尤其是绿色。这意味着，当你寻找压缩图片的方式，或者以某种方式改变它们的亮度和颜色的时候，多放一些注意力在绿色光谱上是很重要的，因为我们对它更敏感。

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

Let's go through this fragment shader line by line:

```glsl
varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform lowp float saturation;
```

我们一行行的看这个片段着色器的代码：

```glsl
varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform lowp float saturation;
```

Again, since this is a fragment shader that is talking to our baseline vertex shader, we do need to declare varyings for our input texture coordinate and our input image texture, in order to receive the information we need to process our filter. We do have a new uniform that we are dealing with in this example, which is saturation. Saturation amount is a parameter we are set up to receive from the user interface. We need to know how much saturation the user wants in order to present the correct amount of color.

再一次，因为这是一个要和基础的顶点着色器通信的片段着色器，我们需要为输入纹理坐标和输入图片纹理声明一个 varyings 变量，这样才能接受到我们需要的信息来进行过滤处理。这个例子中我们有一个新的 uniform 的变量需要处理，那就是饱和度。饱和度的数量是一个我们从用户界面设置的参数。我们需要知道用户需要多少饱和度，从而展示正确的颜色数量。

```glsl
const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
```
```glsl
const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
```

This is where we are setting up a three-component vector to store our color weighting for our luminance extraction. All three of these values must add up to 1.0 so that we can calculate the luminance of a pixel on a scale from 0.0 to 1.0. Notice that the middle number, which represents green, uses 70 percent of the available color weighting, while blue only uses a tenth of that. The blue doesn’t show up as well to us, and it makes more sense to weigh toward green instead for brightness.

这就是我们设置三个元素的向量，为我们的亮度来保存颜色比重的地方。这三个值加起来要为 1，这样我们才能把亮度计算为 0.0 - 1.0 之间的值。注意中间的值，就是表示绿色的值，用了 70% 的颜色比重，而蓝色只用了10%。蓝色对我们的展示不是很好，把更多权重放在绿色上是很有意义的。

```glsl
lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
```
```glsl
lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
```

We need to capture the color information about our specific pixel by sampling its exact coordinate within our image/texture. Instead of simply returning this value as we did with the passthrough filter, we are going to modify it and change it up a little.

我们需要取样特定像素在我们图片/纹理中的具体坐标来获取颜色信息。我们将会改变它一点点，而不是想直通过滤器那样直接返回。

```glsl
lowp float luminance = dot(textureColor.rgb, luminanceWeighting);
```
```glsl
lowp float luminance = dot(textureColor.rgb, luminanceWeighting);
```
This line will probably look unfamiliar to anyone who either never took linear algebra or who took it so long ago that dinosaurs were used to ride to school. We are using the dot product function from GLSL. If you remember using a dot symbol to multiply two numbers together in school, you’re on the right track here. The dot product is taking our `vec4` containing the texture color information for the fragment, dropping the last parameter because it won’t be needed, and multiplying it by its corresponding luminance weight. Then it is taking all three of those values and adding them together to figure out the overall luminance of the pixel.

这行代码会让那些没有学过线性代数或者很早以前学过但是很少用过的人看起来不那么熟悉。我们是在使用 GLSL 中的点乘运算。如果你记得在学校里用点运算符相乘两个数字，那么你在正确的轨道里。点乘计算以包含纹理颜色信息的 `vec4` 为参数，舍弃 `vec4` 的最后一个不需要的元素，将它回相对应的亮度权重相乘。然后取出所有的三个值把它们加在一起，计算出这个像素综合的亮度值。

```glsl
lowp vec3 greyScaleColor = vec3(luminance);
```
```glsl
lowp vec3 greyScaleColor = vec3(luminance);
```

Now we are creating a `vec3` that contains the luminance for all three values. If you only specify one value, the compiler knows enough to set it for each slot in that vector.

我们创建一个包含三个值亮度信息的 `vec3`。如果你只指定一个值，编译器知道怎样正确的设置每一个值。

```glsl
gl_FragColor = vec4(mix(greyScaleColor, textureColor.rgb, saturation), textureColor.w);
```
```glsl
gl_FragColor = vec4(mix(greyScaleColor, textureColor.rgb, saturation), textureColor.w);
```

Finally, we are putting all of our pieces together. In order to determine what the new value of each color is, we are applying our handy dandy mix function that we learned about a little while ago. The mix function is taking the grayscale color we just determined, combining it with the initial texture color, and basing the ratio of the mix on the information we are getting back about the saturation level.

最后，我们把所有的片段组合起来。为了确定每个新的颜色是什么，我们使用刚刚学过的好用的花哨的 mix 函数。mix 函数把我们刚刚计算的灰度值和初始的纹理颜色以及我们得到的饱和度的信息相结合。 

So here is a nice, handy shader that lets you change your image from color to grayscale and back with only four lines of code in the main function. Not too bad, huh?

这就是一个很棒的，好用的着色器，它让你用主函数里的四行代码就可以把图片从彩色到灰色，或者从灰色到彩色。还不错，不是吗？

### Sphere Refraction

### 球形折射

Finally, we’re going to go over a really nifty filter that you can pull out to impress your friends and terrify your enemies. This filter makes it look like there is a glass sphere sitting on top of your image. It's going to be quite a bit more complicated than the previous ones, but I have confidence that we can do it!

最后，我们来看一个很漂亮的过滤器，你可以用来向你的朋友炫耀，或者吓吓你的敌人。这个过滤器看起来像是有一个玻璃球在你的图片上。这会比之前的看起来更复杂。但我相信我们可以完成它。

![Sphere Refraction Filter in Action!](/images/issue-21/sphereRefraction.png)
![实践中的球形折射滤镜！](http://img.objccn.io/issue-21/sphereRefraction.png)

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

Once more, with feeling...

再一次，看起来很熟悉...

```glsl
uniform highp vec2 center;
uniform highp float radius;
uniform highp float aspectRatio;
uniform highp float refractiveIndex;
```

```glsl
uniform highp vec2 center;
uniform highp float radius;
uniform highp float aspectRatio;
uniform highp float refractiveIndex;
```

We are bringing in a few parameters that we need in order to calculate out how much of our image is going to go through the filter. Since this is a sphere, we need a center point and a radius to calculate where the edges of the sphere are. The aspect ratio is determined by the screen size of whatever device you are using, so it can’t be hardcoded, because an iPhone has a different screen ratio than an iPad does. Our user or the programmer will decide what he or she wants the refractive index to be to determine how the refraction looks. The refractive index set in GPUImage is 0.71.

我们引入了一些参数，用来计算出图片中多大的区域要通过滤镜。因为这是一个球形，我们需要一个中心点和半径来计算球形的边界。宽高比是由你使用的设备的屏幕尺寸决定的，所以不能被硬编码，因为iPhone 和 iPad 的比例是不相同的。我们的用户或者程序员会决定折射率，从而确定反射看起来是什么样子的。GPUImage 中折射率被设置为0.71.

```glsl
highp vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
```

```glsl
highp vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
```

The texture coordinates of our image are in a normalized 0.0-1.0 coordinate space. Normalized coordinate spaces means that instead of thinking of the phone as being 320 pixels across and 480 pixels high, the screen is one unit long and one unit wide. Since the phone is taller than it is long, we need to calculate an offset ratio for our sphere so that the sphere is round instead of oval:

图像的纹理坐标是在归一化的 0.0-1.0 的坐标空间内。归一化的坐标空间意味着考虑屏幕是一个单位长和一个单位宽，而不是 320 像素宽 ，480 像素高。因为手机的高度比宽度要长，我们需要为球形计算一个偏移率，这样球就是圆的而不是椭圆的。

![We want a correct aspect ratio](/images/issue-21/aspectRatio.png)
![我们希望正确的宽高比](http://img.objccn.io/issue-21/aspectRatio.png)


```glsl
highp float distanceFromCenter = distance(center, textureCoordinateToUse);
```

```glsl
highp float distanceFromCenter = distance(center, textureCoordinateToUse);
```

We need to calculate how far away from the center of the sphere our specific pixel is. We are using the `distance()` function built into GLSL, which takes the Pythagorean distance between the center coordinate and the aspect-ratio-corrected texture coordinate.

我们需要计算特定的像素点距离球形的中心有多远。我们使用 CLSL 内建的 `distance()` 函数，它会计算出中心坐标和长宽比矫正过的纹理坐标的毕达哥拉斯距离。

```glsl
lowp float checkForPresenceWithinSphere = step(distanceFromCenter, radius);
```

```glsl
lowp float checkForPresenceWithinSphere = step(distanceFromCenter, radius);
```

Here is where we are going to figure out if our fragment resides within the sphere. We are checking to see how far away we are from the center of the sphere and what the radius is. If our distance is shorter than the radius, then the fragment exists within the sphere and this variable is set to 1.0. If, however, the distance from the center is longer than the radius, the fragment does not live within the sphere and this gets set to 0.0:

![Pixels are either inside or outside the sphere](/images/issue-21/distanceFromCenter2.png)

这里我们用来计算片段是否在球体内。我们计算当前点距离球形中心有多远以及球的半径是多少。如果当前距离小于半径，这个片段就在球体内，这个变量被设置为 1.0。但是，如果距离大于半径，这个片段就不在球内，这个变量被设置为 0.0 。

![像素在球内或者球外](http://img.objccn.io/issue-21/distanceFromCenter2.png)

```glsl
distanceFromCenter = distanceFromCenter / radius;
```

```glsl
distanceFromCenter = distanceFromCenter / radius;
```

Now that we have determined which pixels exist within the sphere, we are going to move on to calculating what to do with the ones that do exist in the sphere. Again, we need to normalize our distance from the center. Rather than creating a whole new variable, which adds to the overhead in our program, we are going to reset the `distanceFromCenter` variable. By dividing it by the radius, we are making our math calculations easier in the next few lines of code.

既然我们已经计算出哪些像素是在球内的，我们接着计算对这些球内的像素做些什么。再次，我们需要标准化到球心的距离。我们直接重新设置 `distanceFromCenter` 的值，而不是新建一个变量，因为那会增加我们的开销。 

```glsl
highp float normalizedDepth = radius * sqrt(1.0 - distanceFromCenter * distanceFromCenter);
```

```glsl
highp float normalizedDepth = radius * sqrt(1.0 - distanceFromCenter * distanceFromCenter);
```

Since we are trying to emulate a glass sphere, we need to figure out how “deep” the sphere is. The virtual sphere, for all intents and purposes, is extending a distance up from the image surface toward the viewer in the z-axis. This is going to be used to help the computer figure out how to model the pixels that exist within the sphere. Also, since a sphere is round, there will be different depths for the sphere depending upon how far away you are from the center. The center of the sphere will refract light differently than the edges, due to the different orientations of the surface:

![How deep is the sphere?](/images/issue-21/normalizedDepth.png)

因为我们试图模拟一个玻璃球，我们需要计算球的深度是多少。这个虚拟的球，不论怎样，在 Z 轴上，将会延伸图片表面到观察者的距离。这将帮助计算机确定如何表示球内的像素。还有，因为球是圆的，距离球心不同的距离，会有不同的深度。由于球表面方向的不同，球心处和边缘处对光的反射会不相同：

![球有多深?](http://img.objccn.io/issue-21/normalizedDepth.png)

```glsl
highp vec3 sphereNormal = normalize(vec3(textureCoordinateToUse - center, normalizedDepth));
```

Again, we are back to normals, huzzah. To describe the orientation of the sphere surface at a point, we take the distance of the current pixel from the center of the sphere in X and Y, and combine those components with the sphere depth we calculated. We then normalize the resulting vector to have a length of one.

再一次，我们进行归一化。为了计算球面某个点的方向，我们用 X ，Y 坐标的方式，表示当前像素到球心的距离，然后把这些和计算出的球的深度结合。然后把结果向量归一化为 1 。

Think about when you are using something like Adobe Illustrator. You create a triangle in Illustrator, but it's too small. You hold down the option key and you resize the triangle, except now it's too big. You then scale it down to get it to be the exact size you want:

![What's the angle?](/images/issue-21/sphereNormal.png)

想想当你正在使用 adobe Illustrator 这样的软件。你在 Illustrator 中创建一个三角形，但是它太小了。你按住 option 键，放大三角形，但是它现在太大了。你然后把它缩小到你想要的尺寸：

![什么是角?](http://img.objccn.io/issue-21/sphereNormal.png)

```glsl
highp vec3 refractedVector = refract(vec3(0.0, 0.0, -1.0), sphereNormal, refractiveIndex);
```

```glsl
highp vec3 refractedVector = refract(vec3(0.0, 0.0, -1.0), sphereNormal, refractiveIndex);
```

`refract()` is a fun GLSL function. `refract()` is taking in the sphere normal we just created and using the refractive index to calculate how light passing through a sphere of this type would look at any given point.

`refract()` 是一个很有趣的 GLSL 函数。`refract()` 以我们刚才创建的球法线和折射率来计算当光线通过这样的球时，从任意一个点看起来是怎样的。

```glsl
gl_FragColor = texture2D(inputImageTexture, (refractedVector.xy + 1.0) * 0.5) * checkForPresenceWithinSphere;
```

```glsl
gl_FragColor = texture2D(inputImageTexture, (refractedVector.xy + 1.0) * 0.5) * checkForPresenceWithinSphere;
```

Finally, after jumping through all these hoops, we have gathered together all of the pieces we need to figure out what color to use for the fragment. The refracted light vector is used to find which location on the input image to read from, but because the coordinates in that vector range from −1.0 to 1.0, we adjust that to lie within the 0.0–1.0 texture coordinate space.

最后，通过所有这些障碍后，我们终于凑齐了计算片段使用的颜色所需要的所有信息。折射光向量是用来查找读取输入图片哪个位置的，但是因为在那个向量中，坐标是从 -1.0 到 1.0 的，我们需要把它调整到 0.0 -1.0 的纹理坐标空间内。

We then multiply our effect by the value we got from our sphere bounds check. If our fragment doesn’t lie within the sphere, a transparent pixel (0.0, 0.0, 0.0, 0.0) is written. If the fragment is present within the sphere, the effect is applied and the calculated color returned. This allows us to avoid expensive conditional logic for the shader.

我们然后把我们的结果和球边界检查的值相乘。如果我们的片段没有在球内，一个透明的像素 (0.0, 0.0, 0.0, 0.0) 将被写入。如果片段在球形内，这个结果被使用，然后返回计算好的颜色值。这样我们在着色器中可以就避免昂贵的条件逻辑。

## Debugging Shaders

## 着色器调试

Debugging shaders is not a straightforward task. In your normal program, if the program crashes, you can set a breakpoint. That isn't really possible to do on an operation that gets called in parallel millions of times a second. It also isn't feasible to use `printf()` statements in your shaders to debug what is going wrong, because where would the output even go? Given that your shaders seem to be living in a black box, how do you crack them open to find out why they aren't working?

着色器调试不是一个直观的工作。普通的程序中，如果程序崩溃了，你可以设置一个断点。这在每秒会被并行调用几百万次的运算中是不可能的。在着色器中使用 `printf()` 语句来调试哪里出错了也是不可能的，因为输出到哪里呢？考虑你的着色器运行在黑盒中，你怎么才能打开它然后看看为什么它们不工作呢？
 
You have one output at your disposal: our old friend `gl\_FragColor`. `gl\_FragColor` gives you an output that, with a little lateral thinking, you can use to debug your code.

你有一个可以使用的输出：我们的老朋友 `gl\_FragColor`。`gl\_FragColor` 会给你一个输出，换一种思路想一想，你可以用它来调试你的代码。

All colors you see on the screen are represented by a series of numbers, which are a percentage of the amount of red, green, blue, and opacity each individual pixel contains. You can use this knowledge to test each part of your shader as you construct it to make sure that it is performing the way you would like. Instead of getting back a printed value, you would get back a color with a specific associated value that you can reverse engineer.

所有你在屏幕上看到的颜色都是由一系列的数字表示的，这些数字是每一个像素的红绿蓝和透明度的百分比。你可以用这些知识来测试着色器的每一部分是不是想你构建的那样，从而确定它是不是按照你想的那样运行。你会得一个颜色，和一个可以逆向的关联的值，而不是一个可以打印的值。

If you want to know the value of one of your variables that is between zero and one, you can set it to part of the `vec4` that gets passed to the `gl\_FragColor`. Let's say you set it to the first part, which is the red value. That value will be converted and rendered to the screen, at which point you can examine it to determine what the original value was that was passed in.
 
如果想知道你的一个在0和1之间的值，你可以把它设置给一个将要传入 `gl\_FragColor` 的`vec4`中。假设你把它设置进第一部分，就是红色值。这个值会被转换然后渲染到屏幕上，这时候你就可以检查它来确定原始的传进去的值是什么。

You can then capture these values in a couple of ways. The output image from your shader could be captured and written to disk as an image (preferably in an uncompressed format). This image could then be pulled into an application like Photoshop and the pixel colors examined.

你会有几种方法来捕捉到这些值。从着色器输出的图片可以被捕获到然后作为图片写进磁盘里（最好用户没有压缩过的格式）。这张图片之后就可以放进像 Photoshop 这样的应用，然后检查像素的颜色。

For faster turnaround, you could render your image to the screen in an OS X application, or an iOS one running in the Simulator. To analyze these rendered views, there is a tool included in your Utilities folder in your Applications folder called "Digital Color Meter." If you hover your mouse over any pixel on your desktop, it will show you the exact RGB component of that pixel. Since RGB values in Digital Color Meter and Photoshop are from 0 to 255 instead of 0 to 1, you need to divide the specific value you want by 255 to get an approximate value of what the initial passed-in value was.

为了更快一些，你可以将图片用 OS X的程序或者 IOS 的模拟器显示到屏幕上。在你的应用文件夹下的工具文件夹下有一个 "数码测色计" 的工具可以用来分析这些显示的窗口。把鼠标放在桌面的任何一个像素点上，它都会精确的展示这个像素点 RGB 的值。因为RGB值在数码测色计和 Photoshop 中是从 0 到 255 而不是 从 0 到 1，你需要把你想要的值除以 255 来获得一个近似的输入值。

Let's look back at our sphere refraction shader. We wouldn't want to try to write the whole shader without doing any debugging on it. We have the specific chunk of code to determine if the pixel we are currently looking at is within the circle or not. That block of code ends with a `step()` function that sets the value of a pixel to either 0.0 or 1.0.

回顾下我们的球形折射着色器。简直无法想象没有任何测试就可以写下整个程序。我们有很大一块代码来确定当前处理的像素是不是在这个圆形当中。那段代码的结尾用 `step()` 函数来设置像素的这个值为 0.0 或者 1.0 。

If you passed a `vec4` to the `gl\_FragColor`, where the red value was whatever the `step()` function value was, and the other two colors were set to 0.0, you should see a red circle on a black screen if your code is working properly. If the whole screen is either black or red, then something has gone terribly wrong.

把一个红色值是 `step()` 的输出，其他两个颜色值为 0 的 `vec4` 传入`gl\_FragColor`,如果你的程序正确的运行，你讲看到在黑色的屏幕上一个红色的圈。如果整个屏幕都是黑色，或者都是红色，那么肯定是有什么东西出错了。

## Performance Tuning

## 性能调优

Performance tuning and profiling are incredibly important things to do, especially if you are trying to target your application to run smoothly on older iOS devices.

性能调优和分析是非常重要的事情。尤其是你想让你的应用在旧的IOS设备上流畅的运行时。

Profiling your shader is important, because you can't always be sure how performant something will be. Shader performance changes in nonintuitive ways. You might find a great optimization on Stack Overflow that does nothing to speed up your shader because you didn't optimize where the actual bottleneck was in your processing code. Even switching a couple of lines of code in your project can vastly increase or decrease the amount of time it takes for your frame to render.

分析着色器很重要，因为你总是不能确定多么高性能。着色器性能变化的很不直观。你会发现 Stack Overflow 上一个非常好的优化方案并不会加速你的着色器，因为你没有优化代码的真正瓶颈。即使调换你工程里的几行代码都有可能非常大的减少或增加渲染的时间。

When profiling, I recommend measuring frame rendering time, rather than focusing on frames per second (FPS). Frame rendering time increases or decreases linearly with the performance of your shader, which makes it easy to see the impact you're having. FPS is the inverse of frame time, and it can be harder to understand when tuning. Lastly, if you're capturing from the iPhone's video camera, it will adjust incoming FPS depending upon the lighting in your scene, which can lead to incorrect measurements if you rely on that.

分析的时候，我建议测算帧渲染的时间，而不是每秒钟渲染多少帧。帧渲染时间随着着色器的性能线性的增加或减少，这会让你的观察你的影响更简单。FPS 是帧时间的倒数，在调优的时候可能会难于理解。最后，如果你使用 iPhone 的相机捕捉图像，它会根据场景的光亮来调整 FPS ，如果你依赖于此，会导致不准确的测量。

The frame rendering time is the amount of time it takes for the frame to begin processing until it completely finishes and is rendered to the screen or to a final image. Many mobile GPUs use a technique called "deferred rendering," where rendering instructions are batched up and executed only as needed. Therefore, it's important to measure the entire rendering operation, rather than operations in the middle, because they may run in a different order than you expect.

帧渲染时间是帧从开始处理到完全结束并且渲染到屏幕或者一张图片所花费的时间。许多移动 GPU 用一种叫做 “延迟渲染” 的技术，它会把渲染指令批量处理，并且只会在需要的时候才会处理。所以，计算整个渲染过程，而不是中间的操作过程，因为他们或许会以一种与你想象不同的顺序运行。

Optimizations can also vary wildly from device to device, desktop and mobile. You may need to profile on multiple classes of devices. For example, the GPUs in mobile iOS devices have grown increasingly more powerful. The CPU on an iPhone 5S is approximately ten times faster than the CPU on the iPhone 4, however its GPU is hundreds of times faster.

不同的设备上，桌面设备和移动设备上，优化也会很不相同。你或许需要在不同类型的设备上进行分析 。例如，GPU 的性能在移动 IOS 设备上有了很大的提升。iPhone 5S 的 CPU 比 iPhone 4 快几十倍，GPU则会快几百倍。

If you are testing your applications on devices with an A7 chip or higher, you are going to get vastly different results than you would with an iPhone 5 or lower. [Brad Larson profiled how long a Gaussian Blur took on various iOS devices and has clearly demonstrated a dramatic leap forward in processing times on newer devices:](http://www.sunsetlakesoftware.com/2013/10/21/optimizing-gaussian-blurs-mobile-gpu)

如果你在有着 A7 芯片或者更高的设备上测试你的应用，相比于iPhone 5 或者更低版本的设备，你会获得非常不同的结果。[Brad Larson 概述了高斯模糊在不同的设备上花费的时间，并且非常清晰的展示了在更新版的设备上有着令人惊奇的提升:](http://www.sunsetlakesoftware.com/2013/10/21/optimizing-gaussian-blurs-mobile-gpu)

iPhone Version | Frame Rendering Time in Milliseconds
-------------- | ------------------------------------
iPhone 4       | 873
iPhone 4S      | 145
iPhone 5       | 55
iPhone 5S      | 3

iPhone 版本     | 帧渲染时间（毫秒）
-------------- | ------------------------------------
iPhone 4       | 873
iPhone 4S      | 145
iPhone 5       | 55
iPhone 5S      | 3

There is a tool that you can download, [Imagination Technologies PowerVR SDK](http://community.imgtec.com/developers/powervr/), that will profile your shader and let you know the best- and worst-case performance for your shader rendering. It's important to get the number of cycles necessary to render your shader as low as possible to keep your frame rate high. If you want to hit a target of 60 frames per second, you only have 16.67 milliseconds to get all of your processing done.

你可以下载一个工具，[Imagination Technologies PowerVR SDK](http://community.imgtec.com/developers/powervr/)，它会帮助你分析你的着色器，并且让你知道着色器渲染性能的最好的和最坏的情况 。为了保持高帧速率，使渲染着色器所需的周期数尽可能的低是很重要的。如果你想达成 60 帧每秒，你只有 16.67 毫秒来完成所有的处理。

Here are some easy ways to help you hit your target:

这里有一些简单的方式来帮助你达成目标：

- **Eliminate conditional logic:** Sometimes it's necessary to include conditional logic, but try to keep it to a minimum. Using workarounds like the `step()` function can help you avoid expensive conditional logic in your shaders.

- **消除条件逻辑:** 有时候条件逻辑是必须得，但尽量最小化它。在着色器中使用像 `step()`  函数这样的变通方法可以帮助你避免一些昂贵的条件逻辑。

- **Reduce dependent texture reads:** Dependent texture reads occur when a texture is sampled in a fragment shader from a texture coordinate that wasn't passed in directly as a varying, but was instead calculated in the fragment shader. These dependent texture reads can't take advantage of optimizations in caching that normal texture reads do, leading to much slower reads. For example, if you want to sample from nearby pixels, rather than calculate the offset to the neighboring pixel in your fragment shader, it's best to do this calculation in the vertex shader and have the result be passed along as a varying. A demonstration of this is present in [Brad Larson's article](/issue-21/gpu-accelerated-machine-vision.html), in the case of Sobel edge detection.

- **减少依赖纹理的读取:** 在片段着色器中取样时，如果文理坐标不是直接以 varying 的方式传递进来，而是在片段着色器中计算时，就会发生依赖文理的读取。依赖文理的读取不能使用普通的文理读取的缓存优化，会导致读取更慢。例如，如果你想从附近的像素取样，而不是计算和片段着色器中相邻像素的偏差，最好在顶点着色器中进行计算，然后把结果以 varying 的方式传入片段着色器。[Brad Larson的文章](http://img.objccn.io/issue-21/GPU加速的机器视觉.html)有一个实例，是关于 sobel 边缘检测的。

- **Make your calculations as simple as possible:** If you can avoid an expensive operation and get an approximate value that is good enough, you should do so. Expensive calculations include calling trigonometric functions (like `sin()`, `cos()`, and `tan()`).

- **让你的计算尽量简单:** 如果你在避免一个昂贵的操作情况下可以获得一个近似的足够精度的值，你应该这样做。昂贵的计算包括调用三角函数（像`sin()`, `cos()`, 和 `tan()`）。

- **Shift work over to the vertex shader, if it makes sense:** Our previous talk about dependent texture reads is a situation where it would make sense to move texture coordinate calculations to the vertex shader. If a calculation would have the same result across your image, or would linearly vary across it, look at moving that calculation into the vertex shader. Vertex shaders run once per vertex, whereas fragment shaders execute once per pixel, so a calculation performed in the former will run fewer times.

- **如果可以的话，把工作转移到顶点着色器:**  之前讲的关于依赖文理的读取就是把文理坐标计算转移到顶点着色器很有意义的一种情况。如果一个计算在图片上会有相同的结果，或者线性的变化，看看能不能把计算一道顶点着色器。顶点着色器对每个顶点运行一次，片段着色器在每个像素上运行一次，所以在前者上的计算会比后者少很多。

- **Use appropriate precision on mobile devices:** On certain mobile devices, it can be much faster to work with lower precision values in vectors. Addition of two `lowp vec4`s can often be done in a single clock cycle on these device, where addition of two highp vec4s can take four clock cycles. This is less important on desktop GPUs and more recent mobile GPUs, though, as they don't have the same optimizations for low precision values.

- **在移动设备上使用合适的精度** 在特定的移动设备上，在向量上使用低精度的值会变得更快。在这些设备上，两个 lowp vec4 可以再一个时钟循环内完成，而两个 highp vec4 则需要四个时钟循环。但是在桌面 GPU 和最近的移动 GPU 上，这变得不再那么重要，因为他们对低精度值的优化不同。

# Conclusions and Resources #

## 结论和资源 ##

Shaders seem kind of scary at first, but they are nothing more than modified C programs. Everything involved in creating a shader is stuff that most of us have dealt with at one point or another, just in a different context.

着色器刚开始看起来很吓人，但他们也仅仅是改装的 C 程序而已。创建着色器相关的所有事情，我们大多数都在某些情况下处理过，只不过在不同的环境罢了。

One thing I would highly recommend for anyone trying to get into shaders is to refamiliarize yourself with trigonometry and linear algebra. The biggest stumbling block I encountered when working with this was that I didn't remember a lot of the math I learned in high school, because I hadn't used it in a really long time.

对于想深入了解着色器的人，我非常推荐的一件事就是回顾下三角学和线性代数。做相关工作的时候，我遇到的最大的阻力就是我忘了很多我大学学过的数学，因为我已经很长时间没有实际使用过它们了。

There are some books I would recommend if your math is a little rusty:

- [3D Math Primer for Graphics and Game Development](http://www.amazon.com/Math-Primer-Graphics-Game-Development/dp/1568817231/ref=sr_1_1?ie=UTF8&qid=1422837187&sr=8-1&keywords=3d+math+primer+for+graphics+and+game+development)
- [The Nature of Code](http://natureofcode.com)
- [The Computational Beauty of Nature](http://www.amazon.com/Computational-Beauty-Nature-Explorations-Adaptation/dp/0262561271/ref=sr_1_1?s=books&ie=UTF8&qid=1422837256&sr=1-1&keywords=computational+beauty+of+nature)

如果你的数学有些生疏了，我有一些书可以推荐给你：

- [3D Math Primer for Graphics and Game Development](http://www.amazon.com/Math-Primer-Graphics-Game-Development/dp/1568817231/ref=sr_1_1?ie=UTF8&qid=1422837187&sr=8-1&keywords=3d+math+primer+for+graphics+and+game+development)
- [The Nature of Code](http://natureofcode.com)
- [The Computational Beauty of Nature](http://www.amazon.com/Computational-Beauty-Nature-Explorations-Adaptation/dp/0262561271/ref=sr_1_1?s=books&ie=UTF8&qid=1422837256&sr=1-1&keywords=computational+beauty+of+nature)

There are also countless books out there about GLSL and how some very specific shaders were created by prominent members of our industry:

- [Graphics Shaders: Theory and Practice](http://www.amazon.com/Graphics-Shaders-Theory-Practice-Second/dp/1568814348/ref=sr_1_1?s=books&ie=UTF8&qid=1422837351&sr=1-1&keywords=graphics+shaders+theory+and+practice)
- [The OpenGL Shading Language](http://www.amazon.com/OpenGL-Shading-Language-Randi-Rost/dp/0321637631/ref=sr_1_1?s=books&ie=UTF8&qid=1422896457&sr=1-1&keywords=opengl+shading+language)
- [OpenGL 4 Shading Language Cookbook](http://www.amazon.com/OpenGL-Shading-Language-Cookbook-Second/dp/1782167021/ref=sr_1_2?s=books&ie=UTF8&qid=1422896457&sr=1-2&keywords=opengl+shading+language)
- [GPU Gems](http://http.developer.nvidia.com/GPUGems/gpugems_part01.html)
- [GPU Pro: Advanced Rendering Techniques](http://www.amazon.com/GPU-Pro-Advanced-Rendering-Techniques/dp/1568814720/ref=sr_1_4?s=books&ie=UTF8&qid=1422837427&sr=1-4&keywords=gpu+pro)

也有数不清的关于GLSL书和特殊着色器被我们行业突出的人士创造出来：

- [Graphics Shaders: Theory and Practice](http://www.amazon.com/Graphics-Shaders-Theory-Practice-Second/dp/1568814348/ref=sr_1_1?s=books&ie=UTF8&qid=1422837351&sr=1-1&keywords=graphics+shaders+theory+and+practice)
- [The OpenGL Shading Language](http://www.amazon.com/OpenGL-Shading-Language-Randi-Rost/dp/0321637631/ref=sr_1_1?s=books&ie=UTF8&qid=1422896457&sr=1-1&keywords=opengl+shading+language)
- [OpenGL 4 Shading Language Cookbook](http://www.amazon.com/OpenGL-Shading-Language-Cookbook-Second/dp/1782167021/ref=sr_1_2?s=books&ie=UTF8&qid=1422896457&sr=1-2&keywords=opengl+shading+language)
- [GPU Gems](http://http.developer.nvidia.com/GPUGems/gpugems_part01.html)
- [GPU Pro: Advanced Rendering Techniques](http://www.amazon.com/GPU-Pro-Advanced-Rendering-Techniques/dp/1568814720/ref=sr_1_4?s=books&ie=UTF8&qid=1422837427&sr=1-4&keywords=gpu+pro)

Also, again, [GPUImage](https://github.com/BradLarson/GPUImage) is an open-source resource to get a look at some really cool shaders. One good way to learn about shaders is to take a shader you find interesting and go through it line by line, looking up any part of it that you don't understand. GPUImage also has a [shader designer](https://github.com/BradLarson/GPUImage/tree/master/examples/Mac/ShaderDesigner) application on the Mac side that lets you test out shaders without having to set up the OpenGL code.

还有，再一次强调，[GPUImage](https://github.com/BradLarson/GPUImage)是一个开源的资源，让你看到一些非常酷的着色器。一个非常好的学习着色器的方式，就是拿一个你觉得很有意思的着色器，然后一行一行看下去，搜寻任何你不理解的部分。GPUImage 还有一个[着色器设计](https://github.com/BradLarson/GPUImage/tree/master/examples/Mac/ShaderDesigner)的Mac端应用，可以让你测试着色器而不用准备 OpenGL 的代码。

Learning how to effectively implement shaders in your code can give you a huge performance boost. Not only that, but shaders also allow you to do things that were not possible before.

学习有效的在代码中实现着色器可以给你带来很大的性能提升。不仅如此，着色器也使你可以做以前不可能做出来的东西。

Learning shaders takes some tenacity and some curiosity, but they aren't impossible. If a 33-year-old recovering journalism major could confront her math fear to tackle shaders, so can you.

学习着色器需要一些坚持和好奇心，但是并不是不可能的。如果一个 33 岁的恢复新闻专业的人能够克服她对数学的恐惧来处理着色器，那么你也可以。
