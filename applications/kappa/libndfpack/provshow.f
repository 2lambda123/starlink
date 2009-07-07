      SUBROUTINE PROVSHOW( STATUS )
*+
*  Name:
*     PROVSHOW

*  Purpose:
*     Displays provenance information for an NDF.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL PROVSHOW( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application displays details of the NDFs that were used in
*     the creation of the supplied NDF. This information is read from
*     the PROVENANCE extension within the NDF, and includes both
*     immediate parent NDFs and older ancestor NDFs (i.e. the parents of
*     the parents, etc.).
*
*     Each displayed NDF (see parameter SHOW) is described in a
*     block of lines. The first line holds an integer index for the NDF
*     followed by the path to that NDF. Note, this path is where the NDF
*     was when the provenance information was recorded. It is of course 
*     possible that the NDF may subsequently have been moved or deleted.
*
*     The remaining lines in the NDF description are as follows:
*
*       "Parents" -- A comma-separated list of integers that are the 
*       indices of the immediate parents of the NDF.  These are the
*       integers that are displayed on the first line of each NDF 
*       description.
*
*       "Date" -- The formatted UTC date and time at which the 
*       provenance information for the NDF was recorded.
*
*       "Creator" -- A string identifying the software that created the
*       NDF.
*
*       "More" -- A summary of any extra information about the NDF 
*       stored with the provenance information.  In general this may be 
*       an arbitrary HDS structure and so full details cannot be given 
*       on a single line.  The HDSTRACE command can be used to examine 
*       the MORE field in detail.  To see full details of the NDF with 
*       "ID" value of 12 (say), enter (from a UNIX shell)
*       "hdstrace fred.more.provenance.ancestors'(12)'", where "fred" is
*       the name of the NDF supplied for parameter "NDF".  If the NDF 
*       has no extra information, this item will not be present.
*
*       "History" -- This is only displayed if parameter HISTORY is set
*       to a TRUE value. It contains information copied from the History
*       component of the ancestor NDF. See Parameter HISTORY.
*
*    In addition, a text file can be created containing the paths for the
*    direct parents of the supplied NDF. See Parameter PARENTS.

*  Usage:
*     provshow ndf [show]

*  ADAM Parameters:
*     HISTORY = _LOGICAL (Read)
*        If TRUE, any history records stored with each ancestor are
*        included in the displayed information. Since the amount of
*        history information displayed can be large, and thus swamp other 
*        information, the default is not to display history information.
*
*        When an existing NDF is used in the creation of a new NDF, the
*        provenance system will copy selected records from the HISTORY
*        component of the existing NDF and store them with the provenance
*        information in the new NDF. The history records copied are those
*        that describe operations performed on the existing NDF itself.
*        Inherited history records that describe operations performed on 
*        ancestors of the existing NDF are not copied. [FALSE]
*     NDF = NDF (Read)
*        The NDF data structure.
*     PARENTS = FILENAME (Read)
*        Name of a new text file in which to put the paths to the direct
*        parents of the supplied NDF. These are written one per line with
*        no extra text. If null, no file is created. [!]
*     HIDE = _LOGICAL (Read)
*        If TRUE, then any ancestors which are flagged as "hidden" (for
*        example, using PROVREM) are excluded from the display. If FALSE, 
*        then all requested ancestors, whether hidden or not, are included 
*        in the display (but hidden ancestors will be highlighted as such). 
*        Note, choosing to exclude hidden ancestors may change the index 
*        displayed for each ancestor. The default is to display hidden 
*        ancestors if and only if history is being displayed (see parameter 
*        HISTORY). []
*     SHOW = LITERAL (Read)
*        Determines which ancestors are displayed on the screen. It can
*        take any of the following case-insensitive values (or any 
*        abbreviation).
*
*        - "All" -- Display all ancestors, including the supplied NDF
*                   itself.
*
*        - "Roots" -- Display only the root ancestors (i.e. ancestors that
*                    do not themselves have any recorded parents). The 
*                    supplied NDF itself is not displayed.
*
*        - "Parents" -- Display only the direct parents of the supplied
*                       NDF. The supplied NDF itself is not displayed.
*
*        ["All"]

*  Notes:
*     - An input NDF is included in the provenance of an output NDF only
*     if the Data component of the input NDF is mapped for read or update
*     access by the application. In other words, input NDFs which are
*     accessed only for their meta-data (e.g. WCS information) are not 
*     included in the output provenance of an application.
*     - If a KAPPA application uses one or more input NDFs to create an 
*     output NDF, the output NDF may or may not contain provenance 
*     information depending on two things: 1) whether any of the
*     input NDFs already contain provenance information, and 2) the
*     value of the AUTOPROV environment variable. It is usually 
*     necessary to set the AUTOPROV variable to "1" in order to create 
*     output NDFs that contain provenance information.  The exception to
*     this if you are supplied with NDFs from another source that 
*     already contain provenance.  If such NDFs are used as inputs to 
*     KAPPA applications, then the output NDFs will contain provenance 
*     even if the AUTOPROV variable is unset.  However, setting AUTOPROV
*     to "0" will always prevent provenance information being stored in 
*     the output NDFs.
*     - Some other packages, such as CCDPACK, follow the same strategy
*     for creating and propagating provenance information.

