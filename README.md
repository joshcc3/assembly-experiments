Concurrent File Traversal in Assembly
-------------------------------------

#Build
make in the root directory.
If providing your own file, directory handlers then delete the 

#Run
./target/map_reduce/map_reduce <dir>



#Implementation
Traverses the file system and submits directory names to a provided directory handler and filenames to a file handler. I didn't use an actual heap but just passed around references to the stack. As a consequence passing arguments to threads is impossible(?). So instead I use a memory map for shared memory (you can use flags that allow the OS to optimize its treament since it's thread local). I spawn a new thread for every new directory encountered.

##Threads

Threads are implemented with the clone syscall which takes a pointer to the top of the stack and some flags (fork is implemented in terms of clone and the flags are used to determine if the forked process is treated as a thread or not).
Threads - has a global tid, unique across all tids/pids of existing threads/processes on the system. It is part of a thread group and shares the same pid as its peers. Threads (depending on what flags are passed to clone) will share the virtual memory, file system meta info, file handlers, interrupt handlers and other things with the originating process. It has its own registers and thread local memory. 
Process - Is actually a process group. Processes not created with the `CLONE_THREAD` flag are put in their own process group with pid == tid. Signals can be delivered to any thread in a process group. `SIGCHLD` is delivered when all threads in a process die to the parent.

The clone syscall returns to the address at the top of its own stack so this (it's stack) needs to be prepared (pushing the address for the thread to jump to) before the cloned thread returns. A useful thread interface is to take a function pointer and an args array described across registers and the stack and call the function while performing cleanup (unmapping the stack) after. When trying to unmap you must provide an address aligned on a page boundary.

I use a table in `.bss` to keep track of a futex per thread to be used for waiting on thread exit.


##File Traversal
`getdents` is the syscall for retrieving directory information. You call it on a file descriptor corresponding to an open directory. It fills a (provided) buffer with an array of directory entries (containing the directory name, inode and file type).
`open`, opens a file for reading (you can specify whether it's a temp file/must be a directory and various   other things).

##Locks
###cmpxchg
This is an assembly instruction implementing compare and swap. ( src <- dest if rax == src else rax <- src atomically). I think the docs are misleading (wrong?) on this.

###Futex
Futexes are a syscall that allow fast userspace locking. It supports multiple operations, I use the simplest ones WAIT and WAKE. WAIT sleeps on a futex (a 32 bit value in memory) if the value at that location matches the argument provided to the syscall until a WAKE (just takes the address of the syscall) has been called on the futex.

###My Locks
I implemented a simple version of locks with 2 states, 0 - unlocked; 1 - locked.
`cmpxchg` does a compare and swap  on the lock (compares the src - the lock - with 0 and sets it to 1, otherwise sets rax with the lock value). If the operation fails (wasn't able to lock because it's already locked - detected by checking if rax has changed) then sleep on the lock (futex) of 1. Do this until the lock is acquired.

There are other more efficient implementations:

#### Avoid unnecessary calls to WAKE:
(Taken from (here)[https://github.com/winstonli/nihserver])

To lock:

 - 0: Atomically try 0 -> 1. If successful, return. Otherwise, loop again.
 - 1: Atomically try 1 -> 2. Loop again.
 - 2: Ask futex() to sleep us if the value is still 2. Loop again.

To unlock:
 - 0: What happened? Assert out.
 - 1: Atomically try 1 -> 0. If successful, return. Otherwise, loop again.
 - 2: Only we can change the value, so just set it to 0. Ask futex() to wake someone. Return.

This has the advantage that we don't call WAKE if the lock is uncontended.


#### No wake even in a contended case

To lock:
    - 00: 10 - locked and uncontended atomically, if it fails then loop
    - 01: Shouldnt happen
    - 10: -> 11 atomically
    - 11: Just sleep on the futex
    


To unlock:
    - 00: shouldn't happen
    - 01: shouldn't happen
    - 10: atomically set 1 -> 0, no wake ups
    - 11: atomically set the first 1 -> 0, and wake up a thread only if the value is still 01.

We eliminate another case of an unecessary wakeup here by detecting whether another thread has obtained the lock between the time we unlock (set 1 -> 0) and are about to wake someone up.



#Notes
Assemble programs `nasm -f elf64 -i . -g -F dwarf <assembly-file> -o <out>`. This assembles the program as an elf64 executable, includes the current directory for the `%include` directory, adds symbols for debugging via the `dwarf` flag and generates `out`.

All assembly programs start at `_start` which must be exported via `global` for the linker. There must be a single _start function.

By default everything lives in the `.text` section. The usualy sections are `.data`, `.bss`. Different sections have different combinations of read, write, progbits flags enabled. The usual layout consists of .text, .data, .bss from the bottom and the stack from the top (around 0x7fffffffffffffff). The sections usually have some random padding between them. 

The start function should sys_exit at the end. otherwise it will tear off into the rest of the app.

Syscalls are heavy - they take a microsecond while normal instructions take a nanoseconds.

I'm not sure that `r11` is preserved across instructions!

Single line macros `%define`, multi-line macros with `%macro`, `%endmacro`.

The `call` instruction pushes the return address onto the stack. `jmp $` jumps to the current positions ($, $$ - location of start, location of beginning of section I think).


#Debugging

Run programs in gdb with `gdb <program>`. Run a program with args via `gdb --args <prog> <arg1> <arg2> ...`.

next (n), step (s), step into (si), printf (p/<d/x/c/b>), examine (x/<num units><size><format>), run (r), continue (c), break (b), b *0x40123 (break at address), b *(<label> + offset), info thread (i thread), threads, i regis (info registers)

layout asm - show the relevant assembly, set disassembly-flavor intel - use intel syntax, set $<register>=<value> (use to set the program counter for example).

Create a .gdbinit file in a directory for commands used on start up.


			    
#TODO
 - It sometimes deadlocks on large file trees
 - Providing custom implementations of file handlers and directory handling is strange.
 - Need to limit the number of threads active at a point in time.



#Lessons
 - Prefer to set all values that use only part of a register, esp. ones where you use only a part of the register to a known (0?) value
 - Check all arguments before making a function call - e.g. for futex - you *must* zero out the timestruct
 - When constructing a large program, never keep things in your head, jot them down as todos as soon as they occur to you
 - Make sure that all functions return
 - Make sure to always pop off everything that you push.
 - Remember to set the return value in rax fo
 - Never refer to registers by their names unless its for initialization - always use macros or the stack
 - Pay close attention to the size of the operands and registers used
 - Prefer using the callee's registers unless you don't make any calls in the function
 - Prefer the stack over raw registers because you have to either save them between calls or restore them at the end depending on which set you use
 - Always provide signature types in definitions.
 - Always state your invariants and provide asserts
 - Perform error checking on operations
 - Sometimes arguments need to be page aligned - futex
 - Always perform error handling after every operation
 - Perform bounds checking
