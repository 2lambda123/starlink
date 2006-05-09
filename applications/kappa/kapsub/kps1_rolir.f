      SUBROUTINE KPS1_ROLIR( IDIM1, IDIM2, INARR, VAR, INVAR, ANGLE,
     :                         ODIM1, ODIM2, OUTARR, OUTVAR, STATUS )
*+
*  Name:
*     KPS1_ROLIx

*  Purpose:
*     Rotates an image through an arbitrary angle using bilinear
*     interpolation.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_ROLIx( IDIM1, IDIM2, INARR, VAR, INVAR, ANGLE, ODIM1,
*                      ODIM2, OUTARR, OUTVAR, STATUS )

*  Description:
*     This routine takes an input 2-dimensional array and rotates it
*     clockwise by an arbitrary angle into the output array.  The
*     output pixel value is obtained via bilinear interpolation of the
*     four input pixels surrounding the transformed co-ordinate.  This
*     is slower than the nearest-neighbour mnmethod but produces a
*     more-accurate result.  Allowance is made for invalid pixels,
*     which are excluded from the calculations.  If the nearest input
*     pixel or all four surrounding input pixels are invalid, the
*     output pixel is made invalid.
*
*     Variance information may be used to weight the pixels in the
*     interpolation.

*  Arguments:
*     IDIM1 = INTEGER (Given)
*        The first dimension of the input 2-dimensional array.
*     IDIM2 = INTEGER (Given)
*        The second dimension of the input 2-dimensional array.
*     INARR( IDIM1, IDIM2 ) = ? (Given)
*        The input array to rotate.
*     VAR = LOGICAL (Given)
*        Whether or not to use variance information to weight the
*        interpolations, and hence to create a rotated variance array.
*     INVAR( IDIM1, IDIM2 ) = ? (Given)
*        The input variance array to rotate and use in the weighting
*        if VAR is .TRUE..
*     ANGLE = REAL  (Given)
*        The rotation angle in degrees.
*     ODIM1 = INTEGER (Given)
*        The first dimension of the output 2-dimensional array.
*     ODIM2 = INTEGER (Given)
*        The second dimension of the output 2-dimensional array.
*     OUTARR( ODIM1, ODIM2 ) = ? (Returned)
*        The rotated array.
*     OUTVAR( IDIM1, IDIM2 ) = ? (Given)
*        The rotated variance array if VAR is .TRUE..
*     STATUS = INTEGER (Given and Returned)
*        Global status parameter.

*  Notes:
*     -  There is a routine for double-precision and single-precision
*     floating-point data types: replace "x" in the routine name by D
*     or R as appropriate.  The INARR, INVAR, OUTARR, and OUTVAR
*     arguments must have the data type specified.

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
*           Compute nearest-neighbour (integer) pixel co-ordinates in
*             the input array
*           If this point does not exist in the input array then
*              Output array pixel is invalid
*           Else
*              Store the four surrounding pixels
*              If the nearest-neighbour pixel is invalid or all four
*                surrounding pixels are invalid then
*                 Output array pixel is invalid
*              Else
*                 Compute the fractional-pixel displacements of the
*                   interpolation point
*                 Initialise summation variables
*                 For each valid surrounding pixel
*                    Find the bilinear weighting factor
*                    Increment the sum of the weighted pixel values
*                      and the sum of weights
*                    Output array pixel value is the weighted mean
*                 Endfor
*              Endif
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
      REAL INARR( IDIM1, IDIM2 )
      LOGICAL VAR
      REAL INVAR( IDIM1, IDIM2 )
      REAL ANGLE
      INTEGER ODIM1
      INTEGER ODIM2
 
