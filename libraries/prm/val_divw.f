      INTEGER*2 FUNCTION VAL_DIVW( BAD, ARG1, ARG2, STATUS )
*+
*  Name:
*     VAL_DIVW
 
*  Purpose:
*     Perform a WORD floating divide operation.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     RESULT = VAL_DIVW( BAD, ARG1, ARG2, STATUS )
 
*  Description:
*     The routine performs an arithmetic floating divide operation between
*     a pair of arguments of type WORD.  If a numerical error occurs,
*     the value VAL__BADW is returned and a STATUS value is set.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether the argument values (ARG1 & ARG2) may be "bad".
*     ARG1, ARG2 = INTEGER*2 (Given)
*        The two WORD arguments for the floating divide operation.
*     STATUS = INTEGER (Given & Returned)
*        This should be set to SAI__OK on entry, otherwise the routine
*        returns immediately with the result VAL__BADW.  A STATUS
*        value will be set by this routine if a numerical error occurs.
 
*  Returned Value:
*     VAL_DIVW = INTEGER*2
*        Returns the result of the floating divide operation as a value of
*        type WORD.  The value returned is:
*
*           VAL_DIVW = ARG1 / ARG2
*
*        The value VAL__BADW will be returned under error conditions.
 
*  Authors:
*     R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     11-AUG-1988 (RFWS):
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

 
*  Arguments Given:
      LOGICAL BAD                ! The bad data flag
      INTEGER*2 ARG1                ! The first argument
      INTEGER*2 ARG2                ! The second argument
 
*  Status:
      INTEGER STATUS             ! Error status
 
*  External References:
      EXTERNAL NUM_TRAP          ! Error handling routine
 
*  Global Variables:
      INCLUDE 'NUM_CMN'          ! Define NUM_ERROR flag

 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! Declare NUM_ conversion functions

      INCLUDE 'NUM_DEC_W'      ! Declare NUM_ arithmetic functions

      INCLUDE 'NUM_DEF_CVT'      ! Define NUM_ conversion functions

      INCLUDE 'NUM_DEF_W'      ! Define NUM_ arithmetic functions

 
*.
 
*  Check status.  Return the function result VAL__BADW if not OK.
      IF( STATUS .NE. SAI__OK ) THEN
         VAL_DIVW = VAL__BADW
 
*  If the bad value flag is set, check the arguments given are not bad.
*  Return VAL__BADW if either is.
      ELSE IF( BAD .AND.( ( ARG1 .EQ. VAL__BADW ) .OR.
     :                    ( ARG2 .EQ. VAL__BADW ) ) ) THEN
         VAL_DIVW = VAL__BADW
 
*  Establish the error handler and initialise the common block error
*  flag.
      ELSE
         CALL NUM_HANDL( NUM_TRAP )
         NUM_ERROR = SAI__OK
 
*  Perform the floating divide operation.
         VAL_DIVW = NUM_DIVW( ARG1, ARG2 )
 
*  Check if the numerical error flag is set.  If so, return the result
*  VAL__BADW and set STATUS to NUM_ERROR.
         IF( NUM_ERROR .NE. SAI__OK ) THEN
            VAL_DIVW = VAL__BADW
            STATUS = NUM_ERROR
         ENDIF
 
*  Remove the error handler.
         CALL NUM_REVRT
      ENDIF
 
*  Exit routine.
      END
