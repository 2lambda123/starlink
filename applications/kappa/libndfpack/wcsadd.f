      SUBROUTINE WCSADD( STATUS )
*+
*  Name:
*     WCSADD

*  Purpose:
*     Creates a Mapping and optionally adds a new co-ordinate Frame into the 
*     WCS component of an NDF.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL WCSADD( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application can be used to create a new AST Mapping and
*     optionally use the Mapping to add a new co-ordinate Frame into 
*     the WCS component of an NDF (see parameter NDF). An output text file 
*     may also be created holding a textual representation of the 
*     Mapping for future use by other applications such as RESAMPLE (see 
*     parameter MAPOUT). A number of different types of Mapping can be 
*     used (see parameter MAPTYPE).
*     
*     When adding a new Frame to a WCS component, the Mapping is used to 
*     connect the the new Frame to an existing one (called the "basis" 
*     Frame). The newly added Frame is a copy of the basis Frame, with 
*     the new Domain attribute specified by parameter DOMAIN, and becomes 
*     the current co-ordinate Frame in the NDF. If necessary, other 
*     attributes of the new Frame (Title, Label, Format, etc) can be 
*     changed using application WCSATTRIB.
*
*     WCSADD will only generate Mappings with the same number of 
*     input and output axes; this number is determined by the number
*     of axes in the basis Frame if an NDF is supplied, or by the 
*     NAXES parameter otherwise.

*  Usage:
*     wcsadd ndf frame domain maptype

*  ADAM Parameters:
*     CENTRE( 2 ) = _DOUBLE (Read)
*        The co-ordinates of the centre of a pincushion distortion.
*        Only used when MAPTYPE=PINCUSHION. See also DISCO.
*        [0,0]
*     DIAG( ) = _DOUBLE (Read)
*        The elements along the diagonal of the linear transformation 
*        matrix. There will be as many of these as there are axes in the
*        basis Frame. Each effectively gives the factor by which 
*        co-ordinates on the corresponding axis should be multiplied.
*        This parameter is only used when MAPTYPE=DIAG.
*     DISCO = _DOUBLE (Read)
*        The distortion coefficient of a pincushion distortion. Used
*        in conjunction with the CENTRE parameter, this defines the
*        forward transformation to be used as follows:
*
*                XX = X + D * (X - C1) * ( (X - C1)**2 + (Y - C2)**2 )
*
*                YY = Y + D * (Y - C2) * ( (X - C1)**2 + (Y - C2)**2 )
*
*        where (X,Y) are the input co-ordinates, (XX,YY) the output 
*        co-ordinates, D is DISCO, and C1 and C2 are the two elements of 
*        CENTRE. Only used when MAPTYPE=PINCUSHION.
*     DOMAIN = LITERAL (Read)
*        The value for the Domain attribute for the new Frame. Care should be
*        taken to ensure that domain names are used consistently. This
*        will usually mean avoiding any domain names which are already in
*        use within the WCS component, particularly the standard domain names
*        such as GRID, PIXEL, AXIS and GRAPHICS. The supplied value is 
*        stripped of spaces, and converted to upper case before being used.
*     EPOCH = _DOUBLE (Read)
*        If the basis Frame is specified using a "Sky Co-ordinate System" 
*        specification for a celestial co-ordinate system (see parameter 
*        FRAME), then an epoch value is needed to qualify it. This is the 
*        epoch at which the supplied sky positions were determined. It should 
*        be given as a decimal years value, with or without decimal places  
*        ("1996.8" for example). Such values are interpreted as a Besselian 
*        epoch if less than 1984.0 and as a Julian epoch otherwise. The 
*        suggested default is the value stored in the basis Frame.
*     FOREXP = LITERAL (Read)
*        A group of expressions to be used for the forward co-ordinate 
*        transformations in a MathMap. There must be at least as many
*        expressions as the number of axes of the Mapping, but there
*        may be more if intermediate expressions are to be used. The 
*        expressions may be given directly in response to the prompt, or 
*        read from a text file, in which case the name of the file should
*        be given, preceeded by a "^" character. Individual expression
*        should be separated by commas or, if they are supplied in a file,
*        new-lines (see SUN/95 section "Specifying Groups of Objects"
*        which is within the section "Parameters"). The suntax for each 
*        expression is fortran-like; see the "Examples" section below, and 
*        the Appendix entitled "Using MathMaps" in SUN/95 for details. Only 
*        used when MAPTYPE=MATH.
*     FRAME = LITERAL (Read)
*        A string specifying the basis Frame. If a null value is supplied
*        the current co-ordinate Frame in the NDF is used. The string can 
*        be one of the following:
*
*        - A domain name such as SKY, AXIS, PIXEL, etc. The two
*        "pseudo-domains" WORLD and DATA may be supplied and will be
*        translated into PIXEL and AXIS respectively, so long as the WCS
*        component of the NDF does not contain Frames with these domains.
*
*        - An integer value giving the index of the required Frame within
*        the WCS component.
*
*        - A "Sky Co-ordinate System" (SCS) value such as EQUAT(J2000) 
*        (see section "Sky Co-ordinate Systems" in SUN/95).
*
*     INVEXP = LITERAL (Read)
*        The expressions to be used for the inverse co-ordinate 
*        transformations in a MathMap. See FOREXP. Only used when
*        MAPTYPE=MATH.
*     MAPIN = FILENAME (Read)
*        The  name of a file containing an AST Mapping with which to
*        connect the basis Frame to the new one. The file may be a text
*        file which contains the textual representation of an AST Mapping,
*        or a FITS file which contains the Mapping as an AST object
*        encoded in its headers, or an NDF. If it is an NDF, the
*        Mapping from its base (GRID-domain) to current Frame will be
*        used. Only used when MAPTYPE=FILE.
*     MAPOUT = FILENAME (Write)
*        The name of a text file in which to store a textual representation 
*        of the Mapping. This can be used, for instance, by the RESAMPLE 
*        application. If a null (!) value is supplied, no file is
*        created. [!]
*     MAPTYPE = LITERAL (Read)
*        The type of Mapping to be used to connect the new Frame to the
*        basis Frame. It must be one of the following strings, each
*        of which require some additional parameters as indicated:
* 
*        - DIAGONAL   -- A linear mapping with no translation
*                        of off-diagonal coefficients (see parameter DIAG)
*
*        - FILE       -- A mapping defined by an AST Mapping supplied
*                        in a separate file (see parameter MAPIN)
*
*        - LINEAR     -- A general linear mapping (see parameter TR)
*
*        - MATH       -- A general algebraically defined mapping
*                        (see parameters FOREXP, INVEXP, SIMPFI, SIMPIF)
*
*        - PINCUSHION -- A pincushion/barrel distortion (see parameters DISCO,
*                        CENTRE)
*
*        - SHIFT      -- A translation (see parameter SHIFT)
*
*        - UNIT       -- A unit mapping
*
*        - ZOOM       -- A uniform expansion/contraction (see parameter ZOOM)
*
*        ["LINEAR"]
*     NAXES = _INTEGER (Read)
*        The number of input and output axes which the Mapping will have.
*        Only used if a null value is supplied for parameter NDF.
*     NDF = NDF (Read and Write)
*        The NDF in which to store a new co-ordinate Frame. Supply a null (!)
*        value if you do not wish to add a Frame to an NDF (you can still 
*        use the MAPOUT parameter to write the Mapping to a text file).
*     SHIFT( ) = _DOUBLE (Read)
*        A vector giving the displacement represented by the translation.
*        There must be one element for each axis. Only used when
*        MAPTYPE=SHIFT.
*     SIMPFI = _LOGICAL (Read)
*        The value of the Mapping's SimpFI attribute (whether it is 
*        legitimate to simplify the forward followed by the inverse 
*        transformation to a unit transformation). Only used when
*        MAPTYPE=MATH.  [TRUE]
*     SIMPIF = _LOGICAL (Read)
*        The value of the Mapping's SimpIF attribute (whether it is 
*        legitimate to simplify the inverse followed by the forward 
*        transformation to a unit transformation). Only used when
*        MAPTYPE=MATH.  [TRUE]
*     TR( ) = _DOUBLE (Read)
*        The values of this parameter are the coefficients of a linear 
*        transformation from the basis Frame specified by parameter FRAME
*        to the new Frame. This parameter is only used when MAPTYPE=LINEAR.
*        For instance, if a feature has co-ordinates (X,Y,Z,...) in 
*        the basis Frame, and co-ordinates (U,V,W,...) in the new Frame,
*        then the following transformations would be used, depending on 
*        how many axes the two Frames have:
*
*        - 1-dimensional:
*
*              U = TR(1) + TR(2)*X 
*
*        - 2-dimensional:
*
*              U = TR(1) + TR(2)*X + TR(3)*Y
*
*              V = TR(4) + TR(5)*X + TR(6)*Y
*
*        - 3-dimensional:
*
*              U = TR(1) + TR(2)*X + TR(3)*Y + TR(4)*Z
*
*              V = TR(5) + TR(6)*X + TR(7)*Y + TR(8)*Z
*
*              W = TR(9) + TR(10)*X + TR(11)*Y + TR(12)*Z
*
*        The correct number of values must be supplied (that is, N*(N+1)
*        where N is the number of axes in the new and old Frames). If a 
*        null value (!) is given it is assumed that the new Frame and the
*        basis Frame are connected using a unit mapping (i.e. corresponding
*        axis values are identical in the two Frames). Only used when
*        MAPTYPE=LINEAR. [!]
*     ZOOM = _DOUBLE (Read)
*        The scaling factor for a ZoomMap; every coordinate will be 
*        multiplied by this factor in the forward transformation. 
*        Only used when MAPTYPE=ZOOM. 

