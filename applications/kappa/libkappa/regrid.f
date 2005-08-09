      SUBROUTINE REGRID( STATUS )
*+
*  Name:
*     REGRID

*  Purpose:
*     Applies a geometrical transformation to an NDF.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL REGRID( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application uses a specified Mapping to re-grid the pixel
*     positions in an NDF. The specified Mapping should transform pixel 
*     co-ordinates in the input NDF into the corresponding pixel 
*     co-ordinates in the output NDF. 
*
*     By default, the bounds of the output pixel grid are chosen so that
*     they just encompasses all the transformed input data, but they can
*     be set explicitly using parameters LBOUND and UBOUND.
*
*     Two algorithms are available for determining the output pixel
*     values: resampling and rebinning (the method used is determined by
*     the REBIN parameter). The resampling algorithm steps through every
*     pixel in the output image, sampling the input image at the corresponding 
*     position and storing the sampled input value in the output pixel.
*     The method used for sampling the input image is determined by the 
*     METHOD parameter. The rebinning algorithm steps through every pixel in 
*     the input image, dividing the input pixel value up between a group of 
*     neighbouring output pixels. The way in which the input sample is
*     divided up between the output pixels is determined by the METHOD
*     parameter.
*
*     The two algorithms behaviour quite differently if the transformation 
*     from input to output includes any significant change of scale. In
*     general, resampling will not alter the pixel values associated with
*     a source, even if the pixel size changes. On the other hand, the 
*     rebinning algorithm will change the pixel values in order to
*     correct for a change in pixel size. Thus, rebinning conserves the
*     total data value within a given region where as resampling does not.
*    
*     Resampling is appropriate if the input image represents the spatial
*     density of some physical value (e.g. surface brightness) because the 
*     output image will have the same normalisation as the input image. But
*     rebinning is probably more appropriarte if the image measures (for
*     instance) flux per pixel, since rebinning takes account of the
*     change in pixel size.
*  
*     Another difference is that resampling guarantees to fill the output
*     image with good pixel values (assuming the input image is filled with
*     good input pixel values), whereas holes can be left by the rebinning 
*     algorithm if the output image has smaller pixels than the input image.
*     Such holes occur at output pixels which receive no contributions
*     from any input pixels, and will be filled with the value zero in
*     the output image. If this problem occurs the solution is probably
*     to change the width of the pixel spreading function by assigning
*     a larger value to PARAMS(1) and/or PARAMS(2) (depending on the
*     specific METHOD value being used).
*
*     The Mapping to use can be supplied in several different ways (see
*     parameter MAPPING). 

*  Usage:
*     regrid in out [method]

*  ADAM Parameters:
*     IN = NDF (Read)
*        The NDF to be transformed.
*     LBOUND( ) = _INTEGER (Read)
*        The lower pixel-index bounds of the output NDF.  The number of
*        values must be equal to the number of dimensions in the output 
*        NDF.  If a null value is supplied, default bounds will be used 
*        which are just low enough to fit in all the transformed pixels 
*        of the input NDF. [!]
*     MAPPING = FILENAME (Read)
*        The name of a file containing the Mapping to be used, or null (!)
*        if the input NDF is to be mapped into its own current Frame. If a 
*        file is supplied, the forward direction of the Mapping should 
*        transform pixel co-ordinates in the input NDF into the 
*        corresponding pixel co-ordinates in the output NDF. The file 
*        may be:
*
*        - A text file containing a textual representation of the AST Mapping 
*        to use. Such files can be created by WCSADD.
*
*        - A text file containing a textual representation of an AST
*        FrameSet. If the FrameSet contains a Frame with Domain PIXEL,
*        then the Mapping used is the Mapping from the PIXEL Frame to the
*        current Frame. If there is no PIXEL Frame in the FrameSet, then
*        the Mapping used is the Mapping from the base Frame to the Current 
*        Frame.
*
*        - A FITS file. The Mapping used is the Mapping from the FITS
*        pixel co-ordinates in which the centre of the bottom left pixel
*        is at co-ordinates (1,1), to the co-ordinate system represented 
*        by the primary WCS headers, CRVAL, CRPIX, etc.
*
*        - An NDF. The Mapping used is the Mapping from the PIXEL Frame
*        to the Current Frame of its WCS FrameSet.
*
*        If a null (!) value is supplied, the Mapping used is the Mapping 
*        from pixel co-ordinates in the input NDF to the current Frame in 
*        the input NDF. The output NDF will then have pixel co-ordinates 
*        which match the co-ordinates of the current Frame of the input 
*        NDF (apart from possible additional scalings as specified by the
*        SCALE parameter).
*     METHOD = LITERAL (Read)
*        The method to use when sampling the input pixel values (if
*        resampling), or dividing an input pixel value up between a group 
*        of neighbouring output pixels (if rebinning). For details 
*        on these schemes, see the descriptions of routines AST_RESAMPLEx
*        and AST_REBINx in SUN/210. METHOD can take the following 
*        values:
*
*        - "Bilinear" -- When resampling, the output pixel values are 
*        calculated by bi-linear interpolation among the four nearest pixels 
*        values in the input NDF. When rebinning, the input pixel value
*        is divided up bi-linearly between the four nearest output pixels.
*        Produces smoother output NDFs than the nearest neighbour scheme, but 
*        is marginally slower.
*
*        - "Nearest" -- When resampling, the output pixel values are assigned 
*        the value  of the single nearest input pixel. When rebinning,
*        the input pixel value is assigned completely to the single
*        nearest output pixel.
*
*        - "Sinc" -- use the sinc(pi*x) kernel, where x is the pixel
*        offset from the interpolation point (resampling) or transformed
*        input pixel centre (rebinning), and sinc(z)=sin(z)/z. Use of this 
*        scheme is not recommended.
*
*        - "SincSinc" -- uses the sinc(pi*x)sinc(k*pi*x) kernel. A
*        valuable general-purpose scheme, intermediate in its visual effect 
*        on NDFs between the bilinear and nearest neighbour schemes. 
*         
*        - "SincCos" -- uses the sinc(pi*x)cos(k*pi*x) kernel. Gives
*        similar results to the sincsinc scheme.
*
*        - "SincGauss" -- uses the sinc(pi*x)exp(-k*x*x) kernel. Good 
*        results can be obtained by matching the FWHM of the
*        envelope function to the point spread function of the
*        input data (see parameter PARAMS).
*
*        - "Gauss" -- uses the exp(-k*x*x) kernel. This option is only 
*        available when rebinning (i.e. if REBIN is set to a TRUE value).
*        The FWHM of the Gaussian is given by parameter PARAMS(2), and
*        the point at which to truncate the Gaussian to zero is given by 
*        parameter PARAMS(1).
*
*        All methods propagate variances from input to output, but the
*        variance estimates produced by these schemes other than
*        nearest neighbour need to be treated with care since the spatial 
*        smoothing produced by these methods introduces 
*        correlations in the variance estimates. Also, the degree of 
*        smoothing produced varies across the NDF. This is because a 
*        sample taken at a pixel centre will have no contributions from the 
*        neighbouring pixels, whereas a sample taken at the corner of a 
*        pixel will have equal contributions from all four neighbouring 
*        pixels, resulting in greater smoothing and lower noise. This 
*        effect can produce complex Moire patterns in the output 
*        variance estimates, resulting from the interference of the 
*        spatial frequencies in the sample positions and in the pixel 
*        centre positions. For these reasons, if you want to use the 
*        output variances, you are generally safer using nearest neighbour
*        interpolation. [current value]
*     OUT = NDF (Write)
*        The transformed NDF.
*     PARAMS( 2 ) = _DOUBLE (Read)
*        An optional array which consists of additional parameters
*        required by the Sinc, SincSinc, SincCos, SincGauss and Gauss
*        methods.
*
*        PARAMS( 1 ) is required by all the above schemes.
*        It is used to specify how many pixels are to contribute to the 
*        interpolated result on either side of the interpolation or binning 
*        point in each dimension. Typically, a value of 2 is appropriate and 
*        the minimum allowed value is 1 ( i.e. one pixel on each side ). A 
*        value of zero or less indicates that a suitable number of pixels 
*        should be calculated automatically. [0]
*
*        PARAMS( 2 ) is required only by the Gauss, SincSinc, SincCos, and 
*        SincGauss schemes. For the SincSinc and SincCos 
*        schemes, it specifies the number of pixels at which the envelope
*        of the function goes to zero. The minimum value is 1.0, and the
*        run-time default value is 2.0. For the Gauss and SincGauss scheme, it
*        specifies the full-width at half-maximum (FWHM) of the Gaussian 
*        envelope. The minimum value is 0.1, and the run-time default is
*        1.0. On astronomical NDFs and spectra, good results are often 
*        obtained by approximately matching the FWHM of the envelope 
*        function, given by PARAMS(2), to the point spread function of the 
*        input data. []
*     REBIN = LOGICAL_ (Read)
*        Determines the algorithm used to calculate the output pixel
*        values. If a TRUE value is given, a rebinning algorithm is used.
*        Otherwise, a resampling algorithm is used [current value]
*     SCALE( ) = _DOUBLE (Read)
*        Axis scaling factors which are used to modify the supplied Mapping.
*        If the number of supplied values is less than the number of output
*        axes associated with the Mapping, the final supplied value is
*        duplicated for the missing axes. In effect, transformed input 
*        co-ordinate axis values would be multiplied by these factors to 
*        obtain the corresponding output pixel co-ordinates. If a null (!) 
*        value is supplied for SCALE, then default values are used which 
*        depends on the value of parameter MAPPING. If a null value is 
*        supplied for MAPPING then the default scaling factors are chosen 
*        so that pixels retain their original size (very roughly) after
*        transformation. If as non-null value is supplied for MAPPING then 
*        the default scaling factor used is 1.0 for each axis (i.e. no 
*        scaling). [!]
*     TITLE = LITERAL (Read)
*        A Title for the output NDF structure.  A null value (!)
*        propagates the title from the input NDF to the output NDF. [!]
*     TOL = _DOUBLE (Read)
*        The maximum tolerable geometrical distortion which may be
*        introduced as a result of approximating non-linear Mappings 
*        by a set of piece-wise linear transforms.  The resampling
*        algorithm approximates non-linear co-ordinate transformations
*        in order to improve performance, and this parameter controls
*        how inaccurate the resulting approximation is allowed to be,
*        as a displacement in pixels of the input NDF.  A value of 
*        zero will ensure that no such approximation is done, at the 
*        expense of increasing execution time.
*        [0.2]
*     UBOUND( ) = _INTEGER (Read)
*        The upper pixel-index bounds of the output NDF.  The number of
*        values must be equal to the number of dimensions of the output
*        NDF.  If a null value is supplied, default bounds will be used 
*        which are just high enough to fit in all the transformed pixels 
*        of the input NDF. [!]
*     WLIM = _REAL (Read)
*        This parameter is only used if REBIN is set TRUE. It specifies the 
*        minimum number of good pixels which must contribute to an output pixel
*        for the output pixel to be valid. Note, fractional values are
*        allowed. A null (!) value causes a very small positive value to
*        be used resulting in output pixels being set bad only if they
*        receive no significant contribution from any input pixel. [!]

*  Examples:
*     regrid sg28948 sg28948r mapping=rotate.ast
*        Here sg28948 is resampled into a new co-ordinate system using
*        the AST Mapping stored in a text file called rotate.ast (which
*        may have been created using WCSADD for instance).
*     regrid flat distorted mapping=\!
*        This transforms the NDF called flat.sdf into its current
*        co-ordinate Frame, writing the result to an NDF called
*        distorted.sdf.  It uses nearest-neighbour resampling.
*        If the units of the PIXEL and current co-ordinate Frames of 
*        flat are of similar size, then the pixel co-ordinates of 
*        distorted will be the same as the current co-ordinates of
*        flat, but if there is a large scale discrepancy a scaling 
*        factor will be applied to give the output NDF a similar size 
*        to the input one.  The output NDF will be just large enough 
*        to hold the transformed copies of all the pixels from "flat".
*     regrid flat distorted mapping=\! scale=1 method=sinccos params=[0,3]
*        As the previous example, but the additional scaling factor will
*        not be applied even in the case of large size discrepancy,
*        and a sinc*cos 1-dimensional resampling kernel is used which
*        rolls off at a distance of 3 pixels from the central one.
*     regrid flat distorted mapping=\! scale=0.2 method=blockave params=2
*        In this case, an additional shrinking factor of 0.2 is being
*        applied to the output NDF (i.e. performed following the 
*        Mapping from pixel to current co-ordinates), and the resampling
*        is being done using a block averaging scheme in which a 
*        cube extending two pixels either side of the central pixel
*        is averaged over to produce the output value.  If the 
*        PIXEL-domain and current Frame pixels have (about) the same 
*        size, this will result in every pixel from the input NDF 
*        adding a contribution to one pixel of the output NDF.
*     regrid a119 a119s mapping=\! lbound=[1,-20] ubound=[256,172]
*        This transforms the NDF called a119 into an NDF called a119s.
*        It uses nearest-neighbour resampling.  The shape of a119s 
*        is forced to be (1:256,-20:172) regardless of the location
*        of the transformed pixels of a119.

*  Notes:
*     - If the input NDF contains a Variance component, a Variance 
*     component will be written to the output NDF.  It will be 
*     calculated on the assumption that errors on the input data 
*     values are statistically independent and that their variance
*     estimates may simply be summed (with appropriate weighting 
*     factors) when several input pixels contribute to an output data 
*     value. If this assumption is not valid, then the output error
*     estimates may be biased. In addition, note that the statistical
*     errors on neighbouring output data values (as well as the 
*     estimates of those errors) may often be correlated, even if the
*     above assumption about the input data is correct, because of
*     the sub-pixel interpolation schemes employed. 
*
*     - This task is based on the AST_RESAMPLE<X> and AST_REBIN<X> 
*     routines described in SUN/210.

*  Implementation Status:
*     -  The LABEL, UNITS, and HISTORY components, and all extensions are 
*     propagated. TITLE is controlled by the TITLE parameter. DATA,
*     VARIANCE and WCS are propagated after appropriate modification. The
*     QUALITY component is also propagated if Nearest Neighbour
*     interpolation is being used. The AXIS components is not propagated.
*     -  Processing of bad pixels and automatic quality masking are
*     supported.
*     -  All non-complex numeric data types can be handled. If REBIN is
*     TRUE, the data type will be converted to one of _INTEGER, _DOUBLE
*     or _REAL for processing.
*     -  There can be an arbitrary number of NDF dimensions.

*  Related Applications:
*     KAPPA: FLIP, ROTATE, SLIDE, WCSADD, WCSALIGN.
*     CCDPACK: TRANLIST, TRANNDF, WCSEDIT.

*  Authors:
*     MBT: Mark Taylor (STARLINK)
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     10-DEC-2001 (MBT):
*        Original version.
*     8-Jan-2002 (DSB):
*        Prologue modified. Some parameter defaults and logic changed. Allow 
*        the extra scale factor to be different for each axis. Protect
*        against AST__BAD values being returned by AST_TRAN.
*     15-Jan-2001 (DSB):
*        Modified propagation of WCS to use KPG1_ASFIX. Re-named
*        from RESAMPLE to REGRID. Propagate QUALITY if Nearest Neighbour
*        interpolation is being used.
*     6-MAR-2003 (DSB):
*        Changed the AST_RESAMPLE MAXPIX parameter from a fixed value of
*        50 to 1 larger than the largest output dimension (for extra speed).
*     19-JUL-2005 (DSB):
*        Add REBIN parameter.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST definitions and declarations
      INCLUDE 'PRM_PAR'          ! PRIMDAT constants
      INCLUDE 'NDF_PAR'          ! NDF system constants
      INCLUDE 'PAR_ERR'          ! Parameter system error constants

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER KPG1_FLOOR         ! Most positive integer .LE. a given real
      INTEGER KPG1_CEIL          ! Most negative integer .GE. a given real
      EXTERNAL AST_ISAMAPPING

*  Local Variables:
      CHARACTER DTYPE * ( NDF__SZFTP ) ! Full data type name
      CHARACTER ITYPE * ( NDF__SZTYP ) ! HDS Data type name
      CHARACTER METHOD * ( 16 )  ! Name of resampling scheme
      DOUBLE PRECISION DLBNDI( NDF__MXDIM ) ! Lower bounds of input array
      DOUBLE PRECISION DUBNDI( NDF__MXDIM ) ! Upper bounds of input array
      DOUBLE PRECISION LPO       ! Lower bound in output array
      DOUBLE PRECISION PARAMS( 4 ) ! Additional parameters for resampler
      DOUBLE PRECISION PT1I( NDF__MXDIM ) ! First input point
      DOUBLE PRECISION PT1O( NDF__MXDIM ) ! First output point
      DOUBLE PRECISION PT2I( NDF__MXDIM ) ! Second input point
      DOUBLE PRECISION PT2O( NDF__MXDIM ) ! Second output point
      DOUBLE PRECISION SCALE( NDF__MXDIM ) ! Axis scale factors
      DOUBLE PRECISION SCVAL     ! Value of a single axis scale factor
      DOUBLE PRECISION TOL       ! Tolerance for linear transform approximation
      DOUBLE PRECISION UPO       ! Upper bound in output array
      DOUBLE PRECISION XL( NDF__MXDIM ) ! Position of lowest value
      DOUBLE PRECISION XU( NDF__MXDIM ) ! Position of highest value
      INTEGER BMAX( NDF__MXDIM ) ! Maximum values for array bounds
      INTEGER ELI                ! Number of elements in input NDF
      INTEGER ELO                ! Number of elements in output NDF
      INTEGER FLAGS              ! Flags sent to AST_RESAMPLE<X>
      INTEGER I                  ! Loop variable
      INTEGER INTERP             ! Resampling scheme identifier
      INTEGER IPDATI             ! Pointer to input Data array
      INTEGER IPDATO             ! Pointer to output Data array
      INTEGER IPQUAI             ! Pointer to input Quality array
      INTEGER IPQUAO             ! Pointer to output Quality array
      INTEGER IPVARI             ! Pointer to input Variance array
      INTEGER IPVARO             ! Pointer to output Variance array
      INTEGER JFRM               ! Index of Frame for joining FrameSets
      INTEGER LBDEF( NDF__MXDIM ) ! Default value for LBOUND
      INTEGER LBNDI( NDF__MXDIM ) ! Lower bounds of input NDF pixel co-ordinates
      INTEGER LBNDO( NDF__MXDIM ) ! Lower bounds of output NDF
      INTEGER MAPHI              ! Half-pixel shift Mapping at input end
      INTEGER MAPHIO             ! Mapping with half-pixel shifts at both ends
      INTEGER MAPHO              ! Half-pixel shift Mapping at output end
      INTEGER MAPIO              ! Mapping from input to output NDF
      INTEGER MAPJ               ! Mapping to perform extra scalings
      INTEGER MAPX               ! Basic Mapping to use (without extra scaling)
      INTEGER MAXPIX             ! Max size of linear approximation region
      INTEGER NBAD               ! Number of bad pixels
      INTEGER NDFI               ! NDF identifier of input NDF
      INTEGER NDFO               ! NDF identifier of output NDF
      INTEGER NDIMI              ! Number of dimensions of input NDF
      INTEGER NDIMO              ! Number of dimensions of output NDF
      INTEGER NPARAM             ! Number of parameters required for resampler
      INTEGER NSCALE             ! Number of supplied scale factors
      INTEGER UBDEF( NDF__MXDIM ) ! Default value for UBOUND
      INTEGER UBNDI( NDF__MXDIM ) ! Upper bounds of input NDF pixel co-ordinates
      INTEGER UBNDO( NDF__MXDIM ) ! Upper bounds of output NDF
      INTEGER WCSI               ! WCS FrameSet of input NDF
      INTEGER WCSO               ! WCS FrameSet of the output NDF
      LOGICAL BAD                ! May there be bad pixels?
      LOGICAL CURENT             ! Resample into current Frame?
      LOGICAL HASQUA             ! Does the input NDF have Quality component?
      LOGICAL HASVAR             ! Does the input NDF have Variance component?
      LOGICAL MORE               ! Continue looping?
      LOGICAL REBIN              ! Create output pixels by rebinning?
      LOGICAL SCEQU              ! Are all axis scale factors equal?
      REAL WLIM                  ! Minimum good output weight
*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Start a new AST context.
      CALL AST_BEGIN( STATUS )

*  Start a new NDF context.
      CALL NDF_BEGIN

*  Obtain the input NDF and get the transformation Mapping.
*  ========================================================

*  Open the input NDF.
      CALL LPG_ASSOC( 'IN', 'READ', NDFI, STATUS )

*  Get its dimensions.
      CALL NDF_BOUND( NDFI, NDF__MXDIM, LBNDI, UBNDI, NDIMI, STATUS )

*  See if it has a Variance component.
      CALL NDF_STATE( NDFI, 'VARIANCE', HASVAR, STATUS )
*  Obtain its WCS component.
      CALL KPG1_GTWCS( NDFI, WCSI, STATUS )

*  Attempt to get an externally supplied Mapping - read it from a file.
*  N.B. do not tell ATL1_GTOBJ to look for a Mapping, since in this 
*  case it will extract the Mapping from a FrameSet for us, which
*  we need to do for ourselves if it is going to be done. If a null 
*  value is supplied, annul the error and indicate that the NDF is 
*  to be mapped into its own current Frame.
      IF( STATUS .NE. SAI__OK ) GO TO 999
      CALL ATL1_GTOBJ( 'MAPPING', ' ', AST_NULL, MAPX, STATUS )
      IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         CURENT = .TRUE.
         MAPX = WCSI

*  In the event of any other error, write an explanatory comment (ATL1_GTOBJ
*  does not generate very user-friendly messages) and bail out.
      ELSE IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'REGRID_ERR1', 'REGRID: $MAPPING does not '//
     :                 'contain an AST Object.', STATUS )
         GO TO 999

