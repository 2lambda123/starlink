      SUBROUTINE SET_MAPTITLE (MAP_ROTATED, THETA, POS_ANGLE)

*  Routine to set the X- and Y-axis map titles correctly depending
*  on the state of rotation of the map

      IMPLICIT   NONE

*     Formal parameters:

      LOGICAL    MAP_ROTATED
      REAL       THETA
      REAL       POS_ANGLE

*     Common blocks

      CHARACTER  MAPTIT(3)*11
      CHARACTER  AXTIT(3)*6
      COMMON /TITLES/ MAPTIT, AXTIT

*     Local variables:

      LOGICAL    ROTATE_CUBE

*  Ok, go...

      AXTIT(1) = 'arcsec'
      AXTIT(2) = 'arcsec'

      ROTATE_CUBE = MAP_ROTATED .AND. THETA.NE.0.0

*     (Choose axis titles)

D     TYPE *, ' -- set_maptitle --'
D     TYPE *, '    THETA       = ', THETA
D     TYPE *, '    POS_ANGLE   = ', POS_ANGLE
D     TYPE *, '    MAP_ROTATED = ', MAP_ROTATED
D     TYPE *, '    ROTATE_CUBE = ', ROTATE_CUBE

      IF (           (ROTATE_CUBE .and. POS_ANGLE+THETA.EQ.0.0)
     &     .or. (.NOT.ROTATE_CUBE .and. POS_ANGLE      .EQ.0.0)) THEN
        MAPTIT(1) = 'R.A. offset'
        MAPTIT(2) = 'Dec. offset'
      ELSE
        MAPTIT(1) = 'X    offset'
        MAPTIT(2) = 'Y    offset'
      END IF

      RETURN
      END
