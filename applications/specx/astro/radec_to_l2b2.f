* History:
*    28-JUL-2000 (AJC):
*       Correct PI to 3.14... (was 3.13...)
*       Use ASIN ATAN2 rather that nonstandard ASIND ATAN2D
*       Change TYPE * to PRINT *
*-----------------------------------------------------------------------

      SUBROUTINE RADEC_TO_L2B2 (RA, DEC, L2, B2)

      IMPLICIT   NONE

*     Formal parameters

      DOUBLE PRECISION RA         ! input R.A. in radians
      DOUBLE PRECISION DEC        ! input Dec. in radians
      DOUBLE PRECISION L2         ! output LII in degrees
      DOUBLE PRECISION B2         ! output bII in degrees

*     Local variables

      DOUBLE PRECISION PI        /3.141592654/
      DOUBLE PRECISION DZEROD    /27.4D0/
      DOUBLE PRECISION RZEROD    /192.25D0/
      DOUBLE PRECISION DZERO, RZERO
      DOUBLE PRECISION SINB
      DOUBLE PRECISION ASINLM33, ACOSLM33
      
*  Ok, go...

      DZERO    = DZEROD * PI/180.
      RZERO    = RZEROD * PI/180.

      SINB     = SIN(DZERO)*SIN(DEC)
     &          + COS(DZERO)*COS(DEC)*COS(RA-RZERO)
      ASINLM33 = SIN(DEC) - SIN(DZERO)*SINB
      ACOSLM33 = COS(DZERO)*COS(DEC)*SIN(RA-RZERO)

      L2       = MOD (ATAN2 (ASINLM33,ACOSLM33) * 180.0D0 / PI +
     &             393.D0, 360.D0)
      B2       = MOD (ASIN (SINB) * 180.0D0 / PI + 90.0D0, 180.D0) -
     &             90.D0

D     PRINT *, ' -- radec_to_l2b2 --'
D     PRINT *, '     R.A., Dec. = ', RA*12/PI, DEC*180./PI
D     PRINT *, '     lII,  bII  = ', L2, B2
D     PRINT *

      RETURN
      END

*-----------------------------------------------------------------------

