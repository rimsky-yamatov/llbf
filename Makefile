CC ?= clang
CFLAGS ?= -O2 -std=c11

all: bfcc

bfcc: bfcc.c
	$(CC) $(CFLAGS) -o $@ bfcc.c

clean:
	rm -f bfcc
