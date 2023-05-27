/* 
 * stdio.h
*/

#ifndef _STDIO_H_
#define _STDIO_H_

#include "stdarg.h"
#include "stddef.h"	/* For size_t  */

#ifndef NULL
#define NULL    ((void *) 0)
#endif

#ifndef EOF
#define EOF     (-1)
#endif

int  puts(const char *);
int  putchar(int);
int  getchar(void);

int  printf(const char *,...);
int  sprintf(char *,const char *,...);

int  vsprintf(char *,const char *,va_list);
int  vprintf(const char *,va_list);
int  scanf(const char *,...);
int  sscanf(const char *, const char *,...);
char *gets(char *);

#endif /* _STDIO_H_  */



