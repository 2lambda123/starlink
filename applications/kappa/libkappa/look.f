      SUBROUTINE LOOK( STATUS )
*+
*  Name:
*     LOOK

*  Purpose:
*     List pixel values in a 2-dimensional NDF.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation
*     CALL LOOK( STATUS )

*  Description:
*     This application lists pixel values within a region of
*     a 2D NDF. The listing may be displayed on the screen and logged in
*     a text file (see parameters QUIET and LOGFILE). The region 
*     to be listed can be specified either by giving its centre and size or
*     its corners, or by giving an ARD description for the region (see
*     parameter MODE). The top-right pixel value is also written to an output 
*     parameter (VALUE). The listing may be produced in several different
*     formats (see parameter FORMAT), and the format of each individual
*     displayed data value can be controlled using parameter STYLE.

*  Usage:
*     look ndf centre [size] [logfile] [format] [comp] [mode]

*  ADAM Parameters:
*     AGAIN = _LOGICAL (Read)
*        If TRUE, the user is prompted for further regions to list until
*        a FALSE value is obtained. [FALSE]
*     ARDDESC = LITERAL (Read)
*        An ARD description for the parts of the image to be listed. 
*        Multiple lines can be supplied by ending each line with a minus
*        sign, in which case further prompts for ARDDESC are made until
*        a value is supplied which does not end with a minus sign. All
*        the supplied values are then concatenated together (after removal 
*        of the trailing minus signs). Only acessed if MODE is "ARD".
*     ARDFILE = FILENAME (Read)
*        The name of an existing text file containing an ARD description
*        for the parts of the image to be listed. Only acessed if MODE is 
*        "ARDFile".
*     CENTRE = LITERAL (Read)
*        The co-ordinates of the data pixel at the centre of the area to
*        be displayed, in the current co-ordinate Frame of the NDF (supplying 
*        a colon ":" will display details of the current co-ordinate Frame). 
*        The position should be supplied as a list of formatted axis values 
*        separated by spaces or commas. See also parameter USEAXIS. Only 
*        acessed if MODE is "Centre".
*     COMP = LITERAL (Read)
*        The NDF array component to be displayed.  It may be "Data",
*        "Quality", "Variance", or "Error" (where "Error" is an
*        alternative to "Variance" and causes the square root of the
*        variance values to be displayed).  If "Quality" is specified,
*        then the quality values are treated as numerical values (in
*        the range 0 to 255). ["Data"]
*     FORMAT = LITERAL (Read)
*        Specifies the format for the listing:
*
*        - "strips" -- The area being displayed is divided up into
*        vertical strips of limited width. Each strip is displayed in
*        turn, with Y pixel index at the left of each row, and
*        X pixel index at the top of each column. The highest row is
*        listed first in each strip. This format is intended for human
*        readers - the others are primarily intended for being read by
*        other software.
*
*        - "clist" -- Each row of textual output consists of an X pixel 
*        index, followed by a Y pixel index, followed by the pixel data
*        value. No headers or blank lines are included. The pixels are
*        listed in "fortran order" - the lower left pixel first, and the
*        upper right pixel last. 
*
*        - "vlist" -- Each row of textual output consists of just the
*        pixel data value. No headers or blank lines are included. The 
*        pixels are listed in "fortran order" - the lower left pixel first, 
*        and the upper right pixel last.
*
*        - "region" -- The pixel data values are listed as a 2 dimensional
*        region. Each row of textual output contains a whole row of data 
*        values. The textual output may be truncated if it is too wide. The
*        lowest row is listed first.
*
*        In all cases, adjacent values are separated by spaces, and bad
*        pixel values are represented by the string "BAD". ["strips"]
*
*     LBOUND = LITERAL (Read)
*        The co-ordinates of the data pixel at the bottom-left of the 
*        area to be displayed, in the current co-ordinate Frame of the NDF 
*        (supplying a colon ":" will display details of the current 
*        co-ordinate Frame). The position should be supplied as a list of 
*        formatted axis values separated by spaces or commas. See also 
*        parameter USEAXIS.  A null (!) value causes the bottom-left corner
*        of the supplied NDF to be used. Only acessed if MODE is "Bounds".
*     LOGFILE = FILENAME (Write)
*        The name of the text file in which the textual output may be stored. 
*        See MAXLEN. A null string (!) means that no file is created.  [!]
*     MAXLEN = _INTEGER (Read)
*        The maximum number of characters in a line of textual output. The 
*        line is truncated after the last complete value if it would extend
*        beyond this value. [80]
*     MODE = LITERAL (Read)
*        Indicates how the region to be listed will be specified:
*
*        - "Centre" -- The centre and size of the region are specified
*        using parameters CENTRE and SIZE.
*
*        - "Bounds" -- The bounds of the region are specified using 
*        parameters LBOUND and UBOUND.
*
*        - "ARDFile" -- The region is given by an ARD description 
*        supplied within a text file specified using parameter ARDFILE.
*        Pixels outside the ARD region are represented by the string "OUT". 
*
*        - "ARD" -- The region is given using an ARD description 
*        supplied directly using parameter ARDDESC. Pixels outside the 
*        ARD region are represented by the string "OUT". 
*
*        ["Centre"]
*     NDF = NDF (Read)
*        The input NDF structure containing the data to be displayed.
*     QUIET = LOGICAL (Read)
*        If TRUE then output is not displayed on the screen. The log file
*        and output parameter values are still created. [FALSE]
*     SIZE( 2 ) = _INTEGER (Read)
*        The dimensions of the rectangular area to be displayed, in pixels.
*        If a single value is given, it is used for both axes. The area
*        is centred on the position specified by parameter CENTRE. 
*        Only acessed if MODE is "Centre". [7]
*     STYLE = GROUP (Read)
*        A group of attribute settings describing the format to use 
*        for individual data values.
*
*        A comma-separated list of strings should be given in which each
*        string is either an attribute setting, or the name of a text file
*        preceded by an up-arrow character "^". Such text files should
*        contain further comma-separated lists which will be read and 
*        interpreted in the same manner. Attribute settings are applied in 
*        the order in which they occur within the list, with later settings
*        over-riding any earlier settings given for the same attribute.
*
*        Each individual attribute setting should be of the form:
*
*           <name>=<value>
*        
*        where <name> is the name of a Frame attribute, and <value> is
*        the value to assign to the attribute. Default values will be
*        used for any unspecified attributes. All attributes will be
*        defaulted if a null value (!) is supplied. See section "Plotting
*        Attributes" in SUN/95 for a description of the available
*        attributes. Any unrecognised attributes are ignored (no error is
*        reported). 
*
*        Data values are formatted using attributes Format(1) and Digits(1). 
*        [current value] 
*     UBOUND = LITERAL (Read)
*        The co-ordinates of the data pixel at the top-right corner of the 
*        area to be displayed, in the current co-ordinate Frame of the NDF 
*        (supplying a colon ":" will display details of the current 
*        co-ordinate Frame). The position should be supplied as a list of 
*        formatted axis values separated by spaces or commas. See also 
*        parameter USEAXIS.  A null (!) value causes the top right corner
*        of the supplied NDF to be used. Only acessed if MODE is "Bounds".
*     USEAXIS = GROUP (Read)
*        USEAXIS is only accessed if the current co-ordinate Frame of the 
*        NDF has more than 2 axes. A group of two strings should be
*        supplied specifying the 2 axes which are to be used when supplying 
*        positions for parameters CENTRE, LBOUND and UBOUND. Each axis can 
*        be specified either by its integer index within the current Frame 
*        (in the range 1 to the number of axes in the current Frame), or by
*        its symbol string. A list of acceptable values is displayed if an 
*        illegal value is supplied. If a null (!) value is supplied, the axes 
*        with the same indices as the 2 used pixel axes within the NDF
*        are used. [!]
*     VALUE = _DOUBLE (Write)
*        An output parameter to which is written the data value at the 
*        top-right pixel in the displayed rectangle.

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Examples:
*     look ngc6872 "1:27:23 -22:41:12" quiet logfile=log
*        Lists a 7x7 block of pixel values centred on RA/DEC 1:27:23,
*        -22:41:12 (this assumes that the current co-ordinate Frame in
*        the NDF is an RA/DEC Frame). The listing is written to the text 
*        file "log" but is not displayed on the screen.
*     look m57 mode=bo lbound="18 20" ubound="203 241"
*        Lists the pixel values in an NDF called m57, within a
*        rectangular region from pixel (18,20) to (203,241) (this
*        assumes that the current co-ordinate Frame in the NDF is pixel
*        co-ordinates). The listing is displayed on the screen only.
*     look ngc6872 "10 11" 1 quiet 
*        Stores the value of pixel (10,11) in output parameter VALUE, but
*        does not display it on the screen or store it in a log file. This
*        assumes that the current co-ordinate Frame in the NDF is pixel
*        co-ordinates. 
*     look ngc6872 mode=ard arddesc="circle(1:27:23,-22:41:12,0:0:10)"
*        Lists the pixel values within a circle of radius 10 ard-seconds,
*        centred on RA=1:27:23 DEC=-22:41:12. This assumes that the 
*        current co-ordinate Frame in the NDF is an RA/DEC Frame.
*     look ngc6872 mode=ardfile ardfile=central.ard
*        Lists the pixel values specified by the ARD description stored
*        in the text file "central.dat".

