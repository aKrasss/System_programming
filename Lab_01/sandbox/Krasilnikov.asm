format ELF
public _start

msg db "Krasilnikov", 0xA, "Arseny", 0xA, "Alekseevich", 0xA, 0
msg_len = $ - msg - 1

_start:

mov eax, 4
mov ebx, 1
mov ecx, msg
mov edx, msg_len
int 0x80

mov eax, 1
mov ebx, 0
int 0x80
