/*
 *  Name:
 *     imgOut
 
 *  Purpose:
 *     Defines all the imgOut modules.
 
 *  Language:
 *     ANSI C
 
 *  Invocation:
 *     imgOut( param1, param2, ip, status )
 
 *  Description:
 *     This routine creates all the imgIn[x] routines from the
 *     generic stubs. 

 *  Arguments:
 *     param1 = char * (Given)
 *        Parameter name for the input image (case insensitive).
 *     param2 = char * (Given)
 *        Parameter name for the new output image (case insensitive).
 *     ip = ? * (Returned)
 *        Pointer to the mapped output data.
 *     status = int * (Given and Returned)
 *        The global status.
 
 *  Authors:
 *     PDRAPER: Peter W. Draper (STARLINK - Durham University)
 *     {enter_new_authors_here}
 
 *  History:
 *     28-May-1996 (fcwrap):
 *        Original version.
 *     10-JUN-1996 (PDRAPER):
 *        Changed to use more C-like names.
 *     {enter_changes_here}
 
 *-
 */
#include <string.h>
#include <stdlib.h>
#include "cnf.h"
#include "f77.h"
#include "img1.h"

/*  Define the various names of the subroutines. Note we use two
    macros that join the parts to the type because of use of ## 
    needs to be deferred a while!
    */

#define XIMG_OUT(type)  F77_SUBROUTINE(img_out ## type)
#define IMG_OUT(type)   XIMG_OUT(type)

#define XIMGOUT(type)  void imgOut ## type
#define IMGOUT(type)   XIMGOUT(type)

#define XIMGOUT_CALL(type)  F77_CALL(img_out ## type)
#define IMGOUT_CALL(type)   XIMGOUT_CALL(type)

/*  Define the macros for each of the data types for each of the
    modules, then include the generic code to create the actual
    modules. */

/*  Default type information */
#define IMG_F77_TYPE 
#define IMG_SHORT_C_TYPE
#define IMG_FULL_C_TYPE float
#include "imgOutGen.h"

/*  Byte */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE b
#define IMG_SHORT_C_TYPE B
#define IMG_FULL_C_TYPE signed char
#include "imgOutGen.h"

/*  Unsigned Byte */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE ub
#define IMG_SHORT_C_TYPE UB
#define IMG_FULL_C_TYPE unsigned char
#include "imgOutGen.h"

/*  Word */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE w
#define IMG_SHORT_C_TYPE S
#define IMG_FULL_C_TYPE short int
#include "imgOutGen.h"

/*  Unsigned word */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE uw
#define IMG_SHORT_C_TYPE US
#define IMG_FULL_C_TYPE unsigned short 
#include "imgOutGen.h"

/*  Integer */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE i
#define IMG_SHORT_C_TYPE I
#define IMG_FULL_C_TYPE int
#include "imgOutGen.h"

/*  Real */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE r
#define IMG_SHORT_C_TYPE F
#define IMG_FULL_C_TYPE float
#include "imgOutGen.h"

/*  Double precision */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE d
#define IMG_SHORT_C_TYPE D
#define IMG_FULL_C_TYPE double 
#include "imgOutGen.h"

/* $Id$ */