*  Notes:
*     -  The co-ordinate system in which positions are given within ARD
*     descriptions can be indicated by including suitable
*     COFRAME or WCS statements within the description (see SUN/183).
*     For instance, starting the description with the text
*     "COFRAME(PIXEL)" will indicate that positions are specified in
*     pixel co-ordinates. The statement "COFRAME(SKY,System=FK5)" would
*     indicate that positions are specified in RA/DEC (FK5,J2000). If
*     no such statements are included, then it is assumed that
*     positions are given within the current co-ordinate system of the
*     input NDF.

*  Related Applications:
*     KAPPA: TRANDAT, ARDGEN, ARDMASK, ARDPLOT.

*  Implementation Status:
*     -  This routine correctly processes the DATA, QUALITY and 
*     VARIANCE components of the input NDF.
*     -  Processing of bad pixels and automatic quality masking are
*     supported.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     19-OCT-2001 (DSB):
*        Original NDF/AST version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_new_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE

*  Global Constants:
      INCLUDE 'SAE_PAR'        ! Global SSE definitions
      INCLUDE 'PAR_ERR'        ! PAR error constants
      INCLUDE 'AST_PAR'        ! AST constants and functions
      INCLUDE 'GRP_PAR'        ! GRP constants 
      INCLUDE 'NDF_PAR'        ! NDF constants 

