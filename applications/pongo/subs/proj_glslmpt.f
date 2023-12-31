      SUBROUTINE PROJ_GLSLMPT( PHI0, THETA0, L, M, PHI, THETA, STATUS )
*+
*  Name:
*     PROJ_GLSLMPT

*  Purpose:
*     Find position for direction cosines in the GLS projection

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL PROJ_GLSLMPT( PHI0, THETA0, L, M, PHI, THETA, STATUS )

*  Description:
*     Uses a GLS projection
*
*     L is assumed to be positive to the east
*     M is assumed to be positive to the north
*
*     Based on the AIPS implementation of these geometries - see
*     AIPS memos 27 & 46 - Eric Greisen.
*

*  Arguments:
*     PHI0 = DOUBLE PRECISION (Given)
*        reference point longitude/right ascension
*     THETA0 = DOUBLE PRECISION (Given)
*        reference point latitude/declination
*     L = DOUBLE PRECISION (Given)
*        direction cosine of displacement east
*     M = DOUBLE PRECISION (Given)
*        direction cosine of displacement north
*     PHI = DOUBLE PRECISION (Returned)
*        longitude/right ascension of point
*     THETA = DOUBLE PRECISION (Returned)
*        latitude/declination of point
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  [optional_subroutine_items]...
*  Authors:
*     JBVAD::PAH: Paul Harrison (STARLINK)
*     PDRAPER: P.W. Draper (STARLINK - Durham University)
*     {enter_new_authors_here}

*  History:
*     24-JAN-1990 (JBVAD::PAH):
*        Original version.
*     3-JUN-1994 (PDRAPER):
*        Removed unused variables.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'ASTRO_PAR'        ! Standard astronomical parameters
      INCLUDE 'PROJ_PAR'         ! parameters for the proj routines

*  Arguments Given:
      DOUBLE PRECISION PHI0, THETA0, L, M

*  Arguments Returned:
      DOUBLE PRECISION PHI, THETA

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      DOUBLE PRECISION COST      ! cosine of theta
      DOUBLE PRECISION PHIT      ! temporary store
      DOUBLE PRECISION THETAT    ! temporary store
      DOUBLE PRECISION AMP       ! L*L+M*M

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

      AMP=L*L+M*M
      STATUS=PROJ__UNDEFINED
      IF ( AMP.LE.D2PI*D2PI/2.5D0 ) THEN
         THETAT=THETA0+M
         IF ( ABS(THETAT).LE.DPI/2 ) THEN
            COST=COS(THETAT)
            IF ( ABS(L).LE.DPI*COST ) THEN
               IF ( COST.GT. PROJ__SMALL ) THEN
                  PHIT=PHI0+L/COST
                  STATUS=SAI__OK
               END IF
            END IF
         END IF
      ELSE
         STATUS=PROJ__BADLM
      END IF

      IF ( STATUS .EQ. SAI__OK ) THEN
         PHI=PHIT
         THETA=THETAT
         IF ( PHI.GT.D2PI ) PHI=PHI-D2PI
         IF ( PHI.LT.0D0 ) PHI=PHI+D2PI
      END IF
      END
