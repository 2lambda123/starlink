      SUBROUTINE ATL_RDGRP( IGRP, IAST, STATUS )
*+
*  Name:
*     ATL_RDGRP

*  Purpose:
*     Read an AST Object from a GRP group.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL ATL_RDGRP( IGRP, IAST, STATUS )

*  Description:
*     Read an AST Object from a GRP group. The text in the group can be
*     either an AST Object dump, a set of FITS headers, or an STC-S
*     description.

*  Arguments:
*     IGRP = INTEGER (Given)
*        An identifier for the group holding the text.
*     IAST = INTEGER (Returned)
*        The AST Object, or AST__NULL.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - If the group contains the AST dump of a Channel (of any class),
*     then the Object returned via IAST will be the Channel itself. The
*     exception to this is that if the "Begin " line at the start of
*     the dump ends with the string "(Read)", then the returned IAST
*     Object will be the Object read from the Channel, rather than the
*     Channel itself. For instance, if the group contains the AST dump of
*     a FitsChan, and the first line of the dump is "Begin FitsChan(Read)",
*     then the returned IAST object will be the Object read from the
*     FitsChan, rather than the FitsChan itself. This facility is only
*     available for top level objects (e.g. FitsChans contained within
*     FitsChans cannot be read in this way).

*  Copyright:
*     Copyright (C) 2001 Central Laboratory of the Research Councils.
*     Copyright (C) 2009 Science & Technology Facilities Council.
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
*     12-JAN-2001 (DSB):
*        Original version.
*     30-JUN-2009 (DSB):
*        Support reading Objects from STC-S descriptions.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST constants
      INCLUDE 'GRP_PAR'          ! GRP constants

*  Arguments Given:
      INTEGER IGRP

*  Arguments Returned:
      INTEGER IAST

*  Status:
      INTEGER STATUS             ! Global status


*  Local Variables:
      CHARACTER TEXT*(GRP__SZNAM)
      INTEGER I
      INTEGER SIZE
      LOGICAL DUMP
      LOGICAL FITSWCS
*.

*  Initialise.
      IAST = AST__NULL

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Determine the most likely format of the text in the group. If the
*  group contains a line beginning with the word "Begin" it is probably a
*  dump of an AST object produced by AST_SHOW. If it contains the string
*  CRPIX, CRVAL or CTYPE it is probably a set of FITS_WCS headers.
      CALL GRP_GRPSZ( IGRP, SIZE, STATUS )
      DUMP = .FALSE.
      FITSWCS = .FALSE.
      DO I = 1, SIZE
         CALL GRP_GET( IGRP, I, 1, TEXT, STATUS )
         CALL CHR_LDBLK( TEXT )
         IF( TEXT( : 6 ) .EQ. 'Begin ' ) THEN
            DUMP = .TRUE.
            GO TO 10
         ELSE IF( INDEX( TEXT, 'CRVAL' ) .NE. 0 .OR.
     :            INDEX( TEXT, 'CRPIX' ) .NE. 0 .OR.
     :            INDEX( TEXT, 'CTYPE' ) .NE. 0 ) THEN

            FITSWCS = .TRUE.
            GO TO 10
         END IF
      END DO
 10   CONTINUE

*  Abort if an error has occurred.
      IF( STATUS .NE. SAI__OK ) GO TO 999

*  If the file probably contains a dump of an AST object, try to read it
*  first as a set of FITS headers, then as an STC-S description, then as
*  a object dump. This means that any errors produced while reading it as
*  an object dump will be reported to the user.
      IF( DUMP ) THEN
         CALL ATL_RDFCH( IGRP, IAST, STATUS )

         IF( STATUS .NE. SAI__OK ) CALL ERR_ANNUL( STATUS )
         IF( IAST .EQ. AST__NULL ) CALL ATL_RDSTCS( IGRP, IAST, STATUS )

         IF( STATUS .NE. SAI__OK ) CALL ERR_ANNUL( STATUS )
         IF( IAST .EQ. AST__NULL ) CALL ATL_RDCH( IGRP, IAST, STATUS )

*  If the file probably contains FITS headers, try to read it
*  first as an Object dump, then as an STC-S description, then as a set
*  of FITS headers. This means that any errors produced while reading it as
*  a FITS file will be reported to the user.
      ELSE IF( FITSWCS ) THEN
         CALL ATL_RDCH( IGRP, IAST, STATUS )

         IF( STATUS .NE. SAI__OK ) CALL ERR_ANNUL( STATUS )
         IF( IAST .EQ. AST__NULL ) CALL ATL_RDSTCS( IGRP, IAST, STATUS )

         IF( STATUS .NE. SAI__OK ) CALL ERR_ANNUL( STATUS )
         IF( IAST .EQ. AST__NULL ) CALL ATL_RDFCH( IGRP, IAST, STATUS )

*  If not an AST dump or a set of FITS-WCS headers, the file may contains
*  an STC-S description. Try to read it first as an Object dump, then as a
*  set of FITS headers, then as an STC-S description. This means that any
*  errors produced while reading it as a FITS file will be reported to the
*  user.
      ELSE
         CALL ATL_RDCH( IGRP, IAST, STATUS )

         IF( STATUS .NE. SAI__OK ) CALL ERR_ANNUL( STATUS )
         IF( IAST .EQ. AST__NULL ) CALL ATL_RDFCH( IGRP, IAST, STATUS )

         IF( STATUS .NE. SAI__OK ) CALL ERR_ANNUL( STATUS )
         IF( IAST .EQ. AST__NULL ) CALL ATL_RDSTCS( IGRP, IAST, STATUS )

      END IF

*  Arrive here when finished.
 999  CONTINUE

*  Export the returned Object from the current AST context so that it is
*  not annulled by the following call to AST_END. If an error has occurred,
*  the Object will not be exported, and so will be annulled by AST_END.
      CALL AST_EXPORT( IAST, STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

      END
