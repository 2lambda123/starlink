/*
*+
*  Name:
*     smf_find_subarray

*  Purpose:
*     Determine the subarray name and number

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     smf_find_subarray( const smfHead * hdr, char subarray[],
*                        size_t buflen, int *subnum, int *status );

*  Arguments:
*     hdr = const smfHead * (Given)
*        Header from which to obtain the FITS information
*     subarray = char[] (Given and Returned)
*        Buffer to receive the subarray name. Of size "buflen". Can be
*        NULL.
*     buflen = size_t (Given)
*        Allocate size of "subarray", including nul.
*     subnum = int* (Returned)
*        Pointer to int to contain the subarray number. Can be NULL.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This function reads the FITS header to determine the subarray name
*     and then converts it to a number.
*     
*  Authors:
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2008-07-17 (TIMJ):
*        Initial version.

*  Notes:
*     - Uses sc2ast_name2num
*     - At least one of "subnum" and "subarray" should be non-NULL.

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
*     {note_any_bugs_here}
*-
*/

#include <stdio.h>

/* Starlink includes */
#include "mers.h"
#include "sae_par.h"
#include "star/one.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "sc2da/sc2ast.h"

#define FUNC_NAME "smf_find_subarray"

void smf_find_subarray ( const smfHead * hdr, char subarray[],
                         size_t buflen, int *subnum, int *status ) {
  char buffer[81];  /* for FITS header */

  if (*status != SAI__OK) return;

  if (subnum == NULL && subarray == NULL) {
    *status = SAI__ERROR;
    errRep( " ", FUNC_NAME ": Both 'subnum' and 'subarray' are NULL "
            "(possible programming error)", status);
    return;
  }

  smf_fits_getS( hdr, "SUBARRAY", buffer, sizeof(buffer), status );
  if (subarray) one_strlcpy( subarray, buffer, buflen, status );
  if (subnum) sc2ast_name2num( buffer, subnum, status);
  return;
}
