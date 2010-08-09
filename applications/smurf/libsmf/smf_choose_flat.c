/*
*+
*  Name:
*     smf_choose_flat

*  Purpose:
*     Decide which flat is relevant

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     void smf_choose_flat( const smfArray *flats, const smfData *indata,
*                            size_t *flatidx, int * status );

*  Arguments:
*     flats = const smfArray* (Given)
*        Set of flatfield observations. Can be NULL.
*     indata = const smfData * (Given)
*        Reference science observation to choose flatfield.
*     flatidx = size_t * (Returned)
*        Index in smfArray for the closest previous (or later)
*        flatfield that could be associated with indata.
*        SMF__BADIDX if none can be found.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Search through the supplied flats to find the closest observations
*     to the supplied reference science observation that is suitable.

*  Notes:
*     Uses the OBSIDSS and SUBARRAY information to associate a flatfield ramp with
*     the science data. Does not yet use discrete flatfields from previous
*     observations. Assumes that the flatfield at the start of the observation
*     is the relevant one but if one can not be find it will use a ramp that
*     immediately follows the sequence.

*  Authors:
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2010-03-15 (TIMJ):
*        Initial version.
*     2010-08-06 (TIMJ):
*        Allow following flatfield ramps to be used.

*  Copyright:
*     Copyright (C) 2010 Science and Technology Facilities Council.
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
#include "prm_par.h"

/* SMURF includes */
#include "libsmf/smf.h"

void smf_choose_flat( const smfArray *flats, const smfData *indata,
                       size_t *flatidx, int * status ) {
  size_t i;          /* loop counter */
  int refseq;        /* Sequence count of input science data */
  sc2ast_subarray_t refsubnum; /* Subarray number of science data */

  *flatidx = SMF__BADIDX;

  if (*status  != SAI__OK) return;
  if (!flats) return;
  if (!smf_validate_smfData( indata, 1, 0, status ) ) return;

  /* get reference sequence counter and subarray number */
  smf_find_seqcount( indata->hdr, &refseq, status );
  smf_find_subarray( indata->hdr, NULL, (size_t)0, &refsubnum, status );

  msgOutiff( MSG__DEBUG, "", "Looking for a flatfield for %s subarray %d (seq=%d)",
             status, indata->hdr->obsidss, refsubnum, refseq);

  /* Loop through all the flats looking for ones that match
     subarray and have an earlier sequence counter. If we only find a
     later sequence we use that but only if it is adjacent.
     Assume that the flatfields are in date order. */
  for (i=0; i< flats->ndat; i++) {
    smfData *thisflat = (flats->sdata)[i];
    sc2ast_subarray_t thissubnum;
    smf_find_subarray( thisflat->hdr, NULL, (size_t)0, &thissubnum, status );

    msgOutiff( MSG__DEBUG, "", "Checking against flatfield %s subarray %d",
               status, thisflat->hdr->obsidss, thissubnum);

    /* see if we even need to look at the obsidss */
    if (thissubnum == refsubnum &&
        strcmp( indata->hdr->obsidss, thisflat->hdr->obsidss ) == 0 ) {
      int thisseq;
      int seqdiff;
      smf_find_seqcount( thisflat->hdr, &thisseq, status );
      seqdiff = refseq - thisseq;

      msgOutiff( MSG__DEBUG, "", "Matching flatfield has sequence count %d cf %d",
                 status, thisseq, refseq );

      if ( seqdiff > 0 ) {
        /* Valid previous flat */
        *flatidx = i;
      } else if (seqdiff < 0 ) {
        /* Valid next flat which we will want to use if we could not
           find a previous match. Only select it if it is from the
           sequence that follows immediately afterwards. */
        if (seqdiff == -1) *flatidx = i;
      } else if (seqdiff == 0) {
        /* should not be possible */
        if (*status == SAI__OK) {
          *status = SAI__ERROR;
          errRep(" ","Should not be possible for flat and science "
                 "observation to have identical sequence counter.", status );
          return;
        }
      }
    }

    /* finish if we have everything */
    if (*flatidx != SMF__BADIDX) break;

  }

  if (*flatidx == SMF__BADIDX) {
    msgOutiff( MSG__VERB, " ","Unable to find any prior flatfield for %s",
               status, indata->hdr->obsidss );
  }

}
