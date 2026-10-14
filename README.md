# llbf

Brainfuck LLVM compiler in C.

Version v0.1.0

This repository contains a tiny Brainfuck compiler that emits LLVM IR text, then builds an executable with `clang`.

## Features

- `bfcc input.bf -o output.exe` compiles Brainfuck to an executable.
- `bfcc input.bf -o output.ll --emit-ll` emits LLVM IR text only.
- Stays simple and educational: no LLVM C API or `libLLVM` linking is required.
- Supports a small set of standard Brainfuck commands: `> < + - . , [ ]`

## Build

```bash
gcc -O2 -std=c11 bfcc.c -o bfcc
# or
clang -O2 -std=c11 bfcc.c -o bfcc
```

## Examples

The repository includes a small set of working Brainfuck programs under `examples/`:

- `examples/hello.bf` — canonical Hello World program
- `examples/cat.bf` — echoes input to output
- `examples/newline.bf` — prints a newline byte
- `examples/plus5.bf` — prints the value 5
- `examples/print_65.bf` — prints ASCII 65 (`A`)
- `examples/print_65_alt.bf` — alternate ASCII 65 implementation

Example usage:

```bash
./bfcc examples/hello.bf -o hello.exe
./hello.exe

./bfcc examples/hello.bf -o hello.ll --emit-ll
```

## Example programs

```brainfuck
# examples/hello.bf
++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++++++++.------.--------.>+.>.
```

```brainfuck
# examples/newline.bf
++++++++++.
```

```brainfuck
# examples/plus5.bf
+++++.
```

```brainfuck
# examples/print_65.bf
++++++++[>++++++++++<-]>.
```

## Notes

This is intentionally minimal and intended for learning LLVM IR generation. The compiler emits straightforward LLVM IR text and keeps a simple tape model as a global array.
