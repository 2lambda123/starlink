      SUBROUTINE CCG1_WMD3D( ORDDAT, WEIGHT, NVAL, PBAD, NITER,
     :                         TOLL, NSIGMA, COVEC, XMODE,
     :                         FVAR, USED, NUSED, STATUS )
*+
*  Name:
*     CCG1_WMD3D

*  Language:
*     Starlink Fortran 77

*  Purpose:
*     To estimate the mean of a number of normally distributed data
*     values, some of which may be corrupt.

*  Invocation:
*      CALL CCG1_WMD3D( ORDDAT, WEIGHT, NVAL, PBAD, NITER, TOLL,
*                         NSIGMA, COVEC, XMODE, FVAR, USED,
*                         NUSED, STATUS )

*  Description:
*      This routine is based on maximising the likelyhood function for
*      a statistical model in which any of the data points has a
*      constant probability of being corrupt. A weighted mean is formed
*      with weights chosen according to the deviation of each data
*      point from the current estimate of the mean. The weights are
*      derived from the relative probability of being invalid or
*      corrupt. A sequence of these iterations converges to a
*      stationary point in the likelyhood function. The routine
*      approximates to a k-sigma clipping algorithm for a large number
*      of points and to a mode estimating algorithm for fewer data
*      points.  Different weighting for each data point are allowed to
*      accomodate known different intrinsic errors in the input data.
*
*      The variance of the input population is determined from the
*      whole population and a new variance is computed, after the
*      rejection passes, using the order statistics of a trimmed sample
*      with the derived weights and initial numbers. Thus the input data
*      should be ordered (either increasing or decreasing) so that means
*      which are outliers (due to unstabilities from overly small sigma
*      clipping) can have their variance properly estimated.

*  Arguments:
*     ORDDAT( NVAL ) = DOUBLE PRECISION (Given)
*        An ordered (increasing or decreasing) array of data values.
*     WEIGHT( NVAL ) = DOUBLE PRECISION (Given)
*        An array of data weights for each data value.  The weights
*        should be the inverse variance of each data point. They are
*        used to directly estimate the input population variance.
*     NVAL = INTEGER (Given)
*        The number of data values.
*     PBAD = REAL (Given)
*        An estimate of the probability that any one data point will be
*        corrupt.  (This value is not critical.)
*     NITER = INTEGER (Given)
*        The maximum number of iterations required.
*     TOLL = REAL (Given)
*        The absolute accuracy required in the estimate of the
*        mean.  Iterations cease when two successive estimates
*        differ by less than this amount.
*     NSIGMA = REAL (Given)
*        The sigma level to reject data values at.
*     COVEC( * ) = DOUBLE PRECISION (Given)
*        The packed variance-covariance matrix of the order statistics
*        from a normal distribution of size NVAL, produced by
*        CCD1_ORVAR.
*     XMODE = DOUBLE PRECISION (Returned)
*        The estimate of the uncorrupted mean.
*     FVAR = DOUBLE PRECISION (Returned)
*        An estimate of the uncorrupted variance of the data points.
*     USED( NVAL ) = LOGICAL (Returned)
*        If a value is not rejected then its corresponding used element
*        will be set true.
*     NUSED = INTEGER (Returned)
*        Number of the input data values which are actually used when
*        forming the estimate of the mean. This value will be zero or
*        less if all values are rejected.
*     STATUS = INTEGER (Returned)
*        The global status.

*  Notes:
*      -  The input data must be sorted. The output variances are only
*      accurate if the input data values have a normal distribution.


*  Authors:
*     RFWS: R.F. Warren-Smith (Durham Univ.)
*     MJC: Malcolm J. Currie (STARLINK)
*     PDRAPER: Peter Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1981 (RFWS):
*        Original version.
*     1990 September 25 (MJC):
*        Made generic, renamed from WMODE, added STATUS, commented
*        the variables and converted the prologue.
*     1991 April 4 (PDRAPER):
*        Took from KAPPA and included NSIGMA argument.
*        Changed output to double precision for compatablity.
*     9-APR-1991 (PDRAPER):
*        Added counter for number of points used.
*     30-MAY-1991 (PDRAPER):
*        Added used array to estimate statistics on image useage.
*     29-MAY-1992 (PDRAPER):
*        Added description and more comments.
*     1-JUN-1992 (PDRAPER):
*        Added order statistics for improved variance estimation.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! Bad-pixel constants

