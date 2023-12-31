#include "atl.h"
#include "ast.h"
#include "mers.h"
#include "sae_par.h"

void atlAddWcsAxis( AstFrameSet *wcs, AstMapping *map, AstFrame *frm,
                    int *lbnd, int *ubnd, int *status ){
/*
*+
*  Name:
*     atlAddWcsAxis

*  Purpose:
*     Add one or more axes to an NDFs WCS FrameSet.

*  Language:
*     C.

*  Invocation:
*     void atlAddWcsAxis(  AstFrameSet *wcs, AstMapping *map, AstFrame *frm,
*                          int *lbnd, int *ubnd, int *status )

*  Description:
*     This function adds one or more new axes to all the Frames in an NDF
*     WCS FrameSet. Frames that are known to be NDF-special (e.g. GRID,
*     AXIS, PIXEL and FRACTION) are expanded to include a number of extra
*     appropriate axes equal to the Nin attribute of the supplied Mapping.
*     All other Frames in the FrameSet are replaced by CmpFrames holding the
*     original Frame and the supplied Frame. These new axes are connected to
*     the new GRID axes using the supplied Mapping.

*  Arguments:
*     wcs
*        A pointer to a FrameSet that is to be used as the WCS FrameSet in
*        an NDF. This imposes the restriction that the base Frame must
*        have Domain GRID.
*     map
*        A pointer to a Mapping. The forward transformation should transform
*        the new GRID axes into the new WCS axes.
*     frm
*        A pointer to a Frame defining the new WCS axes.
*     lbnd
*        An array holding the lower pixel index bounds on the new axes.
*        If a NULL pointer is supplied, a value of 1 is assumed for all
*        the new axes.
*     ubnd
*        An array holding the upper pixel index bounds on the new axes.
*        If a NULL pointer is supplied, any FRACTION Frame in the
*        supplied FrameSet is removed.
*     status
*        Pointer to the global status variable.

*  Notes:
*     - The new axes are appended to the end of the existing axes, so the
*     axis indices associated with the new axes will extend from "nold+1"
*     to "nold+nnew", where "nold" is the number of axes in the original
*     Frame, and "nnew" is the number of new axes.
*     - An error will be reported if the Nout attribute of "map" is
*     different to the Naxes attribute of "frm".

*  Copyright:
*     Copyright (C) 2009 Science & Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*     02110-1301, USA

*  Authors:
*     DSB: David S. Berry  (JAC, HAwaii)
*     {enter_new_authors_here}

*  History:
*     29-OCT-2009 (DSB):
*        Original version.
*     20-NOV-2009 (DSB):
*        Treat all NDF Frames (PIXEL, AXIS and FRACTION in addition to
*        GRID) as special. Requires new arguments "lbnd" and "ubnd".
*     28-SEP-2020 (DSB):
*        Changed to be a thin wrapper around atlAddWcsAxis8.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*+
*/

/* Local Variables: */
   int64_t lbnd8[ ATL__MXDIM ];
   int64_t ubnd8[ ATL__MXDIM ];
   int64_t *pl;
   int64_t *pu;
   int i;

/* Check inherited status */
   if( *status != SAI__OK ) return;

/* Convert the supplied 4-byte integer values to 8-byte integers. */
   if( lbnd ) {
      for( i = 0; i < ATL__MXDIM; i++ ){
         lbnd8[ i ] = lbnd[ i ];
      }
      pl = lbnd8;
   } else {
      pl = NULL;
   }

   if( ubnd ) {
      for( i = 0; i < ATL__MXDIM; i++ ){
         ubnd8[ i ] = ubnd[ i ];
      }
      pu = ubnd8;
   } else {
      pu = NULL;
   }


/* Call the 8-byte version of this function. */
   atlAddWcsAxis8( wcs, map, frm, pl, pu, status );
}

