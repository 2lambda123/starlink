      SUBROUTINE HDR_IN( PARAM, XNAME, ITEM, COMP, VALUE, STATUS )
*+
*  Name:
*    HDR_IN

*  Purpose:
*     Reads a header item.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL HDR_IN( PARAM, XNAME, ITEM, COMP, VALUE, STATUS )

*  Description:
*     This routine returns the value of a header item as a character
*     string. Header items include both FITS header records and package
*     specific extension information. The values of FITS header records
*     are extracted by setting the XNAME argument to the value 'FITS'
*     (or ' ').

*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        Parameter name of the image (case insensitive).
*     XNAME = CHARACTER * ( * ) (Given)
*        Name of the extension ('FITS' or ' ' for FITS headers).
*     ITEM = CHARACTER * ( * ) (Given)
*        Name of the header item.
*     COMP = INTEGER (Given)
*        The component of a multiple FITS header item ('HISTORY' and
*        'COMMENT' items often have many occurrences). The number of
*        components may be queried using the HDR_NUMB routine.
*     VALUE = CHARACTER * ( * ) (Given and Returned)
*        The value. This is  unmodified if the item doesn't exist.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - Item names for any extension type may be hierarchical
*     (i.e. ING.DETHEAD gets the FITS header "ING DETHEAD";
*     BOUNDS.MAXX gets the value of the MAXX component of the BOUNDS
*     structure in a non-FITS extension).
*
*     - This routine may be used to read the value of an item in
*     the same extension of more than one image dataset at a time by
*     using multiple parameter names. Multiple parameter names are
*     provided as a comma separated list (i.e. 'IN1,IN2,IN3'). Note the
*     extension must exist in all images and that the argument VALUE
*     must be declared as a dimension of size at least the number of
*     parameters in the list, if this option is used.
*
*     - If a header item is not found its associated element of the
*     VALUE argument will remain unchanged. It is therefore important
*     that suitable defaults are assigned to VALUE before calling this
*     routine. The extension, however, must exist.
*
*     - If the image is not already open then this routine will open it
*     for read only access. If you intend to modify any extension items
*     then you should call HDR_MOD before this routine.

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
*     12-SEP-1994 (PDRAPER):
*        Original version.
*     15-NOV-1994 (PDRAPER):
*        Changed to use character instead of real.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      CHARACTER * ( * ) PARAM
      CHARACTER * ( * ) XNAME
      CHARACTER * ( * ) ITEM
      INTEGER COMP

*  Arguments Returned:
      CHARACTER * ( * ) VALUE( * )

*  Status:
      INTEGER STATUS             ! Global status
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Just call the correct generic form of this routine.
      CALL HDR_INC( PARAM, XNAME, ITEM, COMP, VALUE, STATUS )
      END
* $Id$
