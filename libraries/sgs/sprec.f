      SUBROUTINE sgs_SPREC (NPR)
*+
*  Name:
*     SPREC

*  Purpose:
*     Select text precision.

*  Language:
*     Starlink Fortran 77

*  Arguments:
*     NPR = INTEGER (Given)
*         Text precision

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
*     sgs_OTEXT, GSTXFP

*  Read From Common:
*     IFONT     i      current font

*  Written To Common:
*     IPREC     i      current text precision

*-

      IMPLICIT NONE

      INTEGER NPR

      INCLUDE 'sgscom'




*  Flush any existing text string
      CALL sgs_OTEXT

*  Save precision
      IPREC=NPR

*  Set font and precision
      CALL GSTXFP(IFONT,NPR)

      END
