我们用 Xcode 构建一个程序的过程中，会把源文件 (`.m` 和 `.h`) 文件转换为一个可执行文件。这个可执行文件中包含的字节码会将被 CPU (iOS 设备中的 ARM 处理器或 Mac 上的 Intel 处理器) 执行。

本文将介绍一下上面的过程中编译器都做了些什么，同时深入看看可执行文件内部是怎样的。实际上里面的东西要比我们第一眼看到的多得多。

这里我们把 Xcode 放一边，将使用命令行工具 (command-line tools)。当我们用 Xcode 构建一个程序时，Xcode 只是简单的调用了一系列的工具而已。Florian 对工具调用是如何工作的做了更详细的讨论。本文我们就直接调用这些工具，并看看它们都做了些什么。

真心希望本文能帮助你更好的理解 iOS 或 OS X 中的一个可执行文件 (也叫做 *Mach-O executable*) 是如何执行，以及怎样组装起来的。

## xcrun

先来看一些基础性的东西：这里会大量使用一个名为 `xcrun` 的命令行工具。看起来可能会有点奇怪，不过它非常的出色。这个小工具用来调用别的一些工具。原先，我们在终端执行如下命令：

    % clang -v

现在我们用下面的命令代替：

    % xcrun clang -v

在这里 `xcrun` 做的是定位到 `clang`，并执行它，附带输入 `clang` 后面的参数。

我们为什么要这样做呢？看起来没有什么意义。不过 `xcode` 允许我们: (1) 使用多个版本的 Xcode，以及使用某个特定 Xcode 版本中的工具。(2) 针对某个特定的 SDK (software development kit) 使用不同的工具。如果你有 Xcode 4.5 和 Xcode 5，通过 `xcode-select` 和 `xcrun` 可以选择使用 Xcode 5 中 iOS SDK 的工具，或者 Xcode 4.5 中的 OS X 工具。在许多其它平台中，这是不可能做到的。查阅 `xcrun` 和 `xcode-select` 的主页内容可以了解到详细内容。不用安装 *Command Line Tools*，就能使用命令行中的开发者工具。

## 不使用 IDE 的 Hello World

回到终端 (Terminal)，创建一个包含一个 C 文件的文件夹：

    % mkdir ~/Desktop/objcio-command-line
    % cd !$
    % touch helloworld.c

接着使用你喜欢的文本编辑器来编辑这个文件 -- 例如 TextEdit.app：

    % open -e helloworld.c

输入如下代码：

    #include <stdio.h>
    int main(int argc, char *argv[])
    {
        printf("Hello World!\n");
        return 0;
    }

保存并返回到终端，然后运行如下命令：

    % xcrun clang helloworld.c
    % ./a.out

现在你能够在终端上看到熟悉的 `Hello World!`。这里我们编译并运行 C 程序，全程没有使用 IDE。深呼吸一下，高兴高兴。

上面我们到底做了些什么呢？我们将 `helloworld.c` 编译为一个名为 `a.out` 的 Mach-O 二进制文件。注意，如果我们没有指定名字，那么编译器会默认的将其指定为 a.out。

这个二进制文件是如何生成的呢？实际上有许多内容需要观察和理解。我们先看看编译器吧。

### Hello World 和编译器

