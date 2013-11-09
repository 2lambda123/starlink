*+  GFX_AERRQ - draw asymmetric error bars at points with good quality
      SUBROUTINE GFX_AERRQ(NVAL,N1,N2,X,XL,XU,Y,EL,EU,Q,MASK,STATUS)
*    Description :
*    Authors :
*     BHVAD::RJV
*    History :
*    Type definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'PRM_PAR'
      INCLUDE 'QUAL_PAR'
*    Import :
      INTEGER NVAL		! number of points
      INTEGER N1,N2		! range of points to plot
      REAL X(NVAL)		! array of x values
      REAL XL(NVAL)		! array of x lower values
      REAL XU(NVAL)		! array of x upper values
      REAL Y(NVAL)		! array of y values
      REAL EL(NVAL)		! array of lower errors
      REAL EU(NVAL)		! array of upper errors
      BYTE Q(NVAL)		! quality array
      BYTE MASK			! quality mask
*    Import-Export :
*    Export :
*    Status :
      INTEGER STATUS
*    Function declarations :
      BYTE BIT_ANDUB
*    Local constants :
*    Local variables :
      REAL X1,X2,Y1,Y2
      INTEGER I
      INTEGER SHAPE,WIDTH,COLOUR
      LOGICAL XLOG,YLOG
      LOGICAL OK
*-

      IF (STATUS.EQ.SAI__OK) THEN

*  are axes logarithmic
        CALL GCB_GETL('XAXIS_LOG',OK,XLOG,STATUS)
        IF (.NOT.OK) THEN
          XLOG=.FALSE.
        ENDIF
        CALL GCB_GETL('YAXIS_LOG',OK,YLOG,STATUS)
        IF (.NOT.OK) THEN
          YLOG=.FALSE.
        ENDIF

*  get shape of error bars
        CALL GCB_GETI('ERR_SHAPE',OK,SHAPE,STATUS)
        IF (.NOT.OK) THEN
          SHAPE=1
        ENDIF

*  set line-width etc
        CALL GCB_SETDEF(STATUS)
        CALL GCB_GETI('ERR_WIDTH',OK,WIDTH,STATUS)
        IF (OK) THEN
          CALL PGSLW(WIDTH)
        ENDIF
        CALL GCB_GETI('ERR_COLOUR',OK,COLOUR,STATUS)
        IF (OK) THEN
          CALL PGSCI(COLOUR)
        ENDIF

*  simple case of lin/lin axes
        IF (.NOT.(XLOG.OR.YLOG)) THEN
          DO I=N1,N2
            X1=X(I)-XL(I)
            X2=X(I)+XU(I)
            Y1=Y(I)-EL(I)
            Y2=Y(I)+EU(I)
            IF (BIT_ANDUB(Q(I),MASK).EQ.QUAL__GOOD) THEN
              CALL GFX_ERRSYM(X(I),X1,X2,Y(I),Y1,Y2,SHAPE,STATUS)
            ENDIF
          ENDDO

*  one or both log axes
        ELSEIF (XLOG.AND..NOT.YLOG) THEN
          DO I=N1,N2
            X1=MAX(X(I)-XL(I),VAL__SMLR)
            X2=MAX(X(I)+XU(I),VAL__SMLR)
            Y1=Y(I)-EL(I)
            Y2=Y(I)+EU(I)
            IF (X(I).GT.VAL__SMLR.AND.
     :               BIT_ANDUB(Q(I),MASK).EQ.QUAL__GOOD) THEN
              CALL GFX_ERRSYM(LOG10(X(I)),LOG10(X1),LOG10(X2),
     :                             Y(I),Y1,Y2,SHAPE,STATUS)
            ENDIF
          ENDDO

        ELSEIF (.NOT.XLOG.AND.YLOG) THEN
          DO I=N1,N2
            X1=X(I)-XL(I)
            X2=X(I)+XU(I)
            Y1=MAX(Y(I)-EL(I),VAL__SMLR)
            Y2=MAX(Y(I)+EU(I),VAL__SMLR)
            IF (Y(I).GT.VAL__SMLR.AND.
     :                BIT_ANDUB(Q(I),MASK).EQ.QUAL__GOOD) THEN
              CALL GFX_ERRSYM(X(I),X1,X2,
     :                         LOG10(Y(I)),LOG10(Y1),LOG10(Y2),
     :                                             SHAPE,STATUS)
            ENDIF
          ENDDO


        ELSEIF (XLOG.AND.YLOG) THEN
          DO I=N1,N2
            X1=MAX(X(I)-XL(I),VAL__SMLR)
            X2=MAX(X(I)+XU(I),VAL__SMLR)
            Y1=MAX(Y(I)-EL(I),VAL__SMLR)
            Y2=MAX(Y(I)+EU(I),VAL__SMLR)
            IF (X(I).GT.VAL__SMLR.AND.Y(I).GT.VAL__SMLR.AND.
     :                        BIT_ANDUB(Q(I),MASK).EQ.QUAL__GOOD) THEN
              CALL GFX_ERRSYM(LOG10(X(I)),LOG10(X1),LOG10(X2),
     :                         LOG10(Y(I)),LOG10(Y1),LOG10(Y2),
     :                                            SHAPE,STATUS)
            ENDIF
          ENDDO


        ENDIF

        CALL GCB_SETDEF(STATUS)

      ENDIF

      END
