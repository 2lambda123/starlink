      SUBROUTINE KPS1_NMPLT( VA, VB, NEL, AMIN, AMAX, NBIN, NITER, 
     :                       SIGLIM, MINPIX, NDFA, NDFB, NSUM, ASUM, 
     :                       BSUM, B2SUM, VARLIM, SLOPE, OFFSET, 
     :                       STATUS )
*+
*  Name:
*     KPS1_NMPLT

*  Purpose:
*     To normalize one vector to another similar vector by plotting
*     the intensities in each vector against each other.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_NMPLT( VA, VB, NEL, AMIN, AMAX, NBIN, NITER, SIGLIM,
*    :                 MINPIX, NDF1, NDF2, NSUM, ASUM, BSUM, B2SUM,
*    :                 VARLIM, SLOPE, OFFSET, STATUS )

*  Description:
*     Intensities which are valid in each input vector and lie within
*     the data range to be used in vector A are binned according to the
*     intensity in vector A. A mean and standard deviation for the B
*     intensities are found for each bin. A straight line is fitted to
*     this binned data to determine the slope and intercept, from which
*     the B vector may be normalized to the A vector. Iterations are
*     performed to reject bad data by repeating the binning and line
*     fitting procedure, rejecting pixels whose B intensities deviate
*     by more than a specified number of standard deviations from the
*     line fitted in the previous iteration.
*
*     After the final iteration, a plot is produced showing the bin 
*     centres and error bars, and the best fitting straight line.

*  Arguments:
*     VA( NEL ) = REAL (Given)
*        First input vector, to which the second input vector is 
*        normalized.
*     VB( NEL) = REAL (Given)
*        Second input vector...the one to be normalized.
*     NEL = REAL (Given)
*        No. of elements in the input vectors.
*     AMIN = REAL (Given)
*        Upper limit on data values to use in vector A.
*     AMAX = REAL (Given)
*        Lower limit on data values to use in vector A.
*     NBIN = INTEGER (Given)
*        The nunber of bins to use in the fit.
*     NITER = INTEGER (Given)
*        The number of data rejection iterations to perform.
*     SIGLIM = REAL (Given)
*        The rejection threshold in standard deviations for aberrant
*        data values.
*     MINPIX = INTEGER (Given)
*        The minimum number of data values required before a bin is
*        used.
*     NDFA = INTEGER (Given)
*        The identifier for the NDF from which the first vector was 
*        taken. 
*     NDFB = INTEGER (Given)
*        The identifier for the NDF from which the second vector was 
*        taken. 
*     NSUM( NBIN ) = INTEGER (Given and Returned)
*        Work space.
*     ASUM( NBIN ) = REAL (Given and Returned)
*        Work space.
*     BSUM( NBIN ) = REAL (Given and Returned)
*        Work space.
*     B2SUM( NBIN ) = DOUBLE (Given and Returned)
*        Work space.
*     VARLIM( NBIN ) = REAL (Given and Returned)
*        Work space.
*     SLOPE = REAL (Returned)
*        The slope of the line fitted in the expression B=SLOPE*A+OFFSET.
*     OFFSET = REAL (Returned)
*        The constant C in B=SLOPE*A+OFFSET.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     RFWS: R.F. Warren_Smith (STARLINK)
*     DSB: D.S. Berry (STARLINK)
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     5-JUN-1990 (DSB):
*        Original version (based on EDRS routine NMPLOT).
*     22-JUN-1990 (DSB):
*        Graphics added.
*     1990 Oct 4 (MJC):
*        Added extra arguments MINTIC, MAJTIC and OUTTIC to be passed
*        onto the  NCRBCK routine. Removed tabs.  Corrected the variance
*        equations.
*     17-JUN-1999 (DSB):
*        Change name from NMPLOT to KPS1_NMPLT. 
*        Remove graphics arguments from arguments list.
*        Re-format comments, declarations, etc.
*        Use AST/PGPLOT for graphics.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! VAL__ constants
      INCLUDE 'AST_PAR'          ! AST constants and functions

