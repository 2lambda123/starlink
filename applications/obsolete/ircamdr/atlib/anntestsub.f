	SUBROUTINE ANNTESTSUB( NX, NY, INARR, OUTARR, X, Y, WIDTH, PLATSCAL,
     :	                       ECC, ANG, USEBAD, BADVAL, WHAT)

	IMPLICIT NONE           

*    HISTORY 
*    14-JUL-1994  Changed LIB$ to FIO_ (SKL@JACH)

	INCLUDE 'SAE_PAR'       
        INCLUDE 'FIO_PAR'

	INTEGER
     :    NX,
     :	  NY,
     :	  X,
     :	  Y,
     :	  NPTS,
     :	  BNPTS,
     :	  I,
     :	  J,
     :	  K,
     :	  STATUS,
     :	  NUMANN,
     :	  IFAIL,
     :	  LUN,
     :	  MAXDATA

	PARAMETER ( MAXDATA = 10000)

	REAL
     :	  INARR( NX, NY),
     :	  OUTARR( NX, NY),
     :	  PLATSCAL,
     :    WIDTH,
     :	  R,
     :	  R1,
     :	  R2
      REAL
     :	  MAXX,
     :	  MAXY,
     :	  MAXXR,
     :	  MAXYR,
     :	  MAXR,
     :	  MAXRA,
     :	  VALMAX, 
     :	  VALMIN, 
     :	  SUM, 
     :	  MEAN, 
     :	  MEDIAN, 
     :	  MODE,
     :	  BADVAL,
     :	  ECC,
     :	  ANG,
     :	  XR,
     :	  YR

	REAL*8
     :	  DATARR( MAXDATA)

	CHARACTER*( *) 
     :	  WHAT

	LOGICAL
     :	  USEBAD

	MAXX = MAX( REAL( ABS( NX-X)), REAL( X))
	MAXY = MAX( REAL( ABS( NY-Y)), REAL( Y))

	MAXXR = MAXX*COSD( ANG) - MAXY*SIND( ANG)
	MAXYR = MAXX*SIND( ANG) + MAXY*COSD( ANG)

	MAXR = SQRT( MAXXR**2 + MAXYR**2/(1-ECC**2))
	MAXRA = MAXR*PLATSCAL

	IF( WIDTH .GT. 0.0) THEN
	  NUMANN = MAXRA/WIDTH
	ELSE
	  NUMANN = 0
	END IF

	CALL MSG_SETR( 'SZ', WIDTH)
	CALL MSG_SETI( 'NU', NUMANN)
	CALL MSG_OUT( 'MESS', 'Number of ^SZ arcsec annuli in image = ^NU',
     :	              STATUS)

	CALL FIO_GUNIT( LUN, STATUS )
C###87 [Sunf77] Warning: ignoring unimplemented "carriagecontrol" specifier%%%
	OPEN( UNIT=LUN, FILE='ANNSTATS.RES', STATUS='NEW',
     :	      CARRIAGECONTROL='LIST')

	DO I = 1, NUMANN

	  CALL MSG_OUT( 'BLANK', ' ', STATUS)

	  NPTS = 0
	  BNPTS = 0

	  R1 = ( I-1)*WIDTH/PLATSCAL
	  R2 = I*WIDTH/PLATSCAL

	  DO K = 1, NY

	    DO J = 1, NX

	      XR = ( J-X)*COSD( ANG) - ( K-Y)*SIND( ANG)
	      YR = ( J-X)*SIND( ANG) + ( K-Y)*COSD( ANG)

	      R = SQRT( ( XR**2 + YR**2/(1-ECC**2)))

	      IF( R .GE. R1 .AND. R .LT. R2) THEN

	        IF( USEBAD .EQ. .TRUE. .AND. 
     :	            INARR( J, K) .NE. BADVAL) THEN

	          NPTS = NPTS + 1

	          DATARR( NPTS) = DBLE( INARR( J, K))

	          IF( IFIX( I/2.0)*2 .EQ. I) THEN
	            OUTARR( J, K) = 1
	          ELSE
	            OUTARR( J, K) = 0
	          END IF

	        ELSE IF( USEBAD .EQ. .TRUE. .AND. 
     :	                 INARR( J, K) .EQ. BADVAL) THEN

	          BNPTS = BNPTS + 1

	        ELSE IF( USEBAD .NE. .TRUE.) THEN

	          NPTS = NPTS + 1

	          DATARR( NPTS) = DBLE( INARR( J, K))

	        END IF
	      END IF

	    END DO
	  END DO

	  CALL MSG_SETI( 'N', I)
	  CALL MSG_SETI( 'NU', NPTS)
	  CALL MSG_OUT( 'MESS', ' Number of pixels in annulus ^N    = ^NU',
     :	                STATUS)

	  IF( USEBAD .AND. BNPTS .NE. 0) THEN
	    CALL MSG_SETI( 'N', I)
	    CALL MSG_SETI( 'NU', BNPTS)
	    CALL MSG_OUT( 'MESS', ' Number of BAD pixels in annulus ^N = ^NU',
     :	                STATUS)
	  END IF

*        Sort the pixel values in each stack image
	  IF( NPTS .GT. 0) THEN
	    IFAIL = 0
	    CALL M01ANF( DATARR, 1, NPTS, IFAIL)
 
*          call subroutine to find median for the input DATARR
	    CALL MED3D_CALMEDSUB( NPTS, DATARR, VALMAX, VALMIN, SUM, MEAN, 
     :	                          MEDIAN, MODE)

	  ELSE

	    VALMAX = 0.0
	    VALMIN = 0.0
	    SUM = 0.0
	    MEAN = 0.0
	    MEDIAN = 0.0
	    MODE = 0.0

	  END IF

	  CALL MSG_SETI( 'N', I)
	  CALL MSG_SETR( 'MEA', MEAN)
	  CALL MSG_SETR( 'MED', MEDIAN)
	  CALL MSG_SETR( 'MOD', MODE)
	  CALL MSG_OUT( 'MESS', 
     :	    ' Annulus ^N, Mean = ^MEA, Median = ^MED, Mode = ^MOD', 
     :	                STATUS)

	  R1 = R1*PLATSCAL
	  R2 = R2*PLATSCAL

	  IF( WHAT .EQ. 'MEAN') THEN

	    WRITE( LUN, *) R1, R2, NPTS, MEAN

	  ELSE IF( WHAT .EQ. 'MEDIAN') THEN

	    WRITE( LUN, *) R1, R2, NPTS, MEDIAN

	  ELSE IF( WHAT .EQ. 'MODE') THEN

	    WRITE( LUN, *) R1, R2, NPTS, MODE

	  ELSE IF( WHAT .EQ. 'TOTAL') THEN

	    WRITE( LUN, *) R1, R2, NPTS, SUM

	  ELSE IF( WHAT .EQ. 'MAX') THEN

	    WRITE( LUN, *) R1, R2, NPTS, VALMAX

	  ELSE IF( WHAT .EQ. 'MIN') THEN

	    WRITE( LUN, *) R1, R2, NPTS, VALMIN

	  END IF

	END DO

	CLOSE( LUN)
	CALL FIO_PUNIT( LUN, STATUS )

	CALL MSG_OUT( 'BLANK', ' ', STATUS)
	CALL MSG_OUT( 'MESS', 'Results written to ANNSTATS.RES', STATUS)
	CALL MSG_OUT( 'BLANK', ' ', STATUS)

	END
