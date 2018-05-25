
global sys_exit
global sys_futex
global sys_open	
global sys_getdents


sys_exit:
  mov rdi, rax
  mov rax, 60
  syscall

;; int futex(int *uaddr, int futex_op, int val, ;
;;          const struct timespec *timeout, /* or: uint32_t val2 */
;;          int *uaddr2, int val3)	    ;	
sys_futex:
  mov rax, 202
  syscall
  ret


sys_open:
	mov rax, 2
	syscall
	ret
	
sys_getdents:
	mov rax, 78
	syscall
	ret
