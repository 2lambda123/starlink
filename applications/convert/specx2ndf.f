      SUBROUTINE SPECX2NDF( STATUS )
*+
*  Name:
*     SPECX2NDF

*  Purpose:
*     Converts a SPECX map into a simple data cube, or SPECX data files
*     to individual spectra.

*  Language:
*     Fortran 77.

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL SPECX2NDF (STATUS)

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application converts a SPECX map file into a simple data cube
*     formatted as a standard NDF.  It works on map files in version 4.2
*     or later of the SPECX format.  It can optionally write a schematic 
*     of the map grid to a text file.
*
*     In addition, it will also convert an HDS container file containing
*     an array of one-dimensional NDFs holding SPECX spectra into a
*     similar container file holding individual, scalar NDFs each
*     holding a single spectrum from the supplied array.
*
*     In both cases, WCS components are added to the output NDFs
*     describing the spectral and spatial axes.

*  Usage:
*     specx2ndf in out [gridfile] [telescope] [latitude] [longitude]

*  ADAM Parameters:
*     GRIDFILE  =  LITERAL (Read)
*        The name of a text file to which a schematic of the SPECX map
*        will be written.  This schematic shows those positions in the
*        map grid where spectra were observed.  To indicate that a file
*        containing the schematic is not to be written reply with an
*        exclamation mark ("!").  See Section 'Schematic of the map 
*        grid' (below) for further details.  [!]
*     IN  =  NDF (Read)
*        The name of the input SPECX map, or container file.  The file 
*        extension ('.sdf') should not be included since it is appended 
*        automatically by the application.
*     LATITUDE  =  LITERAL (Read)
*        The geodetic (geographic) latitude of the telescope where the
*        observation was made.  The value should be specified in
*        sexagesimal degrees, with a colon (':') to separate the 
*        degrees, minutes and seconds and no embedded spaces.  Values in
*        the northern hemisphere are positive.  The default corresponds
*        to the latitude of the JCMT.  ["19:49:33"]
*     LONGITUDE  =  LITERAL (Read)
*        The geodetic (geographic) longitude of the telescope where the
*        observation was made.  The value should be specified in
*        sexagesimal degrees, with a colon (':') to separate the 
*        degrees, minutes and seconds and no embedded spaces.  Following
*        the usual geographic convention longitudes west of Greenwich
*        are positive.  The default corresponds to the longitude of the
*        JCMT.  ["155:28:47"]
*     OUT  =  NDF (Write)
*        The name of the output NDF containing the data cube or spectra 
*        written by the application.  The file extension ('.sdf') should 
*        not be included since it is appended automatically by the 
*        application.
*     TELESCOPE  =  LITERAL (Read)
*        The name of the telescope where the observation was made.
*        This parameter is used to look up the geodetic (geographical)
*        latitude and longitude of the telescope.  See the documentation
*        of subroutine SLA_OBS in SUN/67 for a list of permitted values.
*        Alternatively, if you wish to explicitly enter the latitude and
*        longitude enter 'COORDS'.  The values are not case sensitive.
*        ["JCMT"]

*  Examples:
*     specx2ndf  specx_map  specx_cube
*        This example generates an NDF data cube called specx_cube (in
*        file specx_cube.sdf) from the NDF SPECX map called specx_map
*        (in file specx_map.sdf).  A text file containing a schematic 
*        of the map grid will not be produced.
*     specx2ndf  specx_map  specx_cube  gridfile=map.grid
*        This example generates an NDF data cube called specx_cube (in
*        file specx_cube.sdf) from the NDF SPECX map called specx_map
*        (in file specx_map.sdf).  A text file containing a schematic
*        of the map grid will be written to file map.grid.

