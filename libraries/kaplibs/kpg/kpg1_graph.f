      SUBROUTINE KPG1_GRAPH( N, X, Y, NSIGMA, YSIGMA, XLAB, YLAB, TTL,
     :                       XSYM, YSYM, MODE, NULL, XL, XR, YB, YT, 
     :                       APP, QUIET, LMODE, IPLOT, STATUS )
*+
*  Name:
*     KPG1_GRAPH

*  Purpose:
*     Draws a line graph.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_GRAPH( N, X, Y, NSIGMA, YSIGMA, XLAB, YLAB, TTL, XSYM,
*                      YSYM, MODE, NULL, XL, XR, YB, YT, APP, QUIET, 
*                      LMODE, IPLOT, STATUS )

*  Description:
*     Opens a graphics device and draws a graph displaying a supplied 
*     set of points. Each point is defined by an X and Y value, plus an 
*     optional error bar. An AST Plot is returned so that the calling 
*     application can add further graphics to the plot if needed. When 
*     complete, the calling application should annul the Plot, and close 
*     the workstation:
*
*       CALL AST_ANNUL( IPLOT, STATUS )
*       CALL AGP_DEASS( 'DEVICE', .FALSE., STATUS )

*  Environment Parameters:
*     Various envirnment parameter names are used by this routine,
*     to encourage uniformity in parameter naming, and behaviour.
*     See KPG1_GRPHW for details.

*  Arguments:
*     N = INTEGER (Given)
*        No. of points
*     X( N ) = REAL (Given)
*        X value at each point.
*     Y( N ) = REAL (Given)
*        Y value at each point.
*     NSIGMA = REAL (Given)
*        Controls the length of the vertical error bars. A value of zero
*        suppresses error bars. Otherwise error bars are drawn which extend 
*        by from Y - NSIGMA*YSIGMA to Y + NSIGMA*YSIGMA.
*     YSIGMA( N ) = REAL (Given)
*        The standard deviation associated with each Y value.
*     XLAB = CHARACTER * ( * ) (Given)
*        A default label for the X axis. Only used if the user does not
*        supply an alternative. Trailing spaces are ignored.
*     YLAB = CHARACTER * ( * ) (Given)
*        A default label for the Y axis. Only used if the user does not
*        supply an alternative. Trailing spaces are ignored.
*     TTL = CHARACTER * ( * ) (Given)
*        A default title for the plot. Only used if the user does not
*        supply an alternative.
*     XSYM = CHARACTER * ( * ) (Given)
*        The default symbol for the horizontal axis. Only used if the user 
*        does not supply an alternative. This is not displayed on the
*        screen, but will be stored with the Plot in the AGI database and 
*        (for instance) used by CURSOR as axis symbols when displaying the 
*        cursor positions on the screen.
*     YSYM = CHARACTER * ( * ) (Given)
*        The default symbol for the vertical axis. Only used if the user 
*        does not supply an alternative. This is not displayed on the
*        screen, but will be stored with the Plot in the AGI database and 
*        (for instance) used by CURSOR as axis symbols when displaying the 
*        cursor positions on the screen.
*     MODE = INTEGER (Given)
*        Determines the way in which the data points are represented:
*            1 - A "staircase" histogram, in which each horizontal line is
*                centred on the X position.
*            2 - The points are joined by straight lines.
*            3 - A marker is placed at each point.
*            4 - (not used)
*            5 - A "chain" in which each point is marker by a marker and also 
*                join by straight lines to its neighbouring points.
*     NULL = LOGICAL (Given)
*        If .TRUE., then the user may supply a null (!) value for most of the
*        parameters accessed by this routine to indicate that nothing is to
*        be plotted. In this case, no error is returned. Otherwise, a
*        PAR__NULL error status is returned if a null value is supplied.
*     XL = REAL (Given)
*        The default value for the XLEFT parameter. If VAL__BADR is
*        supplied, the minimum of the X values is used (plus a small
*        margin).
*     XR = REAL (Given)
*        The default value for the XRIGHT parameter. If VAL__BADR is
*        supplied, the maximum of the X values is used (plus a small
*        margin).
*     YB = REAL (Given)
*        The default value for the YBOT parameter. If VAL__BADR is
*        supplied, the minimum of the low end of the Y error bars is 
*        used (plus a small margin).
*     YT = REAL (Given)
*        The default value for the YTOP parameter. If VAL__BADR is
*        supplied, the maximum of the high end of the Y error bars is 
*        used (plus a small margin).
*     APP = CHARACTER * ( * ) (Given)
*        The name of the application in the form "<package>_<application>".
*        E.g. "KAPPA_NORMALIZE".
*     QUIET = LOGICAL (Given)
*        If .FALSE., a message is displayed indicating the number of
*        points which were plotted. If .TRUE., nothing is displayed on
*        the alpha screen.
*     LMODE = LOGICAL (Given)
*        If .TRUE., then the user is given the chance to specify the
*        default vertical bounds for the plot using parameter LMODE. If 
*        .FALSE., the supplied bounds (YB, YT ) are used, and the 
*        eqivalent of "Extended" LMODE is used for any bounds which are 
*        not supplied.
*     IPLOT = INTEGER (Returned)
*        The AST Plot used to do the drawing.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - If an error occurs, or if no graphics is produced because the
*     user supplied a null value for a parameter, IPLOT is returned equal
*     to AST__NULL, and PGPLOT is shut down.

