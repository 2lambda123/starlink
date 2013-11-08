*+  SLICE - Lists values in a dataset within a given data range
      SUBROUTINE SLICE( STATUS )
*
*   Description :
*
*     Lists all values (with their item numbers) of a N-D array lying within
*     a user-specified range. The array name may be entered explicitly, or
*     the name of a component containing a DATA_ARRAY. Arrays are mapped so
*     there is no size limitation.
*
*   Parameters :
*
*     INP = UNIV(R)
*         Input data object
*     MIN = REAL(R)
*         Minimum value for inclusion in slice
*     MAX = REAL(R)
*         Maximum value for inclusion in slice
*     DEV = CHAR(R)
*         Output ascii device
*
*   Method :
*     Straightforward.
*   Bugs :
*   Authors :
*
*     Trevor Ponman  (BHVAD::TJP)
*     David Allan    (BHVAD::DJA)
*
*   History :
*
*     14 Apr 86 : Original
*     13 Apr 87 : V0.6-1 Quality mapped as integer (TJP)
*     22 Jul 88 : V1.0-0 New STARLINK standards - Asterix88 upgrade. (DJA)
*      6 Oct 88 : V1.0-1 Range selection tidied up. (DJA)
*      1 Mar 89 : V1.0-2 Removed looping over range parameters. (DJA)
*      9 Aug 93 : V1.7-0 Use UTIL_SPOOL to spool output file. Generalised
*                        to N-dimensions (DJA)
*     28 Jul 94 : V1.7-1 Output using AIO routines - DEV parameter to
*                        use standard system. (DJA)
*     24 Nov 94 : V1.8-0 Now use USI for user interface (DJA)
*     21 Apr 95 : V1.8-1 Updated data interface (DJA)
*     12 Dec 1995 : V2.0-0 ADI port (DJA)
*      6 Oct 1997 : V2.0-1 Linux port (RJV)
*
*   Type Definitions :
*
      IMPLICIT NONE
*
*   Global constants :
*
      INCLUDE 'SAE_PAR'
      INCLUDE 'ADI_PAR'

*   Status :
      INTEGER			STATUS          ! Run-time status
*
*   Local Variables :
*
      CHARACTER*80            	UNITS             	! Units of data
      CHARACTER*200           	PATH,FILE         	! Trace information
      CHARACTER*50		TBUF			! Output text buffer

      REAL		      	RMIN,RMAX		! Min & max values of slice
      REAL		      	D			! Data value
      REAL 		      	DQMIN,DQMAX		! Data min & max with quality
      REAL 		      	DMIN,DMAX	        ! Data min & max without quality

      INTEGER		      	DIMSD(ADI__MXDIM) 	! I/p dimensions
      INTEGER			DPTR			! I/p data
      INTEGER			I, K,L			! Loop counters
      INTEGER			IFID			! Input dataset id
      INTEGER		      	INDICES(ADI__MXDIM) 	! Array indices of point
      INTEGER			OCI			! AIO channel id
      INTEGER			NELM			! # data points
      INTEGER			NDIMD		! Dimensionality of data
      INTEGER			NDIMDR		! Dimensionality of data - 1
      INTEGER			NSLICE			! # good points in slice
      INTEGER			NBAD			! # bad points in slice
      INTEGER			QPTR			! Pointer to data quality
      INTEGER			WIDTH			! Width of o/p stream

      LOGICAL                   OK              	! General validity test
      LOGICAL			Q			! Quality value
      LOGICAL			QUAL_OK		! Quality array available?
*
*    Version id:
*
      CHARACTER*21		VERSION
	PARAMETER	        ( VERSION='SLICE Version 2.1-1' )
*-

*    Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Version
      CALL MSG_PRNT( VERSION )

*  Initialise Asterix common blocks
      CALL AST_INIT()

*  Obtain data object, access and check it
      CALL USI_ASSOC( 'INP', 'BinDS|Array', 'READ', IFID, STATUS )
      CALL USI_SHOW( 'Input dataset {INP}', STATUS )

