/*
*+
*  Name:
*     smf_fits_getF

*  Purpose:
*     Obtain a float FITS item value from a header

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     smf_fits_getF( const smfHead * hdr, const char * name, float * result, int * status );

*  Arguments:
*     hdr = const smfHdr* (Given)
*        Header struct. Assumed to contain a FitsChan in the hdr slot
*     name = const char * (Given)
*        Name of the FITS Item to retrieve.
*     result = float * (Returned)
*        Pointer of float to store the result.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This function looks up a FITS header item and stores the result
*     in the variable provided.

*  Authors:
*     Tim Jenness (JAC, Hawaii)
*     Andy Gibb (UBC)
*     {enter_new_authors_here}

*  History:
*     2006-01-11 (AGG):
*        Initial version, copy from smf_fits_getD
*     2006-01-24 (TIMJ):
*        There is no "float" version of astGetFits, so use astGetFitsD
*        and cast the result.
*     2006-07-24 (TIMJ):
*        Fix compiler warning by casting 0.0
*     {enter_further_changes_here}

*  Notes:
*     - Only use this function if you really really need a float
*       rather than a double. Consider using smf_fits_getD and
*       casting the result to float.
*     - See also smf_fits_getI, smf_fits_getS and smf_fits_getD

*  Copyright:
*     Copyright (C) 2005-2006 Particle Physics and Astronomy Research
*     Council. University of British Columbia. All Rights Reserved.

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

/* Starlink includes */
#include "sae_par.h"

/* SMURF includes */
#include "smf.h"
#include "smf_typ.h"

/* Simple default string for errRep */
#define FUNC_NAME "smf_fits_getF"

void smf_fits_getF (const smfHead *hdr, const char * name, float * result, int * status ) {
  double astres;

  if (*status != SAI__OK) return;

  /* Call smf_fits_getD and cast the result. This is allowed since
     AST always uses Double precision rather than single precision */
  smf_fits_getD( hdr, name, &astres, status );

  /* Simply cast the result */
  if (*status == SAI__OK) {
    *result = (float)astres;
  } else {
    *result = (float)0.0;
  }

  return;
}
