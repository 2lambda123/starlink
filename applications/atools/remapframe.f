      SUBROUTINE REMAPFRAME( STATUS )
*+
*  Name:
*     REMAPFRAME

*  Purpose:
*     Modify a Frame's relationship to other Frames in a FrameSet.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL REMAPFRAME( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application modifies the relationship (i.e. Mapping) between a
*     specified Frame in a FrameSet and the other Frames in that FrameSet. 
*
*     Typically, this might be required if the FrameSet has been used to
*     calibrate (say) an image, and that image is re-binned. The Frame 
*     describing the image will then have undergone a coordinate
*     transformation, and this should be communicated to the associated 
*     FrameSet using this routine. 

*  Usage:
*     remapframe this iframe map result

*  ADAM Parameters:
*     IFRAME = LITERAL (Read)
*        The integer index or Domain name of the Frame to be modified within 
*        the FrameSet (the strings AST__BASE and AST__CURRENT may also be 
*        supplied).
*     MAP = LITERAL (Read) 
*        An NDF or text file holding a Mapping whose forward transformation 
*        converts coordinate values from the original coordinate system
*        described by the Frame to the new one, and whose inverse
*        transformation converts in the opposite direction. If an NDF is 
*        supplied, the Mapping from the Base Frame to the Current Frame of 
*        its WCS FrameSet will be used.
*     RESULT = LITERAL (Read)
*        An NDF or text file to receive the modified FrameSet. If an NDF
*        is supplied, the WCS FrameSet within the NDF will be replaced by 
*        the new FrameSet, if possible.
*     THIS = LITERAL (Read)
*        An NDF or text file holding the original FrameSet. If an NDF is 
*        supplied, the WCS FrameSet will be used.

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
      EXTERNAL AST_ISAFRAMESET
      EXTERNAL AST_ISAMAPPING

*  Local Variables:
      INTEGER FRAME
      INTEGER IFRAME
      INTEGER MAP
      INTEGER THIS
*.

*  Check inherited status.      
      IF( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Get a FrameSet.
      CALL ATL1_GTOBJ( 'THIS', 'FrameSet', AST_ISAFRAMESET, THIS, 
     :                 STATUS )

*  Get the index of the Frame.
      CALL ATL1_GTFRM( 'IFRAME', THIS, IFRAME, STATUS )

*  Get the Mapping.
      CALL ATL1_GTOBJ( 'MAP', 'Mapping', AST_ISAMAPPING, MAP, 
     :                 STATUS )

*  Remap the Frame.
      CALL AST_REMAPFRAME( THIS, IFRAME, MAP, STATUS ) 

*  Write the modified FrameSet out.
      CALL ATL1_PTOBJ( 'RESULT', 'THIS', THIS, STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

*  Give a context message if anything went wrong.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'REMAPFRAME_ERR', 'Error re-mapping a Frame '//
     :                 'within a FrameSet.', STATUS )
      END IF

      END
