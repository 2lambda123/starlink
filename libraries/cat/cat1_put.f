      SUBROUTINE CAT1_PUTB (BVALUE, STRING, IPOSN)
*+
*  Name:
*     CAT1_PUTB
*  Purpose:
*     Put a value of type BYTE into a string at a given position.
*  Language:
*     Starlink Fortran 77
*  Invocation:
*     CALL CAT1_PUTB (BVALUE; STRING, IPOSN)
*  Description:
*     Put a value of type BYTE into a string at a given position.
*     The value is appended to the string beginning at position IPOSN+1.
*     IPOSN is updated to indicate the last element of STRING after the 
*     insertion.  If no copying is done, IPOSN is returned unchanged. The
*     size of STRING is based on the declared Fortran 77 size given by
*     the intrinsic function LEN.
*  Arguments:
*     BVALUE  =  BYTE (Given)
*        The value to be appended to the given string.
*     STRING  =  CHARACTER*(*) (Given and Returned)
*        The string into which the given value is to be appended.
*     IPOSN  =  INTEGER (Given and Returned)
*        The position pointer within STRING.
*  Method:
*     Determine the declared size of the output string.
*     If there is space remaining in the string then
*       Copy the given value to the local variable.
*       If the data type is CHARACTER then
*         Append the given string to the output string, checking for
*         truncation.
*       else if the data type is LOGICAL then
*         Append 'T' or 'F' to the string, as appropriate.
*         Update the counter for the last non-blank element.
*       else (the data type corresponds to a numeric type)
*         If the data type is one of: unsigned byte, byte, unsigned
*         word or word then
*           Convert the given value to data type INTEGER.
*           Convert the given value from INTEGER to CHARACTER.
*         else
*           Convert the given value to CHARACTER.
*         end if
*         Append the new character string to the return string,
*         checking for truncation.
*       end if
*     end if
*  Implementation Deficiencies:
*     Only supports the following data types: BYTE, WORD, INTEGER,
*     REAL, DOUBLE PRECISION, LOGICAL, CHARACTER.
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     JRG: Jack Giddings (UCL)
*     ACD: A.C. Davenhall (ROE, Leicester)
*     AJC: A.J. Chipperfield (STARLINK)
*  History:
*     3-JAN-1983 (JRG):
*        Original version.
*     2-OCT-1984 (ACD):
*        Documenation improved.
*     13-SEP-1988 (AJC):
*        Documentation improved.
*     24-FEB-1989 (AJC):
*        Check on string sizes.
*     14-SEP-1994 (ACD):
*        Created a generic routine from CHR_PUTC, CHR_PUTL and the
*        corresponding numeric routines.
*     24-OCT-1994 (ACD):
*        Fixed bug in doing logical syntax IF tests on LOGICAL variables
*        which the Alpha compiler objected to.
*     14-FEB-1996 (ACD):
*        Fixed various features which were technically illegal.
*  Bugs:
*     None known.
*-
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
*  Arguments Given:
      BYTE
     :  BVALUE
*  Arguments Given and Returned:
      CHARACTER
     :  STRING*(*)
      INTEGER
     :  IPOSN
*  Local Constants:
      INTEGER SZSTR1    ! Size of internal character string STR1.
      PARAMETER (SZSTR1 = 80)
*  Local Variables:
      CHARACTER
     :  STR1*(SZSTR1),  ! Internal character string for converted value.
     :  CURTYP*2  ! Code for the current data type.
      INTEGER
     :  LSTR1,    ! Size of STR1 (excl. trail. blanks).
     :  WKVALI,   ! INTEGER copy of given value.
     :  STRNGS    ! Declared size of STRING.

*
*    Local copies of the given value, one per data type.

      BYTE             BLVAL
      INTEGER*2        WLVAL
      INTEGER          ILVAL
      REAL             RLVAL
      DOUBLE PRECISION DLVAL
      LOGICAL          LLVAL
      CHARACTER        CLVAL*(CAT__SZVAL)
*.

      BLVAL = 0
      WLVAL = 0
      ILVAL = 0
      RLVAL = 0.0E0
      DLVAL = 0.0D0
      LLVAL = .FALSE.
      CLVAL = ' '

*
*    Determine the declared size of the output string and proceed if 
*    there is any space remaining at the end of it.

      STRNGS = LEN(STRING)

      IF (IPOSN .LT. STRNGS) THEN

*
*       Copy the given value to the local variable.

         BLVAL = BVALUE

*
*       Get the data type of the current subroutine.

         CURTYP = 'B'

*
*       Check for data type CHARACTER.

         IF (CURTYP .EQ. 'C') THEN

*
*          Append the given string to the output string, checking for
*          truncation.

            CALL CAT1_APPND (CLVAL, STRING, IPOSN)

*
*       Check for data type CHARACTER.

         ELSE IF (CURTYP .EQ. 'L') THEN

*
*          Update the counter for the last non-blank element and append
*          'T' or 'F' to the string, as appropriate.

            IPOSN = IPOSN + 1

            IF (LLVAL) THEN
               STRING(IPOSN : IPOSN) = 'T'
            ELSE
               STRING(IPOSN : IPOSN) = 'F'
            END IF

*
*       The value must be one of the numeric data types.

         ELSE