*  Arguments Given:
      INTEGER NVAL
      INTEGER NITER
      INTEGER NMAT
      DOUBLE PRECISION ORDDAT( NVAL )
      DOUBLE PRECISION WEIGHT( NVAL )
      DOUBLE PRECISION COVEC( * )
      REAL PBAD
      REAL TOLL
      REAL NSIGMA

*  Arguments Returned:
      DOUBLE PRECISION FVAR
      DOUBLE PRECISION XMODE
      INTEGER NUSED
      LOGICAL USED( NVAL )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      DOUBLE PRECISION NVAR      ! Number of variances from mean
      DOUBLE PRECISION D         ! Data value
      DOUBLE PRECISION DATA      ! Work variable
      DOUBLE PRECISION DEV       ! Deviation from the current mean
      DOUBLE PRECISION DEV2      ! Deviation from the current mean squared, weighted
      DOUBLE PRECISION DEVLIM    ! Maximum deviation to be included
      DOUBLE PRECISION DTOLL     ! TOLL as DBLE
      DOUBLE PRECISION DW        ! Weight as DBLE
      DOUBLE PRECISION DXMODE    ! Increment to the mean
      DOUBLE PRECISION OMODE     ! Old mean value
      DOUBLE PRECISION EX        ! Probability of a point being good
      DOUBLE PRECISION IVAR      ! Initial population variance
      DOUBLE PRECISION PBNORM    ! Normalised probability
      DOUBLE PRECISION PROB      ! Fractional probability of a point being good data
      DOUBLE PRECISION SUMA      ! Sum zero-order moment
      DOUBLE PRECISION SUMB      ! Sum weighted zero-order moment
      DOUBLE PRECISION SUMC      ! Sum first-order moment
      DOUBLE PRECISION SUMD      ! Sum second-order moment
      DOUBLE PRECISION VAR       ! Variance
      DOUBLE PRECISION W1        ! Work variable
      DOUBLE PRECISION W2        ! Work variable
      INTEGER I                  ! Loop counter
      INTEGER J                  ! Loop counter
      INTEGER K                  ! Loop counter
      INTEGER ITER               ! Number of iterations
      INTEGER LBND               ! Lower bound for summation
      INTEGER UBND               ! Upper bound for summation
      INTEGER NLBND              ! Temporary lower bound for summation
      INTEGER NUBND              ! Temporary lower bound for summation

*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'      ! NUM definitions for conversions

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
      IF ( NVAL .LE. 1 ) THEN

*  Only one value - cannot form a variance using this.
         STATUS = SAI__ERROR
         CALL ERR_REP( 'CCG1_WMD2_ERR',
     :     'Insufficient data points to compute a variance.', STATUS )
         GO TO 99
      END IF

*  Form the initial estimate of the mean and variance.
      SUMA = 0.0D0
      SUMB = 0.0D0
      SUMC = 0.0D0
      DO 1 I = 1, NVAL

*  Form sums.
         DATA = NUM_DTOD( WEIGHT( I ) )
         SUMA = SUMA + DATA
         D = NUM_DTOD( ORDDAT( I ) )
         DATA = DATA * D
         SUMB = SUMB + DATA
         SUMC = SUMC + D * DATA

*  Intialise the used flags
         USED( I ) = .FALSE.
 1    CONTINUE

*  Form the first estimate of the mean and variance.
      OMODE = SUMB / SUMA

*  Variance is weighted by mean weight. (Also used in model to weight
*  relative deviation later).
      VAR = ( SUMC - ( SUMB * SUMB ) / SUMA ) / DBLE( NVAL - 1 )
      VAR = MAX( VAR, 0.0D0 )

*  Store initial variance for later modification.
      IVAR = 1.0D0 / SUMA

*  Set bounds of summations  - will assume that input weights are
*  sensible (not heavily weighted to opposite extremes) so that values
*  used to determine mean will be grouped. Using this together with the
*  fact that the input data is ordered we should be able to use updated
*  limits, the range of these values should only ever decrease as more
*  members are excluded from the summations.
      LBND = 1
      UBND = NVAL

*  Set constants.
      PBNORM = DBLE( PBAD * 0.707107 )
      NVAR = DBLE( NSIGMA * NSIGMA )
      DTOLL = DBLE( TOLL )