*  Status:
      INTEGER STATUS

*  Local Variables:
      CHARACTER COMP*8         ! Component to be displayed
      CHARACTER FILNAM*256     ! Name of ARD file
      CHARACTER FORMAT*6       ! Output format
      CHARACTER MCOMP*8        ! Component to be mapped
      CHARACTER MODE*7         ! Mode for getting regions
      CHARACTER TEXT*80        ! Text buffer
      DOUBLE PRECISION CC( 2 ) ! Current Frame co-ords 
      DOUBLE PRECISION CL( 2 ) ! Current Frame co-ords 
      DOUBLE PRECISION CU( 2 ) ! Current Frame co-ords 
      DOUBLE PRECISION GC( 2 ) ! GRID co-ords 
      DOUBLE PRECISION VALUE   ! Final data value
      INTEGER EL               ! No. of mapped values
      INTEGER FDA              ! ARD file descriptor
      INTEGER FDL              ! Log file descriptor
      INTEGER FRM              ! Frame used to format data values
      INTEGER I                ! Loop counter
      INTEGER IGRP             ! GRP identifier for ARD description group
      INTEGER INDF1            ! Input NDF
      INTEGER INDF2            ! Section of input NDF to be listed
      INTEGER IPDAT            ! Pointer to mapped pixel values
      INTEGER IPLINE           ! Pointer to line buffer
      INTEGER IWCS             ! Pointer to the WCS FrameSet from the NDF
      INTEGER MAXLEN           ! Maximum line length
      INTEGER NC               ! No. of characters used
      INTEGER NDIM             ! No. of pixel axes in NDF
      INTEGER NVAL             ! No. of values obtained from parameter
      INTEGER RLBND( 2 )       ! The lower bounds of region to be listed
      INTEGER RUBND( 2 )       ! The upper bounds of region to be listed
      INTEGER LBND( NDF__MXDIM )! The lower bounds of the NDF
      INTEGER UBND( NDF__MXDIM )! The upper bounds of the NDF
      INTEGER SDIM( 2 )        ! The significant NDF axes
      INTEGER SIZE( 2 )        ! Region dimensions
      INTEGER SLBND( 2 )       ! Significant lower bounds of the image
      INTEGER SUBND( 2 )       ! Significant upper bounds of the image
      INTEGER TEMP             ! Temporary storage
      LOGICAL AGAIN            ! List another region?
      LOGICAL CONT             ! ARD description to continue?
      LOGICAL LOG              ! Write to log file?
      LOGICAL QUIET            ! Suppress screen output?
