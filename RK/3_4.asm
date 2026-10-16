;;Раздел 3, задача 4
;;Программа принимает имя каталога, выбирает два случайных файла
;;и меняет их содержимое местами (без переименования). Файлы - до 1 Мб.
;;Запуск: ./3_4 testdir

format ELF64
public _start

section '.data' writable
    urandom db '/dev/urandom', 0
    dot     db '.', 0
    arrow   db ' <-> ', 0

section '.bss' writable
    rnd    rq 2             ;два случайных числа
    names  rq 3000          ;адреса имён файлов
    dirbuf rb 65536         ;записи каталога (getdents)
    buf_a  rb 1048576       ;содержимое первого файла
    buf_b  rb 1048576       ;содержимое второго файла

section '.text' executable

include 'func.asm'

_start:
    pop rcx
    cmp rcx, 2
    jne .exit
    mov rax, 80 ;chdir - заходим в каталог
    mov rdi, [rsp+8]
    syscall
    cmp rax, 0
    jl .exit

    mov rax, 2 ; открываем
    mov rdi, dot
    mov rsi, 65536
    syscall
    cmp rax, 0
    jl .exit
    mov rdi, rax
    mov rax, 78 ;getdents - читаем содержимое
    mov rsi, dirbuf
    mov rdx, 65536
    syscall
    mov r10, rax ;сколько байт записей прочитано

    xor rbx, rbx ;количество файлов
    xor rdx, rdx ;позиция в буфере
    .entry:
        cmp rdx, r10
        jge .choose
        movzx r9, word [dirbuf+rdx+16]   ;d_reclen - размер записи
        cmp byte [dirbuf+rdx+r9-1], 8    ;d_type = 8 - обычный файл
        jne .next
        lea rax, [dirbuf+rdx+18]         ;d_name - имя файла
        mov [names+rbx*8], rax
        inc rbx
        .next:
        add rdx, r9
        jmp .entry

    .choose:
    cmp rbx, 2
    jl .exit
    mov rax, 2              ;два случайных числа из /dev/urandom
    mov rdi, urandom
    mov rsi, 0
    syscall
    mov rdi, rax
    mov rax, 0
    mov rsi, rnd
    mov rdx, 16
    syscall

    mov rax, [rnd]          ;i = rnd1 % n
    xor rdx, rdx
    div rbx
    mov r8, rdx
    mov r12, [names+rdx*8]  ;r12 = первый файл
    dec rbx
    mov rax, [rnd+8]        ;j = rnd2 % (n-1), номер i пропускаем
    xor rdx, rdx
    div rbx
    cmp rdx, r8
    jb .j_ok
    inc rdx
    .j_ok:
    mov r13, [names+rdx*8]  ;r13 = второй файл

    ;;читаем оба файла в память
    mov rdi, r12
    mov rsi, buf_a
    call read_file
    cmp rax, 0
    jl .exit
    mov r14, rax            ;длина первого файла
    mov rdi, r13
    mov rsi, buf_b
    call read_file
    cmp rax, 0
    jl .exit
    mov r15, rax            ;длина второго файла

    ;;перезаписываем файлы чужим содержимым
    mov rdi, r12
    mov rsi, buf_b
    mov rdx, r15
    call write_file
    mov rdi, r13
    mov rsi, buf_a
    mov rdx, r14
    call write_file

    mov rsi, r12            ;печатаем "файл1 <-> файл2"
    call print_str
    mov rsi, arrow
    call print_str
    mov rsi, r13
    call print_str
    call new_line
.exit:
    call exit

;The function reads the file into the buffer
;input rdi - name of the file, rsi - buffer
;output rax - length of the file (<0 - error)
read_file:
    push rsi
    mov rax, 2              ;open(имя, O_RDONLY)
    mov rsi, 0
    syscall
    pop rsi
    mov rdi, rax
    mov rax, 0              ;read
    mov rdx, 1048576
    syscall
    push rax
    mov rax, 3              ;close
    syscall
    pop rax
    ret

;The function rewrites the file with data from the buffer
;input rdi - name of the file, rsi - buffer, rdx - length
write_file:
    push rsi
    push rdx
    mov rax, 2              ;open(имя, O_WRONLY|O_CREAT|O_TRUNC) - старое содержимое стирается
    mov rsi, 577
    mov rdx, 644o
    syscall
    mov rdi, rax
    pop rdx
    pop rsi
    mov rax, 1              ;write
    syscall
    mov rax, 3              ;close
    syscall
    ret