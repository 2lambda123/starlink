      SUBROUTINE CCG1_WTM2R( ORDDAT, WEIGHT, NENT, USED, RESULT,
     :                          STATUS )
*+
*  Name:
*     CCG1_WTM2R

*  Purpose:
*     To form the weighted median of a list of ordered data values.
*     Incrementing the contributing pixel buffers.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCG1_WTM2R( ARR, WEIGHT, NENT, USED, RESULT, STATUS )

*  Description:
*     This routine finds a value which can be associated with the half-
*     weight value. It sums all weights then finds a value for the
*     half-weight. The comparison with the half-weight value proceeds in
*     halves of the weights for each data point (half of the first
*     weight, then the second half of the first weight and the first
*     half of the second weight etc.) until the half weight is exceeded.
*     The data values around this half weight position are then found
*     and a linear interpolation of these values is the wtdmdn. The
*     values which contribute to the result are flagged and passed
*     through the USED array.

*  Arguments:
*     ARR( NENT ) = REAL (Given)
*        The list of ordered data for which the weighted median is
*        required
*     WEIGHT( NENT ) = REAL (Given)
*        The weights of the values.
*     NENT = INTEGER (Given)
*        The number of entries in the data array.
*     USED = LOGICAL (Returned)
*        If a value contributes to the median value it is flagged as
*        true in this array, otherwise the array is set to false.
*     RESULT = DOUBLE PRECISION (Returned)
*        The weighted median
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Prior Requirements:
*     - The input data must be ordered increasing. No BAD values may be
*     present.

*  Notes:
*     - the routine should only be used at real or better precisions.

*  Authors:
*     RFWS: Rodney Warren-Smith (Durham University)
*     PDRAPER: Peter Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     - (RFWS):
*        Original version.
*     5-APR-1991 (PDRAPER):
*        Changed to use preordered array, changed to generic routine.
*        Added prologue etc.
*     30-MAY-1991 (PDRAPER):
*        Added used array.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      INTEGER NENT
      REAL ORDDAT( NENT )
      REAL WEIGHT( NENT )

*  Arguments Returned:
      DOUBLE PRECISION RESULT
      LOGICAL USED( NENT )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      DOUBLE PRECISION TOTWT     ! The total value of weights
      INTEGER I                  ! Loop variable
      DOUBLE PRECISION WTSUM     ! Current sum of weights
      DOUBLE PRECISION WTINC     ! Increment in current wtsum
      DOUBLE PRECISION D1        !
      DOUBLE PRECISION D2        ! Values around half weight
      DOUBLE PRECISION WTDIFF    ! Difference between half weight and
                                 ! current weight (selected)
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! Numeric conversion definitions
      INCLUDE 'NUM_DEF_CVT'      !
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

* Sum weights.
      TOTWT = 0.0D0
      DO 1 I = 1, NENT
         TOTWT = TOTWT + NUM_RTOD( WEIGHT( I ) )

*  Set the used array to false.
         USED( I ) =.FALSE.
 1    CONTINUE

* Search for median weight.
      TOTWT = TOTWT * 0.5D0
      WTSUM = 0.0D0
      DO 2 I = 1, NENT

         IF ( I .EQ. 1 ) THEN
            WTINC = NUM_RTOD( WEIGHT( I ) ) * 0.5D0
         ELSE
            WTINC = ( NUM_RTOD( WEIGHT( I ) + WEIGHT( I-1 )) )* 0.5D0
         END IF
         WTSUM = WTSUM + WTINC
         IF ( WTSUM .GT. TOTWT ) GO TO 66
 2    CONTINUE
 66   I = MIN( I, NENT )

*  Set the used array
         USED( I ) = .TRUE.

* Extract adjacent data values
      IF ( I .EQ. 1 ) THEN
         D1 = NUM_RTOD( ORDDAT( I ) )
         D2 = D1

      ELSE
         D1 = NUM_RTOD( ORDDAT( I - 1 ) )
         D2 = NUM_RTOD( ORDDAT( I ) )

*  Set the used array extra value.
         USED( I - 1 ) = .TRUE.
      END IF

* Interpolate between data values
      WTDIFF = WTSUM - TOTWT
      RESULT = D2 - ( D2 - D1 ) * WTDIFF / MAX( WTINC, 1.0D-20 )

      END
* @(#)ccg1_wtm2.gen	2.1     11/30/93     2
