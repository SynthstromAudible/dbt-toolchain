/*
 * stdlib.h
*/

#ifndef _STDLIB_H_
#define _STDLIB_H_

#include "stddef.h"     /* For size_t and wchar_t  */

#ifndef NULL
#define NULL    ((void*) 0 )
#endif

typedef struct
{
  int   quot;
  int   rem;
} div_t;

typedef struct
{
  long int      quot;
  long int      rem;
} ldiv_t;

#if __INT_MAX__ == 32767
#define RAND_MAX        0x7FFF
#else
#define RAND_MAX	0x7FFFFFFF
#endif

#define EXIT_SUCCESS    0
#define EXIT_FAILURE    1

#define MB_CUR_MAX      1


void *malloc(size_t);
void free(void *);
void exit(int);
void *calloc(size_t, size_t);
void *realloc(void *, size_t);
int  atoi(const char *);
long atol(const char *);
double atof(const char *);
double strtod(const char *, char **);
long int strtol(const char *, char **, int);
unsigned long int strtoul(const char *, char **, int);
int rand(void);
void srand(unsigned int);
void abort(void);
int abs(int);
div_t div(int, int);
long int labs(long int);
ldiv_t ldiv(long int, long int);
void *bsearch(const void *, const void *,
              size_t, size_t,
              int (*)(const void *,const void *));
void qsort(void *, size_t, size_t,
           int (*)(const void *, const void *));

#endif /* _STDLIB_H_  */

