      SUBROUTINE FTS1_EDFEX( NKEY, EDITS, NAMES, PSTNS, KOCCUR, POCCUR,
     :                       VALUES, COMNTS, TYPES, FTSLOC, THERE,
     :                       STATUS )
*+
*  Name:
*     FTS1_EDFEX

*  Purpose:
*     Edits non-reserved keyword cards in a FITS extension of an NDF.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL FTS1_EDFEX( NKEY, EDITS, NAMES, PSTNS, KOCCUR, POCCUR,
*                      VALUES, COMNTS, TYPES, FTSLOC, THERE, STATUS )

*  Description:
*     This subroutine edits a number of non-reserved keyword cards in
*     the FITS extension of an NDF file.  This subroutine inserts,
*     updates, moves, deletes, reports, and tests the existence of a
*     number of keyword cards in the FITS extension of an NDF.  The
*     occurrence of keywords may be defined, when there are more than
*     one cards of the same name.  The location of each insertion or
*     move is immediately before some occurrence of a corresponding
*     keyword.
*
*     This routine itself merely deals with accessing and enlarging the
*     FITS extension, obtaining worksapce, and being able to pass the
*     mapped character arrays in the desired order to routine
*     FTS1_EDKEY via a dummy routine.  FTS1_EDKEY actually performs the
*     editing; look there for more details of the editing functions and
*     rules.

*  Arguments:
*     NKEY = INTEGER (Given)
*        The number of keyword cards to be inserted into the FITS
*        extension.
*     EDITS( NKEY ) = CHARACTER * ( * ) (Given)
*        The editing commands.  These need only be one character per
*        element.  Allowed values are 'Delete', 'Exist', 'Move',
*        'Rename', 'Print', 'Update', and 'Write', which can be
*        abbreviated to the initial letter.
*
*        'Delete' removes a named keyword.
*
*        'Exist' reports TRUE to standard output if the named keyword
*        exists in the header, and FALSE if the keyword is not present.

*        'Move' relocates a named keyword to be immediately before a
*        second keyword.  When this positional keyword is not supplied,
*        it defaults to the END card, and if the END card is absent,
*        the new location is at the end of the headers.
*
*        'Print' causes the value of a named keyword to be displayed to
*        standard output.  This will be a blank for a comment card.
*
*        'Rename' renames a keyword, using the value as the new keyword.
*
*        'Update' revises the value and/or the comment.  If a secondary
*        keyword is defined explicitly, the card may be relocated at
*        the same time.  If the secondary keyword does not exist, the
*        card being edited is not moved.  Update requires that the
*        keyword being edited exists.
*
*        'Write' creates a new card given a value and an optional
*        comment.  Its location uses the same rules as for the Move
*        command.
*     NAMES( NKEY ) = CHARACTER * ( * ) (Given)
*        The names of the keywords to be edited in the FITS card array.
*        A name may be compound to handle hierarchical keywords, and it
*        has the form keyword1.keyword2.keyword3 etc.  The maximum
*        number of keywords per FITS card is 20.  Each keyword must be
*        no longer than 8 characters, and be a valid FITS keyword
*        comprising alphanumeric characters, hyphen, and unsderscore.
*        Any lowercase letters are converted to uppercase and blanks
*        are removed before inserted or comparison with the existing
*        keywords.
*
*        The keywords ' ', 'COMMENT', and 'HISTORY' are comment cards
*        and do not have a value.
*
*        The keyword must exist except for the Write and Exist commands.
*     PSTNS( NKEY ) = CHARACTER * ( * ) (Given)
*        The position keyword names.  A position name may be compound
*        to handle hierarchical keywords, and it has the form
*        keyword1.keyword2.keyword3 etc.  The maximum number of
*        keywords per FITS card is 20.  Each keyword must be no longer
*        than 8 characters.  When locating the position card,
*        comparisons are made in uppercase and with the blanks removed.

