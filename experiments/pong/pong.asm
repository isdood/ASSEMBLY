; Pong Game in x86_64 Assembly
; A simple terminal-based Pong implementation

section .data
    ; Game constants
    SCREEN_WIDTH    equ 80
    SCREEN_HEIGHT   equ 24
    PADDLE_HEIGHT   equ 4
    PADDLE_CHAR     equ '|'
    BALL_CHAR       equ 'O'
    EMPTY_CHAR      equ ' '
    
    ; Terminal control sequences
    CLEAR_SCREEN    db 27, '[2J', 27, '[H', 0
    HIDE_CURSOR     db 27, '[?25l', 0
    SHOW_CURSOR     db 27, '[?25h', 0
    CURSOR_POS      db 27, '[', 0, ';', 0, 'H', 0  ; ANSI escape sequence for cursor positioning

section .bss
    ; Game state
    left_paddle_y   resb 1    ; Y position of left paddle
    right_paddle_y  resb 1    ; Y position of right paddle
    ball_x          resb 1    ; X position of ball
    ball_y          resb 1    ; Y position of ball
    ball_dx         resb 1    ; Ball X direction (-1 or 1)
    ball_dy         resb 1    ; Ball Y direction (-1 or 1)
    cursor_pos      resb 8    ; Buffer for cursor position string

section .text
    global _start

; Function to set cursor position
; Input: r8b = row, r9b = column
set_cursor_pos:
    push rax
    push rdi
    push rsi
    push rdx

    ; Convert row and column to ASCII
    mov rax, r8
    add al, '0'
    mov [CURSOR_POS + 2], al
    mov rax, r9
    add al, '0'
    mov [CURSOR_POS + 4], al

    ; Write cursor position sequence
    mov rax, 1
    mov rdi, 1
    mov rsi, CURSOR_POS
    mov rdx, 7
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Function to draw a paddle
; Input: r8b = y position, r9b = x position
draw_paddle:
    push rax
    push rdi
    push rsi
    push rdx
    push rcx

    mov cl, PADDLE_HEIGHT    ; Counter for paddle height
.draw_paddle_loop:
    ; Set cursor position
    push rcx
    call set_cursor_pos
    pop rcx

    ; Draw paddle character
    mov rax, 1
    mov rdi, 1
    mov rsi, PADDLE_CHAR
    mov rdx, 1
    syscall

    ; Move to next line
    inc r8b
    dec cl
    jnz .draw_paddle_loop

    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Function to draw the ball
; Input: r8b = y position, r9b = x position
draw_ball:
    push rax
    push rdi
    push rsi
    push rdx

    ; Set cursor position
    call set_cursor_pos

    ; Draw ball character
    mov rax, 1
    mov rdi, 1
    mov rsi, BALL_CHAR
    mov rdx, 1
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

_start:
    ; Initialize game state
    mov byte [left_paddle_y], 10    ; Center left paddle
    mov byte [right_paddle_y], 10   ; Center right paddle
    mov byte [ball_x], 40           ; Center ball horizontally
    mov byte [ball_y], 12           ; Center ball vertically
    mov byte [ball_dx], 1           ; Initial ball direction
    mov byte [ball_dy], 1

    ; Hide cursor
    mov rax, 1
    mov rdi, 1
    mov rsi, HIDE_CURSOR
    mov rdx, 6
    syscall

game_loop:
    ; Clear screen
    mov rax, 1
    mov rdi, 1
    mov rsi, CLEAR_SCREEN
    mov rdx, 7
    syscall

    ; Draw left paddle
    mov r8b, [left_paddle_y]
    mov r9b, 2          ; X position for left paddle
    call draw_paddle

    ; Draw right paddle
    mov r8b, [right_paddle_y]
    mov r9b, 77         ; X position for right paddle
    call draw_paddle

    ; Draw ball
    mov r8b, [ball_y]
    mov r9b, [ball_x]
    call draw_ball

    ; Small delay
    mov rax, 35
    mov rdi, 100000    ; 100ms delay
    syscall

    jmp game_loop

exit:
    ; Show cursor before exiting
    mov rax, 1
    mov rdi, 1
    mov rsi, SHOW_CURSOR
    mov rdx, 6
    syscall

    ; Exit program
    mov rax, 60
    xor rdi, rdi
    syscall 