*  If an external Object was obtained succesfully, report an error if it
*  is not a Mapping (it may be a FrameSet, which is-a Mapping).
      ELSE IF( .NOT. AST_ISAMAPPING( MAPX, STATUS ) ) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP( 'REGRID_ERR2', 'REGRID: File $MAPPING does'//
     :                 ' not contain an AST Mapping or FrameSet.', 
     :                 STATUS )
         GO TO 999

*  A usable external Mapping has been supplied. Indicate that we will
*  not be mapping the NDF into its own current Frame.
      ELSE
         CURENT = .FALSE.
      END IF

*  If this is a FrameSet then extract the Mapping explicitly.
      IF ( AST_ISAFRAMESET( MAPX, STATUS ) ) THEN

*  See whether a PIXEL-domain Frame exists.
          CALL KPG1_ASFFR( MAPX, 'PIXEL', JFRM, STATUS )

*  If so, we will use the PIXEL->current Mapping.
          IF ( JFRM .NE. AST__NOFRAME ) THEN
             MAPX = AST_GETMAPPING( MAPX, JFRM, AST__CURRENT, STATUS )

*  Otherwise, use the base->current Mapping.
          ELSE
             MAPX = AST_GETMAPPING( MAPX, AST__BASE, AST__CURRENT,
     :                              STATUS )
          END IF
      END IF

