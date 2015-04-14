*译者注：原文中大量引用出自 objc.io 的英文文章，为了方便阅读，本文已经将链接改成 objccn.io 的文章，如需查看英文原本，请点击该译文最下面的 `原文` 按钮。*

---

在这篇文章中，我们将研究 Core Image 对视频播放的影响。我们来看两个例子：首先，我们把这个影响作用于相机拍摄的照片。其次，我们再将这个影响作用于拍摄好的视频文件。它也可以做到离线渲染，它会把渲染结果返回给视频，而不是直接显示在屏幕上。两个例子的完整源代码，请点击 [这里](https://github.com/objcio/core-image-video)。

## 快速回顾

当涉及到处理视频的时候，性能就会变得非常重要。而且重要的是了解黑箱下的原理 —— 也就是 Core Image 如何工作 —— 如何提供足够的性能。在 GPU 上面做尽可能多的工作非常有必要，并且最大限度的减少 GPU 和 CPU 之间的数据传送。之后的例子中，我们将看看这个细节。

想对 Core Image 有个初步认识的话，可以读读 Warren 的这篇文章 [Core Image 介绍](http://objccn.io/issue-21-6/)。我们将使用 [Swift 的函数式 API](http://objccn.io/issue-16-4/) 中介绍的基于 CIFilter 的 API 封装。想要了解更多关于 AVFoundation，看看本 issue 中的 [Adriaan 的文章](http://objccn.io/issue-23-1/)，还有 issue #21 中的 [iOS 上的相机捕捉](http://objccn.io/issue-21-3/)。


---

[话题 #23 下的更多文章](http://www.objccn.io/issue-23)

原文 [Core Image and Video](http://www.objc.io/issue-23/core-image-video.html)