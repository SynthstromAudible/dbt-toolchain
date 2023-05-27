TARGET = arm
TYPE = none-eabi
CC = $(TARGET)-$(TYPE)-gcc
AS = $(TARGET)-$(TYPE)-as
AR = $(TARGET)-$(TYPE)-ar
CCOPTS = -nostdlib -nostdinc -fno-builtin -w -c -xc -
ASOPTS = -nostdlib -nostdinc -fno-builtin -w -c -xassembler-with-cpp -
#$(BASEDIR) should be the same as $(dir $(MAKEFILE_LIST)) but "$(dir ..)" function truncates at first space
INCDIR = -I "$(BASEDIR)/../$(TARGET)-$(TYPE)/optlibinc"
AR_SW = -rcus
LIBPATH = ./libopt.a
CCUOPTS = 
ASUOPTS = 

ifneq ($(findstring -m64bit-doubles,$(CCUOPTS)),)
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

all: all_announce common ctype stdlib string stdio math
	@echo Build finished for '$@'...

#lib
lib_announce:
	@echo Starting build for '$(@:_announce=)'...

lib: lib_announce $(patsubst lib,,$(MAKECMDGOALS))
	@echo Creating library $(LIBPATH)
	@$(AR) $(AR_SW) "$(LIBPATH)" *.o

#math
acos.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/acos.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

modf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/modf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

cos.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/cos.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

atan2.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/atan2.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

ceil.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/ceil.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

floor.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/floor.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

fabs.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/$(TARGET)/fabs.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

satan.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/satan.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

cosh.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/cosh.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

sinh.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/sinh.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

tanh.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/tanh.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

sinus.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/sinus.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

exp.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/exp.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

exp10.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/exp10.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

exp10f.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/exp10f.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

tan.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/tan.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

atan.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/atan.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

asin.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/asin.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

sin.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/sin.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

acosf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/acosf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

asinf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/asinf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

atan2f.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/atan2f.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

atanf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/atanf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

ceilf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/ceilf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

cosf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/cosf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

coshf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/coshf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

expf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/expf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

floorf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/floorf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

fmodf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/fmodf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

log10f.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/log10f.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

logf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/logf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

powf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/powf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

sinf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/sinf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

sinhf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/sinhf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

sqrtf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/sqrtf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

tanf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/tanf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

tanhf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/tanhf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

sqrt.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/sqrt.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

pow.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/pow.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

log10.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/log10.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

log.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/log.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

fmod.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/fmod.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

frexp.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/frexp.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

ldexpf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/ldexpf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

frexpf.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/frexpf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

ldexp.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/common/ldexp.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

dgetexp.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/$(TARGET)/dgetexp.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

dnormexp.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/$(TARGET)/dnormexp.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

daddexp.o:
	@$(TARGET)-$(TYPE)-libpack -f optm/$(TARGET)/daddexp.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@


#common
assert.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/common/assert.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

errno.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/common/errno.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

_exit.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/$(TARGET)/_exit.S $(CC) $(ASOPTS) $(CCUOPTS) $(ASUOPTS) $(INCDIR) -o $@

_atexit.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/common/atexit.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@


#ctype
ctype.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/ctype/ctype.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

isalnum.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/ctype/isalnum.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

isalpha.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/ctype/isalpha.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

iscntrl.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/ctype/iscntrl.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

isdigit.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/ctype/isdigit.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

isgraph.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/ctype/isgraph.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

islower.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/ctype/islower.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

isprint.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/ctype/isprint.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

ispunct.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/ctype/ispunct.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

isspace.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/ctype/isspace.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

isupper.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/ctype/isupper.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

isxdigit.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/ctype/isxdigit.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

tolower.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/ctype/tolower.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

toupper.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/ctype/toupper.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@


#stdlib
abort.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/abort.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

abs.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/abs.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

atof.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/atof.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

atoi.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/atoi.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

atol.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/atol.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

bsearch.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/bsearch.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

calloc.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/calloc.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

div.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/div.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

exit.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/exit.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

labs.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/labs.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

ldiv.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/ldiv.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

newfree.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/newfree.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

newheap.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/newheap.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

newmalloc.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/newmalloc.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

newrealloc.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/newrealloc.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

rand.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/rand.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

qsort.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/qsort.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

srand.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/srand.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

strtod.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/strtod.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

strtol.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/strtol.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

strtoul.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdlib/strtoul.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@


#stdio
frmrd.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdio/frmrd.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

frmwri.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdio/frmwri.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

_getchar.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdio/getchar.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

