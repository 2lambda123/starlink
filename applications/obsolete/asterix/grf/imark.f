*+  IMARK - marks points on image (current or from list)
      SUBROUTINE IMARK(STATUS)
*    Description :
*    Deficiencies :
*    Bugs :
*    Authors :
*     BHVAD::RJV
*    History :
*       1 Oct 90: V1.2-2 option to mark current position
*                 V1.2-3 new SSO calls
*      18 Sep 91: V1.2-4 accepts text file (RJV)
*      19 Sep 91: V1.2-5 can set symbol and colour (RJV)
*       6 Feb 92: V1.2-5 individual HDS arrays for RA and DEC (RJV)
*      31 Jul 92: V1.2-7 NUMBER option added (DJA)
*      15 Sep 92: V1.2-8 Bug fixed when numbering ascii lists (DJA)
*       4 Oct 92: V1.2-9 " (DJA)
*      20 Jan 93: V1.7-0 Uses GCB to remember marks (RJV)
*       1 Jul 93: V1.7-1 GTR used (RJV)
*      16 Aug 93: V1.7-2 Error reporting for FIO corrected (DJA)
*       8 Aug 94: V1.7-3 Length of filename increased (RJV)
*       5 Sep 94: V1.7-4 OFF option added (RJV)
*       6 Sep 94: V1.7-5 numbering hived off to GFX routine (RJV)
*      10 Apr 95: V1.8-0 ALL option for internal list (RJV)
*      14 Nov 95: V2.0-0 Support for HEASARC database format (DJA)
*
*    Type definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'FIO_ERR'
      INCLUDE 'PAR_ERR'
      INCLUDE 'MATH_PAR'
*    Global variables :
      INCLUDE 'IMG_CMN'
*    Status :
      INTEGER STATUS
*    Function declarations :
*    Local constants :
*    Local variables :
      CHARACTER*(DAT__SZLOC) SLOC
      CHARACTER*(DAT__SZLOC) RLOC
      CHARACTER*(DAT__SZLOC) DLOC
      CHARACTER*132 FILENAME
      CHARACTER*80 REC,RAS*20,DECS*20
      DOUBLE PRECISION RA,DEC,CEL(2),CEL1950(2)
      REAL SIZE
      INTEGER I
      INTEGER NSRC,NPOS
      INTEGER RAPTR,DECPTR
      INTEGER IFD,FSTAT
      INTEGER SYMBOL,COLOUR,BOLD
      INTEGER NMARK
      LOGICAL OK
      LOGICAL POK
      LOGICAL CURR
      LOGICAL ALL
      LOGICAL EXIST
      LOGICAL NUMBER
      LOGICAL OFF
      LOGICAL HDB
*    Version :
      CHARACTER*30 VERSION
      PARAMETER (VERSION = 'IMARK Version 2.0-0')
*-
      CALL USI_INIT()

      CALL MSG_PRNT(VERSION)

      IF (.NOT.I_OPEN) THEN
        CALL MSG_PRNT('AST_ERR: image processing system not active')
      ELSEIF (.NOT.I_DISP) THEN
        CALL MSG_PRNT('AST_ERR: no image being displayed')
      ELSE

*  see if OFF-mode
        CALL USI_GET0L('OFF',OFF,STATUS)

        IF (OFF.AND.STATUS.EQ.SAI__OK) THEN
          CALL GCB_CANI('MARKER_N',STATUS)
          CALL GCB_CANL('MARKER_NUMBER',STATUS)

        ELSE

*  get symbol, colour and size
          CALL USI_GET0I('SYMBOL',SYMBOL,STATUS)
          CALL USI_GET0I('COLOUR',COLOUR,STATUS)
          CALL USI_GET0R('SIZE',SIZE,STATUS)
          CALL USI_GET0I('BOLD',BOLD,STATUS)

*  mark positions in internal list?
          IF (I_NPOS.GT.0) THEN
            CALL USI_GET0L('ALL',ALL,STATUS)
          ELSE
            ALL =.FALSE.
          ENDIF

*  see if only current position to be marked
          IF (.NOT.ALL) THEN
            CALL USI_GET0L('CURR',CURR,STATUS)
          ELSE
            CURR=.FALSE.
          ENDIF

*      Number sources?
          IF ( .NOT. CURR ) THEN
            CALL USI_GET0L('NUMBER',NUMBER,STATUS)
          ELSE
            NUMBER = .FALSE.
          ENDIF
          CALL GCB_SETL('MARKER_NUMBER',NUMBER,STATUS)

