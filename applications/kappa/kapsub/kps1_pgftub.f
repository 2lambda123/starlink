      SUBROUTINE KPS1_PGFTUB( P, PW, PR, NP, NITER, GAUSS, TOLL, AMP,
     :                         BACK, SIGMA, GAMMA, STATUS )
*+
*  Name:
*     KPS1_PGFTx

*  Purpose:
*     To fit a least-squares radial star profile to appropriately 
*     binned data.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_PGFTx( P, PW, PR, NP, NITER, TOLL, AMP, BACK,
*    :                 SIGMA, GAMMA, STATUS )

*  Description:
*     The routine refines initial estimates of the star amplitude,
*     the background, the 'sigma' and the radial exponent gamma which
*     are given on entry.  The routine repeatedly forms and solves
*     the linearised normal equations for a least-squares fit.
*     The radial exponent may be fixed to be 2 (i.e. Gaussian).

*  Arguments:
*     P( NP ) = ? (Given)
*        An array of data values at varying distances from the
*        Gaussian centre.
*     PW( NP ) = REAL (Given)
*        An array of weights (inversely proportional to the square
*        of the probable error) associated with the data values.
*     PR( NP ) = REAL (Given)
*        An array of radii associated with the data values.
*     NP = INTEGER (Given)
*        The dimension of data, radius and weight arrays.
*     NITER = INTEGER (Given)
*        The maximum number of refining iterations.
*     GAUSS = LOGICAL (Given)
*        If .TRUE., the radial-fall-off parameter (gamma) is fixed to be
*        2; in other words the best-fitting two-dimensional Gaussian is
*        evaluated.  If .FALSE., gamma is a free parameter of the fit,
*        and the derived value is returned in argument GAMMA.
*     TOLL = REAL (Given)
*        The fractional accuracy required in the result.  Accuracy is
*        assessed as a fraction of the parameter value for the
*        amplitude, sigma and gamma.  The accuracy of the background
*        is assessed as a fraction of the amplitude.  Iterations cease
*        when two successive iterations give results agreeing
*        within the relative accuracy tolerance.
*     AMP = REAL (Given & Returned)
*        The Gaussian amplitude.
*     BACK = REAL (Returned)
*        The background signal level.
*     SIGMA = REAL (Given & Returned)
*        The 'sigma' of the Gaussian.
*     GAMMA = REAL (Given & Returned)
*        The exponent in the radial profile function.  The fitted
*        function is: 
*          %AMP * exp( -0.5 * ( radius / %SIGMA ) ** %GAMMA ) + %BACK
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     There is a routine for each numeric data type: replace "x" in the
*     routine name by D, R, I, W, UW, B, UB as appropriate.  The array
*     supplied to the routine must have the data type specified.

*  Algorithm:
*     Find initial estimates of the Gaussian amplitude, mean and
*     width by centroiding and linear least-squares, using the
*     lower quartile data point as an initial background estimate.
*     Refine the estimates by repeatedly solving the linearised normal
*     equations for a least-squares fit.

*  Authors:
*     RFWS: R.F. Warren-Smith (Durham Univ.)
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1981 (RFWS):
*        Original version.
*     1990 September 20 (MJC):
*        Made generic, renamed from PRGFIT, added STATUS and commented
*        the variables, and converted the prologue.
*     1996 January 29 (MJC):
*        Removed NAG calls.  Tidied the code to a modern style.
*     1998 May 26 (MJC):
*        Added GAUSS argument and code to effect its use.  A failure
*        to meet the tolerance test is no longer fatal.  Warning
*        messages showing the requested and used tolerances replace
*        the error message.
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
      INTEGER NP
      BYTE P( NP )
      REAL PW( NP )
      REAL PR( NP )
      INTEGER NITER
      LOGICAL GAUSS
      REAL TOLL

*  Arguments Given and Returned:
      REAL AMP
      REAL BACK
      REAL SIGMA
      REAL GAMMA

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      INTEGER NPAR               ! Maximum number of parameters to find
      PARAMETER ( NPAR = 4 )

*  Local Variables:
      DOUBLE PRECISION A( NPAR, NPAR ) ! LHS of normal equations
      REAL ALPHA                 ! Work variable
      REAL BETA                  ! Work variable
      DOUBLE PRECISION C( NPAR ) ! Parameters of the fit
      REAL DELTA                 ! Deviation of the fits from the data
      REAL E1                    ! Relative change in the background
      REAL E2                    ! Relative change in the amplitude
      REAL E3                    ! Relative change in sigma
      REAL E4                    ! Relative change in gamma
      INTEGER ERRCO              ! PDA error indicator
      REAL EX                    ! Gaussian value at the current data
                                 ! element
      INTEGER I                  ! Loop counter
      INTEGER IFAIL              ! PDA-routine status
      INTEGER ITER               ! Iteration loop counter
      INTEGER J                  ! Loop counter
      INTEGER K                  ! Loop counter
      DOUBLE PRECISION R( NPAR ) ! RHS of normal equations and solutions
      REAL RSIG                  ! 1/sigma
      INTEGER UPAR               ! Number of parameters used
      DOUBLE PRECISION WKS1( NPAR ) ! Work space for PDA routine
      INTEGER WKS2( NPAR )       ! Work space for PDA routine
      REAL X( NPAR )             ! Statistics: 1=background,
                                 ! 2=amplitude, 3=sigma, 4=gamma

