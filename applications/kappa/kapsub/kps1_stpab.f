      SUBROUTINE KPS1_STPAB( DIM1, DIM2, ARRAY, LBND, NXY, ISIZE, POS,
     :                         SIG0, AXISR, THETA, NGOOD, SIG, STATUS )
*+
*  Name:
*     KPS1_STPAB
 
*  Purpose:
*     Finds the mean axis ratio, seeing disk size and orientation
*     of a set of elliptical star images.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPS1_STPAB( DIM1, DIM2, ARRAY, LBND, NXY, ISIZE, POS,
*    :                 SIG0, AXISR, THETA, NGOOD, SIG, STATUS )
 
*  Description:
*     This routine finds the mean axis ratio, seeing disk size and
*     orientation of a set of elliptical star images by fitting to 2-d
*     Gaussians.  This is achieved via an iterative method that uses
*     four marginal profiles, at 0, 45, 90 and 135 degrees to the x
*     axis.  The profiles are cleaned via an iterative modal filter
*     that removes contamination for neighbouring stars, dirt, etc.
*     Gaussians are fitted to each of these to determine a centre,
*     width and amplitude.  A mean centre for the four profiles is
*     derived for each star.  Iterations cease after the difference in
*     centroid position does not vary by more than a given tolerance,
*     or a maximum number of iterations have occurred.  Once the
*     centroids of all the stars have been determined the width
*     estimates at each of the four directions for all the stars are
*     combined modally to give four mean widths.  Using these the
*     routine finds the parameters of a mean elliptical star image.
 
