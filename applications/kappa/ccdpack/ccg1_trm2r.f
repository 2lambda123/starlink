      SUBROUTINE CCG1_TRM2R( ALPHA, ORDDAT, SVAR, NSET, USED, COVAR,
     :                         TMEAN, TVAR, STATUS )
*+
*  Name:
*     CCG1_TRM2R

*  Purpose:
*     To form the trimmed mean of the given set of ordered data,
*     returning flags showing which values are used.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCG1_TRM2R( ALPHA, ORDDAT, ORDVAR, NSET, USED, COVAR,
*                        TMEAN, TVAR, STATUS )


*  Description:
*     The routine forms the trimmed mean of the given dataset. The
*     alpha (as a fraction) upper and lower ordered values are removed
*     from consideration.  Then the remaining values are added and
*     averaged. The SVAR value is a (given) best estimate of the
*     original un-ordered population variance. The variance of the
*     output value is formed assuming that the original dataset was
*     normal in distribution, and is now fairly represented by the
*     ordered statistics variances-covariances supplied in packed form
*     in COVAR. The elements of the input array which actually
*     contribute to the final value are flagged in the used array.

*  Arguments:
*     ALPHA = REAL (Given)
*        The fraction of data to trim from upper and lower orders.
*        (MUST BE GREATER THAN 0.0 AND LESS 0.5)
*     ORDDAT( NSET ) = REAL (Given)
*        The set of ordered data for which a trimmed mean is required.
*     SVAR( NSET ) = DOUBLE PRECISION (Given)
*        The variance of the unordered sample now ordered in ORDDAT.
*     NSET = INTEGER (Given)
*        The number of entries in ORDDAT.
*     USED( NSET ) = LOGICAL (Returned)
*        If the corresponding value in ORDDAT contributes to the final
*        value then this is set true.
*     COVAR( * ) = DOUBLE PRECISION (Given)
*        The packed variance-covariance matrix of the order statistics
*        from a normal distribution of size NSET.
*     TMEAN = DOUBLE PRECISION (Returned)
*        The trimmed mean.
*     TVAR = DOUBLE PRECISION (Returned)
*        A variance estimate of the trimmed mean.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Prior Requirements:
*     -  The variance-covariance array must have been generated in a
*     fashion similar to that of ORDVAR.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     28-MAR-1991 (PDRAPER):
*        Original version.
*     30-MAY-1991 (PDRAPER):
*        Added the used argument.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      REAL ALPHA
      INTEGER NSET
      REAL ORDDAT( NSET )
      DOUBLE PRECISION SVAR
      DOUBLE PRECISION COVAR( * )

*  Arguments Returned:
      DOUBLE PRECISION TMEAN
      DOUBLE PRECISION TVAR
      LOGICAL USED( NSET )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER IGNORE             ! Number of eliminated measurements
                                 ! from upper and lower orders.
      INTEGER I, J               ! Loop variables
      DOUBLE PRECISION VSUM      ! Sum of the variances and covariances
                                 ! for ordered statistics
      DOUBLE PRECISION INWEI
      DOUBLE PRECISION OUTWEI    ! Weights for values and outer most
                                 ! values (nominally 1/(nset-2alpha))
      DOUBLE PRECISION IW, JW    ! Weights for covariance summation.
      DOUBLE PRECISION WSUM      ! Sum of weights - required if large
                                 ! trimming fractions to ensure
                                 ! re-normalisation.
      DOUBLE PRECISION DUMMY     ! Dummy to save working
      REAL FRAC                  ! Fractional difference between odd
                                 ! centered values and actual values.
      REAL DENOM                 ! Divisor always checked to be.
      INTEGER LBND               ! Lower index of contributing values
      INTEGER UBND               ! Upper index of contributing values

*  Local references:
      INCLUDE 'NUM_DEC_CVT'
      INCLUDE 'NUM_DEF_CVT'      ! Primdat conversion definition
                                 ! functions
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Check alpha - essential that it is greater than zero and less than
*  0.5
      IF ( ALPHA .GT. 0.0 .AND. ALPHA .LT. 0.5 ) THEN

