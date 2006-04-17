      SUBROUTINE KPG1_NBADD( N, DATA, NBAD, STATUS )
*+
*  Name:
*     KPG1_NBADD
 
*  Purpose:
*     Finds the number of bad values in an array.
 
*  Description:
*     Finds the number of bad values in a 1-D array.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation
*     CALL KPG1_NBADD( N, DATA, NBAD, STATUS )
 
*  Arguments:
*     N = INTEGER (Given)
*        Number of elements in the array.
*     DATA( N ) = ? (Given)
*        The data array.
*     NBAD = INTEGER (Returned)
*        The number of bad values in the data.
*     STATUS = INTEGER (Given)
*        The global status.
 
*  Copyright:
*     Copyright (C) 1998 Central Laboratory of the Research Councils.
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
*     DSB: D.S. Berry (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     9-DEC-1998 (DSB):
*        Original version.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! VAL__ constants
 
*  Arguments Given:
      INTEGER N
      DOUBLE PRECISION DATA( N )
 
*  Arguments Returned:
      INTEGER NBAD
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER I                  ! Loop count
 
*.
 
*  Check the global inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Initialise the returned count.
      NBAD = 0
 
*  Loop round the data array, counting bad values.
      DO I = 1, N
         IF ( DATA( I ) .EQ. VAL__BADD ) NBAD = NBAD + 1
      END DO
 
      END
