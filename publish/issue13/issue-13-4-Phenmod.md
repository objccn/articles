这篇文章跟我以往的文章有点不一样。它主要是一些思想与模式的汇集，而不是一篇指南。下面我所写的模式几乎全都来之不易，都是我犯了错之后才学到的。我并不认为自己是子类方面的权威，但我确实想把我学到的一些东西分享出来。别把本文当做权威指南，它只是一些例子的汇集。

在被问到 OOP（面向对象编程）的时候，Alan Kay（OOP 的发明人）写到：它跟类无关，但跟消息有关。[^1](http://c2.com/cgi/wiki?AlanKayOnMessaging)然而，很多人的关注点仍然还在类层次上。在本文中，我们会看几个我们可能会把注意力放在创建复杂的类结构上的例子，并给出更有用的替代方案。根据经验，这样会让代码更简单，更易维护。关于这个话题，在 [Clean Code](http://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)（中文版：[代码整洁之道](http://www.amazon.cn/%E4%BB%A3%E7%A0%81%E6%95%B4%E6%B4%81%E4%B9%8B%E9%81%93-%E9%A9%AC%E4%B8%81/dp/B0031M9GHC/ref=pd_bxgy_b_img_y)）和 [Code Complete](http://www.amazon.com/Code-Complete-Practical-Handbook-Construction/dp/0735619670)（中文版：[代码大全](http://www.amazon.cn/%E4%BB%A3%E7%A0%81%E5%A4%A7%E5%85%A8-%E5%8F%B2%E8%92%82%E5%A4%AB%E2%80%A2%E8%BF%88%E5%85%8B%E5%BA%B7%E5%A5%88%E5%B0%94/dp/B0061XKRXA/ref=pd_bxgy_b_img_z)）中已经有大量讨论。推荐你阅读这两本书。

## 何时用子类

首先，我们讨论几种使用子类比较合适的场景。如果你要写一个自定义布局的 `UITableViewCell` ，那就创建一个子类。这同样适用于几乎每个视图。一旦你开始布局，把这块代码放入子类就更合理一些，不光代码得到了更好的封装，你也能得到一个可在工程之间重用的组件。

假设你的代码是针对多平台多版本的，并且你需要针对每个平台每个版本写一些代码。这时候更合理的做法可能是创建一个 `OBJDevice` 类，让一些子类如 `OBJIPhoneDevice` 和 `OBJIPadDevice` ，甚至更深层的子类如 `OBJIPhone5Device` 来继承，并让这些子类重写特定的方法。例如，你的 OBJDevice 类可能包含了函数 `applyRoundedCornersToView:withRadius` ，它有一个默认的实现，但是也能被特定的子类重写。

另一个子类化可能很有用的场景是模型对象（model object）。绝大多数情况下，我的模型对象继承自一个实现了 `isEqual:` 、 `hash` 、 `copyWithZone:` 和 `description` 等方法的类。这些方法只被实现一次，并且迭代循环遍历所有属性，所以极不容易出错。（如果你也想找一个这样的基类，可以考虑使用 [Mantle](https://github.com/mantle/mantle) ，它就是这么做的，并且做得更多。）

## 何时不使用子类

在以往工作过的很多工程中，我见到过很多继承层次很深的子类。当我也这么干的时候，总会感到内疚。除非继承的层次非常浅，否则你会很快发现它的局限性。[^2](http://c2.com/cgi/wiki?LimitsOfHierarchies)

幸运的是，如果你发现自己正在使用深层次的继承，还有很多替代方案可选。在下面的章节中，我们会逐个进行更详细地描述。如果你的子类只是使用相同的接口，协议会是个非常好的替代方案。如果你知道某个对象需要大量的修改，你可能会使用代理来动态改变和配置它。当你想给已有对象增加一些简单功能时，类别可能是个选择。当你有一堆重写了相同方法的子类时，你可以使用配置对象（configuration object）来代替。最后，当你想重用某些功能时，组合多个对象而不是扩展它们可能会更好。

## 替代方案

### 替代方案：协议（Protocols）

很多时候，使用子类的原因是你想保证某个对象可以响应某些消息。假设在 app 里你有一个播放器对象，它可以播放视频。现在你想添加对 YouTube 的支持，使用相同的接口，但是具体实现不同。你可以使像这样用子类来实现：

```
@class Player : NSObject

- (void)play;
- (void)pause;

@end


@class YouTubePlayer : Player

@end
```

事实上可能这两个类并没有太多共用的代码，它们只不过具有相同的接口。如果这样的话，使用协议可能会是更好的方案。可以这样用协议来写你的代码：

```
@protocol VideoPlayer <NSObject>

- (void)play;
- (void)pause;

@end


@class Player : NSObject <VideoPlayer>

@end


@class YouTubePlayer : NSObject <VideoPlayer>

@end
```

这样，`YouTubePlayer` 类就不必知道 `Player` 类的内部实现了。

### 替代方案：代理（Delegation）

再一次假设你有一个像上面例子中的 `Player` 类。现在，你想在开始播放的时候在某个地方执行一个自定义的函数。这么做相对容易一些：创建一个自定义的子类，重写 `play` 方法，调用 `[super play ]`，然后开始做你自定义的工作。这么做是一种方法。另外一种方法是，改动你的 `Player` 对象，然后给它设置一个代理。如下：

```
@class Player;

@protocol PlayerDelegate

- (void)playerDidStartPlaying:(Player *)player;

@end


@class Player : NSObject

@property (nonatomic,weak) id<PlayerDelegate> delegate;

- (void)play;
- (void)pause;

@end
```

现在，在播放器的 `play` 方法里，就可以给代理发送 `playerDidStartPlaying: ` 消息了。这个 `Player` 类的任何使用者都可以仅仅实现这个代理协议，而不用继承该该类， `Player` 类也能够保持通用性。这是个强大有效的技术，苹果在自己的框架里大量地使用它。你想想像 `UITextField` 这样的类，还有 `NSLayoutManager`。有时候你还会想把几个不同的方法打包分组到几个单独的协议里，比如 `UITableView` —— 它不仅有一个代理（delegate），还有一个数据源（dataSource）。

### 替代方案：类别（Categories）

有时候，你可能会想给一个对象增加一点点额外的功能。比如你想给 `NSArray` 增加一个方法 `arrayByRemovingFirstObject`。不用子类，你可以把这个函数放到一个类别里。像这样：

```
@interface NSArray (OBJExtras)

- (void)obj_arrayByRemovingFirstObject;

@end
```

在用类别扩展一个不是你自己的类的时候，在方法前添加前缀是个比较好的习惯做法。如果不这么做，有可能别人也用类别对此类添加了相同名字的函数。那时候程序的行为可能跟你想要的并不一样，未预期的事情可能会发生。

使用类别还有另外一个风险，那就是，到最后你可能会使用一大堆的类别，连你自己都会失去对代码全局的认识。假如那样的话，创建自定义的类可能更简单一些。

### 替代方案：配置对象（Configuration Objects）

在我经常会犯的错误中（现在很快就能发现了），其中有一条是：使用一个含有几个抽象方法的类并让很多子类来重写某个方法。例如，在一个幻灯片应用里，你有一个主题类 `Theme` ，它有几个属性，比如 `backgroundColor` 和 `font` ，还有一些在一张幻灯片上如何布局的逻辑函数。

然后，对每种主题，你都创建一个 `Theme` 的子类，重写某个函数（例如 `setup` ）并配置其属性。直接使用父类对此做不了什么事。在这种情况下，你可以使用配置对象来让代码更简单些。你可以把共有的逻辑（比如幻灯片布局）放在 `Theme` 类中，把属性的配置放到较简单的对象中，这些对象中只含有这些属性。

例如，类 `ThemeConfiguration` 具有 `backgroundColor` 和 `font` 属性，而类 `Theme` 在其初始化函数中获取一个配置类 `ThemeConfiguration` 的值。

### 替代方案：组合

组合是代替子类化的最强大有效的方案。如果你想重用已有代码而不想共享同样的接口，组合就是你的首选武器。例如，假设你要设计一个缓存类：

```
@interface OBJCache : NSObject

- (void)cacheValue:(id)value forKey:(NSString *)key;
- (void)removeCachedValueForKey:(NSString *)key;

@end
```

简单点的做法是直接继承 `NSDictionary`，通过调用字典的函数来实现上面的两个方法。

```
@interface OBJCache : NSDictionary
```

但是这么做有几个弊端。它本来是应该被详细实现的，但只是通过字典来实现。现在，在任何需要一个 `NSDictionary` 参数的时候，你可以直接提供一个 `OBJCache` 值。但如果你想把它转为其它完全不同的东西（例如你自己的库），你就可能需要重构很多代码了。

更好的方式是，将这个字典存在一个私有属性（或者实例变量）中，对外仅仅暴露这两个 `cache` 方法。现在，当你有了更深入想法的时候，你可以在灵活地修改其实现，而该类的使用者们不用进行重构。

---

 

原文 [Subclassing](http://www.objc.io/issue-13/subclassing.html)