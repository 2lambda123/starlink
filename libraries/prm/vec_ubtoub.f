      SUBROUTINE VEC_UBTOUB( BAD, N, ARGV, RESV, IERR, NERR, STATUS )
*+
*  Name:
*     VEC_UBTOUB
 
*  Purpose:
*     Copy vectorised UNSIGNED BYTE values.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     CALL VEC_UBTOUB( BAD, N, ARGV, RESV, IERR, NERR, STATUS )
 
*  Description:
*     The routine copies a vectorised array of UNSIGNED BYTE values.  It forms
*     part of the set of type conversion routines, but in this instance
*     the argument and result types are both the same, so the argument
*     values are simply copied.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether the argument values (ARGV) may be "bad" (this argument
*        actually has no effect on the behaviour of the routine, but is
*        present to match the other type conversion routines).
*     N = INTEGER (Given)
*        The number of values to be copied.  If N is not positive the
*        routine returns with IERR and NERR set to zero, but without
*        copying any values.
*     ARGV(*) = BYTE (Given)
*        A vectorised (1-dimensional) array containing the N UNSIGNED BYTE
*        values to be copied.
*     RESV(*) = BYTE (Returned)
*        A vectoried (1-dimensional) array with at least N elements to
*        receive the UNSIGNED BYTE results.
*     IERR = INTEGER (Returned)
*        The index of the first input array element to generate a
*        numerical error.  It will always be set to zero by this
*        routine.
*     NERR = INTEGER (Returned)
*        The number of numerical errors which occurred.  It will always
*        be set to zero by this routine.
*     STATUS = INTEGER (Given)
*        This should be set to SAI__OK on entry, otherwise the routine
*        returns immediately without action.  This routine cannot
*        produce numerical errors, so the STATUS argument will not be
*        changed.
 
*  Authors:
*     R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     15-AUG-1988 (RFWS):
*        Original version.
*     28-OCT-1991 (RFWS):
*        Revoved VAX-specific call.
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
      LOGICAL BAD                ! Bad data flag
      INTEGER N                  ! Number of elements to process
      BYTE ARGV( * )           ! Array of input values
 
*  Arguments Returned:
      BYTE RESV( * )           ! Array of result values
      INTEGER IERR               ! Numerical error pointer
      INTEGER NERR               ! Numerical error count
 
*  Status:
      INTEGER STATUS             ! Error status
 
*  Local Variables:
      INTEGER I                  ! Loop counter
 
*.
 
*   Check status.
      IF( STATUS .NE. SAI__OK ) RETURN
 
*  Copy the values.
      DO I = 1, N
         RESV( I ) = ARGV( I )
      ENDDO
 
*   Set the numerical error pointer and the error count to zero.
      IERR = 0
      NERR = 0
 
*   Exit routine.
      END
