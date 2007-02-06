/*
*+
*  Name:
*     smf_construct_smfHead

*  Purpose:
*     Populate a smfHead structure

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     pntr = smf_construct_smfHead( smfHead * tofill, inst_t instrument,
*              AstFrameSet * wcs, AstFrameSet * tswcs,
*              AstFitsChan * fitshdr, const JCMTState * allState,
*              dim_t curframe, unsigned int ndet,
*              const double fplanex[], const double fplaney[],
*              const double detpos[], const char *detname, int dpazel, 
*              int * status );

*  Arguments:
*     tofill = smfHead* (Given)
*        If non-NULL, this is the smfHead that is populated by the remaining
*        arguments. If NULL, the smfHead is malloced.
*     instrument = inst_t (Given)
*        Instrument code. Can be INST__NONE.
*     wcs = AstFrameSet * (Given)
*        Frameset for the world coordinates. The pointer is copied,
*        not the contents.
*     tswcs = AstrFrameSet * (Given)
*        Frameset for the time series world coordinates. The pointer is copied,
*        not the contents.
*     fitshdr = AstFitsChan * (Given)
*        FITS header. The pointer is copied, not the contents.
*     allState = JCMTState* (Given)
*        Pointer to array of time series information for all time slices.
*        Should be at least "curslice" in size. Contents are not copied.
*     curframe = dim_t (Given)
*        Current time index corresponding to the associated WCS. sc2head
*        will be set to this location.
*     nframes = dim_t (Given)
*        Number of frames (timeslices) in data.
*     ndet = unsigned int (Given)
*        Number of positions in fplanex, fplaney arrays. Number of detectors.
*     fplanex = const double[] (Given)
*        X Coordinates of bolometers/receptors in the focal plane (radians)
*     fplanex = const double[] (Given)
*        Y Coordinates of bolometers/receptors in the focal plane (radians)
*     detpos = const double[] (Given)
*        The position of the bolometers/receptors in tracking coordinates, 
*        in radians. This array should have a length of 2*ndet*nframes.
*     detname = const char * (Given)
*        A concatenated list of null-terminated detector names.
*     dpazel = int (Given)
*        If non-zero, then the values in "detpos" are AZEL
*        positions. Otherwise they are TRACKING positions.
*     tsys = const double[] (Given)
*        System temperatures for each receptor
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Return Value:
*     smf_construct_smfHead = smfHead*
*        Pointer to newly created smfHead (NULL on error) or,
*        if "tofill" is non-NULL, the pointer to the supplied struct.

*  Description:
*     This function fills a smfHead structure. Optionally, the smfHead
*     is allocated by this routines.

*  Notes:
*     - AST objects are neither cloned nor copied by this routine.
*       Use astCopy or astClone when calling if reference counts
*       should be incremented.
*     - "state" is set to point into allState[curslice]
*     - allState is not copied. In general the time series information
*       can be copied between headers without being modified. If this
*       memory should be freed by smf_close_file, set the isCloned flag
*       to false.
*     - Free this memory using smf_close_file, via a smfData structure.
*     - Can be freed with a smf_free if header resources are freed first.

*  Authors:
*     Tim Jenness (TIMJ)
*     David Berry (DSB)
*     Andy Gibb (AGG)
*     {enter_new_authors_here}

*  History:
*     2006-01-26 (TIMJ):
*        Initial version.
*     2006-01-27 (TIMJ):
*        Replace sc2head with allsc2heads. sc2head now indexed
*        into allsc2heads.
*     2006-03-23 (AGG):
*        curslice changed to curframe, nframes added
*     2006-07-26 (TIMJ):
*        sc2head no longer used. Use JCMTState instead.
*     2006-07-26 (TIMJ):
*        Add tswcs.
*     2006-07-31 (TIMJ):
*        Add instrument code. Add fplanex and fplaney.
*     2006-10-2 (DSB):
*        Add detpos.
*     2006-11-6 (DSB):
*        Add detname.
*     2007-02-06 (AGG):
*        Add tsys
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

#define FUNC_NAME "smf_construct_smfHead"

smfHead *
smf_construct_smfHead( smfHead * tofill, inst_t instrument,
		       AstFrameSet * wcs, AstFrameSet * tswcs,
		       AstFitsChan * fitshdr,
		       const JCMTState * allState,
		       dim_t curframe, dim_t nframes, unsigned int ndet,
		       const double fplanex[], const double fplaney[],
		       const double detpos[], const char *detname, 
                       int dpazel, const double tsys[], int * status ) {

  smfHead * hdr = NULL;   /* Header components */

  hdr = tofill;
  if (*status != SAI__OK) return hdr;

  if (tofill == NULL) {
    hdr = smf_create_smfHead( status );
  }

  if (*status == SAI__OK) {
    hdr->instrument = instrument;
    hdr->wcs = wcs;
    hdr->wcs = tswcs;
    hdr->fitshdr = fitshdr;
    hdr->curframe = curframe;
    hdr->nframes = nframes;
    hdr->allState = allState;
    hdr->state = &(allState[curframe]);
    hdr->ndet = ndet;
    hdr->fplanex = fplanex;
    hdr->fplaney = fplaney;
    hdr->detpos = detpos;
    hdr->detname = detname;
    hdr->dpazel = dpazel;
    hdr->tsys = tsys;
    hdr->isCloned = 1;
  }

  return hdr;
}
