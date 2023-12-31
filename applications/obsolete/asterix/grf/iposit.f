*+  IPOSIT - set current position
      SUBROUTINE IPOSIT(STATUS)
*    Description :
*    Method :
*    Deficiencies :
*    Bugs :
*    Authors :
*    History :
*     22 Oct 90: V1.2-1 positions in various frames (RJV)
*      1 Jul 93: V1.2-2 GTR used (RJV)
*      7 Apr 95: V1.8-0 list entry and selection (RJV)
*     20 NOV 95: V2.0-0 GUI version (RJV)
*      2 May 96: V2.0-1 improved GUI version (RJV)
*      8 May 96: V2.0-2 MODE parameter (RJV)
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'PAR_ERR'
*    Import :
*    Import-Export :
*    Export :
*    Status :
      INTEGER STATUS
*    Functions :
*    Local Constants :
*    Local variables :
      CHARACTER*8 MODE
*    Global Variables :
      INCLUDE 'IMG_CMN'
*    Version :
      CHARACTER*30 VERSION
      PARAMETER (VERSION='IPOSIT Version 2.2-0')
*-
      CALL USI_INIT()

      CALL MSG_PRNT(VERSION)

      IF (.NOT.I_OPEN) THEN
        CALL MSG_PRNT('AST_ERR: image processing system not active')
      ELSEIF (.NOT.I_DISP) THEN
        CALL MSG_PRNT('AST_ERR: no image currently displayed')
      ELSE

*  get operating mode
        CALL USI_GET0C('MODE',MODE,STATUS)
        CALL CHR_UCASE(MODE)
        MODE=MODE(:3)

        IF (MODE.EQ.'POI') THEN
          CALL IPOSIT_POINT(STATUS)
        ELSEIF (MODE.EQ.'ENT') THEN
          CALL IPOSIT_ENTER(.FALSE.,STATUS)
        ELSEIF (MODE.EQ.'APP') THEN
          CALL IPOSIT_ENTER(.TRUE.,STATUS)
        ELSEIF (MODE.EQ.'SEL') THEN
          CALL IPOSIT_SELECT(STATUS)
        ELSEIF (MODE.EQ.'SHO') THEN
          CALL IPOSIT_SHOW(STATUS)
        ELSEIF (MODE.EQ.'SAV') THEN
          CALL IPOSIT_SAVE(STATUS)
        ELSEIF (MODE.EQ.'CLE') THEN
          CALL IPOSIT_CLEAR(STATUS)
        ENDIF


      ENDIF

      CALL USI_CLOSE()

      END


*+  IPOSIT_POINT - set current position to selected point
      SUBROUTINE IPOSIT_POINT(STATUS)
*    Description :
*    Method :
*    Deficiencies :
*    Bugs :
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'PAR_ERR'
*    Import :
*    Import-Export :
*    Export :
*    Status :
      INTEGER STATUS
*    Functions :
*    Local Constants :
*    Local variables :
      CHARACTER CH*1,OPT*8
      CHARACTER*20 SRA,SDEC
      DOUBLE PRECISION RA,DEC,ELON,ELAT,B,L
      REAL X,Y,XPIX,YPIX
      REAL XP1,XP2,YP1,YP2
      REAL XW1,XW2,YW1,YW2
      REAL XSCALE,YSCALE
      REAL XOLD,YOLD
      INTEGER FRAME
      INTEGER IXPMAX,IYPMAX
      INTEGER IXP,IYP
      INTEGER FLAG
      LOGICAL FOK
*    Global Variables :
      INCLUDE 'IMG_CMN'
*-
      IF (STATUS.EQ.SAI__OK) THEN

*  ensure transformations correct
        CALL GTR_RESTORE(STATUS)

*  running from GUI
        IF (I_GUI) THEN

*  get transformation info
          CALL IMG_NBGET0I('XPMAX',IXPMAX,STATUS)
          CALL IMG_NBGET0I('YPMAX',IYPMAX,STATUS)
          CALL PGQVP(3,XP1,XP2,YP1,YP2)
          CALL PGQWIN(XW1,XW2,YW1,YW2)
          XSCALE=(XW2-XW1)/(XP2-XP1)
          YSCALE=(YW2-YW1)/(YP2-YP1)
          XOLD=I_X
          YOLD=I_Y

