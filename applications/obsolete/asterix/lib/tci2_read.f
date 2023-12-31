      SUBROUTINE TCI2_READ( NARG, ARGS, OARG, STATUS )
*+
*  Name:
*     TCI2_READ

*  Purpose:
*     Read timing info from FITSfile object

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL TCI2_READ( NARG, ARGS, OARG, STATUS )

*  Description:
*     {routine_description}

*  Arguments:
*     NARG = INTEGER (given)
*        Number of method arguments
*     ARGS(*) = INTEGER (given)
*        ADI identifier of method arguments
*     OARG = INTEGER (returned)
*        Output data
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
*     TCI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/tci.html

*  Keywords:
*     package:tci, usage:private

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     12 Oct 1995 (DJA):
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
      INTEGER                   NARG, ARGS(*)

*  Arguments Returned:
      INTEGER                   OARG

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local Variables:
      INTEGER			PHDU			! Main HDU in file

      LOGICAL			OK			! Keyword copied?
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Create output object
      CALL ADI_NEW0( 'TimingInfo', OARG, STATUS )

*  Locate main HDU
      CALL ADI2_FNDHDU( ARGS(1), ' ', .FALSE., PHDU, STATUS )

*  Copy selected keywords
      CALL ADI2_KCF2A( PHDU, 'TIMEREF', OARG, 'System',
     :                 OK, STATUS )
      CALL ADI2_KCF2A( PHDU, 'TASSIGN', OARG, 'Assign',
     :                 OK, STATUS )
      CALL ADI2_KCF2A( PHDU, 'MJDREF', OARG, 'MJDRef',
     :                 OK, STATUS )
      CALL ADI2_KCF2A( PHDU, 'MJD-OBS', OARG, 'MJDObs',
     :                 OK, STATUS )
      CALL ADI2_KCF2A( PHDU, 'EXPOSURE', OARG, 'Exposure',
     :                 OK, STATUS )
      CALL ADI2_KCF2A( PHDU, 'ONTIME', OARG, 'ObsLength',
     :                 OK, STATUS )

*  Release the HDU
      CALL ADI_ERASE( PHDU, STATUS )

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'TCI2_READ', STATUS )

      END
