      SUBROUTINE CCG1_IS4D( ORDDAT, ANCDAT, NENT, STATUS )
*+
*  Name:
*     CCG1_IS4D

*  Purpose:
*     To sort the list of data orddat into increasing order, also sorts
*     the ancillary data ANCDAT correspondingly.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCG1_IS4D( ORDDAT, ANCDAT, NENT, STATUS )

*  Description:
*     The routine uses an insert sort method. This has proven itself
*     the quickest for sorting small sets of data lots of times, as in
*     image stacking using ordered statistics. The method looks at the
*     second value, compares this with the first if swaps if necessary,
*     then it looks at the third, looks at the previous values swaps
*     with the lowest (or not at all) and so on until all values have
*     been passed. It is fast (for the case above ) simply because of
*     the very few lines of operation. The sort is extended to the
*     ancillary data ANCDAT, this maintains is correspondence with the
*     ORDDAT dataset on exit.

*  Arguments:
*     ORDDAT( NENT ) = <COMM> (Given and Returned)
*        The data to order. On output it contains the data in increasing
*        order.
*     ANCDAT( NENT ) = <COMM> (Given and Returned)
*        A list of data associated with ORDDAT which needs to retain its
*        correspondence with the items in ORDDAT.
*     NENT = INTEGER (Given)
*        The number of entries in ORDDAT.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1998 Central Laboratory of the Research Councils

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     5-APR-1991 (PDRAPER):
*        Original version.
*     30-MAY-1991 (PDRAPER):
*        Added ANCDAT stuff, note ANCDAT is integer.
*     9-JUL-1992 (PDRAPER):
*        Changed to <COMM> ANCDAT and renamed ccg1_is4
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      INTEGER NENT

*  Arguments Given and Returned:
      DOUBLE PRECISION ORDDAT( NENT )
      DOUBLE PRECISION ANCDAT( NENT )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      DOUBLE PRECISION VAL1      ! Dummy
      DOUBLE PRECISION VAL2      ! Dummy
      INTEGER I, J               ! Loop variables

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Look at all values starting from 2 inserting after the first largest
*  value.
      DO 1 I = 2, NENT

*  Store the current value (on the bottom).
         VAL1 = ORDDAT( I )
         VAL2 = ANCDAT( I )

*  Look at all values above this one on the stack.
         DO 2 J = I - 1, 1, -1
            IF( VAL1 .GT. ORDDAT( J ) ) GO TO 3

*  Move values up one to make room for next value (VAL or ORRDAT(J)
*  which ever greater).
            ORDDAT( J + 1 ) = ORDDAT( J )
            ANCDAT( J + 1 ) = ANCDAT( J )
 2       CONTINUE

*  Nothing bigger put this one on the top.
         J = 0

*  Arrive directly here if have found one bigger, put this value below
*  it.
 3       CONTINUE

*  Insert val below first value greater than it, or put on top if none
*  bigger.
         ORDDAT( J + 1 ) = VAL1
         ANCDAT( J + 1 ) = VAL2

 1    CONTINUE
      END
