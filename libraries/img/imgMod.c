/*
 *  Name:
 *     imgMod

 *  Purpose:
 *     Defines default routines that obtains access to a modifyable
 *      input image.

 *  Language:
 *     ANSI C

 *  Invocation:
 *     imgMod[x]( param, nx, ny, ip, status )

 *  Description:
 *     This routine creates all the imgMod[x] routines from the
 *     generic stubs.

 *  Arguments:
 *     param = char * (Given)
 *        Parameter name. (case insensitive).
 *     nx = int * (Returned)
 *        Size of first dimension of the image (in pixels).
 *     ny = int * (Returned)
 *        Size of second dimension of the image (in pixels).
 *     ip = ? ** (Returned)
 *        Pointer to image data.
 *     status = int * (Given and Returned)
 *        The global status.

 *  Authors:
 *     PDRAPER: Peter W. Draper (STARLINK - Durham University)
 *     {enter_new_authors_here}

 *  History:
 *     28-May-1996 (PDRAPER):
 *        Original version
 *     10-JUN-1996 (PDRAPER):
 *        Converted to use more C-like names:
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

#define XIMG_MOD(type)  F77_SUBROUTINE(img_mod ## type)
#define IMG_MOD(type)   XIMG_MOD(type)

#define XIMGMOD(type)  void imgMod ## type
#define IMGMOD(type)   XIMGMOD(type)

#define XIMGMOD_CALL(type)  F77_CALL(img_mod ## type)
#define IMGMOD_CALL(type)   XIMGMOD_CALL(type)

/*  Define the macros for each of the data types for each of the
    modules, then include the generic code to create the actual
    modules. */

/*  Default type information */
#define IMG_F77_TYPE
#define IMG_SHORT_C_TYPE
#define IMG_FULL_C_TYPE float
#include "imgModGen.h"

/*  Byte */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE b
#define IMG_SHORT_C_TYPE B
#define IMG_FULL_C_TYPE signed char
#include "imgModGen.h"

/*  Unsigned Byte */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE ub
#define IMG_SHORT_C_TYPE UB
#define IMG_FULL_C_TYPE unsigned char
#include "imgModGen.h"

/*  Word */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE w
#define IMG_SHORT_C_TYPE S
#define IMG_FULL_C_TYPE short int
#include "imgModGen.h"

/*  Unsigned word */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE uw
#define IMG_SHORT_C_TYPE US
#define IMG_FULL_C_TYPE unsigned short
#include "imgModGen.h"

/*  Integer */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE i
#define IMG_SHORT_C_TYPE I
#define IMG_FULL_C_TYPE int
#include "imgModGen.h"

/*  Real */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE r
#define IMG_SHORT_C_TYPE F
#define IMG_FULL_C_TYPE float
#include "imgModGen.h"

/*  Double precision */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE d
#define IMG_SHORT_C_TYPE D
#define IMG_FULL_C_TYPE double
#include "imgModGen.h"

/* $Id$ */
