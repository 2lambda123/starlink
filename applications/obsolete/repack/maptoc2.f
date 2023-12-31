*+MAPTOC2 Convert map indices to celestial location and roll
	SUBROUTINE MAPTOC2(ILO, ILA, RA, DEC, ROLL)
	IMPLICIT NONE
* Input
	INTEGER		ILO, ILA	! Map indices
* Output
	REAL		RA, DEC		! Map centre (rads)
	REAL		ROLL		! Map roll to North (rads)
*-
* M. Denby Jan-89
	INCLUDE		'CONSTANTS.INC'
	REAL*8		ELONG, ELAT, DRA, DDEC
	REAL*8		NEPRA, NEPDEC
	REAL*8		ELOMAP2, ELAMAP2

	EXTERNAL	ELOMAP2, ELAMAP2

* Get location of N ecl pole
	CALL EC2CEL (0.D0, DBLE(PIBY2), NEPRA, NEPDEC)
	ELONG = ELOMAP2(ILO, ILA)
	ELAT  = ELAMAP2(ILA)
	CALL EC2CEL (ELONG, ELAT, DRA, DDEC)
	RA = REAL(DRA)
	DEC = REAL(DDEC)
	CALL BEARING (RA, DEC, REAL(NEPRA), REAL(NEPDEC), ROLL)

	END
