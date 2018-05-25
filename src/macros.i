%ifndef MACROS_I
%define MACROS_I

%macro prologue 1
  push rbp
  mov rbp, rsp
  sub rsp, %1
%endmacro

%macro epilogue 1
  add rsp, %1
  pop rbp
  ret
%endmacro

%macro def_str 2
  %1: db %2
  %1_end:
  %define %1_len %1_end - %1
%endmacro

%macro pprint 1
  mov rdi, %1
  mov rsi, %1_len
  call println
%endmacro


; clobbers rdi
%macro apply1 2
  mov rdi, %2
  call %1
%endmacro

; clobbers rdi, rsi
%macro apply2 3
  mov rdi, %2
  mov rsi, %3
  call %1
%endmacro

; clobbers rdi, rsi
%macro apply3 4
  mov rdi, %2
  mov rsi, %3
  mov rdx, %4
  call %1
%endmacro

%define NULL 0

%macro curriedArg 2
    mov [rdi + %1*8], rsi
    mov rax, %2
    ret
%endmacro


%macro init_base 2
%define %1 %2
push %1
mov %1, rdi
%endmacro

%define INT_MAX 0x7ffffff

%endif
