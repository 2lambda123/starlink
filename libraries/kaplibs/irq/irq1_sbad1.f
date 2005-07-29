      SUBROUTINE IRQ1_SBAD1B( HELD, NMASK, MASK, NOPC, OPCODE, MXSTK,
     :                       SIZE, QUAL, WORK, VEC, ALLBAD, NOBAD,
     :                       STATUS )
*+
*  Name:
*     IRQ1_SBAD1B

*  Purpose:
*     Set pixels bad which satisfy a given quality expression.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ1_SBAD1B( HELD, NMASK, MASK, NOPC, OPCODE, MXSTK, SIZE,
*                      QUAL, WORK, VEC, ALLBAD, NOBAD, STATUS )

*  Description:
*     This routine does the work for IRQ_SBAD.

*  Arguments:
*     HELD = LOGICAL (Given)
*        If true then those VEC pixels which hold a quality satisfying
*        the supplied quality expression are set bad. Otherwise, those
*        pixels which don't hold such a quality are set bad.
*     NMASK = INTEGER (Given)
*        No. of different masks used in the quality expression.
*     MASK( * ) = INTEGER (Given)
*        Masks defining each quality name. A bit-wise AND is performed
*        between the mask and a value from the QUALITY array.  If the
*        result is equal to the mask, then the quality is held.
*     NOPC = INTEGER (Given)
*        The number of op. codes in OPCODE.
*     OPCODE( NOPC ) = INTEGER (Given)
*        The codes which define the operations which must be performed
*        in order to evaluate the quality expression.
*     MXSTK = INTEGER (Given)
*        The maximum stack size needed to evaluate the quality
*        expression.
*     SIZE = INTEGER (Given)
*        The total number of pixels in VEC and QUAL.
*     QUAL( SIZE ) = BYTE (Given)
*        The QUALITY component from the NDF.
*     WORK( SIZE, MXSTK ) = LOGICAL (Given and Returned)
*        Work space.
*     VEC( SIZE ) = BYTE (Given and Returned)
*        The data to be set bad, depending on the corresponding quality
*        values stored in the NDF. Pixels which are not set bad are
*        left unchanged. It is the same size as the NDF, and
*        corresponds pixel-for-pixel with the vectorised NDF.
*     ALLBAD = LOGICAL (Returned)
*        Returned true if all pixels in VEC are returned with bad
*        values. False if any good pixel values are returned.
*     NOBAD = LOGICAL (Returned)
*        Returned true if no pixels in VEC are returned with bad
*        values. False if any bad pixel values are returned.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*   VAX-based features used:
*      -  Uses BYTE arrays.
*      -  Uses function IAND

