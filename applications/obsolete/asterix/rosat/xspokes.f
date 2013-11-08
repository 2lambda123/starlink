*+  XSPOKES - defines the ribs region on a PSPC image
      SUBROUTINE XSPOKES(STATUS)
*    Description :
*     Defines the rib region on a PSPC image in an ARD spatial file.
*    Method :
*     Works in either Interactive or Calculate mode.
*     Interactive:
*       The user is asked to define two opposite points on the image
*       where the inner circle and ribs intersect.
*     Calculate:
*       Uses the roll angle contained in an attitude file, supplied
*       by the user, to calculate the position of the spokes.
*    Deficiencies :
*    Bugs :
*    Authors :
*     LTVAD::RDS
*    History :
*      12 Feb 92: V1.6-1 original (RDS)
*      30 Mar 92: V1.6-2 allows existing ARD file to be updates (RDS)
*      10 Jun 92: V1.6-3 attempts to use the attitude file to determine
*                        the rib positions (RDS)
*      20 Apr 93: V1.6-4 uses a different attitude file for US data.
*      23 Apr 94: V1.6-5 converted for use with RAT lookup table
*      24 Apr 94: (V1.7-0) for new asterix release
*      03 May 94: (v1.7-1) takes correct action if image system not active
*      27-May-94: Opens output textfile with STATUS="UNKNOWN"
*      15-Jun-94: (v1.7-2)Takes a list (or file) of times to select the mean
*                 roll angle on. 0 roll is now valid.
*      20-Jun-94: (v1.7-3)workaround for bug in CHR_RTOC (uses DTOC)
*       2 Feb 95: v1.8-0  upgrade to new ARD (RJV)
*       7 Apr 98: v2.2-1  removed structures (rjv)
*    Type definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'MATH_PAR'
*    Global variables :
      INCLUDE 'XRTHEAD_CMN'
*    Status :
      INTEGER STATUS
*    Function declarations :
      INTEGER CHR_LEN
        EXTERNAL CHR_LEN
      EXTERNAL IMG_ISOPEN
        LOGICAL IMG_ISOPEN
*    Local variables :
      CHARACTER CH
      CHARACTER MODE                    ! Operation mode C or I
      CHARACTER*80 TEXT
      CHARACTER*132 SFILE
      CHARACTER*132 ATTFIL               ! Attitude file
      CHARACTER*132 ROOTNAME            ! rootname of datafiles
      CHARACTER*20 EXT                  ! Extension name
      CHARACTER*20 ROLL                 ! column name
      CHARACTER*20 TIME                 ! column name
      CHARACTER*(DAT__SZLOC) ALOC       ! Locator to attitude file
      LOGICAL LOUT                      ! include the region outside the image ?
      LOGICAL LNEW                      ! create a new ARD file or update ?
      LOGICAL LPLOT                     ! display the spokes pattern ?
      REAL X1,Y1,X2,Y2,XC,YC
      REAL RAD,RADWID,INNRAD,OUTRAD
      REAL SLENGTH                      ! length of spokes in degs
      REAL SWIDTH                       ! width of spokes in degs
      REAL XSPOKE,YSPOKE                ! centre of intersection of spoke
*                                       ! and central ring
      REAL DELTAX,DELTAY
      REAL XSP(4),YSP(4)                ! cornes of spoke
      REAL XEND,YEND                    ! centre of end of spoke
      REAL XANG                         ! X value to calc spoke angle from.
      REAL TRAD                         ! radius of the total circular f.o.v.
      REAL RMEAN                        ! mean roll angle Degrees
      REAL THETA                        ! mean roll angle (radians)
      REAL EXTRA                        ! additional width of ribs (degs)
      INTEGER RPNTR                     ! pointer to the roll angle array
      INTEGER TPNTR                     ! pointer to the time array
      INTEGER NVALS                     ! number of time/roll values
      INTEGER SUNIT                     ! Logical unit of ARD file
      INTEGER LP
      INTEGER L
      INTEGER ARDID
*    Version :
      CHARACTER*30 VERSION
      PARAMETER (VERSION = 'XSPOKES Version 2.2-2')
*-
      CALL AST_INIT()
      CALL MSG_PRNT(VERSION)

      CALL ARX_OPEN('WRITE',ARDID,STATUS)
*
*     Enquire whether a new ARD file is to be created
      CALL USI_GET0L('NEW', LNEW, STATUS)
*
*     Get name of ARD file
      CALL USI_GET0C('ARDFILE', SFILE, STATUS)
      IF (STATUS .NE. SAI__OK) GOTO 999