*  ensure transformations correct
          CALL GTR_RESTORE(STATUS)
          CALL GCB_ATTACH('IMAGE',STATUS)
          CALL IMG_2DGCB(STATUS)

          IF (CURR) THEN

            CALL GCB_GETI('MARKER_N',OK,NMARK,STATUS)
            IF (.NOT.OK) THEN
              NMARK=0
            ENDIF
            NMARK=NMARK+1
            CALL GCB_SETI('MARKER_N',NMARK,STATUS)
            CALL GCB_SET1I('MARKER_SYMBOL',NMARK,1,SYMBOL,STATUS)
            CALL GCB_SET1R('MARKER_X',NMARK,1,I_X,STATUS)
            CALL GCB_SET1R('MARKER_Y',NMARK,1,I_Y,STATUS)
            CALL GCB_SET1R('MARKER_SIZE',NMARK,1,SIZE,STATUS)
            CALL GCB_SET1I('MARKER_BOLD',NMARK,1,BOLD,STATUS)
            CALL GCB_SET1I('MARKER_COLOUR',NMARK,1,COLOUR,STATUS)

*  mark positions in current list
          ELSEIF (ALL) THEN

            DO I=1,I_NPOS

*  get each entry
              CALL GRP_GET(I_POS_ID,I,1,REC,STATUS)
*  split into ra and dec
              CALL CONV_SPLIT(REC,RAS,DECS,STATUS)
*  parse and save
              CALL CONV_RADEC(RAS,DECS,RA,DEC,STATUS)
              CALL IMARK_SAVE(1,RA,DEC,SYMBOL,COLOUR,SIZE,BOLD,STATUS)

            ENDDO

*  otherwise get list of positions from file
          ELSE

            CALL USI_GET0C('LIST',FILENAME,STATUS)
            IF (STATUS.EQ.SAI__OK) THEN
*  see if file exists in form given
              INQUIRE(FILE=FILENAME,EXIST=EXIST)
*  if it does - assume it to be text file
              IF (EXIST) THEN

*  Is it a HEASARC file?
                CALL USI_GET0L( 'HDB', HDB, STATUS )

                CALL FIO_OPEN(FILENAME,'READ','NONE',0,IFD,STATUS)
                DO WHILE ( STATUS .EQ. SAI__OK )
                  CALL FIO_READF(IFD,REC,STATUS)
                  IF (STATUS.EQ.SAI__OK) THEN
*  ignore blank lines
                    IF (REC.GT.' '.AND.REC(1:1).NE.'#') THEN

*  HEASARC format?
                      IF ( HDB ) THEN
                        READ( REC, '(F11.7,1X,F11.7)',IOSTAT=FSTAT )
     :                                          CEL1950(1),CEL1950(2)
                        IF ( FSTAT.NE. 0 ) THEN
                          STATUS = SAI__ERROR
                          CALL ERR_REP( ' ', 'Error reading HEASARC'/
     :                                    /' database file', STATUS )
                        ELSE

*              Convert to file system
                          CEL1950(1) = CEL1950(1) * MATH__DDTOR
                          CEL1950(2) = CEL1950(2) * MATH__DDTOR
                          CALL WCI_CNS2S( I_FK4SYS, CEL1950, I_SYSID,
     :                                    CEL, STATUS )
                          RA = CEL(1) * MATH__DRTOD
                          DEC = CEL(2) * MATH__DRTOD

                        END IF

                      ELSE
*  remove leading blanks
                        CALL CHR_LDBLK( REC )

*  split record into ra and dec
                        CALL CONV_SPLIT(REC,RAS,DECS,STATUS)
*  parse and save
                        CALL CONV_RADEC(RAS,DECS,RA,DEC,STATUS)
                      END IF
                      CALL IMARK_SAVE(1,RA,DEC,SYMBOL,COLOUR,SIZE,BOLD,
     :                                                           STATUS)
                    ENDIF
                  ENDIF
                ENDDO
                IF ( STATUS .EQ. FIO__EOF ) CALL ERR_ANNUL( STATUS )
                CALL FIO_CLOSE(IFD,STATUS)

*  otherwise assume HDS file in PSS format
              ELSE
                CALL HDS_OPEN( FILENAME,'READ',SLOC,STATUS )
                IF (STATUS.EQ.SAI__OK) THEN

