      SUBROUTINE CCDPACK_RES( STATUS )
*+
*  Name:
*     CCDPACK_RES

*  Purpose:
*     Top-level monolith for miscellaneous routines.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCDPACK( STATUS )

*  Description:
*     This routine gets the action name directly from the Unix kernel.
*     It then calls the appropriate routine to perform the
*     specified action. An error will be reported and STATUS will
*     be set if the action name is not recognized.

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1995, 2001 Central Laboratory of the Research
*     Councils. All Rights Reserved.

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
*     PDRAPER: Peter Draper (STARLINK)
*     DSB: David S Berry (JAC, UCLan)
*     {enter_new_authors_here}

*  History:
*     31-OCT-1995 (PDRAPER):
*        Original version.
*     6-FEB-2001 (MBT):
*        Added MAKESET, SHOWSET entries.
*     27-NOV-2007 (DSB):
*        Use NDG_BEGPV/ENDPV to provide automatic provenance propagation.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PAR_PAR'          ! Parameter system constants
      INCLUDE 'CCD1_PAR'         ! VERS value.

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL PRESENT           ! Avoids confusion with PRESENT intrinsic

*  Local variables:
      CHARACTER * ( PAR__SZNAM ) ACTION ! Action name

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Get the action name.
      CALL TASK_GET_NAME( ACTION, STATUS )

*  Set the NDF application name.
      CALL NDF_HAPPN( ACTION // VERS, STATUS )

*  Tweak the numerics on a RedHat 7 Linux system.
      CALL CCD1_LINFLT

*  Begin a provenance block. This causes event handlers to be registered
*  with the NDF library so that a handler routine in NDG is called every
*  time an NDF is opened. This handler routine keeps a record of all NDFs
*  that are opened for input or output, until the block is closed by
*  calling NDG_ENDPV.
      CALL NDG_BEGPV( STATUS )

*  Test the action name against each valid value in turn, calling the
*  appropriate routine...
      IF ( ACTION .EQ. 'CCDCLEAR' ) THEN
         CALL CCDCLEAR( STATUS )

      ELSE IF ( ACTION .EQ. 'CCDEXP' ) THEN
         CALL CCDEXP( STATUS )

      ELSE IF ( ACTION .EQ. 'CCDGENERATE' ) THEN
         CALL CCDGENERATE( STATUS )

      ELSE IF ( ACTION .EQ. 'CCDIMP' ) THEN
         CALL CCDIMP( STATUS )

      ELSE IF ( ACTION.EQ. 'CCDNDFAC' ) THEN
         CALL CCDNDFAC( STATUS )

      ELSE IF ( ACTION .EQ. 'CCDNOTE' ) THEN
         CALL CCDNOTE( STATUS )

      ELSE IF ( ACTION .EQ. 'CCDSETUP' ) THEN
         CALL CCDSETUP( STATUS )

      ELSE IF ( ACTION.EQ. 'CCDSHOW' ) THEN
         CALL CCDSHOW( STATUS )

      ELSE IF ( ACTION .EQ. 'IMPORT' ) THEN
         CALL IMPORT( STATUS )

      ELSE IF ( ACTION .EQ. 'MAKESET' ) THEN
         CALL MAKESET( STATUS )

      ELSE IF ( ACTION.EQ. 'PICINFO' ) THEN
         CALL PICINFO( STATUS )

      ELSE IF ( ACTION .EQ. 'PRESENT' ) THEN
         CALL PRESENT( STATUS )

      ELSE IF ( ACTION .EQ. 'SCHEDULE' ) THEN
         CALL SCHEDULE( STATUS )

      ELSE IF ( ACTION .EQ. 'SHOWSET' ) THEN
         CALL SHOWSET( STATUS )

*  If the action name is not recognised, then report an error.
      ELSE
         STATUS = SAI__ERROR
         CALL MSG_SETC( 'ACTION', ACTION )
         CALL ERR_REP( 'CCDPACK_ERR',
     :                 'CCDPACK: The action name ''^ACTION'' is ' //
     :                 'not recognised by the CCDPACK '//
     :                 'monolith.', STATUS )
      END IF

*  End the provenance block. This will result in every output NDF being
*  given a provenance extension containing a record of the input NDFs
*  that the application accessed in order to create the output NDF. Any
*  output NDF that already contains a provenance extension is left
*  unchanged (so individual application can over-ride this automatic
*  provenance handling by adding a provenance extension to the output NDF
*  itself).
      CALL NDG_ENDPV( 'CCDPACK:'//ACTION, STATUS )

      END
* $Id$
