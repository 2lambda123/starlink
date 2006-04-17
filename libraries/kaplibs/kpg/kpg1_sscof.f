      SUBROUTINE KPG1_SSCOF( EL, FACTOR, OFFSET, OUT, STATUS )
*+
*  Name:
*     KPG1_SSCOF

*  Purpose:
*     Applies a simple scaling and base-line shift to create the
*     output vector.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_SSCOF( EL, FACTOR, OFFSET, OUT, STATUS )

*  Description:
*     Pixel indices are multiplied by the given factor and
*     the given offset is then added on, to form the output data.
*     The first pixel has value equal to the offset.

*  Arguments:
*     EL = INTEGER (Given)
*        The number elements in the returned array.
*     FACTOR = DOUBLE PRECISION (Given)
*        The factor by which the array indices are scaled.
*     OFFSET = DOUBLE PRECISION (Given)
*        The offset by which the array indices are shifted.
*     OUT( EL ) = REAL (Given)
*        The output data vector.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     There is no exception handler if the evaluated value exceeds the
*     machine floating-pint range.

*  Copyright:
*     Copyright (C) 1990 Science & Engineering Research Council.
*     Copyright (C) 2004 Central Laboratory of the Research Councils.
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
*     MJC: Malcolm J. Currie (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     1990 November 15 (MJC):
*        Original version.
*     2004 Oct 1 (TIMJ):
*        NUM_CMN not required
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Global Variables:

*  Arguments Given:
      INTEGER  EL   
      DOUBLE PRECISION FACTOR
      DOUBLE PRECISION OFFSET

*  Arguments Returned:
      REAL   OUT( EL )

*  Status:
      INTEGER STATUS             ! Global status

*  Local variables:
      INTEGER  ELEM              ! The element counter.

*.

*    Check inherited global status.

      IF ( STATUS .NE. SAI__OK ) RETURN

*    Loop round all the elements of the vector.

      DO ELEM = 1, EL

*       Evaluate the scale and offset for each array element.

         OUT( ELEM ) = REAL( FACTOR * DBLE( ELEM - 1 ) + OFFSET )

      END DO

      END
