      SUBROUTINE SUBPAR_HDSDEF ( NAMECODE, ACCESS, LOC, STATUS )
*+
*  Name:
*     SUBPAR_HDSDEF

*  Purpose:
*     Get static default and return a locator to it.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL SUBPAR_HDSDEF ( NAMECODE, ACCESS, LOC, STATUS )

*  Description:
*     A locator is returned to a static default value associated with
*     the indicated parameter.

*  Arguments:
*     NAMECODE=INTEGER (given)
*        pointer to a parameter
*     ACCESS=CHARACTER*(*) (given)
*        access required to the HDS structure
*     LOC=CHARACTER*(DAT__SZLOC) (returned)
*        locator to the stored data
*     STATUS=INTEGER

*  Algorithm:
*     The static default for the indicated parameter is looked-up.
*     If it is a structure-name, a locator is obtained to it. If it is a
*     value, it is converted to the data type of the indicated parameter,
*     'private' storage is created for it, it is put into store, and a
*     locator to the store is returned.

*  Authors:
*     BDK: B D Kelly (ROE)
*     AJC: A J Chipperfield (Starlink)
*     {enter_new_authors_here}

*  History:
*     01-OCT-1984 (BDK):
*        Original
*     08-MAY-1987 (BDK):
*        Check a default exists
*     08-MAY-1987 (BDK):
*        Check for NULL default
*     14-JAN-1992 (AJC):
*        Add error reports
*     14-MAY-1992 (AJC):
*        Correct message when no default
*     20-JUL-1992 (AJC):
*        Move DATA statement
*     10-NOV-1992 (AJC):
*        Set SUBPAR__ERROR not PAR__
*     26-FEB-1993 (AJC):
*        Add INCLUDE DAT_PAR
*      9-AUG-1993 (AJC):
*        INCLUDE SUBPAR_PARERR not PAR_ERR
*      1-FEB-1996 (AJC):
*        Create storage of appropriate size for CHARACTER strings
*        (min 132).
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE

*  Global Constants:
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'SUBPAR_PAR'
      INCLUDE 'SUBPAR_ERR'
      INCLUDE 'SUBPAR_PARERR'

*  Arguments Given:
      INTEGER NAMECODE          ! pointer to a parameter
      CHARACTER*(*) ACCESS      ! access required to the HDS structure

*  Arguments Returned:
      CHARACTER*(DAT__SZLOC) LOC  ! locator to the stored data

*  Status:
      INTEGER STATUS

*  Global Variables:
      INCLUDE 'SUBPAR_CMN'

*  Local Variables:
      INTEGER COUNT                     ! number of default values
      INTEGER TYPE                      ! code for data type
      INTEGER SLEN                      ! string size
      INTEGER I                         ! index (discarded)
      CHARACTER*15 HDSTYPE              ! data type
      INTEGER NDIMS                     ! dimensionality of data
      INTEGER FIRST                     ! index of first value stored
      CHARACTER*15 POSTYPES(5)          ! possible primitive data types

*  External references:
      EXTERNAL CHR_LEN                  ! used length of string
      INTEGER CHR_LEN

*  Local Data:
      DATA POSTYPES / '_CHAR*', '_REAL', '_DOUBLE', '_INTEGER',
     :  '_LOGICAL' /
*.

      IF ( STATUS .NE. SAI__OK ) RETURN

      IF ( PARDEF(3,NAMECODE) .EQ. SUBPAR__NULLTYPE ) THEN

         STATUS = PAR__NULL
         CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
         CALL EMS_REP( 'SUP_HDSDEF1',
     :   'SUBPAR: Null (!) default value used for parameter ^NAME',
     :    STATUS )

      ELSE IF ( PARDEF(1,NAMECODE) .EQ. 0 ) THEN
*
*      No default exists. Set general error status to cause search-path
*      to continue.
*
         STATUS = SUBPAR__ERROR
         CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
         CALL EMS_REP( 'SUP_HDSDEF2',
     :   'SUBPAR: No default value for parameter ^NAME',
     :    STATUS )

      ELSE IF ( PARDEF(3,NAMECODE) .GE. 20 ) THEN
*
*      The default is the name of an HDS structure. Get a locator to
*      it.
*
         CALL SUBPAR_GETHDS ( NAMECODE, CHARLIST(PARDEF(1,NAMECODE)),
     :     ACCESS, LOC, STATUS )

      ELSE
*
*      Find the number of default values
*
         COUNT = PARDEF(2,NAMECODE) - PARDEF(1,NAMECODE) + 1
*
*      Invent the character-form of the data-type
*
         TYPE = PARDEF(3,NAMECODE)
         HDSTYPE = POSTYPES(TYPE)
         FIRST = PARDEF(1,NAMECODE)

*      Make CHAR types size dependent
         IF ( HDSTYPE .EQ. '_CHAR*' ) THEN
            IF ( COUNT .EQ. 1 ) THEN
               SLEN = MAX( 132, CHR_LEN( CHARLIST( FIRST ) ) )
            ELSE
               SLEN = SUBPAR__STRLEN
            END IF
            CALL CHR_ITOC( SLEN, HDSTYPE(7:), I )
         END IF
*
*      Create storage to hold the data and return a locator to it
*
         IF ( COUNT .GT. 1 ) THEN
            NDIMS = 1
         ELSE
            NDIMS = 0
         ENDIF

         CALL SUBPAR_CRINT ( NAMECODE, HDSTYPE, NDIMS, COUNT, LOC,
     :     STATUS )
*
*     Put the data into it
*
         IF ( TYPE .EQ. SUBPAR__REAL ) THEN
            CALL DAT_PUTR ( LOC, NDIMS, COUNT, REALLIST(FIRST), STATUS )
         ELSE IF ( TYPE .EQ. SUBPAR__CHAR ) THEN
            CALL DAT_PUTC ( LOC, NDIMS, COUNT, CHARLIST(FIRST), STATUS )
         ELSE IF ( TYPE .EQ. SUBPAR__INTEGER ) THEN
            CALL DAT_PUTI ( LOC, NDIMS, COUNT, INTLIST(FIRST), STATUS )
         ELSE IF ( TYPE .EQ. SUBPAR__DOUBLE ) THEN
            CALL DAT_PUTD ( LOC, NDIMS, COUNT, DOUBLELIST(FIRST),
     :        STATUS )
         ELSE IF ( TYPE .EQ. SUBPAR__LOGICAL ) THEN
            CALL DAT_PUTL ( LOC, NDIMS, COUNT, LOGLIST(FIRST), STATUS )
         ENDIF

      ENDIF

      END

