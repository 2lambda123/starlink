      SUBROUTINE KPG1_FFRD( STRING, NVAL, ORIGIN, VALUES, STATUS )
*+
*  Name:
*     KPG1_FFRx
 
*  Purpose:
*     Reads free-format floating-point data from a string.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPG1_FFRx( STRING, NVAL, ORIGIN, VALUES, STATUS )
 
*  Description:
*     A buffer containing free-format values separated by spaces
*     or commas is decoded and the numerical values extracted.
*     It packages up the equivalent SLALIB calls (SLA_FLOTIN and
*     SLA_DFLTIN) in order to obtain an array of values with a single
*     line of code, and provides standard error handling.  See SUN/67
*     for more details of the parsing technique and limitations.
*
*     If the desired number of values cannot be decoded from the string
*     an error status SAI__ERROR is set.
 
*  Arguments:
*     STRING = CHARACTER * ( * ) (Given)
*        The string containing the values to be decoded and extracted.
*     NVAL = INTEGER (Given)
*        The number of values to extract from the string.
*     ORIGIN = INTEGER (Given and Returned)
*        On input this is the column or pointer in the string from
*        where the decoding commences.  On output it is advanced to the
*        next number or the end of the buffer if there are no more
*        numbers.
*     VALUES( NVAL ) = ? (Returned)
*        The decoded values.  These are initialised to zero before
*        decoiding commences.
*     STATUS = INTEGER (Given and Returned)
*        The global status.
 
*  Notes:
*     -  There is a routine for floating-point numeric data types:
*     replace "x" in the routine name by D or R as appropriate.  The
*     array returned from the routine must have the data type specified.
*     [routine_notes]...
 
*  Algorithm:
*     -  Uses SLA_FLOTIN or SLA_DFLTIN (depending on "x") within a loop.
 
*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1992 March 16 (MJC):
*        Original version.
*     {enter_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
 
*  Arguments Given:
      CHARACTER * ( * ) STRING
      INTEGER NVAL
 
*  Arguments Given and Returned:
      INTEGER ORIGIN
 
*  Arguments Returned:
      DOUBLE PRECISION VALUES( NVAL )
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER I                  ! Loop counter
      INTEGER ISTAT              ! SLALIB status
 
*.
 
*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Initialise the values.
      DO I = 1, NVAL
         VALUES( I ) = 0.0D0
      END DO
 
*  Use SLALIB routines for parsing and extracting each value.  The
*  routine chosen depends on the data type to be read.
      IF ( 'D' .EQ. 'R' ) THEN
 
*  Real data.
*  ==========
         DO I = 1, NVAL
 
*  Make the SLALIB do the difficult part.  The pointer is updated.
            CALL SLA_FLOTIN( STRING, ORIGIN, VALUES( I ), ISTAT )
 
*  Check for an error condition, reporting the error and aborting.
            IF ( ISTAT .GT. 0 ) THEN
               STATUS = SAI__ERROR
               CALL MSG_SETI( 'N', ORIGIN )
               CALL MSG_SETC( 'STRING', STRING )
               CALL ERR_REP( 'KPG1_FFRx',
     :           'Error decoding the string: "^STRING" from column '/
     :           /'^N.', STATUS )
               GOTO 999
            END IF
         END DO
 
      ELSE
 
*  Double-precision data.
*  ======================
         DO I = 1, NVAL
 
*  Make the SLALIB do the difficult part.
            CALL SLA_DFLTIN( STRING, ORIGIN, VALUES( I ), ISTAT )
 
*  Check for an error condition, reporting the error and aborting.
            IF ( ISTAT .GT. 0 ) THEN
               STATUS = SAI__ERROR
               CALL MSG_SETI( 'N', ORIGIN )
               CALL MSG_SETC( 'STRING', STRING )
               CALL ERR_REP( 'KPG1_FFRx',
     :           'Error decoding the string: "^STRING" from column '/
     :           /'^N.', STATUS )
               GOTO 999
            END IF
         END DO
      END IF
 
  999 CONTINUE
 
      END
