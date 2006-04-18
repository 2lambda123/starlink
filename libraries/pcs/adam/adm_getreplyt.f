      SUBROUTINE ADAM_GETREPLYT ( TIME, PATH, MESSID, CONTEXT, NAME,
     :  VALUE, STATUS )
*+
*  Name:
*     ADAM_GETREPLYT

*  Purpose:
*     wait for incoming message from specified path & messid.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL ADAM_GETREPLYT ( TIME, PATH, MESSID, CONTEXT, NAME,
*    :                      VALUE, STATUS)

*  Description:
*     Waits for a message from a particular path and with a particular
*     ID to arrive at this task, and returns with the message and
*     associated parameters provided the timeout period has not expired.

*  Arguments:
*     TIME=INTEGER (given)
*        timeout time in 1ms increments
*     PATH=INTEGER (given)
*        required path of the received message
*     MESSID=INTEGER (given)
*        required message number of received message
*     CONTEXT=INTEGER (returned)
*        parameterised 'get, set, obey, cancel'
*     NAME=CHARACTER*(*) (returned)
*        name of function or parameter
*     VALUE=CHARACTER*(*) (returned)
*        received value
*     STATUS=INTEGER

*  Algorithm:
*     Call MESSYS_GETREPLY and interpret the data structure returned.

*  Authors:
*     Charlie Richardson (REVA::DCR)
*     Dennis Kelly (ROE)
*     Alan Chipperfield (RAL)
*     {enter_new_authors_here}

*  History:
*     25-FEB-1985 (DCR):
*        Original.
*     26-FEB-1985 (ADAM):
*        First insertion
*     06-JUN-1986 (BDK):
*        Return values even if bad status from MESSYS
*     12-NOV-1992 (AJC):
*        Use SAI__OK not ADAM__OK
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE

*  Global Constants:
      INCLUDE 'SAE_PAR'

*  Arguments Given:
      INTEGER TIME        ! timeout time in 1ms increments
      INTEGER PATH        !  required path of the received message
      INTEGER MESSID      !  required message number of received message

*  Arguments Returned:
      INTEGER CONTEXT     !  parameterised 'get, set, obey, cancel'
      CHARACTER NAME*(*)  !  name of function or parameter
      CHARACTER VALUE*(*) !  received value

*  Status:
      INTEGER STATUS
*    Data structures for ADAM:
      INCLUDE 'MESSYS_DD'

*.


      IF ( STATUS .NE. SAI__OK ) THEN
         RETURN
      ENDIF

      CALL MESSYS_GETREPLY ( TIME, PATH, MESSID, MSG, STATUS )

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
