
#ifndef _heap_h_
#define _heap_h_

extern char end;			/* provided by linker  */

extern char* _heap_of_memory;		/* Beginning of heap  */

extern char* _last_heap_object;         /* Current heap pointer  */

extern char* _top_of_heap(void);	/* returns end of heap memory  */

#endif

