; Pong Game in x86_64 Assembly (Simplified)
; A basic terminal-based Pong implementation

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
    
    ; Key codes
    KEY_UP          equ 0x41
    KEY_DOWN        equ 0x42
    KEY_W           equ 'w'
    KEY_S           equ 's'
    KEY_Q           equ 'q'
    ESCAPE          equ 0x1b
    BRACKET         equ '['
    
    ; System call numbers
    SYS_READ        equ 0
    SYS_WRITE       equ 1
    SYS_EXIT        equ 60
    
    ; File descriptors
    STDIN           equ 0
    STDOUT          equ 1
    
    ; Game state
    game_title      db 'PONG GAME - Press Q to quit', 10, 0
    game_title_len  equ $ - game_title - 1  ; Exclude null terminator

section .bss
    ; Game state
    left_paddle_y   resb 1    ; Y position of left paddle
    right_paddle_y  resb 1    ; Y position of right paddle
    ball_x          resb 1    ; X position of ball
    ball_y          resb 1    ; Y position of ball
    ball_dx         resb 1    ; Ball X direction (-1 or 1)
    ball_dy         resb 1    ; Ball Y direction (-1 or 1)
    cursor_pos      resb 8    ; Buffer for cursor position string
    
    ; Input buffer
    input_char      resb 1    ; Buffer for reading keyboard input
    escape_seq      resb 2    ; Buffer for escape sequences

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

section .text
global _start

; Print a string to stdout
; rsi = string address
; rdx = string length
print_string:
    push rax
    push rdi
    push rsi
    push rdx
    
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Simple delay function
delay:
    push rcx
    mov rcx, 10000000
.delay_loop:
    dec rcx
    jnz .delay_loop
    pop rcx
    ret

_start:
    ; Initialize game state
    mov byte [left_paddle_y], 10    ; Center left paddle
    mov byte [right_paddle_y], 10   ; Center right paddle
    mov byte [ball_x], 40           ; Center ball horizontally
    mov byte [ball_y], 12           ; Center ball vertically
    mov byte [ball_dx], 1           ; Initial ball direction
    mov byte [ball_dy], 1

    ; Clear screen
    mov rsi, CLEAR_SCREEN
    mov rdx, 7
    call print_string
    
    ; Print game title
    mov rsi, game_title
    mov rdx, game_title_len
    call print_string

game_loop:
    ; Clear screen and redraw everything
    mov rsi, CLEAR_SCREEN
    mov rdx, 7
    call print_string
    
    ; Print game title
    mov rsi, game_title
    mov rdx, game_title_len
    call print_string
    
    ; Handle keyboard input (non-blocking)
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, input_char
    mov rdx, 1
    mov r10, 0x541B  ; FIONREAD
    mov r8, 0        ; Non-blocking mode
    syscall
    
    ; Check if any input was read
    cmp rax, 1
    jne .no_input
    
    ; Check for 'q' to quit
    cmp byte [input_char], 'q'
    je exit
    
    ; Check for 'w' (left paddle up)
    cmp byte [input_char], 'w'
    jne .not_w
    cmp byte [left_paddle_y], 1
    jle .not_w
    dec byte [left_paddle_y]
    jmp .no_input
    
.not_w:
    ; Check for 's' (left paddle down)
    cmp byte [input_char], 's'
    jne .not_s
    mov bl, [left_paddle_y]
    add bl, PADDLE_HEIGHT
    cmp bl, SCREEN_HEIGHT
    jge .no_input
    inc byte [left_paddle_y]
    jmp .no_input
    
.not_s:
    ; Check for up arrow (right paddle up)
    cmp byte [input_char], 0x1B  ; ESC
    jne .no_input
    
    ; Read the next two bytes of the escape sequence
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, input_char
    mov rdx, 2  ; Read 2 bytes for the arrow key sequence
    syscall
    
    cmp rax, 2
    jne .no_input
    
    cmp byte [input_char], '['
    jne .no_input
    
    cmp byte [input_char+1], 'A'  ; Up arrow
    jne .not_up
    
    ; Move right paddle up
    cmp byte [right_paddle_y], 1
    jle .no_input
    dec byte [right_paddle_y]
    jmp .no_input
    
.not_up:
    cmp byte [input_char+1], 'B'  ; Down arrow
    jne .no_input
    
    ; Move right paddle down
    mov bl, [right_paddle_y]
    add bl, PADDLE_HEIGHT
    cmp bl, SCREEN_HEIGHT
    jge .no_input
    inc byte [right_paddle_y]

.no_input:

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
    
    ; Simple ball movement
    ; Update ball position
    mov al, [ball_x]
    add al, [ball_dx]
    mov [ball_x], al
    
    mov al, [ball_y]
    add al, [ball_dy]
    mov [ball_y], al
    
    ; Bounce off top and bottom
    cmp byte [ball_y], 1
    jle .bounce_y
    cmp byte [ball_y], SCREEN_HEIGHT-1
    jl .no_bounce_y
.bounce_y:
    neg byte [ball_dy]
    
.no_bounce_y:
    ; Bounce off left and right (temporary, will add scoring later)
    cmp byte [ball_x], 1
    jle .bounce_x
    cmp byte [ball_x], SCREEN_WIDTH-2
    jl .no_bounce_x
.bounce_x:
    neg byte [ball_dx]
    
.no_bounce_x:
    ; Simple delay
    call delay

    jmp game_loop

exit:
    ; Clear screen and show cursor
    mov rsi, CLEAR_SCREEN
    mov rdx, 7
    call print_string
    
    ; Move cursor to bottom of screen
    mov rsi, .cursor_bottom
    mov rdx, 3
    call print_string
    
    ; Exit program
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall 
    
.cursor_bottom db 27, '[H', 0