*+  PARSECON_ACTLIST - Insert value into constraint list for actions
      SUBROUTINE PARSECON_ACTLIST ( ENTRY, STATUS )
*    Description :
*     Adds a value into the constraint-list for the most recent 
*     entry on the list of required parameters for actions.
*    Invocation :
*     CALL PARSECON_ACTLIST ( ENTRY, STATUS )
*    Parameters :
*     ENTRY=CHARACTER*(*) (given)
*           data value
*     STATUS=INTEGER
*    Method :
*     This routine adds a value into the constraint-list for the most 
*     recent entry on the list of required parameters for actions.
*     The common variable NEEDPTR has been previously set to point to 
*     the relevant entry, and this entry is a pointer to the relevant 
*     parameter. The type of this parameter is extracted from storage, 
*     and compared with the type deduced from the syntax of the value 
*     string in ENTRY. Any valid type conversions are performed, and the 
*     value is stored.
*    Deficiencies :
*     <description of any deficiencies>
*    Bugs :
*     <description of any "bugs" which have not been fixed>
*    Authors :
*     B.D.Kelly (REVAD::BDK)
*     A J Chipperfield (STARLINK)
*    History :
*     14.09.1984:  Original (REVAD::BDK)
*     16.02.1988:  force character values to uppercase (REVAD::BDK)
*     15.10.1990:  Signal error on real or double to integer conversion
*                  Use CHR for conversion. (RLVAD::AJC)
*     24.02.1992:  Report errors (RLVAD::AJC)
*     24.03.1993:  Add DAT_PAR for SUBPAR_CMN
*    endhistory
*    Type Definitions :
      IMPLICIT NONE

*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'PARSECON_ERR'
      INCLUDE 'PARSECON_PAR'
      INCLUDE 'SUBPAR_PAR'

*    Import :
      CHARACTER*(*) ENTRY                        ! data value

*    Status :
      INTEGER STATUS

*    Global variables :
      INCLUDE 'SUBPAR_CMN'

*    Local variables :
      INTEGER TEMPTR                           ! pointer to the 
                                               ! parameter being 
                                               ! constrained

      INTEGER DECTYPE                          ! code for type of 
                                               ! declared program 
                                               ! parameter

      INTEGER CLASS                            ! code for type of ENTRY
                                               ! deduced from its syntax

      CHARACTER*132 VALUE_CHAR                 ! decoded ENTRY string
*-

      IF ( STATUS .NE. SAI__OK ) RETURN

*   Look-up the pointer to the parameter most recently added to the 
*   needs list.
      TEMPTR = NEEDPAR(NEEDPTR) 

*   Get the type declared for the parameter indicated by the last entry 
*   on the needs list.
      DECTYPE = PARTYPE ( TEMPTR )

*   determine what type information can be deduced from the syntax of 
*   the entry to be added, and do any syntax-dependent string 
*   processing. - eg remove single quotes from character constant.
      CALL PARSECON_DECVAL ( ENTRY, VALUE_CHAR, CLASS, STATUS )

*   Check for acceptable type conversions between the given entry value 
*   and the declared type of the associated parameter.
      IF ( CLASS .EQ. PARSE__STRUC ) THEN

*      Structures are not allowed as elements of a constraint list.
         STATUS = PARSE__IVLIST
         CALL EMS_REP ( 'PCN_ACTLIST1',
     :   'PARSECON: Structures are not allowed in "NEEDS" constraints',
     :    STATUS )

      ELSE IF ( CLASS .EQ. PARSE__CHAR ) THEN

*      String constant. VALUE_CHAR will contain the string with the 
*      delimiting single quotes removed, and double (ie escaped) quotes 
*      contracted.
         IF ( DECTYPE .EQ. SUBPAR__CHAR ) THEN

            IF ( CHARPTR .LT. SUBPAR__MAXLIMS ) THEN

               CHARPTR = CHARPTR + 1
               CALL CHR_UCASE( VALUE_CHAR )
               CHARLIST(CHARPTR) = VALUE_CHAR
               IF ( NEEDLIMS(1,NEEDPTR) .EQ. 0 ) 
     :           NEEDLIMS(1,NEEDPTR) = CHARPTR
               NEEDLIMS(2,NEEDPTR) = CHARPTR

            ELSE

               STATUS = PARSE__NOMEM
               CALL EMS_REP ( 'PCN_ACTLIST2',
     :         'PARSECON: Exceeded storage for CHARACTER constraints',
     :         STATUS )

            ENDIF

         ELSE

            STATUS = PARSE__VALTYPE
            CALL EMS_REP ( 'PCN_ACTLIST3',
     :      'PARSECON: String as constraint for numeric parameter',
     :       STATUS )
            
         ENDIF

      ELSE IF ( CLASS .EQ. PARSE__NUMBER ) THEN

