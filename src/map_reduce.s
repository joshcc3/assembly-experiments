%include "f_lang.i"
%include "fs.i"
%include "macros.i"
%include "assert.i"
%include "syscalls.i"	
%include "string.i"
%include "threads.i"
%include "heap.i"
%include "lock.i"
	
global _start

section .bss
stdout_lock resq 1

section .data
def_str filename_prompt, `Filename: \0`
def_str fd_was_restricted, `FD returned by open was 0,1,2\n\0`
def_str done_msg, `Done.\n\0`
def_str error_ls_msg, `Error ls\n\0`
def_str str1, `1: This is string1\0`
def_str str2, `2: This is string2\0`	
def_str dir_msg, `Encountering Directory: \0`
def_str no_args_msg, `Usage: ./map_reduce <root_dir>\n\0`

%define BUF_SIZE 0x1000		; Size of the buffer to read in directory entries - 1 page can fit about 40 dir entries - 80 char filepath + 20 bytes for other dirent info
	


section .text

%define flags [rbp - 8]
%define fd [rbp - 16]
%define buf_ptr [rbp - 24]
%define buf_size [rbp - 32]
%define cur_dir r13
visit_dir:
	prologue 32
	push r12
	push r13
	mov cur_dir, [rbp + 16]

	mov qword buf_size, 0

	
	mov rdi, cur_dir
	call open_dir
	cmp rax, 0
	jl .error_opening_dir

	mov r12, rax		; r12 fd
	
	sub rsp, BUF_SIZE

	;; In the loop we set the current buffer to the result of ls_next
	;; Over here we initialize the current buffer to the start of the buffer
	mov rdi, r12
	mov rsi, rsp
	mov rdx, 256
	mov rcx, rsp
	mov r8, rbp
	add r8, -32
	mov r9, handle_fname
	mov r10, cur_dir
	push handle_dirname
	call next_fname
	add rsp, 8


	.while:	
	mov rdi, r12
	mov rsi, rsp
	mov rdx, 256
	mov rcx, rax
	mov r8, rbp
	add r8, -32
	mov r9, handle_fname
	mov r10, cur_dir
	push handle_dirname
	call next_fname
	add rsp, 8

	cmp rax, NULL
	jle .done
	jmp .while
	
	.done:

	mov rdi, fd
	call sys_close

	add rsp, BUF_SIZE
	pop r13
	pop r12
	epilogue 32

.error_opening_dir:
	mov rdi, stdout_lock
	call acquire	

	mov rdi, r13
	call stringlen
	mov rdi, r13
	mov rsi, rax
	call printerr
	call printerr_new_line

	mov rdi, stdout_lock
	call release

	mov rdi, .error_opening_dir_msg
	mov rsi, .error_opening_dir_msg
	call assert_false

.error_opening_dir_msg: db `Error opening directory\n\0`


next_fname:
	%define fd [rbp - 8]
	%define buffer [rbp - 16]
	%define buffer_size [rbp - 24]
	%define cur_buf [rbp - 32]
	%define function_handler [rbp - 40]
	%define dir_handler [rbp + 16]
	%define last_read_bytes r12
	%define cur_dir [rbp - 48]
	prologue 48

	push r12
	push r13
	push r14
	push rbx

	mov cur_dir, r10
	mov fd, rdi
	mov buffer, rsi
	mov buffer_size, rdx
	mov cur_buf, rcx
	mov last_read_bytes, r8
	mov function_handler, r9

	mov rdi, fd
	mov rsi, buffer
	mov rdx, buffer_size
	mov rcx, last_read_bytes
	mov r8, cur_buf
	call ls_next
	mov r14, rax		; r14, start of the dir ent

	cmp r14, NULL
	je .done

	mov rdi, r14
	call file_type

	cmp rax, DT_REG
	je .is_file

	cmp rax, DT_DIR
	je .is_dir

	.done:

	mov rax, r14
	
	pop rbx
	pop r14
	pop r13
	pop r12

	epilogue 48
	


	.is_dir:
 	mov rdi, cur_dir
 	call stringlen
 	mov r12, rax
 	
	mov rdi, r14
	call fname_len
	sub rsp, rax
	mov r13, rax
	
	mov rdi, r14
	mov rsi, rsp
	mov rdx, r13
	call fname		; store fname in [rsp + 8]
	
 
 	mov rbx, r12
 	add rbx, r13
 
 	sub rsp, rbx
	
   	mov rdi, cur_dir
   	lea rsi, [rsp + rbx]
   	mov rdx, rsp
   	call path_join

     	mov rdi, rsp
     	mov rsi, rbx
      	call dir_handler

 	add rsp, rbx
	add rsp, r13
	jmp .done

	

	.is_file:
	mov rdi, r14
	call fname_len
	sub rsp, rax
	push rax
	
	mov rdi, r14
	mov rsi, rsp
	add rsi, 8
	mov rdx, [rsp]
	call fname		; store fname in [rsp + 8]

	mov rdi, rsp
	add rdi, 8
	mov rsi, [rsp]		; print fname
	call function_handler
	
	pop rdi
	add rsp, rdi
	jmp .done

dot:	db `/.\0`
doubledot:	 db `/..\0`
handle_dirname:
	push r12
	push r13
	push r14
	
	mov r12, rdi		; the dir name
	mov r13, rsi		; the dir name length

	mov rdi, dot		; check that its not '.'
	lea rsi, [r12 + r13 - 3]
	call string_equals
	cmp rax, 1
	je .done
	
	mov rdi, doubledot	; check that its not '..'
	lea rsi, [r12 + r13 - 4]
	call string_equals
	cmp rax, 1
	je .done
	

	
	mov rdi, stdout_lock
	call acquire

	;;  Print a processing message
	mov rdi, dir_msg
	mov rsi, dir_msg_len
	call print

	mov rdi, r12		; print the dirname
	mov rsi, r13
	call println

	mov rdi, stdout_lock
	call release


	mov rdi, r13		; 'malloc' r13 bytes
	call malloc
	mov r14, rax		; save the pointer to r14

	mov rdi, r12
	mov rsi, r14
	mov rdx, r13
	call cp_bytes		; cp the dirname into r14 from r12
	
	mov rdi, visit_dir	; spawn a thread to visit the dirs recursively
	mov rsi, r14		; use the pointer saved to my 'heap'
	call thread_create

	.done:
	pop r14
	pop r13
	pop r12
	ret


def_str processing_message, `Processing: \0`
handle_fname:
	push r12
	push r13
	
	mov r12, rdi
	mov r13, rsi
	
	mov rdi, stdout_lock
	call acquire

	mov rdi, processing_message
	mov rsi, processing_message_len
	call print

	mov rdi, r12
	mov rsi, r13
	call println
	
	mov rdi, stdout_lock
	call release

	pop r13
	pop r12
	ret


_start:
	mov rax, [rsp]
	cmp rax, 2
	jl .insufficient_args

	mov r12, [rsp + 16]
	
	call init_heap
	
	mov rdi, visit_dir	
 	mov rsi, r12
 	call thread_create

	mov rdi, 0
	call sys_exit
	

	.insufficient_args:
	mov rdi, no_args_msg
	mov rsi, no_args_msg_len
	call printerr

	mov rdi, -1
	call sys_exit
