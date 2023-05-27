/* 
 * string.h
*/

#ifndef _STRING_H_
#define _STRING_H_

#include "stddef.h"     /* For size_t  */

#ifndef NULL
#define NULL    ((void*)0)
#endif

void *memcpy(void *, const void *, size_t);
void *memmove(void *, const void *, size_t);
void *memchr(const void *, int, size_t);
void *memset(void *, int, size_t);
int memcmp(const void *, const void *, size_t);
char *strchr(const char *, int);
int strcmp(const char *, const char *);
int strncmp(const char *, const char *, size_t);
int strcoll(const char *, const char *);
size_t strlen(const char *);
size_t strcspn(const char *, const char *);
size_t strspn(const char *, const char *);
char *strpbrk(const char *, const char *);
char *strrchr(const char *, int);
char *strstr(const char *, const char *);
char *strcat(char *, const char *);
char *strncat(char *, const char *, size_t);
char *strcpy(char *, const char *);
char *strncpy(char *, const char *, size_t);
char *strerror(int);
char *strtok(char *, const char *);
size_t strxfrm(char *, const char *, size_t);

#endif /* _STRING_H_  */

