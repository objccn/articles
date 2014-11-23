> The Metal framework supports GPU-accelerated advanced 3D graphics rendering and data-parallel computation workloads. Metal provides a modern and streamlined API for fine-grain, low-level control of the organization, processing, and submission of graphics and computation commands and the management of the associated data and resources for these commands. A primary goal of Metal is to minimize the CPU overhead necessary for executing these GPU workloads.

– [Metal Programming Guide](https://developer.apple.com/library/ios/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40014221-CH1-SW1)


> Mental 框架支持 GPU 加速高级 3D 图像渲染，以及数据并行计算工作。Mental 提供了先进合理的 API，为图形的组织、处理和呈现，为计算命令以及为这些命令相关的数据和资源的管理，提供了细粒度和底层的控制。Mental 的主要目的是最小化 GPU 工作时 CPU 的必要消耗。

– [Metal Programming Guide](https://developer.apple.com/library/ios/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40014221-CH1-SW1)

Metal is a highly optimized framework for programming the GPUs found in iPhones and iPads. The name derives from the fact that Metal is the lowest-level graphics framework on the iOS platform (i.e. it is "closest to the metal").

Mental 是针对 iPhone 和 iPad 中 GPU 编程的高度优化的框架。其名字来源于 Metal 是 iOS 平台中最底层的图形框架 (意指 "最接近硬件")。

The framework is designed to achieve two different goals: 3D graphics rendering and parallel computations. These two things have a lot in common. Both tasks run special code on a huge amount of data in parallel and can be executed on a [GPU](https://en.wikipedia.org/wiki/Graphics_processing_unit). 

该框架被设计用来实现两个目标: 3D 图形渲染和并行计算。这两者有很多共同点。它们都在数量庞大的数据上运行特殊的代码，并可以在 [GPU](https://en.wikipedia.org/wiki/Graphics_processing_unit).  上执行。


## Who Should Use Metal?

## 什么人应该使用 Mental?

Before talking about the API and shading language itself, we should discuss which developers will benefit from using Metal. As previously mentioned, Metal offers two functionalities: graphics rendering and parallel computing.

在谈论 API 和语言本身之前，我们应该讨论一下什么样的开发者能从 Metal 中受益。正如上面提过的，Metal 提供两个功能: 图形渲染和并行计算。

For those who are looking for a game engine, Metal is not the first choice. In this case, Apple's [Scene Kit](https://developer.apple.com/library/ios/documentation/SceneKit/Reference/SceneKit_Framework/) (3D) and [Sprite Kit](https://developer.apple.com/library/ios/documentation/GraphicsAnimation/Conceptual/SpriteKit_PG/Introduction/Introduction.html) (2D) are better options. These APIs offer a high-level game engine, including physics simulation. Another alternative would be a full-featured 3D engine like Epic's [Unreal Engine](https://www.unrealengine.com/), or [Unity](http://unity3d.com), both of which are not limited to Apple's platform. In each of those cases, you profit (or will profit in the future) from the power of Metal without using the API directly.

对于寻找游戏引擎的开发者来说，Metal 不是最佳选择。苹果官方的的 [Scene Kit](https://developer.apple.com/library/ios/documentation/SceneKit/Reference/SceneKit_Framework/) (3D) 和 [Sprite Kit](https://developer.apple.com/library/ios/documentation/GraphicsAnimation/Conceptual/SpriteKit_PG/Introduction/Introduction.html) (2D) 是更好的选择。这些 API 提供了包括物理模拟在内的更高级别的游戏引擎。另外还有功能更全面的 3D 引擎，例如 Epic 的 [Unreal Engine](https://www.unrealengine.com/) 或 [Unity](http://unity3d.com)，二者都是跨平台的。使用这些引擎，你无需直接使用 Metal 的 API，就可以从 Metal 中获益。

When writing a rendering engine based on a low-level graphics API, the alternatives to Metal are OpenGL and OpenGL ES. Not only is OpenGL available for nearly every platform, including OS X, Windows, Linux, and Android, but there are also a huge amount of tutorials, books, and best practice guides written about OpenGL. Right now, Metal resources are very limited and you are constrained to iPhones and iPads with a 64-bit processor. On the other hand, due to limitations in OpenGL, its performance is not always optimal compared to Metal, which was written specifically to overcome such issues.

编写基于底层图形 API 的渲染引擎的其他 选择还有 OpenGL 和 OpenGL ES。OpenGL 不仅支持包括 OSX， Windows，Linux 和 Android 在内的几乎所有平台，还有大量的教程，书籍和最佳实践指南等资料。目前，Metal 的资源非常有限并且仅限于搭载了 64 位处理器的 iPhone 和 iPad。但另外一方面，因为 OpenGL 的限制，其性能与 Metal 相比并不占优势，毕竟后者是专门用来解决这些问题的。

When looking for a high-performance parallel computing library on iOS, the question of which one to use is answered very simply. Metal is the only option. OpenCL is a private framework on iOS, and Core Image (which uses OpenCL) is neither powerful nor flexible enough for this task.

如果想要一个 iOS 上高性能的并行计算库，答案非常简单。Metal 是唯一的选择。OpenCL 在 iOS 上是非开源的，Core Image (使用了 OpenCL) 既不够强大又不够灵活。

## Benefits of Using Metal

## 使用 Metal 的好处

The biggest advantage of Metal is a dramatically reduced overhead compared to OpenGL ES. Whenever you create a buffer or a texture in OpenGL, it is copied to ensure that the data cannot be accessed accidentally while the GPU is using it. Copying large resources such as textures and buffers is an expensive operation undertaken for the sake of safety. Metal, on the other hand, does not copy resources. The developer is responsible for synchronizing the access between the CPU and GPU. Luckily, Apple provides another great API, which makes resource synchronization much easier: [Grand Central Dispatch](https://developer.apple.com/library/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/index.html). Still, using Metal requires some awareness of this topic, but a modern engine that is loading and unloading resources while rendering profits a lot when this extra copy is avoided.

Metal 的最大好处就是与 OpenGL ES 相比显著降低了消耗。在 OpenGL 中无论创建缓冲区还是纹理，OpenGL 都会复制一份以防止 GPU 在使用它们时被意外访问。出于安全的原因复制类似纹理和缓冲区这样的大的资源是非常消耗资源的操作。而 Metal 并不复制资源。开发者负责在 CPU 和 GPU 之间同步访问。幸运的是，苹果提供了另一个很棒的 API 使资源同步访问更加容易: [Grand Central Dispatch](https://developer.apple.com/library/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/index.html)。虽然使用 Metal 时仍然有些这方面的问题需要注意，但是一个在渲染时加载和卸载资源的先进的引擎，在避免额外的复制后能够获得更多的好处。

Another advantage of Metal is its use of pre-evaluated GPU state to avoid redundant validation and compilation. Traditionally in OpenGL, you set GPU states one after the other, and the new set of states needs to be validated when making a draw call. In the worst case, OpenGL needs to recompile shaders again to reflect the new states. Of course, this evaluation is necessary, but Metal chooses to take a different approach here. During the initialization of the rendering engine, a set of states is baked into a pre-evaluted rendering pass. This rendering pass object can be used with different resources, but the other states will be constant. A render pass in Metal can be used without further validation, which reduces the API overhead to a minimum, and allows a greatly increased number of draw calls per frame.

Metal 的另外一个好处是其预估 GPU 状态来避免多余的验证和编译。通常在 OpenGL 中，你需要依次设置 GPU 状态，在调用指令行为前需要验证新的状态。最坏的情况是 OpenGL 需要再次重新编译着色器以反映新的状态。当然，这种评估是必要的，但 Metal 选择了另一种方法。在渲染引擎初始化过程中，一组状态被传入预估渲染路径中。该渲染路径对象可以跟多个不同资源使用，但其它的状态是恒定的。Metal 中一个渲染路径无需更进一步的验证，使 API 的消耗降到最低，从而大大增加每帧的绘制指令的数量。

## The Metal API

## Metal API

Although many APIs on the platform expose concrete classes, Metal offers many of its types as protocols. The reason for this is that the concrete types of Metal objects are dependent on the device on which Metal is running. This also encourages programming to an interface rather than an implementation. This also means, however, that you won't be able to subclass Metal classes or add categories without making extensive and dangerous use of the Objective-C runtime.

虽然许多平台上 API 暴露为具体的类，但 Metal 提供了很多它的类型作为协议。因为 Metal 对象的具体类型取决于 Metal 运行在哪个设备上。这更鼓励了面向接口而不是面向实现编程。然而，这同时也意味着，如果不使用 Objective-C 运行时的广泛而危险的操作，就不能子类化 Metal 的类或者为其增加扩展，

Metal necessarily compromises some safety for speed. In regard to errors, other Apple frameworks are getting more secure and robust, but Metal is totally different. In some instances, you receive a bare pointer to an internal buffer, the access to which you must carefully synchronize. When things go wrong in OpenGL, the result is usually a black screen; in Metal, the results can be totally random effects, including a flickering screen and occasionally a crash. These pitfalls occur because the Metal framework is a very light abstraction of a special-purpose processor next to your CPU.

Metal 为了速度而在安全性上做了必要的妥协。对于错误，苹果的其它框架显得更加安全和健壮，而 Metal 则完全相反。在某些时候，你会收到指向内部缓冲区的裸指针，你必须小心的同步访问它。OpenGL 中发生错误时，结果通常是黑屏；然而在 Metal 中，结果可能是完全随机的效果，例如闪屏和偶尔的崩溃。之所以有这些陷阱，是因为 Metal 框架是对 GPU 的非常轻量级抽象。

An interesting side note is that Apple has not yet implemented a software render for Metal that can be used in the iOS Simulator. When linking the Metal framework, the application must be executed on a physical device.

一个有趣的方面是苹果并没有为 Metal 实现可以在 iOS 模拟器上使用的软件渲染。使用 Metal 框架的时候应用必须运行在真实设备上。

## A Basic Metal Program

## 基础 Metal 程序

In this section, we introduce the necessary ingredients for writing your first Metal program. This simple program draws a square rotating about its center. You can download the [sample code for this article from GitHub](https://github.com/warrenm/metal-demo-objcio).

在这部分中，我们介绍了写出第一个 Metal 程序所必要的部分。这个简单的程序绘制了一个正方形的旋转。你可以在 [sample code for this article from GitHub](https://github.com/warrenm/metal-demo-objcio) 下载。

Although we can't cover each topic in detail, we will try to at least mention all of the moving parts. For more insight, you can read the sample code and consult other online resources.

虽然不能涵盖每一个细节，但我们尽量涉及至少所有的移动部分。你可以阅读源代码和参阅线上资源来扩展知识。

### Creating a Device and Interfacing with UIKit

### 使用 UIKit 创建设备和界面

In Metal, a _device_ is an abstraction of the GPU. It is used to create many other kinds of objects, such as buffers, textures, and function libraries. To get the default device, use the `MTLCreateSystemDefaultDevice` function:

    id<MTLDevice> device = MTLCreateSystemDefaultDevice();

Notice that the device is not of a particular concrete class, but instead conforms to the `MTLDevice` protocol as mentioned above.

The following snippet shows how to create a Metal layer and add it as a sublayer of a UIView's backing layer:

    CAMetalLayer *metalLayer = [CAMetalLayer layer];
    metalLayer.device = device;
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    metalLayer.frame = view.bounds;
    [view.layer addSublayer:self.metalLayer];

`CAMetalLayer` is a subclass of [`CALayer`](https://developer.apple.com/library/mac/Documentation/GraphicsImaging/Reference/CALayer_class/index.html) that knows how to display the contents of a Metal framebuffer. We must tell the layer which Metal device to use (the one we just created), and inform it of its expected pixel format. We choose an 8-bit-per-channel BGRA format, wherein each pixel has blue, green, red, and alpha (transparency) components, with values ranging from 0-255, inclusive.

在 Metal 中，_设备_是 GPU 的抽象。被用来创建很多其它类型的对象，例如缓冲区，纹理和函数库。使用 `MTLCreateSystemDefaultDevice` 函数来获取默认设备:

```objc
id<MTLDevice> device = MTLCreateSystemDefaultDevice();
```

注意 device 并不是一个详细具体的类，而是遵循 `MTLDevice` 协议的类，正如前面提到的。

下面的代码展示了如何创建一个 Metal layer 并将它作为 sublayer 添加到一个 UIView 的 layer:

```objc
CAMetalLayer *metalLayer = [CAMetalLayer layer];
metalLayer.device = device;
metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
metalLayer.frame = view.bounds;
[view.layer addSublayer:self.metalLayer];
```

`CAMetalLayer` 是 [`CALayer`](https://developer.apple.com/library/mac/Documentation/GraphicsImaging/Reference/CALayer_class/index.html) 的子类，知道如何展示 Metal 帧缓冲区的内容。我们必须告诉 layer 该使用哪个 Metal 设备 (我们刚创建的那个)，并通知它所预期的像素格式。我们选择 8-bit-per-channel BGRA 格式，即每个像素由蓝，绿，红和透明组成，值从 0-255。

### Libraries and Functions

### 库和函数

Much of the functionality of your Metal program will be written in the form of vertex and fragment functions, colloquially known as shaders. Metal shaders are written in the Metal shading language, which we will discuss in greater detail below. One of the advantages of Metal is that shader functions are compiled at the time your app builds into an intermediate language, saving valuable time when your app starts up.

你的 Metal 程序的很多功能会被写成顶点和碎片函数，俗称着色器。Metal 着色器用 Metal 着色器语言编写，我们将在下面详细讨论。Metal 的优点之一就是着色器函数在你的应用集成到中间语言时编译，节省了很多应用启动时所需的时间。

A Metal library is simply a collection of functions. All of the shader functions you write in your project are compiled into the default library, which can be retrieved from the device:

    id<MTLLibrary> library = [device newDefaultLibrary]

We will use the library when building the render pipeline state below.

一个 Metal 库是一组函数的集合。所有写在工程内部的着色器函数被编译到默认库中，可以通过设备获得:

```objc
id<MTLLibrary> library = [device newDefaultLibrary]
```

接下来构建渲染管道状态的时候将使用这个库。

### The Command Queue

### 命令队列

Commands are submitted to a Metal device through its associated command queue. The command queue receives commands in a thread-safe fashion and serializes their execution on the device. Creating a command queue is straightforward:

    id<MTLCommandQueue> commandQueue = [device newCommandQueue];
    
命令通过 Metal 设备相关的命令队列提交给 Metal 设备。命令队列以线程安全的方式接收命令并顺序执行。创建一个命令队列:

```objc
id<MTLCommandQueue> commandQueue = [device newCommandQueue];
```

### Building the Pipeline

### 构建管道

When we speak of the pipeline in Metal programming, we mean the different transformations the vertex data undergoes as it is rendered. Vertex shaders and fragment shaders are two programmable junctures in the pipeline, but there are other things that must happen (clipping, scan-line rasterization, and the viewport transform) that are not under our direct control. This latter class of pipeline features constitute the fixed-function pipeline.

当我们在 Metal 编程中提到管道，指的是顶点数据在渲染时经历的变化。顶点着色器和碎片着色器是管道中两个可编程的节点，但还有其它一定会发生的事件 (剪切，栅格化和视图变化) 不在我们的控制之下。管道特性中的后者的类组成了固定功能管道。

To create a pipeline in Metal, we need to specify which vertex and fragment function we want executed for each vertex and each pixel, respectively. We also need to tell the pipeline the pixel format of our framebuffer. In this case, it must match the format of the Metal layer, since we want to draw to the screen.

在 Metal 中创建一个管道，我们需要指定对于每个顶点和每个像素分别想要执行哪个顶点和碎片函数。我们还需要告诉管道帧缓冲区的像素格式。在本例中，该格式必须与 Metal layer 的格式匹配，因为我们想在屏幕上绘制。

To get the functions, we ask for them by name from the library:

    id<MTLFunction> vertexProgram = [library newFunctionWithName:@"vertex_function"];
    id<MTLFunction> fragmentProgram = [library newFunctionWithName:@"fragment_function"];

We then create a pipeline descriptor configured with the functions and the pixel format:

    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    [pipelineStateDescriptor setVertexFunction:vertexProgram];
    [pipelineStateDescriptor setFragmentFunction:fragmentProgram];
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

Finally, we create the pipeline state itself from the descriptor. This compiles the shader functions from their intermediate representation into optimized code for the hardware on which the program is running:

    id<MTLRenderPipelineState> pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:nil];
    
从库中通过名字来获取函数:

```objc
id<MTLFunction> vertexProgram = [library newFunctionWithName:@"vertex_function"];
id<MTLFunction> fragmentProgram = [library newFunctionWithName:@"fragment_function"];
```

接下来创建一个设置了函数和像素格式的管道描述器:

```objc
MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
[pipelineStateDescriptor setVertexFunction:vertexProgram];
[pipelineStateDescriptor setFragmentFunction:fragmentProgram];
pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;        
```

最后，我们从描述器中创建管道状态。这会根据程序运行的硬件环境，从中间代码中编译着色器函数为优化的代码。

```objc
id<MTLRenderPipelineState> pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:nil];
```

### Loading Data into Buffers

### 读取数据到缓冲区

Now that we have a pipeline built, we need data to feed through it. In the sample project, we draw a simple bit of geometry: a spinning square. The square is comprised of two right triangles that share an edge:

    static float quadVertexData[] =
    {
         0.5, -0.5, 0.0, 1.0,     1.0, 0.0, 0.0, 1.0,
        -0.5, -0.5, 0.0, 1.0,     0.0, 1.0, 0.0, 1.0,
        -0.5,  0.5, 0.0, 1.0,     0.0, 0.0, 1.0, 1.0,
        
         0.5,  0.5, 0.0, 1.0,     1.0, 1.0, 0.0, 1.0,
         0.5, -0.5, 0.0, 1.0,     1.0, 0.0, 0.0, 1.0,
        -0.5,  0.5, 0.0, 1.0,     0.0, 0.0, 1.0, 1.0,
    };

The first four numbers of each row represent the x, y, z, and w components of each vertex. The second four numbers represent the red, green, blue, and alpha color components of the vertex.

现在已经有了一个构建好的管道，我们需要用数据填充它。在示例工程中，我们绘制了一个简单的几何图形: 一个旋转的正方形。正方形由两个共享一条边的直角三角形组成:

```objc
static float quadVertexData[] =
{
     0.5, -0.5, 0.0, 1.0,     1.0, 0.0, 0.0, 1.0,
    -0.5, -0.5, 0.0, 1.0,     0.0, 1.0, 0.0, 1.0,
    -0.5,  0.5, 0.0, 1.0,     0.0, 0.0, 1.0, 1.0,
    
     0.5,  0.5, 0.0, 1.0,     1.0, 1.0, 0.0, 1.0,
     0.5, -0.5, 0.0, 1.0,     1.0, 0.0, 0.0, 1.0,
    -0.5,  0.5, 0.0, 1.0,     0.0, 0.0, 1.0, 1.0,
};  
```

每一行的前四个数字代表了每一个顶点的 x，y，z 和 w 元素。后四个数字代表每个顶点的红色，绿色，蓝色和透明值元素。

You may be surprised that there are four numbers required to express a position in 3D space. The fourth component of the vertex position, w, is a mathematical convenience that allows us to represent 3D transformations (rotation, translation, and scaling) in a unified fashion. This detail is not relevant to the sample code for this article.

你可能会奇怪为什么需要四个数字来描述 3D 空间中的一个位置。第四个顶点位置元素，w，是一个数学上的便利，使我们能以一种统一的方式描述 3D 转换(旋转，平移，缩放)。这个细节在本文的示例代码并没有体现。

To draw the vertex data with Metal, we need to place it into a buffer. Buffers are simply unstructured blobs of memory that are shared by the CPU and GPU:

    vertexBuffer = [device newBufferWithBytes:quadVertexData
                                       length:sizeof(quadVertexData)
                                      options:MTLResourceOptionCPUCacheModeDefault];

We will use another buffer for storing the rotation matrix we use to spin the square around. Rather than providing the data up front, we'll just make room for it by creating a buffer of a prescribed length:

    uniformBuffer = [device newBufferWithLength:sizeof(Uniforms) 
                                        options:MTLResourceOptionCPUCacheModeDefault];
                                        
为了使用 Metal 绘制顶点数据，我们需要将它放入缓冲区。缓冲区是被 CPU 和 GPU 共享的简单的无结构的内存块:

```objc
vertexBuffer = [device newBufferWithBytes:quadVertexData
                                       length:sizeof(quadVertexData)
                                      options:MTLResourceOptionCPUCacheModeDefault];
```

我们将使用另一个缓冲区来存储用来旋转正方形的旋转矩阵。与预先提供数据不同，这里只是通过创建规定长度的缓冲区来创建一个空间。

```objc
uniformBuffer = [device newBufferWithLength:sizeof(Uniforms) 
                                        options:MTLResourceOptionCPUCacheModeDefault];
```

### Animation

### 动画

In order to rotate the square on the screen, we need to transform the vertices as part of the vertex shader. This requires updating the uniform buffer each frame. To do this, we use trigonometry to generate a rotation matrix from the current rotation angle and copy it into the uniform buffer.

为了在屏幕上旋转正方形，我们需要把转换顶点作为顶点着色器的一部分。这需要更新每一帧的统一缓冲区。我们运用三角学知识，从当前旋转角度生成一个旋转矩阵，将它复制到统一缓冲区。

The `Uniforms` struct has a single member, which is a 4x4 matrix that holds the rotation matrix. The type of the matrix, `matrix_float4x4`, comes from Apple's SIMD library, a collection of types that take advantage of [data-parallel operations](http://en.wikipedia.org/wiki/SIMD) where they are available:

    typedef struct
    {
        matrix_float4x4 rotation_matrix;
    } Uniforms;

To copy the rotation matrix into the uniform buffer, we get a pointer to its contents and `memcpy` the matrix into it:

    Uniforms uniforms;
    uniforms.rotation_matrix = rotation_matrix_2d(rotationAngle);
    void *bufferPointer = [uniformBuffer contents];
    memcpy(bufferPointer, &uniforms, sizeof(Uniforms));
    
`Uniforms` 结构体只有一个成员，改成员保存旋转矩阵的 4x4 的矩阵。矩阵类型 `matrix_float4x4` 来自于苹果的 SIMD 库，该库是一个类型的集合，从 [data-parallel operations](http://en.wikipedia.org/wiki/SIMD) 中获益:

```objc
typedef struct
{
    matrix_float4x4 rotation_matrix;
} Uniforms;
```

为了将旋转矩阵复制到统一缓冲区中，我们取得它的内容的指针并将矩阵 `memcpy` 进去:

```objc
Uniforms uniforms;
uniforms.rotation_matrix = rotation_matrix_2d(rotationAngle);
void *bufferPointer = [uniformBuffer contents];
memcpy(bufferPointer, &uniforms, sizeof(Uniforms));
```

### Getting Ready to Draw

### 准备绘制

In order to draw into the Metal layer, we first need to get a 'drawable' from the layer. The drawable object manages a set of textures that are appropriate for rendering into:

    id<CAMetalDrawable> drawable = [metalLayer nextDrawable];
    
为了在 Metal layer 上绘制，首先我们需要从 layer 中获得一个 'drawable'。可绘制的对象管理着一组适合渲染的纹理:

```objc
id<CAMetalDrawable> drawable = [metalLayer nextDrawable];
```

Next, we create a render pass descriptor, which describes the various actions Metal should take before and after rendering is done. Below, we describe a render pass that will first clear the framebuffer to a solid white color, then execute its draw calls, and finally store the results into the framebuffer for display:

    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1);
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

接下来我们创建一个渲染路径描述器，它描述了在渲染之前和完成之后 Metal 应该执行的不同动作。下面我们展示了一个渲染路径首先应该将帧缓冲区清除为纯白色，然后执行绘制指令，最后将结果存储到帧缓冲区来展示:

```objc
MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1);
renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
```

### Issuing Draw Calls

### 发布绘制指定

To place commands into a device's command queue, they must be encoded into a command buffer. A command buffer is a set of one or more commands that will be executed and encoded in a compact way that the GPU understands:

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
放入设备的命令队列的命令必须被编码放入命令缓冲区。命令缓冲区是一个或多个命令的集合，可以以一种 GPU 了解的紧凑的方式执行和编码。

```objc
id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
```

In order to actually encode render commands, we need yet another object that knows how to convert from our draw calls into the language of the GPU. This object is called a command encoder. We create it by asking the command buffer for an encoder and passing the render pass descriptor we created above:

    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
为了真正编码渲染命令，我们还需要另一个知道如何将我们的绘制指令转换为 GPU 懂得的语言的对象。这个对象叫做命令编码器。我们将上面创建的渲染路径描述器命令缓冲区创建它:

```objc
id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
```

Immediately before the draw call, we configure the render command encoder with our pre-compiled pipeline state and set up the buffers, which will become the arguments to our vertex shader:

    [renderEncoder setRenderPipelineState:pipelineState];
    [renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:uniformBuffer offset:0 atIndex:1];
    
在绘制指令之前，我们使用预编译的管道状态设置渲染命令编码器并建立缓冲区，该缓冲区作为顶点着色器的参数:

```objc
[renderEncoder setRenderPipelineState:pipelineState];
[renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
[renderEncoder setVertexBuffer:uniformBuffer offset:0 atIndex:1];
```

To actually draw the geometry, we tell Metal the type of shape we want to draw (triangles), and how many vertices it should consume from the buffer (six, in this case):

    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    
为了真正的绘制几何图形，我们告诉 Metal 要绘制的形状 (矩形) 和缓冲区中顶点的数量 (6 个):

```objc
[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
```

Finally, to tell the encoder we are done issuing draw calls, we call `endEncoding`:

    [renderEncoder endEncoding];
    
最后，执行 `endEncoding` 通知编码器发布绘制指令完成。
    
### Presenting the Framebuffer

### 展示帧缓冲区

Now that our draw calls are encoded and ready for execution, we need to tell the command buffer that it should present the results to the screen. To do this, we call `presentDrawable` with the current drawable object retrieved from the Metal layer:

    [commandBuffer presentDrawable:drawable];

To tell the buffer that it is ready for scheduling and execution, we call `commit`: 

    [commandBuffer commit];

And that's it!

现在我们的绘制指令已经被编码并准备就绪，我们需要通知命令缓冲区应该将结果在屏幕上显示出来。调用  `presentDrawable`，使用当前从 Metal layer 中获得的 drawable 对象作为参数:

```objc
[commandBuffer presentDrawable:drawable];
```

执行 `commit` 告诉缓冲区已经准备好安排并执行:

```objc
[commandBuffer commit];
```

## Metal Shading Language

## Metal 着色语言

Although Metal was announced in the same [WWDC keynote](https://www.apple.com/apple-events/june-2014/) as the [Swift](https://developer.apple.com/swift/) programming language, the shading language is based on [C++11](https://en.wikipedia.org/wiki/C%2B%2B11), with some limited features and some added keywords.

虽然 Metal 和 [Swift](https://developer.apple.com/swift/) 是在 [WWDC keynote](https://www.apple.com/apple-events/june-2014/) 上被一同发表的，但着色语言是基于 [C++11](https://en.wikipedia.org/wiki/C%2B%2B11) 的，有一些有限的特点和增加的关键字。

### The Metal Shading Language in Practice

### Metal 着色语言实践

To use the vertex data from our shaders, we define a struct type that corresponds to the layout of the vertex data in the Objective-C program:

    typedef struct
    {
        float4 position;
        float4 color;
    } VertexIn;
    
为了从着色器里使用顶点数据，我们定义了一个对应顶点数据的结构体：

```objc
typedef struct
{
    float4 position;
    float4 color;
} VertexIn;
```

We also need a very similar type to describe the vertex type that will be passed from our vertex shader to the fragment shader. However, in this case, we must identify (through the use of the `[[position]]` attribute) which member of the struct should be regarded as the vertex position:

    typedef struct {
     float4 position [[position]];
     float4 color;
    } VertexOut;
    
我们还需要一个类似的结构体来描述从顶点着色器传入碎片着色器的顶点类型。然而，在本例中，我们必须区分(通过使用 `[[position]]` 属性)哪一个结构体成员应该被看做是顶点位置:

```objc
typedef struct {
 float4 position [[position]];
 float4 color;
} VertexOut;
```

The vertex function is executed once per vertex in the vertex data. It receives a pointer to the list of vertices, and a reference to the uniform data, which contains the rotation matrix. The third parameter is an index that tells the function which vertex it is currently operating on.

顶点函数在顶点数据中每个顶点被执行一次。它接收顶点列表的一个指针，和一个包含旋转矩阵的统一数据的引用。第三个参数是一个索引，用来告诉函数操作的是哪个顶点。

Note that the vertex function arguments are followed by attributes that indicate their usage. In the case of the buffer arguments, the index in the parameter corresponds to the index we specified when setting the buffers on the render command encoder. This is how Metal figures out which parameter corresponds to each buffer.

注意顶点函数的参数后面紧跟着标明它们用途的属性。在缓冲区参数中，索引参数对应着我们在渲染命令编码器中设置缓冲区时指定的索引。Metal 就是这样来区分哪个参数对应哪个缓冲区。

Inside the vertex function, we multiply the rotation matrix by the vertex's position. Because of how we built the matrix, this has the effect of rotating the square about its center. We then assign this transformed position to the output vertex. The vertex's color is copied directly from the input to the output:

    vertex VertexOut vertex_function(device VertexIn *vertices [[buffer(0)]],
                                     constant Uniforms &uniforms [[buffer(1)]],
                                     uint vid [[vertex_id]])
    {
        VertexOut out;
        out.position = uniforms.rotation_matrix * vertices[vid].position;
        out.color = vertices[vid].color;
        return out;
    }
    
在顶点函数中，我们用顶点的位置乘以旋转矩阵。我们构建矩阵的方式决定了效果是围绕中心旋转正方形。接着我们将这个转换过的位置传入输出顶点。顶点颜色则从输入参数中直接复制。

```objc
vertex VertexOut vertex_function(device VertexIn *vertices [[buffer(0)]],
                                     constant Uniforms &uniforms [[buffer(1)]],
                                     uint vid [[vertex_id]])
{
    VertexOut out;
    out.position = uniforms.rotation_matrix * vertices[vid].position;
    out.color = vertices[vid].color;
    return out;
}
```

The fragment function is executed once per pixel. The argument is produced by Metal in the process of [rasterization](http://fgiesen.wordpress.com/2013/02/08/triangle-rasterization-in-practice/) by interpolating between the position and color parameters specified at each vertex. In this simple fragment function, we simply pass out the interpolated color already produced by Metal. This then becomes the color of the pixel on the screen:

    fragment float4 fragment_function(VertexOut in [[stage_in]])
    {
        return in.color;
    }
    
碎片函数每个像素就会被执行一次。Metal 在 [rasterization](http://fgiesen.wordpress.com/2013/02/08/triangle-rasterization-in-practice/) 过程中会通过在每个顶点中指定的位置和颜色参数中添加来生成参数。在这个简单的碎片函数中，我们只是简单的返回了 Metal 添加的颜色。这会成为屏幕像素的颜色:

```objc
fragment float4 fragment_function(VertexOut in [[stage_in]])
{
    return in.color;
}
```

## Why Not Just Extend OpenGL?

## 为什么不干脆扩展 OPENGL?

Apple is on the OpenGL Architecture Review Board, and has also historically provided its own GL extensions in iOS. But changing OpenGL from the inside seems to be a difficult task because it has different design goals. In particular, it must run on a broad variety of devices with a huge range of hardware capabilities. Although OpenGL is continuing to improve, the process is slower and more subtle.

苹果是 OpenGL Architecture Review Board 成员，并且历史上也在 iOS 上提供过它们自己的 GL 扩展。但从内部改变 OpenGL 看起来是个困难的任务，因为它有着不同的设计目标。实际上，它必须有广泛的硬件兼容性以运行在很多不同的设备上。虽然 OpenGL 还在持续发展，但速度缓慢和微小。

Metal, on the other hand, was exclusively created with Apple's platforms in mind. Even if the protocol-based API looks unusual at first, it fits very well with the rest of the frameworks. Metal is written in Objective-C, is based on [Foundation](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/ObjC_classic/index.html), and makes use of Grand Central Dispatch to synchronize between the CPU and GPU. It is a much more modern abstraction of the GPU pipeline than OpenGL can be without a complete rewrite.

而 Metal 则本来就是只为了苹果的平台而创建的。即使基于协议的 API 最初看起来不太常见，但和其它框架配合的很好。Metal 是用 Objective-C 编写的，基于 [Foundation](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/ObjC_classic/index.html)，使用 GCD 在 CPU 和 GPU 之间保持同步。它是更先进的 GPU 管道的抽象，除非 OpenGL 完全重写。

## Metal on the Mac?

## Mac 上的 Metal?

It will only be a matter of time before Metal will be available for OS X, too. The API itself is not limited to the ARM processors that power iPhones and iPads. Most of Metal's benefits are transferable to modern GPUs. Additionally, the iPhone and iPad share RAM between the CPU and GPU, which enables data exchange without actually copying any data. Current generations of Macs don't offer unified memory, but this too will only be a matter of time. Perhaps the API will be adjusted to support architectures with dedicated RAM, or Metal will only run on a future generation of Macs.

OS X 上支持 Metal 也是迟早的事。API 本身并不局限于 iPhone 和 iPad 使用的 ARM 架构的处理器。Metal 的大多数有点都可以移植到先进的 GPU 上。另外，iPhone 和 iPad 的 CPU 和 GPU 是共享内存的，无需复制就可以交换数据。这一代的 Mac 电脑并未提供共享内存，但这只是时间问题。或许，API 会被调整为支持使用了专门内存的架构，或者 Metal 只会运行在下一代的 Mac 电脑上。

## Summary

## 总结

In this article, we have attempted to provide a helpful and unbiased introduction to the Metal framework.

Of course, most game developers will not have direct contact with Metal. However, top game engines already take advantage of it, and developers will profit from the newly available power without touching the API itself. Additionally, for those who want to use the full power of the hardware, Metal may enable developers to create unique and spectacular effects in their games, or perform parallel computations much faster, giving them a competitive edge.

本文中我们尝试给出公正并有所帮助的关于 Metal 框架的介绍。

当然，大多数的游戏开发者并不会直接使用 Metal。然而，顶层的游戏引擎已经从中获益，并且开发者无需直接使用 API 就可以从最新的技术中得到好处。另外，对于那些想要发挥硬件全部性能的开发者来说，Metal 或许可以让他们在游戏中创建出与众不同而华丽的效果，或者进行更快的并行计算，从而得到竞争优势。

## Resources

* [Metal Programming Guide](https://developer.apple.com/Library/ios/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Introduction/Introduction.html)
* [Metal Shading Language Guide](https://developer.apple.com/library/ios/documentation/Metal/Reference/MetalShadingLanguageGuide/Introduction/Introduction.html)
* [Metal by Example](http://metalbyexample.com)

## 资源

* [Metal Programming Guide](https://developer.apple.com/Library/ios/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Introduction/Introduction.html)
* [Metal Shading Language Guide](https://developer.apple.com/library/ios/documentation/Metal/Reference/MetalShadingLanguageGuide/Introduction/Introduction.html)
* [Metal by Example](http://metalbyexample.com)