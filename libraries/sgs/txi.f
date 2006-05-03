      SUBROUTINE sgs_TXI (X,Y, I, NFI)
*+
*  Name:
*     TXI

*  Purpose:
*     Begin a new text string with a formatted integer.

*  Language:
*     Starlink Fortran 77

*  Description:
*     (In practice, this means simply "plot a formatted integer")

*  Arguments:
*     X = REAL (Given)
*         Position of text string (x)
*     Y = REAL (Given)
*         "     "    "     "   (y)
*     I = INTEGER (Given)
*         Integer to be formatted
*     NFI = INTEGER (Given)
*         Format indicator:-
*         either  number of leading spaces (NFI.GE.0)
*         or  minus the field width (NFI.LT.0)

*  Notes:
*     The field width is limited to 20 characters.

*  Copyright:
*     Copyright (C) 1991 Science & Engineering Research Council. All
*     Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     PTW: P. T. Wallace (Starlink)
*     DLT: D. L. Terrett (Starlink)
*     {enter_new_authors_here}

*  History:
*     14-SEP-1991 (PTW/DLT):
*        Modified.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*  Externals:
*     sgs_BTEXT, sgs_ATXI

*-

      IMPLICIT NONE

      REAL X,Y
      INTEGER I,NFI



*  Begin the new text string
      CALL sgs_BTEXT(X,Y)

*  Format the number onto it
      CALL sgs_ATXI(I,NFI)

      END
