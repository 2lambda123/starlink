      SUBROUTINE IMG_NHD( PARAM, EXTEN, N, STATUS )
*+
* Name:
*    IMG_NHD

*  Purpose:
*    Returns the number of header items in an extension. 

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IMG_NHD( PARAM, EXTEN, N, STATUS )

*  Description:
*     This routine determines the number of header items in the named
*     extension. The number returned can be used as an upper limit when
*     indexing using IMG_RHDN.

*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        Parameter name (case insensitive).
*     EXTEN = CHARACTER * ( * ) (Given)
*        The name of the extension.
*     N = INTEGER (Returned)
*        The number of header items in the extension.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - This routine may be used to query the number of items in the
*     same extension of more than one image dataset at a time by using
*     multiple parameter names. Multiple parameter names are provided
*     as a comma separated list (i.e. 'IN1,IN2,IN3'). Note the
*     extension must exist in all images and that the argument N must
*     be declared as a dimension of size at least the number of
*     parameters in the list, if this option is used.

*  Copyright:
*     Copyright (C) 1994 Science & Engineering Research Council.
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
*     PDRAPER: Peter Draper (STARLINK - Durham University)
*     {enter_new_authors_here}

*  History:
*     10-AUG-1994 (PDRAPER):
*        Original version.
*     19-AUG-1994 (PDRAPER):
*        Extended to use multiple parameter names.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'IMG_CONST'        ! IMG_ parameters
      INCLUDE 'IMG_ERR'          ! IMG_ error codes
      
*  Arguments Given:
      CHARACTER * ( * ) PARAM
      CHARACTER * ( * ) EXTEN
      
*  Arguments Returned:
      INTEGER N( * )

*  Status:
      INTEGER STATUS             ! Global status
      
*  External References:
      EXTERNAL CHR_SIMLR
      LOGICAL CHR_SIMLR          ! Strings are the same apart from case

*  Local Variables:
      CHARACTER * ( 1 ) ITEM     ! Dummy item name
      CHARACTER * ( IMG__SZPAR ) VPAR ! Validated parameter name
      INTEGER ESLOT              ! Extension slot number
      INTEGER F                  ! First character position
      INTEGER I1                 ! Position of start of field
      INTEGER I2                 ! Position of end of field
      INTEGER L                  ! Last character positiong
      INTEGER NPAR               ! Number of parameters
      INTEGER SLOT               ! Parameter slot number
      LOGICAL WASNEW             ! Dummy
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
      
*  Initialise the parameter count.
      NPAR = 0

*  Initialise the character pointer to the start of the parameter list.
*  Then loop to extract each element from the list.
      I1 = 1
 1    CONTINUE                   ! Start of "DO WHILE" loop
      IF ( ( STATUS .EQ. SAI__OK ) .AND. ( I1 .LE. LEN( PARAM ) ) )
     :     THEN

*  Find the final character of the next element in the parameter list
*  (the last character before a comma or end of string).
         I2 = INDEX( PARAM( I1 : ), ',' )
         IF ( I2 .EQ. 0 ) THEN
            I2 = LEN( PARAM )
         ELSE
            I2 = I2 + I1 - 2
         END IF
         IF ( I2 .GE. I1 ) THEN

*  Locate the first and last non-blank characters in the element,
*  checking that it is not entirely blank.
            CALL CHR_FANDL( PARAM( I1 : I2 ), F, L )
            IF ( L .GE. F ) THEN
               F = F + I1 - 1
               L = L + I1 - 1

*  Increment the parameter count.
               NPAR = NPAR + 1

*  Validate the parameter and its slot number.
               CALL IMG1_VPAR( PARAM( F: L ), VPAR, STATUS )
               CALL IMG1_GTSLT( VPAR, .FALSE., SLOT, WASNEW, STATUS )
               IF ( STATUS .EQ. SAI__OK ) THEN

*  Initialise IMG to read the extension (if not already doing so).
                  CALL IMG1_EXINI( SLOT, EXTEN, .FALSE., ESLOT, STATUS )

*  Now branch according to the "type" of extension which we are dealing
*  with. FITS requires its own methods.
                  IF ( CHR_SIMLR( 'FITS', EXTEN ) ) THEN
                     CALL IMG1_NMFT( SLOT, ESLOT, N( NPAR ), STATUS )
                  ELSE
                     N( NPAR ) = -1
                     CALL IMG1_NEX( SLOT, ESLOT, N( NPAR ), ITEM,
     :                              STATUS )
                  END IF
               END IF
            END IF
         END IF

*  Increment the character pointer to the start of the next element in
*  the parameter list and return to process the next element.
         I1 = I2 + 2
         GO TO 1
      END IF

*  If no error has occurred, but no non-blank parameter names have been
*  processed, then report an error.
      IF ( ( STATUS .EQ. SAI__OK ) .AND. ( NPAR .EQ. 0 ) ) THEN
         STATUS = IMG__PARIN
         CALL ERR_REP( 'IMG_RDHD<T>_NOPAR',
     :        'No parameter name specified (possible ' //
     :        'programming error).', STATUS )
      END IF
      END
* $Id$
