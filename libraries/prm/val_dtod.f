      DOUBLE PRECISION FUNCTION VAL_DTOD( BAD, ARG, STATUS )
*+
*  Name:
*     VAL_DTOD
 
*  Purpose:
*     Copy a DOUBLE PRECISION value.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     RESULT = VAL_DTOD( BAD, ARG, STATUS )
 
*  Description:
*     The routine copies a value of type DOUBLE PRECISION.  It forms part of the
*     set of type conversion routines, but in this instance the
*     argument and result types are both the same, so the argument
*     value is simply copied.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether the argument value (ARG) may be "bad" (this argument
*        actually has no effect on the behaviour of this routine, but
*        is present to match the other type conversion routines).
*     ARG = DOUBLE PRECISION (Given)
*        The DOUBLE PRECISION value to be copied.
*     STATUS = INTEGER (Given)
*        This should be set to SAI__OK on entry, otherwise the routine
*        returns immediately with the result VAL__BADD.  This routine
*        cannot produce numerical errors, so the STATUS argument will
*        not be changed.
 
*  Returned Value:
*     VAL_DTOD = DOUBLE PRECISION
*        Returns the copied DOUBLE PRECISION value.  The value VAL__BADD will
*        be returned if STATUS is not SAI__OK on entry.
 
*  Authors:
*     R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     4-JUL-1988 (RFWS):
*        Original version.
*     {enter_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

      INCLUDE 'PRM_PAR'          ! PRM_ public constants

 
*  Arguments Given:
      LOGICAL BAD                ! Bad data flag
      DOUBLE PRECISION ARG                 ! Value to be copied
 
*  Status:
      INTEGER STATUS             ! Error status
 
*.
 
*  Check status.  Return the function result VAL__BADD if not OK.
      IF( STATUS .NE. SAI__OK ) THEN
         VAL_DTOD = VAL__BADD
 
*  If OK, return the argument value.
      ELSE
         VAL_DTOD = ARG
      ENDIF
 
*  Exit routine.
      END