*  form input, track or point
          CALL IMG_NBGET0C('OPTIONS',OPT,STATUS)
          IF (OPT(:4).EQ.'FORM') THEN
            I_FORM=.TRUE.
          ELSE
            I_FORM=.FALSE.
            IF (OPT(:5).EQ.'TRACK') THEN
              FLAG=1
*  wait for signal to start tracking
              DO WHILE (FLAG.NE.0)
                CALL IMG_NBGET0I('FLAG',FLAG,STATUS)
              ENDDO
*  track position until further signal received from GUI
              DO WHILE (FLAG.EQ.0)
                CALL IMG_NBGET0I('XP',IXP,STATUS)
                CALL IMG_NBGET0I('YP',IYP,STATUS)
                IYP=IYPMAX-IYP
                X=XW1+(REAL(IXP)-XP1)*XSCALE
                Y=YW1+(REAL(IYP)-YP1)*YSCALE
                CALL IMG_SETPOS(X,Y,STATUS)
                CALL IMG_NBGET0I('FLAG',FLAG,STATUS)
              ENDDO
              IF (FLAG.EQ.3) THEN
*  switched to form input
                I_FORM=.TRUE.
              ELSEIF (FLAG.NE.1) THEN
*  revert to previous position
                CALL IMG_SETPOS(XOLD,YOLD,STATUS)
              ENDIF
            ELSEIF (OPT(:5).EQ.'POINT') THEN
*  get position from GUI and convert to various frames
              CALL IMG_NBGET0I('XP',IXP,STATUS)
              CALL IMG_NBGET0I('YP',IYP,STATUS)
              IYP=IYPMAX-IYP
              X=XW1+(REAL(IXP)-XP1)*XSCALE
              Y=YW1+(REAL(IYP)-YP1)*YSCALE
              CALL IMG_SETPOS(X,Y,STATUS)
            ENDIF

          ENDIF

*  form input
          IF (I_FORM) THEN
            CALL IMG_FORMOK(FOK,STATUS)
            IF (FOK) THEN
              CALL IMG_NBGET0I('PAR_I1',FRAME,STATUS)
              IF (FRAME.EQ.1) THEN
                CALL IMG_NBGET0R('PAR_R1',X,STATUS)
                CALL IMG_NBGET0R('PAR_R2',Y,STATUS)

              ELSEIF (FRAME.EQ.2) THEN
                CALL IMG_NBGET0C('PAR_C1',SRA,STATUS)
                CALL IMG_NBGET0C('PAR_C2',SDEC,STATUS)
                CALL CONV_RADEC(SRA,SDEC,RA,DEC,STATUS)
                CALL IMG_CELTOWORLD(RA,DEC,X,Y,STATUS)

              ELSEIF (FRAME.EQ.3) THEN
                CALL IMG_NBGET0D('PAR_R1',ELON,STATUS)
                CALL IMG_NBGET0D('PAR_R2',ELAT,STATUS)
                CALL IMG_ECLTOWORLD(ELON,ELAT,X,Y,STATUS)

              ELSEIF (FRAME.EQ.4) THEN
                CALL IMG_NBGET0D('PAR_R1',L,STATUS)
                CALL IMG_NBGET0D('PAR_R2',B,STATUS)
                CALL IMG_GALTOWORLD(L,B,X,Y,STATUS)

              ENDIF

              CALL IMG_SETPOS(X,Y,STATUS)

            ENDIF
          ENDIF



*  command mode cursor input
        ELSEIF (I_MODE.EQ.1) THEN
          CALL MSG_PRNT(' ')
          CALL MSG_PRNT('Select position...')

          CALL PGCURSE(X,Y,CH)

          CALL IMG_SETPOS(X,Y,STATUS)

*  keyboard mode
        ELSE

