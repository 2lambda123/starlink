C+
      SUBROUTINE ISEDIT
C
C     I S E D I T
C
C     Interactively edit a 1D or 2D spectrum allowing points or 
C     complete spectra to be removed
C
C     Command parameters -
C
C     'IMAGE'    The name of the input file.
C     'XSTART'   Starting X value to plot
C     'XEND'     Ending X value to plot
C     'YVALUE'   Number of the row to be plotted.
C     'OUTPUT'   The name of the output file.
C
C     Command keywords -
C
C     'WHOLE'    Plot all of spectrum
C
C
C                                     JAB / JAC 11th Dec 1990
C
C     Modified:
C
C     4th Feb. 1991.  JMS / AAO. Added PAR_ABORT and STATUS checks to
C                     support user requested aborts. Made minor modification
C                     to initialisation of NY variable. Added another
C                     interpolation option, "J", to interpolate between 
C                     chosen points.
C     15th Mar. 1991. JMS / AAO. Write an error array only if there was one
C                     in the input (taken from HME's modification of 20/2/91). 
C     26th Mar 1991.  KS / AAO.  Use of 'UPDATE' and 'WRITE' corrected in
C                     mapping calls.
C     26th Apr 1991.  JMS / AAO. Removed the statements IXS=1 and IXE=NX.
C                     FIG_ISEDIT_RANGE now uses only the selected part of
C                     the spectrum to calculate the high, low and mean levels.
C     6th Nov 1991.   HME / UoE, Starlink. Take care of HIGH=LOW. Increase plot
C                     range by 5% on either side.
C     4th  Sep 1992.  HME / UoE, Starlink. Change INCLUDE.
C                     PGASK is banned from ADAM, commented out.
C                     Check status after data access complete.
C     25th Jan 1993.  HME / UoE, Starlink.  Put PGASK back in.
C     27th Jul 1993.  HME / UoE, Starlink.  Disuse GKD_* except
C                     GKD_WRITE_LINE. Disuse PAR_Q*. Add parameter
C                     YVALUE.
C+
      IMPLICIT NONE
C
C     Functions
C
      LOGICAL   PAR_ABORT
      INTEGER   DYN_ELEMENT
      INTEGER   DYN_INCREMENT
      INTEGER   DSA_TYPESIZE
      INTEGER   PGBEGIN      
      CHARACTER ICH_CI*13,ICH_CF*13
 
C
      INTEGER   ADDRESS            ! Virtual address for data array
      CHARACTER COMMAND            ! Command character from cursor 
      CHARACTER DEVICE*32          ! PGPLOT device specification
      INTEGER   DIMS(2)            ! Image dimensions
      INTEGER   DSTATUS            ! Status on getting SOFT device
      INTEGER   DUMMY              ! Dummy argument
      INTEGER   EPTR1              ! Dynamic memory element for spectrum errors
      INTEGER   EPTR               ! Dynamic memory element for current scan
      LOGICAL   EXIST              ! TRUE if errors exist in input file
      LOGICAL   FINISHED           ! TRUE if finished
      REAL      HIGH               ! Highest data value
      INTEGER   IGNORE             ! Ignoreable status
      INTEGER   IXS                ! Initial pixel number
      INTEGER   IXE                ! Final pixel number
      REAL      LOW                ! Lowest data value
      REAL      MEAN               ! Mean data value
      INTEGER   NDIM               ! Number of image dimensions
      INTEGER   NELM               ! Number of elements in image - ignored
      INTEGER   NUM                ! Number of good data points
      INTEGER   NX                 ! First dimension of image
      INTEGER   NY                 ! Second dimension of image
      INTEGER   OPTR1              ! Dynamic memory element for image data
      INTEGER   OPTR               ! Dynamic memory element for current scan
      CHARACTER PLAB*40            ! Plot label
      INTEGER   SCAN               ! Scan number
      INTEGER   SLOT1              ! Slot number for mapped data - ignored
      INTEGER   SLOT2              ! Slot number for mapped data - ignored
      INTEGER   SLOT3              ! Slot number for mapped data - ignored
      INTEGER   SLOT4              ! Slot number for mapped data - ignored
      INTEGER   STATUS             ! Running status for DSA routines
      CHARACTER STRINGS(2)*64      ! Receives axis information
      INTEGER   QPTR1              ! Output quality pointer for image
      INTEGER   QPTR               ! Output quality pointer for current scan
      LOGICAL   WHOLE              ! TRUE to plot whole of spectrum
      REAL      XEN                ! Final X-value
      CHARACTER XLAB*64            ! X-axis label for plot
      CHARACTER XLABEL*32          ! Structure X-axis label
      INTEGER   XPTR               ! Dynamic memory element for X axis data
      REAL      XST                ! Initial X-value
      CHARACTER XUNITS*32          ! Structure X-axis units
      REAL      YVAL               ! Y value (Scan number) to plot        
C
C     Dynamic memory common - defines DYNAMIC_MEM
C
      INCLUDE 'DYNAMIC_MEMORY'
C     
C     Initial values
C
      STATUS=0
C
C     Open DSA routines
C
      CALL DSA_OPEN(STATUS)
      IF (STATUS.NE.0) GOTO 500
C
C     Open IMAGE file
C
      CALL DSA_INPUT ('IMAGE','IMAGE',STATUS)
      IF (STATUS.NE.0) GOTO 500
C
C     Get size of data in IMAGE
C
      CALL DSA_DATA_SIZE ('IMAGE',2,NDIM,DIMS,NELM,STATUS)
      NX=DIMS(1)
      NY=DIMS(2)
C
C     Find out about errors
C
      CALL DSA_SEEK_ERRORS ('IMAGE',EXIST,STATUS)
C
C     Create output file.
C
      CALL DSA_OUTPUT ('OUTPUT','OUTPUT','IMAGE',0,1,STATUS)
      IF (STATUS.NE.0) GOTO 500
      CALL DSA_USE_QUALITY('OUTPUT',STATUS)
C
C     Get range
C
      CALL PAR_RDKEY('WHOLE',.TRUE.,WHOLE)
      IF (PAR_ABORT()) GOTO 500
      CALL DSA_AXIS_RANGE('OUTPUT',1,' ',WHOLE,XST,XEN,IXS,IXE,STATUS)
      IF (STATUS.NE.0) GOTO 500
C
C     Get X-axis label
C
      CALL DSA_GET_AXIS_INFO('OUTPUT',1,2,STRINGS,0,DUMMY,STATUS)
      XUNITS=STRINGS(1)
      XLABEL=STRINGS(2)
      CALL FIG_MAKE_AXIS_LABEL(XLABEL,XUNITS,XLAB)
C
C     Map the output data
C
      CALL DSA_MAP_DATA ('OUTPUT','UPDATE','FLOAT',ADDRESS,SLOT1,
     :                                                          STATUS)
      OPTR1=DYN_ELEMENT(ADDRESS)
C
C     If input had errors use them, else use a zeroed work array
C
      IF (EXIST) THEN
         CALL DSA_MAP_ERRORS('OUTPUT','UPDATE','FLOAT',ADDRESS,SLOT2,
     :                                                          STATUS)
         EPTR1=DYN_ELEMENT(ADDRESS)
      ELSE 
         CALL DSA_GET_WORK_ARRAY(NELM,'FLOAT',ADDRESS,SLOT2,STATUS)
         EPTR1=DYN_ELEMENT(ADDRESS)
         CALL GEN_FILL(NELM*DSA_TYPESIZE('FLOAT',STATUS),0,
     :                                          DYNAMIC_MEM(EPTR1))
      END IF
C
      CALL DSA_MAP_QUALITY ('OUTPUT','UPDATE','BYTE',ADDRESS,SLOT3,
     :                                                          STATUS)
      QPTR1=DYN_ELEMENT(ADDRESS)
      CALL DSA_MAP_AXIS_DATA('OUTPUT',1,'READ','FLOAT',ADDRESS,
     :    SLOT4,STATUS)
      XPTR=DYN_ELEMENT(ADDRESS)
C
C     Check status.
C
      IF (STATUS.NE.0) GO TO 500
C
C     Look for the value of the user variable 'SOFT'
C
      CALL VAR_GETCHR('SOFT',0,0,DEVICE,DSTATUS)
      IF (DSTATUS.NE.0) THEN
         CALL PAR_WRUSER('No plotting device specified.',IGNORE)
         CALL PAR_WRUSER(
     :     'Use "SOFT" command eg "SOFT /VT" to rectify.',IGNORE)
         GOTO 500
      END IF
C
C     Initialize for plotting
C
      SCAN=1
      STATUS=PGBEGIN(0,DEVICE,1,1)
      IF (STATUS .NE. 1) THEN
          CALL PAR_WRUSER('Unable to open graphics device',IGNORE)
          GOTO 500
      ELSE
          STATUS=0
      ENDIF
      CALL PGASK(.FALSE.)
C 
C     Initialize GKD package
C
C
C     Main loop
C
      FINISHED = .FALSE.
      DO WHILE (.NOT. FINISHED)
C
C     Set pointers to appropriate scan
C
         OPTR = DYN_INCREMENT(OPTR1,'FLOAT',(SCAN-1)*NX)
         EPTR = DYN_INCREMENT(EPTR1,'FLOAT',(SCAN-1)*NX)
         QPTR = DYN_INCREMENT(QPTR1,'BYTE',(SCAN-1)*NX)
C
C     Get Range
C
         CALL FIG_ISEDIT_RANGE(DYNAMIC_MEM(OPTR),DYNAMIC_MEM(EPTR),
     :      DYNAMIC_MEM(QPTR),IXS,IXE,HIGH,LOW,MEAN,NUM)
C
C     Do the plot
C     Take care of HIGH=LOW
C     Increase plot range slightly (5% on either side) so that HIGH/LOW
C     do not coincide with the box
C
         IF (NUM .EQ. 0) THEN
            PLAB = 'Y = '//ICH_CI(SCAN)//' No Data Points'
            HIGH = 1.0
            LOW = 0.0
         ELSE IF ( HIGH .EQ. LOW ) THEN
            PLAB = 'Y = '//ICH_CI(SCAN)//' MAX = MIN'
            HIGH = HIGH + .5
            LOW  = LOW  - .5
         ELSE
            PLAB = 'Y = '//ICH_CI(SCAN)//'MEAN = '//ICH_CF(MEAN)
            HIGH = 1.05 * HIGH - 0.05 * LOW
            LOW  = 0.947619 * LOW - 0.047619 * HIGH
         ENDIF
         CALL FIG_ISEDIT_PLOT(DYNAMIC_MEM(XPTR),DYNAMIC_MEM(OPTR),
     :     DYNAMIC_MEM(QPTR),DYNAMIC_MEM(EPTR),NX,IXS,IXE,
     :     HIGH,LOW,XLAB,' ',PLAB,
     :     .TRUE.,.TRUE.,1,1,XST,XEN,
     :     STATUS)
C
C     Output HELP information
C
      CALL FIG_ISEDIT_HELP
C
C     Put up cursor and handle commands
C
         CALL FIG_ISEDIT_CURS(DYNAMIC_MEM(XPTR),DYNAMIC_MEM(OPTR),
     :     DYNAMIC_MEM(QPTR),DYNAMIC_MEM(EPTR),NX,NY,IXS,IXE,HIGH,LOW,
     :     XST,XEN,FINISHED,SCAN,STATUS)
         IF (PAR_ABORT()) GO TO 100
      ENDDO
  100 CONTINUE
      CALL PGEND
C
C     Close down everything
C
  500 CONTINUE
      CALL DSA_CLOSE(STATUS)
C
      END


C+
      SUBROUTINE FIG_ISEDIT_PLOT(XVALS,ZVALS,QUALITY,ERRORS,NX,IXST,
     :               IXEN,HIGH,LOW,XLAB,ZLAB,PLAB,AXES,ERRUSE,
     :                              THICK,CKEY,XVST,XVEN,STATUS)
C
C     F I G _ I S E D I T _ P L O T
C
C     Plots an array (ZVALS) against another array (XVALS), with errors
C     as specified by an error array (ERRORS). It is assumed that these 
C     map element for element, and that the XVALS values represent the 
C     coordinates at the center of each 'bin', and are in ascending order.
C
C     Parameters -   (">" input, "<" output)
C
C     (>) XVALS    (Real array XVALS(NX) The abscissae
C                  for each point to be plotted.
C     (>) ZVALS    (Real array ZVALS(NX) The data to be plotted.
C     (>) QUALITY  (Byte array QUALITY(NX)) The data quality.
C     (>) ERRORS   (Real array ERRROS(NX)) The Y errors on the data.
C     (>) NX       (Integer) Number of elements in XVALS and ZVALS.
C     (>) IXST     (Integer) The first array element to be plotted.
C     (>) IXEN     (Integer) The last array element to be plotted.
C     (>) HIGH     (Real) The maximum value for the plot.
C     (>) LOW      (Real) The minimum value for the plot.
C     (>) XLAB     (Character) The X-label for the plot.
C     (>) ZLAB     (Character) The Z-label for the plot.
C     (>) PLAB     (Character) The label for the plot as a whole.
C     (>) AXES     (Logical) True if axes are to be plotted.
C     (>) ERRUSE   (Logical) True if ERRORS values are to be used.  If
C                  false, errors should be taken as zero.
C     (>) THICK    (Integer) The line thickness for the plot.  
C     (>) CKEY     (Integer) The GRPCKG code (0..7) for the colour
C                  of the plot.
C     (>) XVST     (Real) The actual x-start value for the plot.
C     (>) XVEN     (Real) The actual x-end value for the plot.
C     (<) STATUS   (Integer) Returns plot status.
C                  0 => OK, non zero => some error opening the plot.
C
C     Subroutines / functions used -
C
C     PGBOX      (  "      "    ) Draw the box for a plot.
C     PGPAGE     (  "      "    ) Clear screen or start new plot.
C     PGWINDOW   (  "      "    ) Set the world-coordinate window.
C     PGVSTAND   (  "      "    ) Set the standard viewport.
C     PGLABEL    (  "      "    ) Label a plot.
C     PGSCI      (  "      "    ) Set plot colour
C     PGSLW      (  "      "    ) Set line width
C     PAR_WRUSER (PAR_     "    ) Send a message to user.
C     ICH_LEN    (ICH_     "    ) Get length of string to trailing blanks
C
C     Note: the avoidance of PGENV predates the /APPEND feature of
C     PGPLOT, and was intended to give explicit control over whether
C     or not the screen was erased.
C                                       KS / CIT  14th June 1985
C     Modified:
C
C     11th Dec 1990    Based on FIG_XZEPLOT     JAB / JAC
C+
      IMPLICIT NONE
C
C     Parameters 
C
      LOGICAL AXES,ERRUSE
      INTEGER IXST,IXEN,NX,STATUS,THICK,CKEY
      REAL XVALS(NX),ZVALS(NX),ERRORS(NX),HIGH,LOW,XVST,XVEN
      BYTE QUALITY(NX)
      CHARACTER*(*) XLAB,ZLAB,PLAB
C
C     Functions
C
      INTEGER ICH_LEN,PGBEGIN
C
C     Colour for axes
C
      INTEGER WHITE
      PARAMETER (WHITE=1)
C
C     Local variables
C
      LOGICAL APPEND
      INTEGER I, LENGTH
      REAL XVAL1, XVAL2, YVAL1, YVAL2
      CHARACTER CHARS*64,TYPE*16
C
C       Setup plot environment, and plot data.
C
        CALL PGPAGE                                    
        CALL PGSCI(WHITE)                                 
        CALL PGSLW(THICK)                                 
        CALL PGVSTAND                                     
        CALL PGWINDOW(XVST,XVEN,LOW,HIGH)                 
        IF (AXES) THEN                                    
           CALL PGBOX('ABCNST',0.,0,'ABCNST',0.,0)        
           CALL PGLABEL(XLAB,ZLAB,PLAB)                   
        ELSE                                              
           CALL PGLABEL(' ',' ',PLAB)                     
        END IF                                            
        CALL PGSCI(CKEY)                                  
        DO I=IXST,IXEN                                    
           IF (QUALITY(I) .EQ. 0) THEN
              CALL FIG_ISEDIT_POINT(XVALS,ZVALS,ERRORS,NX,IXST,
     :                IXEN,I,ERRUSE)
           END IF
        END DO                     
        CALL PGSCI(WHITE)          
        CALL PGSLW(1)              
C
C      Close down plot
C
      END


      SUBROUTINE FIG_ISEDIT_POINT(XVALS,ZVALS,ERRORS,NX,IXST,IXEN,
     :     IX,ERRUSE)
C
C     F I G _ I S E D I T _ P O I N T
C
C     Plots one point of an error bar plot
C
C     Parameters -   (">" input, "<" output)
C
C     (>) XVALS    (Real array XVALS(NX) The abscissae
C                  for each point to be plotted.
C     (>) ZVALS    (Real array ZVALS(NX) The data to be plotted.
C     (>) ERRORS   (Real array ERRROS(NX)) The Y errors on the data.
C     (>) NX       (Integer) Number of elements in XVALS and ZVALS.
C     (>) IXST     (Integer) The first array element to be plotted.
C     (>) IXEN     (Integer) The last array element to be plotted.
C     (>) IX       (Integer) The point to plot.
C     (>) ERRUSE   (Logical) True if ERRORS values are to be used.  If
C                  false, errors should be taken as zero.

      INTEGER IXST,IXEN,IX
      REAL XVALS(NX),ZVALS(NX),ERRORS(NX) 
      LOGICAL ERRUSE

      REAL XVAL1,XVAL2,YVAL1,YVAL2,WIDTH

      IF (IXEN .NE. IXST) THEN
          WIDTH=(XVALS(IXEN)-XVALS(IXST))/(IXEN-IXST)
      ELSE
          WIDTH=XVALS(IXEN)-XVALS(IXST)
      ENDIF
      XVAL1=XVALS(IX)-WIDTH*0.5                   
      XVAL2=XVALS(IX)+WIDTH*0.5                   
      CALL PGERRX(1,XVAL1,XVAL2,ZVALS(IX),0.0)              
      IF (ERRUSE) THEN                                     
         YVAL1=ZVALS(IX)-ERRORS(IX)                          
         YVAL2=ZVALS(IX)+ERRORS(IX)                          
         CALL PGERRY(1,XVALS(IX),YVAL1,YVAL2,0.0)           
      END IF                      

      END                         



      SUBROUTINE FIG_ISEDIT_RANGE(A,E,Q,IST,NX,HIGH,LOW,MEAN,NUM)
      IMPLICIT NONE
      INTEGER IST,NX,NUM
      REAL A(NX),E(NX),HIGH,LOW,MEAN
      BYTE Q(NX)

      INTEGER IX

      HIGH=-1.7E38
      LOW = 1.7E38
      MEAN = 0.0
      NUM=0
      DO IX=IST,NX
          IF (Q(IX) .EQ. 0) THEN
              IF (A(IX)+E(IX) .GT. HIGH) HIGH=A(IX)+E(IX)
              IF (A(IX)-E(IX) .LT. LOW) LOW=A(IX)-E(IX)
              MEAN=MEAN+A(IX)
              NUM=NUM+1
          ENDIF
      ENDDO
      IF (NUM .GT. 0) THEN
          MEAN=MEAN/NUM
      ENDIF
      END
     
      SUBROUTINE FIG_ISEDIT_CURS(XVALS,ZVALS,QUALITY,ERRORS,NX,NY,
     :     IXST,IXEN,HIGH,LOW,XST,XEN,FINISHED,SCAN,STATUS)
C
C     F I G _ I S E D I T _ C U R S
C
C     Put up the cursor on the plot and handle commands received.
C
C     Parameters -   (">" input, "<" output)
C
C     (>) XVALS    (Real array XVALS(NX) The abscissae
C                  for each point.
C     (>) ZVALS    (Real array ZVALS(NX) The data plotted.
C     (>) QUALITY  (Byte array QUALITY(NX)) The data quality.
C     (>) ERRORS   (Real array ERRROS(NX)) The Y errors on the data.
C     (>) NX       (Integer) Number of elements in XVALS and ZVALS.
C     (>) NY       (Integer) Number of scans.
C     (>) IXST     (Integer) The first array element to be plotted.
C     (>) IXEN     (Integer) The last array element to be plotted.
C     (>) HIGH     (Real) The maximum value for the plot.
C     (>) LOW      (Real) The minimum value for the plot.
C     (>) XST      (Real) The Starting X value.
C     (>) XEN      (Real) The Ending X value.
C     (<) FINISHED (Logical) Return TRUE if finished.
C     (!) SCAN     (Integer) Scan number.
C     (!) STATUS   (Integer) Status value.
C
C     Modified:
C
C     5th Feb. 1991.   JMS / AAO. Added another interpolation option "J" - Now 
C                      interpolates between chosen X and Y points and Draws 
C                      green crosses at chosen points.
C
C+
      IMPLICIT NONE
      INTEGER NX,NY,IXST,IXEN,SCAN,STATUS
      REAL HIGH,LOW,XST,XEN,XVALS(NX),ZVALS(NX),ERRORS(NX)
      BYTE QUALITY(NX)
      LOGICAL FINISHED
C
C     Local variables
C
      REAL X,Y
      LOGICAL REPEAT
      CHARACTER CH
      REAL YVAL,DZX
      INTEGER IX,INVOKE,NEXT,CI1,CI2,IX1,IX2
      CHARACTER STRING*80
C
C     Functions
C
      LOGICAL PAR_ABORT
      INTEGER GEN_BSEARCH,ICH_ENCODE
      CHARACTER ICH_CI*13
C
C
C
      X=0.5*(XST+XEN)
      Y=0.5*(LOW+HIGH)
      REPEAT = .TRUE.
      DO WHILE (REPEAT)
          CALL PGCURSE(X,Y,CH)
          IF (CH .EQ. 'Q' .OR. CH .EQ. 'q') THEN
              REPEAT = .FALSE.
              FINISHED = .TRUE.
          ELSE IF (CH .EQ. 'Y' .OR. CH .EQ. 'y') THEN
              REPEAT = .FALSE.
              CALL PAR_CNPAR('YVALUE')
              CALL PAR_RDVAL('YVALUE',1.,FLOAT(NY),
     :           FLOAT(MIN(SCAN+1,NY)),' ',YVAL)
              IF (PAR_ABORT()) RETURN
              SCAN=NINT(YVAL) 
          ELSE IF (CH .EQ. 'R' .OR. CH .EQ. 'r') THEN
              REPEAT = .FALSE.
          ELSE IF (CH .EQ. 'S' .OR. CH .EQ. 's') THEN
C
C         Delete Scan
C
              CALL GKD_WRITE_LINE('Deleting Scan with Y = '//
     :              ICH_CI(SCAN))
              DO IX=1,NX
                  QUALITY(IX)=1
              ENDDO            
              CALL PGQCOL(CI1,CI2)
              IF (CI2 .GE. 3) THEN
                  CALL PGSCI(3)
                  DO IX=1,NX
                      CALL FIG_ISEDIT_POINT(XVALS,ZVALS,ERRORS,NX,IXST,
     :                 IXEN,IX,.TRUE.)
                  ENDDO
                  CALL PGSCI(1)
              ELSE IF (CI1 .LE. 0) THEN
                  DO IX=1,NX
                     CALL PGSCI(0)
                     CALL FIG_ISEDIT_POINT(XVALS,ZVALS,ERRORS,NX,IXST,
     :                 IXEN,IX,.TRUE.)
                     CALL PGSLS(4)
                     CALL PGSCI(1)
                     CALL FIG_ISEDIT_POINT(XVALS,ZVALS,ERRORS,NX,IXST,
     :                 IXEN,IX,.TRUE.)
                     CALL PGSLS(1)
                  ENDDO
              ENDIF
          ELSE IF (CH .EQ. 'I' .OR. CH .EQ. 'i') THEN
C
C         Interpolate between two data points
C
              IX1 = MAX(1,MIN(NX,GEN_BSEARCH(XVALS,NX,X)))
              IF (QUALITY(IX1) .NE. 0) THEN
                 CALL GKD_WRITE_LINE('This point is already deleted')
              ELSE
                 CALL GKD_WRITE_LINE('Indicate Second Point'
     :                 //' and Hit any Key')
                 CALL PGCURSE(X,Y,CH)
                 IX2 = MAX(1,MIN(NX,GEN_BSEARCH(XVALS,NX,X)))
                 IF (QUALITY(IX2) .NE. 0) THEN
                    CALL GKD_WRITE_LINE('This point is already deleted')
                 ELSE
                    IF (IX2.LT.IX1) THEN
                       IX=IX1
                       IX1=IX2
                       IX2=IX
                    ENDIF
                    DZX=(ZVALS(IX2)-ZVALS(IX1))/(XVALS(IX2)-XVALS(IX1))
                    DO IX=IX1,IX2
                       CALL PGQCOL(CI1,CI2)
                       IF (CI1 .LE. 0) THEN
                           CALL PGSCI(0)
                           CALL FIG_ISEDIT_POINT(XVALS,ZVALS,ERRORS,NX,
     :                        IXST,IXEN,IX,.TRUE.)
                          CALL PGSCI(1)
                       ENDIF
                       ZVALS(IX)=ZVALS(IX1)+(XVALS(IX)-XVALS(IX1))*DZX
                       QUALITY(IX)=0
                       CALL FIG_ISEDIT_POINT(XVALS,ZVALS,ERRORS,NX,
     :                       IXST,IXEN,IX,.TRUE.)
                    ENDDO
                 ENDIF
              ENDIF
          ELSE IF (CH .EQ. 'J' .OR. CH .EQ. 'j') THEN
C
C         Interpolate between two indicated points
C
              IX1 = MAX(1,MIN(NX,GEN_BSEARCH(XVALS,NX,X)))
              ZVALS(IX1)=Y
              IF (QUALITY(IX1) .NE. 0) THEN
                 CALL GKD_WRITE_LINE('This point is already deleted')
              ELSE
C
C         Draw green cross at selected point
C
                 CALL PGQCOL(CI1,CI2)
                 IF (CI2 .GE. 3) THEN
                    CALL PGSCI(3)
                    CALL PGPOINT(1,X,Y,2)
                    CALL PGSCI(1)
                 END IF
C
                 CALL GKD_WRITE_LINE('Indicate Second Point'
     :                 //' and Hit any Key')
                 CALL PGCURSE(X,Y,CH)
                 IX2 = MAX(1,MIN(NX,GEN_BSEARCH(XVALS,NX,X)))
                 ZVALS(IX2)=Y
                 IF (QUALITY(IX2) .NE. 0) THEN
                    CALL GKD_WRITE_LINE('This point is already deleted')
                 ELSE
C
C         Draw green cross at selected point 
C
                    CALL PGQCOL(CI1,CI2)
                    IF (CI2 .GE. 3) THEN
                       CALL PGSCI(3)
                       CALL PGPOINT(1,X,Y,2)
                       CALL PGSCI(1)
                    END IF
C
                    IF (IX2 .LT. IX1) THEN 
                       IX=IX1
                       IX1=IX2
                       IX2=IX
                    ENDIF
                    DZX=(ZVALS(IX2)-ZVALS(IX1))/(XVALS(IX2)-XVALS(IX1))
                    DO IX=IX1,IX2
                       CALL PGQCOL(CI1,CI2)
                       IF (CI1 .LE. 0) THEN
                           CALL PGSCI(0)
                           CALL FIG_ISEDIT_POINT(XVALS,ZVALS,ERRORS,NX,
     :                        IXST,IXEN,IX,.TRUE.)
                          CALL PGSCI(1)
                       ENDIF
                       ZVALS(IX)=ZVALS(IX1)+(XVALS(IX)-XVALS(IX1))*DZX
                       QUALITY(IX)=0
                       CALL FIG_ISEDIT_POINT(XVALS,ZVALS,ERRORS,NX,
     :                       IXST,IXEN,IX,.TRUE.)
                    ENDDO
                 ENDIF
              ENDIF
          ELSE IF (CH .EQ. 'D' .OR. CH .EQ. 'd') THEN
C
C         Delete Point
C
              IX = MAX(1,MIN(NX,GEN_BSEARCH(XVALS,NX,X)))
              IF (QUALITY(IX) .NE. 0) THEN
                  CALL GKD_WRITE_LINE('This point is already deleted')
              ELSE
                  STRING = 'Deleting Point at X ='
                  INVOKE = ICH_ENCODE(STRING,XVALS(IX),22,8,NEXT)
                  STRING(NEXT:)=', Value = '
                  INVOKE = ICH_ENCODE(STRING,ZVALS(IX),NEXT+11,8,NEXT)
                  CALL GKD_WRITE_LINE(STRING(:NEXT-1))
C
C         Remove it from data by setting quality bad
C
                  QUALITY(IX)= 1
C
C         Mark deleted point on plot by setting colour to green
C         or by a dashed line 
C
                  CALL PGQCOL(CI1,CI2)
                  IF (CI2 .GE. 3) THEN
                     CALL PGSCI(3)
                     CALL FIG_ISEDIT_POINT(XVALS,ZVALS,ERRORS,NX,IXST,
     :                   IXEN,IX,.TRUE.)
                     CALL PGSCI(1)
                  ELSE IF (CI1 .LE. 0) THEN
                     CALL PGSCI(0)
                     CALL FIG_ISEDIT_POINT(XVALS,ZVALS,ERRORS,NX,IXST,
     :                   IXEN,IX,.TRUE.)
                     CALL PGSLS(4)
                     CALL PGSCI(1)
                     CALL FIG_ISEDIT_POINT(XVALS,ZVALS,ERRORS,NX,IXST,
     :                   IXEN,IX,.TRUE.)
                     CALL PGSLS(1)
                  ENDIF
              ENDIF
          ELSE IF (CH .EQ. 'M' .OR. CH .EQ. 'm') THEN
C
C         Move Point
C
              IX = MAX(1,MIN(NX,GEN_BSEARCH(XVALS,NX,X)))
              IF (QUALITY(IX) .NE. 0) THEN
                  CALL GKD_WRITE_LINE('This point is already deleted')
              ELSE
                  STRING = 'Moving Point at X ='
                  INVOKE = ICH_ENCODE(STRING,XVALS(IX),22,8,NEXT)
                  STRING(NEXT:)=' to Value = '
                  INVOKE = ICH_ENCODE(STRING,Y,NEXT+11,8,NEXT)
                  CALL GKD_WRITE_LINE(STRING(:NEXT-1))
C
C         Delete point on plot
C
                  CALL PGQCOL(CI1,CI2)
                  IF (CI1 .LE. 0) THEN
                     CALL PGSCI(0)
                     CALL FIG_ISEDIT_POINT(XVALS,ZVALS,ERRORS,NX,IXST,
     :                   IXEN,IX,.TRUE.)
                     CALL PGSCI(1)
                  ENDIF
C
C         Change data
C
                  ZVALS(IX)= Y
C
C         Redraw point at new position
C
                  CALL FIG_ISEDIT_POINT(XVALS,ZVALS,ERRORS,NX,IXST,
     :                   IXEN,IX,.TRUE.)
              ENDIF
          ELSE IF (CH .EQ. 'H' .OR. CH .EQ. 'h') THEN
C
C         Output help information
C
              CALL FIG_ISEDIT_HELP 
          ENDIF
      ENDDO
      END


      SUBROUTINE FIG_ISEDIT_HELP

      CALL GKD_WRITE_LINE('D - Delete Point')
      CALL GKD_WRITE_LINE('H - Type this list of commands')
      CALL GKD_WRITE_LINE('I - Interpolate Between Two Data Points')
      CALL GKD_WRITE_LINE('J - Interpolate Between Two Indicated '//
     :                    'Points')
      CALL GKD_WRITE_LINE('M - Move Point')
      CALL GKD_WRITE_LINE('R - Redraw Plot')
      CALL GKD_WRITE_LINE('S - Delete This Scan')
      CALL GKD_WRITE_LINE('Q - Quit')
      CALL GKD_WRITE_LINE('Y - Plot a different Y value')

      END
