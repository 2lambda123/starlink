      SUBROUTINE KPG1_VASVW( OEL, INDICE, IEL, INARR, OUTARR, NBAD,
     :                         STATUS )
*+
*  Name:
*     KPG1_VASVx
 
*  Purpose:
*     Assigns values to an output array from an input array using a list
*     of indices.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPG1_VASVx( OEL, INDICE, IEL, INARR, OUTARR, NBAD, STATUS )
 
*  Description:
*     This routine assigns values to an output vector from an input
*     vector.  The values are selected using a list of indices
*     in the input vector, there being one index per output value.
*     A bad value or a value outside the bounds of the array in the
*     list of indices causes a bad value to be assigned to the output
*     array.
 
*  Arguments:
*     OEL = INTEGER (Given)
*        The dimension of the output vector and also the list of
*        indices.
*     INDICE( OEL ) = INTEGER (Given)
*        The indices in the input array that point to the values to be
*        assigned to the output vector.
*     IEL = INTEGER (Given)
*        The dimension of the input vector.
*     INARR( IEL ) = ? (Given)
*        The vector containing values to be given to the output vector.
*     OUTARR( OEL ) = ? (Returned)
*        The vector containing values copied from the input vector
*        according to the list of indices.
*     NBAD = INTEGER (Returned)
*        The number of bad values in the output array.
*     STATUS = INTEGER (Given)
*        The global status.
 
*  Notes:
*     -  There is a routine for each numeric data type: replace "x" in
*     the routine name by D, R, I, W, UW, B or UB as appropriate. The
*     input and output vectors supplied to the routine must have the
*     data type specified.
 
*  [optional_subroutine_items]...
*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1993 March 5 (MJC):
*        Original version.
*     {enter_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT public constants
 
*  Arguments Given:
      INTEGER OEL
      INTEGER IEL
      INTEGER INDICE( OEL )
      INTEGER*2 INARR( IEL )
 
*  Arguments Returned:
      INTEGER*2 OUTARR( OEL )
      INTEGER NBAD
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER I                  ! Loop counter
 
*.
 
*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Initialise the bad-value counter.
      NBAD = 0
 
*  Loop around all output elements.
      DO I = 1, MAX( OEL, 1 )
 
*  Check that the index is valid.  Count the number of bad values.
         IF ( INDICE( I ) .EQ. VAL__BADI .OR. INDICE( I ) .LT. 1 .OR.
     :        INDICE( I ) .GT. IEL ) THEN
            OUTARR( I ) = VAL__BADW
            NBAD = NBAD + 1
 
*  Use the index to assign an output value.
         ELSE
            OUTARR( I ) = INARR( INDICE( I ) )
         END IF
      END DO
 
      END
