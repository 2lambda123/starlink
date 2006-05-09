      SUBROUTINE KPS1_FAINR( BAD, DIM1, DIM2, INARR, SIGRNG, LOW,
     :                        HIGH, BADVAL, INVERT, OUTARR, LOWER,
     :                        UPPER, STATUS )
*+
*  Name:
*     KPS1_FAINx

*  Purpose:
*     Scales an image to a range of standard deviations about the
*     mean value of the image.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_FAINx( BAD, DIM1, DIM2, INARR, SIGRNG, LOW, HIGH,
*    :                 BADVAL, INVERT, OUTARR, LOWER, UPPER, STATUS )

*  Description:
*     This routine scales a 2-d array such that the lower and upper
*     limits are specified by two standard-deviation values about the
*     mean of the array.   The corresponding data values are mapped to
*     the lower and upper limits defined. The polarity of the scaling
*     is controllable by the order of the standard-deviation limits.
*     This routine is intended for picture display, and then the limits
*     correspond to lookup-table entries. Also, the scaled array may be
*     inverted so that when it is displayed it will come out the right
*     way around.

*  Arguments:
*     BAD = LOGICAL (Given)
*        If true bad pixels will be processed.  This should not be set
*        to false unless the input array contains no bad pixels.
*     DIM1 = INTEGER (Given)
*        The first dimension of the 2-d arrays.
*     DIM2 = INTEGER (Given)
*        The second dimension of the 2-d arrays.
*     INARR( DIM1, DIM2 ) = ? (Given)
*        This array contains the original image.
*     SIGRNG( 2 ) = REAL (Given)
*        The range of standard deviations between which the image is
*        to be scaled. Note to get values than span the mean one value
*        should be negative and the other positive.  Thus [-1,7] would
*        scale from the mean-sigma to the mean+7*sigma.  If the higher
*        value is in the first element, the scaling will have negative
*        polarity.
*     LOW = INTEGER (Given)
*        The lower limit for scaling (usually a graphics colour index).
*     HIGH = INTEGER (Given)
*        The upper limit for scaling (usually a graphics colour index).
*     BADVAL = INTEGER (Given)
*         The value to be assigned to bad pixels in the scaled array.
*     INVERT = LOGICAL (Given)
*        True if the image is to be inverted for display.
*     OUTARR( DIM1, DIM2 ) = INTEGER (Returned)
*        The array into which the scaled image is put.
*     LOWER = ? (Returned)
*        The lower limit used for scaling the image.
*     UPPER = ? (Returned)
*        The upper limit used for scaling the image.
*     STATUS = INTEGER (Given)
*        Value of the status on entry.

*  Notes:
*     -  There is a routine for each numeric data type: replace "x" in
*     the routine name by B, D, I, R, or W as appropriate. The array
*     and limits supplied to the routine must have the data type
*     specified.
*     -  The array is normally inverted so that the image will appear
*     the correct way round when displayed as the GKS routine
*     to display the image inverts it.
*     -  The statistical calculations are performed in double-precision
*     arithmetic.

*  Algorithm:
*     - Compute the mean and standard deviation of the array values.
*     - Derive the scaling limits.
*     - The scaled image is then produced with or without inversion,
*       and with or without bad-pixel checking via a subroutine. Bad
*       pixels are set to defined value.

