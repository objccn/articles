[Source](http://www.objc.io/issue-6/mach-o-executables.html "Permalink to Mach-O Executables - Build Tools - objc.io issue #6 ")

# Mach-O Executables - Build Tools - objc.io issue #6 

  * [About][1]
  * [Contributors][2]
  * [Subscribe][3]

A periodical about best practices and advanced techniques in Objective-C.

# Mach-O Executables

[Issue #6 Build Tools][4], November 2013

By [Daniel Eggert][5]

When we build an application in Xcode, part of what happens is that the sources files (`.m` and `.h`) get turned into an executable. This executable contains the byte code than will run on the CPU, the ARM processor on the iOS device, or the Intel processor on your Mac.

We’ll walk through some of what the compiler does and what’s inside such an executable. There’s more to it than first meets the eye.

Let’s put Xcode aside for this and step into the land of command-line tools. When we build in Xcode, it simply calls a series of tools. Florian discusses how this works in more detail. We’ll call these tools directly and take a look at what they do.

Hopefully this will give you a better understanding of how an executable on iOS or OS X – a so-called _Mach-O executable_ – works and is put together.

## xcrun

Some infrastructure first: There’s a command-line tool called `xcrun` which we’ll use a lot. It may seem odd, but it’s pretty awesome. This little tool is used to run other tools. Instead of running:


    % clang -v

On the Terminal, we’ll use:


    % xcrun clang -v

What `xcrun` does is to locate `clang` and run it with the arguments that follow `clang`.

Why would we do this? It may seem pointless. But `xcrun` allows us to (1) have multiple versions of Xcode and use the tools from a specific Xcode version, and (2) use the tools for a specific SDK (software development kit). If you happen to have both Xcode 4.5 and Xcode 5, with `xcode-select` and `xcrun` you can choose to use the tools (and header files, etc.) from the iOS SDK from Xcode 5, or the OS X tools from Xcode 4.5. On most other platforms, that’d be close to impossible. Check out the man pages for `xcrun` and `xcode-select` for more details. And you can use the developer tools from the command line without installing the _Command Line Tools_.

## Hello World Without an IDE

Back in Terminal, let’s create a folder with a C file in it:


    % mkdir ~/Desktop/objcio-command-line
    % cd !$
    % touch helloworld.c

Now edit this file in your favorite text editor – even TextEdit.app will do:


    % open -e helloworld.c

Fill in this piece of code:


    #include 
    int main(int argc, char *argv[])
    {
        printf("Hello World!
    ");
        return 0;
    }

Save and return to Terminal to run this:


    % xcrun clang helloworld.c
    % ./a.out

You should now see a lovely `Hello World!` message on your terminal. You compiled a C program and ran it. All without an IDE. Take a deep breath. Rejoice.

What did we just do here? We compiled `helloworld.c` into a Mach-O binary called `a.out`. That is the default name the compiler will use unless we specify something else.

How did this binary get generated? There are multiple pieces to look at and understand. We’ll look at the compiler first.

### Hello World and the Compiler

The compiler of choice nowadays is `clang` (pronounced /klæŋ/). Chris writes in more detail [about the compiler][6].

Briefly put, the compiler will process the `helloworld.c` input file and produce the executable `a.out`. This processing consist of multiple steps/stages. What we just did is run all of them in succession:

##### Preprocessing

  * Tokenization
  * Macro expansion
  * `#include` expansion

##### Parsing and Semantic Analysis

  * Translates preprocessor tokens into a parse tree
  * Applies semantic analysis to the parse tree
  * Outputs an _Abstract Syntax Tree_ (AST)

##### Code Generation and Optimization

  * Translates an AST into low-level intermediate code (LLVM IR)
  * Responsible for optimizing the generated code
  * target-specific code generation
  * Outputs assembly

##### Assembler

  * Translates assembly code into a target object file

##### Linker

  * Merges multiple object files into an executable (or a dynamic library)

Let’s see how these steps look for our simple example.

#### Preprocessing

The first thing the compiler will do is preprocess the file. We can tell clang to show us what it looks like if we stop after that step:


    % xcrun clang -E helloworld.c

Wow. That will output 413 lines. Let’s open that in an editor to see what’s going on:


    % xcrun clang -E helloworld.c | open -f

At the very top you’ll see lots and lots of lines starting with a `#` (pronounced ‘hash’). These are so-called _linemarker_ statements that tell us which file the following lines are from. We need this. If you look at the `helloworld.c` file again, you’ll see that the first line is:


    #include 

We have all used `#include` and `#import` before. What it does is to tell the preprocessor to insert the content of the file `stdio.h` where the `#include` statement was. This is a recursive process: The `stdio.h` header file in turn includes other files.

Since there’s a lot of recursive insertion going on, we need to be able to keep track of where the lines in the resulting source originate from. To do this, the preprocessor inserts a _linemarker_ beginning with a `#` whenever the origin changes. The number following the `#` is the line number followed by the name of the file. The numbers at the very end of the line are flags indicating the start of a new file (1), returning to a file (2), that the following is from a system header (3), or that the file is to be treated as wrapped in an `extern"C"` block.

If you scroll to the very end of the output, you’ll find our `helloworld.c` code:


    # 2 "helloworld.c" 2
    int main(int argc, char *argv[])
    {
     printf("Hello World!
    ");
     return 0;
    }

In Xcode, you can look at the preprocessor output of any file by selecting **Product** -> **Perform Action** -> **Preprocess**. Note that it takes a few seconds for the Editor to load the preprocessed file – it’ll most likely be close to 100,000 lines long.

#### Compilation

Next up: parsing and code generation. We can tell `clang` to output the resulting assembly code like so:


    % xcrun clang -S -o - helloworld.c | open -f

Let’s take a look at the output. First we’ll notice how some lines start with a dot `.`. These are assembler directives. The other ones are actual x86_64 assembly. Finally there are labels, which are similar to labels in C.

Let’s start with the first three lines:


        .section    __TEXT,__text,regular,pure_instructions
        .globl  _main
        .align  4, 0x90

These three lines are assembler directives, not assembly code. The `.section` directive specifies into which section the following will go. More about sections in a bit.

Next, the `.globl` directive specifies that `_main` is an external symbol. This is our `main()` function. It needs to be visible outside our binary because the system needs to call it to run the executable.

The `.align` directive specifies the alignment of what follows. In our case, the following code will be 16 (2^4) byte aligned and padded with `0x90` if needed.

Next up is the preamble for the main function:


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

This part has a bunch of labels that work the same way as C labels do. They are symbolic references to certain parts of the assembly code. First is the actual start of our function `_main`. This is also the symbol that is exported. The binary will hence have a reference to this position.

The `.cfi_startproc` directive is used at the beginning of most functions. CFI is short for Call Frame Information. A _frame_ corresponds loosely to a function. When you use the debugger and _step in_ or _step out_, you’re actually stepping in/out of call frames. In C code, functions have their own call frames, but other things can too. The `.cfi_startproc` directive gives the function an entry into `.eh_frame`, which contains unwind information – this is how exception can unwind the call frame stack. The directive will also emit architecture-dependent instructions for CFI. It’s matched by a corresponding `.cfi_endproc` further down in the output to mark the end of our `main()` function.

Next, there’s another label `## BB#0:` and then, finally, the first assembly code: `pushq %rbp`. This is where things get interesting. On OS X, we have x86_64 code, and for this architecture there’s a so-called _application binary interface_ (ABI) that specifies how function calls work at the assembly code level. Part of this ABI specifies that the `rbp` register (base pointer register) must be preserved across function calls. It’s the main function’s responsibility to make sure the `rbp` register has the same value once the function returns. `pushq %rbp` pushes its value onto the stack so that we can pop it later.

Next, two more CFI directives: `.cfi_def_cfa_offset 16` and `.cfi_offset %rbp, -16`. Again, these will output information related to generating call frame unwinding information and debug information. We’re changing the stack and the base pointer and these two basically tell the debugger where things are – or rather, they’ll cause information to be output which the debugger can later use to find its way.

Now, `movq %rsp, %rbp` will allow us to put local variables onto the stack. `subq $32, %rsp` moves the stack pointer by 32 bytes, which the function can then use. We’re first storing the old stack pointer in `rbp` and using that as a base for our local variables, then updating the stack pointer to past the part that we’ll use.

Next, we’ll call `printf()`:


    leaq    L_.str(%rip), %rax
    movl    $0, -4(%rbp)
    movl    %edi, -8(%rbp)
    movq    %rsi, -16(%rbp)
    movq    %rax, %rdi
    movb    $0, %al
    callq   _printf

First, `leaq` loads the pointer to `L_.str` into the `rax` register. Note how the `L_.str` label is defined further down in the assembly code. This is our C string `"Hello World! "`. The `edi` and `rsi` registers hold the first and second function arguments. Since we’ll call another function, we first need to store their current values. That’s what we’ll use the 32 bytes based off `rbp` we just reserved for. First a 32-bit 0, then the 32-bit value of the `edi` register (which holds `argc`), then the 64-bit value of the `rsi` register (which holds `argv`). We’re not using those values later, but since the compiler is running without optimizations, it’ll store them anyway.

Now we’ll put the first function argument for `printf()`, `rax`, into the first function argument register `edi`. The `printf()` function is a variadic function. The ABI-calling convention specifies that the number of vector registers used to hold arguments need to be stored in the `al` register. In our case it’s 0. Finally, `callq` calls the `printf()` function:


        movl    $0, %ecx
        movl    %eax, -20(%rbp)         ## 4-byte Spill
        movl    %ecx, %eax

This sets the `ecx` register to 0, saves (spills) the `eax` register onto the stack, then copies the 0 values in `ecx` into `eax`. The ABI specifies that `eax` will hold the return value of a function, and our `main()` function returns 0:


        addq    $32, %rsp
        popq    %rbp
        ret
        .cfi_endproc

Since we’re done, we’ll restore the stack pointer by shifting the stack pointer `rsp` back 32 bytes to undo the effect of `subq $32, %rsp` from above. Finally, we’ll pop the value of `rbp` we’d stored earlier and then return to the caller with `ret`, which will read the return address off the stack. The `.cfi_endproc` balances the `.cfi_startproc` directive.

Next up is the output for our string literal `"Hello World! "`:


        .section    __TEXT,__cstring,cstring_literals
    L_.str:                                 ## @.str
        .asciz   "Hello World!
    "

Again, the `.section` directive specifies which section the following needs to go into. The `L_.str` label allows the actual code to get a pointer to the string literal. The `.asciz` directive tells the assembler to output a 0-terminated string literal.

This starts a new section `__TEXT __cstring`. This section contains C strings:


    L_.str:                                 ## @.str
        .asciz     "Hello World!
    "

And these two lines create a null-terminated string. Note how `L_.str` is the name used further up to access the string.

The final `.subsections_via_symbols` directive is used by the static link editor.

More information about assembler directives can be found in Apple’s [OS X Assembler Reference][7]. The AMD 64 website has documentation on the [application binary interface for x86_64][8]. It also has a [Gentle Introduction to x86-64 Assembly][9].

Again, Xcode lets you review the assembly output of any file by selecting **Product** -> **Perform Action** -> **Assemble**.

#### Assembler

The assembler, simply put, converts the (human-readable) assembly code into machine code. It creates a target object file, often simply called _object file_. These files have a `.o` file ending. If you build your app with Xcode, you’ll find these object files inside the `Objects-normal` folder inside the _derived data_ directory of your project.

#### Linker

We’ll talk a bit more about the linker later. But simply put, the linker will resolve symbols between object files and libraries. What does that mean? Recall the


    callq   _printf

statement. `printf()` is a function in the _libc_ library. Somehow, the final executable needs to be able to know where in memory the `printf()` is, i.e. what the address of the `_printf` symbol is. The linker takes all object files (in our case, only one) and the libraries (in our case, implicitly _libc_) and resolves any unknown symbols (in our case, the `_printf`). It then encodes into the final executable that this symbol can be found in _libc_, and the linker then outputs the final executable that can be run: `a.out`.

## Sections

As we mentioned above, there’s something called sections. An executable will have multiple sections, i.e. parts. Different parts of the executable will each go into their own section, and each section will in turn go inside a segment. This is true for our trivial app, but also for the binary of a full-blown app.

Let’s take a look at the sections of our `a.out` binary. We can use the `size` tool to do that:


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

Our `a.out` file has four segments. Some of these have sections.

When we run an executable, the VM (virtual memory) system maps the segments into the address space (i.e. into memory) of the process. Mapping is very different in nature, but if you’re unfamiliar with the VM system, simply assume that the VM loads the entire executable into memory – even though that’s not what’s really happening. The VM pulls some tricks to avoid having to do so.

When the VM system does this mapping, segments and sections are mapped with different properties, namely different permissions.

The `__TEXT` segment contains our code to be run. It’s mapped as read-only and executable. The process is allowed to execute the code, but not to modify it. The code can not alter itself, and these mapped pages can therefore never become dirty.

The `__DATA` segment is mapped read/write but non-executable. It contains values that need to be updated.

The first segment is `__PAGEZERO`. It’s 4GB large. Those 4GB are not actually in the file, but the file specifies that the first 4GB of the process’ address space will be mapped as non-executable, non-writable, non-readable. This is why you’ll get an `EXC_BAD_ACCESS` when reading from or writing to a `NULL` pointer, or some other value that’s (relatively) small. It’s the operating system trying to prevent you from [causing havoc][10].

Within segments, there are sections. These contain distinct parts of the executable. In the `__TEXT` segment, the `__text` section contains the compiled machine code. `__stubs` and `__stub_helper` are used for the dynamic linker (`dyld`). This allows for lazily linking in dynamically linked code. `__const` (which we don’t have in our example) are constants, and similarly `__cstring` contains the literal string constants of the executable (quoted strings in source code).

The `__DATA` segment contains read/write data. In our case we only have `__nl_symbol_ptr` and `__la_symbol_ptr`, which are _non-lazy_ and _lazy_ symbol pointers, respectively. The lazy symbol pointers are used for so-called undefined functions called by the executable, i.e. functions that are not within the executable itself. They’re lazily resolved. The non-lazy symbol pointers are resolved when the executable is loaded.

Other common sections in the `__DATA` segment are `__const`, which will contain constant data which needs relocation. An example is `char * const p = "foo";` – the data pointed to by `p` is not constant. The `__bss` section contains uninitialized static variables such as `static int a;` – the ANSI C standard specifies that static variables must be set to zero. But they can be changed at run time. The `__common` section contains uninitialized external globals, similar to `static` variables. An example would be `int a;` outside a function block. Finally, `__dyld` is a placeholder section, used by the dynamic linker.

Apple’s [OS X Assembler Reference][7] has more information about some of the section types.

### Section Content

We can inspect the content of a section with `otool(1)` like so:


    % xcrun otool -s __TEXT __text a.out
    a.out:
    (__TEXT,__text) section
    0000000100000f30 55 48 89 e5 48 83 ec 20 48 8d 05 4b 00 00 00 c7
    0000000100000f40 45 fc 00 00 00 00 89 7d f8 48 89 75 f0 48 89 c7
    0000000100000f50 b0 00 e8 11 00 00 00 b9 00 00 00 00 89 45 ec 89
    0000000100000f60 c8 48 83 c4 20 5d c3

This is the code of our app. Since `-s __TEXT __text` is very common, `otool` has a shortcut to it with the `-t` argument. We can even look at the disassembled code by adding `-v`:


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

This is the same stuff, this time disassembled. It should look familiar – it’s what we looked at a bit further back when compiling the code. The only difference is that we don’t have any of the assembler directives in the code anymore; this is the bare binary executable.

In a similar fashion, we can look at other sections:


    % xcrun otool -v -s __TEXT __cstring a.out
    a.out:
    Contents of (__TEXT,__cstring) section
    0x0000000100000f8a  Hello World!


Or:


    % xcrun otool -v -s __TEXT __eh_frame a.out
    a.out:
    Contents of (__TEXT,__eh_frame) section
    0000000100000fe0    14 00 00 00 00 00 00 00 01 7a 52 00 01 78 10 01
    0000000100000ff0    10 0c 07 08 90 01 00 00

#### Side Note on Performance

On a side note: The `__DATA` and `__TEXT` segments have performance implications. If you have a very large binary, you might want to check out Apple’s documentation on [Code Size Performance Guidelines][11]. Moving data into the `__TEXT` segment is beneficial, because those pages are never dirty.

#### Arbitrary Sections

You can add arbitrary data as a section to your executable with the `-sectcreate` linker flag. This is how you’d add a Info.plist to a single file executable. The Info.plist data needs to go into a `__info_plist` section of the `__TEXT` segment. You’d pass `-sectcreate segname sectname file` to the linker by passing


    -Wl,-sectcreate,__TEXT,__info_plist,path/to/Info.plist

to clang. Similarly, `-sectalign` specifies the alignment. If you’re adding an entirely new segment, check out `-segprot` to specify the protection (read/write/executable) of the segment. These are all documented in the main page for the linker, i.e. `ld(1)`.

You can get to sections using the functions defined in `/usr/include/mach-o/getsect.h`, namely `getsectdata()`, which will give you a pointer to the sections data and return its length by reference.

### Mach-O

Executables on OS X and iOS are [Mach-O][12] executables:


    % file a.out
    a.out: Mach-O 64-bit executable x86_64

This is true for GUI applications too:


    % file /Applications/Preview.app/Contents/MacOS/Preview
    /Applications/Preview.app/Contents/MacOS/Preview: Mach-O 64-bit executable x86_64

Apple has detailed information about the [Mach-O file format][13].

We can use `otool(1)` to peek into the executable’s Mach header. It specifies what this file is and how it’s to be loaded. We’ll use the `-h` flag to print the header information:


    % otool -v -h a.out           a.out:
    Mach header
          magic cputype cpusubtype  caps    filetype ncmds sizeofcmds      flags
    MH_MAGIC_64  X86_64        ALL LIB64     EXECUTE    16       1296   NOUNDEFS DYLDLINK TWOLEVEL PIE

The `cputype` and `cpusubtype` specify the target architecture this executable can run on. The `ncmds` and `sizeofcmds` are the load commands which we can look at with the `-l` argument:


    % otool -v -l a.out | open -f
    a.out:
    Load command 0
          cmd LC_SEGMENT_64
      cmdsize 72
      segname __PAGEZERO
       vmaddr 0x0000000000000000
       vmsize 0x0000000100000000
    ...

The load commands specify the logical structure of the file and its layout in virtual memory. Most of the information `otool` prints out is derived from these load commands. Looking at the `Load command 1` part, we find `initprot r-x`, which specifies the protection mentioned above: read-only (no-write) and executable.

For each segment and each section within a segment, the load command specifies where in memory it should end up, and with what protection, etc. Here’s the output for the `__TEXT __text` section:


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

Our code will end up in memory at 0x100000f30. Its offset in the file is 3888. If you look at the disassembly output from before of `xcrun otool -v -t a.out`, you’ll see that the code is, in fact, at 0x100000f30.

We can also take a look at which dynamic libraries the executable is using:


    % otool -v -L a.out
    a.out:
        /usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 169.3.0)
        time stamp 2 Thu Jan  1 01:00:02 1970

This is where our executable will find the `_printf` symbol it’s using.

## A More Complex Sample

Let’s look at a slightly more complex sample with three files:

`Foo.h`:


    #import 

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

### Compiling Multiple Files

In this sample, we have more than one file. We therefore need to tell clang to first generate object files for each input file:


    % xcrun clang -c Foo.m
    % xcrun clang -c helloworld.m

We’re never compiling the header file. Its purpose is simply to share code between the implementation files which do get compiled. Both `Foo.m` and `helloworld.m` pull in the content of the `Foo.h` through the `#import` statement.

We end up with two object files:


    % file helloworld.o Foo.o
    helloworld.o: Mach-O 64-bit object x86_64
    Foo.o:        Mach-O 64-bit object x86_64

In order to generate an executable, we need to link these two object files and the Foundation framework with each other:


    xcrun clang helloworld.o Foo.o -Wl,`xcrun --show-sdk-path`/System/Library/Frameworks/Foundation.framework/Foundation

We can now run our code:


    % ./a.out
    2013-11-03 18:03:03.386 a.out[8302:303] Daniel Eggert

### Symbols and Linking

Our small app was put together from two object files. The `Foo.o` object file contains the implementation of the `Foo` class, and the `helloworld.o` object file contains the `main()` function and calls/uses the `Foo` class.

Furthermore, both of these use the Foundation framework. The `helloworld.o` object file uses it for the autorelease pool, and it indirectly uses the Objective-C runtime in form of the `libobjc.dylib`. It needs the runtime functions to make message calls. This is similar to the `Foo.o` object file.

All of these are represented as so-called _symbols_. We can think of a symbol as something that’ll be a pointer once the app is running, although its nature is slightly different.

Each function, global variable, class, etc. that is defined or used results in a symbol. When we link object files into an executable, the linker (`ld(1)`) resolves symbols as needed between object files and dynamic libraries.

Executables and object files have a symbol table that specify their symbols. If we take a look at the `helloworld.o` object file with the `nm(1)` tool, we get this:


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

These are all symbols of that file. `_OBJC_CLASS_$_Foo` is the symbol as the `Foo` Objective-C class. It’s an _undefined, external_ symbol of the `Foo` class. _External_ means it’s not private to this object file, as opposed to `non-external` symbols which are private to the particular object file. Our `helloworld.o` object file references the class `Foo`, but it doesn’t implement it. Hence, its symbol table ends up having an entry marked as undefined.

Next, the `_main` symbol for the `main()` function is also _external_ because it needs to be visible in order to get called. It, however, is implemented in `helloworld.o` as well, and resides at address 0 and needs to go into the `__TEXT,__text` section. Then there are four Objective-C runtime functions. These are also undefined and need to be resolved by the linker.

If we turn toward the `Foo.o` object file, we get this output:


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

The fifth-to-last line shows that `_OBJC_CLASS_$_Foo` is defined and external to `Foo.o` – it has this class’s implementation.

`Foo.o` also has undefined symbols. First and foremost are the symbols for `NSFullUserName()`, `NSLog()`, and `NSObject` that we’re using.

When we link these two object files and the Foundation framework (which is a dynamic library), the linker tries to resolve all undefined symbols. It can resolve `_OBJC_CLASS_$_Foo` that way. For the others, it will need to use the Foundation framework.

When the linker resolves a symbol through a dynamic library (in our case, the Foundation framework), it will record inside the final linked image that the symbol will be resolved with that dynamic library. The linker records that the output file depends on that particular dynamic library, and what the path of it is. That’s what happens with the `_NSFullUserName`, `_NSLog`, `_OBJC_CLASS_$_NSObject`, `_objc_autoreleasePoolPop`, etc. symbols in our case.

We can look at the symbol table of the final executable `a.out` and see how the linker resolved all the symbols:


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

We see that all the Foundation and Objective-C runtime symbols are still undefined, but the symbol table now has information about how to resolve them, i.e. in which dynamic library they’re to be found.

The executable also knows where to find these libraries:


    % xcrun otool -L a.out
    a.out:
        /System/Library/Frameworks/Foundation.framework/Versions/C/Foundation (compatibility version 300.0.0, current version 1056.0.0)
        /usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1197.1.1)
        /System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation (compatibility version 150.0.0, current version 855.11.0)
        /usr/lib/libobjc.A.dylib (compatibility version 1.0.0, current version 228.0.0)

These undefined symbols are resolved by the dynamic linker `dyld(1)` at runtime. When we run the executable, `dyld` will make sure that `_NSFullUserName`, etc. point to their implementation inside Foundation, etc.

We can run `nm(1)` against Foundation and check that these symbols are, in fact, defined there:


    % xcrun nm -nm `xcrun --show-sdk-path`/System/Library/Frameworks/Foundation.framework/Foundation | grep NSFullUserName
    0000000000007f3e (__TEXT,__text) external _NSFullUserName

### The Dynamic Link Editor

There are a few environment variables that can be useful to see what `dyld` is up to. First and foremost, `DYLD_PRINT_LIBRARIES`. If set, `dyld` will print out what libraries are loaded:


    % (export DYLD_PRINT_LIBRARIES=; ./a.out )
    dyld: loaded: /Users/deggert/Desktop/command_line/./a.out
    dyld: loaded: /System/Library/Frameworks/Foundation.framework/Versions/C/Foundation
    dyld: loaded: /usr/lib/libSystem.B.dylib
    dyld: loaded: /System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation
    dyld: loaded: /usr/lib/libobjc.A.dylib
    dyld: loaded: /usr/lib/libauto.dylib
    [...]

This will show you all seventy dynamic libraries that get loaded as part of loading Foundation. That’s because Foundation depends on other dynamic libraries, which, in turn, depend on others, and so forth. You can run


    % xcrun otool -L `xcrun --show-sdk-path`/System/Library/Frameworks/Foundation.framework/Foundation

to see a list of the fifteen dynamic libraries that Foundation uses.

### The dyld’s Shared Cache

When you’re building a real-world application, you’ll be linking against various frameworks. And these in turn will use countless other frameworks and dynamic libraries. The list of all dynamic libraries that need to get loaded gets large quickly. And the list of interdependent symbols even more so. There will be thousands of symbols to resolve. This works takes a long time: several seconds.

In order to shortcut this process, the dynamic linker on OS X and iOS uses a shared cache that lives inside `/var/db/dyld/`. For each architecture, the OS has a single file that contains almost all dynamic libraries already linked together into a single file with their interdependent symbols resolved. When a Mach-O file (an executable or a library) is loaded, the dynamic linker will first check if it’s inside this _shared cache_ image, and if so, use it from the shared cache. Each process has this dyld shared cache mapped into its address space already. This method dramatically improves launch time on OS X and iOS.




* * *

[More articles in issue #6][14]

  * [Privacy policy][15]

   [1]: http://www.objc.io/about.html
   [2]: http://www.objc.io/contributors.html
   [3]: http://www.objc.io/subscribe.html
   [4]: http://www.objc.io/issue-6/index.html
   [5]: http://twitter.com/danielboedewadt
   [6]: http://www.objc.io/issue-6/compiler.html
   [7]: https://developer.apple.com/library/mac/documentation/DeveloperTools/Reference/Assembler/
   [8]: http://www.x86-64.org/documentation/abi.pdf
   [9]: http://www.x86-64.org/documentation/assembly.html
   [10]: http://www.xkcd.com/371/
   [11]: https://developer.apple.com/library/mac/documentation/Performance/Conceptual/CodeFootprint/Articles/MachOOverview.html
   [12]: https://en.wikipedia.org/wiki/Mach-o
   [13]: https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/MachORuntime/index.html
   [14]: http://www.objc.io/issue-6
   [15]: http://www.objc.io/privacy.html
