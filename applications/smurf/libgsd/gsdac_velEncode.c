/*
*+
*  Name:
*     gsdac_velEncode.c

*  Purpose:
*     Routine to encode contents of LSRFLG.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     gsdac_velEncode ( const char *vframe, const char *vdef, 
                        int *LSRFlg, int *status )

*  Arguments:
*     vframe = const char* (Given)
*        Velocity reference frame
*     vdef = const char* (Given)
*        Velocity definition code
*     LSRFlg = int* (Given and Returned)
*        LSR flag
*     status = int* (Given and Returned)
*        Pointer to global status.  

*  Description:
*    Encodes contents of LSRFLG given velocity frame and velocity law
*    used to observe data: Must be consistent with longstanding usage.
*
*    The assumption is that the LO frequency offsets were made to 
*    bring a souce *at velocity VRAD* in the nominated frame to the
*    centre of the spectrum.
*
*    C version of specx routine velencode.f

*  Authors:
*     J.Balfour (UBC)
*     {enter_new_authors_here}

*  History :
*     2008-02-26 (JB):
*        Original

*  Copyright:
*     Copyright (C) 2008 Science and Technology Facilities Council.
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
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     Many of the values are currently kludged with defaults.
*     These are indicated by //k.
*-
*/

/* Standard includes */
#include <string.h>
#include <ctype.h>

/* Starlink includes */
#include "sae_par.h"

/* SMURF includes */
#include "gsdac.h"
#include "smurf_par.h"

#define FUNC_NAME "gsdac_velEncode.c"

void gsdac_velEncode ( const char *vframe, const char *vdef, 
                       int *LSRFlg, int *status )

{

  /* Local variables */
  int cmp;                    /* string comparison */
  int i;                      /* index for vdef */
  int j;                      /* index for vframe */
  int k;                      /* loop counter */
  char upper[3];              /* uppercase string */
  char *vdefs[4] = { "", "RAD", "OPT", "REL" };
  char *vframes[7] = { "", "TOPO", "LSR", "HELI", "GEO", "BARY", "TELL" };

  /* Check inherited status */
  if ( *status != SAI__OK ) return;

  /* Get the first three characters of the GSD velocity def'n
     in uppercase. */
  strncpy ( upper, vdef, 3 );

  for ( k = 0; k < 3; k++ ) {
    upper[k] = toupper ( upper[k] );
  }

  /* Find the corresponding vdefs index. */
  i = 1;
  while ( i <= 3 && ( strncmp ( upper, vdefs[i], 3 ) != 0 ) ) {
    i++;
  }

  if ( i > 3 ) {
    msgOut ( FUNC_NAME, 
             "Did not understand velocity definition string, assuming RADIO.", 
             status );
    i = 1;
  }


  /* Get the first three characters of the GSD velocity frame
     in uppercase. */
  strncpy ( upper, vframe, 3 );

  for ( k = 0; k < 3; k++ ) {
    upper[k] = toupper ( upper[k] );
  }

  /* Find the corresponding vframes index. */
  j = 1;
  while ( j <= 6 && ( strncmp ( upper, vframes[j], 3 ) != 0 ) ) {
    j++;
  }

  /* Equate BARYCENTRIC with GEOCENTRIC. */
  if ( j == 5 ) j = 4; 

  /* Equsate TELLURIC with TOPOCENTRIC. */
  if ( j == 6 ) j = 1;  

  if ( j > 6 ) {
    msgOut ( FUNC_NAME, 
             "Did not understand velocity frame string, assuming LSR.", 
             status );
    j = 2;
  } 

  /* Calculate the LSRFlg. */
  *LSRFlg = 16 * ( i - 1 ) + ( j - 1 ); 

}
