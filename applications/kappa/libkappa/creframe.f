      SUBROUTINE CREFRAME(STATUS)
*+
*  Name:
*     CREFRAME

*  Purpose:
*     Generates a test 2-d NDF with a selection of several forms.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL CREFRAME( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application creates a 2-dimensional output NDF containing
*     artificial data of various forms (see parameter MODE). The output 
*     NDF can, optionally, have a Variance component describing the noise 
*     in the Data array (see parameter VARIANCE), and additionally a 
*     randomly generated pattern of bad pixels (see parameter BADPIX). 
*     Bad columns or rows of pixels can also be generated 

*  Usage:
*     creframe out mode [lbound] [ubound]

*  ADAM Parameters:
*     BACKGROUND = _REAL (Read)
*        Background intensity to be used in the generated data array.
*        Must not be negative. (GS mode).
*     BADCOL = _INTEGER (Read)
*        The number of bad columns to include. Only accessed if
*        parameter BADPIX is TRUE. The bad columns are distributed 
*        at random using a uniform distribution. [0]
*     BADPIX  = _LOGICAL (Read)
*        Whether or not bad pixels are to be included. See also
*        parameters FRACTION, BADCOL and BADROW. [FALSE]
*     BADROW = _INTEGER (Read)
*        The number of bad rows to include. Only accessed if
*        parameter BADPIX is TRUE. The bad rows are distributed 
*        at random using a uniform distribution. [0]
*     DIRN = _INTEGER (Read)
*        Direction of the ramp. 1 means left to right, 2 is right to
*        left, 3 is bottom to top, and 4 is top to bottom. (RA mode)
*     DISTRIB  =  _CHAR (Read)
*        Radial distribution of the Gaussians to be used (GS mode).
*        Alternatives weightings are:
*
*        - FIX: Fixed distance.
*        - RSQ: One over radius squared. 
*
*        ["FIX"]
*
*     FRACTION = _REAL (Read)
*        Fraction of bad pixels to be included. Only accessed if BADPIX
*        is TRUE. [0.01]
*     HIGH = _REAL (Read)
*        High value used in the generated data array (RA and RL modes).
*     LBOUND( 2 ) = _INTEGER (Read)
*        Lower pixel bounds of the output NDF. Only accessed if parameter 
*        LIKE is set to null (!). 
*     LIKE = NDF (Read)
*        An optional template NDF which, if specified, will be used to
*        define the bounds for the output NDF. If a null value (!) is 
*        given the bounds are obtained via parameters LBOUND and 
*        UBOUND. [!]
*     LOGFILE = LITERAL (Read)
*        Name of a log file in which to store details of the Gaussians
*        added to the output NDF (GS mode). If a null value is supplied
*        no log file is created. [!]
*     LOW  = _REAL (Read)
*        Low value used in the generated data array (RA and RL modes).
*     MAX = _REAL (Read)
*        Peak Gaussian intensity to be used in the generated data 
*        array (GS mode).
*     MEAN = _REAL (Read)
*        Mean value used in the generated data array (FL, RP and GN modes).
*     MIN = _REAL (Read)
*        Lowest Gaussian intensity to be used in the generated data
*        array (GS mode).
*     MODE = LITERAL (Read)
*        The form of the data to be generated. The options are:
*
*        - RR: Uniform noise between 0 and 1.
*        - RL: Uniform noise between specified limits.
*        - BL: A constant value of zero.
*        - FL: A specified constant value.
*        - RP: Poisson noise about a specified mean
*        - GN: Gaussian noise about a specified mean
*        - RA: Ramped between specified minimum and maximum values and a
*              choice of four directions.
*        - GS: A random distribution of 2-d Gaussians of defined
*              FWHM and range of maximum peak values on a specified
*              background, with Poissonian noise. There is a choice of 
*              spatial distributions for the Gaussians: fixed, or inverse 
*              square radially from the array centre. (In essence it is 
*              equivalent to a simulated star field.) The x-y position and 
*              peak value of each Gaussian may be stored in a log file, 
*              a positions list catalogue, or reported on the screen. 
*              Bad pixels may be included randomly, and/or in a column
*              or line of the array. 
*
*     NGAUSS  = _INTEGER (Read)
*        Number of Gaussian star-like images to be generated (GS mode).
*     OUT = NDF (Write)
*        The output NDF.
*     OUTCAT = FILENAME (Write)
*        An output catalogue in which to store the pixel co-ordinates of 
*        the Gausians in the output NDF (GS mode). If a null value is 
*        supplied, no output positions list is produced. [!]
*     QUIET = _LOGICAL  (Read)
*         If FALSE, the Gaussian parameters are reported to you on the
*         screen (GS mode) [TRUE]
*     SEEING = _REAL (Read)
*        Seeing (FWHM) in pixels (not the same as the standard deviation) 
*        (GS mode). 
*     SIGMA = _REAL (Read)
*        Standard deviation of noise to be used in the generated data
*        array (GN mode).
*     TITLE = LITERAL (Read)
*        Title for the output NDF ["KAPPA - Creframe"]
*     UBOUND( 2 ) = _INTEGER (Read)
*        Upper pixel bounds of the output NDF. Only accessed if parameter 
*        LIKE is set to null (!). 
*     VARIANCE = _LOGICAL (Read)
*        If TRUE, a Variance component is added to the output NDF
*        representing the noise added to the field. If a null (!) value is
*        supplied, a default is used which is TRUE for modes which include 
*        noise, and FALSE for modes which do not include any noise. [!]

*  Examples:
*     creframe out=file ubound=[128,128] mode=gs ngauss=5 badpix badcol=2
*              max=200 min=20 background=20 seeing=1.5
*        Produces a 128x128 pixel data array with 5 gaussians with peak
*        values of 200 counts and a background of 20 counts. There will
*        be two bad columns added to the resulting data.  

*  Implementation Status:
*     - The Data and Variance components of the output NDF have a numerical
*     type of "_REAL" (single precision floating point).
*     - This routine does not assign values to any of the following 
*     components in the output NDF: LABEL, UNITS, QUALITY, AXIS, WCS.

*  Authors:
*     MJM: Mark McCaughrean 
*     MJC: Malcolm Currie (Starlink, RAL)
*     AALLAN: Alasdair Allan (Starlink, University of Exeter)
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     01-SEP-2001 (AALLAN):
*        Original NDF version, based on earlier version by MJM and MJC.
*     11-SEP-2001 (DSB):
*        Removed nested status checks, standardize layout of local variable
*        declarations, remove unused variables and include files, etc.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-


*  Type definitions:
      IMPLICIT NONE              ! No implicit typing allowed

*  Global constants:
      INCLUDE 'SAE_PAR'           ! SSE global definitions
      INCLUDE 'DAT_PAR'           ! Data system constants
      INCLUDE 'PAR_ERR'           ! Parameter system errors
      INCLUDE 'PRM_PAR'           ! VAL__ constants

*  Status:
      INTEGER  STATUS

*  External references:
      INTEGER CHR_LEN             ! Length of string ignoring trailing blanks

*  Local Variables:
      CHARACTER BUFFER*132        ! Buffer for writing to the logfile
      CHARACTER DATE*64           ! Date string
      CHARACTER DISTRB*3          ! Radial distribution of Gaussians
      CHARACTER MODE*2            ! Type of data to be generated
      INTEGER BADCOL              ! bad column to be included?
      INTEGER BADROW              ! bad row to be included?
      INTEGER DIRN                ! Direction of ramping in data
      INTEGER INDF                ! Pointer to the output NDF
      INTEGER INDFT               ! Pointer to the input template NDF
      INTEGER IPDAT               ! Pointer to the output DATA component
      INTEGER IPVAR               ! Pointer to the output VAR component
      INTEGER IPWORK              ! Pointer to work space
      INTEGER LBND( 2 )           ! Template NDF lower bounds
      INTEGER NC                  ! Character Column Counters
      INTEGER NCI                 ! Character Column Counters
      INTEGER NDIM                ! Number of dimensions in template NDF
      INTEGER NGAUSS              ! Number of Gaussians (simulated stars)
      INTEGER NPIX                ! Number of pixels in output NDF
      INTEGER NTICKS              ! Number of time ticks 
      INTEGER NVAL                ! Number of supplied values
      INTEGER ODIMS( 2 )          ! Dimensions of the output NDF
      INTEGER UBND( 2 )           ! Template NDF upper bounds
      LOGICAL BADPIX              ! Bad pixels to be included?           
      LOGICAL LOGFIL              ! True if a log file is being written
      LOGICAL QUIET               ! Supress on-screen parameters reporting?
      LOGICAL VARS                ! Should variances be generated?
      REAL BCKGRD                 ! Background intensity
      REAL FRACTN                 ! Fraction of bad pixels to be included
      REAL HIGH                   ! High value in data to be generated
      REAL LOW                    ! Low value in data to be generated
      REAL MAX                    ! Max Gaussian intensity 
      REAL MEAN                   ! Mean value in data to be generated
      REAL MIN                    ! Min Gaussian intensity 
      REAL SEEING                 ! Seeing in pixels
      REAL SIGMA                  ! Std dev in data to be generated
         
*.

*  Check the inherited global status.
      IF( STATUS .NE. SAI__OK ) RETURN
            
*  Begin AST and NDF contexts.
      CALL AST_BEGIN( STATUS )
      CALL NDF_BEGIN

*  Get the shape for the output NDF.
*  =================================
*  Abort if an error has occurred.
      IF( STATUS .NE. SAI__OK ) GO TO 999

*  Attempt to obtain NDF via the LIKE parameter to act as a template.
      CALL LPG_ASSOC( 'LIKE', 'READ', INDFT, STATUS )

*  If a null template was given, annul the error, and get the the bounds of 
*  the NDF to be generated from the UBOUND and LBOUND parameters.
      IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )

         CALL PAR_GET1I('LBOUND', 2, LBND, NVAL, STATUS )
         IF( NVAL .EQ. 1 ) LBND( 2 ) = LBND( 1 )

         UBND( 1 ) = VAL__MAXI
         UBND( 2 ) = VAL__MAXI
         CALL PAR_GRMVI( 'UBOUND', 2, LBND, UBND, UBND, NVAL, STATUS ) 
         IF( NVAL .EQ. 1 ) UBND( 2 ) = UBND( 1 )

