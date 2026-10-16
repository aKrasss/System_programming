;;Раздел 3, задача 1
;;Программа принимает два параметра командной строки: имя каталога и число n.
;;Программа заходит в данный каталог и создаёт n файлов со случайными названиями.
;;Случайные буквы берутся из устройства /dev/urandom.
;;Сборка: fasm 3_1.asm && ld 3_1.o -o 3_1   (или make 3_1)
;;Запуск: ./3_1 testdir 5

format ELF64
public _start

section '.data' writable
    urandom   db '/dev/urandom', 0
    msg_usage db 'Использование: ./3_1 <каталог> <n>', 0xA, 0
    msg_bad   db 'Ошибка: n должно быть целым неотрицательным числом', 0xA, 0
    msg_dir   db 'Ошибка: не удалось перейти в каталог', 0xA, 0
    msg_file  db 'Ошибка: не удалось создать файл', 0xA, 0
    msg_made  db 'Создан файл: ', 0

section '.bss' writable
    number rq 1             ;случайное число
    name   rb 9             ;случайное имя файла (8 букв + 0)

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
    mov r12, rax            ;r12 = сколько файлов осталось создать

    mov rax, 80             ;chdir - заходим в каталог
    mov rdi, [rsp+8]
    syscall
    cmp rax, 0
    jl .no_dir

    .create:
        cmp r12, 0
        je .done
        call gen_name       ;name = случайное имя
        mov rax, 2          ;open
        mov rdi, name
        mov rsi, 193        ;O_WRONLY|O_CREAT|O_EXCL = 1 + 64 + 128
        mov rdx, 644o       ;права rw-r--r--
        syscall
        cmp rax, -17        ;EEXIST - файл с таким именем уже есть, берём другое имя
        je .create
        cmp rax, 0
        jl .no_file
        mov rdi, rax        ;close
        mov rax, 3
        syscall
        mov rsi, msg_made
        call print_str
        mov rsi, name
        call print_str
        call new_line
        dec r12
        jmp .create

    .done:
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
    .no_file:
        mov rsi, msg_file
    .error:
        call print_str
        call exit_error

;The function makes a random name of 8 latin letters
;output - the name in memory "name"
gen_name:
    push rax
    push rbx
    push rcx
    push rdx
    xor rbx, rbx
    .iter:
        call random
        xor rdx, rdx
        mov rcx, 26
        div rcx             ;rdx = случайное число 0..25
        add dl, 'a'
        mov [name+rbx], dl
        inc rbx
        cmp rbx, 8
        jne .iter
    mov byte [name+8], 0
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

;The function gets a random number from the device /dev/urandom (лекция 6)
;output rax - random 64-bit number
random:
    push rcx
    push rdx
    push rdi
    push rsi
    push r8
    push r11
    mov rax, 2              ;открываем /dev/urandom на чтение
    mov rdi, urandom
    mov rsi, 0
    syscall
    mov r8, rax
    mov rax, 0              ;читаем 8 случайных байт
    mov rdi, r8
    mov rsi, number
    mov rdx, 8
    syscall
    mov rax, 3              ;закрываем устройство
    mov rdi, r8
    syscall
    mov rax, [number]
    pop r11
    pop r8
    pop rsi
    pop rdi
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
