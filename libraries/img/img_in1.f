      SUBROUTINE IMG_IN1( PARAM, NX, IP, STATUS )
*+
*  Name:
*     IMG_IN1

*  Purpose:
*     Obtains access to a 1-dimensional input image.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IMG_IN1( PARAM, NX, IP, STATUS )

*  Description:
*     This routine provides access to a 1-dimensional input image. It
*     returns the size of the image and a pointer to its data, mapped
*     as floating point (REAL) values.

*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        Parameter name (case insensitive).
*     NX = INTEGER (Returned)
*        Size of the image (in pixels).
*     IP = INTEGER (Returned)
*        Pointer to the image data.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - Access to multiple image data can also be provided by this
*     routine. Multiple parameter names are specified by supplying a
*     comma separated list of names (i.e. 'SPEC,ARC'). A pointer to the
*     data of each image is then returned (in this case the IP argument
*     should be passed as an array of size at least the number of
*     parameter names). The advantage of obtaining a sequence of
*     images in this manner is that the images are guaranteed to have
*     the same size (in pixels) and the same type (REAL).

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     PDRAPER: Peter Draper (STARLINK - Durham University)
*     {enter_new_authors_here}

*  History:
*     17-FEB-1992 (RFWS):
*        Original version.
*     16-AUG-1994 (PDRAPER):
*        Extended to multiple parameter names.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'IMG_CONST'        ! IMG_ private constants

*  Arguments Given:
      CHARACTER * ( * ) PARAM

*  Arguments Returned:
      INTEGER NX
      INTEGER IP( * )

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL IMG1_OK
      LOGICAL IMG1_OK            ! Test if error status is OK

*  Local Constants:
      INTEGER MXDIM              ! Maximum number of NDF dimensions
      PARAMETER ( MXDIM = 1 )

*  Local Variables:
      INTEGER DIM( MXDIM )       ! NDF dimension sizes

*.

*  Set initial null values for the returned pointer and dimension
*  size.
      IP( 1 ) = IMG__NOPTR
      NX = 1

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Obtain access to the NDF.
      CALL IMG1_GTNDF( PARAM, '_REAL', .TRUE., MXDIM, DIM, IP, STATUS )

*  Return its dimension size (this is the same for all images).
      NX = DIM( 1 )

*  If an error occurred, then report a contextual message.
      IF ( .NOT. IMG1_OK( STATUS ) ) THEN
         IF ( INDEX( PARAM, ',' ) .NE. 0 ) THEN 
            CALL ERR_REP( 'IMG_IN1S_ERR',
     :           'IMG_IN1: Error obtaining access to 1-dimensional ' //
     :           'input images.', STATUS )
         ELSE
            CALL ERR_REP( 'IMG_IN1_ERR',
     :           'IMG_IN1: Error obtaining access to a ' //
     :           '1-dimensional input image.', STATUS )
         END IF
      END IF
      END
* $Id$
