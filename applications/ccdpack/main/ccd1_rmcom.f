      SUBROUTINE CCD1_RMCOM( LINE, NCHAR, STATUS )
*+
*  Name:
*     CCD1_RMCOM

*  Purpose:
*     To check for in-line comments.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCD1_RMCOM( LINE, NCHAR, STATUS )

*  Description:
*     The routine checks the given line of data for the presence of any
*     of the comment delimiters `!' or `#'. If it finds any then the
*     line character counter is set to truncate to the right of this
*     place, excluding trailing blanks. The input string is unmodified.

*  Arguments:
*     LINE = CHARACTER * ( * ) (Given)
*        The line to be checked for in line comments.
*     NCHAR = INTEGER (Given and Returned)
*        The  number of non-blank characters (from start), excluding
*        in-line comments. Used to trim string to relevant part.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1-OCT-1991 (PDRAPER):
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
      CHARACTER * ( * ) LINE

*  Arguments Returned:
      INTEGER NCHAR

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER CHR_LEN
      EXTERNAL CHR_LEN           ! Length of string excluding trailing
                                 ! blanks
*  Local Variables:
      INTEGER IAT                ! Position of in-line comment.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Look for occurences of the comment delimeters.
      IAT = INDEX( LINE, '!' )
      IF ( IAT .EQ. 0 ) THEN
         IAT = INDEX( LINE, '#' )
      END IF

*  If have found an in-line comment then truncate.
      IF ( IAT .NE. 0 ) THEN
         IF ( IAT .EQ. 1 ) THEN

*  Actually this is a comment line return NCHAR = 0
            NCHAR = 0
         ELSE
            IF ( IAT .GE. 2 ) THEN
               NCHAR = CHR_LEN( LINE( : IAT - 1 ) )
            ELSE
               NCHAR = 0
            END IF
         END IF
      END IF

      END
* $Id$