*  Examples:
*     wcsadd ngc5128 pixel old_pixel unit
*        This adds a new co-ordinate Frame into the WCS component of the
*        NDF called ngc5128. The new Frame is given the domain OLD_PIXEL
*        and is a copy of the existing PIXEL Frame. This OLD_PIXEL Frame 
*        will be retained through further processing and can be used as a 
*        record of the original pixel co-ordinate Frame.
*     wcsadd my_data dist-lum dist(au)-lum linear tr=[0,2.0628E5,0,0,0,1]
*        This adds a new co-ordinate Frame into the WCS component of the
*        NDF called my_data. The new Frame is given the domain DIST(AU)-LUM
*        and is a copy of an existing Frame with domain DIST-LUM. The first
*        axis in the new Frame is derived from the first axis in the basis
*        Frame but is in different units (AU instead of parsecs). This
*        change of units is achieved by multiplying the old Frame axis 1
*        values by 2.0628E5. The values on the second axis are copied 
*        without change. You could then use application WCSATTRIB to set
*        the "Unit" attribute for axis 1 of the new Frame to "AU".
*     wcsadd my_data dist-lum dist(au)-lum diag diag=[2.0628E5,1]
*        This does exactly the same as the previous example.
*     wcsadd ax322 ! shrunk zoom zoom=0.25 mapout=zoom.ast
*        This adds a new Frame to the WCS component of ax322 which is a 
*        one-quarter-scale copy of its current co-ordinate Frame. The
*        Mapping is also stored in the text file "zoom.ast".
*     wcsadd cube grid slid shift shift=[0,0,1024]
*        This adds a new Frame to the WCS component of the NDF cube 
*        which matches the GRID-domain co-ordinates in the first two
*        axes, but is translated by 1024 pixels on the third axis.
*     wcsadd plane pixel polar math simpif simpfi 
*           forexp="'r=sqrt(x*x+y*y),theta=atan2(y,x)'"
*           invexp="'x=r*cos(theta),y=r*sin(theta)'"
*        A new Frame is added which gives pixel positions in polar
*        co-ordinates. Fortran-like expressions are supplied which define 
*        both the forward and inverse transformations of the Mapping. The
*        symbols "x" and "y" are used to represent the two input Cartesian
*        pixel co-ordinate axes, and the symbols "r" and "theta" are used to
*        represent the output polar co-ordinates. Note, the single quotes 
*        are needed when running from the Unix shell in order to prevent
*        the shell interpreting the parentheses and commas within the 
*        expressions.
*     wcsadd plane pixel polar math simpif simpfi forexp=^ft invexp=^it
*        As above, but the expressions defining the transformations are
*        supplied in two text files called "ft" and "it", instead of being
*        supplied directly. Each file could contain the two expression on 
*        two separate lines.
*     wcsadd ndf=\! naxes=2 mapout=pcd.ast maptype=pincushion
*           disco=5.3e-10
*        This constructs a pincushion-type distortion Mapping centred
*        on the origin with a distortion coefficient of 5.3e-10,
*        and writes out the Mapping as a text file called pcd.ast.
*        This file could then be used by RESAMPLE to resample
*        the pixels of an NDF according to this transformation.
*        No NDF is accessed.

