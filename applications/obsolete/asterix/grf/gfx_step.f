*+  GFX_STEP - draw a stepped line through points
      SUBROUTINE GFX_STEP(NVAL,N1,N2,X,XW,Y,STATUS)
*    Description :
*    Authors :
*     BHVAD::RJV
*    History :
*    Type definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'PRM_PAR'
*    Import :
      INTEGER NVAL		! number of points
      INTEGER N1,N2		! range of points to plot
      REAL X(NVAL)		! array of x values
      REAL XW(NVAL)		! array of x-widths
      REAL Y(NVAL)		! array of y values
*    Import-Export :
*    Export :
*    Status :
      INTEGER STATUS
*    Function declarations :
*    Local constants :
*    Local variables :
      REAL X1,X2
      INTEGER I
      INTEGER STYLE,WIDTH,COLOUR
      LOGICAL FIRST			! first point of a continuous segment
      LOGICAL OK
      LOGICAL XLOG,YLOG			! whether axes are log
*-

      IF (STATUS.EQ.SAI__OK) THEN

*  see if log axes
        CALL GCB_GETL('XAXIS_LOG',OK,XLOG,STATUS)
        IF (.NOT.OK) THEN
          XLOG=.FALSE.
        ENDIF
        CALL GCB_GETL('YAXIS_LOG',OK,YLOG,STATUS)
        IF (.NOT.OK) THEN
          YLOG=.FALSE.
        ENDIF

*  set plotting attributes
        CALL GCB_SETDEF(STATUS)
        CALL GCB_GETI('STEP_STYLE',OK,STYLE,STATUS)
        IF (OK) THEN
          CALL PGSLS(STYLE)
        ENDIF
        CALL GCB_GETI('STEP_WIDTH',OK,WIDTH,STATUS)
        IF (OK) THEN
          CALL PGSLW(WIDTH)
        ENDIF
        CALL GCB_GETI('STEP_COLOUR',OK,COLOUR,STATUS)
        IF (OK) THEN
          CALL PGSCI(COLOUR)
        ENDIF



*  simple case of lin/lin axes
        IF (.NOT.(XLOG.OR.YLOG)) THEN
*  get starting point
          X1=X(N1)-XW(N1)/2.0
          CALL PGMOVE(X1,Y(N1))
          X2=X(N1)+XW(N1)/2.0
          CALL PGDRAW(X2,Y(N1))
*  plot points
          DO I=N1+1,N2-1
            X1=X2
            X2=X(I)+XW(I)/2.0
            CALL PGDRAW(X1,Y(I))
            CALL PGDRAW(X2,Y(I))
          ENDDO
*  last point
          X1=X2
          X2=X(N2)+XW(N2)/2.0
          CALL PGDRAW(X1,Y(N2))
          CALL PGDRAW(X2,Y(N2))

*  one or both log axes
        ELSEIF (XLOG.AND..NOT.YLOG) THEN
          FIRST=.TRUE.
          X2=X(N1)-XW(N1)/2.0
          DO I=N1,N2
            X1=X2
            X2=X(I)+XW(I)/2.0
            IF (X1.GT.VAL__SMLR) THEN
              IF (FIRST) THEN
                CALL PGMOVE(LOG10(X1),Y(I))
                CALL PGDRAW(LOG10(X2),Y(I))
                FIRST=.FALSE.
              ELSE
                CALL PGDRAW(LOG10(X1),Y(I))
                CALL PGDRAW(LOG10(X2),Y(I))
              ENDIF
            ELSE
              FIRST=.TRUE.
            ENDIF
          ENDDO


        ELSEIF (.NOT.XLOG.AND.YLOG) THEN
          FIRST=.TRUE.
          X2=X(N1)--XW(N1)/2.0
          DO I=N1,N2
            X2=X(I)+XW(I)/2.0
            IF (Y(I).GT.VAL__SMLR) THEN
              IF (FIRST) THEN
                CALL PGMOVE(X1,LOG10(Y(I)))
                CALL PGDRAW(X2,LOG10(Y(I)))
                FIRST=.FALSE.
              ELSE
                CALL PGDRAW(X1,LOG10(Y(I)))
                CALL PGDRAW(X2,LOG10(Y(I)))
              ENDIF
            ELSE
              FIRST=.TRUE.
            ENDIF
          ENDDO


        ELSEIF (XLOG.AND.YLOG) THEN
          FIRST=.TRUE.
          X2=X(N1)-XW(N1)/2.0
          DO I=N1,N2
            X1=X2
            X2=X(I)+XW(I)/2.0
            IF (X1.GT.VAL__SMLR.AND.Y(I).GT.VAL__SMLR) THEN
              IF (FIRST) THEN
                CALL PGMOVE(LOG10(X1),LOG10(Y(I)))
                CALL PGDRAW(LOG10(X2),LOG10(Y(I)))
                FIRST=.FALSE.
              ELSE
                CALL PGDRAW(LOG10(X1),LOG10(Y(I)))
                CALL PGDRAW(LOG10(X2),LOG10(Y(I)))
              ENDIF
            ELSE
              FIRST=.TRUE.
            ENDIF
          ENDDO


        ENDIF

        CALL GCB_SETDEF(STATUS)

      ENDIF

      END
