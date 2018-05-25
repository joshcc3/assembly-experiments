%ifndef LOCKS_S
%define LOCKS_S	
		
global acquire
global release	
	
%endif
	
%include "syscalls.i"
%include "f_lang.i"
%include "macros.i"
%include "lock.i"
%include "assert.i"	
	


	

section .data
	
	def_str futex_err_msg, `Futex err: Return Code: \0`
	def_str release_on_unlocked, `Attempted to release an unlocked lock\n\0`
	def_str lock_unknown_state, `Lock holds an unknown state\n\0`
	def_str lock_locked_assert_failed, `Tried to exit acquire without actually acquiring\n\0`
section .text

;; bool (int32_t* lock_ptr)
lock_is_locked:
  prologue 0
  mov rax, 0
  cmp qword [rdi], LOCKED
  je .true
  mov rax, 1
  .true:
  epilogue 0
	
	
;; *int -> io ()
;; blocks until the lock pointed to by rdi is acquired
;; 	cas (0, u, 1)
;;      if rax = 0
;;	  locked = return
;;	if rax = 1
;;          block: futex 1, u
;;	    loop
%define dest r8
%define lock_ptr r12
%define lock_value [r12]
%define tmp_incr r13
acquire:
  prologue 0
  push r13
  push r12
  mov r13, 0
  mov lock_ptr, rdi
.while_true:
  ;; Loop invariants: lock_ptr constant
  mov rax, UNLOCKED
  mov dest, LOCKED
  inc tmp_incr
  ;; src <- dest if rax == src else rax <- src (atomically - goes through machine hardward)
  cmpxchg lock_value, dest
  cmp rax, UNLOCKED	;
  je .locked 			; Locking was successful - lock_ptr = 0 at cas
  cmp rax, LOCKED		; Locking failed - flag was locked
  je .blocked			; rax set to strange value
  jmp .err_state
	
.blocked:
  cmp tmp_incr, 0x1000	 	; Way too many retries (2^12)
  jge .too_many_retries

  mov rdi, lock_ptr
  mov rsi, FUTEX_WAIT
  mov rdx, LOCKED
  mov r10, NULL
  call sys_futex		; Block on locked state of the futex
  cmp rax, 0
  je .while_true		; was woken up by a lock release
  cmp rax, EAGAIN		; Possibly unlocked before we could sleep
  jne .futex_error		
  jmp .while_true		; attempt to obtain the lock again


  .too_many_retries:
  mov rdi, -1
  mov rsi, .too_many_retries_msg
  call assert_false
  .too_many_retries_msg: db `Too many retries to obtain lock\n\0`

  .futex_error:
  mov rdi, rax
  mov rsi, futex_err_msg
  call assert_false_with_return_code
  
  .return_code: db 6		; 6 bytes including the newline and null
	
.err_state:
	  mov rdi, -1
	  mov rsi, lock_unknown_state
	  call assert_false
	

.locked:
  ;; Only 1 process should ever be here
  mov rdi, lock_is_locked
  mov rsi, lock_locked_assert_failed
  mov rdx, lock_ptr
  call assert
  pop r12
  pop r13	
  mov rax, 0
  epilogue 0



;; void release(int32_t* lock)
%define dest r8
%define lock_ptr r12
%define lock_value [r12]	
release:	
  prologue 0
  push r12
  mov lock_ptr, rdi
  ;; Might want to enforce that only the thread that owns the lock can retrieve
  ;;   release:
  ;; 	cmpxchg 1, u, 0
  ;; 	rax = 1
  ;; 	  futex, 1
  ;; 	rax = 0
  ;;           syserr
  ;;           exit
  mov rax, LOCKED
  mov dest, UNLOCKED
  cmpxchg lock_value, dest	; if lock_value is 1 then set to 0
  
  cmp rax, LOCKED		; If locked at the time of cmpxchg, rax is unmodified
  je .released
  
  cmp rax, UNLOCKED	; rax is set to unlocked at cmpxchg
  je .release_on_unlocked
  
  jmp .bad_lock_state
  
  
  .release_on_unlocked:
    mov rdi, -1
    mov rsi, release_on_unlocked
    call assert_false 	; Program crashes with message
  
  .bad_lock_state:
    mov rdi, -1
    mov rsi, lock_unknown_state
    call assert_false
  
  .released:
    mov rdi, lock_ptr
    mov rsi, FUTEX_WAKE
    call sys_futex
    pop r12
    epilogue 0
	


;;; TODO: implement a method to wait on for arbitrary signals/not just specific threads