*        The new keywords are inserted immediately before each
*        corresponding position keyword.  If any name in it does not
*        exist in FITS array, in the Write and Move edits its
*        corresponding keyword will be inserted just before the END
*        card or appended to FITS array when the END card does not
*        exist (for the Write and Move edits); however, the card is not
*        relocated for the Update edit.  If two or more new cards have
*        the same position name, they will all be put just before the
*        position name in the same order as they are in NAMES.
*
*        A positional keyword is used by the Move, Write, and Update
*        editing commands.
*     KOCCUR( NKEY ) = INTEGER (Given)
*        The occurrences of the NAMES keywords to use.  Values less than
*        or equal to 1 will manipulate the first occurrence of the
*        keyword to insert.
*     POCCUR( NKEY ) = INTEGER (Given)
*        The occurrences of the PSTNS keywords to use.  Values less than
*        or equal to 1 will situate the inserted keyword immediately
*        before the first occurrence of the positional keyword.
*     VALUES( NKEY ) = CHARACTER * ( * ) (Given)
*        The new values of the NAMES keywords for the Update and Write
*        editing commands.  The special value '$V' means use the
*        current value of the NAMES keyword.  This makes it possible to
*        modify a comment, leaving the value unaltered.  In addition
*        $V(keyword) requests that the value of the keyword given
*        between the parentheses be assigned to the keyword being
*        edited.  This positional keyword must exist and have a value
*        for a Write edit; whereas the FITS-header value is unchanged
*        for Update if there are problems with this positional keyword.
*        
*        For a Rename edit, VALUES has a different meaning; in this
*        case it stores the replacement keyword name.
*     COMNTS( NKEY ) = CHARACTER * ( * ) (Given)
*        The comments to be written to the NAMES keywords for the
*        Update and Write editing commands.  The special value '$C'
*        means use the current comment.  In addition $C(keyword)
*        requests that the comment of the keyword given between the
*        parentheses be assigned to the keyword being edited.  If this
*        positional keyword does not exist the comment is unchanged for
*        Update, and is blank for a Write edit.
*     TYPES( NKEY ) = CHARACTER * ( * ) (Given)
*        The data types of the values to Write or Update.  This does
*        allow some numeric or logical values to be written as strings.
*        These will be one of the following: '_CHAR',  '_DOUBLE',
*        '_INTEGER', '_LOGICAL', '_REAL'.  In addition there are two
*        special values: 'COMMENT' to indicate that the card is a
*        comment (so strictly it has no type), and ' ' to indicate that
*        the data type is unknown, as occurs for a value defined by a
*        reference keyword.  The length should be at least 8
*        characters.
*     FTSLOC = CHARACTER * ( * ) (Given)
*        The locator to the FITS extension of the NDF.
*     THERE = LOGICAL (Returned)
*        Result of final "Exist" operation.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Prior Requirements:
*     The FITS extension is mapped for update access.  It therefore must
*     have some values assigned before using the routine.

*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     DSB: David S. Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     1996 November 1 (MJC):
*        Original version based upon FTS1_PTKEY.
*     22-SEP-1999 (DSB):
*        Added argument THERE.
*     2004 September 1 (TIMJ):
*        Use CNF_PVAL
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! Data-system constants

*  Arguments Given:
      INTEGER NKEY
      CHARACTER * ( * ) EDITS( NKEY )
      CHARACTER * ( * ) NAMES( NKEY )
      CHARACTER * ( * ) PSTNS( NKEY )
      INTEGER KOCCUR( NKEY )
      INTEGER POCCUR( NKEY )
      CHARACTER * ( * ) VALUES( NKEY )
      CHARACTER * ( * ) COMNTS( NKEY )
      CHARACTER * ( * ) TYPES( NKEY )
      CHARACTER * ( * ) FTSLOC

*  Arguments Returned:
      LOGICAL THERE

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      INTEGER FITSLN             ! No. of characters in a FITS header
      PARAMETER ( FITSLN = 80 )  ! card

*  Local Variables:
      INTEGER ACTNUM             ! Actual no. of keywords in new FITS X
      INTEGER CPNTR( 1 )         ! Pointer to mapped temp. char. array
      INTEGER EL                 ! Element number of a mapped array
      INTEGER FTSPNT( 1 )        ! Pointer to mapped FITS X
      INTEGER IPNTR1( 1 )        ! Pointer to mapped temp. integer array
      INTEGER IPNTR2( 1 )        ! Pointer to mapped temp. integer array
      INTEGER NEWSIZ( 1 )        ! Size of new FITS extension
      CHARACTER * ( DAT__SZNAM ) OBJNAM ! Name of a HDS object
      INTEGER OLDSIZ             ! Size of old FITS extension
      CHARACTER * ( DAT__SZLOC ) WKLOC ! Locator to HDS workspace

*  Local Data:
      INCLUDE 'FTS_PAR'          ! FTS package constants and some
                                 ! declarations
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Get the name of the object to be located to by FTSLOC.
      CALL DAT_NAME( FTSLOC, OBJNAM, STATUS )

*  If the name is not 'FITS', set status, report the error and exit.
      IF ( OBJNAM .NE. 'FITS' ) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP( 'FTS1_EDFEX', 'The name of the object is not '/
     :                /'FITS.', STATUS )
         GOTO 999
      END IF

*  Get the size of the original FITS array.
      CALL DAT_SIZE( FTSLOC, OLDSIZ, STATUS )

*  Increase the size of the FITS array to the possible maximum size
*  after inserting new cards (and allow for possible extra END card).
      NEWSIZ( 1 ) = OLDSIZ + NKEY + 1
      CALL DAT_ALTER( FTSLOC, 1, NEWSIZ, STATUS )

*  Check status, if error, report and exit.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'FTS1_EDFEX', 'Unable to increase the size of '/
     :                /'FITS array.', STATUS )
         GOTO 999
      END IF

