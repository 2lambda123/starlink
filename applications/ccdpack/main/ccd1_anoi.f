      SUBROUTINE CCD1_ANOI( IMAGE, NPIX, ADU, STATUS )
*+
*  Name:
*     CCD1_ANOI

*  Purpose:
*     To add poissonian noise to data.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL ANOISE( IMAGE, NPIX, ADU, STATUS )

*  Arguments:
*     IMAGE( NPIX ) = REAL (Given and Returned)
*        The image to which noise is to be added.
*     NPIX = INTEGER (Given)
*        The size of the array image, note that we can handle
*        n-dimensional arrays.
*     ADU = REAL (Returned)
*        The scaling factor to get the values in IMAGE to their counting
*        values.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     4-NOV-1991 (PDRAPER):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! Bad values VAL__BADR

*  Arguments Given:
      INTEGER NPIX
      REAL ADU

*  Arguments Given and Returned:
      REAL IMAGE( NPIX )

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL CCD1_RNORM
      REAL CCD1_RNORM            ! The normal random number routine

*  Local Variables:
      INTEGER I                  ! loop variable
      REAL VALUE
      REAL NOISE

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Doing pseudo-poissonian noise, do each pixel
      DO 2  I = 1, NPIX
         IF( IMAGE( I ) .NE. VAL__BADR ) THEN

*  Scale image value to estimate the real mean.
            VALUE = IMAGE( I ) * ADU

*  Find the noise value for this means standard deviation.
            NOISE = CCD1_RNORM( 0.0, SQRT( ABS( VALUE)  ), STATUS )

*  Scale noise back down.
            NOISE = NOISE / ADU

*  Modify the image value with this noise estimate.
            IMAGE( I ) = IMAGE( I ) + NOISE
         END IF
 2    CONTINUE

      END
* $Id$
