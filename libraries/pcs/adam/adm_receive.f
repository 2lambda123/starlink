*+  ADAM_RECEIVE - wait for incoming message
      SUBROUTINE ADAM_RECEIVE ( PATH, CONTEXT, NAME, VALUE,
     :                          MESSID, STATUS )
*    Description :
*     Waits for a message to arrive at this task, and returns with the message
*     and associated parameters.
*     If any messages are already waiting on the message list they will be
*     picked up and returned in chronological order by calls to this 
*     routine.
*    Invocation :
*     CALL ADAM_RECEIVE ( PATH, CONTEXT, NAME, VALUE, MESSID, STATUS )
*    Parameters :
*     PATH=INTEGER (returned)
*           pointer to the path back to the originating task
*     CONTEXT=INTEGER (returned)
*           parameterised 'get, set, obey, cancel'
*     NAME=CHARACTER*(*) (given)
*           name of required function or parameter
*     VALUE=CHARACTER*(*) (returned)
*           received message
*     MESSID=INTEGER (given)
*           message number of received message
*    Method :
*     Receive the message data structure using MESSYS_RECEIVE with 
*     infinite timeout, and split it into its components.
*    Deficiencies :
*     <description of any deficiencies>
*    Bugs :
*     <description of any "bugs" which have not been fixed>
*    Authors :
*     John Cooke (REVAD::JAC) <date>
*    History :
*     date:  changes (institution::username)
*     3-MAY-1984  first insertion (REVAD::JAC)
*     22-MAY-1984  return "msg_status" as status (REVA::ADAM])
*     10-OCT-1984  change "normal" to "adam__OK" (REVA::ADAM)
*     09-JUN-1986  return message even when status bad (REVAD::BDK)
*     12-NOV-1992:  use SAI__OK not ADAM__OK (RLVAD::AJC)
*      8-MAR-1993: use MESSYS_PAR and MESSYS__INFINITE
*                  not MESDEFNS and INFINITE (RLVAD::AJC)
*    endhistory
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'MESSYS_PAR'
*    Export :
      INTEGER PATH        !  pointer to the path back to the originating task
      INTEGER CONTEXT     !  parameterised 'get, set, obey, cancel'
      CHARACTER NAME*(*)  !  name of required function or parameter
      CHARACTER VALUE*(*) !  received value (usually in packed form)
      INTEGER MESSID      !  message number of received message
*    Status :
      INTEGER STATUS 
*    Local Constants :
      INTEGER TIMEOUT
      PARAMETER ( TIMEOUT = MESSYS__INFINITE )
*    Data structures for ADAM:
      INCLUDE 'DDMSG'
*-

      IF ( STATUS .NE. SAI__OK ) THEN
         RETURN
      ENDIF

      CALL MESSYS_RECEIVE ( TIMEOUT, PATH, MSG, MESSID, STATUS )

      CONTEXT = MSG_CONTEXT
      NAME = MSG_NAME

      IF ( MSG_LENGTH .GT. 0 ) THEN
         VALUE = MSG_VAL(1:MSG_LENGTH)
      ELSE
         VALUE = ' '
      ENDIF

      IF ( STATUS .EQ. SAI__OK ) THEN
         STATUS = MSG_STATUS
      ENDIF

      END