*  Otherwise, obtain the bounds of the template NDF.
      ELSE IF( STATUS .EQ. SAI__OK ) THEN 
         CALL NDF_BOUND( INDFT, 2, LBND, UBND, NDIM, STATUS )

      END IF

*  Obtain other options.
*  =====================

*  Get type of data to be generated
      CALL PAR_CHOIC( 'MODE', 'GS', 'GS,RR,RL,RP,RA,FL,BL,GN',
     :                .TRUE., MODE, STATUS )

*  Now get mode-specific parameters...

*  Mode GS: Gaussian Stars.
      IF( MODE .EQ. 'GS' .AND. STATUS .EQ. SAI__OK ) THEN

*  Get number of Gaussians to be generated
         CALL PAR_GDR0I( 'NGAUSS', 10, 1, 1000, .TRUE., NGAUSS,
     :                   STATUS )

*  Get maximum allowable intensity for Gaussians
         CALL PAR_GDR0R( 'MAX', 100.0, 0.0, 1.0E20, .TRUE., MAX,
     :                   STATUS )

*  Get minimum allowable intensity for Gaussians
         CALL PAR_GDR0R( 'MIN', 0.0, 0.0, 1.0E20, .TRUE., MIN,
     :                   STATUS )

*  Get background intensity
         CALL PAR_GDR0R( 'BACKGROUND', 0.0, 0.0, VAL__MAXR, .TRUE., 
     :                   BCKGRD, STATUS )

