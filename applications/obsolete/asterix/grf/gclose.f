*+  GCLOSE - unload data from graphics system
      SUBROUTINE GCLOSE(STATUS)
*    Description :
*    Deficiencies :
*    Bugs :
*    Authors :
*     BHVAD::RJV
*    History :
*    Type definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'PAR_ERR'
*    Global variables :
      INCLUDE 'GFX_CMN'
      INCLUDE 'GMD_CMN'
*    Status :
      INTEGER STATUS
*    Function declarations :
*    Local constants :
*    Local variables :
      CHARACTER*20 DEV
      INTEGER N

*    Version :
      CHARACTER*30 VERSION
      PARAMETER (VERSION = 'GCLOSE Version 2.0-0')
*-
      CALL USI_INIT()

      CALL MSG_PRNT(VERSION)

      IF (G_OPEN) THEN
        CALL MSG_PRNT('Releasing dataset...')
        CALL GCB_ATTACH('GRAFIX',STATUS)
        IF (G_MULTI) THEN
          CALL ADI_FCLOSE(G_MFID,STATUS)
        ELSE
          CALL GCB_FSAVE(G_ID,STATUS)
          CALL ADI_FCLOSE(G_ID,STATUS)
        ENDIF
        G_OPEN=.FALSE.
        CALL GCB_DETACH(STATUS)
      ENDIF

      CALL GCB_QCONTXT(N,STATUS)
      IF (N.GT.0) THEN
        CALL MSG_PRNT('****** Graphics device not closed ******')
        CALL MSG_PRNT('****** other contexts are active  ******')
      ELSE
        CALL MSG_PRNT('Closing device...')
        CALL GDV_DEVICE(DEV,STATUS)
        CALL GDV_CLOSE(STATUS)
        CALL MSG_SETC('DEV',DEV)
        CALL MSG_PRNT('^DEV now closed')
      ENDIF

      CALL USI_CLOSE()

      END
