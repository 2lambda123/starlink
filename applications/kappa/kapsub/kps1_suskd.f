      SUBROUTINE KPS1_SUSKD( NX, X, NXKNOT, XKNOT, STATUS )
 
*+
*  Name:
*     KPS1_SUSKx
 
*  Purpose:
*     To place interior knots so as to maintain an even distribution
*     of data points between the knot positions when fitting spline
*     functions to data.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPS1_SUSKx( NX, X, NXKNOT, XKNOT, STATUS )
 
*  Arguments:
*     NX = INTEGER (Given)
*        The number of data points.
*     X( NX ) = ? (Given)
*        The co-ordinates of the points.
*     NXKNOT = INTEGER (Given)
*        The number of interior knots to be defined.
*     XKNOT( NXKNOT ) = ? (Returned)
*        The x positions of the interior knots defined.
*     STATUS = INTEGER (Given and Returned)
*        The global status.
 
*  Notes:
*     -  Uses the magic-value method for bad or undefined pixels.
*     -  There is a routine for double precision or real data types:
*     replace "x" in the routine name by D or R as appropriate.  The
*     X and XKNOT arguments supplied to the routine must have the data
*     type specified.
 
*  Algorithm:
*     - Calculate the mean number of data points per knot interval.
*     - Place the knots this number of data points apart, interpolating
*       linearly between the data positions to obtain the knot
*       positions.
 
*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1990 Jan 31 (MJC):
*        Original version based on the EDRS code of the same name.
*     1996 October 15 (MJC):
*        Renamed from SETKNT.  Made generic.  Transposed X and NX
*        arguments.  Modern style.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_new_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
 
*  Arguments Given:
      INTEGER NX                 ! Number of data points
      DOUBLE PRECISION X( NX )             ! Co-ordinates of the data
      INTEGER NXKNOT             ! Number of interior knots
 
*  Arguments Returned:
      DOUBLE PRECISION XKNOT( NXKNOT )     ! Positions of the interior knots
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      REAL DATAPT                ! Number of data points just less than
                                 ! the required knot value
      REAL FRAC                  ! Interpolation fraction
      INTEGER I                  ! Loop counter
      INTEGER NDAT1              ! Index to the lower data point used in
                                 ! the interpolation
      INTEGER NDAT2              ! Index to the upper data point used in
                                 ! the interpolation
      REAL XINTVL                ! Number of data points per knot
                                 ! interval
 
*.
 
*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Find the mean number of data points per knot interval.
      XINTVL = REAL( NX - 1 ) / ( REAL( NXKNOT ) + 1.0 )
 
*  Count through each knot, calculating the number of data points less
*  than the required knot value.
      DO  I = 1, NXKNOT
         DATAPT = 1.0 + XINTVL * REAL( I )
 
*  The result is not usually an integer, so interpolate linearly
*  between the ordered data positions.
         NDAT1 = INT( DATAPT )
         NDAT2 = MIN( NX, NDAT1 + 1 )
         FRAC = DATAPT - REAL( NDAT1 )
         XKNOT( I ) = X( NDAT1 ) * ( 1.0 - FRAC ) + X( NDAT2 ) * FRAC
      END DO
 
      END
