      SUBROUTINE KPG1_COPYC( NEL, IN, OUT, STATUS )
*+
*  Name:
*     KPG1_COPYC

*  Purpose:
*     Copies a one-dimensional array of character strings.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_COPYC( NEL, IN, OUT, STATUS )

*  Description:
*     This routine copies a one-dimensional array of character strings
*     from an inmput to an output array.

*  Arguments:
*     NEL = INTEGER (Given)
*        The length of the array.
*     IN = CHARACTER( NEL ) * ( * ) (Given)
*        The input array.
*     OUT = CHARACTER( NEL ) * ( * ) (Returned)
*        The output array.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 2008 Science & Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either Version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
*     02110-1301, USA.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     21-JAN-2008 (DSB):
*        Original version.
*     20-FEB-2020 (DSB):
*        Call 8-byte version to do the work.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      INTEGER NEL
      CHARACTER IN( NEL )*(*)

*  Arguments Returned:
      CHARACTER OUT( NEL )*(*)

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER*8 NEL8
*.

*  Convert INTEGER to INTEGER*8 and call the 8-byte version.
      NEL8 = NEL
      CALL KPG1_COPYC8( NEL8, IN, OUT, STATUS )

      END
