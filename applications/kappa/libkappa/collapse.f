      SUBROUTINE COLLAPSE( STATUS )
*+
*  Name:
*     COLLAPSE

*  Purpose:
*     Reduce the number of axes in an N-dimensional NDF by compressing it 
*     along a nominated axis.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL COLLAPSE( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application collapses a nominated axis of an N-dimensional NDF,
*     producing an output NDF with one fewer axes than the input NDF. A
*     specified range of axis values can be used instead of the whole axis 
*     (see parameters LOW and HIGH).
*
*     For each output pixel, all corresponding input pixel values between
*     the specified bounds of the the nominated axis to be collapsed are
*     combined together using either a mean or median estimator to
*     produce the output pixel value.
*
*     Possible uses include such things as collapsing a range of
*     wavelength planes in a 3-D RA/DEC/Wavelength cube to produce a
*     single 2-D RA/DEC image, or collapsing a range of slit positions in
*     a 2-D slit position/wavelength image to produce a 1-D wavelength
*     array

*  Usage:
*     collapse in out axis [low] [high] [estimator] [wlim]

*  ADAM Parameters:
*     AXIS = LITERAL (Read)
*        The axis along which to collapse the NDF. This can be specified
*        by its integer index within the current Frame of the input
*        NDF (in the range 1 to the number of axes in the current Frame),
*        or by its symbol string. A list of acceptable values is displayed
*        if an illegal value is supplied. If the axes of the current Frame
*        are not parallel to the NDF pixel axes, then the pixel axis which
*        is most nearly parallel to the specified current Frame axis will
*        be used.
*     ESTIMATOR = LITERAL (Read)
*        The method to use for estimating the output pixel values.  It
*        can be either "Mean" or "Median". ["Mean"]
*     HIGH = LITERAL (Read)
*        A value for the axis specified by parameter AXIS. For example,
*        if AXIS is 3 and the current Frame of the input NDF has axes
*        RA/DEC/Wavelength, then a wavelength value should be supplied.
*        If, on the other hand, the current Frame in the NDF was the PIXEL
*        Frame, then a pixel co-ordinate value would be required for the
*        third axis (note, the pixel with index I covers a range of pixel
*        co-ordinates from (I-1) to I). Together with parameter LOW, this 
*        parameter gives the range of axis values to be compressed. Note,
*        HIGH and LOW should not be equal since. If a null value (!) is 
*        supplied for either HIGH or LOW, the entire range of the axis 
*        is collapsed. [!]
*     IN  = NDF (Read)
*        The input NDF. 
*     LOW = LITERAL (Read)
*        A value for the axis specified by parameter AXIS. For example,
*        if AXIS is 3 and the current Frame of the input NDF has axes
*        RA/DEC/Wavelength, then a wavelength value should be supplied.
*        If, on the other hand, the current Frame in the NDF was the PIXEL
*        Frame, then a pixel co-ordinate value would be required for the
*        third axis (note, the pixel with index I covers a range of pixel
*        co-ordinates from (I-1) to I). Together with parameter HIGH, this 
*        parameter gives the range of axis values to be compressed. Note,
*        LOW and HIGH should not be equal since. If a null value (!) is 
*        supplied for either LOW or HIGH, the entire range of the axis 
*        is collapsed. [!]
*     OUT = NDF (Write)
*        The output NDF.
*     TITLE = LITERAL (Read)
*        Title for the output NDF structure.  A null value (!)
*        propagates the title from the input NDF to the output NDF. [!]
*     WLIM = _REAL (Read)
*        If the input NDF contains bad pixels, then this parameter
*        may be used to determine the number of good pixels which must
*        be present within the range of collapsed input pixels before a 
*        valid output pixel is generated. It can be used, for example, to 
*        prevent output pixels from being generated in regions where there 
*        are relatively few good pixels to contribute to the collapsed
*        result.
*
*        WLIM specifies the minimum fraction of good pixels which must
*        be present in order to generate a good output pixel. If this 
*        specified minimum fraction of good input pixels is not present, 
*        then a bad output pixel will result, otherwise an good output 
*        value will be calculated. The value of this parameter should lie 
*        between 0.0 and 1.0 (the actual number used will be rounded up if 
*        necessary to correspond to at least 1 pixel). [0.3]

*  Examples:
*     collapse cube slab lambda 4500 4550 
*        The current Frame in the input 3-dimensional NDF called cube has
*        axes with labels "RA", "DEC" and "Lambda", with the lambda axis
*        being parallel to the third pixel axis. The above command
*        extracts a slab of the input cube between wavelengths 4500 and
*        4550 Angstroms, and collapses this slab into a single
*        2-dimensional output NDF called slab with RA and DEC axes. Each
*        pixel in the output NDF is the mean of the corresponding input
*        pixels with wavelengths between 4500 and 4550 Angstroms.
*     collapse cube slab 3 4500 4550 
*        The same as above except the axis to collapse along is specified
*        by index (3) rather than label (lambda).
*     collapse cube slab 3 101.0 134.0
*        This is the same as the above examples, except that the current
*        Frame in the input NDF has been set to the PIXEL Frame (using
*        WCSFRAME), and so the high and low axis values are specified in 
*        pixel co-ordinates instead of Angstroms. Note the difference 
*        between floating point pixel co-ordinates, and integer pixel 
*        indices (for instance the pixel with index 10 extends from pixel
*        co-ordinate 9.0 to pixel co-ordinate 10.0).
*     collapse cube slab 3 low=99.0 high=100.0
*        This is the same as the above examples, except that a single
*        pixel plane in the cube (pixel 100) is used to create the output 
*        NDF. Following the usual definition of pixel co-ordinates, pixel 
*        100 extends from pixel co-ordinate 99.0 to pixel co-ordinate
*        100.0. So the given HIGH and LOW values encompass the single
*        pixel plane at pixel 100.

*  Notes:
*     -  The collapse is always performed along one of the pixel axes,
*     even if the current Frame in the input NDF is not the PIXEL Frame.
*     Special care should be taken if the current Frame axes are not
*     parallel to the pixel axes. The algorithm used to choose the pixel axis 
*     and the range of values to collapse along this pixel axis proceeds as 
*     follows: 
*     
*     The current Frame co-ordinates of the central pixel in the input
*     NDF are determined (or some other point if the co-ordinates of the
*     central pixel are undefined). Two current Frame positions are then
*     generated by substituting in turn into this central position each
*     of the HIGH and LOW values for the current Frame axis specified by
*     parameter AXIS. These two current Frame positions are transformed
*     into pixel co-ordinates, and the projections of the vector joining
*     these two pixel positions onto the pixel axes are found. The pixel
*     axis with the largest projection is selected as the collapse axis,
*     and the two end points of the projection define the range of axis
*     values to collapse.

*  Related Applications:
*     KAPPA: WCSFRAME, COMPAVE, COMPICK, COMPADD.

*  Implementation Status:
*     -  This routine correctly processes the AXIS, DATA, VARIANCE,
*     LABEL, TITLE, UNITS, WCS and HISTORY components of the input NDF and
*     propagates all extensions.  QUALITY is not propagated.
*     -  Processing of bad pixels and automatic quality masking are
*     supported.
*     -  All non-complex numeric data types can be handled.
*     -  Any number of NDF dimensions is supported.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     31-AUG-2000 (DSB):
*        Original version.
*     {enter_further_changes}

*  Bugs:
*     {note_new_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE            ! No default typing allowed

*  Global Constants:
      INCLUDE  'SAE_PAR'       ! Global SSE definitions
      INCLUDE  'PAR_ERR'       ! Parameter-system errors
      INCLUDE  'NDF_PAR'       ! NDF_ public constants
      INCLUDE  'DAT_PAR'       ! HDS public constants
      INCLUDE  'AST_PAR'       ! AST constants and functions

*  Status:
      INTEGER STATUS

*  External References:
      INTEGER KPG1_FLOOR       ! Most positive integer .LE. a given real
      INTEGER KPG1_CEIL        ! Most negative integer .GE. a given real

*  Local Variables:
      CHARACTER COMP*13        ! List of components to process
      CHARACTER DTYPE*( NDF__SZFTP ) ! Numeric type for output arrays
      CHARACTER ESTIM*6        ! Method to use to estimate collapsed values
      CHARACTER ITYPE*( NDF__SZTYP ) ! Numeric type for processing
      CHARACTER LOC1*(DAT__SZLOC)! Locator to the whole NDF
      CHARACTER LOC2*(DAT__SZLOC)! Locator to NDF AXIS array
      CHARACTER LOC3*(DAT__SZLOC)! Locator to a copy of the original AXIS array
      CHARACTER LOC4*(DAT__SZLOC)! Locator to a cell of the new AXIS array
      CHARACTER LOC5*(DAT__SZLOC)! Locator to a cell of the old AXIS array
      CHARACTER LOC6*(DAT__SZLOC)! Locator to a component of the old cell
      CHARACTER NAME*(DAT__SZNAM)! The component name
      CHARACTER TTLC*255       ! Title of original current Frame
      DOUBLE PRECISION AXHIGH  ! High bound of collapse axis in current Frame
      DOUBLE PRECISION AXLOW   ! Low bound of collapse axis in current Frame
      DOUBLE PRECISION CPOS( 2, NDF__MXDIM )! Two current Frame positions
      DOUBLE PRECISION CURPOS( NDF__MXDIM ) ! A valid current Frame position
      DOUBLE PRECISION DLBND( NDF__MXDIM )  ! Lower bounds in pixel co-ords
      DOUBLE PRECISION DUBND( NDF__MXDIM )  ! Upper bounds in pixel co-ords
      DOUBLE PRECISION PIXPOS( NDF__MXDIM ) ! A valid pixel Frame position
      DOUBLE PRECISION PPOS( 2, NDF__MXDIM )! Two pixel Frame positions
      DOUBLE PRECISION PRJ     ! Vector length projected onto a pixel axis
      DOUBLE PRECISION PRJMAX  ! Maximum vector length projected onto an axis
      INTEGER AXES( NDF__MXDIM )! A list of axis indices
      INTEGER BFRM             ! Original Base Frame pointer
      INTEGER CFRM             ! Original Current Frame pointer
      INTEGER EL1              ! Number of elements in an input mapped array
      INTEGER EL2              ! Number of elements in an output mapped array
      INTEGER I                ! Loop count
      INTEGER IAXIS            ! Index of collapse axis within current Frame
      INTEGER ICURR            ! Index of current Frame
      INTEGER INDF1            ! Input NDF identifier
      INTEGER INDF2            ! Output NDF identifier
      INTEGER INEW             ! Index of new Frame
      INTEGER IOLD             ! Index of old Frame
      INTEGER IPIN( 2 )        ! Pointers to mapped input arrays
      INTEGER IPIX             ! Index of PIXEL Frame within WCS FrameSet
      INTEGER IPOUT( 2 )       ! Pointers to mapped output arrays
      INTEGER IPW1             ! Pointer to first work array
      INTEGER IPW2             ! Pointer to second work array
      INTEGER IWCS             ! WCS FrameSet pointer
      INTEGER J                ! Loop count
      INTEGER JAXIS            ! Index of collapse axis within PIXEL Frame
      INTEGER JHI              ! High pixel index for collapse axis
      INTEGER JLO              ! Low pixel index for collapse axis
      INTEGER LBND( NDF__MXDIM )! Lower pixel index bounds of the input NDF
      INTEGER LBNDO( NDF__MXDIM )! Lower pixel index bounds of the output NDF
      INTEGER MAP              ! PIXEL Frame to Current Frame Mapping pointer
      INTEGER NAXC             ! Original number of current Frame axes
      INTEGER NBFRM            ! New Base Frame pointer
      INTEGER NCFRM            ! New Current Frame pointer
      INTEGER NCOMP              ! No. of components within cell of AXIS array
      INTEGER NDIM             ! No. of pixel axes in input NDF
      INTEGER NDIMO            ! No. of pixel axes in output NDF
      INTEGER NVAL             ! Number of values obtained (1)
      INTEGER PMAP             ! Pointer to PermMap going from old to new Frame
      INTEGER UBND( NDF__MXDIM )! Upper pixel index bounds of the input NDF
      INTEGER UBNDO( NDF__MXDIM )! Upper pixel index bounds of the output NDF
      LOGICAL GOTAX              ! Does the NDF have an AXIS component?
      LOGICAL USEALL           ! Use the entire collapse pixel axis?
      LOGICAL VAR              ! Process variances?
      REAL WLIM                ! Value of WLIM parameter

*.

*  Check the global status.
      IF( STATUS .NE. SAI__OK ) RETURN

*  Start an AST context.
      CALL AST_BEGIN( STATUS )

*  Start an NDF context.
      CALL NDF_BEGIN

*  Obtain the input NDF.
      CALL LPG_ASSOC( 'IN', 'READ', INDF1, STATUS )

*  Get the bounds of the NDF.
      CALL NDF_BOUND( INDF1, NDF__MXDIM, LBND, UBND, NDIM, STATUS )

*  Get the WCS FrameSet from the NDF.
      CALL KPG1_GTWCS( INDF1, IWCS, STATUS )

*  Extract the current and base Frames, and get the number of axes in the
*  current Frame, and its title.
      CFRM = AST_GETFRAME( IWCS, AST__CURRENT, STATUS )
      BFRM = AST_GETFRAME( IWCS, AST__BASE, STATUS )
      NAXC = AST_GETI( CFRM, 'NAXES', STATUS )
      TTLC = AST_GETC( CFRM, 'TITLE', STATUS )

*  Find the index of the PIXEL Frame.
      CALL KPG1_ASFFR( IWCS, 'PIXEL', IPIX, STATUS )

*  Extract the Mapping from PIXEL Frame to Current Frame. 
      MAP = AST_GETMAPPING( IWCS, IPIX, AST__CURRENT, STATUS )

*  Report an error if the Mapping is not defined in either direction.
      IF( .NOT. AST_GETL( MAP, 'TRANINVERSE', STATUS ) .AND.
     :    STATUS .EQ. SAI__OK ) THEN
         STATUS = SAI__ERROR
         CALL NDF_MSG( 'NDF', INDF1 )
         CALL MSG_SETC( 'T', TTLC )
         CALL ERR_REP( 'COLLAPSE_ERR1', 'The transformation from the '//
     :                 'current co-ordinate Frame of ''^NDF'' '//
     :                 '(^T) to pixel co-ordinates is not defined.', 
     :                 STATUS )

      ELSE IF( .NOT. AST_GETL( MAP, 'TRANFORWARD', STATUS ) .AND.
     :         STATUS .EQ. SAI__OK ) THEN
         STATUS = SAI__ERROR
         CALL NDF_MSG( 'NDF', INDF1 )
         CALL MSG_SETC( 'T', TTLC )
         CALL ERR_REP( 'COLLAPSE_ERR2', 'The transformation from '//
     :                 'pixel co-ordinates to the current co-ordinate'//
     :                 ' Frame of ''^NDF'' (^T) is not defined.', 
     :                 STATUS )
      END IF

*  Get the index of the current Frame axis defining the collapse direction. 
*  Use the last axis as the dynamic default.
      IAXIS = NAXC
      CALL KPG1_GTAXI( 'AXIS', CFRM, 1, IAXIS, STATUS )

*  Abort if an error has occurred.
      IF( STATUS .NE. SAI__OK ) GO TO 999  

*  Get the bounding values for the specified current Frame axis defining the 
*  height of the slab to be collapsed.
      AXLOW = AST__BAD
      CALL KPG1_GTAXV( 'LOW', 1, .TRUE., CFRM, IAXIS, AXLOW, NVAL, 
     :                 STATUS )

      AXHIGH = AST__BAD
      CALL KPG1_GTAXV( 'HIGH', 1, .TRUE., CFRM, IAXIS, AXHIGH, NVAL, 
     :                 STATUS )

*  If a null value was supplied for either of these parameters, annul the 
*  error and set a flag indicating that the whole axis should be used.
      IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         USEALL = .TRUE.
      ELSE
         USEALL = .FALSE.
      END IF

*  Find an arbitrary position within the NDF which has valid current Frame 
*  co-ordinates. Both pixel and current Frame co-ordinates for this
*  position are returned.
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

*  If no high and low values for the collapse axis were supplied, modify
*  the collapse axis values in these positions by an arbitrary amount.
      IF( USEALL ) THEN
         IF( CURPOS( IAXIS ) .NE. 0.0 ) THEN
            CPOS( 1, IAXIS ) = 0.99*CURPOS( IAXIS )
            CPOS( 2, IAXIS ) = 1.01*CURPOS( IAXIS )
         ELSE
            CPOS( 1, IAXIS ) = CURPOS( IAXIS ) + 1.0D-4
            CPOS( 2, IAXIS ) = CURPOS( IAXIS ) - 1.0D-4
         END IF

*  If high and low values for the collapse axis were supplied, substitute
*  these into these positions.
      ELSE
         CPOS( 1, IAXIS ) = AXHIGH
         CPOS( 2, IAXIS ) = AXLOW
      END IF

*  Transform these two positions into pixel co-ordinates.
      CALL AST_TRANN( MAP, 2, NAXC, 2, CPOS, .FALSE., NDIM, 2, PPOS,
     :                STATUS ) 

*  Find the pixel axis with the largest projection of the vector joining 
*  these two pixel positions. The collapse will occurr along this pixel
*  axis. Report an error if the positions do not have valid pixel co-ordinates.
      PRJMAX = -1.0
      DO I = 1, NDIM
         IF( PPOS( 1, I ) .NE. AST__BAD .AND.
     :       PPOS( 2, I ) .NE. AST__BAD ) THEN

            PRJ = ABS( PPOS( 1, I ) - PPOS( 2, I ) )
            IF( PRJ .GT. PRJMAX ) THEN
               JAXIS = I
               PRJMAX = PRJ
            END IF

         ELSE IF( STATUS .EQ. SAI__OK ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'COLLAPSE_ERR3', 'The WCS information is '//
     :                    'too complex (cannot find two valid pixel '//
     :                    'positions).', STATUS )
            GO TO 999
         END IF

      END DO

*  Choose the pixel index bounds of the slab to be collapsed on the collapse 
*  pixel axis. If no axis limits supplied, use the upper and lower bounds.
      IF( USEALL ) THEN
         JLO = LBND( JAXIS )
         JHI = UBND( JAXIS )

*  If limits were supplied...
      ELSE

*  Find the projection of the two test points onto the collapse axis.
         JLO = KPG1_FLOOR( REAL( MIN( PPOS( 1, JAXIS ), 
     :                                PPOS( 2, JAXIS ) ) ) ) + 1
         JHI = KPG1_CEIL( REAL( MAX( PPOS( 1, JAXIS ), 
     :                               PPOS( 2, JAXIS ) ) ) )

*  Ensure these are within the bounds of the pixel axis.
         JLO = MAX( LBND( JAXIS ), JLO )
         JHI = MIN( UBND( JAXIS ), JHI )

*  Report an error if there is no intersection.
         IF( JLO .GT. JHI .AND. STATUS .EQ. SAI__OK ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'COLLAPSE_ERR4', 'The axis range to '//
     :                    'collapse covers zero pixels (are the '//
     :                    'HIGH and LOW parameter values equal '//
     :                    'or outside the bounds of the NDF?)', 
     :                    STATUS )
            GO TO 999
         END IF

      END IF

*  Tell the user the range of pixels being collapsed.
      CALL MSG_SETI( 'I', JAXIS )
      CALL MSG_SETI( 'L', JLO )
      CALL MSG_SETI( 'H', JHI )
      CALL MSG_OUT( 'COLLAPSE_MSG1', '   Collapsing pixel axis ^I '//
     :             'from pixel ^L to pixel ^H inclusive...', STATUS )
      CALL MSG_BLANK( ' ', STATUS )

*  Create the output NDF by propagation from the input NDF. This results
*  in history, etc, being passed on. The shape and dimensionality will be
*  wrong but this will be corrected later.
      CALL LPG_PROP( INDF1, 'Axis,Units', 'OUT', INDF2, STATUS )

*  Set the title of the output NDF.
      CALL KPG1_CCPRO( 'TITLE', 'TITLE', INDF1, INDF2, STATUS )

*  See if the input NDF has a Variance component.
      CALL NDF_STATE( INDF1, 'VARIANCE', VAR, STATUS )

*  Store a list of components to be accessed.
      IF( VAR ) THEN
         COMP = 'DATA,VARIANCE'
      ELSE
         COMP = 'DATA'
      END IF

*  Determine the numeric type to be used for processing the input
*  data and variance (if any) arrays.  Since the subroutines that
*  perform the collpase need the data and variance arrays in the same
*  data type, the component list is used.  This application supports
*  single- and double-precision floating-point processing.
      CALL NDF_MTYPE( '_REAL,_DOUBLE', INDF1, INDF2, COMP, ITYPE, DTYPE,
     :                STATUS )

*  The output NDF will have one fewer axes than the input NDF.
      NDIMO = NDIM - 1

*  For each axis I in the final output NDF, find the corresponding axis
*  in the input NDF.
      DO I = 1, NDIMO
         IF( I .LT. JAXIS ) THEN
            AXES( I ) = I
         ELSE
            AXES( I ) = I + 1
         END IF
      END DO

*  Find the pixel bounds of the NDF after axis permutation.
      DO I = 1, NDIMO
         LBNDO( I ) = LBND( AXES( I ) )
         UBNDO( I ) = UBND( AXES( I ) )
      END DO

*  The shape and size of the output NDF created above will be wrong, so
*  we need to correct it by removing the collapse axis. This is easy if
*  it is the final axis (we would just use NDF_SBND with specifying NDIM-1 
*  axes), but is not so easy if the collapse axis is not the final axis.
*  In this case, we do th following:
*    1) - Save copies of an AXIS structures in the output NDF (because
*         the following step will change their lengths to match the new
*         bounds).
*    2) - Change the bounds and dimensionality of the NDF to the
*         appropriate values.
*    3) - Restore the saved AXIS structures, permuting them so that they 
*         apply to the correct axis.
*    4) - Adjust the WCS FrameSet to pick the required axis form the
*         original Base Frame.

