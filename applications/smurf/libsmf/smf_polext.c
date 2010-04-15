/*
*+
*  Name:
*     smf_polext

*  Purpose:
*     Create a POLPACK extension in an output NDF.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     smf_polext( int ondf, double angle, int *status )

*  Arguments:
*     ondf = int (Given)
*        Identifier for the NDF to modify.
*     angle = double (Given)
*        The position angle of the analysed intensity. This is the angle
*        from north in the spatial coordinate system of the output, to
*        the analyser axis. Posotive rotation is in the same sense as
*        rotation from the first spatial pixel axis to the second spatial
*        pixel axis (as required by POLPACK).
*     status = int * (Given and Returned)
*        Pointer to the inherited status.

*  Description:
*     This function creates a POLPACK extension in the supplied NDF.
*     Values are put in the extension that tell POLPACK that the NDF holds
*     linearly analysed intensity, at the specified angle. These are the
*     values needed by the POLPACK:POLCAL task.

*  Authors:
*     David S Berry (JAC, UCLan)
*     {enter_new_authors_here}

*  History:
*     12-OCT-2007 (DSB):
*        Initial version.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2007 Science & Technology Facilities Council.
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

/* Starlink includes */
#include "ast.h"
#include "ndf.h"
#include "star/hds.h"
#include "mers.h"
#include "sae_par.h"
#include "dat_par.h"

/* SMURF includes */
#include "libsmf/smf.h"

void smf_polext( int ondf, double angle, int *status ){

/* Local Variables */
   AstFrame *curfrm = NULL;
   AstFrame *polfrm = NULL;
   AstSkyFrame *template = NULL;
   int perm[ 2 ];
   int icur;
   AstFrameSet *wcs = NULL;
   AstFrameSet *fs = NULL;
   AstMapping *map = NULL;
   HDSLoc *loc = NULL;
   int dummy;

/* Check inherited status, and also check the supplied angle is not bad. */
   if( *status != SAI__OK || angle == AST__BAD ) return;

/* Start an AST context. */
   astBegin;

/* Get a pointer to the WCS FrameSet in the output NDF. */
   ndfGtwcs( ondf, &wcs, status );

/* POLPACK uses the first axis of the WCS Frame with Domain POLANAL as the
   reference direction, so we need to add such a Frame to the WCS FrameSet.
   The "angle" value supplied by the caller is with respect to north in the
   WCS current Frame, so first get a pointer to the current WCS Frame. */
   curfrm = astGetFrame( wcs, AST__CURRENT );

/* The current Frame is 3D, and should contain a SkyFrame. North should
   usually be axis 2 in the 3D Frame, but we make no assumptions here about
   how this axis is connected to the underlying SkyFrame axes. Instead,
   we create a default SkyFrame, permute its axes to make north (latitude)
   the first axis, and then search the 3D current WCS Frame to find a
   Frame that looks like the template. */
   template = astSkyFrame( "MaxAxes=3" );
   perm[ 0 ] = 2;
   perm[ 1 ] = 1;
   astPermAxes( template, perm );
   fs = astFindFrame( curfrm, template, " " );

/* Check a match was found. */
   if( fs ) {

/* The base Frame in the "fs" FrameSet will be identical to "curfrm", and
   the current Frame will be a SkyFrame with axes permuted like "template",
   but will inherit other attributes from "curfrm". This is the Frame we
   will use as the POLANAL Frame. Extract the Mapping and current Frame
   from "fs". */
      map = astGetMapping( fs, AST__BASE, AST__CURRENT );
      polfrm = astGetFrame( fs, AST__CURRENT );

/* Change the Domain to POLANAL. */
      astSet( polfrm, "Domain=POLANAL" );

/* Note the index of the original current Frame in "wcs" so that we can
   re-instate it later. */
      icur = astGetI( wcs, "Current" );

/* Add the POLANAL Frame into the WCS FrameSet using the above Mapping to
   connect it to the original current Frame. */
      astAddFrame( wcs, AST__CURRENT, map, polfrm );

/* Re-instate the original current Frame (astAddFrame changes the current
   Frame). */
      astSetI( wcs, "Current", icur );

/* Save the modified FrameSet back in the output NDF. */
      ndfPtwcs( wcs, ondf, status );

/* Create the empty POLPACK extension. */
      ndfXnew( ondf, "POLPACK", "POLPACK", 0, &dummy, &loc, status );

/* Store the angle from the reference direction (north) to the effective
   analyser axis, measured positive in the same sense as rotation from the
   first to the second pixel axis. */
      ndfXpt0r( angle*AST__DR2D, ondf, "POLPACK", "ANLANG", status );

/* Annul the extension locator.  */
      (void) datAnnul( &loc, status );

/* If the current WCS Frame did not contain a SkyFrame, warn the user. */
   } else {
      ndfMsg( "NDF", ondf );
      msgOut( "", "The WCS current Frame in output NDF ^NDF does not "
              "contain a SkyFrame - no POLPACK extenion can be created.",
              status );
   }

/* End the AST context. */
   astEnd;
}
