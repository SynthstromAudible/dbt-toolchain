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
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libm/math' -I $(MATHINC) $(CCOPTS) -fno-math-errno -fbuiltin $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/common/*.c'
	
libm_complex:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libm/math' -I '$(SRCDIR)/libm/complex' -I $(MATHINC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/complex/*.c'  
	
libm_math:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libm/math' -I $(MATHINC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/math/*.c' 
	
libm_machine:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libm/machine/arm' -I $(MATHINC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/machine/arm/*.c' 

libm_fenv:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/feclearexcept.c' 
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/fe_dfl_env.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/fegetenv.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/fegetexceptflag.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/fegetround.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/feholdexcept.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/feraiseexcept.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/fesetenv.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/fesetexceptflag.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/fesetround.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/fetestexcept.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libm/machine/fenv' -I $(MATHINC) -fno-math-errno $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libm/fenv/feupdateenv.c'

libm: libm_common lib_complex libm_math libm_machine libm_fenv

#only on 's' and 'v' targets
mathfp: libm_common libm_mathfp


libc_argz:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/argz' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/argz/*.c'  

libc_ctype:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/ctype' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/ctype/*.c'
	
libc_errno:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/errno' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/errno/*.c'

libc_locale:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/locale' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/locale/*.c'
	
libc_misc:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/misc' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/misc/__dprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/misc' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/misc/unctrl.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/misc' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/misc/ffs.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/misc' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/misc/init.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/misc' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/misc/fini.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/misc' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/misc/lock.c'
	
libc_reent:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/reent' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/reent/*.c'
	
libc_search:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/search' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/search/*.c'

