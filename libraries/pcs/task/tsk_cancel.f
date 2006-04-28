      SUBROUTINE TASK_CANCEL ( TASK_NAME, NAME, INVAL, OUTVAL, STATUS )
*+
*  Name:
*     TASK_CANCEL

*  Purpose:
*     Request a task to cancel an action

*  Language:
*     Starlink Fortran 77

*  Type Of Module:
*     SUBROUTINE

*  Invocation:
*     CALL TASK_CANCEL ( TASK_NAME, NAME, INVAL, OUTVAL, STATUS )

*  Description:
*     Request the named task to cancel the named action.

*  Arguments:
*     TASK_NAME=CHARACTER*(*) (given)
*           the name of the task
*     NAME=CHARACTER*(*) (given)
*           the name of the action
*     INVAL=CHARACTER*(*) (given)
*           the parameter list to be sent to the task
*     OUTVAL=CHARACTER*(*) (returned)
*           the string returned from the task
*     STATUS=INTEGER

*  Algorithm:
*     Establish the communication path to the named task and send it a 
*     message.

*  Authors:
*     B.D.Kelly (REVAD::BDK)
*     {enter_new_authors_here}

*  History:
*     05-NOV-1987 (REVAD::BDK):
*        Original
*     08-AUG-1991 (REVAD::BDK):
*        Do message forwarding
*     11-JUN-2001 (AJC):
*        Replace ADAM calls with AMS
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'SAE_PAR'
      INCLUDE 'ADAM_DEFNS'
      INCLUDE 'MESSYS_PAR'
*  Arguments Given:
      CHARACTER*(*) TASK_NAME     ! the name of the task
      CHARACTER*(*) NAME          ! the name of the action
      CHARACTER*(*) INVAL         ! the parameter list to be sent to the 
                                  ! task
*  Arguments Returned:
      CHARACTER*(*) OUTVAL        ! the string returned from the task

*  Status:
      INTEGER STATUS

*  Local Variables:
      INTEGER PATH                 ! path to task
      INTEGER MESSID               ! message id for the cancel
      INTEGER MESLEN               ! length of INVAL
*.

      IF ( STATUS .NE. SAI__OK ) RETURN

      CALL FAMS_PATH ( TASK_NAME, PATH, STATUS )
      MESLEN = MIN( LEN(INVAL), MESSYS__VAL_LEN )
      CALL FAMS_SEND( PATH, MESSYS__MESSAGE, SAI__OK, CANCEL, NAME,
     :  MESLEN, INVAL, MESSID, STATUS )
      CALL TASK_DONE ( MESSYS__INFINITE, PATH, MESSID, OUTVAL, STATUS )

      END
