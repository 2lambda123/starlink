      SUBROUTINE PROJ_CONVLMPT( PROJ, PHI0, THETA0, L, M, PHI, THETA,
     :  STATUS )

*+
*  Name:
*     PROJ_CONVLMPT

*  Purpose:
*     Find direction cosines for position for various projections

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL PROJ_CONVLMPT( PROJ, PHI0, THETA0, L, M, PHI, THETA, STATUS )

*  Description:
*     Uses 
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
*     {enter_new_authors_here}

*  History:
*     24-JAN-1990 (JBVAD::PAH):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'ASTRO_PAR'        ! Standard astronomical parameters
      INCLUDE 'PROJ_PAR'         ! PROJ parameters

*  Arguments Given:
      INTEGER PROJ
      DOUBLE PRECISION PHI0, THETA0, L, M

*  Arguments Returned:
      DOUBLE PRECISION  PHI, THETA

*  Status:
      INTEGER STATUS             ! Global status

                                 ! projection 

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

      IF ( PROJ.LT.1 .OR. PROJ.GT.7 ) THEN
         STATUS = PROJ__NSCHPROJ
         GO TO 1000
      END IF
      
      GO TO ( 10, 20, 30, 40, 50, 60, 70 ), PROJ
 10      CALL PROJ_TANLMPT ( PHI0, THETA0, L, M, PHI, THETA, STATUS ) 
         GOTO 1000
 20      CALL PROJ_SINLMPT ( PHI0, THETA0, L, M, PHI, THETA, STATUS ) 
         GOTO 1000
 30      CALL PROJ_ARCLMPT ( PHI0, THETA0, L, M, PHI, THETA, STATUS ) 
         GOTO 1000
 40      CALL PROJ_GLSLMPT ( PHI0, THETA0, L, M, PHI, THETA, STATUS ) 
         GOTO 1000
 50      CALL PROJ_AITLMPT ( PHI0, THETA0, L, M, PHI, THETA, STATUS ) 
         GOTO 1000
 60      CALL PROJ_MERLMPT ( PHI0, THETA0, L, M, PHI, THETA, STATUS ) 
         GOTO 1000
 70      CALL PROJ_STGLMPT ( PHI0, THETA0, L, M, PHI, THETA, STATUS ) 
         GOTO 1000

*   Put some error messages here
 1000 CONTINUE

      END