*
*          If the data type is one of: byte, or word then convert the
*          given value to INTEGER and convert the value from INTEGER to
*          CHARACTER.  Otherwise convert the given value directly to
*          CHARACTER.

            STR1 = ' '
            LSTR1 = 0

            IF (CURTYP .EQ. 'B') THEN
               WKVALI = BLVAL
               CALL CHR_ITOC (WKVALI, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'W') THEN
               WKVALI = WLVAL
               CALL CHR_ITOC (WKVALI, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'I') THEN
               CALL CHR_ITOC (ILVAL, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'R') THEN
               CALL CHR_RTOC (RLVAL, STR1, LSTR1)
            ELSE
               CALL CHR_DTOC (DLVAL, STR1, LSTR1)
            END IF

*
*          Append the new character string to the return string,
*          checking for truncation.

            CALL CAT1_APPND (STR1(1 : LSTR1), STRING, IPOSN)
         END IF
      END IF

      END
      SUBROUTINE CAT1_PUTC (CVALUE, STRING, IPOSN)
*+
*  Name:
*     CAT1_PUTC
*  Purpose:
*     Put a value of type CHARACTER*(*) into a string at a given position.
*  Language:
*     Starlink Fortran 77
*  Invocation:
*     CALL CAT1_PUTC (CVALUE; STRING, IPOSN)
*  Description:
*     Put a value of type CHARACTER*(*) into a string at a given position.
*     The value is appended to the string beginning at position IPOSN+1.
*     IPOSN is updated to indicate the last element of STRING after the 
*     insertion.  If no copying is done, IPOSN is returned unchanged. The
*     size of STRING is based on the declared Fortran 77 size given by
*     the intrinsic function LEN.
*  Arguments:
*     CVALUE  =  CHARACTER*(*) (Given)
*        The value to be appended to the given string.
*     STRING  =  CHARACTER*(*) (Given and Returned)
*        The string into which the given value is to be appended.
*     IPOSN  =  INTEGER (Given and Returned)
*        The position pointer within STRING.
*  Method:
*     Determine the declared size of the output string.
*     If there is space remaining in the string then
*       Copy the given value to the local variable.
*       If the data type is CHARACTER then
*         Append the given string to the output string, checking for
*         truncation.
*       else if the data type is LOGICAL then
*         Append 'T' or 'F' to the string, as appropriate.
*         Update the counter for the last non-blank element.
*       else (the data type corresponds to a numeric type)
*         If the data type is one of: unsigned byte, byte, unsigned
*         word or word then
*           Convert the given value to data type INTEGER.
*           Convert the given value from INTEGER to CHARACTER.
*         else
*           Convert the given value to CHARACTER.
*         end if
*         Append the new character string to the return string,
*         checking for truncation.
*       end if
*     end if
*  Implementation Deficiencies:
*     Only supports the following data types: BYTE, WORD, INTEGER,
*     REAL, DOUBLE PRECISION, LOGICAL, CHARACTER.
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     JRG: Jack Giddings (UCL)
*     ACD: A.C. Davenhall (ROE, Leicester)
*     AJC: A.J. Chipperfield (STARLINK)
*  History:
*     3-JAN-1983 (JRG):
*        Original version.
*     2-OCT-1984 (ACD):
*        Documenation improved.
*     13-SEP-1988 (AJC):
*        Documentation improved.
*     24-FEB-1989 (AJC):
*        Check on string sizes.
*     14-SEP-1994 (ACD):
*        Created a generic routine from CHR_PUTC, CHR_PUTL and the
*        corresponding numeric routines.
*     24-OCT-1994 (ACD):
*        Fixed bug in doing logical syntax IF tests on LOGICAL variables
*        which the Alpha compiler objected to.
*     14-FEB-1996 (ACD):
*        Fixed various features which were technically illegal.
*  Bugs:
*     None known.
*-
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
*  Arguments Given:
      CHARACTER*(*)
     :  CVALUE
*  Arguments Given and Returned:
      CHARACTER
     :  STRING*(*)
      INTEGER
     :  IPOSN
*  Local Constants:
      INTEGER SZSTR1    ! Size of internal character string STR1.
      PARAMETER (SZSTR1 = 80)
*  Local Variables:
      CHARACTER
     :  STR1*(SZSTR1),  ! Internal character string for converted value.
     :  CURTYP*2  ! Code for the current data type.
      INTEGER
     :  LSTR1,    ! Size of STR1 (excl. trail. blanks).
     :  WKVALI,   ! INTEGER copy of given value.
     :  STRNGS    ! Declared size of STRING.

*
*    Local copies of the given value, one per data type.

      BYTE             BLVAL
      INTEGER*2        WLVAL
      INTEGER          ILVAL
      REAL             RLVAL
      DOUBLE PRECISION DLVAL
      LOGICAL          LLVAL
      CHARACTER        CLVAL*(CAT__SZVAL)
*.

      BLVAL = 0
      WLVAL = 0
      ILVAL = 0
      RLVAL = 0.0E0
      DLVAL = 0.0D0
      LLVAL = .FALSE.
      CLVAL = ' '

*
*    Determine the declared size of the output string and proceed if 
*    there is any space remaining at the end of it.

      STRNGS = LEN(STRING)

      IF (IPOSN .LT. STRNGS) THEN

*
*       Copy the given value to the local variable.

         CLVAL = CVALUE

*
*       Get the data type of the current subroutine.

         CURTYP = 'C'

*
*       Check for data type CHARACTER.

         IF (CURTYP .EQ. 'C') THEN