*  Check the base Frame of the Mapping has the right number of dimensions.
      IF ( AST_GETI( MAPX, 'Nin', STATUS ) .NE. NDIMI ) THEN
         CALL MSG_SETI( 'NAX', AST_GETI( MAPX, 'Nin', STATUS ) )
         CALL MSG_SETI( 'NDIM', NDIMI )
         STATUS = SAI__ERROR
         CALL ERR_REP( 'REGRID_ERR3', 'REGRID: Mapping has ^NAX '//
     :                 'input axes and NDF has ^NDIM dimensions', 
     :                 STATUS )
         GO TO 999
      END IF

*  Get the number of output axes of the Mapping, which will be the 
*  dimensionality of the output NDF.
      NDIMO = AST_GETI( MAPX, 'Nout', STATUS )
      
*  Check that resampling into this Frame will be possible.
      IF ( STATUS .NE. SAI__OK ) GO TO 999
      IF ( NDIMO .GT. NDF__MXDIM ) THEN
         CALL MSG_SETI( 'NDIM', NDIMO )
         CALL MSG_SETI( 'MAX', NDF__MXDIM )
         STATUS = SAI__ERROR
         CALL ERR_REP( 'REGRID_ERR4', 'REGRID: Output Frame has '//
     :                 '^NDIM dimensions - maximum is ^MAX.', STATUS )
         GO TO 999
      END IF