*  First see if the AXIS component is defined.
      CALL NDF_STATE( INDF2, 'AXIS', GOTAX, STATUS )

*  If so, we need to save copies of the AXIS structures.
      IF( GOTAX ) THEN

*  Get an HDS locator to the NDF structure,
         CALL NDF_LOC( INDF2, 'UPDATE', LOC1, STATUS )

*  Get a locator for the AXIS component.
         CALL DAT_FIND( LOC1, 'AXIS', LOC2, STATUS )

*  Take a copy of the AXIS component and call it OLDAXIS.
         CALL DAT_COPY( LOC2, LOC1, 'OLDAXIS', STATUS ) 

*  Get a locator for OLDAXIS.
         CALL DAT_FIND( LOC1, 'OLDAXIS', LOC3, STATUS )

      END IF

*  Set the output NDF bounds to the required values. This will change the
*  lengths of the current AXIS arrays (but we have a copy of the
*  originals in OLDAXIS), and reduce the dimensionality by one.
      CALL NDF_SBND( NDIMO, LBNDO, UBNDO, INDF2, STATUS ) 

*  We now re-instate any AXIS structures, in their new order.
      IF( GOTAX ) THEN

*  Promote the NDF locator to a primary locator so that the HDS
*  container file is not closed when the NDF identifier is annulled.
         CALL DAT_PRMRY( .TRUE., LOC1, .TRUE., STATUS ) 

