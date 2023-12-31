/*
*+
*  Name:
*     nanten.h

*  Purpose:
*     Include file defining NANTEN interface to SMURF

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Header file

*  Authors:
*     TIMJ: Tim Jenness (Cornell)
*     {enter_new_authors_here}

*  History:
*     2014-04-01 (TIMJ):
*        Initial version
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2014 Cornell University
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 3 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
*     MA 02110-1301, USA.

*  Bugs:
*     {note_any_bugs_here}
*-
*/

#ifndef NANTEN_DEFINED
#define NANTEN_DEFINED

#include "mers.h"
#include "ast.h"
#include "fitsio.h"

/* If we're not using GNU C, elide __attribute__ */
#ifndef __GNUC__
#  define  __attribute__(x)  /*NOTHING*/
#endif

/* Data types */

/* Data associated with a single receptor at a single time-slice */

typedef struct {
  const char * recepname; /* Name of the receptor */
  double offx;     /* longitude offset from base position */
  double offy;     /* latitude offset from base position */
  double tsys;     /* System temperature */
  double trx;      /* Receiver temperature */
  double inttime;  /* Integration time in seconds */
  double ifpower;  /* IF power */
} NantenSpecHdr;


/* API */

void
nanten_fill_acsis_hdr( AstFitsChan * nantenhdr, AstFitsChan * acsishdr, int * status );

#endif