*  Arguments Given:
      INTEGER NEL          
      REAL VA( NEL )    
      REAL VB( NEL )    
      REAL AMIN         
      REAL AMAX         
      INTEGER NBIN         
      INTEGER NITER        
      REAL SIGLIM       
      REAL MAJTIC( 2 )  
      INTEGER MINPIX       
      REAL MINTIC( 2 )  
      INTEGER NDFA         
      INTEGER NDFB         

*  Arguments Given and Returned:
      INTEGER NSUM( NBIN )  
      REAL ASUM( NBIN )  
      REAL BSUM( NBIN )  
      DOUBLE PRECISION B2SUM( NBIN ) 
      REAL VARLIM( NBIN )

*  Arguments Returned:
      REAL SLOPE 
      REAL OFFSET

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER NDFNAM*255    ! Base name of NDF (possibly with HDS comp. path)
      CHARACTER XL*255       ! Default X axis label
      CHARACTER YL*255       ! Default Y axis label
      DOUBLE PRECISION ABOT  ! Lowest vector A value actually used
      DOUBLE PRECISION ATOP  ! Highest vector A value actually used
      DOUBLE PRECISION FINISH( 2 ) ! End of best fitting line
      DOUBLE PRECISION START( 2 ) ! Start of best fitting line
      DOUBLE PRECISION WT    ! Weight for current bin
      DOUBLE PRECISION WTSUM ! Sum of bin weights
      DOUBLE PRECISION X     ! Mean vector A value over a bin
      DOUBLE PRECISION X2SUM ! Sum of X*X values
      DOUBLE PRECISION XSUM  ! Sum of X values
      DOUBLE PRECISION XYSUM ! Sum of X*Y values
      DOUBLE PRECISION Y     ! Mean vector B value in a bin
      DOUBLE PRECISION YSUM  ! Sum of Y values
      INTEGER I              ! Loop index
      INTEGER IBIN           ! Current bin
      INTEGER IPLOT          ! AST Plot pointer
      INTEGER ITER           ! Iteration counter
      INTEGER LENXL          ! Used length of XL
      INTEGER LENYL          ! Used length of YL
      INTEGER NDATA          ! No. of non-empty bins
      INTEGER NMLEN          ! Used length of NDFNAM
      INTEGER NPIX           ! No. of vector B values used
      REAL A                 ! Vector A value
      REAL A0                ! Bin no. for zero A value
      REAL A1                ! No. of bins in unit A value
      REAL AAMAX             ! Max. allowed value from vector A
      REAL AAMIN             ! Min. allowed value from vector A
      REAL B                 ! Vector B value
      REAL BFIT              ! Expected vector B value
      REAL DET               ! Denominator of normal equations
      REAL Q0                ! Min. possible variance for a bin
      REAL WTMAX             ! Max. allowed bin weight
      REAL XMAX              ! Upper X axis limit for plot
      REAL XMIN              ! Lower X axis limit for plot
      REAL YMAX              ! Upper Y axis limit for plot
      REAL YMIN              ! Lower Y axis limit for plot
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Set minimum expected variance for a bin.
      Q0 = 0.0
      SLOPE = 1.0
      OFFSET = 0.0
 
*  Set constants to convert intensity into bins.
      AAMIN = MIN( AMIN, AMAX )
      AAMAX = MAX( AMIN, AMAX )
      A0 = 1.5 - AAMIN * ( REAL( NBIN - 1 ) ) 
     :       / MAX( 1.0E-20, AAMAX - AAMIN  )
      A1 = REAL( NBIN - 1 ) / MAX( 1.0E-20, AAMAX - AAMIN )

*  Initialise the variance threshold for each bin.
      DO I = 1, NBIN
         VARLIM( I ) = VAL__MAXR
      END DO
 
*  Perform NITER iterations.
      DO ITER = 0, NITER

*  Initialise the bins
         DO I = 1, NBIN
            NSUM( I ) = 0
            ASUM( I ) = 0.0
            BSUM( I ) = 0.0
            B2SUM( I ) = 0.0D0
         END DO

*  Scan through the input vectors.
         DO I = 1, NEL
 
*  Use pixels which are good in both vectors.
            IF ( VA( I ) .NE. VAL__BADR .AND.
     :          VB( I ) .NE. VAL__BADR ) THEN
 
*  Check if the A intensity is in the required data range.
               A = VA( I )
               IF ( A .GE. AAMIN .AND. A .LE. AAMAX ) THEN
 