*  Get the qualifications to the transformation.
*  =============================================

*  Initialise the resampling routine control flags.
      FLAGS = 0

*  Get the algorithm to use.
      CALL PAR_GET0L( 'REBIN', REBIN, STATUS )

*  Get the method for calculating the output array value from the
*  input values.
      MORE = .TRUE.
      DO WHILE( MORE .AND. STATUS .EQ. SAI__OK )
         CALL PAR_CHOIC( 'METHOD', 'SincSinc', 'Nearest,Bilinear,'//
     :                   'Sinc,Gauss,SincSinc,SincCos,SincGauss', 
     :                   .TRUE., METHOD, STATUS )
         IF( .NOT. REBIN .AND. METHOD( 1 : 1 ) .EQ. 'G' ) THEN
            CALL MSG_OUT( ' ', 'Method "Gauss" cannot be used '//
     :                    'because REBIN is set false.', STATUS )
            CALL MSG_OUT( ' ', 'Please supply a new value for '//
     :                    'parameter METHOD.', STATUS )
            CALL PAR_CANCL( 'METHOD', STATUS )
         ELSE
            MORE = .FALSE.
         END IF
         CALL MSG_BLANK( STATUS )
      END DO


      IF ( STATUS .NE. SAI__OK ) GO TO 999
      IF ( METHOD .EQ. 'NEAREST' ) THEN
         CALL MSG_SETC( 'M', 'Nearest Neighbour' )
         INTERP = AST__NEAREST
         NPARAM = 0
      ELSE IF ( METHOD .EQ. 'BILINEAR' ) THEN
         CALL MSG_SETC( 'M', 'Bilinear' )
         INTERP = AST__LINEAR
         NPARAM = 0
      ELSE IF( METHOD .EQ. 'GAUSS' ) THEN
         CALL MSG_SETC( 'M', 'Gaussian' )
         INTERP = AST__GAUSS
         NPARAM = 2
      ELSE IF ( METHOD .EQ. 'SINC' ) THEN
         CALL MSG_SETC( 'M', 'Sinc' )
         INTERP = AST__SINC
         NPARAM = 1
      ELSE IF ( METHOD .EQ. 'SINCSINC' ) THEN
         CALL MSG_SETC( 'M', 'SincSinc' )
         INTERP = AST__SINCSINC
         NPARAM = 2
      ELSE IF ( METHOD .EQ. 'SINCCOS' ) THEN
         CALL MSG_SETC( 'M', 'SincCos' )
         INTERP = AST__SINCCOS
         NPARAM = 2
      ELSE IF ( METHOD .EQ. 'SINCGAUSS' ) THEN
         CALL MSG_SETC( 'M', 'SincGauss' )
         INTERP = AST__SINCGAUSS
         NPARAM = 2
      ELSE IF ( METHOD .EQ. 'BLOCKAVE' ) THEN
         CALL MSG_SETC( 'M', 'BlockAve' )
         INTERP = AST__BLOCKAVE
         NPARAM = 1
      END IF
      IF( REBIN ) THEN
         CALL MSG_OUT( 'REGRID_MSG1', '  Using ^M binning.', 
     :                  STATUS )
      ELSE
         CALL MSG_OUT( 'REGRID_MSG1', '  Using ^M interpolation.', 
     :                  STATUS )
      END IF