*  Notes:
*     -  The new Frame has the same number of axes as the basis Frame.
*     -  An error is reported if the transformation supplied using parameter 
*     TR is singular. 

*  Related Applications:
*     KAPPA: RESAMPLE, NDFTRACE, WCSFRAME, WCSREMOVE, WCSATTRIB.
*     CCDPACK: WCSEDIT.

*  Authors:
*     DSB: David Berry (STARLINK)
*     MBT: Mark Taylor (STARLINK)
*     {enter_new_authors_here}

*  History:
*     2-OCT-1998 (DSB):
*        Original version.
*     25-AUG-1999 (DSB):
*        Add TOKEN arg in call to KPG1_ASFRM
*     14-DEC-2001 (MBT):
*        Added MAPTYPE, MAPOUT and other parameters and several new 
*        Mapping types.
*     8-JAN-2002 (DSB):
*        Minor prologue changes. Change some parameter logic. Use GRP to
*        get the MATHMAP expressions.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
*  Type Definitions:
      IMPLICIT NONE              ! no default typing allowed

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_PAR'          ! NDF constants 
      INCLUDE 'PRM_PAR'          ! PRIMDAT constants
      INCLUDE 'PAR_ERR'          ! PAR error constants 
      INCLUDE 'AST_PAR'          ! AST constants and function declarations
      INCLUDE 'GRP_PAR'          ! GRP constants 