*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'      ! NUM definitions for conversions

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Constrain to a Gaussian.  Fit one fewer parameters and by definition
*  the residual is zero.
      IF ( GAUSS ) THEN
         UPAR = NPAR - 1
         GAMMA = 2.0
         R( NPAR ) = 0.0
      ELSE
         UPAR = NPAR
      END IF

*  Copy initial parameter estimates to array X.
      X( 1 ) = BACK
      X( 2 ) = AMP
      X( 3 ) = SIGMA
      X( 4 ) = GAMMA

*  Begin the iteration loop:
      DO ITER = 1, NITER

*  Initialise arrays for forming the linearised normal equations.
         DO I = 1, UPAR
            R( I ) = 0.0D0

            DO J = 1, UPAR
               A( I, J ) = 0.0D0
            END DO
         END DO

*  Consider each data point with positive weight.
         RSIG = 1.0 / X( 3 )

         DO I = 1, NP
            IF ( PW( I ) .GT. 1.0E-10 ) THEN

*  Form the required parameters for the normal equations.
               ALPHA = ( PR( I ) * RSIG ) *  * X( 4 )
               EX = EXP( - 0.5 * ALPHA )
               BETA = X( 2 ) * EX * ALPHA * 0.5

               C( 1 ) = 1.0D0
               C( 2 ) = EX
               C( 3 ) = BETA * RSIG * X( 4 )
               C( 4 ) = -BETA * LOG( MAX( VAL__SMLR, PR( I ) ) * RSIG )

*  Form the deviation of current profile from the data point.
               DELTA = ( X( 1 ) + X( 2 ) * EX - NUM_UBTOR( P( I ) ) )
     :                 * PW( I )

*  Form the sums for the normal equations. (Ax=R)
               DO J = 1, UPAR
                  R( J ) = R( J ) + DELTA * C( J )

                  DO K = 1, J
                     A( K, J ) = A( K, J ) + C( K ) * C( J ) * PW( I )
                  END DO
               END DO
            END IF
         END DO

*  Form the other half of the symmetric matrix of coefficients.
         DO J = 1, UPAR - 1
            DO I = J + 1, UPAR
               A( I, J ) = A( J, I )
            END DO
         END DO

*  Call a PDA routine to solve the normal equations.  Contain its
*  limited error handling in a new error context, and report specific
*  messages.  The fit is returned in R.
         CALL ERR_MARK
         IFAIL = 0
         CALL PDA_DGEFS( A, UPAR, UPAR, R, 1, ERRCO, WKS1, WKS2, IFAIL )
         IF ( IFAIL .NE. 0 ) CALL ERR_ANNUL( IFAIL )
         CALL ERR_RLSE

*  Watch for an error.
         IF ( ERRCO .EQ. -4 ) THEN
            STATUS = SAI__ERROR
            CALL MSG_SETI( 'IFAIL', ERRCO )
            CALL ERR_REP( 'KPS1_PGFTx_NORMEQ',
     :        'Error solving the normal equations for the Gaussian '/
     :        /'fit.  Normal-equation matrix is singular.', STATUS )
            GO TO 100
         END IF

*  Apply the resultant corrections to the profile parameters with
*  damping factors for large amplitude changes.
         X( 1 ) = X( 1 ) - R( 1 )
         X( 2 ) = X( 2 ) - R( 2 ) / ( 1.0 + 2.0 * ABS( R( 2 ) /
     :            MAX( VAL__SMLR, X( 2 ) ) ) )
         X( 3 ) = X( 3 ) - R( 3 ) / ( 1.0 + 2.0 * ABS( R( 3 ) /
     :            MAX( VAL__SMLR, X( 3 ) ) ) )
         X( 4 ) = X( 4 ) - R( 4 ) / ( 1.0 + 2.0 * ABS( R( 4 ) /
     :            MAX( VAL__SMLR, X( 4 ) ) ) )

*  Form the relative changes in each parameter.
         E1 = ABS( R( 1 ) / MAX( VAL__SMLR, X( 2 ) ) )
         E2 = ABS( R( 2 ) / MAX( VAL__SMLR, X( 2 ) ) )
         E3 = ABS( R( 3 ) / MAX( VAL__SMLR, X( 3 ) ) )
         E4 = ABS( R( 4 ) / MAX( VAL__SMLR, X( 4 ) ) )

*  If relative accuracy criterion is met, exit from iteration loop.
         IF ( MAX( E1, E2, E3, E4 ) .LE. TOLL ) THEN
            BACK = X( 1 )
            AMP = X( 2 )
            SIGMA = X( 3 )
            GAMMA = X( 4 )
            GO TO 100
         END IF

      END DO

* Issue warning that tolerance not met.
      CALL MSG_OUT( 'KPS1_PGFTx_TOLNM',
     :  '   Tolerance not met when fitting the radial Gaussian '/
     :  /'profile.', STATUS )
      CALL MSG_SETR( 'TOLL', TOLL )
      CALL MSG_FMTR( 'UTOLL', 'F7.5', MAX( E1, E2, E3, E4 ) )
      CALL MSG_OUT( 'KPS1_PGFTx_TOLFN',
     :  '   Requested tolerance: ^TOLL; achieved: ^UTOLL', STATUS )
      CALL MSG_BLANK( STATUS )

  100 CONTINUE

      END
