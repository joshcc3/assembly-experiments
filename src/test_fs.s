%include "f_lang.i"
%include "fs.i"
%include "macros.i"
%include "assert.i"
%include "syscalls.i"	
%include "string.i"

	
global _start

section .data
def_str filename_prompt, `Filename: \0`
def_str fd_was_restricted, `FD returned by open was 0,1,2\n\0`
def_str done_msg, `Done.\n\0`
def_str error_ls_msg, `Error ls\n\0`
def_str str1, `1: This is string1\0`
def_str str2, `2: This is string2\0`	



pathname db `.\0`
%define BUF_SIZE 0x100000
	


section .text

test_path_join:

	mov rdi, str1
	call stringlen
	mov r12, rax

	mov rdi, str2
	call stringlen
	mov r14, rax

	mov r13, r12
	add r13, r14
	;;  includes both \0s one of which will be the pathsep
	
	
	sub rsp, r13

	mov rdi, str1
	mov rsi, str2
	mov rdx, rsp
	call path_join

	mov rdi, rsp
	mov rsi, r13
	call println

	sub rsp, 7
	mov byte [rsp + 4], 0

	mov rdi, r13
	mov rsi, rsp
	mov rdx, 1
	call fmt_n_bytes

	mov rdi, rsp
	mov rsi, 5
	call println
	

	mov rdi, 0
	call sys_exit
	
test_concat:
	
	mov rdi, str1
	call stringlen
	mov r12, rax

	mov rdi, str2
	call stringlen
	add r12, rax

	sub r12, 1
	
	sub rsp, r12

	mov rsi, str1
	mov rdi, str2
	mov rdx, rsp
	call concat

	mov rdi, rsp
	mov rsi, r12
	call println
	


	mov rdi, 0
	call sys_exit
	


bad_fd_msg db `Bad fd\n\0`
check_for_error:
	prologue 0
	cmp rdi, 0
	jge .check_2

	;; preserve rdi
	mov rsi, bad_fd_msg
	call assert_false_with_return_code ; Error opening the file

	.check_2:
	cmp rdi, 2
	jg .done
	;;  preserve rdi
	mov rsi, fd_was_restricted
	call assert_false_with_return_code ; returned 0, 1, 2 - shouldn't happen!

	.done:
epilogue 0


next_fname:
	%define fd [rbp - 8]
	%define buffer [rbp - 16]
	%define buffer_size [rbp - 24]
	%define cur_buf [rbp - 32]
	%define function_handler [rbp - 40]
	%define last_read_bytes r12
	prologue 40

	push r12
	
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
	jne .done

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
	
	.done:

	pop r12
	mov rax, r14
	epilogue 40

def_str processing_message, `Processing: \0`
handle_fname:
	push r12
	push r13
	
	mov r12, rdi
	mov r13, rsi
	
	mov rdi, processing_message
	mov rsi, processing_message_len
	call print

	mov rdi, r12
	mov rsi, r13
	call println

	pop r13
	pop r12
	ret



%define flags [rbp - 8]
%define fd [rbp - 16]
%define buf_ptr [rbp - 24]
%define buf_size [rbp - 32]
_start:
	prologue 32
	
	mov qword buf_size, 0
	mov rdi, pathname 		; open dir
	call open_dir
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
	call next_fname
	
	.while:	
	mov rdi, r12
	mov rsi, rsp
	mov rdx, 256
	mov rcx, rax
	mov r8, rbp
	add r8, -32
	mov r9, handle_fname
	call next_fname
	cmp rax, NULL
	jle .done
	jmp .while
	
	.done:
	mov rdi, 0
	call sys_exit
