/*
 *  Name:
 *     imgTmp2

 *  Purpose:
 *     Defines default routines that create a temporary 2-D image.

 *  Language:
 *     ANSI C

 *  Invocation:
 *     imgTmp2[x]( param, nx, ny, ip, status )

 *  Description:
 *     This routine creates all the imgNew[x] routines from the
 *     generic stubs.

 *  Arguments:
 *     param = char * (Given)
 *        Parameter name. (case insensitive).
 *     nx = int * (Given)
 *        Size of first dimension of the image (in pixels).
 *     ny = int * (Given)
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
 *        Changed to use more C-like names for routines.
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

#define XIMG_TMP2(type)  F77_SUBROUTINE(img_tmp2 ## type)
#define IMG_TMP2(type)   XIMG_TMP2(type)

#define XIMGTMP2(type)  void imgTmp2 ## type
#define IMGTMP2(type)   XIMGTMP2(type)

#define XIMGTMP2_CALL(type)  F77_CALL(img_tmp2 ## type)
#define IMGTMP2_CALL(type)   XIMGTMP2_CALL(type)

/*  Define the macros for each of the data types for each of the
    modules, then include the generic code to create the actual
    modules. */

/*  Default type information */
#define IMG_F77_TYPE 
#define IMG_SHORT_C_TYPE
#define IMG_FULL_C_TYPE float
#include "imgTmp2Gen.h"

/*  Byte */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE b
#define IMG_SHORT_C_TYPE B
#define IMG_FULL_C_TYPE signed char
#include "imgTmp2Gen.h"

/*  Unsigned Byte */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE ub
#define IMG_SHORT_C_TYPE UB
#define IMG_FULL_C_TYPE unsigned char
#include "imgTmp2Gen.h"

/*  Word */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE w
#define IMG_SHORT_C_TYPE S
#define IMG_FULL_C_TYPE short int
#include "imgTmp2Gen.h"

/*  Unsigned word */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE uw
#define IMG_SHORT_C_TYPE US
#define IMG_FULL_C_TYPE unsigned short 
#include "imgTmp2Gen.h"

/*  Integer */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE i
#define IMG_SHORT_C_TYPE I
#define IMG_FULL_C_TYPE int
#include "imgTmp2Gen.h"

/*  Real */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE r
#define IMG_SHORT_C_TYPE F
#define IMG_FULL_C_TYPE float
#include "imgTmp2Gen.h"

/*  Double precision */
#undef IMG_F77_TYPE
#undef IMG_SHORT_C_TYPE
#undef IMG_FULL_C_TYPE

#define IMG_F77_TYPE d
#define IMG_SHORT_C_TYPE D
#define IMG_FULL_C_TYPE double 
#include "imgTmp2Gen.h"

/* $Id$ */