*  check if sources
                  CALL SSO_INIT( STATUS )
                  CALL SSO_VALID( SLOC, POK, STATUS )
                  CALL SSO_GETNSRC( SLOC, NSRC, STATUS )
                  IF (.NOT. POK .OR.NSRC.EQ.0 ) THEN
                    CALL MSG_PRNT('AST_ERR: No sources in this SSDS')
                  ELSE
*  get RA DEC of sources
                    CALL SSO_MAPFLD( SLOC, 'RA', '_DOUBLE', 'READ',
     :                                        RAPTR, STATUS )
                    CALL SSO_MAPFLD( SLOC, 'DEC', '_DOUBLE', 'READ',
     :                                        DECPTR, STATUS )

*  save source positions
                    CALL IMARK_SAVE(NSRC,%VAL(RAPTR),%VAL(DECPTR),
     :                              SYMBOL,COLOUR,SIZE,BOLD,STATUS)

                  ENDIF

                  CALL SSO_RELEASE(SLOC,STATUS)
                  CALL HDS_CLOSE(SLOC,STATUS)

                ENDIF

              ENDIF

*  look for individual HDS arrays
            ELSEIF (STATUS.EQ.PAR__NULL) THEN
              CALL ERR_ANNUL(STATUS)
              CALL USI_DASSOC('RA','READ',RLOC,STATUS)
              CALL USI_DASSOC('DEC','READ',DLOC,STATUS)
              CALL DAT_SIZE(RLOC,NPOS,STATUS)
              CALL DYN_MAPD(1,NPOS,RAPTR,STATUS)
              CALL DYN_MAPD(1,NPOS,DECPTR,STATUS)
              CALL DAT_GET1D(RLOC,NPOS,%VAL(RAPTR),NPOS,STATUS)
              CALL DAT_GET1D(DLOC,NPOS,%VAL(DECPTR),NPOS,STATUS)
              CALL IMARK_SAVE(NPOS,%VAL(RAPTR),%VAL(DECPTR),
     :                        SYMBOL,COLOUR,SIZE,BOLD,STATUS)
              CALL DYN_UNMAP(RAPTR,STATUS)
              CALL DYN_UNMAP(DECPTR,STATUS)
              CALL DAT_ANNUL(RLOC,STATUS)
              CALL DAT_ANNUL(DLOC,STATUS)
            ENDIF

          ENDIF

          CALL GFX_MARKS(STATUS)

        ENDIF

      ENDIF

      CALL USI_CLOSE()

      END



      SUBROUTINE IMARK_SAVE(N,RA,DEC,SYMBOL,COLOUR,SIZE,BOLD,STATUS)

*    Type definitions :
      IMPLICIT NONE
      INTEGER N
      DOUBLE PRECISION RA(N),DEC(N)
      REAL SIZE
      INTEGER SYMBOL,COLOUR,BOLD

      INTEGER STATUS

      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'

      REAL X,Y,XP,YP
      INTEGER I,IX,IY
      INTEGER NMARK
      LOGICAL OK

      INCLUDE 'IMG_CMN'

      IF (STATUS.EQ.SAI__OK) THEN

        CALL GCB_GETI('MARKER_N',OK,NMARK,STATUS)
        IF (.NOT.OK) THEN
          NMARK=0
        ENDIF

        DO I=1,N


          CALL IMG_CELTOWORLD(RA(I),DEC(I),X,Y,STATUS)
          CALL IMG_WORLDTOPIX(X,Y,XP,YP,STATUS)
          IX=INT(XP+0.5)
          IY=INT(YP+0.5)

          IF (STATUS.EQ.SAI__OK) THEN
            IF (IX.GE.I_IX1.AND.IX.LE.I_IX2.AND.
     :          IY.GE.I_IY1.AND.IY.LE.I_IY2) THEN

              NMARK=NMARK+1
              CALL GCB_SETI('MARKER_N',NMARK,STATUS)
              CALL GCB_SET1I('MARKER_SYMBOL',NMARK,1,SYMBOL,STATUS)
              CALL GCB_SET1R('MARKER_X',NMARK,1,X,STATUS)
              CALL GCB_SET1R('MARKER_Y',NMARK,1,Y,STATUS)
              CALL GCB_SET1R('MARKER_SIZE',NMARK,1,SIZE,STATUS)
              CALL GCB_SET1I('MARKER_BOLD',NMARK,1,BOLD,STATUS)
              CALL GCB_SET1I('MARKER_COLOUR',NMARK,1,COLOUR,STATUS)


              I_X=X
              I_Y=Y

            ENDIF
          ENDIF


        ENDDO

      ENDIF

      END
