      SUBROUTINE CCD1_ORVAR( NSET, NBIG, PP, VEC, STATUS )
*+
*  Name:
*     CCD1_ORVAR

*  Purpose:
*     To return the variances and covariances of the order statistics
*     from n to 1, assuming an initially normal distribution.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCD1_ORVAR( NSET, NBIG, PP, VEC, STATUS )

*  Description:
*     The routine returns the variances and covariances of the order
*     statistics, assuming an initial (pre-ordered) normal distribution
*     of mean 0 and standard deviation 1. The routine returns all
*     variance/covariances in an array with the terms vectorised - that
*     is following on after each row. This uses the symmetric nature of
*     the matrix to compress the data storage, but remember to double
*     the covariance components if summing in quadrature. The variances
*     -covariances are returned for all statistics from n to 1. The
*     special case of n = 1 returns the variance of 2/pi (median).

*  Arguments:
*     NSET = INTEGER (Given)
*        Number of members in ordered set.
*     NBIG = INTEGER (Given)
*        Maximum number of entries in covariance array row.
*        equal to NSET*(NSET+1)/2).
*     PP( NSET ) = DOUBLE PRECISION (Given)
*        Workspace for storing expected values of order statistics.
*     VEC( NBIG, NSET ) = DOUBLE PRECISION (Returned)
*        The upper triangles of the nset by nset variance-covariance
*        matrix packed by columns. Each triangle is packed into a
*        single row. For each row element Vij is stored in
*        VEC(i+j*(j-1)/2), for 1<=i<=j<=nset.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - Data is returned as above to save on repeated calls (which are
*     too slow). To get the actual variance of the data of order n you
*     need to sum all the variances and twice the covariances and use
*     these to modify the actual variance of the (unordered) data.
*
*     - It is assumed that NSET cannot be any larger than CCD1__MXNDF.    

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     28-MAR-1991 (PDRAPER):
*        Original version.
*     22-MAY-1992 (PDRAPER):
*        Changed 2/pi to pi/2 - in line with other variances.
*     4-SEP-1996 (PDRAPER):
*        Replaced NAG routine calls with public domain versions.
*        Interface remains the same except limit on NSET is now
*        CCD1__MXNDF (needed extra workspace and this is the easiest
*        place to create it).
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}
*-

*  Type Definitions:
      IMPLICIT NONE             ! No implicit typing
      
*     Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'CCD1_PAR'

*  Arguments Given:
      INTEGER NSET
      INTEGER NBIG
      DOUBLE PRECISION PP( NSET )

*  Arguments Returned:
      DOUBLE PRECISION VEC( NBIG, NSET)

*  Local Constants:
      DOUBLE PRECISION PIBY2
      PARAMETER ( PIBY2 = 1.57079632679  ) ! PI/2.0

*  Status:
      INTEGER STATUS            ! Global status

*  External references:
      DOUBLE PRECISION PDA_V11
      EXTERNAL PDA_V11

*  Local Variables:
      DOUBLE PRECISION MATRIX( CCD1__MXNDF, CCD1__MXNDF ) ! Workspace
      DOUBLE PRECISION SUMSQ    ! Sum of squares
      DOUBLE PRECISION EXP1     ! Smallest expectation value
      DOUBLE PRECISION EXP2     ! Second smallest expectation value
      DOUBLE PRECISION V11      ! Value of extreme variance (1,1)
      INTEGER I, J, K, L        ! Loop variables
      INTEGER IFAIL             ! Local status return
      INTEGER N2                ! Half of matrix size

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Loop for all possible values of the ordered set size.
      DO 1  I = 1, NSET
         IF( I .EQ. 1 ) THEN

*  If just have the one nset then the appropriate value is pi/2.
            VEC( 1, 1 ) = PIBY2
         ELSE

*  Get the expected values of the normal order statistics.
            N2 = I/2
            CALL PDA_NSCOR( PP, I, N2, IFAIL )

            EXP1 = PP( 1 )
            IF ( I .EQ. 2 ) THEN
               EXP2 = -EXP1
            ELSE IF ( I .EQ. 3 ) THEN 
               EXP2 = 0.0D0
            ELSE
               EXP2 = PP( 2 )
            END IF

*  Form sum of squares of the expected values of the normal order
*  statistics
            SUMSQ= 0.0D0
            DO 2 J = 1, N2
               SUMSQ = PP( J ) * PP( J ) + SUMSQ
 2          CONTINUE
            SUMSQ = SUMSQ * 2.0D0

*  Get the covariance matrix for I*I.
            V11 = PDA_V11( I, IFAIL )
            CALL PDA_COVMAT( MATRIX, I, CCD1__MXNDF, V11, PP( 1 ), 
     :                       PP( 2 ), SUMSQ, IFAIL)

*  Now pack this into the output matrix in the form recognised by other
*  routines.
            K = 1
            DO 3 J = 1, I
               DO 4 L = 1, J
                  VEC( K, I ) = MATRIX( L, J )
                  K = K + 1
 4             CONTINUE
 3          CONTINUE
         END IF
 1    CONTINUE
      END
* @(#)ccd1_orvar.f	2.2     9/9/96     2
