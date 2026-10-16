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

; [bp-4]  width: right - left + 1
; [bp-2]  current row
; [bp+4]  attribute
; [bp+6]  text pointer
; [bp+8]  right
; [bp+10] left
; [bp+12] last row
; [bp+14] first row

; stream_text(firstRow, lastRow, left, right, textPtr, attr) return ax = next unread position
; long lines wrap onto the next row
stream_text:
    push bp
    mov bp, sp
    sub sp, 4
    push cx
    push si
    push di
    push es
    cld
    mov ax, 0xb800
    mov es, ax
    mov ax, [bp+14]             ; first row
    mov [bp-2], ax
    mov ax, [bp+8]              ; right
    sub ax, [bp+10]             ; - left
    inc ax
    mov [bp-4], ax              ; characters that fit between margins
    mov si, [bp+6]              ; pointer to text
st_line:
    mov ax, [bp-2]
    cmp ax, [bp+12]             ; last row
    ja st_done                  ; no more rows available
    cmp byte [si], 0xff
    je st_done                  ; end of document
    push ax                     ; row
    mov ax, [bp+10]
    push ax                     ; left
    call calculate_offset
    mov di, ax
    mov ah, [bp+4]              ; attribute
    mov cx, [bp-4]
st_ch:
    lodsb                       ; load in al
    or al, al
    jz st_eol                   ; end of line inside the width
    stosw                       ; display from ax
    loop st_ch
    cmp byte [si], 0            ; check if the row to be displayed finished
    jne st_eol                  ; no line continues on next row 
    inc si                      ; yes skip the terminator
st_eol:
    inc word [bp-2]             ; move to the next row
    jmp st_line
st_done:
    mov ax, si                  ; return resume pointer
    pop es
    pop di
    pop si
    pop cx
    mov sp, bp
    pop bp
    ret 12

; [bp-10] rows to  be  moved / blank
; [bp-8]  current row
; [bp-6]  n (clamped)
; [bp-4]  interior height : bottom -  top - 1 
; [bp-2]  interior width : right - left - 1 
; [bp+4]  n (lines to scroll)
; [bp+6]  right
; [bp+8]  bottom
; [bp+10] left
; [bp+12] top

; scroll_window_up(top, left, bottom, right, n)
; moves only the interior up by n rows, so the border is safe
scroll_window_up:
    push bp
    mov bp, sp
    sub sp, 10
    push ax
    push cx
    push si
    push di
    push ds
    push es
    cld
    mov ax, [bp+6]              ; right
    sub ax, [bp+10]             ; - left
    dec ax
    mov [bp-2], ax              ; interior width
    mov ax, [bp+8]              ; bottom
    sub ax, [bp+12]             ; - top
    dec ax
    mov [bp-4], ax              ; interior height
    mov ax, [bp+4]              ; n
    cmp ax, [bp-4]
    jbe sw_n_OK
    mov ax, [bp-4]              ; clamp n down to the interior height In-case n > interior height
sw_n_OK:
    mov [bp-6], ax
    mov ax, [bp+12]             ; top
    inc ax
    mov [bp-8], ax              ; first interior row
    mov ax, [bp-4]
    sub ax, [bp-6]
    mov [bp-10], ax             ; rows to be moved interior height - n
    mov ax, 0xb800
    mov ds, ax
    mov es, ax

sw_move:
    cmp word [bp-10], 0
    je sw_blank
    mov ax, [bp-8]              ; destination row
    push ax
    mov ax, [bp+10]             ; left
    inc ax                      ; left + 1 First interior column
    push ax
    call calculate_offset
    mov di, ax
    mov ax, [bp-8]              ; source = destination row + n
    add ax, [bp-6]
    push ax
    mov ax, [bp+10]             ; left
    inc ax                      ; left + 1 First interior column
    push ax
    call calculate_offset
    mov si, ax
    mov cx, [bp-2]
    rep movsw                   
    inc word [bp-8]      
    dec word [bp-10]
    jmp sw_move

sw_blank:
    mov ax, [bp-6]
    mov [bp-10], ax             ; n rows to be blank
sw_bl:
    cmp word [bp-10], 0
    je sw_done
    mov ax, [bp-8]              ; current row to be blanked 
    push ax
    mov ax, [bp+10]
    inc ax
    push ax
    call calculate_offset
    mov di, ax
    mov cx, [bp-2]
    mov ax, 0x0720              ; black space 
    rep stosw
    inc word [bp-8]
    dec word [bp-10]
    jmp sw_bl

