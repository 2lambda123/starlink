      SUBROUTINE KPS1_DISTL( IPLOT, STATUS )
*+
*  Name:
*     KPS1_DISTL

*  Purpose:
*     Display a Plot Title without using AST_GRID.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_DISTL( IPLOT, STATUS )

*  Description:
*     This routine display the Plot Title at the top of the area covered
*     by the Plot, but does not draw anything else (e.g. axes, tick
*     marks, borders, labels, etc). It does not need the inverse 
*     transformation from current to base Frame to be defined in the Plot.

*  Arguments:
*     IPLOT = INTEGER (Given)
*       The Plot.
*     STATUS = INTEGER (Given and Returned)
*       The global status value.

*  Copyright:
*     Councils. Copyright (C) 2006 Particle Physics & Astronomy
*     Research Council. All Rights Reserved.

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
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1-JUN-2006 (DSB):
*        Original version.
*     {enter_further_changes_here}

*-

*  Type Definitions:
      IMPLICIT NONE

*  Global Constants:
      INCLUDE 'SAE_PAR'        ! Global SSE definitions
      INCLUDE 'AST_PAR'        ! AST functions and constants

*  Arguments Given:
      INTEGER IPLOT

*  Status:
      INTEGER STATUS

*  Local Variables:
      CHARACTER ATTR( 5 )*6
      CHARACTER SATTR*20
      CHARACTER TATTR*20
      CHARACTER TTL*80
      DOUBLE PRECISION POS( 2 )
      INTEGER I
      INTEGER IAT
      INTEGER IPLOTT
      LOGICAL FULL
      REAL LBND( 2 )
      REAL UBND( 2 )
      REAL UP( 2 )

      DATA ATTR / 'Width', 'Colour', 'Font', 'Size', 'Style' /

*.

*  Check the inherited status.
      IF( STATUS .NE. SAI__OK ) RETURN

*  Do nothing if no Title is to be drawn.
      IF( AST_GETL( IPLOT, 'DrawTitle', STATUS ) ) THEN

*  Otherwise, take a copy of the supplied Plot so that we can modify the
*  Plot attributes, etc, without affecting later behaviour.
         IPLOTT = AST_COPY( IPLOT, STATUS )

*  Ensure no clipping is applied.
         CALL AST_CLIP( IPLOTT, AST__NOFRAME, 0.0D0, 0.0D0, STATUS )

*  Get the Title to be displayed.
         TTL = AST_GETC( IPLOTT, 'Title', STATUS )

*  The Mapping from GRAPHICS coords to the original current Frame may not
*  be defined in both direction, so we set the current Frame to be the 
*  GRAPHICS Frame. 
         CALL AST_SETI( IPLOTT, 'Current', AST_GETI( IPLOTT, 'Base', 
     :                                               STATUS ), 
     :                  STATUS )

*  Draw a border using invisble ink. This sets up the bounding box.
         CALL AST_SETL( IPLOTT, 'Invisible', .TRUE., STATUS )
         FULL = AST_BORDER( IPLOTT, STATUS )
         CALL AST_SETL( IPLOTT, 'Invisible', .FALSE., STATUS )

*  Get the bounding box of the border.
         CALL AST_BOUNDINGBOX( IPLOTT, LBND, UBND, STATUS )

*  Copy the Title graphical style to the Strings graphical style.
         DO I = 1, 5
            TATTR = ' '
            IAT = 0
            CALL CHR_APPND( ATTR( I ), TATTR, IAT )
            CALL CHR_APPND( '(Title)', TATTR, IAT )
            SATTR = ' '
            IAT = 0
            CALL CHR_APPND( ATTR( I ), SATTR, IAT )
            CALL CHR_APPND( '(Strings)', SATTR, IAT )

            CALL AST_SETR( IPLOTT, SATTR, AST_GETR( IPLOTT, TATTR, 
     :                                              STATUS ),
     :                     STATUS )
         END DO   

*  Draw the title centred above the bounding box.
         POS( 1 ) = 0.5*( LBND( 1 ) + UBND( 1 ) )
         POS( 2 ) = UBND( 2 ) + 0.05*( UBND( 2 ) - LBND( 2 ) )
         UP( 1 ) = 0.0
         UP( 2 ) = 1.0
         CALL AST_TEXT( IPLOTT, TTL, POS, UP, 'CB', STATUS )

*  Annul the temporary Plot.
         CALL AST_ANNUL( IPLOTT, STATUS )
      END IF

      END