*
*          Append the given string to the output string, checking for
*          truncation.

            CALL CAT1_APPND (CLVAL, STRING, IPOSN)

*
*       Check for data type CHARACTER.

         ELSE IF (CURTYP .EQ. 'L') THEN

*
*          Update the counter for the last non-blank element and append
*          'T' or 'F' to the string, as appropriate.

            IPOSN = IPOSN + 1

            IF (LLVAL) THEN
               STRING(IPOSN : IPOSN) = 'T'
            ELSE
               STRING(IPOSN : IPOSN) = 'F'
            END IF

*
*       The value must be one of the numeric data types.

         ELSE

*
*          If the data type is one of: byte, or word then convert the
*          given value to INTEGER and convert the value from INTEGER to
*          CHARACTER.  Otherwise convert the given value directly to
*          CHARACTER.

            STR1 = ' '
            LSTR1 = 0

            IF (CURTYP .EQ. 'B') THEN
               WKVALI = BLVAL
               CALL CHR_ITOC (WKVALI, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'W') THEN
               WKVALI = WLVAL
               CALL CHR_ITOC (WKVALI, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'I') THEN
               CALL CHR_ITOC (ILVAL, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'R') THEN
               CALL CHR_RTOC (RLVAL, STR1, LSTR1)
            ELSE
               CALL CHR_DTOC (DLVAL, STR1, LSTR1)
            END IF

*
*          Append the new character string to the return string,
*          checking for truncation.

            CALL CAT1_APPND (STR1(1 : LSTR1), STRING, IPOSN)
         END IF
      END IF

      END
      SUBROUTINE CAT1_PUTD (DVALUE, STRING, IPOSN)
*+
*  Name:
*     CAT1_PUTD
*  Purpose:
*     Put a value of type DOUBLE PRECISION into a string at a given position.
*  Language:
*     Starlink Fortran 77
*  Invocation:
*     CALL CAT1_PUTD (DVALUE; STRING, IPOSN)
*  Description:
*     Put a value of type DOUBLE PRECISION into a string at a given position.
*     The value is appended to the string beginning at position IPOSN+1.
*     IPOSN is updated to indicate the last element of STRING after the 
*     insertion.  If no copying is done, IPOSN is returned unchanged. The
*     size of STRING is based on the declared Fortran 77 size given by
*     the intrinsic function LEN.
*  Arguments:
*     DVALUE  =  DOUBLE PRECISION (Given)
*        The value to be appended to the given string.
*     STRING  =  CHARACTER*(*) (Given and Returned)
*        The string into which the given value is to be appended.
*     IPOSN  =  INTEGER (Given and Returned)
*        The position pointer within STRING.
*  Method:
*     Determine the declared size of the output string.
*     If there is space remaining in the string then
*       Copy the given value to the local variable.
*       If the data type is CHARACTER then
*         Append the given string to the output string, checking for
*         truncation.
*       else if the data type is LOGICAL then
*         Append 'T' or 'F' to the string, as appropriate.
*         Update the counter for the last non-blank element.
*       else (the data type corresponds to a numeric type)
*         If the data type is one of: unsigned byte, byte, unsigned
*         word or word then
*           Convert the given value to data type INTEGER.
*           Convert the given value from INTEGER to CHARACTER.
*         else
*           Convert the given value to CHARACTER.
*         end if
*         Append the new character string to the return string,
*         checking for truncation.
*       end if
*     end if
*  Implementation Deficiencies:
*     Only supports the following data types: BYTE, WORD, INTEGER,
*     REAL, DOUBLE PRECISION, LOGICAL, CHARACTER.
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     JRG: Jack Giddings (UCL)
*     ACD: A.C. Davenhall (ROE, Leicester)
*     AJC: A.J. Chipperfield (STARLINK)
*  History:
*     3-JAN-1983 (JRG):
*        Original version.
*     2-OCT-1984 (ACD):
*        Documenation improved.
*     13-SEP-1988 (AJC):
*        Documentation improved.
*     24-FEB-1989 (AJC):
*        Check on string sizes.
*     14-SEP-1994 (ACD):
*        Created a generic routine from CHR_PUTC, CHR_PUTL and the
*        corresponding numeric routines.
*     24-OCT-1994 (ACD):
*        Fixed bug in doing logical syntax IF tests on LOGICAL variables
*        which the Alpha compiler objected to.
*     14-FEB-1996 (ACD):
*        Fixed various features which were technically illegal.
*  Bugs:
*     None known.
*-
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
*  Arguments Given:
      DOUBLE PRECISION
     :  DVALUE
*  Arguments Given and Returned:
      CHARACTER
     :  STRING*(*)
      INTEGER
     :  IPOSN
*  Local Constants:
      INTEGER SZSTR1    ! Size of internal character string STR1.
      PARAMETER (SZSTR1 = 80)
*  Local Variables:
      CHARACTER
     :  STR1*(SZSTR1),  ! Internal character string for converted value.
     :  CURTYP*2  ! Code for the current data type.
      INTEGER
     :  LSTR1,    ! Size of STR1 (excl. trail. blanks).
     :  WKVALI,   ! INTEGER copy of given value.
     :  STRNGS    ! Declared size of STRING.

*
*    Local copies of the given value, one per data type.

      BYTE             BLVAL
      INTEGER*2        WLVAL
      INTEGER          ILVAL
      REAL             RLVAL
      DOUBLE PRECISION DLVAL
      LOGICAL          LLVAL
      CHARACTER        CLVAL*(CAT__SZVAL)
