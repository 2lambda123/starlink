      SUBROUTINE CCD1_WMMC( LIST, PROG,  PREFIX, USEPRO, PROTEC, CONTIN,
     :                      TYPE, FILT, FD, FTYPES, GID, NNDF,
     :                      MASTER, IRFLAT, VALID, PTEMP, TEMP, STATUS )
*+
*  Name:
*     CCD1_WMMC

*  Purpose:
*     Generates a command to create a calibration frame.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCD1_WMMC( LIST, PROG,  PREFIX, USEPRO, PROTEC, CONTIN, TYPE,
*                     FILT, FTYPES, GID, NNDF, MASTER,
*                     IRFLAT, VALID, PTEMP, TEMP, STATUS )

*  Description:
*     This routine creates a command suitable for creating a master
*     calibration frame.
*
*     It only uses the basic parameters IN and OUT which apply to every
*     CCDPACK MAKExxxx command. The actual program name is supplied in
*     the PROG argument. The arguments  PREFIX, USEPRO, PROTEC and
*     CONTIN defines which type of script the command is to be
*     designed for.
*
*     The TYPE parameter describes the sort of MASTER frame to be
*     created. This should be "BIAS", "FLAT", "DARK" or "FLASH" and
*     should match some of the frame types in FTYPES.
*
*     The FTYPES argument is an array which contains the frame types
*     of each of the NDFs (GRP group GID) and the filter type (if
*     appropriate). The filter types (FILT) is only used when the TYPE
*     is FLAT. This extracts only the flatfields with the correct filter
*     type. If the IRFLAT parameter is TRUE then suitable TARGET frames
*     will be used if no FLATs are located.
*
*     GID is a GRP group identifier (for all the FTYPES entries), the
*     names of NDFs are extracted from this and written into a
*     temporary file which is read using indirection.
*
*     VALID is a logical array masking elements of FTYPES which should
*     and shouldn't be considered. On exit this is changed to flag those
*     entries used by the call generated by this routine.
*
*     The command written by this procedure is INCOMPLETE. I.e. the
*     line is terminated by a continuation character. Additional
*     parameters may then be added or the ACCEPT keyword should be
*     written to the next line.

*  Arguments:
*     LIST = LOGICAL (Given)
*        Whether or not to list the NDF names through the logging
*        system.
*     PREFIX = CHARACTER * ( * ) (Given)
*        The prefix for commands.
*     USEPRO = LOGICAL (Returned)
*        Whether quoting protection should be used (in case special
*        characters are present).
*     PROTEC( 2 ) = CHARACTER * ( * ) (Given)
*        The protection characters (if used).
*     CONTIN = CHARACTER * ( * ) (Given)
*        The continuation character for this script type.
*     PROG = CHARACTER * ( * ) (Given)
*        The name of the master calibration frame program (MAKEBIAS
*        MAKECAL or MAKEFLAT).
*     TYPE = CHARACTER * ( * ) (Given)
*        The type of frames to be used to create a "master". Should be
*        FLAT, BIAS, FLASH or DARK.
*     FILT = CHARACTER * ( * ) (Given)
*        If TYPE="FLAT" then a filter type is required to select the
*        correct frames. This is not used otherwise.
*     FD = INTEGER (Given)
*        FIO file descriptor for writing commands to.
*     FTYPES( 2, NNDF ) = CHARACTER * ( * ) (Given)
*        The frame and filter types of the input NDFs. (1,*) are the
*        frame types, (2,*) are the filters (if used).
*     GID = INTEGER (Given)
*        GRP group identifier. This group contains the names of the
*        NDFs.
*     IRFLAT = LOGICAL (Given)
*        Whether or not TARGET frames may be used to flatfield.  This
*        is an IR option and will only be used if no flatfields of an
*        appropriate colour exist.
*     NNDF = INTEGER (Given)
*        The number of NDFs.
*     MASTER = CHARACTER * ( * ) (Given)
*        The name of the master calibration frame which will be created
*        by the command generated here.
*     VALID( NNDF ) = LOGICAL (Given and Returned)
*        Flags indicating which NDFs should be used. A .FALSE. entry
*        indicates that a specified NDF shouldn't be used. On exit these
*        are updated so that frames used by the call generated by this
*        routine are flagged as no longer valid. Except if the IRFLATs
*        flag is in operation.
*     PTEMP( NNDF ) = INTEGER (Given and Returned)
*        Pointers to the frames selected.
*     TEMP = CHARACTER * ( * ) (Returned)
*        The name of the temporary file that is used to contain the
*        NDF names. You should arrange to delete this.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1993-1994 Science & Engineering Research Council.
*     Copyright (C) 1995, 2000 Central Laboratory of the Research
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
*     Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*     02110-1301, USA

