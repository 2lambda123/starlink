*+  CQUALITY - Manipulate quality values in circular areas
      SUBROUTINE CQUALITY( STATUS )
*
*    Description :
*
*     Allows manipulation of quality values within circular or cylindrical
*     regions specified by the user. The available options are:
*
*       IGNORE  - Set temporary bad quality bit
*       RESTORE - Unset temporary bad quality bit
*       SET     - Set quality to specified value
*       AND     - AND existing QUALITY with specified QUALITY value
*       OR      - OR existing QUALITY with specified QUALITY value
*       EOR     - EOR existing QUALITY with specified QUALITY value
*       NOT     - NOT existing QUALITY with specified QUALITY value
*
*    Environment Parameters :
*
*     IGNORE    - Set temp bad qual bit?                 (Logical(F), read)
*     RESTORE   - Unset temp bad qual bit?               (Logical(F), read)
*     SET       - Set quality to specified value?        (Logical(F), read)
*     AND       - AND qualiity with specified value?     (Logical(F), read)
*     OR        - OR qualiity with specified value?      (Logical(F), read)
*     EOR       - EOR qualiity with specified value?     (Logical(F), read)
*     NOT       - NOT existing qualiity value?           (Logical(F), read)
*     OVER      - Overwrite input file?                  (Logical(T), read)
*     QSEL      - Specify a quality value to alter?      (Logical(F), read)
*     INP       - Input file name.                       (Univ, read)
*     OUT       - Output filename                        (Univ, write)
*     QVAL      - Specified quality value                (Byte, read)
*     MODQUAL   - Quality value to modify                (Character, read)
*     QVAL      - Specified quality value                (Character, read)
*
*    Method :
*    Deficiencies :
*    Bugs :
*    Authors :
*
*     David J. Allan (BHVAD::DJA)
*
*    History :
*
*      9 May 91 : V1.4-0  Original. Copied from QUALITY - quality value
*                         changing done by QUALITY_<op> routines. (DJA)
*     19 Nov 92 : V1.7-0  Updated call to AXIS_VAL2PIX (DJA)
*     25 Feb 94 : V1.7-1  Use BIT_ routines to do bit manipulations (DJA)
*     24 Nov 94 : V1.8-0  Now use USI for user interface (DJA)
*      6 Dec 94 : V1.8-1  Use updated QUALITY routines (DJA)
*     21 Feb 95 : V1.8-2  Don't die if axes unrecognised (DJA)
*     13 Dec 1995 : V2.0-0 ADI port (DJA)
*
*    Type Definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
      INCLUDE 'ADI_PAR'
      INCLUDE 'QUAL_PAR'
*
*    Status :
*
      INTEGER STATUS
*
*    Function definitions :
*
      BYTE                   BIT_NOTUB
*
*    Local Constants :
*
      INTEGER                MX_PTS                 ! Max no. circular regions
        PARAMETER            ( MX_PTS = 200 )
*
*    Local variables :
*
      CHARACTER*8            MODQUAL                ! Quality to modify
      CHARACTER*8            QVAL                   ! Quality value
      CHARACTER*80           TEXT(5)                ! History text
      CHARACTER*40           UNITS                  ! Axis units

      REAL                   	XC(MX_PTS), YC(MX_PTS) 	! Circular centres
      REAL                   	RC(MX_PTS)             	! Circular radii

      INTEGER                	AORDER(ADI__MXDIM)     	!
      INTEGER                	TCPTR, CPTR            	! Pointer to dynamic
							! array
      INTEGER                	DIMS(ADI__MXDIM)       ! Length of each dimension
      INTEGER                FSTAT                  ! i/o status
      INTEGER                I                      ! Loop counters
      INTEGER			IFID			! Input dataset id
      INTEGER                INORDER(ADI__MXDIM)    ! Inverse of AORDER
      INTEGER                NCH                    ! Points changed
      INTEGER                NDIM                   ! Number of dimensions
      INTEGER                NELM                   ! Number of data points
      INTEGER                NFROM                  ! # selected points
      INTEGER                NRPTS, NXPTS, NYPTS    ! # values entered
      INTEGER			OFID			! Output dataset id
      INTEGER                	QPTR                   	! Pointer to mapped
							! QUALITY
      INTEGER                TDIMS(ADI__MXDIM)      	! Working dimensions
      INTEGER                TQPTR                  	! Temp quality array
      INTEGER                XPTR, YPTR             	! Spatial axis data

      BYTE                   BQVAL		    	! Quality value

      LOGICAL                MODESET                ! Mode selected
      LOGICAL                MOVE_AXES              ! Move axes?
      LOGICAL                NOTON                  ! Point on X,Y plane?
      LOGICAL                OK                     ! OK?
      LOGICAL                OVERWRITE              ! Overwrite input dataset
      LOGICAL                QSEL                   ! Select QUALITY
                                                    ! Value to modify?
      LOGICAL                Q_AND, Q_OR, Q_IGNORE  ! Quality modes
      LOGICAL                Q_RESTORE, Q_SET, Q_EOR, Q_NOT
