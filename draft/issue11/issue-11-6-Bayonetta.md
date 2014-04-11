---
layout: post
title: "Dependency Injection, Annotations, and why Java is Better Than you Think it is"
category: "11"
date: "2014-04-01 06:00:00"
tags: article
author: "<a href=\"http://twitter.com/billjings\">Bill Phillips</a>"
---


I have a confession to make\: I like Java.

我坦白\: 我喜欢Java。

Really! I do!

我真的喜欢！

That may not be shocking to you. I did help write a book full of Java code, after all. It’s shocking to me, though. I wasn’t a fan when I started writing Android apps, I wasn’t a fan when we began the [Big Nerd Ranch Guide](http://www.bignerdranch.com/book/android_the_big_nerd_ranch_guide), and I still wasn’t a huge fan when we finished it. 

也许这并不会让你感到惊讶。但毕竟我确实参与编著过一本全文均与java程序相关的书，因此这足以让我震惊。**当我开始编写Android应用的时候我并不是一个喜欢java的人，而当我开始编写[书虫编程指南](http://www.bignerdranch.com/book/android_the_big_nerd_ranch_guide)的时候，我也很难称得上是粉丝，甚至当我们完成编写的时候，我也始终不能算是一名超级粉丝。**

My beef was not original or well thought out, but here are my issues, roughly:

我原本并非想抱怨什么，也并非要深刻反思一番。下面列出的这些内容大概就是一直困扰我的问题：

*    It’s verbose. There’s no shortened syntax for implementing callbacks, like blocks or lambdas, so you have to write a lot of boilerplate to implement even a simple interface. If you need an object that holds four things, you have to create a class with four named fields. 

*   Java很冗长。没有任何简短的语法来执行回调，比如Blocks或者Lambda表达式（当然，Java8已经开始支持这一特性），所以你必须编写非常多的引用来实现，有时甚至只是一个简单的接口。如果你需要一个对象来保存四个属性，你必须创建一个拥有四个命名字段的类。

*    It’s rigid. Writing sensible Java constantly requires you to specify exactly which exception you’re catching, to specify which type you’re taking in, to check and make sure that your references aren’t null, and to import every class you need to use. And while there is some flexibility at runtime, it’s nowhere close to what you get in the Objective-C runtime, much less something like Ruby or Python.

*   Java很死板。要编写清楚的Java程序, 你通常要正确的指定需要捕获的异常类型，以及要接受的参数类型，还有仔细检查并确保你的引用非空，甚至还要导入你所使用的每一个类。另外在运行时有一定的**灵活性**，和Objective-c的运行时没有任何相似的地方，更不用说Ruby或者Python了。

That was essentially my view of Java. It was this kind of Java:

这是我眼中的Java，它的代码就像这样:

    public class NumberStack {
        List<Integer> mNumbers = new ArrayList<Integer>();
    
        public void pushNumber(int number) {
            mNumbers.add(number);
        }
    
        public Integer popNumber() {
            if (mNumber.size() == 0) {
                return null;
            } else {
                return mNumber.remove(mNumber.size() - 1);
            }
        }
    }

Add some inner classes and interfaces to the mix, and that is what I learned and worked with. Not the worst thing in the world to be writing, but other languages had features and flexibility that I wished that I had in Java. Never did I find myself writing code in another language and saying, “Man, I wish this were more like Java.”

我学习过并且会在工作中混合使用一些内部类和接口。虽然编写Java程序这并不是世界上最糟糕的事情，但是我还是希望Java能够拥有其他语言的特点和灵活性。类似“天啊，我多么希望这能更像Java”的感叹从没有出现过。

My opinion has changed.

但是，我的想法改变了。

## Something Peculiar to Java

## Java独有的特性

Oddly enough, the tool that changed my mind is only popular because of problems that are peculiar to Java. Consider the following code:

说来也奇怪，改变我想法的恰恰是Java独有的特性。请思考下面的代码:

    public class Payroll {
        ...

        public long getWithholding(long payInDollars) {
            ...
            return withholding;
       }

        public long getAfterTaxPay(Employee employee) {
            long basePay = EmployeeDatabase.getInstance()
               .getBasePay(employee);
            long withholding = getWithholding(basePay);

            return basePay - withholding;
        }
    }

This class has a dependency in `getAfterTaxPay()` called `EmployeeDatabase`. There are a variety of ways that we could create this object, but in this example, I’ve used a typical singleton pattern of having a static getInstance method.

这个类在 `getAfterTaxPay()` 方法中有一个叫做 `EmployeeDatabase` 的依赖对象。有很多种方式可以创建该对象，但在这个例子中, 我使用了单例模式，调用一个静态的实例方法。

Dependencies in Java are surprisingly strict things. Whenever I write a line of code like this:

Java中的依赖关系是非常严格的。所以任何时间我都像这样编写代码：

            long basePay = EmployeeDatabase.getInstance()
               .getBasePay(employee);

I create a strict dependency on the `EmployeeDatabase` class. Not only that, but I also create a strict dependency on a particular method in `EmployeeDatabase`: the `getInstance()` method. In other languages, I might be able to swizzle or monkey patch this kind of thing. Not that that’s a great idea, necessarily, but it is at least possible. Not so in Java.

在 `EmployeeDatabase` 类中我创建了一个严格依赖。不仅如此，我是利用`EmployeeDatabase`类的特定方法 `getInstance()` 创建的严格依赖。而在其他语言里，**I might be able to swizzle or monkey patch this kind of thing.** 当然并不是说这样不好，但它至少存在实现的可能。但是Java不可以。

Other ways of creating a dependency are even more strict than that. Let’s say that instead, I wrote that line like this:

而创建依赖的其他方式比这更加严格。就让我们来看看下面这行：

            long basePay = new EmployeeDatabase()
               .getBasePay(employee);

When I use the new keyword, I tie myself down in all the same ways I did with the static method, but I also add one more: calling `new EmployeeDatabase()` must always yield an instance of the `EmployeeDatabase` class. You can’t rewrite that constructor to return a mock subclass, no matter what you do.

当使用关键字new，我会采用与调用静态方法相同的方式，但有一点不同：调用 `new EmployeeDatabase()`方法必须由 `EmployeeDatabase` 类的一个实例来完成。无论你要做什么，都不能复写构造器来返回子类。

## Dependency Injection

## 依赖注入

The way we usually solve this problem is to use a technique called dependency injection. It’s not a technique unique to Java, but because of the aforementioned issues, Java is in particularly dire need of it. 

我们解决此类问题通常采用依赖注入技术。它并非Java独有的特性，但对于上述提到的问题，Java尤其需要。 

Dependency injection simply means receiving collaborators as constructor parameters instead of fetching them ourselves. So `Payroll` would look like this instead:

依赖注入简单的说，就是接受合作对象作为构造方法的参数而不是直接获取它们自身。所以 `Payroll` 类的实现会相应地变成这样：

    public class Payroll {
        ...

        EmployeeDatabase mEmployeeDatabase;

        public Payroll(EmployeeDatabase employeeDatabase) {
            mEmployeeDatabase = employeeDatabase;
        }

        public long getWithholding(long payInDollars) {
            ...
            return withholding;
       }

        public long getAfterTaxPay(Employee employee) {
            long basePay = mEmployeeDatabase.getBasePay(employee);
            long withholding = getWithholding(basePay);

            return basePay - withholding;
        }
    }

Is `EmployeeDatabase` a singleton? A mocked-out subclass? A context-specific implementation? `Payroll` no longer needs to know.


 `EmployeeDatabase` 是一个单例？一个**子类**？还是一个上下文相关的实现？ `Payroll` 类不再需要知道这些。

## Declarative Dependency Programming

## 用声明依赖进行编程

All of that is just background for what I really want to talk about: dependency injectors.

上述这些仅仅介绍了我真正要讲的内容——依赖注入的背景。

(An aside: I know it’s a little odd to be two problems deep before actually discussing something nifty, but I hope you’ll bear with me. Understanding what Java gets right just requires more work than it does with other languages. It’s the nature of the beast.)

（旁白：我知道在真正开始讨论前将这两个问题讲的比较深入是很奇怪的，但是我希望你们能够容忍我这么做。正确的理解Java比起其他语言要花费更多地时间。**这是野兽的本性。**）

See, now that we are passing in dependencies through our constructors, our objects are more difficult to use and more difficult to change. Before I used dependency injection, I could use `Payroll` like this:

现在我们通过构造函数传递依赖，会导致我们的对象更加难以使用，同时也很难作出更改。在我使用依赖注入之前，我会像这样使用 `Payroll` 类:

        new Payroll().getAfterTaxPay(employee);

Now, though, I have to write this:

但是，现在我必须这样写:

        new Payroll(EmployeeDatabase.getInstance())
            .getAfterTaxPay(employee);

Plus, anytime I change `Payroll`’s dependencies, I have to change every place I write `new Payroll`, too.

还有，任何时候如何我改变了 `Payroll` 的依赖, 我都不得不修改使用了 `new Payroll` 的每一个地方。

A dependency injector allows me to forget about writing code to explicitly supply dependencies. Instead, I declaratively say what my dependencies are, and the tool worries about supplying them when they’re needed. There are a variety of dependency injection tools out there; for these examples, I’ll be using RoboGuice.

而依赖注入允许我不再编写用来明确提供依赖的代码。相反，我可以直接声明我的依赖对象，让工具来自动处理相应操作。有很多依赖注入的工具，下面我将用RoboGuice来举个例子。 

To do this, we use Java’s tool for describing code: the annotation. We declare our dependencies by simply annotating our constructor:

为了这样做，我使用Java工具——“注解“来**描述**代码。我们通过为构造器添加简单的注解声明:

        @Inject
        public Payroll(EmployeeDatabase employeeDatabase) {
            mEmployeeDatabase = employeeDatabase;
        }

The `@Inject` annotation says, “To build an instance of `Payroll`, execute this constructor, passing in values for all of its parameters.” Then when I actually need a `Payroll` instance, I ask the dependency injector to build me one, like so:

注解 `@Inject` 的含义是“创建一个 `Payroll` 类的实例，执行它的构造器方法，传递所有的参数值。”而当我真的需要一个 `Payroll` 实例的时候，我会利用依赖注入器来帮我创建，就像这样：
 
        Payroll payroll = RoboGuice.getInjector(getContext())
            .getInstance(Payroll.class);

        long afterTaxPay = payroll.getAfterTaxPay(employee);

Once I’m constructing instances in this way, I can use the injector itself to configure how dependencies are satisfied. Do I want `EmployeeDatabase` to be a singleton? Do I want to use a customized subclass? All of this can be specified in one place. 

一旦我采用这种方式创建实例，就能使用注入器来设置足够令人满意的依赖。是否需要 `EmployeeDatabase` 是一个单例？是否需要一个可自定义的子类？所有这些都可以在同一个地方指定。

## The Wider World of Declarative Java

## 声明式Java的广阔世界

It’s an easily described tool, but it’s hard to overestimate how fundamental the gap is between Java with and without a dependency injector. Without a dependency injector, aggressive refactoring and test-driven development are laborious. With one, they are effortless. The only thing more indispensable to a Java developer than a dependency injector is a good IDE.

这是一种很容易使用的**描述**工具，但是很难比较在Java中是否使用依赖注入的根本差距。如果没有依赖注入器，重构和测试驱动开发会是一项艰苦的劳动。而使用它，这些工作则会毫不费力。对于一名Java开发者来说，唯一比依赖注入器更重要的就是一个优秀的IDE了。

Still, it’s just the first taste of a wider set of possibilities. Most of the exciting new stuff for Android developers originating outside Google revolves around annotation-based APIs. 

不过，这只是广泛可能性中的第一点。 对于Google外部的Android开发者来说，最令人兴奋的就是基于注解的API了。

Take ButterKnife, for example. We spend a lot of time in Android wiring up listeners to view objects, like this:

举个例子，我们可以使用ButtreKnife。通常情况下，我们会花费大量的时间为Android的视图对象编写监听器，就像这样：

    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_content);

        View okButton = findViewById(R.id.ok_button);
        okButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                onOkButtonClicked();
            }
        });
    }

    public void onOkButtonClicked() {
        // handle button click
    }

