/*
*+
*  Name:
*     smf_flatten

*  Purpose:
*     Low-level FLATFIELD implementation

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     SMURF subroutine

*  Invocation:
*     smf_flatten( smfData *data, int *status );

*  Arguments:
*     data = smfData* (Given and Returned)
*        Pointer to a smfData struct
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This subroutine calls the low-level sc2math_flatten subroutine.

*  Authors:
*     Andy Gibb (UBC)
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2005-12-06 (AGG):
*        Initial test version.
*     26-JUL-2006 (TIMJ):
*        Remove sc2store_struct
*     2008-03-10 (AGG):
*        Add check for bad values on output from flatfield routine and
*        set quality to SMF__Q_BADS
*     2008-03-14 (AGG):
*        Check for quality array after flatfield and set if present
*     2010-03-09 (TIMJ):
*        Change type of flatfield method in smfDA
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2010 Science & Technology Facilities Council.
*     Copyright (C) 2005 Particle Physics and Astronomy Research Council.
*     2005-2008 University of British Columbia.
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

#if HAVE_CONFIG_H
#include <config.h>
#endif

/* Standard includes */
#include <string.h>
#include <stdio.h>

/* Starlink includes */
#include "mers.h"
#include "prm_par.h"
#include "sae_par.h"
#include "msg_par.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "libsmf/smf_err.h"

/* SC2DA includes */
#include "sc2da/sc2math.h"

void smf_flatten ( smfData *data, int *status ) {

  smfDA *da = NULL;            /* Pointer to struct containing flatfield info */
  double *dataArr = NULL;      /* Pointer to flatfielded data array */
  size_t i;                    /* Loop counter */
  size_t ndat;                 /* Total number of data points */
  int nboll;                   /* Number of bolometers */
  int nframes;                 /* Number of frames (timeslices) */
  void *pntr[3];               /* Array of pointers for DATA, QUALITY & VARIANCE */
  unsigned char *qual;         /* Pointer to quality array */

  if ( *status != SAI__OK ) return;

  /* Check that we have actually have everything we need */
  da = data->da;
  pntr[0] = (data->pntr)[0];
  dataArr = pntr[0];

  if ( da == NULL ) {
    if ( *status == SAI__OK) {
      *status = SAI__ERROR;
      errRep("smf_flatten", "No flatfield information in data structure", status);
    }
  } else if ( data == NULL ) {
    if ( *status == SAI__OK) {
      *status = SAI__ERROR;
      errRep("smf_flatten", "Null data structure passed to smf_flatten", status);
    }
  } else if ( dataArr == NULL ) {
    if ( *status == SAI__OK) {
      *status = SAI__ERROR;
      errRep("smf_flatten", "Null data array in data structure", status);
    }
  } else {

    /* Calculate the number of bolometer and number of frames (timeslices) */
    nboll = (data->dims)[0]*(data->dims)[1];
    nframes = (data->dims)[2];

    /* Flatfielder */
    sc2math_flatten( nboll, nframes, smf_flat_methstring(da->flatmeth,status), da->nflat, da->flatcal,
		     da->flatpar, dataArr, status);

    /* Update units and title if we have a header */
    smf_set_clabels( "Flatfielded", NULL, SIPREFIX "W", data->hdr, status);

    /* Now check for a QUALITY array */
    qual = (data->pntr)[2];
    if ( qual != NULL ) {
      /* Check for BAD values from flatfield routine and set QUALITY
	 accordingly. Any bad values at this point means that those
	 samples were flagged as such by the DA system and thus should
	 be assigned a quality value of SMF__Q_BADS */
      msgOutif(MSG__DEBUG, "", 
	       "smfData has a valid QUALITY array: setting SMF__Q_BADS flags", 
	       status);
      ndat = nboll * nframes;
      for (i=0; i<ndat; i++) {
	if ( dataArr[i] == VAL__BADD ) {
	  qual[i] = SMF__Q_BADS; /* quality should not be set here so can be lazy */
	}
      }
    } else {
      msgOutif(MSG__DEBUG, "", "smfData has no QUALITY array", status);
    }

  }
}

