      SUBROUTINE KPG1_WRLST( PARAM, ARRDIM, NPOS, NAX, POS, IFRM, IWCS,
     :                       TITLE, ID0, IDENTS, NULL, STATUS )
*+
*  Name:
*     KPG1_WRLST

*  Purpose:
*     Writes a set of positions to a text file as a CAT catalogue.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_WRLST( PARAM, ARRDIM, NPOS, NAX, POS, IFRM, IWCS, TITLE, 
*                      ID0, IDENTS, NULL, STATUS )

*  Description:
*     This routine saves a set of positions in a text file as a CAT
*     catalogue (see SUN/181). Information describing associated co-ordinate 
*     Frames can also be stored in the file as textual information, allowing 
*     subsequent applications to interpret the positions. Files written with 
*     this routine can be read using KPG1_RDLST (and also XCATVIEW etc).
*
*     The positions are stored in the file in a Frame selected by the 
*     user using hardwired parameters CATFRAME and CATEPOCH. This Frame
*     defaults to a SKY Frame if present, otherwise a PIXEL Frame if present,
*     otherwise the original Base Frame within the supplied FrameSet. The
*     positions can be supplied within any of the Frames in the FrameSet
*     and will be Mapped into the required Frame if necessary.

*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        The name of the parameter to use.
*     ARRDIM = INTEGER (Given)
*        The size of the first dimension of the positions array. This must 
*        be larger than or equal to NPOS.
*     NPOS = INTEGER (Given)
*        The number of positions to store in the file.
*     NAX = INTEGER (Given)
*        The number of axes in the Frame specified by IFRM.
*     POS( ARRDIM, NAX ) = DOUBLE PRECISION (Given)
*        The positions to store in the file. POS( I, J ) should give the
*        axis J value for position I. 
*     IFRM = INTEGER (Given)
*        The index of the Frame within IWCS to which the supplied
*        positions relate. Can be AST__BASE or AST__CURRENT.
*     IWCS = INTEGER (Given)
*        A pointer to an AST FrameSet to store with the positions. 
*     TITLE = CHARACTER * ( * ) (Given)
*        A title to store at the top of the text file. Ignored if blank.
*     ID0 = INTEGER (Given)
*        The integer identifier value to associate with the first
*        supplied position. Identifiers for subsequent positions increase
*        by 1 for each position. If this is supplied less than or equal
*        to zero, then its value is ignored and the identifiers supplied
*        in array IDENTS are used instead.
*     IDENTS( NPOS ) = INTEGER (Given)
*        The individual integer identifiers to associate with each
*        position. Only accessed if ID0 is less than or equal to zero.
*     NULL = LOGICAL (Given)
*        Is the user allowed to supply a null value? If so, the error
*        status will be annulled before returning.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     15-SEP-1998 (DSB):
*        Original version.
*     13-DEC-2001 (DSB):
*        Added facility to specify the Frame in which to store positions
*        in the catalogue.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST constants and function declarations
      INCLUDE 'PAR_ERR'          ! PAR error constants 

*  Arguments Given:
      CHARACTER PARAM*(*)
      INTEGER ARRDIM
      INTEGER NPOS
      INTEGER NAX
      DOUBLE PRECISION POS( ARRDIM, NAX )
      INTEGER IFRM
      INTEGER IWCS
      CHARACTER TITLE*(*)
      LOGICAL NULL
      INTEGER ID0
      INTEGER IDENTS( NPOS )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER CVAL*80          ! Character value obtained for the parameter
      INTEGER CI                 ! CAT identifier
      INTEGER IBASE              ! Index of base Frame 
      INTEGER ICURR              ! Index of current Frame 
      INTEGER IDEF               ! Index of default catalogue Frame 
      INTEGER IPW                ! Pointer to work space
      INTEGER MAP                ! AST Pointer to Mapping
      INTEGER NBAX               ! No. of axes in BASE FRAME
*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Indicate we have not yet changed the Base Frame.
      IBASE = AST__NOFRAME

*  Start an AST context.
      CALL AST_BEGIN( STATUS )

*  Access the catalogue. There is no need to create the positions
*  list is a catalogue cannot be obtained.
      CALL LPG_CATCREAT( PARAM, CI, STATUS )
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_BEGIN( STATUS )
         CALL CAT_TRLSE( CI, STATUS )
         CALL ERR_END( STATUS )
         GO TO 999
      END IF

*  If the input FrameSet has more than 1 Frame, allow the user to select an alternative 
*  base Frame. 
      IF( AST_GETI( IWCS, 'NFRAME', STATUS ) .GT. 1 ) THEN

*  Note the original base and current Frames.
         IBASE = AST_GETI( IWCS, 'BASE', STATUS )
         ICURR = AST_GETI( IWCS, 'CURRENT', STATUS )