*  Authors:
*     DSB: David Berry (STARLINK)
*     BKM: Brian McIlwrath (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     10-MAY-1996 (BKM):
*        Revised for Linux g77 which (currently) has IAND but no IZEXT
*    27-JAN-2002 (DSB):
*        Made generic.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! Starlink data constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Arguments Given:
      LOGICAL HELD
      INTEGER NMASK
      INTEGER MASK( * )
      INTEGER NOPC
      INTEGER OPCODE( NOPC )
      INTEGER MXSTK
      INTEGER SIZE
      BYTE QUAL( SIZE )

*  Arguments Given and Returned:
      LOGICAL WORK( SIZE, MXSTK )

*  Arguments Returned:
      BYTE VEC( SIZE )
      LOGICAL ALLBAD
      LOGICAL NOBAD

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER EL                 ! Current element in QUALITY array.
      INTEGER IOP                ! Index of current op code.
      INTEGER MSK                ! Current mask.
      INTEGER IQUAL              ! Zero extended integer from QUAL byte
      INTEGER NEWTOS             ! New value for TOS after operation is
                                 ! completed.
      INTEGER NXTMSK             ! Index of next mask to be used.
      INTEGER TEMP               ! Temporary logical storage.
      INTEGER TOS                ! Current position of top of stack.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the position of the top of the evaluation and mask stacks.
      TOS = 0
      NXTMSK = 0

*  Loop round each operation in OPCODE.
      DO IOP = 1, NOPC

*  Check for stack underflow.
         IF( TOS .LT. 0 ) THEN
            STATUS = IRQ__STKUN
            CALL ERR_REP( 'IRQ1_SBAD1B_ERR1', 'IRQ1_SBAD1B: '//
     :                    'Stack underflow (programming error)',
     :                    STATUS )
            GO TO 180
         END IF

*  Execute the next operation. (op codes are in the range 1 to 17).
         GO TO ( 10,  20,  30,  40,  50, 60, 70, 80, 90, 100, 110, 120,
     :           130, 140, 150, 160, 170 )
     :          OPCODE( IOP )

*  LDQ - Load single quality bit on to top of stack.
 10      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = ( IAND( IQUAL, MSK ) .EQ. MSK )
         END DO

         GO TO 170

*  RET- End expression. Use top-of-stack to create the output.
 20      CONTINUE

         ALLBAD = .TRUE.
         NOBAD = .TRUE.

         DO EL = 1, SIZE
            IF( WORK( EL, TOS ) .EQV. HELD ) VEC( EL ) = VAL__BADB

            IF( VEC( EL ) .EQ. VAL__BADB ) THEN
               NOBAD = .FALSE.

            ELSE
               ALLBAD = .FALSE.

            END IF

         END DO

         GO TO 170

*  Load constant .FALSE. on to top-of-stack.
 30      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .FALSE.
         END DO

         GO TO 170

*  Load constant .TRUE. on to top-of-stack.
 40      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .TRUE.
         END DO

         GO TO 170

*  Close brackets. Ignore.
 50      CONTINUE
         GO TO 170

*  Open brackets. Ignore.
 60      CONTINUE
         GO TO 170

*  Equivalence operator.
 70      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .EQV. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  Exclusive OR operator.
 80      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK(EL, TOS) .NEQV. WORK(EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  OR operator.
 90      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .OR. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  AND operator.
 100     CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .AND. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  NOT operator.
 110     CONTINUE

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .NOT. WORK( EL, TOS )
         END DO

         GO TO 170

*  LDQE - Load two quality bits with build in EQV operation.
  120    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            TEMP = IAND( IQUAL, MSK )
            WORK( EL, TOS ) = ( TEMP .EQ. MSK ) .OR.
     :                        ( TEMP .EQ. 0 )
         END DO

         GO TO 170

*  LDQX - Load two quality bits with build in XOR operation.
  130    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            TEMP = IAND( IQUAL, MSK )
            WORK( EL, TOS ) = ( TEMP .NE. MSK ) .AND.
     :                        ( TEMP .NE. 0 )
         END DO

         GO TO 170

*  LDQO - Load multiple quality bits with build in OR operation.
  140    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .NE. 0
         END DO

         GO TO 170

*  LDQA - Load multiple quality bits with build in AND operation.
  150    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .EQ. MSK
         END DO

         GO TO 170

*  LDQN - Load a single quality bit with build in NOT operation.
  160    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .EQ. 0
         END DO

         GO TO 170

*  NULL - Do nothing.
 170     CONTINUE

      END DO

*  Stack overflow. Report an error.
 180  CONTINUE
      IF( STATUS .EQ.  IRQ__STKOV ) THEN
         CALL ERR_REP( 'IRQ1_SBAD1B_ERR2', 'IRQ1_SBAD1B: Stack '//
     :                 'overflow (programming error).', STATUS )
      END IF

      END
      SUBROUTINE IRQ1_SBAD1UB( HELD, NMASK, MASK, NOPC, OPCODE, MXSTK,
     :                       SIZE, QUAL, WORK, VEC, ALLBAD, NOBAD,
     :                       STATUS )
*+
*  Name:
*     IRQ1_SBAD1UB

*  Purpose:
*     Set pixels bad which satisfy a given quality expression.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ1_SBAD1UB( HELD, NMASK, MASK, NOPC, OPCODE, MXSTK, SIZE,
*                      QUAL, WORK, VEC, ALLBAD, NOBAD, STATUS )

*  Description:
*     This routine does the work for IRQ_SBAD.

*  Arguments:
*     HELD = LOGICAL (Given)
*        If true then those VEC pixels which hold a quality satisfying
*        the supplied quality expression are set bad. Otherwise, those
*        pixels which don't hold such a quality are set bad.
*     NMASK = INTEGER (Given)
*        No. of different masks used in the quality expression.
*     MASK( * ) = INTEGER (Given)
*        Masks defining each quality name. A bit-wise AND is performed
*        between the mask and a value from the QUALITY array.  If the
*        result is equal to the mask, then the quality is held.
*     NOPC = INTEGER (Given)
*        The number of op. codes in OPCODE.
*     OPCODE( NOPC ) = INTEGER (Given)
*        The codes which define the operations which must be performed
*        in order to evaluate the quality expression.
*     MXSTK = INTEGER (Given)
*        The maximum stack size needed to evaluate the quality
*        expression.
*     SIZE = INTEGER (Given)
*        The total number of pixels in VEC and QUAL.
*     QUAL( SIZE ) = BYTE (Given)
*        The QUALITY component from the NDF.
*     WORK( SIZE, MXSTK ) = LOGICAL (Given and Returned)
*        Work space.
*     VEC( SIZE ) = BYTE (Given and Returned)
*        The data to be set bad, depending on the corresponding quality
*        values stored in the NDF. Pixels which are not set bad are
*        left unchanged. It is the same size as the NDF, and
*        corresponds pixel-for-pixel with the vectorised NDF.
*     ALLBAD = LOGICAL (Returned)
*        Returned true if all pixels in VEC are returned with bad
*        values. False if any good pixel values are returned.
*     NOBAD = LOGICAL (Returned)
*        Returned true if no pixels in VEC are returned with bad
*        values. False if any bad pixel values are returned.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*   VAX-based features used:
*      -  Uses BYTE arrays.
*      -  Uses function IAND

*  Authors:
*     DSB: David Berry (STARLINK)
*     BKM: Brian McIlwrath (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     10-MAY-1996 (BKM):
*        Revised for Linux g77 which (currently) has IAND but no IZEXT
*    27-JAN-2002 (DSB):
*        Made generic.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! Starlink data constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Arguments Given:
      LOGICAL HELD
      INTEGER NMASK
      INTEGER MASK( * )
      INTEGER NOPC
      INTEGER OPCODE( NOPC )
      INTEGER MXSTK
      INTEGER SIZE
      BYTE QUAL( SIZE )

*  Arguments Given and Returned:
      LOGICAL WORK( SIZE, MXSTK )

*  Arguments Returned:
      BYTE VEC( SIZE )
      LOGICAL ALLBAD
      LOGICAL NOBAD

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER EL                 ! Current element in QUALITY array.
      INTEGER IOP                ! Index of current op code.
      INTEGER MSK                ! Current mask.
      INTEGER IQUAL              ! Zero extended integer from QUAL byte
      INTEGER NEWTOS             ! New value for TOS after operation is
                                 ! completed.
      INTEGER NXTMSK             ! Index of next mask to be used.
      INTEGER TEMP               ! Temporary logical storage.
      INTEGER TOS                ! Current position of top of stack.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the position of the top of the evaluation and mask stacks.
      TOS = 0
      NXTMSK = 0

*  Loop round each operation in OPCODE.
      DO IOP = 1, NOPC

*  Check for stack underflow.
         IF( TOS .LT. 0 ) THEN
            STATUS = IRQ__STKUN
            CALL ERR_REP( 'IRQ1_SBAD1UB_ERR1', 'IRQ1_SBAD1UB: '//
     :                    'Stack underflow (programming error)',
     :                    STATUS )
            GO TO 180
         END IF

*  Execute the next operation. (op codes are in the range 1 to 17).
         GO TO ( 10,  20,  30,  40,  50, 60, 70, 80, 90, 100, 110, 120,
     :           130, 140, 150, 160, 170 )
     :          OPCODE( IOP )

*  LDQ - Load single quality bit on to top of stack.
 10      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = ( IAND( IQUAL, MSK ) .EQ. MSK )
         END DO

         GO TO 170

*  RET- End expression. Use top-of-stack to create the output.
 20      CONTINUE

         ALLBAD = .TRUE.
         NOBAD = .TRUE.

         DO EL = 1, SIZE
            IF( WORK( EL, TOS ) .EQV. HELD ) VEC( EL ) = VAL__BADUB

            IF( VEC( EL ) .EQ. VAL__BADUB ) THEN
               NOBAD = .FALSE.

            ELSE
               ALLBAD = .FALSE.

            END IF

         END DO

         GO TO 170

*  Load constant .FALSE. on to top-of-stack.
 30      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .FALSE.
         END DO

         GO TO 170

*  Load constant .TRUE. on to top-of-stack.
 40      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .TRUE.
         END DO

         GO TO 170

*  Close brackets. Ignore.
 50      CONTINUE
         GO TO 170

*  Open brackets. Ignore.
 60      CONTINUE
         GO TO 170

*  Equivalence operator.
 70      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .EQV. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  Exclusive OR operator.
 80      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK(EL, TOS) .NEQV. WORK(EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  OR operator.
 90      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .OR. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  AND operator.
 100     CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .AND. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  NOT operator.
 110     CONTINUE

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .NOT. WORK( EL, TOS )
         END DO

         GO TO 170

*  LDQE - Load two quality bits with build in EQV operation.
  120    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            TEMP = IAND( IQUAL, MSK )
            WORK( EL, TOS ) = ( TEMP .EQ. MSK ) .OR.
     :                        ( TEMP .EQ. 0 )
         END DO

         GO TO 170

*  LDQX - Load two quality bits with build in XOR operation.
  130    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            TEMP = IAND( IQUAL, MSK )
            WORK( EL, TOS ) = ( TEMP .NE. MSK ) .AND.
     :                        ( TEMP .NE. 0 )
         END DO

         GO TO 170

*  LDQO - Load multiple quality bits with build in OR operation.
  140    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .NE. 0
         END DO

         GO TO 170

*  LDQA - Load multiple quality bits with build in AND operation.
  150    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .EQ. MSK
         END DO

         GO TO 170

*  LDQN - Load a single quality bit with build in NOT operation.
  160    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .EQ. 0
         END DO

         GO TO 170

*  NULL - Do nothing.
 170     CONTINUE

      END DO

*  Stack overflow. Report an error.
 180  CONTINUE
      IF( STATUS .EQ.  IRQ__STKOV ) THEN
         CALL ERR_REP( 'IRQ1_SBAD1UB_ERR2', 'IRQ1_SBAD1UB: Stack '//
     :                 'overflow (programming error).', STATUS )
      END IF

      END
      SUBROUTINE IRQ1_SBAD1D( HELD, NMASK, MASK, NOPC, OPCODE, MXSTK,
     :                       SIZE, QUAL, WORK, VEC, ALLBAD, NOBAD,
     :                       STATUS )
*+
*  Name:
*     IRQ1_SBAD1D

*  Purpose:
*     Set pixels bad which satisfy a given quality expression.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ1_SBAD1D( HELD, NMASK, MASK, NOPC, OPCODE, MXSTK, SIZE,
*                      QUAL, WORK, VEC, ALLBAD, NOBAD, STATUS )

*  Description:
*     This routine does the work for IRQ_SBAD.

*  Arguments:
*     HELD = LOGICAL (Given)
*        If true then those VEC pixels which hold a quality satisfying
*        the supplied quality expression are set bad. Otherwise, those
*        pixels which don't hold such a quality are set bad.
*     NMASK = INTEGER (Given)
*        No. of different masks used in the quality expression.
*     MASK( * ) = INTEGER (Given)
*        Masks defining each quality name. A bit-wise AND is performed
*        between the mask and a value from the QUALITY array.  If the
*        result is equal to the mask, then the quality is held.
*     NOPC = INTEGER (Given)
*        The number of op. codes in OPCODE.
*     OPCODE( NOPC ) = INTEGER (Given)
*        The codes which define the operations which must be performed
*        in order to evaluate the quality expression.
*     MXSTK = INTEGER (Given)
*        The maximum stack size needed to evaluate the quality
*        expression.
*     SIZE = INTEGER (Given)
*        The total number of pixels in VEC and QUAL.
*     QUAL( SIZE ) = BYTE (Given)
*        The QUALITY component from the NDF.
*     WORK( SIZE, MXSTK ) = LOGICAL (Given and Returned)
*        Work space.
*     VEC( SIZE ) = DOUBLE PRECISION (Given and Returned)
*        The data to be set bad, depending on the corresponding quality
*        values stored in the NDF. Pixels which are not set bad are
*        left unchanged. It is the same size as the NDF, and
*        corresponds pixel-for-pixel with the vectorised NDF.
*     ALLBAD = LOGICAL (Returned)
*        Returned true if all pixels in VEC are returned with bad
*        values. False if any good pixel values are returned.
*     NOBAD = LOGICAL (Returned)
*        Returned true if no pixels in VEC are returned with bad
*        values. False if any bad pixel values are returned.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*   VAX-based features used:
*      -  Uses BYTE arrays.
*      -  Uses function IAND

*  Authors:
*     DSB: David Berry (STARLINK)
*     BKM: Brian McIlwrath (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     10-MAY-1996 (BKM):
*        Revised for Linux g77 which (currently) has IAND but no IZEXT
*    27-JAN-2002 (DSB):
*        Made generic.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! Starlink data constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Arguments Given:
      LOGICAL HELD
      INTEGER NMASK
      INTEGER MASK( * )
      INTEGER NOPC
      INTEGER OPCODE( NOPC )
      INTEGER MXSTK
      INTEGER SIZE
      BYTE QUAL( SIZE )

*  Arguments Given and Returned:
      LOGICAL WORK( SIZE, MXSTK )

*  Arguments Returned:
      DOUBLE PRECISION VEC( SIZE )
      LOGICAL ALLBAD
      LOGICAL NOBAD

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER EL                 ! Current element in QUALITY array.
      INTEGER IOP                ! Index of current op code.
      INTEGER MSK                ! Current mask.
      INTEGER IQUAL              ! Zero extended integer from QUAL byte
      INTEGER NEWTOS             ! New value for TOS after operation is
                                 ! completed.
      INTEGER NXTMSK             ! Index of next mask to be used.
      INTEGER TEMP               ! Temporary logical storage.
      INTEGER TOS                ! Current position of top of stack.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the position of the top of the evaluation and mask stacks.
      TOS = 0
      NXTMSK = 0

*  Loop round each operation in OPCODE.
      DO IOP = 1, NOPC

*  Check for stack underflow.
         IF( TOS .LT. 0 ) THEN
            STATUS = IRQ__STKUN
            CALL ERR_REP( 'IRQ1_SBAD1D_ERR1', 'IRQ1_SBAD1D: '//
     :                    'Stack underflow (programming error)',
     :                    STATUS )
            GO TO 180
         END IF

*  Execute the next operation. (op codes are in the range 1 to 17).
         GO TO ( 10,  20,  30,  40,  50, 60, 70, 80, 90, 100, 110, 120,
     :           130, 140, 150, 160, 170 )
     :          OPCODE( IOP )

*  LDQ - Load single quality bit on to top of stack.
 10      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = ( IAND( IQUAL, MSK ) .EQ. MSK )
         END DO

         GO TO 170

*  RET- End expression. Use top-of-stack to create the output.
 20      CONTINUE

         ALLBAD = .TRUE.
         NOBAD = .TRUE.

         DO EL = 1, SIZE
            IF( WORK( EL, TOS ) .EQV. HELD ) VEC( EL ) = VAL__BADD

            IF( VEC( EL ) .EQ. VAL__BADD ) THEN
               NOBAD = .FALSE.

            ELSE
               ALLBAD = .FALSE.

            END IF

         END DO

         GO TO 170

*  Load constant .FALSE. on to top-of-stack.
 30      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .FALSE.
         END DO

         GO TO 170

*  Load constant .TRUE. on to top-of-stack.
 40      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .TRUE.
         END DO

         GO TO 170

*  Close brackets. Ignore.
 50      CONTINUE
         GO TO 170

*  Open brackets. Ignore.
 60      CONTINUE
         GO TO 170

*  Equivalence operator.
 70      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .EQV. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  Exclusive OR operator.
 80      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK(EL, TOS) .NEQV. WORK(EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  OR operator.
 90      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .OR. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  AND operator.
 100     CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .AND. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  NOT operator.
 110     CONTINUE

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .NOT. WORK( EL, TOS )
         END DO

         GO TO 170

*  LDQE - Load two quality bits with build in EQV operation.
  120    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            TEMP = IAND( IQUAL, MSK )
            WORK( EL, TOS ) = ( TEMP .EQ. MSK ) .OR.
     :                        ( TEMP .EQ. 0 )
         END DO

         GO TO 170

*  LDQX - Load two quality bits with build in XOR operation.
  130    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            TEMP = IAND( IQUAL, MSK )
            WORK( EL, TOS ) = ( TEMP .NE. MSK ) .AND.
     :                        ( TEMP .NE. 0 )
         END DO

         GO TO 170

*  LDQO - Load multiple quality bits with build in OR operation.
  140    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .NE. 0
         END DO

         GO TO 170

*  LDQA - Load multiple quality bits with build in AND operation.
  150    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .EQ. MSK
         END DO

         GO TO 170

*  LDQN - Load a single quality bit with build in NOT operation.
  160    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .EQ. 0
         END DO

         GO TO 170

*  NULL - Do nothing.
 170     CONTINUE

      END DO

*  Stack overflow. Report an error.
 180  CONTINUE
      IF( STATUS .EQ.  IRQ__STKOV ) THEN
         CALL ERR_REP( 'IRQ1_SBAD1D_ERR2', 'IRQ1_SBAD1D: Stack '//
     :                 'overflow (programming error).', STATUS )
      END IF

      END
      SUBROUTINE IRQ1_SBAD1I( HELD, NMASK, MASK, NOPC, OPCODE, MXSTK,
     :                       SIZE, QUAL, WORK, VEC, ALLBAD, NOBAD,
     :                       STATUS )
*+
*  Name:
*     IRQ1_SBAD1I

*  Purpose:
*     Set pixels bad which satisfy a given quality expression.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ1_SBAD1I( HELD, NMASK, MASK, NOPC, OPCODE, MXSTK, SIZE,
*                      QUAL, WORK, VEC, ALLBAD, NOBAD, STATUS )

*  Description:
*     This routine does the work for IRQ_SBAD.

*  Arguments:
*     HELD = LOGICAL (Given)
*        If true then those VEC pixels which hold a quality satisfying
*        the supplied quality expression are set bad. Otherwise, those
*        pixels which don't hold such a quality are set bad.
*     NMASK = INTEGER (Given)
*        No. of different masks used in the quality expression.
*     MASK( * ) = INTEGER (Given)
*        Masks defining each quality name. A bit-wise AND is performed
*        between the mask and a value from the QUALITY array.  If the
*        result is equal to the mask, then the quality is held.
*     NOPC = INTEGER (Given)
*        The number of op. codes in OPCODE.
*     OPCODE( NOPC ) = INTEGER (Given)
*        The codes which define the operations which must be performed
*        in order to evaluate the quality expression.
*     MXSTK = INTEGER (Given)
*        The maximum stack size needed to evaluate the quality
*        expression.
*     SIZE = INTEGER (Given)
*        The total number of pixels in VEC and QUAL.
*     QUAL( SIZE ) = BYTE (Given)
*        The QUALITY component from the NDF.
*     WORK( SIZE, MXSTK ) = LOGICAL (Given and Returned)
*        Work space.
*     VEC( SIZE ) = INTEGER (Given and Returned)
*        The data to be set bad, depending on the corresponding quality
*        values stored in the NDF. Pixels which are not set bad are
*        left unchanged. It is the same size as the NDF, and
*        corresponds pixel-for-pixel with the vectorised NDF.
*     ALLBAD = LOGICAL (Returned)
*        Returned true if all pixels in VEC are returned with bad
*        values. False if any good pixel values are returned.
*     NOBAD = LOGICAL (Returned)
*        Returned true if no pixels in VEC are returned with bad
*        values. False if any bad pixel values are returned.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*   VAX-based features used:
*      -  Uses BYTE arrays.
*      -  Uses function IAND

*  Authors:
*     DSB: David Berry (STARLINK)
*     BKM: Brian McIlwrath (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     10-MAY-1996 (BKM):
*        Revised for Linux g77 which (currently) has IAND but no IZEXT
*    27-JAN-2002 (DSB):
*        Made generic.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! Starlink data constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Arguments Given:
      LOGICAL HELD
      INTEGER NMASK
      INTEGER MASK( * )
      INTEGER NOPC
      INTEGER OPCODE( NOPC )
      INTEGER MXSTK
      INTEGER SIZE
      BYTE QUAL( SIZE )

*  Arguments Given and Returned:
      LOGICAL WORK( SIZE, MXSTK )

*  Arguments Returned:
      INTEGER VEC( SIZE )
      LOGICAL ALLBAD
      LOGICAL NOBAD

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER EL                 ! Current element in QUALITY array.
      INTEGER IOP                ! Index of current op code.
      INTEGER MSK                ! Current mask.
      INTEGER IQUAL              ! Zero extended integer from QUAL byte
      INTEGER NEWTOS             ! New value for TOS after operation is
                                 ! completed.
      INTEGER NXTMSK             ! Index of next mask to be used.
      INTEGER TEMP               ! Temporary logical storage.
      INTEGER TOS                ! Current position of top of stack.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the position of the top of the evaluation and mask stacks.
      TOS = 0
      NXTMSK = 0

*  Loop round each operation in OPCODE.
      DO IOP = 1, NOPC

*  Check for stack underflow.
         IF( TOS .LT. 0 ) THEN
            STATUS = IRQ__STKUN
            CALL ERR_REP( 'IRQ1_SBAD1I_ERR1', 'IRQ1_SBAD1I: '//
     :                    'Stack underflow (programming error)',
     :                    STATUS )
            GO TO 180
         END IF

*  Execute the next operation. (op codes are in the range 1 to 17).
         GO TO ( 10,  20,  30,  40,  50, 60, 70, 80, 90, 100, 110, 120,
     :           130, 140, 150, 160, 170 )
     :          OPCODE( IOP )

*  LDQ - Load single quality bit on to top of stack.
 10      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = ( IAND( IQUAL, MSK ) .EQ. MSK )
         END DO

         GO TO 170

*  RET- End expression. Use top-of-stack to create the output.
 20      CONTINUE

         ALLBAD = .TRUE.
         NOBAD = .TRUE.

         DO EL = 1, SIZE
            IF( WORK( EL, TOS ) .EQV. HELD ) VEC( EL ) = VAL__BADI

            IF( VEC( EL ) .EQ. VAL__BADI ) THEN
               NOBAD = .FALSE.

            ELSE
               ALLBAD = .FALSE.

            END IF

         END DO

         GO TO 170

*  Load constant .FALSE. on to top-of-stack.
 30      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .FALSE.
         END DO

         GO TO 170

*  Load constant .TRUE. on to top-of-stack.
 40      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .TRUE.
         END DO

         GO TO 170

*  Close brackets. Ignore.
 50      CONTINUE
         GO TO 170

*  Open brackets. Ignore.
 60      CONTINUE
         GO TO 170

*  Equivalence operator.
 70      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .EQV. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  Exclusive OR operator.
 80      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK(EL, TOS) .NEQV. WORK(EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  OR operator.
 90      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .OR. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  AND operator.
 100     CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .AND. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  NOT operator.
 110     CONTINUE

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .NOT. WORK( EL, TOS )
         END DO

         GO TO 170

*  LDQE - Load two quality bits with build in EQV operation.
  120    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            TEMP = IAND( IQUAL, MSK )
            WORK( EL, TOS ) = ( TEMP .EQ. MSK ) .OR.
     :                        ( TEMP .EQ. 0 )
         END DO

         GO TO 170

*  LDQX - Load two quality bits with build in XOR operation.
  130    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            TEMP = IAND( IQUAL, MSK )
            WORK( EL, TOS ) = ( TEMP .NE. MSK ) .AND.
     :                        ( TEMP .NE. 0 )
         END DO

         GO TO 170

*  LDQO - Load multiple quality bits with build in OR operation.
  140    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .NE. 0
         END DO

         GO TO 170

*  LDQA - Load multiple quality bits with build in AND operation.
  150    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .EQ. MSK
         END DO

         GO TO 170

*  LDQN - Load a single quality bit with build in NOT operation.
  160    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .EQ. 0
         END DO

         GO TO 170

*  NULL - Do nothing.
 170     CONTINUE

      END DO

*  Stack overflow. Report an error.
 180  CONTINUE
      IF( STATUS .EQ.  IRQ__STKOV ) THEN
         CALL ERR_REP( 'IRQ1_SBAD1I_ERR2', 'IRQ1_SBAD1I: Stack '//
     :                 'overflow (programming error).', STATUS )
      END IF

      END
      SUBROUTINE IRQ1_SBAD1R( HELD, NMASK, MASK, NOPC, OPCODE, MXSTK,
     :                       SIZE, QUAL, WORK, VEC, ALLBAD, NOBAD,
     :                       STATUS )
*+
*  Name:
*     IRQ1_SBAD1R

*  Purpose:
*     Set pixels bad which satisfy a given quality expression.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ1_SBAD1R( HELD, NMASK, MASK, NOPC, OPCODE, MXSTK, SIZE,
*                      QUAL, WORK, VEC, ALLBAD, NOBAD, STATUS )

*  Description:
*     This routine does the work for IRQ_SBAD.

*  Arguments:
*     HELD = LOGICAL (Given)
*        If true then those VEC pixels which hold a quality satisfying
*        the supplied quality expression are set bad. Otherwise, those
*        pixels which don't hold such a quality are set bad.
*     NMASK = INTEGER (Given)
*        No. of different masks used in the quality expression.
*     MASK( * ) = INTEGER (Given)
*        Masks defining each quality name. A bit-wise AND is performed
*        between the mask and a value from the QUALITY array.  If the
*        result is equal to the mask, then the quality is held.
*     NOPC = INTEGER (Given)
*        The number of op. codes in OPCODE.
*     OPCODE( NOPC ) = INTEGER (Given)
*        The codes which define the operations which must be performed
*        in order to evaluate the quality expression.
*     MXSTK = INTEGER (Given)
*        The maximum stack size needed to evaluate the quality
*        expression.
*     SIZE = INTEGER (Given)
*        The total number of pixels in VEC and QUAL.
*     QUAL( SIZE ) = BYTE (Given)
*        The QUALITY component from the NDF.
*     WORK( SIZE, MXSTK ) = LOGICAL (Given and Returned)
*        Work space.
*     VEC( SIZE ) = REAL (Given and Returned)
*        The data to be set bad, depending on the corresponding quality
*        values stored in the NDF. Pixels which are not set bad are
*        left unchanged. It is the same size as the NDF, and
*        corresponds pixel-for-pixel with the vectorised NDF.
*     ALLBAD = LOGICAL (Returned)
*        Returned true if all pixels in VEC are returned with bad
*        values. False if any good pixel values are returned.
*     NOBAD = LOGICAL (Returned)
*        Returned true if no pixels in VEC are returned with bad
*        values. False if any bad pixel values are returned.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*   VAX-based features used:
*      -  Uses BYTE arrays.
*      -  Uses function IAND

*  Authors:
*     DSB: David Berry (STARLINK)
*     BKM: Brian McIlwrath (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     10-MAY-1996 (BKM):
*        Revised for Linux g77 which (currently) has IAND but no IZEXT
*    27-JAN-2002 (DSB):
*        Made generic.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! Starlink data constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Arguments Given:
      LOGICAL HELD
      INTEGER NMASK
      INTEGER MASK( * )
      INTEGER NOPC
      INTEGER OPCODE( NOPC )
      INTEGER MXSTK
      INTEGER SIZE
      BYTE QUAL( SIZE )

*  Arguments Given and Returned:
      LOGICAL WORK( SIZE, MXSTK )

*  Arguments Returned:
      REAL VEC( SIZE )
      LOGICAL ALLBAD
      LOGICAL NOBAD

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER EL                 ! Current element in QUALITY array.
      INTEGER IOP                ! Index of current op code.
      INTEGER MSK                ! Current mask.
      INTEGER IQUAL              ! Zero extended integer from QUAL byte
      INTEGER NEWTOS             ! New value for TOS after operation is
                                 ! completed.
      INTEGER NXTMSK             ! Index of next mask to be used.
      INTEGER TEMP               ! Temporary logical storage.
      INTEGER TOS                ! Current position of top of stack.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the position of the top of the evaluation and mask stacks.
      TOS = 0
      NXTMSK = 0

*  Loop round each operation in OPCODE.
      DO IOP = 1, NOPC

*  Check for stack underflow.
         IF( TOS .LT. 0 ) THEN
            STATUS = IRQ__STKUN
            CALL ERR_REP( 'IRQ1_SBAD1R_ERR1', 'IRQ1_SBAD1R: '//
     :                    'Stack underflow (programming error)',
     :                    STATUS )
            GO TO 180
         END IF

*  Execute the next operation. (op codes are in the range 1 to 17).
         GO TO ( 10,  20,  30,  40,  50, 60, 70, 80, 90, 100, 110, 120,
     :           130, 140, 150, 160, 170 )
     :          OPCODE( IOP )

*  LDQ - Load single quality bit on to top of stack.
 10      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = ( IAND( IQUAL, MSK ) .EQ. MSK )
         END DO

         GO TO 170

*  RET- End expression. Use top-of-stack to create the output.
 20      CONTINUE

         ALLBAD = .TRUE.
         NOBAD = .TRUE.

         DO EL = 1, SIZE
            IF( WORK( EL, TOS ) .EQV. HELD ) VEC( EL ) = VAL__BADR

            IF( VEC( EL ) .EQ. VAL__BADR ) THEN
               NOBAD = .FALSE.

            ELSE
               ALLBAD = .FALSE.

            END IF

         END DO

         GO TO 170

*  Load constant .FALSE. on to top-of-stack.
 30      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .FALSE.
         END DO

         GO TO 170

*  Load constant .TRUE. on to top-of-stack.
 40      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .TRUE.
         END DO

         GO TO 170

*  Close brackets. Ignore.
 50      CONTINUE
         GO TO 170

*  Open brackets. Ignore.
 60      CONTINUE
         GO TO 170

*  Equivalence operator.
 70      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .EQV. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  Exclusive OR operator.
 80      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK(EL, TOS) .NEQV. WORK(EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  OR operator.
 90      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .OR. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  AND operator.
 100     CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .AND. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  NOT operator.
 110     CONTINUE

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .NOT. WORK( EL, TOS )
         END DO

         GO TO 170

*  LDQE - Load two quality bits with build in EQV operation.
  120    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            TEMP = IAND( IQUAL, MSK )
            WORK( EL, TOS ) = ( TEMP .EQ. MSK ) .OR.
     :                        ( TEMP .EQ. 0 )
         END DO

         GO TO 170

*  LDQX - Load two quality bits with build in XOR operation.
  130    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            TEMP = IAND( IQUAL, MSK )
            WORK( EL, TOS ) = ( TEMP .NE. MSK ) .AND.
     :                        ( TEMP .NE. 0 )
         END DO

         GO TO 170

*  LDQO - Load multiple quality bits with build in OR operation.
  140    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .NE. 0
         END DO

         GO TO 170

*  LDQA - Load multiple quality bits with build in AND operation.
  150    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .EQ. MSK
         END DO

         GO TO 170

*  LDQN - Load a single quality bit with build in NOT operation.
  160    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .EQ. 0
         END DO

         GO TO 170

*  NULL - Do nothing.
 170     CONTINUE

      END DO

*  Stack overflow. Report an error.
 180  CONTINUE
      IF( STATUS .EQ.  IRQ__STKOV ) THEN
         CALL ERR_REP( 'IRQ1_SBAD1R_ERR2', 'IRQ1_SBAD1R: Stack '//
     :                 'overflow (programming error).', STATUS )
      END IF

      END
      SUBROUTINE IRQ1_SBAD1W( HELD, NMASK, MASK, NOPC, OPCODE, MXSTK,
     :                       SIZE, QUAL, WORK, VEC, ALLBAD, NOBAD,
     :                       STATUS )
*+
*  Name:
*     IRQ1_SBAD1W

*  Purpose:
*     Set pixels bad which satisfy a given quality expression.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ1_SBAD1W( HELD, NMASK, MASK, NOPC, OPCODE, MXSTK, SIZE,
*                      QUAL, WORK, VEC, ALLBAD, NOBAD, STATUS )

*  Description:
*     This routine does the work for IRQ_SBAD.

*  Arguments:
*     HELD = LOGICAL (Given)
*        If true then those VEC pixels which hold a quality satisfying
*        the supplied quality expression are set bad. Otherwise, those
*        pixels which don't hold such a quality are set bad.
*     NMASK = INTEGER (Given)
*        No. of different masks used in the quality expression.
*     MASK( * ) = INTEGER (Given)
*        Masks defining each quality name. A bit-wise AND is performed
*        between the mask and a value from the QUALITY array.  If the
*        result is equal to the mask, then the quality is held.
*     NOPC = INTEGER (Given)
*        The number of op. codes in OPCODE.
*     OPCODE( NOPC ) = INTEGER (Given)
*        The codes which define the operations which must be performed
*        in order to evaluate the quality expression.
*     MXSTK = INTEGER (Given)
*        The maximum stack size needed to evaluate the quality
*        expression.
*     SIZE = INTEGER (Given)
*        The total number of pixels in VEC and QUAL.
*     QUAL( SIZE ) = BYTE (Given)
*        The QUALITY component from the NDF.
*     WORK( SIZE, MXSTK ) = LOGICAL (Given and Returned)
*        Work space.
*     VEC( SIZE ) = INTEGER*2 (Given and Returned)
*        The data to be set bad, depending on the corresponding quality
*        values stored in the NDF. Pixels which are not set bad are
*        left unchanged. It is the same size as the NDF, and
*        corresponds pixel-for-pixel with the vectorised NDF.
*     ALLBAD = LOGICAL (Returned)
*        Returned true if all pixels in VEC are returned with bad
*        values. False if any good pixel values are returned.
*     NOBAD = LOGICAL (Returned)
*        Returned true if no pixels in VEC are returned with bad
*        values. False if any bad pixel values are returned.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*   VAX-based features used:
*      -  Uses BYTE arrays.
*      -  Uses function IAND

*  Authors:
*     DSB: David Berry (STARLINK)
*     BKM: Brian McIlwrath (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     10-MAY-1996 (BKM):
*        Revised for Linux g77 which (currently) has IAND but no IZEXT
*    27-JAN-2002 (DSB):
*        Made generic.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! Starlink data constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Arguments Given:
      LOGICAL HELD
      INTEGER NMASK
      INTEGER MASK( * )
      INTEGER NOPC
      INTEGER OPCODE( NOPC )
      INTEGER MXSTK
      INTEGER SIZE
      BYTE QUAL( SIZE )

*  Arguments Given and Returned:
      LOGICAL WORK( SIZE, MXSTK )

*  Arguments Returned:
      INTEGER*2 VEC( SIZE )
      LOGICAL ALLBAD
      LOGICAL NOBAD

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER EL                 ! Current element in QUALITY array.
      INTEGER IOP                ! Index of current op code.
      INTEGER MSK                ! Current mask.
      INTEGER IQUAL              ! Zero extended integer from QUAL byte
      INTEGER NEWTOS             ! New value for TOS after operation is
                                 ! completed.
      INTEGER NXTMSK             ! Index of next mask to be used.
      INTEGER TEMP               ! Temporary logical storage.
      INTEGER TOS                ! Current position of top of stack.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the position of the top of the evaluation and mask stacks.
      TOS = 0
      NXTMSK = 0

*  Loop round each operation in OPCODE.
      DO IOP = 1, NOPC

*  Check for stack underflow.
         IF( TOS .LT. 0 ) THEN
            STATUS = IRQ__STKUN
            CALL ERR_REP( 'IRQ1_SBAD1W_ERR1', 'IRQ1_SBAD1W: '//
     :                    'Stack underflow (programming error)',
     :                    STATUS )
            GO TO 180
         END IF

*  Execute the next operation. (op codes are in the range 1 to 17).
         GO TO ( 10,  20,  30,  40,  50, 60, 70, 80, 90, 100, 110, 120,
     :           130, 140, 150, 160, 170 )
     :          OPCODE( IOP )

*  LDQ - Load single quality bit on to top of stack.
 10      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = ( IAND( IQUAL, MSK ) .EQ. MSK )
         END DO

         GO TO 170

*  RET- End expression. Use top-of-stack to create the output.
 20      CONTINUE

         ALLBAD = .TRUE.
         NOBAD = .TRUE.

         DO EL = 1, SIZE
            IF( WORK( EL, TOS ) .EQV. HELD ) VEC( EL ) = VAL__BADW

            IF( VEC( EL ) .EQ. VAL__BADW ) THEN
               NOBAD = .FALSE.

            ELSE
               ALLBAD = .FALSE.

            END IF

         END DO

         GO TO 170

*  Load constant .FALSE. on to top-of-stack.
 30      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .FALSE.
         END DO

         GO TO 170

*  Load constant .TRUE. on to top-of-stack.
 40      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .TRUE.
         END DO

         GO TO 170

*  Close brackets. Ignore.
 50      CONTINUE
         GO TO 170

*  Open brackets. Ignore.
 60      CONTINUE
         GO TO 170

*  Equivalence operator.
 70      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .EQV. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  Exclusive OR operator.
 80      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK(EL, TOS) .NEQV. WORK(EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  OR operator.
 90      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .OR. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  AND operator.
 100     CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .AND. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  NOT operator.
 110     CONTINUE

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .NOT. WORK( EL, TOS )
         END DO

         GO TO 170

*  LDQE - Load two quality bits with build in EQV operation.
  120    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            TEMP = IAND( IQUAL, MSK )
            WORK( EL, TOS ) = ( TEMP .EQ. MSK ) .OR.
     :                        ( TEMP .EQ. 0 )
         END DO

         GO TO 170

*  LDQX - Load two quality bits with build in XOR operation.
  130    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            TEMP = IAND( IQUAL, MSK )
            WORK( EL, TOS ) = ( TEMP .NE. MSK ) .AND.
     :                        ( TEMP .NE. 0 )
         END DO

         GO TO 170

*  LDQO - Load multiple quality bits with build in OR operation.
  140    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .NE. 0
         END DO

         GO TO 170

*  LDQA - Load multiple quality bits with build in AND operation.
  150    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .EQ. MSK
         END DO

         GO TO 170

*  LDQN - Load a single quality bit with build in NOT operation.
  160    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .EQ. 0
         END DO

         GO TO 170

*  NULL - Do nothing.
 170     CONTINUE

      END DO

*  Stack overflow. Report an error.
 180  CONTINUE
      IF( STATUS .EQ.  IRQ__STKOV ) THEN
         CALL ERR_REP( 'IRQ1_SBAD1W_ERR2', 'IRQ1_SBAD1W: Stack '//
     :                 'overflow (programming error).', STATUS )
      END IF

      END
      SUBROUTINE IRQ1_SBAD1UW( HELD, NMASK, MASK, NOPC, OPCODE, MXSTK,
     :                       SIZE, QUAL, WORK, VEC, ALLBAD, NOBAD,
     :                       STATUS )
*+
*  Name:
*     IRQ1_SBAD1UW

*  Purpose:
*     Set pixels bad which satisfy a given quality expression.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ1_SBAD1UW( HELD, NMASK, MASK, NOPC, OPCODE, MXSTK, SIZE,
*                      QUAL, WORK, VEC, ALLBAD, NOBAD, STATUS )

*  Description:
*     This routine does the work for IRQ_SBAD.

*  Arguments:
*     HELD = LOGICAL (Given)
*        If true then those VEC pixels which hold a quality satisfying
*        the supplied quality expression are set bad. Otherwise, those
*        pixels which don't hold such a quality are set bad.
*     NMASK = INTEGER (Given)
*        No. of different masks used in the quality expression.
*     MASK( * ) = INTEGER (Given)
*        Masks defining each quality name. A bit-wise AND is performed
*        between the mask and a value from the QUALITY array.  If the
*        result is equal to the mask, then the quality is held.
*     NOPC = INTEGER (Given)
*        The number of op. codes in OPCODE.
*     OPCODE( NOPC ) = INTEGER (Given)
*        The codes which define the operations which must be performed
*        in order to evaluate the quality expression.
*     MXSTK = INTEGER (Given)
*        The maximum stack size needed to evaluate the quality
*        expression.
*     SIZE = INTEGER (Given)
*        The total number of pixels in VEC and QUAL.
*     QUAL( SIZE ) = BYTE (Given)
*        The QUALITY component from the NDF.
*     WORK( SIZE, MXSTK ) = LOGICAL (Given and Returned)
*        Work space.
*     VEC( SIZE ) = INTEGER*2 (Given and Returned)
*        The data to be set bad, depending on the corresponding quality
*        values stored in the NDF. Pixels which are not set bad are
*        left unchanged. It is the same size as the NDF, and
*        corresponds pixel-for-pixel with the vectorised NDF.
*     ALLBAD = LOGICAL (Returned)
*        Returned true if all pixels in VEC are returned with bad
*        values. False if any good pixel values are returned.
*     NOBAD = LOGICAL (Returned)
*        Returned true if no pixels in VEC are returned with bad
*        values. False if any bad pixel values are returned.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*   VAX-based features used:
*      -  Uses BYTE arrays.
*      -  Uses function IAND

*  Authors:
*     DSB: David Berry (STARLINK)
*     BKM: Brian McIlwrath (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     10-MAY-1996 (BKM):
*        Revised for Linux g77 which (currently) has IAND but no IZEXT
*    27-JAN-2002 (DSB):
*        Made generic.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! Starlink data constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Arguments Given:
      LOGICAL HELD
      INTEGER NMASK
      INTEGER MASK( * )
      INTEGER NOPC
      INTEGER OPCODE( NOPC )
      INTEGER MXSTK
      INTEGER SIZE
      BYTE QUAL( SIZE )

*  Arguments Given and Returned:
      LOGICAL WORK( SIZE, MXSTK )

*  Arguments Returned:
      INTEGER*2 VEC( SIZE )
      LOGICAL ALLBAD
      LOGICAL NOBAD

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER EL                 ! Current element in QUALITY array.
      INTEGER IOP                ! Index of current op code.
      INTEGER MSK                ! Current mask.
      INTEGER IQUAL              ! Zero extended integer from QUAL byte
      INTEGER NEWTOS             ! New value for TOS after operation is
                                 ! completed.
      INTEGER NXTMSK             ! Index of next mask to be used.
      INTEGER TEMP               ! Temporary logical storage.
      INTEGER TOS                ! Current position of top of stack.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the position of the top of the evaluation and mask stacks.
      TOS = 0
      NXTMSK = 0

*  Loop round each operation in OPCODE.
      DO IOP = 1, NOPC

*  Check for stack underflow.
         IF( TOS .LT. 0 ) THEN
            STATUS = IRQ__STKUN
            CALL ERR_REP( 'IRQ1_SBAD1UW_ERR1', 'IRQ1_SBAD1UW: '//
     :                    'Stack underflow (programming error)',
     :                    STATUS )
            GO TO 180
         END IF

*  Execute the next operation. (op codes are in the range 1 to 17).
         GO TO ( 10,  20,  30,  40,  50, 60, 70, 80, 90, 100, 110, 120,
     :           130, 140, 150, 160, 170 )
     :          OPCODE( IOP )

*  LDQ - Load single quality bit on to top of stack.
 10      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = ( IAND( IQUAL, MSK ) .EQ. MSK )
         END DO

         GO TO 170

*  RET- End expression. Use top-of-stack to create the output.
 20      CONTINUE

         ALLBAD = .TRUE.
         NOBAD = .TRUE.

         DO EL = 1, SIZE
            IF( WORK( EL, TOS ) .EQV. HELD ) VEC( EL ) = VAL__BADUW

            IF( VEC( EL ) .EQ. VAL__BADUW ) THEN
               NOBAD = .FALSE.

            ELSE
               ALLBAD = .FALSE.

            END IF

         END DO

         GO TO 170

*  Load constant .FALSE. on to top-of-stack.
 30      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .FALSE.
         END DO

         GO TO 170

*  Load constant .TRUE. on to top-of-stack.
 40      CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .TRUE.
         END DO

         GO TO 170

*  Close brackets. Ignore.
 50      CONTINUE
         GO TO 170

*  Open brackets. Ignore.
 60      CONTINUE
         GO TO 170

*  Equivalence operator.
 70      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .EQV. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  Exclusive OR operator.
 80      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK(EL, TOS) .NEQV. WORK(EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  OR operator.
 90      CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .OR. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  AND operator.
 100     CONTINUE
         NEWTOS = TOS - 1

         DO EL = 1, SIZE
            WORK( EL, NEWTOS ) = WORK( EL, TOS ) .AND. WORK( EL, NEWTOS)
         END DO

         TOS = NEWTOS
         GO TO 170

*  NOT operator.
 110     CONTINUE

         DO EL = 1, SIZE
            WORK( EL, TOS ) = .NOT. WORK( EL, TOS )
         END DO

         GO TO 170

*  LDQE - Load two quality bits with build in EQV operation.
  120    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            TEMP = IAND( IQUAL, MSK )
            WORK( EL, TOS ) = ( TEMP .EQ. MSK ) .OR.
     :                        ( TEMP .EQ. 0 )
         END DO

         GO TO 170

*  LDQX - Load two quality bits with build in XOR operation.
  130    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            TEMP = IAND( IQUAL, MSK )
            WORK( EL, TOS ) = ( TEMP .NE. MSK ) .AND.
     :                        ( TEMP .NE. 0 )
         END DO

         GO TO 170

*  LDQO - Load multiple quality bits with build in OR operation.
  140    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .NE. 0
         END DO

         GO TO 170

*  LDQA - Load multiple quality bits with build in AND operation.
  150    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .EQ. MSK
         END DO

         GO TO 170

*  LDQN - Load a single quality bit with build in NOT operation.
  160    CONTINUE

         TOS = TOS + 1
         IF( TOS .GT. MXSTK ) THEN
            STATUS = IRQ__STKOV
            GO TO 180
         END IF

         NXTMSK = NXTMSK + 1
         MSK = MASK( NXTMSK )

         DO EL = 1, SIZE
            IQUAL = QUAL( EL )
            IF( IQUAL .LT. 0) IQUAL = 256 + IQUAL
            WORK( EL, TOS ) = IAND( IQUAL, MSK ) .EQ. 0
         END DO

         GO TO 170

*  NULL - Do nothing.
 170     CONTINUE

      END DO

*  Stack overflow. Report an error.
 180  CONTINUE
      IF( STATUS .EQ.  IRQ__STKOV ) THEN
         CALL ERR_REP( 'IRQ1_SBAD1UW_ERR2', 'IRQ1_SBAD1UW: Stack '//
     :                 'overflow (programming error).', STATUS )
      END IF

      END
