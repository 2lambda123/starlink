*+  GCB_CANR - cancel real attribute
      SUBROUTINE GCB_CANR(NAME,STATUS)
*    Description :
*    Type definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'GCB_PAR'
*    Global variables :
      INCLUDE 'GCB_CMN'
*    Structure definitions :
*    Import :
      CHARACTER*(*) NAME
*    Import-Export :
*    Export :
*    Status :
      INTEGER STATUS
*    Function declarations :
*    Local constants :
*    Local variables :
      CHARACTER*16 FMT,TYPE
      INTEGER DISP,SIZ
*-

      IF (STATUS.EQ.SAI__OK) THEN

        CALL GCB_LOCSCAL(NAME,DISP,SIZ,FMT,TYPE,STATUS)
        CALL GCB_CAN_SUB(%val(G_MEMPTR),DISP,SIZ,STATUS)

        IF (STATUS.NE.SAI__OK) THEN
          CALL AST_REXIT('GCB_CANR',STATUS)
        ENDIF

      ENDIF

      END
