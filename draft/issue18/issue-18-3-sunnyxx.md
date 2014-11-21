---
title:  "Scene Kit"
category: "18"
date: "2014-11-10 09:00:00"
tags: article
author: "<a href=\"https://twitter.com/davidronnqvist\">David Rönnqvist</a>"
---



Scene Kit is a Cocoa-style 3D rendering framework that was introduced for OS X back when Apple was still doing cat names (WWDC 2012). It had a good first release as a general 3D _renderer_, and added powerful features like shader modifiers, constraints, and skeletal animations the year after, when Apple introduced its first non-cat OS X: Mavericks. This year (2014), Scene Kit became even more powerful, with support for particle effects, physics simulation, scripted events, and multi-pass rendering, _and_ (perhaps most important to many people) it was introduced to iOS, and Apple now refers to it as "casual game ready." 

在WWDC 2012（那时OS X系统还在用喵系命名），Apple向OS X开发者们介绍了Scene Kit，这个Cocoa下的3D渲染框架。在第一版通用3D渲染器发布后，一年内又陆续增加了像shader（着色器）修改器、节点约束、骨骼动画等几个强大的特性（随Mavericks发布）。今年，Scene Kit变的更加强大，支持了粒子效果、物理引擎、脚本事件以及多通道分层渲染等多种技术，而且，对于很多人来说更关键的是，它终于可以在iOS中使用了。

From the start, I found Scene Kit's biggest strength and differentiator to be its integration with other graphics frameworks like Core Image, Core Animation, and now also Sprite Kit. These are not the things you would normally look for in a game engine, but if you are a hobbyist or otherwise mainly a Cocoa (or Cocoa Touch) developer, then this means that a lot of things should already feel familiar.

一上手，我发现Scene Kit最强大和脱颖而出的地方，就是可以与Core Image，Core Animation，Sprite Kit等已有的图形框架相互整合及协作，这在其他游戏引擎中可不常见，但如果你本身就是个Cocoa或Cocoa Touch框架下的的开发者的话，就会感到相当亲切了。  

# Scene Kit Basics



Scene Kit is built on top of OpenGL, as a higher-level framework where lights, geometries, materials, and cameras are objects that you work with in your Objective-C or Swift code. If you've used OpenGL in [its earliest releases][opengl1], before shaders, this terminology might bring back bad memories of a restricted system with limited configurability. Luckily, this is not the case. High-level configuration is enough for most common tasks — even more advanced things like dynamic shadows and [depth of field][dof] effects. 


Where that is not enough, Scene Kit allows you drop down to a lower level and configure the rendering with your own OpenGL shader code ([GLSL][glsl]).

# Scene Kit概要
Scene Kit建立在OpenGL的基础上，包含了如光照、模型、材质、摄像机等高级引擎特性，这些组件都是面向对象的，你可以用熟悉的Objective-C或Swift语言来编写代码。假如你用过OpenGL[最早的版本][opengl1]，那时还没有shader，只能苦逼的使用各种底层受限制的API开发。而Scene Kit就好了很多，对于大多数需求（甚至像动态阴影和[景深][dof]这种高级特性），使用它提供的上层API来配置，就已经足够了。

不仅如此，Scene Kit还允许你直接调用底层API，或自己写shader进行手动渲染([GLSL][glsl])。

## Nodes
## Nodes（节点）

In addition to the lights, geometries, materials, and cameras, Scene Kit uses a hierarchy of nodes[^name] to organize its content. Each node has a position, rotation, and scale relative to its parent node, which in turn is relative to _its_ parent node, all the way up to the root node. To give one of the other objects a position in the 3D world, it is attached to one of the nodes. The node hierarchy is managed using methods like:

[^name]: A hierarchy of nodes like this is commonly called a _scene graph_ in 3D graphics. That's one explanation for the name Scene Kit.


不仅是光照、模型、材质、摄像机这几个具体的对象，Scene Kit使用节点[^name2]以树状结构来组织内容，每个节点都存储了相对其父节点的位移、旋转角度、缩放等信息，父节点也是如此，一直向上，直到根节点。假如要给一个节点确定一个位置，就必须将它挂载到节点树中的某个节点上，可以使用下面的几个操作方法：

[^name2]: 在3D图形学中，像这样的树状节点结构一般被称做 _scene graph_ ，这也是Scene Kit名称由来的一种解释

- `addChildNode(_:)` 
- `insertChildNode(_: atIndex:)` 
- `removeFromParentNode()` 

These mirror some of the methods that are used to manage the view hierarchies and layer hierarchies on iOS and OS X. 

