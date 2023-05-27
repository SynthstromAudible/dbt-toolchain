/*
 * config.h
*/

#ifndef _CONFIG_H_
#define _CONFIG_H_


#ifndef __CHAR_SIZE__
#define __CHAR_SIZE__ 1
#endif

#ifndef __SHORT_SIZE__
#define __SHORT_SIZE__ 2
#endif

#if defined (__sh__) || defined (__RX__) || defined (__v850__) || defined (__arm__)

#ifndef __INT_SIZE__
#define __INT_SIZE__ 4
#endif

#else

#ifndef __INT_SIZE__
#define __INT_SIZE__ 2
#endif

#endif

#ifndef __LONG_SIZE__
#define __LONG_SIZE__ 4
#endif

#ifndef __FLOAT_SIZE__
#define __FLOAT_SIZE__ 4
#endif

#if defined (__sh__) || defined (__RX__) || defined(__m32c__) || defined(__v850__) || defined(__RL78__) || defined (__arm__)

#ifndef __DOUBLE_SIZE__
#define __DOUBLE_SIZE__ 8
#endif

#ifndef __LONG_DOUBLE_SIZE__
#define __LONG_DOUBLE_SIZE__ 8

#else /* defined (__sh__) || defined (__RX__) || defined(__m32c__)  */
 
#ifndef __DOUBLE_SIZE__
#define __DOUBLE_SIZE__ 4
#endif

#ifndef __LONG_DOUBLE_SIZE__
#define __LONG_DOUBLE_SIZE__ 4
#endif 

#endif /* defined (__sh__) || defined (__RX__) || defined(__m32c__)  */
#endif 
#endif /* _CONFIG_H_  */