*  Get an additional parameter vector if required.
      IF ( NPARAM .GT. 0 ) THEN
         CALL PAR_EXACD( 'PARAMS', NPARAM, PARAMS, STATUS )
      END IF

*  Get the tolerance for Mapping linear approximation.
      CALL PAR_GET0D( 'TOL', TOL, STATUS )
      IF ( STATUS .NE. SAI__OK ) GO TO 999

*  Get the minimum acceptable output weight
      IF( STATUS .EQ. SAI__OK .AND. REBIN ) THEN
         CALL PAR_GET0R( 'WLIM', WLIM, STATUS )      
         IF( STATUS .EQ. PAR__NULL ) THEN
            CALL ERR_ANNUL( STATUS )
            WLIM = 1.0E-10
         END IF
      END IF

*  Add an additional scaling factor to the Mapping.
*  ================================================

*  Get the values of the scale factors from the parameter system. If a null
*  (!) is supplied, annul the error and calculate default values.
      IF( STATUS .NE. SAI__OK ) GO TO 999
      CALL PAR_GET1D( 'SCALE', NDIMO, SCALE, NSCALE, STATUS )
      IF( STATUS .EQ. PAR__NULL ) THEN 
         CALL ERR_ANNUL( STATUS )

*  If we are using a Mapping specified by parameter MAPPING, the default
*  scaling factor is unity on all axes. Otherwise, we need to calculate
*  suitable default values.
         IF( .NOT. CURENT ) THEN
            SCVAL = 1.0
            SCEQU = .TRUE.
         ELSE

