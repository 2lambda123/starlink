      SUBROUTINE SWAP(NPARAMS,PARAMS,TITLE,LAMBDA,STOKES_I,STOKES_Q,
     &                STOKES_QV,STOKES_U,
     &             STOKES_UV,NPTS,
     &             STK_TITLE,STK_LAMBDA,STK_STOKES_I,STK_STOKES_Q,
     &             STK_STOKES_QV,STK_STOKES_U,STK_STOKES_UV,
     &             STK_NPTS,TOP_STK,OUT_LU)
C+
C
C Subroutine:
C
C     S W A P
C
C
C Author: Tim Harries (tjh@st-and.ac.uk)
C
C Parameters:
C
C NPARAMS (<), PARAMS (<), TITLE (><), LAMBDA (><), STOKES_I (><),
C STOKES_Q (><), STOKES_QV (><), STOKES_U (><), STOKES_UV (><), NPTS (><),
C STK_TITLE (><), STK_LAMBDA (><), STK_STOKES_I (><), STK_STOKES_Q (><),
C STK_STOKES_QV (><), STK_STOKES_U (><), STK_STOKES_UV (><),
C STK_NPTS (><), TOP_STK (<), OUT_LU (<)
C
C History:
C
C   May 1994 Created
C
C
C
C
C Swaps the current polarization spectrum with one from the stack
C
C
C
C
C
C-
      IMPLICIT NONE
      INTEGER OUT_LU
      INCLUDE 'ARRAY_SIZE'
C
C Parameters
C
      INTEGER NPARAMS
      REAL PARAMS(*)
C
C The current arrays
C
      REAL LAMBDA(*)
      REAL STOKES_I(*)
      REAL STOKES_Q(*)
      REAL STOKES_QV(*)
      REAL STOKES_U(*)
      REAL STOKES_UV(*)
      INTEGER NPTS
      CHARACTER*80 TITLE
C
C The stack arrays
C
      REAL STK_LAMBDA(MAXPTS,MAXSPEC)
      REAL STK_STOKES_I(MAXPTS,MAXSPEC)
      REAL STK_STOKES_Q(MAXPTS,MAXSPEC)
      REAL STK_STOKES_QV(MAXPTS,MAXSPEC)
      REAL STK_STOKES_U(MAXPTS,MAXSPEC)
      REAL STK_STOKES_UV(MAXPTS,MAXSPEC)
C
C
      REAL TEMP_STOKES_I(MAXPTS)
      REAL TEMP_STOKES_Q(MAXPTS)
      REAL TEMP_STOKES_QV(MAXPTS)
      REAL TEMP_STOKES_U(MAXPTS)
      REAL TEMP_STOKES_UV(MAXPTS)
C
      INTEGER STK_NPTS(MAXSPEC)
      CHARACTER*80 STK_TITLE(MAXSPEC)
      CHARACTER*80 TEMPSTR
      INTEGER TOP_STK
      INTEGER I,NSWAP
      LOGICAL OK
C
      IF (NPARAMS.EQ.0) THEN
        CALL GET_PARAM('Stack entry',PARAMS(1),OK,OUT_LU)
        IF (.NOT.OK) GOTO 666
      ENDIF
C
      IF (NPARAMS.GT.1) THEN
       CALL WR_ERROR('Superfluous parameters ignored',OUT_LU)
      ENDIF
C
      IF (INT(PARAMS(1)).GT.TOP_STK) THEN
       CALL WR_ERROR('Stack entry out of range',OUT_LU)
       GOTO 666
      ENDIF
C
C Ensure there is something in the current arrays
C
      IF (NPTS.EQ.0) THEN
        CALL WR_ERROR('Current arrays are empty',OUT_LU)
        GOTO 666
      ENDIF
C
      NSWAP=INT(PARAMS(1))
C
      DO I = 1,STK_NPTS(NSWAP)
       TEMP_STOKES_I(I)=STK_STOKES_I(I,NSWAP)
       TEMP_STOKES_Q(I)=STK_STOKES_Q(I,NSWAP)
       TEMP_STOKES_QV(I)=STK_STOKES_QV(I,NSWAP)
       TEMP_STOKES_U(I)=STK_STOKES_U(I,NSWAP)
       TEMP_STOKES_UV(I)=STK_STOKES_UV(I,NSWAP)
      ENDDO
      DO I=1,NPTS
       STK_STOKES_I(I,NSWAP) = STOKES_I(I)
       STK_STOKES_Q(I,NSWAP) = STOKES_Q(I)
       STK_STOKES_QV(I,NSWAP) = STOKES_QV(I)
       STK_STOKES_U(I,NSWAP) = STOKES_U(I)
       STK_STOKES_UV(I,NSWAP) = STOKES_UV(I)
       STK_LAMBDA(I,NSWAP) = LAMBDA(I)
      ENDDO
      DO I=1,STK_NPTS(NSWAP)
       STOKES_I(I)=TEMP_STOKES_I(I)
       STOKES_Q(I)=TEMP_STOKES_Q(I)
       STOKES_QV(I)=TEMP_STOKES_QV(I)
       STOKES_U(I)=TEMP_STOKES_U(I)
       STOKES_UV(I)=TEMP_STOKES_UV(I)
      ENDDO
      I = STK_NPTS(NSWAP)
      STK_NPTS(NSWAP) = NPTS
      NPTS = I
      TEMPSTR=STK_TITLE(NSWAP)
      STK_TITLE(NSWAP) = TITLE
      TITLE = TEMPSTR
C
666   CONTINUE
      END
