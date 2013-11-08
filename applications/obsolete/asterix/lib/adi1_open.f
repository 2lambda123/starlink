      SUBROUTINE ADI1_OPEN( FID, MID, ID, STATUS )
*+
*  Name:
*     ADI1_OPEN

*  Purpose:
*     Attempt to open an HDS file. If the file is opened ok then the
*     FileHandle object pointed to by ID is updated.

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL ADI1_OPEN( FSPEC, MODE, ID, STATUS )

*  Description:
*     Attempts to open the named file object as an HDS file. If successful
*     the routine stores the locator on the property list of the ID object.

*  Arguments:
*     FSPEC = CHAR (Given)
*        Name of the object on which HDS access to be attempted
*     MODE = CHAR (Given)
*        File access mode
*     ID = INTEGER (Returned)
*        ADI identifier of opened object
*     STATUS = INTEGER (Given and returned)
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

*  External Routines Used:
*     {name_of_facility_or_package}:
*        {routine_used}...

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  References:
*     ADI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/adi.html

*  Keywords:
*     package:adi, usage:private

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (JET-X,University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     15 Jul 1994 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! Standard HDS constants

*  Arguments Given:
      INTEGER			FID			! File spec
      INTEGER			MID			! Access mode

*  Arguments Returned:
      INTEGER			ID

*  Status:
      INTEGER 			STATUS             	! Global status

*  External references:
      EXTERNAL			CHR_LEN
        INTEGER			CHR_LEN
      EXTERNAL			CHR_SIMLR
        LOGICAL			CHR_SIMLR

*  Local Variables:
      CHARACTER*(DAT__SZLOC)	FLOC			! Object locator
      CHARACTER*(DAT__SZLOC)	TLOC			! Temp file locator
      CHARACTER*200             FSPEC
      CHARACTER*6               MODE

      INTEGER			DP, EP			! Character positions
      INTEGER			FLEN			! Length of FSPEC
*.

*    Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*    Extract name and access mode
      CALL ADI_GET0C( FID, FSPEC, STATUS )
      FLEN = CHR_LEN( FSPEC )
      CALL ADI_GET0C( MID, MODE, STATUS )

*    Length of FSPEC
      FLEN = CHR_LEN( FSPEC )

*    Look for % delimiter, so that trailing representation can be ignored
      EP = FLEN
      DO WHILE ( (EP.GT.0) .AND. (FSPEC(EP:EP).NE.'%') )
        EP = EP - 1
      END DO
      IF ( EP .NE. 0 ) FLEN = EP - 1

*    Check if slice or subcomponent delimiters present. Look for period
*    after the last slash in the file name if one is present, otherwise
*    simply the first period
      EP = FLEN
      DO WHILE ( (EP.GT.0) .AND. (FSPEC(EP:EP).NE.'/') )
        EP = EP - 1
      END DO
      IF ( EP .GT. 0 ) THEN
        DP = INDEX( FSPEC(EP:), '.' ) + EP - 1
      ELSE
        DP = INDEX( FSPEC, '.' )
      END IF
      IF ( DP .GT. EP ) THEN
        IF ( CHR_SIMLR( FSPEC(DP+1:FLEN), 'sdf' ) ) THEN
          DP = 0
          FLEN = FLEN - 4
        END IF
      ELSE
        DP = 0
      END IF

*  Simple HDS file name?
      IF ( DP .EQ. 0 ) THEN

*    Try to open top level file
        CALL HDS_OPEN( FSPEC(:FLEN), MODE, FLOC, STATUS )
        IF ( STATUS .NE. SAI__OK ) THEN
          STATUS = ADI__RETRY
          GOTO 99
        END IF

*  Components or slicing specified?
      ELSE

*     Try to open top level file
        CALL HDS_OPEN( FSPEC(:DP-1), MODE, TLOC, STATUS )
        IF ( STATUS .NE. SAI__OK ) THEN
          STATUS = ADI__RETRY
          GOTO 99
        END IF

        IF ( STATUS .EQ. SAI__OK ) THEN

*        Locate sub-component
          CALL ADI1_FIND( TLOC, FSPEC(DP+1:FLEN), FLOC, STATUS )

*        If successful promote the derived locator to that the file will be
*        closed when FLOC is annulled
          IF ( STATUS .EQ. SAI__OK ) THEN
            CALL DAT_PRMRY( .TRUE., FLOC, .TRUE., STATUS )
            CALL DAT_ANNUL( TLOC, STATUS )
          END IF
        END IF

      END IF

*    Opened ok?
 99   IF ( STATUS .EQ. SAI__OK ) THEN

*      Store the locator
        CALL ADI1_PUTLOC( FLOC, ID, STATUS )

*    End opened ok test
      END IF

      END