*      ENTRY contains a string with the syntax of a number. Convert this
*      to the relevant numeric type.
         IF ( DECTYPE .EQ. SUBPAR__REAL ) THEN

            IF ( REALPTR .LT. SUBPAR__MAXLIMS ) THEN

               REALPTR = REALPTR + 1
               CALL CHR_CTOR( ENTRY, REALLIST(REALPTR), STATUS )
               IF ( NEEDLIMS(1,NEEDPTR) .EQ. 0 ) 
     :           NEEDLIMS(1,NEEDPTR) = REALPTR
               NEEDLIMS(2,NEEDPTR) = REALPTR

            ELSE

               STATUS = PARSE__NOMEM
               CALL EMS_REP ( 'PCN_ACTLIST4',
     :         'PARSECON: Exceeded storage for REAL constraints',
     :         STATUS )

            ENDIF

         ELSE IF ( DECTYPE .EQ. SUBPAR__DOUBLE ) THEN

            IF ( DOUBLEPTR .LT. SUBPAR__MAXLIMS ) THEN

               DOUBLEPTR = DOUBLEPTR + 1
               CALL CHR_CTOD( ENTRY, DOUBLELIST(DOUBLEPTR), STATUS )
               IF ( NEEDLIMS(1,NEEDPTR) .EQ. 0 ) 
     :           NEEDLIMS(1,NEEDPTR) = DOUBLEPTR
               NEEDLIMS(2,NEEDPTR) = DOUBLEPTR

            ELSE

               STATUS = PARSE__NOMEM
               CALL EMS_REP ( 'PCN_ACTLIST5',
     :         'PARSECON: Exceeded storage for DOUBLE constraints',
     :         STATUS )

            ENDIF

         ELSE IF ( DECTYPE .EQ. SUBPAR__INTEGER ) THEN

            IF ( INTPTR .LT. SUBPAR__MAXLIMS ) THEN

               INTPTR = INTPTR + 1
               CALL CHR_CTOI( ENTRY, INTLIST(INTPTR), STATUS )
               IF ( NEEDLIMS(1,NEEDPTR) .EQ. 0 ) 
     :           NEEDLIMS(1,NEEDPTR) = INTPTR
               NEEDLIMS(2,NEEDPTR) = INTPTR

            ELSE

               STATUS = PARSE__NOMEM
               CALL EMS_REP ( 'PCN_ACTLIST6',
     :         'PARSECON: Exceeded storage for INTEGER constraints',
     :         STATUS )

            ENDIF

         ELSE IF ( DECTYPE .EQ. SUBPAR__LOGICAL ) THEN

*         Constraints not allowed on LOGICAL parameters
            STATUS = PARSE__IVLIST
            CALL EMS_REP ( 'PCN_ACTLIST7',
     :      'PARSECON: Constraints not allowed on LOGICAL parameters',
     :       STATUS )

         ENDIF

         IF ( STATUS .EQ. SAI__ERROR ) THEN

            STATUS = PARSE__VALTYPE
            CALL EMS_REP ( 'PCN_ACTLIST8',
     :      'PARSECON: Failed to convert item to required type',
     :       STATUS )

         ENDIF

      ELSE IF ( ( CLASS .EQ. PARSE__LOGTRUE ) .OR.
     :  ( CLASS .EQ. PARSE__LOGFALSE ) ) THEN

*      Logical values - not allowed
         STATUS = PARSE__IVLIST
         CALL EMS_REP ( 'PCN_ACTLIST9',
     :   'PARSECON: LOGICAL constants are not allowed as constraints',
     :    STATUS )

      ELSE

         STATUS = PARSE__VALSYN
         CALL EMS_REP ( 'PCN_ACTLIST10',
     :   'PARSECON: Invalid item in constraints list', STATUS )

      ENDIF

      END
