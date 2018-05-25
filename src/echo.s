global _start

section .bss
  buf resb 16
  buf_end:

section .data
  err_reading_msg db `Error reading file\n`
  err_reading_msg_end:

  err_writing_msg db `Error writing file\n`
  err_writing_msg_end:

section .text

%define buf_count (buf_end - buf)
_start:


  ; start read from stdin
  mov rax, 0

  ; set args for read
  mov rdi, 0
  mov rsi, buf
  mov rdx, buf_count
  syscall

  ; error checking
  cmp rax, 0
  jl .err_reading


  ; store read bytes inside rbx
  mov rbx, 10

  ; start write to stdout
  mov rax, 0

  ; set the write to stdout args
  mov rdi, 1
  mov rsi, buf
  mov rdx, rbx

  syscall

  cmp rax, 0
  jl .err_writing


  ; start read from stdin
  mov rax, 0

  ; set args for read
  mov rdi, 0
  mov rsi, buf
  mov rdx, buf_count
  syscall

  ; error checking
  cmp rax, 0
  jl .err_reading

  mov rdi, 0
  jmp .end

%define err_reading_msg_len err_reading_msg - err_reading_msg_end
.err_reading:
  push rax
  mov rax, 1

  mov rdi, 1
  mov rsi, err_reading_msg
  mov rdx, err_reading_msg_len

  syscall
  pop rdi
  jmp .end

%define err_writing_msg_len err_writing_msg - err_writing_msg_end
.err_writing:
  push rax
  mov rax, 1

  mov rdi, 1
  mov rsi, err_writing_msg
  mov rdx, err_writing_msg_len

  syscall
  pop rdi
  jmp .end

.end:
  mov rax, 60
  syscall
