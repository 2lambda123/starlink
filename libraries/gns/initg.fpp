#include <config.h>
      SUBROUTINE gns_1INITG (STATUS)
*++
*   gns_1INITG   Prepares the GKS name database for access
*
*   Description:
*      If the names database has already been loaded then the routine
*      exits immediately with a success status. Otherwise the database
*      file is opened, read into common, and closed.
*
*   Input arguments:
*      STATUS  i                 Inherited status
*
*   Output arguments:
*      STATUS  i                 Status
*
*   Implicit inputs:
*      The contents of the GKS names database file
*
*   Implicit outputs:
*      none
*
*++
*   Libraries Used:
*
*      EMS
*
*   D L Terrett   4-APR-1989 
*   Nick Eaton   17-MAY-1990  Added sequence numbers
*   Nick Eaton    9-JUL-1990  Added error reporting
*   D L Terrett  15-JAN-1991  Move file names to include file + fix LUN logic
*   Nick Eaton   16-MAR-1992  Initialise the connection id arrays
*   D L Terrett  25-JUL-1995  Search for data files
*   Tim Jenness  15-APR-2004  Use autoconf for RECL

      IMPLICIT NONE
      INCLUDE 'GNS_PAR'
      INCLUDE 'gns.cmn'
      INCLUDE 'GNS_ERR'
      INTEGER STATUS
      
      LOGICAL OPEN
      INTEGER NDELS, LREC, IREC(RECSIZ), IOERR
      PARAMETER (LREC = 134, NDELS = 6)
      INTEGER I, J, K, IDEL(NDELS), L, M
      LOGICAL LUNOPN, NMD
      CHARACTER*132 REC
      CHARACTER*6 NODE, LOCNOD
      CHARACTER*64 FNAME, TNAME
      CHARACTER*64 NAMFNG, DEVFNG
      SAVE FNAME, OPEN

*   Size of each record in platform specific units
      INTEGER RECLEN

*   Number of bytes per record unit
      INTEGER BYTEPRU

*   Use autoconf without trying to do variable substitution
#if FC_RECL_UNIT == 1
       PARAMETER ( BYTEPRU = 1 )
#elif FC_RECL_UNIT == 2
       PARAMETER ( BYTEPRU = 2 )
#elif FC_RECL_UNIT == 4
       PARAMETER ( BYTEPRU = 4 )
#else
#  error "Impossible FC_RECL_UNIT"
#endif

      DATA IDEL/NDELS*LREC/

*   Calculate record length in local units
*   We assume we are using variables that are 4 bytes long
      RECLEN = RECSIZ * 4 / BYTEPRU

      IF (STATUS.EQ.0) THEN

*     If the database is not already open
         IF (.NOT.OPEN) THEN

*        Initialise the connection identifier arrays
            NUMCOG = 0
            DO M = 1, MAXIDS
               ICOIDG( M ) = -1
               IWKTYG( M ) = -1
               CDENAG( M ) = ' '
            ENDDO

*        Check that the logical unit number is not already in use
            LUNGKS = LUNGNS
   10       CONTINUE
            INQUIRE(UNIT = LUNGKS, OPENED=LUNOPN)
            IF (LUNOPN) THEN
               LUNGKS = LUNGKS + 1
               GO TO 10
            END IF

*        Open the GNS names file
            CALL GNS_1FNDF('GKS', 'NAMES', NAMFNG)
            OPEN (UNIT=LUNGKS, FILE=NAMFNG, STATUS='OLD',
#ifdef HAVE_F77_OPEN_READONLY
     :           READONLY,
#endif
     :           ERR=100)

*        Get our own node name
            CALL gns_1HOSTN( LOCNOD, L, STATUS)

            I = 1
   20       CONTINUE
            IF (I.GT.MAXNAI+1) GO TO 60
            READ (UNIT=LUNGKS, END=70, FMT='(A)', ERR=110) REC
            IF (I.LE.MAXNAI) THEN

*           Locate the field delimiters. IDEL(J) points to the character
*           after the Jth delimiter; if there is no Jth delimiter
*           IDEL(J) is two greater than the length of REC
               K = 1
               DO 30 J = 1,NDELS
                  IDEL(J) = INDEX (REC(K:),'/') + K
                  IF (IDEL(J).EQ.K) THEN
                     IDEL(J) = LREC
                     GO TO 40
                  END IF
                  K = IDEL(J)
   30          CONTINUE
   40          CONTINUE

*        If there is a "node" field then check it against our own node
*        name
               IF (IDEL(5)-IDEL(4).GT.1) THEN
                  NODE = REC(IDEL(4):IDEL(5)-2)
                  IF (NODE.NE.'      '.AND.NODE.NE.LOCNOD) GO TO 50
               END IF

