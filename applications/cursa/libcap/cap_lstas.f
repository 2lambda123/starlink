      SUBROUTINE CAP_LSTAS (CI, OFLAG, FLUNIT, BAR, STATUS)
*+
*  Name:
*     CAP_LSTAS
*  Purpose:
*     List all AST information for a catalogue.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAP_LSTAS (CI, OFLAG, FLUNIT, BAR; STATUS)
*  Description:
*     List all AST information for a catalogue.
*
*     The text is listed to the standard output stream (via MSG_OUT)
*     and/or a text file.
*  Arguments:
*     CI  =  INTEGER (Given)
*        Catalogue identifier.
*     OFLAG  =  INTEGER (Given)
*        Flag indicating which output is to be produced.  It is coded
*        as follows:
*         1 - standard output (usually the command screen) only,
*         2 - text file only,
*         3 - both screen and file.
*     FLUNIT  =  INTEGER (Given)
*        Fortran unit number for writing to the text file.
*     BAR  =  LOGICAL (Given)
*        A flag indicating whether or a vertical bar ('|') will be
*        inserted at the start of lines of text sent to standard output.
*        It is coded as follows:
*        .TRUE.  -  insert a bar,
*        .FALSE. -  do not insert a bar.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     Reset access to the text information.
*     Do while (there is more information to be output)
*       Attempt to get the next line of text.
*       If ok and not finished then
*         If the line is of class AST then
*           If required then
*             Display the text to the standard output.
*           end if
*           If required then
*             Write the line of text to the output file.
*           end if
*         end if
*       end if
*       If finished or the status is not ok then
*         Set the termination flag.
*       end if
*     end do
*     If no lines of AST information were encountered then
*       Display a message.
*     end if
*  Copyright:
*     Copyright (C) 2001 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Edinburgh)
*  History:
*     2/11/01 (ACD): Original version (from CAPLSTTX).
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'SAE_PAR'    ! Standard SAE symbolic constants.
      INCLUDE 'SGZ_PAR'    ! catview parametric constants.
*  Arguments Given:
      INTEGER
     :  CI,
     :  OFLAG,
     :  FLUNIT
      LOGICAL
     :  BAR
*  Status:
      INTEGER STATUS       ! Global status.
*  External References:
      INTEGER CHR_LEN
*  Local Variables:
      LOGICAL
     :  FINISH,   ! Last line of text info input?
     :  MORE      ! Continue processing?
      CHARACTER
     :  CLASS*10,          ! Class of text info.
     :  TEXT*(SGZ__SZOPR)  ! Current line of text info.
      INTEGER 
     :  LTEXT,    ! Length of TEXT (excl. trail. blanks).
     :  LSTAT,    ! Local Fortran I/O status.
     :  ACOUNT    ! Number of lines of AST information.
*.

      IF (STATUS .EQ. SAI__OK) THEN

*
*       Write a title.

         IF (OFLAG .EQ. 1  .OR.  OFLAG .EQ. 3) THEN
            CALL CAP_OUT (BAR, ' ', 'AST information.',
     :        STATUS)
            CALL CAP_OUT (BAR, ' ', ' ', STATUS)
         END IF

         IF (OFLAG .EQ. 2  .OR.  OFLAG .EQ. 3) THEN
            WRITE(FLUNIT, 2000, IOSTAT=LSTAT)
 2000       FORMAT(1X, 'AST information.' / )
            CALL FIO_SERR (LSTAT, STATUS)
         END IF

*
*       Reset access to the text information.

         CALL CAT_RSTXT (CI, STATUS)

*
*       Get and report all the textual information.

         ACOUNT = 0
         MORE = .TRUE.
         FINISH = .FALSE.

         DO WHILE (MORE)

*
*          Attempt to get the next line of text and proceed if ok and
*          not finished.

            CALL CAT_GETXT (CI, FINISH, CLASS, TEXT, STATUS)
c           print3000, class, text(1 : 20)
c3000       format(1x, 'class, text: ', a10, 1x, a20, '...')

            IF (STATUS .EQ. SAI__OK  .AND.  .NOT. FINISH) THEN
               IF (CLASS .EQ. 'AST') THEN
                  ACOUNT = ACOUNT + 1

                  IF (TEXT .NE. ' ') THEN
                     LTEXT = CHR_LEN(TEXT)
                  ELSE
                     LTEXT = 1
                  END IF

*
*                Display the line interactively if required.

                  IF (OFLAG .EQ. 1  .OR.  OFLAG .EQ. 3) THEN
                     CALL CAP_OUT (BAR, ' ', TEXT(1 : LTEXT), STATUS)
                  END IF

*
*                Write the line to the output file, if required.

                  IF (OFLAG .EQ. 2  .OR.  OFLAG .EQ. 3) THEN
                     WRITE(FLUNIT, '(1X, A)', IOSTAT=LSTAT)
     :                 TEXT(1 : LTEXT)
                     CALL FIO_SERR (LSTAT, STATUS)
                  END IF
               END IF
            END IF

            IF (FINISH .OR.  STATUS .NE. SAI__OK) THEN
               MORE = .FALSE.
            END IF
         END DO

*
*       If no lines of AST information were encountered then display a
*       message.

         IF (ACOUNT .EQ. 0) THEN
            IF (OFLAG .EQ. 1  .OR.  OFLAG .EQ. 3) THEN
               CALL CAP_OUT (BAR, ' ', '   The catalogue contained no '/
     :           /'AST information.', STATUS)
            END IF

            IF (OFLAG .EQ. 2  .OR.  OFLAG .EQ. 3) THEN
               WRITE(FLUNIT, 2001, IOSTAT=LSTAT)
 2001          FORMAT(3X, 'The catalogue contained no AST information.')
               CALL FIO_SERR (LSTAT, STATUS)
            END IF
         END IF

*
*       Write a blank to follow the output.

         IF (OFLAG .EQ. 1  .OR.  OFLAG .EQ. 3) THEN
            CALL CAP_OUT (BAR, ' ', ' ', STATUS)
         END IF

         IF (OFLAG .EQ. 2  .OR.  OFLAG .EQ. 3) THEN
            WRITE(FLUNIT, 2002, IOSTAT=LSTAT)
 2002       FORMAT(1X)
            CALL FIO_SERR (LSTAT, STATUS)
         END IF

      END IF

      END
