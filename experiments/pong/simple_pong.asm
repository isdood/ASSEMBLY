; Simple Pong Game in x86_64 Assembly
; Basic terminal-based Pong implementation

section .data
    ; Game constants
    SCREEN_WIDTH    equ 80
    SCREEN_HEIGHT   equ 24
    PADDLE_HEIGHT   equ 4
    PADDLE_CHAR     db '|'
    BALL_CHAR       db 'O'
    EMPTY_CHAR      db ' '
    
    ; Termios structure offsets
    TCGETS          equ 0x5401
    TCSETS          equ 0x5402
    ICANON          equ 2
    ECHO            equ 10
    TCSANOW         equ 0
    
    ; System call numbers
    SYS_IOCTL       equ 16
    SYS_READ        equ 0
    SYS_WRITE       equ 1
    SYS_EXIT        equ 60
    
    ; File descriptors
    STDIN           equ 0
    STDOUT          equ 1
    
    ; Terminal control sequences
    CLEAR_SCREEN    db 27, '[2J', 27, '[H', 0
    HIDE_CURSOR     db 27, '[?25l', 0
    SHOW_CURSOR     db 27, '[?25h', 0
    CURSOR_POS      db 27, '[', '00;', '00H', 0  ; For positioning cursor
    
    ; Game state
    left_paddle_y   db 10
    right_paddle_y  db 10
    ball_x          db 40
    ball_y          db 12
    ball_dx         db 1
    ball_dy         db 1
    
    ; Game messages
    game_title      db 'SIMPLE PONG - Q to quit', 10, 0
    game_title_len  equ $ - game_title - 1
    
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
    termios         resb 36  ; termios structure size
    old_termios     resb 36  ; to save original settings

section .text
global _start

; Set terminal to raw mode
set_raw_mode:
    ; Get current terminal settings
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCGETS
    lea rdx, [old_termios]
    syscall
    
    ; Copy to new termios
    mov rsi, old_termios
    lea rdi, [termios]
    mov rcx, 36  ; Size of termios
    rep movsb
    
    ; Disable canonical mode and echo
    and dword [termios + 12], ~(ICANON | ECHO)
    
    ; Set the new settings
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCSETS
    lea rdx, [termios]
    syscall
    ret

; Restore original terminal settings
restore_terminal:
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCSETS
    lea rdx, [old_termios]
    syscall
    ret

; Print a null-terminated string to stdout
; rsi = string address
print_string:
    push rax
    push rdi
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
    
    ; Write the string
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rdx, rcx
    syscall
    
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
    
    ; Convert row and column to ASCII
    mov al, r8b
    mov ah, 0
    mov bl, 10
    div bl
    add ax, 0x3030
    cmp al, 0x30
    jne .row_done
    mov al, ' '
.row_done:
    mov [CURSOR_POS + 2], al
    mov [CURSOR_POS + 3], ah
    
    mov al, r9b
    mov ah, 0
    div bl
    add ax, 0x3030
    cmp al, 0x30
    jne .col_done
    mov al, ' '
.col_done:
    mov [CURSOR_POS + 5], al
    mov [CURSOR_POS + 6], ah
    
    ; Print cursor position sequence
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, CURSOR_POS
    mov rdx, 8
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
    
    mov bl, PADDLE_HEIGHT
.draw_loop:
    ; Set cursor position
    movzx r8, r8b
    mov r9b, [rsp + 24]  ; Get x position from stack
    call set_cursor_pos
    
    ; Draw paddle character
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, PADDLE_CHAR
    mov rdx, 1
    push rdx  ; Save rdx
    syscall
    pop rdx   ; Restore rdx
    
    ; Move to next line
    inc byte [rsp + 32]  ; Increment y position
    dec bl
    jnz .draw_loop
    
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
    mov r8b, [ball_y]
    mov r9b, [ball_x]
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
    mov rcx, 0x3FFFFFF