*  Is the input object the array required?
      CALL BDI_CHK( IFID, 'Data', OK, STATUS )
      CALL BDI_GETSHP( IFID, ADI__MXDIM, DIMSD, NDIMD, STATUS )
      IF ( .NOT. OK ) THEN
	CALL MSG_PRNT( 'ERROR : No data object found.' )
        STATUS = SAI__ERROR
      END IF
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Map in data. and quality - find range
      CALL BDI_MAPR( IFID, 'Data', 'READ', DPTR, STATUS )
      CALL ARR_SUMDIM( NDIMD, DIMSD, NELM )
      IF ( STATUS .NE. SAI__OK ) GOTO 99

      CALL BDI_CHK( IFID, 'Quality', QUAL_OK, STATUS )
      IF ( QUAL_OK .AND. ( STATUS .EQ. SAI__OK ) ) THEN
        CALL BDI_MAPL( IFID, 'LogicalQuality', 'READ', QPTR, STATUS )
      END IF
      IF ( STATUS .NE. SAI__OK ) THEN
        CALL ERR_FLUSH( STATUS )
        QUAL_OK = .FALSE.
      END IF

      CALL ARR_RANG1R( NELM, %VAL(DPTR), DMIN, DMAX, STATUS )

      IF ( QUAL_OK ) THEN
	CALL ARR_RANG1RLQ( NELM, %VAL(DPTR), %VAL(QPTR), DQMIN, DQMAX,
     :                      STATUS )
      ELSE
        IF ( .NOT. QUAL_OK ) THEN
          CALL MSG_PRNT( 'No data quality available.' )
	END IF
        QUAL_OK = .FALSE.
      END IF

*  Try to get data units
      CALL BDI_GET0C( IFID, 'Units', UNITS, STATUS )
      IF ( (UNITS .GT. ' ') .OR. (STATUS.NE.SAI__OK)) THEN
        IF ( STATUS .NE. SAI__OK ) CALL ERR_ANNUL( STATUS )
        UNITS = 'data units'
      END IF

*  Inform user about length of data set and data range
      CALL MSG_SETI( 'NELM', NELM )
      CALL MSG_PRNT ( '^NELM data points entered' )
      CALL MSG_SETR( 'MIN', DMIN )
      CALL MSG_SETR( 'MAX', DMAX )
      CALL MSG_SETC( 'UNITS', UNITS )
      CALL MSG_PRNT( 'Data range is ^MIN to ^MAX ^UNITS' )

      IF ( QUAL_OK ) THEN
        CALL MSG_SETR( 'MIN', DQMIN )
        CALL MSG_SETR( 'MAX', DQMAX )
        CALL MSG_SETC( 'UNITS', UNITS )
        CALL MSG_PRNT( 'Range of good quality data is '//
     :                             '^MIN to ^MAX ^UNITS' )
        CALL USI_DEF0R( 'MIN', DQMIN, STATUS )
        CALL USI_DEF0R( 'MAX', DQMAX, STATUS )
      ELSE
        CALL USI_DEF0R( 'MIN', DMIN, STATUS )
        CALL USI_DEF0R( 'MAX', DMAX, STATUS )
      END IF

