      SUBROUTINE ARD1_CRFND( FRM, NDIM, LBND, UBND, NPAR, D, PAR, 
     :                       LBINTB, UBINTB, STATUS )
*+
*  Name:
*     ARD1_CRFND

*  Purpose:
*     Find the pixel index bounds of an n-D sphere.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL ARD1_CRFND( FRM, NDIM, LBND, UBND, NPAR, D, PAR, LBINTB, UBINTB,
*                      STATUS )

*  Description:
*     The user co-ordinates of the intersection of the sphere with each
*     each axis of the user coordinate system are found (this allows for
*     different axis scales, e.g. for RA/DEC). These are transformed into 
*     pixel indices and the supplied bounds of the internal bounding box 
*     are updated to include all the corners.

*  Arguments:
*     FRM = INTEGER (Given)
*        User coord Frame.
*     NDIM = INTEGER (Given)
*        No. of dimensions.
*     LBND( NDIM ) = INTEGER (Given)
*        Lower bounds of mask.
*     UBND( NDIM ) = INTEGER (Given)
*        Upper bounds of mask.
*     NPAR = INTEGER (Given)
*        No. of values in PAR.
*     D( * ) = DOUBLE PRECISION (Given)
*        The coefficients of the user->pixel mapping. There should be
*        NDIM*(NDIM+1) elements in the array. The mapping is:
*
*        P1 = D0 + D1*U1 + D2*U2 + ...  + Dn*Un
*        P2 = Dn+1 + Dn+2*U1 + Dn+3*U2 + ...  + D2n+1*Un
*        ...
*        Pn = ...
*     PAR( NPAR ) = DOUBLE PRECISION (Given)
*        Parameters; user coords of sphere centre, followed by the radius.
*     LBINTB( NDIM ) = INTEGER (Returned)
*        The lower bounds of the internal bounding box.
*     UBINTB( NDIM ) = INTEGER (Returned)
*        The upper bounds of the internal bounding box.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     21-AUG-2001 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! VAL_ constants
      INCLUDE 'ARD_CONST'        ! ARD private constants

*  Arguments Given:
      INTEGER FRM
      INTEGER NDIM
      INTEGER LBND( NDIM )
      INTEGER UBND( NDIM )
      INTEGER NPAR
      DOUBLE PRECISION D( * ) 
      DOUBLE PRECISION PAR( NPAR )

*  Arguments Returned:
      INTEGER LBINTB( NDIM )
      INTEGER UBINTB( NDIM )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER
     :     I,                    ! Dimension counter
     :     J,                    ! Dimension counter
     :     PINDEX                ! Pixel index value

      DOUBLE PRECISION 
     :     P2( ARD__MXDIM ),     ! User coordinates of target point
     :     PIXCO( ARD__MXDIM ),  ! Pixel coordinates for current corner
     :     USERCO( ARD__MXDIM )  ! User coordinates for current corner

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the interior bounding box.
      DO I = 1, NDIM
         LBINTB( I ) = VAL__MAXI
         UBINTB( I ) = VAL__MINI
      END DO

*  Loop round each dimension.
      DO I = 1, NDIM

*  Store the user coords of a point displaced a little away from the centre 
*  along the I'th axis.
         DO J = 1, NDIM
            P2( J ) = PAR( J )
         END DO

         IF( PAR( I ) .EQ. 0.0 ) THEN
            P2( I ) = 0.1
         ELSE
            P2( I ) = 1.1*P2( I )
         END IF            

*  Offset away from the centre towards this second point, going a
*  distance equal to the sphere radius.
         CALL AST_OFFSET( FRM, PAR, P2, PAR( NDIM + 1), USERCO, 
     :                    STATUS )

*  Transform the resulting user position to pixel coordinates.
         CALL ARD1_LTRAN( NDIM, D, 1, USERCO, PIXCO, STATUS )

*  Convert the pixel co-ordinates to pixel indices and update the upper
*  and lower bounds of the internal bounding box.
         DO J = 1, NDIM
            PINDEX = DBLE( INT( PIXCO( J ) ) )
            IF( PINDEX .LT. PIXCO( J ) ) PINDEX = PINDEX + 1

            LBINTB( J ) = MIN( LBINTB( J ), PINDEX )
            UBINTB( J ) = MAX( UBINTB( J ), PINDEX )

         END DO

*  Now offset in the opposite direction by the same amount (do this by
*  negating the offset distance).
         CALL AST_OFFSET( FRM, PAR, P2, -PAR( NDIM + 1), USERCO, 
     :                    STATUS )

*  Transform the resulting user position to pixel coordinates.
         CALL ARD1_LTRAN( NDIM, D, 1, USERCO, PIXCO, STATUS )

*  Convert the pixel co-ordinates to pixel indices and update the upper
*  and lower bounds of the internal bounding box.
         DO J = 1, NDIM
            PINDEX = DBLE( INT( PIXCO( J ) ) )
            IF( PINDEX .LT. PIXCO( J ) ) PINDEX = PINDEX + 1

            LBINTB( J ) = MIN( LBINTB( J ), PINDEX )
            UBINTB( J ) = MAX( UBINTB( J ), PINDEX )

         END DO

      END DO

*  Ensure that the returned bounding box does not exceed the bounds of
*  the mask.
      DO I = 1, NDIM
         LBINTB( I ) = MAX( LBINTB( I ), LBND( I ) )
         UBINTB( I ) = MIN( UBINTB( I ), UBND( I ) )

*  If the lower bound is higher than the upper bound, return with a 
*  null box
         IF( LBINTB( I ) .GT. UBINTB( I ) ) THEN
            LBINTB( 1 ) = VAL__MINI
            GO TO 999
         END IF

      END DO

 999  CONTINUE

      END