*  Status:
      INTEGER STATUS

*  External References:
      INTEGER CHR_LEN            ! Used length of a string
      EXTERNAL AST_ISAMAPPING    ! AST function to classify Object type

*  Local Constants:
      INTEGER MAXEXP             ! Maximum number of expressions for MathMap
      PARAMETER( MAXEXP = 12 )

*  Local Variables:
      CHARACTER DOM*40           ! Domain for new Frame
      CHARACTER MAPTYP*16        ! Type of transformation to add
      CHARACTER FOREXP( MAXEXP ) * ( GRP__SZNAM ) ! Forward expressions for MathMap
      CHARACTER INVEXP( MAXEXP ) * ( GRP__SZNAM ) ! Inverse expressions for MathMap
      DOUBLE PRECISION CENTRE( 2 ) ! Pincushion distortion centre
      DOUBLE PRECISION DET       ! Matrix determinant
      DOUBLE PRECISION DIAG( NDF__MXDIM ) ! Diagonal matrix elements
      DOUBLE PRECISION DISCO     ! Pincushion distortion coefficient
      DOUBLE PRECISION INA( NDF__MXDIM ) ! Corner "A" of window in input Frame
      DOUBLE PRECISION INB( NDF__MXDIM ) ! Corner "B" of window in input Frame
      DOUBLE PRECISION MATRIX( NDF__MXDIM*NDF__MXDIM ) ! Pure matrix (no offset)
      DOUBLE PRECISION MTEST( NDF__MXDIM*NDF__MXDIM ) ! Pure matrix (no offset)
      DOUBLE PRECISION OFFSET( NDF__MXDIM ) ! Pixel offset vector
      DOUBLE PRECISION OTEST( NDF__MXDIM )  ! Pixel offset vector
      DOUBLE PRECISION OUTA( NDF__MXDIM )! Corner "A" of window in output Frame
      DOUBLE PRECISION OUTB( NDF__MXDIM )! Corner "B" of window in output Frame
      DOUBLE PRECISION SHIFT( NDF__MXDIM ) ! Translation coefficients
      DOUBLE PRECISION TR( NDF__MXDIM*( NDF__MXDIM + 1 ) ) ! Mapping co-effs
      DOUBLE PRECISION ZOOM      ! Scaling factor for ZoomMap
      INTEGER ACTVAL             ! No. of transformation co-efficients supplied
      INTEGER AXES( NDF__MXDIM ) ! Axis selection array
      INTEGER FRMB               ! Pointer to basis Frame
      INTEGER FRMN               ! Pointer to new Frame
      INTEGER I                  ! General loop count
      INTEGER IBASIS             ! Index of basis Frame
      INTEGER IGRP               ! GRP group for MATHMAP expresssions
      INTEGER INDF               ! NDF identifier for NDF being modified
      INTEGER IWCS               ! Pointer to WCS FrameSet
      INTEGER J                  ! Column index
      INTEGER K                  ! Index within supplied list of co-efficients
      INTEGER L                  ! Index within vectorised matrix array
      INTEGER MAP                ! Pointer to old->new Mapping
      INTEGER MTRMAP             ! MatrixMap implied by given co-efficients
      INTEGER NAXB               ! No. of axes in basis Frame
      INTEGER NCOEF              ! Required no. of transformation co-efficients 
      INTEGER NEXP               ! Number of expressions got so far
      INTEGER NFEXP              ! Number of expressions for forward transforms
      INTEGER NIEXP              ! Number of expressions for inverse transforms
      INTEGER SING               ! Non-zero if matrix is singular
      INTEGER WINMAP             ! WinMap implied by given co-efficients
      INTEGER WORK( NDF__MXDIM ) ! Work space
      LOGICAL FIBOTH             ! Do we have both forward and inverse mappings?
      LOGICAL SIMPFI             ! SimpFI attribute of MathMap
      LOGICAL SIMPIF             ! SimpIF attribute of MathMap

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Begin an NDF context.
      CALL NDF_BEGIN

