      BYTE FUNCTION VAL_EXPUB( BAD, ARG, STATUS )
*+
*  Name:
*     VAL_EXPUB
 
*  Purpose:
*     Evaluate the UNSIGNED BYTE exponential function.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     RESULT = VAL_EXPUB( BAD, ARG, STATUS )
 
*  Description:
*     The routine evaluates the exponential function for a single
*     argument of type UNSIGNED BYTE.  If a numerical error occurs, the value
*     VAL__BADUB is returned and a STATUS value is set.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether the argument value (ARG) may be "bad".
*     ARG = BYTE (Given)
*        The UNSIGNED BYTE argument of the exponential function.
*     STATUS = INTEGER (Given & Returned)
*        This should be set to SAI__OK on entry, otherwise the routine
*        returns immediately with the result VAL__BADUB.  A STATUS
*        value will be set by this routine if a numerical error occurs.
 
*  Returned Value:
*     VAL_EXPUB = BYTE
*        Returns the evaluated exponential function result as a UNSIGNED BYTE
*        value.  The value VAL__BADUB will be returned under error
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
      BYTE ARG                 ! Function argument
 
*  Status:
      INTEGER STATUS             ! Error status
 
*  External References:
      EXTERNAL NUM_TRAP          ! Error handling routine
 
*  Global Variables:
      INCLUDE 'NUM_CMN'          ! Define NUM_ERROR flag

 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! Declare NUM_ conversion functions

      INCLUDE 'NUM_DEC_UB'      ! Declare NUM_ arithmetic functions

      INCLUDE 'NUM_DEF_CVT'      ! Define NUM_ conversion functions

      INCLUDE 'NUM_DEF_UB'      ! Define NUM_ arithmetic functions

 
*.
 
*  Check status.  Return the function result VAL__BADUB if not OK.
      IF( STATUS .NE. SAI__OK ) THEN
         VAL_EXPUB = VAL__BADUB
 
*  If the bad data flag is set, check if the argument given is bad.
*  Return VAL__BADUB if it is.
      ELSE IF( BAD .AND. ( ARG .EQ. VAL__BADUB ) ) THEN
         VAL_EXPUB = VAL__BADUB
 
*  Check if the argument value is acceptable.  If not, return the
*  result VAL__BADUB and set a STATUS value.
      ELSE IF( .NOT. ( .TRUE. ) ) THEN
         VAL_EXPUB = VAL__BADUB
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
         VAL_EXPUB = NUM_EXPUB( ARG )
 
*  If an error handler is established, check if the numerical error
*  flag is set.  If so, return the result VAL__BADUB and set STATUS to
*  NUM_ERROR.
         IF( .TRUE. ) THEN
            IF( NUM_ERROR .NE. SAI__OK ) THEN
               VAL_EXPUB = VAL__BADUB
               STATUS = NUM_ERROR
            ENDIF
 
*  Remove the error handler.
            CALL NUM_REVRT
         ENDIF
      ENDIF
 
*  Exit routine.
      END
