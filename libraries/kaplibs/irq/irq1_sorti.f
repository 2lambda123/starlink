      SUBROUTINE IRQ1_SORTI( SIZE, DATA, STATUS )
*+
*  Name:
*     IRQ1_SORTI

*  Purpose:
*     Sorts integers into ascending order.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ1_SORTI( SIZE, DATA, STATUS )

*  Description:
*     Uses a simple "Bubble Sort" method.

*  Arguments:
*     SIZE = INTEGER (Given)
*        Number of integers to sort.
*     DATA( SIZE ) = INTEGER (Given and Returned)
*        Integers to be sorted. On exit, they are sorted so that the
*        smallest value occurs at DATA(1) and the largest at DATA(SIZE).
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     30-JUL-1991 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      INTEGER SIZE

*  Arguments Given and Returned:
      INTEGER DATA( SIZE )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER   ADJEL            ! The element adjacent to the current
                                 ! element.
      LOGICAL   DONE             ! True when the elements of array DATA
                                 ! are in increasing order.
      INTEGER   ELEMNT           ! The current element of the array
                                 ! being checked for correct order.
      INTEGER   LASTEL           ! Points to the last element of the
                                 ! array which needs to be checked for
                                 ! being in order.
      INTEGER   TMP              ! Temporary storage.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialize local variables.
      LASTEL = SIZE
      DONE = .FALSE.

*  Loop until data is in correct order.
      DO WHILE( .NOT.DONE )

*  On each pass through the data the highest number gets 'washed' down
*  to the end of the array, therefore it is not neccessary to check the
*  previously last element because it is known to be in the right order.
         LASTEL = LASTEL - 1

*  Go through all the data considering adjacent pairs. If a pair is in
*  the wrong order swap them round.
         DONE = .TRUE.
         DO ELEMNT = 1, LASTEL
            ADJEL = ELEMNT + 1
            IF( DATA( ELEMNT ) .GT. DATA( ADJEL ) ) THEN
               TMP = DATA( ELEMNT )
               DATA( ELEMNT ) = DATA( ADJEL )
               DATA( ADJEL ) = TMP
               DONE = .FALSE.
            ENDIF
         ENDDO

*  Loop round for next pass through data.
      ENDDO

      END
