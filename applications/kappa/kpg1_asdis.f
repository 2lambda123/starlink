      DOUBLE PRECISION FUNCTION KPG1_ASDIS( FRAME, DIM, NAX, POS, I1, 
     :                                      I2, GEO, STATUS )
*+
*  Name:
*     KPG1_ASDIS

*  Purpose:
*     Find the distance between two points.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     RESULT = KPG1_ASDIS( FRAME, DIM, NAX, POS, I1, I2, GEO, STATUS )

*  Description:
*     This routine returns the distance between two positions in the 
*     supplied co-ordinate Frame. Either the geodesic or Euclidean distance 
*     can be returned.

*  Arguments:
*     FRAME = INTEGER (Given)
*        An AST pointer to the Frame. Only accessed if GEO is .TRUE.
*     DIM = INTEGER (Given)
*        The size of the first dimension of the POS array.
*     NAX = INTEGER (Given)
*        The number of axes in the Frame.
*     POS( DIM, NAX ) = DOUBLE PRECISION (Given)
*        An array holding the co-ordinates at DIM positions within the
*        supplied Frame.
*     I1 = INTEGER (Given)
*        The index of the first position, in the range 1 to DIM.
*     I2 = INTEGER (Given)
*        The index of the second position, in the range 1 to DIM.
*     GEO = LOGICAL (Given)
*        Is the geodesic distance required?
*     STATUS = INTEGER (Given)
*        Global status value.

*  Returned Value:
*     KPG1_ASDIS = DOUBLE PRECISION
*        The distance between the two points.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     10-SEP-1998 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_new_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE            

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_PAR'          ! NDF constants 
      INCLUDE 'AST_PAR'          ! AST constants and functions

*  Arguments Given:
      INTEGER FRAME
      INTEGER DIM
      INTEGER NAX
      DOUBLE PRECISION POS( DIM, NAX )
      INTEGER I1
      INTEGER I2
      LOGICAL GEO

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      
*  Local Variables:
      DOUBLE PRECISION L2        ! The sum of squared axis increments
      DOUBLE PRECISION P1( NDF__MXDIM )! The first position
      DOUBLE PRECISION P2( NDF__MXDIM )! The second position
      INTEGER J                  ! Axis index
      LOGICAL GOOD               ! Both positions good?
*.

*  Initialise.
      KPG1_ASDIS = 0.0D0

*  Check the global inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Store the first position.
      DO J = 1, NAX
         P1( J ) = POS( I1, J )
      END DO

*  Store the second position.
      DO J = 1, NAX
         P2( J ) = POS( I2, J )
      END DO

*  If the geodesic distance is required, use AST_DISTANCE.
      IF( GEO ) THEN
         KPG1_ASDIS = AST_DISTANCE( FRAME, P1, P2, STATUS )

*  Otherwise, just return the Euclidean distance.
      ELSE

*  Find the sum of the squared axis increments between the 2 positions.
         L2 = 0.0D0
         GOOD = .FALSE.
         DO J = 1, NAX
            IF( P1( J ) .NE. AST__BAD .AND. P2( J ) .NE. AST__BAD ) THEN
               L2 = L2 + ( P2( J ) - P1( J ) )**2
               GOOD = .TRUE.
            END IF
         END DO

*  Return the square root of this distance.
         IF( GOOD ) THEN
            KPG1_ASDIS = SQRT( MAX( 0.0D0, L2 ) )
         ELSE
            KPG1_ASDIS = AST__BAD
         END IF

      END IF

      END
