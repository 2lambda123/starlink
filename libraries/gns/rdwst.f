      SUBROUTINE GNS_1RDWST(ITYPE, STATUS)
*+
*   Routine:
*
*      GNS_1RDWST
*
*   Function:
*
*      Ensure that the GNS comon block is filled in with the data for
*      the specified workstation type.
*
*   Call:
*
*      CALL GNS_1RDWST(ITYPE, STATUS)
*
*   Description:
*
*      The workstation type of the current contents of the common block
*      are compared with the requested type and the common block filled
*      by reading from the description file if necessary.
*
*   Arguments:
*
*      Given:
*       
*         ITYPE   (INTEGER)
*                        GKS workstation type
*       
*      Modified:
*       
*         STATUS  (INTEGER)
*                        Inherited status
*       
*+
*   Libraries Used:
*
*      EMS
*
*   D L Terrett   11-MAY-1989 
*   Nick Eaton     2-APR-1990  Added OPEN keyword
*   Nick Eaton    18-MAY-1990  Added AGI types
*   Nick Eaton     9-JUL-1990  Added error reporting

      IMPLICIT NONE
      INTEGER ITYPE, STATUS

      INCLUDE 'GNS_PAR'
      INCLUDE 'gns.cmn'
      INCLUDE 'GNS_ERR'

*   Workstation currently in common block
      INTEGER ICURWK

      INTEGER NREC, I, NP
      
*   Buffer for record from file
      INTEGER IBUF(RECSIZ)
      REAL RBUF(RECSIZ)
      EQUIVALENCE (IBUF,RBUF)

      DATA ICURWK /-1/
      
      IF (STATUS.EQ.0) THEN

*   If the current workstation does not match the one requested
         IF (ICURWK.NE.ITYPE) THEN

*     Make sure that the database is open
            CALL GNS_1INITG(STATUS)
            IF (STATUS.NE.0) GO TO 9999      

*     Hash the workstation type to get a record number and search the
*     file from that point until we get an empty record or find the
*     workstation we want.
            NREC = MOD(ITYPE*GHASH1,GHASH2)
   10       CONTINUE
            NREC = NREC + 1
            READ (UNIT=LUNGKS ,REC=NREC, ERR=100) IBUF
            IF (IBUF(1).EQ.-2) THEN

*        We read an empty record so the workstation we want isn't in the
*        file so fill the common block with defaults.
               CLASS = 0
               SCALE = 0.0
               OUTPUT = 0
               CLEAR = 0
               LERTXT = 0
               LDEFNA = 0
               IOPEN = 0
               AGITYG = 0
            ELSE  
      
*           If the type doesn't match then read another record
               IF (IBUF(1).NE.ITYPE) GO TO 10

*           We have got the right record so copy the data into the
*           common block.
               CLASS = IBUF(2)
               SCALE = RBUF(3)
               OUTPUT = IBUF(4)
               CLEAR = IBUF(5)
               LERTXT = IBUF(6)
               NP = 6
               DO 20 I=1,LERTXT
                  NP = NP + 1

*              If we have reached the end of the record then read the
*              next one
                  IF (NP.GT.RECSIZ) THEN
                     NREC = NREC + 1
                     READ (UNIT=LUNGKS ,REC=NREC, ERR=100) IBUF

*                 it must be a continuation record
                     IF (IBUF(1).NE.-1) GO TO 110

                     NP = 2
                  END IF

                  ERTXT(I:I) = CHAR(IBUF(NP))
   20          CONTINUE

*           Repeat for the next character item
               NP = NP + 1
               IF (NP.GT.RECSIZ) THEN
                  NREC = NREC + 1
                  READ (UNIT=LUNGKS ,REC=NREC, ERR=100) IBUF
                  IF (IBUF(1).NE.-1) GO TO 110
                  NP = 2
               END IF
               LDEFNA = IBUF(NP)
               DO 30 I=1,LDEFNA
                  NP = NP + 1
                  IF (NP.GT.RECSIZ) THEN
                     NREC = NREC + 1
                     READ (UNIT=LUNGKS ,REC=NREC, ERR=100) IBUF
                     IF (IBUF(1).NE.-1) GO TO 110
                     NP = 2
                  END IF
                  DEFNAM(I:I) = CHAR(IBUF(NP))
   30          CONTINUE                  

*           Repeat for the next item ( IOPEN )
               NP = NP + 1
               IF (NP.GT.RECSIZ) THEN
                  NREC = NREC + 1
                  READ (UNIT=LUNGKS ,REC=NREC, ERR=100) IBUF
                  IF (IBUF(1).NE.-1) GO TO 110
                  NP = 2
               END IF
               IOPEN = IBUF(NP)

*           Repeat for the next item ( AGITYG )
               NP = NP + 1
               IF (NP.GT.RECSIZ) THEN
                  NREC = NREC + 1
                  READ (UNIT=LUNGKS ,REC=NREC, ERR=100) IBUF
                  IF (IBUF(1).NE.-1) GO TO 110
                  NP = 2
               END IF
               AGITYG = IBUF(NP)

            END IF
         END IF
      END IF
      GO TO 9999
      
  100 CONTINUE
      STATUS = GNS__DBRDE
      CALL EMS_REP( 'GNS_1RDWST_DBRE',
     :              'Error while reading the GNS database', STATUS )
      GO TO 9999
  110 CONTINUE
      STATUS = GNS__DBFME
      CALL EMS_REP( 'GNS_1RDWST_DBFE',
     :              'GNS database has invalid format', STATUS )
 9999 CONTINUE            
      END
       