*  get coordinate frame
          CALL USI_GET0I('FRAME',FRAME,STATUS)

          IF (FRAME.EQ.1) THEN
            CALL USI_GET0C('RA',SRA,STATUS)
            CALL USI_GET0C('DEC',SDEC,STATUS)
            CALL CONV_RADEC(SRA,SDEC,RA,DEC,STATUS)
            CALL IMG_CELTOWORLD(RA,DEC,X,Y,STATUS)

          ELSEIF (FRAME.EQ.2) THEN
            CALL USI_GET0D('ELON',ELON,STATUS)
            CALL USI_GET0D('ELAT',ELAT,STATUS)
            CALL IMG_ECLTOWORLD(ELON,ELAT,X,Y,STATUS)

          ELSEIF (FRAME.EQ.3) THEN
            CALL USI_GET0D('L',L,STATUS)
            CALL USI_GET0D('B',B,STATUS)
            CALL IMG_GALTOWORLD(L,B,X,Y,STATUS)

          ELSEIF (FRAME.EQ.4) THEN
            CALL USI_GET0R('X',X,STATUS)
            CALL USI_GET0R('Y',Y,STATUS)

          ELSEIF (FRAME.EQ.5) THEN
            CALL USI_GET0R('XPIX',XPIX,STATUS)
            CALL USI_GET0R('YPIX',YPIX,STATUS)
            CALL IMG_PIXTOWORLD(XPIX,YPIX,X,Y,STATUS)

          ENDIF

          CALL IMG_SETPOS(X,Y,STATUS)

        ENDIF


      ENDIF


      END



*+  IPOSIT_ENTER - enter a list of positions
      SUBROUTINE IPOSIT_ENTER(APPEND,STATUS)
*    Description :
*    Method :
*    Deficiencies :
*    Bugs :
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'PAR_ERR'
      INCLUDE 'FIO_ERR'
*    Import :
      LOGICAL APPEND
*    Import-Export :
*    Export :
*    Status :
      INTEGER STATUS
*    Functions :
      INTEGER CHR_LEN
*    Local Constants :
      DOUBLE PRECISION PI, DTOR
      PARAMETER (PI = 3.141592654D0, DTOR = PI/180.0D0)

*    Local variables :
      CHARACTER*132 TEXT
      CHARACTER*80 REC
      CHARACTER*20 RAS,DECS
      CHARACTER*1 LC
      DOUBLE PRECISION RA,DEC
      REAL X,Y
      INTEGER IFD
      INTEGER RAI,DECI
      INTEGER RAPTR,DECPTR
      INTEGER ISRC,NSRC
      INTEGER L,SFID
      INTEGER ROW,ROWS
      LOGICAL EXIST
      LOGICAL STL
      LOGICAL RADEC
      LOGICAL REPEAT
      LOGICAL MORE
      LOGICAL NULFLG
*    Global Variables :
      INCLUDE 'IMG_CMN'
*-
      IF (STATUS.EQ.SAI__OK) THEN



*  get group id for storing positions
        IF (I_NPOS.EQ.0) THEN
          CALL GRP_NEW('Source list',I_POS_ID,STATUS)
*  or append to or reset  existing one
        ELSE
          IF (.NOT.APPEND) THEN
            CALL GRP_SETSZ(I_POS_ID,0,STATUS)
            I_NPOS=0
          ENDIF
        ENDIF

*  get input
        CALL USI_GET0C('LIST',TEXT,STATUS)

        IF (STATUS.EQ.SAI__OK) THEN

*  see if direct RA/DEC entry
          CALL IPOSIT_PARSE(TEXT,RADEC,STATUS)

          IF (RADEC) THEN

            REPEAT=.TRUE.
            DO WHILE (REPEAT.AND.STATUS.EQ.SAI__OK)

*  check for continuation character
              L=CHR_LEN(TEXT)
              LC=TEXT(L:L)
              IF (LC.EQ.'~'.OR.LC.EQ.'-'.OR.LC.EQ.CHAR(92)) THEN
                REPEAT=.TRUE.
                L=CHR_LEN(TEXT(:L-1))
              ELSE
                REPEAT=.FALSE.
              ENDIF

