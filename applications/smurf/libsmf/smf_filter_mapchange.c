 /*
*+
*  Name:
*     smf_filter_mapchange

*  Purpose:
*     Remove low frequency changes from the current map.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Library routine

*  Invocation:
*     smf_filter_mapchange( ThrWorkForce *wf, smfDIMMData *dat,
*                           double filt_diff, int *status)

*  Arguments:
*     wf = ThrWorkForce * (Given)
*        Pointer to a pool of worker threads
*     dat = smfDIMMData * (Given)
*        Struct of pointers to information required by model calculation
*     filt_diff = double (Given)
*        The size of the filter to use, in arc-sec. No filtering is done
*        if this is zero.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Form the change in the map since the previous iteration, remove low
*     frequencies from the map change, and then add the remaining high
*     frequency changes back onto the previous map to get the new map. We
*     filter the map change rather than the map itself since the
*     astronomical signal wil be far weaker (compared to the spurious low
*     frequency structures introduced by the iterative process) in the map
*     change than in the map. This means we probably do not need to worry
*     about ringing round sources etc caused by the filtering process.

*  Authors:
*     DSB: David Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     20-AUG-2014 (DSB):
*        Initial Version
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2014 Science and Technology Facilities Council.
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
*     Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
*     MA 02110-1301, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

/* Starlink includes */
#include "mers.h"
#include "ndf.h"
#include "sae_par.h"
#include "star/ndg.h"
#include "prm_par.h"
#include "par_par.h"
#include "star/one.h"

/* SMURF includes */
#include "libsmf/smf.h"

#define FUNC_NAME "smf_filter_mapchange"

void smf_filter_mapchange( ThrWorkForce *wf, smfDIMMData *dat,
                           double filt_diff, int *status) {

/* Local Variables: */
   dim_t i;
   double *change = NULL;
   double *map;
   smfData *filtermap=NULL;
   smfFilter *filt=NULL;

/* Check inherited status. Also check the filter size is non-zero. */
   if( *status != SAI__OK || filt_diff <= 0.0 ) return;

/* Store a pointer to the current map. */
   map = dat->map;

/* Tell the user what is happening. */
   msgOutiff( MSG__DEBUG, "","   high-pass filtering the map-change to "
              "remove features larger than %g arc-sec.", status, filt_diff );

/* Create a smfData to hold the changes in the map. */
   change = astMalloc( dat->msize*sizeof( *change ) );
   filtermap = smf_create_smfData( 0, status );
   if( *status == SAI__OK ) {
      filtermap->isFFT = -1;
      filtermap->dtype = SMF__DOUBLE;
      filtermap->pntr[0] = change;
      filtermap->ndims = 2;
      filtermap->lbnd[0] = dat->lbnd_out[0];
      filtermap->lbnd[1] = dat->lbnd_out[1];
      filtermap->dims[0] = dat->ubnd_out[0]-dat->lbnd_out[0]+1;
      filtermap->dims[1] = dat->ubnd_out[1]-dat->lbnd_out[1]+1;
      filtermap->hdr->wcs = astClone( dat->outfset );

/* Form the map change, setting bad values to 0. */
      for( i = 0; i < dat->msize; i++ ) {
         if( map[ i ] != VAL__BADD && dat->lastmap[ i ] != VAL__BADD ) {
            change[ i ] = map[ i ] - dat->lastmap[ i ];
         } else {
            change[ i ] = 0;
         }
      }

/* Create and apply a sharp-edged high-pass filter to remove large-scale
   structures from the map change image. */
      filt = smf_create_smfFilter( filtermap, status );

      smf_filter2d_edge( filt, 1.0/filt_diff, 0, status );
      smf_filter_execute( wf, filtermap, filt, 0, 0, status );

/* Add the remining high frequencies of the filtered map-change image back
   onto the previous map. */
      for( i = 0; i < dat->msize; i++ ) {
         if( map[ i ] != VAL__BADD && dat->lastmap[ i ] != VAL__BADD ) {
            map[ i ] = change[ i ] + dat->lastmap[ i ];
         } else {
            map[ i ] = VAL__BADD;
         }
      }

/* Unset pointers to avoid freeing them */
      filtermap->pntr[0] = NULL;
   }

/* Free resources. */
   change = astFree( change );
   smf_close_file( wf, &filtermap, status );
   filt = smf_free_smfFilter( filt, status );
}



