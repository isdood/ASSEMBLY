; Pong Game in x86_64 Assembly
; A simple terminal-based Pong implementation

section .data
    ; Debug messages
    debug_loop      db 'Screen cleared, drawing frame...', 10
    debug_loop_len  equ $ - debug_loop
    loop_count      db 0
    debug_msg       db 'Starting Pong game...', 10
    debug_msg_len   equ $ - debug_msg
    debug_msg2      db 'Terminal setup complete, entering game loop...', 10
    debug_msg2_len  equ $ - debug_msg2
    
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
    
    ; Terminal control constants
    STDIN           equ 0
    ICANON          equ 2
    ECHO            equ 8
    
    ; System call numbers
    SYS_READ        equ 0
    SYS_WRITE       equ 1
    SYS_IOCTL       equ 16
    SYS_NANOSLEEP   equ 35
    SYS_EXIT        equ 60
    
    ; ioctl commands
    TCGETS          equ 0x5401
    TCSETS          equ 0x5402
    FIONREAD        equ 0x541B

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

; Set terminal to non-canonical mode
disable_canonical_mode:
    push rbp
    mov rbp, rsp
    sub rsp, 60                 ; Allocate space for termios structure (60 bytes)
    
    ; Get current terminal settings
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCGETS
    lea rdx, [rsp]             ; Use stack space for termios
    syscall
    
    ; Disable canonical mode and echo
    and dword [rsp + 12], ~(ICANON | ECHO)  ; c_lflag is at offset 12
    
    ; Set minimum number of characters for non-canonical read to 1
    mov byte [rsp + 24 + 6], 1  ; VMIN (c_cc[6])
    mov byte [rsp + 24 + 7], 0  ; VTIME (c_cc[7])
    
    ; Apply new terminal settings
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCSETS
    lea rdx, [rsp]             ; Use stack space for termios
    syscall
    
    mov rsp, rbp
    pop rbp
    ret

; Restore terminal to canonical mode (not used in this version)
restore_canonical_mode:
    ret

; Read a single character from stdin
; Returns: al = character read (0 if no character available)
read_char:
    push rdi
    push rsi
    push rdx
    
    ; First check if there's any input available
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, FIONREAD
    lea rdx, [rsp-8]            ; Use stack space for result
    syscall
    
    ; If no characters available, return 0
    cmp qword [rsp-8], 0
    jle .no_input
    
    ; Read one character
    mov rax, SYS_READ
    mov rdi, STDIN
    lea rsi, [input_char]
    mov rdx, 1
    syscall
    
    ; Return the character
    mov al, [input_char]
    jmp .done
    
.no_input:
    xor eax, eax                ; Return 0 if no input
    
.done:
    pop rdx
    pop rsi
    pop rdi
    ret

; Check for keyboard input and update game state
handle_input:
    push rbx
    
    ; Keep reading characters until input queue is empty
.input_loop:
    call read_char
    test al, al
    jz .input_done             ; No more input
    
    ; Check for 'q' to quit
    cmp al, KEY_Q
    je exit
    
    ; Check for 'w' (left paddle up)
    cmp al, KEY_W
    jne .not_w
    
    ; Move left paddle up (but not above top)
    mov bl, [left_paddle_y]
    cmp bl, 1
    jle .input_loop
    dec byte [left_paddle_y]
    jmp .input_loop
    
.not_w:
    ; Check for 's' (left paddle down)
    cmp al, KEY_S
    jne .not_s
    
    ; Move left paddle down (but not below bottom)
    mov bl, [left_paddle_y]
    add bl, PADDLE_HEIGHT
    cmp bl, SCREEN_HEIGHT
    jge .input_loop
    inc byte [left_paddle_y]
    jmp .input_loop
    
.not_s:
    ; Check for escape sequence (arrow keys)
    cmp al, ESCAPE
    jne .input_loop
    
    ; Read the next byte of the escape sequence
    call read_char
    test al, al
    jz .input_done
    
    cmp al, BRACKET
    jne .input_loop
    
    ; Read the arrow key
    call read_char
    test al, al
    jz .input_done
    
    ; Check for up arrow (right paddle up)
    cmp al, KEY_UP
    jne .not_up
    
    ; Move right paddle up (but not above top)
    mov bl, [right_paddle_y]
    cmp bl, 1
    jle .input_loop
    dec byte [right_paddle_y]
    jmp .input_loop
    
.not_up:
    ; Check for down arrow (right paddle down)
    cmp al, KEY_DOWN
    jne .input_loop
    
    ; Move right paddle down (but not below bottom)
    mov bl, [right_paddle_y]
    add bl, PADDLE_HEIGHT
    cmp bl, SCREEN_HEIGHT
    jge .input_loop
    inc byte [right_paddle_y]
    jmp .input_loop
    
.input_done:
    pop rbx
    ret

_start:
    ; Initialize game state
    mov byte [left_paddle_y], 10    ; Center left paddle
    mov byte [right_paddle_y], 10   ; Center right paddle
    mov byte [ball_x], 40           ; Center ball horizontally
    mov byte [ball_y], 12           ; Center ball vertically
    mov byte [ball_dx], 1           ; Initial ball direction
    mov byte [ball_dy], 1

    ; Debug: Print a message to see if we get here
    mov rax, 1                      ; sys_write
    mov rdi, 1                      ; stdout
    mov rsi, debug_msg
    mov rdx, debug_msg_len
    syscall

    ; Set up terminal
    call disable_canonical_mode
    
    ; Hide cursor
    mov rax, 1
    mov rdi, 1
    mov rsi, HIDE_CURSOR
    mov rdx, 6
    syscall
    
    ; Debug: Print another message after cursor hide
    mov rax, 1                      ; sys_write
    mov rdi, 1                      ; stdout
    mov rsi, debug_msg2
    mov rdx, debug_msg2_len
    syscall

game_loop:
    ; Debug: Print loop counter
    inc byte [loop_count]
    
    ; Handle keyboard input
    call handle_input
    
    ; Clear screen
    mov rax, 1
    mov rdi, 1
    mov rsi, CLEAR_SCREEN
    mov rdx, 7
    syscall
    
    ; Debug: Check if clear screen worked
    mov rax, 1
    mov rdi, 1
    mov rsi, debug_loop
    mov rdx, debug_loop_len
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

    ; Small delay (adjust as needed for game speed)
    push rdi
    push rsi
    
    ; Set up timespec for nanosleep
    sub rsp, 16
    mov qword [rsp], 0          ; seconds
    mov qword [rsp+8], 50000000 ; nanoseconds (50ms)
    
    mov rax, SYS_NANOSLEEP
    mov rdi, rsp                ; req (requested time)
    xor rsi, rsi                ; rem (remaining time, not used)
    syscall
    
    add rsp, 16
    pop rsi
    pop rdi

    jmp game_loop

exit:
    ; Restore terminal settings
    call restore_canonical_mode
    
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