*  split text into ra and dec
              CALL CONV_SPLIT(TEXT(:L),RAS,DECS,STATUS)
*  parse
              CALL CONV_RADEC(RAS,DECS,RA,DEC,STATUS)
*  and store
              CALL IMG_PUTPOS( RA, DEC, STATUS )

*  if first one then make current position
              IF (I_NPOS.EQ.1) THEN
                CALL IMG_CELTOWORLD(RA,DEC,X,Y,STATUS)
                CALL IMG_SETPOS(X,Y,STATUS)
              ENDIF

              IF (REPEAT) THEN
                CALL USI_CANCL('LIST',STATUS)
                CALL USI_GET0C('LIST',TEXT,STATUS)
              ENDIF

            ENDDO

*  otherwise should be a file
          ELSE

*  see if file exists in form given
            INQUIRE(FILE=TEXT,EXIST=EXIST)
*  if it does - assume it to be text file unless told it is Small Text List
            IF (EXIST) THEN

              CALL FIO_OPEN(TEXT,'READ','NONE',0,IFD,STATUS)

*  check if file is Small Text List
              CALL IMG_CHKSTL(IFD,STL,STATUS)


              IF (STL) THEN

                CALL FIO_CLOSE(IFD,STATUS)

                CALL CAT_TOPEN (TEXT, 'OLD', 'READ', IFD, STATUS)

                IF (STATUS.EQ.SAI__OK) THEN

*  find Ra/Dec
                  CALL CAT_TIDNT (IFD, 'RA', RAI, STATUS)
                  CALL CAT_TIDNT (IFD, 'DEC', DECI, STATUS)


                  CALL CAT_TROWS (IFD, ROWS, STATUS)

*
*  Process all the row in the list (or until an error occurs).


                  ROW = 1
                  MORE = .TRUE.

                  DO WHILE (MORE.AND.ROW.LE.ROWS)


                    CALL CAT_RGET (IFD, ROW, STATUS)
                    IF (STATUS .EQ. SAI__OK) THEN

*   Attempt to get the basic plotting attributes.

                      CALL CAT_EGT0D (RAI, RA, NULFLG, STATUS)
                      CALL CAT_EGT0D (DECI, DEC, NULFLG, STATUS)
                      RA=RA/DTOR
                      DEC=DEC/DTOR

*  and store
                      CALL IMG_PUTPOS( RA, DEC, STATUS )



                    ELSE
                      MORE=.FALSE.

                    ENDIF

                    ROW=ROW+1

                  ENDDO

*  close catalogue file
                  CALL CAT_TRLSE (IFD, STATUS)

                ENDIF


              ELSE

                DO WHILE ( STATUS .EQ. SAI__OK )
                  CALL FIO_READF(IFD,REC,STATUS)
                  IF (STATUS.EQ.SAI__OK) THEN
*  ignore blank lines
                    IF (REC.GT.' ') THEN
*  remove leading blanks
                      CALL CHR_LDBLK( REC )

*  split record into ra and dec
                      CALL CONV_SPLIT(REC,RAS,DECS,STATUS)
*  parse
                      CALL CONV_RADEC(RAS,DECS,RA,DEC,STATUS)

*  and store
                     CALL IMG_PUTPOS( RA, DEC, STATUS )

*  make the first one the current position
                      IF (I_NPOS.EQ.1) THEN
                        CALL IMG_CELTOWORLD(RA,DEC,X,Y,STATUS)
                        CALL IMG_SETPOS(X,Y,STATUS)
                      ENDIF

                    ENDIF
                  ENDIF
                ENDDO
                IF ( STATUS .EQ. FIO__EOF ) CALL ERR_ANNUL( STATUS )
                CALL FIO_CLOSE(IFD,STATUS)



              ENDIF


*  otherwise assume HDS file in PSS format
            ELSE

              CALL ADI_FOPEN( TEXT, 'SSDSset|SSDS', 'READ', SFID,
     :                        STATUS )
              IF (STATUS.EQ.SAI__OK) THEN

