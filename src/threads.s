%include "macros.i"
%include "f_lang.i"
%include "syscalls.i"
%include "assert.i"
%include "lock.i"
	
global create_stack
global sleep
global thread_create
global wait_for_completion	
	
%define max_threads 0x100
section .bss
	align 4
	futex_table resd max_threads   ; 2^16 threads ever - no garbage collection in this space yet
        latest_tid: resw 1	       ; support 2^16 tids
	tid_lock:   resq 1	       ; lock for updating the tid

section .data
	def_str futex_assertion_fail, `Futex expected value didn't match actual at update\n\0`
	def_str futex_assertion_check_fail, `Futex value was greater than 2\n\0`
	def_str waiting, `Waiting`
	align 4
	def_str done_waiting, `Done Waiting`
	def_str too_many_state_changes, `Too many state changes for a futex\n\0`
	def_str futex_err_msg, `Failed to wake threads sleeping on futex\n\0`
	def_str failed_to_unmap_at_thread_cleanup, `FAILED TO UNMAP AT THREAD CLEANUP\n\0`	
section .text

;;  word* ()
new_tid:
	prologue 0
	push r12		; Save for snapping the tid
	push r13		; Save for saving the new tid
	
	mov r12, 0
	mov r12w, [latest_tid]	; snap tid before
	mov r13, 0
	
	lea rdi, [tid_lock]	; Mutex start
	call acquire


	mov r13w, [latest_tid]
	inc r13
	mov [latest_tid], r13w	; increment and save tid
	
	
	lea rdi, [tid_lock]	; Mutex end
	call release

	cmp r12w, [latest_tid]	; Sanity check that the tid has increased
	jge .err_state
	
	mov rax, 0		; Reset because we set a word in the next line
	mov ax, r13w		; Save the new tid as the return value

	pop r13
	pop r12
	epilogue 0
	
	.err_state:
	mov rdi, -1
	mov rsi, .err_msg
	call assert_false
	def_str .err_msg, `New tid exited without having increased the tid\n\0`

	
%define STACK_SIZE 0x1000 	; 4KiB for the stack
;;; void ()
create_stack:

	;;unsigned long addr	unsigned long len	unsigned long prot	unsigned long flags	unsigned long fd	unsigned long off

	prologue 0
	mov rax, 9
	mov rdi, NULL		            ; Let the kernel choose where to put the stack
	mov rsi, STACK_SIZE
	mov rdx, PROT_WRITE | PROT_READ

	;; I don't think private adds anything to anonymous, growsdown means that the stack grows downwards (touching the 'guard page' below the current threshold
	;; creates a new mapping). The return address is also the bottom of the new stack
	mov r10, MAP_PRIVATE | MAP_ANONYMOUS | MAP_GROWSDOWN
		;; fd is unused when MAP_ANONYMOUS is set.
	mov r8, -1
	mov r9, 0
	syscall

	epilogue 0
	
;;; void(int32_t* futex, int32_t expected, int32_t final)
update_futex:
	prologue 0
	mov rax, rsi 		        ; set comparison for cmpxchg
        cmpxchg dword [rdi], edx   	; set the futex to the dest
	cmp rax, rsi			; futex value should not have changed as al == bytep[rdi]
	je .check_passed
	mov rdi, -1
	mov rsi, futex_assertion_fail
	call assert_false	; assert out over failed futex check
	.check_passed:
	epilogue 0