*  The DATA array of the output NDF will not yet be in a defined state. 
*  This would result in NDF_ANNUL reporting an error, so we temporarily
*  map the DATA array (which puts it into a defined state) to prevent this.
         CALL NDF_MAP( INDF2, 'DATA', ITYPE, 'WRITE', IPOUT( 1 ), EL2, 
     :                 STATUS ) 

*  Annul the supplied NDF identifier so that we can change the contents of
*  the NDF using HDS, without getting out of step with the NDFs libraries
*  description of the NDF. 
         CALL NDF_ANNUL( INDF2, STATUS )

*  Loop round each cell in the returned AXIS structure.
         DO I = 1, NDIMO

*  Get a locator to this cell in the NDFs AXIS array.
            CALL DAT_CELL( LOC2, 1, I, LOC4, STATUS ) 

*  Empty it of any components
            CALL DAT_NCOMP( LOC4, NCOMP, STATUS )
            DO J = NCOMP, 1, -1
               CALL DAT_INDEX( LOC4, J, LOC5, STATUS )
               CALL DAT_NAME( LOC5, NAME, STATUS )
               CALL DAT_ANNUL( LOC5, STATUS )
               CALL DAT_ERASE( LOC4, NAME, STATUS )
               IF( STATUS .NE. SAI__OK ) GO TO 999
            END DO

