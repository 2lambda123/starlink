      SUBROUTINE NDG_ADDGH( PARAM, IGRP, STATUS )
*+
*  Name:
*     NDG_ADDGH

*  Purpose:
*     Register a GRP group for GRP NDF history recording.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDG_ADDGH( PARAM, IGRP, STATUS )

*  Description:
*     This routine should be called to indicate that the contents of the
*     supplied GRP group should be included in the default History
*     information written out by the NDF library. It returns without
*     action unless a GRP NDF history block has previously been created
*     by calling NDG_BEGGH.

*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        The name of the parameter associated with the group.
*     IGRP = INTEGER (Given)
*        The GRP group identifier.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - The group is registered only if the current value of the
*     associated parameter contains an "INDIRECTION" or "NAME_TOKEN"
*     control character (see SUN/150). This prevents group descriptions
*     being added to the NDF history if the contents of the group are
*     already described fully by the parameters list.
*     - This routine records a copy of the group contents at the time
*     this routine is called. Any subsequent changes to the contents of
*     the group are not included in the default NDF history.
*     - This routine can be invoked multiple times for the same parameter.
*     Later invocations will replace the group contents registered by
*     earlier invocations.

*  Copyright:
*     Copyright (C) 2009 Science & Technology Facilities Council.
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
*     DSB: David Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     16-OCT-2009 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST constants and functions
      INCLUDE 'GRP_PAR'          ! GRP constants

*  Global Variables:
      INCLUDE 'NDG_COM2'         ! Global GRP history information

*  Arguments Given:
      CHARACTER PARAM*(*)
      INTEGER IGRP
      INTEGER IPAR
      CHARACTER GRPEXP*(4*GRP__SZGEX )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER IGRP2
      CHARACTER CC*2
*.

*  Check the inherited status
      IF( STATUS .NE. SAI__OK ) RETURN

*  Check that GHKMP_COM2 is a valid AST KeyMap pointer. This will only be the
*  case if NDG_BEGGH has been called previously.
      IF( AST_ISAKEYMAP( GHKMP_COM2, STATUS ) ) THEN

*  Delete any group already stored for the  given parameter.
         IF( AST_MAPGET0I( GHKMP_COM2, PARAM, IGRP2, STATUS ) ) THEN
            CALL GRP_DELET( IGRP2, STATUS )
         END IF

* Get the current un-interpreted parameter value.
         CALL SUBPAR_FINDPAR( PARAM, IPAR, STATUS )
         CALL SUBPAR_GETNAME( IPAR, GRPEXP, STATUS )

*  Get the control characters used by the group for indirection and
*  modification.
         CALL GRP_GETCC( IGRP, 'INDIRECTION,NAME_TOKEN', CC, STATUS )

*  Only register the group if it contain one or more of the above group
*  control characters.
         IF( INDEX( GRPEXP, CC( 1 : 1 ) ) .GT. 0 .OR.
     :       INDEX( GRPEXP, CC( 2 : 2 ) ) .GT. 0 ) THEN

*  Take a copy of the group, and store the new GRP identifier in the
*  KeyMap.
            CALL GRP_COPY( IGRP, 0, 0, .FALSE., IGRP2, STATUS )
            CALL AST_MAPPUT0I( GHKMP_COM2, PARAM, IGRP2, ' ', STATUS )
         END IF

*  Annul any error caused by GHKMP_COM2 not being a valid KeyMap pointer.
      ELSE IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_ANNUL( STATUS )

      END IF

      END