*  Get required information from NDF or parameters.
*  ================================================

*  Abort if an error has occurred.
      IF( STATUS .NE. SAI__OK ) GO TO 999

*  Obtain an identifier for the NDF to be modified.
      CALL LPG_ASSOC( 'NDF', 'UPDATE', INDF, STATUS )

*  If a null value was supplied annull the error and indicate that 
*  we have no ndf.
      IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         INDF = NDF__NOID

*  If we have no NDF we need to get the number of axes for the Mapping
*  from the user.
         CALL PAR_GDR0I( 'NAXES', -1, 1, VAL__MAXI, .FALSE., NAXB,
     :                   STATUS )

*  If we are adding a new Frame to a WCS FrameSet, we need to extract some 
*  information about the FrameSet.
      ELSE

*  Get the WCS FrameSet associated with the NDF.
         CALL KPG1_GTWCS( INDF, IWCS, STATUS )

*  Get the existing Frame which is to be used as the basis for the new Frame. 
*  The selected Frame becomes the Current Frame.
         CALL NDF_MSG( 'NDF', INDF )
         CALL KPG1_ASFRM( 'FRAME', 'EPOCH', IWCS, 'PIXEL', 'AXIS', 
     :                    .TRUE., '^NDF', STATUS )

*  Get its index, get a pointer to it, and save the number of axes in it.
         IBASIS = AST_GETI( IWCS, 'CURRENT', STATUS )
         FRMB = AST_GETFRAME( IWCS, AST__CURRENT, STATUS )
         NAXB = AST_GETI( FRMB, 'NAXES', STATUS )

*  Copy the basis Frame to create the new Frame.
         FRMN = AST_COPY( FRMB, STATUS ) 

*  Get the Domain for the new Frame. 
         CALL PAR_GET0C( 'DOMAIN', DOM, STATUS )

*  Remove spaces, and convert to upper case. 
         CALL CHR_RMBLK( DOM )
         CALL CHR_UCASE( DOM )

*  Store it in the new Frame.
         CALL AST_SETC( FRMN, 'DOMAIN', 
     :                  DOM( : MAX( 1, CHR_LEN( DOM ) ) ), STATUS )
      END IF

