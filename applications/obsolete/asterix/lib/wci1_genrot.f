      SUBROUTINE WCI1_GENROT( SLONG, SLAT, PLONG, MAT, STATUS )
*+
*  Name:
*     WCI1_GENROT

*  Purpose:
*     Generates rotation matrix given pole and reference longitude

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL WCI1_GENROT( SLONG, SLAT, PLONG, MAT, STATUS )

*  Description:
*     Generate rotation matrix from native sphericals to standard
*     sphericals where (SLONG,SLAT) position of the 'special point'
*     in the standard system, and PLONG is the longitude of the
*     standard system's north pole in the native system.

*  Arguments:
*     SLONG = DOUBLE (given)
*        Longitude of special point in standard system (degrees)
*     SLAT = DOUBLE (given)
*        Latitude of special point in standard system (degrees)
*     PLONG = DOUBLE (given)
*        Longitude of standard north pole in native system (degrees)
*     MAT[3,3] = DOUBLE (returned)
*        The rotation matrix
*     STATUS = INTEGER (given)
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
*     package:wci, usage:private, rotation matrices

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*      5 Jan 1995 (DJA):
*        Original version.
*     21 Feb 1996 (DJA):
*        Removed SIND and COSD for Linux port
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'MATH_PAR'

*  Arguments Given:
      DOUBLE PRECISION		SLONG, SLAT, PLONG

*  Arguments Returned:
      DOUBLE PRECISION		MAT(3,3)

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local variables:
      DOUBLE PRECISION		SIN_AL, COS_AL		! sin/cos SLONG
      DOUBLE PRECISION		SIN_DE, COS_DE		! sin/cos SLAT
      DOUBLE PRECISION		SIN_LP, COS_LP		! sin/cos PLONG
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Pre-compute trig functions
      SIN_AL = SIN(SLONG*MATH__DDTOR)
      COS_AL = COS(SLONG*MATH__DDTOR)
      SIN_DE = SIN(SLAT*MATH__DDTOR)
      COS_DE = COS(SLAT*MATH__DDTOR)
      SIN_LP = SIN(PLONG*MATH__DDTOR)
      COS_LP = COS(PLONG*MATH__DDTOR)

*  Generate the matrix
      MAT(1,1) = -SIN_AL*SIN_LP - COS_AL*COS_LP*SIN_DE
      MAT(1,2) = COS_AL*SIN_LP - SIN_AL*COS_LP*SIN_DE
      MAT(1,3) = COS_LP*COS_DE
      MAT(2,1) = SIN_AL*COS_LP - COS_AL*SIN_LP*SIN_DE
      MAT(2,2) = - COS_AL*COS_LP - SIN_AL*SIN_LP*SIN_DE
      MAT(2,3) = SIN_LP*COS_DE
      MAT(3,1) = COS_AL*COS_DE
      MAT(3,2) = SIN_AL*COS_DE
      MAT(3,3) = SIN_DE

      END
