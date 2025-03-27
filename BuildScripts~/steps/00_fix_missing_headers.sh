#!/bin/bash -eu

echo "Creating missing header files for host compilation..."

# Create directories for missing headers
mkdir -p "$HOME/android-ndk-r21b/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/asm"

# Create stub asm/errno.h
cat > "$HOME/android-ndk-r21b/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/asm/errno.h" << 'EOF'
/* Stub header for WebRTC build */
#ifndef _ASM_GENERIC_ERRNO_H
#define _ASM_GENERIC_ERRNO_H

#define EPERM            1      /* Operation not permitted */
#define ENOENT           2      /* No such file or directory */
#define ESRCH            3      /* No such process */
#define EINTR            4      /* Interrupted system call */
#define EIO              5      /* I/O error */
/* Add other error codes as needed */

#endif /* _ASM_GENERIC_ERRNO_H */
EOF

# Create stub asm/types.h
cat > "$HOME/android-ndk-r21b/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/asm/types.h" << 'EOF'
/* Stub header for WebRTC build */
#ifndef _ASM_TYPES_H
#define _ASM_TYPES_H

#include <stdint.h>

typedef uint32_t __u32;
typedef int32_t  __s32;
typedef uint16_t __u16;
typedef int16_t  __s16;
typedef uint8_t  __u8;
typedef int8_t   __s8;
typedef uint64_t __u64;
typedef int64_t  __s64;

#endif /* _ASM_TYPES_H */
EOF

# Create stub asm/posix_types.h
cat > "$HOME/android-ndk-r21b/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/asm/posix_types.h" << 'EOF'
/* Stub header for WebRTC build */
#ifndef _ASM_POSIX_TYPES_H
#define _ASM_POSIX_TYPES_H

#include <stdint.h>

#define __FD_SETSIZE      1024

typedef unsigned long __kernel_mode_t;
typedef long          __kernel_long_t;
typedef unsigned long __kernel_ulong_t;
typedef unsigned short __kernel_sa_family_t;
typedef unsigned short __kernel_uid16_t;
typedef unsigned short __kernel_gid16_t;
typedef unsigned int   __kernel_uid32_t;
typedef unsigned int   __kernel_gid32_t;
typedef unsigned int   __kernel_size_t;
typedef int            __kernel_ssize_t;
typedef int            __kernel_ptrdiff_t;
typedef long           __kernel_time_t;
typedef long           __kernel_off_t;
typedef unsigned long  __kernel_ino_t;
typedef unsigned int   __kernel_ipc_pid_t;
typedef unsigned int   __kernel_mode_t;
typedef unsigned int   __kernel_daddr_t;
typedef int            __kernel_pid_t;
typedef int            __kernel_timer_t;
typedef int            __kernel_clockid_t;

/* Needed for socket APIs */
typedef unsigned short __kernel_sa_family_t;
typedef unsigned int   __kernel_sockptr_t;

#endif /* _ASM_POSIX_TYPES_H */
EOF

echo "Stub header files created. You can now try building again."