*.

      BLVAL = 0
      WLVAL = 0
      ILVAL = 0
      RLVAL = 0.0E0
      DLVAL = 0.0D0
      LLVAL = .FALSE.
      CLVAL = ' '

*
*    Determine the declared size of the output string and proceed if 
*    there is any space remaining at the end of it.

      STRNGS = LEN(STRING)

      IF (IPOSN .LT. STRNGS) THEN

*
*       Copy the given value to the local variable.

         DLVAL = DVALUE

*
*       Get the data type of the current subroutine.

         CURTYP = 'D'

*
*       Check for data type CHARACTER.

         IF (CURTYP .EQ. 'C') THEN

*
*          Append the given string to the output string, checking for
*          truncation.

            CALL CAT1_APPND (CLVAL, STRING, IPOSN)

*
*       Check for data type CHARACTER.

         ELSE IF (CURTYP .EQ. 'L') THEN

*
*          Update the counter for the last non-blank element and append
*          'T' or 'F' to the string, as appropriate.

            IPOSN = IPOSN + 1

            IF (LLVAL) THEN
               STRING(IPOSN : IPOSN) = 'T'
            ELSE
               STRING(IPOSN : IPOSN) = 'F'
            END IF

*
*       The value must be one of the numeric data types.

         ELSE

*
*          If the data type is one of: byte, or word then convert the
*          given value to INTEGER and convert the value from INTEGER to
*          CHARACTER.  Otherwise convert the given value directly to
*          CHARACTER.

            STR1 = ' '
            LSTR1 = 0

            IF (CURTYP .EQ. 'B') THEN
               WKVALI = BLVAL
               CALL CHR_ITOC (WKVALI, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'W') THEN
               WKVALI = WLVAL
               CALL CHR_ITOC (WKVALI, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'I') THEN
               CALL CHR_ITOC (ILVAL, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'R') THEN
               CALL CHR_RTOC (RLVAL, STR1, LSTR1)
            ELSE
               CALL CHR_DTOC (DLVAL, STR1, LSTR1)
            END IF

*
*          Append the new character string to the return string,
*          checking for truncation.

            CALL CAT1_APPND (STR1(1 : LSTR1), STRING, IPOSN)
         END IF
      END IF

      END
      SUBROUTINE CAT1_PUTI (IVALUE, STRING, IPOSN)
*+
*  Name:
*     CAT1_PUTI
*  Purpose:
*     Put a value of type INTEGER into a string at a given position.
*  Language:
*     Starlink Fortran 77
*  Invocation:
*     CALL CAT1_PUTI (IVALUE; STRING, IPOSN)
*  Description:
*     Put a value of type INTEGER into a string at a given position.
*     The value is appended to the string beginning at position IPOSN+1.
*     IPOSN is updated to indicate the last element of STRING after the 
*     insertion.  If no copying is done, IPOSN is returned unchanged. The
*     size of STRING is based on the declared Fortran 77 size given by
*     the intrinsic function LEN.
*  Arguments:
*     IVALUE  =  INTEGER (Given)
*        The value to be appended to the given string.
*     STRING  =  CHARACTER*(*) (Given and Returned)
*        The string into which the given value is to be appended.
*     IPOSN  =  INTEGER (Given and Returned)
*        The position pointer within STRING.
*  Method:
*     Determine the declared size of the output string.
*     If there is space remaining in the string then
*       Copy the given value to the local variable.
*       If the data type is CHARACTER then
*         Append the given string to the output string, checking for
*         truncation.
*       else if the data type is LOGICAL then
*         Append 'T' or 'F' to the string, as appropriate.
*         Update the counter for the last non-blank element.
*       else (the data type corresponds to a numeric type)
*         If the data type is one of: unsigned byte, byte, unsigned
*         word or word then
*           Convert the given value to data type INTEGER.
*           Convert the given value from INTEGER to CHARACTER.
*         else
*           Convert the given value to CHARACTER.
*         end if
*         Append the new character string to the return string,
*         checking for truncation.
*       end if
*     end if
*  Implementation Deficiencies:
*     Only supports the following data types: BYTE, WORD, INTEGER,
*     REAL, DOUBLE PRECISION, LOGICAL, CHARACTER.
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     JRG: Jack Giddings (UCL)
*     ACD: A.C. Davenhall (ROE, Leicester)
*     AJC: A.J. Chipperfield (STARLINK)
*  History:
*     3-JAN-1983 (JRG):
*        Original version.
*     2-OCT-1984 (ACD):
*        Documenation improved.
*     13-SEP-1988 (AJC):
*        Documentation improved.
*     24-FEB-1989 (AJC):
*        Check on string sizes.
*     14-SEP-1994 (ACD):
*        Created a generic routine from CHR_PUTC, CHR_PUTL and the
*        corresponding numeric routines.
*     24-OCT-1994 (ACD):
*        Fixed bug in doing logical syntax IF tests on LOGICAL variables
*        which the Alpha compiler objected to.
*     14-FEB-1996 (ACD):
*        Fixed various features which were technically illegal.
*  Bugs:
*     None known.
*-
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
*  Arguments Given:
      INTEGER
     :  IVALUE
*  Arguments Given and Returned:
      CHARACTER
     :  STRING*(*)
      INTEGER
     :  IPOSN
