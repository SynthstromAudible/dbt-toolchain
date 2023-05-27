
#ifndef _IOHEADER_H_
#define _IOHEADER_H_

#include "stdarg.h"

/* Formatter used by "scanf" and "sscanf"  */
/* Full ANSI (parameters are line, format, ap)  */

int _formatted_read(const char **, const char **, va_list);

/* Formatters used by "printf" and "sprintf"  */
/* Full ANSI (parameters are format, output-function, secret-pointer, ap)  */

int _formatted_write(const char *, void (*)(char, void *), void *, va_list);

#endif /* _IOHEADER_H_  */
