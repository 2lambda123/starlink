      SUBROUTINE CCD1_WLIS( FD, ID, ARRAY, NREC, NVAL, NDEC, BUFFER,
     :                      BLEN, STATUS )
*+
*  Name:
*     CCD1_WLIS

*  Purpose:
*     Writes out identifiers and an array of values to a formatted file.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCD1_WLIS( FD, ID, ARRAY, NREC, NVAL, NDEC, BUFFER, BLEN,
*                     STATUS )

*  Description:
*     The routine writes identifiers (ID) followed by the associated
*     row of values ARRAY. The strings representing these values are
*     written into BUFFER which consequently defines how large an output
*     line of information may be. The CHR_XTOC routines are used to
*     format the output string so that 'sensible' compression (trailing
*     zero stripping etc.) of the output values occurs.

*  Arguments:
*     FD = INTEGER (Given)
*        FIO file descriptor.
*     ID( NREC ) = INTEGER (Given)
*        Array of identifiers.
*     ARRAY( NDEC, NVAL ) = DOUBLE PRECISION (Given)
*        Array of values whose records (rows) are associated with the
*        identifiers.
*     NREC = INTEGER (Given)
*        Number of records in ARRAY and values in ID to write out.
*     NVAL = INTEGER (Given)
*        Number of values in a record (row) of ARRAY.
*     NDEC = INTEGER (Given)
*        The declared first dimension of ARRAY.
*     BUFFER = CHARACTER * ( BLEN ) (Given and Returned)
*        Buffer to hold an output line.
*     BLEN = INTEGER (Given)
*        Length of BUFFER.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     20-JUL-1992 (PDRAPER):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT constants

*  Arguments Given:
      INTEGER FD
      INTEGER NREC
      INTEGER NVAL
      INTEGER NDEC
      INTEGER ID( NREC )
      DOUBLE PRECISION ARRAY( NDEC, NVAL )
      INTEGER BLEN

*  Arguments Given and Returned:
      CHARACTER * ( * ) BUFFER

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL CHR_LEN
      INTEGER CHR_LEN            ! Length of string excluding trailing
                                 ! blanks

*  Local variables:
      CHARACTER * ( VAL__SZD ) WORD ! Buffer to contain local values
                                    ! as a character string, this is
                                    ! big enough for DBLE values.
      INTEGER IAT                   ! Position within string
      INTEGER I                     ! Loop variable
      INTEGER J                     ! Loop variable
      INTEGER IEND                  ! End position of word insertion
      INTEGER NCHAR                 ! Number of characters used to
                                    ! encode value
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Loop for all output lines.
      DO 1 I = 1, NREC

*  Clear output buffer.
         BUFFER = ' '

*  Set the identifier value
         CALL CHR_ITOC( ID( I ), WORD, NCHAR )

*  Insert it into the output buffer.
         IF ( NCHAR .LT. BLEN ) THEN
            BUFFER( 1 : NCHAR ) = WORD( 1 : NCHAR )
         ELSE

*  String too long.
            STATUS = SAI__ERROR
            GO TO 99
         END IF

*  Increment position within output buffer.
         IAT = MAX( NCHAR, 8 ) + 2

*  Now add all the values.
         DO 2 J = 1, NVAL
            CALL CHR_DTOC( ARRAY( I, J ), WORD, NCHAR )

*  Try to insert it into the output buffer.
            IEND = IAT + NCHAR
            IF ( IEND .LT. BLEN ) THEN
               BUFFER( IAT : IEND ) = WORD( 1 : NCHAR )
               IAT = IAT + MAX( NCHAR, 8 ) + 2
            ELSE
               STATUS = SAI__ERROR
               GO TO 99
            END IF
 2       CONTINUE

*  Now write out buffer to file.
         CALL FIO_WRITE( FD, BUFFER (: CHR_LEN( BUFFER ) ), STATUS )
 1    CONTINUE

 99   CONTINUE

*  If an error has occurred report a message.
      IF ( STATUS .NE. SAI__OK ) THEN 
         CALL MSG_SETI( 'BLEN', BLEN )
         CALL ERR_REP( 'CCD1_WLISERR1',
     :      '  Cannot write output line internal buffer length '//
     :      '(^BLEN) exceeded', STATUS )
      END IF
      END
* $Id$
