C+ 
C                      G K D _ W R I T E _ L I N E
C
C  Routine name: 
C     GKD_WRITE_LINE
C 
C  Function: 
C     Writes a line to the screen controlled by the GKD_ routines.
C 
C  Description: 
C     This routine writes a single line to the alphanumeric text screen
C     controlled by the GKD_ graphics dialogue package.  One way or
C     another, it will get the line out to the screen, and will do 
C     this in as neat a way as possible, depending on what it knows 
C     (if anything) about the terminal being used.  This routine is
C     intended to be used instead of PAR_WRUSER during interactive
C     graphics dialogues.
C 
C  Language: 
C     FORTRAN 
C 
C  Call: 
C     CALL GKD_WRITE_LINE (STRING) 
C 
C  Parameters:   (">" input,"!" modified, "W" workspace, "<" output) 
C 
C     (>) STRING         (Fixed string,descr) The string to be output.
C                        The whole of the string is output, trailing
C                        blanks included.
C 
C  Author: Keith Shortridge, AAO 
C 
C  Version date: 11th March 1988. 
C 
C  Subroutine / function details: 
C     PAR_WRUSER     Output a line to user.
C 
C  History: 
C     11th March 1988 Original version.  KS / AAO. 
C- 
      SUBROUTINE GKD_WRITE_LINE (STRING) 
C 
      IMPLICIT NONE 
C 
C     Parameters 
C 
      CHARACTER*(*) STRING
C 
C     Local variables 
C 
      INTEGER   STATUS          ! Used for all status codes
C
C     There really seems no need to use anything but PAR_WRUSER.
C     If that assumption proves wrong, we may be grateful for 
C     having defined this wrap-up.
C
      CALL PAR_WRUSER(STRING,STATUS)
C
C     Exit
C
      END
