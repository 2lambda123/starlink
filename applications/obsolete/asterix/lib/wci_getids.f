      SUBROUTINE WCI_GETIDS( ID, PIXID, PRJID, SYSID, STATUS )
*+
*  Name:
*     WCI_GETIDS

*  Purpose:
*     Construct the WCI data objects given a dataset identifier

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL WCI_GETIDS( ID, PIXID, PRJID, SYSID, STATUS )

*  Description:
*     Construct the 3 WCI identifiers containing all the information
*     required to describe local and world coordinates in the input
*     object.
*
*     The routine invokes the ReadWCS method on the input object. This
*     method returns a structure containing the 3 components named
*     'Pix', 'Proj' and 'Sys'. This structure is stored on the property
*     list of the input object, and identifiers to the components are
*     returned as separate values.

*  Arguments:
*     ID = INTEGER (given)
*        ADI identifier of the dataset object
*     PIXID = INTEGER (returned)
*        ADI identifier of the Pixellation object
*     PRJID = INTEGER (returned)
*        ADI identifier of the Projection object
*     SYSID = INTEGER (returned)
*        ADI identifier of the CoordSystem object
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
*     package:wci, usage:public

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     14 Feb 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'ADI_PAR'
      INCLUDE 'AST_PKG'

*  Arguments Given:
      INTEGER			ID

*  Arguments Returned:
      INTEGER			PIXID,PRJID,SYSID

*  Status:
      INTEGER 			STATUS             	! Global status

*  External References:
      EXTERNAL			AST_QPKGI
        LOGICAL			AST_QPKGI

*  Local Variables:
      INTEGER			FILID			! Base file identifier
      INTEGER			RESID			! Method output data

      LOGICAL			THERE			! Component exists?
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Check initialised
      IF ( .NOT. AST_QPKGI( WCI__PKG ) ) CALL WCI0_INIT( STATUS )

*  Initialise return values
      PIXID = ADI__NULLID
      PRJID = ADI__NULLID
      SYSID = ADI__NULLID

*  Locate linked object
      CALL ADI_GETLINK( ID, FILID, STATUS )

*  Simply invoke the ReadWCS method
      IF ( FILID .EQ. ADI__NULLID ) THEN
        CALL ADI_EXEC2( 'ReadWCS', ADI__NULLID, ID, RESID, STATUS )
      ELSE
        CALL ADI_EXEC2( 'ReadWCS', ID, FILID, RESID, STATUS )
      END IF

*  If ok, extract results
      IF ( (STATUS .EQ. SAI__OK) .AND. (RESID.NE.ADI__NULLID) ) THEN

*    Locate sub-components for callee
        CALL ADI_THERE( RESID, 'Pix', THERE, STATUS )
        IF ( THERE ) THEN
          CALL ADI_FIND( RESID, 'Pix', PIXID, STATUS )
        END IF
        CALL ADI_THERE( RESID, 'Proj', THERE, STATUS )
        IF ( THERE ) THEN
          CALL ADI_FIND( RESID, 'Proj', PRJID, STATUS )
        END IF
        CALL ADI_THERE( RESID, 'Sys', THERE, STATUS )
        IF ( THERE ) THEN
          CALL ADI_FIND( RESID, 'Sys', SYSID, STATUS )
        END IF

*    Store the returned object on the property list of the object
        CALL ADI_CPUTID( ID, WCI_PROP, RESID, STATUS )

      END IF

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'WCI_GETIDS', STATUS )

      END
