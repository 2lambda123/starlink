************************************************************************

      SUBROUTINE AGI_TWTDD ( PICID, NXY, WX, WY, DX, DY, STATUS )

*+
*  Name :
*     AGI_TWTDD
*
*  Purpose :
*     Transform double precision world to data coordinates
*
*  Invocation :
*     CALL AGI_TWTDD( PICID, NXY, WX, WY, DX, DY, STATUS )
*
*  Description :
*     Transform a set of double precision world coordinates into data
*     coordinates using a transformation stored in the database. The
*     picture identifier signifies which picture contains the required
*     transformation structure. If this identifier is negative then
*     the current picture is used. If no transformation structure
*     is found then the identity transformation is used, i.e. the
*     data coordinates equal the world coordinates.
*
*  Arguments :
*     PICID = INTEGER (Given)
*        Picture identifier
*     NXY = INTEGER (Given)
*        Number of data points to transform
*     WX = DBLE(NXY) (Given)
*        Array of x world coordinates
*     WY = DBLE(NXY) (Given)
*        Array of y world coordinates
*     DX = DBLE(NXY) (Returned)
*        Array of x data coordinates
*     DY = DBLE(NXY) (Returned)
*        Array of y data coordinates
*     STATUS = INTEGER (Given and Returned)
*        The global status
*
*  Algorithm :
*     Check the input status and the number of points in the arrays.
*     Obtain the workstation id and picture number from the picturee id.
*     Look in the cache for this picture.
*     If it is in the cache then see if the transformation is compiled.
*     If it is not in the cache or not compiled then
*        Find the picture in the database.
*        Get a locator to the transformation structure.
*        Put the picture contents in the cache if not already there.
*        Compile the transformation.
*        Put the transformation identifier in the cache.
*     Perform the transformation.
*
*  Authors :
*     NE: Nick Eaton (Durham University)
*
*  History :
*     Jun 1991 (NE):
*        Original version
*-
*  Type Definitions :
      IMPLICIT NONE

*  Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'agi_nam'
      INCLUDE 'AGI_PAR'
      INCLUDE 'AGI_ERR'

*  Global variables :
      INCLUDE 'agi_cache'
      INCLUDE 'agi_locs'
      INCLUDE 'agi_pfree'

*  Arguments Given :
      INTEGER PICID
      INTEGER NXY
      DOUBLE PRECISION WX( * )
      DOUBLE PRECISION WY( * )

*  Arguments Returned :
      DOUBLE PRECISION DX( * )
      DOUBLE PRECISION DY( * )

*  Status :
      INTEGER STATUS

*  Local variables :
      LOGICAL BAD, COMPL, FOUND, INCAC, YESNO

      CHARACTER * ( AGI__CMAX ) COMENT
      CHARACTER * ( DAT__SZLOC ) PICLOC, PSTLOC, TRNLOC, WKSLOC
      CHARACTER * ( AGI__SZNAM ) PNAME
      CHARACTER * ( DAT__SZNAM ) WKNAME

      INTEGER I, J, JJ, K, MEMID, PICNUM, POINT, TID

      REAL DEVICE, NDC, WORLD
*.

*   Check input status
      IF ( STATUS .NE. SAI__OK ) THEN
         GOTO 99
      ENDIF

*   Check the number of data points to transform
      IF ( NXY .LE. 0 ) THEN
         STATUS = AGI__TRNIN
         CALL ERR_REP( 'AGI_TWTOD_TRNIN',
     :                 'Invalid number of transformation points',
     :                 STATUS )
         GOTO 99
      ENDIF

*   Initialise the return values with the identity transformation
      DO I = 1, NXY
         DX( I ) = WX( I )
         DY( I ) = WY( I )
      ENDDO

*   Obtain the workstation and picture number from the picture id
*   If PICID is less than 0 then use the current picture
      IF ( PICID .LT. 0 ) THEN
         WKNAME = CAGIWK( CURPID )
         PICNUM = CPICNM( CURPID )

