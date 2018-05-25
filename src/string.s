%include "macros.i"
%include "assert.i"
%include "f_lang.i"
	

global stringlen
global concat
global string_equals

section .text

	;; int stringlen(char* a, char* b)
string_equals:
	prologue 0
	%define a_ptr rdi
	%define b_ptr rsi
	%define a byte [a_ptr]
	%define b byte [b_ptr]

	.while:
	cmp a, NULL
	je .done
	cmp b, NULL
	je .false

	mov r11b, a
	mov r8b, b
	cmp r11b, r8b
	jne .false
	inc a_ptr
	inc b_ptr
	jmp .while
	.done:

	mov r11b, a
	mov r8b, b
	cmp r11b, r8b
	jne .false

	mov rax, 1
	epilogue 0

	.false:
	mov rax, 0
	epilogue 0



	
	;;  int stringlen(char* s)
stringlen:
	prologue 0
	
	mov rsi, rdi

	mov rdx, 0
	.while:
	mov dl, byte [rdi]
	cmp dl, NULL
	je .done

	inc rdi
	jmp .while
	.done:


	mov rax, rdi
	sub rax, rsi
	inc rax

	epilogue 0


	;;  void concatenate(char* s1, char* s2, char* s3)
%define tmp r8b
%define p3 rdx
%define p2 rsi
%define p1 rdi
concat:
	prologue 0
	
	.while1:
          mov tmp, byte [p1]
	  cmp tmp, 0
	  je .done1
	  
	  mov byte [p3], tmp
	
	  inc p3
	  inc p1
	  jmp .while1
	.done1:


	.while2:
	mov tmp, byte [p2]
	cmp tmp, 0
	je .done2

	mov byte [p3], tmp

	inc p2
	inc p3

	jmp .while2
	.done2:

	mov byte [p3], 0
	epilogue 0

        
