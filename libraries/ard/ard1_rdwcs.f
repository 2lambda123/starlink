      SUBROUTINE ARD1_RDWCS( NDIM, IGRP, IWCS, STATUS )
*+
*  Name:
*     ARD1_RDWCS

*  Purpose:
*     Attempt to read an AST FrameSet from a group.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL ARD1_RDWCS( NDIM, IGRP, IWCS, STATUS )

*  Description:
*     This routine attempts to read an AST FrameSet from the supplied
*     GRP group. An error is reported if the Object read is not a FrameSet,
*     or if the Current Frame does not have NDIM axes.

*  Arguments:
*     NDIM = INTEGER (Given)
*        The number of axes required in the Current Frame.
*     IGRP = INTEGER (Given)
*        A GRP identifier for the supplied group.
*     IWCS = INTEGER (Returned)
*        An AST pointer to the returned Object. AST__NULL is returned if 
*        an error occurs.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     6-JUL-2001 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST constants and function declarations
      INCLUDE 'ARD_ERR'          ! ARD error constants 
      INCLUDE 'ARD_CONST'        ! ARD provate constants 

*  Arguments Given:
      INTEGER NDIM
      INTEGER IGRP

*  Arguments Returned:
      INTEGER IWCS

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL ARD1_SRCTA
      INTEGER CHR_LEN          

*  Global Variables:
      INCLUDE 'ARD_COM'          ! ARD common blocks.
*        CMN_IGRP = INTEGER (Write)
*           GRP identifier for group holding AST_ data.
*        CMN_NXTLN = INTEGER (Write)
*           Next element to use in group holding AST_ data.

*  Local Variables:
      INTEGER CHAN            ! Pointer to AST Channel for reading catalogue
      INTEGER NAX             ! Number of axes in current Frame

*.

*  Initialise returned pointer.
      IWCS = AST__NULL

*  Check the inherited status. 
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Create an AST Channel through which the text stored in the group can be 
*  read, and converted into an AST Object. The subroutine ARD1_SRCTA 
*  extracts the text from the group, concatenates continuation lines, and 
*  supplies the total line to the AST library. Textual information not 
*  related to AST is skipped over without reporting errors. 
      CHAN = AST_CHANNEL( ARD1_SRCTA, AST_NULL, 'SKIP=1', STATUS )

*  Store the group identifier.
      CMN_IGRP = IGRP

*  Initialise the index of the first element to be read from the group.
      CMN_NXTLN = 1

*  Read an Object from the Channel.
      IWCS = AST_READ( CHAN, STATUS )

*  Annul the Channel.
      CALL AST_ANNUL( CHAN, STATUS )      

*  Report an error if no object was read.
      IF( STATUS .EQ. SAI__OK ) THEN
         IF( IWCS .EQ. AST__NULL ) THEN
            STATUS = ARD__BADAR
            CALL ERR_REP( 'ARD1_RDWCS_ERR1', 'No AST Object could '//
     :                    'be read', STATUS )      

*  Report an error if a non-FrameSet was read.
         ELSE IF( .NOT. AST_ISAFRAMESET( IWCS, STATUS ) ) THEN
            CALL AST_ANNUL( IWCS, STATUS )
            STATUS = ARD__BADAR
            CALL MSG_SETC( 'CL', AST_GETC( IWCS, 'CLASS', STATUS ) )
            CALL ERR_REP( 'ARD1_RDWCS_ERR2', 'An AST ^CL was read but'//
     :                    ' a FrameSet is required.', STATUS )      

*  Report an error if the Current Frame has the wrong number of axes.
         ELSE IF( AST_GETI( IWCS, 'NAXIS', STATUS ) .NE. NDIM ) THEN
            NAX = AST_GETI( IWCS, 'NAXIS', STATUS )
            CALL AST_ANNUL( IWCS, STATUS )

            STATUS = ARD__BADAR
            CALL MSG_SETI( 'NAX', NAX )
            CALL MSG_SETI( 'NDIM', NDIM )

            IF( NDIM .EQ. 1 ) THEN
               CALL MSG_SETC( 'NDIM', ' is' )
            ELSE
               CALL MSG_SETC( 'NDIM', ' are' )
            END IF

            CALL ERR_REP( 'ARD1_RDWCS_ERR3', 'The current Frame in '//
     :                    'the FrameSet has ^NAX axes, but ^NDIM '//
     :                    'required.', STATUS )
         END IF

      END IF

      END
