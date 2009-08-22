      SUBROUTINE IRQ1_NDTOV( NDIM, NCOORD, LIST, LBND, UBND, VIND, NOK,
     :                       STATUS )
*+
*  Name:
*     IRQ1_NDTOV

*  Purpose:
*     Convert N-dimensional coordinates to one dimensional indices.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ1_NDTOV( NDIM, NCOORD, LIST, LBND, UBND, VIND, NOK,
*                      STATUS )

*  Description:
*     Converts N dimensional coordinates into 1 dimensional indices.
*     Any input coordinates which do not satisfy the bounds constraints
*     are excluded from the final list of indices.

*  Arguments:
*     NDIM = INTEGER (Given)
*        The number of dimensions.
*     NCOORD = INTEGER (Given)
*        The number of pixels in the input list. Each pixel has NDIM
*        coordinate values to describe its position.
*     LIST( NDIM, NCOORD ) = INTEGER (Given)
*        The list of pixel positions.
*     LBND( NDIM ) = INTEGER (Given)
*        The lower bound on each axis of the pixel space.
*     UBND( NDIM ) = INTEGER (Given)
*        The upper bound on each axis of the pixel space.
*     VIND( NCOORD ) = INTEGER (Returned)
*        The one dimensional indices corresponding to the N dimensional
*        coordinates supplied in LIST.
*     NOK = INTEGER (Returned)
*        The number of pixel positions which satisfied the bounds
*        constraints.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

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
      INTEGER NDIM
      INTEGER NCOORD
      INTEGER LIST( NDIM, NCOORD )
      INTEGER LBND( NDIM )
      INTEGER UBND( NDIM )

*  Arguments Returned:
      INTEGER VIND( NCOORD )
      INTEGER NOK

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I                  ! Loop count.
      INTEGER J                  ! Dimension count.
      INTEGER OFFSET             ! Vector offset corresponding to
                                 ! listed pixel coordinates.
      LOGICAL OK                 ! True if listed pixel is within
                                 ! given bounds.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the number of good positions to zero.
      NOK = 0

*  Loop through each supplied position.
      DO I = 1, NCOORD

*  See if the coordinates are within the supplied bounds.
         OK = .TRUE.
         DO J = 1, NDIM
            IF( LIST( J, I ) .LT. LBND( J ) .OR.
     :          LIST( J, I ) .GT. UBND( J ) ) OK = .FALSE.
         END DO

*  If so, increment the number of good positions.
         IF( OK ) THEN
            NOK = NOK + 1

*  Convert the supplied coordinates into the equivalent vector offsets.
            OFFSET = LIST( NDIM, I ) - LBND( NDIM )
            DO J = NDIM - 1, 1, -1
               OFFSET = OFFSET*( UBND( J ) - LBND( J ) + 1 )
     :                  + LIST( J, I ) - LBND( J )
            END DO

*  Store the corresponding vector index.
            VIND( NOK ) = OFFSET + 1

         END IF

      END DO

      END
