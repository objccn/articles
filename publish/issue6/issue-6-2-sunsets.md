## 编译器做些什么？

本文主要探讨一下编译器主要做些什么，以及如何有效的利用编译器。

简单的说，编译器有两个职责：把 Objective-C 代码转化成低级代码，以及对代码做分析，确保代码中没有任何明显的错误。

现在，Xcode 的默认编译器是 clang。本文中我们提到的编译器都表示 clang。clang 的功能是首先对 Objective-C 代码做分析检查，然后将其转换为低级的类汇编代码：LLVM Intermediate Representation(LLVM 中间表达码)。接着 LLVM 会执行相关指令将 LLVM IR 编译成目标平台上的本地字节码，这个过程的完成方式可以是即时编译 (Just-in-time)，或在编译的时候完成。

LLVM 指令的一个好处就是可以在支持 LLVM 的任意平台上生成和运行 LLVM 指令。例如，你写的一个 iOS app, 它可以自动的运行在两个完全不同的架构(Inter 和 ARM)上，LLVM 会根据不同的平台将 IR 码转换为对应的本地字节码。

LLVM 的优点主要得益于它的三层式架构 -- 第一层支持多种语言作为输入(例如 C, ObjectiveC, C++ 和 Haskell)，第二层是一个共享式的优化器(对 LLVM IR 做优化处理)，第三层是许多不同的目标平台(例如 Intel, ARM 和 PowerPC)。在这三层式的架构中，如果你想要添加一门语言到 LLVM 中，那么可以把重要精力集中到第一层上，如果想要增加另外一个目标平台，那么你没必要过多的考虑输入语言。在书 *The Architecture of Open Source Applications* 中 LLVM 的创建者 (Chris Lattner) 写了一章很棒的内容：关于 [LLVM 架构](http://www.aosabook.org/en/llvm.html)。

在编译一个源文件时，编译器的处理过程分为几个阶段。要想查看编译 *hello.m* 源文件需要几个不同的阶段，我们可以让通过 clang 命令观察：

    % clang -ccc-print-phases hello.m
    
    0: input, "hello.m", objective-c
    1: preprocessor, {0}, objective-c-cpp-output
    2: compiler, {1}, assembler
    3: assembler, {2}, object
    4: linker, {3}, image
    5: bind-arch, "x86_64", {4}, image

本文我们将重点关注第一阶段和第二阶段。在文章 [Mach-O Executables](http://objccn.io/issue-6-3/) 中，Daniel 会对第三阶段和第四阶段进行阐述。

### 预处理

每当编源译文件的时候，编译器首先做的是一些预处理工作。比如预处理器会处理源文件中的宏定义，将代码中的宏用其对应定义的具体内容进行替换。

例如，如果在源文件中出现下述代码：

    #import <Foundation/Foundation.h>

预处理器对这行代码的处理是用 Foundation.h 文件中的内容去替换这行代码，如果 Foundation.h 中也使用了类似的宏引入，则会按照同样的处理方式用各个宏对应的真正代码进行逐级替代。

这也就是为什么人们主张头文件最好尽量少的去引入其他的类或库，因为引入的东西越多，编译器需要做的处理就越多。例如，在头文件中用：

    @class MyClass;

代替：

    #import "MyClass.h"

这么写是告诉编译器 MyClass 是一个类，并且在 .m 实现文件中可以通过 import `MyClass.h` 的方式来使用它。

假设我们写了一个简单的 C 程序 `hello.c`:

    #include <stdio.h>

    int main() {
      printf("hello world\n");
      return 0;
    }

然后给上面的代码执行以下预处理命令，看看是什么效果：

    clang -E hello.c | less

接下来看看处理后的代码，一共是 401 行。如果将如下一行代码添加到上面代码的顶部：：

    #import <Foundation/Foundation.h>

再执行一下上面的预处理命令，处理后的文件代码行数暴增至 89,839 行。这个数字比某些操作系统的总代码行数还要多。

幸好，目前的情况已经改善许多了：引入了[模块 - modules](http://clang.llvm.org/docs/Modules.html)功能，这使预处理变得更加的高级。


####  自定义宏

我们来看看另外一种情形定义或者使用自定义宏，比如定义了如下宏：

    #define MY_CONSTANT 4

那么，凡是在此行宏定义作用域内，输入了 `MY_CONSTANT`，在预处理过程中 `MY_CONSTANT` 都会被替换成 `4`。我们定义的宏也是可以携带参数的， 比如：

    #define MY_MACRO(x) x

鉴于本文的内容所限，就不对强大的预处理做更多、更全面的展开讨论了。但是还是要强调一点，建议大家不要在需要预处理的代码中加入内联代码逻辑。

例如，下面这段代码，这样用没什么问题：

    #define MAX(a,b) a > b ? a : b

    int main() {
      printf("largest: %d\n", MAX(10,100));
      return 0;
    }

但是如果换成这么写：

    #define MAX(a,b) a > b ? a : b

    int main() {
      int i = 200;
      printf("largest: %d\n", MAX(i++,100));
      printf("i: %d\n", i);
      return 0;
    }

用 `clang max.c` 编译一下，结果是：

    largest: 201
    i: 202

用 `clang -E max.c` 进行宏展开的预处理结果是如下所示：

    int main() {
      int i = 200;
      printf("largest: %d\n", i++ > 100 ? i++ : 100);
      printf("i: %d\n", i);
      return 0;
    }

本例是典型的宏使用不当，而且通常这类问题非常隐蔽且难以 debug 。针对本例这类情况，最好使用 `static inline`:

    #include <stdio.h>
    static const int MyConstant = 200;
    
    static inline int max(int l, int r) {
       return l > r ? l : r;
    }
    
    int main() {
      int i = MyConstant;
      printf("largest: %d\n", max(i++,100));
      printf("i: %d\n", i);
      return 0;
    }

这样改过之后，就可以输出正常的结果 (`i:201`)。因为这里定义的代码是内联的 (inlined)，所以它的效率和宏变量差不多，但是可靠性比宏定义要好许多。再者，还可以设置断点、类型检查以及避免异常行为。

基本上，宏的最佳使用场景是日志输出，可以使用 `__FILE__` 和 `__LINE__` 和 assert 宏。

### 词法解析标记

预处理完成以后，每一个 `.m` 源文件里都有一堆的声明和定义。这些代码文本都会从 string 转化成特殊的标记流。

例如，下面是一段简单的 Objective-C hello word 程序：

    int main() {
      NSLog(@"hello, %@", @"world");
      return 0;
    }

利用 clang 命令 `clang -Xclang -dump-tokens hello.m` 来将上面代码的标记流导出：

    int 'int'        [StartOfLine]  Loc=<hello.m:4:1>
    identifier 'main'        [LeadingSpace] Loc=<hello.m:4:5>
    l_paren '('             Loc=<hello.m:4:9>
    r_paren ')'             Loc=<hello.m:4:10>
    l_brace '{'      [LeadingSpace] Loc=<hello.m:4:12>
    identifier 'NSLog'       [StartOfLine] [LeadingSpace]   Loc=<hello.m:5:3>
    l_paren '('             Loc=<hello.m:5:8>
    at '@'          Loc=<hello.m:5:9>
    string_literal '"hello, %@"'            Loc=<hello.m:5:10>
    comma ','               Loc=<hello.m:5:21>
    at '@'   [LeadingSpace] Loc=<hello.m:5:23>
    string_literal '"world"'                Loc=<hello.m:5:24>
    r_paren ')'             Loc=<hello.m:5:31>
    semi ';'                Loc=<hello.m:5:32>
    return 'return'  [StartOfLine] [LeadingSpace]   Loc=<hello.m:6:3>
    numeric_constant '0'     [LeadingSpace] Loc=<hello.m:6:10>
    semi ';'                Loc=<hello.m:6:11>
    r_brace '}'      [StartOfLine]  Loc=<hello.m:7:1>
    eof ''          Loc=<hello.m:7:2>

仔细观察可以发现，每一个标记都包含了对应的源码内容和其在源码中的位置。注意这里的位置是宏展开之前的位置，这样一来，如果编译过程中遇到什么问题，clang 能够在源码中指出出错的具体位置。

### 解析

接下来要说的东西比较有意思：之前生成的标记流将会被解析成一棵抽象语法树 (abstract syntax tree -- AST)。由于 Objective-C 是一门复杂的语言，因此解析的过程不简单。解析过后，源程序变成了一棵抽象语法树：一棵代表源程序的树。假设我们有一个程序 `hello.m`：

    #import <Foundation/Foundation.h>

    @interface World
    - (void)hello;
    @end
    
    @implementation World
    - (void)hello {
      NSLog(@"hello, world");
    }
    @end
    
    int main() {
       World* world = [World new];
       [world hello];
    }

当我们执行 clang 命令 `clang -Xclang -ast-dump -fsyntax-only hello.m` 之后，命令行中输出的结果如下所示：：

    @interface World- (void) hello;
    @end
    @implementation World
    - (void) hello (CompoundStmt 0x10372ded0 <hello.m:8:15, line:10:1>
      (CallExpr 0x10372dea0 <line:9:3, col:24> 'void'
        (ImplicitCastExpr 0x10372de88 <col:3> 'void (*)(NSString *, ...)' <FunctionToPointerDecay>
          (DeclRefExpr 0x10372ddd8 <col:3> 'void (NSString *, ...)' Function 0x1023510d0 'NSLog' 'void (NSString *, ...)'))
        (ObjCStringLiteral 0x10372de38 <col:9, col:10> 'NSString *'
          (StringLiteral 0x10372de00 <col:10> 'char [13]' lvalue "hello, world"))))
    
    
    @end
    int main() (CompoundStmt 0x10372e118 <hello.m:13:12, line:16:1>
      (DeclStmt 0x10372e090 <line:14:4, col:30>
        0x10372dfe0 "World *world =
          (ImplicitCastExpr 0x10372e078 <col:19, col:29> 'World *' <BitCast>
            (ObjCMessageExpr 0x10372e048 <col:19, col:29> 'id':'id' selector=new class='World'))")
      (ObjCMessageExpr 0x10372e0e8 <line:15:4, col:16> 'void' selector=hello
        (ImplicitCastExpr 0x10372e0d0 <col:5> 'World *' <LValueToRValue>
          (DeclRefExpr 0x10372e0a8 <col:5> 'World *' lvalue Var 0x10372dfe0 'world' 'World *'))))

在抽象语法树中的每个节点都标注了其对应源码中的位置，同样的，如果产生了什么问题，clang 可以定位到问题所在处的源码位置。

##### 延伸阅读

* [clang AST 介绍](http://clang.llvm.org/docs/IntroductionToTheClangAST.html)

### 静态分析

一旦编译器把源码生成了抽象语法树，编译器可以对这棵树做分析处理，以找出代码中的错误，比如类型检查：即检查程序中是否有类型错误。例如：如果代码中给某个对象发送了一个消息，编译器会检查这个对象是否实现了这个消息（函数、方法）。此外，clang 对整个程序还做了其它更高级的一些分析，以确保程序没有错误。

#### 类型检查

每当开发人员编写代码的时候，clang 都会帮忙检查错误。其中最常见的就是检查程序是否发送正确的消息给正确的对象，是否在正确的值上调用了正确的函数。如果你给一个单纯的 `NSObject*` 对象发送了一个 `hello` 消息，那么 clang 就会报错。同样，如果你创建了 `NSObject` 的一个子类 `Test`, 如下所示：

    @interface Test : NSObject
    @end

然后试图给这个子类中某个属性设置一个与其自身类型不相符的对象，编译器会给出一个可能使用不正确的警告。

一般会把类型分为两类：动态的和静态的。动态的在运行时做检查，静态的在编译时做检查。以往，编写代码时可以向任意对象发送任何消息，在运行时，才会检查对象是否能够响应这些消息。由于只是在运行时做此类检查，所以叫做动态类型。

至于静态类型，是在编译时做检查。当在代码中使用 ARC 时，编译器在编译期间，会做许多的类型检查：因为编译器需要知道哪个对象该如何使用。例如，如果 myObject 没有 hello 方法，那么就不能写如下这行代码了：

    [myObject hello]

#### 其他分析

clang 在静态分析阶段，除了类型检查外，还会做许多其它一些分析。如果你把 clang 的代码仓库 clone 到本地，然后进入目录 `lib/StaticAnalyzer/Checkers`，你会看到所有静态检查内容。比如 `ObjCUnusedIVarsChecker.cpp` 是用来检查是否有定义了，但是从未使用过的变量。而 `ObjCSelfInitChecker.cpp` 则是检查在 你的初始化方法中中调用 `self` 之前，是否已经调用 `[self initWith...]` 或 `[super init]` 了。编译器还进行了一些其它的检查，例如在 `lib/Sema/SemaExprObjC.cpp` 的 2,534 行，有这样一句：

    Diag(SelLoc, diag::warn_arc_perform_selector_leaks);

这个会生成严重错误的警告 “performSelector may cause a leak because its selector is unknown” 。

## 代码生成

clang 完成代码的标记，解析和分析后，接着就会生成 LLVM 代码。下面继续看看`hello.c`：

    #include <stdio.h>
    
    int main() {
      printf("hello world\n");
      return 0;
    }


要把这段代码编译成 LLVM 字节码（绝大多数情况下是二进制码格式），我们可以执行下面的命令：

    clang -O3 -emit-LLVM hello.c -c -o hello.bc

接着用另一个命令来查看刚刚生成的二进制文件：

    llvm-dis < hello.bc | less

输出如下：

    ; ModuleID = '<stdin>'
    target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
    target triple = "x86_64-apple-macosx10.8.0"
    
    @str = private unnamed_addr constant [12 x i8] c"hello world\00"
    
    ; Function Attrs: nounwind ssp uwtable
    define i32 @main() #0 {
      %puts = tail call i32 @puts(i8* getelementptr inbounds ([12 x i8]* @str, i64 0, i64 0))
      ret i32 0
    }
    
    ; Function Attrs: nounwind
    declare i32 @puts(i8* nocapture) #1
    
    attributes #0 = { nounwind ssp uwtable }
    attributes #1 = { nounwind }

在上面的代码中，可以看到 `main` 函数只有两行代码：一行输出string，另一行返回 `0`。

再换一个程序，拿 `five.m` 为例，对其做相同的编译，然后执行 `LLVM-dis < five.bc | less`:

    #include <stdio.h>
    #import <Foundation/Foundation.h>
    
    int main() {
      NSLog(@"%@", [@5 description]);
      return 0;
    }

抛开其他的不说，单看 `main` 函数：

    define i32 @main() #0 {
      %1 = load %struct._class_t** @"\01L_OBJC_CLASSLIST_REFERENCES_$_", align 8
      %2 = load i8** @"\01L_OBJC_SELECTOR_REFERENCES_", align 8, !invariant.load !4
      %3 = bitcast %struct._class_t* %1 to i8*
      %4 = tail call %0* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to %0* (i8*, i8*, i32)*)(i8* %3, i8* %2, i32 5)
      %5 = load i8** @"\01L_OBJC_SELECTOR_REFERENCES_2", align 8, !invariant.load !4
      %6 = bitcast %0* %4 to i8*
      %7 = tail call %1* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to %1* (i8*, i8*)*)(i8* %6, i8* %5)
      tail call void (%1*, ...)* @NSLog(%1* bitcast (%struct.NSConstantString* @_unnamed_cfstring_ to %1*), %1* %7)
      ret i32 0
    }

上面代码中最重要的是第 4 行，它创建了一个 `NSNumber` 对象。第 7 行，给这个 number 对象发送了一个  `description` 消息。第 8 行，将 `description` 消息返回的内容打印出来。

### 优化

要想了解 LLVM 的优化内容，以及 clang 能做哪些优化，我们先看一个略微复杂的 C 程序：这个函数主要是递归计算 `阶乘`：

    #include <stdio.h>
    
    int factorial(int x) {
       if (x > 1) return x * factorial(x-1);
       else return 1;
    }
    
    int main() {
      printf("factorial 10: %d\n", factorial(10));
    }

先看看不做优化的编译情况，执行下面命令：

    clang -O0 -emit-llvm factorial.c  -c -o factorial.bc && llvm-dis < factorial.bc

重点看一下针对 `阶乘` 部分生成的代码：

    define i32 @factorial(i32 %x) #0 {
      %1 = alloca i32, align 4
      %2 = alloca i32, align 4
      store i32 %x, i32* %2, align 4
      %3 = load i32* %2, align 4
      %4 = icmp sgt i32 %3, 1
      br i1 %4, label %5, label %11
    
    ; <label>:5                                       ; preds = %0
      %6 = load i32* %2, align 4
      %7 = load i32* %2, align 4
      %8 = sub nsw i32 %7, 1
      %9 = call i32 @factorial(i32 %8)
      %10 = mul nsw i32 %6, %9
      store i32 %10, i32* %1
      br label %12
    
    ; <label>:11                                      ; preds = %0
      store i32 1, i32* %1
      br label %12
    
    ; <label>:12                                      ; preds = %11, %5
      %13 = load i32* %1
      ret i32 %13
    }

