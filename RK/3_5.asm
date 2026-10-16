;;Раздел 3, задача 5
;;Программа принимает параметр командной строки - имя каталога.
;;Программа выбирает несколько (от 1 до всех) случайных файлов в каталоге
;;и меняет их права доступа на случайные (системный вызов chmod).
;;Сборка: fasm 3_5.asm && ld 3_5.o -o 3_5   (или make 3_5)
;;Запуск: ./3_5 testdir

format ELF64
public _start

len = 65536                 ;размер буфера для записей каталога
max_files = 4096            ;максимальное количество обрабатываемых файлов

section '.data' writable
    urandom   db '/dev/urandom', 0
    dot       db '.', 0
    colon     db ': ', 0
    rwx       db 'rwxrwxrwx'
    mode_str  db '--------- (000)', 0
    msg_usage db 'Использование: ./3_5 <каталог>', 0xA, 0
    msg_dir   db 'Ошибка: не удалось перейти в каталог', 0xA, 0
    msg_read  db 'Ошибка: не удалось прочитать каталог', 0xA, 0
    msg_empty db 'В каталоге нет файлов', 0xA, 0
    msg_fail  db 'Не удалось изменить права: ', 0

section '.bss' writable
    number rq 1             ;случайное число
    names  rq max_files     ;адреса имён файлов
    dirbuf rb len           ;записи каталога (getdents)

section '.text' executable

include 'func.asm'

_start:
    pop rcx                 ;количество параметров командной строки
    cmp rcx, 2
    jne .usage

    mov rax, 80             ;chdir - заходим в каталог
    mov rdi, [rsp+8]
    syscall
    cmp rax, 0
    jl .no_dir

    call read_dir           ;rax = количество файлов
    cmp rax, 0
    jl .no_read
    je .empty
    mov r15, rax            ;r15 = количество файлов

    call random             ;сколько файлов изменить: 1 + random % count
    xor rdx, rdx
    div r15
    lea r12, [rdx+1]

    xor rbx, rbx            ;i - номер очередного выбранного файла
    .iter:
        cmp rbx, r12
        je .done
        call pick_file      ;rax = имя случайного ещё не выбранного файла
        mov r13, rax
        call random         ;случайные права: 9 младших бит (от 000 до 777 в восьмеричной записи)
        and rax, 777o
        mov r14, rax
        mov rax, 90         ;chmod(имя, права)
        mov rdi, r13
        mov rsi, r14
        syscall
        cmp rax, 0
        jl .fail
        mov rsi, r13        ;печатаем "имя: rwxr-x--- (750)"
        call print_str
        mov rsi, colon
        call print_str
        mov rax, r14
        call print_mode
        jmp .next
        .fail:
        mov rsi, msg_fail
        call print_str
        mov rsi, r13
        call print_str
        call new_line
        .next:
        inc rbx
        jmp .iter

    .done:
    call exit

    .empty:
        mov rsi, msg_empty
        call print_str
        call exit
    .usage:
        mov rsi, msg_usage
        jmp .error
    .no_dir:
        mov rsi, msg_dir
        jmp .error
    .no_read:
        mov rsi, msg_read
    .error:
        call print_str
        call exit_error

;The function prints access rights as "rwxr-x--- (750)"
;input rax - access rights (9 low bits)
print_mode:
    push rbx
    push rcx
    push rdx
    xor rcx, rcx            ;номер символа строки rwxrwxrwx
    mov rbx, 100000000b     ;маска старшего бита прав (r владельца)
    .bit:
        mov dl, '-'
        test rax, rbx
        jz .set
        mov dl, [rwx+rcx]   ;бит установлен - ставим r, w или x
        .set:
        mov [mode_str+rcx], dl
        shr rbx, 1
        inc rcx
        cmp rcx, 9
        jne .bit
    mov rdx, rax            ;восьмеричная запись: три цифры по 3 бита
    shr rdx, 6
    add dl, '0'
    mov [mode_str+11], dl
    mov rdx, rax
    shr rdx, 3
    and rdx, 7
    add dl, '0'
    mov [mode_str+12], dl
    mov rdx, rax
    and rdx, 7
    add dl, '0'
    mov [mode_str+13], dl
    mov rsi, mode_str
    call print_str
    call new_line
    pop rdx
    pop rcx
    pop rbx
    ret

;The function reads the current directory with getdents (лекция 6)
;and saves addresses of names of regular files into the array "names"
;output rax - count of files (-1 - error)
read_dir:
    push rbx
    push rdx
    push r8
    push r9
    push r10
    mov rax, 2              ;открываем текущий каталог "."
    mov rdi, dot
    mov rsi, 65536          ;O_DIRECTORY
    syscall
    cmp rax, 0
    jl .error
    mov r8, rax             ;файловый дескриптор каталога
    xor r10, r10            ;сколько байт записей прочитано
    .read:
        mov rax, 78         ;getdents
        mov rdi, r8
        lea rsi, [dirbuf+r10]
        mov rdx, len
        sub rdx, r10        ;свободное место в буфере
        syscall
        cmp rax, 0
        jle .close          ;0 - каталог прочитан полностью
        add r10, rax
        jmp .read
    .close:
    mov rax, 3
    mov rdi, r8
    syscall

    xor rbx, rbx            ;количество найденных файлов
    xor rdx, rdx            ;текущая позиция в буфере
    .entry:
        cmp rdx, r10
        jge .finish
        movzx r9, word [dirbuf+rdx+16]  ;d_reclen - размер записи
        mov al, byte [dirbuf+rdx+r9-1]  ;d_type - тип файла (последний байт записи)
        cmp al, 8                       ;8 - обычный файл
        jne .next
        cmp rbx, max_files
        jge .next
        lea rax, [dirbuf+rdx+18]        ;d_name - имя файла
        mov [names+rbx*8], rax
        inc rbx
        .next:
        add rdx, r9
        jmp .entry
    .finish:
    mov rax, rbx
    jmp .ret
    .error:
    mov rax, -1
    .ret:
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rbx
    ret

;The function moves a random file from names[i..count-1] to the position i
;input rbx - i, r15 - count of files
;output rax - address of name of the chosen file
pick_file:
    push rcx
    push rdx
    call random             ;j = i + random % (count - i)
    mov rcx, r15
    sub rcx, rbx
    xor rdx, rdx
    div rcx
    add rdx, rbx
    mov rax, [names+rbx*8]  ;меняем местами names[i] и names[j]
    mov rcx, [names+rdx*8]
    mov [names+rbx*8], rcx
    mov [names+rdx*8], rax
    mov rax, rcx
    pop rdx
    pop rcx
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

;Function exit with error code 1
exit_error:
    mov rax, 60
    mov rdi, 1
    syscall