这些方法与iOS和OS X中管理view和layer层级方法如出一辙。

## Geometry Objects
## 几何模型对象


Scene Kit comes with built-in geometry objects for simple shapes like boxes, spheres, planes, and cones, but for games, you'll mostly be loading 3D models from a file. You can import (and export) [COLLADA files][collada] by referencing a file by name:

Scene Kit内建了几种简单的几何模型，如盒子、球体、平面、圆锥体等，但对于游戏来说，一般都会从文件中加载3D模型。你可以通过制定文件名来导入（或导出）[COLLADA][collada]格式的模型文件： 

    let chessPieces = SCNScene(named: "chess pieces") // SCNScene?



If the scene contained in the file should be displayed as is in its entirety, then it can be used as the scene view's scene. If the scene contains multiple objects, but only some of them should be displayed on the screen, then they can be found, referenced by their names, and added to the scene that's being rendered in the scene view:

如果一个从文件里加载的场景可以全部显示时，将其设置成SCNView的scene就好了；但如果加载的场景文件中包含了多个对象，只有一部分对象要显示在屏幕上时，就可以通过名字找到这个对象，再手动加载到view上：

	if let knight = chessPieces.rootNode.childNodeWithName("Knight", recursively: true) {
	    sceneView.scene?.rootNode.addChildNode(knight)
	}


This is a reference to the original node in the imported file and contains any and all child nodes, as well as the geometry objects (with their materials), lights, and cameras that were attached to those nodes. Asking for the child node with the same name again will get you a reference to the same object. 

这是一个对导入文件原始节点的引用，其中包含了任一和每一个子节点，也包括了模型对象（包括其材质），光照，以及绑定在这些节点上的摄像机。只要传入的名字一样，不论调用多少次，返回的都是对同一个对象的引用。

