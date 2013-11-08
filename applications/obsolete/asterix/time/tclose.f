*+  TCLOSE - close down interactive time-series processing system
      SUBROUTINE TCLOSE(STATUS)
*    Description :
*    Deficiencies :
*    Bugs :
*    Authors :
*     BHVAD::RJV
*    History :
*
*    Type definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
*    Global variables :
      INCLUDE 'TIM_CMN'
*    Status :
      INTEGER STATUS
*    Function declarations :
*    Local constants :
*    Local variables :
      CHARACTER*20 DEV
      INTEGER NCONTXT
      LOGICAL ACTIVE
*    Version :
      CHARACTER*30 VERSION
      PARAMETER (VERSION = 'TCLOSE Version 2.0-0')
*-
      CALL MSG_PRNT(VERSION)

      IF (.NOT.T_OPEN) THEN
        CALL MSG_PRNT('AST_ERR: time-series system not active')
      ELSE

        CALL USI_INIT()

        CALL GCB_ATTACH('TIME',STATUS)
        CALL GCB_DETACH(STATUS)


        CALL GDV_STATUS(ACTIVE,STATUS)
        IF (ACTIVE) THEN
          CALL GCB_QCONTXT(NCONTXT,STATUS)
          IF (NCONTXT.GT.0) THEN
            CALL MSG_PRNT('**** graphics device NOT closed ****')
            CALL MSG_PRNT('**** other contexts are active  ****')
          ELSE
            CALL MSG_PRNT('Closing device....')
            CALL GDV_DEVICE(DEV,STATUS)
            CALL MSG_SETC('DEV',DEV)
            CALL GDV_CLOSE(STATUS)
            CALL MSG_PRNT('^DEV now closed')
          ENDIF
        ENDIF

        T_OPEN=.FALSE.
        CALL ADI_CLOSE(T_FID,STATUS)
        CALL AST_CLOSE()

      ENDIF

      END
