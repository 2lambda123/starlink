#include "sae_par.h"
#include "ndf.h"
#include "ast.h"
#include "kaplibs.h"

void kpg1Asndf( int indf, int ndim, int *dim, int *lbnd, int *ubnd,
                AstFrameSet **iwcs, int *status ){
/*
*  Name:
*     kpg1Asndf

*  Purpose:
*     Create a FrameSet containing NDF-special Frames with given bounds.

*  Language:
*     C.

*  Invocation:
*     void kpg1Asndf( int indf, int ndim, int *dim, int *lbnd, int *ubnd,
*                     AstFrameSet **iwcs, int *status )

*  Description:
*     This function creates a FrameSet containing the NDF-special Frames,
*     GRID, PIXEL, FRACTION and AXIS, appropriate to an NDF with the
*     supplied dimensionality and pixel index bounds. Optionally, AXIS
*     information can be propagated from a supplied NDF.

*  Arguments:
*     indf
*        An NDF from which to propagate AXIS information. May be NDF__NOID,
*        in which case the AXIS Frame in the returned FrameSet will describe
*        the default AXIS coordinate system (i.e. pixel coords).
*     ndim
*        The number of pixel axes in the modified FrameSet.
*     dim
*        The indices within INDF corresponding to each of the required
*        ndim axes.
*     lbnd
*        The lower pixel index bounds in the modified FrameSet.
*     ubnd
*        The upper pixel index bounds in the modified FrameSet.
*     iwcs
*        Address at which to return a pointer to a new FrameSet holding
*        GRID, FRACTION, PIXEL and AXIS Frames describing the supplied
*        NDF bounds, plus AXIS information from the supplied NDF.
*     status
*        The inherited status.

*  Notes:
*     -  The function kpg1Asndf8 is equivalent to this function but uses
*     type "hdsdim" for the "lbnd" and "ubnd" arguments.

*  Copyright:
*     Copyright (C) 2010 Science & Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either Version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
*     02110-1301, USA.

*  Authors:
*     DSB: David Berry (JAC, Hawaii)
*     MJC: Malcolm J. Currie (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     22-FEB-2010 (DSB):
*        Original version.
*     19-AUG-2010 (DSB):
*        Added DIM argument.
*     2012 April 18 (MJC):
*        Limit axis copying to existing axes.
*     4-OCT-2019 (DSB):
*        Changed to be a thin wrapper round kpg1Asndf8.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*/

/* Local Variables: */
   int i;
   hdsdim lbnd8[ NDF__MXDIM ];
   hdsdim ubnd8[ NDF__MXDIM ];

/* Copy the supplied "int" values into local "hdsdim" arrays. */
   for( i = 0; i < ndim; i++ ){
      lbnd8[ i ] = lbnd[ i ];
      ubnd8[ i ] = ubnd[ i ];
   }

/* Call the 8-byte version of this routine. */
   kpg1Asndf8( indf, ndim, dim, lbnd8, ubnd8, iwcs, status );
}
