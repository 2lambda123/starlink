      SUBROUTINE DRCNTR (Z,L,MM,NN)
      SAVE
C
      DIMENSION       Z(L,NN)
C
C THIS ROUTINE TRACES A CONTOUR LINE WHEN GIVEN THE BEGINNING BY STLINE.
C TRANSFORMATIONS CAN BE ADDED BY DELETING THE STATEMENT FUNCTIONS FOR
C FX AND FY IN DRLINE AND MINMAX AND ADDING EXTERNAL FUNCTIONS.
C X=1. AT Z(1,J), X=FLOAT(M) AT Z(M,J). X TAKES ON NON-INTEGER VALUES.
C Y=1. AT Z(I,1), Y=FLOAT(N) AT Z(I,N). Y TAKES ON NON-INTEGER VALUES.
C
      COMMON /ISOSR6/ IX         ,IY         ,IDX        ,IDY        ,
     1                IS         ,ISS        ,NP         ,CV         ,
     2                INX(8)     ,INY(8)     ,IR(500)    ,NR
      COMMON /ISOSR9/ BIG        ,IXBIT
C
      LOGICAL         IPEN       ,IPENO
C
      DATA IOFFP,SPVAL/0,0./
      DATA IPEN,IPENO/.TRUE.,.TRUE./
C
C  PACK X AND Y
C
      IPXY(I1,J1) = ISHIFT(I1,IXBIT)+J1
      FX(X1,Y1) = X1
      FY(X1,Y1) = Y1
      C(P11,P21) = (P11-CV)/(P11-P21)
C
      M = MM
      N = NN
      IF (IOFFP .EQ. 0) GO TO  10
      ASSIGN 100 TO JUMP1
      ASSIGN 150 TO JUMP2
      GO TO  20
   10 ASSIGN 120 TO JUMP1
      ASSIGN 160 TO JUMP2
   20 IX0 = IX
      IY0 = IY
      IS0 = IS
      IF (IOFFP .EQ. 0) GO TO  30
      IX2 = IX+INX(IS)
      IY2 = IY+INY(IS)
      IPEN = Z(IX,IY).NE.SPVAL .AND. Z(IX2,IY2).NE.SPVAL
      IPENO = IPEN
   30 IF (IDX .EQ. 0) GO TO  40
      Y = IY
      ISUB = IX+IDX
      X = C(Z(IX,IY),Z(ISUB,IY))*FLOAT(IDX)+FLOAT(IX)
      GO TO  50
   40 X = IX
      ISUB = IY+IDY
      Y = C(Z(IX,IY),Z(IX,ISUB))*FLOAT(IDY)+FLOAT(IY)
   50 IF (IPEN) CALL FRSTS (FX(X,Y),FY(X,Y),1)
   60 IS = IS+1
      IF (IS .GT. 8) IS = IS-8
      IDX = INX(IS)
      IDY = INY(IS)
      IX2 = IX+IDX
      IY2 = IY+IDY
      IF (ISS .NE. 0) GO TO  70
      IF (IX2.GT.M .OR. IY2.GT.N .OR. IX2.LT.1 .OR. IY2.LT.1) GO TO 190
   70 IF (CV-Z(IX2,IY2))  80, 80, 90
   80 IS = IS+4
      IX = IX2
      IY = IY2
      GO TO  60
   90 IF (IS/2*2 .EQ. IS) GO TO  60
      GO TO JUMP1,(100,120)
  100 ISBIG = IS+(8-IS)/6*8
      IX3 = IX+INX(ISBIG-1)
      IY3 = IY+INY(ISBIG-1)
      IX4 = IX+INX(ISBIG-2)
      IY4 = IY+INY(ISBIG-2)
      IPENO = IPEN
      IF (ISS .NE. 0) GO TO 110
      IF (IX3.GT.M .OR. IY3.GT.N .OR. IX3.LT.1 .OR. IY3.LT.1) GO TO 190
      IF (IX4.GT.M .OR. IY4.GT.N .OR. IX4.LT.1 .OR. IY4.LT.1) GO TO 190
  110 IPEN = Z(IX,IY).NE.SPVAL .AND. Z(IX2,IY2).NE.SPVAL .AND.
     1       Z(IX3,IY3).NE.SPVAL .AND. Z(IX4,IY4).NE.SPVAL
  120 IF (IDX .EQ. 0) GO TO 130
      Y = IY
      ISUB = IX+IDX
      X = C(Z(IX,IY),Z(ISUB,IY))*FLOAT(IDX)+FLOAT(IX)
      GO TO 140
  130 X = IX
      ISUB = IY+IDY
      Y = C(Z(IX,IY),Z(IX,ISUB))*FLOAT(IDY)+FLOAT(IY)
  140 GO TO JUMP2,(150,160)
  150 IF (.NOT.IPEN) GO TO 170
      IF (IPENO) GO TO 160
C
C END OF LINE SEGMENT
C
      CALL FRSTS (D1,D2,3)
      CALL FRSTS (FX(XOLD,YOLD),FY(XOLD,YOLD),1)
C
C CONTINUE LINE SEGMENT
C
  160 CALL FRSTS (FX(X,Y),FY(X,Y),2)
  170 XOLD = X
      YOLD = Y
      IF (IS .NE. 1) GO TO 180
      NP = NP+1
      IF (NP .GT. NR) GO TO 190
      IR(NP) = IPXY(IX,IY)
  180 IF (ISS .EQ. 0) GO TO  60
      IF (IX.NE.IX0 .OR. IY.NE.IY0 .OR. IS.NE.IS0) GO TO  60
C
C END OF LINE
C
  190 CALL FRSTS (D1,D2,3)
      RETURN
      END
