      SUBROUTINE CCD1_WRIXY( FD, ID, X, Y, N, BUFFER, BLEN, STATUS )
*+
*  Name:
*     CCD1_WRIXY

*  Purpose:
*     Writes Identifiers, X and Y values to a list.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCD1_WRIXY( FD, ID, X, Y, N, BUFFER, BLEN, STATUS )

*  Description:
*     This routine writes out the ID, X and Y values given to a
*     formmatted file whose FIO files descriptor is given.

*  Arguments:
*     FD = INTEGER (Given)
*        FIO file descriptor.
*     ID ( N ) = INTEGER (Given)
*        The identifiers of the positions.
*     X( N ) = DOUBLE PRECISION (Given)
*        X positions.
*     Y( N ) = DOUBLE PRECISION (Given)
*        Y positions.
*     N = INTEGER (Given)
*        Number of X and Y positions.
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
*     7-AUG-1992 (PDRAPER):
*        Changed to write out just X and Y positions (from list of
*        data).
*     9-OCT-1992 (PDRAPER):
*        Change to add given identifiers.
*     {enter_further_changes_here}

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
      INTEGER N
      INTEGER ID( N )
      DOUBLE PRECISION X( N )
      DOUBLE PRECISION Y( N )
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
      INTEGER IEND                  ! End position of word insertion
      INTEGER NCHAR                 ! Number of characters used to
                                    ! encode value
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Loop for all output lines.
      DO 1 I = 1, N

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

*  Now add all the X and Y values.
         CALL CHR_DTOC( X( I ), WORD, NCHAR )

*  Try to insert it into the output buffer.
         IEND = IAT + NCHAR
         IF ( IEND .LT. BLEN ) THEN
            BUFFER( IAT : IEND ) = WORD( 1 : NCHAR )
            IAT = IAT + MAX( NCHAR, 8 ) + 2
         ELSE
            STATUS = SAI__ERROR
            GO TO 99
         END IF

*  Now for Y value.
         CALL CHR_DTOC( Y( I ), WORD, NCHAR )
         IEND = IAT + NCHAR
         IF ( IEND .LT. BLEN ) THEN
            BUFFER( IAT : IEND ) = WORD( 1 : NCHAR )
            IAT = IAT + MAX( NCHAR, 8 ) + 2
         ELSE
            STATUS = SAI__ERROR
            GO TO 99
         END IF

*  Now write out buffer to file.
         CALL FIO_WRITE( FD, BUFFER (: CHR_LEN( BUFFER ) ), STATUS )
 1    CONTINUE

 99   CONTINUE

*  If an error has occurred report a message.
      IF ( STATUS .NE. SAI__OK ) THEN 
         CALL MSG_SETI( 'BLEN', BLEN )
         CALL ERR_REP( 'CCD1_WRIXYERR1',
     :      '  Cannot write output line internal buffer length '//
     :      '(^BLEN) exceeded', STATUS )
      END IF
      END
* $Id$