*  Arguments Returned:
      REAL OUTARR( ODIM1, ODIM2 )
      REAL OUTVAR( ODIM1, ODIM2 )
 
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
      INTEGER IIP                ! X pixel index of lower-left neighbour
                                 ! in input array enclosing
                                 ! corresponding output-array pixel
      INTEGER IJP                ! Y pixel index of lower-left neighbour
                                 ! in input array enclosing
                                 ! corresponding output-array pixel
      INTEGER J                  ! Array counters
      REAL OCX                   ! X co-ordinate of input array centre
      REAL OCY                   ! X co-ordinate of input array centre
      REAL RI                    ! Real x distance of current output
                                 ! array pixel from output array centre
      REAL RJ                    ! Real y distance of current output
                                 ! array pixel from output array centre
      REAL RIP                   ! Real x distance of corresponding input
                                 ! array point from input array centre
      REAL RJP                   ! Real y distance of corresponding input
                                 ! array point from input array centre
      REAL SANGLE                ! Sine of the rotation angle
      REAL SUM                ! Sum of weighted surrounding pixels
      REAL VAL1               ! Bottom-left value surrounding
                                 ! the point to be interpolated
      REAL VAL2               ! Bottom-right value
      REAL VAL3               ! Top-left value
      REAL VAL4               ! Top-right value
      REAL VAR1               ! Bottom-left variance surrounding
                                 ! the point to be interpolated
      REAL VAR2               ! Bottom-right variance
      REAL VAR3               ! Top-left variance
      REAL VAR4               ! Top-right variance
      REAL WEIGHT             ! Weight of a pixel for interpolation
      REAL WTSUM              ! Sum of weights
      REAL XDIST                 ! Fractional pixel displacement of
                                 ! the interpolation point
      REAL XO                    ! x co-ordinate in input array
                                 ! corresponding to the current output
                                 ! array pixel
      REAL YDIST                 ! Fractional pixel displacement of
                                 ! the interpolation point
      REAL YO                    ! y co-ordinate in input array
                                 ! corresponding to the current output
                                 ! array pixel
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'      ! NUM definitions for conversions
 
*.
 
*  Check the global inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Set up the real co-ordinates of the two array centres
      ICX = REAL( IDIM1 ) / 2.0
      ICY = REAL( IDIM2 ) / 2.0
      OCX = REAL( ODIM1 ) / 2.0
      OCY = REAL( ODIM2 ) / 2.0
 
*  Set up the sine and cosine of the rotation angle.
      CANGLE = COS( DGTORD * ANGLE )
      SANGLE = SIN( DGTORD * ANGLE )
 
*  Test for variance processing.
      IF ( VAR ) THEN
 
*  Loop round each line in the output array.
         DO J = 1, ODIM2
 
*  Set up the real y distance of the current line from the output-array
*  centre.
            RJ = REAL( J ) - 0.5 - OCY
 
*  Loop round each pixel in the current line.
            DO I = 1, ODIM1
 
*  Set up a real x distance of the current point from the output-array
*  centre.
               RI = REAL( I ) - 0.5 - OCX
 
*  Get the real co-ordinates in the input array from which the current
*  output array co-ordinates have been transformed.  Do this by
*  evaluating the pre-rotation distances RIP, RJP from the
*  post-rotation distances RI, RJ and the clockwise rotation ANGLE
*  using a matrix transform.
               RIP = ( RI * CANGLE )  - ( RJ * SANGLE )
               RJP = ( RI * SANGLE )  + ( RJ * CANGLE )
 
*  Convert these distances into pixel indices.
               XO = RIP + ICX + 0.5
               YO = RJP + ICY + 0.5
 
*  Find the indices of the lower-left of the four pixels surrounding the
*  transformed point in the input array.
               IIP = INT( XO )
               IJP = INT( YO )
 
*  Now determine if this calculated point exists in the input array; if
*  not, set the output-array pixel and variance to be invalid.
               IF ( IIP .LT. 1 .OR. IIP .GE. IDIM1 .OR.
     :              IJP .LT. 1 .OR. IJP .GE. IDIM2 ) THEN
                  OUTARR( I, J ) = VAL__BADR
                  OUTVAR( I, J ) = VAL__BADR
 
*  Interpolate to obtain the output pixel value.
               ELSE
 
*  Get the four surrounding pixels in the data array.
                  VAL1 = INARR( IIP, IJP )
                  VAL2 = INARR( IIP + 1, IJP )
                  VAL3 = INARR( IIP, IJP + 1 )
                  VAL4 = INARR( IIP + 1, IJP + 1 )
 
