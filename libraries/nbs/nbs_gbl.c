#include <stdio.h>
#include "nbs_typ.h"

/* Modified 28-Jun-04 (Alasdair Allan, Norman Gray, Tim Jenness)
   Symbols were undefined under Mac OSX and GCC 3.3, defining the pointer
   to NULL fixed this (int's set to zero just in case). Looks to be from the
   ISO-9899:1999 standard (section 6.9.2) (commonly refered to as C99) which 
   declares that:
   
    "A declaration of an identifier for an object that has file scope 
    without an initializer, and without a storage-class specified for with 
    the storage-class specifier static, constitutes a tentative definition. 
    If a translation unit contains one or more tentative definitions for an
    identifier, and the translation unit contains no external definitions for
    that identifier, then the behaviour is exactly as if the translation unit
    contains a file scope declaration of that identifier, with the composite
    type as of the end of the translation unit, with an initializer equal to 0.
*/   

/* External definitions   */

int nbs_gl_defining = 0; /* Currently defining noticeboard contents? */
item_id nbs_ga_base = NULL; /* Pointer to base of noticeboard currently being
                               defined */

int nbs_ga_alloc_next = 0;
int nbs_ga_alloc_base = 0;
int nbs_ga_alloc_last = 0;
int nbs_ga_alloc_data = 0;

int nbs_gl_item_total = 0;	/* Current total size of Item_descriptor's */
int nbs_gl_fixed_total = 0;	/* Current total size of Fixed_info's */
int nbs_gl_shape_total = 0;	/* Current total size of shape information */
int nbs_gl_boardinfo_total = 0; /* Current total size of Board_info's */
int nbs_gl_data_total = 0;	/* Current total size of primitive data */

int nbs_gl_pid = 0;		/* PID of current process */






