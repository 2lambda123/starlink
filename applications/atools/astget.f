      SUBROUTINE ASTGET( STATUS )
*+
*  Name:
*     ASTGET

*  Purpose:
*     Get an attribute value for an Object.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL ASTGET( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application displays the formatted value of a specified attribute 
*     of an Object, and also writes it to an output parameter.

*  Usage:
*     astget this attrib 

*  ADAM Parameters:
*     ATTRIB = LITERAL (Read)
*        A string containing the name of the required attribute.
*     THIS = LITERAL (Read)
*        An NDF or text file holding the Object. If an NDF is supplied, 
*        the WCS FrameSet will be used.
*     VALUE = LITERAL (Write)
*        On exit, this holds the formatted value of the attribute.

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
      CALL ATL1_GTOBJ( 'THIS', ' ', AST_NULL, THIS, STATUS )

*  Get the name of the attribute.
      CALL PAR_GET0C( 'ATTRIB', ATTRIB, STATUS )

*  Get the attribute value, as a character string.
      VAL = AST_GETC( THIS, ATTRIB, STATUS )

*  Display it.
      CALL MSG_SETC( 'V', VAL )
      CALL MSG_OUT( 'ASTGET_MSG1', '^V', STATUS )

*  Store it in an output parameter.
      CALL PAR_PUT0C( 'VALUE', VAL( : MAX( 1, CHR_LEN( VAL ) ) ), 
     :                STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

*  Give a context message if anything went wrong.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'ASTGET_ERR', 'Error getting an attribute '//
     :                 'value from an AST Object.', STATUS )
      END IF

      END
