#if !defined( GRP_INCLUDED )  /* Include this file only once */
#define GRP_INCLUDED
/*
*+
*  Name:
*     grp.h

*  Purpose:
*     Define the C interface to the GRP library.

*  Description:
*     This module defines the C interface to the functions of the GRP
*     library. The file grp.c contains C wrappers for the Fortran 
*     GRP routines.

*  Notes:
*     - Given the size of the GRP library, providing a complete C
*     interface is probably not worth the effort. Instead, I suggest that 
*     people who want to use GRP from C extend this file (and
*     grp.c) to include any functions which they need but which are
*     not already included.

*  Authors:
*     DSB: David .S. Berry (UCLan)
*     TIMJ: Tim Jenness (JAC, Hawaii)

*  History:
*     30-SEP-2005 (DSB):
*        Original version.
*     03-NOV-2005 (TIMJ):
*        Use enum for constants rather than #define.
*        Use an opaque struct for the C interface rather than the bare
*        int.
*     24-JAN-2006 (TIMJ):
*        Add grpInfoi
*     26-JAN-2005 (TIMJ):
*        grpInfoI back to grpInfoi after populist revolt. (and to be
*        consistent with other Starlink wrappers).
*     24-FEB-2006 (TIMJ):
*        Add grpInfoc
*     26-FEB-2006 (TIMJ):
*        Add grpGrpex
*     25-JUN-2006 (TIMJ):
*        Add grpCopy.
*     07-AUG-2006 (TIMJ):
*        GRP__NOID should not be publicly visible from C.
*        Use a NULL pointer instead.
*     8-AUG-2006 (DSB):
*        Add grpIndex
*     20-NOV-2006 (DSB):
*        Add grpSetcs
*     6-JUL-2006 (DSB):
*        Use "const Grp *" pointers for group parameters that are not
*        changed by the changed by the called function.
*     25-OCT-2006 (DSB):
*        Add grpSetsz

*  Copyright:
*     Copyright (C) 2005-2006 Particle Physics and Astronomy Research Council.
*     Copyright (C) 2007 Science & Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
*     MA 02111-1307, USA

*-
*/

/* We need CNF to define Fortran */

#include <f77.h>

/* size_t */
#include <stddef.h>

/* Public Constants */
/* ---------------- */

#define GRP__NOID NULL

/* Note that GRP__NOIDs role in C is to use a NULL pointer. */

/* Maximum length of a group expression. */
enum { GRP__SZGEX  = 255 };

/* Length of a name within a group. */
enum { GRP__SZNAM  = 255 };

/* Max. length of a group type */
enum { GRP__SZTYP  = 80 };

/* Max. length of a file name. */
enum { GRP__SZFNM  = 256 };

/* Max. number of groups which can be used simultaneously. */
enum { GRP__MAXG  = 500 };

/* Type definitions for GRP C interface */
/* ------------------------------------ */

/* The contents of the Grp struct are hidden in grp1.h in order to
   make it difficult for application code to use the structure. Here we
  just provide a forward reference to the structure. */
#ifndef grpINTERNAL
typedef struct Grp Grp;
#endif

/* Public function prototypes */
/* -------------------------- */
Grp * grpCopy( const Grp *, int, int, int, int * );
void grpDelet( Grp **, int * );
void grpGrpex( const char *, const Grp *, Grp *, int *, int *, int *, int * );
void grpGrpsz( const Grp *, int *, int * );
void grpGet( const Grp *, int, int, char *const *, int, int * );
void grpInfoc( const Grp *, int , const char *, char *, size_t, int * );
void grpInfoi( const Grp *, int, const char *, int *, int * );
Grp *grpNew( const char *, int * );
void grpPut1( Grp *, const char *, int, int * );
void grpValid( const Grp *, int *, int * );
void grpIndex( const char *, const Grp *, int, int *, int * );
void grpSetcs( Grp *, int, int * );
void grpSetsz( Grp *, int, int * );

/* Semi-Public function prototypes: For Fortran interface wrappers only */
/* -------------------------------------------------------------------- */
Grp *grpFree( Grp *, int * );
Grp *grpF2C( F77_INTEGER_TYPE, int * );
F77_INTEGER_TYPE grpC2F( const Grp *, int * );



#endif
