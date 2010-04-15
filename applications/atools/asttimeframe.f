      SUBROUTINE ASTTIMEFRAME( STATUS )
*+
*  Name:
*     ASTTIMEFRAME

*  Purpose:
*     Create a TimeFrame.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL ASTTIMEFRAME( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application creates a new TimeFrame and optionally initialises
*     its attributes. A TimeFrame is a specialised form of one-dimensional
*     Frame that represents various coordinate systems used to describe
*     moments in time. The particular coordinate system to be used is
*     specified by setting the TimeFrame's System attribute (the default
*     is MJD) qualified, as necessary, by other attributes such as zero
*     point, time scale, units, etc (see the description of the System
*     attribute for details).

*  Usage:
*     asttimeframe options result

*  ADAM Parameters:
*     OPTIONS = LITERAL (Read)
*        A string containing an optional comma-separated list of attribute
*        assignments to be used for initialising the new TimeFrame.
*     RESULT = LITERAL (Read)
*        A text file to receive the new TimeFrame.

*  Copyright:
*     Copyright (C) 2006 Central Laboratory of the Research Councils.
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
*     29-JUN-2006 (DSB):
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

*  Local Variables:
      INTEGER RESULT
*.

*  Check inherited status.
      IF( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Create the required TimeFrame.
      RESULT = AST_TIMEFRAME( ' ', STATUS )

*  Store the required attribute values.
      CALL ATL1_SETOP( 'OPTIONS', RESULT, STATUS )

*  Write the results out to a text file.
      CALL ATL1_PTOBJ( 'RESULT', ' ', RESULT, STATUS )

 999  CONTINUE

*  End the AST context.
      CALL AST_END( STATUS )

*  Give a context message if anything went wrong.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'ASTTIMEFRAME_ERR', 'Error creating a new '//
     :                 'TimeFrame.', STATUS )
      END IF

      END
