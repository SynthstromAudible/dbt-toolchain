/*
 * limits.h
*/

#ifndef _LIMITS_H_
#define _LIMITS_H_

#include "config.h"

#define CHAR_BIT         8              /* Number of bits in "char"  */

#if __CHAR_UNSIGNED__                   /* "char" = "unsigned char"  */
#define CHAR_MAX         255		/* Maximum value of "char" when it is unsigned char  */
#define CHAR_MIN         0		/* minimum value is 0 when it is unsigned char  */
#else
#define CHAR_MAX         127            /* Maximum value of "char"  */
#define CHAR_MIN        (-128)          /* Mimimum value of "char"  */
#endif

#define MB_LEN_MAX       1              /* No of bytes in multibyte char  */

#define SCHAR_MAX        127            /* Maximum value of "signed char"  */
#define SCHAR_MIN       (-128)          /* Minimum value of "signed char"  */

#define UCHAR_MAX        255            /* Maximum value of "unsigned char"  */
					/* Minimum value is zero  */

#define SHRT_MAX         32767          /* Maximum value of "signed short"  */
#define SHRT_MIN        (-32767-1)      /* Minimum value of "signed short"  */
#define USHRT_MAX        0xFFFFU        /* Maximum value of "unsigned short"  */

#if __INT_SIZE__ == 2
#define INT_MAX          32767          /* Maximum value of "signed int"  */
#define INT_MIN         (-32767-1)      /* Minimum value of "signed int"  */
#define UINT_MAX         0xFFFFU        /* Maximum value of "unsigned int"  */
#else
#define INT_MAX          2147483647	/* Maximum value of "signed int" for 32 bit int  */
#define INT_MIN         (-2147483647-1)	/* Minimum value of "signed int" for 32 bit int  */
#define UINT_MAX         0xFFFFFFFFU	/* Maximum value of "unsigned int" for 32 bit unsigned int  */
#endif

#define LONG_MAX         2147483647     /* Maximum value of "signed long"  */
#define LONG_MIN        (-2147483647-1) /* Minimum value of "signed long"  */
#define ULONG_MAX        0xFFFFFFFFU    /* Maximum value of "unsigned long"  */


#endif /* _LIMITS_H_  */

