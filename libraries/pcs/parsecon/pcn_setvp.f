*+  PARSECON_SETVP - Sets-up parameter vpath
      SUBROUTINE PARSECON_SETVP ( ENTRY, STATUS )
*    Description :
*     Interprets the provided string as a VPATH specification, 
*     and adds it into the VPATH store for the most recently declared 
*     program parameter.
*    Invocation :
*     CALL PARSECON_SETVP ( ENTRY, STATUS )
*    Parameters :
*     ENTRY=CHARACTER*(*) (given)
*           VPATH specifier
*     STATUS=INTEGER
*    Method :
*     Superfluous quotes are removed from the given string, and the 
*     result is interpreted as a set of path specifiers which are encoded 
*     into the array holding VPATH.
*    Deficiencies :
*     <description of any deficiencies>
*    Bugs :
*     <description of any "bugs" which have not been fixed>
*    Authors :
*     B.D.Kelly (REVAD::BDK)
*     A J Chipperfield (STARLINK)
*    History :
*     19.09.1984:  Original (REVAD::BDK)
*     01.03.1985:  make 'INTERNAL' generate full path (REVAD::BDK)
*     15.05.1990:  correct heading comment (RLVAD::AJC)
*     16.10.1990:  use CHR for upper case (RLVAD::AJC)
*     25.06.1991:  STRING_ARRCHAR changed to PARSECON_ARRCHAR (RLVAD::AJC)
*     25.02.1991:  Report errors (RLVAD::AJC)
*     26.02.1992:  _ARRCHAR no longer capitalizes (RLVAD::AJC)
*      7.09.1992:  remove superfluous CHR_UCASE
*                  improve error report (RLVAD::AJC)
*      9.09.1992:  make precedence dynamic, default to match FETCH (RLVAD::AJC)
*     24.03.1993:  Add DAT_PAR for SUBPAR_CMN
*     01.02.2004:  Added to CVS repository cvs.starlink.ac.uk.  See there
*                  for further changes.
*    endhistory
*    Type Definitions :
      IMPLICIT NONE

*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'PARSECON_ERR'

*    Import :
      CHARACTER*(*) ENTRY             ! the VPATH string

*    Status :
      INTEGER STATUS

*    Global variables :
      INCLUDE 'SUBPAR_CMN'

*    External references :
*     None

*    Local variables :
      CHARACTER*80 VALUE              ! VPATH string with quotes removed

      INTEGER POS                     ! loop counter for VPATH step

      CHARACTER*15 STEPS(5)           ! split VPATH string

      INTEGER LENSTEPS(5)             ! length of STEPS strings

      INTEGER COUNT                   ! number of steps
*-

      IF ( STATUS .NE. SAI__OK ) RETURN

      IF ( PARPTR .GT. SUBPAR__MAXPAR ) THEN
*      We've bust the array bounds
         STATUS = PARSE__NOMEM
         CALL EMS_SETI ( 'MAXVP', SUBPAR__MAXPAR )
         CALL EMS_REP ( 'PCN_SETVP2',
     :        'PARSECON: Too many vpaths: maximum ^MAXVP',
     :        STATUS )
         RETURN                 ! JUMP OUT
      ENDIF

*   Remove the quotes from ENTRY and force to uppercase.
      CALL STRING_STRIPQUOT ( ENTRY, VALUE, STATUS )
      CALL CHR_UCASE( VALUE )

*   Split the string up into the set of path specifiers
      CALL PARSECON_ARRCHAR ( VALUE, 5, COUNT, STEPS, LENSTEPS,
     : STATUS )

*   Blank the search path for the latest parameter
      DO POS = 1, 5

         PARVPATH(POS,PARPTR) = SUBPAR__NOPATH

      ENDDO

*   Load encoded version of the VPATH
      IF ( STEPS(1) .EQ. 'INTERNAL' ) THEN

*      Load the search-path INTERNAL, DYNAMIC, DEFAULT, NOPROMPT         
         PARVPATH(1,PARPTR) = SUBPAR__INTERNAL
         PARVPATH(2,PARPTR) = SUBPAR__DYNAMIC
         PARVPATH(3,PARPTR) = SUBPAR__DEFAULT
         PARVPATH(4,PARPTR) = SUBPAR__NOPROMPT

      ELSE

*      Load the given search-path
         DO POS = 1, COUNT
            IF ( STEPS(POS) .EQ. 'CURRENT' ) THEN
               PARVPATH(POS,PARPTR) = SUBPAR__CURRENT
            ELSE IF ( STEPS(POS) .EQ. 'DEFAULT' ) THEN
               PARVPATH(POS,PARPTR) = SUBPAR__DEFAULT
            ELSE IF ( STEPS(POS) .EQ. 'DYNAMIC' ) THEN
               PARVPATH(POS,PARPTR) = SUBPAR__DYNAMIC
            ELSE IF ( STEPS(POS) .EQ. 'GLOBAL' ) THEN
               PARVPATH(POS,PARPTR) = SUBPAR__GLOBAL
            ELSE IF ( STEPS(POS) .EQ. 'NOPROMPT' ) THEN
               PARVPATH(POS,PARPTR) = SUBPAR__NOPROMPT
            ELSE IF ( STEPS(POS) .EQ. 'PROMPT' ) THEN
               PARVPATH(POS,PARPTR) = SUBPAR__PROMPT
            ELSE IF ( STEPS(POS) .EQ. 'INTERNAL' ) THEN
               PARVPATH(POS,PARPTR) = SUBPAR__INTERNAL
            ELSE
               STATUS = PARSE__IVVPATH
               CALL EMS_SETC( 'ITEM', ENTRY )
               CALL EMS_REP ( 'PCN_SETVP1',
     :         'PARSECON: Illegal item in VPATH ^ITEM', STATUS )
            ENDIF

         ENDDO

      ENDIF

      END