*  Construct the Mapping.
*  ======================

*  Get the type of Mapping which is to be used.
      CALL PAR_CHOIC( 'MAPTYPE', 'LINEAR', 'DIAGONAL,FILE,LINEAR,'//
     :                'MATH,PINCUSHION,SHIFT,UNIT,ZOOM', .FALSE.,
     :                MAPTYP, STATUS )
      IF ( STATUS .NE. SAI__OK ) GO TO 999

*  Create a MatrixMap from diagonal coefficients.
      IF ( MAPTYP .EQ. 'DIAGONAL' ) THEN

*  Get the coefficients.
         CALL PAR_EXACD( 'DIAG', NAXB, DIAG, STATUS )

*  Construct the MatrixMap.
         MAP = AST_MATRIXMAP( NAXB, NAXB, 1, DIAG, ' ', STATUS )

*  Use a Mapping stored in an external file.
      ELSE IF ( MAPTYP .EQ. 'FILE' ) THEN

*  Get the Mapping from the file named by the MAPIN parameter.
         CALL ATL1_GTOBJ( 'MAPIN', 'Mapping', AST_ISAMAPPING, MAP,
     :                    STATUS )

*  Create a Mapping representing a general linear transformation.
      ELSE IF ( MAPTYP .EQ. 'LINEAR' ) THEN

*  Get the co-efficients of the linear transformation from the basis
*  Frame to the new Frame. Ensure the exact required number are supplied.
         ACTVAL = 0
         NCOEF = ( NAXB + 1 )*NAXB
         DO WHILE( ACTVAL .NE. NCOEF .AND. STATUS .EQ. SAI__OK ) 
            CALL PAR_GET1D( 'TR', NCOEF, TR, ACTVAL, STATUS )
            IF( ACTVAL .NE. NCOEF .AND. STATUS .EQ. SAI__OK ) THEN
               CALL MSG_SETI( 'N', NCOEF )
               CALL MSG_OUT( 'WCSADD_MSG1', 'Please supply exactly '//
     :                       '^N co-efficient values (or a null '//
     :                       'value) for parameter %TR.', STATUS )
               CALL PAR_CANCL( 'TR', STATUS )
            END IF
         END DO

*  If a null value was given, annul the error and create a unit MatrixMap.
         IF( STATUS .EQ. PAR__NULL ) THEN
            CALL ERR_ANNUL( STATUS )
            MAP = AST_MATRIXMAP( NAXB, NAXB, 2, 0.0D0, ' ', STATUS ) 

*  Otherwise, if no error has occurred, extract the offset and matrix
*  from the supplied list of co-efficients.         
         ELSE

*  Extract the offset into a separate vector, making two copies.
            DO I = 1, NAXB
               OFFSET( I ) = TR( 1 + ( I - 1 )*( NAXB + 1 ) )
               OTEST( I ) = OFFSET( I )
            END DO

*  Extract the matrix into a separate vector, making two copies.
            K = 1
            L = 1
            DO I = 1, NAXB
               K = K + 1
   
               DO J = 1, NAXB
                  MATRIX( L ) = TR( K )
                  MTEST( L ) = TR( K )
                  L = L + 1
                  K = K + 1
               END DO
   
            END DO

*  See if the matrix is singular. The MTEST and OTEST arrays 
*  are changed by this call, This is why we took two copies above.
            CALL SLA_DMAT( NAXB, MTEST, OTEST, DET, SING, WORK )

*  Report an error if the matrix is singular.
            IF( SING .NE. 0 .AND. STATUS .EQ. SAI__OK ) THEN
               STATUS = SAI__ERROR
               CALL ERR_REP( 'WCSADD_ERR1', 'The supplied '//
     :                       'transformation matrix is singular, and '//
     :                       'therefore cannot be inverted.', STATUS )
            END IF

*  Create a MatrixMap from the supplied MATRIX array.
            MTRMAP = AST_MATRIXMAP( NAXB, NAXB, 0, MATRIX, ' ', STATUS )

