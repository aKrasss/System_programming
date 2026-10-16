;;Раздел 2, задача 2
;;Программа принимает параметр командной строки n и вычисляет
;;1 + 11 + 111 + 1111 + ... + sum(10^k, k = 0..n),
;;т.е. сумму n+1 чисел из единиц (последнее слагаемое состоит из n+1 единиц).
;;Каждое следующее слагаемое получается из предыдущего: x = x*10 + 1.
;;Сборка: fasm 2_2.asm && ld 2_2.o -o 2_2   (или make 2_2)
;;Запуск: ./2_2 2      -> 123   (1 + 11 + 111)
;;Без переполнения 64 бит работает при n <= 19.

format ELF64
public _start

;section '.data' writable
;    msg_usage db 'Использование: ./2_2 <n>', 0xA, 0
;    msg_bad   db 'Ошибка: параметр должен быть целым неотрицательным числом', 0xA, 0
;    msg_ovf   db 'Ошибка: переполнение (n слишком большое)', 0xA, 0

section '.bss' writable
    buffer rb 30

section '.text' executable

include 'func.asm'

_start:
    ;pop rcx                 ;количество параметров командной строки
    ;cmp rcx, 2
    ;jne .usage

    mov rsi, [rsp+16] ;адрес параметра n (второй элемент на стеке)
    call is_number
    cmp rax, 0
    ;je .bad
    call str_number
    mov rbx, rax ;rbx = n

    xor r12, r12 ;k - номер слагаемого (0..n)
    xor r13, r13 ;текущее слагаемое: 1, 11, 111, ...
    xor r14, r14 ;сумма
    mov r8, 10
    .iter:
        mov rax, r13
        mul r8
        ;jc .overflow
        add rax, 1
        ;jc .overflow
        mov r13, rax
        add r14, r13
        ;jc .overflow
        cmp r12, rbx
        je .print
        inc r12
        jmp .iter

    .print:
    mov rax, r14
    mov rsi, buffer
    call number_str
    call print_str
    call new_line
    call exit

    ;.usage:
    ;    mov rsi, msg_usage
    ;    jmp .error
    ;.bad:
    ;    mov rsi, msg_bad
    ;    jmp .error
    ;.overflow:
    ;    mov rsi, msg_ovf
    ;.error:
    ;    call print_str
    ;    call exit_error

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
;exit_error:
;    mov rax, 60
;    mov rdi, 1
;    syscall