*
*    Version id :
*
      CHARACTER*30           VERSION
        PARAMETER           (VERSION = 'CQUALITY Version 2.0-0')
*-

      CALL MSG_PRNT( VERSION )

*    Initialize
      CALL AST_INIT

      MODESET=.FALSE.

*    Obtain mode from user
      CALL USI_GET0L( 'SET', Q_SET, STATUS )
      MODESET = Q_SET
      IF (.NOT.MODESET) THEN
        CALL USI_GET0L( 'IGNORE', Q_IGNORE, STATUS )
        MODESET = Q_IGNORE
      END IF
      IF (.NOT.MODESET) THEN
        CALL USI_GET0L( 'RESTORE', Q_RESTORE, STATUS )
        MODESET = Q_RESTORE
      END IF
      IF (.NOT.MODESET) THEN
        CALL USI_GET0L( 'AND', Q_AND, STATUS )
        MODESET = Q_AND
      END IF
      IF (.NOT.MODESET) THEN
        CALL USI_GET0L( 'OR', Q_OR, STATUS )
        MODESET = Q_OR
      END IF
      IF (.NOT.MODESET) THEN
        CALL USI_GET0L( 'EOR', Q_EOR, STATUS )
        MODESET = Q_EOR
      END IF
      IF (.NOT.MODESET) THEN
        CALL USI_GET0L( 'NOT', Q_NOT, STATUS )
        MODESET = Q_NOT
      END IF

      IF ( Q_SET ) THEN
        CALL USI_GET0L( 'QSEL', QSEL, STATUS )
      END IF

*    Check status
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*    Check that a mode has been selected
      IF ( .NOT. MODESET ) THEN
        STATUS = SAI__ERROR
        CALL ERR_REP( ' ', 'No CQUALITY operation selected selected',
     :                STATUS )
        GOTO 99
      END IF

*    Overwrite?
      CALL USI_GET0L( 'OVER', OVERWRITE, STATUS )

