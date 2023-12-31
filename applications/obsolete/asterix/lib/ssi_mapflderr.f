*+  SSI_MAPFLDERR - Map an SSO field's error
      SUBROUTINE SSI_MAPFLDERR( ID, FLD, TYPE, MODE, PTR, STATUS )
*    Description :
*
*     Map an old format SSDS field error. A wrap up for all the old routines.
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
*     17 Jun 91 : Original (DJA)
*
*    Type definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
*
*    Import :
*
      CHARACTER*(DAT__SZLOC)       LOC           ! SSDS locator
      CHARACTER*(*)                FLD           ! Field to map
      CHARACTER*(*)                TYPE          ! Mapping type
      CHARACTER*(*)                MODE          ! Access mode
*
*    Export :
*
      INTEGER                      PTR           ! Ptr to mapped field
*
*    Status :
*
      INTEGER STATUS
*
*    Local variables :
*
      INTEGER ID
*-

      IF(STATUS.EQ.SAI__OK) THEN
        CALL ADI1_GETLOC(ID,LOC,STATUS)
        CALL SSO_MAPFLDERR( LOC, FLD, TYPE, MODE, PTR, STATUS )
        IF ( STATUS.NE.SAI__OK ) THEN
          CALL AST_REXIT( 'SSI_MAPFLDERR', STATUS )
        ENDIF
      ENDIF
      END
