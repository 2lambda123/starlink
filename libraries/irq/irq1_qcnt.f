      SUBROUTINE IRQ1_QCNT( BIT, SIZE, QUAL, NSET, NCLR, STATUS )
*+
*  Name:
*     IRQ1_QCNT

*  Purpose:
*     Count the no. of pixels with a specified QUALITY bit set and
*     clear.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ1_QCNT( BIT, SIZE, QUAL, NSET, NCLR, STATUS )

*  Description:
*     The number of pixels for which the specified bit of the QUALITY
*     vector is set, and the number for which it is cleared, are
*     returned.

*  Arguments:
*     BIT = INTEGER (Given)
*        The bit number within the QUALITY component. The least
*        significant bit is called bit 1 (not bit 0).
*     SIZE = INTEGER (Given)
*        The size of the QUAL vector.
*     QUAL( SIZE ) = BYTE (Given and Returned)
*        The QUALITY vector.
*     NSET = INTEGER (Returned)
*        No. of pixels for which the specified QUALITY bit is set.
*     NCLR = INTEGER (Returned)
*        No. of pixels for which the specified QUALITY bit is cleared.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  VAX-specific features used:
*     -  Uses BYTE arrays.
*     -  Uses function BTEST

*  Copyright:
*     Copyright (C) 1991 Science & Engineering Research Council.
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
      INTEGER BIT
      INTEGER SIZE
      BYTE QUAL( SIZE )

*  Arguments Returned:
      INTEGER NSET
      INTEGER NCLR

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I                  ! Loop count.
      INTEGER LBIT               ! Corrected bit number.

*  PRIMDAT type conversion functions.
      INCLUDE 'NUM_DEC_CVT'
      INCLUDE 'NUM_DEF_CVT'

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Produce a bit number in the range 0 to (IRQ__QBITS - 1).
      LBIT = BIT - 1

*  Initialise the counter.
      NSET = 0

*  Loop round, testing each pixel.
      DO I = 1, SIZE
         IF( BTEST( NUM_UBTOI( QUAL( I ) ), LBIT ) ) THEN
            NSET = NSET + 1
         END IF
      END DO

*  Return the number of cleared pixels.
      NCLR = SIZE - NSET

      END
