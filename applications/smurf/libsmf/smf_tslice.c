/*
*+
*  Name:
*     smf_tslice

*  Purpose:
*     Retrieve data for a specific time slice

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     smf_tslice( smfData *idata, smfData **tdata, int index, int * status);

*  Arguments:
*     idata = smfData* (Given)
*        Data structure containing time series data.
*        The smfHead item in the structure will be updated to receive
*        the updated FrameSet. In addition, if sc2head is non-null, the
*        contents of hdr->sc2head will be updated for this time slice.
*     tdata = smfData** (Returned)
*        Data structure containing the data for a given time slice 
*     index = int (Given)
*        Index of time slice
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This function is used to copy the data for specified time slice
*     from the supplied data structure into a pointer to a 2-D array
*     containing the bolometer data. The header is set from the input
*     smfData struct, which is assumed to be correct for that time
*     slice (i.e. no cross-checking is carried out). Time slices
*     created this way have the `virtual' flag set.

*  Authors:
*     Andy Gibb (UBC)
*     Tim Jenness (JAC)
*     {enter_new_authors_here}

*  History:
*     2005-12-22 (AGG):
*        Initial version.
*     2006-01-12 (AGG):
*        Use sc2store_headget to set the appropriate header.
*     2006-01-25 (TIMJ):
*        Replace malloc with smf_malloc
*     2006-01-26 (TIMJ):
*        sc2head is now embedded in smfHead
*     2006-01-27 (TIMJ):
*        sc2head is a pointer again!
*     2006-07-26 (TIMJ):
*        sc2head no longer used. Use JCMTState instead.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2005-2006 University of British Columbia &
*     Particle Physics and Astronomy Research Council.
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

/* Starlink includes */
#include "ast.h"
#include "sae_par.h"
#include "mers.h"
#include "star/hds_types.h"

/* Standard includes */
#include <string.h>
#include <stdio.h>

/* SMURF includes */
#include "smf.h"
#include "smf_typ.h"

/* Data Acquisition Includes */
#include "jcmt/state.h"
#include "sc2da/sc2ast.h"
#include "sc2da/sc2store.h"

/* Simple default string for errRep */
#define FUNC_NAME "smf_tslice"

void smf_tslice (const smfData *idata, smfData **tdata, int index, int *status ) {

  smfHead *hdr;               /* Pointer to header struct for output data */
  int i;                      /* Loop counter */
  double *indata;             /* Pointer to input data array */
  void *ipntr[3];             /* Input D, Q and V arrays */
  int npts;                   /* Number of points in a time slice */
  int offset;                 /* Offset int othe time series for the
				 start of the current frame */
  JCMTState *sc2hdr;          /* Pointer to STATE data */
  double *tslicedata;         /* Pointer to output data array */

  /* Allocate space for the tdata struct */
  *tdata = smf_malloc( 1, sizeof( smfData ), 0, status );

  /* Copy the current header */
  hdr = smf_malloc( 1, sizeof( smfHead ), 0, status );
  /* Check we got the memory */
  if ( hdr == NULL) {
    if ( *status == SAI__OK) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "Unable to allocate memory for header", status);
    }
  }
  memcpy( hdr, idata->hdr, sizeof( smfHead ) );
  (*tdata)->hdr = hdr;
  sc2hdr = hdr->state;
  /* Retrieve the header for this time slice */
  sc2store_headget( index, sc2hdr, status);

  /* Set the virtual flag */
  (*tdata)->virtual = 1;

  /* Store number of dimensions */
  (*tdata)->ndims = idata->ndims - 1; 
  ((*tdata)->dims)[0] = (idata->dims)[0];
  ((*tdata)->dims)[1] = (idata->dims)[1];

  npts = ((*tdata)->dims)[0] * ((*tdata)->dims)[1];
  offset = npts * index;

  ipntr[0] = (idata->pntr)[0];

  indata = ipntr[0];

  tslicedata = smf_malloc( npts, sizeof( double ), 0, status );
  /* Check we got the memory */
  if ( tslicedata == NULL) {
    if ( *status == SAI__OK) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "Unable to allocate memory for 2-D timeslice", status);
    }
  }
  
  for (i=0; i<npts; i++) {
    tslicedata[i] = indata[offset + i];
    /*    printf("index = %d, bol = %d, data = %g\n",index,i,tslicedata[i]);*/
  }

  ((*tdata)->pntr)[0] = tslicedata;

}
