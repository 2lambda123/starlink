      SUBROUTINE sgs_ARC (XCENT,YCENT, RADIUS, START,FINISH)
*+
*   - - - -
*    A R C
*   - - - -
*
*   Plot an arc of a circle.
*
*   This routine forms a polyline approximation which, in cases where
*   the arc passes close to a clipping boundary, may suffer clipping at
*   a vertex.
*
*   Given:
*      XCENT,YCENT   r   centre (world coordinates)
*      RADIUS        r   radius (world coordinates)
*      START         r   start angle (radians)
*      FINISH        r   finish angle (radians)
*
*   Externals:
*      sgs_IDUN, sgs_BPOLY, sgs_APOLY
*
*   P.T.Wallace, D.L.Terrett   Starlink   14 September 1991
*-

      IMPLICIT NONE

      REAL XCENT,YCENT,RADIUS,START,FINISH

      REAL R,XU,YU,PLTINC,DTHETA,ANGLE,THETA,X,Y
      INTEGER NSTEPS,I



*  Total angle to be plotted
      ANGLE = FINISH-START

*  Get the plotting increments in x & y
      CALL sgs_IDUN(XU,YU)

*  Pick the finer
      PLTINC = MIN(XU,YU)

*  Angle increment for error less than about PLTINC/8
      R = ABS(RADIUS)
      IF (ABS(PLTINC).GT.0.0) THEN
         DTHETA = MAX(0.001,MIN(0.1,ATAN2(SQRT(2.0*PLTINC),R)))
      ELSE
         DTHETA = 0.01
      END IF
      DTHETA = SIGN(DTHETA,ANGLE)

*  Number of lines in polyline approximation
*  (constrain to zero mod 4 for symmetrical circles)
      NSTEPS = 4*(INT((ANGLE/4.0+DTHETA)/DTHETA))

*  Regularise polygon approximation
      DTHETA = ANGLE/REAL(NSTEPS)

*  Adjust radius to improve polygon approximation
      R = RADIUS*(1.0+DTHETA*DTHETA/16.0)

*
*  PLOT
*  ----
*
      DO 10 I = 0,NSTEPS

*     New X,Y
         THETA = START+REAL(I)*DTHETA
         IF (START.LE.FINISH) THEN
            THETA = MIN(FINISH,THETA)
         ELSE
            THETA = MAX(FINISH,THETA)
         END IF
         X = R*COS(THETA)+XCENT
         Y = R*SIN(THETA)+YCENT

*     Append new line to polyline
         IF (I.EQ.0) THEN
            CALL sgs_BPOLY(X,Y)
         ELSE
            CALL sgs_APOLY(X,Y)
         END IF

   10 CONTINUE

      END
