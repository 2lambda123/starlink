      INTEGER*2 FUNCTION VAL_EXPUW( BAD, ARG, STATUS )
*+
*  Name:
*     VAL_EXPUW
 
*  Purpose:
*     Evaluate the UNSIGNED WORD exponential function.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     RESULT = VAL_EXPUW( BAD, ARG, STATUS )
 
*  Description:
*     The routine evaluates the exponential function for a single
*     argument of type UNSIGNED WORD.  If a numerical error occurs, the value
*     VAL__BADUW is returned and a STATUS value is set.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether the argument value (ARG) may be "bad".
*     ARG = INTEGER*2 (Given)
*        The UNSIGNED WORD argument of the exponential function.
*     STATUS = INTEGER (Given & Returned)
*        This should be set to SAI__OK on entry, otherwise the routine
*        returns immediately with the result VAL__BADUW.  A STATUS
*        value will be set by this routine if a numerical error occurs.
 
*  Returned Value:
*     VAL_EXPUW = INTEGER*2
*        Returns the evaluated exponential function result as a UNSIGNED WORD
*        value.  The value VAL__BADUW will be returned under error
*        conditions.
 
*  Authors:
*     R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     15-AUG-1987 (RFWS):
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
      INTEGER*2 ARG                 ! Function argument
 
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
         VAL_EXPUW = VAL__BADUW
 
*  If the bad data flag is set, check if the argument given is bad.
*  Return VAL__BADUW if it is.
      ELSE IF( BAD .AND. ( ARG .EQ. VAL__BADUW ) ) THEN
         VAL_EXPUW = VAL__BADUW
 
*  Check if the argument value is acceptable.  If not, return the
*  result VAL__BADUW and set a STATUS value.
      ELSE IF( .NOT. ( .TRUE. ) ) THEN
         VAL_EXPUW = VAL__BADUW
         STATUS = SAI__OK
 
*  If the argument value is acceptable then, if required, establish the
*  numerical error handler and initialise the common block error
*  status.
      ELSE
         IF( .TRUE. ) THEN
            CALL NUM_HANDL( NUM_TRAP )
            NUM_ERROR = SAI__OK
         ENDIF
 
*  Evaluate the function.
         VAL_EXPUW = NUM_EXPUW( ARG )
 
*  If an error handler is established, check if the numerical error
*  flag is set.  If so, return the result VAL__BADUW and set STATUS to
*  NUM_ERROR.
         IF( .TRUE. ) THEN
            IF( NUM_ERROR .NE. SAI__OK ) THEN
               VAL_EXPUW = VAL__BADUW
               STATUS = NUM_ERROR
            ENDIF
 
*  Remove the error handler.
            CALL NUM_REVRT
         ENDIF
      ENDIF
 
*  Exit routine.
      END