*  Input and output map formats:
*     SPECX map files are written by the SPECX package (see SUN/17) for
*     reducing spectra observed with heterodyne receivers operating in
*     the mm and sub-mm wavelength range of the electromagnetic
*     spectrum.  SPECX is usually used to process observations obtained
*     with the James Clerk Maxwell Telescope (JCMT) in Hawaii.
*
*     A SPECX map file comprises a regular 'rectangular' two-dimensional
*     grid of map positions on the sky, with spectra observed at the
*     grid points.  However, a spectrum is not necessarily available at
*     every grid position; at some positions a spectrum is not observed
*     in order to save observing time.  For example, for a grid centred
*     on a typical, roughly circular, object spectra may be omitted for
*     the positions at the corners of the grid.  SPECX map files are
*     standard Starlink NDF HDS structures.  The principal array of the
*     NDF is a two-dimensional array of the grid positions.  The value
*     of each element is either a pointer to the spectrum observed there
*     (in practice the number of the spectrum in the array where they
*     are stored) or a value indicating that a spectrum was not observed
*     at this point.  In effect the SPECX map structure is an 
*     implementation of a sparse array.
*
*     SPECX2NDF expands a SPECX map file into a simple three-dimensional
*     data cube, again formatted as a standard NDF, in which the first
*     and second pixel axes corresponds to the spatial axes and the
*     third axes correspond to the spectral axis.  The advantage of
*     this approach is that the converted file can be examined with
*     standard applications, such as those in KAPPA (see SUN/95) and
*     easily imported into visualisation packages, such as Data Explorer
*     (DX, see SUN/203 and SC/2).  When the output data cube is created
*     the columns corresponding to the positions on the sky grid where
*     spectra were not observed are filled with  'bad' values (sometimes
*     called 'magic' or 'null' values), to indicate that valid data are
*     not available at these positions.  The standard Starlink bad value
*     is used.  Because of the presence of these bad values the expanded
*     cube is usually larger than the original map file.
*
*     The created NDF cube has a WCS component in which axes 1 and 2 are
*     RA and DEC, and axis 3 is frequency in units of GHz.  The nature of 
*     these axes can be changed if necessary by subsequent use of the
*     WCSATTRIB application within the KAPPA package.  For compatibility 
*     with older applications, AXIS structures are also added to the 
*     output cube. Axes 1 and 2 are offsets from the central position of 
*     the map, with units of seconds of arc, and axis 3 is frequency
*     offset in GHz relative to the central frequency.  The pixel origin
*     is placed at the source position on axes 1 and 2, and the central
*     frequency on axis 3.
*
*     SPECX2NDF reads map files in version 4.2 or later of the SPECX
*     data format.  If it is given a map file in an earlier version of
*     the data format it will terminate with an error message.  Note,
*     however, that SPECX itself can read map files in earlier versions
*     of the SPECX format and convert them to version 4.2.

*  Schematic of the map grid:
*     SPECX2NDF has an optional facility to write a crude schematic of
*     the grid of points observed on the sky to an ASCII text file
*     suitable for printing or viewing on a terminal screen.  This
*     schematic can be useful in interpreting displays of the data cube.
*     It shows the positions on the grid where spectra were observed.
*     Each spectrum is numbered within the SPECX map structure and the
*     first nine are shown using the digits one to nine.  The remaining
*     spectra are shown using an asterisk ('*').  You specify the name
*     of the file to which the schematic is written.  The following is
*     an example of a schematic:
*
*     Schematic map grid for CO21                                    
*
*
*        +---------+
*       9|         |
*       8| 8765432 |
*       7|*******9 |
*       6|******** |
*       5|****1*** |
*       4|******** |
*       3|******** |
*       2|******** |
*       1|         |
*        +---------+
*         123456789

*  Auxiliary information:
*     SPECX2NDF copies all the auxiliary information present in the
*     original map file to the output data cube.  However, the arrays
*     holding the original spectra are not copied in order to save
*     disk space.  

