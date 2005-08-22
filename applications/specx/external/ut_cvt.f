C  History:
C     20 SEP 2000 (AJC):
C        Unused RARAD, DECRAD
*-----------------------------------------------------------------------

      SUBROUTINE EXTRNL2 (ERROR)

*  Temporary routine to allow you to access the UT in a form that can
*  be plotted against other parameters:

      IMPLICIT  NONE

*     Formal parameter

      INTEGER*4 ERROR

*     Include files

      INCLUDE 'STACKCOMM'
      INCLUDE 'FLAGCOMM'

*     Local variables

      INTEGER*4 ISTAT
      LOGICAL*4 TSYMS_OK
      REAL*4    HOUR_ANGLE
      REAL*8    AZ8,   EL8
      REAL*8    L2,    B2
      REAL*8    UTD, JULIAN_DATE, SIDEREAL_TIME
      REAL*8    PI

      DATA      TSYMS_OK  /.FALSE./
      DATA      PI /3.141592654D0/ 

      SAVE      HOUR_ANGLE, UTD, JULIAN_DATE, SIDEREAL_TIME, TSYMS_OK

*  Ok, go..

*     In case it doesn't already exist, make an entry in the symbol
*     table for the numbers. Assume any error is because it exists already

      IF (.NOT. TSYMS_OK) THEN
        CALL GEN_MAKESYMB ('HOUR_ANGLE',    'R4', 1,
     &                      %LOC(HOUR_ANGLE),    ISTAT)
        CALL GEN_MAKESYMB ('UT',            'R8', 1,
     &                      %LOC(UTD),           ISTAT)
        CALL GEN_MAKESYMB ('JULIAN_DATE',   'R8', 1,
     &                      %LOC(JULIAN_DATE),   ISTAT)
        CALL GEN_MAKESYMB ('GLATITUDE',     'R8', 1,
     &                      %LOC(B2),            ISTAT)
        CALL GEN_MAKESYMB ('GLONGITUDE',    'R8', 1,
     &                      %LOC(L2),            ISTAT)
        TSYMS_OK = .TRUE.
      END IF

      ISTAT = 0

      CALL ASTRO_TIMES (ITIME, IDATE, ALONG, TIMCOR, IUTFLG,
     &                  UTD, SIDEREAL_TIME, JULIAN_DATE)

      HOUR_ANGLE = MOD (SIDEREAL_TIME - RA/15., 24.D0)     ! HA in hours

      CALL ASTRO_TIMES (ITIME, IDATE, ALONG, TIMCOR, IUTFLG,
     &                  UTD, SIDEREAL_TIME, JULIAN_DATE)

*     Astronomical coordinates...

      CALL HADEC_TO_AZEL (HOUR_ANGLE*PI/12.,  DEC*PI/180., PI*ALAT/180.,
     &                    AZ8,                EL8)
      CALL RADEC_TO_L2B2 (RA*PI/180.,         DEC*PI/180.,  L2, B2)

      AZ = AZ8 * 180./PI
      EL = EL8 * 180./PI
 
      RETURN
      END

*-----------------------------------------------------------------------
