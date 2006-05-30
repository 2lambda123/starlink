      SUBROUTINE ASTSET( STATUS )
*+
*  Name:
*     ASTSET

*  Purpose:
*     Set an attribute value for an Object.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL ASTSET( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application sets a specified attribute value for an Object.

*  Usage:
*     astset this attrib value result

*  ADAM Parameters:
*     ATTRIB = LITERAL (Read)
*        A string containing the name of the attribute.
*     RESULT = LITERAL (Read)
*        An NDF or text file to receive the modified Object. If an NDF
*        is supplied, the WCS FrameSet within the NDF will be replaced by 
*        the new Object if possible (if it is a FrameSet in which the base 
*        Frame has Domain GRID and has 1 axis for each NDF dimension).
*     THIS = LITERAL (Read)
*        An NDF or text file holding the original Object. If an NDF is 
*        supplied, the WCS FrameSet will be used.
*     VALUE = LITERAL (Read)
*        The formatted value to assign to the attribute.

*  Copyright:
*     Copyright (C) 2001 Central Laboratory of the Research Councils.
*     All Rights Reserved.

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
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     12-JAN-2001 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
*  Type Definitions:
      IMPLICIT NONE              ! no default typing allowed

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST constants and function declarations

*  Status:
      INTEGER STATUS

*  External References:
      INTEGER CHR_LEN

*  Local Variables:
      CHARACTER ATTRIB*30
      CHARACTER VAL*255
      INTEGER THIS
*.

*  Check inherited status.      
      IF( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Get an Object.
      CALL ATL_GTOBJ( 'THIS', ' ', AST_NULL, THIS, STATUS )

*  Get the name of the attribute.
      CALL PAR_GET0C( 'ATTRIB', ATTRIB, STATUS )

*  Get the new value for the attribute.
      CALL PAR_GET0C( 'VALUE', VAL, STATUS )

*  Store the new attribute value.
      CALL AST_SETC( THIS, ATTRIB, VAL( : MAX( 1, CHR_LEN( VAL ) ) ), 
     :               STATUS )

*  Write the modified Object out to a text file.
      CALL ATL1_PTOBJ( 'RESULT', 'THIS', THIS, STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

*  Give a context message if anything went wrong.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'ASTSET_ERR', 'Error setting an attribute '//
     :                 'value for an AST Object.', STATUS )
      END IF

      END
