我坦白\: 我喜欢java.

真的，请相信我。

也许这并不会让你感到惊讶。但毕竟我确实参与编写过一本有关java程序的书，所以这句话足以让我自己震惊。**当我开始编写Android应用的时候我还并不是一个喜欢java的人，当我开始编写[书虫编程指南](http://www.bignerdranch.com/book/android_the_big_nerd_ranch_guide)的时候，我也很难称得上是粉丝，甚至当我们完成编写的时候，我也始终不能算是一名超级粉丝。**

我原本并非想抱怨什么，也并非想要深度反思一番。下面列出的这些内容大概就是一直困扰我的问题：

*   Java很冗长。没有任何更简短的语法来执行回调，比如Blocks或者Lambda表达式（当然，Java8已经开始支持这一特性），所以你必须编写非常多的引用来实现，甚至只是一个简单的接口。如果你需要一个对象来保存四个属性，你必须创建一个拥有四个命名字段的类。
*   Java很死板。编写清楚的Java程序时常需要你去正确的指定要捕获的异常类型，要接受的参数类型，还有仔细检查确保你的引用非空，以及导入你所使用的每一个类。另外在运行时有一定的灵活性，和Objective-c的运行时没有任何相似的地方，更不用说Ruby或者Python了。

这是我眼中的Java，它的代码是这样的:

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

增加一些Add some inner classes and interfaces to the mix, and that is what I learned and worked with. Not the worst thing in the world to be writing, but other languages had features and flexibility that I wished that I had in Java. Never did I find myself writing code in another language and saying, “Man, I wish this were more like Java.”

但是，我的想法改变了。

## Java独有的特性

说来也奇怪，改变我想法的恰恰是Java独有的特性。思考下面的代码:

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

这个类在 `getAfterTaxPay()` 方法中有一个叫做 `EmployeeDatabase` 的依赖对象。有很多种方式可以创建该对象，但在这个例子中, 我使用了单例模式，调用了一个静态的实例方法。

在Java中依赖关系是非常严格的。无论何时我写出这样的代码：

            long basePay = EmployeeDatabase.getInstance()
               .getBasePay(employee);

在 `EmployeeDatabase` 类中我创建了严格的依赖。不仅如此，我还but I also create a strict dependency on a particular method in `EmployeeDatabase`: the `getInstance()` method. In other languages, I might be able to swizzle or monkey patch this kind of thing. Not that that’s a great idea, necessarily, but it is at least possible. Not so in Java.

Other ways of creating a dependency are even more strict than that. Let’s say that instead, I wrote that line like this:

            long basePay = new EmployeeDatabase()
               .getBasePay(employee);

When I use the new keyword, I tie myself down in all the same ways I did with the static method, but I also add one more: calling `new EmployeeDatabase()` must always yield an instance of the `EmployeeDatabase` class. You can’t rewrite that constructor to return a mock subclass, no matter what you do.

## 依赖注入

我们解决此类问题通常采用依赖注入技术。它并非Java独有的特性，但对于上述提到的问题，Java尤其需要它。 

依赖注入简单来说，接受合作对象作为构造函数参数而不是获取它们自身。所以 `Payroll` 类的实现会相应地变成这样：

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

 `EmployeeDatabase` 是一个单例？一个**子类**？还是一个上下文相关的实现？ `Payroll` 类不再需要知道这些。

## 声明依赖编程

上述这些仅仅是我真正要讲的内容——依赖注入的背景。

（旁白：我知道在真正开始讨论前将这两个问题讲的比较深入是很奇怪的，但是我希望你们能够容忍我这么做。正确的理解Java比起其他语言要花费更多地时间。**这是野兽的本性。**）

现在我们通过构造函数传递依赖，会导致我们的对象更加难以使用，同时也很难作出更改。在我使用依赖注入之前，我会像这样使用 `Payroll` 类:

        new Payroll().getAfterTaxPay(employee);

但是，现在我必须这样写:

        new Payroll(EmployeeDatabase.getInstance())
            .getAfterTaxPay(employee);

还有，任何时候我改变了 `Payroll` 的依赖, 我都不得不改变每个使用了 `new Payroll` 的地方。

而依赖注入允许我不用再编写用来明确提供依赖的代码。相反，我可以直接声明我的依赖对象，让工具来自动处理相应操作。有很多种依赖注入的工具，下面我将使用RoboGuice来举个例子。 

为了这样做，我使用Java工具来描述注解的相关代码。我们通过为构造器添加简单的注解声明:

        @Inject
        public Payroll(EmployeeDatabase employeeDatabase) {
            mEmployeeDatabase = employeeDatabase;
        }

 `@Inject` 的含义是“创建一个 `Payroll` 类的实例，执行它的构造器方法，传递所有的参数值。”而当我真的需要一个 `Payroll` 实例的时候，我会利用依赖注入器来帮我建立，就像这样：
 
        Payroll payroll = RoboGuice.getInjector(getContext())
            .getInstance(Payroll.class);

        long afterTaxPay = payroll.getAfterTaxPay(employee);

一旦我采用这种方式创建实例，就能使用注入器来设置足够令人满意的依赖。是否需要 `EmployeeDatabase` 是一个单例？是否需要一个可自定义的子类？所有这些都可以在一个地方制定。

## 声明式Java的广阔世界

这是一个很容易进行描述的工具，但是很难比较在Java中是否使用依赖注入的根本差距。如果没有依赖注入，重构和测试驱动开发会是一项艰苦的劳动。而使用它，这些工作则会毫不费力。对于一名Java开发者来说，唯一会比依赖注入器更重要的就是一个优秀的IDE了。

不过，这只是广泛可能性中的第一点。 对于Google外部的Android开发者来说，最令人兴奋的是基于注解的API了。

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

ButterKnife允许我们只提供很少的代码来表示，“当绑定ID为 `R.id.ok_button` 的视图控件被点击时调用 `onOkButtonClicked` 方法”，就像这样：

    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_content);

        ButterKnife.inject(this);
    }

    @OnClick(R.id.ok_button);
    public void onOkButtonClicked() {
        // handle button click
    }

