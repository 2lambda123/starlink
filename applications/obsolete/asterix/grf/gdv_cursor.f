*+  GDV_CURSOR - does it have a cursor?
      SUBROUTINE GDV_CURSOR(CURSOR,STATUS)
*    Description :
*    Authors :
*    Type definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
*    Global variables :
      INCLUDE 'GDV_CMN'
*    Structure definitions :
*    Import :
*    Import-Export :
*    Export :
      LOGICAL CURSOR
*    Status :
      INTEGER STATUS
*    Function declarations :
*    Local constants :
*    Local variables :
      LOGICAL OK
*-

      IF (STATUS.EQ.SAI__OK) THEN

        CALL GDV_STATUS(OK,STATUS)
        IF (OK) THEN
          CURSOR=G_CURSOR
        ELSE
          CALL MSG_PRNT('AST_ERR: no graphics device active')
          STATUS=SAI__ERROR
        ENDIF

        IF (STATUS.NE.SAI__OK) THEN
          CALL AST_REXIT('GDV_CURSOR',STATUS)
        ENDIF

      ENDIF

      END
