      FUNCTION CUFX (RX)
C
C Given an x coordinate RX in the user system, CUFX(RX) is an x
C coordinate in the fractional system.
C
      COMMON /IUTLCM/ LL,MI,MX,MY,IU(96)
      DIMENSION WD(4),VP(4)
      CALL GQCNTN (IE,NT)
      CALL GQNT (NT,IE,WD,VP)
      I=1
      IF (MI.GE.3) I=2
      IF (LL.LE.2) THEN
        CUFX=(RX-WD(I))/(WD(3-I)-WD(I))*(VP(2)-VP(1))+VP(1)
      ELSE
        CUFX=(ALOG10(RX)-WD(I))/(WD(3-I)-WD(I))*(VP(2)-VP(1))+VP(1)
      ENDIF
      RETURN
      END
