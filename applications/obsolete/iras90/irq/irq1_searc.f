      SUBROUTINE IRQ1_SEARC( LOCS, QNAME, FIXED, VALUE, BIT, COMMNT,
     :                       SLOT, STATUS )
*+
*  Name:
*     IRQ1_SEARC

*  Purpose:
*     Search for a given quality name.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ1_SEARC( LOCS, QNAME, FIXED, VALUE, BIT, COMMNT,
*                      SLOT, STATUS )

*  Description:
*     The supplied name is compared with each name stored in the QUAL
*     array until a match is found or the last used slot is reached.
*     If the name is not found, an error is reported and STATUS returned
*     equal to IRQ__NOQNM.

*  Arguments:
*     LOCS( 5 ) = CHARACTER * ( * ) (Given)
*        A set of 5 HDS locators. LOCS( 1 ) locates a temporary
*        structure holding a cloned NDF identifier. LOCS(2) locates the
*        QUAL array. LOCS(3) locates the LAST_USED value, holding the
*        index of the last used slot in the QUAL array. LOCS(4) locates
*        the NFREE value, holding the number of free slots in the QUAL
*        array. LOCS(5) locates the FREE array, which contains a stack
*        of the NFREE slot indices corresponding to free slots. This
*        stack is accessed in a "First-In-Last-Out" method.
*     QNAME = CHARACTER * ( * ) (Given)
*        The quality name to search for.
*     FIXED = LOGICAL (Returned)
*        True if all or none of the pixels hold the quality. False is
*        some do and some don't.
*     VALUE = LOGICAL (Returned)
*        If FIXED is true and VALUE is true, then the quality is held
*        by all pixels by default.  If FIXED is true and VALUE is
*        false, then the quality is held by no pixels. If FIXED is
*        false, then VALUE is indeterminate.
*     BIT = INTEGER (Returned)
*        If FIXED is false, then this gives the bit number within the
*        QUALITY component which corresponds with the quality name. If
*        FIXED is true, then BIT is indeterminate. The least significant
*        bit is called bit 1 (not bit 0).
*     COMMNT = CHARACTER * ( * ) (Returned)
*        A descriptive comment stored with the name.
*     SLOT = INTEGER (Returned)
*        The index at which the name is stored in the QUAL array.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     26-JUL-1991 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Arguments Given:
      CHARACTER LOCS(5)*(*)
      CHARACTER QNAME*(*)

*  Arguments Returned:
      LOGICAL FIXED
      LOGICAL VALUE
      INTEGER BIT
      CHARACTER COMMNT*(*)
      INTEGER SLOT

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER NAME*(IRQ__SZQNM) ! The name stored in the current slot.
      LOGICAL THERE              ! True if the name is defined.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Find the slot containing the specified name.
      CALL IRQ1_CHECK( LOCS, QNAME, THERE, SLOT, STATUS )

*  If the name was found, get the other associated information.
      IF( THERE ) THEN
         CALL IRQ1_GET( LOCS, SLOT, NAME, FIXED, VALUE, BIT, COMMNT,
     :                  STATUS )

*  If the name was not found, report an error.
      ELSE
         STATUS = IRQ__NOQNM
         CALL MSG_SETC( 'QN', QNAME )
         CALL ERR_REP( 'IRQ1_SEARC_ERR1',
     :                 'IRQ1_SEARC: Quality name ^QN not found.',
     :                 STATUS )
      END IF

      END
