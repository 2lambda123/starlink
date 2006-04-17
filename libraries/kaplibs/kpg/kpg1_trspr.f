      SUBROUTINE KPG1_TRSPR( M, N, IN, OUT, STATUS )
*+
*  Name:
*     KPG1_TRSPx
 
*  Purpose:
*     Transposes a 2-d array.
 
*  Description:
*     Creates a new 2-d array containing a transposed copy of the supplied
*     array. 

*  Language:
*     Starlink Fortran 77
 
*  Invocation
*     CALL KPG1_TRSPx( M, N, IN, OUT, STATUS )
 
*  Arguments:
*     M = INTEGER (Given)
*        Number of columns in the input array and the number of lines
*        in the output array.
*     N = INTEGER (Given)
*        Number of lines in the input array and the number of columns
*        in the output array.
*     IN( M, N ) = ? (Given)
*        The input array to be transposed.
*     OUT( N, M ) = ? (Returned)
*        The transposed array.
*     STATUS = INTEGER (Given)
*        The global status.
 
*  Algorithm:
*     - Do a direct assignment from input to output to save on page
*       faults.
 
*  Notes:
*     -  There is a routine for each numeric data type: replace "x" in
*     the routine name by D, R, I, W, UW, B or UB as appropriate.  The
*     arrays supplied to the routine must have the data type specified.
 
*  Copyright:
*     Copyright (C) 1995 Central Laboratory of the Research Councils.
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
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     6-JAN-1995 (DSB):
*        Original version (based on TRNSP2).
*     1995 March 29 (MJC):
*        Used the modern style of variable declaration, added prologue
*        terminator and made minor stylistic changes.
*     1995 March 30 (MJC):
*        Made generic from TRNSPD.  Reordered IN to be after the
*        dimensions.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
 
*  Arguments Given:
      INTEGER M
      INTEGER N
      REAL IN( M, N )
 
*  Arguments Returned:
      REAL OUT( N, M )
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER I                  ! Input pixel and output line count
      INTEGER J                  ! Output pixel and input line count
 
*.
 
*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Just do it a pixel at a time.
      DO J = 1, N
         DO I = 1, M
            OUT( J, I ) = IN( I, J )
         END DO
      END DO
 
      END