*  Work out the 'size' of a pixel in the input and output arrays.  
*  The purpose of this is just to decide whether they are about the 
*  same size; if they are then SCALE will default to unity, if not 
*  then it will default to some size-equalising factor for each axis.  
*  First set up the corners in the base Frame of a single pixel at teh
*  centre of th einput image.
            DO I = 1, NDIMI
               PT1I( I ) = 0.5D0 * DBLE( LBNDI( I ) + UBNDI( I ) ) - 0.5D0
               PT2I( I ) = PT1I( I ) + 1D0
            END DO

*  Now find the bounds within the output image of this pixel.
            DO I = 1, NDIMO
               CALL AST_MAPBOX( MAPX, PT1I, PT2I, .TRUE., I, PT1O( I ),
     :                          PT2O( I ), XL, XU, STATUS )
            END DO

*  Find the scaling factors which result in the transformed and scaled
*  pixel having a size of unity on each axis. Ignore values between 0.25
*  and 4. If any transformed position is bad, use a scaling factor of 
*  1.0 for that axis.
            SCVAL = 0.0
            DO I = 1, NDIMO
               IF( PT1O( I ) .NE. AST__BAD .AND. 
     :             PT2O( I ) .NE. AST__BAD ) THEN
                  SCALE( I ) = ABS( PT2O( I ) - PT1O( I ) )

                  IF( SCALE( I ) .GT. 0.0 ) THEN
                     IF( SCALE( I ) .LE. 0.25 .OR. 
     :                   SCALE( I ) .GE. 4.0 ) THEN
                        SCALE( I ) = 1.0/SCALE( I )

                     ELSE
                        SCALE( I ) = 1.0

                     END IF                     

                  ELSE
                     SCALE( I ) = 1.0

                  END IF                  

               ELSE
                  SCALE( I ) = 1.0

               END IF

*  Note if all scale values are equal (SCEQU), and not what this
*  value is (SCVAL).
               IF( I .EQ. 1 ) THEN
                  SCVAL = SCALE( 1 )
                  SCEQU = .TRUE.
               ELSE IF( SCALE( I ) .NE. SCVAL ) THEN
                  SCEQU = .FALSE.
               END IF
                  
            END DO
            
         END IF

*  If SCALE values were supplied, see if they are all the same, and copy
*  thre last value to any missing values.
      ELSE
         SCVAL = SCALE( 1 )
         SCEQU = .TRUE.
         DO I = 2, NDIMO
            IF( I .LE. NSCALE ) THEN
               IF( SCALE( I ) .NE. SCVAL ) SCEQU = .FALSE.
            ELSE
               SCALE( I ) = SCALE( NSCALE )
            END IF
         END DO

      END IF

*  If any scale factor is not unity, report them all, and use them.
      IF( .NOT. SCEQU .OR. SCVAL .NE. 1.0 ) THEN     

         IF( SCEQU ) THEN 
            CALL MSG_SETR( 'S', REAL( SCVAL ) )
            CALL MSG_OUT( 'REGRID_MSG2 ', '  The supplied Mapping '//
     :                    'is being modified by a scale factor of ^S '//
     :                    'on each axis.', STATUS )      
           MAPJ = AST_ZOOMMAP( NDIMO, SCVAL, ' ', STATUS )

         ELSE
            DO I = 1, NDIMO 
               CALL MSG_SETR( 'S', REAL( SCALE( I ) ) )
               IF( I .NE. NDIMO ) CALL MSG_SETC( 'S', ',' )
            END DO
            CALL MSG_OUT( 'REGRID_MSG3', '  The supplied Mapping is'//
     :                    '  being modified by scale factors of (^S).',
     :                    STATUS )      
            MAPJ = AST_MATRIXMAP( NDIMI, NDIMO, 1, SCALE, ' ', STATUS )
         END IF 

*  Generate the actual mapping from the input to output array, by
*  combining the Mapping from base to current frames and the Mapping
*  created above. Simplify it.
         MAPIO = AST_SIMPLIFY( AST_CMPMAP( MAPX, MAPJ, .TRUE., ' ',
     :                                     STATUS ), STATUS )

*  Just clone the original Mapping if the scale factor is unity.
      ELSE
         MAPJ = AST_UNITMAP( NDIMO, ' ', STATUS )
         MAPIO = AST_CLONE( MAPX, STATUS )
      END IF

*  Get the bounds of the output NDF.
*  =================================

*  Work out the bounds of an array which would contain the resampled 
*  copy of the whole input array.
      DO I = 1, NDIMI
         DLBNDI( I ) = DBLE( LBNDI( I ) - 1 )
         DUBNDI( I ) = DBLE( UBNDI( I ) )
      END DO
      DO I = 1, NDIMO
         CALL AST_MAPBOX( MAPIO, DLBNDI, DUBNDI, .TRUE., I, LPO, UPO,
     :                    XL, XU, STATUS )
         LBDEF( I ) = KPG1_FLOOR( REAL( LPO ) ) + 1
         UBDEF( I ) = KPG1_CEIL( REAL( UPO ) )
         BMAX( I ) = VAL__MAXI
      END DO

*  Get the actual values for these bounds from the parameter system, 
*  using the calculated values as defaults.
      CALL PAR_GDR1I( 'LBOUND', NDIMO, LBDEF, VAL__MINI, VAL__MAXI,
     :                .TRUE., LBNDO, STATUS )
      CALL PAR_GRM1I( 'UBOUND', NDIMO, UBDEF, LBNDO, BMAX, .TRUE.,
     :                UBNDO, STATUS )

*  Do a check that there is some overlap between the requested range
*  and the resampled image of the NDF. Also, set the initial scale size 
*  for the Mapping linear approximation algorithm to be equal to the 
*  largest dimension (see AST_RESAMPLE<X> documentation).
      MAXPIX = 50
      DO I = 1, NDIMO
         MAXPIX = MAX( MAXPIX, UBNDO( I ) - LBNDO( I ) + 1 )
         IF ( UBNDO( I ) .LT. LBDEF( I ) .OR. 
     :        LBNDO( I ) .GT. UBDEF( I ) ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'REGRID_ERR5', 'REGRID: Requested '//
     :                    'bounds are entirely outside resampled '//
     :                    'region', STATUS )
            GO TO 999
         END IF
      END DO

