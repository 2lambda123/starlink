      SUBROUTINE ARR_COP1<T>( N, IN, OUT, STATUS )
*+
*  Name:
*     ARR_COP1<T>

*  Purpose:
*     Copies 1D <TYPE> array to another

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL ARR_COP1<T>( N, IN, OUT, STATUS )

*  Description:
*     Copies 1D <TYPE> array to another

*  Arguments:
*     IN[] = <TYPE> (given)
*        Input array to be copied
*     N = INTEGER (given)
*        Number of elements to copy
*     OUT[] = <TYPE> (returned)
*        Copy of input array
*     STATUS = INTEGER (given)
*        The global status.

*  Examples:
*     {routine_example_text}
*        {routine_example_description}

*  References:
*     ARR Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/arr.html

*  Keywords:
*     package:arr, usage:public, array, copying

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     RJV: Robert Vallance (University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     13 Mar 1995 (DJA):
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
      INTEGER			N			! Number of elements
      <TYPE>			IN(*)			! Input array

*  Arguments Returned:
      <TYPE>			OUT(*)			! Output array

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local Variables:
      INTEGER			I			! Loop variable
*.

*  Check inherited global status.
      IF ( STATUS .EQ. SAI__OK ) THEN

        DO I = 1, N
          OUT(I) = IN(I)
        END DO

      END IF

      END
