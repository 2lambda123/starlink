      BYTE FUNCTION VAL_LG10B( BAD, ARG, STATUS )
*+
*  Name:
*     VAL_LG10B
 
*  Purpose:
*     Evaluate the BYTE common logarithm (base 10) function.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     RESULT = VAL_LG10B( BAD, ARG, STATUS )
 
*  Description:
*     The routine evaluates the common logarithm (base 10) function for a single
*     argument of type BYTE.  If a numerical error occurs, the value
*     VAL__BADB is returned and a STATUS value is set.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether the argument value (ARG) may be "bad".
*     ARG = BYTE (Given)
*        The BYTE argument of the common logarithm (base 10) function.
*     STATUS = INTEGER (Given & Returned)
*        This should be set to SAI__OK on entry, otherwise the routine
*        returns immediately with the result VAL__BADB.  A STATUS
*        value will be set by this routine if a numerical error occurs.
 
*  Returned Value:
*     VAL_LG10B = BYTE
*        Returns the evaluated common logarithm (base 10) function result as a BYTE
*        value.  The value VAL__BADB will be returned under error
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

      INCLUDE 'NUM_DEC_B'      ! Declare NUM_ arithmetic functions

      INCLUDE 'NUM_DEF_CVT'      ! Define NUM_ conversion functions

      INCLUDE 'NUM_DEF_B'      ! Define NUM_ arithmetic functions

 
*.
 
*  Check status.  Return the function result VAL__BADB if not OK.
      IF( STATUS .NE. SAI__OK ) THEN
         VAL_LG10B = VAL__BADB
 
*  If the bad data flag is set, check if the argument given is bad.
*  Return VAL__BADB if it is.
      ELSE IF( BAD .AND. ( ARG .EQ. VAL__BADB ) ) THEN
         VAL_LG10B = VAL__BADB
 
*  Check if the argument value is acceptable.  If not, return the
*  result VAL__BADB and set a STATUS value.
      ELSE IF( .NOT. ( NUM_GTB( ARG, VAL__ZB ) ) ) THEN
         VAL_LG10B = VAL__BADB
         STATUS = PRM__LOGZN
 
*  If the argument value is acceptable then, if required, establish the
*  numerical error handler and initialise the common block error
*  status.
      ELSE
         IF( .FALSE. ) THEN
            CALL NUM_HANDL( NUM_TRAP )
            NUM_ERROR = SAI__OK
         ENDIF
 
*  Evaluate the function.
         VAL_LG10B = NUM_LG10B( ARG )
 
*  If an error handler is established, check if the numerical error
*  flag is set.  If so, return the result VAL__BADB and set STATUS to
*  NUM_ERROR.
         IF( .FALSE. ) THEN
            IF( NUM_ERROR .NE. SAI__OK ) THEN
               VAL_LG10B = VAL__BADB
               STATUS = NUM_ERROR
            ENDIF
 
*  Remove the error handler.
            CALL NUM_REVRT
         ENDIF
      ENDIF
 
*  Exit routine.
      END
