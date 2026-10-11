; viewport.asm
; Assignment 03 
; Abdul Wahab Nauman (25L-0616)
; nasm viewport.asm -o viewport.com -l viewport.lst

[org 0x0100]
jmp start

title:    db ' Text Viewport Manager - 8088 Assembly ', 0   
keyword:  db 'stack', 0                     ; pattern to be Searched 
status_a: db 'Total Matches Found: ', 0
status_b: db ' | Viewport Status: ACTIVE     ', 0

; Every line ends with 0
; Lone 0 is a blank line
; 0xFF is end of doc

doc:
 db 'The 8088 processor keeps its call frames on the stack.',0
 db 'Every CALL pushes a return address onto the stack, and',0
 db 'RET pops it back into the instruction pointer.',0
 db 0
 db 'A procedure begins by saving BP and copying SP into it.',0
 db 'Parameters live above BP, while locals live below it,',0
 db 'carved out of the stack with a simple SUB SP, N.',0
 db 0
 db 'Video memory in text mode starts at segment 0B800h.',0
 db 'Each cell is two bytes: the ASCII code and an attribute',0
 db 'byte that selects the foreground and background colour.',0
 db 0
 db 'String instructions walk memory using SI and DI, and',0
 db 'the direction flag decides if they move up or down.',0
 db 'MOVSW copies a cell, STOSW fills one, LODSB reads one.',0
 db 0
 db 'REPE CMPSB compares two buffers until a byte differs,',0
 db 'which makes it ideal for matching a keyword in text.',0
 db 0
 db 'Scrolling a window means copying each row upward by the',0
 db 'row stride, then blanking the rows that were vacated.',0
 db 0
 db 'The borders stay untouched because only the interior',0
 db 'cells are ever moved; the outer frame is never copied.',0
 db 0
 db 'Callee cleanup with RET n keeps the stack balanced,',0
 db 'so no caller has to ADD SP after every single CALL.',0
 db 0
 db 'Good assembly programs respect the stack discipline.',0
 db 0xFF

clear_screen:   
    push bp
    mov bp, sp
    push ax
    push cx
    push di
    push es
    cld
    mov ax, 0xb800
    mov es, ax
    mov di, 0
    mov ah, [bp+4]    ; attribute
    mov al, 0x20      ; space ASCII
    mov cx, 2000
    rep stosw
    pop es
    pop di
    pop cx
    pop ax
    pop bp
    ret 2

start:          

mov ax, 0x4c00
int 0x21