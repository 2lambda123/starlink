      SUBROUTINE KPS1_FSPF2( XMIN, XMAX, YMIN, YMAX, NXPAR, NYPAR,
     :                       FIRST, NBIN, MCOEF, MAXBIN, X, Y, Z, W, A,
     :                       V, COVAR, CHCOEF, VARIAN, NCOEF, STATUS )
*+
*  Name:
*     KPS1_FSPF2

*  Purpose:
*     Fits a polynomial surface by least squares to an input
*     2-dimensional array.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_FSPF2( XMIN, XMAX, YMIN, YMAX, NXPAR, NYPAR, FIRST,
*                      NBIN, MCOEF, MAXBIN, X, Y, Z, W, A, V, COVAR,
*                      CHCOEF, VARIAN, NCOEF, STATUS )

*  Description:
*     This routine fits a bivariate Chebyshev polynomial for the given
*     vectors of values and weights at the given x-y co-ordinates.  It
*     returns the coefficients of the fit and their normalised
*     variances.

*  Arguments:
*     XMIN = DOUBLE PRECISION (Given)
*        Lower end of the x range of the fit.  It must not be greater
*        than the x position of the first pixel in the data array.
*     YMIN = DOUBLE PRECISION (Given)
*        Lower end of the y range of the fit.  It must not be greater
*        than the y position of the first pixel in the data array.
*     XMAX = DOUBLE PRECISION (Given)
*        Upper end of the x range of the fit.  It must not be less
*        than the x position of the last pixel in the data array.
*     YMAX = DOUBLE PRECISION (Given)
*        Lower end of the y range of the fit.  It must not be less
*        than the y position of the last pixel in the data array.
*     NXPAR = INTEGER (Given)
*        The number of parameters of the fit in the x direction, i.e.
*        the degree of the polynomial plus one.
*     NYPAR = INTEGER (Given)
*        The number of parameters of the fit in the y direction, i.e.
*        the degree of the polynomial plus one.
*     FIRST = LOGICAL (Given)
*        If .TRUE., the weights will be squared.  (The variance or
*        number of original pixels in a bin is needed for the fitting
*        subroutine.)
*     NBIN = INTEGER (Given)
*        The number of data points to be fitted by least-squares.
*     MCOEF = INTEGER (Given)
*        The maximum number of Chebyshev coefficients.  Must be between
*        1 and 120.
*     MAXBIN = INTEGER (Given)
*        The dimension of the data, weight and co-ordinate vectors.
*     X( MAXBIN ) = DOUBLE PRECISION (Given)
*        The x co-ordinates of the points to be evaluated.
*     Y( MAXBIN ) = DOUBLE PRECISION (Given)
*        The y co-ordinates of the points to be evaluated.
*     Z( MAXBIN ) = DOUBLE PRECISION (Given)
*        The values at the given x-y positions.
*     W( MAXBIN ) = DOUBLE PRECISION (Given and Returned)
*        The weights at the given x-y positions.
*     A( MCOEF, MCOEF ) = DOUBLE PRECISION (Returned)
*        Work space to hold the normal-equation coefficients
*        (covariance).
*     V( MCOEF, MCOEF ) = DOUBLE PRECISION (Returned)
*        Work space to hold the orthogonal matrix used by SVD.
*     COVAR( MCOEF, MCOEF ) = DOUBLE PRECISION (Returned)
*        Work array to stored the covariance matrix of the fit.
*     CHCOEF( NXPAR * NYPAR ) = DOUBLE PRECISION (Returned)
*        The Chebyshev polynomial coefficients, in the order increasing
*        x power for each increasing y power.  Thus coefficient Aij in
*        the standard convention is %CHCOEF(i*(%NYPAR)+j+1).  The array
*        may be rectangular, i.e. the highest x and y orders do not
*        have to be the same.
*     VARIAN( NXPAR * NYPAR ) = DOUBLE PRECISION (Returned)
*        The normalised variances of the Chebyshev polynomial
*        coefficients and correspond to the elements of CHCOEF.
*     NCOEF = INTEGER (Given)
*        The number of Chebyshev coefficients used.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  Uses the magic-value method for bad or undefined pixels.

*  Algorithm:
*     -  Compare number of free fitting parameters with the number of
*        bins and quit if there is insufficient data.  Also compare
*        with the maximum number of coefficients.
*     -  Convert the weights to the number of pixels in the bin if first
*        time through.
*     -  Form sums for the normal equations, summing over all the data
*        points.
*     -  Evaluate the Chebyshev polynomials of the orders required along
*        each axis at the x then y data position.
*     -  Form the required products of the x and y polynomials.
*     -  Omit those products which are too high an order in xy.
*     -  Add the products to the normal-equation sums (a term for each
*        product).
*     -  Solve the normal equations.
*     -  Put the solution coefficients into an array with the terms not
*        required set to zero.
*     -  Should the fit be not unique then warn the user.

