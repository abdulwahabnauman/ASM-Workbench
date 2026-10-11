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

calculate_offset:    
    push bp
    mov bp, sp
    push dx
    mov ax, [bp+6]     ; row
    mov dx, 80
    mul dx             ; AX = row * 80
    add ax, [bp+4]     ; + col
    shl ax, 1          ; * 2 bytes per cell
    pop dx
    pop bp
    ret 4

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

; [bp-4]  current row
; [bp-2]  interior width
; [bp+4]  attribute
; [bp+6]  right
; [bp+8]  bottom
; [bp+10] left
; [bp+12] top

; draw_window(top, left, bottom, right, attribute)

draw_window:    
    push bp
    mov bp, sp
    sub sp, 4
    push ax
    push cx           
    push di 
    push es
    cld                         ; DF = 0
    mov ax, 0xb800
    mov es, ax
    mov ax, [bp+6]              ; right
    sub ax, [bp+10]             ; left
    dec ax
    mov [bp-2], ax              ; columns between corners
    mov ax, [bp+12]             ; top 
    push ax
    mov ax, [bp+10]             ; left
    push ax
    call calculate_offset
    mov di, ax
    mov ah, [bp+4]              ; attrubute
    mov al, 0xc9                ; top-left corner symbol
    stosw                       ; Once 
    mov al, 0xcd                ; horizontal symbol
    mov cx, [bp-2]
    rep stosw
    mov al, 0xbb                ; top-right corner symbol
    stosw                       ; Once
    mov ax, [bp+12]   
    inc ax                      ; row below top
    mov [bp-4], ax

draw_window_rows:       
    mov ax, [bp-4]
    cmp ax, [bp+8]              ; Check if all rows are done
    jae draw_window_bottom
    push ax
    mov ax, [bp+10]             ; left
    push ax
    call calculate_offset
    mov di, ax
    mov ah, [bp+4]
    mov al, 0xba                ; vertical symbol
    stosw                       ; Draw left border
    mov cx, [bp-2]
    shl cx, 1
    add di, cx                  ; Skip interior columns 
    stosw                       ; Draw rightt border
    inc word [bp-4]             ; Next row 
    jmp draw_window_rows

draw_window_bottom:      
    mov ax, [bp+8]               
    push ax
    mov ax, [bp+10]            
    push ax
    call calculate_offset
    mov di, ax
    mov ah, [bp+4]
    mov al, 0xc8                ; bottom-left corner symbol
    stosw                       ; Once 
    mov al, 0xcd                ; horizontal symbol
    mov cx, [bp-2]           
    rep stosw 
    mov al, 0xbc                ; bottom-right corner symbol
    stosw                       ; Once 
    pop es
    pop di
    pop cx
    pop ax
    mov sp, bp
    pop bp
    ret 10

; [bp-2]  length of string
; [bp+4]  attribute
; [bp+6]  string 
; [bp+8]  column
; [bp+10] row

; printString(row, column, string, attribute) return ax = First Free column after the string
printString:
    push bp
    mov bp, sp
    sub sp, 2
    push si
    push di
    push es
    mov word [bp-2], 0
    cld
    mov ax, 0xb800
    mov es, ax
    mov ax, [bp+10]             ; row
    push ax
    mov ax, [bp+8]              ; column
    push ax
    call calculate_offset
    mov di, ax
    mov si, [bp+6]
    mov ah, [bp+4]              ; attribute
ps_next:
    lodsb
    or al, al
    jz ps_end
    stosw
    inc word [bp-2]
    jmp ps_next
ps_end:
    mov ax, [bp+8]
    add ax, [bp-2]              ; return next column => column + length
    pop es
    pop di
    pop si
    mov sp, bp
    pop bp
    ret 8

; [bp-4]  digits printed
; [bp-2]  digits left
; [bp+4]  attribute
; [bp+6]  num
; [bp+8]  column
; [bp+10] row

; printNum(row, column, number, attribute) return ax = column after the number
printNum:
    push bp
    mov bp, sp
    sub sp, 4
    push bx
    push dx
    push di
    push es
    mov word [bp-2], 0
    mov word [bp-4], 0
    mov ax, [bp+6]
    mov bx, 10
pn_divide:
    mov dx, 0
    div bx
    push dx                     ; remainder
    inc word [bp-2]
    cmp ax, 0
    jnz pn_divide
    mov ax, [bp+10]             ; row
    push ax
    mov ax, [bp+8]              ; column
    push ax
    call calculate_offset
    mov di, ax
    cld
    mov ax, 0xb800
    mov es, ax
pn_next:
    pop dx                      ; MSD First
    mov al, dl
    add al, 0x30                ; Convert Digit to ASCII
    mov ah, [bp+4]
    stosw
    inc word [bp-4]
    dec word [bp-2]
    jnz pn_next
    mov ax, [bp+8]
    add ax, [bp-4]              ; return next column => column + digits printed
    pop es
    pop di
    pop dx
    pop bx
    mov sp, bp
    pop bp
    ret 8

start:          

mov ax, 0x4c00
int 0x21