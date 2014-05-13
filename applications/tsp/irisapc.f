C+
      SUBROUTINE IRISAPC(STATUS)
C
C            I R I S A P C
C
C     Command name:
C        IRISAPC
C
C     Function:
C        Measure circular polarization within an aperture for IRIS data
C
C     Description:
C        IRISAP reduces data obtained with the AAT IRIS polarimeter
C        using the wollaston  prism polarizer. The data for a
C        single observation consists of two Figaro files containing the
C        frames for plate position 0 and 90 degrees. Within each
C        frame are selected two star images corresponding to the O and E rays
C        for the same star. The polarization is derived for these.
C
C        Two different algorithms may be selected for the polarimetry
C        reduction. The two algorithms differ in the method used to
C        compensate for transparency variations between the observations
C        at the two plate positions.
C
C
C     Parameters:
C    (1) POS1       (Char)     The Figaro data file for position 0.0.
C    (2) POS2       (Char)     The Figaro data file for position 90.0.
C        X          (Integer)  X coordinate of centre of aperture
C        Y          (Integer)  Y coordinate of centre of aperture
C        R          (Real)     Radius of aperture
C        XSEP       (Integer)  OE separation vector in X
C        YSEP       (Integer)  OE separation vector in Y
C
C     Support: Jeremy Bailey, AAO
C
C     Version date: 17/03/2000
C
C-
C
C  History:
C    25/5/1994   Original Version.   JAB/AAO
C    17/03/2000  Added DOUBLE PRECISION dummy argument DDUMMY.   BLY/RAL
C

      IMPLICIT NONE
      INCLUDE 'SAE_PAR'
      INCLUDE 'CNF_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'USER_ERR'

*  Status argument
      INTEGER STATUS

*  Data pointers
      INTEGER IPTR,XPTR,YPTR,IPTR2,IPTR3,IPTR4

*  Number of elements in data arrays
      INTEGER NDIM, DIMS(7),DIMS2(7)


*  Extraction parameters
      INTEGER XSEP,YSEP
      REAL X,Y,R

*  HDS locators
      CHARACTER*(DAT__SZLOC) ILOC,
     :    SLOC,OXLOC,OYLOC,T1LOC,T2LOC
      CHARACTER*64 FNAME,LABEL,UNITS,XLABEL,XUNITS,YLABEL,YUNITS
      LOGICAL OK
      INTEGER ISLOT,ISLOT2,DUMMY
      CHARACTER*64 STRINGS(2)
      INTEGER ELEMENTS,XSLOT,YSLOT
      DOUBLE PRECISION DDUMMY

*  Access the First Figaro frame

      CALL PAR_GET0C('POS1',FNAME,STATUS)
      CALL DSA_OPEN(STATUS)
      CALL DSA_NAMED_INPUT('INPUT',FNAME,STATUS)

*  Get the data array

      IF (STATUS .EQ. SAI__OK) THEN
         CALL DSA_DATA_SIZE('INPUT',2,NDIM,DIMS,ELEMENTS,STATUS)

*  Check that it is two dimensional

         IF (NDIM .NE. 2) THEN
            CALL MSG_OUT(' ','Dimensions of Input File Invalid',
     :          STATUS)
            GOTO 100
         ELSE

*  Map the data

            CALL DSA_MAP_DATA('INPUT','READ','FLOAT',IPTR,ISLOT,STATUS)
            IF (STATUS .NE. SAI__OK) THEN
               CALL ERR_REP(' ','Error Mapping Input Data',STATUS)
               GOTO 100
            ENDIF

*  Get the label and units

            CALL DSA_GET_DATA_INFO('INPUT',2,STRINGS,1,DDUMMY,STATUS)
            IF (STATUS .EQ. SAI__OK) THEN
                LABEL = STRINGS(2)
                UNITS = STRINGS(1)
            ELSE
                LABEL = ' '
                UNITS = ' '
            ENDIF

*  Map .X.DATA if it exists

            CALL DSA_MAP_AXIS_DATA('INPUT',1,'READ','FLOAT',XPTR,
     :           XSLOT,STATUS)

*  And get its label and units

            CALL DSA_GET_AXIS_INFO('INPUT',1,2,STRINGS,0,DDUMMY,STATUS)
            XLABEL = STRINGS(2)
            XUNITS = STRINGS(1)

*  Map .Y.DATA if it exists

            CALL DSA_MAP_AXIS_DATA('INPUT',2,'READ','FLOAT',YPTR,
     :           YSLOT,STATUS)

*  And get its label and units

            CALL DSA_GET_AXIS_INFO('INPUT',2,2,STRINGS,0,DDUMMY,STATUS)
            YLABEL = STRINGS(2)
            YUNITS = STRINGS(1)

