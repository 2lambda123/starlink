      SUBROUTINE ASTFRAMESET( STATUS )
*+
*  Name:
*     ASTFRAMESET

*  Purpose:
*     Create a FrameSet.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL ASTFRAMESET( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application creates a new FrameSet and optionally initialises
*     its attributes. A FrameSet consists of a set of one or more
*     Frames (which describe coordinate systems), connected together by
*     Mappings (which describe how the coordinate systems are inter-related). 
*     A FrameSet makes it possible to obtain a Mapping between any pair of 
*     these Frames (i.e. to convert between any of the coordinate systems 
*     which it describes). The individual Frames are identified within the
*     FrameSet by an integer index, with Frames being numbered consecutively 
*     from one as they are added to the FrameSet. 
*
*     Every FrameSet has a "base" Frame and a "current" Frame (which are
*     allowed to be the same). Any of the Frames may be nominated to hold 
*     these positions, and the choice is determined by the values of the 
*     FrameSet's Base and Current attributes, which hold the indices of the 
*     relevant Frames. By default, the first Frame added to a FrameSet is 
*     its base Frame, and the last one added is its current Frame. 
*
*     The base Frame describes the "native" coordinate system of whatever
*     the FrameSet is used to calibrate (e.g. the pixel coordinates of an 
*     image) and the current Frame describes the "apparent" coordinate system 
*     in which it should be viewed (e.g. displayed, etc.). Any further 
*     Frames represent a library of alternative coordinate systems, which 
*     may be selected by making them current. 
*
*     When a FrameSet is used in a context that requires a Frame, (e.g.
*     obtaining its Title value, or number of axes), the current Frame 
*     is used. A FrameSet may therefore be used in place of its current 
*     Frame in most situations. 
*
*     When a FrameSet is used in a context that requires a Mapping, the
*     Mapping used is the one between its base Frame and its current 
*     Frame. Thus, a FrameSet may be used to convert "native" coordinates 
*     into "apparent" ones, and vice versa. Like any Mapping, a FrameSet 
*     may also be inverted (see AST_INVERT), which has the effect of 
*     interchanging its base and current Frames and hence of reversing 
*     the Mapping between them. 

*  Usage:
*     astframeset frame options result

*  ADAM Parameters:
*     FRAME = LITERAL (Read) 
*        An NDF or text file holding the first Frame to be inserted into
*        the FrameSet. This initially becomes both the base and the current
*        Frame. (Further Frames may be added using the addframe). If an NDF 
*        is supplied, the current Frame in its WCS FrameSet will be used.
*     OPTIONS = LITERAL (Read)
*        A string containing an optional comma-separated list of attribute 
*        assignments to be used for initialising the new FrameSet. 
*     RESULT = LITERAL (Read)
*        An NDF or text file to receive the new FrameSet. If an NDF is
*        supplied, the WCS FrameSet within the NDF will be replaced by 
*        the new FrameSet, if possible.

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
      INCLUDE 'NDF_PAR'          ! NDF constants
      INCLUDE 'AST_PAR'          ! AST constants and function declarations

*  Status:
      INTEGER STATUS

*  External References:
      EXTERNAL AST_ISAFRAME

*  Local Variables:
      INTEGER RESULT
      INTEGER FRAME
*.

*  Check inherited status.      
      IF( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Get a Frame.
      CALL ATL1_GTOBJ( 'FRAME', 'Frame', AST_ISAFRAME, FRAME, 
     :                 STATUS )

*  Create the required FrameSet.
      RESULT = AST_FRAMESET( FRAME, ' ', STATUS )

*  Store the required attribute values.
      CALL ATL1_SETOP( 'OPTIONS', RESULT, STATUS )

*  Write the results out to a text file.
      CALL ATL1_PTOBJ( 'RESULT', ' ', RESULT, STATUS )

 999  CONTINUE

*  End the AST context.
      CALL AST_END( STATUS )

*  Give a context message if anything went wrong.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'ASTFRAMESET_ERR', 'Error creating a new '//
     :                 'FrameSet.', STATUS )
      END IF

      END
