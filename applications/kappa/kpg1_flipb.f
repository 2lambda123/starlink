      SUBROUTINE KPG1_FLIPB( NDIM, DIM, DATIN, IDIM, DATOUT, STATUS )
*+
*  Name:
*     KPG1_FLIPx
 
*  Purpose:
*     Reverse the pixels in an N-dimensional array along a specified
*     dimension.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPG1_FLIPx( NDIM, DIM, DATIN, IDIM, DATOUT, STATUS )
 
*  Description:
*     This routine reverses the order of the pixels in an N-dimensional
*     array along a specified dimension. The pixel values are
*     unchanged. The array may have any number of dimensions.
 
*  Arguments:
*     NDIM = INTEGER (Given)
*        Number of array dimensions.
*     DIM( NDIM ) = INTEGER (Given)
*        Array of dimension sizes for each array dimension.
*     DATIN( * ) = ? (Given)
*        The input NDIM-dimensional array.
*     IDIM = INTEGER (Given)
*        Number of the array dimension along which the pixel values are
*        to be reversed (in the range 1 to NDIM).
*     DATOUT( * ) = ? (Returned)
*        Output array, with the pixels reversed.
*     STATUS = INTEGER (Given and Returned)
*        The global status.
 
*  Notes:
*     -  There is a routine for each standard numeric type; replace "x"
*     in the array name by D, R, I, W, UW, B or UB as appropriate. The
*     data type of the arrays supplied must match the particular
*     routine used.
 
*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     {enter_new_authors_here}
 
*  History:
*     13-MAR-1991 (RFWS):
*        Original version.
*     {enter_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
 
*  Arguments Given:
      INTEGER NDIM
      INTEGER DIM( NDIM )
      BYTE DATIN( * )
      INTEGER IDIM
 
*  Arguments Returned:
      BYTE DATOUT( * )
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER I                  ! Index of input pixel
      INTEGER ID                 ! Loop counter for dimension IDIM
      INTEGER IL                 ! Loop counter for lower dimensions
      INTEGER IU                 ! Loop counter for upper dimensions
      INTEGER NL                 ! Product of lower dimension sizes
      INTEGER NU                 ! Product of upper dimension sizes
      INTEGER SHIFT              ! Vectorised pixel index shift
 
*.
 
*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Find the product of the dimension sizes of all the dimensions below
*  the one being reversed and of all those above the one being
*  reversed.
      NL = 1
      NU = 1
      DO 1 I = 1, NDIM
         IF ( I .LT. IDIM ) THEN
            NL = NL * DIM( I )
         ELSE IF ( I .GT. IDIM ) THEN
            NU = NU * DIM( I )
         END IF
 1    CONTINUE
 
*  Loop through all the dimensions above the one being reversed.
      I = 0
      DO 5 IU = 1, NU
 
*  Initiallise the vectorised array index shift which each pixel must
*  undergo to place it in the correct (reversed) position in the output
*  array.
         SHIFT = ( DIM( IDIM ) + 1 ) * NL
 
*  If the product of the lower dimension sizes is greater than 1, then
*  loop through the dimension being reversed, updating the shift.
         IF ( NL .GT. 1 ) THEN
            DO 3 ID = 1, DIM( IDIM )
               SHIFT = SHIFT - ( 2 * NL )
 
*  Loop through the lower dimensions and increment the input pixel
*  index. Transfer each pixel from the input array to the appropriate
*  position in the output array.
               DO 2 IL = 1, NL
                  I = I + 1
                  DATOUT( I + SHIFT ) = DATIN( I )
 2             CONTINUE
 3          CONTINUE
 
*  If the product of the lower dimension sizes is 1, then a short cut
*  can be taken to avoid executing the inner DO loop above for every
*  pixel. Step through dimension IDIM and all lower dimensions in one
*  loop, updating the pixel shift and transferring the input pixels to
*  the appropriate position in the output array.
         ELSE
            DO 4 ID = 1, DIM( IDIM )
               I = I + 1
               SHIFT = SHIFT - 2
               DATOUT( I + SHIFT ) = DATIN( I )
 4          CONTINUE
         END IF
 5    CONTINUE
 
      END