*  Create a WinMap which gives the required shift of pixel origin. 
            DO I = 1, NAXB
               INA( I ) = 0.0D0 
               INB( I ) = MAX( ABS( OFFSET( I ) ), 1.0D0 )
               OUTA( I ) = INA( I ) + OFFSET( I )
               OUTB( I ) = INB( I ) + OFFSET( I )
            END DO

            WINMAP = AST_WINMAP( NAXB, INA, INB, OUTA, OUTB, ' ',
     :                           STATUS )

*  Concatenate these two mappings in series to get the mapping from the
*  basis Frame to the new Frame.
            MAP = AST_CMPMAP( MTRMAP, WINMAP, .TRUE., ' ', STATUS )

         END IF

*  Create a MathMap from algebraic expressions supplied by the user.
      ELSE IF ( MAPTYP .EQ. 'MATH' ) THEN
         
*  Get a GRP group holding the algebraic expressions for the forward 
*  transformation.
         IGRP = GRP__NOID
         CALL KPG1_GTGRP( 'FOREXP', IGRP, NFEXP, STATUS )
         DO WHILE( NFEXP .LT. NAXB .AND. STATUS .EQ. SAI__OK ) 
            CALL MSG_SETI( 'N', NAXB )
            CALL MSG_OUT( 'WCSADD_MSG2', 'At least ^N forward '//
     :                    'expressions are required - please enter '//
     :                    'them again.', STATUS )
            CALL PAR_CANCL( 'FOREXP', STATUS )
            CALL KPG1_GTGRP( 'FOREXP', IGRP, NFEXP, STATUS )
         END DO

*  Report an error if too many expressions were given.
         IF( NFEXP .GT. MAXEXP .AND. STATUS .EQ. SAI__OK ) THEN
            STATUS = SAI__ERROR
            CALL MSG_SETI( 'MX', MAXEXP )
            CALL MSG_SETI( 'N', NFEXP )
            CALL MSG_OUT( 'WCSADD_MSG3', 'Too many (^N) forward '//
     :                    'expressions given. No more than ^MX '//
     :                    'should be supplied.', STATUS )
         END IF

*  Copy the expressions into a local array.
         CALL GRP_GET( IGRP, 1, NFEXP, FOREXP, STATUS ) 

*  Similarly, get the algebraic expressions for the inverse transformation.
         CALL KPG1_GTGRP( 'INVEXP', IGRP, NIEXP, STATUS )
         DO WHILE( NIEXP .LT. NAXB .AND. STATUS .EQ. SAI__OK ) 
            CALL MSG_SETI( 'N', NAXB )
            CALL MSG_OUT( 'WCSADD_MSG4', 'At least ^N inverse '//
     :                    'expressions are required - please enter '//
     :                    'them again.', STATUS )
            CALL PAR_CANCL( 'INVEXP', STATUS )
            CALL KPG1_GTGRP( 'INVEXP', IGRP, NIEXP, STATUS )
         END DO

         IF( NIEXP .GT. MAXEXP .AND. STATUS .EQ. SAI__OK ) THEN
            STATUS = SAI__ERROR
            CALL MSG_SETI( 'MX', MAXEXP )
            CALL MSG_SETI( 'N', NIEXP )
            CALL MSG_OUT( 'WCSADD_MSG3', 'Too many (^N) inverse '//
     :                    'expressions given. No more than ^MX '//
     :                    'should be supplied.', STATUS )
         END IF

         CALL GRP_GET( IGRP, 1, NIEXP, INVEXP, STATUS ) 

*  Delete the group.
         CALL GRP_DELET( IGRP, STATUS )

*  See whether it looks as if non-dummy expressions have been supplied
*  for both forward and inverse transformations.  This is not foolproof,
*  but the consequences of getting it wrong are not serious.
         FIBOTH = INDEX( FOREXP( NFEXP ), '=' ) .NE. 0
     :      .AND. INDEX( INVEXP( NFEXP ), '=' ) .NE. 0