*  Examples:
*     provshow m51 
*        This displays information about the NDF m51, and all its
*        recorded ancestors.
*     provshow m51 roots
*        This displays information about the root ancestors of the NDF 
*        m51. 
*     provshow m51 parents
*        This displays information about the direct parents of the NDF 
*        m51. 

*  Related Applications:
*     KAPPA: PROVADD, HISLIST.

*  Copyright:
*     Copyright (C) 2008-2009 Science & Technology Facilities Council.
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
*     DSB: David Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     9-JAN-2008 (DSB):
*        Original version.
*     7-FEB-2008 (DSB):
*        Added parameter PARENTS.
*     12-AUG-2008 (DSB):
*        Added parameter SHOW.
*     16-APR-2009 (DSB):
*        Corrected use of SHOW=ROOTS.
*     25-JUN-2009 (DSB):
*        Updated to use new provenance API. Added parameter HISTORY.
*     3-JUL-2009 (DSB):
*        Correct formatting of history info to avoid truncating the last
*        character.
*     7-JUL-2009 (DSB):
*        Add the HIDE parameter.
*     {enter_further_changes_here}

*-
*  Type Definitions:
      IMPLICIT NONE              ! no default typing allowed

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PAR_ERR'          ! PAR error constants 
      INCLUDE 'DAT_PAR'          ! DAT constants 
      INCLUDE 'AST_PAR'          ! AST constants 

*  Status:
      INTEGER STATUS

*  External References:
      INTEGER CHR_LEN            ! Used length of a string

*  Local Constants:
      INTEGER MXPAR              ! Max number of direct parents
      PARAMETER( MXPAR = 200 )

      INTEGER MXREC              ! Max number of history records
      PARAMETER( MXREC = 100 )

*  Local Variables:
      CHARACTER ID*10            ! Integer index for the current NDF
      CHARACTER KEY*20           ! Key for entry within KeyMap
      CHARACTER MORE*(DAT__SZLOC)! Locator for MORE info
      CHARACTER PARIDS*255       ! Buffer for direct parent ID list
      CHARACTER SHOW*7           ! The ancestors to be displayed
      CHARACTER VALUE*255        ! Buffer for one field value
      INTEGER DIRPAR( MXPAR )    ! Integer IDs for direct parents
      INTEGER FD                 ! File descriptor for parents file
      INTEGER IEND               ! Index of word end
      INTEGER INDF               ! NDF identifier
      INTEGER INTID              ! Integer ID for the current ancestor
      INTEGER IPAR               ! Index into list of parent indices
      INTEGER IPROV              ! Identifier for provenance structure
      INTEGER IPROV2             ! Identifier for cleansed prov structure
      INTEGER IREC               ! Index of current history record
      INTEGER IROW               ! Row index
      INTEGER ISTART             ! Index of word start
      INTEGER KM                 ! KeyMap holding ancestor info
      INTEGER KMHIST( MXREC )    ! KeyMaps holding history records
      INTEGER KMP                ! KeyMap holding parent info
      INTEGER KYMAP1             ! AST KeyMap holding all prov info
      INTEGER KYMAP2             ! AST KeyMap holding field widths
      INTEGER L                  ! Used length of returned string
      INTEGER NC                 ! String length
      INTEGER NPAR               ! Number of direct parents
      INTEGER NREC               ! Number of history records
      INTEGER NROW               ! No. of lines to display
      INTEGER PARI               ! Index of current parent in ancestors
      LOGICAL FIRST              ! Is this the first word?
      LOGICAL HIDDEN             ! Is current ancestor hidden?
      LOGICAL HIDE               ! Exclude hidden ancestors?
      LOGICAL HIST               ! Display history info?
      LOGICAL THERE              ! Does the named component exist?
      LOGICAL USE                ! Display the current ancestor?
*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Obtain an identifier for the NDF.
      CALL LPG_ASSOC( 'NDF', 'READ', INDF, STATUS )

*  Determine which ancestors are to be displayed on the screenn.
      CALL PAR_CHOIC( 'SHOW', 'All', 'All,Roots,Parents', .FALSE., SHOW, 
     :                STATUS )

*  See if history information is to be displayed.
      CALL PAR_GET0L( 'HISTORY', HIST, STATUS )

*  Read provenance information from the NDF.
      CALL NDG_READPROV( INDF, ' ', IPROV, STATUS )

*  See if hidden ancestors are to be excluded from the display.
      CALL PAR_DEF0L( 'HIDE', .NOT. HIST, STATUS )
      CALL PAR_GET0L( 'HIDE', HIDE, STATUS )

*  If we are excluding hidden ancestors create a copy of the provenance 
*  structure from which all hidden ancestors have been removed.
      IF( HIDE ) THEN
         CALL NDG_COPYPROV( IPROV, .TRUE., IPROV2, STATUS )
         CALL NDG_FREEPROV( IPROV, STATUS )
         IPROV = IPROV2
      END IF

*  Format the provenance information. The resulting strings are returned in 
*  an AST KeyMap.
      CALL NDG_FORMATPROV( IPROV, .FALSE., KYMAP1, STATUS )

*  Get the number of entries in the returned keymap. This will be one
*  more than the number of NDFs described in the displayed table.
      NROW = AST_MAPSIZE( KYMAP1, STATUS ) - 1

*  Loop round each NDF to be described.
      DO IROW = 1, NROW 

*  Get the KeyMap holding details for this row.
         CALL CHR_ITOC( IROW - 1, KEY, NC )
         IF( .NOT. AST_MAPGET0A( KYMAP1, KEY( : NC ), KYMAP2, 
     :                           STATUS ) ) THEN
            STATUS = SAI__ERROR
            IF( STATUS .EQ. SAI__OK ) THEN
               CALL MSG_SETI( 'I', IROW )
               CALL ERR_REP( ' ', 'No "^I" entry found in KeyMap '//
     :                       'returned by NDG_FORMATPROV (programming'//
     :                       ' error).', STATUS )
            END IF
            GO TO 999
         END IF

*  Get the ID value for this ancestor.
         ID = ' '
         IF( .NOT. AST_MAPGET0C( KYMAP2, 'ID', ID, NC, STATUS ) ) THEN
            IF( STATUS .EQ. SAI__OK ) THEN
               STATUS = SAI__ERROR
               CALL ERR_REP( ' ', 'No "ID" entry found in KeyMap '//
     :                       'returned by NDG_FORMATPROV (programming'//
     :                       ' error).', STATUS )
            END IF
            GO TO 999
         END IF

* Convert teh ID to an integer (the ancestor index).
         CALL CHR_CTOI( ID, INTID, STATUS )

*  Get the list of direct parent ID values for this ancestor.
         PARIDS = ' '
         IF( .NOT. AST_MAPGET0C( KYMAP2, 'PARENTS', PARIDS, NC, 
     :                           STATUS ) ) THEN
            PARIDS = '<unknown>'
         END IF

*  Decide if this ancestor should be displayed. This depends on the value
*  supplied for parameter SHOW. If "ROOT" then only display this ancestor
*  if it has no direct parents. 
         IF( SHOW .EQ. 'ROOTS' ) THEN
            USE = ( PARIDS .EQ. '<unknown>' )

*  If "PARENTS" then only display this ancestor if its integer ID is 
*  included in the list of direct parent IDs stored when processing the
*  first row (if this is the first row then we always process it).
         ELSE IF( SHOW .EQ. 'PARENTS' ) THEN

*  If we are currently checking the first row, then we never display 
*  it, but we extract the direct parent ID values into an array of 
*  integers for use when checking subsequent rows.
            IF( IROW .EQ. 1 ) THEN
               USE = .FALSE.
               CALL KPG1_PRSAI( PARIDS, MXPAR, DIRPAR, NPAR, STATUS )

*  If this is not the first row, we only display it if its integer ID
*  value is in the list of direct parent IDs obtained when checking the
*  first row.
            ELSE
               USE = .FALSE.
               DO IPAR = 1, NPAR
                  IF( DIRPAR( IPAR ) .EQ. INTID ) USE = .TRUE.
               END DO

            END IF

*  For other values of SHOW, we display all ancestors.
         ELSE
            USE = .TRUE.
         END IF

*  Jump to the next row if we are not displaying the current row. 
         IF( USE ) THEN

*  White space between NDF descriptions.
            CALL MSG_BLANK( STATUS )

*  First line starts with the ID value followed by the NDF path.
            VALUE = ' '
            IF( .NOT. AST_MAPGET0C( KYMAP2, 'PATH', VALUE, NC, 
     :                              STATUS ) ) THEN
               VALUE = '<the NDF path is unknown>'
            END IF
	    
            CALL MSG_SETC( 'ID', ID )
            CALL MSG_SETC( 'P', VALUE )
            CALL MSG_OUT( ' ', '^ID: ^P', STATUS )

*  Next, if hidden ancestors are being included in the display, indicate 
*  if this ancestor is flagged as hidden.
            IF( .NOT. HIDE ) THEN
               CALL NDG_ISHIDDENPROV( IPROV, INTID, HIDDEN, STATUS )
               IF( HIDDEN ) CALL MSG_OUT( ' ', '   (This ancestor '//
     :                                    'has been hidden)', STATUS )
            END IF

*  Next line shows the list of identifiers for the immediate parent NDFs.
            CALL MSG_SETC( 'P', PARIDS )
            CALL MSG_OUT( ' ', '   Parents:  ^P', STATUS )

*  Next line shows the date at which the provenance was stored in the NDF.
            VALUE = ' '
            IF( .NOT. AST_MAPGET0C( KYMAP2, 'DATE', VALUE, NC, 
     :                              STATUS ) ) THEN
               VALUE = '<unknown>'
            END IF
	    
            CALL MSG_SETC( 'P', VALUE )
            CALL MSG_OUT( ' ', '   Date:  ^P', STATUS )

*  Next line shows the software that created the NDF.
            VALUE = ' '
            IF( .NOT. AST_MAPGET0C( KYMAP2, 'CREATOR', VALUE, NC, 
     :                              STATUS ) ) THEN
               VALUE = '<unknown>'
            END IF
	    
            CALL MSG_SETC( 'P', VALUE )
            CALL MSG_OUT( ' ', '   Creator:  ^P', STATUS )

*  Next line shows a summary of any extra info describing the NDF.
            VALUE = ' '
            IF( AST_MAPGET0C( KYMAP2, 'MORE', VALUE, NC, STATUS ) ) THEN
               CALL MSG_SETC( 'P', VALUE )
               CALL MSG_OUT( ' ', '   More:  ^P', STATUS )
            END IF

*  Next, display the history information (if required).
            IF( HIST .AND. ID .NE. '0' ) THEN

               IF( AST_MAPGET1A( KYMAP2, 'HISTORY', MXREC, NREC, 
     :                           KMHIST, STATUS ) ) THEN
                  CALL MSG_OUT( ' ', '   History:', STATUS )

                  DO IREC = 1, NREC               
                     VALUE = ' '
	       
                     IF( AST_MAPGET0C( KMHIST( IREC ), 'DATE', VALUE, 
     :                                 NC, STATUS ) ) THEN
                        CALL MSG_SETC( 'P', VALUE )
                        CALL MSG_OUT( ' ', '      Date:  ^P', STATUS )
                     END IF
	       
                     IF( AST_MAPGET0C( KMHIST( IREC ), 'COMMAND', VALUE, 
     :                                 NC, STATUS ) ) THEN
                        CALL MSG_SETC( 'P', VALUE )
                        CALL MSG_OUT( ' ', '      Command:  ^P', 
     :                                STATUS )
                     END IF
	       
                     IF( AST_MAPGET0C( KMHIST( IREC ), 'USER', VALUE,
     :                                 NC, STATUS ) ) THEN
                        CALL MSG_SETC( 'P', VALUE )
                        CALL MSG_OUT( ' ', '      User:  ^P', STATUS )
                     END IF
	       
                     IF( AST_MAPGET0C( KMHIST( IREC ), 'TEXT', VALUE, 
     :                                 NC, STATUS ) ) THEN

*  Text written by the NDF library starts with 'Parameters: '. Use the
*  colon-terminated words as the headers, and put a single word on each line.
                        IF( VALUE( : 12 ) .EQ. 'Parameters: ' ) THEN
                           FIRST = .TRUE.
			   
                           ISTART = 1
                           DO WHILE( VALUE( ISTART:ISTART ) .EQ. ' ' 
     :                               .AND. ISTART .LT. NC )
                              ISTART = ISTART + 1
                           END DO
			   
                           DO WHILE( ISTART .LE. NC ) 
			   
                              IEND = ISTART
                              DO WHILE( VALUE( IEND:IEND ) .NE. ' ' 
     :                                  .AND. IEND .LE. NC ) 
                                 IEND = IEND + 1
                              END DO

                              IEND = IEND - 1
                              IF( VALUE( IEND : IEND ) .EQ. ':' ) THEN
                                 CALL MSG_SETC( 'V', 
     :                                          VALUE( ISTART:IEND ) )
                                 CALL MSG_OUT( ' ', '      ^V', STATUS )
			   
                              ELSE IF( FIRST ) THEN
                                 CALL MSG_OUT( ' ', '      Text:', 
     :                                         STATUS )
			   
                              ELSE
                                 CALL MSG_SETC( 'V', 
     :                                          VALUE( ISTART:IEND ) )
                                 CALL MSG_OUT( ' ', '         ^V', 
     :                                         STATUS )
                              END IF
			   
                              ISTART = IEND + 1
                              DO WHILE( VALUE( ISTART:ISTART ) .EQ. ' ' 
     :                                  .AND. ISTART .LT. NC )
                                 ISTART = ISTART + 1
                              END DO
			   
                              FIRST = .FALSE.
                           END DO                           

*  If the text was not written by the NDF library, display it as a single
*  string.
                        ELSE
                           CALL MSG_SETC( 'P', VALUE )
                           CALL MSG_OUT( ' ', '      Text:  ^P', 
     :                                   STATUS )
                        END IF

                     END IF
	       
                     CALL MSG_BLANK( STATUS )
                     CALL AST_ANNUL( KMHIST( IREC ), STATUS )
                  END DO

               ELSE
                  CALL MSG_OUT( ' ', '   History:  <unknown>', STATUS )
               END IF
            END IF

         END IF

*  Annul the keymap holding details for this row.
         CALL AST_ANNUL( KYMAP2, STATUS )

      END DO

*  A final blank line.
      CALL MSG_BLANK( STATUS )

*  If required, create a text file containing the paths to the direct
*  parents of the supplied NDF.
*  ================================================================

*  Get an FIO file descriptor for the output file. Annul the error if no
*  file is needed.
      CALL FIO_ASSOC( 'PARENTS', 'WRITE', 'LIST', 255, FD, STATUS )
      IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )

*  If a file is being created, get the provenance information for the
*  supplied NDF. This includes the indices of the NDFs direct parents.
      ELSE
         CALL NDG_GETPROV( IPROV, 0, KM, MORE, STATUS )
         IF( MORE .NE. DAT__NOLOC ) CALL DAT_ANNUL( MORE, STATUS )

*  Check that the NDF has some parents.
         IF( AST_MAPHASKEY( KM, 'PARENTS', STATUS ) ) THEN

*  Loop round each integer index in the PARENTS component of the
*  NDFs provenance information. These are the indices of the NDFs direct
*  parents.
            NPAR = AST_MAPLENGTH( KM, 'PARENTS', STATUS )
            DO IPAR = 1, NPAR

*  Get the next parent index.
               THERE = AST_MAPGETELEMI( KM, 'PARENTS', IPAR, PARI, 
     :                                  STATUS ) 

*  Get the provenance information for the parent.
               CALL NDG_GETPROV( IPROV, PARI, KMP, MORE, STATUS )
               IF( MORE .NE. DAT__NOLOC ) CALL DAT_ANNUL( MORE, STATUS )

*  Check the provenance information includes a path to the parent file.
*  If so, get the path and write it to the output text file.
               IF( AST_MAPGET0C( KMP, 'PATH', VALUE, L, STATUS ) ) THEN
                  CALL FIO_WRITE( FD, VALUE( : L ), STATUS )
               END IF

*  Free resources. 
               CALL AST_ANNUL( KMP, STATUS )

*  Next parent.
            END DO

         END IF

*  Free the KeyMap holding the NDFs provenance information, and close the
*  output text file.
         CALL AST_ANNUL( KM, STATUS )
         CALL FIO_ANNUL( FD, STATUS )
      END IF

*  Arrive here if an error occurs.
 999  CONTINUE

*  Free the Provenance information.
      CALL NDG_FREEPROV( IPROV, STATUS )

*  Annul the NDF identifier.
      CALL NDF_ANNUL( INDF, STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

*  If an error occurred, then report a contextual message.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'PROVSHOW_ERR', 'PROVSHOW: Failed to display '//
     :                 'provenance information in an NDF.', STATUS )
      END IF

      END
