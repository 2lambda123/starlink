      PROGRAM IOCTEST
C
C   Simple exerciser for the Fortran-callable version of the 
C   ioc_ routines.
C
C   No attempt has been made to make this a Starlink or ADAAM Program.
C
C   KFH RAL 17/1/92
C

      IMPLICIT NONE


      INTEGER SAI__OK
      INTEGER STATUS
      CHARACTER*(20) DEVICE
      INTEGER CHAN
      CHARACTER*(5) ACCESS
      INTEGER BLKSIZ
      INTEGER ACT
      BYTE BUFFER(8192)
      CHARACTER*(3) COMMAND
      CHARACTER*(10) FIRST
      CHARACTER*(10) SECOND
      INTEGER FORWARD
      INTEGER BACKWARD
      INTEGER I
      INTEGER J

      SAI__OK = 0

      FIRST = 'qwerty'
      SECOND = 'uiop'
      FORWARD = 1
      BACKWARD = -1
      
*   Device etc.

      PRINT *, 'Enter device name'
      READ (*, '(A)') DEVICE
*   Operational loop

  100 CONTINUE

      STATUS = SAI__OK
      PRINT *, 'Read, Write, Play, Exit ?'
      READ (*, '(A)') ACCESS
      write (*, '(A, A)') DEVICE, ACCESS

      CALL IOC_OPEN(DEVICE, LEN(DEVICE), ACCESS, LEN(ACCESS), 
     :              CHAN, STATUS)
      PRINT *, 'Status from open is ', STATUS
      IF (STATUS .NE. SAI__OK) GO TO 800

      IF (ACCESS(1:1) .EQ. 'e' .OR. ACCESS(1:1) . EQ. 'E') THEN

         CALL IOC_CLOSE(CHAN, STATUS)
         PRINT *, 'Status from close is ', STATUS
         GO TO 800
      ELSE 

      PRINT *, 'ENTER BLOCK SIZE (<=8192)'
      READ (*, '(I)') BLKSIZ


         IF (ACCESS(1:1) .EQ. 'r' .OR. ACCESS(1:1) . EQ. 'R') THEN

            DO I= 1,12
               STATUS = SAI__OK
               CALL IOC_READ(CHAN, BLKSIZ, BUFFER, ACT, STATUS)
               PRINT *, 'Status from read is ', STATUS
               IF (ACT .EQ. 0) THEN
                  PRINT *, 'Read a tape mark'
               ELSE
                  PRINT *, 'Read ', ACT, ' values, first was ', 
     :                     CHAR(BUFFER(1))
               END IF
            END DO
            CALL IOC_REW(CHAN, STATUS)
            PRINT *, 'Status from rewind is ', STATUS

            CALL IOC_CLOSE (CHAN, STATUS)
            PRINT *, 'Status from close is ', STATUS

         ELSE IF (ACCESS(1:1) .EQ. 'w' .OR. ACCESS(1:1) . EQ. 'W') THEN

            DO I = 1,6
               DO J = 1, BLKSIZ
                  BUFFER(J) = ICHAR ( FIRST(I:I) )
               END DO
               STATUS = SAI__OK
               CALL IOC_WRITE(CHAN, BLKSIZ, BUFFER, ACT, STATUS)
               PRINT *, ACT, ' values written, status is ', STATUS
            END DO
            STATUS = SAI__OK
            CALL IOC_WEOF(CHAN, STATUS)
            PRINT *, 'Status from WEOF is ', STATUS
            DO I = 1,4
               DO J = 1,BLKSIZ
                  BUFFER(J) = ICHAR ( SECOND(I:I) )
               END DO
               STATUS = SAI__OK
               CALL IOC_WRITE(CHAN, BLKSIZ, BUFFER, ACT, STATUS)
               PRINT *, ACT, ' values written, status is ', STATUS
            END DO
            CALL IOC_WEOF(CHAN, STATUS)
            PRINT *, 'Status from WEOF is ', STATUS
            CALL IOC_WEOF(CHAN, STATUS)
            PRINT *, 'Status from WEOF is ', STATUS
            CALL IOC_REW(CHAN, STATUS)
            PRINT *, 'Status from rewind is ', STATUS

            CALL IOC_CLOSE(CHAN, STATUS)
            PRINT *, 'Status from close is ', STATUS

         ELSE

  200       CONTINUE
      
            PRINT *, 'Enter command'
            READ (*,'(A)') COMMAND
            STATUS = SAI__OK

            IF (COMMAND(1:2) .EQ. 'rw') THEN
               CALL IOC_REW(CHAN, STATUS)
               PRINT *, 'Status from rewind is ', STATUS 

            ELSE IF (COMMAND(1:2) .EQ. 're') THEN
               CALL IOC_READ(CHAN, BLKSIZ, BUFFER, ACT, STATUS)
               PRINT *, 'Status from read is ', STATUS
               IF (ACT .EQ. 0) THEN
                  PRINT *, 'Read a tape mark'
               ELSE
                  PRINT *, 'Read ', ACT, ' values, first was ', 
     :                     CHAR(BUFFER(1))
               END IF

            ELSE IF (COMMAND(1:2) .EQ. 'ff') THEN
               CALL IOC_SKIPF(CHAN, FORWARD, STATUS)
               PRINT *,'Status from skip forward file is ',STATUS
  
            ELSE IF (COMMAND(1:2) .EQ. 'bf') THEN
               CALL IOC_SKIPF(CHAN, BACKWARD, STATUS)
               PRINT *, 'Status from skip back file is ', STATUS

            ELSE IF (COMMAND(1:2) .EQ. 'fb') THEN
               CALL IOC_SKIPB(CHAN, FORWARD, STATUS)
               PRINT *,'Status from skip forwad block is ',STATUS

            ELSE IF (COMMAND(1:2) .EQ. 'bb') THEN
               CALL IOC_SKIPB(CHAN, BACKWARD, STATUS)
               PRINT *, 'Status from skip backward block is ', STATUS

            ELSE IF (COMMAND(1:2) .EQ. 'ex') THEN
               GO TO 300

            ELSE
               PRINT *, 'Options are re, rw, ff, bf, fb, bb, ex'
            END IF

            GO TO 200

  300       CONTINUE

            CALL IOC_CLOSE(CHAN, STATUS)
            PRINT *, 'Status from close is ', STATUS

         END IF

         GO TO 100

      END IF

  800 CONTINUE
      END
