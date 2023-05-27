
#ifndef _INTRINS_INCLUDED
#define _INTRINS_INCLUDED
#if defined (__H8300H__) || defined (__H8300S__) || defined (__H8300SX__) || defined (__H8300__) || defined (__NORMAL_MODE__)
#if(__SIZEOF_DOUBLE__==8) || defined (DOUBLE_HAS_64_BITS)

signed short __dgetexp(double arg);
double __daddexp(double arg,signed short exp);

#else

signed char __dgetexp(double arg);
                                        /* Extract the exponent, so that  */
                                        /* 2 raised to the exponent times  */
                                        /* the mantissa becomes the  */
                                        /* argument, if the mantissa is  */
                                        /* [0.5,1.0)  */
double __daddexp(double arg,signed char exp);
                                        /* Add the exp to the one in the  */
                                        /* argument, not checking for over-  */
                                        /* under-flow  */

#endif

double __dnormexp(double arg);
	                                    /* Set the exponent so that the  */
                                        /* argument is [0.5,1.0)  */
#else

#if(__SIZEOF_DOUBLE__==8) || defined (DOUBLE_HAS_64_BITS)

signed char dgetexp(double arg);
double daddexp(double arg,signed short exp);

#else

signed char dgetexp(double arg);
                                        /* Extract the exponent, so that  */
                                        /* 2 raised to the exponent times  */
                                        /* the mantissa becomes the  */
                                        /* argument, if the mantissa is  */
                                        /* [0.5,1.0)  */
double daddexp(double arg,signed char exp);
                                        /* Add the exp to the one in the  */
                                        /* argument, not checking for over-  */
                                        /* under-flow  */

#endif

double dnormexp(double arg);
	                                    /* Set the exponent so that the  */
                                        /* argument is [0.5,1.0)  */
#endif
extern double __satan (double);
extern double __sinus (double,unsigned char);
                       
#endif /* _INTRINS_INCLUDED  */
