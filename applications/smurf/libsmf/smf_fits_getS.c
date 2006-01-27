/*
*+
*  Name:
*     smf_fits_getS

*  Purpose:
*     Obtain a character string FITS item value from a header

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     smf_fits_getS( const smfHead * hdr, const char * name, char * result, 
*                    size_t len, int * status );

*  Arguments:
*     hdr = const smfHdr* (Given)
*        Header struct. Assumed to contain a FitsChan in the hdr slot
*     name = const char * (Given)
*        Name of the FITS Item to retrieve.
*     result = char * (Returned)
*        Pointer to string buffer. To guarantee it is large enough
*        to recieve the result, allocate at least 72 characters.
*     len = size_t (Given)
*        Allocated length of "result" buffer. Including space for NUL.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This function looks up a FITS header item and stores the result
*     in the string variable provided.

*  Authors:
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2005-11-08 (TIMJ):
*        Initial version.
*     2005-11-29 (TIMJ):
*        Indicate consting in prolog
*     2006-01-24 (TIMJ):
*        Create string version from Double.
*     2006-01-26 (TIMJ):
*        Fix silly string copy bug.
*     {enter_further_changes_here}

*  Notes:
*     - if the supplied buffer is too small to receive the string, the
*       result will be truncated and status will be set to SMF__STRUN.
*     - See also smf_fits_getI and smf_fits_getD

*  Copyright:
*     Copyright (C) 2005-2006 Particle Physics and Astronomy Research Council.
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

*  Bugs:
*     {note_any_bugs_here}
*-
*/

/* System includes */
#include <string.h>

/* Starlink includes */
#include "ast.h"
#include "sae_par.h"
#include "mers.h"

/* SMURF includes */
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"

/* Simple default string for errRep */
#define FUNC_NAME "smf_fits_getS"

void smf_fits_getS (const smfHead *hdr, const char * name, char * result, 
		    size_t len, int * status ) {
  char * astres; /* Pointer to AST static buffer */

  /* Set a default value */
  result[0] = '\0';
  
  /* Check entry status */
  if (*status != SAI__OK) return;

  if ( hdr == NULL ) {
    *status = SAI__ERROR;
    errRep( FUNC_NAME,
	    "Supplied hdr is a NULL pointer. Possible programming error.",
	    status);
    return;
  }

  if ( hdr->fitshdr == NULL ) {
    *status = SAI__ERROR;
    errRep( FUNC_NAME,
	    "No FitsChan associated with supplied header. Possible programming error.",
	    status );
    return;
  }

  if ( !astGetFitsS( hdr->fitshdr, name, &astres) ) {
    if ( *status == SAI__OK) {
      *status = SAI__ERROR;
      msgSetc("FITS", name );
      errRep(FUNC_NAME, "Unable to retrieve item ^FITS from header",
	     status);
    }
  }

  /* if status is good, copy the result into the output buffer */
  if (*status == SAI__OK) {
    strncpy( result, astres, len - 1 );
    result[len-1] = '\0'; /* terminate */
    if ( len <= strlen(astres) ) {
      *status = SMF__STRUN;
      msgSetc("FITS", name);
      msgSeti("LN", len - 1 );
      msgSeti("SZ", strlen(astres));
      errRep(FUNC_NAME, "String buffer too small to receive FITS item ^FITS"
	     "(^LN < ^SZ)", status);
    }
  }

  return;
}