*  Get seeing in pixels
         CALL PAR_GDR0R( 'SEEING', 1.0, 0.01, 100.0, .TRUE., 
     :                   SEEING, STATUS )

*  Get type of distribution of Gaussians - fixed distance or inverse square
         CALL PAR_CHOIC( 'DISTRIB', 'FIX', 'FIX,RSQ', .TRUE., DISTRB,
     :                   STATUS )

*  Find out whether bad pixels are to be included
         CALL PAR_GTD0L( 'BADPIX', .FALSE., .TRUE., BADPIX, STATUS )

*  If so, then get the fraction to be set bad
         IF( BADPIX ) THEN
            CALL PAR_GDR0R( 'FRACTION', 0.01, 0.0, 1.0, .TRUE.,
     :                      FRACTN, STATUS )
         END IF

*  Find whether a bad column is to be included
         CALL PAR_GET0I( 'BADCOL', BADCOL, STATUS )
            
*  Find whether a bad row is to be included
         CALL PAR_GET0I( 'BADROW', BADROW, STATUS )
            
*  Find out whether the display is wanted on the screen
         CALL PAR_GET0L( 'QUIET', QUIET, STATUS )

*  Mode RR: Random between 0 and 1
      ELSE IF( MODE .EQ. 'RR' .AND. STATUS .EQ. SAI__OK ) THEN
         HIGH  =  1.0
         LOW   =  0.0
         MEAN  =  0.5
         SIGMA =  0.0
         DIRN  =  0

*  Mode RL: Random between set limits
      ELSE IF( MODE .EQ. 'RL' .AND. STATUS .EQ. SAI__OK ) THEN
         CALL PAR_GET0R( 'LOW', LOW, STATUS )
         CALL PAR_GET0R( 'HIGH', HIGH, STATUS )

         MEAN  =  ( HIGH + LOW ) / 2
         SIGMA =  0.0
         DIRN  =  0