*  Local Constants:
      INTEGER SZSTR1    ! Size of internal character string STR1.
      PARAMETER (SZSTR1 = 80)
*  Local Variables:
      CHARACTER
     :  STR1*(SZSTR1),  ! Internal character string for converted value.
     :  CURTYP*2  ! Code for the current data type.
      INTEGER
     :  LSTR1,    ! Size of STR1 (excl. trail. blanks).
     :  WKVALI,   ! INTEGER copy of given value.
     :  STRNGS    ! Declared size of STRING.

*
*    Local copies of the given value, one per data type.

      BYTE             BLVAL
      INTEGER*2        WLVAL
      INTEGER          ILVAL
      REAL             RLVAL
      DOUBLE PRECISION DLVAL
      LOGICAL          LLVAL
      CHARACTER        CLVAL*(CAT__SZVAL)
*.

      BLVAL = 0
      WLVAL = 0
      ILVAL = 0
      RLVAL = 0.0E0
      DLVAL = 0.0D0
      LLVAL = .FALSE.
      CLVAL = ' '

*
*    Determine the declared size of the output string and proceed if 
*    there is any space remaining at the end of it.

      STRNGS = LEN(STRING)

      IF (IPOSN .LT. STRNGS) THEN

*
*       Copy the given value to the local variable.

         ILVAL = IVALUE

*
*       Get the data type of the current subroutine.

         CURTYP = 'I'

*
*       Check for data type CHARACTER.

         IF (CURTYP .EQ. 'C') THEN

*
*          Append the given string to the output string, checking for
*          truncation.

            CALL CAT1_APPND (CLVAL, STRING, IPOSN)

*
*       Check for data type CHARACTER.

         ELSE IF (CURTYP .EQ. 'L') THEN

*
*          Update the counter for the last non-blank element and append
*          'T' or 'F' to the string, as appropriate.

            IPOSN = IPOSN + 1

            IF (LLVAL) THEN
               STRING(IPOSN : IPOSN) = 'T'
            ELSE
               STRING(IPOSN : IPOSN) = 'F'
            END IF

*
*       The value must be one of the numeric data types.

         ELSE

*
*          If the data type is one of: byte, or word then convert the
*          given value to INTEGER and convert the value from INTEGER to
*          CHARACTER.  Otherwise convert the given value directly to
*          CHARACTER.

            STR1 = ' '
            LSTR1 = 0

            IF (CURTYP .EQ. 'B') THEN
               WKVALI = BLVAL
               CALL CHR_ITOC (WKVALI, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'W') THEN
               WKVALI = WLVAL
               CALL CHR_ITOC (WKVALI, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'I') THEN
               CALL CHR_ITOC (ILVAL, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'R') THEN
               CALL CHR_RTOC (RLVAL, STR1, LSTR1)
            ELSE
               CALL CHR_DTOC (DLVAL, STR1, LSTR1)
            END IF

*
*          Append the new character string to the return string,
*          checking for truncation.

            CALL CAT1_APPND (STR1(1 : LSTR1), STRING, IPOSN)
         END IF
      END IF

      END
      SUBROUTINE CAT1_PUTL (LVALUE, STRING, IPOSN)
*+
*  Name:
*     CAT1_PUTL
*  Purpose:
*     Put a value of type LOGICAL into a string at a given position.
*  Language:
*     Starlink Fortran 77
*  Invocation:
*     CALL CAT1_PUTL (LVALUE; STRING, IPOSN)
*  Description:
*     Put a value of type LOGICAL into a string at a given position.
*     The value is appended to the string beginning at position IPOSN+1.
*     IPOSN is updated to indicate the last element of STRING after the 
*     insertion.  If no copying is done, IPOSN is returned unchanged. The
*     size of STRING is based on the declared Fortran 77 size given by
*     the intrinsic function LEN.
*  Arguments:
*     LVALUE  =  LOGICAL (Given)
*        The value to be appended to the given string.
*     STRING  =  CHARACTER*(*) (Given and Returned)
*        The string into which the given value is to be appended.
*     IPOSN  =  INTEGER (Given and Returned)
*        The position pointer within STRING.
*  Method:
*     Determine the declared size of the output string.
*     If there is space remaining in the string then
*       Copy the given value to the local variable.
*       If the data type is CHARACTER then
*         Append the given string to the output string, checking for
*         truncation.
*       else if the data type is LOGICAL then
*         Append 'T' or 'F' to the string, as appropriate.
*         Update the counter for the last non-blank element.
*       else (the data type corresponds to a numeric type)
*         If the data type is one of: unsigned byte, byte, unsigned
*         word or word then
*           Convert the given value to data type INTEGER.
*           Convert the given value from INTEGER to CHARACTER.
*         else
*           Convert the given value to CHARACTER.
*         end if
*         Append the new character string to the return string,
*         checking for truncation.
*       end if
*     end if
*  Implementation Deficiencies:
*     Only supports the following data types: BYTE, WORD, INTEGER,
*     REAL, DOUBLE PRECISION, LOGICAL, CHARACTER.
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     JRG: Jack Giddings (UCL)
*     ACD: A.C. Davenhall (ROE, Leicester)
*     AJC: A.J. Chipperfield (STARLINK)
*  History:
*     3-JAN-1983 (JRG):
*        Original version.
*     2-OCT-1984 (ACD):
*        Documenation improved.
*     13-SEP-1988 (AJC):
*        Documentation improved.
*     24-FEB-1989 (AJC):
*        Check on string sizes.
*     14-SEP-1994 (ACD):
*        Created a generic routine from CHR_PUTC, CHR_PUTL and the
*        corresponding numeric routines.
*     24-OCT-1994 (ACD):
*        Fixed bug in doing logical syntax IF tests on LOGICAL variables
*        which the Alpha compiler objected to.
*     14-FEB-1996 (ACD):
*        Fixed various features which were technically illegal.
*  Bugs:
*     None known.
*-
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
*  Arguments Given:
      LOGICAL
     :  LVALUE