*  Make the default Frame the current Frame. If a SKY Frame is available,
*  use it, otherwise if a PIXEL Frame is available, use it, otherwise use
*  the current Base Frame.
         CALL KPG1_ASFFR( IWCS, 'SKY', IDEF,STATUS )
         IF( IDEF .EQ. AST__NOFRAME ) THEN
            CALL KPG1_ASFFR( IWCS, 'PIXEL', IDEF,STATUS )
            IF( IDEF .EQ. AST__NOFRAME ) IDEF = IBASE
         END IF         
         CALL AST_SETI( IWCS, 'CURRENT', IDEF, STATUS )

*  Allow the user to change the current FRAME.
         CALL MSG_SETC( 'A', 'catalogue' )
         CALL KPG1_ASFRM( 'CATFRAME', 'CATEPOCH', IWCS, 'PIXEL', 'AXIS', 
     :                    .TRUE., '^A', STATUS )

*  Set the base Frame equal to the new current Frame, and then re-instate 
*  the original current Frame.
         CALL AST_SETI( IWCS, 'BASE', AST_GETI( IWCS, 'CURRENT', 
     :                                          STATUS ),
     :                  STATUS )
         CALL AST_SETI( IWCS, 'CURRENT', ICURR, STATUS )

*  Get the simplified Mapping from the supplied Frame to the Base Frame.
         MAP = AST_SIMPLIFY( AST_GETMAPPING( IWCS, IFRM, AST__BASE, 
     :                                       STATUS ), STATUS )
 
*  Use a UnitMap if there is only 1 Frame in the FrameSet.
      ELSE
         MAP = AST_UNITMAP( AST_GETI( IWCS, 'NIN', STATUS ), ' ',
     :                      STATUS )
      END IF

*  If the forward transformation is not defined, store the positions in
*  the Frame in which they were supplied. The associated FrameSet contains
*  just the specified Frame.
      IF( .NOT. AST_GETL( MAP, 'TRANFORWARD', STATUS ) ) THEN
         CALL KPG1_WRLS2( PARAM, ARRDIM, NPOS, NAX, POS, 
     :                    AST_FRAMESET( AST_GETFRAME( IWCS, IFRM, 
     :                                                STATUS ), 
     :                                  ' ', STATUS ),
     :                    TITLE, ID0, IDENTS, STATUS )

*  Otherwise, if the Mapping is a UnitMap, we can store the positions as 
*  supplied, with the full FrameSet.
      ELSE IF( AST_ISAUNITMAP( MAP, STATUS ) ) THEN
         CALL KPG1_WRLS2( PARAM, ARRDIM, NPOS, NAX, POS, IWCS,
     :                    TITLE, ID0, IDENTS, STATUS )

*  Otherwise, we need to map the supplied positions into the Base Frame
*  before storing them.
      ELSE

*  Get the number of axes in the Base Frame.
         NBAX = AST_GETI( IWCS, 'NIN', STATUS )

*  Allocate memory to hold the mapped positions.
         CALL PSX_CALLOC( NBAX*NPOS, '_DOUBLE', IPW, STATUS )

*  Abort if an error occurred.
         IF( STATUS .NE. SAI__OK ) GO TO 999

*  Transform the supplied positions into the Base Frame, storing them
*  in the workspace.
         CALL AST_TRANN( MAP, NPOS, NAX, ARRDIM, POS, .TRUE., NBAX, 
     :                   NPOS, %VAL( IPW ), STATUS ) 

*  Put the stored Frame positions into the file.
         CALL KPG1_WRLS2( PARAM, NPOS, NPOS, NBAX, %VAL( IPW ), IWCS,
     :                    TITLE, ID0, IDENTS, STATUS )

*  Free the workspace.
         CALL PSX_FREE( IPW, STATUS )

      END IF

 999  CONTINUE

*  If a null parameter value was supplied, annul the error if a null
*  value is OK. 
      IF( STATUS .EQ. PAR__NULL .AND. NULL ) CALL ERR_ANNUL( STATUS )

*  Re-instate the original base Frame in the FrameSet.
      IF( IBASE .NE. AST__NOFRAME ) CALL AST_SETI( IWCS, 'BASE', IBASE, 
     :                                             STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

*  If we still have a null status, or an abort status, re-report the
*  error with a more friendly message.
      IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         STATUS = PAR__NULL
         CALL MSG_SETC( 'PARAM', PARAM )
         CALL ERR_REP( 'KPG1_WRLST_ERR', 'Aborted attempt to create '//
     :                 'a positions list using parameter %^PARAM.', 
     :                 STATUS )

      ELSE IF( STATUS .EQ. PAR__ABORT ) THEN
         CALL ERR_ANNUL( STATUS )
         STATUS = PAR__ABORT
         CALL MSG_SETC( 'PARAM', PARAM )
         CALL ERR_REP( 'KPG1_WRLST_ERR', 'Aborted attempt to create '//
     :                 'a positions list using parameter %^PARAM.', 
     :                 STATUS )

      ELSE IF( STATUS .NE. SAI__OK ) THEN
         CALL MSG_SETC( 'PARAM', PARAM )
         CALL ERR_REP( 'KPG1_WRLST_ERR2', 'Failed to create a '//
     :                 'positions list using parameter %^PARAM.', 
     :                 STATUS )
      END IF

      END