*  check if sources
                CALL ADI_CGET0I( SFID, 'NSRC', NSRC, STATUS )

                IF (NSRC.EQ.0 ) THEN
                  CALL MSG_PRNT('AST_ERR: No sources in this SSDS')
                ELSE
*  get RA DEC of sources
                  CALL SSI_MAPFLD( SFID, 'RA', '_DOUBLE', 'READ',
     :                                            RAPTR, STATUS )
                  CALL SSI_MAPFLD( SFID, 'DEC', '_DOUBLE', 'READ',
     :                                           DECPTR, STATUS )
                  DO ISRC=1,NSRC
*  get each position
                    CALL ARR_ELEM1D(RAPTR,NSRC,ISRC,RA,STATUS)
                    CALL ARR_ELEM1D(DECPTR,NSRC,ISRC,DEC,STATUS)

*  and store
                    CALL IMG_PUTPOS( RA, DEC, STATUS )

*  make the first one the current position
                    IF (I_NPOS.EQ.1) THEN
                      CALL IMG_CELTOWORLD(RA,DEC,X,Y,STATUS)
                      CALL IMG_SETPOS(X,Y,STATUS)
                    ENDIF

                  ENDDO

                ENDIF

                CALL SSI_RELEASE(SFID,STATUS)
                CALL ADI_FCLOSE(SFID,STATUS)

              ENDIF

            ENDIF

          ENDIF

        ENDIF

      ENDIF

      END




*+  IPOSIT_SELECT - select current position from list
      SUBROUTINE IPOSIT_SELECT(STATUS)
*    Description :
*    Method :
*    Deficiencies :
*    Bugs :
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'PAR_ERR'
*    Import :
*    Import-Export :
*    Export :
*    Status :
      INTEGER STATUS
*    Functions :
*    Local Constants :
*    Local variables :
      CHARACTER*80 REC
      CHARACTER*20 RAS,DECS
      DOUBLE PRECISION RA,DEC
      REAL X,Y
      INTEGER NUM
*    Global Variables :
      INCLUDE 'IMG_CMN'
*-
      IF (STATUS.EQ.SAI__OK) THEN

*  get number
        CALL USI_GET0I('NUM',NUM,STATUS)
        IF (NUM.LE.0.OR.NUM.GT.I_NPOS) THEN
          CALL MSG_PRNT('AST_ERR: invalid position number')

        ELSE

*  get entry from list
          CALL GRP_GET(I_POS_ID,NUM,1,REC,STATUS)
*  split record into ra and dec
          CALL CONV_SPLIT(REC,RAS,DECS,STATUS)
*  parse
          CALL CONV_RADEC(RAS,DECS,RA,DEC,STATUS)
*  and store as current position
          CALL IMG_CELTOWORLD(RA,DEC,X,Y,STATUS)
          CALL IMG_SETPOS(X,Y,STATUS)

        ENDIF

      ENDIF

      END



*+  IPOSIT_SHOW - list positions
      SUBROUTINE IPOSIT_SHOW(STATUS)
*    Description :
*    Method :
*    Deficiencies :
*    Bugs :
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
*    Import :
*    Import-Export :
*    Export :
*    Status :
      INTEGER STATUS
*    Functions :
*    Local Constants :
*    Local variables :
      CHARACTER*40 REC/' '/
      INTEGER IPOS
*    Global Variables :
      INCLUDE 'IMG_CMN'
*-
      IF (STATUS.EQ.SAI__OK) THEN

        CALL MSG_BLNK()
        DO IPOS=1,I_NPOS
          CALL GRP_GET(I_POS_ID,IPOS,1,REC(6:),STATUS)
          WRITE(REC(:3),'(I3)') IPOS
          CALL MSG_PRNT(REC)
        ENDDO
        CALL MSG_BLNK()

      ENDIF

      END





*+  IPOSIT_PARSE - decide whether string is likely candidate for RA/DEC
      SUBROUTINE IPOSIT_PARSE(TEXT,RADEC,STATUS)
