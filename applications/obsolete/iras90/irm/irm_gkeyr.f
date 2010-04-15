      SUBROUTINE IRM_GKEYR( NCARD, BUFFER, SCARD, NAME, THERE, VALUE,
     :                      CARD, STATUS )
*+
*  Name:
*     IRM_GKEYR

*  Purpose:
*     Get the value of a named header of type _REAL from a buffer of
*     FITS header card images.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRM_GKEYR( NCARD, BUFFER, SCARD, NAME, THERE, VALUE, CARD,
*                     STATUS )

*  Description:
*     This routine searches a buffer containing the header card images
*     from a FITS file for card named %NAME; and returns its _REAL
*     value, %VALUE, and the number of the card image within the buffer
*     array that contains the named keyword.  The search ends when the
*     next end of a header block, marked by the END keyword, is
*     encountered or the buffer is exhausted.  If the keyword is
*     present %THERE is true, otherwise it is false.   Since all images
*     are in character format, type conversion is performed.  An error
*     status will be returned if the conversion has failed.  If the
*     keyword is present more than once in the header, only the first
*     occurence will be used.

*     The name may be compound to permit reading of hierarchical
*     keywords.  This routine will also work for HISTORY and COMMENTS
*     provided there is but one value given on the line, i.e. only
*     one "keyword = value" before any comment marker. An error will
*     result otherwise.

*  Arguments:
*     NCARD = INTEGER (Given)
*        The number of card images in the buffer.
*     BUFFER( NCARD ) = CHARACTER * 80 (Given)
*        The buffer containing the header card images.
*     SCARD = INTEGER (Given)
*        The number of the card from where the search will begin.  This
*        is needed because the headers make contain a dummy header
*        prior to an extension.
*     NAME = CHARACTER * ( * ) (Given)
*        The name of the keyword whose value is required.  This may be
*        a compound name to handle hierarchical keywords, and it has
*        the form keyword1.keyword2.keyword3 etc.  The maximum number of
*        keywords per FITS card is 20.  Comparisons are performed in
*        uppercase and blanks are removed.  Each keyword must be no
*        longer than 8 characters.
*     THERE = LOGICAL (Returned)
*        If true the keyword %NAME is present.
*     VALUE = REAL (Returned)
*        The value of the keyword.
*     CARD = INTEGER (Returned)
*        The number of the card containing the named keyword.
*        If the card could not be found this is set to zero.
*     STATUS = INTEGER (Given)
*        Global status value.

*  Algorithm:
*     -  Initialise counter and flag.  Test whether the input name is
*     compound by looking for the delimiter.
*     -  If it is not compound loop for all cards until the last card,
*     or the requested card is located.  Compare each card with the
*     desired keyword.  Once the required card is found set flag to
*     say keyword has been found, convert from a character string to
*     the value, otherwise go to the next card.
*     -  For a compound name loop for all cards until the last card,
*     or the requested card is located.  Go to the next card if the
*     current card does not contain an equals sign.  Generate the
*     compound keyword from the keywords before the equals sign. Compare
*     the compound keyword with the desired name.  Once the required
*     card is found set flag to say keyword has been found, find the
*     extent of the value in the card by finding any comment delimeter,
*     convert from a character string to the value, otherwise go to the
*     next card.
*     -  Reset card number to zero if the keyword is not present

*  Implementation Deficiencies:
*     Cannot handle character data because the arguments to CHR_CTOC
*     are different from the other CHR_CTOx routines.  The imaginary
*     portion of complex data is not processed.

*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     4-DEC-1992 (DSB):
*        Copied from KAPPA routine FTS1_GKEYR, written by MJC.
*     {enter_further_changes_here}

*  Bugs:
*     None known.
*     {note_new_bugs_here}

*-

*  Type Definitions:
      IMPLICIT  NONE           ! no default typing allowed

*  Global Constants:
      INCLUDE 'SAE_PAR'       ! SSE global definitions

