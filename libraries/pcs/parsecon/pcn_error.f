*+  PARSECON_ERROR - Error report for interface parser
      SUBROUTINE PARSECON_ERROR ( LINENUM, TOKEN, STATUS )
*    Description :
*     Produces an error message when an error has been detected in 
*     parsing an interface file.
*    Invocation :
*     CALL PARSECON_ERROR ( LINENUM, TOKEN, STATUS )
*    Parameters :
*     LINENUM=INTEGER (given)
*           line number in interface file
*     TOKEN=CHARACTER*(*) (given)
*           current token when the error was detected
*     STATUS=INTEGER (given)
*           the error detected
*    Method :
*     The number and text of the line in which the error occurred is
*     reported along with the action and parameter names if active,
*     the error message corresponding to the status and the current
*     token.
*     The error message stack is then flushed using PARSECON_ERFL

*    Deficiencies :
*    Bugs :
*     <description of any "bugs" which have not been fixed>
*    Authors :
*     B.D.Kelly (REVAD::BDK)
*     A J Chipperfield (STARLINK)
*    History :
*     02.10.1984:  Original (REVAD::BDK)
*     17.11.1984:  Use LIB$SIGNAL (REVAD::BDK)
*     16.08.1990:  Add line, interface and parameter (RLVAD::AJC)
*     12.06.1991:  Use EMS for reporting (RLVAD::AJC)
*     21.02.1992:  Modify messages for full EMS compliance (RLVAD::AJC)
*     24.03.1993:  Add DAT_PAR for SUBPAR_CMN
*    endhistory
*    Type Definitions :
      IMPLICIT NONE

*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'

*    Import :
      INTEGER LINENUM                ! line number in interface file

      CHARACTER*(*) TOKEN            ! current token

      INTEGER STATUS                 ! error code

*    Global variables :
      INCLUDE 'SUBPAR_CMN'
      INCLUDE 'PARSECON3_CMN'

*    External references :
      INTEGER CHR_LEN
      EXTERNAL CHR_LEN

*    Local Variables :
      INTEGER ISTAT                  ! local status

*-
      CALL EMS_SETI( 'LINENUM', LINENUM )
      CALL EMS_REP( 'PCN_ERROR1',
     :'Interface file error at line ^LINENUM', 
     : STATUS )

      CALL EMS_SETC( 'BUFFER', BUFFER(1:BUFFLEN) )
      CALL EMS_REP( 'PCN_ERROR2', '// ^BUFFER //', STATUS )
!      TYPE *, '// ',BUFFER(1:BUFFLEN),' //'

      IF (PRNAME .NE. ' ') THEN
         CALL EMS_SETC( 'PRNAME', PRNAME )
         CALL EMS_SETC( 'ACNAME', ACNAME )
         CALL EMS_REP( 'PCN_ERROR3', 
     :    'In parameter ^PRNAME specification '/
     :    /'in interface/action ^ACNAME', STATUS )

      ELSEIF (ACNAME .NE. ' ') THEN
         CALL EMS_SETC( 'ACNAME', ACNAME )
         CALL EMS_REP( 'PCN_ERROR4',
     :    'In interface/action ^ACNAME', STATUS )
      ENDIF

      IF (TOKEN .NE. ' ') THEN
         CALL EMS_SETC( 'TOKEN', TOKEN )
         CALL EMS_REP( 'PCN_ERROR6',
     :    'Token objected to is: ^TOKEN', STATUS )
      ENDIF

      CALL EMS_REP( 'PCN_ERROR7', ' ', STATUS )

*  Now flush any pending messages
      CALL PARSECON_ERFL( ISTAT )     

      END

