************************************************************************

      SUBROUTINE AGI_END ( PICID, STATUS )

*+
*  Name :
*     AGI_END
*
*  Purpose :
*     Mark the end of an AGI scope.
*
*  Invocation :
*     CALL AGI_END( PICID, STATUS )
*
*  Description :
*     Mark the end of an AGI scope. The given picture is made the
*     current one. If the argument is a negative number then the picture
*     current when the matching AGI_BEGIN was called is made current.
*     All identifiers allocated within this begin-end block are annulled.
*     If the last active identifier is annulled the database is closed.
*
*  Arguments :
*     PICID = INTEGER (Given)
*        Picture identifier
*     STATUS = INTEGER (Given and Returned)
*        The global status
*
*  Algorithm :
*     Initialise control variables.
*     Ensure the database locator is annuled.
*     Close the database if the flag is set
*
*  Authors :
*     NE: Nick Eaton (Durham University)
*
*  History :
*     Nov 1990 (NE):
*        Original version
*     Apr 1991 (NE):
*        Do not pick up a picture whose release has been deferred.
*        Clear transformation flags in cache
*     Nov 1990 (NE):
*        Correct use of local status
*-
*  Type Definitions :
      IMPLICIT NONE

*  Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'AGI_ERR'
      INCLUDE 'AGI_PAR'

*  Global variables :
      INCLUDE 'agi_cache'
      INCLUDE 'agi_locs'
      INCLUDE 'agi_nest'
      INCLUDE 'agi_pfree'

*  Arguments Given :
      INTEGER PICID

*  Status :
      INTEGER STATUS

*  Local variables :
      LOGICAL THERE, YESNO

      INTEGER I, J, LPICID, LSTAT, LOSTAT
*.

*   Decrement the nest counter
      IF ( CNEST .GT. 1 ) THEN
         CNEST = CNEST - 1
      ENDIF

*   Initialise local status
      LSTAT = SAI__OK

*   Make the given picture the current one
      THERE = .FALSE.
      IF ( PICID .GE. 0 ) THEN
         IF ( ( PICID .GE. 1 ) .AND. ( PICID .LE. FRELEN ) ) THEN

*   Check this identifier contains a valid entry
            IF ( CPICNM( PICID ) .GT. 0 ) THEN

*   Select it as the current picture
               CALL AGI_SELP( PICID, LSTAT )
               IF ( LSTAT .EQ. SAI__OK ) THEN
                  THERE = .TRUE.
               ELSE
                  LSTAT = SAI__OK
               ENDIF
            ENDIF
         ENDIF

*   Report an error if there was something amiss with the identifier
         IF ( .NOT. THERE ) THEN
            LSTAT = AGI__IMPID
            CALL ERR_REP( 'AGI_END_IMPID', 'Invalid picture identifier',
     :                    LSTAT )
         ENDIF

*   If the given picture identifier is negative then use the values
*   stored by the matching BEGIN, otherwise do nothing
      ELSE
         IF ( CNESPN( CNEST ) .GT. 0 ) THEN
            LPICID = -1
            DO I = 1, FRELEN

*   Find a picture with matching charactersitics, but do not
*   count one whose release has been deferred.
               IF ( ( CNESPN( CNEST ) .EQ. CPICNM( I ) ) .AND.
     :              ( CNESWK( CNEST ) .EQ. CAGIWK( I ) ) .AND.
     :              ( CDEPS( I ) .EQ. 0 ) ) THEN
                  LPICID = I
               ENDIF
            ENDDO

*   If a matching picture identifier was found then select it
            IF ( LPICID .GT. 0 ) THEN
               CALL AGI_SELP( LPICID, LSTAT )

*   Otherwise indicate this picture is current in the database
            ELSE
               CALL AGI_1WPACT( CNESWK( CNEST ), CNESPN( CNEST ), LSTAT)
            ENDIF
         ENDIF
      ENDIF

*   Release all identifiers at the current nesting level
      DO I = 1, FRELEN
         IF ( CLEVEL( I ) .GT. CNEST ) THEN
            LOSTAT = SAI__OK
            CALL AGI_ANNUL( I, LOSTAT )
            IF ( LOSTAT .NE. SAI__OK ) THEN
               LSTAT = LOSTAT
            ENDIF
         ENDIF
      ENDDO

*   Close the database if the flag is set
      IF ( CLOSEF .AND. ( CNEST .EQ. 1 ) ) THEN

*   First check if the locator is valid
         CALL DAT_VALID( DABLOC, YESNO, LSTAT )

*   If it is then close the database file
         IF ( YESNO ) THEN
            CALL HDS_CLOSE( DABLOC, LSTAT )
            DABLOC = ' '

*   Set database locator valid flag and the database flush flag
            LOCVAL = .FALSE.
            FLUSH = .FALSE.

*   Ensure that the TRANSFORM facility is closed down
            CALL TRN_CLOSE( LSTAT )

*   Clear out cache transformation flags
            DO J = 0, NFIFO - 1
               DO I = 0, FIFLEN - 1
                  CTRFOR( I, J ) = 0
                  CTRINV( I, J ) = 0
               ENDDO
            ENDDO

*   Make sure GNS is shut down for all packages (if relevant)
            CALL AGI1_ENDGNS( LSTAT )
         ENDIF

*   Reset the flag
         CLOSEF = .FALSE.
      ENDIF

*   Return the local status if the global status is zero
      IF ( STATUS .EQ. SAI__OK ) THEN
         STATUS = LSTAT
      ENDIF

*      print*, '+++++ AGI_END +++++'
*      call HDS_SHOW( 'FILES', status )
*      call HDS_SHOW( 'LOCATORS', status )

      END