*  Get the four surrounding pixels in the variance array.
                  VAR1 = INVAR( IIP, IJP )
                  VAR2 = INVAR( IIP + 1, IJP )
                  VAR3 = INVAR( IIP, IJP + 1 )
                  VAR4 = INVAR( IIP + 1, IJP + 1 )
 
*  The output pixel is made invalid if nearest input pixel is invalid,
*  or all four surrounding pixels or their variances are invalid.
                  IF ( INARR( IIP, IJP ) .EQ. VAL__BADR .OR.
     :                 ( ( VAL1 .EQ. VAL__BADR .OR.
     :                     VAR1 .EQ. VAL__BADR ) .AND.
     :                   ( VAL2 .EQ. VAL__BADR .OR.
     :                     VAR2 .EQ. VAL__BADR ) .AND.
     :                   ( VAL3 .EQ. VAL__BADR .OR.
     :                     VAR3 .EQ. VAL__BADR ) .AND.
     :                   ( VAL4 .EQ. VAL__BADR .OR.
     :                     VAR4 .EQ. VAL__BADR ) )  ) THEN
 
                     OUTARR( I, J ) = VAL__BADR
                     OUTVAR( I, J ) = VAL__BADR
 
*  Otherwise continue with the interpolation.
                  ELSE
 
*  Evaluate the fractional-pixel displacements of the interpolation
*  point.
                     XDIST = NUM_RTOR( XO - REAL( IIP ) )
                     YDIST = NUM_RTOR( YO - REAL( IJP ) )
 
*  Initialise sums for forming the weighted mean.
                     SUM = 0.0E0
                     WTSUM = 0.0E0
 
*  Form the weighted mean of adjacent four pixels, checking that each
*  lies within the input image and is not invalid.
                     IF ( VAL1 .NE. VAL__BADR .AND.
     :                    VAR1 .NE. VAL__BADR ) THEN
 
*  Weight is calculated from the x-y shift from integer pixel
*  locations.  Bilinear interpolation is used.  First the bottom-left
*  pixel...
                        WEIGHT = ( 1.0E0 - XDIST ) *
     :                           ( 1.0E0 - YDIST ) / VAR1
                        SUM = SUM + VAL1 * WEIGHT
                        WTSUM = WTSUM + WEIGHT
                     END IF
 
*  bottom right...
                     IF ( VAL2 .NE. VAL__BADR ) THEN
                        WEIGHT = XDIST * ( 1.0E0 - YDIST ) / VAR2
                        SUM = SUM + VAL2 * WEIGHT
                        WTSUM = WTSUM + WEIGHT
                     END IF
 
*  top left...
                     IF ( VAL3 .NE. VAL__BADR ) THEN
                        WEIGHT = ( 1.0E0 - XDIST ) * YDIST / VAR3
                        SUM = SUM + VAL3 * WEIGHT
                        WTSUM = WTSUM + WEIGHT
                     END IF
 
*  top right...
                     IF ( VAL4 .NE. VAL__BADR ) THEN
                        WEIGHT = XDIST * YDIST / VAR4
                        SUM = SUM + VAL4 * WEIGHT
                        WTSUM = WTSUM + WEIGHT
                     END IF
 
*  Assign the weighted mean to the output pixel (WTSUM cannot
*  be zero, since at least 1 input pixel must be valid).  Assign the
*  inverse weight to the output variance.
                     OUTARR( I, J ) = SUM / WTSUM
                     OUTVAR( I, J ) = 1.0E0 / WTSUM
 
*  End of are-input-data-invalid check.
                  END IF
 
*  End of transformed-output-pixel-is-not-in-input-array check.
               END IF
 
*  End of loops for all columns and lines of the output array.
            END DO
         END DO
 
*  No variance weighting.
      ELSE
 
*  Loop round each line in the output array.
         DO J = 1, ODIM2
 
*  Set up the real y distance of the current line from the output-array
*  centre.
            RJ = REAL( J ) - 0.5 - OCY
 
*  Loop round each pixel in the current line.
            DO I = 1, ODIM1
 
*  Set up a real x distance of the current point from the output-array
*  centre.
               RI = REAL( I ) - 0.5 - OCX
 
