%include "macros.i"
%include "f_lang.i"	
%include "syscalls.i"


	
global assert
global assert_false
global assert_false_with_return_code
	
	
section .data
	def_str begin, `Begin Assert\n`
	def_str return_code_msg, `Return Code: `

section .text

;; void (int return_code, char* message) null terminated
assert_false:
	prologue 0
	mov rax, rdi
	push rsi
	sub rsp, 8
	jmp assert_failed
	


assert:
  prologue 0
  push rsi
  push rdi
  mov rdi, rdx
  mov rsi, rcx
  mov rdx, r8
  mov rcx, r9

  call [rsp]

  cmp rax, 0
  jne assert_failed

  pop rdi
  pop rsi
  epilogue 0

assert_failed:

  mov rdi, [rsp + 8]
  call strlen
	
  mov rdi, 2
  mov rsi, [rsp + 8]
  mov rdx, rax
  mov rax, 1
  syscall

  mov rdi, 1
  call sys_exit


	;;  void (int64_t return_code, char* message)
%define return_code rdi
%define message_ptr rsi
assert_false_with_return_code:
     mov r12, rdi
     mov r13, rsi

     sub rsp, 19
     mov byte [rsp + 18], 0
     mov rsi, rsp
     mov rdx, 8
     call fmt_n_bytes		; Store the hex rep of rax in rsp (19 bytes)
	
     mov rdi, return_code_msg
     mov rsi, return_code_msg_len
     call printerr		; Print the err message
	
     

     mov rdi, rsp
     mov rsi, 19
     call printerr		; print the error code

     call print_new_line
	
     mov rdi, r12
     mov rsi, r13
     call assert_false