*  Arguments Given:
      INTEGER
     :  NCARD,                 ! Number of FITS card images to search
     :  SCARD                  ! Search-start card number

      CHARACTER * ( * )
     :  BUFFER( NCARD ) * 80,  ! FITS tape buffer
     :  NAME                   ! Name of the keyword

*  Arguments Returned:
      LOGICAL                  ! True if:
     :  THERE                  ! Card containing the keyword is
                               ! present

      REAL
     :  VALUE                  ! Value of the keyword

      INTEGER
     :  CARD                   ! Number of the card image containing
                               ! keyword NAME

*  Status:
      INTEGER STATUS

*  External References:
      INTEGER
     :  CHR_LEN                ! Number of characters in a string
                               ! ignoring trailing blanks

*  Local Constants:
      INTEGER MXWORD           ! Maximum number of hierarchical levels
                               ! in a keyword
      PARAMETER ( MXWORD = 20 )

*  Local Variables:
      CHARACTER
     :  CHRVAL * 60,           ! The value in characters
     :  CMPKEY * 72,           ! Compound name
     :  CRDKEY * 8,            ! Card keyword
     :  KEYWRD * 80,           ! The compound keyword
     :  WORDS( MXWORD ) * 8    ! The keywords in the current card image

      INTEGER
     :  COMMNT,                ! Column number containing the comment
                               ! character in the current card image
     :  ENDW( MXWORD ),        ! End columns of each keyword in a card
                               ! image
     :  EQUALS,                ! Column number containing the first
                               ! equals sign in the current card image
     :  I,                     ! Loop counter
     :  ISTAT,                 ! Local status
     :  NC,                    ! Number of characters
     :  NCK,                   ! Number of characters in the compound
                               ! keyword
     :  NCHV,                  ! Number of characters in the value
     :  NWORD,                 ! Number of keywords in the current card
                               ! image
     :  STARTW( MXWORD )       ! Start columns of each keyword in a
                               ! card image

      LOGICAL                  ! True if:
     :  COMPND                 ! Supplied name is compound

*.


*  Check for error on entry.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise some variables.
      CARD = MAX( 1, SCARD )
      THERE = .FALSE.

*  Remove blanks from the keyword to be searched for, and make it
*  uppercase for comparisons.  Find its effective length.
      KEYWRD = NAME
      CALL CHR_UCASE( KEYWRD )
      CALL CHR_RMBLK( KEYWRD )
      NC = CHR_LEN( KEYWRD )

*  Is it a compound name?
      COMPND = INDEX( KEYWRD, '.' ) .NE. 0

*  The simple case.
*  ================
      IF ( .NOT. COMPND ) THEN

*  Now loop through the cards.  Compare the keyword on each word with
*  the given keyword, until the required card is found, or the 'END'
*  card is met, or there are no cardd remaining.
         DO WHILE ( ( .NOT. THERE ) .AND. ( CARD .LE. NCARD ) .AND.
     :              ( BUFFER( MIN( NCARD, CARD ) )( :3 ) .NE. 'END' ) )

*  Extract the keyword from this card image.
            CRDKEY = BUFFER( CARD )( :8 )

*  Is the current card the required keyword?
            IF ( CRDKEY( :CHR_LEN( CRDKEY ) ) .EQ. NAME( :NC ) ) THEN

*  The keyword is present.
               THERE = .TRUE.

               CHRVAL = BUFFER( CARD )( 11:30 )

*  Remove leading blanks and get number of characters comprising the
*  value.
               CALL CHR_LDBLK( CHRVAL )
               NCHV = CHR_LEN( CHRVAL )

*  Convert the string to a numeric value.
               CALL CHR_CTOR( CHRVAL( :NCHV ), VALUE, STATUS )