;;; void thread_create(void* function_pointer, . ... void*) - create a new thread from a function pointer with upto 4 arguments
;;; the 4 argument restriction is because I'm lazy - it could be 5 (save the new stack to another location)
thread_create:
  push rbp
  mov rbp, rsp	
  push r12			; Used to save the result of clone (the tid of the child/0)
  push r13			; Used to save my tid, only cleared for parent
	
  push rdi
  push rsi
  push rdx
  push rcx
  push r8

  call new_tid
  mov r13, rax			; Save my tid of the child
	
  call create_stack

  lea rsi, [rax + STACK_SIZE - 8]  ; the high address of the stack (the top of the stack)
  pop qword [rsi]			   ; Store the thread function at the top of the stack to be called on 'ret'urn
  pop qword [rsi - 8]			   ; Store the saved registers in reverse order 
  pop qword [rsi - 16]			   ; Store the saved registers in reverse order
  pop qword [rsi - 24]			   ; Store the saved registers in reverse order
  pop qword [rsi - 32]			   ; Store the saved registers in reverse order
  mov rdi, CLONE_SIGHAND | CLONE_FILES | CLONE_FS | CLONE_VM | CLONE_THREAD ; Share virtual memory for, e.g. shared objects - communication between threads.
	            			   ; CLONE_THREAD puts the child thread into the same thread group as the parent thread. The parent is the callers parent.
        ;; Signals behave a little strangely in thread groups and calls to execve are also different than when called on processes.
  lea rsi, [rsi - 32]
  mov rax, 56
  syscall
	
  cmp rax, 0

	jne .parent
  %define child_tid r13
  .child:
	
  mov dword [futex_table + child_tid*4], 0 ; reinitialize the futex table entry for this thread - we don't care about what the previous value was - although it should 0, 1, 2

  lea rdi, [futex_table + child_tid*4]
  mov rsi, 0
  mov rdx, 1
  call update_futex		; Check that the futex contains a 0 and update to 1 atomically
	
  pop rax			; pop the function pointer into rax
  call rax			 ; invoke the thread function

  lea rdi, [futex_table + child_tid*4]
  mov rsi, 1
  mov rdx, 2	; mark thread complete
  call update_futex


  lea rdi, [futex_table + child_tid*4]
  mov rsi, FUTEX_WAKE
  mov rdx, INT_MAX
  call sys_futex		; Wake all threads waiting on this thread

  cmp rax, 0
  jl .futex_wake_error		
  
  	
  lea rdi, [rsp + 0x100 - STACK_SIZE]; must be aligned on a page boundary
  mov r12, -1
  shl r12, 12			; shift left by 12 bits, (page size)
  and rdi, r12
	
  mov rsi, STACK_SIZE	
  mov rax, 11
  syscall
	
  cmp rax, 0
  jl .failed_to_unmap

;;; free mmap here
  mov rax, 60 			; exit - no stack so we can't call functions 
  mov rdi, 0
  syscall

  .parent:
  mov rax, r13			; Return the child tid here
  pop r13
  pop r12
  pop rbp
  ret
.futex_wake_error:
  mov rdi, rax
  mov rsi, futex_err_msg
  call assert_false_with_return_code
.failed_to_unmap:
  mov rdi, rax
  mov rdi, failed_to_unmap_at_thread_cleanup
  call assert_false_with_return_code	

; void (long long seconds, long long nanoseconds)
%define seconds rdi
%define nanoseconds rsi 
%define time_struct_ptr r8
sleep:
  prologue 16 

  mov rax, 35 ; syscall number for nanosleep
  lea time_struct_ptr, [rbp - 16] ; location of time struct 
  mov qword [time_struct_ptr], seconds 
  mov qword [time_struct_ptr + 8], nanoseconds

  mov rdi, time_struct_ptr
  mov rsi, NULL
  syscall
	
  epilogue 16

	

;;; Waiting on thread completion
;;; A thread goes through the state:
;;; 0 - uninitialized
;;; 1 - running/crashed without cleanup
;;; 2 - completed
%define futex_ptr r12
%define futex_val dword [r12]
%define tid r14
;;; void (tid_t thread_id)
wait_for_completion:
	push rbp
	mov rbp, rsp
	push r12	                ; preserved across fn calls
	push r13
	push r14
	mov r14, rdi
	mov r13, 0
	lea r12, [futex_table + tid*4]		; 
	.while:	
	cmp r13, 3
	jge .too_many_state_changes		; Not more than 2 state changes: 0 -> 1 -> 2

	cmp futex_val, 2	; check for completed and if so return immediately
	je .complete
	jg .error
	
	mov rdi, futex_ptr	
	mov rsi, FUTEX_WAIT
	mov rdx, 0
	mov edx, futex_val
	mov r10, NULL
	call sys_futex		; wait on the futex val (0 or 1)

	cmp rax, 0		; success
	je .complete
	
	inc r13

	cmp rax, EAGAIN		;
	je .while
	
	jne .error
	.complete:

	pop r14
	pop r13
	pop r12
	pop rbp
	ret
	
	.error:
	mov rdi, rax
	mov rsi, futex_assertion_check_fail
	call assert_false_with_return_code

	.too_many_state_changes:
	mov rdi, -1
	mov rsi, too_many_state_changes
	call assert_false
