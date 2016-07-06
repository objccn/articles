我坦白\: 我喜欢 Java。

我真的喜欢！

也许这并不会让你感到吃惊，因为我毕竟确实参与编著过一本满是 Java 代码的书。但是事实上，当我开始编写 Android 应用的时候我并不是一个喜欢 Java 的人，而当我开始编写[书虫编程指南](http://www.bignerdranch.com/book/android_the_big_nerd_ranch_guide)的时候，我也很难称得上是粉丝，甚至当我们完成编写的时候，我也始终不能算是一名超级粉丝。这个事实其实让我自己都很吃惊！

我原本并非想抱怨什么，也并非要深刻反思一番。但是下面列出的这些内容却是一直困扰我的问题：

*   Java 很冗长。没有任何简短的类似 Blocks 或者 Lambda 表达式的语法来执行回调（当然，Java8已经开始支持这一特性），所以你必须编写非常多的模板代码来实现，有时甚至只是一个简单的接口。如果你需要一个对象来保存四个属性，你必须创建一个拥有四个命名字段的类。

*   Java 很死板。要编写清楚的Java程序, 你通常要正确的指定需要捕获的异常类型，以及要接受的参数类型，还有仔细检查并确保你的引用非空，甚至还要导入你所使用的每一个类。另外在运行时虽然有一定的灵活性，但是和 Objective-C 的 runtime 没有任何相似的地方，更不用说和 Ruby 或者 Python 相比了。

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

我学习过并且会在工作中混合使用一些内部类和接口。虽然编写Java程序这并不是世界上最糟糕的事情，但是我还是希望Java能够拥有其他语言的特点和灵活性。类似 “天啊，我多么希望这能更像 Java” 的感叹从没有出现过。

但是，我的想法改变了。

## Java 独有的特性

说来也奇怪，改变我想法的恰恰是 Java 独有的特性。请思考下面的代码:

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

这个类在 `getAfterTaxPay()` 方法中需要依赖一个 `EmployeeDatabase` 对象。有很多种方式可以创建该对象，但在这个例子中， 我使用了单例模式，调用一个静态的 getInstance 方法。

Java 中的依赖关系是非常严格的。所以任何时间我都像这样编写代码：

            long basePay = EmployeeDatabase.getInstance()
               .getBasePay(employee);

在 `EmployeeDatabase` 类中我创建了一个严格依赖。不仅如此，我是利用`EmployeeDatabase`类的特定方法 `getInstance()` 创建的严格依赖。而在其他语言里，我也许可以使用 swizzle 或者 monkey patch 的方式来处理这样的事情.当然并不是说这样的方法有什么好处，但它至少存在实现的可能。但是在 Java 里是不可能的。

而创建依赖的其他方式比这更加严格。就让我们来看看下面这行：

            long basePay = new EmployeeDatabase()
               .getBasePay(employee);

当使用关键字 new 时，我会采用与调用静态方法相同的方式，但有一点不同：调用 `new EmployeeDatabase()` 方法一定会返回给我们一个 `EmployeeDatabase` 类的实例。无论你如何努力，你都没有办法重写这个构造函数来让它返回一个 mock 的子类对象。

## 依赖注入

我们解决此类问题通常采用依赖注入技术。它并非 Java 独有的特性，但对于上述提到的问题，Java 尤其需要这个特性。

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

 `EmployeeDatabase` 是一个单例？一个模拟出来的子类？还是一个上下文相关的实现？ `Payroll` 类不再需要知道这些。

## 用声明依赖进行编程

上述这些仅仅介绍了我真正要讲的内容——依赖注入器。

（旁白：我知道在真正开始讨论前将这两个问题讲的比较深入是很奇怪的，但是我希望你们能够容忍我这么做。正确的理解 Java 比起其他语言要花费更多地时间。困难的事物往往都是这样。）

现在我们通过构造函数传递依赖，会导致我们的对象更加难以使用，同时也很难作出更改。在我使用依赖注入之前，我会像这样使用 `Payroll` 类:

        new Payroll().getAfterTaxPay(employee);

但是，现在我必须这样写:

        new Payroll(EmployeeDatabase.getInstance())
            .getAfterTaxPay(employee);

还有，任何时候如何我改变了 `Payroll` 的依赖, 我都不得不修改使用了 `new Payroll` 的每一个地方。

而依赖注入器允许我不再编写用来明确提供依赖的代码。相反，我可以直接声明我的依赖对象，让工具来自动处理相应操作。有很多依赖注入的工具，下面我将用 RoboGuice 来举个例子。 

为了这样做，我使用“注解“这一 Java 工具来描述代码。我们通过为构造函数添加简单的注解声明:

        @Inject
        public Payroll(EmployeeDatabase employeeDatabase) {
            mEmployeeDatabase = employeeDatabase;
        }

注解 `@Inject` 的含义是“创建一个 `Payroll` 类的实例，执行它的构造方法，传递所有的参数值。”而之后当我真的需要一个 `Payroll` 实例的时候，我会利用依赖注入器来帮我创建，就像这样：
 
        Payroll payroll = RoboGuice.getInjector(getContext())
            .getInstance(Payroll.class);

        long afterTaxPay = payroll.getAfterTaxPay(employee);

一旦我采用这种方式创建实例，就能使用注入器来设置足够令人满意的依赖。是否需要 `EmployeeDatabase` 是一个单例？是否需要一个可自定义的子类？所有这些都可以在同一个地方指定。

## 声明式 Java 的广阔世界

这是一种很容易使用的描述工具，但是很难比较在 Java 中是否使用依赖注入的根本差距。如果没有依赖注入器，重构和测试驱动开发会是一项艰苦的劳动。而使用它，这些工作则会毫不费力。对于一名 Java 开发者来说，唯一比依赖注入器更重要的就是一个优秀的 IDE 了。

不过，这只是广泛可能性中的第一点。 对于 Google 之外的 Android 开发者来说，最令人兴奋的就是基于注解的 API 了。

举个例子，我们可以使用 ButtreKnife。通常情况下，我们会花费大量的时间为 Android 的视图对象编写监听器，就像这样：

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
        // 处理按钮点击
    }

