      SUBROUTINE WCI1_UNIT2R( UNIT, FACTOR, STATUS )
*+
*  Name:
*     WCI1_UNIT2R

*  Purpose:
*     Return conversion factor from units supplied to radians

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL WCI1_UNIT2R( UNIT, FACTOR, STATUS )

*  Description:
*     Returns conversion factor from angular units UNIT to radians. An
*     error is reported if the units cannot be recognised.

*  Arguments:
*     UNIT = CHARACTER*(*) (given)
*        The units to convert
*     FACTOR = DOUBLE (returned)
*        The quantity such that a number with units UNIT can be converted
*        to radians by multiplication
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
*     WCI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/wci.html

*  Keywords:
*     package:wci, usage:private

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     RB: Richard Beard (ROSAT, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     9 Jan 1995 (DJA):
*        Original version.
*     11 Apr 1997 (RB):
*        Add meaningless case for pixels.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          			! Standard SAE
      INCLUDE 'MATH_PAR'				! ASTERIX maths

*  Arguments Given:
      CHARACTER*(*)		UNIT			! Units string

*  Arguments Returned:
      DOUBLE PRECISION		FACTOR			! Conversion factor

*  Status:
      INTEGER 			STATUS             	! Global status

*  External References:
      EXTERNAL			STR_ABBREV
        LOGICAL			STR_ABBREV
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Always return a default
      FACTOR = 1D0

      IF ( STR_ABBREV( UNIT, 'DEG' ) ) THEN
        FACTOR = MATH__DDTOR

      ELSE IF ( STR_ABBREV( UNIT, 'ARCMIN' ) ) THEN
        FACTOR = MATH__DDTOR / 60D0

      ELSE IF ( STR_ABBREV( UNIT, 'ARCSEC' ) ) THEN
        FACTOR = MATH__DDTOR / 3600D0

      ELSE IF ( STR_ABBREV( UNIT, 'RAD') ) THEN
        FACTOR = 1D0

      ELSE IF ( STR_ABBREV( UNIT, 'PIX' ) ) THEN
        FACTOR = 1D0

      ELSE
        CALL MSG_SETC( 'UN', UNIT )
        STATUS = SAI__ERROR
        CALL ERR_REP( ' ', 'Unrecognised angular units ^UN', STATUS )

      END IF

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'WCI1_UNIT2R', STATUS )

      END
