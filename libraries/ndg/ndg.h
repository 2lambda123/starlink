#if !defined( NDG_ADAM_INCLUDED )  /* Include this file only once */
#define NDG_ADAM_INCLUDED
/*
*  Name:
*     ndg_adam.h

*  Purpose:
*     Define the ADAM C interface to the NDG library.

*  Description:
*     This module defines the C interface to the functions of the ADAM NDG
*     library. The file ndg_adam.c contains C wrappers for the Fortran 
*     GRP routines.

*  Notes:
*     - Given the size of the NDg library, providing a complete C
*     interface is probably not worth the effort. Instead, I suggest that 
*     people who want to use NDG from C extend this file (and
*     ndg_adam.c) to include any functions which they need but which are
*     not already included.

*  Authors:
*     DSB: David .S. Berry
*     TIMJ: Tim Jenness (JAC, Hawaii)

*  History:
*     30-SEP-2005 (DSB):
*        Original version.
*     02-NOV-2005 (TIMJ):
*        Copy from grp.h
*     20-DEC-2005 (TIMJ):
*        Add ndgAsexp
*     12-JUL-2006 (TIMJ):
*        Add ndgNdfcr
*     8-AUG-2006 (DSB):
*        Added ndgGtsup
*     2-NOV-2007 (DSB):
*        Added ndgPtprv, ndgBegpv and ndgEndpv.

*  Copyright:
*     Copyright (C) 2005 Particle Physics and Astronomy Research Council.
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

*/

/* Need Grp type definitions */
#include "star/grp.h"

/* Need HDS dim type */
#include "star/hds_types.h"

/* Public function prototypes */
/* -------------------------- */
void ndgAsexp( const char grpexp[], int verb, const Grp *igrp1, Grp **igrp2, int *size, int *flag, int *status );
void ndgAssoc( char *param, int verb, Grp **igrp, int *size, int *flag, int *status );
void ndgCreat( char *param, const Grp *igrp0, Grp **igrp, int *size, int *flag, int *status);
void ndgNdfas( const Grp *igrp, int index, const char mode[], int *indf, int *status );
void ndgNdfcr( const Grp *igrp, int index, const char ftype[], int ndim,
	       const hdsdim lbnd[], const hdsdim ubnd[], int *indf, int *status );
void ndgNdfpr( int indf1, const char clist[], const Grp *igrp, int index, int *indf2, int *status);
void ndgGtsup( const Grp *grp, int i, char const *fields[6], int len, int *status );
void ndgBegpv( int *status );
void ndgEndpv( const char *creator, int *status );
void ndgPtprv( int indf1, int indf2, HDSLoc *more, int isroot, const char *creator, int *status );

#endif
