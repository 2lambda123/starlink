      SUBROUTINE CCG1_WMD2D( X, W, NX, PBAD, NITER, TOLL, NSIGMA,
     :                          XMODE, SIGMA, USED, NUSED, STATUS )
*+
*  Name:
*     CCG1_WMD2D

*  Language:
*     Starlink Fortran 77

*  Purpose:
*     To estimate the mean of a number of normally distributed data
*     values, some of which may be corrupt.

*  Invocation:
*      CALL CCG1_WMD2D( X, W, NX, PBAD, NITER, TOLL, NSIGMA, XMODE,
*                          SIGMA, USED, NUSED, STATUS )

*  Description:
*      Not available. Remember to look in EDRS.

*  Arguments:
*     X( NX ) = DOUBLE PRECISION (Given)
*        An array of data values.
*     W( NX ) = DOUBLE PRECISION (Given)
*        An array of data weights for each data value.  The weights are
*        inversely proportional to the square of the relative errors on
*        each data point.
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
*     NSIGMA = REAL (Given)
*        The sigma level to reject data values at.
*     XMODE = DOUBLE PRECISION (Returned)
*        The estimate of the uncorrupted mean.
*     SIGMA = DOUBLE PRECISION (Returned)
*        An estimate of the uncorrupted normalised standard deviation of
*        the data points.  An estimate of the standard deviation of any
*        one point is:  SIGMA / SQRT( W ) where W is its weight.
*     USED( NX ) = LOGICAL (Returned)
*        If a value is not rejected then its corresponding used element
*        will be set true.
*     NUSED = INTEGER (Returned)
*        Number of the input data values which are actually used.
*     STATUS = INTEGER (Returned)
*        The global status.

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
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*.


*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! Bad-pixel constants

*  Arguments Given:
      INTEGER
     :  NX,
     :  NITER

      DOUBLE PRECISION
     :  X( NX ),
     :  W( NX )

      REAL
     :  PBAD,
     :  TOLL,
     :  NSIGMA

*  Arguments Returned:
      DOUBLE PRECISION
     :  SIGMA,
     :  XMODE
      INTEGER NUSED
      LOGICAL USED( NX )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      REAL
     :  DEV,                     ! Deviation from the current mean
     :  DEV2,                    ! Deviation from the current mean
                                 ! squared, weighted
     :  DEVLIM,                  ! Maximum deviation to be included
     :  DX2,                     ! Deviation squared
     :  DXMODE,                  ! Increment to the mean
     :  EX,                      ! Probability of a point being good
     :  PROB,                    ! Fractional probability of a point
                                 ! being good data
     :  PBNORM,                  ! Normalised probability
     :  SUMA,                    ! Sum zero-order  moment
     :  SUMB,                    ! Sum weighted zero-order moment
     :  SUMC,                    ! Sum first-order moment
     :  SUMD,                    ! Sum second-order moment
     :  W2,                      ! Work variable
     :  RW,                      ! Weight as REAL
     :  VAR                      ! Variance

      INTEGER
     :  I,                       ! Loop counter
     :  ITER,                    ! Number of iterations
     :  N                        ! Pixel counter

      DOUBLE PRECISION
     :  D,                       ! Data value
     :  DATA,                    ! Work variable
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
      N = 0

      DO I = 1, NX

*       Ignore bad pixels.

         IF ( X( I ) .NE. VAL__BADD ) THEN

*          Form sums in double precision to reduce rounding errors
*          giving large relative uncertainities in the statistics.

            N = N + 1
            DATA = NUM_DTOD( W( I ) )
            SUM1 = SUM1 + DATA
            D = NUM_DTOD( X( I ) )
            DATA = DATA * D
            SUM2 = SUM2 + DATA
            SUM3 = SUM3 + D * DATA
         END IF

*  Intialise the used flags
         USED( I ) = .FALSE.

      END DO

*    Check that there were sufficient data before forming the first
*    estimate of the statistics.

      IF ( N .GT. 1 ) THEN
         XMODE = SUM2 / SUM1
         VAR = ( SUM3 - ( SUM2 * SUM2 ) / SUM1 ) / REAL( N - 1 )
         VAR = MAX( VAR, 0.0 )
      ELSE
         STATUS = SAI__ERROR
         CALL ERR_REP( 'KPG1_WMODEX_INSDA',
     :     'Insufficient data points to compute a variance.', STATUS )
         VAR = 0.0
         XMODE = SUM2
         GO TO 100
      END IF

*    Now start the iteration loop.

      PBNORM = PBAD * 0.707107

      DO ITER = 1, NITER
         VAR = MAX( VAR, 1.0E-20 )
         W2 = 0.5 / VAR

*    Initialise sums for forming new estimate.

         SUMA = 0.0
         SUMB = 0.0
         SUMC = 0.0
         SUMD = 0.0

*  Limit good value to lie within NSIGMA
         DEVLIM = VAR * NSIGMA * NSIGMA

*       Scan through the data points, forming weighted sums to calculate
*       new mean and variance.

         NUSED = 0
         DO I = 1, NX
            IF ( X( I ) .NE. VAL__BADD ) THEN
               DEV = NUM_DTOR( X( I ) ) - XMODE
               DX2 = DEV * DEV
               RW = NUM_DTOR( W( I ) )
               DEV2 = DX2 * RW

*             Ignore points more than 10 sigma from the mode.

               IF ( DEV2 .LE. DEVLIM ) THEN

*  Increment the used counter and flag this value used.
                  NUSED = NUSED + 1
                  USED( I ) = .TRUE.

*                The weights depend on the fractional probability of
*                being good data.

                  EX = EXP( - W2 * DEV2 )
                  PROB = EX / ( PBNORM + EX )
                  SUMA = SUMA + PROB
                  SUMB = SUMB + PROB * RW
                  SUMC = SUMC + DEV * PROB * RW
                  SUMD = SUMD + DEV2 * PROB
               END IF
            END IF

         END DO

*       Form the new estimates for the uncorrupted mean and standard
*       deviation.

         SUMA = MAX( SUMA, 1.0E-20 )
         SUMB = MAX( SUMB, 1.0E-20 )
         XMODE = XMODE + SUMC / SUMB
         VAR = SUMD / SUMA

*       If the required accuracy has been met, return
         DXMODE = SUMC / SUMB
         IF ( ABS( DXMODE ) .LE. TOLL ) GO TO 100
      END DO

  100 CONTINUE
      SIGMA = SQRT( VAR )

      END
* $Id$
