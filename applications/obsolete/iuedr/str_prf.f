      SUBROUTINE str_PRF(RIGHT, FIELD, STR, FIRST, FVALUE, STATUS)

*+
*
*   Name:
*      SUBROUTINE str_PRF
*
*   Description:
*      Grab float value from parameter string using edit parameters.
*
*   History:
*      Jack Giddings      03-JAN-82     IUEDR Vn. 1.0
*      Paul Rees          28-OCT-88     IUEDR Vn. 2.0
*
*   Method:
*      The substring containing a formatted float number is extracted
*      from the string according to the supplied edit parameters.
*      The FIRST parameter is left pointing to the next character
*      after the present field.
*      The actual decoding is done by a seperate routine.
*
*-

*   Implicit:
      IMPLICIT NONE

*   Import:
      LOGICAL RIGHT         ! whether right justified
 
      INTEGER FIELD         ! field size
 
      BYTE STR(100)         ! string to be scanned
 
*   Import/Export:
      BYTE FIRST            ! first character position containing float
 
*   Export:
      REAL*8 FVALUE           ! float value
 
      INTEGER STATUS        ! status return
 
*   External references:
      INTEGER str_INDEX     ! index of character in string
      INTEGER str_LEN       ! string length
 
*   Local variables:
      LOGICAL NOESGN        ! no exponent sign yet
      LOGICAL NOEVAL        ! no exponent value yet
      LOGICAL NOEXP         ! no E, e, D or d yet
      LOGICAL NOPER         ! no period yet
      LOGICAL NOUSED        ! no characters used yet
      LOGICAL NOVAL         ! no numeric value yet
      LOGICAL NOVSGN        ! no value sign yet

      BYTE VALUE(256)       ! local copy of the field
 
      INTEGER DIG           ! character index
      INTEGER FUSED         ! position of first used character
      INTEGER LAST          ! last character position in string
      INTEGER POS           ! character position
      INTEGER USED          ! number of characters used

*   Length of string
      LAST = str_LEN(STR)
 
*   FIELD specified
      IF (FIELD.LE.0) THEN
 
*      FIELD unspecified means must search for valid format
         NOUSED = .TRUE.
         NOVAL = .TRUE.
         NOVSGN = .TRUE.
         NOPER = .TRUE.
         NOEXP = .TRUE.
         STATUS = -3
         USED = 0
         POS = FIRST

 50      CONTINUE

         IF (POS.LE.LAST) THEN

            IF (NOEXP) THEN

               DIG = str_INDEX('0123456789+-.eEdD \\', STR(POS))
               IF (DIG.LE.0) GO TO 200

               IF (NOUSED .AND. STR(POS).NE.32) THEN

                  NOUSED = .FALSE.
                  FUSED = POS

               END IF

               IF (DIG.LE.10) THEN

                  STATUS = 0
                  NOVAL = .FALSE.

               ELSE IF (STR(POS).EQ.43) THEN

                  STATUS = -3
                  IF (.NOT.(NOVSGN .AND. NOPER .AND. NOVAL)) GO TO 200
                  NOVSGN = .FALSE.

               ELSE IF (STR(POS).EQ.45) THEN

                  STATUS = -3
                  IF (.NOT.(NOVSGN .AND. NOPER .AND. NOVAL)) GO TO 200
                  NOVSGN = .FALSE.

               ELSE IF (STR(POS).EQ.46) THEN

                  IF (NOPER) THEN

                     NOPER = .FALSE.

                  ELSE

                     STATUS = -3
                     GO TO 200

                  END IF

               ELSE IF (DIG.GE.13 .AND. DIG.LE.16) THEN

                  STATUS = -3
                  IF (NOVAL) GO TO 200
                  NOEXP = .FALSE.
                  NOEVAL = .TRUE.
                  NOESGN = .TRUE.

               ELSE IF (.NOT.NOVAL) THEN

                  GO TO 200

               END IF

            ELSE

               DIG = str_INDEX('0123456789+- \\', STR(POS))

               IF (DIG.GT.0) THEN

                  IF (DIG.LE.10) THEN

                     STATUS = 0
                     NOEVAL = .FALSE.

                  ELSE IF (STR(POS).EQ.43) THEN

                     STATUS = -3
                     IF (.NOT.(NOEVAL)) GO TO 200
                     IF (.NOT.(NOESGN)) GO TO 200
                     NOESGN = .FALSE.

                  ELSE IF (STR(POS).EQ.45) THEN

                     STATUS = -3
                     IF (.NOT.(NOEVAL)) GO TO 200
                     IF (.NOT.(NOESGN)) GO TO 200
                     NOESGN = .FALSE.

                  ELSE IF (.NOT.NOEVAL) THEN

                     GO TO 200

                  END IF

               ELSE IF (NOEVAL) THEN

                  GO TO 200

               END IF

            END IF

            IF (.NOT.NOUSED) THEN

               USED = USED + 1

            ELSE IF (RIGHT) THEN

               USED = USED + 1

            END IF

            POS = POS + 1
            GO TO 50

         END IF
 
*   Right justified means grab next FIELD characters
      ELSE IF (RIGHT) THEN

         FUSED = FIRST
         POS = FUSED + FIELD - 1

         IF (POS.LE.LAST + 1) THEN

            STATUS = 0

         ELSE

            STATUS = -3

         END IF
 
*   Left justified means find first valid character
      ELSE

         POS = FIRST

 100     CONTINUE

         IF (POS.LE.LAST) THEN

            IF (STR(POS).NE.32 .AND. STR(POS).NE.9) THEN

               IF (str_INDEX('+-0123456789.\\', STR(POS)).EQ.0) THEN

                  STATUS = -3

               ELSE

                  FUSED = POS
                  STATUS = 0

               END IF

               GO TO 200

            END IF

            POS = POS + 1
            GO TO 100

         END IF

      END IF

 200  CONTINUE
 
*   Update FIRST based of number of characters used, field size and
*   justification
      IF (STATUS.EQ.0) THEN

         IF (FIELD.GT.0) THEN

            FIRST = FUSED + FIELD

         ELSE

            FIRST = POS

         END IF

         CALL str_TERM(0, 256, VALUE)
         CALL str_COPY(STR, FUSED, FIRST - 1, 1, 256, VALUE)
         CALL gen_STOF(VALUE, FVALUE, STATUS)

      ELSE

         FVALUE = 0

      END IF

      END