*
*
*
*     Open the spatial file - get filename from the user
      IF (LNEW) THEN
         CALL FIO_OPEN(SFILE,'WRITE','LIST',0,SUNIT,STATUS)
      ELSE
         CALL FIO_OPEN(SFILE,'APPEND','LIST',0,SUNIT,STATUS)
      ENDIF

      IF (STATUS .NE. SAI__OK) THEN
         CALL MSG_PRNT('** Error opening spatial description file **')
         GOTO 999
      ENDIF
*
*
*     see if user wants to define the pixels interactively
      CALL USI_GET0C('MODE', MODE, STATUS)
      IF (STATUS .NE. SAI__OK) GOTO 999
*
*     Convert the mode to uppercase
      CALL CHR_UCASE(MODE)
*
*     Ask if user wants the area outside the circular field
*     of view setting bad
      CALL USI_GET0L('OUTSIDE', LOUT, STATUS)
      IF (STATUS .NE. SAI__OK) GOTO 999
*
*     Find if plotting required in Calculate mode, should be yes by default
      IF (MODE .EQ. 'C') THEN
*        plot is image processing system active
         CALL USI_DEF0L('DOPLOT', IMG_ISOPEN( STATUS ), STATUS)
         CALL USI_GET0L('DOPLOT', LPLOT, STATUS)
      ELSE
         LPLOT = .TRUE.
      ENDIF
      IF (STATUS .NE. SAI__OK) GOTO 999
*
*     If ouside to be set bad
      IF (LOUT) THEN
         XC=0.0
         YC=0.0
*
*        Get the radius of the circle from the parameter system
         CALL USI_GET0R('TRAD', TRAD, STATUS)
*
         IF (STATUS .NE. SAI__OK) GOTO 999