*  Get a locator to the corresponding cell in the OLDAXIS array.
            CALL DAT_CELL( LOC3, 1, AXES( I ), LOC5, STATUS ) 

*  We now copy all the components of the OLDAXIS cell into the AXIS cell. Find 
*  the number of components, and loop round them.
            CALL DAT_NCOMP( LOC5, NCOMP, STATUS )
            DO J = NCOMP, 1, -1

*  Get a locator to this component in the original OLDAXIS cell.
               CALL DAT_INDEX( LOC5, J, LOC6, STATUS )

*  Get its name.
               CALL DAT_NAME( LOC6, NAME, STATUS )

*  Copy it into the new AXIS structure.
               CALL DAT_COPY( LOC6, LOC4, NAME, STATUS )           

*  Annul the locators.
               CALL DAT_ANNUL( LOC6, STATUS )

*  Abort if an error has occurred.
               IF( STATUS .NE. SAI__OK ) GO TO 999

            END DO

*  Annul the locators.
            CALL DAT_ANNUL( LOC4, STATUS )
            CALL DAT_ANNUL( LOC5, STATUS )

         END DO

*  Annul the locator to the OLDAXIS structure and then erase the object.
         CALL DAT_ANNUL( LOC3, STATUS )
         CALL DAT_ERASE( LOC1, 'OLDAXIS', STATUS ) 

