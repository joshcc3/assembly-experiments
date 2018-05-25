%include "macros.i"
%include "f_lang.i"
%include "threads.i"
%include "syscalls.i"

global _start

section .data
def_str thread1_msg, `Hello from Thread1\n\0`

def_str thread2_msg, `Hello from Thread2\n\0`

def_str main_sleep, `Main sleep\n`

def_str main_end, `Main done\n`

section .text

thread_action_1:
  prologue 0
  pprint thread1_msg
  
  mov rax, 0
  call sys_exit  


thread_action_2:
  prologue 0
  pprint thread2_msg

  mov rax, 0
  call sys_exit

zero_param_regs:
  xor rsi, rsi
  xor rdi, rdi
  xor rdx, rdx
  xor rcx, rcx
  xor r8, r8
  xor r9, r9
  xor r10, r10
  ret

_start:
  call zero_param_regs

  mov rdi, thread_action_1
  call thread_create

  mov rdi, thread_action_2
  call thread_create

  pprint main_sleep
  mov rdi, 2
  mov rsi, 0
  call sleep
   
  pprint main_end

  mov rax, 0
  call sys_exit


; thread1.start()
; thread2.start()

; thread1.join()
; thread2.join()