*   Otherwise use the specified picture
      ELSEIF ( ( PICID .GT. 0 ) .AND. ( PICID .LE. FRELEN ) ) THEN
         WKNAME = CAGIWK( PICID )
         PICNUM = CPICNM( PICID )

*   Else the picture identifier is invalid so use the identity transformation
      ELSE
         GOTO 99
      ENDIF

*   Look in the cache for the picture
*   Obtain the FIFO number by hashing the picture number
      K = MOD( PICNUM, NFIFO )

*   Step through the cache members
      INCAC = .FALSE.
      DO J = FIFLEN - 1, 0, -1

*   Start at the most recent entry and work backwards
         JJ = MOD( J + PFIFO( K ) + 1, FIFLEN )

*   If the cache entry matches the given picture jump out of the loop
         IF ( ( FIFO( JJ, K ) .EQ. PICNUM ) .AND.
     :        ( CWKNAM( JJ, K ) .EQ. WKNAME ) ) THEN
            INCAC = .TRUE.
            POINT = JJ
            GOTO 10
         ENDIF
      ENDDO

  10  CONTINUE

*   See if the transformation has been compiled
*   Note: cannot put the test CTRINV.EQ.0 in the following IF statement
*   because in INCAC is false then CTRINV( POINT, K ) will not be defined
      IF ( INCAC ) THEN
         IF ( CTRINV( POINT, K ) .EQ. 0 ) THEN
            COMPL = .FALSE.
         ELSE
            COMPL = .TRUE.
            TID = CTRINV( POINT, K )
         ENDIF
      ENDIF

*   If the picture has not been found in the cache or the transformation
*   has not been compiled then find the transformation in the database
      IF ( ( .NOT. INCAC ) .OR. ( .NOT. COMPL ) ) THEN

*   Get a locator to the required picture
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
     :                            STATUS )
                  CALL DAT_ANNUL( PSTLOC, STATUS )
                  PSTLOC = ' '
               ENDIF
               CALL DAT_ANNUL( WKSLOC, STATUS )
               WKSLOC = ' '
            ENDIF
         ENDIF

*   If the picture was found then find the transformation
         IF ( FOUND ) THEN
            CALL DAT_THERE( PICLOC, AGI__TRANS, FOUND, STATUS )
            IF ( FOUND ) THEN
               TRNLOC = ' '
               CALL DAT_FIND( PICLOC, AGI__TRANS, TRNLOC, STATUS )
            ENDIF

*   If there is no cache entry for this picture then make one now
            IF ( .NOT. INCAC ) THEN
               CALL AGI_1RPARS( PICLOC, PNAME, COMENT, DEVICE, NDC,
     :                          WORLD, MEMID, YESNO, STATUS )
               CALL AGI_1WCACH( WKNAME, PICNUM, PNAME, COMENT, DEVICE,
     :                          NDC, WORLD, MEMID, POINT, STATUS )
            ENDIF

*   Annul the picture locator
            CALL DAT_ANNUL( PICLOC, STATUS )
            PICLOC = ' '
         ENDIF

*   If the transformation has not been found then use the identity transformation
         IF ( .NOT. FOUND ) THEN
            GOTO 99
         ENDIF

*   Compile the transformation
         CALL TRN_COMP( TRNLOC, .FALSE., TID, STATUS )
         CALL DAT_ANNUL( TRNLOC, STATUS )
         TRNLOC = ' '
         IF ( STATUS .NE. SAI__OK ) THEN
            GOTO 99
         ENDIF

*   Store the transformation number in the cache
         CTRINV( POINT, K ) = TID

      ENDIF

*   Now there is a transformation compiled and ready to do work
      BAD = .TRUE.
      CALL TRN_TR2D( BAD, NXY, WX, WY, TID, DX, DY, STATUS )

*   Flush HDS if database file has been updated
      IF ( FLUSH ) THEN
*         CALL HDS_FREE( DABLOC, STATUS )
         FLUSH = .FALSE.
      ENDIF

  99  CONTINUE

*      print*, '+++++ AGI_TWTDD +++++'
*      call HDS_SHOW( 'FILES', status )
*      call HDS_SHOW( 'LOCATORS', status )

      END

