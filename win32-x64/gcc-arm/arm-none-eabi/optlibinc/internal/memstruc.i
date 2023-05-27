
#ifndef _MEMSTRUC_I_
#define _MEMSTRUC_I_


/* The header for each allocated region on the heap */
typedef struct
{
  char busy;
  char *next;
} _m_header;

/* A union that is here to get the maximum alignment bucket */
typedef union 
{
  long l;
  long double ld;
  char *p;
} __align_union__;

/* Get number of align bucket from number of bytes in the heap */
#define __HEAP_SIZE__(x) ((x) / sizeof(__align_union__))

#ifndef __MAX_ALIGNMENT__
/* Note, this macro must be used in run-time code */
#ifndef __ALIGNOF__
#define __ALIGNOF__(type) (sizeof(struct {type y; char a;}) - sizeof(type))
#endif
#define __MAX_ALIGNMENT__ (__ALIGNOF__(__align_union__)) 
#endif

#endif /* _MEMSTRUC_I_ */
