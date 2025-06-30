; Simple Pong Game in x86_64 Assembly
; A basic terminal-based Pong implementation

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
    game_title      db 'PONG - W/S: Left Paddle  Arrows: Right Paddle  Q: Quit', 10, 0
    
    ; System call numbers
    SYS_READ        equ 0
    SYS_WRITE       equ 1
    SYS_EXIT        equ 60
    
    ; File descriptors
    STDIN           equ 0
    STDOUT          equ 1

section .bss
    input_char      resb 1

section .text
global _start

; Print a null-terminated string to stdout
; rsi = string address
print_string:
    push rax
    push rdi
    push rdx
    push rsi
    
    ; Calculate string length
    mov rdi, rsi
    xor rcx, rcx
    not rcx
    xor al, al
    cld
    repne scasb
    not rcx
    dec rcx
    
    ; Write the string
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rdx, rcx
    syscall
    
    pop rsi
    pop rdx
    pop rdi
    pop rax
    ret

; Set cursor position
; r8b = row, r9b = column
set_cursor_pos:
    push rax
    push rdi
    push rsi
    push rdx
    
    ; Build cursor position string
    mov rsi, cursor_buf
    mov byte [rsi], 27
    mov byte [rsi+1], '['
    
    ; Convert row to ASCII
    mov al, r8b
    xor ah, ah
    mov bl, 10
    div bl
    add ax, 0x3030
    cmp al, '0'
    jne .row_done
    mov al, ' '
.row_done:
    mov [rsi+2], al
    mov [rsi+3], ah
    
    ; Add semicolon
    mov byte [rsi+4], ';'
    
    ; Convert column to ASCII
    mov al, r9b
    xor ah, ah
    div bl
    add ax, 0x3030
    cmp al, '0'
    jne .col_done
    mov al, ' '
.col_done:
    mov [rsi+5], al
    mov [rsi+6], ah
    
    ; Add 'H' and null terminator
    mov word [rsi+7], 'H'
    mov byte [rsi+8], 0
    
    ; Print cursor position sequence
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [cursor_buf]
    mov rdx, 9
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Draw a paddle
; r8b = y position, r9b = x position
draw_paddle:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    mov bl, PADDLE_HEIGHT
    movzx r8, r8b
    
.draw_loop:
    ; Set cursor position
    push r8
    push r9
    call set_cursor_pos
    pop r9
    pop r8
    
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
    
    pop rdi
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
    
    ; Set cursor position
    movzx r8, byte [ball_y]
    movzx r9, byte [ball_x]
    call set_cursor_pos
    
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

; Simple delay
delay:
    push rcx
    mov rcx, 0x3FFFFFF
.delay_loop:
    dec rcx
    jnz .delay_loop
    pop rcx
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
    ; Check for escape sequence (arrow keys)
    cmp byte [input_char], 0x1B
    jne .done
    
    ; Read the next byte of the escape sequence
    mov rax, SYS_READ
    mov rdi, STDIN
    lea rsi, [input_char]
    mov rdx, 1
    syscall
    
    cmp rax, 1
    jne .done
    
    cmp byte [input_char], '['
    jne .done
    
    ; Read the arrow key
    mov rax, SYS_READ
    mov rdi, STDIN
    lea rsi, [input_char]
    mov rdx, 1
    syscall
    
    cmp rax, 1
    jne .done
    
    ; Check for up arrow (right paddle up)
    cmp byte [input_char], 'A'
    jne .not_up
    
    ; Move right paddle up
    cmp byte [right_paddle_y], 1
    jle .done
    dec byte [right_paddle_y]
    jmp .done
    
.not_up:
    ; Check for down arrow (right paddle down)
    cmp byte [input_char], 'B'
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

section .bss
    cursor_buf resb 16
