*+  SCULIB_SUBARE - subtract one real array from another into a third
      SUBROUTINE SCULIB_SUBARE (N, ARRAY1, ARRAY2, ARRAY3, Q1DATA,
     :   Q2DATA, Q3DATA, V1DATA, V2DATA, V3DATA, QUALITY, FLAGGED,
     :   VARIANCE)
*    Description :
*     Subtracts two real arrays. Note that any of the arrays may be the same.
*    Invocation :
*     CALL SCULIB_SUBARE (N, ARRAY1, ARRAY2, ARRAY3, Q1DATA,
*    :   Q2DATA, Q3DATA, V1DATA, V2DATA, V3DATA, QUALITY, FLAGGED,
*    :   VARIANCE)
*    Parameters :
*     N            = INTEGER (Given)
*             Number of elements in each array
*     ARRAY1 (N)   = REAL (Given)
*             Input array
*     ARRAY2 (N)   = REAL (Given)
*             Second input array
*     ARRAY3 (N)   = REAL (Returned)
*             Result array.  ARRAY3 = ARRAY1 - ARRAY2
*     Q1DATA (N)   = INTEGER (Given)
*             Quality array for first input array
*     Q2DATA (N)   = INTEGER (Given)
*             Quality array for second input array
*     Q3DATA (N)   = INTEGER (Returned)
*             Quality array for output array
*     V1DATA (N)   = REAL (Given)
*             Variance array for first input array
*     V2DATA (N)   = REAL (Given)
*             Variance array for second input array
*     V3DATA (N)   = REAL (Returned)
*             Variance array for output array
*     QUALITY      = LOGICAL (Given)
*             True if input has quality information
*     FLAGGED      = LOGICAL (Given)
*             True if input has flagged data values
*     VARIANCE     = LOGICAL (Given)
*             True if both input arrays have variance arrays
*    Method :
*    Deficiencies :
*    Bugs :
*    Authors :
*     J.Lightfoot (REVAD::JFL), adapted from GEN_SUBAFE by K.Shortridge
*    History :
*     $Id$
*     25.11.1992: Original version
*    endhistory
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'PRM_PAR'                ! for VAL__BADR
*    Import :
      INTEGER N
      REAL ARRAY1 (N)
      REAL ARRAY2 (N)
      INTEGER Q1DATA (N)
      INTEGER Q2DATA (N)
      REAL V1DATA (N)
      REAL V2DATA (N)
      LOGICAL QUALITY
      LOGICAL FLAGGED
      LOGICAL VARIANCE
*    Import-Export :
*    Export :
      REAL ARRAY3 (N)
      INTEGER Q3DATA (N)
      REAL V3DATA (N)
*    Status :
*    External references :
*    Global variables :
*    Local Constants :
      INTEGER  GOOD, BAD
      PARAMETER (BAD = 1, GOOD = 0)
*    Local variables :
      INTEGER I
*    Internal References :
*    Local data :
*-

*  Handle different quality methods separately.  

      IF (QUALITY) THEN

         DO I = 1, N
            IF ((Q1DATA(I).EQ.GOOD).AND.(Q2DATA(I).EQ.GOOD)) THEN
               Q3DATA (I) = GOOD
               ARRAY3 (I) = ARRAY1 (I) - ARRAY2 (I)
               IF (VARIANCE) THEN
                 V3DATA (I) = V1DATA(I) + V2DATA(I)
               END IF
            ELSE
               Q3DATA (I) = BAD
            END IF
         END DO

      ELSE IF (FLAGGED) THEN

         DO I = 1, N

            IF ((ARRAY1(I) .NE. VAL__BADR) .AND.
     :          (ARRAY2(I) .NE. VAL__BADR)) THEN
               ARRAY3 (I) = ARRAY1 (I) - ARRAY2 (I)
               IF (VARIANCE) THEN
                 V3DATA (I) = V1DATA(I) + V2DATA(I)
               END IF
            ELSE
               ARRAY3 (I) = VAL__BADR
            END IF
         END DO

      ELSE

         IF (VARIANCE) THEN
            DO I = 1, N
               ARRAY3 (I) = ARRAY1 (I) - ARRAY2 (I)
               V3DATA (I) = V1DATA (I) + V2DATA (I)
            END DO
         ELSE
            DO I = 1, N
               ARRAY3 (I) = ARRAY1 (I)- ARRAY2 (I)
            END DO
         END IF

      END IF

      END