*  Annul the AXIS array locator.
         CALL DAT_ANNUL( LOC2, STATUS )

*  Import the modified NDF back into the NDF system.
         CALL NDF_FIND( LOC1, ' ', INDF2, STATUS ) 

*  Annul the NDF locator.
         CALL DAT_ANNUL( LOC1, STATUS )

      END IF

*  Map the full input, and output data and (if needed) variance arrays.
      CALL NDF_MAP( INDF1, COMP, ITYPE, 'READ', IPIN, EL1, STATUS )
      CALL NDF_MAP( INDF2, COMP, ITYPE, 'WRITE', IPOUT, EL2, STATUS )

*  We now store an appropriate WCS FrameSet in the output NDF. This is a
*  copy of the input NDFs WCS FrameSet but with the current and Base Frames
*  modified to remove the collapse axis. Create a new Frame by picking these 
*  axes from the original Base Frame. A PermMap is also created which goes 
*  from the original Base Frame to the new Base Frame.
      NBFRM = AST_PICKAXES( BFRM, NDIMO, AXES, PMAP, STATUS )

*  Now add this new Frame into the FrameSet, using the PermMap created
*  above to connect it to the origial Base Frame. This will make modify
*  the current Frame, so note the index of the current Frame first, and
*  re-instate it afterwards, remembering the index of the new Frame.
      ICURR = AST_GETI( IWCS, 'CURRENT', STATUS )
      CALL AST_ADDFRAME( IWCS, AST__BASE, PMAP, NBFRM, STATUS )       
      INEW = AST_GETI( IWCS, 'CURRENT', STATUS )
      CALL AST_SETI( IWCS, 'CURRENT', ICURR, STATUS )

