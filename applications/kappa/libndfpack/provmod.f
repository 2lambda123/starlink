      SUBROUTINE PROVMOD( STATUS )
*+
*  Name:
*     PROVMOD

*  Purpose:
*     Modifies provenance information for an NDF.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL PROVMOD( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application modifies the provenance information stored in 
*     the PROVENANCE extension of an NDF. 

*  Usage:
*     provmod ndf ancestor path

*  ADAM Parameters:
*     ANCESTOR = LITERAL (Update)
*        Specifies the indices of one or more ancestors that are to be
*        modified.  An index of zero refers to the supplied NDF itself.
*        A positive index refers to one of the NDFs listed in the 
*        ANCESTORS table in the PROVENANCE extension of the NDF. The maximum 
*        number of ancestors is limited to 100 unless "ALL" or "*" is 
*        specified.  The supplied parameter value can take any of the 
*        following forms.
*
*        - "ALL" or "*" --  All ancestors.
*
*        - "xx,yy,zz" -- A list of anestor indices.
*
*        - "xx:yy" --  Ancestor indices between xx and yy inclusively.  When
*        xx is omitted the range begins from 0; when yy is omitted the range 
*        ends with the maximum value it can take, that is the number of 
*        ancestors described in the PROVENANCE extension.
*
*        - Any reasonable combination of above values separated by 
*        commas. ["ALL"]
*     CREATOR = LITERAL (Read)
*        Specifies one or more substitutions to be performed on the "CREATOR"
*        string read from each of the ancestors being modified. See
*        "Substitution Syntax:" below. If null (!) is supplied, the PATH
*        item is left unchanged. [!]
*     DATE = LITERAL (Read)
*        Specifies one or more substitutions to be performed on the "DATE"
*        string read from each of the ancestors being modified. See
*        "Substitution Syntax:" below. An error will be reported if any of
*        these substitutions result in a string that is not a valid date 
*        and time string. If null (!) is supplied, the PATH item is left 
*        unchanged. [!]
*     NDF = NDF (Update)
*        The NDF data structure.
*     PATH = LITERAL (Read)
*        Specifies one or more substitutions to be performed on the "PATH"
*        string read from each of the ancestors being modified. See
*        "Substitution Syntax:" below. If null (!) is supplied, the PATH
*        item is left unchanged. [!]

*  Examples:
*     provrem ff path='(_x)$=_y'
*        This modifies any ancestor within the NDF called ff that has a
*        path ending in "_x" by replacing the final "_x" with "_y".
*     provrem ff path='(_x)$=_y'
*        This modifies any ancestor within the NDF called ff that has a
*        path ending in "_x" by replacing the final "_x" with "_y".
*     provrem ff path='(.*)_(.*)=$2=$1'
*        This modifies any ancestor within the NDF called ff that has a
*        path consisting of two parts separated by an underscore by
*        swapping the parts. If there is more than one underscore in the
*        ancestor path, then the final underscore is used (because the
*        initial quantifier ".*" is greedy).
*     provrem ff path='(.*?)_(.*)=$2=$1'
*        This modifies any ancestor within the NDF called ff that has a
*        path consisting of two parts separated by an underscore by
*        swapping the parts. If there is more than one underscore in the
*        ancestor path, then the first underscore is used (because the
*        initial quantifier ".*?" is not greedy).

*  Substitution Syntax:
*     The syntax for the CREATOR, DATE and PATH parameter values is a 
*     minimal form of regular expression. The following atoms are allowed:
*
*     "[chars]" - Matches any of the characters within the brackets.
*     "[^chars]" - Matches any character that is not within the brackets
*                  (ignoring the initiual "^" character).
*     "." - Matches any single character.
*     "\d" - Matches a single digit.
*     "\D" - Matches anything but a single digit.
*     "\w" - Matches any alphanumeric character, and "_".
*     "\W" - Matches anything but alphanumeric characters, and "_".
*     "\s" - Matches white space.
*     "\S" - Matches anything but white space.
*
*     Any other character that has no special significance within a
*     regular expression matches itself. Characters that have special
*     significance can be matched by preceeding them with a backslash
*     (\) in which case their special significance is ignored (note, this
*     does not apply to the characters in the set dDsSwW).
*
*     Note, minus signs ("-") within brackets have no special significance, 
*     so ranges of characters must be specified explicitly.
*
*     The following quantifiers are allowed:
*
*     "*" - Matches zero or more of the preceeding atom, choosing the
*           largest posible number that gives a match.
*     "*?"- Matches zero or more of the preceeding atom, choosing the
*           smallest posible number that gives a match.
*     "+" - Matches one or more of the preceeding atom, choosing the
*           largest posible number that gives a match.
*     "+?"- Matches one or more of the preceeding atom, choosing the
*           smallest posible number that gives a match.
*     "?" - Matches zero or one of the preceeding atom.

*     The following constraints are allowed:
*
*     "^" - Matches the start of the test string.
*     "$" - Matches the end of the test string.
* 
*     Multiple templates can be concatenated, using the "|" character to 
*     separate them. The test string is compared against each one in turn 
*     until a match is found. 
*
*     A template should use parentheses to enclose the sub-strings that 
*     are to be replaced, and the set of corresponding replacement values 
*     should be appended to the end of the string, separated by "="
*     characters. The section of the test string that matches the first 
*     parenthesised section in the template string will be replaced by the 
*     first replacement string. The section of the test string that matches 
*     the second parenthesised section in the template string will be 
*     replaced by the second replacement string, and so on.
*
*     The replacement strings can include the tokens "$1", "$2", etc.
*     The section of the test string that matched the corresponding 
*     parenthesised section in the template is used in place of the token.
*
*     See the "Examples" section above for how to use these facilities.

*  Related Applications:
*     KAPPA: PROVADD, PROVREM, PROVSHOW.

*  Copyright:
*     Copyright (C) 2008 Science & Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either Version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
*     02111-1307, USA.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     26-FEB-2008 (DSB):
*        Original version.
*     {enter_further_changes_here}

*-
*  Type Definitions:
      IMPLICIT NONE              ! no default typing allowed

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'CNF_PAR'          ! CNF constants and functions
      INCLUDE 'PAR_ERR'          ! PAR error constants 
      INCLUDE 'AST_PAR'          ! AST constants and cuntions
      INCLUDE 'DAT_PAR'          ! HDS constants 

*  Status:
      INTEGER STATUS

*  External References:
      LOGICAL CHR_SIMLR          ! Case blind string comparison
      INTEGER CHR_LEN            ! Used length of a string

*  Local Constants:
      INTEGER MXANC              ! Max. no. of selected ancestors
      PARAMETER( MXANC = 100 )

*  Local Variables:
      CHARACTER ANC*20           ! ANCESTOR parameter value
      CHARACTER CRESUB*400       ! Substitution string
      CHARACTER DATSUB*400       ! Substitution string
      CHARACTER LOC*(DAT__SZLOC) ! Locator for required component
      CHARACTER PROV*(DAT__SZLOC)! Locator for provenance store
      CHARACTER PTHSUB*400       ! Substitution string
      CHARACTER RESULT*400       ! result of substitutions
      CHARACTER TEST*400         ! String to be tested
      INTEGER I                  ! Ancestor index
      INTEGER IANC( MXANC )      ! Indices of selected ancestors
      INTEGER INDF               ! NDF identifier
      INTEGER IPW1               ! Pointer to work space
      INTEGER J                  ! Ancestor count
      INTEGER K                  ! Substitution count
      INTEGER L                  ! String len
      INTEGER MANC               ! Number of selected ancestors
      INTEGER NANC               ! Total number of ancestors
      LOGICAL DOALL              ! Modify all ancestors?
      LOGICAL THERE              ! Does component exist?
*.


*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Obtain an identifier for the NDF.
      CALL LPG_ASSOC( 'NDF', 'UPDATE', INDF, STATUS )

*  Get the number of ancestors described in the NDFs PROVENANCE 
*  extension.
      CALL NDG_CTPRV( INDF, NANC, STATUS )

*  Get the indices of the ancestors to be modified. Since KPG1_GILST 
*  limits the number of values that can be supplied, first check the
*  parameter value directly to see if it set to "ALL". If so, we bypass 
*  KPG1_GILST, setting a flag instead to show that all ancestors should
*  be modified.
      CALL PAR_GET0C( 'ANCESTOR', ANC, STATUS )
      IF( CHR_SIMLR( ANC, 'ALL' ) .OR. ANC .EQ. '*' ) THEN
         DOALL = .TRUE.
         MANC = NANC + 1
      ELSE
         DOALL = .FALSE.
         CALL PSX_CALLOC( NANC + 1, '_INTEGER', IPW1, STATUS )
         CALL KPG1_GILST( 0, NANC, MXANC, 'ANCESTOR', 
     :                    %VAL( CNF_PVAL( IPW1 ) ), IANC, MANC,
     :                    STATUS )
         CALL PSX_FREE( IPW1, STATUS )
      END IF

*  If an error occurred, exit.
      IF ( STATUS .NE. SAI__OK ) GO TO 999

*  Get the substitutions. 
      CALL PAR_GET0C( 'CREATOR', CRESUB, STATUS )
      IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         CRESUB = ' ' 
      END IF

      CALL PAR_GET0C( 'DATE', DATSUB, STATUS )
      IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         DATSUB = ' ' 
      END IF

      CALL PAR_GET0C( 'PATH', PTHSUB, STATUS )
      IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         PTHSUB = ' ' 
      END IF

*  Loop round all the ancestors that are to be modified.
      DO J = 1, MANC

*  Get the index of the next ancestor to be modified.
         IF( DOALL ) THEN
            I = J - 1
         ELSE
            I = IANC( J )        
         END IF

*  Get a temporary HDS structure holding the existing provenance
*  information for the specified ancestor.
         CALL NDG_GTPRV( INDF, I, PROV, STATUS )

*  Does the information for this ancestor include a CREATOR string? If
*  so, get its value.
         IF( CRESUB .NE. ' ' ) THEN
            CALL DAT_THERE( PROV, 'CREATOR', THERE, STATUS )
            IF( THERE ) THEN
               CALL DAT_FIND( PROV, 'CREATOR', LOC, STATUS )
               CALL DAT_GET0C( LOC, TEST, STATUS )

*  If the specifier matches the CREATOR string, perform the substitutions
*  and use the resulting string in place of the current CREATOR string.
               IF( AST_CHRSUB( TEST, CRESUB, RESULT, STATUS ) ) THEN
                  TEST = RESULT
               END IF

*  Put the modified string back into the HDS structure containing the
*  information for the current ancestor.
               CALL DAT_ANNUL( LOC, STATUS )
               CALL DAT_ERASE( PROV, 'CREATOR', STATUS )
               L = MAX( 1, CHR_LEN( TEST ) )
               CALL DAT_NEW0C( PROV, 'CREATOR', L, STATUS )
               CALL DAT_FIND( PROV, 'CREATOR', LOC, STATUS )
   
               CALL DAT_PUT0C( LOC, TEST( : L ), STATUS )
               CALL DAT_ANNUL( LOC, STATUS )
            END IF
         END IF

*  Does the information for this ancestor include a DATE string? If
*  so, get its value.
         IF( DATSUB .NE. ' ' ) THEN
            CALL DAT_THERE( PROV, 'DATE', THERE, STATUS )
            IF( THERE ) THEN
               CALL DAT_FIND( PROV, 'DATE', LOC, STATUS )
               CALL DAT_GET0C( LOC, TEST, STATUS )

*  If the specifier matches the DATE string, perform the substitutions
*  and use the resulting string in place of the current DATE string.
               IF( AST_CHRSUB( TEST, DATSUB, RESULT, STATUS ) ) THEN
                  TEST = RESULT
               END IF

*  Put the modified string back into the HDS structure containing the
*  information for the current ancestor.
               CALL DAT_ANNUL( LOC, STATUS )
               CALL DAT_ERASE( PROV, 'DATE', STATUS )
               L = MAX( 1, CHR_LEN( TEST ) )
               CALL DAT_NEW0C( PROV, 'DATE', L, STATUS )
               CALL DAT_FIND( PROV, 'DATE', LOC, STATUS )
   
               CALL DAT_PUT0C( LOC, TEST( : L ), STATUS )
            END IF
         END IF

*  Does the information for this ancestor include a PATH string? If
*  so, get its value.
         IF( PTHSUB .NE. ' ' ) THEN
            CALL DAT_THERE( PROV, 'PATH', THERE, STATUS )
            IF( THERE ) THEN
               CALL DAT_FIND( PROV, 'PATH', LOC, STATUS )
               CALL DAT_GET0C( LOC, TEST, STATUS )

*  If the specifier matches the PATH string, perform the substitutions
*  and use the resulting string in place of the current PATH string.
               IF( AST_CHRSUB( TEST, PTHSUB, RESULT, STATUS ) ) THEN
                  TEST = RESULT
               END IF

*  Put the modified string back into the HDS structure containing the
*  information for the current ancestor.
               CALL DAT_ANNUL( LOC, STATUS )
               CALL DAT_ERASE( PROV, 'PATH', STATUS )
               L = MAX( 1, CHR_LEN( TEST ) )
               CALL DAT_NEW0C( PROV, 'PATH', L, STATUS )
               CALL DAT_FIND( PROV, 'PATH', LOC, STATUS )
   
               CALL DAT_PUT0C( LOC, TEST( : L ), STATUS )
               CALL DAT_ANNUL( LOC, STATUS )
            END IF
         END IF

*  Store the modified provenance information back in the NDF.
         CALL NDG_MDPRV( INDF, I, PROV, STATUS )

*  Annul the locator for the ancestor information.
         CALL DAT_ANNUL( PROV, STATUS )

      END DO

*  Arrive here if an error occurs.
 999  CONTINUE

*  Annul the NDF identifier.
      CALL NDF_ANNUL( INDF, STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

*  If an error occurred, then report a contextual message.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'PROVMOD_ERR', 'PROVMOD: Failed to modify '//
     :                 'provenance information in an NDF.', STATUS )
      END IF

      END