*  Ensure that MAXPIX is larger than the largest dimension.
      MAXPIX = MAXPIX + 1

*  Create and configure the output NDF.
*  ====================================

*  Create a new NDF by propagation from the input one.
      CALL LPG_PROP( NDFI, 'UNIT', 'OUT', NDFO, STATUS )

*  Get a title for the new NDF from the parameter system.
      CALL NDF_CINP( 'TITLE', NDFO, 'TITLE', STATUS )
      IF ( STATUS .NE. SAI__OK ) GO TO 999

*  Set the shape of the output NDF.
      CALL NDF_SBND( NDIMO, LBNDO, UBNDO, NDFO, STATUS )

*  Determine a data type which can be used for operations on the
*  Data and possibly Variance components of the NDF.
      IF( REBIN ) THEN
         CALL NDF_MTYPN( '_INTEGER,_REAL,_DOUBLE', 1, NDFI, 
     :                   'DATA,VARIANCE', ITYPE, DTYPE, STATUS )
      ELSE
         CALL NDF_MTYPN( '_BYTE,_UBYTE,_WORD,_UWORD,_INTEGER,_REAL,'//
     :                '_DOUBLE', 1, NDFI, 'DATA,VARIANCE', ITYPE,
     :                DTYPE, STATUS )
      END IF

*  Set the Data and possibly Variance component data types.
      CALL NDF_STYPE( ITYPE, NDFO, 'DATA', STATUS )
      IF ( HASVAR ) THEN
         CALL NDF_STYPE( ITYPE, NDFO, 'VARIANCE', STATUS )
      END IF
      
*  Store a suitably modified copy of the input WCS in the output.
      CALL KPG1_ASFIX( MAPIO, NDFI, NDFO, STATUS )

*  Map the array components.
*  =========================

*  Map the Data array of the input and output NDFs.
      CALL NDF_MAP( NDFI, 'DATA', ITYPE, 'READ', IPDATI, ELI, STATUS )
      CALL NDF_MAP( NDFO, 'DATA', ITYPE, 'WRITE', IPDATO, ELO,
     :              STATUS )

*  Find out if there may be bad pixels in the mapped Data array.
      CALL NDF_BAD( NDFI, 'DATA', .FALSE., BAD, STATUS )

*  Map the Variance component of the input and output NDFs if we are
*  processing variances.
      IF ( HASVAR ) THEN
         CALL NDF_MAP( NDFI, 'VARIANCE', ITYPE, 'READ', IPVARI, ELI,
     :                 STATUS )
         CALL NDF_MAP( NDFO, 'VARIANCE', ITYPE, 'WRITE', IPVARO,
     :                 ELO, STATUS )

*  Unless we already know of bad values in the Data component, see 
*  whether the Variance component may contain them.
         IF ( .NOT. BAD ) THEN
            CALL NDF_BAD( NDFI, 'VARIANCE', .FALSE., BAD, STATUS )
         END IF

*  Record the fact that variances should be processed.
         FLAGS = FLAGS + AST__USEVAR
      END IF

*  If either the Data or Variance component of the input NDF may have
*  bad values, record this fact.
      IF ( BAD ) THEN
         FLAGS = FLAGS + AST__USEBAD
      END IF

*  Perform the resampling.
*  =======================

*  Since AST_RESAMPLE<X> requires the centre of pixels to be represented
*  by integers (the LBND and UBND arrays) it is necessary to add a 
*  half-pixel shift onto both ends of the Mapping prior to executing
*  the resample.  First construct a Mapping which transforms minus a 
*  half pixel in every input dimension.
      DO I = 1, NDIMI
         PT1I( I ) = 0D0
         PT2I( I ) = 1D0
         PT1O( I ) = PT1I( I ) - 0.5D0
         PT2O( I ) = PT2I( I ) - 0.5D0
      END DO
      MAPHI = AST_WINMAP( NDIMI, PT1I, PT2I, PT1O, PT2O, ' ', STATUS )

*  Then one which transforms plus a half-pixel in every output dimension.
      DO I = 1, NDIMO
         PT1I( I ) = 0D0
         PT2I( I ) = 1D0
         PT1O( I ) = PT1I( I ) + 0.5D0
         PT2O( I ) = PT2I( I ) + 0.5D0
      END DO
      MAPHO = AST_WINMAP( NDIMO, PT1I, PT2I, PT1O, PT2O, ' ', STATUS )

*  Combine these to get a Mapping which does what we want it to,
*  correcting for the half pixel at either end.
      MAPHIO = AST_CMPMAP( MAPHI, MAPIO, .TRUE., ' ', STATUS )
      MAPHIO = AST_CMPMAP( MAPHIO, MAPHO, .TRUE., ' ', STATUS )
      MAPHIO = AST_SIMPLIFY( MAPHIO, STATUS )