ButterKnife allows us to instead provide a little bit of metadata that says, “Call `onOkButtonClicked` when the view with the id `R.id.ok_button` is clicked.” Like this:

ButterKnife允许我们只提供很少的代码来表示“ID为 `R.id.ok_button` 的视图控件被点击时调用 `onOkButtonClicked` 方法”，就像这样：

    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_content);

        ButterKnife.inject(this);
    }

    @OnClick(R.id.ok_button);
    public void onOkButtonClicked() {
        // handle button click
    }

I could go on and on with more examples. There are libraries that use annotations to serialize and deserialize JSON, to stash fields in `savedInstanceState`, to generate code to interface with RESTful web services, and on and on and on.

我能继续写很多这样的例子。有很多库可以通过注解来实现序列化与反序列化Json，在 `savedInstanceState` 方法内部存储字段, 生成REST网络服务的接口代码等操作。

## Compile Time vs. Runtime Annotation Processing

## 编译时和运行时注解处理对比

While some tools may achieve similar effects with annotations, Java allows them to achieve these effects in different ways. Take RoboGuice and Dagger, for example. Both are dependency injectors; both use the `@Inject` annotation. But where RoboGuice reads your code annotations at runtime, Dagger reads them at compile time and generates code.

尽管有些使用注解的工具会产生相似的效果，不过Java允许使用不同的方式实现。下面我用RoboGuice和Dagger来举个例子。它们都是依赖注入器，也同样都使用 `@Inject` 注解。但是RoboGuice会在运行时读取你的代码注解，而Dragger则是在编译时生成对应的代码。

