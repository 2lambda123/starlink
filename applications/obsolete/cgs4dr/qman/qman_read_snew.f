*+  QMAN_READ_SNEW - Get record number at maximum time 
      SUBROUTINE QMAN_READ_SNEW( STATUS )
*    Invocation :
*     CALL QMAN_READ_SNEW( STATUS )
*    Authors :
*     P. N. Daly (PND@JACH.HAWAII.EDU)
*    History :
*     27-May-1994: Original version                                   (PND)
*    endhistory
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'               ! Defines SAI__OK and others
      INCLUDE 'PRM_PAR'               ! Defines VAL__something messages
      INCLUDE 'MESSYS_LEN'                 ! Defines MSG_VAL_LEN etc
*    Status :
      INTEGER STATUS                  ! Inherited global ADAM status
*    Global variables :
      INCLUDE 'QMAN_GLOBAL.PAR'       ! Task global parameters
      INCLUDE 'QMAN_COMMON.BLK'       ! Task common block
*    Local variables :
      INTEGER ICOUNT                  ! Counter
      DOUBLE PRECISION MAXDATE        ! Maximum date 
*-

*   Return immediately if status bad.
      IF ( STATUS .NE. SAI__OK ) RETURN

*   Loop through used records
      MAXDATE = VAL__MIND
      DO ICOUNT = 0, MAX_QENTRIES, 1

*     Use records that match search string
        IF ( CHARQ(ICOUNT).EQ.STRING .AND. DATEQ(ICOUNT).NE.0.0 ) THEN

*       Get the oldest such record
          IF ( DATEQ(ICOUNT).GT.MAXDATE ) THEN
            MAXDATE = DATEQ( ICOUNT )
            READREC_PTR = ICOUNT
          ENDIF
        ENDIF
      ENDDO

*   If no record has been found, point to record zero
      IF ( MAXDATE .EQ. VAL__MIND ) READREC_PTR = 0

*   Write out verbose mode message
      IF ( VERBOSE ) THEN
        CALL MSG_FMTD( 'D', 'F21.14', MAXDATE )
        CALL MSG_SETI( 'R', READREC_PTR )
        CALL MSG_OUT( ' ', 'Maximum time is ^D at record ^R', STATUS )
      ENDIF

*   Exit subroutine
      END