*  Make the new Frame the Base Frame and remove the original Base Frame 
*  since it is no longer needed.
      IOLD = AST_GETI( IWCS, 'BASE', STATUS )
      CALL AST_SETI( IWCS, 'BASE', INEW, STATUS )
      CALL AST_REMOVEFRAME( IWCS, IOLD, STATUS )

*  We now need to modify the current Frame similarly to remove the collapse 
*  axis.
      DO I = 1, NAXC - 1
         IF( I .LT. IAXIS ) THEN
            AXES( I ) = I
         ELSE
            AXES( I ) = I + 1
         END IF
      END DO

      NCFRM = AST_PICKAXES( CFRM, NAXC - 1, AXES, PMAP, STATUS )

      IOLD = AST_GETI( IWCS, 'CURRENT', STATUS )
      CALL AST_ADDFRAME( IWCS, AST__CURRENT, PMAP, NCFRM, STATUS )       
      CALL AST_REMOVEFRAME( IWCS, IOLD, STATUS )

*  Save this WCS Frameet in the output NDF.
      CALL NDF_PTWCS( IWCS, INDF2, STATUS )      

*  Get the ESTIMATOR and WLIM parameters.
      CALL PAR_CHOIC( 'ESTIMATOR', 'Mean', 'Mean,Median', .FALSE.,
     :                ESTIM, STATUS )
      CALL PAR_GDR0R( 'WLIM', 0.3, 0.0, 1.0, .FALSE., WLIM, STATUS )

