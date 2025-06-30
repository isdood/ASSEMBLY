# Makefile for Assembly Pong

# Compiler and flags
NASM = nasm
NASMFLAGS = -f elf64 -g -F dwarf
LD = ld
LDFLAGS = -m elf_x86_64 -dynamic-linker /lib64/ld-linux-x86-64.so.2 -lc -o

# Source and output files
SRC = pong.asm
OBJ = pong.o
BIN = pong

# Default target
all: $(BIN)

# Build the executable
$(BIN): $(OBJ)
	$(LD) $(LDFLAGS) $@ $< -I/lib64/ld-linux-x86-64.so.2

# Compile assembly to object file
$(OBJ): $(SRC)
	$(NASM) $(NASMFLAGS) -o $@ $<

# Clean build files
clean:
	rm -f $(OBJ) $(BIN)

.PHONY: all clean