gets.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdio/gets.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

printf.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdio/printf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

putchar.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdio/putchar.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

puts.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdio/puts.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

scanf.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdio/scanf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

sprintf.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdio/sprintf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

snprintf.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdio/snprintf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

sscanf.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdio/sscanf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

vprintf.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdio/vprintf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

vsprintf.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/stdio/vsprintf.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@


#string
memmove.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/memmove.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

_memchr.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/memchr.c $(CC) $(CCOPTS) $(CCUOPTS) $(CCUOPTS) $(INCDIR) -o $@

_memcmp.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/memcmp.c $(CC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) $(INCDIR) -o $@

_memcpy.o: 
	@$(TARGET)-$(TYPE)-libpack -f optc/string/memcpy.c $(CC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) $(INCDIR) -o $@

_memset.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/memset.c $(CC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) $(INCDIR) -o $@

_strcat.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strcat.c $(CC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) $(INCDIR) -o $@

_strncat.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strncat.c $(CC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) $(INCDIR) -o $@

_strchr.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strchr.c $(CC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) $(INCDIR) -o $@

_strrchr.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strrchr.c $(CC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) $(INCDIR) -o $@

_strcmp.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strcmp.c $(CC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) $(INCDIR) -o $@

_strcpy.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strcpy.c $(CC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) $(INCDIR) -o $@

_strncpy.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strncpy.c $(CC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) $(INCDIR) -o $@

strcspn.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strcspn.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

strerror.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strerror.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

_strlen.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strlen.c $(CC) $(CCOPTS) $(CCUOPTS) $(ASUOPTS) $(INCDIR) -o $@

strpbrk.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strpbrk.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

strrchr.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strrchr.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

strspn.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strspn.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

strstr.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strstr.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

strtok.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strtok.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

strcoll.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strcoll.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@

strxfrm.o:
	@$(TARGET)-$(TYPE)-libpack -f optc/string/strxfrm.c $(CC) $(CCOPTS) $(CCUOPTS) $(INCDIR) -o $@


#math
math_announce:
	@echo Starting build for '$(@:_announce=)'...

math: math_announce acos.o modf.o cos.o atan2.o ceil.o floor.o fabs.o satan.o cosh.o sinh.o tanh.o sinus.o exp.o exp10.o exp10f.o tan.o atan.o asin.o sin.o tanf.o \
 acosf.o asinf.o atan2f.o atanf.o ceilf.o cosf.o coshf.o expf.o floorf.o fmodf.o log10f.o logf.o powf.o sinf.o sinhf.o sqrtf.o tanf.o tanhf.o \
 sqrt.o pow.o log10.o log.o fmod.o frexp.o ldexpf.o frexpf.o ldexp.o dgetexp.o dnormexp.o daddexp.o
	@echo Build finished for '$@'...


#common
common_announce:
	@echo Starting build for '$(@:_announce=)'...
	
common: common_announce assert.o _atexit.o errno.o _exit.o
	@echo Build finished for '$@'...


#ctype
ctype_announce:
	@echo Starting build for '$(@:_announce=)'...
	
ctype: ctype_announce ctype.o isalnum.o isalpha.o iscntrl.o isdigit.o isgraph.o islower.o isprint.o ispunct.o isspace.o isupper.o isxdigit.o tolower.o toupper.o
	@echo Build finished for '$@'...


#stdio
stdio_announce:
	@echo Starting build for '$(@:_announce=)'...

stdio: stdio_announce frmrd.o frmwri.o _getchar.o gets.o printf.o putchar.o puts.o scanf.o sprintf.o sscanf.o vprintf.o vsprintf.o
	@echo Build finished for '$@'...


#stdlib
stdlib_announce:
	@echo Starting build for '$(@:_announce=)'...

stdlib: stdlib_announce abort.o abs.o atof.o atoi.o atol.o bsearch.o calloc.o div.o exit.o labs.o ldiv.o newfree.o newheap.o newmalloc.o newrealloc.o qsort.o rand.o srand.o strtod.o strtol.o strtoul.o
	@echo Build finished for '$@'...


#string
string_announce: 
	@echo Starting build for '$(@:_announce=)'...

string: string_announce memmove.o _memchr.o _memcmp.o _memcpy.o _memset.o _strcat.o _strncat.o _strchr.o _strrchr.o _strcmp.o _strcpy.o _strncpy.o strcspn.o strerror.o _strlen.o strpbrk.o strrchr.o strspn.o strstr.o strtok.o strxfrm.o strcoll.o
	@echo Build finished for '$@'...