*  Authors:
*     PDRAPER: Peter Draper (STARLINK - Durham University)
*     MBT: Mark Taylor (STARLINK)
*     {enter_new_authors_here}

*  History:
*     21-SEP-1993 (PDRAPER):
*        Original version.
*     27-JAN-1994 (PDRAPER):
*        Added LIST argument to increase user awareness.
*     31-JAN-1994 (PDRAPER):
*        Now flags frames by setting VALID false for those selected.
*     10-NOV-1995 (PDRAPER):
*        Added IRFLAT for IR data reductiions.
*     29-JUN-2000 (MBT):
*        Replaced use of IRH/IRG with GRP/NDG.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'FIO_PAR'          ! FIO parameters
      INCLUDE 'MSG_PAR'          ! Message system parameters
      INCLUDE 'GRP_PAR'          ! Standard GRP constants

*  Arguments Given:
      LOGICAL LIST
      INTEGER NNDF
      CHARACTER * ( * ) PROG
      CHARACTER * ( * ) PREFIX
      LOGICAL USEPRO
      CHARACTER * ( * ) PROTEC( 2 )
      CHARACTER * ( * ) CONTIN
      CHARACTER * ( * ) TYPE
      CHARACTER * ( * ) FILT
      INTEGER FD
      CHARACTER * ( * ) FTYPES( 2, NNDF )
      INTEGER GID
      CHARACTER * ( * ) MASTER
      LOGICAL IRFLAT

*  Arguments Given and Returned.
      LOGICAL VALID( NNDF )
      INTEGER PTEMP( NNDF )

*  Arguments Returned.
      CHARACTER * ( * ) TEMP

*  Status:
      INTEGER STATUS             ! Global status

*  External references:
      INTEGER CHR_LEN
      EXTERNAL CHR_LEN           ! Length of string excluding trailing
                                 ! blanks

*  Local Variables:
      CHARACTER * ( GRP__SZNAM ) NDFNAM ! Name of NDF
      CHARACTER * ( MSG__SZMSG ) MESS ! Output buffer
      CHARACTER COMC             ! GRP comment character
      CHARACTER INDC             ! GRP indirection character
      INTEGER FDTMP              ! Temporary file descriptor
      INTEGER I                  ! Loop variable
      INTEGER IAT                ! Position within string
      INTEGER NFRMS              ! Number of frames of TYPE
      INTEGER LCONT              ! Used length of CONTIN
      LOGICAL OPEN               ! Whether temporary file is opened
      LOGICAL IRUSED             ! Whether the IRFLAT option has been used.
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  IRFLAT option not used.
      IRUSED = .FALSE.

*  Get pointers to the appropriate frames.
      IF ( TYPE .EQ. 'FLAT' ) THEN

*  Will be using a filter specification too. Choose specifications which
*  also have this filter type.
         CALL CCD1_LOCS3( FTYPES, 2, NNDF, 1, 2, VALID, TYPE,
     :                    FILT, PTEMP, NFRMS, STATUS )

*  If asked check for TARGETS that could be used.
         IF ( NFRMS .EQ. 0 .AND. IRFLAT ) THEN
            CALL CCD1_LOCS3( FTYPES, 2, NNDF, 1, 2, VALID, 'TARGET',
     :                       FILT, PTEMP, NFRMS, STATUS )
            IRUSED = .TRUE.
         END IF
      ELSE

