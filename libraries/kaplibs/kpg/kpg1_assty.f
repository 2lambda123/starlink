      SUBROUTINE KPG1_ASSTY( SETTNG, NAME, VALUE, STATUS )
*+
*  Name:
*     KPG1_ASSTY

*  Purpose:
*     Check for synonyms and colour names in AST attribute settings.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_ASSTY( SETTNG, NAME, VALUE, STATUS )

*  Description:
*     This routine splits the supplied AST attribute setting string up
*     into a name and a value, replacing synonyms for AST attribute names
*     or qualifiers with the corresponding AST names and qualifiers, and
*     replacing colour names within the attribute value with corresponding 
*     PGPLOT colour indices. Synonyms for AST attribute names or
*     qualifiers are set up using KPG1_ASPSY.
*
*     Matching of attribute names and attribute qualifiers are performed 
*     separately. The names are matched first. An attempt to match any 
*     supplied attribute qualifier against a synonym is only made if the 
*     attribute names match, or if the synonym does not contain an 
*     attribute name. Synonyms may specify minimum abbreviations for 
*     attribute qualifiers by including an asterisk within the qualifier
*     string. The asterisk marks the end of the minimum abbreviation.

*  Arguments:
*     SETTNG = CHARACTER * ( * ) (Given)
*        The text to be checked, potetially containing synonyms and
*        colour names.
*     NAME = CHARACTER * ( * ) (Returned)
*        The corresponding AST attribute name (with a possible qualifier).
*     VALUE = CHARACTER * ( * ) (Returned)
*        The corresponding AST attribute value.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1998 Central Laboratory of the Research Councils.
*     Copyright (C) 2005 Particle Physics & Astronomy Research Council.
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
*     DSB: David S. Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     14-JUL-1998 (DSB):
*        Original version.
*     14-SEP-2005 (TIMJ):
*        Use common block accessor functions
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'GRP_PAR'          ! GRP constants
      INCLUDE 'DAT_PAR'          ! HDS constants (needed by KPG_AST)
      INCLUDE 'CTM_PAR'          ! CTM_ Colour-Table Management constants

*  Arguments Given:
      CHARACTER SETTNG*(*)

*  Arguments Returned:
      CHARACTER NAME*(*)
      CHARACTER VALUE*(*)

*  Status:
      INTEGER STATUS             ! Global status

*  Global Variables:

*  External References:
      INTEGER CHR_LEN            ! Significant length of a string
      LOGICAL KPG1_SHORT         ! Is string an allowed abbreviation?
      LOGICAL CHR_SIMLR          ! Are strings equal apart from case?

      INTEGER KPG1_GETASTING     ! GRP identifier for group holding synonyms.
      INTEGER KPG1_GETASTNPS     ! Number of defined synonyms
      INTEGER KPG1_GETASTOUG     ! GRP id for group holding AST attr names
      EXTERNAL KPG1_GETASTING
      EXTERNAL KPG1_GETASTOUG
      EXTERNAL KPG1_GETASTNPS

*  Local Variables:
      CHARACTER ANAME*(GRP__SZNAM)! Attribute name to return
      CHARACTER AQUAL*(GRP__SZNAM)! Attribute qualifier to return
      CHARACTER SY*(GRP__SZNAM)   ! synonym
      CHARACTER TRAN*(GRP__SZNAM) ! Translation
      INTEGER CL                 ! Index of closing parenthesis in synonym
      INTEGER CL1                ! Index of closing parenthesis in translation
      INTEGER CL2                ! Index of closing parenthesis in text
      INTEGER COLIND             ! Colour index
      INTEGER DOWN               ! The lowest colour index available
      INTEGER EQUALS             ! Index of equals sign
      INTEGER IAT                ! Significant length of text2
      INTEGER ID                 ! PGPLOT device identifier (zero if none)
      INTEGER J                  ! Synonym index
      INTEGER NCH                ! No. of characters used to format COLIND
      INTEGER NPLEN              ! Length of attribute name in synonym
      INTEGER NRLEN              ! Length of attribute name in translation
      INTEGER NTLEN              ! Length of attribute name in supplied text
      INTEGER OP                 ! Index of opening parenthesis in synonym
      INTEGER OP1                ! Index of opening parenthesis in translation
      INTEGER OP2                ! Index of opening parenthesis in text
      INTEGER UP                 ! The highest colour index available
      LOGICAL NMATCH             ! Does synonym name match text?
      LOGICAL QMATCH             ! Does synonym qualifier match text?
      LOGICAL VALID1             ! Is synonym group identifier valid?
      LOGICAL VALID2             ! Is attribute name group identifier valid?