*  Mode RP: Poissonian noise about mean
      ELSE IF( MODE .EQ. 'RP' .AND. STATUS .EQ. SAI__OK ) THEN

         CALL PAR_GET0R( 'MEAN', MEAN, STATUS )

         HIGH  =  0.0
         LOW   =  0.0
         DIRN  =  0
         SIGMA =  0.0

*  Mode GN: Gaussian noise about mean
      ELSE IF( MODE .EQ. 'GN' .AND. STATUS .EQ. SAI__OK ) THEN

         CALL PAR_GET0R( 'MEAN', MEAN, STATUS )
         CALL PAR_GET0R( 'SIGMA', SIGMA, STATUS )

         HIGH  =  0.0
         LOW   =  0.0
         DIRN  =  0

*  Mode RA: Ramp across array
      ELSE IF( MODE .EQ. 'RA' .AND. STATUS .EQ. SAI__OK ) THEN

         CALL PAR_GET0R( 'LOW', LOW, STATUS )
         CALL PAR_GET0R( 'HIGH', HIGH, STATUS )
         CALL PAR_GDR0I( 'DIRN', 1, 1, 4, .FALSE., DIRN, STATUS )
 
         MEAN  =  ( HIGH + LOW ) / 2

*  Mode FL: Flat all over array
      ELSE IF( MODE .EQ. 'FL' .AND. STATUS .EQ. SAI__OK ) THEN

         CALL PAR_GET0R( 'MEAN', MEAN, STATUS )

         HIGH  =  MEAN
         LOW   =  MEAN
         SIGMA =  0.0
         DIRN  =  0

*  Mode BL: Zero all over array
      ELSE IF( MODE .EQ. 'BL' .AND. STATUS .EQ. SAI__OK ) THEN

         HIGH  =  0.0
         LOW   =  0.0
         SIGMA =  0.0
         DIRN  =  0

      END IF

*  Create the output NDF.
*  ======================

*  Create a simple NDF via the parameter system.
      CALL LPG_CREAT( 'OUT', '_REAL', 2, LBND, UBND, INDF, STATUS)

*  Obtain a new title.
      CALL NDF_CINP( 'TITLE', INDF, 'Title', STATUS )

*  Abort if an error has occurred.
      IF( STATUS .NE. SAI__OK ) GO TO 999

*  Find out whether we should generate variances
      CALL PAR_GET0L( 'VARIANCE', VARS, STATUS )        

*  If a null value was obtained, annull the error and use a default of
*  .TRUE. for modes which include noise, and .FALSE. for modes which do
*  not include noise.
      IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         VARS = .NOT. ( MODE .EQ. 'BL' .OR. MODE .EQ. 'FL' .OR.
     :                  MODE .EQ. 'RA' )
      END IF 
                              
*  Map the DATA component array
      CALL NDF_MAP( INDF, 'Data', '_REAL', 'WRITE', IPDAT, NPIX, 
     :              STATUS )

*  Map a VARIANCE component if required
      IF( VARS ) CALL NDF_MAP( INDF, 'Variance', '_REAL', 'WRITE', 
     :                         IPVAR, NPIX, STATUS )            
            
*  Obtained the dimensions of the output NDF
      CALL NDF_DIM( INDF, 2, ODIMS, NDIM, STATUS )

*  Call actual subroutines to do the work, allocating any necessary work
*  space.
      IF( MODE .EQ. 'GS' ) THEN
         CALL PSX_CALLOC( NGAUSS*2, '_DOUBLE', IPWORK, STATUS )
         CALL KPS1_CREMG( ODIMS( 1 ), ODIMS( 2 ), MAX, MIN, BCKGRD, 
     :                    NGAUSS, SEEING, DISTRB, BADPIX, FRACTN, 
     :                    BADCOL, BADROW, .NOT. QUIET, 'LOGFILE', 
     :                    'OUTCAT', VARS, %VAL( IPDAT ), 
     :                    %VAL( IPVAR ), %VAL( IPWORK ), STATUS )
         CALL PSX_FREE( IPWORK, STATUS )

      ELSE
         CALL KPS1_CRETS( ODIMS( 1 ), ODIMS( 2 ), MODE, MEAN, HIGH, 
     :                    LOW, DIRN, SIGMA, VARS, %VAL( IPDAT ), 
     :                    %VAL( IPVAR ), STATUS )
      END IF

*  Tidy up.
*  ========
 999  CONTINUE

*  End the NDF and AST contexts.
      CALL NDF_END( STATUS )
      CALL AST_END( STATUS )

*  Add a context report if anything went wrong.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'CREFRAME_ERR', 'CREFRAME: Failed to create a '//
     :                 'test NDF.', STATUS )
      END IF

      END 