*  Arguments:
*     DIM1 = INTEGER (Given)
*        The number of pixels per line of the array.
*     DIM2 = INTEGER (Given)
*        The number of lines in the array.
*     ARRAY( DIM1, DIM2 ) = ? (Given)
*        The input array containing the stars to be fitted.
*     LBND( 2 ) = ? (Given)
*        The lower bounds of the input array.
*     NXY = INTEGER (Given)
*        The number of stars to be fitted.
*     ISIZE = INTEGER (Given)
*        The length of the search square side used in finding stars
*        and calculating their ellipticity.
*     POS( NXY, 2 ) = DOUBLE PRECISION (Given & Returned)
*        Each line comprises the x then y positions of a star centre.
*        On entry these are approximate centroids.  On exit they are
*        accurate, fitted centroids.
*     SIG0 = REAL (Returned)
*        The mean star 'sigma'.
*     AXISR = REAL (Returned)
*        The axis ratio of the star images.
*     THETA = REAL (Returned)
*        The orientation of the major axis of the star images to the
*        x axis in radians (x through y positive).
*     NGOOD = INTEGER (Returned)
*        The number of stars successfully found and used in the fit.
*     SIG( NXY, 5 ) = REAL (Returned)
*        Intermediate storage for the widths of the star marginal
*        profiles. The first four lines are the Gaussian widths of stars
*        in directions oriented at 0, 45, 90 and 135 degrees to the x
*        axis (x through y positive).  The fifth line returns the sum
*        of the amplitudes of the 4 profiles of each star (i.e. it is
*        proportional to the amplitude of each star.  If a star was not
*        found, all its entries in %SIG are zero.
*     STATUS = INTEGER (Given and Returned)
*        The global status.
 
*  Notes:
*     -  There is a routine for each numeric data type: replace "x" in
*     the routine name by D, R, I, W, UW, B, UB as appropriate.  The
*     array supplied to the routine must have the data type specified.
*     -  This is a server routine for PSF.
 
*  Authors:
*     RFWS: R.F. Warren-Smith (Durham Univ.)
*     MJC: Malcolm J. Currie (STARLINK)
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1981 (RFWS):
*        Original version.
*     1990 September 21 (MJC):
*        Made generic, renamed from STARIM, removed INVAL, combined the
*        x-y co-ordinates into one argument and re-ordered it, commented
*        the variables, and converted the prologue.
*     1991 July 14 (MJC):
*        Permitted PSF to be determined for a single object.
*     1992 April 2 (MJC):
*        Reordered the ARRAY argument to its normal location after the
*        dimensions.  Added LBND argument and corrected the x-y
*        positions as if the lower bounds were both one.
*     20-SEP-1999 (DSB):
*        Reversed order of POS indices and made it _DOUBLE for use with AST.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! Magic-value definitions
 
*  Arguments Given:
      INTEGER
     :  DIM1, DIM2,
     :  LBND( 2 ),
     :  ISIZE,
     :  NXY
 
      BYTE
     :  ARRAY( DIM1, DIM2 )
 
      DOUBLE PRECISION
     :  POS( NXY, 2 )
 
*  Arguments Returned:
      REAL
     :  AXISR,
     :  SIG( NXY, 5 ),
     :  SIG0,
     :  THETA
 
      INTEGER
     :  NGOOD
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Constants:
      INTEGER ITMODE             ! Number of iterations to compute the
                                 ! mode
      PARAMETER ( ITMODE = 10 )
      INTEGER MAXX               ! Maximum radius in pixels for forming
                                 ! the marginal profiles
      PARAMETER ( MAXX = 50 )
      REAL RMAXX                 ! REAL version of MAXX
      PARAMETER ( RMAXX = 50.0 )
      INTEGER MAXP               ! As MAXX but allow for 45-degree
                                 ! directions as well.
      PARAMETER ( MAXP = 1.41421 * RMAXX + 1.0 )
      INTEGER MAXSIZ             ! Maximum boxsize in pixels
      PARAMETER ( MAXSIZ = 2 * MAXX + 1 )
      INTEGER NGAUIT             ! Number of Gaussian iterations
      PARAMETER ( NGAUIT = 15 )
      INTEGER NITER              ! Number of iterations
      PARAMETER ( NITER = 3 )
      REAL TOLL                  ! Tolerance of the fitting
      PARAMETER ( TOLL = 0.001 )
 
*  Local Variables:
 
      REAL
     :  AP,                      ! Gaussian amplitude in p
     :  AQ,                      ! Gaussian amplitude in q
     :  AX,                      ! Gaussian amplitude in x
     :  AY,                      ! Gaussian amplitude in y
     :  BACK,                    ! Gaussian background level
     :  ERR,                     ! Uncorrupted error of width (not used)
     :  PCEN, QCEN,              ! Calculated p,q centre
     :  PSUM( -MAXP:MAXP ),      ! p marginal profile
     :  QSUM( -MAXP:MAXP ),      ! q marginal profile
     :  SHIFT,                   ! Shift from the old centre to the new
     :  SIGMA( 4 ),              ! Sigmas of the 4 profiles ?
     :  SIGP,                    ! p marginal sigma
     :  SIGQ,                    ! q marginal sigma
     :  SIGX,                    ! x marginal sigma
     :  SIGY                     ! y marginal sigma
 
      REAL
     :  V,                       ! Work variable
     :  X, Y,                    ! Centre of the current star
     :  XCEN, YCEN,              ! Calculated x,y centre
     :  XNEW, YNEW,              ! New centre of the current star
     :  XSUM( -MAXX:MAXX ),      ! x marginal profile
     :  YSUM( -MAXX:MAXX )       ! y marginal profile
 
      INTEGER
     :  BINI, BINJ,              ! Bin loop counters (x,y)
     :  BINP, BINQ,              ! Bin loop counters (45 degree)
     :  I, J,                    ! Pixel loop counters
     :  I0, J0,                  ! Pixel nearest the star centre
     :  IDP,                     ! 45-degree number of bins
     :  IDX,                     ! Number of bins
     :  ITER,                    ! Iteration counter
     :  IX,                      ! Size of the search area
     :  NP( -MAXP:MAXP ),        ! Number of good pixels in the p
                                 ! marginals
     :  NQ( -MAXP:MAXP ),        ! Number of good pixels in the q
                                 ! marginals
     :  NSIG,                    ! Sigma counter
     :  NX( -MAXX:MAXX ),        ! Number of good pixels in the x
                                 ! marginals
     :  NY( -MAXX:MAXX ),        ! Number of good pixels in the y
                                 ! marginals
     :  STAR                     ! Star counter
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'      ! NUM definitions for conversions
*.
 
*    Check inherited global status.
 
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*    Start a new error context.
 
      CALL ERR_MARK
 
*    Determine the size of the search area as odd and not exceeding
*    MAXSIZ, then determine the corresponding number of bins in the
*    45-degree directions.
 
      IX = MIN( ISIZE, MAXSIZ )
      IDX = MAX( 1, IX / 2 )
      IDP = NINT( 1.41421 * IDX )
 
 
*    Consider each star position in turn, counting the successes.
 
      NGOOD = 0
 
      DO STAR = 1, NXY
 
*       The star positions are supplied in world co-ordinates.  In this
*       routine the array has lower bounds which are both one, but the
*       positions may not.  Therefore correct the positions to what they
*       would be given lower bounds of one.
 
         X = REAL( POS( STAR, 1 ) ) - REAL( LBND( 1 ) - 1 )
         Y = REAL( POS( STAR, 2 ) ) - REAL( LBND( 2 ) - 1 )
 
*       Perform the iterations, each time centering the search area on
*       the previous estimate of the star centre.
 
         DO ITER = 1, NITER
            I0 = NINT( MIN( MAX( - 1.0E8, X ), 1.0E8 ) )
            J0 = NINT( MIN( MAX( - 1.0E8, Y ), 1.0E8 ) )
 
*          Initialise arrays for forming the marginal profiles in the
*          x and y directions and at 45 degrees (p and q).
 
            DO I = -IDX, IDX
               XSUM( I ) = 0.0
               YSUM( I ) = 0.0
               NX( I ) = 0
               NY( I ) = 0
            END DO
 
            DO I = -IDP, IDP
               PSUM( I ) = 0.0
               QSUM( I ) = 0.0
               NP( I ) = 0
               NQ( I ) = 0
            END DO
 
*          Now form the marginal profiles, scanning a large enough image
*          area to accommodate the search square turned through 45
*          degrees.
 
            DO BINJ = -IDP, IDP
               J = J0 + BINJ
 
*             Check that we are still inside the image.
 
               IF ( J .GE. 1 .AND. J .LE. DIM2 ) THEN
 
                  DO BINI = -IDP, IDP
                     I = I0 + BINI
 
                     IF ( I .GE. 1 .AND. I .LE. DIM1 ) THEN
 
 
*                     If the pixel is valid, find the p,q coordinates.
 
                        IF ( ARRAY( I, J ) .NE. VAL__BADI ) THEN
                           BINP = BINI + BINJ
                           BINQ = BINJ - BINI
 
*                         If the pixel lies in the normal search square,
*                         add it to the x and y marginals.  Do the
*                         summations in floating point.
 
                           IF ( ABS( BINI ) .LE. IDX .AND. ABS( BINJ )
     :                           .LE. IDX ) THEN
                              V = NUM_BTOR( ARRAY( I, J ) )
                              XSUM( BINI ) = XSUM( BINI ) + V
                              YSUM( BINJ ) = YSUM( BINJ ) + V
                              NX( BINI ) = NX( BINI ) + 1
                              NY( BINJ ) = NY( BINJ ) + 1
                           END IF
 
*                         If the pixel lies in the 45 degree square,
*                         add it to the p and q marginals.  Do the
*                         summations in floating point.
 
                           IF ( ABS( BINP ) .LE. IDP .AND. ABS( BINQ )
     :                           .LE. IDP ) THEN
                              V = NUM_BTOR( ARRAY( I, J ) )
                              PSUM( BINP ) = PSUM( BINP ) + V
                              QSUM( BINQ ) = QSUM( BINQ ) + V
                              NP( BINP ) = NP( BINP ) + 1
                              NQ( BINQ ) = NQ( BINQ ) + 1
                           END IF
                        END IF
                     END IF
                  END DO
               END IF
            END DO
 
 
*          Evaluate the x and y marginals.
 
            DO I = -IDX, IDX
 
               IF ( NX( I ) .GT. 0 ) THEN
                  XSUM( I ) = XSUM( I ) / NX( I )
 
               ELSE
                  XSUM( I ) = VAL__BADR
               END IF
 
 
               IF ( NY( I ) .GT. 0 ) THEN
                  YSUM( I ) = YSUM( I ) / NY( I )
 
               ELSE
                  YSUM( I ) = VAL__BADR
               END IF
            END DO
 
*          Evaluate the p and q marginals.
 
            DO I = -IDP, IDP
 
               IF ( NP( I ) .GT. 0 ) THEN
                  PSUM( I ) = PSUM( I ) / NP( I )
 
               ELSE
                  PSUM( I ) = VAL__BADR
               END IF
 
 
               IF ( NQ( I ) .GT. 0 ) THEN
                  QSUM( I ) = QSUM( I ) / NQ( I )
 
               ELSE
                  QSUM( I ) = VAL__BADR
               END IF
 
            END DO
 
*          Remove the background and neighbouring stars, dirt
*          etc. from each profile.
 
            CALL KPS1_CLNSR( -IDX, IDX, 0.0, XSUM( -IDX ), STATUS )
            CALL KPS1_CLNSR( -IDX, IDX, 0.0, YSUM( -IDX ), STATUS )
            CALL KPS1_CLNSR( -IDP, IDP, 0.0, PSUM( -IDP ), STATUS )
            CALL KPS1_CLNSR( -IDP, IDP, 0.0, QSUM( -IDP ), STATUS )
 
 
*          Fit a Gaussian to each profile.
 
            CALL KPG1_GAUFR( XSUM( - IDX ), -IDX, IDX, NGAUIT, TOLL,
     :                       AX, XCEN, SIGX, BACK, STATUS )
            CALL KPG1_GAUFR( YSUM( - IDX ), -IDX, IDX, NGAUIT, TOLL,
     :                       AY, YCEN, SIGY, BACK, STATUS )
            CALL KPG1_GAUFR( PSUM( - IDP ), -IDP, IDP, NGAUIT, TOLL,
     :                       AP, PCEN, SIGP, BACK, STATUS )
            CALL KPG1_GAUFR( QSUM( - IDP ), -IDP, IDP, NGAUIT, TOLL,
     :                       AQ, QCEN, SIGQ, BACK, STATUS )
 
 
*          If no fatal errors were encountered, calculate a mean centre
*          position from the centres of each profile.  Otherwise exit
*          from the iteration loop which finds the centre.
 
            IF ( STATUS .NE. SAI__OK ) GO TO 50
            XNEW = I0 + ( XCEN + 0.5 * ( PCEN - QCEN ) ) * 0.5
            YNEW = J0 + ( YCEN + 0.5 * ( PCEN + QCEN ) ) * 0.5
 
*          Calculate shift of centre this iteration... if it satisfies
*          the accuracy criterion, exit from the centre-finding
*          iteration loop.
 
            SHIFT = SQRT( ( X - XNEW ) *  * 2 + ( Y - YNEW ) *  * 2 )
            X = XNEW
            Y = YNEW
 
            IF ( SHIFT .LE. TOLL ) GO TO 50
 
         END DO
 
*       If the centre was found successfully, record the widths of each
*       profile and the star centre and form a weight from the star
*       amplitude.
 
   50    CONTINUE
         IF ( STATUS .EQ. SAI__OK ) THEN
            NGOOD = NGOOD + 1
 
*          Correct for different bin spacing in the p,q directions.
 
            SIGP = 0.7071068 * SIGP
            SIGQ = 0.7071068 * SIGQ
            POS( STAR, 1 ) = DBLE( X ) + DBLE( LBND( 1 ) - 1 )
            POS( STAR, 2 ) = DBLE( Y ) + DBLE( LBND( 2 ) - 1 ) 
            SIG( STAR, 1 ) = SIGX 
            SIG( STAR, 2 ) = SIGP 
            SIG( STAR, 3 ) = SIGY 
            SIG( STAR, 4 ) = SIGQ 
            SIG( STAR, 5 ) = AP + AQ + AX + AY 
 
*          If the centre was not found successfully, record the
*          weight as zero.
 
         ELSE
            SIG( STAR, 1 ) = 0.0
            SIG( STAR, 2 ) = 0.0
            SIG( STAR, 3 ) = 0.0
            SIG( STAR, 4 ) = 0.0
            SIG( STAR, 5 ) = 0.0
         END IF
 
      END DO
 
*    If at least one star was successful, find a mean width for each
*    profile direction.
 
      IF ( NGOOD .GE. 1 ) THEN
 
         IF ( NGOOD .GT. 1 ) THEN
            DO NSIG = 1, 4
               CALL KPG1_WMODR( SIG( 1, NSIG ), SIG( 1, 5 ), NXY, 0.01,
     :                          ITMODE, TOLL, SIGMA( NSIG ), ERR,
     :                          STATUS )
            END DO
 
*       Only one object so there is no mean width.
 
         ELSE
            DO NSIG = 1, 4
               SIGMA( NSIG ) = SIG( 1, NSIG )
            END DO
         END IF
 
*       Find the parameters of an elliptical star image
*       from the marginal widths.
 
         CALL KPS1_ELGAU( SIGMA, SIG0, AXISR, THETA, STATUS )
      END IF
 
*    Close the new error context.
 
      CALL ERR_RLSE
 
      END