*.

*  Check the inherited status.
      IF( STATUS .NE. SAI__OK ) RETURN

*  Extract the name/qualifier, and value from the supplied setting string.
*  =======================================================================

*  See if there is an equals in the supplied string.
      EQUALS = INDEX( SETTNG, '=' )

*  If no equals sign is found return a balnk value.
      IF( EQUALS .EQ. 0 ) THEN
         NAME = SETTNG
         VALUE = ' '
         GO TO 999
      END IF

*  Store everything before the equals (except spaces) as the attribute name
*  and (maybe) qualifier. Return if it is blank.
      IF( EQUALS .EQ. 1 .OR. SETTNG( : EQUALS - 1 ) .EQ. ' ' ) THEN
         NAME = ' '
         VALUE = SETTNG
         GO TO 999

      ELSE
         NAME = SETTNG( : EQUALS - 1 )
         CALL CHR_RMBLK( NAME )
         CALL CHR_UCASE( NAME )
      END IF

*  Store everything after the equals as the attribute value.
      IF( EQUALS .LT. LEN( SETTNG ) ) THEN
         VALUE = SETTNG( EQUALS + 1 : )
      ELSE
         VALUE = ' '
      END IF

*  Replace synonyms in the attribute name/qualifier.
*  =================================================

*  See if any synonymns are available. This is the case if both group 
*  identifiers supplied in common (KPG_AST) are valid.
      CALL GRP_VALID( KPG1_GETASTING(), VALID1, STATUS )
      CALL GRP_VALID( KPG1_GETASTOUG(), VALID2, STATUS )
      IF( VALID1 .AND. VALID2 ) THEN

*  Check for each synonym in turn. 
         DO J = 1, KPG1_GETASTNPS()

*  Get the synonym and its corresponding attribute name.
            CALL GRP_GET( KPG1_GETASTING(), J, 1, SY, STATUS )
            CALL GRP_GET( KPG1_GETASTOUG(), J, 1, TRAN, STATUS )

*  See if the synonym contains a qualifier (i.e. a string in parenthesise).
            CALL KPG1_PRNTH( SY, OP, CL, STATUS )

*  Get the length of the attribute name (i.e. the string in front of
*  any qualifier) in the synonym.
            IF( OP .EQ. 0 ) THEN  
               NPLEN = CHR_LEN( SY )
            ELSE
               NPLEN = OP - 1
            END IF

*  See if the synonym translation contains a qualifier.
            CALL KPG1_PRNTH( TRAN, OP1, CL1, STATUS )

*  Get the length of the attribute name in the translation.
            IF( OP1 .EQ. 0 ) THEN  
               NRLEN = CHR_LEN( TRAN )
            ELSE
               NRLEN = OP1 - 1
            END IF

*  See if the supplied name/qualifier contains a qualifier.
            CALL KPG1_PRNTH( NAME, OP2, CL2, STATUS )

*  Get the length of the attribute name in the supplied text.
            IF( OP2 .EQ. 0 ) THEN  
               NTLEN = CHR_LEN( NAME )
            ELSE
               NTLEN = OP2 - 1
            END IF

*  Indicate that as yet we have no attribute name or qualifier to return.
            ANAME = ' '
            AQUAL = ' '

*  See if the attribute name in the supplied text matches the attribute
*  name in the synonym. A blank name in the synonym matches any supplied
*  name, in which case retain the supplied attribute name.
            IF( NPLEN .EQ. 0 ) THEN
               NMATCH = .TRUE.
               ANAME = NAME( : NTLEN )

