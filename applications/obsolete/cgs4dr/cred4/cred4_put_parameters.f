*+  CRED4_PUT_PARAMETERS - Puts a heirarchical item into the parameter file
      SUBROUTINE CRED4_PUT_PARAMETERS( ITEM, VALUE, TYPE, STATUS )
*    Description :
*     This routine takes an item like xxxxCRED4_NB.MISCELLANEOUS.MASK 
*     and populates the parameter file with an associated value. 
*    Invocation :
*     CALL CRED4_PUT_PARAMETERS( ITEM, VALUE, TYPE, STATUS )
*    Parameters :
*     ITEM      = CHARACTER*(*)( READ )
*           The noticeboard item to be modified.
*     VALUE     = CHARACTER*(*)( READ )
*           Character string value, which on entry contains any character
*           string supplied with the action, and which on exit contains
*           any error message to be displayed.
*     STATUS    = INTEGER( UPDATE )
*           Global status. This must be ADAM__OK on entry.
*           If this routine completes successfully, the STATUS
*           will be ADAM__OK on exit. Any other value indicates
*           an error.
*    Method :
*    Deficiencies :
*    Bugs :
*    Authors :
*     P N Daly   (JACH.HAWAII.EDU::PND)
*    History :
*     22-Jan-1993: Original version.                           (PND)
*     22-Dec-1993: Use INDEX instead of string length 
*                   except where the string is NOT unique      (PND)
*     22-Mar-1994: Add automated extract spc                   (PND,KLK)
*     24-May-1994: Add bright and faint source algorithm       (PND)
*     29-Jul-1994: Major changes for Unix port                 (PND)
*    endhistory
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
*    Import-Export :
      CHARACTER*(*)
     :  ITEM,                         ! The item
     :  VALUE,                        ! Character string value
     :  TYPE                          ! Data-type
*    Status :
      INTEGER
     :  STATUS                        ! Global status
*    External references :
      INTEGER
     :  CHR_LEN                       ! Character length finding function
*    Local variables :
      INTEGER
     :  IVALUE,                       ! Integer decoded value
     :  CLEN                          ! Character string length
      LOGICAL
     :  LVALUE                        ! Logical decoded value
      REAL
     :  RVALUE                        ! Real decoded value
*-

*   Check for error on entry
      IF ( STATUS .NE. SAI__OK ) RETURN

*   Initialise local valiables
      IVALUE = 0
      LVALUE = .FALSE.
      RVALUE = 0.0

*   Remove leading blanks from ITEM, VALUE and TYPE
      CALL CHR_RMBLK( ITEM )
      CALL CHR_UCASE( ITEM )
      CALL CHR_LDBLK( VALUE )
      CALL CHR_RMBLK( TYPE )
      CALL CHR_UCASE( TYPE )

*   Convert integer, real and logical values from character encoding
      IF ( INDEX( TYPE, 'INTEGER' ) .GT. 0 ) THEN

         CALL CHR_CTOI( VALUE, IVALUE, STATUS )
      ELSE IF ( INDEX( TYPE, 'LOGICAL' ) .GT. 0 ) THEN

         CALL CHR_CTOL( VALUE, LVALUE, STATUS )
      ELSE IF ( INDEX( TYPE, 'REAL' ) .GT. 0 ) THEN

         CALL CHR_CTOR( VALUE, RVALUE, STATUS )
      ELSE

         CLEN = CHR_LEN( VALUE )
      END IF

