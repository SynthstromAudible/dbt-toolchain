TARGET = arm
TYPE = none-eabi
AR := $(TARGET)-$(TYPE)-ar
CC := $(TARGET)-$(TYPE)-gcc
RANLIB := $(TARGET)-$(TYPE)-ranlib
CCOPTS = -D__NO_SYSCALLS__ -DHAVE_INIT_FINI -D_COMPILING_NEWLIB -fno-builtin
#and this too "-D_LDBL_EQ_DBL", when "-m64bit-doubles'
SINC := -isystem '$(SRCDIR)/libc/include'
MATHINC := '$(SRCDIR)/libm/common'
LIBGLOSS :=  -L '$(SRCDIR)/libgloss/arm' -L '$(SRCDIR)/libgloss/libnosys'
AR_SW = -rc
LIBPATH =
CCUOPTS = 
ASUOPTS = 

ifeq ($(findstring -m64bit-doubles,$(CCUOPTS)),)
CCOPTS += -D_LDBL_EQ_DBL
endif

MKFILE_PATH := $(realpath $(MAKEFILE_LIST))
MKFILE_DIR := $(dir $(MKFILE_PATH))

#clean
clean:
	@echo Cleaning...
	-@$(RM) *.o

#all
all_announce:
	@echo Starting build for '$(@:_announce=)'...


libm_common:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I $(MATHINC) $(CCOPTS) -fno-math-errno -fbuiltin $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/common/*.c'
	
libm_complex:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libm/complex' -I $(MATHINC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/complex/*.c'  
	
libm_math:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libm/math' -I $(MATHINC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/math/*.c' 
	
libm_machine:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libm/machine/arm' -I $(MATHINC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/machine/arm/*.c' 

libm_fenv:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/feclearexcept.c' 
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/fe_dfl_env.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/fegetenv.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/fegetexceptflag.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/fegetround.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/feholdexcept.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/feraiseexcept.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/fesetenv.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/fesetexceptflag.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/fesetround.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/fetestexcept.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/feupdateenv.c'

libm: libm_common lib_complex libm_math libm_machine libm_fenv

#only on 's' and 'v' targets
mathfp: libm_common libm_mathfp


libc_argz:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/argz' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/argz/*.c'  

libc_ctype:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/ctype' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/ctype/*.c'
	
libc_errno:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/errno' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/errno/*.c'

libc_locale:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/locale' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/locale/*.c'
	
libc_misc:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/misc' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/misc/*.c'
	
libc_reent:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/reent' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/reent/*.c'
	
libc_search:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/search' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/search/*.c'

libc_signal:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/signal' $(CCOPTS) $(CCUOPTS) $(ASUOPTS)  -c '$(SRCDIR)/libc/signal/*.c'

libc_stdio:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/*.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTEGER_ONLY -DSTRING_ONLY -c '$(SRCDIR)/libc/stdio/vfprintf.c' -o svfiprintf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DSTRING_ONLY -c '$(SRCDIR)/libc/stdio/vfprintf.c' -o svfprintf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTEGER_ONLY -DSTRING_ONLY -c '$(SRCDIR)/libc/stdio/vfscanf.c' -o svfiscanf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DSTRING_ONLY -c '$(SRCDIR)/libc/stdio/vfscanf.c' -o svfscanf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTEGER_ONLY -c '$(SRCDIR)/libc/stdio/vfprintf.c' -o vfiprintf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/vfscanf.c' -o vfscanf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTEGER_ONLY -c '$(SRCDIR)/libc/stdio/vfscanf.c' -o vfiscanf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTEGER_ONLY -DSTRING_ONLY -c '$(SRCDIR)/libc/stdio/vfwprintf.c' -o svfiwprintf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DSTRING_ONLY -c '$(SRCDIR)/libc/stdio/vfwprintf.c' -o svfwprintf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTEGER_ONLY -c '$(SRCDIR)/libc/stdio/vfwprintf.c' -o vfiwprintf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTEGER_ONLY -DSTRING_ONLY -c '$(SRCDIR)/libc/stdio/vfwscanf.c' -o svfiwscanf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DSTRING_ONLY -c '$(SRCDIR)/libc/stdio/vfwscanf.c' -o svfwscanf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTEGER_ONLY -c '$(SRCDIR)/libc/stdio/vfwscanf.c' -o vfiwscanf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/vfwscanf.c' -o vfwscanf.o

libc_stdlib:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(LIBGLOSS) $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdlib/*.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_FREE -c '$(SRCDIR)/libc/stdlib/mallocr/mallocr.c' -o freer.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_REALLOC -c '$(SRCDIR)/libc/stdlib/mallocr/mallocr.c' -o reallocr.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_CALLOC -c '$(SRCDIR)/libc/stdlib/mallocr/mallocr.c' -o callocr.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_CFREE -c '$(SRCDIR)/libc/stdlib/mallocr/mallocr.c' -o cfreer.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_MALLINFO -c '$(SRCDIR)/libc/stdlib/mallocr/mallocr.c' -o mallinfor.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_MALLOC_STATS -c '$(SRCDIR)/libc/stdlib/mallocr/mallocr.c' -o mallstatsr.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_MALLOC_USABLE_SIZE -c '$(SRCDIR)/libc/stdlib/mallocr/mallocr.c' -o msizer.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_MALLOC -c '$(SRCDIR)/libc/stdlib/mallocr/mallocr.c' -o mallocr.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_MEMALIGN -c '$(SRCDIR)/libc/stdlib/mallocr/mallocr.c' -o malignr.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_MALLOPT -c '$(SRCDIR)/libc/stdlib/mallocr/mallocr.c' -o malloptr.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_PVALLOC -c '$(SRCDIR)/libc/stdlib/mallocr/mallocr.c' -o pvallocr.o
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_VALLOC -c '$(SRCDIR)/libc/stdlib/mallocr/mallocr.c' -o vallocr.o

libc_string:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/string' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/string/*.c'

libc_time:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/time' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/time/*.c'

libc_machine:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/setjmp.S'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/strcmp.S'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/strcpy.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/aeabi_memcpy.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/aeabi_memcpy-armv7a.S'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/aeabi_memmove.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/aeabi_memmove-soft.S'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/aeabi_memset.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/aeabi_memset-soft.S'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/aeabi_memclr.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/memchr-stub.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/memchr.S'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/memcpy-stub.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/memcpy.S'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/strlen-stub.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/strlen.S'
	
libc_syscalls:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/syscalls' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/syscalls/*.c'
	
libc_sys:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm/sys' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/sys/arm/access.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm/sys' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/sys/arm/aeabi_atexit.c'
	
libc_ssp:
	@$(CC) -isystem '$(SRCDIR)/targ-include' $(SINC) -I. -I '$(SRCDIR)/libc/ssp' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/ssp/*.c'
	
libc: libc_argz libc_errno libc_locale libc_machine libc_misc libc_reent libc_reent libc_search libc_signal libc_ctype libc_stdio  libc_string

math: libm_common libm_math libm_complex libm_fenv

common: libc_argz libc_errno libc_locale libc_machine libc_ssp libc_syscalls libc_sys libc_misc libc_reent libc_search libc_signal libc_time

stdio: libc_stdio

stdlib: libc_stdlib

string: libc_string

ctype: libc_ctype

all: stdio stdlib string ctype common math

lib: all $(patsubst lib,,$(MAKECMDGOALS))
	@echo Creating library $(LIBPATH)
	@$(AR) $(AR_SW) '$(LIBPATH)' *.o
	@$(RANLIB) '$(LIBPATH)'