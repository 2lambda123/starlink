      BYTE FUNCTION VAL_MAXB( BAD, ARG1, ARG2, STATUS )
*+
*  Name:
*     VAL_MAXB
 
*  Purpose:
*     Evaluate the BYTE maximum function.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     RESULT = VAL_MAXB( BAD, ARG1, ARG2, STATUS )
 
*  Description:
*     The routine evaluates the maximum function for a pair of
*     arguments of type BYTE.  If a numerical error occurs, the value
*     VAL__BADB is returned and a STATUS value is set.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether the argument values (ARG1 & ARG2) may be "bad".
*     ARG1, ARG2 = BYTE (Given)
*        The two BYTE arguments of the maximum function.
*     STATUS = INTEGER (Given & Returned)
*        This should be set to SAI__OK on entry, otherwise the routine
*        returns immediately with the result VAL__BADB.  A STATUS
*        value will be set by this routine if a numerical error occurs.
 
*  Returned Value:
*     VAL_MAXB = BYTE
*        Returns the evaluated maximum function result as a BYTE
*        value.  The value VAL__BADB will be returned under error
*        conditions.
 
*  Authors:
*     R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     11-AUG-1987 (RFWS):
*        Original version.
*     28-OCT-1991 (RFWS):
*        Added LIB$REVERT call.
*     7-NOV-1991 (RFWS):
*        Changed to use NUM_TRAP.
*     27-SEP-1995 (BKM):
*        Changed LIB$ESTABLISH and LIB$REVERT calls to NUM_HANDL and NUM_REVRT
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

      INCLUDE 'PRM_PAR'          ! PRM_ public constants

      INCLUDE 'PRM_CONST'        ! PRM_ private constants

      INCLUDE 'PRM_ERR'          ! PRM_ error codes

 
*  Arguments Given:
      LOGICAL BAD                ! Bad data flag
      BYTE ARG1                ! Function argument 1
      BYTE ARG2                ! Function argument 2
 
*  Status:
      INTEGER STATUS             ! Error status
 
*  External References:
      EXTERNAL NUM_TRAP          ! Error handling routine
 
*  Global Variables:
      INCLUDE 'NUM_CMN'          ! Define NUM_ERROR flag

 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! Declare NUM_ conversion functions

      INCLUDE 'NUM_DEC_B'      ! Declare NUM_ arithmetic functions

      INCLUDE 'NUM_DEF_CVT'      ! Define NUM_ conversion functions

      INCLUDE 'NUM_DEF_B'      ! Define NUM_ arithmetic functions

 
*.
 
*  Check status.  Return the function result VAL__BADB if not OK.
      IF( STATUS .NE. SAI__OK ) THEN
         VAL_MAXB = VAL__BADB
 
*  If the bad value flag is set, check the arguments given are not bad.
*  Return VAL__BADB if either is.
      ELSE IF( BAD .AND. ( ( ARG1 .EQ. VAL__BADB ) .OR.
     :                     ( ARG2 .EQ. VAL__BADB ) ) ) THEN
         VAL_MAXB = VAL__BADB
 
*  Check if the argument values are acceptable.  If not, return the
*  result VAL__BADB and set a STATUS value.
      ELSE IF( .NOT. ( .TRUE. ) ) THEN
         VAL_MAXB = VAL__BADB
         STATUS = SAI__OK
 
*  If the argument values are acceptable then, if required, establish a
*  numerical error handler and initialise the common block error flag.
      ELSE
         IF( .FALSE. ) THEN
            CALL NUM_HANDL( NUM_TRAP )
            NUM_ERROR = SAI__OK
         ENDIF
 
*  Evaluate the function.
         VAL_MAXB = NUM_MAXB( ARG1, ARG2 )
 
*  If an error handler is established, check if the numerical error
*  flag is set.  If so, return the result VAL__BADB and set STATUS to
*  NUM_ERROR.
         IF( .FALSE. ) THEN
            IF( NUM_ERROR .NE. SAI__OK ) THEN
               VAL_MAXB = VAL__BADB
               STATUS = NUM_ERROR
            ENDIF
 
*  Remove the error handler.
            CALL NUM_REVRT
         ENDIF
      ENDIF
 
*  Exit routine.
      END
