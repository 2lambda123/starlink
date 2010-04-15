      SUBROUTINE CCG1_CENR( XINIT, YINIT, IMAGE, NCOL, NLINE, ISIZE,
     :                        SIGN, MAXSHF, MAXIT, TOLER, XACC, YACC,
     :                        STATUS )
*+
*  Name:
*     CCG1_CEN

*  Purpose:
*     Locates the centroids of star-like image features.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCG1_CENR( XINIT, YINIT, IMAGE, NCOL, NLINE, ISIZE, SIGN,
*                      MAXSHF, MAXIT, TOLER, XACC, YACC, STATUS )

*  Description:
*     The routine locates the centroid of image features by forming
*     marginal profiles within a search square. A background estimate is
*     made for each element of each profile by finding the lower quartile point
*     in the pixel values contributing to the profile element. These values
*     are then used to form the centroid. This sequence is repeated until a
*     given number of iterations is exceeded or the centroid is located with
*     the given accuracy.

*  Arguments:
*     XINIT = DOUBLE PRECISION (Given)
*        Initial guess at x position of object feature.
*     YINIT = DOUBLE PRECISION (Given)
*        Initial guess at y position of object feature.
*     IMAGE( NCOL, NLINE ) = REAL (Given)
*        The data.
*     NCOL = INTEGER (Given)
*        First dimension of IMAGE.
*     NLINE = INTEGER (Given)
*        Second dimension of IMAGE.
*     ISIZE = INTEGER (Given)
*        The size of the search square side.
*     SIGN = LOGICAL (Given)
*        True of the image features have positive data values. False
*        if they have negative values.
*     MAXSHF = DOUBLE PRECISION (Given)
*        Maximum allowed shift in image centre.
*     MAXIT = INTEGER (Given)
*        Maximum number of refining iterations.
*     TOLER = DOUBLE PRECISION (Given)
*        Accuracy with which the centroid should be located.
*     XACC = DOUBLE PRECISION (Returned)
*        X position of centroid.
*     YACC = DOUBLE PRECISION (Returned)
*        X position of centroid.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  If no centroid is located STATUS will be set and an appropriate
*        message will reported. No coordinate values will be mentioned
*        in the message, this will need to be performed by the calling
*        application.

*  Copyright:
*     Copyright (C) 1998 Central Laboratory of the Research Councils

*  Authors:
*     RFWS: Rodney Warren-Smith (Durham Polarimetry Group)
*     PDRAPER: Peter Draper (STARLINK)
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     - (RFWS):
*        Original version - Durham local version of EDRS.
*     9-JUL-1992 (PDRAPER):
*        Changed prologue, converted to ADAM and made generic.
*     20-MAY-1997 (DSB):
*        Background estimation changed so that a separate background
*        estimate is made for each cell in each profile, rather than
*        using a single background estimate for the whole of each profile.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT constants

*  Arguments Given:
      INTEGER NCOL
      INTEGER NLINE
      REAL IMAGE( NCOL, NLINE )
      INTEGER ISIZE
      LOGICAL SIGN
      DOUBLE PRECISION MAXSHF
      INTEGER MAXIT
      DOUBLE PRECISION TOLER
      DOUBLE PRECISION XINIT
      DOUBLE PRECISION YINIT

*  Arguments Returned:
      DOUBLE PRECISION XACC
      DOUBLE PRECISION YACC

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      INTEGER MAXSID             ! Maximum size of search square side.
      PARAMETER ( MAXSID = 51 )

*  Local Variables:
      DOUBLE PRECISION PSNCNG    ! Position change from initial
      DOUBLE PRECISION SHIFT     ! Shift from last position
      DOUBLE PRECISION VAL       ! Dummy value
      DOUBLE PRECISION WORK( MAXSID ) ! Row/column values
      DOUBLE PRECISION WORK2( MAXSID ) ! Row/column values
      DOUBLE PRECISION X         ! Current X position
      DOUBLE PRECISION XAV( MAXSID ) ! X profile means
      DOUBLE PRECISION XDENOM    ! Sum of data values in profile
      DOUBLE PRECISION XLAST     ! Last X position
      DOUBLE PRECISION XNUMER    ! Weighted sum of X positions
      DOUBLE PRECISION XPOSN( MAXSID ) ! X position of means
      DOUBLE PRECISION Y         ! Current Y postion
      DOUBLE PRECISION YAV( MAXSID ) ! Y profile means
      DOUBLE PRECISION YDENOM    ! Sum of data values in profile
      DOUBLE PRECISION YLAST     ! Last Y position
      DOUBLE PRECISION YNUMER    ! Sum of weighted positions
      DOUBLE PRECISION YPOSN( MAXSID ) ! X position of means
      INTEGER I                  ! Loop counter
      INTEGER IHALF              ! Half square side
      INTEGER IPOSN              ! X position in search square
      INTEGER ISTART             ! X starting point of search square
      INTEGER ITER               ! Number of iterations
      INTEGER J                  ! Loop counter
      INTEGER JPOSN              ! Y position in search square
      INTEGER JSTART             ! Y starting point of search square
      INTEGER NBIN               ! Loop counter
      INTEGER NITER              ! Maximum number of interations
      INTEGER NSAMP              ! Number of bins in search side
      INTEGER NTH                ! Dummy
      INTEGER NVALX              ! Number of non-empty X profile
                                 ! bins
      INTEGER NVALY              ! Number of non-empty Y profile
                                 ! bins
      INTEGER NXAV( MAXSID )     ! Number of values contributed to
                                 ! X bin
      INTEGER NYAV( MAXSID )     ! Number of values contributed to
                                 ! Y bin