*  How many values are to be ignored from each end of the order
*  dataset?
         IGNORE = INT(ALPHA * REAL( NSET ) )

*  Fractional difference between the idea trimmed state and the
*  actual state. This is used in weighting the outer observations.
         FRAC = REAL( ALPHA * REAL( NSET ) - INT( ALPHA * NSET ) )

*  Calculate the weights for the edge values and inner values.
         DENOM = REAL( NSET ) * ( 1.0 - 2.0 * ALPHA )
         OUTWEI = DBLE( ( 1.0 - FRAC ) / DENOM )
         INWEI  = DBLE( 1.0 / DENOM )

*  Set up the upper and lower bounds for the useful values.
         LBND = IGNORE + 1
         UBND = NSET - IGNORE

*  Loop over all values forming the sum of values for trimmed mean.
         TMEAN = 0.0D0
         WSUM = 0.0D0
         DO 1 I = 1, NSET
            IF( I .EQ. LBND .OR. I .EQ. UBND ) THEN

*   Use outer weight at these extreme.
               TMEAN = NUM_RTOD( ORDDAT( I ) ) * OUTWEI + TMEAN
               WSUM = WSUM + OUTWEI

*  Use inner weight for these values
            ELSE IF ( I .GE. LBND + 1 .AND. I .LE. UBND -1 ) THEN
               TMEAN = NUM_RTOD( ORDDAT( I ) ) * INWEI + TMEAN
               WSUM = WSUM + INWEI
            ELSE

*  Ignore these values, they lie outside of IGNORE and NSET-IGNORE+1
            END IF
 1       CONTINUE

*  Re-normalise trimmed mean.
         TMEAN = TMEAN / WSUM

*  Sum the relevant ordered statistic variances and covariances.
*  weighting accordingly.
         WSUM = 0.0D0
         VSUM = 0.0D0
         DO 2 I = LBND, UBND
            IF( I .EQ. LBND .OR. I .EQ. UBND ) THEN
               IW = OUTWEI
            ELSE
               IW = INWEI
            END IF
            DO 3 J = I, UBND
               IF( J .EQ. LBND .OR. J .EQ. UBND ) THEN
                  JW = OUTWEI
               ELSE
                  JW = INWEI
               END IF

*  Sum variances and twice covariances ( off diagonal elements ).
               IF( I .EQ. J ) THEN
                  DUMMY = IW * JW
                  VSUM = VSUM + DUMMY * COVAR( I + J * ( J - 1 )/ 2 )
                  WSUM = WSUM + DUMMY
               ELSE
                  DUMMY = IW * JW * 2.0D0
                  VSUM = VSUM + DUMMY * COVAR( I + J * ( J - 1 )/ 2 )
                  WSUM = WSUM + DUMMY
               END IF
 3          CONTINUE
 2       CONTINUE

*  Renormalise variance sum by weights
         VSUM = VSUM / WSUM

*  Set up the used variable array.
         DO 4 I = 1, NSET
            IF ( I .GE. LBND .AND. I .LE. UBND ) THEN
               USED( I ) = .TRUE.
            ELSE
               USED( I ) =.FALSE.
            END IF
 4       CONTINUE

*  Right make the new variance estimate. Use the sum of variances
*  and covariances of the order statistic of the trimmed sample size
*  Sample variance changes to NSET * SVAR to represent total variance
*  of original data.
         TVAR = SVAR * NSET * VSUM
      ELSE

*  Invalid alpha ...
         CALL MSG_SETD( 'ALPHA', ALPHA )
         STATUS = SAI__ERROR
         CALL ERR_REP( 'CCG1_TRM2_ALPH', 'Invalid value for ALPHA'//
     :   ' trimming fraction ^ALPHA : must be greater than 0.0 less'//
     :    'than 0.5' , STATUS )
      END IF
      END
* $Id$
