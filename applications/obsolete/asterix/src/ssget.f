*+  SSGET - Writes information about SSDS to environment variable
      SUBROUTINE SSGET( STATUS )
*
*    Description :
*
*     This application returns many different pieces of information
*     depending on the value of the ITEM parameter.
*
*      Item code     Returned type     Description
*
*      NSRC          _INTEGER          Number of sources in SSDS
*      NFILE         _INTEGER          Number of files searched
*      <FIELD>       _DOUBLE           Field value of ISRC'th source
*
*    Parameters :
*
*     INP = HDS data object
*        Object to be interrogated
*     ITEM = CHAR(R)
*        Item of info wanted
*     ISRC = INTEGER(R)
*        Source number
*     ATTR = UNIV(W)
*        Attribute value
*     ECHO = LOGICAL(R)
*        Echo attribute value to standard output stream?
*
*    Method :
*
*     IF object valid THEN
*       Get attribute value and return it
*     ELSE
*       ATTR = INVALID
*     ENDIF
*
*    Deficiencies :
*    Bugs :
*    Authors :
*
*     David J. Allan (BHVAD::DJA)
*
*    History :
*
*      6 Oct 94 : V1.8-0 Original, adapted from HGET (DJA)
*     24 Nov 94 : V1.8-1 Now use USI for user interface (DJA)
*      8 Feb 1996 : V1.8-2 Use SSI routines (DJA)
*
*    Type Definitions :
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
*    Functions :
*
      INTEGER                	CHR_LEN
      LOGICAL                	STR_ABBREV
*
*    Local constants :
*
      INTEGER                	TYP_INT, TYP_CHAR, TYP_DBLE
        PARAMETER            	( TYP_INT = 1, TYP_CHAR = 2,
     :                            TYP_DBLE = 3 )
*
*    Local variables :
*
      CHARACTER*200          	CVALUE           	! Character attribute
      CHARACTER*40           	FIELD            	! Field to get
      CHARACTER*40           	FITEM            	! Field item to get
      CHARACTER*40           	ITEM             	! Item to get

      DOUBLE PRECISION       	DVALUE           	! Double value

      INTEGER                	ATYPE            	! Attribute type
      INTEGER                	CLEN             	! Length of character attribute
      INTEGER			CPOS			! Char pointer
      INTEGER			ISRC			! Source number
      INTEGER                	IVALUE           	! Integer attribute
      INTEGER                	NCOMP            	! # of files
      INTEGER			NCPOS			! Char pointer
      INTEGER                	NSRC             	! # of sources

      INTEGER                	PTR              	! Ptr to mapped data
      INTEGER			SFID			! Input file identifier
      INTEGER                	TSTAT            	! Temporary status

      LOGICAL                	ECHO             	! Echo to standard output?
      LOGICAL                	OK               	! Validity check
*
*    Version id :
*
      CHARACTER*40           VERSION
        PARAMETER            ( VERSION='SSGET Version 1.8-2' )
*-

*    Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*    Initialise SSO system
      CALL AST_INIT()
      CALL SSO_INIT()

