      SUBROUTINE ARD1_EQV( NDIM, LBND, UBND, MSKSIZ, A, LBEXTA,
     :                     UBEXTA, LBINTA, UBINTA, B, LBEXTB, UBEXTB,
     :                     LBINTB, UBINTB, STATUS )
*+
*  Name:
*     ARD1_EQV

*  Purpose:
*     Perform an EQV operation on two arrays

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL ARD1_EQV( NDIM, LBND, UBND, MSKSIZ, A, LBEXTA,
*                    UBEXTA, LBINTA, UBINTA, B, LBEXTB, UBEXTB,
*                    LBINTB, UBINTB, STATUS )

*  Description:
*     The supplied interior and exterior bounding boxes of the two
*     arrays are combined to produce a bounding box for the area in
*     which the result of the .EQV. operation may differ from the
*     supplied contents of the B array. The operation is then performed
*     between the two supplied arrays within this box, and the results
*     are returned in B (over-writing the supplied values). All B
*     values outside the box are left unaltered. The exterior and
*     interior bounding boxes of the resulting array are calculated and
*     over-write the boxes supplied for array B.

*  Arguments:
*     NDIM = INTEGER (Given)
*        The number of dimensions in each array.
*     LBND( NDIM ) = INTEGER (Given)
*        The lower pixel index bounds of each array.
*     UBND( NDIM ) = INTEGER (Given)
*        The upper pixel index bounds of each array.
*     MSKSIZ = INTEGER (Given)
*        The total number of elements in each array.
*     A( MSKSIZ ) = INTEGER (Given)
*        The first operand array (in vector form). This should hold zero
*        for all exterior points, and a positive value for all interior
*        points.
*     LBEXTA( NDIM ) = INTEGER (Given)
*        The lower pixel bounds of the smallest box which contains all
*        exterior points in A. A value of VAL__MAXI for element 1 is
*        used to indicate an infinite box, and a value of VAL__MINI for
*        element 1 is used to indicate a zero sized box.
*     UBEXTA( NDIM ) = INTEGER (Given)
*        The upper pixel bounds of the smallest box which contains all
*        exterior points in A. 
*     LBINTA( NDIM ) = INTEGER (Given)
*        The lower pixel bounds of the smallest box which contains all
*        interior points in A. A value of VAL__MAXI for element 1 is
*        used to indicate an infinite box, and a value of VAL__MINI for
*        element 1 is used to indicate a zero sized box.
*     UBINTA( NDIM ) = INTEGER (Given)
*        The upper pixel bounds of the smallest box which contains all
*        interior points in A. 
*     B( MSKSIZ ) = INTEGER (Given and Returned)
*        The second operand array (in vector form). This should hold
*        zero for all exterior points, and a positive value for all
*        interior points. The results of the operation are written back
*        into this array.
*     LBEXTB( NDIM ) = INTEGER (Given and Returned)
*        The lower pixel bounds of the smallest box which contains all
*        exterior points in B. A value of VAL__MAXI for element 1 is
*        used to indicate an infinite box, and a value of VAL__MINI for
*        element 1 is used to indicate a zero sized box.
*     UBEXTB( NDIM ) = INTEGER (Given and Returned)
*        The upper pixel bounds of the smallest box which contains all
*        exterior points in B. 
*     LBINTB( NDIM ) = INTEGER (Given and Returned)
*        The lower pixel bounds of the smallest box which contains all
*        interior points in B. A value of VAL__MAXI for element 1 is
*        used to indicate an infinite box, and a value of VAL__MINI for
*        element 1 is used to indicate a zero sized box.
*     UBINTB( NDIM ) = INTEGER (Given and Returned)
*        The upper pixel bounds of the smallest box which contains all
*        interior points in B. 
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     28-FEB-1994 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'ARD_CONST'        ! ARD_ private constants

*  Arguments Given:
      INTEGER NDIM
      INTEGER LBND( NDIM )
      INTEGER UBND( NDIM )
      INTEGER MSKSIZ
      INTEGER A( MSKSIZ )
      INTEGER LBEXTA( NDIM )
      INTEGER UBEXTA( NDIM )
      INTEGER LBINTA( NDIM )
      INTEGER UBINTA( NDIM )

*  Arguments Given and Returned:
      INTEGER B( MSKSIZ )
      INTEGER LBEXTB( NDIM )
      INTEGER UBEXTB( NDIM )
      INTEGER LBINTB( NDIM )
      INTEGER UBINTB( NDIM )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER
     :        I,                 ! Loop count
     :        LB1( ARD__MXDIM),  ! Temporary box lower bounds
     :        LB2( ARD__MXDIM),  ! Temporary box lower bounds
     :        LB3( ARD__MXDIM),  ! Temporary box lower bounds
     :        UB1( ARD__MXDIM),  ! Temporary box upper bounds
     :        UB2( ARD__MXDIM),  ! Temporary box upper bounds
     :        UB3( ARD__MXDIM)   ! Temporary box upper bounds

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  The values stored in B may change for any point within the interior
*  bounding box of B. They may also change within the intersection of
*  the exterior bounding boxes of A and B. Find the bounds of a box
*  which encompass all points which may change.
      CALL ARD1_ANDBX( NDIM, LBEXTA, UBEXTA, LBEXTB, UBEXTB, LB2, UB2,
     :                 STATUS )
      CALL ARD1_ORBX( NDIM, LBINTB, UBINTB, LB2, UB2, LB3, UB3, STATUS )

*  Process the input data within this box.
      CALL ARD1_BXEQV( NDIM, LBND, UBND, MSKSIZ, A, LB3, UB3,
     :                 B, STATUS )

*  Now find the interior bounding box of the results. This is the union
*  of two regions; the first being the intersection of the interior
*  bounding box of A and the interior bounding box of B; and the second
*  being the intersection of the exterior bounding box of A and the
*  exterior bounding box of B. The results are stored in local arrays
*  (LB3 and UB3) to avoid changing the values in LBINTB and UBINTB
*  since these are used later to find the exterior bounding box of the
*  results.
      CALL ARD1_ANDBX( NDIM, LBINTA, UBINTA, LBINTB, UBINTB, LB1, UB1,
     :                 STATUS )
      CALL ARD1_ORBX( NDIM, LB1, UB1, LB2, UB2, LB3, UB3, STATUS )

*  Now find the exterior bounding box of the results. This is the union
*  of two regions; the first being the intersection of the interior
*  bounding box of A and the exterior bounding box of B; and the second
*  being the intersection of the exterior bounding box of A and the
*  interior bounding box of B. The results are returned to the calling
*  routine in LBEXTB abd UBEXTB.
      CALL ARD1_ANDBX( NDIM, LBINTA, UBINTA, LBEXTB, UBEXTB, LB1, UB1,
     :                 STATUS )
      CALL ARD1_ANDBX( NDIM, LBEXTA, UBEXTA, LBINTB, UBINTB, LB2, UB2,
     :                 STATUS )
      CALL ARD1_ORBX( NDIM, LB1, UB1, LB2, UB2, LBEXTB, UBEXTB, STATUS )

*  Now return the interior bounding box in LBINTB and UBINTB.
      DO I = 1, NDIM
         LBINTB( I ) = LB3( I )
         UBINTB( I ) = UB3( I )
      END DO         

      END