*  If the synonym contains an attribute name, see if it matches the
*  supplied attribute name. If it does, use the translated name, or
*  (if the translation contained no name) the supplied name.
            ELSE 
               IF( NTLEN .GT. 0 ) THEN
                  IF( SY( : NPLEN ) .EQ. NAME( : NTLEN ) ) THEN
                     NMATCH = .TRUE.
                  ELSE
                     NMATCH = .FALSE.
                  END IF
               ELSE
                  NMATCH = .FALSE.
               END IF

*  If it does, and if the translation contains an attribute name, return the 
*  attribute name from the translation. Otherwise, use the supplied name.
               IF( NMATCH .AND. NRLEN .GT. 0 ) THEN
                  ANAME = TRAN( : NRLEN )

               ELSE IF( NTLEN .GT. 0 ) THEN
                  ANAME = NAME( : NTLEN )

               END IF

            END IF

*  Now see if the qualifier in the supplied text matches the qualiier
*  in the synonym. A blank qualifier in the synonym matches any supplied
*  qualifier, so retain the supplied qualifier. If there is no supplied
*  qualifier, use any qualifier in the translation.
            IF( OP + 1 .GT. CL - 1 ) THEN
               QMATCH = .TRUE.
               IF( CL2 .GT. OP2 + 1 ) THEN
                  AQUAL = NAME( OP2 : CL2 )
               ELSE IF( CL1 .GT. OP1 + 1 ) THEN
                  AQUAL = TRAN( OP1 : CL1 )
               END IF

*  If the synonym contains a qualifier, but there is no supplied qualifier
*  the qualifiers do not match.
            ELSE IF( OP2 + 1 .GT. CL2 - 1 ) THEN
               QMATCH = .FALSE.

*  If both the synonym and supplied string contain qualifiers, see if they
*  match, allowing minimum abbreviations indicated by an asterisk in 
*  the synonym. The comparison is case insensitive. If it does, use the 
*  qualifier from the synonym translation (if any).
            ELSE IF( KPG1_SHORT( SY( OP + 1 : CL - 1 ),
     :                           NAME( OP2 + 1 : CL2 - 1 ),
     :                           '*', .FALSE., STATUS ) ) THEN
               QMATCH = .TRUE.
               IF( OP1 .GT. 0 ) AQUAL = TRAN( OP1 : CL1 )

*  Otherwise, the qualifiers do not match.
            ELSE
               QMATCH = .FALSE.
            END IF

*  If both name and qualifier match, construct a new attribute name + 
*  qualifier string.
            IF( QMATCH .AND. NMATCH ) THEN 
               NAME = ' '
               IAT = 0
               CALL CHR_APPND( ANAME, NAME, IAT )
               CALL CHR_APPND( AQUAL, NAME, IAT )
            END IF

         END DO

      END IF

*  Replace colour names in the attribute value
*  ===========================================

*  Abort if an error has occurred.
      IF( STATUS .NE. SAI__OK ) GO TO 999    

*  This setting sets a colour attribute if the name/qualifier contains 
*  either of the strings COLOR or COLOUR.
      IF( INDEX( NAME, 'COLOR' ) .NE. 0 .OR.
     :    INDEX( NAME, 'COLOUR') .NE. 0 )  THEN

*  See if PGPLOT is currently active. Assume a colour index of zero if not.
         CALL PGQID( ID )
         IF( ID .LE. 0 ) THEN
            COLIND = 0

*  Otherwise, get the number of colour indices available on the current 
*  device, and find the colour index corresponding to the attribute value. 
*  An error will be reported if the attribute value cannot be interpreted 
*  as a colour specification.
         ELSE
            CALL PGQCOL( DOWN, UP )
            CALL KPG1_PGCOL( VALUE, MIN( CTM__RSVPN, UP ), UP, COLIND,
     :                       STATUS )
         END IF

*  If the colour was not known, annul the error. The calling routine will then
*  continue in an attempt to use the colour as an AST attribute value and
*  will fail. An error will then be reported including the whole
*  attribute string.
         IF( STATUS .NE. SAI__OK ) THEN
            CALL ERR_ANNUL( STATUS )
   
*  If the colour was found, replace its name with the colour index.
         ELSE
            VALUE = ' '
            CALL CHR_ITOC( COLIND, VALUE, NCH )
         END IF
   
      END IF

 999  CONTINUE

      END
