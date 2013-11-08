*+  HDS2TEXT - Exports one or more numeric arrays to an  ASCII file
      SUBROUTINE HDS2TEXT( STATUS )
*
*    Description :
*
*
*    Environment parameters :
*
*     OUT                   = CHAR(R)
*                 The ASCII file to send the output
*     IN1                   = CHAR(R)
*                 The first input object
*
*     ...         ......................
*
*     IN9                   = CHAR(R)
*                 The ninth input object
*     FMT                   = CHAR(R)
*                 Output format
*
*    Method :
*    Deficiencies :
*    Bugs :
*    Authors :
*
*     David J. Allan (BHVAD::DJA)
*
*    History :
*
*     15 Nov 89 : V1.0-0 Original (DJA)
*      5 Dec 90 : V1.3-0 Works on spaced arrays (DJA)
*      3 Mar 92 : V1.6-0 Renamed from EXPORT (DJA)
*     30 Mar 92 : V1.6-1 Correct use ERR_ANNUL (DJA)
*     24 Nov 94 : V1.8-0 Now use USI for user interface (DJA)
*     14 Feb 95 : V1.8-1 Use AIO for i/o to allow file clobbering (DJA)
*      5 Oct 95 : V2.0-0 Full ADI port (DJA)
*
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
*    Local constants :
*
      INTEGER              MX_IN
         PARAMETER         (MX_IN = 9 )
*
*    Functions :
*
      INTEGER              CHR_LEN
*
*    Local variables :
*
      CHARACTER*40         	OUTF                   	! Output format
      CHARACTER            	PNAME*3                	! Input parameter name
      CHARACTER            	STR*200			! Output buffer

      REAL                 	DATUM                  	! Output datum

      INTEGER              	DIMS(ADI__MXDIM)	! Dimensions of input
      INTEGER			IFID(MX_IN)		! Input identifiers
      INTEGER         		ODIMS(ADI__MXDIM)	! Output dimensions

      INTEGER              	BAD                    	! Number of bad inputs
      INTEGER              	CHAN                   	! Output file channel
      INTEGER              	I, J
      INTEGER              	LTAB
      INTEGER              	N
      INTEGER              	NELM
      INTEGER              	NDIM, ONDIM
      INTEGER              	OLEN                   	! Output format
      INTEGER			OUTWID			! Output channel width
      INTEGER              	PTR(MX_IN)		! Data to write

      LOGICAL              	OK(MX_IN)              	! Inputs ok?
*
*    Version :
*
      CHARACTER*30         VERSION
        PARAMETER          ( VERSION = 'HDS2TEXT Version 2.1-0' )
*-

*    Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*    Set up ASTERIX
      CALL AST_INIT()

*    Loop to get input files
      I = 1
      N = 0
      DO WHILE ( ( I .LE. MX_IN ) .AND. ( STATUS .EQ. SAI__OK ) )
        WRITE( PNAME, '(A2,I1)' ) 'IN', I
        CALL USI_ASSOC( PNAME, 'BinDS|Array', 'READ', IFID(I), STATUS )
        IF ( STATUS .EQ. SAI__OK ) N = N + 1
        I = I + 1
      END DO

*    Bomb out if abort
      IF ( STATUS .EQ. PAR__NULL ) THEN
        CALL ERR_ANNUL( STATUS )
      ELSE
        GOTO 99
      END IF

*  Check all datasets have data are the same size
      BAD = 0
      DO I = 1, N

*    Check input
        CALL BDI_GETSHP( IFID(I), ADI__MXDIM, DIMS, NDIM, STATUS )
        CALL BDI_CHK( IFID(I), 'Data', OK(I), STATUS )

*    Check dimensionality
        IF ( I .EQ. 1 ) THEN
          ONDIM = NDIM
          DO J = 1, NDIM
            ODIMS(J) = DIMS(I)
          END DO
        ELSE
          IF ( NDIM .NE. ONDIM ) THEN
            CALL MSG_PRNT( 'Dimensionality mismatch' )
            OK(I) = .FALSE.
          ELSE
            DO J = 1, ONDIM
              IF ( DIMS(J) .NE. ODIMS(J) ) THEN
                CALL MSG_PRNT( 'Dimensionality mismatch' )
                OK(I) = .FALSE.
                GOTO 49
              END IF
            END DO
          END IF
        END IF

*    Map the data
        CALL BDI_MAPR( IFID(I), 'Data', 'READ', PTR(I), STATUS )

 49     CONTINUE

        IF ( ( STATUS .NE. SAI__OK ) .OR. .NOT. OK(I) ) THEN
          IF ( BAD .NE. N ) THEN
            CALL MSG_SETI( 'I', I )
            CALL MSG_PRNT( 'Object number ^I has no valid data - '/
     :                               /'ignored in output' )
          ELSE
            CALL MSG_PRNT( 'All inputs are bad!' )
            STATUS = SAI__ERROR
          END IF
        END IF

      END DO
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Move valid pointers to bottom of array and reset N
      J = 1
      DO I = 1, N - BAD
        IF ( OK(I) ) THEN
          PTR(J) = PTR(I)
          J = J + 1
        END IF
      END DO
      N = N - BAD

*  Total number of data items per array
      CALL ARR_SUMDIM( NDIM, ODIMS, NELM )

*  Get format
      CALL USI_GET0C( 'FMT', OUTF, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
        OUTF='1P,G14.6'
        CALL ERR_ANNUL( STATUS )
      END IF

*    Open output file
      CALL AIO_ASSOCO( 'OUT', 'LIST', CHAN, OUTWID, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Output the data
      OLEN = CHR_LEN(OUTF)
      OUTF = '('//OUTF(:OLEN)//')'
      OLEN = OLEN + 2
      DO I = 1, NELM
        STR = ' '
        LTAB = 2
        DO J = 1, N
          CALL ARR_ELEM1R( PTR(J), NELM, I, DATUM, STATUS )
          WRITE ( STR(LTAB:(LTAB+14)), OUTF(:OLEN) ) DATUM
          LTAB = LTAB + 15
        END DO
        CALL AIO_WRITE( CHAN, STR(:(LTAB-1)), STATUS )
      END DO

*  Close down output
      CALL AIO_CANCL( 'OUT', STATUS )

*  Tidy up
 99   CALL AST_CLOSE()
      CALL AST_ERR( STATUS )

      END