*  Perform the resampling according to data type.
      IF( .NOT. REBIN ) THEN
         IF ( ITYPE .EQ. '_BYTE' ) THEN
            NBAD = AST_RESAMPLEB( MAPHIO, NDIMI, LBNDI, UBNDI,
     :                         %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                         AST_NULL, PARAMS, FLAGS, TOL, MAXPIX,
     :                         VAL__BADB, NDIMO, LBNDO, UBNDO, LBNDO,
     :                         UBNDO, %VAL( IPDATO ), %VAL( IPVARO ),
     :                         STATUS )
         
         ELSE IF ( ITYPE .EQ. '_UBYTE' ) THEN
            NBAD = AST_RESAMPLEUB( MAPHIO, NDIMI, LBNDI, UBNDI,
     :                         %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                         AST_NULL, PARAMS, FLAGS, TOL, MAXPIX,
     :                         VAL__BADUB, NDIMO, LBNDO, UBNDO, LBNDO,
     :                         UBNDO, %VAL( IPDATO ), %VAL( IPVARO ),
     :                         STATUS )
         
         ELSE IF ( ITYPE .EQ. '_WORD' ) THEN
            NBAD = AST_RESAMPLEW( MAPHIO, NDIMI, LBNDI, UBNDI,
     :                         %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                         AST_NULL, PARAMS, FLAGS, TOL, MAXPIX,
     :                         VAL__BADW, NDIMO, LBNDO, UBNDO, LBNDO,
     :                         UBNDO, %VAL( IPDATO ), %VAL( IPVARO ),
     :                         STATUS )
         
         ELSE IF ( ITYPE .EQ. '_UWORD' ) THEN
            NBAD = AST_RESAMPLEUW( MAPHIO, NDIMI, LBNDI, UBNDI,
     :                         %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                         AST_NULL, PARAMS, FLAGS, TOL, MAXPIX,
     :                         VAL__BADUW, NDIMO, LBNDO, UBNDO, LBNDO,
     :                         UBNDO, %VAL( IPDATO ), %VAL( IPVARO ),
     :                         STATUS )
         
         ELSE IF ( ITYPE .EQ. '_INTEGER' ) THEN
            NBAD = AST_RESAMPLEI( MAPHIO, NDIMI, LBNDI, UBNDI,
     :                         %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                         AST_NULL, PARAMS, FLAGS, TOL, MAXPIX,
     :                         VAL__BADI, NDIMO, LBNDO, UBNDO, LBNDO,
     :                         UBNDO, %VAL( IPDATO ), %VAL( IPVARO ),
     :                         STATUS )
         
         ELSE IF ( ITYPE .EQ. '_REAL' ) THEN
            NBAD = AST_RESAMPLER( MAPHIO, NDIMI, LBNDI, UBNDI,
     :                         %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                         AST_NULL, PARAMS, FLAGS, TOL, MAXPIX,
     :                         VAL__BADR, NDIMO, LBNDO, UBNDO, LBNDO,
     :                         UBNDO, %VAL( IPDATO ), %VAL( IPVARO ),
     :                         STATUS )
         
         ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
            NBAD = AST_RESAMPLED( MAPHIO, NDIMI, LBNDI, UBNDI,
     :                         %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                         AST_NULL, PARAMS, FLAGS, TOL, MAXPIX,
     :                         VAL__BADD, NDIMO, LBNDO, UBNDO, LBNDO,
     :                         UBNDO, %VAL( IPDATO ), %VAL( IPVARO ),
     :                         STATUS )
         END IF


      ELSE
         IF ( ITYPE .EQ. '_INTEGER' ) THEN
            CALL AST_REBINI( MAPHIO, DBLE(WLIM), NDIMI, LBNDI, UBNDI,
     :                       %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                       PARAMS, FLAGS, TOL, MAXPIX,
     :                       VAL__BADI, NDIMO, LBNDO, UBNDO, LBNDI,
     :                       UBNDI, %VAL( IPDATO ), %VAL( IPVARO ),
     :                       STATUS )
         
         ELSE IF ( ITYPE .EQ. '_REAL' ) THEN
            CALL AST_REBINR( MAPHIO, DBLE(WLIM), NDIMI, LBNDI, UBNDI,
     :                       %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                       PARAMS, FLAGS, TOL, MAXPIX,
     :                       VAL__BADR, NDIMO, LBNDO, UBNDO, LBNDI,
     :                       UBNDI, %VAL( IPDATO ), %VAL( IPVARO ),
     :                       STATUS )

         ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
            CALL AST_REBIND( MAPHIO, DBLE(WLIM), NDIMI, LBNDI, UBNDI,
     :                       %VAL( IPDATI ), %VAL( IPVARI ), INTERP,
     :                       PARAMS, FLAGS, TOL, MAXPIX,
     :                       VAL__BADD, NDIMO, LBNDO, UBNDO, LBNDI,
     :                       UBNDI, %VAL( IPDATO ), %VAL( IPVARO ),
     :                       STATUS )
         END IF

         NBAD = 1

      END IF

*  We can set the bad pixels flag according to the bad pixel count 
*  returned from AST_RESAMPLE<X>.
      BAD = NBAD .GT. 0
      CALL NDF_SBAD( BAD, NDFO, 'DATA', STATUS )
      IF ( HASVAR ) THEN
         CALL NDF_SBAD( BAD, NDFO, 'VARIANCE', STATUS )
      END IF

*  If using Nearest Neighbour interpolation, resample any QUALITY array.
*  =====================================================================
      CALL NDF_STATE( NDFI, 'QUALITY', HASQUA, STATUS )
      IF( INTERP .EQ. AST__NEAREST .AND. HASQUA ) THEN

*  Map the QUALITY array of the input and output NDFs. Note, QUALITY
*  arrays should always be mapped as _UBYTE.
         CALL NDF_MAP( NDFI, 'QUALITY', '_UBYTE', 'READ', IPQUAI, ELI, 
     :                 STATUS )
         CALL NDF_MAP( NDFO, 'QUALITY', '_UBYTE', 'WRITE', IPQUAO, ELO,
     :                 STATUS )

*  Do the resampling.
         NBAD = AST_RESAMPLEUB( MAPHIO, NDIMI, LBNDI, UBNDI,
     :                          %VAL( IPQUAI ), %VAL( IPQUAI ), INTERP,
     :                          AST_NULL, PARAMS, 0, TOL, MAXPIX,
     :                          VAL__BADUB, NDIMO, LBNDO, UBNDO, LBNDO,
     :                          UBNDO, %VAL( IPQUAO ), %VAL( IPQUAO ),
     :                          STATUS )

      END IF

*  Tidy up.
*  ========

*  Annul (and unmap) the input and output NDFs.
      CALL NDF_ANNUL( NDFI, STATUS )
      CALL NDF_ANNUL( NDFO, STATUS )

*  Error exit label.
  999 CONTINUE

*  Exit the NDF context.
      CALL NDF_END( STATUS )

*  Exit the AST context.
      CALL AST_END( STATUS )

*  If an error occurred, then report a contextual message.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'REGRID_ERR6', 'REGRID: Unable to '//
     :                 'transform the NDF.', STATUS )
      END IF

      END
