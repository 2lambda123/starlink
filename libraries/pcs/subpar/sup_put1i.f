      SUBROUTINE SUBPAR_PUT1I ( NAMECODE, NVAL, VALUES, STATUS )
*+
*  Name:
*     SUBPAR_PUT1I
 
*  Purpose:
*     Write vector parameter values.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL SUBPAR_PUT1I ( NAMECODE, NVAL, IVALUES, STATUS )
 
*  Description:
*     Write the values to a vector primitive object associated with
*     a Parameter.
*     There is a routine for each access type, INTEGER:
 
*        SUBPAR_PUT1D    DOUBLE PRECISION
*        SUBPAR_PUT1R    REAL
*        SUBPAR_PUT1I    INTEGER
*        SUBPAR_PUT1L    LOGICAL
*        SUBPAR_PUT1C    CHARACTER[*n]
 
*     If the object data type differs from the access type, INTEGER, then
*     conversion is performed (if allowed).
 
*  Arguments:
*     NAMECODE=INTEGER ( given)
*        pointer to the parameter
*     NVAL=INTEGER
*        the number of values that are to be written.
*     VALUES(NVAL)=INTEGER
*        Array containing the values to be written into the object.
*     STATUS=INTEGER
 
*  Copyright:
*     Copyright (C) 1984, 1986, 1988, 1991, 1992, 1993 Science & Engineering Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*     
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*     
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     BDK: B D Kelly (ROE)
*     AJC: A J Chipperfield (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     23-Jul-1984 (BDK):
*        Original version
*     07.11.1984 (BDK):
*        INCOPY arguments changed
*     18.08.1986 (BDK):
*        Check status before using pointer
*     15.08.1988 (AJC):
*        Don't annul locator if not obtained
*     06.08.1991 (AJC):
*        Use HDS type conversion
*        Change PAR__ICACM to SUBPAR__
*        and EMS error reports
*     24.09.1991 (AJC):
*        Prefix messages with 'SUBPAR:'
*     20-JUL-1992 (AJC):
*        Move DATA statement
*     04-AUG-1992 (AJC):
*        Add message to cover if HDS doesn't.
*        Go through CRINT for internals or normal params unless a named
*        object is associated. This allows a change of size or type.
*     26-FEB-1993 (AJC):
*        Add INCLUDE DAT_PAR
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE
 
 
*  Global Constants:
      INCLUDE 'SAE_PAR'                 ! SAI Constants
      INCLUDE 'DAT_PAR'
      INCLUDE 'SUBPAR_PAR'
      INCLUDE 'SUBPAR_ERR'
 
 
*  Arguments Given:
      INTEGER NAMECODE                  ! Parameter number
 
      INTEGER NVAL                      ! number of values
 
      INTEGER VALUES(*)                  ! Array to supply values
 
*    Status return :
      INTEGER STATUS                    ! Status Return
 
 
*  Global Variables:
      INCLUDE 'SUBPAR_CMN'
 
 
*  Local Variables:
      LOGICAL INTERNAL                  ! .TRUE. => values are to be
                                        ! stored locally to the program
                                        ! rather than in a
                                        ! user-specified HDS structure.
 
      CHARACTER*(DAT__SZLOC) BOTLOC     ! locator to HDS object
 
      CHARACTER*15 HDSTYPE              ! type of primitive data
                                        ! to be stored
 
      INTEGER TYPE                      ! encoded data type
 
      CHARACTER*15 POSTYPES(5)          ! possible primitive data types
 
 
*  Local Data:
      DATA POSTYPES / '_CHAR', '_REAL', '_DOUBLE', '_INTEGER',
     :  '_LOGICAL' /
 
*.
 
 
      IF (STATUS .NE. SAI__OK) RETURN
 
*
*   Check that there is write access to the parameter
*
      IF ( PARWRITE(NAMECODE) ) THEN
*
*      Get the type of the parameter
*
         TYPE = MOD ( PARTYPE(NAMECODE), 10 )
*
*      Get character version of type
*
         HDSTYPE = POSTYPES(TYPE)
         IF ( TYPE .EQ. SUBPAR__CHAR ) THEN
*
*         Invent an oversize value
*
            HDSTYPE = '_CHAR*132'
         ENDIF
*
*      Check to see whether 'internal' storage is to be used to
*      hold the data.
*      i.e. if STATE is not NULL and either PARTYPE lies between 10 and 20
*      or the parameter is declared INTERNAL and has not had a named object
*      associated with it
         IF ( ( PARSTATE(NAMECODE) .NE. SUBPAR__NULL ) .AND.
     :     ( ( PARTYPE(NAMECODE) .GE. 10 ) .AND.
     :       ( PARTYPE(NAMECODE) .LT. 20 ) ) .OR.
     :     ( ( PARVPATH(1,NAMECODE) .EQ. SUBPAR__INTERNAL ) .AND.
     :     ( PARTYPE(NAMECODE) .LT. 10 ) ) ) THEN
            INTERNAL = .TRUE.
         ELSE
            INTERNAL = .FALSE.
         ENDIF
 
         IF ( .NOT. INTERNAL ) THEN
*
*         Attempt to get a locator to an HDS structure
*
            CALL SUBPAR_ASSOC ( NAMECODE, 'WRITE', BOTLOC, STATUS )
            IF ( ( STATUS .EQ. SAI__OK ) .AND.
     :           ( PARTYPE(NAMECODE) .LT. 20 ) ) INTERNAL = .TRUE.
 
         END IF
 
         IF ( INTERNAL ) THEN
*
*         Value is to be put into the program's private parameter
*         store.
*         Create the necessary space and return a locator to it
*
            CALL SUBPAR_CRINT ( NAMECODE, HDSTYPE, 1, NVAL, BOTLOC,
     :        STATUS )
 
         ENDIF
 
         IF (STATUS .EQ. SAI__OK) THEN
*
*         Write the data
*
            CALL DAT_PUT1I ( BOTLOC, NVAL, VALUES, STATUS )
*
*      Report if error - in case HDS doesn't
*
            IF ( STATUS .NE. SAI__OK ) THEN
               CALL EMS_SETC ( 'NAME', PARKEY(NAMECODE) )
               CALL EMS_REP ( 'SUP_PUT1_1',
     :         'SUBPAR: HDS failed to ''PUT'' to parameter ^NAME',
     :          STATUS )
            END IF
*
*         Annul the locator.
*
            CALL DAT_ANNUL ( BOTLOC, STATUS )
 
         ENDIF
 
      ELSE
 
*      No write access to parameter
         STATUS = SUBPAR__ICACM
         CALL EMS_SETC ( 'NAME', PARKEY(NAMECODE) )
         CALL EMS_REP ( 'SUP_PUT1_2',
     :   'SUBPAR: Failed to ''PUT'' to parameter ^NAME - '//
     :   'access READ specified', STATUS )
 
      ENDIF
 
 
      END
