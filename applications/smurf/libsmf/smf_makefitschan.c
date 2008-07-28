/*
*+
*  Name:
*     smf_makefitschan

*  Purpose:
*     Put cards into a FitsChan describing a tan plane projection.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     smf_makefitschan( const char *system, double crpix[2], double crval[2], 
*                       double cdelt[2], double crota2, AstFitsChan *fc, 
*                       int *status );

*  Arguments:
*     system = char * (Given)
*        Specifies the celestial coordinate system. It should be a 
*        valid value for the System attribute of an AST SkyFrame.
*     crpix = double[ 2 ] (Given)
*        Reference pixel associated with position crval[].
*     crval = double[ 2 ] (Given)
*        The longitude and latitude to use as the tangent point in the output 
*        cube, in radians in the system specified by "system". 
*     cdelt = double[ 2 ] (Given)
*        Spatial pixel sizes for the output cube at the tangent point, in 
*        arcsec.
*     crota2 = double (Given)
*        The angle from north through east to the second pixel axis, in
*        degrees.
*     fc = AstFitsChan * (Given)
*        A pointer to a FitsCHan in which to put the FITS-WCS cards
*        describing the tan plane projection.
*     status = int * (Given and Returned)
*        Pointer to inherited status.

*  Description:
*     This function creates a set of FITS-WCS header cards describing a
*     tan plane projection and puts them into a supplied AST FitsChan.
*     Celestial north is at the position angle specified by "crota", and the
*     tangent point is placed at grid cords (0,0). Note, the observatory
*     position is not recorded in the FitsChan.

*  Authors:
*     David S Berry (JAC, UCLan)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     25-SEP-2006 (DSB):
*        Initial version.
*     1-NOV-2006 (DSB):
*        New interface to allow more control of the projection parameters.
*     28-JUL-2008 (TIMJ):
*        Add CRPIX argument.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2008 Science and Technology Facilities Council.
*     Copyright (C) 2006 Particle Physics and Astronomy Research Council.
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
#include <string.h>
#include <math.h>

/* Starlink includes */
#include "ast.h"
#include "mers.h"
#include "sae_par.h"

/* SMURF includes */
#include "libsmf/smf.h"

#define FUNC_NAME "smf_makefitschan"

void smf_makefitschan( const char *system, double crpix[2], double crval[2],
                       double cdelt[2], double crota2, AstFitsChan *fc,
                       int *status ){


/* Local Variables */
   int i;
   int ncard;

/* Check inherited status */
   if( *status != SAI__OK ) return;

/* Ensure the FitsChan is empty. */
   astClear( fc, "Card" );
   ncard = astGetI( fc, "NCard" );
   for( i = 0; i < ncard; i++ ) astDelFits( fc );

/* Pixel coords of reference point. */
   astSetFitsF( fc, "CRPIX1", crpix[0], NULL, 0 );
   astSetFitsF( fc, "CRPIX2", crpix[1], NULL, 0 );

/* World coords of reference point. */
   astSetFitsF( fc, "CRVAL1", crval[ 0 ]*AST__DR2D, NULL, 0 );
   astSetFitsF( fc, "CRVAL2", crval[ 1 ]*AST__DR2D, NULL, 0 );

/* Axis rotation. */
   astSetFitsF( fc, "CROTA2", crota2, NULL, 0 );

/* Pixel size. AZEL is right-handed. */
   if( !strcmp( system, "AZEL" ) ) {
      astSetFitsF( fc, "CDELT1", fabs(cdelt[ 0 ])/3600.0, NULL, 0 );
   } else {
      astSetFitsF( fc, "CDELT1", -fabs(cdelt[ 0 ])/3600.0, NULL, 0 );
   }
   astSetFitsF( fc, "CDELT2", fabs(cdelt[ 1 ])/3600.0, NULL, 0 );

/* Axis types and reference frame. */
   if( !strcmp( system, "ICRS" ) ||
       !strcmp( system, "GAPPT" ) ||
       !strcmp( system, "FK4-NO-E" ) ||
       !strcmp( system, "FK5" ) ||
       !strcmp( system, "FK4" ) ) {

      astSetFitsS( fc, "CTYPE1", "RA---TAN", NULL, 0 );
      astSetFitsS( fc, "CTYPE2", "DEC--TAN", NULL, 0 );
      astSetFitsS( fc, "RADESYS", system, NULL, 0 );

   } else if( !strcmp( system, "ECLIPTIC" ) ) {
      astSetFitsS( fc, "CTYPE1", "ELON-TAN", NULL, 0 );
      astSetFitsS( fc, "CTYPE2", "ELAT-TAN", NULL, 0 );

   } else if( !strcmp( system, "GALACTIC" ) ) {
      astSetFitsS( fc, "CTYPE1", "GLON-TAN", NULL, 0 );
      astSetFitsS( fc, "CTYPE2", "GLAT-TAN", NULL, 0 );

   } else if( !strcmp( system, "AZEL" ) ) {
      astSetFitsS( fc, "CTYPE1", "AZ---TAN", NULL, 0 );
      astSetFitsS( fc, "CTYPE2", "EL---TAN", NULL, 0 );

   } else if( *status == SAI__OK ) {
      *status = SAI__ERROR;
      msgSetc( "SYS", system );
      errRep( FUNC_NAME, "Unsupported sky coordinate system \"^SYS\".",
              status );
   }
}