*   Populate the parameter file
      IF ( INDEX(ITEM,'REDUCTION.SUBTRACT_BIAS.EXECUTE').GT.0 .OR. 
     :     INDEX(ITEM,'SUBTRACT_BIAS').GT.0 ) THEN 
         CALL PAR_PUT0C( 'SUBTRACT_BIAS', VALUE(1:CLEN), STATUS )

      ELSE IF ( INDEX(ITEM,'REDUCTION.SUBTRACT_DARK.EXECUTE').GT.0 .OR. 
     :          INDEX(ITEM,'SUBTRACT_DARK').GT.0 ) THEN 
         CALL PAR_PUT0C( 'SUBTRACT_DARK', VALUE(1:CLEN), STATUS )

      ELSE IF ( INDEX(ITEM,'REDUCTION.ADD_INT.EXECUTE').GT.0  .OR.
     :          INDEX(ITEM,'ADD_INT').GT.0 ) THEN 
         CALL PAR_PUT0C( 'ADD_INT', VALUE(1:CLEN), STATUS )
 
      ELSE IF ( INDEX(ITEM,'REDUCTION.ARCHIVE_OBS.EXECUTE').GT.0 .OR. 
     :          INDEX(ITEM,'ARCHIVE_OBS').GT.0 ) THEN 
         CALL PAR_PUT0C( 'ARCHIVE_OBS', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.FILE_OBS.EXECUTE').GT.0 .OR. 
     :          INDEX(ITEM,'FILE_OBS').GT.0 ) THEN 
         CALL PAR_PUT0C( 'FILE_OBS', VALUE(1:CLEN), STATUS ) 
 
      ELSE IF ( INDEX(ITEM,'REDUCTION.NORMALISE_FF.EXECUTE').GT.0 .OR. 
     :          ITEM(1:CHR_LEN(ITEM)).EQ.'NORMALISE_FF' ) THEN   
         CALL PAR_PUT0C( 'NORMALISE_FF', VALUE(1:CLEN), STATUS ) 
 
      ELSE IF ( INDEX(ITEM,'REDUCTION.DIVIDE_BY_FF.EXECUTE').GT.0 .OR. 
     :          INDEX(ITEM,'DIVIDE_BY_FF').GT.0 ) THEN 
         CALL PAR_PUT0C( 'DIVIDE_BY_FF', VALUE(1:CLEN), STATUS ) 
 
      ELSE IF ( INDEX(ITEM,'REDUCTION.ADD_OBS.EXECUTE').GT.0 .OR. 
     :          INDEX(ITEM,'ADD_OBS').GT.0 ) THEN 
         CALL PAR_PUT0C( 'ADD_OBS', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.TO_WAVELENGTH.EXECUTE').GT.0 .OR. 
     :          ITEM(1:CHR_LEN(ITEM)).EQ.'TO_WAVELENGTH' ) THEN   
         CALL PAR_PUT0C( 'TO_WAVELENGTH', VALUE(1:CLEN), STATUS ) 
  
      ELSE IF ( INDEX(ITEM,'REDUCTION.DIVIDE_BY_STD.EXECUTE').GT.0 .OR. 
     :          INDEX(ITEM,'DIVIDE_BY_STD').GT.0 ) THEN 
         CALL PAR_PUT0C( 'DIVIDE_BY_STD', VALUE(1:CLEN), STATUS ) 
  
      ELSE IF ( INDEX(ITEM,'REDUCTION.EXTRACT_SPC.EXECUTE').GT.0 .OR. 
     :          ITEM(1:CHR_LEN(ITEM)).EQ.'EXTRACT_SPC' ) THEN  
         CALL PAR_PUT0C( 'EXTRACT_SPC', VALUE(1:CLEN), STATUS ) 
 
      ELSE IF ( INDEX(ITEM,'REDUCTION.AUTOFIT.EXECUTE').GT.0 .OR. 
     :          ITEM(1:CHR_LEN(ITEM)).EQ.'AUTOFIT' ) THEN  
         CALL PAR_PUT0C( 'AUTOFIT', VALUE(1:CLEN), STATUS ) 
 
      ELSE IF ( INDEX(ITEM,'DISPLAY.INT_P0').GT.0 .OR. 
     :          INDEX(ITEM,'INT_P0').GT.0 ) THEN 
         CALL PAR_PUT0C( 'INT_P0', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.INT_P1').GT.0 .OR. 
     :          INDEX(ITEM,'INT_P1').GT.0 ) THEN 
         CALL PAR_PUT0C( 'INT_P1', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.INT_P2').GT.0 .OR. 
     :          INDEX(ITEM,'INT_P2').GT.0 ) THEN 
         CALL PAR_PUT0C( 'INT_P2', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.INT_P3').GT.0 .OR. 
     :          INDEX(ITEM,'INT_P3').GT.0 ) THEN 
         CALL PAR_PUT0C( 'INT_P3', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.INT_P4').GT.0 .OR. 
     :          INDEX(ITEM,'INT_P4').GT.0 ) THEN 
         CALL PAR_PUT0C( 'INT_P4', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.INT_P5').GT.0 .OR. 
     :          INDEX(ITEM,'INT_P5').GT.0 ) THEN 
         CALL PAR_PUT0C( 'INT_P5', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.INT_P6').GT.0 .OR. 
     :          INDEX(ITEM,'INT_P6').GT.0 ) THEN 
         CALL PAR_PUT0C( 'INT_P6', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.INT_P7').GT.0 .OR. 
     :          INDEX(ITEM,'INT_P7').GT.0 ) THEN 
         CALL PAR_PUT0C( 'INT_P7', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.INT_P8').GT.0 .OR. 
     :          INDEX(ITEM,'INT_P8').GT.0 ) THEN 
         CALL PAR_PUT0C( 'INT_P8', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.OBS_P0').GT.0 .OR. 
     :          INDEX(ITEM,'OBS_P0').GT.0 ) THEN 
         CALL PAR_PUT0C( 'OBS_P0', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.OBS_P1').GT.0 .OR. 
     :          INDEX(ITEM,'OBS_P1').GT.0 ) THEN 
         CALL PAR_PUT0C( 'OBS_P1', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.OBS_P2').GT.0 .OR. 
     :          INDEX(ITEM,'OBS_P2').GT.0 ) THEN 
         CALL PAR_PUT0C( 'OBS_P2', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.OBS_P3').GT.0 .OR. 
     :          INDEX(ITEM,'OBS_P3').GT.0 ) THEN 
         CALL PAR_PUT0C( 'OBS_P3', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.OBS_P4').GT.0 .OR. 
     :          INDEX(ITEM,'OBS_P4').GT.0 ) THEN 
         CALL PAR_PUT0C( 'OBS_P4', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.OBS_P5').GT.0 .OR. 
     :          INDEX(ITEM,'OBS_P5').GT.0 ) THEN 
         CALL PAR_PUT0C( 'OBS_P5', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.OBS_P6').GT.0 .OR. 
     :          INDEX(ITEM,'OBS_P6').GT.0 ) THEN 
         CALL PAR_PUT0C( 'OBS_P6', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.OBS_P7').GT.0 .OR. 
     :          INDEX(ITEM,'OBS_P7').GT.0 ) THEN 
         CALL PAR_PUT0C( 'OBS_P7', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.OBS_P8').GT.0 .OR. 
     :          INDEX(ITEM,'OBS_P8').GT.0 ) THEN 
         CALL PAR_PUT0C( 'OBS_P8', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.GRP_P0').GT.0 .OR. 
     :          INDEX(ITEM,'GRP_P0').GT.0 ) THEN 
         CALL PAR_PUT0C( 'GRP_P0', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.GRP_P1').GT.0 .OR. 
     :          INDEX(ITEM,'GRP_P1').GT.0 ) THEN 
         CALL PAR_PUT0C( 'GRP_P1', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.GRP_P2').GT.0 .OR. 
     :          INDEX(ITEM,'GRP_P2').GT.0 ) THEN 
         CALL PAR_PUT0C( 'GRP_P2', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.GRP_P3').GT.0 .OR. 
     :          INDEX(ITEM,'GRP_P3').GT.0 ) THEN 
         CALL PAR_PUT0C( 'GRP_P3', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.GRP_P4').GT.0 .OR. 
     :          INDEX(ITEM,'GRP_P4').GT.0 ) THEN 
         CALL PAR_PUT0C( 'GRP_P4', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.GRP_P5').GT.0 .OR. 
     :          INDEX(ITEM,'GRP_P5').GT.0 ) THEN 
         CALL PAR_PUT0C( 'GRP_P5', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.GRP_P6').GT.0 .OR. 
     :          INDEX(ITEM,'GRP_P6').GT.0 ) THEN 
         CALL PAR_PUT0C( 'GRP_P6', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.GRP_P7').GT.0 .OR. 
     :          INDEX(ITEM,'GRP_P7').GT.0 ) THEN 
         CALL PAR_PUT0C( 'GRP_P7', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.GRP_P8').GT.0 .OR. 
     :          INDEX(ITEM,'GRP_P8').GT.0 ) THEN 
         CALL PAR_PUT0C( 'GRP_P8', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.SPC_P0').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_P0').GT.0 ) THEN 
         CALL PAR_PUT0C( 'SPC_P0', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.SPC_P1').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_P1').GT.0 ) THEN 
         CALL PAR_PUT0C( 'SPC_P1', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.SPC_P2').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_P2').GT.0 ) THEN 
         CALL PAR_PUT0C( 'SPC_P2', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.SPC_P3').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_P3').GT.0 ) THEN 
         CALL PAR_PUT0C( 'SPC_P3', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.SPC_P4').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_P4').GT.0 ) THEN 
         CALL PAR_PUT0C( 'SPC_P4', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.SPC_P5').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_P5').GT.0 ) THEN 
         CALL PAR_PUT0C( 'SPC_P5', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.SPC_P6').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_P6').GT.0 ) THEN 
         CALL PAR_PUT0C( 'SPC_P6', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.SPC_P7').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_P7').GT.0 ) THEN 
         CALL PAR_PUT0C( 'SPC_P7', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'DISPLAY.SPC_P8').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_P8').GT.0 ) THEN 
         CALL PAR_PUT0C( 'SPC_P8', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.BIAS_MODE').GT.0 .OR. 
     :          INDEX(ITEM,'BIAS_MODE').GT.0 ) THEN 
         CALL PAR_PUT0C( 'BIAS_MODE', VALUE(1:CLEN), STATUS ) 
 
      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.SPECIFIED_BIAS').GT.0 .OR. 
     :          INDEX(ITEM,'SPECIFIED_BIAS').GT.0 ) THEN 
         CALL PAR_PUT0C( 'SPECIFIED_BIAS', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.DARK_MODE').GT.0 .OR. 
     :          INDEX(ITEM,'DARK_MODE').GT.0 ) THEN 
         CALL PAR_PUT0C( 'DARK_MODE', VALUE(1:CLEN), STATUS ) 
 
      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.SPECIFIED_DARK').GT.0 .OR. 
     :          INDEX(ITEM,'SPECIFIED_DARK').GT.0 ) THEN 
         CALL PAR_PUT0C( 'SPECIFIED_DARK', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.FLAT_MODE').GT.0 .OR. 
     :          INDEX(ITEM,'FLAT_MODE').GT.0 ) THEN 
         CALL PAR_PUT0C( 'FLAT_MODE', VALUE(1:CLEN), STATUS ) 
 
      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.SPECIFIED_FLAT').GT.0 .OR. 
     :          INDEX(ITEM,'SPECIFIED_FLAT').GT.0 ) THEN 
         CALL PAR_PUT0C( 'SPECIFIED_FLAT', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.CALIB_MODE').GT.0 .OR. 
     :          INDEX(ITEM,'CALIB_MODE').GT.0 ) THEN 
         CALL PAR_PUT0C( 'CALIB_MODE', VALUE(1:CLEN), STATUS ) 
 
      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.SPECIFIED_CALIB').GT.0 .OR. 
     :          INDEX(ITEM,'SPECIFIED_CALIB').GT.0 ) THEN 
         CALL PAR_PUT0C( 'SPECIFIED_CALIB', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.STANDARD_MODE').GT.0 .OR. 
     :          INDEX(ITEM,'STANDARD_MODE').GT.0 ) THEN 
         CALL PAR_PUT0C( 'STANDARD_MODE', VALUE(1:CLEN), STATUS ) 
 
      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.SPECIFIED_STD').GT.0 .OR. 
     :          INDEX(ITEM,'SPECIFIED_STD').GT.0 ) THEN 
         CALL PAR_PUT0C( 'SPECIFIED_STD', VALUE(1:CLEN), STATUS ) 
 
      ELSE IF ( INDEX(ITEM,'REDUCTION.NORMALISE_FF.METHOD').GT.0 .OR. 
     :          INDEX(ITEM,'NORM_METHOD').GT.0 ) THEN 
         CALL PAR_PUT0C( 'NORM_METHOD', VALUE(1:CLEN), STATUS ) 
 
      ELSE IF ( INDEX(ITEM,'REDUCTION.NORMALISE_FF.ORDER').GT.0 .OR. 
     :          INDEX(ITEM,'ORDER').GT.0 ) THEN 
         CALL PAR_PUT0I( 'ORDER', IVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.NORMALISE_FF.BOXSIZE').GT.0 .OR. 
     :          INDEX(ITEM,'BOXSIZE').GT.0 ) THEN 
         CALL PAR_PUT0I( 'BOXSIZE', IVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.TO_WAVELENGTH.METHOD').GT.0 .OR. 
     :          INDEX(ITEM,'LAMBDA_METHOD').GT.0 ) THEN 
         CALL PAR_PUT0C( 'LAMBDA_METHOD', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.ADD_IN_PAIRS').GT.0 .OR. 
     :          INDEX(ITEM,'ADD_IN_PAIRS').GT.0 ) THEN 
         CALL PAR_PUT0L( 'ADD_IN_PAIRS', LVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.VARIANCE_WT').GT.0 .OR. 
     :          INDEX(ITEM,'VARIANCE_WT').GT.0 ) THEN 
         CALL PAR_PUT0L( 'VARIANCE_WT', LVALUE, STATUS ) 

