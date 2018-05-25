%ifndef FS_I
%define FS_I

%define DT_UNKNOWN	0
%define DT_FIFO		1
%define DT_CHR		2
%define DT_DIR		4
%define DT_BLK		6
%define DT_REG		8
%define DT_LNK		10
%define DT_SOCK		12
%define DT_WHT		14

%ifndef FS_S
%define FS_S

extern open_dir
extern ls_next
extern fname
extern fname_len
extern inode
extern file_type
extern path_join


%endif



;            struct linux_dirent {
;                unsigned long  d_ino;     /* Inode number */
;                unsigned long  d_off;     /* Offset to next linux_dirent */
;                unsigned short d_reclen;  /* Length of this linux_dirent */
;                char           d_name[];  /* Filename (null-terminated) */
;                                  /* length is actually (d_reclen - 2 -
;                                     offsetof(struct linux_dirent, d_name)) */
;                /*
;                char           pad;       // Zero padding byte
;                char           d_type;    // File type (only since Linux
;                                          // 2.6.4); offset is (d_reclen - 1)
;                */
;            }


%define linux_dirent.d_ino 0
%define linux_dirent.d_off 8
%define linux_dirent.d_reclen 16
%define linux_dirent.d_name 18		; var len
%define	linux.d_pad -2
%define	linux.d_type -1



%endif
