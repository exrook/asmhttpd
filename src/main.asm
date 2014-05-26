%include "lib.asm"

section .data
  endmsg: db 'Stopped asmhttpd',10
  endmsgLen: equ $-endmsg

  close_conn: db 'Connection Closed',10
  close_connLen: equ $-close_conn
section .bss
  socket_fd: resw 1; socket file descriptor
  index:     resw 1; index.html fd
  
section .text
  global _start

open_socket:
  push ebp    ; save ebp
  mov ebp,esp ; save stack pointer
  
  push dword 6 ; (IPPROTO_TCP)
  push dword 1 ; (SOCK_STREAM)
  push dword 2 ; (PF_INET)
  
  mov eax,102 ; SYS_SOCKET
  mov ebx,1   ; Subcall 1, Socket
  mov ecx,esp ; Arguments are in the stack
  
  int 80h             ; call kernel
  mov [socket_fd],eax ; save file descriptor
  
  mov esp,ebp ; restore stack pointer
  pop ebp     ; restore ebp
  ret
bind:
  mov edi,esp ; save stack pointer
  
  push dword 0     ; push sockaddr onto stack in reverse order,0.0.0.0
  push word 0x901F ; 8080
  push word 2      ; AF_INET
  
  mov ecx,esp ; set ecx to the address of sockaddr
  
  push byte 16          ; length of sockaddr
  push ecx              ; pointer to sockaddr
  mov ecx,[socket_fd]
  push ecx ; socket's file descriptor
  
  mov eax,102 ; socketcall syscall
  mov ebx,2   ; bind subcall
  mov ecx,esp ; bind arguments are on the stack
  int 80h     ; syscall
  cmp eax,0
  jl bind_error
  mov esp,edi ; restore stack pointer
  ret
bind_error:
  write_m 1,"Error binding to :8080",10
  jmp exit
listen:
  mov edi,esp ; save stack pointer
  
  push byte 1         ; max backlog
  mov ecx,[socket_fd] ; get socket_fd
  push ecx            ; push socket_fd
  
  mov eax,102 ; socketcall
  mov ebx,4   ; listen subcall
  mov ecx,esp ; args are on stack
  int 80h
  
  mov esp,edi ; restore stack pointer
  ret
accept:
  pop edi ; save stack pointer
  
  push 0              ; push args for accept to stack
  push 0              ; we don't care about the client address, so pass null
  mov ecx,[socket_fd] ; get socket_fd
  push ecx            ; push socket_fd
  
  mov eax,102 ; socketcall
  mov ebx,5   ; accept
  mov ecx,esp ; args on stack
  int 80h     ; syscall
  
  push eax  ; save return value
  mov eax,2 ; fork process call (2)
  int 80h   ; syscall
  
  mov ecx,[index]
  test eax,eax ; eax will be zero in child
  jz respond
  push edi ; restore stack pointer
  ret
respond:
  pop eax
  write_m eax,"<h1>Hello World!</h1>"
  push 0
  mov ebx,esp
  push 162
  push ebx
  push esi
  push eax
  call sendfile
  shutdown_m eax,2
  close_m eax
  write_m 1,"Closed Connection",10
  jmp exit
_start:
  write_m 1,"Starting ASM-HTTPD",10
  open_m 0,"index.html",0
  pop esi
  mov [index],esi
  call open_socket
  call bind
loop:
  call listen
  call accept
  jmp loop
  write_m 1,"Stopping ASM-HTTPD",10
exit:
  mov eax,1
  mov ebx,0
  int 80h
