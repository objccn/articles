[Source](http://www.objc.io/issue-3/moving-pixels-onto-the-screen.html "Permalink to Getting Pixels onto the Screen - Views - objc.io issue #3 ")

# Getting Pixels onto the Screen - Views - objc.io issue #3 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# Getting Pixels onto the Screen

[Issue #3 Views][4], August 2013

By [Daniel Eggert][5]

How does a pixel get onto the screen? There are many ways to get something onto the display and they involve many different frameworks and many different combinations of functions and methods. Here we’ll walk through some of the things that happen behind the scenes. We hope this will help you understand which API works best when you need to determine when and how to debug and fix performance problems. We’ll focus on iOS, however most of what is discussed will apply to OS X as well.

## Graphics Stack

There’s a lot going on under the hood when pixels have to get onto the screen. But once they’re on the screen, each pixel consists of three color components: red, green, and blue. Three individual color cells light up with a particular intensity to give the impression of a single pixel with a specific color. On your iPhone 5, the [liquid-crystal display][6] has 1,136×640 = 727,040 pixels and hence 2,181,120 color cells. On a 15” MacBook Pro with Retina Display this number is just above 15.5 million. The entire graphics stack works together to make sure each one lights up with the correct intensity. And when you scroll in full screen, all those million intensities have to update 60 times per second. That’s a lot of work.

### The Software Components

In a simplified view, the software stack looks somewhat like this:

![Software Stack][7]

Just above the display sits the GPU, the _graphics processing unit_. The GPU is a highly concurrent processing unit, which is tailored specifically for parallel computation of graphics. That’s how it’s possible to update all those pixels and push the result onto the display. Its parallel nature also allows it to do compositing of textures onto each other very efficiently. We’ll talk about [compositing][8] in more detail in a bit. The key point is that the GPU is extremely specialized and therefore it is efficient at some kinds of work, i.e. it’s very fast and uses less power than the CPU for this work. The ‘normal’ CPU has a very general purpose; it can do many different things, but compositing, for example, would be way slower on the CPU.

The GPU driver is the piece of code that talks directly to the GPU. Different GPUs are different beasts, and the driver makes them appear more uniform to the next layer, which is typically OpenGL / OpenGL ES.

OpenGL ([Open Graphics Library][9]) is an API for rendering 2D and 3D graphics. Since the GPU is a very specialized piece of hardware, OpenGL works very closely with the GPU to facilitate the GPU’s capabilities and to achieve hardware-accelerated rendering. To many, OpenGL may seem very low-level, but when it was first released in 1992 (more than twenty years ago) it was the first major standardized way to talk to graphics hardware (the GPU), and hence a major leap forward since programmers no longer had to rewrite their apps for each GPU.

Above OpenGL things split out a bit. On iOS nearly everything goes through Core Animation at this point, while on OS X, it’s not uncommon for Core Graphics to bypass Core Animation. For some specialized applications, particularly games, the app might talk directly to OpenGL / OpenGL ES. And things get even more confusing, because Core Animation uses Core Graphics for some of its rendering. Frameworks like AVFoundation, Core Image, and others access a mix of everything.

One thing to keep in mind, though, is this: The GPU is a very powerful piece of graphics hardware and it plays a central role in displaying your pixels. It is connected to the CPU. In hardware there’s some sort of [bus][10] between the two – and there are frameworks such as OpenGL, Core Animation, and Core Graphics that orchestrate the transfer of data between the GPU and the CPU. In order for your pixels to make it onto the screen, some processing will be done on the CPU. Then data will be transferred to the GPU, which, in turn, will also do processing, and finally your pixels show up on screen.

Each part of this “journey” has its own challenges, and there are tradeoffs to be made along the way.

### The Hardware Players

 

![Graphics Hardware][11]

A very simplified view of the challenges looks like this: The GPU has textures (bitmaps) that it composites together for each frame (i.e. 60 times a second). Each texture takes up VRAM (video RAM) and therefore there’s a limit to how many textures the GPU can hold onto. The GPU is super efficient at compositing, but certain compositing tasks are more complex than others, and there’s a limit to how much work the GPU can do in 16.7 ms (1/60 s).

The next challenge is getting your data to the GPU. In order for the GPU to access data, it needs to be moved from RAM into VRAM. This is referred to as _uploading to the GPU_. This may seem trivial, but for large textures this can be very time-consuming.

Finally, the CPU runs your program. You may be telling the CPU to load a PNG from your bundle and decompress it. All that happens on the CPU. When you then want to display that decompressed image, it somehow needs to get uploaded to the GPU. Something as mundane as displaying text is a tremendously complex task for the CPU that facilitates a tight integration between the Core Text and Core Graphics frameworks to generate a bitmap from the text. Once ready, it gets uploaded to the GPU as a texture, ready to be displayed. When you scroll or otherwise move that text on screen, however, the very same texture can be reused, and the CPU will simply tell the GPU what the new position is, so the GPU can reuse the existing texture. The CPU doesn’t have to re-render the text, and the bitmap doesn’t have to be re-uploaded.

This illustrates some of the complexities involved. With this overview out of the way, we’ll dive into some of the technologies involved.

## Compositing

Compositing in the graphics world is a term that describes how different bitmaps are put together to create the final image you see on the screen. It is, in many ways, so obvious that it’s easy to forget the complexity and computations involved.

Let’s ignore some of the more esoteric cases and assume that everything on the screen is a texture. A texture is a rectangular area of RGBA values, i.e. for each pixel we have red, green, and blue values, and an alpha value. In the Core Animation world this is basically what a `CALayer` is.

In this slightly simplified setup, each layer is a texture, and all these textures are in some way stacked on top of each other. For each pixel on screen, the GPU needs to to figure out how to blend / mix these textures to get the RGB value of that pixel. That’s what compositing is about.

If all we have is a single texture that is the size of the screen and aligned with the screen pixels, each pixel on the screen corresponds to a single pixel in that texture. The texture’s pixels end up being the screen’s pixels.

If we have a second texture that’s placed on top of the first texture, the GPU will then have to composite this texture onto the first. There are different blend modes, but if we assume that both textures are pixel-aligned and we’re using the normal blend mode, the resulting color is calculated with this formula for each pixel:


    R = S %2B D * (1 - Sa)

The resulting color is the source color (top texture) plus the destination color (lower texture) times one minus the source color’s alpha. All colors in this formula are assumed to be pre-multiplied with their alpha.

Obviously there’s quite a bit going on here. Let’s for a second assume that all textures are fully opaque, i.e. alpha = 1. If the destination (lower) texture is blue (RGB = 0, 0, 1), and the source (top) texture is red (RGB = 1, 0, 0), and because `Sa` is `1`, the result is


    R = S

and the result is the source’s red color. That’s what you’d expect.

If the source (top) layer was 50% transparent, i.e. alpha = 0.5, the RGB values for S would be (0.5, 0, 0) since the alpha component is pre-multiplied into the RGB-values. The formula would then look like this:


                           0.5   0               0.5
    R = S %2B D * (1 - Sa) = 0   %2B 0 * (1 - 0.5) = 0
                           0     1               0.5

We’d end up getting an RGB value of (0.5, 0, 0.5) which is a saturated ‘plum’ or purple color. That’s hopefully what you’d intuitively expect when mixing a transparent red onto a blue background.

Remember that what we just did is compositing one single pixel of a texture into another pixel from another texture. The GPU needs to do this for all pixels where the two textures overlay. And as you know, most apps have a multitude of layers and hence textures that need to be composited together. This keeps the GPU busy, even though it’s a piece of hardware that’s highly optimized to do things like this.

### Opaque vs. Transparent

When the source texture is fully opaque, the resulting pixels are identical to the source texture. This could save the GPU a lot of work, since it can simply copy the source texture in place of blending all pixel values. But there’s no way for the GPU to tell if all pixels in a texture are opaque or not. Only you as a programmer know what you’re putting into your `CALayer`. And that’s why `CALayer` has a property called `opaque`. If this is `YES`, then the GPU will not do any blending and simply copy from this layer, disregarding anything that’s below it. It saves the GPU quite a bit work. This is what the Instruments option **color blended layers** is all about (which is also available in the Simulator’s Debug menu). It allows you to see which layers (textures) are marked as non-opaque, i.e. for which layers the GPU is doing blending. Compositing opaque layers is cheaper because there’s less math involved.

So if you know your layer is opaque, be sure to set `opaque` to `YES`. If you’re loading an image that doesn’t have an alpha channel and displaying it in a `UIImageView` this will happen automatically. But note that there’s a big difference between an image without an alpha channel, and an image that has alpha at 100% everywhere. In the latter case, Core Animation has to assume that there might be pixels for which alpha is not 100%. In the Finder, you can use _Get Info_ and check the _More Info_ section. It’ll say if the image has an alpha channel or not.

### Pixel Alignment and Misalignment

So far we’ve looked at layers that have pixels that are perfectly aligned with the display. When everything is pixel-aligned we get the relatively simple math we’ve looked at so far. Whenever the GPU has to figure out what color a pixel on screen should be, it only needs to look at a single pixel in the layers that are above this screen pixel and composite those together. Or, if the top texture is opaque, the GPU can simply copy the pixel of that top texture.

A layer is pixel-aligned when all its pixels line up perfectly with the screen’s pixels. There are mainly two reasons why this may not be the case. The first one is scaling; when a texture is scaled up or down, the pixels of the texture won’t line up with the screen’s. Another reason is when the texture’s origin is not at a pixel boundary.

In both of these cases the GPU again has to do extra math. It has to blend together multiple pixels from the source texture to create a value that’s used for compositing. When everything is pixel-aligned, the GPU has less work to do.

Again, the Core Animation Instrument and the Simulator have an option called **color misaligned images** that will show you when this happens for your CALayer instances.

### Masks

A layer can have a mask associated with it. The mask is a bitmap of alpha values which are to be applied to the layer’s pixels before they’re composited onto the content below it. When you’re setting a layer’s corner radius, you’re effectively setting a mask on that layer. But it’s also possible to specify an arbitrary mask, e.g. have a mask that’s the shape of the letter _A_. Only the part of the layer’s content that’s part of that mask would be rendered then.

### Offscreen Rendering

Offscreen rendering can be triggered automatically by Core Animation or be forced by the application. Offscreen rendering composites / renders a part of the layer tree into a new buffer (which is offscreen, i.e. not on the screen), and then that buffer is rendered onto the screen.

You may want to force offscreen rendering when compositing is computationally expensive. It’s a way to cache composited texture / layers. If your render tree (all the textures and how they fit together) is complex, you can force offscreen rendering to cache those layers and then use that cache for compositing onto the screen.

If your app combines lots of layers and wants to animate them together, the GPU normally has to re-composite all of these layers onto what’s below them for each frame (1/60 s). When using offscreen rendering, the GPU first combines those layers into a bitmap cache based on a new texture and then uses that texture to draw onto the screen. Now when those layers move together, the GPU can re-use this bitmap cache and has to do less work. The caveat is that this only works if those layers don’t change. If they do, the GPU has to re-create the bitmap cache. You trigger this behavior by setting `shouldRasterize` to `YES`.

It’s a trade-off, though. For one, it may cause things to get slower. Creating the extra offscreen buffer is an additional step that the GPU has to perform, and particularly if it can never reuse this bitmap, it’s a wasted effort. If however, the bitmap can be reused, the GPU may be offloaded. You have to measure the GPU utilization and frame rate to see if it helps.

Offscreen rendering can also happen as a side effect. If you’re directly or indirectly applying a mask to a layer, Core Animation is forced to do offscreen rendering in order to apply that mask. This puts a burden on the GPU. Normally it would just be able to render directly onto the frame buffer (the screen).

Instruments’ Core Animation Tool has an option called **Color Offscreen-Rendered Yellow** that will color regions yellow that have been rendered with an offscreen buffer (this option is also available in the Simulator’s Debug menu). Be sure to also check **Color Hits Green and Misses Red**. Green is for whenever an offscreen buffer is reused, while red is for when it had to be re-created.

Generally, you want to avoid offscreen rendering, because it’s expensive. Compositing layers straight onto the frame buffer (onto the display) is way cheaper than first creating an offscreen buffer, rendering into that, and then rendering the result back into the frame buffer. There are two expensive context switches involved (switching the context to the offscreen buffer, then switching the context back to the frame buffer).

So when you see yellow after turning on **Color Offscreen-Rendered Yellow**, that should be a warning sign. But it isn’t necessarily bad. If Core Animation is able to reuse the result of the offscreen rendering, it may improve performance if Core Animation can reuse the buffer. It can reuse when the layers that were used for the offscreen buffer didn’t change.

Note also that there’s limited space for rasterized layers. Apple hinted that there’s roughly two times the screen size of space for rasterized layers / offscreen buffers.

And if the way you’re using layers causes an offscreen rendering pass, you’re probably better off trying to get rid of that offscreen rendering altogether. Using masks or setting a corner radius on a layer causes offscreen rendering, so does applying shadows.

As for masks, with corner radius (which is just a special mask), and `clipsToBounds` / `masksToBounds`, you may be able to simply create content that has masks already burned in, e.g. by using an image with the right mask already applied. As always, it’s a trade-off. If you want to apply a rectangular mask to a layer with its `contents` set, you can probably use `contentsRect` instead of the mask.

If you end up setting `shouldRasterize` to `YES`, remember to set the `rasterizationScale` to the `contentsScale`.

### More about Compositing

As always, Wikipedia has more background on the math of [alpha compositing][12]. We’ll dive a bit more into how red, green, blue, and alpha are represented in memory later on when talking about [pixels][13].

### OS X

If you’re working on OS X, you’ll find most of those debugging options in a separate app called “Quartz Debug,” and not inside Instruments. Quartz Debug is a part of the “Graphics Tools” which is a separate [download at the developer portal][14].

## Core Animation & OpenGL ES

As the name suggests, Core Animation lets you animate things on the screen. We will mostly skip talking about animations, though, and focus on drawing. The thing to note, however, is that Core Animation allows you to do extremely efficient rendering. And that’s why you can do animations at 60 frames per second when you’re using Core Animation.

Core Animation, at its core, is an abstraction on top of OpenGL ES. Simply put, it lets you use the power of OpenGL ES without having to deal with all of its complexities. When we talked about [compositing][8] above we were using the terms layer and texture interchangeably. They’re not the same thing, but quite analogous.

Core Animation layers can have sublayers, so what you end up with is a layer tree. The heavy lifting that Core Animation does is figuring out what layers need to be (re-)drawn, and which OpenGL ES calls need to be made to composite the layers onto the screen.

For example, Core Animation creates an OpenGL texture when you set a layer’s contents to a `CGImageRef`, making sure that the bitmap in that image gets uploaded to the corresponding texture, etc. Or if you override `-drawInContext`, Core Animation will allocate a texture and make sure that the Core Graphics calls you make will turn into that texture’s bitmap data. A layer’s properties and the `CALayer` subclasses affect how OpenGL rendering is performed, and many lower-level OpenGL ES behaviors are nicely encapsulated in easy-to-understand `CALayer` concepts.

Core Animation orchestrates CPU-based bitmap drawing through Core Graphics on one end with OpenGL ES on the other end. And because Core Animation sits at this crucial place in the rendering pipeline, how you use Core Animation can dramatically impact performance.

### CPU bound vs. GPU bound

There are many components at play when you’re displaying something on the screen. The two main hardware players are the CPU and the GPU. The P and U in their names stand for processing unit, and both of these will do processing when things have to be drawn on the screen. Both also have limited resources.

In order to achieve 60 frames per second, you have to make sure that neither the CPU nor the GPU are overloaded with work. In addition to that, even when you’re at 60 fps, you want to put as much of the work as possible onto the GPU. You want to CPU to be free to run your applications code instead of being busy drawing. And quite often, the GPU is more efficient than the CPU at rendering, which turns into a lower overall load and power consumption of the system.

Since drawing performance depends on both CPU and GPU, you need to figure out which one is limiting your drawing performance. If you’re using all GPU resources, i.e. the GPU is what’s limiting your performance, your drawing is said to be _GPU bound_. Likewise if you’re maxing out the CPU, you’re said to be _CPU bound_.

If you’re GPU bound, you need to offload the GPU (and perhaps do more of the work on the CPU). If you’re CPU bound, you need to offload the CPU.

To tell if you’re GPU bound, use the _OpenGL ES Driver_ instrument. Click on the little _i_ button, then _configure_, and make sure _Device Utilization %_ is checked. Now, when you run your app, you’ll see how loaded the GPU is. If this number is close to 100%, you’re trying to do much work on the GPU.

Being CPU bound is the more _traditional_ aspect of your app doing to much work. The _Time Profiler_ instrument helps you with that.

## Core Graphics / Quartz 2D

Quartz 2D is more commonly known by the name of the framework that contains it: Core Graphics.

Quartz 2D has more tricks up its sleeve than we’d possibly be able to cover here. We’re not going to talk about the huge part that’s related to PDF creating, rendering, parsing, or printing. Just note that printing and PDF creation is largely identical to drawing bitmaps on the screen, since it is all based on Quartz 2D.

Let’s just very briefly touch upon the main concepts of Quartz 2D. For details, make sure to check Apple’s [Quartz 2D Programming Guide][15].

Rest assured that Quartz 2D is very powerful when it comes to 2D drawing. There’s path-based drawing, anti-aliased rendering, transparency layers, and resolution- and device-independency, to name a few features. It can be quite daunting, more so because it’s a low-level and C-based API.

The main concepts are relatively simple, though. Both UIKit and AppKit wrap some Quartz 2D in simply to use API, and even the plain C API is accessible once you’ve gotten used to it. You end up with a drawing engine that can do most of what you’d be able to do in Photoshop and Illustrator. Apple [mentioned the stocks app on iOS][16] as an example of Quartz 2D usage, as the graph is a simple example of a graph that’s dynamically rendered in code using Quartz 2D.

When your app does bitmap drawing it will – in one way or another – be based on Quartz 2D. That is, the CPU part of your drawing will be performed by Quartz 2D. And although Quartz can do other things, we’ll be focusing on bitmap drawing here, i.e. drawing that results on a buffer (a piece of memory) that contains RGBA data.

Let’s say we want to draw an [Octagon][17]. We could do that using UIKit


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

This corresponds more or less to this Core Graphics code:


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

The question to ask is: Where is this drawing to? This is where the so-called `CGContext` comes into play. The `ctx` argument we were passing is in that context. And the context defines where we’re drawing to. If we’re implementing `CALayer`’s `-drawInContext:` we’re being passed a context. Drawing to that context will draw into the layer’s backing store (its buffer). But we can also create our own context, namely a bitmap-based context with e.g. `CGBitmapContextCreate()`. This function returns a context that we can then pass to the `CGContext` functions to draw into that context, etc.

Note how the `UIKit` version of the code doesn’t pass a context into the methods. That’s because when using `UIKit` or `AppKit` the context is implicit. `UIKit` maintains a stack of contexts and the UIKit methods always draw into the top context. You can use `UIGraphicsGetCurrentContext()` to get that context. You’d use `UIGraphicsPushContext()` and `UIGraphicsPopContext()` to push and pop context onto UIKit’s stack.

Most notably, UIKit has the convenience methods `UIGraphicsBeginImageContextWithOptions()` and `UIGraphicsEndImageContext()` to create a bitmap context analogous to `CGBitmapContextCreate()`. Mixing UIKit and Core Graphics calls is quite simple:


    UIGraphicsBeginImageContextWithOptions(CGSizeMake(45, 45), YES, 2);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, 16.72, 7.22);
    CGContextAddLineToPoint(ctx, 3.29, 20.83);
    ...
    CGContextStrokePath(ctx);
    UIGraphicsEndImageContext();

or the other way around:


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

There’s a huge amount of really cool stuff you can do with Core Graphics. For a good reason, the Apple documents call out its _unmatched output fidelity_. We can’t get into all the details, but: Core Graphics has a graphics model that (for historic reasons) is very close to how [Adobe Illustrator][18] and [Adobe Photoshop][19] work. And most of the tools’ concepts translate to Core Graphics. After all, its origins are in [NeXTSTEP][20], which used [Display PostScript][21].

### CGLayer

We originally indicated that `CGLayer` could be used to speed up repeated drawing of identical elements. As pointed out by [Dave Hayden][22], [word in the street][23] has it that this is no longer true.

## Pixels

Pixels on screen are composed of three color components: red, green, blue. Hence bitmap data is also sometimes referred to as RGB data. You may wonder how this data is organized in memory. But the fact is, there are many, many different ways RGB bitmap data can be represented in memory.

In a bit we’ll talk about compressed data, which is entirely different again. For now, let us look at RGB bitmap data, where we have a value for each color component: red, green, and blue. And quite often we’ll have a fourth component: alpha. We end up with four individual values for each and every pixel.

### Default Pixel Layouts

A very common format on iOS and OS X is what is known amongst friends as _32 bits-per-pixel (bpp), 8 bits-per-component (bpc), alpha premultiplied first_. In memory this looks like


      A   R   G   B   A   R   G   B   A   R   G   B
    | pixel 0       | pixel 1       | pixel 2
      0   1   2   3   4   5   6   7   8   9   10  11 ...

This format is often (ambiguously) referred to as ARGB. Each pixel uses four bytes (32 bpp). Each color component is one byte (8 bpc). Each pixel has an alpha value, which comes first (before the RGB values). And finally the red-green-blue values are _pre-multiplied_ with the alpha. Pre-multiplied means that the alpha value is baked into the red, green and blue component. If we have an orange color its RGB values at 8 bpc would be something like 240, 99 and 24 respectively. An orange pixel that’s fully opaque would have ARGB values of 255, 240, 99, 24 in memory with the above layout. If we had a pixel of the same color, but an alpha value of 33%, the pixel values would be 84, 80, 33, 8.

Another common format is _32 bpp, 8 bpc, alpha-none-skip-first_ which looks like this:


      x   R   G   B   x   R   G   B   x   R   G   B
    | pixel 0       | pixel 1       | pixel 2
      0   1   2   3   4   5   6   7   8   9   10  11 ...

This is also referred to as xRGB. The pixels don’t have any alpha value (they’re assumed to be 100% opaque), but the memory layout is the same. You may wonder why this format is popular, as, if we didn’t have that unused byte for each pixel, we would save 25% space. It turns out, though, that this format is much easier to _digest_ by modern CPUs and imaging algorithms, because the individual pixels are aligned to 32-bit boundaries. Modern CPUs don’t like loading (reading) unaligned data. The algorithms would have to do a lot of shifting and masking, particularly when mixing this format with the above format that does have alpha.

When dealing with RGB data, Core Graphics also supports putting the alpha value last (and additionally skipping). These are sometimes referred to as RGBA and RGBx respectively, implicitly assuming 8 bpc and pre-multiplied alpha.

### Esoteric Layouts

Most of the time, when dealing with bitmap data, we’ll be dealing with Core Graphics / Quartz 2D. It has a very specific list of format combinations that it supports. But let’s first look at the remaining RGB formats:

Another option is _16 bpp, 5 bpc without alpha_. This layout takes up only 50% of memory (2 bytes per pixel) compared to the previous ones. That can come in handy if you need to store (uncompressed) RGB data in memory or on disk. But since this format only has 5 bits per pixel, images (particularly smooth gradients) may get [banding artifacts][24].

Going the other way, there’s _64 bpp, 16 bpc_ and finally _128 bpp, 32 bpc, float-components_ (both with or without alpha). These use eight bytes and sixteen bytes per pixel respectively and allow for much higher fidelity, at the cost of higher memory usage and being more computationally expensive.

To round things off, Core Graphics also supports a few grayscale and [CMYK][25] formats, as well as an alpha-only format (for masks).

### Planar Data

Most frameworks (including Core Graphics) use pixel data where the components (red, green, blue, alpha) are intermixed. There are situation where we’ll run into something called _planar components_, or _component planes_. What this means is that each color component is in its own region of memory, i.e. _plane_. For RGB data, we’d have three independent memory regions, with one large region containing the red values for all pixels, one containing the green values for all pixels, and one containing the blue values for all pixels.

Some of the video frameworks will use planar data under some circumstances.

### YCbCr

[YCbCr][26] is a format relatively common when working with video data. It also consists of threecomponents (Y, Cb and Cr) and can represent color data. But (briefly put) it is more similar to the way human vision perceives color. Human vision is less sensitive to fidelity of the two chroma components Cb and Cr, but quite sensitive to fidelity of the luma signal Y. When data is in YCbCr format, the Cb and Cr components can be compressed harder than the Y component with the same perceived quality.

JPEG images are also sometimes converting pixel data from RGB to YCbCr for the same reason. JPEG compresses each color plane independently. When compressing YCbCr-based planes, the Cb and Cr can be compressed more than the Y plane.

## Image Formats

Images on disk are mostly JPEG and PNG when you’re dealing with iOS or OS X. Let’s take a closer look.

### JPEG

Everybody knows [JPEG][27]. It’s the stuff that comes out of cameras. It’s how photos are stored on computers. Even your mom has heard of JPEG.

For good reasons, many people think that a JPEG file is just another way to format pixel data, meaning the RGB pixel layouts we [just talked about][13]. That’s very far from the truth, though.

Turning JPEG data into pixel data is a very complex process, certainly nothing you’d be able to pull off as a weekend project, even on a very long weekend. For each [color plane][28], JPEG compression uses an algorithm based on the [discrete cosine transform][29] to convert spatial information into the frequency domain. This information is then quantized, sequenced, and packed using a variant of [Huffman encoding][30]. And quite often, initially, the data is converted from RGB to YCbCr planes. When decoding a JPEG all of this has to run in reverse.

That’s why when you create a `UIImage` from a JPEG file and draw that onto the screen, there’ll be a delay, because the CPU is busy decompressing that JPEG. If you have to decompress a JPEG for each table view cell, your scrolling won’t be smooth.

So why would you use JPEG at all? The answer ist that JPEG can compress photos very, very well. An uncompressed photo from your iPhone 5 would take up almost 24MB. With the default compression setting, your photos in your camera roll are usually around 2MB to 3MB. JPEG compression works so well, because it is lossy. It throws away information that is less perceptible to the human eye, and in doing so, it can push the limits far beyond what “normal” compression algorithms such as gzip do. But this only works well on photos, because JPEG relies on the fact that there’s a lot in photos that’s not very perceptible to the human vision. If you take a screen shot of a web page that’s mostly displaying text, JPEG is not going to do very well. Compression will be lower, and you’ll most likely see that the JPEG compression has altered the image.

### PNG

[PNG][31] is pronounced “ping”. As opposed to JPEG, it’s a lossless compression format. When you save an image as PNG, and later open it (and decompress it), all pixel data is exactly what it was originally. Because of this restriction, PNG can’t compress photos as well as JPEG, but for app artwork such as buttons, icons etc. it actually works very well. And what’s more, decoding PNG data is a lot less complex than decoding JPEG.

In the real world, things are never quite as simple, and there are actually a slew of different PNG formats. Check Wikipedia for the details. But simply put, PNG supports compressing color (RGB) pixels with or without an alpha channel. That’s another reason why it works well for app artwork.

### Picking a Format

When you’re using photos in your app, you should stick to one of these two: JPEG or PNG. The decompressors and compressors for reading and writing these formats are highly optimized for performance and, to some extent, support parallization. And you’ll get the constant additional improvements that Apple is doing to these decompressors for free with future updates of the OS. If you’re tempted to use another format, be aware that this is likely to impact performance of your app, and also likely to open security holes, as image decompressors are a favorite target of attackers.

Quite a bit has been written about [optimizing PNGs][32]. Search the web yourself, if you feel so inclined. It is very important, though, to note that Xcode’s _optimized PNG_ option is something quite different that most other optimization engines.

When Xcode _optimizes_ PNG files, it turns these PNG files into something that’s, technically speaking, [no longer a valid PNG][33]. But iOS can read these files, and in fact can decompress these files way faster that normal PNGs. Xcode changes them in such a way that lets iOS use a more efficient decompression algorithm that doesn’t work on regular PNGs. The main point worth noting is that it changes the pixel layout. As we mentioned under [Pixels][13], there are many ways to represent RGB data, and if the format is not what the iOS graphics system needs, it needs to shift the data around for each pixel. Not having to do so speeds things up.

And, let us stress again: If you can, you should use so-called [resizable images][34] for artwork. Your files will be smaller, and hence there’s less data that needs to be loaded from the file system and then decompressed.

## UIKit and Pixels

Each view in UIKit has its own `CALayer`. In turn, this layer (normally) has a backing store, which is pixel bitmap, a bit like an image. This backing store is what actually gets rendered onto the display.

### With -drawRect:

If your view class implements `-drawRect:` things work like this:

When you call `-setNeedsDisplay`, UIKit will call `-setNeedsDisplay` on the views layer. This sets a flag on that layer, marking it as _dirty_, as needing display. It’s not actually doing any work, so it’s totally acceptable to call `-setNeedsDisplay` multiple times in a row.

Next, when the rendering system is ready, it calls `-display` on that view’s layer. At this point, the layer sets up its backing store. Then it sets up a Core Graphics context (`CGContextRef`) that is backed by the memory region of that backing store. Drawing using that `CGContextRef` will then go into that memory region.

When you use UIKit’s drawing methods such as `UIRectFill()` or `-[UIBezierPath fill]` inside your `-drawRect:` method, they will use this context. The way this works is that UIKit pushes the `CGContextRef` for that backing store onto its _graphics context stack_, i.e. it makes that context the _current_ one. Thus `UIGraphicsGetCurrent()` will return that very context. And since the UIKit drawing methods use `UIGraphicsGetCurrent()`, the drawing will go into the layer’s backing store. If you want to use Core Graphics methods directly, you can get to that same context by calling `UIGraphicsGetCurrent()` yourself and passing the context into the Core Graphics functions as the context.

From now on, the layers backing store will be rendered onto the display repeatedly, until something calls the view’s `-setNeedsDisplay` again, and that in turn causes the layers backing store to be updated.

### Without -drawRect:

When you’re using a `UIImageView` things work slightly different. The view still has a `CALayer`, but the layer doesn’t allocate a backing store. Instead it uses a `CGImageRef` as its contents and the render server will draw that image’s bits into the frame buffer, i.e. onto the display.

In this case, there’s no drawing going on. We’re simply passing bitmap data in form of an image to the `UIImageView`, which forwards it to Core Animation, which, in turn, forwards it to the render server.

### To -drawRect: or Not to -drawRect:

It may sound cheesy, but: The fastest drawing is the drawing you don’t do.

Most of the time, you can get away with compositing your custom view from other views or compositing it from layers or a combination of the two. Check Chris’ article about [custom controls][35] for more info. This is recommended, because the view classes of `UIKit` are extremely optimized.

A good example of when you might need custom drawing code is the “finger painting” app that Apple shows in [WWDC 2012’s session 506][36]: _Optimizing 2D Graphics and Animation Performance_.

Another place that uses custom drawing is the iOS stocks app. The stock graph is drawn on the device with Core Graphics. Note, however that just because you do custom drawing, you don’t necessarily need to have a `-drawRect:` method. At times, it may make more sense to create a bitmap with `UIGraphicsBeginImageContextWithOptions()` or `CGBitmapContextCreate()`, grab the resulting image from that, and set it as a `CALayer`’s `contents`. Test and measure. We’ll give an example of this [below][37].

### Solid Colors

If we look at this example:


    // Don't do this
    - (void)drawRect:(CGRect)rect
    {
        [[UIColor redColor] setFill];
        UIRectFill([self bounds]);
    }

we now know why this is bad: We’re causing Core Animation to create a backing store for us, and we’re asking Core Graphics to fill the backing store with a solid color. And then that has to get uploaded to the GPU.

We can save all this work by not implementing `-drawRect:` at all, and simply setting the view’s layer’s `backgroundColor`. If the view has a `CAGradientLayer` as its layer, the same technique would work for gradients.

### Resizable Images

Similarly, you can use resizable images to lower pressure on the graphics system. Let’s say you want a 300 x 50 points button for which you have artwork. That’s 600 x 100 = 60k pixels or 60k x 4 = 240kB of memory that has to get uploaded to the GPU, and that then takes up VRAM. If we were to use a so-called resizable image, we might get away with e.g. a 54 x 12 points image which would be just below 2.6k pixels or 10kB of memory. Things are faster.

Core Animation can resize images with the [`contentsCenter`][38] property on `CALayer` but in most cases you’d want to use [`-[UIImage resizableImageWithCapInsets:resizingMode:]`][39].

Note also, that before this button can be rendered for the first time, instead of having to read a 60k pixel PNG from the file system and decode that 60k pixel PNG, decoding the much smaller PNG is faster. This way, your app has to do way less work in all steps involved and your views will load a lot quicker.

### Concurrent Drawing

The [last objc.io issue][40] was about concurrency. And as you’ll know, UIKit’s threading model is very simple: You can only use UIKit classes (views etc.) from the main queue (i.e. main thread). So what’s this thing about concurrent drawing?

If you have to implement `-drawRect:` and you have to draw something non-trivial, this is going to take time. And since you want animations to be smooth, you’ll be tempted to do things on a queue other than the main queue. Concurrency is complex, but with a few caveats, drawing concurrently is easily achievable.

We can’t draw into a `CALayer`’s backing store from anything but the main queue. Bad things would happen. But what we can do is to draw into a totally disconnected bitmap context.

As we mentioned above under [Core Graphics][41], all Core Graphics drawing methods take a _context_ argument that specifies which context drawing goes into. And UIKit in turn has a concept of a _current_ context that its drawing goes into. This _current_ context is per-thread.

In order to concurrently draw, we’ll do the following. We’ll create an image on another queue, and once we have that image, we’ll switch back to the main queue and set that resulting image as the `UIImageView`’s image. This technique is discussed in [WWDC 2012 session 211][42].

Add a new method in which you’ll do the drawing:


    - (UIImage *)renderInImageOfSize:(CGSize)size;
    {
    	UIGraphicsBeginImageContextWithOptions(size, NO, 0);

    	// do drawing here

    	UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    	UIGraphicsEndImageContext();
    	return result;
    }

This method creates a new bitmap `CGContextRef` for the given size through the `UIGraphicsBeginImageContextWithOptions()` function. That function also makes that new context the _current_ UIKit context. You can now do your drawing just as you would normally do in `-drawRect:`. Then we get the bitmap data of that context as an `UIImage` with `UIGraphicsGetImageFromCurrentImageContext()`, and finally tear down the context.

It is important that any calls your drawing code in this method makes are threadsafe, i.e. if you access properties etc., they need to be threadsafe. The reason is that you’ll call this method from another queue. If this method is in your view class, that can be a bit tricky. Another option (which may be easier) is to create a separate renderer class that you set all needed properties on and only then trigger to render the image. If so, you might be able to use a plain `UIImageView` or `UITableViewCell`.

Note that all the UIKit drawing APIs are safe to use on another queue. Just make sure to call them inside the same operation that starts with `UIGraphicsBeginImageContextWithOptions()` and ends with `UIGraphicsEndIamgeContext()`.

You’d trigger the rendering code with something like this:


    UIImageView *view; // assume we have this
    NSOperationQueue *renderQueue; // assume we have this
    CGSize size = view.bounds.size;
    [renderQueue addOperationWithBlock:^(){
    	UIImage *image = [renderer renderInImageOfSize:size];
    	[[NSOperationQueue mainQueue] addOperationWithBlock:^(){
    		view.image = image;
    	}];
    }];

Note that we’re calling `view.image = image` on the main queue. This is a very important detail. You can _not_ call this on any other queue.

As always, with concurrency comes a lot of complexity. You may now have to implement canceling of background rendering. And you’ll most likely have to set a reasonable maximum concurrent operation count on the render queue.

In order to support all this, it’s most likely easiest to implement the `-renderInImageOfSize:` inside an `NSOperation` subclass.

Finally, it’s important to point out that setting `UITableViewCell` content asynchronously is tricky. The cell may have been reused at the point in time when the asynchronous rendering is done, and you’ll be setting content on it although the cell now is being used for something else.

## CALayer Odds and Ends

By now you should know that a `CALayer` is somehow related and similar to a texture on the GPU. The layer has a backing store, which is the bitmap that gets drawn onto the display.

Quite often, when you use a `CALayer`, you’ll set its `contents` property to an image. What this does, is it tells Core Animation to use that image’s bitmap data for the texture. Core Animation will cause the image to be decoded if it’s compressed (JPEG or PNG) and then upload the pixel data to the GPU.

There are other kinds of layers, though. If you use a plain `CALayer`, don’t set the `contents`, and set a background color, Core Animation doesn’t have to upload any data to the GPU, but will be able to do all the work on the GPU without any pixel data. Similarly for gradient layers, the GPU can create the gradient and the CPU doesn’t need to do any work, and nothing needs to be uploaded to the GPU.

### Layers with Custom Drawing

If a `CALayer` subclass implements `-drawInContext:` or its delegate, the corresponding `-drawLayer:inContext:`, Core Animation will allocate a backing store for that layer to hold the bitmap that these methods will draw into. The code inside these methods runs on the CPU, and the result is then uploaded to the GPU.

### Shape and Text Layers

Things are somewhat different for shape and text layers. First off, Core Animation allocates a backing store for these layers to hold the bitmap data that needs to be generated for the contents. Core Animation will then draw the shape or the text into that backing store. This is conceptually very similar to the situation where you’d implement `-drawInContext:` and would draw the shape or text inside that method. And performance is going to be very similar, too.

When you change a shape or text layer in a way that it needs to update its backing store, Core Animation will re-render the backing store. E.g. when animating the size of a shape layer, Core Animation has to re-draw the shape for each frame in the animation.

### Asynchronous Drawing

`CALayer` has a property called `drawsAsynchronously`, and this may seems like a silver bullet to solve all problems. Beware, though, that it may improve performance, but it might just as well make things slower.

What happens, when you set `drawsAsynchronously` to `YES`, is that your `-drawRect:` / `-drawInContext:` method will still get called on the main thread. But all calls to Core Graphics (and hence also UIKit’s graphics API, which in turn call Core Graphics) don’t do any drawing. Instead, the drawing commands are deferred and processed asynchronously in a background thread.

One way to look at it is that the drawing commands are recorded first, and then later replayed on a background thread. In order for this to work, more work has to be done, and more memory needs to be allocated. But some work is shifted off the main queue. Test and measure.

It is most likely to improve performance for expensive drawing methods, and less likely for those that are cheap.




* * *

[More articles in issue #3][43]

  * [Privacy policy][44]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-3/index.html
   [5]: http://twitter.com/danielboedewadt
   [6]: https://en.wikipedia.org/wiki/IPS_LCD
   [7]: http://www.objc.io/images/issue-3/pixels-software-stack@2x.png
   [8]: http://www.objc.io/issue-3/moving-pixels-onto-the-screen.html#compositing
   [9]: http://en.wikipedia.org/wiki/OpenGL
   [10]: https://en.wikipedia.org/wiki/Bus_%28computing%29
   [11]: http://www.objc.io/images/issue-3/pixels%2C%20hardware%402x.png
   [12]: https://en.wikipedia.org/wiki/Alpha_compositing
   [13]: http://www.objc.io/issue-3/moving-pixels-onto-the-screen.html#pixels
   [14]: https://developer.apple.com/downloads/
   [15]: https://developer.apple.com/library/mac/#documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Introduction/Introduction.html
   [16]: https://developer.apple.com/videos/wwdc/2011/?id=129
   [17]: https://en.wikipedia.org/wiki/Octagon
   [18]: https://en.wikipedia.org/wiki/Adobe_Illustrator
   [19]: https://en.wikipedia.org/wiki/Adobe_Photoshop
   [20]: https://en.wikipedia.org/wiki/NextStep
   [21]: https://en.wikipedia.org/wiki/Display_PostScript
   [22]: https://twitter.com/davehayden
   [23]: http://iosptl.com/posts/cglayer-no-longer-recommended/
   [24]: https://en.wikipedia.org/wiki/Posterization
   [25]: https://en.wikipedia.org/wiki/CMYK
   [26]: https://en.wikipedia.org/wiki/YCbCr
   [27]: https://en.wikipedia.org/wiki/JPEG
   [28]: http://www.objc.io/issue-3/moving-pixels-onto-the-screen.html#planar-data
   [29]: https://en.wikipedia.org/wiki/Discrete_cosine_transform
   [30]: https://en.wikipedia.org/wiki/Huffman_encoding
   [31]: https://en.wikipedia.org/wiki/Portable_Network_Graphics
   [32]: https://duckduckgo.com/?q=%22optimizing%20PNG%22
   [33]: https://developer.apple.com/library/ios/#qa/qa1681/_index.html
   [34]: http://www.objc.io/issue-3/moving-pixels-onto-the-screen.html#resizable-images
   [35]: http://www.objc.io/issue-3/custom-controls.html
   [36]: https://developer.apple.com/videos/wwdc/2012/?id=506
   [37]: http://www.objc.io/issue-3/moving-pixels-onto-the-screen.html#concurrent-drawing
   [38]: https://developer.apple.com/library/mac/documentation/graphicsimaging/reference/CALayer_class/Introduction/Introduction.html#//apple_ref/occ/instp/CALayer/contentsCenter
   [39]: http://developer.apple.com/library/ios/documentation/UIKit/Reference/UIImage_Class/Reference/Reference.html#//apple_ref/occ/instm/UIImage/resizableImageWithCapInsets:resizingMode:
   [40]: http://www.objc.io/issue-2/index.html
   [41]: http://www.objc.io/issue-3/moving-pixels-onto-the-screen.html#core-graphics
   [42]: https://developer.apple.com/videos/wwdc/2012/?id=211
   [43]: http://www.objc.io/issue-3
   [44]: http://www.objc.io/privacy.html