*.

*  Check the inherited global status.
      IF( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Begin an NDF context.
      CALL NDF_BEGIN

*  Get the input NDF identifier.
      CALL LPG_ASSOC( 'NDF', 'READ', INDF1, STATUS )

*  Find which component to display. MCOMP is for use with NDF_MAP and may
*  be set to 'Error'. COMP is for use with all other NDF routines (which
*  do not accept 'Error' as an NDF component name), and has 'Variance' in
*  place of 'Error'.
      CALL KPG1_ARCOG( 'COMP', INDF1, MCOMP, COMP, STATUS )

*  Now get the WCS FrameSet from the NDF.
      CALL KPG1_ASGET( INDF1, 2, .FALSE., .TRUE., .TRUE., SDIM, 
     :                 SLBND, SUBND, IWCS, STATUS )

*  Get the bounds of all pixel axes in the NDF.
      CALL NDF_BOUND( INDF1, NDF__MXDIM, LBND, UBND, NDIM, STATUS )      

*  Obtain the mode in which to obtain the region to be listed.
      CALL PAR_CHOIC( 'MODE', 'Centre', 'Centre,Bounds,ARD,ARDFile', 
     :                .FALSE., MODE, STATUS )

*  Abort if an error has occurred.
      IF( STATUS .NE. SAI__OK ) GO TO 999

*  Find the centre position (used as a default for CENTRE).
      IF( MODE .EQ. 'CENTRE' ) THEN 
         GC( 1 ) = 0.5*( SUBND( SDIM( 1 ) ) - SLBND( SDIM( 1 ) ) )  
     :             + 1.0
         GC( 2 ) = 0.5*( SUBND( SDIM( 2 ) ) - SLBND( SDIM( 2 ) ) )
     :             + 1.0
         CALL AST_TRAN2( IWCS, 1, GC( 1 ), GC( 2 ), .TRUE., CC( 1 ), 
     :                   CC( 2 ), STATUS ) 

*  KPG1_GTPOS displays the default with large accuracy. This is probably
*  more than we need here, so reduce the accuracy of the defaults by
*  formatting them and unformatting them.
         DO I = 1, 2
            TEXT = AST_FORMAT( IWCS, I, CC( I ), STATUS )
            NC = AST_UNFORMAT( IWCS, I, TEXT, CC( I ), STATUS ) 
         END DO

*  The defaults for BOUNDS mode are the bottom left and top right
*  corners of the entire image.
      ELSE IF( MODE .EQ. 'BOUNDS' ) THEN 
         GC( 1 ) = 1.0
         GC( 2 ) = 1.0
         CALL AST_TRAN2( IWCS, 1, GC( 1 ), GC( 2 ), .TRUE., CL( 1 ), 
     :                   CL( 2 ), STATUS ) 

         DO I = 1, 2
            TEXT = AST_FORMAT( IWCS, I, CL( I ), STATUS )
            NC = AST_UNFORMAT( IWCS, I, TEXT, CL( I ), STATUS ) 
         END DO

         GC( 1 ) = DBLE( SUBND( SDIM( 1 ) ) - SLBND( SDIM( 1 ) ) + 1 )
         GC( 2 ) = DBLE( SUBND( SDIM( 2 ) ) - SLBND( SDIM( 2 ) ) + 1 )
         CALL AST_TRAN2( IWCS, 1, GC( 1 ), GC( 2 ), .TRUE., CU( 1 ), 
     :                   CU( 2 ), STATUS ) 

         DO I = 1, 2
            TEXT = AST_FORMAT( IWCS, I, CU( I ), STATUS )
            NC = AST_UNFORMAT( IWCS, I, TEXT, CU( I ), STATUS ) 
         END DO

      END IF

*  Get the maximum line length, and allocate a buffer string of this size.
      CALL PAR_GDR0I( 'MAXLEN', 80, 1, 10000, .TRUE., MAXLEN, STATUS )
      CALL PSX_CALLOC( MAXLEN, '_CHAR', IPLINE, STATUS )

*  Abort if an error has occurred.
      IF( STATUS .NE. SAI__OK ) GO TO 999

*  Attempt to open a log file to store the results.
      LOG = .FALSE.
      CALL FIO_ASSOC( 'LOGFILE', 'WRITE', 'LIST', MAXLEN, FDL, STATUS )

*  Annul the error if a null value was given, and indicate that a log
*  file is not to be created.
      IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )

      ELSE IF( STATUS .EQ. SAI__OK ) THEN
         LOG = .TRUE.

      END IF

