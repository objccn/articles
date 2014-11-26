
在WWDC 2012（那时OS X系统还在用喵系命名），Apple向OS X开发者们介绍了Scene Kit，这个Cocoa下的3D渲染框架。在第一版通用3D渲染器发布后，一年内又陆续增加了像shader（着色器）修改器、节点约束、骨骼动画等几个强大的特性（随Mavericks发布）。今年，Scene Kit变的更加强大，支持了粒子效果、物理引擎、脚本事件以及多通道分层渲染等多种技术，而且，对于很多人来说更关键的是，它终于可以在iOS中使用了。

一上手，我发现Scene Kit最强大和脱颖而出的地方，就是可以与Core Image，Core Animation，Sprite Kit等已有的图形框架相互整合及协作，这在其他游戏引擎中可不常见，但如果你本身就是个Cocoa或Cocoa Touch框架下的的开发者的话，就会感到相当亲切了。  

# Scene Kit概要

Scene Kit建立在OpenGL的基础上，包含了如光照、模型、材质、摄像机等高级引擎特性，这些组件都是面向对象的，你可以用熟悉的Objective-C或Swift语言来编写代码。假如你用过OpenGL[最早的版本][opengl1]，那时还没有shader，只能苦逼的使用各种底层受限制的API开发。而Scene Kit就好了很多，对于大多数需求（甚至像动态阴影和[景深][dof]这种高级特性），使用它提供的上层API来配置，就已经足够了。

不仅如此，Scene Kit还允许你直接调用底层API，或自己写shader进行手动渲染([GLSL][glsl])。

## Nodes（节点）

不仅是光照、模型、材质、摄像机这几个具体的对象，Scene Kit使用节点[^name]以树状结构来组织内容，每个节点都存储了相对其父节点的位移、旋转角度、缩放等信息，父节点也是如此，一直向上，直到根节点。假如要给一个节点确定一个位置，就必须将它挂载到节点树中的某个节点上，可以使用下面的几个操作方法：

[^name]: 在3D图形学中，像这样的树状节点结构一般被称做 _scene graph_ ，这也是Scene Kit名称由来的一种解释

- `addChildNode(_:)` 
- `insertChildNode(_: atIndex:)` 
- `removeFromParentNode()`  

这些方法与iOS和OS X中管理view和layer层级方法如出一辙。

## 几何模型对象

Scene Kit comes with built-in geometry objects for simple shapes like boxes, spheres, planes, and cones, but for games, you'll mostly be loading 3D models from a file. You can import (and export) [COLLADA files][collada] by referencing a file by name:

Scene Kit内建了几种简单的几何模型，如盒子、球体、平面、圆锥体等，但对于游戏来说，一般都会从文件中加载3D模型。你可以通过制定文件名来导入（或导出）[COLLADA][collada]格式的模型文件： 

    let chessPieces = SCNScene(named: "chess pieces") // SCNScene?


如果一个从文件里加载的场景可以全部显示时，将其设置成SCNView的scene就好了；但如果加载的场景文件中包含了多个对象，只有一部分对象要显示在屏幕上时，就可以通过名字找到这个对象，再手动加载到view上：

	if let knight = chessPieces.rootNode.childNodeWithName("Knight", recursively: true) {
	    sceneView.scene?.rootNode.addChildNode(knight)
	}

这是一个对导入文件原始节点的引用，其中包含了任一和每一个子节点，也包括了模型对象（包括其材质），光照，以及绑定在这些节点上的摄像机。只要传入的名字一样，不论调用多少次，返回的都是对同一个对象的引用。