*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM_ type conversion functions
      INCLUDE 'NUM_DEF_CVT'      ! Define functions...

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Set up the initial position
      X = XINIT
      Y = YINIT

*  Restrict search square size to lie from 3 to maxsid.
      NSAMP = MIN( MAX( 3, ISIZE ), MAXSID )
      IHALF = NSAMP / 2

*  Make number of iterations at least 1.
      NITER = MAX( 1, MAXIT )

*  Start counting iterations
*  -------------------------
      ITER=0
 63   CONTINUE
         ITER=ITER+1

*  Find starting edge of search square.
         ISTART = NINT( X ) - IHALF - 1
         JSTART = NINT( Y ) - IHALF - 1

*  Remember starting position this iteration.
         XLAST = X
         YLAST = Y

*  Initiallise arrays for forming marginal profiles.
         DO 10 NBIN = 1, NSAMP
            XAV( NBIN ) = 0.0D0
            YAV( NBIN ) = 0.0D0
            NXAV( NBIN ) = 0
            NYAV( NBIN ) = 0
            XPOSN( NBIN ) = 0.0D0
            YPOSN( NBIN ) = 0.0D0
 10      CONTINUE

*  Now form the X and Y profiles for all valid pixels. Do each row and
*  column separately, and subtract a background from each equal to the
*  lower quartile of the values in the row or column.
         DO NBIN = 1, NSAMP

* First do the NBIN'th column...
            IPOSN = ISTART + NBIN
            IF ( ( IPOSN .GE. 1 ) .AND. ( IPOSN .LE. NCOL ) ) THEN
               NVALY = 0

               DO J = 1, NSAMP
                  JPOSN = JSTART + J
                  IF ( ( JPOSN .GE. 1 ) .AND.
     :                 ( JPOSN .LE. NLINE ) ) THEN

                     IF ( IMAGE( IPOSN, JPOSN ) .NE.VAL__BADR ) THEN
                        VAL = NUM_RTOD( IMAGE( IPOSN, JPOSN ) )
                        XAV( NBIN ) = XAV( NBIN ) + VAL
                        NVALY = NXAV( NBIN ) + 1
                        NXAV( NBIN ) = NVALY
                        WORK( NVALY ) = VAL
                        WORK2( NVALY ) = VAL
                     END IF

                  END IF
               END DO

* Find the lower quartile of the pixel values in this column, and subtract
* it from the column's total data sum, NVALY times.
               IF ( NVALY .GT. 0 ) THEN
                  NTH = MAX( NVALY / 4, 2 )
                  CALL CCG1_IS4D( WORK, WORK2, NVALY, STATUS )
                  XAV( NBIN ) = XAV( NBIN ) - NVALY*WORK( NTH )
               END IF

            END IF


* Now do the NBIN'th row...
            JPOSN = JSTART + NBIN
            IF ( ( JPOSN .GE. 1 ) .AND. ( JPOSN .LE. NLINE ) ) THEN
               NVALX = 0

               DO I = 1, NSAMP
                  IPOSN = ISTART + I
                  IF ( ( IPOSN .GE. 1 ) .AND.
     :                 ( IPOSN .LE. NCOL ) ) THEN

                     IF ( IMAGE( IPOSN, JPOSN ) .NE.VAL__BADR ) THEN
                        VAL = NUM_RTOD( IMAGE( IPOSN, JPOSN ) )
                        YAV( NBIN ) = YAV( NBIN ) + VAL
                        NVALX = NYAV( NBIN ) + 1
                        NYAV( NBIN ) = NVALX
                        WORK( NVALX ) = VAL
                        WORK2( NVALX ) = VAL
                     END IF

                  END IF
               END DO

