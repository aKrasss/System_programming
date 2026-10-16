;;Раздел 2, задача 1
;;Программа принимает параметр командной строки - нечётное число 2n+1
;;и вычисляет 1 + 3 + 5 + 7 + ... + (2n+1).
;;Если введено чётное число - выводится ошибка.
;;Сборка: fasm 2_1.asm && ld 2_1.o -o 2_1   (или make 2_1)
;;Запуск: ./2_1 7      -> 16

format ELF64
public _start

section '.data' writable
    msg_usage db 'Использование: ./2_1 <нечётное число 2n+1>', 0xA, 0
    msg_bad   db 'Ошибка: параметр должен быть целым неотрицательным числом', 0xA, 0
    msg_even  db 'Ошибка: введено чётное число', 0xA, 0
    msg_ovf   db 'Ошибка: переполнение результата', 0xA, 0

section '.bss' writable
    buffer rb 30

section '.text' executable

include 'func.asm'

_start:
    pop rcx                 ;количество параметров командной строки
    cmp rcx, 2              ;должно быть: имя программы + число
    jne .usage

    mov rsi, [rsp+8]        ;адрес первого параметра
    call is_number
    cmp rax, 0
    je .bad
    call str_number         ;rax = 2n+1

    test rax, 1             ;младший бит = 0 -> число чётное
    jz .even

    mov rbx, rax            ;последний член ряда (2n+1)
    xor r8, r8              ;сумма
    mov rcx, 1              ;текущий член ряда
    .iter:
        add r8, rcx
        jc .overflow        ;CF = 1 -> результат не помещается в 64 бита
        cmp rcx, rbx
        je .print
        add rcx, 2
        jmp .iter

    .print:
    mov rax, r8
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
    .even:
        mov rsi, msg_even
        jmp .error
    .overflow:
        mov rsi, msg_ovf
    .error:
        call print_str
        call exit_error

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
