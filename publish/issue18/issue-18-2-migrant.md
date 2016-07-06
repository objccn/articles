> Metal 框架支持 GPU 加速高级 3D 图像渲染，以及数据并行计算工作。Metal 提供了先进合理的 API，它不仅为图形的组织、处理和呈现，也为计算命令以及为这些命令相关的数据和资源的管理，提供了细粒度和底层的控制。Metal 的主要目的是最小化 GPU 工作时 CPU 所要的消耗。

– [Metal Programming Guide](https://developer.apple.com/library/ios/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40014221-CH1-SW1)

Metal 是针对 iPhone 和 iPad 中 GPU 编程的高度优化的框架。其名字来源是因为 Metal 是 iOS 平台中最底层的图形框架 (意指 "最接近硬件")。

该框架被设计用来实现两个目标: 3D 图形渲染和并行计算。这两者有很多共同点。它们都在数量庞大的数据上并行运行特殊的代码，并可以在 [GPU](https://en.wikipedia.org/wiki/Graphics_processing_unit).  上执行。

## 什么人应该使用 Metal?

在谈论 API 和语言本身之前，我们应该讨论一下什么样的开发者能从 Metal 中受益。正如上面提过的，Metal 提供两个功能: 图形渲染和并行计算。

对于寻找游戏引擎的开发者来说，Metal 不是最佳选择。苹果官方的的 [Scene Kit](https://developer.apple.com/library/ios/documentation/SceneKit/Reference/SceneKit_Framework/) (3D) 和 [Sprite Kit](https://developer.apple.com/library/ios/documentation/GraphicsAnimation/Conceptual/SpriteKit_PG/Introduction/Introduction.html) (2D) 是更好的选择。这些 API 提供了包括物理模拟在内的更高级别的游戏引擎。另外还有功能更全面的 3D 引擎，例如 Epic 的 [Unreal Engine](https://www.unrealengine.com/) 或 [Unity](http://unity3d.com)，二者都是跨平台的。使用这些引擎，你无需直接使用 Metal 的 API，就可以从 Metal 中获益。

编写基于底层图形 API 的渲染引擎时，除了 Metal 以外的其他选择还有 OpenGL 和 OpenGL ES。OpenGL 不仅支持包括 OSX，Windows，Linux 和 Android 在内的几乎所有平台，还有大量的教程，书籍和最佳实践指南等资料。目前，Metal 的资源非常有限，并且仅限于搭载了 64 位处理器的 iPhone 和 iPad。但另外一方面，因为 OpenGL 的限制，其性能与 Metal 相比并不占优势，毕竟后者是专门用来解决这些问题的。

如果想要一个 iOS 上高性能的并行计算库，答案非常简单。Metal 是唯一的选择。OpenCL 在 iOS 上是私有框架，而 Core Image (使用了 OpenCL) 对这样的任务来说既不够强大又不够灵活。

## 使用 Metal 的好处

Metal 的最大好处就是与 OpenGL ES 相比显著降低了消耗。在 OpenGL 中无论创建缓冲区还是纹理，OpenGL 都会复制一份以防止 GPU 在使用它们的时候被意外访问。出于安全的原因复制类似纹理和缓冲区这样的大的资源是非常耗时的操作。而 Metal 并不复制资源。开发者需要负责在 CPU 和 GPU 之间同步访问。幸运的是，苹果提供了另一个很棒的 API 使资源同步访问更加容易，那就是 [Grand Central Dispatch](https://developer.apple.com/library/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/index.html)。虽然使用 Metal 时仍然有些这方面的问题需要注意，但是一个在渲染时加载和卸载资源的先进的引擎，在避免额外的复制后能够获得更多的好处。

Metal 的另外一个好处是其预估 GPU 状态来避免多余的验证和编译。通常在 OpenGL 中，你需要依次设置 GPU 的状态，在每个绘制指令 (draw call) 之前需要验证新的状态。最坏的情况是 OpenGL 需要再次重新编译着色器 (shader) 以反映新的状态。当然，这种评估是必要的，但 Metal 选择了另一种方法。在渲染引擎初始化过程中，一组状态被烘焙 (bake) 至预估渲染的 路径 (pass) 中。多个不同资源可以共同使用该渲染路径对象，但其它的状态是恒定的。Metal 中一个渲染路径无需更进一步的验证，使 API 的消耗降到最低，从而大大增加每帧的绘制指令的数量。

## Metal API

虽然这个平台上许多 API 都暴露为具体的类，但 Metal 提供的大多是协议。因为 Metal 对象的具体类型取决于 Metal 运行在哪个设备上。这更鼓励了面向接口而不是面向实现编程。然而，这同时也意味着，如果不使用 Objective-C 运行时的广泛而危险的操作，就不能子类化 Metal 的类或者为其增加扩展，

Metal 为了速度而在安全性上做了必要的妥协。对于错误，苹果的其它框架显得更加安全和健壮，而 Metal 则完全相反。在某些时候，你会收到指向内部缓冲区的裸指针，你必须小心的同步访问它。OpenGL 中发生错误时，结果通常是黑屏；然而在 Metal 中，结果可能是完全随机的效果，例如闪屏和偶尔的崩溃。之所以有这些陷阱，是因为 Metal 框架是对 GPU 的非常轻量级抽象。

一个有趣的方面是苹果并没有为 Metal 实现可以在 iOS 模拟器上使用的软件渲染。使用 Metal 框架的时候应用必须运行在真实设备上。

## 基础 Metal 程序

在这部分中，我们会介绍写出第一个 Metal 程序所必要的部分。这个简单的程序绘制了一个正方形的旋转。你可以在 [GitHub 中下载这篇文章的示例代码](https://github.com/objcio/metal-demo-objcio)。

虽然不能涵盖每一个细节，但我们尽量涉及至少所有的移动部分。你可以阅读源代码和参阅线上资源来深入理解。

### 使用 UIKit 创建设备和界面

在 Metal 中，**设备**是 GPU 的抽象。它被用来创建很多其它类型的对象，例如缓冲区，纹理和函数库。使用 `MTLCreateSystemDefaultDevice` 函数来获取默认设备:

```objc
id<MTLDevice> device = MTLCreateSystemDefaultDevice();
```

注意 device 并不是一个详细具体的类，正如前面提到的，它是遵循 `MTLDevice` 协议的类。

下面的代码展示了如何创建一个 Metal layer 并将它作为 sublayer 添加到一个 UIView 的 layer:

```objc
CAMetalLayer *metalLayer = [CAMetalLayer layer];
metalLayer.device = device;
metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
metalLayer.frame = view.bounds;
[view.layer addSublayer:self.metalLayer];
```

`CAMetalLayer` 是 [`CALayer`](https://developer.apple.com/library/mac/Documentation/GraphicsImaging/Reference/CALayer_class/index.html) 的子类，它可以展示 Metal 帧缓冲区的内容。我们必须告诉 layer 该使用哪个 Metal 设备 (我们刚创建的那个)，并通知它所预期的像素格式。我们选择 8-bit-per-channel BGRA 格式，即每个像素由蓝，绿，红和透明组成，值从 0-255。

### 库和函数

你的 Metal 程序的很多功能会被用顶点和片段函数的方式书写，也就是我们所说的着色器。Metal 着色器用 Metal 着色器语言编写，我们将在下面详细讨论。Metal 的优点之一就是着色器函数在你的应用构建到中间语言时进行编译，这可以节省很多应用启动时所需的时间。

一个 Metal 库是一组函数的集合。你的所有写在工程内的着色器函数都将被编译到默认库中，这个库可以通过设备获得:

```objc
id<MTLLibrary> library = [device newDefaultLibrary]
```

接下来构建渲染管道状态的时候将使用这个库。

### 命令队列

命令通过与 Metal 设备相关联的命令队列提交给 Metal 设备。命令队列以线程安全的方式接收命令并顺序执行。创建一个命令队列:

```objc
id<MTLCommandQueue> commandQueue = [device newCommandQueue];
```

### 构建管道

当我们在 Metal 编程中提到管道，指的是顶点数据在渲染时经历的变化。顶点着色器和片段着色器是管道中两个可编程的节点，但还有其它一定会发生的事件 (剪切，栅格化和视图变化) 不在我们的直接控制之下。管道特性中的后者的类组成了固定功能管道。

在 Metal 中创建一个管道，我们需要指定对于每个顶点和每个像素分别想要执行哪个顶点和片段函数 (译者注: 片段着色器又被称为像素着色器)。我们还需要将帧缓冲区的像素格式告诉管道。在本例中，该格式必须与 Metal layer 的格式匹配，因为我们想在屏幕上绘制。

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

最后，我们从描述器中创建管道状态。这会根据程序运行的硬件环境，从中间代码中编译着色器函数为优化后的代码。

```objc
id<MTLRenderPipelineState> pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:nil];
```

### 读取数据到缓冲区

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

你可能会奇怪为什么需要四个数字来描述 3D 空间中的一个位置。第四个顶点位置元素，w，是一个数学上的便利，使我们能以一种统一的方式描述 3D 转换 (旋转，平移，缩放)。这个细节在本文的示例代码并没有体现。

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

### 动画

为了在屏幕上旋转正方形，我们需要把转换顶点作为顶点着色器的一部分。这需要更新每一帧的统一缓冲区。我们运用三角学知识，从当前旋转角度生成一个旋转矩阵，将它复制到统一缓冲区。

`Uniforms` 结构体只有一个成员，该成员是一个保存了旋转矩阵的 4x4 的矩阵。矩阵类型 `matrix_float4x4` 来自于苹果的 SIMD 库，该库是一个类型的集合，它们可以从 [数据并行操作](http://en.wikipedia.org/wiki/SIMD) 中获益:

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

### 准备绘制

为了在 Metal layer 上绘制，首先我们需要从 layer 中获得一个 'drawable' 对象。这个可绘制对象管理着一组适合渲染的纹理:

```objc
id<CAMetalDrawable> drawable = [metalLayer nextDrawable];
```

接下来我们创建一个渲染路径描述器，它描述了在渲染之前和完成之后 Metal 应该执行的不同动作。下面我们展示了一个渲染路径，它将首先把帧缓冲区清除为纯白色，然后执行绘制指令，最后将结果存储到帧缓冲区来展示:

```objc
MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1);
renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
```

### 发布绘制指令

要放入设备的命令队列的命令必须被编码到命令缓冲区里。命令缓冲区是一个或多个命令的集合，可以以一种 GPU 了解的紧凑的方式执行和编码。

```objc
id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
```

为了真正编码渲染命令，我们还需要另一个知道如何将我们的绘制指令转换为 GPU 懂得的语言的对象。这个对象叫做命令编码器。我们将上面创建的渲染路径描述器作为参数传入，就可以向命令缓冲区请求一个编码器:

```objc
id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
```

在绘制指令之前，我们使用预编译的管道状态设置渲染命令编码器并建立缓冲区，该缓冲区将作为顶点着色器的参数:

```objc
[renderEncoder setRenderPipelineState:pipelineState];
[renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
[renderEncoder setVertexBuffer:uniformBuffer offset:0 atIndex:1];
```

为了真正的绘制几何图形，我们告诉 Metal 要绘制的形状 (三角形) 和缓冲区中顶点的数量 (本例中 6 个):

```objc
[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
```
    
最后，执行 `endEncoding` 通知编码器发布绘制指令完成。

```objc
[renderEncoder endEncoding];
```

### 展示帧缓冲区

现在我们的绘制指令已经被编码并准备就绪，我们需要通知命令缓冲区应该将结果在屏幕上显示出来。调用  `presentDrawable`，使用当前从 Metal layer 中获得的 drawable 对象作为参数:

```objc
[commandBuffer presentDrawable:drawable];
```

执行 `commit` 告诉缓冲区已经准备好安排并执行:

```objc
[commandBuffer commit];
```

就这么多！

## Metal 着色语言

虽然 Metal 和 [Swift](https://developer.apple.com/swift/) 是在 [WWDC keynote](https://www.apple.com/apple-events/june-2014/) 上被一同发表的，但着色语言是基于 [C++11](https://en.wikipedia.org/wiki/C%2B%2B11) 的，有一些有限制的特性和增加的关键字。

### Metal 着色语言实践
    
为了在着色器里使用顶点数据，我们定义了一个对应 Objective-C 中顶点数据的结构体：

```glsl
typedef struct
{
    float4 position;
    float4 color;
} VertexIn;
```

我们还需要一个类似的结构体来描述从顶点着色器传入片段着色器的顶点类型。然而，在本例中，我们必须区分 (通过使用 `[[position]]` 属性) 哪一个结构体成员应该被看做是顶点位置:

```glsl
typedef struct {
 float4 position [[position]];
 float4 color;
} VertexOut;
```

顶点函数在顶点数据中每个顶点被执行一次。它接收顶点列表的一个指针，和一个包含旋转矩阵的统一数据的引用。第三个参数是一个索引，用来告诉函数当前操作的是哪个顶点。

注意顶点函数的参数后面紧跟着标明它们用途的属性。在缓冲区参数中，参数中的索引对应着我们在渲染命令编码器中设置缓冲区时指定的索引。Metal 就是这样来区分哪个参数对应哪个缓冲区。

在顶点函数中，我们用顶点的位置乘以旋转矩阵。我们构建矩阵的方式决定了效果是围绕中心旋转正方形。接着我们将这个转换过的位置传入输出顶点。顶点颜色则从输入参数中直接复制。

```glsl
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

片段函数每个像素就会被执行一次。Metal 在 [rasterization](http://fgiesen.wordpress.com/2013/02/08/triangle-rasterization-in-practice/) 过程中会通过在每个顶点中指定的位置和颜色参数中添加来生成参数。在这个简单的片段函数中，我们只是简单的返回了 Metal 添加的颜色。这会成为屏幕像素的颜色:

```objc
fragment float4 fragment_function(VertexOut in [[stage_in]])
{
    return in.color;
}
```

## 为什么不干脆扩展 OPENGL?

苹果是 OpenGL 架构审查委员会的成员，并且历史上也在 iOS 上提供过它们自己的 GL 扩展。但从内部改变 OpenGL 看起来是个困难的任务，因为它有着不同的设计目标。实际上，它必须有广泛的硬件兼容性以运行在很多不同的设备上。虽然 OpenGL 还在持续发展，但速度缓慢。

而 Metal 则本来就是只为了苹果的平台而创建的。即使基于协议的 API 最初看起来不太常见，但和其它框架配合的很好。Metal 是用 Objective-C 编写的，基于 [Foundation](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/ObjC_classic/index.html)，使用 GCD 在 CPU 和 GPU 之间保持同步。它是更先进的 GPU 管道的抽象，而 OpenGL 想达到这些的话只能完全重写。

## Mac 上的 Metal?

OS X 上支持 Metal 也是迟早的事。API 本身并不局限于 iPhone 和 iPad 使用的 ARM 架构的处理器。Metal 的大多数优点都可以移植到先进的 GPU 上。另外，iPhone 和 iPad 的 CPU 和 GPU 是共享内存的，无需复制就可以交换数据。这一代的 Mac 电脑并未提供共享内存，但这只是时间问题。或许，API 会被调整为支持使用了专门内存的架构，或者 Metal 只会运行在下一代的 Mac 电脑上。

## 总结

本文中我们尝试给出公正并有所帮助的关于 Metal 框架的介绍。

当然，大多数的游戏开发者并不会直接使用 Metal。然而，顶层的游戏引擎已经从中获益，并且开发者无需直接使用 API 就可以从最新的技术中得到好处。另外，对于那些想要发挥硬件全部性能的开发者来说，Metal 或许可以让他们在游戏中创建出与众不同而华丽的效果，或者进行更快的并行计算，从而得到竞争优势。

## 资源

* [Metal Programming Guide](https://developer.apple.com/Library/ios/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Introduction/Introduction.html)
* [Metal Shading Language Guide](https://developer.apple.com/library/ios/documentation/Metal/Reference/MetalShadingLanguageGuide/Introduction/Introduction.html)
* [Metal by Example](http://metalbyexample.com)

---

 

原文 [Metal](http://www.objc.io/issue-18/metal.html)
