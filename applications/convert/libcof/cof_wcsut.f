      SUBROUTINE COF_WCSUT( INDF, STATUS )
*+
*  Name:
*     COF_WCSUT

*  Purpose:
*     Remove the spurious copy of the AXIS Frame which is left in
*     WCS component when using non-Native encodings.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL COF_WCSUT( INDF, STATUS )

*  Description:
*     This routine removes the Current Frame in the WCS component of an
*     NDF if no value has been set for its Domain attribute, and if it
*     corresponds closely to the AXIS Frame (i.e. if the Mapping from the
*     Current Frame to the AXIS Frame is nearly a UnitMap).
*
*     When using non-Native encoding, the AXIS Frame written by NDF2FITS 
*     will not have any associated Domain value, and so will not be
*     recognised by the NDF library as an AXIS Frame when it is read back
*     in by FITS2NDF. The Frame will therefore be left in the WCS
*     component of the NDF, even though it is in reality a copy of the AXIS
*     Frame. This routine removes such Frames.

*  Arguments:
*     INDF = INTEGER (Given)
*        The NDF identifier.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     17-DEC-1997 (DSB):
*        Original version.
*     20-SEP-2000 (DSB):
*        Check that the number of axes in the current Frame is equal to
*        the number of pixel axes in the NDF.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_PAR'          ! NDF_ public constants
      INCLUDE 'AST_PAR'          ! AST_ public constants

*  Arguments Given:
      INTEGER INDF

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      DOUBLE PRECISION EPS       ! Max. relative error for equivalence
      PARAMETER ( EPS = 1.0D-6 )


*  Local Variables:
      DOUBLE PRECISION A1        ! First AXIS coordinate
      DOUBLE PRECISION A2        ! Last AXIS coordinate
      DOUBLE PRECISION B1        ! First original Current Frame coordinate
      DOUBLE PRECISION B2        ! Last original Current Frame coordinate
      DOUBLE PRECISION IN( 2, NDF__MXDIM )  ! First and last GRID coordinates
      DOUBLE PRECISION OUTA( 2, NDF__MXDIM )! First and last AXIS coordinates
      DOUBLE PRECISION OUTB( 2, NDF__MXDIM )! First and last Current coordinates
      INTEGER DIM( NDF__MXDIM )  ! NDF dimensions
      INTEGER I                  ! Loop count
      INTEGER ICURR              ! Index of Current Frame 
      INTEGER IWCS               ! AST identifier for NDF's WCS information
      INTEGER NAXC               ! No. of axes in WCS current Frame
      INTEGER NDIM               ! Dimensionality of the NDF
      LOGICAL ISAXIS             ! Is Current Frame equivalent to AXIS Frame?
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Get the WCS component. The NDF library will ensure that the returned 
*  FrameSet has a single AXIS Frame which is consistent with the NDF's 
*  AXIS structures.
      CALL NDF_GTWCS( INDF, IWCS, STATUS )

*  Check that no value has been set for the Current Frame's Domain
*  attribute.
      IF( .NOT. AST_TEST( IWCS, 'DOMAIN', STATUS ) ) THEN

*  Get the number of axes in the current Frame.
         NAXC = AST_GETI( IWCS, 'NAXES', STATUS )

*  Get the dimensions of the NDF. 
         CALL NDF_DIM( INDF, NDF__MXDIM, DIM, NDIM, STATUS ) 

*  The current Frame can only be a copy of the AXES Frame if the number of
*  axes in the current Frame equals the number of pixel axes in the NDF.
         IF( NDIM .EQ. NAXC ) THEN

*  Note the index of the Current Frame so that it can be re-instated later.
            ICURR = AST_GETI( IWCS, 'Current', STATUS )

*  Look for the AXIS Frame in the FrameSet. If found, it becomes the
*  Current Frame.
            IF( AST_FINDFRAME( IWCS, AST_FRAME( NDIM, ' ', STATUS ), 
     :                        'AXIS', STATUS ) .NE. AST__NULL ) THEN

*  We now need to check to see if the original Current Frame and the AXIS
*  Frame (the new Current Frame) are equivalent. This is assumed to be
*  the case if the mapping between them is a unit mapping. Because of 
*  rounding errors, etc, we cannot just get the Mapping, simplify it and
*  see if it is a UnitMap. Instead, we transform points in GRID
*  coordinates into each of the two Frames, and see if the resulting values 
*  are nearly equal. The two points used are the first and last pixel.

*  Store the GRID coordinates of the first and last pixels.
               DO I = 1, NDIM
                  IN( 1, I ) = 1.0
                  IN( 2, I ) = DIM( I )
               END DO               

*  Transform the GRID coordinates into AXIS coordinates.
               CALL AST_TRANN( IWCS, 2, NDIM, 2, IN, .TRUE., NDIM, 2,
     :                         OUTA, STATUS )

*  Re-instate the original Current Frame
               CALL AST_SETI( IWCS, 'CURRENT', ICURR, STATUS )

*  Transform the GRID coordinates into coordinates in the original
*  Current Frame.
               CALL AST_TRANN( IWCS, 2, NDIM, 2, IN, .TRUE., NDIM, 2,
     :                         OUTB, STATUS )

*  See if the results are nearly equal on all axes.
               ISAXIS = .TRUE.
               DO I = 1, NDIM
   
                  A1 = OUTA( 1, I )
                  A2 = OUTA( 2, I )
                  B1 = OUTB( 1, I )
                  B2 = OUTB( 2, I )
 
                  IF( A1 .EQ. AST__BAD .OR.
     :                A2 .EQ. AST__BAD .OR.
     :                B1 .EQ. AST__BAD .OR.
     :                B2 .EQ. AST__BAD ) THEN
                     ISAXIS = .FALSE.

                  ELSE IF( ABS( ( A1 - B1 ) ) .GT. 
     :                     EPS*MAX( ABS( A1 ), ABS( B1 ) ) ) THEN
                     ISAXIS = .FALSE.

                  ELSE IF( ABS( ( A2 - B2 ) ) .GT. 
     :                     EPS*MAX( ABS( A2 ), ABS( B2 ) ) ) THEN
                     ISAXIS = .FALSE.
                
                  END IF

               END DO

*  Remove the Current Frame if it is a spurious copy of the AXIS Frame,
*  and store the modified FrameSet back in the NDF.
               IF( ISAXIS ) THEN
                  CALL AST_REMOVEFRAME( IWCS, ICURR, STATUS )
                  CALL NDF_PTWCS( IWCS, INDF, STATUS )
               END IF

            END IF

         END IF

      END IF

      END
