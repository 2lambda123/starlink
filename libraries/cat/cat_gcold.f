      SUBROUTINE CAT_GCOLD( CI, GI, FROW, NROW, VALS, STATUS )
*+
*  Name:
*     CAT_GCOLD

*  Purpose:
*     Read multiple values for a single column from a catalogue.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CAT_GCOLD( CI, GI, FROW, NROW, VALS, STATUS )

*  Description:
*     This routine reads multiple values for a single column from a 
*     catalogue. 

*  Arguments:
*     CI = INTEGER (Given)
*        The CAT identifier for the catalogue.
*     GI = INTEGER (Given)
*        The CAT identifier for the column to be read.
*     FROW = INTEGER (Given)
*        The index of the first row to read.
*     NROW = INTEGER (Given)
*        The number of rows to read.
*     VALS( NROW ) = DOUBLE PRECISION (Returned)
*        The array to hold the data.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 2000 Central Laboratory of the Research Councils
 
*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     8-SEP-2000 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! VAL__ constants 

      INCLUDE 'CAT_PAR'          ! CAT public constants
      INCLUDE 'CAT1_PAR'         ! CAT internal constants
      INCLUDE 'CAT3_FIT_CMN'     ! CAT internal common blocks
      INCLUDE 'CAT1_CATS_CMN'    ! CAT internal common blocks

*  Arguments Given:
      INTEGER CI
      INTEGER GI
      INTEGER FROW
      INTEGER NROW

*  Arguments Returned:
      DOUBLE PRECISION VALS( NROW )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      INTEGER FITSOK             ! Value of good FITSIO status
      PARAMETER( FITSOK = 0 )

*  Local Variables:
      INTEGER FSTAT              ! FITSIO status
      INTEGER FUNIT              ! Fortran IO unit for the FITS file
      INTEGER I                  ! Loop index
      INTEGER ICOL               ! Column number
      INTEGER SLOT               ! CAT common block index for catalogue
      LOGICAL BAD                ! Column array contains bad values?
      LOGICAL NULL               ! Is this a null element?
*.

*  Check the inherited status. 
      IF ( STATUS .NE. SAI__OK ) RETURN

*  First find the index of the slot within the CAT common blocks which
*  describe this catalogue.
      CALL CAT1_CIELM( CI, SLOT, STATUS )

*  First deal with the special case of FITS format.
      IF( BKTYP__CAT1( SLOT ) .EQ. CAT1__BKFIT ) THEN

*  Get the Fortran IO unit attached to the FITS file. 
         FUNIT = FUNT__CAT3( SLOT )

*  Get the column number associated with CAT column identifier GI.
         ICOL = COLNO__CAT3( GI )

*  Initialise the FITSIO status.  It's not the same as the Starlink
*  status, which is reset by the fixed part.
         FSTAT = FITSOK

*  Read the column data.
         CALL FTGCVD( FUNIT, ICOL, FROW, 1, NROW, VAL__BADD, VALS,
     :                BAD, FSTAT )

*  Handle a bad status.  Negative values are reserved for non-fatal
*  warnings.  
         IF ( FSTAT .GT. FITSOK ) THEN
            CALL MSG_SETI( 'I', ICOL )
            CALL CAT_FIOER( FSTAT, 'CAT_GCOLD_ERR1', 'FTGCVE',
     :                       'Error writing the values for column ^I.',
     :                       STATUS )
         END IF


*  Now use CAT routines directly to process non-FITS catalogues.
      ELSE

*  Loop round the rows.
         DO I = 1, NROW

*  Get the column value.
            CALL CAT_FGT0D( CI, I + FROW - 1, GI, VALS( I ), NULL, 
     :                      STATUS )

*  If this value is null, store a bad value.
            IF( NULL ) VALS( I ) = VAL__BADD

         END DO

      END IF

      END
