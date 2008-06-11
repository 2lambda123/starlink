/*
*+
*  Name:
*     smf_filter_edge

*  Purpose:
*     Apply a hard low- or high-pass edge to a smfFiler at given frequency

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     smf_filter_edge( smfFilter *filt, double f, int lowpass, int *status );

*  Arguments:
*     filt = smfFilter * (Given and Returned)
*        Pointer to smfFilter to be modified
*     f = double (Given)
*        Frequency of the edge in Hz
*     highpass = int (Given)
*        Set flag if edge is low-pass. Otherwise high-pass is assumed.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Return Value:

*  Description:
*     This function applies a hard low- or high-pass cut at the specified
*     edge frequency. The power at all frequencies below (or above) this
*     edge are set to zero if highpass is 0 (or non-zero). The conversion
*     of the frequency to a discrete bin in the filter is accomplished by
*     rounding. The range of frequencies set to 0 include the bin corresponding
*     to the edge frequency. This function will operate on either real or
*     complex-valued filters, and will not alter the data type. Bad status is
*     set if filt is NULL, or the filter is 0 length. If filt->buf is NULL it
*     is first initialized by calling smf_filter_ident (type=real).

*  Notes:

*  Authors:
*     Ed Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2008-06-11 (EC):
*        Initial version
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2006 Particle Physics and Astronomy Research
*     Council. University of British Columbia. All Rights Reserved.

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

/* System includes */
#include <stdlib.h>
#include <string.h>
#include <math.h>

/* Starlink includes */
#include "sae_par.h"
#include "mers.h"
#include "ndf.h"
#include "fftw3.h"

/* SMURF routines */
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"

#define FUNC_NAME "smf_filter_edge"

void smf_filter_edge( smfFilter *filt, double f, int lowpass, int *status ) {
  void *base=NULL;      /* Pointer to start of memory to be zero'd */    
  size_t iedge;         /* Index corresponding to the edge frequency */
  size_t len;           /* Length of memory to be zero'd */
  size_t bperel;        /* Size of array element in bytes */

  if (*status != SAI__OK) return;

  if( !filt ) {
    *status = SAI__ERROR;
    errRep( FUNC_NAME, "NULL smfFilter supplied.", status );
    return;
  }

  /* If filt->buf is NULL, create a real identity filter first */
  if( !filt->buf ) {
    smf_filter_ident( filt, 0, status );
    if( *status != SAI__OK ) return;
  }

  if( f < 0 ) {
    *status = SAI__ERROR;
    msgSetd("F",f);
    errRep( FUNC_NAME, "Filter edge ^F Hz cannot be < 0.", status );
    return;
  }

  /* Calculate offset of edge frequency in filter */
  iedge = (size_t) round( f/filt->df ); 

  if( iedge >= filt->dim ) {
    /* Bad status if edge above Nyquist frequency */
    *status = SAI__ERROR;
    msgSetd("F",f);
    errRep( FUNC_NAME, "Filter edge ^F is > Nyquist", status );
    return;
  }

  /* Size of array element */
  if( filt->isComplex ) bperel = sizeof(fftw_complex);
  else bperel = sizeof(double);

  /* Since we're zero'ing a continuous piece of memory, just use memset */
  if( lowpass ) { /* Zero frequencies beyond edge */
    base = filt->buf + iedge*bperel;
    len = (filt->dim - iedge - 1)*bperel;
  } else {        /* Zero frequencies from 0 to edge */
    base = filt->buf;
    len = iedge*bperel + 1;
  }

  memset( base, 0, len );

}
