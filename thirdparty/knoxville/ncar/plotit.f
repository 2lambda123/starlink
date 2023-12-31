      SUBROUTINE PLOTIT (IX,IY,IP)
C
C Move the pen to the point (IX,IY), in the metacode coordinate system.
C If IP is zero, do a pen-up move.  If IP is one, do a pen-down move.
C If IP is two, flush the buffer.  (For the sake of efficiency, the
C moves are buffered; "CALL PLOTIT (0,0,0)" will also flush the buffer.)
C
C The variable IU(5), in the labelled common block IUTLCM, specifies
C the size of the buffer to be used by PLOTIT (between 2 and 50).
C
      COMMON /IUTLCM/ IU(100)
C
C The common block VCTSEQ contains variables implementing the buffering
C of pen moves.
C
      COMMON /VCTSEQ/ NQ,QX(50),QY(50),NF,IF(25)
C
C In the common block PLTCM are recorded the coordinates of the last
C pen position, in the metacode coordinate system, for MXMY.
C
      COMMON /PLTCM/ JX,JY
C
C Force loading of the block data routine which initializes the contents
C of the common blocks.
C
      EXTERNAL UTILBD
C
C VP and WD hold viewport and window parameters obtained, when needed,
C from GKS.
C
      DIMENSION VP(4),WD(4)
C
C Check for out-of-range values of the pen parameter.
C
      IF (IP.LT.0.OR.IP.GT.2) THEN
        CALL SETER ('PLOTIT - ILLEGAL VALUE FOR IPEN',1,2)
      END IF
C
C If a buffer flush is requested, jump.
C
      IF (IP.EQ.2) GO TO 101
C
C Limit the given coordinates to the legal metacode range.
C
      JX=MAX0(0,MIN0(32767,IX))
      JY=MAX0(0,MIN0(32767,IY))
C
C If the current move is a pen-down move, or if the last one was, bump
C the pointer into the coordinate arrays and, if the current move is
C a pen-up move, make a new entry in the array IF, which records the
C positions of the pen-up moves.  Note that we never get two pen-up
C moves in a row, which means that IF need be dimensioned only half as
C large as QX and QY.
C
      IF (IP.NE.0.OR.IF(NF).NE.NQ) THEN
        NQ=NQ+1
        IF (IP.EQ.0) THEN
          NF=NF+1
          IF(NF)=NQ
        END IF
      END IF
C
C Save the coordinates of the point, in the fractional coordinate
C system.
C
      QX(NQ)=FLOAT(JX)/32767.
      QY(NQ)=FLOAT(JY)/32767.
C
C If all three arguments were zero, or if the point-coordinate buffer
C is full, dump the buffers; otherwise, return.
C
      IF (IX.EQ.0.AND.IY.EQ.0.AND.IP.EQ.0) GO TO 101
      IF (NQ.LT.IU(5)) RETURN
C
C Dump the buffers.  If NQ is one, there's nothing to dump.  All that's
C there is a single pen-up move.
C
  101 IF (NQ.LE.1) RETURN
C
C Get NT, the number of the current transformation, and, if it is not
C zero, modify the current transformation so that we can use fractional
C coordinates (normalized device coordinates, in GKS terms).
C
      CALL GQCNTN (IE,NT)
      IF (NT.NE.0) THEN
        CALL GQNT (NT,IE,WD,VP)
        CALL GSWN (NT,VP(1),VP(2),VP(3),VP(4))
      END IF
C
C Dump out a series of polylines, each one defined by a pen-up move and
C a series of pen-down moves.
C
      DO 102 I=1,NF-1
        CALL GPL (IF(I+1)-IF(I),QX(IF(I)),QY(IF(I)))
  102 CONTINUE
      IF (IF(NF).NE.NQ) CALL GPL (NQ-IF(NF)+1,QX(IF(I)),QY(IF(I)))
C
C Put the current transformation back the way it was.
C
      IF (NT.NE.0) THEN
        CALL GSWN (NT,WD(1),WD(2),WD(3),WD(4))
      END IF
C
C Move the last pen position to the beginning of the buffer and pretend
C there was a pen-up move to that position.
C
      QX(1)=QX(NQ)
      QY(1)=QY(NQ)
      NQ=1
      IF(1)=1
      NF=1
C
C Done.
C
      RETURN
C
      END