*    NB Can't use INDEX here because "ERRORS" is not a unique keyword
      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.ERRORS').GT.0 .OR. 
     :          ITEM(1:CHR_LEN(ITEM)).EQ.'ERRORS' ) THEN 
         CALL PAR_PUT0C( 'ERRORS', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.SKY_WT').GT.0 .OR. 
     :          INDEX(ITEM,'SKY_WT').GT.0 ) THEN 
         CALL PAR_PUT0R( 'SKY_WT', RVALUE, STATUS )
 
      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.PF_POLYFIT').GT.0 .OR. 
     :          INDEX(ITEM,'PF_POLYFIT').GT.0 ) THEN 
         CALL PAR_PUT0C( 'PF_POLYFIT', VALUE(1:CLEN), STATUS ) 
 
      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.PF_DEGREE').GT.0 .OR. 
     :          INDEX(ITEM,'PF_DEGREE').GT.0 ) THEN 
         CALL PAR_PUT0I( 'PF_DEGREE', IVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.PF_NREJECT').GT.0 .OR. 
     :          INDEX(ITEM,'PF_NREJECT').GT.0 ) THEN 
         CALL PAR_PUT0I( 'PF_NREJECT', IVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.PF_WEIGHT').GT.0 .OR. 
     :          INDEX(ITEM,'PF_WEIGHT').GT.0 ) THEN 
         CALL PAR_PUT0L( 'PF_WEIGHT', LVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.PF_SAYS1').GT.0 .OR. 
     :          INDEX(ITEM,'PF_SAYS1').GT.0 ) THEN 
         CALL PAR_PUT0I( 'PF_SAYS1', IVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.PF_SAYE1').GT.0 .OR. 
     :          INDEX(ITEM,'PF_SAYE1').GT.0 ) THEN 
         CALL PAR_PUT0I( 'PF_SAYE1', IVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.PF_SAYS2').GT.0 .OR. 
     :          INDEX(ITEM,'PF_SAYS2').GT.0 ) THEN 
         CALL PAR_PUT0I( 'PF_SAYS2', IVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.PF_SAYE2').GT.0 .OR. 
     :          INDEX(ITEM,'PF_SAYE2').GT.0 ) THEN 
         CALL PAR_PUT0I( 'PF_SAYE2', IVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.PF_SAYS3').GT.0 .OR. 
     :          INDEX(ITEM,'PF_SAYS3').GT.0 ) THEN 
         CALL PAR_PUT0I( 'PF_SAYS3', IVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.PF_SAYE3').GT.0 .OR. 
     :          INDEX(ITEM,'PF_SAYE3').GT.0 ) THEN 
         CALL PAR_PUT0I( 'PF_SAYE3', IVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.PF_SAYS4').GT.0 .OR. 
     :          INDEX(ITEM,'PF_SAYS4').GT.0 ) THEN 
         CALL PAR_PUT0I( 'PF_SAYS4', IVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.PF_SAYE4').GT.0 .OR. 
     :          INDEX(ITEM,'PF_SAYE4').GT.0 ) THEN 
         CALL PAR_PUT0I( 'PF_SAYE4', IVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.EXTRACT_SPC.ROW1S').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_ROW1S').GT.0 ) THEN 
          CALL PAR_PUT0R( 'SPC_ROW1S', RVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.EXTRACT_SPC.ROW1E').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_ROW1E').GT.0 ) THEN 
          CALL PAR_PUT0R( 'SPC_ROW1E', RVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.EXTRACT_SPC.ROW2S').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_ROW2S').GT.0 ) THEN 
          CALL PAR_PUT0R( 'SPC_ROW2S', RVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.EXTRACT_SPC.ROW2E').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_ROW2E').GT.0 ) THEN 
          CALL PAR_PUT0R( 'SPC_ROW2E', RVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.EXTRACT_SPC.ROW3S').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_ROW3S').GT.0 ) THEN 
          CALL PAR_PUT0R( 'SPC_ROW3S', RVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.EXTRACT_SPC.ROW3E').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_ROW3E').GT.0 ) THEN 
          CALL PAR_PUT0R( 'SPC_ROW3E', RVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.EXTRACT_SPC.INVERT').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_INVERT').GT.0 ) THEN 
          CALL PAR_PUT0L( 'SPC_INVERT', LVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.EXTRACT_SPC.ALGORITHM').GT.0 .OR. 
     :          INDEX(ITEM,'SPC_ALGORITHM').GT.0 ) THEN 
          CALL PAR_PUT0C( 'SPC_ALGORITHM', VALUE(1:CLEN), STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.AUTOFIT.NROWS').GT.0 .OR. 
     :          INDEX(ITEM,'AFIT_NROWS').GT.0 ) THEN 
          CALL PAR_PUT0I( 'AFIT_NROWS', IVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.AUTOFIT.ROW1').GT.0 .OR. 
     :          INDEX(ITEM,'AFIT_ROW1').GT.0 ) THEN 
          CALL PAR_PUT0I( 'AFIT_ROW1', IVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.AUTOFIT.ROW2').GT.0 .OR. 
     :          INDEX(ITEM,'AFIT_ROW2').GT.0 ) THEN 
          CALL PAR_PUT0I( 'AFIT_ROW2', IVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.AUTOFIT.XSTART').GT.0 .OR. 
     :          INDEX(ITEM,'AFIT_XSTART').GT.0 ) THEN 
          CALL PAR_PUT0R( 'AFIT_XSTART', RVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'REDUCTION.AUTOFIT.XEND').GT.0 .OR. 
     :          INDEX(ITEM,'AFIT_XEND').GT.0 ) THEN 
          CALL PAR_PUT0R( 'AFIT_XEND', RVALUE, STATUS ) 

      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.LINCOEFFS').GT.0 .OR. 
     :          INDEX(ITEM,'LINCOEFFS').GT.0 ) THEN 
         CALL PAR_PUT0C( 'LINCOEFFS', VALUE(1:CLEN), STATUS ) 
 
      ELSE IF ( INDEX(ITEM,'MISCELLANEOUS.MASK').GT.0 .OR. 
     :          INDEX(ITEM,'MASK').GT.0 ) THEN 
         CALL PAR_PUT0C( 'MASK', VALUE(1:CLEN), STATUS ) 

      ELSE
        
         STATUS = SAI__ERROR
         CALL MSG_SETC( 'ITEM', ITEM )
         CALL ERR_REP( ' ', 'CRED4_PUT_PARAMETERS: '/
     :      /'Item ^ITEM does not exist in parameter file', STATUS )
      END IF

*   Exit subroutine
      END