我能继续写很多这样的例子。有很多的库可以使用注解来进行序列化与反序列化Json，在 `savedInstanceState` 方法内部存储字段, 生成REST网络服务的接口代码等操作。

## 编译时和运行时注解处理的对比

虽然有些工具使用注解会产生相似的效果，但是Java允许使用不同的方式实现。下面我用RoboGuice和Dagger来举个例子。它们都是依赖注入器，也同样都使用 `@Inject` 注解。但是RoboGuice是在运行时读取你的代码注解，而Dragger时在编译时生成对应的代码。

这样会有一些重要的好处。它能在更早的时间发现注解中的语义错误。Dagger能够在编译时提醒你可能存在的循环依赖，但是RoboGuice不能。

而且这对提高性能也有帮助。通过依赖注入生成的代码可以减少创建时间，并在运行时避免读取注解。因为读取注解需要使用Java反射相关的API，在Android设备上是很耗时的。 

### 运行时进行注解处理的例子

我会通过展示一个怎样定义和处理运行时注解的简单例子，来结束今天的内容。 假设你是一个很没有耐心地人，厌倦了在你的Android程序中打出一个完整的静态限定常亮，比如：

    public class CrimeActivity {
        public static final String ACTION_VIEW_CRIME = 
            “com.bignerdranch.android.criminalintent.CrimeActivity.ACTION_VIEW_CRIME”;
    }

你可以使用一个运行时注解来帮你做这些事情。首先，你会创建一个**注解类**：

    @Retention(RetentionPolicy.RUNTIME)
    @Target( { ElementType.FIELD })
    public @interface ServiceConstant { }
    
这段代码声明了一个名为 `ServiceConstant` 的注解。 而代码本身被 `@Retention`、`@Target` 注解。`@Retention` 表示注解将会停留的时间。这里，我们将它设置为运行时触发。如果我们想仅仅在编译时处理注解，可以进行 `RetentionPolicy.SOURCE` 的声明.

另一个注解 `@Target`, 表示你将注解放置的位置。有很多的数据类型可以选择。因为我们的注解仅需要对字段有效，所以只需要提供 `ElementType.FIELD` 的声明。

一旦定义了注解，我们接着写些代码来寻找并自动填充带注解的字段：

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

最后，我们为代码增加注解，然后调用我们充满魔力的方法：

    public class CrimeActivity {
        @ServiceConstant
        public static final String ACTION_VIEW_CRIME;
    
        static {
            ServiceUtils.populateConstants(CrimeActivity.class);
    }

## 总结

这些就是我了解的全部内容。有太多与Java注解的部分。我不能保证所有的这些能够立刻让你对Java的感受变得和我一样，但是我希望你确实的看到很多有趣的东西。虽然通常Java在表达上还欠缺一些，但是在Java的工具包中有一些基本的构建块，使高级开发人员可以构建更强大的工具，从而扩大整个社会的生产力。

如果你对此很感兴趣，并且打算深入了解这些，你会发现通过注解驱动代码生成非常有趣。**有时候并不一定要有漂亮的读写，**但是人们会利用这些工具创造出漂亮的代码。假如你对于实际场景如何应用依赖注入的原理很感兴趣的话，ButterKnife的源码是相当简单的。

---

[话题 #11 下的更多文章](http://objccn.io/issue-11)
 
原文 [Dependency Injection, Annotations, and why Java is Better Than you Think it is #11](http://www.objc.io/issue-11/dependency-injection-in-java.html)