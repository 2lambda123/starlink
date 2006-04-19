      SUBROUTINE PARSECON_FINDACT ( NAME, NAMECODE, STATUS )
*+
*  Name:
*     PARSECON_FINDACT

*  Purpose:
*     Search action-list for named action.

*  Language:
*     VAX Fortran

*  Invocation:
*     CALL PARSECON_FINDACT ( NAME, NAMECODE, STATUS )

*  Description:
*     Search the list of actions for the given name, and if it is found,
*     return its index.

*  Arguments:
*     NAME=CHARACTER*(*) (given)
*        name of requested action
*     NAMECODE=INTEGER (returned)
*        index number of action, if found.
*     STATUS=INTEGER

*  Algorithm:
*     The list of action names is searched sequentially

*  Authors:
*     B.D.Kelly (REVAD::BDK)
*     A J Chipperfield (STARLINK)
*     {enter_new_authors_here}

*  History:
*     02.10.1984:  Original (REVAD::BDK)
*     24.02.1991:  Report errors (RLVAD::AJC)
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
      INCLUDE 'PARSECON_ERR'


*  Arguments Given:
      CHARACTER*(*) NAME                 ! name to be found


*  Arguments Returned:
      INTEGER NAMECODE                   ! index of NAME if found


*  Status:
      INTEGER STATUS


*  Global Variables:
      INCLUDE 'SUBPAR_CMN'


*  Local Variables:
      LOGICAL FOUND


*.


      IF ( STATUS .NE. SAI__OK ) RETURN

      NAMECODE = 0
      FOUND = .FALSE.

      DO WHILE ( ( .NOT. FOUND ) .AND. ( NAMECODE .LT. ACTPTR ) )

         NAMECODE = NAMECODE + 1
         IF ( NAME .EQ. ACTNAMES(NAMECODE) ) FOUND = .TRUE.

      ENDDO

      IF ( .NOT. FOUND ) THEN
         STATUS = PARSE__NOACT
         CALL EMS_SETC ( 'NAME', NAME )
         CALL EMS_REP ( 'PCN_FINDACT1',
     :   'PARSECON: Action ^NAME not defined', STATUS )
         NAMECODE = 0
      ENDIF

      END
