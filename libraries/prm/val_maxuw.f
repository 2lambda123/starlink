      INTEGER*2 FUNCTION VAL_MAXUW( BAD, ARG1, ARG2, STATUS )
*+
*  Name:
*     VAL_MAXUW
 
*  Purpose:
*     Evaluate the UNSIGNED WORD maximum function.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     RESULT = VAL_MAXUW( BAD, ARG1, ARG2, STATUS )
 
*  Description:
*     The routine evaluates the maximum function for a pair of
*     arguments of type UNSIGNED WORD.  If a numerical error occurs, the value
*     VAL__BADUW is returned and a STATUS value is set.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether the argument values (ARG1 & ARG2) may be "bad".
*     ARG1, ARG2 = INTEGER*2 (Given)
*        The two UNSIGNED WORD arguments of the maximum function.
*     STATUS = INTEGER (Given & Returned)
*        This should be set to SAI__OK on entry, otherwise the routine
*        returns immediately with the result VAL__BADUW.  A STATUS
*        value will be set by this routine if a numerical error occurs.
 
*  Returned Value:
*     VAL_MAXUW = INTEGER*2
*        Returns the evaluated maximum function result as a UNSIGNED WORD
*        value.  The value VAL__BADUW will be returned under error
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
      INTEGER*2 ARG1                ! Function argument 1
      INTEGER*2 ARG2                ! Function argument 2
 
*  Status:
      INTEGER STATUS             ! Error status
 
*  External References:
      EXTERNAL NUM_TRAP          ! Error handling routine
 
*  Global Variables:
      INCLUDE 'NUM_CMN'          ! Define NUM_ERROR flag

 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! Declare NUM_ conversion functions

      INCLUDE 'NUM_DEC_UW'      ! Declare NUM_ arithmetic functions

      INCLUDE 'NUM_DEF_CVT'      ! Define NUM_ conversion functions

      INCLUDE 'NUM_DEF_UW'      ! Define NUM_ arithmetic functions

 
*.
 
*  Check status.  Return the function result VAL__BADUW if not OK.
      IF( STATUS .NE. SAI__OK ) THEN
         VAL_MAXUW = VAL__BADUW
 
*  If the bad value flag is set, check the arguments given are not bad.
*  Return VAL__BADUW if either is.
      ELSE IF( BAD .AND. ( ( ARG1 .EQ. VAL__BADUW ) .OR.
     :                     ( ARG2 .EQ. VAL__BADUW ) ) ) THEN
         VAL_MAXUW = VAL__BADUW
 
*  Check if the argument values are acceptable.  If not, return the
*  result VAL__BADUW and set a STATUS value.
      ELSE IF( .NOT. ( .TRUE. ) ) THEN
         VAL_MAXUW = VAL__BADUW
         STATUS = SAI__OK
 
*  If the argument values are acceptable then, if required, establish a
*  numerical error handler and initialise the common block error flag.
      ELSE
         IF( .FALSE. ) THEN
            CALL NUM_HANDL( NUM_TRAP )
            NUM_ERROR = SAI__OK
         ENDIF
 
*  Evaluate the function.
         VAL_MAXUW = NUM_MAXUW( ARG1, ARG2 )
 
*  If an error handler is established, check if the numerical error
*  flag is set.  If so, return the result VAL__BADUW and set STATUS to
*  NUM_ERROR.
         IF( .FALSE. ) THEN
            IF( NUM_ERROR .NE. SAI__OK ) THEN
               VAL_MAXUW = VAL__BADUW
               STATUS = NUM_ERROR
            ENDIF
 
*  Remove the error handler.
            CALL NUM_REVRT
         ENDIF
      ENDIF
 
*  Exit routine.
      END
