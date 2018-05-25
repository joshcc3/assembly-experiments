%include "syscalls.i"	
%include "f_lang.i"
%include "threads.i"	
%include "macros.i"
%include "assert.i"
%include "lock.i"
	
global _start
	
section .data
	def_str val_rax, `Value of rax:\n`
	def_str val_src, `Value of src:\n`		
	def_str val_dest, `Value of dest:\n`
	def_str newline, `\n`
	def_str t2_dead, `T2: is now dead\n`	
	def_str about_to_futex_wait, `Thread1: About_to_futex_wait\n`
	def_str t1_waiting_completion, `T1: Waiting completion\n\0`
	def_str main_thread_exit, `Main: Thread exit\n`
	def_str waking_futex, `Main: Waking futex\n`
	def_str main_thread_sleeping, `Main: Thread sleeping\n`
	def_str main_thread_waiting, `Main: Thread waiting\n`	
	def_str thread_acquiring_lock, `Thread1: Acquiring lock\n\0`
	def_str thread_acquired_lock, `Thread1: Acquired lock\n\0`
	def_str thread_releasing_lock, `Thread1: Releasing lock\n\0`
	def_str thread_released_lock, `Thread1: Released lock\n\0`
	def_str thread_exit, `Thread1: Exiting lock\n\0`
	def_str thread_acquire_lock, `Thread1: Acquiring lock\n\0`	
	def_str main_acquired_lock, `Main1: Acquired lock\n\0`
	def_str main_releasing_lock, `Main1: Releasing lock\n\0`
	def_str main_released_lock, `Main1: Released lock\n\0`
	def_str main_acquire_lock, `Main1: Acquiring lock\n\0`
	def_str thread_sleeping, `Thread: Sleeping\n\0`
section .text
	
	%define src r12
	%define dest r13
test_cmp_exchg:	

	mov src, 69
	mov dest, 72
	mov rax, 69
	cmpxchg src, dest
	push rax

	pprint val_rax
	pprint newline
	
	mov rax, 1
	mov rsi, rsp
	mov rdx, 1
	syscall
	pprint newline
	
	pprint val_src
	push src
	mov rax, 1
	mov rdi, 1
	mov rsi, rsp
	mov rdx, 1
	syscall
	pprint newline
	
	pprint val_dest
	push dest
	
	mov rax, 1
	mov rdi, 1
	mov rsi, rsp
	mov rdx, 1
	syscall
	pprint newline

	mov rdi, 0
	call sys_exit


thread_fn:
	pprint about_to_futex_wait
        mov rdi, [rsp]
        mov rsi, FUTEX_WAIT
        mov rdx, 1
        mov r10, NULL
        xor r8, r8
        xor r9, r9
	call sys_futex

        mov rdi, 0
	call sys_exit


fail_assert:
	mov rax, 1
	ret

test_assert:
	mov rdi, fail_assert
	mov rsi, .fail_message
	call assert
.fail_message db `Assert failure\n\0`
	
test_futex:
	push 1
	
	mov rdi, thread_fn
	mov rsi, rsp
	call thread_create

	pprint main_thread_sleeping
	mov rdi, 2
	mov rsi, 0
	call sleep

	pprint waking_futex

	mov rdi, rsp
	mov rsi, 1
	call sys_futex

	mov rdi, 1
	mov rsi, 0
	call sleep
	
	pprint main_thread_exit

	mov rdi, 0
	call sys_exit

;; 	void ()
sleepy_thread:
	pprint thread_sleeping
	mov rdi, 5
	mov rsi, 0
	call sleep
	pprint thread_exit

	mov rdi, 0
	call sys_exit
	
	
test_sleepy_tread:
	mov rdi, sleepy_thread
	call thread_create

	pprint main_thread_exit
	
	mov rdi, 0
	call sys_exit

	;; void thread_acquires_lock(int32_t* lock)
%define lock [rsp + 8]	
thread_acquires_lock:
	pprint thread_acquiring_lock
	
	mov rdi, lock
	call acquire
	
	pprint thread_acquired_lock

	mov rdi, 5
	mov rsi, 500000000
	call sleep
	pprint thread_releasing_lock

	mov rdi, lock
        call release

	pprint thread_released_lock

	pprint thread_exit

	ret


test_hex_printing:	
	mov rdi, 0xff
	call to_hex

	;; test print err of different sizes of formatted ints
	sub rsp, 19
	mov qword [rsp], 0
	mov qword [rsp - 8], 0
	mov word [rsp - 16], 0
	mov byte [rsp - 18], 0
	
	mov rdi, 0xffffaacc7fff11aa
	mov rsi, rsp
	mov rdx, 8
	call fmt_n_bytes
	
	mov rdi, rsp
	mov rsi, 16
	call println

	push 10
	mov rdi, rsp
	mov rsi, 1
	call println

	mov rdi, 0
	call sys_exit

def_str something, `Something\n`
_etst:

	%define location rdi
	%define size rsi
	%define prot rdx
	%define flags r10
	%define fd r8
	%define offset r9
	
	sub rsp, 8
	mov qword [rsp], 0
	
	mov rax, 0
	mov rdi, 0
	mov rsi, rsp
	mov rdx, 8
	syscall
	

	mov rdi, rsp
	mov rsi, 8
	call println
	
	mov rax, 9
	mov location, NULL
	mov size, 0x1000
	mov prot, PROT_READ | PROT_WRITE
	mov flags, MAP_ANONYMOUS | MAP_SHARED
	mov fd, -1
	mov offset, 0
	syscall
	mov r8, rax

	sub rsp, 8
	mov qword [rsp], 0
	
	mov rax, 0
	mov rdi, 0
	mov rsi, rsp
	mov rdx, 8
	syscall

	mov dword [r8], 0x41424344

	mov rdi, r8
	mov rsi, 4
	call println
	
	mov rax, 0
	mov rdi, 0
	mov rsi, rsp
	mov rdx, 8
	syscall
	mov dword [r8+4], 0x41424344
	
	mov rdi, 0
	call sys_exit


