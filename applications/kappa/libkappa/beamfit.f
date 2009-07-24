      SUBROUTINE BEAMFIT ( STATUS )
*+
*  Name:
*     BEAMFIT

*  Purpose:
*     Fits beam features in a two-dimensional NDF.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL BEAMFIT( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This fits Gaussians to beam features within the data array of a
*     two-dimensional NDF given approximate initial co-ordinates.  It
*     uses an unconstrained least-squares minimisation using the
*     residuals and a modified Levenberg-Marquardt algorithm.  The
*     beam feature is a set of connected pixels which are either
*     above or below the surrounding background region.  The errors in
*     the fitted coefficients are also calculated.
*
*     You may apply various constraints.  These are either fixed, or
*     relative.   Fixed values include the FWHM or background level.
*     Relative constraints define the properties of secondary beam
*     features with respect to the primary (first given) feature, and
*     can specify amplitude ratios, and beam separations in Cartesian
*     or polar co-ordinates.
*
*     Four methods are available for obtaining the initial positions, 
*     selected using Parameter MODE:
*
*     - from the parameter system (see Parameters POS, POS2--POS5);
*
*     - using a graphics cursor to indicate the feature in a previously
*     displayed data array (see Parameter DEVICE);
*
*     - from a specified positions list (see Parameter INCAT); or
*
*     - from a simple text file containing a list of co-ordinates (see
*     Parameter COIN).
*
*     In the first two modes the application loops, asking for new
*     feature co-ordinates until it is told to quit or encounters an
*     error or the maximum number of features is reached.  The last is
*     five, unless Parameters POS2---POS5 define the location of the 
*     secondary beams and then only the primary beam's position is 
*     demanded.
*
*     BEAMFIT both reports and stores in parameters its results. 
*     These are fit coefficients and their errors, the offsets and
*     position angles of the secondary beam features with respect to 
*     the primary beam, and the offset of the primary beam from a
*     reference position.  Also a listing of the fit results may be 
*     written to a log file geared more towards human readers, 
*     including details of the input parameters (see Parameter
*     LOGFILE).  
*
*  Usage:
*     beamfit ndf [mode] { incat=?
*                        { [beams]
*                        { coin=?
*                        { [beams] pos pos2-pos5=?
*                        mode

*  ADAM Parameters:
*     AMP( 2 ) = _DOUBLE (Write)
*        The primary beam position's amplitude and its error.
*     AMPRATIO( ) = _REAL (Read)
*        If number of beam positions given by BEAMS is more than one,
*        this specifies the ratio of the amplitude of the secondary
*        beams to the primary.  Thus you should supply one fewer value 
*        than the number of beams.  If you give fewer than that the last
*        ratio  is copied to the missing values.  The ratios would
*        normally be negative, usually -1 or -0.5.  AMPRATIO is ignored
*        when there is only one beam feature to fit.  [!]
*     BACK( 2 ) = _DOUBLE (Write)
*        The primary beam position's background level and its error.
*     BEAMS = _INTEGER (Read)
*        The number of beam positions to fit.  This will normally be 1, 
*        unless a chopped observation is supplied, when there may be two
*        or three beam positions.  This parameter is ignored  for "File" 
*        and "Catalogue" modes, where the number comes from the number 
*        of beam positions read from the files; and for "Interface" mode
*        when the beam positions POS, POS2, etc. are supplied in full
*        on the command line without BEAMS.  In all modes there is a 
*        maximum of five positions, which for "File" or "Catalogue" 
*        modes will be the first five.  [1]
*     CENTRE( 2 ) = LITERAL (Write)
*        The formatted co-ordinates and their errors of the primary
*        beam in the current co-ordinate Frame of the NDF.  
*     COIN = FILENAME (Read)
*        Name of a text file containing the initial guesses at the 
*        co-ordinates of beams to be fitted.  It is only accessed if 
*        Parameter MODE is given the value "File".  Each line should
*        contain the formatted axis values for a single position, in the
*        current Frame of the NDF.  Axis values can be separated by 
*        spaces, tabs or commas.  The file may contain comment lines 
*        with the first character # or !. 
*     DESCRIBE = LOGICAL (Read)
*        If TRUE, a detailed description of the co-ordinate Frame in 
*        which the beam positions will be reported is displayed before 
*        the positions themselves.  [current value]
*     DEVICE = DEVICE (Read)
*        The graphics device which is to be used to give the initial
*        guesses at the beam positions.  Only accessed if Parameter 
*        MODE is given the value "Cursor".  [Current graphics device]
*     FIXAMP = _DOUBLE (Read)
*        This specifies the fixed amplitude of the first beam. 
*        Secondary sources arising from chopped data use FIXAMP 
*        multiplied by the AMPRATIO.  A null value indicates that
*        the amplitude should be fitted.  [!]
*     FITAREA() = _INTEGER (Read)
*        Size in pixels of the fitting area to be used.  If only a 
*        single value is given, then it will be duplicated to all 
*        dimensions so that a square region is fitted.  Each value must 
*        be greater than 9.  A null value requests that the full data 
*        array is used.  [!]
*     FIXBACK = _DOUBLE (Read)
*        If a non-null value is supplied then the model fit will use
*        that value as the constant background level otherwise the
*        background is a free parameter of the fit.  [!]
*     FIXFWHM = LITERAL (Read)
*        If a non-null value is supplied then the model fit will use
*        that value as the full-width half-maximum value for the beam
*        and assumes that the beam is circular.  If two values are 
*        supplied then these are the fixed major- and minor-axis 
*        full-width half maxima.
*        
*        If the current co-ordinate Frame of the NDF is a SKY Frame 
*        (e.g. right ascension and declination), then the value should 
*        be supplied as an increment of celestial latitude (e.g.
*        declination).  Thus, "5.7" means 5.7 arcseconds, "20:0" would
*        mean 20 arcminutes, and "1:0:0" would mean 1 degree.  If the 
*        current co-ordinate Frame is not a SKY Frame, then the widths
*        should be specified as an increment along Axis 1 of the 
*        current co-ordinate Frame.  Thus, if the Current Frame is 
*        PIXEL, the value should be given simply as a number of pixels.
*
*        Null indicates that the FWHM values are free parameters of the
*        fit.  [!]
*     FIXPOS = _LOGICAL (Read)
*        If TRUE, the supplied position of each beam is used and
*        the centre co-ordinates of the beam features are not fit. 
*        FALSE causes the initial estimate of the location of each 
*        beam to come from the source selected by Parameter MODE, and 
*        all these locations are part of the fitting process (however
*        note the exception when FIXSEP = TRUE.  It is advisable not to
*        use this option in the inaccurate "Cursor" mode.  [FALSE]
*     FIXSEP = _LOGICAL (Read)
*        If TRUE, the separations of secondary beams from the primary
*        beam are fixed, and this takes precedence over Parameter
*        FIXPOS.  If FALSE, the beam separations are free to be fitted
*        (although it is actually the centres being fit).  It is 
*        advisable not to use this option in the inaccurate "Cursor" 
*        mode.  [FALSE]
*     INCAT = FILENAME (Read)
*        A catalogue containing a positions list giving the initial
*        guesses at the beam positions, such as produced by applications
*        CURSOR, LISTMAKE, etc.  It is only accessed if Parameter MODE 
*        is given the value "Catalogue". 
*     LOGFILE = FILENAME (Read)
*        Name of the text file to log the results.  If null, there
*        will be no logging.  Note this is intended for the human reader
*        and is not intended for passing to other applications.  [!]
*     MAJFWHM( 2 ) = _DOUBLE (Write)
*         The primary beam position's major-axis FWHM and its error, 
*         measured in the current co-ordinate Frame of the NDF.
*     MARK = LITERAL (Read)
*        Only accessed if Parameter MODE is given the value "Cursor". 
*        It indicates which positions are to be marked on the screen 
*        using the marker type given by Parameter MARKER.  It can take 
*        any of the following values.
*
*        - "Initial" -- The position of the cursor when the mouse 
*       button is pressed is marked.
*
*        - "Fit" -- The corresponding fit position is marked.
*
*        - "Ellipse" -- As "Fit" but it also plots an ellipse at the
*        FWHM radii and orientation.
*
*        - "None" -- No positions are marked.
*
*        [current value]
*     MARKER = INTEGER (Read)
*        This parameter is only accessed if Parameter MARK is set TRUE.
*        It specifies the type of marker with which each cursor 
*        position should be marked, and should be given as an integer
*        PGPLOT marker type.  For instance, 0 gives a box, 1 gives a
*        dot, 2 gives a cross, 3 gives an asterisk, 7 gives a triangle. 
*        The value must be larger than or equal to -31.  [current value]
*     MINFWHM( 2 ) = _DOUBLE (Write)
*        The primary beam position's minor-axis FWHM and its error,
*        measured in the current co-ordinate Frame of the NDF.
*     MODE = LITERAL (Read)
*        The mode in which the initial co-ordinates are to be obtained. 
*        The supplied string can be one of the following values.
*
*        - "Interface" -- positions are obtained using Parameters POS,
*        POS2--POS5.
*
*        - "Cursor" -- positions are obtained using the graphics cursor
*        of the device specified by Parameter DEVICE.
*
*        - "Catalogue" -- positions are obtained from a positions list
*        using Parameter INCAT.
*
*        -  "File" -- positions are obtained from a text file using 
*        Parameter COIN. 
*        [current value]
*     NDF = NDF (Read)
*        The NDF structure containing the data array to be analysed.  In
*        cursor mode (see Parameter MODE), the run-time default is the 
*        displayed data, as recorded in the graphics database.  In other
*        modes, there is no run-time default and the user must supply a
*        value.  []
*     OFFSET( ) = LITERAL (Write)
*        The formatted offset and its error of each secondary beam 
*        feature with respect to the primary beam.  They are measured in
*        the current Frame of the NDF along a latitude axis if that
*        Frame is in the SKY Domain, or the first axis otherwise.  The 
*        number of values stored is twice the number of beams.  The
*        array alternates an offset, then its corresponding error,
*        appearing in beam order starting with the first secondary beam.
*     ORIENT( 2 ) = _DOUBLE (Write)
*        The primary beam position's orientation and its error, measured
*        in degrees.  If the current WCS frame is a SKY Frame, the angle
*        is measured from North through East.  For other Frames the 
*        angle is from the X-axis through Y.
*     PA() = _REAL (Write)
*        The position angle and its errors of each secondary beam
*        feature with respect to the primary beam.  They are measured in
*        the current Frame of the NDF from North through East if that is
*        a SKY Domain, or anticlockwise from the Y axis otherwise.  The
*        number of values stored is twice the number of beams.  The
*        array alternates a position angle, then its corresponding 
*        error, appearing in beam order starting with the first
*        secondary beam.
*     PLOTSTYLE = LITERAL (Read)
*        A group of attribute settings describing the style to use when
*        drawing the graphics markers specified by Parameter MARK.
*
*        A comma-separated list of strings should be given in which each
*        string is either an attribute setting, or the name of a text 
*        file preceded by an up-arrow character "^".  Such text files 
*        should contain further comma-separated lists which will be 
*        read and interpreted in the same manner.  Attribute settings 
*        are applied in the order in which they occur within the list, 
*        with later settings overriding any earlier settings given for 
*        the same attribute.
*
*        Each individual attribute setting should be of the form:
*
*           <name>=<value>
*
*        where <name> is the name of a plotting attribute, and <value>
*        is the value to assign to the attribute.  Default values will
*        be used for any unspecified attributes.  All attributes will be
*        defaulted if a null value (!) is supplied.  See section 
*        "Plotting Attributes" in SUN/95 for a description of the 
*        available attributes.  Any unrecognised attributes are ignored
*        (no error is reported).  [current value]
*     POLAR = _LOGICAL (Read)
*        If TRUE, the co-ordinates supplied through POS2--POS5 are
*        interpreted in polar co-ordinates (offset, position angle) 
*        about the primary beam.  The radial co-ordinate is a distance 
*        measured in units of the latitude axis if the current WCS Frame
*        is a a SKY Domain, or the first axis for other Frames.  For a 
*        SKY current WCS Frame, position angle follows the standard
*        convention of North through East.  For other Frames the angle 
*        is measured from the second axis anticlockwise, e.g. for a 
*        PIXEL Frame it would be from Y through negative X, not the 
*        standard X through Y.
*
*        If FALSE, the co-ordinates are the regular axis co-ordinates in 
*        the current Frame.  
*
*        POLAR is only accessed when there is more than one beam to fit.
*        [TRUE]
*     POS = LITERAL (Read)
*        When MODE = "Interface" POS specifies the co-ordinates of the 
*        primary beam position.  This is either merely an initial guess
*        for the fit, or if Parameter FIXPOS is TRUE, it defines a
*        fixed location.  It is specified in the current co-ordinate 
*        Frame of the NDF (supplying a colon ":" will display details of
*        the current co-ordinate Frame).  A position should be supplied 
*        as a list of formatted WCS axis values separated by spaces or
*        commas, and should lie within the bounds of the NDF.

*        If the initial co-ordinates are supplied on the command line 
*        without BEAMS the number of contiguous POS, POS2,... parameters
*        specifies the number of beams to be fit.
*     POS2-POS5 = LITERAL (Read)
*        When MODE = "Interface" these parameters specify the 
*        co-ordinates of the secondary beam positions.  These should lie 
*        within the bounds of the NDF.  For each parameter the supplied 
*        location may be merely an initial guess for the fit, or if 
*        Parameter FIXPOS is TRUE, it defines a fixed location, unless 
*        Parameter FIXSEP is TRUE, whereupon it defines 
*        a fixed separation from the primary beam.
*
*        For POLAR = FALSE each distance should be given as a single
*        literal string containing a space- or comma-separated list of 
*        formatted axis values measured in the current co-ordinate Frame 
*        of the NDF.  The allowed formats depends on the class of the 
*        current Frame.  Supplying a single colon ":" will display 
*        details of the current Frame, together with an indication of 
*        the format required for each axis value, and a new parameter 
*        value is then obtained.

*        If Parameter POLAR is TRUE, POS2--POS5 may be given as an 
*        offset followed by a position angle.  See Parameter POLAR for 
*        more details of the sense of the angle and the offset 
*        co-ordinates.
*
*        The parameter name increments by 1 for each subsequent beam 
*        feature.  Thus POS2 applies to the first secondary beam
*        (second position in all), POS3 is for the second secondary 
*        beam, and so on.  As the total number of parameters required is
*        one fewer than the value of Parameter BEAMS, POS2--POS5 are 
*        only accessed when BEAMS exceeds 1.
*     REFOFF( 2 ) = LITERAL (Write)
*        The formatted offset followed by its error of the primary
*        beam's location with respect to the reference position (see
*        Parameter REFPOS).  The offset  might be used to assess the
*        optical alignment of an instrument.  The ofset and its error
*        are measured in the current Frame of the NDF along a latitude
*        axis if that Frame is in the SKY Domain, or the first axis
*        otherwise.  The error is derived entirely from the
*        uncertainities in the fitted position of the primary beam,
*        i.e. the reference position has no error attached to it.  By
*        definition the error is zero when FIXPOS is TRUE.
*     REFPOS = LITERAL (Read)
*        The reference position.  This is often the desired position for
*        the beam.  The offset of the primary beam with respect to this 
*        point is reported and stored in Parameter REFOFF.  It is only
*        accessed if the current WCS Frame in the NDF is not a SKY
*        Domain containing a reference position.

*        The co-ordinates are specified in the current WCS Frame of the
*        NDF (supplying a colon ":" will display details of the current
*        co-ordinate Frame).  A position should be supplied either as a
*        list of formatted WCS axis values separated by spaces or 
*        commas.  A null value (!) requests that the centre of the
*        supplied map is deemed to be the reference position.
*     RESID = NDF (Write)
*        The map of the residuals of the fit.  It inherits the
*        properties of the input NDF, except that its data type is 
*        _DOUBLE or _REAL depending on the precision demanded by the 
*         type of IN, and no variance is propagated.  A null (!) value 
*         requests that no residual map be created.  [!]
*     RMS = _REAL (Write)
*        The primary beam position's root mean-squared deviation from
*        the fit.
*     TITLE = LITERAL (Read)
*        The title for the NDF to contain the residuals of the fit.
*        If null (!) is entered the NDF will not contain a title.  
*        ["KAPPA - BEAMFIT"]
*     VARIANCE = _LOGICAL (Read)
*        If TRUE, then any VARIANCE component present within the input
*        NDF will be used to weight the fit; the weight used for each
*        data value is the reciprocal of the variance.  If set to FALSE 
*        or there is no VARIANCE present, all points will be given equal
*        weight.  [FALSE]

*  Examples:
*     beamfit mars_3pos i 1 "5.0,-3.5"
*        This finds the Gaussian coefficients of the primary beam
*        feature in the NDF called mars_3pos, using the supplied
*        co-ordinates (5.0,-3.5) for the initial guess for the beam's
*        centre.  The co-ordinates are measured in the NDF's current
*        co-ordinate Frame.  In this case they are offsets in
*        arcseconds.
*     beamfit ndf=mars_3pos mode=interface beams=1 pos="5.0,-3.5"
*             fixback=0.0
*        As above but now the background is fixed to be zero.
*     beamfit ndf=mars_3pos mode=interface beams=1 pos="5.0,-3.5" 
*             fixfwhm=16.5
*        As above but now the Gaussian is constrained to have a FWHM of
*        16.5 arcseconds and be circular.
*     beamfit mars_3pos in beams=1 fixfwhm=16.5 fitarea=51 pos="5.,-3.5"
*        As above but now the fitted data is restricted to areas 51x51
*        pixels about the initial guess positions.  All the other 
*        examples use the full array.
*     beamfit mars_3pos int 3 "5.0,-3.5" ampratio=-0.5 resid=mars_res
*        As the first example except this finds the Gaussian 
*        coefficients of the primary beam feature and two secondary 
*        features.  The secondary features have fixed amplitudes that 
*        are half that of the primary feature and of the opposite
*        polarity.  The residuals after subtracting the fit are stored
*        in NDF mars_res.  In all the other examples no residual map
*        is created.
*     beamfit mars_3pos int 2 "5.0,-3.5" pos2="60.0,90" fixpos
*        This finds the Gaussian coefficients of the primary beam
*        feature and a secondary feature in the NDF called mars_3pos.
*        The supplied co-ordinates (5.0,-3.5) define the centre, i.e.
*        they are not fitted.  Also the secondary beam is fixed at
*        60 arcseconds towards the East (position angle 90 degrees).
*     beamfit mars_3pos int 2 "5.0,-3.5" pos2="60.0,90" fixsep
*        As the previous example, except now the separation of the
*        second position is fixed at 60 arcseconds towards the East from
*        the primary beam, instead of being an absolute location.
*     beamfit mars_3pos int 2 "5.0,-3.5" pos2="-60.5,0.6" polar=f fixpos
*        As the last-but-one example, but now location of the secondary
*        beam is fixed at (-55.5,-2.9).
*     beamfit mode=cu beams=1
*        This finds the Gaussian coefficients of the primary beam
*        feature of an NDF, using the graphics cursor on the current 
*        graphics device to indicate the approximate centre of the 
*        feature.  The NDF being analysed comes from the graphics
*        database.
*     beamfit uranus cu 2 mark=ce plotstyle='colour=red' marker=3
*        This fits to two beam features in the NDF called uranus 
*        via the graphics cursor on the current graphics device.  The
*        beam positions are marked using a red asterisk.
*     beamfit uranus file 4 coin=features.dat logfile=uranus.log
*        This fits to the beam features in the NDF called uranus.  The
*        initial positions are given in the text file features.dat in
*        the current co-ordinate Frame.  Only the first four positions
*        will be used.  The last three positions are in polar
*        co-ordinates with respect to the primary beam.  A log of 
*        selected input parameter values, and the fitted coefficients 
*        and errors is written to the text file uranus.log.
*     beamfit uranus mode=cat incat=uranus_beams polar=f
*        This example reads the initial guess positions from the
*        positions list in file uranus_beams.FIT.  The number of beam
*        features fit is the number of positions in the catalogue
*        subject to a maximum of five.  The input file may, for
*        instance, have been created using the application CURSOR.

*  Notes:
*     -  All positions are supplied and reported in the current 
*     co-ordinate Frame of the NDF.  A description of the co-ordinate 
*     Frame being used is given if Parameter DESCRIBE is set to a TRUE
*     value.  Application WCSFRAME can be used to change the current
*     co-ordinate Frame of the NDF before running this application if 
*     required.
*     -  The uncertainty in the positions are estimated iteratively
*     using the curvature matrix derived from the Jacobian, itself
*     determined by a forward-difference approximation.
*     -  The fit parameters are not displayed on the screen when the
*     message filter environment variable MSG_FILTER is set to QUIET.

*  Related Applications:
*     KAPPA: PSF, CENTROID, CURSOR, LISTSHOW, LISTMAKE; ESP: GAUFIT;
*     Figaro: FITGAUSS.

*  Implementation Status:
*      -  Processing of bad pixels and automatic quality masking are
*      supported.
*      -  All non-complex numeric data types can be handled.  Arithmetic
*      is performed using double-precision floating point.

*  Copyright:
*     Copyright (C) 2007 Particle Physics & Astronomy Research Council.
*     Copyright (C) 2009 Science and Technology Facilities Council. 
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either Version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE.  See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
*     MA 02111-1307, USA.

*  Authors:
*     MJC: Malcolm J. Currie  (STARLINK)
*     {enter_new_authors_here}

*  History:
*     2007 January 17 (MJC):
*        Original version based on CENTROID.
*     2007 April 27 (MJC):
*        Add FIXAMP and FIXRAT.  Changed to concurrent fitting of
*        multiple Gaussians, from a series of fits to individual
*        Gaussians.
*     2007 May 11 (MJC):
*        Use an array for the fixed parameters.
*     2007 May 14 (MJC):
*        Add SEPARATION parameter.
*     2007 May 22 (MJC):
*        Improve and correct documentation.  Made SEPARATION a series of
*        Parameters SEP--SEP4 to allow command-line access.  Revise
*        calls to routines whose APIs have changed.
*     2007 June 1 (MJC):
*        Add Parameters OFFSET, PA, and POLAR.
*     2007 June 4 (MJC):
*        Polar co-ordinates demanded a further restructuring of the code
*        and revised parameters.  Parameter FIXSEP was introduced, 
*        SEP1--SEP4 were removed, and INIT1--INIT5 have become POS and 
*        POS2--POS5 overloading meanings depending on the values of
*        FIXPOS and FIXSEP.
*     2007 June 8 (MJC):
*        Add RESID parameter and calculation of the residual-image NDF.
*        Rework derivation of the number of positions from the command
*        line.  Remove unused variables.
*     2007 June 15 (MJC):
*        Added Parameters REFPOS and REFOUT, and Ellipse option to
*        MARK.
*     2007 July 9 (MJC):
*        Do not ignore SkyRef attribute for the reference position when 
*        the SkyRefIs attribute is set to Ignored.  Record which
*        reference point is being used.
*     2009 January 31 (MJC):
*        Clarify some of the parameter descriptions.  Flag that we
*        have a reference position for SkyRefIs=Origin.
*     2009 July 22 (MJC):
*        Remove QUIET parameter and use the current reporting level
*        instead (set by the global MSG_FILTER environment variable).
*     {enter_further_changes_here}

*-

*  Type Definitions:
      IMPLICIT  NONE             ! No implicit typing allowed

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! SSE global definitions
      INCLUDE 'DAT_PAR'          ! Data-system constants
      INCLUDE 'AST_PAR'          ! AST constants and functions
      INCLUDE 'NDF_PAR'          ! NDF definitions
      INCLUDE 'MSG_PAR'          ! Message-system constants
      INCLUDE 'PAR_PAR'          ! Parameter-system constants
      INCLUDE 'PAR_ERR'          ! Parameter-system errors
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function
      INCLUDE 'PRM_PAR'          ! PRIMDAT constants
      INCLUDE 'BF_PAR'           ! Used for array size constants

*  Status:
      INTEGER  STATUS

*  Local Constants:
      INTEGER MXPOS              ! Maximum number of beam positions
      PARAMETER ( MXPOS = 5 )

      INTEGER MXCOEF              ! Maximum number of fit coefficients
      PARAMETER ( MXCOEF = BF__NCOEF * BF__MXPOS )

*  Local Variables:
      REAL AMPRAT( BF__MXPOS - 1 ) ! Amplitude ratios
      
      DOUBLE PRECISION ATTR( 20 )! Saved graphics attribute values
      CHARACTER*9 ATT            ! AST attribute name
      DOUBLE PRECISION BC( BF__NDIM )! Dummy base co-ordinates
      CHARACTER*132  BUFOUT      ! Buffer for writing the logfile
      LOGICAL CAT                ! Catalogue mode was selected
      DOUBLE PRECISION CENTRE( BF__NDIM ) ! Map centre pixel co-ords
      INTEGER CFRM               ! Pointer to Current Frame of the NDF
      LOGICAL CURSOR             ! Cursor mode was selected
      LOGICAL DESC               ! Describe the current Frame?
      INTEGER DIMS( BF__NDIM )   ! Dimensions of NDF
      CHARACTER*( NDF__SZFTP ) DTYPE ! Numeric type for results
      INTEGER EL                 ! Number of mapped elements
      LOGICAL FAREA              ! Full data area to be used?
      INTEGER FDL                ! File description of logfile
      LOGICAL FILE               ! File mode was selected?
      INTEGER FITREG( BF__NDIM ) ! Size of fitting region to be used
      DOUBLE PRECISION FPAR( MXCOEF ) ! Stores fixed parameter values
      LOGICAL FIXCON( BF__NCON ) ! Constraints set?
      DOUBLE PRECISION FWHM( BF__NDIM ) ! Fixed FWHM
      LOGICAL GOTLOC             ! Locator to the NDF obtained?
      LOGICAL GOTNAM             ! Reference name of the NDF obtained?
      LOGICAL GOTREF             ! Reference position obtained?
      LOGICAL HASVAR             ! Errors to be calculated
      INTEGER I                  ! Loop counter
      INTEGER IMARK              ! PGPLOT marker type
      DOUBLE PRECISION INPOL( 2 ) ! Pole co-ordinates
      LOGICAL ISSKY              ! Current Frame in SKY Domain?
      LOGICAL INTERF             ! Interface mode selected?
      INTEGER IPD                ! Pointer to input data array
      INTEGER IPIC               ! AGI identifier for last data picture
      INTEGER IPIC0              ! AGI identifier for original current 
                                 ! picture
      INTEGER IPID               ! Pointer to array of position 
                                 ! identifiers
      INTEGER IPIN               ! Pointer to array of supplied 
                                 ! positions
      INTEGER IPIX               ! Index of PIXEL Frame in IWCS
      INTEGER IPLOT              ! Plot obtained from graphics database
      INTEGER IPRES              ! Pointer to residuals data array
      CHARACTER*( NDF__SZTYP ) ITYPE ! Data type for residuals map
      INTEGER IWCS               ! WCS FrameSet from input NDF
      INTEGER IWCSG              ! FrameSet read from input catalogue
      INTEGER J                  ! Loop counter and index
      CHARACTER*(DAT__SZLOC) LOCI ! Locator for input data structure
      LOGICAL LOGF               ! Write log of positions to text file?
      LOGICAL LOOP               ! Loop for more cmd-line POS params?
      INTEGER MAP1               ! Mapping from PIXEL Frame to Current 
                                 ! Frame
      INTEGER MAP2               ! Mapping from supplied Frame to 
                                 ! Current Frame
      INTEGER MAP3               ! Mapping from supplied Frame to PIXEL 
                                 ! Frame
      CHARACTER*8 MARK           ! Positions to mark
      CHARACTER*10 MODE          ! Mode for getting initial co-ords 
      LOGICAL MORE               ! Obtain another separation?
      INTEGER MSGFIL             ! Initial message-system filter level
      INTEGER NAMP               ! Number of amplitude ratios supplied
      INTEGER NAXC               ! Number of axes in current NDF Frame
      INTEGER NAXIN              ! Number of axes in supplied Frame
      INTEGER NC                 ! Character column counter
      INTEGER NDFI               ! Input NDF identifier
      INTEGER NDFR               ! Residuals map's NDF identifier
      CHARACTER*256 NDFNAM       ! Name of input IMAGE
      INTEGER NDIMS              ! Number of significant dimensions of 
                                 ! the NDF
      INTEGER NPOS               ! Number of supplied beam positions
      INTEGER NVAL               ! Number of values returned for a
                                 ! parameter
      DOUBLE PRECISION OFF1( NDF__MXDIM ) ! Separation for one position
      DOUBLE PRECISION OFFSET( BF__MXPOS - 1, NDF__MXDIM )! Separations
      CHARACTER*( PAR__SZNAM + 1 ) PARNAM ! Parameter name for the
                                 ! current initial beam position
      LOGICAL POLAR              ! Use polar co-ordinates for POS2-POS5?
      LOGICAL POSC               ! Centre fixed at supplied position?
      LOGICAL QUIET              ! Suppress screen output?
      CHARACTER*22 REFLAB        ! Label describing reference point
      CHARACTER*256 REFNAM       ! Reference name
      DOUBLE PRECISION REFPOS( BF__NDIM ) ! Reference position
      DOUBLE PRECISION S2FWHM    ! Standard deviation to FWHM
      INTEGER SDIM( BF__NDIM )   ! Significant dimensions of the NDF
      CHARACTER*4 SEPAR          ! SEPn parameter name
      INTEGER SLBND( BF__NDIM )  ! Significant lower bounds of the image
      CHARACTER*3 SPARAM         ! Parameter root for fixed separations
      CHARACTER*7 SKYREF         ! Value of Frame attribute SkyRefIs
      INTEGER STATE              ! State of POSx parameter
      INTEGER SUBND( BF__NDIM )  ! Significant upper bounds of the image
      CHARACTER*80 TITLE         ! Title for output positions list
      LOGICAL VAR                ! Use variance for weighting
      INTEGER WAX                ! Index of axis measuring fixed FWHMs

*.

*  Check the inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise.
      GOTLOC = .FALSE.
      GOTNAM = .FALSE.
      LOGF = .FALSE.
      FILE = .FALSE.
      NPOS = 0
      MARK = ' '

*  Initialise pointers for valgrind.
      IPIN = 0
      IPID = 0

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Begin an NDF context.
      CALL NDF_BEGIN

*  See whether quiet mode is required, i.e not at NORMAL or lower
*  priority.
      QUIET = .NOT. MSG_FLEVOK( MSG__NORM, STATUS )

*  Attempt to open a log file to store the results for human readers.  
      CALL FIO_ASSOC( 'LOGFILE', 'WRITE', 'LIST', 80, FDL, STATUS )

*  Annul the error if a null value was given, and indicate that a log
*  file is not to be created.
      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )

      ELSE IF ( STATUS .EQ. SAI__OK ) THEN
         LOGF = .TRUE.

      END IF

*  Remind the user about the log file, if required.
      IF ( LOGF ) CALL MSG_OUTIF( MSG__NORM, 'LOG', 
     :                            '  Logging to $LOGFILE', STATUS )

*  Select & initialise beam-selection mode
*  =======================================

*  Find where the initial guess positions are to be obtained from.
      CALL PAR_CHOIC( 'MODE', 'Interface', 'Interface,Cursor,'//
     :                'Catalogue,File', .TRUE., MODE, STATUS )

*  Set convenience flags for the various values of MODE.
      CURSOR = MODE .EQ. 'CURSOR'
      CAT = MODE .EQ. 'CATALOGUE'
      FILE = MODE .EQ. 'FILE'
      INTERF = MODE .EQ. 'INTERFACE'
      TITLE = ' '

*  Abort if an error occurred.
      IF ( STATUS .NE.  SAI__OK ) GO TO 999

      NPOS = -1

*  No initialization needed for "File" mode.  We cannot read the 
*  contents of a file yet, because we do not yet have an NDF and so do
*  not know how many columns the file must contain.
      IF ( FILE ) THEN

*  In "Catalogue" mode, open a positions list catalogue and read its
*  contents.  A pointer to a FrameSet is returned, together with 
*  pointers to positions and identifiers, and a title.  The positions 
*  are returned in the Base Frame of this FrameSet.
      ELSE IF ( CAT ) THEN
         IWCSG = AST__NULL
         CALL KPG1_RDLST( 'INCAT', .FALSE., IWCSG, NPOS, NAXIN, IPIN, 
     :                    IPID, TITLE, ' ', STATUS )
         NPOS = MIN( NPOS, BF__MXPOS )

*  In "Cursor" mode, open and prepare the graphics device.
      ELSE IF ( CURSOR ) THEN

*  Open the graphics device for plotting with PGPLOT, obtaining an
*  identifier for the current AGI picture.
         CALL KPG1_PGOPN( 'DEVICE', 'UPDATE', IPIC0, STATUS )

*  Find the most recent DATA picture.
         CALL KPG1_AGFND( 'DATA', IPIC, STATUS )

*  Report the name, comment, and label, if one exists, for the current 
*  picture.
         CALL KPG1_AGATC( STATUS )

*  Set the PGPLOT viewport and AST Plot for this DATA picture.  The 
*  PGPLOT viewport is set equal to the selected picture, with world 
*  co-ordinates giving millimetres from the bottom-left corner of the 
*  view surface.  The returned Plot may include a Frame with Domain 
*  AGI_DATA representing AGI DATA co-ordinates (defined by a TRANSFORM 
*  structure stored with the picture in the database).
         CALL KPG1_GDGET( IPIC, AST__NULL, .TRUE., IPLOT, STATUS )

*  See what markers are to be drawn.
         CALL PAR_CHOIC( 'MARK', 'Fit', 'Fit,Ellipse,Initial,None',
     :                   .FALSE., MARK, STATUS )

*  If so, get the marker type, and set the plotting style.
         IF ( MARK .NE.  'NONE' ) THEN
            CALL PAR_GDR0I( 'MARKER', 2, -31, 10000, .FALSE., IMARK, 
     :                      STATUS )
            CALL KPG1_ASSET( 'KAPPA_BEAMFIT', 'PLOTSTYLE', IPLOT, 
     :                       STATUS )

*  Set the current PGPLOT marker attributes (size, colour, etc.) so 
*  that they are the same as the marker attributes specified in the
*  Plot.  The pre-existing PGPLOT attribute values are saved in ATTR.
            CALL KPG1_PGSTY( IPLOT, 'MARKERS', .TRUE., ATTR, STATUS )
         END IF

*  Abort if an error has occurred.
         IF ( STATUS .NE. SAI__OK ) GO TO 999 

*  Obtain a reference to the NDF.
         CALL KPG1_AGREF( IPIC, 'READ', GOTNAM, REFNAM, STATUS )

*  See whether the reference is a name or locator.  The latter should be
*  phased out, but there may be some old databases and software
*  in circulation.
         CALL DAT_VALID( REFNAM, GOTLOC, STATUS )
         IF ( GOTLOC ) LOCI = REFNAM

*  End immediately if there an error.
         IF ( STATUS .NE. SAI__OK ) GO TO 999

*  "Interface" mode.
      ELSE IF ( INTERF ) THEN

*  If the initial co-ordinates are supplied on the command line and
*  without BEAMS, we count the number of beams to be fitted.  The
*  parameter names must be contiguous.
         I = 1
         CALL LPG_STATE( 'BEAMS', STATE, STATUS )
         LOOP = STATE .NE. PAR__ACTIVE

         DO WHILE ( I .LE. BF__MXPOS .AND. LOOP )

*  Create separate parameter names for each beam position.
            PARNAM = 'POS'
            IF ( I .GT. 1 ) THEN
               NC = 3
               CALL CHR_PUTI( I, PARNAM, NC )
            END IF

*  Was the parameter supplied on the command line?
            CALL LPG_STATE( PARNAM, STATE, STATUS )

            IF ( STATE .EQ. PAR__ACTIVE ) THEN
               NPOS = I
            ELSE
               LOOP = .FALSE.
            END IF
            I = I + 1
         END DO
      END IF

*  Obtain the NDF & WCS Frame
*  ==========================

*  Obtain the NDF.  If the name is given on the command line it will be 
*  used.  If not, the database data reference is used, if there is one. 
*  Otherwise, the user is prompted.
      CALL KPG1_ASREF( 'NDF', 'READ', GOTNAM, REFNAM, NDFI, STATUS )

*  Check that there is variance present in the NDF.
      CALL NDF_STATE( NDFI, 'Variance', HASVAR, STATUS )

*  If all input have variance components, see if input variances are to 
*  be used as weights.
      IF ( HASVAR ) THEN
         CALL PAR_GET0L( 'VARIANCE', VAR, STATUS )
      ELSE
         VAR = .FALSE.
      END IF      

*  We need to know how many significant axes there are (i.e. pixel axes
*  spanning more than a single pixel), and there must not be more than
*  two.
      CALL KPG1_SGDIM( NDFI, BF__NDIM, SDIM, STATUS )

*  Now get the WCS FrameSet from the NDF.
      CALL KPG1_ASGET( NDFI, BF__NDIM, .TRUE., .FALSE., .FALSE., SDIM, 
     :                 SLBND, SUBND, IWCS, STATUS )
      DO I = 1, BF__NDIM
         DIMS( I ) = SUBND( I ) - SLBND( I ) + 1
      END DO

*  In case the data have come from a cube with an insignificant axis
*  recording the co-ordinate of the plane from which the two-dimensional
*  array was derived, we want to extract a Current Frame that has no
*  insignificant axes.
      CALL KPG1_ASSIG( IWCS, BF__NDIM, SLBND, SUBND, STATUS )

*  Get a pointer to the possibly new Current Frame in the NDF.
      CFRM = AST_GETFRAME( IWCS, AST__CURRENT, STATUS )

*  Save the number of Current Frame axes.  This should be BF__NDIM.
*  Leave it parameterised in case the alloweddimensionality is 
*  extended.
      NAXC = AST_GETI( CFRM, 'NAXES', STATUS )

*  Get the Mapping from the Current Frame to PIXEL in the NDF.  First
*  find the index of the PIXEL Frame, and then get the Mapping.
      CALL KPG1_ASFFR( IWCS, 'PIXEL', IPIX, STATUS )
      MAP1 = AST_SIMPLIFY( AST_GETMAPPING( IWCS, IPIX, AST__CURRENT, 
     :                                     STATUS ), STATUS )

*  Is it a sky domain?
      ISSKY = AST_ISASKYFRAME( CFRM, STATUS )

      IF ( STATUS .NE. SAI__OK ) GO TO 999

*  Obtain the AST Frame of input beam co-ordinates.
*  ================================================

*  We now get the AST Mapping from the Frame in which the positions are
*  supplied to the Current Frame of the NDF.
      IF ( CURSOR ) THEN

*  In cursor mode, the positions will be supplied in GRAPHICS 
*  co-ordinates (i.e.  millimetres from the bottom-left corner of the 
*  screen).  Merge the Plot read from the graphics database with the 
*  FrameSet read from the NDF aligning them in some suitable Frame.  
         CALL KPG1_ASMRG( IPLOT, IWCS, ' ', QUIET, 0, STATUS )

*  Get the Mapping.
         MAP2 = AST_SIMPLIFY( AST_GETMAPPING( IPLOT, AST__BASE, 
     :                                        AST__CURRENT, STATUS ),
     :                        STATUS )

*  In catalogue mode, the positions are supplied in the Base Frame of
*  the FrameSet stored in the catalogue.  Merge this FrameSet with the 
*  FrameSet read from the NDF aligning them in some suitable Frame.  
      ELSE IF ( CAT ) THEN
         CALL KPG1_ASMRG( IWCSG, IWCS, ' ', QUIET, 0, STATUS )

*  Get the Mapping.
         MAP2 = AST_SIMPLIFY( AST_GETMAPPING( IWCSG, AST__BASE, 
     :                                        AST__CURRENT, STATUS ),
     :                        STATUS )


*  In the other modes, the positions are supplied in the Current Frame.
      ELSE
         MAP2 = AST_UNITMAP( NAXC, ' ', STATUS )
      END IF

*  Find the Mapping from input Frame to PIXEL co-ordinates
*  =======================================================

*  Save the number of axes in the Frame in which the positions are
*  supplied.
      NAXIN = AST_GETI( MAP2, 'NIN', STATUS )

*  We need the Mapping from the Frame in which the positions are
*  supplied, to the PIXEL Frame of the NDF.  We get this Mapping by
*  concatenating the Mapping from input Frame to Current Frame, with 
*  the Mapping from Current Frame to PIXEL Frame (obtained by 
*  temporarily inverting the Mapping from PIXEL to Current Frame).
      CALL AST_INVERT( MAP1, STATUS )
      MAP3 = AST_SIMPLIFY( AST_CMPMAP( MAP2, MAP1, .TRUE., ' ', 
     :                                 STATUS ), STATUS )
      CALL AST_INVERT( MAP1, STATUS )

*  See if a description of the NDFs current Frame is required.
      CALL PAR_GET0L( 'DESCRIBE', DESC, STATUS )

*  If so, give a detailed description of the Frame in which positions 
*  will be reported if required.
      IF ( DESC .AND. .NOT. QUIET ) THEN
         CALL KPG1_DSFRM( CFRM, 'Positions will be reported in the '//
     :                    'following co-ordinate Frame:', .TRUE.,
     :                    STATUS )
      END IF

*  If we are in "File" mode, obtain the file and read the positions,
*  interpreting them as positions within the Current Frame of the NDF.
*  A pointer to memory holding the positions is returned.  Store a safe
*  value for the IPID pointer.  Identifiers are generated automatically 
*  in File mode instead of being read from the file, and so we do not
*  have a pointer to an array of identifiers at this point.
      IF ( FILE ) THEN
         CALL KPG1_ASFIL( 'COIN', ' ', CFRM, NPOS, IPIN, ' ', STATUS )
         IF ( NPOS .EQ. 0 ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'BEAMFIT_EMPTYFILE', 'No data records of '//
     :                    'formatted positions found.', STATUS )
            GO TO 999
         END IF
         IPID = IPIN
      END IF

      IF ( FILE .OR. CAT ) THEN
         IF ( NPOS .GT. 1 ) THEN
            CALL MSG_SETI( 'NPOS', NPOS )
            CALL MSG_OUTIF( MSG__NORM, ' ', 
     :                      '  ^NPOS beam positions read', STATUS )
         ELSE
            CALL MSG_OUTIF( MSG__NORM, ' ', 
     :                      '  One beam position read', STATUS )
         END IF
      END IF


*  Additional Parameters
*  =====================

*  Obtain the number of beam positions if it's not been determined
*  already.
      IF ( NPOS .EQ. -1 ) CALL PAR_GDR0I( 'BEAMS', 1, 1, BF__MXPOS, 
     :                                    .FALSE., NPOS, STATUS )

*  Initialise in case there may be more.
      DO I = 1, MXCOEF
         FPAR( I ) = VAL__BADD
      END DO

*  We need to specify which axis to use for the widths and separations.
*  By convention this is the latitude axis of a SkyFrame or the first 
*  axis otherwise.
      IF ( ISSKY ) THEN
         WAX = AST_GETI( CFRM, 'LATAXIS', STATUS )
      ELSE
         WAX = 1
      END IF

*  Fit area
*  --------
*  Obtain the fitting region sizes, duplicating the value if only a 
*  single value is given.
      FAREA = .FALSE.
      CALL PAR_GDRVI( 'FITAREA', BF__NDIM, 9, 99999, FITREG, NVAL, 
     :                STATUS )
      IF ( STATUS .EQ. SAI__OK .AND. NVAL .LT. BF__NDIM ) THEN
         DO I = NVAL + 1, BF__NDIM
            FITREG( I ) = FITREG( 1 )
         END DO
      ELSE IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         FAREA = .TRUE.
         DO I = 1, BF__NDIM
            FITREG( I ) = DIMS( I )
         END DO
      END IF

*  Constrain the search area to be no bigger than the image.
      DO  I = 1, BF__NDIM
         FITREG( I ) = MIN( DIMS( I ), FITREG( I ) )
      END DO

*  Reference position
*  ------------------

*  SkyRefIs origin means an offset plot about the reference position,
*  so therefore in this co-ordinate system the reference position is
*  at the origin.
      GOTREF = .FALSE.
      IF ( ISSKY ) THEN
         SKYREF = AST_GETC( CFRM, 'SkyRefIs', STATUS )      
         IF ( SKYREF .EQ. 'Origin' ) THEN
            REFPOS( 1 ) = 0.0D0
            REFPOS( 2 ) = 0.0D0
            GOTREF = .TRUE.

*  Extract the co-ordinates of the reference position in the current
*  Frame.  These are in radians.
         ELSE
            DO I = 1, BF__NDIM
               ATT = 'SkyRef('
               NC = 7
               CALL CHR_PUTI( I, ATT, NC )
               CALL CHR_APPND( ')', ATT, NC )
               REFPOS( I ) = AST_GETD( CFRM, ATT( : NC ), STATUS )
            END DO
            GOTREF = REFPOS( 1 ) .NE. VAL__BADD .AND. 
     :               REFPOS( 2 ) .NE. VAL__BADD
            IF ( GOTREF ) REFLAB = 'sky reference position'
         END IF
      END IF

      IF ( .NOT. GOTREF ) THEN

*  Find the image centre in PIXEL co-ordinates and convert the location 
*  to the current Frame.
         DO I = 1, BF__NDIM
            CENTRE( I ) = 0.5D0 * ( DBLE( SLBND( I ) + SUBND( I ) ) ) -
     :                    0.5D0 
         END DO

         CALL AST_TRANN( MAP1, 1, BF__NDIM, 1, CENTRE, .TRUE., BF__NDIM,
     :                   1, REFPOS, STATUS )

*  Obtain the reference position.  Use the map centre as the dynamic 
*  default when a null is supplied.
         CALL KPG1_GTPOS( 'REFPOS', CFRM, .TRUE., REFPOS, BC, STATUS )
         REFLAB = 'map centre'
      END IF

*  Is the amplitude fixed?
*  -----------------------
      CALL PAR_GDR0D( 'FIXAMP', 1.0D0, VAL__MIND, VAL__MAXD, .FALSE., 
     :                FPAR( 6 ), STATUS )

      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         FIXCON( 1 ) = .FALSE.
      ELSE
         FIXCON( 1 ) = .TRUE.
         IF ( NPOS .GT. 1 ) THEN
            DO I = 2, NPOS
               FPAR( 6 + ( I - 1 ) * BF__NCOEF ) = FPAR( 6 )
            END DO
         END IF
      END IF

*  Is the background fixed?
*  ------------------------
      CALL PAR_GDR0D( 'FIXBACK', 0.0D0, VAL__MIND, VAL__MAXD, .FALSE., 
     :                FPAR( 7 ), STATUS )

      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         FIXCON( 2 ) = .FALSE.
      ELSE
         FIXCON( 2 ) = .TRUE.
         IF ( NPOS .GT. 1 ) THEN
            DO I = 2, NPOS
               FPAR( 7 + ( I - 1 ) * BF__NCOEF ) = FPAR( 7 )
            END DO
         END IF
      END IF

*  Is the FWHM fixed?
*  ------------------
      S2FWHM = SQRT( 8.D0 * LOG( 2.D0 ) )

*  Obtain the FIXFWHM parameter value(s).  There is no dynamic default.
      FWHM( 1 ) = AST__BAD
      FWHM( 2 ) = AST__BAD
      CALL KPG1_GTAXV( 'FIXFWHM', BF__NDIM, .FALSE., CFRM, WAX, FWHM,
     :                 NVAL, STATUS )
      
      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         FIXCON( 3 ) = .FALSE.
      ELSE

*  Assign the single (circular) fixed value.
         FIXCON( 3 ) = .TRUE.
         IF ( NVAL .EQ. 1 ) THEN
            DO I = 1, NPOS
               J = ( I - 1 ) * BF__NCOEF

*  Note we calculate the standard deviations of the Gaussian, so apply
*  the standard scaling.
               FPAR( 3 + J ) = FWHM( 1 ) / S2FWHM
               FPAR( 4 + J ) = FPAR( 3 + J )
               FPAR( 5 + J ) = 0.0D0
            END DO

*  We've been supplied with the major and minor axes.
         ELSE
            DO I = 1, NPOS
               J = ( I - 1 ) * BF__NCOEF

*  Note we calculate the standard deviations of the Gaussian, so apply
*  the standard scaling.
               FPAR( 3 + J ) = MAX( FWHM( 1 ), FWHM( 2 ) ) / S2FWHM
               FPAR( 4 + J ) = MIN( FWHM( 1 ), FWHM( 2 ) ) / S2FWHM
            END DO
         END IF
      END IF

*  Positions
*  ---------
*  Use the initial co-ordinates rather than fitting.
      CALL PAR_GET0L( 'FIXPOS', FIXCON( 4 ), STATUS )

*  Amplitude ratios
*  ----------------
      FIXCON( 5 ) = .FALSE.
      IF ( NPOS .GT. 1 ) THEN
         CALL PAR_GDRVR( 'AMPRATIO', NPOS - 1, -2.0, 2.0, AMPRAT, 
     :                   NAMP, STATUS )

         IF ( STATUS .EQ. PAR__NULL ) THEN
            CALL ERR_ANNUL( STATUS )
         ELSE
            FIXCON( 5 ) = .TRUE.
            IF ( NAMP .LT. NPOS - 1 ) THEN
               DO I = NAMP, NPOS - 1
                  AMPRAT( I ) = AMPRAT( NAMP )
               END DO
            END IF
         END IF
      END IF

*  Are the separations fixed?
*  --------------------------
      CALL PAR_GET0L( 'FIXSEP', FIXCON( 6 ), STATUS )

      POLAR = .FALSE.
      IF ( NPOS .GT. 1 ) THEN

*  Are the POS2--POS5 parameters to be specified in polar co-ordinates 
*  about the primary beam's centre?  A null defaults to TRUE.
         CALL PAR_GTD0L( 'POLAR', .TRUE., .TRUE., POLAR, STATUS )

      END IF

*  Record input data in the log file.
*  ==================================
      IF ( LOGF .AND. STATUS .EQ. SAI__OK ) THEN

*  NDF name
*  --------
*  Store the NDF name in the logfile, aligning with the rest of the
*  output.
         CALL NDF_MSG( 'NAME', NDFI )
         CALL MSG_LOAD( 'DATASET', '    NDF             : ^NAME',
     :                  BUFOUT, NC, STATUS )
         CALL FIO_WRITE( FDL, BUFOUT( : NC ), STATUS )
      END IF

*  Display the header.
      CALL KPS1_BFHD( CFRM, LOGF, FDL, NAXC, TITLE, STATUS )
         
*  Fitting region
*  --------------
      IF ( LOGF ) THEN

*  Form string for the search areas.
         BUFOUT = '    Fitting area    : '
         NC = 22
         DO  J = 1, BF__NDIM
            CALL CHR_PUTI( FITREG( J ), BUFOUT, NC )
            IF ( J .LT. BF__NDIM ) CALL CHR_PUTC( ', ', BUFOUT, NC )
         END DO
         CALL CHR_PUTC( ' pixels',  BUFOUT, NC )
         CALL FIO_WRITE( FDL, BUFOUT( :NC ), STATUS )

      END IF

*  Do the fitting
*  ==============

*  Process all the supplied beams together as a single batch in
*  non-interactive modes.  These invoke the routine KPS1_BFOP that
*  records all the results parameters.
      IF ( CAT .OR. FILE ) THEN

*  Find the beam parameters and determine errors, and report them.
         CALL KPS1_BFFIL( NDFI, IWCS, MAP3, MAP1, MAP2, CFRM, VAR, NPOS,
     :                    NAXC, NAXIN, %VAL( CNF_PVAL( IPIN ) ), CAT, 
     :                    %VAL( CNF_PVAL( IPID ) ), LOGF, FDL, FIXCON,
     :                    AMPRAT, SLBND, SUBND, FAREA, FITREG, REFPOS,
     :                    REFLAB, MXCOEF, FPAR, STATUS )

*  In interactive modes, find each beam individually, waiting for the
*  user to supply a new one before continuing each time.
      ELSE

*  Fit the beams obtained interactively, and determine errors. 
*  Display the results.
         CALL KPS1_BFINT( NDFI, IWCS, IPLOT, MAP3, MAP1, MAP2, CFRM, 
     :                    VAR, NPOS, POLAR, 'POS', CURSOR, MARK, IMARK,
     :                    NAXC, NAXIN, LOGF, FDL, FIXCON, AMPRAT, SLBND,
     :                    SUBND, FAREA, FITREG, REFPOS, REFLAB, MXCOEF,
     :                    FPAR, STATUS )

      END IF

*  Create residuals map
*  ====================
      CALL ERR_MARK

*  Start a new NDF context.
      CALL NDF_BEGIN

*  Create a new NDF, by propagating the shape, size, WCS, etc. from the
*  input NDF,
      CALL LPG_PROP( NDFI, 'NOLABEL,WCS,AXIS', 'RESID', NDFR, STATUS )

*  Determine the data type to use for the residuals map.
      CALL NDF_MTYPE( '_REAL,_DOUBLE', NDFI, NDFI, 'Data', ITYPE,
     :                DTYPE, STATUS )

*  Map it for write access.
      CALL KPG1_MAP( NDFR, 'Data', ITYPE, 'WRITE', IPRES, EL, STATUS )

*  Map the input data array.
      CALL KPG1_MAP( NDFI, 'Data', ITYPE, 'READ', IPD, EL, STATUS )

*  Fill the data array with the evaluated point-spread function less
*  the original array.
      IF ( ITYPE .EQ. '_DOUBLE' ) THEN
         CALL KPS1_BFRED( DIMS( 1 ), DIMS( 2 ), %VAL( CNF_PVAL( IPD ) ),
     :                    SLBND, NPOS, MXCOEF, FPAR,
     :                    %VAL( CNF_PVAL( IPRES ) ), STATUS )
      ELSE
         CALL KPS1_BFRER( DIMS( 1 ), DIMS( 2 ), %VAL( CNF_PVAL( IPD ) ),
     :                    SLBND, NPOS, MXCOEF, FPAR, 
     :                    %VAL( CNF_PVAL( IPRES ) ), STATUS )
      END IF

*  Store a title.
      CALL NDF_CINP( 'TITLE', NDFR, 'TITLE', STATUS )

*  Store a label.
      CALL NDF_CPUT( 'BEAMFIT residuals map', NDFR, 'Lab', STATUS )

*  A null status can be ignored.  This means that no output NDF was
*  required.
      IF ( STATUS .EQ. PAR__NULL ) CALL ERR_ANNUL( STATUS )

*  End the NDF context.
      CALL NDF_END( STATUS )
      
      CALL ERR_RLSE


*  Tidy up.
*  ========
 999  CONTINUE

*  Close any open files.
      IF ( LOGF ) CALL FIO_ANNUL( FDL, STATUS )

*  End the NDF context.
      CALL NDF_END( STATUS )

*  Release the dynamic arrays holding the input positions and 
*  identifiers in catalogue mode.
      IF ( CAT ) THEN
         CALL PSX_FREE( IPID, STATUS )
         CALL PSX_FREE( IPIN, STATUS )

*  Release the dynamic arrays holding the input positions and 
*  identifiers in file mode.
      ELSE IF ( FILE ) THEN
         CALL PSX_FREE( IPIN, STATUS )

*  Do cursor mode tidying...
      ELSE IF ( CURSOR ) THEN

*  Annul the locator to the reference object.
         IF ( GOTLOC ) CALL REF_ANNUL( LOCI, STATUS )
         CALL DAT_VALID( LOCI, GOTLOC, STATUS )
         IF ( GOTLOC ) CALL DAT_ANNUL( LOCI, STATUS )

*  Re-instate any changed PGPLOT marker attributes.
         IF ( MARK .NE. 'NONE' ) CALL KPG1_PGSTY( IPLOT, 'MARKERS', 
     :                                           .FALSE., ATTR, STATUS )

*  Close the graphics database and device.
         CALL KPG1_PGCLS( 'DEVICE', .FALSE., STATUS )

      END IF

*  End the AST context.
      CALL AST_END( STATUS )

*  Give a contextual error message if anything went wrong.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'BEAMFIT_ERR', 'BEAMFIT: Failed to fit to '//
     :                 'the beams.', STATUS )
      END IF

      END
