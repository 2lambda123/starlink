      SUBROUTINE CCG1_TMN2D( IGNORE, ORDDAT, SVAR, NSET, USED, COVAR,
     :                         TMEAN, TVAR, STATUS )
*+
*  Name:
*     CCG1_TMN2D

*  Purpose:
*     To form the n-trimmed mean of the given set of ordered data.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCG1_TMN2D( ORDDAT, ORDVAR, NSET, USED, COVAR, TMEAN,
*                        TVAR, STATUS )

*  Description:
*     The routine forms the trimmed mean of the given dataset. The
*     IGNORE upper and lower ordered values are removed from
*     consideration.  Then the remaining values are added and averaged.
*     The SVAR value is a (given) best estimate of the original
*     un-ordered population variance. The variance of the output value
*     is formed assuming that the original dataset was normal in
*     distribution, and is now fairly represented by the ordered
*     statistics variances-covariances supplied in packed form in
*     COVAR. The values not rejected are indicated by setting the flags
*     in array used.

*  Arguments:
*     IGNORE = INTEGER (Given)
*        The number of values to ignore from the upper and lower orders.
*     ORDDAT( NSET ) = DOUBLE PRECISION (Given)
*        The set of ordered data for which a trimmed mean is required.
*     SVAR( NSET ) = DOUBLE PRECISION (Given)
*        The variance of the unordered sample now ordered in ORDDAT.
*     NSET = INTEGER (Given)
*        The number of entries in ORDDAT.
*     USED( NSET ) = LOGICAL (Returned)
*        Flags showing which values have not been rejected.
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
*     4-APR-1991 (PDRAPER):
*        Changed to remove n values from upper and lower orders
*        instead of a given fraction.
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
      INCLUDE 'PRM_PAR'          ! PRIMDAT constants

*  Arguments Given:
      INTEGER IGNORE
      INTEGER NSET
      DOUBLE PRECISION ORDDAT( NSET )
      DOUBLE PRECISION SVAR
      DOUBLE PRECISION COVAR( * )

*  Arguments Returned:
      DOUBLE PRECISION TMEAN
      DOUBLE PRECISION TVAR
      LOGICAL USED( NSET )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I, J               ! Loop variables
      DOUBLE PRECISION VSUM      ! Sum of the variances and covariances
                                 ! for ordered statistics
      INTEGER NLEFT              ! Number of values left to process
      INTEGER LBND               ! Lower index of used values
      INTEGER UBND               ! Upper index of used values

*  Local references:
      INCLUDE 'NUM_DEC_CVT'
      INCLUDE 'NUM_DEF_CVT'      ! Primdat conversion definition
                                 ! functions
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Make sure that there are enough variables left after ignoring the
*  outer ones. If there are not set output values to BAD and set used
*  to false.
      NLEFT = NSET - 2 * IGNORE
      IF ( NLEFT .LE. 0 ) THEN
         TMEAN = VAL__BADD
         TVAR = VAL__BADD
         DO 4 I = 1, NSET
            USED( I ) = .FALSE.
 4       CONTINUE
      ELSE

*  Set the bounds
         LBND = IGNORE + 1
         UBND = NSET - IGNORE

*  Loop over all values forming the sum of values for trimmed mean.
*  Set used flags
         TMEAN = 0.0D0
         DO 1 I = 1, NSET
            IF( I .GE. LBND .AND. I .LE. UBND ) THEN
               TMEAN = NUM_DTOD( ORDDAT( I ) ) + TMEAN
               USED( I ) = .TRUE.
            ELSE
               USED( I ) = .FALSE.
            END IF
 1       CONTINUE
         TMEAN = TMEAN / DBLE( NLEFT )

*  Sum the relevant ordered statistic variances and covariances.
*  weighting accordingly.
         VSUM = 0.0D0
         DO 2 I = LBND , UBND
            DO 3 J = I, UBND

*  Sum variances and twice covariances ( off diagonal elements ).
               IF( I .EQ. J ) THEN
                  VSUM = VSUM+ COVAR( I + J* ( J - 1 ) / 2 )
               ELSE
                  VSUM = VSUM+ 2.0D0 * COVAR( I + J* ( J - 1 ) / 2 )
               END IF
 3          CONTINUE
 2       CONTINUE

*  Right make the new variance estimate. Use the sum of variances
*  and covariances of the order statistic of the trimmed sample size
*  Sample variance changes to NSET * SVAR to represent total variance
*  of original data.
         TVAR = SVAR * NSET * VSUM / DBLE( NLEFT * NLEFT )

      END IF
      END
* $Id$
