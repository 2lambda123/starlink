      SUBROUTINE ADI2_DEFBTB( FID, HDU, NROWS, NFLDS, NAMES, TYPES,
     :                        UNITS, VARIDAT, STATUS )
*+
*  Name:
*     ADI2_DEFBTB

*  Purpose:
*     Define the data area of a BINTABLE HDU

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL ADI2_DEFBTB( FID, HDU, NROWS, NFLDS, NAMES, TYPES,
*                       UNITS, VARIDAT, STATUS )

*  Description:
*     {routine_description}

*  Arguments:
*     FID = INTEGER (given)
*        ADI identifier of FITS file object
*     HDU = CHARACTER*(*) (given)
*        Name of the HDU
*     NROWS = INTEGER (given)
*        Number of rows in the table
*     NFLDS = INTEGER (given)
*        Number of fields in the table
*     NAMES[] = CHARACTER*(*) (given)
*        Names of the table fields
*     TYPES[] = CHARACTER*(*) (given)
*        Types of the table fields
*     UNITS[] = CHARACTER*(*) (given)
*        Units of the table fields
*     VARIDAT = INTEGER (given)
*        Number of variable length data bytes
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
*     ADI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/adi.html

*  Keywords:
*     package:adi, usage:private

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     28 Feb 1995 (DJA):
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
      INTEGER			FID			! See above
      CHARACTER*(*)		HDU			!
      INTEGER			NROWS			!
      INTEGER			NFLDS			!
      CHARACTER*(*)		NAMES(*)		!
      CHARACTER*(*)		TYPES(*)		!
      CHARACTER*(*)		UNITS(*)		!
      INTEGER			VARIDAT			!

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local Variables:
      CHARACTER*40		EXTNAME			! Name of extension

      INTEGER			FSTAT			! FITSIO status
      INTEGER			HID			! HDU identifier
      INTEGER			KCID			! Keyword container
      INTEGER			LUN			! Logical unit
      INTEGER			NKEY			! Number of keywords
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise
      FSTAT = 0

*  Locate the HDU buffer
      CALL ADI2_MOVHDU( FID, HDU, HID, STATUS )

*  Get logical unit
      CALL ADI2_GETLUN( FID, LUN, STATUS )

*  Reserve space for keywords
      CALL ADI_FIND( HID, 'Keys', KCID, STATUS )
      CALL ADI_NCMP( KCID, NKEY, STATUS )
      IF ( NKEY .GT. 0 ) THEN
        CALL FTHDEF( LUN, NKEY, FSTAT )
      END IF
      CALL ADI_ERASE( KCID, STATUS )

*  Define BINTABLE extension
      FSTAT = 0
      CALL ADI_CGET0C( HID, 'Name', EXTNAME, STATUS )
      CALL FTPHBN( LUN, NROWS, NFLDS, NAMES, TYPES, UNITS, EXTNAME,
     :             VARIDAT, FSTAT )
      IF ( FSTAT .EQ. 0 ) THEN
        CALL ADI_CPUT0L( HID, 'DefStart', .TRUE., STATUS )
        CALL ADI_CPUT0L( HID, 'DefEnd', (VARIDAT.EQ.0), STATUS )
      ELSE
        CALL ADI2_FITERP( FSTAT, STATUS )
      END IF

*  Define its size
      CALL FTBDEF( LUN, NFLDS, TYPES, VARIDAT, NROWS, FSTAT )

*  Free the buffer
      CALL ADI_ERASE( HID, STATUS )

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) THEN
        CALL AST_REXIT( 'ADI2_DEFBTB', STATUS )
      END IF

      END
