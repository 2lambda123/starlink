      SUBROUTINE WCI_UNPROJ( STD, PRJID, RPH, STATUS )
*+
*  Name:
*     WCI_UNPROJ

*  Purpose:
*     Unproject linear x,y to relative spherical coords

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL WCI_UNPROJ( STD, PRJID, RPH, STATUS )

*  Description:
*     {routine_description}

*  Arguments:
*     STD[3] = DOUBLE (given)
*        Position in native spherical coordinates
*     PRJID = INTEGER (given)
*        ADI identifier of projection object
*     RPH[3] = DOUBLE (returned)
*        Relative physical coordinates.
*     STATUS = INTEGER (given and returned)
*        The global status.

*  Examples:
*     {routine_example_text}
*        {routine_example_description}

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
*     package:wci, usage:public

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     5 Jan 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PKG'

*  Arguments Given:
      DOUBLE PRECISION		STD(3)
      INTEGER			PRJID

*  Arguments Returned:
      DOUBLE PRECISION		RPH(3)

*  Status:
      INTEGER 			STATUS             	! Global status

*  External References:
      EXTERNAL			AST_QPKGI
        LOGICAL			AST_QPKGI

*  Local Variables:
      INTEGER			RPTR			! Routine address
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Check initialised
      IF ( .NOT. AST_QPKGI( WCI__PKG ) ) CALL WCI1_INIT( STATUS )

*  Extract projection routine address
      CALL ADI_CGET0I( PRJID, '.WCIRTN', RPTR, STATUS )

*  If ok, invoke the routine
      IF ( STATUS .EQ. SAI__OK ) THEN

*    Must dereference the pointer
        CALL WCI_UNPROJ1( %VAL(RPTR), STD, PRJID, RPH, STATUS )

      END IF

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'WCI_PROJ', STATUS )

      END



      SUBROUTINE WCI_UNPROJ1( RTN, STD, PRJID, RPH, STATUS )
*+
*  Name:
*     WCI_UNPROJ1

*  Purpose:
*     Unproject native system to relative physicals coords, internal routine

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL WCI_UNPROJ1( RTN, RPH, PRJID, STD, STATUS )

*  Description:
*     Invoke projector routine to project relative physical coords to
*     native spehericals.

*  Arguments:
*     RTN = EXTERNAL (given)
*        Projector routine
*     RPH[3] = DOUBLE (given)
*        Relative physical coordinates.
*     PRJID = INTEGER (given)
*        ADI identifier of projection object
*     STD[3] = DOUBLE (returned)
*        Position in native spherical coordinates
*     STATUS = INTEGER (given and returned)
*        The global status.

*  Examples:
*     {routine_example_text}
*        {routine_example_description}

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
*     {enter_new_authors_here}

*  History:
*     5 Jan 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'WCI_PAR'

*  Arguments Given:
      EXTERNAL			RTN			! Routine
      DOUBLE PRECISION		STD(3)			! Native sphericals
      INTEGER			PRJID			! Projection object

*  Arguments Returned:
      DOUBLE PRECISION		RPH(3)			! Relative physicals

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local constants:
      INTEGER			MAXPAR			! Max control pars
        PARAMETER		( MAXPAR = 2 )

*  Local variables:
      REAL			PARAM(MAXPAR)		! Control params

      INTEGER			NPAR			! # control params

      LOGICAL			THERE			! Component exists?
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Extract number of control parameters if valid
      CALL ADI_THERE( PRJID, 'PARAM', THERE, STATUS )
      IF ( THERE ) THEN
        CALL ADI_CGET1R( PRJID, 'PARAM', 2, PARAM, NPAR, STATUS )
      ELSE
        NPAR = 0
      END IF

*  Invoke the projector routine
      CALL RTN( WCI__OPS2N, RPH, NPAR, PARAM, STD, STATUS )

      END
