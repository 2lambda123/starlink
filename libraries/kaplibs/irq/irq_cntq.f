      SUBROUTINE IRQ_CNTQ( LOCS, SIZE, SET, STATUS )
*+
*  Name:
*     IRQ_CNTQ

*  Purpose:
*     Count the number of pixels which are set in each bit-plane of the
*     QUALITY component.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ_CNTQ( LOCS, SIZE, SET, STATUS )

*  Description:
*     Each bit plane of the NDF QUALITY component corresponds to a
*     different quality, described by a name stored in the quality
*     names information structure in an NDF extension.  A pixel is set
*     in a bit plane of the QUALITY component if the pixel has the
*     quality associated with the bit plane. This routine counts the
*     number of such pixels in each bit plane.
*
*     Note, write or update access must be available for the NDF (as
*     set up by routine LPG_ASSOC for instance), and the QUALITY
*     component of the NDF must not be mapped on entry to this routine.
*
*  Arguments:
*     LOCS(5) = CHARACTER * ( * ) (Given)
*        An array of 5 HDS locators. These locators identify the NDF
*        and the associated quality name information.  They should have
*        been obtained using routine IRQ_FIND or routine IRQ_NEW.
*     SIZE = INTEGER (Given)
*        The number of bit planes for which a count of set pixels is
*        required.
*     SET( SIZE ) = INTEGER (Returned)
*        The number of pixels holding the corresponding quality in each
*        of bit planes 1 to SIZE. The least significant bit is bit 1.
*        If SIZE is larger than the number of bit planes in the QUALITY
*        component, the unused elements are set to zero.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     2004 September 1 (TIMJ):
*        Use CNF_PVAL
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function

*  Arguments Given:
      CHARACTER LOCS*(*)
      INTEGER SIZE

*  Arguments Returned:
      INTEGER SET( SIZE )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER BIT                ! QUALITY bit (LSB = 1).
      INTEGER CLEAR              ! No. of pixels which do not hold the
                                 ! quality.
      LOGICAL DEF                ! True if QUALITY component is in a
                                 ! defined state.
      INTEGER INDF               ! Identifier for the NDF containing the
                                 ! quality names information.
      INTEGER NEL                ! No. of pixels in the NDF.
      INTEGER PNT                ! Pointer to the mapped QUALITY array.
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Obtain the NDF identifier from LOCS, and check it is still valid.
      CALL IRQ1_INDF( LOCS, INDF, STATUS )

*  Check that the QUALITY component is in a defined state.
      CALL NDF_STATE( INDF, 'QUALITY', DEF, STATUS )
      IF( .NOT. DEF .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = IRQ__QUNDF
         CALL ERR_REP( 'IRQ_CNTQ_ERR1',
     :                 'IRQ_CNTQ: No QUALITY array found in the NDF.',
     :                  STATUS )
      END IF

*  Map the QUALITY component of the NDF.
      CALL NDF_MAP( INDF, 'QUALITY', '_UBYTE', 'READ', PNT, NEL,
     :              STATUS )
      IF ( STATUS .NE. SAI__OK ) GO TO 999

*  Loop round each element of the SET array.
      DO BIT = 1, SIZE

*  If there is a QUALITY bit plane with this index, count the number of
*  set pixels.
         IF( BIT .LE. IRQ__QBITS ) THEN

*  Count the number of pixels which do and do not have the quality.
            CALL IRQ1_QCNT( BIT, NEL, %VAL( CNF_PVAL( PNT ) ), 
     :                      SET( BIT ), CLEAR,
     :                      STATUS )

*  If no such bit exists, set the count to zero.
         ELSE
            SET( BIT ) = 0

         END IF

      END DO

*  Unmap the QUALITY array.
      CALL NDF_UNMAP( INDF, 'QUALITY', STATUS )

*  If an error occur, give context information.
 999  CONTINUE
      IF( STATUS .NE. SAI__OK ) THEN
         CALL NDF_MSG( 'NDF', INDF )
         CALL ERR_REP( 'IRQ_CNTQ_ERR2',
     :             'IRQ_CNTQ: Unable to count QUALITY bits in NDF ^NDF',
     :                  STATUS )
      END IF

      END