This has a few important benefits. It means that errors in your annotation semantics can be detected early. Dagger can tell you at compile time when you have a circular dependency; RoboGuice cannot.

这样会有一些重要的好处。它能在更早的时间发现注解中的语义错误。Dagger能够在编译时提醒你可能存在的循环依赖，但是RoboGuice不能。

It can also improve performance. Generated code can reduce startup time and eliminate the need to read annotations at runtime. Reading annotation requires the use of Java’s reflection APIs, which can be expensive on some Android devices. 

而且这对提高性能也很有帮助。通过依赖注入生成的代码可以减少创建时间，并在运行时避免读取注解。因为读取注解需要使用Java反射相关的API，这在Android设备上是很耗时的。 

### An Example of Runtime Annotation Processing

### 运行时进行注解处理的例子

I’d like to finish up by showing a simple example of how one might define and process a runtime annotation. Let’s say that you were an exceptionally impatient person and were tired of typing out fully qualified static constants in your Android codebase, constants like these:

我会通过展示一个如何定义和处理运行时注解的简单例子，来结束今天的内容。 假设你是一个很没有耐心地人，并且厌倦了在你的Android程序中打出一个完整的静态限定常量，比如：

    public class CrimeActivity {
        public static final String ACTION_VIEW_CRIME = 
            “com.bignerdranch.android.criminalintent.CrimeActivity.ACTION_VIEW_CRIME”;
    }

