      SUBROUTINE HSI_OK( IFID, OK, STATUS )
*+
*  Name:
*     HSI_OK

*  Purpose:
*     Check that history exists for the dataset

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL HSI_OK( IFID, OK, STATUS )

*  Description:
*     Checks that a history structure exists in the dataset supplied.

*  Arguments:
*     IFID = INTEGER (given)
*        ADI identifier of input dataset
*     OK = LOGICAL (returned)
*        History structure is ok?
*     STATUS = INTEGER (given and returned)
*        The global status.

*  Examples:
*     {routine_example_text}
*        {routine_example_description}

*  Pitfalls:
*     {pitfall_description}...

*  Notes:
*     {routine_notes}...

*  Prior Requirements:
*     {routine_prior_requirements}...

*  Side Effects:
*     {routine_side_effects}...

*  Algorithm:
*     {algorithm_description}...

*  Accuracy:
*     {routine_accuracy}

*  Timing:
*     {routine_timing}

*  External Routines Used:
*     {name_of_facility_or_package}:
*        {routine_used}...

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  References:
*     HSI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/hsi.html

*  Keywords:
*     package:hsi, usage:public

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     12 Jan 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Global Variables:
      INCLUDE 'HSI_CMN'                                 ! HSI common block
*       HSI_INIT = LOGICAL (given)
*         HSI class definitions loaded?

*  Arguments Given:
      INTEGER			IFID			! Input dataset

*  Arguments Returned:
      LOGICAL			OK			! History is ok?

*  Status:
      INTEGER 			STATUS             	! Global status

*  External References:
      EXTERNAL                  HSI0_BLK                ! Ensures inclusion

*  Local Variables:
      INTEGER			FILID			! Base file identifier
      INTEGER			OARG			! Method output value
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Check initialised
      IF ( .NOT. HSI_INIT ) CALL HSI0_INIT( STATUS )

*  Locate base file
      CALL ADI_GETFILE( IFID, FILID, STATUS )

*  Invoke method
      CALL ADI_EXEC( 'ChkHistory', 1, FILID, OARG, STATUS )

*  Extract logical value
      CALL ADI_GET0L( OARG, OK, STATUS )

*  Destroy result
      CALL ADI_ERASE( OARG, STATUS )

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'HSI_OK', STATUS )

      END
