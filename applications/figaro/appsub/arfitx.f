C+
      SUBROUTINE ARFITX(LINE,CHANS,WAVES,WEIGHTS,NLID,ORDER,RMSX)
C
C     A R F I T X
C
C     Calculates the RMS that would be obtained if a specified line
C     were to be omitted from the fit.
C
C     Parameters -  (">" input, "!" modified, "<" output)
C
C     (>) LINE     (Integer) The number of the line to be omitted.
C                  If LINE is zero, then a fit to all the lines is
C                  performed (which is one way of getting the RMS).
C     (>) CHANS    (Real array CHANS(NLID)) The centers of the
C                  identified lines, in pixel numbers.
C     (>) WAVES    (Real array WAVES(NLID)) The wavelengths of the
C                  identified lines.
C     (>) WEIGHTS  (Real array WEIGHTS(NLMAX)) The weights for the 
C                  identified arc lines.
C     (>) NLID     (Integer) The number of identified lines.
C     (>) ORDER    (Integer) The number of parameters used for the 
C                  fit. (Note: this is the usual meaning of 'order'
C                  plus 1)  This routine assumes that ORDER is not
C                  too large for the number of lines.
C     (<) RMSX     (Real) The RMS error from the fit, in the wavelength
C                  units being used.
C
C                                      KS / AAO 5th Sept 1985
C     Modified:
C
C     30th June 1986  KS / AAO Allows for possibility ORDER>NLID
C+
      IMPLICIT NONE
C
C     Parameters
C
      INTEGER LINE,NLID,ORDER
      REAL CHANS(NLID),WAVES(NLID),WEIGHTS(NLID),RMSX
C
C     Functions
C
      DOUBLE PRECISION GEN_EPOLYD
C
C     Local variables
C
      INTEGER I,NORDER
      REAL ERR,WEIGHT
      DOUBLE PRECISION COEFFS(11)
C
C     Set line weight to zero
C
      IF ((LINE.GT.0).AND.(LINE.LE.NLID)) THEN
         WEIGHT=WEIGHTS(LINE)
         WEIGHTS(LINE)=1.0E-20
      END IF
C
C     Calculate coefficients
C
      NORDER=MIN(NLID,ORDER)
      CALL FIG_WXYFIT(CHANS,WAVES,WEIGHTS,NLID,COEFFS,NORDER-1)
C
C     Calculate rms
C
      RMSX=0.
      DO I=1,NLID
         IF (I.NE.LINE) THEN
            ERR=GEN_EPOLYD(DBLE(CHANS(I)),COEFFS,NORDER)-WAVES(I)
            RMSX=RMSX+ERR*ERR
         END IF
      END DO
      IF (NLID.GT.1) THEN
         RMSX=SQRT(RMSX/FLOAT(NLID-1))
      ELSE
         RMSX=0.
      END IF
C
C     Restore weight
C
      IF ((LINE.GT.0).AND.(LINE.LE.NLID)) WEIGHTS(LINE)=WEIGHT
C
      END