*  Arguments Given and Returned:
      CHARACTER
     :  STRING*(*)
      INTEGER
     :  IPOSN
*  Local Constants:
      INTEGER SZSTR1    ! Size of internal character string STR1.
      PARAMETER (SZSTR1 = 80)
*  Local Variables:
      CHARACTER
     :  STR1*(SZSTR1),  ! Internal character string for converted value.
     :  CURTYP*2  ! Code for the current data type.
      INTEGER
     :  LSTR1,    ! Size of STR1 (excl. trail. blanks).
     :  WKVALI,   ! INTEGER copy of given value.
     :  STRNGS    ! Declared size of STRING.

*
*    Local copies of the given value, one per data type.

      BYTE             BLVAL
      INTEGER*2        WLVAL
      INTEGER          ILVAL
      REAL             RLVAL
      DOUBLE PRECISION DLVAL
      LOGICAL          LLVAL
      CHARACTER        CLVAL*(CAT__SZVAL)
*.

      BLVAL = 0
      WLVAL = 0
      ILVAL = 0
      RLVAL = 0.0E0
      DLVAL = 0.0D0
      LLVAL = .FALSE.
      CLVAL = ' '

*
*    Determine the declared size of the output string and proceed if 
*    there is any space remaining at the end of it.

      STRNGS = LEN(STRING)

      IF (IPOSN .LT. STRNGS) THEN

*
*       Copy the given value to the local variable.

         LLVAL = LVALUE

*
*       Get the data type of the current subroutine.

         CURTYP = 'L'

*
*       Check for data type CHARACTER.

         IF (CURTYP .EQ. 'C') THEN

*
*          Append the given string to the output string, checking for
*          truncation.

            CALL CAT1_APPND (CLVAL, STRING, IPOSN)

*
*       Check for data type CHARACTER.

         ELSE IF (CURTYP .EQ. 'L') THEN

*
*          Update the counter for the last non-blank element and append
*          'T' or 'F' to the string, as appropriate.

            IPOSN = IPOSN + 1

            IF (LLVAL) THEN
               STRING(IPOSN : IPOSN) = 'T'
            ELSE
               STRING(IPOSN : IPOSN) = 'F'
            END IF

*
*       The value must be one of the numeric data types.

         ELSE

*
*          If the data type is one of: byte, or word then convert the
*          given value to INTEGER and convert the value from INTEGER to
*          CHARACTER.  Otherwise convert the given value directly to
*          CHARACTER.

            STR1 = ' '
            LSTR1 = 0

            IF (CURTYP .EQ. 'B') THEN
               WKVALI = BLVAL
               CALL CHR_ITOC (WKVALI, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'W') THEN
               WKVALI = WLVAL
               CALL CHR_ITOC (WKVALI, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'I') THEN
               CALL CHR_ITOC (ILVAL, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'R') THEN
               CALL CHR_RTOC (RLVAL, STR1, LSTR1)
            ELSE
               CALL CHR_DTOC (DLVAL, STR1, LSTR1)
            END IF

*
*          Append the new character string to the return string,
*          checking for truncation.

            CALL CAT1_APPND (STR1(1 : LSTR1), STRING, IPOSN)
         END IF
      END IF

      END
      SUBROUTINE CAT1_PUTR (RVALUE, STRING, IPOSN)
*+
*  Name:
*     CAT1_PUTR
*  Purpose:
*     Put a value of type REAL into a string at a given position.
*  Language:
*     Starlink Fortran 77
*  Invocation:
*     CALL CAT1_PUTR (RVALUE; STRING, IPOSN)
*  Description:
*     Put a value of type REAL into a string at a given position.
*     The value is appended to the string beginning at position IPOSN+1.
*     IPOSN is updated to indicate the last element of STRING after the 
*     insertion.  If no copying is done, IPOSN is returned unchanged. The
*     size of STRING is based on the declared Fortran 77 size given by
*     the intrinsic function LEN.
*  Arguments:
*     RVALUE  =  REAL (Given)
*        The value to be appended to the given string.
*     STRING  =  CHARACTER*(*) (Given and Returned)
*        The string into which the given value is to be appended.
*     IPOSN  =  INTEGER (Given and Returned)
*        The position pointer within STRING.
*  Method:
*     Determine the declared size of the output string.
*     If there is space remaining in the string then
*       Copy the given value to the local variable.
*       If the data type is CHARACTER then
*         Append the given string to the output string, checking for
*         truncation.
*       else if the data type is LOGICAL then
*         Append 'T' or 'F' to the string, as appropriate.
*         Update the counter for the last non-blank element.
*       else (the data type corresponds to a numeric type)
*         If the data type is one of: unsigned byte, byte, unsigned
*         word or word then
*           Convert the given value to data type INTEGER.
*           Convert the given value from INTEGER to CHARACTER.
*         else
*           Convert the given value to CHARACTER.
*         end if
*         Append the new character string to the return string,
*         checking for truncation.
*       end if
*     end if
*  Implementation Deficiencies:
*     Only supports the following data types: BYTE, WORD, INTEGER,
*     REAL, DOUBLE PRECISION, LOGICAL, CHARACTER.
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     JRG: Jack Giddings (UCL)
*     ACD: A.C. Davenhall (ROE, Leicester)
*     AJC: A.J. Chipperfield (STARLINK)
*  History:
*     3-JAN-1983 (JRG):
*        Original version.
*     2-OCT-1984 (ACD):
*        Documenation improved.
*     13-SEP-1988 (AJC):
*        Documentation improved.
*     24-FEB-1989 (AJC):
*        Check on string sizes.
*     14-SEP-1994 (ACD):
*        Created a generic routine from CHR_PUTC, CHR_PUTL and the
*        corresponding numeric routines.
*     24-OCT-1994 (ACD):
*        Fixed bug in doing logical syntax IF tests on LOGICAL variables
*        which the Alpha compiler objected to.
*     14-FEB-1996 (ACD):
*        Fixed various features which were technically illegal.
*  Bugs:
*     None known.
*-
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
*  Arguments Given:
      REAL
     :  RVALUE
