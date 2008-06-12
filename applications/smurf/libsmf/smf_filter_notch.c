/*
*+
*  Name:
*     smf_filter_notch

*  Purpose:
*     Apply N hard-edged notch filters to a smfFilter

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     smf_filter_notch( smfFilter *filt, const double *f_low, 
*                       const double *f_high, size_t n, int *status );

*  Arguments:
*     filt = smfFilter * (Given and Returned)
*        Pointer to smfFilter to be modified
*     f_low = double* (Given)
*        Array of n lower frequency edges (Hz) for the notches
*     f_high = double* (Given)
*        Array of n upper frequency edges (Hz) for the notches
*     n = size_t (Given)
*        Number of notches in the filter (elements in f_low/f_high)
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Return Value:

*  Description:
*     This function applies n hard-edged notch files to a
*     smfFilter. The power at all frequencies in the ranges f_low[i] to
*     f_hi[i] (inclusive) are set to 0. The conversion of frequencies
*     to discrete bins in the filter is accomplished by rounding. This
*     function will operate on either real or complex-valued filters,
*     and will not alter the data type. Bad status is set if filt is
*     NULL, or the filter is 0 length. If filt->buf is NULL it is
*     first initialized by calling smf_filter_ident (type=real).

*  Notes:

*  Authors:
*     Ed Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2008-06-11 (EC):
*        Initial version
*     2008-06-12 (EC):
*        -Switch to split real/imaginary arrays for smfFilter
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

#define FUNC_NAME "smf_filter_notch"

void smf_filter_notch( smfFilter *filt, const double *f_low, 
                       const double *f_high, int n, int *status ) {

  size_t base;          /* Index to start of memory to be zero'd */    
  size_t bperel;        /* Size of array element in bytes */
  size_t i;             /* Loop counter */
  size_t iedge_high;    /* Index corresponding to lower edge frequency */
  size_t iedge_low;     /* Index corresponding to upper edge frequency */
  size_t len;           /* Length of memory to be zero'd */

  if (*status != SAI__OK) return;

  if( !n ) return;

  if( !filt ) {
    *status = SAI__ERROR;
    errRep( FUNC_NAME, "NULL smfFilter supplied.", status );
    return;
  }

  if( !f_low || !f_high ) {
    *status = SAI__ERROR;
    errRep( FUNC_NAME, "NULL notch frequency arrays supplied", status );
    return;
  }

  /* If filt->real is NULL, create a real identity filter first */
  if( !filt->real ) {
    smf_filter_ident( filt, 0, status );
    if( *status != SAI__OK ) return;
  }

  /* Loop over notches */
  for( i=0; (*status == SAI__OK) && i<n; i++ ) {
    /* Calculate edge offsets for notch, checking for reversed inputs */
    if( f_high[i] > f_low[i] ) {
      iedge_low = (size_t) round( f_low[i]/filt->df ); 
      iedge_high = (size_t) round( f_high[i]/filt->df ); 
    } else {
      iedge_low = (size_t) round( f_high[i]/filt->df ); 
      iedge_high = (size_t) round( f_low[i]/filt->df ); 
    }
    
    /* Check for valid ranges */
    if( iedge_low < 0 ) {
      /* No negative frequencies allowed */
      *status = SAI__ERROR;
      msgSetd("F", (f_low[i]<f_high[i]) ? f_low[i]:f_high[i]);
      errRep( FUNC_NAME, "Filter edge ^F Hz cannot be < 0.", status );
    }

    if( iedge_low >= filt->dim ) {
      /* Notch is above Nyquist frequency. Generate bad status */
      *status = SAI__ERROR;
      errRep( FUNC_NAME, "Notch filter is completely above Nyquist", status );
    } else if( iedge_high >= filt->dim ) {
      /* Only upper edge of notch > Nyquist. Set to Nyquist */
      iedge_high = filt->dim-1;
    }

    if( *status == SAI__OK ) {
      /* Since we're zero'ing a continuous piece of memory, just use memset */

      len = iedge_high - iedge_low + 1;

      memset( ((void *) filt->real) + iedge_low*sizeof(*filt->real), 0, 
              len*sizeof(*filt->real) );
      if( filt->isComplex ) {
        memset( ((void *) filt->imag) + iedge_low*sizeof(*filt->imag), 0, 
                len*sizeof(*filt->imag) );
      }
    }
  }

}
