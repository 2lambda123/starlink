      SUBROUTINE KPS1_GLIBD( LBND1, LBND2, UBND1, UBND2, DIN, IPPIX, 
     :                       NPOS, STATUS ) 
*+
*  Name:
*     KPS1_GLIBD

*  Purpose:
*     Get pixel positions to be de-glitched from the environment.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_GLIBD( LBND1, LBND2, UBND1, UBND2, DIN, IPPIX, NPOS, STATUS ) 

*  Description:
*     This routine returns an array holding the pixel co-ordinates at the
*     centre of all the bad pixels in the supplied array.

*  Arguments:
*     LBND1 = INTEGER (Given)
*        Lower pixel index on axis 1.
*     LBND2 = INTEGER (Given)
*        Lower pixel index on axis 2.
*     UBND1 = INTEGER (Given)
*        Upper pixel index on axis 1.
*     UBND2 = INTEGER (Given)
*        Upper pixel index on axis 2.
*     DIN( LBND1:UBND1, LBND2:UBND2 ) = DOUBLE PRECISION (Given)
*        The input data array.
*     IPPIX = INTEGER (Returned)
*        A pointer to a double precision array with dimensions (NPOS,2),
*        containing the pixel co-ordinates at the centre of every bad pixel.
*        This should be freed with PSX_FREE when no longer needed.
*     NPOS = INTEGER (Returned)
*        The number of returned positions. Returned equal to zero if
*        there are no bad pixels in the array,
*     STATUS = INTEGER (Given and Returned)
*        The inherited status.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     7-MAR-2000 (DSB):
*        Initial version.
*     2004 September 3 (TIMJ):
*        Use CNF_PVAL
*     {enter_further_changes_here}

*  Bugs:
*     {note_new_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE            ! no default typing allowed

*  Global Constants: 
      INCLUDE 'SAE_PAR'        ! Global SSE parameters 
      INCLUDE 'PRM_PAR'        ! VAL__ constants
      INCLUDE 'CNF_PAR'        ! For CNF_PVAL function

*  Arguments Given:
      INTEGER LBND1
      INTEGER LBND2
      INTEGER UBND1
      INTEGER UBND2
      DOUBLE PRECISION DIN( LBND1:UBND1, LBND2:UBND2 )

*  Arguments Returned:
      INTEGER IPPIX
      INTEGER NPOS

*  Global Status:
      INTEGER STATUS

*  Local Variables:
      INTEGER I,J      
*.

*  Check inherited global status.
      IF( STATUS .NE. SAI__OK ) RETURN

*  Count the number of bad pixels.
      NPOS = 0
      DO J = LBND2, UBND2
         DO I = LBND1, UBND1
            IF( DIN( I, J ) .EQ. VAL__BADD ) NPOS = NPOS + 1
         END DO
      END DO

*  If there are no bad pixels, return a pointer value of zero.
      IF( NPOS .EQ. 0 ) THEN
         IPPIX = 0

*  Otherwise, allocate the memory.
      ELSE
         CALL PSX_CALLOC( NPOS*2, '_DOUBLE', IPPIX, STATUS )
         IF( STATUS .EQ. SAI__OK ) THEN

*  Store the pixel positions in the memory.
            CALL KPS1_GLIDD( LBND1, LBND2, UBND1, UBND2, DIN, 
     :                       NPOS, %VAL( CNF_PVAL( IPPIX ) ), STATUS )

         END IF

      END IF

      END