*  See if we are to run quietly.
      CALL PAR_GET0L( 'QUIET', QUIET, STATUS )

*  Obtain the formatting method to use.
      CALL PAR_CHOIC( 'FORMAT', 'strips', 'Strips,Clist,Vlist,Region', 
     :                .FALSE., FORMAT, STATUS )

*  Create a 1D Frame and set its style. The AST_FORMAT method for axis 1 of
*  this Frame is used to format the data values.
      FRM = AST_FRAME( 1, ' ', STATUS )
      CALL KPG1_ASSET( 'KAPPA_LOOK', 'STYLE', FRM, STATUS )

*  Loop until no more regions are given.
      AGAIN = .TRUE.
      DO WHILE( AGAIN .AND. STATUS .EQ. SAI__OK )

*  In CENTER mode, get the centre position and size for the region.
         IF( MODE .EQ. 'CENTRE' ) THEN

*  Obtain the Current Frame co-ordinates (returned in CC) to put at the 
*  centre of the listing, using parameter CENTRE. 
            CALL KPG1_GTPOS( 'CENTRE', IWCS, .FALSE., CC, GC, STATUS )

*  Get the box size in pixel.
            CALL PAR_GDRVI( 'SIZE', 2, 1, 20000, SIZE, NVAL, STATUS )
            IF ( NVAL .LT. 2 ) SIZE( 2 ) = SIZE( 1 )

*  Store the pixel index bounds of the region to be listed.
            RLBND( 1 ) = NINT( GC( 1 ) ) - 1 + SLBND( SDIM( 1 ) ) - 
     :                   SIZE( 1 )/2
            RUBND( 1 ) = RLBND( 1 ) + SIZE( 1 ) - 1
            RLBND( 2 ) = NINT( GC( 2 ) ) - 1 + SLBND( SDIM( 2 ) ) - 
     :                   SIZE( 2 )/2
            RUBND( 2 ) = RLBND( 2 ) + SIZE( 2 ) - 1
 
*  Get an NDF identifier for the relevant section.
            LBND( SDIM( 1 ) ) = RLBND( 1 )
            LBND( SDIM( 2 ) ) = RLBND( 2 )
            UBND( SDIM( 1 ) ) = RUBND( 1 )
            UBND( SDIM( 2 ) ) = RUBND( 2 )
            CALL NDF_SECT( INDF1, NDIM, LBND, UBND, INDF2, STATUS ) 

*  Map the required NDF component.
            CALL NDF_MAP( INDF2, MCOMP, '_DOUBLE', 'READ', IPDAT, EL,
     :                    STATUS )

*  In Bounds mode, get the positions of the top right and bottom left
*  corners.
         ELSE IF( MODE .EQ. 'BOUNDS' ) THEN

            CALL KPG1_GTPOS( 'LBOUND', IWCS, .FALSE., CL, GC, STATUS )
            IF( STATUS .EQ. PAR__NULL ) THEN
               CALL ERR_ANNUL( STATUS )   
               RLBND( 1 ) = SLBND( SDIM( 1 ) ) 
               RLBND( 2 ) = SLBND( SDIM( 2 ) ) 
            ELSE
               RLBND( 1 ) = NINT( GC( 1 ) ) - 1 + SLBND( SDIM( 1 ) )
               RLBND( 2 ) = NINT( GC( 2 ) ) - 1 + SLBND( SDIM( 2 ) ) 
            END IF
   
            CALL KPG1_GTPOS( 'UBOUND', IWCS, .FALSE., CU, GC, STATUS )
            IF( STATUS .EQ. PAR__NULL ) THEN
               CALL ERR_ANNUL( STATUS )   
               RUBND( 1 ) = SUBND( SDIM( 1 ) ) 
               RUBND( 2 ) = SUBND( SDIM( 2 ) ) 
            ELSE
               RUBND( 1 ) = NINT( GC( 1 ) ) - 1 + SLBND( SDIM( 1 ) )
               RUBND( 2 ) = NINT( GC( 2 ) ) - 1 + SLBND( SDIM( 2 ) ) 
            END IF

