# Makefile for Assembly Pong

# Compiler and flags
NASM = nasm
NASMFLAGS = -f elf64
LD = ld
LDFLAGS = -m elf_x86_64

# Source and output files
SRC = pong.asm
OBJ = pong.o
BIN = pong

# Default target
all: $(BIN)

# Build the executable
$(BIN): $(OBJ)
	$(LD) $(LDFLAGS) -o $@ $<

# Compile assembly to object file
$(OBJ): $(SRC)
	$(NASM) $(NASMFLAGS) -o $@ $<

# Clean build files
clean:
	rm -f $(OBJ) $(BIN)

.PHONY: all clean 