![Node > Geometry > Material > Textures](http://img.objccn.io/issue-18/textures.png)

To have multiple copies in a scene, for example, to display two knights on a chess board, you would either `copy` the node or `clone` it (for a recursive copy). This makes a copy of the node that references the same geometry object with the same materials. Both copies would still point to the same geometry objects. So to change one piece's material, the geometry object would also have to be copied and have a new material attached to it. Copying a geometry object remains fast and cheap, since the copies still refer to the same vertex data. 

若需要在场景中拥有一个节点的多个拷贝，如在一个国际象棋棋盘上显示两个马，你可以对马这个节点进行`copy`或`clone`（递归的copy）。这将会拷贝一份节点的引用，但两份引用所指向的材质对象和模型对象仍然是原来那个。所以，想要单独改变副本材质的话，需要再copy一份模型对象，并对这个新的模型对象设置新材质。copy一个模型对象的速度仍然很快，开销也不高，因为副本引用的顶点数据还是同一份。

Imported nodes with geometry objects that are rigged for [skeletal animation][skeletal] have a skinner object, which provides access to the skeletal node hierarchy and manages the relationship between the bones and the geometry object. Individual bones can be moved and rotated; however, a more complex animation modifying multiple bones — for example, a character's walk cycle — would most likely be loaded from a file and added to the object.

带有骨骼动画的模型对象也会拥有一个皮肤对象，它提供了对骨骼中各个节点的访问接口，以及管理骨骼和模型间连接的功能。每个单独的骨骼都可以被移动和旋转，而复杂的动画需要同时对多块骨骼进行操作，如一个角色走路的动画，很可能就是从文件读取并加到对象上的。（而不是用代码一根骨头一根骨头的写）

## Lights

## 光照
Lights in Scene Kit are completely dynamic. This makes them easy to grasp and generally easy to work with, but it also mean that the lighting they provide is less advanced than that of a fully fledged game engine. There are four different types of lights: ambient, directional, omnidirectional (point lights), and spotlights. 

Scene Kit中完全都是动态光照，使用起来一般会很简单，但也意味着与完整的游戏引擎相比，光照这块进步并不明显。Scene Kit提供四种类型的光照：环境光、定向光源、点光源和聚光灯。

In many cases, specifying a rotation axis and an angle is not the most intuitive way of pointing a light at an object. In these cases, the node that gives the light its position and orientation can be constrained to look at another node. Adding a "look at"-constraint also means that the light will keep pointing at that node, even as it moves:

通常来说，旋转坐标轴和变换角度并不是设定光照的最佳方法。下面的例子表示一个光照对象通过一个节点对象来设置空间坐标，再通过"look at"约束，将光照对象约束到了目标对象上，即使它移动，光照也会一直朝向目标对象。

	let spot = SCNLight()
	spot.type = SCNLightTypeSpot
	spot.castsShadow = true
	
	let spotNode = SCNNode()
	spotNode.light = spot
	spotNode.position = SCNVector3(x: 4, y: 7, z: 6)
	
	let lookAt = SCNLookAtConstraint(target: knight)
	spotNode.constraints = [lookAt]
	
![Rotating Knight with dynamic shadow](http://img.objccn.io/issue-18/spinning.gif)
	
## Animation 

## 动画

Pretty much any property on any object in Scene Kit is animatable. Just as with Cocoa (or Cocoa Touch), this means that you can create a `CAAnimation` for that key path (even paths like `"position.x"`) and add it to the object. Similarly, you can change the value in between the "begin" and "commit" of a `SCNTransaction`. These two approaches should be immediately familiar, but weren't built specifically for animations in games:

Scene Kit的对象中绝大多数属性都是可以进行动画的，就像Cocoa（或Cocoa Touch）框架一样，你可以创建一个`CAAnimation`对象，并指定一个key path（甚至可以`"position.x"`），然后向一个对象施加这个动画。同样的，你可以在`SCNTransaction`的"begin"和"commit"调用间去改变值，和刚才的CAAnimation非常相似：

	let move = CABasicAnimation(keyPath: "position.x")
	move.byValue  = 10
	move.duration = 1.0
	knight.addAnimation(move, forKey: "slide right")




Scene Kit also supports the action-style animation API from Sprite Kit. This allows you to create sequences of animations and run blocks of code as custom actions together with other animations. Unlike Core Animation, these actions run as part of the game loop and update the model value for every frame, not just the presentation node. 

Scene Kit也提供了像Sprite Kit那样的action形式的动画API，你可以创建串行的动画组，也支持自定义action来协同使用。与Core Animation不同的是，这些action作为游戏循环的一部分执行，在每一帧都更新模型对象的值，而不只是更新表现层的节点。

In fact, if you've worked with Sprite Kit before, Scene Kit should look fairly familiar, but in 3D. As of iOS 8 (the first iOS version that supports Scene Kit) and OS X 10.10, the two frameworks (Scene Kit and Sprite Kit) can work together. On the Sprite Kit side of things, 3D models can be mixed with 2D sprites. On the Scene Kit side of things, Sprite Kit scenes and textures can be used as textures in Scene Kit, and a Sprite Kit scene can be used as a 2D overlay on top of a Scene Kit scene[^twoScenes]. 

假如你之前用过Sprite Kit，会发现Scene Kit除了变成了3D之外，没有太多陌生的东西。目前，在iOS8（首次支持Scene Kit）和OS X 10.10下，Scene Kit和Sprite Kit可以协同工作：对Sprite Kit来说，3D模型可以与2D精灵混合使用；对Scene Kit来说，Sprite Kit中的场景和纹理可以作为Scene Kit的纹理贴图，而且Sprite Kit的场景可以作为Scene Kit场景的蒙层[^twoScenes2]。（如3D游戏中的2D菜单面板，译者注）

[^twoScenes]: Yes, having two very similar APIs with two very similar concepts (scenes, nodes, constrains, etc. exist in both Scene Kit and Sprite Kit) can get confusing.

[^twoScenes2]: 两套非常像的API和概念（像场景啊，节点啊，约束啊两边都有）让人容易混淆。

# Writing Games in Scene Kit

# 开始用Scene Kit写游戏 

Actions and textures are not the only things that Scene Kit and Sprite Kit have in common. When it comes to writing a game using Scene Kit, it bears a strong resemblance to its 2D counterpart. In both cases, the game loop goes through the same steps, making callbacks to the delegate:

1. Updating the scene
2. Applying animations / actions
3. Simulating physics 
4. Applying constraints
5. Rendering

不仅是动作和纹理，Scene Kit和Sprite Kit还有很多相同之处。当开始写游戏的时候，Scene Kit和它2D版本的小伙伴非常相似，它们的游戏循环步骤完全一致，使用线面几个代理回调：

1. 更新场景
2. 应用动画/动作
3. 模拟物理效果
4. 应用约束
5. 渲染

![Game Loop](http://img.objccn.io/issue-18/gameloop.png)

Each callback is sent exactly once per frame and is used to perform gameplay-related logic like input handling, artificial intelligence, and game scripting.

这些回调在每帧被调用，并用来执行游戏相关的逻辑，如用户输入，AI（人工智能）和游戏脚本。

## Input Handling

## 处理用户输入

Scene Kit uses the same input mechanisms for keyboard events, mouse events, touch events, and gesture recognition as regular Cocoa and Cocoa Touch apps, the main difference being that there is only one view, the scene view. For keyboard events, or gestures like pinch, swipe, and rotate, it may be fine just knowing _that_ they happened, but events like clicks, and gestures like taps or pans, are likely to require more information about the event. 

Scene Kit与普通Cocoa或Cocoa Touch应用使用一样的机制来处理用户输入，如键盘事件、鼠标事件、触摸事件和手势识别，而主要区别在于Scene Kit中只有一个视图，场景视图（scene view）。像键盘事件或如捏取、滑动、旋转的手势，只要知道事件的发生就好了，但像鼠标点击，或触碰、拖动手势等就需要知道具体的事件信息了。

For these cases, the scene view can be hit tested using `-hitTest(_: options:)`. Unlike regular views and layers that only return the subview or sublayer that was hit, Scene Kit returns an array of hit test results for each intersection with a geometry object and a ray from the camera through the specified point. Each hit test result contains basic information about what node the hit geometry object belongs to, as well as detailed information about the intersection (the coordinate of the hit, the surface normal at that point, and the texture coordinates at that point). For many cases, it's enough just knowing what the first node that was hit was:

	if let firstHit = sceneView.hitTest(tapLocation, options: nil)?.first as? SCNHitTestResult {
	    let hitNode = firstHit.node
	    // do something with the node that was hit...
	}

这些情况下，scene view可以使用`-hitTest(_: options:)`来做点击测试。与通常的视图只返回被点击的子view或子layer不同，Scene Kit返回一个数组，里面存有每个相交的模型对象以及从摄像机投向这个测试点的射线。每个hit test的结果包含被击中模型的节点对象，也包含了交点的详细信息（交点坐标、交点表面法线，交点的纹理坐标）。多数情况下，知道第一个被击中的节点就足够了： 

	if let firstHit = sceneView.hitTest(tapLocation, options: nil)?.first as? SCNHitTestResult {
	    let hitNode = firstHit.node
	    // do something with the node that was hit...
	}

# Extending the Default Rendering

# 扩展默认渲染流程

Light and material configurations, while easy to work with, can only get you so far. If you already have existing OpenGL shaders, you can configure a material to use those for rendering, in order to do something completely custom. However, if you only want to modify the default rendering, Scene Kit exposes four points where snippets of shader code (GLSL) can be injected into the default rendering. At the different entry points, Scene Kit provides access to data like transform matrices, geometry data, sampled textures, and the rendered output color. 

光照和材质的配置方法很易用，但有局限性。假如你有写好的OpenGL着色器（shader），可以用于完全自定制的进行材质渲染；如果你只想修改下默认的渲染，Scene Kit暴露了4个入口用于插入shader代码（GLSL）来改变默认渲染。Scene Kit在不同入口点分别提供了对旋转矩阵、模型数据、样本贴图及渲染后输出的色值的访问。

For example, these lines of GLSL in the geometry entry points can be used to twist all points in a geometry object around the x-axis. This is done by defining a function to create a rotation transform and applying such a transform to the positions and normals of the geometry object. This also defines a custom ["uniform" variable][uniform] that determines how much the object is twisted:

比如，下面的GLSL代码被用在模型数据的入口点中，可以将模型对象上所有点沿x轴扭曲。这是通过定义一个函数来创建一个旋转变换，并将其应用在模型的位置和法线上。同时，也自定义了一个["uniform"变量][uniform]来决定对象该如何被扭曲。

	// a function that creates a rotation transform matrix around X
	mat4 rotationAroundX(float angle)
	{
	    return mat4(1.0,    0.0,         0.0,        0.0,
	                0.0,    cos(angle), -sin(angle), 0.0,
	                0.0,    sin(angle),  cos(angle), 0.0,
	                0.0,    0.0,         0.0,        1.0);
	}
	
	#pragma body
	
	uniform float twistFactor = 1.0;
	float rotationAngle = _geometry.position.x * twistFactor;
	mat4 rotationMatrix = rotationAroundX(rotationAngle);
	
	// position is a vec4
	_geometry.position *= rotationMatrix;
	
	// normal is a vec3
	vec4 twistedNormal = vec4(_geometry.normal, 1.0) * rotationMatrix;
	_geometry.normal   = twistedNormal.xyz;

Shader modifiers can be attached to either a geometry object or to one of its materials. Both classes are fully key-value coding compliant, which means that you can set values for arbitrary keys. Having declared the "twistFactor" uniform in the shader modifier makes Scene Kit observe that key and re-bind the uniform variable whenever the value changes. This means that it can be altered using key-value coding:

着色修改器（Shader modifier）既可以绑定在模型对象上，也可以绑定在它的材质对象上。这两个类都完全支持key-value coding（KVC），你可以指定任意key进行赋值。在shader中声明的"twistFactor" uniform变量使得Scene Kit在这个值改变时自动重新绑定uniform，这使得你也可以用KVC来实现：

	torus.setValue(5.0, forKey: "twistFactor")

It can also be animated by creating a `CAAnimation` for that key path:

使用这个key path的`CAAnimation`也ok：

	let twist = CABasicAnimation(keyPath: "twistFactor")
	twist.fromValue = 5
	twist.toValue   = 0
	twist.duration  = 2.0
	
	torus.addAnimation(twist, forKey: "Twist the torus")

![Animated twisting torus](http://img.objccn.io/issue-18/twist.gif)

## Deferred Shading
## 延时着色

There are some graphic effects that can't be achieved in a single render pass, even in pure OpenGL. Instead, different shaders operate in a sequence to perform post-processing or [deferred shading][deferred]. Scene Kit represents such rendering techniques using the [SCNTechnique class][technique]. It is created with a dictionary that defines the drawing passes, their inputs and outputs, shader files, symbols, etc.

即使在纯OpenGL环境下，有些图像效果也无法通过一次渲染pass完成，我们可以将不同shader进行序列操作，以达到后续处理的目的，称为[延时着色][deferred]。Scene Kit使用[SCNTechnique类][technique]来表示这种技术。它使用字典来创建，字典中定义了绘图步骤、输入输出、shader文件、符号等等。

The first pass is always Scene Kit's default rendering, which outputs both the color and the depth of the scene. If you don't want the colors to be shaded, the materials can be configured to have the "constant" lighting model, or all lights in the scene can be replaced with a single ambient light.

第一个渲染pass永远是Scene Kit的默认渲染，它输出场景的颜色和景深。如果你不想这时计算色值，可以将材质设置成"恒定"的光照模型，或者将场景里所有光照都设置成环境光。

For example, by getting the depth from Scene Kit's initial pass and the normals from a second pass, and performing edge detection on both of them in a third pass, you can draw strong contours both along the outline and along edges:

比如，从Scene Kit渲染流程的第一个pass获取景深，第二个获取法线，第三个对其执行边界检测，你即可以沿轮廓也可以沿边缘画粗线：

![Bishop with strong contours](http://img.objccn.io/issue-18/bishop.png)

---

**Further Reading**  
**延伸阅读**

If you want to learn more about making games using Scene Kit, I recommend watching the ["Building a Game with Scene Kit" video][wwdc game] from this year's WWDC and looking at the [Bananas sample code][bananas].

如果你想了解更多使用Scene Kit做游戏的知识的话，我推荐今年的WWDC中得["Building a Game with Scene Kit" video][wwdc game]，并看看[Bananas sample code][bananas].

Additionally, if you want to learn about Scene Kit in general, I recommend watching [this year's][wwdc 13] and [last year's][wwdc 14] "What's New in Scene Kit" videos. If you still want to learn more, you can check out [my upcoming book][book] on the topic.

如果你想学习Scene Kit基础知识，我推荐看[这一年的][wwdc 13]和[去年的][wwdc 14]"What's New in Scene Kit"相关视频。如果你还想学习更多，可以关注[我即将发布的这个主题的书](book)。
  
[collada]: https://en.wikipedia.org/wiki/COLLADA

[skeletal]: https://en.wikipedia.org/wiki/Skeletal_animation

[opengl1]: https://www.opengl.org/documentation/specs/version1.1/glspec1.1/node30.html#SECTION005130000000000000000
[glsl]: https://en.wikipedia.org/wiki/OpenGL_Shading_Language
[dof]: https://en.wikipedia.org/wiki/Depth_of_field
[uniform]: https://www.opengl.org/wiki/Uniform_(GLSL)
[deferred]: https://en.wikipedia.org/wiki/Deferred_shading

[wwdc game]: https://developer.apple.com/videos/wwdc/2014/?id=610
[bananas]: https://developer.apple.com/library/ios/samplecode/Bananas/Introduction/Intro.html

[technique]: https://developer.apple.com/library/ios/documentation/SceneKit/Reference/SCNTechnique_Class/index.html

[wwdc 13]: https://developer.apple.com/videos/wwdc/2013/?id=500
[wwdc 14]: https://developer.apple.com/videos/wwdc/2014/?id=609

[book]: http://scenekitbook.com