*  Input and output spectra formats:
*     In addition to converting SPECX map files, this application can 
*     also convert HDS files which hold an array of one-dimensional NDF
*     structures, each being a single spectrum extracted by SPECX. 
*     Since arrays of NDFs are not easily accessed, this application
*     extracts each NDF from the array and creates a new scalar NDF
*     holding the same data within the output container file.  The name
*     of the new NDF is "SPECTRUM<n>" where "<n>" is its index within
*     the original array of NDFs.  Each new scalar NDF is actually
*     three-dimensional and has the format described above for
*     an output cube (i.e. axes 1 and 2 are RA and DEC, and axis 3 is
*     frequency). However, pixel axes 1 and 2 span only a single pixel
*     (the size of this single spatial pixel is assumed to be half the
*     size of the resolution of the JCMT at the central frequency). 
*     Inclusion of three-dimensional WCS information allows the
*     individual spectra to be aligned on the sky (for instance using
*     the KAPPA WCSALIGN task).

*  Authors:
*     ACD: A C Davenhall (Edinburgh)
*     DSB: David S. Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)

*  History:
*     25/6/97 (ACD): 
*        Original version.
*     8/1/98  (ACD): 
*        First stable version.
*     17-FEB-2003 (DSB):
*        Extensive modifications to replace the original spectral axis
*        code by code which adds a WCS component to the output, including 
*        a SpecFrame. Changed axis order to make spectral axis, axis 3.
*     24-FEB-2004 (DSB):
*        Modified NDF label to use AST escape sequences.
*     11-AUG-2004 (TIMJ):
*        Fix NDF lable for spectra as well as maps.
*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  External References:
      DOUBLE PRECISION SLA_DRANGE

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants.
      INCLUDE 'AST_PAR'          ! AST constants and functions.
      INCLUDE 'DAT_PAR'          ! HDS constants 
      INCLUDE 'NDF_PAR'          ! NDF constants 
      INCLUDE 'PAR_ERR'          ! PAR_ error constants.

*  Status:
      INTEGER STATUS             ! Global status.

*  External Referecnes:
      INTEGER CHR_LEN          ! Used length of a string

*  Local Variables:
      INTEGER NCOMP
      INTEGER I
      INTEGER PLACE
      INTEGER IPIN
      INTEGER IPOUT 
      INTEGER EL
      INTEGER IERR
      INTEGER NDIM
      INTEGER NERR
      INTEGER NNDF
      INTEGER IAT
      CHARACTER NAME*(DAT__SZNAM)
      CHARACTER OUTNAM*(DAT__SZNAM)
      CHARACTER HDSOUT*256
      CHARACTER LOC1*(DAT__SZLOC)
      CHARACTER LOC2*(DAT__SZLOC)
      CHARACTER LOC3*(DAT__SZLOC)
      CHARACTER LOC4*(DAT__SZLOC)
      CHARACTER LOC5*(DAT__SZLOC)
      LOGICAL GOTMAP
      LOGICAL OK
      CHARACTER CLAT*12        ! Geodetic latitude (sexagesimal string format)
      CHARACTER CLONG*12       ! Geodetic longitude (sexagesimal string format)
      CHARACTER DESCR*40       ! Description of the telescope
      CHARACTER GRIDFL*70      ! Name of file containing schematic of map grid
      CHARACTER TELSCP*10      ! Name of telescope
      CHARACTER TTL*80         ! Title for output NDF
      DOUBLE PRECISION HT      ! Height above sea level
      DOUBLE PRECISION LAT     ! Geodetic latitude
      DOUBLE PRECISION LONG    ! Geodetic latitude
      INTEGER CLWBND(3)        ! Lower bounds for the data cube
      INTEGER CUPBND(3)        ! Upper bounds for the data cube
      INTEGER DIM( 3 )         ! Dimension sizes
      INTEGER MXDIM            ! Max dimension size
      INTEGER DIMS             ! Array dimensionality
      INTEGER INDF1            ! Identifier for an input NDF
      INTEGER INDF2            ! Identifier for an output NDF
      INTEGER IPWORK           ! Pointer to work space
      INTEGER LTTL             ! Length of title for output NDF
      INTEGER MLWBND(3)        ! Lower bounds for the ndf
      INTEGER MUPBND(3)        ! Upper bounds for the ndf
      INTEGER NDONE            ! Number of spectra converted
      INTEGER NSPEC            ! Number of spectra
      INTEGER NX               ! X size of the data cube
      INTEGER NY               ! Y size of the data cube
      INTEGER NZ               ! Z size of the data cube
      INTEGER SPTS             ! Number of points in each spectrum
      LOGICAL APPHST           ! Flag; append history to output cube?
      LOGICAL GRIDFG           ! Flag; write schematic of grid to a file?
      REAL VERSN               ! Data format version number
