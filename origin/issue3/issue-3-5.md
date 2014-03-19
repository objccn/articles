[Source](http://www.objc.io/issue-3/advanced-auto-layout-toolbox.html "Permalink to Advanced Auto Layout Toolbox - Views - objc.io issue #3 ")

# Advanced Auto Layout Toolbox - Views - objc.io issue #3 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# Advanced Auto Layout Toolbox

[Issue #3 Views][4], August 2013

By [Florian Kugler][5]

Auto Layout was introduced in OS X 10.7, and one year later it made its way into iOS 6. Soon apps on iOS 7 will be expected to honor the systemwide font size setting, thus requiring even more flexibility in the user interface layout next to different screen sizes and orientations. Apple is doubling down on Auto Layout, so now is a good time to get your feet wet if you haven’t done so yet.

Many developers struggle with Auto Layout when first trying it, because of the often-frustrating experience of building constraint-based layouts with Xcode 4’s Interface Builder. But don’t let yourself be discouraged by that; Auto Layout is much better than Interface Builder’s current support for it. Xcode 5 will bring some major relief in this area.

This article is not an introduction to Auto Layout. If you haven’t worked with it yet, we encourage you to watch the Auto Layout sessions from WWDC 2012 ([202 – Introduction to Auto Layout for iOS and OS X][6], [228 – Best Practices for Mastering Auto Layout][7], [232 – Auto Layout by Example][8]). These are excellent introductions to the topic which cover a lot of ground.

Instead, we are going to focus on several advanced tips and techniques, which enhance productivity with Auto Layout and make your (development) life easier. Most of these are touched upon in the WWDC sessions mentioned above, but they are the kind of things that are easy to oversee or forget while trying to get your daily work done.

## The Layout Process

First we will recap the steps it takes to bring views on screen with Auto Layout enabled. When you’re struggling to produce the kind of layout you want with Auto Layout, specifically with advanced use cases and animation, it helps to take a step back and to recall how the layout process works.

Compared to working with springs and struts, Auto Layout introduces two additional steps to the process before views can be displayed: updating constraints and laying out views. Each step is dependent on the one before; display depends on layout, and layout depends on updating constraints.

The first step – updating constraints – can be considered a “measurement pass.” It happens bottom-up (from subview to super view) and prepares the information needed for the layout pass to actually set the views’ frame. You can trigger this pass by calling `setNeedsUpdateConstraints`. Any changes you make to the system of constraints itself will automatically trigger this. However, it is useful to notify Auto Layout about changes in custom views that could affect the layout. Speaking of custom views, you can override `updateConstraints` to add the local constraints needed for your view in this phase.

The second step – layout – happens top-down (from super view to subview). This layout pass actually applies the solution of the constraint system to the views by setting their frames (on OS X) or their center and bounds (on iOS). You can trigger this pass by calling `setNeedsLayout`, which does not actually go ahead and apply the layout immediately, but takes note of your request for later. This way you don’t have to worry about calling it too often, since all the layout requests will be coalesced into one layout pass.

To force the system to update the layout of a view tree immediately, you can call `layoutIfNeeded`/`layoutSubtreeIfNeeded` (on iOS and OS X respectively). This can be helpful if your next steps rely on the views’ frame being up to date. In your custom views you can override `layoutSubviews`/`layout` to gain full control over the layout pass. We will show use cases for this later on.

Finally, the display pass renders the views to screen and is independent of whether you’re using Auto Layout or not. It operates top-down and can be triggered by calling `setNeedsDisplay`, which results in a deferred redraw coalescing all those calls. Overriding the familiar `drawRect:` is how you gain full control over this stage of the display process in your custom views.

Since each step depends on the one before it, the display pass will trigger a layout pass if any layout changes are pending. Similarly, the layout pass will trigger updating the constraints if the constraint system has pending changes.

It’s important to remember that these three steps are not a one-way street. Constraint-based layout is an iterative process. The layout pass can make changes to the constraints based on the previous layout solution, which again triggers updating the constraints following another layout pass. This can be leveraged to create advanced layouts of custom views, but you can also get stuck in an infinite loop if every call of your custom implementation of `layoutSubviews` results in another layout pass.

## Enabling Custom Views for Auto Layout

When writing a custom view, you need to be aware of the following things with regard to Auto Layout: specifying an appropriate intrinsic content size, distinguishing between the view’s frame and alignment rect, enabling baseline-aligned layout, and how to hook into the layout process. We will go through these aspects one by one.

### Intrinsic Content Size

The intrinsic content size is the size a view prefers to have for a specific content it displays. For example, `UILabel` has a preferred height based on the font, and a preferred width based on the font and the text it displays. A `UIProgressView` only has a preferred height based on its artwork, but no preferred width. A plain `UIView` has neither a preferred width nor a preferred height.

You have to decide, based on the content to be displayed, if your custom view has an intrinsic content size, and if so, for which dimensions.

To implement an intrinsic content size in a custom view, you have to do two things: override [`intrinsicContentSize`][9] to return the appropriate size for the content, and call [`invalidateIntrinsicContentSize`][10] whenever something changes which affects the intrinsic content size. If the view only has an intrinsic size for one dimension, return `UIViewNoIntrinsicMetric`/`NSViewNoIntrinsicMetric` for the other one.

Note that the intrinsic content size must be independent of the view’s frame. For example, it’s not possible to return an intrinsic content size with a specific aspect ratio based on the frame’s height or width.

#### Compression Resistance and Content Hugging

Each view has content compression resistance priorities and content hugging priorities assigned for both dimensions. These properties only take effect for views which define an intrinsic content size, otherwise there is no content size defined that could resist compression or be hugged.

Behind the scenes, the intrinsic content size and these priority values get translated into constraints. For a label with an intrinsic content size of `{ 100, 30 }`, horizontal/vertical compression resistance priority of `750`, and horizontal/vertical content hugging priority of `250`, four constraints will be generated:


    H:[label(=100@750)]
    V:[label(=30@750)]

If you’re not familiar with the visual format language for the constraints used above, you can read up about it in [Apple’s documentation][11]. Keeping in mind that these additional constraints are generated implicitly helps to understand Auto Layout’s behavior and to make better sense of its error messages.

### Frame vs. Alignment Rect

Auto Layout does not operate on views’ frame, but on their alignment rect. It’s easy to forget the subtle difference, because in many cases they are the same. But alignment rects are actually a powerful new concept that decouple a view’s layout alignment edges from its visual appearance.

For example, a button in the form of a custom icon that is smaller than the touch target we want to have would normally be difficult to lay out. We would have to know about the dimensions of the artwork displayed within a larger frame and adjust the button’s frame accordingly, so that the icon lines up with other interface elements. The same happens if we want to draw custom ornamentation around the content, like badges, shadows, and reflections.

Using alignment rects we can easily define the rectangle which should be used for layout. In most cases you can just override the [`alignmentRectInsets`][12] method, which lets you return edge insets relative to the frame. If you need more control you can override the methods [`alignmentRectForFrame:`][13] and [`frameForAlignmentRect:`][14]. This can be useful if you want to calculate the alignment rect based on the current frame value instead of just subtracting fixed insets. But you have to make sure that these two methods are inverses of each other.

In this context it is also good to recall that the aforementioned intrinsic content size of a view refers to its alignment rect, not to its frame. This makes sense, because Auto Layout generates the compression resistance and content hugging constraints straight from the intrinsic content size.

### Baseline Alignment

To enable constraints using the `NSLayoutAttributeBaseline` attribute to work on a custom view, we have to do a little bit of extra work. Of course this only makes sense if the custom view in question has something like a baseline.

On iOS, baseline alignment can be enabled by implementing [`viewForBaselineLayout`][15]. The bottom edge of the view you return here will be used as baseline. The default implementation simply returns self, while a custom implementation can return any subview. On OS X you don’t return a subview but an offset from the view’s bottom edge by overriding [`baselineOffsetFromBottom`][16], which has the same default behavior as its iOS counterpart by returning 0 in its default implementation.

### Taking Control of Layout

In a custom view you have full control over the layout of its subviews. You can add local constraints, you can change local constraints if a change in content requires it, you can fine-tune the result of the layout pass for subviews, or you can opt out of Auto Layout altogether.

Make sure though that you use this power wisely. Most cases can be handled by simply adding local constraints for your subviews.

#### Local Constraints

If we want to compose a custom view out of several subviews, we have to lay out these subviews somehow. In an Auto Layout environment it is most natural to add local constraints for these views. However, note that this makes your custom view dependent on Auto Layout, and it cannot be used anymore in windows without Auto Layout enabled. It’s best to make this dependency explicit by implementing [`requiresConstraintBasedLayout`][17] to return `YES`.

The place to add local constraints is [`updateConstraints`][18]. Make sure to invoke [`super updateConstraints]` in your implementation _after_ you’ve added whatever constraints you need to lay out the subviews. In this method, you’re not allowed to invalidate any constraints, because you are already in the first step of the [layout process][19] described above. Trying to do so will generate a friendly error message informing you that you’ve made a “programming error.”

If something changes later on that invalidates one of your constraints, you should remove the constraint immediately and call [`setNeedsUpdateConstraints`][20]. In fact, that’s the only case where you should have to trigger a constraint update pass.

#### Control Layout of Subviews

If you cannot use layout constraints to achieve the desired layout of your subviews, you can go one step further and override [`layoutSubviews`][21] on iOS or [`layout`][22] on OS X. This way, you’re hooking into the second step of the [layout process][19], when the constraint system has already been solved and the results are being applied to the view.

The most drastic approach is to override `layoutSubviews`/`layout` without calling the super class’s implementation. This means that you’re opting out of Auto Layout for the view tree within this view. From this point on, you can position subviews manually however you like.

If you still want to use constraints to lay out subviews, you have to call [`super layoutSubviews]`/[`super layout]` and make fine-tuned adjustments to the layout afterwards. You can use this to create layouts which are not possible to define using constraints, for example layouts involving relationships between the size and the spacing between views.

Another interesting use case for this is to create a layout-dependent view tree. After Auto Layout has done its first pass and set the frames on your custom view’s subviews, you can inspect the positioning and sizing of these subviews and make changes to the view hierarchy and/or to the constraints. WWDC session [228 – Best Practices for Mastering Auto Layout][7] has a good example of this, where subviews are removed after the first layout pass if they are getting clipped.

You could also decide to change the constraints after the first layout pass. For example, switch from lining up subviews in one row to two rows, if the views are becoming too narrow.


    - layoutSubviews
    {
        [super layoutSubviews];
        if (self.subviews[0].frame.size.width 