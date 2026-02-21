// misc.h (C) 1996 DG Lane

#ifndef __MISC_H__
#define __MISC_H__

#include <math.h>

#ifndef ASSERT
#define ASSERT(x) if (!(x)) { \
    printf("Assertion failed at line %i in file %s", __LINE__, __FILE__); \
    exit(0); \
}
#endif

// #ifdef expl
#define REAL long double
#define EXP expl
#define FABS fabsl
// #else
// #define REAL double
// #define EXP exp
// #define FABS fabs
// #endif

#ifdef random
#define RAND_RANGE(x) ((REAL)(random() & 0xFFFF)*(x)/(REAL)(0xFFFF))
#else
#define RAND_RANGE(x) ((REAL)(rand())*(REAL)(x)/(REAL)(RAND_MAX))
#endif

#define MAX(x,y) ((x) > (y)) ? (x) : (y)

#define MIN(x,y) ((x) < (y)) ? (x) : (y)

#endif
