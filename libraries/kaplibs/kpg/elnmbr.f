      SUBROUTINE ELNMBR( X1, X2, ODIM, OUTARR, STATUS )
*+
*  Name:
*     KPG1_ELNMBR
 
*  Purpose:
*     Write a range of element numbers into an array.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation
*     CALL KPG1_ELNMBx( X1, X2, ODIM, OUTARR, STATUS )
 
*  Description:
*     This routine writes numbers sequentially to a REAL 1-d
*     array, where the numbers are between defined integer limits and
*     are stepped by 1 (or -1) from one pixel to the next.  In other
*     words the array value takes the element number plus an offset.
*     Only the first %ODIM elements can be accommodated in the output
*     array, should the section be larger than this.
 
*  Arguments:
*     X1 = INTEGER (Given)
*        The first value to be written to the output array.  If this
*        is larger than %X2 the values will decrease by 1 for each
*        element.
*     X2 = INTEGER (Given)
*        The last value to be written to the output array, provided
*        there are sufficient elements to accommodate it.  If not
*        only %ODIM values will be stored.
*     ODIM = INTEGER (Given)
*        The number of elements in the output array.
*     OUTARR( ODIM ) = ? (Returned)
*        The array into which the sub-array is copied.
*     STATUS = INTEGER (Given)
*        The status value on entry to this routine.
 
*  Algorithm:
*     Check for error on entry - return if not o.k.
*     The maximum and minimum extents of the sub-array are found
*        and the maximum is constrained by the dimension of the output
*        array
*     The values are written to the output array, converting to the
*       appropriate type
*     End
 
*  Copyright:
*     Copyright (C) 1988, 1990 Science & Engineering Research Council.
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
*     MJC: Malcolm J. Currie  (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1988 Oct 25 (MJC):
*        Original version.
*     1990 Jul 29 (MJC):
*        Allowed the element value to decrease with increasing element
*        number.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE            ! No assumed typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'        ! Global SSE definitions
 
*  Arguments Given:
      INTEGER
     :    ODIM,
     :    X1,
     :    X2
 
*  Arguments Returned:
      REAL OUTARR( ODIM )
 
*  Status:
      INTEGER STATUS
 
*  Local Variables:
      INTEGER
     :  I, J,                  ! Counters
     :  LOWER,                 ! Lower bound of the sub-array
     :  UPPER                  ! Upper bound of the sub-array
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'    ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'    ! NUM definitions for conversions
 
*.
 
 
*    If status value is bad, then return immediately.
 
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*    Forward or reverse?
 
      IF ( X2. GE. X1 ) THEN
 
*       Forward
*       =======
*
*       Only store as many values as can be accommodated.
 
         UPPER = MIN( X2, ODIM + X1 - 1 )
 
*       Copy the elements of the sub-array.
 
         J = 0
         DO  I = X1, UPPER, 1
            J = J + 1
            OUTARR( J ) = NUM_ITOR( I )
         END DO
 
      ELSE
 
*      Reverse
*      =======
 
*       Only store as many values as can be accommodated.
 
         LOWER = MAX( X2, X1 - ODIM + 1 )
 
*       Copy the elements of the sub-array.
 
         J = 0
         DO  I = X1, LOWER, -1
            J = J + 1
            OUTARR( J ) = NUM_ITOR( I )
         END DO
      END IF
 
      END
