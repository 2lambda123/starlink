      SUBROUTINE CON_CAXES( IMAP, INDF, WORK, STATUS )
*+
*  Name:
*     CON_CAXES

*  Purpose:
*     Construct the NDF axis components for a SPECX data cube.

*  Language:
*     Fortran 77.

*  Invocation:
*     CALL CON_CAXES( IMAP, INDF, WORK, STATUS )

*  Description:
*     Construct the NDF axis components for a SPECX data cube.
*
*     This routine also sets the pixel origin of the output NDF to be
*     coincident with the SPECX reference point.

*  Arguments:
*     IMAP  =  INTEGER (Given)
*        Identifier for the input SPECX map grid.
*     INDF  =  INTEGER (Given)
*        Identifier for the output NDF cube.
*     WORK( * ) =  DOUBLE PRECISION (Returned)
*        A work array. The number of elements in it should be at least 6
*        times the largest pixel dimension of the output NDF.
*     STATUS  =  INTEGER( Given and Returned )
*        The global status.

*  Authors:
*     ACD: A C Davenhall (Edinburgh)
*     DSB: David S. Berry (STARLINK)

*  History:
*     25/6/97( ACD ): 
*        Original version.
*     14/8/97( ACD ): 
*        First stable version.
*     17-FEB-2003 (DSB):
*        Re-written to derived the AXIS values from the WCS component of
*        the NDF cube.

*-

*  Type Definitions:
      IMPLICIT NONE

*  Global Constants:
      INCLUDE 'SAE_PAR'           ! Standard Starlink constants
      INCLUDE 'AST_PAR'           ! AST constants and functions

*  Arguments Given:
      INTEGER IMAP
      INTEGER INDF
      DOUBLE PRECISION WORK( * )

*  Status:
      INTEGER STATUS              ! Global status

*  External References:
      DOUBLE PRECISION SLA_DRANGE

*  Local Constants:
      DOUBLE PRECISION D2R         ! Degrees to radians conversion factor
      PARAMETER ( D2R = 0.01745329252 )

*  Local Variables:
      CHARACTER AX*10     ! Buffer for axis specifier
      CHARACTER LA(3)*8   ! Label attribute names
      CHARACTER TEXT*80   ! Buffer for label text
      DOUBLE PRECISION BPOS( 3 ) ! A Base Frame positions
      DOUBLE PRECISION CPOS( 3 ) ! A Current Frame position
      DOUBLE PRECISION DPOS( 3 ) ! A Current Frame position
      DOUBLE PRECISION DDEC  ! Dec offset (arc-seconds)
      DOUBLE PRECISION DRA   ! RA offset (seconds)
      INTEGER DIM( 3 )    ! Dimensions of pixel axes in output NDF
      INTEGER I           ! Loop index
      INTEGER IAT         ! Used length of string
      INTEGER IERR        ! Index of first conversion error
      INTEGER IPAXIS      ! Axis pointer
      INTEGER IWCS        ! WCS FrameSet in output NDF
      INTEGER J           ! Point index
      INTEGER K           ! Axis index
      INTEGER L           ! Index of next element of WORK array
      INTEGER LBND( 3 )   ! Lower pixel bounds in output NDF
      INTEGER NDIM        ! No. of dimensions in output NDF
      INTEGER NEL         ! Number of elements in this axis
      INTEGER NERR        ! Number of conversion errors
      INTEGER SHIFT( 3 )  ! Shifts in pixel bounds in output NDF
      INTEGER UBND( 3 )   ! Upper pixel bounds in output NDF
      LOGICAL INCSYM      ! Include Symbol attribute in label?
      LOGICAL THERE       ! Does the object exist?
      REAL POSANG         ! Position angle of Y axis in input map

      DATA LA / 'LABEL(1)', 'LABEL(2)', 'LABEL(3)' /
*.

*  Check the inherited status.
      IF( STATUS .NE. SAI__OK ) RETURN

*  Ensure we start with a clean plate by deleting any existing AXIS 
*  structures in the output NDF.
      CALL NDF_RESET( INDF, 'AXIS', STATUS )

*  Get the position angle of the Y axis (assumed to be in degrees).
*  This is used to determined the axis labels.
      CALL NDF_XSTAT( IMAP, 'SPECX_MAP', THERE, STATUS ) 
      IF( THERE ) THEN
         CALL NDF_XGT0R( IMAP, 'SPECX_MAP', 'POSANGLE', POSANG, STATUS )
      ELSE
         POSANG = 0.0
      END IF

*  Get the NDF WCS FrameSet.
      CALL NDF_GTWCS( INDF, IWCS, STATUS )

*  Get the RA and DEC of the source from the SPECX map, and convert to 
*  radians.
      CALL NDF_XGT0D( IMAP, 'SPECX', 'RA_DEC(1)', CPOS( 1 ), STATUS )
      CALL NDF_XGT0D( IMAP, 'SPECX', 'RA_DEC(2)', CPOS( 2 ), STATUS )

      CALL NDF_XGT0D( IMAP, 'SPECX', 'DPOS(1)', DRA, STATUS )
      CALL NDF_XGT0D( IMAP, 'SPECX', 'DPOS(2)', DDEC, STATUS )

      CPOS( 2 ) = ( CPOS( 2 ) + DDEC/3600.0 )*D2R
      CPOS( 1 ) = ( CPOS( 1 ) + DRA/( 3600.0*COS( CPOS( 2 ) ) ) )*D2R

*  Get the central frequency from the SPECX map, in kHz, convert to GHz.
      CALL NDF_XGT0D( IMAP, 'SPECX', 'JFCEN(1)', CPOS( 3 ), STATUS )
      CPOS( 3 ) = CPOS( 3 )*1.0D-6

