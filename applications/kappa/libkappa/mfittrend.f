      SUBROUTINE MFITTREND( STATUS )
*+
*  Name:
*     MFITTREND

*  Purpose:
*     Fits independent trends to data lines that are parallel to an
*     axis.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL MFITTREND( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This routine fits trends to all lines of data in an NDF that lie
*     parallel to a chosen axis.  The trends are characterised by
*     polynomials of order up to 15 and can be restricted to use data
*     that only lies within a series of co-ordinate ranges along the
*     selected axis.
*
*     The ranges may be determined automatically.  It this mode the
*     application averages selected lines, and bins neighbouring pixels
*     within this average line.  Then it performs a linear fit upon the
*     binned line, and rejects the outliers, iteratively with
*     standard-deviation clipping.  The ranges are the intervals between
*     the rejected points, rescaled to the original pixels.
*
*     Once the trends have been determined they can either be stored
*     directly or subtracted from the input data.  If stored directly
*     they can be subtracted later.  The advantage of that approach is
*     the subtraction can be undone, but at some cost in efficiency.
*
*     Fits may be rejected if their root-mean squared (rms) residuals 
*     are more than a specified number of standard deviations from the 
*     the mean rms residuals of the fits.  Rejected fits appear as
*     bad pixels in the output data.

*     Fitting independent trends can be useful when you need to remove
*     the continuum from a spectral cube, where each spectrum is
*     independent of the others (that is you need an independent
*     continuum determination for each position on the sky).  It can 
*     also be used to de-trend individual spectra and perform functions
*     like debiassing a CCD which has bias strips.

*  Usage:
*     mfittrend in axis ranges order out

*  ADAM Parameters:
*     ARANGES() = _INTEGER (Write)
*        This parameter is only written when AUTO=TRUE, recording the
*        trend-axis fitting regions determined automatically.  They 
*        comprise pairs of grid co-ordinates.
*     AUTO = _LOGICAL (Read)
*        If TRUE, the ranges that define the trends are determined
*        automatically, and parameter RANGES is ignored.  [FALSE]
*     AXIS = LITERAL (Read)
*        The axis of the current co-ordinate system that defines the
*        direction of the trends.  This is specified by its integer 
*        index within the current Frame of the input NDF (in the range
*        1 to the number of axes in the current Frame), or by its symbol
*        string.  A list of acceptable values is displayed if an illegal
*        value is supplied.  If the axes of the current Frame are not
*        parallel to the NDF pixel axes, then the pixel axis which is
*        most nearly parallel to the specified current Frame axis will
*        be used.  AXIS defaults to the last axis.  [!]
*     CLIP() = _REAL (Read)
*        Array of standard-deviation limits for progressive clipping 
*        of pixel values while determining the fitting ranges 
*        automatically.  It is therefore only applicable when AUTO=TRUE.
*        Between one and five values may be supplied.  [2,2,2.5,3]
*     IN = NDF (Read & Write)
*        The input NDF.  On successful completion this may have the
*        trends subtracted, but only if SUBTRACT and MODIFYIN are both
*        set TRUE.
*     MODIFYIN = _LOGICAL (Read)
*        Whether or not to modify the input NDF.  It is only used when
*        SUBTRACT is TRUE.  If MODYFYIN is FALSE, then an NDF name must
*        be supplied by the OUT parameter.  [FALSE]
*     ORDER = _INTEGER (Read)
*        The order of the polynomials to be used when trend fitting.
*        A polynomial of order 0 is a constant and 1 a line, 2 a
*        quadratic etc.  The maximum value is 15.  [3]
*     OUT = NDF (Read)
*        The output NDF containing either the difference between the
*        input NDF and the various trends, or the values of the trends
*        themselves.  This will not be used if SUBTRACT and MODIFYIN
*        are TRUE (in that case the input NDF will be modified).
*     RANGES() = LITERAL (Read)
*        These are the pairs of co-ordinates that define ranges 
*        along the trend axis.  When given these ranges are used to 
*        select the values that are used in the fits.  The null value 
*        (!) causes all the values along each data line to be used.  The
*        units of these ranges is determined by the current axis of the
*        world co-ordinate system that corresponds to the trend axis.  
*        Up to ten pairs of values are allowed.  This parameter is not
*        accessed when AUTO=TRUE.  [!]
*     RMSCLIP = _REAL (Read)
*        The number of standard deviations exceeding the mean of the 
*        root-mean-squared residuals of the fits at which a fit is
*        rejected.  A null value (!) means perform no rejections.  
*        Allowed values are between 2 and 15.  [!]
*     SECTION = LITERAL (Read)
*        The region from which representative lines are averaged
*        in automatic mode to determine the regions to fit trends.  It
*        is therefore only accessed when AUTO=TRUE and the
*        dimensionality of the input NDF is more than 1.  The value is 
*        defined as an NDF section, so that ranges can be defined along 
*        any axis, and be given as pixel indices or axis (data) 
*        co-ordinates.  The pixel axis corresponding to parameter AXIS
*        is ignored.   So for example, if the pixel axis were 3 in a
*        cube, the value "3:5,4," would average all the lines 
*        in elements in columns 3 to 5 and row 4.  See "NDF sections" 
*        in SUN/95, or the online documentation for details.  
*
*        A null value (!) requests that a representative region around 
*        the centre be used.  [!]
*     SUBTRACT = _LOGICAL (Read)
*        Whether not to subtract the trends from the input NDF or not. 
*        If not, then the trends will be evaluated and written to a new 
*        NDF.  [FALSE]
*     TITLE = LITERAL (Read)
*        Value for the title of the output NDF.  A null value will cause
*        the title of the NDF supplied for parameter IN to be used
*        instead.  [!]
*     VARIANCE = _LOGICAL (Read)
*        If TRUE and the input NDF contains variances, then the
*        polynomial fits will be weighted by the variances.

*  Examples:
*     mfittrend in=cube axis=3 ranges="1000,2000,3000,4000" order=4 
*               out=detrend
*        This example fits cubic polynomials to the spectral axis of
*        a data cube. The fits only use the data lying within the
*        ranges 1000 to 2000 and 3000 to 4000 Angstroms (assuming
*        the spectral axis is calibrated in Angstroms and that is the
*        current co-ordinate system).  The fit is evaluated and
*        written to the data cube called detrend.
*     mfittrend in=cube axis=3 auto clip=[2,3] order=4 out=detrend
*        As above except the fitting ranges are determined automatically
*        with 2- then 3-sigma clipping.

*  Notes:
*     -  This application attempts to solve the problem of fitting 
*     numerous polynomials in a least-squares sense and that do not 
*     follow the natural ordering of the NDF data, in the most 
*     CPU-time-efficient way possible.
*
*     To do this requires the use of additional memory (of order one
*     less than the dimensionality of the NDF itself, times the
*     polynomial order squared).  To minimise the use of memory and get
*     the fastest possible determinations you should not use weighting
*     and assert that the input data do not have any BAD values (use the
*     application SETBAD to set the appropriate flag).
*     -  You may need to determine empirically what is the best
*     clipping limits and region to average if you choose to use the
*     automatic range determination.  At present the binning factor
*     is fixed to give 32 bins, unless the number of elements is
*     fewer whereupon there is no binning with the averaged line.

*  Related Applications:
*     FIGARO: FITCONT, FITPOLY; CCDPACK: DEBIAS; KAPPA: SETBAD.

*  Implementation Status:
*     -  This routine correctly processes the AXIS, DATA, QUALITY,
*     LABEL, UNITS, TITLE, HISTORY, WCS and VARIANCE components of an
*     NDF data structure and propagates all extensions.
*     -  Processing of bad pixels and automatic quality masking are
*     supported.
*     -  All non-complex numeric data types can be handled.
*     -  Handles data of up to 7 dimensions.

*  Copyright:
*     Copyright (C) Particle Physics and Astronomy Research Council.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either Version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
*     02111-1307, USA.

*  Authors:
*     PWD: Peter W. Draper (JAC, Durham University)
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     14-SEP-2005 (PWD):
*        Original version, some parts from COLLAPSE.
*     2006 April 12 (MJC):
*        Remove unused variables.
*     2006 May 31 (MJC):
*        Added option for automatic estimations of the ranges.
*     2007 January 11 (MJC):
*        Added clipping of outlier fits via the RMSCLIP parameter.
*     2007 January 18 (MJC):
*        Constrain the automatic ranges to be within the NDF's bounds.
*        Record automatically determined fitting regions to output
*        parameter ARANGES.
*     {enter_further_changes_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST parameters and functions
      INCLUDE 'DAT_PAR'          ! Data-system constants
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function
      INCLUDE 'MSG_PAR'          ! Message-system constants
      INCLUDE 'NDF_PAR'          ! NDF_ public constants
      INCLUDE 'PAR_ERR'          ! Parameter-system errors
      INCLUDE 'PRM_PAR'          ! Magic-value definitions

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER KPG1_FLOOR         ! Most positive integer .LE. a given 
                                 ! real
      INTEGER KPG1_CEIL          ! Most negative integer .GE. a given
                                 ! real

*  Local Constants:
      INTEGER MAXRNG             ! Maximum number of range limits
      PARAMETER( MAXRNG = 20 )

      INTEGER MXCLIP             ! Maximum number of clips of the data
      PARAMETER ( MXCLIP = 5 )

*  Local Variables:
      CHARACTER COMP * ( 15 )    ! List of array components to process
      CHARACTER ITYPE * ( NDF__SZTYP ) ! Numeric type for processing
      CHARACTER * ( DAT__SZLOC ) LOC ! Locator for the input NDF
      CHARACTER * ( 80 ) SECT    ! Section specifier
      CHARACTER * ( 255 ) TTLC   ! Title of original current Frame
      DOUBLE PRECISION CPOS( 2, NDF__MXDIM ) ! Two current Frame 
                                 ! positions
      DOUBLE PRECISION CURPOS( NDF__MXDIM ) ! A valid current Frame 
                                 ! position
      DOUBLE PRECISION DLBND( NDF__MXDIM ) ! Lower bounds, pixel co-ords
      DOUBLE PRECISION DRANGE( MAXRNG ) ! Fit ranges world co-ordinates
      DOUBLE PRECISION DUBND( NDF__MXDIM ) ! Upper bounds, pixel co-ords
      DOUBLE PRECISION PIXPOS( NDF__MXDIM ) ! A valid pixel Frame
                                 ! position
      DOUBLE PRECISION PPOS( 2, NDF__MXDIM ) ! Two pixel Frame positions
      DOUBLE PRECISION PRJ       ! Vector length projected on to a pixel
                                 ! axis
      DOUBLE PRECISION PRJMAX    ! Maximum vector length projected on to
                                 ! an axis
      INTEGER AREA               ! Area of axes orthogonal to fit axis
      INTEGER CFRM               ! Current frame
      INTEGER DIMS( NDF__MXDIM ) ! Dimensions of NDF
      INTEGER EL                 ! Number of mapped elements
      INTEGER I                  ! Loop variable
      INTEGER IAXIS              ! Index of axis within current Frame
      INTEGER IERR               ! Position of first error (dummy)
      INTEGER INNDF              ! NDF identifier of input NDF
      INTEGER IPAS               ! Pointer to workspace
      INTEGER IPBS               ! Pointer to coefficients
      INTEGER IPCOL              ! Pointer to collapsed rms residuals
      INTEGER IPDAT( 2 )         ! Pointer to NDF data & variance comp's
      INTEGER IPIN               ! Pointer to input NDF data
      INTEGER IPIX               ! Index of PIXEL Frame within FrameSet
      INTEGER IPRES              ! Pointer to array of residuals
      INTEGER IPTMP( 1 )         ! Pointer to temporary NDF component
      INTEGER IPVAR( 1 )         ! Pointer to NDF variance component
      INTEGER IPWRK1             ! Pointer to workspace
      INTEGER IPWRK2             ! Pointer to workspace
      INTEGER IPWRK3             ! Pointer to workspace
      INTEGER IWCS               ! AST FrameSet identifier
      INTEGER JAXIS              ! Index of axis within pixel Frame
      INTEGER JHI                ! High pixel index for axis
      INTEGER JLO                ! Low pixel index for axis
      INTEGER LBND( NDF__MXDIM ) ! Lower bounds of NDF
      INTEGER MAP                ! PIXEL Frame to Current Frame Mapping
                                 ! pointer
      INTEGER NAXC               ! Number of axes in current frame
      INTEGER NCLIP              ! Number of clips of averaged data
      INTEGER NCSECT             ! Number of characters in section
      INTEGER NDFS               ! NDF identifier of section
      INTEGER NDIM               ! Number of NDF dimensions
      INTEGER NERR               ! Number of errors
      INTEGER NRANGE             ! Number of range values (not pairs)
      INTEGER ORDER              ! The order of the polynomial to fit
      INTEGER OUTNDF             ! NDF identifier of output NDF
      INTEGER RANGES( MAXRNG )   ! The fit ranges pixels
      INTEGER UBND( NDF__MXDIM ) ! Upper bounds of NDF
      LOGICAL AUTO               ! Determine regions automatically?
      LOGICAL CLIPRE             ! Clip the outlier residuals?
      LOGICAL HASBAD             ! Input NDF may have BAD pixels?
      LOGICAL HAVVAR             ! Have a variance component?
      LOGICAL MODIN              ! Modify input NDF by subtracting fits?
      LOGICAL SUBTRA             ! Subtract fit from data?
      LOGICAL USEALL             ! Use the entire axis?
      LOGICAL USEVAR             ! Use variance as weights in fits?
      REAL CLIP( MXCLIP )        ! Clipping sigmas during binning
      REAL CLPRMS                ! Clipping sigma for outlier rejection

*.

*  Future development notes: should look at storing the coefficients and
*  write a model evaluating application MAKETREND?  This would follow
*  the KAPPA model more closely and allow the fit to be undone, even
*  when subtracting directly.  Maybe a need for a statistics-generating
*  version too, but the quality of the fits is a potentially large
*  amount of information.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Obtain the main parameters.
*  ===========================
*  Get the order of the polynomial.
      CALL PAR_GDR0I( 'ORDER', 3, 0, 15, .FALSE., ORDER, STATUS )

*  See if we should subtract fit from data. Need to do this early as we
*  may be modifying the input NDF.
      CALL PAR_GET0L( 'SUBTRACT', SUBTRA, STATUS )

*  See if the input NDF should have the fits subtracted, only matters if
*  we're subtracting the fit.
      MODIN = .FALSE.
      IF ( SUBTRA ) THEN
         CALL PAR_GET0L( 'MODIFYIN', MODIN, STATUS )
      END IF

*  Obtain the rms clipping threshold.
      CLIPRE = .FALSE.
      CALL PAR_GDR0R( 'RMSCLIP', 4.0, 2.0, 15.0, .FALSE., CLPRMS,
     :                STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
      ELSE IF ( STATUS .EQ. SAI__OK ) THEN
         CLIPRE = .TRUE.
      END IF

*  Access the input NDF.
*  =====================
*  Start an AST context.
      CALL AST_BEGIN( STATUS )

*  Begin an NDF context.
      CALL NDF_BEGIN

*  Obtain identifier for the input NDF.
      IF ( MODIN ) THEN
         CALL LPG_ASSOC( 'IN', 'UPDATE', INNDF, STATUS )
      ELSE
         CALL LPG_ASSOC( 'IN', 'READ', INNDF, STATUS )
      END IF

*  Get the bounds and dimensionality.
      CALL NDF_BOUND( INNDF, NDF__MXDIM, LBND, UBND, NDIM, STATUS )

*  Extra dimensions have nominal size 1.
      DO I = NDIM + 1, NDF__MXDIM
         LBND( I ) = 1
         UBND( I ) = 1
      END DO

*  Get dimensions of NDF.
      DO I = 1, NDF__MXDIM
         DIMS( I ) = UBND( I ) - LBND( I ) + 1
      END DO

*  Do we have any variances to use for weights and should they be used?
      CALL NDF_STATE( INNDF, 'Variance', HAVVAR, STATUS )
      IF ( HAVVAR ) THEN
         CALL PAR_GET0L( 'VARIANCE', USEVAR, STATUS )
         COMP = 'Data,Variance'
      ELSE
         USEVAR = .FALSE.
         COMP = 'Data'
      END IF

*  Get the fit ranges.
*  ===================
      USEALL = .FALSE.

*  Manual or automatic estimation?
      CALL PAR_GET0L( 'AUTO', AUTO, STATUS )
      IF ( STATUS .NE. SAI__OK ) GO TO 999

*  Get the WCS FrameSet from the NDF.
      CALL KPG1_GTWCS( INNDF, IWCS, STATUS )

*  Extract the current Frame, this is used for picking the axis and the
*  units of the ranges.
      CFRM = AST_GETFRAME( IWCS, AST__CURRENT, STATUS )
      NAXC = AST_GETI( CFRM, 'NAXES', STATUS )
      TTLC = AST_GETC( CFRM, 'TITLE', STATUS )

*  Get axis to fit the polynomials to. Default is last axis in the WCS.
      IF ( NDIM .NE. 1 ) THEN
         IAXIS = NAXC
         CALL KPG1_GTAXI( 'AXIS', CFRM, 1, IAXIS, STATUS )
      ELSE
         IAXIS = 1
      END IF

*  Find the index of the PIXEL Frame.
      CALL KPG1_ASFFR( IWCS, 'PIXEL', IPIX, STATUS )

*  Extract the Mapping from PIXEL Frame to Current Frame.
      MAP = AST_GETMAPPING( IWCS, IPIX, AST__CURRENT, STATUS )

*  Report an error if the Mapping is not defined in either direction.
      IF ( .NOT. AST_GETL( MAP, 'TRANINVERSE', STATUS ) .AND.
     :     STATUS .EQ. SAI__OK ) THEN
         STATUS = SAI__ERROR
         CALL NDF_MSG( 'NDF', INNDF )
         CALL MSG_SETC( 'T', TTLC )
         CALL ERR_REP( 'MFITTREND_ERR2', 'The transformation from '//
     :                 'the current co-ordinate Frame of ''^NDF'' '//
     :                 '(^T) to pixel co-ordinates is not defined.',
     :                 STATUS )

      ELSE IF ( .NOT. AST_GETL( MAP, 'TRANFORWARD', STATUS ) .AND.
     :          STATUS .EQ. SAI__OK ) THEN
         STATUS = SAI__ERROR
         CALL NDF_MSG( 'NDF', INNDF )
         CALL MSG_SETC( 'T', TTLC )
         CALL ERR_REP( 'MFITTREND_ERR3', 'The transformation from '//
     :                 'pixel co-ordinates to the current '//
     :                 'co-ordinate Frame of ''^NDF'' (^T) is not '//
     :                 'defined.', STATUS )
      END IF
      IF ( STATUS .NE. SAI__OK ) GO TO 999

      IF ( AUTO ) THEN
         CALL MSG_BLANK( STATUS )
         CALL MSG_OUTIF( MSG__NORM, 'AUTOWARN1',
     :     'WARNING: The automatic mode has undergone only moderate '//
     :     'testing.  Check that the regions used for fitting '//
     :     'reported below are sensible, i.e. avoid features like '//
     :     'spectral lines.', STATUS )
         CALL MSG_BLANK( STATUS )
         CALL MSG_OUTIF( MSG__NORM, 'AUTOWARN2',
     :     'Feedback is welcome on the tuning of the CLIP '//
     :     'parameter''s default, the size of the default averaging '//
     :     'region, the binning resolution, and whether or not the '//
     :     'simple linear fit is adequate for detecting features '//
     :     'and not rejecting curvature in the trend.', STATUS )
         CALL MSG_BLANK( STATUS )
      ELSE

*  Get the ranges to use. These values are transformed from current
*  co-ordinates along the fit axis to pixel co-ordinates on some
*  NDF axis (we've yet to determine).
         DRANGE( 1 ) = AST__BAD
         CALL KPG1_GTAXV( 'RANGES', MAXRNG, .FALSE., CFRM, IAXIS,
     :                    DRANGE, NRANGE, STATUS )

*  If a null value was supplied then we should use the full extent.
         IF ( STATUS .EQ. PAR__NULL ) THEN
            CALL ERR_ANNUL( STATUS )
            USEALL = .TRUE.
         ELSE

*  Ranges must come in pairs.
            IF ( 2 * ( NRANGE / 2 ) .NE. NRANGE ) THEN
               STATUS = SAI__ERROR
               CALL ERR_REP( 'MFITTREND_ERR4',
     :                       'Range values must be supplied in pairs',
     :                       STATUS )
               GO TO 999
            END IF
         END IF
      END IF

*  Obtain the NDF axis corresponding to the WCS axis.
*  --------------------------------------------------

*  WCS axes can be permuted, rotated etc. so we must check.

*  Find an arbitrary position within the NDF which has valid current
*  Frame co-ordinates. Both pixel and current Frame co-ordinates for
*  this position are returned.
      DO I = 1, NDIM
         DLBND( I ) = DBLE( LBND( I ) - 1 )
         DUBND( I ) = DBLE( UBND( I ) )
      END DO
      CALL KPG1_ASGDP( MAP, NDIM, NAXC, DLBND, DUBND, PIXPOS, CURPOS,
     :                 STATUS )

*  Create two copies of these current Frame co-ordinates.
      DO I = 1, NAXC
         CPOS( 1, I ) = CURPOS( I )
         CPOS( 2, I ) = CURPOS( I )
      END DO

*  If no ranges were supplied, modify the values in these positions by
*  an arbitrary amount.
      IF ( AUTO .OR. USEALL ) THEN
         IF ( CURPOS( IAXIS ) .NE. 0.0 ) THEN
            CPOS( 1, IAXIS ) = 0.99 * CURPOS( IAXIS )
            CPOS( 2, IAXIS ) = 1.01 * CURPOS( IAXIS )
         ELSE
            CPOS( 1, IAXIS ) = CURPOS( IAXIS ) + 1.0D-4
            CPOS( 2, IAXIS ) = CURPOS( IAXIS ) - 1.0D-4
         END IF

*  Use the first set of ranges.
      ELSE
         CPOS( 1, IAXIS ) = DRANGE( 2 )
         CPOS( 2, IAXIS ) = DRANGE( 1 )
      END IF

*  Transform these two positions into pixel co-ordinates.
      CALL AST_TRANN( MAP, 2, NAXC, 2, CPOS, .FALSE., NDIM, 2, PPOS,
     :                STATUS )

*  Find the pixel axis with the largest projection of the vector joining
*  these two pixel positions. The ranges apply to this axis. Report an
*  error if the positions do not have valid pixel co-ordinates.
      PRJMAX = -1.0
      DO I = 1, NDIM
         IF ( PPOS( 1, I ) .NE. AST__BAD .AND.
     :        PPOS( 2, I ) .NE. AST__BAD ) THEN

            PRJ = ABS( PPOS( 1, I ) - PPOS( 2, I ) )
            IF ( PRJ .GT. PRJMAX ) THEN
               JAXIS = I
               PRJMAX = PRJ
            END IF

         ELSE IF ( STATUS .EQ. SAI__OK ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'MFITTREND_ERR5', 'The WCS information is '//
     :                    'too complex (cannot find two valid pixel '//
     :                    'positions). Change current frame to PIXEL '//
     :                    'and try again', STATUS )
            GO TO 999
         END IF
      END DO

*  Automatic mode to define ranges.
*  --------------------------------
      IF ( AUTO ) THEN

*  Obtain the clipping thresholds.
         NCLIP = 0
         CALL PAR_GDRVR( 'CLIP', MXCLIP, 1.0, VAL__MAXR,
     :                   CLIP, NCLIP, STATUS )
         IF ( STATUS .EQ. PAR__NULL ) THEN
            CALL ERR_ANNUL( STATUS )
            NCLIP = 3
            CLIP( 1 ) = 2.0
            CLIP( 2 ) = 2.5
            CLIP( 3 ) = 3.0

         ELSE IF ( STATUS .NE. SAI__OK ) THEN
            GOTO 999

         END IF

*  Obtain the NDF section of the test region.
         CALL KPS1_MFGNS( 'SECTION', JAXIS, NDIM, DIMS, NCSECT,
     :                    SECT, STATUS )

*  Obtain a locator to the input NDF.
         CALL NDF_LOC( INNDF, 'Read', LOC, STATUS )

*  Create the section in the input array.  Allow dfor a null string
*  for a one-dimensional NDF.
         IF ( NCSECT .GT. 0 ) THEN
            CALL NDF_FIND( LOC, '(' // SECT( :NCSECT ) // ')', NDFS,
     :                     STATUS )
         ELSE
            CALL NDF_FIND( LOC, '()', NDFS, STATUS )
            CALL DAT_ANNUL( LOC, STATUS )
         END IF

*  Form ranges by averaging the lines in the section, and then
*  performing a fit, and rejecting outliers.
         CALL KPS1_MFAUR( NDFS, JAXIS, NCLIP, CLIP, MAXRNG, NRANGE, 
     :                    RANGES, STATUS )

*  Ensure that we have valid ranges before attempting to use them.
         IF ( STATUS .NE. SAI__OK ) GOTO 999

*  Convert the GRID co-ordinates of the RANGES to pixel co-ordinates.
*  Also ensure that the selected regions are within the NDF bounds.
         DO I = 1, NRANGE
            RANGES( I ) = MAX( MIN( DIMS( JAXIS ), RANGES( I ) ), 1 )
     :                    + LBND( JAXIS ) - 1
         END DO

*  Record the ranges to a parameter.
         CALL PAR_PUT1I( 'ARANGES', NRANGE, RANGES, STATUS )

*  OK, use NDF axis JAXIS. Pick full extent if no values were given.
      ELSE IF ( USEALL ) THEN
         RANGES( 1 ) = LBND( JAXIS )
         RANGES( 2 ) = UBND( JAXIS )
         NRANGE = 2

*  Project the given ranges into pixel co-ordinates.
      ELSE
         DO I = 1, NRANGE, 2
            CPOS( 1, IAXIS ) = DRANGE( I + 1 )
            CPOS( 2, IAXIS ) = DRANGE( I )

            CALL AST_TRANN( MAP, 2, NAXC, 2, CPOS, .FALSE., NDIM, 2,
     :                      PPOS, STATUS )

*  Find the projection of the two test points onto the axis.
            JLO = KPG1_FLOOR( REAL( MIN( PPOS( 1, JAXIS ),
     :                                   PPOS( 2, JAXIS ) ) ) )
            JHI = KPG1_CEIL( REAL( MAX( PPOS( 1, JAXIS ),
     :                                  PPOS( 2, JAXIS ) ) ) )

*  Ensure these are within the bounds of the pixel axis.
            JLO = MAX( LBND( JAXIS ), JLO )
            JHI = MIN( UBND( JAXIS ), JHI )

*  Report an error if there is no intersection.
            IF ( JLO .GT. JHI .AND. STATUS .EQ. SAI__OK ) THEN
               STATUS = SAI__ERROR
               CALL MSG_SETI( 'LO', JLO )
               CALL MSG_SETI( 'HI', JHI )
               CALL ERR_REP( 'MFITTREND_ERR6', 'An axis range '//
     :                       'covers zero pixels (are the '//
     :                       'RANGE values equal or outside the '//
     :                       'bounds of the NDF?)(^LO:^HI)',
     :                       STATUS )
               GO TO 999
            END IF

*  Store pixel co-ordinates.
            RANGES( I ) = JLO
            RANGES( I + 1 ) = JHI
         END DO
      END IF

*  Tell the user the ranges of pixel being used.
      CALL MSG_SETI( 'I', JAXIS )
      CALL MSG_OUT( ' ', '   Fitting NDF axis ^I, using pixel ranges:',
     :              STATUS )
      DO I = 1, NRANGE, 2
         CALL MSG_SETI( 'L', RANGES( I ) )
         CALL MSG_SETI( 'H', RANGES( I + 1 ) )
         CALL MSG_OUT( ' ', '      ^L : ^H ', STATUS )
      END DO
      CALL MSG_BLANK( STATUS )

*  Convert ranges into indices of the NDF data arrays by correcting for
*  the origin.
      DO I = 1, NRANGE
         RANGES( I ) = RANGES( I ) - LBND( JAXIS ) + 1
      END DO

*  Create output NDF.
*  ==================

*  If needed create a new output NDF based on the input NDF.
      IF ( SUBTRA ) THEN
         IF ( .NOT. MODIN ) THEN

*  Propagate all components except data and variance to the new NDF.
            CALL LPG_PROP( INNDF, 'Quality,Units,Label,Axis,WCS',
     :                     'OUT', OUTNDF, STATUS )
         END IF
      ELSE

*  Will write evals to a new NDF. Don't propagate quality as this is
*  model data now. Note we will also not propagate the variance.
         CALL LPG_PROP( INNDF, 'Units,Label,Axis,WCS', 'OUT', OUTNDF,
     :                  STATUS )
      END IF

*  Determine if the input NDF has an explicit no bad pixels flag. Could
*  make the check really check if there's no variances as this speeds
*  the calculations, but should let the user control that.
      CALL NDF_BAD( INNDF, 'Data', .FALSE., HASBAD, STATUS )

*  Get the data type.
      CALL NDF_TYPE( INNDF, 'DATA', ITYPE, STATUS )

*  Map the data. 
*  =============

*  Note we transfer the data component from the input NDF to the output 
*  NDF, as this saves on an unmap by HDS followed by a map by us (if we 
*  allowed this to propagate).
      IF ( SUBTRA ) THEN
         IF ( .NOT. MODIN ) THEN
            CALL NDF_MAP( INNDF, 'DATA', ITYPE, 'READ', IPTMP, EL,
     :                    STATUS )
            CALL NDF_MAP( OUTNDF, 'DATA', ITYPE, 'WRITE', IPDAT, EL,
     :                    STATUS )

*  Copy data to the output NDF.
            CALL KPG1_COPY( ITYPE, EL, IPTMP( 1 ), IPDAT( 1 ), STATUS )
            CALL NDF_UNMAP( INNDF, 'DATA', STATUS )

*  Same for variances.
            IF ( USEVAR ) THEN
               CALL NDF_MAP( INNDF, 'VARIANCE', ITYPE, 'READ', IPTMP,
     :                       EL, STATUS )
               CALL NDF_MAP( OUTNDF, 'VARIANCE', ITYPE, 'WRITE', IPVAR,
     :                       EL, STATUS )
               CALL KPG1_COPY( ITYPE, EL, IPTMP( 1 ), IPVAR( 1 ),
     :                         STATUS )
               CALL NDF_UNMAP( INNDF, 'VARIANCE', STATUS )
            END IF
         ELSE

*  Subtracting from the input DATA, just map that in update mode.
            CALL NDF_MAP( INNDF, 'DATA', ITYPE, 'UPDATE', IPDAT, EL,
     :                    STATUS )
            IF ( USEVAR ) THEN
               CALL NDF_MAP( INNDF, 'VARIANCE', ITYPE, 'UPDATE', IPVAR,
     :                       EL, STATUS )
            END IF
         END IF
      ELSE

*  No need to copy input data, will just populate output NDF data
*  component with model values.
         CALL NDF_MAP( INNDF, 'DATA', ITYPE, 'READ', IPDAT, EL,
     :                 STATUS )
         IF ( USEVAR ) THEN
            CALL NDF_MAP( INNDF, 'VARIANCE', ITYPE, 'READ', IPVAR, EL,
     :                    STATUS )
         END IF
      END IF

*  Allocate various workspaces. 
*  ============================

*  The requirements for the workspaces depends on the dimensionality. 
*  We need space for the cumulative coefficient sums and the 
*  coefficients themselves (Ax=B).
      AREA = 1
      DO 5 I = 1, NDIM
         IF ( I .NE. JAXIS ) THEN
            AREA = AREA * DIMS( I )
         END IF
 5    CONTINUE

      IF ( USEVAR .OR. HASBAD ) THEN
         CALL PSX_CALLOC( AREA * ( ORDER + 1 ) * ( ORDER + 1 ),
     :                    '_DOUBLE', IPAS, STATUS )
      ELSE

*  When there are no variances and we also know there are no BAD values
*  useful savings in memory and speed are available as the cumulative
*  sums for matrix inversion are fixed.
         CALL PSX_CALLOC( ( ORDER + 1 ) * ( ORDER + 1 ), '_DOUBLE',
     :                    IPAS, STATUS )
      END IF
      CALL PSX_CALLOC( AREA * ( ORDER + 1 ), '_DOUBLE', IPBS, STATUS )
      CALL PSX_CALLOC( AREA * ( ORDER + 1 ), '_DOUBLE', IPWRK1, STATUS )
      CALL PSX_CALLOC( AREA * ( ORDER + 1 ), '_INTEGER', IPWRK2,
     :                 STATUS )

*  Determine the fits.
*  ===================

*  N.B. could reduce memory use by NDF blocking though planes for 
*  higher dimensional data, or just mapping the intersection of ranges, 
*  or individual ranges, but that would only be good if working with the
*  last axis (need contiguity).
      IF ( USEVAR .OR. HASBAD ) THEN
         IF ( ITYPE .EQ. '_BYTE' ) THEN
            CALL KPS1_LFTB( ORDER, JAXIS, RANGES, NRANGE, USEVAR,
     :                      %VAL( CNF_PVAL( IPDAT( 1 ) ) ),
     :                      %VAL( CNF_PVAL( IPVAR( 1 ) ) ), DIMS,
     :                      %VAL( CNF_PVAL( IPAS ) ),
     :                      %VAL( CNF_PVAL( IPBS ) ),
     :                      %VAL( CNF_PVAL( IPWRK1 ) ),
     :                      %VAL( CNF_PVAL( IPWRK2 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_UBYTE' ) THEN
            CALL KPS1_LFTUB( ORDER, JAXIS, RANGES, NRANGE, USEVAR,
     :                       %VAL( CNF_PVAL( IPDAT( 1 ) ) ),
     :                       %VAL( CNF_PVAL( IPVAR( 1 ) ) ), DIMS,
     :                       %VAL( CNF_PVAL( IPAS ) ),
     :                       %VAL( CNF_PVAL( IPBS ) ),
     :                       %VAL( CNF_PVAL( IPWRK1 ) ),
     :                       %VAL( CNF_PVAL( IPWRK2 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
            CALL KPS1_LFTD( ORDER, JAXIS, RANGES, NRANGE, USEVAR,
     :                      %VAL( CNF_PVAL( IPDAT( 1 ) ) ),
     :                      %VAL( CNF_PVAL( IPVAR( 1 ) ) ), DIMS,
     :                      %VAL( CNF_PVAL( IPAS ) ),
     :                      %VAL( CNF_PVAL( IPBS ) ),
     :                      %VAL( CNF_PVAL( IPWRK1 ) ),
     :                      %VAL( CNF_PVAL( IPWRK2 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_INTEGER' ) THEN
            CALL KPS1_LFTI( ORDER, JAXIS, RANGES, NRANGE, USEVAR,
     :                      %VAL( CNF_PVAL( IPDAT( 1 ) ) ),
     :                      %VAL( CNF_PVAL( IPVAR( 1 ) ) ), DIMS,
     :                      %VAL( CNF_PVAL( IPAS ) ),
     :                      %VAL( CNF_PVAL( IPBS ) ),
     :                      %VAL( CNF_PVAL( IPWRK1 ) ),
     :                      %VAL( CNF_PVAL( IPWRK2 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_REAL' ) THEN
            CALL KPS1_LFTR( ORDER, JAXIS, RANGES, NRANGE, USEVAR,
     :                      %VAL( CNF_PVAL( IPDAT( 1 ) ) ),
     :                      %VAL( CNF_PVAL( IPVAR( 1 ) ) ), DIMS,
     :                      %VAL( CNF_PVAL( IPAS ) ),
     :                      %VAL( CNF_PVAL( IPBS ) ),
     :                      %VAL( CNF_PVAL( IPWRK1 ) ),
     :                      %VAL( CNF_PVAL( IPWRK2 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_WORD' ) THEN
            CALL KPS1_LFTW( ORDER, JAXIS, RANGES, NRANGE, USEVAR,
     :                      %VAL( CNF_PVAL( IPDAT( 1 ) ) ),
     :                      %VAL( CNF_PVAL( IPVAR( 1 ) ) ), DIMS,
     :                      %VAL( CNF_PVAL( IPAS ) ),
     :                      %VAL( CNF_PVAL( IPBS ) ),
     :                      %VAL( CNF_PVAL( IPWRK1 ) ),
     :                      %VAL( CNF_PVAL( IPWRK2 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_UWORD' ) THEN
            CALL KPS1_LFTUW( ORDER, JAXIS, RANGES, NRANGE, USEVAR,
     :                       %VAL( CNF_PVAL( IPDAT( 1 ) ) ),
     :                       %VAL( CNF_PVAL( IPVAR( 1 ) ) ), DIMS,
     :                       %VAL( CNF_PVAL( IPAS ) ),
     :                       %VAL( CNF_PVAL( IPBS ) ),
     :                       %VAL( CNF_PVAL( IPWRK1 ) ),
     :                       %VAL( CNF_PVAL( IPWRK2 ) ), STATUS )
         END IF
      ELSE

*  No variances and no bad values, use fastest method.
         IF ( ITYPE .EQ. '_BYTE' ) THEN
            CALL KPS1_LFTQB( ORDER, JAXIS, RANGES, NRANGE,
     :                       %VAL( CNF_PVAL( IPDAT( 1 ) ) ), DIMS,
     :                       %VAL( CNF_PVAL( IPAS ) ),
     :                       %VAL( CNF_PVAL( IPBS ) ),
     :                       %VAL( CNF_PVAL( IPWRK1 ) ),
     :                       %VAL( CNF_PVAL( IPWRK2 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_UBYTE' ) THEN
            CALL KPS1_LFTQUB( ORDER, JAXIS, RANGES, NRANGE,
     :                        %VAL( CNF_PVAL( IPDAT( 1 ) ) ), DIMS,
     :                        %VAL( CNF_PVAL( IPAS ) ),
     :                        %VAL( CNF_PVAL( IPBS ) ),
     :                        %VAL( CNF_PVAL( IPWRK1 ) ),
     :                        %VAL( CNF_PVAL( IPWRK2 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
            CALL KPS1_LFTQD( ORDER, JAXIS, RANGES, NRANGE,
     :                       %VAL( CNF_PVAL( IPDAT( 1 ) ) ), DIMS,
     :                       %VAL( CNF_PVAL( IPAS ) ),
     :                       %VAL( CNF_PVAL( IPBS ) ),
     :                       %VAL( CNF_PVAL( IPWRK1 ) ),
     :                       %VAL( CNF_PVAL( IPWRK2 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_INTEGER' ) THEN
            CALL KPS1_LFTQI( ORDER, JAXIS, RANGES, NRANGE,
     :                       %VAL( CNF_PVAL( IPDAT( 1 ) ) ), DIMS,
     :                       %VAL( CNF_PVAL( IPAS ) ),
     :                       %VAL( CNF_PVAL( IPBS ) ),
     :                       %VAL( CNF_PVAL( IPWRK1 ) ),
     :                       %VAL( CNF_PVAL( IPWRK2 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_REAL' ) THEN
            CALL KPS1_LFTQR( ORDER, JAXIS, RANGES, NRANGE,
     :                       %VAL( CNF_PVAL( IPDAT( 1 ) ) ), DIMS,
     :                       %VAL( CNF_PVAL( IPAS ) ),
     :                       %VAL( CNF_PVAL( IPBS ) ),
     :                       %VAL( CNF_PVAL( IPWRK1 ) ),
     :                       %VAL( CNF_PVAL( IPWRK2 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_WORD' ) THEN
            CALL KPS1_LFTQW( ORDER, JAXIS, RANGES, NRANGE,
     :                       %VAL( CNF_PVAL( IPDAT( 1 ) ) ), DIMS,
     :                       %VAL( CNF_PVAL( IPAS ) ),
     :                       %VAL( CNF_PVAL( IPBS ) ),
     :                       %VAL( CNF_PVAL( IPWRK1 ) ),
     :                       %VAL( CNF_PVAL( IPWRK2 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_UWORD' ) THEN
            CALL KPS1_LFTQUW( ORDER, JAXIS, RANGES, NRANGE,
     :                        %VAL( CNF_PVAL( IPDAT( 1 ) ) ), DIMS,
     :                        %VAL( CNF_PVAL( IPAS ) ),
     :                        %VAL( CNF_PVAL( IPBS ) ),
     :                        %VAL( CNF_PVAL( IPWRK1 ) ),
     :                        %VAL( CNF_PVAL( IPWRK2 ) ), STATUS )
         END IF
      END IF

* Free up the workspace at the earliest opportunity.
      CALL PSX_FREE( IPAS, STATUS )
      CALL PSX_FREE( IPWRK1, STATUS )
      CALL PSX_FREE( IPWRK2, STATUS )

*  Evaluate and optioally subtract the trends.
*  ===========================================

*  Subtract the result from the NDF data or write the evaluated fit.
*  If evaluating, then we need to map in the data component, may as
*  well release the input one to save VM.  Note that if resiual reject
*  of points is requested that the IPDAT pointer would be overloaded.
*  So retain the original pointer for the subtraction forming residuals.
      IF ( .NOT. SUBTRA ) THEN
         IF ( CLIPRE ) THEN
            IPIN = IPDAT( 1 )
         ELSE
            CALL NDF_UNMAP( INNDF, 'DATA', STATUS )
         END IF

         IF ( USEVAR ) THEN
            CALL NDF_UNMAP( INNDF, 'VARIANCE', STATUS )
         END IF
         CALL NDF_MAP( OUTNDF, 'DATA', ITYPE, 'WRITE', IPDAT,
     :                 EL, STATUS )
      END IF

      IF ( ITYPE .EQ. '_BYTE' ) THEN
         CALL KPS1_LFTSB( ORDER, JAXIS, SUBTRA,
     :                    DIMS, %VAL( CNF_PVAL( IPBS ) ),
     :                    %VAL( CNF_PVAL( IPDAT( 1 ) ) ), STATUS )

      ELSE IF ( ITYPE .EQ. '_UBYTE' ) THEN
         CALL KPS1_LFTSUB( ORDER, JAXIS, SUBTRA,
     :                     DIMS, %VAL( CNF_PVAL( IPBS ) ),
     :                     %VAL( CNF_PVAL( IPDAT( 1 ) ) ), STATUS )

      ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
         CALL KPS1_LFTSD( ORDER, JAXIS, SUBTRA,
     :                    DIMS, %VAL( CNF_PVAL( IPBS ) ),
     :                    %VAL( CNF_PVAL( IPDAT( 1 ) ) ), STATUS )

      ELSE IF ( ITYPE .EQ. '_INTEGER' ) THEN
         CALL KPS1_LFTSI( ORDER, JAXIS, SUBTRA,
     :                    DIMS, %VAL( CNF_PVAL( IPBS ) ),
     :                    %VAL( CNF_PVAL( IPDAT( 1 ) ) ), STATUS )

      ELSE IF ( ITYPE .EQ. '_REAL' ) THEN
         CALL KPS1_LFTSR( ORDER, JAXIS, SUBTRA,
     :                    DIMS, %VAL( CNF_PVAL( IPBS ) ),
     :                    %VAL( CNF_PVAL( IPDAT( 1 ) ) ), STATUS )

      ELSE IF ( ITYPE .EQ. '_WORD' ) THEN
         CALL KPS1_LFTSW( ORDER, JAXIS, SUBTRA,
     :                    DIMS, %VAL( CNF_PVAL( IPBS ) ),
     :                    %VAL( CNF_PVAL( IPDAT( 1 ) ) ), STATUS )

      ELSE IF ( ITYPE .EQ. '_UWORD' ) THEN
         CALL KPS1_LFTSUW( ORDER, JAXIS, SUBTRA,
     :                     DIMS, %VAL( CNF_PVAL( IPBS ) ),
     :                     %VAL( CNF_PVAL( IPDAT( 1 ) ) ), STATUS )
      END IF

* Free up the remaining workspace at the earliest opportunity.
      CALL PSX_FREE( IPBS, STATUS )

*  Form residuals.
*  ===============

*  If no detrended data calculated, i.e. the residuals, need to form 
*  the residuals to reject their outliers.
      IF ( CLIPRE ) THEN
         IF ( .NOT. SUBTRA ) THEN
            CALL PSX_CALLOC( EL, ITYPE, IPRES, STATUS )

*  Select the appropriate routine for the data type being processed and
*  subtract the data arrays.
            IF ( ITYPE .EQ. '_BYTE' ) THEN
               CALL VEC_SUBB( HASBAD, EL, %VAL( CNF_PVAL( IPIN ) ),
     :                        %VAL( CNF_PVAL( IPDAT( 1 ) ) ), 
     :                        %VAL( CNF_PVAL( IPRES ) ),
     :                        IERR, NERR, STATUS )
 
            ELSE IF ( ITYPE .EQ. '_UBYTE' ) THEN
               CALL VEC_SUBUB( HASBAD, EL, %VAL( CNF_PVAL( IPIN ) ),
     :                         %VAL( CNF_PVAL( IPDAT( 1 ) ) ), 
     :                         %VAL( CNF_PVAL( IPRES ) ),
     :                         IERR, NERR, STATUS )
 
            ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
               CALL VEC_SUBD( HASBAD, EL, %VAL( CNF_PVAL( IPIN ) ),
     :                        %VAL( CNF_PVAL( IPDAT( 1 ) ) ), 
     :                        %VAL( CNF_PVAL( IPRES ) ),
     :                        IERR, NERR, STATUS )
 
            ELSE IF ( ITYPE .EQ. '_INTEGER' ) THEN
               CALL VEC_SUBI( HASBAD, EL, %VAL( CNF_PVAL( IPIN ) ),
     :                        %VAL( CNF_PVAL( IPDAT( 1 ) ) ), 
     :                        %VAL( CNF_PVAL( IPRES ) ),
     :                        IERR, NERR, STATUS )
 
            ELSE IF ( ITYPE .EQ. '_REAL' ) THEN
               CALL VEC_SUBR( HASBAD, EL, %VAL( CNF_PVAL( IPIN ) ),
     :                        %VAL( CNF_PVAL( IPDAT( 1 ) ) ), 
     :                        %VAL( CNF_PVAL( IPRES ) ),
     :                        IERR, NERR, STATUS )
 
            ELSE IF ( ITYPE .EQ. '_WORD' ) THEN
               CALL VEC_SUBW( HASBAD, EL, %VAL( CNF_PVAL( IPIN ) ),
     :                        %VAL( CNF_PVAL( IPDAT( 1 ) ) ), 
     :                        %VAL( CNF_PVAL( IPRES ) ),
     :                        IERR, NERR, STATUS )
 
            ELSE IF ( ITYPE .EQ. '_UWORD' ) THEN
               CALL VEC_SUBUW( HASBAD, EL, %VAL( CNF_PVAL( IPIN ) ),
     :                         %VAL( CNF_PVAL( IPDAT( 1 ) ) ), 
     :                         %VAL( CNF_PVAL( IPRES ) ),
     :                         IERR, NERR, STATUS )
            END IF

*  Done with the input data array.
            CALL NDF_UNMAP( INNDF, 'DATA', STATUS )

         ELSE
            IPRES = IPDAT( 1 )
         END IF

*  Obtain workspace for the JAXIS collapsed array.
         CALL PSX_CALLOC( AREA, '_DOUBLE', IPCOL, STATUS )
         CALL PSX_CALLOC( AREA, '_INTEGER', IPWRK3, STATUS )

*  Derive the the rms of the residuals in the fitting ranges.
         IF ( ITYPE .EQ. '_BYTE' ) THEN
            CALL KPS1_MFRMB( JAXIS, NRANGE, RANGES, CLPRMS, DIMS, 
     :                       %VAL( CNF_PVAL( IPRES ) ),
     :                       %VAL( CNF_PVAL( IPCOL ) ), 
     :                       %VAL( CNF_PVAL( IPWRK3 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_UBYTE' ) THEN
            CALL KPS1_MFRMUB( JAXIS, NRANGE, RANGES, CLPRMS, DIMS, 
     :                        %VAL( CNF_PVAL( IPRES ) ),
     :                        %VAL( CNF_PVAL( IPCOL ) ), 
     :                        %VAL( CNF_PVAL( IPWRK3 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
            CALL KPS1_MFRMD( JAXIS, NRANGE, RANGES, CLPRMS, DIMS, 
     :                       %VAL( CNF_PVAL( IPRES ) ),
     :                       %VAL( CNF_PVAL( IPCOL ) ), 
     :                       %VAL( CNF_PVAL( IPWRK3 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_INTEGER' ) THEN
            CALL KPS1_MFRMI( JAXIS, NRANGE, RANGES, CLPRMS, DIMS, 
     :                       %VAL( CNF_PVAL( IPRES ) ),
     :                       %VAL( CNF_PVAL( IPCOL ) ), 
     :                       %VAL( CNF_PVAL( IPWRK3 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_REAL' ) THEN
            CALL KPS1_MFRMR( JAXIS, NRANGE, RANGES, CLPRMS, DIMS, 
     :                       %VAL( CNF_PVAL( IPRES ) ),
     :                       %VAL( CNF_PVAL( IPCOL ) ), 
     :                       %VAL( CNF_PVAL( IPWRK3 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_WORD' ) THEN
            CALL KPS1_MFRMW( JAXIS, NRANGE, RANGES, CLPRMS, DIMS, 
     :                       %VAL( CNF_PVAL( IPRES ) ),
     :                       %VAL( CNF_PVAL( IPCOL ) ), 
     :                       %VAL( CNF_PVAL( IPWRK3 ) ), STATUS )

         ELSE IF ( ITYPE .EQ. '_UWORD' ) THEN
            CALL KPS1_MFRMUW( JAXIS, NRANGE, RANGES, CLPRMS, DIMS, 
     :                        %VAL( CNF_PVAL( IPRES ) ),
     :                        %VAL( CNF_PVAL( IPCOL ) ), 
     :                        %VAL( CNF_PVAL( IPWRK3 ) ), STATUS )
         END IF

         CALL PSX_FREE( IPCOL, STATUS )
         CALL PSX_FREE( IPWRK3, STATUS )

*  Propagate the bad values to the output.  Recall that if the data 
*  were already detrended then the array supplied to and amended in
*  KPS1_MFRM is the output array.
         IF ( .NOT. SUBTRA ) THEN
            
            IF ( ITYPE .EQ. '_BYTE' ) THEN
               CALL KPG1_CPBDB( EL, %VAL( CNF_PVAL( IPDAT ) ), 
     :                          %VAL( CNF_PVAL( IPRES ) ), 
     :                          %VAL( CNF_PVAL( IPDAT( 1 ) ) ), STATUS )
            ELSE IF ( ITYPE .EQ. '_UBYTE' ) THEN
               CALL KPG1_CPBDUB( EL, %VAL( CNF_PVAL( IPDAT( 1 ) ) ), 
     :                           %VAL( CNF_PVAL( IPRES ) ), 
     :                           %VAL( CNF_PVAL( IPDAT( 1 ) ) ),
     :                           STATUS )
            ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
               CALL KPG1_CPBDD( EL, %VAL( CNF_PVAL( IPDAT( 1 ) ) ), 
     :                          %VAL( CNF_PVAL( IPRES ) ), 
     :                          %VAL( CNF_PVAL( IPDAT( 1 ) ) ), STATUS )
            ELSE IF ( ITYPE .EQ. '_INTEGER' ) THEN
               CALL KPG1_CPBDI( EL, %VAL( CNF_PVAL( IPDAT( 1 ) ) ), 
     :                          %VAL( CNF_PVAL( IPRES ) ), 
     :                          %VAL( CNF_PVAL( IPDAT( 1 ) ) ), STATUS )
            ELSE IF ( ITYPE .EQ. '_REAL' ) THEN
               CALL KPG1_CPBDR( EL, %VAL( CNF_PVAL( IPDAT( 1 ) ) ), 
     :                          %VAL( CNF_PVAL( IPRES ) ), 
     :                          %VAL( CNF_PVAL( IPDAT( 1 ) ) ), STATUS )
            ELSE IF ( ITYPE .EQ. '_WORD' ) THEN
               CALL KPG1_CPBDW( EL, %VAL( CNF_PVAL( IPDAT( 1 ) ) ), 
     :                          %VAL( CNF_PVAL( IPRES ) ), 
     :                          %VAL( CNF_PVAL( IPDAT( 1 ) ) ), STATUS )
            ELSE IF ( ITYPE .EQ. '_UWORD' ) THEN
               CALL KPG1_CPBDUW( EL, %VAL( CNF_PVAL( IPDAT( 1 ) ) ), 
     :                           %VAL( CNF_PVAL( IPRES ) ),
     :                           %VAL( CNF_PVAL( IPDAT( 1 ) ) ),
     :                           STATUS )
            END IF

*  Tidy.
            CALL PSX_FREE( IPRES, STATUS )
         END IF
      END IF

*  Obtain the output title and insert it into the result NDF.
      IF ( MODIN ) THEN
         CALL NDF_CINP( 'TITLE', INNDF, 'TITLE', STATUS )
      ELSE
         CALL NDF_CINP( 'TITLE', OUTNDF, 'TITLE', STATUS )
      END IF

*  Exit in error label, tidyup after this point.
 999  CONTINUE

*  End the NDF context.
      CALL NDF_END( STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

*  If an error occurred, then report context information.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'MFITTREND_ERR', 
     :                 'MFITTREND: Error determining trends',
     :                 STATUS )
      END IF

      END
