      SUBROUTINE IRQ1_ANTMP( LOC, STATUS )
*+
*  Name:
*     IRQ1_ANTMP

*  Purpose:
*     Annul a locator to a temporary object, thereby erasing the object.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ1_ANTMP( LOC, STATUS )

*  Description:
*     The routine annuls a locator to a temporary object created by
*     IRQ1_TEMP, thereby causing the associated object to be erased and
*     the file space associated with it to be released. If data are
*     mapped to the object via HDS, then they are first unmapped.

*  Arguments:
*     LOC = CHARACTER * ( * ) (Given and Returned)
*        HDS locator to the temporary object to be annulled. The
*        character variable supplied is reset to a blank string by this
*        routine.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  This routine attempts to execute even if STATUS is set on
*     entry. However, no additional error report is made if it
*     subsequently fails under these circumstances.

*  Algorithm:
*     -  Save the error context on entry.
*     -  Find the parent of the object to be annulled.
*     -  Locate the object within its parent structure.
*     -  Annul the object's locator.
*     -  Erase the object.
*     -  Annul the parent's locator.
*     -  Restore the error context.

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK)
*     DSB: D.S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     19-MAY-1992 (RFWS):
*        Original, derived from the equivalent AIF_ routine.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT__ constants

*  Arguments Given:
      CHARACTER * ( * ) LOC

*  Status:
      INTEGER STATUS             ! Global status

*  Local variables:
      CHARACTER * ( DAT__SZLOC ) LOCP ! Locator to parent object
      CHARACTER * ( DAT__SZNAM ) NAME ! Name of object to be erased
      INTEGER TSTAT              ! Local temporary status variable

*.

*  Save the STATUS value and mark the error stack.
      TSTAT = STATUS
      CALL ERR_MARK

*  Find the temporary object's name.
      STATUS = SAI__OK
      CALL DAT_NAME( LOC, NAME, STATUS )

*  Find its parent.
      LOCP = ' '
      CALL DAT_PAREN( LOC, LOCP, STATUS )

*  Annul the object's locator.
      CALL DAT_ANNUL( LOC, STATUS )
      LOC = ' '

*  Erase the object.
      CALL DAT_ERASE( LOCP, NAME, STATUS )

*  Annul the parent's locator.
      CALL DAT_ANNUL( LOCP, STATUS )
      LOCP = ' '

*  Annul any error if STATUS was previously bad, otherwise let the new
*  error report stand.
      IF ( STATUS .NE. SAI__OK ) THEN
         IF ( TSTAT .NE. SAI__OK ) THEN
            CALL ERR_ANNUL( STATUS )
            STATUS = TSTAT
         END IF
      ELSE
         STATUS = TSTAT
      END IF

*  Release the error stack.
      CALL ERR_RLSE

      END
