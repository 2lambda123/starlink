      SUBROUTINE KPG1_DCLID( NDIM, NDF, DALBND, DAUBND, SCALE, OFFSET,
     :                       LINEAR, STATUS )
*+
*  Name:
*     KPG1_DCLIx
 
*  Purpose:
*     Determines a linear transformation from pixel to NDF-axis
*     co-ordinates.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPG1_DCLIx( NDIM, NDF, DALBND, DAUBND, SCALE, OFFSET, LINEAR,
*                      STATUS )
 
*  Description:
*     This routine obtains a data co-ordinate system from the NDF
*     axes, and determines whether all the axes are linear.  If they
*     are linear transformations between pixel co-ordinates and
*     data co-ordinates are derived.  A warning message is reported
*     for each individual non-linear axis.
 
*  Arguments:
*     NDIM = INTEGER (Given)
*        The number of contiguous axes.  If it is negative, it indicates
*        that not all the dimensions need be significant.
*     NDF = INTEGER (Given)
*        The identifier of the NDF whose axes are to provide the data
*        co-ordinates.  It must have at least NDIM dimensions, though
*        this is not checked.
*     DALBND( NDIM ) = ? (Returned)
*        The lower bounds of the data co-ordinates obtained from the
*        NDF's axes.  Note that this gives the data co-ordinate at the
*        lower side of the array element, and not at its centre.
*     DAUBND( NDIM ) = ?  (Returned)
*        The upper bounds of the data co-ordinates obtained from the
*        NDF's axes.   Note that this gives the data co-ordinate at the
*        upper side of the array element, and not at its centre.
*     SCALE( NDIM ) = ? (Returned)
*        The scale factors in the linear transformations from world
*        to data co-ordinates.  They should be ignored if LINEAR is
*        false.
*     OFFSET( NDIM ) = ? (Returned)
*        The offsets in the linear transformations from world
*        to data co-ordinates.  They should be ignored if LINEAR is
*        false.
*     LINEAR = LOGICAL (Returned)
*        If true the NDF axes are all linear and different from world
*        co-ordinates.
*     STATUS = INTEGER (Given and Returned)
*        The global status.
 
*  Notes:
*     -  There is a routine for real and double-precision data types:
*     replace "x" in the routine name by R or D respectively.  The scale
*     and offset, and the bounds returned by the routine must have
*     the data type specified.
*     -  This routine assumes monotonic axes.
 
*  [optional_subroutine_items]...
*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     PWD: Peter W. Draper (Starlink, Durham University)
*     {enter_new_authors_here}
 
*  History:
*     1991 April 9 (MJC):
*        Original version.
*     1991 June 14 (MJC):
*        Converted to generic.
*     1992 March 31 (MJC):
*        Checked for significant dimensions.
*     1993 January 7 (MJC):
*        Allowed axes to be insignificant by passing a negative NDIM,
*        calling KPG1_SDIMP instead of KPG1_SGDIM, and setting the scale
*        and offset.
*     2004 September 1 (TIMJ):
*        Use CNF_PVAL
*     2004 September 20 (PWD):
*        Moved CNF_PAR include into declarations.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_PAR'          ! NDF constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT constants
      INCLUDE 'CNF_PAR'          ! CNF functions
 
*  Arguments Given:
      INTEGER
     :  NDIM,
     :  NDF
 
*  Arguments Returned:
      DOUBLE PRECISION
     :  DALBND( * ),
     :  DAUBND( * ),
     :  SCALE( * ),
     :  OFFSET( * )
 
      LOGICAL
     :  LINEAR
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      LOGICAL                  ! True if :
     :  AXLIN( NDF__MXDIM ),   ! Axes are linear
     :  IDENTY                 ! Axes have unit scale and zero offset
 
      INTEGER
     :  AEL,                   ! Number of elements in an axis array
     :  AXPNTR( 1 ),           ! Pointer to an NDF-axis component
     :  I,                     ! Loop counter
     :  LBND( NDF__MXDIM ),    ! Lower bounds of the NDF
     :  NDIMS,                 ! Number of dimensions possessed by the
                               ! NDF
     :  SGDIM( NDF__MXDIM ),   ! Significant dimensions of the NDF
     :  UBND( NDF__MXDIM )     ! Upper bounds of the NDF
 
      CHARACTER
     :  ATYPE * ( NDF__SZTYP ) ! Processing type of the axis centres
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'    ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'    ! NUM definitions for conversions
 