sw_done:
    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop ax
    mov sp, bp
    pop bp
    ret 10

; [bp-90] Stack buffer of 80 bytes 
; [bp-10] Scan position in Stack buffer
; [bp-8]  pattern length
; [bp-6]  interior width : right - left - 1
; [bp-4]  current row
; [bp-2]  match count
; [bp+4]  highlight attribute
; [bp+6]  pattern terminated by 0 
; [bp+8]  right
; [bp+10] bottom
; [bp+12] left
; [bp+14] top

; find_and_highlight(top, left, bottom, right, pattern, attribute) return ax = number of matches
; copies each row's characters into a stack,then scans it for pattern 
; with SCASB + REPE CMPSB and rewrites only attribute 
find_and_highlight:
    push bp
    mov bp, sp
    sub sp, 90
    push bx
    push cx
    push si
    push di
    push ds
    push es
    cld
    mov word [bp-2], 0          ; match count
    mov ax, cs
    mov ds, ax                  
    mov es, ax
    mov di, [bp+6]              ; pattern 
    xor al, al
    mov cx, 0xffff
    repne scasb                 ; find terminating 0
    mov ax, 0xfffe
    sub ax, cx
    mov [bp-8], ax              ; pattern length
    mov ax, [bp+8]              ; right
    sub ax, [bp+12]             ; - left
    dec ax
    mov [bp-6], ax              ; interior width
    cmp word [bp-8], 0
    je fh_done                  ; empty check
    cmp ax, [bp-8]              ; row length less than pattern length
    jl fh_done                  ; pattern longer than the window
    mov ax, [bp+14]             ; top
    inc ax                      ; skip border
    mov [bp-4], ax              ; first interior row

fh_row:
    mov ax, [bp-4]              ; current row 
    cmp ax, [bp+10]             ; bottom
    jae fh_done                 
    push ax                     ; row
    mov ax, [bp+12]             ; left column
    inc ax                      
    push ax
    call calculate_offset
    mov si, ax                  ; start of row 
    mov ax, 0xb800
    mov ds, ax                  ; DS:SI row on Video Memory
    mov ax, ss
    mov es, ax
    mov di, bp
    sub di, 90                  ; ES:DI row on Stack 
    mov cx, [bp-6]
fh_copy:
    lodsb                       ; load a byte from AL from Video Memory
    inc si                      ; no Need for Attribute byte
    stosb                       ; store loaded byte in Stack
    loop fh_copy
    mov ax, cs
    mov ds, ax                  ; pattern segment
    mov word [bp-10], 0         

fh_pos:
    mov ax, ss
    mov es, ax
    mov ax, [bp-6]
    sub ax, [bp-8]              
    cmp [bp-10], ax
    ja fh_nextrow
    mov bx, [bp+6]              ; pattern
    mov al, [bx]                ; pattern first character
    mov di, bp
    sub di, 90
    add di, [bp-10]             ; buffer + position
    scasb                       
    jne fh_nomatch              ; move to next position on stack 
    mov si, bx
    inc si    
    mov cx, [bp-8]                  
    dec cx                      ; characters still to compare
    cmp al, al                  ; 1 char pattern check 
    repe cmpsb
    jne fh_nomatch
    inc word [bp-2]             ; match found
    mov ax, [bp-4]              ; current row
    push ax
    mov ax, [bp+12]
    inc ax
    add ax, [bp-10]             ; column = left + 1 + position
    push ax
    call calculate_offset
    mov di, ax
    inc di                      ; point at the attribute byte
    mov ax, 0xb800
    mov es, ax
    mov cx, [bp-8]
    mov al, [bp+4]              ; load new attribute
fh_hl:
    stosb                       ; change attribute only
    inc di                      ; skip character byte
    loop fh_hl
    mov ax, [bp-8]
    add [bp-10], ax             ; continue after the match
    jmp fh_pos

fh_nomatch:
    inc word [bp-10]
    jmp fh_pos

fh_nextrow:
    inc word [bp-4]
    jmp fh_row

fh_done:
    mov ax, [bp-2]              ; return match count
    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop bx
    mov sp, bp
    pop bp
    ret 12

start:          

mov ax, 0x4c00
int 0x21