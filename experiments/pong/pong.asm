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

section .bss
    ; Game state
    left_paddle_y   resb 1    ; Y position of left paddle
    right_paddle_y  resb 1    ; Y position of right paddle
    ball_x          resb 1    ; X position of ball
    ball_y          resb 1    ; Y position of ball
    ball_dx         resb 1    ; Ball X direction (-1 or 1)
    ball_dy         resb 1    ; Ball Y direction (-1 or 1)

section .text
    global _start

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

    ; TODO: Handle input
    ; TODO: Update game state
    ; TODO: Draw game elements

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