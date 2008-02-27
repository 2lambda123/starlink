/*
*+
*  Name:
*     smf_subtract_poly

*  Purpose:
*     Low-level polynomial subtraction routine

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     smf_subtract_poly( smfData **data, int rel, int *status ) 

*  Arguments:
*     data = smfData** (Given and Returned)
*        Pointer to input data struct
*     rel = int (Given)
*        Integer flag to denote whether the polynomial is subtracted
*        relative to the first value (as for 1/f drifts)
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This is the main routine implementing the subtraction of a
*     polynomial from the data. The polynomial is previously
*     independently fitted to the timestream for each detector. The
*     polynomial coefficients are retrieved from the input
*     smfData. The routine returns immediately if there is no
*     polynomial extension.
*
*     The parameter rel is used to specify whether the polynomial is
*     evaluated relative to the value for the first frame as would be
*     desired for subtracting drifts in the absolute bolometer level.

*  Notes:
*     - It is assumed that the polynomial is a function of the
*       timeslice index and not of a physical quantity (i.e. time).

*  Authors:
*     Andy Gibb (UBC)
*     {enter_new_authors_here}

*  History:
*     2006-02-17 (AGG):
*        Initial test version
*     2006-04-21 (AGG):
*        Add history check, and update history if routine successful
*     2008-02-19 (AGG):
*        Minor comment/documentation changes, use size_t
*     2008-02-20 (AGG):
*        Swap loop order to gain speed increase
*     2008-02-26 (AGG):
*        Add rel parameter to denote whether to subtract changes
*        relative to first time slice
*     2008-02-27 (AGG):
*        Don't subtract from bad values
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2006-2008 University of British Columbia. All
*     Rights Reserved.

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

/* Standard includes */
#include <stdio.h>

/* Starlink includes */
#include "sae_par.h"
#include "ast.h"
#include "mers.h"
#include "msg_par.h"
#include "prm_par.h"

/* SMURF includes */
#include "smf.h"
#include "smurf_par.h"
#include "smurf_typ.h"

/* Simple default string for errRep */
#define FUNC_NAME "smf_subtract_poly"

void smf_subtract_poly(smfData *data, int rel, int *status) {

  /* Local variables */
  double baseline = 0.0;      /* Baseline level to be subtracted */
  double *firstframe = NULL;  /* Pointer to array containing first frame data */
  size_t i;                   /* Bolometer index loop counter */
  size_t j;                   /* Timeslice index loop counter */
  double jay;                 /* Double-precision version of j */
  size_t k;                   /* Coefficient index loop counter */
  size_t nbol;                /* Number of bolometers */
  size_t ncoeff = 0;          /* Number of polynomial coefficients */
  size_t nframes;             /* Number of time slices */
  double *outdata = NULL;     /* Pointer to output data array */
  double *poly = NULL;        /* Pointer to polynomial coefficents */

  /* Check status */
  if (*status != SAI__OK) return;

  /* Return if this has already been done */
  if ( smf_history_check( data, FUNC_NAME, status) ) return;

  /* Retrieve polynomial data */
  ncoeff = data->ncoeff;
  poly = data->poly;

  /* Check they're non NULL */
  if ( (ncoeff == 0)  || (poly == NULL) ) {
    msgOutif(MSG__VERB," ", "No polynomial coefficients present", status);
    return;
  }

  /* Data array */
  outdata = (data->pntr)[0];

  /* Calculate the number of bolometers and retrieve number of coefficients */
  nbol = (data->dims)[0] * (data->dims)[1];
  nframes = (data->dims)[2];

  /* Allocate memory for one frame of data, initialize to zero */
  firstframe = smf_malloc( nbol, sizeof(double), 1, status );
  if ( firstframe == NULL ) {
    *status = SAI__ERROR;
    goto CLEANUP;
  }

  /* Store the fitted value for the first frame if the offset is to be
     subtracted */
  if ( rel == 1 ) {
    for (i=0; i<nbol; i++) {
      firstframe[i] = poly[i];
    }
  }

  /* Loop over the timeslices for this bolometer */
  for (j=0; j<nframes; j++) {
    jay = (double)j; /* Cast outside the loop over bolometers */

    /* Loop over the number of bolometers */
    for (i=0; i<nbol; i++) {
      /* Construct the polynomial for this bolometer - the first two
	 terms are trivial and are determined manually. This is
	 quicker than calling pow() unnecessarily. */
      if ( outdata[i + nbol*j] != VAL__BADD ) {
	baseline = -firstframe[i];
	for (k=0; k<ncoeff; k++) {
	  if ( k==0 ) {
	    baseline += poly[i];
	  } else if ( k==1 ) {
	    baseline +=  jay*poly[i+nbol];
	  } else {
	    baseline += poly[i + nbol*k] * pow(jay, (double)k);
	  }
	}
	outdata[i + nbol*j] -= baseline;
      }
    }

  }
  /* Store polynomial-subtracted data */
  (data->pntr)[0] = outdata;

 CLEANUP:
  smf_free( firstframe, status );
  /* Write history entry */
  if ( *status == SAI__OK ) {
    smf_history_add( data, FUNC_NAME, 
		       "Polynomial subtraction successful", status);
  } else {
    errRep(FUNC_NAME, "Error: status set bad. Possible programming error.", 
	   status);
  }

}
