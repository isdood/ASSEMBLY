section .data
    ; Terminal control sequences
    clear_screen    db 27, '[2J', 27, '[H', 0
    hide_cursor     db 27, '[?25l', 0
    show_cursor     db 27, '[?25h', 0
    
    ; Game state
    ball_x          db 10
    ball_y          db 10
    
    ; System call numbers
    SYS_WRITE       equ 1
    SYS_EXIT        equ 60
    STDOUT          equ 1

section .text
global _start

; Print a string to stdout
; rsi = string address
; rdx = string length
print_string:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    ret

; Simple delay
delay:
    push rcx
    mov rcx, 0x3FFFFF
.delay_loop:
    dec rcx
    jnz .delay_loop
    pop rcx
    ret

; Set cursor position
; r8b = row, r9b = column
set_cursor_pos:
    push rax
    push rdi
    push rsi
    push rdx
    
    ; Build cursor position string
    mov byte [cursor_buf], 27
    mov byte [cursor_buf+1], '['
    
    ; Convert row to ASCII
    mov al, r8b
    add al, '0'
    mov [cursor_buf+2], al
    
    ; Add semicolon
    mov byte [cursor_buf+3], ';'
    
    ; Convert column to ASCII
    mov al, r9b
    add al, '0'
    mov [cursor_buf+4], al
    
    ; Add 'H' and null terminator
    mov byte [cursor_buf+5], 'H'
    mov byte [cursor_buf+6], 0
    
    ; Print cursor position sequence
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [cursor_buf]
    mov rdx, 6
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Main program
_start:
    ; Clear screen and hide cursor
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [clear_screen]
    mov rdx, 7
    syscall
    
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [hide_cursor]
    mov rdx, 6
    syscall

game_loop:
    ; Clear screen
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [clear_screen]
    mov rdx, 7
    syscall
    
    ; Move ball
    inc byte [ball_x]
    cmp byte [ball_x], 20
    jl .no_reset
    mov byte [ball_x], 1
    
.no_reset:
    ; Set cursor position and draw ball
    movzx r8, byte [ball_y]
    movzx r9, byte [ball_x]
    call set_cursor_pos
    
    ; Draw ball
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, 'O'
    push rsi
    lea rsi, [rsp]
    mov rdx, 1
    syscall
    pop rsi
    
    ; Small delay
    call delay
    
    ; Continue loop
    jmp game_loop

exit:
    ; Show cursor and exit
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [show_cursor]
    mov rdx, 6
    syscall
    
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

section .bss
    cursor_buf resb 16