*.
 
*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Obtain the significant dimensions and bounds of the NDF.  The lower
*  bound is needed to compute the linear offset between world and data
*  co-ordinates.  The scale only needs the number of pixels which is
*  derived by mapping the axis.
 
*  Some applications may not need all the dimensions to be significant.
*  In this case we do not want an error, so call the routine that pads
*  out the list of "significant" dimensions with dummy ones.
      IF ( NDIM .LT. 0 ) THEN
         CALL KPG1_SDIMP( NDF, -NDIM, SGDIM, STATUS )
      ELSE
         CALL KPG1_SGDIM( NDF, NDIM, SGDIM, STATUS )
      END IF
      CALL NDF_BOUND( NDF, NDF__MXDIM, LBND, UBND, NDIMS, STATUS )
 
*  Assume that the data co-ordinates are linear and all have the
*  identity transformation, i.e. unit scale factor and zero offset.
      LINEAR = .TRUE.
      IDENTY = .TRUE.
 
      IF ( 'D' .EQ. 'D' ) THEN
         ATYPE = '_DOUBLE'
      ELSE
         ATYPE = '_REAL'
      END IF
 
*  Loop for each axis dimension.
      DO  I = 1, ABS( NDIM )
 
*  Map the axis centres for the dimension.
         CALL NDF_AMAP( NDF, 'Centre', SGDIM( I ), ATYPE, 'READ',
     :                  AXPNTR, AEL, STATUS )
 
*  Only evaluate the transformation when there are more than one element
*  along the axis.
         IF ( AEL .GT. 1 ) THEN
 
*  Find the range of the axis co-ordinates and whether or not the axis
*  is linear.
            CALL KPG1_AXLID( AEL, %VAL( CNF_PVAL( AXPNTR( 1 ) ) ), 
     :                       DALBND( I ),
     :                         DAUBND( I ), AXLIN( I ), STATUS )
 
*  Let the application complete without an error if the world
*  co-ordinates are non-linear, but issue a warning.
            IF ( .NOT. AXLIN( I ) ) THEN
               CALL MSG_SETI( 'IAXIS', I )
               CALL MSG_OUT( 'NONLINEAR',
     :           'Axis ^IAXIS is non-linear or reversed.  Data '/
     :           /'co-ordinates along any plot axis and in the '/
     :           /'database will be wrong.', STATUS )
 
*  Cannot store a non-linear transformation.
               LINEAR = .FALSE.
            ELSE
 
*  Determine the scale and offset of the transformation between world
*  and data co-ordinates.
               SCALE( I ) = ( DAUBND( I ) - DALBND( I ) ) /
     :                      NUM_ITOD( AEL - 1 )
               OFFSET( I ) = DALBND( I ) - SCALE( I ) *
     :                       ( NUM_ITOD( LBND( SGDIM( I ) ) ) - 0.5 )
 
*  Correct the lower and upper bounds data co-ordinates.  Current
*  values are for the array-element centres, whereas the co-ordinates
*  at the sides are required.  Thus apply half-pixel corrections.
               DAUBND( I ) = DAUBND( I ) + 0.5 * SCALE( I )
               DALBND( I ) = DALBND( I ) - 0.5 * SCALE( I )
 
*  Determine whether the two co-ordinate systems are identical.
               IDENTY = IDENTY .AND. (
     :               ABS( SCALE( I ) - 1.0D0 ) .LT. VAL__EPSD .AND.
     :               ABS( OFFSET( I ) - 0.0D0 ) .LT. VAL__EPSD )
 
*  End of check for linear axis.
            END IF
 
*  Given just one pixel, the scale is undefined.  The offset is just
*  the data-co-ordinate value of the single axis position, obtained by
*  the bounds-finding routine.
         ELSE
            CALL KPG1_AXBND( AEL, %VAL( CNF_PVAL( AXPNTR( 1 ) ) ), 
     :                       DALBND( I ),
     :                         DAUBND( I ), STATUS )
            SCALE( I ) = 0.0D0
            OFFSET( I ) = DALBND( I )
            IDENTY = .FALSE.
         END IF
 
*  Unmap the axis co-ordinates.
         CALL NDF_AUNMP( NDF, 'Centre', SGDIM( I ), STATUS )
 
      END DO
 
*  If the linear axes have identical co-ordinate systems the returned
*  flag is made false.
      LINEAR = LINEAR .AND. .NOT. IDENTY
 
      END
