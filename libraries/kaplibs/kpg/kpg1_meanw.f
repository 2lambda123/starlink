      SUBROUTINE KPG1_MEANW( N, DATA, MEAN, STATUS )
*+
*  Name:
*     KPG1_MEANx
 
*  Purpose:
*     Finds the mean of the good data values in an array.
 
*  Description:
*     Finds the mean of the good data values in a 1-D array.

*  Language:
*     Starlink Fortran 77
 
*  Invocation
*     CALL KPG1_MEANx( N, DATA, MEAN, STATUS )
 
*  Arguments:
*     N = INTEGER (Given)
*        Number of elements in the array.
*     DATA( N ) = ? (Given)
*        The data array.
*     MEAN = ? (Returned)
*        The mean value.  Set to VAL__BADW if no good data are found.
*     STATUS = INTEGER (Given)
*        The global status.
 
*  Notes:
*     -  There is a routine for each of the standard numeric types.
*     Replace "x" in the routine name by D, R, I, W, UW, B or UB as
*     appropriate.    The array and mean arguments supplied to the
*     routine must have the data type specified.
*     -  The summation is carried out in double precision.
 
*  Authors:
*     DSB: D.S. Berry (STARLINK)
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     6-JAN-1995 (DSB):
*        Original version.
*     1995 March 30 (MJC):
*        Made generic from KPG1_MEANx.  Added prologue terminator.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! VAL__ constants
 
*  Arguments Given:
      INTEGER N
      INTEGER*2 DATA( N )
 
*  Arguments Returned:
      INTEGER*2 MEAN
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER I                  ! Loop count
      INTEGER NSUM               ! Number of good pixels found so far
      DOUBLE PRECISION SUM       ! Sum of good data values
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM_ type conversion declarations
      INCLUDE 'NUM_DEF_CVT'      ! NUM_ type conversion functions
 
*.
 
*  Check the global inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Initialise the running totals.
      SUM = 0.0D0
      NSUM = 0
 
*  Loop round the data array, summing all the good data values, and
*  keeping a count of the number of good values found.
      DO I = 1, N
 
         IF ( DATA( I ) .NE. VAL__BADW ) THEN
            SUM = SUM + NUM_WTOD( DATA( I ) )
            NSUM = NSUM + 1
         END IF
 
      END DO
 
*  If any good values were found, find the mean of them.  Otherwise,
*  return a bad value.
      IF ( NSUM .GT. 0 ) THEN
         MEAN = NUM_DTOW( SUM / DBLE( NSUM ) )
 
      ELSE
         MEAN = VAL__BADW
 
      END IF
 
      END