*
*        Write the outer region into ARD description
         TEXT=' .NOT.(CIRCLE( 0.0 , 0.0 ,'
         L=CHR_LEN(TEXT)
         CALL MSG_SETR('R',TRAD)
         CALL MSG_MAKE(TEXT(:L)//' ^R ))',TEXT,L)
         CALL ARX_PUT(ARDID,0,TEXT(:L),STATUS)
*
*        Draw limiting circle on the plot
         IF (LPLOT) CALL XRT_CIRCLE(XC,YC,TRAD,STATUS)
*
      ENDIF
*
*     Use the cal. files ?
      IF (MODE .EQ. 'C') THEN
*
*        find the name for the attitude file
         CALL USI_GET0C('ROOTNAME', ROOTNAME, STATUS)
         IF (STATUS .NE. SAI__OK) GOTO 999
*
*        Open the header file to get the origins of the data
         CALL RAT_GETXRTHEAD(ROOTNAME,STATUS)
*
*        build the attitude file name
         CALL RAT_HDLOOKUP('ASPDATA','EXTNAME',EXT,STATUS)
         ATTFIL = ROOTNAME(1:CHR_LEN(ROOTNAME))//EXT
*
*        set the default filename
         CALL USI_DEF0C('ATTFIL', ATTFIL, STATUS)
         CALL USI_GET0C('ATTFIL', ATTFIL, STATUS)
         IF (STATUS .NE. SAI__OK) GOTO 999
*
*
         CALL HDS_OPEN(ATTFIL, 'READ', ALOC, STATUS)
*
         IF (STATUS .NE. SAI__OK) THEN
            CALL MSG_PRNT('Error opening attitude file - try defining '/
     &                   /'the spokes with the cursor')
            GOTO 999
         ENDIF
*
*  get the mean roll angle and times from the system
         CALL RAT_HDLOOKUP('ASPDATA','ROLL',ROLL,STATUS)
         CALL CMP_MAPV(ALOC,ROLL,'_REAL','READ',RPNTR,NVALS,STATUS)
         IF (STATUS .NE. SAI__OK) THEN
            CALL MSG_SETC('ARR',ROLL)
            CALL MSG_PRNT('** Error accessing ROLL angle array ^ARR **')
            GOTO 999
         ENDIF
         CALL RAT_HDLOOKUP('ASPDATA','TIME',TIME,STATUS)
         CALL CMP_MAPV(ALOC,TIME,'_DOUBLE','READ',TPNTR,NVALS,STATUS)
         IF (STATUS .NE. SAI__OK) THEN
            CALL MSG_SETC('ARR',TIME)
            CALL MSG_PRNT('** Error accessing TIME array ^ARR **')
            GOTO 999
         ENDIF
*
*  find the mean roll angle - file is often corrupted so need to
*  ignore zeroes in the file (this could of course bias the result if
*  the roll angle is actually close to zero).
         CALL XSPOKES_MEANROLL( NVALS, %val(TPNTR), %val(RPNTR),
     &                                                   RMEAN, STATUS)
*
         IF (STATUS .NE. SAI__OK) GOTO 999
*
         THETA = (RMEAN * MATH__PI) / 180.0
         CALL MSG_SETR('ANG', RMEAN)
         CALL MSG_PRNT('Rotation angle = ^ANG degrees')
*
*
*  set the various standard values  -  radius of the circle seems to be
*  about 21 arcmins.
         RAD = 21.0 / 60.0  ! degrees
         XC = 0.0
         YC = 0.0
*
      ELSE IF(MODE .EQ. 'I') THEN
*
*     get first intersection
         CALL MSG_PRNT(' ')
         CALL MSG_PRNT('Select an intersection of a '/
     &                 /'spoke and the central ring')
         CALL PGCURSE(X1,Y1,CH)
         CALL PGPOINT(1,X1,Y1,2)

*     get second intersection
         CALL MSG_PRNT(' ')
         CALL MSG_PRNT('Select the intersection of the opposite '/
     &                 /'spoke and the central ring')
         CALL PGCURSE(X2,Y2,CH)
         CALL PGPOINT(1,X2,Y2,2)

*     calculate radius
         RAD = SQRT( (X2 - X1)**2 + (Y2 - Y1)**2 ) / 2
*
*     calculate centre of ring
         XC = (X1 + X2) / 2.0
         YC = (Y1 + Y2) / 2.0
*
*     calculate the angle to south of the first spoke  (Terrestial west
*     is +90 degs). Find the angle from the centre with the largest
*     Y value
         IF (Y1 .GT. Y2) THEN
            XANG = X1
         ELSE
            XANG = X2
         ENDIF
*
         THETA = ASIN((XANG-XC)/RAD)
*
      ENDIF
*
*  Allow the user to add a constant onto the width value
      CALL USI_GET0R('EXTRA_WIDTH', EXTRA, STATUS)
*
*  calculate inner and outer radius of central ring
*  Set circle width - assuming image is in degrees.
      RADWID = 0.06 + EXTRA
*
      INNRAD = RAD - RADWID / 2.0
      OUTRAD = RAD + RADWID / 2.0
*
*  display central ring exclusion zone on image
      IF (LPLOT) THEN
         CALL XRT_CIRCLE(XC,YC,INNRAD,STATUS)
         CALL XRT_CIRCLE(XC,YC,OUTRAD,STATUS)
      ENDIF
*
* Write in the annulus description
      TEXT=' (CIRCLE( '
      L=CHR_LEN(TEXT)

      CALL MSG_SETR('XC',XC)
      CALL MSG_SETR('YC',YC)
      CALL MSG_SETR('RAD',OUTRAD)
      CALL MSG_MAKE(TEXT(:L)//' ^XC , ^YC , ^RAD )',TEXT,L)

      CALL ARX_PUT(ARDID,0,TEXT(:L),STATUS)


      TEXT='     .AND..NOT.CIRCLE('
      L=CHR_LEN(TEXT)

      CALL MSG_SETR('XC',XC)
      CALL MSG_SETR('YC',YC)
      CALL MSG_SETR('RAD',INNRAD)
      CALL MSG_MAKE(TEXT(:L)//' ^XC , ^YC , ^RAD ))',TEXT,L)

      CALL ARX_PUT(ARDID,0,TEXT(:L),STATUS)


*
*  set the length and width of the spokes in degrees. NB: this does assume that
*  the image axes are degrees.
      SLENGTH = 0.69
      SWIDTH = 0.06 + EXTRA
*
*  Loop over each spoke
      DO LP=1,8
*
*  Calculate the X,Y position of the centre of the start of each spoke
         XSPOKE = RAD * SIN(THETA) + XC
         YSPOKE = RAD * COS(THETA) + YC
*
*  Calc. the four corners of the spoke
         DELTAX = COS(THETA) * SWIDTH / 2.
         DELTAY = SIN(THETA) * SWIDTH / 2.
*
         XSP(1) = XSPOKE - DELTAX
         XSP(2) = XSPOKE + DELTAX
         YSP(1) = YSPOKE + DELTAY
         YSP(2) = YSPOKE - DELTAY
*
*      Calc the centre coords of the end of the spoke
         XEND = XSPOKE + SLENGTH * SIN(THETA)
         YEND = YSPOKE + SLENGTH * COS(THETA)
*
         XSP(3) = XEND + DELTAX
         XSP(4) = XEND - DELTAX
         YSP(3) = YEND - DELTAY
         YSP(4) = YEND + DELTAY
*
*  Display this spoke on the image
         IF (LPLOT) THEN
            CALL PGMOVE(XSP(1),YSP(1))
            CALL PGDRAW(XSP(2),YSP(2))
            CALL PGDRAW(XSP(3),YSP(3))
            CALL PGDRAW(XSP(4),YSP(4))
            CALL PGDRAW(XSP(1),YSP(1))
         ENDIF
*
*  Write the spoke description into the ARD text
         TEXT=' POLYGON('
         L=CHR_LEN(TEXT)
         CALL MSG_SETR('X1',XSP(1))
         CALL MSG_SETR('Y1',YSP(1))
         CALL MSG_SETR('X2',XSP(2))
         CALL MSG_SETR('Y2',YSP(2))
         CALL MSG_MAKE(TEXT(:L)//' ^X1 , ^Y1 , ^X2 , ^Y2 ,',TEXT,L)
         CALL ARX_PUT(ARDID,0,TEXT(:L),STATUS)
         TEXT=' '
         L=9
         CALL MSG_SETR('X3',XSP(3))
         CALL MSG_SETR('Y3',YSP(3))
         CALL MSG_SETR('X4',XSP(4))
         CALL MSG_SETR('Y4',YSP(4))
         CALL MSG_MAKE(TEXT(:L)//' ^X3 , ^Y3 , ^X4 , ^Y4 )',TEXT,L)
         CALL ARX_PUT(ARDID,0,TEXT(:L),STATUS)
*
*  Calculate the angle of the next spoke to south
         THETA = THETA + MATH__PI/4.0
*
      ENDDO
*
*  Write out ARD text and close file
      CALL ARX_WRITEF(ARDID,SUNIT,STATUS)
      CALL ARX_CLOSE(ARDID,STATUS)
      CALL FIO_CLOSE(SUNIT,STATUS)

      IF (MODE .EQ. 'C') CALL HDS_CLOSE(ALOC, STATUS)

*  Tidy up
 999  CALL AST_CLOSE()
      CALL AST_ERR( STATUS )

      END

*+ XSPOKES_MEANROLL - calculates the mean roll angle
      SUBROUTINE XSPOKES_MEANROLL(NVALS,TIME,ROLL,MEANROLL,STATUS)
*    Description :
*    Method :
*    History :
*    Type definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'PAR_ERR'
*    Global variables :
      INCLUDE 'XRTHEAD_CMN'
*    Import :
      INTEGER NVALS
      DOUBLE PRECISION TIME(NVALS)
      REAL ROLL(NVALS)
*    Import-Export :
*     <declarations and descriptions for imported/exported arguments>
*    Export :
      REAL MEANROLL                ! Degrees
*    Status :
      INTEGER STATUS
*    Local constants :
      INTEGER MXTIME
      PARAMETER (MXTIME = 500)
*    Local variables :
      CHARACTER*132 TIMSTRING
      CHARACTER*20 C1,C2
      INTEGER LP,CNT,TP,NTIME,K1,K2
      REAL RTOT
      DOUBLE PRECISION TOFFSET
      DOUBLE PRECISION TMIN(MXTIME),TMAX(MXTIME)
      DOUBLE PRECISION START,STOP
*    Local data :
*-
      RTOT = 0.0
      CNT = 0
*
*     Time range may be input as either a string of start and stop
*     times or a text file of times. The times may be expressed as offsets
*     from time zero or as MJDs in which case they are prefixed wih an 'M'.
      START = HEAD_TSTART(1)
      STOP = HEAD_TEND(HEAD_NTRANGE)
      CALL CHR_DTOC(START, C1, K1)
      CALL CHR_DTOC(STOP, C2, K2)
      TIMSTRING = C1(1:K1) // ':' // C2(1:K2)
      CALL USI_DEF0C('TIMRANGE', TIMSTRING, STATUS)
      CALL USI_GET0C('TIMRANGE',TIMSTRING,STATUS)
*
*     Decode the timestring into a sequence of start and stop times
      CALL UTIL_TDECODE(TIMSTRING, HEAD_BASE_MJD, MXTIME,
     &                      NTIME, TMIN, TMAX, STATUS)
*
      IF (STATUS .NE. SAI__OK) GOTO 999

      DO LP = 1, NVALS
         DO TP = 1, NTIME
            TOFFSET = TIME(LP) - HEAD_BASE_SCTIME
            IF ((TOFFSET.GT.TMIN(TP)).AND.(TOFFSET.LT.TMAX(TP))) THEN
               RTOT = RTOT + ROLL(LP)
               CNT = CNT + 1
            ENDIF
         ENDDO
      ENDDO
*
      IF (CNT .GE. 1) THEN
         MEANROLL = RTOT / CNT
*  convert mean roll to degrees and to the convention of west=+90.
         IF (HEAD_ORIGIN.EQ.'RDF')
     &      MEANROLL = (MEANROLL + 180.0) * 7200.0     ! degrees to Arcmin/2
         MEANROLL = 270. - (MEANROLL / 7200.0)         ! Arcmin/2 to degrees
         IF (MEANROLL.LT.0.0) MEANROLL = MEANROLL + 360.0
         IF (MEANROLL.GT.360.0) MEANROLL = MEANROLL - 360.0
      ELSE
         CALL MSG_PRNT('Warning: No valid roll angles, using default')
         MEANROLL = 0.0
      ENDIF

999   CONTINUE

      END
