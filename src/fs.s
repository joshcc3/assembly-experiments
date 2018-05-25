%define FS_S	

%include "macros.i"
%include "f_lang.i"
%include "assert.i"
%include "syscalls.i"
%include "fs.i"
%include "string.i"


global open_dir
global ls_next
global fname
global fname_len
global inode
global file_type
global path_join


section .data
path_seperator db `/`

section .text

%define path_seperator `/`
%define result_path_sep r12
%define result_offsetted r13
%define p1 r14
%define p2 rbx
%define p1_size [rbp - 8]
%define p2_size [rbp - 16]
%define result [rbp - 24]	
path_join:
	prologue 24
	push r12
	push r13
	push r14
	push rbx

	mov p1, rdi
	mov p2, rsi
	mov result, rdx

	mov rdi, p1
	call stringlen
	mov p1_size, rax

	mov rdi, p2
	call stringlen
	mov p2_size, rax
	
	mov result_path_sep, result
	add result_path_sep, p1_size
	sub result_path_sep, 1
	
	mov result_offsetted, result_path_sep
	add result_offsetted, 1

	
	mov rdi, p1
	mov rsi, result
	mov rdx, p1_size
	call cp_bytes

	mov byte [result_path_sep], path_seperator

	mov rdi, p2
	mov rsi, result_offsetted
	mov rdx, p2_size
	call cp_bytes

	
	pop rbx
	pop r14
	pop r13
	pop r12
	epilogue 24
	

	
	;;  ulong inode(linux_dirent* dirent)
inode:	
	prologue 0
	mov rax, qword [rdi + linux_dirent.d_ino]
	epilogue 0
	
	;; void fname_len(linux_dirent* dirent, char* dest, int size) 
	;;  copies size bytes from src to dest
fname:
	prologue 0
	lea rdi, [rdi + linux_dirent.d_name]
	call cp_bytes
	epilogue 0
	
	;;  int fname_len(linux_dirent* dirent)
%define name_len r8w
%define buf rdi
fname_len:	
	prologue 0


	lea rdi, [rdi + linux_dirent.d_name]
	mov r8, rdi
	
	mov r9, 0
	.while:
	mov r9b, [rdi]
	cmp r9b, 0
	jz .done
	inc rdi
	jmp .while
	.done:
	
	sub rdi, r8
	mov rax, rdi
	inc rax

	epilogue 0

	
	
	;;  int file_type(linux_dirent *stat)
file_type:
	prologue 0
	mov rax, 0
	mov rdx, 0
	mov rsi, rdi		; buf_ptr into rax
	mov dx, [rsi + linux_dirent.d_reclen] ; mov rax to the end of the buffer
	add rsi, rdx
	add rsi, linux.d_type		     ; position of d_type relative to end
	mov al, byte [rsi]
	epilogue 0


	;;  fd_t open_dir(char* fname)
open_dir:
	prologue 0
	
	;; mov rdi, pathname		 ;; element of the directory
	mov rsi,  O_RDONLY | O_DIRECTORY	; 
	mov rdx, 0		; mode - zeroed, only needed for O_CREAT, O_TMPFILE
	call sys_open

	epilogue 0


	;;  void ls_next(fd_t fd, void* buffer, buffer_size, linux_dirent* cur_buf)
ls_next:
	%define cur_buf r12
	%define next_buffer r13
	%define buffer_end r14
	%define buffer [rbp - 8]
	%define fd [rbp - 16]
	%define buffer_size [rbp - 24]	
	%define bytes_read_so_far rbx

	prologue 24
	push cur_buf
	push next_buffer
	push buffer_end
	push bytes_read_so_far
	
	mov bytes_read_so_far, rcx
	mov cur_buf, r8		; current dirent
	mov buffer_size, rdx
	mov buffer, rsi
	mov buffer_end, buffer
	add buffer_end, [bytes_read_so_far] ; End of the buffer
	mov fd, rdi
	
	cmp cur_buf, NULL
	je .reinitbuf
	
	
	mov r9, 0
	mov r9w, word [cur_buf + linux_dirent.d_reclen] ; size of the record
	mov next_buffer, cur_buf
	add next_buffer, r9	       ; start of the next entry
	
	mov r9, next_buffer
	add r9, 23

	cmp r9, buffer_end
	jge .reinitbuf		; cur_buf == null || next_buf > buffer_end, reinit
	
	

	.done:
	
	mov rax, next_buffer	; result = next_buffer

	pop bytes_read_so_far
	pop buffer_end
	pop next_buffer
	pop cur_buf
	epilogue 24

	.reinitbuf:
	mov rdi, fd
	mov rsi, buffer
	mov rdx, buffer_size
	call sys_getdents	; getdents(fd, buf, BUF_SIZE)
	mov [bytes_read_so_far], rax

	cmp qword [bytes_read_so_far], 0
	jl .error
	je .null_result
	mov next_buffer, buffer	; start of the buffer
	jmp .done

	.null_result:
	mov next_buffer, NULL
	jmp .done

	.error:
	mov rdi, rax
	mov rsi, .error_msg
	call assert_false_with_return_code
	.error_msg db `Error reading from dirent\n\0`
