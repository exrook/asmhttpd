section .data
  startmsg: db 'Starting asmhttpd',10
  startmsgLen: equ $-startmsg
  
  endmsg: db 'Stopped asmhttpd',10
  endmsgLen: equ $-endmsg

  response: db '<h1>Hello World!</h1>'
  responseLen: equ $-response
  
  close_conn: db 'Connection Closed',10
  close_connLen: equ $-close_conn
section .bss
  socket_fd: resw 1; socket file descriptor
  
section .text
  global _start

write:
  push ebp    ; save ebp
  mov ebp,esp ; save esp
  
  push eax ; save registers
  push ebx
  push ecx
  push edx
  
  mov ebx,[ebp+8]  ; fd
  mov edx,[ebp+12] ; msgLength
  mov ecx,[ebp+16] ; msg
  
  mov eax,4 ; syscall 4 - write
  int 80h   ; syscall
  
  push edx
  push ecx
  push ebx
  push eax
  
  mov esp,ebp      ; restore esp
  mov ebp,[esp+4]  ; save ret addr to ebp
  add esp,20       ; clear args+ret addr+old ebp off stack
  push ebp         ; push ret addr 
  mov ebp,[esp-16] ; restore old ebp from stack
  ret              ; return
print:
  pop edi
  push 1
  push edi
  jmp write
close:
  push ebp
  mov ebp,esp
  
  push eax
  push ebx
  
  mov ebx,[ebp+8] ; fd to close
  
  mov eax,6 ; close syscall (6)
  int 80h   ; syscall
  
  pop ebx
  pop eax
  
  mov esp,ebp     ; restore esp
  mov ebp,[esp+4] ; save ret addr to ebp
  add esp,12      ; clear args w/ ebp+ret addr
  push ebp        ; push ret addr
  mov ebp,[esp-8] ; restore ebp
  ret
shutdown:
  push ebp    ; save ebp
  mov ebp,esp ; save esp
  
  mov eax,102   ; netcall
  mov ebx,13    ; subcall 13 - shutdown
  add esp,8     ; args are on stack 8 bytes back
  mov ecx,esp   ; fd and mode are on the stack
  int 80h       ; syscall
  
  mov esp,ebp ; restore esp
  pop ebp     ; restore ebp
  pop eax     ; save ret address
  add esp,8   ; clear args
  push eax    ; restore ret addr
  ret
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
  
  push dword 0     ; push sockaddr onto stack in reverse order
  push word 0x6022 ; 0.0.0.0:8800
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
  mov esp,edi ; restore stack pointer
  ret
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
  
  test eax,eax ; eax will be zero in child
  jz respond
  push edi ; restore stack pointer
  ret
respond:
  pop eax
  push eax
  push 2
  push eax
  push response
  push responseLen
  push eax
  call write
  call shutdown
  call close
  push close_conn
  push close_connLen
  call print
  jmp exit
_start:
  push startmsg
  push startmsgLen
  call print
  call open_socket
  call bind
loop:
  call listen
  call accept
  jmp loop
  push endmsg
  push endmsgLen
  call print
exit:
  mov eax,1
  mov ebx,0
  int 80h
