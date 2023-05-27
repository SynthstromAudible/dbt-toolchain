/*
 * stdarg.h
*/

#ifndef _STDARG_H_
#define _STDARG_H_

#if defined(__sh__) || defined(__m32c__) || defined(__RX__) || defined(__v850__) || defined(__v850e__) || defined(__v850e2__) || defined(__v850e2v3__) || defined(__RL78__)

typedef __builtin_va_list va_list;

#define va_start(ap, parmN)	__builtin_va_start(ap, parmN)
#define va_arg(ap, mode)	__builtin_va_arg(ap, mode)
#define va_end(ap)		__builtin_va_end(ap)

#else /* defined(__sh__) || defined(__m32c__)|| defined(__RX__)  */

typedef void *va_list[1];

#if defined(__H8300H__) || defined(__H8300S__) || defined (__H8300SX__)

#define STACK_ALIGNMENT	4

#else /* defined(__H8300H__) || defined(__H8300S__) || defined (__H8300SX__)  */

/* It will come here for H8300L  */

#define STACK_ALIGNMENT 2

#endif /* defined(__H8300H__) || defined(__H8300S__) || defined (__H8300SX__)  */

#define ALIGNMENT_GAP(type)\
                ((STACK_ALIGNMENT - (sizeof(type) % STACK_ALIGNMENT)) % STACK_ALIGNMENT)

#define va_start(ap, parmN)\
                ap[0] = ((char *) &parmN) + sizeof(parmN)
	
#define va_arg(ap, mode)\
		(ap[0] = ((char*)ap[0]) + sizeof(mode) + ALIGNMENT_GAP(mode) , \
		 (*((mode*) (((char*)ap[0]) - sizeof(mode)))))
	
#define va_end(ap)      ((void)0) 

#endif /* defined(__sh__) || defined(__m32c__) || defined(__RX__)  */

#endif /* _STDARG_H_  */

