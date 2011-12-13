      SUBROUTINE DTASK_GTCMD( CMDLIN, STATUS )
*+
*  Name:
*     DTASK_GTCMD

*  Purpose:
*     To obtain the parameters section of the command line which
*     invoked this task.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL DTASK_GTCMD( CMDLIN, STATUS )

*  Description:
*     This is the SUN UNIX version.
*     Each parameter is obtained in turn and appended to the CMDLIN
*     string.

*  Arguments:
*     CMDLIN = CHARACTER*(*) (Returned)
*        The constructed command line
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Implementation Deficiencies:
*     The routine is necessarily system dependent

*  Copyright:
*     Copyright (C) 1991-1992 Science & Engineering Research Council.
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
*     Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*     02110-1301, USA

*  Authors:
*     AJC: A J Chipperfield (STARLINK)
*     {enter_new_authors_here}

*  History:
*     18-JUL-1991 (AJC):
*        Original version.
*     06-FEB-1992 (AJC):
*        Space fill remainder of line
*     02-JUN-1992 (AJC):
*        Prefix command too long message
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INTEGER MCLEN              ! Max length of command line
      PARAMETER ( MCLEN = 444 )

*  Arguments Returned:
      CHARACTER*(*) CMDLIN

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER IARGC
      INTEGER CHR_LEN

*  Local Variables:
      INTEGER CLPTR              ! Pointer into CMDLIN
      INTEGER OLDPTR             ! Saved pointer
      INTEGER I                  ! Loop counter
      INTEGER ARGLEN             ! Used length of ARG
      CHARACTER*(MCLEN) ARG      ! Individual argument
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise pointers
      I = 1
      CLPTR = 0
      OLDPTR = 1

*  For each command argument in turn
      DOWHILE ( ( I .LE. IARGC() ) .AND. ( STATUS .EQ. SAI__OK ) )

*     Get the Ith argument and its length
         CALL GETARG ( I, ARG )
         ARGLEN = CHR_LEN ( ARG )

*     Append the argument to CMDLIN and follow it with space.
         CALL CHR_PUTC ( ARG(1:ARGLEN), CMDLIN, CLPTR )
         CALL CHR_PUTC ( ' ', CMDLIN, CLPTR )

*     Now check for overflow (highly unlikely)
         IF ( CLPTR .EQ. OLDPTR ) THEN
            STATUS = SAI__ERROR
            CALL EMS_REP( 'DTASK_GTCMD1',
     :      'DTASK_GTCMD: Command line too long', STATUS )

*     If OK, save the pointer to check next time
         ELSE
            OLDPTR = CLPTR

         ENDIF

*  Do next argument
         I = I + 1

      ENDDO

*  Space fill the command line if necessary
      IF ( CLPTR .LT. LEN(CMDLIN) ) CMDLIN(CLPTR+1:) = ' '

      END