看一下 `%9` 标注的那一行，这行代码正是递归调用阶乘函数本身，实际上这样调用是非常低效的，因为每次递归调用都要重新压栈。接下来可以看一下优化后的效果，可以通过这样的方式开启优化 -- 将 `-03` 标志传给 clang：

    clang -O3 -emit-llvm factorial.c  -c -o factorial.bc && llvm-dis < factorial.bc

现在 `阶乘` 计算相关代码编译后生成的代码如下：

    define i32 @factorial(i32 %x) #0 {
      %1 = icmp sgt i32 %x, 1
      br i1 %1, label %tailrecurse, label %tailrecurse._crit_edge
    
    tailrecurse:                                      ; preds = %tailrecurse, %0
      %x.tr2 = phi i32 [ %2, %tailrecurse ], [ %x, %0 ]
      %accumulator.tr1 = phi i32 [ %3, %tailrecurse ], [ 1, %0 ]
      %2 = add nsw i32 %x.tr2, -1
      %3 = mul nsw i32 %x.tr2, %accumulator.tr1
      %4 = icmp sgt i32 %2, 1
      br i1 %4, label %tailrecurse, label %tailrecurse._crit_edge
    
    tailrecurse._crit_edge:                           ; preds = %tailrecurse, %0
      %accumulator.tr.lcssa = phi i32 [ 1, %0 ], [ %3, %tailrecurse ]
      ret i32 %accumulator.tr.lcssa
    }


