TARGET=arm
TYPE=none-eabi
AR:=$(TARGET)-$(TYPE)-ar
CC:=$(TARGET)-$(TYPE)-gcc
CCOPTS=-c -W -Wall -Wno-narrowing -Wwrite-strings -Wcast-qual -Wstrict-prototypes -Wmissing-prototypes -Wold-style-definition -Dinhibit_libc -fno-inline -O2 -fbuilding-libgcc -fno-stack-protector -ffunction-sections -fdata-sections
ASOPTS=-c -xassembler-with-cpp -ffunction-sections -fdata-sections
FLAGS1=-DIN_GCC -DCROSS_DIRECTORY_STRUCTURE -DIN_LIBGCC2 -DHAVE_CC_TLS
INC="$(SRCDIR)/include"
AR_SW=-rcus
LIBPATH=./libgcc.a
CCUOPTS=
ASUOPTS=

all:
	$(warning There is no implementation for project-generated libgcc for ARM!)

lib: $(OBJS)
	$(warning There is no implementation for project-generated libgcc for ARM!)

clean:
	-@$(RM) *.o

