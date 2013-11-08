*+  EVSIM - Creates dummy event dataset
      SUBROUTINE EVSIM( STATUS )
*
*    Description :
*
*     Sets up a dummy event dataset. Both the background count rate and
*     the source count rate can be set. The source position is at the
*     centre of the image.
*
*    Environment parameters :
*
*     OUT                   = UNIV(W)
*           Output event dataset
*     MODEL                = CHAR(R)
*           Model file (optional)
*     PIXSIZE               = REAL(R)
*           Pixel size ( ie. QUANTUM )
*     FIELDSIZE             = REAL(R)
*           Full width of field
*     SEED                  = INTEGER(R)
*           Start seed
*     BACK                  = INTEGER(R)
*           Number of background counts
*     SOURCEC               = INTEGER(R)
*           List of source counts
*     SOURCEP               = REAL(R)
*           List of source positions
*     WIDTHS               = REAL(R)
*           List of source widths
*     PSF                   = CHAR(R)
*           User's selected psf
*     BACK                  = INTEGER(R)
*           The number of background counts
*     SOURCE                = INTEGER[](R)
*           The number of each source's counts
*
*    Method :
*
*     X and Y arrays are set up and filled randomly with the number
*     of background counts required. The source counts are distributed
*     randomly one at a time and are tested against the PSF. If they
*     pass, a counter is incremented, if not another photon is tested.
*
*    Authors :
*
*     Robin Jeffries (BHVAD::RDJ)
*     David J. Allan (BHVAD::DJA)
*
*    History :
*
*     20 Jul 89 : Original (RDJ)
*     26 May 90 : V1.2-0 Generalised PSF access and converted to Asterix (DJA)
*     24 Jul 90 : V1.2-1 Simulation parameters written to output file. If
*                        seed supplied, counts are not deviated (DJA)
*      2 Aug 90 : V1.2-2 Bug in source photon distribution fixedd (DJA)
*      4 Dec 90 : V1.3-0 Can convolve source psf with gaussian of any width
*                        (DJA)
*     25 Jul 91 : V1.5-0 Takes background model as well as counts (DJA)
*      4 Mar 92 : V1.6-1 Takes spatial parameters from model if present (DJA)
*     12 Mar 92 : V1.6-2 Use 2D psf system (DJA)
*     22 May 92 : V1.6-3 Use ERR_ANNUL to reset all status (DJA)
*      9 Dec 92 : V1.7-0 Uses SLA_ random number generator (DJA)
*      5 Mar 93 : V1.7-1 Use non-congruential number generator, SIM_RND (DJA)
*     14 Jul 93 : V1.7-2 Use MATH_RND generator (DJA)
*     24 Nov 94 : V1.8-0 Now use USI for user interface (DJA)
*     28 Mar 95 : V1.8-1 Use new interface for model (DJA)
*     12 Dec 1995 : V2.0-0 ADI port (DJA)
*    Type definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
      INCLUDE 'ADI_PAR'
      INCLUDE 'PAR_ERR'
*
*    Status :
*
      INTEGER STATUS
*
*    Function declarations :
*
      INTEGER           MATH_POISS
      INTEGER           CHR_LEN
*
*    Local constants :
*
      INTEGER           MAXSRC
         PARAMETER      ( MAXSRC = 50 )
