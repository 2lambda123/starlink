*+  PARSECON_OREQ - Set-up new entry on required value list for OBEY
      SUBROUTINE PARSECON_OREQ ( ENTRY, STATUS )
*    Description :
*     Sets up an entry on the required value list of an OBEY action. The 
*     entry must be already declared on the list of program parameters.
*    Invocation :
*     CALL PARSECON_OREQ ( ENTRY, STATUS )
*    Parameters :
*     ENTRY=CHARACTER*(*) (given)
*           the name of the 'required' parameter
*     STATUS=INTEGER
*    Method :
*     Check that ENTRY has been declared as a program parameter.
*     Then check it isn't in the NEEDS list currently being generated. 
*     Finally add it to the NEEDS list.
*    Deficiencies :
*     <description of any deficiencies>
*    Bugs :
*     <description of any "bugs" which have not been fixed>
*    Authors :
*     B.D.Kelly (REVAD::BDK)
*     A J Chipperfield (STARLINK)
*    History :
*     14.09.1984:  Original (REVAD::BDK)
*     24.02.1992:  Report errors
*                  and rely on _FINDPAR to set NOPAR (RLVAD::AJC)
*     24.03.1993:  Add DAT_PAR for SUBPAR_CMN
*    endhistory
*    Type Definitions :
      IMPLICIT NONE

*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'PARSECON_ERR'

*    Import :
      CHARACTER*(*) ENTRY

*    Status :
      INTEGER STATUS

*    Global variables :
      INCLUDE 'SUBPAR_CMN'

*    Local variables :
      INTEGER NAMCOD                         ! pointer to parameter to 
                                             ! be added to list.

      INTEGER J
*-

      IF ( STATUS .NE. SAI__OK ) RETURN

*
*   Check that the eeds list is not full
*
      IF ( NEEDPTR .LT. SUBPAR__MAXNEEDS ) THEN
*
*      search name list for name - error if not found
*
         CALL PARSECON_FINDPAR ( ENTRY, NAMCOD, STATUS )

         IF ( STATUS .EQ. SAI__OK ) THEN
*
*         name there, so search for it on required value list 
*         - error if found
*
            IF ( NEEDOB(1,ACTPTR) .NE. 0 ) THEN
*
*            A list of required parameters has already been started for 
*            this OBEY action, so search the list.
*
               DO J = NEEDOB(1,ACTPTR), NEEDOB(2,ACTPTR)

                  IF ( NEEDPAR(J) .EQ. NAMCOD ) THEN
                     STATUS = PARSE__OLDREQ
                     CALL EMS_REP ( 'PCN_OREQ1',
     :               'PARSECON: Parameter repeated on "NEEDS" list',
     :                STATUS )
                  ENDIF

               ENDDO

            ELSE
*
*            Starting a new list
*
               NEEDOB(1,ACTPTR) = NEEDPTR + 1

            ENDIF

            IF ( STATUS .EQ. SAI__OK ) THEN
*
*            Add to required value list.
*
               NEEDPTR = NEEDPTR + 1
               NEEDPAR(NEEDPTR) = NAMCOD
               NEEDOB(2,ACTPTR) = NEEDPTR

            ENDIF

         ENDIF

      ELSE

         STATUS = PARSE__NOMEM
         CALL EMS_REP ( 'PCN_OREQ2',
     :   'PARSECON: Exceeded storage for "NEEDS"', STATUS )

      ENDIF

      END
