      SUBROUTINE KPG1_GDQPC( X1, X2, Y1, Y2, XM, YM, STATUS )
*+
*  Name:
*     KPG1_GDQPC

*  Purpose:
*     Return the extent of the current picture.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_GDQPC( X1, X2, Y1, Y2, XM, YM, STATUS )

*  Description:
*     This routine makes the current PGPLOT bviewport and window match
*     the current AGI picture, and returns the extent of the picture in 
*     AGI world co-ordinates and physical coordinates (metres).

*  Arguments:
*     X1 = REAL (Returned)
*        The X world coordinate of the bottom left corner.
*     Y1 = REAL (Returned)
*        The Y world coordinate of the bottom left corner.
*     X2 = REAL (Returned)
*        The X world coordinate of the top right corner.
*     Y2 = REAL (Returned)
*        The Y world coordinate of the top right corner.
*     XM = REAL (Returned)
*        The extent of the Y axis in metres.
*     YM = REAL (Returned)
*        The extent of the Y axis in metres.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  The PGPLOT interface to the AGI library should be opened before
*     calling this routine.  
*     -  The PGPLOT viewport corresponds to the current AGI picture
*     on exit.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     2-MAR-1998 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Returned:
      REAL X1
      REAL X2
      REAL Y1
      REAL Y2
      REAL XM
      REAL YM

*  Status:
      INTEGER STATUS               ! Global status

*  Initialise safe values for returned variables.
      X1 = 0.0
      X2 = 1.0
      Y1 = 0.0
      Y2 = 1.0
      XM = 1.0
      YM = 1.0
*.

*  Check the inherited status. 
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Set the PGPLOT viewport form the current picture.
      CALL AGP_NVIEW( .FALSE., STATUS )
      IF( STATUS .EQ. SAI__OK ) THEN

*  Get the bounds of the picture in millimetres, and convert to metres.
         CALL PGQVP( 2, X1, X2, Y1, Y2 )
         XM = ( X2 - X1 )/1000.0
         YM = ( Y2 - Y1 )/1000.0

*  Get its bounds in world coordinates.
         CALL PGQWIN( X1, X2, Y1, Y2 )
      END IF

      END
