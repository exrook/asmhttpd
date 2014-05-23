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
  pop edi ; save return addr
  
  pop ebx ; fd
  pop edx ; msgLength
  pop ecx ; msg
  
  mov eax,4 ; syscall 4 - write
  int 80h
  
  push edi ; restore return addr
  ret
print:
  pop edi
  push 1
  push edi
  jmp write
close:
  pop edi   ; save return addr
  pop ebx   ; fd to close
  mov eax,6 ; write syscall (6)
  int 80h   ; syscall
  push edi
  ret
shutdown:
  pop edi
  mov eax,102
  mov ebx,13
  mov ecx,esp
  int 80h
  pop eax
  pop eax
  push edi
  ret
open_socket:
  mov edx,esp ; save stack pointer
  push dword 6 ; (IPPROTO_TCP)
  push dword 1 ; (SOCK_STREAM)
  push dword 2 ; (PF_INET)
  
  mov eax,102 ; SYS_SOCKET
  mov ebx,1   ; Subcall 1, Socket
  mov ecx,esp ; Arguments are in the stack
  
  int 80h             ; call kernel
  mov [socket_fd],eax ; save file descriptor
  mov esp,edx ; restore stack pointer
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
