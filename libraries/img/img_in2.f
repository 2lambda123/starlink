      SUBROUTINE IMG_IN2( PARAM, NX, NY, IP, STATUS )
*+
*  Name:
*     IMG_IN2

*  Purpose:
*     Obtains access to a 2-dimensional input image.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IMG_IN2( PARAM, NX, NY, IP, STATUS )

*  Description:
*     This routine provides access to a 2-dimensional input image. It
*     returns the size of the image and a pointer to its data, mapped
*     as floating point (REAL) values.

*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        Parameter name (case insensitive).
*     NX = INTEGER (Returned)
*        Size of the first dimension of the image (in pixels).
*     NY = INTEGER (Returned)
*        Size of the second dimension of the image (in pixels).
*     IP = INTEGER (Returned)
*        Pointer to the image data.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - Access to multiple image data can also be provided by this
*     routine. Multiple parameter names are specified by supplying a
*     comma separated list of names (i.e. 'DATA,BIAS,FLAT'). A pointer
*     to the data of each image is then returned (in this case the IP
*     argument should be passed as an array of size at least the number
*     of parameter names). The advantage of obtaining a sequence of
*     images in this manner is that the images are guaranteed to have
*     the same shape (NX and NY) and the same type (REAL).
      
*  Copyright:
*     Copyright (C) 1992, 1994 Science & Engineering Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*     
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*     
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     PDRAPER: Peter Draper (STARLINK - Durham University)
*     {enter_new_authors_here}

*  History:
*     17-FEB-1992 (RFWS):
*        Original version.
*     16-AUG-1994 (PDRAPER):
*        Extended to use multiple parameter names.
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
      INTEGER NY
      INTEGER IP( * )

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL IMG1_OK
      LOGICAL IMG1_OK            ! Test if error status is OK

*  Local Constants:
      INTEGER MXDIM              ! Maximum number of NDF dimensions
      PARAMETER ( MXDIM = 2 )

*  Local Variables:
      INTEGER DIM( MXDIM )       ! NDF dimension sizes

*.

*  Set initial null values for first returned pointer and the
*  dimension sizes.
      IP( 1 ) = IMG__NOPTR
      NX = 1
      NY = 1

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Obtain access to the NDF.
      CALL IMG1_GTNDF( PARAM, '_REAL', .TRUE., MXDIM, DIM, IP, STATUS )

*  Return the dimension sizes (these are the same for all input images).
      NX = DIM( 1 )
      NY = DIM( 2 )

*  If an error occurred, then report a contextual message.
      IF ( .NOT. IMG1_OK( STATUS ) ) THEN
         IF ( INDEX ( PARAM, ',' ) .NE. 0 ) THEN 
            CALL ERR_REP( 'IMG_IN2_ERR',
     :           'IMG_IN2: Error obtaining access to ' //
     :           '2-dimensional input images.', STATUS )
         ELSE
            CALL ERR_REP( 'IMG_IN2_ERR',
     :           'IMG_IN2: Error obtaining access to a ' //
     :           '2-dimensional input image.', STATUS )
         END IF
      END IF

      END
* $Id$
