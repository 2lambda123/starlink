      SUBROUTINE CAT6_STCAE (ROWS, CSIZE, ROW, VALUE, COLIST, STATUS)
*+
*  Name:
*     CAT6_STAE<t>
*  Purpose:
*     Set a specified element in a character array of column values. 
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT6_STCAE (ROWS, CSIZE, ROW, VALUE; COLIST; STATUS)
*  Description:
*     Set a specified element in a character array of column values. 
*  Arguments:
*     ROWS  =  INTEGER (Given)
*        Number of rows in the column.
*     CSIZE  -  INTEGER (Given)
*        Size of each element (corresponding to a field) in the
*        character array.
*     ROW  =  INTEGER (Given)
*        Row number to be set.
*     VALUE  =  CHARACTER*(*) (Given)
*        Field value to be set (that is, the value of the column for
*        the given row).
*     COLIST(ROWS)  =  INTEGER (Given and Returned)
*        Array of column values.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     If the row number is inside the permitted range then
*       Set the value.
*     else
*       Set the status.
*       Report an error.
*     end if
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Edinburgh)
*  History:
*     15/6/99 (ACD): Original version (from CAT5_STCAE).
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
      INCLUDE 'CAT_ERR'           ! CAT error codes.
*  Arguments Given:
      INTEGER
     :  ROWS,
     :  CSIZE,
     :  ROW
      CHARACTER
     :  VALUE*(*)
*  Arguments Given and Returned:
      INTEGER
     :  COLIST(CSIZE, ROWS)
*  Status:
      INTEGER STATUS             ! Global status
*  External References:
      INTEGER CHR_LEN
*  Local Variables:
      CHARACTER
     :  ERRMSG*75   ! Text of error message.
      INTEGER
     :  LVALUE,     ! Length of value (excl. trail. blanks).
     :  LAST,       ! Last element to be set.
     :  LOOP,       ! Loop index.
     :  ERRLEN      ! Length of ERRMSG (excl. trail. blanks).
*.

      IF (STATUS .EQ. CAT__OK) THEN

         IF (ROW .GT. 0  .AND.  ROW .LE. ROWS) THEN
            IF (VALUE .NE. ' ') THEN
               LVALUE = CHR_LEN(VALUE)

               LAST = MIN(LVALUE, CSIZE)

               DO LOOP = 1, LAST
                  COLIST(LOOP, ROW) = ICHAR(VALUE(LOOP : LOOP) )
               END DO

               DO LOOP = LVALUE+1, CSIZE
                  COLIST(LOOP, ROW) = ICHAR(' ')
               END DO

            ELSE
               DO LOOP = 1, CSIZE
                  COLIST(LOOP, ROW) = ICHAR(' ')
               END DO

            END IF

         ELSE
            STATUS = CAT__INVRW

            ERRMSG = ' '
            ERRLEN = 0

            CALL CHR_PUTC ('Error: row number ', ERRMSG, ERRLEN)
            CALL CHR_PUTI (ROW, ERRMSG, ERRLEN)
            CALL CHR_PUTC (' is out of range.', ERRMSG, ERRLEN)

            CALL CAT1_ERREP ('CAT6_STCAE_ERR', ERRMSG(1 : ERRLEN),
     :        STATUS)
         END IF

      END IF

      END
