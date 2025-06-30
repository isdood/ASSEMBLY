; Minimal Pong Game in x86_64 Assembly
; Simplified version with working terminal handling

section .data
    ; Game constants
    SCREEN_WIDTH    equ 80
    SCREEN_HEIGHT   equ 24
    PADDLE_HEIGHT   equ 4
    PADDLE_CHAR     db '|', 0
    BALL_CHAR       db 'O', 0
    
    ; Debug messages
    debug_start_msg      db 'Starting Pong game...', 10, 0
    debug_termios_msg    db 'Setting up terminal...', 10, 0
    debug_ioctl_msg      db 'Calling ioctl...', 10, 0
    debug_ioctl_done_msg db 'ioctl completed', 10, 0
    debug_game_loop_msg  db 'Entering game loop...', 10, 0
    debug_exit_msg       db 'Exiting game...', 10, 0
    
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
    
    ; System call numbers
    SYS_READ        equ 0
    SYS_WRITE       equ 1
    SYS_IOCTL       equ 16
    SYS_EXIT        equ 60
    
    ; File descriptors
    STDIN           equ 0
    STDOUT          equ 1
    
    ; ioctl constants
    TCGETS          equ 0x5401
    TCSETS          equ 0x5402
    FIONBIO         equ 0x5421
    
    ; Termios flags
    ICANON          equ 2
    ECHO            equ 10

section .bss
    ; Terminal settings
    termios         resb 36  ; Size of termios structure
    
    ; Input buffer
    input_char      resb 1
    
    ; Cursor position buffer
    cursor_buf      resb 16

section .text
global _start

; Print a string to stderr (for debug)
; rsi = string address
debug_print:
    push rax
    push rdi
    push rsi
    push rdx
    
    ; Calculate string length
    mov rdi, rsi
    xor rcx, rcx
    not rcx
    xor al, al
    cld
    repne scasb
    not rcx
    dec rcx
    
    ; Write to stderr (file descriptor 2)
    mov rax, SYS_WRITE
    mov rdi, 2           ; stderr
    mov rdx, rcx         ; length
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Print a string to stdout
; rsi = string address
print_string:
    push rax
    push rdi
    push rsi
    push rdx
    
    ; Calculate string length
    mov rdi, rsi
    xor rcx, rcx
    not rcx
    xor al, al
    cld
    repne scasb
    not rcx
    dec rcx
    
    ; Write string
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rdx, rcx
    syscall
    
    pop rdx
    pop rsi
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
    push rbx
    
    ; Build cursor position string
    mov byte [cursor_buf], 27    ; ESC
    mov byte [cursor_buf+1], '['
    
    ; Convert row to ASCII
    mov al, r8b
    mov bl, 10
    xor ah, ah
    div bl
    add ax, '00'
    mov [cursor_buf+2], al
    mov [cursor_buf+3], ah
    
    mov byte [cursor_buf+4], ';'
    
    ; Convert column to ASCII
    mov al, r9b
    xor ah, ah
    div bl
    add ax, '00'
    mov [cursor_buf+5], al
    mov [cursor_buf+6], ah
    
    mov byte [cursor_buf+7], 'H'
    mov byte [cursor_buf+8], 0
    
    ; Write cursor position
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, cursor_buf
    mov rdx, 8
    syscall
    
    pop rbx
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
    
    mov bl, PADDLE_HEIGHT
    
.draw_loop:
    ; Set cursor position
    call set_cursor_pos
    
    ; Draw paddle character
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, PADDLE_CHAR
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
    
    ; Set cursor position
    call set_cursor_pos
    
    ; Draw ball character
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, BALL_CHAR
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
    mov rcx, 0x3FFFFF
.delay_loop:
    dec rcx
    jnz .delay_loop
    pop rcx
    ret

; Setup terminal in raw mode
setup_terminal:
    push rax
    push rdi
    push rsi
    push rdx
    
    mov rsi, debug_termios_msg
    call debug_print
    mov rsi, debug_ioctl_msg
    call debug_print
    
    ; Get current terminal settings
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCGETS
    lea rdx, [termios]
    syscall
    
    ; Disable canonical mode and echo
    and dword [termios + 12], ~(ICANON | ECHO)
    
    ; Apply new settings
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCSETS
    lea rdx, [termios]
    syscall
    
    mov rsi, debug_ioctl_done_msg
    call debug_print
    
    ; Hide cursor
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, HIDE_CURSOR
    mov rdx, 6
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Restore terminal settings
restore_terminal:
    push rax
    push rdi
    push rsi
    push rdx
    
    ; Re-enable canonical mode and echo
    or dword [termios + 12], ICANON | ECHO
    
    ; Apply original settings
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCSETS
    lea rdx, [termios]
    syscall
    
    ; Show cursor
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, SHOW_CURSOR
    mov rdx, 6
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
    mov r10, FIONBIO
    mov r8, 1
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
    cmp byte [input_char], 0x1B  ; ESC
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
    jl .check_paddles
.bounce_y:
    neg byte [ball_dy]
    
.check_paddles:
    ; Check for paddle collisions (simplified)
    ; Left paddle
    cmp byte [ball_x], 2
    jne .check_right_paddle
    
    mov al, [ball_y]
    cmp al, [left_paddle_y]
    jl .check_right_paddle
    
    mov bl, [left_paddle_y]
    add bl, PADDLE_HEIGHT
    cmp al, bl
    jg .check_right_paddle
    
    ; Bounce off left paddle
    neg byte [ball_dx]
    jmp .done
    
.check_right_paddle:
    ; Right paddle
    cmp byte [ball_x], SCREEN_WIDTH-3
    jne .done
    
    mov al, [ball_y]
    cmp al, [right_paddle_y]
    jl .done
    
    mov bl, [right_paddle_y]
    add bl, PADDLE_HEIGHT
    cmp al, bl
    jg .done
    
    ; Bounce off right paddle
    neg byte [ball_dx]
    
.done:
    ret

; Main game loop
_start:
    ; Debug message
    mov rsi, debug_start_msg
    call debug_print
    
    ; Set up terminal
    call setup_terminal
    
    ; Initialize game state
    mov byte [left_paddle_y], 10    ; Center left paddle
    mov byte [right_paddle_y], 10   ; Center right paddle
    mov byte [ball_x], 40           ; Center ball horizontally
    mov byte [ball_y], 12           ; Center ball vertically
    mov byte [ball_dx], 1           ; Initial ball direction
    mov byte [ball_dy], 1
    
    ; Clear screen
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, CLEAR_SCREEN
    mov rdx, 7
    syscall

    mov rsi, debug_game_loop_msg
    call debug_print

game_loop:
    ; Clear screen
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, CLEAR_SCREEN
    mov rdx, 7
    syscall
    
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
    movzx r8, byte [ball_y]
    movzx r9, byte [ball_x]
    call draw_ball
    
    ; Small delay
    call delay
    
    ; Continue game loop
    jmp game_loop

exit:
    ; Debug message
    mov rsi, debug_exit_msg
    call debug_print
    
    ; Restore terminal settings
    call restore_terminal
    
    ; Clear screen
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, CLEAR_SCREEN
    mov rdx, 7
    syscall
    
    ; Exit program
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
