      PROGRAM HDS_TEST
*+
*  Name:
*     HDS_TEST

*  Purpose:
*     Test installation of HDS.

*  Language:
*     Starlink Fortran 77

*  Description:
*     This program should be run after building and installing HDS in
*     order to test for correct installation. Note that this is not an
*     exhaustive test of HDS, but only of its installation.

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     19-AUG-1991 (RFWS):
*        Original version.
*     25-AUG-1992 (RFWS):
*        Changed to use EMS instead of ERR.
*     26-AUG-1992 (RFWS):
*        Removed calls to HDS_START and HDS_STOP - no longer needed.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ public constants
      INCLUDE 'DAT_ERR'          ! DAT_ error codes
      INCLUDE 'CMP_ERR'          ! CMP_ error codes
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER * ( DAT__SZLOC ) LOC1 ! Top-level locator
      CHARACTER * ( DAT__SZLOC ) LOC2 ! Locator for data array
      INTEGER DIM( 2 )           ! Data array dimensions
      INTEGER EL                 ! Number of mapped elements
      INTEGER ISUM               ! Sum of array elements
      INTEGER PNTR               ! Pointer to mapped array
      INTEGER EXITSTATUS         ! Exit status to be reported at end

*  Local Data:
      DATA DIM / 10, 20 /

*.

*  Initialise the global status.
      STATUS = SAI__OK

*  Create a new container file with a data array inside it.
      CALL HDS_NEW( 'hds_test', 'HDS_TEST', 'NDF', 0, DIM, LOC1,
     :              STATUS )
      CALL DAT_NEW( LOC1, 'DATA_ARRAY', '_INTEGER', 2, DIM, STATUS )

*  Find and map the data array.
      CALL DAT_FIND( LOC1, 'DATA_ARRAY', LOC2, STATUS )
      CALL DAT_MAPV( LOC2, '_REAL', 'WRITE', PNTR, EL, STATUS )

*  Initialise the array.
      CALL SETUP( EL, %VAL( CNF_PVAL( PNTR ) ), STATUS )

*  Clean up and close the file.
      CALL DAT_UNMAP( LOC2, STATUS )
      CALL DAT_ANNUL( LOC2, STATUS )
      CALL HDS_CLOSE( LOC1, STATUS )

*  Re-open the file.
      CALL HDS_OPEN( 'hds_test', 'UPDATE', LOC1, STATUS )

*  Find and map the data array.
      CALL DAT_FIND( LOC1, 'DATA_ARRAY', LOC2, STATUS )
      CALL DAT_MAPV( LOC2, '_INTEGER', 'READ', PNTR, EL, STATUS )

*  Sum the data elements.
      CALL SUM( EL, %VAL( CNF_PVAL( PNTR ) ), ISUM, STATUS )

*  Clean up and erase the container file.
      CALL DAT_UNMAP( LOC2, STATUS )
      CALL DAT_ANNUL( LOC2, STATUS )
      CALL HDS_ERASE( LOC1, STATUS )

*  Check if the test ran OK. If so, then report success.
      IF ( ( STATUS .EQ. SAI__OK ) .AND. ( ISUM .EQ. 20100 ) ) THEN
         WRITE( *, * ) '   HDS installation test succeeded.'
         EXITSTATUS = 0

*  Otherwise, report an error.
      ELSE
         IF ( STATUS .EQ. SAI__OK ) STATUS = SAI__ERROR
         CALL EMS_REP( 'HDS_TEST_ERR',
     :   'HDS_TEST: HDS installation test failed.', STATUS )
         EXITSTATUS = 1
      END IF
      
*   Use non-standard but common exit() intrinsic
      CALL EXIT(EXITSTATUS)

      END

      SUBROUTINE SETUP( EL, ARRAY, STATUS )
*+
*  Name:
*     SETUP

*  Purpose:
*     Initialise an array.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL SETUP( EL, ARRAY, STATUS )

*  Description:
*     Set each element of a 1-dimensional array equal to its element
*     number.

*  Arguments:
*     EL = INTEGER (Given)
*        Number of array elements.
*     ARRAY( EL ) = REAL (Returned)
*        Array to be initialised.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     19-AUG-1991 (RFWS):
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
      INTEGER EL

*  Arguments Returned:
      REAL ARRAY( * )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I                  ! Loop counter

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the array.
      DO 1 I = 1, EL
         ARRAY( I ) = REAL( I )
 1    CONTINUE

      END

      SUBROUTINE SUM( EL, ARRAY, ISUM, STATUS )
*+
*  Name:
*     SUM

*  Purpose:
*     Sum the elements of an array.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL SUM( EL, ARRAY, ISUM, STATUS )

*  Description:
*     Return the sum of the elements of a 1-dimensional array.

*  Arguments:
*     EL = INTEGER (Given)
*        Number of array elements.
*     ARRAY( EL ) = INTEGER (Given)
*        Array whose elements are to be summed.
*     ISUM = INTEGER (Returned)
*        Sum of array elements.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     19-AUG-1991 (RFWS):
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
      INTEGER EL
      INTEGER ARRAY( * )

*  Arguments Returned:
      INTEGER ISUM

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I                  ! Loop counter

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise.
      ISUM = 0

*  Sum the array elements.
      DO 1 I = 1, EL
         ISUM = ISUM + ARRAY( I )
 1    CONTINUE

      END