*  Copyright:
*     Copyright (C) 1990-1991 Science & Engineering Research Council.
*     All Rights Reserved.

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
*     MJC: Malcolm J. Currie  (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1990 July 19 (MJC):
*        Original version.
*     1991 July 23 (MJC):
*        Added BADVAL argument.
*     {enter_further_changes_here}

*-
 
*  Type Definitions:
      IMPLICIT NONE
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT primitive data constants
 
*  Arguments Given:
      INTEGER
     :  DIM1, DIM2,
     :  HIGH,
     :  LOW,
     :  BADVAL
 
      LOGICAL
     :  BAD,
     :  INVERT
 
      REAL
     :  SIGRNG( 2 )
 
      REAL
     :  INARR( DIM1, DIM2 )
 
*  Arguments Returned:
      INTEGER
     :  OUTARR( DIM1, DIM2 )
 
      REAL
     :  LOWER,
     :  UPPER
 
*  Status:
      INTEGER STATUS
 
*  Local Variables:
      INTEGER
     :  I, J,                  ! General variables
     :  VALCNT                 ! Count of valid values of data elements
                               ! in the image
 
      DOUBLE PRECISION
     :  DIMAGE,                ! Current pixel value
     :  MEAN,                  ! Mean value of data
     :  SIGMA,                 ! Standard deviation of the image data
     :  SX,                    ! Sum of the image data elements
     :  SXX,                   ! Sum of the squares of the image data
                               ! elements
     :  VARNCE                 ! Variance of the image
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'    ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'    ! NUM definitions for conversions
 
*.
 
*    If the status on entry of this subroutine is bad, then
*    return to the calling program.
 
      IF ( STATUS .NE. SAI__OK ) RETURN
 
      SX = 0.0D0
      SXX = 0.0D0
 
*    Bad-pixel checking.
 
      IF ( BAD ) THEN
         VALCNT = 0
 
*       For all pixels in the input image.
 
         DO  I = 1, DIM2, 1
            DO  J = 1, DIM1, 1
 
*             Calculate the sum of the data elements and of the squares
*             of the data elements in the image, excluding the bad
*             pixels.
 
               IF ( INARR( J, I ) .NE. VAL__BADR ) THEN
                  DIMAGE = NUM_RTOD( INARR( J, I ) )
                  SX = SX + DIMAGE
                  SXX = SXX + DIMAGE * DIMAGE
                  VALCNT = VALCNT + 1
               END IF
 
            END DO
         END DO
 
*       Check that there sufficient pixels to define a sigma.
 
         IF ( VALCNT .LT. 2 ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'KPS1_FAINx_INSP',
     :        'Insufficient valid pixels to calculate statistics',
     :        STATUS )
            GOTO 999
         END IF
      ELSE
 
*       All elements are valid.
 
         VALCNT = DIM1 * DIM2
 
*       For all pixels in the input image.
 
         DO  I = 1, DIM2, 1
            DO  J = 1, DIM1, 1
 
               DIMAGE = NUM_RTOD( INARR( J, I ) )
 
*             Calculate the sum of the data elements and of the squares
*             of the data elements in the image.
 
               SX = SX + DIMAGE
               SXX = SXX + DIMAGE * DIMAGE
            END DO
         END DO
      END IF
 
*    Calculate the mean and standard deviation of the image.
 
      MEAN = SX/ DBLE( VALCNT )
 
      VARNCE = ( SXX - SX * SX / DBLE( VALCNT ) ) / DBLE( VALCNT-1 )
      IF ( VARNCE .LT. VAL__SMLD ) THEN
         SIGMA = 0.0
      ELSE
         SIGMA = REAL( SQRT( VARNCE ) )
      END IF
 
*    Calculate the upper and lower limits between which the image will
*    be scaled.  These may be constrained by the extreme values for the
*    data type.
 
      LOWER = NUM_DTOR( MAX( MEAN + SIGRNG( 1 ) * SIGMA,
     :                    NUM_RTOD( VAL__MINR ) ) )
      UPPER = NUM_DTOR( MIN( MEAN + SIGRNG( 2 ) * SIGMA,
     :                    NUM_RTOD( VAL__MAXR ) ) )
 
*    Report the scaling limits.
 
      CALL MSG_SETD( 'MINVAL', NUM_RTOD( LOWER ) )
      CALL MSG_SETD( 'MAXVAL', NUM_RTOD( UPPER ) )
      CALL MSG_OUT( 'PVLO', 'Data will be scaled from ^MINVAL to '/
     :              /'^MAXVAL.', STATUS )
 
*    Scale the values between the upper and lower pens.
 
      CALL KPG1_ISCLR( BAD, DIM1, DIM2, INARR, INVERT, LOWER, UPPER,
     :                   LOW, HIGH, BADVAL, OUTARR, STATUS )
 
 999  CONTINUE
 
      END
