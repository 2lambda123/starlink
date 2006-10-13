/*
*+
*  Name:
*     smf_deepcopy_smfHead

*  Purpose:
*     Copy all elements of a smfHead structure

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     new = smf_deepcopy_smfHead( const smfHead *old, int * status );

*  Arguments:
*     old = const smfHead* (Given)
*        Pointer to smfHead to be copied
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Return Value:
*     smf_deepcopy_smfHead = smfHead*
*        Pointer to newly created smfHead. NULL on error.

*  Description:
*     This function copies all information from an existing smfHead
*     structure and all the internal structures to a new smfHead
*     structure.

*  Notes:
*     - Free this memory using smf_close_file, via a smfData structure.
*     - Can be freed with a smf_free if header resources are freed first.

*  Authors:
*     Tim Jenness (TIMJ)
*     Andy Gibb (UBC)
*     David Berry (DSB)
*     {enter_new_authors_here}

*  History:
*     2006-03-23 (AGG):
*        Initial version.
*     2006-03-24 (AGG):
*        Trap NULL allsc2heads
*     2006-07-26 (TIMJ):
*        sc2head no longer used. Use JCMTState instead.
*     2006-07-28 (TIMJ):
*        Add support for tswcs.
*     2006-06-31 (TIMJ):
*        Add instrument and fplane*
*        make sure memcpy is protected. Some tidy up.
*     2006-08-02 (TIMJ):
*        The new smfHead is not a clone.
*     2006-10-02 (DSB):
*        Add detpos.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2006 Particle Physics and Astronomy Research
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

/* System includes */
#include <stdlib.h>
#include <string.h>

/* Starlink includes */
#include "sae_par.h"
#include "mers.h"
#include "ndf.h"

/* SMURF routines */
#include "jcmt/state.h"
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"

#define FUNC_NAME "smf_deepcopy_smfHead"

smfHead *
smf_deepcopy_smfHead( const smfHead *old, int * status ) {

  smfHead *new = NULL;   /* New Header */
  dim_t nframes = 0;
  dim_t curframe = 0;
  JCMTState *allState = NULL;
  AstFitsChan *fitshdr = NULL;
  AstFrameSet *tswcs = NULL;
  AstFrameSet *wcs = NULL;
  inst_t instrument = INST__NONE;
  unsigned int ndet = 0;
  double *fplanex = NULL;
  double *fplaney = NULL;
  double *detpos = NULL;

  if (*status != SAI__OK) return NULL;

  /* Copy elements */
  nframes = old->nframes;
  curframe = old->curframe;

  if (old->fitshdr) fitshdr = astCopy(old->fitshdr);

  if (old->wcs) wcs = astCopy(old->wcs);
  if (old->tswcs) tswcs = astCopy(old->tswcs);

  if (old->instrument) instrument = old->instrument;

  /* Only allocate space for allState if we have a non-NULL input
     allState */
  if ( old->allState != NULL) {
    allState = smf_malloc( nframes, sizeof(*allState), 0, status);
    if ( allState == NULL) {
      /* Status should be bad from smf_malloc */
      if (*status == SAI__OK) *status = SAI__ERROR;
      errRep(FUNC_NAME,"Unable to allocate memory for allState", status);
    } else {
      memcpy( allState, old->allState, nframes*sizeof(*allState) );
    }
  }

  /* need to allocate focal plane offsets */
  if (old->ndet > 0 && old->fplanex && old->fplaney) {
    ndet = old->ndet;
    fplanex = smf_malloc( ndet, sizeof(*fplanex), 0, status );
    if (fplanex) memcpy( fplanex, old->fplanex, ndet*sizeof(*fplanex) );

    fplaney = smf_malloc( ndet, sizeof(*fplaney), 0, status );
    if (fplaney) memcpy( fplaney, old->fplaney, ndet*sizeof(*fplaney) );
  } 

  /* need to allocate detector positions */
  if (old->ndet > 0 && old->nframes > 0 && old->detpos) {
    ndet = old->ndet;
    nframes = old->nframes;
    detpos = smf_malloc( 2*ndet*nframes, sizeof(*detpos), 0, status );
    if (detpos) memcpy( detpos, old->detpos, 2*ndet*nframes*sizeof(*detpos) );
  } 

  /* Insert elements into new smfHead */
  new = smf_construct_smfHead( new, instrument, wcs, tswcs, fitshdr,
			       allState, curframe,
			       nframes, ndet, fplanex, fplaney, detpos,
                               old->dpazel, status );

  /* see isCloned to 0 since we have allocated this memory */
  if (new) new->isCloned = 0;

  /* let people know where things are going wrong */
  if (*status != SAI__OK) {
    errRep( " ", FUNC_NAME ": error deep copying a smfHead", status );
  }

  /* this could be NULL */
  return new;
}
