;;Раздел 2, задача 3
;;Программа принимает параметр командной строки n и вычисляет
;;1 + 2 + ... + 11 + 21 + 31 + ... + 91 + 2 + 12 + ...,
;;т.е. сумму реверсированных (записанных задом наперёд) чисел от 1 до n.
;;Сборка: fasm 2_3.asm && ld 2_3.o -o 2_3   (или make 2_3)
;;Запуск: ./2_3 12     -> 78   (1+2+...+9 + 1 + 11 + 21)

format ELF64
public _start

section '.data' writable
    msg_usage db 'Использование: ./2_3 <n>', 0xA, 0
    msg_bad   db 'Ошибка: параметр должен быть целым неотрицательным числом', 0xA, 0
    msg_ovf   db 'Ошибка: переполнение результата', 0xA, 0

section '.bss' writable
    buffer rb 30

section '.text' executable

include 'func.asm'

_start:
    pop rcx                 ;количество параметров командной строки
    cmp rcx, 2
    jne .usage

    mov rsi, [rsp+8]        ;адрес параметра n
    call is_number
    cmp rax, 0
    je .bad
    call str_number
    mov rbx, rax            ;rbx = n

    xor r14, r14            ;сумма
    mov r12, 1              ;k = 1
    .iter:
        cmp r12, rbx
        ja .print
        mov rax, r12
        call reverse        ;rax = k, записанное задом наперёд
        add r14, rax
        jc .overflow
        inc r12
        jmp .iter

    .print:
    mov rax, r14
    mov rsi, buffer
    call number_str
    call print_str
    call new_line
    call exit

    .usage:
        mov rsi, msg_usage
        jmp .error
    .bad:
        mov rsi, msg_bad
        jmp .error
    .overflow:
        mov rsi, msg_ovf
    .error:
        call print_str
        call exit_error

;The function reverses the number (123 -> 321)
;input rax - number
;output rax - reversed number
reverse:
    push rbx
    push rcx
    push rdx
    xor rbx, rbx            ;результат
    mov rcx, 10
    .iter:
        xor rdx, rdx
        div rcx             ;rdx = последняя цифра, rax = оставшаяся часть числа
        imul rbx, rbx, 10
        add rbx, rdx
        cmp rax, 0
        jne .iter
    mov rax, rbx
    pop rdx
    pop rcx
    pop rbx
    ret

;The function checks that the string contains only digits (no more than 19)
;input rsi - place of memory of begin string
;output rax - 1 - number, 0 - not a number
is_number:
    push rcx
    xor rcx, rcx
    .iter:
        xor rax, rax
        mov al, byte [rsi+rcx]
        cmp al, 0
        je .finish
        cmp al, '0'
        jl .no
        cmp al, '9'
        jg .no
        inc rcx
        jmp .iter
    .finish:
        cmp rcx, 0          ;пустая строка
        je .no
        cmp rcx, 19         ;больше 19 цифр не помещается в 64 бита
        jg .no
        mov rax, 1
        pop rcx
        ret
    .no:
        xor rax, rax
        pop rcx
        ret

;Function exit with error code 1
exit_error:
    mov rax, 60
    mov rdi, 1
    syscall