*  Get the real co-ordinates in the input array from which the current
*  output array co-ordinates have been transformed.  Do this by
*  evaluating the pre-rotation distances RIP, RJP from the
*  post-rotation distances RI, RJ and the clockwise rotation ANGLE
*  using a matrix transform.
               RIP = ( RI * CANGLE )  - ( RJ * SANGLE )
               RJP = ( RI * SANGLE )  + ( RJ * CANGLE )
 
*  Convert these distances into pixel indices.
               XO = RIP + ICX + 0.5
               YO = RJP + ICY + 0.5
 
*  Find the indices of the lower-left of the four pixels surrounding the
*  transformed point in the input array.
               IIP = INT( XO )
               IJP = INT( YO )
 
*  Now determine if this calculated point exists in the input array; if
*  not, set the output-array pixel to be invalid.
               IF ( IIP .LT. 1 .OR. IIP .GE. IDIM1 .OR.
     :              IJP .LT. 1 .OR. IJP .GE. IDIM2 ) THEN
                  OUTARR( I, J ) = VAL__BADR
 
*  Interpolate to obtain the output pixel value.
               ELSE
 
*  Get the four surrounding points in the data array.
                  VAL1 = INARR( IIP, IJP )
                  VAL2 = INARR( IIP + 1, IJP )
                  VAL3 = INARR( IIP, IJP + 1 )
                  VAL4 = INARR( IIP + 1, IJP + 1 )
 
*  The output pixel is made invalid if nearest input pixel is invalid,
*  or all four surrounding pixels are invalid.
                  IF ( INARR( IIP, IJP ) .EQ. VAL__BADR .OR.
     :                 (  VAL1 .EQ. VAL__BADR .AND.
     :                    VAL2 .EQ. VAL__BADR .AND.
     :                    VAL3 .EQ. VAL__BADR .AND.
     :                    VAL4 .EQ. VAL__BADR )  ) THEN
 
                     OUTARR( I, J ) = VAL__BADR
 
*  Otherwise continue with the interpolation.
                  ELSE
 
*  Evaluate the fractional-pixel displacements of the interpolation
*  point.
                     XDIST = NUM_RTOR( XO - REAL( IIP ) )
                     YDIST = NUM_RTOR( YO - REAL( IJP ) )
 
*  Initialise sums for forming the weighted mean.
 
                     SUM = 0.0E0
                     WTSUM = 0.0E0
 
*  Form the weighted mean of adjacent four pixels, checking that each
*  lies within the input image and is not invalid.
                     IF ( VAL1 .NE. VAL__BADR ) THEN
 
*  Weight is calculated from the x-y shift from integer pixel
*  locations.  Bilinear interpolation is used.  First the bottom-left
*  pixel...
                        WEIGHT = ( 1.0E0 - XDIST ) *
     :                           ( 1.0E0 - YDIST )
                        SUM = SUM + VAL1 * WEIGHT
                        WTSUM = WTSUM + WEIGHT
                     END IF
 
*  bottom right...
                     IF ( VAL2 .NE. VAL__BADR ) THEN
                        WEIGHT = XDIST * ( 1.0E0 - YDIST )
                        SUM = SUM + VAL2 * WEIGHT
                        WTSUM = WTSUM + WEIGHT
                     END IF
 
*  top left...
                     IF ( VAL3 .NE. VAL__BADR ) THEN
                        WEIGHT = ( 1.0E0 - XDIST ) * YDIST
                        SUM = SUM + VAL3 * WEIGHT
                        WTSUM = WTSUM + WEIGHT
                     END IF
 
*  top right...
                     IF ( VAL4 .NE. VAL__BADR ) THEN
                        WEIGHT = XDIST * YDIST
                        SUM = SUM + VAL4 * WEIGHT
                        WTSUM = WTSUM + WEIGHT
                     END IF
 
*  Assign the weighted mean to the output pixel (WTSUM cannot
*  be zero, since at least 1 input pixel must be valid).
                     OUTARR( I, J ) = SUM / WTSUM
 
*  End of are-input-data-invalid check.
                  END IF
 
*  End of transformed-output-pixel-is-not-in-input-array check.
               END IF
 
*  End of loops for all columns and lines of the output array.
            END DO
         END DO
 
*  End of variance-processing check.
      END IF
 
      END