.delay_loop:
    dec rcx
    jnz .delay_loop
    pop rcx
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
    ; Set up terminal
    call set_raw_mode
    
    ; Set up signal handler for clean exit
    mov rax, 13  ; rt_sigaction
    mov rdi, 2   ; SIGINT
    mov rsi, sigint_handler
    xor rdx, 0
    mov r10, 8   ; sizeof(sigset_t)
    syscall
    
    ; Clear screen
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, CLEAR_SCREEN
    mov rdx, 7
    syscall
    
    ; Print game title
    mov rsi, game_title
    call print_string
    
game_loop:
    ; Clear screen
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, CLEAR_SCREEN
    mov rdx, 7
    syscall
    
    ; Print game title
    mov rsi, game_title
    call print_string
    
    ; Check for input (non-blocking)
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, input_char
    mov rdx, 1
    mov r10, 0x541B  ; FIONREAD
    mov r8, 0        ; Non-blocking mode
    syscall
    
    ; If we have input, process it
    cmp rax, 1
    jne .no_input
    
    ; Process the input
    call handle_input
    
.no_input:
    
    ; Update game state
    call update_ball
    
    ; Draw game elements
    mov r8b, [left_paddle_y]
    mov r9b, 2
    call draw_paddle
    
    mov r8b, [right_paddle_y]
    mov r9b, 77
    call draw_paddle
    
    call draw_ball
    
    ; Small delay (shorter for more responsive controls)
    push rcx
    mov rcx, 3000000  ; Adjust this value to change game speed
.delay_loop:
    dec rcx
    jnz .delay_loop
    pop rcx
    
    ; Continue game loop
    jmp game_loop

exit:
    ; Restore terminal settings
    call restore_terminal
    
    ; Clear screen and show cursor
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, CLEAR_SCREEN
    mov rdx, 7
    syscall
    
    ; Move cursor to bottom of screen
    mov rsi, .cursor_bottom
    call print_string
    
    ; Exit program
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall 
    
.cursor_bottom db 27, '[H', 0

; Signal handler for clean exit
sigint_handler:
    ; Restore terminal settings
    call restore_terminal
    
    ; Exit with error code 130 (128 + SIGINT)
    mov rax, SYS_EXIT
    mov rdi, 130
    syscall

; Handle input
handle_input:
    ; Check for 'q' to quit
    cmp byte [input_char], 'q'
    je exit
    
    ; Check for 'w' (left paddle up)
    cmp byte [input_char], 'w'
    jne .not_w
    cmp byte [left_paddle_y], 1
    jle .not_w
    dec byte [left_paddle_y]
    ret
    
.not_w:
    ; Check for 's' (left paddle down)
    cmp byte [input_char], 's'
    jne .not_s
    mov al, [left_paddle_y]
    add al, PADDLE_HEIGHT
    cmp al, SCREEN_HEIGHT
    jge .not_s
    inc byte [left_paddle_y]
    ret
    
.not_s:
    ; Check for escape sequence (arrow keys)
    cmp byte [input_char], 0x1B
    jne .done
    
    ; Read the next two bytes of the escape sequence
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, input_char
    mov rdx, 2  ; Read 2 bytes for the arrow key sequence
    syscall
    
    cmp rax, 2
    jne .done
    
    cmp byte [input_char], '['
    jne .done
    
    cmp byte [input_char + 1], 'A'  ; Up arrow
    jne .not_up
    
    ; Move right paddle up
    cmp byte [right_paddle_y], 1
    jle .done
    dec byte [right_paddle_y]
    ret
    
.not_up:
    cmp byte [input_char + 1], 'B'  ; Down arrow
    jne .done
    
    ; Move right paddle down
    mov al, [right_paddle_y]
    add al, PADDLE_HEIGHT
    cmp al, SCREEN_HEIGHT
    jge .done
    inc byte [right_paddle_y]
    
.done:
    ret
