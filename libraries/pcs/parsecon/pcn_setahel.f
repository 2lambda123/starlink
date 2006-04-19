      SUBROUTINE PARSECON_SETAHEL ( ENTRY, STATUS )
*+
*  Name:
*     PARSECON_SETAHEL

*  Purpose:
*     Sets-up action help text.

*  Language:
*     VAX Fortran

*  Invocation:
*     CALL PARSECON_SETAHEL ( ENTRY, STATUS )

*  Description:
*     Loads the provided string into the help store for the most
*     recently declared program action.

*  Arguments:
*     ENTRY=CHARACTER*(*) (given)
*        help string
*     STATUS=INTEGER

*  Algorithm:
*     Superfluous quotes are removed from the given string, and the
*     result is put into the array holding help text.

*  Authors:
*     B.D.Kelly (REVAD::BDK)
*     A J Chipperfield (STARLINK)
*     {enter_new_authors_here}

*  History:
*     13.05.1986:  Original (REVAD::BDK)
*     16.10.1990:  define QUOTE portably (RLVAD::AJC)
*     24.03.1993:  Add DAT_PAR for SUBPAR_CMN
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE


*  Global Constants:
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'


*  Arguments Given:
      CHARACTER*(*) ENTRY             ! the help string


*  Status:
      INTEGER STATUS


*  Global Variables:
      INCLUDE 'SUBPAR_CMN'


*  Local Constants:
      CHARACTER*(*) QUOTE
      PARAMETER ( QUOTE = '''' )


*.


      IF ( STATUS .NE. SAI__OK ) RETURN

*   If the help text is a quoted string, process the quotes
      IF ( ENTRY(1:1) .EQ. QUOTE ) THEN
         CALL STRING_STRIPQUOT ( ENTRY, ACTHELP(ACTPTR), STATUS )

      ELSE
         ACTHELP(ACTPTR) = ENTRY

      ENDIF

      END
