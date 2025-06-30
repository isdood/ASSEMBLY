section .data
    ; Game constants
    SCREEN_WIDTH    equ 80
    SCREEN_HEIGHT   equ 24
    PADDLE_HEIGHT   equ 4
    PADDLE_CHAR     db '|'
    BALL_CHAR       db 'O'
    
    ; Terminal control sequences
    CLEAR_SCREEN    db 27, '[2J', 27, '[H', 0
    HIDE_CURSOR     db 27, '[?25l', 0
    SHOW_CURSOR     db 27, '[?25h', 0
    
    ; Game state
    left_paddle_y   db 10
    right_paddle_y  db 10
    ball_x          db 40
    ball_y          db 12
    ball_dx         db 1
    ball_dy         db 1
    
    ; Game messages
    game_title      db 'MINI PONG - W/S: Left Paddle  Up/Down: Right Paddle  Q: Quit', 10, 0
    
    ; System call numbers
    SYS_READ        equ 0
    SYS_WRITE       equ 1
    SYS_EXIT        equ 60
    
    ; File descriptors
    STDIN           equ 0
    STDOUT          equ 1

section .bss
    input_char      resb 1
    cursor_buf      resb 16

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

; Simple delay
delay:
    push rcx
    mov rcx, 0x3FFFFFF
.delay_loop:
    dec rcx
    jnz .delay_loop
    pop rcx
    ret

; Draw a paddle
; r8b = y position, r9b = x position
draw_paddle:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    
    mov bl, PADDLE_HEIGHT
    
.draw_loop:
    ; Move cursor to position
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [CLEAR_SCREEN]  ; Just to get the cursor position sequence
    mov rdx, 2
    syscall
    
    ; Draw paddle character
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [PADDLE_CHAR]
    mov rdx, 1
    push rdx
    syscall
    pop rdx
    
    ; Move to next line
    inc r8b
    dec bl
    jnz .draw_loop
    
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; Draw the ball
draw_ball:
    push rax
    push rdi
    push rsi
    push rdx
    
    ; Move cursor to ball position
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [CLEAR_SCREEN]  ; Just to get the cursor position sequence
    mov rdx, 2
    syscall
    
    ; Draw ball character
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [BALL_CHAR]
    mov rdx, 1
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Handle input
handle_input:
    ; Try to read a character (non-blocking)
    mov rax, SYS_READ
    mov rdi, STDIN
    lea rsi, [input_char]
    mov rdx, 1
    mov r10, 0x541B  ; FIONREAD
    xor r8, r8
    syscall
    
    ; If no input, return
    cmp rax, 1
    jne .done
    
    ; Check for 'q' to quit
    cmp byte [input_char], 'q'
    je exit
    
    ; Check for 'w' (left paddle up)
    cmp byte [input_char], 'w'
    jne .not_w
    cmp byte [left_paddle_y], 1
    jle .not_w
    dec byte [left_paddle_y]
    jmp .done
    
.not_w:
    ; Check for 's' (left paddle down)
    cmp byte [input_char], 's'
    jne .not_s
    mov al, [left_paddle_y]
    add al, PADDLE_HEIGHT
    cmp al, SCREEN_HEIGHT
    jge .not_s
    inc byte [left_paddle_y]
    jmp .done
    
.not_s:
    ; Check for up arrow (right paddle up)
    cmp byte [input_char], 0x1B
    jne .done
    
    ; Read the next two bytes of the escape sequence
    mov rax, SYS_READ
    mov rdi, STDIN
    lea rsi, [input_char]
    mov rdx, 2
    syscall
    
    cmp rax, 2
    jne .done
    
    cmp byte [input_char], '['
    jne .done
    
    cmp byte [input_char+1], 'A'  ; Up arrow
    jne .not_up
    
    ; Move right paddle up
    cmp byte [right_paddle_y], 1
    jle .done
    dec byte [right_paddle_y]
    jmp .done
    
.not_up:
    cmp byte [input_char+1], 'B'  ; Down arrow
    jne .done
    
    ; Move right paddle down
    mov al, [right_paddle_y]
    add al, PADDLE_HEIGHT
    cmp al, SCREEN_HEIGHT
    jge .done
    inc byte [right_paddle_y]
    
.done:
    ret

; Update ball position
update_ball:
    ; Update x position
    mov al, [ball_dx]
    add [ball_x], al
    
    ; Bounce off left and right walls
    cmp byte [ball_x], 1
    jle .bounce_x
    cmp byte [ball_x], SCREEN_WIDTH-2
    jl .check_y
.bounce_x:
    neg byte [ball_dx]
    
.check_y:
    ; Update y position
    mov al, [ball_dy]
    add [ball_y], al
    
    ; Bounce off top and bottom
    cmp byte [ball_y], 1
    jle .bounce_y
    cmp byte [ball_y], SCREEN_HEIGHT-1
    jl .done
.bounce_y:
    neg byte [ball_dy]
    
.done:
    ret

; Main game loop
_start:
    ; Clear screen
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [CLEAR_SCREEN]
    mov rdx, 7
    syscall
    
    ; Print game title
    lea rsi, [game_title]
    call print_string

game_loop:
    ; Clear screen
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [CLEAR_SCREEN]
    mov rdx, 7
    syscall
    
    ; Print game title
    lea rsi, [game_title]
    call print_string
    
    ; Handle input
    call handle_input
    
    ; Update game state
    call update_ball
    
    ; Draw left paddle (x=2)
    movzx r8, byte [left_paddle_y]
    mov r9b, 2
    call draw_paddle
    
    ; Draw right paddle (x=77)
    movzx r8, byte [right_paddle_y]
    mov r9b, 77
    call draw_paddle
    
    ; Draw ball
    call draw_ball
    
    ; Small delay
    call delay
    
    ; Continue game loop
    jmp game_loop

exit:
    ; Clear screen and show cursor
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [CLEAR_SCREEN]
    mov rdx, 7
    syscall
    
    ; Move cursor to bottom of screen
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [SHOW_CURSOR]
    mov rdx, 6
    syscall
    
    ; Exit program
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