*
*    Local variables :
*
      CHARACTER*80      	OROOT                  	! Output dataset root
      CHARACTER*132     	ONAME                  	! Output file name
      CHARACTER*40      	UNITS                  	! Model X axis units
      CHARACTER*40		WUN(2)			! WCS units

      DOUBLE PRECISION		SPOINT(2)		! Special pointing dir

      REAL              	FSIZE                  	! Size of field
      REAL              	LO, HI                 	! AXIS extrema
      REAL              	MTOT                   	! Total valid data in model
      REAL              	PSIZE                  	! Pixel size - quantum of lists
      REAL              	SPOS(MAXSRC*2)         	! Source positions
      REAL              	TOR                    	! Axis units to radians factor
      REAL              	WIDS(MAXSRC)           	! Source widths
      REAL			SPARR(2)		! Spaced array info
      REAL              	XPOS(MAXSRC),YPOS(MAXSRC)
      REAL              	XBASE, XSCALE          	! Model X axis
      REAL              	YBASE, YSCALE          	! Model Y axis
      REAL              	XLO, XHI, YLO, YHI     	! Output evds bounds

      INTEGER           ACTSRC                 ! Actual number of sources
      INTEGER           ACTWID                 ! Actual number of widths given
      INTEGER           	DIMS(ADI__MXDIM)       	! Bgnd dimensions
      INTEGER			EVID			! Event interface obj
      INTEGER                   FFILE                   ! Index of first file
      INTEGER           	IFILE                  	! Loop over files
      INTEGER           	ISRC                   	! Loop over sources
      INTEGER           IWID                   ! Loop over widths
      INTEGER			MFID			! Model dataset id
      INTEGER           NPT                    ! No. of points in position lists
      INTEGER           NBACK                  ! No. of background counts
      INTEGER           NDIM                   ! Bgnd dimensionality
      INTEGER           NELM                   ! Bgnd elements
      INTEGER           NFILE                  ! # files to create
      INTEGER           NOUT                   ! # events outside field ranges
      INTEGER           NSRC                   ! # sources in image
      INTEGER           NVAL                   ! # values in model axis
      INTEGER			OFID			! Output dataset id
      INTEGER           ONBACK                 ! Requested # background counts
      INTEGER           OSCOUNT(MAXSRC)        ! Requested # of source counts
      INTEGER           PDPTR,ptptr,pkptr                  ! Psf data ptr
      INTEGER                   PIXID, PRJID, SYSID     ! World coordinates
      INTEGER           PIN                    ! Length of psf prob index
      INTEGER           PIPTR                  ! Psf prob index ptr
      INTEGER           	PSLOT                  	! PSF system slot
      INTEGER           PSW                    ! Psf access width in pixels
      INTEGER           PSW2                   ! Psf model width in pixels
      INTEGER           MDPTR                  ! Model data ptr
      INTEGER           MIPTR                  ! Model probability index ptr
      INTEGER           MQPTR                  ! Model quality ptr
      INTEGER           SCOUNT(MAXSRC)         ! Actual # of source counts
      INTEGER           	SEED                   	! Random number seed
      INTEGER			XLID, YLID		! X & Y list ids
      INTEGER           	XPTR, YPTR             	! Pointers to list data

      LOGICAL           	MOK                    	! Using a model?
      LOGICAL           	OK                     	! Validity check
      LOGICAL           	PDEV                   	! Poisson deviate
      LOGICAL           	PSFCON                 	! Psf constant across field?
      LOGICAL           	SEED_GIVEN             	! Seed supplied?
      LOGICAL           	XDEC, YDEC             	! Axes decreasing?
*
*    Version id :
*
      CHARACTER*30      VERSION
         PARAMETER      ( VERSION = 'EVSIM Version 2.0-0' )
*
*    Local Data:
*
      DATA              SPOINT/0D0,0D0/
*-

*  Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Version
      CALL MSG_PRNT( VERSION )

*  Initialise Asterix
      CALL AST_INIT()

*  No astrometry by default
      PIXID = ADI__NULLID
      PRJID = ADI__NULLID
      SYSID = ADI__NULLID