*  Just get pointers to NDFs with this type.
         CALL CCD1_LOCS2( FTYPES, 2, NNDF, 1, VALID, TYPE, PTEMP,
     :                    NFRMS, STATUS )
      END IF

*  Check that the name selection has been successful.
      IF ( NFRMS .GT. 0 ) THEN

*  Ok got some data to work with. Create a temporary file to contain
*  these names.
         TEMP = ' '
         CALL CCD1_TMPNM( PROG, TEMP( 2: ), STATUS )

*  Get required GRP control characters.
         CALL GRP_GETCC( GID, 'COMMENT', COMC, STATUS )
         CALL GRP_GETCC( GID, 'INDIRECTION', INDC, STATUS )

*  Open the file.
         IF ( STATUS .NE. SAI__OK ) GO TO 99
         OPEN = .FALSE.
         CALL CCD1_OPFIO( TEMP( 2: ), 'WRITE', 'LIST', 0, FDTMP,
     :                    STATUS )
         IF ( STATUS .EQ. SAI__OK ) OPEN = .TRUE.
         MESS = ' '
         MESS = COMC // ' List of names used by '
     :          // PROG( :CHR_LEN( PROG ) )
         CALL FIO_WRITE( FDTMP, MESS( :CHR_LEN( MESS ) ), STATUS )

*  Now extract the name of the NDFs, add the trailing modification
*  element and write these into the file.
         DO 1 I = 1, NFRMS
            NDFNAM = ' '
            CALL GRP_GET( GID, PTEMP( I ), 1, NDFNAM, STATUS )
            IAT = CHR_LEN( NDFNAM )
            CALL FIO_WRITE( FDTMP, NDFNAM( :IAT ), STATUS )

*  If required list the names to the log system.
            IF ( LIST ) THEN
               CALL MSG_SETC( 'NDFNAM', NDFNAM )
               CALL CCD1_MSG( ' ', '    ^NDFNAM', STATUS )
            END IF

*  Set the valid flag of this frame to false.
            IF ( .NOT. IRUSED ) VALID( PTEMP( I ) ) = .FALSE.
 1       CONTINUE

*  Close the temporary file.
         CALL FIO_CLOSE( FDTMP, STATUS )

*  Now create the command for the script file. First add the routine
*  name.
         MESS = ' '
         IAT = CHR_LEN( PROG )
         MESS = PREFIX//PROG( :IAT )//CONTIN
         CALL FIO_WRITE( FD, MESS( :CHR_LEN( MESS ) ), STATUS )
         LCONT = CHR_LEN( CONTIN )

*  Now add the input file specifier.
         TEMP( 1: 1 ) = INDC
         IAT = 3
         MESS = ' '
         CALL CCD1_ADKEY( 'IN', TEMP, USEPRO, PROTEC, MESS, IAT,
     :                    STATUS )
         MESS = MESS( :IAT )//CONTIN
         CALL FIO_WRITE( FD, MESS( :IAT+LCONT ), STATUS )
         TEMP( 1: 1 ) = ' '

*  And the output file.
         IAT = 3
         MESS = ' '
         CALL CCD1_ADKEY( 'OUT', MASTER, USEPRO, PROTEC, MESS, IAT,
     :                    STATUS )
         MESS = MESS( :IAT )//CONTIN
         CALL FIO_WRITE( FD, MESS( :IAT+LCONT ), STATUS )
      ELSE

*  No selection of frames with this type has been possible.
         STATUS = SAI__ERROR
         CALL MSG_SETC( 'TYPE', TYPE )
         CALL MSG_SETC( 'PROG', PROG )
         CALL ERR_REP( 'CCD1_WMMC1',
     :   '  CCD1_WMMC: Unable to find any frames of type ^TYPE, for'//
     :   ' processing by routine ^PROG', STATUS )
      END IF

*  Exit label.
 99   CONTINUE
      END

* $Id$
