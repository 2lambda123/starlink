      SUBROUTINE KPG1_MODER( X, NX, PBAD, NITER, TOLL, XMODE, SIGMA,
     :                         STATUS )
*+
*  Name:
*     KPG1_MODEx
 
*  Purpose:
*     To estimate the mean of a number of normally distributed data
*     values, some of which may be corrupt.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPG1_MODEx(  X, NX, PBAD, NITER, TOLL, XMODE, SIGMA,
*    :                  STATUS )
 
*  Description:
*     The routine is based on maximising the likelihood function for a
*     statistical model in which any of the data points has a constant
*     probability of being corrupt.  A weighted mean is chosen
*     according to the deviation of each data point from the current
*     estimate of the mean.  The weights are derived from the relative
*     probabilities of being valid or corrupt.  A sequence of these
*     iterations converges to a stationary point in the likelihood
*     function.  The routine approximates to a k-sigma clipping
*     algorithm for a large number of data points and to a
*     mode-estimating algorithm for fewer data points.
 
*  Arguments:
*     X( NX ) = ? (Given)
*        An array of data values.
*     NX = INTEGER (Given)
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
*     XMODE = REAL (Returned)
*        The estimate of the uncorrupted mean.
*     SIGMA = REAL (Returned)
*        An estimate of the uncorrupted standard deviation of the data
*        points.
*     STATUS = INTEGER (Returned)
*        The global status.
 
*  Notes:
*     There is a routine for each numeric data type: replace "x" in the
*     routine name by D, R, I, W, UW, B, UB as appropriate.  The array
*     supplied to the routine must have the data type specified.
 
*  Authors:
*     RFWS: R.F. Warren-Smith (Durham Univ.)
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1981 (RFWS):
*        Original version.
*     1990 September 18 (MJC):
*        Made generic, renamed from MODE, added STATUS , commented
*        varaibles and converted the prologue.
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
      INTEGER
     :  NX,
     :  NITER
 
      REAL
     :  X( NX )
 
      REAL
     :  PBAD,
     :  TOLL
 
*  Arguments Returned:
      REAL
     :  SIGMA,
     :  XMODE
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      REAL
     :  DEV,                     ! Deviation from the current mean
     :  DEV2,                    ! Deviation from the current mean
                                 ! squared
     :  DEVLIM,                  ! Maximum deviation to be included
     :  DXMODE,                  ! Increment to the mean
     :  EX,                      ! Probability of a point being good
     :  PROB,                    ! Fractional probability of a point
                                 ! being good data
     :  PBNORM,                  ! Normalised probability
     :  SUMA,                    ! Sum zero-order  moment
     :  SUMB,                    ! Sum first-order moment
     :  SUMC,                    ! Sum second-order moment
     :  W2,                      ! Work variable
     :  VAR                      ! Variance
 
      INTEGER
     :  I,                       ! Loop counter
     :  ITER                     ! Number of iterations
 
      DOUBLE PRECISION
     :  D,                       ! Data value
     :  SUM1,                    ! Sum zero-order  moment (first pass)
     :  SUM2,                    ! Sum first-order moment (first pass)
     :  SUM3                     ! Sum second-order moment (first pass)
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'      ! NUM definitions for conversions
 
*.
 
*    Check inherited global status.
 
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*    Form the initial estimate of the mean and sigma.
 
      SUM1 = 0.0D0
      SUM2 = 0.0D0
      SUM3 = 0.0D0
 
      DO I = 1, NX
 
*       Ignore bad pixels.
 
         IF ( X( I ) .NE. VAL__BADR ) THEN
 
*          Form sums in double precision to reduce rounding errors
*          giving large relative uncertainities in the statistics.
 
            SUM1 = SUM1 + 1.0D0
            D = NUM_RTOD( X( I ) )
            SUM2 = SUM2 + D
            SUM3 = SUM3 + D * D
         END IF
      END DO
 
*    Check that there were sufficient data before forming the first
*    estimate of the statistics.
 
      IF ( SUM1 .GT. 1.0D0 ) THEN
         XMODE = REAL( SUM2 / SUM1 )
         VAR = REAL( ( SUM3 - ( SUM2 * SUM2 ) / SUM1 ) /
     :         ( SUM1 - 1.0D0 ) )
         VAR = MAX( VAR, 0.0 )
      ELSE
         STATUS = SAI__ERROR
         CALL ERR_REP( 'KPG1_MODEX_INSDA',
     :     'Insufficient data points to compute a variance.', STATUS )
         VAR = 0.0
         XMODE = REAL( SUM2 )
         GOTO 100
      END IF
 
*    Now start the iteration loop.
 
      PBNORM = PBAD * 0.707107
 
      DO ITER = 1, NITER
         VAR = MAX( VAR, VAL__SMLR, 1.0E-12 * XMODE ** 2 )
         W2 = 0.5 / VAR
 
*    Initialise sums for forming new estimate.
 
         SUMA = 0.0
         SUMB = 0.0
         SUMC = 0.0
         DEVLIM = 100.0 * VAR
 
*       Scan through the data points, forming weighted sums to calculate
*       new mean and variance.
 
         DO I = 1, NX
            IF ( STATUS .NE. VAL__BADR ) THEN
               DEV = NUM_RTOR( X( I ) ) - XMODE
               DEV2 = DEV * DEV
 
*             Ignore points more than 10 sigma from the mode.
 
               IF ( DEV2 .LE. DEVLIM ) THEN
 
*                The weights depend on the fractional probability of
*                being good data.
 
                  EX = EXP( - W2 * DEV2 )
                  PROB = EX / ( PBNORM + EX )
                  SUMA = SUMA + PROB
                  SUMB = SUMB + DEV * PROB
                  SUMC = SUMC + DEV2 * PROB
               END IF
            END IF
 
         END DO
 
*       Form the new estimates for the uncorrupted mean and standard
*       deviation.
 
         SUMA = MAX( SUMA, VAL__SMLR )
         DXMODE = SUMB / SUMA
         XMODE = XMODE + DXMODE
         VAR = SUMC / SUMA
 
*       If the required accuracy has been met, return
 
         IF ( ABS( DXMODE ) .LE. TOLL ) GO TO 100
      END DO
 
  100 CONTINUE
      SIGMA = SQRT( VAR )
 
      END
