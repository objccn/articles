
Our world gets noisier every day. This is the case for all modalities, and not just sound. Alerts and cues blink, beep, jingle, and vibrate from an ever-expanding array of sources. If there is a “war” for our attention, the only guarantee is that there will be no winners. Consider over-compressed and dynamically limited music where “everything is as loud as everything else.” This can be an impressive and even enjoyable experience for a limited amount of time. Over a longer period, however, the listener is left fatigued. If we create a product where modalities are unnecessarily stacked, e.g. you are looking at it and it blinks and it beeps and it vibrates, we will get the same effect: overloaded perceptual bandwidth, fatigue, and frustration with the product.

我们的世界每天都会产生很多噪音。这是所有（交互）形式都存在的问题，并非只针对声音。各个源头组成了一个不断扩大的阵列，输出着警报和提示闪烁、蜂鸣声、铃声和振动。如果把争夺我们的注意力当做一场“战争”，唯一能确认的就是没有赢家。考虑到过度压缩，动态限制的音乐，还在标榜着“还原声响”。如果时间有所限制，这大概会是一个令人印象深刻且倍感愉悦的体验。可随着时间跨度拉长，留给听者的就只剩下疲劳。如果我们创造的产品堆叠着不必要的交互形式，例如，你看到一个同时闪烁、蜂鸣且振动的东西，我们的感觉应该差不多：这是一款令人感知带宽超载，疲劳和沮丧的产品。

We can do better. Let's reduce the collective load on our perceptual bandwidth. How? By starting with a careful integration of sound with the other aspects of interaction design. Use it where it's needed, and even then, with respect for the idea that a given sound or alert comprising sound and some visual or haptic element might be experienced by someone many thousands of times or more during his or her exposure to our product. 

我们本可以做的更好，至少给感知带宽减一些负担。怎么做呢？走心一些，将音效与交互设计的其它方面结合在一起，我们从这里开始就可以。记得只在必要的时候使用音效交互，每一个给定的声音或警报，包括一些视觉或触觉元素，在用户接触到我们的产品后，都有可能体验成千上万次，怀有谨慎和敬畏的心情，从来都是更好的选择。

Sound design is part of the interaction design process, and not something to be tacked on at the end. Experiment early and often, or in this case: play, fail, iterate.

音效设计是交互设计过程的一部分，别等到设计结束后再去追加。试验早一点、多一点，直到进入这样的状态：播放，失败，迭代。

Here are five guidelines and associated concepts that help me design and integrate sound into products — digital, physical, or otherwise. They can be used however you like: as a checklist, manifesto, guideline, etc.  

这里有五个指导原则和相关概念，帮我设计音效并整合到产品中 - 数字的，物理的，或其它形式的产品都有。忽略个人喜好的话，你可以将它们作为一个清单，宣言，准则等等。

### Sound design for products and interaction shall:

###产品的音效设计与互动：

### 1. Not annoy the person using it.

### 1. 不要打扰用户

This should be obvious, but it is truly a wicked problem — what is annoying to one person might be just right for someone else. There are many ways to solve this problem! To start, create sounds that play at appropriate times and volumes and are mindful of people’s needs. Above all else: when in doubt, leave it out. Some of the best sound design is NO sound design. Look for opportunities to create silence and reflection. 

这本应该是显而易见的，但它确实是一个顽劣的问题 - 打扰到某人的设计对其他人来说其实刚刚好。有很多方法可以解决这个问题。首先，在合适的时间和音量去播放人们需要的音效。最重要的是：被质疑时，别管它。一些最好的设计是无声设计。寻找机会，创造沉默和更优的表现方式。

### 2. Help a person do what he or she wants to do or let him or her know that something has happened.

### 2. 帮助一个人做他/她想做的事，或让他/她知道有些事情已经发生

“If I touch the interface and don’t feel or hear anything change, how will I know I have succeeded in doing what I wanted to do?” Sound, of course, fills this gap. That said, we should take care to make interactive sound as relevant, accurate, and non-intrusive as possible. Take the time to test, then tune the synchronization of audio and moving elements. When that isn’t possible, deemphasize the correlation. Unless sound *has* to be there, leave it out.

“如果我触摸界面，却没有感知或听到任何变化，我将如何知道我已经成功地做​​了我想做的事？”声音可以填补这一空白。这就是说，我们要花心思使音效的交互更为契合、精准且不具有侵入性。花时间来测试，调整音频和移动元素之间的协调性。如果做不到，就弱化它们的联系。除非声音**必须**出现，不然可以考虑放弃它。

The graphic below is a mental model that might help in implementing this idea.

下图是一个心智模型，可能有助于你去实现所想。

The user experience of a given interaction can be seen as the sum of the physical, graphical, and audio interfaces over time. The ratio of the different modalities changes over time according to context and interaction flow (see graphic). There are cases such as targeted interactions, e.g. looking directly at the GUI where the AUI (audio user interface) part of the venn diagram might be very small or nonexistent, whereas for an “eyes-free” interaction such as an incoming phone call, the AUI would be much more important. These rations change over time depending on the use case or cases, and in the end provide the basis for a user’s experience.

