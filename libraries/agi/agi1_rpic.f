************************************************************************
*+  AGI_1RPIC - Read the contents of a picture

      SUBROUTINE AGI_1RPIC ( WKNAME, PICNUM, PNAME, COMENT, DEVICE, NDC,
     :                       WORLD, MEMID, FOUND, STATUS )

*    Description :
*     Read the contents of a picture from the cache or the database
*
*    Invocation :
*     CALL AGI_1RPIC( WKNAME, PICNUM, PNAME, COMENT, DEVICE, NDC,
*    :                WORLD, MEMID, FOUND, STATUS )
*
*    Method :
*     Check status on entry.
*     Look in the cache for the picture.
*     If not there look in the database.
*     If not there flag an error.
*
*    Deficiencies :
*     If the picture is found this does not guarantee that all the
*     parameters are properly defined.
*
*    Authors :
*     Nick Eaton  ( DUVAD::NE )
*
*    History :
*     July 1988
*     June 1989  Allow for the extra FIFO's
*     July 1989  Read database locator from common block
*     June 1990  Added MEMID parameter
*    endhistory
*
*    Type Definitions :
      IMPLICIT NONE

*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'AGI_PAR'

*    Import :

*     Name of workstation
      CHARACTER * ( * ) WKNAME

*     Number of picture in array of pictures to be read.
      INTEGER PICNUM

*    Export :

*     Name of picture
      CHARACTER * ( * ) PNAME

*     Description of picture
      CHARACTER * ( * ) COMENT

*     Device coordinates of picture
      REAL DEVICE( 4 )

*     Normalised device coordinates of picture
      REAL NDC( 4 )

*     World coordinates of picture
      REAL WORLD( 4 )

*     Memory identifier
      INTEGER MEMID

*     Flag to indicate if picture was found
      LOGICAL FOUND

*    Status :
      INTEGER STATUS

*    Global variables :
      INCLUDE 'agi_cache'

*    Local variables :
      LOGICAL PFOUND

      INTEGER I, J, JJ, K, POINT

      CHARACTER * ( DAT__SZLOC ) PICLOC, PSTLOC, WKSLOC
*-

      IF ( STATUS .EQ. SAI__OK ) THEN

*   Obtain the FIFO number by hashing the picture number
         K = MOD( PICNUM, NFIFO )

*   Look in the cache first
         FOUND = .FALSE.
         DO J = FIFLEN - 1, 0, -1

*   Start at the most recent entry and work backwards
            JJ = MOD( J + PFIFO( K ) + 1, FIFLEN )

*   If the cache entry matches the given picture jump out of the loop
            IF ( ( FIFO( JJ, K ) .EQ. PICNUM ) .AND.
     :           ( CWKNAM( JJ, K ) .EQ. WKNAME ) ) THEN
               FOUND = .TRUE.
               POINT = JJ
               GOTO 10
            ENDIF
         ENDDO

  10     CONTINUE

*   If it is in the cache then read the contents
         IF ( FOUND ) THEN
            PNAME = CPNAME( POINT, K )
            COMENT = CCOM( POINT, K )
            MEMID = CMEMID( POINT, K )
            DO I = 1, 4
               DEVICE( I ) = CDEV( I, POINT, K )
               NDC( I ) = CNDC( I, POINT, K )
               WORLD( I ) = CWORLD( I, POINT, K )
            ENDDO

*   If it is not in the cache look in the database
         ELSE

*   Check picture structure is present
            CALL AGI_1FDB( FOUND, STATUS )
            IF ( FOUND ) THEN
               WKSLOC = ' '
               CALL AGI_1FWORK( WKNAME, WKSLOC, FOUND, STATUS )
               IF ( FOUND ) THEN
                  PSTLOC = ' '
                  CALL AGI_1FPST( WKSLOC, PSTLOC, FOUND, STATUS )
                  IF ( FOUND ) THEN
                     PICLOC = ' '
                     CALL AGI_1FPIC( PSTLOC, PICNUM, PICLOC, FOUND,
     :                               STATUS )

*   Fill elements with passed parameters
                     IF ( FOUND ) THEN
                        CALL AGI_1RPARS( PICLOC, PNAME, COMENT, DEVICE,
     :                                   NDC, WORLD, MEMID, PFOUND,
     :                                   STATUS )
                        CALL DAT_ANNUL( PICLOC, STATUS )
                        PICLOC = ' '
                     ENDIF
                     CALL DAT_ANNUL( PSTLOC, STATUS )
                     PSTLOC = ' '
                  ENDIF
                  CALL DAT_ANNUL( WKSLOC, STATUS )
                  WKSLOC = ' '
               ENDIF
            ENDIF

*   If the picture was found in the database then put it in the cache
            IF ( FOUND ) THEN
               CALL AGI_1WCACH( WKNAME, PICNUM, PNAME, COMENT, DEVICE,
     :                          NDC, WORLD, MEMID, POINT, STATUS )
            ENDIF

         ENDIF
      ENDIF

*      print*, '+++++ AGI_1RPIC +++++'
*      call HDS_SHOW( 'FILES', status )
*      call HDS_SHOW( 'LOCATORS', status )

      END