*  Report the error context.
               IF ( STATUS .NE. SAI__OK ) THEN
                  CALL MSG_SETC( 'NAME', NAME( :NC ) )
                  CALL ERR_REP( 'IRM_GKEYR_ERR1',
     :   'IRM_GKEYR: Error converting ^NAME to a floating point value.',
     :              STATUS )
               END IF

            ELSE

*  Onto the next card in the buffer.
               CARD = CARD + 1
            END IF
         END DO

*  Hierarchical-keyword case.
*  ==========================
      ELSE

*  Now loop through the cards ('END' terminates header).
         DO WHILE ( .NOT. THERE .AND. CARD .LE. NCARD .AND.
     :               BUFFER( MIN( NCARD, CARD ) )( :3 ) .NE. 'END' )

*  Does the current card have a value, i.e. an equals sign.  (This is
*  not foolproof because of the ING format et al.  uses blank fields,
*  comments and history to store data.
            EQUALS = INDEX( BUFFER( CARD ), '=' )
            IF ( EQUALS .NE. 0 ) THEN

*  Extract the words from the FITS card image up to the equals sign,
*  assuming these to be keywords.
               CALL CHR_DCWRD( BUFFER( CARD )( :EQUALS-1 ), MXWORD,
     :                         NWORD, STARTW, ENDW, WORDS, ISTAT )

*  Form compound name if there is more than one supposed keyword by
*  concatenating the words via the delimeter.
               IF ( NWORD .GT. 1 ) THEN
                  NCK = 0
                  CMPKEY = ' '
                  DO I = 1, NWORD
                     NC = ENDW( I ) - STARTW( I ) + 1
                     CALL CHR_PUTC( WORDS( I )( :NC ), CMPKEY, NCK )
                     IF ( I .NE. NWORD )
     :                 CALL CHR_PUTC( '.', CMPKEY, NCK )
                  END DO

*  Merely copy the first keyword.
               ELSE
                  CMPKEY = WORDS( 1 )
                  NCK = ENDW( 1 ) - STARTW( 1 ) + 1
               END IF

*  Compare the (compound) keyword of the current card image with that
*  of the compound keyword be searched for in the buffer.
               IF ( CMPKEY( :NCK ) .EQ. KEYWRD( :NCK ) ) THEN

*  The keyword is present.
                  THERE = .TRUE.

*  Find the upper range of columns that contains the value associated
*  with the hierarchical keyword.  This is achieved by looking for the
*  comment character.  This was not necessary for the the simple case
*  because the format is rigid.  Hierarchical keywords are non-standard
*  so it pays to be flexible.  Allow for the offset of the equals sign
*  when finding the column that last contains part of the value.
                  COMMNT = INDEX( BUFFER( CARD )( EQUALS + 1: ), '/' )
                  IF ( COMMNT .EQ. 0 ) THEN
                     COMMNT = LEN( BUFFER( CARD ) )
                  ELSE
                     COMMNT = COMMNT + EQUALS - 1
                  END IF

*  Extract the value as a character string.
                  CHRVAL = BUFFER( CARD )( EQUALS + 1:COMMNT )

*  Remove leading blanks and get number of characters comprising the
*  value.
                  CALL CHR_LDBLK( CHRVAL )
                  NCHV = CHR_LEN( CHRVAL )

*  Convert the string to a numeric value.
                  CALL CHR_CTOR( CHRVAL( :NCHV ), VALUE, STATUS )

*  Report the error context.
                  IF ( STATUS .NE. SAI__OK ) THEN
                     CALL MSG_SETC( 'NAME', KEYWRD( :NCK ) )
                     CALL ERR_REP( 'IRM_GKEYR_ERR2',
     :   'IRM_GKEYR: Error converting ^NAME to a floating point value.',
     :                 STATUS )
                  END IF

               ELSE

*  Onto the next card in the buffer.
                  CARD = CARD + 1
               END IF

            ELSE

*  Onto the next card in the buffer.
               CARD = CARD + 1
            END IF
         END DO
      END IF

      IF ( .NOT. THERE ) CARD = 0

      END