*  Allocate work space.
      CALL PSX_CALLOC( EL2*( JHI - JLO + 1 ), ITYPE, IPW1, STATUS )
      IF( VAR ) THEN
         CALL PSX_CALLOC( EL2*( JHI - JLO + 1 ), ITYPE, IPW2, STATUS )
      ELSE
         IPW2 = IPW1
      END IF  

*  Now do the work, using a routine appropriate to the numeric type.
      IF ( ITYPE .EQ. '_REAL' ) THEN
         CALL KPS1_CLPSR( JAXIS, JLO, JHI, VAR, ESTIM, WLIM, EL2, NDIM, 
     :                    LBND, UBND, %VAL( IPIN( 1 ) ), 
     :                    %VAL( IPIN( 2 ) ), NDIMO, LBNDO, UBNDO, 
     :                    %VAL( IPOUT( 1 ) ), %VAL( IPOUT( 2 ) ), 
     :                    %VAL( IPW1 ), %VAL( IPW2 ), STATUS )

      ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
         CALL KPS1_CLPSD( JAXIS, JLO, JHI, VAR, ESTIM, WLIM, EL2, NDIM, 
     :                    LBND, UBND, %VAL( IPIN( 1 ) ), 
     :                    %VAL( IPIN( 2 ) ), NDIMO, LBNDO, UBNDO, 
     :                    %VAL( IPOUT( 1 ) ), %VAL( IPOUT( 2 ) ), 
     :                    %VAL( IPW1 ), %VAL( IPW2 ), STATUS )

      ELSE IF( STATUS .EQ. SAI__OK ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETC( 'T', ITYPE )
         CALL ERR_REP( 'COLLAPSE_ERR5', 'COLLAPSE: Unsupported data '//
     :                 'type ^T (programming error).', STATUS )
      END IF

*  Free the work space.
      CALL PSX_FREE( IPW1, STATUS )
      IF( VAR ) CALL PSX_FREE( IPW2, STATUS )

*  Come here if something has gone wrong.
  999 CONTINUE

*  End the NDF context.
      CALL NDF_END( STATUS )

*  End the AST context.
      CALL AST_BEGIN( STATUS )

*  Report a contextual message if anything went wrong.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'COLLAPSE_ERR6', 'COLLAPSE: Unable to collapse'//
     :                  ' an NDF along one axis.', STATUS )
      END IF

      END
