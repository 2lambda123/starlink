      SUBROUTINE SST_FSKEY( STATUS )
*+
*  Name:
*     SST_FSKEY

*  Purpose:
*     Write an explanatory key for the FORSTATS application.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL SST_FSKEY( STATUS )

*  Description:
*     This routine writes a key for the FORSTATS application,
*     explaining to the user how to interpret the output from that
*     routine. The key is read from the file SST_DIR:FORSTATS.DAT.

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK)
*     PDRAPER: Peter Draper (STARLINK - Durham University)
*     {enter_new_authors_here}

*  History:
*     14-AUG-1990 (RFWS):
*        Original version.
*     5-SEP-1990 (RFWS):
*        Converted to read the key from a data file.
*     28-SEP-1990 (RFWS):
*        Added calls to ERR_MARK and ERR_RLSE.
*     5-DEC-1994 (PDRAPER):
*        Changed OPEN to FIO_OPEN, should be more portable.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'SST_PAR'          ! SST_ constants
      INCLUDE 'FIO_ERR'          ! FIO_ error codes

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL CHR_LEN
      INTEGER CHR_LEN            ! Used length of string

*  Local Variables:
      CHARACTER * ( SST__SZLIN ) LINE ! I/O buffer
      CHARACTER * ( 132 ) FILE   ! Full name of file to open
      INTEGER FD                 ! File descriptor
      INTEGER F                  ! First character position
      INTEGER IOERR              ! I/O error status
      INTEGER KEY                ! I/O unit for key data file
      INTEGER L                  ! Last character position

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Open the data file containing the key.
      CALL PSX_GETENV( 'SST_DIR', FILE, STATUS )
      CALL CHR_APPND( '/forstats.dat', FILE, CHR_LEN( FILE ) )
      CALL FIO_OPEN( FILE, 'READ', 'LIST', 0, FD, STATUS )
      CALL FIO_UNIT( FD, KEY, STATUS )

*  If an error occurred, then construct a message and report it.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL MSG_SETI( 'UNIT', KEY )
         CALL ERR_REP( 'SST_FSKEY_OPEN',
     :   'Error opening file $SST_DIR/forstats.dat for reading on ' //
     :   'Fortran unit ^UNIT.', STATUS )
         GO TO 99
      END IF

*  Loop to read the key.
      CALL ERR_MARK
1     CONTINUE                   ! Start of 'DO WHILE' loop
      IF ( STATUS .EQ. SAI__OK ) THEN
         CALL SST_GET( KEY, LINE, STATUS )
         CALL CHR_FANDL( LINE, F, L )

*  If the line is blank, then output a blank line. Otherwise, send the
*  input line to the output file, preserving its indentation.
         IF ( F .GT. L ) THEN
            CALL SST_PUT( 0, ' ', STATUS )
         ELSE
            CALL SST_PUT( F - 1, LINE( F : L ), STATUS )
         END IF
         GO TO 1
      END IF

*  Annul the end-of-file error and close the file.
      IF ( STATUS .EQ. FIO__EOF ) CALL ERR_ANNUL( STATUS )
      CALL ERR_RLSE
      CALL FIO_CLOSE( FD, STATUS )

*  Add a spacing line at the end.
      CALL SST_PUT( 0, ' ', STATUS )

 99   CONTINUE

      END
* @(#)sst_fskey.f   1.5   95/03/06 11:13:04   96/07/05 10:27:32
