      SUBROUTINE MMASK
C
C  MAKE THE MACHINE DEPENDENT MASKS USED IN THE CONTOUR DRAWING
C  AND SHADING ALGORITHMS
C
      SAVE
      COMMON /ISOSR5/ NBPW       ,MASK(16)   ,GENDON
      LOGICAL         GENDON
      COMMON /ISOSR7/ IENTRY     ,IONES
      COMMON /ISOSR8/ NMASK(16)  ,IXOLD      ,IYOLD      ,IBTOLD     ,
     1                HBFLAG     ,IOSLSN     ,LRLX       ,IFSX       ,
     2                IFSY       ,FIRST      ,IYDIR      ,IHX        ,
     3                IHB        ,IHS        ,IHV        ,IVOLD      ,
     4                IVAL       ,IHRX       ,YCHANG     ,ITPD       ,
     5                IHF
      COMMON /ISOSR9/ BIG        ,IXBIT
      LOGICAL         YCHANG     ,HBFLAG     ,FIRST      ,IHF
      GENDON = .TRUE.
      NBPW = 16
C
C  GET BIGGEST REAL NUMBER
C
      BIG = R1MACH(2)
C
C  MASKS TO SELECT A SPECIFIC BIT
C
      DO  10 K=1,NBPW
         MASK(K) = ISHIFT(1,K-1)
   10 CONTINUE
C
C  GENERATE  THE BIT PATTERN 177777 OCTAL
C
      ITEMP1 = 0
      ITEMP = MASK(NBPW)
      IST = NBPW-1
      DO  20 K=1,IST
         ITEMP1 = IOR(ITEMP,ISHIFT(ITEMP1,-1))
   20 CONTINUE
      MFIX = IOR(ITEMP1,1)
C
C  MASKS TO CLEAR A SPECIFIC BIT
C
      DO  30 K=1,NBPW
         NMASK(K) = IAND(ITEMP1,MFIX)
         ITEMP1 = IOR(ISHIFT(ITEMP1,1),1)
   30 CONTINUE
      IONES = MFIX
      RETURN
C
C REVISION HISTORY---
C
C JANUARY 1978     DELETED REFERENCES TO THE  *COSY  CARDS AND
C                  ADDED REVISION HISTORY
C JANUARY 1979     NEW SHADING ALGORITHM
C MARCH 1979       MADE CODE MACHINE INDEPENDENT AND CONFORM
C                  TO 66 FORTRAN STANDARD
C JUNE 1979        THIS VERSION PLACED ON ULIB.
C SEPTEMBER 1979   FIXED PROBLEM IN EZISOS DEALING WITH
C                  DETERMINATION OF VISIBILITY OF W PLANE.
C DECEMBER 1979    FIXED PROBLEM WITH PEN DOWN ON CONTOUR
C                  INITIALIZATION IN SUBROUTINE FRSTC
C MARCH            CHANGED ROUTINE NAMES  TRN32I  AND  DRAW  TO
C                  TRN32I  AND  DRAWI  TO BE CONSISTENT WITH THE
C                  USAGE OF THE NEW ROUTINE  PWRZI.
C JUNE  1980       FIXED PROBLEM WITH ZERO INDEX COMPUTATION IN
C                  SUBROUTINE FRSTC.  ADDED INPUT PARAMETER
C                  DIMENSION STATEMENT MISSING IN EZISOS.
C                  FIXED ERROR IN COMPUTATION OF ARCCOSINE
C                  IN EZISOS AND TRN32I.
C DECEMBER 1984    CONVERTED TO GKS LEVEL 0A AND STANDARD FORTRAN 77
C-----------------------------------------------------------------------
C
      END