一个给定的交互的用户体验可以被看作是一段时间内物理、图形与音频的接口叠加。不同的形式占比随着时间的推移，根据上下文和交互流程（见图表）变化。有时候，有些交互场景是有针对性的，例如直接看着 GUI 的场景，AUI（Audio User Interface）在维恩图中的占比可能非常小甚至不存在，而对于“无视觉约束”的交互，比如拨入的电话，AUI 就显得更为重要。这些配比会根据使用情况变化，并且在最后提供用户体验的依据。

![image1][image1]

### 3. Reproduce well on the target.

### 3. 终端的复现质量

Many technical problems have non-technical origins. Getting UI sound and related audio to sound good on hardware is no exception. Don’t pick your soundset by listening to it through a nice stereo system or, conversely, through the speakers of a Dell laptop in an echoey conference room. Decisions concerning selection of sounds and their relative merits within a design system should be made on the target hardware, i.e. test it on the device(s) you are developing for. You might say: “But sound coming out of a handheld device (medical device, automobile, etc.) sucks!” That is exactly why the decision about what goes into a build should be made on target hardware. 

很多技术问题都不是因为技术。让 UI 的声音和相关音频在硬件上好听些也是类似的道理。不要从一个音质优秀的立体声系统中去挑选你的音效，而应该在一间有回声的会议室里，用戴尔笔记本的扬声器去播放。在一个设计系统内，关于判断声音及其相对优劣的决定应当基于目标硬件，也就是说，应该在你正在为之进行开发的设备上进行测试。你可能会说：“可是声音就像从一个手持设备（医疗设备、汽车等）传出来的一样！”不过这也正是为什么，将一些选择纳入项目的决定应该在目标硬件上进行。

Restated: confirm stakeholder buy-in and integrate sound into the beginning of the design process. Communicate the risk(s) of bad, inappropriate, or poorly implemented sound design before all the project’s capacity is spoken for.

重申：确认利益相关者的介入，在设计过程开始时就要与音效结合在一起。沟通冒险的不利与不妥之处，或者在项目被确定下来之前做一些音效设计的简易实现。

### 4. Reflect the product tone of voice in a unique way.

Some things have a face, others a voice, and a limited few have an aura. Does your product have an aura?

### 4. 产品的声音要独一无二

有些东西有表象，有些会发声，而有限的几个则有光环。你的产品有光环么？

### 5. Be future-proof.

### 5. 面向未来

To hit a moving target, you have to aim ahead of it. 

想击中一个移动的目标，你必须先瞄准它。

Less-than-optimal audio hardware, such as tiny little speakers, underpowered amplifiers, extremely band-limited frequency response, etc. has been the hobgoblin of sound design for many products for a long time — especially mobile devices. There were mobile devices that had good sound hardware before the iPhone, but none that had the same impact. After the iPhone came out, user expectations went up. They are continuing to go up, and this should be reflected in whatever sound design you incorporate into your product. Design for the “late now” and the future. Furthermore, interfaces are getting smaller, to the point of disappearing altogether, e.g. wearables (see graphic). Sound design just got some new pants.

一些性能较差的音频硬件，如微小的扬声器，动力不足的放大器，极带限频率响应等，在很长一段时间里都是许多产品音效设计的噩梦 - 尤其是移动设备。在 iPhone 之前，移动设备中也不乏一些不错的音效硬件，但没有一样有同样的影响力。在 iPhone 现世后，用户的期望变得更高。他们的期望会继续上升，这应该反映在你纳入产品的每一个音效设计上，设计需要面向“稍后”和未来。此外，接口的尺寸越来越小，到完全消失的地步，就像可穿戴品一样（见图表）。音效设计刚好得到了一些新裤子。

![image2][image2]


### Is That All? 

### 这就是全部？

No. There is more, but that is a start. These guidelines are no guarantee for successful integration of sound into products, but they will definitely point the development and design process in the right direction.

不。还有更多，这只不过是一个开始。这些准则并不能保证声音转化为产品的成功整合，但它们肯定会指向正确的发展方向和设计过程。

### In Conclusion

### 结论

 * The proper mix of beautiful sound and well-timed silence will make for happier customers.

 * 优美的声音和适时的沉默适当搭配，更有助于提升客户满意度。

 * Sound design is part of interaction design — not something added “on top.”

 * 音效设计是交互设计的一部分，而不是补充。

 * Take the time to test and tune. When that isn’t possible, deemphasize the correlation.

 * 花时间来测试和调整。如果时间不允许，弱化它们的联系。

 * When in doubt, leave it out.

 * 如果被质疑，别管它。

 * Confirm stakeholder buy-in and integrate sound into the beginning of the design process.

 * 确认利益相关者的介入，在设计之初就与音效相结合。

 * Don’t let app store reviews rule your life! You will never make everyone happy all the time, especially with sound. 

 * 不要让 App Store 的评论操纵你的生活！你永远不会让所有人都满意的时候，尤其是声音。

 * Play. Fail. Iterate.

 * 播放、失败、迭代。

[image1]:http://img.objccn.io/issue-24/sum-of-interfaces.svg
[image2]:http://img.objccn.io/issue-24/size-vs-auditive.svg