You could use a runtime annotation to do this work for you. First, you’d create the annotation class:

你可以使用一个运行时注解来帮你做这些事情。首先，你要创建一个**注解类**：

    @Retention(RetentionPolicy.RUNTIME)
    @Target( { ElementType.FIELD })
    public @interface ServiceConstant { }
    
This code declares an annotation named `ServiceConstant`. The code is itself annotated with two annotations: `@Retention`, and `@Target`. `@Retention` says how long the annotation will stick around. Here, we say that we want to see it at runtime. If we wanted this annotation to be processed at compile time only, we could have specified `RetentionPolicy.SOURCE`.

这段代码声明了一个名为 `ServiceConstant` 的注解。 而代码本身被 `@Retention`、`@Target` 注解。`@Retention` 表示注解将会停留的时间。在这里我们将它设置为运行时触发。如果我们想仅仅在编译时处理注解，可以进行 `RetentionPolicy.SOURCE` 的声明。

The other annotation, `@Target`, says where you can put the annotation in your source code. Any number of values can be provided. Our annotation is only valid for fields, so we have just provided `ElementType.FIELD`.

另一个注解 `@Target`，表示你放置注解的位置。当然有很多的数据类型可以选择。因为我们的注解仅需要对字段有效，所以只需要提供 `ElementType.FIELD` 的声明。