*  Convert this position from the Current Frame (RA,Dec,Freq) of the NDF to 
*  the Base Frame (GRID coords).
      CALL AST_TRANN( IWCS, 1, 3, 1, CPOS, .FALSE., 3, 1, BPOS, STATUS ) 

*  Get the pixel bounds and dimensions of the NDF.
      CALL NDF_BOUND( INDF, 3, LBND, UBND, NDIM, STATUS )
      DIM( 1 ) = UBND( 1 ) - LBND( 1 ) + 1
      DIM( 2 ) = UBND( 2 ) - LBND( 2 ) + 1
      DIM( 3 ) = UBND( 3 ) - LBND( 3 ) + 1

*  Shift the pixel bounds so that the source position is at pixel index zero.
      SHIFT( 1 ) = 1 - LBND( 1 ) - NINT( BPOS( 1 ) ) 
      SHIFT( 2 ) = 1 - LBND( 2 ) - NINT( BPOS( 2 ) ) 
      SHIFT( 3 ) = 1 - LBND( 3 ) - NINT( BPOS( 3 ) ) 
      CALL NDF_SHIFT( 3, SHIFT, INDF, STATUS )      

*  Now produce each axis in turn.
      DO I = 1, 3

*  Fill the work array with the grid coords at the centre of each pixel
*  along the I'th axis. On axis I, these go from 1.0 at the first pixel
*  to DIM(I) at the last pixel. On the other axes, the value is fixed at
*  the central grid value found above. The work array contains a set of 
*  axis-1 values, followed by a set of axis-2 values, followed by a set 
*  of axis 3 values. The number of values in each set is equal to the size 
*  of the I'th pixel axis.
         L = 1
         DO K = 1, 3
            DO J = 1, DIM( I )
               IF( K .NE. I ) THEN 
                  WORK( L ) = BPOS( K )
               ELSE
                  WORK( L ) = DBLE( J )
               END IF 
               L = L + 1
            END DO
         END DO

*  Transform the grid coords into the current Frame. The transformed
*  values are stored at the end of the WORK array.
         CALL AST_TRANN( IWCS, DIM( I ), 3, DIM( I ), WORK, .TRUE., 3, 
     :                   DIM( I ), WORK( L ), STATUS ) 

*  Map the axis centre array. 
         CALL NDF_AMAP( INDF, 'CENTRE', I, '_DOUBLE', 'WRITE', IPAXIS, 
     :                  NEL, STATUS )

*  For axis 3 (the Frequency axis), we subtract the central frequency, and 
*  copy them into the AXIS centre array.
         IF( I .EQ. 3 ) THEN
            L = L + 2*DIM( 3 )
            DO J = L, L + DIM( 3 ) - 1
               WORK( J ) = WORK( J ) - CPOS( 3 )
            END DO
            CALL VEC_DTOD( .FALSE., NEL, WORK( L ), %VAL( IPAXIS ), 
     :                     IERR, NERR, STATUS )

*  For RA and DEC axes, find the arc-distance from the source position at
*  each pixel centre along the axis. Convert from radians to arc-seconds.
*  Distances returned by AST_DISTANCE are always positive. So set the sign 
*  of the distance depending on which side of the central position it is.
         ELSE
            DO J = 1, DIM( I )
               DO K = 0, 2
                  DPOS( K + 1 ) = WORK( L + K*DIM( I ) )
               END DO
               L  = L + 1

               WORK( J ) = AST_DISTANCE( IWCS, CPOS, DPOS, STATUS )

               IF( WORK( J ) .NE. AST__BAD ) THEN
                  WORK( J ) = WORK( J )*3600.0/D2R
                  IF( SLA_DRANGE( DPOS( I ) - CPOS( I ) ) .LT. 0.0 ) 
     :                                        WORK( J ) = -WORK( J )
               END IF

            END DO

*  Copy these to the AXIS centre array.
            CALL VEC_DTOD( .FALSE., NEL, WORK, %VAL( IPAXIS ), IERR, 
     :                     NERR, STATUS )
         END IF

*  Unmap the AXIS centre array.
         CALL NDF_AUNMP( INDF, 'CENTRE', I, STATUS )

*  Now add units and initialise the starting text for the labels.
         INCSYM = .FALSE.
         IF( I .EQ. 3 ) THEN
            CALL NDF_ACPUT( 'GHz', INDF, 'UNITS', I, STATUS )
            TEXT = 'Frequency '
            IAT = 10
         ELSE 
            CALL NDF_ACPUT( 'arcsec', INDF, 'UNITS', I, STATUS )
            IF( POSANG .NE. 0.0 ) THEN
               INCSYM = .TRUE.
               IF( I .EQ. 2 ) THEN
                  TEXT = 'X '
                  IAT = 2
               ELSE
                  TEXT = 'Y '
                  IAT = 2
               END IF
            ELSE
               IF( I .EQ. 1 ) THEN
                  TEXT = 'RA '
                  IAT = 3
               ELSE
                  TEXT = 'Dec '
                  IAT = 4
               END IF
            END IF
         END IF

*  Complete the label text by adding the absolute central axis value.
*  Include the axis symbol if required.
         CALL CHR_APPND( 'offset from', TEXT, IAT )
         IAT = IAT + 1

         IF( INCSYM ) THEN
            CALL CHR_APPND( AST_GETC( IWCS, LA( I ), STATUS ),
     :                      TEXT, IAT )
            IAT = IAT + 1
         END IF

         CALL CHR_APPND( AST_FORMAT( IWCS, I, CPOS( I ), STATUS ), TEXT,
     :                   IAT )

*  Store the axis label in the NDF. 
         CALL NDF_ACPUT( TEXT( : IAT ), INDF, 'LABEL', I, STATUS )

      END DO

      END
