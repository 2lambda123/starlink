      SUBROUTINE PGP_DEACT ( STATUS )
*+
*  Name:
*     PGP_DEACT

*  Purpose:
*     De-activate ADAM PGPLOT.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL PGP_DEACT ( STATUS )

*  Description:
*     De-activate ADAM PGPLOT after use by an application.

*  Arguments:
*     STATUS = INTEGER (Given and returned)
*        The global status.

*  Notes:
*     On entry, the STATUS variable holds the global status value.
*     If the given value of STATUS is SAI__OK and the routine fails to
*     complete, STATUS will be set to an appropriate error number.
*     If the given value of STATUS is not SAI__OK, then the routine
*     will still attempt to execute and will return with STATUS
*     unchanged.

*  Algorithm:
*     Free all resources still allocated.
*     Shut down PGPLOT.

*  Authors:
*     DLT: David Terrett (Starlink, RAL)
*     {enter_new_authors_here}

*  History:
*     28-JAN-1992 (DLT):
*        Original.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! SAE Symbolic Constants

      INCLUDE 'PAR_PAR'          ! PAR Symbolic Constants

      INCLUDE 'PGP_ERR'          ! PGP Error codes

      INCLUDE 'pgpenv_par'       ! PGP Environment Symbolic Constants


*  Global Variables:
      INCLUDE 'pgpgo_cmn'        ! PGP Initialisation Switch

      INCLUDE 'pgppa_cmn'        ! PGP Parameter Table

      EXTERNAL PGP1_BLK

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER ISTAT              ! Local status
      INTEGER I                  ! Loop index

*.


*   Save the initial status value
      ISTAT = STATUS
      STATUS = SAI__OK

*   Set error context level
      CALL ERR_MARK

*   Annul all used parameters
      DO I = 1, PGP__MXPAR
         IF ( .NOT. PFREE(I) ) THEN
            CALL PGP_ANNUL ( PDESC(I), STATUS )
         ENDIF
      ENDDO

*   Close PGPLOT
      CALL PGEND

*   Set PGP asleep
      PGPSLP = .TRUE.

*   If initial status was bad, ignore all internal errors
      IF ( ISTAT .NE. SAI__OK ) THEN
         CALL ERR_ANNUL( STATUS )
         STATUS = ISTAT
      ENDIF

*   Release error context
      CALL ERR_RLSE

      END