Once the annotation is defined, we write some code to look for it and populate the annotated field automatically:

一旦定义了注解，我们接着就要写些代码来寻找并自动填充带注解的字段：

    public static void populateConstants(Class<?> klass) {
        String packageName = klass.getPackage().getName();
        for (Field field : klass.getDeclaredFields()) {
            if (Modifier.isStatic(field.getModifiers()) && 
                    field.isAnnotationPresent(ServiceConstant.class)) {
                String value = packageName + "." + field.getName();
                try {
                    field.set(null, value);
                    Log.i(TAG, "Setup service constant: " + value + "");
                } catch (IllegalAccessException iae) {
                    Log.e(TAG, "Unable to setup constant for field " + 
                            field.getName() +
                            " in class " + klass.getName());
                }
            }
        }
    }
    
Finally, we add the annotation to our code, and call our magic method:

最后，我们为代码增加注解，然后调用我们充满魔力的方法：

    public class CrimeActivity {
        @ServiceConstant
        public static final String ACTION_VIEW_CRIME;
    
        static {
            ServiceUtils.populateConstants(CrimeActivity.class);
    }

## Conclusion

## 总结

Well, that’s all I’ve got. So much for annotations in Java. I can’t say that I’m sure that all this has made you feel the same way as I do about Java, but I hope that you’ve seen some interesting stuff. While day-to-day Java may be lacking a bit in expressivity, there are a few basic building blocks in the Java kit that make it possible for advanced developers to create powerful tools that amplify the productivity of the entire community. 

这些就是我了解的全部内容。有太多与Java注解相关的部分。我不能保证所有这些能够立刻让你对Java的感受变得和我一样，但是我希望你能确实看到很多有趣的东西。虽然通常Java在表达性上还欠缺一些，但是在Java的工具包中有一些基本的**构建块**，使高级开发人员可以构建更强大的工具，从而扩大整个社会的生产力。

If you’re interested in diving in deeper, you will find the topic of driving code generation with annotations very interesting. It’s not necessarily pretty to read or write, but folks are doing some nifty work out there with the tools as they are. The source for ButterKnife is reasonably simple, if you’re interested in an example of how it’s done in the real world.

如果你对此很感兴趣，并且打算深入了解这些，你会发现通过注解驱动代码生成的过程非常有趣。**有时候并不一定要真的阅读或者写出漂亮的代码**，但是人们会利用这些工具创造出漂亮的代码。假如你对于实际场景如何应用依赖注入的原理很感兴趣的话，ButterKnife的源码是相当简单的。

---

[话题 #11 下的更多文章](http://objccn.io/issue-11)
 
原文 [Dependency Injection, Annotations, and why Java is Better Than you Think it is #11](http://www.objc.io/issue-11/dependency-injection-in-java.html)