*  Get range of data
      CALL USI_GET0R( 'MIN', RMIN, STATUS )
      CALL USI_GET0R( 'MAX', RMAX, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99

      IF ( RMIN .LT. RMAX ) THEN
         IF ( RMIN.LT.DMIN ) THEN
            RMIN = DMIN
            CALL MSG_SETR( 'TMIN', DMIN )
            CALL MSG_PRNT( 'WARNING: Min value too small '//
     :                              '- increased to ^TMIN' )
         END IF

         IF ( RMAX .GT. DMAX ) THEN
            RMAX = DMAX
            CALL MSG_SETR( 'TMAX', DMAX )
            CALL MSG_PRNT( 'WARNING: Max value too large '//
     :                              '- decreased to ^TMAX' )
         END IF

         IF ( QUAL_OK ) THEN
            IF ((RMIN.LT.DQMIN).OR.(RMAX.GT.DQMAX)) THEN
               CALL MSG_PRNT( 'WARNING: Range will include'
     :                        //'some bad quality points' )
            END IF
         END IF

      ELSE
        STATUS = SAI__ERROR
        CALL ERR_REP( ' ', 'Lower bound must be less than upper'
     :                                     //' bound.', STATUS )
        GOTO 99

      END IF

*  Open the output device
      CALL AIO_ASSOCO( 'DEV', 'LIST', OCI, WIDTH, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Output header
      CALL AIO_TITLE( OCI, VERSION, STATUS )

*  Report file name
      CALL ADI_FTRACE( IFID, I, PATH, FILE, STATUS )
      IF ( STATUS .NE. SAI__OK ) THEN
        CALL ERR_ANNUL( STATUS )
      ELSE
        CALL AIO_BLNK( OCI, STATUS )
        CALL MSG_SETC( 'FILE', PATH )
        CALL AIO_WRITE( OCI, 'Analysing data set ^FILE', STATUS )
      END IF
      CALL AIO_BLNK( OCI, STATUS )
      CALL MSG_FMTR( 'MIN', '1PG14.6', RMIN )
      CALL MSG_FMTR( 'MAX', '1PG14.6', RMAX )
      CALL AIO_WRITE( OCI, ' Slice limits : ^MIN to ^MAX', STATUS )

*    List points within slice
      NBAD   = 0
      NSLICE = 0

      CALL AIO_BLNK( OCI, STATUS )
      CALL AIO_BLNK( OCI, STATUS )
      CALL AIO_WRITE( OCI, '       Data value           Index', STATUS )
      CALL AIO_WRITE( OCI, '    **********************************'/
     :                /'**********', STATUS )

      NDIMDR = NDIMD - 1
      DO I = 1, NELM

*    Get data value
        CALL ARR_ELEM1R( DPTR, NELM, I, D, STATUS )

*    In user supplied range?
	IF ( (D .GE. RMIN) .AND. (D.LE.RMAX))THEN

*      Increment counter
	  NSLICE = NSLICE + 1

*      Is this a good quality point?
	  IF ( QUAL_OK ) THEN
            CALL ARR_ELEM1L( QPTR, NELM, I, Q, STATUS )
          ELSE
            Q = .TRUE.
	  END IF

*      If its a good point...
          IF ( Q ) THEN

*        Recover array indices
            CALL UTIL_INDEX( NDIMD, DIMSD, I, INDICES )

*        Write line containing value and indices
            WRITE(TBUF,'(1PG14.6,3X,I7)') D,INDICES(1)
            L=35
            DO K=2,NDIMD
              WRITE(TBUF(L:),'(A2,I7)') ', ',INDICES(K)
              L=L+9
            ENDDO
            CALL AIO_IWRITE( OCI, 6, TBUF, STATUS )

          ELSE
            NBAD = NBAD + 1

          END IF
	END IF
      END DO

*  Number of points
      CALL AIO_BLNK( OCI, STATUS )
      CALL AIO_BLNK( OCI, STATUS )
      CALL MSG_SETI( 'NP', NSLICE )
      CALL AIO_WRITE( OCI, 'Total of ^NP points', STATUS )

*  Number of bad points (if any)
      IF ( QUAL_OK ) THEN
        CALL MSG_SETI( 'NB', NBAD )
        CALL AIO_WRITE( OCI, '^NB bad quality points omitted from'/
     :                                          /' slice', STATUS )
      END IF

*  Close file and spool
      CALL AIO_CANCL( 'DEV', STATUS )

*  Tidy up & exit
 99   CALL AST_CLOSE()
      CALL AST_ERR( STATUS )

      END