时下 Xcode 中编译器默认选择使用 `clang`(读作 /klæŋ/)。[关于编译器](http://objccn.io/issue-6-2/)，Chris 写了更详细的文章。

简单的说，编译器处理过程中，将 `helloworld.c` 当做输入文件，并生成一个可执行文件 `a.out`。这个过程有多个步骤/阶段。我们需要做的就是正确的执行它们。

##### 预处理

* 符号化 (Tokenization)
* 宏定义的展开
* `#include` 的展开

##### 语法和语义分析

* 将符号化后的内容转化为一棵解析树 (parse tree)
* 解析树做语义分析
* 输出一棵*抽象语法树*（Abstract Syntax Tree* (AST)）

##### 生成代码和优化

* 将 AST 转换为更低级的中间码 (LLVM IR)
* 对生成的中间码做优化
* 生成特定目标代码
* 输出汇编代码

##### 汇编器

* 将汇编代码转换为目标对象文件。

##### 链接器

* 将多个目标对象文件合并为一个可执行文件 (或者一个动态库)

我们来看一个关于这些步骤的简单的例子。

#### 预处理

编译过程中，编译器首先要做的事情就是对文件做处理。预处理结束之后，如果我们停止编译过程，那么我们可以让编译器显示出预处理的一些内容：

    % xcrun clang -E helloworld.c

喔喔。 上面的命令输出的内容有 413 行。我们用编辑器打开这些内容，看看到底发生了什么：

    % xcrun clang -E helloworld.c | open -f

在顶部可以看到的许多行语句都是以 `#` 开头 (读作 `hash`)。这些被称为 *行标记* 的语句告诉我们后面跟着的内容来自哪里。如果再回头看看 `helloworld.c` 文件，会发现第一行是：

    #include <stdio.h>

我们都用过 `#include` 和 `import`。它们所做的事情是告诉预处理器将文件 `stdio.h` 中的内容插入到 `#include` 语句所在的位置。这是一个递归的过程：`stdio.h` 可能会包含其它的文件。

由于这样的递归插入过程很多，所以我们需要确保记住相关行号信息。为了确保无误，预处理器在发生变更的地方插入以 `#` 开头的 `行标记`。跟在 `#` 后面的数字是在源文件中的行号，而最后的数字是在新文件中的行号。回到刚才打开的文件，紧跟着的是系统头文件，或者是被看做为封装了 `extern "C"` 代码块的文件。

如果滚动到文件末尾，可以看到我们的 `helloworld.c` 代码：

    # 2 "helloworld.c" 2
    int main(int argc, char *argv[])
    {
     printf("Hello World!\n");
     return 0;
    }

在 Xcode 中，可以通过这样的方式查看任意文件的预处理结果：**Product** -> **Perform Action** -> **Preprocess**。注意，编辑器加载预处理后的文件需要花费一些时间 -- 接近 100,000 行代码。

#### 编译

下一步：分析和代码生成。我们可以用下面的命令让 `clang` 输出汇编代码：

    % xcrun clang -S -o - helloworld.c | open -f

我们来看看输出的结果。首先会看到有一些以点 `.` 开头的行。这些就是汇编指令。其它的则是实际的 x86_64 汇编代码。最后是一些标记 (label)，与 C 语言中的类似。

我们先看看前三行：

        .section    __TEXT,__text,regular,pure_instructions
        .globl  _main
        .align  4, 0x90

这三行是汇编指令，不是汇编代码。`.section` 指令指定接下来会执行哪一个段。

第二行的 `.globl` 指令说明 `_main` 是一个外部符号。这就是我们的 `main()` 函数。这个函数对于二进制文件外部来说是可见的，因为系统要调用它来运行可执行文件。

`.align` 指令指出了后面代码的对齐方式。在我们的代码中，后面的代码会按照 16(2^4) 字节对齐，如果需要的话，用 `0x90` 补齐。

接下来是 main 函数的头部：

    _main:                                  ## @main
        .cfi_startproc
    ## BB#0:
        pushq   %rbp
    Ltmp2:
        .cfi_def_cfa_offset 16
    Ltmp3:
        .cfi_offset %rbp, -16
        movq    %rsp, %rbp
    Ltmp4:
        .cfi_def_cfa_register %rbp
        subq    $32, %rsp

上面的代码中有一些与 C 标记工作机制一样的一些标记。它们是某些特定部分的汇编代码的符号链接。首先是 `_main` 函数真正开始的地址。这个符号会被 export。二进制文件会有这个位置的一个引用。

`.cfi_startproc` 指令通常用于函数的开始处。CFI 是调用帧信息 (Call Frame Information) 的缩写。这个调用 `帧` 以松散的方式对应着一个函数。当开发者使用 debugger 和 *step in* 或 *step out* 时，实际上是 stepping in/out 一个调用帧。在 C 代码中，函数有自己的调用帧，当然，别的一些东西也会有类似的调用帧。`.cfi_startproc` 指令给了函数一个 `.eh_frame` 入口，这个入口包含了一些调用栈的信息（抛出异常时也是用其来展开调用帧堆栈的）。这个指令也会发送一些和具体平台相关的指令给 CFI。它与后面的 `.cfi_endproc` 相匹配，以此标记出 `main()` 函数结束的地方。

接着是另外一个 label `## BB#0:`。然后，终于，看到第一句汇编代码：`pushq %rbp`。从这里开始事情开始变得有趣。在 OS X上，我们会有 X86_64 的代码，对于这种架构，有一个东西叫做 *ABI* ( 应用二进制接口 application binary interface)，ABI 指定了函数调用是如何在汇编代码层面上工作的。在函数调用期间，ABI 会让 `rbp` 寄存器 (基础指针寄存器 base pointer register) 被保护起来。当函数调用返回时，确保 `rbp` 寄存器的值跟之前一样，这是属于 main 函数的职责。`pushq %rbp` 将 `rbp` 的值 push 到栈中，以便我们以后将其 pop 出来。

接下来是两个 CFI 指令：`.cfi_def_cfa_offset 16` 和 `.cfi_offset %rbp, -16`。这将会输出一些关于生成调用堆栈展开和调试的信息。我们改变了堆栈和基础指针，而这两个指令可以告诉编译器它们都在哪儿，或者更确切的，它们可以确保之后调试器要使用这些信息时，能找到对应的东西。

接下来，`movq %rsp, %rbp` 将把局部变量放置到栈上。`subq $32, %rsp` 将栈指针移动 32 个字节，也就是函数会调用的位置。我们先将老的栈指针存储到 `rbp` 中，然后将此作为我们局部变量的基址，接着我们更新堆栈指针到我们将会使用的位置。

之后，我们调用了 `printf()`：

    leaq    L_.str(%rip), %rax
    movl    $0, -4(%rbp)
    movl    %edi, -8(%rbp)
    movq    %rsi, -16(%rbp)
    movq    %rax, %rdi
    movb    $0, %al
    callq   _printf

首先，`leaq` 会将 `L_.str` 的指针加载到 `rax` 寄存器中。留意 `L_.str` 标记在后面的汇编代码中是如何定义的。它就是 C 字符串`"Hello World!\n"`。 `edi` 和 `rsi` 寄存器保存了函数的第一个和第二个参数。由于我们会调用别的函数，所以首先需要将它们的当前值保存起来。这就是为什么我们使用刚刚存储的 `rbp` 偏移32个字节的原因。第一个 32 字节的值是 0，之后的 32 字节的值是 `edi` 寄存器的值 (存储了 `argc`)。然后是 64 字节 的值：`rsi` 寄存器的值 (存储了 `argv`)。我们在后面并没有使用这些值，但是编译器在没有经过优化处理的时候，它们还是会被存下来。

现在我们把第一个函数 `printf()` 的参数 `rax` 设置给第一个函数参数寄存器 `edi` 中。`printf()` 是一个可变参数的函数。ABI 调用约定指定，将会把使用来存储参数的寄存器数量存储在寄存器 `al` 中。在这里是 0。最后 `callq` 调用了 `printf()` 函数。

        movl    $0, %ecx
        movl    %eax, -20(%rbp)         ## 4-byte Spill
        movl    %ecx, %eax

上面的代码将 `ecx` 寄存器设置为 0，并把 `eax` 寄存器的值保存至栈中，然后将 `ect` 中的 0 拷贝至 `eax` 中。ABI 规定 `eax` 将用来保存一个函数的返回值，或者此处 `main()` 函数的返回值 0：

        addq    $32, %rsp
        popq    %rbp
        ret
        .cfi_endproc

函数执行完成后，将恢复堆栈指针 —— 利用上面的指令 `subq $32, %rsp` 把堆栈指针 `rsp` 上移 32 字节。最后，把之前存储至 `rbp` 中的值从栈中弹出来，然后调用 `ret` 返回调用者， `ret` 会读取出栈的返回地址。 `.cfi_endproc` 平衡了 `.cfi_startproc` 指令。

接下来是输出字符串 `"Hello World!\n"`:

        .section    __TEXT,__cstring,cstring_literals
    L_.str:                                 ## @.str
        .asciz   "Hello World!\n"

同样，`.section` 指令指出下面将要进入的段。`L_.str` 标记运行在实际的代码中获取到字符串的一个指针。`.asciz` 指令告诉编译器输出一个以 ‘\0’ (null) 结尾的字符串。

`__TEXT __cstring` 开启了一个新的段。这个段中包含了 C 字符串：

    L_.str:                                 ## @.str
        .asciz     "Hello World!\n"

上面两行代码创建了一个 null 结尾的字符串。注意 `L_.str` 是如何命名，之后会通过它来访问字符串。

最后的 `.subsections_via_symbols` 指令是静态链接编辑器使用的。

更过关于汇编指令的资料可以在 苹果的 [OS X Assembler Reference](https://developer.apple.com/library/mac/documentation/DeveloperTools/Reference/Assembler/) 中看到。AMD 64 网站有关于 [ABI for x86 的文档](http://www.x86-64.org/documentation/abi.pdf)。另外还有 [Gentle Introduction to x86-64 Assembly](http://www.x86-64.org/documentation/assembly.html)。

重申一下，通过下面的选择操作，我们可以用 Xcode 查看任意文件的汇编输出结果：**Product** -> **Perform Action** -> **Assemble**.

#### 汇编器

汇编器将可读的汇编代码转换为机器代码。它会创建一个目标对象文件，一般简称为 *对象文件*。这些文件以 `.o` 结尾。如果用 Xcode 构建应用程序，可以在工程的 *derived data* 目录中，`Objects-normal` 文件夹下找到这些文件。

#### 链接器

稍后我们会对链接器做更详细的介绍。这里简单介绍一下：链接器解决了目标文件和库之间的链接。什么意思呢？还记得下面的语句吗：

    callq   _printf

`printf()` 是 *libc* 库中的一个函数。无论怎样，最后的可执行文件需要能需要知道 `printf()` 在内存中的具体位置：例如，`_printf` 的地址符号是什么。链接器会读取所有的目标文件 (此处只有一个) 和库 (此处是 *libc*)，并解决所有未知符号 (此处是 `_printf`) 的问题。然后将它们编码进最后的可执行文件中  （可以在 *libc* 中找到符号 `_printf`），接着链接器会输出可以运行的执行文件：`a.out`。

## Section

就像我们上面提到的一样，这里有些东西叫做 section。一个可执行文件包含多个段，也就是多个 section。可执行文件不同的部分将加载进不同的 section，并且每个 section 会转换进某个 segment 里。这个概念对于所有的可执行文件都是成立的。

我们来看看 `a.out` 二进制中的 section。我们可以使用 `size` 工具来观察：

    % xcrun size -x -l -m a.out 
    Segment __PAGEZERO: 0x100000000 (vmaddr 0x0 fileoff 0)
    Segment __TEXT: 0x1000 (vmaddr 0x100000000 fileoff 0)
        Section __text: 0x37 (addr 0x100000f30 offset 3888)
        Section __stubs: 0x6 (addr 0x100000f68 offset 3944)
        Section __stub_helper: 0x1a (addr 0x100000f70 offset 3952)
        Section __cstring: 0xe (addr 0x100000f8a offset 3978)
        Section __unwind_info: 0x48 (addr 0x100000f98 offset 3992)
        Section __eh_frame: 0x18 (addr 0x100000fe0 offset 4064)
        total 0xc5
    Segment __DATA: 0x1000 (vmaddr 0x100001000 fileoff 4096)
        Section __nl_symbol_ptr: 0x10 (addr 0x100001000 offset 4096)
        Section __la_symbol_ptr: 0x8 (addr 0x100001010 offset 4112)
        total 0x18
    Segment __LINKEDIT: 0x1000 (vmaddr 0x100002000 fileoff 8192)
    total 0x100003000

如上代码所示，我们的 `a.out` 文件有 4 个 segment。有些 segment 中有多个 section。

当运行一个可执行文件时，虚拟内存 (VM - virtual memory) 系统将 segment 映射到进程的地址空间上。映射完全不同于我们一般的认识，如果你对虚拟内存系统不熟悉，可以简单的想象虚拟内存系统将整个可执行文件加载进内存 -- 虽然在实际上不是这样的。VM 使用了一些技巧来避免全部加载。

当虚拟内存系统进行映射时，segment 和 section 会以不同的参数和权限被映射。

上面的代码中，`__TEXT` segment 包含了被执行的代码。它被以只读和可执行的方式映射。进程被允许执行这些代码，但是不能修改。这些代码也不能对自己做出修改，因此这些被映射的页从来不会被改变。

`__DATA` segment 以可读写和不可执行的方式映射。它包含了将会被更改的数据。

第一个 segment 是 `__PAGEZERO`。它的大小为 4GB。这 4GB 并不是文件的真实大小，但是规定了进程地址空间的前 4GB 被映射为 不可执行、不可写和不可读。这就是为什么当读写一个 `NULL` 指针或更小的值时会得到一个 `EXC_BAD_ACCESS` 错误。这是操作系统在尝试防止[引起系统崩溃](http://www.xkcd.com/371/)。

在 segment中，一般都会有多个 section。它们包含了可执行文件的不同部分。在 `__TEXT` segment 中，`__text` section 包含了编译所得到的机器码。`__stubs` 和 `__stub_helper` 是给动态链接器 (`dyld`) 使用的。通过这两个 section，在动态链接代码中，可以允许延迟链接。`__const` (在我们的代码中没有) 是常量，不可变的，就像 `__cstring` (包含了可执行文件中的字符串常量 -- 在源码中被双引号包含的字符串) 常量一样。

`__DATA` segment 中包含了可读写数据。在我们的程序中只有 `__nl_symbol_ptr` 和 `__la_symbol_ptr`，它们分别是 *non-lazy* 和 *lazy* 符号指针。延迟符号指针用于可执行文件中调用未定义的函数，例如不包含在可执行文件中的函数，它们将会延迟加载。而针对非延迟符号指针，当可执行文件被加载同时，也会被加载。

在 `_DATA` segment 中的其它常见 section 包括 `__const`，在这里面会包含一些需要重定向的常量数据。例如 `char * const p = "foo";` -- `p` 指针指向的数据是可变的。`__bss` section 没有被初始化的静态变量，例如 `static int a;` -- ANSI C 标准规定静态变量必须设置为 0。并且在运行时静态变量的值是可以修改的。`__common` section 包含未初始化的外部全局变量，跟 `static` 变量类似。例如在函数外面定义的 `int a;`。最后，`__dyld` 是一个 section 占位符，被用于动态链接器。

苹果的 [OS X Assembler Reference](https://developer.apple.com/library/mac/documentation/DeveloperTools/Reference/Assembler/) 文档有更多关于 section 类型的介绍。

### Section 中的内容

下面，我们用 `otool(1)` 来观察一个 section 中的内容：

    % xcrun otool -s __TEXT __text a.out 
    a.out:
    (__TEXT,__text) section
    0000000100000f30 55 48 89 e5 48 83 ec 20 48 8d 05 4b 00 00 00 c7 
    0000000100000f40 45 fc 00 00 00 00 89 7d f8 48 89 75 f0 48 89 c7 
    0000000100000f50 b0 00 e8 11 00 00 00 b9 00 00 00 00 89 45 ec 89 
    0000000100000f60 c8 48 83 c4 20 5d c3 

上面是我们 app 中的代码。由于 `-s __TEXT __text` 很常见，`otool` 对其设置了一个缩写 `-t` 。我们还可以通过添加 `-v` 来查看反汇编代码：

    % xcrun otool -v -t a.out
    a.out:
    (__TEXT,__text) section
    _main:
    0000000100000f30    pushq   %rbp
    0000000100000f31    movq    %rsp, %rbp
    0000000100000f34    subq    $0x20, %rsp
    0000000100000f38    leaq    0x4b(%rip), %rax
    0000000100000f3f    movl    $0x0, 0xfffffffffffffffc(%rbp)
    0000000100000f46    movl    %edi, 0xfffffffffffffff8(%rbp)
    0000000100000f49    movq    %rsi, 0xfffffffffffffff0(%rbp)
    0000000100000f4d    movq    %rax, %rdi
    0000000100000f50    movb    $0x0, %al
    0000000100000f52    callq   0x100000f68
    0000000100000f57    movl    $0x0, %ecx
    0000000100000f5c    movl    %eax, 0xffffffffffffffec(%rbp)
    0000000100000f5f    movl    %ecx, %eax
    0000000100000f61    addq    $0x20, %rsp
    0000000100000f65    popq    %rbp
    0000000100000f66    ret

上面的内容是一样的，只不过以反汇编形式显示出来。你应该感觉很熟悉，这就是我们在前面编译时候的代码。唯一的不同就是，在这里我们没有任何的汇编指令在里面。这是纯粹的二进制执行文件。

同样的方法，我们可以查看别的 section：

    % xcrun otool -v -s __TEXT __cstring a.out
    a.out:
    Contents of (__TEXT,__cstring) section
    0x0000000100000f8a  Hello World!\n

或:

    % xcrun otool -v -s __TEXT __eh_frame a.out 
    a.out:
    Contents of (__TEXT,__eh_frame) section
    0000000100000fe0    14 00 00 00 00 00 00 00 01 7a 52 00 01 78 10 01 
    0000000100000ff0    10 0c 07 08 90 01 00 00 

#### 性能上需要注意的事项

从侧面来讲，`__DATA` 和 `__TEXT` segment对性能会有所影响。如果你有一个很大的二进制文件，你可能得去看看苹果的文档：[关于代码大小性能指南](https://developer.apple.com/library/mac/documentation/Performance/Conceptual/CodeFootprint/Articles/MachOOverview.html)。将数据移至 `__TEXT` 是个不错的选择，因为这些页从来不会被改变。

#### 任意的片段

使用链接符号 `-sectcreate` 我们可以给可执行文件以 section 的方式添加任意的数据。这就是如何将一个 Info.plist 文件添加到一个独立的可执行文件中的方法。Info.plist 文件中的数据需要放入到 `__TEXT` segment 里面的一个 `__info_plist` section 中。可以将 `-sectcreate segname sectname file` 传递给链接器（通过将下面的内容传递给 clang）：

    -Wl,-sectcreate,__TEXT,__info_plist,path/to/Info.plist

同样，`-sectalign` 规定了对其方式。如果你添加的是一个全新的 segment，那么需要通过 `-segprot` 来规定 segment 的保护方式 (读/写/可执行)。这些所有内容在链接器的帮助文档中都有，例如 `ld(1)`。

我们可以利用定义在 `/usr/include/mach-o/getsect.h` 中的函数 `getsectdata()` 得到 section，例如 `getsectdata()` 可以得到指向 section 数据的一个指针，并返回相关 section 的长度。

### Mach-O

在 OS X 和 iOS 中可执行文件的格式为 [Mach-O](https://en.wikipedia.org/wiki/Mach-o)：

    % file a.out 
    a.out: Mach-O 64-bit executable x86_64

对于 GUI 程序也是一样的：

    % file /Applications/Preview.app/Contents/MacOS/Preview 
    /Applications/Preview.app/Contents/MacOS/Preview: Mach-O 64-bit executable x86_64

关于 [Mach-O 文件格式](https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/MachORuntime/index.html) 苹果有详细的介绍。

我们可以使用 `otool(1)` 来观察可执行文件的头部 -- 规定了这个文件是什么，以及文件是如何被加载的。通过 `-h` 可以打印出头信息：

    % otool -v -h a.out           a.out:
    Mach header
          magic cputype cpusubtype  caps    filetype ncmds sizeofcmds      flags
    MH_MAGIC_64  X86_64        ALL LIB64     EXECUTE    16       1296   NOUNDEFS DYLDLINK TWOLEVEL PIE

`cputype` 和 `cpusubtype` 规定了这个可执行文件能够运行在哪些目标架构上。`ncmds` 和 `sizeofcmds` 是加载命令，可以通过 `-l` 来查看这两个加载命令：

    % otool -v -l a.out | open -f
    a.out:
    Load command 0
          cmd LC_SEGMENT_64
      cmdsize 72
      segname __PAGEZERO
       vmaddr 0x0000000000000000
       vmsize 0x0000000100000000
    ...

加载命令规定了文件的逻辑结构和文件在虚拟内存中的布局。`otool` 打印出的大多数信息都是源自这里的加载命令。看一下 `Load command 1` 部分，可以找到 `initprot r-x`，它规定了之前提到的保护方式：只读和可执行。

对于每一个 segment，以及segment 中的每个 section，加载命令规定了它们在内存中结束的位置，以及保护模式等。例如，下面是 `__TEXT __text` section 的输出内容：

    Section
      sectname __text
       segname __TEXT
          addr 0x0000000100000f30
          size 0x0000000000000037
        offset 3888
         align 2^4 (16)
        reloff 0
        nreloc 0
          type S_REGULAR
    attributes PURE_INSTRUCTIONS SOME_INSTRUCTIONS
     reserved1 0
     reserved2 0

上面的代码将在 0x100000f30 处结束。它在文件中的偏移量为 3888。如果看一下之前 `xcrun otool -v -t a.out` 输出的反汇编代码，可以发现代码实际位置在 0x100000f30。

我们同样看看在可执行文件中，动态链接库是如何使用的：

    % otool -v -L a.out
    a.out:
        /usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 169.3.0)
        time stamp 2 Thu Jan  1 01:00:02 1970

上面就是我们可执行文件将要找到 `_printf` 符号的地方。

## 一个更复杂的例子

我们来看看有三个文件的复杂例子：

`Foo.h`:

    #import <Foundation/Foundation.h>
    
    @interface Foo : NSObject
    
    - (void)run;
    
    @end

`Foo.m`:

    #import "Foo.h"
    
    @implementation Foo
    
    - (void)run
    {
        NSLog(@"%@", NSFullUserName());
    }
    
    @end

`helloworld.m`:

    #import "Foo.h"
    
    int main(int argc, char *argv[])
    {
        @autoreleasepool {
            Foo *foo = [[Foo alloc] init];
            [foo run];
            return 0;
        }
    }

### 编译多个文件

在上面的示例中，有多个源文件。所以我们需要让 clang 对输入每个文件生成对应的目标文件：

    % xcrun clang -c Foo.m
    % xcrun clang -c helloworld.m

我们从来不编译头文件。头文件的作用就是在被编译的实现文件中对代码做简单的共享。`Foo.m` 和 `helloworld.m` 都是通过 `#import` 语句将 `Foo.h` 文件中的内容添加到实现文件中的。

最终得到了两个目标文件：

    % file helloworld.o Foo.o
    helloworld.o: Mach-O 64-bit object x86_64
    Foo.o:        Mach-O 64-bit object x86_64

为了生成一个可执行文件，我们需要将这两个目标文件和 Foundation framework 链接起来：

    xcrun clang helloworld.o Foo.o -Wl,`xcrun --show-sdk-path`/System/Library/Frameworks/Foundation.framework/Foundation

现在可以运行我们的程序了:

    % ./a.out 
    2013-11-03 18:03:03.386 a.out[8302:303] Daniel Eggert

### 符号表和链接

我们这个简单的程序是将两个目标文件合并到一起的。`Foo.o` 目标文件包含了 `Foo` 类的实现，而 `helloworld.o` 目标文件包含了 `main()` 函数，以及调用/使用 `Foo` 类。

另外，这两个目标对象都使用了 Foundation framework。`helloworld.o` 目标文件使用了它的 autorelease pool，并间接的使用了  `libobjc.dylib` 中的 Objective-C 运行时。它需要运行时函数来进行消息的调用。`Foo.o` 目标文件也有类似的原理。

所有的这些东西都被形象的称之为符号。我们可以把符号看成是一些在运行时将会变成指针的东西。虽然实际上并不是这样的。

每个函数、全局变量和类等都是通过符号的形式来定义和使用的。当我们将目标文件链接为一个可执行文件时，链接器 (`ld(1)`) 在目标文件盒动态库之间对符号做了解析处理。

可执行文件和目标文件有一个符号表，这个符号表规定了它们的符号。如果我们用 `nm(1)` 工具观察一下 `helloworld.0` 目标文件，可以看到如下内容：

    % xcrun nm -nm helloworld.o
                     (undefined) external _OBJC_CLASS_$_Foo
    0000000000000000 (__TEXT,__text) external _main
                     (undefined) external _objc_autoreleasePoolPop
                     (undefined) external _objc_autoreleasePoolPush
                     (undefined) external _objc_msgSend
                     (undefined) external _objc_msgSend_fixup
    0000000000000088 (__TEXT,__objc_methname) non-external L_OBJC_METH_VAR_NAME_
    000000000000008e (__TEXT,__objc_methname) non-external L_OBJC_METH_VAR_NAME_1
    0000000000000093 (__TEXT,__objc_methname) non-external L_OBJC_METH_VAR_NAME_2
    00000000000000a0 (__DATA,__objc_msgrefs) weak private external l_objc_msgSend_fixup_alloc
    00000000000000e8 (__TEXT,__eh_frame) non-external EH_frame0
    0000000000000100 (__TEXT,__eh_frame) external _main.eh

上面就是那个目标文件的所有符号。`_OBJC_CLASS_$_Foo` 是 `Foo` Objective-C 类的符号。该符号是 *undefined, external* 。*External* 的意思是指对于这个目标文件该类并不是私有的，相反，`non-external` 的符号则表示对于目标文件是私有的。我们的 `helloworld.o` 目标文件引用了类 `Foo`，不过这并没有实现它。因此符号表中将其标示为 undefined。

接下来是 `_main` 符号，它是表示 `main()` 函数，同样为 *external*，这是因为该函数需要被调用，所以应该为可见的。由于在 `helloworld.o` 文件中实现了 这个 main 函数。这个函数地址位于 0处，并且需要转入到  `__TEXT,__text` section。接着是 4 个 Objective-C 运行时函数。它们同样是 undefined的，需要链接器进行符号解析。

如果我们转而观察 `Foo.o` 目标文件，可以看到如下输出：

    % xcrun nm -nm Foo.o
    0000000000000000 (__TEXT,__text) non-external -[Foo run]
                     (undefined) external _NSFullUserName
                     (undefined) external _NSLog
                     (undefined) external _OBJC_CLASS_$_NSObject
                     (undefined) external _OBJC_METACLASS_$_NSObject
                     (undefined) external ___CFConstantStringClassReference
                     (undefined) external __objc_empty_cache
                     (undefined) external __objc_empty_vtable
    000000000000002f (__TEXT,__cstring) non-external l_.str
    0000000000000060 (__TEXT,__objc_classname) non-external L_OBJC_CLASS_NAME_
    0000000000000068 (__DATA,__objc_const) non-external l_OBJC_METACLASS_RO_$_Foo
    00000000000000b0 (__DATA,__objc_const) non-external l_OBJC_$_INSTANCE_METHODS_Foo
    00000000000000d0 (__DATA,__objc_const) non-external l_OBJC_CLASS_RO_$_Foo
    0000000000000118 (__DATA,__objc_data) external _OBJC_METACLASS_$_Foo
    0000000000000140 (__DATA,__objc_data) external _OBJC_CLASS_$_Foo
    0000000000000168 (__TEXT,__objc_methname) non-external L_OBJC_METH_VAR_NAME_
    000000000000016c (__TEXT,__objc_methtype) non-external L_OBJC_METH_VAR_TYPE_
    00000000000001a8 (__TEXT,__eh_frame) non-external EH_frame0
    00000000000001c0 (__TEXT,__eh_frame) non-external -[Foo run].eh

第五行至最后一行显示了 `_OBJC_CLASS_$_Foo` 已经定义了，并且对于 `Foo.o` 是一个外部符号 -- ·Foo.o· 包含了这个类的实现。

`Foo.o` 同样有 undefined 的符号。首先是使用了符号 `NSFullUserName()`，`NSLog()`和 `NSObject`。

当我们将这两个目标文件和 Foundation framework (是一个动态库) 进行链接处理时，链接器会尝试解析所有的 undefined 符号。它可以解析  `_OBJC_CLASS_$_Foo`。另外，它将使用 Foundation framework。

当链接器通过动态库 (此处是 Foundation framework) 解析成功一个符号时，它会在最终的链接图中记录这个符号是通过动态库进行解析的。链接器会记录输出文件是依赖于哪个动态链接库，并连同其路径一起进行记录。在我们的例子中，`_NSFullUserName`，`_NSLog`，`_OBJC_CLASS_$_NSObject`，`_objc_autoreleasePoolPop` 等符号都是遵循这个过程。

我们可以看一下最终可执行文件 `a.out` 的符号表，并注意观察链接器是如何解析所有符号的：

    % xcrun nm -nm a.out 
                     (undefined) external _NSFullUserName (from Foundation)
                     (undefined) external _NSLog (from Foundation)
                     (undefined) external _OBJC_CLASS_$_NSObject (from CoreFoundation)
                     (undefined) external _OBJC_METACLASS_$_NSObject (from CoreFoundation)
                     (undefined) external ___CFConstantStringClassReference (from CoreFoundation)
                     (undefined) external __objc_empty_cache (from libobjc)
                     (undefined) external __objc_empty_vtable (from libobjc)
                     (undefined) external _objc_autoreleasePoolPop (from libobjc)
                     (undefined) external _objc_autoreleasePoolPush (from libobjc)
                     (undefined) external _objc_msgSend (from libobjc)
                     (undefined) external _objc_msgSend_fixup (from libobjc)
                     (undefined) external dyld_stub_binder (from libSystem)
    0000000100000000 (__TEXT,__text) [referenced dynamically] external __mh_execute_header
    0000000100000e50 (__TEXT,__text) external _main
    0000000100000ed0 (__TEXT,__text) non-external -[Foo run]
    0000000100001128 (__DATA,__objc_data) external _OBJC_METACLASS_$_Foo
    0000000100001150 (__DATA,__objc_data) external _OBJC_CLASS_$_Foo

可以看到所有的 Foundation 和 Objective-C 运行时符号依旧是 undefined，不过现在的符号表中已经多了如何解析它们的信息，例如在哪个动态库中可以找到对应的符号。

可执行文件同样知道去哪里找到所需库：

    % xcrun otool -L a.out
    a.out:
        /System/Library/Frameworks/Foundation.framework/Versions/C/Foundation (compatibility version 300.0.0, current version 1056.0.0)
        /usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1197.1.1)
        /System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation (compatibility version 150.0.0, current version 855.11.0)
        /usr/lib/libobjc.A.dylib (compatibility version 1.0.0, current version 228.0.0)

在运行时，动态链接器  `dyld(1)` 可以解析这些 undefined 符号，`dyld` 将会确定好 `_NSFullUserName` 等符号，并指向它们在 Foundation 中的实现等。

我们可以针对 Foundation 运行 `nm(1)`，并检查这些符号的定义情况： 

    % xcrun nm -nm `xcrun --show-sdk-path`/System/Library/Frameworks/Foundation.framework/Foundation | grep NSFullUserName
    0000000000007f3e (__TEXT,__text) external _NSFullUserName 

### 动态链接编辑器

有一些环境变量对于 `dyld` 的输出信息非常有用。首先，如果设置了 `DYLD_PRINT_LIBRARIES`，那么 `dyld` 将会打印出什么库被加载了：

    % (export DYLD_PRINT_LIBRARIES=; ./a.out )
    dyld: loaded: /Users/deggert/Desktop/command_line/./a.out
    dyld: loaded: /System/Library/Frameworks/Foundation.framework/Versions/C/Foundation
    dyld: loaded: /usr/lib/libSystem.B.dylib
    dyld: loaded: /System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation
    dyld: loaded: /usr/lib/libobjc.A.dylib
    dyld: loaded: /usr/lib/libauto.dylib
    [...]

上面将会显示出在加载 Foundation 时，同时会加载的 70 个动态库。这是由于 Foundation 依赖于另外一些动态库。运行下面的命令：

    % xcrun otool -L `xcrun --show-sdk-path`/System/Library/Frameworks/Foundation.framework/Foundation

可以看到 Foundation 使用了 15 个动态库。

### dyld 的共享缓存

当你构建一个真正的程序时，将会链接各种各样的库。它们又会依赖其他一些 framework 和 动态库。需要加载的动态库会非常多。而对于相互依赖的符号就更多了。可能将会有上千个符号需要解析处理，这将花费很长的时间：一般是好几秒钟。

为了缩短这个处理过程所花费时间，在 OS X 和 iOS 上的动态链接器使用了共享缓存，共享缓存存于 `/var/db/dyld/`。对于每一种架构，操作系统都有一个单独的文件，文件中包含了绝大多数的动态库，这些库都已经链接为一个文件，并且已经处理好了它们之间的符号关系。当加载一个 Mach-O 文件 (一个可执行文件或者一个库) 时，动态链接器首先会检查 *共享缓存* 看看是否存在其中，如果存在，那么就直接从共享缓存中拿出来使用。每一个进程都把这个共享缓存映射到了自己的地址空间中。这个方法大大优化了 OS X 和 iOS 上程序的启动时间。

---

 

原文: [Mach-O Executables](http://www.objc.io/issue-6/mach-o-executables.html)

译文 [objc.io 第6期 Mach-O 可执行文件](http://blog.jobbole.com/51527/)

精细校对 [@BeyondVincent](http://beyondvincent.com/)