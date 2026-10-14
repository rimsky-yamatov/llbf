# llbf

Brainfuck LLVM compiler in C.

This repository contains a small compiler that reads Brainfuck source and emits LLVM IR text. By default it compiles the generated LLVM IR to an executable using `clang`.

## Features

- `bfcc input.bf -o output.exe` compiles Brainfuck to an executable.
- `bfcc input.bf -o output.ll --emit-ll` emits LLVM IR text only.
- Works from a plain C build without requiring the LLVM C API or libLLVM.

## Quick start

```bash
make
./bfcc examples/hello.bf -o hello.exe
./hello.exe
```

Or emit LLVM IR only:

```bash
./bfcc examples/hello.bf -o hello.ll --emit-ll
```

## Build requirements

- GNU make or a C compiler such as `clang` or `gcc`
- `clang` must be available in `PATH` for the default executable-generation mode

## Example

The repository includes a minimal Brainfuck Hello World program:

```brainfuck
++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++++++++.------.--------.>+.>.
```

## Notes

This is intentionally compact and educational. It emits straightforward LLVM IR text and keeps a simple tape model as a global array.