*  Get values of SimpFI and SimpIF attributes for mapping if a forward
*  and inverse transformations both exist.
         IF ( FIBOTH ) THEN
            CALL PAR_GET0L( 'SIMPFI', SIMPFI, STATUS )
            CALL PAR_GET0L( 'SIMPIF', SIMPIF, STATUS )
         ELSE
            SIMPFI = .FALSE.
            SIMPIF = .FALSE.
         END IF

*  Construct the mapping.
         MAP = AST_MATHMAP( NAXB, NAXB, NFEXP, FOREXP, NIEXP, INVEXP,
     :                      ' ', STATUS )

*  Add simplification attributes.
         CALL AST_SETL( MAP, 'SimpFI', SIMPFI, STATUS )
         CALL AST_SETL( MAP, 'SimpIF', SIMPIF, STATUS )

*  Create a PcdMap.
      ELSE IF ( MAPTYP .EQ. 'PINCUSHION' ) THEN

*  Check that the basis Frame has exactly two axes.
         IF ( NAXB .NE. 2 ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'WCSADD_ERR2', 'A pincushion distortion is '//
     :                    'valid on a 2-dimensional basis Frame.',
     :                    STATUS )
            GO TO 999
         END IF

*  Get the DISCO and CENTRE coefficients required for the Mapping.
         CALL PAR_GET0D( 'DISCO', DISCO, STATUS )
         CALL PAR_EXACD( 'CENTRE', 2, CENTRE, STATUS )

*  Construct the PcdMap.
         MAP = AST_PCDMAP( DISCO, CENTRE, ' ', STATUS )

*  Create a translated linear Mapping.
      ELSE IF ( MAPTYP .EQ. 'SHIFT' ) THEN

*  Get the coefficients for the translation.
         CALL PAR_EXACD( 'SHIFT', NAXB, SHIFT, STATUS )

*  Construct the corresponding WinMap.
         DO I = 1, NAXB
            INA( I ) = 0D0
            INB( I ) = 1D0
            OUTA( I ) = INA( I ) + SHIFT( I )
            OUTB( I ) = INB( I ) + SHIFT( I )
         END DO
         MAP = AST_WINMAP( NAXB, INA, INB, OUTA, OUTB, ' ', STATUS )

*  Create a UnitMap.
      ELSE IF ( MAPTYP .EQ. 'UNIT' ) THEN
         MAP = AST_UNITMAP( NAXB, ' ', STATUS )

*  Create a ZoomMap.
      ELSE IF ( MAPTYP .EQ. 'ZOOM' ) THEN
         CALL PAR_GET0D( 'ZOOM', ZOOM, STATUS )
         MAP = AST_ZOOMMAP( NAXB, ZOOM, ' ', STATUS )
      END IF

*  Simplify the Mapping
      MAP = AST_SIMPLIFY( MAP, STATUS )

*  Use the constructed Mapping.
*  ============================

*  Write the Mapping out to a text file. 
      IF( STATUS .NE. SAI__OK ) GO TO 999
      CALL ATL1_CREAT( 'MAPOUT', MAP, STATUS )

*  If a null value was supplied, annull the error
      IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
      
*  If we do not have an NDF, cancel the parameter and try once more to 
*  create an output file. We do this because the default value for
*  MAPOUT in the ifl file is a null.
         IF( INDF .EQ. NDF__NOID ) THEN
            CALL PAR_CANCL( 'MAPOUT', STATUS )
            CALL ATL1_CREAT( 'MAPOUT', MAP, STATUS )
         END IF
      END IF      
         
*  If we have an NDF, add the new Frame into the FrameSet, and store
*  the modified FrameSet in the NDF.
      IF( INDF .NE. NDF__NOID ) THEN 
         CALL AST_ADDFRAME( IWCS, IBASIS, MAP, FRMN, STATUS ) 
         CALL NDF_PTWCS( IWCS, INDF, STATUS )
      END IF

*  Tidy up.
*  ========
 999  CONTINUE

*  End the NDF context.
      CALL NDF_END( STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

*  If an error occurred, then report a contextual message.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'WCSADD_ERR3', 'WCSADD: Failed to add a new '//
     :                 'co-ordinate Frame into an NDF WCS component.',
     :                 STATUS )
      END IF

      END