*        Copy the data from the input record to the common block
               IF (IDEL(1).GT.2) THEN
                  NAMES(I) = REC(:IDEL(1)-2)
               ELSE
                  STATUS = GNS__DBINV
                  CALL EMS_REP( 'GNS_1INITG_DBN1',
     :                          'GNS database file has invalid format',
     :                          STATUS )
                  GO TO 70
               END IF
      
               IF (IDEL(2)-IDEL(1).GT.1) THEN
                  READ (UNIT=REC(IDEL(1):IDEL(2)-2), FMT='(I99)',
     :               IOSTAT=IOERR) ITYPES(I)
                  IF (IOERR.NE.0) THEN
                      STATUS = GNS__DBINV
                      CALL EMS_REP( 'GNS_1INITG_DBN2',
     :                          'GNS database file has invalid format',
     :                          STATUS )
                      GO TO 70
                  END IF
               ELSE
                  STATUS = GNS__DBINV
                  CALL EMS_REP( 'GNS_1INITG_DBN2',
     :                          'GNS database file has invalid format',
     :                          STATUS )
                  GO TO 70
               END IF
      
               IF (IDEL(3)-IDEL(2).GT.1) THEN
                  VMSNAM(I) = REC(IDEL(2):IDEL(3)-2)
               ELSE
                  VMSNAM(I) = ' '
               END IF
      
               IF (IDEL(4)-IDEL(3).GT.1) THEN
                  WSDESC(I) = REC(IDEL(3):IDEL(4)-2)
                  LDESC(I) = IDEL(4) - IDEL(3) - 1
               ELSE
                  LDESC(I) = 0
               END IF

               IF (IDEL(6)-IDEL(5).GT.1) THEN
                  READ (UNIT=REC(IDEL(5):IDEL(6)-2), FMT='(I99)',
     :               IOSTAT=IOERR) ISEQNG(I)
                  IF (IOERR.NE.0) ISEQNG(I) = 0
               ELSE
                  ISEQNG(I) = 0
               END IF
            END IF
            I = I + 1
   50       CONTINUE
            GO TO 20

*        If we get to here then there are more records in the file than
*        space in the common block
   60       CONTINUE
            STATUS = GNS__DBOVF
            CALL EMS_REP( 'GNS_1INITG_DBOV',
     :                   'Too many workstation names have been defined',
     :                    STATUS )

   70       CONTINUE
            CLOSE (UNIT=LUNGKS)
            NUMNAM = I - 1
            OPEN = .TRUE.
         END IF

         IF (STATUS.EQ.0) THEN

*        Check the state of the logical unit
            INQUIRE (UNIT=LUNGKS, OPENED=LUNOPN, NAMED=NMD, NAME=TNAME)

            IF (.NOT.LUNOPN .OR. .NOT.NMD .OR. TNAME.NE.FNAME) THEN

*           if the logical unit was in use then we have to search for a
*           free unit
   80          CONTINUE
               IF (LUNOPN) THEN
                  LUNGKS = LUNGKS + 1
                  INQUIRE (UNIT=LUNGKS, OPENED=LUNOPN)
                  GO TO 80
               END IF
         
*           Open the workstation description file
               CALL GNS_1FNDF('GKS', 'DEVICES', DEVFNG)
               OPEN (UNIT=LUNGKS, FILE=DEVFNG, STATUS='OLD', 
     :              RECL=RECLEN,
#ifdef HAVE_F77_OPEN_READONLY
     :              READONLY,
#endif
     :              ACCESS='DIRECT', 
     :               FORM='UNFORMATTED', ERR=100)

*           Save the file name returned by INQUIRE
               INQUIRE (UNIT=LUNGKS, NAME=FNAME)

*           Read the first record to check the version number and find the
*           constants used in the hashing algorithm
               READ (UNIT=LUNGKS, REC=1, ERR=110) IREC
               IF (IREC(1).GT.1) THEN
                  STATUS = GNS__VNSUP
                  CALL EMS_REP( 'GNS_1INITG_VNSP',
     :                         'Description file version not supported',
     :                          STATUS )
               ELSE
                  GHASH1 = IREC(2)
                  GHASH2 = IREC(3)
               END IF

            END IF
         END IF
      END IF
      GO TO 999

  100 CONTINUE
      STATUS = GNS__DBOPE
      CALL EMS_REP( 'GNS_1INITG_DBOP',
     :              'Unable to open GNS database file', STATUS )
      GO TO 999
  110 CONTINUE
      STATUS = GNS__DBINV
      CALL EMS_REP( 'GNS_1INITG_DBN3',
     :              'GNS database file has invalid format', STATUS )
      CLOSE (UNIT=LUNGKS)
  999 CONTINUE
      END       