*  Now start the iteration loop.
      DO 2 ITER = 1, NITER
         VAR = MAX( VAR, 1.0D-20 )
         W2 = 0.5D0 / VAR

*  Initialise sums for forming new estimate.
         SUMA = 0.0D0
         SUMB = 0.0D0
         SUMC = 0.0D0
         SUMD = 0.0D0

*  Set new bounds variables.
         NLBND = LBND
         NUBND = UBND

*  Limit good value to lie within NSIGMA deviations.
         DEVLIM = VAR * NVAR

*  Scan through the data points, forming weighted sums to calculate
*  new mean and variance.
         K = LBND
         LBND = UBND
         UBND = K
         DO 3 I = NLBND, NUBND

*  Determine deviation from mean and weight it.
            DATA = NUM_DTOD( ORDDAT( I ) )
            DEV = DATA - OMODE
            DW = NUM_DTOD( WEIGHT( I ) )
            DEV2 = DEV * DEV * DW

*  Ignore points more than NSIGMA from the mean.
            IF ( DEV2 .LE. DEVLIM ) THEN

*  The weights depend on the fractional probability of being good data.
               EX = EXP( - W2 * DEV2 )
               PROB = EX / ( PBNORM + EX )
               SUMA = SUMA + PROB
               SUMB = SUMB + PROB * DW
               SUMC = SUMC + DATA * PROB * DW
               SUMD = SUMD + DEV2 * PROB

*  Set new bounds for next iteration.
               LBND = MIN( LBND, I )
               UBND = MAX( UBND, I )
            END IF
 3       CONTINUE

*  Catch special case of all values rejected.
         IF ( LBND .GT. UBND ) GO TO 101

*  Form the new estimates for the uncorrupted mean and fractional
*  change.
         SUMA = MAX( SUMA, 1.0D-20 )
         SUMB = MAX( SUMB, 1.0D-20 )
         XMODE = SUMC / SUMB
         DXMODE = XMODE - OMODE

*  If the required accuracy has been met,
         IF ( ABS( DXMODE ) .LE. DTOLL ) GO TO 101

*  If this is any other than the last loop then re-evaluate the variance
*  do not change it on last loop as it is used for weights in summing
*  covariances. Store present estimate of mean to compare with new
*  estimate.
         IF ( ITER .NE. NITER ) THEN
            VAR = SUMD / SUMA
            OMODE = XMODE
         END IF
 2    CONTINUE

*  Exit point for tolerance criterioN met or number of iterations
*  exceeded.
 101   CONTINUE

*  Number of values used.
       NUSED = UBND - LBND + 1

*  Only procede if NUSED greater than zero - otherwise all values
*  rejected.
      IF ( NUSED .GT. 0 ) THEN

*  Half inverse variance (constant now)
         DATA = 0.5D0 / VAR

*  Sum variance-covariances for this population size using the weights.
         SUMA = 0.0D0
         SUMB = 0.0D0
         DO 4 J = LBND, UBND

*  Set used this variable flag. (Do it here as one pass only!)
            USED( J ) = .TRUE.

*  Determine weight associated with this value.
            DEV = NUM_DTOD( ORDDAT( J ) ) - XMODE
            DW = NUM_DTOD( WEIGHT( J ) )
            DEV2 = DW * DEV * DEV
            EX = EXP( - DATA * DEV2 )
            PROB = EX / ( PBNORM + EX )
            W1 = DW * PROB

            DO 5 K = J, UBND
               IF( J .EQ. K ) THEN

*  Same weight as determined for J
                  W2 = W1 * W1
               ELSE

*  Determine weight associated with this value.
                  DEV = NUM_DTOD( ORDDAT( K ) ) - XMODE
                  DW = NUM_DTOD( WEIGHT( K ) )
                  DEV2 = DW * DEV * DEV
                  EX = EXP( - DATA  * DEV2 )
                  PROB = EX / ( PBNORM + EX )
                  W2 = DW * PROB
                  W2 = 2.0D0 * W1 * W2
               END IF

*  Sum covariance matrix.
               SUMA = SUMA + W2 * COVEC( J + K * ( K - 1 ) / 2 )
               SUMB = SUMB + W2
 5          CONTINUE
 4       CONTINUE

*  Variance modification factor.
         SUMA = SUMA / SUMB

*  Correct the original population variance.
         FVAR = SUMA * IVAR * NVAL

      END IF
 99   CONTINUE
      END
* $Id$
