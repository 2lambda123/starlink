      SUBROUTINE TASK_ENC1L ( NVALS, LVALS, STRING, STATUS )
*+
*  Name:
*     TASK_ENC1L

*  Purpose:
*     Encode a vector as a character string

*  Language:
*     Starlink Fortran 77

*  Type Of Module:
*     SUBROUTINE

*  Invocation:
*     CALL TASK_ENC1L ( NVALS, LVALS, STRING, STATUS )

*  Description:
*     Convert the given 1-D array into characters and concatenate the
*     result into a string with the ADAM syntax, that is the elements of
*     the array are separated and the whole is surrounded by [].
*     There is a routine for each type C, D, I, L, R.

*  Arguments:
*     NVALS=INTEGER (given)
*           number of values in the 1-D array
*     LVALS(NVALS)=LOGICAL (given)
*           the array to be converted
*     STRING=CHARACTER*(*) (returned)
*           the returned character string
*     STATUS=INTEGER

*  Algorithm:
*     Call TASK_ENCNL

*  Copyright:
*     Copyright (C) 1987, 1989 Science & Engineering Research Council.
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
*     B.D.Kelly (REVAD::BDK)
*     {enter_new_authors_here}

*  History:
*     06-NOV-1987 (REVAD::BDK):
*        Original
*     29-APR-1989 (AAOEPP::WFL):
*        Make it generic
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'SAE_PAR'
 
*  Arguments Given:
      INTEGER NVALS         ! number of values in the 1-D array
 
      LOGICAL LVALS(NVALS) ! the array to be encoded
 
*  Arguments Returned:
      CHARACTER*(*) STRING  ! the returned character string
 
*  Status:
      INTEGER STATUS
 
*  Local Variables:
      INTEGER NDIMS         ! no of dimensions to be passed
*.
 
      IF ( STATUS .NE. SAI__OK ) RETURN
 
      NDIMS = 1
      CALL TASK_ENCNL ( NDIMS, NVALS, LVALS, STRING, STATUS )
 
      END
