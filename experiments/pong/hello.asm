section .data
    msg db 'Hello, World!', 0x0A
    len equ $ - msg

section .text
    global _start

_start:
    ; write(1, msg, len)
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, len
    syscall

    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall
