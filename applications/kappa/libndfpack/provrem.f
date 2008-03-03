      SUBROUTINE PROVREM( STATUS )
*+
*  Name:
*     PROVREM

*  Purpose:
*     Removes selected provenance information from an NDF.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL PROVREM( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application removes selected ancestors from the provenance
*     information stored in a given NDF. The "generation gap" caused by
*     removing an ancestor is bridged by assigning all the direct parents
*     of the removed ancestor to each of the direct children of the 
*     ancestor.
*
*     The ancestors to be removed can be specified either by giving their 
*     indicies (parameter ANCESTOR), or by comparing each ancestor with a
*     supplied pattern matching template (parameter PATTERN).

*  Usage:
*     provrem ndf pattern item

*  ADAM Parameters:
*     ANCESTOR = LITERAL (Update)
*        Specifies the indices of one or more ancestors that are to be
*        removed.  If a null (!) value is supplied, the ancestors to be
*        removed are instead determined using the PATTERN parameter. Each
*        supplied index must be positive and refers to one of the NDFs 
*        listed in the ANCESTORS table in the PROVENANCE extension of the 
*        NDF. The maximum number of ancestors that can be removed is 
*        limited to 100 unless "ALL", "*" or "!" is specified. The 
*        supplied parameter value can take any of the following forms.
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
*        commas. ["!"]
*     ITEM = LITERAL (Read)
*        Specifies the item of provenance information that is checked 
*        against the pattern matching template specified for parameter 
*        PATTERN. It can be "PATH", "CREATOR" or "DATE". ["PATH"]
*     NDF = NDF (Update)
*        The NDF data structure.
*     PATTERN = LITERAL (Read)
*        Specifies a pattern matching template using the syntax described
*        below in "Pattern Matching Syntax:". Each ancestor listed in the 
*        PROVENANCE extension of the NDF is compared with this template,
*        and each ancestor that matches is removed. The item of provenance 
*        information to be compared to the pattern is specified by parameter 
*        ITEM. 
*     REMOVE = _LOGICAL (Read)
*        If TRUE, then the ancestors specified by parameter PATTERN or
*        ANCESTORS are removed. Otherwise, these ancestors are retained 
*        and all other ancestors are removed. [TRUE]

*  Examples:
*     provrem ff ancestor=1
*        This removes the first ancestor from the NDF called ff.
*     provrem ff ancestor=all
*        This erases all provenance information.
*     provrem ff pattern='_xb$|_yb$'
*        This removes all ancestors that have paths that end with "_xb"
*        or "_yb". Note, provenance paths do not include a trailing ".sdf"
*        string.
*     provrem ff pattern='_ave'
*        This removes all ancestors that have paths that contain the
*        string "_ave" anywhere.
*     provrem ff pattern='_ave' remove=no
*        This removes all ancestors that have paths that do not contain 
*        the string "_ave" anywhere.
*     provrem ff pattern='_d[^/]*$'
*        This removes all ancestors that have file base-names that begin
*        with "_d". The pattern matches "_d" followed by any number of
*        characters that are not "/", followed by the end of the string.
*     provrem ff pattern='^m51|^m31'
*        This removes all ancestors that have paths that begin with "m51"
*        or "m31".

*  Pattern Matching Syntax:
*     The syntax for the PATTERN parameter value is a minimal form of 
*     regular expression. The following atoms are allowed:
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
*     "*" - Matches zero or more of the preceeding atom.
*     "+" - Matches one or more of the preceeding atom.
*     "?" - Matches zero or one of the preceeding atom.

*     The following constraints are allowed:
*
*     "^" - Matches the start of the test string.
*     "$" - Matches the end of the test string.
* 
*     Multiple templates can be concatenated, using the "|" character to 
*     separate them. The test string is compared against each one in turn 
*     until a match is found. 

*  Related Applications:
*     KAPPA: PROVADD, PROVMOD, PROVSHOW.

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
*     29-FEB-2008 (DSB):
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

*  Local Constants:
      INTEGER MXANC              ! Max. no. of selected ancestors
      PARAMETER( MXANC = 100 )

*  Local Variables:
      CHARACTER ANC*20           ! ANCESTOR parameter value
      CHARACTER ITEM*10          ! Item to check
      CHARACTER PAT*400          ! Pattern matching template
      CHARACTER PROV*(DAT__SZLOC)! Locator for provenance store
      CHARACTER RESULT*400       ! result of substitutions
      CHARACTER TEST*400         ! String to be tested
      INTEGER I                  ! Ancestor index
      INTEGER J                  ! Ancestor index
      INTEGER IANC( MXANC )      ! Indices of selected ancestors
      INTEGER INDF               ! NDF identifier
      INTEGER IPW1               ! Pointer to work space
      INTEGER NANC               ! Total number of ancestors
      INTEGER NREM               ! Number of ancestors removed
      LOGICAL REMOVE             ! Remove matching ancestors?
      LOGICAL THERE              ! Does component exist?
*.


*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Obtain an identifier for the NDF.
      CALL LPG_ASSOC( 'NDF', 'UPDATE', INDF, STATUS )

*  Count the number of ancestors in the NDF.
      CALL NDG_CTPRV( INDF, NANC, STATUS )

*  Initialise the number of ancestors removed.
      NREM = 0

*  See if specified ancestors are to be removed or retained.
      CALL PAR_GET0L( 'REMOVE', REMOVE, STATUS )

*  Abort if an error has occurred or there is no provenance information.
      IF( STATUS .NE. SAI__OK .OR. NANC .EQ. 0 ) GO TO 999   

*  See if a NULL value has been supplied for parameter ANCESTOR. If so,
*  annnul the error, and get the PATTERN and ITEM parameters.
      CALL PAR_GET0C( 'ANCESTOR', ANC, STATUS )
      IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )

         CALL PAR_GET0C( 'PATTERN', PAT, STATUS )
         CALL PAR_CHOIC( 'ITEM', 'PATH', 'PATH,DATE,CREATOR', .TRUE., 
     :                    ITEM, STATUS )

*  Loop round all ancestors 
         I = 1
         DO WHILE( I .LE. NANC - NREM )

*  Get a locator for a temporary HDS structure holding information about
*  the I'th ancestor.
            CALL NDG_GTPRV( INDF, I, PROV, STATUS )
            
*  Get the required item of information form the ancestor, use a blank
*  string if it is not there.
            TEST = ' '
            CALL DAT_THERE( PROV, ITEM, THERE, STATUS )
            IF( THERE ) CALL CMP_GET0C( PROV, ITEM, TEST, STATUS )

*  Annul the temporary HDS structure holding information about the I'th 
*  ancestor.
            CALL DAT_ANNUL( PROV, STATUS )

*  See if the pattern matches the item. If required, remove the ancestor.
            IF( REMOVE .EQV. 
     :          AST_CHRSUB( TEST, PAT, RESULT, STATUS ) ) THEN
               CALL NDG_RMPRV( INDF, I, STATUS )
               NREM = NREM + 1

*  If the ancestor was not removed, move on to check the ancestor with
*  the next higher index.
            ELSE
               I = I + 1
            END IF

         END DO

*  Otherwise, we remove the ancestors specified by parameter ANCESTOR.
      ELSE

*  Get the indices of the ancestors to be modified. Since KPG1_GILST 
*  limits the number of values that can be supplied, first check the
*  parameter value directly to see if it set to "ALL". If so, we just
*  erase the provenance extension.
         IF( CHR_SIMLR( ANC, 'ALL' ) .OR. ANC .EQ. '*' ) THEN
            CALL NDF_XSTAT( INDF, 'PROVENANCE', THERE, STATUS )
            IF( THERE ) CALL NDF_XDEL( INDF, 'PROVENANCE', STATUS )
            NREM = NANC

*  Otherwise, extract the list of ancestors to remove and remove each one
*  in turn.
         ELSE
            CALL PSX_CALLOC( NANC + 1, '_INTEGER', IPW1, STATUS )
            CALL KPG1_GILST( 0, NANC, MXANC, 'ANCESTOR', 
     :                       %VAL( CNF_PVAL( IPW1 ) ), IANC, NREM,
     :                       STATUS )
            CALL PSX_FREE( IPW1, STATUS )

*  Sort the ancestor indices.
            CALL KPG1_QSRTI( NREM, 1, NREM, IANC, STATUS )

*  If we are removing the specified ancestors, go through them in reverse 
*  order, removing each one.
            IF( REMOVE ) THEN 
               DO I = NREM, 1, -1
                  CALL NDG_RMPRV( INDF, IANC( I ), STATUS )
               END DO

*  If we are removing all except the specified ancestors, go through 
*  them in reverse order, removing each one that is not in the list of
*  specified ancestors.
            ELSE
               I = NANC
               J = NREM
               DO WHILE( I .GT. 0 )
                  IF( I .GT. IANC( J ) ) THEN
                     CALL NDG_RMPRV( INDF, I, STATUS )
                  ELSE
                     J = J - 1
                  END IF

                  I = I - 1
               END DO

            END IF

         END IF
      END IF

*  Arrive here if an error occurs.
 999  CONTINUE

*  Report the number of ancestors removed.
      IF( NREM .EQ. 0 ) THEN
         CALL MSG_OUT( ' ', '   No ancestors removed', STATUS )

      ELSE IF( NREM .EQ. 1 ) THEN
         CALL MSG_OUT( ' ', '   1 ancestor removed', STATUS )

      ELSE
         CALL MSG_SETI( 'N', NREM )
         CALL MSG_OUT( ' ', '   ^N ancestors removed', STATUS )
      END IF

      CALL MSG_BLANK( STATUS )

*  Annul the NDF identifier.
      CALL NDF_ANNUL( INDF, STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

*  If an error occurred, then report a contextual message.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'PROVREM_ERR', 'PROVREM: Failed to remove '//
     :                 'provenance information in an NDF.', STATUS )
      END IF

      END