*  Ensure bounds are in the correct order.
            IF( RLBND( 1 ) .GT. RUBND( 1 ) ) THEN
               TEMP = RLBND( 1 ) 
               RLBND( 1 ) = RUBND( 1 )
               RUBND( 1 ) = TEMP
            END IF

            IF( RLBND( 2 ) .GT. RUBND( 2 ) ) THEN
               TEMP = RLBND( 2 ) 
               RLBND( 2 ) = RUBND( 2 )
               RUBND( 2 ) = TEMP
            END IF

*  Get an NDF identifier for the relevant section.
            LBND( SDIM( 1 ) ) = RLBND( 1 )
            LBND( SDIM( 2 ) ) = RLBND( 2 )
            UBND( SDIM( 1 ) ) = RUBND( 1 )
            UBND( SDIM( 2 ) ) = RUBND( 2 )
            CALL NDF_SECT( INDF1, NDIM, LBND, UBND, INDF2, STATUS ) 

*  Map the required NDF component.
            CALL NDF_MAP( INDF2, MCOMP, '_DOUBLE', 'READ', IPDAT, EL,
     :                    STATUS )

*  In ARD or ARDFILE mode, get an ARD file and use it to define the region.
         ELSE 
            IGRP = GRP__NOID

*  In ARD mode, get an ARD description directly from the user, storing
*  it in a GRP group.
            IF( MODE .EQ. 'ARD' ) THEN
               CALL ARD_GROUP( 'ARDDESC', GRP__NOID, IGRP, STATUS )

*  In ARDFILE mode, use a parameter to obtain the name of an existing 
*  text file. Add the GRP indirection symbol so that ARD does 
*  not treat the filename as a literal ARD description.
            ELSE
               CALL FIO_ASSOC( 'ARDFILE', 'READ', 'LIST', 0, FDA, 
     :                          STATUS )
               CALL AIF_FLNAM( 'ARDFILE', FILNAM( 2: ), STATUS )
               CALL FIO_ANNUL( FDA, STATUS )
               FILNAM( 1:1 ) = '^'

*  Read the file to produce an ARD description in a GRP group 
               CALL ARD_GRPEX( FILNAM, GRP__NOID, IGRP, CONT, STATUS )
            END IF

*  The next call returns a pointer to some memory which contains a copy of
*  the requested pixels in the input NDF. The pixel bounds of this region
*  are also returned.
            CALL KPS1_LOOK1( INDF1, MCOMP, IWCS, SDIM, IGRP, RLBND, 
     :                       RUBND, IPDAT, STATUS )

         END IF

*  Produce the listing.
         CALL KPS1_LOOK( FRM, RLBND( 1 ), RUBND( 1 ), RLBND( 2 ), 
     :                   RUBND( 2 ), %VAL( IPDAT ), QUIET, LOG, FDL, 
     :                   %VAL( IPLINE ), FORMAT, MAXLEN, VALUE, 
     :                   STATUS, %VAL( MAXLEN ) )

*  Annull the temporary resources.
         IF( MODE .EQ. 'CENTRE' .OR. MODE .EQ. 'BOUNDS' ) THEN
            CALL NDF_ANNUL( INDF2, STATUS )
         ELSE
            CALL PSX_FREE( IPDAT, STATUS )
            CALL GRP_DELET( IGRP, STATUS )
         END IF

*  See if another region is to be listed.
         CALL PAR_GET0L( 'AGAIN', AGAIN, STATUS )

*  If so cancel the required parameters values os that new values are
*  obtained on the next pass.
         IF( AGAIN ) THEN
            CALL PAR_CANCL( 'AGAIN', STATUS )
            CALL PAR_CANCL( 'CENTRE', STATUS )
            CALL PAR_CANCL( 'SIZE', STATUS )
            CALL PAR_CANCL( 'LBOUND', STATUS )
            CALL PAR_CANCL( 'UBOUND', STATUS )
            CALL PAR_CANCL( 'ARDDESC', STATUS )
            CALL PAR_CANCL( 'ARDFILE', STATUS )
         END IF

      END DO

*  Write out the last data value to the output parameter.
      CALL PAR_PUT0D( 'VALUE', VALUE, STATUS )

*  Shutdown procedure.
*  ===================
 999  CONTINUE

*  Close any log file.
      IF( LOG ) CALL FIO_ANNUL( FDL, STATUS )

*  End the NDF context.
      CALL NDF_END( STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

*  Add a context report if anything went wrong.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'LOOK_ERR', 'LOOK: Failed to list pixel values'//
     :                 ' in a 1 or 2-dimensional data set.', STATUS )
      END IF

      END