* Find the lower quartile of the pixel values in this row, and subtract
* it from the row's total data sum, NVALX times.
               IF ( NVALX .GT. 0 ) THEN
                  NTH = MAX( NVALX / 4, 2 )
                  CALL CCG1_IS4D( WORK, WORK2, NVALX, STATUS )
                  YAV( NBIN ) = YAV( NBIN ) - NVALX*WORK( NTH )
               END IF

            END IF

         END DO

*  Evaluate those x profile bins which contain at least 1 valid pixel,
*  invert the results if sign is set false. Also determine the position
*  of each bin and record this before it is lost.
         NVALX = 0
         NVALY = 0
         DO 80 NBIN = 1, NSAMP
            IF ( NXAV( NBIN ) .GT. 0 ) THEN
               NVALX = NVALX + 1
               XAV( NVALX ) = XAV( NBIN ) / DBLE( NXAV( NBIN ) )
               IF( .NOT. SIGN ) THEN
                  XAV( NVALX ) = -XAV( NVALX )
               END IF

*  Record position.
               XPOSN( NVALX ) = DBLE( ISTART + NBIN )
            END IF

*  Repeat for the y profile.
            IF( NYAV( NBIN ) .GT. 0 ) THEN
               NVALY = NVALY + 1
               YAV( NVALY ) = YAV( NBIN ) / NYAV( NBIN )
               IF( .NOT. SIGN ) THEN
                  YAV( NVALY ) = -YAV( NVALY )
               END IF

*  Record position.
               YPOSN( NVALY ) = DBLE( JSTART + NBIN )
            END IF
 80      CONTINUE

*  If both profiles contain no data then abort.
         IF ( NVALX .EQ. 0 .AND. NVALY .EQ. 0 ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'CCG1_CENR_NODATA',
     :      '  Centroid - profiles contain no data', STATUS )
            GO TO 99
         END IF

*  Initiallise sums for forming centroids.
         XNUMER = 0.0D0
         XDENOM = 0.0D0
         YNUMER = 0.0D0
         YDENOM = 0.0D0

*  Scan the profiles, using all data above the background to form
*  sums for the centroids.
         IF ( NVALX .GT. 0 ) THEN
            DO 110 NBIN = 1, NVALX
               VAL = MAX ( XAV( NBIN ), 0.0D0 )
               XNUMER = XNUMER + XPOSN( NBIN ) * VAL
               XDENOM = XDENOM + VAL
 110        CONTINUE
         END IF
         IF ( NVALY .GT. 0 ) THEN
            DO 111 NBIN = 1, NVALY
               VAL = MAX ( YAV( NBIN ), 0.0D0 )
               YNUMER = YNUMER + YPOSN( NBIN ) * VAL
               YDENOM = YDENOM + VAL
 111        CONTINUE
         END IF

*  If a profile contained no data then leave the current position at its
*  last value. (This allows for linear features running directly along x
*  or y to be centroided).
         IF ( NVALX .EQ. 0 .AND. YDENOM .NE. 0.0D0 ) THEN
            X = XLAST
            Y = YNUMER / YDENOM
         ELSE IF( NVALY .EQ. 0 .AND. XDENOM .NE. 0.0D0 )THEN
            X = XNUMER / XDENOM
            Y = YLAST
         ELSE IF ( XDENOM .NE. 0.0D0 .AND. YDENOM .NE. 0.0D0 ) THEN

*  Otherwise form the x and y centroids and find the shift from
*  the initial position
            X = XNUMER / XDENOM
            Y = YNUMER / YDENOM
         ELSE

*  Both denominators are zero - spoil this position.
            X = XINIT + MAXSHF + 1.0D0
            Y = YINIT + MAXSHF + 1.0D0
         END IF
         SHIFT = SQRT( ( X - XINIT )**2 + ( Y - YINIT )**2 )

*  If max shift is exceeded abort with error message.
         IF ( SHIFT .GT. MAXSHF ) THEN
            X = XINIT
            Y = YINIT
            STATUS = SAI__ERROR
            CALL ERR_REP( 'CCG1_CENR_MAXSHIFT',
     :      '  Centroid - maximum shift in object position exceeded',
     :      STATUS )
            GO TO 99
         ELSE

*  Otherwise find the position shift this iteration.
            PSNCNG = SQRT( ( X - XLAST )**2 + ( Y - YLAST )**2 )

*  If required accuracy has been met, exit. Otherwise if iterations
*  remain go around iteration loop again.
            IF( PSNCNG .GT. TOLER ) THEN
               IF( ITER .LT. NITER ) GO TO 63
            END IF
         END IF

*  Escape label.
 99   CONTINUE

*  Set output positions to centroid values.
      XACC = X
      YACC = Y

      END
* @(#)ccg1_cen.gen	2.1     11/30/93     2
