      SUBROUTINE CCG1_WTM3D( ORDDAT, WEIGHT, VAR, NENT, USED, COVAR,
     :                         RESULT, RESVAR, STATUS )
*+
*  Name:
*     CCG1_WTM3D

*  Purpose:
*     To form the weighted median of a list of ordered data values.
*     Incrementing the contributing pixel buffers and estimating the
*     variance change.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*      CALL CCG1_WTM3D( ORDDAT, WEIGHT, VAR, NENT, USED, COVAR,
*                         RESULT, RESVAR, STATUS )

*  Description:
*     This routine finds a value which can be associated with the half-
*     weight value. It sums all weights then finds a value for the
*     half-weight. The comparison with the half-weight value proceeds
*     in halves of the weights for each data point (half of the first
*     weight, then the second half of the first weight and the first
*     half of the second weight etc.) until the half weight is
*     exceeded. The data values around this half weight position are
*     then found and a linear interpolation of these values is the
*     weighted median. The values which contribute to the result are
*     flagged and passed through the USED array. This routine also
*     uses the order statistic covariance array (for a population NENT
*     big) to estimate the change in the variance from a optimal
*     measurement from the given population, returning the adjusted
*     variance.

*  Arguments:
*     ARR( NENT ) = DOUBLE PRECISION (Given)
*        The list of ordered data for which the weighted median is
*        required
*     WEIGHT( NENT ) = DOUBLE PRECISION (Given)
*        The weights of the values.
*     VAR( NSET ) = DOUBLE PRECISION (Given)
*        The variance of the unordered sample now ordered in ARR.
*     NENT = INTEGER (Given)
*        The number of entries in the data array.
*     USED = LOGICAL (Returned)
*        If a value contributes to the median value it is flagged as
*        true in this array, otherwise the array is set to false.
*     COVAR( * ) = DOUBLE PRECISION (Given)
*        The packed variance-covariance matrix of the order statistics
*        from a normal distribution of size NENT.
*     RESULT = DOUBLE PRECISION (Returned)
*        The weighted median
*     RESVAR = DOUBLE PRECISION (Returned)
*        The variance of result.
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
*     27-MAY-1992 (PDRAPER):
*        Added direct variance estimates.
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
      DOUBLE PRECISION ORDDAT( NENT )
      DOUBLE PRECISION WEIGHT( NENT )
      DOUBLE PRECISION VAR
      DOUBLE PRECISION COVAR( * )

*  Arguments Returned:
      DOUBLE PRECISION RESULT
      DOUBLE PRECISION RESVAR
      LOGICAL USED( NENT )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      DOUBLE PRECISION TOTWT     ! The total value of weights
      INTEGER I                  ! Loop variable
      INTEGER J                  ! Loop variable
      INTEGER K                  ! Loop variable
      INTEGER LBND               ! Lower sum bound
      INTEGER UBND               ! Upper sum bound
      DOUBLE PRECISION WTSUM     ! Current sum of weights
      DOUBLE PRECISION WTINC     ! Increment in current wtsum
      DOUBLE PRECISION D1        !
      DOUBLE PRECISION D2        ! Values around half weight
      DOUBLE PRECISION W1        ! Fractional weight of value
      DOUBLE PRECISION W2        ! Fractional weight of value
      DOUBLE PRECISION IW        ! Dummy
      DOUBLE PRECISION JW        ! Dummy
      DOUBLE PRECISION VSUM      ! Covariance sum

*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! Numeric conversion definitions
      INCLUDE 'NUM_DEF_CVT'      !
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  If only one input value has been given, do thing quickly.
      IF ( NENT .EQ. 1 ) THEN

*  Just one value, copy the input values to the output values.
         RESULT = NUM_DTOD( ORDDAT( 1 ) )
         RESVAR = VAR
         USED( 1 ) = .TRUE.
      ELSE

*  More than one value so process in earnest. 
*  Sum weights.
         TOTWT = 0.0D0
         DO 1 I = 1, NENT
            TOTWT = TOTWT + NUM_DTOD( WEIGHT( I ) )

*  Set the used array to false.
            USED( I ) =.FALSE.
 1       CONTINUE

* Search for median weight.
         TOTWT = TOTWT * 0.5D0
         WTSUM = 0.0D0
         DO 2 I = 1, NENT
            IF ( I .EQ. 1 ) THEN
               WTINC = NUM_DTOD( WEIGHT( I ) ) * 0.5D0
            ELSE
               WTINC = ( NUM_DTOD( WEIGHT( I ) + WEIGHT( I - 1 ) ) ) 
     :                 *  0.5D0
            END IF
            WTSUM = WTSUM + WTINC
            IF ( WTSUM .GT. TOTWT ) GO TO 66
 2       CONTINUE
 66      I = MIN( I, NENT )

*  Set the used array
         USED( I ) = .TRUE.

*  Bounds are present value and previous one.
         LBND = I - 1
         UBND = I
         D1 = NUM_DTOD( ORDDAT( LBND ) )
         D2 = NUM_DTOD( ORDDAT( I ) )

*  Set the used array extra value.
         USED( I - 1 ) = .TRUE.

*  Set weights factors
         W1 = ( WTSUM - TOTWT ) / MAX( WTINC, 1.0D-20 )
         W2 = 1.0D0 - W1

* Interpolate between data values
         RESULT = D1 * W1 + D2 * W2

*  Sum the relevant ordered statistic variances and covariances.
*  weighting accordingly.
         VSUM = 0.0D0
         DO 3 K = LBND, UBND
            IF( K .EQ. LBND ) THEN
               IW = W1
            ELSE
               IW = W2
            END IF
            DO 4 J = K, UBND
               IF( J .EQ. LBND ) THEN
                  JW = W1
               ELSE
                  JW = W2
               END IF

*  Sum variances and twice covariances ( off diagonal elements ).
               IF( K .EQ. J ) THEN
                  VSUM = VSUM + IW * JW * COVAR( K + J * ( J - 1 )/ 2 )
               ELSE
                  VSUM = VSUM +
     :                   2.0D0 * IW * JW * COVAR( K + J * ( J - 1 )/ 2 )
               END IF
 4          CONTINUE
 3       CONTINUE

*  Right make the new variance estimate. Use the sum of variances
*  and covariances of the order statistic of the `trimmed' sample size
*  Sample variance changes to NENT * VAR to represent total variance
*  of original data.
         RESVAR = VAR * NENT * VSUM
      END IF
      END
* $Id$
