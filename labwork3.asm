PRINT macro message
    lea dx, message
    mov ah, 9
    int 21h
    xor dx, dx
endm

.model small
.stack

.data
    hello_message db 'Hello!', 13, 10, '$'
    result_message db 'The result is: $'
    x_input_invitation db 'Please enter X: $'
    y_input_invitation db 'Please enter Y: $'
    type_exception_message db 'Enter only decimal numbers!', 13, 10, '$'
    overflow_exception_message db 'The number should be between -32,768 and 32,752.', 13, 10, '$'
    op_overflow_exception_message db 'Overflow occurred!$'
    new_line db 13, 10, '$'
    dot_character db '.$'
    
    buffer db 7, ?, 7 dup('$')
    buffer_size dw 6
    
    MAX_VALUE dw 32752
    MIN_VALUE dw -32768
    
    x_value dw ?
    y_value dw ?
    
    divide dw ?
    divider dw ?
    
    precision dw 5
    result_sign dw 0
    integer dw 1
    float db 5 dup (0)

.code

main proc
    mov ax, @data
    mov ds, ax

    PRINT hello_message
    
    mov di, offset x_input_invitation
    call read_int
    mov x_value, ax
    
    mov di, offset y_input_invitation
    call read_int
    mov y_value, ax
    
    cmp y_value, 0
    je third_case
    jg first_case
    jl second_case
    
    print_result:
        PRINT result_message
        call print_float
        mov ah, 4ch
        int 21h
    
    operation_overflow:
        PRINT op_overflow_exception_message
        mov ah, 4ch
        int 21h
    
    first_case:
        cmp x_value, 5
        jne print_result
        
        mov ax, x_value
        imul ax
        jo operation_overflow
        mov bx, x_value
        imul bx
        jo operation_overflow
        mov bx, 6
        imul bx
        jo operation_overflow
        
        mov divide, ax
        mov ax, y_value
        mov divider, ax
        
        call calculate_float
        jmp print_result
    
    second_case:
        mov ax, x_value
        mov bx, 38
        imul bx
        jo operation_overflow
        mov divide, ax

        mov ax, y_value
        mov bx, y_value
        imul bx
        jo operation_overflow
        mov bx, 5
        imul bx
        jo operation_overflow
        mov divider, ax
        
        call calculate_float
        jmp print_result
    
    third_case:
        mov ax, x_value
        imul ax
        jo operation_overflow
        mov bx, 25
        mul bx
        jo operation_overflow
        mov integer, ax
        jmp print_result
main endp

read_int proc
    input_loop:
        lea dx, [di]
        mov ah, 9
        int 21h

        lea dx, buffer
        mov ah, 0Ah
        int 21h
        
        PRINT new_line

        mov si, offset buffer + 2
        mov al, [si]
        mov cx, 0
        
        cmp al, '-'
        jne type_check_loop
        
        inc si
        inc buffer_size

        type_check_loop:
            mov al, [si]
            
            cmp al, '0'
            jb type_exception
            
            cmp al, '9'
            ja type_exception

            inc si
            inc cx
            mov al, [si]

            cmp cx, buffer_size
            je overflow_exception
                
            cmp al, 0dh
            je type_success
        jmp type_check_loop
        
        reset_buffer:
            mov cx, buffer_size
            mov si, offset buffer + 2

            reset_loop:
                mov byte ptr [si], '$'
                inc si
            loop reset_loop
            
            jmp input_loop

        type_exception:
            PRINT type_exception_message
            jmp reset_buffer
            
        overflow_exception:
            PRINT overflow_exception_message
            jmp reset_buffer

        type_success:
            xor ax, ax
            mov cx, 10
            mov si, offset buffer + 2
            mov bl, [si]
            
            cmp bl, '-'
            jne convert_positive_int
            
            inc si
            
            convert_negative_int:
                mov bl, [si]
                
                cmp bl, 0dh
                je negative_int_done
                
                sub bl, '0'
                mul cx
                sub ax, bx
                inc si
            jmp convert_negative_int
            
            convert_positive_int:
                mov bl, [si]
                
                cmp bl, 0dh
                je positive_int_done
                
                sub bl, '0'
                mul cx
                add ax, bx
                inc si
            jmp convert_positive_int
             
            negative_int_done:
                cmp ax, MIN_VALUE
                jb overflow_exception
                jmp convert_done
             
            positive_int_done:
                cmp ax, MAX_VALUE
                ja overflow_exception
                jmp convert_done

            convert_done:
                ret 
read_int endp

print_int proc
    mov bx, ax
    or bx, bx
    jns m1
    mov al, '-'
    int 29h
    neg bx
    m1:
        mov ax, bx
        xor cx, cx
        mov bx, 10
    m2:
        xor dx, dx
        div bx
        add dl, '0'
        push dx
        inc cx
        test ax, ax
        jnz m2
    m3:
        pop ax
        int 29h
        loop m3
        ret
print_int endp

calculate_float proc
    mov ax, divide
    mov bx, divider
    xor cx, cx
    
    check_divide:
        or ax, ax
        jns check_divider
        neg ax
        inc cx

    check_divider:
        or bx, bx
        jns integer_part
        neg bx
        inc cx

    integer_part:
        div bx
        jo division_overflow
        mov integer, ax
        mov ax, dx
        
        cmp cx, 1
        jne floating_part
        
        mov result_sign, 1
    
    floating_part:
        cmp ax, 0
        je success
    
        mov cx, 0
    
        column_division_loop:
            cmp cx, precision
            je success
        
            mov di, 0
        
            multiply_float_loop:
                mov dx, 10
                mul dx
                jo division_overflow
                
                cmp ax, bx
                jae continue_division
            
                inc di
            jmp multiply_float_loop

            continue_division:
                add cx, di
                jo division_overflow
            
                cmp cx, precision
                jae success
            
                div bx
                jo division_overflow
                
                mov si, offset float
                add si, cx
                mov [si], ax
            
                mov ax, dx
            
                cmp ax, 0
                je success
            
                inc cx
            jmp column_division_loop
            
    success:
        ret
        
    division_overflow:
        PRINT op_overflow_exception_message
        mov ah, 4ch
        int 21h
endp

print_float proc
    cmp result_sign, 1
    jne print_number
    
    mov al, '-'
    int 29h
    
    print_number:
        mov ax, integer
        call print_int
    
        PRINT dot_character
    
        mov cx, precision
        lea si, float

        print_loop:
            mov dl, [si]
            add dl, 48
            mov ah, 02h
            int 21h
            inc si
        loop print_loop
    
    ret
endp

end main