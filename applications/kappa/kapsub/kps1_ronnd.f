      SUBROUTINE KPS1_RONND( IDIM1, IDIM2, INARR, ANGLE, ODIM1, ODIM2,
     :                         OUTARR, STATUS )
*+
*  Name:
*     KPS1_RONNx

*  Purpose:
*     Rotates an image through an arbitrary angle using the
*     nearest-neighbour method.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_RONNx( IDIM1, IDIM2, INARR, ANGLE, ODIM1, ODIM2, OUTARR,
*                      STATUS )

*  Description:
*     This routine takes an input 2-dimensional array and rotates it
*     clockwise by an arbitrary angle into the output array.  It uses
*     the nearest-neighbour method to derive output values.  The value
*     of the pixel in the input array which is nearest to the
*     calculated pre-transform position becomes the value assigned to
*     output pixel.  This prevents gaps forming in the output array due
*     to real-to-integer truncation when transforming old to new
*     pixels.  This may lead to the occasional instance where two
*     adjacent pixels in the new array are calculated to have come from
*     the same pixel in the old array.  This implies some slight
*     degradation of resolution.

*  Arguments:
*     IDIM1 = INTEGER (Given)
*        The first dimension of the input 2-dimensional array.
*     IDIM2 = INTEGER (Given)
*        The second dimension of the input 2-dimensional array.
*     INARR( IDIM1, IDIM2 ) = ? (Given)
*        The input array to rotate.
*     ANGLE = REAL  (Given)
*        The rotation angle in degrees.
*     ODIM1 = INTEGER (Given)
*        The first dimension of the output 2-dimensional array.
*     ODIM2 = INTEGER (Given)
*        The second dimension of the output 2-dimensional array.
*     OUTARR( ODIM1, ODIM2 ) = ? (Returned)
*        The rotated array.
*     STATUS = INTEGER (Given and Returned)
*        Global status parameter.

*  Notes:
*     -  There is a routine for each numeric data type: replace "x" in
*     the routine name by D, R, I, W, UW, B or UB as appropriate.  The
*     INARR and OUTARR arguments must have the data type specified.

*  Algorithm:
*     If status not o.k. - return
*     Set up co-ordinates of the two array centres
*     Compute sine and cosine of the angle of rotation
*     For all lines in output array
*        Compute y distance of current line from output array centre
*        For all pixels in current line in output array
*           Compute x distance of current line from output array centre
*           Get the co-ordinates in the input array from which the
*             current output-array co-ordinates have been transformed
*           If this point exists in the input array then
*              Set output array pixel to that value
*           Else
*              Output array pixel is invalid
*           Endif
*        Endfor
*     Endfor
*     Return

*  Copyright:
*     Copyright (C) 1985-1986, 1988-1989 Science & Engineering Research
*     Council. Copyright (C) 1995 Central Laboratory of the Research
*     Councils. All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     MJM: Mark McCaughrean (UoE)
*     MJC: Malcolm Currie (Starlink)
*     {enter_new_authors_here}

*  History:
*     14-11-1985 (MJM):
*        First implementation for ROTATE.
*     1986 September 9 (MJC):
*        Completed the prologue, reordered arguments (3rd to 5th),
*        added bad-pixel handling and nearly conformed to Starlink
*        standards.
*     1988 June 24 (MJC):
*        Added bilinear-interpolation option and therefore extra
*        argument NNMETH.
*     1989 August 7 (MJC):
*        Passed array dimensions as separate variables.
*     1995 May 17 (MJC):
*        Split the nearest neighbour and biliear interpolation into two
*        generic routines from ROTNRS.  Used a new-style prologue and
*        modern variable declarations.  Evaluate the transformation
*        inline for greater efficiency.
*     {enter_further_changes_here}

*-

*  Type Definitions:
      IMPLICIT  NONE             ! no implicit typing allowed

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! SSE global definitions
      INCLUDE 'PRM_PAR'          ! PRIMDAT public constants

*  Arguments Given:
      INTEGER IDIM1
      INTEGER IDIM2
      DOUBLE PRECISION INARR( IDIM1, IDIM2 )
      REAL ANGLE
      INTEGER ODIM1
      INTEGER ODIM2

*  Arguments Returned:
      DOUBLE PRECISION OUTARR( ODIM1, ODIM2 )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      REAL DGTORD                ! Degrees to radians
      PARAMETER ( DGTORD = 0.01745329 )

*  Local Variables:
      REAL CANGLE                ! Cosine of the rotation angle
      INTEGER I                  ! Array counter
      REAL ICX                   ! X co-ordinate of input array centre
      REAL ICY                   ! Y co-ordinate of input array centre
      INTEGER IIP                ! X pixel in input array corresponding
                                 ! to the current output array pixel
      INTEGER IJP                ! Y pixel in input array corresponding
                                 ! to the current output array pixel
      INTEGER J                  ! Array counter
      REAL OCX                   ! X co-ordinate of input array centre
      REAL OCY                   ! Y co-ordinate of input array centre
      REAL RI                    ! Y distance of current output
                                 ! array pixel from output array centre
      REAL RJ                    ! Y distance of current output
                                 ! array pixel from output array centre
      REAL RIP                   ! X distance of corresponding input
                                 ! array point from input array centre
      REAL RJP                   ! Y distance of corresponding input
                                 ! array point from input array centre
      REAL SANGLE                ! Sine of the rotation angle

*.

*  Check the global inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Set up the real co-ordinates of the two array centres.
      ICX = REAL( IDIM1 ) / 2.0
      ICY = REAL( IDIM2 ) / 2.0
      OCX = REAL( ODIM1 ) / 2.0
      OCY = REAL( ODIM2 ) / 2.0

*  Set up the sine and cosine of the rotation angle.
      CANGLE = COS( DGTORD * ANGLE )
      SANGLE = SIN( DGTORD * ANGLE )

*  Loop round each line in the output array.
      DO J = 1, ODIM2

*  Set up real y distance of the current line from the output-array
*  centre.
         RJ = REAL( J ) - 0.5 - OCY

*  Loop round each pixel in the current line.
         DO I = 1, ODIM1

*  Set up real x distance of current point from output array centre.
            RI = REAL( I ) - 0.5 - OCX

*  Get the real co-ordinates in the input array from which the current
*  output array co-ordinates have been transformed.  Do this by
*  evaluating the pre-rotation distances RIP, RJP from the
*  post-rotation distances RI, RJ and the clockwise rotation ANGLE
*  using a matrix transform.
            RIP = ( RI * CANGLE )  - ( RJ * SANGLE )
            RJP = ( RI * SANGLE )  + ( RJ * CANGLE )

*  Convert these real distances into integer pixel indices, e.g.
*  (56,45); add the input array centre co-ordinate first, then another
*  0.5, and then take the nearest integer.
            IIP = NINT( RIP + ICX + 0.5 )
            IJP = NINT( RJP + ICY + 0.5 )

*  Now determine if this calculated point exists in the input array.
*  If so, set output-array pixel to that value; if not, set
*  output-array pixel invalid.
            IF ( IIP .GE. 1 .AND. IIP .LE. IDIM1 .AND.
     :           IJP .GE. 1 .AND. IJP .LE. IDIM2 ) THEN
               OUTARR( I, J ) = INARR( IIP, IJP )

            ELSE
               OUTARR( I, J ) = VAL__BADD

            END IF

*  End of loops for all columns and lines of output array
         END DO
      END DO

      END