*  Access the Second Figaro frame

             CALL PAR_GET0C('POS2',FNAME,STATUS)
             CALL DSA_NAMED_INPUT('INPUT2',FNAME,STATUS)
             IF (STATUS .NE. SAI__OK) THEN
               CALL MSG_OUT(' ','Error accessing frame',STATUS)
               GOTO 100
             ENDIF

*  Get the data array

             IF (STATUS .EQ. SAI__OK) THEN
                CALL DSA_DATA_SIZE('INPUT2',2,NDIM,DIMS2,ELEMENTS,
     :               STATUS)

*  Check that its dimensions match those of the previous frame

                IF (NDIM .NE. 2 .OR.
     :               DIMS2(1) .NE. DIMS(1) .OR.
     :               DIMS2(2) .NE. DIMS(2)) THEN
                  CALL MSG_OUT(' ','Dimensions of Input File Invalid',
     :              STATUS)
                  GOTO 100
                ENDIF

*  Map the data

                CALL DSA_MAP_DATA('INPUT2','READ','FLOAT',IPTR2,ISLOT2,
     :                STATUS)
                IF (STATUS .NE. SAI__OK) THEN
                   CALL ERR_REP(' ','Error Mapping Input Data',STATUS)
                   GOTO 100
                ENDIF
             ENDIF


*  Get information on location of spectra


*  Centre of aperture in X
             CALL PAR_GET0R('X',X,STATUS)

*  Centre of aperture in Y
             CALL PAR_GET0R('Y',Y,STATUS)

*  Radius of aperture
             CALL PAR_GET0R('R',R,STATUS)

*  Separation in X
             CALL PAR_GET0I('XSEP',XSEP,STATUS)

*  Separation in Y
             CALL PAR_GET0I('YSEP',YSEP,STATUS)

*  Check them for validity


*  Reduce the data

             IF (STATUS .EQ. SAI__OK) THEN


                    CALL TSP_IRISAPC(DIMS(1),DIMS(2),
     :       %VAL(CNF_PVAL(IPTR)),
     :                %VAL(CNF_PVAL(IPTR2)),
     :                X,Y,R,XSEP,YSEP,STATUS)

             ENDIF

*  Unmap output arrays and annul locators


          ENDIF

*  Unmap input arrays

      ENDIF
100   CONTINUE
      CALL DSA_CLOSE(STATUS)
      END




      SUBROUTINE TSP_IRISAPC(IX,IY,I1,I2,X,Y,R,XSEP,YSEP,STATUS)
*+
*   Subroutine to do the aperture polarimetry
*
*
*    (>) IX   (Integer)  First dimension of arrays
*    (>) IY   (Integer)  Second dimension of arrays
*    (>) I1      (Real array(IX,IY))  The first intensity array
*    (>) I2      (Real array(IX,IY))  The second intensity array
*    (>) X       (Real) X centre of aperture
*    (>) Y       (Real) Y centre of aperture
*    (>) R       (Real) Radius of aperture
*    (>) XSEP    (Integer) X separation of E and O
*    (>) YSEP    (Integer) Y separation of E and O
*    (!) STATUS  (Integer)  Status value
*
*    Jeremy Bailey   25/5/1994
*
*    Modified:
*
*+
      IMPLICIT NONE
      INCLUDE 'SAE_PAR'
      INCLUDE 'CNF_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'PRM_PAR'

*  Parameters
      INTEGER IX,IY
      REAL I1(IX,IY),I2(IX,IY)
      REAL X,Y,R
      INTEGER XSEP,YSEP
      INTEGER STATUS

*  Local variables
      INTEGER I,J

      REAL E1,E2,O1,O2
      REAL VE,VO,V,DX,DY,DD

      IF (STATUS .EQ. SAI__OK) THEN

         E1=0.0
         E2=0.0
         O1=0.0
         O2=0.0
*  Determine the sum of the intensities
         DO I=1,IX
           DO J=1,IY

*  Only sum channels for which both intensities are good
            IF (I1(I,J) .NE. VAL__BADR .AND.
     :          I2(I,J) .NE. VAL__BADR) THEN
              DX = REAL(I)-X
              DY = REAL(J)-Y
              DD = SQRT(DX*DX+DY*DY)
              IF (DD .LT. R) THEN
                E1 = E1+I1(I,J)
                E2 = E2+I2(I,J)
              ENDIF

              DX = REAL(I)-(X + REAL(XSEP))
              DY = REAL(J)-(Y + REAL(YSEP))
              DD = SQRT(DX*DX+DY*DY)
              IF (DD .LT. R) THEN
                O1 = O1+I1(I,J)
                O2 = O2+I2(I,J)
              ENDIF


            ENDIF
           ENDDO
         ENDDO

         VE = (E2-E1)/(E1+E2)
         VO = (O1-O2)/(O1+O2)
         V = 0.5*(VE+VO)
         V = V*100.0
         CALL MSG_SETR('V',V)
         CALL MSG_OUT(' ','V/I = ^V  ',STATUS)
       ENDIF

      END

