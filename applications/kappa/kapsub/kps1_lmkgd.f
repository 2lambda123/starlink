      SUBROUTINE KPS1_LMKGD( IN, NDIM, DIM, NP, PIXCEN, STATUS )
*+
*  Name:
*     KPS1_LMKGD

*  Purpose:
*     Store good pixel GRID Frame centres in an array for LISTMAKE.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_LMKGD( IN, NDIM, DIM, NP, PIXCEN, STATUS )

*  Description:
*     This routine stores the GRID Frame co-ordinates of every good pixel
*     in the supplied array.

*  Arguments:
*     IN( * ) = REAL (Given)
*        The vectorised array containing the pixel values.
*     NDIM = INTEGER (Given)
*        The number of axes.
*     DIM( NDIM ) = INTEGER (Given)
*        The dimension of each axis.
*     NP = INTEGER (Given)
*        The maximum number of pixels to return in PIXCEN.
*     PIXCEN( NP, NDIM ) = DOUBLE PRECISION (Returned)
*        The returned pixel centre positions.
*     STATUS = INTEGER (Given)
*        Global status value.

*  Authors:
*     DSB: David S. Berry (JACH)
*     {enter_new_authors_here}

*  History:
*     19-JAN-2006 (DSB):
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
      INCLUDE 'PRM_PAR'          ! VAL__ constants

*  Arguments Given:
      REAL IN( * )
      INTEGER NDIM
      INTEGER DIM( NDIM )
      INTEGER NP

*  Arguments Returned:
      DOUBLE PRECISION PIXCEN( NP, NDIM )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER EL                 ! Total number of pixels
      INTEGER I                  ! Position count
      INTEGER J( NDF__MXDIM )    ! pixel indices
      INTEGER K                  ! Axis count
      INTEGER NCEN               ! Number of pixels stored so far
*.

*  Check the global inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN

      write(*,*) 'LMKGD: NDIM=',NDIM
      write(*,*) 'DIM: ',DIM(1),',',DIM(2)


*  Initialise the indices of the current pixel, and find the total number
*  of pixels.
      EL = 1
      DO K = 1, NDIM
         J( K ) = 1
         EL = EL * DIM( K )
      END DO

*  Initialise the number of pixel centres stored in PIXCEN.
      NCEN = 0
  
*  Check each pixel.
      DO I = 1, EL

*  Skip it if it is bad 
         IF( IN( I ) .NE. VAL__BADR ) THEN

*  Store the required GRID co-ordinates.
            NCEN = NCEN + 1
            DO K = 1, NDIM
               PIXCEN( NCEN, K ) = DBLE( J( K ) ) 
            END DO

*  Abort if the PIXCEN array is now full.
            IF( NCEN .EQ. NP ) GO TO 999

         END IF

*  Increment the pixel indices.   
         J( 1 ) = J( 1 ) + 1

         K = 1
         DO WHILE( K .LE. NDIM .AND. J( K ) .GT. DIM( K ) ) 
            J( K ) = 1
            K = K + 1
            J( K ) = J( K ) + 1
         END DO

      END DO

 999  CONTINUE

      END
