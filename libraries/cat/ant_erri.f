      SUBROUTINE ANT_ERRI (MESSGE, CODE)
*+
*  Name:
*     ANT_ERRI
*  Purpose:
*     Report a parser error message with an associated INTEGER code.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL ANT_ERRI (MESSGE, CODE)
*  Description:
*     Report a parser error message with an associated INTEGER code.
*  Arguments:
*     MESSGE  =  CHARACTER*(*) (Given)
*        Error message to be reported.
*     CODE  =  INTEGER (Given)
*        INTEGER code associated with the message.
*  Algorithm:
*     Assemble the text string and report the message.
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Edinburgh)
*  History:
*     13/8/99 (ACD): Original version.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
*  Arguments Given:
      CHARACTER
     :  MESSGE*(*)
      INTEGER
     :  CODE
*  External References:
      INTEGER CHR_LEN
*  Local Variables:
      INTEGER
     :  MSGLEN,    ! length of MESSGE (excl. trail. blanks).
     :  BUFPOS     !   "    "  BUFFER ( "  .   "  .   "   ).
      CHARACTER
     :  BUFFER*80  ! Output buffer.
*.

*
*    Assemble the text string containing the error report.

      BUFFER = ' '
      BUFPOS = 0

      IF (MESSGE .NE. ' ') THEN
         MSGLEN = CHR_LEN(MESSGE)
         CALL CHR_PUTC (MESSGE(1 : MSGLEN), BUFFER, BUFPOS)
      ELSE
         CALL CHR_PUTC ('<No text available>', BUFFER, BUFPOS)
      END IF

      CALL CHR_PUTC (' ', BUFFER, BUFPOS)
      CALL CHR_PUTI (CODE, BUFFER, BUFPOS)

*
*    Report the message.

      CALL ANT_ERR (BUFFER(1 : BUFPOS) )

      END