*    Get input object from user
      CALL USI_ASSOC( 'INP', 'SSDS', 'READ', SFID, STATUS )
      CALL ADI1_GETLOC
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*    Get number of sources
      CALL SSI_GETNSRC( SFID, NSRC, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*    Get item code
      CALL USI_GET0C( 'ITEM', ITEM, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99
      CALL CHR_UCASE( ITEM )

*   Item code which does not require source number?
*    Number of sources
      IF ( STR_ABBREV( ITEM, 'NSRC' ) ) THEN
        ATYPE = TYP_INT
        IVALUE = NSRC

*    Number of files searched
      ELSE IF ( STR_ABBREV( ITEM, 'NFILE' ) ) THEN
        CALL ADI_CGET0I( SFID, 'NFILE', NCOMP, STATUS )
        ATYPE = TYP_INT
        IVALUE = NCOMP

      ELSE

*      Extract field name
        CPOS = 0
 10     CONTINUE
        NCPOS = INDEX( ITEM(CPOS+1:), '_' )
        IF ( NCPOS .GT. 0 ) THEN
          CPOS = CPOS + NCPOS
          GOTO 10
        END IF
        IF ( CPOS .GT. 2 ) THEN
          FIELD = ITEM(:CPOS-1)
          FITEM = ITEM(CPOS+1:)
        ELSE
          FIELD = ITEM
          CPOS = 0
        END IF
        CALL SSI_CHKFLD( SFID, FIELD, OK, STATUS )
        IF ( .NOT. OK ) THEN
          CALL MSG_SETC( 'FIELD', FIELD )
          STATUS = SAI__ERROR
          CALL ERR_REP( ' ', 'Field ^FIELD not present', STATUS )
          GOTO 99
        END IF

*      Plain field name?
        IF ( CPOS .EQ. 0 ) THEN

*        Get source number
          CALL USI_GET0I( 'ISRC', ISRC, STATUS )
          IF ( STATUS .NE. SAI__OK ) GOTO 99

          CALL SSI_MAPFLD( SFID, FIELD, '_DOUBLE', 'READ', PTR, STATUS )
          CALL ARR_ELEM1D( PTR, NSRC, ISRC, DVALUE, STATUS )
          CALL SSI_UNMAPFLD( SFID, FIELD, STATUS )
          ATYPE = TYP_DBLE

*      Errors
        ELSE IF ( STR_ABBREV( FITEM, 'ERROR' ) ) THEN

*        Get source number
          CALL USI_GET0I( 'ISRC', ISRC, STATUS )
          IF ( STATUS .NE. SAI__OK ) GOTO 99

          CALL SSI_MAPFLDERR( SFID, FIELD, '_DOUBLE', 'READ', PTR,
     :                        STATUS )
          CALL ARR_ELEM1D( PTR, NSRC, ISRC, DVALUE, STATUS )
          CALL SSI_UNMAPFLD( SFID, FIELD, STATUS )
          ATYPE = TYP_DBLE

*      Other kind of field item
        ELSE
          CALL SSI_GETFITEM0C( SFID, FIELD, FITEM, CVALUE, STATUS )
          CLEN = CHR_LEN(CVALUE)
          ATYPE = TYP_CHAR

        END IF

      END IF

      IF ( STATUS .NE. SAI__OK ) THEN
        ATYPE = TYP_CHAR
        CVALUE = 'INVALID'
      END IF

*    Echo to output?
      CALL USI_GET0L( 'ECHO', ECHO, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*    Write attribute
      TSTAT = SAI__OK
      IF ( ATYPE .EQ. TYP_INT ) THEN
        CALL USI_PUT0I( 'ATTR', IVALUE, TSTAT )
        IF ( ECHO ) CALL MSG_SETI( 'VAL', IVALUE )
      ELSE IF ( ATYPE .EQ. TYP_DBLE ) THEN
        CALL USI_PUT0D( 'ATTR', DVALUE, TSTAT )
        IF ( ECHO ) CALL MSG_SETD( 'VAL', DVALUE )
      ELSE IF ( ATYPE .EQ. TYP_CHAR ) THEN
        CLEN = CHR_LEN( CVALUE )
        CALL USI_PUT0C( 'ATTR', CVALUE(:CLEN), TSTAT )
        IF ( ECHO ) CALL MSG_SETC( 'VAL', CVALUE(1:CLEN) )
      END IF

*    Echo the output?
      IF ( ECHO ) CALL MSG_PRNT( '^VAL' )

*    Release input file
      CALL SSI_RELEASE( SFID, STATUS )

*    Tidy up
 99   CALL SSO_CLOSE( STATUS )
      CALL AST_CLOSE()
      CALL AST_ERR( STATUS )

      END
