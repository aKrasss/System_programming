;;Раздел 2, задача 4
;;Программа принимает два параметра командной строки n, k и суммирует
;;все числа от 1 до n, у которых сумма цифр равна k.
;;Сборка: fasm 2_4.asm && ld 2_4.o -o 2_4   (или make 2_4)
;;Запуск: ./2_4 30 3   -> 66   (3 + 12 + 21 + 30)

format ELF64
public _start

section '.data' writable
    msg_usage db 'Использование: ./2_4 <n> <k>', 0xA, 0
    msg_bad   db 'Ошибка: параметры должны быть целыми неотрицательными числами', 0xA, 0
    msg_ovf   db 'Ошибка: переполнение результата', 0xA, 0

section '.bss' writable
    buffer rb 30

section '.text' executable

include 'func.asm'

_start:
    pop rcx                 ;количество параметров командной строки
    cmp rcx, 3
    jne .usage

    mov rsi, [rsp+8]        ;первый параметр - n
    call is_number
    cmp rax, 0
    je .bad
    call str_number
    mov rbx, rax            ;rbx = n

    mov rsi, [rsp+16]       ;второй параметр - k
    call is_number
    cmp rax, 0
    je .bad
    call str_number
    mov r13, rax            ;r13 = k

    xor r14, r14            ;сумма
    mov r12, 1              ;текущее число i
    .iter:
        cmp r12, rbx
        ja .print
        mov rax, r12
        call digit_sum      ;rax = сумма цифр i
        cmp rax, r13
        jne .next
        add r14, r12
        jc .overflow
        .next:
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

;The function finds the sum of digits of the number
;input rax - number
;output rax - sum of digits
digit_sum:
    push rbx
    push rcx
    push rdx
    xor rbx, rbx            ;сумма цифр
    mov rcx, 10
    .iter:
        xor rdx, rdx
        div rcx             ;rdx = последняя цифра
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
