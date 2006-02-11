      SUBROUTINE NDFTRACE( STATUS )
*+
*  Name:
*     NDFTRACE

*  Purpose:
*     Displays the attributes of an NDF data structure.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL NDFTRACE( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This routine displays the attributes of an NDF data structure
*     including:
*
*     -  its name;
*     -  the values of its character components (title, label and
*     units);
*     -  its shape (pixel bounds, dimension sizes, number of dimensions
*     and total number of pixels);
*     -  axis co-ordinate information (axis labels, units and extents);
*     -  optionally, axis array attributes (type and storage form) and
*     the values of the axis normalisation flags;
*     -  attributes of the main data array and any other array
*     components present (including the type and storage form and an
*     indication of whether `bad' pixels may be present);
*     -  attributes of the current co-ordinate Frame in the WCS 
*     component (title, domain, and, optionally, axis labels and axis 
*     units, plus the system epoch and projection for sky co-ordinate 
*     Frames).  In addition the bounding box of the NDF within the Frame
*     is displayed.
*     -  optionally, attributes of all other co-ordinate Frames in the
*     WCS component.
*     -  a list of any NDF extensions present, together with their data
*     types; and
*     -  history information (creation and last-updated dates, the
*     update mode and the number of history records).
*
*     Most of this information is output to parameters.

*  Usage:
*     ndftrace ndf

*  ADAM Parameters:
*     AEND( ) = _DOUBLE (Write)
*        The axis upper extents of the NDF.  For non-monotonic axes,
*        zero is used.  See parameter AMONO.  This is not assigned if
*        AXIS is FALSE.
*     AFORM( ) = LITERAL (Write)
*        The storage forms of the axis centres of the NDF.  This is
*        only written when FULLAXIS is TRUE and AXIS is TRUE.
*     ALABEL( ) = LITERAL (Write)
*        The axis labels of the NDF.  This is not assigned if AXIS is
*        FALSE.
*     AMONO( ) = _LOGICAL (Write)
*        These are TRUE when the axis centres are monotonic, and FALSE
*        otherwise.  This is not assigned if AXIS is FALSE.
*     ANORM( ) = _LOGICAL (Write)
*        The axis normalisation flags of the NDF.  This is only written
*        when FULLAXIS is TRUE and AXIS is TRUE.
*     ASTART( ) = _DOUBLE (Write)
*        The axis lower extents of the NDF.  For non-monotonic axes,
*        zero is used.  See parameter AMONO.  This is not assigned if
*        AXIS is FALSE.
*     ATYPE( ) = LITERAL (Write)
*        The data types of the axis centres of the NDF.  This is only
*        written when FULLAXIS is TRUE and AXIS is TRUE.
*     AUNITS( ) = LITERAL (Write)
*        The axis units of the NDF.  This is not assigned if AXIS is
*        FALSE.
*     AVARIANCE( ) = _LOGICAL (Write)
*        Whether or not there are axis variance arrays present in the
*        NDF.  This is only written when FULLAXIS is TRUE and AXIS is
*        TRUE.
*     AXIS = _LOGICAL (Write)
*        Whether or not the NDF has an axis system.
*     BAD = _LOGICAL (Write)
*        If TRUE, the NDF's data array may contain bad values.
*     BADBITS = LITERAL (Write)
*        The BADBITS mask.  This is only valid when QUALITY is TRUE.
*     CURRENT = _INTEGER (Write)
*        The integer Frame index of the current co-ordinate Frame in the
*        WCS component.
*     DIMS( ) = _INTEGER (Write)
*        The dimensions of the NDF.
*     EXTNAME( ) = LITERAL (Write)
*        The names of the extensions in the NDF.  It is only written
*        when NEXTN is positive.
*     EXTTYPE( ) = LITERAL (Write)
*        The types of the extensions in the NDF.  Their order
*        corresponds to the names in EXTNAME.  It is only written when
*        NEXTN is positive.
*     FDIM( ) = _INTEGER (Write)
*        The numbers of axes in each co-ordinate Frame stored in the WCS
*        component of the NDF.  The elements in this parameter 
*        correspond to those in the FDOMAIN and FTITLE parameters.  The
*        number of elements in each of these parameters is given by
*        NFRAME.
*     FDOMAIN( ) = LITERAL (Write)
*        The domain of each co-ordinate Frame stored in the WCS
*        component of the NDF.  The elements in this parameter
*        correspond to those in the FDIM and FTITLE parameters.  The 
*        number of elements in each of these parameters is given by
*        NFRAME.
*     FLABEL( ) = LITERAL (Write)
*        The axis labels from the current WCS Frame of the NDF.  
*     FLBND( ) = _DOUBLE (Write)
*        The lower bounds of the bounding box enclosing the NDF in the
*        current WCS Frame.  The number of elements in this parameter is
*        equal to the number of axes in the current WCS Frame (see 
*        FDIM).  Celestial axis values will be in units of radians.
*     FUBND( ) = _DOUBLE (Write)
*        The upper bounds of the bounding box enclosing the NDF in the
*        current WCS Frame.  The number of elements in this parameter is
*        equal to the number of axes in the current WCS Frame (see 
*        FDIM).  Celestial axis values will be in units of radians.
*     FORM = LITERAL (Write)
*        The storage form of the NDF's data array.
*     FTITLE( ) = LITERAL (Write)
*        The title of each co-ordinate Frame stored in the WCS component
*        of the NDF.  The elements in this parameter correspond to those
*        in the FDOMAIN and FDIM parameters.  The number of elements in
*        each of these parameters is given by NFRAME.
*     FULLAXIS = _LOGICAL (Read)
*        If the NDF being examined has an axis co-ordinate system
*        defined, then by default only the label, units and extent of
*        each axis will be displayed.  However, if a TRUE value is given
*        for this parameter, full details of the attributes of all the
*        axis arrays will also be given. [FALSE]
*     FULLFRAME = _LOGICAL (Read)
*        If a FALSE value is given for this parameter then only the
*        Title and Domain attributes plus the axis labels and units are 
*        displayed for a co-ordinate Frame.  Otherwise, a more complete 
*        description is given, including the bounds of the NDF within
*        the Frame. [FALSE]
*     FULLWCS = _LOGICAL (Read)
*        If a TRUE value is given for this parameter then all
*        co-ordinate Frames in the WCS component of the NDF are
*        displayed.  Otherwise, only the current co-ordinate Frame is 
*        displayed. [FALSE]
*     FUNIT( ) = LITERAL (Write)
*        The axis units from the current WCS Frame of the NDF.  
*     HISTORY = _LOGICAL (Write)
*        Whether or not the NDF contains HISTORY records.
*     LABEL = LITERAL (Write)
*        The label of the NDF.
*     LBOUND( ) = _INTEGER (Write)
*        The lower bounds of the NDF.
*     NDF = NDF (Read)
*        The NDF data structure whose attributes are to be displayed.
*     NDIM = _INTEGER (Write)
*        The number of dimensions of the NDF.
*     NEXTN = _INTEGER (Write)
*        The number of extensions in the NDF.
*     NFRAME = _INTEGER (Write)
*        The number of WCS Frames described by parameters FDIM, FDOMAIN
*        and FTITLE.  Set to zero if WCS is FALSE. 
*     QUALITY = _LOGICAL (Write)
*        Whether or not the NDF contains a QUALITY array.
*     QUIET = _LOGICAL (Read)
*        A TRUE value suppresses the reporting of the NDF's attributes.
*        It is intended for procedures and scripts where only the
*        output parameters are needed. [FALSE]
*     TITLE = LITERAL (Write)
*        The title of the NDF.
*     TYPE = LITERAL (Write)
*        The data type of the NDF's data array.
*     UBOUND( ) = _INTEGER (Write)
*        The upper bounds of the NDF.
*     UNITS = LITERAL (Write)
*        The units of the NDF.
*     VARIANCE = _LOGICAL (Write)
*        Whether or not the NDF contains a VARIANCE array.
*     WCS = _LOGICAL (Write)
*        Whether or not the NDF has any WCS co-ordinate Frames, over
*        and above the default GRID, PIXEL and AXIS Frames.
*     WIDTH( ) = _LOGICAL (Write)
*        Whether or not there are axis width arrays present in the NDF.
*        This is only written when FULLAXIS is TRUE and AXIS is TRUE.

*  Notes:
*     -  If the WCS component of the NDF is undefined, then an attempt 
*     is made to find WCS information from two other sources: first, an 
*     IRAS90 astrometry structure, and second, the FITS extension.  If 
*     either of these sources yield usable WCS information, then it is
*     displayed in the same way as the NDF WCS component.  Other KAPPA
*     applications will use this WCS information as if it were stored in
*     the WCS component.

*  Examples:
*     ndftrace mydata
*        Displays information about the attributes of the NDF structure
*        called mydata.
*     ndftrace ndf=r106 fullaxis
*        Displays information about the NDF structure r106, including
*        full details of any axis arrays present.
*     ndftrace mydata quiet ndim=(mdim)
*        Passes the number of dimensions of the NDF called mydata
*        into the ICL variable mdim.  No information is displayed.

*  Related Applications:
*     KAPPA: WCSFRAME; HDSTRACE

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK)
*     MJC: Malcolm J. Currie (STARLINK)
*     DSB: David S. Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     PWD: Peter W. Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1990 April 6 (RFWS):
*        Original version.
*     1991 April 29 (RFWS):
*        Added support for axis components and added the usage and
*        examples sections to the prologue.
*     1992 November 30 (MJC):
*        Reports non-monotonic axis centres.
*     1993 February 4 (MJC):
*        Fixed bug that caused incorrect axis extents to be reported
*        when there were no axis-width arrays and the axis centres did
*        not increment by one.
*     1994 July 29 (RFWS):
*        Adapted to handle history information.
*     1995 April 24 (MJC):
*        Made usage and examples lowercase.  Added Related Applications.
*        Added History to the Description.  Sorted the variable
*        declarations and other tidying.
*     1995 June 18 (MJC):
*        Added QUIET option and the output parameters.
*     27-NOV-1997 (DSB):
*        Added support for WCS component.
*     7-SEP-1999 (DSB):
*        Replaced ERR_MARK/RLSE by ERR_BEGIN/END.
*     17-MAR-2000 (DSB):
*        Corrected value written to parameter "WCS".
*     20-MAR-2000 (DSB):
*        Normalize displayed first pixel centre in current WCS Frame.
*     10-JAN-2003 (DSB):
*        Modified to display details of WCS SpecFrames.
*     2004 September 3 (TIMJ):
*        Use CNF_PVAL
*     30-SEP-2004 (PWD):
*        Moved CNF_PAR out of executable code.
*     16-MAR-2005 (DSB):
*        Only write AXIS-related output parameters if the NDF has an 
*        AXIS structure.
*     17-MAR-2005 (DSB):
*        Added FLBND and FUBND.
*     21-MAR-2005 (DSB):
*        Added FLABEL and FUNIT.
*     31-JAN-2006 (TIMJ):
*        Extension type (XTYPE) must be declared as DAT__SZTYP and not
*        NDF__SZTYP (NDF__SZTYP is for a numeric type of an NDF).
*     2006 February 10 (MJC)
*        Wrap lines at 72.  English spelling.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ constants
      INCLUDE 'NDF_PAR'          ! NDF_ public constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT primitive data constants
      INCLUDE 'AST_PAR'          ! AST_ public constants
      INCLUDE 'CNF_PAR'          ! CNF functions

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      INTEGER MXEXTN             ! Maximum number of extensions
      PARAMETER ( MXEXTN = 32 )

      INTEGER MXFRM              ! Maximum number of WCS Frames
      PARAMETER ( MXFRM = 32 )

*  Local Variables:
      BYTE BADBIT                ! Bad-bits mask
      CHARACTER * ( 35 ) APPN    ! Last recorded application name
      CHARACTER * ( 15 ) ATTRIB  ! AST attribute name
      CHARACTER * ( 8 ) BINSTR   ! Binary bad-bits mask string
      CHARACTER * ( 80 ) ALABEL( NDF__MXDIM ) ! Axis label
      CHARACTER * ( 80 ) AUNITS( NDF__MXDIM ) ! Axis units
      CHARACTER * ( 80 ) CCOMP   ! Character component
      CHARACTER * ( 80 ) FLABEL( NDF__MXDIM ) ! WCS axis label
      CHARACTER * ( 80 ) FUNIT( NDF__MXDIM ) ! WCS axis units
      CHARACTER * ( 80 ) FRMDMN  ! Frame domain
      CHARACTER * ( 80 ) FRMTTL  ! Frame title
      CHARACTER * ( 80 ) WCSDMN( MXFRM )  ! Frame domains
      CHARACTER * ( 80 ) WCSTTL( MXFRM )  ! Frame titles
      CHARACTER * ( DAT__SZLOC ) XLOC ! Extension locator
      CHARACTER * ( DAT__SZTYP ) TYPE ! Data type
      CHARACTER * ( NDF__MXDIM * ( 2 * VAL__SZI + 3 ) - 2 ) BUF ! Text 
                                 ! buffer for shape information
      CHARACTER * ( NDF__SZFRM ) CFORM( NDF__MXDIM ) ! Type for axis 
                                 ! centres 
      CHARACTER * ( NDF__SZFRM ) FORM ! Storage form
      CHARACTER * ( NDF__SZFTP ) FTYPE ! Full data type
      CHARACTER * ( NDF__SZHDT ) CREAT ! History component creation date
      CHARACTER * ( NDF__SZHDT ) DATE ! Date of last history update
      CHARACTER * ( NDF__SZHUM ) HMODE ! History update mode
      CHARACTER * ( NDF__SZTYP ) ATYPE ! Type for axis extent value
      CHARACTER * ( NDF__SZTYP ) CTYPE( NDF__MXDIM ) ! Type for axis 
                                 ! centres 
      CHARACTER * ( DAT__SZTYP ) XTYPE( MXEXTN ) ! Extension name
      CHARACTER * ( NDF__SZXNM ) XNAME( MXEXTN ) ! Extension name
      DOUBLE PRECISION AEND( NDF__MXDIM )  ! End of NDF extent along an
                                 ! axis
      DOUBLE PRECISION ASTART( NDF__MXDIM )! Start of NDF extent along 
                                 ! an axis
      DOUBLE PRECISION GFIRST( 1, NDF__MXDIM ) ! GRID coords of first
                                 ! pixel
      DOUBLE PRECISION LBIN( NDF__MXDIM )  ! Lower GRID bounds
      DOUBLE PRECISION LBOUT( NDF__MXDIM ) ! Lower WCS bounds
      DOUBLE PRECISION UBIN( NDF__MXDIM )  ! Upper GRID bounds
      DOUBLE PRECISION UBOUT( NDF__MXDIM ) ! Upper WCS bounds
      DOUBLE PRECISION XL( NDF__MXDIM ) ! GRID position at lower limit
      DOUBLE PRECISION XU( NDF__MXDIM ) ! GRID position at upper limit
      INTEGER AXPNTR( 1 )        ! Pointer to axis centres
      INTEGER BBI                ! Bad-bits value as an integer
      INTEGER DIGVAL             ! Binary digit value
      INTEGER DIM( NDF__MXDIM )  ! Dimension sizes
      INTEGER EL                 ! Number of array elements mapped
      INTEGER FRMNAX             ! Frame dimensionality
      INTEGER I                  ! Loop counter for dimensions
      INTEGER IAT                ! Used length of string
      INTEGER IAXIS              ! Loop counter for axes
      INTEGER ICURR              ! Index of Current Frame in WCS 
                                 ! FrameSet
      INTEGER IDIG               ! Loop counter for binary digits
      INTEGER IEXTN              ! Extension index
      INTEGER IFRAME             ! Frame index
      INTEGER INDF               ! NDF identifier
      INTEGER IWCS               ! AST identifier for NDF's WCS FrameSet
      INTEGER LBND( NDF__MXDIM ) ! Lower pixel-index bounds
      INTEGER MAP                ! AST Mapping from GRID to current WCS 
                                 ! Frame
      INTEGER N                  ! Loop counter for extensions
      INTEGER NC                 ! Character count
      INTEGER NDIM               ! Number of dimensions
      INTEGER NEXTN              ! Number of extensions
      INTEGER NFRAME             ! Total number of WCS Frames
      INTEGER NFRM               ! Indexof next WCS Frame
      INTEGER NREC               ! Number of history records
      INTEGER PNTR( 2 )          ! Pointers to axis elements
      INTEGER SIZE               ! Total number of pixels
      INTEGER UBND( NDF__MXDIM ) ! Upper pixel-index bounds
      INTEGER WCSNAX( MXFRM )    ! Frame dimensionalities
      LOGICAL AVAR( NDF__MXDIM ) ! NDF axis-variance components defined?
      LOGICAL BAD                ! Bad pixel flag
      LOGICAL FULLAX             ! Display full axis information?
      LOGICAL FULLFR             ! Display more details for each WCS 
                                 ! Frame?
      LOGICAL FULLWC             ! Display full WCS information?
      LOGICAL MONOTO( NDF__MXDIM ) ! Axis monotonic flags
      LOGICAL NORM( NDF__MXDIM ) ! Axis normalisation flags
      LOGICAL QUIET              ! Do not report the trace?
      LOGICAL REPORT             ! Report the trace?
      LOGICAL THERE              ! NDF component is defined?
      LOGICAL WIDTH( NDF__MXDIM ) ! NDF axis-width components defined?

*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM_ type conversion routines
      INCLUDE 'NUM_DEF_CVT'
*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Obtain an identifier for the NDF structure to be examined.
      CALL LPG_ASSOC( 'NDF', 'READ', INDF, STATUS )

*  See if full axis information is to be obtained.
      CALL PAR_GET0L( 'FULLAXIS', FULLAX, STATUS )

*  See if full WCS information is to be obtained.
      CALL PAR_GET0L( 'FULLWCS', FULLWC, STATUS )

*  See if WCS Frames are to be displayed in fully, or in breif.
      CALL PAR_GET0L( 'FULLFRAME', FULLFR, STATUS )

*  See if any information is to be displayed.
      CALL PAR_GET0L( 'QUIET', QUIET, STATUS )
      REPORT = .NOT. QUIET

*  Display the NDF's name.
      IF ( REPORT ) THEN
         CALL MSG_BLANK( STATUS )
         CALL NDF_MSG( 'NDF', INDF )
         CALL MSG_OUT( 'HEADER', '   NDF structure ^NDF:', STATUS )
      END IF


*  Character components:
*  =====================
*  See if the title component is defined.  If so, then display its
*  value.
      CALL NDF_STATE( INDF, 'Title', THERE, STATUS )
      IF ( THERE ) THEN
         CALL NDF_CGET( INDF, 'Title', CCOMP, STATUS )
         IF ( REPORT ) THEN
            CALL MSG_SETC( 'TITLE', CCOMP )
            CALL MSG_OUT( 'M_TITLE', '      Title:  ^TITLE', STATUS )
         END IF
      ELSE
         CCOMP = ' '
      END IF

*  Write the title to the output parameter.
      CALL PAR_PUT0C( 'TITLE', CCOMP, STATUS )

*  See if the label component is defined.  If so, then display its
*  value.
      CALL NDF_STATE( INDF, 'Label', THERE, STATUS )
      IF ( THERE ) THEN
         CALL NDF_CGET( INDF, 'Label', CCOMP, STATUS )
         IF ( REPORT ) THEN
            CALL MSG_SETC( 'LABEL', CCOMP )
            CALL MSG_OUT( 'M_LABEL', '      Label:  ^LABEL', STATUS )
         END IF
      ELSE
         CCOMP = ' '
      END IF

*  Write the label to the output parameter.
      CALL PAR_PUT0C( 'LABEL', CCOMP, STATUS )

*  See if the units component is defined.  If so, then display its
*  value.
      CALL NDF_STATE( INDF, 'Units', THERE, STATUS )
      IF ( THERE ) THEN
         CALL NDF_CGET( INDF, 'Units', CCOMP, STATUS )
         IF ( REPORT ) THEN
            CALL MSG_SETC( 'UNITS', CCOMP )
            CALL MSG_OUT( 'M_UNITS', '      Units:  ^UNITS', STATUS )
         END IF
      ELSE
         CCOMP = ' '
      END IF

*  Write the units to the output parameter.
      CALL PAR_PUT0C( 'UNITS', CCOMP, STATUS )


*  NDF shape:
*  ==========
*  Obtain the dimension sizes.
      CALL NDF_DIM( INDF, NDF__MXDIM, DIM, NDIM, STATUS )

*  Display a header for this information.
      IF ( REPORT ) THEN
         CALL MSG_BLANK( STATUS )
         CALL MSG_OUT( 'SHAPE_HEADER', '   Shape:', STATUS )

*  Display the number of dimensions.
         CALL MSG_SETI( 'NDIM', NDIM )
         CALL MSG_OUT( 'DIMENSIONALITY',
     :     '      No. of dimensions:  ^NDIM', STATUS )

*  Construct a string showing the dimension sizes.
         IF ( STATUS .EQ. SAI__OK ) THEN
            NC = 0
            DO 1 I = 1, NDIM
               IF ( I .GT. 1 ) CALL CHR_PUTC( ' x ', BUF, NC )
               CALL CHR_PUTI( DIM( I ), BUF, NC )
    1       CONTINUE
            CALL MSG_SETC( 'DIMS', BUF( : NC ) )
         END IF

*  Display the dimension size information.
         CALL MSG_OUT( 'DIMENSIONS',
     :     '      Dimension size(s):  ^DIMS', STATUS )
      END IF

*  Output the dimensionality.
      CALL PAR_PUT0I( 'NDIM', NDIM, STATUS )

*  Obtain the pixel-index bounds.
      CALL NDF_BOUND( INDF, NDF__MXDIM, LBND, UBND, NDIM, STATUS )

*  Construct a string showing the pixel-index bounds.
      IF ( REPORT ) THEN
         IF ( STATUS .EQ. SAI__OK ) THEN
            NC = 0
            DO 2 I = 1, NDIM
               IF ( I .GT. 1 ) CALL CHR_PUTC( ', ', BUF, NC )
               CALL CHR_PUTI( LBND( I ), BUF, NC )
               CALL CHR_PUTC( ':', BUF, NC )
               CALL CHR_PUTI( UBND( I ), BUF, NC )
    2       CONTINUE
            CALL MSG_SETC( 'BNDS', BUF( : NC ) )
         END IF

*  Display the pixel-index bounds information.
         CALL MSG_OUT( 'BOUNDS',
     :     '      Pixel bounds     :  ^BNDS', STATUS )
      END IF

*  Output the dimensions and bounds.
      CALL PAR_PUT1I( 'DIMS', NDIM, DIM, STATUS )
      CALL PAR_PUT1I( 'LBOUND', NDIM, LBND, STATUS )
      CALL PAR_PUT1I( 'UBOUND', NDIM, UBND, STATUS )

*  Obtain the NDF size and display this information.
      IF ( REPORT ) THEN
         CALL NDF_SIZE( INDF, SIZE, STATUS )
         CALL MSG_SETI( 'SIZE', SIZE )
         CALL MSG_OUT( 'SIZE',
     :     '      Total pixels     :  ^SIZE ', STATUS )
      END IF

*  Axis component:
*  ===============
*  See if the axis co-ordinate system is defined. If so, then display a
*  header for it.  Set the AXIS output parameter.
      CALL NDF_STATE( INDF, 'Axis', THERE, STATUS )
      CALL PAR_PUT0L( 'AXIS', THERE, STATUS )

      IF ( THERE ) THEN
         IF ( REPORT ) THEN
            CALL MSG_BLANK( STATUS )
            CALL MSG_OUT( 'AXIS_HEADER', '   Axes:', STATUS )
         END IF

*  Loop to display information for each NDF axis, starting with a
*  heading showing the axis number.
         DO 3 IAXIS = 1, NDIM
            IF ( REPORT ) THEN
               CALL MSG_SETI( 'IAXIS', IAXIS )
               CALL MSG_OUT( 'AXIS_NUMBER',
     :            '      Axis ^IAXIS:', STATUS )
            END IF

*  Obtain the label for the axis and display it.  Note that since the
*  values must be written to output parameters, a call to NDF_ACMSG is
*  inadequate.
            CALL NDF_ASTAT( INDF, 'Label', IAXIS, THERE, STATUS )
            IF ( THERE ) THEN
               CALL NDF_ACGET( INDF, 'Label', IAXIS, ALABEL( IAXIS ),
     :                         STATUS )

               IF ( REPORT ) THEN
                  CALL MSG_SETC( 'LABEL', ALABEL( IAXIS ) )
                  CALL MSG_OUT( 'AXIS_LABEL',
     :              '         Label : ^LABEL', STATUS )
               END IF
            ELSE
               ALABEL( IAXIS ) = ' '
            END IF

*  Obtain the units for the axis and display it.  Note that since the
*  values must be written to output parameters, a call to NDF_ACMSG is
*  inadequate.
            CALL NDF_ASTAT( INDF, 'Units', IAXIS, THERE, STATUS )
            IF ( THERE ) THEN
               CALL NDF_ACGET( INDF, 'Units', IAXIS, AUNITS( IAXIS ),
     :                         STATUS )

               IF ( REPORT ) THEN
                  CALL MSG_SETC( 'UNITS', AUNITS( IAXIS ) )
                  CALL MSG_OUT( 'AXIS_UNITS',
     :              '         Units : ^UNITS', STATUS )
               END IF
            ELSE
               AUNITS( IAXIS ) = ' '
            END IF


*  Axis Extent:
*  ============

*  First check for monotonic axis centre values.  Map the axis centre
*  array, using double precision to prevent loss of precision.
            CALL NDF_AMAP( INDF, 'Centre', IAXIS, '_DOUBLE',
     :                     'READ', AXPNTR, EL, STATUS )

*  Are all the axes monotonic?  Start a new error context so that the
*  error reports concerning a non-monotonic axis may be annulled.
*  Instead we issue a warning message so that the application can
*  continue by using world co-ordinates.
            CALL ERR_BEGIN( STATUS )
            CALL KPG1_MONOD( .TRUE., EL, 
     :                       %VAL( CNF_PVAL( AXPNTR( 1 ) ) ),
     :                       MONOTO( IAXIS ), STATUS )
            IF ( STATUS .NE. SAI__OK ) THEN
               CALL ERR_ANNUL( STATUS )
               MONOTO( IAXIS ) = .FALSE.
            END IF
            CALL ERR_END( STATUS )

*  Unmap the axis.
            CALL NDF_AUNMP( INDF, 'Centre', IAXIS, STATUS )

*  Report a non-monotonic axis.
            IF ( .NOT. MONOTO( IAXIS ) ) THEN
               IF ( REPORT ) CALL MSG_OUT( 'AXIS_EXTENT',
     :           '         Extent: Non-monotonic', STATUS )
            ELSE

*  Map the axis centre and width arrays and use them to determine the
*  overall extent of the NDF along the current axis.  Unmap the arrays
*  afterwards.
               CALL NDF_AMAP( INDF, 'Centre,Width', IAXIS, '_DOUBLE',
     :                        'READ', PNTR, EL, STATUS )
               CALL KPG1_AXRNG( EL, %VAL( CNF_PVAL( PNTR( 1 ) ) ),
     :                          %VAL( CNF_PVAL( PNTR( 2 ) ) ), 
     :                          ASTART( IAXIS ),
     :                          AEND( IAXIS ), STATUS )
               CALL NDF_AUNMP( INDF, 'Centre,Width', IAXIS, STATUS )

*  Determine the numeric type which should be used to display the NDF's
*  extent and define message tokens appropriately.
               CALL NDF_ATYPE( INDF, 'Centre,Width', IAXIS, ATYPE,
     :                         STATUS )
               IF ( REPORT ) THEN
                  IF ( ATYPE .EQ. '_DOUBLE' ) THEN
                     CALL MSG_SETD( 'ASTART', ASTART( IAXIS ) )
                     CALL MSG_SETD( 'AEND', AEND( IAXIS ) )
                  ELSE
                     CALL MSG_SETR( 'ASTART', SNGL( ASTART( IAXIS ) ) )
                     CALL MSG_SETR( 'AEND', SNGL( AEND( IAXIS ) ) )
                  END IF

*  Display the NDF's extent.
                  CALL MSG_OUT( 'AXIS_EXTENT',
     :              '         Extent: ^ASTART to ^AEND', STATUS )
               END IF
            END IF


*  Axis Centre Array:
*  ==================
*  If full axis information is to be displayed, then obtain the axis
*  centre array attributes.
            IF ( FULLAX ) THEN
               CALL NDF_ATYPE( INDF, 'Centre', IAXIS, CTYPE( IAXIS ),
     :                         STATUS )
               CALL NDF_AFORM( INDF, 'Centre', IAXIS, CFORM( IAXIS ),
     :                         STATUS )

*  Display the axis centre array attributes.
               IF ( REPORT ) THEN
                  CALL MSG_BLANK( STATUS )
                  CALL MSG_OUT( 'AXISC_HEADER',
     :              '            Centre Array:', STATUS )
                  CALL MSG_SETC( 'TYPE', CTYPE( IAXIS ) )
                  CALL MSG_OUT( 'AXISC_TYPE',
     :              '               Type        :  ^TYPE', STATUS )
                  CALL MSG_SETC( 'FORM', CFORM( IAXIS ) )
                  CALL MSG_OUT( 'AXISC_FORM',
     :              '               Storage form:  ^FORM', STATUS )
               END IF


*  Axis Normalisation Flag:
*  ========================
*  Obtain and display the axis normalisation flag.
               CALL NDF_ANORM( INDF, IAXIS, NORM( IAXIS ), STATUS )
               IF ( REPORT ) THEN
                  CALL MSG_SETL( 'NORM', NORM( IAXIS ) )
                  CALL MSG_OUT( 'AXIS_NORM',
     :              '            Normalisation Flag: ^NORM', STATUS )
               END IF


*  Axis Width Array:
*  =================
*  See whether or not the axis width array is defined.  If it is, then 
*  obtain its attributes.
               CALL NDF_ASTAT( INDF, 'Width', IAXIS, WIDTH( IAXIS ),
     :                         STATUS )
               IF ( THERE ) THEN
                  CALL NDF_ATYPE( INDF, 'Width', IAXIS, TYPE, STATUS )
                  CALL NDF_AFORM( INDF, 'Width', IAXIS, FORM, STATUS )

*  Display the axis width attributes.
                  IF ( REPORT ) THEN
                     CALL MSG_BLANK( STATUS )
                     CALL MSG_OUT( 'AXISW_HEADER',
     :                 '            Width Array:', STATUS )
                     CALL MSG_SETC( 'TYPE', TYPE )
                     CALL MSG_OUT( 'AXISW_TYPE',
     :                 '               Type        :  ^TYPE', STATUS )
                     CALL MSG_SETC( 'FORM', FORM )
                     CALL MSG_OUT( 'AXISW_FORM',
     :                 '               Storage form:  ^FORM', STATUS )
                  END IF
               END IF


*  Axis Variance Array:
*  ====================
*  See whether the axis variance array is defined. If so, then obtain
*  its attributes.
               CALL NDF_ASTAT( INDF, 'Variance', IAXIS, AVAR( IAXIS ),
     :                         STATUS )
               IF ( THERE ) THEN
                  CALL NDF_ATYPE( INDF, 'Variance', IAXIS, TYPE,
     :                            STATUS )
                  CALL NDF_AFORM( INDF, 'Variance', IAXIS, FORM,
     :                            STATUS )

*  Display the axis variance attributes.
                  IF ( REPORT ) THEN
                     CALL MSG_BLANK( STATUS )
                     CALL MSG_OUT( 'AXISV_HEADER',
     :                 '            Variance Array:', STATUS )
                     CALL MSG_SETC( 'TYPE', TYPE )
                     CALL MSG_OUT( 'AXISV_TYPE',
     :                 '               Type        :  ^TYPE', STATUS )
                     CALL MSG_SETC( 'FORM', FORM )
                     CALL MSG_OUT( 'AXISV_FORM',
     :                 '               Storage form:  ^FORM', STATUS )
                  END IF
               END IF
            END IF

*  Add a spacing line after the information for each axis.
            IF ( IAXIS .NE. NDIM .AND. REPORT ) CALL MSG_BLANK( STATUS )
    3    CONTINUE

*  Write the output axis parameters.
         CALL PAR_PUT1D( 'AEND', NDIM, AEND, STATUS )
         CALL PAR_PUT1C( 'ALABEL', NDIM, ALABEL, STATUS )
         CALL PAR_PUT1D( 'ASTART', NDIM, ASTART, STATUS )
         CALL PAR_PUT1C( 'AUNITS', NDIM, AUNITS, STATUS )
         IF ( FULLAX ) THEN
            CALL PAR_PUT1C( 'AFORM', NDIM, CFORM, STATUS )
            CALL PAR_PUT1L( 'AMONO', NDIM, MONOTO, STATUS )
            CALL PAR_PUT1L( 'ANORM', NDIM, NORM, STATUS )
            CALL PAR_PUT1C( 'ATYPE', NDIM, CTYPE, STATUS )
            CALL PAR_PUT1L( 'AVARIANCE', NDIM, AVAR, STATUS )
            CALL PAR_PUT1L( 'WIDTH', NDIM, WIDTH, STATUS )
         END IF

      END IF

*  Data component:
*  ===============
*  Obtain the data component attributes.
      CALL NDF_FTYPE( INDF, 'Data', FTYPE, STATUS )
      CALL NDF_FORM( INDF, 'Data', FORM, STATUS )

*  Output the values to parameters.
      CALL PAR_PUT0C( 'TYPE', FTYPE, STATUS )
      CALL PAR_PUT0C( 'FORM', FORM, STATUS )

*  Display the data component attributes.
      IF ( REPORT ) THEN
         CALL MSG_BLANK( STATUS )
         CALL MSG_OUT( 'DATA_HEADER', '   Data Component:', STATUS )
         CALL MSG_SETC( 'FTYPE', FTYPE )
         CALL MSG_OUT( 'DATA_TYPE', '      Type        :  ^FTYPE',
     :                 STATUS )
         CALL MSG_SETC( 'FORM', FORM )
         CALL MSG_OUT( 'DATA_FORM', '      Storage form:  ^FORM',
     :                 STATUS )
      END IF

*  Determine if the data values are defined. Issue a warning message if
*  they are not.
      CALL NDF_STATE( INDF, 'Data', THERE, STATUS )
      IF ( .NOT. THERE ) THEN
         IF ( REPORT ) THEN
            CALL MSG_OUT( 'DATA_UNDEF',
     :        '      WARNING: the Data component values are not '/
     :        /'defined', STATUS )
         END IF

*  Disable automatic quality masking and see if the data component may
*  contain bad pixels.  If so, then display an appropriate message.
      ELSE
         CALL NDF_SQMF( .FALSE., INDF, STATUS )
         CALL NDF_BAD( INDF, 'Data', .FALSE., BAD, STATUS )
         IF ( BAD ) THEN
            IF ( REPORT ) THEN
               CALL MSG_OUT( 'DATA_ISBAD',
     :           '      Bad pixels may be present', STATUS )
            END IF

*  If there were no bad pixels present, then re-enable quality masking
*  and test again.  Issue an appropriate message.
         ELSE
            CALL NDF_SQMF( .TRUE., INDF, STATUS )
            CALL NDF_BAD( INDF, 'Data', .FALSE., BAD, STATUS )
            IF ( REPORT ) THEN
               IF ( .NOT. BAD ) THEN
                  CALL MSG_OUT( 'DATA_NOBAD',
     :              '      There are no bad pixels present', STATUS )
               ELSE
                  CALL MSG_OUT( 'DATA_QBAD',
     :            '      Bad pixels may be introduced via the Quality '/
     :            /'component', STATUS )
               END IF
            END IF

         END IF

*  Set the output parameter.
         CALL PAR_PUT0L( 'BAD', BAD, STATUS )
      END IF


*  Variance component:
*  ===================
*  See if the variance component is defined.  If so, then obtain its
*  attributes.  Indicate its presence or otherwise through the output
*  parameter.
      CALL NDF_STATE( INDF, 'Variance', THERE, STATUS )
      CALL PAR_PUT0L( 'VARIANCE', THERE, STATUS )
      IF ( THERE ) THEN
         CALL NDF_FTYPE( INDF, 'Variance', FTYPE, STATUS )
         CALL NDF_FORM( INDF, 'Variance', FORM, STATUS )

*  Display the variance component attributes.
         IF ( REPORT ) THEN
            CALL MSG_BLANK( STATUS )
            CALL MSG_OUT( 'VAR_HEADER', '   Variance Component:',
     :                    STATUS )
            CALL MSG_SETC( 'FTYPE', FTYPE )
            CALL MSG_OUT( 'VAR_TYPE', '      Type        :  ^FTYPE',
     :                    STATUS )
            CALL MSG_SETC( 'FORM', FORM )
            CALL MSG_OUT( 'VAR_FORM', '      Storage form:  ^FORM',
     :                    STATUS )
         END IF

*  Disable automatic quality masking and see if the variance component
*  may contain bad pixels.  If so, then display an appropriate message.
         CALL NDF_SQMF( .FALSE., INDF, STATUS )
         CALL NDF_BAD( INDF, 'Variance', .FALSE., BAD, STATUS )
         IF ( REPORT ) THEN
            IF ( BAD ) THEN
               CALL MSG_OUT( 'VAR_ISBAD',
     :           '      Bad pixels may be present', STATUS )

*  If there were no bad pixels present, then re-enable quality masking
*  and test again. Issue an appropriate message.
            ELSE
               CALL NDF_SQMF( .TRUE., INDF, STATUS )
               CALL NDF_BAD( INDF, 'Variance', .FALSE., BAD, STATUS )
               IF ( .NOT. BAD ) THEN
                  CALL MSG_OUT( 'VAR_NOBAD',
     :              '      There are no bad pixels present', STATUS )
               ELSE
                  CALL MSG_OUT( 'VAR_QBAD',
     :              '      Bad pixels may be introduced via the '/
     :              /'Quality component', STATUS )
               END IF
            END IF
         END IF
      END IF


*  Quality component:
*  ==================
*  See if the quality component is defined.  If so, then obtain its
*  attributes.  Indicate its presence or otherwise through the output
*  parameter.
      CALL NDF_STATE( INDF, 'Quality', THERE, STATUS )
      CALL PAR_PUT0L( 'QUALITY', THERE, STATUS )
      IF ( THERE ) THEN
         CALL NDF_FORM( INDF, 'Quality', FORM, STATUS )

*  Display the quality component attributes.
         IF ( REPORT ) THEN
            CALL MSG_BLANK( STATUS )
            CALL MSG_OUT( 'QUALITY_HEADER', '   Quality Component:',
     :                    STATUS )
            CALL MSG_SETC( 'FORM', FORM )
            CALL MSG_OUT( 'QUALITY_FORM', '      Storage form :  ^FORM',
     :                    STATUS )
         END IF

*  Obtain the bad-bits mask value.
         CALL NDF_BB( INDF, BADBIT, STATUS )

*  Generate a binary representation in a character string.
         IF ( STATUS .EQ. SAI__OK ) THEN
            BBI = NUM_UBTOI( BADBIT )
            DIGVAL = 2 ** 7
            DO 4 IDIG = 1, 8
               IF ( BBI .GE. DIGVAL ) THEN
                  BINSTR( IDIG : IDIG ) = '1'
                  BBI = BBI - DIGVAL
               ELSE
                  BINSTR( IDIG : IDIG ) = '0'
               END IF
               DIGVAL = DIGVAL / 2
    4       CONTINUE
         END IF

*  Display the bad-bits mask information.
         IF ( REPORT ) THEN
            CALL MSG_SETI( 'BADBIT', NUM_UBTOI( BADBIT ) )
            CALL MSG_SETC( 'BINARY', BINSTR )
            CALL MSG_OUT( 'QUALITY_BADBIT',
     :        '      Bad-bits mask:  ^BADBIT (binary ^BINARY)', STATUS )
         END IF

*  Output the BADBITS mask to a parameter.
         CALL PAR_PUT0C( 'BADBITS', BINSTR, STATUS )
      END IF

*  WCS component:
*  ==============
*  Get an AST pointer for the FrameSet defining the NDF's World 
*  Co-ordinate Systems.  Store the number of co-ordinate systems
*  ("Frames") described by the FrameSet. 
      CALL KPG1_GTWCS( INDF, IWCS, STATUS )
      NFRAME = AST_GETI( IWCS, 'NFRAME', STATUS )

*  Initialise the number of Frames stored in the output parameters.
      NFRM = 0

*  Only proceed if there are more than the basic three Frames (GRID,
*  PIXEL and AXIS) in the WCS FrameSet, or a listing of all Frames 
*  has been requested.
      IF ( NFRAME .GT. 3 .OR. FULLWC ) THEN
         
*  Start an AST context.
         CALL AST_BEGIN( STATUS )

*  Save the index of the original current Frame, so that it can be
*  re-instated later.
         ICURR = AST_GETI( IWCS, 'CURRENT', STATUS )

         IF ( REPORT ) THEN
            CALL MSG_BLANK( STATUS )

            CALL MSG_OUT( 'WCS_HEADER', '   World Co-ordinate '//
     :                    'Systems:', STATUS )

            CALL MSG_SETI( 'NF', NFRAME )

            IF( FULLWC ) THEN
               CALL MSG_OUT( 'WCS_NFRM',
     :                 '      Number of co-ordinate Frames      : ^NF',
     :                       STATUS )
               CALL MSG_SETI( 'CUR', ICURR )
               CALL MSG_OUT( 'WCS_CURRENT',
     :                 '      Index of current co-ordinate Frame: ^CUR',
     :                       STATUS )
               CALL MSG_BLANK( STATUS )

            ELSE
               CALL MSG_OUT( 'WCS_NFRM',
     :                 '      Number of co-ordinate Frames: ^NF',
     :                       STATUS )
               CALL MSG_BLANK( STATUS )
               CALL MSG_SETI( 'N', ICURR )
               CALL MSG_OUT( 'WCS_CURRENT',
     :                 '      Current co-ordinate Frame (Frame ^N):', 
     :                       STATUS )
            END IF

         END IF

*  Store the GRID co-ordinates of the centre of the first pixel.  This
*  is defined to be (1.0,1.0,...).  This position will be mapped into 
*  each of the other Frames, to find the co-ordinates of the first 
*  pixel.  Also store the lower and upper bounds of the NDF in GRID 
*  co-ordinates.
         DO 301 IAXIS = 1, NDIM
            GFIRST( 1, IAXIS ) = 1.0D0
            LBIN( IAXIS ) = 0.5D0
            UBIN( IAXIS ) = DBLE( DIM( IAXIS ) ) + 0.5D0
 301     CONTINUE

*  Loop round each co-ordinate system.
         DO 304 IFRAME = 1, NFRAME

*  Make this Frame the current Frame
            CALL AST_SETI( IWCS, 'CURRENT', IFRAME, STATUS )            

*  Get the Frame title, domain and dimensionality.
            FRMTTL = AST_GETC( IWCS, 'TITLE', STATUS )
            FRMDMN = AST_GETC( IWCS, 'DOMAIN', STATUS )
            FRMNAX = AST_GETI( IWCS, 'NAXES', STATUS )

*  Remove any PGPLOT escape sequences from the title.
            CALL KPG1_PGESC( FRMTTL, STATUS )

*  Put the title, domain and dimensionality in the arrays to be stored 
*  in the output parameters if there is room. 
            IF( NFRM .LT. MXFRM ) THEN               
               NFRM = NFRM + 1
               WCSTTL( NFRM ) = FRMTTL
               WCSDMN( NFRM ) = FRMDMN
               WCSNAX( NFRM ) = FRMNAX
            END IF

*  If this is the current Frame, or if we are reporting full information
*  on all Frames, get the bounds of the NDF in this Frame.
            IF( IFRAME .EQ. ICURR .OR. ( REPORT .AND. FULLFR ) ) THEN
               MAP = AST_GETMAPPING( IWCS, AST__BASE, AST__CURRENT, 
     :                              STATUS )
               DO IAXIS = 1, FRMNAX
                  CALL AST_MAPBOX( MAP, LBIN, UBIN, .TRUE., IAXIS,
     :                             LBOUT( IAXIS ), UBOUT( IAXIS ), XL, 
     :                             XU, STATUS )
               END DO
               CALL AST_ANNUL( MAP, STATUS )

*  Normalise the two positions for display.
               CALL AST_NORM( IWCS, LBOUT, STATUS )
               CALL AST_NORM( IWCS, UBOUT, STATUS )

*  If this is the current Frame, write the bounds units and labels to 
*  the output parameters.
               IF( IFRAME .EQ. ICURR ) THEN 
                  CALL PAR_PUT1D( 'FLBND', FRMNAX, LBOUT, STATUS )
                  CALL PAR_PUT1D( 'FUBND', FRMNAX, UBOUT, STATUS )

                  DO IAXIS = 1, FRMNAX
                     ATTRIB = 'UNIT('
                     IAT = 5
                     CALL CHR_PUTI( IAXIS, ATTRIB, IAT )
                     CALL CHR_PUTC( ')', ATTRIB, IAT )
                     FUNIT( IAXIS ) = AST_GETC( IWCS, ATTRIB( : IAT ),
     :                                           STATUS )
                     ATTRIB = 'LABEL('
                     IAT = 6
                     CALL CHR_PUTI( IAXIS, ATTRIB, IAT )
                     CALL CHR_PUTC( ')', ATTRIB, IAT )
                     FLABEL( IAXIS ) = AST_GETC( IWCS, ATTRIB( : IAT ),
     :                                           STATUS )
                  END DO

                  CALL PAR_PUT1C( 'FUNIT', FRMNAX, FUNIT, STATUS )
                  CALL PAR_PUT1C( 'FLABEL', FRMNAX, FLABEL, STATUS )

               END IF
            END IF

*  The rest we only do if we are reporting information on the screen. 
*  Only display the Current Frame if parameter FULLWCS is FALSE.
            IF ( REPORT .AND. ( FULLWC .OR. IFRAME .EQ. ICURR ) ) THEN

*  Display the Frame index.
               CALL MSG_SETI( 'INDEX', IFRAME )
               IF( FULLWC ) THEN
                  CALL KPG1_DSFRM( IWCS, 
     :                           '      Frame index: ^INDEX', 
     :                             FULLFR, STATUS )

               ELSE IF( FULLFR ) THEN
                  CALL KPG1_DSFRM( IWCS, 
     :                           '        Index               : ^INDEX',
     :                             FULLFR, STATUS )
               ELSE
                  CALL KPG1_DSFRM( IWCS, ' ', FULLFR, STATUS )

               END IF

*  Display the bounds of the NDF in this Frame if full frame information
*  is being displayed.
               IF( FULLFR ) THEN
                  CALL MSG_OUT( 'WCS_WBND1', 
     :                          '        NDF Bounding Box:', STATUS )
                  CALL MSG_BLANK( STATUS )

                  DO IAXIS = 1, FRMNAX
                     CALL MSG_SETI( 'I', IAXIS )
                     CALL MSG_SETC( 'L', AST_FORMAT( IWCS, IAXIS, 
     :                                        LBOUT( IAXIS ), STATUS ) )
                     CALL MSG_SETC( 'U', AST_FORMAT( IWCS, IAXIS, 
     :                                        UBOUT( IAXIS ), STATUS ) )
                     CALL MSG_OUT( 'WCS_WBND2', 
     :                             '           Axis ^I: ^L -> ^U', 
     :                             STATUS )
                  END DO

                  CALL MSG_BLANK( STATUS )

               END IF
            END IF

 304     CONTINUE 

*  Re-instate the original current Frame.
         CALL AST_SETI( IWCS, 'CURRENT', ICURR, STATUS )

*  Write the output Frame parameters.
         CALL PAR_PUT1C( 'FTITLE', NFRM, WCSTTL, STATUS )
         CALL PAR_PUT1C( 'FDOMAIN', NFRM, WCSDMN, STATUS )
         CALL PAR_PUT1I( 'FDIM', NFRM, WCSNAX, STATUS )
         CALL PAR_PUT0I( 'CURRENT', ICURR, STATUS )

*  End the AST context.
         CALL AST_END( STATUS )

      END IF

*  Write out the WCS and NFRAME parameter values.
      CALL PAR_PUT0L( 'WCS', (NFRAME .GT. 3 ), STATUS )
      CALL PAR_PUT0I( 'NFRAME', NFRM, STATUS )

*  Extensions:
*  ===========
*  Determine how many extensions are present.
      CALL NDF_XNUMB( INDF, NEXTN, STATUS )

*  Output the number to a parameter.
      CALL PAR_PUT0I( 'NEXTN', NEXTN, STATUS )

*  Display a heading for the extensions.
      IF ( NEXTN .GT. 0 ) THEN
         IF ( REPORT ) THEN
            CALL MSG_BLANK( STATUS )
            CALL MSG_OUT( 'EXTN_HEADER', '   Extensions:', STATUS )
         END IF

*  Loop to obtain the name and data type of each extension.
*  Protect against array-bounds errors.  It is unlikely that there will
*  ever be more the MXEXTN extensions.
         DO 5 N = 1, NEXTN
            IEXTN = MIN( N, MXEXTN )
            CALL NDF_XNAME( INDF, N, XNAME( IEXTN ), STATUS )
            CALL NDF_XLOC( INDF, XNAME( IEXTN ), 'READ', XLOC, STATUS )
            CALL DAT_TYPE( XLOC, XTYPE( IEXTN ), STATUS )
            CALL DAT_ANNUL( XLOC, STATUS )
            XLOC = ' '

*  Display the information for each extension.
            IF ( REPORT ) THEN
               CALL MSG_SETC( 'TYPE', XTYPE( IEXTN ) )
               CALL MSG_OUT( 'EXTN',
     :           '      ' // XNAME( IEXTN ) // '  <^TYPE>', STATUS )
            END IF
    5    CONTINUE

*   Output the names and types of the extensions.
         CALL PAR_PUT1C( 'EXTNAME', NEXTN, XNAME, STATUS )
         CALL PAR_PUT1C( 'EXTTYPE', NEXTN, XTYPE, STATUS )

      END IF
      IF ( REPORT ) CALL MSG_BLANK( STATUS )

*  History:
*  ========
*  See if a history component is present, and send the result to an
*  output parameter.
      CALL NDF_STATE( INDF, 'History', THERE, STATUS )
      CALL PAR_PUT0L( 'HISTORY', THERE, STATUS )

*  If so, then obtain its attributes.
      IF ( THERE .AND. REPORT ) THEN
         CALL NDF_HINFO( INDF, 'CREATED', 0, CREAT, STATUS )
         CALL NDF_HNREC( INDF, NREC, STATUS )
         CALL NDF_HINFO( INDF, 'MODE', 0, HMODE, STATUS )
         CALL NDF_HINFO( INDF, 'DATE', NREC, DATE, STATUS )
         CALL NDF_HINFO( INDF, 'APPLICATION', NREC, APPN, STATUS )

*  Convert the date format to KAPPA style.
         CALL KPG1_FHDAT( CREAT, STATUS )
         CALL KPG1_FHDAT( DATE, STATUS )

*  Display the history component attributes.
         CALL MSG_BLANK( STATUS )
         CALL MSG_OUT( 'HISTORY_HEADER', '   History Component:',
     :                 STATUS )
         CALL MSG_SETC( 'CREAT', CREAT( : 20 ) )
         CALL MSG_OUT( 'HISTORY_CREAT',
     :                 '      Created    :  ^CREAT', STATUS )
         CALL MSG_SETI( 'NREC', NREC )
         CALL MSG_OUT( 'HISTORY_NREC',
     :                 '      No. records:  ^NREC', STATUS )
         CALL MSG_SETC( 'DATE', DATE( : 20 ) )
         CALL MSG_SETC( 'APPN', APPN )
         CALL MSG_OUT( 'HISTORY_DATE',
     :                 '      Last update:  ^DATE (^APPN)', STATUS )
         CALL MSG_SETC( 'HMODE', HMODE )
         CALL MSG_OUT( 'HISTORY_HMODE',
     :                 '      Update mode:  ^HMODE', STATUS )
      END IF
      IF ( REPORT ) CALL MSG_BLANK( STATUS )

*  Clean up:
*  ========
*  Annul the NDF identifier.
      CALL NDF_ANNUL( INDF, STATUS )

*  If an error occurred, then report context information.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'NDFTRACE_ERR',
     :     'NDFTRACE: Error displaying the attributes of an NDF ' //
     :     'data structure.', STATUS )
      END IF

      END
