      SUBROUTINE IRQ1_QMSK( BIT, BAD, SET, SIZE, MASK, QUAL, STATUS )
*+
*  Name:
*     IRQ1_QMSK

*  Purpose:
*     Set a QUALITY bit for pixels determined by a mask.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ1_QMSK( BIT, BAD, SET, SIZE, MASK, QUAL, STATUS )

*  Description:
*     If SET is true then selected pixels in the QUALITY vector have the
*     specified bit set. If SET is false, then the selected pixels have
*     the specified bit cleared. If BAD is true then pixels are selected
*     if they correspond to bad pixels in the mask. If BAD is false then
*     pixels are selected if they do not correspond to bad pixels in
*     the mask.

*  Arguments:
*     BIT = INTEGER (Given)
*        The bit number within the QUALITY component. The least
*        significant bit is called bit 1 (not bit 0).
*     BAD = LOGICAL (Given)
*        If true, then the operation specified by SET is performed on
*        only those pixels in the QUAL vector which correspond to bad
*        pixels in the MASK vector.  If false, then the operation
*        specified by SET is performed on only those pixels in the QUAL
*        vector which do not correspond to bad pixels in the MASK
*        vector.
*     SET = LOGICAL (Given)
*        If true, then the selected pixels have the given bit set,
*        indicating that the corresponding quality is held.  If false,
*        then the selected pixels have the given bit cleared,
*        indicating that the corresponding quality is not held.
*     SIZE = INTEGER (Given)
*        The size of the QUAL and MASK vectors.
*     MASK( SIZE ) = REAL (Given)
*        The mask vector.
*     QUAL( SIZE ) = BYTE (Given and Returned)
*        The QUALITY vector.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  VAX-specific features used:
*     -  Uses BYTE arrays.
*     -  Uses functions IBSET and IBCLR

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     30-JUL-1991 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! Starlink data constants

*  Arguments Given:
      INTEGER BIT
      LOGICAL BAD
      LOGICAL SET
      INTEGER SIZE
      REAL MASK( SIZE )

*  Arguments Given and Returned:
      BYTE QUAL( SIZE )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I                  ! Loop count.
      INTEGER LBIT               ! Corrected bit number.

*  PRIMDAT type conversion functions.
      INCLUDE 'NUM_DEC_CVT'
      INCLUDE 'NUM_DEF_CVT'
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Produce a bit number in the range 0 to (IRQ__QBITS - 1 ).
      LBIT = BIT - 1

*  If the bit is to be set...
      IF( SET ) THEN

*  ... and if bad pixels are to be set...
         IF( BAD ) THEN

*  ...loop round each pixel in the two vectors.
            DO I = 1, SIZE
               IF( MASK( I ) .EQ. VAL__BADR ) THEN
                  QUAL( I ) = NUM_ITOUB( IBSET( NUM_UBTOI( QUAL( I ) ),
     :                                        LBIT ) )
               END IF
            END DO

*  If good pixels are to be set...
         ELSE

*  ...loop round each pixel in the two vectors.
            DO I = 1, SIZE
               IF( MASK( I ) .NE. VAL__BADR ) THEN
                  QUAL( I ) = NUM_ITOUB( IBSET( NUM_UBTOI( QUAL( I ) ),
     :                                        LBIT ) )
               END IF
            END DO

         END IF

*  If the bit is to be cleared...
      ELSE

*  ... and if bad pixels are to be cleared...
         IF( BAD ) THEN

*  ...loop round each pixel in the two vectors.
            DO I = 1, SIZE
               IF( MASK( I ) .EQ. VAL__BADR ) THEN
                  QUAL( I ) = NUM_ITOUB( IBCLR( NUM_UBTOI( QUAL( I ) ),
     :                                        LBIT ) )
               END IF
            END DO

*  If good pixels are to be cleared...
         ELSE

*  ...loop round each pixel in the two vectors.
            DO I = 1, SIZE
               IF( MASK( I ) .NE. VAL__BADR ) THEN
                  QUAL( I ) = NUM_ITOUB( IBCLR( NUM_UBTOI( QUAL( I ) ),
     :                                        LBIT ) )
               END IF
            END DO

         END IF

      END IF

      END
