;;Раздел 2, задача 5
;;Программа принимает параметр командной строки n и вычисляет
;;sum(k * first_digit(k), k = 1..n),
;;где first_digit(k) - первая значащая цифра числа k.
;;Сборка: fasm 2_5.asm && ld 2_5.o -o 2_5   (или make 2_5)
;;Запуск: ./2_5 12     -> 318  (1*1 + 2*2 + ... + 9*9 + 10*1 + 11*1 + 12*1)

format ELF64
public _start

section '.data' writable
    msg_usage db 'Использование: ./2_5 <n>', 0xA, 0
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
        call first_digit    ;rax = первая цифра k
        mul r12             ;rax = k * first_digit(k)
        jc .overflow
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

;The function finds the first significant digit of the number
;input rax - number
;output rax - first digit
first_digit:
    push rcx
    push rdx
    mov rcx, 10
    .iter:
        cmp rax, 10
        jb .finish
        xor rdx, rdx
        div rcx             ;отбрасываем последнюю цифру
        jmp .iter
    .finish:
    pop rdx
    pop rcx
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
