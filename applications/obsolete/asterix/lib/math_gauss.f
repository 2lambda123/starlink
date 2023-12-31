*+  MATH_GAUSS - Returns Gaussian distributed value with given mean & std deviation
	REAL FUNCTION MATH_GAUSS(XMEAN,SIGMA)
*    Description :
*     Returns Gaussian distributed variable with mean XMEAN and Std devn SIGMA
*    Method :
*     Uses NAG routines
*    Deficiencies :
*    Bugs :
*    Authors :
*
*     Doug Bertram (BHVAD::DB)
*     David J. Allan (JET-X, University of Birmingham)
*     Richard Beard (ROSAT, University of Birminggam)
*
*    History :
*
*     10 Aug 90 : Original (adapted from MATH_POISS) (DB)
*     10 Jun 94 : Converted internals to double precision (DJA)
*      6 Jun 97 : Convert to PDA (RB)
*     22 Jun 98 : Make seed varry every second and with PID (RB)
*
*    Type Definitions :
*
      IMPLICIT NONE
*
*    Import :
*
      REAL			XMEAN			! Mean value
      REAL 			SIGMA
*
*    External references :
*
      REAL			PDA_RNNOR
        EXTERNAL		  PDA_RNNOR
*
*    Local variables :
*
      LOGICAL			INITIALISE		! True if first call
        SAVE			INITIALISE

      INTEGER			SEED, TICKS, PID, STATUS
*
*    Local data :
*
      DATA			INITIALISE /.TRUE./
*-

*    Initialise random number generator if necessary
      IF ( INITIALISE ) THEN
        STATUS = 0
        CALL PSX_TIME( TICKS, STATUS )
        CALL PSX_GETPID( PID, STATUS )
        SEED = 1000 * (( TICKS / 4 ) / 1000 ) + 4 * MOD( TICKS, 1000 )
     :                                        + 4 * MOD( PID, 1000 )
	IF ( MOD( SEED, 2 ) .EQ. 0 ) SEED = SEED + 1
        CALL PDA_RNSED( SEED )
	INITIALISE=.FALSE.
      END IF

      MATH_GAUSS = PDA_RNNOR ( XMEAN, SIGMA )

      END