*  Map the 80-character FITS card array.
      CALL DAT_MAPV( FTSLOC, '_CHAR', 'UPDATE', FTSPNT, EL, STATUS )

*  Create and map workspace to hold two temporary integer arrays and a
*  temporary character array.
      CALL PSX_CALLOC( NEWSIZ( 1 ), '_INTEGER', IPNTR1, STATUS )
      CALL PSX_CALLOC( NEWSIZ( 1 ), '_INTEGER', IPNTR2, STATUS )
      CALL AIF_GETVM( '_CHAR*80', 1, NEWSIZ( 1 ), CPNTR, WKLOC, STATUS )

*  Cannot use PSX for character arrays due to a bug in PSX (it only uses
*  bytes and doesn't have a descriptor needed for Fortran).
*      CALL PSX_CALLOC( NEWSIZ( 1 ) * FITSLN, '_CHAR', CPNTR, STATUS )

*  Check status.  If error, report and exit.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'FTS1_EDFEX', 'Unable to map the FITS '/
     :     /'extension or get temporary work spaces.', STATUS )
         GOTO 990
      END IF

*  Insert the keyword cards into the FITS array.  Pass the length of an
*  element of each mapped character array.  Use a dummy routine so that
*  the order imposed here by UNIX compilers need not corrupt the actual
*  routine, whose arguments are in the standard order.  The mapped
*  arrays must appear before the unmapped arrays because we must pass
*  the lengths explicitly for the former as the compilers pass the
*  lengths of the latter as appended arguments .
      CALL FTS1_EDKEY_C1( OLDSIZ, NKEY, NEWSIZ( 1 ),
     :                    %VAL( CNF_PVAL( FTSPNT( 1 ) ) ), 
     :                    %VAL( CNF_PVAL( CPNTR( 1 ) ) ),
     :                    EDITS, NAMES, PSTNS, KOCCUR, POCCUR, VALUES,
     :                    COMNTS, TYPES, ACTNUM, 
     :                    %VAL( CNF_PVAL( IPNTR1( 1 ) ) ),
     :                    %VAL( CNF_PVAL( IPNTR2( 1 ) ) ), 
     :                    THERE, STATUS,
     :                    %VAL( FITSLN ), %VAL( FITSLN ) )

*  Unmap the FITS array.
      CALL DAT_UNMAP( FTSLOC, STATUS )

*  Reduce the size of FITS array to the actual number of cards.
      CALL DAT_ALTER( FTSLOC, 1, ACTNUM, STATUS )   

 990  CONTINUE

*  Annul the workspace.
      CALL PSX_FREE( IPNTR1, STATUS )
      CALL PSX_FREE( IPNTR2, STATUS )
*      CALL PSX_FREE( CPNTR, STATUS )
      CALL AIF_ANTMP( WKLOC, STATUS )

 999  CONTINUE
      
      END

*  This is a dummy routine needed to pass the mapped character arrays
*  in the order demanded by UNIX compilers.  All it does is call
*  the correct routine once the lengths of the mapped arrays are
*  known.
      SUBROUTINE FTS1_EDKEY_C1( OLDSIZ, NKEY, NEWSIZ, CARDS, CWORK,
     :                          EDITS, NAMES, PSTNS, KOCCUR, POCCUR,
     :                          VALUES, COMNTS, TYPES, ACTNUM,
     :                          IARY1, IARY2, THERE, STATUS )
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Arguments Given:
      INTEGER OLDSIZ
      INTEGER NKEY
      INTEGER NEWSIZ
      CHARACTER * ( * ) EDITS( NKEY )
      CHARACTER * ( * ) NAMES( NKEY )
      CHARACTER * ( * ) PSTNS( NKEY )
      INTEGER KOCCUR( NKEY )
      INTEGER POCCUR( NKEY )
      CHARACTER * ( * ) VALUES( NKEY )
      CHARACTER * ( * ) COMNTS( NKEY )
      CHARACTER * ( * ) TYPES( NKEY )
      INTEGER ACTNUM
      
*  Arguments Given and Returned:
      CHARACTER * ( * ) CARDS( NEWSIZ )
      INTEGER IARY1( NEWSIZ )
      INTEGER IARY2( NEWSIZ )

*  Arguments Returned:
      CHARACTER * ( * ) CWORK( NEWSIZ )
      LOGICAL THERE
      
*  Status:
      INTEGER STATUS             ! Global status

*  Insert the keyword cards into the FITS array.  Pass the length of an
*  element of the mapped character array.
      CALL FTS1_EDKEY( OLDSIZ, NKEY, NEWSIZ, EDITS, NAMES, PSTNS,
     :                 KOCCUR, POCCUR, VALUES, COMNTS, TYPES, CARDS,
     :                 ACTNUM, IARY1, IARY2, CWORK, THERE, STATUS )

      END