![Node > Geometry > Material > Textures](http://img.objccn.io/issue-18/textures.png)

若需要在场景中拥有一个节点的多个拷贝，如在一个国际象棋棋盘上显示两个马，你可以对马这个节点进行`copy`或`clone`（递归的copy）。这将会拷贝一份节点的引用，但两份引用所指向的材质对象和模型对象仍然是原来那个。所以，想要单独改变副本材质的话，需要再copy一份模型对象，并对这个新的模型对象设置新材质。copy一个模型对象的速度仍然很快，开销也不高，因为副本引用的顶点数据还是同一份。

带有骨骼动画的模型对象也会拥有一个皮肤对象，它提供了对骨骼中各个节点的访问接口，以及管理骨骼和模型间连接的功能。每个单独的骨骼都可以被移动和旋转，而复杂的动画需要同时对多块骨骼进行操作，如一个角色走路的动画，很可能就是从文件读取并加到对象上的。（而不是用代码一根骨头一根骨头的写）

## 光照

Scene Kit中完全都是动态光照，使用起来一般会很简单，但也意味着与完整的游戏引擎相比，光照这块进步并不明显。Scene Kit提供四种类型的光照：环境光、定向光源、点光源和聚光灯。

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

## 动画

Scene Kit的对象中绝大多数属性都是可以进行动画的，就像Cocoa（或Cocoa Touch）框架一样，你可以创建一个`CAAnimation`对象，并指定一个key path（甚至可以`"position.x"`），然后向一个对象施加这个动画。同样的，你可以在`SCNTransaction`的"begin"和"commit"调用间去改变值，和刚才的CAAnimation非常相似：

	let move = CABasicAnimation(keyPath: "position.x")
	move.byValue  = 10
	move.duration = 1.0
	knight.addAnimation(move, forKey: "slide right")

Scene Kit也提供了像Sprite Kit那样的action形式的动画API，你可以创建串行的动画组，也支持自定义action来协同使用。与Core Animation不同的是，这些action作为游戏循环的一部分执行，在每一帧都更新模型对象的值，而不只是更新表现层的节点。

假如你之前用过Sprite Kit，会发现Scene Kit除了变成了3D之外，没有太多陌生的东西。目前，在iOS8（首次支持Scene Kit）和OS X 10.10下，Scene Kit和Sprite Kit可以协同工作：对Sprite Kit来说，3D模型可以与2D精灵混合使用；对Scene Kit来说，Sprite Kit中的场景和纹理可以作为Scene Kit的纹理贴图，而且Sprite Kit的场景可以作为Scene Kit场景的蒙层[^twoScenes]。（如3D游戏中的2D菜单面板，译者注）

[^twoScenes]: 两套非常像的API和概念（像场景啊，节点啊，约束啊两边都有）让人容易混淆。

# 开始用Scene Kit写游戏 

不仅是动作和纹理，Scene Kit和Sprite Kit还有很多相同之处。当开始写游戏的时候，Scene Kit和它2D版本的小伙伴非常相似，它们的游戏循环步骤完全一致，使用下面几个代理回调：

1. 更新场景
2. 应用动画/动作
3. 模拟物理效果
4. 应用约束
5. 渲染

![Game Loop](http://img.objccn.io/issue-18/gameloop.png)

这些回调在每帧被调用，并用来执行游戏相关的逻辑，如用户输入，AI（人工智能）和游戏脚本。

## 处理用户输入

Scene Kit与普通Cocoa或Cocoa Touch应用使用一样的机制来处理用户输入，如键盘事件、鼠标事件、触摸事件和手势识别，而主要区别在于Scene Kit中只有一个视图，场景视图（scene view）。像键盘事件或如捏取、滑动、旋转的手势，只要知道事件的发生就好了，但像鼠标点击，或触碰、拖动手势等就需要知道具体的事件信息了。

这些情况下，scene view可以使用`-hitTest(_: options:)`来做点击测试。与通常的视图只返回被点击的子view或子layer不同，Scene Kit返回一个数组，里面存有每个相交的模型对象以及从摄像机投向这个测试点的射线。每个hit test的结果包含被击中模型的节点对象，也包含了交点的详细信息（交点坐标、交点表面法线，交点的纹理坐标）。多数情况下，知道第一个被击中的节点就足够了： 

	if let firstHit = sceneView.hitTest(tapLocation, options: nil)?.first as? SCNHitTestResult 	{
	    let hitNode = firstHit.node
	    // do something with the node that was hit...
	}

# 扩展默认渲染流程

光照和材质的配置方法很易用，但有局限性。假如你有写好的OpenGL着色器（shader），可以用于完全自定制的进行材质渲染；如果你只想修改下默认的渲染，Scene Kit暴露了4个入口用于插入shader代码（GLSL）来改变默认渲染。Scene Kit在不同入口点分别提供了对旋转矩阵、模型数据、样本贴图及渲染后输出的色值的访问。

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

着色修改器（Shader modifier）既可以绑定在模型对象上，也可以绑定在它的材质对象上。这两个类都完全支持key-value coding（KVC），你可以指定任意key进行赋值。在shader中声明的"twistFactor" uniform变量使得Scene Kit在这个值改变时自动重新绑定uniform，这使得你也可以用KVC来实现：

	torus.setValue(5.0, forKey: "twistFactor")

使用这个key path的`CAAnimation`也ok：

	let twist = CABasicAnimation(keyPath: "twistFactor")
	twist.fromValue = 5
	twist.toValue   = 0
	twist.duration  = 2.0
	
	torus.addAnimation(twist, forKey: "Twist the torus")

![Animated twisting torus](http://img.objccn.io/issue-18/twist.gif)

## 延时着色

即使在纯OpenGL环境下，有些图像效果也无法通过一次渲染pass完成，我们可以将不同shader进行序列操作，以达到后续处理的目的，称为[延时着色][deferred]。Scene Kit使用[SCNTechnique类][technique]来表示这种技术。它使用字典来创建，字典中定义了绘图步骤、输入输出、shader文件、符号等等。

第一个渲染pass永远是Scene Kit的默认渲染，它输出场景的颜色和景深。如果你不想这时计算色值，可以将材质设置成"恒定"的光照模型，或者将场景里所有光照都设置成环境光。

比如，从Scene Kit渲染流程的第一个pass获取景深，第二个获取法线，第三个对其执行边界检测，你即可以沿轮廓也可以沿边缘画粗线：

![Bishop with strong contours](http://img.objccn.io/issue-18/bishop.png)

---

**延伸阅读**

如果你想了解更多使用Scene Kit做游戏的知识的话，我推荐今年的WWDC中得["Building a Game with Scene Kit" video][wwdc game]，并看看[Bananas sample code][bananas].

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