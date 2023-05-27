/*
 * stddef.h
*/

#ifndef _STDDEF_H_
#define _STDDEF_H_

#ifndef NULL
#define NULL            ((void *) 0)
#endif

#if defined (__H8300H__) || defined (__H8300S__) || defined (__H8300SX__)
#if (!defined (__NORMAL_MODE__) && (__INT_MAX__ == 32767))
typedef unsigned long	size_t;
#elif defined (__NORMAL_MODE__)
#if (__INT_MAX__ == 32767)
typedef unsigned int    size_t;
#else
typedef unsigned short  size_t;
#endif /* #if (__INT_MAX__ == 32767)  */
#else
typedef unsigned long   size_t;
#endif /* #if (!defined (__NORMAL_MODE__) && (__INT_MAX__ == 32767))  */
#else
typedef unsigned int    size_t;
#endif /* #if defined (__H8300H__) || defined (__H8300S__) || defined (__H8300SX__)  */

typedef int             ptrdiff_t;

#ifndef offsetof
#define offsetof(type,member)   ((size_t)(&((type *)0)->member))
#endif

#ifndef wchar_t
#define wchar_t char
#endif

#endif /* _STDDEF_H_ */

