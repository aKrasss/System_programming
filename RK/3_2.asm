;;Раздел 3, задача 2
;;Программа принимает два параметра командной строки: имя каталога name и число n.
;;Программа заходит в каталог name, создаёт в нём новый каталог name,
;;далее заходит в каталог ./name/name и создаёт там новый каталог name, делая так n раз.
;;Сборка: fasm 3_2.asm && ld 3_2.o -o 3_2   (или make 3_2)
;;Запуск: ./3_2 abc 3   ->  abc/abc/abc/abc

format ELF64
public _start

section '.data' writable
    msg_usage db 'Использование: ./3_2 <каталог name> <n>', 0xA, 0
    msg_bad   db 'Ошибка: n должно быть целым неотрицательным числом', 0xA, 0
    msg_dir   db 'Ошибка: не удалось перейти в каталог', 0xA, 0
    msg_mkdir db 'Ошибка: не удалось создать каталог', 0xA, 0
    msg_done  db 'Готово, создано вложенных каталогов: ', 0

section '.bss' writable
    buffer rb 30

section '.text' executable

include 'func.asm'

_start:
    pop rcx                 ;количество параметров командной строки
    cmp rcx, 3
    jne .usage

    mov rsi, [rsp+16]       ;второй параметр - n
    call is_number
    cmp rax, 0
    je .bad
    call str_number
    mov r12, rax            ;r12 = n
    mov r13, [rsp+8]        ;r13 = адрес имени каталога name

    mov rax, 80             ;chdir(name) - заходим в исходный каталог
    mov rdi, r13
    syscall
    cmp rax, 0
    jl .no_dir

    xor rbx, rbx            ;счётчик созданных каталогов
    .iter:
        cmp rbx, r12
        je .done
        mov rax, 83         ;mkdir(name, 0777)
        mov rdi, r13
        mov rsi, 777o
        syscall
        cmp rax, -17        ;EEXIST - каталог уже есть, просто заходим в него
        je .enter
        cmp rax, 0
        jl .no_mkdir
        .enter:
        mov rax, 80         ;chdir(name) - заходим в созданный каталог
        mov rdi, r13
        syscall
        cmp rax, 0
        jl .no_dir
        inc rbx
        jmp .iter

    .done:
    mov rsi, msg_done
    call print_str
    mov rax, r12
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
    .no_dir:
        mov rsi, msg_dir
        jmp .error
    .no_mkdir:
        mov rsi, msg_mkdir
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
