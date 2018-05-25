%include "macros.i"
%include "f_lang.i"

global _start

section .bss
section .data

  def_str horiz, `\n-------------------\n\0`

  def_str message, `hello world\0`
  def_str message2, `Thanks for a wonderful day debness!\n\0`

  def_str about_to_foldl, `About to foldl\n\0`
  def_str end_foldl, `End Foldl\n\0`
  def_str iter_foldl, `Iteration Foldl\n\0`

  def_str null_term, `12\n\0`

  def_str progress_foldl, `About to call fold func\n\0`

  def_str null_check_fail_msg, `Null check failed\n\0`
  def_str null_check_success_msg, `Null check success\n\0`


section .text





%define result rdi
x2_plus_1:
  prologue 0

  imul result, result
  add result, 1

  mov rax, result

  epilogue 0




_start:
  prologue 64

  pprint horiz

  ; convert 1 to its char rep
  apply1 chr, 1
  push rax
  mov rdi, rsp
  mov rsi, 1
  call println

  pprint horiz

  ; Print `hello world`
  pprint message

  pprint horiz

  ; Converts all lower case to upper case (and updates all non alphabet chars with - 32
  apply2 map_bytes, sub_32, message

  mov rdi, message
  mov rsi, message_len - 1
  call println

  pprint horiz

  ; sums an array of bytes
  ; init array
  %define arr [rbp - 11]
  %define i al
  mov i, 10
  .while:
    cmp i, 1
    jl .end_while
    mov byte [rbp - 11 + rax - 1], i

    sub i, 1
    jmp .while

  .end_while:
  mov byte [rbp - 1], 0
  pprint about_to_foldl
  ; sum the bytes in arr
  mov r8, rbp
  sub r8, 11
  apply3 foldl_bytes, plus, 0, r8


  ; mov bytes onto stack
  mov byte [rbp - 10], al
  mov rdi, rbp
  sub rdi, 10
  mov rsi, 1
  call println

  pprint horiz


  ;apply1 x2_plus_1, 7
  ;push rax
  ;mov rdi, rsp
  ;mov rsi, 8
  ;call println

  mov rdi, horiz
  mov rsi, horiz_len
  call println

  jmp .exit


.exit:
  add rsp, 64
  pop rbp

  mov rax, 60
  mov rdi, 0
  syscall


.null_check_fail:
  mov rdi, null_check_fail_msg
  mov rsi, null_check_fail_msg_len
  call println
  jmp .exit

.null_check_success:
  mov rdi, null_check_success_msg
  mov rsi, null_check_success_msg_len
  call println
  jmp .exit
