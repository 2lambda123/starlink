*+  SCULIB_COADD - coadd exposure into coadded result
      SUBROUTINE SCULIB_COADD (N, IN_DATA, IN_VARIANCE, IN_QUALITY,
     :   INCOADD_DATA, INCOADD_VAR, INCOADD_QUAL, INCOADD_NUMBER, 
     :   OUTCOADD_DATA, OUTCOADD_VAR, OUTCOADD_QUAL, OUTCOADD_NUMBER,
     :   BADBIT, VARIANCE)
*    Description :
*     This routine coadds the current exposure to the input coadd arrays
*     and puts the result in the output coadd arrays. The input and output
*     arrays can be the same. The coadd result is the average of exposures 
*     that have been input. The coadd variance is calculated from
*     the spread of the input exposures about the mean if more than
*     one exposure has been added in. If only one exposure is
*     available then the coadd variance is set equal to variance on the
*     input data if present, otherwise it is set equal to zero.
*     Input pixels with bad quality are ignored.
*    Invocation :
*     SUBROUTINE SCULIB_COADD (N, IN_DATA, IN_VARIANCE, IN_QUALITY,
*    :   INCOADD_DATA, INCOADD_VAR, INCOADD_QUAL, INCOADD_NUMBER, 
*    :   OUTCOADD_DATA, OUTCOADD_VAR, OUTCOADD_QUAL, OUTCOADD_NUMBER,
*    :   BADBIT, VARIANCE)
*    Parameters :
*     N                       = INTEGER (Given)
*           Number of elements in arrays.
*     IN_DATA (N)             = REAL (Given)
*           data to be added to coadd
*     IN_VARIANCE (N)         = REAL (Given)
*           variance on input data
*     IN_QUALITY (N)          = BYTE (Given)
*           quality on input data
*     INCOADD_DATA (N)        = REAL (Given)
*           Input coadd. 
*     INCOADD_VAR (N)         = REAL (Given)
*           Input coadd variance.
*     INCOADD_QUAL (N)       = BYTE (returned)
*           Input coadd quality.
*     INCOADD_NUMBER (N)      = INTEGER (Given)
*           Number of exposures coadded in input coadd.
*     OUTCOADD_DATA (N)       = REAL (Returned)
*           Output coadd. 
*     OUTCOADD_VAR (N)        = REAL (Returned)
*           Output coadd variance.
*     OUTCOADD_QUAL (N)       = BYTE (returned)
*           Output coadd quality.
*     OUTCOADD_NUMBER (N)     = INTEGER (Returned)
*           Number of exposures coadded in output coadd.
*     BADBIT                  = BYTE (Given)
*           Bad bit mask
*     VARIANCE                = LOGICAL (Given)
*           T if input data has variance associated with it
*    Method :
*    Deficiencies :
*    Bugs :
*    Authors :
*     J.Lightfoot (REVAD::JFL)
*    History :
*     $Id$
*     5-JUL-1994: Renamed from SCUDR_COADD (JFL).
*    endhistory
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'PRM_PAR'
*    Import :
      BYTE BADBIT
      INTEGER N
      REAL IN_DATA (N)
      REAL IN_VARIANCE (N)
      BYTE IN_QUALITY(N)
      REAL INCOADD_DATA (N)
      REAL INCOADD_VAR (N)
      BYTE INCOADD_QUAL (N)
      INTEGER INCOADD_NUMBER (N)
      LOGICAL VARIANCE
*    Import-Export :
*    Export :
      REAL OUTCOADD_DATA (N)
      REAL OUTCOADD_VAR (N)
      BYTE OUTCOADD_QUAL (N)
      INTEGER OUTCOADD_NUMBER (N)
*    Status :
*    External references :
*    Global variables :
*    Local Constants :
*    Local variables :
      INTEGER I                   ! DO loop
      REAL    SUM                 ! sum of data coadded 
      REAL    SUMSQ               ! sum of data squared coadded
*    Internal References :
*    Local data :
*    External functions:
      INCLUDE 'NDF_FUNC'
*-

      DO I = 1, N

         IF (NDF_QMASK(IN_QUALITY(I), BADBIT).AND.
     :        NDF_QMASK(INCOADD_QUAL(I), BADBIT)) THEN

*  good quality input point, 
*  ..recover the sum of the data points and the sum of them squared

            IF (INCOADD_NUMBER(I) .EQ. 1) THEN
               SUM = INCOADD_DATA (I)
               SUMSQ = INCOADD_DATA(I)**2
            ELSE IF (INCOADD_NUMBER(I) .GT. 1) THEN
               SUM = INCOADD_DATA (I) * INCOADD_NUMBER (I)
               SUMSQ = INCOADD_NUMBER (I) * INCOADD_DATA(I)**2 + 
     :            INCOADD_NUMBER(I) * (INCOADD_NUMBER(I)-1) * 
     :            INCOADD_VAR (I)
            ELSE
               SUM = 0.0
               SUMSQ = 0.0
               INCOADD_NUMBER (I) = 0
            END IF

*  ..add in the current exposure

            SUM = SUM + IN_DATA (I)
            SUMSQ = SUMSQ + IN_DATA(I)**2
            OUTCOADD_NUMBER (I) = INCOADD_NUMBER (I) + 1
            OUTCOADD_QUAL (I) = 0

*  ..calculate the new average and variance, set the variance to the variance
*    of the input data if there is any, otherwise set it to zero

            OUTCOADD_DATA (I) = SUM / OUTCOADD_NUMBER (I)
            IF (OUTCOADD_NUMBER(I) .GT. 1) THEN
               OUTCOADD_VAR (I) = 
     :            (SUMSQ - OUTCOADD_NUMBER(I) * OUTCOADD_DATA(I)**2) /
     :            (OUTCOADD_NUMBER(I) * (OUTCOADD_NUMBER(I)-1))
            ELSE 
               IF (VARIANCE) THEN
                  OUTCOADD_VAR (I) = IN_VARIANCE (I)
               ELSE
                  OUTCOADD_VAR (I) = 0.0
               END IF
            END IF
         END IF
      END DO

      END
