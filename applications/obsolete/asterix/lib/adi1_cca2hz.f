      SUBROUTINE ADI1_CCA2HZ( ID, MEMBER, LOC, CMP, STATUS )
*+
*  Name:
*     ADI1_CCA2HZ

*  Purpose:
*     Conditional copy of HDSfile ADI data member to HDS component

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL ADI1_CCA2HZ( ID, MEMBER, LOC, CMP, STATUS )

*  Description:
*     Copies an ADI data member to an HDS object if the member data is
*     defined.

*  Arguments:
*     ID = INTEGER (Given)
*        The ADI identifier containing the data member
*     MEMBER = CHARACTER*(*) (Given)
*        The name of the data member to copy
*     LOC = CHARACTER*(DAT__SZLOC) (Given)
*        The locator to the HDS structure to contain the component
*     CMP = CHARACTER*(*) (Given)
*        The name of the new HDS component
*     STATUS = INTEGER (Given and returned)
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
*     ADI Subroutine Guide : http://www.sr.bham.ac.uk:8080/asterix-docs/Programmer/Guides/adi.html

*  Keywords:
*     package:adi, usage:private

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     29 Mar 1995 (DJA):
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
      INCLUDE 'DAT_PAR'

*  Arguments Given:
      INTEGER			ID			! See above
      CHARACTER*(*)		MEMBER
      CHARACTER*(DAT__SZLOC)	LOC
      CHARACTER*(*)		CMP

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local Variables:
      CHARACTER*(DAT__SZLOC)	VLOC			! Value locator

      INTEGER			MID			! Value identifier

      LOGICAL			THERE			! Component exists?
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Does the member exist?
      IF ( MEMBER .GT. ' ' ) THEN
        CALL ADI_THERE( ID, MEMBER, THERE, STATUS )
        IF ( THERE ) THEN
          CALL ADI_FIND( ID, MEMBER, MID, STATUS )
        END IF
      ELSE
        THERE = .TRUE.
        MID = ID
      END IF

*  Try to copy if it exists
      IF ( THERE ) THEN

*    HDS value already exists? If so, delete it
        CALL DAT_THERE( LOC, CMP, THERE, STATUS )
        IF ( THERE ) THEN
          CALL DAT_ERASE( LOC, CMP, STATUS )
        END IF

*    Get value object locator
        CALL ADI1_GETLOC( MID, VLOC, STATUS )

*    Copy it into the named subcomponent
        CALL DAT_COPY( VLOC, LOC, CMP, STATUS )

      END IF

*  Free the member identifier
      IF ( MEMBER .GT. ' ' ) THEN
        CALL ADI_ERASE( MID, STATUS )
      END IF

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'ADI1_CCA2HZ', STATUS )

      END
