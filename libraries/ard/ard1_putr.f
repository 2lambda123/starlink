      SUBROUTINE ARD1_PUTR( VALUE, SIZE, INDEX, ARRAY, STATUS )
*+
*  Name:
*     ARD1_PUTI

*  Purpose:
*     Put a real value into an array

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL ARD1_PUTR( VALUE, SIZE, INDEX, ARRAY, STATUS )

*  Description:
*     The supplied value is stored in the array at the given index.

*  Arguments:
*     VALUE = REAL (Given)
*        The value to be stored.
*     SIZE = INTEGER (Given)
*        The size of the array.
*     INDEX = INTEGER (Given)
*        The index at which to store the value.
*     ARRAY( SIZE ) = REAL (Given and Returned)
*        The array.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1994 Science & Engineering Research Council.
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
*     16-FEB-1994 (DSB):
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
      REAL VALUE
      INTEGER SIZE
      INTEGER INDEX

*  Arguments Given and Returned:
      REAL ARRAY( SIZE )

*  Status:
      INTEGER STATUS             ! Global status

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Store the value at the given index.
      ARRAY( INDEX ) = VALUE

      END