*  Calculate the bin number and form sums for this bin
                  IBIN = INT( A0 + A1 * A )
                  B = VB( I )
                  BFIT = A * SLOPE + OFFSET
 
                  IF ( ( B - BFIT )**2 .LE. VARLIM( IBIN ) ) THEN
                     NSUM( IBIN ) = NSUM( IBIN ) + 1
                     BSUM( IBIN ) = BSUM( IBIN ) + B
                     B2SUM( IBIN ) = B2SUM( IBIN ) + DBLE( B * B )
                     ASUM( IBIN ) = ASUM( IBIN ) + A
                  END IF
 
               END IF
 
            END IF
 
         END DO
 
*  Count the total number of pixels used.
         NPIX = 0
 
         DO I = 1, NBIN
            NPIX = NPIX + NSUM( I )
         END DO
 
*  Calculate the max. weight to be applied to any bin (this is the
*  number of points per bin if the points are uniformly distributed).
         WTMAX = REAL( NPIX ) / REAL( NBIN )
 
*  Initialise sums for the straight line fit.
         XSUM = 0.0D0
         X2SUM = 0.0D0
         YSUM = 0.0D0
         XYSUM = 0.0D0
         WTSUM = 0.0D0
         ABOT = VAL__MAXD
         ATOP = VAL__MIND
 
*  Scan those bins with at least the minimum number of pixels in.
         DO I = 1, NBIN
 
            IF ( NSUM( I ) .GE. MAX( 1, MINPIX ) ) THEN
 
*  Form the weight for this bin.
               WT = DBLE( MIN( WTMAX, REAL( NSUM( I ) ) ) )
 
*  Set the variance threshold in this bin for the next iteration.
               VARLIM( I ) = REAL( DBLE( SIGLIM**2 ) * 
     :                       ( B2SUM( I ) - DBLE( BSUM( I )**2 ) / 
     :                                      DBLE( NSUM( I ) )  ) )
     :                       / MAX( 1.0, REAL( NSUM( I ) - 1 ) )

               VARLIM( I ) = MAX( VARLIM( I ), Q0 * ( SIGLIM**2 ) )
 
*  Form the mean data values in each bin.
               X = DBLE( ASUM( I ) ) / DBLE( NSUM( I ) )
               Y = DBLE( BSUM( I ) ) / DBLE( NSUM( I ) )
 
*  Form weighted sums for fit.
               XSUM = XSUM + X * WT
               X2SUM = X2SUM + X * X * WT
               YSUM = YSUM + Y * WT
               XYSUM = XYSUM + Y * X * WT
               WTSUM = WTSUM + WT

*  Note the range of values used.
               ATOP = MAX( ATOP, X )
               ABOT = MIN( ABOT, X )
 
            ELSE
 
*  Set minimum variance for bins with too few points.
               VARLIM( I ) = ( SIGLIM**2 ) * Q0

            END IF
 
         END DO
 
