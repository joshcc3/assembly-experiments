%ifndef ERRNO_I
%define

errno_table:
eperm		dq EPERM		
enoent		dq ENOENT		
esrch		dq ESRCH		
eintr		dq EINTR		
eio		dq EIO		
enxio		dq ENXIO		
e2big		dq E2BIG		
enoexec		dq ENOEXEC		
ebadf		dq EBADF		
echild		dq ECHILD		
eagain		dq EAGAIN		
enomem		dq ENOMEM		
eacces		dq EACCES		
efault		dq EFAULT		
enotblk		dq ENOTBLK		
ebusy		dq EBUSY		
eexist		dq EEXIST		
exdev		dq EXDEV		
enodev		dq ENODEV		
enotdir		dq ENOTDIR		
eisdir		dq EISDIR		
einval		dq EINVAL		
enfile		dq ENFILE		
emfile		dq EMFILE		
enotty		dq ENOTTY		
etxtbsy		dq ETXTBSY		
efbig		dq EFBIG		
enospc		dq ENOSPC		
espipe		dq ESPIPE		
erofs		dq EROFS		
emlink		dq EMLINK		
epipe		dq EPIPE		
edom		dq EDOM		
erange		dq ERANGE		
errno_table_end:


EPERM		 db `Operation not permitted\n\0` ; 1
ENOENT		 db `No such file or directory\n\0` ; 2
ESRCH		 db `No such process\n\0` ; 3
EINTR		 db `Interrupted system call\n\0` ; 4
EIO		 db `I/O error\n\0` ; 5
ENXIO		 db `No such device or address\n\0` ; 6
E2BIG		 db `Argument list too long\n\0` ; 7
ENOEXEC		 db `Exec format error\n\0` ; 8
EBADF		 db `Bad file number\n\0` ; 9
ECHILD		db `No child processes\n\0` ; 10
EAGAIN		db `Try again\n\0` ; 11
ENOMEM		db `Out of memory\n\0` ; 12
EACCES		db `Permission denied\n\0` ; 13
EFAULT		db `Bad address\n\0` ; 14
ENOTBLK		db `Block device required\n\0` ; 15
EBUSY		db `Device or resource busy\n\0` ; 16
EEXIST		db `File exists\n\0` ; 17
EXDEV		db `Cross-device link\n\0` ; 18
ENODEV		db `No such device\n\0` ; 19
ENOTDIR		db `Not a directory\n\0` ; 20
EISDIR		db `Is a directory\n\0` ; 21
EINVAL		db `Invalid argument\n\0` ; 22
ENFILE		db `File table overflow\n\0` ; 23
EMFILE		db `Too many open files\n\0` ; 24
ENOTTY		db `Not a typewriter\n\0` ; 25
ETXTBSY		db `Text file busy\n\0` ; 26
EFBIG		db `File too large\n\0` ; 27
ENOSPC		db `No space left on device\n\0` ; 28
ESPIPE		db `Illegal seek\n\0` ; 29
EROFS		db `Read-only file system\n\0` ; 30
EMLINK		db `Too many links\n\0` ; 31
EPIPE		db `Broken pipe\n\0` ; 32
EDOM		db `Math argument out of domain of func\n\0` ; 33
ERANGE		db `Math result not representable\n\0` ; 34


%endif
