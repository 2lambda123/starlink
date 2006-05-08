      SUBROUTINE KPS1_PLCPD( EL, NEL, IN, USE, FILL, OUT, STATUS )
*+
*  Name:
*     KPS1_PLCPX

*  Purpose:
*     Copies a single element of an array from the input to the output.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_PLCPx( EL, NEL, IN, USE, FILL, OUT, STATUS )

*  Description:
*     Stores a value in a specified pixel of the ouput array, either by
*     copying the corresponding pixel value from the input array, or
*     by using a supplied constant value.

*  Arguments:
*     EL = INTEGER (Given)
*        The index of the array element to be copied.
*     NEL = INTEGER (Given)
*        The size of the input and output arrays.
*     IN( NEL ) = ? (Given)
*        The input array.
*     USE = LOGICAL (Given)
*        If .TRUE. then copy in the input array value to the output,
*        otherwise use the value of argument FILL.
*     FILL = ? (Given)
*        A constant value to store in the output if the input array
*        value is not to be used.
*     OUT( NEL ) = ? (Returned)
*        The output array.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  There is a routine for all numeric data types: replace "x" in
*     the routine name by B, D, I, R, UB, UW, or W as appropriate.  The
*     IN, FILL, and OUT arguments must have the data type specified.

*  Copyright:
*     Copyright (C) 1993 Science & Engineering Research Council.
*     Copyright (C) 1995 Central Laboratory of the Research Councils.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     DSB: David Berry (STARLINK)
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     12-NOV-1993 (DSB):
*        Original version.
*     1995 April 12 (MJC):
*        Added the Notes.  Minor stylistic changes.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
 
*  Arguments Given:
      INTEGER EL
      INTEGER NEL
      DOUBLE PRECISION IN( NEL )
      LOGICAL USE
      DOUBLE PRECISION FILL
 
*  Arguments Returned:
      DOUBLE PRECISION OUT( NEL )
 
*  Status:
      INTEGER STATUS             ! Global status
 
*.
 
*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  If the input array can be used, copy the pixel value to the output
*  array.
      IF ( USE ) THEN
         OUT( EL ) = IN( EL )
 
*  Otherwise, copy the supplied fill value to the output array.
      ELSE
         OUT( EL ) = FILL
 
      END IF
 
      END
