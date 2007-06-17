      SUBROUTINE ARR_COP1B( N, IN, OUT, STATUS )
*+
*  Name:
*     ARR_COP1B

*  Purpose:
*     Copies 1D BYTE array to another

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL ARR_COP1B( N, IN, OUT, STATUS )

*  Description:
*     Copies 1D BYTE array to another

*  Arguments:
*     IN[] = BYTE (given)
*        Input array to be copied
*     N = INTEGER (given)
*        Number of elements to copy
*     OUT[] = BYTE (returned)
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
      BYTE			IN(*)			! Input array

*  Arguments Returned:
      BYTE			OUT(*)			! Output array

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
      SUBROUTINE ARR_COP1D( N, IN, OUT, STATUS )
*+
*  Name:
*     ARR_COP1D

*  Purpose:
*     Copies 1D DOUBLE PRECISION array to another

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL ARR_COP1D( N, IN, OUT, STATUS )

*  Description:
*     Copies 1D DOUBLE PRECISION array to another

*  Arguments:
*     IN[] = DOUBLE PRECISION (given)
*        Input array to be copied
*     N = INTEGER (given)
*        Number of elements to copy
*     OUT[] = DOUBLE PRECISION (returned)
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
      DOUBLE PRECISION			IN(*)			! Input array

*  Arguments Returned:
      DOUBLE PRECISION			OUT(*)			! Output array

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
      SUBROUTINE ARR_COP1L( N, IN, OUT, STATUS )
*+
*  Name:
*     ARR_COP1L

*  Purpose:
*     Copies 1D LOGICAL array to another

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL ARR_COP1L( N, IN, OUT, STATUS )

*  Description:
*     Copies 1D LOGICAL array to another

*  Arguments:
*     IN[] = LOGICAL (given)
*        Input array to be copied
*     N = INTEGER (given)
*        Number of elements to copy
*     OUT[] = LOGICAL (returned)
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
      LOGICAL			IN(*)			! Input array

*  Arguments Returned:
      LOGICAL			OUT(*)			! Output array

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
