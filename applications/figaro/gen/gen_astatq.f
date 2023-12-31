C+
      SUBROUTINE GEN_ASTATQ(ARRAY,QUAL,NX,NY,IXST,IXEN,IYST,IYEN,TOTAL,
     :                 AMAX,AMIN,MEAN,XMAX,XMIN,YMAX,YMIN,SIGMA,SIZE)
C
C     G E N _ A S T A T Q
C
C     Examines a subset of a 2-dimensional array and returns a number
C     of statistics about the data in it.
C     This routine detects bad values using a quality array in the usual
C     way and ignores them in the statistics.
C     The calling routine should check that SIZE.GE.2 before using
C     the other returned values.
C
C     Parameters -  (">" input, "<" output)
C
C     (>) ARRAY   (Real array ARRAY(NX,NY)) The input array.
C     (>) QUAL    (Byte array QUAL(NX,NY)) The quality of ARRAY.
C     (>) NX      (Integer) The first (x) dimension of ARRAY.
C     (>) NY      (Integer) The second (y) dimension of ARRAY.
C     (>) IXST    (Integer) The first x-value of the subset.
C     (>) IXEN    (Integer) The last    "     "   "    "
C     (>) IYST    (Integer) The first y-value "   "    "
C     (>) IYEN    (Integer) The last    "     "   "    "
C     (<) TOTAL   (Real) The total data in the subset.
C     (<) AMAX    (Real) The maximum value in the subset.
C     (<) AMIN    (Real) The minimum   "   "   "   "
C     (<) MEAN    (Real) The mean      "   "   "   "
C     (<) XMAX    (Real) ) These four quantities return the positions
C     (<) XMIN    (Real) ) in x and y (ie the values of the array indices)
C     (<) YMAX    (Real) ) at which the maximum and minimum data values
C     (<) YMIN    (Real) ) were found.
C     (<) SIGMA   (Real) The standard deviation of the data in the subset
C     (<) SIZE    (Real) The number of pixels in the subset (this is
C                 not necessarily that implied by IXST,IYST etc, if these
C                 parameters would take the subset outside the array
C                 bounds.  SIZE is the number of pixels actually examined.
C
C                                               KS / CIT  6th March 1983
C     Modified:
C
C     19th March 1987.  KS / AAO. Double precision now used for total values
C                       in the internal calculations.
C     6th April 1993.   HME / UoE, Starlink.  Handle bad values. Adaption
C                       from GEN_ASTAT.
C     20th July 1998.   MBT / IoA, Starlink.  Handle bad values using quality
C                       array.  Adaption from GEN_ASTATB.
C+
      IMPLICIT NONE
C
C     Parameters
C
      INTEGER NX,NY,IXST,IXEN,IYST,IYEN
      REAL TOTAL,AMAX,AMIN,MEAN,XMAX,XMIN,YMAX,YMIN
      REAL SIGMA,SIZE
      REAL ARRAY(NX*NY)
      BYTE QUAL(NX*NY)
C          (Slightly more efficient than (NX,NY) in terms of code
C           generated by the compiler.)
C
C     Local variables
C
      INTEGER NXST,NYST,NXEN,NYEN,IX,IY,IPTR,IPBASE
      REAL    VALUE
      DOUBLE PRECISION TOTALDP,TOTSQ
      BYTE    GOOD
C
C     Constants
C
      PARAMETER (GOOD=0)
C
C     Check array limits
C
      NXST=MAX(1,IXST)
      NYST=MAX(1,IYST)
      NXEN=MIN(NX,IXEN)
      NYEN=MIN(NY,IYEN)
C
C     Initial values
C
      IPBASE=(NYST-1)*NX+NXST
      AMAX=ARRAY(IPBASE)
      AMIN=AMAX
      TOTALDP=0.
      TOTSQ=0.
      XMIN=NXST
      XMAX=NXST
      YMIN=NYST
      YMAX=NYST
      SIZE=0.
C
C     Pass through data
C
      DO IY=NYST,NYEN
         IPTR=IPBASE
         DO IX=NXST,NXEN
            VALUE=ARRAY(IPTR)
            IF (QUAL(IPTR).EQ.GOOD) THEN
               IPTR=IPTR+1
               IF (VALUE.LT.AMIN) THEN
                  AMIN=VALUE
                  XMIN=IX
                  YMIN=IY
               END IF
               IF (VALUE.GT.AMAX) THEN
                  AMAX=VALUE
                  XMAX=IX
                  YMAX=IY
               END IF
               SIZE=SIZE+1.
               TOTALDP=TOTALDP+VALUE
               TOTSQ=TOTSQ+VALUE*VALUE
            END IF
         END DO
         IPBASE=IPBASE+NX
      END DO
C
      IF (SIZE.GE.2.) THEN
         MEAN=TOTALDP/SIZE
         SIGMA=SQRT(ABS((TOTSQ-(TOTALDP*TOTALDP)/SIZE)/(SIZE-1.)))
         TOTAL=TOTALDP
      ELSE
         MEAN=0.
         SIGMA=1.
         TOTAL=0.
      END IF
C
      END