*  Arguments Given and Returned:
      CHARACTER
     :  STRING*(*)
      INTEGER
     :  IPOSN
*  Local Constants:
      INTEGER SZSTR1    ! Size of internal character string STR1.
      PARAMETER (SZSTR1 = 80)
*  Local Variables:
      CHARACTER
     :  STR1*(SZSTR1),  ! Internal character string for converted value.
     :  CURTYP*2  ! Code for the current data type.
      INTEGER
     :  LSTR1,    ! Size of STR1 (excl. trail. blanks).
     :  WKVALI,   ! INTEGER copy of given value.
     :  STRNGS    ! Declared size of STRING.

*
*    Local copies of the given value, one per data type.

      BYTE             BLVAL
      INTEGER*2        WLVAL
      INTEGER          ILVAL
      REAL             RLVAL
      DOUBLE PRECISION DLVAL
      LOGICAL          LLVAL
      CHARACTER        CLVAL*(CAT__SZVAL)
*.

      BLVAL = 0
      WLVAL = 0
      ILVAL = 0
      RLVAL = 0.0E0
      DLVAL = 0.0D0
      LLVAL = .FALSE.
      CLVAL = ' '

*
*    Determine the declared size of the output string and proceed if 
*    there is any space remaining at the end of it.

      STRNGS = LEN(STRING)

      IF (IPOSN .LT. STRNGS) THEN

*
*       Copy the given value to the local variable.

         RLVAL = RVALUE

*
*       Get the data type of the current subroutine.

         CURTYP = 'R'

*
*       Check for data type CHARACTER.

         IF (CURTYP .EQ. 'C') THEN

*
*          Append the given string to the output string, checking for
*          truncation.

            CALL CAT1_APPND (CLVAL, STRING, IPOSN)

*
*       Check for data type CHARACTER.

         ELSE IF (CURTYP .EQ. 'L') THEN

*
*          Update the counter for the last non-blank element and append
*          'T' or 'F' to the string, as appropriate.

            IPOSN = IPOSN + 1

            IF (LLVAL) THEN
               STRING(IPOSN : IPOSN) = 'T'
            ELSE
               STRING(IPOSN : IPOSN) = 'F'
            END IF

*
*       The value must be one of the numeric data types.

         ELSE

*
*          If the data type is one of: byte, or word then convert the
*          given value to INTEGER and convert the value from INTEGER to
*          CHARACTER.  Otherwise convert the given value directly to
*          CHARACTER.

            STR1 = ' '
            LSTR1 = 0

            IF (CURTYP .EQ. 'B') THEN
               WKVALI = BLVAL
               CALL CHR_ITOC (WKVALI, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'W') THEN
               WKVALI = WLVAL
               CALL CHR_ITOC (WKVALI, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'I') THEN
               CALL CHR_ITOC (ILVAL, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'R') THEN
               CALL CHR_RTOC (RLVAL, STR1, LSTR1)
            ELSE
               CALL CHR_DTOC (DLVAL, STR1, LSTR1)
            END IF

*
*          Append the new character string to the return string,
*          checking for truncation.

            CALL CAT1_APPND (STR1(1 : LSTR1), STRING, IPOSN)
         END IF
      END IF

      END
      SUBROUTINE CAT1_PUTW (WVALUE, STRING, IPOSN)