*    Get input
      IF ( OVERWRITE ) THEN
        CALL USI_ASSOC( 'INP', 'BinDS', 'UPDATE', IFID, STATUS )
        OFID = IFID
      ELSE
        CALL USI_ASSOC( 'INP', 'BinDS', 'READ', IFID, STATUS )
        CALL USI_CREAT( 'INP', 'OUT', 'BinDS', OFID, STATUS )
      END IF
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Validate dataset
      CALL BDI_GETSHP( OFID, ADI__MXDIM, DIMS, NDIM, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Check axes
      CALL AXIS_TGETORD( OFID, 'XY', MOVE_AXES, AORDER, NDIM, TDIMS,
     :                   STATUS )
      IF ( STATUS .NE. SAI__OK ) THEN
        CALL ERR_ANNUL( STATUS )
        CALL MSG_PRNT( 'Axes are not recognisable as X and Y, '/
     :                 /'using axes 1 and 2' )
        AORDER(1) = 1
        AORDER(2) = 2
        MOVE_AXES = .FALSE.
        DO I = 1, NDIM
          TDIMS(I) = DIMS(I)
        END DO
        CALL AR7_PAD( NDIM, TDIMS, STATUS )

      ELSE IF ( (AORDER(1) .NE. 1) .AND. (AORDER(2).NE.2) ) THEN
        MOVE_AXES = .TRUE.

      END IF

*  Find length of array
      CALL ARR_SUMDIM( NDIM, DIMS, NELM )

*  Check QUALITY
      CALL BDI_CHK( OFID, 'Quality', OK, STATUS )
      IF ( .NOT. OK ) THEN
        IF ( Q_SET .OR. Q_IGNORE ) THEN
          CALL BDI_MAPUB( OFID, 'Quality', 'WRITE', QPTR, STATUS )
          CALL ARR_INIT1B( QUAL__GOOD, NELM, %VAL(QPTR), STATUS )
          CALL BDI_PUT0UB( OFID, 'QualityMask', QUAL__MASK, STATUS )
        ELSE
          STATUS = SAI__ERROR
          CALL ERR_REP( ' ', 'No input quality!', STATUS )
        END IF
      ELSE
        CALL BDI_MAPUB( OFID, 'Quality', 'UPDATE', QPTR, STATUS )
      END IF
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Adjust size of array to 7 D
      CALL AR7_PAD( NDIM, DIMS, STATUS )

*  Quality needing moved due to axis order?
      IF ( MOVE_AXES ) THEN
        CALL MSG_PRNT( 'Changing axis order to X,Y...' )
        CALL DYN_MAPB( NDIM, TDIMS, TQPTR, STATUS )
        CALL AR7_AXSWAP_B( DIMS, %VAL(QPTR), AORDER, TDIMS,
     :                                %VAL(TQPTR), STATUS )
      ELSE
        TQPTR = QPTR
      END IF
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Get axis units for message
      CALL BDI_AXGET0C( OFID, AORDER(1), 'Units', UNITS, STATUS )
      IF ( UNITS .GT. ' ' ) THEN
        CALL CHR_UCASE( UNITS )
        CALL MSG_SETC( 'UNIT', UNITS )
        CALL MSG_PRNT( 'Specify circular regions in ^UNIT' )
      END IF

*  Get centres and radii for positions
      CALL USI_GET1R( 'CX', MX_PTS, XC, NXPTS, STATUS )
      CALL USI_GET1R( 'CY', MX_PTS, YC, NYPTS, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99
      IF ( NXPTS .LT. 1 ) THEN
        STATUS = SAI__ERROR
        CALL ERR_REP( ' ', 'No X values supplied', STATUS )
      ELSE IF ( NXPTS .NE. NYPTS ) THEN
        STATUS = SAI__ERROR
        CALL ERR_REP( ' ', 'Numbers of X and Y values differ', STATUS )
      END IF
      CALL USI_GET1R( 'CR', MX_PTS, RC, NRPTS, STATUS )
      IF ( STATUS .EQ. SAI__OK ) THEN
        IF ( ( NRPTS .NE. 1 ) .AND. ( NRPTS .NE. NXPTS ) ) THEN
          STATUS = SAI__ERROR
          CALL ERR_REP( ' ', 'Numbers of radii must be 1 or same as'/
     :                             /' number of X,Y values', STATUS )
        ELSE IF ( ( NRPTS .EQ. 1 ) .AND. ( NXPTS .GT. 1 ) ) THEN
          CALL ARR_INIT1R( RC(1), NXPTS, RC, STATUS )
        END IF
      END IF
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Set up temporary array for flagging selections - initialised to selected
      CALL DYN_MAPL( 1, NELM, CPTR, STATUS )
      CALL DYN_MAPL( 1, NELM, TCPTR, STATUS )
      CALL ARR_INIT1L( .TRUE., NELM, %VAL(CPTR), STATUS )

*  Map two spatial axes
      CALL BDI_AXMAPR( OFID, AORDER(1), 'Data', 'READ', XPTR, STATUS )
      CALL BDI_AXMAPR( OFID, AORDER(2), 'Data', 'READ', YPTR, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Initialise local selection array
      CALL ARR_INIT1L( .FALSE., NELM, %VAL(TCPTR), STATUS )

*  For each area
      DO I = 1, NXPTS

*    Set elements of selection array
        CALL CQUALITY_CIRSEL( TDIMS, XC(I), YC(I), RC(I), %VAL(XPTR),
     :                       %VAL(YPTR), %VAL(TCPTR), NOTON, STATUS )
        IF ( NOTON ) THEN
          CALL MSG_SETI( 'N', I )
          CALL MSG_PRNT( 'Point ^N is not within the bounds'/
     :                                   /' of the dataset' )
        END IF
      END DO
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Combine local with global selection
      CALL QUALITY_ANDSEL( NELM, %VAL(TCPTR), %VAL(CPTR), STATUS )

*  Selecting on value?
      IF ( QSEL ) THEN

*    Get quality value to modify
        CALL QUALITY_GETQV( 'MODQUAL', ' ', MODQUAL, BQVAL, STATUS )
        CALL QUALITY_SETQSEL( NELM, BQVAL, %VAL(TQPTR), %VAL(TCPTR),
     :                                                      STATUS )

*    Combine local with global selection
        CALL QUALITY_ANDSEL( NELM, %VAL(TCPTR), %VAL(CPTR), STATUS )

      END IF
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Write the output quality
      IF ( Q_SET ) THEN
        CALL QUALITY_GETQV( 'QVAL', 'New quality value', QVAL,
     :                                         BQVAL, STATUS )
        TEXT(1) = '     QUALITY set to '//QVAL
        CALL QUALITY_SET( NELM, BQVAL, %VAL(CPTR), %VAL(TQPTR), NCH,
     :                                                      STATUS )

      ELSE IF ( Q_IGNORE ) THEN
        BQVAL = QUAL__IGNORE
        CALL QUALITY_OR( NELM, BQVAL, %VAL(CPTR), %VAL(TQPTR), NCH,
     :                                                     STATUS )
        TEXT(1) = '     IGNORE mode'

      ELSE IF ( Q_RESTORE ) THEN
        BQVAL = BIT_NOTUB( QUAL__IGNORE )
        CALL QUALITY_AND( NELM, BQVAL, %VAL(CPTR), %VAL(TQPTR), NCH,
     :                                                      STATUS )
        TEXT(1) = '     RESTORE mode'

      ELSE IF ( Q_AND ) THEN
        CALL QUALITY_GETQV( 'QVAL', 'Value for AND operation', QVAL,
     :                                               BQVAL, STATUS )
        CALL QUALITY_AND( NELM, BQVAL, %VAL(CPTR), %VAL(TQPTR), NCH,
     :                                                       STATUS )
        TEXT(1) = '     QUALITY ANDed with '//QVAL

      ELSE IF ( Q_OR ) THEN
        CALL QUALITY_GETQV( 'QVAL', 'Value for OR operation', QVAL,
     :                                              BQVAL, STATUS )
        CALL QUALITY_OR( NELM, BQVAL, %VAL(CPTR), %VAL(TQPTR), NCH,
     :                                                     STATUS )
        TEXT(1) = '     QUALITY ORed with '//QVAL

      ELSE IF ( Q_EOR ) THEN
        CALL QUALITY_GETQV( 'QVAL', 'Value for EOR operation', QVAL,
     :                                               BQVAL, STATUS )
        CALL QUALITY_EOR( NELM, BQVAL, %VAL(CPTR), %VAL(TQPTR), NCH,
     :                                                      STATUS )
        TEXT(1) = '     QUALITY EORed with '//QVAL

      ELSE IF ( Q_NOT ) THEN
        CALL QUALITY_NOT( NELM, %VAL(CPTR), %VAL(TQPTR), NCH, STATUS )
        TEXT(1) = '     QUALITY complemented'

      END IF
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Unmap quality, restoring axes if necessary
      IF ( MOVE_AXES ) THEN
        CALL MSG_PRNT( 'Restoring axis order...' )
        CALL AXIS_ORDINV( NDIM, AORDER, INORDER )
        CALL AR7_AXSWAP_B( TDIMS, %VAL(TQPTR), INORDER, DIMS,
     :                                   %VAL(QPTR), STATUS )
        CALL DYN_UNMAP( TQPTR, STATUS )
      END IF
      CALL BDI_UNMAP( OFID, 'Quality', %VAL(QPTR), STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Count points selected
      CALL QUALITY_CNTSEL( NELM, %VAL(CPTR), NFROM, STATUS )

*  Inform user of altered points
      CALL MSG_SETI( 'NFROM', NFROM )
      CALL MSG_PRNT( '^NFROM points had quality modified' )

*  Write history
      CALL HSI_ADD( OFID, VERSION, STATUS )
      IF ( QSEL ) THEN
        TEXT(2) = ' Only points having QUALITY = '//MODQUAL//' altered'
      END IF

 80   FORMAT( A,<NXPTS>(E10.4) )
      WRITE( TEXT(3), 80, IOSTAT=FSTAT ) 'X-pos : ',(XC(I),I=1,NXPTS)
      WRITE( TEXT(4), 80, IOSTAT=FSTAT ) 'Y-pos : ',(YC(I),I=1,NXPTS)
      WRITE( TEXT(5), 80, IOSTAT=FSTAT ) 'Radii : ',(RC(I),I=1,NRPTS)

*  Write history
      CALL HSI_PTXT( OFID, 5, TEXT, STATUS )

*  Exit
 99   CALL AST_CLOSE()
      CALL AST_ERR( STATUS )

      END



*+  CQUALITY_CIRSEL - Use circular ranges to select valid output pixels
      SUBROUTINE CQUALITY_CIRSEL( DIMS, XC, YC, RC, XAX, YAX, SEL,
     :                                             NOTON, STATUS )
*    Description :
*    History :
*    Type definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
*
*    Import :
*
      INTEGER                DIMS(*)            ! DATA_ARRAY dimensions
      REAL                   XC,YC,RC           ! Circle centre and radius
      REAL                   XAX(*), YAX(*)     ! Spatial axes
*
*    Export :
*
      LOGICAL                SEL(*)             ! Selection array
      LOGICAL                NOTON              ! Point in plane?
*
*    Status :
*
      INTEGER STATUS
*-
      IF (STATUS.NE.SAI__OK) RETURN

      CALL CQUALITY_CIRSEL_INT(DIMS(1),DIMS(2),DIMS(3),DIMS(4),DIMS(5),
     :                         DIMS(6),DIMS(7), XC, YC, RC, XAX, YAX,
     :                                       SEL, NOTON, STATUS )

      END



*+  CQUALITY_CIRSEL_INT - Use circular ranges to select valid output pixels
      SUBROUTINE CQUALITY_CIRSEL_INT( D1,D2,D3,D4,D5,D6,D7, XC, YC,
     :                     RC, XAX, YAX, SEL, NOTON, STATUS )
*    Description :
*     Loops over input data array setting SELECT = .TRUE. if values lie
*     within circular region
*    History :
*    Type definitions :
*
      IMPLICIT NONE
*
*    Status :
*
      INTEGER STATUS
*
*    Import :
*
      INTEGER                D1,D2,D3,D4,D5,D6,D7 ! DATA_ARRAY dimensions
      REAL                   XC,YC,RC             ! Circle centre and radius
      REAL                   XAX(D1), YAX(D2)     ! Spatial axes
*
*    Export :
*
      LOGICAL                SEL(D1,D2,D3,D4,D5,D6,D7)
      LOGICAL                NOTON                ! Point in plane?
*
*    Local variables :
*
      REAL                   R2, R2Y, RC2, XDIR, YDIR
      REAL                   XD, YD                 !

      INTEGER                A,B,C,D,E,X,Y          ! Loop counters
      INTEGER                XLO, XHI               ! X axis bounds
      INTEGER                YLO, YHI               ! Y axis bounds

*-

*    Find greatest extent of circle in plane
      XDIR = SIGN( 1.0, XAX(2)-XAX(1) )
      YDIR = SIGN( 1.0, YAX(2)-YAX(1) )
      NOTON = .TRUE.
      XD = ( XC - (XAX(1)-XDIR*RC) ) /
     :                    ((XAX(D1)+XDIR*RC)-(XAX(1)-XDIR*RC))
      YD = ( YC - (YAX(1)-YDIR*RC) ) /
     :                    ((YAX(D2)+YDIR*RC)-(YAX(1)-YDIR*RC))
      IF ( ( XD .LT. 0.0 ) .OR. ( XD .GT. 1.0 ) .OR.
     :     ( YD .LT. 0.0 ) .OR. ( YD .GT. 1.0 ) ) GOTO 99
      NOTON = .FALSE.
      CALL AXIS_VAL2PIX( D1, XAX, .FALSE., XC-XDIR*RC, XC+XDIR*RC,
     :                                          XLO, XHI, STATUS )
      CALL AXIS_VAL2PIX( D2, YAX, .FALSE., YC-YDIR*RC, YC+YDIR*RC,
     :                                          YLO, YHI, STATUS )

      RC2 = RC*RC

*    Loop over all slices
      DO A = 1, D7
        DO B = 1, D6
          DO C = 1, D5
            DO D = 1, D4
              DO E = 1, D3

*              Test each pixel in restricted region
                DO Y = YLO, YHI
                  R2Y = (YAX(Y)-YC)**2
                  DO X = XLO, XHI
                    R2 = (XAX(X)-XC)**2 + R2Y
                    IF ( R2 .LE. RC2 ) THEN
                      SEL(X,Y,E,D,C,B,A) = .TRUE.
                    END IF
                  END DO
                END DO

              END DO
            END DO
          END DO
        END DO
      END DO

 99   CONTINUE

      END
