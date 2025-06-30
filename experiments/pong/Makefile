# Makefile for Assembly Pong

# Compiler and flags
NASM = nasm
NASMFLAGS = -f elf64 -g -F dwarf
LD = ld
LDFLAGS = -m elf_x86_64 -dynamic-linker /lib64/ld-linux-x86-64.so.2 -lc -o

# Default target
all: debug_pong

# Debug Pong with debug output
debug_pong: debug_pong.o
	$(LD) -o debug_pong debug_pong.o

debug_pong.o: debug_pong.asm
	$(NASM) $(NASMFLAGS) -o debug_pong.o debug_pong.asm

# Enhanced Pong with better terminal handling
enhanced_pong: enhanced_pong.o
	$(LD) -o enhanced_pong enhanced_pong.o

enhanced_pong.o: enhanced_pong.asm
	$(NASM) $(NASMFLAGS) -o enhanced_pong.o enhanced_pong.asm

# Simple hello world test
hello: hello.o
	$(LD) -o hello hello.o

hello.o: hello.asm
	$(NASM) $(NASMFLAGS) -o hello.o hello.asm

# Test Game - minimal test case
test_game: test_game.o
	$(LD) -o test_game test_game.o

test_game.o: test_game.asm
	$(NASM) $(NASMFLAGS) -o test_game.o test_game.asm

# Simple Game - clean implementation
simple_game: simple_game.o
	$(LD) -o simple_game simple_game.o

simple_game.o: simple_game.asm
	$(NASM) $(NASMFLAGS) -o simple_game.o simple_game.asm

# Mini Pong - simplest working version
mini_pong: mini_pong.o
	$(LD) -o mini_pong mini_pong.o

mini_pong.o: mini_pong.asm
	$(NASM) $(NASMFLAGS) -o mini_pong.o mini_pong.asm

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
	rm -f *.o pong simple_pong pong_fixed mini_pong simple_game test_game hello enhanced_pong debug_pong

.PHONY: all clean