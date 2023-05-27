/*
 * ctype.h
*/

#ifndef _CTYPE_H_
#define _CTYPE_H_

#define _U      01
#define _L      02
#define _N      04
#define _S      010
#define _P      020
#define _C      040
#define _X      0100
#define _B      0200


int isalpha(int);
int isupper(int);
int islower(int);
int isdigit(int);
int isxdigit(int);
int isspace(int);
int ispunct(int);
int isalnum(int);
int isprint(int);
int isgraph(int);
int iscntrl(int);
int toupper(int);
int tolower(int);

extern	const char	*__ctype_ptr;
extern	const char	_ctype_[];  /* For backward compatibility.  */

#endif /* _CTYPE_H_  */

