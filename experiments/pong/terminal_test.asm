; Minimal terminal test program

section .data
    ; Terminal control sequences
    clear_screen    db 27, '[2J', 27, '[H', 0
    hide_cursor     db 27, '[?25l', 0
    show_cursor     db 27, '[?25h', 0
    newline         db 10, 0
    
    ; Messages
    msg_hello       db 'Terminal test - Press any key to exit', 10, 0
    msg_bye         db 10, 'Goodbye!', 10, 0
    msg_setup       db 'Setting up terminal...', 10, 0
    msg_termios_get db 'Getting terminal settings...', 10, 0
    msg_termios_set db 'Setting terminal settings...', 10, 0
    msg_termios_done db 'Terminal setup complete', 10, 0
    msg_waiting     db 'Waiting for input...', 10, 0
    msg_got_input   db 'Got input: ', 0
    msg_restore     db 'Restoring terminal...', 10, 0
    msg_restore_done db 'Terminal restored', 10, 0
    
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
    
    ; Termios flags
    ICANON          equ 2
    ECHO            equ 10

section .bss
    ; Terminal settings
    termios         resb 36  ; Size of termios structure
    
    ; Input buffer
    input_char      resb 1

section .text
global _start

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

; Debug print function
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
    mov rax, 1          ; sys_write
    mov rdi, 2           ; stderr
    mov rdx, rcx         ; length
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Setup terminal in raw mode
setup_terminal:
    push rax
    push rdi
    push rsi
    push rdx
    
    mov rsi, msg_setup
    call debug_print
    
    mov rsi, msg_termios_get
    call debug_print
    
    ; Get current terminal settings
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCGETS
    lea rdx, [termios]
    syscall
    
    ; Disable canonical mode and echo
    and dword [termios + 12], ~(ICANON | ECHO)
    
    mov rsi, msg_termios_set
    call debug_print
    
    ; Apply new settings
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCSETS
    lea rdx, [termios]
    syscall
    
    mov rsi, msg_termios_done
    call debug_print
    
    ; Hide cursor
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, hide_cursor
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
    mov rsi, show_cursor
    mov rdx, 6
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Main program
_start:
    ; Set up terminal
    call setup_terminal
    
    ; Clear screen
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, clear_screen
    mov rdx, 7
    syscall
    
    ; Print hello message
    mov rsi, msg_hello
    call print_string
    
    ; Debug message
    mov rsi, msg_waiting
    call debug_print
    
    ; Wait for a keypress
    mov rax, SYS_READ
    mov rdi, STDIN
    lea rsi, [input_char]
    mov rdx, 1
    syscall
    
    ; Debug message
    push rax
    mov rsi, msg_got_input
    call debug_print
    
    ; Print the character we got
    mov rax, 1
    mov rdi, 2
    lea rsi, [input_char]
    mov rdx, 1
    syscall
    
    ; Newline
    mov rax, 1
    mov rdi, 2
    mov rsi, newline
    mov rdx, 1
    syscall
    
    pop rax
    
    ; Print goodbye message
    mov rsi, msg_bye
    call print_string
    
    ; Debug message
    mov rsi, msg_restore
    call debug_print
    
    ; Restore terminal
    call restore_terminal
    
    mov rsi, msg_restore_done
    call debug_print
    
    ; Exit program
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
