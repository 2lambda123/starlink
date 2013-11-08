      SUBROUTINE HSI_NEW( IFID, STATUS )
*+
*  Name:
*     HSI_NEW

*  Purpose:
*     Create a new history structure in a dataset

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL HSI_NEW( IFID, STATUS )

*  Description:
*     Create new history structure in dataset, deleting existing one if
*     present.

*  Arguments:
*     IFID = INTEGER (given)
*        ADI identifier if input dataset
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
*     package:hsi, usage:public, history, creation

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

*  Status:
      INTEGER 			STATUS             	! Global status

*  External References:
      EXTERNAL                  HSI0_BLK                ! Ensures inclusion

*  Local Variables:
      INTEGER			FILID			! Base file identifier
      INTEGER			OARG			! Unused method return
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Check initialised
      IF ( .NOT. HSI_INIT ) CALL HSI0_INIT( STATUS )

*  Get base file
      CALL ADI_GETFILE( IFID, FILID, STATUS )

*  Invoke method
      CALL ADI_EXEC( 'NewHistory', 1, FILID, OARG, STATUS )

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'HSI_NEW', STATUS )

      END
