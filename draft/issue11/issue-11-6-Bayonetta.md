我坦白\: 我喜欢java.

真的，请相信我。

也许这并不会让你感到惊讶。但毕竟我确实参与编写过一本有关java程序的书，所以这句话足以让我自己震惊。当我开始编写Android应用的时候我还并不是一个喜欢java的人，当我开始编写[书呆子编程指南](http://www.bignerdranch.com/book/android_the_big_nerd_ranch_guide)的时候，我也很难称得上是粉丝，甚至当我们完成编写的时候，我也始终不能算是一名超级粉丝。

My beef was not original or well thought out, but here are my issues, roughly:

*    It’s verbose. There’s no shortened syntax for implementing callbacks, like blocks or lambdas, so you have to write a lot of boilerplate to implement even a simple interface. If you need an object that holds four things, you have to create a class with four named fields. 
*    It’s rigid. Writing sensible Java constantly requires you to specify exactly which exception you’re catching, to specify which type you’re taking in, to check and make sure that your references aren’t null, and to import every class you need to use. And while there is some flexibility at runtime, it’s nowhere close to what you get in the Objective-C runtime, much less something like Ruby or Python.

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

Add some inner classes and interfaces to the mix, and that is what I learned and worked with. Not the worst thing in the world to be writing, but other languages had features and flexibility that I wished that I had in Java. Never did I find myself writing code in another language and saying, “Man, I wish this were more like Java.”

My opinion has changed.

## Java独有的特性

Oddly enough, the tool that changed my mind is only popular because of problems that are peculiar to Java. Consider the following code:

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

Dependencies in Java are surprisingly strict things. Whenever I write a line of code like this:

            long basePay = EmployeeDatabase.getInstance()
               .getBasePay(employee);

I create a strict dependency on the `EmployeeDatabase` class. Not only that, but I also create a strict dependency on a particular method in `EmployeeDatabase`: the `getInstance()` method. In other languages, I might be able to swizzle or monkey patch this kind of thing. Not that that’s a great idea, necessarily, but it is at least possible. Not so in Java.

Other ways of creating a dependency are even more strict than that. Let’s say that instead, I wrote that line like this:

            long basePay = new EmployeeDatabase()
               .getBasePay(employee);

When I use the new keyword, I tie myself down in all the same ways I did with the static method, but I also add one more: calling `new EmployeeDatabase()` must always yield an instance of the `EmployeeDatabase` class. You can’t rewrite that constructor to return a mock subclass, no matter what you do.

## 依赖注入

The way we usually solve this problem is to use a technique called dependency injection. It’s not a technique unique to Java, but because of the aforementioned issues, Java is in particularly dire need of it. 

Dependency injection simply means receiving collaborators as constructor parameters instead of fetching them ourselves. So `Payroll` would look like this instead:

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

## Declarative Dependency Programming

All of that is just background for what I really want to talk about: dependency injectors.

(An aside: I know it’s a little odd to be two problems deep before actually discussing something nifty, but I hope you’ll bear with me. Understanding what Java gets right just requires more work than it does with other languages. It’s the nature of the beast.)

See, now that we are passing in dependencies through our constructors, our objects are more difficult to use and more difficult to change. Before I used dependency injection, I could use `Payroll` like this:

        new Payroll().getAfterTaxPay(employee);

Now, though, I have to write this:

        new Payroll(EmployeeDatabase.getInstance())
            .getAfterTaxPay(employee);

Plus, anytime I change `Payroll`’s dependencies, I have to change every place I write `new Payroll`, too.

A dependency injector allows me to forget about writing code to explicitly supply dependencies. Instead, I declaratively say what my dependencies are, and the tool worries about supplying them when they’re needed. There are a variety of dependency injection tools out there; for these examples, I’ll be using RoboGuice.

To do this, we use Java’s tool for describing code: the annotation. We declare our dependencies by simply annotating our constructor:

        @Inject
        public Payroll(EmployeeDatabase employeeDatabase) {
            mEmployeeDatabase = employeeDatabase;
        }

The `@Inject` annotation says, “To build an instance of `Payroll`, execute this constructor, passing in values for all of its parameters.” Then when I actually need a `Payroll` instance, I ask the dependency injector to build me one, like so:

        Payroll payroll = RoboGuice.getInjector(getContext())
            .getInstance(Payroll.class);

        long afterTaxPay = payroll.getAfterTaxPay(employee);

Once I’m constructing instances in this way, I can use the injector itself to configure how dependencies are satisfied. Do I want `EmployeeDatabase` to be a singleton? Do I want to use a customized subclass? All of this can be specified in one place. 

## The Wider World of Declarative Java

It’s an easily described tool, but it’s hard to overestimate how fundamental the gap is between Java with and without a dependency injector. Without a dependency injector, aggressive refactoring and test-driven development are laborious. With one, they are effortless. The only thing more indispensable to a Java developer than a dependency injector is a good IDE.

Still, it’s just the first taste of a wider set of possibilities. Most of the exciting new stuff for Android developers originating outside Google revolves around annotation-based APIs. 

Take ButterKnife, for example. We spend a lot of time in Android wiring up listeners to view objects, like this:

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

## Compile Time vs. Runtime Annotation Processing

While some tools may achieve similar effects with annotations, Java allows them to achieve these effects in different ways. Take RoboGuice and Dagger, for example. Both are dependency injectors; both use the `@Inject` annotation. But where RoboGuice reads your code annotations at runtime, Dagger reads them at compile time and generates code.

This has a few important benefits. It means that errors in your annotation semantics can be detected early. Dagger can tell you at compile time when you have a circular dependency; RoboGuice cannot.

It can also improve performance. Generated code can reduce startup time and eliminate the need to read annotations at runtime. Reading annotation requires the use of Java’s reflection APIs, which can be expensive on some Android devices. 

### An Example of Runtime Annotation Processing

I’d like to finish up by showing a simple example of how one might define and process a runtime annotation. Let’s say that you were an exceptionally impatient person and were tired of typing out fully qualified static constants in your Android codebase, constants like these:

    public class CrimeActivity {
        public static final String ACTION_VIEW_CRIME = 
            “com.bignerdranch.android.criminalintent.CrimeActivity.ACTION_VIEW_CRIME”;
    }

You could use a runtime annotation to do this work for you. First, you’d create the annotation class:

    @Retention(RetentionPolicy.RUNTIME)
    @Target( { ElementType.FIELD })
    public @interface ServiceConstant { }
    
This code declares an annotation named `ServiceConstant`. The code is itself annotated with two annotations: `@Retention`, and `@Target`. `@Retention` says how long the annotation will stick around. Here, we say that we want to see it at runtime. If we wanted this annotation to be processed at compile time only, we could have specified `RetentionPolicy.SOURCE`.

The other annotation, `@Target`, says where you can put the annotation in your source code. Any number of values can be provided. Our annotation is only valid for fields, so we have just provided `ElementType.FIELD`.

Once the annotation is defined, we write some code to look for it and populate the annotated field automatically:

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

    public class CrimeActivity {
        @ServiceConstant
        public static final String ACTION_VIEW_CRIME;
    
        static {
            ServiceUtils.populateConstants(CrimeActivity.class);
    }

## 总结

这些是我了解的全部内容. So much for annotations in Java. I can’t say that I’m sure that all this has made you feel the same way as I do about Java, but I hope that you’ve seen some interesting stuff. While day-to-day Java may be lacking a bit in expressivity, there are a few basic building blocks in the Java kit that make it possible for advanced developers to create powerful tools that amplify the productivity of the entire community. 

If you’re interested in diving in deeper, you will find the topic of driving code generation with annotations very interesting. It’s not necessarily pretty to read or write, but folks are doing some nifty work out there with the tools as they are. The source for ButterKnife is reasonably simple, if you’re interested in an example of how it’s done in the real world.
