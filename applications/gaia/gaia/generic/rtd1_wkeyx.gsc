      SUBROUTINE RTD1_WKEY<T>( NCARD, BLOCK, CARD, NEWEND, KEYWRD,
     :                         COMMEN, VALUE, STATUS )
*+
* Name:
*    RTD1_WKEY<T>

*  Purpose:
*     Writes a FITS keyword, value and comment.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL RTD1_WKEY<T>( NCARD, BLOCK, CARD, NEWEND, KEYWRD, COMMEN,
*                      VALUE, STATUS )

*  Description:
*     This routine writes a FITS keyword together with its value and a
*     comment into a FITS card record (a "FITS block"). The new record
*     is inserted at position CARD in the block and a new "END" record
*     is created immediately after this if required. The special
*     keywords 'COMMENT', 'HISTORY' and ' ' are correctly dealt with (no
*     comment or equals sign and are appended after last occurence).
*     The keyword may be "hierarchical", this results in a multiple
*     keyword record.

*  Arguments:
*     NCARD = INTEGER (Given)
*        The number of elements (cards) in BLOCK.
*     BLOCK( NCARD ) = CHARACTER * ( * ) (Given and Returned)
*        The FITS block (note this is passed at this point so that it is
*        before the other *(*) characters which allows this array to be
*        mapped -- see SUN/92).
*     CARD = INTEGER (Given)
*        The index of the card in which to insert the new record.
*     NEWEND = LOGICAL (Given)
*        Whether an "END" record is required immediately after the new
*        record.
*     KEYWRD = CHARACTER * ( * ) (Given)
*        The FITS keyword. This may be hierarchical. The components of
*        the name should be separated by periods (e.g. ING.DETHEAD
*        results in a keyword 'ING DETHEAD').
*     COMMEN = CHARACTER * ( * ) (Given)
*        Comment for the record. Ignored if keyword is 'HISTORY' or
*        'COMMENT'.
*     VALUE =  <COMM> (Given)
*        The value.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - There is a version of this routine for writing header items
*     of various types. Replace the "x" in the routine name by C, L, D,
*     R, or I as appropriate.
*

*  Copyright:
*     Copyright (C) 1998 Central Laboratory of the Research Councils

*  Authors:
*     PDRAPER: Peter Draper (STARLINK - Durham University)
*     {enter_new_authors_here}

*  History:
*     22-JUL-1994 (PDRAPER):
*        Original version.
*     30-NOV-1994 (PDRAPER):
*        Added checj that non-compound names are only 8 characters.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      INTEGER CARD
      LOGICAL NEWEND
      CHARACTER * ( * ) KEYWRD
      CHARACTER * ( * ) COMMEN
      <TYPE> VALUE
      INTEGER NCARD

*  Arguments Given and Returned:
      CHARACTER * ( * ) BLOCK( NCARD )

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL CHR_LEN
      INTEGER CHR_LEN            ! Used length of string

*  Local Variables:
      CHARACTER * ( 80 ) LKEY    ! Local record buffer
      CHARACTER * ( 80 ) BUFFER  ! Temporary buffer
      INTEGER LENKEY             ! Used length of LKEY
      INTEGER I                  ! Loop variable
      INTEGER ENDCRD             ! Position of END card
      INTEGER IAT                ! Current insertion point
      INTEGER NOWAT              ! Current insertion point
      LOGICAL SPEC               ! Keyword is COMMENT, HISTORY or ' '
      LOGICAL COMPND             ! Keyword is compound
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Create local copy of keyword.
      LKEY = KEYWRD
      CALL CHR_UCASE( LKEY )
      CALL CHR_LDBLK( LKEY )

*  Clear the current contents of the card.
      BLOCK( CARD ) = ' '

*  Get lengths of string for reference.
      LENKEY = CHR_LEN( LKEY )

*  See if keyword is a special.
      SPEC = LKEY( :LENKEY ) .EQ. 'COMMENT' .OR.
     :       LKEY( :LENKEY ) .EQ. 'HISTORY' .OR.
     :       LKEY .EQ. ' '

*  See if keyword is hierarchical.
      COMPND = INDEX( LKEY( : LENKEY ), '.' ) .NE. 0 
      IF ( COMPND ) THEN

*  Strip out the '.' and indent by 9.
         LENKEY = MIN( LENKEY, 71 )
         DO 1 I = LENKEY, 1, -1
            IF ( LKEY( I: I ) .EQ. '.' ) THEN
               LKEY( I + 9: I + 9 ) = ' '
            ELSE
               LKEY( I + 9: I + 9 ) = LKEY( I: I )
            END IF
            LKEY( I: I ) = ' '
 1       CONTINUE
         LENKEY = LENKEY + 9
      END IF
         
*  Add keyword to the record.
      IF ( COMPND ) THEN
         BLOCK( CARD ) = LKEY( :LENKEY )
      ELSE

*  Non-compound (so presumably correct names) are limited to 8
*  characters.
         LENKEY = MIN( LENKEY, 8 )
         BLOCK( CARD ) = LKEY( : MIN( 8, LENKEY ) )
      END IF
      IAT = MAX( LENKEY, 8 ) + 1
      IF ( .NOT. SPEC ) THEN

*  Add an equals sign.
         BLOCK( CARD )( IAT: ) = '= '
         IAT = IAT + 2
      END IF

*  No values should ever appear before column 10 (after '=' column)
      IAT = MAX( 10, IAT )

*  Insert the value try to right justify this to the column +10 (~30)
*  from this position (only for non-character types).
      NOWAT = 0
      LKEY = ' '
      BUFFER = ' '
      CALL CHR_PUT<T>( VALUE, BUFFER, NOWAT )
      IF ( NOWAT .LE. 19 .AND. 'C' .NE. '<T>') THEN
         CALL RTD1_PLOC( BUFFER( :NOWAT ), 20, LKEY, STATUS )
         NOWAT = 20
      ELSE
         NOWAT = CHR_LEN( BUFFER )
         LKEY = BUFFER( :MAX( 1, NOWAT ) )
      END IF

*  If the type is character we need to add quotes (unless it's a
*  special). The standard also specifies that the end-quote should not
*  occur before column 21, so align it with column before usual
*  comments.
      IF ( '<T>' .EQ. 'C' .AND. .NOT. SPEC ) THEN
         BLOCK( CARD )( IAT: ) = ''''//LKEY( :MAX( 1, NOWAT ) )
         IAT = MAX( NOWAT + IAT + 1, 30 )
         BLOCK( CARD )( IAT: IAT) = ''''
         IAT = MAX( IAT + 1, 32 )
      ELSE 
         BLOCK( CARD )( IAT: ) = LKEY( : MAX( 1, NOWAT ) )
         IAT = IAT + NOWAT + 1
      END IF

*  Now add the comment.
      IF ( .NOT. SPEC ) BLOCK( CARD )( IAT: ) = '/ '//COMMEN

*  Finally add an extra 'END' record if asked.
      IF ( NEWEND ) THEN 
         ENDCRD = CARD + 1
         IF ( ENDCRD .LE. NCARD ) THEN 
            BLOCK( ENDCRD ) = 'END'
         END IF
      END IF  

      END
