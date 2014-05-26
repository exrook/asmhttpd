section .text

%macro write_m 2+
  [section .data]
%%str: db %2
%%endstr:
  __SECT__
  push %%str
  push %%endstr-%%str
  push %1
  call write
%endmacro

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
  
  pop edx
  pop ecx
  pop ebx
  pop eax
  
  mov esp,ebp      ; restore esp
  mov ebp,[esp+4]  ; save ret addr to ebp
  add esp,20       ; clear args+ret addr+old ebp off stack 8+(4*3)
  push ebp         ; push ret addr 
  mov ebp,[esp-16] ; restore old ebp from stack
  ret              ; return

%macro close_m 1
  push %1
  call close
%endmacro

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
  add esp,12      ; clear args w/ ebp+ret addr 8+4
  push ebp        ; push ret addr
  mov ebp,[esp-8] ; restore ebp
  ret
  
%macro shutdown_m 2
  push %2
  push %1
  call shutdown
%endmacro
  
shutdown:
  push ebp    ; save ebp
  mov ebp,esp ; save esp
  
  push eax
  push ebx
  push ecx
  
  mov eax,102   ; netcall
  mov ebx,13    ; subcall 13 - shutdown
  mov ecx,ebp   ; fd and mode are on the stack
  add ecx,8     ; args are on stack 8 bytes back
  int 80h       ; syscall
  
  pop ecx
  pop ebx
  pop eax
  
  mov esp,ebp     ; restore esp
  mov ebp,[esp+4] ; save ret addr to ebp
  add esp,16      ; clear stack 8+8
  push ebp        ; restore return address
  mov ebp,[esp-8] ; restore ebp
  ret
  
%macro open_m 2+
  [section .data]
%%file: db %2
  __SECT__
  push %1
  push %%file
  call open
%endmacro
  
open:
  push ebp
  mov ebp,esp
  
  push eax
  push ebx
  push ecx
  
  mov eax,5
  mov ebx,[ebp+8]
  mov ecx,[ebp+12]
  int 80h
  
  mov [ebp+12],eax
  
  pop ecx
  pop ebx
  pop eax
  
  mov esp,ebp
  mov ebp,[esp+4]
  add esp,8+4
  push ebp
  mov ebp,[esp-8]
  ret
  
%macro sendfile_m 4
  [section .data]
%%offset: dw %3
  __SECT__
  push word %4
  push %%offset
  push %2
  push %1
  call sendfile
%endmacro
  
sendfile:
  push ebp
  mov ebp,esp
  
  push eax
  push ebx
  push ecx
  push edx
  push esi
  
  mov eax,187
  mov ebx,[ebp+8]
  mov ecx,[ebp+12]
  mov edx,[ebp+16]
  mov esi,[ebp+20]
  int 80h
  
  pop esi
  pop edx
  pop ecx
  pop ebx
  pop eax
  
  mov esp,ebp
  mov ebp,[esp+4]
  add esp,8+4*4
  push ebp
  mov ebp,[esp-8]
  ret
mmap:
  push ebp
  mov ebp,esp
  
  push eax
  push ebx
  push ecx
  push edx
  push esi
  push edi
  
  mov eax,90
  mov ebx,[ebp+8]
  mov ecx,[ebp+12]
  mov edx,[ebp+16]
  mov esi,[ebp+20]
  mov edi,[ebp+24]
  push ebp
  mov ebp,[ebp+28]
  pop ebp
  int 80h
  
  pop edi
  pop esi
  pop edx
  pop ecx
  pop ebx
  pop eax
  
  mov esp,ebp
  mov ebp,[esp+4]
  add esp,8+4*6
  push ebp
  mov ebp,[esp-8]
  ret
