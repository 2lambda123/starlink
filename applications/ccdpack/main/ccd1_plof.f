      SUBROUTINE CCD1_PLOF( STR1, IRIGHT, STR2, STATUS )
*+
*  Name:
*     CCD1_PLOF

*  Purpose:
*     To place a copy of a string leftwards of a given point into
*     another string.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCD1_PLOF( STR1, IRIGHT, STR2, STATUS )

*  Description:
*     This routine copies STR1 into STR2, starting from the point
*     IRIGHT. STR1 is copied into the region before IRIGHT, ie. leftward
*     from this point. Truncation thus occurs from the left ensuring
*     that the later elements of STR1 are copied into STR2.

*  Arguments:
*     STR1 = CHARACTER * ( * ) (Given)
*        The string to be copied.
*     IRIGHT = INTEGER (Given)
*        The starting point from which elements of STR1 are copied into
*        STR2.
*     STR2 = CHARACTER * ( * ) (Given and Returned)
*        Output string containing the copy of STR1, truncated from the
*        left.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     This routine is used to ensure that the trailing characters of a
*     string are copied in preference to the leading characters.
*     Ie. copying 'disk$scratch:[user]filename' into a string of 20
*     characters gives '...[user]filename' showing the most important
*     elements. Note the later addition of an ellipsis.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     4-JUN-1991 (PDRAPER):
*        Original version.
*     16-SEP-1991 (PDRAPER):
*        Added ellipsis.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      CHARACTER * ( * ) STR1
      INTEGER IRIGHT

*  Arguments Given and Returned:
      CHARACTER * ( * ) STR2

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I
      INTEGER J
      INTEGER IRMOST
      INTEGER LENS1

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Check the IRIGHT value.
      IRMOST = MAX( 1, MIN( IRIGHT, LEN( STR2 ) ) )

*  Find the length of STR1
      LENS1 = LEN( STR1 )

*  Loop from this position to the start of the string copying any
*  character left in STR1.
      J = LENS1
      DO 1 I = IRMOST, 1, -1
         IF ( J .GT. 0 ) THEN
            STR2( I : I ) = STR1( J : J )
         END IF
         J = J - 1
 1    CONTINUE

*  If an ellipsis can be added do so.
      IF ( IRMOST .GT. 4 ) THEN
         STR2( 1 : 3 ) = '...'
      END IF
      END
* $Id$