*    Description :
*    Method :
*    Deficiencies :
*    Bugs :
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
*    Import :
      CHARACTER*(*) TEXT
*    Import-Export :
*    Export :
      LOGICAL RADEC
*    Status :
      INTEGER STATUS
*    Functions :
      INTEGER CHR_LEN
*    Local Constants :
*    Local variables :
      CHARACTER*1 C
      INTEGER L
      INTEGER NDIGIT,NDELIM,NDOT,NMINUS,NPLUS
      INTEGER I
*-
      IF (STATUS.EQ.SAI__OK) THEN

        L=CHR_LEN(TEXT)
        C=TEXT(L:L)
*  ignore continuation character
        IF (C.EQ.'~'.OR.C.EQ.'-'.OR.C.EQ.CHAR(92)) THEN
          L=L-1
        ENDIF

        NDIGIT=0
        NDELIM=0
        NDOT=0
        NMINUS=0
        NPLUS=0
        DO I=1,L
          C=TEXT(I:I)
          IF (C.GE.'0'.AND.C.LE.'9') THEN
            NDIGIT=NDIGIT+1
          ELSEIF (C.EQ.'.') THEN
            NDOT=NDOT+1
          ELSEIF (C.EQ.'-') THEN
            NMINUS=NMINUS+1
          ELSEIF (C.EQ.'+') THEN
            NPLUS=NPLUS+1
          ELSE
            IF (C.EQ.' '.OR.C.EQ.':'.OR.C.EQ.'h'.OR.C.EQ.'d'.OR.
     :                                  C.EQ.'m'.OR.C.EQ.'s') THEN
              NDELIM=NDELIM+1
            ENDIF
          ENDIF
        ENDDO

        RADEC=(NDIGIT.GE.4.AND.NDOT.LE.2.AND.NMINUS.LE.1.AND.
     :                       (NDIGIT+NDOT+NMINUS+NDELIM).EQ.L)

      ENDIF

      END





*+  IPOSIT_SAVE - save positions to file
      SUBROUTINE IPOSIT_SAVE(STATUS)
*    Description :
*    Method :
*    Deficiencies :
*    Bugs :
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
*    Import :
*    Import-Export :
*    Export :
*    Status :
      INTEGER STATUS
*    Functions :
*    Local Constants :
*    Local variables :
      CHARACTER FILE*132,REC*40,NUM*4,NAME*16,RA*12,DEC*12
      INTEGER IPOS
      INTEGER FID
*    Global Variables :
      INCLUDE 'IMG_CMN'
*-
      IF (STATUS.EQ.SAI__OK) THEN

        CALL USI_GET0C('FILE',FILE,STATUS)
        CALL FIO_OPEN(FILE,'APPEND','LIST',0,FID,STATUS)
        CALL FIO_RWIND(FID,STATUS)

        DO IPOS=1,I_NPOS
          REC=' '
          WRITE(NUM,'(I4)') IPOS
          NAME=NUM
          CALL GRP_GET(I_POS_ID,IPOS,1,REC,STATUS)
          CALL CONV_SPLIT(REC,RA,DEC,STATUS)
          REC=NAME//RA//DEC
          CALL FIO_WRITE(FID,REC,STATUS)
        ENDDO

        CALL FIO_CLOSE(FID,STATUS)

      ENDIF

      END



*+  IPOSIT_CLEAR
      SUBROUTINE IPOSIT_CLEAR(STATUS)
*    Description :
*    Method :
*    Deficiencies :
*    Bugs :
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
*    Import :
*    Import-Export :
*    Export :
*    Status :
      INTEGER STATUS
*    Functions :
*    Local Constants :
*    Local variables :
*    Global Variables :
      INCLUDE 'IMG_CMN'
*-
      IF (STATUS.EQ.SAI__OK) THEN

        IF (I_NPOS.GT.0) THEN
          CALL GRP_SETSZ(I_POS_ID,0,STATUS)
          I_NPOS=0
        ENDIF

      ENDIF

      END
