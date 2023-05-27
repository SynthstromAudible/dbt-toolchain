/*
 * assert.h
*/

#ifndef _ASSERT_H_
#define _ASSERT_H_


#ifdef NDEBUG

#define assert(ignore)  ( (void) 0)

#else

void __assert(const char *, int, const char *); /* forward declaration  */

#define assert(expr)   ((expr) ? (void)0 : \
				 (void) __assert (__FILE__, __LINE__, #expr) )

#endif  /* NDEBUG  */

#endif  /* _ASSERT_H_  */

