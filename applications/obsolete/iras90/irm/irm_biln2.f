      SUBROUTINE IRM_BILN2( X, Y, XLO, XHI, YLO, YHI, DATA, INTERP,
     :                      STATUS )
*+
*  Name:
*     IRM_BILN2

*  Purpose:
*     Perform bi-linear interpolation with no checking for bad values.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRM_BILN2( X, Y, XLO, XHI, YLO, YHI, DATA, INTERP, STATUS )

*  Description:
*     An imaginary pixel is centred on the supplied interpolation
*     position. The area of the overlap between this imaginary pixel
*     and each of the four surrounding real pixels is found, and used
*     as the weight for the corresponding pixel value. The returned
*     interpolated value is the weighted mean of the four surrounding
*     pixel values. A bad value is returned if any of these four pixels
*     lie outside the image.

*  Arguments:
*     X = REAL (Given)
*        The pixel X coordinate at which to perform the interpolation.
*     Y = REAL (Given)
*        The pixel Y coordinate at which to perform the interpolation.
*     XLO = INTEGER (Given)
*        The lower bound on the array X axis.
*     XHI = INTEGER (Given)
*        The upper bound on the array X axis.
*     YLO = INTEGER (Given)
*        The lower bound on the array Y axis.
*     YHI = INTEGER (Given)
*        The upper bound on the array Y axis.
*     DATA( XLO:XHI, YLO:YHI ) = REAL (Given)
*        The data array to be interpolated.
*     INTERP = REAL (Returned)
*        The interpolated value.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     20-JAN-1992 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants.
      INCLUDE 'PRM_PAR'          ! Starlink data constants.

*  Arguments Given:
      REAL X
      REAL Y
      INTEGER XLO
      INTEGER XHI
      INTEGER YLO
      INTEGER YHI
      REAL DATA( XLO:XHI, YLO:YHI )

*  Arguments Returned:
      REAL INTERP

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      REAL DX                    ! Overlap in X between two left pixels
                                 ! and imaginary interpolating pixel.
      REAL DY                    ! Overlap in Y between two lower pixels
                                 ! and imaginary interpolating pixel.
      REAL EX                    ! Overlap in X between two right pixels
                                 ! and imaginary interpolating pixel.
      REAL EY                    ! Overlap in Y between two upper pixels
                                 ! and imaginary interpolating pixel.
      INTEGER IX                 ! X index of lower left pixel.
      INTEGER IY                 ! Y index of lower left pixel.
      INTEGER JX                 ! X index of upper right pixel.
      INTEGER JY                 ! Y index of upper right pixel.
      REAL V1                    ! Lower left pixel value.
      REAL V2                    ! Upper left pixel value.
      REAL V3                    ! Lower right pixel value.
      REAL V4                    ! Upper right pixel value.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Find the indices of the pixel which is centred to the lower left of
*  the required interpolation point.
      IX = INT( X + 0.5 )
      IY = INT( Y + 0.5 )

*  Find the indices of the pixel which is centred to the upper right of
*  the required interpolation point.
      JX = IX + 1
      JY = IY + 1

*  Check that all four neighbouring pixels are within the image area.
      IF( IX .GE. XLO .AND. JX .LE. XHI .AND.
     :    IY .GE. YLO .AND. JY .LE. YHI ) THEN

*  Store the four pixel values.
         V1 = DATA( IX, IY )
         V2 = DATA( IX, JY )
         V3 = DATA( JX, IY )
         V4 = DATA( JX, JY )

*  Find the fractions of the lower left pixel X and Y dimensions which
*  are included in the area covered by a pixel centred on the required
*  interpolation point.
         DX = 0.5 - X + IX
         DY = 0.5 - Y + IY

*  Find the fractions of the upper right pixel X and Y dimensions which
*  are included in the area covered by a pixel centred on the required
*  interpolation point.
         EX = 1.0 - DX
         EY = 1.0 - DY

*  Evaluate the interpolated values by weighting the four surrounding
*  pixel values by the are of overlap which the pixel has with a pixel
*  centred on the required interpolation point.
         INTERP = V1*DX*DY + V2*DX*EY + V3*EX*DY + V4*EX*EY

*  Return a bad value if any of the four surrrounding pixels do not lie
*  within the image area.
      ELSE
         INTERP = VAL__BADR

      END IF

      END
