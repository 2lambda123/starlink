C+
      SUBROUTINE GEN_GROWY (ARR1D,NX,NY,IX1,IX2,ARR2D)
C
C     G E N _ G R O W Y
C
C     Copies a one dimensional array into successive cross-
C     sections of a two dimensional array.  The cross-sections
C     are cross-sections in the 'Y' direction, ie array elements
C     for which the first array index is constant.  The arrays
C     are described here as integers, but arrays with 4-byte
C     elements (ie real arrays), can be used equally well.
C
C     Parameters -  (">" input, "<" output)
C
C     (>) ARR1D    (Integer array ARR1D(NY)) The 1D array.
C     (>) NX       (Integer) The first dimension of ARR2D.
C     (>) NY       (Integer) The number of elements in ARR1D.
C                  Also the second dimension of ARR2D.
C     (>) IX1      (Integer) The number of the first cross-section
C                  of ARR2D into which ARR1D is to be copied.
C     (>) IX2      (Integer) The number of the last cross-section
C                  of ARR2D into which ARR1D is to be copied.
C     (<) ARR2D    (Integer array ARR2D(NX,NY)) The 2D array.
C
C     Common variables used -  None
C
C     Subroutines / functions used -  None
C
C                                             KS / CIT 29th March 1985
C+
      IMPLICIT NONE
C
C     Parameters
C
      INTEGER NX,NY,IX1,IX2,ARR1D(NY),ARR2D(NX,NY)
C
C     Local variables
C
      INTEGER IX,IY,LIM1,LIM2
C
      LIM1=MAX(1,IX1)
      LIM2=MIN(NX,IX2)
      DO IY=1,NY
         DO IX=LIM1,LIM2
            ARR2D(IX,IY)=ARR1D(IY)
         END DO
      END DO
C
      END
