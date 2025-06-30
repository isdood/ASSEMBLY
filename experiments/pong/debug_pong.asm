; Debug version of Pong with additional debug output

section .data
    ; Debug messages
    debug_msg1 db 'Starting debug output...', 10, 0
    debug_msg2 db 'Setting up terminal...', 10, 0
    debug_msg3 db 'Terminal setup complete', 10, 0
    debug_msg4 db 'Entering game loop', 10, 0
    debug_msg5 db 'Exiting...', 10, 0
    
    ; Test messages
    test_input_msg    db 'Testing input (press any key, q to quit)...', 10, 0
    prompt_msg        db '> ', 0
    got_input_msg     db 'Got input: ', 0
    no_input_msg      db 'No input', 10, 0
    input_test_done   db 'Input test complete', 10, 0
    char_buf          db 0, 0
    debug_ioctl db 'Calling ioctl...', 10, 0
    debug_ioctl_done db 'ioctl completed', 10, 0
    debug_termios db 'Termios structure at: ', 0
    debug_newline db 10, 0
    
    ; Terminal control sequences
    CLEAR_SCREEN    db 27, '[2J', 27, '[H', 0
    HIDE_CURSOR     db 27, '[?25l', 0
    SHOW_CURSOR     db 27, '[?25h', 0
    
    ; System call numbers
    SYS_IOCTL       equ 16
    SYS_WRITE       equ 1
    SYS_EXIT        equ 60
    
    ; File descriptors
    STDIN           equ 0
    STDOUT          equ 1
    STDERR          equ 2
    
    ; ioctl constants
    TCGETS          equ 0x5401
    TCSETS          equ 0x5402
    
    ; Termios flags
    ICANON          equ 2
    ECHO            equ 10

section .bss
    ; Terminal settings
    termios         resb 36  ; Size of termios structure
    
    ; Debug buffer
    debug_buf       resb 32
    
    ; Input buffer
    input_buf       resb 1

section .text
global _start

; Debug print function
; rsi = message to print
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
    
    ; Write to stderr (fd=2)
    mov rax, SYS_WRITE
    mov rdi, STDERR
    mov rdx, rcx        ; length
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Print a number in hex
; rax = number to print
debug_print_hex:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    
    lea rdi, [debug_buf + 15]  ; Start at the end of the buffer
    mov byte [rdi], 0            ; Null terminator
    mov rcx, 16                  ; 16 hex digits
    
.next_digit:
    dec rdi
    mov rbx, rax
    and rbx, 0xF
    cmp rbx, 10
    jb .is_digit
    add bl, 'a' - 10 - '0'
.is_digit:
    add bl, '0'
    mov [rdi], bl
    
    shr rax, 4
    loop .next_digit
    
    ; Print the hex number
    mov rsi, rdi
    call debug_print
    
    ; Print newline
    mov rsi, debug_newline
    call debug_print
    
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; Setup terminal in raw mode
setup_terminal:
    push rax
    push rdi
    push rsi
    push rdx
    
    mov rsi, debug_msg2
    call debug_print
    
    ; Get current terminal settings
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCGETS
    lea rdx, [termios]
    
    mov rsi, debug_ioctl
    call debug_print
    
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCGETS
    lea rdx, [termios]
    syscall
    
    mov rsi, debug_ioctl_done
    call debug_print
    
    ; Print termios address
    mov rsi, debug_termios
    call debug_print
    lea rax, [termios]
    call debug_print_hex
    
    ; Disable canonical mode and echo
    and dword [termios + 12], ~(ICANON | ECHO)
    
    ; Apply new settings
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCSETS
    lea rdx, [termios]
    syscall
    
    ; Hide cursor
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, HIDE_CURSOR
    mov rdx, 6
    syscall
    
    mov rsi, debug_msg3
    call debug_print
    
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

_start:
    ; Print debug message
    mov rsi, debug_msg1
    call debug_print
    
    ; Setup terminal
    call setup_terminal
    
    ; Print message
    mov rsi, debug_msg4
    call debug_print
    
    ; Test non-blocking input
    mov rsi, test_input_msg
    call debug_print
    
    ; Set non-blocking mode
    mov rax, 16  ; ioctl
    mov rdi, 0   ; stdin
    mov rsi, 0x5421  ; FIONBIO
    mov rdx, 1   ; non-zero = non-blocking
    syscall
    
    ; Simple input test - just wait for a key
    mov rsi, prompt_msg
    call debug_print
    
    ; Read a single character
    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    lea rsi, [input_buf]
    mov rdx, 1          ; read 1 byte
    syscall
    
    ; Print what we got
    mov rsi, got_input_msg
    call debug_print
    
    mov al, [input_buf]
    mov [char_buf], al
    mov rsi, char_buf
    call debug_print
    
    mov rsi, debug_newline
    call debug_print
    
.input_done:
    mov rsi, input_test_done
    call debug_print
    
    ; Small delay to see the output
    mov rcx, 0x3FFFFFF
.delay_loop:
    dec rcx
    jnz .delay_loop
    
    ; Restore terminal
    call restore_terminal
    
    ; Exit
    mov rsi, debug_msg5
    call debug_print
    
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