*  Copyright:
*     Copyright (C) 1990-1991, 1993 Science & Engineering Research
*     Council. Copyright (C) 1995-1996 Central Laboratory of the
*     Research Councils. All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1990 Jan 30 (MJC):
*        Original version based on EDRS code.
*     1991 July 5 (MJC):
*        Passed A and AA as arguments plus their dimension, the maximum
*        number of coefficients.  Validates input maximum number of
*        coefficients in case it is greater in the calling routine than
*        allowed here, and added commentary on this point.
*     1993 April 22 (SMB):
*        Changed size of CHCOEF array from MCOEF to NXPAR * NYPAR.
*        A temporary fix - awaits official fix from Malcolm Currie.
*     1995 August 3 (MJC):
*        Renamed from PLY2D.  Used a modern prologue and style.
*     1996 January 29 (MJC):
*        Replaced NAG calls.  As a result the AA argument was surplus
*        to requirements.
*     {enter_further_changes_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      DOUBLE PRECISION XMIN, XMAX ! X bounds of the fit
      DOUBLE PRECISION YMIN, YMAX ! Y bounds of the fit
      INTEGER NXPAR              ! X degree of the polynomial plus 1
      INTEGER NYPAR              ! Y degree of the polynomial plus 1
      LOGICAL FIRST              ! Weights are to be squared?
      INTEGER NBIN               ! Number of points for evaluation
      INTEGER MCOEF              ! Max. number of Chebyshev coefficients
      INTEGER MAXBIN             ! Dimension of the data vectors
      DOUBLE PRECISION X( MAXBIN ) ! X co-ordinates of the data
      DOUBLE PRECISION Y( MAXBIN ) ! Y co-ordinates of the data
      DOUBLE PRECISION Z( MAXBIN ) ! Data values

*  Arguments Given and Returned:
      DOUBLE PRECISION W( MAXBIN ) ! Data weights

*  Arguments Returned:
      DOUBLE PRECISION A( MCOEF, MCOEF ) ! Normal-equation coefficients
                                 ! (covariance)
      DOUBLE PRECISION V( MCOEF, MCOEF ) ! Work space for SVD orthogonal
                                 ! matrix
      DOUBLE PRECISION COVAR( MCOEF, MCOEF ) ! Covariance matrix
      DOUBLE PRECISION CHCOEF( NXPAR * NYPAR ) ! Chebyshev coefficients
      DOUBLE PRECISION VARIAN( NXPAR * NYPAR ) ! Coefficient variances
      INTEGER NCOEF              ! Number of Chebyshev coefficients

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      INTEGER MXPAR              ! Maximum number of parameters which
                                 ! can be handled in each direction
                                 ! Not all the small work arrays are
                                 ! obtained externally because of
                                 ! efficiency considerations.  This
                                 ! constant should be the same value or
                                 ! greater than it has in calling
                                 ! applications.
      PARAMETER ( MXPAR = 15 )

      INTEGER MXCOEF             ! Maximum number of Chebyshev
                                 ! coefficients
      PARAMETER ( MXCOEF = ( MXPAR * ( MXPAR + 1 ) ) / 2 )

*  Local Variables:
      DOUBLE PRECISION B( MXCOEF ) ! Normal-equation coefficients and
                                 ! solution
      DOUBLE PRECISION CC( MXPAR ) ! Chebyshev coefficients in x or y
      INTEGER ERRCO              ! PDA error indicator
      INTEGER I                  ! Loop counter
      INTEGER IBIN               ! Bin counter
      INTEGER IFAIL              ! PDA error status
      INTEGER J                  ! Loop counter
      INTEGER K                  ! Coefficient index
      INTEGER NC                 ! Number of Chebyshev coefficients
                                 ! so far
      DOUBLE PRECISION PX( MXPAR ) ! Work array
      DOUBLE PRECISION PY( MXPAR ) ! Work array
      DOUBLE PRECISION WKS1( MXCOEF ) ! Work array (W diagonal matrix)
      DOUBLE PRECISION WKS2( MXCOEF ) ! Work array for SVD
      DOUBLE PRECISION WKS3( MXCOEF ) ! Work array for coefficients

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Compare the number of free fitting parameters and quit if there are
*  insufficient data.
      IF ( NBIN .LT. MCOEF ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'NBIN', NBIN )
         CALL MSG_SETI( 'MCOEF', MCOEF )
         CALL ERR_REP( 'KPS1_FSPF2_INSFD',
     :     'KPS1_FSPF2: Insufficient data --- ^NBINS bins and ^MCOEF '/
     :     /'free parameters.', STATUS )
         GOTO 999
      END IF

*  Compare the number of free fitting parameters with the maximum
*  permitted by this routine.  This is to protect against a difference
*  of MXPAR between this and the calling routine.
      IF ( MXCOEF .LT. MCOEF ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'MXCOEF', MXCOEF )
         CALL MSG_SETI( 'MCOEF', MCOEF )
         CALL ERR_REP( 'KPS1_FSPF2_INSFCO',
     :     'KPS1_FSPF2: More coefficients requested (^MCOEF) than is '/
     :     /'supported (^MXCOEF).', STATUS )
         GOTO 999
      END IF

*  Convert data weights to represent the number of pixels in bin.
      IF ( FIRST ) THEN
         DO I = 1, NBIN
            W( I ) = W( I ) * W( I )
         END DO
      END IF

*  Initialise arrays to hold the coefficients of normal equations.
      DO J = 1, MCOEF
         B( J ) = 0.0D0

         DO I = 1, MCOEF
            A( I, J ) = 0.0D0
         END DO
      END DO

*  Form sums for normal equations, summing over all the data points.
      DO IBIN = 1, NBIN

*  Initialise coefficients for evaluating Chebyshev polynomials.
         DO I = 1, MAX( NXPAR, NYPAR )
            CC( I ) = 0.0D0
         END DO

*  Evaluate the Chebyshev polynomials of the orders required along each
*  axis at the data position.
         DO I = 1, MAX( NXPAR, NYPAR )
            CC( I ) = 1.0D0

            IF ( I .LE. NXPAR ) THEN
               CALL KPG1_CHEVD( XMIN, XMAX, I, CC, 1, X( IBIN ),
     :                          PX( I ), STATUS )
               IF ( STATUS .NE. SAI__OK ) GOTO 999
            END IF

            IF ( I .LE. NYPAR ) THEN
               CALL KPG1_CHEVD( YMIN, YMAX, I, CC, 1, Y( IBIN ),
     :                          PY( I ), STATUS )
               IF ( STATUS .NE. SAI__OK ) GOTO 999
            END IF

*  Reset the coefficient.
            CC( I ) = 0.0D0
         END DO

*  Now form the required products of the x and y polynomials.
         NC = 0

         DO J = 1, NYPAR
            DO I = 1, NXPAR

*  Omit those products which are of too high an order in x or y.
               IF ( I .GT. 1 .AND. I + J - 1 .GT. NXPAR ) GOTO 20

               IF ( J .GT. 1 .AND. I + J - 1 .GT. NYPAR ) GOTO 20

*  Store the required products.
               NC = NC + 1
               CHCOEF( NC ) = PX( I ) * PY( J )
            END DO
   20       CONTINUE
         END DO

*  Add to the normal equation sums (a term for each product).
         DO J = 1, NC
            B( J ) = B( J ) + CHCOEF( J ) * W( IBIN ) * Z( IBIN )

            DO I = 1, NC
               A( I, J ) = A( I, J ) +
     :                     CHCOEF( I ) * CHCOEF( J ) * W( IBIN )
            END DO
         END DO

      END DO

*  Solve the normal equations using singular-value decomposition.
*  Factorise the matrix, solve, and generate the covariance matrix.
      CALL SLA_SVD( NC, NC, MCOEF, MCOEF, A, WKS1, V, WKS2, IFAIL )
      CALL SLA_SVDSOL( NC, NC, MCOEF, MCOEF, B, A, WKS1, V, WKS2, WKS3 )
      CALL SLA_SVDCOV( NC, MCOEF, MCOEF, WKS1, V, WKS2, COVAR )

*  Watch for an error.
      IF ( IFAIL .EQ. -1 ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'IFAIL', ERRCO )
         CALL ERR_REP( 'KPS1_FSPF2_NORMEQ',
     :     'Error solving the normal equations for the surface '/
     :     /'fit.  Normal-equation matrix has wrong shape.', STATUS )
         GO TO 999
      END IF

*  Put the solution coefficients into an array with the terms not
*  required set to zero.
      NC = 0

      DO J = 1, NYPAR
         DO I = 1, NXPAR

            CHCOEF( ( I - 1 ) * NYPAR + J ) = 0.0D0

*  Leave zeroes in if the term is of too high an order in x or y.
            IF ( I .GT. 1 .AND. I + J - 1 .GT. NXPAR ) GOTO 50

            IF ( J .GT. 1 .AND. I + J - 1 .GT. NYPAR ) GOTO 50

*  Otherwise put the appropriate coefficient into the store.
            NC = NC + 1
            K = ( I - 1 ) * NYPAR + J 
            CHCOEF( K ) = WKS3( NC )

*  Store the normalised variance from the covariance matrix.
            VARIAN( K ) = COVAR( NC, NC )

   50       CONTINUE
         END DO
      END DO

      NCOEF = NC

  999 CONTINUE

      END
