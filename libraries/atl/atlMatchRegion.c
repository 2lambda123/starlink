#include "f77.h"
#include "ast.h"
#include "atl.h"
#include "ndf.h"
#include "mers.h"
#include "sae_par.h"

AstRegion *atlMatchRegion( AstRegion *region, AstFrame *frame, int *status ) {
/*
*+
*  Name:
*     atlMatchRegion 

*  Purpose:
*     Ensure the axes in a Region match those in a Frame.

*  Invocation:
*     AstRegion *atlMatchRegion( AstRegion *region, AstFrame *frame, 
*                                int *status )

*  Description:
*     This function checks for matching axes in a supplied Region and 
*     Frame. If possible, a new region is created containing a set of 
*     axes that correspond in number and type (but not necessarily in
*     specific attributes) to those in the supplied Frame. This means 
*     that astConvert should be able to find a Mapping between the 
*     supplied Frame and the returned Region. Note, the order of the 
*     axes in the returned Region may not match those in the Frame, but 
*     astConvert will be able to identify any required re-ordering. 
*
*     If it is not possible to find a matching Region (for instance, if
*     there are no axes in common between the supplied Region and Frame), 
*     an error is reported.

*  Arguments:
*     region
*        An AST pointer for the Region to be modified.
*     frame
*        An AST pointer for a Frame to be matched.
*     status
*        The global status.

*  Returned Value:
*      An AST pointer for a Region that matches Frame, or NULL if
*      an error occurs.

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
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     DSB: David S. Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     30-SEP-2009 (DSB):
*        Original version.
*     {enter_further_changes_here}
*-
*/

/* Local Variables: */ 
   AstMapping *junk;          /* Unused Mapping */
   AstNullRegion *ereg;       /* Unbounded Region spanning extra Frame axes */
   AstRegion *result;         /* Returned Region pointer */
   AstFrame *ureg;            /* Supplied Region with no non-Frame axes */
   int *old_status;           /* Original status pointer */
   int axes[ NDF__MXDIM ];    /* Region axis index for each Frame axis */
   int i;                     /* Loop index */
   int nax;                   /* No. of axes in supplied Frame */
   int nrpick;                /* No. of of region axes to pick */
   int nwpick;                /* No. of of Frame axes to pick */
   int raxes[ NDF__MXDIM ];   /* Indicies of Region axes to pick */
   int waxes[ NDF__MXDIM ];   /* Indicies of Frame axes to pick */

/* Initialise */
   result = NULL;

/* Check the inherited status. */
   if( *status != SAI__OK ) return result;

/* Make AST use the supplied status variable. */
   old_status = astWatch( status );

/* Begin an AST context. */
   astBegin;

/* Try to get a region in which the axes are the same in number and type 
   (but not necessarily order - astConvert should be called to take 
   account of any difference in axis order) as those spanned by the 
   supplied Frame. First find which (if any) Region axis corresponds 
   to each axis in the Frame. */
   astMatchAxes( region, frame, axes );

/* Get a list (WAXES) of the Frame axis indices that have no corresponding 
   region axis. Also get a list (RAXES) of the Region axes indicies that 
   have corresponding axes in the Frame. */
   nax = astGetI( frame, "Naxes" );
   nwpick = 0;
   nrpick = 0;
   for( i = 0; i < nax; i++ ) {
      if( axes[ i ] == 0 ) {
         waxes[ nwpick++ ] = i + 1;
      } else {
         raxes[ nrpick++ ] = axes[ i ];
      }
   }

/* Report an error if none of the region axes are present in the Frame. */
   if( nrpick == 0 && *status == SAI__OK ) {
      *status = SAI__ERROR;
      errRep( " ", "The supplied Region has no axes in common with "
              "the current WCS Frame in the NDF.", status );
   }

/* Pick the axes from the Region that are also in the Frame. This
   should produce a cut-down version of the supplied Region. */
   ureg = astPickAxes( region, nrpick, raxes, &junk );

/* If the resulting Object is not a Region, we cannot match the region
   and the Frame. */
   if( ! astIsARegion( ureg ) && *status == SAI__OK ) {
      *status = SAI__ERROR;
      errRep( " ", "Cannot pick the current WCS axes from the supplied "
              "Region.", status );
   }

/* If any Frame axes have no corresponding axis in the region, get an
   unbounded region (a negated NullRegion) in a Frame that spans the 
   Frame axes that have no corresponding axes in the Region. */
   if( nwpick > 0 ) {
      ereg = astNullRegion( astPickAxes( frame, nwpick, waxes, &junk ), 
                            NULL, "Negated=1" );

/* Join this region in parallel with the region containing the Frame axes 
   picked from the supplied region. */
      result = (AstRegion *) astPrism( (AstRegion *) ureg, ereg, " " );

/* If there are no extra Frame axes, just use the cut-down supplied region. */
   } else {
      result = astClone( ureg );
   }

/* Export the returned Region. */
   astExport( result );

/* End the AST context. */
   astEnd;

/* Make AST use its original status variable. */
   astWatch( old_status );

/* Return the result. */
   return result;
}

/* The fortran interface */

F77_SUBROUTINE(atl_matchregion)( INTEGER(REGION), INTEGER(FRAME),
                                 INTEGER(NEWREG), INTEGER(STATUS ) ){
/*
*+
*  Name:
*     ATL_MATCHREGION

*  Purpose:
*     Ensure the axes in a Region match those in a Frame.

*  Invocation:
*     CALL ATL_MATCHREGION( REGION, FRAME, NEWREG, STATUS )

*  Description:
*     This routine checks for matching axes in a supplied Region and 
*     Frame. If possible, a new region is created containing a set of 
*     axes that correspond in number and type (but not necessarily in
*     specific attributes) to those in the supplied Frame. This means 
*     that AST_CONVERT should be able to find a Mapping between the 
*     supplied Frame and the returned Region. Note, the order of the 
*     axes in the returned Region may not match those in the Frame, 
*     but AST_CONVERT will be able to identify any required re-ordering. 
*
*     If it is not possible to find a matching Region (for instance, if
*     there are no axes in common between the supplied Region and Frame), 
*     an error is reported.

*  Arguments:
*     REGION = INTEGER (Given)
*        An AST pointer for the Region to be modified.
*     FRAME = INTEGER (Given)
*        An AST pointer for a Frame to be matched.
*     NEWREG = INTEGER (Returned)
*        An AST pointer to the returned Region.
*     STATUS = INTEGER (Given and Returned )
*        The global status.

*-
*/
   GENPTR_INTEGER(REGION)
   GENPTR_INTEGER(FRAME)
   GENPTR_INTEGER(NEWREG)
   GENPTR_INTEGER(STATUS)

   *NEWREG = astP2I( atlMatchRegion( astI2P( *REGION ),  astI2P( *FRAME ), 
                                     STATUS ) );
}