*+
*  Name:
*     CAT1_PUTW
*  Purpose:
*     Put a value of type INTEGER*2 into a string at a given position.
*  Language:
*     Starlink Fortran 77
*  Invocation:
*     CALL CAT1_PUTW (WVALUE; STRING, IPOSN)
*  Description:
*     Put a value of type INTEGER*2 into a string at a given position.
*     The value is appended to the string beginning at position IPOSN+1.
*     IPOSN is updated to indicate the last element of STRING after the 
*     insertion.  If no copying is done, IPOSN is returned unchanged. The
*     size of STRING is based on the declared Fortran 77 size given by
*     the intrinsic function LEN.
*  Arguments:
*     WVALUE  =  INTEGER*2 (Given)
*        The value to be appended to the given string.
*     STRING  =  CHARACTER*(*) (Given and Returned)
*        The string into which the given value is to be appended.
*     IPOSN  =  INTEGER (Given and Returned)
*        The position pointer within STRING.
*  Method:
*     Determine the declared size of the output string.
*     If there is space remaining in the string then
*       Copy the given value to the local variable.
*       If the data type is CHARACTER then
*         Append the given string to the output string, checking for
*         truncation.
*       else if the data type is LOGICAL then
*         Append 'T' or 'F' to the string, as appropriate.
*         Update the counter for the last non-blank element.
*       else (the data type corresponds to a numeric type)
*         If the data type is one of: unsigned byte, byte, unsigned
*         word or word then
*           Convert the given value to data type INTEGER.
*           Convert the given value from INTEGER to CHARACTER.
*         else
*           Convert the given value to CHARACTER.
*         end if
*         Append the new character string to the return string,
*         checking for truncation.
*       end if
*     end if
*  Implementation Deficiencies:
*     Only supports the following data types: BYTE, WORD, INTEGER,
*     REAL, DOUBLE PRECISION, LOGICAL, CHARACTER.
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     JRG: Jack Giddings (UCL)
*     ACD: A.C. Davenhall (ROE, Leicester)
*     AJC: A.J. Chipperfield (STARLINK)
*  History:
*     3-JAN-1983 (JRG):
*        Original version.
*     2-OCT-1984 (ACD):
*        Documenation improved.
*     13-SEP-1988 (AJC):
*        Documentation improved.
*     24-FEB-1989 (AJC):
*        Check on string sizes.
*     14-SEP-1994 (ACD):
*        Created a generic routine from CHR_PUTC, CHR_PUTL and the
*        corresponding numeric routines.
*     24-OCT-1994 (ACD):
*        Fixed bug in doing logical syntax IF tests on LOGICAL variables
*        which the Alpha compiler objected to.
*     14-FEB-1996 (ACD):
*        Fixed various features which were technically illegal.
*  Bugs:
*     None known.
*-
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
*  Arguments Given:
      INTEGER*2
     :  WVALUE
*  Arguments Given and Returned:
      CHARACTER
     :  STRING*(*)
      INTEGER
     :  IPOSN
*  Local Constants:
      INTEGER SZSTR1    ! Size of internal character string STR1.
      PARAMETER (SZSTR1 = 80)
*  Local Variables:
      CHARACTER
     :  STR1*(SZSTR1),  ! Internal character string for converted value.
     :  CURTYP*2  ! Code for the current data type.
      INTEGER
     :  LSTR1,    ! Size of STR1 (excl. trail. blanks).
     :  WKVALI,   ! INTEGER copy of given value.
     :  STRNGS    ! Declared size of STRING.

*
*    Local copies of the given value, one per data type.

      BYTE             BLVAL
      INTEGER*2        WLVAL
      INTEGER          ILVAL
      REAL             RLVAL
      DOUBLE PRECISION DLVAL
      LOGICAL          LLVAL
      CHARACTER        CLVAL*(CAT__SZVAL)
*.

      BLVAL = 0
      WLVAL = 0
      ILVAL = 0
      RLVAL = 0.0E0
      DLVAL = 0.0D0
      LLVAL = .FALSE.
      CLVAL = ' '

*
*    Determine the declared size of the output string and proceed if 
*    there is any space remaining at the end of it.

      STRNGS = LEN(STRING)

      IF (IPOSN .LT. STRNGS) THEN

*
*       Copy the given value to the local variable.

         WLVAL = WVALUE

*
*       Get the data type of the current subroutine.

         CURTYP = 'W'

*
*       Check for data type CHARACTER.

         IF (CURTYP .EQ. 'C') THEN

*
*          Append the given string to the output string, checking for
*          truncation.

            CALL CAT1_APPND (CLVAL, STRING, IPOSN)

*
*       Check for data type CHARACTER.

         ELSE IF (CURTYP .EQ. 'L') THEN

*
*          Update the counter for the last non-blank element and append
*          'T' or 'F' to the string, as appropriate.

            IPOSN = IPOSN + 1

            IF (LLVAL) THEN
               STRING(IPOSN : IPOSN) = 'T'
            ELSE
               STRING(IPOSN : IPOSN) = 'F'
            END IF

*
*       The value must be one of the numeric data types.

         ELSE

*
*          If the data type is one of: byte, or word then convert the
*          given value to INTEGER and convert the value from INTEGER to
*          CHARACTER.  Otherwise convert the given value directly to
*          CHARACTER.

            STR1 = ' '
            LSTR1 = 0

            IF (CURTYP .EQ. 'B') THEN
               WKVALI = BLVAL
               CALL CHR_ITOC (WKVALI, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'W') THEN
               WKVALI = WLVAL
               CALL CHR_ITOC (WKVALI, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'I') THEN
               CALL CHR_ITOC (ILVAL, STR1, LSTR1)
            ELSE IF (CURTYP .EQ. 'R') THEN
               CALL CHR_RTOC (RLVAL, STR1, LSTR1)
            ELSE
               CALL CHR_DTOC (DLVAL, STR1, LSTR1)
            END IF

*
*          Append the new character string to the return string,
*          checking for truncation.

            CALL CAT1_APPND (STR1(1 : LSTR1), STRING, IPOSN)
         END IF
      END IF

      END
