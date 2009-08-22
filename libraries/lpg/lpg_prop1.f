      SUBROUTINE LPG_PROP1( INDF1, CLIST, PARAM, INDF2, NAME, STATUS )
*+
*  Name:
*     LPG_PROP1

*  Purpose:
*     Create a single new NDF by propagation using a specified parameter.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL LPG_PROP1( INDF1, CLIST, PARAM, INDF2, NAME, STATUS )

*  Description:
*     This routine is equivalent to NDF_PROP except that it allows the 
*     NDF to be specified using a GRP group expression (for instance, its
*     name may be given within a text file, etc.). The first NDF in the 
*     group expression is returned. Any other names in the group
*     expression are ignored. Modification elements use the name of the 
*     supplied NDF as the basis name.

*  Arguments:
*     INDF1 = INTEGER (Given)
*        Identifier for an existing NDF (or NDF section) to act as a
*        template.
*     CLIST = CHARACTER * ( * ) (Given)
*        A comma-separated list of the NDF components which are to be
*        propagated to the new data structure. By default, the HISTORY,
*        LABEL and TITLE components and all extensions are propagated.
*        See the "Component Propagation" section in the documentation
*        for routine NDF_PROP within SUN/33 for further details.
*     PARAM = CHARACTER * ( * ) (Given)
*        Name of the ADAM parameter for the new NDF.
*     INDF2 = INTEGER (Returned)
*        Identifier for the new NDF.
*     NAME = CHARACTER * ( * ) (Returned)
*        The full file specification for the NDF.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 2004 Central Laboratory of the Research Councils.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*     
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
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
*     15-MAR-2004 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'GRP_PAR'          ! GRP constants.
      INCLUDE 'NDF_PAR'          ! NDF constants

*  Arguments Given:
      INTEGER INDF1
      CHARACTER CLIST*(*)
      CHARACTER PARAM*(*)

*  Arguments Returned:
      INTEGER INDF2
      CHARACTER NAME*(*)

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER NDFNAM*255       ! Spec. for supplied basis NDF
      INTEGER IGRP               ! Group holding supplied NDF names
      INTEGER IGRP0              ! Basis group for modifications
      INTEGER NDFLEN             ! Used length of NDFNAM
      INTEGER SIZE               ! No. of supplied NDF names
      LOGICAL FLAG               ! User wants to supply more NDFs?
*.

*  Set an initial value for the INDF argument.
      INDF2 = NDF__NOID

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Create a group holding the name of the supplied NDF.
      CALL NDF_MSG( 'NDF', INDF1 )
      CALL MSG_LOAD( PARAM, '^NDF', NDFNAM, NDFLEN, STATUS )
      CALL GRP_NEW( 'NDF name', IGRP0, STATUS )
      CALL GRP_PUT( IGRP0, 1, NDFNAM( : NDFLEN ), 0, STATUS )

*  Get a group of NDFs from the environment using the supplied parameter.
*  There is no need to loop if a group expression is given which is 
*  terminated by a flag character since we only want one NDF.
      IGRP = GRP__NOID
      CALL NDG_CREAT( PARAM, IGRP0, IGRP, SIZE, FLAG, STATUS )

*  If the requested output NDF is already in use as an input NDF, we
*  create a temporary output NDF (if allowed) which is copied to the
*  correct place once the application has completed. Modify the entry in
*  the group  if necessary to refer to a temporary output NDF.
      CALL LPG1_ADDTM( IGRP, 1, STATUS )

*  Get the name of the first NDF in the group.
      CALL GRP_GET( IGRP, 1, 1, NAME, STATUS ) 

*  Get an NDF identifier for the first NDF in the group.         
      CALL NDG_NDFPR( INDF1, CLIST, IGRP, 1, INDF2, STATUS )

*  Delete the groups.
      CALL GRP_DELET( IGRP0, STATUS )
      CALL GRP_DELET( IGRP, STATUS )

*  If an error occurred, annul the NDF.
      IF( STATUS .NE. SAI__OK ) CALL NDF_ANNUL( INDF2, STATUS )

      END
