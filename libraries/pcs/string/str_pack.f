*+  STRING_PACK - pack an array of strings into a smaller array
      SUBROUTINE STRING_PACK ( NUMPACK, SIZE, INARRAY, OUTARRAY, 
     :     STATUS )
*    Description :
*     Pack an array of strings into a smaller array of bigger strings.
*     The NUMPACK elements of the output array each consist of SIZE 
*     elements of the input array separated by commas and surrounded by 
*     brackets.
*    Deficiencies :
*     The use of CHR_FIWS assumes that there are no significant leading
*     commas in the input elements.
*    Invocation :
*     CALL STRING_PACK ( NUMPACK, SIZE, INARRAY, OUTARRAY, 
*    :     STATUS )
*    Parameters :
*     NUMPACK=INTEGER (given)
*           number of output strings
*     SIZE=INTEGER (given)
*           number of input strings per output string
*     INARRAY(*)=CHARACTER*(*) (given)
*           array of input strings
*     OUTARRAY(*)=CHARACTER*(*) (returned)
*           array of output strings
*     STATUS=INTEGER
*    Method :
*     For each output string, concatenate the SIZE input strings
*     separating them by commas and removing trailing spaces.
*     Each output string is surrounded by a pair of brackets.
*    Deficiencies :
*     <description of any deficiencies>
*    Bugs :
*     <description of any "bugs" which have not been fixed>
*    Authors :
*     B.D.Kelly
*    History :
*     08.05.1987:  Original  (REVAD::BDK)
*     08.06.1987:  use square brackets (REVAD::BDK)
*     19.07.1991:  rewrite using CHR not VMS specifics (RLVAD::AJC)
*    endhistory
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'CHR_ERR'
*    Local constants :
      CHARACTER LBRACK
      PARAMETER ( LBRACK = '[' )

      CHARACTER RBRACK
      PARAMETER ( RBRACK = ']' )

*    Import :
      INTEGER NUMPACK            ! number of output strings

      INTEGER SIZE               ! number of input strings per output 
                                 ! string

      CHARACTER*(*) INARRAY(*)   ! array of input strings

*    Export :
      CHARACTER*(*) OUTARRAY(*)  ! array of output strings

*    Status :
      INTEGER STATUS

*    External references :
      INTEGER CHR_LEN            ! used length of string

*    Local variables :
      INTEGER I             ! counter for packing output array

      INTEGER J             ! counter for output array

      INTEGER K             ! counter for input array

      INTEGER POS           ! counter for output string

      INTEGER LENGTH        ! trimmed length of strings

      INTEGER START         ! start position of strings
*-

      IF ( STATUS .NE. SAI__OK ) RETURN
*  For each element of the output array
      DO J = 1, NUMPACK

*     Put the initial [
         OUTARRAY(J) = LBRACK

*     Initialise pointers
         I = 1
         POS = 1

*     and fill the output array with SIZE input array elements, removing
*     leading and trailing blanks.
         DOWHILE ( ( I .LE. SIZE ) .AND. ( STATUS .EQ. SAI__OK ) )
            K = I + (J-1)*SIZE
*        Find the first non-SPACE/TAB/COMMA character
            START = 1
            CALL CHR_FIWS( INARRAY(K), START, STATUS )
*        If no word was found
*        clear STATUS and cause a single space to be output
            IF ( STATUS .EQ. CHR__WRDNOTFND ) THEN
               STATUS = SAI__OK
               START = 1
            ENDIF

*        Find the used length of the input string
            LENGTH = CHR_LEN( INARRAY(K)(START:) )

*        If there is room for it in the output array element, copy it,
            IF ( POS+1+LENGTH .LE. LEN( OUTARRAY(J) ) ) THEN
               OUTARRAY(J)(POS+1:) = INARRAY(K)(START:START+LENGTH-1)
*           increment the output string pointer
               POS = POS + 1 + LENGTH
*           and follow it with a comma 
*           - this also copes with blank strings
               OUTARRAY(J)(POS:POS) = ','

*        If there is insufficient room in the output array element.
*        Set status and report error
            ELSE
               STATUS = SAI__ERROR
               CALL EMS_REP( 'STR_PACK1',
     :         'STRING_PACK: Overflowed output string', STATUS )

            ENDIF

*        Do next input element
            I = I + 1

         ENDDO

*  Overwrite the last comma with ]
         OUTARRAY(J)(POS:POS) = RBRACK
      ENDDO

      END

