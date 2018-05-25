%include "lock.i"
%include "imports.i"

	
global malloc
global init_heap

section .bss
heap_ptr resq 1
heap_lock resq 1




section .text



%define HEAP_SIZE 0x10000000 	; 256MiB worth of heap space
init_heap:
	prologue 0
	
	mov rax, 9
	mov rdi, NULL		            ; Let the kernel choose where to put the stack
	mov rsi, HEAP_SIZE
	mov rdx, PROT_WRITE | PROT_READ

	;; I don't think private adds anything to anonymous, growsdown means that the stack grows downwards (touching the 'guard page' below the current threshold
	;; creates a new mapping). The return address is also the bottom of the new stack
	mov r10, MAP_PRIVATE | MAP_ANONYMOUS
		;; fd is unused when MAP_ANONYMOUS is set.
	mov r8, -1
	mov r9, 0
	syscall

	mov [heap_ptr], rax

	epilogue 0

malloc:
	prologue 0
	push r14
	push r13

	mov r13, rdi
	
	
	mov rdi, heap_lock	; could use the cmpxchg straight on the heap_ptr instead of going through a lock
	call acquire
	mov r14, [heap_ptr]	; save space and read the ptr into r14
	add [heap_ptr], r13	
	mov rdi, heap_lock
	call release
	
	mov rax, r14

	pop r13
	pop r14
	epilogue 0
	
