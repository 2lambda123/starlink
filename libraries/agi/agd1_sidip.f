************************************************************************
*+  AGD_1SIDIP - Store IDI parameters in the database

      SUBROUTINE AGD_1SIDIP ( STATUS )

*    Description :
*     Store the current IDI zoom and scroll factors in the database.
*     The IDI display identifier is used to identify which workstation
*     structure is to be the recipient.
*
*    Invocation :
*     CALL AGD_1SIDIP( STATUS )
*
*    Method :
*     Check status on entry.
*     Verify the common block identifiers.
*     Find the correct workstation by matching the IDI display identifiers.
*     Open the database and get a locator to the workstation structure.
*     If there is an IDI parameter structure then
*        If it does not have sufficient dimensions then
*           Increase the dimensions of the structure.
*        Endif
*     Else
*        Create a structure.
*     Endif
*     Fill the structure with the values from the common blocks.
*
*    Deficiencies :
*     <description of any deficiencies>
*
*    Bugs :
*     <description of any "bugs" which have not been fixed>
*
*    Authors :
*     Nick Eaton  ( DUVAD::NE )
*
*    History :
*     June 1990
*    endhistory
*
*    Type Definitions :
      IMPLICIT NONE

*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'agi_nam'
      INCLUDE 'AGI_PAR'
      INCLUDE 'AGI_ERR'

*    Status :
      INTEGER STATUS

*    Global variables :
      INCLUDE 'agi_idips'
      INCLUDE 'agi_locs'
      INCLUDE 'agi_pfree'

*    Local variables :
      LOGICAL FOUND, YESNO

      INTEGER IDIMS( 2 ), IDIPAR( 3, MXMEMS ), J, JMEMS, NDIM, PICID

      CHARACTER * ( DAT__SZLOC ) ISTLOC, WKSLOC
      CHARACTER * ( DAT__SZNAM ) WKNAME
*-

*   Check status on entry
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*   Verify the display identifier in the common block
      IF ( CDIPID .LE. 0 ) GOTO 99

*   Verify the number of memories on the current device
      IF ( CNMEMS .LT. 1 ) GOTO 99
      JMEMS = MIN( CNMEMS, MXMEMS )

*   Find a workstation entry that has the same IDI identifier as
*   the one in the IDI parameters common block
      IF ( CDIPID .EQ. CIDIID( CURPID ) ) THEN
         PICID = CURPID
      ELSE
         DO 10 J = 1, FRELEN
            IF ( CIDIID( J ) .EQ. CDIPID ) THEN
               PICID = J
               GOTO 20
            ENDIF
  10     CONTINUE

*   If this point is reached then there are no matches
         STATUS = AGI__IMPID
         CALL ERR_REP( 'AGI_1SIDIP_IPID',
     :                     'Picture identifier is improper', STATUS )
         GOTO 99

  20     CONTINUE
      ENDIF

*   Get the workstation name for this device
      WKNAME = CAGIWK( PICID )

*   Get a locator to the workstation structure
      CALL AGI_1FDB( FOUND, STATUS )
      IF ( FOUND ) THEN
         WKSLOC = ' '
         CALL AGI_1FWORK( WKNAME, WKSLOC, FOUND, STATUS )
      ENDIF

*   If the workstation structure was found then continue
      IF ( FOUND ) THEN

*   See if there is an IDIPAR structure already
         CALL DAT_THERE( WKSLOC, AGI__IDNAM, YESNO, STATUS )
         ISTLOC = ' '

*   Check that it has sufficient dimensions
         IF ( YESNO ) THEN
            CALL DAT_FIND( WKSLOC, AGI__IDNAM, ISTLOC, STATUS )
            CALL DAT_SHAPE( ISTLOC, 2, IDIMS, NDIM, STATUS )
            IF ( ( NDIM .LT. 1 ) .OR. ( NDIM .GT. 2 ) .OR.
     :           ( IDIMS( 1 ) .NE. 3 ) ) THEN
               STATUS = AGI__DINER
               CALL ERR_REP( 'AGI_1SIDIP_DINE',
     :                       'Database integrity error', STATUS )
               GOTO 98
            ENDIF

*   If not then increase the dimensions
            IF ( IDIMS( 2 ) .LT. JMEMS ) THEN
               IDIMS( 2 ) = JMEMS
               CALL DAT_ALTER( ISTLOC, 2, IDIMS, STATUS )
            ENDIF

*   If the IDIPAR structure is not there then create one
         ELSE
            IDIMS( 1 ) = 3
            IDIMS( 2 ) = JMEMS
            CALL DAT_NEW( WKSLOC, AGI__IDNAM, '_INTEGER', 2, IDIMS,
     :                    STATUS )
            CALL DAT_FIND( WKSLOC, AGI__IDNAM, ISTLOC, STATUS )
         ENDIF

*   Fill the structure with the current values
*   The parameters are (1) zoom factor, (2) x-scroll, (3) y-scroll.
         DO 30 J = 1, JMEMS
            IDIPAR( 1, J ) = CZOOMF( J - 1 )
            IDIPAR( 2, J ) = CXSCRL( J - 1 )
            IDIPAR( 3, J ) = CYSCRL( J - 1 )
  30     CONTINUE
         IDIMS( 1 ) = 3
         IDIMS( 2 ) = JMEMS
         CALL DAT_PUTI( ISTLOC, 2, IDIMS, IDIPAR, STATUS )

*   Indicate that the database has been updated
         FLUSH = .TRUE.

*   Annul the locators
  98     CONTINUE
         CALL DAT_ANNUL( ISTLOC, STATUS )
         ISTLOC = ' '
         CALL DAT_ANNUL( WKSLOC, STATUS )
         WKSLOC = ' '

*   Otherwise report an error
      ELSE
         STATUS = AGI__WKSNF
         CALL ERR_REP( 'AGD_1SIDIP_WKNF', 'Workstation not found',
     :                 STATUS )
         GOTO 99
      ENDIF

  99  CONTINUE

*      print*, '+++++ AGD_1SIDIP +++++'
*      call HDS_SHOW( 'FILES', status )
*      call HDS_SHOW( 'LOCATORS', status )

      END

