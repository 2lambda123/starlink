      SUBROUTINE IRH1_SETI( FIRST, LAST, VALUE, SIZE, ARRAY, STATUS )
*+
*  Name:
*     IRH1_SETI

*  Purpose:
*     Set part of an integer array to a constant value.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRH1_SETI( FIRST, LAST, VALUE, SIZE, ARRAY, STATUS )

*  Description:
*     The given value is written into the given part of the array.

*  Arguments:
*     FIRST = INTEGER (Given)
*        The first array element to be written to.
*     LAST = INTEGER (Given)
*        The last array element to be written to.
*     VALUE = INTEGER (Given)
*        The value to write to the array.
*     SIZE = INTEGER (Given)
*        The total size of the array.
*     ARRAY( SIZE ) = INTEGER (Given and Returned)
*        The array.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     13-JUN-1991 (DSB):
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
      INTEGER FIRST
      INTEGER LAST
      INTEGER VALUE
      INTEGER SIZE

*  Arguments Given and Returned:
      INTEGER ARRAY( SIZE )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I                  ! Loop count.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Write the given value to the given range of the array.
      DO I = MAX( 1, FIRST ), MIN( SIZE, LAST )
         ARRAY( I ) = VALUE
      END DO

      END
* $Id$