ButterKnife 允许我们只提供很少的代码来描述“在 ID 为 `R.id.ok_button` 的视图控件被点击时调用 `onOkButtonClicked` 方法”这件事情，就像这样：

    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_content);

        ButterKnife.inject(this);
    }

    @OnClick(R.id.ok_button);
    public void onOkButtonClicked() {
        // 处理按钮点击
    }

我能继续写很多这样的例子。有很多库可以通过注解来实现序列化与反序列化 Json，在 `savedInstanceState` 方法内部存储字段，或者是生成 REST 网络服务的接口代码等操作。

## 编译时和运行时注解处理对比

尽管有些使用注解的工具会产生相似的效果，不过 Java 允许使用不同的方式实现。下面我用 RoboGuice 和 Dagger 来举个例子。它们都是依赖注入器，也同样都使用 `@Inject` 注解。但是 RoboGuice 会在运行时读取你的代码注解，而 Dragger 则是在编译时生成对应的代码。

这样会有一些重要的好处。它能在更早的时间发现注解中的语义错误。Dagger 能够在编译时提醒你可能存在的循环依赖，但是 RoboGuice 不能。

而且这对提高性能也很有帮助。使用预先生成的代码可以减少启动时间，并在运行时避免读取注解。因为读取注解需要使用 Java 反射相关的 API，这在 Android 设备上是很耗时的。 

### 运行时进行注解处理的例子

我会通过展示一个如何定义和处理运行时注解的简单例子，来结束今天的内容。 假设你是一个很没有耐心地人，并且厌倦了在你的 Android 程序中打出一个完整的静态限定常量，比如：

    public class CrimeActivity {
        public static final String ACTION_VIEW_CRIME = 
            “com.bignerdranch.android.criminalintent.CrimeActivity.ACTION_VIEW_CRIME”;
    }

你可以使用一个运行时注解来帮你做这些事情。首先，你要创建一个注解类：

    @Retention(RetentionPolicy.RUNTIME)
    @Target( { ElementType.FIELD })
    public @interface ServiceConstant { }
    
这段代码声明了一个名为 `ServiceConstant` 的注解。 而代码本身被 `@Retention`、`@Target` 注解。`@Retention` 表示注解将会停留的时间。在这里我们将它设置为运行时触发。如果我们想仅仅在编译时处理注解，可以将其设置为 `RetentionPolicy.SOURCE`。

另一个注解 `@Target`，表示你放置注解的位置。当然有很多的数据类型可以选择。因为我们的注解仅需要对字段有效，所以只需要提供 `ElementType.FIELD` 的声明。

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
    
最后，我们为代码增加注解，然后调用我们充满魔力的方法：

    public class CrimeActivity {
        @ServiceConstant
        public static final String ACTION_VIEW_CRIME;
    
        static {
            ServiceUtils.populateConstants(CrimeActivity.class);
    }

## 总结

这些就是我了解的全部内容。有太多与 Java 注解相关的部分。我不能保证所有这些能够立刻让你对 Java 的感受变得和我一样，但是我希望你能确实看到很多有趣的东西。虽然通常 Java 在表达性上还欠缺一些，但是在 Java 的工具包中有一些基本的构建模块，能够让高级开发人员可以构建更强大的工具，从而扩大整个社区的生产力。

如果你对此很感兴趣，并且打算深入了解这些，你会发现通过注解驱动代码生成的过程非常有趣。有时候并不一定要真的阅读或者写出漂亮的代码，但是人们可以利用这些工具创造出漂亮的代码。假如你对于实际场景如何应用依赖注入的原理很感兴趣的话，ButterKnife 的源码还是相当简单的。

---

 
 
原文 [Dependency Injection, Annotations, and why Java is Better Than you Think it is](http://www.objc.io/issue-11/dependency-injection-in-java.html)