*.

*  Check the inherited status. Return if an error has already occurred.
      IF( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Start an NDF context.
      CALL NDF_BEGIN

*  Open the input HDS file.
      CALL DAT_ASSOC( 'IN', 'READ', LOC1, STATUS )

*  Abort if an error has occurred.
      IF( STATUS .NE. SAI__OK ) GO TO 999

*  Attempt to import the top level object as an NDF.
      CALL NDF_FIND( LOC1, ' ', INDF1, STATUS ) 

*  If this was succesful, and the NDF is 2-D, we assume we have a SPECX map 
*  file as input.
      IF( STATUS .EQ. SAI__OK ) THEN
         CALL NDF_BOUND( INDF1, 2, MLWBND, MUPBND, DIMS, STATUS )
         GOTMAP = ( DIMS .EQ. 2 )
      ELSE
         CALL ERR_ANNUL( STATUS )
         GOTMAP = .FALSE.
      END IF

*  Determine the geodetic longitude and latitude of the observer.
      CALL PAR_GET0C( 'TELESCOPE', TELSCP, STATUS )
      CALL CHR_UCASE( TELSCP )

      IF( TELSCP .NE. 'COORDS' ) THEN
         CALL SLA_OBS( 0, TELSCP, DESCR, LONG, LAT, HT )

         IF( DESCR .EQ. '?' ) THEN
            IF( STATUS .EQ. SAI__OK ) THEN         
               STATUS = SAI__ERROR
               CALL MSG_SETC( 'TELSCP', TELSCP )
               CALL ERR_REP( 'SPECX2NDF_TEL', 'The given telescope '//
     :                       '(^TELSCP) is unknown.', STATUS  )
            END IF
         END IF

      ELSE
         CALL PAR_GET0C( 'LATITUDE', CLAT, STATUS )
         CALL CON_ANGDC( 'DEGREES', CLAT, LAT, STATUS )

         CALL PAR_GET0C( 'LONGITUDE', CLONG, STATUS )
         CALL CON_ANGDC( 'DEGREES', CLONG, LONG, STATUS )
      END IF

*  Reverse the sign of the longitude to make it "east positive" as
*  required by CON_WCSPX.
      LONG = SLA_DRANGE( -LONG )

*  First deal with SPECX map file inputs...
*  ========================================
      IF( GOTMAP ) THEN

*  Determine the version number of the data format Report an error and
*  abort if it is less than 4.2.
         CALL NDF_XGT0R( INDF1, 'SPECX_MAP', 'VERSION', VERSN, STATUS )
         IF( VERSN .LT. 4.2 ) THEN
            IF( STATUS .EQ. SAI__OK ) THEN
               STATUS = SAI__ERROR
               CALL ERR_REP( 'SPECX2NDF_BDF', 'SPECX2NDF: the input '//
     :                       'SPECX data format version is less than '//
     :                       '4.2.', STATUS )
            END IF
         END IF            

*  Abort if an error has occurred.
         IF( STATUS .NE. SAI__OK ) GO TO 999

*  Determine whether to write a schematic of the map grid. If no schematic 
*  is required then a null value is returned for GRIDFL; otherwise it is 
*  set to the name of the file to which the schematic will be written.
         CALL PAR_GET0C( 'GRIDFILE', GRIDFL, STATUS )
         IF( STATUS .EQ. PAR__NULL ) THEN
            CALL ERR_ANNUL( STATUS  )
            GRIDFG = .FALSE.
            GRIDFL = ' '
         ELSE
            GRIDFG = .TRUE.
         END IF

*  Determine the size of the input map grid.
         CALL NDF_BOUND( INDF1, 2, MLWBND, MUPBND, DIMS, STATUS )

*  Determine the number of spectra and the number of points in each spectrum.
         CALL NDF_XGT0I( INDF1, 'SPECX_MAP', 'NSPEC', NSPEC, STATUS )
         CALL NDF_XGT0I( INDF1, 'SPECX_MAP', 'NPTS1', SPTS, STATUS )
            
*  Attempt to get an identifier for the output cube and proceed if ok.  
*  First construct the array bounds.
         CLWBND( 1 ) = MLWBND( 1 )
         CUPBND( 1 ) = MUPBND( 1 )
   
         CLWBND( 2 ) = MLWBND( 2 )
         CUPBND( 2 ) = MUPBND( 2 )
    
         CLWBND( 3 ) = 1
         CUPBND( 3 ) = SPTS
   
         CALL NDF_CREAT( 'OUT', '_REAL', 3, CLWBND, CUPBND, INDF2, 
     :                   STATUS )

*  Find the largest dimension.
         DIM( 1 ) = CUPBND( 1 ) - CLWBND( 1 ) + 1
         DIM( 2 ) = CUPBND( 2 ) - CLWBND( 2 ) + 1
         DIM( 3 ) = CUPBND( 3 ) - CLWBND( 3 ) + 1
         MXDIM = DIM( 1 )      
         IF( DIM( 2 ) .GT. MXDIM ) MXDIM = DIM( 2 )
         IF( DIM( 3 ) .GT. MXDIM ) MXDIM = DIM( 3 )

*  Copy the data cube.
         CALL CON_CCPY( GRIDFG, GRIDFL, INDF1, 2, MLWBND, MUPBND,
     :                  NSPEC, SPTS, INDF2, STATUS )

*  Create the WCS component.
         CALL CON_WCSPX( INDF2, INDF1, LONG, LAT, STATUS )

*  Add AXIS structures to the output NDF.
         CALL PSX_CALLOC( 6*MXDIM, '_DOUBLE', IPWORK, STATUS )
         CALL CON_CAXES( INDF1, INDF2, %VAL( IPWORK ), STATUS )
         CALL PSX_FREE( IPWORK, STATUS )

*  Copy any auxilliary information.
         CALL CON_CAUX( INDF1, INDF2, APPHST, STATUS )

*  Set the output NDF title, label and unit.
         CALL NDF_XGT0C( INDF1, 'SPECX_MAP', 'ID', TTL, STATUS )
         CALL CHR_LDBLK( TTL )
         LTTL = CHR_LEN( TTL )
         IF( LTTL .NE. 0 ) CALL NDF_CPUT( TTL( : LTTL ), INDF2, 'TITLE', 
     :                                    STATUS ) 
         CALL NDF_CPUT( 'T%s60+%v30+A%^50+%<20+*%+   corrected '//
     :                  'antenna temperature', INDF2, 'LABEL', STATUS ) 
         CALL NDF_CPUT( 'K', INDF2, 'Unit', STATUS ) 

*  Report success.
         IF( STATUS .EQ. SAI__OK ) THEN
            NX = CUPBND(1 ) + 1 - CLWBND(1 )
            NY = CUPBND(2 ) + 1 - CLWBND(2 )
            NZ = CUPBND(3 ) + 1 - CLWBND(3 )
         
            CALL MSG_SETI( 'NX', NX )
            CALL MSG_SETI( 'NY', NY )
            CALL MSG_SETI( 'NZ', NZ )
         
            CALL MSG_OUT( ' ', '^NX x ^NY x ^NZ cube created '//
     :                    'successfully from SPECX map file.', STATUS )
         
         END IF

*  Now deal with SPECX spectrum file inputs...
*  ===========================================
      ELSE

*  If the supplied input HDS object was an NDF, check it is one
*  dimensional.
         OK = .TRUE.
         NNDF = 0
         LOC2 = DAT__NOLOC
         LOC4 = DAT__NOLOC
         IF( INDF1 .NE. NDF__NOID ) THEN
            IF( DIMS .NE. 1 ) THEN
               OK = .FALSE.
            ELSE
               NNDF = 1

*  Create the output from the input.
               CALL NDF_PROP( INDF1, 'UNITS', 'OUT', INDF2, STATUS ) 
            END IF

*  If the supplied input HDS object was not an NDF, see if it has an
*  1D array component called SPECTRUM. If so get the length of the array,
*  and attempt to import an NDF from the first cell.
         ELSE
            CALL DAT_THERE( LOC1, 'SPECTRUM', OK, STATUS ) 
            IF( OK ) THEN
               CALL DAT_FIND( LOC1, 'SPECTRUM', LOC2, STATUS )             
               CALL DAT_SHAPE( LOC2, 1, NNDF, NDIM, STATUS ) 

               IF( NDIM .EQ. 1 ) THEN
                  CALL DAT_CELL( LOC2, 1, 1, LOC3, STATUS ) 

                  IF( STATUS .NE. SAI__OK ) GO TO 999

                  CALL NDF_FIND( LOC3, ' ', INDF1, STATUS ) 
                  IF( STATUS .NE. SAI__OK ) THEN
                     CALL ERR_ANNUL( STATUS )
                     OK = .FALSE.
                  ELSE
                     CALL NDF_BOUND( INDF1, 2, MLWBND, MUPBND, DIMS, 
     :                               STATUS )
                  END IF
                  CALL DAT_ANNUL( LOC3, STATUS )

*  Create a container file for the output NDFs by copying the input file.
                  CALL DAT_CREAT( 'OUT' , 'SPECX_SPECTRA', 0, 0, 
     :                            STATUS ) 
                  CALL DAT_ASSOC( 'OUT', 'UPDATE', LOC4, STATUS )
                  CALL DAT_NCOMP( LOC1, NCOMP, STATUS ) 
                  DO I = 1, NCOMP
                     CALL DAT_INDEX( LOC1, I, LOC5, STATUS ) 
                     CALL DAT_NAME( LOC5, NAME, STATUS ) 
                     IF( NAME(:4) .NE. 'SPEC' ) THEN
                        CALL DAT_COPY( LOC5, LOC4, NAME, STATUS ) 
                     END IF
                  END DO

*  Create the first output NDF from the first input NDF.
                  CALL NDF_PLACE( LOC4, 'SPECTRUM1', PLACE, STATUS ) 
                  CALL NDF_SCOPY( INDF1, 'UNITS', PLACE, INDF2, STATUS ) 

               ELSE
                  OK = .FALSE.
               END IF
            END IF
         END IF

*  Report an error if the array could nto be accessed.
         IF( .NOT. OK .AND. STATUS .EQ. SAI__OK ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'SPECX2NDF_IN', 'The input does not seem to'//
     :                    ' contain either a SPECX map or SPECX '//
     :                    'spectra.', STATUS )
            GO TO 999
         END IF

*  Loop round processing all the NDFs. We already have an identifier for
*  the first.
         NDONE = 0
         DO I = 1, NNDF
            IF( INDF2 .NE. NDF__NOID ) THEN
               NDONE = NDONE + 1

*  Process this output NDF. First make it 3 dimensional, with the
*  spectral axis on axis 3.
               MLWBND( 3 ) = MLWBND( 1 )
               MLWBND( 1 ) = 1
               MLWBND( 2 ) = 1
               MUPBND( 3 ) = MUPBND( 1 )
               MUPBND( 1 ) = 1
               MUPBND( 2 ) = 1
               CALL NDF_SBND( 3, MLWBND, MUPBND, INDF2, STATUS ) 

*  Copy the data values.
               CALL NDF_MAP( INDF1, 'DATA', '_REAL', 'READ', IPIN, EL, 
     :                       STATUS ) 
               CALL NDF_MAP( INDF2, 'DATA', '_REAL', 'WRITE', IPOUT, EL, 
     :                       STATUS ) 
               CALL VEC_RTOR( .FALSE., EL, %VAL( IPIN ), %VAL( IPOUT ), 
     :                        IERR, NERR, STATUS )

*  Unmap the array components.
               CALL NDF_UNMAP( INDF1, '*', STATUS )
               CALL NDF_UNMAP( INDF2, '*', STATUS )

*  Create the WCS component.
               CALL CON_WCSPX( INDF2, INDF1, LONG, LAT, STATUS )

*  Add AXIS structures to the output NDF.
               CALL PSX_CALLOC( 6*( MUPBND(3) - MLWBND(3) + 1 ), 
     :                          '_DOUBLE', IPWORK, STATUS )
               CALL CON_CAXES( INDF1, INDF2, %VAL( IPWORK ), STATUS )
               CALL PSX_FREE( IPWORK, STATUS )

*  Set the output NDF label and unit.
               CALL NDF_CPUT( 'T%s60+%v30+A%^50+%<20+*%+   corrected '//
     :              'antenna temperature', INDF2, 'LABEL', STATUS ) 
               CALL NDF_CPUT( 'K', INDF2, 'Unit', STATUS ) 

*  Annul the current input and output NDF identifiers. 
               CALL NDF_ANNUL( INDF2, STATUS )
            END IF
            CALL NDF_ANNUL( INDF1, STATUS )

*  Get an identifier for the next input NDF if necessary.
            IF( I .LT. NNDF ) THEN
               CALL DAT_CELL( LOC2, 1, I + 1, LOC3, STATUS ) 
               CALL NDF_FIND( LOC3, ' ', INDF1, STATUS ) 
               CALL NDF_BOUND( INDF1, 2, MLWBND, MUPBND, DIMS, 
     :                         STATUS )
               CALL DAT_ANNUL( LOC3, STATUS )

*  Create the next output NDF by copying the next input NDF.
               IF( MUPBND( 1 ) - MLWBND( 1 ) .GT. 0 ) THEN
                  OUTNAM = 'SPECTRUM'
                  IAT = 8
                  CALL CHR_PUTI( I + 1, OUTNAM, IAT )
                  CALL NDF_PLACE( LOC4, OUTNAM( : IAT ), PLACE, STATUS ) 
                  CALL NDF_COPY( INDF1, PLACE, INDF2, STATUS ) 
               ELSE
                  INDF2 = NDF__NOID
               END IF
            END IF
         END DO

*  Annul the locator to the array of input spectra.
         IF( LOC2 .NE. DAT__NOLOC ) CALL DAT_ANNUL( LOC2, STATUS )

*  Annul the locator to the output container.
         IF( LOC4 .NE. DAT__NOLOC ) CALL DAT_ANNUL( LOC4, STATUS )

*  Report success.
         IF( NDONE .GT. 0 .AND. STATUS .EQ. SAI__OK ) THEN
            CALL MSG_SETI( 'N', NDONE )
            CALL MSG_OUT( ' ', '^N spectra converted successfully.', 
     :                   STATUS )
         END IF

      END IF

 999  CONTINUE

*  End the NDF context.
      CALL NDF_END( STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

*  Annul the input HDS object.
      CALL DAT_ANNUL( LOC1, STATUS )

*  Report a message if any error occurred.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'SPECX2NDF_ERR', 'SPECX2NDF: failed to '//
     :                 'convert SPECX map file.', STATUS )
      END IF

      END
