.model small
.stack

.data
    hello_message db 'Hello!', 13, 10, '$'
    result_message db 'The result is: $'
    input_invitation db 'Please enter an integer value: $'
    type_exception_message db 'Enter only decimal numbers!', 13, 10, '$'
    overflow_exception_message db 'The number should be between -32,768 and 32,752.', 13, 10, '$'
    new_line db 13, 10, '$'
    
    buffer db 7, ?, 7 dup('$')
    buffer_size dw 6
    
    number dw ?
    supplement dw 15
    max_value dw 32752
    min_value dw -32768

.code
main proc
    mov ax, @data
    mov ds, ax

    lea dx, hello_message
    mov ah, 9
    int 21h
    
    call read_int
    
    lea dx, result_message
    mov ah, 9
    int 21h
    
    call print_int
    
    mov ah, 4ch
    int 21h
main endp

read_int proc
    input_loop:
        lea dx, input_invitation
        mov ah, 9
        int 21h

        lea dx, buffer
        mov ah, 0Ah
        int 21h
        
        lea dx, new_line
        mov ah, 9
        int 21h

        mov si, offset buffer + 2
        mov al, [si]
        
        cmp al, '-'
        je negative_input
        jne positive_input

        positive_input:
            mov cx, 0
        
            positive_check_loop:
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
            jmp positive_check_loop
            
        negative_input:
            inc si
            
            negative_check_loop:
                mov al, [si]

                cmp al, '0'
                jb type_exception

                cmp al, '9'
                ja type_exception

                inc si
                mov al, [si]

                cmp al, 0dh
                je type_success
            jmp negative_check_loop
        
        reset_buffer:
            mov cx, buffer_size
            mov si, offset buffer + 2

            reset_loop:
                mov byte ptr [si], '$'
                inc si
            loop reset_loop
            
            jmp input_loop

        type_exception:
            lea dx, type_exception_message
            mov ah, 9
            int 21h
            jmp reset_buffer
            
        overflow_exception:
            lea dx, overflow_exception_message
            mov ah, 9
            int 21h
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
                cmp ax, min_value
                jb overflow_exception
                jmp convert_done
             
            positive_int_done:
                cmp ax, max_value
                ja overflow_exception
                jmp convert_done

            convert_done:
                add ax, supplement
                mov number, ax
                ret 
read_int endp

print_int proc
    mov bx, number
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
end main