*  If all bins are empty, abort with STATUS = SAI__ERROR
         IF ( ATOP .EQ. VAL__MIND ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP('NORMALIZE_EMPTY',
     :        'NORMALIZE: All the bins in the fit are empty.', STATUS )
            GO TO 10
         END IF

*  If normal equations are singular, abort with STATUS = SAI__ERROR
         DET = REAL( WTSUM * X2SUM - XSUM * XSUM )
 
         IF ( ABS( DET ) .LE. VAL__SMLR ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP('NORMALIZE_SINGULAR',
     :        'NORMALIZE: Unable to calculate normalization constants.',
     :         STATUS )
            GO TO 10
         END IF

*  Form the straight line parameters (B=SLOPE*A+OFFSET).
         SLOPE = REAL( WTSUM * XYSUM - XSUM * YSUM )
         OFFSET = REAL( X2SUM * YSUM - XSUM * XYSUM )
         SLOPE = SLOPE / DET
         OFFSET = OFFSET / DET
 
*  Print the results of this iteration.
         CALL MSG_OUT( 'REPORT', ' ', STATUS )

         CALL NDF_MSG( 'VA', NDFA )
         CALL MSG_SETI( 'ITER', ITER )      
         CALL MSG_SETI( 'NPIX', NPIX )      
         CALL MSG_SETR( 'ABOT', REAL( ABOT ) )
         CALL MSG_SETR( 'ATOP', REAL( ATOP ) )
         CALL MSG_OUT( 'REPORT',
     :    ' Iteration ^ITER used ^NPIX pixels '//
     :    'in the range ^ABOT and ^ATOP in ^VA', STATUS )

         CALL MSG_OUT( 'REPORT', ' ', STATUS )

         CALL MSG_SETR( 'SLOPE', SLOPE )
         CALL MSG_SETR( 'OFFSET', OFFSET )
         CALL NDF_MSG( 'VA', NDFA )
         CALL NDF_MSG( 'VB', NDFB )

         CALL MSG_OUT( 'REPORT',
     :    '   Fit gives:   ^VB = (^SLOPE) * ^VA + (^OFFSET)', STATUS )

         CALL MSG_OUT( 'REPORT', ' ', STATUS )

*  On the final iteration, plot the fit if required.
         IF( ITER .EQ. NITER .AND. STATUS .EQ. SAI__OK ) THEN
 
*  Remove bins with no data in and form the values to plot. 
            NDATA = 0
            DO I = 1, NBIN
 
               IF( NSUM( I ) .GE. MINPIX ) THEN
                  NDATA = NDATA + 1

                  ASUM( NDATA ) = ASUM( I ) / DBLE( NSUM( I ) )
                  BSUM( NDATA ) = BSUM( I ) / DBLE( NSUM( I ) )

                  VARLIM( NDATA ) = SQRT( MAX( 0.0D0,
     :                 ( B2SUM( I ) - ( BSUM( I )**2 ) * 
     :                   DBLE( NSUM( I ) ) ) /
     :                   MAX( 1.0D0, DBLE( NSUM( I ) - 1 ) ) ) )

                END IF
 
            END DO

*  Construct the default label for the X axis.
            CALL KPG1_NDFNM( NDFA, NDFNAM, NMLEN, STATUS )
            CALL MSG_SETC( 'NDF', NDFNAM )
            CALL MSG_LOAD( ' ', 'Data value in ^NDF', XL, LENXL, 
     :                     STATUS )

*  Construct the default label for the Y axis.
            CALL KPG1_NDFNM( NDFB, NDFNAM, NMLEN, STATUS )
            CALL MSG_SETC( 'NDF', NDFNAM )
            CALL MSG_LOAD( ' ', 'Data value in ^NDF', YL, LENYL, 
     :                     STATUS )

*  Draw the plot.
            CALL KPG1_GRAPH( NDATA, ASUM, BSUM, 1.0, VARLIM, 
     :                       XL( : LENXL ), YL( : LENYL ), 
     :                       'Normalization plot', 'XDATA', 'YDATA', 3, 
     :                       .TRUE., VAL__BADR, VAL__BADR, VAL__BADR,
     :                       VAL__BADR, 'KAPPA_NORMALIZE', .TRUE., 
     :                       .FALSE., IPLOT, STATUS )

*  If a Plot was produced, we need to draw the best fitting straight line
*  over it.
            IF( IPLOT .NE. AST__NULL ) THEN

*  Get the data co-ordinates at the start and end of the line.
               START( 1 ) = DBLE( ASUM( 1 )  )
               START( 2 ) = DBLE( SLOPE * ASUM( 1 ) + OFFSET )
               FINISH( 1 ) = DBLE( ASUM( NDATA ) )
               FINISH( 2 ) = DBLE( SLOPE * ASUM( NDATA ) + OFFSET )

*  Set up the plotting characteristics to use when drawing the line.
               CALL KPG1_ASPSY( '(LIN*ES)', '(CURVES)', STATUS )
               CALL KPG1_ASSET( 'KAPPA_NORMALIZE', 'STYLE', IPLOT, 
     :                          STATUS )

*  Draw the line.
               CALL AST_CURVE( IPLOT, START, FINISH, STATUS ) 

*  Annul the Plot, and shut down the graphics workstation and database.
               CALL AST_ANNUL( IPLOT, STATUS )
               CALL KPG1_PGCLS( 'DEVICE', .FALSE., STATUS )

            END IF

         END IF

*  Return for next iteration.

      END DO
 
   10 CONTINUE

      END
