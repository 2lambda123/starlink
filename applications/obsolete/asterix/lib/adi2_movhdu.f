      SUBROUTINE ADI2_MOVHDU( FID, HDU, ID, STATUS )
*+
*  Name:
*     ADI2_MOVHDU

*  Purpose:
*     Locate HDU and set FITSIO HDU cursor to that HDU

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL ADI2_MOVHDU( FID, HDU, ID, STATUS )

*  Description:
*     Locates (and creates if necessary) the buffer structures for storing
*     FITS keyword data in FITSfile derived classes

*  Arguments:
*     FID = INTEGER (given)
*        ADI identifier of FITSfile object
*     HDU = CHARACTER*(*) (given)
*        Logical HDU whose keyword this is. Blank for primary
*     ID = INTEGER (returned)
*        ADI identifier of FITSfile object
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
*     {routine_references}...

*  Keywords:
*     package:adi, usage:private, FITS

*  Copyright:
*     {routine_copyright}

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     2 Feb 1995 (DJA):
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
      INTEGER                   FID                     ! File identifier
      CHARACTER*(*)             HDU                     ! HDU name

*  Arguments Returned:
      INTEGER                   ID                      ! Structure identifier

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local Variables:
      INTEGER			FSTAT			! FITSIO status
      INTEGER			HDUTYPE			! HDU type
      INTEGER			LUN			! Logical unit
      INTEGER			NHDU			! HDU number

      LOGICAL			CREATED			! HDU already exists?
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Locate the HDU, forcing its creation
      CALL ADI2_LOCHDU( FID, HDU, ID, STATUS )

*  Get the HDU number
      CALL ADI_CGET0I( FID, 'Nhdu', NHDU, STATUS )

*  Ensure previous HDU's data areas are defined
      IF ( NHDU .GT. 1 ) THEN
        CALL ADI2_CHKPRV( FID, NHDU-1, .FALSE., STATUS )
      END IF

*  Move the specified unit
      CALL ADI2_GETLUN( FID, LUN, STATUS )
      FSTAT = 0
      CALL ADI_CGET0L( ID, 'Created', CREATED, STATUS )
      IF ( CREATED ) THEN
        CALL FTMAHD( LUN, NHDU, HDUTYPE, FSTAT )
        IF ( FSTAT .EQ. 107 ) FSTAT = 0
        CALL FTCRHD( LUN, FSTAT )
        IF ( FSTAT .NE. 0 ) THEN
          CALL ADI2_FITERP( FSTAT, STATUS )
        END IF
        CALL ADI_CPUT0L( ID, 'Created', .TRUE., STATUS )
      ELSE
        CALL FTMAHD( LUN, NHDU, HDUTYPE, FSTAT )
      END IF
      IF ( (FSTAT.NE.0) .AND. (FSTAT.NE.107) ) THEN
        CALL ADI2_FITERP( FSTAT, STATUS )
      ELSE IF ( FSTAT .EQ. 107 ) THEN
        FSTAT = 0
      END IF

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'ADI2_MOVHDU', STATUS )

      END
