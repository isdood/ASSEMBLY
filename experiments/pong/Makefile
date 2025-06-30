# Makefile for Assembly Pong

# Compiler and flags
NASM = nasm
NASMFLAGS = -f elf64 -g -F dwarf
LD = ld
LDFLAGS = -m elf_x86_64 -dynamic-linker /lib64/ld-linux-x86-64.so.2 -lc -o

# Default target
all: pong_fixed

# Fixed Pong game with better terminal handling
pong_fixed: pong_fixed.o
	$(LD) -o pong_fixed pong_fixed.o

pong_fixed.o: pong_fixed.asm
	$(NASM) $(NASMFLAGS) -o pong_fixed.o pong_fixed.asm

# Original Pong game
pong: pong.o
	$(LD) -o pong pong.o

pong.o: pong.asm
	$(NASM) $(NASMFLAGS) -o pong.o pong.asm

# Simple Pong game (more reliable version)
simple_pong: simple_pong.o
	$(LD) -o simple_pong simple_pong.o

simple_pong.o: simple_pong.asm
	$(NASM) $(NASMFLAGS) -o simple_pong.o simple_pong.asm

# Clean build files
clean:
	rm -f *.o pong simple_pong pong_fixed

.PHONY: all clean