%define filename `./\0`
_start:
	



;;  tid <- spawn1(l)
;;  tid2 <- spwan2(l, tid)
;;  wait(tid)
;;  wait(tid2)
;;
;;  spawn1
;;	tid <- spawnc1(l)
;;	tid2 <- spawnc2(l, tid)
;;	exits
;;
;;	spawnc1
;;	   acquire l
;;	   release l
;;	   acquire l
;;	   release l
;;	   done
;;	spawnc2
;;	   acquire l
;;	   release l
;;	   wait tid
;;  spawn2
;;	acquire l
;;	release l
;;	wait tid
	def_str waiting_on_t1, `Main: Wating on t1\n`
	def_str waiting_on_t2, `Main: Wating on t2\n`
	def_str spawning_t1, `Main: Spawning t1\n`
	def_str spawning_t2, `Main: Spawning t2\n`
	def_str exiting, `Main: Exiting\n`

	def_str spawning_c1, `T1: Spawning c1\n`
	def_str spawning_c2, `T1: Spawning c2\n`
	def_str quiting, `T1: Quitting\n`
	def_str acquire_l1, `TC1: Acquire l1\n`
	def_str acquire_l2, `TC1: Acquire l2\n`
	def_str release_l1, `TC1: Release l1\n`
	def_str release_l2, `TC1: Release l2\n`
	def_str quitting, `TC1: Quitting\n`
	
	def_str c2_dead, `C2: Dead\n`
	def_str c2_start, `C2: Start\n`	
	
	def_str acquiring_lock, `T2: Acquiring lock\n`
	def_str acquired_lock, `T2: Acquired lock\n`	
	def_str releasing_lock, `T2: Releasing lock\n`

_test_thread_hierarchy:
	%define tid [rsp + 8]
	%define tid2 [rsp + 16]
	%define lock [rsp]
	pprint spawning_t1
	sub rsp, 24
	mov rdi, .spawn1 
	lea rsi, lock
	mov qword lock, 0
	call thread_create
	mov tid, rax

	pprint spawning_t2	
	mov rdi, .spawn2
	lea rsi, lock
	mov rdx, tid
	call thread_create
	mov tid2, rax
	
	
	mov rdi, 10
	mov rsi, 0
	call sleep

	pprint waiting_on_t1
	mov rdi, tid
	call wait_for_completion

	mov rdi, 20
	mov rsi, 0
	call sleep

	pprint waiting_on_t2
	mov rdi, tid2
	call wait_for_completion


	pprint exiting
	mov rdi, 0
	call sys_exit


	
%define lock [rsp + 16]

.spawn1:
	prologue 0
	pprint spawning_c1
	mov rdi, .spawnc1
	mov rsi, lock
	call thread_create
	mov r12, rax
	
	mov rdi, 5
	mov rsi, 3
	call sleep
	
	pprint spawning_c2
	mov rdi, .spawnc2
	mov rsi, lock
	mov rdx, r12
	call thread_create
	mov r12, rax

	mov rdi, 10
	mov rsi, 0
	call sleep
	
	
	pprint t1_waiting_completion
	mov rdi, r12
	call wait_for_completion

 	pprint quiting

	epilogue 0
	

	
%define lock [rsp + 16]
.spawnc1:
	prologue 0

	pprint acquire_l1
	mov rdi, lock
	call acquire
	
	mov rdi, 10
	mov rsi, 0
	call sleep

	pprint release_l1
	mov rdi, lock
	call release
	
	mov rdi, 2
	mov rsi, 0
	call sleep

	pprint acquire_l2
	mov rdi, lock
	call acquire
	
	mov rdi, 3
	mov rsi, 0
	call sleep

	pprint release_l2
	mov rdi, lock
	call release

	mov rdi, 1
	mov rsi, 0
	call sleep

	pprint quitting
	
	epilogue 0

%define lock [rsp + 16]
%define tid [rsp + 24]	
.spawnc2:
	prologue 0

	pprint c2_start
	mov rdi, lock
	call acquire
	
	mov rdi, 8
	mov rsi, 0
	call sleep

	mov rdi, lock
	call release
	
	mov rdi, 3
	mov rsi, 0
	call sleep

	mov rdi, tid
	call wait_for_completion
	
	pprint c2_dead
	
	epilogue 0


%define lock [rsp + 16]
%define tid [rsp + 24]	
.spawn2:
	prologue 0

	pprint acquiring_lock
	mov rdi, lock
	call acquire
	pprint acquired_lock
	mov rdi, lock
	call release
	pprint releasing_lock
	
	mov rdi, 4
	mov rsi, 0
	call sleep

	mov rdi, tid
	call wait_for_completion
	pprint t2_dead

	epilogue 0
	
	
%define lock [rsp]
test_two_threads:

	mov rdi, thread_acquires_lock
	push qword 0
	lea rsi, lock
	
	call thread_create
	mov r12, rax
	
	pprint main_thread_waiting

 	mov rdi, r12
 	call wait_for_completion

	pprint main_acquire_lock

	lea rdi, lock
	call acquire
	
	pprint main_acquired_lock

	pprint main_releasing_lock
	lea rdi, lock
	call release
	
	pprint main_thread_exit

	mov rax, 0
	call sys_exit