*  Copyright:
*     Copyright (C) 1999, 2004 Central Laboratory of the Research Councils.
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
*     DSB: D.S. Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     17-JUN-1999 (DSB):
*        Original version.
*     1-OCT-1999 (DSB):
*        Added argument LMODE. 
*     2004 September 1 (TIMJ):
*        Use CNF_PVAL
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function

*  Arguments Given:
      INTEGER N
      REAL X( N )
      REAL Y( N )
      REAL NSIGMA
      REAL YSIGMA( N )
      CHARACTER XLAB*(*)
      CHARACTER YLAB*(*)
      CHARACTER TTL*(*)
      CHARACTER XSYM*(*)
      CHARACTER YSYM*(*)
      INTEGER MODE
      LOGICAL NULL
      REAL XL
      REAL XR
      REAL YB
      REAL YT
      CHARACTER APP*(*)
      LOGICAL QUIET
      LOGICAL LMODE

*  Arguments Returned:
      INTEGER IPLOT

*  Status:
      INTEGER STATUS          ! Global status

*  Local Variables:
      INTEGER IPW1
      INTEGER IPW2
      INTEGER IPW3
*.

*  Check inherited global status.
      IF( STATUS .NE. SAI__OK ) RETURN

*  Allocate the required work space.
      CALL PSX_CALLOC( N, '_DOUBLE', IPW1, STATUS )
      CALL PSX_CALLOC( N, '_DOUBLE', IPW2, STATUS )

      IF( NSIGMA .GT. 0 ) THEN
         CALL PSX_CALLOC( 2*N, '_DOUBLE', IPW3, STATUS )
      ELSE
         IPW3 = IPW1 
      END IF

*  Draw the graph.
      CALL KPG1_GRPHW( N, X, Y, NSIGMA, YSIGMA, XLAB, YLAB, TTL,
     :                 XSYM, YSYM, MODE, NULL, XL, XR, YB, YT, APP, 
     :                 QUIET, LMODE, %VAL( CNF_PVAL( IPW1 ) ), 
     :                 %VAL( CNF_PVAL( IPW2 ) ),
     :                 %VAL( CNF_PVAL( IPW3 ) ), IPLOT, STATUS )

*  Free the work space.
      CALL PSX_FREE( IPW1, STATUS )
      CALL PSX_FREE( IPW2, STATUS )
      IF( NSIGMA .GT. 0 ) CALL PSX_FREE( IPW3, STATUS )

      END
