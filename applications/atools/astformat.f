      SUBROUTINE ASTFORMAT( STATUS )
*+
*  Name:
*     ASTFORMAT

*  Purpose:
*     Format coordinate values for a Frame axis

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL ASTFORMAT( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application displays character strings containing the formatted 
*     (character) versions of coordinate values for a Frame axis. The 
*     formatting applied is determined by the Frame's attributes and, in 
*     particular, by any Format attribute string that has been set for the 
*     axis. A suitable default format (based on the Digits attribute value) 
*     will be applied if necessary.

*  Usage:
*     astformat this axis value result

*  ADAM Parameters:
*     THIS = LITERAL (Read)
*        An NDF, FITS file or text file holding the Frame. If an NDF is 
*        supplied, the current Frame of the WCS FrameSet will be used. If a 
*        FITS file is supplied, the Frame corresponding to the primary axis 
*        descriptions will be used.
*     AXIS = INTEGER (Read)
*         The number of the Frame axis for which formatting is to be
*         performed (axis numbering starts at 1 for the first axis).
*     VALUE = GROUP (Read)
*        A comma-separated list of floating point values to be formatted.
*        A text file may be specified by preceeding the name of the file 
*        with an up arrow character "^". If the supplied value ends with a 
*        minus sign, the user is re-prompted for additional values.
*     RESULT = LITERAL (Read)
*        The name of a text file in which to put the formatted axis
*        values. No file is produced if a null (!) value is supplied. One
*        axis value is stored on each line of the file. [!]

*  Copyright:
*     Copyright (C) 2003 Central Laboratory of the Research Councils.
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
*     6-JUN-2003 (DSB):
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
      INCLUDE 'GRP_PAR'          ! GRP constants 
      INCLUDE 'PAR_ERR'          ! PAR error constants 

*  External References:
      EXTERNAL AST_ISAFRAME
      INTEGER CHR_LEN

*  Status:
      INTEGER STATUS

*  Local Variables:
      INTEGER THIS, IGRP, NP
      CHARACTER FNAME*255, BUF*255
      INTEGER I, FD, NC, AXIS
      DOUBLE PRECISION VALUE
      LOGICAL LOG
*.

*  Check inherited status.      
      IF( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Get the Frame.
      CALL ATL_GTOBJ( 'THIS', 'Frame', AST_ISAFRAME, THIS,
     :                 STATUS )

*  Get the axis index.
      CALL PAR_GDR0I( 'AXIS', 1, 1, AST_GETI( THIS, 'NAXES', STATUS ), 
     :                .FALSE., AXIS, STATUS ) 

*  Get a group holding the input axis values.
      IGRP = GRP__NOID
      CALL KPG1_GTGRP( 'VALUE', IGRP, NP, STATUS )

*  If required, open an output text file.
      LOG = .FALSE.
      CALL PAR_GET0C( 'RESULT', FNAME, STATUS )
      IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
      ELSE

*  We delete any pre-existing file first. 
         CALL ATL_RM( FNAME, STATUS )

*  Open a new file and get an FIO identifier for it.
         CALL FIO_OPEN( FNAME, 'WRITE', 'LIST', 132, FD, STATUS )
         IF( STATUS .EQ. SAI__OK ) LOG = .TRUE.

      END IF

*  Loop round the group.
      DO I = 1, NP

*  Get this element.
         CALL GRP_GET( IGRP, I, 1, BUF, STATUS ) 

*  Attempt to convert it to a double.
         CALL CHR_CTOD( BUF, VALUE, STATUS ) 
         IF( STATUS .NE. SAI__OK ) THEN

            CALL ERR_BEGIN( STATUS )               
            CALL GRP_INFOC( IGRP, I, 'NAME', FNAME, STATUS ) 
            CALL ERR_END( STATUS )               

            CALL MSG_SETC( 'C', BUF )
            IF( FNAME .EQ. ' ' ) THEN 
               CALL ERR_REP( 'ASTFORMAT_ERR1', 'Error reading '//
     :                       'string ''^C''.', STATUS )
            ELSE
               CALL MSG_SETC( 'F', FNAME )
               CALL ERR_REP( 'ASTFORMATL_ERR2', 'Error reading '//
     :                       'string ''^C'' in file ^F.', STATUS )
            END IF

         END IF

*  Format the value.
         BUF = AST_FORMAT( THIS, AXIS, VALUE, STATUS )  

*  Display it to the screen.
         CALL MSG_SETC( 'V', BUF )
         CALL MSG_OUT( ' ', '  ^V', STATUS )

*  Write it to the text file if necessary.
         IF( LOG ) CALL FIO_WRITE( FD, BUF( : CHR_LEN( BUF ) ), STATUS )

      END DO

*  Free resources.
      CALL GRP_DELET( IGRP, STATUS )

*  Close the file.
      CALL FIO_ANNUL( FD, STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

*  Give a context message if anything went wrong.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'ASTFORMAT_ERR', 'Error formatting an axis '//
     :                 'value.', STATUS )
      END IF

      END
