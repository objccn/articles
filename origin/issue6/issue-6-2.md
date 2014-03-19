[Source](http://www.objc.io/issue-6/compiler.html "Permalink to The Compiler - Build Tools - objc.io issue #6 ")

# The Compiler - Build Tools - objc.io issue #6 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# The Compiler

[Issue #6 Build Tools][4], November 2013

By [Chris Eidhof][5]

## What Does a Compiler Do?

In this article we’ll have a look at what a compiler does, and how we can use that to our advantage.

Roughly speaking, the compiler has two tasks: converting our Objective-C code into low-level code, and analyzing our code to make sure we didn’t make any obvious mistakes.

These days, Xcode ships with clang as the compiler. Wherever we write compiler, you can read it as clang. clang is the tool that takes Objective-C code, analyzes it, and transforms it into a more low-level representation that resembles assembly code: LLVM Intermediate Representation. LLVM IR is low level, and operating system independent. LLVM takes instructions and compiles them into native bytecode for the target platform. This can either be done just-in-time or at the same time as compilation.

The nice thing about having those LLVM instructions is that you can generate and run them on any platform that is supported by LLVM. For example, if you write your iOS app, it automatically runs on two very different architectures (Intel and ARM), and it’s LLVM that takes care of translating the IR code into native bytecode for those platforms.

LLVM benefits from having a three-tier architecture, which means it supports a lot of input languages (e.g. C, Objective-C, and C%2B%2B, but also Haskell) in the first tier, then a shared optimizer in the second tier (which optimizes the LLVM IR), and different targets in the third tier (e.g. Intel, ARM, and PowerPC). If you want to add a language, you can focus on the first tier, and if you want to add another compilation target, you don’t have to worry too much about the input languages. In the book _The Architecture of Open Source Applications_ there’s a great chapter by LLVM’s creator, Chris Lattner, about the [LLVM architecture][6].

When compiling a source file, the compiler proceeds through several phases. To see the different phases, we can ask clang what it will do to compile the file _hello.m_:


    % clang -ccc-print-phases hello.m

    0: input, "hello.m", objective-c
    1: preprocessor, {0}, objective-c-cpp-output
    2: compiler, {1}, assembler
    3: assembler, {2}, object
    4: linker, {3}, image
    5: bind-arch, "x86_64", {4}, image

In this article, we’ll focus on phases one and two. In [Mach-O Executables][7], Daniel explains phases three and four.

### Preprocessing

The first thing that happens when you’re compiling a source file is preprocessing. The preprocessor handles a macro processing language, which means it will replace macros in your text by their definitions. For example, if you write the following:


    #import 

The preprocessor will take that line, and substitute it with the contents of that file. If that header file contains any other macro definitions, they will get substituted too.

This is the reason why people tell you to keep your header files free of imports as much as you can, because anytime you import something, the compiler has to do more work. For example, in your header file, instead of writing:


    #import "MyClass.h"

You could write:


    @class MyClass;

And by doing that you promise the compiler that there will be a class, `MyClass`. In the implementation file (the `.m` file), you can then import the `MyClass.h` and use it.

Now suppose we have a very simple pure C program, named `hello.c`:


    #include 

    int main() {
      printf("hello world
    ");
      return 0;
    }

We can run the preprocessor on this to see what the effect is:


    clang -E hello.c | less

Now, have a look at that code. It’s 401 lines. If we also add the following line to the top:


    #import 

We can run the command again, and see that our file has expanded to a whopping 89,839 lines. There are entire operating systems written in less lines of code.

Luckily, the situation has recently improved a bit. There’s now a feature called [modules][8] that makes this process a bit more high level.

#### Custom Macros

Another example is when you define or use custom macros, like this:


    #define MY_CONSTANT 4

Now, anytime you write `MY_CONSTANT` after this line, it’ll get replaced by `4` before the rest of compilation starts. You can also define more interesting macros that take arguments:


    #define MY_MACRO(x) x

This article is too short to discuss the full scope of what is possible with the preprocessor, but it’s a very powerful tool. Often, the preprocessor is used to inline code. We strongly discourage this. For example, suppose you have the following innocent-looking program:


    #define MAX(a,b) a > b ? a : b

    int main() {
      printf("largest: %d
    ", MAX(10,100));
      return 0;
    }

This will work fine. However, what about the following program:


    #define MAX(a,b) a > b ? a : b

    int main() {
      int i = 200;
      printf("largest: %d
    ", MAX(i%2B%2B,100));
      printf("i: %d
    ", i);
      return 0;
    }

If we compile this with `clang max.c`, we get the following result:


    largest: 201
    i: 202

This is quite obvious when we run the preprocessor and expand all the macros by issuing `clang -E max.c`:


    int main() {
      int i = 200;
      printf("largest: %d
    ", i%2B%2B > 100 ? i%2B%2B : 100);
      printf("i: %d
    ", i);
      return 0;
    }

In this case, it’s an obvious example of what could go wrong with macros, but things can go also wrong in more unexpected and hard-to-debug ways. Instead of using a macro, you should use `static inline` functions:


    #include 

    static const int MyConstant = 200;

    static inline int max(int l, int r) {
       return l > r ? l : r;
    }

    int main() {
      int i = MyConstant;
      printf("largest: %d
    ", max(i%2B%2B,100));
      printf("i: %d
    ", i);
      return 0;
    }

This will print the correct result (`i: 201`). Because the code is inlined, it will have the same performance as the macro variant, but it’s a lot less error-prone. Also, you can set breakpoints, have type checking, and avoid unexpected behavior.

The only time when macros are a reasonable solution is for logging, since you can use `__FILE__` and `__LINE__` and assert macros.

### Tokenization (Lexing)

After preprocessing is done, every source `.m` file now has a bunch of definitions. This text is converted from a string to a stream of tokens. For example, in the case of a simple Objective-C hello world program:


    int main() {
      NSLog(@"hello, %@", @"world");
      return 0;
    }

We can ask clang to dump the tokens for this program by issuing the following command: `clang -Xclang -dump-tokens hello.m`:


    int 'int'        [StartOfLine]  Loc=
    identifier 'main'        [LeadingSpace] Loc=
    l_paren '('             Loc=
    r_paren ')'             Loc=
    l_brace '{'      [LeadingSpace] Loc=
    identifier 'NSLog'       [StartOfLine] [LeadingSpace]   Loc=
    l_paren '('             Loc=
    at '@'          Loc=
    string_literal '"hello, %@"'            Loc=
    comma ','               Loc=
    at '@'   [LeadingSpace] Loc=
    string_literal '"world"'                Loc=
    r_paren ')'             Loc=
    semi ';'                Loc=
    return 'return'  [StartOfLine] [LeadingSpace]   Loc=
    numeric_constant '0'     [LeadingSpace] Loc=
    semi ';'                Loc=
    r_brace '}'      [StartOfLine]  Loc=
    eof ''          Loc=

We can see that each token consists of a piece of text and a source location. The source location is from before macro expansion, so that if something goes wrong, clang can point you to the right spot.

### Parsing

Now the interesting part starts: our stream of tokens is parsed into an abstract syntax tree. Because Objective-C is a rather complicated language, parsing is not always easy. After parsing, a program is now available as an abstract syntax tree: a tree that represents the original program. Suppose we have a program `hello.m`:


    #import 

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

When we issue `clang -Xclang -ast-dump -fsyntax-only hello.m`, we get the following result printed to our command line:


    @interface World- (void) hello;
    @end
    @implementation World
    - (void) hello (CompoundStmt 0x10372ded0 
      (CallExpr 0x10372dea0  'void'
        (ImplicitCastExpr 0x10372de88  'void (*)(NSString *, ...)' 
          (DeclRefExpr 0x10372ddd8  'void (NSString *, ...)' Function 0x1023510d0 'NSLog' 'void (NSString *, ...)'))
        (ObjCStringLiteral 0x10372de38  'NSString *'
          (StringLiteral 0x10372de00  'char [13]' lvalue "hello, world"))))


    @end
    int main() (CompoundStmt 0x10372e118 
      (DeclStmt 0x10372e090 
        0x10372dfe0 "World *world =
          (ImplicitCastExpr 0x10372e078  'World *' 
            (ObjCMessageExpr 0x10372e048  'id':'id' selector=new class='World'))")
      (ObjCMessageExpr 0x10372e0e8  'void' selector=hello
        (ImplicitCastExpr 0x10372e0d0  'World *' 
          (DeclRefExpr 0x10372e0a8  'World *' lvalue Var 0x10372dfe0 'world' 'World *'))))

Every node in the abstract syntax tree is annotated with the original source position, so that if there’s any problem later on, clang can warn about your program and give you the correct location.

##### See Also

  * [Introduction to the clang AST][9]

### Static Analysis

Once the compiler has an abstract syntax tree, it can perform analyses on that tree to help catch you errors, such as in type checking, where it checks whether your program is type correct. For example, when you send a message to an object, it checks if the object actually implements that message. Also, clang does more advanced analyses where it walks through your program to make sure you’re not doing anything weird.

#### Type Checking

Any time you write code, clang is there to help you check that you didn’t make any mistakes. One of the obvious things to check is if your program sends the correct messages to the correct objects and calls the correct functions on the correct values. If you have a plain `NSObject*`, you can’t just send it the `hello` message, as clang will report an error. Also, if you create a class `Test` that subclasses `NSObject`, like this:


    @interface Test : NSObject
    @end

And you then try to assign an object with a different type to that object, the compiler will help you and warn you that what you’re doing is probably not correct.

There are two types of typing: dynamic and static typing. Dynamic typing means that a type is checked at runtime, and static typing means that the types are checked at compile time. In the past, you could always send any message to any object, and at runtime, it would be determined if the object responds to that message. When this is checked only at runtime, it’s called dynamic typing.

With static typing, this is checked at compile time. When you use ARC, the compiler checks a lot more types at compile time, because it needs to know which objects it works with. For example, you can not write the following code anymore:


    [myObject hello]

If there’s no `hello` method defined anywhere in your program.

#### Other Analyses

There are a lot of other analyses that clang does for you. If you clone the clang repository and go to `lib/StaticAnalyzer/Checkers`, you’ll see all the static checkers. For example, there’s `ObjCUnusedIVarsChecker.cpp`, which checks if ivars are unused. Or there is `ObjCSelfInitChecker.cpp`, which checks if you called [`self initWith...]` or [`super init]` before you start using `self` inside your initializer. Some of the other checks happen in other parts of the compiler. For example, in line 2,534 of `lib/Sema/SemaExprObjC.cpp`, you can see the line that does the following:


     Diag(SelLoc, diag::warn_arc_perform_selector_leaks);

Which produces the dreaded “performSelector may cause a leak because its selector is unknown” warning.

## Code Generation

Now, once your code is fully tokenized, parsed, and analyzed by clang, it can generate the LLVM code for you. To see what happens, we can have a look again at the program `hello.c`:


    #include 

    int main() {
      printf("hello world
    ");
      return 0;
    }

To compile this into LLVM bitcode (which is, most of the time, represented in a binary format) we can issue the following command:


    clang -O3 -emit-LLVM hello.c -c -o hello.bc

This generates a binary file that we can then inspect using another command:


    llvm-dis < hello.bc | less

Which gives us the following output:


    ; ModuleID = ''
    target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
    target triple = "x86_64-apple-macosx10.8.0"

    @str = private unnamed_addr constant [12 x i8] c"hello world"

    ; Function Attrs: nounwind ssp uwtable
    define i32 @main() #0 {
      %puts = tail call i32 @puts(i8* getelementptr inbounds ([12 x i8]* @str, i64 0, i64 0))
      ret i32 0
    }

    ; Function Attrs: nounwind
    declare i32 @puts(i8* nocapture) #1

    attributes #0 = { nounwind ssp uwtable }
    attributes #1 = { nounwind }

You can see that the `main` function is only two lines: one to print the string and one to return `0`.

It’s also interesting to do the same thing for a very simple Objective-C program `five.m` that we compile and then view using `LLVM-dis < five.bc | less`:


    #include 
    #import 

    int main() {
      NSLog(@"%@", [@5 description]);
      return 0;
    }

There are a lot more things going on around, but here’s the `main` function:


    define i32 @main() #0 {
      %1 = load %struct._class_t** @"L_OBJC_CLASSLIST_REFERENCES_$_", align 8
      %2 = load i8** @"L_OBJC_SELECTOR_REFERENCES_", align 8, !invariant.load !4
      %3 = bitcast %struct._class_t* %1 to i8*
      %4 = tail call %0* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to %0* (i8*, i8*, i32)*)(i8* %3, i8* %2, i32 5)
      %5 = load i8** @"L_OBJC_SELECTOR_REFERENCES_2", align 8, !invariant.load !4
      %6 = bitcast %0* %4 to i8*
      %7 = tail call %1* bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to %1* (i8*, i8*)*)(i8* %6, i8* %5)
      tail call void (%1*, ...)* @NSLog(%1* bitcast (%struct.NSConstantString* @_unnamed_cfstring_ to %1*), %1* %7)
      ret i32 0
    }

The most important lines are line 4, which creates the `NSNumber` object, line `7`, which sends the `description` message to the number object, and line 8, which logs the string returned from the `description` message.

### Optimizations

To see which kind of optimizations LLVM and clang can do, it’s interesting to look at a slightly more complicated C example, the recursively defined `factorial` function:


    #include 

    int factorial(int x) {
       if (x > 1) return x * factorial(x-1);
       else return 1;
    }

    int main() {
      printf("factorial 10: %d
    ", factorial(10));
    }

To compile this without optimizations, run the following command:


    clang -O0 -emit-llvm factorial.c  -c -o factorial.bc && llvm-dis < factorial.bc

The interesting part is to look at the code generated for the `factorial` function:


    define i32 @factorial(i32 %x) #0 {
      %1 = alloca i32, align 4
      %2 = alloca i32, align 4
      store i32 %x, i32* %2, align 4
      %3 = load i32* %2, align 4
      %4 = icmp sgt i32 %3, 1
      br i1 %4, label %5, label %11

    ; :5                                       ; preds = %0
      %6 = load i32* %2, align 4
      %7 = load i32* %2, align 4
      %8 = sub nsw i32 %7, 1
      %9 = call i32 @factorial(i32 %8)
      %10 = mul nsw i32 %6, %9
      store i32 %10, i32* %1
      br label %12

    ; :11                                      ; preds = %0
      store i32 1, i32* %1
      br label %12

    ; :12                                      ; preds = %11, %5
      %13 = load i32* %1
      ret i32 %13
    }

You can see that at the line marked with `%9`, it calls itself recursively. This is quite inefficient, because the stack increases with each recursive call. To turn on optimizations, we can pass the flag `-O3` to clang:


    clang -O3 -emit-llvm factorial.c  -c -o factorial.bc && llvm-dis < factorial.bc

Now the code for the `factorial` function looks like this:


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

Even though our function was not written in a [tail-recursive][10] way, clang can still optimize it and now it’s just one function with a loop. There are a lot more optimizations that clang will do on your code. A good example of what gcc can do is at [ridiculousfish.com][11].

**More Reading**

  * [LLVM blog: posts tagged ‘optimization’][12]
  * [LLVM blog: vectorization improvements][13]
  * [LLVM blog: greedy register allocation][14]
  * [The Polly project][15]

## How to Use this to Your Advantage

Now that we’ve seen a full compile, from tokenization to parsing, from abstract syntax trees to analysis and compilation, we can wonder: why should we care?

### Using libclang or clang Plugins

The cool thing about clang is that it’s open-source and a really well-built project: almost everything is a library. That means that it’s possible to create your own version of clang and only change those parts that you need. For example, you can change the way clang generates code, add better type checking, or perform your analyses. There are a lot of ways in which you can do this; the easiest way is by using a C library called [libclang][16]. libclang provides you with a simple C API to clang, and you can use it to analyze all your sources. However, in my experience, as soon as you want to do something that’s a bit more advanced, libclang is too limited. Also, there’s [ClangKit][17], which is an Objective-C wrapper around some of the functionality provided by clang.

Another way is to use the C%2B%2B library provided by clang by directly using LibTooling. This is a lot more work, and involves C%2B%2B, but gives you the full power of clang. You can do any kind of analyses, or even rewrite programs. If you want to add custom analyses to clang, want to write your own refactorer, need to rewrite a massive code base, or want to generate graphs and documentation from your project, LibTooling is your friend.

### Writing an Analyzer

Follow the instructions on [Tutorial for building tools using LibTooling][18] to build LLVM, clang, and clang-tools-extra. Be sure to leave some time aside for compilation; even though I have a very fast machine, I was still able to do the dishes during the time LLVM compiled.

Next, go to your LLVM directory and do a `cd ~/llvm/tools/clang/tools/`. In this directory, you can create your own standalone clang tools. As an example, we created a small tool to help us detect correct usage of a library. Clone the [example repository][19] into this directory, and type `make`. This will provide you with a binary called `example`.

Our use case is as follows: suppose we have an `Observer` class, which looks like this:


    @interface Observer
    %2B (instancetype)observerWithTarget:(id)target action:(SEL)selector;
    @end

Now, we want to check whenever this class is used that the `action` is a method that exists on the `target` object. We can write a quick C%2B%2B function that does this (be warned, this is the first C%2B%2B I ever wrote, so it’s definitely not idiomatic):


    virtual bool VisitObjCMessageExpr(ObjCMessageExpr *E) {
      if (E->getReceiverKind() == ObjCMessageExpr::Class) {
        QualType ReceiverType = E->getClassReceiver();
        Selector Sel = E->getSelector();
        string TypeName = ReceiverType.getAsString();
        string SelName = Sel.getAsString();
        if (TypeName == "Observer" && SelName == "observerWithTarget:action:") {
          Expr *Receiver = E->getArg(0)->IgnoreParenCasts();
          ObjCSelectorExpr* SelExpr = cast(E->getArg(1)->IgnoreParenCasts());
          Selector Sel = SelExpr->getSelector();
          if (const ObjCObjectPointerType *OT = Receiver->getType()->getAs()) {
            ObjCInterfaceDecl *decl = OT->getInterfaceDecl();
            if (! decl->lookupInstanceMethod(Sel)) {
              errs() 