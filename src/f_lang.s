%include "macros.i"
%include "syscalls.i"

global chr
global add_32
global sub_32
global foldl_bytes
global map_bytes
global plus
global println
global printerr
global strlen
global to_hex
global fmt_n_bytes
global print_new_line	
global cp_bytes	
global print

	
section .data
	def_str string_too_large, `strlen of a string that was too large.\n`
hex_table:	 db `0123456789abcdef`
	
section .text
; byte -> byte
chr:
  prologue 0
  mov rax, '0'
  add rax, rdi
  epilogue 0

;; rdi must have bits 31-8 zero'd out
;;  word -> word : converts the lower byte to two hex chars stored in the word ('big endian order')
to_hex:
	mov rax, 0
	
	mov al, dil 		; store byte in sil
	and al, 0xf		; get first 4 bits
	mov al, [hex_table + rax] ; store the corresponding hex char inside sil

	shr dil, 4		; store the first 4 bits inside dl
        mov dil, [hex_table + rdi]	; store the character of the hextable in dl
	shl ax, 8		; left shift the first 4 bits as they will be displayed second
	add ax, di			; concatenate the bits
	ret
	

	;; void cp_bytes(char* src, char* dest, int size)
cp_bytes:
	%define tmp r9b
	%define src rdi
	%define dest rsi
	%define size rdx 	; no need to store in temp regs cuz no fn calls here

	prologue 0
	
	.while:
	  cmp size, 1
	  jl .done

	  mov tmp, [src + size - 1]
          mov [dest + size - 1], tmp
	
	  add size, -1
	  jmp .while
        .done:

        mov rax, 0
	epilogue 0



; int64_t -> int64_t
add_32:
  prologue 0
  add rdi, 0x20
  mov rax, rdi
  epilogue 0


; int64_t -> int64_t
sub_32:
  prologue 0
  sub rdi, 0x20
  mov rax, rdi
  epilogue 0


; (byte -> byte -> byte) -> byte -> byte* -> byte
%define f [rbp - 8]
%define acc [rbp - 16]
%define l rdx
%define i rbx
%define l_i [l + i]
foldl_bytes:
  prologue 16
  mov f, rdi
  mov acc, rsi
  mov i, 0
  .while:
    cmp byte l_i, 0
    je .end_while

    apply2 f, acc, l_i
    mov acc, rax

    inc i
    jmp .while
  .end_while:

  mov rax, acc
  epilogue 16


;; char* -> int64_t
%define str r9
%define length r8	
%define MAX_LEN 0x1000000
strlen:
   mov length, 0
   mov str, rdi

   .while:
	inc length
        cmp byte [str + length - 1], 0
	je .end_while
	cmp length, MAX_LEN
	jge .err_too_large

	jmp .while
   .end_while:

   mov rax, length
   ret
   .err_too_large:
	pprint string_too_large
	mov rax, 1
	call sys_exit

	

; (byte -> byte) -> byte* -> byte*
%define f [rbp - 8]
%define s rsi
%define s_i [s + i]
%define i rbx
map_bytes:
  prologue 8
  mov f, rdi
  mov i, 0
  .while:
      ; while condition - while not end of the string
      cmp byte s_i, 0
      je .end_of_string

      ; f(s[i])
      mov rdi, s_i
      call f

      ; s[i] = f(s[i])
      mov byte s_i, al

      inc i

      jmp .while

  .end_of_string:
  mov rax, s

  epilogue 8


; int64_t -> int64_t -> int64_T
plus:
  prologue 0
  add rdi, rsi
  mov rax, rdi
  epilogue 0

print:	
  prologue 8
  mov rax, 1

  ; Shift the args by 1 because rdi contains the stdout fd
  mov rdx, rsi
  mov rsi, rdi

  mov rdi, 1

  syscall
	
  epilogue 8


; string -> int; 0 -> success, <0 -> -errno
println:
  prologue 8
  mov rax, 1

  ; Shift the args by 1 because rdi contains the stdout fd
  mov rdx, rsi
  mov rsi, rdi

  mov rdi, 1

  syscall
	
  call print_new_line

  epilogue 8

; string -> int; 0 -> success, <0 -> -errno
printerr:
  prologue 0
  mov rax, 1

  ; Shift the args by 1 because rdi contains the stdout fd
  mov rdx, rsi
  mov rsi, rdi

  mov rdi, 2

  syscall

  epilogue 0

;;; int8*n -> char* -> n -> void (char* is 2*n + 3 byte long char array with char[-1] == \0)
%define i r12
%define dest r13
%define inp r14
%define size_t r15	
fmt_n_bytes:
	;; Save the registers that are going to be used
	push r12
	push r13
	push r14
	push r15

	;; initialize the variables
	mov dest, rsi
	mov byte [dest], 0x30
	mov byte [dest + 1], 0x78
	add dest, 2		; the first two bytes of dest are initialized with 0x

	mov inp, rdi
	mov size_t, rdx
	
	mov i, size_t
	sub i, 1

	.while:
	;; jump if i >= num_bytes
	cmp i, 0
	jl .end_while

	mov rdi, 0
	mov dil, r14b		; The current byte lives at the LSB of r14b, updated at the end of the loop
	call to_hex
	
	;; the result is in rax with the first char in LSB
	mov [dest + 2*i], ax
	
	sub i, 1
	shr r14, 8		; Shift r14 to the right by 8 to print the next byte
	
	jmp .while
	.end_while:

	pop r15
	pop r14
	pop r13
	pop r12
	ret

;;; void ()
print_new_line:
	prologue 0
	
	push 10
	mov rdi, rsp
	mov rsi, 1
	call print
	pop rdi
	
	epilogue 0

