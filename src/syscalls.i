; ERRNO defs https://github.com/torvalds/linux/blob/master/include/uapi/asm-generic/errno-base.h

%ifndef SYSCALLS_I
%define SYSCALLS_I

extern sys_futex
extern sys_exit
extern sys_open
extern sys_getdents
extern sys_close

; From https://github.com/torvalds/linux/blob/ead751507de86d90fa250431e9990a8b881f713c/tools/arch/alpha/include/uapi/asm/mman.h
%define PROT_READ 0x0
%define PROT_WRITE 0x2
%define PROT_EXEC 0x100

%define MAP_SHARED 0x1
%define MAP_PRIVATE 0x2
%define MAP_ANONYMOUS 0x20
%define MAP_GROWSDOWN 0x100

%define CLONE_VM 0x100
%define CLONE_FS 0x200
%define CLONE_FILES 0x400
%define CLONE_SIGHAND 0x800
%define CLONE_THREAD 0x10000


%define FUTEX_WAIT 0x0
%define FUTEX_WAKE 0x1
%define FUTEX_PRIVATE_FLAG 0x80
%define FUTEX_CLOCK_REALTIME 0x100
%define FUTEX_CMP_REQUEUE 0x4

%define EAGAIN -11

%define O_RDONLY	0x00000000
%define O_DIRECTORY	0x100000	

%endif