*  Get number of files
      CALL USI_GET0I( 'NFILE', NFILE, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Get output dataset root name
      IF ( NFILE .GT. 1 ) THEN
        CALL USI_GET0I( 'FFILE', FFILE, STATUS )
        CALL USI_PROMT( 'OUT', 'Root name for multiple outputs',STATUS )
      END IF
      CALL USI_GET0C( 'OUT', OROOT, STATUS )

*  See if user supplied seed given
      CALL USI_GET0I( 'SEED', SEED, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
        CALL ERR_ANNUL( STATUS )
        SEED_GIVEN = .FALSE.
      ELSE
        SEED_GIVEN = .TRUE.
      END IF
      PDEV = (.NOT.SEED_GIVEN)

*  Create random seed?
      IF ( .NOT. SEED_GIVEN ) THEN
        CALL PSX_TIME( SEED, STATUS )
        SEED = -MOD(SEED,13234597)
      END IF

*  Set up generator
      CALL MATH_SETRND( SEED )

*  Prompt for the background counts in field
      CALL USI_ASSOC( 'MODEL', 'BinDS', 'READ', MFID, STATUS )
      IF ( STATUS .EQ. SAI__OK ) THEN

*    Check dimensions and map
        CALL BDI_CHK( MFID, 'Data', OK, STATUS )
        CALL BDI_GETSHP( MFID, ADI__MXDIM, DIMS, NDIM, STATUS )
        IF ( STATUS .NE. SAI__OK ) GOTO 99

*    Check dimensionality
        IF ( .NOT. OK ) THEN
          STATUS = SAI__ERROR
          CALL ERR_REP( ' ', 'Invalid model data', STATUS )
        ELSE IF ( NDIM .NE. 2 ) THEN
          STATUS = SAI__ERROR
          CALL ERR_REP( ' ', 'Background must be 2D', STATUS )
        END IF
        IF ( STATUS .NE. SAI__OK ) GOTO 99

*    Map model array
        NELM = DIMS(1)*DIMS(2)
        CALL BDI_MAPR( MFID, 'Data', 'READ', MDPTR, STATUS )

*    Quality present?
        CALL BDI_CHK( MFID, 'Quality', OK, STATUS )
        IF ( OK ) THEN
          CALL BDI_MAPL( MFID, 'LogicalQuality', 'READ', MQPTR, STATUS )
          CALL MSG_PRNT( 'Using model quality array...' )
        END IF

*    Map memory for index
        CALL DYN_MAPR( 1, NELM+1, MIPTR, STATUS )

*    Normalise
        CALL MSG_PRNT( 'Normalising model...' )
        CALL SIM_MNORM( NELM, %VAL(MDPTR), OK, %VAL(MQPTR),
     :                              %VAL(MIPTR), MTOT, STATUS )

*    Report counts in model
        CALL MSG_SETR( 'C', MTOT )
        CALL MSG_PRNT( 'Model contains ^C counts' )

*    Get axis details
        CALL BDI_AXGET1R( MFID, 1, 'SpacedData', 2, SPARR, NVAL,
     :                    STATUS )
        XBASE = SPARR(1)
        XSCALE = SPARR(2)
        CALL BDI_AXGET1R( MFID, 1, 'SpacedData', 2, SPARR, NVAL,
     :                    STATUS )
        YBASE = SPARR(1)
        YSCALE = SPARR(2)
        CALL BDI_AXGET0C( MFID, 1, 'Units', UNITS, STATUS )

*    Describe evds bounds
        XDEC = (XSCALE.LT.0.0)
        LO = XBASE - XSCALE/2.0
        HI = LO + DIMS(1)*XSCALE
        XLO = MIN( LO, HI )
        XHI = MAX( LO, HI )
        YDEC = (YSCALE.LT.0.0)
        LO = YBASE - YSCALE/2.0
        HI = LO + DIMS(2)*YSCALE
        YLO = MIN( LO, HI )
        YHI = MAX( LO, HI )
        PSIZE = ABS(XSCALE)
        MOK = .TRUE.

*    Get world coordinates
        CALL WCI_GETIDS( MFID, PIXID, PRJID, SYSID, STATUS )

*  No model
      ELSE IF ( STATUS .EQ. PAR__NULL ) THEN

        MOK = .FALSE.
        CALL ERR_ANNUL( STATUS )

*    Decide on image size etc.
        CALL USI_GET0R( 'FIELDSIZE', FSIZE, STATUS )
        CALL USI_GET0R( 'PIXSIZE', PSIZE, STATUS )
        UNITS = 'arcmin'
        XDEC = .TRUE.
        YDEC = .FALSE.
        XLO = -FSIZE/2.0
        YLO = XLO
        XHI = -XLO
        YHI = -YLO

*    Invent some WCS stuff
        WUN(1) = UNITS
        WUN(2) = UNITS
        CALL WCI_NEWPX( 0, 0.0, 0.0, WUN, 0.0, PIXID, STATUS )
        CALL WCI_NEWPRJ( 'TAN', 0, 0.0, SPOINT, 180D0, PRJID, STATUS )
        CALL WCI_NEWSYS( 'FK5', 2000.0, 2000D0, SYSID, STATUS )

      END IF
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Convert axis units to radians
      CALL CONV_UNIT2R( UNITS, TOR, STATUS )

*  Get number of background counts
 10   CALL USI_GET0I( 'BACK', ONBACK, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
        CALL ERR_ANNUL( STATUS )
        ONBACK = 0
      ELSE IF ( ( ONBACK .LT. 0 ) .AND. ( STATUS .EQ. SAI__OK ) ) THEN
        STATUS = SAI__ERROR
        CALL ERR_REP( ' ', 'Number of counts must be positive',
     :                STATUS )
      END IF
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Prompt for the number of source counts
 20   CALL USI_GET1I( 'SOURCEC', MAXSRC, OSCOUNT, NSRC, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
        CALL ERR_ANNUL( STATUS )
        NSRC = 0
      ELSE IF ( STATUS .NE. SAI__OK ) THEN
        GOTO 99
      ELSE IF ( NSRC .GT. MAXSRC ) THEN
        CALL MSG_SETI( 'MAX', MAXSRC )
        STATUS = SAI__ERROR
        CALL ERR_REP( ' ', 'Number of sources must be between 0 and'/
     :                /' ^MAX', STATUS )
        GOTO 99
      END IF

*    No sources and background
      IF ( ( NSRC .EQ. 0 ) .AND. ( ONBACK .EQ. 0 ) ) THEN
        STATUS = SAI__ERROR
        CALL ERR_REP( ' ', 'No sources and no background', STATUS )
        GOTO 99
      END IF

*    Any sources?
      IF ( NSRC .GT. 0 ) THEN

*      Get source positions
 30     CALL USI_GET1R( 'SOURCEP', NSRC*2, SPOS, ACTSRC, STATUS )
        IF ( STATUS .NE. SAI__OK ) GOTO 99
        IF ( ACTSRC .NE. (NSRC*2) ) THEN
          CALL USI_CANCL('SOURCEP',STATUS)
          GOTO 30
        END IF
        DO ISRC = 1, NSRC
          XPOS(ISRC) = SPOS(ISRC*2-1)
          YPOS(ISRC) = SPOS(ISRC*2)
        END DO

*      Get widths
        ACTWID = 1
        IF ( NSRC .GT. 0 ) THEN
 40       IF ( NSRC .EQ. 1 ) THEN
            CALL USI_GET0R( 'WIDTHS', WIDS, STATUS )
          ELSE
            DO IWID = 1,NSRC
              WIDS(IWID) = 0
            END DO
            CALL USI_DEF1R( 'WIDTHS', NSRC, WIDS, STATUS )
            CALL USI_GET1R( 'WIDTHS', NSRC, WIDS, ACTWID, STATUS )
            IF ( ACTWID .EQ. 1 ) THEN
              CALL ARR_INIT1R( WIDS(1), NSRC, WIDS, STATUS )
            ELSE IF ( STATUS .NE. SAI__OK ) THEN
              GOTO 99
            ELSE IF ( ACTWID .NE. NSRC ) THEN
              CALL USI_CANCL( 'WIDTHS', STATUS )
              GOTO 40
            END IF
          END IF
          IF ( STATUS .NE. SAI__OK ) GOTO 99
        END IF

*      Psf to vary across field
        CALL USI_GET0L( 'PSFCON', PSFCON, STATUS )

*      Psf size
        CALL USI_GET0I( 'SRADIUS', PSW, STATUS )
        IF ( STATUS .NE. SAI__OK ) GOTO 99

*      Map psf data
        PSW2 = PSW+1
        PIN = (2*PSW2+1)**2
        IF ( PSFCON .AND. ( ACTWID .EQ. 1 ) ) THEN
          CALL DYN_MAPR( 1, PIN, PDPTR, STATUS )
          CALL DYN_MAPR( 1, PIN+1, PIPTR, STATUS )
        ELSE
          CALL DYN_MAPR( 1, PIN*NSRC, PDPTR, STATUS )
          CALL DYN_MAPR( 1, (PIN+1)*NSRC, PIPTR, STATUS )
        END IF
        CALL DYN_MAPR( 1, PIN, PTPTR, STATUS )
        CALL DYN_MAPR( 1, PIN, PKPTR, STATUS )

*    Prevent problems declaring psf arrays in EVSIM_INT
      ELSE
        PIN = 1
        PSW = 1
        PSW2 = 1

      END IF

*  For each output file
      DO IFILE = 1, NFILE

*    Construct file name
        IF ( NFILE .EQ. 1 ) THEN
          ONAME = OROOT
        ELSE
 12       FORMAT ( 2A, I4.4 )
          WRITE( ONAME, 12 ) OROOT(:CHR_LEN(OROOT)), '_', IFILE+FFILE-1
          CALL MSG_SETI( 'N', IFILE+FFILE-1 )
          CALL MSG_PRNT( 'Creating file ^N' )
        END IF

*    Introduce Poisson noise into source and background
        IF ( PDEV .AND. (ONBACK.GT.0) ) THEN
          NBACK = MATH_POISS(FLOAT(ONBACK))
        ELSE
          NBACK = ONBACK
        END IF
        NPT = NBACK
        DO ISRC = 1, NSRC
          IF ( PDEV ) THEN
            SCOUNT(ISRC) = MATH_POISS(FLOAT(OSCOUNT(ISRC)))
          ELSE
            SCOUNT(ISRC) = OSCOUNT(ISRC)
          END IF
          NPT = NPT + SCOUNT(ISRC)
        END DO

*    Define EventDS
        CALL ADI_NEW0( 'EventDS', EVID, STATUS )
        CALL ADI_CPUT0I( EVID, 'NEVENT', NPT, STATUS )

*    Open file
        CALL ADI_FCREAT( ONAME(:CHR_LEN(ONAME))//'%hds', EVID,
     :                   OFID, STATUS )

*    Create the dataset lists
        CALL EDI_CREL0R( OFID, 'X_CORR', XDEC, XLO, XHI,
     :                   0.0, UNITS, XLID, STATUS )
        CALL EDI_CREL0R( OFID, 'Y_CORR', YDEC, YLO, YHI,
     :                   0.0, UNITS, YLID, STATUS )
        CALL EDI_CREAT( OFID, XLID, STATUS )
        CALL EDI_CREAT( OFID, YLID, STATUS )

*    Map the lists
        CALL EDI_MAPR( OFID, 'X_CORR', 'WRITE', 0, 0, XPTR, STATUS )
        CALL EDI_MAPR( OFID, 'Y_CORR', 'WRITE', 0, 0, YPTR, STATUS )

*    Write astrometry
        CALL WCI_PUTIDS( OFID, PIXID, PRJID, SYSID, STATUS )

*    Associate psf if first time through
        IF ( IFILE .EQ. 1 ) THEN

*      Associate psf if first time through
          IF ( NSRC .GT. 0 ) THEN
            CALL PSF_ASSOCO( OFID, PSLOT, STATUS )
            IF ( STATUS .NE. SAI__OK ) GOTO 99
          END IF

        END IF

*    Dump counts to user
        CALL MSG_SETI( 'NB', NBACK )
        CALL MSG_PRNT( 'Background ^NB counts' )
        DO ISRC = 1, NSRC
          CALL MSG_SETI( 'N', ISRC )
          CALL MSG_SETI( 'SC', SCOUNT(ISRC) )
          CALL MSG_PRNT( 'Source ^N ^SC counts' )
        END DO

*    Create events
        CALL EVSIM_INT( OFID, PSLOT, PSFCON, SEED_GIVEN, SEED,
     :                  NSRC, SCOUNT, WIDS, NBACK, MOK, DIMS(1),
     :                  DIMS(2), %VAL(MIPTR), PSIZE, TOR, XLO, XHI,
     :                  XDEC, YLO, YHI, YDEC, %VAL(XPTR), %VAL(YPTR),
     :                  IFILE, PSW2, %VAL(PDPTR), %VAL(PTPTR),
     :                  %VAL(PKPTR), PIN, %VAL(PIPTR),
     :                  XPOS, YPOS, NOUT, STATUS )

        SEED_GIVEN = .FALSE.

*    Unmap lists
        CALL EDI_UNMAP( OFID, 'X_CORR', STATUS )
        CALL EDI_UNMAP( OFID, 'Y_CORR', STATUS )

*    Lists to be altered
        IF ( NOUT .GT. 0 ) THEN
          CALL EDI_ALTLEN( OFID, NPT-NOUT, STATUS )
        END IF

*    Close if not first file, or if this is the last file
        IF ( (IFILE.GT.1) .OR. (IFILE.EQ.NFILE) ) THEN
          CALL ADI_FCLOSE( OFID, STATUS )
        END IF

      END DO

*  Free model
      IF ( MOK ) THEN
        CALL USI_ANNUL( 'MODEL', STATUS )
      END IF

*  Tidy up
 99   CALL PSF_CLOSE( STATUS )
      CALL AST_CLOSE()
      CALL AST_ERR( STATUS )

      END



*+  EVSIM_INT - Creates the dummy data set
      SUBROUTINE EVSIM_INT( OFID, PSFH, PSFCON, SEEDOK, GSEED,
     :                      NSRC, SCOUNT, WID, NMOD, MOK,
     :                      BNX, BNY, MPI, DX, TOR, XMIN, XMAX,
     :                      XDEC, YMIN, YMAX, YDEC, XP, YP,
     :                      IFILE, PW, PD, PTEMP, PKERN,
     :                      PIN, PI, SX, SY, NOUT, STATUS )
*
*    Description:
*
*     Dimensions the x and y lists, and places the background randomly
*     into them. Then puts source photons into the image, calculates
*     a cumulative probability for the psf-gets a radius from the
*     random no. generator, and generates a random angle and hence
*     places the photon.
*
*    Method:
*    Bugs:
*    Author:
*
*     Rob Jeffries (BHVAD::RDJ)
*
*    History:
*
*     20 Jul 89 : Original (BHVAD::RDJ)
*
*    Type Definitions:
*
      IMPLICIT NONE
*
*    Global Constants:
*
      INCLUDE 'SAE_PAR'
      INCLUDE 'MATH_PAR'
*
*    Status:
*
      INTEGER STATUS
*
*    Import:
*
      INTEGER			OFID			! Output dataset id
      INTEGER                 	PSFH                	! PSF system handle
      LOGICAL                 PSFCON              ! Psf constant across field?
      INTEGER                 PW                  ! Psf width in pixels
      REAL                    PD(-PW:PW,-PW:PW,*) ! Psf data
      REAL                    PTEMP(-PW:PW,-PW:PW) ! Psf data
      REAL                    PKERN(-PW:PW,-PW:PW) ! Psf data
      INTEGER                 PIN                 ! Psf index size (PW*2+1)^2+1
      REAL                    PI(PIN,*)           ! Psf index data
      LOGICAL                 SEEDOK              ! Seed given?
      INTEGER                 GSEED               ! Seed for random generator
      INTEGER                 NSRC                ! # of sources
      INTEGER                 SCOUNT(*)           ! # of source counts
      REAL                    WID(*)              ! Source extensions
      INTEGER                 NMOD                ! # of model counts
      LOGICAL                 MOK                 ! Use probability model?
      INTEGER                 BNX, BNY            ! Dimensions of model
      INTEGER                 MPI(*)              ! Model probability index
      REAL                    DX                  ! Pixel size
      REAL                    TOR                 ! Units to radians factor
      REAL                    XMIN,XMAX,YMIN,YMAX ! Image bounds
      REAL                    SX(*),SY(*)         ! Source positions
      INTEGER                 IFILE               ! File number
      LOGICAL                 XDEC, YDEC          ! Axes decreasing?
*
*    Export :
*
      REAL                    XP(*), YP(*)        ! List data
      INTEGER                 NOUT                ! # events not to be output
*
*    Functions :
*
      REAL                    MATH_RND
*
*    Local Variables:
*
      REAL             FWX, FWY                         ! Field full widths
C      REAL             GAU(0:MAXPSF)                    ! Gaussian data
C      REAL             GSIG                             ! Gaussian sigma in arcmin
C      REAL             PGSIG                            ! Gaussian sigma in pix
      REAL             PSUM                             ! Psf normalisation
      REAL             RPW                              ! real(PW)-1.0
      REAL             PTW                              !
      REAL		SIGP
      REAL             SDX, SDY                         ! Signed radian pix size

      INTEGER          ISRC                     	! Loop indices
      INTEGER          IP, IPHOT                        ! Photon counters
      INTEGER          PSRC                             ! Source of psf data
      INTEGER          SEED                             ! Seed for MATH_RND
*-

*    Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*    Initialise
      NOUT = 0

*    Widths in axis units
      FWX = XMAX - XMIN
      FWY = YMAX - YMIN

*    Pixel sizes in radians for psf system
      SDX = DX*TOR
      IF ( XDEC ) SDX = - SDX
      SDY = DX*TOR
      IF ( YDEC ) SDY = - SDY

*    Set up the seed
      IF ( .NOT. SEEDOK ) THEN
        CALL PSX_TIME( SEED, STATUS )
        SEED = -MOD(SEED,13535321)
      ELSE
        SEED = GSEED
      END IF

*    Write simulation parameters
      CALL AUI_PUT0I( OFID, 'SIM_DATA.SEED', SEED, STATUS )
      CALL AUI_PUT0I( OFID, 'SIM_DATA.BCOUNT', NMOD, STATUS )
      IF ( NSRC .GT. 0 ) THEN
        CALL AUI_PUT1I( OFID, 'SIM_DATA.SCOUNT', NSRC, SCOUNT, STATUS )
      END IF

*    Jump over this bit if no source
      IF ( NSRC .EQ. 0 ) GOTO 50

*    Find the psf probability distribution
      IF ( IFILE .EQ. 1 ) THEN

*      Only need first psf if psf constant
        DO ISRC = 1, NSRC

*        Get radial profile
          IF ( ( ISRC .EQ. 1 ) .OR. .NOT. PSFCON ) THEN

*          Evaluate psf into subsection o psf array. PW covers the
*          access region plus border strip
            CALL PSF_2D_DATA( PSFH, SX(ISRC)*TOR, SY(ISRC)*TOR,
     :                        0.0, 0.0, SDX, SDY, .TRUE., PW*2+1,
     :                        PW*2+1, PD(-PW,-PW,ISRC), STATUS )

*        Convolve with gaussian?
          IF ( WID(ISRC) .GT. 0.0 ) THEN

*          Make gaussian of this width
            SIGP = (WID(ISRC) / (2.0 * SQRT(2.0*ALOG(2.0))))
     :             / (ABS(DX)*MATH__RTOD*60.0)
            CALL MATH_INTGAU2D( SIGP, SIGP, 0.0, 0.0, 0.0,
     :                          0.0, 0.0, 1.0, 1.0, PW*2+1, PW*2+1,
     :                          PKERN, STATUS )

*          Make copy of psf
            CALL ARR_COP1R( (PW*2+1)**2, PD(-PW,-PW,ISRC), PTEMP,
     :                     STATUS )

*          Convolve
            CALL PSF_CONVOLVE( PW*2+1, TPW*2+1, PTEMP, PW*2+1, PW*2+1,
     :                         PKERN, PD(-PW,-PW,ISRC), STATUS )

          END IF

*          Copy and psf the psf data into the full array
            CALL SIM_PADJUST( PW*2+1, PD(-PW,-PW,ISRC) )

*          Create index
            CALL SIM_MNORM( (PW*2+1)**2, PD(-PW,-PW,ISRC), .FALSE.,
     :                                  0, PI(1,ISRC), PSUM, STATUS )

          END IF

        END DO

      END IF

*    Distribute the model photons
 50   IF ( MOK ) THEN

*      Get photon positions in model pixels
        CALL EVSIM_APMOD( BNX, BNY, MPI, NMOD, SEED, XP, YP, STATUS )

*      Convert to axis units
        IF ( XDEC ) THEN
          DO IPHOT = 1, NMOD
            XP(IPHOT) = XMAX - (XP(IPHOT)-0.5)*DX
          END DO
        ELSE
          DO IPHOT = 1, NMOD
            XP(IPHOT) = XMIN + (XP(IPHOT)-0.5)*DX
          END DO
        END IF
        IF ( YDEC ) THEN
          DO IPHOT = 1, NMOD
            YP(IPHOT) = YMAX - (YP(IPHOT)-0.5)*DX
          END DO
        ELSE
          DO IPHOT = 1, NMOD
            YP(IPHOT) = YMIN + (YP(IPHOT)-0.5)*DX
          END DO
        END IF

      ELSE

*      For each photon
        DO IPHOT = 1, NMOD
          XP(IPHOT) = FWX * MATH_RND() + XMIN
          YP(IPHOT) = FWY * MATH_RND() + YMIN
        END DO

      END IF

*    For each source
      IPHOT = NMOD + 1
      DO ISRC = 1, NSRC

*      Source of psf
        IF ( PSFCON ) THEN
          PSRC = 1
        ELSE
          PSRC = ISRC
        END IF

*      Find photon positions in model psf array
        CALL EVSIM_APMOD( PW*2+1, PW*2+1, PI(1,PSRC), SCOUNT(ISRC),
     :                         SEED, XP(IPHOT), YP(IPHOT), STATUS )

*      Convert to axis units
        RPW = REAL(PW) + 0.5
        SDX = DX
        SDY = DX
        IF ( XDEC ) SDX = - SDX
        IF ( YDEC ) SDY = - SDY

*      Source photon in field AND in the good psf area
        PTW = REAL(PW*2+1)
        DO IP = IPHOT, IPHOT + SCOUNT(ISRC) - 1
          IF ( (XP(IP) .LT. 0.0 ) .OR.
     :         (YP(IP) .LT. 0.0 ) .OR.
     :         (XP(IP) .GT. PTW ) .OR.
     :         (YP(IP) .GT. PTW ) ) THEN
            NOUT = NOUT + 1
          ELSE
            XP(IP) = SX(ISRC)+(XP(IP)-RPW)*SDX
            YP(IP) = SY(ISRC)+(YP(IP)-RPW)*SDY
            IF ( (XP(IP).GE.XMIN) .AND. (XP(IP).LE.XMAX) .AND.
     :           (YP(IP).GE.YMIN) .AND. (YP(IP).LE.YMAX) ) THEN
              IPHOT = IPHOT + 1
              XP(IPHOT) = XP(IP)
              YP(IPHOT) = YP(IP)
            ELSE
              NOUT = NOUT + 1
            END IF
          END IF
        END DO

      END DO

      END



*+  EVSIM_APMOD - Apply model index array and create a photon list
      SUBROUTINE EVSIM_APMOD( NX, NY, MODEL, NP, SEED, XP, YP, STATUS )
*
*    Description :
*
*     Uses a normalised probability index array to create a list of
*     photon X and Ys which are in pixels from the bottom lhs of the
*     array.
*
*    History :
*
*      7 Mar 92 : Original (DJA)
*
*    Type definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
*
*    Status :
*
      INTEGER STATUS
*
*    Import :
*
      INTEGER                     NX, NY              ! Model dimensions
      REAL                        MODEL(*)            ! Probability index
      INTEGER                     NP                  ! # photons
*
*    Import/export :
*
      INTEGER                     SEED                ! Random generator seed
*
*    Export :
*
      REAL                        XP(NP), YP(NP)      ! Photon positions
*
*    Functions :
*
      REAL                        MATH_RND
*
*    Local variables :
*
      REAL                        R                   ! Random number

      INTEGER                     IP                  ! Loop over photons
      INTEGER                     IX,IY               ! Model pixel number
      INTEGER                     J,JL,JM,JU          ! Probability index value
      INTEGER                     NIN                 ! # index values
*-

*    Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*    For each photon
      NIN = NX * NY

      DO IP = 1, NP

*      Get probability of progression to end of model from random generator
        R = MATH_RND()

*      Binary search for value in model index array
        JL = 1
        JU = NIN
        DO WHILE ( (JU-JL) .GT. 1 )
          JM = (JU+JL)/2
          IF ( R .GT. MODEL(JM) ) THEN
            JL = JM
          ELSE
            JU = JM
          END IF
        END DO
        J = JL

*      Convert to model pixels
        IY = J/NX
        IX = J - NX*IY

*      Convert model bin number J to fractional pixels from bottom lhs
*      corner of the psf model array
        XP(IP) = REAL(IX)+MATH_RND()
        YP(IP) = REAL(IY)+MATH_RND()

      END DO

      END
