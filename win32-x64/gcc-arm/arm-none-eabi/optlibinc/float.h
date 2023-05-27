/*
 * float.h
*/

#ifndef _FLOAT_H_
#define _FLOAT_H_

#define FLT_RADIX       2
#define FLT_ROUNDS      1

#define FLT_MANT_DIG    24
#define FLT_EPSILON     1.192092896e-07
#define FLT_DIG         6                       /* Digits of precision  */
#define FLT_MIN_EXP     -125
#define FLT_MIN         1.175494351e-38         /* Min positive value  */
#define FLT_MIN_10_EXP  -37                     /* Min decimal exponent  */
#define FLT_MAX_EXP     128
#define FLT_MAX         3.402823466e+38         /* Max value  */
#define FLT_MAX_10_EXP  38                      /* Max decimal exponent  */

#if(__SIZEOF_DOUBLE__==8 || DOUBLE_HAS_64_BITS)
	#define DBL_MANT_DIG    53
	#define DBL_EPSILON     2.2204460492503131e-016
	#define DBL_DIG         15                      /* Digits of precision  */
	#define DBL_MIN_EXP     -1021
	#define DBL_MIN         2.2250738585072014e-308 /* Min positive value  */
	#define DBL_MIN_10_EXP  -307                    /* Min decimal exponent  */
	#define DBL_MAX_EXP     1024
	#define DBL_MAX         1.7976931348623158e+308 /* Max value  */
	#define DBL_MAX_10_EXP  308                     /* Max decimal exponent  */
#else
	#define DBL_MANT_DIG    FLT_MANT_DIG
	#define DBL_EPSILON     FLT_EPSILON
	#define DBL_DIG         FLT_DIG
	#define DBL_MIN_EXP     FLT_MIN_EXP
	#define DBL_MIN         FLT_MIN
	#define DBL_MIN_10_EXP  FLT_MIN_10_EXP 
	#define DBL_MAX_EXP     FLT_MAX_EXP
	#define DBL_MAX         FLT_MAX
	#define DBL_MAX_10_EXP  FLT_MAX_10_EXP
#endif

	#define LDBL_MANT_DIG   DBL_MANT_DIG
	#define LDBL_EPSILON    DBL_EPSILON
	#define LDBL_DIG        DBL_DIG
	#define LDBL_MIN_EXP    DBL_MIN_EXP
	#define LDBL_MIN        DBL_MIN
	#define LDBL_MIN_10_EXP DBL_MIN_10_EXP 
	#define LDBL_MAX_EXP    DBL_MAX_EXP
	#define LDBL_MAX        DBL_MAX
	#define LDBL_MAX_10_EXP DBL_MAX_10_EXP

#endif /* _FLOAT_H_  */

