************************************************************************
*+  AGI_1FDB - Find the database

      SUBROUTINE AGI_1FDB ( FOUND, STATUS )

*    Description :
*     Get a locator to the database container file if it is there.
*
*    Invocation :
*     CALL AGI_1FDB ( FOUND, STATUS )
*
*    Method :
*     Check status on entry.
*     If this is the first call to AGI_1FDB then
*        See if HDS has been started
*        If it hasn't been started then
*           Start HDS locator facility
*        Endif
*        Initialise the database cache.
*        Set a flag ( and save it ) to ensure this section is not repeated.
*     Endif
*     See if the locator in the common block is valid
*     If it is then the database is already open so set found to true
*     Else see if a database file exists
*        Open the database file
*        Set found to false if an error has occured in this section
*        
*    Authors :
*     Nick Eaton  ( DUVAD::NE )
*
*    History :
*     July 1988
*     July 1989  Store database locator in common block
*     July 1990  Call AGI_1FNAME
*     Dec  1991  Remove calls to EXC_1LEVEL and HDS_TUNE
*     Mar  1992  Define file extension using AGI__ENAME parameter
*     Oct  1993  Remove unused variable
*    endhistory
*
*    Type Definitions :
      IMPLICIT NONE

*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'agi_nam'

*    Export :

*    Flag to indicate if database has been found.
      LOGICAL FOUND

*    Status :
      INTEGER STATUS

*    Global variables :
      INCLUDE 'agi_locs'

*    Local variables :
      LOGICAL FIRST, STATE

      CHARACTER FNAME * 64

      INTEGER LEXT, LNAME

*    Local data :
      DATA FIRST /.TRUE./
      SAVE FIRST
*-

      IF ( STATUS .EQ. SAI__OK ) THEN

*   Do various tasks on the first time round
         IF ( FIRST ) THEN

*   See if HDS has been started
            CALL HDS_STATE( STATE, STATUS )

*   If it has not been started then we are not in ADAM so start HDS
            IF ( .NOT. STATE ) THEN
               CALL HDS_START( STATUS )
            ENDIF

*   Initialise database cache
            CALL AGI_1INIT

*   Set the database locator valid flag to false
            LOCVAL = .FALSE.

*   Make sure this is not done again
            FIRST = .FALSE.
         ENDIF

*   See if the database locator is valid
         IF ( LOCVAL ) THEN
            FOUND = .TRUE.

*   Otherwise check if database is already there
         ELSE

*   Get the database file name
            CALL AGI_1FNAME( FNAME, LNAME, STATUS )

*   Add the file extension to the database file name
            LEXT = LEN( AGI__ENAME )
            FNAME( LNAME+1 : LNAME+LEXT ) = AGI__ENAME

*   Inquire if the file exists
            INQUIRE( FILE = FNAME( :LNAME+LEXT ), EXIST = FOUND )

*   If found then open the file
            IF ( FOUND ) THEN
C               CALL HDS_TUNE( 'WAIT', .TRUE., STATUS )
               DABLOC = ' '
               CALL HDS_OPEN( FNAME( :LNAME+LEXT ), AGI__DBMOD, DABLOC,
     :                        STATUS )

*   If an error occured opening the file then set found to false
               IF ( STATUS .NE. SAI__OK ) THEN
                  FOUND = .FALSE.
                  LOCVAL = .FALSE.
                  GOTO 99
               ENDIF

*   Set the database locator valid flag and the flush flag
               LOCVAL = .TRUE.
               FLUSH = .TRUE.

            ENDIF
         ENDIF
      ENDIF

  99  CONTINUE

*      print*, '+++++ AGI_1FDB +++++'
*      call HDS_SHOW( 'FILES', status )
*      call HDS_SHOW( 'LOCATORS', status )

      END