即便我们的函数并没有按照[尾递归](http://en.wikipedia.org/wiki/Tail_call)的方式编写，clang 仍然能对其做优化处理，让该函数编译的结果中只包含一个循环。当然 clang 能对代码进行的优化还有很多方面。可以看以下这个比较不错的 gcc 的优化例子[ridiculousfish.com](http://ridiculousfish.com/blog/posts/will-it-optimize.html)。

**延伸阅读**

* [LLVM blog: posts tagged 'optimization'](http://blog.llvm.org/search/label/optimization)
* [LLVM blog: vectorization improvements](http://blog.llvm.org/2013/05/llvm-33-vectorization-improvements.html)
* [LLVM blog: greedy register allocation](http://blog.llvm.org/2011/09/greedy-register-allocation-in-llvm-30.html)
* [The Polly project](http://polly.llvm.org/index.html)

## 如何在实际中应用这些特性

刚刚我们探讨了编译的全过程，从标记到解析，从抽象语法树到分析检查，再到汇编。读者不禁要问，为什么要关注这些？

### 使用 libclan g或 clang 插件

之所以 clang 很酷：是因为它是一个开源的项目、并且它是一个非常好的工程：几乎可以说全身是宝。使用者可以创建自己的 clang 版本，针对自己的需求对其进行改造。比如说，可以改变 clang 生成代码的方式，增加更强的类型检查，或者按照自己的定义进行代码的检查分析等等。要想达成以上的目标，有很多种方法，其中最简单的就是使用一个名为 [libclang](http://clang.llvm.org/doxygen/group__CINDEX.html) 的C类库。libclang 提供的 API 非常简单，可以对 C 和 clang 做桥接，并可以用它对所有的源码做分析处理。不过，根据我的经验，如果使用者的需求更高，那么 libclang 就不怎么行了。针对这种情况，推荐使用 [Clangkit](https://github.com/macmade/ClangKit)，它是基于 clang 提供的功能，用 Objective-C 进行封装的一个库。

最后，clang 还提供了一个直接使用 LibTooling 的 C++ 类库。这里要做的事儿比较多，而且涉及到 C++，但是它能够发挥 clang 的强大功能。用它你可以对源码做任意类型的分析，甚至重写程序。如果你想要给 clang 添加一些自定义的分析、创建自己的重构器 (refactorer)、或者需要基于现有代码做出大量修改，甚至想要基于工程生成相关图形或者文档，那么 LibTooling 是很好的选择。


### 自定义分析器

开发者可以按照 [Tutorial for building tools using LibTooling](http://clang.LLVM.org/docs/LibASTMatchersTutorial.html) 中的说明去构造 LLVM ，clang 以及 clan g的附加工具。需要注意的是，编译代码是需要花费一些时间的，即时机器已经很快了，但是在编译期间，我还是可以吃顿饭的。

接下来，进入到 LLVM 目录，然后执行命令`cd ~/llvm/tools/clang/tools/`。在这个目录中，可以创建自己独立的 clang 工具。例如，我们创建一个小工具，用来检查某个库是否正确使用。首先将 [样例工程](https://github.com/objcio/issue6-compiler-tool) 克隆到本地，然后输入 `make`。这样就会生成一个名为 `example` 的二进制文件。

我们的使用场景是：假如有一个 `Observer` 类, 代码如下所示：

    @interface Observer
    + (instancetype)observerWithTarget:(id)target action:(SEL)selector;
    @end

接下来，我们想要检查一下每当这个类被调用的时候，在 `target` 对象中是否都有对应的 `action` 方法存在。可以写个 C++ 函数来做这件事（注意，这是我第一次写 C++ 程序，可能不那么严谨）：

    virtual bool VisitObjCMessageExpr(ObjCMessageExpr *E) {
      if (E->getReceiverKind() == ObjCMessageExpr::Class) {
        QualType ReceiverType = E->getClassReceiver();
        Selector Sel = E->getSelector();
        string TypeName = ReceiverType.getAsString();
        string SelName = Sel.getAsString();
        if (TypeName == "Observer" && SelName == "observerWithTarget:action:") {
          Expr *Receiver = E->getArg(0)->IgnoreParenCasts();
          ObjCSelectorExpr* SelExpr = cast<ObjCSelectorExpr>(E->getArg(1)->IgnoreParenCasts());
          Selector Sel = SelExpr->getSelector();
          if (const ObjCObjectPointerType *OT = Receiver->getType()->getAs<ObjCObjectPointerType>()) {
            ObjCInterfaceDecl *decl = OT->getInterfaceDecl();
            if (! decl->lookupInstanceMethod(Sel)) {
              errs() << "Warning: class " << TypeName << " does not implement selector " << Sel.getAsString() << "\n";
              SourceLocation Loc = E->getExprLoc();
              PresumedLoc PLoc = astContext->getSourceManager().getPresumedLoc(Loc);
              errs() << "in " << PLoc.getFilename() << " <" << PLoc.getLine() << ":" << PLoc.getColumn() << ">\n";
            }
          }
        }
      }
      return true;
    }

上面的这个方法首先查找消息表达式， 以 `Observer` 作为接收者， `observerWithTarget:action:` 作为 selector，然后检查 target 中是否存在相应的方法。虽然这个例子有点儿刻意，但如果你想要利用 AST 对自己的代码库做某些检查，按照上面的例子来就可以了。

### clang的其他特性

clang还有许多其他的用途。比如，可以写编译器插件（例如，类似上面的检查器例子）并且动态的加载到编译器中。虽然我没有亲自实验过，但是我觉得在 Xcode 中应该是可行的。再比如，也可以通过编写 clang 插件来自定义代码样式（具体可以参见 [编译过程](http://objccn.io/issue-6-1/)）。

另外，如果想对现有的代码做大规模的重构， 而 Xcode 或 AppCode 本身集成的重构工具无法达你的要求，你完全可以用 clang 自己写个重构工具。听起来有点儿可怕，读读下面的文档和教程，你会发现其实没那么难。

最后，如果是真的有这种需求，你完全可以引导 Xcdoe 使用你自己编译的 clang 。再一次，如果你去尝试，其实这些事儿真的没想象中那么复杂，反而会发现许多个中乐趣。

##### 延伸阅读

* [Clang Tutorial](https://github.com/loarabia/Clang-tutorial)
* [X86_64 Assembly Language Tutorial](http://cocoafactory.com/blog/2012/11/23/x86-64-assembly-language-tutorial-part-1/)
* [Custom clang Build with Xcode (I)](http://clang-analyzer.llvm.org/xcode.html) 和 [(II)](http://stackoverflow.com/questions/3297986/using-an-external-xcode-clang-static-analyzer-binary-with-additional-checks)
* [Clang Tutorial (I)](http://kevinaboos.wordpress.com/2013/07/23/clang-tutorial-part-i-introduction/), [(II)](http://kevinaboos.wordpress.com/2013/07/23/clang-tutorial-part-ii-libtooling-example/) 和 [(III)](http://kevinaboos.wordpress.com/2013/07/29/clang-tutorial-part-iii-plugin-example/)
* [Clang Plugin Tutorial](http://getoffmylawnentertainment.com/blog/2011/10/01/clang-plugin-development-tutorial/)
* [LLVM blog: What every C programmer should know (I)](http://blog.llvm.org/2011/05/what-every-c-programmer-should-know.html) , [(II)](http://blog.llvm.org/2011/05/what-every-c-programmer-should-know_14.html) 和 [(III)](http://blog.llvm.org/2011/05/what-every-c-programmer-should-know_21.html)

---

 

原文: [The Compiler](http://www.objc.io/issue-6/compiler.html)

译文 [objc.io 第6期 编译器](https://github.com/answer-huang/objcio_cn/blob/master/%E7%BF%BB%E8%AF%91%E5%AE%8C%E6%88%90/Issue%20%236%20The%20Compiler%20%E7%BC%96%E8%AF%91%E5%99%A8.md)

精细校对 [@BeyondVincent](http://beyondvincent.com/)
