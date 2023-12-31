!
!   SUBROUTINE IHROT
!
!  SMOOTHING USING FUNCTION FOR ROTATIONAL CONVOLUTION
!   (DOES NOT ASSUME REGULAR 'Y' INTERVALS)
!
!   IMPORTS:
!     WAVE     (REAL)  ARRAY OF 'Y' VALUES
!     WORK     (REAL)  ARRAY OF 'X' VALUES
!     NPNTS    (INTEGER)  SIZE OF (WAVE, WORK, FLUX) ARRAYS
!     VEL    (REAL)  ROTATIONAL VELOCITY
!
!   EXPORTS:
!     FLUX     (REAL)  ARRAY OF SMOOTHED 'X' VALUES
!
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++!
       SUBROUTINE IHROT
     : (WAVE,FLUX,WORK,NPNTS,NTEST,TSTVAL,VEL)
!
!
!   DECLARATIONS
!
!
       IMPLICIT NONE
!
!
       INTEGER I, J
       INTEGER JSTART, J1
       INTEGER NPNTS
       INTEGER NTEST
!
!
       REAL WAVE(NPNTS), WORK(NPNTS), FLUX(NPNTS)
       REAL VEL, SIG3
       REAL FLUXI, WTI, WV, W1, W2
       REAL GAUSWT, WTGAUS
       REAL WAV1, WAVN
       REAL W0, SIG, WX
       REAL VSINI       ! WTROT
       REAL TSTVAL
!
!
       LOGICAL JTST

       CHARACTER*1 BLEEP
       COMMON /BLEEP/ BLEEP
!
!
! STATEMENT FUNCTION FOR ROTATIONAL CONVOLUTION
!
!       WTROT (W0,VSINI,WX) = (-95427.1/(WX*VSINI))*(SQRT(
!     +        1.0-((299793.0/VSINI)*(WX/W0-1.0))**2.0) +
!     + 1.1781*(1.0-((299793.0/VSINI)*(WX/W0-1.0))**2.0))
!
!   INITIALISATIONS
!
!

        WRITE (*,
     :  '(''   STAROT:  not implemented in this version of DIPSO'',A)')
     :  BLEEP

        END
