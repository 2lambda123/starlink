      SUBROUTINE NDG1_HNDLR( EVNAME, EVTEXT, STATUS )
*+
*  Name:
*     NDG1_HNDLR

*  Purpose:
*     Handle an NDF event.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDG1_HNDLR( EVNAME, EVTEXT, STATUS )

*  Description:
*     NDG_BEGPV registers this routine with the NDF library as an event
*     handler to be called whenever an NDF is opened or closed, or has
*     its data array mapped for read or update access.

*  Arguments:
*     EVNAME = CHARACTER * ( * ) (Given)
*        The type of NDF event that has occurred.
*     EVTEXT = CHARACTER * ( * ) (Given)
*        Descriptive information associated with the event. This will 
*        usually be the path to the file that was opened, closed, etc.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 2007-2008 Science & Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This programme is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either Version 2 of
*     the License, or (at your option) any later version.
*     
*     This programme is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE.  See the GNU General Public License for more details.
*     
*     You should have received a copy of the GNU General Public License
*     along with this programme; if not, write to the Free Software
*     Foundation, Inc., 59, Temple Place, Suite 330, Boston, MA
*     02111-1307, USA.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1-NOV-2007 (DSB):
*        Original version.
*     2-JUN-2008 (DSB):
*        Use a pair of AST KeyMaps to hold the NDF names rather than a
*        pair of GRP groups (avoids the need to purge duplicate NDF
*        names, which can be very slow for large numbers of NDFs).
*     1-SEP-2008 (DSB):
*        Record each input NDF that is mapped for read or update access.
*     3-AUG-2009 (DSB):
*        Ensure a re-opened output NDF is not treated as an input NDF.
*     15-OCT-2009 (DSB):
*        Add handler for DEF_HISTORY event.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST constants and functions
      INCLUDE 'NDF_PAR'          ! NDF constants 
      INCLUDE 'GRP_PAR'          ! GRP constants 
      INCLUDE 'DAT_PAR'          ! DAT constants 

*  Global Variables:
      INTEGER RDKMP              ! KeyMap holding input NDFs
      INTEGER WRKMP              ! KeyMap holding output NDFs
      INTEGER MPKMP              ! KeyMap holding mapped NDFs
      COMMON /NDG_PRV/ RDKMP, WRKMP, MPKMP

      INTEGER DHKMP              ! KeyMap holding NDF to which default 
                                 ! history has been written.
      INTEGER GHKMP              ! KeyMap holding GRP group contents
      COMMON /NDG_GH/ GHKMP, DHKMP

*  Arguments Given:
      CHARACTER EVNAME*(*)
      CHARACTER EVTEXT*(*)

*  Status:
      INTEGER STATUS             ! Global status

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  If the event was the opening of an input NDF( i.e. an existing NDF 
*  opened for READ or UPDATE mode), add the path to the NDF to the RDKMP
*  KeyMap. Use the NDF name as the key, rather than the value so that any
*  subsequent invocations of this routine with the same NDF will overwrite
*  the earlier KeyMap entry, rather than creating an extra KeyMap entry.
*  Arbitrarily store zero as the value for the KeyMap entry.
*
*  If an application creates an output NDF, closes it, and then re-opens
*  it before the application terminates, we do not want the NDF to be
*  included in the list of input NDFs, so do not add the NDF into the
*  RDKMP keymap if it is already in the WRKMP keymap.
      IF( EVNAME .EQ. 'READ_EXISTING_NDF' .OR. 
     :    EVNAME .EQ. 'UPDATE_EXISTING_NDF' ) THEN

         IF( .NOT. AST_MAPHASKEY( WRKMP, EVTEXT, STATUS ) ) THEN
            CALL AST_MAPPUT0I( RDKMP, EVTEXT, 0, ' ', STATUS )
         ENDIF

      END IF

*  If the event was the opening of an output NDF( i.e. an existing NDF 
*  opened for UPDATE mode or a new NDF opened), add the path to the NDF 
*  to the WRKMP KeyMap.
      IF( EVNAME .EQ. 'UPDATE_EXISTING_NDF' .OR. 
     :    EVNAME .EQ. 'OPEN_NEW_NDF' ) THEN
         CALL AST_MAPPUT0I( WRKMP, EVTEXT, 0, ' ', STATUS )
      END IF

*  If the event was the mapping of a data array for read or update access, 
*  add the path to the NDF to the MPKMP KeyMap.
      IF( EVNAME .EQ. 'UPDATE_DATA' .OR. EVNAME .EQ. 'READ_DATA' ) THEN
         CALL AST_MAPPUT0I( MPKMP, EVTEXT, 0, ' ', STATUS )
      END IF

*  If the event was the writing of default history, add the path to the NDF 
*  to the DHKMP KeyMap.
      IF( EVNAME .EQ. 'DEF_HISTORY' ) THEN
         CALL AST_MAPPUT0I( DHKMP, EVTEXT, 0, ' ', STATUS )
      END IF

      END