libc_signal:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/signal' $(CCOPTS) $(CCUOPTS) $(ASUOPTS)  -c '$(SRCDIR)/libc/signal/*.c'

libc_stdio:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/clearerr.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fclose.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fdopen.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/feof.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/ferror.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fflush.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fgetc.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fgetpos.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fgets.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fileno.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/findfp.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/flags.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fopen.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fputc.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fputs.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fread.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/freopen.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fscanf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fseek.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fsetpos.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/ftell.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fvwrite.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fwalk.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fwrite.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/getc.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/getchar.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/getc_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/getchar_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/getdelim.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/getline.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/gets.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/makebuf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/perror.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/printf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/putc.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/putchar.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/putc_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/putchar_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/puts.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/refill.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/remove.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/rename.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/rewind.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/rget.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/scanf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/sccl.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/setbuf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/setbuffer.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/setlinebuf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/setvbuf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/snprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/sprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/sscanf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/stdio.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/tmpfile.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/tmpnam.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/ungetc.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/vdprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/vprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/vscanf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/vsnprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/vsprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/vsscanf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/wbuf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/wsetup.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/asprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fcloseall.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fseeko.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/ftello.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/getw.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/mktemp.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/putw.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/vasprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/asnprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/clearerr_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/dprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/feof_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/ferror_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fflush_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fgetc_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fgets_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fgetwc.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fgetwc_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fgetws.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fgetws_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fileno_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fmemopen.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fopencookie.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fpurge.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fputc_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fputs_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fputwc.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fputwc_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fputws.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fputws_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fread_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fsetlocking.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/funopen.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fwide.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fwprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fwrite_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/fwscanf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/getwc.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/getwc_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/getwchar.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/getwchar_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/open_memstream.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/putwc.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/putwc_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/putwchar.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/putwchar_u.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/stdio_ext.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/swprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/swscanf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/ungetwc.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/vasnprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/vswprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/vswscanf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/vwprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/vwscanf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/wprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/wscanf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' -I '$(SRCDIR)/libc/stdio/nano' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/nano/nano-vfprintf_float.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' -I '$(SRCDIR)/libc/stdio/nano' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DSTRING_ONLY -c '$(SRCDIR)/libc/stdio/nano/nano-vfprintf.c' -o nano-svfprintf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' -I '$(SRCDIR)/libc/stdio/nano'$(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DSTRING_ONLY -c '$(SRCDIR)/libc/stdio/nano/nano-vfscanf.c' -o nano-svfscanf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' -I '$(SRCDIR)/libc/stdio/nano'$(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/nano/nano-vfprintf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' -I '$(SRCDIR)/libc/stdio/nano'$(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/nano/nano-vfprintf_i.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' -I '$(SRCDIR)/libc/stdio/nano'$(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/nano/nano-vfscanf.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' -I '$(SRCDIR)/libc/stdio/nano'$(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/nano/nano-vfscanf_i.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' -I '$(SRCDIR)/libc/stdio/nano' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/nano/nano-vfscanf_float.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTEGER_ONLY -DSTRING_ONLY -c '$(SRCDIR)/libc/stdio/vfwprintf.c' -o svfiwprintf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DSTRING_ONLY -c '$(SRCDIR)/libc/stdio/vfwprintf.c' -o svfwprintf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTEGER_ONLY -c '$(SRCDIR)/libc/stdio/vfwprintf.c' -o vfiwprintf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTEGER_ONLY -DSTRING_ONLY -c '$(SRCDIR)/libc/stdio/vfwscanf.c' -o svfiwscanf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DSTRING_ONLY -c '$(SRCDIR)/libc/stdio/vfwscanf.c' -o svfwscanf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTEGER_ONLY -c '$(SRCDIR)/libc/stdio/vfwscanf.c' -o vfiwscanf.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdio' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdio/vfwscanf.c'
		
libc_stdlib:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(LIBGLOSS) $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/stdlib/*.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_FREE -c '$(SRCDIR)/libc/stdlib/mallocr/nano-mallocr.c' -o nano-freer.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_REALLOC -c '$(SRCDIR)/libc/stdlib/mallocr/nano-mallocr.c' -o nano-reallocr.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_CALLOC -c '$(SRCDIR)/libc/stdlib/mallocr/nano-mallocr.c' -o nano-callocr.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_CFREE -c '$(SRCDIR)/libc/stdlib/mallocr/nano-mallocr.c' -o nano-cfreer.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_MALLINFO -c '$(SRCDIR)/libc/stdlib/mallocr/nano-mallocr.c' -o nano-mallinfor.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_MALLOC_STATS -c '$(SRCDIR)/libc/stdlib/mallocr/nano-mallocr.c' -o nano-mallstatsr.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_MALLOC_USABLE_SIZE -c '$(SRCDIR)/libc/stdlib/mallocr/nano-mallocr.c' -o nano-msizer.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_MALLOC -c '$(SRCDIR)/libc/stdlib/mallocr/nano-mallocr.c' -o nano-mallocr.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_MEMALIGN -c '$(SRCDIR)/libc/stdlib/mallocr/nano-mallocr.c' -o nano-malignr.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_MALLOPT -c '$(SRCDIR)/libc/stdlib/mallocr/nano-mallocr.c' -o nano-malloptr.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_PVALLOC -c '$(SRCDIR)/libc/stdlib/mallocr/nano-mallocr.c' -o nano-pvallocr.o
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/stdlib' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -DINTERNAL_NEWLIB -DDEFINE_VALLOC -c '$(SRCDIR)/libc/stdlib/mallocr/nano-mallocr.c' -o nano-vallocr.o

libc_string:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/string' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/string/*.c'

libc_time:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/time' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/time/*.c'

libc_machine:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/setjmp.S'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/strcmp.S'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/strcpy.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/aeabi_memcpy.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/aeabi_memcpy-armv7a.S'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/aeabi_memmove.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/aeabi_memmove-soft.S'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/aeabi_memset.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/aeabi_memset-soft.S'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/aeabi_memclr.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/memchr-stub.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/memchr.S'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/memcpy-stub.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/memcpy.S'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/strlen-stub.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/machine/arm/strlen.S'
	
libc_syscalls:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/syscalls' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/syscalls/*.c'
	
libc_sys:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm/sys' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/sys/arm/access.c'
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/machine/arm/sys' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/sys/arm/aeabi_atexit.c'
	
libc_ssp:
	@$(CC) -isystem '$(SRCDIR)/targ-include_nano' $(SINC) -I. -I '$(SRCDIR)/libc/ssp' $(CCOPTS) $(CCUOPTS) $(ASUOPTS) -c '$(SRCDIR)/libc/ssp/*.c'
	
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